# Copyright 2024 Thales Silicon Security
#
# Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
# You may obtain a copy of the License at https://solderpad.org/licenses/
#
# Original Author: Côme ALLART - Thales

"""
Performance model of the cva6
"""

import argparse
import re

from dataclasses import dataclass
from enum import Enum
from collections import defaultdict

# from matplotlib import pyplot as plt

from isa import Instr, Reg

EventKind = Enum(
    "EventKind",
    [
        "WAW",
        "WAR",
        "RAW",
        "BMISS",
        "BHIT",
        "STRUCT",
        "issue",
        "done",
        "commit",
    ],
)


def to_signed(value, xlen=32):
    signed = value
    if signed >> (xlen - 1):
        signed -= 1 << xlen
    return signed


class Event:
    """Represents an event on an instruction"""

    def __init__(self, kind, cycle):
        self.kind = kind
        self.cycle = cycle

    def __repr__(self):
        return f"@{self.cycle}: {self.kind}"


class Instruction(Instr):
    """Represents a RISC-V instruction with annotations"""

    def __init__(self, line, address, hex_code, mnemo):
        Instr.__init__(self, int(hex_code, base=16))
        self.line = line
        self.address = int(address, base=16)
        self.hex_code = hex_code
        self.mnemo = mnemo
        self.events = []

    def mnemo_name(self):
        """The name of the instruction (fisrt word of the mnemo)"""
        return self.mnemo.split()[0]

    def next_addr(self):
        """Address of next instruction"""
        return self.address + self.size()

    _ret_regs = [Reg.ra, Reg.t0]

    def is_ret(self):
        "Does CVA6 consider this instruction as a ret?"
        f = self.fields()
        # Strange conditions, no imm check, no rd-discard check
        return (
            self.is_regjump()
            and f.rs1 in Instruction._ret_regs
            and (self.is_compressed() or f.rs1 != f.rd)
        )

    def is_call(self):
        "Does CVA6 consider this instruction as a ret?"
        base = self.base()
        f = self.fields()
        return (
            base == "C.JAL"
            or base == "C.J[AL]R/C.MV/C.ADD"
            and f.name == "C.JALR"
            or base in ["JAL", "JALR"]
            and f.rd in Instruction._ret_regs
        )

    def __repr__(self):
        return self.mnemo


@dataclass
class Entry:
    """A scoreboard entry"""

    instr: Instruction
    cycles_since_issue = 0
    done: bool = False

    def __repr__(self):
        status = "DONE" if self.done else "WIP "
        addr = f"0x{self.instr.address:08X}"
        return f"{status} {addr}:`{self.instr}` for {self.cycles_since_issue}"


@dataclass
class LastIssue:
    """To store the last issued instruction"""

    instr: Instruction
    issue_cycle: int


class IqLen:
    """Model of the instruction queue with only a size counter"""

    def __init__(self, fetch_size, debug=False):
        self.fetch_size = 4
        while self.fetch_size < fetch_size:
            self.fetch_size <<= 1
        self.debug = debug
        self.len = self.fetch_size
        self.new_fetch = True

    def fetch(self):
        """Fetch bytes"""
        self.len += self.fetch_size
        self._debug(f"fetched {self.fetch_size}, got {self.len}")
        self.new_fetch = True

    def flush(self):
        """Flush instruction queue (bmiss or exception)"""
        self.len = 0
        self._debug(f"flushed, got {self.len}")
        self.new_fetch = False

    def jump(self):
        """Loose a fetch cycle and truncate (jump, branch hit taken)"""
        if self.new_fetch:
            self.len -= self.fetch_size
            self._debug(f"jumping, removed {self.fetch_size}, got {self.len}")
            self.new_fetch = False
        self._truncate()
        self._debug(f"jumped, got {self.len}")

    def has(self, instr):
        """Does the instruction queue have this instruction?"""
        length = self.len
        if self._is_crossword(instr):
            length -= self.fetch_size - 2
        self._debug(f"comparing {length} to {instr.size()} ({instr})")
        return length >= instr.size()

    def remove(self, instr):
        """Remove instruction from queue"""
        self.len -= instr.size()
        self._debug(f"removed {instr.size()}, got {self.len}")
        self._truncate(self._addr_index(instr.next_addr()))
        if instr.is_jump():
            self.jump()

    def _addr_index(self, addr):
        return addr & (self.fetch_size - 1)

    def _is_crossword(self, instr):
        is_last = self._addr_index(instr.address) == self.fetch_size - 2
        return is_last and not instr.is_compressed()

    def _truncate(self, index=0):
        occupancy = self.fetch_size - self._addr_index(self.len)
        to_remove = index - occupancy
        if to_remove < 0:
            to_remove += self.fetch_size
        self.len -= to_remove
        self._debug(f"truncated, removed {to_remove}, got {self.len}")

    def _debug(self, message):
        if self.debug:
            print(f"iq: {message}")


