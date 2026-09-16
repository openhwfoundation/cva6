# Copyright 2026 Thales France
#
# Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
# You may obtain a copy of the License at https://solderpad.org/licenses/
#
# Original Author: Yannick Casamatta (yannick.casamatta@thalesgroup.com)

# Please refer to flows/README.md to add target

import csv
from pathlib import Path
import shutil
from enum import Enum
import re
from functools import reduce
import yaml
import typer
import plotly.graph_objects as go
from flows.utils.config_loader import load_techno_config
from flows.utils.manifest import write_manifest
from flows.utils.recipe_report import RecipeReport
from flows.utils.run_cmd import run_cmd
from flows.utils.autocompletion import (
    TechnoOption,
    autocompletion_target,
)
from flows.utils.target_config import (
    read_config_or_exit_flist,
    read_config_or_exit_testbench_cfg,
    read_config_expected_value,
    top_elaborate as get_top_elaborate,
)

app = typer.Typer()

# Gate count deviation tolerance vs config/target/<target>/expected_values.yml
DIFF_GATES = 250

# Columns of the hierarchical area CSV (graph generation)
CSV_COLUMNS_AREA = [
    "hier0",
    "hier1",
    "hier2",
    "hier3",
    "hier4",
    "hier5",
    "hier6",
    "hier7",
    "hier8",
    "areaTot",
    "P100Tot",
    "Combi",
    "NonCombi",
    "BlackBox",
    "InstanceName",
]


class PreProcOption(str, Enum):
    HPDCACHE_ASSERT_OFF = "HPDCACHE_ASSERT_OFF"
    RVFI_ENABLE = "RVFI_ENABLE"


# ==========================================================
# RECIPE
# ==========================================================


