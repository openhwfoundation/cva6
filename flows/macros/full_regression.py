# Copyright 2026 Thales France
#
# Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
# You may obtain a copy of the License at https://solderpad.org/licenses/
#
# Original Author: Yannick Casamatta (yannick.casamatta@thalesgroup.com)

# Please refer to flows/README.md to add target

# The pipeline is declared here, one target and one testlist per line: the
# length is the list of targets, not code to split.
# pylint: disable=too-many-lines

"""
Whole regression pipeline in a single working directory.

This macro is the regression pipeline, run without a CI engine: the
recipes are called directly, in dependency order, in one Git checkout. Nothing is passed through artifacts and the
repositories are cloned once, so the pipeline can be replayed locally or
on a single machine.

Jobs form a dependency graph executed by the small scheduler included
below, with two independent limits:

- `--jobs`: how many recipes run at the same time;
- one semaphore per CAD tool license pool, so recipes sharing the same
  licenses are counted together (VCS elaboration + VCS simulation share
  the `vcs` pool, Spyglass runs alone, synthesis runs alone). Software
  compilations and Python/RTL lints take no license and are not capped.

Every recipe keeps writing its own `build/**/cook_report.yml`, so the
final `merge-reports` + `report-html` build the same dashboard as the CI
does; they are always run, even when jobs failed.
"""

import os
import random
from functools import partial
from pathlib import Path
import yaml
import typer

from flows.patterns.coremark import coremark
from flows.patterns.dhrystone import dhrystone
from flows.patterns.fpga_bootrom import bootrom_out_dir, fpga_bootrom
from flows.patterns.hello_world import hello_world
from flows.patterns.pk_hello_world import pk_hello_world
from flows.patterns.zephyr_hello_world import zephyr_hello_world
from flows.recipes.black_python_formating import black_python_formating
from flows.recipes.dc_shell_synth import dc_shell_synth, PreProcOption
from flows.recipes.docs_build import docs_build
from flows.recipes.fpga_linux_boot import BOOT_TIMEOUT, fpga_linux_boot
from flows.recipes.git_dependencies import git_dependencies
from flows.recipes.merge_reports import merge_reports
from flows.recipes.pk_build import pk_build
from flows.recipes.pylint_run import pylint_run
from flows.recipes.quartus_fpga_build import quartus_fpga_build
from flows.recipes.quartus_fpga_program import quartus_fpga_program
from flows.recipes.report_html import report_html
from flows.recipes.riscv_isa_modify import riscv_isa_modify
from flows.recipes.rtl_lint import rtl_lint
from flows.recipes.self_check import self_check
from flows.recipes.spyglass_design_read import spyglass_design_read
from flows.recipes.spyglass_run import spyglass_run, RunType
from flows.recipes.sw_compile_testlist import sw_compile_testlist
from flows.recipes.uvm_run_testlist import uvm_run_testlist, Simulator
from flows.recipes.vcs_uvm_comp import vcs_uvm_comp
from flows.recipes.vcs_testharness_comp import vcs_testharness_comp
from flows.recipes.vcs_testharness_run import vcs_testharness_run
from flows.recipes.vcs_uvm_run import vcs_uvm_run
from flows.recipes.verible_rtl_formating import verible_rtl_formating
from flows.recipes.verilator_testharness_comp import verilator_testharness_comp
from flows.recipes.verilator_testharness_run import verilator_testharness_run
from flows.recipes.yosys_synth import yosys_synth
from flows.recipes.vivado_fpga_build import vivado_fpga_build
from flows.recipes.vivado_fpga_program import vivado_fpga_program
from flows.utils.job_scheduler import JobFailure, Scheduler
from flows.utils.fpga_board import is_altera_board
from flows.utils.recipe_report import RecipeReport
from flows.utils.rtl_config import parse_rtl_cfg
from flows.utils.uart_boot import DEFAULT_EXPECT
from flows.utils.autocompletion import (
    AlteraBoard,
    AnyBoard,
    CompMode,
    FpgaBoard,
    TechnoOption,
    ToolchainOption,
    TraceMode,
    UvmVerbosity,
    autocompletion_target,
)

app = typer.Typer()


# ==========================================================
# PIPELINE DEFINITION
# ==========================================================

# Targets of the pipeline, by group (config/README.md): the products of the
# members (cv...), the FPGA configurations (fpga_linux_), the profiles and
# reference points (profile_), and the summits (summit_), the points of the
# configuration matrix that cover every structural combination left.
TARGETS = [
    # Product: the embedded core of the cv32a60x-v6.0.0 release
    "cv32a60x",
    # Product: the superscalar embedded core of the cv32a60x-v6.0.0 release
    "cv32a65x",
    # FPGA: the RV64 Linux configuration of the genesys2 and agilex7 boards
    "fpga_linux_cv64a6",
    # FPGA: the RV32 Linux configuration of the genesys2 board
    "fpga_linux_cv32a6",
    # Profile RVI20U32, and the smallest core
    "profile_rvi20u32",
    # Profile RVI20U64, and the smallest RV64 core
    "profile_rvi20u64",
    # The smallest core with code compression (C, Zcb, Zcmp, Zcmt)
    "profile_tinyc32",
    # Profile RVM23 (draft), as close as the core supports
    "profile_rvm23u32",
    # The highest CoreMark on RV32, on AXI and on OBI
    "profile_perf32_axi",
    "profile_perf32_obi",
    # Profile RVA20S64
    "profile_rva20s64",
    # Profile RVA22S64, as close as the core supports
    "profile_rva22s64",
    # Profile RVA23S64, as close as the core supports
    "profile_rva23s64",
    # The highest CoreMark on RV64 with Linux, on AXI
    "profile_perf64_axi",
    # Configuration matrix
    "summit_titlis",
    "summit_pilatus",
    "summit_saentis",
    "summit_eiger",
    "summit_pizpalue",
    "summit_toedi",
    "summit_galenstock",
    "summit_dammastock",
    "summit_oldenhorn",
    "summit_dom",
    "summit_weisshorn",
    "summit_matterhorn",
    "summit_grandcombin",
    "summit_dentblanche",
    "summit_nadelhorn",
    "summit_grandesjorasses",
    "summit_finsteraarhorn",
    "summit_monterosa",
    "summit_lyskamm",
    "summit_barredesecrins",
    "summit_grandparadis",
]

