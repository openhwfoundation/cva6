# Benchmarks

Purpose: measure the cycles of CoreMark and Dhrystone on a target, and
check them against its baseline.

**Prerequisites:** [uvm_testbench.md](uvm_testbench.md) (a UVM
elaboration on VCS; the CI measures with VCS).

```bash
./cook.py coremark -t cv32a65x -c gcc-15
./cook.py dhrystone -t cv32a65x -c gcc-15
./cook.py vcs-uvm-comp -t cv32a65x --stats
./cook.py vcs-uvm-run -t cv32a65x -n coremark --stats --tb-performance-mode
./cook.py vcs-uvm-run -t cv32a65x -n dhrystone --stats --tb-performance-mode
```

- `coremark` and `dhrystone` compile the benchmark for the target.
- `--tb-performance-mode` makes the memory of the testbench answer
  without stalls, so the count measures the pipeline alone.
- `--stats` enables the RTL performance tracer; it must be given to the
  elaboration too.

The report gives the cycles of the measured iteration and the scores per
MHz. The cycles are compared with the `coremark_cycle` and
`dhrystone_cycle` keys of `config/target/<t>/expected_values.yml`: any
difference fails the run. A change that moves them on purpose updates
the keys in the same commit
([developer/ci_checks.md](../developer/ci_checks.md#baselines-of-performance-and-area)).

## See also

- [flows/README.md, `coremark`](../../flows/README.md#coremark),
  [`dhrystone`](../../flows/README.md#dhrystone)
- [flows/README.md, Reports](../../flows/README.md#reports)
