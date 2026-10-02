# Copyright 2026 OpenHW Group
#
# Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
# You may obtain a copy of the License at https://solderpad.org/licenses/

"""Run Cook-compiled testlists with Verilator TestHarness and Spike."""

from __future__ import annotations

import os
import re
from pathlib import Path
import shlex
import signal
import subprocess
import sys
from typing import Any, NamedTuple

import typer
import yaml

from flows.utils.report_builder import Report, TableStatusMetric
from flows.utils.utils import (
    autocompletion_target,
    autocompletion_testlist,
    autocompletion_testname_in_testlist,
    print_error,
    print_param_table,
    print_recipe_end,
    print_recipe_title,
    print_step,
    print_success,
)

app = typer.Typer()

COMPARE_BACKEND = "veri-testharness,spike"
TANDEM_BACKEND = "veri-testharness"

# cva6.py appends target-specific ISA extensions after parsing --isa.
SUPPORTED_TARGETS = frozenset({"cv32a60x_axi", "cv32a65x_axi"})


class RunContext(NamedTuple):
    repo_dir: Path
    target: str
    target_dir: Path
    build_root: Path
    simulation_root: Path
    generated_iss_file: Path
    default_mabi: str
    privilege: str
    backend: str
    tandem_enabled: bool
    env: dict[str, str]
    iss_timeout: int
    sv_seed: str
    quiet: bool


class CompiledTestResult(NamedTuple):
    name: str
    compiler_isa: str
    mabi: str
    passed: bool


def enabled_tests(
    testlist_data: dict[str, Any], selected: list[str] | None
) -> list[dict[str, Any]]:
    raw_tests = testlist_data.get("testlist")
    if not isinstance(raw_tests, list):
        raise ValueError("testlist must contain a list named 'testlist'")

    tests = []
    for index, test in enumerate(raw_tests):
        if not isinstance(test, dict) or not isinstance(test.get("test"), str):
            raise ValueError(f"Invalid test entry at index {index}")
        try:
            iterations = int(test.get("iterations", 1))
        except (TypeError, ValueError) as error:
            raise ValueError(f"Invalid iterations for test {test['test']}") from error
        if iterations < 0:
            raise ValueError(f"Negative iterations for test {test['test']}")
        if iterations > 0:
            tests.append(test)

    if selected:
        requested = set(selected)
        available = {test["test"] for test in tests}
        unknown = sorted(requested - available)
        if unknown:
            raise ValueError("Unknown or disabled tests: " + ", ".join(unknown))
        tests = [test for test in tests if test["test"] in requested]
    return tests


def validate_target(target: str) -> None:
    if target not in SUPPORTED_TARGETS:
        supported = ", ".join(sorted(SUPPORTED_TARGETS))
        raise ValueError(
            f"Unsupported TestHarness target: {target}; supported targets: {supported}"
        )


def cva6_input_isa(compiled_isa: str, target: str) -> str:
    validate_target(target)
    parts = compiled_isa.strip().split("_")
    if not parts or not parts[0].startswith("rv32"):
        raise ValueError(f"Invalid compiled ISA: {compiled_isa}")

    filtered = [part for part in parts if part != "zicsr"]
    return "_".join(filtered)


def write_iss_config(source: Path, output: Path, spike_yaml: Path) -> None:
    data = yaml.safe_load(source.read_text(encoding="utf-8"))
    if not isinstance(data, list):
        raise ValueError(f"Expected an ISS list in {source}")

    make_argument = f" spike_yaml={shlex.quote(str(spike_yaml))}"
    patched = 0
    for index, entry in enumerate(data):
        if not isinstance(entry, dict):
            raise ValueError(f"Invalid ISS entry at index {index}")
        if entry.get("iss") in {"spike", "veri-testharness"}:
            command = entry.get("cmd")
            if not isinstance(command, str) or not command.strip():
                raise ValueError(f"Missing command for ISS {entry.get('iss')}")
            if "spike_yaml=" in command:
                raise ValueError(f"ISS {entry.get('iss')} already sets spike_yaml")
            entry["cmd"] = command.rstrip() + make_argument
            patched += 1
    if patched != 2:
        raise ValueError(f"Expected Spike and TestHarness commands, patched {patched}")
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(yaml.safe_dump(data, sort_keys=False), encoding="utf-8")


