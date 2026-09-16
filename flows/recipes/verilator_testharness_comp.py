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
Elaborate the TestHarness testbench with Verilator.

The other simulators drive the UVM testbench; this one elaborates
`ariane_testharness`, the SystemVerilog harness of `corev_apu/tb`, into a
native binary. Only the AXI targets are wired for it today.
"""

import os
from pathlib import Path
import shlex
import shutil

import typer

from flows.utils.autocompletion import CompMode, TraceMode, autocompletion_target
from flows.utils.manifest import MANIFEST_NAME, write_manifest
from flows.utils.recipe_report import RecipeReport
from flows.utils.run_cmd import run_cmd
from flows.utils.target_config import read_config_or_exit_testbench_cfg, target_dir

app = typer.Typer()


PACKAGE_SOURCES = (
    "corev_apu/tb/ariane_axi_pkg.sv",
    "corev_apu/tb/axi_intf.sv",
    "corev_apu/register_interface/src/reg_intf.sv",
    "corev_apu/tb/ariane_soc_pkg.sv",
    "corev_apu/riscv-dbg/src/dm_pkg.sv",
    "corev_apu/tb/ariane_axi_soc_pkg.sv",
)

INCLUDE_DIRECTORIES = (
    "vendor/pulp-platform/common_cells/include",
    "vendor/pulp-platform/axi/include",
    "corev_apu/register_interface/include",
    "corev_apu/tb/common",
    "vendor/pulp-platform/obi/include",
    "verif/core-v-verif/lib/uvm_agents/uvma_rvfi",
    "verif/core-v-verif/lib/uvm_components/uvmc_rvfi_reference_model",
    "verif/core-v-verif/lib/uvm_components/uvmc_rvfi_scoreboard",
    "verif/core-v-verif/lib/uvm_agents/uvma_core_cntrl",
    "verif/tb/core",
    "core/include",
    "corev_apu/instr_tracing/ITI/include",
    "corev_apu/axi_node",
)

CXX_SOURCES = (
    "corev_apu/tb/ariane_tb.cpp",
    "corev_apu/tb/dpi/SimDTM.cc",
    "corev_apu/tb/dpi/SimJTAG.cc",
    "corev_apu/tb/dpi/remote_bitbang.cc",
    "corev_apu/tb/dpi/msim_helper.cc",
)


def check_options(
    comp_mode: CompMode, trace_mode: TraceMode, stats: bool, report
) -> None:
    "Stop on an option the Verilator harness does not implement"
    if comp_mode != CompMode.rtl:
        report.error_exit(
            f"Verilator TestHarness supports only the rtl compilation mode, "
            f"got {comp_mode.value}",
            env=True,
        )
    if trace_mode == TraceMode.gui:
        report.error_exit("Verilator TestHarness has no interactive GUI mode", env=True)
    if stats:
        report.error_exit(
            "The RTL perf tracer is not wired to the Verilator TestHarness", env=True
        )


def check_target(target: str, report) -> Path:
    """
    Return the configuration directory of an AXI target.

    The harness instantiates `ariane_testharness`, which drives the core
    over AXI: an OBI target elaborates but has nothing on the bus.
    """
    directory = target_dir(target)
    required = (
        directory / "Flist.cva6",
        directory / "rtl_cfg_pkg.sv",
        directory / "testbench_cfg.yml",
    )
    missing = [str(path) for path in required if not path.is_file()]
    if missing:
        report.error_exit("Missing target file(s): " + ", ".join(missing), env=True)

    hier = read_config_or_exit_testbench_cfg(target, report, record=False)
    if hier.value != "axi":
        report.error_exit(
            f"The Verilator TestHarness requires an AXI target, {target} is "
            f"{hier.value}. Use a matching AXI configuration such as "
            f"cv32a60x_axi.",
            env=True,
        )
    return directory


def build_directory(repo_dir: Path, *parts: str) -> Path:
    "Return build/<parts>, refusing a component that escapes the tree"
    repo_dir = repo_dir.resolve()
    directory = repo_dir / "build"
    for part in parts:
        if part in {"", ".", ".."} or Path(part).name != part:
            raise ValueError(f"Invalid build path component: {part}")
        directory /= part
    for parent in (directory, *directory.parents):
        if parent == repo_dir:
            break
        if parent.is_symlink():
            raise ValueError(
                f"Build output must not traverse a symbolic link: {parent}"
            )
    return directory


def elaboration_directory(repo_dir: Path, target: str, comp_mode: CompMode) -> Path:
    return build_directory(
        repo_dir, target, "elab", f"sim_{comp_mode.value}_verilator_testharness"
    )


def testharness_binary(repo_dir: Path, target: str, comp_mode: CompMode) -> Path:
    return elaboration_directory(repo_dir, target, comp_mode) / "Variane_testharness"


def _verilator_root(binary: str, report) -> Path:
    """
    Return the VERILATOR_ROOT of an installation.

    Asked to the binary rather than derived from its path: Verilator 5
    keeps its headers beside the sources, not under the install prefix, so
    the two differ on a build tree.
    """
    env = os.environ.copy()
    env.pop("VERILATOR_ROOT", None)
    output = run_cmd(
        cmd=[binary, "--getenv", "VERILATOR_ROOT"],
        report=report,
        env=env,
        log_file=None,
        timeout=60,
    )
    if not output.strip():
        report.error_exit("Verilator returned an empty VERILATOR_ROOT", env=True)
    root = Path(output.strip()).resolve()
    if not (root / "include" / "vltstd").is_dir():
        report.error_exit(
            f"Missing Verilator include directory: {root / 'include'}", env=True
        )
    return root


def _verilator(report) -> tuple[str, Path]:
    "Return the Verilator binary and its root, from VERILATOR_INSTALL_DIR or PATH"
    configured = os.environ.get("VERILATOR_INSTALL_DIR")
    if configured:
        binary = Path(configured).resolve() / "bin" / "verilator"
        if not binary.is_file() or not os.access(binary, os.X_OK):
            report.error_exit(f"Missing Verilator executable: {binary}", env=True)
        return str(binary), _verilator_root(str(binary), report)

    binary = shutil.which("verilator")
    if binary is None:
        report.error_exit(
            "verilator: Not found\n"
            "  Install it and put it in the path, or point "
            "VERILATOR_INSTALL_DIR at it (see setenv.sh).",
            env=True,
        )
    return binary, _verilator_root(binary, report)


def tool_paths(repo_dir: Path, report) -> tuple[Path, Path, str, Path]:
    """
    Return the RISC-V toolchain, Spike, and the Verilator of this machine.

    The harness links against the Spike libraries: the disassembler and the
    front-end server are what the testbench calls at run time, so headers
    and libraries must both be there.
    """
    riscv_env = os.environ.get("RISCV")
    if not riscv_env:
        report.error_exit(
            "RISCV is not set: it names the RISC-V toolchain the harness "
            "links against (see setenv.sh).",
            env=True,
        )
    riscv = Path(riscv_env).resolve()
    spike = Path(
        os.environ.get("SPIKE_INSTALL_DIR", repo_dir / "tools" / "spike")
    ).resolve()
    for directory, description in (
        (riscv / "include", "RISC-V include directory"),
        (riscv / "lib", "RISC-V library directory"),
        (spike / "include", "Spike include directory"),
        (spike / "lib", "Spike library directory"),
    ):
        if not directory.is_dir():
            report.error_exit(f"Missing {description}: {directory}", env=True)

    verilator, verilator_root = _verilator(report)
    return riscv, spike, verilator, verilator_root


def compile_environment(repo_dir: Path, target: str, spike: Path) -> dict[str, str]:
    return {
        "CVA6_REPO_DIR": str(repo_dir),
        "TARGET_CFG": target,
        "HPDCACHE_DIR": str(repo_dir / "core" / "cache_subsystem" / "hpdcache"),
        "SPIKE_INSTALL_DIR": str(spike),
    }


def build_command(
    *,
    repo_dir: Path,
    target: str,
    comp_mode: CompMode,
    trace_mode: TraceMode,
    jobs: int,
    verilator: str,
    verilator_root: Path,
    riscv: Path,
    spike: Path,
) -> list[str]:
    elab_dir = elaboration_directory(repo_dir, target, comp_mode)

    cflags = [
        f"-I{repo_dir}",
        f"-I{spike / 'include' / 'riscv'}",
        f"-I{spike / 'include' / 'disasm'}",
        f"-I{verilator_root / 'include' / 'vltstd'}",
        f"-I{riscv / 'include'}",
        f"-I{spike / 'include'}",
        "-std=c++17",
        f"-I{repo_dir / 'corev_apu' / 'tb' / 'dpi'}",
        "-O3",
        "-DVL_DEBUG",
        f"-I{spike}",
    ]
    ldflags = [
        f"-L{riscv / 'lib'}",
        f"-L{spike / 'lib'}",
        f"-Wl,-rpath,{riscv / 'lib'}",
        f"-Wl,-rpath,{spike / 'lib'}",
        "-lfesvr",
        "-lriscv",
        "-ldisasm",
        "-lyaml-cpp",
        "-lpthread",
    ]
    if trace_mode == TraceMode.compact:
        ldflags.append("-lz")

    command = [
        verilator,
        "--build",
        "-j",
        str(jobs),
        "--no-timing",
        str(repo_dir / "verilator_config.vlt"),
        "-f",
        str(repo_dir / "config" / "target" / target / "Flist.cva6"),
        str(repo_dir / "core" / "cva6_rvfi.sv"),
    ]
    command.extend(str(repo_dir / source) for source in PACKAGE_SOURCES)
    command.extend(
        (
            "-f",
            str(repo_dir / "verif" / "tb" / "core" / "Flist.verilator_testharness"),
            "-DPRELOAD=1",
            "--unroll-count",
            "256",
            "-Wall",
            "-Werror-PINMISSING",
            "-Werror-IMPLICIT",
            "-Wno-fatal",
            "-Wno-PINCONNECTEMPTY",
            "-Wno-ASSIGNDLY",
            "-Wno-DECLFILENAME",
            "-Wno-UNUSED",
            "-Wno-UNOPTFLAT",
            "-Wno-BLKANDNBLK",
            "-Wno-style",
            "-LDFLAGS",
            shlex.join(ldflags),
            "-CFLAGS",
            shlex.join(cflags),
            "--cc",
            "--vpi",
        )
    )
    command.extend(
        f"+incdir+{repo_dir / directory}" for directory in INCLUDE_DIRECTORIES
    )
    command.append(f"+incdir+{spike / 'include' / 'disasm'}")

    if trace_mode == TraceMode.fast:
        command.extend(("--trace", "+define+VM_TRACE"))
    elif trace_mode == TraceMode.compact:
        command.extend(("--trace-fst", "+define+VM_TRACE", "+define+VM_TRACE_FST"))

    command.extend(
        (
            "--top-module",
            "ariane_testharness",
            "--threads-dpi",
            "none",
            "--Mdir",
            str(elab_dir),
            "-O3",
            "--exe",
        )
    )
    command.extend(str(repo_dir / source) for source in CXX_SOURCES)
    return command


@app.command()
def verilator_testharness_comp(
    target: str = typer.Option(
        ...,
        "--target",
        "-t",
        help="CVA6 user configuration",
        autocompletion=autocompletion_target,
    ),
    comp_mode: CompMode = typer.Option(
        CompMode.rtl, help="Compilation mode; only rtl is supported"
    ),
    trace_mode: TraceMode = typer.Option(
        TraceMode.notrace,
        help="notrace, fast (VCD), or compact (FST); gui is unsupported",
    ),
    stats: bool = typer.Option(False, help="RTL perf tracer; currently unsupported"),
    jobs: int = typer.Option(8, "--jobs", "-j", help="Verilator parallel jobs"),
    quiet: bool = typer.Option(
        False, "--quiet", "-q", help="Suppress output (errors only)"
    ),
) -> None:
    """
    Elaborate the TestHarness testbench with Verilator
    """
    repo_dir = Path.cwd().resolve()
    elab_dir = elaboration_directory(repo_dir, target, comp_mode)
    report = RecipeReport(
        "verilator-testharness-comp",
        out_dir=elab_dir,
        title="VERILATOR TESTHARNESS COMPILATION",
        context={
            "target": target,
            "comp_mode": comp_mode.value,
            "trace_mode": trace_mode.value,
            "stats": stats,
            "jobs": jobs,
        },
        quiet=quiet,
    )

    report.step("Check prerequisites")
    check_options(comp_mode, trace_mode, stats, report)
    check_target(target, report)
    riscv, spike, verilator, verilator_root = tool_paths(repo_dir, report)

    env = {
        **compile_environment(repo_dir, target, spike),
        "VERILATOR_ROOT": str(verilator_root),
    }
    version = run_cmd(
        cmd=[verilator, "--version"],
        report=report,
        env=env,
        log_file=None,
        timeout=60,
    ).strip()
    report.success(f"verilator: {version}")

    command = build_command(
        repo_dir=repo_dir,
        target=target,
        comp_mode=comp_mode,
        trace_mode=trace_mode,
        jobs=jobs,
        verilator=verilator,
        verilator_root=verilator_root,
        riscv=riscv,
        spike=spike,
    )
    report.add_context({"verilator": version}, table="Options")

    report.step("Clean")
    try:
        if elab_dir.exists():
            shutil.rmtree(elab_dir)
        elab_dir.mkdir(parents=True, exist_ok=True)
        report.info(f"create {elab_dir}")
        # Kept next to the objects they produced: the version and the
        # command line are what a build directory cannot be reproduced
        # without.
        (elab_dir / "verilator.version").write_text(version + "\n", encoding="utf-8")
        (elab_dir / "compilation.command").write_text(
            shlex.join(command) + "\n", encoding="utf-8"
        )
    except OSError as e:
        report.error_exit(f"Clean error: {e}", env=True)

    report.step("Compile TestHarness")
    log_file = elab_dir / "compilation.log"
    run_cmd(
        cmd=command,
        report=report,
        cwd=repo_dir,
        env=env,
        error_patterns=[r"^%Error"],
        warning_patterns=[r"^%Warning"],
        log_file=log_file,
        timeout=1800,
    )

    binary = testharness_binary(repo_dir, target, comp_mode)
    if not binary.is_file() or not os.access(binary, os.X_OK):
        report.error(f"Missing or non-executable Verilator output: {binary}")
    report.analyze_log(
        log_file,
        error_patterns=[r"^%Error"],
        warning_patterns=[r"^%Warning"],
        fail_on_error=True,
    )

    write_manifest(
        elab_dir,
        "verilator-testharness-comp",
        {
            "target": target,
            "comp_mode": comp_mode,
            "trace_mode": trace_mode,
            "stats": stats,
        },
        report,
    )

    report.step("Generated files")
    for path in (binary, log_file, elab_dir / MANIFEST_NAME):
        if path.exists():
            report.info(f"> {path}")

    report.end()
