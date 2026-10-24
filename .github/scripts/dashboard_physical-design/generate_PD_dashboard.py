#!/usr/bin/env python3
# Copyright 2026 OpenHW Group
# SPDX-License-Identifier: Apache-2.0
"""Generate CVA6 PD dashboard HTML from collected JSON data.

Reads per-workflow JSON files and renders a Jinja2 template into
a self-contained static HTML file.
"""

import argparse
import copy
import json
import os
from datetime import datetime, timezone
from pathlib import Path
from collections import defaultdict
from zoneinfo import ZoneInfo

from jinja2 import Environment, FileSystemLoader, StrictUndefined

# Same flows and run classification as the collected data (script in this directory)
from extract_PD_metrics import BUILD_PARAM_LABELS, DEFAULT_BRANCH, PD_FLOWS, is_reference_run

# Presentation of the PD_FLOWS flows, in display order.
# chart_metrics: metric keys to extract from each flow's metrics dict.
# type: passed to template to select which charts to render.
WORKFLOWS = [
    {
        "key":           "flp",
        "type":          "Floorplan",
        "chart_metrics": ["fmax_mhz", "stdcell_kgate", "worst_setup_slack_ps", "power_mw"],
    },
    {
        "key":           "grt",
        "type":          "GRT",
        "chart_metrics": ["fmax_mhz", "stdcell_kgate", "worst_setup_slack_ps", "power_mw"],
    },
]
if {wf["key"] for wf in WORKFLOWS} != set(PD_FLOWS):
    raise SystemExit("WORKFLOWS must list the flows of PD_FLOWS (extract_PD_metrics.py)")
for wf in WORKFLOWS:
    wf["file"] = PD_FLOWS[wf["key"]]["runs_file"]
    wf["display_name"] = Path(PD_FLOWS[wf["key"]]["workflow"]).stem  # e.g. "OR-flow-floorplan"

TREND_COUNT = 20

# Optional fields of the run and flow records, with their value when missing:
# records written before a field existed lack it. The template is rendered with
# StrictUndefined, so that a misspelled or removed field fails the generation
# instead of rendering empty: a field it reads must be in every record, or here.
RUN_DEFAULTS = {
    "event":          "",
    "actor":          "",
    "commit_subject": "",
    "display_title":  "",
    "pr_number":      None,
    "build_params":   {},
    "flows":          [],
}
FLOW_DEFAULTS = {
    "raw_json_path": None,
    "logs_zip_path": None,
    "error":         None,
}


def format_duration(seconds: int) -> str:
    """Format seconds into human-readable duration."""
    if seconds <= 0:
        return "N/A"
    minutes = seconds // 60
    secs = seconds % 60
    if minutes >= 60:
        hours = minutes // 60
        mins = minutes % 60
        return f"{hours}h {mins}m"
    return f"{minutes}m {secs}s"


def format_datetime(iso_str: str) -> str:
    """Format ISO datetime to readable string (Paris time)."""
    if not iso_str:
        return "N/A"
    try:
        dt = datetime.fromisoformat(iso_str.replace("Z", "+00:00"))
        # Convert UTC to Paris time
        paris_tz = ZoneInfo("Europe/Paris")
        dt_paris = dt.astimezone(paris_tz)
        return dt_paris.strftime("%Y-%m-%d %H:%M %Z")
    except (ValueError, TypeError):
        return iso_str


def load_workflow_data(data_dir: Path) -> dict:
    """Load all workflow JSON data files.

    Missing files are treated as empty runs (logs a warning) so the dashboard
    can be generated even when only one workflow has executed so far.

    Raises:
        FileNotFoundError: If the data directory itself doesn't exist.
        json.JSONDecodeError: If a JSON file is malformed.
    """
    result = {}

    # Check if data directory exists
    if not data_dir.exists():
        raise FileNotFoundError(
            f"Data directory not found: {data_dir.resolve()}\n"
            f"  Create it or use --data-dir to specify the correct path."
        )

    for wf in WORKFLOWS:
        path = data_dir / wf["file"]

        if not path.exists():
            print(
                f"WARNING: {wf['file']} not found in {data_dir.resolve()} — "
                f"treating {wf['display_name']} as having no runs yet.",
                file=__import__('sys').stderr,
            )
            result[wf["key"]] = []
            continue

        try:
            with open(path, 'r', encoding='utf-8') as f:
                data = json.load(f, parse_float=lambda x: round(float(x), 2))
                if not isinstance(data, list):
                    raise ValueError(
                        f"Expected JSON array (list of runs) in {path.name}, "
                        f"but got {type(data).__name__}"
                    )
                result[wf["key"]] = data
                print(f"Loaded {len(data)} runs from {path.name}")
        except json.JSONDecodeError as e:
            raise json.JSONDecodeError(
                f"Invalid JSON in {path.resolve()}: {e.msg} at line {e.lineno}, col {e.colno}",
                e.doc,
                e.pos
            )
        except (IOError, OSError) as e:
            raise IOError(
                f"Cannot read {path.resolve()}: {e.strerror}\n"
                f"  Check file permissions and ensure the file is readable."
            )

    return result


