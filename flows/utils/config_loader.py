# Copyright 2026 Thales France
#
# Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
# You may obtain a copy of the License at https://solderpad.org/licenses/
#
# Original Author: Yannick Casamatta (yannick.casamatta@thalesgroup.com)

# Please refer to flows/README.md to add target

import os
from pathlib import Path
import yaml
from rich.console import Console
from rich.panel import Panel

console = Console()

config_dir = Path(os.getenv("CONFIG_DIR", Path.cwd() / "flows" / "config"))
print(config_dir)


def _read_config(config_file: str, verbose: bool):
    DATA = None
    try:
        with (config_dir / config_file).open("r") as f:
            DATA = yaml.safe_load(f)
    except FileNotFoundError:
        if verbose:
            console.print(
                Panel(
                    f"[red]{config_dir}/{config_file}[/red]",
                    title="ERROR CONFIG NOT FOUND",
                    title_align="left",
                    border_style="red",
                    expand=False,
                )
            )
    except yaml.YAMLError:
        if verbose:
            console.print(
                Panel(
                    f"[red]{config_dir}/{config_file}[/red]",
                    title="ERROR READ YAML CONFIG",
                    title_align="left",
                    border_style="red",
                    expand=False,
                )
            )
    # Test to detect dummy config (uninitialised environement
    # Rename dummy1 key in yaml to disable this error
    if DATA is not None and "dummy1" in DATA:
        if verbose:
            console.print(
                Panel(
                    f"[red]{config_dir}/{config_file}\n\
        Please configure flows/config/{config_file} \n\
        to fit your environment or set $CONFIG_DIR env variable\n\
        to a path that contains your personnal yml config files[/red]",
                    title="ERROR CONFIG NOT INITIALISED",
                    title_align="left",
                    border_style="red",
                    expand=False,
                )
            )
    return DATA


def load_techno_config(verbose: bool = True):
    return _read_config("techno.yml", verbose)


def load_compiler_config(verbose: bool = True):
    return _read_config("compiler.yml", verbose)


def is_clang_toolchain(toolchain, verbose: bool = False):
    """
    True when `toolchain` selects a Clang/LLVM compiler.

    Patterns use it to pick compiler-specific options: a flag understood by
    one compiler is often rejected outright by the other, and an option that
    fixes a GCC code generation issue can cost performance on Clang (or the
    reverse). `toolchain` accepts the Enum or its string value.
    """
    name = getattr(toolchain, "value", toolchain)
    entry = load_compiler_config(verbose).get(name) or {}
    return bool(entry.get("CLANG"))
