# Copyright 2026 Thales France
#
# Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
# You may obtain a copy of the License at https://solderpad.org/licenses/
#
# Original Author: Yannick Casamatta (yannick.casamatta@thalesgroup.com)

# Please refer to flows/README.md to add target

import os
from pathlib import Path
import re
import shutil
import typer
from flows.utils.config_loader import load_techno_config, load_compiler_config
from flows.utils.run_cmd import run_cmd
from flows.utils.tmp_dir import scratch_dir
from flows.utils.recipe_report import RecipeReport
from flows.utils.docs_manual import (
    ASCIIDOCTOR_REQUIRES,
    asciidoctor_cmd,
    asciidoctor_found,
)

app = typer.Typer()

# Command printing the version of a tool, and how to keep the line that
# names it. Run in a scratch directory of build/tmp/ with no input: some
# tools (dc_shell, Spyglass) write logs in the current directory.
# A tool missing here gets no version, only its path.
VERSION_COMMANDS = {
    "vcs": (["vcs", "-ID"], r"Compiler version"),
    "xrun": (["xrun", "-version"], None),
    "vsim": (["vsim", "-version"], None),
    "verilator": (["verilator", "--version"], None),
    "slang": (["slang", "--version"], None),
    "dc_shell": (["dc_shell", "-v"], r"version"),
    "yosys": (["yosys", "-V"], None),
    "vivado": (["vivado", "-version"], None),
    "vivado_lab": (["vivado_lab", "-version"], None),
    "quartus_sh": (["quartus_sh", "--version"], r"Version"),
    "pt_shell": (["pt_shell", "-v"], r"version"),
    "aipk_read": (["spyglass", "-version"], r"^Version "),
    "aipk_run": (["spyglass", "-version"], r"^Version "),
    "dtc": (["dtc", "--version"], None),
    "wavedrom-cli": (["wavedrom-cli", "--version"], None),
    "asciidoctor": (["asciidoctor", "--version"], None),
    "sphinx-build": (["sphinx-build", "--version"], None),
    "verible-verilog-format": (["verible-verilog-format", "--version"], None),
    "black": (["black", "--version"], None),
    "pylint": (["pylint", "--version"], None),
}

# The lint baselines (expected_lint.yml) and the TestHarness are built
# with the Verilator installed by this script
VERILATOR_INSTALL_SCRIPT = Path("verif") / "regress" / "install-verilator.sh"


# Tools whose version is read from their installation path rather than
# run: Verdi opens its GUI whatever the option.
# /sw/synopsys/verdi/W-2024.09-SP1-1/bin/verdi -> W-2024.09-SP1-1
VERSION_FROM_PATH = {"verdi": r"/verdi/([^/]+)/bin/"}


def tool_version(tool_name, workdir, report):
    "First line naming the version of a tool, or '' when it gives none"
    path_pattern = VERSION_FROM_PATH.get(tool_name)
    if path_pattern is not None:
        match = re.search(path_pattern, shutil.which(tool_name) or "")
        return match.group(1) if match else ""
    command = VERSION_COMMANDS.get(tool_name)
    if command is None:
        return ""
    cmd, pattern = command
    log_file = Path(workdir) / f"{tool_name}_version.log"
    # Quiet: the command stays recorded in the report, not on the console
    quiet = report.quiet
    report.set_quiet(True)
    try:
        with open(os.devnull, encoding="utf-8") as no_input:
            run_cmd(
                cmd=cmd,
                report=report,
                cwd=workdir,
                stdin=no_input,
                log_file=log_file,
                timeout=60,
                check=False,
                capture_output=False,
            )
    finally:
        report.set_quiet(quiet)
    try:
        output = log_file.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return ""
    for line in output.splitlines():
        line = line.strip()
        if line and (pattern is None or re.search(pattern, line)):
            return line[:120]
    return ""


def expected_verilator_version(repo_dir):
    "Version installed by install-verilator.sh (e.g. 5.050), or None"
    try:
        text = (repo_dir / VERILATOR_INSTALL_SCRIPT).read_text(encoding="utf-8")
    except OSError:
        return None
    match = re.search(r'^VERILATOR_HASH="v?([\d.]+)"', text, re.M)
    return match.group(1) if match else None


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
        ("verilator", "Verilator - open-source simulator, TestHarness and RTL lint"),
        ("slang", "slang - SystemVerilog compiler, RTL lint (else pyslang)"),
        ("dc_shell", "Design Compiler - Synopsys synthesis"),
        ("yosys", "Yosys - open-source synthesis, with its slang plugin"),
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

    with scratch_dir() as scratch:
        for tool_name, description in tools:
            tool_path = shutil.which(tool_name)
            if tool_path is not None:
                found.add(tool_name)
                version = tool_version(tool_name, scratch, report)
                report.success(f"{tool_name}: found")
                tool_results.add_row(
                    description=description, path=tool_path, version=version
                )
            else:
                report.warning(f"{tool_name} ({description}): Not found")
                tool_results.add_row(description=description, path="", version="")

        # Another Verilator in PATH (the OSS CAD Suite of Yosys ships one)
        # gives other lint counts than the baselines and may not build the
        # TestHarness
        expected = expected_verilator_version(Path.cwd())
        if "verilator" in found and expected:
            version = tool_version("verilator", scratch, report)
            if not re.search(rf"\b{re.escape(expected)}\b", version):
                report.warning(
                    f"verilator {version or '(unknown version)'} found at "
                    f"{shutil.which('verilator')}, expected {expected} "
                    f"({VERILATOR_INSTALL_SCRIPT}): put "
                    "$VERILATOR_INSTALL_DIR/bin before the other tools in PATH"
                )
            else:
                report.success(f"verilator: version {expected}, as expected")

    # rtl-lint falls back on the pyslang module when the slang binary is
    # not installed: only both missing leaves the lint without slang
    if "slang" not in found:
        try:
            import pyslang  # pylint: disable=import-outside-toplevel

            report.success(
                f"pyslang {getattr(pyslang, '__version__', '')}: replaces slang for rtl-lint"
            )
        except ImportError:
            report.warning(
                "pyslang: Not found either, rtl-lint cannot run "
                "(pip3 install -r flows/requirements.txt)"
            )

    # yosys-synth reads the SystemVerilog through the slang plugin, which a
    # plain Yosys build does not carry
    if "yosys" in found:
        output = run_cmd(
            cmd=["yosys", "-q", "-p", "plugin -i slang"],
            report=report,
            check=False,
            capture_output=True,
            log_file=None,
            timeout=60,
        )
        if "ERROR" in (output or ""):
            report.warning("yosys: no slang plugin, yosys-synth cannot read the RTL")
        else:
            report.success("yosys: slang plugin loads")

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
        with scratch_dir() as tmp:
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
                f"{p}: Not found, see verif/regress/install-spike.sh (MANDATORY)",
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
                f"{p}: Not found, run ./cook.py git-dependencies (MANDATORY)",
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
            report.warning(f"{p}: Not found, run ./cook.py git-dependencies")

    report.step("riscv-arch-test installation")

    # riscv-arch-test
    path = [
        "./verif/tests/riscv-arch-test",
    ]

    for p in path:
        if Path(p).exists():
            report.success(f"{p}: exist")
        else:
            report.warning(f"{p}: Not found, run ./cook.py git-dependencies")

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
