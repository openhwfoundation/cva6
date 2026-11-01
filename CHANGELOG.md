# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

### Changed

- Fix non-setable MEIE bit in MIE CSR
- Bump `fpnew` to `v0.6.2`
- Restructured directories to separate CVA6 core from CVA6-APU (FPGA emulation platform for the core).  See the [README](README.md#new-directory-structure) for details.
- Bump `common_cells` to `v1.23.0`
- Bump `axi` to `v0.31.0`
- Remove `axi_node` dependency, replace with `axi_xbar` from `axi` repository

#### Moved Package files
```
include/riscv_pkg.sv                                  ==> core/include/riscv_pkg.sv
src/riscv-dbg/src/dm_pkg.sv                           ==> corev_apu/riscv-dbg/src/dm_pkg.sv
include/ariane_pkg.sv                                 ==> core/include/ariane_pkg.sv
include/std_cache_pkg.sv                              ==> core/include/std_cache_pkg.sv
include/wt_cache_pkg.sv                               ==> core/include/wt_cache_pkg.sv
src/axi/src/axi_pkg.sv                                ==> corev_apu/axi/src/axi_pkg.sv
src/register_interface/src/reg_intf.sv                ==> corev_apu/register_interface/src/reg_intf.sv
src/register_interface/src/reg_intf_pkg.sv            ==> corev_apu/register_interface/src/reg_intf_pkg.sv
include/axi_intf.sv                                   ==> core/include/axi_intf.sv
tb/ariane_soc_pkg.sv                                  ==> corev_apu/tb/ariane_soc_pkg.sv
tb/ariane_axi_soc_pkg.sv                              ==> corev_apu/tb/ariane_axi_soc_pkg.sv
include/ariane_axi_pkg.sv                             ==> core/include/ariane_axi_pkg.sv
src/fpu/src/fpnew_pkg.sv                              ==> core/fpu/src/fpnew_pkg.sv
src/fpu/src/fpu_div_sqrt_mvp/hdl/defs_div_sqrt_mvp.sv ==> core/fpu/src/fpu_div_sqrt_mvp/hdl/defs_div_sqrt_mvp.sv
```

#### Moved standalone components
```
 src/frontend/*.sv                                    ==> core/frontend/*.sv
 src/cache_subsystem/*.sv                             ==> core/cache_subsystem/*.sv (excluding std_no_dcache.sv)
 bootrom/*.sv                                         ==> corev_apu/bootrom/*.sv
 src/clint/*.sv                                       ==> corev_apu/clint/*.sv
 fpga/src/axi2apb/src/*.sv                            ==> corev_apu/fpga/src/axi2apb/src/*.sv
 fpga/src/apb_timer/*.sv                              ==> corev_apu/fpga/src/apb_timer/*.sv
 fpga/src/axi_slice/src/*.sv                          ==> corev_apu/fpga/src/axi_slice/src/*.sv
 src/axi_node/src/*.sv                                ==> corev_apu/axi_node/src/*.sv
 src/axi_riscv_atomics/src/*.sv                       ==> corev_apu/src/axi_riscv_atomics/src/*.sv
 src/axi_mem_if/src/*.sv                              ==> corev_apu/axi_mem_if/src/*.sv
 src/pmp/src/*.sv                                     ==> core/pmp/src/*.sv
 src/rv_plic/rtl/rv_plic_target.sv                    ==> corev_apu/rv_plic/rtl/rv_plic_target.sv
 src/rv_plic/rtl/rv_plic_gateway.sv                   ==> corev_apu/rv_plic/rtl/rv_plic_gateway.sv
 src/rv_plic/rtl/plic_regmap.sv                       ==> corev_apu/rv_plic/rtl/plic_regmap.sv
 src/rv_plic/rtl/plic_top.sv                          ==> corev_apu/rv_plic/rtl/plic_top.sv
 src/riscv-dbg/src/dmi_cdc.sv                         ==> corev_apu/riscv-dbg/src/dmi_cdc.sv
 src/riscv-dbg/src/dmi_jtag.sv                        ==> corev_apu/riscv-dbg/src/dmi_jtag.sv
 src/riscv-dbg/src/dmi_jtag_tap.sv                    ==> corev_apu/riscv-dbg/src/dmi_jtag_tap.sv
 src/riscv-dbg/src/dm_csrs.sv                         ==> corev_apu/riscv-dbg/src/dm_csrs.sv
 src/riscv-dbg/src/dm_mem.sv                          ==> corev_apu/riscv-dbg/src/dm_mem.sv
 src/riscv-dbg/src/dm_sba.sv                          ==> corev_apu/riscv-dbg/src/dm_sba.sv
 src/riscv-dbg/src/dm_top.sv                          ==> corev_apu/riscv-dbg/src/dm_top.sv
 src/riscv-dbg/debug_rom/debug_rom.sv                 ==> corev_apu/riscv-dbg/debug_rom/debug_rom.sv
 src/register_interface/src/apb_to_reg.sv             ==> corev_apu/register_interface/src/apb_to_reg.sv
 src/axi/src/axi_multicut.sv                          ==> corev_apu/axi/src/axi_multicut.sv
 src/common_cells/src/deprecated/generic_fifo.sv      ==> common/submodules/common_cells/src/deprecated/generic_fifo.sv
 src/common_cells/src/deprecated/pulp_sync.sv         ==> common/submodules/common_cells/src/deprecated/pulp_sync.sv
 src/common_cells/src/deprecated/find_first_one.sv    ==> common/submodules/common_cells/src/deprecated/find_first_one.sv
 src/common_cells/src/rstgen_bypass.sv                ==> common/submodules/common_cells/src/rstgen_bypass.sv
 src/common_cells/src/rstgen.sv                       ==> common/submodules/common_cells/src/rstgen.sv
 src/common_cells/src/stream_mux.sv                   ==> common/submodules/common_cells/src/stream_mux.sv
 src/common_cells/src/stream_demux.sv                 ==> common/submodules/common_cells/src/stream_demux.sv
 src/common_cells/src/exp_backoff.sv                  ==> common/submodules/common_cells/src/exp_backoff.sv
 src/axi/src/axi_cut.sv                               ==> corev_apu/axi/src/axi_cut.sv
 src/axi/src/axi_join.sv                              ==> corev_apu/axi/src/axi_join.sv
 src/axi/src/axi_delayer.sv                           ==> corev_apu/axi/src/axi_delayer.sv
 src/axi/src/axi_to_axi_lite.sv                       ==> corev_apu/axi/src/axi_to_axi_lite.sv
 src/common_cells/src/unread.sv                       ==> common/submodules/common_cells/src/unread.sv
 src/common_cells/src/sync.sv                         ==> common/submodules/common_cells/src/sync.sv
 src/common_cells/src/cdc_2phase.sv                   ==> common/submodules/common_cells/src/cdc_2phase.sv
 src/common_cells/src/spill_register.sv               ==> common/submodules/common_cells/src/spill_register.sv
 src/common_cells/src/sync_wedge.sv                   ==> common/submodules/common_cells/src/sync_wedge.sv
 src/common_cells/src/edge_detect.sv                  ==> common/submodules/common_cells/src/edge_detect.sv
 src/common_cells/src/stream_arbiter.sv               ==> common/submodules/common_cells/src/stream_arbiter.sv
 src/common_cells/src/stream_arbiter_flushable.sv     ==> common/submodules/common_cells/src/stream_arbiter_flushable.sv
 src/common_cells/src/deprecated/fifo_v1.sv           ==> common/submodules/common_cells/src/deprecated/fifo_v1.sv
 src/common_cells/src/deprecated/fifo_v2.sv           ==> common/submodules/common_cells/src/deprecated/fifo_v2.sv
 src/common_cells/src/fifo_v3.sv                      ==> common/submodules/common_cells/src/fifo_v3.sv
 src/common_cells/src/rr_arb_tree.sv                  ==> common/submodules/common_cells/src/rr_arb_tree.sv
 src/common_cells/src/deprecated/rrarbiter.sv         ==> common/submodules/common_cells/src/deprecated/rrarbiter.sv
 src/common_cells/src/stream_delay.sv                 ==> common/submodules/common_cells/src/stream_delay.sv
 src/common_cells/src/lfsr_8bit.sv                    ==> common/submodules/common_cells/src/lfsr_8bit.sv
 src/common_cells/src/lfsr_16bit.sv                   ==> common/submodules/common_cells/src/lfsr_16bit.sv
 src/common_cells/src/delta_counter.sv                ==> common/submodules/common_cells/src/delta_counter.sv
 src/common_cells/src/counter.sv                      ==> common/submodules/common_cells/src/counter.sv
 src/common_cells/src/shift_reg.sv                    ==> common/submodules/common_cells/src/shift_reg.sv
 src/tech_cells_generic/src/pulp_clock_gating.sv      ==> corev_apu/src/tech_cells_generic/src/pulp_clock_gating.sv
 src/tech_cells_generic/src/cluster_clock_inverter.sv ==> corev_apu/src/tech_cells_generic/src/cluster_clock_inverter.sv
 src/tech_cells_generic/src/pulp_clock_mux2.sv        ==> corev_apu/src/tech_cells_generic/src/pulp_clock_mux2.sv
 tb/ariane_testharness.sv                             ==> corev_apu/tb/ariane_testharness.sv
 tb/ariane_peripherals.sv                             ==> corev_apu/tb/ariane_peripherals.sv
 tb/common/uart.sv                                    ==> corev_apu/tb/common/uart.sv
 tb/common/SimDTM.sv                                  ==> corev_apu/tb/common/SimDTM.sv
 tb/common/SimJTAG.sv                                 ==> corev_apu/tb/common/SimJTAG.sv
```

#### Removed standalone components
```
src/util/axi_master_connect.sv
src/util/axi_slave_connect.sv
src/util/axi_master_connect_rev.sv
src/util/axi_slave_connect_rev.sv
```

### 4.2.0 - 2019-06-04

### Added

- Check execute PMA on instruction frontend
- Add support for non-contiguous cacheable regions to the PMA checks
- Provision exponential backoff for AMO SC in L1 D$ miss handler

### Changed

- Several small fixes to get the code running on VCS
- Fix compressed instruction decoding in tracer
- Fix privilege bug in performance counters. The counters have always been accessible in user mode.
- Fix RISC-V PK simulation bug caused due to insufficient time to init the `a0` and `a1` registers via the bootrom
- Fix bug in `wt_axi_adapter` (only appeared when dcache lines were wider than icache lines)
- Fix potentially long timing path in `axi_lite_interface`
- Fix VCS elab warning in `load_store_unit`
- Replace PLIC with implementation from lowRISC
- Re-work interrupt and debug subsystem to associate requests during decode. This improves stability on for non-idempotent loads.
- Bump `fpnew` to `v0.5.5`
- Bump `axi` to `v0.7.0`
- Bump `common_cells` to `v1.13.1`
- Bump `riscv-dbg` to `v0.1`
- Improve FPU pipelining and timing around scoreboard
- Reworked the `axilite` to PLIC shim for OpenPiton+Ariane
- Remove `in` and `out` aliases for AXI interfaces
- Fix small issues with DC synthesis
- Fix wrong dirtying of `sd` flag in `mstatus`
- Synthesis fix for `Vivado 2018.3`
- Clean-up instruction front-end, small IPC improvement
- Move to Verilator `4.014`

### 4.1.2

- Update FPU headers (license)

### 4.1.1

### Changed

- Hotfix: add missing defines for OpenPiton cache system.

### 4.1.0

### Added

- Official support for floating point unit
- Added AXI-64bit adapter for write-through cache system
- Added AXI atomic ops and exclusive access support to write-through cache system
- Provision `riscv-isa-sim` tandem simulation
- Support for preloading

### Changed

- Rerouted the JTAG from PMOD to second channel of FTDI 2232 chip on Genesys 2 board
- Increase available RAM size on Genesys II board to 1 GiB
- Fixed problem which decoded compressed hints as illegal instructions
- Reduce clock frequency of FPGA to 30 MHz to accomodate FPU
- Bugfixes in write-through cache system
- ID width fix in random delayer

### 4.0.0

### Added

- Preliminary support for A-Extension
- Preliminary FP support
- Preliminary support for OpenPiton cache system
- Commit log feature
- Provisioned `aw_top` signal for close to memory atomics
- FPGA Support
- Misc bug-fixes
- Platform Level Interrupt Controller (PLIC)
- FPGA Bootrom with capability to boot from SD Card

### Changed

- core_id / cluster_id inputs have been merged to hard_id input (interface changes)
- The three AXI ports have been merged into one (interface changes)
- [Bugfix] Wrong flagging of memory in machine mode if high bits (63-38) are not equal #136

### 3.0.0

### Added

- Added RISC-V compliant debug (interface changes)
- Implemented basic re-naming

### Changed

- [Bugfix] Cache-refill AXI logic (AXI protocol violation)
- [Bugfix] `MSTATUS` write-able through `SSTATUS` #65
- [Bugfix] PTW has protocol violation #61
- [Bugfix] Race-condition #54
- Removed timer input. Access to mtime will trap and must be handled by M-mode SW.

### 2.0.2 - 2018-04-08

### Changed

- Bugfix in flush behaviour of cache #34
- Pumped submodules

### 2.0.1 - 2018-01-26

### Added

- Improved instruction fetch front-end
- Add RAS
- Add support for Bender hardware management

### Changed

- Bugfix in non-detected illegal instruction #12
- Bugfix in non-detected illegal instruction JALR (funct3 != 0)
- Bugfix in non-detected illegal instruction FENCE (some bit-checks missing)

### 2.0.0 - 2018-01-26

### Added

- Instruction cache added
- Support for Verilator

### Changed

- CI support for verilator
- Update documentation

### 1.0.0 - 2018-01-17

### Added

- Non-blocking data cache
- Two AXI interfaces on top level, one for bypassing and one for actual cache-able regions
- Performance Counters
- Hardware multiplication (full M-Extension)
- Support for inter processor interrupts (IPI)

### Changed

- Testbench: EOC component now listening on store interface only
- Store interfaces has been simplified by removing the `valid` signal, a transaction is now considered finished as soon as the dcache gives the grant signal.
- EOC and dcache checker has been reworked to get rid of absolute path in UVM testbench
- Fix problem when bypassing the data cache

### 0.4.0 - 2017-10-13

Linux booting on FPGA.

### Added
- Support for M Extension (mul, div and reminder) in simulation
- Preliminary debug support
- Added support for cache management instructions

### Changed
- Various bug fixes (branch-prediction, PTW and TLB problems, interrupt handling)
- Fixed synthesis issues

## [0.3.0] - 2017-07-15

### Added
- Added support for device tree in Ariane's testbench

### Changed
- Bugfixes in compressed decoder (legal shifts where throwing an illegal instruction although they where legal)
- Increase memory size to 16 MB in-order to simulate a full Linux boot
- Re-worked timer facilities in the CSR section, moved to a platform RTC
- Core completed its first full Linux boot
- Changelog design, adhering to a common [standard](http://keepachangelog.com/en/1.0.0/)

## [0.2.0] - 2017-06-28

### Added
- Virtual memory support according to RISC-V privilege specification 1.11 (WIP)
- Add support for Torture test framework

### Changed
- IPC improvements
- Timing improvements
- New fetch interface, smaller and ready for macro-op fusion and dual-issue

## [0.1.0] - 2017-06-21

### Added
- Initial development, getting to a stable point
