## Common Ariane XDCs

create_clock -period 100.000 -name tck -waveform {0.000 50.000} [get_ports tck]
set_input_jitter tck 1.000

# minimize routing delay
set_input_delay  -clock tck -clock_fall 5 [get_ports tdi    ]
set_input_delay  -clock tck -clock_fall 5 [get_ports tms    ]
set_output_delay -clock tck             5 [get_ports tdo    ]
set_false_path   -from                    [get_ports trst_n ]


set_max_delay -datapath_only -from [get_pins i_dmi_jtag/i_dmi_cdc/i_cdc_resp/i_src/data_src_q_reg*/C] -to [get_pins i_dmi_jtag/i_dmi_cdc/i_cdc_resp/i_dst/data_dst_q_reg*/D] 20.000
set_max_delay -datapath_only -from [get_pins i_dmi_jtag/i_dmi_cdc/i_cdc_resp/i_src/req_src_q_reg/C] -to [get_pins i_dmi_jtag/i_dmi_cdc/i_cdc_resp/i_dst/i_sync/reg_q_reg[*]/D] 20.000
set_max_delay -datapath_only -from [get_pins i_dmi_jtag/i_dmi_cdc/i_cdc_req/i_dst/ack_dst_q_reg/C] -to [get_pins i_dmi_jtag/i_dmi_cdc/i_cdc_req/i_src/i_sync/reg_q_reg[*]/D] 20.000

# set multicycle path on reset, on the FPGA we do not care about the reset anyway
set_multicycle_path -from [get_pins {i_rstgen_main/i_rstgen_bypass/synch_regs_q_reg[3]/C}] 4
set_multicycle_path -hold -from [get_pins {i_rstgen_main/i_rstgen_bypass/synch_regs_q_reg[3]/C}] 3

create_clock -period 16.667 -name prog_clko_pin -waveform {0.000 8.333} [get_ports prog_clko]

set_input_delay -clock [get_clocks prog_clko_pin] -min -add_delay 1.000 [get_ports {prog_d[*]}]
set_input_delay -clock [get_clocks prog_clko_pin] -max -add_delay 7.150 [get_ports {prog_d[*]}]
set_input_delay -clock [get_clocks prog_clko_pin] -min -add_delay 1.000 [get_ports prog_rxen]
set_input_delay -clock [get_clocks prog_clko_pin] -max -add_delay 7.150 [get_ports prog_rxen]
set_input_delay -clock [get_clocks prog_clko_pin] -min -add_delay 1.000 [get_ports prog_txen]
set_input_delay -clock [get_clocks prog_clko_pin] -max -add_delay 7.150 [get_ports prog_txen]
set_output_delay -clock [get_clocks prog_clko_pin] -min -add_delay 0.400 [get_ports {prog_d[*]}]
set_output_delay -clock [get_clocks prog_clko_pin] -max -add_delay 8.600 [get_ports {prog_d[*]}]
set_output_delay -clock [get_clocks prog_clko_pin] -min -add_delay 0.400 [get_ports prog_oen]
set_output_delay -clock [get_clocks prog_clko_pin] -max -add_delay 8.600 [get_ports prog_oen]
set_output_delay -clock [get_clocks prog_clko_pin] -min -add_delay 0.400 [get_ports prog_rdn]
set_output_delay -clock [get_clocks prog_clko_pin] -max -add_delay 8.600 [get_ports prog_rdn]
set_output_delay -clock [get_clocks prog_clko_pin] -min -add_delay 0.400 [get_ports prog_wrn]
set_output_delay -clock [get_clocks prog_clko_pin] -max -add_delay 8.600 [get_ports prog_wrn]

set_property IOB TRUE [get_ports {prog_d[*]}]
set_property IOB TRUE [get_ports prog_rxen]
set_property IOB TRUE [get_ports prog_txen]

set_property DONT_TOUCH true [get_cells i_cva6_rvfi]
set_property DONT_TOUCH true [get_cells i_iti]
set_property DONT_TOUCH true [get_cells i_encapsulator]