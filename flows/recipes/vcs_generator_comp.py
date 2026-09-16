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

app = typer.Typer()


# ==========================================================
# RECIPE
# ==========================================================


@app.command()
def vcs_generator_comp(
    quiet: bool = typer.Option(
        False, "--quiet", "-q", help="Suppress output (errors only)"
    )
):
    """
    VCS UVM compilation / elaboration flow
    """
    report = RecipeReport(
        "vcs-generator-comp", title="VCS DESIGN ELABORATION", context={}, quiet=quiet
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
    elab_dir = build_root / "dv"
    report.set_out_dir(elab_dir)

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

    incdirs = [
        str(repo_dir / "verif" / "env" / "corev-dv" / "target" / "cv32a65x"),
        str(repo_dir / "verif" / " sim" / "dv" / "user_extension"),
    ]

    flist += [
        str(repo_dir / "verif" / "sim" / "dv" / "cva6-files.f"),
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

    for f in flist:
        vcs_cmd += ["-f", str(f)]

    for d in incdirs:
        vcs_cmd += [f"+incdir+{d}"]

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
