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
Bitstream generation of the CVA6 Xilinx FPGA top level (Vivado).

Two stages:

- the nine Vivado IP cores, generated once into the source tree by the
  per-IP scripts of `corev_apu/fpga/xilinx/`;
- the synthesis and implementation themselves, from a TCL script this
  recipe generates.

The zero stage bootloader is **not** built here: it is a software pattern
of its own (`fpga-bootrom`), indexed by board and register width rather
than by target, and consumed as a prerequisite. The recipe checks it was
built for the board being targeted, its device tree carrying the board
parameters.

The RTL comes from `config/target/<target>/Flist.cva6_fpga`, so the file
list is data rather than code (see the header of
`corev_apu/fpga/Flist.cva6_fpga` for why it does not include the core
one), and the generated script uses absolute paths: the Vivado project
is created under `build/`, not in the middle of the sources.

Reports the FPGA utilization and the worst negative slack as KPIs,
checked against `config/target/<target>/expected_values.yml` when the
target carries baselines for them.
"""

from pathlib import Path
import re
import shutil
import typer

from flows.utils.fpga_board import (
    FPGA_COMMON_XDC,
    FPGA_GLOBAL_INCLUDE,
    FPGA_INCDIRS,
    FPGA_IPS,
    FPGA_TOP,
    board_params,
    ip_dir,
    ip_is_generated,
    ip_xci,
)
from flows.utils.manifest import (
    read_manifest,
    require_manifest_option,
    require_prerequisite,
    write_manifest,
)
from flows.utils.recipe_report import RecipeReport
from flows.utils.run_cmd import run_cmd
from flows.utils.autocompletion import FpgaBoard, autocompletion_target
from flows.utils.target_config import (
    read_config_expected_value,
    read_config_or_exit_flist,
    read_config_or_exit_isa,
)

app = typer.Typer()

# Utilization deviation tolerance (%) vs
# config/target/<target>/expected_values.yml. Wider than the synthesis
# gate count check: place and route is directive driven and its result
# moves slightly between two Vivado runs of the same RTL.
DIFF_UTILIZATION = 2.0

# Hierarchical utilization table of `report_utilization -hierarchical`.
UTILIZATION_RE = re.compile(
    r"\|(?P<ind> +)(?P<instance>[\w()\[\].]+) +\| +(?P<module>[\w()\[\].]+) \| +"
    r"(?P<luts>\d+) \| +(?P<logic_luts>\d+) \| +(?P<lutrams>\d+) \| +"
    r"(?P<srls>\d+) \| +(?P<ffs>\d+) \| +(?P<ramb36>\d+) \| +(?P<ramb18>\d+) \| +"
    r"(?P<dsp>\d+) \|"
)

# Worst negative slack of `report_timing`. Vivado prints it as the slack
# of the reported path; a design meeting timing reports a positive value.
WNS_RE = re.compile(r"^\s*Slack\s*\((MET|VIOLATED)\)\s*:?\s*(-?\d+\.?\d*)ns", re.M)

# Indentation of `report_utilization -hierarchical` from which a row is
# too deep in the hierarchy to be reported.
UTILIZATION_DEPTH = 10


def _xlen(target, report):
    """
    Return the register width the target is built for.

    Read from the ISA the software is compiled with rather than guessed
    from the target name: `rv64...` is the only thing that makes a build
    64 bit, and it selects the bootloader to cross-compile.
    """
    march, _ = read_config_or_exit_isa(target, report)
    if march.startswith("rv64"):
        return 64
    if march.startswith("rv32"):
        return 32
    return report.error_exit(
        f"Cannot tell the register width from march {march!r} of target "
        f"'{target}': expected it to start with rv32 or rv64",
        env=True,
    )


def _build_tcl(out_dir, repo_dir, target, board, jobs, bootrom_sv, rtl_files):
    """
    Return the Vivado script building the bitstream.

    Merges what `corev_apu/fpga/scripts/prologue.tcl` and `run.tcl` did,
    with three deliberate differences: every path is absolute, so the
    project is created in the recipe output directory instead of the
    source tree; the parameters come from the board table rather than
    from environment variables; and the post implementation reports do
    not wipe the post synthesis ones (`run.tcl` ran `rm -rf reports/*`
    twice, which destroyed the CDC and clock interaction reports it had
    just produced).
    """
    params = board_params(board)
    fpga_dir = repo_dir / "corev_apu" / "fpga"
    vhdl = [f for f in rtl_files if f.lower().endswith(".vhd")]
    verilog = [f for f in rtl_files if not f.lower().endswith(".vhd")]
    # The bootloader is generated, so it is not in the filelist: it is
    # appended here, from the directory the bootrom stage built it in.
    verilog.append(str(bootrom_sv))

    def tcl_list(paths):
        return " \\\n    ".join(Path(p).as_posix() for p in paths)

    svh = (fpga_dir / params.svh).as_posix()
    registers_svh = (repo_dir / FPGA_GLOBAL_INCLUDE).as_posix()

    return f"""\
