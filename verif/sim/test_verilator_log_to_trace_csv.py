# Copyright 2026 Hyeonuk Jeong
# SPDX-License-Identifier: Apache-2.0

import csv
import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).parent / "dv/scripts"))
from verilator_log_to_trace_csv import process_verilator_sim_log


@pytest.mark.parametrize("disasm,operand", [
    ("lw t0, 4(sp)", "t0,sp,4"),
    ("sw t0, -4(sp)", "t0,sp,-4"),
    ("ld a0, 16(s0)", "a0,s0,16"),
    ("sd a0, 0(s0)", "a0,s0,0"),
    ("flw fa0, 8(sp)", "fa0,sp,8"),
    ("fsd fa0, -8(sp)", "fa0,sp,-8"),
    ("addi t0, sp, 4", "t0,sp,4"),
])
def test_memory_operand_order(tmp_path, disasm, operand):
    logfile = tmp_path / "trace.log"
    logfile.write_text(
        f"core 0: 0x0000000080000000 (0x00412283) {disasm}\n")
    output = tmp_path / "trace.csv"
    assert process_verilator_sim_log(str(logfile), str(output), full_trace=1) == 1
    with output.open() as handle:
        entries = list(csv.DictReader(handle))
    assert entries[0]["operand"] == operand
    assert entries[0]["pc"] == "0000000080000000"