def precompiled_object_alias(elf_file: Path) -> Path:
    alias = elf_file.with_suffix(".precompiled.o")
    if alias.exists() or alias.is_symlink():
        alias.unlink()
    os.link(elf_file, alias)
    return alias


def preserve_run_log(log: Path, simulation_dir: Path) -> Path:
    destination = simulation_dir / "cook_testharness.log"
    simulation_dir.mkdir(parents=True, exist_ok=True)
    if destination.exists() or destination.is_symlink():
        destination.unlink()
    if log.is_file():
        log.replace(destination)
    return destination


def regression_report_passed(report: Path) -> tuple[bool, str]:
    if not report.is_file():
        return False, f"missing regression report: {report}"

    try:
        report_text = report.read_text(encoding="utf-8")
    except OSError as error:
        return False, f"cannot read regression report: {error}"

    failed_markers = report_text.count("[FAILED]")
    if failed_markers:
        return False, f"{failed_markers} failed comparison(s)"

    matched_counts = [
        int(value)
        for value in re.findall(
            r"\[PASSED\]:\s*([0-9]+)\s+matched\b", report_text
        )
    ]
    if matched_counts and all(count > 0 for count in matched_counts):
        return True, (
            f"{sum(matched_counts)} matched instruction(s) "
            f"across {len(matched_counts)} comparison(s)"
        )
    if matched_counts:
        return False, "regression report contains a zero-match comparison"
    return False, "regression report contains no pass/fail comparison result"


def tandem_log_passed(simulation_dir: Path) -> tuple[bool, str]:
    log_directory = simulation_dir / "veri-testharness_sim"
    logs = sorted(log_directory.glob("*.iss"))
    if len(logs) != 1:
        return False, f"expected one TestHarness ISS log, found {len(logs)}"

    try:
        log_text = logs[0].read_text(encoding="utf-8")
    except OSError as error:
        return False, f"cannot read TestHarness ISS log: {error}"

    failure_markers = (
        "*** FAILED ***",
        "SIMULATION FAILED",
        "[FAILED]",
        "UVM_ERROR",
        "UVM_FATAL",
        "MISMATCH",
    )
    found_failures = [marker for marker in failure_markers if marker in log_text]
    if found_failures:
        return False, "TestHarness failure markers: " + ", ".join(found_failures)

    tandem_markers = (
        "Running binary in tandem mode",
        "spike_tandem Setting up Spike",
    )
    missing_tandem = [marker for marker in tandem_markers if marker not in log_text]
    if missing_tandem:
        return False, "missing live Spike tandem markers"

    if "*** SUCCESS *** (tohost = 0)" not in log_text:
        return False, "missing successful TestHarness tohost result"
    return True, "live Spike tandem completed"


def run_streaming(
    command: list[str],
    cwd: Path,
    env: dict[str, str],
    log: Path,
    quiet: bool = False,
) -> int:
    log.parent.mkdir(parents=True, exist_ok=True)
    with log.open("w", encoding="utf-8") as log_file:
        with subprocess.Popen(
            command,
            cwd=cwd,
            env=env,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1,
            start_new_session=True,
        ) as process:
            try:
                if process.stdout is None:
                    raise RuntimeError("Failed to capture command output")
                for line in process.stdout:
                    if not quiet:
                        print(line, end="")
                    log_file.write(line)
                    log_file.flush()
                return process.wait()
            except KeyboardInterrupt:
                if process.poll() is None:
                    os.killpg(os.getpgid(process.pid), signal.SIGTERM)
                    try:
                        process.wait(timeout=3)
                    except subprocess.TimeoutExpired:
                        os.killpg(os.getpgid(process.pid), signal.SIGKILL)
                raise


