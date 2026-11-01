// mcontrol6 compares the load address (unsigned) against tdata2.
module trigger_match_ge_lt_test;
  function automatic config_pkg::cva6_cfg_t test_config();
    config_pkg::cva6_cfg_t cfg;
    cfg = build_config_pkg::build_config(cva6_config_pkg::cva6_cfg);
    cfg.Sdtrig = 1;
    cfg.SdtrigMcontrol6 = 1;
    cfg.SdtrigMcontrol6LoadAddr = 1;
    cfg.SdtrigNrTriggers = 2;
    cfg.SdtrigSupportedActions = 2'b11;
    cfg.SdtrigSupportedMatch = 10'b11_1111_1111;
    return cfg;
  endfunction

  localparam config_pkg::cva6_cfg_t TestCfg = test_config();
  typedef struct packed {
    logic valid;
    logic [63:0] cause, tval, tval2;
    logic [31:0] tinst;
    logic gva, timing;
  } exception_t;

  logic clk = 0;
  logic rst_n = 0;
  logic [63:0] tdata1_i = 0, tdata2_i = 0;
  logic tdata1_we = 0, tdata2_we = 0;
  logic lsu_valid = 0;
  logic [63:0] lsu_vaddr = 0;
  logic trigger_cancel;
  int failures = 0;
  always #5 clk = !clk;

  trigger_module #(.CVA6Cfg(TestCfg), .exception_t(exception_t)) dut (
      .clk_i(clk), .rst_ni(rst_n), .commit_ack_i('0), .ex_i('0),
      .priv_lvl_i(riscv::PRIV_LVL_M), .v_i(1'b0), .debug_mode_i(1'b0),
      .mret_i(1'b0), .sret_i(1'b0), .instr_count_d('0), .instr_count_q('0),
      .sdtrig_lsu_inputs_vaddr_i(lsu_vaddr), .sdtrig_lsu_inputs_data_i('0),
      .sdtrig_lsu_inputs_fu_i(1'b0), .sdtrig_lsu_inputs_valid_i(lsu_valid),
      .sdtrig_load_data_i('0), .sdtrig_load_valid_i(1'b0), .scontext_i('0),
      .tdata1_i(tdata1_i), .tdata2_i(tdata2_i), .tdata3_i('0),
      .tselect_i('0), .tselect_we(1'b0), .tdata1_we(tdata1_we),
      .tdata2_we(tdata2_we), .tdata3_we(1'b0), .tselect_o(),
      .tdata1_o(), .tdata2_o(), .tdata3_o(), .flush_o(),
      .mepc_i('0), .mcause_i('0), .mtval_i('0),
      .etrigger_context_saved_valid_o(), .etrigger_context_mepc_o(),
      .etrigger_context_mcause_o(), .etrigger_context_mtval_o(),
      .fetch_sdtrig_pc_i('0), .fetch_sdtrig_instr_i('0),
      .sdtrig_decoder_action_o(), .sdtrig_load_data_action_o(),
      .sdtrig_load_cancel_o(trigger_cancel), .sdtrig_load_action_o(),
      .sdtrig_store_stall_o(), .sdtrig_store_action_o(),
      .sdtrig_commit_std_exception_valid_o(), .sdtrig_commit_icount_valid_o(),
      .sdtrig_commit_action_o(), .sdtrig_commit_icount_nr_instr_o()
  );

  task automatic set_trigger(input logic [63:0] threshold, input logic [1:0] kind);
    @(negedge clk);
    tdata2_i = threshold;
    tdata2_we = 1;
    @(negedge clk);
    tdata2_we = 0;
    tdata1_i = 64'h6000_0000_0000_0041 | (64'(kind) << 7);
    tdata1_we = 1;
    @(negedge clk);
    tdata1_we = 0;
  endtask

  task automatic check_load(input logic [63:0] address, input logic expected);
    logic actual;
    @(negedge clk);
    lsu_vaddr = address;
    lsu_valid = 1;
    @(posedge clk);
    #1;
    actual = trigger_cancel;
    @(negedge clk);
    lsu_valid = 0;
    if (actual !== expected) begin
      $display("FAIL: threshold=%h address=%h actual=%b expected=%b", tdata2_i, address,
               actual, expected);
      failures++;
    end
    @(negedge clk);
  endtask

  initial begin
    repeat (2) @(negedge clk);
    rst_n = 1;
    set_trigger(64'h8000_1000, 2);
    check_load(64'h8000_0800, 0);
    check_load(64'h8000_1000, 1);
    check_load(64'h8000_2000, 1);
    set_trigger(64'h8000_1000, 3);
    check_load(64'h8000_0800, 1);
    check_load(64'h8000_1000, 0);
    check_load(64'h8000_2000, 0);
    set_trigger(64'h8000_0000_0000_0000, 2);
    check_load(64'h7fff_ffff_ffff_ffff, 0);
    check_load(64'h8000_0000_0000_0000, 1);
    set_trigger(64'h8000_0000_0000_0000, 3);
    check_load(64'h7fff_ffff_ffff_ffff, 1);
    check_load(64'h8000_0000_0000_0000, 0);
    set_trigger(64'h0, 2);
    check_load(64'h0, 1);
    set_trigger(64'hffff_ffff_ffff_ffff, 3);
    check_load(64'hffff_ffff_ffff_fffe, 1);
    check_load(64'hffff_ffff_ffff_ffff, 0);
    set_trigger(64'h8000_1000, 0);
    check_load(64'h8000_0800, 0);
    check_load(64'h8000_1000, 1);
    if (failures) $fatal(1, "%0d ge/lt comparisons failed", failures);
    $display("PASS: mcontrol6 ge/lt compare against tdata2");
    $finish;
  end
endmodule
