## ASIC Synthesis

Synthesis runs with `cook.py`, on a technology declared in `$CONFIG_DIR/techno.yml`:
```
./cook.py dc-shell-synth -t cv32a60x --techno MyTechno --period 10.0
```
Reports are under `build/<target>/synthesis/`. A technology independent synthesis needs no PDK:
```
./cook.py dc-shell-synth -t cv32a60x --gtech
```

## ASIC Gate Simulation

The netlist is simulated on the UVM testbench, see [Synthesis, then the netlist](../flows/QUICKSTART.md#synthesis-then-the-netlist):
```
./cook.py hello-world -t cv32a60x -c gcc-15
./cook.py vcs-uvm-comp -t cv32a60x --comp-mode gate_wc_timing
./cook.py vcs-uvm-run -t cv32a60x -n hello-world --comp-mode gate_wc_timing
```
