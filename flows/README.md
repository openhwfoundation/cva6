<!--
Copyright 2026 Thales France

Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
You may obtain a copy of the License at https://solderpad.org/licenses/

Original Author: Yannick Casamatta (yannick.casamatta@thalesgroup.com)
-->

# CVA6 Command Runner - `cook.py`

A modular command runner to automate and simplify RTL flow execution for the CVA6 RISC-V processor.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [cook.py configuration](#cookpy-configuration)
- [Build Directory Organization](#build-directory-organization)
- [Cook.py Architecture](#cookpy-architecture)
- [Recipe Reference](#recipe-reference)
  - [Test Patterns](#test-patterns)
  - [Software Compilation](#software-compilation)
  - [RTL Simulation](#rtl-simulation) (UVM testbench)
  - [RTL Simulation: TestHarness testbench](#rtl-simulation-testharness-testbench)
  - [Random Test Generation](#random-test-generation)
  - [Synthesis](#synthesis)
  - [FPGA](#fpga)
  - [Static Analysis](#static-analysis)
  - [Documentation](#documentation)
  - [Reports](#reports)
  - [Macros](#macros)
  - [Utilities](#utilities)
- [Complete Flow Examples](#complete-flow-examples)
- [Simulation Outputs and Logs](#simulation-outputs-and-logs)

Getting started, worked end to end: **[QUICKSTART.md](QUICKSTART.md)**.
Writing a flow rather than using one:
**[CONTRIBUTING.md](CONTRIBUTING.md)**.
Running the flows from a CI engine:
**[CONTINUOUS_INTEGRATION.md](CONTINUOUS_INTEGRATION.md)**.

## Overview

`cook.py` is the main entry point for launching various "recipes" (tasks) in the CVA6 RTL flow. Built on [Typer](https://typer.tiangolo.com/), this modular framework enables you to:

- Compile software programs for CVA6 targets
- Elaborate and simulate RTL
- Run synthesis
- Execute static analysis tools (Spyglass, Verible, Pylint)
- Generate performance and area reports
- Automate complete flows via macros

## Current Status

### Two testbenches

CVA6 is simulated in **two different testbenches**. They are not two
modes of the same one: their sources, their tops, their recipes and their
output directories are separate, and a design elaborated for one cannot
run a test of the other.

| | **UVM** | **TestHarness** |
|---|---|---|
| Top level | `uvmt_cva6_tb` | `ariane_tb` (event-driven simulators), `ariane_testharness` (Verilator) |
| Sources | `verif/tb/uvmt/`, core-v-verif agents | `corev_apu/tb/`, `verif/tb/core/Flist.testharness*` |
| Core interface | AXI or OBI, driven by the UVM agents of core-v-verif | AXI, through the SoC of `corev_apu` |
| Targets | all | targets declaring `hier: axi` only, checked by the recipes |
| Verdict | UVM scoreboard, optional tandem against SPIKE | `tohost` written by the program |
| Recipes | `<simulator>-uvm-comp`, `<simulator>-uvm-run`, `uvm-run-testlist` | `<simulator>-testharness-comp`, `<simulator>-testharness-run`, `testharness-run-testlist` |
| Outputs | `build/<target>/{elab,simulation}/sim_<comp_mode>/` | `build/<target>/{elab,simulation}/sim_<comp_mode>_<simulator>_testharness/` |

The UVM testbench is the one the verification of CVA6 relies on. The
TestHarness is the lighter one: the only one Verilator can run, and the
one to reach for when an open-source simulator is required.

### Simulator support

| Simulator | UVM | TestHarness |
|---|---|---|
| VCS (Synopsys) | supported | supported |
| Questa (Siemens) | supported | **not verified** |
| Xcelium (Cadence) | **not verified** | **not verified** |
| Verilator | — | supported |

*Not verified* means the recipes exist, follow the reference flow of the
Makefile and of the verified recipes, but have not been run to the end
of a test. Expect to have to fix them on first use, and report what you
find.

Synthesis runs on DC shell, RTL lint on SpyGlass, and the FPGA flows
drive both Vivado (Xilinx) and Quartus (Intel/Altera). The documentation
is built by a recipe as well.

### Roadmap

- Support for the Verilator ISS.
- Verification of the UVM testbench on Xcelium.
- Verification of the TestHarness on Questa and Xcelium.

Ideally, all project operations should be accessible through this single
entry point: cook.py. Writing one is described in
[CONTRIBUTING.md](CONTRIBUTING.md).

## Prerequisites

### CAD Tools

The following Synopsys tools must be installed with binaries accessible in `$PATH`:

- **VCS** - RTL simulation
- **Verdi** - Waveform debugging and trace analysis
- **DC Shell** - Logic synthesis
- **Spyglass** - Static analysis and lint checking

The FPGA recipes use AMD/Xilinx tools instead:

- **Vivado** - FPGA synthesis, implementation and bitstream generation
- **Vivado Lab** - board programming only (`--vivado-cmd vivado_lab`)

The Intel/Altera recipes use Quartus instead:

- **Quartus Prime Pro** - synthesis, fitting and bitstream generation
  (`quartus_sh`, `quartus_syn`, `quartus_fit`, `quartus_asm`,
  `quartus_sta`, `quartus_pfg`, `quartus_ipgenerate`)
- **Platform Designer** - IP and system generation (`qsys-script`,
  `qsys-generate`, in the `sopc_builder/bin` of the install)
- **Quartus Programmer** - board programming (`quartus_pgm`,
  `jtagconfig`), also available standalone as `qprogrammer`

### Generic Tools

- **Black** - Python formatter
- **pyLint** - Python static analysis and lint checking
- **Sphinx** - documentation user manual
- **dtc** - device tree compiler, for the FPGA bootloader
- **AsciiDoctor** - documentation specifications (`asciidoctor`,
  `asciidoctor-pdf`), installed with its Ruby extensions, see
  [`docs-build`](#docs-build)

Black, pyLint and Sphinx come with `flows/requirements.txt` (see
[Python Environment](#python-environment)); `dtc` is a system package and
AsciiDoctor a set of Ruby gems, see
[Documentation dependencies](#documentation-dependencies).

### Documentation dependencies

The user manual is Python only. The **specifications** cross three package
managers, and `./cook.py self-check` reports what is usable:

| What | Needed by | Root |
|---|---|---|
| `flows/requirements.txt` (Sphinx) | the user manual | no |
| `asciidoctor`, `asciidoctor-pdf` | every specification | no |
| `asciidoctor-bibtex`, `-diagram`, `-lists`, `-mathematical` | the RISC-V manuals only | no |
| `wavedrom-cli`, `bytefield-svg` (npm) | the RISC-V manuals only | no |
| cmake, bison, flex, libpango, libgdk-pixbuf, libgtk2 | building `asciidoctor-mathematical` | **yes** |

Only the last line needs privileges: `asciidoctor-mathematical` compiles a
native extension. On Debian or Ubuntu the packages are the ones of
`docs/riscv-isa/riscv-isa-manual/dependencies/apt_packages.txt`:

```bash
apt install $(grep -v '^#' \
    docs/riscv-isa/riscv-isa-manual/dependencies/apt_packages.txt)
```

On RHEL, Rocky or Fedora the packages are their `-devel` counterparts:
`cairo-devel pango-devel gdk-pixbuf2-devel glib2-devel libxml2-devel
libffi-devel libwebp-devel libzstd-devel cmake bison flex ruby-devel
java-headless graphviz`, plus `make` and a C toolchain (`gcc`):

```bash
dnf install cairo-devel pango-devel gdk-pixbuf2-devel glib2-devel \
    libxml2-devel libffi-devel libwebp-devel libzstd-devel cmake bison \
    flex ruby-devel java-headless graphviz make gcc
```

Everything else installs per user. The gems are those of the `Gemfile` of
the submodule — `asciidoctor`, `asciidoctor-pdf`, the four extensions the
manuals need, and what they pull in — and the node packages those of its
`package.json`:

```bash
gem install --user-install -g docs/riscv-isa/riscv-isa-manual/dependencies/Gemfile
npm install -g wavedrom-cli bytefield-svg
```

Or the gems one by one, the full list of the `Gemfile` being:

```bash
gem install --user-install asciidoctor asciidoctor-pdf \
    asciidoctor-bibtex asciidoctor-diagram asciidoctor-lists \
    asciidoctor-mathematical asciidoctor-epub3 citeproc-ruby coderay \
    csl-styles json pygments.rb rghost rouge ruby_dev mathematical
```

Installed per user with `gem install --user-install`, the gems land in
`Gem.user_dir` and their executables in `~/.local/bin`, which `setenv.sh`
already puts on the `PATH`; `npm install -g` puts the node generators in
the npm prefix (e.g. `/usr/local/bin`), also on the `PATH`. Nothing has
to be added. `asciidoctor-diagram` carries a converter for each kind of
diagram, but both shell out to the node generator: the RISC-V manuals
draw their registers with WaveDrom and their bit fields with bytefield.

A `GEM_PATH` set by the site can hide the user gems: Ruby then does not
search `Gem.user_dir` by default, and AsciiDoctor reports

    cannot load such file -- asciidoctor-bibtex (LoadError)

Uncomment `GEM_HOME` in `setenv.sh` to name that directory back.

`./cook.py self-check` renders a probe document with each extension, so
that case is reported before a manual is built rather than half way
through one.

None of it is pinned: the `Gemfile` and the `package.json` of the
submodule name the packages without a version, so an installation picks
whatever is current. A combination that does not work renders the manual
without the diagrams it could not generate, leaving the error and the
source of the diagram in the page while AsciiDoctor still exits 0 —
`docs-build` reads its log and fails on it.

**The CVA6 design manual needs none of them.** It carries no citation, no
WaveDrom diagram and no LaTeX, so it renders with `asciidoctor` alone:

```bash
./cook.py docs-build -t cv32a60x -m design
```

The extensions are only required for the manuals asking for them, so a
machine without them still builds the CVA6 documentation.

### Verification Tools and Test Suites

- **SPIKE** - RISC-V ISA simulator (reference model for tandem verification)
- **riscv-tests** - Basic ISA tests
- **riscv-arch-test** - Official RISC-V architecture tests
- **riscv-compliance** - Compliance test suite
- **riscv-dv** - Random instruction generator
- **Proxy kernel** - system calls (optional)

## Installation

### Step-by-Step Setup

1. **Clone the repository and initialize submodules**

```bash
git clone https://github.com/openhwgroup/cva6.git
cd cva6
git submodule update --init --recursive
```

2. **Install the RISC-V toolchain**

At least one RISC-V toolchain must be configured (GCC or LLVM/Clang).

It is **strongly recommended** to use the toolchain built with the provided scripts.

Install toolchain build prerequisites
See util/toolchain-builder/README.md for details

Build and install the toolchain
See util/toolchain-builder/README.md for instructions

3. **Install Spike**

To speed up compilation and elaboration, you can set the `NUM_JOBS`

```bash
#Prerequisites (Debian based example)
sudo apt-get install cmake help2man device-tree-compiler
export NUM_JOBS=8  # Use 8 parallel jobs (cmake)
# Install SPIKE (RISC-V ISA simulator)
./verif/regress/install-spike.sh
```

4. **Install external git dependencies**

The test suites the `base_*` testlists run (riscv-tests, riscv-compliance,
riscv-arch-test) are not submodules and have to be cloned. The same recipe
also applies the patches declared on the Git submodules, so run it after
`git submodule update` even if you do not need the test suites.

```bash
# Clone the external test suites and patch the submodules
./cook.py git-dependencies
```

Running it again is harmless: an existing clone is kept and a patch already
applied is skipped.

## cook.py configuration

### Python Environment

**Python 3.9 or later.** Everything the flows import is listed in
`flows/requirements.txt`, installed in one go:

```bash
pip3 install -r flows/requirements.txt

# Without write access to the system site-packages, either
pip3 install --user -r flows/requirements.txt   # then add ~/.local/bin to PATH
# or, preferred, in a virtual environment
python3 -m venv .venv && . .venv/bin/activate
pip3 install -r flows/requirements.txt
```

`setenv.sh` activates it with the rest of the tools, `VENV_PATH`
defaulting to the `.venv` of the current directory: that file is shared by
every checkout, so it is sourced from the root of the repository being
worked on. Leave `VENV_PATH` unset to manage the interpreter yourself.

What it covers: the CLI itself (`typer`, `rich`), the configuration and
report files (`pyyaml`, `jinja2`), the charts of the reports (`plotly`,
`pandas`, `matplotlib`, `scipy`), the serial console of the FPGA boot
(`pyserial`), the code quality recipes (`black`, `pylint`) and the
documentation (`sphinx`, `sphinx-rtd-theme`, `recommonmark`).

The set is what ReadTheDocs installs on its own (`flows/requirements.txt`
is the `requirements` of its config), so a machine set up for the flows
can build the documentation too.

`./cook.py self-check` reports the *executables* it finds, `black`,
`pylint` and `sphinx-build` among them; a library that is only imported
is reported by the recipe needing it, when it needs it.

### Configuration Files

Four files, all read from `$CONFIG_DIR` (default: `flows/config/`):

- **`setenv.sh`** - where the tools are (required, see below)
- **`compiler.yml`** - toolchain configurations (required)
- **`techno.yml`** - technology libraries for synthesis
- **`dependencies.yml`** - external git repositories and submodule patches

The three `.yml` are read by the recipes themselves; `setenv.sh` is a shell
script **you** source before calling `cook.py`.

The versions shipped in `flows/config/` are templates with placeholder paths.
Point `CONFIG_DIR` at your own copy, typically shared by a whole site, so the
repository stays free of machine-specific paths:

```bash
export CONFIG_DIR=/path/to/your/config
source $CONFIG_DIR/setenv.sh
```

### Environment (`setenv.sh`)

**This file must be adapted to your environment.**

The recipes do not take tool paths as options: they look the tools up in
`PATH` (`vcs`, `xrun`, `vsim`, `dc_shell`, `aipk_read`, `verible-verilog-format`,
`black`, `pylint`...) and report an actionable environment error when one is
missing. `setenv.sh` is what puts them there, by sourcing the bashrc of each
tool:

```sh
export CONFIG_DIR=/path/to/config          # where the four files live
export SPIKE_PATH=/path/to/spike           # shared Spike install root
export NUM_JOBS=24                         # parallelism of the tool builds
export SYN_VCS_BASHRC=/path/to/vcs/setup/bashrc
export SYN_SG_BASHRC=/path/to/spyglass/setup/bashrc
export VERIBLE_PATH=/path/to/verible/bin
export PATH=$PATH:$VERIBLE_PATH
#source $SYN_VCS_BASHRC                    # uncomment the tools you use
```

Only what you actually run has to be defined: a missing simulator makes the
recipes that need it fail, not the others.

**Check your setup at any time:**

```bash
./cook.py self-check
```

It reports which tools are in `PATH`, the Spike install, the submodules, the
external test suites and the configuration files, and fails only when none of
`vcs`, `xrun` or `vsim` is found: the flows offer three simulators and several
optional steps, so a missing one is not an error by itself.

Two of these variables are read by the recipes rather than by the shell:
`CONFIG_DIR` to locate the configuration files, and `SPIKE_PATH` to find the
Spike install. The rest only matter through `PATH`.

### Compiler Configuration (`compiler.yml`)

**This file must be adapted to your environment.**

Example configuration:

```yaml
# LLVM 20 configuration
llvm-20-1-8:
    TOOLS_PATH: "/opt/riscv/llvm-20"
    CLANG: "riscv32-unknown-elf-clang"
    GCC: None
    OBJDUMP: "riscv32-unknown-elf-objdump"
    NM: "riscv32-unknown-elf-nm"
    TARGET_TOOLCHAIN: "riscv32-unknown-elf"

# GCC 14 configuration
gcc-14:
    TOOLS_PATH: "/opt/riscv/gcc-14"
    CLANG: None
    GCC: "riscv32-unknown-elf-gcc"
    OBJDUMP: "riscv32-unknown-elf-objdump"
    NM: "riscv32-unknown-elf-nm"
    TARGET_TOOLCHAIN: "riscv32-unknown-elf"
```

**Notes:**
- `TOOLS_PATH`: Directory containing the toolchain
- Set `None` for `GCC` if using Clang, and vice versa
- Configuration name (e.g., `llvm-20-1-8`) is used with `-c` option in commands

### Techno Configuration (`techno.yml`)

**This file must be adapted to your environment.**

Example configuration:

```yaml
# MyTechno configuration
MyTechno:
    NAND2_AREA: "100"
    FOUNDRY_PATH: "/tmp/PDK/TECH1/STDCELLS/TECHNAME"
    LIB_NAME: "libname"
    TECH_NAME: "techname"
    CORNER_SYNTH: "corner_synth"
    SCENARIO_SYNTH_NAME: "wc_timing"
    CORNER_POWER: "corner_power"
    SCENARIO_POWER_NAME: "wc_power"
    LIB_VERILOG: "/tmp/PDK/TECH1/verilog/beh.v"
    FOUNDRY_RAM_PATH: ""

```

## Build Directory Organization

Everything a flow produces goes under `build/<target>/<recipe>/`, one
directory per recipe, described in
[CONTRIBUTING.md](CONTRIBUTING.md#build-directory-organization).

## Cook.py Architecture

The layout of `flows/`, how a recipe is written and the conventions it
follows are in the contributor guide:
**[CONTRIBUTING.md](CONTRIBUTING.md)**.

## Recipe Reference

### General Usage

```bash
# Show all available commands
./cook.py --help

# Get help for a specific command
./cook.py <command> --help
```

**Run it from the root of the checkout.** The recipes address the
repository by relative path, `config/target/` and `build/` among them,
while a path given on the command line is resolved by the shell that typed
it; the two only agree at the root. `cook.py` stops with the directory it
expected rather than reading and writing beside the repository.

---

### Test Patterns

Pre-configured benchmark and test patterns for quick CVA6 validation.

#### `hello-world`

Build a simple "Hello World" test program.

```bash
./cook.py hello-world [OPTIONS]
```

**Required Options:**
- `-t, --target TEXT` - CVA6 user configuration (e.g., cv32a60x, cv32a65x)
- `-c, --toolchain [llvm-20-1-8|...]` - Toolchain defined in `$CONFIG_DIR/compiler.yml`

**Optional:**
- `--march TEXT` - Custom RISC-V architecture string (overrides target default)
- `--mabi TEXT` - Custom RISC-V ABI (overrides target default)

**Example:**
```bash
./cook.py hello-world -t cv32a60x -c llvm-20-1-8
```

#### `coremark`

Build the CoreMark performance benchmark.

```bash
./cook.py coremark [OPTIONS]
```

**Required Options:**
- `-t, --target TEXT` - CVA6 user configuration
- `-c, --toolchain [llvm-20-1-8|...]` - Toolchain defined in `$CONFIG_DIR/compiler.yml`

**Optional:**
- `--march TEXT` - Custom march string
- `--mabi TEXT` - Custom mabi string

**Example:**
```bash
./cook.py coremark -t cv32a60x -c llvm-20-1-8 --march rv32imac
```

**Output:** Generates `build/<target>/compile/coremark/*.elf` and reports

#### `dhrystone`

Build the Dhrystone performance benchmark.

```bash
./cook.py dhrystone [OPTIONS]
```

**Required Options:**
- `-t, --target TEXT` - CVA6 user configuration
- `-c, --toolchain [llvm-20-1-8|...]` - Toolchain defined in `$CONFIG_DIR/compiler.yml`

**Optional:**
- `--march TEXT` - Custom march string
- `--mabi TEXT` - Custom mabi string

**Example:**
```bash
./cook.py dhrystone -t cv32a65x -c gcc-14
```

---

### Software Compilation

Compile C/Assembly programs for CVA6 targets.

#### `sw-compile`

Compile software from source files and generate ELF binary with reports.

```bash
./cook.py sw-compile [OPTIONS] SRC_FILES...
```

**Required Arguments:**
- `SRC_FILES...` - Source files (.c, .S, etc.)

**Required Options:**
- `-t, --target TEXT` - CVA6 user configuration
- `-c, --toolchain [llvm-20-1-8|...]` - Toolchain defined in `$CONFIG_DIR/compiler.yml`
- `--linker TEXT` - Linker script file path
- `--out TEXT` - Test name (used throughout the flow)

**Optional:**
- `--inc TEXT` - Include directories (can be repeated)
- `--options TEXT` - Additional compiler options
- `--march TEXT` - Custom march instead of target default
- `--mabi TEXT` - Custom mabi instead of target default
- `--define TEXT` - Preprocessor directives (can be repeated)

**Example:**
```bash
./cook.py sw-compile \
  -t cv32a60x \
  -c llvm-20-1-8 \
  --linker config/target/cv32a60x/link.ld \
  --out my_test \
  --inc verif/tests/custom/common \
  --define DEBUG=1 \
  src/main.c src/util.c src/startup.S
```

**Output:**
- `build/<target>/compile/<test>/<test>.elf`
- `build/<target>/compile/<test>/<test>.dump`
- `build/<target>/compile/<test>/<test>.size`
- `build/<target>/compile/<test>/compiler_version.log` - `--version` of the
  compiler behind the `--toolchain` label. Its first line (e.g. `clang
  version 22.1.2`) is recorded as the `compiler_version` report context and
  build manifest option, and reported with the resolved march/mabi in the
  summary rows.

#### `sw-compile-testlist`

Build tests from a YAML testlist file.

```bash
./cook.py sw-compile-testlist [OPTIONS]
```

**Required Options:**
- `-t, --target TEXT` - CVA6 user configuration
- `-c, --toolchain [llvm-20-1-8|...]` - Toolchain defined in `$CONFIG_DIR/compiler.yml`
- `-l, --testlist TEXT` - Testlist YAML file in `verif/tests`

**Optional:**
- `-n, --testname TEXT` - Single test of the testlist
- `--march TEXT` - Custom march instead of target default
- `--mabi TEXT` - Custom mabi instead of target default
- `-q, --quiet` - Suppress output (errors only)

A testlist points at its sources through `path_var`. The `base_*` ones use
`TESTS_PATH` (`verif/tests`) and run the riscv-tests suite, which is not a
submodule: install it once with `./cook.py git-dependencies --repo
riscv-tests`.

**Example:**
```bash
# Compile all tests in the list
./cook.py sw-compile-testlist -t cv32a60x -c llvm-20-1-8 -l verif/tests/base_rv32_p.yaml

# Compile only one test from the list
./cook.py sw-compile-testlist -t cv32a60x -c llvm-20-1-8 -l verif/tests/base_rv32_p.yaml -n rv32ui-p-add
```

---

### RTL Simulation

Two testbenches, with their own recipes: the **UVM testbench** below, and
the **TestHarness testbench** in the
[next section](#rtl-simulation-testharness-testbench). See
[Two testbenches](#two-testbenches) for how they differ and
[Simulator support](#simulator-support) for what is verified.

#### UVM testbench

VCS and Questa are verified; the Xcelium recipes are **not verified**.

#### `vcs-uvm-comp`

Compile and elaborate the VCS UVM simulation.

```bash
./cook.py vcs-uvm-comp [OPTIONS]
```

**Required Options:**
- `-t, --target TEXT` - CVA6 user configuration

**Optional:**
- `--comp-mode [rtl|gate_wc_power|gate_wc_timing|coverage]` - Hardware compilation mode (default: `rtl`)
- `--trace-mode [gui|fast|compact|notrace]` - Waveform trace mode (default: `notrace`)
  - `gui`: Full traces for Verdi (FSDB format)
  - `fast`: Fast dump with reduced detail
  - `compact`: Minimal traces
  - `notrace`: No waveform generation
- `--tandem-enabled / --no-tandem-enabled` - Enable SPIKE tandem verification (default: disabled)
- `--stats / --no-stats` - Enable RTL performance tracer (default: disabled)
- `--sim-profile / --no-sim-profile` - Enable simulation profiling (default: disabled)

**Example:**
```bash
# Basic RTL compilation
./cook.py vcs-uvm-comp -t cv32a60x

# With full traces and tandem verification
./cook.py vcs-uvm-comp \
  -t cv32a60x \
  --trace-mode gui \
  --tandem-enabled \
  --stats
```

**Output:** `build/<target>/elab/sim_rtl/simv` (simulation executable)

#### `vcs-uvm-run`

Run a single test on the elaborated simulation.

```bash
./cook.py vcs-uvm-run [OPTIONS]
```

**Required Options:**
- `-t, --target TEXT` - CVA6 user configuration
- `-n, --testname TEXT` - Test name (must be compiled first)

**Optional:**
- `--comp-mode [rtl|gate_wc_power|gate_wc_timing|coverage]` - Hardware compilation mode (default: `rtl`)
- `--trace-mode [gui|fast|compact|notrace]` - Trace mode (default: `notrace`)
- `--uvm-verbosity [NONE|LOW|MEDIUM|HIGH|FULL|DEBUG]` - UVM verbosity level (default: `NONE`)
- `--tandem-enabled / --no-tandem-enabled` - Enable SPIKE tandem (default: disabled)
- `--tb-performance-mode / --no-tb-performance-mode` - Enable testbench performance mode (default: disabled)
- `--stats / --no-stats` - Enable RTL perf tracer (default: disabled)
- `--sim-profile / --no-sim-profile` - Enable simulation profiling (default: disabled)
- `--interactive-gui / --no-interactive-gui` - Launch Verdi for interactive simulation (default: disabled)
- `--run_opts TEXT` - Additional simulation run options
- `--uvm-seed TEXT` - UVM randomization seed (default: randomized)
- `--run-name TEXT` - Name of the output directory (default: the test name)

`--run-name` is what lets the same test run more than once on the same
design without the second erasing the first: the output is named after the
run, not after the test. The pipeline uses it to measure `hello-world`
twice, see below.

**Example:**
```bash
# Run with GUI traces
./cook.py vcs-uvm-run \
  -t cv32a60x \
  -n hello-world \
  --trace-mode gui \
  --uvm-verbosity MEDIUM

# Run with interactive Verdi
./cook.py vcs-uvm-run \
  -t cv32a60x \
  -n coremark \
  --interactive-gui \
  --stats
```

**Output:** `build/<target>/simulation/sim_rtl/<test>/`

#### `xcelium-uvm-comp`

Compile and elaborate the Xcelium (Cadence) UVM simulation.
**Not verified.**

```bash
./cook.py xcelium-uvm-comp [OPTIONS]
```

**Options:** Same as `vcs-uvm-comp` (see above)

**Example:**
```bash
./cook.py xcelium-uvm-comp -t cv32a60x --trace-mode fast
```

**Output:** `build/<target>/elab/sim_rtl/xcelium.d/` (snapshot)

#### `xcelium-uvm-run`

Run a single test with Xcelium simulator. **Not verified.**

```bash
./cook.py xcelium-uvm-run [OPTIONS]
```

**Options:** Same as `vcs-uvm-run` (see above), `--run-name` included,
except `--sim-profile` and `--cycle-timeout` which are VCS only

**Example:**
```bash
./cook.py xcelium-uvm-run -t cv32a60x -n hello-world --trace-mode fast
```

**Output:** `build/<target>/simulation/sim_rtl/<test>/` (waveforms in `.shm` format)

#### `questa-uvm-comp`

Compile and elaborate the Questa/ModelSim (Siemens) UVM simulation.

```bash
./cook.py questa-uvm-comp [OPTIONS]
```

**Options:** Same as `vcs-uvm-comp` (see above, except `--sim-profile` not supported)

**Example:**
```bash
./cook.py questa-uvm-comp -t cv32a60x --trace-mode fast
```

**Output:** `build/<target>/elab/sim_rtl/work/` (library)

#### `questa-uvm-run`

Run a single test with Questa/ModelSim simulator.

```bash
./cook.py questa-uvm-run [OPTIONS]
```

**Options:** Same as `vcs-uvm-run` (see above), `--run-name` included,
except `--sim-profile` and `--cycle-timeout` which are VCS only

**Example:**
```bash
./cook.py questa-uvm-run -t cv32a60x -n hello-world --trace-mode fast
```

**Output:** `build/<target>/simulation/sim_rtl/<test>/` (waveforms in `.wlf` format)

#### `uvm-run-testlist`

Run all tests (or a single test) from a testlist with any simulator.

```bash
./cook.py uvm-run-testlist [OPTIONS]
```

**Required Options:**
- `-s, --simulator [vcs|xcelium|questa]` - Simulator to use
- `-t, --target TEXT` - CVA6 user configuration

**Optional:**
- `-l, --testlist TEXT` - Testlist YAML file in `verif/tests`
- `-n, --testname TEXT` - Test in the testlist or already compiled (multiple allowed)
- `--comp-mode [rtl|gate_wc_power|gate_wc_timing|coverage]` - Hardware compilation mode (default: `rtl`)
- `--trace-mode [gui|fast|compact|notrace]` - Trace mode (default: `notrace`)
- `--uvm-verbosity [NONE|LOW|MEDIUM|HIGH|FULL|DEBUG]` - UVM verbosity level (default: `NONE`)
- `--tandem-enabled / --no-tandem-enabled` - Enable SPIKE tandem (default: disabled)
- `--tb-performance-mode / --no-tb-performance-mode` - Enable TB perf mode (default: disabled)
- `--stats / --no-stats` - Enable RTL perf tracer (default: disabled)
- `--sim-profile / --no-sim-profile` - Enable simulation profiling (VCS only, default: disabled)
- `--interactive-gui / --no-interactive-gui` - Launch GUI interactively (default: disabled)
- `--run_opts TEXT` - Additional simulation run options
- `--uvm-seed TEXT` - UVM randomization seed

**Example:**
```bash
# Run entire testlist with VCS
./cook.py uvm-run-testlist \
  -s vcs \
  -t cv32a60x \
  -l verif/tests/base_rv32_p.yaml \
  --trace-mode compact

# Run with Xcelium
./cook.py uvm-run-testlist \
  -s xcelium \
  -t cv32a60x \
  -l verif/tests/base_rv32_p.yaml \
  --tandem-enabled

# Run with Questa
./cook.py uvm-run-testlist \
  -s questa \
  -t cv32a60x \
  -n test_mul \
  --stats
```


#### `vcs-uvm-gui`

Open Verdi to view simulation traces (FSDB only).

```bash
./cook.py vcs-uvm-gui [OPTIONS]
```

**Required Options:**
- `-t, --target TEXT` - CVA6 user configuration

**Optional:**
- `-n, --testname TEXT` - Test name (compiled and simulated)
- `--comp-mode [rtl|gate_wc_power|gate_wc_timing|coverage]` - Hardware compilation mode (default: `rtl`)
- `-s, --session TEXT` - Verdi session file (user-saved .ses file)

**Example:**
```bash
# Open Verdi for a specific test
./cook.py vcs-uvm-gui -t cv32a60x -n hello-world

# Open with saved session
./cook.py vcs-uvm-gui -t cv32a60x -n coremark -s my_debug_session.ses
```

#### `spike-run`

Run test using the SPIKE ISA simulator.

```bash
./cook.py spike-run [OPTIONS]
```

**Required Options:**
- `-t, --target TEXT` - CVA6 user configuration
- `-n, --testname TEXT` - Test name (must be compiled first)

**Example:**
```bash
./cook.py spike-run -t cv32a60x -n hello-world
```

### RTL Simulation: TestHarness testbench

The `ariane_testharness` of `corev_apu` wraps the core in a small AXI
SoC (memory, UART, debug module) and loads the program itself. The
harness prints `*** SUCCESS ***` or `*** FAILED *** (tohost = N)`, and
the verdict is read from both the log and the exit code:

- **VCS, Questa, Xcelium**: `ariane_tb` reports a failure through
  `uvm_error` and ends with `$finish`, so the simulator exits 0 whatever
  the program did. The log decides.
- **Verilator**: the C++ driver returns the `tohost` value, so a failing
  program also fails the command. The log alone is not enough: on
  SIGTERM, which is how a timeout ends the run, the driver prints
  `*** SUCCESS ***` and exits 0. A timeout or a crash is therefore
  reported as such, before the log is looked at.

In both cases a log carrying `*** FAILED ***`, `SIMULATION FAILED`,
`[FAILED]`, `UVM_ERROR` or `UVM_FATAL` fails the test, and one without
`*** SUCCESS *** (tohost = 0)` does too.

Verilator and VCS are verified; the Questa and Xcelium recipes are
**not verified**.

Common to all of them:

- **AXI targets only**: those whose configuration declares `hier: axi`.
  The recipes refuse the others before building anything.
- **`rtl` only**: `--comp-mode` accepts the other values for symmetry
  with the UVM recipes, and rejects them.
- The program is compiled by `sw-compile` beforehand: the run reads the
  ISA and the `tohost` address from its manifest.
- The SPIKE libraries of `tools/spike` are required, even without tandem:
  the harness loads the ELF and resolves its DPI through them. Nothing
  comes from the RISC-V toolchain.
- The sources are shared: `config/target/<target>/Flist.cva6`, then
  `verif/tb/core/Flist.testharness`. The event-driven simulators add
  `verif/tb/core/Flist.testharness_top` (the `ariane_tb` top and the
  real UART); Verilator drives the harness from C++ instead.

#### `verilator-testharness-comp`

Build the Verilator model of the harness.

```bash
./cook.py verilator-testharness-comp [OPTIONS]
```

**Required Options:**
- `-t, --target TEXT` - CVA6 user configuration

**Optional:**
- `--trace-mode [notrace|fast|compact]` - `fast` dumps VCD, `compact` FST; `gui` is rejected (default: `notrace`)
- `-j, --jobs INTEGER` - Parallel jobs of the C++ build (default: 8)

The Verilator of the path is used, `setenv.sh` putting the one of
`VERILATOR_INSTALL_DIR` there; the version is recorded in
`verilator.version` next to the model.

**Output:** `build/<target>/elab/sim_rtl_verilator_testharness/Variane_testharness`

#### `verilator-testharness-run`

Run one test on the Verilator model.

```bash
./cook.py verilator-testharness-run [OPTIONS]
```

**Required Options:**
- `-t, --target TEXT` - CVA6 user configuration
- `-n, --testname TEXT` - Test compiled by `sw-compile`

**Optional:**
- `--trace-mode [notrace|fast|compact]` - Must match the build (default: `notrace`)
- `--sim-timeout INTEGER` - Timeout in seconds (default: 500)
- `--run-name TEXT` - Name of the output directory (default: the test name)

**Output:** `build/<target>/simulation/sim_rtl_verilator_testharness/<run>/`

#### `vcs-testharness-comp`

Elaborate the harness with VCS: one `vcs` call over the filelists,
`ariane_tb` as top, like `vcs-uvm-comp`.

```bash
./cook.py vcs-testharness-comp [OPTIONS]
```

**Required Options:**
- `-t, --target TEXT` - CVA6 user configuration

**Optional:**
- `--trace-mode [notrace|compact|fast|gui]` - Any value but `notrace` elaborates with debug access (`-kdb`, `-debug_access+all`) (default: `notrace`)

**Output:** `build/<target>/elab/sim_rtl_vcs_testharness/simv`

#### `vcs-testharness-run`

Run one test on the VCS elaboration.

```bash
./cook.py vcs-testharness-run [OPTIONS]
```

**Required Options:**
- `-t, --target TEXT` - CVA6 user configuration
- `-n, --testname TEXT` - Test compiled by `sw-compile`

**Optional:**
- `--trace-mode` - Must match the elaboration; the run itself writes no waveform (default: `notrace`)
- `--uvm-verbosity [NONE|LOW|MEDIUM|HIGH|FULL|DEBUG]` - (default: `LOW`). Not `NONE`: the harness reports its verdict through `uvm_info` at `UVM_LOW`, and `NONE` hides it.
- `--sim-timeout INTEGER` - Timeout in seconds (default: 500)
- `--run-name TEXT` - Name of the output directory (default: the test name)

**Output:** `build/<target>/simulation/sim_rtl_vcs_testharness/<run>/`

#### `questa-testharness-comp`, `questa-testharness-run`

**Not verified.** Same options as the VCS recipes.

The compilation is `vlib`, `vlog` then `vopt`, like `questa-uvm-comp`, into
`build/<target>/elab/sim_rtl_questa_testharness/work/ariane_tb_opt`. The
run needs a Questa whose gcc runtime is at least the one the SPIKE
libraries were built against (`GLIBCXX_3.4.29`); `-noautoldlibpath`
keeps the one Questa ships off the loader path.

#### `xcelium-testharness-comp`, `xcelium-testharness-run`

**Not verified.** Same options as the VCS recipes.

Written after `xrun_comp` and `xrun_sim` of the Makefile and after
`xcelium-uvm-comp`, but never run: Xcelium was not available. The
compilation is `xrun -elaborate`; the run reopens the snapshot with
`xrun -R` and loads the SPIKE libraries with `+sv_lib`, as on the other
simulators.

**Output:** `build/<target>/elab/sim_rtl_xcelium_testharness/xcelium.d/`

#### `testharness-run-testlist`

Run every test of a testlist on one simulator.

```bash
./cook.py testharness-run-testlist [OPTIONS]
```

**Required Options:**
- `-t, --target TEXT` - CVA6 user configuration
- `-l, --testlist TEXT` - Testlist YAML file

**Optional:**
- `-s, --simulator [verilator|vcs|questa|xcelium]` - (default: `verilator`)
- `--trace-mode`, `--sim-timeout` - Passed to each run
- `--uvm-verbosity` - Passed to the event-driven simulators, ignored by Verilator (default: `LOW`)

Each entry of the testlist runs as `<test>_<iteration>`, the name
`sw-compile-testlist` gives it: compile with the same testlist first.

**Output:** one directory per test as for the run recipes, and the
result table in
`build/<target>/simulation/testharness_<simulator>_<testlist>/cook_report.yml`

#### Example

```bash
./cook.py sw-compile-testlist -t cv32a65x_axi -c gcc-15 \
  -l verif/tests/testlist_verilator_testharness_smoke.yaml
./cook.py verilator-testharness-comp -t cv32a65x_axi
./cook.py testharness-run-testlist -s verilator -t cv32a65x_axi \
  -l verif/tests/testlist_verilator_testharness_smoke.yaml

# The same tests on VCS
./cook.py vcs-testharness-comp -t cv32a65x_axi
./cook.py testharness-run-testlist -s vcs -t cv32a65x_axi \
  -l verif/tests/testlist_verilator_testharness_smoke.yaml
```

---

### Random Test Generation

RISC-V DV random instruction generator integration.

#### `vcs-generator-comp`

Compile the RISC-V DV generator project.

```bash
./cook.py vcs-generator-comp
```

No options required. This elaborates the test generation environment.

**Example:**
```bash
./cook.py vcs-generator-comp
```

#### `vcs-generator-run`

Run RISC-V DV to generate random instruction tests.

```bash
./cook.py vcs-generator-run [OPTIONS]
```

**Required Options:**
- `-n, --testname TEXT` - Test name to generate

**Optional:**
- `--type-instr [load_store|branch_jump|fence|csr_instr|dret|ebreak|unaligned_load_store]` - Instruction types to enable (comma-separated)
- `--gen-test TEXT` - Generator test class to run (default: `cva6_instr_base_test_c`)
- `-i, --iterations INTEGER` - Number of iterations (default: 1)
- `--batch-size INTEGER` - Tests to generate per batch (default: 1)
- `--instr-cnt INTEGER` - Number of instructions to generate (default: 300)
- `-e, --extension [zba|zbb|zbc|zbs|zcb|zcmp|zcmt|x]` - RISC-V extensions to enable (repeat flag for multiple)
- `-d, --directed-instr TEXT` - Directed instruction streams (e.g., `cva6_load_store_rand_instr_stream_c,10`)
- `--illegal-instr-ratio INTEGER` - Illegal instruction ratio (default: 0)
- `--unsupported-instr-ratio INTEGER` - Unsupported instruction ratio (default: 0)
- `--num-of-sub-program INTEGER` - Number of sub-programs (default: 0)
- `--seed INTEGER` - Random seed (randomized if not provided)
- `--tvec-alignment INTEGER` - Trap vector alignment value (default: 8)
- `-v, --verbose` - Enable UVM_HIGH verbosity
- `--options TEXT` - Additional options

**Example:**
```bash
# Generate simple random test
./cook.py vcs-generator-run -n my_random_test

# Generate with extensions and iterations
./cook.py vcs-generator-run \
  -n stress_test \
  --gen-test cva6_instr_base_test_c \
  --instr-cnt 1000 \
  -i 10 \
  -e zba -e zbb -e zbs \
  --directed-instr "cva6_load_store_rand_instr_stream_c,20"

# Generate with specific seed
./cook.py vcs-generator-run \
  -n reproducible_test \
  --seed 12345 \
  --instr-cnt 500 \
  --type-instr load_store,branch_jump
```

#### `vcs-generator-run-testlist`

Generate and run tests from a testlist.

```bash
./cook.py vcs-generator-run-testlist [OPTIONS]
```

**Required Options:**
- `-l, --testlist TEXT` - Testlist YAML file in `verif/tests`

**Optional:**
- `-n, --testname TEXT` - Single test of the testlist
- `--seed INTEGER` - Random seed (randomized if not provided)
- `--batch-size INTEGER` - Tests to generate per batch (default: 1)
- `-q, --quiet` - Suppress output (errors only)

**Example:**
```bash
# Generate all tests in testlist
./cook.py vcs-generator-run-testlist -l verif/tests/<generator-testlist>.yaml

# Generate specific test with seed
./cook.py vcs-generator-run-testlist \
  -l verif/tests/<generator-testlist>.yaml \
  -n arithmetic_test \
  --seed 98765 \
  --batch-size 4
```

---

### Synthesis

DC Shell logic synthesis.

#### `dc-shell-synth`

Run DC Shell synthesis flow.

```bash
./cook.py dc-shell-synth [OPTIONS]
```

**Required Options:**
- `-t, --target TEXT` - CVA6 user configuration
- `--techno [MyTechno]` - Technology defined in `$CONFIG_DIR/techno.yml` (not with `--gtech`)
- `--period TEXT` - Synthesis target clock period (in ns) (not with `--gtech`)

**Optional:**
- `--gtech` - Technology independent synthesis with `pd/synth/gtech_dc.tcl`:
  the design is mapped on the GTECH cells of dc_shell, hierarchy kept, and
  needs no PDK nor `RM_FLOW`. The files come from
  `config/target/<target>/Flist.cva6_synth`, which reads the HPDcache SRAMs
  as blackboxes. The GTECH cells have no area, so the recipe reports cell
  and register counts instead, checked against the `gtech_cells` and
  `gtech_registers` keys of `expected_values.yml` (tolerance 1%); any
  inferred latch fails the run. Output: `build/<target>/synthesis_gtech/`
- `--script-file TEXT` - DC setup script (default: `dc.tcl`)
- `--define [HPDCACHE_ASSERT_OFF|RVFI_ENABLE]` - Preprocessor directives (default: `HPDCACHE_ASSERT_OFF`)
- `--clean / --no-clean` - Clean working directory before synthesis (default: clean)

**Example:**
```bash
# Basic synthesis
./cook.py dc-shell-synth \
  -t cv32a60x \
  --techno MyTechno \
  --period 10.0

# Technology independent, no PDK
./cook.py dc-shell-synth -t cv32a60x --gtech

# with custom script
./cook.py dc-shell-synth \
  -t cv32a65x \
  --techno MyTechno \
  --period 5.0 \
  --script-file custom_dc.tcl \
  --no-clean
```

**Output:** `build/<target>/synthesis/`

---

### FPGA

Bitstream generation, board programming and Linux boot on an AMD/Xilinx
FPGA board. The three recipes form a chain, each checking the artifacts
of the previous one, so the board can be reprogrammed or the boot
replayed without rebuilding the bitstream.

**Supported boards:** `genesys2` (default), `kc705`, `vc707`,
`nexys_video`. Their parameters (part, board part, constraints, flash
interface, console baudrate) live in `flows/utils/fpga_board.py`.
Programming and booting additionally need the JTAG device name of the
board, which is only known for `genesys2` today: the other three build
but are refused by `vivado-fpga-program`, with the entry to add.

#### Vivado prerequisites

**Version.** Vivado **2018.2** is the version the CVA6 FPGA flow is
tested with. Check the devices of the boards you build for are actually
installed, an installation can be trimmed down to a few families:

```bash
source /path/to/Vivado/2018.2/settings64.sh
vivado -nojournal -mode batch -source /dev/stdin <<< \
  'puts [llength [get_parts xc7k325tffg900-2]]; exit'   # 1 = present, 0 = absent
```

A device that is absent makes `create_project` fail with
`ERROR: [Coretcl 2-106] Specified part could not be found`. The Genesys 2
and the KC705 need `xc7k325t`, the VC707 `xc7vx485t`, the Nexys Video
`xc7a200t`.

**Licence.** Synthesis and implementation are licensed features, and the
licence must cover the **device** too. What is needed:

| Feature | Needed by |
|---|---|
| `Synthesis` | `synth_design`, and the synthesis run of every IP core |
| `Implementation` | place, route and `write_bitstream` |
| the device (e.g. `7K325T`) | both, the licence is device scoped |

WebPACK, which is free, does **not** cover `xc7k325t`: a Genesys 2 or a
KC705 needs a full Vivado licence, or an OEM/board voucher entitlement
covering that device.

A node-locked licence is tied to the MAC address of one machine. The
hostid to declare for the machine running the builds:

```bash
/path/to/Vivado/2018.2/../bin_lm/lmutil lmhostid   # or lmutil from any FlexLM install
```

Point Vivado at the licence with `XILINXD_LICENSE_FILE` (a file for a
node-locked licence, `port@host` for a served one); a file dropped in
`~/.Xilinx/` is picked up as well.

Diagnosing a refusal is worth doing before suspecting the flow, the
Vivado message alone does not say why:

```bash
FLEXLM_DIAGNOSTICS=3 vivado -nojournal -mode batch -source build.tcl
```

It names the real cause, e.g. `Invalid host. The hostid of this system
does not match the hostid` with the hostid the licence is bound to. A
licence issued for another machine is **rehosted** from the AMD licensing
site by the owner of the entitlement: it is free and immediate, and it is
the only correct way to move it. Note also that a licence carries a
version ceiling (`INCREMENT ... xilinxd 2022.06`), so it covers the
Vivado releases up to that date only.

A missing licence is reported by the recipe as an **environment**
failure, at the stage that needed it, with the Vivado error lines
attached to the report.

#### `fpga-bootrom`

Build the zero stage bootloader of the FPGA images
(`bootrom_<XLEN>.sv`), the ROM `ariane_xilinx.sv` instantiates.

```bash
./cook.py fpga-bootrom [OPTIONS]
```

**Required Options:**
- `-t, --target TEXT` - CVA6 user configuration (selects the register width)
- `-c, --toolchain [...]` - Toolchain defined in `$CONFIG_DIR/compiler.yml`

**Optional:**
- `--board [genesys2|kc705|vc707|nexys_video]` - FPGA board (default: `genesys2`)
- `--xlen INTEGER` - Register width, 32 or 64 (default: from the ISA of the target)

A software pattern, like `hello-world`: it goes through `sw-compile`, so
the bootloader is traceable to the compiler that produced it. Two steps
surround the compilation:

1. the **device tree** is resolved from `cv<XLEN>a6.dts.in` with the
   parameters of the board (memory size, clock frequencies, console
   baudrate, presence of the ethernet controller) and compiled with `dtc`.
   It is compiled *first*: `startup.S` embeds it with `.incbin`, so the
   kernel receives the board description through the bootloader;
2. the ELF is turned into a **SystemVerilog ROM** by
   `corev_apu/bootrom/gen_rom.py`.

**One ROM per board and per register width**, not per target: the FPGA top
level reads `bootrom_<XLEN>.sv`, so the same binary serves every target of
that width. This is why the ISA is pinned to `rv<XLEN>im_zicsr` instead of
following the `march` of the target: a shared ROM may only use what every
configuration decodes, and their ISA strings have no common superset (the
`cv32a60x` family carries `zba_zbb_zbs_zbc`, `cv32a6_imac_sv32` carries
`zbkb`, `cv32a6_ima_sv32_fpga` has `RVB: 0`). Upstream pinned it down for
that reason (openhwgroup/cva6#2121).

**Example:**
```bash
./cook.py fpga-bootrom -t cv32a6_imac_sv32 -c gcc-15 --board genesys2
```

**Output:** `build/bootrom/<board>/bootrom_<XLEN>.sv` (plus the resolved
`.dts`, the `.dtb` and the intermediate binaries)

#### `vivado-fpga-build`

Generate the bitstream of the Xilinx FPGA top level (`ariane_xilinx`).

```bash
./cook.py vivado-fpga-build [OPTIONS]
```

**Required Options:**
- `-t, --target TEXT` - CVA6 user configuration

**Optional:**
- `--board [genesys2|kc705|vc707|nexys_video]` - FPGA board (default: `genesys2`)
- `--mcs / --no-mcs` - Also generate the `.mcs` flash image (default: disabled)
- `--clean / --no-clean` - Clean working directory before (default: clean)
- `-j, --jobs INTEGER` - Vivado parallel jobs (default: 8)

Two stages run in order:

1. the **nine Vivado IP cores**, generated into the source tree by the
   per-IP scripts of `corev_apu/fpga/xilinx/`. An IP is reused when its
   synthesized checkpoint (`.dcp`) is there, so only the first build pays
   for them. The definition (`.xci`) is deliberately *not* the mark: it is
   written first, and an IP whose synthesis run was refused would look
   ready while the design build failed much later on `DCP does not exist`.
   Such a leftover is cleaned and generated again;
2. the **synthesis and implementation**, from a `build.tcl` the recipe
   generates in its output directory. Every path in it is absolute, so
   the Vivado project is created under `build/` instead of in the middle
   of the sources.

The zero stage bootloader is a prerequisite, built by `fpga-bootrom`: the
recipe checks it exists and was built for the board being targeted, its
device tree carrying the board parameters.

The RTL comes from `config/target/<target>/Flist.cva6_fpga`, which
includes the shared `corev_apu/fpga/Flist.cva6_fpga`; add target specific
sources after the include to overload the common list.

**Example:**
```bash
# Bitstream for the default board
./cook.py vivado-fpga-build -t cv32a6_imac_sv32

# Another board, with the flash image, reusing the generated IPs
./cook.py vivado-fpga-build \
  -t cv32a6_imac_sv32 \
  --board nexys_video \
  --mcs \
  --no-bootrom
```

**Output:** `build/<target>/fpga/<board>/ariane_xilinx.bit` (+ `.mcs`,
the Vivado reports and the generated netlists)

**Reported:** the FPGA utilization (`fpga_luts`, `fpga_ffs`,
`fpga_brams` KPIs, label `<n> kLUTs`) and the worst negative slack
(`fpga_wns`). A negative slack fails the recipe. The LUT count is checked
against the `fpga_luts` key of
`config/target/<target>/expected_values.yml` (tolerance: 2 %) when the
target carries one. A Vivado report that cannot be parsed is reported as
a warning and skipped, never as a failure: the bitstream is the
deliverable, and a report layout change must not turn a good build red.

#### `vivado-fpga-program`

Load a bitstream onto a physical board (volatile configuration).

```bash
./cook.py vivado-fpga-program [OPTIONS]
```

**Required Options:**
- `-t, --target TEXT` - CVA6 user configuration

**Optional:**
- `--board [...]` - FPGA board (default: `genesys2`)
- `--hw-server TEXT` - URL of the `hw_server` driving the board (default: `$HW_SERVER_URL`)
- `--bitstream PATH` - Bitstream to load (default: the `vivado-fpga-build` output)
- `--vivado-cmd TEXT` - Vivado executable (default: `vivado`; `vivado_lab` is enough to program)

The `hw_server` is expected to be already running next to the board; the
recipe only connects to it. The bitstream is checked to have been built
for the board being programmed, so the image of another board is refused
rather than pushed.

**Example:**
```bash
# Program the board driven by a local hw_server
./cook.py vivado-fpga-program \
  -t cv32a6_imac_sv32 \
  --hw-server localhost:3121

# Program an artifact built elsewhere, with the lab edition
./cook.py vivado-fpga-program \
  -t cv32a6_imac_sv32 \
  --bitstream artifacts/FPGA/bitstream/ariane_xilinx.bit \
  --vivado-cmd vivado_lab
```

**Output:** `build/<target>/fpga_program/<board>/`

#### `fpga-linux-boot`

Boot Linux on the programmed board and check it on the serial console.

```bash
./cook.py fpga-linux-boot [OPTIONS]
```

**Required Options:**
- `-t, --target TEXT` - CVA6 user configuration

**Optional:**
- `--board [...]` - FPGA board (default: `genesys2`)
- `--uart TEXT` - Serial console: local device or URL of a remote one (default: `$UART_SERIAL`)
- `--cable TEXT` - JTAG cable, on a board whose console is a JTAG UART (default: `$JTAG_CABLE`)
- `--juart-instance INTEGER` - Instance of the JTAG UART on the cable
- `--baudrate INTEGER` - Console baudrate (default: the baudrate of the board)
- `--boot-timeout INTEGER` - Boot timeout in seconds (default: 300)
- `--expect TEXT` - Console line identifying a booted kernel (default: `Linux buildroot`)

The recipe follows the console, answers the shell prompt with `uname -a`
and takes the line naming the kernel and the architecture as the proof
that the system is up. How the console is reached is a property of the
board, taken from its entry in `flows/utils/fpga_board.py`: a **serial
port** on the Xilinx boards (`--uart`), the **JTAG UART** read through the
Quartus terminal on the Altera ones (`--cable`). The detection logic is the
same on both. The Linux image itself is **not** built here: it
comes from the CVA6 SDK and must already be on the SD card of the board
(see the FPGA section of the repository README for the SD card
preparation).

The boot has a wall clock deadline, so a board that never boots fails on
its own instead of hanging until the CI job times out. A board that says
nothing at all is reported as an **environment** failure (console, power
or SD card), a board that talks without reaching Linux as a **test**
failure.

**Example:**
```bash
./cook.py fpga-linux-boot -t cv32a6_imac_sv32 --uart /dev/ttyUSB1
```

**Output:** `build/<target>/fpga_boot/<board>/boot.log` (the full console
transcript, kept whatever the verdict)

#### Intel/Altera boards

The Altera flow is a separate pair of recipes, not an option of the Xilinx
ones: the two share no tool, no top level and no project format. Quartus
drives seven executables where Vivado drives one, elaborates `cva6_altera`
instead of `ariane_xilinx`, and takes its project from a `.qsf` assembled
out of the CSV board description of `corev_apu/altera/` instead of a TCL
script. What they do share is the bootloader, `fpga-bootrom` taking a
board of either vendor.

**Supported board:** `agilex7` (Agilex 7 FPGA Development Kit). Its
parameters live next to the Xilinx ones in `flows/utils/fpga_board.py`.

| Xilinx | Intel/Altera |
|---|---|
| `vivado-fpga-build` | `quartus-fpga-build` |
| `vivado-fpga-program` | `quartus-fpga-program` |
| `fpga-bootrom` | `fpga-bootrom` (shared) |
| `fpga-linux-boot` | `fpga-linux-boot` (shared, see the caveat below) |

##### `quartus-fpga-build`

```bash
./cook.py quartus-fpga-build -t <target> [--board agilex7] [--no-rbf]
```

Four stages: the **Platform Designer systems** (`interconnect` and
`system`, the latter carrying the HPS), the **project files** written from
the CSV board description, the **nine IP cores**, then the **compilation**
(`quartus_syn` → `quartus_fit` → `quartus_asm` → `quartus_sta`) and
`quartus_pfg` for the `.rbf` the HPS boots the fabric from.

The RTL comes from `config/target/<target>/Flist.cva6_altera`, which
includes the shared `corev_apu/altera/Flist.cva6_altera`. The CSV files
(66 settings, 270 pin locations, 74 IO standards, 13 IP files, 10 search
paths) are consumed as they are: they describe the board, not the recipe.

**Output:** `build/<target>/fpga_altera/<board>/output_files/*.sof` and
`cva6-hps.rbf`

**Reported:** `altera_alms`, `altera_registers`, `altera_memory_bits` and
`altera_slack` as KPIs, the ALM count checked against the `altera_alms`
key of `expected_values.yml` (tolerance: 2 %). A negative slack fails the
recipe.

##### `quartus-fpga-program`

```bash
./cook.py quartus-fpga-program -t <target> [--cable "<hardware setup>"]
```

Quartus programs through a **local JTAG cable** named by the programmer,
not through a server reached over TCP: the board must be on the machine
running the recipe, or its cable exported by `jtagd`. The cable name is
what the Quartus Programmer calls a hardware setup, e.g.
`AGF FPGA Development Kit [1-3]`; the recipe asks `jtagconfig --enum` when
`--cable` and `$JTAG_CABLE` are both unset.

##### Booting the Agilex

`fpga-linux-boot` works on `--board agilex7` too, through a different
**transport**: the console of that board is its JTAG UART, not a serial
port. Nothing to pass, the recipe picks the transport from the board table.

Why it differs: `cva6_altera_peripherals.sv:214` instantiates
`cva6_intel_jtag_uart_0` where the Xilinx design instantiates `apb_uart`
wired to the `rx`/`tx` pins of its top level
(`ariane_peripherals_xilinx.sv:270`). The Agilex top level has no such
pins, its only UART signals being `hps_uart0_RX/TX`, which belong to the
ARM HPS and not to CVA6. The console is therefore carried by the JTAG
cable and read with the `juart-terminal` of Quartus, which the recipe runs
and follows; `--uart` and `--baudrate` do not apply, `--cable` and
`--juart-instance` do.

```bash
# The cable is optional with a single board connected
./cook.py fpga-linux-boot -t <target> --board agilex7
./cook.py fpga-linux-boot -t <target> --board agilex7 \
  --cable "AGF FPGA Development Kit [1-3]"
```

The bootloader writes to that UART as it does to a serial port (the
`PLAT_AGILEX` branch of `bootrom/src/uart.c`), and loads its `fw_payload`
from the SD card at block **0x32800** (100 MB, `bootrom/src/main.c:77`)
where the Xilinx boards use a GPT partition: that offset is what an SD card
prepared for this board must follow.

Note that the device tree describes that UART as `compatible = "ns16550a"`
at `ariane_soc::UARTBase` (`cv<XLEN>a6_agilex.dts.in`), which the hardware
is not. The address is right and Linux talks to it, but the description
does not name the actual controller: a discrepancy of the Agilex port,
not of these flows, and the reason the transport cannot be inferred from
the device tree.

The `altera-boot` CI job runs the check, but stays `when: manual` until a
runner carries the board.

#### Driving a board attached to another machine

The board is often not on the machine running the flows: the bitstream is
built on the server holding the sources and the CAD tools, while the
board itself sits next to a bench PC (frequently a Windows one), the
server being reached over a remote desktop session. Only the last two
steps of the chain cross the network:

| Recipe | Runs where | Needs the board |
|---|---|---|
| `fpga-bootrom` | on the server, like every other recipe | no |
| `vivado-fpga-build` | on the server, like every other recipe | no |
| `vivado-fpga-program` | on the server, driving the board over TCP | yes |
| `fpga-linux-boot` | on the server, reading the console over TCP | yes |

**Do not try to forward the USB cables.** A remote desktop session
redirects USB towards the *client* of the session, which is not where the
board is, and the JTAG and console cables tolerate the added latency
badly.

Both interfaces are reached over TCP instead, each by its own service
running on the machine the board is cabled to:

| Interface | On the machine holding the board | Given to the recipes |
|---|---|---|
| JTAG | `hw_server` (ships with Vivado), listening on 3121 | `vivado-fpga-program --hw-server <host>:3121` |
| Console | a serial to TCP bridge on the USB UART | `fpga-linux-boot --uart socket://<host>:<port>` |

Nothing has to be copied to the bench PC: the bitstream stays on the
server and is sent through the JTAG connection by the programming recipe.

`hw_server` needs nothing else: it *is* the remote debug protocol of
Vivado, and the recipe only connects to it.

For the console, any bridge exposing the serial port as a TCP socket
works, since the recipe opens it through `serial_for_url`:

- Linux: `ser2net`, or `socat TCP-LISTEN:4001,reuseaddr,fork /dev/ttyUSB1,raw,b115200`
- Windows: `com0com` + `hub4com`, or the `rfc2217` server shipped with
  pyserial (`python -m serial.rfc2217_server -p COM3 -P 4001`)

Prefer `rfc2217://` over `socket://` when the bridge supports it: the
line settings are then carried to the bridge, so `--baudrate` is applied
to the real port instead of being assumed to match. A bridge that is not
running is reported as an environment failure naming it, not as a boot
failure.

```bash
# Board cabled to bench-pc, flows running on the Linux server
./cook.py vivado-fpga-program -t cv32a6_imac_sv32 --hw-server bench-pc:3121
./cook.py fpga-linux-boot -t cv32a6_imac_sv32 --uart socket://bench-pc:4001
```

If the two machines are not on the same network, forward the two ports
through SSH rather than exposing them:

```bash
ssh -N -L 3121:localhost:3121 -L 4001:localhost:4001 user@bench-pc
./cook.py vivado-fpga-program -t cv32a6_imac_sv32 --hw-server localhost:3121
./cook.py fpga-linux-boot -t cv32a6_imac_sv32 --uart socket://localhost:4001
```

---

### Static Analysis

Code quality and lint checking tools.

#### `spyglass-design-read`

Load design into Spyglass for static analysis.

```bash
./cook.py spyglass-design-read [OPTIONS]
```

**Required Options:**
- `-t, --target TEXT` - CVA6 user configuration

**Example:**
```bash
./cook.py spyglass-design-read -t cv32a60x
```

#### `spyglass-run`

Run Spyglass static analysis checks.

```bash
./cook.py spyglass-run [OPTIONS]
```

**Required Options:**
- `-t, --target TEXT` - CVA6 user configuration

**Optional:**
- `--run-type [run_cli|gui|show_goals]` - Execution mode (default: `run_cli`)
  - `run_cli`: Command-line batch mode
  - `gui`: Interactive GUI mode
  - `show_goals`: Display analysis goals

In `run_cli` mode, the lint summary is compared against the per-target
baseline `config/target/<target>/expected_spyglass.rpt`: any new rule or
count increase fails the recipe (the full diff is recorded in the report).
A count decrease or a removed rule passes; update the baseline to make it
the new reference.

**Example:**
```bash
# Run checks in CLI mode
./cook.py spyglass-run -t cv32a60x

# Open GUI for interactive analysis
./cook.py spyglass-run -t cv32a60x --run-type gui
```

#### `verible-rtl-formating`

Format CVA6 RTL files with Verible formatter.

```bash
./cook.py verible-rtl-formating [OPTIONS]
```

**Required Options:**
- `-t, --target TEXT` - CVA6 user configuration

**Example:**
```bash
./cook.py verible-rtl-formating -t cv32a60x
```

**Note:** Verible formatting is mandatory before submitting pull requests.

#### `black-python-formating`

Format Python files with Black formatter.

```bash
./cook.py black-python-formating
```

No options required.

**Example:**
```bash
./cook.py black-python-formating
```

**Note:** Black formatting is mandatory before submitting pull requests.

#### `pylint-run`

Run Pylint static code analysis on Python files.

```bash
./cook.py pylint-run
```

No options required.

**Example:**
```bash
./cook.py pylint-run
```

**Note:** pylint 10/10 is mandatory before submitting pull requests.

---

### Documentation

#### `docs-build`

Build the CVA6 documentation: the AsciiDoctor specifications and the Sphinx
user manual.

```bash
./cook.py docs-build [OPTIONS]
```

**Required Options:**
- `-t, --target TEXT` - CVA6 user configuration the specifications document,
  or `--readthedoc` to prepare every chapter of `docs/` at once

**Optional:**
- `--readthedoc` - Prepare the documentation of every chapter of `docs/` that
  embeds a manual, in place: each rendered `.html` is placed next to its page
  and `user_cfg_doc.rst` is regenerated, as `make -C docs prepare` did for
  ReadTheDocs. Takes no `-t`, builds HTML only, and leaves Sphinx to
  ReadTheDocs, which runs `sphinx-build` itself.
- `-m, --manual [priv|unpriv|design]` - Manual to build, repeatable (default: all of them)
- `--sphinx / --no-sphinx` - Render the user manual with Sphinx (default: enabled)
- `--format [html|pdf|both]` - Format of the specifications (default: `html`)
- `--strict / --no-strict` - Fail on an AsciiDoctor or Sphinx warning (default: disabled)
- `--clean / --no-clean` - Clean working directory before (default: clean)

Two stages:

1. the **specifications**, one AsciiDoctor run per manual: the RISC-V
   privileged and unprivileged ones, and the CVA6 design manual. Their
   sources are assembled in the output directory, the upstream
   `riscv-isa-manual` submodule with the CVA6 overrides of
   `docs/riscv-isa/src` on top, together with the `.adoc` generated from
   the RTL configuration of the target;
2. the **user manual**, rendered by Sphinx from the `.rst` of `docs/`.

What is generated from the RTL, rather than written by hand:

| File | Content |
|---|---|
| `config.adoc` | AsciiDoctor attributes of the configuration, which the specifications test to include or exclude a section |
| `parameters.adoc` | parameter table of the configuration |
| `port_<module>.adoc` | IO ports of each documented module, the ones tied to a constant listed apart |
| `user_cfg_doc.rst` | reference table of `cva6_user_cfg_t` |

Each generated file opens on a licence and ownership header, taken from
`config/target/<target>/doc.yml`:

```yaml
authors:
  - "Original Author: Jean-Roch COULON - Thales"
```

| Key | Content | Default |
|---|---|---|
| `authors` | who is responsible for the documentation, one entry per line of the header | **required** |
| `copyright` | the copyright line | `Copyright 2024 Thales DIS France SAS` |
| `license` | the licence name | Solderpad Hardware License, Version 2.1 |
| `spdx` | the SPDX identifier | `Apache-2.0 WITH SHL-2.1` |
| `url` | where to obtain the licence | `https://solderpad.org/licenses/` |

`authors` is a list, so an organisation and the people it delegates to can
both appear, and a target whose documentation has no owner yet says so
rather than naming someone who is not:

```yaml
authors:
  - "Looking for a maintainer"
```

Every target carries the file and the recipe stops without it: the header
names an owner, and a generated document attributed to the wrong person is
worse than one that is missing. Values are quoted because an author line
usually contains a colon, which YAML would otherwise read as a key.

**Example:**
```bash
# Everything, for one configuration
./cook.py docs-build -t cv32a60x

# One manual as PDF, without the user manual
./cook.py docs-build -t cv32a65x -m design --format pdf --no-sphinx

# Every manual the chapters of docs/ embed, next to their pages
./cook.py docs-build --readthedoc
```

**Output:** `build/<target>/docs/` - `html/index.html` (user manual),
`{priv,unpriv}-isa-<target>.html` and `design-<target>.html`. The working
directory of each manual (its sources copied together with the generated
`.adoc`, twenty megabytes apiece) is removed once the document is rendered,
so what is left is what a CI job archives: the documents, the logs and the
report. `merge-reports` publishes the specifications next to the pipeline
report, and the dashboard links to them from the row of their target.

With `--readthedoc`, the chapters of `docs/` are discovered (`0<NN>_<target>/`
directories holding the page of a manual), each manual is rendered and copied
next to its page (`docs/<chapter>/riscv/priv-isa-<target>.html` and the
like), `docs/01_cva6_user/user_cfg_doc.rst` is regenerated for the last
chapter, and the output goes to `build/readthedoc/docs/`. A chapter whose
target has no `config/target/` directory of its own is documented from the
closest supported configuration - `cv64a6_mmu` from
`cv64a6_imafdc_sv39_hpdcache_pmp_mmu_axi`, as it moved under
`deprecated_packages/` upstream.

**Reported:** `docs_pages` and `docs_warnings` as KPIs, the label being the
page count. A manual that fails does not stop the others: they are
independent documents, and the report lists the verdict and the log of each.
Warnings do not fail the recipe by default - the documents render with them -
`--strict` is there for a pipeline that wants to hold the line.

**Prerequisites:** `asciidoctor` and its extensions
(`asciidoctor-bibtex`, `asciidoctor-diagram`, `asciidoctor-lists`,
`asciidoctor-mathematical`), the `wavedrom-cli` and `bytefield-svg`
diagram generators and `sphinx-build`. See
[Documentation dependencies](#documentation-dependencies); the recipe
checks them and names what to install.

---

### Reports

Each recipe writes a `cook_report.yml` in its output directory: the
verdict, the metrics and the KPIs it measured. How to produce one is
described in
[CONTRIBUTING.md](CONTRIBUTING.md#recipereport--the-verdict-and-what-was-measured); what the flows
record in it:

- **Benchmark cycle count**: the `*-uvm-run` recipes record the measured
  cycle count of every test. For known benchmarks (test name containing
  `coremark` or `dhrystone`), the per-MHz scores (CoreMark/MHz,
  Dhrystone/MHz, DMIPS/MHz) are computed from the iteration count the
  binary was compiled with (`benchmark_iterations` in the sw-compile
  manifest, defined once in `flows/patterns/coremark.py` and
  `flows/patterns/dhrystone.py`) and the GLOBAL_PATTERN cycle window.
  The cycle count is checked against the `<test>_cycle` key of
  `config/target/<target>/expected_values.yml`; any deviation fails the
  run.
- **Synthesis KPI**: `dc-shell-synth` reports the area breakdown (kGates),
  checks the total gate count against the `gates` key of
  `config/target/<target>/expected_values.yml` (tolerance: 250 gates),
  and generates a hierarchical area Sunburst chart
  (`build/<target>/synthesis/reports/synth_area.html` + `.csv`). With
  `--gtech`, it reports the `gtech_cells` and `gtech_registers` counts
  instead, the GTECH cells having no area, and fails on any latch. Its
  chart counts the cells of each block, one ring per level of hierarchy.

The recipes are the single source of truth for the verdict: a pipeline
reads these reports rather than the tool logs. What they contain, how to
gate a CI job on them and how the pipelines of the repository use them:
[CONTINUOUS_INTEGRATION.md](CONTINUOUS_INTEGRATION.md).

#### `merge-reports`

Merge every `cook_report.yml` found under `build/` into a single
pipeline report: `artifacts/reports/pipeline_report.yml`.

```bash
# Merge all job reports (all targets)
./cook.py merge-reports

# Only merge the reports of one target
./cook.py merge-reports -t cv32a65x
```

Cross-target recipe: it writes to `artifacts/`, not `build/<target>/`,
and `--target` is only a filter. Reports written by a testlist recipe
next to its own (one per test) are attached to the parent job under a
`children` key, so the pipeline report is self-contained. Pipeline
metadata (id, commit, author...) comes from the CI environment when
available and falls back to local git information, so the report can
also be produced and inspected on a workstation. The pipeline verdict
(`N/M PASS`) does not fail the recipe itself.

The specifications a `docs-build` job produced are copied next to the
report, under `artifacts/reports/docs/<target>/`, and recorded in the
`target_docs` key. That is what lets the dashboard link to them: it is a
single page published on its own, so a link into `build/` would be dead
there. The dashboard shows them at the top of the detail of their target,
above its KPIs, and reports the verdict of the job itself in a `Doc` column
of the matrix. A target no `docs-build` job ran on gets neither, and a
document that could not be copied is dropped from the key rather than
linked to nothing.

Paths of the working directory are made relative in the merged report
(`config/target/.../link.ld`, not `/gitlab-runner/.../cva6/config/...`):
the checkout directory is noise and differs between two pipelines of the
same commit. Paths outside it (CAD tools, shared toolchains) stay
absolute.

#### `report-html`

Render the pipeline report as a single self-contained HTML page:
`artifacts/reports/pipeline_report.html`.

```bash
# Render artifacts/reports/pipeline_report.yml (merge-reports output)
./cook.py report-html

# Render another pipeline report
./cook.py report-html -i path/to/pipeline_report.yml
```

The page inlines the vendored assets (`flows/templates/assets/`) and
the pipeline data, so it can be opened directly from the CI artifacts
or pushed as-is to the dashboard: no server, no external resource, no
token. In CI both recipes are the last two jobs of the `full-regression`
macro, so the dashboard is built inside the regression job itself.

---

### Macros

Automated multi-step workflows.

#### `full-regression`

Run the whole regression pipeline of `.gitlab-ci.yml` on a workstation,
the same recipes in the same order, with a cap on the jobs and on each
CAD licence pool.

```bash
./cook.py full-regression --dry-run   # what would run here
./cook.py full-regression -j 32 --vcs-licenses 10
```

Scheduling, licence pools, reports, options, and how to add a job:
[CONTINUOUS_INTEGRATION.md](CONTINUOUS_INTEGRATION.md#the-full-regression-macro).

---

#### `macro-vcs-generator-testlist`

Complete flow: VCS Generator → SW Compile → UVM Run from testlist.

```bash
./cook.py macro-vcs-generator-testlist [OPTIONS]
```

**Required Options:**
- `-t, --target TEXT` - CVA6 user configuration
- `-l, --testlist TEXT` - Testlist YAML file in `verif/tests`

**Optional:**
- `-n, --testname TEXT` - Single test of the testlist
- `-c, --toolchain [llvm-20-1-8|...]` - Toolchain (default: llvm-20-1-8)
- `--march TEXT` - Custom march
- `--mabi TEXT` - Custom mabi
- `--comp-mode [rtl|gate_wc_power|gate_wc_timing|coverage]` - Hardware compilation mode (default: `rtl`)
- `--trace-mode [gui|fast|compact|notrace]` - Trace mode (default: `notrace`)
- `--uvm-verbosity [NONE|LOW|MEDIUM|HIGH|FULL|DEBUG]` - UVM verbosity (default: `NONE`)
- `--tandem-enabled / --no-tandem-enabled` - Enable SPIKE tandem (default: disabled)
- `--tb-performance-mode / --no-tb-performance-mode` - Enable TB perf mode (default: disabled)
- `--stats / --no-stats` - Enable RTL perf tracer (default: disabled)
- `--sim-profile / --no-sim-profile` - Enable simulation profiling (default: disabled)
- `--run_opts TEXT` - Simulation run options
- `--batch-size INTEGER` - Tests to generate per batch (default: 1)
- `--seed INTEGER` - Random seed (randomized if not provided)
- `--uvm-seed TEXT` - UVM randomization seed

**Example:**
```bash
# Run complete random test generation flow
./cook.py macro-vcs-generator-testlist \
  -t cv32a60x \
  -l verif/tests/<generator-testlist>.yaml \
  -c llvm-20-1-8 \
  --trace-mode fast \
  --batch-size 4

# Single test with tandem verification
./cook.py macro-vcs-generator-testlist \
  -t cv32a65x \
  -l verif/tests/<generator-testlist>.yaml \
  -n arithmetic_stress \
  -c gcc-14 \
  --tandem-enabled \
  --stats
```

---

### Utilities

System utilities and configuration helpers.

#### `git-dependencies`

Install the external test repositories and patch the Git submodules.

```bash
./cook.py git-dependencies [OPTIONS]
```

Two things, both driven by `$CONFIG_DIR/dependencies.yml`:

- **clone** the external test repositories (riscv-tests, riscv-compliance,
  riscv-arch-test) at the pinned commit and apply their patches. These are
  *not* submodules: an existing destination is left untouched unless
  `--force` is passed;
- **patch the Git submodules** listed under `submodule_patches`. They are
  checked out by `git submodule update`, so a fix that is not merged
  upstream yet lives here as a patch rather than as a commit in the
  submodule, and its pointer keeps tracking upstream.

Applying a patch is idempotent, so the recipe can be run repeatedly: a
patch already in place is skipped. A submodule that is not initialised is
an environment error telling you to run `git submodule update --init
--recursive`.

**Optional:**
- `-r, --repo TEXT` - Install only this dependency, repeatable (default: all)
- `-f, --force` - Re-clone even if the destination already exists
- `-q, --quiet` - Suppress output (errors only)

**Generated files:**
- the destinations declared in `dependencies.yml`
  (`verif/tests/riscv-tests`, `verif/tests/riscv-compliance`,
  `verif/tests/riscv-arch-test`)
- `build/git_dependencies/cook_report.yml` - status of every dependency
  and of every submodule patch

**Example:**
```bash
# Install everything and patch the submodules
./cook.py git-dependencies

# Re-clone one dependency from scratch
./cook.py git-dependencies --repo riscv-tests --force
```

To declare a patch on a submodule, add it to `dependencies.yml` with the
reason it exists and what to watch for upstream, so it can be dropped once
the fix lands there:

```yaml
submodule_patches:
  verif/core-v-verif:
    patches:
      - "verif/patches/some-fix.patch"
      - "verif/patches/other-fix.patch:subdir"   # applied in subdir/
    reason: >
      Why the patch is needed, and what to watch for upstream.
```

---

#### `hwconfig-forge`

Modify or override hardware configuration parameters.

```bash
./cook.py hwconfig-forge [OPTIONS]
```

**Required Options:**
- `-t, --target_ref TEXT` - Reference CVA6 user configuration
- `-f, --target_forged TEXT` - Name of new forged configuration
- `-p, --param TEXT` - Parameter to override with value (`parameter=newvalue`) - repeat for multiple

**Example:**
```bash
# Create modified configuration
./cook.py hwconfig-forge \
  -t cv32a60x \
  -f cv32a60x_custom \
  -p "NrLoadPipeRegs=2" \
  -p "FpgaEn=false" \
  -p "CvxifEn=true"
```

**Output:** `config/target/<new target>/`, a complete target directory:
the forged `rtl_cfg_pkg.sv`, and the files of the reference target copied
beside it (`link.ld`, `spike.yaml`, `isa.yml`, `testbench_cfg.yml`,
`Flist.cva6`, `Flist.cva6_gate`, `Flist.cva6_synth`). It is passed to `-t`
like any other target.

The reference configuration is read through `flows/utils/rtl_config.py`,
the same parser `docs-build` uses: a parameter name absent from it is an
error naming the file to look at, instead of a replacement silently doing
nothing, and the forged package is read back to check it still parses.

#### `riscv-isa-modify`

Modify RISC-V ISA strings by adding or removing extensions with automatic dependency handling.

```bash
./cook.py riscv-isa-modify [OPTIONS]
```

**Required Options:**
- `-t, --target TEXT` - CVA6 user configuration (for output directory isolation)
- `-i, --isa TEXT` - Input RISC-V ISA string (e.g., `rv32imc_zicsr` or `rv64gc`)

**Optional Options:**
- `-a, --add TEXT` - Extensions to add if not present (can be specified multiple times)
- `-r, --remove TEXT` - Extensions to remove if present (can be specified multiple times)
- `-q, --quiet` - Suppress output (errors only)

**Features:**
- Automatic extension dependency handling (e.g., adding 'd' auto-adds 'f')
- G-macro expansion/compaction (G = IMAFD + Zicsr + Zifencei)
- Per-target output isolation (prevents contamination in parallel CI jobs)
- YAML output for easy shell parsing

**Examples:**
```bash
# Add floating-point extensions
./cook.py riscv-isa-modify -t cv32a60x --isa rv32imc --add f --add d

# Remove floating-point (also removes dependent extensions)
./cook.py riscv-isa-modify -t cv64a6_imafdc_sv39 --isa rv64gc --remove f

# Combined add and remove
./cook.py riscv-isa-modify -t cv32a60x --isa rv32imc_zicsr --add f --add d --remove c

# Use in shell script
./cook.py riscv-isa-modify -t cv32a60x --isa rv32imc --add f --quiet
MODIFIED_ISA=$(grep modified_isa build/cv32a60x/riscv_isa_modify/modified_isa.yml | awk '{print $2}')
echo "Result: $MODIFIED_ISA"  # rv32imfc
```

**Output:** `build/<target>/riscv_isa_modify/modified_isa.yml`

**Use Case:** Commonly used in CI to dynamically adjust ISA strings for specific test requirements (e.g., adding 'f' extension for virtual memory tests).

#### `self-check`

Verify framework integrity and configuration.

```bash
./cook.py self-check
```

No options required.

CAD tools are reported but not required one by one: the flows offer four
simulators and several optional steps (synthesis, STA, lint), so a missing
tool is a warning. The recipe only fails when no simulator at all (`vcs`,
`xrun`, `vsim`, `verilator`) is in the path, or when a mandatory
dependency is missing (Spike, submodules, riscv-tests).

**Example:**
```bash
./cook.py self-check
```

---

## Complete Flow Examples

Worked sequences, from a fresh clone to a design running on a board, are
in **[QUICKSTART.md](QUICKSTART.md)**: installation, RTL simulation
(single test, testlist, benchmarks, random tests, gate level) and FPGA.

## Simulation Outputs and Logs

### Build Directory Structure

Simulation outputs live in `build/<target>/simulation/<comp mode>/<run>/`,
one directory per run. The whole tree is described in
[CONTRIBUTING.md](CONTRIBUTING.md#build-directory-organization).

### Simulation Log Files Description

- **simulation.log**: Simulator console output
- **trace_rvfi_hart_00.dasm**: RTL simulation trace (RVFI)
- **spike_dasm.log**: RTL simulation trace disassembled (from trace_rvfi_hart_00.dasm)
- **tandem.log**: Spike Reference model trace (if tandem_mode enabled)
- **tandem_report.yml**: Tandem mismatchs  if any (if tandem_mode enabled)
- **timing_GLOBAL_PATTERN_end**: Time when ELF symbol timing_GLOBAL_PATTERN is detected
- **timing_GLOBAL_PATTERN_start**: Time when ELF symbol timing_GLOBAL_PATTERN is detected
- **timing_GLOBAL_PATTERN_start_cycle**: Cycle when ELF symbol timing_GLOBAL_PATTERN is detected
- **timing_GLOBAL_PATTERN_end_cycle**: Cycle when ELF symbol timing_GLOBAL_PATTERN is detected

### Waveform Generation

Waveform generation is controlled by the `--trace-mode` option:

- **`notrace`** (default): No waveform generation (fastest simulation)
- **`compact`**: Generate compact waveforms (FSDB format, smaller file size)
- **`fast`**: Generate fast waveforms (VPD format, faster dump, larger files)
- **`gui`**: Generate full waveforms for GUI viewing (FSDB format)

**Examples:**

```bash
# No waveforms (fastest)
./cook.py vcs-uvm-run -t cv32a60x -n hello-world --trace-mode notrace

# Compact waveforms (good for debugging)
./cook.py vcs-uvm-run -t cv32a60x -n hello-world --trace-mode compact

# Full GUI waveforms
./cook.py vcs-uvm-run -t cv32a60x -n hello-world --trace-mode gui

# View waveforms with Verdi
./cook.py vcs-uvm-gui -t cv32a60x -n hello-world
```

**Waveform file locations:**
- FSDB files: `build/<target>/simulation/<comp-mode>/<run>/trace.fsdb`
- VPD files: `build/<target>/simulation/<comp-mode>/<run>/trace.vpd`
