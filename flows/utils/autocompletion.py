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
CLI option types and shell autocompletion helpers for cook.py recipes.

Enums define the closed sets of values accepted by recipe options
(compilation mode, trace mode, toolchain...); the autocompletion_*
functions provide dynamic completion based on the project tree
(targets, compiled tests, testlists...).
"""

import re
from enum import Enum
from pathlib import Path
import typer
import yaml
from flows.utils.config_loader import load_techno_config, load_compiler_config

TECHNO_DATA = load_techno_config(verbose=False)
COMPILER_DATA = load_compiler_config(verbose=False)


class CompMode(str, Enum):
    rtl = "rtl"
    gate_wc_power = "gate_wc_power"
    gate_wc_timing = "gate_wc_timing"
    coverage = "coverage"


class TraceMode(str, Enum):
    gui = "gui"
    fast = "fast"
    compact = "compact"
    notrace = "notrace"


class UvmVerbosity(str, Enum):
    none = "NONE"
    low = "LOW"
    medium = "MEDIUM"
    high = "HIGH"
    full = "FULL"
    debug = "DEBUG"


class Cva6Hier(str, Enum):
    obi = "obi"
    axi = "axi"


class FpgaBoard(str, Enum):
    genesys2 = "genesys2"
    kc705 = "kc705"
    vc707 = "vc707"
    nexys_video = "nexys_video"


class AlteraBoard(str, Enum):
    agilex7 = "agilex7"


# Every board of both vendors, for what is shared between the two flows:
# the bootloader is the same artifact whatever the FPGA family. Derived
# from the two enums rather than listing them again, so a board added to
# either one appears here without a second edit.
AnyBoard = Enum(
    "AnyBoard",
    {b.name: b.value for b in FpgaBoard} | {b.name: b.value for b in AlteraBoard},
    type=str,
)


if TECHNO_DATA is not None:
    TechnoOption = Enum(
        "TechnoOption", {key.upper(): key for key in TECHNO_DATA.keys()}
    )
else:
    TechnoOption = Enum("TechnoOption", [])

if COMPILER_DATA is not None:
    ToolchainOption = Enum(
        "ToolchainOption", {key.upper(): key for key in COMPILER_DATA.keys()}
    )
else:
    ToolchainOption = Enum("ToolchainOption", [])


def autocompletion_target():
    target_list = []
    target_path = Path.cwd() / "config" / "target"
    if not target_path.exists():
        return target_list
    for elmt in target_path.iterdir():
        if elmt.is_dir():
            target_list += [elmt.name]
    return target_list


def autocompletion_testname_compiled(ctx: typer.Context):
    testname_list = []
    target = ctx.params["target"]
    target_build_path = Path.cwd() / "build" / target / "compile"
    if not (target and target_build_path.exists()):
        print("Missing target or any compiled test found")
        return testname_list
    for d in target_build_path.iterdir():
        if d.is_dir():
            testname_list += [d.name]
    return testname_list


def autocompletion_testlist(ctx: typer.Context):
    testlist_list = []
    testlist_path_list = [Path.cwd() / "verif" / "tests"]
    target = ctx.params["target"]
    if target:
        testlist_path_list += [Path.cwd() / "config" / "target" / target / "verif"]
    for path in testlist_path_list:
        if path.exists():
            for file in path.iterdir():
                if file.is_file() and (
                    file.name.endswith(".yaml") or file.name.endswith(".yml")
                ):
                    testlist_list += [str(file.relative_to(Path.cwd()))]
    return testlist_list


def autocompletion_testname_in_testlist(ctx: typer.Context):
    testname_list = []
    testlist = ctx.params["testlist"]
    if testlist:
        testlist_path = Path.cwd() / testlist
    else:
        print("Missing testlist")
        return testname_list
    if not testlist_path.exists():
        print(f"Missing {testlist_path}")
        return testname_list
    with testlist_path.open("r") as f:
        data = yaml.safe_load(f)
    for v in data["testlist"]:
        testname_list += [v["test"]]
    return testname_list


def autocompletion_param_config(ctx: typer.Context):
    param_list = []
    target = ctx.params["target"]
    target_cfg = Path.cwd() / "core" / "include" / f"{target}_config_pkg.sv"
    if not (target and target_cfg.exists()):
        print(f"Missing core/include/{target}_config_pkg.sv")
        return param_list
    pattern = re.compile(r"^\s*(\w*)\s*:.*$")
    with (target_cfg).open("r") as f:
        for line in f:
            match = pattern.search(line)
            if match:
                param_list += [match.group(1).strip()]
    return param_list
