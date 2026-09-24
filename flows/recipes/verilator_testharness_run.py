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
import re
import shutil
import stat
import subprocess

import typer
import yaml

from flows.recipes.verilator_testharness_comp import (
    build_directory,
    elaboration_directory,
    testharness_binary,
    target_directory,
    validate_options,
)
from flows.utils.manifest import (
    MANIFEST_NAME,
    read_manifest,
    require_manifest_option,
    require_prerequisite,
    write_manifest,
)
from flows.utils.logged_process import run_logged_process
from flows.utils.utils import (
    CompMode,
    TraceMode,
    autocompletion_target,
    autocompletion_testname_compiled,
    print_error,
    print_info,
    print_param_table,
    print_recipe_end,
    print_recipe_title,
    print_step,
    print_success,
    tail_file,
)

app = typer.Typer()

SIMULATION_TIMEOUT = 500


def validate_path_component(value: str, label: str) -> str:
    if value in {"", ".", ".."} or Path(value).name != value:
        raise ValueError(f"Invalid {label}: {value}")
    return value


def validate_run_options(
    comp_mode: CompMode, trace_mode: TraceMode, interactive_gui: bool
) -> None:
    validate_options(comp_mode, trace_mode, stats=False)
    if interactive_gui:
        raise ValueError(
            "Interactive GUI is not supported by the Verilator TestHarness recipe"
        )


def simulation_directory(
    repo_dir: Path, target: str, test_name: str, comp_mode: CompMode
) -> Path:
    target = validate_path_component(target, "target name")
    test_name = validate_path_component(test_name, "test name")
    return build_directory(
        repo_dir,
        target,
        "simulation",
        f"sim_{comp_mode.value}_verilator_testharness",
        test_name,
    )


def testharness_log_passed(log: Path) -> tuple[bool, str]:
    if not log.is_file():
        return False, f"missing TestHarness log: {log}"
    try:
        text = log.read_text(encoding="utf-8")
    except (OSError, UnicodeError) as error:
        return False, f"cannot read TestHarness log: {error}"

    failure_markers = (
        "*** FAILED ***",
        "SIMULATION FAILED",
        "[FAILED]",
        "UVM_ERROR",
        "UVM_FATAL",
    )
    failures = [marker for marker in failure_markers if marker in text]
    if failures:
        return False, "failure marker(s): " + ", ".join(failures)
    if "*** SUCCESS *** (tohost = 0)" not in text:
        return False, "missing successful TestHarness tohost result"
    return True, "TestHarness completed"


def runtime_environment(repo_dir: Path, target: str) -> tuple[dict[str, str], Path]:
    try:
        riscv = Path(os.environ["RISCV"]).resolve()
    except KeyError as error:
        raise ValueError("RISCV is not set") from error
    spike = Path(
        os.environ.get("SPIKE_INSTALL_DIR", repo_dir / "tools" / "spike")
    ).resolve()

    env = os.environ.copy()
    libraries = [str(spike / "lib"), str(riscv / "lib")]
    if env.get("LD_LIBRARY_PATH"):
        libraries.append(env["LD_LIBRARY_PATH"])
    env["LD_LIBRARY_PATH"] = os.pathsep.join(libraries)
    env["CVA6_REPO_DIR"] = str(repo_dir)
    env["TARGET_CFG"] = target
    env["SPIKE_INSTALL_DIR"] = str(spike)
    env.pop("SPIKE_TANDEM", None)
    return env, spike


def testharness_command(
    binary: Path,
    elf: Path,
    *,
    target: str,
    tohost: str,
    trace_mode: TraceMode,
) -> list[str]:
    command = [str(binary)]
    if trace_mode == TraceMode.fast:
        command.extend(("--vcd", "verilator.vcd"))
    elif trace_mode == TraceMode.compact:
        command.extend(("--fst", "verilator.fst"))
    elif trace_mode != TraceMode.notrace:
        raise ValueError(f"Unsupported Verilator trace mode: {trace_mode.value}")
    command.extend(("--seed", "1", str(elf)))
    command.extend(
        (
            "+tb_performance_mode",
            "+debug_disable=1",
            "+UVM_VERBOSITY=UVM_NONE",
            f"++{elf}",
            f"+elf_file={elf}",
            f"+core_name={target}",
            "+signature=signature_output",
            "+UVM_TESTNAME=uvmt_cva6_firmware_test_c",
            "+report_file=testharness.log.yaml",
            f"+tohost_addr={tohost}",
        )
    )
    return command


