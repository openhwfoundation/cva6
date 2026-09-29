# Writing a cook.py flow

How the framework is put together, and what a new recipe is expected to
look like. For *using* the flows, see [README.md](README.md); for a
worked path through them, [QUICKSTART.md](QUICKSTART.md); for running
them from a CI engine, [CONTINUOUS_INTEGRATION.md](CONTINUOUS_INTEGRATION.md).

## Table of Contents

- [Philosophy](#philosophy)
- [Architecture](#architecture)
- [Adding a recipe](#adding-a-recipe)
- [The helpers](#the-helpers)
- [Where code belongs](#where-code-belongs)
- [Build directory organization](#build-directory-organization)
- [Build manifests and prerequisite checks](#build-manifests-and-prerequisite-checks)
- [Trying a recipe out](#trying-a-recipe-out)
- [Before submitting](#before-submitting)

## Philosophy

**One recipe, one tool invocation, one output directory.** A recipe drives
a tool and reports what it did. It does not orchestrate other recipes:
that is what the macros of `flows/macros/` are for.

**A recipe is callable from the command line and from Python.** The macros
call recipes as plain functions, so a recipe takes its inputs as arguments
rather than reading global state. One consequence worth knowing: an option
left out of such a call arrives as the Typer descriptor, not as its
default, and `OptionInfo` is truthy — pass the value explicitly.

**The recipe is the single source of truth for the verdict.** It writes
its own `cook_report.yml`, which the CI collects; there is no separate
reporting step that could disagree with it.

**An environment problem is not a test failure.** A missing tool, a
missing prerequisite or a malformed configuration stops the recipe with a
message naming what to install or which command to run first. Only the
design under test can fail a test.

**No `make`.** Everything is driven from `cook.py`, so a flow behaves the
same on a workstation and in the CI, and a target is selected with `-t`
rather than hardcoded in a Makefile.

## Architecture

```
CVA6_ROOT_DIR/
├── cook.py                      # Main entry point
├── flows/
│   ├── recipes/                 # Main recipes
│   │   ├── sw_compile.py
│   │   ├── vcs_uvm_comp.py
│   │   ├── vcs_uvm_run.py
│   │   ├── dc_shell_synth.py
│   │   ├── vivado_fpga_build.py # FPGA bitstream (Vivado)
│   │   ├── vivado_fpga_program.py
│   │   ├── quartus_fpga_build.py # FPGA bitstream (Quartus, Altera)
│   │   ├── quartus_fpga_program.py
│   │   ├── fpga_linux_boot.py
│   │   ├── docs_build.py        # Documentation (AsciiDoctor + Sphinx)
│   │   └── ...
│   ├── patterns/                # Pre-configured basic tests
│   │   ├── hello_world.py
│   │   ├── coremark.py
│   │   └── dhrystone.py
│   ├── macros/                  # Multi-recipe automation
│   │   └── full_regression.py   # Whole pipeline in one working directory
│   ├── utils/                   # Helper functions
│   │   ├── autocompletion.py    # CLI option types and completion
│   │   ├── config_loader.py
│   │   ├── console.py           # Shared Rich console
│   │   ├── fpga_board.py        # FPGA board parameters
│   │   ├── manifest.py          # Build manifest (cook_manifest.yml)
│   │   ├── recipe_report.py     # Recipe report (cook_report.yml)
│   │   ├── run_cmd.py           # Command runner
│   │   ├── job_scheduler.py     # Job graph runner of the macros
│   │   ├── rtl_config.py        # rtl_cfg_pkg.sv parser
│   │   ├── target_config.py     # config/target/<target>/ accessors
│   │   └── uart_boot.py         # Serial console boot watch
│   └── config/                  # Configuration (customize for your env)
│       ├── compiler.yml         # Toolchain configuration
│       └── techno.yml           # Technology configuration
└── build/                       # Build directory (generated)
```

## Adding a recipe

1. Create a Python file in `flows/recipes/`, `flows/patterns/`, or `flows/macros/`
2. Define a Typer application named `app`
3. The module will be automatically loaded by `cook.py`

Example:

```python
import typer

app = typer.Typer()

@app.command()
def my_recipe(
    target: str = typer.Option(..., "--target", "-t", help="CVA6 configuration"),
):
    """Description of my recipe."""
    # Implementation
    pass
```

### The shape of a recipe

Every recipe follows the same four beats: open a report, check what it
needs, do the work, close the report.

```python
@app.command()
def my_recipe(
    target: str = typer.Option(..., "--target", "-t",
                               autocompletion=autocompletion_target),
    quiet: bool = typer.Option(False, "--quiet", "-q"),
):
    """One line, shown by `./cook.py --help`."""
    out_dir = Path.cwd() / "build" / target / "my_recipe"
    report = RecipeReport(
        "my-recipe",                 # the command name
        out_dir=out_dir,
        title="My recipe",           # heading on the console and dashboard
        context={"target": target},  # the options, recorded and displayed
        quiet=quiet,
    )

    report.step("Check the prerequisites")
    require_prerequisite(
        elf, f"compiled software for test {test!r}",
        f"./cook.py sw-compile -t {target} ...", report,
    )

    report.step("Run the tool")
    out_dir.mkdir(parents=True, exist_ok=True)   # run_cmd does not create it
    run_cmd(cmd=["my-tool", "-o", str(out_dir)], report=report,
            log_file=out_dir / "my_tool.log", timeout=600)

    report.metric("Results", {"produced": 42})
    write_manifest(out_dir, "my-recipe", {"target": target}, report)
    report.end()
```

`report.end()` is the single exit point: it writes `cook_report.yml` and
sets the exit code from what was recorded. A recipe never calls
`sys.exit()` or raises `typer.Exit` itself.

Paths follow the working directory, which `cook.py` checks is the root of
the checkout: `Path.cwd()` is the repository, and a path the user typed is
taken as given so the shell that completed it and the recipe reading it
agree.

### Naming

The command is the module name with underscores turned into dashes:
`flows/recipes/docs_build.py` is `./cook.py docs-build`. Keep the pair
consistent, the CI and the dashboard key jobs on the command name.

## The helpers

Five modules cover what a recipe needs. Their full signatures are in the
docstrings; what follows is what each is for and the traps that come with
it.

### Failures: the `report` convention

A recipe has a **single exit point**, `report.end()`, and a
`cook_report.yml` must exist even when it aborts early. Helpers of
`flows/utils/` follow one rule, readable from their signature:

| Signature | Contract |
|---|---|
| takes `report` | **may terminate the recipe**, through `report.error(...)` or `report.error_exit(...)`. The report is written before `typer.Exit` is raised. The caller checks no return value and must not catch that exit. |
| does not take `report` | **never terminates the recipe**: either a pure function, or one raising an ordinary exception the recipe handles itself. |

First group: `run_cmd`, `require_prerequisite`,
`require_manifest_option`, `check_tandem_verdict`, and the
`read_config_or_exit_*` of `target_config`.

Second group: `extract_rvfi_timing` (wrapped in a `try/except OSError`
by the caller), `formats.*`, `config_loader.*`, and the
`autocompletion_*` functions — the latter are called by the *shell*
during completion, where a failure must not kill the CLI.

Readers of `config/target/<target>/` spell the contract out in their
name, so a call site says what happens on a missing file without opening
the helper:

| Naming | On a missing file or key |
|---|---|
| `read_config_or_exit_<what>` | the recipe cannot work without it: it stops with a message naming the file to add (`..._testbench_cfg`, `..._isa`, `..._flist`) |
| `read_config_<what>` | optional: yields `None`/`{}` and the caller skips what depended on it (`read_config_expected_value`), so a target carrying no golden numbers stays usable |

`read_config_or_exit_flist` is also the single RTL filelist parser: it
expands the `${CVA6_REPO_DIR}`/`${TARGET_CFG}`/`${HPDCACHE_DIR}`
placeholders, follows the `-F` includes, drops comments and `+incdir+`
entries, and returns source files only — each recipe then formats them
for its own tool (an `analyze` command for dc_shell/fm_shell, a plain
path for verible). It replaced three local copies that had already
diverged.

A lookup that *cannot* fail belongs to the second group, and should stay
there rather than take a `report` for an unreachable branch: make it
total and assert it at import time. `top_elaborate()` and `dut_hier()`
are total over `Cva6Hier` for that reason, so adding a flavour without
its derived names breaks the very first `cook.py` call instead of
failing inside a recipe.

Recipes must not raise `typer.Exit` directly: `error_exit()` for early
aborts, `end()` as the single exit point.

### `run_cmd` — running a tool

```python
from flows.utils.run_cmd import run_cmd

output = run_cmd(
    cmd=["vcs", "-full64", "-o", str(simv)],   # a list, never a string
    report=report,
    cwd=elab_dir,
    env={"VCS_HOME": vcs_home},   # merged into os.environ, not replacing it
    log_file=elab_dir / "compilation.log",
    timeout=3600,
    error_patterns=[r"^Error-"],
    warning_patterns=[r"^Warning-"],
    check=True,
    capture_output=True,
)
```

Every argument after `cmd` is keyword-only, and `report` is required.

**It does not raise.** A non-zero exit code, a command that cannot be
executed and a timeout are all recorded in the report; the recipe carries
on and `report.end()` turns what was recorded into the exit code. Test
`report.failed` when the next step depends on this one having worked.

**The command is a list.** A string is refused with an error rather than
being handed to a shell, so a path containing a space cannot silently
split into two arguments.

**`timeout` is a wall clock on the whole command**, enforced by a watchdog
that kills the process group. A tool that hangs while keeping stdout open
— a stuck simulation, a licence wait — is covered, which a
`subprocess` timeout on the stream alone would not be.

`error_patterns` and `warning_patterns` mark the report from the tool
output; `check=False` keeps a non-zero exit from failing the report, for
the tools that use the exit code as an answer rather than as a verdict.

### `RecipeReport` — the verdict and what was measured

Each recipe writes one `cook_report.yml`. It is the single source of
truth for the verdict: the CI reads it, the dashboard renders it, and
`merge-reports` assembles them into the pipeline report.

| Method | Use |
|---|---|
| `step(name)` | open a phase, shown as a console rule |
| `info` / `success` / `warning` | print **and** record a message |
| `error(msg, env=False)` | mark the report failed, keep going |
| `error_exit(msg, env=True)` | write the report and stop now |
| `metric(name, data)` | a table (dict) or rows (list of dicts) |
| `kpi(name, value, unit=, expected=, better=)` | one comparable number, collected across the pipeline |
| `log(name, lines)` / `data(name, payload)` | text, or a raw payload for post-processing |
| `analyze_log(log_file, error_patterns=...)` | grep a tool log and attach the matching lines |
| `add_context(dict, table=)` | record what the recipe was given |
| `end(msg)` | write the report, set the exit code |

Metric values are **pure**: a number, not `"42 kGates"`. The unit and the
display format belong to the metric, not to the value, so the dashboard
and the KPI comparisons can compute on it. The format of a column is
inferred from its name and type (`flows/utils/formats.py`), `fmt=` settles
the ambiguous cases.

The kinds of metric a report carries:

- `table`: name/value pairs — `report.metric("Timing", {"cycles": 3400})`
- `rows`: list of rows (columns = the dict keys); a `status` key
  ("pass"/"fail"/"env") holds the row verdict and a fail/env row fails
  the report — `report.metric("Test results", [{"test": ..., "status":
  "pass", "report": ...}])`, or incrementally with `add_row(...)`
- `kpi`: a single comparable value with a stable name, also collected in
  the top-level `kpi:` dict of the report so cross-pipeline tools read
  them without parsing
- `log`: text lines — `report.log("Generated files", lines)`
- `data`: raw machine-readable payload for post-processing

`env=True` on an error says *the environment is wrong*, not *the design
is wrong*: a missing tool, an unreadable configuration. The dashboard
counts those apart from test failures, which is what keeps a broken
runner from looking like a broken design.

### `manifest` — what a recipe produced, and what it needs

`write_manifest()` records at the end of a producer recipe which options
its artifacts were built with; `require_prerequisite()` and
`require_manifest_option()` let a consumer refuse to start rather than
fail obscurely half an hour later. Both are detailed in
[Build manifests and prerequisite checks](#build-manifests-and-prerequisite-checks).

### `target_config` — reading `config/target/<target>/`

One reader per file of the target directory, named after what happens
when it is missing (see
[the `report` convention](#failures-the-report-convention)):

| Function | Reads | Returns |
|---|---|---|
| `read_config_or_exit_testbench_cfg` | `testbench_cfg.yml` | the `Cva6Hier` flavour |
| `read_config_or_exit_isa` | `isa.yml` | the `(march, mabi)` pair |
| `read_config_or_exit_flist` | `Flist.cva6*` | the source files, includes followed |
| `read_config_or_exit_rtl_cfg` | `rtl_cfg_pkg.sv` | the RTL parameters, resolved |
| `read_config_or_exit_doc` | `doc.yml` | the documentation header fields |
| `read_config_expected_value(s)` | `expected_values.yml` | the KPI baselines, or `None` |
| `target_dir(target)` | — | the directory itself |

Never build those paths by hand in a recipe: the layout of
`config/target/` has moved before, and these are what moved with it.

### `autocompletion` — option types and shell completion

The enumerations a recipe takes its options from (`CompMode`,
`TraceMode`, `UvmVerbosity`, `Cva6Hier`, `FpgaBoard`, `AlteraBoard`) and
the completion callbacks (`autocompletion_target`,
`autocompletion_testname_compiled`, ...). Pass the callback with
`autocompletion=` on the Typer option: completion runs in the *shell*, so
those functions never fail loudly — a broken one silently gives no
suggestion.

## Where code belongs

| Directory | Holds | Test |
|---|---|---|
| `flows/recipes/` | one tool, one flow | it is something a user runs |
| `flows/patterns/` | a pre-configured test (sources, iterations, cycle window) | it describes *what* to run, not *how* |
| `flows/macros/` | a graph of recipes | it calls recipes, it does not call tools |
| `flows/utils/` | a helper **used by more than one recipe** | a second caller exists |

The last line is the one that gets bent. Code used by a single recipe
belongs to that recipe, however large it is: `flows/utils/` is what
recipes share, not where long files go. A recipe holding a whole flow
runs long — `docs-build` carries the table of the ports each
configuration ties to a constant — and the lint allows twelve hundred
lines for that reason. Past it, extract what a *second* recipe would
use, or move the data out to a file next to the recipe; moving private
code to `flows/utils/` only hides the size somewhere else.

## Build directory organization

The `build/` directory is structured as follows:

```
build/
├── <target>/                    # e.g., cv32a60x, cv32a65x
│   ├── compile/                 # Software compilation outputs
│   │   └── <test name>/          # e.g., hello-world, coremark
│   │       ├── compile.log
│   │       ├── <test>.elf       # Executable binary
│   │       ├── <test>.dump      # Disassembly
│   │       ├── <test>.size      # Size report
│   │       └── cook_manifest.yml # Build manifest (options, symbols, march)
│   ├── elab/                    # RTL elaboration
│   │   └── <compilation mode>/  # e.g., sim_rtl
│   │       ├── compilation.log
│   │       ├── simv             # Simulation executable
│   │       └── cook_manifest.yml
│   ├── simulation/              # Simulation results
│   │   └── <compilation mode>/  # e.g., sim_rtl
│   │       └── <run name>/      # the test name unless --run-name
│   │           ├── simulation.log
│   │           ├── trace_rvfi_hart_00.dasm  # RVFI trace
│   │           ├── spike_dasm.log  # the same, disassembled
│   │           ├── trace.fsdb   # waveforms (--trace-mode gui/compact)
│   │           └── cook_report.yml
│   ├── synthesis/               # Synthesis results
│   │   ├── build_config.yaml
│   │   └── ...
│   ├── fpga/                    # FPGA bitstream generation
│   │   └── <board>/             # e.g., genesys2
│   │       ├── build.tcl        # Generated Vivado script
│   │       ├── vivado.log
│   │       ├── ariane_xilinx.bit
│   │       └── reports/         # Utilization, timing, CDC
│   ├── fpga_altera/             # Altera bitstream (quartus-fpga-build)
│   │   └── <board>/             # .qsf, output_files/*.sof, *.rpt
│   ├── fpga_program/            # Board programming
│   │   └── <board>/
│   ├── fpga_altera_program/     # Altera board programming
│   │   └── <board>/
│   ├── fpga_boot/               # Linux boot on the board
│   │   └── <board>/
│   │       └── boot.log         # Serial console transcript
│   ├── spyglass/                # RTL lint
│   ├── docs/                    # Documentation (docs-build)
│   │   ├── html/                # Sphinx user manual
│   │   └── *.html               # Specifications of the target
│   ├── riscv_isa_modify/        # Derived ISA strings
│   └── verible/                 # RTL formatting
│       └── verible-cmd.log
├── bootrom/                     # FPGA bootloader, per board (fpga-bootrom)
│   └── <board>/                 # bootrom_<XLEN>.sv, .dts, .dtb
├── black_python_formating/      # Cross-target recipes, no <target>
├── pylint_run/
├── git_dependencies/
├── self_check/
└── full_regression/             # Report of the macro itself
```

**Structure:**
- Each **target** (CVA6 configuration) has its own directory
- Each **recipe** has a working directory inside the target
- Results are organized by task type (compile, simulation, synthesis, etc.)
- Recipes that are not target-specific write at the root of `build/`
- Every one of those directories holds the `cook_report.yml` of the recipe
  that produced it, and a `cook_manifest.yml` when it produces artifacts
  other recipes consume

The merged pipeline report is written outside `build/`, in
`artifacts/reports/` (`pipeline_report.yml` and `pipeline_report.html`),
because it describes the whole run rather than one recipe.

## Build manifests and prerequisite checks

Recipes often depend on artifacts produced by other recipes (e.g. a simulation
needs the software compiled by `sw-compile` and the design elaborated by
`vcs-uvm-comp`). To make these dependencies explicit and user-friendly, the
framework provides `flows/utils/manifest.py`:

- **`write_manifest(out_dir, recipe, options, report)`** - called at the end of a
  producer recipe. Writes a `cook_manifest.yml` file in the recipe's output
  directory recording the recipe name, date, and all options used. Example:

  ```yaml
  # build/cv32a60x/elab/sim_rtl/cook_manifest.yml
  recipe: vcs-uvm-comp
  date: '2026-08-26T14:32:11'
  options:
    target: cv32a60x
    comp_mode: rtl
    trace_mode: notrace
    tandem_enabled: false
    stats: false
    sim_profile: false
  ```

- **`require_prerequisite(path, description, hint, report)`** - called at the
  beginning of a consumer recipe. If the artifact is missing, prints an
  actionable error telling the user which recipe to run first, then exits:

  ```
  Missing prerequisite: compiled software for test 'hello-world'
    Expected: build/cv32a60x/compile/hello-world/hello-world.elf
    Run first: ./cook.py sw-compile -t cv32a60x -c <toolchain> --out hello-world <sources>
  ```

- **`read_manifest(out_dir, report)` + `require_manifest_option(...)`** - used by
  consumer recipes to verify that the options requested now are compatible
  with the options used by the producer. For example, `vcs-uvm-run
  --trace-mode fast` fails early with an explanation if the design was
  elaborated with `--trace-mode notrace`:

  ```
  Incompatible option: trace mode 'fast' requires a design elaborated with trace support
    'vcs-uvm-comp' was run with trace_mode='notrace', expected one of ['gui', 'fast', 'compact']
    Fix: ./cook.py vcs-uvm-comp -t cv32a60x --comp-mode rtl --trace-mode fast
  ```

  If no manifest exists (artifacts generated by an older cook.py), the
  compatibility check is skipped with a warning instead of failing.

**Current prerequisites enforced:**

| Consumer recipe | Needs | Produced by |
|---|---|---|
| `spike-run` | Spike binary, compiled ELF | `git-dependencies`, `sw-compile` |
| `vcs-uvm-run` / `xcelium-uvm-run` / `questa-uvm-run` | compiled ELF, elaborated design | `sw-compile`, `*-uvm-comp` |
| `uvm-run-testlist` | elaborated design, ELF of every test | `*-uvm-comp`, `sw-compile-testlist` |
| `vcs-uvm-gui` | FSDB trace of the test | `vcs-uvm-run --trace-mode gui/fast` |
| `*-uvm-comp` in a gate mode | synthesized netlist | `dc-shell-synth` |
| `spyglass-run` | design read setup | `spyglass-design-read` |
| `vcs-generator-run` | generator `simv` | `vcs-generator-comp` |
| `vivado-fpga-build` | bootloader of the board | `fpga-bootrom` |
| `quartus-fpga-build` | bootloader of the board | `fpga-bootrom` |
| `vivado-fpga-program` | bitstream of the board | `vivado-fpga-build` |
| `quartus-fpga-program` | bitstream of the board | `quartus-fpga-build` |
| `fpga-linux-boot` | board programmed with the design | `vivado-fpga-program` / `quartus-fpga-program` |

A missing prerequisite is an **environment** failure, not a test failure:
the recipe stops before doing any work and names the command to run first.
`report-html` is the exception: it reads the merged report produced by
`merge-reports` but fails on the file itself, being given its path.

**Current option compatibility rules enforced:**

| Consumer recipe | Option | Requires producer elaborated with |
|---|---|---|
| `vcs-uvm-run` / `xcelium-uvm-run` / `questa-uvm-run` | `--trace-mode` (any except notrace) | `--trace-mode` gui/fast/compact |
| `vcs-uvm-run` | `--interactive-gui` | `--trace-mode gui` |
| `*-uvm-run` | `--tandem-enabled` | `--tandem-enabled` |
| `*-uvm-run` | `--stats` | `--stats` |
| `vcs-uvm-run` | `--sim-profile` | `--sim-profile` |
| `vcs-uvm-gui` | (always) | simulation run with `--trace-mode` gui/fast |
| `*-uvm-comp` gate modes | `--comp-mode gate_*` | `dc-shell-synth` outputs present |
| `vivado-fpga-build` / `quartus-fpga-build` | `--board` | `fpga-bootrom --board` (the same one) |
| `*-fpga-program` | `--board` | `*-fpga-build --board` (the same one) |
| `fpga-linux-boot` | `--board` | `vivado-fpga-program --board` (the same one) |

When adding a new recipe, follow this pattern:

1. Call `require_prerequisite()` early (before cleaning output directories)
   for every artifact the recipe consumes.
2. Call `write_manifest()` at the end, once artifacts are generated, passing
   all options that could affect downstream recipes.
3. If some of your options only work when the producer used specific options,
   add a `require_manifest_option()` check.

**Rule of thumb: no dedicated build directory, no manifest.** Recipes that do
not write to a dedicated output directory under `build/` do not write a
manifest. This covers:

- code quality tools (`black-python-formating`, `pylint-run`,
  `verible-rtl-formating`, `self-check`)
- recipes writing into the source tree (`hwconfig-forge` - its generated
  config package already carries a traceability header comment)
- external installers (`git-dependencies` - consumers check the installed
  tools directly with `require_prerequisite()`)
- testlist wrappers (`sw-compile-testlist`, `vcs-generator-run-testlist`,
  `uvm-run-testlist`) - each underlying unit recipe already writes a
  per-test manifest in its own output directory.

## Trying a recipe out

```bash
# The command and its options
./cook.py my-recipe --help

# Shell completion of the target names, which is a recipe bug when broken
./cook.py my-recipe -t <TAB>

# What it produces, in the directory the recipe reported writing to
cat build/<target>/<recipe>/cook_report.yml
```

The output directory of a target recipe is `build/<target>/<recipe>/`;
a recipe that is not target-specific writes to `build/<recipe>/`, and
`report.set_out_dir()` moves it when the recipe splits its output per
test or per run.

A recipe is expected to be re-runnable: running it twice in a row must
give the same result, the second run starting by cleaning its own output
directory. Check the failure paths too, they are the ones a user meets
first: a missing prerequisite, a missing configuration file, a tool
absent from the PATH.

`./cook.py full-regression --dry-run` lists what the pipeline would run
without running it, which is how a new job is checked before it costs a
licence.

## Before submitting

```bash
./cook.py black-python-formating   # formatting, rewrites in place
./cook.py pylint-run               # 10.00/10 required, 1200 lines per module
./cook.py self-check               # the tools the flows expect
```

`pylint-run` reads the files tracked by git at `HEAD`, not the working
tree: a new file is only linted once it is added, so add it before
trusting a passing run.

Comments explain a mechanism or a subtlety. What changed, why it changed
and what the alternatives were belong to the commit message; results of a
verification belong to the commit message too, not to a docstring.
