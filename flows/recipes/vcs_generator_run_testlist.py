# Copyright 2026 Thales France
#
# Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
# You may obtain a copy of the License at https://solderpad.org/licenses/
#
# Original Author: Théo GIOVINAZZI

import shlex
from pathlib import Path

import typer
import yaml

from flows.recipes.vcs_generator_run import vcs_generator_run
from flows.utils.recipe_report import RecipeReport
from flows.utils.autocompletion import autocompletion_testlist

app = typer.Typer()


# ==========================================================
# RECIPE
# ==========================================================


@app.command()
def vcs_generator_run_testlist(
    testlist: str = typer.Option(
        ...,
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
    ),
    seed: int = typer.Option(None, help="randomized if not provided"),
    batch_size: int = typer.Option(1, help="Number of tests to generate per run batch"),
    quiet: bool = typer.Option(
        False, "--quiet", "-q", help="Suppress output (errors only)"
    ),
):
    """
    VCS UVM generator run testlist simulation flow
    """
    repo_dir = Path.cwd()

    # One pass/fail row per generated test.
    # Testlist report is stored in a subdirectory named after the testlist
    # so several testlists can run in the same workdir without overwriting
    # each other
    report = RecipeReport(
        "vcs-generator-run-testlist",
        out_dir=repo_dir / "build" / "cv32a65x" / "dv_generated" / Path(testlist).stem,
        title="VCS DESIGN RUN GENERATOR TESTLIST",
        context={
            "testlist": testlist,
            "test_name": test_name,
            "seed": seed,
            "batch_size": batch_size,
        },
        quiet=quiet,
    )
    results = report.metric("Generation results")

    # Per-test output dirs of the vcs-generator-run sub-recipe
    dv_generated_dir = repo_dir / "build" / "cv32a65x" / "dv_generated"

    data = {"testlist": []}

    testlist_file = repo_dir / testlist

    try:
        with testlist_file.open("r") as f:
            raw = yaml.safe_load(f)
            if isinstance(raw, list):
                data = {"testlist": raw}
            elif isinstance(raw, dict) and "testlist" in raw:
                data = raw
            else:
                report.error_exit(f"YAML format error in {testlist_file}", env=True)

    except FileNotFoundError:
        report.error_exit(f"File Not found in file {testlist_file}", env=True)

    for test in data["testlist"]:
        # Single test mode
        if testlist and test_name:
            if test["test"] not in test_name:
                continue

        # Skip disabled tests
        if "iterations" not in test:
            report.error_exit("Iterations not found in the TestList", env=True)

        iterations = test["iterations"]

        if iterations == 0:
            continue

        child_report = dv_generated_dir / test["test"] / "cook_report.yml"
        try:
            # ==========================================================
            # RUN GENERATOR
            # ==========================================================

            gen_test = test.get("gen_test", "cva6_instr_base_test_c")

            gen_opts_str = test.get("gen_opts", "")
            opts = shlex.split(gen_opts_str)

            vcs_generator_run(
                test_name=test["test"],
                gen_test=gen_test,
                iterations=iterations,
                batch_size=batch_size,
                extensions=[],
                directed_instrs=[],
                type_instr="",
                seed=seed,
                verbose=False,
                tvec_alignment=8,
                num_of_sub_program=0,
                illegal_instr_ratio=0,
                unsupported_instr_ratio=0,
                instr_cnt=300,
                opts=opts,
                quiet=quiet,
            )
            results.add_row(status="pass", test=test["test"], report=str(child_report))

        except typer.Exit:
            report.error(f"{test['test']}: Return Error")
            results.add_row(status="fail", test=test["test"], report=str(child_report))

    # ==========================================================
    # BUILD REPORT
    # ==========================================================
    report.print_metric(results)
    n_total = len(results.values)
    n_pass = sum(1 for row in results.values if row["status"] == "pass")
    report.set_label(f"{n_pass}/{n_total} PASS")
    if n_pass != n_total:
        report.error(f"{n_total - n_pass} generation(s) failed")
    else:
        report.success(f"All {n_total} generation(s) passed")

    report.end("Completed")
