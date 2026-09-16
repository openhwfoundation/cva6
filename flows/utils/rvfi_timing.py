# Copyright 2026 Thales France
#
# Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
# You may obtain a copy of the License at https://solderpad.org/licenses/
#
# Original Author: Yannick Casamatta (yannick.casamatta@thalesgroup.com)

"""
Timing extraction from the UVM testbench simulation log.

`corev_apu/tb/rvfi_tracer.sv` displays one line per timing event:

    *** [rvfi_tracer] INFO: GLOBAL_PATTERN_start (0x...) detected at <t> ns, <n> cycles!
    *** [rvfi_tracer] INFO: GLOBAL_PATTERN_end (0x...) detected at <t> ns, <n> cycles!
    *** [rvfi_tracer] INFO: Simulation terminated after <n> cycles!

plus the `$finish at simulation time <t>` line printed by the simulator.
These lines are the same under VCS, Questa and Xcelium: only the line
prefix differs (e.g. `# ` under Questa), so the patterns are not
anchored.

These patterns belong to the UVM testbench: a different testbench needs
its own extraction module.
"""

import re

_SYMBOL = re.compile(
    r"\[rvfi_tracer\] INFO: (GLOBAL_PATTERN_\w+) \((0x[0-9a-fA-F]+)\)"
    r" detected at\s+(\d+) ns,\s+(\d+) cycles"
)
_SIM_END_CYCLES = re.compile(
    r"\[rvfi_tracer\] INFO: Simulation terminated after\s+(\d+) cycles"
)
_SIM_END_NS = re.compile(r"\$finish at simulation time\s+(\d+)")


def extract_rvfi_timing(log_file):
    """
    Parse the timing events of a UVM simulation log.

    Returns a dict of pure values (first occurrence of each event wins):

        {"GLOBAL_PATTERN_start": {"pc": "0x...80001111", "ns": 250, "cycles": 3400},
         "GLOBAL_PATTERN_end":   {"pc": "0x...80003333", "ns": 300, "cycles": 3900},
         "simulation_end":       {"ns": 310, "cycles": 3950}}

    Events not present in the log are simply absent from the dict (e.g.
    no GLOBAL_PATTERN entries when the ELF does not define the symbols).
    """
    events = {}
    with log_file.open("r", encoding="utf-8", errors="replace") as f:
        for line in f:
            m = _SYMBOL.search(line)
            if m:
                events.setdefault(
                    m.group(1),
                    {
                        "pc": m.group(2),
                        "ns": int(m.group(3)),
                        "cycles": int(m.group(4)),
                    },
                )
                continue
            m = _SIM_END_CYCLES.search(line)
            if m:
                events.setdefault("simulation_end", {}).setdefault(
                    "cycles", int(m.group(1))
                )
                continue
            m = _SIM_END_NS.search(line)
            if m:
                events.setdefault("simulation_end", {}).setdefault(
                    "ns", int(m.group(1))
                )
    return events


def benchmark_window(events):
    """
    Return the cycle count of the benchmark window, or None.

    The window is delimited by the GLOBAL_PATTERN symbols when they were
    hit, and falls back to the whole simulation (cycle 0 to the last
    cycle) otherwise.
    """
    start = events.get("GLOBAL_PATTERN_start", {}).get("cycles", 0)
    end = events.get("GLOBAL_PATTERN_end", {}).get("cycles")
    if end is None:
        end = events.get("simulation_end", {}).get("cycles")
    if end is None:
        return None
    return end - start
