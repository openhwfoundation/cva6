# Copyright 2026 Thales France
#
# Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
# You may obtain a copy of the License at https://solderpad.org/licenses/
#
# Original Author: Yannick Casamatta (yannick.casamatta@thalesgroup.com)

"""
Merge every `cook_report.yml` found under `build/` into a single
pipeline report (`artifacts/reports/pipeline_report.yml`).

Cross-target recipe: it reads the reports written by the unit recipes
(published as job artifacts in CI, `when: always`) and produces the
document consumed by `report-html` and by the dashboard. It writes to
`artifacts/`, not `build/<target>/`, and follows the "no dedicated
build directory, no manifest" rule.

Testlist recipes record the report path of each of their tests in a
`report` row column: those child reports are attached to the
referencing job under a `children` key (their console `Details` log is
dropped to keep the document size reasonable), so the pipeline report
is self-contained.

Pipeline metadata comes from the CI environment when available (GitLab
CI, or the GitHub workflow wrapper variables), and falls back to local
git information otherwise, so the report can be produced and inspected
on a workstation.
"""

import os
import re
import shutil
from datetime import datetime as dt
from pathlib import Path
import yaml
import typer
from flows.utils.recipe_report import RecipeReport
from flows.utils.run_cmd import run_cmd
from flows.utils.autocompletion import autocompletion_target
from flows.utils.rtl_config import parse_rtl_cfg

app = typer.Typer()

REPORTS_DIR = Path("artifacts") / "reports"
PIPELINE_REPORT = "pipeline_report.yml"

# Bit fields yielding a label when set, in display order. They all belong to
# the "ext" group, the width, the bus and the memory ones being built apart.
CFG_EXTENSIONS = [
    ("ZCMT", "RVZCMT"),
    ("ZCB", "RVZCB"),
    ("ZCMP", "RVZCMP"),
    ("ZIFENCEI", "RVZifencei"),
    ("ZICOND", "RVZiCond"),
    ("ZICNTR", "RVZicntr"),
    ("ZIHPM", "RVZihpm"),
    ("ZKN", "ZKN"),
    ("A", "RVA"),
    ("B", "RVB"),
    ("C", "RVC"),
    ("F", "RVF"),
    ("D", "RVD"),
    ("V", "RVV"),
    ("H", "RVH"),
    ("S", "RVS"),
    ("U", "RVU"),
]

# Write policy of the data cache, config_pkg::cache_type_t
CFG_DCACHE_TYPE = {
    "WB": "WB",
    "WT": "WT",
    "HPDCACHE_WT": "WT",
    "HPDCACHE_WB": "WB",
    "HPDCACHE_WT_WB": "WT/WB",
}

# unsigned'(8), bit'(1), int'(config_pkg::OBI_V1_6)
CFG_FIELD_RE = re.compile(r"^\s*(\w+)\s*:\s*\w+'\(\s*([^)]*?)\s*\)\s*,?\s*$")
# DCacheType: config_pkg::HPDCACHE_WT,  (no type cast)
CFG_ENUM_RE = re.compile(r"^\s*(\w+)\s*:\s*(?:config_pkg::)?(\w+)\s*,?\s*$")
CFG_LOCALPARAM_RE = re.compile(r"^\s*localparam\s+(\w+)\s*=\s*([^;]+);")


# ==========================================================
# TARGET CONFIGURATION
# ==========================================================


