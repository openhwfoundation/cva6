# Copyright 2026 Thales France
#
# Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
# You may obtain a copy of the License at https://solderpad.org/licenses/
#
# Original Author: Yannick Casamatta (yannick.casamatta@thalesgroup.com)

# Please refer to flows/README.md to add target

from pathlib import Path
import re
import shutil
from enum import Enum
import typer
from flows.utils.manifest import require_prerequisite
from flows.utils.recipe_report import RecipeReport
from flows.utils.run_cmd import run_cmd
from flows.utils.autocompletion import autocompletion_target
from flows.utils.target_config import (
    read_config_or_exit_testbench_cfg,
    top_elaborate as get_top_elaborate,
)

app = typer.Typer()


class RunType(str, Enum):
    run_cli = "run_cli"
    gui = "gui"
    show_goals = "show_goals"


def _parse_summary_rpt(summary_file):
    """
    Parse a Spyglass summary.rpt into {(severity, rule): (count, help)}.

    Rule lines look like `WARNING    SYNTH_5064    10    Short help...`,
    possibly continued on indented lines (help text wrapping).
    """
    rule_re = re.compile(r"(WARNING|ERROR|INFO)\s+(\S+)\s+(\d+)\s+(.+)$")
    continuation_re = re.compile(r"^ +(.*)")

    rules = {}
    last_key = None
    for line in summary_file.read_text(encoding="utf-8", errors="replace").splitlines():
        match = rule_re.match(line)
        if match:
            severity, rule_name, count, short_help = match.groups()
            last_key = (severity, rule_name)
            rules[last_key] = (int(count), short_help.strip())
            continue
        match = continuation_re.match(line)
        if match and last_key is not None:
            count, short_help = rules[last_key]
            rules[last_key] = (count, f"{short_help} {match.group(1).strip()}")
    return rules


def _check_against_baseline(baseline_file, summary_file, report):
    """
    Compare the Spyglass summary against the expected baseline.

    Every (severity, rule) is compared by count: a new rule or a count
    increase fails the report; a deleted rule or a count decrease passes
    (with an informative diff). The full comparison is recorded as a
    status table.
    """
    report.step("Compare violations against baseline")

    baseline = _parse_summary_rpt(baseline_file)
    new = _parse_summary_rpt(summary_file)

    severity_order = {"ERROR": 1, "WARNING": 2, "INFO": 3}
    results = []  # (severity, rule, count, help, passed, diff)

    for key, (count, short_help) in baseline.items():
        if key not in new:
            results.append((*key, count, short_help, True, "Deleted"))

    for key, (count, short_help) in new.items():
        if key not in baseline:
            results.append((*key, count, short_help, False, "NEW"))
        elif count == baseline[key][0]:
            results.append((*key, count, short_help, True, "SAME"))
        else:
            diff = f"Count changed from {baseline[key][0]} to {count}"
            results.append((*key, count, short_help, count <= baseline[key][0], diff))

    results.sort(key=lambda x: severity_order.get(x[0], 4))

    metric = report.metric("Lint baseline comparison")

    failed = 0
    for severity, rule_name, count, short_help, passed, diff in results:
        metric.add_row(
            status="pass" if passed else "fail",
            severity=severity,
            rule=rule_name,
            count=count,
            help=short_help,
            diff=diff,
        )
        if not passed:
            failed += 1

    if failed:
        report.error(f"Lint deviations from baseline: {failed} rule(s)")
    else:
        report.success(f"Lint matches baseline ({len(new)} rules)")


# ==========================================================
# RECIPE
# ==========================================================


