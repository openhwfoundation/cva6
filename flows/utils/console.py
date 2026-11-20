# Copyright 2026 Thales France
#
# Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
# You may obtain a copy of the License at https://solderpad.org/licenses/
#
# Original Author: Yannick Casamatta (yannick.casamatta@thalesgroup.com)

"""
Shared Rich console.

Single Console instance used by all flows modules, so terminal rendering
can be configured in one place (e.g. force_terminal for CI colors).
This module must stay a leaf: it must not import anything from flows.
"""

from rich.console import Console

console = Console()
