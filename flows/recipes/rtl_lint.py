# Copyright 2026 Thales France
#
# Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
# You may obtain a copy of the License at https://solderpad.org/licenses/
#
# Original Author: Yannick Casamatta (yannick.casamatta@thalesgroup.com)

# Please refer to flows/README.md to add target

"""
Open-source RTL lint of a target: slang, then Verilator --lint-only.

Both elaborate the core with the configuration package of the target, from
the same top as Spyglass (cva6_example_obi or cva6_example_axi), so every
target is linted, Spyglass licence or not:

- slang checks the conformance to the SystemVerilog standard, more strictly
  than the simulators (implicit nets, width and type mismatches...);
- Verilator adds the checks oriented towards synthesis (latches, widths,
  ranges), with the waivers of verilator_config.vlt.

As for Spyglass, the verdict is a comparison with a baseline,
config/target/<target>/expected_lint.yml: the number of diagnostics per
(tool, severity, rule). Any error fails, and so does a rule that is not in
the baseline or whose count increases; a count that decreases passes and is
reported, so the baseline can be lowered with --update-baseline.

slang is the `slang` binary when it is in PATH, the pyslang module of
flows/requirements.txt otherwise, so a runner needs nothing installed.
"""

from collections import Counter
from pathlib import Path
import re
import shutil
import sys

import typer
import yaml

from flows.utils.autocompletion import autocompletion_target
from flows.utils.recipe_report import RecipeReport
from flows.utils.run_cmd import run_cmd
from flows.utils.target_config import (
    read_config_or_exit_testbench_cfg,
    top_elaborate as get_top_elaborate,
)

app = typer.Typer()

BASELINE_FILE = "expected_lint.yml"

# slang through its Python binding when the binary is not installed: the
# driver of pyslang takes the very same command line as the binary
PYSLANG_DRIVER = """
import sys
import pyslang

driver = pyslang.Driver()
driver.addStandardArgs()
args = " ".join(["slang"] + ['"' + a + '"' for a in sys.argv[1:]])
if not driver.parseCommandLine(args, pyslang.CommandLineOptions()):
    sys.exit(2)
if not driver.processOptions():
    sys.exit(2)
ok = driver.parseAllSources()
compilation = driver.createCompilation()
ok = driver.reportCompilation(compilation, False) and ok
sys.exit(0 if ok else 1)
"""

# Options of the TestHarness elaboration, minus the build: the same set of
# warnings, so the lint reports what that flow would
VERILATOR_OPTIONS = [
    "--lint-only",
    "--no-timing",
    "-DPRELOAD=1",
    "--unroll-count",
    "256",
    "-Wall",
    "-Werror-PINMISSING",
    "-Werror-IMPLICIT",
    "-Wno-fatal",
    "-Wno-PINCONNECTEMPTY",
    "-Wno-ASSIGNDLY",
    "-Wno-DECLFILENAME",
    "-Wno-UNUSED",
    "-Wno-UNOPTFLAT",
    "-Wno-BLKANDNBLK",
    "-Wno-style",
]

# `file:line:col: severity: message [-Wrule]`
SLANG_DIAG = re.compile(
    r"^(?P<file>[^:\s][^:]*):\d+:\d+: (?P<sev>error|warning): .*?(?:\[-W(?P<rule>[\w-]+)\])?$"
)
# `%Warning-RULE: file:line:col: message` or `%Error: file:...`
VERILATOR_DIAG = re.compile(
    r"^%(?P<sev>Warning|Error)(?:-(?P<rule>[A-Z0-9_]+))?: (?P<file>[^:\s][^:]*):\d+"
)


def _slang_cmd():
    "Command running slang: the binary in PATH, else pyslang"
    slang = shutil.which("slang")
    if slang is not None:
        return [slang], slang
    try:
        import pyslang  # pylint: disable=import-outside-toplevel
    except ImportError:
        return None, None
    version = getattr(pyslang, "__version__", "")
    return [sys.executable, "-c", PYSLANG_DRIVER], f"pyslang {version}".strip()


