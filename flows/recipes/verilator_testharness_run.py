# Copyright 2026 OpenHW Foundation
#
# Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
# You may obtain a copy of the License at https://solderpad.org/licenses/
#
# Original Author: Junchao Chen (junchao.chen@eclipse-foundation.org)

# Please refer to flows/README.md to add target

"""
Run one test on the Verilator TestHarness.

The harness prints its verdict rather than returning it: the simulation
exits 0 whatever the program did, so the log is what says whether the
test passed.
"""

import os
from pathlib import Path
import re
import shutil
import stat

import typer

from flows.utils.autocompletion import (
    CompMode,
    TraceMode,
    autocompletion_target,
    autocompletion_testname_compiled,
)
from flows.utils.manifest import (
    MANIFEST_NAME,
    get_manifest_option,
    read_manifest,
    require_manifest_option,
    require_prerequisite,
    write_manifest,
)
from flows.utils.recipe_report import RecipeReport
from flows.utils.run_cmd import run_cmd
from flows.recipes.verilator_testharness_comp import (
    build_directory,
    check_target,
    elaboration_directory,
    testharness_binary,
)

app = typer.Typer()

SIMULATION_TIMEOUT = 500


def validate_path_component(value: str, label: str) -> str:
    if value in {"", ".", ".."} or Path(value).name != value:
        raise ValueError(f"Invalid {label}: {value}")
    return value


def check_run_options(
    comp_mode: CompMode, trace_mode: TraceMode, interactive_gui: bool, report
) -> None:
    "Stop on an option the Verilator harness does not implement"
    if comp_mode != CompMode.rtl:
        report.error_exit(
            f"Verilator TestHarness supports only the rtl compilation mode, "
            f"got {comp_mode.value}",
            env=True,
        )
    if trace_mode == TraceMode.gui or interactive_gui:
        report.error_exit("Verilator TestHarness has no interactive GUI mode", env=True)


def simulation_directory(
    repo_dir: Path, target: str, test_name: str, comp_mode: CompMode, run_name=None
) -> Path:
    "Return the output directory of a run, named after it rather than the test"
    target = validate_path_component(target, "target name")
    name = validate_path_component(run_name or test_name, "run name")
    return build_directory(
        repo_dir,
        target,
        "simulation",
        f"sim_{comp_mode.value}_verilator_testharness",
        name,
    )


def testharness_log_passed(log: Path) -> tuple[bool, str]:
    if not log.is_file():
        return False, f"missing TestHarness log: {log}"
    try:
        text = log.read_text(encoding="utf-8")
    except (OSError, UnicodeError) as error:
        return False, f"cannot read TestHarness log: {error}"

    failure_markers = (
        "*** FAILED ***",
        "SIMULATION FAILED",
        "[FAILED]",
        "UVM_ERROR",
        "UVM_FATAL",
    )
    failures = [marker for marker in failure_markers if marker in text]
    if failures:
        return False, "failure marker(s): " + ", ".join(failures)
    if "*** SUCCESS *** (tohost = 0)" not in text:
        return False, "missing successful TestHarness tohost result"
    return True, "TestHarness completed"


def runtime_environment(repo_dir: Path, target: str, report) -> tuple[dict, Path]:
    """
    Return the environment the harness runs with, and the Spike prefix.

    The binary is linked against the Spike and toolchain libraries but
    carries no rpath for them, so they have to be on LD_LIBRARY_PATH.
    SPIKE_TANDEM is dropped: it makes the harness expect a reference model
    this recipe does not run.
    """
    riscv_env = os.environ.get("RISCV")
    if not riscv_env:
        report.error_exit("RISCV is not set (see setenv.sh)", env=True)
    riscv = Path(riscv_env).resolve()
    spike = Path(
        os.environ.get("SPIKE_INSTALL_DIR", repo_dir / "tools" / "spike")
    ).resolve()

    libraries = [str(spike / "lib"), str(riscv / "lib")]
    if os.environ.get("LD_LIBRARY_PATH"):
        libraries.append(os.environ["LD_LIBRARY_PATH"])
    env = {
        "LD_LIBRARY_PATH": os.pathsep.join(libraries),
        "CVA6_REPO_DIR": str(repo_dir),
        "TARGET_CFG": target,
        "SPIKE_INSTALL_DIR": str(spike),
        "SPIKE_TANDEM": "",
    }
    return env, spike


