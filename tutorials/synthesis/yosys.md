# Synthesis with Yosys

Purpose: estimate the size of a target on generic cells, with no licence.

**Prerequisites:** [getting_started.md](../getting_started.md), Yosys with
its slang plugin in the `PATH` (`setenv.sh`).

## Run

```bash
./cook.py yosys-synth -t cv32a60x
```

The only option is the target. The slang plugin reads the SystemVerilog
of `config/target/<t>/Flist.cva6_synth`, from the example top of the
target, then `synth` maps the design on the internal cells of Yosys
(`$_AND_`, `$_MUX_`, `$_DFF_`...). These cells have no area: the results
are cell, register and latch counts, and the cells of each block.

Output in `build/cv32a60x/synthesis_yosys/`: the script `synth.ys`, the
statistics `stat.txt`, the log `yosys.log` and the `cook_report.yml`.

## Verdict

- A latch fails the run: the RTL is meant to have none.
- The cell and register counts are compared with `yosys_cells` and
  `yosys_registers` of `config/target/<t>/expected_values.yml`, 5 %
  tolerance.

The CI runs it on every target.

## A real PDK

Today Yosys runs on its generic cells only. Mapping on a PDK library is
not available in the recipe yet. For an area in gates, a netlist and an
SDF, use Design Compiler: [dc_shell.md](dc_shell.md#on-your-pdk).

## See also

- [README.md](README.md): the synthesis flows compared
- [dc_shell.md](dc_shell.md): Design Compiler, GTECH or PDK