def _read_target_config(repo_dir, target):
    """Summarise config/target/<target>/rtl_cfg_pkg.sv as display labels.

    The file is SystemVerilog, so the fields are matched textually rather
    than parsed: only the simple `Name: type'(value),` form is needed, plus
    the localparams the config refers to for XLEN.

    Each label carries the group it belongs to, so the report can colour the
    width, the bus, the features of the core (DCLS), the memory subsystem
    and the extensions apart.
    """
    cfg_file = repo_dir / "config" / "target" / target / "rtl_cfg_pkg.sv"
    try:
        text = cfg_file.read_text(encoding="utf-8")
    except OSError:
        return None

    consts, fields, enums = {}, {}, {}
    for line in text.splitlines():
        m = CFG_LOCALPARAM_RE.match(line)
        if m:
            consts[m.group(1)] = m.group(2).strip()
            continue
        m = CFG_FIELD_RE.match(line)
        if m:
            fields[m.group(1)] = m.group(2).strip()
            continue
        m = CFG_ENUM_RE.match(line)
        if m:
            enums[m.group(1)] = m.group(2).strip()

    def value(name):
        raw = fields.get(name)
        if raw is None:
            return None
        raw = consts.get(raw, raw)
        try:
            return int(raw, 0)
        except (TypeError, ValueError):
            return raw

    labels = []
    xlen = value("XLEN")
    if isinstance(xlen, int):
        labels.append({"text": f"RV{xlen}", "group": "xlen"})

    # PipelineOnly replaces the caches and the AXI interface by OBI, so a
    # DCacheType is still declared there but drives nothing
    pipeline_only = bool(value("PipelineOnly"))
    labels.append({"text": "OBI" if pipeline_only else "AXI", "group": "bus"})
    if not pipeline_only:
        policy = CFG_DCACHE_TYPE.get(enums.get("DCacheType", ""))
        if policy:
            labels.append({"text": policy, "group": "mem"})

    # Dual-core lockstep: a shadow core runs a few cycles behind the main
    # one and their outputs are compared, which doubles the core
    if value("DclsEn"):
        labels.append({"text": "DCLS", "group": "feat"})

    if isinstance(value("MmuPresent"), int) and value("MmuPresent") > 0:
        labels.append({"text": "MMU", "group": "mem"})
    if isinstance(value("NrPMPEntries"), int) and value("NrPMPEntries") > 0:
        labels.append({"text": "PMP", "group": "mem"})

    for text_, field in CFG_EXTENSIONS:
        val = value(field)
        if isinstance(val, int) and val > 0:
            labels.append({"text": text_, "group": "ext"})
    return labels or None


def _child_paths(doc):
    """build/-relative report paths referenced by the rows of a report.

    Testlist recipes record the report of each of their tests in a
    `report` row column (an absolute path); it is normalized to the
    build/-relative path used as collection key.
    """
    paths = set()
    for metric in doc.get("metrics") or []:
        if metric.get("kind") != "rows":
            continue
        for row in metric.get("data") or []:
            ref = row.get("report")
            if not isinstance(ref, str) or not ref:
                continue
            ref = ref.replace("\\", "/")
            idx = ref.rfind("/build/")
            paths.add(ref[idx + 1 :] if idx >= 0 else ref)
    return paths


def _read_target_parameters(repo_dir, target, report):
    """
    Return the RTL parameters of a target, as name -> displayable value.

    The whole configuration package, not the handful of labels
    `_read_target_config` derives: the dashboard shows it as a collapsible
    table, so a reader can check what a target actually is without opening
    its `rtl_cfg_pkg.sv`.

    Read through the shared parser (`flows/utils/rtl_config.py`), the one
    `docs-build` and `hwconfig-forge` use. Values are made displayable here
    rather than in the template: a list of sixteen PMP entries is a string
    the browser only has to print.
    """
    path = repo_dir / "config" / "target" / target / "rtl_cfg_pkg.sv"
    if not path.exists():
        return None
    try:
        config = parse_rtl_cfg(path)
    except OSError as e:
        report.warning(f"Could not read {path}: {e}")
        return None

    displayable = {}
    for name, value in config.items():
        if isinstance(value, bool):
            displayable[name] = "true" if value else "false"
        elif isinstance(value, list):
            # An array of identical values is the common case (one entry per
            # PMP region): collapsed so the table stays readable.
            unique = set(map(str, value))
            displayable[name] = (
                f"{len(value)} x {unique.pop()}"
                if len(unique) == 1
                else ", ".join(str(v) for v in value)
            )
        else:
            displayable[name] = str(value)
    return displayable


