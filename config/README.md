<!--
Copyright 2026 Thales France

Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
You may obtain a copy of the License at https://solderpad.org/licenses/

Original Author: Yannick Casamatta (yannick.casamatta@thalesgroup.com)
-->
# CVA6 Target Configurations

This directory contains the configuration files of the CVA6 processor variants built and verified by the CI. Only the products are maintained by an organisation; the other groups are presets and option crosses (see [Available Targets](#available-targets)).

## Table of Contents

- [Overview](#overview)
- [Available Targets](#available-targets)
- [Target Directory Structure](#target-directory-structure)
- [Configuration Files Reference](#configuration-files-reference)
- [Creating a New Target](#creating-a-new-target)
- [Validation and CI](#validation-and-ci)
- [Best Practices](#best-practices)

## Overview

Each target configuration defines a complete CVA6 variant with specific:
- ISA extensions and parameters
- RTL configuration package
- Memory map and linker script
- SPIKE reference model configuration
- Testbench flavour (OBI or AXI)
- Expected performance, area and lint baselines for CI validation
- RTL file lists for simulation, synthesis and FPGA
- Its category, description and profile, shown in the dashboard

These configurations ensure that each CVA6 variant can be consistently built, simulated, and validated across different flows and tools.

## Available Targets

The targets fall in four groups, told apart by the prefix of their name and
by the `category` key of their `doc.yml`, which sorts them into the sections
of the dashboard (`official`, `fpga`, `profile`, `cross`):

| Prefix | Group |
|---|---|
| `cv...` | **Products**: configurations of the members, named by them. On the OpenHW repositories their name starts with `cv`. |
| `fpga_linux_` | **FPGA**: the configurations that boot Linux on a board. They are kept apart so that the parameters the platform depends on (FPGA RAMs, cache sizes for timing) evolve with the board, not with the other targets. |
| `profile_` | **Profiles and reference points**: the RISC-V profiles the core comes closest to, named after the profile with its XLEN (`rva22s64`), and credible reference points (the smallest core with compression, the fastest ones). |
| `summit_` | **Option crosses**: points named after Alpine summits (3000 m for RV32, 4000 m for RV64) that cross the configuration parameters that change the structure of the RTL, to check that each option keeps working whatever the others: the options must vary independently. They are generated: their options may change without notice, do not build a product on them. |

### Products

| Target | Role |
|---|---|
| `cv32a60x` | Embedded core maintained by Thales: scalar, OBI, no PMP. Its configuration of the cv32a60x-v6.0.0 tag reached TRL5, verified within the TRISTAN project. |
| `cv32a65x` | Superscalar embedded core maintained by Thales: OBI, PMP. Its configuration of the cv32a60x-v6.0.0 tag reached TRL5, verified within the TRISTAN project. |

`cv32a60x` and `cv32a65x` keep the configuration of the `cv32a60x-v6.0.0`
tag, with three changes: `DcacheByteSize` 2048 (2028 was a typo),
`AxiIdWidth` 5 (required by the HPDcache) and Zifencei, which the tests use.
The parameters added since the tag are set to the value that disables them.

### FPGA

| Target | Role |
|---|---|
| `fpga_linux_cv32a6` | Reference 32-bit configuration to boot Linux on the Genesys 2 board: rv32imac, Sv32, S and U, PMP, FPGA RAMs. |
| `fpga_linux_cv64a6` | Reference 64-bit configuration to boot Linux on the Genesys 2 board, also built for the Agilex 7 board: rv64gc with B, Sv39, S and U, PMP, CVXIF, FPGA RAMs. |

### Profiles and reference points

| Target | Role |
|---|---|
| `profile_rvi20u32` | Profile RVI20U32, and the smallest core: scalar, one commit port, no branch prediction, no PMP, no CVXIF, no debug, no counters |
| `profile_rvi20u64` | Profile RVI20U64, and the smallest RV64 core: the options of profile_rvi20u32 on RV64 |
| `profile_tinyc32` | The smallest core with code compression: profile_rvi20u32 plus C, Zcb, Zcmp and Zcmt |
| `profile_rvm23u32` | Profile RVM23 (microcontroller, draft), as close as the core supports |
| `profile_perf32_axi` | The highest CoreMark on RV32: superscalar with ALU bypass, private-history branch predictor of 256 entries, AXI HPDcache with 16 KiB I-cache, F, no Zcb |
| `profile_perf32_obi` | The highest CoreMark on RV32: superscalar with ALU bypass, private-history branch predictor of 256 entries, OBI without cache, F, no Zcb |
| `profile_rva20s64` | Profile RVA20S64 |
| `profile_rva22s64` | Profile RVA22S64, as close as the core supports |
| `profile_rva23s64` | Profile RVA23S64, as close as the core supports |
| `profile_perf64_axi` | The highest CoreMark on RV64 with Linux: superscalar with ALU bypass, private-history branch predictor of 256 entries, Sv39 with the shared TLB, write-back AXI HPDcache, no Zcb |

#### Support of the RISC-V profiles

What the core lacks for each profile, checked in the RTL. The same list is
in the `profile:` key of the `doc.yml` of each profile target, which the
dashboard shows: the profile next to the target, red with the count of
missing extensions, and their list in the detail of the target. Update both when an extension is added to the core.

| Extension | State in CVA6 | RVA22S64 | RVA23S64 |
|---|---|---|---|
| Zicond | supported |  | required |
| Zicbom | supported | required | required |
| Zcb | supported |  | required |
| B (Zba, Zbb, Zbs) | supported | required | required |
| Svnapot | supported on RV64 |  | required |
| Svade | supported: A and D not set fault | required | required |
| Zicbop | partial: prefetches execute as no-ops | required | required |
| Zihintpause | partial: pause executes as a full fence | required | required |
| Zicboz | **missing**: cbo.zero not decoded | required | required |
| Zfhmin | **missing**: only through XF16, with D on RV64 | required | required |
| Svpbmt | **missing**: menvcfg.PBMTE not implemented | required | required |
| Svinval | **missing**: sinval.vma not decoded | required | required |
| V | **missing**: no vector unit |  | required |
| Zfa | **missing** |  | required |
| Zawrs | **missing** |  | required |
| Zimop, Zcmop | **missing** |  | required |
| Sstc | **missing**: no stimecmp |  | required |
| Sscofpmf | **missing**: no counter overflow |  | required |
| Ssnpm, Supm | **missing**: no pointer masking |  | required |
| Zkt | **not guaranteed**: the divider stops early on some operands |  | required |
| Misaligned accesses | trap (allowed, slow) | allowed | allowed |

RVI20U32, RVI20U64 and RVA20S64 are fully supported. RVM23 is checked against its
draft and has to be reviewed when it is ratified.

### Configuration matrix

The parameters of `rtl_cfg_pkg.sv` that change the structure of the RTL
(which modules are instantiated, the width of the datapaths, the number of
ports) were grouped by the parts of the core they couple. Inside each group
every legal combination is built by at least one target; independent
options and sizes take each of their values at least once. The products and
the FPGA targets are left out of this count, the profiles and reference
points are in it.

| Group | Parameters combined |
|---|---|
| Fetch and issue | XLEN, RVC, SuperscalarEn and NrCommitPorts |
| Decode | RVC, Zcmp, Zcmt, CvxifEn, SuperscalarEn |
| Execute | SuperscalarEn, ALUBypass, FPU present, CvxifEn |
| Privilege and translation | XLEN, S, U, H, MmuPresent, UseSharedTlb, SvnapotEn |
| Memory | MemSubsystem and CacheWritePolicy, two-phase loads (MmuPresent), Zcmt |
| FP | XLEN, F, D, XF16ALT |
| Counters | PerfCounterEn, Zicntr, Zihpm, XLEN |
| Triggers | Sdtrig with or without debug action, commit ports, XLEN and H |
| Branch prediction | BHT, private-history BHT or none, RVC, SuperscalarEn |
| ALU | XLEN, B, ZKN |

Single values: BigEndianEn, DclsEn, DcacheEccEnable, PMP entries, TvalEn,
DebugEn, NrLoadBufEntries (1, 2 to 15, 16 and more), NrLoadPipeRegs and
NrStorePipeRegs (0, 1, 2), each also paired with the memory subsystem or the
privilege where they interact.

The axes of each summit target are in the `matrix:` key of its `doc.yml`.

| Target | XLEN | Superscalar | Zcmp/Zcmt | Privilege | MMU | Memory | FP | Sdtrig |
|---|---|---|---|---|---|---|---|---|
| `summit_titlis` | 32 | SS | none | M | nommu | HPD-WB | none | nodbg |
| `summit_pilatus` | 32 | SS | t | MU | nommu | HPD-WB | F | off |
| `summit_saentis` | 32 | SS | none | MSU | mmu | HPD-WT | F | dbg |
| `summit_eiger` | 32 | 2c | none | M | nommu | HPD-WT | none | off |
| `summit_pizpalue` | 32 | SS | pt | MU | nommu | HPD-WT | F | nodbg |
| `summit_toedi` | 32 | 1c | t | M | nommu | HPD-WT_WB | none | dbg |
| `summit_galenstock` | 32 | SS+byp | t | M | nommu | HPD-WT_WB | none | nodbg |
| `summit_dammastock` | 32 | SS+byp | none | MSU | mmu+stlb | OBI | F | off |
| `summit_oldenhorn` | 32 | 1c | t | MSU | nommu | OBI | F | nodbg |
| `summit_dom` | 64 | 1c | none | MSUH | mmu+stlb | HPD-WB | FD+xf | off |
| `summit_weisshorn` | 64 | 1c | p | MSUH | mmu | HPD-WT | none | dbg |
| `summit_matterhorn` | 64 | 1c | p | MSUH | mmu+stlb | HPD-WT | none | nodbg |
| `summit_grandcombin` | 64 | 2c | none | MSU | mmu+stlb+napot | HPD-WT | FD | nodbg |
| `summit_dentblanche` | 64 | SS+byp | none | MSUH | mmu+stlb+napot | HPD-WT | none | off |
| `summit_nadelhorn` | 64 | SS+byp | pt | MU | nommu | HPD-WT | none | dbg |
| `summit_grandesjorasses` | 64 | SS | none | MSUH | mmu+napot | HPD-WT_WB | FD+xf | nodbg |
| `summit_finsteraarhorn` | 64 | 1c | none | M | nommu | HPD-WT_WB | none | off |
| `summit_monterosa` | 64 | 1c | none | MSU | nommu | HPD-WT_WB | FD | nodbg |
| `summit_lyskamm` | 64 | 1c | pt | M | nommu | HPD-WT_WB | none | dbg |
| `summit_barredesecrins` | 64 | SS | p | MSUH | mmu | OBI | none | dbg |
| `summit_grandparadis` | 64 | SS | p | MSU | mmu+napot | OBI | none | dbg |

## Target Directory Structure

Each target directory contains the following files:

```
config/target/<target_name>/
├── doc.yml                   # Category, description, profile and matrix point; documentation header
├── isa.yml                   # ISA string and ABI for the toolchain
├── spike.yaml                # SPIKE reference model configuration
├── link.ld                   # Linker script for software compilation
├── rtl_cfg_pkg.sv            # RTL configuration package (SystemVerilog)
├── testbench_cfg.yml         # Testbench flavour (OBI or AXI)
├── Flist.cva6                # RTL file list for simulation and lint
├── Flist.cva6_gate           # RTL file list for gate-level simulation
├── Flist.cva6_synth          # RTL file list for synthesis (DC Shell, Yosys)
├── Flist.cva6_fpga           # RTL file list of the Xilinx FPGA build (Vivado)
├── Flist.cva6_altera         # RTL file list of the Altera FPGA build (Quartus)
├── expected_values.yml       # Baselines of the cycle counts and of the area
├── expected_lint.yml         # Baseline of the open-source lint (slang, Verilator)
├── expected_spyglass.rpt     # Baseline of the Spyglass lint (optional)
└── verif/regression.yaml     # Test list of the former verif/sim flow (optional, not read by cook.py)
```

## Configuration Files Reference

### `doc.yml`

Read by `docs-build` for the header of the generated documentation, and by
`merge-reports` to sort and describe the target in the dashboard. The full
list of keys is in [flows/README.md](../flows/README.md#docs-build).

```yaml
authors:
  - "Looking for a maintainer"
category: profile            # official, fpga, profile or cross
role: "Profile RVA22S64, as close as the core supports"
profile:                     # profile targets only
  name: RVA22S64
  version: "ratified, profiles 1.0"
  missing: [Zicboz, Zfhmin, Svpbmt, Svinval]
  partial: [Zihintpause, Zicbop]
matrix:                      # point of the configuration matrix
  XLEN: "64"
  # ...
  description: "cv64a6_imafdc_sv39_hpdwt_nox_b_bht_ldb2"
```

The `profile:` lists must match the
[support table](#support-of-the-risc-v-profiles), and `matrix:` the axes of
the [configuration matrix](#configuration-matrix).

### `isa.yml`

Defines the ISA string and ABI used by the compilation toolchain.

**Format:**
```yaml
march: <RISC-V ISA string>
mabi: <ABI specification>
```

**Example:**
```yaml
march: rv32imc_zicsr_zifencei_zba_zbb_zbs_zbc_zcb
mabi: ilp32
```

**Fields:**
- `march`: RISC-V architecture string (ISA extensions)
- `mabi`: Application Binary Interface specification

**Common march patterns:**
- `rv32i` / `rv64i` - Base integer ISA (32-bit / 64-bit)
- `m` - Integer multiplication and division
- `a` - Atomic instructions
- `f` - Single-precision floating-point
- `d` - Double-precision floating-point
- `c` - Compressed instructions
- `zicsr` - CSR instructions
- `zifencei` - Instruction-fetch fence
- `zbb`, `zbs`, `zba` - Bitmanip extensions
- `zcb`, `zcmt`, `zcmp` - Code-size reduction extensions

**Common mabi patterns:**
- `ilp32` - 32-bit integer, long, pointer
- `ilp32f` - ilp32 + hardware float
- `ilp32d` - ilp32 + hardware double
- `lp64` - 64-bit long, pointer
- `lp64f` - lp64 + hardware float
- `lp64d` - lp64 + hardware double

### `spike.yaml`

Configuration for the SPIKE ISA simulator (reference model for tandem verification).

**Structure:**
```yaml
spike_param_tree:
  # Memory configuration
  bootrom: <bool>
  bootrom_base: <address>
  bootrom_size: <bytes>
  dram: <bool>
  dram_base: <address>
  dram_size: <bytes>

  # Execution limits
  max_steps: <number>
  max_steps_enabled: <bool>

  # ISA configuration
  isa: <ISA string>
  priv: <privilege modes>

  # Core-specific configuration
  core_configs:
    - isa: <ISA string>
      extensions: <custom extensions>
      boot_addr: <address>
      marchid_override_mask: <hex>
      marchid_override_value: <hex>
      # ... (CSR configurations)
```

**Key Parameters:**
- **Memory Map**: Defines bootrom and DRAM regions
- **ISA**: Must match the RTL configuration
- **Privilege Modes**: M (Machine), S (Supervisor), U (User)
- **CSR Overrides**: Configure CSR accessibility and reset values

### `link.ld`

Linker script that defines the memory layout for compiled software.

**Key Sections:**
```ld
OUTPUT_ARCH("riscv")
ENTRY(_start)

SECTIONS
{
  . = 0x80000000;           /* Start address */

  .text.init : { *(.text.init) }
  .text : { *(.text*) }
  .rodata : { *(.rodata*) }
  .data : { *(.data*) }
  .bss : { *(.bss*) }

  /* Special sections for simulation */
  .tohost : { *(.tohost) }
  .fromhost : { *(.fromhost) }
}
```

**Important Elements:**
- **Entry Point**: `ENTRY(_start)` - defines the program start
- **Memory Base**: Typically `0x80000000` for DRAM start
- **Test Sections**: `.tohost` / `.fromhost` for testbench communication
- **Alignment**: Sections should be properly aligned for the target

### `rtl_cfg_pkg.sv`

SystemVerilog package that defines all RTL configuration parameters, in a
`config_pkg::cva6_user_cfg_t`. The fields and their meaning are in
`core/include/config_pkg.sv`. Every field is written with its value; the
only `localparam`s are the ones read outside the package (by `riscv_pkg`,
`ariane_pkg`, the AXI package and the testbench).

**Structure:**
```systemverilog
package cva6_config_pkg;

  localparam CVA6ConfigXlen = 64;

  localparam CVA6ConfigRvfiTrace = 1;

  localparam CVA6ConfigAxiIdWidth = 5;  // axi_pkg.sv
  localparam CVA6ConfigAxiAddrWidth = 64;  // axi_pkg.sv
  localparam CVA6ConfigAxiDataWidth = 64;  // axi_pkg.sv
  localparam CVA6ConfigDataUserWidth = CVA6ConfigXlen;  // axi_pkg.sv

  localparam config_pkg::cva6_user_cfg_t cva6_cfg = '{
      XLEN: unsigned'(CVA6ConfigXlen),
      VLEN: unsigned'(64),
      FpgaEn: bit'(0),
      // ... (every field of cva6_user_cfg_t)
      MemSubsystem: config_pkg::MEM_HPDCACHE_AXI,
      // ...
  };

endpackage
```

**Key Parameters:**
- `XLEN`: 32 or 64
- `RVF`, `RVD`, `RVA`, `RVB`, `RVC`, `RVH`, `RVS`, `RVU`, `RVZCB`, `RVZCMP`, `RVZCMT`...: ISA extensions and privilege modes
- `SuperscalarEn`, `ALUBypass`, `NrCommitPorts`: issue width; a superscalar core takes two commit ports
- `MmuPresent`, `UseSharedTlb`, `SvnapotEn`: address translation
- `NrPMPEntries`: PMP
- `MemSubsystem` (`MEM_OBI` or `MEM_HPDCACHE_AXI`), `CacheWritePolicy`, cache sizes: memory subsystem; with `MEM_OBI` the core has no cache and the cache parameters are ignored
- `BPType`, `BHTEntries`, `BHTHist`: branch prediction
- `NrLoadPipeRegs`, `NrStorePipeRegs`, `NrLoadBufEntries`: load and store pipeline
- `FpgaEn`: FPGA RAMs; `FpgaAlteraEn` selects the Altera ones

### `testbench_cfg.yml`

Selects the testbench the core is wrapped in.

```yaml
hier: obi   # or axi
```

It must agree with `MemSubsystem` in `rtl_cfg_pkg.sv` (`MEM_OBI` with
`obi`, `MEM_HPDCACHE_AXI` with `axi`): the recipes refuse a mismatch.

### `Flist.cva6`

List of RTL files to compile for simulation (RTL mode) and lint.

**Format:**
```tcl
// Comments start with //
-F ${CVA6_REPO_DIR}/core/Flist.cva6
${CVA6_REPO_DIR}/config/target/<target>/rtl_cfg_pkg.sv
```

**Directives:**
- `-F <file>` - Include another file list
- `+incdir+<path>` - Add include directory
- `<path>` - Direct file path
- `${VAR}` - Environment variable expansion

### `Flist.cva6_gate`

List of RTL files for gate-level simulation (post-synthesis).

**Differences from Flist.cva6:**
- May exclude certain modules replaced by gate-level netlists
- May include technology library wrappers
- May include additional timing models

### `Flist.cva6_synth`

List of RTL files for synthesis (`dc-shell-synth`, `yosys-synth`).

It includes `core/Flist.cva6_synth`, which is `core/Flist.cva6` with the
HPDcache SRAMs read as their blackbox models: the behavioural ones would
synthesise every bit of the caches into a register. A target can list only
the files it needs instead.

### `Flist.cva6_fpga` and `Flist.cva6_altera`

RTL of the FPGA builds: `vivado-fpga-build` reads `Flist.cva6_fpga`, which
includes `corev_apu/fpga/Flist.cva6_fpga`; `quartus-fpga-build` reads
`Flist.cva6_altera`, which includes `corev_apu/altera/Flist.cva6_altera`.
Add target-specific sources after the include to override the common list.

### `expected_values.yml`

Baselines the recipes compare their results with. Every key is optional: a
missing file or key is a warning and the check is skipped.

```yaml
coremark_cycle: 213436
dhrystone_cycle: 17079
gates: 142628
yosys_cells: 110015
yosys_registers: 8707
```

| Key | Recipe | Check |
|---|---|---|
| `coremark_cycle`, `dhrystone_cycle` | `vcs-uvm-run` (and the other UVM simulators) | cycles of the measured iteration, must match exactly |
| `gates` | `dc-shell-synth` | gate count (NAND2 equivalents), ±5 % |
| `gtech_cells`, `gtech_registers` | `dc-shell-synth --gtech` | ±5 % |
| `yosys_cells`, `yosys_registers` | `yosys-synth` | ±5 % |
| `fpga_luts`, `fpga_wns` | `vivado-fpga-build` | LUTs ±2 %, worst negative slack |
| `altera_alms`, `altera_slack` | `quartus-fpga-build` | ALMs ±2 %, worst slack |

Each value is also published as a KPI of the pipeline report, so the
dashboard shows its evolution.

### `expected_lint.yml`

Baseline of `rtl-lint`: the number of diagnostics per tool, severity and
rule. Any error fails, and so does a new rule or a higher count; a lower
count passes. Rewrite it with:

```bash
./cook.py rtl-lint -t <target> --update-baseline
```

### `expected_spyglass.rpt` (Optional)

Baseline of `spyglass-run`, compared rule by rule in the same way. Only the
targets of `SPYGLASS_TARGETS` in `flows/macros/full_regression.py` are linted
by the CI.

## Creating a New Target

### 1. Choose a Target Name

Pick the prefix of its [group](#available-targets): `cv...` for a product
maintained by an organisation, `fpga_linux_` for a board image, `profile_`
for a profile or a reference point, `summit_` for an option cross.

### 2. Start from an Existing Target

`hwconfig-forge` copies a reference target and overrides parameters of its
`rtl_cfg_pkg.sv`, checking that each name exists:

```bash
./cook.py hwconfig-forge -t profile_rva22s64 -f <new_target> \
  -p "NrLoadPipeRegs=1" -p "CvxifEn=1"
```

Or copy a whole directory:

```bash
cp -r config/target/cv32a60x config/target/<new_target>          # 32-bit embedded
cp -r config/target/profile_rva22s64 config/target/<new_target>  # 64-bit
```

### 3. Align the Configuration Files

- `rtl_cfg_pkg.sv`: the parameters of the core.
- `isa.yml` and `spike.yaml`: the same ISA and privilege modes as
  `rtl_cfg_pkg.sv`, or the tandem comparison fails.
- `testbench_cfg.yml`: `hier` matching `MemSubsystem`.
- `doc.yml`: `category`, `role`, and `profile` or `matrix` for its group.
- `link.ld` and the `Flist.*`: only when the memory map or the RTL differ.

### 4. Validate the Configuration

```bash
# Smoke test with the Spike tandem
./cook.py hello-world -t <new_target> -c gcc-15
./cook.py vcs-uvm-comp -t <new_target> --tandem-enabled
./cook.py vcs-uvm-run -t <new_target> -n hello-world --tandem-enabled

# Test lists
./cook.py sw-compile-testlist -t <new_target> -c gcc-15 -l <testlist>
./cook.py uvm-run-testlist -s vcs -t <new_target> -l <testlist>

# Lint baseline
./cook.py rtl-lint -t <new_target> --update-baseline
```

### 5. Record the Baselines

Run the benchmarks and the synthesis, then copy their results in
`expected_values.yml`:

```bash
./cook.py coremark -t <new_target> -c gcc-15
./cook.py vcs-uvm-run -t <new_target> -n coremark
./cook.py dhrystone -t <new_target> -c gcc-15
./cook.py vcs-uvm-run -t <new_target> -n dhrystone
./cook.py yosys-synth -t <new_target>
```

### 6. Add it to the CI

Add the target to `TARGETS` and its test lists to `TESTLISTS` in
`flows/macros/full_regression.py`, then to the tables of this file.

## Validation and CI

`./cook.py full-regression` runs the pipeline of
`flows/macros/full_regression.py` on every target of `TARGETS`:

1. **Software**: hello world, benchmarks and test lists built with the
   toolchains of the pipeline.
2. **Simulation**: VCS UVM testbench with the Spike tandem comparison,
   test lists of `TESTLISTS`, the TestHarness on Verilator and VCS for the
   AXI targets, pk and Zephyr hello worlds on the targets of `PK_TARGETS`
   and `ZEPHYR_TARGETS`.
3. **Performance**: CoreMark and Dhrystone cycle counts against
   `expected_values.yml`.
4. **Static analysis**: `rtl-lint` against `expected_lint.yml`, Spyglass,
   Verible formatting.
5. **Synthesis**: Yosys on every target but the FPGA ones, DC Shell and
   GTECH on the targets of their lists.
6. **FPGA**: bitstreams and Linux boot of the `fpga_linux_` targets.

`merge-reports` gathers the results into `pipeline_report.yml` and
`report-html` renders the dashboard, the targets sorted by the `category`
of their `doc.yml`. See [flows/README.md](../flows/README.md) and
[flows/CONTINUOUS_INTEGRATION.md](../flows/CONTINUOUS_INTEGRATION.md).

## Best Practices

1. **Consistency**: keep `isa.yml`, `spike.yaml`, `rtl_cfg_pkg.sv` and
   `testbench_cfg.yml` aligned.
2. **Validation**: always validate with the tandem simulation.
3. **Baselines**: update `expected_values.yml` and `expected_lint.yml` only
   with a justified change, explained in the commit.
4. **Documentation**: update `doc.yml` and the tables of this file with the
   target.
