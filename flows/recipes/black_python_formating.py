# Copyright 2026 Thales France
#
# Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
# You may obtain a copy of the License at https://solderpad.org/licenses/
#
# Original Author: André Sintzoff (andre.sintzoff@thalesgroup.com)

# Please refer to flows/README.md to add target

from pathlib import Path
import typer
from flows.utils.run_cmd import run_cmd
from flows.utils.recipe_report import RecipeReport

app = typer.Typer()


@app.command()
def black_python_formating(
    quiet: bool = typer.Option(
        False, "--quiet", "-q", help="Suppress output (errors only)"
    ),
):
    """
    Format Python files with black
    """
    report = RecipeReport(
        "black-python-formating",
        out_dir=Path.cwd() / "build" / "black_python_formating",
        title="Black Python formating",
        context={},
        quiet=quiet,
    )
    report.step("Launch Black")
    dir_list = [".gitlab-ci", "flows", "pd", "perf-model"]
    get_files_cmd = [
        "git",
        "ls-tree",
        "-r",
        "HEAD",
        "--name-only",
    ] + dir_list
    files = run_cmd(
        cmd=get_files_cmd,
        cwd=None,
        env=None,
        error_patterns=None,
        warning_patterns=None,
        highlight_patterns=[".*"],
        log_file=None,
        timeout=300,
        check=False,
        capture_output=True,
        report=report,
    )
    py_files = ["cook.py"]
    for f in files.split():
        if f.endswith(".py"):
            py_files.append(f)
    black_cmd = ["black", "--diff", "--check"]
    black_cmd += py_files
    run_cmd(
        cmd=black_cmd,
        cwd=None,
        env=None,
        error_patterns=None,
        warning_patterns=None,
        highlight_patterns=[".*"],
        log_file=None,
        timeout=300,
        check=True,
        capture_output=False,
        report=report,
    )

    if report.failed:
        report.error("Black formatting check failed")
    else:
        report.success(f"All {len(py_files)} Python files properly formatted")

    report.end("Completed")
