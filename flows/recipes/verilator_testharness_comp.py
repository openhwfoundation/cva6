# Copyright 2026 OpenHW Foundation
#
# Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
# You may obtain a copy of the License at https://solderpad.org/licenses/
#
# Original Author: Junchao Chen (junchao.chen@eclipse-foundation.org)

from __future__ import annotations

import os
from pathlib import Path
import shlex
import shutil
import subprocess

import typer
import yaml

from flows.utils.logged_process import run_logged_process
from flows.utils.manifest import MANIFEST_NAME, read_manifest, write_manifest
from flows.utils.utils import (
    CompMode,
    TraceMode,
    autocompletion_target,
    print_error,
    print_file_regex,
    print_info,
    print_param_table,
    print_recipe_end,
    print_recipe_title,
    print_step,
    print_success,
    tail_file,
)

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


def validate_options(comp_mode: CompMode, trace_mode: TraceMode, stats: bool) -> None:
    if comp_mode != CompMode.rtl:
        raise ValueError(
            "Verilator TestHarness currently supports only rtl compilation mode; "
            f"requested {comp_mode.value}"
        )
    if trace_mode == TraceMode.gui:
        raise ValueError("Verilator TestHarness does not support interactive GUI mode")
    if stats:
        raise ValueError(
            "RTL perf tracer statistics are not supported by the Verilator "
            "TestHarness recipe"
        )


def target_directory(repo_dir: Path, target: str) -> Path:
    if target in {"", ".", ".."} or Path(target).name != target:
        raise ValueError(f"Invalid target name: {target}")

    directory = repo_dir / "config" / "target" / target
    required = (
        directory / "Flist.cva6",
        directory / "rtl_cfg_pkg.sv",
        directory / "testbench_cfg.yml",
    )
    missing = [str(path) for path in required if not path.is_file()]
    if missing:
        raise ValueError("Missing target file(s): " + ", ".join(missing))
    config = yaml.safe_load(
        (directory / "testbench_cfg.yml").read_text(encoding="utf-8")
    )
    if not isinstance(config, dict) or config.get("hier") != "axi":
        raise ValueError(
            f"The current Verilator TestHarness requires an AXI target (hier: axi); "
            f"requested {target}. Use a matching AXI configuration such as cv32a60x_axi."
        )
    return directory


def build_directory(repo_dir: Path, *parts: str) -> Path:
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


def _verilator_from_install(install_dir: Path) -> tuple[str, Path]:
    binary = install_dir / "bin" / "verilator"
    if not binary.is_file() or not os.access(binary, os.X_OK):
        raise ValueError(f"Missing Verilator executable: {binary}")
    return str(binary), _verilator_root(str(binary))


def _verilator_from_path() -> tuple[str, Path]:
    binary = shutil.which("verilator")
    if binary is None:
        raise ValueError("verilator is not available in PATH")

    return binary, _verilator_root(binary)


def _verilator_root(binary: str) -> Path:
    env = os.environ.copy()
    env.pop("VERILATOR_ROOT", None)
    try:
        output = subprocess.run(
            [binary, "--getenv", "VERILATOR_ROOT"],
            check=True,
            capture_output=True,
            text=True,
            env=env,
            timeout=10,
        ).stdout
    except (OSError, subprocess.SubprocessError) as error:
        raise ValueError(f"Cannot query Verilator installation: {error}") from error
    if not output.strip():
        raise ValueError("Verilator returned an empty VERILATOR_ROOT")
    root = Path(output.strip()).resolve()
    if not (root / "include" / "vltstd").is_dir():
        raise ValueError(f"Missing Verilator include directory: {root / 'include'}")
    return root


