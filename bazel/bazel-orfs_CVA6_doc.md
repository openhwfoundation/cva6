Run CVA6 design flow with bazel-orfs:
===

## Requirements

1) [Bazelisk](https://bazel.build/install/bazelisk)

That's it. Bazel builds OpenROAD, OpenSTA, Yosys, ABC, GNU Make, and Qt from source, and manages all other dependencies (Python, toolchains) hermetically.

> On macOS: brew install bazelisk.
>
> On Windows: winget install Bazel.Bazelisk, choco install bazelisk, or scoop install bazelisk.
>
> On Linux: download Bazelisk binary add it to your PATH manually
>
> E.g. :
> ``` bash
> > curl -L -o bazelisk https://github.com/bazelbuild/bazelisk/releases/latest/download/bazelisk-linux-amd64
>
> > chmod +x bazelisk
> > sudo mv bazelisk /usr/local/bin/bazel
>
> # make sure you get the binary available in $PATH
> > which bazel
> bazel is /usr/local/bin/bazel
> ```

⚠️ **However, Bazel still relies on the host system compiler and standard Linux toolchain.** As a result, a reasonably recent Linux distribution is required. The CI runs the flow on **Ubuntu 24.04**.

Older distributions (e.g. Debian 11 Bullseye) may ship compiler or system libraries that are too old to build all Bazel dependencies successfully. In this case, the recommended solution is to run the flow inside a Docker or Apptainer container based on Ubuntu 24.04.

Example Docker and Apptainer build files are provided under:

```text
bazel/container/
```

Simply build the container, mount your CVA6 repository inside it, and run the Bazel commands from within the container.


2) Clone [CVA6](https://github.com/openhwfoundation/cva6):

```git clone git@github.com:openhwfoundation/cva6.git```

3) In your terminal, at the root of the repository:

``` bash
> bazel --version
# Should output:
bazel 8.6.0
```

which is the version defined in the .bazelversion file.

## How Bazel works:

Unlike a traditional Makefile-based flow, Bazel organizes a project as a graph of **targets**. Each target represents either:

* a file to generate,
* a library or executable to build,
* or an action to execute.

A target declares:

* its inputs,
* the command used to produce its outputs,
* and its dependencies on other targets.

From these declarations, Bazel computes the dependency graph and automatically executes only the steps that are required.

### Main Bazel files

Only two Bazel files are important for the CVA6 synthesis flow.

#### `MODULE.bazel`

`MODULE.bazel` declares the external dependencies required by the project.

For this repository, it specifies the versions of:

* `bazel-orfs`,
* ORFS (OpenROAD-flow-scripts), OpenROAD and Yosys, built from source,
* and other external repositories, with the overrides some of them need to build.

