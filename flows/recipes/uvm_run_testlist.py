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
import random
from enum import Enum
import yaml
import typer
from flows.recipes.vcs_uvm_run import vcs_uvm_run
from flows.recipes.xcelium_uvm_run import xcelium_uvm_run
from flows.recipes.questa_uvm_run import questa_uvm_run
from flows.utils.manifest import require_prerequisite
from flows.utils.recipe_report import RecipeReport
from flows.utils.autocompletion import (
    CompMode,
    TraceMode,
    UvmVerbosity,
    autocompletion_target,
    autocompletion_testlist,
    autocompletion_testname_in_testlist,
)

app = typer.Typer()


# ==========================================================
# SIMULATOR ENUM
# ==========================================================


class Simulator(str, Enum):
    vcs = "vcs"
    xcelium = "xcelium"
    questa = "questa"


# ==========================================================
# RECIPE
# ==========================================================


@app.command()
def uvm_run_testlist(
    simulator: Simulator = typer.Option(
        ...,
        "--simulator",
        "-s",
        help="Simulator to use (vcs, xcelium, questa)",
    ),
    target: str = typer.Option(
        ...,
        "--target",
        "-t",
        help="CVA6 user configuration",
        autocompletion=autocompletion_target,
    ),
    testlist: str = typer.Option(
        None,
        "--testlist",
        "-l",
        help="Testlist (YML file) in verif/tests",
        autocompletion=autocompletion_testlist,
    ),
    test_name: list[str] = typer.Option(
        None,
        "--testname",
        "-n",
        help="Single test in the given testlist",
        autocompletion=autocompletion_testname_in_testlist,
    ),
    comp_mode: CompMode = typer.Option(CompMode.rtl, help="Hardware compilation mode"),
    trace_mode: TraceMode = typer.Option(TraceMode.notrace, help="Trace mode"),
    uvm_verbosity: UvmVerbosity = typer.Option(UvmVerbosity.none, help="UVM verbosity"),
    tandem_enabled: bool = typer.Option(False, help="Enable spike tandem"),
    tb_performance_mode: bool = typer.Option(False, help="Enable tb perf mode"),
    stats: bool = typer.Option(False, help="Enable RTL perf tracer"),
    sim_profile: bool = typer.Option(
        False, help="Enable simulation profiling (VCS only)"
    ),
    interactive_gui: bool = typer.Option(
        False, help="Launch GUI for interactive simulation"
    ),
    run_opts: list[str] = typer.Option([], "--run_opts", help="Simulation run options"),
    uvm_seed: str = typer.Option(
        str(random.getrandbits(31)), help="Randomize UVM seed"
    ),
    sim_timeout: int = typer.Option(
        3000, "--sim-timeout", help="Per-test simulation timeout in seconds"
    ),
    cycle_timeout: int = typer.Option(
        None,
        "--cycle-timeout",
        help="Stop each simulation after that many cycles. Cuts short a test "
        "that derails without ever writing tohost, instead of waiting for the "
        "wall clock timeout. VCS only, defaults to the testbench value.",
    ),
    quiet: bool = typer.Option(
        False, "--quiet", "-q", help="Suppress output (errors only)"
    ),
):
    """
    UVM run testlist simulation flow (multi-simulator)
    """

    # One pass/fail row per executed test
    report = RecipeReport(
        "uvm-run-testlist",
        title=f"{simulator.value.upper()} DESIGN RUN SIMULATION TESTLIST",
        context={
            "simulator": simulator,
            "target": target,
            "testlist": testlist,
            "test_name": test_name,
            "comp_mode": comp_mode,
            "trace_mode": trace_mode,
            "tandem_enabled": tandem_enabled,
            "uvm_seed": uvm_seed,
            "sim_timeout": sim_timeout,
            "cycle_timeout": cycle_timeout,
        },
        quiet=quiet,
    )
    results = report.metric("Test results")

    # Select the appropriate run function based on simulator
    if simulator == Simulator.vcs:
        run_function = vcs_uvm_run
    elif simulator == Simulator.xcelium:
        run_function = xcelium_uvm_run
    elif simulator == Simulator.questa:
        run_function = questa_uvm_run
    else:
        report.error_exit(f"Unknown simulator: {simulator}", env=True)

    repo_dir = Path.cwd()

    # ==========================================================
    # CHECK PREREQUISITES (fail fast before looping on testlist)
    # ==========================================================
    if comp_mode == CompMode.rtl:
        inout_dir = "sim_rtl"
    elif comp_mode == CompMode.coverage:
        inout_dir = "sim_cov"
    elif comp_mode == CompMode.gate_wc_timing:
        inout_dir = "sim_gate_wc_timing"
    elif comp_mode == CompMode.gate_wc_power:
        inout_dir = "sim_gate_wc_power"
    else:
        report.error_exit("Unknown comp_mode", env=True)

    elab_dir = repo_dir / "build" / target / "elab" / inout_dir
    # Testlist report is stored in a subdirectory named after the testlist
    # so several testlists of the same target can run in the same workdir
    # without overwriting each other
    testlist_name = Path(testlist).stem if testlist else "custom"
    sim_root = repo_dir / "build" / target / "simulation" / inout_dir
    report.set_out_dir(sim_root / testlist_name)
    elab_artifact = {
        Simulator.vcs: elab_dir / "simv",
        Simulator.xcelium: elab_dir / "xcelium.d",
        Simulator.questa: elab_dir / "work",
    }[simulator]
    require_prerequisite(
        elab_artifact,
        f"{simulator.value} elaborated design (comp mode '{comp_mode.value}')",
        f"./cook.py {simulator.value}-uvm-comp -t {target} --comp-mode {comp_mode.value}",
        report=report,
    )

    data = {"testlist": []}

    # Special handling for cvxif testlist
    if testlist and "cvxif" in testlist:
        run_opts = list(run_opts) + ["+enabled_cvxif"]
        print("Detected cvxif testlist, adding run option: +enabled_cvxif")

    if testlist:
        testlist_file = repo_dir / testlist
        try:
            with testlist_file.open("r") as f:
                data = yaml.safe_load(f)
        except FileNotFoundError:
            report.error_exit(f"testlist: File not found: {testlist_file}", env=True)

        if "testlist" in data:
            report.success(f"testlist: Found in file {testlist}")
        else:
            report.error_exit(f"testlist: Not found in file {testlist}", env=True)
    elif test_name:
        data["testlist"] = [{"test": name, "iterations": 1} for name in test_name]
    else:
        report.error_exit("Error: You must provide --testlist or --testname", env=True)

    # Run tests
    for test in data["testlist"]:
        # Single test mode - skip tests not in test_name list
        if testlist and test_name:
            if test["test"] not in test_name:
                continue

        iterations = test.get("iterations", 1)
        # Skip disabled tests (iterations == 0)
        if iterations == 0:
            continue

        for i in range(iterations):
            iter_test_name = f"{test['test']}_{i}"
            child_report = sim_root / iter_test_name / "cook_report.yml"
            try:
                # Call the appropriate simulator run function
                # Note: sim_profile only supported by VCS
                if simulator == Simulator.vcs:
                    run_function(
                        target=target,
                        test_name=iter_test_name,
                        comp_mode=comp_mode,
                        trace_mode=trace_mode,
                        uvm_verbosity=uvm_verbosity,
                        tandem_enabled=tandem_enabled,
                        tb_performance_mode=tb_performance_mode,
                        interactive_gui=interactive_gui,
                        stats=stats,
                        sim_profile=sim_profile,
                        run_opts=run_opts,
                        uvm_seed=uvm_seed,
                        sim_timeout=sim_timeout,
                        cycle_timeout=cycle_timeout,
                        # Each test already has its own output directory.
                        # Passed explicitly: an option left out of a recipe
                        # called as a plain function arrives as the Typer
                        # descriptor, which is truthy, not as its default.
                        run_name=None,
                        quiet=quiet,
                    )
                else:
                    # Xcelium and Questa don't have sim_profile
                    run_function(
                        target=target,
                        test_name=iter_test_name,
                        comp_mode=comp_mode,
                        trace_mode=trace_mode,
                        uvm_verbosity=uvm_verbosity,
                        tandem_enabled=tandem_enabled,
                        tb_performance_mode=tb_performance_mode,
                        interactive_gui=interactive_gui,
                        stats=stats,
                        run_opts=run_opts,
                        uvm_seed=uvm_seed,
                        sim_timeout=sim_timeout,
                        run_name=None,
                        quiet=quiet,
                    )
                results.add_row(
                    status="pass", test=iter_test_name, report=str(child_report)
                )
            except typer.Exit:
                report.error(f"{test['test']}: Returned error")
                results.add_row(
                    status="fail", test=iter_test_name, report=str(child_report)
                )

    # ==========================================================
    # BUILD REPORT
    # ==========================================================
    report.print_metric(results)
    n_total = len(results.values)
    n_pass = sum(1 for row in results.values if row["status"] == "pass")
    report.set_label(f"{n_pass}/{n_total} PASS")
    if n_pass != n_total:
        report.error(f"{n_total - n_pass} test(s) failed")
    else:
        report.success(f"All {n_total} test(s) passed")

    report.end("Completed")
