#!/usr/bin/env python3
# Copyright 2026 OpenHW Group
# SPDX-License-Identifier: Apache-2.0
"""Collect OpenROAD design flow PPA metrics for the CVA6 dashboard.

Fetches completed runs of the OpenRoad design flow workflows from the GitHub API,
downloads the JSON artifacts, and extracts PPA metrics.
Requires `gh` CLI authenticated (pre-installed on GHA runners).

Intended for use in PD-dashboard.yml, triggered via
workflow_run on OR-flow-floorplan.yml & OR-flow-grt.yml.

E.g. for OR-flow-floorplan.yml:

    python3 extract_PD_metrics.py --flow flp --data-dir /tmp/PD-data \
        --default-branch master

PD_FLOWS defines each tracked flow ("flp", "grt"): its workflow, artifact names,
metrics file and runs file.

Artifact layout expected from OR-flow-floorplan.yml:

    Artifact name:  PD-flp-{arch}-{config}
    Contents:       2_1_floorplan.json

Artifact layout expected from OR-flow-grt.yml:

    Artifact name:  PD-grt-{arch}-{config}
    Contents:       5_1_grt.json

Both workflows also upload a `PD-{flp,grt}-logs-{arch}-{config}` artifact:
logs, reports, the arguments of each stage (*.args.json, written by bazel-orfs)
and build_params.json (written by a CI step: what the *.args.json lack, i.e. the
clock period, and the PR number for pull_request runs).

The script downloads all artifacts for each run using
`gh run download` (which handles authentication and zip extraction),
then processes the extracted JSON files.

A run whose jobs or artifacts cannot be fetched (FetchError, e.g. a network
error or a rate limit) is left out, and processed again by the next update
instead of being recorded with failed flows. So is a re-run: same run id, new
run_attempt, whose record replaces the previous one.

The run's matrix jobs (GitHub API) define the flow list, not the artifacts:
a job killed before its upload steps (e.g. runner shutdown, where even the
`if: always()` steps are skipped) leaves no artifact at all, but must still
show up as failed. Its GitHub job log is then used as the downloadable logs.

Runs of the default branch (--default-branch) are the reference runs (trends,
history). PR runs and runs of other branches are the candidate runs, which the
dashboard compares to the reference runs. Both are kept in the same JSON file,
trimmed separately.
"""

import argparse
import json
import os
import re
import subprocess
import sys
import tempfile
import zipfile
from datetime import datetime, timezone
from pathlib import Path
import shutil

# Reference cell area for Kgate calculation (µm²).
# A "gate equivalent" = area of a 2-input NAND cell.
# ASAP7 RVT NAND2x1: 0.0874 µm².
# Override with --nand2-area for other PDKs.
ASAP7_NAND2_AREA_UM2 = 0.0874

# --default-branch value when run by hand: the CI passes the repository's default branch,
# whose runs (PR runs excepted) are the reference runs
DEFAULT_BRANCH = "master"

# Trimmed separately, so that a burst of PR runs cannot push the reference history out
MAX_REFERENCE_HISTORY = 50
MAX_CANDIDATE_HISTORY = 30

# The tracked flows are defined by PD_FLOWS, after the metric extractors it refers to

# Build parameters shown on the dashboard, as ordered (key, display label) pairs:
# the build arguments that most affect PPA metrics. The run records keep these keys.
BUILD_PARAM_LABELS = [
    ("CORE_UTILIZATION", "Core Utilization (%)"),
    ("PLACE_DENSITY", "Place Density"),
    ("ABC_CLOCK_PERIOD_IN_PS", "Target Clock Period (ps)"),
    ("SYNTH_HIERARCHICAL", "Hierarchical Synthesis"),
    ("SYNTH_MINIMUM_KEEP_SIZE", "Min Module Keep Size"),
]

# Their sources, in the logs artifact of a flow (merged in this order, later files winning):
# - the arguments that bazel-orfs passes to each stage, one file per stage (1_synth, 2_floorplan...).
#   Only the arguments set in BUILD.bazel, not the ORFS defaults
STAGE_ARGS_GLOB = "*.args.json"
# - the file written by the `Extract build parameters` CI step: what the stage arguments lack
#   (ABC_CLOCK_PERIOD_IN_PS, from the SDC). The floorplan workflow also writes the PR number in
#   it (PR_NUMBER key, empty outside pull_request runs), popped into the run record
BUILD_PARAMS_FILENAME = "build_params.json"