# Generated by ./cook.py vivado-fpga-build -- do not edit.
# target {target}, board {board.value}

create_project {FPGA_TOP} {out_dir.as_posix()} -force -part {params.part}
set_property board_part {params.board_part} [current_project]
set_param general.maxThreads {jobs}

set_msg_config -id {{[Synth 8-5858]}} -new_severity "info"
set_msg_config -id {{[Synth 8-4480]}} -limit 1000

# Constraints: board pinout then the design timing exceptions
add_files -fileset constrs_1 -norecurse {(fpga_dir / params.xdc).as_posix()}
add_files -fileset constrs_1 -norecurse {(fpga_dir / FPGA_COMMON_XDC).as_posix()}

# IP cores, generated beforehand into the source tree
read_ip {{ \\
    {tcl_list(str(ip_xci(repo_dir, ip)) for ip in FPGA_IPS)} \\
}}

set_property include_dirs {{ \\
    {tcl_list((repo_dir / d).as_posix() for d in FPGA_INCDIRS)} \\
}} [current_fileset]

read_vhdl {{ \\
    {tcl_list(vhdl)} \\
}}

read_verilog -sv {{ \\
    {tcl_list(verilog)} \\
}}

# Board defines and register macros, included by every source file
read_verilog -sv {{{svh} {registers_svh}}}
set_property -dict {{file_type {{Verilog Header}} is_global_include 1}} \\
    -objects [get_files -of_objects [get_filesets sources_1] \\
        [list "{svh}" "{registers_svh}"]]

set_property top {FPGA_TOP} [current_fileset]
update_compile_order -fileset sources_1

synth_design -rtl -name rtl_1
set_property STEPS.SYNTH_DESIGN.ARGS.RETIMING true [get_runs synth_1]
launch_runs synth_1 -jobs {jobs}
wait_on_run synth_1
open_run synth_1

file mkdir reports
check_timing -verbose \\
    -file reports/{FPGA_TOP}.synth_check_timing.rpt
report_timing -max_paths 100 -nworst 100 -delay_type max -sort_by slack \\
    -file reports/{FPGA_TOP}.synth_timing_WORST_100.rpt
report_utilization -hierarchical \\
    -file reports/{FPGA_TOP}.synth_utilization.rpt
report_cdc \\
    -file reports/{FPGA_TOP}.cdc.rpt
report_clock_interaction \\
    -file reports/{FPGA_TOP}.clock_interaction.rpt

# RuntimeOptimized: the directives the CVA6 FPGA flow has always closed on
set_property "steps.place_design.args.directive" "RuntimeOptimized" [get_runs impl_1]
set_property "steps.route_design.args.directive" "RuntimeOptimized" [get_runs impl_1]

launch_runs impl_1 -jobs {jobs}
wait_on_run impl_1
launch_runs impl_1 -to_step write_bitstream -jobs {jobs}
wait_on_run impl_1
open_run impl_1

