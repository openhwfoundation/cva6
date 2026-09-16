# Copyright 2026 Thales France
#
# Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
# You may obtain a copy of the License at https://solderpad.org/licenses/
#
# Original Author: Yannick Casamatta (yannick.casamatta@thalesgroup.com)

"""
Recipe report utilities.

Each recipe builds a YAML report (`cook_report.yml`) in its output
directory, in parallel with the console output. The goals of the report:

- give the context (recipe name, target, test name, toolchain, options...)
- give the global status of the run: PASS or FAIL
- on failure: record the error lines needed to understand and fix the issue
- on success: record the useful metrics (kGates, perf, list of executed
  tests...) so the user can check what was actually done to produce the
  PASS/FAIL verdict

The report body is a list of metrics with pure values (no markup, no
unit embedded in the value), so recipe reports can be collected by the
CI and displayed on the dashboard without a dedicated log-grepping
script: the recipe already has all the context (target/testname/
toolchain) and analyzes its own logs. Metric kinds: `table` (dict),
`rows` (list of dicts, columns = keys, a `status` key holds the row
verdict), `log` (text lines), `data` (raw payload), `kpi` (comparable
value). How a value is displayed is inferred from the column name and
value type (see flows/utils/formats.py), with optional `fmt` overrides.

Report structure mirrors the recipe console structure: each recorded
message is attached to the current recipe step (see `step()`). The global
verdict is the top-level `status: pass|fail` key; each Summary row also
carries its own `status` column (pass/fail/env).

Errors are classified with the `fail_kind` top-level key:
- "environment": python/linux/license/tool/prerequisite problem, the run
  verdict is not meaningful (fix the setup and re-run)
- "test": real error extracted from the tool logs (simulation failed,
  compile error...), the thing under test is at fault

Typical usage in a recipe:

    report = RecipeReport(
        "my-recipe",
        title="MY RECIPE",                          # banner + "Options" table
        context={"target": target},
        quiet=quiet,
    )
    ...
    report.add_context({"march": march})            # context resolved later
    report.add_context(                             # record + print as table
        compiler_data, table="Compiler parameters"
    )
    ...
    report.step("Run simulation")                   # step header + track step
    ...
    report.success("Compilation successful")        # print + record
    report.error("Simulation FAILED")               # print + record + fail
    report.error(f"tool not found: {e}", env=True)  # environment error
    report.error_exit("tool missing", env=True)     # error + report + exit(1)
    ...
    report.analyze_log(                             # grep a log into the report
        log_file,
        error_patterns=[r"^Error-"],
        warning_patterns=[r"^Warning-"],
    )
    ...
    report.metric("Timing", {"cycles": cycles})     # dict -> table
    results = report.metric("Test results")         # empty -> rows
    results.add_row(test=test_name, status="pass")
    ...
    report.kpi("kgates", 42.31, unit="kGates",      # compared across
               expected=42.0, better="lower")       # pipelines
    ...
    report.end("Completed")                         # write cook_report.yml,
                                                    # exit(1) if any failure

Console output respects the `quiet` toggle given at construction (or via
set_quiet); everything is still recorded in the report when quiet is on.

Recipes must not raise `typer.Exit` directly: use `error_exit()` for
early aborts and `end()` as the single exit point of a recipe. Both
write the report before exiting, so the report exists even on failure.

In CI, the `cook_report.yml` files are collected directly from `build/`
by the pipeline; the report is only written to the recipe output
directory.
"""

import os
import re
from datetime import datetime as dt
from enum import Enum
from pathlib import Path
from typing import NoReturn
import typer
import yaml
from rich.panel import Panel
from rich.rule import Rule
from rich.padding import Padding
from rich.table import Table
from rich.syntax import Syntax
from rich.text import Text

from flows.utils.console import console
from flows.utils import formats

REPORT_NAME = "cook_report.yml"