@app.command()
def spyglass_run(
    target: str = typer.Option(
        ...,
        "--target",
        "-t",
        help="CVA6 user configuration",
        autocompletion=autocompletion_target,
    ),
    run_type: RunType = typer.Option(RunType.run_cli, help="Run mode"),
    quiet: bool = typer.Option(
        False, "--quiet", "-q", help="Suppress output (errors only)"
    ),
):
    """
    Spyglass run
    """
    report = RecipeReport(
        "spyglass-run",
        title="Spyglass run",
        context={
            "target": target,
            "run_type": run_type,
        },
        quiet=quiet,
    )

    # Output directory set first: a failure reading the target
    # configuration below must still produce a report.
    repo_dir = Path.cwd()
    build_root = repo_dir / "build" / target
    spyglass_dir = build_root / "spyglass"
    report.set_out_dir(spyglass_dir)

    # Get testbench config
    cva6_hier = read_config_or_exit_testbench_cfg(target, report)

    # Test tools in path
    aipk_run_path = shutil.which("aipk_run")
    if aipk_run_path is not None:
        report.success(f"aipk_run: {aipk_run_path}")
    else:
        report.error_exit("aipk_run: Not found", env=True)

    top_elaborate = get_top_elaborate(cva6_hier)

    report.add_context({"top_elaborate": top_elaborate})

    # Create files and folder paths
    sg_setup_dir = spyglass_dir / "sg_setup" / f"{top_elaborate}"
    tmp_dir = spyglass_dir / "tmp"

    require_prerequisite(
        sg_setup_dir,
        "Spyglass design read setup",
        f"./cook.py spyglass-design-read -t {target}",
        report=report,
    )
    report.info(f"sg_setup found: {spyglass_dir}")

    # ==========================================================
    # CLEAN
    # ==========================================================
    report.step("Clean")
    report.info("None")

    # ==========================================================
    # ENV VARIABLES (passed to run_cmd only)
    # ==========================================================

    env_vars = {
        "CVA6_REPO_DIR": str(repo_dir),
        "TARGET_CFG": target,
        "HPDCACHE_DIR": str(repo_dir / "core/cache_subsystem/hpdcache"),
        "SPYGLASS_TMPDIR": str(tmp_dir),
    }

    # ==========================================================
    # BUILD SPYGLASS DESIGN READ COMMAND
    # ==========================================================
    sg_cmd = ["aipk_run"]
    sg_cmd += [f"-top={top_elaborate}"]

    if run_type == "run_cli":
        sg_cmd += ["-goals=lint_rtl"]
    elif run_type == "gui":
        sg_cmd += ["-gui"]
    elif run_type == "show_goals":
        sg_cmd += ["-showgoals"]

    # ==========================================================
    # LAUNCH SPYGLASS DESIGN READ COMMAND
    # ==========================================================
    report.step("LAUNCH SPYGLASS DESIGN READ")

    log_file = spyglass_dir / "run.log"

    run_cmd(
        cmd=sg_cmd,
        report=report,
        cwd=spyglass_dir,
        env=env_vars,
        error_patterns=["error:|^AIPK_ERROR :|^ERROR:"],
        warning_patterns=["warning:|^AIPK_WARNING :|^WARNING:"],
        highlight_patterns=["info:|Messages:|Total Messages|^AIPK_INFO :|^INFO:"],
        log_file=log_file,
        timeout=1800,
        check=False,
        capture_output=True,
    )

    # ==========================================================
    # Results processing
    # ==========================================================

    report.step("Results processing")

    if not log_file.exists():
        report.error_exit(f"{log_file} missing", env=True)

    n_err, _ = report.analyze_log(
        log_file,
        name="run.log analysis",
        error_patterns=["error:|^AIPK_ERROR :|^ERROR:"],
        warning_patterns=["warning:|^AIPK_WARNING :|^WARNING:"],
        env_patterns=[
            r"(license|licence).*(error|fail|unable|denied|expired)",
            r"unable to checkout",
            r"command not found",
        ],
        fail_on_error=False,
    )

    moresimple_rpt = (
        spyglass_dir
        / "sg_run_results"
        / f"{top_elaborate}"
        / f"{top_elaborate}"
        / "lint"
        / "lint_rtl"
        / "spyglass_reports"
        / "moresimple.rpt"
    )

    report.file_regex(
        moresimple_rpt,
        highlight_patterns=["Error|Fatal|Warning"],
    )

    # Violation summary (counts from moresimple.rpt)
    if moresimple_rpt.exists():
        counts = {"Fatal": 0, "Error": 0, "Warning": 0}
        pattern = re.compile(r"Fatal|Error|Warning")
        for line in moresimple_rpt.read_text(errors="replace").splitlines():
            match = pattern.search(line)
            if match:
                counts[match.group(0)] += 1
        report.metric("Violations summary", counts)
    elif run_type == RunType.run_cli:
        report.warning(f"{moresimple_rpt} missing")

    # Baseline comparison (only meaningful for a lint run)
    if run_type == RunType.run_cli:
        baseline_rpt = repo_dir / "config" / "target" / target / "expected_spyglass.rpt"
        summary_rpt = (
            spyglass_dir
            / "sg_run_results"
            / f"{top_elaborate}_sg_reports"
            / f"{top_elaborate}_lint_lint_rtl"
            / "summary.rpt"
        )
        if not baseline_rpt.exists():
            report.warning(f"No lint baseline for this target: {baseline_rpt} missing")
        elif not summary_rpt.exists():
            report.error(f"{summary_rpt} missing: lint baseline cannot be checked")
        else:
            _check_against_baseline(baseline_rpt, summary_rpt, report)

    if n_err > 0:
        report.error_exit(f"Spyglass run failed: {n_err} error(s) in {log_file}")
    report.success("Spyglass run completed")

    # ==========================================================
    # List
    # ==========================================================
    report.step("Generated files")
    gen_files = [
        log_file,
        spyglass_dir
        / "sg_run_results"
        / f"{top_elaborate}"
        / f"{top_elaborate}"
        / "lint"
        / "design_audit"
        / "spyglass.log",
        spyglass_dir
        / "sg_run_results"
        / f"{top_elaborate}"
        / f"{top_elaborate}"
        / "lint"
        / "design_audit"
        / "spyglass_reports",
        spyglass_dir
        / "sg_run_results"
        / f"{top_elaborate}"
        / f"{top_elaborate}"
        / "cdc"
        / "cdc_setup_check"
        / "spyglass.log",
        spyglass_dir
        / "sg_run_results"
        / f"{top_elaborate}"
        / f"{top_elaborate}"
        / "cdc"
        / "cdc_setup_check"
        / "spyglass_reports",
        spyglass_dir
        / "sg_run_results"
        / f"{top_elaborate}_sg_reports"
        / "html_reports"
        / "goals_summary.html",
    ]

    generated = []
    for genfile in gen_files:
        if genfile.exists():
            report.info(f"> {genfile}")
            generated.append(str(genfile.relative_to(repo_dir)))

    # ==========================================================
    # BUILD REPORT
    # ==========================================================
    report.log("Generated files", generated)

    report.end("Completed")
