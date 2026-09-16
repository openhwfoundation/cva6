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
import shutil
import typer
from flows.utils.manifest import write_manifest, require_prerequisite
from flows.utils.recipe_report import RecipeReport
from flows.utils.run_cmd import run_cmd
from flows.utils.autocompletion import (
    CompMode,
    TraceMode,
    autocompletion_target,
)
from flows.utils.target_config import read_config_or_exit_testbench_cfg, dut_hier

app = typer.Typer()


# ==========================================================
# RECIPE
# ==========================================================


@app.command()
def questa_uvm_comp(
    target: str = typer.Option(
        ...,
        "--target",
        "-t",
        help="CVA6 user configuration",
        autocompletion=autocompletion_target,
    ),
    comp_mode: CompMode = typer.Option(CompMode.rtl, help="Hardware compilation mode"),
    trace_mode: TraceMode = typer.Option(TraceMode.notrace, help="Trace mode"),
    tandem_enabled: bool = typer.Option(False, help="Enable spike tandem"),
    stats: bool = typer.Option(False, help="Enable RTL perf tracer"),
    quiet: bool = typer.Option(
        False, "--quiet", "-q", help="Suppress output (errors only)"
    ),
):
    """
    Questa UVM compilation / elaboration flow
    """
    report = RecipeReport(
        "questa-uvm-comp",
        title="QUESTA DESIGN ELABORATION",
        context={
            "target": target,
            "comp_mode": comp_mode,
            "trace_mode": trace_mode,
            "tandem_enabled": tandem_enabled,
            "stats": stats,
        },
        quiet=quiet,
    )

    repo_dir = Path.cwd()

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

    # Test tools in path
    vlog_path = shutil.which("vlog")
    vopt_path = shutil.which("vopt")
    if vlog_path is not None and vopt_path is not None:
        report.success(f"vlog: {vlog_path}")
        report.success(f"vopt: {vopt_path}")
    else:
        if vlog_path is None:
            report.error("vlog: Not found", env=True)
        if vopt_path is None:
            report.error("vopt: Not found", env=True)
        report.error_exit("Questa tools not found in PATH", env=True)

    # Create files and folder paths
    build_root = repo_dir / "build" / target
    elab_dir = build_root / "elab" / inout_dir
    report.set_out_dir(elab_dir)
    work_dir = elab_dir / "work"

    # Get testbench config
    cva6_hier = read_config_or_exit_testbench_cfg(target, report)

    # ==========================================================
    # CHECK PREREQUISITES
    # ==========================================================
    report.step("Check prerequisites")

    if comp_mode in [CompMode.gate_wc_power, CompMode.gate_wc_timing]:
        synth_dir = build_root / "synthesis"
        sdf_name = (
            "wc_timing.sdf" if comp_mode == CompMode.gate_wc_timing else "wc_power.sdf"
        )
        for artifact, description in [
            (synth_dir / "Flist.libverilog", "synthesis library filelist"),
            (synth_dir / "netlist" / "synth.v", "synthesized netlist"),
            (synth_dir / "netlist" / sdf_name, "SDF timing annotation"),
        ]:
            require_prerequisite(
                artifact,
                f"{description} (gate-level compilation needs a synthesized design)",
                f"./cook.py dc-shell-synth -t {target} --techno <techno> --period <period>",
                report=report,
            )
    report.success("Prerequisites OK")

    # ==========================================================
    # CLEAN
    # ==========================================================
    report.step("Clean")
    try:
        if elab_dir.exists():
            shutil.rmtree(elab_dir)
            report.info(f"remove {elab_dir}")
    except Exception as e:
        report.error_exit(f"Clean error : {e}", env=True)

    elab_dir.mkdir(parents=True, exist_ok=True)
    report.info(f"create {elab_dir}")

    # ==========================================================
    # ENV VARIABLES (passed to run_cmd only)
    # ==========================================================

    env_vars = {
        "CVA6_REPO_DIR": str(repo_dir),
        "TARGET": target,
        "TARGET_CFG": target,
        "SPIKE_PATH": str(
            repo_dir / "verif" / "core-v-verif" / "vendor" / "riscv" / "riscv-isa-sim"
        ),
        "LD_PRELOAD": f"{repo_dir}/tools/spike/lib/libyaml-cpp.so:{repo_dir}/tools/spike/lib/libriscv.so",  # ← ADD THIS COMMA
        "HPDCACHE_DIR": str(repo_dir / "core" / "cache_subsystem" / "hpdcache"),
        "CVA6_UVMT_DIR": str(repo_dir / "verif/tb/uvmt"),
        "CVA6_CORET_DIR": str(repo_dir / "verif/tb/core"),
        "CVA6_UVMT_PATH": str(repo_dir / "verif/tb/uvmt"),
        "CVA6_UVME_PATH": str(repo_dir / "verif/env/uvme"),
        "CV_CORE_LC": "cva6",
        "CV_CORE_UC": "CVA6",
        "CVA6_TB_DIR": str(repo_dir / "verif/tb/core"),
        "DV_UVMT_PATH": str(repo_dir / "verif/tb/uvmt"),
        "DV_UVME_PATH": str(repo_dir / "verif/env/uvme"),
        "DV_UVML_HRTBT_PATH": str(
            repo_dir / "verif/core-v-verif/lib/uvm_libs/uvml_hrtbt"
        ),
        "DV_UVMA_CORE_CNTRL_PATH": str(
            repo_dir / "verif/core-v-verif/lib/uvm_agents/uvma_core_cntrl"
        ),
        "DV_UVMA_RVFI_PATH": str(
            repo_dir / "verif/core-v-verif/lib/uvm_agents/uvma_rvfi"
        ),
        "DV_UVMA_ISACOV_PATH": str(
            repo_dir / "verif/core-v-verif/lib/uvm_agents/uvma_isacov"
        ),
        "DV_UVMA_CLKNRST_PATH": str(
            repo_dir / "verif/core-v-verif/lib/uvm_agents/uvma_clknrst"
        ),
        "DV_UVMA_AXI_PATH": str(
            repo_dir / "verif/core-v-verif/lib/uvm_agents/uvma_axi5"
        ),
        "DV_UVMA_CVXIF_PATH": str(
            repo_dir / "verif/core-v-verif/lib/uvm_agents/uvma_cvxif"
        ),
        "DV_UVMA_INTERRUPT_PATH": str(repo_dir / "verif/env/uvme/uvma_interrupt"),
        "DV_UVMA_DEBUG_PATH": str(
            repo_dir / "verif/core-v-verif/lib/uvm_agents/uvma_debug"
        ),
        "DV_UVMA_OBI_PATH": str(
            repo_dir / "verif/core-v-verif/lib/uvm_agents/uvma_obi"
        ),
        "DV_UVMC_RVFI_SCOREBOARD_PATH": str(
            repo_dir / "verif/core-v-verif/lib/uvm_components/uvmc_rvfi_scoreboard/"
        ),
        "DV_UVMC_RVFI_REFERENCE_MODEL_PATH": str(
            repo_dir
            / "verif/core-v-verif/lib/uvm_components/uvmc_rvfi_reference_model/"
        ),
        "DV_UVML_TRN_PATH": str(repo_dir / "verif/core-v-verif/lib/uvm_libs/uvml_trn"),
        "DV_UVML_MEM_PATH": str(repo_dir / "verif/core-v-verif/lib/uvm_libs/uvml_mem"),
        "DV_UVML_LOGS_PATH": str(
            repo_dir / "verif/core-v-verif/lib/uvm_libs/uvml_logs"
        ),
        "DV_UVML_SB_PATH": str(repo_dir / "verif/core-v-verif/lib/uvm_libs/uvml_sb"),
        "DV_UVMA_OBI_MEMORY_PATH": str(
            repo_dir / "verif/core-v-verif/lib/uvm_agents/uvma_obi_memory"
        ),
        "CV_CORE_PKG": str(repo_dir / "verif/core-v-verif/core-v-cores/cva6"),
        "DESIGN_RTL_DIR": str(repo_dir / "verif/core-v-verif/core-v-cores/cva6/rtl"),
        "TBSRC_HOME": str(repo_dir / "verif/core-v-verif/cva6/tb"),
    }

    # Get QUESTASIM_HOME
    questasim_home = shutil.which("vsim")
    if questasim_home:
        # Get the parent directory (bin) then the parent of that
        questasim_home = Path(questasim_home).parent.parent
        env_vars["QUESTASIM_HOME"] = str(questasim_home)
        report.info(f"QUESTASIM_HOME: {questasim_home}")
    else:
        report.error_exit("Cannot determine QUESTASIM_HOME", env=True)

    # ==========================================================
    # CUSTOMIZE WITH OPTIONS
    # ==========================================================

    # FILELIST
    flist = []

    if comp_mode in [CompMode.gate_wc_power, CompMode.gate_wc_timing]:
        flist += [
            repo_dir / "build" / target / "synthesis" / "Flist.libverilog",
            repo_dir / "config" / "target" / target / "Flist.cva6_gate",
        ]
    else:
        flist += [repo_dir / "config" / "target" / target / "Flist.cva6"]

    flist += [
        repo_dir / "verif" / "tb" / "core" / "Flist.cva6_tb",
        repo_dir / "verif" / "tb" / "uvmt" / "uvmt_cva6.flist",
    ]

    if stats:
        flist += [repo_dir / "perf-model" / "rtl_models_trace" / "Flist.perf-model"]

    # INCLUDE DIRS
    incdirs = [
        repo_dir / "verif" / "env" / "uvme",
        repo_dir / "verif" / "tb" / "uvmt",
        Path(f"{questasim_home}") / "verilog_src" / "uvm-1.2" / "src",
    ]

    # DEFINES
    defines = [
        "UVM",
        "HPDCACHE_ASSERT_OFF=1",
        f"SPIKE_TANDEM={int(tandem_enabled)}",
        "UNSUPPORTED_WITH",
        "QUESTA",
    ]

    # ==========================================================
    # STEP 1: CREATE LIBRARY (vlib)
    # ==========================================================
    report.step("Create Questa work library")

    vlib_cmd = ["vlib", str(work_dir)]

    run_cmd(
        cmd=vlib_cmd,
        cwd=elab_dir,
        env=env_vars,
        error_patterns=["^\\*\\* Error"],
        warning_patterns=["^\\*\\* Warning"],
        highlight_patterns=None,
        log_file=elab_dir / "vlib.log",
        timeout=30,
        check=False,
        capture_output=True,
        report=report,
    )

    if not work_dir.exists():
        report.error_exit("Work library not created")

    report.success(f"Work library created: {work_dir}")

    # ==========================================================
    # STEP 2: COMPILE (vlog)
    # ==========================================================
    report.step("Compile with vlog")

    vlog_cmd = ["vlog"]

    # Basic options
    vlog_options = [
        "-sv",
        "-sv17compat",
        "-64",
        "-timescale",
        "1ns/1ns",
        "+acc=+rb",
        "-incr",
        "-nologo",
        "-quiet",
        "-permissive",
        "-svinputport=compat",
        "-pedanticerror",
        "-compat",
        "+jtag_rbb_enable=0",
        "-work",
        str(work_dir),
    ]

    # Suppressed warnings
    vlog_options += [
        "-suppress",
        "vlog-2745",
        "-suppress",
        "vlog-8386",
        "-suppress",
        "vlog-8607",
    ]

    vlog_cmd += vlog_options

    # Include directories
    for d in incdirs:
        vlog_cmd += [f"+incdir+{d}"]

    # Defines
    for d in defines:
        vlog_cmd += [f"+define+{d}"]

    # UVM package
    vlog_cmd += [
        f"{questasim_home}/verilog_src/uvm-1.2/src/uvm_pkg.sv",
    ]

    # File lists
    for f in flist:
        vlog_cmd += ["-f", str(f)]

    # Coverage options
    if comp_mode == CompMode.coverage:
        vlog_cmd += [
            "+cover=sbcef",
        ]

    # SDF for gate-level
    if comp_mode in [CompMode.gate_wc_timing, CompMode.gate_wc_power]:
        sdf_hier = dut_hier(cva6_hier)
        report.add_context({"sdf_hier": sdf_hier})

        if comp_mode == CompMode.gate_wc_timing:
            sdf = (
                repo_dir / "build" / target / "synthesis" / "netlist" / "wc_timing.sdf"
            )
        else:
            sdf = repo_dir / "build" / target / "synthesis" / "netlist" / "wc_power.sdf"

        # Create SDF file for vsim to use
        # (.as_posix(): .do files are TCL, backslashes are escape characters)
        sdf_file = elab_dir / "sdf.do"
        sdf_file.write_text(f'sdf load -file "{sdf.as_posix()}" {sdf_hier}')
        report.info(f"Created SDF file: {sdf_file}")

    log_file = elab_dir / "vlog.log"

    run_cmd(
        cmd=vlog_cmd,
        cwd=elab_dir,
        env=env_vars,
        error_patterns=["^\\*\\* Error"],
        warning_patterns=["^\\*\\* Warning"],
        highlight_patterns=["Compiling", "Successfully compiled"],
        log_file=log_file,
        timeout=1800,
        check=False,
        capture_output=True,
        report=report,
    )

    report.analyze_log(
        log_file,
        name="vlog.log analysis",
        error_patterns=[r"^\*\* Error"],
        warning_patterns=[r"^\*\* Warning"],
        env_patterns=[
            r"(license|licence).*(error|fail|unable|denied|expired)",
            r"unable to checkout",
            r"command not found",
        ],
        fail_on_error=False,
    )

    # ==========================================================
    # STEP 3: OPTIMIZE (vopt)
    # ==========================================================
    report.step("Optimize with vopt")

    vopt_cmd = [
        "vopt",
        "-work",
        str(work_dir),
        "-64",
        "+acc",
    ]

    # Coverage options
    if comp_mode == CompMode.coverage:
        vopt_cmd += [
            "+cover=sbcef",
        ]

    # Trace options
    # Note: +acc is already added above (line 381) which enables all debug access
    # This is sufficient for waveform dumping, no additional options needed

    vopt_cmd += [
        "uvmt_cva6_tb",
        "-o",
        "uvmt_cva6_tb_opt",
    ]

    run_cmd(
        cmd=vopt_cmd,
        cwd=elab_dir,
        env=env_vars,
        error_patterns=["^\\*\\* Error"],
        warning_patterns=["^\\*\\* Warning"],
        highlight_patterns=["Optimizing", "Optimization complete"],
        log_file=elab_dir / "vopt.log",
        timeout=600,
        check=False,
        capture_output=True,
        report=report,
    )

    report.analyze_log(
        elab_dir / "vopt.log",
        name="vopt.log analysis",
        error_patterns=[r"^\*\* Error"],
        warning_patterns=[r"^\*\* Warning"],
        env_patterns=[
            r"(license|licence).*(error|fail|unable|denied|expired)",
            r"unable to checkout",
            r"command not found",
        ],
        fail_on_error=False,
    )

    # Check if optimization succeeded
    if not (work_dir / "uvmt_cva6_tb_opt").exists():
        report.error_exit("Optimized design not generated")

    report.success("Optimized design generated")

    if not log_file.exists():
        report.warning("Compilation log missing")

    # ==========================================================
    # BUILD MANIFEST
    # ==========================================================
    write_manifest(
        elab_dir,
        "questa-uvm-comp",
        {
            "target": target,
            "comp_mode": comp_mode,
            "trace_mode": trace_mode,
            "tandem_enabled": tandem_enabled,
            "stats": stats,
        },
        report=report,
    )

    # ==========================================================
    # List
    # ==========================================================
    report.step("Generated files")
    gen_files = [work_dir, log_file, elab_dir / "vopt.log"]

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