# Known benchmarks: substring of the test name -> scores derived from
# iterations-per-MHz (score = ipmhz * factor). Each entry becomes a column of
# the "<test> results" metric and a `<test>_<kpi>` KPI, so one measurement can
# be published under several normalisations: Dhrystone reports the raw
# iteration rate and DMIPS/MHz (that rate / the 1757 Dhrystones/s of the VAX
# 11/780 defining 1 DMIPS), a CoreMark score already being a rate.
KNOWN_BENCHMARKS = {
    "dhrystone": {
        "Dhrystone/MHz": {"factor": 1.0, "kpi": "per_mhz"},
        "DMIPS/MHz": {"factor": 1.0 / 1757, "kpi": "dmips_per_mhz"},
    },
    "coremark": {"CM/MHz": {"factor": 1.0, "kpi": "per_mhz"}},
}


def known_benchmark_scores(test_name):
    """Return the score table of a known benchmark, or None."""
    for key, scores in KNOWN_BENCHMARKS.items():
        if key in test_name:
            return scores
    return None


def _serialize(value):
    """Convert values to plain YAML-friendly types."""
    if isinstance(value, Enum):
        return value.value
    if isinstance(value, Path):
        return str(value)
    if isinstance(value, (list, tuple)):
        return [_serialize(v) for v in value]
    if isinstance(value, dict):
        return {k: _serialize(v) for k, v in value.items()}
    return value


# ==========================================================
# Metrics (dashboard format)
# ==========================================================


class Metric:
    """
    A metric is a named part of the report body.

    Values are pure (no markup, no unit inside the value); the display
    format of each column is inferred from its name and value type
    (see flows/utils/formats.py), with optional `fmt` overrides:
    `fmt={"cycles": "cycles", "diff": "delta"}`.
    """

    def __init__(self, name, fmt=None):
        self.name = name
        self.failed = False
        self.fmt = dict(fmt) if fmt else {}
        self.values = []

    def to_doc(self):
        "Transform to a dictionary (report document format)"
        doc = {
            "name": self.name,
            "kind": self._kind(),
            "status": "fail" if self.failed else "pass",
            "data": self.values,
        }
        if self.fmt:
            doc["fmt"] = dict(self.fmt)
        return doc

    def fail(self):
        "Mark metric as failed"
        self.failed = True

    def _kind(self):
        raise NotImplementedError()


class LogMetric(Metric):
    "Log lines"

    def add_value(self, line):
        "Insert a line in the log"
        self.values.append(line)

    def _kind(self):
        return "log"


class TableMetric(Metric):
    "Two-column name/value table built from a dict"

    def __init__(self, name, data=None, fmt=None):
        super().__init__(name, fmt)
        self.values = {}
        if data:
            for key, value in data.items():
                self.add_value(key, value)

    def add_value(self, key, value):
        "Set a name/value entry of the table"
        self.values[str(key)] = _serialize(value)

    def _kind(self):
        return "table"


class RowsMetric(Metric):
    """
    Table built from rows (one dict per row, columns = the dict keys).

    The row verdict is an ordinary
    `status` column ("pass", "fail" or "env"); a fail/env row marks the
    metric (and thus the report) as failed at write time.
    """

    def add_row(self, **cols):
        "Append a row; a 'fail' or 'env' status marks the metric failed"
        row = {str(k): _serialize(v) for k, v in cols.items()}
        self.values.append(row)
        if str(row.get("status", "")).lower() in ("fail", "env"):
            self.fail()
        return row

    def _kind(self):
        return "rows"


class KpiMetric(Metric):
    """
    Key performance indicator: a single value meant to be compared.

    A KPI is a contract with the dashboard: a stable name and a pure
    value that can be compared between two pipelines without parsing.
    KPIs are also collected in the top-level `kpi:` dict of the report.
    """

    def __init__(self, name, value, unit=None, expected=None, better=None):
        super().__init__(name)
        self.values = {"value": _serialize(value)}
        if unit is not None:
            self.values["unit"] = str(unit)
        if expected is not None:
            self.values["expected"] = _serialize(expected)
        if better is not None:
            self.values["better"] = str(better)

    def _kind(self):
        return "kpi"