def run_compiled_test(
    test: dict[str, Any], iteration: int, context: RunContext
) -> CompiledTestResult:
    compiled_name = f"{test['test']}_{iteration}"
    compile_dir = context.build_root / "compile" / compiled_name
    elf_file = compile_dir / f"{compiled_name}.elf"
    isa_string_file = compile_dir / "isa_string"
    simulation_dir = context.simulation_root / compiled_name
    transient_log = context.simulation_root / f"{compiled_name}.cook_testharness.log"

    compiled_mabi = context.default_mabi

    if not elf_file.is_file() or not isa_string_file.is_file():
        print_error(
            f"Missing cook compilation output for {compiled_name}",
            quiet=context.quiet,
        )
        return CompiledTestResult(compiled_name, "unknown", compiled_mabi, False)

    compiled_isa = "unknown"
    try:
        compiled_isa = isa_string_file.read_text(encoding="utf-8").strip()
        simulation_isa = cva6_input_isa(compiled_isa, context.target)
        elf_alias = precompiled_object_alias(elf_file)
    except (OSError, ValueError) as error:
        print_error(str(error), quiet=context.quiet)
        return CompiledTestResult(compiled_name, compiled_isa, compiled_mabi, False)

    command = [
        sys.executable,
        "cva6.py",
        "--target",
        context.target,
        "--custom_target",
        str(context.target_dir),
        "--isa",
        simulation_isa,
        "--mabi",
        compiled_mabi,
        "--elf_tests",
        str(elf_alias),
        "--iss_yaml",
        str(context.generated_iss_file),
        "--iss",
        context.backend,
        "--iss_timeout",
        str(context.iss_timeout),
        "--issrun_opts=+tb_performance_mode+debug_disable=1+UVM_VERBOSITY=UVM_NONE",
        "--sv_seed",
        context.sv_seed,
        "--priv",
        context.privilege,
        "--output",
        str(simulation_dir),
    ]
    print_step(f"Run {compiled_name}", quiet=context.quiet)
    try:
        return_code = run_streaming(
            command,
            context.repo_dir / "verif" / "sim",
            context.env,
            transient_log,
            quiet=context.quiet,
        )
    except OSError as error:
        print_error(f"{compiled_name}: {error}", quiet=context.quiet)
        return_code = 1
    finally:
        preserve_run_log(transient_log, simulation_dir)

    if return_code == 0:
        if context.tandem_enabled:
            passed, status_detail = tandem_log_passed(simulation_dir)
        else:
            passed, status_detail = regression_report_passed(
                simulation_dir / "iss_regr.log"
            )
    else:
        passed = False
        status_detail = f"cva6.py returned {return_code}"

    if passed:
        print_success(f"{compiled_name}: PASS ({status_detail})", quiet=context.quiet)
    else:
        print_error(f"{compiled_name}: FAIL ({status_detail})", quiet=context.quiet)
    return CompiledTestResult(compiled_name, compiled_isa, compiled_mabi, passed)


