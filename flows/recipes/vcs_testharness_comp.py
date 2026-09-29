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
Elaborate the TestHarness testbench with VCS.

The top level is `ariane_tb`, the SystemVerilog testbench that
instantiates the harness. The harness talks to the core over AXI, so
only the AXI targets are wired for it.
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
def vcs_testharness_comp(
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
        TraceMode.notrace, help="notrace, compact (FSDB), fast or gui"
    ),
    stats: bool = typer.Option(False, help="RTL perf tracer; currently unsupported"),
    quiet: bool = typer.Option(
        False, "--quiet", "-q", help="Suppress output (errors only)"
    ),
):
    """
    Elaborate the TestHarness testbench with VCS
    """
    report = RecipeReport(
        "vcs-testharness-comp",
        title="VCS TESTHARNESS COMPILATION",
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

    vcs_path = shutil.which("vcs")
    if vcs_path is not None:
        report.success(f"VCS: {vcs_path}")
    else:
        report.error_exit("vcs: Not found", env=True)

    build_root = repo_dir / "build" / target
    elab_dir = build_root / "elab" / "sim_rtl_vcs_testharness"
    report.set_out_dir(elab_dir)
    simv = elab_dir / "simv"

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
    options = [
        "-full64",
        "-sverilog",
        "-ntb_opts",
        "uvm-1.2",
        "-assert",
        "svaext",
        "-timescale=1ns/1ns",
        "-ignore",
        "initializer_driver_checks",
        "-error=IWNF",
    ]
    if trace_mode != TraceMode.notrace:
        options += ["-debug_access+all", "-kdb"]
    if trace_mode == TraceMode.compact:
        options += ["+vcs+fsdbon"]

    # The filelists of the testbench: the RTL of the target, the harness,
    # then the SystemVerilog top and the real UART, which only the
    # event-driven simulators read.
    flist = [
        repo_dir / "config" / "target" / target / "Flist.cva6",
        repo_dir / "verif" / "tb" / "core" / "Flist.testharness",
        repo_dir / "verif" / "tb" / "core" / "Flist.testharness_top",
    ]

    # ==========================================================
    # BUILD VCS COMMAND
    # ==========================================================
    vcs_cmd = ["vcs"]
    vcs_cmd += options
    # Before the filelists: `ariane_tb` resolves `uvm_pkg::` while it is
    # parsed, and a design built without it faults when the UVM objects
    # are destroyed. ${VCS_HOME} is expanded by VCS.
    vcs_cmd += [
        "+incdir+${VCS_HOME}/etc/uvm-1.2/src",
        "${VCS_HOME}/etc/uvm-1.2/src/uvm_pkg.sv",
    ]
    for f in flist:
        vcs_cmd += ["-f", str(f)]
    vcs_cmd += ["-top", "ariane_tb", "-o", str(simv)]

    # ==========================================================
    # LAUNCH VCS COMMAND
    # ==========================================================
    report.step("LAUNCH VCS")

    log_file = elab_dir / "compilation.log"

    run_cmd(
        cmd=vcs_cmd,
        report=report,
        cwd=elab_dir,
        env=env_vars,
        error_patterns=["^Error-"],
        warning_patterns=["^Warning-"],
        log_file=log_file,
        timeout=1800,
        check=False,
    )

    report.analyze_log(
        log_file,
        name="compilation.log analysis",
        error_patterns=["^Error-"],
        warning_patterns=["^Warning-"],
        env_patterns=[
            r"(license|licence).*(error|fail|unable|denied|expired)",
            r"unable to checkout",
            r"command not found",
        ],
        fail_on_error=False,
    )

    if not simv.exists():
        report.error_exit("SIMV not generated")

    report.success("SIMV generated")

    # ==========================================================
    # BUILD MANIFEST
    # ==========================================================
    write_manifest(
        elab_dir,
        "vcs-testharness-comp",
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
    for genfile in [simv, log_file]:
        if genfile.exists():
            report.info(f"> {genfile}")
            generated.append(str(genfile.relative_to(repo_dir)))
    report.log("Generated files", generated)

    report.end("Completed")