class Ras:
    "Return Address Stack"

    def __init__(self, depth=2, debug=False):
        self.depth = depth - 1
        self.stack = []
        self.debug = debug
        self.last_dropped = None

    def push(self, addr):
        "Push an address on the stack, forget oldest entry if full"
        self.stack.append(addr)
        self._debug(f"pushed 0x{addr:08X}")
        if len(self.stack) > self.depth:
            self.stack.pop(0)
            self._debug("overflown")

    def drop(self):
        "Drop an address from the stack"
        self._debug("dropping")
        if len(self.stack) > 0:
            self.last_dropped = self.stack.pop()
        else:
            self.last_dropped = None
            self._debug("was already empty")

    def read(self):
        "Read the top of the stack without modifying it"
        self._debug("reading")
        if self.last_dropped is not None:
            addr = self.last_dropped
            self._debug(f"read 0x{addr:08X}")
            return addr
        self._debug("was empty")
        return None

    def resolve(self, instr):
        "Push or pop depending on the instruction"
        self._debug(f"issuing {instr}")
        if instr.is_ret():
            self._debug("detected ret")
            self.drop()
        if instr.is_call():
            self._debug("detected call")
            self.push(instr.next_addr())

    def _debug(self, message):
        if self.debug:
            print(f"RAS: {message}")


class Bht:
    "Branch History Table"

    @dataclass
    class Entry:
        "A BTB entry"

        valid: bool = False
        sat_counter: int = 0

    def __init__(self, entries=128):
        self.contents = [Bht.Entry() for _ in range(entries)]

    def predict(self, addr):
        "Is the branch taken? None if don't know"
        entry = self.contents[self._index(addr)]
        if entry.valid:
            return entry.sat_counter >= 2
        return None

    def resolve(self, addr, taken):
        "Update branch prediction"
        index = self._index(addr)
        entry = self.contents[index]
        entry.valid = True
        if taken:
            if entry.sat_counter < 3:
                entry.sat_counter += 1
        else:
            if entry.sat_counter > 0:
                entry.sat_counter -= 1

    def _index(self, addr):
        return (addr >> 1) % len(self.contents)


Fu = Enum("Fu", ["ALU", "MUL", "BRANCH", "LDU", "STU"])

# We have
# - FLU gathering ALU + BRANCH (+ CSR, not significant in CoreMark)
# - LSU for loads and stores
# - FP gathering MUL + second ALU (+ Floating, unused in CoreMark)
# This way we do not have more write-back ports than currently with F


def to_fu(instr):
    if instr.is_branch() or instr.is_jump() or instr.is_regjump():
        return Fu.BRANCH
    if instr.is_muldiv():
        return Fu.MUL
    if instr.is_load():
        return Fu.LDU
    if instr.is_store():
        return Fu.STU
    return Fu.ALU


class FusBusy:
    "Is each functional unit busy"

    def __init__(self, has_alu2=False):
        self.has_alu2 = has_alu2

        self.alu = False
        self.mul = False
        self.branch = False
        self.ldu = False
        self.stu = False
        self.alu2 = False

        self.issued_mul = False

    def _alu2_ready(self):
        return self.has_alu2 and not self.alu2

    def is_ready(self, fu):
        return {
            Fu.ALU: self._alu2_ready() or not self.alu,
            Fu.MUL: not self.mul,
            Fu.BRANCH: not self.branch,
            Fu.LDU: not self.ldu,
            Fu.STU: not self.stu,
        }[fu]

    def is_ready_for(self, instr):
        return self.is_ready(to_fu(instr))

    def issue(self, instr):
        return {
            Fu.ALU: FusBusy.issue_alu,
            Fu.MUL: FusBusy.issue_mul,
            Fu.BRANCH: FusBusy.issue_branch,
            Fu.LDU: FusBusy.issue_ldu,
            Fu.STU: FusBusy.issue_stu,
        }[to_fu(instr)](self)

    def issue_mul(self):
        self.mul = True
        self.issued_mul = True

    def issue_alu(self):
        if not self._alu2_ready():
            assert not self.alu
            self.alu = True
            self.branch = True
        else:
            self.alu2 = True

    def issue_branch(self):
        self.alu = True
        self.branch = True
        # Stores are not allowed yet
        self.stu = True

    def issue_ldu(self):
        self.ldu = True
        self.stu = True

    def issue_stu(self):
        self.stu = True
        self.ldu = True

    def cycle(self):
        self.alu = self.issued_mul
        self.mul = False
        self.branch = self.issued_mul
        self.ldu = False
        self.stu = False
        self.alu2 = False
        self.issued_mul = False


