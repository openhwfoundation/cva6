module trigger_icount_test;
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
    cfg.SdtrigIcount = 1;
    cfg.SdtrigNrTriggers = 4;
    cfg.SdtrigSupportedActions = 2'b11;
    return cfg;
  endfunction

  localparam config_pkg::cva6_cfg_t TestCfg = test_config();
  localparam int unsigned NrW = $clog2(TestCfg.NrCommitPorts);

  logic clk = 0;
  logic rst_n = 0;
  logic debug_mode;
  riscv::priv_lvl_t priv_lvl;
  exception_t ex;
  logic mret;
  logic [TestCfg.NrCommitPorts-1:0] commit_ack;
  logic [13:0] instret_d, instret_q;
  logic [XLEN-1:0] tdata1_i;
  logic tdata1_we;
  logic [XLEN-1:0] tdata1_o;
  logic icount_valid;
  logic [NrW-1:0] icount_nr;
  logic [XLEN-1:0] icount_action;

  always #1 clk = !clk;

  trigger_module #(
      .CVA6Cfg(TestCfg),
      .exception_t(exception_t)
  ) dut (
      .clk_i(clk),
      .rst_ni(rst_n),
      .commit_ack_i(commit_ack),
      .ex_i(ex),
      .priv_lvl_i(priv_lvl),
      .v_i(1'b0),
      .debug_mode_i(debug_mode),
      .mret_i(mret),
      .sret_i(1'b0),
      .instr_count_d(instret_d),
      .instr_count_q(instret_q),
      .sdtrig_lsu_inputs_vaddr_i('0),
      .sdtrig_lsu_inputs_data_i('0),
      .sdtrig_lsu_inputs_fu_i(1'b0),
      .sdtrig_lsu_inputs_valid_i(1'b0),
      .sdtrig_load_data_i('0),
      .sdtrig_load_valid_i(1'b0),
      .scontext_i('0),
      .tdata1_i(tdata1_i),
      .tdata2_i('0),
      .tdata3_i('0),
      .tselect_i('0),
      .tselect_we(1'b0),
      .tdata1_we(tdata1_we),
      .tdata2_we(1'b0),
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
      .sdtrig_load_data_action_o(),
      .sdtrig_load_cancel_o(),
      .sdtrig_load_action_o(),
      .sdtrig_store_stall_o(),
      .sdtrig_store_action_o(),
      .sdtrig_commit_std_exception_valid_o(),
      .sdtrig_commit_icount_valid_o(icount_valid),
      .sdtrig_commit_action_o(icount_action),
      .sdtrig_commit_icount_nr_instr_o(icount_nr)
  );

  localparam logic [XLEN-1:0] ICOUNT = XLEN'(3) << (XLEN - 4);
  localparam logic [XLEN-1:0] ICOUNT_M = XLEN'(32'h200);
  localparam logic [XLEN-1:0] ICOUNT_U = XLEN'(32'h40);
  localparam logic [XLEN-1:0] PENDING = XLEN'(32'h100);
  localparam logic [XLEN-1:0] HIT = XLEN'(32'h100_0000);

  function automatic logic [XLEN-1:0] count(input int c);
    return XLEN'(c) << 10;
  endfunction

  // The commit stage takes the trigger action in this cycle
  function automatic logic fire_now();
    return icount_valid && icount_nr == '0;
  endfunction

  task automatic write_tdata1(input logic [XLEN-1:0] value);
    tdata1_i  = value;
    tdata1_we = 1;
    @(posedge clk);
    #0.1;
    tdata1_we = 0;
    // The write flushes the pipeline: nothing retires in the next cycle
    @(posedge clk);
    #0.1;
  endtask

  // n instructions retire in one cycle
  task automatic retire(input int n);
    commit_ack = '0;
    for (int p = 0; p < n; p++) commit_ack[p] = 1'b1;
    instret_d = instret_q + 14'(n);
    @(posedge clk);
    #0.1;
    commit_ack = '0;
    instret_q  = instret_d;
  endtask

  // The trigger action is taken: the commit stage raises the exception
  task automatic take_fire();
    assert (fire_now()) else $fatal(1, "no fire to take");
    ex.valid = 1;
    ex.cause = icount_action;
    @(posedge clk);
    #0.1;
    ex = '0;
    // The handler returns
    mret = 1;
    @(posedge clk);
    #0.1;
    mret = 0;
  endtask

  task automatic check_no_fire(input int n, input string what);
    repeat (n) begin
      @(posedge clk);
      #0.1;
      assert (!fire_now()) else $fatal(1, "%s", what);
    end
  endtask

  initial begin
    debug_mode = 0;
    priv_lvl   = riscv::PRIV_LVL_M;
    ex         = '0;
    mret       = 0;
    commit_ack = '0;
    instret_d  = '0;
    instret_q  = '0;
    tdata1_i   = '0;
    tdata1_we  = 0;
    repeat (2) @(posedge clk);
    #0.1;
    rst_n = 1;

    // count=0: the trigger does not fire
    write_tdata1(ICOUNT | count(0) | ICOUNT_M);
    repeat (4) retire(1);
    check_no_fire(4, "count=0 fires");
    assert (!(tdata1_o & PENDING)) else $fatal(1, "count=0 sets pending");

    // count=1: one instruction at a time retires. After one instruction, the
    // trigger fires on the next instruction. The request stays until it is taken.
    write_tdata1(ICOUNT | count(1) | ICOUNT_M);
    @(posedge clk);
    #0.1;
    if (TestCfg.NrCommitPorts > 1)
      assert (icount_valid && icount_nr == NrW'(1)) else $fatal(1, "count=1 does not limit commit");
    assert (!fire_now()) else $fatal(1, "count=1 fires before an instruction retires");
    retire(1);
    @(posedge clk);
    #0.1;
    repeat (5) begin
      assert (fire_now()) else $fatal(1, "pending trigger does not request the fire");
      assert (icount_action == riscv::BREAKPOINT) else $fatal(1, "fire action %0d", icount_action);
      @(posedge clk);
      #0.1;
    end
    take_fire();
    check_no_fire(4, "trigger fires twice");
    assert ((tdata1_o & (PENDING | HIT)) == HIT) else $fatal(1, "fire reads %h", tdata1_o);

    // pending is kept in a mode where the trigger is not enabled, and in Debug Mode.
    // The trigger fires when the hart is back in an enabled mode.
    priv_lvl = riscv::PRIV_LVL_U;
    write_tdata1(ICOUNT | count(1) | ICOUNT_U);
    retire(1);
    priv_lvl = riscv::PRIV_LVL_M;
    check_no_fire(4, "trigger fires in a mode that is not enabled");
    debug_mode = 1;
    check_no_fire(4, "trigger fires in Debug Mode");
    debug_mode = 0;
    assert (tdata1_o & PENDING) else $fatal(1, "pending is lost");
    priv_lvl = riscv::PRIV_LVL_U;
    @(posedge clk);
    #0.1;
    take_fire();
    check_no_fire(4, "trigger fires twice");

    $display("PASS: icount fires on the next instruction in an enabled mode (XLEN=%0d)", XLEN);
    $finish;
  end
endmodule