def _count(log_file, pattern, tool, repo_dir):
    """
    Diagnostics of a tool log, as {(tool, severity, rule): count} and the
    list of their lines. Diagnostics outside the repository count too:
    the submodules are part of what is elaborated.
    """
    counts = Counter()
    lines = []
    if not log_file.exists():
        return counts, lines
    prefix = f"{repo_dir.as_posix()}/"
    for line in log_file.read_text(encoding="utf-8", errors="replace").splitlines():
        match = pattern.match(line)
        if not match:
            continue
        severity = match.group("sev").lower()
        rule = match.group("rule") or "none"
        counts[(tool, severity, rule)] += 1
        lines.append(line.replace(prefix, ""))
    return counts, lines


def _read_baseline(path):
    "{(tool, severity, rule): count} of the baseline file"
    data = yaml.safe_load(path.read_text(encoding="utf-8")) or {}
    baseline = Counter()
    for tool, severities in data.items():
        for severity, rules in (severities or {}).items():
            for rule, count in (rules or {}).items():
                baseline[(tool, severity, str(rule))] = int(count)
    return baseline


def _write_baseline(path, counts, target):
    "Write the counts as the baseline of the target"
    data = {}
    for (tool, severity, rule), count in sorted(counts.items()):
        data.setdefault(tool, {}).setdefault(severity, {})[rule] = count
    header = (
        f"# Lint baseline of {target}: diagnostics per tool, severity and rule.\n"
        "# Written by `./cook.py rtl-lint -t <target> --update-baseline`, read\n"
        "# by rtl-lint, which fails on a new rule or a higher count.\n"
    )
    path.write_text(
        header + yaml.safe_dump(data, default_flow_style=False, sort_keys=True),
        encoding="utf-8",
    )


def _check_against_baseline(baseline, counts, report):
    "Compare the counts with the baseline, one row per rule"
    report.step("Compare diagnostics against baseline")
    metric = report.metric("Lint baseline comparison")
    failed = 0
    for key in sorted(set(baseline) | set(counts)):
        tool, severity, rule = key
        before, now = baseline.get(key, 0), counts.get(key, 0)
        if key not in counts:
            passed, diff = True, "Deleted"
        elif key not in baseline:
            passed, diff = False, "NEW"
        elif now == before:
            passed, diff = True, "SAME"
        else:
            passed, diff = now <= before, f"Count changed from {before} to {now}"
        if severity == "error" and now:
            passed = False
        metric.add_row(
            status="pass" if passed else "fail",
            tool=tool,
            severity=severity,
            rule=rule,
            count=now,
            diff=diff,
        )
        failed += not passed
    if failed:
        report.error(f"Lint deviations from baseline: {failed} rule(s)")
    else:
        report.success(f"Lint matches baseline ({len(counts)} rules)")


# ==========================================================
# RECIPE
# ==========================================================


