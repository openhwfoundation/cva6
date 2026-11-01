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
// Date: 08.04.2017
// Description: Scoreboard - keeps track of all decoded, issued and committed instructions

`include "utils_macros.svh"

module scoreboard #(
    parameter config_pkg::cva6_cfg_t CVA6Cfg = config_pkg::cva6_cfg_empty,
    parameter type bp_resolve_t = logic,
    parameter type exception_t = logic,
    parameter type scoreboard_entry_t = logic,
    parameter type forwarding_t = logic,
    parameter type writeback_t = logic,
    parameter type rs3_len_t = logic
) (
    // Subsystem Clock - SUBSYSTEM
    input  logic                                          clk_i,
    // Asynchronous reset active low - SUBSYSTEM
    input  logic                                          rst_ni,
    // Is scoreboard full - PERF_COUNTERS
    output logic                                          sb_full_o,
    // Prevent from issuing - CONTROLLER
    input  logic                                          flush_unissued_instr_i,
    // Flush whole scoreboard - CONTROLLER
    input  logic                                          flush_i,
    // Writeback Handling of CVXIF
    // CVXIF trasaction accepted - ISSUE_READ_OPERANDS
    input  logic                                          x_transaction_accepted_i,
    // CVXIF Issue writeback - ISSUE_READ_OPERANDS
    input  logic                                          x_issue_writeback_i,
    // CVXIF ID - ISSUE_READ_OPERANDS
    input  logic              [CVA6Cfg.TRANS_ID_BITS-1:0] x_id_i,
    // advertise instruction to commit stage, if commit_ack_i is asserted advance the commit pointer
    // Instructions to commit - COMMIT_STAGE
    output scoreboard_entry_t [CVA6Cfg.NrCommitPorts-1:0] commit_instr_o,
    // Instruction is cancelled - COMMIT_STAGE
    output logic              [CVA6Cfg.NrCommitPorts-1:0] commit_drop_o,
    // Commit acknowledge - COMMIT_STAGE
    input  logic              [CVA6Cfg.NrCommitPorts-1:0] commit_ack_i,

    // instruction to put on top of scoreboard e.g.: top pointer
    // we can always put this instruction to the top unless we signal with asserted full_o
    // Handshake's data with decode stage - ID_STAGE
    input  scoreboard_entry_t [CVA6Cfg.NrIssuePorts-1:0]       decoded_instr_i,
    // instruction value - ID_STAGE
    input  logic              [CVA6Cfg.NrIssuePorts-1:0][31:0] orig_instr_i,
    // Handshake's valid with decode stage - ID_STAGE
    input  logic              [CVA6Cfg.NrIssuePorts-1:0]       decoded_instr_valid_i,
    // Handshake's acknowledge with decode stage - ID_STAGE
    output logic              [CVA6Cfg.NrIssuePorts-1:0]       decoded_instr_ack_o,

    // instruction to issue logic, if issue_instr_valid and issue_ready is asserted, advance the issue pointer
    // Entry about the instruction to issue - ISSUE_READ_OPERANDS
    output scoreboard_entry_t [CVA6Cfg.NrIssuePorts-1:0]       issue_instr_o,
    // Instruction to issue - ISSUE_READ_OPERANDS
    output logic              [CVA6Cfg.NrIssuePorts-1:0][31:0] orig_instr_o,
    // Is there an instruction to issue - ISSUE_READ_OPERANDS
    output logic              [CVA6Cfg.NrIssuePorts-1:0]       issue_instr_valid_o,
    // Issue stage acknowledge - ISSUE_READ_OPERANDS
    input  logic              [CVA6Cfg.NrIssuePorts-1:0]       issue_ack_i,
    // Forwarding - ISSUE_READ_OPERANDS
    output forwarding_t                                        fwd_o,

    // Result from branch unit - EX_STAGE
    input bp_resolve_t resolved_branch_i,
    // Transaction ID at which to write the result back - EX_STAGE
    input logic [CVA6Cfg.NrWbPorts-1:0][CVA6Cfg.TRANS_ID_BITS-1:0] trans_id_i,
    // Results to write back - EX_STAGE
    input logic [CVA6Cfg.NrWbPorts-1:0][CVA6Cfg.XLEN-1:0] wbdata_i,
    // Exception from a functional unit (e.g.: ld/st exception) - EX_STAGE
    input exception_t [CVA6Cfg.NrWbPorts-1:0] ex_i,
    // Indicates valid results - EX_STAGE
    input logic [CVA6Cfg.NrWbPorts-1:0] wt_valid_i,
    // Cvxif we for writeback - EX_STAGE
    input logic x_we_i,
    // CVXIF destination register - ISSUE_STAGE
    input logic [4:0] x_rd_i,

    // Issue pointer - RVFI
    output logic [ CVA6Cfg.NrIssuePorts-1:0][CVA6Cfg.TRANS_ID_BITS-1:0] rvfi_issue_pointer_o,
    // Commit pointer - RVFI
    output logic [CVA6Cfg.NrCommitPorts-1:0][CVA6Cfg.TRANS_ID_BITS-1:0] rvfi_commit_pointer_o
);

  // this is the FIFO struct of the issue queue
  typedef struct packed {
    logic issued;  // this bit indicates whether we issued this instruction e.g.: if it is valid
    logic cancelled;  // this instruction was cancelled (speculative scoreboard)
    logic is_rd_fpr_flag;  // redundant meta info, added for speed
    scoreboard_entry_t sbe;  // this is the score board entry we will send to ex
  } sb_mem_t;
  sb_mem_t [CVA6Cfg.NR_SB_ENTRIES-1:0] mem_q, mem_n;
  logic [CVA6Cfg.NR_SB_ENTRIES-1:0] still_issued;

  logic [CVA6Cfg.NrIssuePorts-1:0] issue_full;
  logic [1:0][CVA6Cfg.NR_SB_ENTRIES/2-1:0] issued_instrs_even_odd;

  logic bmiss;
  logic [CVA6Cfg.TRANS_ID_BITS-1:0] after_flu_wb;
  logic [CVA6Cfg.NR_SB_ENTRIES-1:0] speculative_instrs;

  logic [CVA6Cfg.NrIssuePorts-1:0] num_issue;
  logic [CVA6Cfg.TRANS_ID_BITS-1:0] issue_pointer_n, issue_pointer_q;
  logic [CVA6Cfg.NrIssuePorts:0][CVA6Cfg.TRANS_ID_BITS-1:0] issue_pointer;

  logic [CVA6Cfg.NrCommitPorts-1:0][CVA6Cfg.TRANS_ID_BITS-1:0] commit_pointer_n, commit_pointer_q;
  logic [$clog2(CVA6Cfg.NrCommitPorts):0] num_commit;

  for (genvar i = 0; i < CVA6Cfg.NR_SB_ENTRIES; i++) begin
    assign still_issued[i] = mem_q[i].issued & ~(CVA6Cfg.SpeculativeSb & mem_q[i].cancelled);
  end

  for (genvar i = 0; i < CVA6Cfg.NR_SB_ENTRIES; i++) begin
    assign issued_instrs_even_odd[i%2][i/2] = mem_q[i].issued;
  end

  // the issue queue is full don't issue any new instructions
  assign issue_full[0] = &issued_instrs_even_odd[0] && &issued_instrs_even_odd[1];
  if (CVA6Cfg.SuperscalarEn) begin : assign_issue_full
    // Need two slots available to issue two instructions.
    // They are next to each other so one must be even and one odd
    assign issue_full[1] = &issued_instrs_even_odd[0] || &issued_instrs_even_odd[1];
  end

  assign sb_full_o = issue_full[0];

  // output commit instruction directly
  always_comb begin : commit_ports
    for (int unsigned i = 0; i < CVA6Cfg.NrCommitPorts; i++) begin
      commit_instr_o[i] = mem_q[commit_pointer_q[i]].sbe;
      commit_instr_o[i].trans_id = commit_pointer_q[i];
      commit_drop_o[i] = mem_q[commit_pointer_q[i]].cancelled;
    end
  end

  assign issue_pointer[0] = issue_pointer_q;
  for (genvar i = 0; i < CVA6Cfg.NrIssuePorts; i++) begin
    assign issue_pointer[i+1] = issue_pointer[i] + 'd1;
  end

  // an instruction is ready for issue if we have place in the issue FIFO and the decoder says it is valid
  always_comb begin
    issue_instr_o = decoded_instr_i;
    orig_instr_o  = orig_instr_i;
    for (int unsigned i = 0; i < CVA6Cfg.NrIssuePorts; i++) begin
      // make sure we assign the correct trans ID
      issue_instr_o[i].trans_id = issue_pointer[i];

      issue_instr_valid_o[i]    = decoded_instr_valid_i[i] & ~issue_full[i];
      decoded_instr_ack_o[i]    = issue_ack_i[i] & ~issue_full[i];
    end
  end

  // maintain a FIFO with issued instructions
  // keep track of all issued instructions
  always_comb begin : issue_fifo
    // default assignment
    mem_n     = mem_q;
    num_issue = '0;

    // if we got an acknowledge from the issue stage, put this scoreboard entry in the queue
    for (int unsigned i = 0; i < CVA6Cfg.NrIssuePorts; i++) begin
      if (decoded_instr_valid_i[i] && decoded_instr_ack_o[i] && !flush_unissued_instr_i) begin
        // the decoded instruction we put in there is valid (1st bit)
        // increase the issue counter and advance issue pointer
        num_issue += 'd1;
        mem_n[issue_pointer[i]] = '{
            issued: 1'b1,
            cancelled: 1'b0,
            is_rd_fpr_flag: CVA6Cfg.FpPresent && ariane_pkg::is_rd_fpr(decoded_instr_i[i].op),
            sbe: decoded_instr_i[i]
        };
      end
    end

    // ------------
    // FU NONE
    // ------------
    for (int unsigned i = 0; i < CVA6Cfg.NR_SB_ENTRIES; i++) begin
      // The FU is NONE -> this instruction is valid immediately
      if (mem_q[i].sbe.fu == ariane_pkg::NONE && mem_q[i].issued) mem_n[i].sbe.valid = 1'b1;
      // A cancelled first Zcmp micro-op is only marked valid by its last one,
      // which the branch miss kept from issuing: mark it valid so that the
      // commit stage drops it.
      if (CVA6Cfg.SpeculativeSb && CVA6Cfg.RVZCMP && mem_q[i].issued && mem_q[i].cancelled &&
          mem_q[i].sbe.is_macro_instr && !mem_q[i].sbe.is_last_macro_instr)
        mem_n[i].sbe.valid = 1'b1;
    end

    // ------------
    // Write Back
    // ------------
    for (int unsigned i = 0; i < CVA6Cfg.NrWbPorts; i++) begin
      // check if this instruction was issued (e.g.: it could happen after a flush that there is still
      // something in the pipeline e.g. an incomplete memory operation)
      if (wt_valid_i[i] && mem_q[trans_id_i[i]].issued) begin
        if (CVA6Cfg.RVZCMP && mem_q[trans_id_i[i]].sbe.is_double_rd_macro_instr && mem_q[trans_id_i[i]].sbe.is_macro_instr) begin
          if (mem_q[trans_id_i[i]].sbe.is_last_macro_instr) begin
            mem_n[trans_id_i[i]].sbe.valid = 1'b1;
            // The first micro-op is the entry just before this one, wrapping
            // from entry 0 to the last one.
            mem_n[CVA6Cfg.TRANS_ID_BITS'(trans_id_i[i]-1'b1)].sbe.valid = 1'b1;
          end
          // The first micro-op waits for the last one, which marks both
          // valid: it is left as is, as the last one may have written back
          // in this same cycle on another port.
        end else begin
          mem_n[trans_id_i[i]].sbe.valid = 1'b1;
        end
        mem_n[trans_id_i[i]].sbe.result = wbdata_i[i];
        // save the target address of a branch (needed for debug in commit stage)
        if (CVA6Cfg.DebugEn) begin
          mem_n[trans_id_i[i]].sbe.bp.predict_address = resolved_branch_i.target_address;
        end
        if (mem_n[trans_id_i[i]].sbe.fu == ariane_pkg::CVXIF) begin
          if (x_we_i) mem_n[trans_id_i[i]].sbe.rd = x_rd_i;
          else mem_n[trans_id_i[i]].sbe.rd = 5'b0;
        end
        // write the exception back if it is valid, or if it is a load data trigger
        // break (timing set, valid clear), which lands on the next instruction
        if (ex_i[i].valid || ex_i[i].timing) mem_n[trans_id_i[i]].sbe.ex = ex_i[i];
        // write the fflags back from the FPU (exception valid is never set), leave tval intact
        else if(CVA6Cfg.FpPresent && (mem_q[trans_id_i[i]].sbe.fu == ariane_pkg::FPU || mem_q[trans_id_i[i]].sbe.fu == ariane_pkg::FPU_VEC)) begin
          mem_n[trans_id_i[i]].sbe.ex.cause = ex_i[i].cause;
        end
      end
    end

    // ------------
    // Cancel
    // ------------
    if (CVA6Cfg.SpeculativeSb) begin
      if (bmiss) begin
        if (after_flu_wb != issue_pointer[0]) begin
          mem_n[after_flu_wb].cancelled = 1'b1;
        end
      end
    end

    // ------------
    // Commit Port
    // ------------
    // we've got an acknowledge from commit
    for (int i = 0; i < CVA6Cfg.NrCommitPorts; i++) begin
      if (commit_ack_i[i]) begin
        // this instruction is no longer in issue e.g.: it is considered finished
        mem_n[commit_pointer_q[i]].issued    = 1'b0;
        mem_n[commit_pointer_q[i]].cancelled = 1'b0;
        mem_n[commit_pointer_q[i]].sbe.valid = 1'b0;
      end
    end

    // ------
    // Flush
    // ------
    if (flush_i) begin
      for (int unsigned i = 0; i < CVA6Cfg.NR_SB_ENTRIES; i++) begin
        // set all valid flags for all entries to zero
        mem_n[i].issued       = 1'b0;
        mem_n[i].cancelled    = 1'b0;
        mem_n[i].sbe.valid    = 1'b0;
        mem_n[i].sbe.ex.valid = 1'b0;
      end
    end
  end

  assign bmiss = resolved_branch_i.is_mispredict;
  assign after_flu_wb = trans_id_i[ariane_pkg::FLU_WB] + 'd1;

  // FIFO counter updates
  if (CVA6Cfg.NrCommitPorts == 2) begin : gen_commit_ports
    assign num_commit = commit_ack_i[1] + commit_ack_i[0];
  end else begin : gen_one_commit_port
    assign num_commit = commit_ack_i[0];
  end

  assign commit_pointer_n[0] = (flush_i) ? '0 : commit_pointer_q[0] + CVA6Cfg.TRANS_ID_BITS'(num_commit);

  always_comb begin : assign_issue_pointer_n
    issue_pointer_n = issue_pointer[num_issue];
    if (flush_i) issue_pointer_n = '0;
  end

  // precompute offsets for commit slots
  for (genvar k = 1; k < CVA6Cfg.NrCommitPorts; k++) begin : gen_cnt_incr
    assign commit_pointer_n[k] = (flush_i) ? '0 : commit_pointer_n[0] + unsigned'(k);
  end

  // Forwarding logic
  writeback_t [CVA6Cfg.NrWbPorts-1:0] wb;
  for (genvar i = 0; i < CVA6Cfg.NrWbPorts; i++) begin
    assign wb[i].valid = wt_valid_i[i];
    assign wb[i].data = wbdata_i[i];
    assign wb[i].ex_valid = ex_i[i].valid;
    assign wb[i].trans_id = trans_id_i[i];
  end

  assign fwd_o.still_issued = still_issued;
  assign fwd_o.issue_pointer = issue_pointer[0];
  assign fwd_o.wb = wb;
  for (genvar i = 0; i < CVA6Cfg.NR_SB_ENTRIES; i++) begin
    assign fwd_o.sbe[i] = mem_q[i].sbe;
  end

  // sequential process
  always_ff @(posedge clk_i or negedge rst_ni) begin : regs
    if (!rst_ni) begin
      mem_q            <= '{default: sb_mem_t'(0)};
      commit_pointer_q <= '0;
      issue_pointer_q  <= '0;
    end else begin
      issue_pointer_q <= issue_pointer_n;
      mem_q <= mem_n;
      mem_q[x_id_i].sbe.rd <= (x_transaction_accepted_i && ~x_issue_writeback_i) ? 5'b0 : mem_n[x_id_i].sbe.rd;
      commit_pointer_q <= commit_pointer_n;
    end
  end

  //RVFI
  assign rvfi_issue_pointer_o  = issue_pointer[CVA6Cfg.NrIssuePorts-1:0];
  assign rvfi_commit_pointer_o = commit_pointer_q;

  //pragma translate_off
  initial begin
    assert (CVA6Cfg.NR_SB_ENTRIES == 2 ** CVA6Cfg.TRANS_ID_BITS)
    else `ASSERT_FATAL("Scoreboard size needs to be a power of two.");
  end
  // assert that we never acknowledge a commit if the instruction is not valid
  assert property (
    @(posedge clk_i) disable iff (!rst_ni) commit_ack_i[0] |-> commit_instr_o[0].valid)
  else `ASSERT_FATAL("Commit acknowledged but instruction is not valid");
  if (CVA6Cfg.NrCommitPorts == 2) begin : gen_two_commit_ports
    assert property (
        @(posedge clk_i) disable iff (!rst_ni) commit_ack_i[1] |-> commit_instr_o[1].valid)
    else `ASSERT_FATAL("Commit acknowledged but instruction is not valid");
  end
  // assert that we never give an issue ack signal if the instruction is not valid
  for (genvar i = 0; i < CVA6Cfg.NrIssuePorts; i++) begin
    assert property (
      @(posedge clk_i) disable iff (!rst_ni) issue_ack_i[i] |-> issue_instr_valid_o[i])
    else `ASSERT_FATAL("Issue acknowledged but instruction is not valid");
  end

  // there should never be more than one instruction writing the same destination register (except x0)
  // check that no functional unit is retiring with the same transaction id
  for (genvar i = 0; i < CVA6Cfg.NrWbPorts; i++) begin
    for (genvar j = 0; j < CVA6Cfg.NrWbPorts; j++) begin
      assert property (
        @(posedge clk_i) disable iff (!rst_ni) wt_valid_i[i] && wt_valid_i[j] && (i != j) |-> (trans_id_i[i] != trans_id_i[j]))
      else
        `ASSERT_FATAL(
            "Two or more functional units are retiring instructions with the same transaction id!");
    end
  end
  //pragma translate_on
endmodule
