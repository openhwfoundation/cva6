module trigger_tdata1_test;
  timeunit 1ns; timeprecision 1ps;
  localparam int unsigned XLEN = cva6_config_pkg::CVA6ConfigXlen;

  typedef struct packed {
    logic            valid;
    logic [XLEN-1:0] cause;
  } exception_t;

  function automatic config_pkg::cva6_cfg_t test_config();
    config_pkg::cva6_cfg_t cfg;
    cfg = build_config_pkg::build_config(cva6_config_pkg::cva6_cfg);
    cfg.Sdtrig = 1;
    cfg.SdtrigMcontrol6 = 1;
    cfg.SdtrigMcontrol6ExecAddr = 1;
    cfg.SdtrigIcount = 1;
    cfg.SdtrigEtrigger = 1;
    cfg.SdtrigItrigger = 1;
    cfg.SdtrigNrTriggers = 4;
    cfg.SdtrigSupportedActions = 2'b11;
    cfg.SdtrigSupportedMatch = 10'b11_1111_1111;
    return cfg;
  endfunction

  localparam config_pkg::cva6_cfg_t TestCfg = test_config();

  logic clk = 0;
  logic rst_n = 0;
  logic debug_mode;
  logic [XLEN-1:0] tdata1_i, tdata2_i, tselect_i;
  logic tdata1_we, tdata2_we, tselect_we;
  logic [XLEN-1:0] tdata1_o;
  logic flush;
  logic [TestCfg.NrIssuePorts-1:0][TestCfg.VLEN-1:0] fetch_pc;
  logic [XLEN-1:0] decoder_action[TestCfg.NrIssuePorts];

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
      .debug_mode_i(debug_mode),
      .mret_i(1'b0),
      .sret_i(1'b0),
      .mstatus_mie_i(1'b1),
      .mstatus_sie_i(1'b1),
      .medeleg_breakpoint_i(1'b0),
      .sdtrig_lsu_inputs_vaddr_i('0),
      .sdtrig_lsu_inputs_data_i('0),
      .sdtrig_lsu_inputs_fu_i(1'b0),
      .sdtrig_lsu_inputs_op_i(ariane_pkg::ADD),
      .sdtrig_lsu_inputs_valid_i(1'b0),
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
      .flush_o(flush),
      .mepc_i('0),
      .mcause_i('0),
      .mtval_i('0),
      .etrigger_context_saved_valid_o(),
      .etrigger_context_mepc_o(),
      .etrigger_context_mcause_o(),
      .etrigger_context_mtval_o(),
      .fetch_sdtrig_pc_i(fetch_pc),
      .fetch_sdtrig_instr_i('0),
      .sdtrig_decoder_action_o(decoder_action),
      .sdtrig_load_stall_o(),
      .sdtrig_load_cancel_o(),
      .sdtrig_load_action_o(),
      .sdtrig_store_stall_o(),
      .sdtrig_store_action_o(),
      .sdtrig_commit_std_exception_valid_o(),
      .sdtrig_commit_icount_valid_o(),
      .sdtrig_commit_action_o(),
      .sdtrig_commit_icount_nr_instr_o()
  );

  function automatic logic [XLEN-1:0] tdata1_type(input logic [3:0] t);
    return XLEN'(t) << (XLEN - 4);
  endfunction

  localparam logic [XLEN-1:0] DMODE = XLEN'(1) << (XLEN - 5);
  localparam logic [XLEN-1:0] DISABLED = XLEN'(15) << (XLEN - 4);

  // Write tdata1. Return the value of flush_o in the write cycle.
  task automatic write_tdata1(input logic [XLEN-1:0] value, output logic flushed);
    tdata1_i  = value;
    tdata1_we = 1;
    #0.5;
    flushed = flush;
    @(posedge clk);
    #0.1;
    tdata1_we = 0;
  endtask

  task automatic write_tdata2(input logic [XLEN-1:0] value);
    tdata2_i  = value;
    tdata2_we = 1;
    @(posedge clk);
    #0.1;
    tdata2_we = 0;
  endtask

  task automatic write_tselect(input logic [XLEN-1:0] value);
    tselect_i  = value;
    tselect_we = 1;
    @(posedge clk);
    #0.1;
    tselect_we = 0;
  endtask

  logic flushed;

  initial begin
    debug_mode = 0;
    tdata1_i   = '0;
    tdata2_i   = '0;
    tselect_i  = '0;
    tdata1_we  = 0;
    tdata2_we  = 0;
    tselect_we = 0;
    fetch_pc   = '0;
    repeat (2) @(posedge clk);
    #0.1;
    rst_n = 1;

    // After reset, every trigger is disabled (type 15), not "no trigger" (type 0)
    for (int i = 0; i < 4; i++) begin
      write_tselect(XLEN'(i));
      assert (tdata1_o == DISABLED)
      else $fatal(1, "trigger %0d reads %h after reset", i, tdata1_o);
    end
    write_tselect('0);

    // An execute trigger on 0x80000000 matches the fetched PC
    write_tdata2(XLEN'(64'h8000_0000));
    write_tdata1(tdata1_type(4'd6) | XLEN'(32'h44), flushed);
    fetch_pc[0] = TestCfg.VLEN'(64'h8000_0000);
    #0.5;
    assert (decoder_action[0] == riscv::BREAKPOINT)
    else $fatal(1, "execute trigger does not match");

    // A write of 0 disables the trigger: type 15, no match, pipeline flush
    write_tdata1('0, flushed);
    assert (flushed) else $fatal(1, "a write of 0 does not flush");
    assert (tdata1_o == DISABLED) else $fatal(1, "a write of 0 reads %h", tdata1_o);
    #0.5;
    assert (decoder_action[0] == '0) else $fatal(1, "disabled trigger still matches");

    // A write of type 15 reads back as type 15
    write_tdata1(tdata1_type(4'd6) | XLEN'(32'h44), flushed);
    write_tdata1(DISABLED | XLEN'(32'h44), flushed);
    assert (tdata1_o == DISABLED) else $fatal(1, "a write of type 15 reads %h", tdata1_o);
    #0.5;
    assert (decoder_action[0] == '0) else $fatal(1, "type 15 trigger matches");

    // A write of a type that is not supported (2) disables the trigger
    write_tdata1(tdata1_type(4'd2) | XLEN'(32'h44), flushed);
    assert (tdata1_o == DISABLED) else $fatal(1, "a write of type 2 reads %h", tdata1_o);

    // A write of 0 from Debug Mode keeps dmode=0. A write of type 15 with
    // dmode=1 from Debug Mode keeps dmode=1.
    debug_mode = 1;
    write_tdata1(DISABLED | DMODE, flushed);
    assert (tdata1_o == (DISABLED | DMODE))
    else $fatal(1, "type 15 with dmode reads %h", tdata1_o);
    // dmode=1 blocks the writes from M-mode
    debug_mode = 0;
    write_tdata1(tdata1_type(4'd6) | XLEN'(32'h44), flushed);
    assert (tdata1_o == (DISABLED | DMODE)) else $fatal(1, "dmode=1 trigger written from M-mode");
    debug_mode = 1;
    write_tdata1('0, flushed);
    assert (tdata1_o == DISABLED) else $fatal(1, "a write of 0 from Debug Mode reads %h", tdata1_o);
    debug_mode = 0;

    // A write from M-mode cannot set dmode. Thus action=1 becomes action=0.
    // mcontrol6: action is bits 15:12. icount, etrigger, itrigger: bits 5:0.
    write_tdata1(tdata1_type(4'd6) | DMODE | XLEN'(32'h1044), flushed);
    assert (tdata1_o == (tdata1_type(4'd6) | XLEN'(32'h44)))
    else $fatal(1, "mcontrol6 dmode=1 action=1 from M-mode reads %h", tdata1_o);
    #0.5;
    assert (decoder_action[0] == riscv::BREAKPOINT)
    else $fatal(1, "legalized mcontrol6 does not give a breakpoint");
    write_tdata1(tdata1_type(4'd6) | XLEN'(32'h1044), flushed);
    assert (tdata1_o == (tdata1_type(4'd6) | XLEN'(32'h44)))
    else $fatal(1, "mcontrol6 dmode=0 action=1 reads %h", tdata1_o);
    write_tdata1(tdata1_type(4'd3) | DMODE | XLEN'(32'h1641), flushed);
    assert (tdata1_o == (tdata1_type(4'd3) | XLEN'(32'h1640)))
    else $fatal(1, "icount action=1 from M-mode reads %h", tdata1_o);
    write_tdata1(tdata1_type(4'd5) | XLEN'(32'h241), flushed);
    assert (tdata1_o == (tdata1_type(4'd5) | XLEN'(32'h240)))
    else $fatal(1, "etrigger action=1 from M-mode reads %h", tdata1_o);
    write_tdata1(tdata1_type(4'd4) | XLEN'(32'h241), flushed);
    assert (tdata1_o == (tdata1_type(4'd4) | XLEN'(32'h240)))
    else $fatal(1, "itrigger action=1 from M-mode reads %h", tdata1_o);
    // An action that is not supported (5) becomes 0
    write_tdata1(tdata1_type(4'd5) | XLEN'(32'h245), flushed);
    assert (tdata1_o == (tdata1_type(4'd5) | XLEN'(32'h240)))
    else $fatal(1, "etrigger action=5 reads %h", tdata1_o);

    // From Debug Mode, dmode=1 keeps action=1. dmode=0 gives action=0.
    debug_mode = 1;
    write_tdata1(tdata1_type(4'd6) | XLEN'(32'h1044), flushed);
    assert (tdata1_o == (tdata1_type(4'd6) | XLEN'(32'h44)))
    else $fatal(1, "mcontrol6 dmode=0 action=1 from Debug Mode reads %h", tdata1_o);
    write_tdata1(tdata1_type(4'd3) | DMODE | XLEN'(32'h1641), flushed);
    assert (tdata1_o == (tdata1_type(4'd3) | DMODE | XLEN'(32'h1641)))
    else $fatal(1, "icount dmode=1 action=1 from Debug Mode reads %h", tdata1_o);
    write_tdata1(tdata1_type(4'd6) | DMODE | XLEN'(32'h1044), flushed);
    assert (tdata1_o == (tdata1_type(4'd6) | DMODE | XLEN'(32'h1044)))
    else $fatal(1, "mcontrol6 dmode=1 action=1 from Debug Mode reads %h", tdata1_o);
    // A trigger with action=1 requests Debug Mode with the trigger cause,
    // not with the cause of a halt request.
    debug_mode = 0;
    #0.5;
    assert (decoder_action[0] == riscv::DEBUG_TRIGGER)
    else $fatal(1, "action=1 trigger gives cause %0d", decoder_action[0]);
    debug_mode = 1;
    write_tdata1('0, flushed);
    debug_mode = 0;

    $display("PASS: tdata1 write of 0 disables the trigger (XLEN=%0d)", XLEN);
    $display("PASS: tdata1 never holds dmode=0 with action=1 (XLEN=%0d)", XLEN);
    $display("PASS: an action=1 trigger requests Debug Mode with the trigger cause (XLEN=%0d)", XLEN);
    $finish;
  end
endmodule
