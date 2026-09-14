//Copyright (C) 2018 to present,
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 2.0 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-2.0. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// Author: Florian Zaruba, ETH Zurich
// Date: 08.02.2018
// Migrated: Luis Vitorio Cargnini, IEEE
// Date: 09.06.2018

// return address stack
//
// The stack is updated at predecode time in the frontend, i.e. under an
// arbitrary number of unresolved branches. Entries that are pushed while a
// branch is unresolved are tagged speculative; the index of the stack at
// the point speculation started is checkpointed so that the stack can be
// rewound when the branch turns out to be mispredicted or when the pipeline is
// flushed. The speculative tags are cleared when a resolved branch is
// correctly predicted, which turns the entries architectural.
//
// Because the rewind has to move the index back up as well as down, the 
// storage is a circular buffer indexed by a pointer rather than a stack 
// register (a pop no longer destroys the entry it removes).
module ras #(
    parameter config_pkg::cva6_cfg_t CVA6Cfg = config_pkg::cva6_cfg_empty,
    parameter type ras_t = logic
) (
    // Subsystem Clock - SUBSYSTEM
    input logic clk_i,
    // Asynchronous reset active low - SUBSYSTEM
    input logic rst_ni,
    // Branch prediction flush request - zero
    input logic flush_bp_i,
    // Pipeline flush - CONTROLLER
    input logic flush_i,
    // The update presented this cycle is issued under an unresolved branch - FRONTEND
    input logic speculative_i,
    // A branch resolved and was correctly predicted - EXECUTE
    input logic predict_i,
    // A branch resolved and was mispredicted - EXECUTE
    input logic mispredict_i,
    // Push address in RAS - FRONTEND
    input logic push_i,
    // Pop address from RAS - FRONTEND
    input logic pop_i,
    // Data to be pushed - FRONTEND
    input logic [CVA6Cfg.VLEN-1:0] addr_i,
    // Popped data - FRONTEND
    output ras_t addr_o
);

  localparam int unsigned RASDepth = CVA6Cfg.RASDepth;
  localparam int unsigned PtrWidth = (RASDepth <= 1) ? 1 : $clog2(RASDepth);
  localparam int unsigned CntrWidth = $clog2(RASDepth + 1);

  localparam type ptr_t = logic [PtrWidth-1:0];
  localparam type cntr_t = logic [CntrWidth-1:0];

  // state of the stack at the point it became speculative
  localparam type chkpt_t = struct packed {
    logic  valid;
    ptr_t  ptr;
    cntr_t cnt;
    ras_t  top;
  };

  localparam ptr_t RASTop = PtrWidth'(RASDepth - 1);

  ras_t [RASDepth-1:0] stack_d, stack_q;

  // one speculative tag per entry
  logic [RASDepth-1:0] spec_d, spec_q;

  // index of the entry currently on top of the stack, only meaningful when cnt_q != 0
  // it is reset to RASDepth-1 so that the first push lands on 0
  ptr_t top_ptr_d, top_ptr_q;

  // number of live entries
  cntr_t cnt_d, cnt_q;

  chkpt_t chkpt_d, chkpt_q;

  function automatic ptr_t nxt_ptr(input ptr_t p);
    nxt_ptr = (p == RASTop) ? '0 : (p + PtrWidth'(1));
  endfunction

  function automatic ptr_t prv_ptr(input ptr_t p);
    prv_ptr = (p == '0) ? RASTop : (p - PtrWidth'(1));
  endfunction

  logic squash, update;

  // a mispredict and a pipeline flush both kill everything the frontend speculated on
  assign squash = mispredict_i | flush_i;
  // anything the predecoder presents in the squash cycle is itself on the killed path
  assign update = ~squash;

  always_comb begin
    automatic ptr_t  ptr;
    automatic cntr_t cnt;

    // state before this cycle's push/pop, used to arm a new checkpoint
    automatic ptr_t  base_ptr;
    automatic cntr_t base_cnt;
    automatic ras_t  base_top;

    stack_d = stack_q;
    spec_d  = spec_q;

    if (squash) begin
      // discard every entry that was pushed under the unresolved branch
      for (int unsigned i = 0; i < RASDepth; i++) begin
        if (spec_q[i]) begin
          stack_d[i].valid = 1'b0;
          stack_d[i].ra    = '0;
        end
      end
      spec_d = '0;
    end else if (predict_i) begin
      // the branch was correctly predicted, so everything pushed under it is architectural from now on
      spec_d = '0;
    end

    // restore the index to where the stack stood when speculation started
    if (squash && chkpt_q.valid) begin
      base_ptr = chkpt_q.ptr;
      base_cnt = chkpt_q.cnt;
      base_top = chkpt_q.top;
      // put back the entry that was on top, it may have been overwritten
      stack_d[chkpt_q.ptr] = chkpt_q.top;
      spec_d[chkpt_q.ptr] = 1'b0;
    end else begin
      base_ptr = top_ptr_q;
      base_cnt = cnt_q;
      base_top = stack_q[top_ptr_q];
    end

    ptr = base_ptr;
    cnt = base_cnt;

    if (update) begin
      if (push_i && pop_i) begin
        // a call and a return in the same fetch group
        // the depth is unchanged, only the top of stack is replaced
        if (cnt == '0) begin
          ptr = nxt_ptr(ptr);
          cnt = cnt + CntrWidth'(1);
        end
        stack_d[ptr].ra    = addr_i;
        stack_d[ptr].valid = 1'b1;
        spec_d[ptr]        = speculative_i;
      end else if (push_i) begin
        ptr                = nxt_ptr(ptr);
        stack_d[ptr].ra    = addr_i;
        stack_d[ptr].valid = 1'b1;
        spec_d[ptr]        = speculative_i;
        // on overflow the oldest entry is silently overwritten
        if (cnt != CntrWidth'(RASDepth)) cnt = cnt + CntrWidth'(1);
      end else if (pop_i) begin
        if (cnt != '0) begin
          ptr = prv_ptr(ptr);
          cnt = cnt - CntrWidth'(1);
        end
      end
    end

    chkpt_d = chkpt_q;

    // the checkpoint is consumed by whatever ends the speculation
    if (squash || predict_i) chkpt_d.valid = 1'b0;

    // arm a new one on the first cycle the stack is touched speculatively
    if (speculative_i && !chkpt_d.valid) begin
      chkpt_d.valid = 1'b1;
      chkpt_d.ptr   = base_ptr;
      chkpt_d.cnt   = base_cnt;
      chkpt_d.top   = base_top;
    end

    top_ptr_d = ptr;
    cnt_d     = cnt;

    if (flush_bp_i) begin
      stack_d       = '0;
      spec_d        = '0;
      top_ptr_d     = RASTop;
      cnt_d         = '0;
      chkpt_d.valid = 1'b0;
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      stack_q   <= '0;
      spec_q    <= '0;
      top_ptr_q <= RASTop;
      cnt_q     <= '0;
      chkpt_q   <= '0;
    end else begin
      stack_q   <= stack_d;
      spec_q    <= spec_d;
      top_ptr_q <= top_ptr_d;
      cnt_q     <= cnt_d;
      chkpt_q   <= chkpt_d;
    end
  end

  // the prediction is only valid if the stack is non-empty
  assign addr_o.ra    = stack_q[top_ptr_q].ra;
  assign addr_o.valid = stack_q[top_ptr_q].valid & (cnt_q != '0);

endmodule