def _target_documents(jobs, repo_dir, docs_dir, report):
    """
    Collect the specifications `docs-build` produced, per target.

    The documents are read from the report of that recipe, which already
    records the manual, the format and the file of each: the merge does not
    have to know how the documentation is built, only that a target has one.

    They are copied next to the pipeline report rather than linked in place,
    because the dashboard is published on its own (GitLab Pages serves
    `public/`, not the build tree) and a link into `build/` would be dead
    there. The template links to them from the top of the detail of their
    target; the verdict of the job itself is a `Doc` column of the matrix.
    The layout mirrors the link the template builds:

        artifacts/reports/docs/<target>/<document>

    Returns `{target: [{"manual", "format", "file"}]}`.
    """
    documents = {}
    for job in jobs:
        if job.get("recipe") != "docs-build":
            continue
        target = (job.get("context") or {}).get("target")
        if not isinstance(target, str) or not target:
            continue
        for metric in job.get("metrics") or []:
            if metric.get("name") != "Specifications":
                continue
            for row in metric.get("data") or []:
                if row.get("status") != "pass" or not row.get("document"):
                    continue
                documents.setdefault(target, []).append(
                    {
                        "manual": row.get("manual") or "",
                        "format": row.get("format") or "",
                        "file": row["document"],
                    }
                )

    if not documents:
        return {}

    # The Sphinx user manual is not per target: only the specifications
    # are collected here.
    copied = 0
    for target, entries in documents.items():
        source_dir = repo_dir / "build" / target / "docs"
        target_dir = docs_dir / target
        for entry in entries:
            source = source_dir / entry["file"]
            if not source.is_file():
                report.warning(f"Specification not found, skipping: {source}")
                continue
            try:
                target_dir.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(source, target_dir / entry["file"])
                copied += 1
            except OSError as e:
                report.warning(f"Could not publish {source}: {e}")

    # Drop the entries whose document could not be copied: a link the
    # dashboard cannot follow is worse than no link.
    for target in list(documents):
        documents[target] = [
            entry
            for entry in documents[target]
            if (docs_dir / target / entry["file"]).is_file()
        ]
        if not documents[target]:
            del documents[target]

    if copied:
        report.success(f"{copied} specification(s) published next to the report")
    return documents


def _strip_workdir(value, prefixes):
    """
    Drop the cook.py working directory from every path of `value`.

    Reports are written with absolute paths, which on a runner carry the
    whole checkout directory (/gitlab-runner/.../builds/<hash>/<n>/...):
    noise in the dashboard, and it changes between two pipelines of the same
    commit, so two reports cannot be diffed. Only the working directory is
    stripped, so a path outside it (a CAD tool, a shared toolchain) stays
    absolute, since that one carries information.

    `prefixes` are the working directory forms *without* trailing slash: a
    path below it becomes relative, the bare directory becomes ".".

    Walks the document recursively; non-string leaves are returned as is.
    """
    if isinstance(value, dict):
        return {k: _strip_workdir(v, prefixes) for k, v in value.items()}
    if isinstance(value, list):
        return [_strip_workdir(v, prefixes) for v in value]
    if isinstance(value, str):
        for prefix in prefixes:
            value = value.replace(prefix + "/", "")
            value = value.replace(prefix, ".")
        return value
    return value


def _collect_reports(repo_dir, target, report):
    """Load every build/**/cook_report.yml, filtered by target if given."""
    reports = {}
    for path in sorted((repo_dir / "build").rglob("cook_report.yml")):
        rel = path.relative_to(repo_dir).as_posix()
        try:
            with path.open("r", encoding="utf-8") as f:
                doc = yaml.safe_load(f)
        except Exception as e:
            report.warning(f"Skipping unreadable report {rel}: {e}")
            continue
        if not isinstance(doc, dict):
            report.warning(f"Skipping invalid report {rel}")
            continue
        if target and (doc.get("context") or {}).get("target") != target:
            continue
        reports[rel] = doc
    return reports


def _merge_jobs(reports):
    """Split reports into parent jobs and attach the child reports.

    A report referenced by a `report` row column of another report
    (written by a testlist recipe for each of its tests) is attached to
    the referencing job under `children`, keyed by its build/-relative
    path — the same path recorded in the parent row, which the HTML
    template uses to bind the row to the child report. Their `Details`
    console log is dropped.
    """
    parent_of = {}
    for path, doc in reports.items():
        for ref in _child_paths(doc):
            if ref in reports and ref != path:
                parent_of[ref] = path
    jobs = []
    for path, doc in reports.items():
        parent_path = parent_of.get(path)
        if parent_path is None:
            doc["report_path"] = path
            jobs.append(doc)
        else:
            doc["metrics"] = [
                m for m in doc.get("metrics") or [] if m.get("name") != "Details"
            ]
            reports[parent_path].setdefault("children", {})[path] = doc
    return jobs


# ==========================================================
# PIPELINE METADATA
# ==========================================================


