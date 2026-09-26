# Copyright 2026 Thales France
#
# Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
# You may obtain a copy of the License at https://solderpad.org/licenses/
#
# Original Author: Yannick Casamatta (yannick.casamatta@thalesgroup.com)

"""
Parameters of the supported FPGA boards, AMD/Xilinx and Intel/Altera.

A board is a property of the hardware the bitstream runs on, not of the
design under test: it selects the FPGA part, the pin constraints, the
board specific defines and, for the boards wired for it, the JTAG device
to program. They are gathered here so a recipe asks for "the part of
this board" rather than repeating the table. The `BOARD` switch of the
root Makefile, `corev_apu/fpga/sourceme.sh` and the `$::env(BOARD)`
branches of the Vivado scripts carry the same values for `make fpga`.

The two vendors keep separate enums (`FpgaBoard`, `AlteraBoard`) because
their flows share nothing: Vivado against Quartus, `ariane_xilinx`
against `cva6_altera`, a TCL project against a `.qsf` assembled from CSV
files. A recipe therefore cannot be handed the board of the other vendor,
the CLI rejects it. What the two do share is the bootloader, so the
parameters it needs (`clock_hz`, `dram_size`, `uart_baudrate`,
`bootrom_platform`) live on both records and `bootrom_defines()` accepts
either.

Each mapping is total over its enum and asserted at import time (see
`target_config.top_elaborate` for the same pattern): a board added to an
enum without its parameters breaks the very first `cook.py` call instead
of failing inside a recipe. The accessors therefore take no `report` and
cannot terminate a recipe, per the convention of
`flows/CONTRIBUTING.md`.

`hw_device` is the one entry allowed to be absent. It is the JTAG device
name `vivado-fpga-program` drives, and it is only known for the boards
whose programming was actually exercised: a board without it can be built
but not programmed, and the recipes say so rather than guessing a device
name that would fail inside Vivado.
"""

from flows.utils.autocompletion import AlteraBoard, FpgaBoard


# A parameter record: one attribute per column of the table below
# pylint: disable-next=too-many-instance-attributes
class BoardParams:
    """
    Parameters of one FPGA board.

    Args:
        part: Xilinx part number (`XILINX_PART`, `create_project -part`)
        board_part: Vivado board part (`XILINX_BOARD`, `set_property board_part`)
        xdc: pin/timing constraints, relative to `corev_apu/fpga/`
        svh: board defines header, relative to `corev_apu/fpga/`
        cfgmem_interface: flash interface of `write_cfgmem` (.mcs generation)
        cfgmem_size: flash size in Mb of `write_cfgmem`
        uart_baudrate: console baudrate the bootrom is built for
        console_kind: how the console of the design is reached, "serial" or
            "juart" (see flows/utils/uart_boot.py)
        clock_hz: core clock the board is clocked at, compiled into the
            device tree and into the UART divider of the bootloader
        dram_size: usable DRAM, per register width, as a device tree value
        has_ethernet: the board carries the ethernet controller, whose node
            is dropped from the device tree when it does not
        bootrom_platform: platform macro the bootloader is compiled with
        hw_device: JTAG device programmed by Vivado, None when unknown
    """

    def __init__(
        self,
        part,
        board_part,
        xdc,
        svh,
        cfgmem_interface,
        cfgmem_size,
        uart_baudrate,
        clock_hz,
        dram_size,
        has_ethernet=True,
        console_kind="serial",
        bootrom_platform="PLAT_XILINX",
        hw_device=None,
    ):
        self.part = part
        self.board_part = board_part
        self.xdc = xdc
        self.svh = svh
        self.cfgmem_interface = cfgmem_interface
        self.cfgmem_size = cfgmem_size
        self.uart_baudrate = uart_baudrate
        self.clock_hz = clock_hz
        self.dram_size = dram_size
        self.has_ethernet = has_ethernet
        self.console_kind = console_kind
        self.bootrom_platform = bootrom_platform
        self.hw_device = hw_device


