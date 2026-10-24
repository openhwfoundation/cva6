####################################
# SRAM macro PDN, restricted to M1-M4 (same layer usage as ASAP7 fakeram7)
#
# The abstract is written with `write_abstract_lef -bloat_occupied_layers`,
# which obstructs the whole macro on every layer holding a shape. Keeping
# the PDN (and pins) below M5 leaves M5-M7 routable over the macro at top level.
####################################
# global connections
####################################
add_global_connection -net {VDD} -inst_pattern {.*} -pin_pattern {^VDD$} -power
add_global_connection -net {VSS} -inst_pattern {.*} -pin_pattern {^VSS$} -ground
global_connect
####################################
# voltage domains
####################################
set_voltage_domain -name {CORE} -power {VDD} -ground {VSS}
####################################
# standard cell grid
####################################
# M4 straps are promoted to VDD/VSS pins, connected by CORE_macro_grid_1 in pdn.tcl
define_pdn_grid -name {top} -voltage_domains {CORE} -pins {M4}
add_pdn_stripe -grid {top} -layer {M1} -width {0.018} -pitch {0.54} -offset {0} -followpins
add_pdn_stripe -grid {top} -layer {M2} -width {0.018} -pitch {0.54} -offset {0} -followpins
# M2 and M4 are both horizontal: vertical M3 straps are needed to connect them
add_pdn_stripe -grid {top} -layer {M3} -width {0.09} -spacing {0.054} -pitch {5.4} -offset {0.300}
add_pdn_stripe -grid {top} -layer {M4} -width {0.12} -spacing {0.072} -pitch {5.4} -offset {0.513}
add_pdn_connect -grid {top} -layers {M1 M2}
add_pdn_connect -grid {top} -layers {M2 M3}
add_pdn_connect -grid {top} -layers {M3 M4}
