// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
// CSR-level regression for CVA6 issue #3497. No forced DUT state or UVM.
`include "rvfi_types.svh"

module csr_wfi_case #(
    parameter bit DebugEn = 1'b1
) (
    output bit done_o
);
  timeunit 1ns; timeprecision 1ps;
  import ariane_pkg::*;

  function automatic config_pkg::cva6_cfg_t test_config();
    config_pkg::cva6_cfg_t cfg;
    cfg = build_config_pkg::build_config(cva6_config_pkg::cva6_cfg);
    cfg.DebugEn = DebugEn;
    return cfg;
  endfunction
  localparam config_pkg::cva6_cfg_t Cfg = test_config();
  typedef logic [Cfg.XLEN-1:0] xlen_t;
  typedef struct packed {
    xlen_t cause;
    xlen_t tval;
    logic [Cfg.GPLEN-1:0] tval2;
    logic [31:0] tinst;
    logic gva;
    logic valid;
    logic timing;
  } exception_t;
  // Only the scoreboard fields consumed by csr_regfile (triggers disabled).
  typedef struct packed {
    logic [Cfg.VLEN-1:0] pc;
    fu_t fu;
    struct packed {logic [Cfg.VLEN-1:0] predict_address;} bp;
    logic is_compressed;
  } commit_t;
  typedef struct packed {
    logic [Cfg.XLEN-7:0] base;
    logic [5:0] mode;
  } jvt_t;
  typedef struct packed {
    xlen_t mie, mip, mideleg, hideleg;
    logic sie, global_enable;
  } irq_ctrl_t;
  typedef `RVFI_PROBES_CSR_T(Cfg) rvfi_csr_t;

  bit clk = 0;
  bit rst_n = 0;
  fu_op op;
  logic [11:0] addr;
  xlen_t wdata, rdata;
  logic [Cfg.VLEN-1:0] pc;
  logic [Cfg.NrCommitPorts-1:0] ack;
  commit_t instruction;
  exception_t exception_in, exception_out;
  logic [1:0] irq;
  logic ipi, debug_req;
  logic halt, debug_mode, single_step, set_debug_pc, eret;
  riscv::priv_lvl_t privilege;

  csr_regfile #(
      .CVA6Cfg(Cfg),
      .exception_t(exception_t),
      .jvt_t(jvt_t),
      .irq_ctrl_t(irq_ctrl_t),
      .scoreboard_entry_t(commit_t),
      .rvfi_probes_csr_t(rvfi_csr_t)
  ) dut (
      .clk_i(clk),
      .rst_ni(rst_n),
      .time_irq_i(1'b0),
      .halt_csr_o(halt),
      .commit_instr_i(instruction),
      .commit_ack_i(ack),
      .boot_addr_i(Cfg.VLEN'('h80000000)),
      .hart_id_i('0),
      .ex_i(exception_in),
      .csr_op_i(op),
      .csr_addr_i(addr),
      .csr_wdata_i(wdata),
      .csr_rdata_o(rdata),
      .dirty_fp_state_i(1'b0),
      .csr_write_fflags_i(1'b0),
      .pc_i(pc),
      .csr_exception_o(exception_out),
      .eret_o(eret),
      .priv_lvl_o(privilege),
      .csr_hs_ld_st_inst_i(1'b0),
      .irq_i(irq),
      .ipi_i(ipi),
      .debug_req_i(debug_req),
      .set_debug_pc_o(set_debug_pc),
      .debug_mode_o(debug_mode),
      .single_step_o(single_step),
      .perf_data_i('0),
      .sdtrig_lsu_inputs_vaddr_i('0),
      .sdtrig_lsu_inputs_data_i('0),
      .sdtrig_lsu_inputs_fu_i(1'b0),
      .sdtrig_lsu_inputs_valid_i(1'b0),
      .sdtrig_load_data_i('0),
      .sdtrig_load_valid_i(1'b0),
      .fetch_sdtrig_pc_i('0),
      .fetch_sdtrig_instr_i('0)
  );

  task automatic check(input bit condition, input string message);
    if (!condition) $fatal(1, "FAIL DebugEn=%0d: %s", DebugEn, message);
  endtask

  task automatic tick();
    #5ns;
    clk = 1;
    #5ns;
    clk = 0;
    #1ns;
  endtask

  task automatic idle();
    op = ADD;
    addr = '0;
    wdata = '0;
    pc = '0;
    ack = '0;
    instruction = '0;
    exception_in = '0;
    #1ns;
  endtask

  task automatic reset_dut();
    rst_n = 0;
    irq = '0;
    ipi = 0;
    debug_req = 0;
    idle();
    tick();
    rst_n = 1;
    tick();
    check(!halt && !debug_mode && !single_step, "reset state");
  endtask

  task automatic write_csr(input logic [11:0] address, input xlen_t value);
    check(!halt, "CSR write attempted while halted");
    op = CSR_WRITE;
    addr = address;
    wdata = value;
    ack[0] = 1;
    #1ns;
    check(!exception_out.valid, "unexpected CSR write exception");
    tick();
    idle();
  endtask

  task automatic read_csr(input logic [11:0] address, output xlen_t value);
    check(!halt, "CSR read attempted while halted");
    op   = CSR_READ;
    addr = address;
    #1ns;
    check(!exception_out.valid, "unexpected CSR read exception");
    value = rdata;
    idle();
  endtask

  task automatic enter_debug();
    debug_req = 1;
    exception_in.valid = 1;
    exception_in.cause = riscv::DEBUG_REQUEST;
    pc = Cfg.VLEN'('h80000020);
    #1ns;
    check(set_debug_pc, "debug-request redirect");
    tick();
    debug_req = 0;
    idle();
    check(debug_mode && !halt, "debug-request entry");
  endtask

  task automatic configure_step(input bit step_enable, input bit stepie);
    xlen_t dcsr;
    read_csr(riscv::CSR_DCSR, dcsr);
    dcsr[2]   = step_enable;
    dcsr[11]  = stepie;
    dcsr[1:0] = riscv::PRIV_LVL_M;
    write_csr(riscv::CSR_DCSR, dcsr);
    check(single_step == step_enable, "step CSR programming");
  endtask

  task automatic resume_mmode();
    op = DRET;
    ack[0] = 1;
    #1ns;
    check(eret, "DRET return indication");
    tick();
    idle();
    check(!debug_mode && !halt && privilege == riscv::PRIV_LVL_M,
          "DRET must resume running in M mode");
  endtask

  task automatic commit_wfi(input xlen_t address);
    check(!halt, "WFI issued while already halted");
    op = WFI;
    pc = Cfg.VLEN'(address);
    instruction.pc = Cfg.VLEN'(address);
    instruction.fu = CSR;
    instruction.is_compressed = 0;
    ack[0] = 1;
    #1ns;
    if (DebugEn && single_step && !debug_mode)
      check(set_debug_pc, "stepped WFI must request debug redirect");
    tick();
    idle();
  endtask

  task automatic normal_wfi_tests();
    reset_dut();
    write_csr(riscv::CSR_MIE, xlen_t'(1 << 3));
    commit_wfi(xlen_t'('h80000040));
    repeat (3) begin
      check(halt && !debug_mode, "ordinary WFI must wait");
      tick();
    end
    // mip is registered; allow its update and the following wake clock.
    ipi = 1;
    repeat (2) tick();
    check(!halt, "enabled pending interrupt must wake WFI");

    reset_dut();
    commit_wfi(xlen_t'('h80000040));
    irq[1] = 1;
    tick();
    check(!halt, "irq_i[1] must wake WFI");

    reset_dut();
    commit_wfi(xlen_t'('h80000040));
    debug_req = 1;
    tick();
    check(halt == !DebugEn, "debug-request wake must respect DebugEn");

    reset_dut();
    // Exercise the CSR module's exception guard without retirement.
    op = WFI;
    exception_in.valid = 1;
    exception_in.cause = riscv::ILLEGAL_INSTR;
    tick();
    idle();
    check(!halt, "exceptional WFI must not set the wait state");
    $display("PASS ordinary WFI/wake/exception DebugEn=%0d", DebugEn);
  endtask

  task automatic stepped_wfi_test(input bit stepie);
    xlen_t value;
    reset_dut();
    enter_debug();
    // WFI must remain non-stalling in Debug Mode with step clear or set.
    commit_wfi(xlen_t'('h80000024));
    check(debug_mode && !halt, "WFI in Debug Mode with step=0");
    configure_step(1, stepie);
    commit_wfi(xlen_t'('h80000028));
    check(debug_mode && !halt, "WFI in Debug Mode with step=1");
    resume_mmode();
    check(irq == 0 && !ipi && !debug_req, "no wake event may mask the bug");
    commit_wfi(xlen_t'('h80000040));
    check(debug_mode, "stepped WFI must re-enter Debug Mode");
    check(!halt, "ISSUE3497: stepped WFI leaked halt into Debug Mode");
    read_csr(riscv::CSR_DCSR, value);
    check(value[8:6] == CauseSingleStep, "single-step debug cause");
    check(value[1:0] == riscv::PRIV_LVL_M, "single-step saved privilege");
    read_csr(riscv::CSR_DPC, value);
    check(value == xlen_t'('h80000044), "DPC must equal WFI PC + 4");
    repeat (4) begin
      tick();
      check(debug_mode && !halt, "no delayed WFI halt in Debug Mode");
    end
    // Demonstrate continued CSR access; this does not execute a Debug ROM.
    write_csr(riscv::CSR_DSCRATCH0, xlen_t'('h13579bdf));
    read_csr(riscv::CSR_DSCRATCH0, value);
    check(value == xlen_t'('h13579bdf), "debug CSR access after stepped WFI");
    configure_step(0, stepie);
    resume_mmode();
    commit_wfi(xlen_t'('h80000044));
    check(halt && !debug_mode, "clearing step must restore ordinary WFI");
    $display("PASS stepped WFI stepie=%0d", stepie);
  endtask

  initial begin
    done_o = 0;
    check(!Cfg.Sdtrig, "test requires a configuration with triggers disabled");
    normal_wfi_tests();
    if (DebugEn) begin
      stepped_wfi_test(0);
      stepped_wfi_test(1);
    end
    done_o = 1;
  end
endmodule

module csr_wfi_tb;
  timeunit 1ns; timeprecision 1ps;
  wire debug_done, no_debug_done;
  csr_wfi_case #(.DebugEn(1)) debug_case (.done_o(debug_done));
  csr_wfi_case #(.DebugEn(0)) no_debug_case (.done_o(no_debug_done));
  initial begin
    wait (debug_done && no_debug_done);
    $display("PASS: CVA6 CSR WFI regression");
    $finish;
  end
  initial begin
    #100us;
    $fatal(1, "FAIL: CSR WFI regression timeout");
  end
endmodule
