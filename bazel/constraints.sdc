# CVA6 cv32a60x: single clock, 500 MHz on ASAP7
set clk_name clk_i
set clk_port_name clk_i
set clk_period 4000

if {[llength [all_registers]] > 0} {
  # Parts of this constraint file are inspired from:
  #   https://github.com/The-OpenROAD-Project/OpenROAD-flow-scripts/blob/master/flow/platforms/asap7/constraints.sdc
  #   source $env(PLATFORM_DIR)/constraints.sdc
  set non_clk_inputs [all_inputs -no_clocks]
  set outputs        [all_outputs]
  set registers      [all_registers]

  set clk_port [get_ports $clk_port_name]
  create_clock -period $clk_period -waveform [list 0 [expr $clk_period / 2]] -name $clk_name $clk_port

  set_input_delay -max -clock [get_clocks ${clk_name}] [expr ${clk_period}*.3] $non_clk_inputs
  set_output_delay -max -clock [get_clocks ${clk_name}] [expr ${clk_period}*.3] $outputs

  group_path -name in2reg -from $non_clk_inputs -to $registers
  group_path -name reg2out -from $registers -to $outputs
  group_path -name reg2reg -from $registers -to $registers
  group_path -name in2out -from $non_clk_inputs -to $outputs
}