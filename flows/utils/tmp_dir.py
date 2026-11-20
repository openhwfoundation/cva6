# Copyright 2026 Thales France
#
# Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
# You may obtain a copy of the License at https://solderpad.org/licenses/
#
# Original Author: Yannick Casamatta (yannick.casamatta@thalesgroup.com)

"""
Scratch directory of the short probes run by the recipes (tool versions,
AsciiDoctor extensions).

The probes run under build/tmp/ of the repository rather than in the
temporary directory of the system, which is not writable on every machine,
and away from the source tree, since some tools write logs in their
current directory. Each probe gets its own directory, removed on exit.
"""

from pathlib import Path
import tempfile

BUILD_TMP = Path("build") / "tmp"


def scratch_dir(repo_dir=None):
    """
    Context manager yielding the path of a new directory under build/tmp/,
    removed on exit.
    """
    root = Path(repo_dir or Path.cwd()) / BUILD_TMP
    root.mkdir(parents=True, exist_ok=True)
    return tempfile.TemporaryDirectory(dir=root)
