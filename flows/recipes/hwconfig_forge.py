# Copyright 2026 Thales France
#
# Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
# You may obtain a copy of the License at https://solderpad.org/licenses/
#
# Original Author: Mounsaf YOUSFI/Yannick Casamatta (yannick.casamatta@thalesgroup.com)

# Please refer to flows/README.md to add target

from pathlib import Path
import shutil
import re
from datetime import datetime
import typer
from flows.utils.autocompletion import (
    autocompletion_target,
    autocompletion_param_config,
)
from flows.utils.recipe_report import RecipeReport
from flows.utils.rtl_config import parse_rtl_cfg
from flows.utils.target_config import read_config_or_exit_rtl_cfg, target_dir

app = typer.Typer()


@app.command()
def hwconfig_forge(
    new_target_name: str = typer.Option(
        ...,
        "--target_forged",
        "-f",
        help="Name of forged CVA6 user configuration",
    ),
    target: str = typer.Option(
        ...,
        "--target_ref",
        "-t",
        help="Reference CVA6 user configuration",
        autocompletion=autocompletion_target,
    ),
    arg_replace: list[str] = typer.Option(
        ...,
        "--param",
        "-p",
        help="Individual parameters to override with value <parameter=newvalue>",
        autocompletion=autocompletion_param_config,
    ),
    quiet: bool = typer.Option(
        False, "--quiet", "-q", help="Suppress output (errors only)"
    ),
):
    """
    Hardware config modify/overwrite
    """
    report = RecipeReport(
        "hwconfig-forge",
        out_dir=Path.cwd() / "config" / "target" / new_target_name,
        title="HWCONFIG : Forging new config",
        context={
            "new_target_name": new_target_name,
            "target": target,
            "arg_replace": arg_replace,
        },
        quiet=quiet,
    )

    # ==========================================================
    # GENERATE MODIFICATIONS DICTIONARY
    # ==========================================================

    try:
        arg_replace_dict = dict(item.split("=") for item in arg_replace)
    except Exception as e:
        report.error_exit(
            f'\033[1mThe list of arguments to overwrite is incorrect, please use ./cook.py hwconfig-forge TARGET "PARAMETER=VALUE" "PARAMETER=VALUE"...\033[0m{e}',
        )

    # ==========================================================
    # FETCH TEMPLATE (ORIGINAL TARGET CONFIG PKG)
    # ==========================================================

    report.step("Target config package fetch")
    repo_dir = Path.cwd()
    config_pkg = target_dir(target, repo_dir) / "rtl_cfg_pkg.sv"
    forged_target_dir = target_dir(new_target_name, repo_dir)
    forged_config_pkg = forged_target_dir / "rtl_cfg_pkg.sv"
    # A target is a directory of config/target: the package, and the files
    # that must follow it, copied verbatim since the forge only rewrites
    # parameters of the package.
    companion_files = [
        "link.ld",
        "spike.yaml",
        "isa.yml",
        "testbench_cfg.yml",
        "Flist.cva6",
        "Flist.cva6_gate",
        "Flist.cva6_synth",
    ]
    if not config_pkg.exists():
        report.error_exit(f"{config_pkg} does not exist", env=True)
    report.info(f"{config_pkg} found")

    # The parameters of the reference target, to check the names to replace
    # against: a name absent from it matches no line of the package, and
    # would forge a configuration identical to the reference.
    reference = read_config_or_exit_rtl_cfg(target, report, repo_dir)
    unknown = [p for p in arg_replace_dict if p not in reference]
    if unknown:
        report.error_exit(
            f"Unknown parameter(s) for target '{target}': {', '.join(unknown)}\n"
            f"  The configuration package declares "
            f"{len(reference)} parameters, see {config_pkg}.",
            env=True,
        )
    config_pkg = config_pkg.open()

    report.step("Target config package forge")

    # ==========================================================
    # FORGE MODIFIED CONFIG PKG
    # ==========================================================

    forged_config_content = []

    param_table = {}
    titles_l = ["Parameter", "Old value", "New value"]
    style_l = ["cyan", "red", "green"]
    compare_forge_str = "// Generated using cook.py hwconfig-forge recipe"
    cTime = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    forge_str = f"{compare_forge_str} at {cTime}"
    forged_config_content = []
    config_pkg_1st_line = str(config_pkg.readline()).strip()
    forged_config_content.append(forge_str)
    if compare_forge_str not in config_pkg_1st_line:
        forged_config_content.append(config_pkg_1st_line)
    for line in config_pkg.read().splitlines():
        if not line or line.startswith("//"):
            forged_config_content.append(line)
            continue

        for rkey, rval in arg_replace_dict.items():
            if rkey in line:
                if re.search(rf"\({rkey}\)", line):
                    continue
                if re.search(rf"\b{rkey}\b", line):
                    val_l = []
                    val_l += [line.strip().strip(",")]  # old value
                    if ": " in line:
                        if re.search(r"\(.+?\)", line):
                            line = re.sub(r"\(.+?\)", f"({rval})", line)
                        else:
                            line = re.sub(r":.*", f": {rval},", line)
                    else:
                        line = re.sub(r"=.*", f"= {rval};", line)
                    val_l += [line.strip().strip(",")]  # new value

                    param_table[rkey] = val_l
                else:
                    continue

        forged_config_content.append(line)

    report.styled_table(
        params=param_table,
        title="Updated config values",
        column_name=titles_l,
        style=style_l,
    )

    # Record updated values in the report (already printed by styled_table)
    updated = report.metric("Updated config values")
    for param, (old_value, new_value) in param_table.items():
        updated.add_row(parameter=param, old=old_value, new=new_value)

    report.step(f"New target '{new_target_name}' generation")

    # The forged target gets its own directory of config/target/, so it can
    # be passed to `-t` like any other one.
    forged_target_dir.mkdir(parents=True, exist_ok=True)
    with forged_config_pkg.open("w") as f:
        for line in forged_config_content:
            f.write(f"{line}\n")
        report.info(f"create {forged_config_pkg}")

    # Re-read what was written: the package is rewritten line by line, so a
    # replacement may produce a value the parser cannot resolve, which the
    # first recipe using the forged target would be the one to hit.
    try:
        forged = parse_rtl_cfg(forged_config_pkg)
    except OSError as e:
        report.error_exit(f"Could not read back {forged_config_pkg}: {e}")
    for param in arg_replace_dict:
        if param not in forged:
            report.error(f"{param} disappeared from the forged configuration")
    report.success(f"{len(forged)} parameter(s) in the forged configuration")

    gen_files = [forged_config_pkg]
    for name in companion_files:
        src = target_dir(target, repo_dir) / name
        dst = forged_target_dir / name
        if not src.exists():
            continue
        if not dst.exists():
            shutil.copy(src, dst)
            report.info(f"Copy {src} -> {dst}")
        gen_files.append(dst)

    # ==========================================================
    # List
    # ==========================================================

    report.step("Generated files")
    for genfile in gen_files:
        if genfile.exists():
            report.info(f"> {genfile}")
        else:
            report.error(f"> Missing: {genfile}")

    if not report.failed:
        report.success(f"New target '{new_target_name}' forged")

    report.end("Completed")
