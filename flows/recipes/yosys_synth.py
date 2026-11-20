# Copyright 2026 Thales France
#
# Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
# You may obtain a copy of the License at https://solderpad.org/licenses/
#
# Original Author: Yannick Casamatta (yannick.casamatta@thalesgroup.com)

# Please refer to flows/README.md to add target

"""
Open-source synthesis of a target with Yosys, on its generic cells.

The open-source counterpart of the GTECH synthesis of dc-shell-synth: no
licence and no PDK, so every target is synthesised. The slang plugin of
Yosys reads the SystemVerilog of config/target/<target>/Flist.cva6_synth,
from the same top as Spyglass, then `synth` maps the design on the
internal cells of Yosys ($_AND_, $_MUX_, $_DFF_..., which have no area).

The figures are the cell, register and latch counts, and the cells of each
block: the hierarchy is kept, so there is no optimisation across blocks
and the totals are higher than those of a flat synthesis. A latch is an
error, the RTL is meant to have none; the counts are checked against
yosys_cells and yosys_registers of
config/target/<target>/expected_values.yml.
"""

from pathlib import Path
import re
import shutil

import typer

from flows.utils.autocompletion import autocompletion_target
from flows.utils.manifest import write_manifest
from flows.utils.recipe_report import RecipeReport
from flows.utils.run_cmd import run_cmd
from flows.utils.target_config import (
    read_config_expected_value,
    read_config_or_exit_testbench_cfg,
    top_elaborate as get_top_elaborate,
)

app = typer.Typer()

# Deviation tolerated on the counts, relative to expected_values.yml
YOSYS_TOLERANCE = 0.05

# Levels of hierarchy the per-block cell counts go down to, below the top
YOSYS_HIER_DEPTH = 4

# Threads slang parses the sources with
YOSYS_THREADS = 4

# Defines of the synthesis, as for dc-shell-synth
YOSYS_DEFINES = ["HPDCACHE_ASSERT_OFF=1"]

# Cell types of the generic library that hold state
REGISTER = re.compile(r"^\$_(S?DFFS?R?E?|ALDFFE?|DFFSRE?)_")
LATCH = re.compile(r"^\$_(DLATCH|SR)")


def _script(flist, top, stat_file):
    "Yosys script of the synthesis"
    defines = " ".join(f"-D{d}" for d in YOSYS_DEFINES)
    return "\n".join(
        [
            "plugin -i slang",
            f"read_slang --best-effort-hierarchy -j {YOSYS_THREADS} -f {flist} "
            f"--top {top} --timescale 1ns/1ps {defines}",
            f"hierarchy -top {top}",
            f"synth -top {top}",
            f"tee -o {stat_file} stat",
            "",
        ]
    )


def _modules(stat_file):
    """
    {module: (cells by type, sub-modules by name)} of a Yosys stat report.

    A cell whose type is another module of the report is a sub-module: its
    cells are not leaf cells of the module that holds it.
    """
    text = stat_file.read_text(encoding="utf-8", errors="replace")
    text = text.split("=== design hierarchy ===")[0]
    parts = re.split(r"^=== (.+?) ===$", text, flags=re.MULTILINE)
    names = set(parts[1::2])
    modules = {}
    for name, body in zip(parts[1::2], parts[2::2]):
        cells, subs = {}, {}
        for cell, count in re.findall(r"^\s+(\S+)\s+(\d+)$", body, re.MULTILINE):
            if cell in names:
                subs[cell] = subs.get(cell, 0) + int(count)
            elif cell.startswith("$"):
                cells[cell] = cells.get(cell, 0) + int(count)
        modules[name] = (cells, subs)
    return modules


def _totals(stat_file, top):
    "Cell, register and latch counts of the design below its top"
    modules = _modules(stat_file)
    cells = {}

    def add(name, times):
        own, subs = modules.get(name, ({}, {}))
        for cell, count in own.items():
            cells[cell] = cells.get(cell, 0) + times * count
        for sub, count in subs.items():
            add(sub, times * count)

    add(top, 1)
    return {
        "yosys_cells": sum(cells.values()),
        "yosys_registers": sum(n for c, n in cells.items() if REGISTER.match(c)),
        "yosys_latches": sum(n for c, n in cells.items() if LATCH.match(c)),
    }


def _hierarchy(stat_file, top, depth):
    """
    Rows (hierarchy, level, cells, pct) of the blocks `depth` levels below
    the top. A module is named <module>$<instance path>: the instance is
    the part after the last dot.
    """
    modules = _modules(stat_file)
    totals = {}

    def total(name):
        if name not in totals:
            own, subs = modules.get(name, ({}, {}))
            totals[name] = sum(own.values()) + sum(
                n * total(s) for s, n in subs.items()
            )
        return totals[name]

    top_cells = total(top) or 1
    rows = []

    def walk(name, path, level):
        for sub in sorted(modules.get(name, ({}, {}))[1]):
            instance = sub.split("$", 1)[-1].rsplit(".", 1)[-1]
            sub_path = f"{path}/{instance}" if path else instance
            rows.append(
                {
                    "hierarchy": sub_path,
                    "level": level,
                    "cells": total(sub),
                    "pct": round(total(sub) / top_cells * 100, 2),
                }
            )
            if level < depth:
                walk(sub, sub_path, level + 1)

    walk(top, "", 1)
    return rows