# Testlists run per target. A testlist whose
# name ends with `_v` (virtual memory tests) needs the F extension, added
# to the target ISA by the riscv-isa-modify recipe before compiling.
#
# Feature testlists follow the configuration of the target:
#   base_rv32_fp_p, base_rv64_fp_p  RVF on RV32, RVD on RV64
#   base_rv32_v, base_rv64_v  an MMU and TvalEn (the page fault handler reads
#                  stval)
#   base_pmp       PMP entries
#   base_rv64_pmp  PMP entries and RVS on RV64
#   base_rv64_pmp_mmu  PMP entries and an MMU on RV64
#   base_rv64_pmp_tval  PMP entries, RVA and TvalEn on RV64 (one test runs an
#                  AMO, the trap handlers check mtval)
#   base_rv64_pmp_mmu_tval  base_rv64_pmp_mmu with TvalEn
#   base_rv32_amo_p, base_rv64_amo_p  RVA; base_rv32_amo_v, base_rv64_amo_v
#                  RVA, an MMU and TvalEn
#   base_zcmt, base_rv64_zcmt  RVZCMT on RV32, RV64
#   base_rv32_ma_fetch, base_rv64_ma_fetch  every target built with GCC (the
#                  test does not build with LLVM)
#   base_csr       every target without RVH (base_rv64_h holds the RVH variant)
#   base_zicbom    RVZiCbom, RVS and RVU
#   base_zicbom_h  RVZiCbom and RVH
#   base_rv64_s    RVS on RV64
#   base_rv64_h    RVH
#   base_rv64_h_pmp  RVH and PMP entries
#   base_rv64_h_hpm  RVH and PerfCounterEn (the test reads the DTLB miss counter)
#   base_rv64_h_zicntr  RVH and RVZicntr
#   base_rv32_mmu  Sv32 with PMP entries (the tests program pmpcfg)
#   base_be        BigEndianEn (big endian data accesses)
#   base_rv32_be_mmu, base_rv64_be_mmu  BigEndianEn with Sv32, Sv39
#   base_le        not BigEndianEn (endianness control bits read-only zero)
#   base_ni        a non-idempotent region covering 0x1000
#   base_obi       the OBI testbench (MEM_OBI), which injects bus errors
#   base_zcmp, base_rv64_zcmp  RVZCMP on RV32, RV64
#   dcache_wt, dcache_wb, dcache_wt_wb  CacheWritePolicy of an HPDcache with
#                  RVZiCbom
#   testlist_sdtrig  Sdtrig
#   testlist_sdtrig_h  Sdtrig and RVH
TESTLISTS = {
    "cv32a60x": ["base_rv32_p", "base_csr", "base_le", "base_obi"],
    "cv32a65x": [
        "base_rv32_p",
        "base_pmp",
        "base_csr",
        "base_le",
        "base_obi",
    ],
    "fpga_linux_cv64a6": [
        "base_rv64_p",
        "base_rv64_s",
        "base_rv64_ma_fetch",
        "base_rv64_fp_p",
        "base_rv64_v",
        "base_pmp",
        "base_rv64_pmp",
        "base_rv64_pmp_tval",
        "base_rv64_pmp_mmu",
        "base_rv64_pmp_mmu_tval",
        "base_rv64_amo_p",
        "base_rv64_amo_v",
        "base_csr",
        "base_zicbom",
        "dcache_wt",
        "base_le",
    ],
    "fpga_linux_cv32a6": [
        "base_rv32_p",
        "base_rv32_ma_fetch",
        "base_rv32_v",
        "base_rv32_mmu",
        "base_pmp",
        "base_rv32_amo_p",
        "base_rv32_amo_v",
        "base_csr",
        "base_zicbom",
        "dcache_wt",
        "base_le",
        "base_ni",
    ],
    "profile_rvi20u32": [
        "base_rv32_p",
        "base_rv32_ma_fetch",
        "base_csr",
        "base_le",
        "base_obi",
    ],
    "profile_rvi20u64": [
        "base_rv64_p",
        "base_rv64_ma_fetch",
        "base_csr",
        "base_le",
        "base_obi",
    ],
    "profile_tinyc32": [
        "base_rv32_p",
        "base_rv32_ma_fetch",
        "base_csr",
        "base_zcmt",
        "base_zcmp",
        "base_le",
        "base_obi",
    ],
    "profile_rvm23u32": [
        "base_rv32_p",
        "base_rv32_ma_fetch",
        "base_pmp",
        "base_csr",
        "base_zcmt",
        "base_zcmp",
        "base_le",
        "base_obi",
    ],
    "profile_perf32_axi": [
        "base_rv32_p",
        "base_rv32_ma_fetch",
        "base_rv32_fp_p",
        "base_pmp",
        "base_rv32_amo_p",
        "base_csr",
        "base_le",
    ],
    "profile_perf32_obi": [
        "base_rv32_p",
        "base_rv32_ma_fetch",
        "base_rv32_fp_p",
        "base_pmp",
        "base_rv32_amo_p",
        "base_csr",
        "base_le",
        "base_obi",
    ],
    "profile_rva20s64": [
        "base_rv64_p",
        "base_rv64_s",
        "base_rv64_ma_fetch",
        "base_rv64_fp_p",
        "base_rv64_v",
        "base_pmp",
        "base_rv64_pmp",
        "base_rv64_pmp_tval",
        "base_rv64_pmp_mmu",
        "base_rv64_pmp_mmu_tval",
        "base_rv64_amo_p",
        "base_rv64_amo_v",
        "base_csr",
        "base_le",
        "base_zicbom",
        "dcache_wt",
    ],
    "profile_rva22s64": [
        "base_rv64_p",
        "base_rv64_s",
        "base_rv64_ma_fetch",
        "base_rv64_fp_p",
        "base_rv64_v",
        "base_pmp",
        "base_rv64_pmp",
        "base_rv64_pmp_tval",
        "base_rv64_pmp_mmu",
        "base_rv64_pmp_mmu_tval",
        "base_rv64_amo_p",
        "base_rv64_amo_v",
        "base_csr",
        "base_le",
        "base_zicbom",
        "dcache_wt",
    ],
    "profile_rva23s64": [
        "base_rv64_p",
        "base_rv64_s",
        "base_rv64_ma_fetch",
        "base_rv64_fp_p",
        "base_rv64_v",
        "base_pmp",
        "base_rv64_pmp",
        "base_rv64_pmp_tval",
        "base_rv64_pmp_mmu",
        "base_rv64_pmp_mmu_tval",
        "base_rv64_amo_p",
        "base_rv64_amo_v",
        "base_rv64_h",
        "base_rv64_h_zicntr",
        "base_rv64_h_hpm",
        "base_rv64_h_pmp",
        "base_rv64_svnapot",
        "base_le",
        "base_zicbom_h",
        "dcache_wt",
    ],
    "profile_perf64_axi": [
        "base_rv64_p",
        "base_rv64_s",
        "base_rv64_ma_fetch",
        "base_rv64_fp_p",
        "base_rv64_v",
        "base_pmp",
        "base_rv64_pmp",
        "base_rv64_pmp_tval",
        "base_rv64_pmp_mmu",
        "base_rv64_pmp_mmu_tval",
        "base_rv64_amo_p",
        "base_rv64_amo_v",
        "base_csr",
        "base_le",
        "base_zicbom",
        "dcache_wb",
    ],
    "summit_titlis": [
        "base_rv32_p",
        "base_rv32_ma_fetch",
        "base_csr",
        "base_le",
        "dcache_ecc",
        "testlist_sdtrig",
    ],
    "summit_pilatus": [
        "base_rv32_p",
        "base_rv32_ma_fetch",
        "base_rv32_fp_p",
        "base_pmp",
        "base_csr",
        "base_zcmt",
        "base_be",
    ],
    "summit_saentis": [
        "base_rv32_p",
        "base_rv32_ma_fetch",
        "base_rv32_fp_p",
        "base_csr",
        "base_be",
        "base_rv32_be_mmu",
        "base_zicbom",
        "dcache_wt",
        "dcache_ecc",
        "testlist_sdtrig",
    ],
    "summit_eiger": [
        "base_rv32_p",
        "base_rv32_ma_fetch",
        "base_csr",
        "base_le",
    ],
    "summit_pizpalue": [
        "base_rv32_p",
        "base_rv32_ma_fetch",
        "base_rv32_fp_p",
        "base_pmp",
        "base_csr",
        "base_zcmt",
        "base_zcmp",
        "base_le",
        "dcache_ecc",
        "testlist_sdtrig",
    ],
    "summit_toedi": [
        "base_rv32_p",
        "base_rv32_ma_fetch",
        "base_pmp",
        "base_csr",
        "base_zcmt",
        "base_le",
        "testlist_sdtrig",
    ],
    "summit_galenstock": [
        "base_rv32_p",
        "base_rv32_ma_fetch",
        "base_pmp",
        "base_csr",
        "base_zcmt",
        "base_le",
        "dcache_ecc",
        "testlist_sdtrig",
    ],
    "summit_dammastock": [
        "base_rv32_p",
        "base_rv32_ma_fetch",
        "base_rv32_fp_p",
        "base_csr",
        "base_be",
        "base_rv32_be_mmu",
        "base_obi",
    ],
    "summit_oldenhorn": [
        "base_rv32_p",
        "base_rv32_ma_fetch",
        "base_rv32_fp_p",
        "base_csr",
        "base_zcmt",
        "base_be",
        "base_obi",
        "testlist_sdtrig",
    ],
    "summit_dom": [
        "base_rv64_p",
        "base_rv64_s",
        "base_rv64_ma_fetch",
        "base_rv64_fp_p",
        "base_rv64_v",
        "base_rv64_amo_p",
        "base_rv64_amo_v",
        "base_rv64_h",
        "base_rv64_h_hpm",
        "base_le",
        "base_zicbom_h",
        "dcache_wb",
        "dcache_ecc",
    ],
    "summit_weisshorn": [
        "base_rv64_p",
        "base_rv64_s",
        "base_rv64_ma_fetch",
        "base_rv64_v",
        "base_pmp",
        "base_rv64_pmp",
        "base_rv64_pmp_tval",
        "base_rv64_pmp_mmu",
        "base_rv64_pmp_mmu_tval",
        "base_rv64_amo_p",
        "base_rv64_amo_v",
        "base_rv64_h",
        "base_rv64_h_zicntr",
        "base_rv64_h_hpm",
        "base_rv64_h_pmp",
        "base_rv64_zcmp",
        "base_le",
        "base_zicbom_h",
        "dcache_wt",
        "testlist_sdtrig_h",
    ],
    "summit_matterhorn": [
        "base_rv64_p",
        "base_rv64_s",
        "base_rv64_ma_fetch",
        "base_rv64_v",
        "base_rv64_amo_p",
        "base_rv64_amo_v",
        "base_rv64_h",
        "base_rv64_h_hpm",
        "base_rv64_zcmp",
        "base_le",
        "base_zicbom_h",
        "dcache_wt",
        "dcache_ecc",
        "testlist_sdtrig_h",
    ],
    "summit_grandcombin": [
        "base_rv64_p",
        "base_rv64_s",
        "base_rv64_ma_fetch",
        "base_rv64_fp_p",
        "base_pmp",
        "base_rv64_pmp",
        "base_rv64_pmp_mmu",
        "base_csr",
        "base_rv64_svnapot",
        "base_be",
        "base_rv64_be_mmu",
        "base_zicbom",
        "dcache_wt",
        "dcache_ecc",
        "testlist_sdtrig",
    ],
    "summit_dentblanche": [
        "base_rv64_p",
        "base_rv64_s",
        "base_rv64_ma_fetch",
        "base_rv64_amo_p",
        "base_rv64_h",
        "base_rv64_h_zicntr",
        "base_rv64_h_hpm",
        "base_rv64_svnapot",
        "base_le",
        "base_zicbom_h",
        "dcache_wt",
    ],
    "summit_nadelhorn": [
        "base_rv64_p",
        "base_rv64_ma_fetch",
        "base_pmp",
        "base_csr",
        "base_rv64_zcmt",
        "base_rv64_zcmp",
        "base_be",
        "testlist_sdtrig",
    ],
    "summit_grandesjorasses": [
        "base_rv64_p",
        "base_rv64_s",
        "base_rv64_ma_fetch",
        "base_rv64_fp_p",
        "base_rv64_amo_p",
        "base_rv64_h",
        "base_rv64_h_hpm",
        "base_rv64_svnapot",
        "base_le",
        "base_zicbom_h",
        "dcache_wt_wb",
        "dcache_ecc",
        "testlist_sdtrig_h",
    ],
    "summit_finsteraarhorn": [
        "base_rv64_p",
        "base_rv64_ma_fetch",
        "base_pmp",
        "base_csr",
        "base_be",
        "dcache_ecc",
    ],
    "summit_monterosa": [
        "base_rv64_p",
        "base_rv64_s",
        "base_rv64_ma_fetch",
        "base_rv64_fp_p",
        "base_csr",
        "base_be",
        "base_zicbom",
        "dcache_wt_wb",
        "dcache_ecc",
        "testlist_sdtrig",
    ],
    "summit_lyskamm": [
        "base_rv64_p",
        "base_rv64_ma_fetch",
        "base_pmp",
        "base_rv64_amo_p",
        "base_csr",
        "base_rv64_zcmt",
        "base_rv64_zcmp",
        "base_le",
        "dcache_ecc",
        "testlist_sdtrig",
    ],
    "summit_barredesecrins": [
        "base_rv64_p",
        "base_rv64_s",
        "base_rv64_ma_fetch",
        "base_rv64_v",
        "base_rv64_amo_p",
        "base_rv64_amo_v",
        "base_rv64_h",
        "base_rv64_zcmp",
        "base_le",
        "base_obi",
        "testlist_sdtrig_h",
    ],
    "summit_grandparadis": [
        "base_rv64_p",
        "base_rv64_s",
        "base_rv64_ma_fetch",
        "base_csr",
        "base_rv64_zcmp",
        "base_rv64_svnapot",
        "base_be",
        "base_rv64_be_mmu",
        "base_obi",
        "testlist_sdtrig",
    ],
}


