# Integrating CVA6 in a SoC

For the SoC integrator: where the RTL is, how to collect its files, how to
choose a configuration and which top to instantiate.

**Prerequisites:** [getting_started.md](../getting_started.md), steps 1 to 3
(clone, submodules, `git-dependencies`).

## Where the RTL is

| Path | Content |
|---|---|
| `core/` | the CVA6 core: pipeline, caches, MMU, PMP |
| `core/include/` | packages: `config_pkg.sv` (`cva6_user_cfg_t`, `cva6_cfg_t`), `build_config_pkg.sv`, `ariane_pkg.sv`, `riscv_pkg.sv` |
| `core/cvfpu/` | the FPU (submodule) |
| `core/cache_subsystem/hpdcache/` | the HPDcache (submodule) |
| `vendor/pulp-platform/` | common cells, AXI, OBI, FPGA memories (copied in the repository) |
| `common/local/util/` | shared utilities (SRAM wrappers, ...) |
| `config/target/<target>/` | the configuration of each target |
| `corev_apu/` | the APU platform (TestHarness, FPGA SoC): not needed by the core |

The core does not depend on `corev_apu/`. See the
[directory structure](../../README.md#directory-structure) of the root README.

## Apply the submodule patches

Some fixes are not merged upstream yet. They are kept as patches in
`verif/patches/` and listed under `submodule_patches` in
[flows/config/dependencies.yml](../../flows/config/dependencies.yml). One of
them patches the HPDcache (`core/cache_subsystem/hpdcache`).

If you take the RTL from this repository, run:

```bash
./cook.py git-dependencies
```

after every clone and every pull. Without it, the HPDcache you integrate
is not the one CVA6 is verified with, and the CVA6 RTL does not compile
against it (the patch adds a field the cache adapters use). If you do not use `cook.py`, apply by hand, with
`git apply` in the submodule directory, every patch listed for that
submodule in `dependencies.yml`.

## Choose a configuration

A configuration (a *target*) is a directory of `config/target/`. The RTL
parameters are in its `rtl_cfg_pkg.sv`: a package `cva6_config_pkg` with
a `cva6_cfg` constant of type `config_pkg::cva6_user_cfg_t`. The tops
turn it into the full `config_pkg::cva6_cfg_t` with
`build_config_pkg::build_config(cva6_config_pkg::cva6_cfg)`.

- Start from an existing target when one is close to your need. The list,
  with the role of each group (`cv...` products, `fpga_linux_`,
  `profile_`, `summit_`), is in
  [config/README.md](../../config/README.md#available-targets).
- Do not build a product on a `summit_` target: their options may change.
- To create a target, follow
  [Creating a New Target](../../config/README.md#creating-a-new-target).
  `hwconfig-forge` copies a target and overrides parameters:

```bash
./cook.py hwconfig-forge -t cv32a60x -f my_soc_core -p "NrLoadPipeRegs=2"
```

The meaning of each field of `cva6_user_cfg_t` is in
`core/include/config_pkg.sv`. Keep `isa.yml`, `spike.yaml` and
`testbench_cfg.yml` of the target consistent with `rtl_cfg_pkg.sv`
([Best Practices](../../config/README.md#best-practices)).

## Collect the files: the Flist

The file lists are standard filelists (`-F` includes, `+incdir+`, one file
per line, `//` comments), read by most simulators and synthesis tools.

| File | Use |
|---|---|
| `config/target/<t>/Flist.cva6` | RTL simulation and lint; it includes `core/Flist.cva6` |
| `config/target/<t>/Flist.cva6_synth` | synthesis; it includes `core/Flist.cva6_synth`, where the HPDcache SRAMs are blackbox models |
| `config/target/<t>/Flist.cva6_gate` | gate-level simulation |
| `config/target/<t>/Flist.cva6_fpga`, `Flist.cva6_altera` | the FPGA builds |

`core/Flist.cva6` is a core-only manifest. It uses three placeholders,
which your scripts must define as environment variables (most tools expand
`${VAR}` in a filelist) or substitute:

| Placeholder | Value |
|---|---|
| `${CVA6_REPO_DIR}` | root of the CVA6 checkout |
| `${TARGET_CFG}` | the target name: selects `config/target/${TARGET_CFG}/rtl_cfg_pkg.sv` |
| `${HPDCACHE_DIR}` | `${CVA6_REPO_DIR}/core/cache_subsystem/hpdcache` |

For example, with VCS:

```bash
export CVA6_REPO_DIR=$PWD TARGET_CFG=cv32a60x
export HPDCACHE_DIR=$CVA6_REPO_DIR/core/cache_subsystem/hpdcache
vcs -sverilog -F config/target/cv32a60x/Flist.cva6 ...
```

For a tool that does not follow `-F` includes, `util/flist_flattener.py`
writes one flat list, with the placeholders expanded from the environment:

```bash
python3 util/flist_flattener.py --print_incdir --print_newline \
  config/target/cv32a60x/Flist.cva6 > cva6_cv32a60x.f
```

A `Bender.yml` is also at the root of the repository, with one Bender
target per configuration. The `cook.py` flows only use the Flist files.

## The top-level modules

| Module | File | Role |
|---|---|---|
| `cva6` | `core/cva6.sv` | the core. Parameters: `CVA6Cfg` (`cva6_cfg_t`) and the types of its ports (`noc_req_t`, `noc_resp_t`, RVFI, CV-X-IF) |
| `cva6_top` | `core/cva6_top.sv` | wraps `cva6`; adds the lockstep (DCLS) option of `DclsEn` |
| `cva6_example_axi` | `core/cva6_example_axi.sv` | instantiation example of `cva6_top` for an AXI target: defines the AXI types from the configuration |
| `cva6_example_obi` | `core/cva6_example_obi.sv` | the same for an OBI target: the memory port is a set of OBI buses (fetch, load, store, AMO, page table walker, Zcmt) |

The two examples are the tops that `rtl-lint`, `yosys-synth`,
`dc-shell-synth` and Spyglass elaborate. Start from the one of your bus.

The common ports are the clock, the active-low asynchronous reset, the
boot address, the hart id, the interrupts (`irq_i`, `ipi_i`,
`time_irq_i`), the debug request, the CV-X-IF coprocessor interface, the
memory port (`noc_req_o`/`noc_resp_i`) and the RVFI probes (can be left
open). The comments of the port list in `core/cva6.sv` describe each one.

## The bus: AXI or OBI

The bus is chosen by `MemSubsystem` in `rtl_cfg_pkg.sv`:

| `MemSubsystem` | Bus | Caches | `hier` of `testbench_cfg.yml` |
|---|---|---|---|
| `MEM_HPDCACHE_AXI` | one AXI4 port (with atomics) | HPDcache, instruction and data | `axi` |
| `MEM_OBI` | several OBI ports | none | `obi` |

`testbench_cfg.yml` tells the flows which testbench and which example top
to use. It must agree with `MemSubsystem`: the recipes refuse a mismatch.
The AXI widths come from the `CVA6ConfigAxi*` localparams of
`rtl_cfg_pkg.sv`. Only AXI targets run on the TestHarness
([simulation/testharness.md](../simulation/testharness.md)); both buses run
on the UVM testbench ([simulation/uvm_testbench.md](../simulation/uvm_testbench.md)).

## Check your configuration

Lint the RTL of a target with slang and Verilator, no licence needed:

```bash
./cook.py rtl-lint -t my_soc_core
```

The result is compared with `config/target/<t>/expected_lint.yml`; the
first time, create the baseline with `--update-baseline`. Then estimate
the size on generic cells, also without licence:

```bash
./cook.py yosys-synth -t my_soc_core
```

Both read the same Flist as your flow ([synthesis/yosys.md](../synthesis/yosys.md)).
Then run a first test in simulation, on the testbench that suits you
([simulation/README.md](../simulation/README.md)).

## See also

- [config/README.md](../../config/README.md): the targets and their files
- [synthesis/README.md](../synthesis/README.md): synthesis flows
- [simulation/gate_level.md](../simulation/gate_level.md): simulation of the netlist
- [fpga/README.md](../fpga/README.md): the FPGA SoC of `corev_apu`
- [developer/ci_checks.md](../developer/ci_checks.md): checking a change like the CI
- The user manual, `docs/01_cva6_user/` (interfaces, parameters)
