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
import shutil
import typer
from flows.utils.manifest import (
    read_manifest,
    require_prerequisite,
    require_manifest_option,
)
from flows.utils.recipe_report import RecipeReport
from flows.utils.run_cmd import run_cmd
from flows.utils.autocompletion import (
    CompMode,
    TraceMode,
    autocompletion_target,
    autocompletion_testname_compiled,
)

app = typer.Typer()


# ==========================================================
# RECIPE
# ==========================================================


@app.command()
def vcs_uvm_gui(
    target: str = typer.Option(
        ...,
        "--target",
        "-t",
        help="CVA6 user configuration",
        autocompletion=autocompletion_target,
    ),
    test_name: str = typer.Option(
        None,
        "--testname",
        "-n",
        help="Test name (compiled from list or not)",
        autocompletion=autocompletion_testname_compiled,
    ),
    comp_mode: CompMode = typer.Option(CompMode.rtl, help="Hardware compilation mode"),
    session: str = typer.Option(
        None,
        "--session",
        "-s",
        help="Verdi session file(saved by user)",
    ),
    quiet: bool = typer.Option(
        False, "--quiet", "-q", help="Suppress output (errors only)"
    ),
):
    """
    Verdi open simulation trace (fsdb only)
    """
    report = RecipeReport(
        "vcs-uvm-gui",
        title="VCS Simulation open trace",
        context={
            "target": target,
            "test_name": test_name,
            "comp_mode": comp_mode,
            "session": session,
        },
        quiet=quiet,
    )

    # Mode dir
    if comp_mode == CompMode.rtl:
        inout_dir = "sim_rtl"
    elif comp_mode == CompMode.coverage:
        inout_dir = "sim_cov"
    elif comp_mode == CompMode.gate_wc_timing:
        inout_dir = "sim_gate_wc_timing"
    elif comp_mode == CompMode.gate_wc_power:
        inout_dir = "sim_gate_wc_power"
    else:
        report.error_exit("Unknown comp_mode", env=True)

    # Test tools in path
    verdi_path = shutil.which("verdi")
    if verdi_path is not None:
        report.success(f"verdi: {verdi_path}")
    else:
        report.error_exit("VERDI: Not found", env=True)

    # Create files and folder paths
    repo_dir = Path.cwd()
    build_root = repo_dir / "build" / target
    elab_dir = build_root / "elab" / inout_dir
    simulation_dir = build_root / "simulation" / inout_dir / test_name
    report.set_out_dir(simulation_dir)

    # ==========================================================
    # CHECK PREREQUISITES
    # ==========================================================
    report.step("Check prerequisites")

    require_prerequisite(
        simulation_dir / "trace.fsdb",
        f"FSDB trace for test '{test_name}' (comp mode '{comp_mode.value}')",
        f"./cook.py vcs-uvm-run -t {target} -n {test_name} --comp-mode {comp_mode.value} --trace-mode gui (design must be elaborated with --trace-mode gui too)",
        report=report,
    )

    sim_manifest = read_manifest(simulation_dir, report)
    require_manifest_option(
        sim_manifest,
        "trace_mode",
        [TraceMode.gui.value, TraceMode.fast.value],
        "Verdi needs an FSDB trace generated with --trace-mode gui or fast",
        f"./cook.py vcs-uvm-run -t {target} -n {test_name} --comp-mode {comp_mode.value} --trace-mode gui",
        report=report,
        manifest_dir=simulation_dir,
    )

    report.success("Prerequisites OK")

    # ==========================================================
    # BUILD VERDI COMMAND
    # ==========================================================
    report.step("Build verdi command")

    verdi_cmd = ["verdi"]
    verdi_cmd += ["-ssf", f"{simulation_dir / 'trace.fsdb'}"]
    verdi_cmd += ["-dbdir", f"{elab_dir / 'simv.daidir'}"]

    # ==========================================================
    # ADDITIONAL VERDI COMMAND ARGS: RESTORE SESSION
    # ==========================================================
    if session is not None:
        session_file = Path(session)
        if session_file.exists():
            report.step("Saved session found, session restoring configuration")
            verdiRestoreTCL = Path("flows/utils/verdiRestore.tcl")
            verdi_cmd += ["-play", f"{verdiRestoreTCL}"]
            with verdiRestoreTCL.open("w", encoding="utf-8") as f:
                # .as_posix(): backslashes are escape characters in TCL
                f.write(f"set session_file {session_file.as_posix()}\n")
                f.write("debRestoreSession $session_file\n")
        else:
            report.step("Session file is none, skipping session restoring")

    # ==========================================================
    # LAUNCH VERDI
    # ==========================================================
    report.step("Launch Verdi")

    log_file = simulation_dir / "verdi.log"

    run_cmd(
        cmd=verdi_cmd,
        report=report,
        cwd=None,
        env=None,
        error_patterns=None,
        warning_patterns=None,
        highlight_patterns=None,
        log_file=log_file,
        timeout=3600,
        check=False,
        capture_output=False,
    )

    # ==========================================================
    # BUILD REPORT
    # ==========================================================

    report.end("Completed")
