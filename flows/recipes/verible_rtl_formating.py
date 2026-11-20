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
import fnmatch
import shutil
import typer
from flows.utils.run_cmd import run_cmd
from flows.utils.target_config import read_config_or_exit_flist
from flows.utils.autocompletion import autocompletion_target
from flows.utils.recipe_report import RecipeReport

app = typer.Typer()

# Same scope as the CI Verible check (.github/workflows/verible.yml): the
# CVA6 RTL under core/, without its submodules and the generated configuration
# packages.
FORMAT_ROOT = "core"
FORMAT_EXCLUDE = [
    "core/include/*_config_pkg.sv",
    "core/cvfpu/*",
    "core/cache_subsystem/hpdcache/*",
]


def files_to_format(files, repo_dir):
    """Keep the files of `files` that belong to the formatted scope."""
    repo_dir = Path(repo_dir).resolve()
    kept = []
    for f in files:
        try:
            rel = Path(f).resolve().relative_to(repo_dir).as_posix()
        except ValueError:
            continue
        if not rel.startswith(FORMAT_ROOT + "/"):
            continue
        if any(fnmatch.fnmatch(rel, pat) for pat in FORMAT_EXCLUDE):
            continue
        kept.append(f)
    return kept


@app.command()
def verible_rtl_formating(
    target: str = typer.Option(
        ...,
        "--target",
        "-t",
        help="CVA6 user configuration",
        autocompletion=autocompletion_target,
    ),
    quiet: bool = typer.Option(
        False, "--quiet", "-q", help="Suppress output (errors only)"
    ),
):
    """
    Format CVA6 RTL files with Verible, failing if any file was not formatted
    (mandatory for submit PR)
    """

    repo_dir = Path.cwd()
    verible_dir = repo_dir / "build" / target / "verible"

    # Init report (written in verible_dir at the end of the recipe):
    # prints the title banner and the "Options" table from the context
    report = RecipeReport(
        "verible-rtl-formating",
        out_dir=verible_dir,
        title="Verible RTL formating",
        context={"target": target},
        quiet=quiet,
    )

    verible_path = shutil.which("verible-verilog-format")
    if verible_path is not None:
        report.success(f"verible-verilog-format: {verible_path}")
    else:
        report.error_exit("verible-verilog-format: Not found", env=True)

    # ==========================================================
    # CLEAN
    # ==========================================================
    report.step("Clean")
    try:
        if verible_dir.exists():
            shutil.rmtree(verible_dir)
            report.info(f"remove {verible_dir}")
    except Exception as e:
        report.error_exit(f"Clean error : {e}", env=True)

    verible_dir.mkdir(parents=True, exist_ok=True)
    report.info(f"create {verible_dir}")

    # ==========================================================
    # GET FILE LIST TO FORMAT
    # ==========================================================

    flist_files = read_config_or_exit_flist(target, report)
    analyse_files = files_to_format(flist_files, repo_dir)
    report.info(
        f"{len(analyse_files)} of {len(flist_files)} filelist files in scope"
        f" ({FORMAT_ROOT}/, without {', '.join(FORMAT_EXCLUDE)})"
    )

    # ==========================================================
    # BUILD VERIBLE COMMAND
    # ==========================================================

    # With --verify, Verible only reports the files that would change and
    # returns 1 if there is any; without it, --inplace always returns 0. The
    # check runs first, then the formatting. Several files require --inplace.
    check_cmd = ["verible-verilog-format", "--inplace", "--verify"] + analyse_files
    verible_cmd = ["verible-verilog-format", "--inplace"] + analyse_files

    # ==========================================================
    # CHECK FORMATTING
    # ==========================================================
    report.step("Check formatting")

    check_log = verible_dir / "verible-check.log"

    run_cmd(
        cmd=check_cmd,
        report=report,
        cwd=None,
        env=None,
        error_patterns=["Needs formatting"],
        warning_patterns=None,
        highlight_patterns=None,
        log_file=check_log,
        timeout=300,
        check=True,
        capture_output=False,
    )

    # ==========================================================
    # LAUNCH VERIBLE
    # ==========================================================
    report.step("Launch Verible")

    log_file = verible_dir / "verible-cmd.log"

    run_cmd(
        cmd=verible_cmd,
        report=report,
        cwd=None,
        env=None,
        error_patterns=None,
        warning_patterns=None,
        highlight_patterns=None,
        log_file=log_file,
        timeout=300,
        check=True,
        capture_output=False,
    )

    if report.failed:
        report.error(
            "Verible formatting check failed: the files were reformatted,"
            " commit them"
        )
    else:
        report.success(f"All {len(analyse_files)} RTL files properly formatted")

    # ==========================================================
    # List
    # ==========================================================

    gen_files = [check_log, log_file]

    report.step("Generated files")
    for genfile in gen_files:
        if genfile.exists():
            report.info(f"> {genfile}")

    report.end("Completed")
