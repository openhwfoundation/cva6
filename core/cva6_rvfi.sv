// Copyright 2024 Thales DIS France SAS
//
// Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
// You may obtain a copy of the License at https://solderpad.org/licenses/
//
// Original Author: Yannick Casamatta - Thales
// Date: 09/01/2024


module cva6_rvfi
  import ariane_pkg::*;
#(
    parameter config_pkg::cva6_cfg_t CVA6Cfg = config_pkg::cva6_cfg_empty,
    parameter type rvfi_instr_t = logic,
    parameter type rvfi_csr_t = logic,
    parameter type rvfi_probes_instr_t = logic,
    parameter type rvfi_probes_csr_t = logic,
    parameter type rvfi_probes_t = logic,
    parameter type rvfi_to_iti_t = logic

) (

    input logic clk_i,
    input logic rst_ni,

    input rvfi_probes_t rvfi_probes_i,
    output rvfi_instr_t [CVA6Cfg.NrCommitPorts-1:0] rvfi_instr_o,
    output rvfi_to_iti_t rvfi_to_iti_o,
    output rvfi_csr_t rvfi_csr_o
);

  localparam logic [CVA6Cfg.XLEN-1:0] IsaCode =
    (CVA6Cfg.XLEN'(CVA6Cfg.RVA) << 0)   // A - Atomic Instructions extension
  | (CVA6Cfg.XLEN'(CVA6Cfg.RVB) << 1)  // C - Bitmanip extension
  | (CVA6Cfg.XLEN'(CVA6Cfg.RVC) << 2)  // C - Compressed extension
  | (CVA6Cfg.XLEN'(CVA6Cfg.RVD) << 3)  // D - Double precision floating-point extension
  | (CVA6Cfg.XLEN'(CVA6Cfg.RVF) << 5)  // F - Single precision floating-point extension
  | (CVA6Cfg.XLEN'(CVA6Cfg.RVH) << 7)  // H - Hypervisor extension
  | (CVA6Cfg.XLEN'(1) << 8)  // I - RV32I/64I/128I base ISA
  | (CVA6Cfg.XLEN'(1) << 12)  // M - Integer Multiply/Divide extension
  | (CVA6Cfg.XLEN'(0) << 13)  // N - User level interrupts supported
  | (CVA6Cfg.XLEN'(CVA6Cfg.RVS) << 18)  // S - Supervisor mode implemented
  | (CVA6Cfg.XLEN'(CVA6Cfg.RVU) << 20)  // U - User mode implemented
  | (CVA6Cfg.XLEN'(CVA6Cfg.RVV) << 21)  // V - Vector extension
  | (CVA6Cfg.XLEN'(CVA6Cfg.NSX) << 23)  // X - Non-standard extensions present
  | ((CVA6Cfg.XLEN == 64 ? 2 : 1) << CVA6Cfg.XLEN - 2);  // MXL

  localparam logic [CVA6Cfg.XLEN-1:0] hart_id_i = '0;

  // Function to compute AMO write value for RVFI logging
  // This mirrors the AMO ALU behaviour so the tracer sees the value actually written
  // back to memory. This is post-alignment data (lower bytes contain the payload) so
  // the tracer can rotate it using the write mask and address offset.
  function automatic logic [CVA6Cfg.XLEN-1:0] compute_amo_wdata(
      input fu_op amo_op, input logic [CVA6Cfg.XLEN-1:0] mem_old_val,
      input logic [CVA6Cfg.XLEN-1:0] reg_val);
    ariane_pkg::amo_t amo_kind;
    logic is_word_op;
    logic [63:0] operand_a_sext, operand_b_sext;
    logic [63:0] operand_a_zext, operand_b_zext;
    logic [63:0] result64;
    logic [64:0] adder_operand_a, adder_operand_b, adder_sum;

    // Decode functional unit opcode into AMO class and width information
    amo_kind   = AMO_NONE;
    is_word_op = 1'b0;
    unique case (amo_op)
      AMO_LRW: begin
        amo_kind   = AMO_LR;
        is_word_op = 1'b1;
      end
      AMO_LRD: begin
        amo_kind   = AMO_LR;
        is_word_op = 1'b0;
      end
      AMO_SCW: begin
        amo_kind   = AMO_SC;
        is_word_op = 1'b1;
      end
      AMO_SCD: begin
        amo_kind   = AMO_SC;
        is_word_op = 1'b0;
      end
      AMO_SWAPW: begin
        amo_kind   = AMO_SWAP;
        is_word_op = 1'b1;
      end
      AMO_SWAPD: begin
        amo_kind   = AMO_SWAP;
        is_word_op = 1'b0;
      end
      AMO_ADDW: begin
        amo_kind   = AMO_ADD;
        is_word_op = 1'b1;
      end
      AMO_ADDD: begin
        amo_kind   = AMO_ADD;
        is_word_op = 1'b0;
      end
      AMO_ANDW: begin
        amo_kind   = AMO_AND;
        is_word_op = 1'b1;
      end
      AMO_ANDD: begin
        amo_kind   = AMO_AND;
        is_word_op = 1'b0;
      end
      AMO_ORW: begin
        amo_kind   = AMO_OR;
        is_word_op = 1'b1;
      end
      AMO_ORD: begin
        amo_kind   = AMO_OR;
        is_word_op = 1'b0;
      end
      AMO_XORW: begin
        amo_kind   = AMO_XOR;
        is_word_op = 1'b1;
      end
      AMO_XORD: begin
        amo_kind   = AMO_XOR;
        is_word_op = 1'b0;
      end
      AMO_MAXW: begin
        amo_kind   = AMO_MAX;
        is_word_op = 1'b1;
      end
      AMO_MAXD: begin
        amo_kind   = AMO_MAX;
        is_word_op = 1'b0;
      end
      AMO_MAXWU: begin
        amo_kind   = AMO_MAXU;
        is_word_op = 1'b1;
      end
      AMO_MAXDU: begin
        amo_kind   = AMO_MAXU;
        is_word_op = 1'b0;
      end
      AMO_MINW: begin
        amo_kind   = AMO_MIN;
        is_word_op = 1'b1;
      end
      AMO_MIND: begin
        amo_kind   = AMO_MIN;
        is_word_op = 1'b0;
      end
      AMO_MINWU: begin
        amo_kind   = AMO_MINU;
        is_word_op = 1'b1;
      end
      AMO_MINDU: begin
        amo_kind   = AMO_MINU;
        is_word_op = 1'b0;
      end
      default: begin
        amo_kind   = AMO_NONE;
        is_word_op = 1'b0;
      end
    endcase

    // Create signed and unsigned 64-bit views of the operands (word ops use 32-bit payloads)
    if (is_word_op) begin
      operand_a_sext = {{32{mem_old_val[31]}}, mem_old_val[31:0]};
      operand_b_sext = {{32{reg_val[31]}}, reg_val[31:0]};
      operand_a_zext = {32'b0, mem_old_val[31:0]};
      operand_b_zext = {32'b0, reg_val[31:0]};
    end else begin
      operand_a_sext = $signed(mem_old_val);
      operand_b_sext = $signed(reg_val);
      operand_a_zext = $unsigned(mem_old_val);
      operand_b_zext = $unsigned(reg_val);
    end

    // Default to returning the register operand (SWAP/SC path)
    result64        = operand_b_zext;
    adder_operand_a = {operand_a_sext[63], operand_a_sext};
    adder_operand_b = {operand_b_sext[63], operand_b_sext};
    adder_sum       = '0;

    unique case (amo_kind)
      AMO_SC, AMO_SWAP: begin
        result64 = operand_b_zext;
      end
      AMO_ADD: begin
        adder_sum = adder_operand_a + adder_operand_b;
        result64  = adder_sum[63:0];
      end
      AMO_AND: result64 = operand_a_zext & operand_b_zext;
      AMO_OR:  result64 = operand_a_zext | operand_b_zext;
      AMO_XOR: result64 = operand_a_zext ^ operand_b_zext;
      AMO_MAX: begin
        adder_operand_b = -{operand_b_sext[63], operand_b_sext};
        adder_sum       = adder_operand_a + adder_operand_b;
        result64        = adder_sum[64] ? operand_b_zext : operand_a_zext;
      end
      AMO_MIN: begin
        adder_operand_b = -{operand_b_sext[63], operand_b_sext};
        adder_sum       = adder_operand_a + adder_operand_b;
        result64        = adder_sum[64] ? operand_a_zext : operand_b_zext;
      end
      AMO_MAXU: begin
        adder_operand_a = {1'b0, operand_a_zext};
        adder_operand_b = -{1'b0, operand_b_zext};
        adder_sum       = adder_operand_a + adder_operand_b;
        result64        = adder_sum[64] ? operand_b_zext : operand_a_zext;
      end
      AMO_MINU: begin
        adder_operand_a = {1'b0, operand_a_zext};
        adder_operand_b = -{1'b0, operand_b_zext};
        adder_sum       = adder_operand_a + adder_operand_b;
        result64        = adder_sum[64] ? operand_a_zext : operand_b_zext;
      end
      default: begin
        result64 = operand_b_zext;
      end
    endcase

    if (is_word_op) begin
      return {{CVA6Cfg.XLEN - 32{1'b0}}, result64[31:0]};
    end else begin
      return result64[CVA6Cfg.XLEN-1:0];
    end
  endfunction

  localparam logic [63:0] SMODE_STATUS_READ_MASK = ariane_pkg::smode_status_read_mask(CVA6Cfg);

  logic flush;
  logic [CVA6Cfg.NrIssuePorts-1:0] issue_instr_ack;
  logic [CVA6Cfg.NrIssuePorts-1:0] fetch_entry_valid;
  logic [CVA6Cfg.NrIssuePorts-1:0][31:0] instruction;
  logic [CVA6Cfg.NrIssuePorts-1:0] is_compressed;
  logic [CVA6Cfg.NrIssuePorts-1:0][31:0] truncated;

  logic [CVA6Cfg.NrIssuePorts-1:0][CVA6Cfg.TRANS_ID_BITS-1:0] issue_pointer;
  logic [CVA6Cfg.NrCommitPorts-1:0][CVA6Cfg.TRANS_ID_BITS-1:0] commit_pointer;

  logic flush_unissued_instr;
  logic [CVA6Cfg.NrIssuePorts-1:0] decoded_instr_valid;
  logic [CVA6Cfg.NrIssuePorts-1:0] decoded_instr_ack;

  logic [CVA6Cfg.NrIssuePorts-1:0][CVA6Cfg.XLEN-1:0] rs1;
  logic [CVA6Cfg.NrIssuePorts-1:0][CVA6Cfg.XLEN-1:0] rs2;

  logic [CVA6Cfg.NrCommitPorts-1:0][CVA6Cfg.XLEN-1:0] rvfi_intr;

  logic [CVA6Cfg.NrCommitPorts-1:0][CVA6Cfg.VLEN-1:0] commit_instr_pc;
  fu_op [CVA6Cfg.NrCommitPorts-1:0] commit_instr_op;
  logic [CVA6Cfg.NrCommitPorts-1:0][REG_ADDR_SIZE-1:0] commit_instr_rs1;
  logic [CVA6Cfg.NrCommitPorts-1:0][REG_ADDR_SIZE-1:0] commit_instr_rs2;
  logic [CVA6Cfg.NrCommitPorts-1:0][REG_ADDR_SIZE-1:0] commit_instr_rd;
  logic [CVA6Cfg.NrCommitPorts-1:0][CVA6Cfg.XLEN-1:0] commit_instr_result;
  logic [CVA6Cfg.NrCommitPorts-1:0] commit_instr_valid;
  logic [CVA6Cfg.NrCommitPorts-1:0] commit_drop;

  logic [CVA6Cfg.XLEN-1:0] ex_commit_cause;
  logic ex_commit_valid;

  logic [CVA6Cfg.NrCommitPorts-1:0] valid_iti;
  logic [CVA6Cfg.NrCommitPorts-1:0][CVA6Cfg.VLEN-1:0] pc_iti;
  ariane_pkg::fu_op [CVA6Cfg.NrCommitPorts-1:0] op_iti;
  logic branch_valid_iti;
  logic is_taken_iti;
  logic [CVA6Cfg.XLEN-1:0] tval_iti;
  logic [63:0] time_iti;

  riscv::priv_lvl_t priv_lvl;

  logic [CVA6Cfg.VLEN-1:0] lsu_ctrl_vaddr;
  fu_t lsu_ctrl_fu;
  logic [(CVA6Cfg.XLEN/8)-1:0] lsu_ctrl_be;
  logic [CVA6Cfg.TRANS_ID_BITS-1:0] lsu_ctrl_trans_id;

  logic [((CVA6Cfg.CvxifEn || CVA6Cfg.RVV) ? 5 : 4)-1:0][CVA6Cfg.XLEN-1:0] wbdata;
  logic [CVA6Cfg.NrCommitPorts-1:0] commit_ack;
  logic [CVA6Cfg.PLEN-1:0] mem_paddr;
  logic debug_mode;
  logic [CVA6Cfg.NrCommitPorts-1:0][CVA6Cfg.XLEN-1:0] wdata;

  logic [CVA6Cfg.VLEN-1:0] lsu_addr;
  logic [(CVA6Cfg.XLEN/8)-1:0] lsu_rmask;
  logic [(CVA6Cfg.XLEN/8)-1:0] lsu_wmask;
  logic [CVA6Cfg.TRANS_ID_BITS-1:0] lsu_addr_trans_id;

  logic [CVA6Cfg.TRANS_ID_BITS-1:0] branch_trans_id;

  riscv::pmpcfg_t [15:0] pmpcfg_q, pmpcfg_d;

  rvfi_probes_csr_t   csr;
  rvfi_probes_instr_t instr;

  always_comb begin
    csr   = '0;
    instr = '0;

    if ($bits(rvfi_probes_i.instr) == $bits(instr)) begin
      instr = rvfi_probes_i.instr;
    end

    if ($bits(rvfi_probes_i.csr) == $bits(csr)) begin
      csr = rvfi_probes_i.csr;
    end

  end


  assign flush = instr.flush;
  assign issue_instr_ack = instr.issue_instr_ack;
  assign fetch_entry_valid = instr.fetch_entry_valid;
  assign instruction = instr.instruction;
  assign is_compressed = instr.is_compressed;

  assign issue_pointer = instr.issue_pointer;
  assign commit_pointer = instr.commit_pointer;

  assign flush_unissued_instr = instr.flush_unissued_instr;
  assign decoded_instr_valid = instr.decoded_instr_valid;
  assign decoded_instr_ack = instr.decoded_instr_ack;

  assign rs1 = instr.rs1;
  assign rs2 = instr.rs2;

  assign commit_instr_pc = instr.commit_instr_pc;
  assign commit_instr_op = instr.commit_instr_op;
  assign commit_instr_rs1 = instr.commit_instr_rs1;
  assign commit_instr_rs2 = instr.commit_instr_rs2;
  assign commit_instr_rd = instr.commit_instr_rd;
  assign commit_instr_result = instr.commit_instr_result;
  assign commit_instr_valid = instr.commit_instr_valid;
  assign commit_drop = instr.commit_drop;

  assign ex_commit_cause = instr.ex_commit_cause;
  assign ex_commit_valid = instr.ex_commit_valid;

  assign valid_iti = instr.commit_ack;
  assign pc_iti = instr.commit_instr_pc;
  assign op_iti = instr.commit_instr_op;
  assign branch_valid_iti = instr.branch_valid;
  assign is_taken_iti = instr.is_taken;
  assign tval_iti = instr.tval;
  assign time_iti = csr.cycle_q;

  assign priv_lvl = instr.priv_lvl;

  assign wbdata = instr.wbdata;
  assign commit_ack = instr.commit_ack;
  assign mem_paddr = instr.mem_paddr;
  assign debug_mode = instr.debug_mode;
  assign wdata = instr.wdata;

  assign lsu_addr = instr.lsu_ctrl_vaddr;
  assign lsu_rmask = instr.lsu_ctrl_fu == LOAD ? instr.lsu_ctrl_be : '0;
  assign lsu_wmask = instr.lsu_ctrl_fu == STORE ? instr.lsu_ctrl_be : '0;
  assign lsu_addr_trans_id = instr.lsu_ctrl_trans_id;
  assign branch_trans_id = instr.branch_trans_id;



  //ID STAGE

  for (genvar i = 0; i < CVA6Cfg.NrIssuePorts; i++) begin
    assign truncated[i] = (is_compressed[i]) ? {16'b0, instruction[i][15:0]} : instruction[i];
  end

  typedef struct packed {
    logic        valid;
    logic [31:0] instr;
    logic        is_compressed;
  } issue_struct_t;
  issue_struct_t [CVA6Cfg.NrIssuePorts-1:0] issue_n, issue_q;
  logic took0;

  always_comb begin
    issue_n = issue_q;
    took0   = 1'b0;

    for (int unsigned i = 0; i < CVA6Cfg.NrIssuePorts; i++) begin
      if (issue_instr_ack[i]) begin
        issue_n[i].valid = 1'b0;
      end
    end

    if (!issue_n[CVA6Cfg.NrIssuePorts-1].valid) begin
      issue_n[CVA6Cfg.NrIssuePorts-1].valid = fetch_entry_valid[0];
      issue_n[CVA6Cfg.NrIssuePorts-1].instr = truncated[0];
      issue_n[CVA6Cfg.NrIssuePorts-1].is_compressed = is_compressed[0];
      took0 = 1'b1;
    end

    if (!issue_n[0].valid) begin
      issue_n[0] = issue_n[CVA6Cfg.NrIssuePorts-1];
      issue_n[CVA6Cfg.NrIssuePorts-1].valid = 1'b0;
    end

    if (!issue_n[CVA6Cfg.NrIssuePorts-1].valid) begin
      if (took0) begin
        issue_n[CVA6Cfg.NrIssuePorts-1].valid = fetch_entry_valid[CVA6Cfg.NrIssuePorts-1];
        issue_n[CVA6Cfg.NrIssuePorts-1].instr = truncated[CVA6Cfg.NrIssuePorts-1];
        issue_n[CVA6Cfg.NrIssuePorts-1].is_compressed = is_compressed[CVA6Cfg.NrIssuePorts-1];
      end else begin
        issue_n[CVA6Cfg.NrIssuePorts-1].valid = fetch_entry_valid[0];
        issue_n[CVA6Cfg.NrIssuePorts-1].instr = truncated[0];
        issue_n[CVA6Cfg.NrIssuePorts-1].is_compressed = is_compressed[0];
      end
    end

    if (flush) begin
      for (int unsigned i = 0; i < CVA6Cfg.NrIssuePorts; i++) begin
        issue_n[i].valid = 1'b0;
      end
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      issue_q <= '0;
    end else begin
      issue_q <= issue_n;
    end
  end

  //ISSUE STAGE

  // this is the FIFO struct of the issue queue
  typedef struct packed {
    logic [CVA6Cfg.XLEN-1:0] rs1_rdata;
    logic [CVA6Cfg.XLEN-1:0] rs2_rdata;
    logic [CVA6Cfg.VLEN-1:0] lsu_addr;
    logic [CVA6Cfg.PLEN-1:0] lsu_paddr;
    logic [(CVA6Cfg.XLEN/8)-1:0] lsu_rmask;
    logic [(CVA6Cfg.XLEN/8)-1:0] lsu_wmask;
    logic [CVA6Cfg.XLEN-1:0] lsu_wdata;
    logic [31:0] instr;
    logic branch_valid;
    logic is_taken;
    logic is_compressed;
  } sb_mem_t;
  sb_mem_t [CVA6Cfg.NR_SB_ENTRIES-1:0] mem_q, mem_n;

  // Delayed copy of the access signals, used to pair mem_paddr with the
  // access it belongs to when an MMU delays the store buffer by one cycle.
  logic [(CVA6Cfg.XLEN/8)-1:0] lsu_rmask_q, lsu_wmask_q;
  logic [CVA6Cfg.TRANS_ID_BITS-1:0] lsu_addr_trans_id_q;

  always_comb begin : issue_fifo
    mem_n = mem_q;

    for (int unsigned i = 0; i < CVA6Cfg.NrIssuePorts; i++) begin
      if (decoded_instr_valid[i] && decoded_instr_ack[i] && !flush_unissued_instr) begin
        mem_n[issue_pointer[i]] = '{
            rs1_rdata: rs1[i],
            rs2_rdata: rs2[i],
            lsu_addr: '0,
            lsu_paddr: '0,
            lsu_rmask: '0,
            lsu_wmask: '0,
            lsu_wdata: '0,
            instr: issue_q[i].instr,
            branch_valid: 1'b0,
            is_taken: 1'b0,
            is_compressed: issue_q[i].is_compressed
        };
      end
    end
    if (branch_valid_iti) begin
      mem_n[branch_trans_id].branch_valid = branch_valid_iti;
      mem_n[branch_trans_id].is_taken = is_taken_iti;
    end
    // The physical address is latched with the access it belongs to, next to
    // the virtual one: mem_paddr is a probe of the address currently presented
    // to the store buffer, so sampling it at commit time would report whatever
    // access the LSU happens to handle then, which follows the memory latency
    // rather than the instruction.
    //
    // With an MMU the store buffer accepts the entry one cycle after lsu_ctrl
    // presents the access (store_unit.sv registers store_buffer_valid), so the
    // address of the access seen this cycle only reaches mem_paddr on the next
    // one: use the delayed lsu_ctrl to pair them. Without an MMU both are
    // combinational and coincide.
    if (lsu_rmask != 0) begin
      mem_n[lsu_addr_trans_id].lsu_addr  = lsu_addr;
      mem_n[lsu_addr_trans_id].lsu_rmask = lsu_rmask;
    end else if (lsu_wmask != 0) begin
      mem_n[lsu_addr_trans_id].lsu_addr  = lsu_addr;
      mem_n[lsu_addr_trans_id].lsu_wmask = lsu_wmask;
      mem_n[lsu_addr_trans_id].lsu_wdata = wbdata[STORE_WB];
    end
    if (CVA6Cfg.MmuPresent) begin
      if (lsu_wmask_q != 0 || lsu_rmask_q != 0) begin
        mem_n[lsu_addr_trans_id_q].lsu_paddr = mem_paddr;
      end
    end else if (lsu_rmask != 0 || lsu_wmask != 0) begin
      mem_n[lsu_addr_trans_id].lsu_paddr = mem_paddr;
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin : regs
    if (!rst_ni) begin
      mem_q <= '{default: sb_mem_t'(0)};
      lsu_rmask_q <= '0;
      lsu_wmask_q <= '0;
      lsu_addr_trans_id_q <= '0;
    end else begin
      mem_q <= mem_n;
      lsu_rmask_q <= lsu_rmask;
      lsu_wmask_q <= lsu_wmask;
      lsu_addr_trans_id_q <= lsu_addr_trans_id;
    end
  end

  //----------------------------------------------------------------------------------------------------------
  // PACK
  //----------------------------------------------------------------------------------------------------------

  always_ff @(posedge clk_i) begin
    for (int i = 0; i < CVA6Cfg.NrCommitPorts; i++) begin
      logic exception;
      logic valid;
      exception = (i == 0) && commit_instr_valid[i] && ex_commit_valid && !commit_drop[i];
      valid     = (commit_ack[i] && !ex_commit_valid && !commit_drop[i]) ||
        (exception && (ex_commit_cause == riscv::ENV_CALL_MMODE ||
                  ex_commit_cause == riscv::ENV_CALL_SMODE ||
                  ex_commit_cause == riscv::ENV_CALL_UMODE));
      rvfi_instr_o[i].valid <= valid;
      rvfi_instr_o[i].insn  <= mem_q[commit_pointer[i]].instr;
      // when synchronous trap, the instruction is not executed
      rvfi_instr_o[i].trap  <= exception && !ex_commit_cause[31];

      if (exception && ex_commit_cause[31]) begin
        rvfi_intr[i] <= 'b101;
      end else if (exception) begin
        rvfi_intr[i] <= 'b11;
      end
      if (valid) begin
        rvfi_intr[i] <= 0;
      end

      rvfi_instr_o[i].intr <= rvfi_intr[i];

      rvfi_instr_o[i].cause <= ex_commit_cause;
      rvfi_instr_o[i].mode <= (CVA6Cfg.DebugEn && debug_mode) ? 2'b10 : priv_lvl;
      rvfi_instr_o[i].ixl <= CVA6Cfg.XLEN == 64 ? 2 : 1;
      rvfi_instr_o[i].rs1_addr <= commit_instr_rs1[i];
      rvfi_instr_o[i].rs2_addr <= commit_instr_rs2[i];
      rvfi_instr_o[i].rd_addr <= commit_instr_rd[i];
      rvfi_instr_o[i].rd_wdata <= (CVA6Cfg.FpPresent && is_rd_fpr(
          commit_instr_op[i]
      )) ? commit_instr_result[i] : wdata[i];
      rvfi_instr_o[i].pc_rdata <= commit_instr_pc[i];
      rvfi_instr_o[i].mem_addr <= mem_q[commit_pointer[i]].lsu_addr;
      rvfi_instr_o[i].mem_paddr <= mem_q[commit_pointer[i]].lsu_paddr;
      rvfi_instr_o[i].mem_wmask <= mem_q[commit_pointer[i]].lsu_wmask;

      // For AMO operations, compute the actual write value
      // Note: AMO operations write a computed value to memory, not the original register value
      if (is_amo(commit_instr_op[i])) begin
        rvfi_instr_o[i].mem_wdata <= compute_amo_wdata(
            commit_instr_op[i],  // AMO operation type
            wdata[i],  // Old memory value (the value returned to rd)
            mem_q[commit_pointer[i]].rs2_rdata  // Register operand (rs2)
        );
      end else begin
        rvfi_instr_o[i].mem_wdata <= mem_q[commit_pointer[i]].lsu_wdata;
      end

      rvfi_instr_o[i].mem_rmask <= mem_q[commit_pointer[i]].lsu_rmask;
      rvfi_instr_o[i].mem_rdata <= commit_instr_result[i];
      rvfi_instr_o[i].rs1_rdata <= mem_q[commit_pointer[i]].rs1_rdata;
      rvfi_instr_o[i].rs2_rdata <= mem_q[commit_pointer[i]].rs2_rdata;
      rvfi_to_iti_o.branch_valid[i] <= mem_q[commit_pointer[i]].branch_valid;
      rvfi_to_iti_o.is_taken[i] <= mem_q[commit_pointer[i]].is_taken;
      rvfi_to_iti_o.is_compressed[i] <= mem_q[commit_pointer[i]].is_compressed;
      rvfi_to_iti_o.valid[i] <= valid_iti[i];
      rvfi_to_iti_o.pc[i] <= pc_iti[i];
      rvfi_to_iti_o.op[i] <= op_iti[i];
    end
    rvfi_to_iti_o.ex_valid <= ex_commit_valid;
    rvfi_to_iti_o.cycles <= time_iti;
    rvfi_to_iti_o.cause <= ex_commit_cause;
    rvfi_to_iti_o.tval <= tval_iti;
    rvfi_to_iti_o.priv_lvl <= priv_lvl;
  end


  //----------------------------------------------------------------------------------------------------------
  // CSR
  //----------------------------------------------------------------------------------------------------------
  // Changing verible formating to fix vivado synthesis errors and warnings
  // verilog_format: off
  `define CONNECT_RVFI_FULL(CSR_ENABLE_COND, CSR_NAME, CSR_SOURCE_NAME) \
  always_ff @(posedge clk_i) begin \
      if (CSR_ENABLE_COND) begin \
          rvfi_csr_o.``CSR_NAME``.rdata <= {{CVA6Cfg.XLEN - $bits(CSR_SOURCE_NAME)}, CSR_SOURCE_NAME}; \
      end \
  end \
  assign rvfi_csr_o.``CSR_NAME``.wdata = CSR_ENABLE_COND ? { {{CVA6Cfg.XLEN-$bits(CSR_SOURCE_NAME)}, CSR_SOURCE_NAME} } : 0; \
  assign rvfi_csr_o.``CSR_NAME``.rmask = CSR_ENABLE_COND ? 1 : 0; \
  assign rvfi_csr_o.``CSR_NAME``.wmask = (rvfi_csr_o.``CSR_NAME``.rdata != {{CVA6Cfg.XLEN - $bits(CSR_SOURCE_NAME)}, CSR_SOURCE_NAME}) && CSR_ENABLE_COND;

  `define CONNECT_RVFI_SAME(CSR_ENABLE_COND, CSR_NAME) \
          `CONNECT_RVFI_FULL(CSR_ENABLE_COND, CSR_NAME, csr.``CSR_NAME``_q)

  if ($bits(rvfi_csr_o) != 1) begin
    `CONNECT_RVFI_FULL(CVA6Cfg.FpPresent, fflags, csr.fcsr_q.fflags)
    `CONNECT_RVFI_FULL(CVA6Cfg.FpPresent, frm, csr.fcsr_q.frm)
    `CONNECT_RVFI_FULL(CVA6Cfg.FpPresent, fcsr, {csr.fcsr_q.frm, csr.fcsr_q.fflags})

    `CONNECT_RVFI_FULL(CVA6Cfg.FpPresent, ftran, csr.fcsr_q.fprec)
    `CONNECT_RVFI_SAME(CVA6Cfg.FpPresent, dcsr)

    `CONNECT_RVFI_SAME(CVA6Cfg.DebugEn, dpc)

    `CONNECT_RVFI_SAME(CVA6Cfg.DebugEn, dscratch0)
    `CONNECT_RVFI_SAME(CVA6Cfg.DebugEn, dscratch1)

    `CONNECT_RVFI_FULL(CVA6Cfg.RVS, sstatus, csr.mstatus_extended & SMODE_STATUS_READ_MASK[CVA6Cfg.XLEN-1:0])

    `CONNECT_RVFI_FULL(CVA6Cfg.RVS, sie, csr.mie_q & csr.mideleg_q)
    `CONNECT_RVFI_FULL(CVA6Cfg.RVS, sip, csr.mip_q & csr.mideleg_q)

    `CONNECT_RVFI_SAME(CVA6Cfg.RVS, stvec)

    `CONNECT_RVFI_SAME(CVA6Cfg.RVS, scounteren)

    `CONNECT_RVFI_SAME(CVA6Cfg.RVS, sscratch)
    `CONNECT_RVFI_SAME(CVA6Cfg.RVS, sepc)

    `CONNECT_RVFI_SAME(CVA6Cfg.RVS, scause)

    `CONNECT_RVFI_SAME(CVA6Cfg.RVS, stval)
    `CONNECT_RVFI_SAME(CVA6Cfg.RVS, satp)

    `CONNECT_RVFI_FULL(1'b1, mstatus, csr.mstatus_extended)

    bit [31:0] mstatush_q;
    `CONNECT_RVFI_FULL(1'b1, mstatush, mstatush_q)

    `CONNECT_RVFI_FULL(1'b1, misa, IsaCode)

    `CONNECT_RVFI_SAME(CVA6Cfg.RVS, medeleg)
    `CONNECT_RVFI_SAME(CVA6Cfg.RVS, mideleg)

    `CONNECT_RVFI_SAME(1'b1, mie)
    `CONNECT_RVFI_SAME(1'b1, mtvec)
    `CONNECT_RVFI_SAME(1'b1, mcounteren)

    `CONNECT_RVFI_SAME(1'b1, mscratch)

    `CONNECT_RVFI_SAME(1'b1, mepc)
    `CONNECT_RVFI_SAME(1'b1, mcause)
    `CONNECT_RVFI_SAME(1'b1, mtval)
    `CONNECT_RVFI_SAME(1'b1, mip)

    `CONNECT_RVFI_FULL(1'b1, menvcfg, csr.fiom_q)

    `CONNECT_RVFI_FULL(CVA6Cfg.XLEN == 32, menvcfgh, 32'h0)

    `CONNECT_RVFI_FULL(1'b1, mvendorid, OPENHWGROUP_MVENDORID)
    `CONNECT_RVFI_FULL(1'b1, marchid, ARIANE_MARCHID)
    `CONNECT_RVFI_FULL(1'b1, mhartid, hart_id_i)

    `CONNECT_RVFI_SAME(1'b1, mcountinhibit)

    `CONNECT_RVFI_FULL(1'b1, mcycle, csr.cycle_q[CVA6Cfg.XLEN-1:0])
    `CONNECT_RVFI_FULL(CVA6Cfg.XLEN == 32, mcycleh, csr.cycle_q[63:32])

    `CONNECT_RVFI_FULL(1'b1, minstret, csr.instret_q[CVA6Cfg.XLEN-1:0])
    `CONNECT_RVFI_FULL(CVA6Cfg.XLEN == 32, minstreth, csr.instret_q[63:32])

    `CONNECT_RVFI_FULL(1'b1, cycle, csr.cycle_q[CVA6Cfg.XLEN-1:0])
    `CONNECT_RVFI_FULL(CVA6Cfg.XLEN == 32, cycleh, csr.cycle_q[63:32])

    `CONNECT_RVFI_FULL(1'b1, instret, csr.instret_q[CVA6Cfg.XLEN-1:0])
    `CONNECT_RVFI_FULL(CVA6Cfg.XLEN == 32, instreth, csr.instret_q[63:32])

    `CONNECT_RVFI_SAME(1'b1, dcache)
    `CONNECT_RVFI_SAME(1'b1, icache)

    `CONNECT_RVFI_SAME(CVA6Cfg.EnableAccelerator, acc_cons)
    `CONNECT_RVFI_SAME(CVA6Cfg.RVZCMT, jvt)
    `CONNECT_RVFI_FULL(1'b1, pmpcfg0, csr.pmpcfg_q[CVA6Cfg.XLEN/8-1:0])
    `CONNECT_RVFI_FULL(CVA6Cfg.XLEN == 32, pmpcfg1, csr.pmpcfg_q[7:4])

    `CONNECT_RVFI_FULL(1'b1, pmpcfg2, csr.pmpcfg_q[8+:CVA6Cfg.XLEN/8])
    `CONNECT_RVFI_FULL(CVA6Cfg.XLEN == 32, pmpcfg3, csr.pmpcfg_q[15:12])

    bit [CVA6Cfg.XLEN-1:0] pmpaddr_q;
    genvar i;
    for (i = 0; i < 16; i++) begin
      `CONNECT_RVFI_FULL(1'b1, pmpaddr[i], {csr.pmpaddr_q[i][CVA6Cfg.PLEN-3:1], pmpcfg_q[i].addr_mode[1]})
    end
    ;
  end
  // verilog_format: on
endmodule