_BOARD_PARAMS = {
    FpgaBoard.genesys2: BoardParams(
        part="xc7k325tffg900-2",
        board_part="digilentinc.com:genesys2:part0:1.1",
        xdc="constraints/genesys-2.xdc",
        svh="src/genesysii.svh",
        cfgmem_interface="SPIx4",
        cfgmem_size=256,
        uart_baudrate=115200,
        clock_hz=50000000,
        dram_size={32: "0x08000000", 64: "0x40000000"},
        hw_device="xc7k325t_0",
    ),
    FpgaBoard.kc705: BoardParams(
        part="xc7k325tffg900-2",
        board_part="xilinx.com:kc705:part0:1.5",
        xdc="constraints/kc705.xdc",
        svh="src/kc705.svh",
        cfgmem_interface="SPIx4",
        cfgmem_size=128,
        uart_baudrate=115200,
        clock_hz=50000000,
        dram_size={32: "0x08000000", 64: "0x40000000"},
    ),
    FpgaBoard.vc707: BoardParams(
        part="xc7vx485tffg1761-2",
        board_part="xilinx.com:vc707:part0:1.3",
        xdc="constraints/vc707.xdc",
        svh="src/vc707.svh",
        cfgmem_interface="bpix16",
        cfgmem_size=128,
        uart_baudrate=115200,
        clock_hz=50000000,
        dram_size={32: "0x08000000", 64: "0x40000000"},
    ),
    FpgaBoard.nexys_video: BoardParams(
        part="xc7a200tsbg484-1",
        board_part="digilentinc.com:nexys_video:part0:1.1",
        xdc="constraints/nexys_video.xdc",
        svh="src/nexys_video.svh",
        cfgmem_interface="SPIx4",
        cfgmem_size=256,
        # This board is clocked slower, carries half the memory and has no
        # ethernet: the bootloader and the device tree follow, and the
        # console of fpga-linux-boot with them (see the BOARD switch of
        # corev_apu/fpga/src/bootrom/Makefile).
        uart_baudrate=57600,
        clock_hz=25000000,
        dram_size={32: "0x08000000", 64: "0x20000000"},
        has_ethernet=False,
    ),
}

assert set(_BOARD_PARAMS) == set(FpgaBoard), "missing FPGA board parameters"


# ==========================================================
# Intel / Altera
# ==========================================================


# A parameter record, like BoardParams above
# pylint: disable-next=too-many-instance-attributes
class AlteraBoardParams:
    """
    Parameters of one Intel/Altera FPGA board.

    A different record from `BoardParams`, not a superset of it: the two
    flows share no tool and no top level, so the Quartus side has no part
    number to hand to `create_project` and no `.xdc`, but a device and a
    family to write into the `.qsf`. Only the bootloader parameters are
    common, which is what `bootrom_defines()` reads.

    Args:
        device: Quartus device (`DEVICE` of the .qsf, `$ALTERA_PART`)
        family: Quartus device family (`FAMILY` of the .qsf)
        dev_kit: development kit name (`$ALTERA_BOARD`)
        uart_baudrate: console baudrate the bootrom is built for
        console_kind: how the console of the design is reached. "juart" on
            the Agilex: it instantiates `cva6_intel_jtag_uart_0` and has no
            serial pin, so the console travels over the JTAG cable
        clock_hz: core clock the board is clocked at
        dram_size: usable DRAM, per register width
        has_ethernet: the board carries the ethernet controller
        bootrom_platform: platform macro the bootloader is compiled with
        openocd_cfg: OpenOCD configuration driving the board, relative to
            `corev_apu/altera/`
        chipname: OpenOCD chip name, the JTAG scan chain is named after it
    """

    def __init__(
        self,
        device,
        family,
        dev_kit,
        uart_baudrate,
        clock_hz,
        dram_size,
        has_ethernet=True,
        console_kind="juart",
        bootrom_platform="PLAT_AGILEX",
        openocd_cfg="altera.cfg",
        chipname="agilex7",
    ):
        self.device = device
        self.family = family
        self.dev_kit = dev_kit
        self.uart_baudrate = uart_baudrate
        self.clock_hz = clock_hz
        self.dram_size = dram_size
        self.has_ethernet = has_ethernet
        self.console_kind = console_kind
        self.bootrom_platform = bootrom_platform
        self.openocd_cfg = openocd_cfg
        self.chipname = chipname