def _sanitize_title(subject):
    "Truncate the commit subject and strip HTML-injection characters"
    title = subject if len(subject) <= 60 else subject[:60] + "..."
    return re.sub("[<>\n]", "", title)


def _git(args, report):
    "Best-effort git query for local (non-CI) pipeline metadata"
    out = run_cmd(
        cmd=["git"] + args,
        report=report,
        check=False,
        capture_output=True,
        timeout=60,
    )
    return (out or "").strip()


def _pipeline_metadata(report):
    """Pipeline identity: CI environment when available, local git otherwise."""
    env = os.environ
    now = int(dt.now().timestamp())

    if not (env.get("GITLAB_CI") or env.get("GITHUB_ACTIONS")):
        sha = _git(["rev-parse", "HEAD"], report)
        branch = _git(["rev-parse", "--abbrev-ref", "HEAD"], report)
        return {
            "workflow_uid": "local",
            "workflow_repo": "cva6",
            "workflow_action": "local",
            "pipeline_url": "",
            "timestamp": now,
            "runtime": 0,
            "title": _sanitize_title(_git(["log", "-1", "--format=%s"], report)),
            "description": "",
            "ref_name": branch,
            "sha": sha,
            "author": _git(["log", "-1", "--format=%an <%ae>"], report),
            "env": {
                "cva6": {"sha": sha, "branch": branch},
                "core-v-verif": {"sha": "0000000", "branch": "none"},
            },
        }

    created_at = env.get("CI_PIPELINE_CREATED_AT")
    try:
        timestamp = int(dt.strptime(created_at, "%Y-%m-%dT%H:%M:%S%z").timestamp())
    except (TypeError, ValueError):
        timestamp = now

    workflow_type = env.get("WORKFLOW_TYPE", "gitlab").strip("'\"")
    if workflow_type == "github":  # from the GitHub workflow wrapper
        uid = env.get("WORKFLOW_RUN_ID", "").strip("'\"")
        repo = (
            "cva6"
            if env.get("CI_COMMIT_REF_NAME") == "master"
            else env.get("CI_COMMIT_REF_NAME", "")
        )  # cvv or cva6
        subject = env.get("WORKFLOW_COMMIT_MESSAGE", "").strip("'\"")
        author = env.get("WORKFLOW_COMMIT_AUTHOR", "").strip("'\"")
        cvv = {
            "branch": env.get("CORE_V_VERIF_BRANCH", "").strip("'\""),
            "sha": env.get("CORE_V_VERIF_HASH", "").strip("'\""),
        }
        cva6 = {
            "branch": env.get("CVA6_BRANCH", "").strip("'\""),
            "sha": env.get("CVA6_HASH", "").strip("'\""),
        }
    else:  # plain GitLab pipeline
        uid = env.get("CI_PIPELINE_ID", "").strip("'\"")
        repo = "cva6"
        subject = env.get("CI_COMMIT_MESSAGE", "").strip("'\"")
        author = env.get("CI_COMMIT_AUTHOR", "").strip("'\"")
        cvv = {"branch": "none", "sha": "0000000"}
        cva6 = {
            "branch": env.get("CI_COMMIT_REF_NAME", "").strip("'\""),
            "sha": env.get("CI_COMMIT_SHA", "").strip("'\""),
        }

    head = cva6 if repo == "cva6" else cvv
    return {
        "workflow_uid": uid,
        "workflow_repo": repo,
        "workflow_action": env.get("CI_PIPELINE_SOURCE", "").strip("'\""),
        "pipeline_url": env.get("CI_PIPELINE_URL", ""),
        "timestamp": timestamp,
        "runtime": now - timestamp,
        "title": _sanitize_title(subject),
        "description": "",
        "ref_name": head["branch"],
        "sha": head["sha"],
        "author": author,
        "env": {"cva6": cva6, "core-v-verif": cvv},
    }


# ==========================================================
# RECIPE
# ==========================================================