class Model:
    """Models the scheduling of CVA6"""

    re_instr = re.compile(
        r"([a-z]+)\s+0:\s*0x0*([0-9a-f]+)\s*\(([0-9a-fx]+)\)\s*(@\s*[0-9]+)?\s*(.*)"
    )

    def __init__(
        self,
        debug=False,
        issue=1,
        commit=2,
        sb_len=8,
        fetch_size=None,
        has_forwarding=True,
        has_renaming=True,
        ras_depth=2,
        bht_entries=128,
    ):
        self.ras = Ras(depth=ras_depth, debug=debug)
        self.bht = Bht(entries=bht_entries)
        self.instr_queue = []
        self.scoreboard = []
        self.fus = FusBusy(issue > 1)
        self.last_issued = None
        self.last_committed = None
        self.retired = []
        self.sb_len = sb_len
        self.debug = debug
        self.iqlen = IqLen(fetch_size or 4 * issue, debug)
        self.issue_width = issue
        self.commit_width = commit
        self.has_forwarding = has_forwarding
        self.has_renaming = has_renaming
        self.log = []

    def log_event_on(self, instr, kind, cycle):
        """Log an event on the instruction"""
        if self.debug:
            print(f"{instr}: {kind}")
        event = Event(kind, cycle)
        instr.events.append(event)
        self.log.append((event, instr))

    def predict_branch(self, instr):
        """Predict if branch is taken or not"""
        pred = self.bht.predict(instr.address)
        if pred is not None:
            return pred
        return instr.offset() >> 31 != 0

    def predict_regjump(self, instr):
        """Predict destination address of indirect jump"""
        if instr.is_ret():
            return self.ras.read() or 0
        return 0  # always miss, as there is no btb yet

    def predict_pc(self, last):
        """Predict next program counter depending on last issued instruction"""
        if last.is_branch():
            taken = self.predict_branch(last)
            offset = to_signed(last.offset()) if taken else last.size()
            return last.address + offset
        if last.is_regjump():
            return self.predict_regjump(last)
        return None

    def issue_manage_last_branch(self, instr, cycle):
        """Flush IQ if branch miss, jump if branch hit"""
        if self.last_issued is not None:
            last = self.last_issued.instr
            pred = self.predict_pc(last)
            if pred is not None:
                bmiss = pred != instr.address
                resolved = cycle >= self.last_issued.issue_cycle + 6
                if bmiss and not resolved:
                    self.iqlen.flush()
                branch = EventKind.BMISS if bmiss else EventKind.BHIT
                if branch not in [e.kind for e in instr.events]:
                    self.log_event_on(instr, branch, cycle)
                    taken = instr.address != last.next_addr()
                    if taken and not bmiss:
                        # last (not instr) was like a jump
                        self.iqlen.jump()

    def commit_manage_last_branch(self, instr, cycle):
        "Resolve branch prediction"
        if self.last_committed is not None:
            last = self.last_committed
            if last.is_branch():
                taken = instr.address != last.next_addr()
                self.bht.resolve(last.address, taken)
        self.last_committed = instr

    def find_data_hazards(self, instr, cycle):
        """Detect and log data hazards"""
        found = False
        for entry in self.scoreboard:
            if instr.has_WAW_from(entry.instr) and not self.has_renaming:
                self.log_event_on(instr, EventKind.WAW, cycle)
                found = True
            can_forward = self.has_forwarding and entry.done
            if instr.has_RAW_from(entry.instr) and not can_forward:
                self.log_event_on(instr, EventKind.RAW, cycle)
                found = True
        return found

    def find_structural_hazard(self, instr, cycle):
        """Detect and log structural hazards"""
        if not self.fus.is_ready_for(instr):
            self.log_event_on(instr, EventKind.STRUCT, cycle)
            return True
        return False

    def try_issue(self, cycle):
        """Try to issue an instruction"""
        if len(self.instr_queue) == 0 or len(self.scoreboard) >= self.sb_len:
            return
        can_issue = True
        instr = self.instr_queue[0]
        if self.find_data_hazards(instr, cycle):
            can_issue = False
        if self.find_structural_hazard(instr, cycle):
            can_issue = False
        self.issue_manage_last_branch(instr, cycle)
        if not self.iqlen.has(instr):
            can_issue = False
        if can_issue:
            self.iqlen.remove(instr)
            instr = self.instr_queue.pop(0)
            self.log_event_on(instr, EventKind.issue, cycle)
            entry = Entry(instr)
            self.scoreboard.append(entry)
            self.fus.issue(instr)
            self.last_issued = LastIssue(instr, cycle)
            self.ras.resolve(instr)

    def try_execute(self, cycle):
        """Try to execute instructions"""
        for entry in self.scoreboard:
            entry.cycles_since_issue += 1
            instr = entry.instr
            duration = 1
            if instr.is_load() or instr.is_store():
                duration = 2
            if instr.is_muldiv():
                duration = 2
            if entry.cycles_since_issue == duration:
                self.log_event_on(instr, EventKind.done, cycle)
                entry.done = True

    def try_commit(self, cycle, commit_port):
        """Try to commit an instruction"""
        if len(self.scoreboard) == 0:
            return
        entry = self.scoreboard[0]
        can_commit = True
        if commit_port > 0:
            if entry.instr.is_store():
                can_commit = False
        if not entry.done:
            can_commit = False
        if can_commit:
            instr = self.scoreboard.pop(0).instr
            self.log_event_on(instr, EventKind.commit, cycle)
            self.retired.append(instr)
            self.commit_manage_last_branch(instr, cycle)

    def run_cycle(self, cycle):
        """Runs a cycle"""
        self.fus.cycle()
        for commit_port in range(self.commit_width):
            self.try_commit(cycle, commit_port)
        self.try_execute(cycle)
        for _ in range(self.issue_width):
            self.try_issue(cycle)
        self.iqlen.fetch()

    def load_file(self, path):
        """Fill a model from a trace file"""
        with open(path, "r", encoding="utf8") as file:
            for line in [l.strip() for l in file]:
                found = Model.re_instr.search(line)
                if found:
                    address = found.group(2)
                    hex_code = found.group(3)
                    mnemo = found.group(5)
                    instr = Instruction(line, address, hex_code, mnemo)
                    self.instr_queue.append(instr)

    def run(self, cycles=None):
        """Run until completion"""
        cycle = 0
        while len(self.instr_queue) > 0 or len(self.scoreboard) > 0:
            self.run_cycle(cycle)
            if self.debug:
                print(f"Scoreboard @{cycle}")
                for entry in self.scoreboard:
                    print(f"    {entry}")
                print(f"iqlen = {self.iqlen.len}")
                print()
            cycle += 1

            if cycles is not None and cycle > cycles:
                break
        return cycle


