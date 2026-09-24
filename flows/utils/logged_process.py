# Copyright 2026 OpenHW Foundation
#
# Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
# You may obtain a copy of the License at https://solderpad.org/licenses/
#
# Original Author: Junchao Chen (junchao.chen@eclipse-foundation.org)

"""Run a tool with a file-backed log and a wall-clock timeout."""

# Keep subprocess handling separate so execution recipes can reuse it.

import os
from pathlib import Path
import signal
import subprocess


def _terminate(process: subprocess.Popen) -> None:
    # Each tool owns a new process group, including compiler subprocesses.
    if os.name == "posix":
        try:
            os.killpg(process.pid, signal.SIGTERM)
        except ProcessLookupError:
            pass
    elif process.poll() is None:
        process.terminate()
    try:
        process.wait(timeout=3)
    except subprocess.TimeoutExpired:
        process.kill()
    finally:
        if os.name == "posix":
            try:
                os.killpg(process.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
        process.wait()


def run_logged_process(
    command: list[str],
    *,
    cwd: Path,
    env: dict[str, str],
    log: Path,
    timeout: float,
) -> tuple[int, bool]:
    """Return (exit code, timed out); env is the complete child environment."""
    log.parent.mkdir(parents=True, exist_ok=True)
    with log.open("w", encoding="utf-8") as output:
        with subprocess.Popen(
            command,
            cwd=cwd,
            env=env,
            stdout=output,
            stderr=subprocess.STDOUT,
            start_new_session=os.name == "posix",
        ) as process:
            try:
                return process.wait(timeout=timeout), False
            except subprocess.TimeoutExpired:
                _terminate(process)
                return 124, True
            except BaseException:
                _terminate(process)
                raise
