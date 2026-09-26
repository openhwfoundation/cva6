# Copyright 2026 Thales France
#
# Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
# You may obtain a copy of the License at https://solderpad.org/licenses/
#
# Original Author: Guillaume Chauvon

# Please refer to flows/README.md to add target

"""
Boot Linux on a programmed FPGA board and check it on the serial console.

The end to end test of the FPGA flow: the board has been programmed by
`vivado-fpga-program`, the Linux image is on its SD card, and this recipe
watches the console until the kernel identifies itself. The system image
is not built here; it comes from the CVA6 SDK (see the FPGA section of
the repository README for the SD card preparation).

Replaces `corev_apu/fpga/scripts/check_fpga_boot.sh` and `linux_boot.py`.
Three behaviours change, all of them defects of the originals: the boot
has a wall clock deadline instead of relying on the CI job timeout, a
missing bitstream is an error instead of a silent success (the shell
script exited 0 when the file was absent), and the verdict is taken on
the whole transcript rather than on its last line only.
"""

import os
from pathlib import Path
import shutil
import typer

from flows.utils.fpga_board import any_board_params, is_altera_board
from flows.utils.manifest import (
    read_manifest,
    require_manifest_option,
    require_prerequisite,
    write_manifest,
)
from flows.utils.recipe_report import RecipeReport
from flows.utils.uart_boot import (
    DEFAULT_EXPECT,
    JUART_TERMINAL,
    JuartConsole,
    SerialConsole,
    is_url,
    watch_boot,
)
from flows.utils.autocompletion import AnyBoard, autocompletion_target

app = typer.Typer()

# Wall clock budget of the boot. The board runs a full Linux from an SD
# card at a few dozen MHz: minutes, not seconds.
BOOT_TIMEOUT = 300


# ==========================================================
# RECIPE
# ==========================================================


