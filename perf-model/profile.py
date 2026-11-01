from dataclasses import dataclass
import subprocess
import sys
import re

import flameprof

import isa

re_instr = re.compile(
    r"([a-z]+)\s+0:\s*0x00000000([0-9a-f]+)\s*\(([0-9a-fx]+)\)\s*@\s*([0-9]+)\s*(.*)"
)
# Cycle written before the instruction, as by corev_apu/tb/rvfi_tracer.sv
re_prefix = re.compile(
    r"^\s*([0-9]+)\s*\|\s*([a-z]+)\s+0:\s*0x00000000([0-9a-f]+)\s*\(([0-9a-fx]+)\)\s*(.*)"
)
re_mem = re.compile(r"mem\s*0x([0-9a-f]+)")


@dataclass
class AsmFunc:
    index: int
    name: str
    size: int
    vma: int
    lma: int
    file_off: int
    align: int

    def start_addr(self):
        return self.vma

    def end_addr(self):
        return self.vma + self.size

    def contains(self, addr):
        return self.start_addr() <= addr and addr < self.end_addr()

    def load_elf(path):
        with open(path, "r", encoding="utf8") as f:
            lines = f.readlines()
        return [AsmFunc._from_line(l.split()) for l in lines if ".text." in l]

    def _from_line(line):
        return AsmFunc(
            index=int(line[0]),
            name=line[1][6:],
            size=int(line[2], 16),
            vma=int(line[3], 16),
            lma=int(line[4], 16),
            file_off=int(line[5], 16),
            align=int(line[6][3:], 16),
        )


@dataclass
class RvfiInstr:
    def __init__(self, address, cycle, op, name, line, next_line=None):
        self.address = address
        self.cycle = cycle
        self.op = isa.Instr(op)
        self.line = line
        self.name = name
        self.mem_address = None
        if self.op.is_load() or self.op.is_store():
            assert next_line is not None
            self.mem_address = int(re_mem.search(next_line).group(1), 16)

    def load_trace(path):
        with open(path, "r", encoding="utf8") as f:
            lines = f.readlines()
        return RvfiInstr._from_lines(lines)

    def _from_lines(lines):
        instrs = []
        for i, l in enumerate(lines):
            line = l.strip()
            found = re_instr.search(line)
            if found:
                address, op, cycle, mnemo = (
                    found.group(2),
                    found.group(3),
                    found.group(4),
                    found.group(5),
                )
            else:
                found = re_prefix.search(line)
                if not found:
                    continue
                address, op, cycle, mnemo = (
                    found.group(3),
                    found.group(4),
                    found.group(1),
                    found.group(5),
                )
            instr = RvfiInstr(
                address=int(address, 16),
                cycle=int(cycle),
                op=int(op, 16),
                line=line,
                name=mnemo.split(" ")[0],
                next_line=lines[i + 1] if i + 1 < len(lines) else None,
            )
            instrs.append(instr)
        return instrs


class CallStack:
    def __init__(self, functions):
        self.stack = []
        self.fns = {f.start_addr(): f for f in functions}

    def run(self, instr):
        addr = instr.address

        f = self.fns.get(addr)
        if f:
            e = RawEvent(stack=self.stack_names(), cycle=instr.cycle)
            self.stack.append(f)
            return e

        if len(self.stack) > 0:
            curr = self.stack[-1]
            if not curr.contains(addr) and any(
                f.contains(addr) for f in self.fns.values()
            ):
                e = RawEvent(stack=self.stack_names(), cycle=instr.cycle)
                self.stack.pop()
                return e

        return None

    def stack_names(self):
        return [f.name for f in self.stack]


@dataclass
class RawEvent:
    stack: list
    cycle: int


@dataclass
class Event:
    stack: list
    instr: RvfiInstr
    duration: int
    icount: int
    executed_ins: dict


def run_all(fns, instrs):
    events = []
    cs = CallStack(fns)
    last_event_cycle = 0
    last_event_i = 0
    last_instr_cycle = 0
    executed_ins = {}

    for i, instr in enumerate(instrs):
        count, tot_duration = executed_ins.get(instr.name, (0, 0))
        count += 1
        tot_duration += instr.cycle - last_instr_cycle
        executed_ins[instr.name] = count, tot_duration
        last_instr_cycle = instr.cycle

        event = cs.run(instr)
        if event:
            events.append(
                Event(
                    stack=event.stack,
                    instr=instr,
                    duration=event.cycle - last_event_cycle,
                    icount=i - last_event_i,
                    executed_ins=executed_ins,
                )
            )
            last_event_cycle = event.cycle
            last_event_i = i
            executed_ins = {}

    return events


def fake_file(func):
    return ("", 1, func)


