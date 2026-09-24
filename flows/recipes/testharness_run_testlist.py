# Copyright 2026 OpenHW Foundation
#
# Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
# You may obtain a copy of the License at https://solderpad.org/licenses/
#
# Original Author: Junchao Chen (junchao.chen@eclipse-foundation.org)

from contextlib import redirect_stdout
from enum import Enum
from io import StringIO
from pathlib import Path
import re

import typer
import yaml

from flows.recipes.verilator_testharness_comp import build_directory, validate_options
from flows.recipes.verilator_testharness_run import (
    simulation_directory,
    validate_path_component,
    verilator_testharness_run,
)
from flows.utils.report_builder import Report, TableStatusMetric
from flows.utils.utils import (
    CompMode,
    TraceMode,
    autocompletion_target,
    autocompletion_testlist,
    print_error,
    print_info,
    print_recipe_end,
    print_recipe_title,
)

app = typer.Typer()


class Simulator(str, Enum):
    verilator = "verilator"


def enabled_tests(testlist: Path) -> list[str]:
    data = yaml.safe_load(testlist.read_text(encoding="utf-8"))
    if not isinstance(data, dict) or not isinstance(data.get("testlist"), list):
        raise ValueError("Testlist must contain a 'testlist' sequence")
    names = []
    seen = set()
    for entry in data["testlist"]:
        if not isinstance(entry, dict) or not isinstance(entry.get("test"), str):
            raise ValueError("Each testlist entry needs a string 'test' name")
        name = validate_path_component(entry["test"], "test name")
        iterations = entry.get("iterations", 1)
        if (
            not isinstance(iterations, int)
            or isinstance(iterations, bool)
            or iterations < 0
        ):
            raise ValueError(f"{name}: iterations must be a nonnegative integer")
        for iteration in range(iterations):
            compiled = f"{name}_{iteration}"
            if compiled in seen:
                raise ValueError(f"Duplicate compiled test: {compiled}")
            seen.add(compiled)
            names.append(compiled)
    if not names:
        raise ValueError("No enabled tests in testlist")
    return names


def report_path(repo: Path, target: str, simulator: Simulator, testlist: str) -> Path:
    label = re.sub(r"[^A-Za-z0-9_.-]+", "_", Path(testlist).stem)
    return build_directory(
        repo, target, "simulation", f"testharness_{simulator.value}_{label}_report.yml"
    )


def run_entries(
    names: list[str],
    *,
    target: str,
    comp_mode: CompMode,
    trace_mode: TraceMode,
    iss_enabled: bool,
    quiet: bool,
) -> list[dict]:
    results = []
    for name in names:
        case = {"test_name": name, "status": "FAIL", "detail": "Run did not complete"}
        try:
            output = simulation_directory(Path.cwd(), target, name, comp_mode)
            receipt = output / "result.yml"
            # A failed preflight must not be confused with an earlier passing run.
            receipt.unlink(missing_ok=True)
            run_error = None
            try:
                verilator_testharness_run(
                    target=target,
                    test_name=name,
                    comp_mode=comp_mode,
                    trace_mode=trace_mode,
                    iss_enabled=iss_enabled,
                    interactive_gui=False,
                    quiet=quiet,
                )
            except typer.Exit as error:
                run_error = f"Run recipe exited with code {error.exit_code}"
                if not receipt.exists():
                    case["detail"] = run_error
                    print_error(f"{name}: {run_error}")
                    results.append(case)
                    continue
            result = yaml.safe_load(receipt.read_text(encoding="utf-8"))
            if (
                not isinstance(result, dict)
                or any(
                    result.get(key) != expected
                    for key, expected in {
                        "target": target,
                        "test_name": name,
                    }.items()
                )
                or result.get("iss_enabled") is not False
                or result.get("status") not in {"PASS", "FAIL"}
            ):
                raise ValueError("Missing or inconsistent run result")
            detail = str(result.get("detail", "Run returned no detail"))
            if run_error:
                case["detail"] = f"{run_error}: {detail}"
            else:
                case.update(status=result["status"], detail=detail)
        except (OSError, TypeError, ValueError, yaml.YAMLError) as error:
            case["detail"] = str(error)
        if case["status"] != "PASS":
            print_error(f"{name}: {case['detail']}")
        results.append(case)
    return results


