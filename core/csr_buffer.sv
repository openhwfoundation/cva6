// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// Author: Florian Zaruba, ETH Zurich
// Date: 05.05.2017
// Description: Buffer to hold CSR address, this acts like a functional unit
//              to the scoreboard.


module csr_buffer
  import ariane_pkg::*;
#(
    parameter config_pkg::cva6_cfg_t CVA6Cfg = config_pkg::cva6_cfg_empty,
    parameter type fu_data_t = logic
) (
    // Subsystem Clock - SUBSYSTEM
    input logic clk_i,
    // Asynchronous reset active low - SUBSYSTEM
    input logic rst_ni,
    // Flush CSR - CONTROLLER
    input logic flush_i,
    // FU data needed to execute instruction - ISSUE_STAGE
    input fu_data_t fu_data_i,
    // CSR FU is ready - ISSUE_STAGE
    output logic csr_ready_o,
    // CSR instruction is valid - ISSUE_STAGE
    input logic csr_valid_i,
    // CSR buffer result - ISSUE_STAGE
    output logic [CVA6Cfg.XLEN-1:0] csr_result_o,
    // commit the pending CSR OP - COMMIT_STAGE
    input logic csr_commit_i,
    // CSR address to write - COMMIT_STAGE
    output logic [11:0] csr_addr_o
);
  // this is a single entry store buffer for the address of the CSR
  // which we are going to need in the commit stage
  struct packed {
    logic [11:0] csr_address;
    logic        valid;
  }
      csr_reg_n, csr_reg_q;

  // control logic, scoreboard signals
  assign csr_result_o = fu_data_i.operand_a;
  assign csr_addr_o   = csr_reg_q.csr_address;

  // write logic
  always_comb begin : write
    csr_reg_n   = csr_reg_q;
    // by default we are ready
    csr_ready_o = 1'b1;
    // if we have a valid uncommitted csr req or are just getting one WITHOUT a commit in, we are not ready
    if ((csr_reg_q.valid || csr_valid_i) && ~csr_commit_i) csr_ready_o = 1'b0;
    // if we got a valid from the scoreboard
    // store the CSR address
    if (csr_valid_i) begin
      csr_reg_n.csr_address = fu_data_i.operand_b[11:0];
      csr_reg_n.valid       = 1'b1;
    end
    // if we get a commit and no new valid instruction -> clear the valid bit
    if (csr_commit_i && ~csr_valid_i) begin
      csr_reg_n.valid = 1'b0;
    end
    // clear the buffer if we flushed
    if (flush_i) csr_reg_n.valid = 1'b0;
  end
  // sequential process
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      csr_reg_q <= '{default: 0};
    end else begin
      csr_reg_q <= csr_reg_n;
    end
  end

endmodule
