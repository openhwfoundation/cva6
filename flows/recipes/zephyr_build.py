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
Build a Zephyr application for a target.

Zephyr supports the CVA6 SoC of the Genesys 2 board in two configurations,
whose memory map is the one of the TestHarness: DRAM at 0x8000_0000, ns16550
UART at 0x1000_0000, CLINT and PLIC. The board follows from the target:
cv32a6_genesys_2 (rv32ima) for a 32-bit target, cv64a6_genesys_2
(rv64imafdc) for a 64-bit one with F and D.

The build output is laid out as the one of sw-compile, so that the run
recipes read the ELF and its tohost from the same manifest.
"""

import os
from pathlib import Path
import shutil
import sys

import typer

from flows.utils.autocompletion import ToolchainOption, autocompletion_target
from flows.utils.config_loader import load_compiler_config
from flows.utils.manifest import require_prerequisite, write_manifest
from flows.utils.recipe_report import RecipeReport
from flows.utils.run_cmd import run_cmd
from flows.utils.target_config import read_config_or_exit_rtl_cfg

app = typer.Typer()

ZEPHYR_BASE = Path("tools") / "zephyr"
# Zephyr runs at the reset vector of the TestHarness, in M-mode: it needs
# the A extension, and the board the ISA of its SoC.
BOARD_ISA = {
    "cv32a6_genesys_2": "rv32ima",
    "cv64a6_genesys_2": "rv64imafdc",
}


def zephyr_board(rtl_cfg):
    "Zephyr board of a target, or None when no board fits its ISA"
    if not rtl_cfg.get("RVA"):
        return None
    if rtl_cfg.get("XLEN") == 32:
        return "cv32a6_genesys_2"
    if rtl_cfg.get("XLEN") == 64 and rtl_cfg.get("RVF") and rtl_cfg.get("RVD"):
        return "cv64a6_genesys_2"
    return None


# ==========================================================
# RECIPE
# ==========================================================


@app.command()
def zephyr_build(
    target: str = typer.Option(
        ...,
        "--target",
        "-t",
        help="CVA6 user configuration",
        autocompletion=autocompletion_target,
    ),
    toolchain: ToolchainOption = typer.Option(
        ...,
        "--toolchain",
        "-c",
        help="GCC toolchain defined in $CONFIG_DIR/compiler.yml, with a "
        "libgcc built for -mcmodel=medany (the Zephyr SDK one)",
    ),
    app_dir: str = typer.Option(
        ..., "--app", help="Zephyr application directory (with its CMakeLists.txt)"
    ),
    test_name: str = typer.Option(
        ..., "--out", help="Test name (used in rest of flow)"
    ),
    quiet: bool = typer.Option(
        False, "--quiet", "-q", help="Suppress output (errors only)"
    ),
):
    """
    Build a Zephyr application for a target.
    """
    report = RecipeReport(
        "zephyr-build",
        title="Zephyr build",
        context={
            "target": target,
            "toolchain": toolchain,
            "app_dir": app_dir,
            "test_name": test_name,
        },
        quiet=quiet,
    )

    repo_dir = Path.cwd()
    compile_dir = repo_dir / "build" / target / "compile" / test_name
    report.set_out_dir(compile_dir)
    zephyr_base = repo_dir / ZEPHYR_BASE

    # ==========================================================
    # CHECK PREREQUISITES
    # ==========================================================
    report.step("Check prerequisites")

    require_prerequisite(
        zephyr_base / "VERSION",
        "Zephyr sources",
        "./cook.py git-dependencies --repo zephyr",
        report=report,
    )
    require_prerequisite(
        Path(app_dir) / "CMakeLists.txt",
        "Zephyr application",
        "an application directory with its CMakeLists.txt",
        report=report,
    )

    # The build scripts of Zephyr run with the interpreter of cook.py, whose
    # requirements cover the ones they import
    python = sys.executable
    for tool in ("cmake", "ninja", "dtc"):
        if shutil.which(tool) is None:
            report.error_exit(f"{tool}: Not found", env=True)

    compiler_data = load_compiler_config()[toolchain.value]
    if compiler_data["CLANG"] is not None or not compiler_data["GCC"]:
        report.error_exit(
            f"The Zephyr build needs a GCC toolchain, {toolchain.value} is not one",
            env=True,
        )
    tools_path = compiler_data["TOOLS_PATH"]
    prefix = compiler_data["GCC"][: -len("gcc")]
    nm = f"{tools_path}/bin/{compiler_data['NM']}"
    objdump = f"{tools_path}/bin/{compiler_data['OBJDUMP']}"

    board = zephyr_board(read_config_or_exit_rtl_cfg(target, report))
    if board is None:
        report.error_exit(
            f"No Zephyr board fits {target}: a 32-bit target with A "
            f"(cv32a6_genesys_2), or a 64-bit one with A, F and D "
            f"(cv64a6_genesys_2)"
        )
    report.success(f"Zephyr board: {board}")

    # ==========================================================
    # CLEAN
    # ==========================================================
    report.step("Clean")
    try:
        if compile_dir.exists():
            shutil.rmtree(compile_dir)
            report.info(f"remove {compile_dir}")
    except Exception as e:
        report.error_exit(f"Clean error : {e}", env=True)
    work_dir = compile_dir / "zephyr_build"
    work_dir.mkdir(parents=True, exist_ok=True)
    report.info(f"create {compile_dir}")

    # The applications use no Zephyr module: an empty one stands for them,
    # so that the build needs no west workspace.
    no_module = compile_dir / "no_module"
    (no_module / "zephyr").mkdir(parents=True, exist_ok=True)
    (no_module / "zephyr" / "module.yml").write_text(
        "name: no_module\nbuild:\n  cmake-ext: false\n  kconfig-ext: false\n",
        encoding="utf-8",
    )

    env = dict(os.environ)
    env["ZEPHYR_BASE"] = str(zephyr_base)
    env["ZEPHYR_TOOLCHAIN_VARIANT"] = "cross-compile"
    env["CROSS_COMPILE"] = f"{tools_path}/bin/{prefix}"

    # ==========================================================
    # CONFIGURE AND BUILD
    # ==========================================================
    for step, cmd, log_name in (
        (
            "Configure",
            [
                "cmake",
                "-GNinja",
                "-S",
                str(Path(app_dir).resolve()),
                "-B",
                str(work_dir),
                f"-DBOARD={board}",
                f"-DPython3_EXECUTABLE={python}",
                f"-DUSER_CACHE_DIR={compile_dir / 'zephyr_cache'}",
                f"-DZEPHYR_MODULES={no_module}",
            ],
            "configure.log",
        ),
        ("Compilation", ["ninja", "-C", str(work_dir)], "compile.log"),
    ):
        report.step(step)
        failed_before = report.failed
        run_cmd(
            cmd=cmd,
            report=report,
            cwd=compile_dir,
            env=env,
            error_patterns=[r"CMake Error", r"\berror:"],
            warning_patterns=[r"\bwarning:"],
            highlight_patterns=None,
            log_file=compile_dir / log_name,
            timeout=900,
        )
        if report.failed and not failed_before:
            report.error_exit(f"{step} failed, see {compile_dir / log_name}")

    built = work_dir / "zephyr" / "zephyr.elf"
    elf = compile_dir / f"{test_name}.elf"
    if not built.exists():
        report.error_exit(f"Zephyr ELF not built: {built}")
    shutil.copyfile(built, elf)
    report.success(f"ELF: {elf}")

    run_cmd(
        cmd=[objdump, "-D", str(elf)],
        report=report,
        cwd=None,
        env=None,
        error_patterns=None,
        warning_patterns=None,
        highlight_patterns=None,
        log_file=compile_dir / f"{test_name}.dump",
        timeout=90,
        check=False,
        capture_output=False,
    )

    # ==========================================================
    # SYMBOLS
    # ==========================================================
    # The application ends the run by writing tohost
    report.step("Symbols extraction")
    nm_output = run_cmd(
        cmd=[nm, str(elf)],
        report=report,
        cwd=None,
        env=None,
        error_patterns=None,
        warning_patterns=None,
        highlight_patterns=None,
        log_file=None,
        timeout=90,
        check=False,
        capture_output=True,
    )
    symbols = {}
    for line in (nm_output or "").splitlines():
        parts = line.split()
        if len(parts) >= 3 and parts[2] == "tohost":
            symbols["tohost"] = parts[0]
    if "tohost" not in symbols:
        report.error_exit(
            f"No tohost symbol in {elf}: the application must write it to end "
            f"the simulation"
        )
    report.success(f"tohost: 0x{symbols['tohost']}")

    # ==========================================================
    # BUILD MANIFEST
    # ==========================================================
    # The keys of sw-compile, read by the run recipes
    write_manifest(
        compile_dir,
        "zephyr-build",
        {
            "target": target,
            "toolchain": toolchain,
            "test_name": test_name,
            "app_dir": app_dir,
            "zephyr_board": board,
            "march": BOARD_ISA[board],
            "symbols": symbols,
        },
        report=report,
    )

    report.log("Generated files", [str(elf.relative_to(repo_dir))])
    report.end("Completed")
