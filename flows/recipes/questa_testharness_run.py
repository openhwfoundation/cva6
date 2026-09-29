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
Run one test on the TestHarness testbench with Questa.

The harness prints its verdict rather than returning it: `ariane_tb`
reports `*** FAILED ***` through uvm_error and ends with $finish, so vsim
exits 0 whatever the program did. The log is what says whether the test
passed.
"""

from pathlib import Path
import re
import shutil
import stat

import typer

from flows.utils.autocompletion import (
    CompMode,
    TraceMode,
    UvmVerbosity,
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
from flows.utils.recipe_report import RecipeReport
from flows.utils.run_cmd import run_cmd

app = typer.Typer()

# Wall clock limit of one run. The harness stops on tohost; a test that
# derails never writes it and would otherwise hold the pipeline.
SIMULATION_TIMEOUT = 500


# ==========================================================
# RECIPE
# ==========================================================


@app.command()
def questa_testharness_run(
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
        TraceMode.notrace, help="notrace, or any other value to keep the signals"
    ),
    uvm_verbosity: UvmVerbosity = typer.Option(
        # LOW rather than NONE: the harness reports its verdict with
        # `uvm_info(..., UVM_LOW)`, and NONE drops the line it is read from.
        UvmVerbosity.low,
        help="UVM verbosity of the run",
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
    Run one test on the TestHarness testbench with Questa
    """
    report = RecipeReport(
        "questa-testharness-run",
        title="QUESTA TESTHARNESS RUN",
        context={
            "target": target,
            "test_name": test_name,
            "comp_mode": comp_mode,
            "trace_mode": trace_mode,
            "uvm_verbosity": uvm_verbosity,
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

    vsim_path = shutil.which("vsim")
    if vsim_path is not None:
        report.success(f"vsim: {vsim_path}")
    else:
        report.error_exit("vsim: Not found", env=True)
    # Not resolve(): the install is reached through a symlink whose target
    # holds the binaries but not the UVM tree
    questasim_home = Path(vsim_path).parent.parent

    repo_dir = Path.cwd()
    build_root = repo_dir / "build" / target
    compile_dir = build_root / "compile" / test_name
    elab_dir = build_root / "elab" / "sim_rtl_questa_testharness"
    # Named after the run rather than the test, so running the same test
    # twice on one elaboration keeps both outputs and both reports.
    simulation_dir = (
        build_root
        / "simulation"
        / "sim_rtl_questa_testharness"
        / (run_name or test_name)
    )
    report.set_out_dir(simulation_dir)

    spike_lib = repo_dir / "tools" / "spike" / "lib"
    spike_dasm = repo_dir / "tools" / "spike" / "bin" / "spike-dasm"
    elf = compile_dir / f"{test_name}.elf"
    design = elab_dir / "work" / "ariane_tb_opt"
    # The Spike configuration of the target, the one vcs-uvm-run passes:
    # the harness reads the ISA of the target from it
    spike_yaml = repo_dir / "config" / "target" / target / "spike.yaml"

    # ==========================================================
    # CHECK PREREQUISITES
    # ==========================================================
    report.step("Check prerequisites")

    require_prerequisite(
        elf,
        f"compiled software for test '{test_name}'",
        f"./cook.py sw-compile -t {target} -c <toolchain> --out {test_name} <sources>",
        report=report,
    )

    require_prerequisite(
        design,
        "TestHarness elaborated with Questa",
        f"./cook.py questa-testharness-comp -t {target}",
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
            f"trace mode '{trace_mode.value}' requires a matching elaboration",
            f"./cook.py questa-testharness-comp -t {target} "
            f"--trace-mode {trace_mode.value}",
            report=report,
            manifest_dir=elab_dir,
        )
    if not spike_yaml.is_file():
        report.error_exit(f"Missing {spike_yaml}", env=True)

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

    # Symbol address extracted at compile time (sw-compile manifest):
    # tohost drives the end-of-test detection
    symbols = get_manifest_option(compile_manifest, "symbols", {})
    add_tohost = symbols.get("tohost")
    if add_tohost is None:
        report.error_exit(
            f"No tohost symbol recorded in the sw-compile manifest of {compile_dir}",
            env=True,
        )

    # ==========================================================
    # BUILD VSIM COMMAND
    # ==========================================================
    # The plusargs of `COMMON_RUN_ARGS` in verif/sim/Makefile.
    vsim_cmd = [
        "vsim",
        "-64",
        "-c",
        # Questa puts its own gcc runtime ahead of everything on the
        # loader path, older than the one the Spike libraries were built
        # against: without this they fail to load on a missing GLIBCXX.
        "-noautoldlibpath",
        "-t",
        "1ns",
        # The library sits in the elaboration directory, the results in
        # the run one: named rather than moved to, so that a design serves
        # any number of tests.
        "-lib",
        str(elab_dir / "work"),
        # -c runs without the interface and `-do` drives it to the end,
        # vsim otherwise stopping at its prompt. `-onfinish stop` keeps
        # $finish from closing the tool before `quit` reports.
        "-onfinish",
        "stop",
        "-do",
        "run -all; quit -f",
        # The HTIF of Spike walks the argv of vsim and rejects what it
        # does not know, `-64` included: `+permissive` makes it skip those,
        # and `++` marks the ELF as the program to load. The window is left
        # open: closing it with `+permissive-off` brings the rejection back.
        "+permissive",
        f"++{elf}",
        f"+elf_file={elf}",
        f"+core_name={target}",
        f"+config_file={spike_yaml}",
        f"+tohost_addr={add_tohost}",
        f"+signature={elf}.signature_output",
        "+UVM_TESTNAME=uvmt_cva6_firmware_test_c",
        # Nothing drives the debug module: left enabled, the SimDTM of the
        # harness halts a core built with DebugEn into its debug ROM
        # 500 cycles after reset, and the program crawls through it.
        "+debug_disable=1",
        f"+report_file={simulation_dir / 'report.yaml'}",
        f"+UVM_VERBOSITY=UVM_{uvm_verbosity.value}",
        # uvm_dpi first: the UVM of Questa imports its command line and its
        # regexps from there, and faults on a null function pointer without
        # it. The Spike libraries follow, in dependency order.
        "-sv_lib",
        str(questasim_home / "uvm-1.2" / "linux_x86_64" / "uvm_dpi"),
        "-sv_lib",
        f"{spike_lib}/libcustomext",
        "-sv_lib",
        f"{spike_lib}/libyaml-cpp",
        "-sv_lib",
        f"{spike_lib}/libriscv",
        "-sv_lib",
        f"{spike_lib}/libfesvr",
        "-sv_lib",
        f"{spike_lib}/libdisasm",
        "ariane_tb_opt",
    ]

    # ==========================================================
    # LAUNCH SIMULATION
    # ==========================================================
    report.step("LAUNCH SIMULATION")

    log_file = simulation_dir / "testharness.log"
    raw_trace = simulation_dir / "trace_rvfi_hart_00.dasm"
    dasm_log = simulation_dir / "spike_dasm.log"

    failed_before = report.failed
    run_cmd(
        cmd=vsim_cmd,
        report=report,
        cwd=simulation_dir,
        env={"QUESTASIM_HOME": str(questasim_home)},
        error_patterns=[
            r"(\*\*\* FAILED \*\*\*|^\*\* Error|^# \*\* Error|UVM_ERROR|UVM_FATAL|Fatal)"
        ],
        warning_patterns=[r"(^\*\* Warning|^# \*\* Warning|UVM_WARNING)"],
        highlight_patterns=[r"\*\*\* SUCCESS \*\*\*"],
        log_file=log_file,
        timeout=sim_timeout,
    )
    run_failed = report.failed and not failed_before

    # ==========================================================
    # VERDICT
    # ==========================================================
    # A failing program is only in the log: vsim exits 0 on $finish. A
    # timeout or a crash is recorded by run_cmd, and leaves the log cut.
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
        # The cycle count the rvfi_tracer prints at the end of the run, the
        # label the dashboard shows as for the UVM runs
        cycles = re.search(r"Simulation terminated after\s+(\d+) cycles", text)
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
        "questa-testharness-run",
        {
            "target": target,
            "test_name": test_name,
            "comp_mode": comp_mode,
            "trace_mode": trace_mode,
            "uvm_verbosity": uvm_verbosity,
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
