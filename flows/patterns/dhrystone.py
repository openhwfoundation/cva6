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
import typer
from flows.recipes.sw_compile import sw_compile
from flows.utils.autocompletion import ToolchainOption, autocompletion_target
from flows.utils.config_loader import is_clang_toolchain

app = typer.Typer()


@app.command()
def dhrystone(
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
    Build DHRYSTONE pattern.
    """
    repo_dir = Path.cwd()

    src_files = [
        str(repo_dir / "verif" / "tests" / "custom" / "dhrystone" / "dhrystone_main.c"),
        str(repo_dir / "verif" / "tests" / "custom" / "dhrystone" / "dhrystone.c"),
        str(repo_dir / "verif" / "tests" / "custom" / "common" / "syscalls.c"),
        str(repo_dir / "verif" / "tests" / "custom" / "common" / "crt.S"),
    ]

    inc_dirs = [
        str(repo_dir / "verif" / "tests" / "custom" / "env"),
        str(repo_dir / "verif" / "tests" / "custom" / "common"),
        str(repo_dir / "verif" / "tests" / "custom" / "dhrystone"),
    ]

    linker_file = str(repo_dir / "config" / "target" / target / "link.ld")

    options = [
        # Legacy K&R C: since GCC 15 the default standard is C23, where
        # unprototyped declarations like `void f()` no longer compile
        "std=gnu17",
        "O3",
        # See coremark.py: keeps GCC from turning the memcpy/memset loops of
        # syscalls.c into self-recursive calls. Part of the reference benchmark
        # configuration; do not swap it for -fno-builtin, which would stop
        # strcpy being inlined in the measured loop. Clang needs nothing.
        *(
            []
            if is_clang_toolchain(toolchain)
            else ["fno-tree-loop-distribute-patterns"]
        ),
        "static",
        "mcmodel=medany",
        "fvisibility=hidden",
        "nostartfiles",
        "fno-inline",
        "Wno-implicit-function-declaration",
        "Wno-implicit-int",
    ]

    # Iterations executed in the GLOBAL_PATTERN timing window. Single
    # definition: compiled in the binary (-DNUMBER_OF_RUNS) and recorded
    # in the build manifest, from which the run recipes compute the
    # Dhrystone/MHz and DMIPS/MHz scores (iterations * 1e6 / measured
    # cycles, the latter divided by 1757).
    iterations = 50

    preprocessor_directives = [
        "NOPRINT",
        f"NUMBER_OF_RUNS={iterations}",
    ]

    test_name = "dhrystone"

    sw_compile(
        target=target,
        toolchain=toolchain,
        src_files=src_files,
        inc_dirs=inc_dirs,
        linker_file=linker_file,
        options=options,
        march=march,
        mabi=mabi,
        preprocessor_directives=preprocessor_directives,
        benchmark_iterations=iterations,
        test_name=test_name,
        quiet=quiet,
    )
