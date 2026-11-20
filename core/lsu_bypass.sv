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
// Date: 19.04.2017
// Description: Load Store Unit, handles address calculation and memory interface signals


// ------------------
// LSU Control
// ------------------
// The LSU consists of two independent blocks which share a common address translation block.
// One block is the load unit, the other one is the store unit. They will signal their readiness
// with separate signals. If they are not ready the LSU control should keep the last applied signals stable.
// Furthermore it can be the case that another request for one of the two store units arrives in which case
// the LSU control should sample it and store it for later application to the units. It does so, by storing it in a
// two element FIFO. This is necessary as we only know very late in the cycle whether the load/store will succeed (address check,
// TLB hit mainly). So we better unconditionally allow another request to arrive and store this request in case we need to.
module lsu_bypass
  import ariane_pkg::*;
#(
    parameter config_pkg::cva6_cfg_t CVA6Cfg = config_pkg::cva6_cfg_empty,
    parameter type lsu_ctrl_t = logic
) (
    // Subsystem Clock - SUBSYSTEM
    input logic clk_i,
    // Asynchronous reset active low - SUBSYSTEM
    input logic rst_ni,
    // Flush - CONTROLLER
    input logic flush_i,

    // Load store unit request - LSU_UNIT
    input lsu_ctrl_t lsu_req_i,
    // load store unit valid - LSU_UNIT
    input logic      lsu_req_valid_i,
    // Pop load - LOAD_UNIT
    input logic      pop_ld_i,
    // Pop store - STORE_UNIT
    input logic      pop_st_i,

    // RVFI information - RVFI
    output lsu_ctrl_t lsu_ctrl_o,
    // Load Store Unit is ready - ISSUE_STAGE
    output logic      ready_o
);

  lsu_ctrl_t [1:0] mem_n, mem_q;
  logic read_pointer_n, read_pointer_q;
  logic write_pointer_n, write_pointer_q;
  logic [1:0] status_cnt_n, status_cnt_q;

  logic empty;
  assign empty   = (status_cnt_q == 0);
  assign ready_o = empty;

  always_comb begin
    automatic logic [1:0] status_cnt;
    automatic logic write_pointer;
    automatic logic read_pointer;

    status_cnt = status_cnt_q;
    write_pointer = write_pointer_q;
    read_pointer = read_pointer_q;

    mem_n = mem_q;
    // we've got a valid LSU request
    if (lsu_req_valid_i) begin
      mem_n[write_pointer_q] = lsu_req_i;
      write_pointer++;
      status_cnt++;
    end

    if (pop_ld_i) begin
      // invalidate the result
      mem_n[read_pointer_q].valid = 1'b0;
      read_pointer++;
      status_cnt--;
    end

    if (pop_st_i) begin
      // invalidate the result
      mem_n[read_pointer_q].valid = 1'b0;
      read_pointer++;
      status_cnt--;
    end

    if (pop_st_i && pop_ld_i) mem_n = '0;

    if (flush_i) begin
      status_cnt = '0;
      write_pointer = '0;
      read_pointer = '0;
      mem_n = '0;
    end
    // default assignments
    read_pointer_n  = read_pointer;
    write_pointer_n = write_pointer;
    status_cnt_n    = status_cnt;
  end

  // output assignment
  always_comb begin : output_assignments
    if (empty) begin
      lsu_ctrl_o = lsu_req_i;
    end else begin
      lsu_ctrl_o = mem_q[read_pointer_q];
    end
  end

  // registers
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      mem_q           <= '0;
      status_cnt_q    <= '0;
      write_pointer_q <= '0;
      read_pointer_q  <= '0;
    end else begin
      mem_q           <= mem_n;
      status_cnt_q    <= status_cnt_n;
      write_pointer_q <= write_pointer_n;
      read_pointer_q  <= read_pointer_n;
    end
  end
endmodule

