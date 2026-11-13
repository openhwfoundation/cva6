# Waveforms and debug

Purpose: dump waveforms, open a GUI and replay a failing run, on each
simulator of each testbench.

**Prerequisites:** a first run on your testbench:
[uvm_testbench.md](uvm_testbench.md) or [testharness.md](testharness.md).

## The rule: elaborate and run with the same trace mode

The waveform dump is chosen by `--trace-mode`: `notrace` (default),
`compact`, `fast` or `gui`. The elaboration must be done with the same
mode as the run: the run refuses a trace mode its elaboration was not
built for, and prints the command to rebuild it.

```bash
./cook.py vcs-uvm-comp -t cv32a60x --trace-mode gui
./cook.py vcs-uvm-run -t cv32a60x -n hello-world --trace-mode gui
```

The files land in the run directory,
`build/<t>/simulation/<comp_mode dir>/<run>/`.

## UVM testbench

### VCS

| `--trace-mode` | File |
|---|---|
| `gui`, `fast` | `trace.fsdb` |
| `compact` | `trace.vpd` |

```bash
./cook.py vcs-uvm-gui -t cv32a60x -n hello-world        # Verdi on trace.fsdb
```

`vcs-uvm-gui` needs a run made with `--trace-mode gui` or `fast`.
`--session` reloads a Verdi session file you saved.
`vcs-uvm-run --interactive-gui` starts the simulation inside Verdi; it
needs an elaboration with `--trace-mode gui`. See
[`vcs-uvm-gui`](../../flows/README.md#vcs-uvm-gui).

### Questa

Every trace mode other than `notrace` writes `trace.wlf` (`compact`
compresses it). `--trace-mode gui` or `--interactive-gui` opens the Questa
GUI. There is no `questa-uvm-gui` recipe: open the WLF file with `vsim`.

### Xcelium

`fast` and `compact` write an SHM database, `trace.shm` (`compact`
compresses it). `--trace-mode gui` or `--interactive-gui` opens the GUI.
Not verified, as the other Xcelium recipes.

## TestHarness

### Verilator

`--trace-mode fast` writes `verilator.vcd`, `compact` writes
`verilator.fst`, in the run directory. `gui` and `--interactive-gui` are
refused: open the file with a viewer such as GTKWave.

### VCS, Questa, Xcelium

On these simulators, a trace mode other than `notrace` only builds the
harness with debug access (signals kept visible). The run itself writes
no waveform file. Use the trace mode on the elaboration and the run, then
attach the tools of the simulator as you usually do.

## Other debug options

On the UVM run recipes (`<sim>-uvm-run`, `uvm-run-testlist`):

- `--uvm-verbosity`: UVM message level;
- `--uvm-seed`: replays a seed (recorded in the report of each run);
- `--run-name`: keeps two runs of one test apart;
- `--cycle-timeout` (VCS): stops the run after that many cycles;
- `--sim-timeout`: wall clock limit, in seconds;
- `--run_opts`: extra plusargs.

On both testbenches, `trace_rvfi_hart_00.dasm` in the run directory lists
every retired instruction. `spike-run` runs a compiled test on Spike
alone, to compare with the reference model. Every option:
[`vcs-uvm-run`](../../flows/README.md#vcs-uvm-run).

## See also

- [flows/README.md, Waveform Generation](../../flows/README.md#waveform-generation)
- [flows/README.md, log files](../../flows/README.md#simulation-log-files-description)
- [generated_tests.md](generated_tests.md#seeds-reproduce-a-failing-test): replay a random test
- [corev_apu/instr_tracing/README.md](../../corev_apu/instr_tracing/README.md): instruction tracing