def write_reports(output: Path, cases: list[dict], metadata: dict, quiet: bool) -> None:
    metric = TableStatusMetric("TestHarness testlist results")
    metric.add_column("Target", "text")
    metric.add_column("Test", "text")
    metric.add_column("Detail", "text")
    for case in cases:
        add = metric.add_pass if case["status"] == "PASS" else metric.add_fail
        add(metadata["target"], case["test_name"], case["detail"])
    report = Report()
    report.add_metric(metric)
    if quiet:
        with redirect_stdout(StringIO()):
            report.dump(output)
    else:
        report.dump(output)
    passed = sum(case["status"] == "PASS" for case in cases)
    summary = {
        "schema_version": 1,
        **metadata,
        "status": "PASS" if passed == len(cases) and cases else "FAIL",
        "total": len(cases),
        "passed": passed,
        "failed": len(cases) - passed,
        "cases": cases,
    }
    summary_path = output.with_name(output.name.replace("_report.yml", "_summary.yml"))
    build_directory(Path.cwd(), metadata["target"], "simulation", summary_path.name)
    summary_path.write_text(yaml.safe_dump(summary, sort_keys=False), encoding="utf-8")


@app.command()
def testharness_run_testlist(
    simulator: Simulator = typer.Option(
        ..., "--simulator", "-s", help="TestHarness simulator (verilator only)"
    ),
    target: str = typer.Option(
        ...,
        "--target",
        "-t",
        help="CVA6 user configuration",
        autocompletion=autocompletion_target,
    ),
    testlist: str = typer.Option(
        ...,
        "--testlist",
        "-l",
        help="Cook testlist YAML",
        autocompletion=autocompletion_testlist,
    ),
    comp_mode: CompMode = typer.Option(CompMode.rtl, help="Only rtl is supported"),
    trace_mode: TraceMode = typer.Option(
        TraceMode.notrace, help="notrace, fast (VCD), compact (FST)"
    ),
    iss_enabled: bool = typer.Option(
        False, help="Reserved for ISS comparison; enabling it is not yet supported"
    ),
    quiet: bool = typer.Option(
        False, "--quiet", "-q", help="Suppress output (errors only)"
    ),
) -> None:
    """Run a testlist after separate software and TestHarness compilation."""
    print_recipe_title("TESTHARNESS RUN TESTLIST", quiet=quiet)
    try:
        if iss_enabled:
            raise ValueError("ISS comparison is not supported by this version")
        if simulator != Simulator.verilator:
            raise ValueError(f"Unsupported TestHarness simulator: {simulator}")
        validate_options(comp_mode, trace_mode, stats=False)
        output = report_path(Path.cwd(), target, simulator, testlist)
        output.unlink(missing_ok=True)
        summary = output.with_name(output.name.replace("_report.yml", "_summary.yml"))
        build_directory(Path.cwd(), target, "simulation", summary.name)
        summary.unlink(missing_ok=True)
        names = enabled_tests(Path(testlist))
        cases = run_entries(
            names,
            target=target,
            comp_mode=comp_mode,
            trace_mode=trace_mode,
            iss_enabled=iss_enabled,
            quiet=quiet,
        )
        write_reports(
            output,
            cases,
            {
                "target": target,
                "simulator": simulator.value,
                "testlist": testlist,
                "comp_mode": comp_mode.value,
                "trace_mode": trace_mode.value,
                "iss_enabled": iss_enabled,
            },
            quiet,
        )
    except (OSError, TypeError, ValueError, yaml.YAMLError) as error:
        print_error(str(error))
        raise typer.Exit(code=1) from error
    print_info(f"Report: {output}", quiet=quiet)
    if any(case["status"] != "PASS" for case in cases):
        raise typer.Exit(code=1)
    print_recipe_end("Completed", quiet=quiet)