def write_trace(output_file, instructions):
    """Write cycle-annotated trace"""
    pattern = re.compile(r"\)\s*(@\s*[0-9]+)? ")

    lines = []
    for instr in instructions:
        commit_event = instr.events[-1]
        assert commit_event.kind == EventKind.commit
        cycle = commit_event.cycle
        annotated = re.sub(pattern, f") @ {cycle} ", instr.line)
        # if EventKind.STRUCT in [e.kind for e in instr.events]:
        #    annotated += " #STRUCT"
        # if EventKind.RAW in [e.kind for e in instr.events]:
        #    annotated += " #RAW"
        lines.append(f"{annotated}\n")

    with open(output_file, "w") as f:
        f.writelines(lines)


def print_data(name, value, ts=24, sep="="):
    "Prints 'name = data' with alignment of the '='"

    spaces = " " * (ts - len(name))
    print(f"{name}{spaces} {sep} {value}")


def display_scores(scores):
    """Display a 3D graph of scores against commit/issue-wide"""
    bars = []
    for x, l in enumerate(scores):
        for y, z in enumerate(l):
            bars.append((x, y, z))

    x, y, z, dx, dy, dz = [], [], [], [], [], []
    for bx, by, bz in bars:
        x.append(bx)
        y.append(by)
        z.append(0)
        dx.append(0.5)
        dy.append(0.5)
        dz.append(bz)

    # fig = plt.figure()
    # ax1 = fig.add_subplot(111, projection='3d')
    # ax1.bar3d(x, y, z, dx, dy, dz)
    # ax1.set_xlabel("issue")
    # ax1.set_ylabel("commit")
    # ax1.set_zlabel("CoreMark/MHz")
    # plt.show()


