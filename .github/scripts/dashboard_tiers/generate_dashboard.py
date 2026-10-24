#!/usr/bin/env python3
# Copyright 2026 OpenHW Group
# SPDX-License-Identifier: Apache-2.0
"""Generate CVA6 tier dashboard HTML from collected JSON data.

Reads per-workflow JSON files and renders a Jinja2 template into
a self-contained static HTML file.
"""

import argparse
import json
import os
import shutil
from datetime import datetime, timezone
from pathlib import Path

from jinja2 import Environment, FileSystemLoader

# Workflow display info (order matters for UI)
WORKFLOW_INFO = [
    {"key": "ci", "display_name": "ci.yml (Reference)", "file": "runs_ci.json"},
    {"key": "tier1", "display_name": "Tier 1", "file": "runs_tier1.json"},
    {"key": "tier2", "display_name": "Tier 2", "file": "runs_tier2.json"},
]

# Preferred display order for configs and test suites in the matrix.
# Any configs/suites not listed here but found in the data will be
# appended at the end automatically.
MATRIX_CONFIGS_ORDER = [
    "cv32a65x",
    "cv32a60x",
    "cv64a6_imafdc_sv39_hpdcache_wb",
    "cv64a6_imafdc_sv39_hpdcache",
    "cv64a6_imafdc_sv39_wb",
    "cv64a6_imafdc_sv39",
]

MATRIX_SUITES_ORDER = [
    "smoke-tests-cv32a65x",
    "cv32a6_tests",
    "cv64a6_imafdc_tests",
    "dv-riscv-arch-test",
    "dv-riscv-tests-p",
    "dv-riscv-tests-v",
    "dv-riscv-compliance",
    "dv-riscv-csr-access-test",
    "benchmark",
]

TREND_COUNT = 20


def is_valid_matrix_job(job: dict) -> bool:
    """Return True if a job has usable config/testcase for matrix rendering."""
    config = job.get("config", "")
    testcase = job.get("testcase", "")
    if not config or not testcase:
        return False
    if "${{" in config or "${{" in testcase:
        return False
    return True


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
    """Format ISO datetime to readable string."""
    if not iso_str:
        return "N/A"
    try:
        dt = datetime.fromisoformat(iso_str.replace("Z", "+00:00"))
        return dt.strftime("%Y-%m-%d %H:%M UTC")
    except (ValueError, TypeError):
        return iso_str


def load_workflow_data(data_dir: Path) -> dict:
    """Load all workflow JSON data files."""
    result = {}
    for wf in WORKFLOW_INFO:
        path = data_dir / wf["file"]
        if path.exists():
            with open(path) as f:
                result[wf["key"]] = json.load(f)
        else:
            result[wf["key"]] = []
    return result


def build_matrix(all_data: dict) -> tuple:
    """Build unified config x testsuite matrix from ALL workflows.

    Each cell is a dict keyed by workflow name, e.g.:
        matrix["cv64a6_imafdc_sv39_hpdcache_wb"]["dv-riscv-arch-test"] = {
            "ci": {"conclusion": "success", "html_url": "..."},
            "tier2": {"conclusion": "success", "html_url": "..."},
        }

    Returns: (matrix_data, configs_used, suites_used)
    """
    # matrix[config][testcase][workflow_key] = {conclusion, html_url}
    matrix = {}
    all_configs = set()
    all_suites = set()

    for wf in WORKFLOW_INFO:
        key = wf["key"]
        runs = all_data.get(key, [])
        if not runs:
            continue

        # Use the latest run that actually has usable matrix jobs.
        # This avoids rendering placeholder jobs from early setup failures.
        latest = next(
            (run for run in runs if any(is_valid_matrix_job(job) for job in run.get("jobs", []))),
            None,
        )
        if latest is None:
            continue

        for job in latest.get("jobs", []):
            if not is_valid_matrix_job(job):
                continue
            config = job.get("config", "")
            testcase = job.get("testcase", "")

            all_configs.add(config)
            all_suites.add(testcase)

            if config not in matrix:
                matrix[config] = {}
            if testcase not in matrix[config]:
                matrix[config][testcase] = {}

            matrix[config][testcase][key] = {
                "conclusion": job.get("conclusion", "unknown"),
                "html_url": job.get("html_url", ""),
            }

    # Order: preferred order first, then any extras alphabetically
    def ordered(items, preferred):
        result = [c for c in preferred if c in items]
        extras = sorted(items - set(preferred))
        return result + extras

    configs_used = ordered(all_configs, MATRIX_CONFIGS_ORDER)
    suites_used = ordered(all_suites, MATRIX_SUITES_ORDER)

    return matrix, configs_used, suites_used