# Benchmark patterns, compiled with the same
# toolchain for every target so the scores stay comparable
BENCHMARKS = {"coremark": coremark, "dhrystone": dhrystone}
BENCHMARK_TOOLCHAIN = "gcc-15"

# RTL formatting is target independent: run it once
VERIBLE_TARGET = "cv32a60x"

# Targets the documentation is built for. The specifications are derived
# from the configuration package, so one build per target would render the
# same RISC-V manuals twenty times for a handful of attribute differences.
DOCS_TARGETS = [
    "cv32a60x",
]

# Targets the Spyglass lint runs on. It takes a licence and several minutes
# per target, and only these have a clean baseline today. Add a target
# here once its lint passes.
SPYGLASS_TARGETS = [
    "cv32a60x",
    "cv32a65x",
]

# Hello world under the RISC-V proxy kernel, on the TestHarness: a target
# with U-mode and the debug module, through which pk talks to HTIF. Each
# one on one simulator, pk running about 2.5M cycles.
PK_TARGETS = {
    "fpga_linux_cv32a6": "verilator",
    "fpga_linux_cv64a6": "vcs",
}
PK_TOOLCHAIN = "gcc-15"
PK_TEST = "pk-hello-world"
PK_BUILD_JOBS = 4

# Hello world of Zephyr on the TestHarness, for a target Zephyr has a board
# for: the Genesys 2 SoCs, whose memory map is the one of the harness. The
# SDK toolchain: Zephyr needs a libgcc built for -mcmodel=medany.
ZEPHYR_TARGETS = {
    "fpga_linux_cv32a6": "verilator",
    "fpga_linux_cv64a6": "vcs",
}
ZEPHYR_TOOLCHAIN = "zephyr-sdk"
ZEPHYR_TEST = "zephyr-hello-world"
# Wall clock limit of a run under pk: about 2 minutes on Verilator, 4 on VCS
PK_SIM_TIMEOUT = 1200

# Targets of the GTECH synthesis, which needs dc_shell but no PDK: the two
# embedded products. A licence at a time, 2 to 10 minutes each.
GTECH_TARGETS = [
    "cv32a60x",
    "cv32a65x",
]

# Values of the --<category>-targets options other than a list of targets
ALL_TARGETS = "all"
NO_TARGET = "none"

# Per-test simulation timeout of the hello-world and testlist jobs: a
# hung simulation must fail on its own instead of blocking the pipeline
SIM_TIMEOUT = 300

# Cycle budget of the same jobs. A test that derails never writes tohost, so it
# would otherwise run until the wall clock timeout: stopping on a cycle count
# fails it as soon as it is clearly lost. Twice the longest of those jobs
# that passes, cm_push_pop_all, whose length depends on the memory stalls
# the OBI agent draws; the benchmarks are much longer and keep the testbench
# default.
SIM_CYCLE_TIMEOUT = 200000

