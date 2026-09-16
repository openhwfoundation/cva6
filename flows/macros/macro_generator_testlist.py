# Copyright 2026 Thales France
#
# Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
# You may obtain a copy of the License at https://solderpad.org/licenses/
#
# Original Author: Théo GIOVINAZZI

import random
from pathlib import Path
import typer

from flows.recipes.sw_compile_testlist import sw_compile_testlist
from flows.recipes.vcs_generator_run_testlist import vcs_generator_run_testlist
from flows.recipes.uvm_run_testlist import uvm_run_testlist
from flows.utils.recipe_report import RecipeReport
from flows.utils.autocompletion import (
    CompMode,
    ToolchainOption,
    TraceMode,
    UvmVerbosity,
    autocompletion_target,
    autocompletion_testlist,
)

app = typer.Typer()


# ==========================================================
# RECIPE
# ==========================================================


@app.command()
def macro_vcs_generator_testlist(
    # --- Arguments for generator ---
    target: str = typer.Option(
        ...,
        "--target",
        "-t",
        help="CVA6 user configuration",
        autocompletion=autocompletion_target,
    ),
    testlist: str = typer.Option(
        ...,
        "--testlist",
        "-l",
        help="Testlist (YML file) in verif/tests",
        autocompletion=autocompletion_testlist,
    ),
    test_name: list[str] = typer.Option(
        None, "--testname", "-n", help="Single test in the given testlist"
    ),
    # --- Arguments for compilation ---
    toolchain: ToolchainOption = typer.Option(
        ...,
        "--toolchain",
        "-c",
        help="Toolchain defined in $CONFIG_DIR/compiler.yml",
    ),
    march: str = typer.Option(
        None, help="march custom instead of default one from config/target"
    ),
    mabi: str = typer.Option(
        None, help="mabi custom instead of default one from config/target"
    ),
    # --- Arguments for simulation UVM ---
    comp_mode: CompMode = typer.Option(CompMode.rtl, help="Hardware compilation mode"),
    trace_mode: TraceMode = typer.Option(TraceMode.notrace, help="Trace mode"),
    uvm_verbosity: UvmVerbosity = typer.Option(UvmVerbosity.none, help="UVM verbosity"),
    tandem_enabled: bool = typer.Option(False, help="Enable spike tandem"),
    tb_performance_mode: bool = typer.Option(False, help="Enable tb perf mode"),
    stats: bool = typer.Option(False, help="Enable RTL perf tracer"),
    sim_profile: bool = typer.Option(False, help="Enable simulation profiling"),
    run_opts: list[str] = typer.Option([], "--run_opts", help="Simulation run options"),
    batch_size: int = typer.Option(1, help="Number of tests to generate per run batch"),
    seed: int = typer.Option(None, help="randomized if not provided"),
    uvm_seed: str = typer.Option(
        str(random.getrandbits(31)), help="Randomize UVM seed"
    ),
    quiet: bool = typer.Option(
        False, "--quiet", "-q", help="Suppress output (errors only)"
    ),
):
    """
    Macro : VCS Generator -> SW Compile -> UVM Run from a testlist
    """
    repo_dir = Path.cwd()

    # One pass/fail row per executed step, with the path of
    # each sub-recipe cook_report.yml (each report stays in its own out_dir)
    report = RecipeReport(
        "macro-vcs-generator-testlist",
        out_dir=repo_dir / "build" / target,
        title="MACRO: VCS GENERATOR -> COMPILATION -> SIMULATION",
        context={
            "target": target,
            "testlist": testlist,
            "test_name": test_name,
            "toolchain": toolchain,
            "march": march,
            "mabi": mabi,
            "comp_mode": comp_mode,
            "trace_mode": trace_mode,
            "uvm_verbosity": uvm_verbosity,
            "tandem_enabled": tandem_enabled,
            "tb_performance_mode": tb_performance_mode,
            "stats": stats,
            "sim_profile": sim_profile,
            "run_opts": run_opts,
            "batch_size": batch_size,
            "seed": seed,
            "uvm_seed": uvm_seed,
        },
        quiet=quiet,
    )
    results = report.metric("Macro steps")

    # cook_report.yml locations of the sub-recipes (their out_dir)
    generator_report = (
        repo_dir / "build" / "cv32a65x" / "dv_generated" / "cook_report.yml"
    )
    sw_compile_report = repo_dir / "build" / target / "compile" / "cook_report.yml"
    inout_dir = {
        CompMode.rtl: "sim_rtl",
        CompMode.coverage: "sim_cov",
        CompMode.gate_wc_timing: "sim_gate_wc_timing",
        CompMode.gate_wc_power: "sim_gate_wc_power",
    }[comp_mode]
    uvm_run_report = (
        repo_dir / "build" / target / "simulation" / inout_dir / "cook_report.yml"
    )

    # ==========================================
    # STEP 1 : GENERATOR
    # ==========================================
    try:
        report.step("STEP 1: RUN GENERATOR")
        vcs_generator_run_testlist(
            testlist=testlist,
            test_name=test_name,
            seed=seed,
            batch_size=batch_size,
            quiet=quiet,
        )
        results.add_row(
            status="pass", step="Run Generator", report=str(generator_report)
        )
    except typer.Exit:
        report.error("Macro Error: Run Generator")
        results.add_row(
            status="fail", step="Run Generator", report=str(generator_report)
        )
        report.set_label("FAIL: Run Generator")
        report.end("FAIL: Run Generator")

    # ==========================================
    # STEP 2 : SOFTWARE COMPILE
    # ==========================================

    try:
        report.step("STEP 2: SW COMPILE")
        sw_compile_testlist(
            target=target,
            toolchain=toolchain,
            testlist=testlist,
            test_name=test_name,
            march=march,
            mabi=mabi,
            quiet=quiet,
        )
        results.add_row(status="pass", step="Sw Compile", report=str(sw_compile_report))
    except typer.Exit:
        report.error("Macro Error: Sw Compile")
        results.add_row(status="fail", step="Sw Compile", report=str(sw_compile_report))
        report.set_label("FAIL: Sw Compile")
        report.end("FAIL: Sw Compile")

    # ==========================================
    # STEP 3 : UVM SIMULATION RUN
    # ==========================================
    try:
        report.step("STEP 3: UVM RUN")
        uvm_run_testlist(
            simulator="vcs",
            target=target,
            testlist=testlist,
            test_name=test_name,
            comp_mode=comp_mode,
            trace_mode=trace_mode,
            uvm_verbosity=uvm_verbosity,
            tandem_enabled=tandem_enabled,
            tb_performance_mode=tb_performance_mode,
            stats=stats,
            sim_profile=sim_profile,
            interactive_gui=False,
            run_opts=run_opts,
            uvm_seed=uvm_seed,
            sim_timeout=3000,
            cycle_timeout=None,
            quiet=quiet,
        )
        results.add_row(status="pass", step="UVM Run", report=str(uvm_run_report))
    except typer.Exit:
        report.error("Macro Error: UVM run")
        results.add_row(status="fail", step="UVM Run", report=str(uvm_run_report))
        report.set_label("FAIL: UVM Run")
        report.end("FAIL: UVM Run")

    # ==========================================================
    # BUILD REPORT
    # ==========================================================
    report.print_metric(results)
    n_total = len(results.values)
    report.set_label(f"{n_total}/{n_total} PASS")
    report.success(f"All {n_total} step(s) passed")

    report.end("Completed")