# Arch and config names go into file paths and into the dashboard page. They come
# from artifact and job names, which the workflow of a PR run sets freely.
SAFE_NAME_RE = re.compile(r"[A-Za-z0-9_]+")


# ---------------------------------------------------------------------------
# Problem reporting
# ---------------------------------------------------------------------------

def annotate(level: str, message: str) -> None:
    """Report a problem the dashboard workflow keeps running through.

    level: "warning" or "error". In GitHub Actions, prints a workflow command:
    the message shows on the run's summary page, not only deep in the step log
    of a workflow that passes. Elsewhere, a plain stderr line.
    """
    if os.environ.get("GITHUB_ACTIONS") == "true":
        # Workflow commands are single-line: escaped as the runner expects
        escaped = message.replace("%", "%25").replace("\r", "%0D").replace("\n", "%0A")
        print(f"::{level}::{escaped}")
    else:
        print(f"{level.upper()}: {message}", file=sys.stderr)


class FetchError(Exception):
    """The jobs or artifacts of a run could not be fetched, likely a transient error.

    The run is left out of this update, to be processed again by the next one:
    recording it would show flows failing for a reason other than the design, for
    good, since recorded runs are not processed again.
    """


# ---------------------------------------------------------------------------
# Metric extraction
# ---------------------------------------------------------------------------

def require_number(data: dict, key: str) -> float:
    """data[key], checked to be a number: ValueError naming the key otherwise."""
    value = data.get(key)
    if value is None:
        raise ValueError(f"key not found in the metrics JSON: {key}")
    if not isinstance(value, (int, float)):
        raise ValueError(f"non-numeric {key} in the metrics JSON: {value!r}")
    return value


def extract_grt_metrics(data: dict, nand2_area: float) -> dict:
    """Extract PPA metrics from a GRT-stage JSON report."""
    def get(key):
        return require_number(data, key)

    # A congested GRT still produces this JSON (bazel-orfs sets GENERATE_ARTIFACTS_ON_FAILURE=1)
    errors = get("globalroute__flow__errors__count")
    if errors:
        raise ValueError(f"global routing finished with {errors} error(s)")

    stdcell_area_um2 = get("globalroute__design__instance__area__stdcell")
    macro_area_um2   = get("globalroute__design__instance__area__macros")
    total_area_um2   = get("globalroute__design__instance__area")
    die_area_um2     = get("globalroute__design__die__area")
    core_area_um2    = get("globalroute__design__core__area")
    fmax_hz          = get("globalroute__timing__fmax")
    worst_slack_ps   = get("globalroute__timing__setup__ws")
    power_w          = get("globalroute__power__total")

    return {
        "stdcell_area_um2":    round(stdcell_area_um2, 4),
        "macro_area_um2":      round(macro_area_um2, 4),
        "total_instance_area_um2": round(total_area_um2, 4),
        "core_area_um2":       round(core_area_um2, 4),
        "die_area_um2":        round(die_area_um2, 4),
        "stdcell_kgate":       round(stdcell_area_um2 / nand2_area / 1000, 4),
        "fmax_mhz":            round(fmax_hz / 1e6, 2),
        "worst_setup_slack_ps": round(worst_slack_ps, 3),
        "timing_met":          worst_slack_ps >= 0,
        "power_mw":            round(power_w * 1e3, 3),
    }


def extract_flp_metrics(data: dict, nand2_area: float) -> dict:
    """Extract PPA metrics from a floorplan-stage JSON report."""
    def get(key):
        return require_number(data, key)

    stdcell_area_um2 = get("floorplan__design__instance__area__stdcell")
    macro_area_um2   = get("floorplan__design__instance__area__macros")
    total_area_um2   = get("floorplan__design__instance__area")
    die_area_um2     = get("floorplan__design__die__area")
    core_area_um2    = get("floorplan__design__core__area")
    utilization      = get("floorplan__design__instance__utilization")
    fmax_hz          = get("floorplan__timing__fmax")
    worst_slack_ps   = get("floorplan__timing__setup__ws")
    power_w          = get("floorplan__power__total")

    return {
        "stdcell_area_um2":        round(stdcell_area_um2, 4),
        "macro_area_um2":          round(macro_area_um2, 4),
        "total_instance_area_um2": round(total_area_um2, 4),
        "core_area_um2":           round(core_area_um2, 4),
        "die_area_um2":            round(die_area_um2, 4),
        "utilization":             round(utilization, 6),
        "stdcell_kgate":           round(stdcell_area_um2 / nand2_area / 1000, 4),
        "fmax_mhz":                round(fmax_hz / 1e6, 2),
        "worst_setup_slack_ps":    round(worst_slack_ps, 3),
        "timing_met":              worst_slack_ps >= 0,
        "power_mw":                round(power_w * 1e3, 3),
    }


