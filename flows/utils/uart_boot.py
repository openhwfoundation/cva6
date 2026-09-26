# Copyright 2026 Thales France
#
# Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
# You may obtain a copy of the License at https://solderpad.org/licenses/
#
# Original Author: Guillaume Chauvon

"""
Read the console of an FPGA board until Linux has booted.

Follow the console, answer the shell prompt with `uname -a`, and take the
line naming the kernel and the architecture as the proof that the system
is up. A **wall clock deadline** bounds the whole boot: a recipe cannot
delegate its verdict to a job timeout, and a board that never boots must
fail on its own.

Two transports, because the two FPGA families expose their console
differently, while the boot itself looks the same on both:

- a **serial port**, on the Xilinx boards: their design drives an
  `apb_uart` wired to the `rx`/`tx` pins of the top level. Opened through
  `serial.serial_for_url`, so it can be a local device (`/dev/ttyUSB1`) or
  a **remote one reached over TCP** (`socket://host:port`). The board is
  often wired to another machine than the one running the flows - a
  Windows PC next to the bench, the recipes on a Linux server - and a USB
  cable does not travel over a remote desktop session. A serial to TCP
  bridge on the machine holding the board is what makes the console
  reachable, the same way `hw_server` makes the JTAG reachable.

- a **JTAG UART**, on the Altera boards: their design instantiates
  `cva6_intel_jtag_uart_0` and has no serial pin at all, the console
  travelling over the JTAG cable. It is read by running the vendor
  terminal (`juart-terminal`) and following its output, so the "device" is
  a program rather than a port.

The transport is the only difference: `watch_boot()` drives both through
the same loop, and each is a small object exposing `readline()` and
`write()`.

Takes no RecipeReport and therefore never terminates the calling recipe:
it returns what it saw, and reports a broken console by raising
(`serial.SerialException` derives from `OSError`), which the recipe
handles. See the helper convention of `flows/CONTRIBUTING.md`.

`pyserial` is imported lazily: cook.py imports every recipe at startup,
and a missing optional dependency must not break the whole CLI.
"""

import select
import subprocess
import time

# URL schemes accepted by `serial.serial_for_url` for a console that is
# not a local device. `socket://` is the one a serial to TCP bridge
# exposes (com0com + hub4com, ser2net, socat...); `rfc2217://` adds the
# Telnet extension that carries the line settings, so the baudrate is
# applied by the bridge rather than assumed.
URL_SCHEMES = ("socket://", "rfc2217://")

# Vendor terminal reading the Altera JTAG UART. Ships with Quartus, in the
# `quartus/bin` of the install (also of the standalone programmer).
JUART_TERMINAL = "juart-terminal"


def is_url(device):
    """
    True when `device` is a pyserial URL rather than a local device.

    Used by the recipes to skip the existence check on a path that is not
    one: `socket://bench-pc:4001` has no entry in the filesystem.
    """
    return str(device).startswith(URL_SCHEMES)


# The board prints a `# ` shell prompt when the boot is over; answering
# it makes the kernel identify itself on the console.
PROMPT = "#"
PROMPT_COMMAND = b"uname -a\n"

# The `uname -a` answer of a booted system carries both of these: the
# distribution built by the CVA6 SDK and the architecture of the core.
DEFAULT_EXPECT = "Linux buildroot"
ARCH_MARKER = "riscv"


class BootResult:
    """
    Outcome of a boot watch.

    Attributes:
        booted: the expected kernel line was seen
        lines: the whole console transcript, one entry per line
        matched: the line that concluded the boot, or None
        elapsed: seconds spent watching the console
        timed_out: the deadline expired before the kernel line appeared
    """

    def __init__(self, booted, lines, matched, elapsed, timed_out):
        self.booted = booted
        self.lines = lines
        self.matched = matched
        self.elapsed = elapsed
        self.timed_out = timed_out


class SerialConsole:
    """
    Console of a board reached through a serial port.

    Thin wrapper over pyserial, opened from a device path or a URL: what
    `watch_boot()` needs of a console is a line to read and a command to
    write back.
    """

    def __init__(self, device, baudrate, read_timeout=1):
        # Imported here rather than at module level: see the module
        # docstring. `import-error` is disabled too, pyserial being needed
        # by this single recipe: a workstation that never drives a board
        # does not install it, and the lint must not ask it to.
        # pylint: disable-next=import-outside-toplevel,import-error
        import serial

        # serial_for_url() rather than Serial(): it accepts a local device
        # and a `socket://` URL alike, so a board wired to another machine
        # needs no special case. `do_not_open` + explicit settings: the
        # baudrate of a URL must be applied before opening, an already open
        # socket would ignore it.
        self._port = serial.serial_for_url(str(device), do_not_open=True)
        self._port.baudrate = baudrate
        self._port.timeout = read_timeout
        self._port.open()

    def readline(self):
        "Return the next raw line, or b'' when nothing arrived in time"
        return self._port.readline()

    def write(self, data):
        "Send a command back to the board"
        self._port.write(data)
        self._port.flush()

    def close(self):
        "Release the port"
        self._port.close()


