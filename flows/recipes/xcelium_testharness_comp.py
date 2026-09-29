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
Elaborate the TestHarness testbench with Xcelium.

The top level is `ariane_tb`, the SystemVerilog testbench that
instantiates the harness. The harness talks to the core over AXI, so
only the AXI targets are wired for it. `xrun -elaborate` leaves a
snapshot the run recipe reopens with `-R`.
"""

from pathlib import Path
import shutil

import typer

from flows.utils.autocompletion import CompMode, TraceMode, autocompletion_target
from flows.utils.manifest import write_manifest
from flows.utils.recipe_report import RecipeReport
from flows.utils.run_cmd import run_cmd
from flows.utils.target_config import read_config_or_exit_testbench_cfg

app = typer.Typer()


# ==========================================================
# RECIPE
# ==========================================================


@app.command()
def xcelium_testharness_comp(
    target: str = typer.Option(
        ...,
        "--target",
        "-t",
        help="CVA6 user configuration",
        autocompletion=autocompletion_target,
    ),
    comp_mode: CompMode = typer.Option(
        CompMode.rtl, help="Compilation mode; only rtl is supported"
    ),
    trace_mode: TraceMode = typer.Option(
        TraceMode.notrace, help="notrace, or any other value to keep the signals"
    ),
    stats: bool = typer.Option(False, help="RTL perf tracer; currently unsupported"),
    quiet: bool = typer.Option(
        False, "--quiet", "-q", help="Suppress output (errors only)"
    ),
):
    """
    Elaborate the TestHarness testbench with Xcelium
    """
    report = RecipeReport(
        "xcelium-testharness-comp",
        title="XCELIUM TESTHARNESS COMPILATION",
        context={
            "target": target,
            "comp_mode": comp_mode,
            "trace_mode": trace_mode,
            "stats": stats,
        },
        quiet=quiet,
    )

    repo_dir = Path.cwd()

    if comp_mode != CompMode.rtl:
        report.error_exit(
            f"The TestHarness supports only the rtl compilation mode, got "
            f"{comp_mode.value}",
            env=True,
        )
    if stats:
        report.error_exit(
            "The RTL perf tracer is not wired to the TestHarness", env=True
        )

    xrun_path = shutil.which("xrun")
    if xrun_path is not None:
        report.success(f"XRUN: {xrun_path}")
    else:
        report.error_exit("xrun: Not found", env=True)

    build_root = repo_dir / "build" / target
    elab_dir = build_root / "elab" / "sim_rtl_xcelium_testharness"
    report.set_out_dir(elab_dir)
    snapshot_dir = elab_dir / "xcelium.d"

    # ==========================================================
    # CHECK PREREQUISITES
    # ==========================================================
    report.step("Check prerequisites")

    cva6_hier = read_config_or_exit_testbench_cfg(target, report)
    if cva6_hier.value != "axi":
        report.error_exit(
            f"The TestHarness requires an AXI target, {target} is "
            f"{cva6_hier.value}",
            env=True,
        )
    report.success("Prerequisites OK")

    # ==========================================================
    # CLEAN
    # ==========================================================
    report.step("Clean")
    try:
        if elab_dir.exists():
            shutil.rmtree(elab_dir)
            report.info(f"remove {elab_dir}")
    except Exception as e:
        report.error_exit(f"Clean error : {e}", env=True)

    elab_dir.mkdir(parents=True, exist_ok=True)
    report.info(f"create {elab_dir}")

    # ==========================================================
    # ENV VARIABLES (passed to run_cmd only)
    # ==========================================================
    env_vars = {
        "CVA6_REPO_DIR": str(repo_dir),
        "TARGET_CFG": target,
        "HPDCACHE_DIR": str(repo_dir / "core" / "cache_subsystem" / "hpdcache"),
    }

    # ==========================================================
    # OPTIONS
    # ==========================================================
    # -smartorder lets xrun work out the order the files are read in, the
    # UVM package included. The DPI of the harness is resolved at run time
    # against the Spike libraries, as on the other simulators.
    options = [
        "-elaborate",
        "-messages",
        "-64bit",
        "-v200x",
        "-disable_sem2009",
        "-sv",
        "-uvm",
        "-uvmhome",
        "CDNS-1.2",
        "-smartorder",
        "-timescale",
        "1ns/1ps",
        "-status",
        # +rwc keeps the signals readable, writable and connected, which
        # the waveform database needs: only asked for when tracing
        "-access",
        "+rwc" if trace_mode != TraceMode.notrace else "+r",
    ]
    # Raised by the CVA6 sources on every run, the XRUN_DISABLED_WARNINGS
    # of the root Makefile
    for warning in ("BIGWIX", "ZROMCW", "STRINT", "ENUMERR", "SPDUSD", "RNDXCELON"):
        options += ["-nowarn", warning]

    flist = [
        repo_dir / "config" / "target" / target / "Flist.cva6",
        repo_dir / "verif" / "tb" / "core" / "Flist.testharness",
        repo_dir / "verif" / "tb" / "core" / "Flist.testharness_top",
    ]

    # ==========================================================
    # BUILD XRUN COMMAND
    # ==========================================================
    xrun_cmd = ["xrun"]
    xrun_cmd += options
    for f in flist:
        xrun_cmd += ["-f", str(f)]
    xrun_cmd += ["-top", "worklib.ariane_tb"]

    # ==========================================================
    # LAUNCH XRUN COMMAND
    # ==========================================================
    report.step("LAUNCH XRUN")

    log_file = elab_dir / "compilation.log"

    run_cmd(
        cmd=xrun_cmd,
        report=report,
        cwd=elab_dir,
        env=env_vars,
        error_patterns=["^xm.*: \\*E", "Error-"],
        warning_patterns=["^xm.*: \\*W", "Warning-"],
        log_file=log_file,
        timeout=1800,
        check=False,
    )

    report.analyze_log(
        log_file,
        name="compilation.log analysis",
        error_patterns=["^xm.*: \\*E", "Error-"],
        warning_patterns=["^xm.*: \\*W", "Warning-"],
        env_patterns=[
            r"(license|licence).*(error|fail|unable|denied|expired)",
            r"unable to checkout",
            r"command not found",
        ],
        fail_on_error=False,
    )

    if not snapshot_dir.exists():
        report.error_exit("Xcelium snapshot not generated")

    report.success("Xcelium snapshot generated")

    # ==========================================================
    # BUILD MANIFEST
    # ==========================================================
    write_manifest(
        elab_dir,
        "xcelium-testharness-comp",
        {
            "target": target,
            "comp_mode": comp_mode,
            "trace_mode": trace_mode,
            "stats": stats,
        },
        report=report,
    )

    # ==========================================================
    # List
    # ==========================================================
    report.step("Generated files")
    generated = []
    for genfile in [snapshot_dir, log_file]:
        if genfile.exists():
            report.info(f"> {genfile}")
            generated.append(str(genfile.relative_to(repo_dir)))
    report.log("Generated files", generated)

    report.end("Completed")
