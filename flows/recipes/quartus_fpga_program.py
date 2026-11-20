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
Load a bitstream onto an Intel/Altera FPGA board (Quartus Programmer).

The Intel counterpart of `vivado-fpga-program`, and again a recipe of its
own: nothing of the Xilinx side applies. Quartus programs through
`quartus_pgm` and a JTAG cable named by the programmer, not through a
`hw_server` reached over TCP, so the board has to be on the machine
running the recipe (or its cable forwarded by `jtagd`, see the FPGA
section of flows/README.md).

The cable name is what the Quartus Programmer calls a "hardware setup",
e.g. `AGF FPGA Development Kit [1-3]`. It is discovered with
`jtagconfig --enum`, which this recipe runs when `--cable` is not given
so a first use does not require knowing it.
"""

import os
from pathlib import Path
import re
import shutil
import typer

from flows.utils.fpga_board import altera_board_params
from flows.utils.manifest import (
    read_manifest,
    require_manifest_option,
    require_prerequisite,
    write_manifest,
)
from flows.utils.recipe_report import RecipeReport
from flows.utils.run_cmd import run_cmd
from flows.utils.autocompletion import AlteraBoard, autocompletion_target

app = typer.Typer()

# `jtagconfig --enum` lists one cable per line, as `1) <name>`
CABLE_RE = re.compile(r"^\s*\d+\)\s*(.+?)\s*$", re.M)


def _detect_cable(report):
    """
    Return the first JTAG cable the programmer sees, or None.

    Only a convenience for a single board setup: with several cables
    connected the choice is the user's, through `--cable`.
    """
    out = run_cmd(
        cmd=["jtagconfig", "--enum"],
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
    cables = CABLE_RE.findall(out or "")
    # `jtagconfig` lists the devices of a cable on the following lines,
    # indented: only the numbered entries are cables.
    return cables[0] if cables else None


# ==========================================================
# RECIPE
# ==========================================================


@app.command()
def quartus_fpga_program(
    target: str = typer.Option(
        ...,
        "--target",
        "-t",
        help="CVA6 user configuration",
        autocompletion=autocompletion_target,
    ),
    board: AlteraBoard = typer.Option(AlteraBoard.agilex7, help="Altera FPGA board"),
    cable: str = typer.Option(
        None,
        "--cable",
        help="JTAG cable of the programmer (default: $JTAG_CABLE, else the "
        "first one jtagconfig sees)",
    ),
    device_index: int = typer.Option(
        1, "--device-index", help="Position of the FPGA in the JTAG chain"
    ),
    bitstream: Path = typer.Option(
        None,
        "--bitstream",
        help="Bitstream to load (default: the quartus-fpga-build output)",
    ),
    quiet: bool = typer.Option(
        False, "--quiet", "-q", help="Suppress output (errors only)"
    ),
):
    """
    Quartus FPGA board programming flow
    """
    report = RecipeReport(
        "quartus-fpga-program",
        title="QUARTUS FPGA PROGRAM",
        context={
            "target": target,
            "board": board,
            "cable": cable,
            "device_index": device_index,
            "bitstream": bitstream,
        },
        quiet=quiet,
    )

    repo_dir = Path.cwd()
    build_dir = repo_dir / "build" / target / "fpga_altera" / board.value
    out_dir = repo_dir / "build" / target / "fpga_altera_program" / board.value
    report.set_out_dir(out_dir)

    params = altera_board_params(board)

    # ==========================================================
    # CHECK PREREQUISITES
    # ==========================================================
    report.step("Check prerequisites")

    for tool in ("quartus_pgm", "jtagconfig"):
        path = shutil.which(tool)
        if path is None:
            report.error_exit(
                f"{tool}: Not found\n"
                f"  Programming an Altera board needs the Quartus Programmer "
                f"in PATH (it ships with Quartus, also standalone as "
                f"qprogrammer).",
                env=True,
            )
        report.success(f"{tool}: {path}")

    if bitstream is None:
        sof_files = sorted((build_dir / "output_files").glob("*.sof"))
        bitstream = sof_files[0] if sof_files else build_dir / "output_files"
        require_prerequisite(
            bitstream,
            f"bitstream of target '{target}' for board '{board.value}'",
            f"./cook.py quartus-fpga-build -t {target} --board {board.value}",
            report=report,
        )
        # The bitstream is board specific: programming a board with the
        # image of another one is refused rather than attempted.
        require_manifest_option(
            read_manifest(build_dir, report),
            "board",
            [board.value],
            f"programming board '{board.value}' needs a bitstream built for it",
            f"./cook.py quartus-fpga-build -t {target} --board {board.value}",
            report=report,
            manifest_dir=build_dir,
        )
    else:
        bitstream = Path(bitstream).resolve()
        require_prerequisite(
            bitstream,
            "bitstream given with --bitstream",
            f"./cook.py quartus-fpga-build -t {target} --board {board.value}",
            report=report,
        )
    report.info(f"bitstream: {bitstream}")

    cable = cable or os.environ.get("JTAG_CABLE")
    if not cable:
        report.info("No cable given, asking the programmer")
        cable = _detect_cable(report)
        if not cable:
            report.error_exit(
                "No JTAG cable found\n"
                "  Pass --cable or set $JTAG_CABLE to the hardware setup name "
                "of the board (e.g. 'AGF FPGA Development Kit [1-3]'), and "
                "check `jtagconfig --enum` sees it.",
                env=True,
            )
    report.add_context({"cable": cable, "device": params.device})
    report.success(f"cable: {cable}")

    # ==========================================================
    # CLEAN
    # ==========================================================
    report.step("Clean")
    try:
        if out_dir.exists():
            shutil.rmtree(out_dir)
            report.info(f"remove {out_dir}")
    except OSError as e:
        report.error_exit(f"Clean error : {e}", env=True)

    out_dir.mkdir(parents=True, exist_ok=True)
    report.info(f"create {out_dir}")

    # ==========================================================
    # PROGRAM THE BOARD
    # ==========================================================
    report.step("Program the board")

    log_file = out_dir / "program.log"

    run_cmd(
        cmd=[
            "quartus_pgm",
            "-c",
            cable,
            "-m",
            "jtag",
            "-o",
            f"P;{bitstream}@{device_index}",
        ],
        report=report,
        cwd=out_dir,
        env=None,
        error_patterns=["^Error|Error \\("],
        warning_patterns=["^Warning"],
        highlight_patterns=["^Info.*successful"],
        log_file=log_file,
        timeout=1800,
        check=False,
        capture_output=False,
    )

    # A programming failure is an environment problem (board off, cable
    # busy, wrong chain position), not a defect of the design.
    n_err, _ = report.analyze_log(
        log_file,
        name="program.log analysis",
        error_patterns=["^Error", "Error \\("],
        warning_patterns=["^Warning"],
        env_patterns=[
            r"(license|licence).*(error|fail|unable|denied|expired)",
            r"[Cc]an't access JTAG chain",
            r"No JTAG hardware available",
            r"command not found",
        ],
        fail_on_error=False,
    )

    if n_err:
        report.error_exit(
            f"Board programming failed: {n_err} error(s) in {log_file}", env=True
        )
    report.success(f"Board programmed: {params.device} on {cable}")
    report.set_label("PROGRAMMED")

    # ==========================================================
    # BUILD MANIFEST
    # ==========================================================
    write_manifest(
        out_dir,
        "quartus-fpga-program",
        {
            "target": target,
            "board": board,
            "cable": cable,
            "device_index": device_index,
            "device": params.device,
            "bitstream": str(bitstream),
        },
        report=report,
    )

    # ==========================================================
    # List
    # ==========================================================
    report.step("Generated files")
    generated = []
    if log_file.exists():
        report.info(f"> {log_file}")
        generated.append(str(log_file.relative_to(repo_dir)))

    # ==========================================================
    # BUILD REPORT
    # ==========================================================
    report.log("Generated files", generated)

    report.end("Completed")