_ALTERA_BOARD_PARAMS = {
    AlteraBoard.agilex7: AlteraBoardParams(
        device="AGFB014R24B2E2V",
        family="Agilex 7",
        dev_kit="DK-DEV-AGF014E3ES",
        # Parameters of the PLAT_AGILEX branch of the bootrom Makefile: the
        # board is clocked twice as fast as the Xilinx ones.
        uart_baudrate=115200,
        clock_hz=100000000,
        dram_size={32: "0x08000000", 64: "0x40000000"},
    ),
}

assert set(_ALTERA_BOARD_PARAMS) == set(AlteraBoard), "missing Altera board parameters"


def altera_board_params(board):
    """
    Return the parameters of an Intel/Altera FPGA board.

    Total over AlteraBoard (see the assertion above), so this cannot fail.
    """
    return _ALTERA_BOARD_PARAMS[AlteraBoard(board)]


def is_altera_board(board):
    """
    True when `board` belongs to the Intel/Altera family.

    What the shared recipes branch on: the two vendors have their own
    build and programming recipes, and so their own build directories.
    Accepts the enum or its string value.
    """
    return isinstance(board, AlteraBoard) or str(getattr(board, "value", board)) in {
        b.value for b in AlteraBoard
    }


def any_board_params(board):
    """
    Return the parameters of a board of either vendor.

    Used by what is shared between the two flows, the bootloader and the
    console: they need the clock, the memory size and the console
    baudrate, which both records carry under the same names.
    """
    if is_altera_board(board):
        return altera_board_params(board)
    return board_params(board)


def bootrom_defines(board):
    """
    Return the device tree substitutions of a board, as pure values.

    The names are the placeholders of `cv<XLEN>a6.dts.in`. The timebase is
    half the core clock, as the CVA6 SoC divides it.

    Accepts a board of either vendor: the bootloader is the one artifact
    the Xilinx and the Altera flows have in common.

    Both memory sizes are returned whatever the width: each template only
    carries the placeholder of its own width (`cv32a6.dts.in` references
    `DRAM_SIZE_32`), so the unused one simply never matches.
    """
    params = any_board_params(board)
    return {
        "DRAM_SIZE_32": params.dram_size[32],
        "DRAM_SIZE_64": params.dram_size[64],
        "HALF_CLOCK_FREQUENCY": params.clock_hz // 2,
        "CLOCK_FREQUENCY": params.clock_hz,
        "UART_BITRATE": params.uart_baudrate,
    }


def board_params(board):
    """
    Return the parameters of an FPGA board.

    Total over FpgaBoard (see the assertion above), so this cannot fail:
    the board has already been validated by Typer, which is the only way
    a recipe obtains one.
    """
    return _BOARD_PARAMS[FpgaBoard(board)]


# Vivado IP cores instantiated by the FPGA top level, in the order the
# `corev_apu/fpga/Makefile` generates them. Each name is both the IP
# directory under `corev_apu/fpga/xilinx/` and the `.xci` basename.
FPGA_IPS = [
    "xlnx_axi_clock_converter",
    "xlnx_axi_dwidth_converter",
    "xlnx_axi_dwidth_converter_dm_master",
    "xlnx_axi_dwidth_converter_dm_slave",
    "xlnx_axi_quad_spi",
    "xlnx_axi_gpio",
    "xlnx_clk_gen",
    "xlnx_dpti_clk",
    "xlnx_mig_7_ddr3",
]


def ip_dir(repo_dir, ip_name):
    "Return the Vivado project directory of an IP core"
    return repo_dir / "corev_apu" / "fpga" / "xilinx" / ip_name


def _ip_sources(repo_dir, ip_name):
    "Return the directory holding the generated files of an IP core"
    return ip_dir(repo_dir, ip_name) / f"{ip_name}.srcs" / "sources_1" / "ip" / ip_name