class DataMetric(Metric):
    """
    Raw data payload for post-processing.

    Not meant to be displayed: carries machine-readable data (lists,
    dicts of series...) attached to a report for later post-processing
    such as matplotlib/plotly graphs. Produces `kind: data` in the YAML
    document, with the payload stored as-is under `data`.
    """

    def __init__(self, name, payload=None):
        super().__init__(name)
        self.values = payload

    def set_value(self, payload):
        "Set the data payload"
        self.values = payload

    def _kind(self):
        return "data"


# Central reporting hub of every recipe: its size is assumed
# pylint: disable-next=too-many-instance-attributes,too-many-public-methods
class RecipeReport:
    """
    Build a recipe report in parallel with the console output.

    The `info/success/warning/error` methods both print to the console
    (respecting the `quiet` toggle) and record the message in the report,
    so recipes do not have to duplicate every message.
    """

    def __init__(
        self, recipe, out_dir=None, context=None, label=None, quiet=False, title=None
    ):
        """
        Args:
            recipe: cook.py recipe name (e.g. "vcs-uvm-run")
            out_dir: recipe output directory where cook_report.yml is written
                     (can be set later with set_out_dir)
            context: dict of the options used by the recipe
                     (same dict as write_manifest); recorded in the report
                     and printed as the "Options" parameter table
            label: short label shown on the dashboard (e.g. "12.34 kGates"),
                   defaults to PASS/FAIL
            quiet: suppress console output (messages are still recorded in
                   the report); can be changed later with set_quiet
            title: recipe title banner printed before the "Options" table
                   (console only, same as calling title())
        """
        self.recipe = recipe
        self.out_dir = Path(out_dir) if out_dir else None
        self.label = label
        self.quiet = quiet
        self.failed = False
        self.env_failed = False
        self._step = ""
        self._started_at = int(dt.now().timestamp())
        self._context = {}
        self._summary = RowsMetric("Summary")
        self._details = LogMetric("Details")
        self._metrics = []
        if title:
            self.title(title)
        if context:
            self.add_context(context, table="Options")

    # ==========================================================
    # Context
    # ==========================================================

    def set_out_dir(self, out_dir):
        "Set the directory where cook_report.yml will be written"
        self.out_dir = Path(out_dir)

    def set_quiet(self, quiet):
        "Enable/disable quiet mode (suppress console output of the methods)"
        self.quiet = quiet

    def add_context(self, context, table=None):
        """
        Add or update context entries (recipe options, resolved values...).

        If `table` is given, the entries are also printed as a parameter
        table with that title (e.g. "Compiler parameters"), so parameters
        of an element selected by an option can be displayed and recorded
        in one call:

            report.add_context(compiler_data, table="Compiler parameters")
        """
        serialized = {str(k): _serialize(v) for k, v in context.items()}
        self._context.update(serialized)
        if table:
            self.param_table(serialized, table)

    def set_label(self, label):
        "Set the report label (e.g. '12.34 kGates', '15/16 PASS')"
        self.label = label

    # ==========================================================
    # Print + record helpers
    # ==========================================================

    def title(self, msg):
        "Print the recipe title banner (console only, not recorded)"
        if not self.quiet:
            console.print(
                Panel(
                    msg,
                    expand=True,
                    style="bold",
                    border_style="blue",
                )
            )

    def end(self, msg="Completed"):
        """
        Finish the recipe: write the report, print the end message and
        exit with code 1 if the report is failed.

        Call this once at the end of the recipe instead of
        `write_report()` + `raise typer.Exit(...)`: every failure recorded
        with `error(...)` (directly or through analyze_log/status_table)
        makes the recipe exit with a non-zero code.
        """
        self.write_report()
        if not self.quiet:
            console.print(msg, style="bold cyan")
        if self.failed:
            raise typer.Exit(code=1)

    def param_table(self, params, name):
        "Print a parameter table (console only, context is recorded separately)"
        if not self.quiet and isinstance(params, dict):
            table = Table(show_header=False, box=None)
            table.add_column("Name")
            table.add_column("Value")
            for n, v in params.items():
                table.add_row(n, str(v))
            console.print(
                Panel(
                    table,
                    title=name,
                    title_align="left",
                    border_style="white",
                    expand=False,
                )
            )

    def _fmt_cell(self, key, value, fmt):
        "Return a rich Text cell formatted with the shared display formats"
        cell_fmt = fmt.get(str(key)) or formats.infer_fmt(key, value)
        return Text(
            formats.render(value, cell_fmt), style=formats.style(value, cell_fmt)
        )

    def _print_table(self, name, data, fmt):
        "Print a name/value metric table (console only)"
        if self.quiet or not data:
            return
        table = Table(show_header=False, box=None)
        table.add_column("Name")
        table.add_column("Value")
        for k, v in data.items():
            table.add_row(str(k), self._fmt_cell(k, v, fmt))
        console.print(
            Panel(
                table,
                title=name,
                title_align="left",
                border_style="white",
                expand=False,
            )
        )

    def _print_rows(self, name, rows, fmt):
        "Print a rows metric (console only, columns = the row keys)"
        if self.quiet or not rows:
            return
        columns = []
        for row in rows:
            for key in row:
                if key not in columns:
                    columns.append(key)
        table = Table(box=None)
        for key in columns:
            table.add_column(str(key).upper())
        for row in rows:
            table.add_row(*[self._fmt_cell(k, row.get(k), fmt) for k in columns])
        console.print(
            Panel(
                table,
                title=name,
                title_align="left",
                border_style="white",
                expand=False,
            )
        )

    def code(self, content, lang):
        "Print a syntax-highlighted code block and record it in the details"
        if not self.quiet:
            console.print(Padding(Syntax(content, lang, word_wrap=True), (0, 2)))
        self._details.add_value(
            f"[{self._step}] {content}" if self._step else str(content)
        )

    def styled_table(self, params, title, column_name, style):
        "Print a styled multi-column table (console only, not recorded)"
        if not self.quiet:
            table = Table(show_header=False, box=None)
            for i, name in enumerate(column_name):
                table.add_column(name, style=style[i])
            table.add_row(*column_name)
            for k, v in params.items():
                table.add_row(k, *v)
            console.print(
                Panel(
                    table,
                    title=title,
                    title_align="left",
                    border_style="white",
                    expand=False,
                )
            )

    def file_regex(
        self,
        file_path,
        error_patterns=None,
        warning_patterns=None,
        highlight_patterns=None,
    ):
        "Print file lines matching patterns (console only, not recorded)"
        if self.quiet:
            return
        err = [re.compile(p, re.I) for p in (error_patterns or [])]
        warn = [re.compile(p, re.I) for p in (warning_patterns or [])]
        high = [re.compile(p, re.I) for p in (highlight_patterns or [])]
        try:
            with file_path.open("r") as f:
                lines = f.readlines()
            for line in lines:
                if any(p.search(line) for p in err):
                    console.print(Text(line), style="bold white on red", end="")
                elif any(p.search(line) for p in warn):
                    console.print(Text(line), style="black on yellow", end="")
                elif any(p.search(line) for p in high):
                    console.print(Text(line), end="")
        except Exception as e:
            console.print(f"Error print results: {e}", style="red")

    def step(self, name):
        """
        Print a step header and set the current step.

        Every following success/error line recorded in the report is
        attached to this step.
        """
        if not self.quiet:
            console.print(Rule(name, style="bold cyan"))
        self._step = str(name)

    def info(self, msg):
        "Print an info message and record it in the report details"
        if not self.quiet:
            console.print(f"{msg}", style="white", highlight=False)
        self._details.add_value(f"[{self._step}] {msg}" if self._step else str(msg))

    def warning(self, msg):
        "Print a warning message and record it in the report details"
        if not self.quiet:
            console.print(f"{msg}", style="yellow", highlight=False)
        self._details.add_value(
            f"[{self._step}] WARNING: {msg}" if self._step else f"WARNING: {msg}"
        )

    def success(self, msg):
        "Print a success message and record a PASS line in the report summary"
        if not self.quiet:
            console.print(f"\\[{msg}]", style="green", highlight=False)
        self._summary.add_row(status="pass", step=self._step, message=str(msg))

    def error(self, msg, env=False):
        """
        Print an error message, record a FAIL line and mark the report failed.

        Args:
            env: set True for environment errors (python/linux/license/tool/
                 prerequisite problem) as opposed to real errors extracted
                 from the tool logs. Environment failures are labelled ENV
                 in the summary and reported in the `fail_kind` key.
        """
        if not self.quiet:
            console.print(f"{msg}", style="red", highlight=False)
        status = "env" if env else "fail"
        self._summary.add_row(status=status, step=self._step, message=str(msg))
        self.failed = True
        if env:
            self.env_failed = True

    def fail(self):
        "Mark the report as failed without printing anything"
        self.failed = True

    def error_exit(self, msg, code=1, env=False) -> NoReturn:
        """
        Print an error, record it, write the report and exit the recipe.

        Use this instead of `error(...)` + `raise typer.Exit(code=1)`
        so the report file is written even on early failures and contains
        the information needed to fix the problem.
        """
        self.error(msg, env=env)
        self.write_report()
        raise typer.Exit(code=code)

    # ==========================================================
    # Metrics
    # ==========================================================

    def add_metric(self, *metrics):
        "Attach one or more metrics to the report"
        for m in metrics:
            self._metrics.append(m)

    def metric(self, name, data=None, fmt=None):
        """
        Add a metric with pure values (print + record).

        The metric kind is chosen from the data:
        - dict -> `table`: two-column name/value table
        - list of dicts -> `rows`: one dict per row, columns = the keys.
          A `status` key ("pass"/"fail"/"env") holds the row verdict; a
          fail/env row marks the whole report as failed at write time.
        - None -> empty `rows` metric, to be filled with `add_row(...)`
          (incremental rows are recorded but not printed)

        Values must stay pure (no unit, no markup inside the value): the
        display format of each column is inferred from its name and value
        type (see flows/utils/formats.py). Use `fmt` only for ambiguous
        cases: `report.metric("Timing", rows, fmt={"cycles": "cycles"})`.

        Returns the metric.
        """
        if isinstance(data, dict):
            metric = TableMetric(name, data, fmt)
            self._print_table(name, metric.values, metric.fmt)
        else:
            metric = RowsMetric(name, fmt)
            for row in data or []:
                metric.add_row(**row)
            if metric.values:
                self._print_rows(name, metric.values, metric.fmt)
        self._metrics.append(metric)
        return metric

    def print_metric(self, metric):
        """
        Print a metric on the console (console only, nothing recorded).

        Useful to recap at the end of a recipe a metric filled
        incrementally with `add_row(...)` (which does not print).
        """
        if isinstance(metric.values, dict):
            self._print_table(metric.name, metric.values, metric.fmt)
        else:
            self._print_rows(metric.name, metric.values, metric.fmt)

    def kpi(self, name, value, unit=None, expected=None, better=None):
        """
        Add a key performance indicator (print + record).

        A KPI is a metric meant to be compared: a stable name and a pure
        value read directly by the dashboard (top-level `kpi:` dict of
        the report), without parsing any display string.

        Args:
            name: stable KPI name (renaming it breaks dashboard history)
            value: measured value (pure number)
            unit: display unit (e.g. "kGates", "CoreMark/MHz")
            expected: baseline value, typically read from
                      `config/target/<target>/expected_values.yml`
            better: "lower" or "higher", direction of improvement

        Recording a KPI emits no verdict: checking the value against the
        expected one (and calling `error(...)`) is up to the recipe.
        """
        metric = KpiMetric(name, value, unit, expected, better)
        self._metrics.append(metric)
        if not self.quiet:
            text = f"KPI {name}: {formats.render(value, 'num')}"
            if unit:
                text += f" {unit}"
            if expected is not None:
                text += f" (expected {formats.render(expected, 'num')})"
            console.print(text, style="cyan", highlight=False)
        return metric

    def table(self, name, data, fmt=None):
        "Alias of metric() for dict data (two-column name/value table)"
        return self.metric(name, dict(data), fmt)

    def log(self, name, lines):
        """
        Add a log metric from a list of lines.

        Returns the LogMetric for further additions.
        """
        metric = LogMetric(name)
        for line in lines:
            metric.add_value(str(line))
        self._metrics.append(metric)
        return metric

    def data(self, name, payload):
        """
        Add a raw data metric (record-only, nothing is printed).

        Attach machine-readable data to the report for later
        post-processing (e.g. matplotlib/plotly graphs). The payload is
        converted to plain YAML-friendly types and stored under a
        `type: data` metric, ignored by the dashboard display.

        Example:
            report.data("freq_sweep", {"mhz": [100, 200], "mw": [1.2, 2.5]})

        Returns the DataMetric for further updates via set_value().
        """
        metric = DataMetric(name, _serialize(payload))
        self._metrics.append(metric)
        return metric

    def benchmark(self, target, test_name, cycles, iterations=None):
        """
        Record benchmark results (print + record).

        `iterations` is the number of benchmark iterations executed in
        the measured window. It must come from the binary that actually
        ran (the `benchmark_iterations` key of the sw-compile build
        manifest, recorded by the coremark/dhrystone patterns), not from
        a hand-maintained constant: a mismatch silently skews the score.

        Two cases:
        - `test_name` matches a known benchmark (see KNOWN_BENCHMARKS)
          and `iterations` is known: every score of the benchmark
          (CM/MHz, or Dhrystone/MHz *and* DMIPS/MHz) is recorded, with
          the `<test_name>_cycle` KPI and one KPI per score. When a
          baseline is available (key `<test_name>_cycle` of
          `config/target/<target>/expected_values.yml`), any cycle
          deviation fails the report.
        - otherwise (normal pattern): only the cycle count is recorded,
          no verdict is emitted.

        The report label is set to "<X> kCycles" in both cases.

        Returns True if the check passed (or no check was done),
        False on cycle count deviation.
        """
        self.set_label(f"{cycles / 1000:.2f} kCycles")

        scores = known_benchmark_scores(test_name)

        if scores is not None and iterations is None:
            self.warning(
                "No iteration count available (GLOBAL_PATTERN window not "
                "hit, or count not recorded at compile time): reporting "
                "the raw cycle count, no score"
            )

        if scores is None or iterations is None:
            self.info(f"{test_name}: {cycles} cycles")
            self.metric(
                f"{test_name} results", {"cycles": cycles}, fmt={"cycles": "cycles"}
            )
            return True

        # Baseline of the target, optional: a missing file or key only
        # skips the check (see utils/target_config.py). Imported here and
        # not at module level: target_config is about the design under
        # test, the report is about the recipe, and only this method
        # bridges the two.
        # pylint: disable-next=import-outside-toplevel,cyclic-import
        from flows.utils.target_config import read_config_expected_value

        expected_cycles = read_config_expected_value(target, f"{test_name}_cycle", self)
        if expected_cycles is not None:
            try:
                expected_cycles = int(expected_cycles)
                self.info(f"Read expected: {expected_cycles} expected cycles.")
            except (TypeError, ValueError) as e:
                self.warning(
                    f"Invalid '{test_name}_cycle' baseline ({e}), "
                    f"skipping cycle count check"
                )
                expected_cycles = None

        ipmhz = iterations * 1000000 / cycles

        # KPI named after the expected_values.yml key, comparable
        # between pipelines without parsing
        self.kpi(
            f"{test_name}_cycle",
            cycles,
            unit="cycles",
            expected=expected_cycles,
            better="lower",
        )
        # One KPI per published score (dhrystone_per_mhz,
        # dhrystone_dmips_per_mhz, ...), read by name by the Bench columns.
        for score_name, score in scores.items():
            self.kpi(
                f"{test_name}_{score['kpi']}",
                round(ipmhz * score["factor"], 2),
                unit=score_name,
                expected=(
                    round(iterations * 1000000 / expected_cycles * score["factor"], 2)
                    if expected_cycles
                    else None
                ),
                better="higher",
            )

        results = {"iterations": iterations, "cycles": cycles}
        if expected_cycles is not None:
            results["expected"] = expected_cycles
            results["diff"] = cycles - expected_cycles
        for score_name, score in scores.items():
            results[score_name] = round(ipmhz * score["factor"], 2)

        metric = self.metric(
            f"{test_name} results",
            results,
            fmt={"expected": "cycles", "cycles": "cycles", "diff": "delta"},
        )

        if expected_cycles is None:
            return True

        passed = cycles == expected_cycles
        if passed:
            self.success("PASS: Cycle count matchs!")
        else:
            metric.fail()
            self.error("FAIL: Cycle count deviation detected!")

        return passed

    # ==========================================================
    # Log analysis
    # ==========================================================

    def analyze_log(
        self,
        log_file,
        name=None,
        error_patterns=None,
        warning_patterns=None,
        env_patterns=None,
        ignore_patterns=None,
        max_lines=200,
        fail_on_error=True,
        ignore_case=True,
    ):
        """
        Grep a log file and record matching lines in the report.

        The recipe has all the context, so it analyzes its own logs and
        attaches the relevant lines directly to the report.

        Args:
            log_file: path of the log file to analyze
            name: metric display name (default: "<filename> analysis")
            error_patterns: regex list; matching lines are recorded and,
                            if fail_on_error, mark the report as failed
            warning_patterns: regex list; matching lines are recorded
            env_patterns: regex list; matching lines are environment errors
                          (license checkout failure, missing tool/file...):
                          recorded, counted as errors and reported in the
                          `fail_kind` key as "environment"
            ignore_patterns: regex list; matching lines are skipped
            max_lines: maximum number of lines recorded in the metric
            fail_on_error: mark the report failed if an error line is found
            ignore_case: case-insensitive matching (default True)

        Returns:
            (n_errors, n_warnings) match counts (not capped by max_lines)
        """
        log_file = Path(log_file)
        if name is None:
            name = f"{log_file.name} analysis"

        flags = re.IGNORECASE if ignore_case else 0
        err = [re.compile(p, flags) for p in (error_patterns or [])]
        warn = [re.compile(p, flags) for p in (warning_patterns or [])]
        env = [re.compile(p, flags) for p in (env_patterns or [])]
        ign = [re.compile(p, flags) for p in (ignore_patterns or [])]

        metric = LogMetric(name)
        n_err, n_warn = 0, 0

        if not log_file.exists():
            metric.add_value(f"log file not found: {log_file}")
            if fail_on_error:
                metric.fail()
                self.failed = True
                self.env_failed = True
            self._metrics.append(metric)
            return (1, 0)

        try:
            with log_file.open("r", encoding="utf-8", errors="replace") as f:
                for line in f:
                    line = line.rstrip("\n")
                    if any(p.search(line) for p in ign):
                        continue
                    if any(p.search(line) for p in env):
                        n_err += 1
                        self.env_failed = True
                        if len(metric.values) < max_lines:
                            metric.add_value(f"[ENV] {line}")
                    elif any(p.search(line) for p in err):
                        n_err += 1
                        if len(metric.values) < max_lines:
                            metric.add_value(line)
                    elif any(p.search(line) for p in warn):
                        n_warn += 1
                        if len(metric.values) < max_lines:
                            metric.add_value(line)
        except Exception as e:
            self.warning(f"Could not analyze log {log_file}: {e}")

        if n_err + n_warn > max_lines:
            metric.add_value(
                f"... truncated: {n_err} error(s), {n_warn} warning(s) in total"
            )

        if n_err > 0 and fail_on_error:
            metric.fail()
            self.failed = True

        if metric.values:
            self._metrics.append(metric)

        return (n_err, n_warn)

    # ==========================================================
    # Write
    # ==========================================================

    def write_report(self, out_dir=None):
        """
        Write the report.

        Writes `cook_report.yml` in the recipe output directory (`out_dir`
        argument, or the one given at construction / via set_out_dir).

        A report writing failure never fails the recipe: errors are
        reported as warnings only.
        """
        if out_dir is not None:
            self.out_dir = Path(out_dir)
        try:
            # Collect the metrics (Summary first, Details last)
            metrics = []
            if self._summary.values:
                metrics.append(self._summary)
            metrics.extend(self._metrics)
            if self._details.values:
                metrics.append(self._details)

            # Propagate metric failures (rows with a fail status, failed
            # analyze_log metric...) to the report status, so end() exits
            # with a non-zero code
            self.failed = self.failed or any(m.failed for m in metrics)
            failed = self.failed

            status = "fail" if failed else "pass"
            doc = {
                # Wall-clock of this recipe, not of the CI job: a macro runs
                # many recipes inside one job, whose CI_JOB_STARTED_AT would
                # date every one of them from the start of the whole job.
                "job_started_at": self._started_at,
                "job_end_at": int(dt.now().timestamp()),
                "status": status,
                "metrics": [m.to_doc() for m in metrics],
                "label": self.label if self.label else status.upper(),
            }

            # KPIs are duplicated in a top-level dict so cross-pipeline
            # tools read them without walking the metrics list
            kpis = {m.name: m.values for m in metrics if isinstance(m, KpiMetric)}
            if kpis:
                doc["kpi"] = kpis

            # Dashboard job metadata, only when running in CI (GitLab sets
            # GITLAB_CI, GitHub Actions sets GITHUB_ACTIONS). The reports
            # are collected from the job artifacts by the merge job.
            if os.environ.get("GITLAB_CI") or os.environ.get("GITHUB_ACTIONS"):
                doc["category"] = os.environ.get("DASHBOARD_JOB_CATEGORY")
                doc["job_id"] = os.environ.get("CI_JOB_ID")
                doc["job_url"] = os.environ.get("CI_JOB_URL")
                doc["job_stage_name"] = os.environ.get("CI_JOB_STAGE")

            # Extra keys for humans and tools reading the report directly
            doc["recipe"] = self.recipe
            doc["context"] = dict(self._context)
            if not failed:
                doc["fail_kind"] = None
            elif self.env_failed:
                doc["fail_kind"] = "environment"
            else:
                doc["fail_kind"] = "test"

            if self.out_dir is not None:
                report_path = self.out_dir / REPORT_NAME
                report_path.parent.mkdir(parents=True, exist_ok=True)
                with report_path.open("w", encoding="utf-8") as f:
                    yaml.dump(doc, f)
                if not self.quiet:
                    console.print(f"report written: {report_path}", style="white")
        except Exception as e:
            console.print(f"Could not write report: {e}", style="yellow")
