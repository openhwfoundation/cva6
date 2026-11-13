# Getting started

For everybody: from a fresh clone to a first `cook.py` command. The other
[tutorials](README.md) assume this page is done.

`cook.py` is the single entry point of the CVA6 flows. Each command is a
*recipe*. The options of every recipe are in the reference,
[flows/README.md](../flows/README.md).

**Prerequisites:** a Linux workstation with Git and Python 3.12 or later
(or `uv`, which downloads it).

## 1. Clone the repository and its submodules

```bash
git clone https://github.com/openhwgroup/cva6.git
cd cva6
git submodule update --init --recursive
```

## 2. Create the Python environment

`cook.py` needs Python 3.12 or later and the packages of
`flows/requirements.txt`, in a virtual environment.
[uv](https://docs.astral.sh/uv/) downloads the interpreter for you:

```bash
pip3 install --user uv
uv venv -p 3.12 .venv && . .venv/bin/activate
uv pip install -r flows/requirements.txt
```

With a Python 3.12 already installed, `python3.12 -m venv .venv` then
`pip3 install -r flows/requirements.txt` do the same. Details:
[Python Environment](../flows/README.md#python-environment).

## 3. Patch the submodules and clone the test suites

```bash
./cook.py git-dependencies
```

This step is **mandatory**, after the clone and after every `git pull`.
It does two things:

- it applies the patches of the submodules listed under `submodule_patches`
  in [flows/config/dependencies.yml](../flows/config/dependencies.yml).
  The patch files are in `verif/patches/`; today they patch
  `verif/core-v-verif` and the HPDcache (`core/cache_subsystem/hpdcache`);
- it clones the external test suites (riscv-tests, riscv-arch-test,
  riscv-compliance) at a pinned commit.

`cook.py` refuses to run any other recipe while a submodule patch is not
applied, and prints the missing patches. Running it again is harmless.
The proxy kernel and Zephyr are cloned by the same recipe:
`./cook.py git-dependencies --repo riscv-pk` or `--repo zephyr`. See
[`git-dependencies`](../flows/README.md#git-dependencies).

## 4. Point cook.py at your tools

The configuration lives in the directory named by `$CONFIG_DIR` (default:
`flows/config/`):

| File | Content |
|---|---|
| `setenv.sh` | puts the tools in `PATH` (simulators, Verilator, Verible, Yosys...) and activates the virtual environment |
| `compiler.yml` | the RISC-V toolchains, by name (`gcc-15`, `llvm-22`, `zephyr-sdk`...): the `-c` option of the recipes |
| `techno.yml` | the technology libraries for synthesis (optional) |

The files of `flows/config/` are examples with placeholder paths. Copy
them to a directory of your own, edit them, then, from the root of the
checkout:

```bash
export CONFIG_DIR=/path/to/your/config
source $CONFIG_DIR/setenv.sh
```

The format of each file: [cook.py configuration](../flows/README.md#cookpy-configuration).
To build a RISC-V toolchain, see
[util/toolchain-builder/README.md](../util/toolchain-builder/README.md).

## 5. Install Spike and Verilator

Spike is the reference model of the tandem comparison. The TestHarness
also needs its libraries. It is built from `verif/core-v-verif` and
installed in `tools/spike`:

```bash
sudo apt-get install cmake help2man device-tree-compiler   # Debian based
export NUM_JOBS=8
./verif/regress/install-spike.sh
```

Verilator v5.050 is needed for the TestHarness and for `rtl-lint`. The
script installs it in `tools/verilator-v5.050`. Point
`VERILATOR_INSTALL_DIR` of `setenv.sh` at it:

```bash
./verif/regress/install-verilator.sh
```

## 6. Check the setup

```bash
./cook.py self-check
```

It lists the tools found in `PATH`, the Spike install, the submodules, the
test suites and the configuration files. A missing optional tool is only a
warning. See [`self-check`](../flows/README.md#self-check).

Shell completion of the recipes, options and target names:

```bash
./cook.py --install-completion
./cook.py --help                 # all recipes
./cook.py <recipe> --help        # options of one recipe
```

Always run `cook.py` from the root of the checkout. It refuses any other
directory.

## 7. A first command

```bash
./cook.py hello-world -t cv32a60x -c gcc-15
```

`-t` is the target, a directory of `config/target/` (see
[config/README.md](../config/README.md)). `-c` is a toolchain name of
your `compiler.yml`.

## Where the results go

Every recipe writes in its own directory under `build/<target>/`, or
under `build/<recipe>/` when it has no target. For example:

| Recipe | Directory |
|---|---|
| `hello-world`, `sw-compile` | `build/<target>/compile/<test>/` |
| `vcs-uvm-comp` | `build/<target>/elab/sim_rtl/` |
| `vcs-uvm-run` | `build/<target>/simulation/sim_rtl/<test>/` |

The whole tree: [Build directory organization](../flows/CONTRIBUTING.md#build-directory-organization).

Each of these directories holds a `cook_report.yml`: the verdict of the
recipe. Read it rather than the console:

- `status`: `pass` or `fail`;
- `fail_kind`: `environment` when a tool, a licence or a prerequisite is
  missing (fix the setup), `test` when the design or the program is at
  fault;
- `metrics` and `kpi`: what was measured (cycles, area, test results).

A failing recipe exits with code 1, but only the report says what failed
and where. The fields:
[What every recipe leaves behind](../flows/CONTINUOUS_INTEGRATION.md#what-every-recipe-leaves-behind).

## See also

- [Tutorials index](README.md): pick the next page by use
- [simulation/testharness.md](simulation/testharness.md): a first simulation without licence
- [flows/QUICKSTART.md](../flows/QUICKSTART.md): worked sequences to copy
- [flows/README.md](../flows/README.md): the reference of every recipe
- [config/README.md](../config/README.md): the targets
