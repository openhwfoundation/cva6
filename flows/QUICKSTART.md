# Quick start

Worked examples, from a fresh clone to a design running on a board. Each
one is a sequence to copy, with what it produces and where. The reference
of every option is in [README.md](README.md), writing a new flow is in
[CONTRIBUTING.md](CONTRIBUTING.md), running them from a CI engine is in
[CONTINUOUS_INTEGRATION.md](CONTINUOUS_INTEGRATION.md).

The commands use `cv32a60x` and the `llvm-20-1-8` toolchain of the example
`compiler.yml`; substitute the target and the toolchain name of your own
configuration.

- [Installation](#installation)
- [RTL simulation](#rtl-simulation)
- [Documentation](#documentation)
- [FPGA](#fpga)

## Installation

**1. Clone the repository and its submodules**

```bash
git clone https://github.com/openhwgroup/cva6.git
cd cva6
git submodule update --init --recursive
```

**2. Install the Python dependencies**

```bash
pip3 install -r flows/requirements.txt
```

Without write access to the system packages, use `pip3 install --user`
and add `~/.local/bin` to the `PATH`, or work in a virtual environment
(`python3 -m venv .venv && . .venv/bin/activate`).

**3. Install a RISC-V toolchain**

At least one, GCC or LLVM/Clang. Building it with the provided scripts is
strongly recommended, see
[util/toolchain-builder/README.md](../util/toolchain-builder/README.md).

**4. Install Spike**

The reference model of the tandem comparison.

```bash
sudo apt-get install cmake help2man device-tree-compiler   # Debian based
export NUM_JOBS=8
./verif/regress/install-spike.sh
```

**5. Clone the external test suites and patch the submodules**

The suites the `base_*` testlists run are not submodules. The same recipe
applies the patches declared on the submodules, so run it even if the
suites are not needed.

```bash
./cook.py git-dependencies
```

Running it again is harmless: an existing clone is kept, a patch already
applied is skipped.

**6. Install the documentation dependencies (optional)**

Only for `docs-build`, and only for the RISC-V specifications: the CVA6
design manual and the Sphinx user manual need neither. Both install per
user, no privilege required.

```bash
gem install --user-install -g docs/riscv-isa/riscv-isa-manual/dependencies/Gemfile
npm install -g wavedrom-cli bytefield-svg
```

`asciidoctor-mathematical` compiles a native extension: cmake, bison,
flex and the pango headers have to be on the machine, which is the one
part needing root. See
[Documentation dependencies](README.md#documentation-dependencies).

**7. Point cook.py at your tools**

`$CONFIG_DIR` (default `flows/config/`) holds `setenv.sh`, `compiler.yml`
and `techno.yml`, described in
[cook.py configuration](README.md#cookpy-configuration). `setenv.sh` is
what puts every tool in the path, the CAD ones through their own bashrc
and the Python entry points by activating the virtual environment. It is
shared by every checkout, so source it from the root of this one:

```bash
source $CONFIG_DIR/setenv.sh
./cook.py self-check     # what is found, and what is missing
./cook.py --help         # the recipes
```

## RTL simulation

CVA6 has **two testbenches**, with their own recipes: the **UVM** one
(`*-uvm-*`), used below, and the lighter **TestHarness**
(`*-testharness-*`), the only one Verilator runs. A design elaborated for
one does not run the tests of the other. The differences, and which
simulator is verified on which testbench, are in
[README.md](README.md#two-testbenches).

### A first test

```bash
# 1. Compile a pattern
./cook.py hello-world -t cv32a60x -c llvm-20-1-8

# 2. Elaborate the design
./cook.py vcs-uvm-comp -t cv32a60x

# 3. Run it, dumping waveforms
./cook.py vcs-uvm-run -t cv32a60x -n hello-world --trace-mode gui

# 4. Open them
./cook.py vcs-uvm-gui -t cv32a60x -n hello-world
```

The verdict, the cycle count and the log analysis land in
`build/cv32a60x/simulation/sim_rtl/hello-world/cook_report.yml`.

Elaboration is the expensive step and is done once: steps 1 and 3 can be
replayed on their own as long as the design does not change. Questa and
Xcelium take the same options, `questa-uvm-comp`/`questa-uvm-run` and
`xcelium-uvm-comp`/`xcelium-uvm-run`; the Xcelium ones are not verified.

### A whole testlist

```bash
# 0. The base_* testlists run riscv-tests, cloned by git-dependencies
./cook.py git-dependencies --repo riscv-tests

# 1. Compile every test of the list
./cook.py sw-compile-testlist -t cv32a60x -c llvm-20-1-8 \
  -l verif/tests/base_rv32_p.yaml

# 2. Elaborate once
./cook.py vcs-uvm-comp -t cv32a60x

# 3. Run them all, no waveforms
./cook.py uvm-run-testlist --simulator vcs -t cv32a60x \
  -l verif/tests/base_rv32_p.yaml --trace-mode notrace
```

### The TestHarness testbench

AXI targets only. Verilator needs no licence, which makes it the way in
without the commercial tools:

```bash
# 1. Compile the two Hello tests of the smoke testlist
./cook.py sw-compile-testlist -t cv32a65x_axi -c gcc-15 \
  -l verif/tests/testlist_verilator_testharness_smoke.yaml

# 2. Build the Verilator model
./cook.py verilator-testharness-comp -t cv32a65x_axi

# 3. Run one test, then the whole list
./cook.py verilator-testharness-run -t cv32a65x_axi -n hello-uart_0
./cook.py testharness-run-testlist --simulator verilator -t cv32a65x_axi \
  -l verif/tests/testlist_verilator_testharness_smoke.yaml
```

The same on VCS is `vcs-testharness-comp`, then `vcs-testharness-run`
or `--simulator vcs`. The Questa and Xcelium recipes exist but are not
verified.

### Benchmarks

```bash
# 1. Compile them
./cook.py coremark -t cv32a65x -c gcc-14
./cook.py dhrystone -t cv32a65x -c gcc-14

# 2. Elaborate with the performance counters
./cook.py vcs-uvm-comp -t cv32a65x --stats

# 3. Run them against a memory that never stalls
./cook.py vcs-uvm-run -t cv32a65x -n coremark --stats --tb-performance-mode
./cook.py vcs-uvm-run -t cv32a65x -n dhrystone --stats --tb-performance-mode
```

The cycle count is checked against the `<test>_cycle` key of
`config/target/cv32a65x/expected_values.yml`, and the per-MHz scores are
recorded in the report of each run.

### Random tests

```bash
# 1. Elaborate the generator
./cook.py vcs-generator-comp

# 2. Generate and run, in batches, against Spike
./cook.py macro-vcs-generator-testlist \
  -t cv32a60x \
  -l verif/tests/<generator-testlist>.yaml \
  -c llvm-20-1-8 \
  --batch-size 8 \
  --trace-mode compact \
  --tandem-enabled
```

### Synthesis, then the netlist

```bash
# 1. Synthesize
./cook.py dc-shell-synth -t cv32a60x --techno umc55 --period 5.0
```

The gate count is checked against the `gates` key of
`expected_values.yml`, and the area breakdown and its Sunburst chart are
written to `build/cv32a60x/synthesis/reports/`.

```bash
# 2. Compile a test and elaborate the netlist with its timing
./cook.py hello-world -t cv32a60x -c llvm-20-1-8
./cook.py vcs-uvm-comp -t cv32a60x --comp-mode gate_wc_timing --trace-mode gui

# 3. Run it
./cook.py vcs-uvm-run -t cv32a60x -n hello-world \
  --comp-mode gate_wc_timing --trace-mode gui
```

### The whole pipeline

What the CI runs, in one working directory:

```bash
./cook.py full-regression --dry-run    # what it would run
./cook.py full-regression --jobs 32 --vcs-licenses 10
```

## Documentation

```bash
# The CVA6 design manual and the user manual: asciidoctor and Sphinx only
./cook.py docs-build -t cv32a60x -m design

# The RISC-V specifications too, which need the AsciiDoctor extensions
./cook.py docs-build -t cv32a60x

# One manual as PDF, without the user manual
./cook.py docs-build -t cv32a60x -m priv --format pdf --no-sphinx
```

The rendered documents land in `build/<target>/docs/`, the user manual
under its `html/`. `./cook.py self-check` reports which extensions load,
so a manual that cannot be rendered is known before the build.

## FPGA

Needs Vivado (Xilinx) or Quartus (Intel/Altera), a board, and an SD card
carrying a Linux image built with the CVA6 SDK.

### Xilinx

```bash
# 1. Build the bootloader: one ROM per board and per register width,
#    shared by every target of that width
./cook.py fpga-bootrom -t cv32a6_imac_sv32 -c gcc-15 --board genesys2

# 2. Build the bitstream (the first build also generates the Vivado IPs,
#    reused by every later build)
./cook.py vivado-fpga-build -t cv32a6_imac_sv32 --board genesys2

# 3. Load it on the board driven by a running hw_server
./cook.py vivado-fpga-program -t cv32a6_imac_sv32 --hw-server localhost:3121

# 4. Watch the console until Linux boots
./cook.py fpga-linux-boot -t cv32a6_imac_sv32 --uart /dev/ttyUSB1
```

Steps 3 and 4 can be replayed on their own: the bitstream is a
prerequisite, not something to rebuild.

### Intel/Altera

The same four steps, with the Quartus recipes. The bootloader is shared,
`fpga-bootrom` taking a board of either vendor.

```bash
./cook.py fpga-bootrom -t cv64a6_imafdc_sv39_hpdcache_pmp_mmu_axi \
  -c gcc-15 --board agilex7
./cook.py quartus-fpga-build -t cv64a6_imafdc_sv39_hpdcache_pmp_mmu_axi \
  --board agilex7
./cook.py quartus-fpga-program -t cv64a6_imafdc_sv39_hpdcache_pmp_mmu_axi
./cook.py fpga-linux-boot -t cv64a6_imafdc_sv39_hpdcache_pmp_mmu_axi \
  --uart /dev/ttyUSB1
```

The board is often not on the machine holding the sources. Only the last
two steps need it, and both can drive one attached elsewhere, see
[Driving a board attached to another machine](README.md#driving-a-board-attached-to-another-machine).
