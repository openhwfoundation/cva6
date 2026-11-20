// Copyright 2024 Thales DIS France SAS
//
// Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
// You may obtain a copy of the License at https://solderpad.org/licenses/
//
// Original Author: Guillaume Chauvon

`include "utils_macros.svh"

module instr_decoder #(
    parameter type               copro_issue_resp_t          = logic,
    parameter type               opcode_t                    = logic,
    parameter int                NbInstr                     = 1,
    parameter copro_issue_resp_t CoproInstr        [NbInstr] = {0},
    parameter int unsigned       NrRgprPorts                 = 2,
    parameter type               hartid_t                    = logic,
    parameter type               id_t                        = logic,
    parameter type               x_issue_req_t               = logic,
    parameter type               x_issue_resp_t              = logic,
    parameter type               x_register_t                = logic,
    parameter type               registers_t                 = logic
) (
    input  logic                clk_i,
    input  logic                rst_ni,
    input  logic                issue_valid_i,
    input  x_issue_req_t        issue_req_i,
    output logic                issue_ready_o,
    output x_issue_resp_t       issue_resp_o,
    input  logic                register_valid_i,
    input  x_register_t         register_i,
    output registers_t          registers_o,
    output opcode_t             opcode_o,
    output hartid_t             hartid_o,
    output id_t                 id_o,
    output logic          [4:0] rd_o
);

  logic [NbInstr-1:0] sel;
  logic rs1_ready;
  logic rs2_ready;
  logic rs3_ready;

  for (genvar i = 0; i < NbInstr; i++) begin : gen_predecoder_selector
    assign sel[i] = ((CoproInstr[i].mask & issue_req_i.instr) == CoproInstr[i].instr);
  end

  always_comb begin
    rs1_ready                  = '0;
    rs2_ready                  = '0;
    rs3_ready                  = '0;
    issue_ready_o              = '0;
    issue_resp_o.accept        = '0;
    issue_resp_o.writeback     = '0;
    issue_resp_o.register_read = '0;
    registers_o                = '0;
    opcode_o                   = opcode_t'(0);  // == ILLEGAL see cvxif_instr_pkg.sv
    hartid_o                   = '0;
    id_o                       = '0;
    rd_o                       = '0;
    for (int unsigned i = 0; i < NbInstr; i++) begin
      if (sel[i] && issue_valid_i) begin
        issue_resp_o.accept = CoproInstr[i].resp.accept;
        issue_resp_o.writeback = CoproInstr[i].resp.writeback;
        issue_resp_o.register_read = CoproInstr[i].resp.register_read; // Warning :  potential 3 bits vector into 2 bits one
        if (issue_resp_o.accept) begin
          rs1_ready = (~CoproInstr[i].resp.register_read[0] || register_i.rs_valid[0]);
          rs2_ready = (~CoproInstr[i].resp.register_read[1] || register_i.rs_valid[1]);
          rs3_ready = NrRgprPorts == 3 ? (~CoproInstr[i].resp.register_read[2] || register_i.rs_valid[2]) : 1'b1;
          issue_ready_o = rs1_ready && rs2_ready && rs3_ready;
        end
        opcode_o = CoproInstr[i].opcode;
        id_o     = issue_req_i.id;
        hartid_o = issue_req_i.hartid;
        rd_o     = issue_req_i.instr[11:7];
        for (int unsigned j = 0; j < NrRgprPorts; j++) begin
          registers_o[j] = issue_resp_o.register_read[j] ? register_i.rs[j] : '0;
        end
      end
    end
    // Coprocessor could not decode offloaded instruction -> instruction is not accepted
    if (issue_valid_i && ~(|sel)) begin
      issue_ready_o = 1'b1;
    end
  end

  assert property (@(posedge clk_i) $onehot0(sel))
  else
    `ASSERT_WARNING("This offloaded instruction is valid for multiple coprocessor instructions !");

endmodule