# Cycle budget of the testlists run in virtual memory (name ending in _v):
# their environment builds the page tables and walks every page before the
# test, through the MMU and the memory stalls. Twice the longest that passes.
SIM_CYCLE_TIMEOUT_V = 600000

# Benchmarks are long: they keep the default recipe timeout
BENCHMARK_SIM_TIMEOUT = 3000

# Parallel jobs of the C++ build of a Verilator model. It takes no licence,
# so it is the job slots of --jobs that bound how many build at once.
VERILATOR_JOBS = 8

# FPGA images: (target, board). A bitstream is built once the RTL of its
# target elaborates, then the board is programmed and Linux booted on it.
# The two images of a board share it through its pool, one boot at a time.
# The Altera one needs a runner wired to its board: it is only run when
# asked, with --altera.
FPGA_TARGETS = [
    ("fpga_linux_cv32a6", FpgaBoard.genesys2),
    ("fpga_linux_cv64a6", FpgaBoard.genesys2),
]
ALTERA_TARGETS = [
    ("fpga_linux_cv64a6", AlteraBoard.agilex7),
]

# Toolchain of $CONFIG_DIR/compiler.yml the bootloader is built with
FPGA_TOOLCHAIN = "gcc-15"

# Parallel jobs of Vivado, within the job slot it takes
VIVADO_JOBS = 8

# License pools: recipes sharing a pool are counted together
VCS = "vcs"
SPYGLASS = "spyglass"
SYNTH = "synth"
VIVADO = "vivado"
QUARTUS = "quartus"


def board_pool(board):
    """
    Pool of a physical board, one slot: programming it and booting Linux
    on it take the board as a whole, and two jobs driving it at the same
    time would boot one bitstream and read the console of the other.

    It serialises the jobs of one run only: two pipelines on the same
    board are kept apart by the resource_group of the CI job.
    """
    return f"board:{board.value}"


# Where merge-reports and report-html write the final dashboard
REPORTS_DIR = Path("artifacts") / "reports"


# ==========================================================
# RECIPE CALL HELPERS
# ==========================================================


def _recipe(recipe, **kwargs):
    """
    Call a recipe function and turn a non-zero exit into a JobFailure.

    Recipes report their own errors (console + cook_report.yml) and end
    with `typer.Exit`; the scheduler only needs the verdict.
    """
    try:
        recipe(**kwargs)
    except typer.Exit as exc:
        code = getattr(exc, "exit_code", 1)
        if code:
            raise JobFailure(f"recipe failed (exit code {code})") from exc


# Toolchain of a target that has no my_<target>_toolchain entry in
# $CONFIG_DIR/compiler.yml, so a configuration created on the fly runs
# without editing it
DEFAULT_TOOLCHAIN = "default_toolchain"


def _toolchain(name):
    "Resolve a toolchain name declared in $CONFIG_DIR/compiler.yml"
    try:
        return ToolchainOption(name)
    except ValueError as exc:
        raise JobFailure(f"unknown toolchain: {name}") from exc


def _target_toolchain(target):
    "Toolchain of a target: its own entry, else the default one"
    try:
        return ToolchainOption(f"my_{target}_toolchain")
    except ValueError:
        return _toolchain(DEFAULT_TOOLCHAIN)


def _yaml_key(path, key):
    "Read a single key from a YAML file written by a recipe or a config"
    try:
        with path.open("r") as f:
            data = yaml.safe_load(f) or {}
    except OSError as exc:
        raise JobFailure(f"cannot read {path}: {exc}") from exc
    except yaml.YAMLError as exc:
        raise JobFailure(f"cannot parse {path}: {exc}") from exc
    if key not in data:
        raise JobFailure(f"no '{key}' key in {path}")
    return data[key]


def _target_xlen(target):
    "Register width of a target, from the march of its isa.yml"
    isa = Path.cwd() / "config" / "target" / target / "isa.yml"
    try:
        march = _yaml_key(isa, "march")
    except JobFailure:
        return 32  # only names a build directory; the job reports the error
    return 64 if str(march).startswith("rv64") else 32


def _march_with_f(target, quiet):
    """
    ISA string of the target with the F extension added.

    Virtual memory testlists need floating point support: the CI derives
    the march with the riscv-isa-modify recipe instead of hardcoding a
    second ISA string per target.
    """
    repo_dir = Path.cwd()
    march = _yaml_key(repo_dir / "config" / "target" / target / "isa.yml", "march")
    _recipe(
        riscv_isa_modify,
        target=target,
        isa_string=march,
        add_ext=["f"],
        remove_ext=[],
        quiet=quiet,
    )
    modified = repo_dir / "build" / target / "riscv_isa_modify" / "modified_isa.yml"
    return _yaml_key(modified, "modified_isa")


# ==========================================================
# JOB BODIES
# ==========================================================
#
# One function per kind of job, called with keyword arguments by the
# graph below. A job that chains several recipes fails as soon as one of
# them fails, except the testlist loops: every testlist is played, then
# the job fails.


def _rtl_cfg_bool(target, name):
    "A bit field of the configuration package of `target`, False when unread"
    cfg = Path.cwd() / "config" / "target" / target / "rtl_cfg_pkg.sv"
    try:
        return bool(parse_rtl_cfg(cfg).get(name))
    except OSError:
        return False


def _hier(target):
    """
    Return the bus the core of `target` is connected over, `obi` or `axi`.

    The `hier` of `testbench_cfg.yml`, which the UVM recipes elaborate
    from and the TestHarness recipes check. None when it cannot be read:
    the elaboration reports it, the job graph only has to choose.
    """
    cfg = Path.cwd() / "config" / "target" / target / "testbench_cfg.yml"
    try:
        with cfg.open(encoding="utf-8") as f:
            return (yaml.safe_load(f) or {}).get("hier")
    except (OSError, yaml.YAMLError):
        return None


def _job_verilator_comp(target, quiet):
    "Verilator model of the TestHarness"
    _recipe(
        verilator_testharness_comp,
        target=target,
        comp_mode=CompMode.rtl,
        trace_mode=TraceMode.notrace,
        stats=False,
        jobs=VERILATOR_JOBS,
        quiet=quiet,
    )


def _job_verilator_run(target, test_name, quiet, timeout=SIM_TIMEOUT):
    "Single test on the Verilator model of the TestHarness"
    _recipe(
        verilator_testharness_run,
        target=target,
        test_name=test_name,
        comp_mode=CompMode.rtl,
        trace_mode=TraceMode.notrace,
        interactive_gui=False,
        sim_timeout=timeout,
        run_name=None,
        quiet=quiet,
    )


def _job_fpga_bootrom(target, board, quiet):
    "Zero stage bootloader of a board, for the register width of `target`"
    _recipe(
        fpga_bootrom,
        target=target,
        toolchain=_toolchain(FPGA_TOOLCHAIN),
        board=AnyBoard(board.value),
        xlen=None,
        quiet=quiet,
    )


def _job_fpga_build(target, board, quiet):
    "Bitstream of `target` for `board`, with the tool of its vendor"
    if is_altera_board(board):
        _recipe(
            quartus_fpga_build,
            target=target,
            board=board,
            rbf=True,
            clean=True,
            quiet=quiet,
        )
    else:
        _recipe(
            vivado_fpga_build,
            target=target,
            board=board,
            mcs=False,
            clean=True,
            jobs=VIVADO_JOBS,
            quiet=quiet,
        )


