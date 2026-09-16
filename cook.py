#!/usr/bin/env python3
# Copyright 2026 Thales France
#
# Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
# You may obtain a copy of the License at https://solderpad.org/licenses/
#
# Original Author: Yannick Casamatta (yannick.casamatta@thalesgroup.com)

# Please refer to flows/README.md to add target

import importlib
from pathlib import Path
import pkgutil
import sys
import typer

app = typer.Typer()

# The recipes address the repository by relative path, `config/target/` and
# `build/` among them, and a path given on the command line is resolved by
# the shell that typed it. The two only agree when the current directory is
# the root of the checkout: run from `verif/`, `--testlist ./tests/x.yaml`
# would name something the recipe cannot find while `build/` would be
# created under `verif/`.
#
# Checked once here rather than left to each recipe, and before Typer parses
# anything so the message is the first thing printed.
REPO_DIR = Path(__file__).resolve().parent


def check_cwd():
    "Stop unless cook.py is run from the root of its own checkout"
    if Path.cwd().resolve() != REPO_DIR:
        print(
            f"cook.py must be run from the root of the repository it belongs to\n"
            f"  expected: {REPO_DIR}\n"
            f"  current:  {Path.cwd().resolve()}\n"
            f"  The recipes read config/target/ and write build/ relative to it.",
            file=sys.stderr,
        )
        sys.exit(1)


def load_commands(folder: str):
    # folder to look for typer commands
    package = f"flows.{folder}"
    pkg = importlib.import_module(package)

    for _, module_name, _ in pkgutil.iter_modules(pkg.__path__):
        full_module_name = f"{package}.{module_name}"
        module = importlib.import_module(full_module_name)
        if hasattr(module, "app"):
            # app.add_typer(module.app, name=module_name)
            app.add_typer(module.app)


# Load all command in commands and patterns folders
load_commands("recipes")
load_commands("patterns")
load_commands("macros")

if __name__ == "__main__":
    check_cwd()
    app()