def read_metrics(json_path: Path | None, extractor, nand2_area: float) -> dict:
    """Metrics of a flow, read from its metrics JSON by `extractor`.

    Raises OSError or ValueError, whose message says why the flow has no metrics.
    """
    if json_path is None:
        raise FileNotFoundError("no metrics artifact (job failed before upload)")
    try:
        with open(json_path) as f:
            data = json.load(f)
    except json.JSONDecodeError as exc:
        raise ValueError(f"invalid metrics JSON: {exc}") from exc
    if not isinstance(data, dict):
        raise ValueError(f"the metrics JSON holds a {type(data).__name__}, not an object")
    return extractor(data, nand2_area)


# ---------------------------------------------------------------------------
# Tracked flows
# ---------------------------------------------------------------------------

# The only definition of each flow: PD-dashboard.yml passes the key (--flow), and
# generate_PD_dashboard.py reads the runs file from here. The artifact names must
# match those of the workflow's upload steps.
PD_FLOWS = {
    "flp": {
        "workflow":        "OR-flow-floorplan.yml",
        "artifact_prefix": "PD-flp-",       # PD-flp-{arch}-{config}, holding metrics_file
        "logs_prefix":     "PD-flp-logs-",  # PD-flp-logs-{arch}-{config}
        "metrics_file":    "2_1_floorplan.json",
        "extractor":       extract_flp_metrics,
        "runs_file":       "runs_PD_flp.json",
    },
    "grt": {
        "workflow":        "OR-flow-grt.yml",
        "artifact_prefix": "PD-grt-",
        "logs_prefix":     "PD-grt-logs-",
        "metrics_file":    "5_1_grt.json",
        "extractor":       extract_grt_metrics,
        "runs_file":       "runs_PD_grt.json",
    },
}


# ---------------------------------------------------------------------------
# JSON persistence helpers  (mirrors .github/scripts/dashboard_tiers/collect_data.py)
# ---------------------------------------------------------------------------

def load_existing(path: Path) -> list:
    """Load existing run data from a JSON file, [] when it does not exist yet.

    Any other error stops the script: starting fresh would overwrite the history,
    delete the raw files of its runs, and the dashboard workflow would then commit
    that over the persisted data.
    """
    if not path.exists():
        return []
    try:
        with open(path) as f:
            data = json.load(f)
    except (OSError, json.JSONDecodeError) as exc:
        annotate("error", f"Cannot read {path}: {exc}. Fix it, or delete it to start a new history")
        sys.exit(1)
    if not isinstance(data, list):
        annotate("error", f"{path} holds a {type(data).__name__}, not a list of runs")
        sys.exit(1)
    return data


def is_reference_run(run: dict, default_branch: str) -> bool:
    """True for a run of default_branch, False for a PR run or a run of another branch.

    Works on both GitHub API runs and the run records of this script. A fork PR
    opened from a branch named like default_branch is a pull_request run: not a
    reference.
    """
    return run.get("event") != "pull_request" and run.get("head_branch") == default_branch


def merge_runs(existing: list, new_runs: list, default_branch: str) -> list:
    """Merge new runs into existing data.

    A new record replaces the existing one of the same run (processed again
    after a re-run).
    """
    by_id = {r["id"]: r for r in existing}
    by_id.update((r["id"], r) for r in new_runs)

    # Sort by created_at descending (newest first)
    merged = sorted(by_id.values(), key=lambda r: r.get("created_at", ""), reverse=True)

    # Trim reference and candidate runs separately, then interleave them back
    reference  = [r for r in merged if is_reference_run(r, default_branch)][:MAX_REFERENCE_HISTORY]
    candidates = [r for r in merged if not is_reference_run(r, default_branch)][:MAX_CANDIDATE_HISTORY]
    return sorted(reference + candidates, key=lambda r: r.get("created_at", ""), reverse=True)

