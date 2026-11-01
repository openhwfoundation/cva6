# CVA6 RISC-V CPU [![Build Status](https://github.com/openhwgroup/cva6/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/openhwgroup/cva6/actions/workflows/ci.yml) [![master_candidate](https://riscv-ci.pages.thales-invia.fr/cva6-dashboard/latest/badge.svg)](https://riscv-ci.pages.thales-invia.fr/cva6-dashboard/latest/) [![Documentation Status](https://readthedocs.com/projects/openhw-group-cva6-user-manual/badge/?version=latest)](https://docs.openhwgroup.org/projects/cva6-user-manual/?badge=latest) [![GitHub release](https://img.shields.io/github/release/openhwgroup/cva6?include_prereleases=&sort=semver&color=blue)](https://github.com/openhwgroup/cva6/releases/)

CVA6 is a 6-stage, single-issue, in-order CPU which implements the 64-bit RISC-V instruction set. It fully implements I, M, A and C extensions as specified in Volume I: User-Level ISA V 2.3 as well as the draft privilege extension 1.10. It implements three privilege levels M, S, U to fully support a Unix-like operating system. Furthermore, it is compliant to the draft external debug spec 0.13.

It has a configurable size, separate TLBs, a hardware PTW and branch-prediction (branch target buffer and branch history table). The primary design goal was on reducing critical path length.

<img src="docs/03_cva6_design/_static/ariane_overview.drawio.png"/>

# CVA6 Target Configurations

CVA6 is not one CPU but a family: from a 32-bit microcontroller to a
superscalar 64-bit core running Linux, every point built from the same RTL
by its configuration package. The CI builds and verifies 35 of them, each in
`config/target/<target_name>/`; see [config/README.md](config/README.md).

## Member configurations

Each of these configurations is maintained by an OpenHW member. CoreMark/MHz
measured in simulation, with an ideal memory:

| Target | Maintainer | CoreMark/MHz |
|---|---|---|
| `cv32a60x` | Thales | 3.25 |
| `cv32a65x` | Thales | 4.69 |
| `fpga_linux_cv32a6` | PlanV | 3.03 |
| `fpga_linux_cv64a6` | PlanV | 2.73 |

### cv32a60x

32-bit embedded core maintained by Thales: RV32IMC + B + Zcb, scalar, OBI
bus, no PMP. Its configuration of the `cv32a60x-v6.0.0` tag reached TRL5,
verified within the TRISTAN project.

### cv32a65x

32-bit embedded core maintained by Thales: the ISA of cv32a60x on a
superscalar pipeline, OBI bus, 8 PMP entries. Its configuration of the
`cv32a60x-v6.0.0` tag reached TRL5, verified within the TRISTAN project.

### fpga_linux_cv32a6

Reference 32-bit configuration maintained by PlanV to boot Linux on the Genesys 2
FPGA board: RV32IMAC, Sv32 MMU, S and U modes, PMP.

### fpga_linux_cv64a6

Reference 64-bit configuration maintained by PlanV to boot Linux on the Genesys 2
FPGA board: RV64GC + B, Sv39 MMU, S and U modes, PMP.

## Profiles and reference points

CoreMark/MHz measured in simulation, with an ideal memory:

| Target | Core | CoreMark/MHz | Limitations |
|---|---|---|---|
| `profile_rvi20u32` | RV32IM, smallest core | 2.79 | |
| `profile_tinyc32` | RV32IMC + Zcb/Zcmp/Zcmt, smallest with code compression | 2.79 | |
| `profile_rvm23u32` | RVM23 microcontroller profile | 3.24 | profile still a draft |
| `profile_perf32_axi` | RV32IMAFC, superscalar, AXI HPDcache | 5.08 | |
| `profile_perf32_obi` | Same core on OBI, no cache | 5.25 | figure set by a zero-wait memory |
| `profile_rvi20u64` | RV64IM, smallest RV64 core | 2.22 | |
| `profile_rva20s64` | RVA20 application profile, Sv39, Linux | 2.41 | |
| `profile_rva22s64` | RVA22 application profile | 2.91 | lacks Zicboz, Zfhmin, Svpbmt, Svinval |
| `profile_rva23s64` | RVA23 application profile, hypervisor | 2.96 | lacks V and 12 other extensions |
| `profile_perf64_axi` | RV64GC + B, superscalar, Sv39, Linux | 4.26 | |

## Option crosses

21 `summit_` targets cross the structural options (XLEN, superscalar, MMU,
hypervisor, caches, FPU, endianness, triggers...) so each one keeps working
whatever the others.

# Quick Start

#### cook.py

`cook.py` is a Python-based command runner that provides a unified interface for CVA6 workflows including software compilation, RTL simulation with multiple simulators (VCS, Xcelium, Questa), synthesis, and analysis.

