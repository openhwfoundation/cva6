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
import yaml
import typer
from flows.recipes.sw_compile import sw_compile
from flows.utils.config_loader import load_compiler_config
from flows.utils.recipe_report import RecipeReport
from flows.utils.autocompletion import (
    ToolchainOption,
    autocompletion_target,
    autocompletion_testlist,
    autocompletion_testname_in_testlist,
)

app = typer.Typer()


# ==========================================================
# RECIPE - COMPILATION OF TESTLIST
# ==========================================================


@app.command()
def sw_compile_testlist(
    target: str = typer.Option(
        ...,
        "--target",
        "-t",
        help="CVA6 user configuration",
        autocompletion=autocompletion_target,
    ),
    toolchain: ToolchainOption = typer.Option(
        ..., "--toolchain", "-c", help="Toolchain defined in $CONFIG_DIR/compiler.yml"
    ),
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
        autocompletion=autocompletion_testname_in_testlist,
    ),
    march: str = typer.Option(
        None, help="march custom instead of default one from config/target"
    ),
    mabi: str = typer.Option(
        None, help="mabi custom instead of default one from config/target"
    ),
    quiet: bool = typer.Option(
        False, "--quiet", "-q", help="Suppress output (errors only)"
    ),
):
    """
    Build Test lists.
    """

    repo_dir = Path.cwd()
    compile_root = repo_dir / "build" / target / "compile"

    # One pass/fail row per compiled test, stored in a
    # subdirectory named after the testlist so several testlists of the
    # same target can run in the same workdir without overwriting each
    # other
    report = RecipeReport(
        "sw-compile-testlist",
        out_dir=compile_root / Path(testlist).stem,
        title="Software compilation of testlist",
        context={
            "target": target,
            "toolchain": toolchain,
            "testlist": testlist,
            "test_name": test_name,
            "march": march,
            "mabi": mabi,
        },
        quiet=quiet,
    )
    results = report.metric("Compilation results")

    # Detect LLVM mode to select llvm_opts instead of gcc_opts in testlists
    # (same detection as in sw_compile)
    COMPILER_DATA = load_compiler_config()
    is_llvm = COMPILER_DATA[toolchain.value]["CLANG"] is not None

    testlist_file = repo_dir / testlist

    try:
        with testlist_file.open("r") as f:
            data = yaml.safe_load(f)
    except FileNotFoundError:
        report.error_exit(f"testlist: File Not found in file {testlist_file}", env=True)

    if "testlist" in data:
        report.success(f"testlist: Found in file {testlist}")
    else:
        report.error_exit(f"testlist: Not found in file {testlist}", env=True)

    for test in data["testlist"]:
        # Single test mode
        if test_name:
            if test["test"] not in test_name:
                continue
        iterations = test.get("iterations", 1)
        # Skip disables tests
        if iterations == 0:
            continue

        # Select compile options: llvm_opts (if LLVM toolchain and key present),
        # otherwise gcc_opts
        opts_key = "llvm_opts" if is_llvm and "llvm_opts" in test else "gcc_opts"

        if "path_var" in test:
            if test["path_var"] == "TESTS_PATH":
                test["path_var"] = "verif/tests"
            elif test["path_var"] == "TESTS_GEN_PATH":
                test["path_var"] = f"build/{target}/dv_generated"
            else:
                report.warning(f"Check {test['path_var']} is a valid path")
            test["asm_tests"] = test["asm_tests"].replace(
                "<path_var>", test["path_var"]
            )
            test[opts_key] = test[opts_key].replace("<path_var>", test["path_var"])

        # Case where mabi or march is specified in <testlist>.yml
        if "mabi" not in test:
            test["mabi"] = mabi
        if "march" not in test:
            test["march"] = march

        test[opts_key] = test[opts_key].split()
        test["asm_tests"] = test["asm_tests"].split()

        report.param_table(
            {
                "Test": test["test"],
                opts_key: test[opts_key],
                "Iterations": test["iterations"],
                "Test path": test["asm_tests"],
                "march": test["march"],
                "mabi": test["mabi"],
            },
            "Test parameters",
        )
        linker_file = None
        inc_dirs = []
        options = []
        preprocessor_directives = []

        for item in test[opts_key]:
            if item.startswith("-I"):
                inc_dirs += [item[2:]]
            elif item.startswith("-T"):
                linker_file = item[2:]
            elif item.startswith("-D"):
                preprocessor_directives += [item[2:]]
            elif item.startswith("-"):
                options += [item[1:]]
            else:
                test["asm_tests"] += [item]

        for i in range(iterations):
            src_file_name = [
                src.replace("<iterations>", str(i)) for src in test["asm_tests"]
            ]
            test_file_name = f"{test['test']}_{i}"
            child_report = compile_root / test_file_name / "cook_report.yml"
            try:
                sw_compile(
                    target=target,
                    toolchain=toolchain,
                    src_files=src_file_name,
                    inc_dirs=inc_dirs,
                    linker_file=linker_file,
                    options=options,
                    march=test["march"],
                    mabi=test["mabi"],
                    preprocessor_directives=preprocessor_directives,
                    benchmark_iterations=None,
                    test_name=test_file_name,
                    quiet=quiet,
                )
                results.add_row(
                    status="pass", test=test_file_name, report=str(child_report)
                )
            except typer.Exit:
                report.error(f"{test['test']}: Return Error")
                results.add_row(
                    status="fail", test=test_file_name, report=str(child_report)
                )

    # ==========================================================
    # BUILD REPORT
    # ==========================================================
    report.print_metric(results)
    n_total = len(results.values)
    n_pass = sum(1 for row in results.values if row["status"] == "pass")
    report.set_label(f"{n_pass}/{n_total} PASS")
    if n_pass != n_total:
        report.error(f"{n_total - n_pass} compilation(s) failed")
    else:
        report.success(f"All {n_total} compilation(s) passed")

    report.end("Completed")
