# Copyright 2026 Thales France
#
# Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
# You may obtain a copy of the License at https://solderpad.org/licenses/
#
# Original Author: Yannick Casamatta (yannick.casamatta@thalesgroup.com)

# Technology independent synthesis of a target, run by
# `cook.py dc-shell-synth --gtech`.
#
# The design is mapped on the GTECH generic cells and the DesignWare
# operators that ship with dc_shell, so no PDK is needed. The GTECH cells
# have no area: the figures are cell and register counts, per hierarchy.
# The hierarchy is kept (no ungroup, no flatten) for those counts to be
# reported per block.
#
# Read from the environment, set by the recipe:
#   CVA6_REPO_DIR   repository root
#   HPDCACHE_DIR    HPDcache submodule
#   TOP_ELABORATE   design to elaborate
#   SYNTH_DIR       output directory (build/<target>/synthesis)
#   FLIST           analyze commands of the target files
#   DC_CORES        cores dc_shell may use

set repo     $env(CVA6_REPO_DIR)
set hpdcache $env(HPDCACHE_DIR)
set top      $env(TOP_ELABORATE)
set out      $env(SYNTH_DIR)

set_host_options -max_cores $env(DC_CORES)

# The include directories of the RTL: +incdir+ entries are not part of
# the file list the recipe passes
set_app_var search_path [list . \
    $repo/core/include \
    $repo/common/local/util \
    $repo/vendor/pulp-platform/common_cells/include \
    $repo/vendor/pulp-platform/common_cells/src \
    $repo/vendor/pulp-platform/axi/include \
    $repo/vendor/pulp-platform/obi/include \
    $hpdcache/rtl/include \
    $hpdcache/rtl/src/utils/ecc \
    {*}$search_path]

set_app_var target_library    gtech.db
set_app_var synthetic_library dw_foundation.sldb
set_app_var link_library      [list * gtech.db dw_foundation.sldb]

# No formal verification follows: without this, the SVF guidance that
# dc_shell records by default makes compile stop at once (GHM-006)
set_svf -off
set_vsdc -off

file mkdir $out/work $out/reports $out/netlist
define_design_lib ariane_lib -path $out/work

# ----------------------------------------------------------------------
# Read and elaborate
# ----------------------------------------------------------------------
source $env(FLIST)

if {![elaborate $top -library ariane_lib]} {
    puts "Error: elaboration of $top failed"
    exit 1
}
current_design $top
if {![link]} {
    puts "Error: link of $top failed"
    exit 1
}
check_design -summary > $out/reports/check_design.rpt

# ----------------------------------------------------------------------
# Map on GTECH, hierarchy kept
# ----------------------------------------------------------------------
uniquify
compile

# ----------------------------------------------------------------------
# Reports
# ----------------------------------------------------------------------
report_area -hierarchy > $out/reports/synth_area.rpt
report_reference -hierarchy > $out/reports/synth_reference.rpt
check_design > $out/reports/check_design_full.rpt

# One line per figure, parsed by the recipe
puts "GTECH-CELLS [sizeof_collection [get_cells -hierarchical * -filter is_hierarchical==false]]"
puts "GTECH-REGISTERS [sizeof_collection [all_registers]]"
puts "GTECH-LATCHES [sizeof_collection [all_registers -level_sensitive]]"

write -format verilog -hierarchy -output $out/netlist/synth.v
exit 0
