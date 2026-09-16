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
from flows.utils.config_loader import load_compiler_config
from flows.utils.manifest import write_manifest
from flows.utils.recipe_report import RecipeReport
from flows.utils.target_config import read_config_or_exit_isa, target_dir
from flows.utils.run_cmd import run_cmd
from flows.utils.autocompletion import ToolchainOption, autocompletion_target

app = typer.Typer()


# ==========================================================
# RECIPE
# ==========================================================


@app.command()
def sw_compile(
    target: str = typer.Option(
        ...,
        "--target",
        "-t",
        help="CVA6 user configuration",
        autocompletion=autocompletion_target,
    ),
    toolchain: ToolchainOption = typer.Option(
        ..., "--toolchain", "-c", help="Toolchain defined in $CONFIG_DIR/compiler.yml"
    ),
    src_files: list[str] = typer.Argument(..., help="Source files"),
    inc_dirs: list[str] = typer.Option([], "--inc", help="Include directories"),
    linker_file: str = typer.Option(..., "--linker", help="Linker file path"),
    options: list[str] = typer.Option([], "--options", help="Options"),
    march: str = typer.Option(
        None, help="march custom instead of default one from config/target"
    ),
    mabi: str = typer.Option(
        None, help="mabi custom instead of default one from config/target"
    ),
    preprocessor_directives: list[str] = typer.Option(
        [], "--define", help="Preprocessor directives"
    ),
    benchmark_iterations: int = typer.Option(
        None,
        "--benchmark-iterations",
        help="Benchmark iterations compiled in the binary (recorded in the "
        "manifest, used by the run recipes to compute the score)",
    ),
    test_name: str = typer.Option(
        ..., "--out", help="Test name (used in rest of flow)"
    ),
    quiet: bool = typer.Option(
        False, "--quiet", "-q", help="Suppress output (errors only)"
    ),
):
    """
    Compile software and generate ELF + reports.
    """

    COMPILER_DATA = load_compiler_config()

    report = RecipeReport(
        "sw-compile",
        title="Software compilation",
        context={
            "target": target,
            "toolchain": toolchain,
            "test_name": test_name,
            "src_files": src_files,
            "inc_dirs": inc_dirs,
            "linker_file": linker_file,
            "options": options,
            "march": march,
            "mabi": mabi,
            "preprocessor_directives": preprocessor_directives,
        },
        quiet=quiet,
    )

    repo_dir = Path.cwd()

    compiler_data = COMPILER_DATA[toolchain.value]
    report.add_context(compiler_data, table="Compiler parameters")

    if compiler_data["CLANG"] is not None:
        report.info("LLVM mode")
        compiler = compiler_data["CLANG"]
    else:
        report.info("GCC mode")
        compiler = compiler_data["GCC"]

    tools_path = compiler_data["TOOLS_PATH"]
    objdump = compiler_data["OBJDUMP"]
    nm = compiler_data["NM"]
    target_toolchain = compiler_data["TARGET_TOOLCHAIN"]

    # Create files and folder paths
    build_root = repo_dir / "build" / target
    compile_dir = build_root / "compile" / test_name
    report.set_out_dir(compile_dir)
    elf_file = compile_dir / f"{test_name}.elf"
    objdump_file = compile_dir / f"{test_name}.dump"
    size_file = compile_dir / f"{test_name}.size"

    # ==========================================================
    # CLEAN
    # ==========================================================
    report.step("Clean")
    try:
        if compile_dir.exists():
            shutil.rmtree(compile_dir)
            report.info(f"remove {compile_dir}")
    except Exception as e:
        report.error_exit(f"Clean error : {e}", env=True)

    compile_dir.mkdir(parents=True, exist_ok=True)
    report.info(f"create {compile_dir}")

    # ==========================================================
    # COMPILER SELECTION
    # ==========================================================
    # The `toolchain` option is only a label from compiler.yml: resolve what
    # the binary reports about itself, so a report tells which compiler
    # produced the ELF and not merely which entry was selected. `--version`
    # rather than `-dumpversion`: it names the compiler (GCC / clang) too.
    # Own log file: run_cmd truncates, and compile.log belongs to the build.
    report.step("Compiler selection")
    compiler_version = run_cmd(
        cmd=[f"{tools_path}/bin/{compiler}", "--version"],
        report=report,
        cwd=None,
        env=None,
        error_patterns=None,
        warning_patterns=None,
        highlight_patterns=None,
        log_file=compile_dir / "compiler_version.log",
        timeout=30,
        check=False,
        capture_output=True,
    )
    # First line only: "riscv-none-elf-gcc (GCC) 15.2.0" or
    # "clang version 22.1.1 (git@...)" — drop the trailing repo/commit.
    compiler_version = (compiler_version or "").strip().splitlines()
    compiler_version = compiler_version[0].strip() if compiler_version else "unknown"
    compiler_version = compiler_version.split(" (git")[0].strip()
    report.add_context({"compiler_version": compiler_version})
    # Summary row: what actually built the ELF, readable in the expanded job
    # next to the Compilation/Objdump verdicts (the context is not displayed).
    report.success(compiler_version)

    # ==========================================================
    # ISA STRING SELECTION
    # ==========================================================

    report.step("ISA string selection")

    # Not provided (standard case): taken from the isa.yml of the target
    march, mabi = read_config_or_exit_isa(target, report, march=march, mabi=mabi)

    if linker_file is None:
        linker_file = str(target_dir(target) / "link.ld")

    report.add_context(
        {"march": march, "mabi": mabi, "linker_file": linker_file},
        table="ISA and Linker file",
    )

    # Summary rows: the ISA actually compiled for.
    report.success(f"march: {march}")
    report.success(f"mabi: {mabi}")

    # ==========================================================
    # LAUNCH COMPILER COMMAND
    # ==========================================================
    report.step("Compilation")

    compile_cmd = [
        f"{tools_path}/bin/{compiler}",
        *src_files,
        *[f"-I{inc}" for inc in inc_dirs],
        f"-T{linker_file}",
        *[f"-{option}" for option in options],
        f"-march={march}",
        f"-mabi={mabi}",
        *[f"-D{macro}" for macro in preprocessor_directives],
        "-o",
        str(elf_file),
    ]
    if compiler_data["CLANG"] is not None:
        compile_cmd += [
            f"--target={target_toolchain}",
        ]

        # Clang does not link any runtime library with -nostdlib, unlike GCC
        # where -lgcc provides builtins (e.g. 64-bit division on RV32).
        # Resolve the compiler-rt builtins archive and link it explicitly.
        # march/mabi are passed so multilib toolchains return the right variant.
        rtlib_query_cmd = [
            f"{tools_path}/bin/{compiler}",
            f"--target={target_toolchain}",
            f"-march={march}",
            f"-mabi={mabi}",
            "--rtlib=compiler-rt",
            "-print-libgcc-file-name",
        ]
        rtlib_path = run_cmd(
            cmd=rtlib_query_cmd,
            report=report,
            cwd=None,
            env=None,
            error_patterns=None,
            warning_patterns=None,
            highlight_patterns=None,
            log_file=None,
            timeout=30,
            check=False,
            capture_output=True,
        ).strip()
        if rtlib_path and Path(rtlib_path).exists():
            report.info(f"Link compiler-rt builtins: {rtlib_path}")
            compile_cmd += [rtlib_path]
        else:
            report.warning(
                f"compiler-rt builtins not found ({rtlib_path}), "
                "link may fail on missing builtins (e.g. __umoddi3)",
            )

    run_cmd(
        cmd=compile_cmd,
        report=report,
        cwd=None,
        env=None,
        error_patterns=["error"],
        warning_patterns=["warning"],
        highlight_patterns=None,
        log_file=compile_dir / "compile.log",
        timeout=90,
        check=False,
        capture_output=False,
    )

    if elf_file.exists():
        report.success("Compilation successful")
    else:
        report.analyze_log(
            compile_dir / "compile.log",
            error_patterns=["error"],
            warning_patterns=["warning"],
            env_patterns=[
                r"no such file or directory",
                r"command not found",
                r"cannot execute",
            ],
            fail_on_error=False,
        )
        report.error_exit("Compilation failed")

    # ==========================================================
    # Objdump
    # ==========================================================
    report.step("Objdump")

    compile_cmd = [f"{tools_path}/bin/{objdump}", "-D", str(elf_file)]

    run_cmd(
        cmd=compile_cmd,
        report=report,
        cwd=None,
        env=None,
        error_patterns=None,
        warning_patterns=None,
        highlight_patterns=None,
        log_file=objdump_file,
        timeout=90,
        check=False,
        capture_output=False,
    )

    if objdump_file.exists():
        report.success("Objdump generated")
    else:
        report.error_exit("Objdump failed", env=True)

    # ==========================================================
    # Section size report
    # ==========================================================
    report.step("Sections size reporting")

    compile_cmd = ["size", "-A", str(elf_file)]

    run_cmd(
        cmd=compile_cmd,
        report=report,
        cwd=None,
        env=None,
        error_patterns=None,
        warning_patterns=None,
        highlight_patterns=None,
        log_file=size_file,
        timeout=90,
        check=False,
        capture_output=False,
    )

    if size_file.exists():
        report.success("Size report generated")
    else:
        report.error_exit("Size report failed", env=True)

    # ==========================================================
    # Symbols extraction
    # ==========================================================
    report.step("Symbols extraction")

    # One `nm` invocation for all symbols. Addresses are recorded in the
    # build manifest (raw hex, consumed by the *_uvm_run and spike-run
    # recipes) and in the report as `0x...`.
    wanted_symbols = ["tohost", "GLOBAL_PATTERN_start", "GLOBAL_PATTERN_end"]

    nm_output = run_cmd(
        cmd=[f"{tools_path}/bin/{nm}", str(elf_file)],
        report=report,
        cwd=None,
        env=None,
        error_patterns=None,
        warning_patterns=None,
        highlight_patterns=None,
        log_file=None,
        timeout=90,
        check=False,
        capture_output=True,
    )

    symbols = {}
    for line in nm_output.splitlines():
        parts = line.split()
        if len(parts) >= 3 and parts[2] in wanted_symbols:
            symbols[parts[2]] = parts[0]

    for symbol_name in wanted_symbols:
        if symbol_name in symbols:
            report.success(f"{symbol_name}: 0x{symbols[symbol_name]}")
        else:
            report.warning(f"{symbol_name} not found")

    if symbols:
        report.metric("Symbols", {k: f"0x{v}" for k, v in symbols.items()})

    # ==========================================================
    # BUILD MANIFEST
    # ==========================================================
    write_manifest(
        compile_dir,
        "sw-compile",
        {
            "target": target,
            "toolchain": toolchain,
            # Version of the binary behind the `toolchain` label, so an ELF
            # can be traced back to the compiler that produced it.
            "compiler_version": compiler_version,
            "test_name": test_name,
            "src_files": src_files,
            "inc_dirs": inc_dirs,
            "linker_file": linker_file,
            "options": options,
            "march": march,
            "mabi": mabi,
            "preprocessor_directives": preprocessor_directives,
            # Iterations compiled in the benchmark binary: the run recipes
            # read it back to compute the per-MHz score. Single source of
            # truth so the score cannot diverge from the executed binary.
            "benchmark_iterations": benchmark_iterations,
            # Symbol addresses (raw hex, no 0x prefix) consumed by the
            # simulation recipes (*_uvm_run plusargs, spike-run check)
            "symbols": symbols,
        },
        report=report,
    )

    # ==========================================================
    # List
    # ==========================================================
    report.step("Generated files")
    gen_files = [
        elf_file,
        objdump_file,
        size_file,
    ]
    generated = []
    for genfile in gen_files:
        if genfile.exists():
            report.info(f"> {genfile}")
            generated.append(str(genfile.relative_to(repo_dir)))

    # ==========================================================
    # BUILD REPORT
    # ==========================================================
    # Section sizes are a useful PASS metric (check what was built)
    if size_file.exists():
        size_rows = {}
        for line in size_file.read_text().splitlines():
            parts = line.split()
            if len(parts) >= 2 and (parts[0].startswith(".") or parts[0] == "Total"):
                try:
                    size_rows[parts[0]] = int(parts[1])
                except ValueError:
                    size_rows[parts[0]] = parts[1]
        if size_rows:
            report.metric("Section sizes (bytes)", size_rows)

    report.log("Generated files", generated)

    report.end("Completed")