**Quick Start Example:**
```bash
# Clone the repository
git clone https://github.com/openhwgroup/cva6.git
cd cva6

# Python 3.12 or later, in a virtual environment. uv downloads the
# interpreter, whatever the Python of the system (pip3 install --user uv):
uv venv -p 3.12 .venv && . .venv/bin/activate
uv pip install -r flows/requirements.txt

# Initialize submodules
git submodule update --init --recursive

# Patch the submodules and clone the external test suites (riscv-tests, ...).
# Required: cook.py stops while a submodule patch of
# flows/config/dependencies.yml is not applied. Run it again after a pull.
./cook.py git-dependencies

# Install Spike ISA simulator (requires: gcc, g++, device-tree-compiler, libboost-dev)
# See verif/regress/install-spike.sh for details
(cd verif/regress && source ./install-spike.sh)

# Configure your environment (adapt to your setup)
# Edit flows/config/setenv.sh - Set paths to your CAD tools (VCS, Xcelium, Questa, etc.)
# Edit flows/config/compiler.yml - Set your RISC-V toolchain paths (GCC or LLVM)
# Edit flows/config/techno.yml - Set your ASIC library paths (optional, for synthesis)
source flows/config/setenv.sh

# Optional: Verify your setup
./cook.py self-check
# Optional: Enable shell autocompletion for cook.py commands
./cook.py --install-completion
# Optional: Get help on available commands
./cook.py --help

# Compile a test program
./cook.py hello-world --target cv32a60x --compiler llvm-22

# Compile RTL and run simulation with VCS
./cook.py vcs-uvm-comp --target cv32a60x          #
./cook.py vcs-uvm-run --target cv32a60x --testname hello-world

# Or with Xcelium
./cook.py xcelium-uvm-comp --target cv32a60x
./cook.py xcelium-uvm-run --target cv32a60x --testname hello-world

# Or with Questa
./cook.py questa-uvm-comp --target cv32a60x
./cook.py questa-uvm-run --target cv32a60x --testname hello-world
```

**For complete documentation**, see [flows/README.md](flows/README.md)

# Tutorials

* **[Running Simulations](tutorials/running_sim.md)**
* **[ASIC Implementation](tutorials/asic.md)**
* **[FPGA Implementation and running an OS](tutorials/fpga.md)**
* **[Instruction Tracing](corev_apu/instr_tracing/README.md)**

# Directory Structure:

The directory structure separates the [CVA6 RISC-V CPU](#cva6-risc-v-cpu) core from the [CORE-V-APU FPGA Emulation Platform](tutorials/fpga.md#corev-apu-fpga-emulation).
Files, directories and submodules under `cva6` are for the core _only_ and should not have any dependencies on the APU.
Files, directories and submodules under `corev_apu` are for the FPGA Emulation platform.
The CVA6 core can be compiled stand-alone, and obviously the APU is dependent on the core.

The top-level directories of this repo:
* **ci**: Scriptware of the former CI (toolchain and test suite builds).
* **common**: Source code used by both the CVA6 Core and the COREV APU, under `local`.
* **config**: Configurations of the core: one directory per target in `config/target`, see [config/README.md](config/README.md).
* **core**: Source code for the CVA6 Core only. There should be no sources in this directory used to build anything other than the CVA6 core.
* **corev_apu**: Source code for the CVA6 APU, exclusive of the CVA6 core. There should be no sources in this directory used to build the CVA6 core.
* **docs**: Documentation.
* **flows**: `cook.py` recipes, CI pipeline and dashboard, see [flows/README.md](flows/README.md).
* **pd**: Example and CI scripts to synthesis CVA6.
* **perf-model**: Performance model of the core.
* **tutorials**: Simulation, ASIC and FPGA tutorials.
* **util**: General utility scriptware.
* **vendor**: Third-party IP maintained outside the repository.
* **verif**: Verification environment for the CVA6. The verification files shared with other cores are in the [core-v-verif](https://github.com/openhwgroup/core-v-verif) repository on GitHub. core-v-verif is defined as a cva6 submodule.

Not versioned, created by `cook.py`: **build** (outputs of the recipes, one
directory per target), **artifacts** (pipeline report and dashboard) and
**tools** (Spike, riscv-pk, Zephyr). The external test suites are cloned in
`verif/tests` by `cook.py git-dependencies`.

## verif Directories

- **bsp**:     board support package for test-programs compiled/assembled/linked for the CVA6.
This BSP is used by both `core` testbench and `uvmt_cva6` UVM verification environment.
- **core-v-verif**: submodule of the verification components shared with other cores.
- **docs**:    verification plans and specifications.
- **env**:     UVM environment (`uvme`) and riscv-dv extensions (`corev-dv`).
- **patches**: patches applied to the submodules by `cook.py git-dependencies`.
- **regress**: scripts of the former flow to install tools and run test suites.
- **sim**:     riscv-dv simulation environment.
- **tb**:      testbench module instancing the core
- **tests**:   test lists (`*.yaml`, read by `cook.py`) and the sources of the custom, unit and UVM tests

# Planned Improvements

Go to the CVA6 Kanban Board which also loosely tracks planned improvements.


# Contributing

We highly appreciate community contributions.
<br><br>To ease the work of reviewing contributions, please review [CONTRIBUTING](CONTRIBUTING.md).


# Issues and Troubleshooting

If you find any problems or issues with CVA6 or the documentation, please check out the [issue tracker](https://github.com/openhwgroup/cva6/issues)
and create a new issue if your problem is not yet tracked.


# Publication

If you use CVA6 in your academic work you can cite us:

<details>
<summary>CVA6 Publication</summary>
<p>
```
@article{zaruba2019cost,
   author={F. {Zaruba} and L. {Benini}},
   journal={IEEE Transactions on Very Large Scale Integration (VLSI) Systems},
   title={The Cost of Application-Class Processing: Energy and Performance Analysis of a Linux-Ready 1.7-GHz 64-Bit RISC-V Core in 22-nm FDSOI Technology},
   year={2019},
   volume={27},
   number={11},
   pages={2629-2640},
   doi={10.1109/TVLSI.2019.2926114},
   ISSN={1557-9999},
   month={Nov},
}
```
</p>
</details>
<br/>


# Resources and Ecosystem

The CVA6 core is part of a vivid ecosystem. In [this document](RESOURCES.md), we gather pointers to this ecosystem (building blocks, designs, partners...)

# Acknowledgements

Check out the [acknowledgements](ACKNOWLEDGEMENTS.md).
