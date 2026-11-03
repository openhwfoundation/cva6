# ACT4 Tests for CV32A65X

This document describes how to generate and run RISC-V Architectural Certification Tests (ACT4) on the CV32A65X configuration of CVA6.

## Prerequisites

Initialize the CVA6 submodules:

```bash
git submodule update --init --recursive
```

Set the RISC-V toolchain:

```bash
export RISCV=/path/to/riscv/toolchain
```

The toolchain must provide `riscv64-unknown-elf-*` binaries.

## Run ACT4

From the CVA6 repository root, run:

```bash
bash verif/regress/wrapper-cv32a65x-act.sh
```

The wrapper:

1. Sets up the required simulation tools and environment.
2. Builds the CV32A65X Verilator model.
3. Generates the ACT4 tests.
4. Runs the generated tests on the CVA6 Verilator model.
5. Reports the certification results.

The default simulators are `veri-testharness` and `spike`. This can be overridden using `DV_SIMULATORS`.

## Results

The certification summary is generated at:

```text
verif/sim/simulation_results/certification_summary.txt
```
