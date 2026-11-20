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
    get_manifest_option,
    read_manifest,
    require_manifest_option,
    require_prerequisite,
    write_manifest,
)
from flows.utils.pk_run import HarnessProgram
from flows.utils.recipe_report import RecipeReport
from flows.utils.run_cmd import run_cmd
from flows.utils.target_config import spike_core_name

app = typer.Typer()

# Wall clock limit of one run. The harness stops on tohost; a test that
# derails never writes it and would otherwise hold the pipeline.
SIMULATION_TIMEOUT = 500


# ==========================================================
# RECIPE
# ==========================================================


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
):
    """
    Run one test on the Verilator TestHarness
    """
    report = RecipeReport(
        "verilator-testharness-run",
        title="VERILATOR TESTHARNESS RUN",
        context={
            "target": target,
            "test_name": test_name,
            "comp_mode": comp_mode,
            "trace_mode": trace_mode,
            "interactive_gui": interactive_gui,
            "sim_timeout": sim_timeout,
            "run_name": run_name,
        },
        quiet=quiet,
    )

    if comp_mode != CompMode.rtl:
        report.error_exit(
            f"The TestHarness supports only the rtl compilation mode, got "
            f"{comp_mode.value}",
            env=True,
        )
    if trace_mode == TraceMode.gui or interactive_gui:
        report.error_exit("The Verilator TestHarness has no GUI mode", env=True)

    # Create files and folder paths
    repo_dir = Path.cwd()
    build_root = repo_dir / "build" / target
    compile_dir = build_root / "compile" / test_name
    elab_dir = build_root / "elab" / "sim_rtl_verilator_testharness"
    # Named after the run rather than the test, so running the same test
    # twice on one elaboration keeps both outputs and both reports.
    simulation_dir = (
        build_root
        / "simulation"
        / "sim_rtl_verilator_testharness"
        / (run_name or test_name)
    )
    report.set_out_dir(simulation_dir)

    spike_dir = repo_dir / "tools" / "spike"
    spike_dasm = spike_dir / "bin" / "spike-dasm"
    elf = compile_dir / f"{test_name}.elf"
    binary = elab_dir / "Variane_testharness"

    # ==========================================================
    # CHECK PREREQUISITES
    # ==========================================================
    report.step("Check prerequisites")

    # Software must be compiled first
    require_prerequisite(
        elf,
        f"compiled software for test '{test_name}'",
        f"./cook.py sw-compile -t {target} -c <toolchain> --out {test_name} <sources>",
        report=report,
    )

    # Hardware must be elaborated first
    require_prerequisite(
        binary,
        "Verilator TestHarness",
        f"./cook.py verilator-testharness-comp -t {target}",
        report=report,
    )

    # Options must be compatible with how the design was elaborated
    elab_manifest = read_manifest(elab_dir, report)
    compile_manifest = read_manifest(compile_dir, report)
    if trace_mode != TraceMode.notrace:
        require_manifest_option(
            elab_manifest,
            "trace_mode",
            [trace_mode.value],
            f"trace mode '{trace_mode.value}' requires a matching TestHarness build",
            f"./cook.py verilator-testharness-comp -t {target} "
            f"--trace-mode {trace_mode.value}",
            report=report,
            manifest_dir=elab_dir,
        )

    report.success("Prerequisites OK")

    # ==========================================================
    # CLEAN
    # ==========================================================
    report.step("Clean")
    try:
        if simulation_dir.exists():
            shutil.rmtree(simulation_dir)
            report.info(f"remove {simulation_dir}")
    except Exception as e:
        report.error_exit(f"Clean error : {e}", env=True)

    simulation_dir.mkdir(parents=True, exist_ok=True)
    report.info(f"create {simulation_dir}")

    # ==========================================================
    # OPTIONS
    # ==========================================================

    # Program loaded by the harness, and the tohost that ends the test:
    # the ones of the proxy kernel for a test built to run under it
    program = HarnessProgram(
        compile_dir, test_name, compile_manifest, report, pk_supported=True
    )

    options = []
    if trace_mode == TraceMode.fast:
        options += ["--vcd", "verilator.vcd"]
    elif trace_mode == TraceMode.compact:
        options += ["--fst", "verilator.fst"]

    # ==========================================================
    # BUILD SIMULATION COMMAND
    # ==========================================================
    sim_cmd = [str(binary)] + options
    sim_cmd += [
        "--seed",
        "1",
        *program.run_plusargs(),
        *program.htif_args(),
        "+tb_performance_mode",
        "+UVM_VERBOSITY=UVM_NONE",
        f"+elf_file={program.binary}",
        f"+core_name={spike_core_name(target, report)}",
        "+signature=signature_output",
        "+UVM_TESTNAME=uvmt_cva6_firmware_test_c",
        "+report_file=testharness.log.yaml",
        f"+tohost_addr={program.tohost}",
    ]

    # ==========================================================
    # LAUNCH SIMULATION
    # ==========================================================
    report.step("LAUNCH SIMULATION")

    log_file = simulation_dir / "testharness.log"
    raw_trace = simulation_dir / "trace_rvfi_hart_00.dasm"
    dasm_log = simulation_dir / "spike_dasm.log"

    # The driver returns the tohost value of the program: run_cmd records a
    # non-zero exit code, like a timeout, as a failure of the run.
    failed_before = report.failed
    run_cmd(
        cmd=sim_cmd,
        report=report,
        cwd=simulation_dir,
        error_patterns=[r"(\*\*\* FAILED \*\*\*|^%Error|terminate called)"],
        warning_patterns=[r"(^%Warning)"],
        highlight_patterns=[r"\*\*\* SUCCESS \*\*\*"],
        log_file=log_file,
        timeout=sim_timeout,
    )
    run_failed = report.failed and not failed_before

    # ==========================================================
    # VERDICT
    # ==========================================================
    # The driver prints `*** SUCCESS ***` or `*** FAILED *** (tohost = N)`,
    # but the log alone is not the verdict: on SIGTERM, which is how a
    # timeout ends the run, the driver stops the DTM and prints SUCCESS
    # with an exit code of 0. The failure recorded by run_cmd comes first.
    # Named after the test: the GitHub smoke reads the verdict of this step
    report.step(f"Run {test_name}")
    passed = False
    text = log_file.read_text(encoding="utf-8", errors="replace")
    failures = [
        marker
        for marker in (
            "*** FAILED ***",
            "SIMULATION FAILED",
            "[FAILED]",
            "UVM_ERROR",
            "UVM_FATAL",
        )
        if marker in text
    ]
    if failures:
        report.error(f"{test_name}: failure marker(s): " + ", ".join(failures))
    elif run_failed:
        report.error(f"{test_name}: the run did not complete, see above")
    elif "*** SUCCESS *** (tohost = 0)" not in text:
        report.error(f"{test_name}: missing successful TestHarness tohost result")
    else:
        passed = True
        report.success(f"{test_name}: TestHarness completed")
        # The cycle count the driver prints with its verdict, the label
        # the dashboard shows as for the UVM runs
        cycles = re.search(r"\*\*\* SUCCESS \*\*\*.* after (\d+) cycles", text)
        if cycles:
            report.set_label(f"{int(cycles.group(1)) / 1000:.2f} kCycles")

    # ==========================================================
    # DISASSEMBLE RVFI TRACE
    # ==========================================================
    # Only on a passing run: a failing one is already reported, and its
    # trace may be cut. A missing trace is skipped, but a path that is
    # not a regular file is not followed.
    report.step("Disassemble rvfi trace")
    if not passed:
        report.info("Skipped: the simulation did not pass")
    elif not raw_trace.exists() and not raw_trace.is_symlink():
        report.info(f"Skipped: {raw_trace.name} not produced")
    elif not stat.S_ISREG(raw_trace.lstat().st_mode):
        report.error(f"Raw trace is not a regular file: {raw_trace}")
    else:
        with raw_trace.open("rb") as source:
            run_cmd(
                cmd=[
                    str(spike_dasm),
                    f"--isa={get_manifest_option(compile_manifest, 'march')}",
                ],
                report=report,
                cwd=simulation_dir,
                stdin=source,
                log_file=dasm_log,
                timeout=120,
            )

    # ==========================================================
    # BUILD MANIFEST
    # ==========================================================
    write_manifest(
        simulation_dir,
        "verilator-testharness-run",
        {
            "target": target,
            "test_name": test_name,
            "comp_mode": comp_mode,
            "trace_mode": trace_mode,
            "interactive_gui": interactive_gui,
            "run_name": run_name,
        },
        report=report,
    )

    # ==========================================================
    # List
    # ==========================================================
    report.step("Generated files")
    generated = []
    for genfile in [log_file, raw_trace, dasm_log]:
        if genfile.exists():
            report.info(f"> {genfile}")
            generated.append(str(genfile.relative_to(repo_dir)))
    report.log("Generated files", generated)

    report.end("Completed")
