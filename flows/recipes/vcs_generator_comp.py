# Copyright 2026 Thales France
#
# Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
# You may obtain a copy of the License at https://solderpad.org/licenses/
#
# Original Author: Théo GIOVINAZZI

from pathlib import Path
import shutil
import typer
from flows.utils.manifest import write_manifest
from flows.utils.recipe_report import RecipeReport
from flows.utils.run_cmd import run_cmd
from flows.utils.autocompletion import autocompletion_target
from flows.utils.target_config import read_config_or_exit_isa

app = typer.Typer()


# corev-dv core settings (verif/env/corev-dv/target/<setting>/
# riscv_core_setting.sv): the ISA groups, privilege modes and CSRs the
# generator may use. derive_core_setting() picks one from the march of the
# target; --core-setting overrides it.
COREV_DV_TARGET_DIR = Path("verif") / "env" / "corev-dv" / "target"


def derive_core_setting(march):
    """
    Name of the corev-dv core setting matching `march`, or None.

    The settings are not generated from the target: the closest one that
    generates nothing the target lacks is chosen (rv32imcb: I, M, C and
    Zba/Zbb/Zbc/Zbs, no A; rv32imac: I, M, A, C; rv64gc).
    """
    march = march.lower()
    if march.startswith("rv64"):
        return "rv64gc"
    if not march.startswith("rv32"):
        return None
    base, *exts = march[4:].split("_")
    if not {"i", "m", "c"} <= set(base) and not base.startswith("g"):
        return None
    if {"zba", "zbb", "zbc", "zbs"} <= set(exts):
        return "rv32imcb"
    if "a" in base or base.startswith("g"):
        return "rv32imac"
    return None


# ==========================================================
# RECIPE
# ==========================================================