def _job_fpga_boot(target, board, quiet):
    """
    Program the board with the bitstream, then boot Linux on it.

    One job holding the board for both steps: between the two, another
    job could program it with a different bitstream. The connection to
    the board comes from the environment of the runner, $HW_SERVER_URL
    and $UART_SERIAL for Xilinx, $JTAG_CABLE for Altera.
    """
    if is_altera_board(board):
        _recipe(
            quartus_fpga_program,
            target=target,
            board=board,
            cable=None,
            device_index=1,
            bitstream=None,
            quiet=quiet,
        )
    else:
        _recipe(
            vivado_fpga_program,
            target=target,
            board=board,
            hw_server=None,
            bitstream=None,
            # vivado_lab is enough to program a board, on a runner carrying
            # the lab edition only
            vivado_cmd=os.environ.get("VIVADO_CMD", "vivado"),
            quiet=quiet,
        )
    _recipe(
        fpga_linux_boot,
        target=target,
        board=AnyBoard(board.value),
        uart=None,
        cable=None,
        juart_instance=None,
        baudrate=None,
        boot_timeout=BOOT_TIMEOUT,
        expect=DEFAULT_EXPECT,
        quiet=quiet,
    )


def _job_vcs_testharness_comp(target, quiet):
    "VCS elaboration of the TestHarness"
    _recipe(
        vcs_testharness_comp,
        target=target,
        comp_mode=CompMode.rtl,
        trace_mode=TraceMode.notrace,
        stats=False,
        quiet=quiet,
    )


def _job_vcs_testharness_run(target, test_name, quiet, timeout=SIM_TIMEOUT):
    "Single test on the VCS elaboration of the TestHarness"
    _recipe(
        vcs_testharness_run,
        target=target,
        test_name=test_name,
        comp_mode=CompMode.rtl,
        trace_mode=TraceMode.notrace,
        uvm_verbosity=UvmVerbosity.low,
        sim_timeout=timeout,
        run_name=None,
        quiet=quiet,
    )


def _job_pk_compile(target, quiet):
    "Proxy kernel of the target, then the Hello world program it runs"
    _recipe(
        pk_build,
        target=target,
        toolchain=_toolchain(PK_TOOLCHAIN),
        jobs=PK_BUILD_JOBS,
        quiet=quiet,
    )
    _recipe(
        pk_hello_world, target=target, toolchain=_toolchain(PK_TOOLCHAIN), quiet=quiet
    )


def _job_zephyr_compile(target, quiet):
    "Hello world application of Zephyr"
    _recipe(
        zephyr_hello_world,
        target=target,
        toolchain=_toolchain(ZEPHYR_TOOLCHAIN),
        quiet=quiet,
    )


def _job_spyglass(target, quiet):
    "Design read then lint run, holding a single Spyglass license"
    _recipe(spyglass_design_read, target=target, quiet=quiet)
    _recipe(spyglass_run, target=target, run_type=RunType.run_cli, quiet=quiet)


def _job_sw_compile(target, quiet):
    "hello-world compiled with the toolchain of the target"
    _recipe(
        hello_world,
        target=target,
        toolchain=_target_toolchain(target),
        march=None,
        mabi=None,
        quiet=quiet,
    )


def _job_benchmark_compile(target, benchmark, quiet):
    "Benchmark compiled with the reference toolchain of the pipeline"
    _recipe(
        BENCHMARKS[benchmark],
        target=target,
        toolchain=_toolchain(BENCHMARK_TOOLCHAIN),
        march=None,
        mabi=None,
        quiet=quiet,
    )


def _job_elab(target, comp_mode, quiet):
    "VCS UVM elaboration (RTL or post-synthesis netlist)"
    _recipe(
        vcs_uvm_comp,
        target=target,
        comp_mode=comp_mode,
        trace_mode=TraceMode.notrace,
        tandem_enabled=True,
        stats=False,
        sim_profile=False,
        quiet=quiet,
    )


def _job_run(
    target,
    test_name,
    comp_mode,
    tandem,
    performance,
    timeout,
    quiet,
    cycle_timeout=None,
    run_name=None,
):
    "Single test simulation on the elaborated model"
    _recipe(
        vcs_uvm_run,
        target=target,
        test_name=test_name,
        comp_mode=comp_mode,
        trace_mode=TraceMode.notrace,
        uvm_verbosity=UvmVerbosity.none,
        tandem_enabled=tandem,
        tb_performance_mode=performance,
        stats=False,
        sim_profile=False,
        interactive_gui=False,
        run_opts=[],
        irq_delay=[],
        uvm_seed=str(random.getrandbits(31)),
        sim_timeout=timeout,
        cycle_timeout=cycle_timeout,
        run_name=run_name,
        quiet=quiet,
    )


def _job_testlist_compile(target, quiet):
    """
    Compile every testlist of the target.

    A failing testlist does not stop the others: all of them are compiled
    and the job fails at the end.
    """
    failed = []
    for testlist in TESTLISTS.get(target, []):
        try:
            march = _march_with_f(target, quiet) if testlist.endswith("_v") else None
            _recipe(
                sw_compile_testlist,
                target=target,
                toolchain=_target_toolchain(target),
                testlist=f"verif/tests/{testlist}.yaml",
                test_name=None,
                march=march,
                mabi=None,
                quiet=quiet,
            )
        except JobFailure:
            failed.append(testlist)
    if failed:
        raise JobFailure(f"failed testlist(s): {', '.join(failed)}")


def _job_testlist_run(target, quiet):
    "Run every testlist of the target, one testlist after the other"
    failed = []
    for testlist in TESTLISTS.get(target, []):
        try:
            _recipe(
                uvm_run_testlist,
                simulator=Simulator.vcs,
                target=target,
                testlist=f"verif/tests/{testlist}.yaml",
                test_name=None,
                comp_mode=CompMode.rtl,
                trace_mode=TraceMode.notrace,
                uvm_verbosity=UvmVerbosity.none,
                tandem_enabled=False,
                tb_performance_mode=False,
                stats=False,
                sim_profile=False,
                interactive_gui=False,
                run_opts=[],
                uvm_seed=str(random.getrandbits(31)),
                sim_timeout=SIM_TIMEOUT,
                cycle_timeout=(
                    SIM_CYCLE_TIMEOUT_V
                    if testlist.endswith("_v")
                    else SIM_CYCLE_TIMEOUT
                ),
                quiet=quiet,
            )
        except JobFailure:
            failed.append(testlist)
    if failed:
        raise JobFailure(f"failed testlist(s): {', '.join(failed)}")


def _job_gtech_synth(target, quiet):
    "Technology independent synthesis of the target (one license at a time)"
    _recipe(
        dc_shell_synth,
        target=target,
        techno=None,
        period=None,
        script_file="dc.tcl",
        preprocessor_defines=[PreProcOption.HPDCACHE_ASSERT_OFF],
        gtech=True,
        clean=True,
        quiet=quiet,
    )


def _job_synth(target, techno, period, quiet):
    "ASIC synthesis of the target (one license at a time)"
    _recipe(
        dc_shell_synth,
        target=target,
        techno=techno,
        period=period,
        script_file="dc.tcl",
        preprocessor_defines=[PreProcOption.HPDCACHE_ASSERT_OFF],
        gtech=False,
        clean=True,
        quiet=quiet,
    )


# ==========================================================
# GRAPH CONSTRUCTION
# ==========================================================


def _add_fpga_jobs(scheduler, target, board, elab_job, deps_job, quiet):
    """
    Bootloader, bitstream, then programming and boot of the board.

    The bitstream waits for the RTL elaboration of its target: a design
    that does not elaborate in simulation would spend hours of Vivado to
    fail in synthesis. The bootloader is built per board, and the
    bitstream consumes it.
    """
    build = Path.cwd() / "build"
    altera = is_altera_board(board)
    bootrom = scheduler.add(
        f"fpga-bootrom:{target}:{board.value}",
        partial(_job_fpga_bootrom, target=target, board=board, quiet=quiet),
        bootrom_out_dir(Path.cwd(), board, _target_xlen(target)),
        deps=[deps_job],
    )
    image = scheduler.add(
        f"fpga-build:{target}:{board.value}",
        partial(_job_fpga_build, target=target, board=board, quiet=quiet),
        build / target / ("fpga_altera" if altera else "fpga") / board.value,
        deps=[elab_job, bootrom],
        resource=QUARTUS if altera else VIVADO,
    )
    scheduler.add(
        f"fpga-boot:{target}:{board.value}",
        partial(_job_fpga_boot, target=target, board=board, quiet=quiet),
        build / target / "fpga_boot" / board.value,
        deps=[image],
        resource=board_pool(board),
    )


