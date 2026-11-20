add wave -noupdate -group core /ariane_tb/dut/i_ariane/*

add wave -noupdate -group frontend /ariane_tb/dut/i_ariane/i_frontend/*
add wave -noupdate -group frontend -group ras /ariane_tb/dut/i_ariane/i_frontend/i_ras/*
add wave -noupdate -group frontend -group btb /ariane_tb/dut/i_ariane/i_frontend/i_btb/*
add wave -noupdate -group frontend -group bht /ariane_tb/dut/i_ariane/i_frontend/i_bht/*
# add wave -noupdate -group frontend -group instr_scan /ariane_tb/dut/i_ariane/i_frontend/*/i_instr_scan/*
# add wave -noupdate -group frontend -group fetch_fifo /ariane_tb/dut/i_ariane/i_frontend/i_fetch_fifo/*

add wave -noupdate -group id_stage -group decoder /ariane_tb/dut/i_ariane/id_stage_i/decoder_i/*
add wave -noupdate -group id_stage -group compressed_decoder /ariane_tb/dut/i_ariane/id_stage_i/compressed_decoder_i/*
add wave -noupdate -group id_stage -group instr_realigner /ariane_tb/dut/i_ariane/id_stage_i/instr_realigner_i/*
add wave -noupdate -group id_stage /ariane_tb/dut/i_ariane/id_stage_i/*

add wave -noupdate -group issue_stage -group scoreboard /ariane_tb/dut/i_ariane/issue_stage_i/i_scoreboard/*
add wave -noupdate -group issue_stage -group issue_read_operands /ariane_tb/dut/i_ariane/issue_stage_i/i_issue_read_operands/*
add wave -noupdate -group issue_stage -group rename /ariane_tb/dut/i_ariane/issue_stage_i/i_re_name/*
add wave -noupdate -group issue_stage /ariane_tb/dut/i_ariane/issue_stage_i/*

add wave -noupdate -group ex_stage -group alu /ariane_tb/dut/i_ariane/ex_stage_i/alu_i/*
add wave -noupdate -group ex_stage -group mult /ariane_tb/dut/i_ariane/ex_stage_i/i_mult/*
add wave -noupdate -group ex_stage -group mult -group mul /ariane_tb/dut/i_ariane/ex_stage_i/i_mult/i_mul/*
add wave -noupdate -group ex_stage -group mult -group div /ariane_tb/dut/i_ariane/ex_stage_i/i_mult/i_div/*
add wave -noupdate -group ex_stage -group fpu /ariane_tb/dut/i_ariane/ex_stage_i/fpu_gen/fpu_i/*
add wave -noupdate -group ex_stage -group fpu -group fpnew /ariane_tb/dut/i_ariane/ex_stage_i/fpu_gen/fpu_i/fpnew_top_i/i_fpnew/*

add wave -noupdate -group ex_stage -group lsu /ariane_tb/dut/i_ariane/ex_stage_i/lsu_i/*
add wave -noupdate -group ex_stage -group lsu  -group lsu_bypass /ariane_tb/dut/i_ariane/ex_stage_i/lsu_i/lsu_bypass_i/*
add wave -noupdate -group ex_stage -group lsu -group mmu /ariane_tb/dut/i_ariane/ex_stage_i/lsu_i/i_mmu/*
add wave -noupdate -group ex_stage -group lsu -group mmu -group itlb /ariane_tb/dut/i_ariane/ex_stage_i/lsu_i/i_mmu/i_itlb/*
add wave -noupdate -group ex_stage -group lsu -group mmu -group dtlb /ariane_tb/dut/i_ariane/ex_stage_i/lsu_i/i_mmu/i_dtlb/*
add wave -noupdate -group ex_stage -group lsu -group mmu -group ptw /ariane_tb/dut/i_ariane/ex_stage_i/lsu_i/i_mmu/i_ptw/*

add wave -noupdate -group ex_stage -group lsu -group store_unit /ariane_tb/dut/i_ariane/ex_stage_i/lsu_i/i_store_unit/*
add wave -noupdate -group ex_stage -group lsu -group store_unit -group store_buffer /ariane_tb/dut/i_ariane/ex_stage_i/lsu_i/i_store_unit/store_buffer_i/*

add wave -noupdate -group ex_stage -group lsu -group load_unit /ariane_tb/dut/i_ariane/ex_stage_i/lsu_i/i_load_unit/*
add wave -noupdate -group ex_stage -group lsu -group lsu_arbiter /ariane_tb/dut/i_ariane/ex_stage_i/lsu_i/i_lsu_arbiter/*

add wave -noupdate -group ex_stage -group branch_unit /ariane_tb/dut/i_ariane/ex_stage_i/branch_unit_i/*

add wave -noupdate -group ex_stage -group csr_buffer /ariane_tb/dut/i_ariane/ex_stage_i/csr_buffer_i/*
add wave -noupdate -group ex_stage /ariane_tb/dut/i_ariane/ex_stage_i/*

add wave -noupdate -group commit_stage /ariane_tb/dut/i_ariane/commit_stage_i/*

add wave -noupdate -group csr_file /ariane_tb/dut/i_ariane/csr_regfile_i/*

add wave -noupdate -group controller /ariane_tb/dut/i_ariane/controller_i/*

add wave -noupdate -group perf_counters /ariane_tb/dut/i_ariane/i_perf_counters/*

add wave -noupdate -group dm_top /ariane_tb/dut/i_dm_top/*
add wave -noupdate -group dm_top -group dm_csrs /ariane_tb/dut/i_dm_top/i_dm_csrs/*
add wave -noupdate -group dm_top -group dm_mem /ariane_tb/dut/i_dm_top/i_dm_mem/*

add wave -noupdate -group bootrom /ariane_tb/dut/i_bootrom/*

add wave -noupdate -group tracer_if /ariane_tb/dut/i_ariane/instr_tracer_i/tracer_if/*

add wave -group SimJTAG /ariane_tb/dut/i_SimJTAG/*

add wave -group dmi_jtag /ariane_tb/dut/i_dmi_jtag/*
add wave -group dmi_jtag -group dmi_jtag_tap /ariane_tb/dut/i_dmi_jtag/i_dmi_jtag_tap/*
add wave -group dmi_jtag -group dmi_cdc /ariane_tb/dut/i_dmi_jtag/i_dmi_cdc/*