def cleanup_old_raw_files(raw_dir: Path, kept_run_ids: set) -> None:
    """Delete raw JSON files for runs no longer in the kept list."""
    if not raw_dir.exists():
        return
    for run_dir in raw_dir.iterdir():
        if run_dir.is_dir():
            try:
                run_id = int(run_dir.name)
                if run_id not in kept_run_ids:
                    shutil.rmtree(run_dir)
                    print(f"Cleaned up old run data: {run_dir}")
            except ValueError:
                pass  # Skip non-numeric directories


def all_kept_run_ids(data_dir: Path) -> set:
    """Union of run ids across the runs files of every PD_FLOWS flow in data_dir.

    raw/ is shared between the flp and grt invocations of this script, so
    cleanup must keep ids from both JSON files, not just the one just written.
    """
    runs_files = {flow["runs_file"] for flow in PD_FLOWS.values()}
    for path in sorted(data_dir.glob("*.json")):
        if path.name not in runs_files:
            # e.g. the runs file of a flow renamed in PD_FLOWS: its history is no longer shown
            annotate("warning", f"{path} is not the runs file of a PD_FLOWS flow: "
                                f"the raw files of its runs are deleted")
    ids = set()
    for name in runs_files:
        ids.update(run["id"] for run in load_existing(data_dir / name))
    return ids


def duration_seconds(started_at: str, completed_at: str) -> int:
    """Calculate duration in seconds between two ISO timestamps."""
    if not started_at or not completed_at:
        return 0
    try:
        start = datetime.fromisoformat(started_at.replace("Z", "+00:00"))
        end   = datetime.fromisoformat(completed_at.replace("Z", "+00:00"))
        return max(0, int((end - start).total_seconds()))
    except (ValueError, TypeError):
        return 0


# ---------------------------------------------------------------------------
# GitHub API helpers  (mirrors collect_data.py)
# ---------------------------------------------------------------------------