def _select_targets(value, default, targets):
    """
    Targets of one job category from its --<category>-targets option.

    `value` is a comma or space separated list of targets, `all` for every
    target of the run, `none` for no target, or empty for `default`. The
    result keeps the order of `targets`, and a target outside the run is
    left out: it returns the selected targets and the ones of an explicit
    list that are not in the run (a default list narrowed by --target is
    not worth a message).
    """
    names = value.replace(",", " ").split() if value else None
    if names is None:
        wanted = default
    elif names == [ALL_TARGETS]:
        wanted = targets
    elif names == [NO_TARGET]:
        wanted = []
    else:
        wanted = names
    selected = [t for t in targets if t in wanted]
    ignored = [t for t in wanted if t not in targets] if names else []
    return selected, ignored


def _build_graph(scheduler, targets, techno, period, fpga, altera, quiet, selection):
    """
    Add every pipeline job to the scheduler.

    `selection` maps a job category (docs, spyglass, gtech, synth) to the
    targets it runs on, see _select_targets().

    `scheduler.add()` takes the job name, the deferred call, the
    directory holding the cook_report.yml of the recipe, and returns the
    name so it can be used as a dependency of the next jobs.
    """
    build = Path.cwd() / "build"

    # --- Setup: environment check and external test repositories ------
    # The environment check is informative: its report is part of the
    # dashboard but a missing tool of an unused stage (synthesis, other
    # simulators) must not fail the pipeline
    scheduler.add(
        "self-check",
        partial(_recipe, self_check, quiet=quiet),
        build / "self_check",
        allow_failure=True,
    )
    # Test repositories are cloned once for the whole pipeline. The same recipe applies the patches declared on the Git
    # submodules, so the elaborations that follow see a patched tree.
    deps_job = scheduler.add(
        "git-dependencies",
        partial(
            _recipe,
            git_dependencies,
            repo=["riscv-tests", "riscv-pk", "zephyr"],
            force=False,
            quiet=quiet,
        ),
        build / "git_dependencies",
    )

    # --- Lint stage ---------------------------------------------------
    scheduler.add(
        "verible-rtl-formating",
        partial(_recipe, verible_rtl_formating, target=VERIBLE_TARGET, quiet=quiet),
        build / VERIBLE_TARGET / "verible",
    )
    scheduler.add(
        "black-python-formating",
        partial(_recipe, black_python_formating, quiet=quiet),
        build / "black_python_formating",
    )
    scheduler.add(
        "pylint-run",
        partial(_recipe, pylint_run, quiet=quiet),
        build / "pylint_run",
    )

    for target in targets:
        target_dir = build / target

        # Open-source lint of every target: no licence, a minute or two, so
        # the targets Spyglass skips are linted too (those it covers get both)
        scheduler.add(
            f"rtl-lint:{target}",
            partial(
                _recipe, rtl_lint, target=target, update_baseline=False, quiet=quiet
            ),
            target_dir / "rtl_lint",
        )

        if target in selection["spyglass"]:
            scheduler.add(
                f"spyglass:{target}",
                partial(_job_spyglass, target=target, quiet=quiet),
                target_dir / "spyglass",
                resource=SPYGLASS,
            )

        if target in selection["docs"]:
            # Depends on nothing and takes no licence, so it fills a slot
            # while the elaborations hold theirs. The rendered documents
            # stay in build/<target>/docs/, where merge-reports collects
            # them for the dashboard.
            scheduler.add(
                f"docs:{target}",
                partial(
                    _recipe,
                    docs_build,
                    target=target,
                    # Every option the recipe would default: called as a
                    # plain function it receives the Typer descriptor for
                    # the ones left out, and `list(manual)` then fails on
                    # an OptionInfo.
                    readthedoc=False,
                    manual=[],
                    sphinx=True,
                    doc_format="html",
                    strict=False,
                    clean=True,
                    quiet=quiet,
                ),
                target_dir / "docs",
            )

        # --- Software and RTL elaboration -----------------------------
        compile_job = scheduler.add(
            f"sw-compile:{target}",
            partial(_job_sw_compile, target=target, quiet=quiet),
            target_dir / "compile" / "hello-world",
        )
        elab_job = scheduler.add(
            f"elab:{target}",
            partial(_job_elab, target=target, comp_mode=CompMode.rtl, quiet=quiet),
            target_dir / "elab" / "sim_rtl",
            deps=[deps_job],  # the submodule patches must be applied before elaborating
            resource=VCS,
        )
        scheduler.add(
            f"run-sim:{target}",
            partial(
                _job_run,
                target=target,
                test_name="hello-world",
                comp_mode=CompMode.rtl,
                tandem=True,
                # The memory answers in the cycle it is asked, so the count
                # measures the pipeline alone. The run the matrix reports.
                performance=True,
                timeout=SIM_TIMEOUT,
                cycle_timeout=SIM_CYCLE_TIMEOUT,
                quiet=quiet,
            ),
            target_dir / "simulation" / "sim_rtl" / "hello-world",
            deps=[elab_job, compile_job],
            resource=VCS,
        )

        # The same binary through the other testbench or another memory:
        # - AXI: the TestHarness, on VCS and on Verilator, so the target
        #   runs hello-world three times. It has no stalling run: the AXI
        #   agent of the UVM testbench is held in zero delay mode whatever
        #   the run, so it would repeat the one above.
        # - OBI: VCS again, against the memory stalls the OBI agent
        #   randomises and the run above turns off. The TestHarness is
        #   AXI only.
        if _hier(target) == "axi":
            vcs_th_comp = scheduler.add(
                f"vcs-testharness-comp:{target}",
                partial(_job_vcs_testharness_comp, target=target, quiet=quiet),
                target_dir / "elab" / "sim_rtl_vcs_testharness",
                deps=[deps_job],
                resource=VCS,
            )
            scheduler.add(
                f"vcs-testharness-run:{target}",
                partial(
                    _job_vcs_testharness_run,
                    target=target,
                    test_name="hello-world",
                    quiet=quiet,
                ),
                target_dir / "simulation" / "sim_rtl_vcs_testharness" / "hello-world",
                deps=[vcs_th_comp, compile_job],
                resource=VCS,
            )
            verilator_comp = scheduler.add(
                f"verilator-testharness-comp:{target}",
                partial(_job_verilator_comp, target=target, quiet=quiet),
                target_dir / "elab" / "sim_rtl_verilator_testharness",
                deps=[deps_job],
            )
            scheduler.add(
                f"verilator-testharness-run:{target}",
                partial(
                    _job_verilator_run,
                    target=target,
                    test_name="hello-world",
                    quiet=quiet,
                ),
                target_dir
                / "simulation"
                / "sim_rtl_verilator_testharness"
                / "hello-world",
                deps=[verilator_comp, compile_job],
            )
            if target in PK_TARGETS:
                pk_compile = scheduler.add(
                    f"pk-hello-world:{target}",
                    partial(_job_pk_compile, target=target, quiet=quiet),
                    target_dir / "compile" / PK_TEST,
                    deps=[deps_job],
                )
                simulator = PK_TARGETS[target]
                run_job, comp_job, resource = {
                    "verilator": (_job_verilator_run, verilator_comp, None),
                    "vcs": (_job_vcs_testharness_run, vcs_th_comp, VCS),
                }[simulator]
                scheduler.add(
                    f"{simulator}-testharness-run:{target}:{PK_TEST}",
                    partial(
                        run_job,
                        target=target,
                        test_name=PK_TEST,
                        timeout=PK_SIM_TIMEOUT,
                        quiet=quiet,
                    ),
                    target_dir
                    / "simulation"
                    / f"sim_rtl_{simulator}_testharness"
                    / PK_TEST,
                    deps=[comp_job, pk_compile],
                    resource=resource,
                )
            if target in ZEPHYR_TARGETS:
                zephyr_compile = scheduler.add(
                    f"zephyr-hello-world:{target}",
                    partial(_job_zephyr_compile, target=target, quiet=quiet),
                    target_dir / "compile" / ZEPHYR_TEST,
                    deps=[deps_job],
                )
                simulator = ZEPHYR_TARGETS[target]
                run_job, comp_job, resource = {
                    "verilator": (_job_verilator_run, verilator_comp, None),
                    "vcs": (_job_vcs_testharness_run, vcs_th_comp, VCS),
                }[simulator]
                scheduler.add(
                    f"{simulator}-testharness-run:{target}:{ZEPHYR_TEST}",
                    partial(
                        run_job,
                        target=target,
                        test_name=ZEPHYR_TEST,
                        quiet=quiet,
                    ),
                    target_dir
                    / "simulation"
                    / f"sim_rtl_{simulator}_testharness"
                    / ZEPHYR_TEST,
                    deps=[comp_job, zephyr_compile],
                    resource=resource,
                )
        elif _hier(target) == "obi":
            scheduler.add(
                f"run-sim-stall:{target}",
                partial(
                    _job_run,
                    target=target,
                    test_name="hello-world",
                    comp_mode=CompMode.rtl,
                    tandem=True,
                    performance=False,
                    timeout=SIM_TIMEOUT,
                    cycle_timeout=SIM_CYCLE_TIMEOUT,
                    run_name="hello-world-stall",
                    quiet=quiet,
                ),
                target_dir / "simulation" / "sim_rtl" / "hello-world-stall",
                deps=[elab_job, compile_job],
                resource=VCS,
            )

        # --- Benchmarks -----------------------------------------------
        # A benchmark regression must not fail the pipeline: the score is
        # reported, the verdict stays a warning
        for benchmark in BENCHMARKS:
            bench_compile = scheduler.add(
                f"benchmark-compile:{target}:{benchmark}",
                partial(
                    _job_benchmark_compile,
                    target=target,
                    benchmark=benchmark,
                    quiet=quiet,
                ),
                target_dir / "compile" / benchmark,
                deps=[deps_job],
            )
            scheduler.add(
                f"benchmark-run:{target}:{benchmark}",
                partial(
                    _job_run,
                    target=target,
                    test_name=benchmark,
                    comp_mode=CompMode.rtl,
                    tandem=False,
                    performance=True,
                    timeout=BENCHMARK_SIM_TIMEOUT,
                    quiet=quiet,
                ),
                target_dir / "simulation" / "sim_rtl" / benchmark,
                deps=[elab_job, bench_compile],
                resource=VCS,
                allow_failure=True,
            )

        # --- Testlist regression --------------------------------------
        if TESTLISTS.get(target):
            testlist_compile = scheduler.add(
                f"testlist-compile:{target}",
                partial(_job_testlist_compile, target=target, quiet=quiet),
                target_dir / "compile",
                deps=[deps_job],
            )
            scheduler.add(
                f"testlist-run:{target}",
                partial(_job_testlist_run, target=target, quiet=quiet),
                target_dir / "simulation" / "sim_rtl",
                deps=[elab_job, testlist_compile],
                resource=VCS,
            )

        # --- FPGA image, board programming and Linux boot -------------
        images = (FPGA_TARGETS if fpga else []) + (ALTERA_TARGETS if altera else [])
        for fpga_target, board in images:
            if fpga_target != target:
                continue
            _add_fpga_jobs(scheduler, target, board, elab_job, deps_job, quiet)

        # --- Open-source synthesis -------------------------------------
        # Every target, no licence: after the RTL elaboration, like the
        # GTECH synthesis, so a design that does not elaborate fails once.
        # Not the FPGA targets: their memories are the dual-port RAMs of the
        # FPGA vendors, written from two processes, which only an FPGA
        # synthesis infers
        if not _rtl_cfg_bool(target, "FpgaEn"):
            scheduler.add(
                f"yosys-synth:{target}",
                partial(_recipe, yosys_synth, target=target, quiet=quiet),
                target_dir / "synthesis_yosys",
                deps=[elab_job],
            )

        # --- GTECH synthesis ------------------------------------------
        # After the RTL elaboration, like the bitstream: a design that
        # does not elaborate would hold a DC licence to fail the same way
        if target in selection["gtech"]:
            scheduler.add(
                f"synthesis-gtech:{target}",
                partial(_job_gtech_synth, target=target, quiet=quiet),
                target_dir / "synthesis_gtech",
                deps=[elab_job],
                resource=SYNTH,
            )

        # --- ASIC synthesis and gate-level simulation -----------------
        # Needs a techno, so enabled only when --techno is given
        if techno is not None and target in selection["synth"]:
            synth_job = scheduler.add(
                f"synthesis:{target}",
                partial(
                    _job_synth,
                    target=target,
                    techno=techno,
                    period=period,
                    quiet=quiet,
                ),
                target_dir / "synthesis",
                deps=[elab_job],
                resource=SYNTH,
            )
            gate_elab = scheduler.add(
                f"gate-elab:{target}",
                partial(
                    _job_elab,
                    target=target,
                    comp_mode=CompMode.gate_wc_timing,
                    quiet=quiet,
                ),
                target_dir / "elab" / "sim_gate_wc_timing",
                deps=[synth_job],
                resource=VCS,
            )
            scheduler.add(
                f"gate-run-sim:{target}",
                partial(
                    _job_run,
                    target=target,
                    test_name="hello-world",
                    comp_mode=CompMode.gate_wc_timing,
                    tandem=False,
                    performance=False,
                    timeout=BENCHMARK_SIM_TIMEOUT,
                    quiet=quiet,
                ),
                target_dir / "simulation" / "sim_gate_wc_timing" / "hello-world",
                deps=[gate_elab, compile_job],
                resource=VCS,
            )


