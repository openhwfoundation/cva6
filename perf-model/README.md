# CVA6 cycle-accurate performance model

This repository contains a cycle-accurate performance model of CVA6 control-path.

It was developed to explore microarchitecture changes in CVA6 before implementing them.

To cite this model, please head to the end of this document.


## Getting started

### Generate an RVFI trace

Run a simulation with cook.py, for instance CoreMark on cv32a65x:

```bash
./cook.py vcs-uvm-comp -t cv32a65x
./cook.py coremark -t cv32a65x -c gcc-15
./cook.py vcs-uvm-run -t cv32a65x -n coremark --tb-performance-mode
```

The disassembled RVFI trace is `build/<target>/simulation/sim_rtl/<test-name>/spike_dasm.log`.


### Running the model

```bash
python3 perf-model/model.py build/<target>/simulation/sim_rtl/<test-name>/spike_dasm.log
```

The annotated trace is generated in an `annotated.log` file in the current directory (`--output` to change it).

It prints a lot of debug information so that you can see all the events (note: it slows down model execution).
`-q` disables these prints.

At the end of the simulation, the model prints statistics with the `print_stats` call in the `main` function.
With `--timed`, these statistics are computed on the timed part only, which is filtered with the `filter_timed_part` function: the instructions between the two `csrr minstret`.
Feel free to modify the `filter_timed_part` function to suit your needs.


### Exploring design space

The parameters of the model are command line options (`python3 perf-model/model.py --help`):

| Option            | Default     | Description                             |
| :---              | :---        | :---                                    |
| `--issue`         | 2           | Issue width                             |
| `--commit`        | 2           | Commit width                            |
| `--sb-len`        | 8           | Scoreboard entries                      |
| `--fetch-size`    | 4 * issue   | Instruction queue fetch size, in bytes  |
| `--ras-depth`     | 2           | Return address stack depth              |
| `--bht-entries`   | 128         | Branch history table entries            |
| `--no-forwarding` |             | Disable operand forwarding              |
| `--no-renaming`   |             | Disable register renaming               |

For instance, the timed part of CoreMark with one commit port:

```bash
python3 perf-model/model.py -q --timed --commit 1 build/cv32a65x/simulation/sim_rtl/coremark/spike_dasm.log
```

Generic parameters are available in `Model.__init__`.
You can add new parameters to explore here.

To perform exploration, run the model in a loop, like `issue_commit_graph` does.
The `display_scores` function is meant to print a 3D plot if you have `matplotlib`.
`issue_commit_graph` prints the scores so that you can store it and display the figure without re-running the model.


## Comparing the model and the RTL

### Cycle number in the RVFI trace

`cycle_diff.py` and `profile.py` need the cycle number of each instruction.
The model does not use it; it is used to compare the model and CVA6.

`corev_apu/tb/rvfi_tracer.sv` writes it before each instruction
(`<cycle> | core   0: ...`). The `core   0: ... @<cycle>` form written by
`annotated.log` is read as well.


### Calculate instruction duration

Run `cycle_diff.py` for each script.

```bash
python3 perf-model/cycle_diff.py annotated.log
mv traceout.log model.log
python3 perf-model/cycle_diff.py build/<target>/simulation/sim_rtl/<test-name>/spike_dasm.log
```

Note: the `cycles_diff.py` script filters the "timed" part of the program.
To do this, it tries to find `csrr minstret` instructions.
Feel free to modify the script to suit your needs.


### List the differences

```bash
diff -y traceout.log model.log | less
```

## RVFI-based Flamegraph Profiler

This tool generates execution profile visualizations and performance metrics from CVA6 RISC-V trace logs.
The profiler processes RVFI traces with cycle number (see Cycle number in the RVFI trace) and produces two complementary flamegraph outputs: a standard cycle-attribution and an instruction-level breakdown variant.

```bash
python perf-model/profile.py dumpfile.dump traceout.log svg_name.svg
```

**Parameters:**
- `dumpfile.dump`: section headers of the ELF (`riscv-none-elf-objdump -h <test-name>.elf`). One function is one `.text.<name>` section, so the test must be compiled with `-ffunction-sections`, as CoreMark is.
- `traceout.log`: RVFI execution trace file from CVA6 simulation
- `svg_name.svg`: Output flamegraph basename (generates `svg_name.svg` and `svg_name_with_ins.svg`)

It needs the `flameprof` Python package (`pip install flameprof`).

**Outputs:**
- `svg_name.svg`: Cycle-based flamegraph showing execution hotspots by cycle attribution
- `svg_name_with_ins.svg`: Instruction-level flamegraph with per-instruction cost breakdown


## Files

| Name            | Description                                              |
| :---            | :---                                                     |
| `cycle_diff.py` | Calculates duration of each instruction in an RVFI trace |
| `isa.py`        | Module to create Python objects from RISC-V instructions |
| `model.py`      | The CVA6 performance model                               |
| `profile.py`    | RVFI-based flamegraph profiler                           |


## Citing

```bibtex
@inproceedings{cf24,
   author = {Allart, C\^{o}me and Coulon, Jean-Roch and Sintzoff, Andr\'{e} and Potin, Olivier and Rigaud, Jean-Baptiste},
   title = {Using a Performance Model to Implement a Superscalar CVA6},
   year = {2024},
   isbn = {9798400704925},
   publisher = {Association for Computing Machinery},
   url = {https://doi.org/10.1145/3637543.3652871},
   doi = {10.1145/3637543.3652871},
   abstract = {A performance model of CVA6 RISC-V processor is built to evaluate performance-related modifications before implementing them in RTL. Its accuracy is 99.2\% on CoreMark. This model is used to evaluate a superscalar feature for CVA6. During design phase, the model helped detecting and fixing performance bugs. The superscalar feature resulted in a CVA6 performance improvement of 40\% on CoreMark.},
   booktitle = {Proceedings of the 21st ACM International Conference on Computing Frontiers: Workshops and Special Sessions},
   pages = {43–46},
   numpages = {4},
   keywords = {CVA6, Cycle-Based Model, Multi-Issue, Performance, RISC-V, Superscalar},
   location = {Ischia, Italy},
   series = {CF '24 Companion}
}
```