@app.command()
def rtl_lint(
    target: str = typer.Option(
        ...,
        "--target",
        "-t",
        help="CVA6 user configuration",
        autocompletion=autocompletion_target,
    ),
    update_baseline: bool = typer.Option(
        False,
        help=f"Write the diagnostics found as config/target/<target>/{BASELINE_FILE}",
    ),
    quiet: bool = typer.Option(
        False, "--quiet", "-q", help="Suppress output (errors only)"
    ),
):
    """
    Open-source RTL lint (slang + Verilator) against a baseline
    """
    report = RecipeReport(
        "rtl-lint",
        title="RTL lint (slang + Verilator)",
        context={"target": target, "update_baseline": update_baseline},
        quiet=quiet,
    )

    # Output directory set first: a failure reading the target
    # configuration below must still produce a report.
    repo_dir = Path.cwd()
    lint_dir = repo_dir / "build" / target / "rtl_lint"
    report.set_out_dir(lint_dir)

    top = get_top_elaborate(read_config_or_exit_testbench_cfg(target, report))
    report.add_context({"top_elaborate": top})

    report.step("Prerequisites")
    slang_cmd, slang_version = _slang_cmd()
    if slang_cmd is None:
        report.error_exit(
            "slang: Not found, neither the binary in PATH nor the pyslang module "
            "(pip3 install -r flows/requirements.txt)",
            env=True,
        )
    report.success(f"slang: {slang_version}")
    verilator = shutil.which("verilator")
    if verilator is None:
        report.error_exit(
            "verilator: Not found\n  Source setenv.sh, which puts it in the path.",
            env=True,
        )
    report.success(f"verilator: {verilator}")
    report.add_context({"slang": slang_version, "verilator": verilator})

    flist = repo_dir / "config" / "target" / target / "Flist.cva6"
    baseline_file = repo_dir / "config" / "target" / target / BASELINE_FILE

    # ==========================================================
    # CLEAN
    # ==========================================================
    report.step("Clean")
    try:
        if lint_dir.exists():
            shutil.rmtree(lint_dir)
            report.info(f"remove {lint_dir}")
    except Exception as e:
        report.error_exit(f"Clean error : {e}", env=True)
    lint_dir.mkdir(parents=True, exist_ok=True)

    env_vars = {
        "CVA6_REPO_DIR": str(repo_dir),
        "TARGET_CFG": target,
        "HPDCACHE_DIR": str(repo_dir / "core" / "cache_subsystem" / "hpdcache"),
    }

    # ==========================================================
    # SLANG
    # ==========================================================
    report.step("slang")
    slang_log = lint_dir / "slang.log"
    run_cmd(
        cmd=slang_cmd
        + [
            "-f",
            str(flist),
            "--top",
            top,
            "--timescale",
            "1ns/1ps",
            "--error-limit=0",
        ],
        report=report,
        cwd=repo_dir,
        env=env_vars,
        error_patterns=[r": error:"],
        warning_patterns=[r": warning:"],
        highlight_patterns=["Build succeeded|Build failed"],
        log_file=slang_log,
        timeout=1800,
        check=False,
        capture_output=False,
    )

    # ==========================================================
    # VERILATOR
    # ==========================================================
    report.step("Verilator")
    verilator_log = lint_dir / "verilator.log"
    run_cmd(
        cmd=[verilator, str(repo_dir / "verilator_config.vlt")]
        + VERILATOR_OPTIONS
        + ["-f", str(flist), "--top-module", top],
        report=report,
        cwd=repo_dir,
        env=env_vars,
        error_patterns=[r"^%Error"],
        warning_patterns=[r"^%Warning"],
        highlight_patterns=None,
        log_file=verilator_log,
        timeout=1800,
        check=False,
        capture_output=False,
    )

    # ==========================================================
    # RESULTS
    # ==========================================================
    report.step("Results processing")
    counts, slang_lines = _count(slang_log, SLANG_DIAG, "slang", repo_dir)
    verilator_counts, verilator_lines = _count(
        verilator_log, VERILATOR_DIAG, "verilator", repo_dir
    )
    counts.update(verilator_counts)
    # "Exiting due to N error(s)" is the conclusion, not a diagnostic
    counts.pop(("verilator", "error", "none"), None)
    verilator_lines = [line for line in verilator_lines if "Exiting due to" not in line]

    summary = Counter()
    for (tool, severity, _), count in counts.items():
        summary[f"{tool} {severity}s"] += count
    report.metric(
        "Diagnostics summary",
        {
            key: summary.get(key, 0)
            for key in (
                "slang errors",
                "slang warnings",
                "verilator errors",
                "verilator warnings",
            )
        },
    )
    # Every diagnostic, so the dashboard shows each of them, not a sample:
    # a few hundred lines per target at most
    report.log("slang diagnostics", slang_lines)
    report.log("Verilator diagnostics", verilator_lines)
    errors = summary["slang errors"] + summary["verilator errors"]
    warnings = summary["slang warnings"] + summary["verilator warnings"]
    report.set_label(f"{errors} err / {warnings} warn")

    if update_baseline:
        _write_baseline(baseline_file, counts, target)
        report.success(f"Baseline written: {baseline_file.relative_to(repo_dir)}")
    elif baseline_file.exists():
        _check_against_baseline(_read_baseline(baseline_file), counts, report)
    else:
        report.warning(f"No lint baseline for this target: {baseline_file} missing")
        if errors:
            report.error(f"{errors} lint error(s)")

    report.log(
        "Generated files",
        [str(p.relative_to(repo_dir)) for p in (slang_log, verilator_log)],
    )
    report.end("Completed")