# ==========================================================
# RECIPE
# ==========================================================


@app.command()
def yosys_synth(
    target: str = typer.Option(
        ...,
        "--target",
        "-t",
        help="CVA6 user configuration",
        autocompletion=autocompletion_target,
    ),
    quiet: bool = typer.Option(
        False, "--quiet", "-q", help="Suppress output (errors only)"
    ),
):
    """
    Open-source synthesis (Yosys) on generic cells
    """
    report = RecipeReport(
        "yosys-synth",
        title="Yosys synthesis (generic cells)",
        context={"target": target},
        quiet=quiet,
    )

    repo_dir = Path.cwd()
    synth_dir = repo_dir / "build" / target / "synthesis_yosys"
    report.set_out_dir(synth_dir)

    top = get_top_elaborate(read_config_or_exit_testbench_cfg(target, report))
    report.add_context({"top_elaborate": top})

    report.step("Prerequisites")
    yosys = shutil.which("yosys")
    if yosys is None:
        report.error_exit(
            "yosys: Not found\n  Source setenv.sh, which puts it in the path.",
            env=True,
        )
    report.success(f"yosys: {yosys}")
    version = run_cmd(
        cmd=[yosys, "-V"], report=report, log_file=None, timeout=60, check=False
    )
    report.add_context({"yosys": (version or "").strip()})

    report.step("Clean")
    try:
        if synth_dir.exists():
            shutil.rmtree(synth_dir)
            report.info(f"remove {synth_dir}")
    except Exception as e:
        report.error_exit(f"Clean error : {e}", env=True)
    synth_dir.mkdir(parents=True, exist_ok=True)

    env_vars = {
        "CVA6_REPO_DIR": str(repo_dir),
        "TARGET_CFG": target,
        "HPDCACHE_DIR": str(repo_dir / "core" / "cache_subsystem" / "hpdcache"),
    }
    flist = repo_dir / "config" / "target" / target / "Flist.cva6_synth"

    report.step("Yosys")
    script = synth_dir / "synth.ys"
    stat_file = synth_dir / "stat.txt"
    script.write_text(_script(flist, top, stat_file), encoding="utf-8")
    log_file = synth_dir / "yosys.log"
    run_cmd(
        cmd=[yosys, "-q", "-l", str(log_file), str(script)],
        report=report,
        cwd=synth_dir,
        env=env_vars,
        error_patterns=[r"^ERROR:", r": error:"],
        warning_patterns=None,
        highlight_patterns=None,
        log_file=synth_dir / "yosys.out",
        timeout=6000,
        check=True,
        capture_output=False,
    )
    report.analyze_log(
        log_file,
        name="yosys.log analysis",
        error_patterns=[r"^ERROR:", r": error:"],
        warning_patterns=[r"^Warning: "],
        fail_on_error=True,
    )
    if not stat_file.exists():
        report.error_exit(f"{stat_file.name} missing: the synthesis did not end")

    report.step("Cell counts")
    counts = _totals(stat_file, top)
    report.metric("Global results", dict(counts))
    report.set_label(f"{counts['yosys_cells'] / 1000:.1f} kCells")

    hier_metric = report.metric("Hierarchies details", fmt={"pct": "pct"})
    for row in _hierarchy(stat_file, top, YOSYS_HIER_DEPTH):
        hier_metric.add_row(
            hierarchy=row["hierarchy"],
            level=row["level"],
            kcells=round(row["cells"] / 1000, 2),
            pct=row["pct"],
        )
    report.print_metric(hier_metric)

    if counts["yosys_latches"]:
        report.error(f"{counts['yosys_latches']} latch(es) inferred")

    for name in ("yosys_cells", "yosys_registers"):
        value = counts[name]
        expected = read_config_expected_value(target, name, report)
        report.kpi(
            name,
            value,
            unit="cells",
            expected=expected,
            better="lower",
            tolerance=YOSYS_TOLERANCE,
        )
        if expected is None:
            report.info(f"{name}: {value}, no expected value")
        elif abs(value - expected) > expected * YOSYS_TOLERANCE:
            report.error(
                f"{name}: {value}, expected {expected} "
                f"(deviation over {YOSYS_TOLERANCE:.0%})"
            )
        else:
            report.success(f"{name}: {value}, expected {expected}")

    write_manifest(synth_dir, "yosys-synth", {"target": target}, report=report)
    report.log(
        "Generated files",
        [
            str(p.relative_to(repo_dir))
            for p in sorted(synth_dir.glob("*"))
            if p.suffix in (".ys", ".log", ".txt")
        ],
    )
    report.end("Completed")
