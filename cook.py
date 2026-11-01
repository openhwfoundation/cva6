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

import sys

# Ahead of the other imports, which a too old interpreter fails on first
PYTHON_MIN = (3, 12)
if sys.version_info < PYTHON_MIN:
    sys.exit(
        f"cook.py needs Python {PYTHON_MIN[0]}.{PYTHON_MIN[1]} or later, "
        f"{sys.executable} is {sys.version.split()[0]}: see the Python "
        f"Environment section of flows/README.md"
    )

# pylint: disable=wrong-import-position
import importlib
from pathlib import Path
import pkgutil
import subprocess
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


# Commands run before the submodules are patched: the setup recipes, and the
# regression, which runs git-dependencies itself before any elaboration
SETUP_COMMANDS = ("git-dependencies", "self-check", "full-regression")


def check_submodule_patches():
    """
    Stop when a patch of a Git submodule is not applied.

    The patches come with the repository: a pull can bring a new one, and
    nothing would apply it before the next `git-dependencies`. The RTL or
    testbench would then be used unpatched without any message. The check is
    `git apply --reverse --check`, which modifies nothing.
    """
    command = next((a for a in sys.argv[1:] if not a.startswith("-")), None)
    if command is None or command in SETUP_COMMANDS:
        return
    # pylint: disable-next=import-outside-toplevel
    from flows.recipes.git_dependencies import submodule_patches

    missing = []
    for _, patch_file, patch_cwd in submodule_patches(REPO_DIR):
        result = subprocess.run(
            ["git", "apply", "--reverse", "--check", str(patch_file)],
            cwd=patch_cwd,
            capture_output=True,
            check=False,
        )
        if result.returncode != 0:
            missing.append(
                f"{patch_file.relative_to(REPO_DIR)} in {patch_cwd.relative_to(REPO_DIR)}"
            )
    if missing:
        print(
            "Patches of the Git submodules not applied:\n  "
            + "\n  ".join(missing)
            + "\n  Run: ./cook.py git-dependencies",
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
    check_submodule_patches()
    app()
