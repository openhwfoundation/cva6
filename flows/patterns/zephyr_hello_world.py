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
from flows.recipes.zephyr_build import zephyr_build
from flows.utils.autocompletion import ToolchainOption, autocompletion_target

app = typer.Typer()


@app.command()
def zephyr_hello_world(
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
    Build the Hello world application of Zephyr, which ends the simulation.
    """
    zephyr_build(
        target=target,
        toolchain=toolchain,
        app_dir=str(
            Path.cwd() / "verif" / "tests" / "custom" / "zephyr" / "hello_world"
        ),
        test_name="zephyr-hello-world",
        quiet=quiet,
    )