def tool_paths(repo_dir: Path) -> tuple[Path, Path, str, Path]:
    try:
        riscv = Path(os.environ["RISCV"]).resolve()
    except KeyError as error:
        raise ValueError("RISCV is not set") from error

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
            raise ValueError(f"Missing {description}: {directory}")

    configured = os.environ.get("VERILATOR_INSTALL_DIR")
    if configured:
        verilator, verilator_root = _verilator_from_install(Path(configured).resolve())
    else:
        verilator, verilator_root = _verilator_from_path()
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
    stats: bool,
    jobs: int,
    verilator: str,
    verilator_root: Path,
    riscv: Path,
    spike: Path,
) -> list[str]:
    validate_options(comp_mode, trace_mode, stats)
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
    quiet: bool = typer.Option(
        False, "--quiet", "-q", help="Suppress output (errors only)"
    ),
) -> None:
    """Verilator TestHarness compilation flow."""
    print_recipe_title("VERILATOR TESTHARNESS COMPILATION", quiet=quiet)
    repo_dir = Path.cwd().resolve()

    try:
        validate_options(comp_mode, trace_mode, stats)
        target_directory(repo_dir, target)
        riscv, spike, verilator, verilator_root = tool_paths(repo_dir)
        env = {**os.environ, **compile_environment(repo_dir, target, spike)}
        env["VERILATOR_ROOT"] = str(verilator_root)
        version = subprocess.run(
            [verilator, "--version"],
            check=True,
            capture_output=True,
            text=True,
            env=env,
            timeout=10,
        ).stdout.strip()
        jobs = int(os.environ.get("NUM_JOBS", "1"))
        if jobs < 1:
            raise ValueError("NUM_JOBS must be at least 1")
        command = build_command(
            repo_dir=repo_dir,
            target=target,
            comp_mode=comp_mode,
            trace_mode=trace_mode,
            stats=stats,
            jobs=jobs,
            verilator=verilator,
            verilator_root=verilator_root,
            riscv=riscv,
            spike=spike,
        )
    except (
        OSError,
        TypeError,
        ValueError,
        yaml.YAMLError,
        subprocess.SubprocessError,
    ) as error:
        print_error(str(error))
        raise typer.Exit(code=1) from error

    elab_dir = elaboration_directory(repo_dir, target, comp_mode)
    binary = testharness_binary(repo_dir, target, comp_mode)
    log_file = elab_dir / "compilation.log"
    print_param_table(
        {
            "Target": target,
            "Compilation mode": comp_mode.value,
            "Trace mode": trace_mode.value,
            "RTL perf tracer": stats,
            "Build directory": elab_dir,
            "Jobs": jobs,
            "Verilator": version,
        },
        "Options",
        quiet=quiet,
    )

    print_step("Clean", quiet=quiet)
    try:
        if elab_dir.exists():
            shutil.rmtree(elab_dir)
            print_info(f"remove {elab_dir}", quiet=quiet)
        elab_dir.mkdir(parents=True, exist_ok=True)
        (elab_dir / "verilator.version").write_text(version + "\n", encoding="utf-8")
        (elab_dir / "compilation.command").write_text(
            shlex.join(command) + "\n", encoding="utf-8"
        )
        print_info(f"create {elab_dir}", quiet=quiet)
    except OSError as error:
        print_error(f"Clean error: {error}")
        raise typer.Exit(code=1) from error

    print_step("Compile TestHarness", quiet=quiet)
    try:
        return_code, timed_out = run_logged_process(
            command,
            cwd=repo_dir,
            env=env,
            log=log_file,
            timeout=1800,
        )
        if timed_out:
            raise RuntimeError("exceeded the 1800-second compilation timeout")
        if return_code != 0:
            raise RuntimeError(f"Verilator returned {return_code}")
    except (OSError, RuntimeError) as error:
        print_error(f"Verilator compilation failed: {error}; log: {log_file}")
        if log_file.is_file():
            tail_file(log_file, n=30)
        raise typer.Exit(code=1) from error

    if not binary.is_file() or not os.access(binary, os.X_OK):
        print_error(f"Missing or non-executable Verilator output: {binary}")
        raise typer.Exit(code=1)
    if not log_file.is_file():
        print_error(f"Missing compilation log: {log_file}")
        raise typer.Exit(code=1)
    print_file_regex(
        log_file,
        error_patterns=[r"^%Error"],
        warning_patterns=[r"^%Warning"],
        quiet=quiet,
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
        quiet=quiet,
    )
    manifest = read_manifest(elab_dir)
    expected = {
        "target": target,
        "comp_mode": comp_mode.value,
        "trace_mode": trace_mode.value,
        "stats": stats,
    }
    if (
        not isinstance(manifest, dict)
        or manifest.get("recipe") != "verilator-testharness-comp"
        or manifest.get("options") != expected
    ):
        print_error(
            f"Compilation manifest was not written correctly: {elab_dir / MANIFEST_NAME}"
        )
        raise typer.Exit(code=1)

    print_step("Generated files", quiet=quiet)
    for path in (binary, log_file, elab_dir / MANIFEST_NAME):
        if path.exists():
            print_info(f"> {path}", quiet=quiet)

    print_success(f"Verilator TestHarness: {binary}", quiet=quiet)
    print_recipe_end("Completed", quiet=quiet)
