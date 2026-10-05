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

    python3 extract_PD_metrics.py \
        --artifact-prefix PD-flp- --workflow OR-flow-floorplan.yml \
        --output-file runs_PD_flp.json --data-dir /tmp/PD-data

Artifact layout expected from OR-flow-flp.yml:

    Artifact name:  PD-flp-{arch}-{config}
    Contents:       2_1_floorplan.json

Artifact layout expected from OR-flow-grt.yml:

    Artifact name:  PD-grt-{arch}-{config}
    Contents:       5_1_grt.json

Both workflows also upload a `PD-{flp,grt}-logs-{arch}-{config}` artifact
(logs, reports, and build_params.json — the latter produced by a `bazel run
... -- print-VAR` CI step, giving the exact bazel build arguments used).

The script downloads all artifacts for each run using
`gh run download` (which handles authentication and zip extraction),
then processes the extracted JSON files.
"""

import argparse
import json
import os
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

MAX_HISTORY = 50

# Maps artifact prefix to the metrics JSON filename produced inside each artifact.
METRICS_FILENAME = {
    "PD-flp-": "2_1_floorplan.json",
    "PD-grt-": "5_1_grt.json",
}

# Maps metrics artifact prefix to its corresponding logs artifact prefix.
LOGS_ARTIFACT_PREFIX = {
    "PD-flp-": "PD-flp-logs-",
    "PD-grt-": "PD-grt-logs-",
}

# Filename (written by the `Extract build parameters` CI step, via bazel-orfs'
# `print-VAR` bazel run target) holding the bazel build arguments that most
# affect PPA metrics. Read straight from the logs artifact instead of parsing
# BUILD.bazel, so it stays correct regardless of how that file is organized.
BUILD_PARAMS_FILENAME = "build_params.json"


# ---------------------------------------------------------------------------
# Metric extraction
# ---------------------------------------------------------------------------

def extract_grt_metrics(data: dict, nand2_area: float) -> dict:
    """Extract PPA metrics from a GRT-stage JSON report."""
    def get(key):
        v = data.get(key)
        if v is None:
            raise KeyError(f"Key not found in JSON: {key}")
        return v

    stdcell_area_um2 = get("globalroute__design__instance__area__stdcell")
    macro_area_um2   = get("globalroute__design__instance__area__macros")
    total_area_um2   = get("globalroute__design__instance__area")
    die_area_um2     = get("globalroute__design__die__area")
    core_area_um2    = get("globalroute__design__core__area")
    fmax_hz          = get("globalroute__timing__fmax")
    worst_slack_ps   = get("globalroute__timing__setup__ws")

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
    }


def extract_flp_metrics(data: dict, nand2_area: float) -> dict:
    """Extract PPA metrics from a floorplan-stage JSON report."""
    def get(key):
        v = data.get(key)
        if v is None:
            raise KeyError(f"Key not found in JSON: {key}")
        return v

    stdcell_area_um2 = get("floorplan__design__instance__area__stdcell")
    macro_area_um2   = get("floorplan__design__instance__area__macros")
    total_area_um2   = get("floorplan__design__instance__area")
    die_area_um2     = get("floorplan__design__die__area")
    core_area_um2    = get("floorplan__design__core__area")
    utilization      = get("floorplan__design__instance__utilization")
    fmax_hz          = get("floorplan__timing__fmax")
    worst_slack_ps   = get("floorplan__timing__setup__ws")

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
    }


# ---------------------------------------------------------------------------
# JSON persistence helpers  (mirrors .github/scripts/dashboard_tiers/collect_data.py)
# ---------------------------------------------------------------------------

def load_existing(path: Path) -> list:
    """Load existing run data from a JSON file."""
    if path.exists():
        try:
            with open(path) as f:
                return json.load(f)
        except (json.JSONDecodeError, IOError):
            print(f"WARNING: Could not read {path}, starting fresh", file=sys.stderr)
    return []


def merge_runs(existing: list, new_runs: list) -> list:
    """Merge new runs into existing data, deduplicating by run_id."""
    existing_ids = {r["id"] for r in existing}
    merged = list(existing)

    for run in new_runs:
        if run["id"] not in existing_ids:
            merged.append(run)
            existing_ids.add(run["id"])

    # Sort by created_at descending (newest first)
    merged.sort(key=lambda r: r.get("created_at", ""), reverse=True)

    # Trim to MAX_HISTORY
    return merged[:MAX_HISTORY]

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
    """Union of run ids across every runs_PD_*.json file in data_dir.

    raw/ is shared between the flp and grt invocations of this script, so
    cleanup must keep ids from both JSON files, not just the one just written.
    """
    ids = set()
    for path in data_dir.glob("runs_PD_*.json"):
        ids.update(runs_file["id"] for runs_file in load_existing(path))
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

def fetch_job_durations(repo: str, run_id: int) -> dict:
    """Return {config_name: duration_seconds} for every matrix job in a run."""
    result = subprocess.run(
        ["gh", "api", f"/repos/{repo}/actions/runs/{run_id}/jobs", "--paginate"],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        print(
            f"  WARNING: Could not fetch jobs for run {run_id}: {result.stderr}",
            file=sys.stderr,
        )
        return {}
    data = json.loads(result.stdout)
    durations = {}
    for job in data.get("jobs", []):
        name = job.get("name", "")
        dur = duration_seconds(job.get("started_at", ""), job.get("completed_at", ""))
        durations[name] = dur
    return durations


def gh_api(endpoint: str, repo: str) -> dict:
    """Call GitHub API via `gh api` and return parsed JSON."""
    url    = f"/repos/{repo}/actions/{endpoint}"
    result = subprocess.run(
        ["gh", "api", url],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        print(f"ERROR: gh api {url} failed: {result.stderr}", file=sys.stderr)
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

def iter_artifact_dirs(dest_dir: Path, prefix: str):
    """Yield (arch, config, artifact_dir) for each artifact directory matching prefix."""
        
    for artifact_dir in sorted(dest_dir.iterdir()):
        if not artifact_dir.is_dir() or not artifact_dir.name.startswith(prefix):
            continue
        suffix = artifact_dir.name[len(prefix):]
        # rsplit on "-" (last occurrence) so design names containing "-" are preserved.
        parts  = suffix.rsplit("-", 1)
        arch   = parts[0] if len(parts) >= 1 else suffix
        config = parts[1] if len(parts) >= 2 else "base"
        yield arch, config, artifact_dir


def download_run_artifacts(repo: str, run_id: int, dest_dir: Path, artifact_prefix: str) -> list:
    """Download all artifacts matching artifact_prefix for a run into dest_dir.

    Uses `gh run download` which handles authentication and zip extraction.
    Each artifact lands at dest_dir/{artifact_name}/{metrics_json}.

    Returns a list of (arch, config, json_path) tuples.
    """
    metrics_filename = METRICS_FILENAME[artifact_prefix]
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
        print(
            f"  WARNING: gh run download failed for run {run_id}: {result.stderr}",
            file=sys.stderr,
        )
        return []

    found = []
    logs_prefix = LOGS_ARTIFACT_PREFIX.get(artifact_prefix, "")
    for arch, config, artifact_dir in iter_artifact_dirs(dest_dir, artifact_prefix):
        # "PD-flp-*" also matches "PD-flp-logs-*" artifacts pulled by the same
        # `gh run download` pattern; skip those, they're handled separately.
        if logs_prefix and artifact_dir.name.startswith(logs_prefix):
            continue
        json_path = artifact_dir / metrics_filename
        if json_path.exists():
            found.append((arch, config, json_path))
            print(f"  Downloaded: {artifact_dir.name} -> {arch}/{config}")
        else:
            print(
                f"  WARNING: {metrics_filename} not found in artifact {artifact_dir.name}",
                file=sys.stderr,
            )

    return found


def download_and_zip_logs(
    repo: str,
    run_id: int,
    dest_dir: Path,
    logs_prefix: str,
    run_raw_dir: Path,
) -> tuple:
    """Download log artifacts, zip them per config.

    Returns (logs_map, build_params_map):
      logs_map:         {(arch, config): site_relative_zip_path}
      build_params_map: {(arch, config): dict of bazel build params}, read from
                         build_params.json (written by the `print-VAR` CI step)
                         when present in the artifact.
    """
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
        print(
            f"  WARNING: gh run download (logs) failed for run {run_id}: {result.stderr}",
            file=sys.stderr,
        )
        return {}, {}

    logs_map = {}
    build_params_map = {}
    for arch, config, artifact_dir in iter_artifact_dirs(dest_dir, logs_prefix):
        # Get all files in the artifact (logs + reports)
        log_files = sorted([f for f in artifact_dir.rglob("*") if f.is_file()])
        if not log_files:
            print(f"  WARNING: no .log files in artifact {artifact_dir.name}", file=sys.stderr)
            continue

        params_path = artifact_dir / BUILD_PARAMS_FILENAME
        if params_path.exists():
            try:
                with open(params_path) as f:
                    build_params_map[(arch, config)] = json.load(f)
            except (json.JSONDecodeError, IOError) as exc:
                print(f"  WARNING: could not read {params_path}: {exc}", file=sys.stderr)

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

def process_ci_run(repo: str, run: dict, nand2_area: float, raw_dir: Path, artifact_prefix: str) -> dict:
    """Fetch artifacts for a PD run, extract metrics, and build a run record."""
    run_id = run["id"]
    extractor = extract_flp_metrics if artifact_prefix == "PD-flp-" else extract_grt_metrics

    job_durations = fetch_job_durations(repo, run_id)

    # Persist raw files before the tmpdir is deleted
    run_raw_dir = raw_dir / str(run_id)
    run_raw_dir.mkdir(parents=True, exist_ok=True)

    with tempfile.TemporaryDirectory() as tmp:
        tmp_path = Path(tmp)
        json_list = download_run_artifacts(repo, run_id, tmp_path / "artifacts", artifact_prefix)

        for arch, config, json_path in json_list:
            shutil.copy2(json_path, run_raw_dir / f"{arch}_{config}.json")

        logs_prefix = LOGS_ARTIFACT_PREFIX[artifact_prefix]
        logs_map, build_params_map = download_and_zip_logs(repo, run_id, tmp_path / "logs", logs_prefix, run_raw_dir)

        json_map = {(arch, config): json_path for arch, config, json_path in json_list}

        flows = []
        for arch, config in json_map.keys() | logs_map.keys():
            json_path = json_map.get((arch, config))
            try:
                if json_path is None:
                    raise FileNotFoundError("no metrics artifact (job failed before upload)")
                with open(json_path) as f:
                    data = json.load(f)
                metrics    = extractor(data, nand2_area)
                conclusion = "success"
                timing_str = "timing met" if metrics["timing_met"] else "timing NOT met"
                print(
                    f"    [SUCCESS] {arch}/{config}  "
                    f"fmax={metrics['fmax_mhz']:.1f} MHz  "
                    f"stdcell={metrics['stdcell_area_um2']:.3f} µm²  "
                    f"({metrics['stdcell_kgate']:.2f} Kgate)  [{timing_str}]"
                )
            except (json.JSONDecodeError, KeyError, IOError, FileNotFoundError) as exc:
                print(f"    [FAILURE] {arch}/{config}: {exc}", file=sys.stderr)
                metrics    = {}
                conclusion = "failure"

            flow_dur = job_durations.get(config, 0)
            flows.append({
                "arch":             arch,
                "config":           config,
                "conclusion":       conclusion,
                "html_url":         run.get("html_url", ""),
                "duration_seconds": flow_dur,
                "raw_json_path":    f"./PD-data/raw/{run_id}/{arch}_{config}.json" if json_path else None,
                "logs_zip_path":    logs_map.get((arch, config)),
                "metrics":          metrics,
            })

    # Matrix jobs currently share identical bazel arguments; surface the first
    # available set as a single run-level record for the dashboard.
    build_params = next(iter(build_params_map.values()), {})

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
        "run_number":       run.get("run_number", 0),
        "conclusion":       run.get("conclusion", "unknown"),
        "event":            run.get("event", ""),
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
        "--workflow",
        default="OR-flow-floorplan.yml",
        help="Workflow filename to track (default: OR-flow-floorplan.yml)",
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
    parser.add_argument(
        "--artifact-prefix",
        default="PD-flp-",
        choices=list(METRICS_FILENAME),
        help="Artifact name prefix to download (default: PD-flp-)",
    )
    parser.add_argument(
        "--output-file",
        default="runs_PD_flp.json",
        help="Output JSON filename within --data-dir (default: runs_PD_flp.json)",
    )
    args = parser.parse_args()

    data_dir = Path(args.data_dir)
    data_dir.mkdir(parents=True, exist_ok=True)

    raw_dir = data_dir / "raw" # To store raw PD flow source files 
    raw_dir.mkdir(parents=True, exist_ok=True)

    json_path = data_dir / args.output_file
    existing  = load_existing(json_path)
    print(f"Existing records: {len(existing)}")

    print(f"\nFetching runs for {args.workflow} from {args.repo}")
    existing_ids = {r["id"] for r in existing}
    runs_raw     = fetch_runs(args.repo, args.workflow, args.fetch_count)
    print(f"Fetched {len(runs_raw)} runs from API")

    new_runs = []
    for run in runs_raw:
        if run["id"] in existing_ids:
            print(f"  Skipping run #{run['run_number']} (id={run['id']}) - already exists")
            continue

        print(f"  Processing run #{run['run_number']} (id={run['id']})...")
        processed = process_ci_run(args.repo, run, args.nand2_area, raw_dir, args.artifact_prefix)
        new_runs.append(processed)
        print(
            f"    -> {processed['total_flows']} flows: "
            f"{processed['passed_flows']} passed, "
            f"{processed['failed_flows']} failed"
        )

    merged = merge_runs(existing, new_runs)

    with open(json_path, "w") as f:
        json.dump(merged, f, indent=2)

    print(f"\nSaved {len(merged)} records to {json_path}")

    # raw/ is shared with the sibling flp/grt invocation; cleanup must keep ids
    # referenced by ANY runs_PD_*.json, not just the one just written above.
    cleanup_old_raw_files(raw_dir, all_kept_run_ids(data_dir))


if __name__ == "__main__":
    main()