# Netlists for a gate level simulation of the FPGA image
write_verilog -force -mode funcsim {FPGA_TOP}_funcsim.v
write_verilog -force -mode timesim {FPGA_TOP}_timesim.v
write_sdf -force {FPGA_TOP}_timesim.sdf

# Post implementation reports, kept alongside the post synthesis ones
check_timing \\
    -file reports/{FPGA_TOP}.check_timing.rpt
report_timing -max_paths 100 -nworst 100 -delay_type max -sort_by slack \\
    -file reports/{FPGA_TOP}.timing_WORST_100.rpt
report_timing -nworst 1 -delay_type max -sort_by group \\
    -file reports/{FPGA_TOP}.timing.rpt
report_utilization -hierarchical \\
    -file reports/{FPGA_TOP}.utilization.rpt

exit
"""


def _cfgmem_tcl(out_dir, board, bit_file, mcs_file):
    """Return the Vivado script turning the bitstream into a flash image."""
    params = board_params(board)
    return f"""\
# Generated by ./cook.py vivado-fpga-build -- do not edit.
open_project {(out_dir / f"{FPGA_TOP}.xpr").as_posix()}
write_cfgmem -format mcs -interface {params.cfgmem_interface} \\
    -size {params.cfgmem_size} \\
    -loadbit "up 0x0 {bit_file.as_posix()}" \\
    -file {mcs_file.as_posix()} -force
