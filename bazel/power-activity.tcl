####################################
# Switching activity used by report_power for the power metric of the PD dashboard
# Sourced as PRE_FLOORPLAN_TCL and PRE_GLOBAL_ROUTE_TCL, after the design and
# its SDC are loaded and before the stage reports its metrics.
#
# Every net toggles 0.1 times per clock period and is high half of the time.
# Clock nets keep the activity of their SDC clock (2 toggles per period).
#
# Why not OpenSTA's default vectorless propagation:
# without annotated activities, OpenSTA seeds the inputs with this same 0.1 and
# propagates it through the logic and across the flops, iterating until it
# converges, for 50 passes at most. On CVA6 it never converges, and on some
# netlists it diverges. The power then depends on where the iterations stop,
# and jumps between netlists far more than their difference in area and cells.
#
# What the metric tracks with a fixed activity:
# a deterministic "switched capacitance" power that only moves with the design:
# number and size of the cells, wire capacitance once placed, clock tree after
# CTS, and leakage. It does not reflect how often each part of the core really
# switches: a commit changing that without changing the logic leaves the metric
# unchanged. The dcache SRAM macros still count as 0 W (timing-only .lib).
#
# Long-term alternative, a project of its own: real activity from simulation.
# Run a benchmark on the Verilator testharness, dump a SAIF or VCD file and
# annotate the flops with it (read_saif / read_vcd -scope): Yosys keeps the
# register names in the netlist, up to a name mapping. OpenSTA then only
# propagates through combinational logic, with no loop and no divergence.
####################################
set_power_activity -global -activity 0.1 -duty 0.5
