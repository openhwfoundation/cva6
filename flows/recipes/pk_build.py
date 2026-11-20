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
Build the RISC-V proxy kernel (riscv-pk) for a target.

pk runs in M-mode, loads a user program in U-mode and serves its system
calls through HTIF. It is compiled for the march/mabi of the target, from
the sources cloned by `./cook.py git-dependencies --repo riscv-pk`.

The recipe also builds the DPI library of the SimDTM the simulators load
under pk (corev_apu/tb/dpi/pk_dtm.cc), against the Spike fesvr library.
"""

import os
from pathlib import Path
import shutil

import typer

from flows.utils.autocompletion import ToolchainOption, autocompletion_target
from flows.utils.config_loader import load_compiler_config
from flows.utils.manifest import require_prerequisite, write_manifest
from flows.utils.recipe_report import RecipeReport
from flows.utils.run_cmd import run_cmd
from flows.utils.target_config import (
    read_config_or_exit_isa,
    read_config_or_exit_rtl_cfg,
)

app = typer.Typer()

PK_SOURCES = Path("tools") / "riscv-pk"
DTM_SOURCE = Path("corev_apu") / "tb" / "dpi" / "pk_dtm.cc"


def pk_build_dir(target, repo_dir=None):
    "Output directory of pk-build for `target`"
    repo_dir = Path(repo_dir) if repo_dir else Path.cwd()
    return repo_dir / "build" / target / "pk"


# ==========================================================
# RECIPE
# ==========================================================


@app.command()
def pk_build(
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
        help="GCC toolchain defined in $CONFIG_DIR/compiler.yml",
    ),
    jobs: int = typer.Option(8, "--jobs", "-j", help="Parallel make jobs"),
    quiet: bool = typer.Option(
        False, "--quiet", "-q", help="Suppress output (errors only)"
    ),
):
    """
    Build the RISC-V proxy kernel (pk) for a target.
    """
    report = RecipeReport(
        "pk-build",
        title="Proxy kernel build",
        context={"target": target, "toolchain": toolchain, "jobs": jobs},
        quiet=quiet,
    )

    repo_dir = Path.cwd()
    out_dir = pk_build_dir(target, repo_dir)
    report.set_out_dir(out_dir)
    sources = repo_dir / PK_SOURCES

    # ==========================================================
    # CHECK PREREQUISITES
    # ==========================================================
    report.step("Check prerequisites")

    require_prerequisite(
        sources / "configure",
        "riscv-pk sources",
        "./cook.py git-dependencies --repo riscv-pk",
        report=report,
    )

    compiler_data = load_compiler_config()[toolchain.value]
    if compiler_data["CLANG"] is not None or not compiler_data["GCC"]:
        report.error_exit(
            f"pk needs a GCC toolchain, {toolchain.value} is not one", env=True
        )

    # pk drops the program to U-mode
    rtl_cfg = read_config_or_exit_rtl_cfg(target, report)
    if not rtl_cfg.get("RVU"):
        report.error_exit(f"{target} has no U-mode (RVU): pk cannot run on it")

    march, mabi = read_config_or_exit_isa(target, report)
    report.success(f"march: {march}")
    report.success(f"mabi: {mabi}")

    tools_path = compiler_data["TOOLS_PATH"]
    host = compiler_data["TARGET_TOOLCHAIN"]
    nm = f"{tools_path}/bin/{compiler_data['NM']}"
    env = dict(os.environ)
    env["PATH"] = f"{tools_path}/bin:{env.get('PATH', '')}"

    # ==========================================================
    # CLEAN
    # ==========================================================
    report.step("Clean")
    try:
        if out_dir.exists():
            shutil.rmtree(out_dir)
            report.info(f"remove {out_dir}")
    except Exception as e:
        report.error_exit(f"Clean error : {e}", env=True)

    work_dir = out_dir / "work"
    install_dir = out_dir / "install"
    work_dir.mkdir(parents=True, exist_ok=True)
    report.info(f"create {out_dir}")

    # ==========================================================
    # CONFIGURE, BUILD, INSTALL
    # ==========================================================
    for step, cmd, log_name, timeout in (
        (
            "Configure",
            [
                str(sources / "configure"),
                f"--prefix={install_dir}",
                f"--host={host}",
                f"--with-arch={march}",
                f"--with-abi={mabi}",
            ],
            "configure.log",
            300,
        ),
        ("Build", ["make", f"-j{jobs}"], "make.log", 900),
        ("Install", ["make", "install"], "install.log", 300),
    ):
        report.step(step)
        failed_before = report.failed
        run_cmd(
            cmd=cmd,
            report=report,
            cwd=work_dir,
            env=env,
            error_patterns=[r"^configure: error", r"\berror:", r"Error \d+"],
            warning_patterns=None,
            highlight_patterns=None,
            log_file=out_dir / log_name,
            timeout=timeout,
        )
        if report.failed and not failed_before:
            report.error_exit(f"{step} failed, see {out_dir / log_name}")

    pk = install_dir / host / "bin" / "pk"
    if not pk.exists():
        report.error_exit(f"pk not installed: {pk}")
    report.success(f"pk: {pk}")

    # ==========================================================
    # PRELOADED SIMDTM
    # ==========================================================
    report.step("Preloaded SimDTM library")
    spike_dir = repo_dir / "tools" / "spike"
    require_prerequisite(
        spike_dir / "lib" / "libfesvr.so",
        "Spike fesvr library",
        "bash verif/regress/install-spike.sh",
        report=report,
    )
    dtm_lib = out_dir / "libpk_dtm.so"
    failed_before = report.failed
    run_cmd(
        cmd=[
            "g++",
            "-std=c++17",
            "-O2",
            "-fPIC",
            "-shared",
            f"-I{spike_dir / 'include'}",
            str(repo_dir / DTM_SOURCE),
            f"-L{spike_dir / 'lib'}",
            f"-Wl,-rpath,{spike_dir / 'lib'}",
            "-lfesvr",
            "-o",
            str(dtm_lib),
        ],
        report=report,
        cwd=out_dir,
        env=None,
        error_patterns=[r"\berror:"],
        warning_patterns=None,
        highlight_patterns=None,
        log_file=out_dir / "dtm.log",
        timeout=300,
    )
    if (report.failed and not failed_before) or not dtm_lib.exists():
        report.error_exit(f"SimDTM library not built, see {out_dir / 'dtm.log'}")
    report.success(f"SimDTM library: {dtm_lib}")

    # ==========================================================
    # SYMBOLS
    # ==========================================================
    # tohost of pk, not of the user program, ends the simulation
    report.step("Symbols extraction")
    nm_output = run_cmd(
        cmd=[nm, str(pk)],
        report=report,
        cwd=None,
        env=None,
        error_patterns=None,
        warning_patterns=None,
        highlight_patterns=None,
        log_file=None,
        timeout=60,
        check=False,
        capture_output=True,
    )
    symbols = {}
    for line in (nm_output or "").splitlines():
        parts = line.split()
        if len(parts) >= 3 and parts[2] in ("tohost", "fromhost"):
            symbols[parts[2]] = parts[0]
    if "tohost" not in symbols:
        report.error_exit(f"No tohost symbol in {pk}")
    report.success(f"tohost: 0x{symbols['tohost']}")

    # ==========================================================
    # BUILD MANIFEST
    # ==========================================================
    write_manifest(
        out_dir,
        "pk-build",
        {
            "target": target,
            "toolchain": toolchain,
            "march": march,
            "mabi": mabi,
            "pk": str(pk),
            "dtm_lib": str(dtm_lib),
            "symbols": symbols,
        },
        report=report,
    )

    report.log(
        "Generated files",
        [str(pk.relative_to(repo_dir)), str(dtm_lib.relative_to(repo_dir))],
    )
    report.end("Completed")