In normal usage, this file should rarely need to be modified. It is only updated when changing dependency versions (see [Updating ORFS, OpenROAD and bazel-orfs](#updating-orfs-openroad-and-bazel-orfs)) or adding new external packages.

#### `BUILD.bazel`

`BUILD.bazel` is where the actual build flow is described.

It defines the **targets** available in the repository and how they relate to one another. This is the file that users will most often modify when:

* adding support for a new CVA6 configuration,
* changing synthesis parameters,
* or creating additional design flow targets.

Each target is defined by calling a Bazel rule. For example:

```python
orfs_flow(
    name = "cv32a65x_synth",
    ...
)
```

The rule (`orfs_flow`) defines what kind of action will be performed, while the attributes configure that action. The most important attribute is `name`, which gives the target its identifier.

A target is referenced using the syntax:

```text
//:target_name
```

For example:

```bash
bazel build //:cv32a65x_synth
```

builds the target named `cv32a65x_synth` defined in the `BUILD.bazel` file at the repository root.

### Dependencies between targets

Targets can depend on other targets.

For example, a synthesis target may depend on generated RTL files, technology libraries, or configuration targets. When a target is built, Bazel first ensures that all of its dependencies are up to date.

Because Bazel knows the complete dependency graph, it only rebuilds what has changed. If neither a target nor any of its dependencies have been modified, Bazel simply reuses the previous result from its cache instead of executing the build again.

## Run the CVA6 flow

The `orfs_flow` rule allows stopping the OpenROAD flow at different stages. This is useful when only intermediate results are needed (for example, synthesis metrics) or when running the complete physical implementation.

The available stages are:

* `synth`
* `floorplan`
* `place`
* `cts` *(clock tree synthesis)*
* `grt` *(global routing)*
* `route`
* `final`

Each `orfs_flow` creates one target per stage, named `<name>_<stage>`. Building one of them runs every stage up to it, reusing the cached results of the stages that did not change.

For example:

```bash
# Run synthesis only
bazel build //:cv32a65x_synth

# Run up to cts
bazel build //:cv32a65x_cts

# Run the complete implementation flow of another config
bazel build //:cv64a6_imafdc_sv39_hpdcache_final
```

`bazel run` on the same targets builds them too, then also copies the stage into `tmp/<target>/`, with a `make` wrapper to rerun it or open it (see [GUI](#gui)).

Currently, the repository provides flow targets for `cv32a65x`, `cv64a6_imafdc_sv39_hpdcache`, and `cv64a6_imafdc_sv39_hpdcache_wb`, each available for the supported OpenROAD stages.
Additional targets can easily be added by following the existing examples in `BUILD.bazel`.

### GUI

The generated design can be inspected with the OpenROAD GUI.

For example:

```bash
bazel run //:cv32a65x_final gui_final
```

This opens the design database corresponding to the selected stage, allowing inspection of the floorplan, placement, routing, timing, and other implementation results.

### Results and reports

All generated outputs are available under Bazel's output directory:

```text
bazel-bin/
```

The most useful subdirectories are:

* `bazel-bin/logs/...` contains the log of every OpenROAD substep for each stage. These logs include execution time, memory usage, and the complete tool output.
* `bazel-bin/reports/...` contains the textual reports generated by OpenROAD.
* `bazel-bin/results/...` contains the generated design databases and implementation artifacts.

For example, for the `cv32a65x` configuration targeting the ASAP7 technology:

```text
bazel-bin/logs/asap7/cva6/base/
```

contains one log file and one JSON metrics file per stage. The JSON files gather the most important implementation metrics, including:

* maximum frequency (`fmax`),
* worst negative slack (WNS),
* total negative slack (TNS),
* standard-cell area,
* cell counts,
* and many other QoR metrics.

⚠️ **Build a single top-level target per `bazel build` command.** The output paths depend on the top-level module and the variant, not on the target: every CVA6 target (all configurations, full and fast variants) writes to `bazel-bin/{logs,reports,results}/asap7/cva6/base/`, and every SRAM macro target to `bazel-bin/*/asap7/hpdcache_sram_*_impl/base/`. As a consequence:

* `bazel-bin` only holds the results of the last target built,
* building two top-level targets in the same command (e.g. `bazel build //:cv32a65x_floorplan //:cv32a65x_fast_floorplan`) fails with `file ... is generated by these conflicting actions`.

The CI builds one configuration per job, so it is not affected.

## Understanding and editing the `BUILD.bazel` file

The synthesis flow is defined in the repository root `BUILD.bazel` file. It is organized in two parts:

* a **shared settings** section, holding the flow parameters and the RTL file list common to all targets,
* four `orfs_flow()` **target generators**, creating the targets for every configuration listed in `TARGET_CFGS`:

| Generator | Targets | Used by |
|---|---|---|
| Macro targets, full quality | `{TARGET_CFG}_{sram}` (`abstract_stage = "cts"`) | weekly GRT flow |
| Top-level targets, full quality | `{TARGET_CFG}` (e.g. `//:cv32a65x_grt`) | weekly GRT flow |
| Macro targets, fast variant | `{TARGET_CFG}_{sram}_fast` (`abstract_stage = "place"`) | per-push floorplan flow |
| Top-level targets, fast variant | `{TARGET_CFG}_fast` (e.g. `//:cv32a65x_fast_floorplan`) | per-push floorplan flow |

The full and fast variants use the same shared settings, so both CI flows build the same design and report comparable metrics. They only differ by the stage at which the macro flows stop.

### The `orfs_flow()` rule

`orfs_flow()` is the Bazel rule provided by `bazel-orfs` to describe an OpenROAD implementation flow.

The most important attributes are:

* `name`: name of the Bazel target.
* `top`: top-level Verilog module.
* `verilog_files`: RTL sources to synthesize.
* `sources`: additional input files (SDC constraints, PDN scripts, etc.).
* `macros`: list of macro abstract views to integrate into the design.
* `arguments`: OpenROAD flow parameters.
* `abstract_stage` (macro targets only): stage at which the macro flow stops before generating its abstract view.

Most modifications only require editing the shared settings or adding a new entry to `TARGET_CFGS`.

### Shared settings

| Variable | Content | Used by |
|---|---|---|
| `CVA6_ARGS` | OpenROAD flow parameters (`arguments`) | top-level targets |
| `CVA6_SOURCES` | SDC constraints, PDN script, Yosys canonicalize hook and power activity hook (`sources`) | top-level targets |
| `CVA6_VERILOG_FILES` | CVA6 RTL file list, excerpt from `core/Flist.cva6` (`verilog_files`) | top-level targets |
| `SRAM_ARGS` | OpenROAD flow parameters (`arguments`) | macro targets |
| `SRAM_SOURCES` | SDC constraints, pin placement and PDN scripts (`sources`) | macro targets |

In `CVA6_VERILOG_FILES`, the `{TARGET_CFG}` placeholder is replaced by the configuration name, which selects `core/include/{TARGET_CFG}_config_pkg.sv`. Each target then appends the SRAM wrappers of its configuration, from `bazel/srams/`.

### Main CVA6 targets

Each top-level target:

* synthesizes the selected CVA6 configuration,
* uses the SRAM macro abstracts of its variant (full or fast),
* applies the OpenROAD parameters defined in `CVA6_ARGS`,
* and runs the implementation flow to the selected stage.

The RVFI verification port of the core (`rvfi_probes_o`) is removed right after elaboration by `bazel/canonicalize.tcl` (`SYNTH_CANONICALIZE_TCL`), like in the ORFS `asap7/cva6` reference design. This port only feeds testbenches and is left unconnected in a real SoC, but at the top level of this flow it makes up ~80% of the IO pins. `SYNTH_OPT_HIER` then lets Yosys remove the logic that only fed it, including inside the modules kept by the hierarchical synthesis.

### SRAM macro targets

The macro target generators create one implementation flow for every SRAM used by each CVA6 configuration.

These flows are independent from the top-level design and are used only to generate the abstract LEF views required during floorplanning.

The `abstract_stage` parameter specifies how far the macro implementation is run before generating its abstract view. It is set to `cts` for the full variant, which provides sufficiently realistic macro timing, and to `place` for the fast variant, which is much quicker and enough when the top level stops at floorplan.

The macro flows use a dedicated PDN, `bazel/pdn-sram.tcl`, restricted to metal layers M1-M4 like the ASAP7 fakeram macros. The abstract LEF obstructs every layer holding a shape, so this leaves M5-M7 free for the top level to route over the macros. The top-level PDN, `bazel/pdn.tcl`, connects to their M4 power pins.

In the top-level RTL, the `hpdcache_sram_1rw` and `hpdcache_sram_wbyteenable_1rw` modules come from `bazel/srams/` instead of the HPDcache behavioral models: they only instantiate the macro (`*_impl` module), and ignore their parameters. The macro dimensions are those hardcoded in the `bazel/srams/{TARGET_CFG}_*_impl.sv` files.

### Known limitation: the icache is not synthesized

Only the dcache (HPDcache) SRAMs are replaced by macros. The icache SRAMs (tag and data) are **removed from the synthesized netlist**, in every configuration:

* the icache instantiates its SRAMs through `common/local/util/tc_sram_wrapper.sv` (cv64a6 configurations) or `tc_sram_wrapper_cache_techno.sv` (cv32a65x, `TechnoCut = 1`), which both wrap their `tc_sram` instance in `// synthesis translate_off`,
* yosys-slang honors it without any warning: the SRAM read data is left undriven, and synthesis removes the logic that depends on it (e.g. the tag comparison).

As a result, the area, timing, power and congestion reported by this flow, and shown on the PD dashboard, leave out the icache SRAMs (2 KiB of data for cv32a65x, 16 KiB for the cv64a6 configurations, plus the tags) and part of the icache logic. The metrics remain meaningful to track regressions from commit to commit, but they are not the PPA of the complete core.

See [Improvement tracks](#improvement-tracks) for the fix.

### The flow parameters

The `arguments` attribute contains the OpenROAD flow parameters passed to `bazel-orfs`: synthesis options, floorplan settings, placement density, clock tree synthesis, routing options and various implementation settings. They come from `CVA6_ARGS` for the top level and from `SRAM_ARGS` for the macros, where each parameter is briefly commented.

Complete list and doc can be found [**here**](https://github.com/The-OpenROAD-Project/OpenROAD-flow-scripts/blob/master/flow/scripts/variables.yaml).

These settings target **commit-to-commit PPA regression tracking**, not the best achievable results:

* **They must stay constant.** Changing any of them, or bumping the ORFS/OpenROAD versions in `MODULE.bazel`, shifts every metric and starts a new baseline on the dashboard.
* **Timing repair is disabled at every stage**, so that timing metrics reflect the RTL rather than what the optimizer managed to fix.
* **Power is reported at a fixed switching activity** (`bazel/power-activity.tcl`, sourced before the floorplan and global route metrics): OpenSTA's default activity propagation does not converge on CVA6, and made the power jump between unrelated netlists. The file explains what the metric tracks and the long-term alternative (activity from simulation).
* **Steps that do not affect the tracked metrics are skipped** (tap and fill cells, IR drop analysis, etc.). Metrics reporting must stay enabled, since the dashboard reads them.

The speed-oriented parameters are documented in the `bazel-orfs` documentation:

https://github.com/The-OpenROAD-Project/bazel-orfs#speed-up-your-builds

To try a different value on a single target without modifying the shared settings, merge an override into its `arguments`:

```python
arguments = CVA6_ARGS | {"PLACE_DENSITY": "0.60"},
```

### Adding a new CVA6 configuration

Adding support for a new CVA6 configuration only requires adding a new entry to the `TARGET_CFGS` dictionary, following the existing examples.

The configuration name must exactly match the corresponding configuration package:

```text
core/include/{TARGET_CFG}_config_pkg.sv
```

This package is then picked automatically through the `{TARGET_CFG}` placeholder of `CVA6_VERILOG_FILES`.

The SRAM names must also match the corresponding SRAM Verilog module names.

The `name`, `rows` and `width` fields are **not read by the flow**: they document each macro, with the hierarchical path of an instance and the dimensions hardcoded in its `_impl.sv` file.

For a new configuration to work, the corresponding SRAM implementation files must be added manually under:

```text
bazel/srams/
```

These `{TARGET_CFG}_{sram}_impl.sv` files must contain the hardcoded SRAM dimensions for the new configuration. The easiest approach is to copy one of the existing implementations and modify it accordingly.

## Keeping the flow in sync with the CVA6 RTL

Some parts of the flow duplicate information from the RTL. Nothing checks that they stay consistent, so RTL changes may require updating them:

* **RTL file list**: `CVA6_VERILOG_FILES` in `BUILD.bazel` is a copy of part of `core/Flist.cva6`. A file added, renamed or removed in `core/Flist.cva6` must be reported there too, otherwise `OR-flow-floorplan` fails on the pull request (unknown module at elaboration).
* **dcache SRAM dimensions**: changing the dcache geometry of a configuration (size, associativity, line width in its `*_config_pkg.sv`, or the HPDcache parameters) changes the dimensions of its SRAMs. The `bazel/srams/{TARGET_CFG}_*_impl.sv` files, and the `rows`/`width` fields of `TARGET_CFGS`, must then be updated by hand: the wrappers ignore their parameters, so the flow would otherwise keep the old macros.
* **Top-level ports**: `bazel/canonicalize.tcl` fails the flow if the `rvfi_probes_o` port is renamed, and the SDC files fail it if the clock port (`clk_i`) is.

## Updating ORFS, OpenROAD and bazel-orfs

bazel-orfs provides a command that updates the bazel-orfs, ORFS and OpenROAD commits pinned in `MODULE.bazel` (including the OpenROAD submodule archives of its `patch_cmds`), then runs `bazel mod tidy`:

```bash
bazel run @bazel-orfs//:bump
```

After an update:

* check that the flow still builds: the ORFS patch (`bazel/patches/fix_orfs_dev_deps.patch`) and the `single_version_override` workarounds of `MODULE.bazel` may need updating, or may no longer be needed (their comments say when they can be dropped),
* every metric of the PD dashboard may shift: push the update in a pull request of its own, so that the step in the trends is attributed to it (`OR-flow-floorplan` runs on `MODULE.bazel` changes).

## CI and PD dashboard

### Workflows

| Workflow | Trigger | What it does |
|---|---|---|
| `OR-flow-floorplan.yml` | Push to `master` and pull requests changing `core/`, `vendor/`, `common/` or the Bazel setup; manual | Builds `//:{TARGET_CFG}_fast_floorplan` for the 3 configurations |
| `OR-flow-grt.yml` | Weekly (Sunday, 02:00 UTC); manual | Builds `//:{TARGET_CFG}_grt` for the 3 configurations. Fails on any global routing error (congestion), since bazel-orfs lets a congested GRT pass |
| `PD-dashboard.yml` | After each run of the two workflows above; manual | Collects their metrics, generates the PD dashboard, deploys the GitHub Pages site and persists the dashboard data |

Each OR-flow job uploads two artifacts: `PD-{flp,grt}-{arch}-{config}` with the metrics JSON of the last stage, and `PD-{flp,grt}-logs-{arch}-{config}` with the logs, reports and build parameters. The Bazel disk and repository caches are saved by `master` runs only; pull requests and other branches restore them. Each workflow has its own disk cache per configuration: a GRT run without one starts from the floorplan cache, which already holds the tools built from source.

### PD dashboard

The scripts are in `.github/scripts/dashboard_physical-design/`:

* `extract_PD_metrics.py` fetches the latest runs of a flow through the GitHub API, downloads their artifacts and extracts the metrics. `PD_FLOWS` defines the tracked flows, and `extract_flp_metrics()`/`extract_grt_metrics()` the metrics read from the ORFS JSON files,
* `generate_PD_dashboard.py` renders `templates/PD_dashboard.html`,
* `check_PD_site.py` warns about dead download links.

The `master` runs are the reference runs, shown in the trends and the run history. Pull request runs and runs of other branches are each compared to the latest `master` run started before them where the same flow passed.

### Data branch and GitHub Pages

The dashboard history is persisted on the `gh-pages-cva6-dashboard-data` branch, shared with the tier dashboard (`openhw-cva6-tier-dashboard.yml`):

* `data/PD/`: the PD runs (`runs_PD_flp.json`, `runs_PD_grt.json`) and their raw files (`raw/<run id>/`: metrics JSON and zipped logs of each configuration),
* `data/tier/`: the tier dashboard runs,
* `data/dash-site/`: the last generated site. Each dashboard workflow deploys the whole site, so it needs the last page of the other dashboard.

Each workflow only writes its own paths, and retries its push if the other workflow pushed in between.

The site is deployed with `actions/deploy-pages`: in the repository settings, *Pages* > *Source* must be set to *GitHub Actions*. It holds a landing page (`index.html`), `PD_dashboard.html` and `tier_dashboard.html`.

To rebuild the PD history from scratch (e.g. corrupted data), delete `data/PD/` on the data branch: the next update imports again the last 20 runs of each flow. Runs whose artifacts have expired (after 90 days by default) are then shown as failed, with no metrics.

## Improvement tracks

* **Synthesize the icache** (see [Known limitation: the icache is not synthesized](#known-limitation-the-icache-is-not-synthesized)): replace the icache SRAMs by macros, built like the dcache ones, instead of the `tc_sram` wrappers. Synthesizing them as flip-flops would be much larger. For reference, the `pd/synth` flow keeps them as black boxes (`set_dont_touch` in `pd/synth/cva6_synth.tcl`).
* **Generate the SRAM implementation files**: a script could generate the `bazel/srams/{TARGET_CFG}_*_impl.sv` files from the `rows` and `width` fields of `TARGET_CFGS`, instead of maintaining hand-written copies. It would make adding a configuration, or changing a dcache geometry, a `BUILD.bazel` change only.
