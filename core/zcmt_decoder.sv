// Licensed under the Solderpad Hardware Licence, Version 2.1 (the "License");
// you may not use this file except in compliance with the License.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
// You may obtain a copy of the License at https://solderpad.org/licenses/
//
// Author: Farhan Ali Shah, 10xEngineers
// Date: 15.11.2024
// Description: ZCMT extension in the CVA6 core targeting the 32-bit embedded-class platforms (CV32A60x).
// ZCMT is a code-size reduction feature that utilizes compressed table jump instructions (cm.jt and cm.jalt) to
//reduce code size for embedded systems
//
module zcmt_decoder #(
    parameter config_pkg::cva6_cfg_t CVA6Cfg = config_pkg::cva6_cfg_empty,
    parameter type ypb_zcmt_req_t = logic,
    parameter type ypb_zcmt_rsp_t = logic,
    parameter type jvt_t = logic,
    parameter type branchpredict_sbe_t = logic
) (
    // Subsystem Clock - SUBSYSTEM
    input  logic                             clk_i,
    // Asynchronous reset active low - SUBSYSTEM
    input  logic                             rst_ni,
    // Flush the decoded instruction - CONTROLLER
    input  logic                             flush_i,
    // Instruction input - compressed_decoder
    input  logic          [            31:0] instr_i,
    // current PC - FRONTEND
    input  logic          [CVA6Cfg.VLEN-1:0] pc_i,
    // Instruction is of ZCMT extension - compressed_decoder
    input  logic                             is_zcmt_instr_i,
    // Instruction is illegal - compressed_decoder
    input  logic                             illegal_instr_i,
    // Instruction is compressed - compressed_decoder
    input  logic                             is_compressed_i,
    // JVT struct input - CSR
    input  jvt_t                             jvt_i,
    // Data cache request request
    output ypb_zcmt_req_t                    ypb_zcmt_req_o,
    // Data cache request response
    input  ypb_zcmt_rsp_t                    ypb_zcmt_rsp_i,
    // Instruction out - cvxif_compressed_if_driver
    output logic          [            31:0] instr_o,
    // Instruction is illegal out - cvxif_compressed_if_driver     
    output logic                             illegal_instr_o,
    // Instruction is compressed out - cvxif_compressed_if_driver
    output logic                             is_compressed_o,
    // Fetch stall - cvxif_compressed_if_driver
    output logic                             fetch_stall_o,
    // jump_address
    output logic          [CVA6Cfg.XLEN-1:0] jump_address_o

);

  // FSM States
  enum logic [1:0] {
    IDLE,  // if ZCMT instruction then request sent to fetch the entry from jump table
    TABLE_WAIT_GNT,
    TABLE_WAIT_RVALID // Check the valid data from jump table and Calculate the offset for jump and create jal instruction

  }
      state_d, state_q;
  // Temporary registers
  // Physical address: jvt + (index <<2)
  logic [CVA6Cfg.VLEN-1:0] table_address;
  logic [CVA6Cfg.VLEN-1:0] req_addr_q, req_addr_d;
  // The pending table read belongs to a flushed instruction: its response is
  // dropped, else it would be taken for the read of the next table jump
  logic drop_q, drop_d;

  assign ypb_zcmt_req_o.cacheable = config_pkg::is_inside_cacheable_regions(
      CVA6Cfg, {{64 - CVA6Cfg.PLEN{1'b0}}, ypb_zcmt_req_o.paddr}  //TO DO CHECK GRANULARITY
  );
  assign ypb_zcmt_req_o.bufferable = config_pkg::is_inside_bufferable_regions(
      CVA6Cfg, {{64 - CVA6Cfg.PLEN{1'b0}}, ypb_zcmt_req_o.paddr}
  );
  assign ypb_zcmt_req_o.access_type = 1'b1;  //1 = data

  always_comb begin
    state_d                 = state_q;
    illegal_instr_o         = 1'b0;
    instr_o                 = instr_i;
    is_compressed_o         = is_zcmt_instr_i || is_compressed_i;
    fetch_stall_o           = '0;
    jump_address_o          = '0;  // cache request port
    req_addr_d              = req_addr_q;
    drop_d                  = drop_q;
    ypb_zcmt_req_o.paddr    = CVA6Cfg.PLEN'(req_addr_q);
    ypb_zcmt_req_o.preq     = 1'b0;
    ypb_zcmt_req_o.we       = 1'b0;
    // One XLEN-bit table entry
    ypb_zcmt_req_o.be       = '1;
    ypb_zcmt_req_o.size     = CVA6Cfg.IS_XLEN64 ? 2'b11 : 2'b10;
    ypb_zcmt_req_o.wdata    = '0;
    ypb_zcmt_req_o.rready   = '1;
    ypb_zcmt_req_o.aid      = 1'b0;
    ypb_zcmt_req_o.kill_req = 1'b0;
    ypb_zcmt_req_o.vreq     = 1'b0;
    ypb_zcmt_req_o.atop     = ariane_pkg::AMO_NONE;
    ypb_zcmt_req_o.cbo_op   = ariane_pkg::CBO_NONE;
    unique case (state_q)
      IDLE: begin
        fetch_stall_o = 1'b0;
        ypb_zcmt_req_o.preq = 1'b0;
        if (is_zcmt_instr_i) begin
          // table_address = jvt.base + (index << log2(XLEN/8))
          req_addr_d = {jvt_i.base, 6'b000000} +
              (CVA6Cfg.IS_XLEN64 ? CVA6Cfg.VLEN'({instr_i[9:2], 3'b000}) :
                                   CVA6Cfg.VLEN'({instr_i[9:2], 2'b00}));
          ypb_zcmt_req_o.paddr = CVA6Cfg.PLEN'(req_addr_d);
          ypb_zcmt_req_o.preq = 1'b1;  // Always assert req
          fetch_stall_o = 1'b1;
          drop_d = flush_i;
          if (!ypb_zcmt_rsp_i.pgnt) begin
            state_d = TABLE_WAIT_GNT;
          end else begin
            state_d = TABLE_WAIT_RVALID;
          end
        end else begin
          illegal_instr_o = illegal_instr_i;
          instr_o = instr_i;
          state_d = IDLE;
        end
      end

      TABLE_WAIT_GNT: begin
        fetch_stall_o = 1'b1;
        // The request stays asserted until granted, even on a flush
        ypb_zcmt_req_o.preq = 1'b1;
        if (flush_i) begin
          drop_d = 1'b1;
        end
        if (ypb_zcmt_rsp_i.pgnt) begin
          state_d = TABLE_WAIT_RVALID;
        end
      end

      TABLE_WAIT_RVALID: begin
        ypb_zcmt_req_o.preq = 1'b0;
        if (ypb_zcmt_rsp_i.rvalid && drop_q) begin
          // Response of a flushed instruction: drop it and keep the fetch
          // stalled for this cycle
          fetch_stall_o = 1'b1;
          drop_d = 1'b0;
          state_d = IDLE;
        end else if (ypb_zcmt_rsp_i.rvalid) begin
          // Clear bit 0 of the JVT target before converting it to a PC-relative offset.
          jump_address_o =
              $unsigned($signed({ypb_zcmt_rsp_i.rdata[CVA6Cfg.XLEN-1:1], 1'b0}) - $signed(pc_i));
          if (instr_i[9:2] < 32) begin
            // jal pc_offset, x0 for no return stack
            instr_o = {20'h0, 5'h0, riscv::OpcodeJal};
          end else if ((instr_i[9:2] >= 32) && (instr_i[9:2] <= 255)) begin
            // jal pc_offset, x1 for return stack
            instr_o = {20'h0, 5'h1, riscv::OpcodeJal};
          end else begin
            illegal_instr_o = 1'b1;
            instr_o = instr_i;
          end
          fetch_stall_o = 1'b0;
          state_d = IDLE;
        end else begin
          fetch_stall_o = 1'b1;
          if (flush_i) begin
            drop_d = 1'b1;
          end
          state_d = TABLE_WAIT_RVALID;
        end

      end

      default: begin
        state_d = IDLE;
      end
    endcase
  end
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      state_q <= IDLE;
      req_addr_q <= '0;
      drop_q <= 1'b0;
    end else begin
      state_q <= state_d;
      req_addr_q <= req_addr_d;
      drop_q <= drop_d;
    end
  end
endmodule