@app.command()
def vcs_generator_comp(
    target: str = typer.Option(
        ...,
        "--target",
        "-t",
        help="CVA6 user configuration",
        autocompletion=autocompletion_target,
    ),
    core_setting: str = typer.Option(
        None,
        "--core-setting",
        help="corev-dv core setting (directory of verif/env/corev-dv/target); "
        "derived from the march of the target if not provided",
    ),
    quiet: bool = typer.Option(
        False, "--quiet", "-q", help="Suppress output (errors only)"
    ),
):
    """
    VCS elaboration of the riscv-dv random instruction generator
    (with the corev-dv extensions)
    """
    report = RecipeReport(
        "vcs-generator-comp",
        title="VCS GENERATOR ELABORATION",
        context={"target": target, "core_setting": core_setting},
        quiet=quiet,
    )

    # Test tools in path
    vcs_path = shutil.which("vcs")
    if vcs_path is not None:
        report.success(f"VCS: {vcs_path}")
    else:
        report.error_exit("vcs: Not found", env=True)

    # Create files and folder paths
    repo_dir = Path.cwd()
    build_root = repo_dir / "build"
    elab_dir = build_root / target / "dv_generator"
    report.set_out_dir(elab_dir)

    # Core setting of the generator
    report.step("Core setting")
    march, _ = read_config_or_exit_isa(target, report)
    if core_setting is None:
        core_setting = derive_core_setting(march)
        if core_setting is None:
            report.error_exit(
                f"No corev-dv core setting matches march {march} of {target}: "
                f"pass --core-setting (one of "
                f"{sorted(d.name for d in (repo_dir / COREV_DV_TARGET_DIR).iterdir())})",
                env=True,
            )
    setting_dir = repo_dir / COREV_DV_TARGET_DIR / core_setting
    if not (setting_dir / "riscv_core_setting.sv").exists():
        report.error_exit(f"Missing {setting_dir / 'riscv_core_setting.sv'}", env=True)
    report.success(f"core setting {core_setting} (march {march})")

    # ==========================================================
    # CLEAN
    # ==========================================================
    report.step("Clean")
    try:
        if elab_dir.exists():
            shutil.rmtree(elab_dir)
            report.info(f"remove {elab_dir}")
    except Exception as e:
        report.error_exit(f"Clean error : {e}", env=True)

    elab_dir.mkdir(parents=True, exist_ok=True)
    report.info(f"create {elab_dir}")

    # ==========================================================
    # ENV VARIABLES
    # ==========================================================

    env_vars = {
        "RISCV_DV_ROOT": str(repo_dir / "verif" / "sim" / "dv"),
        "CVA6_DV_ROOT": str(repo_dir / "verif" / "env" / "corev-dv"),
    }

    # ==========================================================
    # CUSTOMIZE WITH OPTIONS
    # ==========================================================

    # FILELIST
    flist = []

    # The core setting comes first so that it wins over the default
    # riscv_core_setting.sv of riscv-dv; riscv-dv user_extension holds the
    # user_extension.svh included by riscv_instr_pkg (cva6-files.f adds the
    # corev-dv user_extension, which holds the headers of the tests).
    incdirs = [
        str(setting_dir),
        str(repo_dir / "verif" / "sim" / "dv" / "user_extension"),
    ]

    flist += [
        str(repo_dir / "verif" / "env" / "corev-dv" / "cva6-files.f"),
    ]
    # DEFINES
    defines = [
        "UVM",
        "HPDCACHE_ASSERT_OFF=1",
    ]

    # VCS OPTIONS
    options = [
        "-lca",
        "-sverilog",
        "-ntb_opts",
        "uvm-1.2",
        "-timescale=1ns/1ps",
        "-assert",
        "svaext",
        "-full64",
        "-q",
    ]

    # ==========================================================
    # BUILD VCS COMMAND
    # ==========================================================

    vcs_cmd = ["vcs"]
    vcs_cmd += options

    for d in defines:
        vcs_cmd += [f"+define+{d}"]

    for d in incdirs:
        vcs_cmd += [f"+incdir+{d}"]

    for f in flist:
        vcs_cmd += ["-f", str(f)]

    vcs_cmd += [
        "-top",
        "cva6_instr_gen_tb_top",
    ]

    # ==============================================================================
    # COPY CUSTOM INSTRUCTIONS
    # ==============================================================================
    report.step("Copy custom instructions")
    try:
        src_file = (
            repo_dir
            / "verif"
            / "env"
            / "corev-dv"
            / "custom"
            / "riscv_custom_instr_enum.sv"
        )
        dest_dir = repo_dir / "verif" / "sim" / "dv" / "src" / "isa" / "custom"

        dest_dir.mkdir(parents=True, exist_ok=True)

        # cp verif/env/corev-dv/custom/riscv_custom_instr_enum.sv ./verif/sim/dv/src/isa/custom/ :
        shutil.copy2(src_file, dest_dir)
        report.info(f"copy {src_file.name} to {dest_dir}")

    except Exception as e:
        report.error_exit(f"Copy error : {e}", env=True)

    # ==========================================================
    # LAUNCH VCS COMMAND
    # ==========================================================
    report.step("LAUNCH VCS")

    log_file = elab_dir / "compilation.log"

    run_cmd(
        cmd=vcs_cmd,
        report=report,
        cwd=elab_dir,
        env=env_vars,
        error_patterns=["^Error-"],
        warning_patterns=["^Warning-"],
        highlight_patterns=["^../simv up to date"],
        log_file=log_file,
        timeout=1800,
        check=False,
        capture_output=True,
    )

    simv = elab_dir / "simv"

    report.analyze_log(
        log_file,
        name="compilation.log analysis",
        error_patterns=["^Error-"],
        warning_patterns=["^Warning-"],
        env_patterns=[
            r"(license|licence).*(error|fail|unable|denied|expired)",
            r"unable to checkout",
            r"command not found",
        ],
        fail_on_error=False,
    )

    if not simv.exists():
        report.error_exit("SIMV not generated")

    report.success("SIMV generated")

    if not log_file.exists():
        report.warning("Compilation log missing")

    # ==========================================================
    # List
    # ==========================================================
    report.step("Generated files")
    gen_files = [simv, log_file]

    generated = []
    for genfile in gen_files:
        if genfile.exists():
            report.info(f"> {genfile}")
            generated.append(str(genfile.relative_to(repo_dir)))

    # ==========================================================
    # BUILD MANIFEST
    # ==========================================================
    write_manifest(
        elab_dir,
        "vcs-generator-comp",
        {
            "target": target,
            "core_setting": core_setting,
            "top": "cva6_instr_gen_tb_top",
            "defines": defines,
        },
        report=report,
    )

    # ==========================================================
    # BUILD REPORT
    # ==========================================================
    report.log("Generated files", generated)

    report.end("Completed")