def fetch_jobs(repo: str, run_id: int) -> dict:
    """Return {config_name: job_info} for every matrix job in a run.

    job_info holds the job "id", "conclusion", "html_url" and "duration_seconds".
    Matrix jobs are named after their config (`name: ${{ matrix.config }}`).
    Raises FetchError when the jobs cannot be fetched.
    """
    result = subprocess.run(
        ["gh", "api", f"/repos/{repo}/actions/runs/{run_id}/jobs", "--paginate"],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        raise FetchError(f"could not fetch its jobs: {result.stderr.strip()}")
    data = json.loads(result.stdout)
    jobs = {}
    for job in data.get("jobs", []):
        name = job.get("name", "")
        if not SAFE_NAME_RE.fullmatch(name):
            annotate("warning", f"Ignoring job {name!r} of run {run_id}: not a config name")
            continue
        jobs[name] = {
            "id":               job.get("id"),
            "conclusion":       job.get("conclusion"),
            "html_url":         job.get("html_url", ""),
            "duration_seconds": duration_seconds(job.get("started_at", ""), job.get("completed_at", "")),
        }
    return jobs


def download_job_log(repo: str, job_id: int, zip_dest: Path) -> bool:
    """Zip the GitHub log of a job into zip_dest; return True on success.

    Fallback for jobs that uploaded no logs artifact: their GitHub job log is
    then the only log left (requires `actions: read`).
    """
    result = subprocess.run(
        ["gh", "api", f"/repos/{repo}/actions/jobs/{job_id}/logs"],
        capture_output=True,
    )
    if result.returncode != 0:
        annotate("warning", f"Could not fetch the log of job {job_id}: {result.stderr.decode(errors='replace').strip()}")
        return False
    with zipfile.ZipFile(zip_dest, "w", zipfile.ZIP_DEFLATED) as zf:
        zf.writestr("github_job.log", result.stdout)
    return True


def gh_api(endpoint: str, repo: str) -> dict:
    """Call GitHub API via `gh api` and return parsed JSON."""
    url    = f"/repos/{repo}/actions/{endpoint}"
    result = subprocess.run(
        ["gh", "api", url],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        annotate("error", f"gh api {url} failed: {result.stderr.strip()}")
        sys.exit(1)
    return json.loads(result.stdout)


def fetch_runs(repo: str, workflow_file: str, count: int) -> list:
    """Fetch the latest `count` completed workflow runs."""
    data = gh_api(
        f"workflows/{workflow_file}/runs?status=completed&per_page={count}",
        repo,
    )
    return data.get("workflow_runs", [])[:count]


# ---------------------------------------------------------------------------
# Artifact download
# ---------------------------------------------------------------------------

def list_run_artifacts(repo: str, run_id: int) -> set:
    """Names of the unexpired artifacts of a run. Raises FetchError.

    Tells a run without artifacts (e.g. jobs that failed before their upload)
    from a failed download: `gh run download` fails in both cases.
    """
    result = subprocess.run(
        ["gh", "api", f"/repos/{repo}/actions/runs/{run_id}/artifacts", "--paginate",
         "--jq", ".artifacts[] | select(.expired | not) | .name"],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        raise FetchError(f"could not list its artifacts: {result.stderr.strip()}")
    return set(result.stdout.splitlines())


def arch_for_config(config: str) -> str:
    """Arch of a config, as the OR-flow workflows put it in artifact names."""
    return "RV32" if config.startswith("cv32") else "RV64"


def iter_artifact_dirs(dest_dir: Path, prefix: str, skip_prefix: str = ""):
    """Yield (arch, config, artifact_dir) for each artifact directory matching prefix.

    skip_prefix: artifacts to leave out, e.g. the "PD-flp-logs-" ones that the
    "PD-flp-*" download pattern also pulls.
    """
    for artifact_dir in sorted(dest_dir.iterdir()):
        if not artifact_dir.is_dir() or not artifact_dir.name.startswith(prefix):
            continue
        if skip_prefix and artifact_dir.name.startswith(skip_prefix):
            continue
        suffix = artifact_dir.name[len(prefix):]
        # rsplit on "-" (last occurrence) so design names containing "-" are preserved.
        parts  = suffix.rsplit("-", 1)
        arch   = parts[0] if len(parts) >= 1 else suffix
        config = parts[1] if len(parts) >= 2 else "base"
        if not (SAFE_NAME_RE.fullmatch(arch) and SAFE_NAME_RE.fullmatch(config)):
            annotate("warning", f"Ignoring artifact {artifact_dir.name!r}: unexpected arch/config name")
            continue
        yield arch, config, artifact_dir


def download_run_artifacts(repo: str, run_id: int, dest_dir: Path, flow: dict,
                           artifact_names: set) -> list:
    """Download the metrics artifacts of a PD_FLOWS flow for a run into dest_dir.

    Uses `gh run download` which handles authentication and zip extraction.
    Each artifact lands at dest_dir/{artifact_name}/{metrics_json}.
    artifact_names: from list_run_artifacts(), to skip a run without any.

    Returns a list of (arch, config, json_path) tuples. Raises FetchError.
    """
    metrics_filename = flow["metrics_file"]
    artifact_prefix  = flow["artifact_prefix"]
    # "PD-flp-*" also matches the "PD-flp-logs-*" artifacts, handled separately
    logs_prefix = flow["logs_prefix"]
    if not any(n.startswith(artifact_prefix) and not n.startswith(logs_prefix) for n in artifact_names):
        return []
    result = subprocess.run(
        [
            "gh", "run", "download", str(run_id),
            "--repo", repo,
            "--pattern", f"{artifact_prefix}*",
            "--dir", str(dest_dir),
        ],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        raise FetchError(f"gh run download failed: {result.stderr.strip()}")

    found = []
    for arch, config, artifact_dir in iter_artifact_dirs(dest_dir, artifact_prefix, skip_prefix=logs_prefix):
        json_path = artifact_dir / metrics_filename
        if json_path.exists():
            found.append((arch, config, json_path))
            print(f"  Downloaded: {artifact_dir.name} -> {arch}/{config}")
        else:
            annotate("warning", f"{metrics_filename} not found in artifact {artifact_dir.name} of run {run_id}")

    return found


def read_build_params(artifact_dir: Path) -> dict:
    """All the build parameters found in a logs artifact (see STAGE_ARGS_GLOB).

    The stage files are merged in flow order, later stages winning as in bazel-orfs.
    Raises OSError or ValueError on an unreadable file.
    """
    # Stage files sort in flow order: 1_synth, 2_floorplan, ..., 5_1_grt
    paths = sorted(artifact_dir.rglob(STAGE_ARGS_GLOB), key=lambda path: path.name)
    paths += sorted(artifact_dir.rglob(BUILD_PARAMS_FILENAME))
    params = {}
    for path in paths:
        try:
            with open(path) as f:
                data = json.load(f)
        except json.JSONDecodeError as exc:
            raise ValueError(f"invalid JSON in {path.name}: {exc}") from exc
        if not isinstance(data, dict):
            raise ValueError(f"{path.name} holds a {type(data).__name__}, not an object")
        params.update(data)
    return params


def download_and_zip_logs(
    repo: str,
    run_id: int,
    dest_dir: Path,
    logs_prefix: str,
    run_raw_dir: Path,
    artifact_names: set,
) -> tuple:
    """Download log artifacts, zip them per config. Raises FetchError.

    artifact_names: from list_run_artifacts(), to skip a run without any.

    Returns (logs_map, build_params_map):
      logs_map:         {(arch, config): site_relative_zip_path}
      build_params_map: {(arch, config): read_build_params() of the artifact}
    """
    if not any(n.startswith(logs_prefix) for n in artifact_names):
        return {}, {}
    result = subprocess.run(
        [
            "gh", "run", "download", str(run_id),
            "--repo", repo,
            "--pattern", f"{logs_prefix}*",
            "--dir", str(dest_dir),
        ],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        raise FetchError(f"gh run download (logs) failed: {result.stderr.strip()}")

    logs_map = {}
    build_params_map = {}
    for arch, config, artifact_dir in iter_artifact_dirs(dest_dir, logs_prefix):
        # Get all files in the artifact (logs + reports)
        log_files = sorted([f for f in artifact_dir.rglob("*") if f.is_file()])
        if not log_files:
            annotate("warning", f"Artifact {artifact_dir.name} of run {run_id} holds no file")
            continue

        # upload-artifact roots multi-path artifacts at the paths' common ancestor
        # (bazel-bin/), so the files sit under logs/asap7/..., results/asap7/..., not at the root.
        try:
            build_params_map[(arch, config)] = read_build_params(artifact_dir)
        except (OSError, ValueError) as exc:
            annotate("warning", f"Could not read the build parameters of artifact {artifact_dir.name} "
                                f"of run {run_id}: {exc}")

        zip_dest = run_raw_dir / f"{arch}_{config}_logs.zip"
        with zipfile.ZipFile(zip_dest, "w", zipfile.ZIP_DEFLATED) as zf:
            for lf in log_files:
                zf.write(lf, lf.name)
        logs_map[(arch, config)] = f"./PD-data/raw/{run_id}/{arch}_{config}_logs.zip"
        print(f"  Zipped {len(log_files)} log(s) -> {zip_dest.name}")

    return logs_map, build_params_map


# ---------------------------------------------------------------------------
# CI run processing
# ---------------------------------------------------------------------------

def pop_pr_number(run: dict, build_params: dict) -> int | None:
    """PR number of a pull_request run, None for other runs.

    Taken out of build_params (PR_NUMBER), where the floorplan job writes it.
    The GitHub API only gives it for PRs opened from this repository
    (run["pull_requests"], empty for fork PRs): fallback for a job that left no
    build_params.json.
    """
    value = str(build_params.pop("PR_NUMBER", ""))
    if run.get("event") != "pull_request":
        return None
    if re.fullmatch(r"[0-9]+", value):
        return int(value)
    prs = run.get("pull_requests") or []
    return prs[0].get("number") if prs else None


def process_ci_run(repo: str, run: dict, nand2_area: float, raw_dir: Path, flow: dict) -> dict:
    """Fetch artifacts for a PD run, extract metrics, and build a run record.

    Raises FetchError, leaving raw_dir untouched.
    """
    run_id = run["id"]
    extractor = flow["extractor"]

    jobs = fetch_jobs(repo, run_id)
    artifact_names = list_run_artifacts(repo, run_id)

    with tempfile.TemporaryDirectory() as tmp:
        tmp_path = Path(tmp)
        # Raw files are staged, and moved to raw_dir once the run is processed: a
        # FetchError leaves no partial files, nor overwrites those of a previous attempt
        run_raw_dir = tmp_path / "raw"
        run_raw_dir.mkdir()

        json_list = download_run_artifacts(repo, run_id, tmp_path / "artifacts", flow, artifact_names)

        for arch, config, json_path in json_list:
            shutil.copy2(json_path, run_raw_dir / f"{arch}_{config}.json")

        logs_map, build_params_map = download_and_zip_logs(repo, run_id, tmp_path / "logs", flow["logs_prefix"],
                                                           run_raw_dir, artifact_names)

        json_map = {(arch, config): json_path for arch, config, json_path in json_list}

        # Jobs that left no artifact at all (e.g. runner shutdown) still get a flow
        flow_keys = json_map.keys() | logs_map.keys()
        configs_with_artifacts = {config for _, config in flow_keys}
        flow_keys |= {(arch_for_config(config), config) for config in jobs
                      if config not in configs_with_artifacts}

        flows = []
        for arch, config in flow_keys:
            json_path = json_map.get((arch, config))
            job = jobs.get(config, {})
            if (arch, config) not in logs_map and job.get("id"):
                zip_dest = run_raw_dir / f"{arch}_{config}_logs.zip"
                if download_job_log(repo, job["id"], zip_dest):
                    logs_map[(arch, config)] = f"./PD-data/raw/{run_id}/{zip_dest.name}"
                    print(f"  No logs artifact for {arch}/{config}, zipped its GitHub job log instead")
            # error: why the flow has no metrics, shown on the dashboard
            error = None
            try:
                metrics    = read_metrics(json_path, extractor, nand2_area)
                conclusion = "success"
                timing_str = "timing met" if metrics["timing_met"] else "timing NOT met"
                print(
                    f"    [SUCCESS] {arch}/{config}  "
                    f"fmax={metrics['fmax_mhz']:.1f} MHz  "
                    f"stdcell={metrics['stdcell_area_um2']:.3f} µm²  "
                    f"({metrics['stdcell_kgate']:.2f} Kgate)  "
                    f"power={metrics['power_mw']:.2f} mW  [{timing_str}]"
                )
            except (OSError, ValueError) as exc:
                error      = str(exc)
                metrics    = {}
                conclusion = "failure"
                if job.get("conclusion") in (None, "success"):
                    # Not explained by a failed job: the run looks fine on GitHub
                    annotate("warning", f"Run {run['run_number']} (id={run_id}), {arch}/{config}: "
                                        f"no metrics although the job passed: {error}")
                else:
                    print(f"    [FAILURE] {arch}/{config}: {error}")

            # A failed/cancelled job overrides the metrics check (e.g. it died after the upload)
            if job.get("conclusion") not in (None, "success"):
                conclusion = job["conclusion"]

            flows.append({
                "arch":             arch,
                "config":           config,
                "conclusion":       conclusion,
                "html_url":         job.get("html_url") or run.get("html_url", ""),
                "duration_seconds": job.get("duration_seconds", 0),
                "raw_json_path":    f"./PD-data/raw/{run_id}/{arch}_{config}.json" if json_path else None,
                "logs_zip_path":    logs_map.get((arch, config)),
                "metrics":          metrics,
                "error":            error,
            })

        final_raw_dir = raw_dir / str(run_id)
        if final_raw_dir.exists():
            shutil.rmtree(final_raw_dir)
        shutil.move(run_raw_dir, final_raw_dir)

    # Matrix jobs currently share identical bazel arguments; surface one set as a
    # single run-level record for the dashboard, from a passed job when there is one.
    passed = [key for key in build_params_map if jobs.get(key[1], {}).get("conclusion") == "success"]
    all_params = dict(build_params_map.get(next(iter(passed or build_params_map), None), {}))
    pr_number = pop_pr_number(run, all_params)
    build_params = {key: all_params[key] for key, _ in BUILD_PARAM_LABELS if key in all_params}
    missing = [key for key, _ in BUILD_PARAM_LABELS if key not in all_params]
    if passed and missing:
        # A failed job may stop before writing them; a passed one has them all, unless one is
        # no longer set in BUILD.bazel (its ORFS default applies) or no longer where it is read
        annotate("warning", f"Run {run['run_number']} (id={run_id}): build parameters "
                            f"{', '.join(missing)} not found in the {STAGE_ARGS_GLOB} files nor in "
                            f"{BUILD_PARAMS_FILENAME}: not shown on the dashboard")

    passed_flows = sum(1 for j in flows if j["conclusion"] == "success")
    run_dur     = duration_seconds(
        run.get("run_started_at", run.get("created_at", "")),
        run.get("updated_at", ""),
    )

    head_commit    = run.get("head_commit") or {}
    commit_msg     = head_commit.get("message", "")
    commit_subject = commit_msg.splitlines()[0].strip() if commit_msg else ""
    actor          = (run.get("actor") or {}).get("login", "")

    return {
        "id":               run_id,
        # Processed again when a later attempt (re-run) completes
        "run_attempt":      run.get("run_attempt", 1),
        "run_number":       run.get("run_number", 0),
        "conclusion":       run.get("conclusion", "unknown"),
        "event":            run.get("event", ""),
        "pr_number":        pr_number,
        # PR title for a pull_request run, commit subject for a push
        "display_title":    run.get("display_title", ""),
        "html_url":         run.get("html_url", ""),
        "head_branch":      run.get("head_branch", ""),
        "head_sha":         run.get("head_sha", "")[:8],
        "commit_subject":   commit_subject,
        "actor":            actor,
        "created_at":       run.get("created_at", ""),
        "duration_seconds": run_dur,
        "total_flows":       len(flows),
        "passed_flows":      passed_flows,
        "failed_flows":      len(flows) - passed_flows,
        "flows":             flows,
        "build_params":      build_params,
    }


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(
        description="Collect CVA6 physical design PPA metrics for the CI dashboard",
    )
    parser.add_argument(
        "--repo",
        default=os.environ.get("GITHUB_REPOSITORY", "openhwgroup/cva6"),
        help="GitHub repository (owner/name)",
    )
    parser.add_argument(
        "--data-dir",
        default="data",
        help="Directory to store JSON data files (default: data/)",
    )
    parser.add_argument(
        "--fetch-count",
        type=int,
        default=20,
        help="Number of recent physical design runs to fetch (default: 20)",
    )
    parser.add_argument(
        "--flow",
        required=True,
        choices=list(PD_FLOWS),
        help="Flow to collect, a key of PD_FLOWS",
    )
    parser.add_argument(
        "--default-branch",
        default=DEFAULT_BRANCH,
        help=f"Branch whose runs are the reference runs (default: {DEFAULT_BRANCH})",
    )
    parser.add_argument(
        "--nand2-area",
        type=float,
        default=ASAP7_NAND2_AREA_UM2,
        metavar="UM2",
        help=(
            f"NAND2 cell area in µm² for Kgate calculation "
            f"(default: {ASAP7_NAND2_AREA_UM2} for ASAP7 RVT)"
        ),
    )
    args = parser.parse_args()
    if not args.default_branch:
        parser.error("--default-branch is empty")
    flow = PD_FLOWS[args.flow]

    data_dir = Path(args.data_dir)
    data_dir.mkdir(parents=True, exist_ok=True)

    raw_dir = data_dir / "raw" # To store raw PD flow source files
    raw_dir.mkdir(parents=True, exist_ok=True)

    json_path = data_dir / flow["runs_file"]
    existing  = load_existing(json_path)
    print(f"Existing records: {len(existing)}")

    print(f"\nFetching runs for {flow['workflow']} from {args.repo}")
    # Records written before run_attempt was stored are attempt 1
    existing_attempts = {r["id"]: r.get("run_attempt", 1) for r in existing}
    runs_raw     = fetch_runs(args.repo, flow["workflow"], args.fetch_count)
    print(f"Fetched {len(runs_raw)} runs from API")

    new_runs = []
    for run in runs_raw:
        attempt = run.get("run_attempt", 1)
        if existing_attempts.get(run["id"], 0) >= attempt:
            print(f"  Skipping run #{run['run_number']} (id={run['id']}) - already exists")
            continue

        print(f"  Processing run #{run['run_number']} (id={run['id']}, attempt {attempt})...")
        try:
            processed = process_ci_run(args.repo, run, args.nand2_area, raw_dir, flow)
        except FetchError as exc:
            annotate("warning", f"Run {run['run_number']} (id={run['id']}) left out of this update, "
                                f"processed again by the next one: {exc}")
            continue
        new_runs.append(processed)
        print(
            f"    -> {processed['total_flows']} flows: "
            f"{processed['passed_flows']} passed, "
            f"{processed['failed_flows']} failed"
        )

    merged = merge_runs(existing, new_runs, args.default_branch)

    with open(json_path, "w") as f:
        json.dump(merged, f, indent=2)

    print(f"\nSaved {len(merged)} records to {json_path}")

    # raw/ is shared with the sibling flp/grt invocation; cleanup must keep ids
    # referenced by any PD_FLOWS runs file, not just the one just written above.
    cleanup_old_raw_files(raw_dir, all_kept_run_ids(data_dir))


if __name__ == "__main__":
    main()