def testharness_command(
    binary: Path,
    elf: Path,
    *,
    target: str,
    tohost: str,
    trace_mode: TraceMode,
) -> list[str]:
    command = [str(binary)]
    if trace_mode == TraceMode.fast:
        command.extend(("--vcd", "verilator.vcd"))
    elif trace_mode == TraceMode.compact:
        command.extend(("--fst", "verilator.fst"))
    elif trace_mode != TraceMode.notrace:
        raise ValueError(f"Unsupported Verilator trace mode: {trace_mode.value}")
    command.extend(("--seed", "1", str(elf)))
    command.extend(
        (
            "+tb_performance_mode",
            "+debug_disable=1",
            "+UVM_VERBOSITY=UVM_NONE",
            f"++{elf}",
            f"+elf_file={elf}",
            f"+core_name={target}",
            "+signature=signature_output",
            "+UVM_TESTNAME=uvmt_cva6_firmware_test_c",
            "+report_file=testharness.log.yaml",
            f"+tohost_addr={tohost}",
        )
    )
    return command


def check_manifests(
    *,
    target: str,
    test_name: str,
    comp_mode: CompMode,
    trace_mode: TraceMode,
    compile_dir: Path,
    elab_dir: Path,
    report,
) -> None:
    "Refuse a binary built for another target, test or trace mode"
    software = read_manifest(compile_dir, report)
    hint_sw = (
        f"./cook.py sw-compile -t {target} -c <toolchain> --out {test_name} <sources>"
    )
    require_manifest_option(
        software,
        "target",
        [target],
        "compiled software target does not match the requested target",
        hint_sw,
        report,
        manifest_dir=compile_dir,
    )
    require_manifest_option(
        software,
        "test_name",
        [test_name],
        "compiled software name does not match the requested test",
        hint_sw,
        report,
        manifest_dir=compile_dir,
    )

    hardware = read_manifest(elab_dir, report)
    hint_hw = f"./cook.py verilator-testharness-comp -t {target}"
    if hardware and hardware.get("recipe") != "verilator-testharness-comp":
        report.error_exit(
            f"{elab_dir} was produced by {hardware.get('recipe')!r}, not by "
            f"verilator-testharness-comp\n  Fix: {hint_hw}",
            env=True,
        )
    require_manifest_option(
        hardware,
        "target",
        [target],
        "TestHarness target does not match the requested target",
        hint_hw,
        report,
        manifest_dir=elab_dir,
    )
    require_manifest_option(
        hardware,
        "comp_mode",
        [comp_mode.value],
        "TestHarness compilation mode does not match the requested mode",
        f"{hint_hw} --comp-mode {comp_mode.value}",
        report,
        manifest_dir=elab_dir,
    )
    if trace_mode != TraceMode.notrace:
        require_manifest_option(
            hardware,
            "trace_mode",
            [trace_mode.value],
            f"trace mode {trace_mode.value!r} requires a matching TestHarness build",
            f"{hint_hw} --trace-mode {trace_mode.value}",
            report,
            manifest_dir=elab_dir,
        )


