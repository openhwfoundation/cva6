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
Elaborate the TestHarness testbench with Questa.

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
def questa_testharness_comp(
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
    Elaborate the TestHarness testbench with Questa
    """
    report = RecipeReport(
        "questa-testharness-comp",
        title="QUESTA TESTHARNESS COMPILATION",
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

    for tool in ("vlib", "vlog", "vopt", "vsim"):
        tool_path = shutil.which(tool)
        if tool_path is not None:
            report.success(f"{tool}: {tool_path}")
        else:
            report.error_exit(f"{tool}: Not found", env=True)
    # Not resolve(): the install is reached through a symlink whose target
    # holds the binaries but not the Verilog sources of the UVM
    questasim_home = Path(shutil.which("vsim")).parent.parent

    build_root = repo_dir / "build" / target
    elab_dir = build_root / "elab" / "sim_rtl_questa_testharness"
    report.set_out_dir(elab_dir)
    work_dir = elab_dir / "work"
    uvm_src = questasim_home / "verilog_src" / "uvm-1.2" / "src"

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
        "QUESTASIM_HOME": str(questasim_home),
    }
    error_patterns = [r"^\*\* Error"]
    warning_patterns = [r"^\*\* Warning"]
    env_patterns = [
        r"(license|licence).*(error|fail|unable|denied|expired)",
        r"unable to checkout",
        r"command not found",
    ]

    # ==========================================================
    # STEP 1: CREATE LIBRARY (vlib)
    # ==========================================================
    report.step("Create Questa work library")

    run_cmd(
        cmd=["vlib", str(work_dir)],
        report=report,
        cwd=elab_dir,
        env=env_vars,
        error_patterns=error_patterns,
        warning_patterns=warning_patterns,
        log_file=elab_dir / "vlib.log",
        timeout=30,
        check=False,
    )

    if not work_dir.exists():
        report.error_exit("Work library not created")

    report.success(f"Work library created: {work_dir}")

    # ==========================================================
    # STEP 2: COMPILE (vlog)
    # ==========================================================
    report.step("Compile with vlog")

    # The UVM package first: `ariane_tb` resolves `uvm_pkg::` while it is
    # parsed. Then the RTL of the target, the harness, and the
    # SystemVerilog top with the real UART.
    vlog_cmd = [
        "vlog",
        "-quiet",
        "-sv",
        "-work",
        str(work_dir),
        "-timescale",
        "1ns/1ns",
        "-suppress",
        "2583",
        f"+incdir+{uvm_src}",
        str(uvm_src / "uvm_pkg.sv"),
        "-f",
        str(repo_dir / "config" / "target" / target / "Flist.cva6"),
        "-f",
        str(repo_dir / "verif" / "tb" / "core" / "Flist.testharness"),
        "-f",
        str(repo_dir / "verif" / "tb" / "core" / "Flist.testharness_top"),
    ]

    log_file = elab_dir / "vlog.log"

    run_cmd(
        cmd=vlog_cmd,
        report=report,
        cwd=elab_dir,
        env=env_vars,
        error_patterns=error_patterns,
        warning_patterns=warning_patterns,
        log_file=log_file,
        timeout=1800,
        check=False,
    )

    report.analyze_log(
        log_file,
        name="vlog.log analysis",
        error_patterns=error_patterns,
        warning_patterns=warning_patterns,
        env_patterns=env_patterns,
        fail_on_error=False,
    )

    # ==========================================================
    # STEP 3: OPTIMIZE (vopt)
    # ==========================================================
    report.step("Optimize with vopt")

    vopt_cmd = ["vopt", "-quiet", "-64", "-work", str(work_dir)]
    # +acc keeps the signals reachable, at the cost of the optimisations
    # vopt would otherwise apply: only asked for when tracing
    if trace_mode != TraceMode.notrace:
        vopt_cmd += ["+acc"]
    vopt_cmd += ["ariane_tb", "-o", "ariane_tb_opt"]

    run_cmd(
        cmd=vopt_cmd,
        report=report,
        cwd=elab_dir,
        env=env_vars,
        error_patterns=error_patterns,
        warning_patterns=warning_patterns,
        log_file=elab_dir / "vopt.log",
        timeout=1800,
        check=False,
    )

    report.analyze_log(
        elab_dir / "vopt.log",
        name="vopt.log analysis",
        error_patterns=error_patterns,
        warning_patterns=warning_patterns,
        env_patterns=env_patterns,
        fail_on_error=False,
    )

    if not (work_dir / "ariane_tb_opt").exists():
        report.error_exit("Optimized design not generated")

    report.success("Optimized design generated")

    # ==========================================================
    # BUILD MANIFEST
    # ==========================================================
    write_manifest(
        elab_dir,
        "questa-testharness-comp",
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
    for genfile in [work_dir, log_file, elab_dir / "vopt.log"]:
        if genfile.exists():
            report.info(f"> {genfile}")
            generated.append(str(genfile.relative_to(repo_dir)))
    report.log("Generated files", generated)

    report.end("Completed")
