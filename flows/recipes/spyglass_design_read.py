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
from flows.utils.manifest import write_manifest
from flows.utils.recipe_report import RecipeReport
from flows.utils.run_cmd import run_cmd
from flows.utils.autocompletion import autocompletion_target
from flows.utils.target_config import (
    read_config_or_exit_testbench_cfg,
    top_elaborate as get_top_elaborate,
)

app = typer.Typer()


# ==========================================================
# RECIPE
# ==========================================================


@app.command()
def spyglass_design_read(
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
    Spyglass design read
    """
    report = RecipeReport(
        "spyglass-design-read",
        title="Spyglass design read",
        context={
            "target": target,
        },
        quiet=quiet,
    )

    # Output directory set first: a failure reading the target
    # configuration below must still produce a report.
    repo_dir = Path.cwd()
    build_root = repo_dir / "build" / target
    spyglass_dir = build_root / "spyglass"
    report.set_out_dir(spyglass_dir)

    # Get testbench config
    cva6_hier = read_config_or_exit_testbench_cfg(target, report)

    # Test tools in path
    aipk_read_path = shutil.which("aipk_read")
    if aipk_read_path is not None:
        report.success(f"aipk_read: {aipk_read_path}")
    else:
        report.error_exit("aipk_read: Not found", env=True)

    top_elaborate = get_top_elaborate(cva6_hier)

    report.add_context({"top_elaborate": top_elaborate})

    # Create files and folder paths
    sg_setup_dir = spyglass_dir / "sg_setup" / top_elaborate
    tmp_dir = spyglass_dir / "tmp"

    options_file = sg_setup_dir / f"{top_elaborate}_options.tcl"
    goals_file = sg_setup_dir / f"{top_elaborate}_goals_setup.tcl"
    waiver_file = sg_setup_dir / f"{top_elaborate}_waiver.awl"
    sgdc_file = sg_setup_dir / f"{top_elaborate}.sgdc"

    # ==========================================================
    # CLEAN
    # ==========================================================
    report.step("Clean")
    try:
        if spyglass_dir.exists():
            shutil.rmtree(spyglass_dir)
            report.info(f"remove {spyglass_dir}")
    except Exception as e:
        report.error_exit(f"Clean error : {e}", env=True)

    sg_setup_dir.mkdir(parents=True, exist_ok=True)
    report.info(f"create {sg_setup_dir}")

    tmp_dir.mkdir(parents=True, exist_ok=True)
    report.info(f"create {tmp_dir}")

    # ==========================================================
    # ENV VARIABLES (passed to run_cmd only)
    # ==========================================================

    env_vars = {
        "CVA6_REPO_DIR": str(repo_dir),
        "TARGET_CFG": target,
        "HPDCACHE_DIR": str(repo_dir / "core" / "cache_subsystem" / "hpdcache"),
        "SPYGLASS_TMPDIR": str(tmp_dir),
    }

    # ==========================================================
    # CUSTOMIZE WITH OPTIONS
    # ==========================================================

    # FILELIST
    flist = repo_dir / "config" / "target" / target / "Flist.cva6"

    # ==========================================================
    # GENERATE OPTIONS FILE
    # ==========================================================
    report.step("Generate options file")

    options_content = """## File Name : Option File
set_option enableSV no
set_option enableSV09 yes
"""

    options_file.write_text(options_content)

    report.info(f"File generated at {options_file}")
    report.code(options_content, "tcl")

    # ==========================================================
    # GENERATE GOALS SETUP
    # ==========================================================
    report.step("Generate goals setup file")

    goals_content = """## File Name : SpyGlass Goal Setup File
set_parameter ignore_bitwiseor_assignment yes
set_parameter ignore_if_case_statement yes
current_goal cdc/cdc_verify_struct
set_goal_option report {count moresimple moresimple_sevclass sign_off summary waiver CKSGDCInfo Clock-Reset-Summary CDC-report Ac_sync_group_detail Glitch_detailed CrossingInfo SynchInfo Clock-Reset-Detail}
set_parameter dump_sync_info detailed
current_goal cdc/cdc_verify
set_goal_option report {count moresimple moresimple_sevclass sign_off summary waiver CKSGDCInfo Clock-Reset-Summary CDC-report Ac_sync_group_detail Glitch_detailed}
set_parameter fa_atime 20
set_parameter fa_scope block
current_goal dft/dft_scan_ready
set_parameter dftGenerateStuckAtFaultReport all
current_goal dft/dft_best_practice
set_parameter dftGenerateStuckAtFaultReport all
current_goal none
"""

    goals_file.write_text(goals_content)

    report.info(f"File generated at {goals_file}")
    report.code(goals_content, "tcl")

    # ==========================================================
    # GENERATE WAIVER
    # ==========================================================
    report.step("Generate waiver file")

    waiver_content = """## File Name : Local Waiver File(.awl)
waive -file_line {$CVA6_REPO_DIR/common/local/util/sram_cache.sv}  {55}  -severity {  {ERROR}  }  -rule {  {ErrorAnalyzeBBox}  }
waive -file_line {$CVA6_REPO_DIR/common/local/util/sram_cache.sv}  {85}  -severity {  {ERROR}  }  -rule {  {ErrorAnalyzeBBox}  }
waive -file {  {$CVA6_REPO_DIR/vendor/pulp-platform/tech_cells_generic/src/rtl/tc_sram.sv}  }  -severity {  {ERROR}  }  -rule {  {ErrorAnalyzeBBox}  }
waive -file {  {$CVA6_REPO_DIR/vendor/pulp-platform/tech_cells_generic/src/rtl/tc_sram.sv}  }  -severity {  {ERROR}  }  -rule {  {SYNTH_5251}  }
waive -file {  {$CVA6_REPO_DIR/vendor/pulp-platform/tech_cells_generic/src/rtl/tc_sram.sv}  }  -severity {  {SynthesisWarning}  }  -rule {  {SYNTH_5143}  }
waive -file {  {$CVA6_REPO_DIR/core/csr_regfile.sv}  }  -severity {  {SynthesisWarning}  }  -rule {  {SYNTH_89}  }
waive -file {  {$CVA6_REPO_DIR/vendor/pulp-platform/axi/src/axi_pkg.sv} }
waive -file {  {$CVA6_REPO_DIR/core/cva6_rvfi_probes.sv} }
#waive -file {$CVA6_REPO_DIR/core/cache_subsystem/*} -regexp
waive -rule {  {W240}  }  -comment {Remove 'Input declared but not read' warning as it happens very often for disable features such as PMP, Accelerator, ...}
waive -rule {  {W528}  }  -comment {Remove 'Set but not read' warning as it happens very often for disable features such as PMP, Accelerator, ...}
"""

    waiver_file.write_text(waiver_content)

    report.info(f"File generated at {waiver_file}")
    report.code(waiver_content, "tcl")

    # ==========================================================
    # GENERATE CONSTRAINTS FILE
    # ==========================================================
    report.step("Generate onstraints file")

    sgdc_content = f"""## File Name : SpyGlass Constraints File (sgdc file)
current_design {top_elaborate}
clock -name "{top_elaborate}.clk_i" -domain domain0 -tag SG_AUTO_TAG_1 -testclock -atspeed -period 10 -edge {{0 5}}
reset -name "{top_elaborate}.rst_ni" -value 0
test_mode -scanshift -name "{top_elaborate}.rst_ni" -value 1
"""

    sgdc_file.write_text(sgdc_content)

    report.info(f"File generated at {sgdc_file}")
    report.code(sgdc_content, "tcl")

    # ==========================================================
    # BUILD SPYGLASS DESIGN READ COMMAND
    # ==========================================================

    sg_cmd = ["aipk_read"]
    sg_cmd += [f"-top={top_elaborate}"]
    sg_cmd += [f"-srcfile={str(flist)}"]

    # ==========================================================
    # LAUNCH SPYGLASS DESIGN READ COMMAND
    # ==========================================================
    report.step("LAUNCH SPYGLASS DESIGN READ")

    log_file = spyglass_dir / "design_read.log"

    run_cmd(
        cmd=sg_cmd,
        report=report,
        cwd=spyglass_dir,
        env=env_vars,
        error_patterns=["error:|^AIPK_ERROR :|^ERROR:"],
        warning_patterns=["warning:|^AIPK_WARNING :|^WARNING:"],
        highlight_patterns=["info:|Messages:|Total Messages|^AIPK_INFO :|^INFO:"],
        log_file=log_file,
        timeout=1800,
        check=False,
        capture_output=True,
    )

    # ==========================================================
    # Results processing
    # ==========================================================
    report.step("Results processing")

    if not log_file.exists():
        report.error_exit(f"{log_file} missing", env=True)

    n_err, _ = report.analyze_log(
        log_file,
        name="design_read.log analysis",
        error_patterns=["error:|^AIPK_ERROR :|^ERROR:"],
        warning_patterns=["warning:|^AIPK_WARNING :|^WARNING:"],
        env_patterns=[
            r"(license|licence).*(error|fail|unable|denied|expired)",
            r"unable to checkout",
            r"command not found",
        ],
        fail_on_error=False,
    )

    if n_err > 0:
        report.error_exit(f"Design read failed: {n_err} error(s) in {log_file}")
    report.success("Design read completed")

    # ==========================================================
    # List
    # ==========================================================
    report.step("Generated files")
    gen_files = [
        log_file,
        spyglass_dir
        / "sg_run_results"
        / top_elaborate
        / top_elaborate
        / "lint"
        / "design_audit"
        / "spyglass.log",
        spyglass_dir
        / "sg_run_results"
        / top_elaborate
        / top_elaborate
        / "lint"
        / "design_audit"
        / "spyglass_reports",
        spyglass_dir
        / "sg_run_results"
        / top_elaborate
        / top_elaborate
        / "cdc"
        / "cdc_setup_check"
        / "spyglass.log",
        spyglass_dir
        / "sg_run_results"
        / top_elaborate
        / top_elaborate
        / "cdc"
        / "cdc_setup_check"
        / "spyglass_reports",
        spyglass_dir
        / "sg_run_results"
        / f"{top_elaborate}_sg_reports"
        / "html_reports"
        / "goals_summary.html",
    ]

    generated = []
    for genfile in gen_files:
        if genfile.exists():
            report.info(f"> {genfile}")
            generated.append(str(genfile.relative_to(repo_dir)))

    # ==========================================================
    # BUILD MANIFEST
    # ==========================================================
    write_manifest(
        spyglass_dir,
        "spyglass-design-read",
        {
            "target": target,
            "cva6_hier": cva6_hier,
            "top_elaborate": top_elaborate,
        },
        report=report,
    )

    # ==========================================================
    # BUILD REPORT
    # ==========================================================
    report.log("Generated files", generated)

    report.end("Completed")