def flow_key_of(flow: dict) -> str:
    """Key identifying a flow across runs, e.g. "RV32_cv32a65x"."""
    return f"{flow['arch']}_{flow['config']}"


def build_chart_data(all_data: dict, default_branch: str) -> dict:
    """Build Chart.js data for trend charts."""
    chart_data = {}

    for wf in WORKFLOWS:
        key          = wf["key"]
        chart_metrics = wf["chart_metrics"]
        # Trends follow the reference history: PR runs are not part of it
        runs = [r for r in all_data.get(key, []) if is_reference_run(r, default_branch)]

        # Take last TREND_COUNT runs, reversed for chronological order
        trend_runs = list(reversed(runs[:TREND_COUNT]))

        labels = []

        # Use defaultdict to avoid pre-initializing all possible flow keys.
        series = defaultdict(lambda: {m: [] for m in chart_metrics})

        # Collect all unique flow keys (first pass)
        all_flow_keys = set()
        for run in trend_runs:
            for flow in run.get("flows", []):
                all_flow_keys.add(flow_key_of(flow))

        # Process each run (second pass)
        for run in trend_runs:
            labels.append(str(run.get("run_number", "")))

            # Build O(1) lookup dict for flows in this run
            flow_dict = {}
            for flow in run.get("flows", []):
                flow_dict[flow_key_of(flow)] = flow.get("metrics", {})

            # For each flow_key, append metric or None
            for flow_key in all_flow_keys:
                if flow_key in flow_dict:
                    metrics = flow_dict[flow_key]
                    for m in chart_metrics:
                        series[flow_key][m].append(metrics.get(m))
                else:
                    # Flow absent from this run: fill with None
                    for m in chart_metrics:
                        series[flow_key][m].append(None)


        chart_data[key] = {
            "labels": labels,
            "series": dict(series),
        }

    return chart_data


def enrich_run(run: dict) -> dict:
    """Add display-friendly fields to a run dict, and the missing optional ones."""
    for key, default in RUN_DEFAULTS.items():
        run.setdefault(key, copy.copy(default))
    run["duration_display"] = format_duration(run.get("duration_seconds", 0))
    run["created_at_display"] = format_datetime(run.get("created_at", ""))
    for flow in run["flows"]:
        for key, default in FLOW_DEFAULTS.items():
            flow.setdefault(key, default)
        flow["duration_display"] = format_duration(flow.get("duration_seconds", 0))
    build_params = run.get("build_params") or {}
    run["build_params_display"] = [
        {"label": label, "value": build_params[key]}
        for key, label in BUILD_PARAM_LABELS
        if key in build_params
    ]
    return run


def _delta(current, previous, relative: bool = False) -> dict | None:
    """Return signed delta info between two numeric metric values.

    relative: delta in % of the previous value instead of in the metric's unit.
    """
    if current is None or previous is None:
        return None
    try:
        d = float(current) - float(previous)
        if relative:
            d = d / float(previous) * 100
        d = round(d, 2)
        return {"value": d, "sign": "+" if d >= 0 else ""}
    except (TypeError, ValueError, ZeroDivisionError):
        return None


def baseline_flow(run: dict, ref_runs: list, flow_key: str) -> tuple:
    """(reference run, flow) that the `flow_key` flow of `run` is compared to.

    The latest reference run created before `run` (`run` itself excluded) where
    this flow succeeded: a config failing on the reference branch is compared to
    its last good metrics. (None, None) when there is no such run.
    """
    for ref in ref_runs:  # newest first
        if ref["id"] == run.get("id") or ref.get("created_at", "") > run.get("created_at", ""):
            continue
        for flow in ref.get("flows", []):
            if flow_key_of(flow) == flow_key and flow.get("conclusion") == "success" and flow.get("metrics"):
                return ref, flow
    return None, None


def metric_deltas(m: dict, prev: dict, baseline) -> dict:
    """Deltas of metrics `m` vs `prev`, the metrics of the `baseline` run.

    Holds the "baseline" run and one _delta() per metric, None when either side
    lacks the value.
    """
    return {
        "baseline": baseline,
        "fmax_mhz": _delta(m.get("fmax_mhz"), prev.get("fmax_mhz")),
        "stdcell_kgate": _delta(m.get("stdcell_kgate"), prev.get("stdcell_kgate")),
        # In %: in µm², it would just repeat the stdcell delta (the macros don't change)
        "total_instance_area_um2": _delta(m.get("total_instance_area_um2"),
                                          prev.get("total_instance_area_um2"), relative=True),
        "worst_setup_slack_ps": _delta(m.get("worst_setup_slack_ps"), prev.get("worst_setup_slack_ps")),
        "power_mw": _delta(m.get("power_mw"), prev.get("power_mw")),
    }


# For a flow without a flow_deltas() entry: every key of a metric_deltas() entry, all None
NO_DELTAS = metric_deltas({}, {}, None)


