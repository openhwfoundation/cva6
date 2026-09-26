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
import tempfile
import typer
from flows.utils.config_loader import load_techno_config, load_compiler_config
from flows.utils.run_cmd import run_cmd
from flows.utils.recipe_report import RecipeReport
from flows.utils.docs_manual import (
    ASCIIDOCTOR_REQUIRES,
    asciidoctor_cmd,
    asciidoctor_found,
)

app = typer.Typer()


# ==========================================================
# RECIPE - Self check
# ==========================================================


@app.command()
def self_check(
    quiet: bool = typer.Option(
        False, "--quiet", "-q", help="Suppress output (errors only)"
    ),
):
    """
    Self check
    """

    TECHNO_DATA = load_techno_config()
    COMPILER_DATA = load_compiler_config()

    report = RecipeReport(
        "self-check",
        out_dir=Path.cwd() / "build" / "self_check",
        title="Self check",
        context={},
        quiet=quiet,
    )

    report.step("Tools in path")

    # A workstation is not expected to hold every CAD tool: the flows offer
    # alternatives (four simulators) and optional steps (synthesis, STA), so
    # a missing tool is only reported as a warning. What must fail is having
    # *no* simulator at all, checked after the loop.
    tools = [
        ("vcs", "VCS - Synopsys simulator"),
        ("verdi", "Verdi - Synopsys debug"),
        ("xrun", "Xcelium - Cadence simulator"),
        ("vsim", "Questa/ModelSim - Siemens simulator"),
        ("vlog", "Questa/ModelSim - Verilog compiler"),
        ("vopt", "Questa/ModelSim - Optimizer"),
        ("verilator", "Verilator - open-source simulator, TestHarness only"),
        ("dc_shell", "Design Compiler - Synopsys synthesis"),
        ("pt_shell", "PrimeTime - Synopsys STA"),
        ("aipk_read", "Spyglass - Synopsys static analysis"),
        ("aipk_run", "Spyglass - Synopsys static analysis"),
        ("vivado", "Vivado - AMD/Xilinx FPGA synthesis"),
        ("vivado_lab", "Vivado Lab - AMD/Xilinx board programming"),
        ("quartus_sh", "Quartus Prime Pro - Intel/Altera FPGA synthesis"),
        ("qsys-script", "Platform Designer - Intel/Altera IP generation"),
        ("quartus_pgm", "Quartus Programmer - Intel/Altera board programming"),
        ("dtc", "Device tree compiler - FPGA bootloader"),
        ("asciidoctor", "AsciiDoctor - documentation specifications"),
        ("wavedrom-cli", "WaveDrom - register diagrams of the RISC-V manuals"),
        ("bytefield-svg", "Bytefield - bit field diagrams of the RISC-V manuals"),
        ("sphinx-build", "Sphinx - documentation user manual"),
        ("verible-verilog-format", "Verible - RTL formatter"),
        ("black", "Black - Python formatter"),
        ("pylint", "Pylint - Python linter"),
    ]

    # Verilator runs the TestHarness only, but that is a simulation too.
    simulators = ("vcs", "xrun", "vsim", "verilator")

    tool_results = report.metric("Tools in path")
    found = set()

    for tool_name, description in tools:
        tool_path = shutil.which(tool_name)
        if tool_path is not None:
            found.add(tool_name)
            report.success(f"{tool_name} ({description}): {tool_path}")
            tool_results.add_row(
                tool=tool_name, description=description, path=tool_path
            )
        else:
            report.warning(f"{tool_name} ({description}): Not found")
            tool_results.add_row(tool=tool_name, description=description, path="")

    if not found.intersection(simulators):
        report.error(
            f"No simulator in path (one of {', '.join(simulators)} is required)",
            env=True,
        )

    report.step("AsciiDoctor extensions")

    # The only check that is not a lookup: the extensions are loaded by
    # asciidoctor at startup, from where Ruby looks rather than from the
    # path, so one installed under a GEM_PATH the site overrides is found
    # by neither `which` nor the renderer. Rendering a probe document is
    # what tells them apart; `--version` answers before loading anything.
    #
    # A warning, like the tools above: only the RISC-V specifications need
    # them, the CVA6 design manual and the user manual do not.
    if asciidoctor_found("asciidoctor") is None:
        report.warning("asciidoctor: Not found, the specifications cannot be rendered")
    else:
        gem_results = report.metric("AsciiDoctor extensions")
        with tempfile.TemporaryDirectory() as tmp:
            probe = Path(tmp) / "probe.adoc"
            probe.write_text("= Probe\n\ncontent\n", encoding="utf-8")
            for gem in ASCIIDOCTOR_REQUIRES:
                output = run_cmd(
                    cmd=asciidoctor_cmd("asciidoctor")
                    + [
                        "--require",
                        gem,
                        "-o",
                        str(Path(tmp) / "probe.html"),
                        str(probe),
                    ],
                    report=report,
                    check=False,
                    capture_output=True,
                    log_file=None,
                    timeout=120,
                )
                loaded = "could not be loaded" not in output
                if loaded:
                    report.success(f"{gem}: loads")
                else:
                    report.warning(
                        f"{gem}: not loadable by asciidoctor "
                        f"(installed where Ruby does not look?)"
                    )
                gem_results.add_row(extension=gem, status="loads" if loaded else "")

    report.step("Spike installation (mandatory for tandem verification)")

    path = [
        "./tools/spike/bin",
        "./tools/spike/lib",
    ]

    for p in path:
        if Path(p).exists():
            report.success(f"{p}: exist")
        else:
            report.error(
                f"{p}: Not found see verif/regress/install-spike (MANDATORY)",
                env=True,
            )

    # Submodules
    report.step("Submodules of CVA6 repositoy")

    result = run_cmd(
        cmd=["git", "submodule", "status", "--recursive"],
        cwd=None,
        env=None,
        error_patterns=None,
        warning_patterns=None,
        highlight_patterns=None,
        log_file=None,
        timeout=90,
        check=False,
        capture_output=True,
        report=report,
    )

    for line in result.split("\n"):
        if line.startswith("-"):
            report.error(f"{line}: Submodule not initialised", env=True)
        else:
            report.success(f"{line}: Submodule initialised")

    # riscv-tests
    report.step("riscv-tests installation")

    path = [
        "./verif/tests/riscv-tests",
    ]

    for p in path:
        if Path(p).exists():
            report.success(f"{p}: exist")
        else:
            report.error(
                f"{p}: Not found, see verif/regress/install-riscv-tests (MANDATORY)",
                env=True,
            )

    # riscv-compliance
    report.step("riscv-compliance installation")

    path = [
        "./verif/tests/riscv-compliance",
    ]

    for p in path:
        if Path(p).exists():
            report.success(f"{p}: exist")
        else:
            report.warning(f"{p}: Not found, see verif/regress/install-compliance")

    report.step("riscv-arch-test installation")

    # riscv-arch-test
    path = [
        "./verif/tests/riscv-arch-test",
    ]

    for p in path:
        if Path(p).exists():
            report.success(f"{p}: exist")
        else:
            report.warning(f"{p}: Not found, see verif/regress/install-arch-test")

    report.step("Specific organisation configuration files")

    # Get organisation techno config (asic)
    techno_data = TECHNO_DATA

    report.param_table(
        techno_data,
        "Techno parameters",
    )

    # Get organisation compiler config
    compiler_data = COMPILER_DATA

    report.param_table(
        compiler_data,
        "Compiler parameters",
    )

    report.end("Completed")
