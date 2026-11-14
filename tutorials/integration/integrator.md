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

In your SoC, instantiate `cva6_top` (with the lockstep option) or `cva6`
(without), not the examples. The examples are the tops that `rtl-lint`,
`yosys-synth`, `dc-shell-synth` and Spyglass elaborate: use them as the
model of the types to give to `cva6_top`, see below.

The common ports are the clock, the active-low asynchronous reset, the
boot address, the hart id, the interrupts (`irq_i`, `ipi_i`,
`time_irq_i`), the debug request, the CV-X-IF coprocessor interface, the
memory port (`noc_req_o`/`noc_resp_i`) and the RVFI probes (can be left
open). The comments of the port list in `core/cva6.sv` describe each one.

## The types of the ports

`cva6_top` and `cva6` take the configuration and the types of their ports
as parameters. The bus types default to `logic`: define them from
`CVA6Cfg`, as `core/cva6_example_axi.sv` and `core/cva6_example_obi.sv`
do, and pass them to the instance:

| Parameter | Content | Model |
|---|---|---|
| `CVA6Cfg` | `build_config_pkg::build_config(<package>::cva6_cfg)` | both examples |
| `noc_req_t`, `noc_resp_t` | AXI: the `AXI_*` macros of `core/include/axi_types.svh`. OBI: a struct of six OBI buses (fetch, store, load, amo, mmu_ptw, zcmt) built with the `OBI_CFG_*` macros of `obi/typedef.svh` | the `noc_req_t` / `noc_resp_t` of the example of your bus |
| `rvfi_probes_t` | a struct of the `RVFI_PROBES_CSR_T` and `RVFI_PROBES_INSTR_T` of `rvfi_types.svh` | both examples |

The CV-X-IF types are derived inside the core from `CVA6Cfg`.

## Several different cores in one design

The configuration is a parameter of each instance, not a global setting.
So one design can hold several CVA6 with different configurations, for
instance a 32-bit embedded core on OBI next to a 64-bit application core
on AXI, each with the types built from its own configuration:

1. Give each configuration a package of its own. Copy the
   `rtl_cfg_pkg.sv` of each target and rename its package, for instance
   `cfg_a_pkg` and `cfg_b_pkg` instead of `cva6_config_pkg`.
2. For each core, build its configuration and the types of its ports, and
   pass them to its `cva6_top`:

```systemverilog
`include "obi/typedef.svh"
`include "axi_types.svh"
`include "rvfi_types.svh"

// Core A: cv32a65x, OBI
localparam config_pkg::cva6_cfg_t CfgA = build_config_pkg::build_config(cfg_a_pkg::cva6_cfg);
// One OBI bus, as in cva6_example_obi.sv; the same for store, load, amo,
// mmu_ptw and zcmt with CfgA.ObiStorebusCfg, ...
localparam type a_fetch_a_opt_t = `OBI_CFG_ALL_A_OPTIONAL_T(CfgA.ObiFetchbusCfg);
localparam type a_fetch_a_t     = `OBI_CFG_A_CHAN_T(CfgA.ObiFetchbusCfg, a_fetch_a_opt_t);
localparam type a_fetch_req_t   = `OBI_CFG_INTEGRITY_REQ_T(a_fetch_a_t);
localparam type a_fetch_r_opt_t = `OBI_CFG_ALL_R_OPTIONAL_T(CfgA.ObiFetchbusCfg);
localparam type a_fetch_r_t     = `OBI_CFG_R_CHAN_T(CfgA.ObiFetchbusCfg, a_fetch_r_opt_t);
localparam type a_fetch_rsp_t   = `OBI_CFG_INTEGRITY_RSP_T(a_fetch_r_t);
// ...
typedef struct packed {
  a_fetch_req_t obi_fetch_req;  a_store_req_t obi_store_req;
  a_load_req_t  obi_load_req;   a_amo_req_t   obi_amo_req;
  a_ptw_req_t   obi_mmu_ptw_req; a_zcmt_req_t obi_zcmt_req;
} a_noc_req_t;
// a_noc_resp_t: the same with the *_rsp_t types
localparam type a_rvfi_csr_t   = `RVFI_PROBES_CSR_T(CfgA);
localparam type a_rvfi_instr_t = `RVFI_PROBES_INSTR_T(CfgA);
typedef struct packed {a_rvfi_csr_t csr; a_rvfi_instr_t instr;} a_rvfi_probes_t;

cva6_top #(
    .CVA6Cfg(CfgA), .rvfi_probes_t(a_rvfi_probes_t),
    .noc_req_t(a_noc_req_t), .noc_resp_t(a_noc_resp_t)
) i_core_a (...);

// Core B: profile_rva23s64, AXI. The AXI macros name the channel types
// axi_*_chan_t: declare them in a scope of their own.
localparam config_pkg::cva6_cfg_t CfgB = build_config_pkg::build_config(cfg_b_pkg::cva6_cfg);
if (1) begin : gen_core_b
  localparam type axi_ar_chan_t = `AXI_AR_CHAN_T(CfgB);
  localparam type axi_aw_chan_t = `AXI_AW_CHAN_T(CfgB);
  localparam type axi_w_chan_t  = `AXI_W_CHAN_T(CfgB);
  localparam type axi_b_chan_t  = `AXI_B_CHAN_T(CfgB);
  localparam type axi_r_chan_t  = `AXI_R_CHAN_T(CfgB);
  localparam type b_noc_req_t   = `AXI_REQ_T(CfgB);
  localparam type b_noc_resp_t  = `AXI_RSP_T(CfgB);
  // b_rvfi_probes_t as for core A, with CfgB
  cva6_top #(
      .CVA6Cfg(CfgB), .rvfi_probes_t(b_rvfi_probes_t),
      .noc_req_t(b_noc_req_t), .noc_resp_t(b_noc_resp_t)
  ) i_core_b (...);
end
```

3. Elaborate with the file list of the core (`core/Flist.cva6`) and the
   two packages. `core/Flist.cva6` still reads one target package,
   `config/target/${TARGET_CFG}/rtl_cfg_pkg.sv` (the `cva6_config_pkg`):
   set `TARGET_CFG` to one of the targets.

Each core keeps its own options, the lockstep included: `DclsEn` in the
configuration of a core turns on its `cva6_top` lockstep only.

**Limitation.** A few globals still read `cva6_config_pkg` instead of
`CVA6Cfg`: `riscv::XLEN` in `core/perf_counters.sv` (the access to the
`mhpmcounter` CSRs), and some constants of `ariane_pkg`. With two cores of
different XLEN, the hardware performance counters of one of them are
accessed with the wrong width. Avoid reading them, or disable them
(`PerfCounterEn`), until these globals are removed.

This two-core design (cv32a65x on OBI, with and without lockstep, and
profile_rva23s64 on AXI) elaborates with slang and Verilator. It is not
run by the CI.

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
