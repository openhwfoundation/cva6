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
Build the Hello world program to run under the RISC-V proxy kernel.

The program is a plain user program of the toolchain (newlib start files,
default linker script): pk loads it and serves its system calls, so
printf goes through the write system call instead of syscalls.c.
"""

from pathlib import Path
import shutil
import typer
from flows.recipes.pk_build import pk_build_dir
from flows.recipes.sw_compile import sw_compile
from flows.utils.autocompletion import ToolchainOption, autocompletion_target
from flows.utils.manifest import get_manifest_option, read_manifest
from flows.utils.recipe_report import RecipeReport

app = typer.Typer()


@app.command()
def pk_hello_world(
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
    quiet: bool = typer.Option(
        False, "--quiet", "-q", help="Suppress output (errors only)"
    ),
):
    """
    Build Hello world pattern to run under the proxy kernel (pk-build first).
    """
    repo_dir = Path.cwd()
    test_name = "pk-hello-world"

    # The program is built for the march/mabi pk was built for
    pk_dir = pk_build_dir(target, repo_dir)
    compile_dir = repo_dir / "build" / target / "compile" / test_name
    # Report of the prerequisite check, written only when it fails; the one
    # of the build is written by sw-compile
    report = RecipeReport(
        "pk-hello-world",
        out_dir=compile_dir,
        title="Proxy kernel Hello world",
        context={"target": target, "toolchain": toolchain},
        quiet=quiet,
    )
    pk_manifest = read_manifest(pk_dir, report)
    pk_binary = get_manifest_option(pk_manifest, "pk")
    if not pk_binary or not Path(pk_binary).exists():
        # No ELF left from an earlier build for the run recipes to pick up
        shutil.rmtree(compile_dir, ignore_errors=True)
        report.error_exit(
            f"Missing prerequisite: proxy kernel of {target}\n"
            f"  Expected: {pk_dir}\n"
            f"  Run first: ./cook.py pk-build -t {target} -c {toolchain.value}",
            env=True,
        )

    sw_compile(
        target=target,
        toolchain=toolchain,
        src_files=[
            str(
                repo_dir
                / "verif"
                / "tests"
                / "custom"
                / "hello_world"
                / "hello_world.c"
            )
        ],
        inc_dirs=[],
        linker_file="",
        options=["g", "O2", "static"],
        march=get_manifest_option(pk_manifest, "march"),
        mabi=get_manifest_option(pk_manifest, "mabi"),
        preprocessor_directives=[],
        benchmark_iterations=None,
        test_name=test_name,
        pk_dir=str(pk_dir),
        quiet=quiet,
    )
