# Copyright 2026 OpenHW Foundation
#
# Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
# You may obtain a copy of the License at https://solderpad.org/licenses/
#
# Original Author: Junchao Chen (junchao.chen@eclipse-foundation.org)

# Please refer to flows/README.md to add target

"""
Run a testlist on the TestHarness testbench.

The counterpart of `uvm-run-testlist` for the harness: one elaboration,
one run per test, and a single report carrying the verdict of each.
"""

from enum import Enum
from pathlib import Path

import typer
import yaml

from flows.utils.autocompletion import (
    CompMode,
    TraceMode,
    UvmVerbosity,
    autocompletion_target,
    autocompletion_testlist,
)
from flows.utils.recipe_report import RecipeReport
from flows.recipes.questa_testharness_run import questa_testharness_run
from flows.recipes.vcs_testharness_run import vcs_testharness_run
from flows.recipes.verilator_testharness_run import (
    SIMULATION_TIMEOUT,
    verilator_testharness_run,
)
from flows.recipes.xcelium_testharness_run import xcelium_testharness_run

app = typer.Typer()


class Simulator(str, Enum):
    "Simulators able to run the TestHarness"

    verilator = "verilator"
    vcs = "vcs"
    questa = "questa"
    xcelium = "xcelium"


@app.command()
def testharness_run_testlist(
    simulator: Simulator = typer.Option(
        Simulator.verilator,
        "--simulator",
        "-s",
        help="TestHarness simulator",
    ),
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
        help="Testlist of the tests to run",
        autocompletion=autocompletion_testlist,
    ),
    comp_mode: CompMode = typer.Option(
        CompMode.rtl, help="Compilation mode; only rtl is supported"
    ),
    trace_mode: TraceMode = typer.Option(
        TraceMode.notrace,
        help="notrace, fast (VCD), or compact (FST); must match the build",
    ),
    sim_timeout: int = typer.Option(
        SIMULATION_TIMEOUT, "--sim-timeout", help="Simulation timeout in seconds"
    ),
    uvm_verbosity: UvmVerbosity = typer.Option(
        # LOW rather than NONE: the harness reports its verdict with
        # `uvm_info(..., UVM_LOW)`, and NONE drops the line the recipes
        # read the result from. Ignored by Verilator.
        UvmVerbosity.low,
        help="UVM verbosity of the event-driven simulators",
    ),
    quiet: bool = typer.Option(
        False, "--quiet", "-q", help="Suppress output (errors only)"
    ),
) -> None:
    """
    Run a testlist on the TestHarness testbench
    """
    repo_dir = Path.cwd()
    testlist_file = Path(testlist)
    build_root = repo_dir / "build" / target
    report = RecipeReport(
        "testharness-run-testlist",
        out_dir=build_root
        / "simulation"
        / f"testharness_{simulator.value}_{testlist_file.stem}",
        title="TESTHARNESS TESTLIST RUN",
        context={
            "simulator": simulator.value,
            "target": target,
            "testlist": testlist,
            "comp_mode": comp_mode.value,
            "trace_mode": trace_mode.value,
        },
        quiet=quiet,
    )
    results = report.metric("Test results")

    report.step("Read the testlist")
    if not testlist_file.is_file():
        report.error_exit(f"Missing testlist: {testlist_file}", env=True)
    try:
        data = yaml.safe_load(testlist_file.read_text(encoding="utf-8"))
    except (OSError, yaml.YAMLError) as e:
        report.error_exit(f"Could not read {testlist_file}: {e}", env=True)
    if not isinstance(data, dict) or not isinstance(data.get("testlist"), list):
        report.error_exit(f"No 'testlist' sequence in {testlist_file}", env=True)

    # The compiled name of a test carries its iteration, the way
    # sw-compile-testlist named it: `iterations: 0` disables a test
    # without removing it from the list.
    names = []
    for entry in data["testlist"]:
        if not isinstance(entry, dict) or not isinstance(entry.get("test"), str):
            report.error_exit(
                f"Each entry of {testlist_file} needs a string 'test'", env=True
            )
        for iteration in range(entry.get("iterations", 1)):
            names.append(f"{entry['test']}_{iteration}")
    if not names:
        report.error_exit(f"No enabled test in {testlist_file}", env=True)
    report.success(f"{len(names)} test(s) to run")

    for name in names:
        report.step(f"Run {name}")
        run_dir = (
            build_root / "simulation" / f"sim_rtl_{simulator.value}_testharness" / name
        )
        # Each test already has its own output directory, hence run_name.
        # The options are passed explicitly: one left out of a recipe
        # called as a plain function arrives as the Typer descriptor,
        # which is truthy, not as its default.
        arguments = {
            "target": target,
            "test_name": name,
            "comp_mode": comp_mode,
            "trace_mode": trace_mode,
            "run_name": None,
            "sim_timeout": sim_timeout,
            "quiet": quiet,
        }
        try:
            if simulator == Simulator.verilator:
                # Only Verilator opens a waveform viewer of its own.
                verilator_testharness_run(interactive_gui=False, **arguments)
            else:
                # The event-driven simulators take the UVM verbosity, the
                # harness reporting its verdict through uvm_info.
                arguments["uvm_verbosity"] = uvm_verbosity
                if simulator == Simulator.vcs:
                    vcs_testharness_run(**arguments)
                elif simulator == Simulator.questa:
                    questa_testharness_run(**arguments)
                else:
                    xcelium_testharness_run(**arguments)
            results.add_row(status="pass", test=name, report=str(run_dir))
        except typer.Exit:
            report.error(f"{name}: Returned error")
            results.add_row(status="fail", test=name, report=str(run_dir))

    report.print_metric(results)
    n_total = len(results.values)
    n_pass = sum(1 for row in results.values if row["status"] == "pass")
    report.set_label(f"{n_pass}/{n_total} PASS")
    if n_pass != n_total:
        report.error(f"{n_total - n_pass} test(s) failed")
    else:
        report.success(f"{n_total} test(s) passed")

    report.end()