def build_chart_data(all_data: dict) -> dict:
    """Build Chart.js data for trend charts."""
    chart_data = {}

    for wf in WORKFLOW_INFO:
        key = wf["key"]
        runs = all_data.get(key, [])

        # Take last TREND_COUNT runs, reversed for chronological order
        trend_runs = list(reversed(runs[:TREND_COUNT]))

        labels = []
        pass_rates = []
        durations = []

        for run in trend_runs:
            labels.append(str(run.get("run_number", "")))
            total = run.get("total_jobs", 0)
            passed = run.get("passed_jobs", 0)
            rate = round(passed / total * 100, 1) if total > 0 else 0
            pass_rates.append(rate)
            dur_min = round(run.get("duration_seconds", 0) / 60, 1)
            durations.append(dur_min)

        chart_data[key] = {
            "labels": labels,
            "pass_rates": pass_rates,
            "durations": durations,
        }

    return chart_data


def enrich_run(run: dict) -> dict:
    """Add display-friendly fields to a run dict."""
    run["duration_display"] = format_duration(run.get("duration_seconds", 0))
    run["created_at_display"] = format_datetime(run.get("created_at", ""))
    for job in run.get("jobs", []):
        job["duration_display"] = format_duration(job.get("duration_seconds", 0))
    return run


def build_workflows_context(all_data: dict) -> list:
    """Build the workflows list for the template context."""
    workflows = []

    for wf in WORKFLOW_INFO:
        key = wf["key"]
        runs = all_data.get(key, [])

        # Enrich all runs
        for run in runs:
            enrich_run(run)

        # Build latest run summary (or placeholder)
        if runs:
            latest = runs[0]
        else:
            latest = {
                "conclusion": "unknown",
                "head_branch": "N/A",
                "head_sha": "N/A",
                "passed_jobs": 0,
                "failed_jobs": 0,
                "skipped_jobs": 0,
                "total_jobs": 0,
                "duration_display": "N/A",
                "run_number": 0,
                "html_url": "#",
            }

        workflows.append(
            {
                "key": key,
                "display_name": wf["display_name"],
                "latest": latest,
                "runs": runs,
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
    args = parser.parse_args()

    data_dir = Path(args.data_dir)
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    # Load data
    all_data = load_workflow_data(data_dir)

    # Build template context
    now = datetime.now(timezone.utc)
    workflows = build_workflows_context(all_data)
    matrix_data, matrix_configs, matrix_suites = build_matrix(all_data)
    chart_data = build_chart_data(all_data)

    default_matrix_wf = "tier2"
    if not all_data.get("tier2"):
        for wf in WORKFLOW_INFO:
            if all_data.get(wf["key"]):
                default_matrix_wf = wf["key"]
                break

    context = {
        "generated_at": now.strftime("%Y-%m-%d %H:%M UTC"),
        "year": now.year,
        "repo": args.repo,
        "workflows": workflows,
        "matrix_data": matrix_data,
        "matrix_configs": matrix_configs,
        "matrix_suites": matrix_suites,
        "default_matrix_wf": default_matrix_wf,
        "chart_data": chart_data,
        "trend_count": TREND_COUNT,
    }

    # Render template
    template_dir = Path(__file__).parent / "templates"
    env = Environment(loader=FileSystemLoader(str(template_dir)), autoescape=True)
    template = env.get_template("tier_dashboard.html")
    html = template.render(**context)

    # Write output
    output_file = output_dir / "tier_dashboard.html"
    with open(output_file, "w") as f:
        f.write(html)

    # Copy static dashboard assets, such as the local OpenHW logo.
    static_dir = Path(__file__).parent / "static"
    if static_dir.exists():
        assets_dir = output_dir / "assets"
        if assets_dir.exists():
            shutil.rmtree(assets_dir)
        shutil.copytree(static_dir, assets_dir)

    print(f"Dashboard generated: {output_file}")
    print(f"  Workflows: {len(workflows)}")
    for wf in workflows:
        print(f"    - {wf['display_name']}: {len(wf['runs'])} runs")
    print(f"  Matrix: {len(matrix_configs)} configs x {len(matrix_suites)} suites")


if __name__ == "__main__":
    main()