def run_spike_dasm(
    spike_dasm: Path,
    raw_trace: Path,
    output_log: Path,
    error_log: Path,
    compiler_isa: str,
    timeout: int,
    *,
    env: dict[str, str],
) -> tuple[bool, str]:
    try:
        with (
            raw_trace.open("rb") as source,
            output_log.open("wb") as output,
            error_log.open("wb") as errors,
        ):
            result = subprocess.run(
                [str(spike_dasm), f"--isa={compiler_isa}"],
                stdin=source,
                stdout=output,
                stderr=errors,
                timeout=timeout,
                check=False,
                env=env,
            )
    except subprocess.TimeoutExpired:
        return False, f"spike-dasm timed out after {timeout} seconds"
    except OSError as error:
        return False, f"trace disassembly I/O or launch error: {error}"
    if result.returncode != 0:
        return (
            False,
            f"spike-dasm exited with code {result.returncode}; see {error_log}",
        )
    return True, "trace disassembly completed"


def check_manifests(
    *,
    target: str,
    test_name: str,
    comp_mode: CompMode,
    trace_mode: TraceMode,
    compile_dir: Path,
    elab_dir: Path,
) -> None:
    software_manifest = read_manifest(compile_dir)
    for directory in (compile_dir, elab_dir):
        manifest = read_manifest(directory)
        if not isinstance(manifest, dict) or not isinstance(
            manifest.get("options"), dict
        ):
            raise ValueError(
                f"Missing or malformed Cook manifest: {directory / MANIFEST_NAME}; compile the prerequisite again"
            )
    require_manifest_option(
        software_manifest,
        "target",
        [target],
        "compiled software target does not match the requested target",
        f"./cook.py sw-compile -t {target} -c <toolchain> --out {test_name} <sources>",
        manifest_dir=compile_dir,
    )
    require_manifest_option(
        software_manifest,
        "test_name",
        [test_name],
        "compiled software name does not match the requested test",
        f"./cook.py sw-compile -t {target} -c <toolchain> --out {test_name} <sources>",
        manifest_dir=compile_dir,
    )

    hardware_manifest = read_manifest(elab_dir)
    if hardware_manifest.get("recipe") != "verilator-testharness-comp":
        raise ValueError("Hardware must be produced by verilator-testharness-comp")
    require_manifest_option(
        hardware_manifest,
        "target",
        [target],
        "TestHarness target does not match the requested target",
        f"./cook.py verilator-testharness-comp -t {target}",
        manifest_dir=elab_dir,
    )
    require_manifest_option(
        hardware_manifest,
        "comp_mode",
        [comp_mode.value],
        "TestHarness compilation mode does not match the requested mode",
        f"./cook.py verilator-testharness-comp -t {target} --comp-mode {comp_mode.value}",
        manifest_dir=elab_dir,
    )
    if trace_mode != TraceMode.notrace:
        require_manifest_option(
            hardware_manifest,
            "trace_mode",
            [trace_mode.value],
            f"trace mode '{trace_mode.value}' requires a matching TestHarness build",
            f"./cook.py verilator-testharness-comp -t {target} --trace-mode {trace_mode.value}",
            manifest_dir=elab_dir,
        )


