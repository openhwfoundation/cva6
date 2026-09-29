<!--
Copyright 2026 Thales France

Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
You may obtain a copy of the License at https://solderpad.org/licenses/

Original Author: Yannick Casamatta (yannick.casamatta@thalesgroup.com)
-->

# Continuous integration with `cook.py`

For whoever runs `cook.py` from a CI engine: reads its results, adds a job
to a pipeline, or maintains one of the two pipelines of the repository.

- [Principle](#principle)
- [What every recipe leaves behind](#what-every-recipe-leaves-behind)
- [Gating a job on a recipe](#gating-a-job-on-a-recipe)
- [The full-regression macro](#the-full-regression-macro)
- [The GitLab CI pipeline](#the-gitlab-ci-pipeline)
- [The GitHub Actions TestHarness smoke](#the-github-actions-testharness-smoke)

Using the recipes: [README.md](README.md). Writing one:
[CONTRIBUTING.md](CONTRIBUTING.md).

## Principle

**The CI engine provides a machine, an environment and a place to publish.
The flow lives in `cook.py`.** A CI job calls recipes, as a person on a
workstation would, and reads the verdict they wrote, instead of parsing
tool logs on its own.

This gives three properties to rely on:

- Whatever a pipeline runs can be replayed on a workstation with the same
  command.
- The verdict is decided once, by the recipe, which knows its target, its
  test and its tool. A pipeline adds no judgement of its own.
- Adding a target, a testlist or a stage is a change in Python, not in
  the YAML of a CI engine.

## What every recipe leaves behind

Each recipe writes two files in its output directory, whatever it does.

### `cook_report.yml`: the verdict

| Key | Content |
| --- | --- |
| `recipe` | Name of the recipe that wrote it |
| `status` | `pass` or `fail`: **the field to gate on** |
| `fail_kind` | `null` on a pass. On a failure, `environment` or `test`, see below |
| `label` | Short verdict for a human, `PASS`, `FAIL`, or e.g. `2/2 PASS` for a testlist |
| `context` | Options and resolved parameters of the run |
| `metrics` | The tables the recipe printed, each with a `name`, a `kind`, a `status` and its rows in `data` |
| `kpi` | Measured values meant to be compared across pipelines, when the recipe has any |
| `job_started_at`, `job_end_at` | Wall-clock of the recipe, not of the CI job |

`fail_kind` says where the fix is:

- `environment`: the verdict is not meaningful. A tool, a licence, a
  prerequisite or the Python environment is missing or broken. Fix the
  setup and run again.
- `test`: the thing under test is at fault. The recipe extracted a real
  error from the logs: a compilation error, a failed simulation, a
  measurement out of its expected range.

When `GITLAB_CI` or `GITHUB_ACTIONS` is set, the report also records the
job it ran in: `category` (from `DASHBOARD_JOB_CATEGORY`), `job_id`,
`job_url` and `job_stage_name` (from `CI_JOB_ID`, `CI_JOB_URL` and
`CI_JOB_STAGE`). GitHub Actions does not set those three, so on GitHub
they stay empty unless the workflow exports them.

The metric kinds, and how a recipe produces them, are described in
[CONTRIBUTING.md](CONTRIBUTING.md#recipereport--the-verdict-and-what-was-measured).

### `cook_manifest.yml`: what was built, and how

| Key | Content |
| --- | --- |
| `recipe` | Name of the recipe |
| `date` | When it ran |
| `options` | The options it ran with |

This is what the next recipe checks its prerequisites against. For
instance, a run refuses an elaboration done with another target or another
trace mode. A CI check reads it for the same reason: it records what
actually ran, whatever command line the job believes it passed.

### Where they are

In the output directory of the recipe, under `build/<target>/`:

| Recipes | Directory |
| --- | --- |
| `sw-compile`, patterns | `compile/<test>/` |
| `<simulator>-uvm-comp` | `elab/sim_<comp_mode>/` |
| `<simulator>-uvm-run` | `simulation/sim_<comp_mode>/<run>/` |
| `<simulator>-testharness-comp` | `elab/sim_<comp_mode>_<simulator>_testharness/` |
| `<simulator>-testharness-run` | `simulation/sim_<comp_mode>_<simulator>_testharness/<run>/` |
| `testharness-run-testlist` | `simulation/testharness_<simulator>_<testlist stem>/` |

`<run>` is the test name unless `--run-name` gave another one. The
[Build Directory Organization](README.md#build-directory-organization) of
the README has the whole tree.

## Gating a job on a recipe

- **Gate on `status`.** A recipe does exit 1 on a failure, but the exit
  code only says *that* something failed, and the report says *what* and
  *where*.
- **Report `fail_kind` and `label`** in the summary of the job. An
  `environment` failure goes to whoever maintains the runner, a `test`
  failure to whoever touched the design.
- **Read the options from `cook_manifest.yml`**, not from the command line
  of the job.
- **Keep an independent check when a log carries one.** The TestHarness
  prints `*** SUCCESS *** (tohost = 0)`, and a check on it does not depend
  on how Cook reached its verdict.
- **Archive the `cook_report.yml` and `cook_manifest.yml` files with their
  `build/` path**, so that the artifact reads like a build directory and
  `merge-reports` can be run on it again.
- **Upload the artifacts even on failure** (`when: always` on GitLab,
  `if: always()` on GitHub). A failed pipeline is the one worth reading.

A recipe called from Python, as the macros do, bypasses Typer. **Pass all
its options explicitly**: an omitted option arrives as a Typer `OptionInfo`
object, which is truthy, instead of its default value.

## The full-regression macro

Run the whole regression pipeline of `.gitlab-ci.yml` in the current
working directory, without a CI engine: the same recipes are called in
the same order, but in a single Git checkout. Nothing is passed through
artifacts and the external test repositories are cloned once.

```bash
./cook.py full-regression [OPTIONS]
```

**This is the regression Thales runs on CVA6, and what it contains
changes with it.** The point is one job covering many targets at once,
not a fixed list: targets, testlists and stages are added and removed as
the verification progresses. Read `flows/macros/full_regression.py`
for what runs today, or `--dry-run` for what would run here.

Every target runs hello-world on the UVM testbench with VCS, with a
memory that answers in the cycle it is asked, then again depending on its
bus:

| Bus | Runs of hello-world |
| --- | --- |
| OBI | UVM on VCS, then UVM on VCS against the memory stalls the OBI agent randomises |
| AXI | UVM on VCS, then the TestHarness on VCS and on Verilator |

The TestHarness is AXI only, and AXI gets no stalling run: the AXI agent
of the UVM testbench is held in zero delay mode whatever the run, so it
would repeat the first one. The bus is the `hier` of `testbench_cfg.yml`.

The FPGA images of `FPGA_TARGETS` are built once the RTL of their target
elaborates: a design that does not elaborate in simulation would spend
hours of Vivado to fail in synthesis. The bootloader of the board comes
first, then the bitstream, then one job that programs the board and boots
Linux on it, holding the board for both. `--no-fpga` leaves them out, on a
machine without Vivado or without the board. The Intel/Altera images of
`ALTERA_TARGETS` are run only with `--altera`, no runner carrying their
board yet.

The targets of `GTECH_TARGETS` (cv32a60x, cv32a65x_noPMP_axi and
cv64a6_imafdc_sv39_hpdcache_pmp_mmu_axi) are synthesised on the GTECH cells
of dc_shell (`dc-shell-synth --gtech`), which needs no PDK, once their RTL
elaborates. The job checks their cell and register counts, and fails on
any latch. The synthesis on a real techno, and the gate-level simulation
of its netlist, only run with `--techno`.

### Scheduling and licences

Jobs form a dependency graph (like `needs:` in GitLab CI) executed by
threads, with two independent limits:

- `--jobs` caps the total number of recipes running at the same time.
- Each **CAD tool licence pool** has its own cap. Recipes sharing a pool
  are counted together, so the pipeline never asks for more licences
  than available:

| Pool | Recipes | Default limit |
| --- | --- | --- |
| `vcs` | `vcs-uvm-comp`, `vcs-uvm-run`, `uvm-run-testlist` | 10 |
| `spyglass` | `spyglass-design-read`, `spyglass-run` | 1 |
| `synth` | `dc-shell-synth` | 1 |
| `vivado` | `vivado-fpga-build` | 1 |
| `quartus` | `quartus-fpga-build` | 1 |
| `board:<board>` | the programming and the boot of one board | 1, fixed |
| *(none)* | compilations, Verilator, lints, documentation, reports | unlimited |

A job only starts once its dependencies passed **and** a licence slot is
free, so a job never holds a worker while waiting for a licence. A job
whose dependency failed is skipped, and a failure never stops the other
branches: the whole pipeline is run and reported in one go.

### Reports

Every recipe keeps writing its own `build/**/cook_report.yml`, so
`merge-reports` and `report-html` are always run at the end (even when
jobs failed) and build the same dashboard as the CI does:

- `artifacts/reports/pipeline_report.yml`: merged report of every job,
  including the verdict of the macro itself.
- `artifacts/reports/pipeline_report.html`: self-contained page, to be
  opened directly or pushed as-is to the dashboard.

Both paths are listed in the *Generated files* of the macro report; a
report that could not be produced is flagged as an error. The two recipes
are described in the [Reports](README.md#reports) section of the README.

### Options

**Optional:**
- `-t, --target TEXT` - CVA6 user configuration, repeatable (default: every target of the CI matrix)
- `-j, --jobs INTEGER` - Maximum number of recipes running at the same time (default: 8)
- `--vcs-licenses INTEGER` - Concurrent VCS jobs (default: 10)
- `--spyglass-licenses INTEGER` - Concurrent Spyglass jobs (default: 1)
- `--synth-licenses INTEGER` - Concurrent DC Shell synthesis jobs (default: 1)
- `--fpga / --no-fpga` - Build, program and boot the Xilinx FPGA images (default: on)
- `--altera / --no-altera` - The same for the Intel/Altera images (default: off)
- `--vivado-licenses INTEGER` - Concurrent Vivado builds (default: 1)
- `--quartus-licenses INTEGER` - Concurrent Quartus builds (default: 1)
- `--techno [...]` - Enable the synthesis and gate-level stages with this techno (disabled by default, like in the CI)
- `--period TEXT` - Synthesis target period (default: 15)
- `--dry-run` - List the jobs, their licence pool and their dependencies, run nothing
- `-q, --quiet` - Suppress output (errors only)

With `--jobs` greater than 1 the sub-recipes are run quietly (they all
share one console, their output would interleave): the macro prints the
pipeline progress only, and the full output of each recipe stays in the
Details of its own report. Use `--jobs 1` to get the verbose output back.

**Example:**
```bash
# Inspect what the pipeline would run, without running it
./cook.py full-regression --dry-run

# Full pipeline, 32 recipes at a time but never more than 10 VCS licences
./cook.py full-regression -j 32 --vcs-licenses 10

# Single target, including synthesis and gate-level simulation
./cook.py full-regression -t cv32a65x --techno my_techno --period 10
```

### Adding a job

In `flows/macros/full_regression.py`:

- `TARGETS` lists the targets.
- `TESTLISTS` maps a target to its testlists.
- `FPGA_TARGETS` and `ALTERA_TARGETS` pair a target with the board its
  image is built for.
- `scheduler.add(name, run, report_dir, deps=..., resource=...)` registers
  a job with its dependencies and its licence pool.

A recipe called from there receives **all** its options explicitly, see
[Gating a job on a recipe](#gating-a-job-on-a-recipe).

## The GitLab CI pipeline

The pipeline is the macro: `.gitlab-ci.yml` only provides the machine,
the environment and the publication of the dashboard. **Adding a target
or a testlist is a change in the macro, not in `.gitlab-ci.yml`.**

| Stage | Job | Role |
| --- | --- | --- |
| `build` | `build spike` | Builds the tandem reference model, once per core-v-verif commit into a shared directory |
| `regression` | `full regression` | Runs the macro, which is the whole pipeline, FPGA images included |
| `deploy` | `pages` | Publishes the dashboard, `when: always` |

The runner of `full regression` therefore carries Vivado and its licence,
and reaches the board through `$HW_SERVER_URL` for the JTAG and
`$UART_SERIAL` for the console, see the FPGA section of the
[README](README.md).

### Artifacts

Everything the regression does happens in the single `full regression`
job, so nothing transits through artifacts between recipes. The job
archives the per-recipe reports and the tool logs under `artifacts/logs/`,
keeping the `build/` tree structure; `build/` itself is not archived, it
also holds the `simv` binaries.

`pages` copies the dashboard of the regression job into `public/`: every
verdict of the pipeline is in it already.

### Publication

The dashboard is published by the `pages` job, one deployment per branch
or merge request:

```
$CI_PAGES_URL/            default branch
$CI_PAGES_URL/mr-42/      merge request 42
$CI_PAGES_URL/br-dev-foo/ branch dev/foo
```

The specifications of the documented targets are published next to it,
under the path the dashboard links to, so a target row carries a link to
its own manuals:

```
$CI_PAGES_URL/<prefix>/                                  the dashboard
$CI_PAGES_URL/<prefix>/docs/<target>/priv-isa-<target>.html
$CI_PAGES_URL/<prefix>/docs/<target>/design-<target>.html
```

`docs-build` is a job of the regression macro, so the documents are in
the build tree `merge-reports` reads; `pages` copies the result into
`public/`, which Pages serves and nothing else.

### Variables

| Variable | Role |
| --- | --- |
| `CONFIG_DIR` | Directory holding `setenv.sh`, `compiler.yml` and `techno.yml`; to be set in the CI project variables |
| `MY_JOBS` | `--jobs` of the macro |
| `MY_VCS_LICENSES`, `MY_SPYGLASS_LICENSES`, `MY_SYNTH_LICENSES`, `MY_VIVADO_LICENSES` | Licence pools of the macro |
| `XILINX_VIVADO_BASHRC`, `HW_SERVER_URL`, `UART_SERIAL`, `VIVADO_CMD` | Vivado and the board, for the FPGA jobs of the macro |
| `VERILATOR_INSTALL_DIR` | Verilator of the TestHarness jobs of the macro: `setenv.sh` puts its `bin/` in `PATH`, where the recipes look for it |
| `CI_KIND` | Which jobs a pipeline runs: set by `workflow:rules` from the pipeline source, or by hand for a web pipeline |
| `PAGES_PREFIX`, `PAGES_EXPIRE` | Deployment of the dashboard, set by `workflow:rules` |

## The GitHub Actions TestHarness smoke

`.github/workflows/cook-testharness-smoke.yml` runs on the pull requests
to `master_candidate`. With Verilator, no commercial tool is involved, so
it runs on a hosted runner. It builds the TestHarness of `cv32a65x_axi`,
runs two Hello tests one at a time, then again as the testlist
`verif/tests/testlist_verilator_testharness_smoke.yaml`, and checks every
result.

| File | Role |
| --- | --- |
| `.github/cook/setup/` | Installs Verilator, the RISC-V toolchain and SPIKE |
| `.github/cook/prepare_toolchains.py` | Writes `compiler.yml`, `techno.yml` and `environment.yml` into `$CONFIG_DIR`, with the `github_actions_gcc` toolchain |
| `.github/cook/run_smoke.py` | Runs the Cook commands and checks their reports |

`run_smoke.py` follows [Gating a job on a recipe](#gating-a-job-on-a-recipe):

- For each stage, it checks the `status` and `recipe` of its
  `cook_report.yml`.
- For each run, it checks the options of its `cook_manifest.yml`, the
  `Run <test>` row of its `Summary` table, and the log, which must hold the
  success marker, no failure marker, and the UART greeting for
  `hello-uart_0`.
- For the testlist, it checks that the `label` is `2/2 PASS`, that the
  `context` matches, and that the `Test results` table has one passing row
  per test, pointing at the run directory.

It refuses a checkout that already holds `build/cv32a65x_axi`, so that
earlier build products can never pass for the current ones.

Everything lands in `ci-results/`, uploaded as an artifact:

| Path | Content |
| --- | --- |
| `evidence.json` | The verdict of the smoke, the commands with their exit code, and the SHA-256 of the sources and binaries |
| `<stage>.log` | Console of each Cook command |
| `elab/`, `simulation/` | Cook files of each stage, under the same relative path as in `build/<target>/` |
| `single/<test>/` | The files of the single runs. The testlist reruns the same tests in the same directories, so they are saved before it overwrites them |

To replay it locally, from a fresh checkout with its submodules:

```bash
export RISCV=<toolchain> CV_SW_PREFIX=riscv-none-elf-
export VERILATOR_INSTALL_DIR=<verilator> SPIKE_INSTALL_DIR=<spike>
export PATH=$VERILATOR_INSTALL_DIR/bin:$PATH
export CONFIG_DIR=$PWD/ci-results/cook-config
python3 .github/cook/prepare_toolchains.py --output-dir "$CONFIG_DIR"
python3 .github/cook/run_smoke.py
```
