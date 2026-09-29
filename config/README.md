<!--
Copyright 2026 Thales France

Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
You may obtain a copy of the License at https://solderpad.org/licenses/

Original Author: Yannick Casamatta (yannick.casamatta@thalesgroup.com)
-->
# CVA6 Target Configurations

This directory contains the configuration files for all supported CVA6 processor variants. Each target represents a specific CVA6 configuration supported by at least one partner organization in the OpenHW Group.

## Table of Contents

- [Overview](#overview)
- [Available Targets](#available-targets)
- [Target Directory Structure](#target-directory-structure)
- [Configuration Files Reference](#configuration-files-reference)
- [Creating a New Target](#creating-a-new-target)
- [Validation and CI](#validation-and-ci)

## Overview

Each target configuration defines a complete CVA6 variant with specific:
- ISA extensions and parameters
- RTL configuration package
- Memory map and linker script
- SPIKE reference model configuration
- Expected performance metrics for CI validation
- RTL file lists for compilation

These configurations ensure that each CVA6 variant can be consistently built, simulated, and validated across different flows and tools.

## Available Targets

### Embedded-class OBI buses (noPMP/noMMU, no L1 caches)

- cv32a60x
- **cv32a60x_no_zcmt** (minimal)
- cv32a65x_noPMP
- cv64a6_imafdc_sv39_hpdcache_nopmp_nommu_obi

### Embedded-class AXI buses (noPMP/noMMU, with L1 caches)

- cv32a60x_axi
- cv32a60x_no_zcmt_axi
- cv32a65x_noPMP_axi
- cv64a6_imafdc_sv39_hpdcache_nopmp_nommu_axi

### Embedded-class OBI buses + PMP (noMMU, no L1 caches)

- cv32a60x_zcmt_pmp
- cv32a65x
- cv64a6_imafdc_sv39_hpdcache_pmp_nommu_obi

### Embedded-class AXI buses + PMP (noMMU, with L1 caches)

- cv32a60x_zcmt_pmp_axi
- cv32a65x_axi
- cv64a6_imafdc_sv39_hpdcache_pmp_nommu_axi

### Application-class OBI buses (no L1 caches)

- cv32a6_imac_sv32_obi
- cv32a65x_sv32
- cv64a6_imafdc_sv39_hpdcache_pmp_mmu_obi

### Application-class AXI buses + PMP (with L1 caches)

- cv32a6_imac_sv32
- cv32a65x_sv32_axi
- **cv64a6_imafdc_sv39_hpdcache_pmp_mmu_axi** (High performance 64b core)

## Table Targets main options


| Target | OBI | Mmu | PMP | XLEN | SuperScalar | ZCMT | AMO |
|--------|--------------|------------|--------------|------|---------------|--------|-----|
| cv32a60x | 1 | 0 | 0 | 32 | 0 | 1 | 0 |
| cv32a60x_no_zcmt | 1 | 0 | 0 | 32 | 0 | 0 | 0 |
| cv32a60x_axi | 0 | 0 | 0 | 32 | 0 | 1 | 0 |
| cv32a60x_no_zcmt_axi | 0 | 0 | 0 | 32 | 0 | 0 | 0 |
| cv32a65x_noPMP | 1 | 0 | 0 | 32 | 1 | 1 | 0 |
| cv32a65x_noPMP_axi | 0 | 0 | 0 | 32 | 1 | 1 | 0 |
| cv64a6_imafdc_sv39_hpdcache_nopmp_nommu_obi | 1 | 0 | 0 | 64 | 0 | 0 | 1 |
| cv64a6_imafdc_sv39_hpdcache_nopmp_nommu_axi | 0 | 0 | 0 | 64 | 0 | 0 | 1 |
| cv32a60x_zcmt_pmp | 1 | 0 | 8 | 32 | 0 | 1 | 0 |
| cv32a60x_zcmt_pmp_axi | 0 | 0 | 8 | 32 | 0 | 1 | 0 |
| cv32a65x | 1 | 0 | 8 | 32 | 1 | 1 | 0 |
| cv32a65x_axi | 0 | 0 | 8 | 32 | 1 | 1 | 0 |
| cv64a6_imafdc_sv39_hpdcache_pmp_nommu_obi | 1 | 0 | 8 | 64 | 0 | 0 | 1 |
| cv64a6_imafdc_sv39_hpdcache_pmp_nommu_axi | 0 | 0 | 8 | 64 | 0 | 0 | 1 |
| cv32a65x_sv32 | 1 | 1 | 8 | 32 | 1 | 0 | 0 |
| cv32a65x_sv32_axi | 0 | 1 | 8 | 32 | 1 | 0 | 0 |
| cv32a6_imac_sv32_obi | 1 | 1 | 8 | 32 | 0 | 0 | 1 |
| cv32a6_imac_sv32 | 0 | 1 | 8 | 32 | 0 | 0 | 1 |
| cv64a6_imafdc_sv39_hpdcache_pmp_mmu_obi | 1 | 1 | 8 | 64 | 0 | 0 | 1 |
| cv64a6_imafdc_sv39_hpdcache_pmp_mmu_axi | 0 | 1 | 8 | 64 | 0 | 0 | 1 |

## Target Directory Structure

Each target directory contains the following files:

```
config/target/<target_name>/
├── isa.yml                    # ISA string and ABI for toolchain
├── spike.yaml                 # SPIKE reference model configuration
├── link.ld                    # Linker script for software compilation
├── rtl_cfg_pkg.sv            # RTL configuration package (SystemVerilog)
├── Flist.cva6                # RTL file list for simulation
├── Flist.cva6_gate           # RTL file list for gate-level simulation
├── Flist.cva6_synth          # RTL file list for synthesis
├── expected_values.yml       # Expected metrics for CI validation
└── expected_spyglass.rpt     # Expected Spyglass lint results (optional)
└── testbench_cfg.yml         # Configuration for testbench (AXI/OBI, DCLS)
```

## Configuration Files Reference

### `isa.yml`

Defines the ISA string and ABI used by the compilation toolchain.

**Format:**
```yaml
march: <RISC-V ISA string>
mabi: <ABI specification>
```

**Example:**
```yaml
march: rv32ic_zmmul_zcb_zbb_zbs_zcmt_zicsr_zifencei
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
  bootrom_base: <hex address>
  bootrom_size: <bytes>
  dram: <bool>
  dram_base: <hex address>
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
      boot_addr: <hex address>
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

SystemVerilog package that defines all RTL configuration parameters.

**Structure:**
```systemverilog
package cva6_config_pkg;

  // Basic configuration
  localparam CVA6ConfigXlen = 32;  // or 64
  localparam CVA6ConfigRvfiTrace = 1;

  // AXI/OBI parameters
  localparam CVA6ConfigAxiIdWidth = 5;
  localparam CVA6ConfigAxiAddrWidth = 64;
  localparam CVA6ConfigAxiDataWidth = 64;

  // Main configuration structure
  localparam config_pkg::cva6_user_cfg_t cva6_cfg = '{
    XLEN: unsigned'(CVA6ConfigXlen),
    VLEN: unsigned'(32),
    FpgaEn: bit'(0),
    SuperscalarEn: bit'(0),
    NrCommitPorts: unsigned'(1),
    // ... (many more parameters)
  };

endpackage
```

**Key Parameters:**
- `XLEN`: 32 or 64 (architecture width)
- `FpgaEn`: Enable FPGA-specific optimizations
- `SuperscalarEn`: Enable superscalar execution
- `RVF/RVD/RVA/RVM`: Enable ISA extensions
- `MMUEn`: Enable MMU
- `PMP*`: PMP configuration
- `NrLoadPipeRegs`: Load pipeline depth
- Memory interface widths

### `Flist.cva6`

List of RTL files to compile for simulation (RTL mode).

**Format:**
```tcl
# Comments start with #
-F ${CVA6_REPO_DIR}/core/Flist.cva6
-F ${CVA6_REPO_DIR}/vendor/pulp-platform/axi/Flist.axi
+incdir+${CVA6_REPO_DIR}/core/include
${CVA6_REPO_DIR}/config/target/<target>/rtl_cfg_pkg.sv
```

**Directives:**
- `-F <file>` - Include another file list
- `+incdir+<path>` - Add include directory
- `<path>` - Direct file path
- `${VAR}` - Environment variable expansion

**Purpose:**
- Speeds up compilation by pre-specifying all files
- Ensures correct compilation order
- Can be customized per-target for specific modules

### `Flist.cva6_gate`

List of RTL files for gate-level simulation (post-synthesis).

**Differences from Flist.cva6:**
- May exclude certain modules replaced by gate-level netlists
- May include technology library wrappers
- May include additional timing models

### `Flist.cva6_synth`

List of RTL files for synthesis (`dc-shell-synth --gtech`).

It includes `core/Flist.cva6_synth`, which is `core/Flist.cva6` with the
HPDcache SRAMs read as their blackbox models: the behavioural ones would
synthesise every bit of the caches into a register. A target can list only
the files it needs instead.


## Configuration Files Reference

### `testbench_cfg.yml`

Defines the option for testbench.

**Format:**
```yaml
hier: <axi/obi>
dcls: <true/false>
```

### `expected_values.yml`

Expected performance metrics for CI validation.

**Format:**
```yaml
gates: <gate count>
coremark_cycle: <cycles>
coremark_iters: <iterations>
dhrystone_cycle: <cycles>
dhrystone_iters: <iterations>
```

**Example:**
```yaml
gates: 97499
coremark_cycle: 451410
coremark_iters: 1
dhrystone_cycle: 36552
dhrystone_iters: 20
```

**Purpose:**
- CI pipelines compare actual results against these values
- Detect performance regressions
- Validate synthesis results (gate count)
- Ensure consistency across builds

**Metrics:**
- `gates`: Total gate count after synthesis (normalized to NAND2)
- `coremark_cycle`: Cycles to complete CoreMark benchmark
- `coremark_iters`: Number of CoreMark iterations
- `dhrystone_cycle`: Cycles to complete Dhrystone benchmark
- `dhrystone_iters`: Number of Dhrystone iterations

### `expected_spyglass.rpt` (Optional)

Expected lint results from Spyglass static analysis.

**Purpose:**
- Baseline for lint checking
- Track known issues
- Prevent new violations

## Creating a New Target

To create a new CVA6 configuration, follow these steps:

### 1. Choose a Target Name

Follow the naming convention: (TBD)
```
cv<bitwidth>a6<variant>_<features>_<interface>
```

Examples:
- `cv32a60x` - 32-bit, variant 60x, OBI (minimal)
- `cv64a6_imafdc_sv39_hpdcache_pmp_mmu_axi` - 64-bit, hig perf, AXI

### 2. Create Target Directory

```bash
mkdir -p config/target/<new_target_name>
```

### 3. Start from an Existing Target

Copy a similar configuration as a baseline:

```bash
# For a 32-bit embedded target
cp -r config/target/cv32a60x/* config/target/<new_target>

# For a 64-bit target
cp -r config/target/cv64a6_imafdc_sv39_hpdcache_pmp_mmu_obi/* config/target/<new_target>
```

### 4. Customize Configuration Files

#### 4.1. Update `isa.yml`

Set the ISA extensions and ABI:

```yaml
march: rv32i_<extensions>
mabi: ilp32  # or ilp32f, ilp32d, lp64, etc.
```

#### 4.2. Update `rtl_cfg_pkg.sv`

Modify the RTL parameters to match your configuration:

```systemverilog
// Key parameters to review:
- XLEN (32 or 64)
- ISA extension enables (RVF, RVD, RVA, RVM, RVC, etc.)
- MMU configuration (MMUEn, MODE_OFF, MODE_SV32, MODE_SV39)
- PMP configuration (NrPMPEntries)
- Cache configuration (if applicable)
- Pipeline configuration (NrLoadPipeRegs, NrScoreboardEntries, etc.)
```

#### 4.3. Update `spike.yaml`

Configure the SPIKE reference model to match RTL:

```yaml
spike_param_tree:
  isa: rv<bitwidth>im<extensions>
  priv: M  # or MS, MSU
  core_configs:
    - isa: rv<bitwidth>im<extensions>
      extensions: <custom_extensions>
      # Update CSR configurations
      # Update memory map if needed
```

**Important:** Ensure ISA and CSR configurations match `rtl_cfg_pkg.sv`.

#### 4.4. Update `link.ld`

Adjust memory layout if needed:

```ld
SECTIONS
{
  . = 0x80000000;  /* Adjust base address if needed */
  /* ... */
}
```

#### 4.5. Update `Flist.cva6`

Include any custom RTL modules:

```tcl
-F ${CVA6_REPO_DIR}/core/Flist.cva6
${CVA6_REPO_DIR}/config/target/<new_target>/rtl_cfg_pkg.sv
# Add any additional custom files
```

#### 4.6. Create `expected_values.yml`

Run benchmarks to establish baseline metrics:

```bash
# Compile and run CoreMark
./cook.py coremark -t <new_target> -c <toolchain>
./cook.py vcs-uvm-comp -t <new_target> --cva6-hier obi
./cook.py vcs-uvm-run -t <new_target> -n coremark
./cook.py report_benchmark -t <new_target> -n coremark

# Extract cycle count from simulation logs
# Update expected_values.yml with actual results
```

### 5. Validate the Configuration

```bash
# Test compilation
./cook.py hello-world -t <new_target> -c <toolchain>

# Test RTL elaboration
./cook.py vcs-uvm-comp -t <new_target> --cva6-hier <obi/axi>

# Test simulation
./cook.py vcs-uvm-run -t <new_target> -n hello-world

# Test with SPIKE tandem (recommanded)
./cook.py vcs-uvm-comp -t <new_target> --cva6-hier <obi/axi> --tandem-enabled
./cook.py vcs-uvm-run -t <new_target> -n hello-world --tandem-enabled

# Run benchmarks
./cook.py coremark -t <new_target> -c <toolchain>
./cook.py vcs-uvm-run -t <new_target> -n coremark
./cook.py dhrystone -t <new_target> -c <toolchain>
./cook.py vcs-uvm-run -t <new_target> -n dhrystone
```

### 6. Test with Test Suites

```bash
# Run ISA tests
./cook.py sw-compile-testlist -t <new_target> -c <toolchain> -l <testlist>
./cook.py uvm-run-testlist --simulator vcs -t <new_target> -l <testlist>
```

## Validation and CI

### Continuous Integration Checks

Each target is validated in CI pipelines using:

1. **Compilation Tests**
   - Software compilation with multiple toolchains
   - RTL elaboration with VCS
   - Synthesis with DC Shell

2. **Functional Tests**
   - ISA tests (riscv-tests)
   - Architecture tests (riscv-arch-test)
   - Custom directed tests

3. **Performance Benchmarks**
   - CoreMark (CoreMark/MHz)
   - Dhrystone (Dhrystones/Second)
   - Cycle count validation against `expected_values.yml`

4. **Tandem Verification**
   - Execution trace comparison with SPIKE
   - Instruction-by-instruction validation

5. **Static Analysis**
   - Spyglass lint checking
   - Verible formatting

### CI Pipeline Usage

The CI pipeline automatically:
- Detects changed targets
- Runs relevant test suites
- Compares results against `expected_values.yml`
- Reports any deviations or failures

**Acceptable Tolerances:**
- Gate count: ±2% (TBD)
- Cycle count: ±1% (TBD)

Exceeding these tolerances triggers a CI failure.

## Best Practices

### Configuration Management

1. **Consistency**: Ensure `isa.yml`, `spike.yaml`, and `rtl_cfg_pkg.sv` are aligned
3. **Validation**: Always validate with tandem simulation
4. **Baselines**: Update `expected_values.yml` only with justified changes

### Testing Strategy

1. **Smoke Test**: Start with hello-world
2. **ISA Coverage**: Run complete ISA test suite
3. **Benchmarks**: Validate performance with CoreMark/Dhrystone
4. **Stress Tests**: Run random instruction generation (TBD)
5. **Tandem**: Validate with SPIKE reference model
