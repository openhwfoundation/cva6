# Copyright 2024 Thales Silicon Security
#
# Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
# You may obtain a copy of the License at https://solderpad.org/licenses/
#
# Original Author: Côme ALLART - Thales

import re
import sys

re_csrr_minstret = re.compile(r"^csrrs\s+\w+,\s*minstret\b")
re_full = re.compile(
    r"([a-z]+)\s+0:\s*0x00000000([0-9a-f]+)\s*\(([0-9a-fx]+)\)\s*(\S*)@\s*([0-9]+)\s*(.*)"
)
# Cycle written before the instruction, as by corev_apu/tb/rvfi_tracer.sv
re_prefix = re.compile(
    r"^\s*([0-9]+)\s*\|\s*([a-z]+)\s+0:\s*0x00000000([0-9a-f]+)\s*\(([0-9a-fx]+)\)\s*(.*)"
)


class Trace:
    def __init__(self, addr, cycle, mnemo, flags):
        self.addr = addr
        self.cycle = cycle
        self.mnemo = mnemo
        self.flags = flags
        self.delta = None

    def report(self):
        """True if the instruction is a loading instruction"""
        return f"+{self.delta} {self.flags} 0x{self.addr}: {self.mnemo}"


def print_data(name, value):
    "Prints 'name = data' with alignment of the '='"
    spaces = " " * (24 - len(name))
    print(f"{name}{spaces} = {value}")


def read_traces(input_file):
    "Collect stage traces from file"
    l = []

    def filter_add(trace):
        if not hasattr(filter_add, "accepting"):
            filter_add.accepting = False
        if re_csrr_minstret.search(trace.mnemo):
            filter_add.accepting = not filter_add.accepting
            return
        if filter_add.accepting:
            l.append(trace)

    with open(input_file, "r", encoding="utf8") as f:
        for line in [l.strip() for l in f]:
            found = re_full.search(line)
            if found:
                addr = found.group(2)
                flags = found.group(4)
                cycle = int(found.group(5))
                mnemo = found.group(6)
                filter_add(Trace(addr, cycle, mnemo, flags))
                continue
            found = re_prefix.search(line)
            if found:
                addr = found.group(3)
                cycle = int(found.group(1))
                mnemo = found.group(5)
                filter_add(Trace(addr, cycle, mnemo, ""))
                # l.append(Trace(addr, cycle, mnemo, flags))
    return l


def write_traces(outfile, traces):
    "Write all instructions to output file"
    print("output file:", outfile)
    with open(outfile, "w", encoding="utf8") as f:
        for trace in traces:
            f.write(trace.report() + "\n")


def main(input_file: str):
    "Main function"
    traces = read_traces(input_file)
    cycle = traces[0].cycle
    cycle_number = traces[-1].cycle - cycle + 1
    for trace in traces:
        trace.delta = trace.cycle - cycle
        cycle = trace.cycle
    print_data("cycle number", cycle_number)
    print_data("Coremark/MHz", 1000000 / cycle_number)
    print_data("instruction number", len(traces))
    print_data("IPC", len(traces) / cycle_number)
    write_traces("traceout.log", traces)


if __name__ == "__main__":
    main(sys.argv[1])