def ip_xci(repo_dir, ip_name):
    """
    Return the `.xci` of an IP core, its definition.

    Written by `create_ip`, so it exists as soon as the IP has been
    *declared*, well before it is usable. Use `ip_is_generated()` to tell
    whether the IP can be read by a design build.
    """
    return _ip_sources(repo_dir, ip_name) / f"{ip_name}.xci"


def ip_dcp(repo_dir, ip_name):
    """
    Return the `.dcp` of an IP core, its synthesized checkpoint.

    Produced by the IP synthesis run, which is the last step of the
    generation and the one a design build actually consumes
    (`ERROR: [Runs 36-527] DCP does not exist` otherwise).
    """
    return _ip_sources(repo_dir, ip_name) / f"{ip_name}.dcp"


def ip_is_generated(repo_dir, ip_name):
    """
    True when an IP core is complete enough to be read by a design build.

    The `.xci` alone is not evidence of that: `create_ip` writes it first,
    and an IP whose synthesis run failed (a missing licence, an
    interrupted build) leaves the definition behind without the
    checkpoint, which would look cached and fail much later as a `DCP
    does not exist` error in the middle of the design build. The
    checkpoint is the mark, so an incomplete IP is generated again.
    """
    return ip_dcp(repo_dir, ip_name).exists()


# Include directories of the FPGA elaboration, relative to the repository
# root. Same list as the `set_property include_dirs` of
# `corev_apu/fpga/scripts/run.tcl`, made repository relative so the
# generated script does not depend on the Vivado working directory.
FPGA_INCDIRS = [
    "corev_apu/fpga/src/axi_sd_bridge/include",
    "vendor/pulp-platform/common_cells/include",
    "vendor/pulp-platform/axi/include",
    "vendor/pulp-platform/obi/include",
    "core/cache_subsystem/hpdcache/rtl/include",
    "corev_apu/register_interface/include",
    "corev_apu/instr_tracing/ITI/include",
    "core/include",
]

# Register macros of common_cells, read as a Verilog header with the
# board defines of the board (`BoardParams.svh`).
FPGA_GLOBAL_INCLUDE = (
    "vendor/pulp-platform/common_cells/include/common_cells/registers.svh"
)

# Top module of the FPGA design, and the design constraints applying to
# it whatever the board.
FPGA_TOP = "ariane_xilinx"
FPGA_COMMON_XDC = "constraints/ariane.xdc"


# ==========================================================
# Intel / Altera flow
# ==========================================================

# Top module of the Altera design: another top level than the Xilinx one,
# with its own peripherals and a vJTAG debug bridge
# (`corev_apu/altera/src/cva6_altera.sv`).
ALTERA_TOP = "cva6_altera"

# Platform Designer systems, elaborated before the project is written: the
# RTL they generate is part of the sources, and `system` carries the HPS.
# Maps the system name (and so the directory it generates into) to the
# `qsys-script` that builds it.
ALTERA_QSYS = {
    "interconnect": "interconnect.tcl",
    "system": "hps_cva6_altera.tcl",
}

# IP cores of the Altera design, in the order corev_apu/altera/Makefile
# generates them. Each is a `qsys-script` producing a `.ip` file, which
# `quartus_ipgenerate` then turns into RTL.
ALTERA_IPS = [
    "test_mm_ccb_0.tcl",
    "cva6_intel_jtag_uart_0.tcl",
    "ed_synth_emif_fm_0.tcl",
    "emif_cal.tcl",
    "iddr_intel.tcl",
    "io_pll.tcl",
    "iobuf.tcl",
    "oddr_intel.tcl",
    "vJTAG.tcl",
]

# Assignments of `settings.csv` the board table owns instead: the device
# and the family come from `AlteraBoardParams`, the top level from
# `ALTERA_TOP`. Letting both through would emit each twice, and Quartus
# would silently keep whichever came last - so the board a recipe was
# asked for could differ from the one it builds.
ALTERA_QSF_OVERRIDDEN = ("TOP_LEVEL_ENTITY", "DEVICE", "FAMILY")
