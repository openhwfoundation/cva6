module trigger_loadaddr_test;
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
    logic        valid;
    logic [63:0] cause;
    logic [63:0] tval;
    logic [63:0] tval2;
    logic [31:0] tinst;
    logic        gva;
    logic        timing;
  } exception_t;

  logic clk = 0;
  logic rst_n = 0;
  logic [63:0] tdata1_i = 0;
  logic [63:0] tdata2_i = 0;
  logic [63:0] tselect_i = 0;
  logic tdata1_we = 0;
  logic tdata2_we = 0;
  logic tselect_we = 0;
  logic [63:0] tdata1_o;
  logic lsu_valid = 0;
  logic [63:0] lsu_vaddr = 0;
  logic trigger_cancel;
  logic [63:0] trigger_action;

  always #1 clk = !clk;

  trigger_module #(
      .CVA6Cfg(TestCfg),
      .exception_t(exception_t)
  ) dut (
      .clk_i(clk),
      .rst_ni(rst_n),
      .commit_ack_i('0),
      .ex_i('0),
      .priv_lvl_i(riscv::PRIV_LVL_M),
      .debug_mode_i(1'b0),
      .mret_i(1'b0),
      .sret_i(1'b0),
      .mstatus_mie_i(1'b1),
      .mstatus_sie_i(1'b1),
      .medeleg_breakpoint_i(1'b0),
      .sdtrig_lsu_inputs_vaddr_i(lsu_vaddr),
      .sdtrig_lsu_inputs_data_i('0),
      .sdtrig_lsu_inputs_fu_i(1'b0),
      .sdtrig_lsu_inputs_op_i(ariane_pkg::ADD),
      .sdtrig_lsu_inputs_valid_i(lsu_valid),
      .sdtrig_load_data_i('0),
      .sdtrig_load_valid_i(1'b0),
      .scontext_i('0),
      .tdata1_i(tdata1_i),
      .tdata2_i(tdata2_i),
      .tdata3_i('0),
      .tselect_i(tselect_i),
      .tselect_we(tselect_we),
      .tdata1_we(tdata1_we),
      .tdata2_we(tdata2_we),
      .tdata3_we(1'b0),
      .tselect_o(),
      .tdata1_o(tdata1_o),
      .tdata2_o(),
      .tdata3_o(),
      .flush_o(),
      .mepc_i('0),
      .mcause_i('0),
      .mtval_i('0),
      .etrigger_context_saved_valid_o(),
      .etrigger_context_mepc_o(),
      .etrigger_context_mcause_o(),
      .etrigger_context_mtval_o(),
      .fetch_sdtrig_pc_i('0),
      .fetch_sdtrig_instr_i('0),
      .sdtrig_decoder_action_o(),
      .sdtrig_load_stall_o(),
      .sdtrig_load_cancel_o(trigger_cancel),
      .sdtrig_load_action_o(trigger_action),
      .sdtrig_store_stall_o(),
      .sdtrig_store_action_o(),
      .sdtrig_commit_std_exception_valid_o(),
      .sdtrig_commit_icount_valid_o(),
      .sdtrig_commit_action_o(),
      .sdtrig_commit_icount_nr_instr_o()
  );

  task automatic write_tdata1(input logic [63:0] value);
    tdata1_i = value;
    tdata1_we = 1;
    @(posedge clk);
    #1;
    tdata1_we = 0;
  endtask

  task automatic write_tselect(input logic [63:0] value);
    tselect_i = value;
    tselect_we = 1;
    @(posedge clk);
    #1;
    tselect_we = 0;
  endtask

  task automatic write_tdata2(input logic [63:0] value);
    tdata2_i = value;
    tdata2_we = 1;
    @(posedge clk);
    #1;
    tdata2_we = 0;
  endtask

  initial begin
    repeat (2) @(posedge clk);
    rst_n = 1;

    write_tselect(0);
    write_tdata2(64'h1234);
    write_tdata1(64'h6000_0000_0000_0041);
    write_tselect(1);
    write_tdata2(64'h5678);
    write_tdata1(64'h6000_0000_0000_1041);

    lsu_vaddr = 64'h1234;
    lsu_valid = 1;
    @(posedge clk);
    #1;

    assert (trigger_cancel)
      else $fatal(1, "LoadAddr match did not produce cancel");
    assert (trigger_action == riscv::BREAKPOINT)
      else $fatal(1, "cancel used an unrelated trigger action");

    lsu_valid = 0;
    @(posedge clk);
    #1;
    assert (!trigger_cancel)
      else $fatal(1, "cancel pulse did not clear");

    write_tselect(0);
    assert (tdata1_o[22])
      else $fatal(1, "matching trigger did not record hit0");
    write_tselect(1);
    assert (!tdata1_o[22])
      else $fatal(1, "unmatched trigger recorded hit0");

    $display("PASS: LoadAddr cancel retains its trigger");
    $finish;
  end
endmodule