class JuartConsole:
    """
    Console of a board reached through the Altera JTAG UART.

    Runs the vendor terminal and follows its output. Writing back goes to
    its stdin, which `juart-terminal` forwards to the board, so answering
    the shell prompt works as on a serial port.

    The terminal is killed on close: it does not stop on its own, its own
    help telling the user to interrupt it.
    """

    def __init__(
        self, cable=None, instance=None, executable=JUART_TERMINAL, read_timeout=1
    ):
        cmd = [executable]
        if cable:
            cmd += ["--cable", str(cable)]
        if instance is not None:
            cmd += ["--instance", str(instance)]
        self.cmd = cmd
        self._read_timeout = read_timeout
        try:
            # pylint: disable-next=consider-using-with
            self._proc = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                stdin=subprocess.PIPE,
                bufsize=0,
            )
        except (FileNotFoundError, PermissionError) as e:
            # Same contract as the serial transport: an unusable console is
            # an OSError the recipe reports as an environment failure.
            raise OSError(f"cannot run {' '.join(cmd)}: {e}") from e

    def readline(self):
        """
        Return the next raw line, or b'' when nothing arrived in time.

        Bounded like the read timeout of a serial port, and for the same
        reason: a silent board must not hold the caller. `readline()` on a
        pipe blocks until the writer produces a newline or exits, so a
        terminal that prints nothing would ignore the deadline of
        `watch_boot()` entirely; `select` is what makes the wait bounded.
        """
        if self._proc.stdout is None:
            return b""
        ready, _, _ = select.select([self._proc.stdout], [], [], self._read_timeout)
        if not ready:
            return b""
        return self._proc.stdout.readline()

    def write(self, data):
        "Send a command to the board through the terminal stdin"
        try:
            self._proc.stdin.write(data)
            self._proc.stdin.flush()
        except (BrokenPipeError, OSError):
            # The terminal died: the next readline() returns b'' and the
            # watch ends on its deadline rather than on an exception here.
            pass

    def close(self):
        "Stop the vendor terminal"
        if self._proc.poll() is None:
            self._proc.terminate()
            try:
                self._proc.wait(timeout=5)
            except subprocess.TimeoutExpired:
                self._proc.kill()
        for stream in (self._proc.stdout, self._proc.stdin):
            if stream is not None:
                stream.close()


def watch_boot(console, timeout, expect=DEFAULT_EXPECT, arch=ARCH_MARKER, on_line=None):
    """
    Watch a console until Linux boots or the deadline expires.

    Transport agnostic: `console` is anything exposing `readline()`,
    `write()` and `close()`, so a serial port and the JTAG UART terminal
    go through the same logic.

    Args:
        console: SerialConsole or JuartConsole
        timeout: wall clock budget in seconds for the whole boot
        expect: substring identifying the booted kernel
        arch: substring identifying the architecture, expected on the
              same line as `expect`
        on_line: optional callback receiving each line as it arrives

    Returns:
        BootResult
    """
    lines = []
    deadline = time.monotonic() + timeout
    started = time.monotonic()

    try:
        while True:
            if time.monotonic() >= deadline:
                return BootResult(False, lines, None, time.monotonic() - started, True)

            raw = console.readline()
            if not raw:
                continue  # nothing yet, the deadline above is the guard

            line = raw.decode("utf-8", errors="replace").rstrip("\r\n")
            lines.append(line)
            if on_line is not None:
                on_line(line)

            # End of boot: identify the system on the console, once per
            # prompt.
            if line.strip() == PROMPT or line.rstrip().endswith(PROMPT):
                console.write(PROMPT_COMMAND)
                continue

            if expect in line and arch in line:
                return BootResult(True, lines, line, time.monotonic() - started, False)
    finally:
        console.close()


def watch_linux_boot(
    device,
    baudrate,
    timeout,
    expect=DEFAULT_EXPECT,
    arch=ARCH_MARKER,
    on_line=None,
):
    """
    Watch a serial console until Linux boots or the deadline expires.

    Convenience wrapper opening a `SerialConsole` and handing it to
    `watch_boot()`.

    Args:
        device: console of the board, either a local device
            (`/dev/ttyUSB1`, `COM3`) or a pyserial URL reaching a remote
            one (`socket://bench-pc:4001`, `rfc2217://bench-pc:4001`)
        baudrate: console baudrate, a property of the board
        timeout: wall clock budget in seconds for the whole boot
        expect: substring identifying the booted kernel
        arch: substring identifying the architecture
        on_line: optional callback receiving each line as it arrives

    Returns:
        BootResult

    Raises:
        OSError: the console cannot be opened or read (a refused TCP
            connection included: `serial.SerialException` derives from it)
        ImportError: pyserial is not installed
    """
    return watch_boot(
        SerialConsole(device, baudrate),
        timeout,
        expect=expect,
        arch=arch,
        on_line=on_line,
    )