def flow_deltas(run: dict, ref_runs: list) -> dict:
    """{flow key: metric_deltas() vs its baseline flow} for every flow of `run`."""
    deltas = {}
    for flow in run.get("flows", []):
        flow_key = flow_key_of(flow)
        ref, ref_flow = baseline_flow(run, ref_runs, flow_key)
        m = flow.get("metrics") or {}
        prev = ref_flow["metrics"] if ref_flow else {}
        deltas[flow_key] = metric_deltas(m, prev, ref)
    return deltas


def build_workflows_context(all_data: dict, default_branch: str) -> list:
    """Build the workflows list for the template context."""
    workflows = []
    for wf in WORKFLOWS:
        key = wf["key"]
        runs = all_data.get(key, [])

        # Enrich all runs
        for run in runs:
            enrich_run(run)

        # Reference runs make the history; candidate runs (PRs, other branches)
        # are each compared to them
        ref_runs       = [r for r in runs if is_reference_run(r, default_branch)]
        candidate_runs = [r for r in runs if not is_reference_run(r, default_branch)]

        # Build latest run summary (or placeholder)
        if ref_runs:
            latest = ref_runs[0]
        else:
            latest = enrich_run({
                "conclusion": "unknown",
                "head_branch": "N/A",
                "head_sha": "N/A",
                "passed_flows": 0,
                "failed_flows": 0,
                "total_flows": 0,
                "run_number": 0,
                "html_url": "#",
            })

        # Reference runs (latest run card, run history) are each compared to the
        # previous reference run, candidate runs to the latest one before them
        for run in (ref_runs or [latest]) + candidate_runs:
            run["flow_deltas"] = flow_deltas(run, ref_runs)
            # Distinct reference runs compared to, newest first (usually a single one)
            baselines = {d["baseline"]["id"]: d["baseline"]
                         for d in run["flow_deltas"].values() if d["baseline"]}
            run["baselines"] = sorted(baselines.values(), key=lambda r: r.get("created_at", ""), reverse=True)

        workflows.append(
            {
                "key": key,
                "type": wf["type"],
                "display_name": wf["display_name"],
                "latest": latest,
                "runs": ref_runs,
                "candidate_runs": candidate_runs,
            }
        )

    return workflows


def main():
    parser = argparse.ArgumentParser(
        description="Generate CVA6 CI Dashboard HTML"
    )
    parser.add_argument(
        "--data-dir",
        default="data",
        help="Directory containing JSON data files",
    )
    parser.add_argument(
        "--output-dir",
        default="site",
        help="Output directory for generated HTML",
    )
    parser.add_argument(
        "--repo",
        default=os.environ.get("GITHUB_REPOSITORY", "openhwgroup/cva6"),
        help="GitHub repository (owner/name)",
    )
    parser.add_argument(
        "--default-branch",
        default=DEFAULT_BRANCH,
        help=f"Branch whose runs are the reference runs (default: {DEFAULT_BRANCH})",
    )
    args = parser.parse_args()
    if not args.default_branch:
        parser.error("--default-branch is empty")

    data_dir = Path(args.data_dir)
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    # Load data
    try:
        all_data = load_workflow_data(data_dir)
    except FileNotFoundError as e:
        print(f"ERROR: {e}", file=__import__('sys').stderr)
        return 1
    except json.JSONDecodeError as e:
        print(f"JSON ERROR: {e}", file=__import__('sys').stderr)
        return 1
    except IOError as e:
        print(f"READ ERROR: {e}", file=__import__('sys').stderr)
        return 1
    except Exception as e:
        print(f"UNEXPECTED ERROR: {e}", file=__import__('sys').stderr)
        return 1

    # Build template context
    now = datetime.now(timezone.utc)
    workflows = build_workflows_context(all_data, args.default_branch)
    chart_data = build_chart_data(all_data, args.default_branch)

    context = {
        "generated_at": format_datetime(now.isoformat()),
        "year": now.year,
        "repo": args.repo,
        "default_branch": args.default_branch,
        "no_deltas": NO_DELTAS,
        "workflows": workflows,
        "chart_data": chart_data,
        "trend_count": TREND_COUNT
    }

    # Render template
    template_dir = Path(__file__).parent / "templates"
    # StrictUndefined: a missing variable or field is an error, not an empty string
    env = Environment(loader=FileSystemLoader(str(template_dir)), autoescape=True,
                      undefined=StrictUndefined)
    template = env.get_template("PD_dashboard.html")
    html = template.render(**context)

    # Write output
    output_file = output_dir / "PD_dashboard.html"
    with open(output_file, "w") as f:
        f.write(html)

    print(f"Dashboard generated: {output_file}")
    print(f"  Workflows: {len(workflows)}")
    for wf in workflows:
        print(f"    - {wf['display_name']}: {len(wf['runs'])} {args.default_branch} runs, "
              f"{len(wf['candidate_runs'])} PR/branch runs")

    return 0


if __name__ == "__main__":
    import sys
    sys.exit(main())