@app.command()
def verilator_testharness_run_testlist(
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
        help="Testlist YAML compiled by sw-compile-testlist",
        autocompletion=autocompletion_testlist,
    ),
    test_name: list[str] | None = typer.Option(
        None,
        "--testname",
        "-n",
        help="Run selected enabled tests from the testlist",
        autocompletion=autocompletion_testname_in_testlist,
    ),
    tandem_enabled: bool = typer.Option(
        False,
        "--tandem-enabled/--no-tandem",
        help="Use live Spike tandem mode; otherwise run and compare both backends",
    ),
    iss_timeout: int = typer.Option(
        500, min=1, help="Timeout in seconds for each ISS/TestHarness execution"
    ),
    sv_seed: str = typer.Option(
        "1", "--seed", "--sv-seed", help="Deterministic TestHarness seed"
    ),
    quiet: bool = typer.Option(
        False, "--quiet", "-q", help="Suppress command output and summaries"
    ),
) -> None:
    """Run Cook ELF testlists with Verilator TestHarness and Spike."""
    print_recipe_title("VERILATOR TESTHARNESS TESTLIST", quiet=quiet)

    try:
        validate_target(target)
    except ValueError as error:
        print_error(str(error), quiet=quiet)
        raise typer.Exit(code=1) from error

    print_param_table(
        {
            "Target": target,
            "Testlist": testlist,
            "Selected tests": test_name or "all enabled tests",
            "Tandem enabled": tandem_enabled,
            "ISS timeout (seconds)": iss_timeout,
            "Simulation seed": sv_seed,
        },
        "Options",
        quiet=quiet,
    )

    repo_dir = Path.cwd().resolve()
    target_dir = repo_dir / "config" / "target" / target
    testlist_file = (repo_dir / testlist).resolve()
    isa_file = target_dir / "isa.yml"
    spike_file = target_dir / "spike.yaml"
    source_iss_file = repo_dir / "verif" / "sim" / "cva6.yaml"
    required = [testlist_file, isa_file, spike_file, source_iss_file]
    missing = [str(path) for path in required if not path.is_file()]
    if missing:
        for path in missing:
            print_error(f"Missing required file: {path}", quiet=quiet)
        raise typer.Exit(code=1)

    try:
        testlist_data = yaml.safe_load(testlist_file.read_text(encoding="utf-8"))
        isa_data = yaml.safe_load(isa_file.read_text(encoding="utf-8"))
        spike_data = yaml.safe_load(spike_file.read_text(encoding="utf-8"))
        if not isinstance(testlist_data, dict):
            raise ValueError(f"Expected a mapping in {testlist_file}")
        if not isinstance(isa_data, dict):
            raise ValueError(f"Expected a mapping in {isa_file}")
        if not isinstance(spike_data, dict):
            raise ValueError(f"Expected a mapping in {spike_file}")
        default_mabi = isa_data.get("mabi")
        if not isinstance(default_mabi, str) or not default_mabi:
            raise ValueError(f"Missing mabi in {isa_file}")
        tests = enabled_tests(testlist_data, test_name)
    except (OSError, TypeError, ValueError, yaml.YAMLError) as error:
        print_error(str(error), quiet=quiet)
        raise typer.Exit(code=1) from error

    if not tests:
        print_error("No enabled tests selected", quiet=quiet)
        raise typer.Exit(code=1)

    build_root = repo_dir / "build" / target
    simulation_root = build_root / "simulation" / "sim_verilator_testharness"
    generated_iss_file = build_root / "config" / "verilator_testharness_cva6.yaml"
    try:
        write_iss_config(source_iss_file, generated_iss_file, spike_file)
    except (OSError, ValueError, yaml.YAMLError) as error:
        print_error(str(error), quiet=quiet)
        raise typer.Exit(code=1) from error

    result_metric = TableStatusMetric("Verilator TestHarness test results")
    result_metric.add_column("Target", "text")
    result_metric.add_column("Test", "text")
    result_metric.add_column("Compiler ISA", "text")
    result_metric.add_column("ABI", "text")
    result_metric.add_column("Backend", "text")

    spike_parameters = spike_data.get("spike_param_tree", {})
    if not isinstance(spike_parameters, dict):
        print_error(f"Invalid spike_param_tree in {spike_file}", quiet=quiet)
        raise typer.Exit(code=1)
    privilege_value = spike_parameters.get("priv", "MSU")
    if not isinstance(privilege_value, str) or not privilege_value:
        print_error(f"Invalid privilege mode in {spike_file}", quiet=quiet)
        raise typer.Exit(code=1)
    privilege = privilege_value.lower()
    env = os.environ.copy()
    if tandem_enabled:
        env["SPIKE_TANDEM"] = "1"
    else:
        env.pop("SPIKE_TANDEM", None)

    context = RunContext(
        repo_dir=repo_dir,
        target=target,
        target_dir=target_dir,
        build_root=build_root,
        simulation_root=simulation_root,
        generated_iss_file=generated_iss_file,
        default_mabi=default_mabi,
        privilege=privilege,
        backend=TANDEM_BACKEND if tandem_enabled else COMPARE_BACKEND,
        tandem_enabled=tandem_enabled,
        env=env,
        iss_timeout=iss_timeout,
        sv_seed=sv_seed,
        quiet=quiet,
    )

    failed = False
    for test in tests:
        for iteration in range(int(test.get("iterations", 1))):
            result = run_compiled_test(test, iteration, context)
            result_row = (
                target,
                result.name,
                result.compiler_isa,
                result.mabi,
                context.backend,
            )
            if result.passed:
                result_metric.add_pass(*result_row)
            else:
                result_metric.add_fail(*result_row)
                failed = True

    report = Report()
    report.add_metric(result_metric)
    report_path = (
        repo_dir
        / "artifacts"
        / "reports"
        / f"report_verilator_testharness_{target}_{testlist_file.stem}.yml"
    )
    report.dump(str(report_path.relative_to(repo_dir)))
    print_recipe_end("Completed", quiet=quiet)

    if failed:
        raise typer.Exit(code=1)