@app.command()
def fpga_linux_boot(
    target: str = typer.Option(
        ...,
        "--target",
        "-t",
        help="CVA6 user configuration",
        autocompletion=autocompletion_target,
    ),
    board: AnyBoard = typer.Option(
        AnyBoard.genesys2, help="FPGA board, of either vendor"
    ),
    uart: str = typer.Option(
        None,
        "--uart",
        help="Serial console of the board: local device (/dev/ttyUSB1) or URL "
        "of a remote one (socket://bench-pc:4001). Default: $UART_SERIAL. "
        "Ignored on a board whose console is a JTAG UART",
    ),
    cable: str = typer.Option(
        None,
        "--cable",
        help="JTAG cable carrying the console, on a board whose console is a "
        "JTAG UART (default: $JTAG_CABLE, else the only one)",
    ),
    juart_instance: int = typer.Option(
        None,
        "--juart-instance",
        help="Instance of the JTAG UART on the cable (default: the only one)",
    ),
    baudrate: int = typer.Option(
        None,
        "--baudrate",
        help="Console baudrate (default: the baudrate of the board)",
    ),
    boot_timeout: int = typer.Option(
        BOOT_TIMEOUT, "--boot-timeout", help="Boot timeout in seconds"
    ),
    expect: str = typer.Option(
        DEFAULT_EXPECT, "--expect", help="Console line identifying a booted kernel"
    ),
    quiet: bool = typer.Option(
        False, "--quiet", "-q", help="Suppress output (errors only)"
    ),
):
    """
    Linux boot check on the FPGA board console
    """
    report = RecipeReport(
        "fpga-linux-boot",
        title="FPGA LINUX BOOT",
        context={
            "target": target,
            "board": board,
            "uart": uart,
            "cable": cable,
            "juart_instance": juart_instance,
            "baudrate": baudrate,
            "boot_timeout": boot_timeout,
            "expect": expect,
        },
        quiet=quiet,
    )

    repo_dir = Path.cwd()
    # Each vendor has its own programming recipe and so its own directory
    if is_altera_board(board):
        program_dir = repo_dir / "build" / target / "fpga_altera_program" / board.value
        program_recipe = "quartus-fpga-program"
    else:
        program_dir = repo_dir / "build" / target / "fpga_program" / board.value
        program_recipe = "vivado-fpga-program"
    out_dir = repo_dir / "build" / target / "fpga_boot" / board.value
    report.set_out_dir(out_dir)

    params = any_board_params(board)
    # How the console is reached is a property of the design, not a choice:
    # the Xilinx boards drive a serial port, the Altera ones a JTAG UART.
    console_kind = params.console_kind
    # The baudrate is a property of the board too: the bootloader is
    # compiled for it (see corev_apu/fpga/src/bootrom/Makefile), so the
    # console follows unless the caller knows better. A JTAG UART carries
    # no line settings, the link being the JTAG cable.
    baudrate = baudrate or params.uart_baudrate
    report.add_context({"console_kind": console_kind})

    # ==========================================================
    # CHECK PREREQUISITES
    # ==========================================================
    report.step("Check prerequisites")

    if console_kind == "juart":
        # The vendor terminal is the only way in: the design has no serial
        # pin, the console travelling over the JTAG cable.
        if not shutil.which(JUART_TERMINAL):
            report.error_exit(
                f"{JUART_TERMINAL}: Not found\n"
                f"  The console of board '{board.value}' is a JTAG UART, read "
                f"by the terminal shipped with Quartus (in its quartus/bin, "
                f"also in the standalone programmer).",
                env=True,
            )
        cable = cable or os.environ.get("JTAG_CABLE")
        report.add_context({"cable": cable, "juart_instance": juart_instance})
        report.info(
            "JTAG UART console"
            + (f" on cable {cable}" if cable else " on the only cable")
        )
    else:
        uart = uart or os.environ.get("UART_SERIAL")
        if not uart:
            report.error_exit(
                "No serial console\n"
                "  Pass --uart or set $UART_SERIAL to the console of the board:\n"
                "    a local device, e.g. /dev/ttyUSB1\n"
                "    or a remote one, e.g. socket://bench-pc:4001 when the board\n"
                "    is wired to another machine exposing its console over TCP.",
                env=True,
            )
        report.add_context({"uart": uart, "baudrate": baudrate})

    # The board must hold the design under test: without this the recipe
    # would watch the console of whatever was programmed last.
    require_prerequisite(
        program_dir / "cook_report.yml",
        f"board '{board.value}' programmed with target '{target}'",
        f"./cook.py {program_recipe} -t {target} --board {board.value}",
        report=report,
    )
    require_manifest_option(
        read_manifest(program_dir, report),
        "board",
        [board.value],
        f"booting board '{board.value}' needs that board to be the programmed one",
        f"./cook.py {program_recipe} -t {target} --board {board.value}",
        report=report,
        manifest_dir=program_dir,
    )

    # A local serial console must exist as a device node; a remote one is a
    # URL with no filesystem entry, and its reachability is only known when
    # the connection is attempted below. A JTAG UART has neither.
    if console_kind == "serial":
        if is_url(uart):
            report.info(f"Remote console: {uart}")
        elif not Path(uart).exists():
            report.error_exit(
                f"Serial console not found: {uart}\n"
                f"  Check the board is connected and the device name is right.\n"
                f"  A board wired to another machine is reached by URL instead, "
                f"e.g. --uart socket://bench-pc:4001",
                env=True,
            )

    report.success("Prerequisites OK")

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
    # WATCH THE CONSOLE
    # ==========================================================
    report.step("Watch the console")

    log_file = out_dir / "boot.log"

    if console_kind == "juart":
        source = f"the JTAG UART of {cable or 'the only cable'}"
    else:
        source = f"{uart} at {baudrate} bauds"
    report.info(f"Reading {source}, up to {boot_timeout}s")

    try:
        if console_kind == "juart":
            console = JuartConsole(cable=cable, instance=juart_instance)
        else:
            console = SerialConsole(uart, baudrate)
        result = watch_boot(
            console,
            boot_timeout,
            expect=expect,
            on_line=None if quiet else report.info,
        )
    except ImportError as e:
        report.error_exit(
            f"pyserial is not installed ({e}, see flows/requirements.txt)", env=True
        )
    except OSError as e:
        # A refused TCP connection arrives here too: the bridge exposing a
        # remote console is a separate process, and a missing one has to be
        # named rather than reported as a bare I/O error. Same for the
        # vendor terminal of a JTAG UART.
        if console_kind == "juart":
            hint = (
                "\n  Check the board is powered and its cable free: the "
                "terminal shares the JTAG chain with the programmer."
            )
        elif is_url(uart):
            hint = (
                "\n  Check the serial bridge is running on the machine holding "
                "the board, and that its port is reachable."
            )
        else:
            hint = ""
        report.error_exit(f"Cannot read the console ({source}): {e}{hint}", env=True)

    # The transcript is the evidence of the run, kept whatever the
    # verdict: a boot that failed is precisely the one worth reading.
    try:
        log_file.write_text("\n".join(result.lines) + "\n", encoding="utf-8")
        report.info(f"console transcript written: {log_file}")
    except OSError as e:
        report.warning(f"Could not write {log_file}: {e}")

    # ==========================================================
    # VERDICT
    # ==========================================================
    report.step("Boot verdict")

    boot = report.metric("Boot")
    boot.add_row(
        status="pass" if result.booted else "fail",
        board=board.value,
        lines=len(result.lines),
        seconds=round(result.elapsed, 1),
        kernel=result.matched or "",
    )
    report.print_metric(boot)

    report.kpi("fpga_boot_seconds", round(result.elapsed, 1), unit="s", better="lower")

    if result.booted:
        report.success(f"Linux booted in {result.elapsed:.1f}s: {result.matched}")
        report.set_label(f"BOOT {result.elapsed:.0f}s")
    elif result.timed_out:
        # A board that says nothing at all points at the setup (console,
        # power, SD card) rather than at the design being tested.
        report.error(
            f"No '{expect}' line after {boot_timeout}s "
            f"({len(result.lines)} console line(s) read)",
            env=not result.lines,
        )
        report.set_label("BOOT TIMEOUT")
    else:
        report.error(f"Boot did not reach '{expect}'")
        report.set_label("BOOT FAILED")

    # The last console lines in the report, so a failure can be read
    # without opening the transcript
    report.log("Boot log", result.lines[-50:])

    # ==========================================================
    # BUILD MANIFEST
    # ==========================================================
    write_manifest(
        out_dir,
        "fpga-linux-boot",
        {
            "target": target,
            "board": board,
            "console_kind": console_kind,
            "uart": uart,
            "cable": cable,
            "baudrate": baudrate,
            "booted": result.booted,
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
