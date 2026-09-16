# Copyright 2026 Thales France
#
# Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
# You may obtain a copy of the License at https://solderpad.org/licenses/
#
# Original Author: Yannick Casamatta (yannick.casamatta@thalesgroup.com)

# Please refer to flows/README.md to add target

from pathlib import Path
import glob
import shutil
import re
import importlib.util
import sys
import random
import typer
from flows.utils.manifest import (
    write_manifest,
    read_manifest,
    require_prerequisite,
    require_manifest_option,
    get_manifest_option,
)
from flows.utils.recipe_report import RecipeReport
from flows.utils.run_cmd import run_cmd
from flows.utils.rvfi_timing import extract_rvfi_timing, benchmark_window
from flows.utils.tandem import check_tandem_verdict, spike_broken_extensions
from flows.utils.autocompletion import (
    CompMode,
    TraceMode,
    UvmVerbosity,
    autocompletion_target,
    autocompletion_testname_compiled,
)

app = typer.Typer()


# ==========================================================
# RECIPE
# ==========================================================


@app.command()
def xcelium_uvm_run(
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
        help="Test name (compiled from list or not)",
        autocompletion=autocompletion_testname_compiled,
    ),
    comp_mode: CompMode = typer.Option(CompMode.rtl, help="Hardware compilation mode"),
    trace_mode: TraceMode = typer.Option(TraceMode.notrace, help="Trace mode"),
    uvm_verbosity: UvmVerbosity = typer.Option(UvmVerbosity.none, help="UVM verbosity"),
    tandem_enabled: bool = typer.Option(False, help="Enable spike tandem"),
    tb_performance_mode: bool = typer.Option(False, help="Enable tb perf mode"),
    stats: bool = typer.Option(False, help="Enable RTL perf tracer"),
    interactive_gui: bool = typer.Option(
        False, help="Launch GUI for interactive simulation"
    ),
    run_opts: list[str] = typer.Option([], "--run_opts", help="Simulation run options"),
    uvm_seed: str = typer.Option(
        default=str(random.getrandbits(31)), help="Randomize UVM seed"
    ),
    sim_timeout: int = typer.Option(
        3000, "--sim-timeout", help="Simulation timeout in seconds"
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
    Xcelium UVM run simulation flow
    """

    report = RecipeReport(
        "xcelium-uvm-run",
        title="XCELIUM DESIGN RUN SIMULATION",
        context={
            "target": target,
            "test_name": test_name,
            "comp_mode": comp_mode,
            "trace_mode": trace_mode,
            "uvm_verbosity": uvm_verbosity,
            "tandem_enabled": tandem_enabled,
            "tb_performance_mode": tb_performance_mode,
            "stats": stats,
            "interactive_gui": interactive_gui,
            "run_opts": run_opts,
            "uvm_seed": uvm_seed,
            "run_name": run_name,
            "sim_timeout": sim_timeout,
        },
        quiet=quiet,
    )

    # Test tools in path
    xrun_path = shutil.which("xrun")
    if xrun_path is not None:
        report.success(f"xrun: {xrun_path}")
    else:
        report.error_exit("xrun: Not found", env=True)

    # Mode dir
    if comp_mode == CompMode.rtl:
        inout_dir = "sim_rtl"
    elif comp_mode == CompMode.coverage:
        inout_dir = "sim_cov"
    elif comp_mode == CompMode.gate_wc_timing:
        inout_dir = "sim_gate_wc_timing"
    elif comp_mode == CompMode.gate_wc_power:
        inout_dir = "sim_gate_wc_power"
    else:
        report.error_exit("Unknown comp_mode", env=True)

    # Create files and folder paths
    repo_dir = Path.cwd()
    build_root = repo_dir / "build" / target
    compile_dir = build_root / "compile" / test_name
    elab_dir = build_root / "elab" / inout_dir
    # Named after the run rather than the test, so running the same test
    # twice on one elaboration keeps both outputs and both reports.
    simulation_dir = build_root / "simulation" / inout_dir / (run_name or test_name)
    report.set_out_dir(simulation_dir)

    spike_dir = repo_dir / "tools" / "spike"
    spike_dasm = spike_dir / "bin" / "spike-dasm"
    spike_lib = spike_dir / "lib"

    # ==========================================================
    # CHECK PREREQUISITES
    # ==========================================================
    report.step("Check prerequisites")

    # Software must be compiled first
    require_prerequisite(
        compile_dir / f"{test_name}.elf",
        f"compiled software for test '{test_name}'",
        f"./cook.py sw-compile -t {target} -c <toolchain> --out {test_name} <sources>",
        report=report,
    )

    # Hardware must be elaborated first (in the same comp_mode)
    require_prerequisite(
        elab_dir / "xcelium.d",
        f"Xcelium elaborated design (comp mode '{comp_mode.value}')",
        f"./cook.py xcelium-uvm-comp -t {target} --comp-mode {comp_mode.value}",
        report=report,
    )

    # Options must be compatible with how the design was elaborated
    elab_manifest = read_manifest(elab_dir, report)
    compile_manifest = read_manifest(compile_dir, report)

    # Spike tandem is force-disabled when the ISA the test was compiled
    # with (march of the sw-compile manifest) contains an extension known
    # to be incompatible with the current Spike version (see
    # SPIKE_TANDEM_BROKEN_EXTENSIONS): the tandem verdict would be
    # unreliable. Other tests keep the requested tandem behavior.
    if tandem_enabled:
        tandem_broken = spike_broken_extensions(
            get_manifest_option(compile_manifest, "march", "")
        )
        if tandem_broken:
            tandem_enabled = False
            report.add_context({"tandem_enabled": tandem_enabled})
            report.warning(
                "Spike tandem force-disabled: ISA extension(s) "
                f"{', '.join(tandem_broken)} incompatible with the current Spike"
            )

    if trace_mode != TraceMode.notrace:
        require_manifest_option(
            elab_manifest,
            "trace_mode",
            [TraceMode.gui.value, TraceMode.fast.value, TraceMode.compact.value],
            f"trace mode '{trace_mode.value}' requires a design elaborated with trace support",
            f"./cook.py xcelium-uvm-comp -t {target} --comp-mode {comp_mode.value} --trace-mode {trace_mode.value}",
            report=report,
            manifest_dir=elab_dir,
        )

    if tandem_enabled:
        require_manifest_option(
            elab_manifest,
            "tandem_enabled",
            [True],
            "spike tandem requires a design elaborated with --tandem-enabled",
            f"./cook.py xcelium-uvm-comp -t {target} --comp-mode {comp_mode.value} --tandem-enabled",
            report=report,
            manifest_dir=elab_dir,
        )

    if stats:
        require_manifest_option(
            elab_manifest,
            "stats",
            [True],
            "RTL perf tracer requires a design elaborated with --stats",
            f"./cook.py xcelium-uvm-comp -t {target} --comp-mode {comp_mode.value} --stats",
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

    # Symbol addresses extracted at compile time (sw-compile manifest):
    # tohost drives the end-of-test detection, the GLOBAL_PATTERN symbols
    # bound the benchmark timing window (0 = not instrumented)
    symbols = get_manifest_option(compile_manifest, "symbols", {})

    add_tohost = symbols.get("tohost")
    if add_tohost is None:
        report.error_exit(
            f"No tohost symbol recorded in the sw-compile manifest of {compile_dir}",
            env=True,
        )

    add_start_window = symbols.get("GLOBAL_PATTERN_start", 0)
    add_end_window = symbols.get("GLOBAL_PATTERN_end", 0)

    spike_param_file = repo_dir / "config" / "target" / target / "spike.yaml"

    if not spike_param_file.exists():
        report.error_exit(f"Missing {spike_param_file}", env=True)

    elf = compile_dir / f"{test_name}.elf"
    signature = compile_dir / f"{test_name}.elf.signature_output"
    tandem_report = simulation_dir / "tandem_report.yml"

    options = [
        "-R",
        "-messages",
        "-status",
        "-64bit",
        "-licqueue",
        "-noupdate",
        "-uvmhome",
        "CDNS-1.2",
        f"++{elf}",
        f"+elf_file={elf}",
        f"+core_name={target}",
        "+mhartid=0",
        f"+signature={signature}",
        "+UVM_TESTNAME=uvmt_cva6_firmware_test_c",
        f"+report_file={tandem_report}",
        f"+UVM_VERBOSITY=UVM_{uvm_verbosity}",
        *[f"{run_opt}" for run_opt in run_opts],
        f"+config_file={spike_param_file}",
        "+sv_lib",
        f"{spike_lib}/libcustomext",
        "+sv_lib",
        f"{spike_lib}/libyaml-cpp",
        "+sv_lib",
        f"{spike_lib}/libriscv",
        "+sv_lib",
        f"{spike_lib}/libfesvr",
        "+sv_lib",
        f"{spike_lib}/libdisasm",
        f"+tandem_enabled={int(tandem_enabled)}",
        f"+tohost_addr={add_tohost}",
        f"+GLOBAL_PATTERN_start={add_start_window}",
        f"+GLOBAL_PATTERN_end={add_end_window}",
        "-log",
        "simulation.log",
    ]

    # Disabled warnings
    disabled_warnings = ["BIGWIX", "ZROMCW", "STRINT", "ENUMERR", "SPDUSD", "RNDXCELON"]
    for warn in disabled_warnings:
        options += ["-nowarn", warn]

    if interactive_gui:
        options += ["-gui"]
    if uvm_seed is not None:
        options += ["-svseed", uvm_seed]
    if tb_performance_mode:
        options += ["+tb_performance_mode"]
    if comp_mode == CompMode.coverage:
        options += [
            "-coverage",
            "all",
            "-covoverwrite",
            "-covtest",
            f"{test_name}_{uvm_seed}",
        ]
    if stats:
        options += [
            "+perf_tracer_enabled",
            f"+perf_test_name={test_name}",
            f"+perf_output_dir={simulation_dir}",
        ]

    # Trace mode
    if trace_mode == TraceMode.gui:
        options += ["-gui", "-access", "+rwc"]
    elif trace_mode == TraceMode.fast:
        options += [
            "-input",
            "xcelium_trace.tcl",
        ]
        # Create TCL script for waveform dumping
        # (.as_posix(): backslashes are escape characters in TCL)
        tcl_file = simulation_dir / "xcelium_trace.tcl"
        tcl_file.write_text(
            f"database -open waves -shm -into {(simulation_dir / 'trace.shm').as_posix()}\n"
            "probe -create -all -depth all -database waves\n"
            "run\n"
        )
        report.info(f"Created trace TCL file: {tcl_file}")
    elif trace_mode == TraceMode.compact:
        options += [
            "-input",
            "xcelium_trace.tcl",
        ]
        # Create TCL script for waveform dumping (compact)
        # (.as_posix(): backslashes are escape characters in TCL)
        tcl_file = simulation_dir / "xcelium_trace.tcl"
        tcl_file.write_text(
            f"database -open waves -shm -into {(simulation_dir / 'trace.shm').as_posix()} -compress\n"
            "probe -create -all -depth all -database waves\n"
            "run\n"
        )
        report.info(f"Created trace TCL file: {tcl_file}")

    # ==========================================================
    # BUILD XRUN COMMAND
    # ==========================================================

    xrun_cmd = ["xrun"]
    xrun_cmd += options

    # ==========================================================
    # LAUNCH XRUN
    # ==========================================================
    report.step("Run Xcelium simulation")

    log_file = simulation_dir / "simulation.log"

    # Get XCELIUM_HOME
    xcelium_home = shutil.which("xrun")
    if xcelium_home:
        xcelium_home = Path(xcelium_home).parent.parent
    else:
        report.error_exit("Cannot determine XCELIUM_HOME", env=True)

    env_vars = {
        "LD_LIBRARY_PATH": f"{spike_lib}",
        "XCELIUM_HOME": str(xcelium_home),
    }

    # The CVA6 UVM testbench emits `UVM_ERROR @ <time> ns : ...`
    # (underscore, see verif/tb/core/custom_uvm_macros.svh) and `%t` pads
    # the line start: do not match `UVM-ERROR`, do not anchor `^UVM_ERROR`.
    # Same patterns as analyze_log below: keep them in sync.
    run_cmd(
        cmd=xrun_cmd,
        report=report,
        cwd=elab_dir,
        env=env_vars,
        error_patterns=["(ERROR:|^xm.*: \\*E|UVM_ERROR|UVM_FATAL|^Fatal-)"],
        warning_patterns=["(WARNING:|^xm.*: \\*W|UVM_WARNING)"],
        highlight_patterns=None,
        log_file=log_file,
        timeout=sim_timeout,
        check=False,
        capture_output=False,
    )

    # ==========================================================
    # POST PROCESS LOGS
    # ==========================================================

    status_passed = re.compile(r"^\s+SIMULATION PASSED")
    status_failed = re.compile(r"^\s+SIMULATION FAILED")

    try:
        found = 0
        with log_file.open("r") as f_in:
            for line in f_in:
                if status_passed.search(line):
                    report.success("Simulation PASSED")
                    found = 1
                    break
                if status_failed.search(line):
                    report.error("Simulation FAILED")
                    found = 1
                    break
    except Exception as e:
        report.error(f"Error process log: {e}", env=True)

    if found == 0:
        report.error("Simulation status unknown")

    # Attach UVM/Xcelium error and warning lines to the report so a failure
    # can be understood from the report alone (no log grepping needed)
    report.analyze_log(
        log_file,
        name="simulation.log analysis",
        error_patterns=[r"(ERROR:|^xm.*: \*E|UVM_ERROR|UVM_FATAL|^Fatal-)"],
        warning_patterns=[r"(WARNING:|^xm.*: \*W|UVM_WARNING)"],
        env_patterns=[
            r"(license|licence).*(error|fail|unable|denied|expired)",
            r"unable to checkout",
            r"no such file or directory",
            r"command not found",
        ],
        fail_on_error=False,
    )

    # ==========================================================
    # TANDEM VERDICT
    # ==========================================================
    # The `SIMULATION PASSED` banner alone does not cover the tandem
    # comparison: read the scoreboard report back for a blocking verdict
    if tandem_enabled:
        check_tandem_verdict(tandem_report, spike_param_file, report)

    # ==========================================================
    # POST PROCESS TIMING
    # ==========================================================
    # Timing events displayed by rvfi_tracer.sv (UVM testbench): the
    # GLOBAL_PATTERN symbol hits and the end of simulation, as pure
    # ns/cycle values. See flows/utils/rvfi_timing.py.
    report.step("Post-process timing info")

    try:
        timing_events = extract_rvfi_timing(log_file)
    except OSError as e:
        report.warning(f"Cannot read {log_file}: {e}")
        timing_events = {}

    if timing_events:
        timing = report.metric("Timing", fmt={"cycles": "cycles"})
        for event, values in timing_events.items():
            timing.add_row(event=event, **values)
        report.print_metric(timing)

    # ==========================================================
    # BENCHMARK CYCLE COUNT
    # ==========================================================
    # Record the measured cycle count; for known benchmarks (coremark,
    # dhrystone...) the score is computed from the iteration count the
    # binary was compiled with (sw-compile manifest) and the cycle count
    # is checked against the target expected values.
    report.step("Benchmark cycle count")
    cycles = benchmark_window(timing_events)
    if cycles is None:
        report.info("No cycle count available, skipping benchmark reporting")
    else:
        # Score only from an instrumented window: without the
        # GLOBAL_PATTERN symbols the fallback covers the whole simulation
        # (boot included) and the per-MHz score would be silently skewed
        iterations = None
        if "GLOBAL_PATTERN_end" in timing_events:
            iterations = get_manifest_option(compile_manifest, "benchmark_iterations")
        report.benchmark(target, test_name, cycles, iterations=iterations)

    # ==========================================================
    # Disassemble rvfi trace with spike_dasm
    # ==========================================================
    report.step("Disassemble rvfi trace")

    spike_dasm_log_file = simulation_dir / "spike_dasm.log"

    # Disassemble with the march the ELF was compiled with (sw-compile
    # manifest), which may differ from the target isa.yml: users may add
    # or remove extensions for software compilation only.
    isa = get_manifest_option(compile_manifest, "march")

    trace_rvfi_file = elab_dir / "trace_rvfi_hart_00.dasm"

    if not trace_rvfi_file.exists():
        report.info(
            "Trace RVFI not found, if rvfi interface is disabled it's normal",
        )
    elif isa is None:
        report.warning(
            "No march recorded in the sw-compile manifest, skipping disassembly"
        )
    else:
        env_vars_dasm = {"LD_LIBRARY_PATH": f"{spike_lib}"}

        spike_dasm_cmd = [str(spike_dasm)]
        spike_dasm_cmd += [f"--isa={isa}"]

        with trace_rvfi_file.open("rb") as f:
            run_cmd(
                cmd=spike_dasm_cmd,
                report=report,
                cwd=elab_dir,
                env=env_vars_dasm,
                error_patterns=["(ERROR|Error|No such file or directory)"],
                warning_patterns=["(WARNING|Warning)"],
                highlight_patterns=None,
                stdin=f,
                log_file=spike_dasm_log_file,
                timeout=30,
                check=False,
                capture_output=False,
            )

    # ==========================================================
    # MOVE LOGS / TRACES
    # ==========================================================
    report.step("Move files")

    for pattern in [
        elab_dir / "tandem.log",
        elab_dir / "trace_rvfi_hart*.dasm",
    ]:
        for file_path in glob.glob(str(pattern)):
            try:
                shutil.move(file_path, str(simulation_dir))
                report.info(f"Moved {file_path} -> {simulation_dir}")
            except FileNotFoundError:
                report.warning(f"No file matched: {file_path}")
            except Exception as e:
                report.warning(f"Failed to move {file_path}: {e}")

    # ==========================================================
    # Stats
    # ==========================================================
    if stats:
        report.step("Analysis Stats")

        path_script = (
            repo_dir / "perf-model" / "rtl_models_trace" / "scripts" / "main_stats.py"
        )
        path_json = simulation_dir / f"stalls_{test_name}_{target}.json"

        directory_script = str(path_script.parent)
        sys.path.insert(0, directory_script)

        try:
            spec = importlib.util.spec_from_file_location("main_stats", path_script)
            main_stats = importlib.util.module_from_spec(spec)
            sys.modules["main_stats"] = main_stats
            spec.loader.exec_module(main_stats)
            try:
                main_stats.main(
                    files=[str(path_json)], csv=True, i=None, pc=None, c=None, v=None
                )
            except SystemExit as e:
                pass

        finally:
            if directory_script in sys.path:
                sys.path.remove(directory_script)

    # ==========================================================
    # BUILD MANIFEST
    # ==========================================================
    write_manifest(
        simulation_dir,
        "xcelium-uvm-run",
        {
            "target": target,
            "test_name": test_name,
            "comp_mode": comp_mode,
            "trace_mode": trace_mode,
            "uvm_verbosity": uvm_verbosity,
            "tandem_enabled": tandem_enabled,
            "tb_performance_mode": tb_performance_mode,
            "stats": stats,
            "run_opts": run_opts,
            "uvm_seed": uvm_seed,
            "run_name": run_name,
        },
        report=report,
    )

    # ==========================================================
    # List
    # ==========================================================

    gen_files = [
        simulation_dir / "simulation.log",
        simulation_dir / "tandem.log",
        simulation_dir / "tandem_report.yml",
        simulation_dir / "trace_rvfi_hart_00.dasm",
        simulation_dir / "spike_dasm.log",
        simulation_dir / "trace.shm",
        simulation_dir / f"stalls_{test_name}_{target}.json",
        simulation_dir / f"details_{test_name}_{target}.txt",
        simulation_dir / f"analysis_{test_name}_{target}.txt",
    ]

    report.step("Generated files")
    generated = []
    for genfile in gen_files:
        if genfile.exists():
            report.info(f"> {genfile}")
            generated.append(str(genfile.relative_to(repo_dir)))

    # ==========================================================
    # BUILD REPORT
    # ==========================================================
    report.log("Generated files", generated)

    report.end("Completed")
