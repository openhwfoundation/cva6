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
def coremark(
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
    Build COREMARK pattern.
    """
    repo_dir = Path.cwd()

    src_files = [
        str(repo_dir / "verif" / "tests" / "custom" / "coremark" / "coremark_main.c"),
        str(repo_dir / "verif" / "tests" / "custom" / "coremark" / "uart.c"),
        str(repo_dir / "verif" / "tests" / "custom" / "coremark" / "core_list_join.c"),
        str(repo_dir / "verif" / "tests" / "custom" / "coremark" / "core_matrix.c"),
        str(repo_dir / "verif" / "tests" / "custom" / "coremark" / "core_portme.c"),
        str(repo_dir / "verif" / "tests" / "custom" / "coremark" / "core_state.c"),
        str(repo_dir / "verif" / "tests" / "custom" / "coremark" / "core_util.c"),
        str(repo_dir / "verif" / "tests" / "custom" / "common" / "syscalls.c"),
        str(repo_dir / "verif" / "tests" / "custom" / "common" / "crt.S"),
    ]

    inc_dirs = [
        str(repo_dir / "verif" / "tests" / "custom" / "env"),
        str(repo_dir / "verif" / "tests" / "custom" / "common"),
    ]

    linker_file = str(repo_dir / "config" / "target" / target / "link.ld")

    options = [
        # Legacy K&R C: since GCC 15 the default standard is C23, where
        # unprototyped declarations like `void f()` no longer compile
        "std=gnu17",
        "O3",
        # syscalls.c defines memcpy/memset with plain byte-wise loops. From -O2
        # on, GCC recognises those loops as memcpy/memset idioms and rewrites
        # them into calls to the very function being defined, making it
        # infinitely self-recursive, and bare-metal there is no stack guard.
        #
        # This is the flag of the reference benchmark configuration. Do not
        # swap it for the portable -fno-builtin, which would also bar the
        # inlining of the other string functions and change what the benchmark
        # measures. Clang never emits that recursion and rejects the flag, so a
        # clang score is not comparable to a GCC one.
        *(
            []
            if is_clang_toolchain(toolchain)
            else ["fno-tree-loop-distribute-patterns"]
        ),
        "g",
        "static",
        "mcmodel=medany",
        "fvisibility=hidden",
        "nostartfiles",
        "funroll-all-loops",
        "ffunction-sections",
        "fdata-sections",
        "Wl,-gc-sections",
        "falign-functions=16",
        "Wno-implicit-function-declaration",
        "Wno-implicit-int",
    ]

    # Iterations executed in the GLOBAL_PATTERN timing window. Single
    # definition: compiled in the binary (-DITERATIONS) and recorded in
    # the build manifest, from which the run recipes compute the
    # CM/MHz score (iterations * 1e6 / measured cycles).
    iterations = 1

    preprocessor_directives = [
        "_LITTLE_ENDIAN_",
        "NOPRINT",
        "HAS_PRINTF=0",
        f"ITERATIONS={iterations}",
        "PERFORMANCE_RUN",
        "SKIP_TIME_CHECK",
    ]

    test_name = "coremark"

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