@app.command()
def verilator_testharness_run(
    target: str = typer.Option(
        ...,
        "--target",
        "-t",
        help="CVA6 user configuration",
        autocompletion=autocompletion_target,
    ),
    test_name: str = typer.Option(
        ...,
        "--testname",
        "-n",
        help="Cook-compiled test name",
        autocompletion=autocompletion_testname_compiled,
    ),
    comp_mode: CompMode = typer.Option(
        CompMode.rtl, help="Compilation mode; only rtl is supported"
    ),
    trace_mode: TraceMode = typer.Option(
        TraceMode.notrace,
        help="notrace, fast (VCD), or compact (FST); must match the build",
    ),
    interactive_gui: bool = typer.Option(
        False, help="Interactive GUI is currently unsupported"
    ),
    sim_timeout: int = typer.Option(
        SIMULATION_TIMEOUT, "--sim-timeout", help="Simulation timeout in seconds"
    ),
    run_name: str = typer.Option(
        None,
        "--run-name",
        help="Name of the output directory, when the same test is run more "
        "than once on the same design (default: the test name)",
    ),
    quiet: bool = typer.Option(
        False, "--quiet", "-q", help="Suppress output (errors only)"
    ),
) -> None:
    """
    Run one test on the Verilator TestHarness
    """
    repo_dir = Path.cwd().resolve()
    output_dir = simulation_directory(repo_dir, target, test_name, comp_mode, run_name)
    report = RecipeReport(
        "verilator-testharness-run",
        out_dir=output_dir,
        title="VERILATOR TESTHARNESS RUN",
        context={
            "target": target,
            "test_name": test_name,
            "comp_mode": comp_mode.value,
            "trace_mode": trace_mode.value,
            "interactive_gui": interactive_gui,
            "run_name": run_name,
        },
        quiet=quiet,
    )

    report.step("Check prerequisites")
    check_run_options(comp_mode, trace_mode, interactive_gui, report)
    check_target(target, report)

    compile_dir = build_directory(repo_dir, target, "compile", test_name)
    elab_dir = elaboration_directory(repo_dir, target, comp_mode)
    elf = compile_dir / f"{test_name}.elf"
    binary = testharness_binary(repo_dir, target, comp_mode)

    hint_sw = (
        f"./cook.py sw-compile -t {target} -c <toolchain> --out {test_name} <sources>"
    )
    require_prerequisite(
        elf, f"compiled software for test '{test_name}'", hint_sw, report
    )
    require_prerequisite(
        binary,
        f"Verilator TestHarness (comp mode '{comp_mode.value}')",
        f"./cook.py verilator-testharness-comp -t {target} --comp-mode {comp_mode.value}",
        report,
    )
    check_manifests(
        target=target,
        test_name=test_name,
        comp_mode=comp_mode,
        trace_mode=trace_mode,
        compile_dir=compile_dir,
        elab_dir=elab_dir,
        report=report,
    )

    # Recorded by sw-compile rather than kept in files of their own: the
    # ISA the trace is disassembled with is the one the test was built for.
    software = read_manifest(compile_dir, report)
    compiler_isa = get_manifest_option(software, "march")
    if not compiler_isa:
        report.error_exit(
            f"No march in the sw-compile manifest of {compile_dir}", env=True
        )
    tohost = str(get_manifest_option(software, "symbols", {}).get("tohost", ""))
    # A zero tohost means the linker did not place the symbol: the harness
    # would run to the timeout instead of stopping on the test verdict.
    if not re.fullmatch(r"(?:0[xX])?[0-9a-fA-F]+", tohost) or int(tohost, 16) == 0:
        report.error_exit(
            f"Invalid or zero tohost address in the sw-compile manifest of "
            f"{compile_dir}: {tohost!r}",
            env=True,
        )

    env, spike_install = runtime_environment(repo_dir, target, report)
    report.success("Prerequisites OK")

    report.step("Clean")
    try:
        if output_dir.exists():
            shutil.rmtree(output_dir)
        output_dir.mkdir(parents=True)
        report.info(f"create {output_dir}")
    except OSError as e:
        report.error_exit(f"Clean error: {e}", env=True)

    report.step(f"Run {test_name}")
    log_file = output_dir / "testharness.log"
    run_cmd(
        cmd=testharness_command(
            binary, elf, target=target, tohost=tohost, trace_mode=trace_mode
        ),
        report=report,
        cwd=output_dir,
        env=env,
        log_file=log_file,
        timeout=sim_timeout,
    )

    # The harness exits 0 whatever the program did, so the verdict is in
    # the log: a test that never reached tohost looks like a clean run.
    passed, detail = testharness_log_passed(log_file)
    if passed:
        report.success(f"{test_name}: {detail}")
    else:
        report.error(f"{test_name}: {detail}")

    report.step("Disassemble the trace")
    raw_trace = output_dir / "trace_rvfi_hart_00.dasm"
    if not raw_trace.exists():
        report.info(f"{raw_trace.name} not produced, nothing to disassemble")
    elif not stat.S_ISREG(raw_trace.lstat().st_mode):
        report.error(f"Raw trace is not a regular file: {raw_trace}")
    else:
        with raw_trace.open("rb") as source:
            run_cmd(
                cmd=[
                    str(spike_install / "bin" / "spike-dasm"),
                    f"--isa={compiler_isa}",
                ],
                report=report,
                cwd=output_dir,
                env=env,
                stdin=source,
                log_file=output_dir / "spike_dasm.log",
                timeout=min(sim_timeout, 120),
                check=False,
            )

    write_manifest(
        output_dir,
        "verilator-testharness-run",
        {
            "target": target,
            "test_name": test_name,
            "comp_mode": comp_mode,
            "trace_mode": trace_mode,
            "interactive_gui": interactive_gui,
            "run_name": run_name,
        },
        report,
    )

    report.step("Generated files")
    for path in (log_file, raw_trace, output_dir / MANIFEST_NAME):
        if path.exists():
            report.info(f"> {path}")

    report.end()