def run_testharness_and_trace(
    *,
    command: list[str],
    output_dir: Path,
    env: dict[str, str],
    spike_install: Path,
    compiler_isa: str,
    timeout: int,
) -> tuple[bool, str]:
    testharness_log = output_dir / "testharness.log"
    return_code, timed_out = run_logged_process(
        command,
        cwd=output_dir,
        env=env,
        log=testharness_log,
        timeout=timeout,
    )
    if timed_out:
        return False, f"TestHarness timed out after {timeout} seconds"
    if return_code != 0:
        return False, f"TestHarness returned {return_code}"

    passed, detail = testharness_log_passed(testharness_log)
    if not passed:
        return False, detail

    raw_trace = output_dir / "trace_rvfi_hart_00.dasm"
    failure = "RTL simulation passed; trace post-processing failed"
    # Only an absent path is optional; invalid trace paths must not be skipped.
    try:
        trace_stat = raw_trace.lstat()
    except FileNotFoundError:
        return (
            True,
            f"{detail}; trace disassembly skipped: raw trace not produced ({raw_trace.name})",
        )
    except OSError as error:
        return False, f"{failure}: cannot inspect raw trace: {error}"
    if not stat.S_ISREG(trace_stat.st_mode):
        return False, f"{failure}: raw trace is not a regular file: {raw_trace}"

    trace_passed, trace_detail = run_spike_dasm(
        spike_install / "bin" / "spike-dasm",
        raw_trace,
        output_dir / "verilator.log",
        output_dir / "spike_dasm.log",
        compiler_isa,
        min(timeout, 120),
        env=env,
    )
    if not trace_passed:
        return False, f"{failure}: {trace_detail}"
    return True, f"{detail}; {trace_detail}"


def run_test(
    *,
    target: str,
    test_name: str,
    comp_mode: CompMode,
    trace_mode: TraceMode,
    iss_enabled: bool,
    interactive_gui: bool,
    timeout: int = SIMULATION_TIMEOUT,
) -> tuple[bool, str, Path]:
    if iss_enabled:
        raise ValueError("ISS comparison is not supported by this version")

    repo_dir = Path.cwd().resolve()
    validate_run_options(comp_mode, trace_mode, interactive_gui)
    target = validate_path_component(target, "target name")
    test_name = validate_path_component(test_name, "test name")

    target_directory(repo_dir, target)
    compile_dir = repo_dir / "build" / target / "compile" / test_name
    elab_dir = elaboration_directory(repo_dir, target, comp_mode)
    output_dir = simulation_directory(repo_dir, target, test_name, comp_mode)
    elf = compile_dir / f"{test_name}.elf"
    isa_file = compile_dir / "isa_string"
    tohost_file = compile_dir / f"{test_name}.add_tohost"
    binary = testharness_binary(repo_dir, target, comp_mode)

    require_prerequisite(
        elf,
        f"compiled software for test '{test_name}'",
        f"./cook.py sw-compile -t {target} -c <toolchain> --out {test_name} <sources>",
    )
    require_prerequisite(
        isa_file,
        f"compiler ISA for test '{test_name}'",
        f"./cook.py sw-compile -t {target} -c <toolchain> --out {test_name} <sources>",
    )
    require_prerequisite(
        tohost_file,
        f"tohost address for test '{test_name}'",
        f"./cook.py sw-compile -t {target} -c <toolchain> --out {test_name} <sources>",
    )
    require_prerequisite(
        binary,
        f"Verilator TestHarness (comp mode '{comp_mode.value}')",
        f"./cook.py verilator-testharness-comp -t {target} --comp-mode {comp_mode.value}",
    )
    check_manifests(
        target=target,
        test_name=test_name,
        comp_mode=comp_mode,
        trace_mode=trace_mode,
        compile_dir=compile_dir,
        elab_dir=elab_dir,
    )

    compiler_isa = isa_file.read_text(encoding="utf-8").strip()
    tohost = tohost_file.read_text(encoding="utf-8").strip()
    if not compiler_isa:
        raise ValueError(f"Empty compiler ISA in {isa_file}")
    if not re.fullmatch(r"(?:0[xX])?[0-9a-fA-F]+", tohost) or int(tohost, 16) == 0:
        raise ValueError(f"Invalid or zero tohost address in {tohost_file}")
    if not os.access(binary, os.X_OK):
        raise ValueError(f"TestHarness is not executable: {binary}")
    env, spike_install = runtime_environment(repo_dir, target)

    if output_dir.exists():
        shutil.rmtree(output_dir)
    output_dir.mkdir(parents=True)
    command = testharness_command(
        binary,
        elf,
        target=target,
        tohost=tohost,
        trace_mode=trace_mode,
    )
    passed, detail = run_testharness_and_trace(
        command=command,
        output_dir=output_dir,
        env=env,
        spike_install=spike_install,
        compiler_isa=compiler_isa,
        timeout=timeout,
    )
    return passed, detail, output_dir


