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
// Date: 08.02.2018
// Description: Ariane Instruction Fetch Frontend
//
// This module interfaces with the instruction cache, handles control
// change request from the back-end and does branch prediction.

// Additional contributions by:
// June 2025 - Yannick Casamatta, Thales : YPB Protocol

module frontend
  import ariane_pkg::*;
#(
    parameter config_pkg::cva6_cfg_t CVA6Cfg = config_pkg::cva6_cfg_empty,
    parameter type bp_resolve_t = logic,
    parameter type fetch_entry_t = logic,
    parameter type fetch_areq_t = logic,
    parameter type fetch_arsp_t = logic,
    parameter type ypb_fetch_req_t = logic,
    parameter type ypb_fetch_rsp_t = logic,
    parameter type bht_inputs_t = logic
) (
    // Subsystem Clock - SUBSYSTEM
    input logic clk_i,
    // Asynchronous reset active low - SUBSYSTEM
    input logic rst_ni,
    // Next PC when reset - SUBSYSTEM
    input logic [CVA6Cfg.VLEN-1:0] boot_addr_i,
    // Flush branch prediction - zero
    input logic flush_bp_i,
    // Flush requested by FENCE, mis-predict and exception - CONTROLLER
    input logic flush_i,
    // Halt requested by WFI - CONTROLLER
    input logic halt_i,
    // Halt frontend during fence.i, to avoid fetching a stale instruction - CONTROLLER
    input logic halt_frontend_i,
    // Set COMMIT PC as next PC requested by FENCE and CSR side-effect - CONTROLLER
    input logic set_pc_commit_i,
    // COMMIT PC - COMMIT
    input logic [CVA6Cfg.VLEN-1:0] pc_commit_i,
    // Exception event - COMMIT
    input logic ex_valid_i,
    // Mispredict event and next PC - EXECUTE
    input bp_resolve_t resolved_branch_i,
    // Return from exception event - CSR
    input logic eret_i,
    // Next PC when returning from exception - CSR
    input logic [CVA6Cfg.VLEN-1:0] epc_i,
    // Next PC when jumping into exception - CSR
    input logic [CVA6Cfg.VLEN-1:0] trap_vector_base_i,
    // Debug event - CSR
    input logic set_debug_pc_i,
    // Debug mode state - CSR
    input logic debug_mode_i,
    // address translation request chanel - EXECUTE
    input fetch_arsp_t arsp_i,
    // address translation response chanel - EXECUTE
    output fetch_areq_t areq_o,
    // YPB Fetch Request channel - CACHES
    output ypb_fetch_req_t ypb_fetch_req_o,
    // YPB Fetch Response channel - CACHES
    input ypb_fetch_rsp_t ypb_fetch_rsp_i,
    // Handshake's data between fetch and decode - ID_STAGE
    output fetch_entry_t [CVA6Cfg.NrIssuePorts-1:0] fetch_entry_o,
    // Handshake's valid between fetch and decode - ID_STAGE
    output logic [CVA6Cfg.NrIssuePorts-1:0] fetch_entry_valid_o,
    // Handshake's ready between fetch and decode - ID_STAGE
    input logic [CVA6Cfg.NrIssuePorts-1:0] fetch_entry_ready_i,
    // DCLS
    input bht_prediction_t [CVA6Cfg.INSTR_PER_FETCH-1:0] dcls_common_bht_data_i,
    output bht_inputs_t dcls_common_bht_ctrl_o
);

  localparam type bht_update_t = struct packed {
    logic                    valid;
    logic [CVA6Cfg.VLEN-1:0] pc;     // update at PC
    logic                    taken;
  };

  localparam type btb_prediction_t = struct packed {
    logic                    valid;
    logic [CVA6Cfg.VLEN-1:0] target_address;
  };

  localparam type btb_update_t = struct packed {
    logic                    valid;
    logic [CVA6Cfg.VLEN-1:0] pc;              // update at PC
    logic [CVA6Cfg.VLEN-1:0] target_address;
  };

  localparam type ras_t = struct packed {
    logic                    valid;
    logic [CVA6Cfg.VLEN-1:0] ra;
  };

  // Instruction Cache Registers, from I$
  logic                            [    CVA6Cfg.FETCH_WIDTH-1:0] fetch_data_q;
  logic                                                          fetch_valid_q;
  ariane_pkg::frontend_exception_t                               fetch_ex_valid_q;
  logic                            [           CVA6Cfg.VLEN-1:0] fetch_vaddr_q;
  logic                            [          CVA6Cfg.GPLEN-1:0] fetch_gpaddr_q;
  logic                            [                       31:0] fetch_tinst_q;
  logic                                                          fetch_gva_q;
  logic                                                          instr_queue_ready;
  logic                            [CVA6Cfg.INSTR_PER_FETCH-1:0] instr_queue_consumed;
  // upper-most branch-prediction from last cycle
  btb_prediction_t                                               btb_q;
  bht_prediction_t                                               bht_q;
  // instruction fetch is ready
  logic                                                          if_ready;
  logic [CVA6Cfg.VLEN-1:0] npc_d, npc_q;  // next PC

  // indicates whether we come out of reset (then we need to load boot_addr_i)
  logic                    npc_rst_load_q;

  logic                    replay;
  logic [CVA6Cfg.VLEN-1:0] replay_addr;

  logic [CVA6Cfg.VLEN-1:0]
      npc_fetch_address, vaddr_d, ypb_vaddr_q, ypb_vaddr_d, vaddr_q, fetch_vaddr_d;
  logic [CVA6Cfg.PLEN-1:0] paddr_d, paddr_q;

  // shift amount
  logic [(CVA6Cfg.INSTR_PER_FETCH > 1 ? $clog2(CVA6Cfg.INSTR_PER_FETCH) : 1)-1:0] shamt;
  // address will always be 16 bit aligned, make this explicit here
  if (CVA6Cfg.RVC) begin : gen_shamt
    assign shamt = fetch_vaddr_d[$clog2(CVA6Cfg.INSTR_PER_FETCH):1];
  end else begin
    assign shamt = '0;
  end

  // -----------------------
  // Ctrl Flow Speculation
  // -----------------------
  // RVI ctrl flow prediction
  logic [CVA6Cfg.INSTR_PER_FETCH-1:0] rvi_return, rvi_call, rvi_branch, rvi_jalr, rvi_jump;
  logic [CVA6Cfg.INSTR_PER_FETCH-1:0][CVA6Cfg.VLEN-1:0] rvi_imm;
  // RVC branching
  logic [CVA6Cfg.INSTR_PER_FETCH-1:0] rvc_branch, rvc_jump, rvc_jr, rvc_return, rvc_jalr, rvc_call;
  logic            [CVA6Cfg.INSTR_PER_FETCH-1:0][CVA6Cfg.VLEN-1:0] rvc_imm;
  // re-aligned instruction and address (coming from cache - combinationally)
  logic            [CVA6Cfg.INSTR_PER_FETCH-1:0][            31:0] instr;
  logic            [CVA6Cfg.INSTR_PER_FETCH-1:0][CVA6Cfg.VLEN-1:0] addr;
  logic            [CVA6Cfg.INSTR_PER_FETCH-1:0]                   instruction_valid;
  // BHT, BTB and RAS prediction
  bht_prediction_t [CVA6Cfg.INSTR_PER_FETCH-1:0]                   bht_prediction;
  btb_prediction_t [CVA6Cfg.INSTR_PER_FETCH-1:0]                   btb_prediction;
  bht_prediction_t [CVA6Cfg.INSTR_PER_FETCH-1:0]                   bht_prediction_shifted;
  btb_prediction_t [CVA6Cfg.INSTR_PER_FETCH-1:0]                   btb_prediction_shifted;
  ras_t                                                            ras_predict;
  logic            [           CVA6Cfg.VLEN-1:0]                   vpc_btb;
  logic            [           CVA6Cfg.VLEN-1:0]                   vpc_bht;

  // branch-predict update
  logic is_mispredict, was_mispredicted;
  logic ras_push, ras_pop;
  logic [           CVA6Cfg.VLEN-1:0] ras_update;

  // Instruction FIFO
  logic [           CVA6Cfg.VLEN-1:0] predict_address;
  cf_t  [CVA6Cfg.INSTR_PER_FETCH-1:0] cf_type;
  logic [CVA6Cfg.INSTR_PER_FETCH-1:0] cf_valid;
  logic [CVA6Cfg.INSTR_PER_FETCH-1:0] taken_rvi_cf;
  logic [CVA6Cfg.INSTR_PER_FETCH-1:0] taken_rvc_cf;

  logic kill_s1, kill_s2;

  logic serving_unaligned;
  // Re-align instructions
  instr_realign #(
      .CVA6Cfg(CVA6Cfg)
  ) i_instr_realign (
      .clk_i              (clk_i),
      .rst_ni             (rst_ni),
      .flush_i            (kill_s2),
      .valid_i            (fetch_valid_q),
      .serving_unaligned_o(serving_unaligned),
      .address_i          (fetch_vaddr_q),
      .data_i             (fetch_data_q),
      .valid_o            (instruction_valid),
      .addr_o             (addr),
      .instr_o            (instr)
  );
  // --------------------
  // Branch Prediction
  // --------------------
  // select the right branch prediction result
  // in case we are serving an unaligned instruction in instr[0] we need to take
  // the prediction we saved from the previous fetch
  if (CVA6Cfg.RVC) begin : gen_btb_prediction_shifted
    assign bht_prediction_shifted[0] = (serving_unaligned) ? bht_q : bht_prediction[addr[0][$clog2(
        CVA6Cfg.INSTR_PER_FETCH
    ):1]];
    assign btb_prediction_shifted[0] = (serving_unaligned) ? btb_q : btb_prediction[addr[0][$clog2(
        CVA6Cfg.INSTR_PER_FETCH
    ):1]];

    // for all other predictions we can use the generated address to index
    // into the branch prediction data structures
    for (genvar i = 1; i < CVA6Cfg.INSTR_PER_FETCH; i++) begin : gen_prediction_address
      assign bht_prediction_shifted[i] = bht_prediction[addr[i][$clog2(CVA6Cfg.INSTR_PER_FETCH):1]];
      assign btb_prediction_shifted[i] = btb_prediction[addr[i][$clog2(CVA6Cfg.INSTR_PER_FETCH):1]];
    end
  end else begin
    //  Without C an instruction is 4-byte aligned, so bit 2 of the address
    //  selects the prediction slot. INSTR_PER_FETCH is still 2 under
    //  superscalar fetch, and slot 1 must be driven too.
    if (CVA6Cfg.INSTR_PER_FETCH == 1) begin : gen_single_prediction_without_c
      assign bht_prediction_shifted[0] = (serving_unaligned) ? bht_q : bht_prediction[0];
      assign btb_prediction_shifted[0] = (serving_unaligned) ? btb_q : btb_prediction[0];
    end else begin : gen_prediction_address_without_c
      assign bht_prediction_shifted[0] = (serving_unaligned) ? bht_q : bht_prediction[addr[0][2]];
      assign btb_prediction_shifted[0] = (serving_unaligned) ? btb_q : btb_prediction[addr[0][2]];
      for (genvar i = 1; i < CVA6Cfg.INSTR_PER_FETCH; i++) begin : gen_upper_slots
        assign bht_prediction_shifted[i] = bht_prediction[addr[i][2]];
        assign btb_prediction_shifted[i] = btb_prediction[addr[i][2]];
      end
    end
  end
  ;

  // for the return address stack it doesn't matter as we have the
  // address of the call/return already
  logic bp_valid;
  logic [CVA6Cfg.INSTR_PER_FETCH-1:0] is_branch;
  logic [CVA6Cfg.INSTR_PER_FETCH-1:0] is_call;
  logic [CVA6Cfg.INSTR_PER_FETCH-1:0] is_jump;
  logic [CVA6Cfg.INSTR_PER_FETCH-1:0] is_return;
  logic [CVA6Cfg.INSTR_PER_FETCH-1:0] is_jalr;

  // branch history table -> BHT
  assign is_branch = instruction_valid & (rvi_branch | rvc_branch);
  // function calls -> RAS
  assign is_call   = instruction_valid & (rvi_call | rvc_call);
  // function return -> RAS
  assign is_return = instruction_valid & (rvi_return | rvc_return);
  // unconditional jumps with known target -> immediately resolved
  assign is_jump   = instruction_valid & (rvi_jump | rvc_jump);
  // unconditional jumps with unknown target -> BTB
  assign is_jalr   = instruction_valid & ~is_return & (rvi_jalr | rvc_jalr | rvc_jr);

  // taken/not taken
  always_comb begin
    taken_rvi_cf = '0;
    taken_rvc_cf = '0;
    predict_address = '0;

    for (int i = 0; i < CVA6Cfg.INSTR_PER_FETCH; i++) cf_type[i] = ariane_pkg::NoCF;
    for (int i = 0; i < CVA6Cfg.INSTR_PER_FETCH; i++) cf_valid[i] = 1'b0;

    ras_push = 1'b0;
    ras_pop = 1'b0;
    ras_update = '0;

    // lower most prediction gets precedence
    for (int i = CVA6Cfg.INSTR_PER_FETCH - 1; i >= 0; i--) begin
      unique case ({
        is_branch[i], is_return[i], is_jump[i], is_jalr[i]
      })
        4'b0000: ;  // regular instruction e.g.: no branch
        // unconditional jump to register, we need the BTB to resolve this
        4'b0001: begin
          ras_pop = 1'b0;
          ras_push = 1'b0;
          cf_type[i] = ariane_pkg::JumpR;
          if (CVA6Cfg.BTBEntries != 0 && btb_prediction_shifted[i].valid) begin
            predict_address = btb_prediction_shifted[i].target_address;
            cf_valid[i] = 1'b1;
          end
        end
        // its an unconditional jump to an immediate
        4'b0010: begin
          ras_pop = 1'b0;
          ras_push = 1'b0;
          taken_rvi_cf[i] = rvi_jump[i];
          taken_rvc_cf[i] = rvc_jump[i];
          cf_type[i] = ariane_pkg::Jump;
          cf_valid[i] = rvi_jump[i] || rvc_jump[i];
        end
        // return
        4'b0100: begin
          // make sure to only alter the RAS if we actually consumed the instruction
          ras_pop = ras_predict.valid & instr_queue_consumed[i];
          ras_push = 1'b0;
          predict_address = ras_predict.ra;
          cf_type[i] = ariane_pkg::Return;
          cf_valid[i] = ras_predict.valid;
        end
        // branch prediction
        4'b1000: begin
          ras_pop  = 1'b0;
          ras_push = 1'b0;
          // if we have a valid dynamic prediction use it
          if (bht_prediction_shifted[i].valid) begin
            taken_rvi_cf[i] = rvi_branch[i] & bht_prediction_shifted[i].taken;
            taken_rvc_cf[i] = rvc_branch[i] & bht_prediction_shifted[i].taken;
            // otherwise default to static prediction
          end else begin
            // set if immediate is negative - static prediction
            taken_rvi_cf[i] = rvi_branch[i] & rvi_imm[i][CVA6Cfg.VLEN-1];
            taken_rvc_cf[i] = rvc_branch[i] & rvc_imm[i][CVA6Cfg.VLEN-1];
          end
          if (taken_rvi_cf[i] || taken_rvc_cf[i]) begin
            cf_type[i]  = ariane_pkg::Branch;
            cf_valid[i] = 1'b1;
          end
        end
        default: ;
        // default: $error("Decoded more than one control flow");
      endcase
      // if this instruction, in addition, is a call, save the resulting address
      // but only if we actually consumed the address
      if (is_call[i]) begin
        ras_push   = instr_queue_consumed[i];
        ras_update = addr[i] + (rvc_call[i] ? 2 : 4);
      end
      // calculate the jump target address
      if (taken_rvc_cf[i] || taken_rvi_cf[i]) begin
        predict_address = addr[i] + (taken_rvc_cf[i] ? rvc_imm[i] : rvi_imm[i]);
      end
    end
  end
  // Or reduce struct
  assign bp_valid = |cf_valid;
  assign is_mispredict = resolved_branch_i.valid & resolved_branch_i.is_mispredict;

  logic spec_req_non_idempot;

  // MMU interface
  assign areq_o.fetch_vaddr = (vaddr_d >> CVA6Cfg.FETCH_ALIGN_BITS) << CVA6Cfg.FETCH_ALIGN_BITS;

  // CHECK PMA regions

  logic paddr_is_cacheable;  // asserted if physical address is non-cacheable
  assign paddr_is_cacheable = config_pkg::is_inside_cacheable_regions(
      CVA6Cfg, {{64 - CVA6Cfg.PLEN{1'b0}}, ypb_fetch_req_o.paddr}  //TO DO CHECK GRANULARITY
  );

  logic paddr_nonidempotent;
  assign paddr_nonidempotent = arsp_i.fetch_valid && config_pkg::is_inside_nonidempotent_regions(
      CVA6Cfg, {{64 - CVA6Cfg.PLEN{1'b0}}, arsp_i.fetch_paddr}  //TO DO CHECK GRANULARITY
  );

  // Caches optimisation signals

  logic [CVA6Cfg.VLEN-1:0] vaddr_rvalid;
  logic rvalid;
  logic ex_rvalid;
  logic pop_fetch;

  // in order to decouple the response interface from the request interface,
  // we need a a buffer which can hold all inflight memory fetch requests
  typedef struct packed {
    logic [CVA6Cfg.VLEN-1:0] vaddr;  // scoreboard identifier
  } fetchbuf_t;

  logic [CVA6Cfg.PLEN-1:0] paddr;

  // to support a throughput of one fetch per cycle, if the number of entries
  // of the fetch buffer is 1, implement a fall-through mode. This however
  // adds a combinational path between the request and response interfaces
  // towards the cache.
  localparam logic FETCHBUF_FALLTHROUGH = (CVA6Cfg.NrFetchBufEntries == 1);
  localparam int unsigned REQ_ID_BITS = CVA6Cfg.NrFetchBufEntries > 1 ? $clog2(
      CVA6Cfg.NrFetchBufEntries
  ) : 1;

  typedef logic [REQ_ID_BITS-1:0] fetchbuf_id_t;

  logic [CVA6Cfg.NrFetchBufEntries-1:0] fetchbuf_valid_q, fetchbuf_valid_d;
  logic [CVA6Cfg.NrFetchBufEntries-1:0] fetchbuf_flushed_q, fetchbuf_flushed_d;
  fetchbuf_t [CVA6Cfg.NrFetchBufEntries-1:0] fetchbuf_q;
  logic fetchbuf_empty, fetchbuf_full;
  fetchbuf_id_t fetchbuf_free_index;
  logic fetchbuf_w, fetchbuf_w_q;
  fetchbuf_id_t fetchbuf_windex, fetchbuf_windex_q;
  logic         fetchbuf_r;
  fetchbuf_t    fetchbuf_rdata;
  fetchbuf_id_t fetchbuf_rindex;
  fetchbuf_id_t fetchbuf_last_id_q;

  logic kill_req_d, kill_req_q;
  logic ex_s1;

  typedef enum logic [1:0] {
    TRANSPARENT,
    REGISTRED
  } ypb_a_state_e;
  ypb_a_state_e ypb_a_state_d, ypb_a_state_q;

  assign fetchbuf_full = &fetchbuf_valid_q && !(FETCHBUF_FALLTHROUGH && fetchbuf_r && ypb_a_state_q == TRANSPARENT);


  //
  //  buffer of outstanding fetchs

  //  write in the first available slot
  generate
    if (CVA6Cfg.NrFetchBufEntries > 1) begin : fetchbuf_free_index_multi_gen
      lzc #(
          .WIDTH(CVA6Cfg.NrFetchBufEntries),
          .MODE (1'b0)                        // Count leading zeros
      ) lzc_windex_i (
          .in_i   (~fetchbuf_valid_q),
          .cnt_o  (fetchbuf_free_index),
          .empty_o(fetchbuf_empty)
      );
    end else begin : fetchbuf_free_index_single_gen
      assign fetchbuf_free_index = 1'b0;
    end
  endgenerate

  assign fetchbuf_windex = (FETCHBUF_FALLTHROUGH && fetchbuf_r) ? fetchbuf_rindex : fetchbuf_free_index;

  always_comb begin : fetchbuf_comb
    fetchbuf_flushed_d = fetchbuf_flushed_q;
    fetchbuf_valid_d   = fetchbuf_valid_q;

    //  In case of flush, raise the flushed flag in all slots.
    if (flush_i) begin
      fetchbuf_flushed_d = '1;
    end
    //  Free read entry (in the case of fall-through mode, free the entry
    //  only if there is no pending fetch)
    if (fetchbuf_r && ypb_a_state_q == TRANSPARENT && (!FETCHBUF_FALLTHROUGH || !fetchbuf_w)) begin
      fetchbuf_valid_d[fetchbuf_rindex] = 1'b0;
    end
    // Flush on bp_valid
    if (kill_s2) begin
      fetchbuf_flushed_d[fetchbuf_last_id_q] = 1'b1;
    end
    // Free on exception
    //if (fetchbuf_w_q && ((CVA6Cfg.MmuPresent && ex_s1) || bp_valid) || kill_req_q) begin
    //  fetchbuf_valid_d[fetchbuf_windex_q] = 1'b0;
    //end
    //  Track a new outstanding operation in the fetch buffer
    if (fetchbuf_w) begin
      fetchbuf_flushed_d[fetchbuf_windex] = 1'b0;
      fetchbuf_valid_d[fetchbuf_windex]   = 1'b1;
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin : fetchbuf_ff
    if (!rst_ni) begin
      fetchbuf_flushed_q <= '0;
      fetchbuf_valid_q   <= '0;
      fetchbuf_last_id_q <= '0;
      fetchbuf_q         <= '0;
    end else begin
      fetchbuf_flushed_q <= fetchbuf_flushed_d;
      fetchbuf_valid_q   <= fetchbuf_valid_d;
      if (fetchbuf_w) begin
        fetchbuf_last_id_q                <= fetchbuf_windex;
        fetchbuf_q[fetchbuf_windex].vaddr <= vaddr_d;
      end
    end
  end





  logic stall_ni, stall_ypb, stall_translation, stall_instr_queue;
  logic data_req, data_rvalid;

  assign stall_ni = spec_req_non_idempot;
  assign stall_ypb = (ypb_a_state_q == REGISTRED);  //&& !ypb_load_rsp_i.pgnt;
  assign stall_translation = CVA6Cfg.MmuPresent ? areq_o.fetch_req && (!arsp_i.fetch_valid || (arsp_i.fetch_valid && arsp_i.fetch_exception.valid)) : 1'b0;
  assign stall_instr_queue = !instr_queue_ready;

  assign ex_s1 = (CVA6Cfg.MmuPresent && arsp_i.fetch_exception.valid);

  // We need to flush the cache pipeline if:
  // 1. We mispredicted
  // 2. Want to flush the whole processor front-end
  // 3. Need to replay an instruction because the fetch-fifo was full
  assign kill_s1 = is_mispredict | flush_i | replay;
  // if we have a valid branch-prediction we need to only kill the last cache request
  // also if we killed the first stage we also need to kill the second stage (inclusive flush)
  assign kill_s2 = kill_s1 | bp_valid;

  assign ypb_fetch_req_o.kill_req = kill_req_q || kill_s2 || ex_s1;

  assign data_rvalid = fetchbuf_r && !fetchbuf_flushed_q[fetchbuf_rindex] && !kill_s2;

  //assign ypb_vaddr_d = pop_fetch ?  : ypb_vaddr_qvaddr_d;
  assign vaddr_d = npc_fetch_address;
  assign ypb_fetch_req_o.vaddr = npc_fetch_address;
  assign paddr = CVA6Cfg.MmuPresent ? arsp_i.fetch_paddr : npc_fetch_address;

  assign data_req = (CVA6Cfg.MmuPresent ? (fetchbuf_w || fetchbuf_w_q) && !ex_s1 && arsp_i.fetch_valid: fetchbuf_w);

  always_comb begin : p_fsm_common
    // default assignmen
    kill_req_d = 1'b0;
    fetchbuf_w = 1'b0;
    //response
    vaddr_rvalid = npc_fetch_address;
    rvalid    = 1'b0;
    ex_rvalid = 1'b0;
    pop_fetch = 1'b0; // release lsu_bypass fifo

    // REQUEST
    //if (instr_queue_ready) begin
    areq_o.fetch_req = 1'b1;
    ypb_fetch_req_o.vreq = 1'b1;
    if (!CVA6Cfg.MmuPresent || ypb_fetch_rsp_i.vgnt) begin
      // halt_frontend_i: no fetch while fence.i flushes the data cache. It is
      // held before the fetch buffer, whose entries only a response frees.
      if (stall_ni || stall_ypb || stall_instr_queue || stall_translation || fetchbuf_full || halt_frontend_i) begin
        kill_req_d = CVA6Cfg.MmuPresent ? 1'b1 :  1'b0; // MmuPresent only : next cycle is s2 but we need to kill because not ready to sent tag
      end else begin
        fetchbuf_w  = !kill_s1 && !flush_i; // record request into outstanding fetch fifo and trigger YPB physical request
        pop_fetch = arsp_i.fetch_valid;  // release lsu_bypass fifo
      end
    end
    //end
    // RETIRE FETCH
    // we got an rvalid and it's corresponding request was not flushed
    if (data_rvalid) begin
      vaddr_rvalid = fetchbuf_q[fetchbuf_rindex].vaddr;
      rvalid    = !bp_valid && !flush_i;
      ex_rvalid = 1'b0;
      // RETIRE EXCEPTION (low priority)
    end else if (CVA6Cfg.MmuPresent && ex_s1) begin
      vaddr_rvalid = vaddr_q;
      rvalid    = arsp_i.fetch_valid && !bp_valid && !flush_i && !was_mispredicted;
      ex_rvalid = arsp_i.fetch_valid; //1'b1;
      pop_fetch = arsp_i.fetch_valid; // release lsu_bypass fifo
    end

  end

  // ---------------
  // Retire Load
  // ---------------
  assign fetchbuf_rindex = (CVA6Cfg.NrFetchBufEntries > 1) ? fetchbuf_id_t'(ypb_fetch_rsp_i.rid) : 1'b0;
  assign fetchbuf_rdata = fetchbuf_q[fetchbuf_rindex];

  //  read the pending fetch buffer
  assign fetchbuf_r = ypb_fetch_rsp_i.rvalid;


  //default YPB state registred
  assign ypb_fetch_req_o.paddr = {
    ypb_a_state_q == TRANSPARENT ? paddr[CVA6Cfg.PLEN-1:CVA6Cfg.FETCH_ALIGN_BITS] : paddr_q[CVA6Cfg.PLEN-1:CVA6Cfg.FETCH_ALIGN_BITS],
    {CVA6Cfg.FETCH_ALIGN_BITS{1'b0}}
  };
  assign ypb_fetch_req_o.we = '0;
  assign ypb_fetch_req_o.be = '1;
  assign ypb_fetch_req_o.size = CVA6Cfg.FETCH_ALIGN_BITS;
  assign ypb_fetch_req_o.wdata = '0;
  assign ypb_fetch_req_o.aid = (!CVA6Cfg.MmuPresent && (ypb_a_state_q == TRANSPARENT)) ? fetchbuf_windex : fetchbuf_windex_q;
  assign ypb_fetch_req_o.atop = ariane_pkg::AMO_NONE;
  assign ypb_fetch_req_o.cbo_op = ariane_pkg::CBO_NONE;
  assign ypb_fetch_req_o.cacheable = paddr_is_cacheable;
  assign ypb_fetch_req_o.bufferable = config_pkg::is_inside_bufferable_regions(
      CVA6Cfg, {{64 - CVA6Cfg.PLEN{1'b0}}, ypb_fetch_req_o.paddr}
  );
  assign ypb_fetch_req_o.access_type = '0;  //  0 = fetch
  assign ypb_fetch_req_o.rready = '1;  //always ready  TODO maybe manage instr_queue_ready & replay with this signal



  always_comb begin : p_fsm_ypb_a
    // default assignment
    ypb_a_state_d = ypb_a_state_q;
    ypb_fetch_req_o.preq    = 1'b0;

    unique case (ypb_a_state_q)
      TRANSPARENT: begin
        if (data_req) begin
          ypb_fetch_req_o.preq = 1'b1;
          if (!ypb_fetch_rsp_i.pgnt) begin
            ypb_a_state_d = REGISTRED;
          end
        end
      end

      REGISTRED: begin
        ypb_fetch_req_o.preq = 1'b1;
        if (ypb_fetch_rsp_i.pgnt) begin
          ypb_a_state_d = TRANSPARENT;
        end
      end

      default: begin
        // we should never get here
        ypb_a_state_d = TRANSPARENT;
      end
    endcase
  end

  // latch physical address for the tag cycle (one cycle after applying the index)
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      ypb_a_state_q <= TRANSPARENT;
      paddr_q <= '0;
      kill_req_q <= '0;
      fetchbuf_windex_q <= '0;
      fetchbuf_w_q <= '0;
      vaddr_q <= vaddr_d;
    end else begin
      if (ypb_a_state_q == TRANSPARENT) begin
        paddr_q <= paddr;
      end
      ypb_a_state_q <= ypb_a_state_d;
      kill_req_q <= kill_req_d;
      if (!ex_s1) begin
        fetchbuf_windex_q <= fetchbuf_windex;
        fetchbuf_w_q <= (CVA6Cfg.MmuPresent && !arsp_i.fetch_valid) ? fetchbuf_w : fetchbuf_w_q;
      end
      vaddr_q <= vaddr_d;
    end
  end

  // Update Control Flow Predictions
  bht_update_t bht_update;
  btb_update_t btb_update;

  logic speculative_q, speculative_d;
  assign speculative_d = (speculative_q && !resolved_branch_i.valid || |is_branch || |is_return || |is_jalr) && !flush_i;

  assign spec_req_non_idempot = CVA6Cfg.NonIdemPotenceEn ? speculative_d && paddr_nonidempotent : 1'b0;


  assign bht_update.valid = resolved_branch_i.valid
                                & (resolved_branch_i.cf_type == ariane_pkg::Branch);
  assign bht_update.pc = resolved_branch_i.pc;
  assign bht_update.taken = resolved_branch_i.is_taken;
  // only update mispredicted branches e.g. no returns from the RAS
  assign btb_update.valid = resolved_branch_i.is_mispredict
                                & (resolved_branch_i.cf_type == ariane_pkg::JumpR);
  assign btb_update.pc = resolved_branch_i.pc;
  assign btb_update.target_address = resolved_branch_i.target_address;

  // -------------------
  // Next PC
  // -------------------
  // next PC (NPC) can come from (in order of precedence):
  // 0. Default assignment/replay instruction
  // 1. Branch Predict taken
  // 2. Control flow change request (misprediction)
  // 3. Return from environment call
  // 4. Exception/Interrupt
  // 5. Pipeline Flush because of CSR side effects
  // Mis-predict handling is a little bit different
  // select PC a.k.a PC Gen
  always_comb begin : npc_select
    automatic logic [CVA6Cfg.VLEN-1:0] fetch_address;
    // check whether we come out of reset
    // this is a workaround. some tools have issues
    // having boot_addr_i in the asynchronous
    // reset assignment to npc_q, even though
    // boot_addr_i will be assigned a constant
    // on the top-level.
    if (npc_rst_load_q) begin
      npc_d         = boot_addr_i;
      fetch_address = boot_addr_i;
    end else begin
      fetch_address = npc_q;
      // keep stable by default
      npc_d         = npc_q;
    end
    // 0. Branch Prediction
    if (bp_valid) begin
      fetch_address = predict_address;
      npc_d = predict_address;
    end
    // 1. Default assignment
    if (pop_fetch && (!was_mispredicted || !stall_translation)) begin
      npc_d = {
        fetch_address[CVA6Cfg.VLEN-1:CVA6Cfg.FETCH_ALIGN_BITS] + 1, {CVA6Cfg.FETCH_ALIGN_BITS{1'b0}}
      };
    end
    // 2. Replay instruction fetch
    if (replay) begin
      npc_d = replay_addr;
      fetch_address = replay_addr;
    end
    // 3. Control flow change request
    if (is_mispredict) begin
      npc_d = resolved_branch_i.target_address;
      fetch_address = resolved_branch_i.target_address;
    end
    // 4. Return from environment call
    if (eret_i) begin
      npc_d = epc_i;
      fetch_address = epc_i;
    end
    // 5. Exception/Interrupt
    if (ex_valid_i) begin
      npc_d = trap_vector_base_i;
      fetch_address = trap_vector_base_i;
    end
    // 6. Pipeline Flush because of CSR side effects
    // On a pipeline flush start fetching from the next address
    // of the instruction in the commit stage
    // we either came here from a flush request of a CSR instruction or AMO,
    // so as CSR or AMO instructions do not exist in a compressed form
    // we can unconditionally do PC + 4 here
    // or if the commit stage is halted, just take the current pc of the
    // instruction in the commit stage
    // IMPROVEMENT: This adder can at least be merged with the one in the csr_regfile stage
    if (set_pc_commit_i) begin
      npc_d = pc_commit_i + (halt_i ? '0 : {{CVA6Cfg.VLEN - 3{1'b0}}, 3'b100});
      fetch_address = pc_commit_i + (halt_i ? '0 : {{CVA6Cfg.VLEN - 3{1'b0}}, 3'b100});
    end
    // 7. Debug
    // enter debug on a hard-coded base-address
    if (CVA6Cfg.DebugEn && set_debug_pc_i)
      npc_d = CVA6Cfg.DmBaseAddress[CVA6Cfg.VLEN-1:0] + CVA6Cfg.HaltAddress[CVA6Cfg.VLEN-1:0];
    npc_fetch_address = fetch_address;
  end

  logic [CVA6Cfg.FETCH_WIDTH-1:0] fetch_data;
  logic fetch_valid_d;

  // re-align the cache line
  assign fetch_data = ex_rvalid && CVA6Cfg.MmuPresent ? '0 : ypb_fetch_rsp_i.rdata >> {shamt, 4'b0};
  assign fetch_valid_d = rvalid;
  assign fetch_vaddr_d = vaddr_rvalid;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      npc_rst_load_q   <= 1'b1;
      npc_q            <= '0;
      speculative_q    <= '0;
      fetch_data_q     <= '0;
      fetch_valid_q    <= 1'b0;
      fetch_vaddr_q    <= 'b0;
      fetch_gpaddr_q   <= 'b0;
      fetch_tinst_q    <= 'b0;
      fetch_gva_q      <= 1'b0;
      fetch_ex_valid_q <= ariane_pkg::FE_NONE;
      btb_q            <= '0;
      bht_q            <= '0;
      was_mispredicted <= '0;
    end else begin
      npc_rst_load_q <= 1'b0;
      npc_q <= npc_d;
      speculative_q <= speculative_d;
      fetch_valid_q <= fetch_valid_d;
      if (fetch_valid_d) begin
        fetch_data_q  <= fetch_data;
        fetch_vaddr_q <= fetch_vaddr_d;
        if (CVA6Cfg.RVH) begin
          fetch_gpaddr_q <= arsp_i.fetch_exception.tval2[CVA6Cfg.GPLEN-1:0];
          fetch_tinst_q  <= arsp_i.fetch_exception.tinst;
          fetch_gva_q    <= arsp_i.fetch_exception.gva;
        end else begin
          fetch_gpaddr_q <= 'b0;
          fetch_tinst_q  <= 'b0;
          fetch_gva_q    <= 1'b0;
        end

        // Map the only three exceptions which can occur in the frontend to a two bit enum
        if (CVA6Cfg.MmuPresent && arsp_i.fetch_valid && arsp_i.fetch_exception.cause == riscv::INSTR_GUEST_PAGE_FAULT) begin
          fetch_ex_valid_q <= ariane_pkg::FE_INSTR_GUEST_PAGE_FAULT;
        end else if (CVA6Cfg.MmuPresent && arsp_i.fetch_valid && arsp_i.fetch_exception.cause == riscv::INSTR_PAGE_FAULT) begin
          fetch_ex_valid_q <= ariane_pkg::FE_INSTR_PAGE_FAULT;
        end else if (CVA6Cfg.NrPMPEntries != 0 && arsp_i.fetch_valid && arsp_i.fetch_exception.cause == riscv::INSTR_ACCESS_FAULT) begin
          fetch_ex_valid_q <= ariane_pkg::FE_INSTR_ACCESS_FAULT;
        end else begin
          fetch_ex_valid_q <= ariane_pkg::FE_NONE;
        end
        // save the uppermost prediction
        btb_q <= btb_prediction[CVA6Cfg.INSTR_PER_FETCH-1];
        bht_q <= bht_prediction[CVA6Cfg.INSTR_PER_FETCH-1];
      end

      if (arsp_i.fetch_valid)  // translation finished, can clear flag
        was_mispredicted <= '0;
      else if (is_mispredict & !arsp_i.fetch_valid)  // translation request for misprediction ongoing
        was_mispredicted <= '1;
    end
  end

  if (CVA6Cfg.RASDepth == 0) begin
    assign ras_predict = '0;
  end else begin : ras_gen
    ras #(
        .CVA6Cfg(CVA6Cfg),
        .ras_t  (ras_t),
        .DEPTH  (CVA6Cfg.RASDepth)
    ) i_ras (
        .clk_i,
        .rst_ni,
        .flush_bp_i(flush_bp_i),
        .push_i(ras_push),
        .pop_i(ras_pop),
        .data_i(ras_update),
        .data_o(ras_predict)
    );
  end

  //For FPGA, BTB is implemented in read synchronous BRAM
  //while for ASIC, BTB is implemented in D flip-flop
  //and can be read at the same cycle.
  //Same for BHT
  assign vpc_btb = (CVA6Cfg.FpgaEn) ? vaddr_q : fetch_vaddr_q;
  assign vpc_bht = (CVA6Cfg.FpgaEn && CVA6Cfg.FpgaAlteraEn && fetch_valid_d) ? vaddr_q : fetch_vaddr_q;

  if (CVA6Cfg.BTBEntries == 0) begin
    assign btb_prediction = '0;
  end else begin : btb_gen
    btb #(
        .CVA6Cfg   (CVA6Cfg),
        .btb_update_t(btb_update_t),
        .btb_prediction_t(btb_prediction_t),
        .NR_ENTRIES(CVA6Cfg.BTBEntries)
    ) i_btb (
        .clk_i,
        .rst_ni,
        .flush_bp_i      (flush_bp_i),
        .debug_mode_i,
        .vpc_i           (vpc_btb),
        .btb_update_i    (btb_update),
        .btb_prediction_o(btb_prediction)
    );
  end

  if (CVA6Cfg.BHTEntries == 0) begin
    assign bht_prediction = '0;
  end else if (CVA6Cfg.BPType == config_pkg::PH_BHT) begin : bht2lvl_gen
    bht2lvl #(
        .CVA6Cfg     (CVA6Cfg),
        .bht_update_t(bht_update_t)
    ) i_bht (
        .clk_i,
        .rst_ni,
        .flush_i         (flush_bp_i),
        .vpc_i           (vpc_bht),
        .bht_update_i    (bht_update),
        .bht_prediction_o(bht_prediction)
    );
  end else begin : bht_gen
    if (CVA6Cfg.DclsEn & CVA6Cfg.DclsCommonBHT) begin : gen_common_bht
      assign bht_prediction = dcls_common_bht_data_i;

      assign dcls_common_bht_ctrl_o = '{flush_bp_i, debug_mode_i, vpc_bht, bht_update};
    end else begin : gen_no_common_bht
      bht #(
          .CVA6Cfg   (CVA6Cfg),
          .bht_update_t(bht_update_t),
          .NR_ENTRIES(CVA6Cfg.BHTEntries)
      ) i_bht (
          .clk_i,
          .rst_ni,
          .flush_bp_i      (flush_bp_i),
          .debug_mode_i,
          .vpc_i           (vpc_bht),
          .bht_update_i    (bht_update),
          .bht_prediction_o(bht_prediction)
      );
    end
  end

  // we need to inspect up to CVA6Cfg.INSTR_PER_FETCH instructions for branches
  // and jumps
  for (genvar i = 0; i < CVA6Cfg.INSTR_PER_FETCH; i++) begin : gen_instr_scan
    instr_scan #(
        .CVA6Cfg(CVA6Cfg)
    ) i_instr_scan (
        .instr_i     (instr[i]),
        .rvi_return_o(rvi_return[i]),
        .rvi_call_o  (rvi_call[i]),
        .rvi_branch_o(rvi_branch[i]),
        .rvi_jalr_o  (rvi_jalr[i]),
        .rvi_jump_o  (rvi_jump[i]),
        .rvi_imm_o   (rvi_imm[i]),
        .rvc_branch_o(rvc_branch[i]),
        .rvc_jump_o  (rvc_jump[i]),
        .rvc_jr_o    (rvc_jr[i]),
        .rvc_return_o(rvc_return[i]),
        .rvc_jalr_o  (rvc_jalr[i]),
        .rvc_call_o  (rvc_call[i]),
        .rvc_imm_o   (rvc_imm[i])
    );
  end

  instr_queue #(
      .CVA6Cfg(CVA6Cfg),
      .fetch_entry_t(fetch_entry_t)
  ) i_instr_queue (
      .clk_i              (clk_i),
      .rst_ni             (rst_ni),
      .flush_i            (flush_i),
      .instr_i            (instr),                 // from re-aligner
      .addr_i             (addr),                  // from re-aligner
      .exception_i        (fetch_ex_valid_q),      // from I$
      .exception_addr_i   (fetch_vaddr_q),
      .exception_gpaddr_i (fetch_gpaddr_q),
      .exception_tinst_i  (fetch_tinst_q),
      .exception_gva_i    (fetch_gva_q),
      .predict_address_i  (predict_address),
      .cf_type_i          (cf_type),
      .cf_valid_i         (cf_valid),
      .valid_i            (instruction_valid),     // from re-aligner
      .consumed_o         (instr_queue_consumed),
      .ready_o            (instr_queue_ready),
      .replay_o           (replay),
      .replay_addr_o      (replay_addr),
      .fetch_entry_o      (fetch_entry_o),         // to back-end
      .fetch_entry_valid_o(fetch_entry_valid_o),   // to back-end
      .fetch_entry_ready_i(fetch_entry_ready_i)    // to back-end
  );

endmodule
