# Copyright 2026 Thales France
#
# Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
# You may obtain a copy of the License at https://solderpad.org/licenses/
#
# Original Author: Guillaume Chauvon

# Please refer to flows/README.md to add target

from pathlib import Path
import shutil
import typer
from flows.utils.manifest import (
    write_manifest,
    read_manifest,
    require_prerequisite,
    get_manifest_option,
)
from flows.utils.recipe_report import RecipeReport
from flows.utils.run_cmd import run_cmd
from flows.utils.tandem import spike_broken_extensions
from flows.utils.target_config import target_dir
from flows.utils.autocompletion import (
    autocompletion_target,
    autocompletion_testname_compiled,
)

app = typer.Typer()


# ==========================================================
# RECIPE - RUN SPIKE SIMULATION
# ==========================================================


@app.command()
def spike_run(
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
    quiet: bool = typer.Option(
        False, "--quiet", "-q", help="Suppress output (errors only)"
    ),
):
    """
    VCS UVM run simulation flow
    """

    report = RecipeReport(
        "spike-run",
        title="SPIKE SIMULATION",
        context={
            "target": target,
            "test_name": test_name,
        },
        quiet=quiet,
    )

    # Mode dir
    inout_dir = "sim_spike"

    # Create files and folder paths
    repo_dir = Path.cwd()
    build_root = repo_dir / "build" / target
    compile_dir = build_root / "compile" / test_name
    simulation_dir = build_root / "simulation" / inout_dir / test_name
    report.set_out_dir(simulation_dir)

    spike_dir = repo_dir / "tools" / "spike"
    spike_bin = spike_dir / "bin" / "spike"
    spike_lib = spike_dir / "lib"

    # ==========================================================
    # CHECK PREREQUISITES
    # ==========================================================
    report.step("Check prerequisites")

    require_prerequisite(
        spike_bin,
        "SPIKE simulator binary",
        "./cook.py git-dependencies",
        report=report,
    )

    require_prerequisite(
        compile_dir / f"{test_name}.elf",
        f"compiled software for test '{test_name}'",
        f"./cook.py sw-compile -t {target} -c <toolchain> --out {test_name} <sources>",
        report=report,
    )

    # Spike parameters of the target: passed to --param-file below. Checked
    # here rather than left to Spike, which reports it as a parameter error
    # instead of a missing target configuration file.
    spike_param_file = target_dir(target) / "spike.yaml"
    require_prerequisite(
        spike_param_file,
        f"Spike parameters of target '{target}'",
        f"add config/target/{target}/spike.yaml (see another target for the format)",
        report=report,
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
        report.error_exit(f"Clean error: {e}", env=True)

    simulation_dir.mkdir(parents=True, exist_ok=True)
    report.info(f"create {simulation_dir}")

    # ==========================================================
    # OPTIONS
    # ==========================================================

    # The ISA the test was compiled with (march of the sw-compile
    # manifest) must not contain an extension known to be incompatible
    # with the current Spike version (see SPIKE_TANDEM_BROKEN_EXTENSIONS):
    # the Spike behavior would be unreliable. Do not run Spike at all.
    compile_manifest = read_manifest(compile_dir, report)
    tandem_broken = spike_broken_extensions(
        get_manifest_option(compile_manifest, "march", "")
    )
    if tandem_broken:
        report.error_exit(
            "Spike run disabled: ISA extension(s) "
            f"{', '.join(tandem_broken)} incompatible with the current Spike",
            env=True,
        )

    env_vars = {"LD_LIBRARY_PATH": f"{spike_lib}"}

    elf = compile_dir / f"{test_name}.elf"

    options = [
        "--steps=2000000",
        "--log-commits",
        "--param-file",
        f"{spike_param_file}",
        "-l",
        f"{elf}",
    ]

    # ==========================================================
    # BUILD SPIKE COMMAND
    # ==========================================================

    spike_cmd = [str(spike_bin)]
    spike_cmd += options

    # ==========================================================
    # LAUNCH SIMV
    # ==========================================================
    report.step("Run SPIKE simulation")

    log_file = simulation_dir / "simulation.log"

    run_cmd(
        cmd=spike_cmd,
        report=report,
        cwd=simulation_dir,
        env=env_vars,
        error_patterns=["(ERROR|Error|No such file or directory)"],
        warning_patterns=["(WARNING|Warning)"],
        highlight_patterns=None,
        log_file=log_file,
        timeout=3000,
        check=False,
        capture_output=False,
    )

    # ==========================================================
    # POST PROCESS LOGS
    # ==========================================================

    # tohost address extracted at compile time (sw-compile manifest)
    symbols = get_manifest_option(compile_manifest, "symbols", {})
    add_tohost = symbols.get("tohost")

    found = 0
    if add_tohost is not None:
        try:
            with log_file.open("r") as f_in:
                lines = f_in.readlines()
            last_line = lines[-1].strip()
            last_line_words = last_line.split()
            tohost = last_line_words[-2]
            return_val = last_line_words[-1]
            if tohost[2:] == add_tohost:
                if return_val[2:] == "00000001":
                    report.success(
                        f"Spike ended with value {return_val[2:]} in tohost ({add_tohost})",
                    )
                    found = 1
                else:
                    report.error(
                        f"Spike ended with value {return_val[2:]} in tohost ({add_tohost})",
                    )
                    found = 1
            else:
                report.error(
                    f"Spike did not end with write in tohost ({add_tohost}): {tohost[2:]}",
                )
                found = 1
        except Exception as e:
            report.error(f"Error process log: {e}", env=True)
    else:
        report.error(
            f"No tohost symbol recorded in the sw-compile manifest of {compile_dir}",
            env=True,
        )

    if found == 0:
        report.error("Simulation status unknown")

    report.analyze_log(
        log_file,
        error_patterns=["(ERROR|Error)"],
        warning_patterns=["(WARNING|Warning)"],
        env_patterns=["No such file or directory", "command not found"],
        fail_on_error=False,
    )

    # ==========================================================
    # BUILD MANIFEST
    # ==========================================================
    write_manifest(
        simulation_dir,
        "spike-run",
        {
            "target": target,
            "test_name": test_name,
        },
        report=report,
    )

    # ==========================================================
    # List
    # ==========================================================
    report.step("Generated files")
    gen_files = [
        simulation_dir / "simulation.log",
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