@app.command()
def merge_reports(
    target: str = typer.Option(
        None,
        "--target",
        "-t",
        help="Only merge the reports of this target (default: all)",
        autocompletion=autocompletion_target,
    ),
    quiet: bool = typer.Option(
        False, "--quiet", "-q", help="Suppress output (errors only)"
    ),
):
    """
    Merge all job reports into artifacts/reports/pipeline_report.yml
    """
    report = RecipeReport(
        "merge-reports",
        title="MERGE JOB REPORTS",
        context={"target": target},
        quiet=quiet,
    )
    repo_dir = Path.cwd()
    out_file = repo_dir / REPORTS_DIR / PIPELINE_REPORT

    # ==========================================================
    # COLLECT JOB REPORTS
    # ==========================================================
    report.step("Collect job reports")
    reports = _collect_reports(repo_dir, target, report)
    if not reports:
        report.error_exit("No cook_report.yml found under build/", env=True)
    jobs = _merge_jobs(reports)
    report.success(f"Found {len(reports)} report(s), {len(jobs)} job(s)")

    # ==========================================================
    # BUILD PIPELINE DOCUMENT
    # ==========================================================
    report.step("Build pipeline report")
    n_pass = sum(1 for j in jobs if j.get("status") == "pass")
    pipeline = _pipeline_metadata(report)
    pipeline["token"] = "YC" + str(pipeline["timestamp"])
    pipeline["status"] = "pass" if n_pass == len(jobs) else "fail"
    pipeline["label"] = f"{n_pass}/{len(jobs)} PASS"
    pipeline["jobs_pass"] = n_pass
    pipeline["jobs_total"] = len(jobs)
    pipeline["jobs"] = jobs

    # Summarise the configuration of every target the jobs ran on, so the
    # report can show what a target actually is without opening its
    # rtl_cfg_pkg.sv
    targets = {
        (job.get("context") or {}).get("target")
        for job in jobs
        if isinstance((job.get("context") or {}).get("target"), str)
    }
    target_cfg = {}
    target_params = {}
    for name in sorted(t for t in targets if t):
        labels = _read_target_config(repo_dir, name)
        if labels:
            target_cfg[name] = labels
        # The whole configuration package too: the dashboard shows it as a
        # collapsible table in the detail of the target.
        params = _read_target_parameters(repo_dir, name, report)
        if params:
            target_params[name] = params
    if target_cfg:
        pipeline["target_config"] = target_cfg
        report.success(f"Configuration read for {len(target_cfg)} target(s)")
    if target_params:
        pipeline["target_parameters"] = target_params
        report.success(f"RTL parameters read for {len(target_params)} target(s)")

    # Specifications of the targets that have one, copied next to the
    # report so the dashboard can link to them (see _target_documents)
    target_docs = _target_documents(
        jobs, repo_dir, repo_dir / REPORTS_DIR / "docs", report
    )
    if target_docs:
        pipeline["target_docs"] = target_docs

    # The job verdict is recorded under `result`, not `status`: a fail
    # row must not fail the merge recipe itself (only collection errors do)
    recap = report.metric("Merged job reports")
    for job in jobs:
        recap.add_row(
            result=job.get("status"),
            stage=job.get("job_stage_name") or "",
            recipe=job.get("recipe") or "",
            target=(job.get("context") or {}).get("target") or "",
            label=job.get("label") or "",
        )
    report.print_metric(recap)

    # The pipeline verdict does not fail the merge itself: this recipe
    # succeeds as long as the reports were collected and merged.
    if pipeline["status"] == "pass":
        report.success(f"Pipeline PASS ({pipeline['label']})")
    else:
        report.warning(f"Pipeline FAIL ({pipeline['label']})")

    # ==========================================================
    # WRITE PIPELINE REPORT
    # ==========================================================
    report.step("Write pipeline report")
    # Paths are relative to the working directory in the merged report: the
    # checkout directory of a runner is noise, and it differs between two
    # pipelines of the same commit. The resolved form is stripped too, as a
    # recipe may record either when the checkout is reached through a symlink.
    prefixes = {
        repo_dir.as_posix().rstrip("/"),
        repo_dir.resolve().as_posix().rstrip("/"),
    }
    pipeline = _strip_workdir(pipeline, sorted(prefixes, key=len, reverse=True))
    try:
        out_file.parent.mkdir(parents=True, exist_ok=True)
        with out_file.open("w", encoding="utf-8") as f:
            yaml.dump(pipeline, f)
    except OSError as e:
        report.error_exit(f"Could not write {out_file}: {e}", env=True)
    report.success(f"Pipeline report written: {out_file}")
    report.log("Generated files", [str(out_file)])

    report.end("Completed")