def issue_commit_graph(input_file, n=3):
    """Plot the issue/commit graph"""

    r = range(n + 1)
    scores = [[0 for _ in r] for _ in r]

    if input_file is None:
        scores = [
            [0, 0, 0, 0, 0, 0],
            [
                0,
                2.651936045910317,
                2.651936045910317,
                2.651936045910317,
                2.651936045910317,
                2.651936045910317,
            ],
            [
                0,
                3.212779150348426,
                3.6292766488711137,
                3.6292766488711137,
                3.6292766488711137,
                3.6292766488711137,
            ],
            [
                0,
                3.2550388000624966,
                3.900216852056974,
                3.914997572701505,
                3.914997572701505,
                3.914997572701505,
            ],
            [
                0,
                3.2596436557555526,
                3.9257869239889134,
                3.9420984578510834,
                3.9421606193922765,
                3.9421606193922765,
            ],
            [
                0,
                3.260695897718491,
                3.944757614368385,
                3.9623576027736505,
                3.9625460150656,
                3.9625460150656,
            ],
        ]  # pylint: disable=line-too-long
    else:
        r = range(1, n + 1)
        for issue in r:
            for commit in r:
                print("running", issue, commit)
                model = Model(issue=issue, commit=commit)
                model.load_file(input_file)
                model.run()
                n_cycles = count_cycles(filter_timed_part(model.retired))
                score = 1000000 / n_cycles
                scores[issue][commit] = score
        print(scores)
    display_scores(scores)


def filter_timed_part(all_instructions):
    "Keep only timed part from a trace"
    filtered = []
    re_csrr_minstret = re.compile(r"^csrrs\s+\w+,\s*minstret\b")
    accepting = False
    for instr in all_instructions:
        if re_csrr_minstret.search(instr.mnemo):
            accepting = not accepting
            continue
        if accepting:
            filtered.append(instr)
    return filtered


def count_cycles(retired):
    start = min(e.cycle for e in retired[0].events)
    end = max(e.cycle for e in retired[-1].events)
    return end - start


def print_stats(instructions):
    ecount = defaultdict(lambda: 0)

    for instr in instructions:
        for e in instr.events:
            ecount[e.kind] += 1
            cycle = e.cycle
    n_instr = len(instructions)
    n_cycles = count_cycles(instructions)

    print_data("cycle number", n_cycles)
    print_data("Coremark/MHz", 1000000 / n_cycles)
    print_data("instruction number", n_instr)
    for ek, count in ecount.items():
        print_data(f"{ek}/instr", f"{100 * count / n_instr:.2f}%")


def parse_args(argv=None):
    "Command line options, each one a parameter of Model"
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("trace", help="RVFI trace (spike_dasm.log of cook.py)")
    parser.add_argument("--issue", type=int, default=2, help="issue width")
    parser.add_argument("--commit", type=int, default=2, help="commit width")
    parser.add_argument("--sb-len", type=int, default=8, help="scoreboard entries")
    parser.add_argument(
        "--fetch-size",
        type=int,
        default=None,
        help="instruction queue fetch size in bytes (default: 4 * issue)",
    )
    parser.add_argument("--ras-depth", type=int, default=2, help="RAS depth")
    parser.add_argument("--bht-entries", type=int, default=128, help="BHT entries")
    parser.add_argument(
        "--no-forwarding", action="store_true", help="disable operand forwarding"
    )
    parser.add_argument(
        "--no-renaming", action="store_true", help="disable register renaming"
    )
    parser.add_argument(
        "--timed",
        action="store_true",
        help="statistics on the part between the two csrr minstret only",
    )
    parser.add_argument(
        "--output",
        default="annotated.log",
        help="annotated trace (default: annotated.log)",
    )
    parser.add_argument(
        "-q", "--quiet", action="store_true", help="do not print the events"
    )
    return parser.parse_args(argv)


def main(argv=None):
    "Entry point"
    args = parse_args(argv)

    model = Model(
        debug=not args.quiet,
        issue=args.issue,
        commit=args.commit,
        sb_len=args.sb_len,
        fetch_size=args.fetch_size,
        has_forwarding=not args.no_forwarding,
        has_renaming=not args.no_renaming,
        ras_depth=args.ras_depth,
        bht_entries=args.bht_entries,
    )
    model.load_file(args.trace)
    model.run()

    write_trace(args.output, model.retired)

    retired = filter_timed_part(model.retired) if args.timed else model.retired
    print_stats(retired)


if __name__ == "__main__":
    main()
