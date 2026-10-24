####################################
# Yosys hook run right after elaboration (SYNTH_CANONICALIZE_TCL)
#
# Removes the RVFI verification port of the core (rvfi_probes_o). It only
# feeds testbenches and is left unconnected in a real SoC, but as the top level
# of this flow it becomes ~80% of the IO pins. The logic driving it then becomes
# dead and is removed by synthesis (inside kept modules thanks to SYNTH_OPT_HIER).
# Same as the ORFS asap7/cva6 reference design.
####################################
# Fail if the port is renamed upstream, instead of silently keeping it
select -assert-min 1 cva6/o:rvfi_probes_o*
# Only drop the port attribute: the wire stays as an internal net
delete -port cva6/o:rvfi_probes_o*