class Stat:
    def __init__(self):
        self.cc = 0
        self.nc = 0
        self.tt = 0
        self.ct = 0
        self.icount = 0
        self.callers = {}

    def ipc(self):
        return self.icount / self.tt if self.tt > 0 else 0.0

    def build(self):
        callers = {fake_file(func): t for func, t in self.callers.items()}
        return (self.cc, self.nc, self.tt, self.ct, callers)

    def add_caller(self, caller, c_cc, c_nc, c_tt, c_ct):
        cc, nc, tt, ct = (
            self.callers[caller] if caller in self.callers else (0, 0, 0, 0)
        )

        cc += c_cc
        nc += c_nc
        tt += c_tt
        ct += c_ct

        self.callers[caller] = (cc, nc, tt, ct)


def put_stat(d, name):
    if not name in d:
        d[name] = Stat()


def build_stats(events, inst_analysis=False):
    stats = {}
    last_stack = []

    for event in events:
        if len(event.stack) == 0:
            continue
        stack = event.stack
        # Current function, in the which event.duration has been spent
        func = stack[-1]
        put_stat(stats, func)
        # All time is spent inside instructions
        duration = 0 if inst_analysis else event.duration

        if inst_analysis:
            for instr_name, (count, d) in event.executed_ins.items():
                put_stat(stats, instr_name)
                stats[instr_name].tt += d
                stats[instr_name].ct += d
                stats[instr_name].add_caller(func, 0, count, d, d)

        # Spent duration right into func
        stats[func].tt += duration
        stats[func].icount += event.icount

        # Spent duration in func and its parents
        for f in stack:
            stats[f].ct += event.duration

        # Spent duration while being called directly by caller
        if len(stack) > 1:
            caller = stack[-2]
            stats[func].add_caller(caller, 0, 0, duration, 0)

        # Each function in the call stack spent duration called by its caller
        for i, callee in enumerate(stack):
            if i > 0:
                caller = stack[i - 1]
                stats[callee].add_caller(caller, 0, 0, 0, event.duration)

        if len(event.stack) >= len(last_stack):
            # Make sure it is a call
            assert len(event.stack) == len(last_stack) + 1
        else:
            # Make sure it is a ret
            assert len(event.stack) == len(last_stack) - 1

            callee = last_stack[-1]
            caller = func
            put_stat(stats, caller)

            # The caller called the callee once
            # It is not a prim call if the callee was already in the stack.
            c_cc = 1 if not callee in event.stack else 0
            stats[callee].add_caller(caller, c_cc, 1, 0, 0)
            stats[callee].cc += c_cc
            stats[callee].nc += 1

        last_stack = stack

    return stats

    # { func: (cc, nc, tt, ct, callers) }
    # func = file_name, line_number, func_name
    # cc = prim_calls = number of calls if not already in call stack (non-recurse calls)?
    # nc = number of calls
    # tt = tottime = time spent in this function alone (not callees)
    # ct = cumtime = time spent in the function plus all functions that this function called
    # callers/clist = { cfunc: t } = { name: (cc, nc, tt, ct) }


def format_stack_change(old_stack, new_stack):
    if len(old_stack) > len(new_stack):
        return f"RET FROM {old_stack[-1]} (in {new_stack})"
    if len(new_stack) > len(old_stack):
        return f"CALL {new_stack[-1]} (in {old_stack})"
    return None


def render(stats, svg_path, threshold=0):
    stats = {fake_file(func): stat.build() for func, stat in stats.items()}

    with open(svg_path, "w") as f:
        flameprof.render(stats, f, width=3000, threshold=threshold)


def filter_events(events, func_name):
    return [e for e in events if func_name not in e.stack]


if __name__ == "__main__":
    assert len(sys.argv) == 4
    elf_file = sys.argv[1]
    trace_file = sys.argv[2]
    path_svg = sys.argv[3]
    assert path_svg.endswith(".svg")

    functions = AsmFunc.load_elf(elf_file)
    instructions = RvfiInstr.load_trace(trace_file)

    events = run_all(functions, instructions)

    i_event = 0
    for instr in instructions:
        if i_event < len(events) - 1 and events[i_event].instr is instr:
            print(
                ">>>",
                format_stack_change(events[i_event].stack, events[i_event + 1].stack),
            )
            i_event += 1
        print(instr.line)

    stats = build_stats(events)
    duration = sum(map(lambda e: e.duration, events))
    icount = sum(map(lambda e: e.icount, events))
    print("duration:", duration)
    print("icount:", icount)
    print("IPC:", icount / duration)

    ipcs = [(stat.ipc(), func) for func, stat in stats.items()]
    ipcs.sort(reverse=True)
    for ipc, func in ipcs:
        print(f"{ipc:.02f} IPC for {func}")

    render(stats, path_svg)

    stats = build_stats(events, True)
    for f, s in stats.items():
        print(f"{f}: {s.ct}")
    render(stats, f"{path_svg[:-4]}_with_ins.svg")