exit
"""


def _report_utilization(report, target, util_rpt):
    """
    Record the FPGA resource usage and check it against the baseline.

    A report that cannot be parsed is a warning, never a failure: the
    bitstream is the deliverable of this recipe, and a Vivado release
    changing the layout of its table must not turn a good build into a
    red one.
    """
    report.step("Utilization")

    if not util_rpt.exists():
        report.warning(f"{util_rpt} missing, skipping utilization reporting")
        return

    rows = []
    for match in UTILIZATION_RE.finditer(
        util_rpt.read_text(encoding="utf-8", errors="replace")
    ):
        row = match.groupdict()
        # Past the peripherals subtree the table describes the SoC, not
        # the core.
        if row["instance"] == "i_ariane_peripherals":
            break
        rows.append(row)

    if not rows:
        report.warning(f"No utilization table found in {util_rpt}")
        return

    top = rows[0]
    luts, ffs = int(top["luts"]), int(top["ffs"])
    brams = int(top["ramb36"]) + int(top["ramb18"])

    usage = report.metric("Utilization")
    for row in rows:
        if row["ind"].count(" ") >= UTILIZATION_DEPTH:
            continue
        usage.add_row(
            instance=row["instance"],
            module=row["module"],
            luts=int(row["luts"]),
            ffs=int(row["ffs"]),
            ramb36=int(row["ramb36"]),
            ramb18=int(row["ramb18"]),
            dsp=int(row["dsp"]),
        )
    report.print_metric(usage)

    report.set_label(f"{luts // 1000} kLUTs")

    expected_luts = read_config_expected_value(target, "fpga_luts", report)
    report.kpi("fpga_luts", luts, unit="LUTs", expected=expected_luts, better="lower")
    report.kpi("fpga_ffs", ffs, unit="FFs", better="lower")
    report.kpi("fpga_brams", brams, unit="BRAMs", better="lower")

    if expected_luts is None:
        report.info("No expected LUT count available, skipping utilization check")
        return

    diff = (luts - int(expected_luts)) / int(expected_luts) * 100
    details = (
        f"Expected:  {expected_luts} LUTs\n"
        f"Observed:  {luts} LUTs\n"
        f"Deviation: {diff:.2f} %"
    )
    if abs(diff) > DIFF_UTILIZATION:
        report.error(
            f"LUT count deviation limit exceeded (> {DIFF_UTILIZATION} %)\n\n{details}"
        )
    else:
        report.success(f"LUT count within limits.\n\n{details}")


def _report_timing(report, target, timing_rpt):
    """
    Record the worst negative slack and fail the build on a violation.

    A bitstream that does not meet timing may still program a board and
    boot, so this check is what tells the two apart. As above, a report
    that cannot be parsed only warns.
    """
    report.step("Timing")

    if not timing_rpt.exists():
        report.warning(f"{timing_rpt} missing, skipping timing reporting")
        return

    match = WNS_RE.search(timing_rpt.read_text(encoding="utf-8", errors="replace"))
    if match is None:
        report.warning(f"No slack found in {timing_rpt}, skipping timing check")
        return

    wns = float(match.group(2))
    expected_wns = read_config_expected_value(target, "fpga_wns", report)
    report.kpi("fpga_wns", wns, unit="ns", expected=expected_wns, better="higher")
    report.metric("Timing", {"wns": wns, "verdict": match.group(1)})

    if wns < 0:
        report.error(f"Timing not met: worst negative slack {wns} ns")
    else:
        report.success(f"Timing met: worst slack {wns} ns")


# ==========================================================
# RECIPE
# ==========================================================


@app.command()
def vivado_fpga_build(
    target: str = typer.Option(
        ...,
        "--target",
        "-t",
        help="CVA6 user configuration",
        autocompletion=autocompletion_target,
    ),
    board: FpgaBoard = typer.Option(FpgaBoard.genesys2, help="FPGA board"),
    mcs: bool = typer.Option(False, help="Also generate the .mcs flash image"),
    clean: bool = typer.Option(True, help="Clean working dir before"),
    jobs: int = typer.Option(8, "--jobs", "-j", help="Vivado parallel jobs"),
    quiet: bool = typer.Option(
        False, "--quiet", "-q", help="Suppress output (errors only)"
    ),
):
    """
    Vivado FPGA bitstream generation flow
    """
    report = RecipeReport(
        "vivado-fpga-build",
        title="VIVADO FPGA BUILD",
        context={
            "target": target,
            "board": board,
            "mcs": mcs,
            "clean": clean,
            "jobs": jobs,
        },
        quiet=quiet,
    )

    # Output directory set first: a failure reading the target
    # configuration below must still produce a report. The board is part
    # of the path, two boards yielding two different bitstreams.
    repo_dir = Path.cwd()
    fpga_dir = repo_dir / "corev_apu" / "fpga"
    out_dir = repo_dir / "build" / target / "fpga" / board.value
    report.set_out_dir(out_dir)

    params = board_params(board)
    report.add_context(
        {"part": params.part, "board_part": params.board_part},
        table="Board parameters",
    )

    xlen = _xlen(target, report)
    # The bootloader is built by its own pattern, per board and per width:
    # one ROM serves every target of a width, so it is not rebuilt here.
    bootrom_dir = repo_dir / "build" / "bootrom" / board.value
    bootrom_sv = bootrom_dir / f"bootrom_{xlen}.sv"
    report.add_context({"xlen": xlen})

    # ==========================================================
    # CHECK PREREQUISITES
    # ==========================================================
    report.step("Check prerequisites")

    vivado_path = shutil.which("vivado")
    if vivado_path is not None:
        report.success(f"vivado: {vivado_path}")
    else:
        report.error_exit("vivado: Not found", env=True)

    for name, path in (
        ("board constraints", fpga_dir / params.xdc),
        ("board defines", fpga_dir / params.svh),
        ("design constraints", fpga_dir / FPGA_COMMON_XDC),
    ):
        if not path.exists():
            report.error_exit(f"Missing {name}: {path}", env=True)

    require_prerequisite(
        bootrom_sv,
        f"zero stage bootloader of board '{board.value}' (RV{xlen})",
        f"./cook.py fpga-bootrom -t {target} -c <toolchain> --board {board.value}",
        report=report,
    )
    # The ROM carries the board parameters (memory size, clocks, console
    # baudrate) in its device tree, so one built for another board would
    # produce an image that boots on nothing.
    require_manifest_option(
        read_manifest(bootrom_dir, report),
        "board",
        [board.value],
        f"the bitstream of board '{board.value}' needs a bootloader built for it",
        f"./cook.py fpga-bootrom -t {target} -c <toolchain> --board {board.value}",
        report=report,
        manifest_dir=bootrom_dir,
    )

    report.success("Prerequisites OK")

    # ==========================================================
    # CLEAN
    # ==========================================================
    report.step("Clean")
    if clean:
        try:
            if out_dir.exists():
                shutil.rmtree(out_dir)
                report.info(f"remove {out_dir}")
        except OSError as e:
            report.error_exit(f"Clean error : {e}", env=True)
    else:
        report.info(f"Skip cleaning {out_dir}")

    out_dir.mkdir(parents=True, exist_ok=True)
    report.info(f"create {out_dir}")

    # ==========================================================
    # IP CORES
    # ==========================================================
    # The IP projects live in the source tree and survive a build/
    # removal, so an already generated IP is reused: regenerating the
    # nine of them is several Vivado invocations for an unchanged result.
    # What counts as generated is the synthesized checkpoint, not the
    # definition: see ip_is_generated().
    report.step("Generate IP cores")

    ip_env = {
        "XILINX_PART": params.part,
        "XILINX_BOARD": params.board_part,
        "BOARD": board.value,
    }
    ip_results = report.metric("IP cores")
    for ip_name in FPGA_IPS:
        if ip_is_generated(repo_dir, ip_name):
            report.info(f"{ip_name}: already generated")
            ip_results.add_row(status="pass", ip=ip_name, state="cached")
            continue
        # An IP left half generated by an earlier failed run would make
        # `create_ip` refuse to redefine it, so the stale definition goes
        # first.
        if ip_xci(repo_dir, ip_name).exists():
            report.warning(
                f"{ip_name}: definition without checkpoint "
                f"(previous generation failed), regenerating"
            )
            run_cmd(
                cmd=["make", "clean"],
                report=report,
                cwd=ip_dir(repo_dir, ip_name),
                env=None,
                error_patterns=None,
                warning_patterns=None,
                highlight_patterns=None,
                log_file=out_dir / f"ip_{ip_name}_clean.log",
                timeout=300,
                check=False,
                capture_output=False,
            )
        report.info(f"{ip_name}: generating")
        run_cmd(
            cmd=["vivado", "-nojournal", "-mode", "batch", "-source", "tcl/run.tcl"],
            report=report,
            cwd=ip_dir(repo_dir, ip_name),
            env=ip_env,
            error_patterns=["^ERROR:"],
            warning_patterns=["^CRITICAL WARNING:"],
            highlight_patterns=None,
            log_file=out_dir / f"ip_{ip_name}.log",
            timeout=1800,
            check=False,
            capture_output=False,
        )
        if ip_is_generated(repo_dir, ip_name):
            ip_results.add_row(status="pass", ip=ip_name, state="generated")
        else:
            # Tell a definition that was never written from one whose
            # synthesis failed: the second means the IP was configured
            # correctly and the run itself was refused (licence, part).
            state = "no checkpoint" if ip_xci(repo_dir, ip_name).exists() else "missing"
            ip_results.add_row(status="fail", ip=ip_name, state=state)
            report.analyze_log(
                out_dir / f"ip_{ip_name}.log",
                name=f"ip_{ip_name}.log analysis",
                error_patterns=["^ERROR:"],
                env_patterns=[
                    r"(license|licence).*(error|fail|unable|denied|expired)",
                    r"A valid license was not found",
                    r"unable to checkout",
                    r"command not found",
                ],
                fail_on_error=False,
            )
    report.print_metric(ip_results)
    if ip_results.failed:
        report.error_exit("IP core generation failed")
    report.success(f"{len(FPGA_IPS)} IP core(s) available")

    # ==========================================================
    # GENERATE TCL
    # ==========================================================
    report.step("Generate build.tcl")

    rtl_files = read_config_or_exit_flist(
        target, report, filename="Flist.cva6_fpga", repo_dir=repo_dir
    )
    report.info(f"{len(rtl_files)} RTL file(s) read from Flist.cva6_fpga")

    tcl = _build_tcl(out_dir, repo_dir, target, board, jobs, bootrom_sv, rtl_files)
    script_file = out_dir / "build.tcl"
    script_file.write_text(tcl, encoding="utf-8")
    report.info(f"build.tcl generated at {script_file}")

    # ==========================================================
    # LAUNCH VIVADO
    # ==========================================================
    report.step("Launch Vivado")

    log_file = out_dir / "vivado.log"

    run_cmd(
        cmd=["vivado", "-nojournal", "-mode", "batch", "-source", "build.tcl"],
        report=report,
        cwd=out_dir,
        env=None,
        error_patterns=["^ERROR:|^CRITICAL WARNING:"],
        warning_patterns=["^WARNING:"],
        highlight_patterns=["^INFO: \\[Vivado"],
        log_file=log_file,
        timeout=28800,
        check=False,
        capture_output=False,
    )

    report.analyze_log(
        log_file,
        name="vivado.log analysis",
        error_patterns=["^ERROR:", "^CRITICAL WARNING:"],
        warning_patterns=["^WARNING:"],
        env_patterns=[
            r"(license|licence).*(error|fail|unable|denied|expired)",
            r"unable to checkout",
            r"command not found",
        ],
        fail_on_error=False,
    )

    # Vivado writes the bitstream in the implementation run directory
    bit_file = out_dir / f"{FPGA_TOP}.bit"
    impl_bit = out_dir / f"{FPGA_TOP}.runs" / "impl_1" / f"{FPGA_TOP}.bit"
    if impl_bit.exists():
        shutil.copyfile(impl_bit, bit_file)
        report.success(f"Bitstream generated: {bit_file}")
    else:
        report.error_exit(f"Bitstream not generated: {impl_bit}")

    # ==========================================================
    # FLASH IMAGE
    # ==========================================================
    mcs_file = out_dir / f"{FPGA_TOP}.mcs"
    if mcs:
        report.step("Generate flash image")
        cfgmem_script = out_dir / "write_cfgmem.tcl"
        cfgmem_script.write_text(
            _cfgmem_tcl(out_dir, board, bit_file, mcs_file), encoding="utf-8"
        )
        run_cmd(
            cmd=[
                "vivado",
                "-nojournal",
                "-mode",
                "batch",
                "-source",
                "write_cfgmem.tcl",
            ],
            report=report,
            cwd=out_dir,
            env=None,
            error_patterns=["^ERROR:"],
            warning_patterns=["^CRITICAL WARNING:"],
            highlight_patterns=None,
            log_file=out_dir / "write_cfgmem.log",
            timeout=1800,
            check=False,
            capture_output=False,
        )
        if mcs_file.exists():
            report.success(f"Flash image generated: {mcs_file}")
        else:
            report.error(f"Flash image not generated: {mcs_file}")

    # ==========================================================
    # REPORTING
    # ==========================================================
    reports_dir = out_dir / "reports"
    _report_utilization(report, target, reports_dir / f"{FPGA_TOP}.utilization.rpt")
    _report_timing(report, target, reports_dir / f"{FPGA_TOP}.timing.rpt")

    # ==========================================================
    # BUILD MANIFEST
    # ==========================================================
    write_manifest(
        out_dir,
        "vivado-fpga-build",
        {
            "target": target,
            "board": board,
            "xlen": xlen,
            "part": params.part,
            "board_part": params.board_part,
            "bootrom_sv": str(bootrom_sv.relative_to(repo_dir)),
            "mcs": mcs,
        },
        report=report,
    )

    # ==========================================================
    # List
    # ==========================================================
    report.step("Generated files")
    gen_files = [
        bit_file,
        mcs_file,
        script_file,
        log_file,
        reports_dir / f"{FPGA_TOP}.utilization.rpt",
        reports_dir / f"{FPGA_TOP}.timing.rpt",
        reports_dir / f"{FPGA_TOP}.timing_WORST_100.rpt",
        reports_dir / f"{FPGA_TOP}.check_timing.rpt",
        reports_dir / f"{FPGA_TOP}.cdc.rpt",
        reports_dir / f"{FPGA_TOP}.clock_interaction.rpt",
    ]
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
