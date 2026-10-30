module trigger_xtrigger_test;
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
    cfg.SdtrigEtrigger = 1;
    cfg.SdtrigItrigger = 1;
    cfg.SdtrigNrTriggers = 4;
    cfg.SdtrigSupportedActions = 2'b11;
    return cfg;
  endfunction

  localparam config_pkg::cva6_cfg_t TestCfg = test_config();

  logic clk = 0;
  logic rst_n = 0;
  logic debug_mode;
  riscv::priv_lvl_t priv_lvl;
  exception_t ex;
  logic mret;
  logic [TestCfg.NrCommitPorts-1:0] commit_ack;
  logic [XLEN-1:0] tdata1_i, tdata2_i, tselect_i;
  logic tdata1_we, tdata2_we, tselect_we;
  logic [XLEN-1:0] tdata1_o;
  logic fire;
  logic [XLEN-1:0] fire_action;

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
      .debug_mode_i(debug_mode),
      .mret_i(mret),
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
      .sdtrig_load_cancel_o(),
      .sdtrig_load_action_o(),
      .sdtrig_store_stall_o(),
      .sdtrig_store_action_o(),
      .sdtrig_commit_std_exception_valid_o(fire),
      .sdtrig_commit_icount_valid_o(),
      .sdtrig_commit_action_o(fire_action),
      .sdtrig_commit_icount_nr_instr_o()
  );

  function automatic logic [XLEN-1:0] tdata1_type(input logic [3:0] t);
    return XLEN'(t) << (XLEN - 4);
  endfunction

  localparam logic [XLEN-1:0] DMODE = XLEN'(1) << (XLEN - 5);
  localparam logic [XLEN-1:0] INTERRUPT = XLEN'(1) << (XLEN - 1);
  localparam logic [XLEN-1:0] XTRIG_M = XLEN'(32'h200);

  task automatic write_csr(input int csr, input logic [XLEN-1:0] value);
    case (csr)
      0: begin tselect_i = value; tselect_we = 1; end
      1: begin tdata1_i = value; tdata1_we = 1; end
      2: begin tdata2_i = value; tdata2_we = 1; end
      default: ;
    endcase
    @(posedge clk);
    #0.1;
    tselect_we = 0;
    tdata1_we  = 0;
    tdata2_we  = 0;
  endtask

  // A trap with this cause is taken in one cycle
  task automatic take_trap(input logic [XLEN-1:0] cause);
    ex.valid = 1;
    ex.cause = cause;
    @(posedge clk);
    #0.1;
    ex = '0;
  endtask

  // The trigger module does not request a fire in the next n cycles
  task automatic check_no_fire(input int n, input string what);
    repeat (n) begin
      @(posedge clk);
      #0.1;
      assert (!fire) else $fatal(1, "%s", what);
    end
  endtask

  // The trigger module requests a fire with this action in the next n cycles
  task automatic check_fire(input int n, input logic [XLEN-1:0] action, input string what);
    logic seen = 0;
    repeat (n) begin
      @(posedge clk);
      #0.1;
      if (fire) begin
        seen = 1;
        assert (fire_action == action)
        else $fatal(1, "%s: action %0d, expected %0d", what, fire_action, action);
      end
    end
    assert (seen) else $fatal(1, "%s: no fire", what);
  endtask

  // The breakpoint (or the Debug Mode entry) of the fire is taken
  task automatic take_fire(input logic [XLEN-1:0] cause);
    wait (fire);
    take_trap(cause);
    check_no_fire(4, "fire is not cleared");
  endtask

  initial begin
    debug_mode = 0;
    priv_lvl   = riscv::PRIV_LVL_M;
    ex         = '0;
    mret       = 0;
    commit_ack = '0;
    tdata1_i   = '0;
    tdata2_i   = '0;
    tselect_i  = '0;
    tdata1_we  = 0;
    tdata2_we  = 0;
    tselect_we = 0;
    repeat (2) @(posedge clk);
    #0.1;
    rst_n = 1;

    // etrigger on exception code 0. No trap: ex_i.cause is 0, ex_i.valid is 0.
    write_csr(0, 0);
    write_csr(2, XLEN'(1));
    write_csr(1, tdata1_type(4'd5) | XTRIG_M);
    check_no_fire(8, "etrigger fires with no trap");

    // etrigger on exception code 7. An interrupt with code 7 does not match.
    write_csr(2, XLEN'(1) << 7);
    take_trap(INTERRUPT | XLEN'(7));
    check_no_fire(8, "etrigger fires on an interrupt");

    // A Debug Mode entry is not a trap
    write_csr(2, XLEN'(1) << 24);
    take_trap(riscv::DEBUG_REQUEST);
    check_no_fire(8, "etrigger fires on a halt request");

    // An exception with code 7 matches. The trigger fires with a breakpoint.
    write_csr(2, XLEN'(1) << 7);
    take_trap(XLEN'(7));
    check_fire(3, riscv::BREAKPOINT, "etrigger on exception 7");
    take_fire(riscv::BREAKPOINT);
    mret = 1;
    @(posedge clk);
    #0.1;
    mret = 0;

    // An exception from S-mode matches a trigger with s=1
    priv_lvl = riscv::PRIV_LVL_S;
    write_csr(1, tdata1_type(4'd5) | XLEN'(32'h80));
    take_trap(XLEN'(7));
    check_fire(3, riscv::BREAKPOINT, "etrigger on an exception from S-mode");
    take_fire(riscv::BREAKPOINT);
    priv_lvl = riscv::PRIV_LVL_M;
    mret = 1;
    @(posedge clk);
    #0.1;
    mret = 0;

    // An exception with code 2 is not selected
    write_csr(1, tdata1_type(4'd5) | XTRIG_M);
    take_trap(XLEN'(2));
    check_no_fire(8, "etrigger fires on a code that is not selected");

    // An exception from a mode that is not enabled does not match
    priv_lvl = riscv::PRIV_LVL_U;
    take_trap(XLEN'(7));
    check_no_fire(8, "etrigger fires on a trap from a mode that is not enabled");
    priv_lvl = riscv::PRIV_LVL_M;

    // Trigger 0 is an etrigger on code 7, trigger 1 an etrigger on code 2.
    // Exception 7 fires trigger 0 only. Trigger 1 does not record a hit.
    write_csr(1, tdata1_type(4'd5) | XTRIG_M);
    write_csr(2, XLEN'(1) << 7);
    write_csr(0, 1);
    write_csr(1, tdata1_type(4'd5) | XTRIG_M);
    write_csr(2, XLEN'(1) << 2);
    take_trap(XLEN'(7));
    check_fire(3, riscv::BREAKPOINT, "etrigger 0 on exception 7");
    take_fire(riscv::BREAKPOINT);
    assert (tdata1_o[XLEN-6] == 1'b0) else $fatal(1, "etrigger 1 fired on exception 7");
    write_csr(0, 0);
    assert (tdata1_o[XLEN-6] == 1'b1) else $fatal(1, "etrigger 0 did not record a hit");
    mret = 1;
    @(posedge clk);
    #0.1;
    mret = 0;

    $display("PASS: etrigger fires only on a selected exception (XLEN=%0d)", XLEN);

    // itrigger on interrupt 7: it fires after the trap, before the first
    // instruction of the handler. It does not wait for an mret.
    write_csr(1, tdata1_type(4'd4) | XTRIG_M);
    write_csr(2, XLEN'(1) << 7);
    take_trap(INTERRUPT | XLEN'(7));
    check_fire(3, riscv::BREAKPOINT, "itrigger on interrupt 7");
    take_fire(riscv::BREAKPOINT);
    mret = 1;
    @(posedge clk);
    #0.1;
    mret = 0;

    // An exception with code 7 does not match an itrigger
    write_csr(1, tdata1_type(4'd4) | XTRIG_M);
    take_trap(XLEN'(7));
    check_no_fire(8, "itrigger fires on an exception");

    // An interrupt taken from S-mode matches an itrigger with s=1
    priv_lvl = riscv::PRIV_LVL_S;
    write_csr(1, tdata1_type(4'd4) | XLEN'(32'h80));
    take_trap(INTERRUPT | XLEN'(7));
    check_fire(3, riscv::BREAKPOINT, "itrigger on an interrupt from S-mode");
    take_fire(riscv::BREAKPOINT);
    priv_lvl = riscv::PRIV_LVL_M;
    mret = 1;
    @(posedge clk);
    #0.1;
    mret = 0;

    // Trigger 0 is an itrigger, trigger 1 is an etrigger, both on code 7.
    // An interrupt fires only the itrigger. The etrigger does not record a hit.
    write_csr(1, tdata1_type(4'd4) | XTRIG_M);
    write_csr(0, 1);
    write_csr(1, tdata1_type(4'd5) | XTRIG_M);
    write_csr(2, XLEN'(1) << 7);
    take_trap(INTERRUPT | XLEN'(7));
    check_fire(3, riscv::BREAKPOINT, "itrigger with an etrigger on the same code");
    take_fire(riscv::BREAKPOINT);
    assert (tdata1_o[XLEN-6] == 1'b0) else $fatal(1, "etrigger fired on an interrupt");
    write_csr(0, 0);
    assert (tdata1_o[XLEN-6] == 1'b1) else $fatal(1, "itrigger did not record a hit");

    $display("PASS: itrigger fires before the first instruction of the handler (XLEN=%0d)", XLEN);
    $finish;
  end
endmodule