# ==========================================================
# MACRO
# ==========================================================


@app.command()
def full_regression(
    target: list[str] = typer.Option(
        [],
        "--target",
        "-t",
        help="CVA6 user configuration (repeatable, default: every CI target)",
        autocompletion=autocompletion_target,
    ),
    jobs: int = typer.Option(
        8, "--jobs", "-j", help="Maximum number of recipes running at the same time"
    ),
    vcs_licenses: int = typer.Option(
        10, help="Concurrent VCS jobs (elaboration + simulation share the pool)"
    ),
    spyglass_licenses: int = typer.Option(1, help="Concurrent Spyglass jobs"),
    synth_licenses: int = typer.Option(1, help="Concurrent DC Shell synthesis jobs"),
    techno: TechnoOption = typer.Option(
        None, help="Enable the synthesis stage with this techno (disabled by default)"
    ),
    period: str = typer.Option("15", help="Synthesis target period"),
    docs_targets: str = typer.Option(
        "",
        help="Targets the documentation is built for: comma separated list, "
        "'all' or 'none' (default: DOCS_TARGETS)",
    ),
    spyglass_targets: str = typer.Option(
        "",
        help="Targets of the Spyglass lint: comma separated list, 'all' or "
        "'none' (default: SPYGLASS_TARGETS)",
    ),
    gtech_targets: str = typer.Option(
        "",
        help="Targets of the GTECH synthesis: comma separated list, 'all' or "
        "'none' (default: GTECH_TARGETS)",
    ),
    synth_targets: str = typer.Option(
        "",
        help="Targets of the techno synthesis and gate-level simulation, with "
        "--techno: comma separated list, 'all' or 'none' (default: all)",
    ),
    fpga: bool = typer.Option(
        True,
        help="Build, program and boot the Xilinx FPGA images (needs Vivado and "
        "the board, see FPGA_TARGETS)",
    ),
    altera: bool = typer.Option(
        False,
        help="Build, program and boot the Intel/Altera FPGA images (needs "
        "Quartus and the board, see ALTERA_TARGETS)",
    ),
    vivado_licenses: int = typer.Option(1, help="Concurrent Vivado builds"),
    quartus_licenses: int = typer.Option(1, help="Concurrent Quartus builds"),
    dry_run: bool = typer.Option(
        False, "--dry-run", help="List the jobs and their dependencies, run nothing"
    ),
    quiet: bool = typer.Option(
        False, "--quiet", "-q", help="Suppress output (errors only)"
    ),
):
    """
    Macro : run the whole CI pipeline in the current working directory.
    """
    repo_dir = Path.cwd()
    targets = list(target) or TARGETS

    # Targets of each job category, within the targets of the run
    selection = {}
    ignored = {}
    for category, value, default in (
        ("docs", docs_targets, DOCS_TARGETS),
        ("spyglass", spyglass_targets, SPYGLASS_TARGETS),
        ("gtech", gtech_targets, GTECH_TARGETS),
        ("synth", synth_targets, targets),
    ):
        selection[category], ignored[category] = _select_targets(
            value, default, targets
        )

    report = RecipeReport(
        "full-regression",
        out_dir=repo_dir / "build" / "full_regression",
        title="FULL REGRESSION",
        context={
            # Plural key: `target` is read as *the* target of a job (matrix
            # row, per-target grouping), and a list there would be taken for
            # one exotic target name.
            "targets": targets,
            "jobs": jobs,
            "vcs_licenses": vcs_licenses,
            "spyglass_licenses": spyglass_licenses,
            "synth_licenses": synth_licenses,
            "techno": techno,
            "period": period,
            "docs_targets": selection["docs"],
            "spyglass_targets": selection["spyglass"],
            "gtech_targets": selection["gtech"],
            "synth_targets": selection["synth"],
            "fpga": fpga,
            "altera": altera,
            "vivado_licenses": vivado_licenses,
            "quartus_licenses": quartus_licenses,
            "dry_run": dry_run,
        },
        quiet=quiet,
    )

    unknown = [t for t in targets if not (repo_dir / "config" / "target" / t).is_dir()]
    if unknown:
        report.error_exit(f"Unknown target(s): {', '.join(unknown)}", env=True)

    # A target of a category that is not a target at all is a typo, which
    # would silently drop the job: fail. One that exists but is not run
    # (--target narrowed the run) is only left out.
    for category, names in ignored.items():
        unknown = [
            t for t in names if not (repo_dir / "config" / "target" / t).is_dir()
        ]
        if unknown:
            report.error_exit(
                f"Unknown target(s) in --{category}-targets: {', '.join(unknown)}",
                env=True,
            )
        if names:
            report.info(
                f"--{category}-targets: not in the run, left out: {', '.join(names)}"
            )

    # Recipes write to a single shared console: their output would be
    # interleaved as soon as two of them run together. In parallel mode
    # only the pipeline progress is printed, each recipe keeping its full
    # console output in the Details of its own cook_report.yml.
    sub_quiet = quiet or jobs > 1

    # ==========================================================
    # BUILD THE JOB GRAPH
    # ==========================================================
    report.step("BUILD PIPELINE")

    # Mutable counters shared with the progress callback
    total = [0]
    done = [0]

    def on_event(kind, job, result):
        # Called from inside the scheduler lock: events are serialized,
        # so the progress lines never interleave
        if kind == "start":
            report.info(f"START {job.name}")
            return
        done[0] += 1
        detail = f" ({result.message})" if result.message else ""
        line = f"[{done[0]}/{total[0]}] {result.status.upper()} {job.name}{detail}"
        # The verdict is built from the results table at the end: a job
        # failure is only traced here, it must not fail the macro report
        if result.status == "pass":
            report.info(line)
        else:
            report.warning(line)

    scheduler = Scheduler(
        resources={
            VCS: vcs_licenses,
            SPYGLASS: spyglass_licenses,
            SYNTH: synth_licenses,
            VIVADO: vivado_licenses,
            QUARTUS: quartus_licenses,
            # One slot per board: see board_pool()
            **{board_pool(board): 1 for _, board in FPGA_TARGETS + ALTERA_TARGETS},
        },
        max_workers=jobs,
        on_event=on_event,
    )
    _build_graph(scheduler, targets, techno, period, fpga, altera, sub_quiet, selection)
    total[0] = len(scheduler.jobs)

    missing = scheduler.unknown_deps()
    if missing:
        report.error_exit(f"Unresolved job dependencies: {missing}", env=True)

    report.success(f"{total[0]} job(s) on {len(targets)} target(s)")

    # ==========================================================
    # DRY RUN: SHOW THE GRAPH ONLY
    # ==========================================================
    if dry_run:
        graph = report.metric("Pipeline jobs")
        for job in scheduler.jobs:
            graph.add_row(
                job=job.name,
                resource=job.resource or "",
                needs=", ".join(job.deps),
                report_path=job.report_dir,
            )
        report.print_metric(graph)
        report.set_label(f"{total[0]} jobs")
        report.end("Dry run completed")
        return

    # ==========================================================
    # RUN THE PIPELINE
    # ==========================================================
    report.step("RUN PIPELINE")
    results = scheduler.run()

    # One row per job, in pipeline declaration order. A failed job that is
    # allowed to fail (benchmarks) is reported as "warn" so it does not
    # change the verdict of the pipeline.
    summary = report.metric("Pipeline jobs")
    count = {"pass": 0, "fail": 0, "warn": 0, "skip": 0}
    for result in results:
        status = result.status
        if status == "fail" and result.job.allow_failure:
            status = "warn"
        count[status] += 1
        summary.add_row(
            status=status,
            job=result.job.name,
            resource=result.job.resource or "",
            duration=round(result.duration, 1),
            message=result.message,
            report_path=result.job.report_dir,
        )
    report.print_metric(summary)

    report.step("PIPELINE VERDICT")
    if count["warn"]:
        report.warning(f"{count['warn']} allowed failure(s)")
    if count["skip"]:
        report.warning(f"{count['skip']} job(s) skipped after a failed dependency")
    if count["fail"]:
        report.error(f"{count['fail']}/{total[0]} job(s) failed")
    else:
        report.success(f"All {count['pass']}/{total[0]} required job(s) passed")
    report.set_label(f"{count['pass']}/{total[0]} PASS")

    # ==========================================================
    # FINAL PIPELINE REPORT
    # ==========================================================
    # Written before merging so the verdict of the macro is part of the
    # dashboard. Like the `merge reports` job of the CI, the reports are
    # always built, even when jobs failed (`when: always`).
    report.write_report()

    report.step("MERGE REPORTS")
    pipeline_yml = REPORTS_DIR / "pipeline_report.yml"
    pipeline_html = REPORTS_DIR / "pipeline_report.html"
    for recipe, kwargs in (
        (merge_reports, {"target": None, "quiet": quiet}),
        (report_html, {"input_file": pipeline_yml, "quiet": quiet}),
    ):
        try:
            _recipe(recipe, **kwargs)
        except JobFailure as exc:
            report.error(f"{recipe.__name__}: {exc}")

    # The dashboard is the deliverable of the macro: expose it even when
    # the pipeline failed, and flag a report that was not produced
    generated = []
    for artifact in (pipeline_yml, pipeline_html):
        if (repo_dir / artifact).is_file():
            generated.append(str(repo_dir / artifact))
        else:
            report.error(f"Report not generated: {artifact}")
    if generated:
        report.log("Generated files", generated)
    if (repo_dir / pipeline_html).is_file():
        report.success(f"Dashboard: {repo_dir / pipeline_html}")

    report.end("Completed")