@app.command()
def dc_shell_synth(
    target: str = typer.Option(
        ...,
        "--target",
        "-t",
        help="CVA6 user configuration",
        autocompletion=autocompletion_target,
    ),
    techno: TechnoOption = typer.Option(
        ..., help="Techno defined in $CONFIG_DIR/techno.yml"
    ),
    period: str = typer.Option(..., help="Synthesis target period"),
    script_file: str = typer.Option("dc.tcl", help="dc setup script"),
    preprocessor_defines: list[PreProcOption] = typer.Option(
        [PreProcOption.HPDCACHE_ASSERT_OFF], "--define", help="Preprocessor directives"
    ),
    clean: bool = typer.Option(True, help="Clean working dir before"),
    quiet: bool = typer.Option(
        False, "--quiet", "-q", help="Suppress output (errors only)"
    ),
):
    """
    DC Shell Synthesis flow
    """
    define_one_string = (
        "{ " + reduce(lambda a, b: f"{a}, {b}", preprocessor_defines) + " }"
    )

    report = RecipeReport(
        "dc-shell-synth",
        title="Dc shell synthesis flow",
        context={
            "target": target,
            "techno": techno,
            "period": period,
            "script_file": script_file,
            "preprocessor_defines": preprocessor_defines,
            "clean": clean,
        },
        quiet=quiet,
    )

    # Output directory set first: a failure reading the target
    # configuration below must still produce a report.
    repo_dir = Path.cwd()
    synth_dir = repo_dir / "build" / target / "synthesis"
    report.set_out_dir(synth_dir)

    # Get testbench config
    cva6_hier = read_config_or_exit_testbench_cfg(target, report)

    # Get config
    #
    TECHNO_DATA = load_techno_config()
    techno = TECHNO_DATA[techno.value]

    report.add_context(techno, table="Techno parameters")

    # Test tools in path
    dc_shell_path = shutil.which("dc_shell")
    if dc_shell_path is not None:
        report.success(f"dc_shell: {dc_shell_path}")
    else:
        report.error_exit("dc_shell: Not found", env=True)

    # Create files and folder paths
    rm_flow = repo_dir / "RM_FLOW" / "synth"

    # ==========================================================
    # CLEAN
    # ==========================================================
    report.step("Clean")
    if clean:
        try:
            if synth_dir.exists():
                shutil.rmtree(synth_dir)
                report.info(f"remove {synth_dir}")
        except Exception as e:
            report.error_exit(f"Clean error : {e}", env=True)
    else:
        report.info(f"Skip cleaning {synth_dir}")

    synth_dir.mkdir(parents=True, exist_ok=True)
    report.info(f"create {synth_dir}")

    # print config in synth_dir
    with open(synth_dir / "build_config.yaml", "w", encoding="utf-8") as f:
        yaml.dump(techno, f, default_flow_style=False)
        print("Generated file : ", synth_dir / "build_config.yaml")

    # ==========================================================
    # CUSTOMIZE WITH OPTIONS
    # ==========================================================

    top_elaborate = get_top_elaborate(cva6_hier)

    # ==========================================================
    # ENV VARIABLES (passed to run_cmd only)
    # ==========================================================

    env_vars = {
        "TOP": "cva6_top",
        "TOP_ELABORATE": top_elaborate,
        "TOP_SYNTHESIS": "cva6_top__*",
        "TARGET": target,
        "TARGET_CFG": target,
        # .as_posix(): these paths are consumed by TCL scripts (dc.tcl) where
        # backslashes are escape characters; TCL on Windows accepts "/" natively
        "CVA6_REPO_DIR": repo_dir.as_posix(),
        "HPDCACHE_DIR": (repo_dir / "core/cache_subsystem/hpdcache").as_posix(),
        "PERIOD": period,
        "TOP_LIB": "ariane_lib",
        "IP_LIST": "",
        "DC_FILE": "",
        "LIST_FF": "ON",
        "LIST_CKG": "OFF",
        "FF_DETAILS": "OFF",
        "FAST_SYNTH": "OFF",
        "TERM": "vt100",
        "SCRIPTS_DIR": "",
        "SNPSLMD_QUEUE": "TRUE",
    }

    env_vars |= techno

    # ==========================================================
    # GENERATE FLIST FOR DC_SHELL
    # ==========================================================
    report.step("Generate Flist.cva6_synth")

    rtl_files = read_config_or_exit_flist(target, report)
    analyse_files = [
        f"analyze -f sverilog -lib ariane_lib -define {define_one_string} {f}\n"
        for f in rtl_files
    ]

    # Write Flist.cva6_synth in rm_flow dir
    (rm_flow / "Flist.cva6_synth").write_text("".join(analyse_files))

    # ==========================================================
    # CUSTOMIZE WITH OPTIONS
    # ==========================================================

    options = [
        "-no_gui",
        "-no_log",
        "-topographical_mode",
        "-f",
        f"{rm_flow / 'rm_dc_scripts' / script_file}",
    ]

    # ==========================================================
    # BUILD DC_SHELL COMMAND
    # ==========================================================

    dc_cmd = ["dc_shell"]
    dc_cmd += options

    # ==========================================================
    # LAUNCH DC_SHELL COMMAND
    # ==========================================================
    report.step("Launch dc_shell")

    log_file = synth_dir / "synthesis.log"

    run_cmd(
        cmd=dc_cmd,
        cwd=rm_flow,
        env=env_vars,
        error_patterns=["^Error:|^RM-Error"],
        warning_patterns=None,
        highlight_patterns=["^RM-Info"],
        log_file=log_file,
        timeout=6000,
        check=False,
        capture_output=False,
        report=report,
    )

    # ==========================================================
    # Post-process netlist/sdf/spef
    # ==========================================================
    report.step("Post-process netlist/reports")

    top = env_vars["TOP"]
    TARGET = env_vars["TARGET"]
    TECH_NAME = env_vars["TECH_NAME"]
    SCENARIO_SYNTH = techno["SCENARIO_SYNTH_NAME"]
    SCENARIO_POWER = env_vars["SCENARIO_POWER_NAME"]

    files_to_post_process = [
        # (src, dest)
        (
            synth_dir / "netlist" / f"{top}_{TARGET}_{TECH_NAME}_synth.v",
            synth_dir / "netlist" / "synth.v",
        ),
        (
            synth_dir
            / "netlist"
            / f"{top}_{TARGET}_{TECH_NAME}_synth.{SCENARIO_SYNTH}.sdf",
            synth_dir / "netlist" / "wc_timing.sdf",
        ),
        (
            synth_dir
            / "netlist"
            / f"{top}_{TARGET}_{TECH_NAME}_synth.{SCENARIO_POWER}.sdf",
            synth_dir / "netlist" / "wc_power.sdf",
        ),
        (
            synth_dir
            / "netlist"
            / f"{top}_{TARGET}_{TECH_NAME}_synth.{SCENARIO_POWER}.spef",
            synth_dir / "netlist" / "wc_power.spef",
        ),
        (
            synth_dir / "reports" / f"{top}_{TARGET}_{TECH_NAME}_synth_area.rpt",
            synth_dir / "reports" / "synth_area.rpt",
        ),
    ]

    for src, dst in files_to_post_process:
        if src.exists():
            # sed "s/${TOP}__[0-9]\+/${TOP}/g"
            with src.open("r") as f_in, dst.open("w") as f_out:
                for line in f_in:
                    f_out.write(re.sub(rf"{top}__\d+", top, line))

        else:
            report.error(f"{src} missing")

    report.analyze_log(
        log_file,
        name="synthesis.log analysis",
        error_patterns=["^Error:", "^RM-Error"],
        warning_patterns=["Warning: "],
        ignore_patterns=[
            "TFCHK-014",
            "TFCHK-012",
            "TFCHK-049",
            "MV-021",
            "MV-028",
            "TLUP-004",
            "TLUP-005",
            "TIM-164",
            "PWR-890",
            "PWR-80",
            "OPT-1413",
        ],
        env_patterns=[
            r"(license|licence).*(error|fail|unable|denied|expired)",
            r"unable to checkout",
            r"command not found",
        ],
        fail_on_error=False,
    )

    # Write Flist.libverilog to help compile step
    (synth_dir / "Flist.libverilog").write_text(env_vars["LIB_VERILOG"])

    # ==========================================================
    # BUILD MANIFEST
    # ==========================================================
    write_manifest(
        synth_dir,
        "dc-shell-synth",
        {
            "target": target,
            "techno": techno.get("TECH_NAME", None),
            "period": period,
            "script_file": script_file,
            "preprocessor_defines": preprocessor_defines,
        },
        report=report,
    )

    # ==========================================================
    # Reporting area
    # ==========================================================
    report.step("Area reporting")

    NAND2_AREA = int(env_vars["NAND2_AREA"])

    pattern_global_val = re.compile(
        r"^(Combinational area|Buf/Inv area|Noncombinational area|Macro/Black Box area):\ *(\d*\.\d*)$",
        re.MULTILINE,
    )
    pattern_hier = re.compile(
        r"^(\w*(?:\/\w*){0,2})\ *(\d*\.\d*)\ *(\d*\.\d*)\ *(\d*\.\d*)\ *(\d*\.\d*)\ *(\d*\.\d*)\ *(\w*)$",
        re.MULTILINE,
    )

    try:
        with (synth_dir / "reports" / "synth_area.rpt").open("r") as f:
            log = f.read()
            global_val = pattern_global_val.findall(log)
            hier = pattern_hier.findall(log)
    except Exception as e:
        report.error_exit(f"Error process log: {e}", env=True)

    total_area = float(hier[0][1])
    kgates = total_area / NAND2_AREA

    # Global results: pure values (area breakdown as percentages)
    global_metric = {"Total area (kGates)": round(kgates, 2)}
    global_fmt = {}
    for name, area in global_val:
        rel_area = 0.0 if total_area == 0 else float(area) / total_area * 100
        global_metric[name] = round(rel_area, 1)
        global_fmt[name] = "pct"

    report.metric("Global results", global_metric, fmt=global_fmt)
    report.set_label(f"{kgates:.2f} kGates")

    # Area per hierarchy: pure rows (also the donut chart data source)
    hier_metric = report.metric("Hierarchies details", fmt={"pct": "pct"})
    for row in hier:
        hier_metric.add_row(
            hierarchy=row[0],
            kgates=round(float(row[1]) / NAND2_AREA, 2),
            pct=round(float(row[2]), 2),
        )
    report.print_metric(hier_metric)

    # ==========================================================
    # Gate count check vs expected values
    # ==========================================================
    report.step("Gate count check")

    gates = int(kgates * 1000)
    expected_gates = read_config_expected_value(target, "gates", report)

    report.kpi(
        "gates",
        gates,
        unit="gates",
        expected=int(expected_gates) if expected_gates is not None else None,
        better="lower",
    )

    if expected_gates is None:
        report.info("No expected gate count available, skipping gate count check")
    else:
        diff = gates - int(expected_gates)
        if abs(diff) >= DIFF_GATES:
            report.error(
                f"Gate count deviation limit exceeded (>= {DIFF_GATES} gates)\n\n"
                f"Expected:  {expected_gates} gates\n"
                f"Observed:  {gates} gates\n"
                f"Delta:     {diff} gates"
            )
        else:
            report.success(
                f"Gate count validation passed successfully.\n\n"
                f"Expected:  {expected_gates} gates\n"
                f"Observed:  {gates} gates ({kgates:.2f} kGates)\n"
                f"Delta:     {diff} gates"
            )

    # ==========================================================
    # Area graph (sunburst)
    # ==========================================================
    report.step("Area graph")

    area_csv = synth_dir / "reports" / "synth_area.csv"
    area_html = synth_dir / "reports" / "synth_area.html"

    try:
        hier_deep_pattern = re.compile(
            r"(?P<hier0>[\w\d]+)(/(?P<hier1>[\w\d]+))?(/(?P<hier2>[\w\d]+))?"
            r"(/(?P<hier3>[\w\d]+))?(/(?P<hier4>[\w\d]+))?(/(?P<hier5>[\w\d]+))?"
            r"(/(?P<hier6>[\w\d]+))?(/(?P<hier7>[\w\d]+))?(/(?P<hier8>[\w\d]+))?"
            r"\s+(?P<areaTot>[\d.]+)\s+(?P<P100Tot>[\d.]+)\s+(?P<Combi>[\d.]+)"
            r"\s+(?P<NonCombi>[\d.]+)\s+(?P<BlackBox>[\d.]+)\s+(?P<InstanceName>[\w\d]+)"
        )
        dict_data = [m.groupdict() for m in hier_deep_pattern.finditer(log)]

        with area_csv.open("w", newline="", encoding="utf-8") as csvfile:
            writer = csv.DictWriter(csvfile, fieldnames=CSV_COLUMNS_AREA)
            writer.writeheader()
            for data in dict_data:
                writer.writerow(data)

        labels, values, parents, ids = [], [], [], []
        for elm in dict_data:
            i = 0
            while i < 8 and elm.get(CSV_COLUMNS_AREA[i + 1]) is not None:
                i += 1

            if elm.get("areaTot") and float(elm["areaTot"]) / NAND2_AREA > 0.001:
                labels.append(elm[CSV_COLUMNS_AREA[i]])
                values.append(float(elm["areaTot"]) / NAND2_AREA)

                ids_name = ""
                parents_name = ""

                if i == 0:
                    ids_name = labels[-1]
                    parents_name = (
                        ""
                        if elm[CSV_COLUMNS_AREA[i]] == top_elaborate
                        else top_elaborate
                    )
                else:
                    for j in range(i + 1):
                        ids_name += str(elm.get(CSV_COLUMNS_AREA[j], ""))
                    for j in range(i):
                        parents_name += str(elm.get(CSV_COLUMNS_AREA[j], ""))

                parents.append(parents_name)
                ids.append(ids_name)

        fig = go.Figure(
            data=[
                go.Sunburst(
                    ids=ids,
                    labels=labels,
                    parents=parents,
                    values=values,
                    branchvalues="total",
                )
            ]
        )
        fig.write_html(area_html)
        report.info(f"CSV file:   {area_csv}\nHTML file:  {area_html}")
    except ImportError as e:
        report.warning(f"plotly not available, skipping area graph: {e}")
    except Exception as e:
        report.warning(f"Area graph generation failed: {e}")

    # ==========================================================
    # List
    # ==========================================================
    report.step("Generated files")
    gen_files = [
        log_file,
        synth_dir / "warnings.log",
        synth_dir / "errors.log",
        synth_dir / "Flist.libverilog",
        synth_dir / "reports" / "synth_area.rpt",
        synth_dir / "reports" / "synth_area.csv",
        synth_dir / "reports" / "synth_area.html",
        synth_dir / "netlist" / "synth.v",
        synth_dir / "netlist" / "wc_timing.sdf",
        synth_dir / "netlist" / "wc_power.sdf",
        synth_dir / "netlist" / "wc_power.spef",
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
