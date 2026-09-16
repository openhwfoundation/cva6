# Copyright 2026 Thales France
#
# Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
# You may obtain a copy of the License at https://solderpad.org/licenses/
#
# Original Author: Yannick Casamatta (yannick.casamatta@thalesgroup.com)

"""
Robust command runner used by all cook.py recipes.

Commands are executed without a shell, their output is streamed to the
console (with optional highlight patterns) and optionally captured
and/or written to a log file. Execution problems are recorded in the
recipe report instead of raising, so recipes can check `report.failed`
and let `report.end()` set the exit code.
"""

import subprocess
import os
import re
import signal
import platform
import threading
from rich.text import Text
from flows.utils.console import console


def _kill_process_group(process):
    """Terminate the whole process group (SIGKILL after a grace period)."""
    if platform.system() == "Windows":
        # pylint: disable-next=no-member
        process.send_signal(signal.CTRL_BREAK_EVENT)
        return
    try:
        pgid = os.getpgid(process.pid)
    except ProcessLookupError:
        return
    os.killpg(pgid, signal.SIGTERM)
    try:
        process.wait(timeout=3)
    except subprocess.TimeoutExpired:
        os.killpg(pgid, signal.SIGKILL)


def run_cmd(
    cmd,
    *,
    report,
    cwd=None,
    env=None,
    error_patterns=None,
    warning_patterns=None,
    highlight_patterns=None,
    stdin=None,
    log_file=None,
    timeout=None,
    check=True,
    capture_output=True,
):
    """
    Robust command runner. Never raises (except KeyboardInterrupt):
    execution problems are recorded in the report instead, so recipes
    can check `report.failed` and let `report.end()` set the exit code.

    Args:
        report: RecipeReport of the calling recipe. The command line, cwd
            and execution errors are printed and recorded through it;
            console verbosity follows `report.quiet` (tool output
            streaming and decorations are console-only).
        check: with check=True (default), a non-zero exit code is
            recorded as an error in the report. Unexecutable commands
            (environment errors) and timeouts are always recorded,
            regardless of check.
        timeout: wall-clock limit in seconds on the total command
            runtime. On expiry the whole process group is killed by a
            watchdog timer, so a process hanging while keeping stdout
            open (e.g. a stuck simulation) is covered too.
    """

    if isinstance(cmd, str):
        report.error(
            "Cmd is a string, Passing a command as a string is not supported. Prefer a list of arguments to avoid shell parsing issues"
        )
        return "" if capture_output else None

    err = [re.compile(p, re.I) for p in (error_patterns or [])]
    warn = [re.compile(p, re.I) for p in (warning_patterns or [])]
    high = [re.compile(p, re.I) for p in (highlight_patterns or [])]

    full_env = {**os.environ, **(env or {})}

    popen_kwargs = {
        "stdout": subprocess.PIPE,
        "stderr": subprocess.STDOUT,
        "stdin": stdin,
        "text": True,
        "bufsize": 1,
        "env": full_env,
        "cwd": cwd,
        "shell": False,
        "close_fds": True,
    }

    if platform.system() == "Windows":
        popen_kwargs["creationflags"] = subprocess.CREATE_NEW_PROCESS_GROUP
    else:
        popen_kwargs["start_new_session"] = True

    report.info("Set current working directory:")
    report.code(str(cwd), "bash")

    report.info("Command launched:")
    report.code(" ".join(cmd), "bash")

    # Environment variables are console-only, not recorded in the report
    report.param_table(env, "Environment variables")

    if stdin is None:
        report.info("Stdin: Not used")
    else:
        report.info("Stdin: Used")

    try:
        process = subprocess.Popen(cmd, **popen_kwargs)
    except (FileNotFoundError, PermissionError) as e:
        # Missing/non-executable tool: environment error. Record it in the
        # log file (if any) so recipes can analyze it into their report
        # instead of crashing with a raw traceback.
        msg = f"cannot execute command: {e}"
        report.error(msg, env=True)
        if log_file:
            with log_file.open("w") as f:
                f.write(msg + "\n")
        return "" if capture_output else None

    logfile = log_file.open("w") if log_file else None
    collected_output = []

    # Wall-clock watchdog: kills the process group on expiry so the
    # stdout reading loop below unblocks (pipe closed) even if the
    # process was hanging without producing output.
    timed_out = threading.Event()
    watchdog = None
    if timeout:

        def _on_timeout():
            timed_out.set()
            _kill_process_group(process)

        watchdog = threading.Timer(timeout, _on_timeout)
        watchdog.daemon = True
        watchdog.start()

    if not report.quiet:
        console.print("[Begin]", style="white", highlight=False)
    try:
        for line in iter(process.stdout.readline, ""):

            if capture_output:
                collected_output.append(line)

            if logfile:
                logfile.write(line)
                logfile.flush()

            if not report.quiet:
                if any(p.search(line) for p in err):
                    console.print(Text(line), style="bold white on red", end="")
                elif any(p.search(line) for p in warn):
                    console.print(Text(line), style="black on yellow", end="")
                elif any(p.search(line) for p in high):
                    console.print(Text(line), style="black on green", end="")

        process.stdout.close()
        process.wait()

    except KeyboardInterrupt:
        report.warning("Interrupted! Killing process group...")
        _kill_process_group(process)
        raise

    finally:
        if watchdog:
            watchdog.cancel()
        if logfile:
            logfile.close()
        if not report.quiet:
            console.print("[End]", style="white", highlight=False)

    if timed_out.is_set():
        report.error(f"Command timed out after {timeout}s, process group killed")
    elif check and process.returncode != 0:
        report.error(f"Command failed ({process.returncode})")

    if capture_output:
        return "".join(collected_output)

    return None
