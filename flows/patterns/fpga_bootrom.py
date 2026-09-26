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
Zero stage bootloader of the FPGA images (`bootrom_<XLEN>.sv`).

Built like any other software pattern, through `sw-compile`, plus the two
steps that turn an ELF into something the RTL can instantiate:

- the **device tree** is compiled first and linked into the binary:
  `startup.S` includes it with `.incbin "cv<XLEN>a6.dtb"`, so the board
  parameters (memory size, clock frequencies, console baudrate) reach the
  kernel through the bootloader itself;
- the ELF is then turned into a **SystemVerilog ROM** by
  `corev_apu/bootrom/gen_rom.py`, which is what `ariane_xilinx.sv`
  instantiates as `bootrom_32` / `bootrom_64`.

One ROM per register width, not per target: the FPGA top level reads
`bootrom_<XLEN>.sv` (see `fpga_src` in the root Makefile), so the same
binary serves every target of that width. Hence the ISA below.

## Why `rv<XLEN>im_zicsr`

The ISA is deliberately the smallest one every CVA6 configuration
implements, and it is **not** the `march` of the target: a single ROM is
shared by all the targets of a width, so it may only use what all of them
decode. Their `isa.yml` do not even have a common superset - the
`cv32a60x` family carries `zba_zbb_zbs_zbc`, `cv32a6_imac_sv32` carries
`zbkb` instead, and `cv32a6_ima_sv32_fpga` has `RVB: 0` and so decodes no
bitmanip at all (openhwgroup/cva6#2121). Compression is left out for the
same reason.
"""

from pathlib import Path
import shutil
import typer

from flows.recipes.sw_compile import sw_compile
from flows.utils.fpga_board import any_board_params, bootrom_defines
from flows.utils.manifest import write_manifest
from flows.utils.recipe_report import RecipeReport
from flows.utils.run_cmd import run_cmd
from flows.utils.autocompletion import (
    AnyBoard,
    ToolchainOption,
    autocompletion_target,
)

app = typer.Typer()

# Base integer ISA of the bootloader, see the module docstring. Keyed by
# register width, the only thing the ROM is specialised for.
BOOTROM_MARCH = {32: "rv32im_zicsr", 64: "rv64im_zicsr"}
BOOTROM_MABI = {32: "ilp32", 64: "lp64"}

# Compiler options of the bootloader, as the bootrom Makefile passes
# them. `-nostdlib`/`-nostartfiles`: it is the first code the core runs,
# there is no runtime under it. Kept per width because the 32 bit build is
# the one that must fit in the ROM and is built for size at -O2 while the
# 64 bit one uses -Os.
BOOTROM_OPTIONS = {
    32: ["O2", "ggdb", "W", "Wall", "fno-builtin"],
    64: ["Os", "ggdb", "Wall"],
}
BOOTROM_COMMON_OPTIONS = [
    "mcmodel=medany",
    "mexplicit-relocs",
    "ffreestanding",
    "nostdlib",
    "nodefaultlibs",
    "nostartfiles",
]

# Sources of the bootloader: the SD card and UART drivers it needs to
# find a kernel and report what it is doing, plus the startup code that
# embeds the device tree.
BOOTROM_SRC = [
    "startup.S",
    "src/main.c",
    "src/uart.c",
    "src/spi.c",
    "src/sd.c",
    "src/gpt.c",
    "src/dw_mmc.c",
    "src/bouncebuf.c",
]


def _write_dts(dts_in, dts_out, defines, has_ethernet):
    """
    Resolve the device tree template of the board.

    The substitutions are plain text, so they are done here and the
    result is readable in the recipe output directory.

    The template ends with a `/delete-node/ &eth;` line tagged
    `DELETE_ETH`. It is what removes the ethernet controller from the tree,
    so it must be **kept** on a board that has none and **dropped** on a
    board that has one - the reverse of what its name suggests, and the
    reason the original `sed` only passes `-e /DELETE_ETH/d` when
    `HAS_ETHERNET` is set.
    """
    text = dts_in.read_text(encoding="utf-8")
    # Longest names first: DRAM_SIZE_32 is a prefix-free name but
    # CLOCK_FREQUENCY is a substring of HALF_CLOCK_FREQUENCY.
    for key in sorted(defines, key=len, reverse=True):
        text = text.replace(key, str(defines[key]))
    if has_ethernet:
        text = "\n".join(line for line in text.splitlines() if "DELETE_ETH" not in line)
    dts_out.write_text(text.rstrip("\n") + "\n", encoding="utf-8")


# ==========================================================
# PATTERN
# ==========================================================


@app.command()
def fpga_bootrom(
    target: str = typer.Option(
        ...,
        "--target",
        "-t",
        help="CVA6 user configuration (selects the register width)",
        autocompletion=autocompletion_target,
    ),
    toolchain: ToolchainOption = typer.Option(
        ..., "--toolchain", "-c", help="Toolchain defined in $CONFIG_DIR/compiler.yml"
    ),
    board: AnyBoard = typer.Option(
        AnyBoard.genesys2, help="FPGA board, of either vendor"
    ),
    xlen: int = typer.Option(
        None, help="Register width, 32 or 64 (default: from the ISA of the target)"
    ),
    quiet: bool = typer.Option(
        False, "--quiet", "-q", help="Suppress output (errors only)"
    ),
):
    """
    Build the FPGA zero stage bootloader (bootrom_<XLEN>.sv).
    """
    report = RecipeReport(
        "fpga-bootrom",
        title="FPGA BOOTLOADER",
        context={
            "target": target,
            "toolchain": toolchain,
            "board": board,
            "xlen": xlen,
        },
        quiet=quiet,
    )

    repo_dir = Path.cwd()
    bootrom_dir = repo_dir / "corev_apu" / "fpga" / "src" / "bootrom"
    # One ROM per width and per board: the width selects the sources, the
    # board the parameters compiled into the device tree.
    out_dir = repo_dir / "build" / "bootrom" / board.value
    report.set_out_dir(out_dir)

    params = any_board_params(board)

    # ==========================================================
    # REGISTER WIDTH
    # ==========================================================
    report.step("Register width")

    if xlen is None:
        # Resolved from the ISA of the target, the only thing that says
        # whether a configuration is 32 or 64 bit. Imported here rather
        # than at module level: a pattern reads the target configuration
        # through the same helpers as the recipes.
        # pylint: disable-next=import-outside-toplevel
        from flows.utils.target_config import read_config_or_exit_isa

        march, _ = read_config_or_exit_isa(target, report)
        if march.startswith("rv64"):
            xlen = 64
        elif march.startswith("rv32"):
            xlen = 32
        else:
            report.error_exit(
                f"Cannot tell the register width from march {march!r} of "
                f"target '{target}': expected it to start with rv32 or rv64",
                env=True,
            )
    if xlen not in BOOTROM_MARCH:
        report.error_exit(f"Unsupported register width: {xlen}", env=True)

    test_name = f"bootrom_{xlen}"
    march = BOOTROM_MARCH[xlen]
    mabi = BOOTROM_MABI[xlen]
    report.add_context({"xlen": xlen, "march": march, "mabi": mabi})
    report.success(f"RV{xlen}: {march} / {mabi}")

    # ==========================================================
    # CLEAN
    # ==========================================================
    report.step("Clean")
    try:
        if out_dir.exists():
            shutil.rmtree(out_dir)
            report.info(f"remove {out_dir}")
    except OSError as e:
        report.error_exit(f"Clean error : {e}", env=True)

    out_dir.mkdir(parents=True, exist_ok=True)
    report.info(f"create {out_dir}")

    # ==========================================================
    # DEVICE TREE
    # ==========================================================
    # Compiled before the software: startup.S embeds the .dtb with
    # `.incbin`, so it must exist and be on the include path.
    report.step("Device tree")

    if not shutil.which("dtc"):
        report.error_exit(
            "dtc: Not found (device-tree-compiler, needed by the bootloader)",
            env=True,
        )

    # The Agilex board describes a different SoC (no Xilinx GPIO, no
    # xps-spi, an HPS instead), so it has a template of its own. Both carry
    # the same placeholders.
    suffix = "_agilex" if params.bootrom_platform == "PLAT_AGILEX" else ""
    dts_in = bootrom_dir / f"cv{xlen}a6{suffix}.dts.in"
    if not dts_in.exists():
        report.error_exit(f"Missing device tree template {dts_in}", env=True)

    defines = bootrom_defines(board)
    report.add_context(defines, table="Device tree parameters")

    dts_file = out_dir / f"cv{xlen}a6.dts"
    dtb_file = out_dir / f"cv{xlen}a6.dtb"
    _write_dts(dts_in, dts_file, defines, params.has_ethernet)
    report.info(f"device tree resolved: {dts_file}")

    run_cmd(
        cmd=["dtc", "-I", "dts", "-O", "dtb", "-o", str(dtb_file), str(dts_file)],
        report=report,
        cwd=out_dir,
        env=None,
        error_patterns=["[Ee]rror|FATAL"],
        warning_patterns=["[Ww]arning"],
        highlight_patterns=None,
        log_file=out_dir / "dtc.log",
        timeout=60,
        check=False,
        capture_output=False,
    )
    if not dtb_file.exists():
        report.error_exit(f"Device tree not compiled: {dtb_file}")
    report.success(f"Device tree compiled: {dtb_file.name}")

    # ==========================================================
    # COMPILATION
    # ==========================================================
    # Same recipe as every other pattern, so the bootloader is traceable
    # to the compiler that produced it and its ELF carries a manifest.
    # The output directory of the device tree is an include directory:
    # that is how `.incbin "cv<XLEN>a6.dtb"` of startup.S resolves.
    sw_compile(
        target=target,
        toolchain=toolchain,
        src_files=[str(bootrom_dir / src) for src in BOOTROM_SRC],
        inc_dirs=[str(out_dir), str(bootrom_dir), str(bootrom_dir / "src")],
        linker_file=str(bootrom_dir / "linker.lds"),
        options=BOOTROM_OPTIONS[xlen] + BOOTROM_COMMON_OPTIONS,
        march=march,
        mabi=mabi,
        preprocessor_directives=[
            f"CLOCK_FREQUENCY={defines['CLOCK_FREQUENCY']}",
            f"UART_BITRATE={defines['UART_BITRATE']}",
            f"XLEN={xlen}",
            params.bootrom_platform,
        ],
        benchmark_iterations=None,
        test_name=test_name,
        quiet=quiet,
    )

    elf_file = repo_dir / "build" / target / "compile" / test_name / f"{test_name}.elf"
    if not elf_file.exists():
        report.error_exit(f"Bootloader ELF not generated: {elf_file}")
    report.success(f"ELF built: {elf_file}")

    # ==========================================================
    # SYSTEMVERILOG ROM
    # ==========================================================
    # gen_rom.py names the module after the file it is given, and
    # ariane_xilinx.sv instantiates `bootrom_<XLEN>`: the binary must
    # therefore be named `bootrom_<XLEN>.img` and converted from its own
    # directory.
    report.step("Generate SystemVerilog ROM")

    objcopy = f"{repo_dir}/corev_apu/bootrom/gen_rom.py"
    bin_file = out_dir / f"{test_name}.bin"
    img_file = out_dir / f"{test_name}.img"
    sv_file = out_dir / f"{test_name}.sv"

    run_cmd(
        cmd=[
            str(_objcopy(toolchain, report)),
            "-O",
            "binary",
            str(elf_file),
            str(bin_file),
        ],
        report=report,
        cwd=out_dir,
        env=None,
        error_patterns=["[Ee]rror"],
        warning_patterns=["[Ww]arning"],
        highlight_patterns=None,
        log_file=out_dir / "objcopy.log",
        timeout=60,
        check=False,
        capture_output=False,
    )
    if not bin_file.exists():
        report.error_exit(f"Binary not extracted: {bin_file}")

    # A plain copy, with no padding: the alignment the ROM needs is done
    # by gen_rom.py, which pads to 64 bits. Kept as a copy so the .img name gen_rom.py expects exists.
    shutil.copyfile(bin_file, img_file)

    run_cmd(
        cmd=["python3", objcopy, img_file.name],
        report=report,
        cwd=out_dir,
        env=None,
        error_patterns=["[Ee]rror|Traceback"],
        warning_patterns=None,
        highlight_patterns=None,
        log_file=out_dir / "gen_rom.log",
        timeout=120,
        check=False,
        capture_output=False,
    )
    if not sv_file.exists():
        report.analyze_log(
            out_dir / "gen_rom.log",
            error_patterns=["[Ee]rror", "Traceback"],
            env_patterns=["No module named", "command not found"],
            fail_on_error=False,
        )
        report.error_exit(f"ROM not generated: {sv_file}")

    rom_bytes = img_file.stat().st_size
    report.success(f"ROM generated: {sv_file.name} ({rom_bytes} bytes)")
    report.metric("Bootloader", {"rom_bytes": rom_bytes, "module": test_name})
    report.set_label(f"{rom_bytes} B")

    # ==========================================================
    # BUILD MANIFEST
    # ==========================================================
    write_manifest(
        out_dir,
        "fpga-bootrom",
        {
            "target": target,
            "toolchain": toolchain,
            "board": board,
            "xlen": xlen,
            "march": march,
            "mabi": mabi,
            "rom_bytes": rom_bytes,
            **defines,
        },
        report=report,
    )

    # ==========================================================
    # List
    # ==========================================================
    report.step("Generated files")
    generated = []
    for genfile in (dts_file, dtb_file, bin_file, img_file, sv_file):
        if genfile.exists():
            report.info(f"> {genfile}")
            generated.append(str(genfile.relative_to(repo_dir)))

    # ==========================================================
    # BUILD REPORT
    # ==========================================================
    report.log("Generated files", generated)

    report.end("Completed")


def _objcopy(toolchain, report):
    """
    Return the objcopy of the selected toolchain.

    `compiler.yml` names the objdump and the nm of a toolchain but not its
    objcopy, which only this pattern needs: it is derived from the tool
    prefix rather than added to the schema of every entry.
    """
    # pylint: disable-next=import-outside-toplevel
    from flows.utils.config_loader import load_compiler_config

    entry = load_compiler_config().get(getattr(toolchain, "value", toolchain)) or {}
    tools_path = entry.get("TOOLS_PATH")
    prefix = entry.get("TARGET_TOOLCHAIN")
    if not tools_path or not prefix:
        report.error_exit(
            f"No TOOLS_PATH/TARGET_TOOLCHAIN for toolchain "
            f"{getattr(toolchain, 'value', toolchain)!r} in $CONFIG_DIR/compiler.yml",
            env=True,
        )
    objcopy = Path(tools_path) / "bin" / f"{prefix}-objcopy"
    if not objcopy.exists():
        report.error_exit(f"objcopy not found: {objcopy}", env=True)
    return objcopy
