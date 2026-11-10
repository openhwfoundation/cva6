# CVA6: Verification Environment for the CVA6 CORE-V processor core

- [Directories](#directories)

Tests are compiled and run with `cook.py`, see [flows/README.md](../flows/README.md).

## Directories:
- **bsp**:   board support package for test-programs compiled/assembled/linked for the CVA6.
This BSP is used by both `core` testbench and `uvmt_cva6` UVM verification environment.
- **regress**: Spike and Verilator installation scripts, patches of the external test suites
- **sim**:   riscv-dv submodule, verification plan (`cva6.hvp`), coverage exclusion list and trace conversion scripts.
  The generated tests of a target are listed in `config/target/<target>/verif/generated_test.yaml`
- **tb**:    testbench module instancing the core
- **tests**: source of test cases and test lists

There are README files in each directory with additional information.