@app.command()
def verilator_testharness_run(
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
        help="Cook-compiled test name",
        autocompletion=autocompletion_testname_compiled,
    ),
    comp_mode: CompMode = typer.Option(
        CompMode.rtl, help="Compilation mode; only rtl is supported"
    ),
    trace_mode: TraceMode = typer.Option(
        TraceMode.notrace,
        help="notrace, fast (VCD), or compact (FST); must match the build",
    ),
    iss_enabled: bool = typer.Option(
        False, help="Reserved for ISS comparison; enabling it is not yet supported"
    ),
    interactive_gui: bool = typer.Option(
        False, help="Interactive GUI is currently unsupported"
    ),
    quiet: bool = typer.Option(
        False, "--quiet", "-q", help="Suppress output (errors only)"
    ),
) -> None:
    """Run a single ELF with the Verilator TestHarness (no ISS comparison)."""
    print_recipe_title("VERILATOR TESTHARNESS RUN", quiet=quiet)
    print_param_table(
        {
            "Target": target,
            "Test": test_name,
            "Compilation mode": comp_mode.value,
            "Trace mode": trace_mode.value,
            "ISS comparison": iss_enabled,
            "Interactive GUI": interactive_gui,
        },
        "Options",
        quiet=quiet,
    )
    print_step(f"Run {test_name}", quiet=quiet)

    try:
        passed, detail, output_dir = run_test(
            target=target,
            test_name=test_name,
            comp_mode=comp_mode,
            trace_mode=trace_mode,
            iss_enabled=iss_enabled,
            interactive_gui=interactive_gui,
        )
    except (OSError, TypeError, ValueError, yaml.YAMLError) as error:
        print_error(str(error))
        raise typer.Exit(code=1) from error

    if (not quiet or not passed) and (output_dir / "testharness.log").is_file():
        tail_file(output_dir / "testharness.log", n=20)
    options = {
        "target": target,
        "test_name": test_name,
        "comp_mode": comp_mode.value,
        "trace_mode": trace_mode.value,
        "iss_enabled": iss_enabled,
        "interactive_gui": interactive_gui,
    }
    write_manifest(
        output_dir,
        "verilator-testharness-run",
        options,
        quiet=quiet,
    )
    manifest = read_manifest(output_dir)
    if (
        not isinstance(manifest, dict)
        or manifest.get("recipe") != "verilator-testharness-run"
        or manifest.get("options") != options
    ):
        print_error(
            f"Run manifest was not written correctly: {output_dir / MANIFEST_NAME}"
        )
        raise typer.Exit(code=1)
    try:
        (output_dir / "result.yml").write_text(
            yaml.safe_dump(
                {
                    "target": target,
                    "test_name": test_name,
                    "status": "PASS" if passed else "FAIL",
                    "iss_enabled": iss_enabled,
                    "detail": detail,
                },
                sort_keys=False,
            ),
            encoding="utf-8",
        )
    except OSError as error:
        print_error(f"Cannot write run result: {error}")
        raise typer.Exit(code=1) from error
    if passed:
        print_success(f"{test_name}: PASS ({detail})", quiet=quiet)
    else:
        print_error(f"{test_name}: FAIL ({detail}); results: {output_dir}")
    print_info(f"Results: {output_dir}", quiet=quiet)
    print_recipe_end("Completed", quiet=quiet)
    if not passed:
        raise typer.Exit(code=1)
