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
// Author: Florian Zaruba    <zarubaf@iis.ee.ethz.ch>, ETH Zurich
//         Michael Schaffner <schaffner@iis.ee.ethz.ch>, ETH Zurich
// Date: 15.08.2018
// Description: Load Unit, takes care of all load requests
//
// Additional contributions by:
// August, 2023 - Cesar Fuguet <cesar.fuguettortolero@cea.fr>, CEA List
//          Add support for multiple outstanding load operations
//          to the data cache
// November, 2024 - Yannick Casamatta, Thales
//          OBI Protocol
// June, 2025 - Yannick Casamatta, Thales
//          YPB Protocol

`include "utils_macros.svh"

module load_unit
  import ariane_pkg::*;
#(
    parameter config_pkg::cva6_cfg_t CVA6Cfg = config_pkg::cva6_cfg_empty,
    parameter type ypb_load_req_t = logic,
    parameter type ypb_load_rsp_t = logic,
    parameter type exception_t = logic,
    parameter type lsu_ctrl_t = logic
) (
    // Subsystem Clock - SUBSYSTEM
    input  logic                                      clk_i,
    // Asynchronous reset active low - SUBSYSTEM
    input  logic                                      rst_ni,
    // Flush signal - CONTROLLER
    input  logic                                      flush_i,
    // Load request is valid - LSU_BYPASS
    input  logic                                      valid_i,
    // Load request input - LSU_BYPASS
    input  lsu_ctrl_t                                 lsu_ctrl_i,
    // Pop the load request from the LSU bypass FIFO - LSU_BYPASS
    output logic                                      pop_ld_o,
    // Load unit result is valid - ISSUE_STAGE
    output logic                                      valid_o,
    // Load transaction ID - ISSUE_STAGE
    output logic          [CVA6Cfg.TRANS_ID_BITS-1:0] trans_id_o,
    // Load result - ISSUE_STAGE
    output logic          [         CVA6Cfg.XLEN-1:0] result_o,
    // Load exception - ISSUE_STAGE
    output exception_t                                ex_o,
    // Data Endian mode - CSR_REGFILE
    input  logic                                      mbe_i,
    // Request address translation - MMU/PMP
    output logic                                      translation_req_o,
    // Virtual address - MMU/PMP
    output logic          [         CVA6Cfg.VLEN-1:0] vaddr_o,
    // Transformed trap instruction out - MMU
    output logic          [                     31:0] tinst_o,
    // Instruction is a hyp load store instruction - MMU
    output logic                                      hs_ld_st_inst_o,
    // Hyp load store with execute permissions - MMU
    output logic                                      hlvx_inst_o,
    // Physical address - MMU/PMP
    input  logic          [         CVA6Cfg.PLEN-1:0] paddr_i,
    // Excepted which appears before load - MMU/PMP
    input  exception_t                                ex_i,
    // Data TLB hit - MMU
    input  logic                                      dtlb_hit_i,
    // Physical page number from the DTLB - MMU
    input  logic          [         CVA6Cfg.PPNW-1:0] dtlb_ppn_i,
    // Page offset for address checking - STORE_UNIT
    output logic          [                     11:0] page_offset_o,
    // Indicates if the page offset matches a store unit entry - STORE_UNIT
    input  logic                                      page_offset_matches_i,
    // Store buffer is empty - STORE_UNIT
    input  logic                                      store_buffer_empty_i,
    // Transaction ID of the committing instruction - COMMIT_STAGE
    input  logic          [CVA6Cfg.TRANS_ID_BITS-1:0] commit_tran_id_i,
    // The committing instruction is dropped (speculative scoreboard) - COMMIT_STAGE
    input  logic                                      commit_drop_i,
    // Load cache response - DCACHE
    output ypb_load_req_t                             ypb_load_req_o,
    // Load cache request - DCACHE
    input  ypb_load_rsp_t                             ypb_load_rsp_i,

    // Presence of non-idempotent operations in the D$ write buffer - CACHES
    input logic dcache_wbuffer_not_ni_i,
    //Trigger module
    input logic sdtrig_load_cancel_i,
    input logic [CVA6Cfg.XLEN-1:0] sdtrig_load_action_i
);

  // in order to decouple the response interface from the request interface,
  // we need a a buffer which can hold all inflight memory load requests
  typedef struct packed {
    logic [CVA6Cfg.TRANS_ID_BITS-1:0] trans_id;   // scoreboard identifier
    logic [CVA6Cfg.VLEN-1:0]          vaddr;      // virtual address
    fu_op                             operation;  // type of load
  } ldbuf_t;


  // to support a throughput of one load per cycle, if the number of entries
  // of the load buffer is 1, implement a fall-through mode. This however
  // adds a combinational path between the request and response interfaces
  // towards the cache.
  localparam logic LDBUF_FALLTHROUGH = (CVA6Cfg.NrLoadBufEntries == 1);
  localparam int unsigned REQ_ID_BITS = CVA6Cfg.NrLoadBufEntries > 1 ? $clog2(
      CVA6Cfg.NrLoadBufEntries
  ) : 1;

  typedef logic [REQ_ID_BITS-1:0] ldbuf_id_t;

  logic [CVA6Cfg.NrLoadBufEntries-1:0] ldbuf_valid_q, ldbuf_valid_d;
  logic [CVA6Cfg.NrLoadBufEntries-1:0] ldbuf_flushed_q, ldbuf_flushed_d;
  ldbuf_t [CVA6Cfg.NrLoadBufEntries-1:0] ldbuf_q;
  logic ldbuf_empty, ldbuf_full;
  ldbuf_id_t ldbuf_free_index;
  logic ldbuf_w, ldbuf_w_q;

  // Transaction id of the load a trigger matched on, captured at the match:
  // the trigger module reports its cancel one cycle later, when lsu_ctrl_i
  // already presents the next request.
  logic [CVA6Cfg.TRANS_ID_BITS-1:0] sdtrig_trans_id_d, sdtrig_trans_id_q;
  // With TwoPhaseReq, an exception of a load in its second phase that meets
  // the response of an earlier load waits here for the output to be free.
  logic ex_s1_held_d, ex_s1_held_q;
  logic [CVA6Cfg.TRANS_ID_BITS-1:0] ex_s1_held_trans_id_d, ex_s1_held_trans_id_q;
  exception_t ex_s1_held_ex_d, ex_s1_held_ex_q;
  exception_t ex_s1_src;
  ldbuf_id_t ldbuf_windex, ldbuf_windex_q;
  logic      ldbuf_r;
  ldbuf_t    ldbuf_rdata;
  ldbuf_id_t ldbuf_rindex;
  logic      data_rvalid;
  ldbuf_id_t ldbuf_last_id_q;

  logic kill_req_d, kill_req_q;
  // Load address trigger: match on the presented load, its registered copy
  // for the physical phase, and the kill of that phase
  logic sdtrig_load_match, sdtrig_match_q, sdtrig_kill_s1;

  logic [CVA6Cfg.PLEN-1:0] paddr_q;
  ldbuf_id_t aid_q;
  logic [(CVA6Cfg.XLEN/8)-1:0] be_q;



  assign ldbuf_full = &ldbuf_valid_q && !(LDBUF_FALLTHROUGH && ldbuf_r);

  //
  //  buffer of outstanding loads

  //  write in the first available slot
  generate
    if (CVA6Cfg.NrLoadBufEntries > 1) begin : ldbuf_free_index_multi_gen
      lzc #(
          .WIDTH(CVA6Cfg.NrLoadBufEntries),
          .MODE (1'b0)                       // Count leading zeros
      ) lzc_windex_i (
          .in_i   (~ldbuf_valid_q),
          .cnt_o  (ldbuf_free_index),
          .empty_o(ldbuf_empty)
      );
    end else begin : ldbuf_free_index_single_gen
      assign ldbuf_free_index = 1'b0;
    end
  endgenerate

  assign ldbuf_windex = (LDBUF_FALLTHROUGH && ldbuf_r) ? ldbuf_rindex : ldbuf_free_index;

  always_comb begin : ldbuf_comb
    ldbuf_flushed_d = ldbuf_flushed_q;
    ldbuf_valid_d   = ldbuf_valid_q;

    //  Free read entry (in the case of fall-through mode, free the entry
    //  only if there is no pending load)
    if (ldbuf_r && (!LDBUF_FALLTHROUGH || !ldbuf_w)) begin
      ldbuf_valid_d[ldbuf_rindex] = 1'b0;
    end
    // Free on exception, or when a load trigger cancels the physical phase
    if (CVA6Cfg.TwoPhaseReq && (ldbuf_w_q && (ex_i.valid || sdtrig_kill_s1))) begin
      ldbuf_valid_d[ldbuf_windex_q] = 1'b0;
    end
    //  Track a new outstanding operation in the load buffer
    if (ldbuf_w) begin
      ldbuf_flushed_d[ldbuf_windex] = 1'b0;
      ldbuf_valid_d[ldbuf_windex]   = 1'b1;
    end
    //  In case of flush, raise the flushed flag in all slots, including a slot
    //  allocated in the same cycle: this branch comes after ldbuf_w so that it
    //  wins.
    if (flush_i) begin
      ldbuf_flushed_d = '1;
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin : ldbuf_ff
    if (!rst_ni) begin
      ldbuf_flushed_q       <= '0;
      ldbuf_valid_q         <= '0;
      ldbuf_last_id_q       <= '0;
      ldbuf_q               <= '0;
      sdtrig_trans_id_q     <= '0;
      ex_s1_held_q          <= 1'b0;
      ex_s1_held_trans_id_q <= '0;
      ex_s1_held_ex_q       <= '0;
    end else begin
      ldbuf_flushed_q <= ldbuf_flushed_d;
      ldbuf_valid_q <= ldbuf_valid_d;
      sdtrig_trans_id_q <= sdtrig_trans_id_d;
      ex_s1_held_q <= ex_s1_held_d && !flush_i;
      ex_s1_held_trans_id_q <= ex_s1_held_trans_id_d;
      ex_s1_held_ex_q <= ex_s1_held_ex_d;
      if (ldbuf_w) begin
        ldbuf_last_id_q                 <= ldbuf_windex;
        ldbuf_q[ldbuf_windex].trans_id  <= lsu_ctrl_i.trans_id;
        ldbuf_q[ldbuf_windex].vaddr     <= lsu_ctrl_i.vaddr;
        ldbuf_q[ldbuf_windex].operation <= lsu_ctrl_i.operation;
      end
    end
  end

  // page offset is defined as the lower 12 bits, feed through for address checker
  assign page_offset_o = lsu_ctrl_i.vaddr[11:0];
  // feed-through the virtual address for VA translation
  assign vaddr_o = lsu_ctrl_i.vaddr;
  assign hs_ld_st_inst_o = CVA6Cfg.RVH ? lsu_ctrl_i.hs_ld_st_inst : 1'b0;
  assign hlvx_inst_o = CVA6Cfg.RVH ? lsu_ctrl_i.hlvx_inst : 1'b0;
  // feed-through the transformed instruction for mmu
  assign tinst_o = CVA6Cfg.RVH ? lsu_ctrl_i.tinst : '0;

  // output address
  // we can now output the lower 12 bit as the index to the cache
  assign ypb_load_req_o.vaddr = lsu_ctrl_i.vaddr;

  // directly forward exception fields (valid bit is set below)
  // A load address trigger reports its own cause and the faulting address.
  //  An error on the response takes precedence over the MMU and trigger causes.
  assign ex_s1_src = ex_s1_held_q ? ex_s1_held_ex_q : ex_i;
  assign ex_o.cause = ypb_load_rsp_i.err                ? riscv::HARDWARE_ERROR :
                      (sdtrig_load_action_i != '0)      ? sdtrig_load_action_i  :
                                                          ex_s1_src.cause;
  //  On a response tval is the virtual address of the load that the response
  //  answers, held in the load buffer, as the load that caused it may have left
  //  lsu_ctrl_i long ago: the hardware error and the load data trigger report
  //  it.
  assign ex_o.tval = !CVA6Cfg.TvalEn ? ex_s1_src.tval :
                     data_rvalid ? {{CVA6Cfg.XLEN - CVA6Cfg.VLEN{1'b0}}, ldbuf_rdata.vaddr} :
                     (sdtrig_load_action_i != '0)        ? {{CVA6Cfg.XLEN - CVA6Cfg.VLEN{1'b0}}, lsu_ctrl_i.vaddr} :
                                                           ex_s1_src.tval;
  // The load data trigger break is added after the output register of the
  // load store unit, see load_store_unit.
  assign ex_o.timing = 1'b0;
  assign ex_o.tval2 = CVA6Cfg.RVH ? ex_s1_src.tval2 : '0;
  assign ex_o.tinst = CVA6Cfg.RVH ? ex_s1_src.tinst : '0;
  assign ex_o.gva = CVA6Cfg.RVH ? ex_s1_src.gva : 1'b0;

  logic [CVA6Cfg.PLEN-1:0] paddr;

  // With TwoPhaseReq paddr_i belongs to the request in s1, otherwise the request
  // carries its own address.
  assign paddr = CVA6Cfg.TwoPhaseReq ? paddr_i : lsu_ctrl_i.vaddr;

  // CHECK PMA regions

  logic paddr_is_cacheable;  // asserted if physical address is non-cacheable
  assign paddr_is_cacheable = config_pkg::is_inside_cacheable_regions(
      CVA6Cfg,
      {
        {64 - CVA6Cfg.DCACHE_INDEX_WIDTH - CVA6Cfg.DCACHE_TAG_WIDTH{1'b0}},
        ypb_load_req_o.paddr[ CVA6Cfg.DCACHE_TAG_WIDTH +
                                      CVA6Cfg.DCACHE_INDEX_WIDTH-1:
                                      CVA6Cfg.DCACHE_INDEX_WIDTH ],
        {CVA6Cfg.DCACHE_INDEX_WIDTH{1'b0}}
      }
  );

  logic paddr_nonidempotent;
  assign paddr_nonidempotent = config_pkg::is_inside_nonidempotent_regions(
      CVA6Cfg, {{52 - CVA6Cfg.PPNW{1'b0}}, dtlb_ppn_i, 12'd0}
  );

  // Check that NI operations follow the necessary conditions
  logic not_commit_time;
  logic inflight_stores;
  logic stall_ni_mem;
  assign not_commit_time = commit_tran_id_i != lsu_ctrl_i.trans_id;
  // A non-idempotent load waits to be the committing instruction. If commit
  // drops it (wrong path), it is retired without accessing memory.
  logic ni_load_dropped;
  assign ni_load_dropped = CVA6Cfg.SpeculativeSb && CVA6Cfg.NonIdemPotenceEn && valid_i &&
                           paddr_nonidempotent && commit_drop_i &&
                           commit_tran_id_i == lsu_ctrl_i.trans_id;
  assign inflight_stores = (!dcache_wbuffer_not_ni_i || !store_buffer_empty_i);

  typedef enum logic [1:0] {
    TRANSPARENT,
    REGISTRED
  } ypb_a_state_e;
  ypb_a_state_e ypb_a_state_d, ypb_a_state_q;

  // ---------------
  // Load Control
  // ---------------
  logic ex_s0, ex_s1, kill_s1;

  logic stall_ypb, stall_translation;
  logic data_req;

  assign ypb_load_req_o.kill_req = kill_req_q || kill_s1;

  // Non-idempotent stall, which gates the request itself: such a load must not
  // leave until it is the oldest in flight.
  assign stall_ni_mem = (inflight_stores || not_commit_time || ni_load_dropped) && (paddr_nonidempotent && CVA6Cfg.NonIdemPotenceEn);
  // A load address trigger matches on the load presented in this cycle: its
  // action comes with it and the cancel follows one cycle later. The load must
  // not reach memory, so the match holds its request back, as an exception of
  // the request cycle does.
  assign sdtrig_load_match = CVA6Cfg.SdtrigMcontrol6LoadAddr && valid_i &&
                             !sdtrig_load_cancel_i && sdtrig_load_action_i != '0;
  // Capture while the request is still the one being presented.
  assign sdtrig_trans_id_d = (valid_i && sdtrig_load_action_i != '0) ? lsu_ctrl_i.trans_id
                                                                    : sdtrig_trans_id_q;
  // With TwoPhaseReq the previous request presents its paddr (s1) in the cycle
  // the new one is accepted (s0), so its grant is checked in that same cycle.
  assign stall_ypb = (ypb_a_state_q == REGISTRED) ||
                     (CVA6Cfg.TwoPhaseReq && data_req && !ypb_load_rsp_i.pgnt);
  assign stall_translation = CVA6Cfg.MmuPresent ? translation_req_o && !dtlb_hit_i : 1'b0;

  assign ex_s0 = CVA6Cfg.MmuPresent && stall_translation && ex_i.valid;
  assign ex_s1 = ((CVA6Cfg.TwoPhaseReq ? ldbuf_w_q : valid_i) && ex_i.valid);
  // With TwoPhaseReq a matched load is already accepted in its first phase:
  // its physical phase is killed instead of sent.
  assign sdtrig_kill_s1 = CVA6Cfg.TwoPhaseReq && ldbuf_w_q && sdtrig_match_q;
  assign kill_s1 = CVA6Cfg.TwoPhaseReq ? ex_s1 || sdtrig_kill_s1 : 1'b0;

  assign data_rvalid = ypb_load_rsp_i.rvalid && !ldbuf_flushed_q[ldbuf_rindex];
  assign data_req = (CVA6Cfg.TwoPhaseReq ? ldbuf_w_q && !ex_s1 && !sdtrig_kill_s1 : ldbuf_w);

  always_comb begin : p_fsm_common
    // default assignment
    ypb_load_req_o.vreq = '0;
    kill_req_d = 1'b0;
    ldbuf_w = 1'b0;
    translation_req_o = 1'b0;
    //response
    trans_id_o = lsu_ctrl_i.trans_id;
    valid_o    = 1'b0;
    ex_o.valid = 1'b0;
    pop_ld_o = 1'b0; // release lsu_bypass fifo
    ex_s1_held_d = ex_s1_held_q;
    ex_s1_held_trans_id_d = ex_s1_held_trans_id_q;
    ex_s1_held_ex_d = ex_s1_held_ex_q;

    // REQUEST
    if (valid_i) begin
      translation_req_o = 1'b1;
      if (!page_offset_matches_i) begin
        ypb_load_req_o.vreq = !stall_translation && !stall_ni_mem;
        if (!CVA6Cfg.TwoPhaseReq || ypb_load_rsp_i.vgnt) begin
          if (stall_translation || stall_ni_mem || stall_ypb || ldbuf_full || flush_i || sdtrig_load_cancel_i ||
              (CVA6Cfg.TwoPhaseReq && ex_s1_held_q)) begin
            kill_req_d = 1'b1;  // TwoPhaseReq only: the first phase is accepted, the physical one will not follow
          end else begin
            ldbuf_w  = CVA6Cfg.TwoPhaseReq ? 1'b1 : !ex_s1 && !sdtrig_load_match;  // record request into outstanding load fifo and trigger physical request
            pop_ld_o = !ex_s1 && !sdtrig_load_match;  // release lsu_bypass fifo
          end
        end
      end
    end else begin
      kill_req_d = ldbuf_flushed_q[0];  //if there was a flush, a request might have started s0
    end
    // RETIRE LOAD
    // we got an rvalid and its corresponding request was not flushed
    if (data_rvalid) begin
      trans_id_o = ldbuf_q[ldbuf_rindex].trans_id;
      valid_o    = 1'b1;
      //  The response carries an error: retire the load as an exception rather
      //  than writing a corrupt value back.
      ex_o.valid = ypb_load_rsp_i.err;
      //  The output is taken: hold the second phase exception of this cycle.
      if (CVA6Cfg.TwoPhaseReq && ex_s1 && !ex_s1_held_q) begin
        ex_s1_held_d = 1'b1;
        ex_s1_held_trans_id_d = ldbuf_q[ldbuf_windex_q].trans_id;
        ex_s1_held_ex_d = ex_i;
        pop_ld_o = ldbuf_w && !sdtrig_load_match;
      end
      // RETIRE A HELD EXCEPTION
    end else if (CVA6Cfg.TwoPhaseReq && ex_s1_held_q) begin
      trans_id_o = ex_s1_held_trans_id_q;
      valid_o = 1'b1;
      ex_o.valid = 1'b1;
      ex_s1_held_d = 1'b0;
      // RETIRE EXCEPTION (low priority)
    end else if (ex_s1 || sdtrig_load_cancel_i) begin
      trans_id_o = (CVA6Cfg.SdtrigMcontrol6LoadAddr && sdtrig_load_cancel_i) ? sdtrig_trans_id_q :
                   (CVA6Cfg.TwoPhaseReq ? ldbuf_q[ldbuf_windex_q].trans_id : lsu_ctrl_i.trans_id);
      valid_o = 1'b1;
      ex_o.valid = 1'b1;
      // With TwoPhaseReq the faulting load released its lsu_bypass entry in its
      // first phase: only a load accepted in this cycle is released here.
      pop_ld_o = (CVA6Cfg.TwoPhaseReq && !sdtrig_load_cancel_i) ? ldbuf_w && !sdtrig_load_match
                                                                : !stall_translation;
      // RETIRE EXCEPTION (low priority)
    end else if (CVA6Cfg.MmuPresent && ex_s0) begin
      trans_id_o = lsu_ctrl_i.trans_id;
      valid_o    = 1'b1;
      ex_o.valid = 1'b1;
      // The faulting load leaves the lsu_bypass fifo: a load dropped by the
      // speculative scoreboard is not flushed out of it.
      pop_ld_o = 1'b1;
    end else if (ni_load_dropped) begin
      trans_id_o = lsu_ctrl_i.trans_id;
      valid_o    = 1'b1;
      pop_ld_o   = 1'b1;
    end

  end


  //default ypb state registred
  assign ypb_load_req_o.paddr = ypb_a_state_q == TRANSPARENT ? paddr : paddr_q;
  assign ypb_load_req_o.we = '0;
  // be, size and aid go with the first address phase (YPB 4.1): the first
  // phase with TwoPhaseReq, the physical phase without, held until it is granted.
  assign ypb_load_req_o.be = (!CVA6Cfg.TwoPhaseReq && ypb_a_state_q == REGISTRED) ? be_q
                                                                                : lsu_ctrl_i.be;
  assign ypb_load_req_o.size = (CVA6Cfg.IS_XLEN64) ? ariane_pkg::size_gen(
      ypb_load_req_o.be
  ) : ariane_pkg::size_gen_32(
      ypb_load_req_o.be
  );
  assign ypb_load_req_o.wdata = '0;
  assign ypb_load_req_o.aid = (!CVA6Cfg.TwoPhaseReq && ypb_a_state_q == REGISTRED) ?
      CVA6Cfg.IdWidth'(aid_q) : CVA6Cfg.IdWidth'(ldbuf_windex);
  assign ypb_load_req_o.atop = ariane_pkg::AMO_NONE;
  assign ypb_load_req_o.cbo_op = ariane_pkg::CBO_NONE;
  assign ypb_load_req_o.cacheable = paddr_is_cacheable;
  assign ypb_load_req_o.bufferable = config_pkg::is_inside_bufferable_regions(
      CVA6Cfg, {{64 - CVA6Cfg.PLEN{1'b0}}, ypb_load_req_o.paddr}
  );
  assign ypb_load_req_o.access_type = 1'b1;  //data


  assign ypb_load_req_o.rready = '1;  //always ready

  always_comb begin : p_fsm_ypb_a
    // default assignment
    ypb_a_state_d = ypb_a_state_q;
    ypb_load_req_o.preq    = 1'b0;

    unique case (ypb_a_state_q)
      TRANSPARENT: begin
        if (data_req) begin
          ypb_load_req_o.preq = 1'b1;
          if (!ypb_load_rsp_i.pgnt) begin
            ypb_a_state_d = REGISTRED;
          end
        end
      end

      REGISTRED: begin
        ypb_load_req_o.preq = 1'b1;
        if (ypb_load_rsp_i.pgnt) begin
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
      aid_q <= '0;
      be_q <= '0;
      kill_req_q <= '0;
      ldbuf_windex_q <= '0;
      ldbuf_w_q <= '0;
      sdtrig_match_q <= 1'b0;
    end else begin
      if (ypb_a_state_q == TRANSPARENT) begin
        paddr_q <= paddr;
        aid_q   <= ldbuf_id_t'(ypb_load_req_o.aid);
        be_q    <= ypb_load_req_o.be;
      end
      ypb_a_state_q <= ypb_a_state_d;
      kill_req_q <= kill_req_d;
      //if (!ex_s1) begin
      ldbuf_windex_q <= ldbuf_windex;
      ldbuf_w_q <= ldbuf_w;
      sdtrig_match_q <= sdtrig_load_match;
      //end
    end
  end


  // ---------------
  // Retire Load
  // ---------------
  assign ldbuf_rindex = (CVA6Cfg.NrLoadBufEntries > 1) ? ldbuf_id_t'(ypb_load_rsp_i.rid) : '0;
  assign ldbuf_rdata  = ldbuf_q[ldbuf_rindex];

  logic [CVA6Cfg.XLEN_ALIGN_BYTES-1:0] ldbuf_addroff;
  assign ldbuf_addroff = ldbuf_rdata.vaddr[CVA6Cfg.XLEN_ALIGN_BYTES-1:0];

  //  read the pending load buffer
  assign ldbuf_r    = ypb_load_rsp_i.rvalid;

  // ---------------
  // Sign Extend
  // ---------------
  logic [CVA6Cfg.XLEN-1:0] shifted_data;

  // realign as needed
  assign shifted_data = ypb_load_rsp_i.rdata >> {ldbuf_addroff, 3'b000};

  /*  // result mux (leaner code, but more logic stages.
    // can be used instead of the code below (in between //result mux fast) if timing is not so critical)
    always_comb begin
        unique case (ldbuf_rdata.operation)
            LWU:        result_o = shifted_data[31:0];
            LHU:        result_o = shifted_data[15:0];
            LBU:        result_o = shifted_data[7:0];
            LW:         result_o = 64'(signed'(shifted_data[31:0]));
            LH:         result_o = 64'(signed'(shifted_data[15:0]));
            LB:         result_o = 64'(signed'(shifted_data[ 7:0]));
            default:    result_o = shifted_data;
        endcase
    end  */

  // The internals of CVA6 are little endian. When mstatus.MBE is set the
  // processor treats data memory as big endian, so the byte order is reversed
  // as the data enters the core through a load.
  logic [CVA6Cfg.XLEN-1:0] endian_data;
  always_comb begin
    endian_data = shifted_data;
    if (CVA6Cfg.BigEndianEn && mbe_i) begin
      case (ldbuf_rdata.operation)
        ariane_pkg::LB, ariane_pkg::LBU, ariane_pkg::HLV_B, ariane_pkg::HLV_BU, ariane_pkg::FLB: begin
          // a single byte needs no reordering
          endian_data[7:0] = {shifted_data[7:0]};
        end
        ariane_pkg::LH, ariane_pkg::LHU, ariane_pkg::HLV_H, ariane_pkg::HLV_HU, ariane_pkg::HLVX_HU, ariane_pkg::FLH: begin
          endian_data[15:0] = {<<8{shifted_data[15:0]}};
        end
        ariane_pkg::LW, ariane_pkg::LWU, ariane_pkg::HLV_W, ariane_pkg::HLV_WU, ariane_pkg::HLVX_WU, ariane_pkg::FLW,
        ariane_pkg::AMO_LRW, ariane_pkg::AMO_SCW, ariane_pkg::AMO_SWAPW, ariane_pkg::AMO_ADDW,
        ariane_pkg::AMO_ANDW, ariane_pkg::AMO_ORW, ariane_pkg::AMO_XORW, ariane_pkg::AMO_MAXW,
        ariane_pkg::AMO_MAXWU, ariane_pkg::AMO_MINW, ariane_pkg::AMO_MINWU: begin
          endian_data[31:0] = {<<8{shifted_data[31:0]}};
        end
        default: begin
          endian_data[CVA6Cfg.XLEN-1:0] = {<<8{shifted_data[CVA6Cfg.XLEN-1:0]}};
        end
      endcase
    end
  end

  // result mux fast
  logic [        (CVA6Cfg.XLEN/8)-1:0] rdata_sign_bits;
  logic [CVA6Cfg.XLEN_ALIGN_BYTES-1:0] rdata_offset;
  logic rdata_sign_bit, rdata_is_signed, rdata_is_fp_signed;


  // prepare these signals for faster selection in the next cycle
  assign rdata_is_signed    =   ldbuf_rdata.operation inside {ariane_pkg::LW,  ariane_pkg::LH,  ariane_pkg::LB, ariane_pkg::HLV_W, ariane_pkg::HLV_H, ariane_pkg::HLV_B};
  assign rdata_is_fp_signed =   ldbuf_rdata.operation inside {ariane_pkg::FLW, ariane_pkg::FLH, ariane_pkg::FLB};
  // In big endian mode nothing is added to the offset to reach the byte that
  // holds the sign bit: it is always the lowest addressed one.
  assign rdata_offset       = ((ldbuf_rdata.operation inside {ariane_pkg::LW,  ariane_pkg::FLW, ariane_pkg::HLV_W}) && CVA6Cfg.IS_XLEN64 && !(CVA6Cfg.BigEndianEn && mbe_i)) ? ldbuf_addroff + 3 :
                                ( ldbuf_rdata.operation inside {ariane_pkg::LH,  ariane_pkg::FLH, ariane_pkg::HLV_H} && !(CVA6Cfg.BigEndianEn && mbe_i))                     ? ldbuf_addroff + 1 :
                                                                                                                         ldbuf_addroff;

  for (genvar i = 0; i < (CVA6Cfg.XLEN / 8); i++) begin : gen_sign_bits
    assign rdata_sign_bits[i] = ypb_load_rsp_i.rdata[(i+1)*8-1];
  end


  // select correct sign bit in parallel to result shifter above
  // pull to 0 if unsigned
  assign rdata_sign_bit = (rdata_is_signed && rdata_sign_bits[rdata_offset]) || (CVA6Cfg.FpPresent && rdata_is_fp_signed);

  // result mux
  always_comb begin
    unique case (ldbuf_rdata.operation)
      ariane_pkg::LW, ariane_pkg::LWU, ariane_pkg::HLV_W, ariane_pkg::HLV_WU, ariane_pkg::HLVX_WU:
      result_o = {{CVA6Cfg.XLEN - 32{rdata_sign_bit}}, endian_data[31:0]};
      ariane_pkg::LH, ariane_pkg::LHU, ariane_pkg::HLV_H, ariane_pkg::HLV_HU, ariane_pkg::HLVX_HU:
      result_o = {{CVA6Cfg.XLEN - 32 + 16{rdata_sign_bit}}, endian_data[15:0]};
      ariane_pkg::LB, ariane_pkg::LBU, ariane_pkg::HLV_B, ariane_pkg::HLV_BU:
      result_o = {{CVA6Cfg.XLEN - 32 + 24{rdata_sign_bit}}, endian_data[7:0]};
      default: begin
        // FLW, FLH and FLB have been defined here in default case to improve Code Coverage
        if (CVA6Cfg.FpPresent) begin
          unique case (ldbuf_rdata.operation)
            ariane_pkg::FLW: begin
              result_o = {{CVA6Cfg.XLEN - 32{rdata_sign_bit}}, endian_data[31:0]};
            end
            ariane_pkg::FLH: begin
              result_o = {{CVA6Cfg.XLEN - 32 + 16{rdata_sign_bit}}, endian_data[15:0]};
            end
            ariane_pkg::FLB: begin
              result_o = {{CVA6Cfg.XLEN - 32 + 24{rdata_sign_bit}}, endian_data[7:0]};
            end
            default: begin
              result_o = endian_data[CVA6Cfg.XLEN-1:0];
            end
          endcase
        end else begin
          result_o = endian_data[CVA6Cfg.XLEN-1:0];
        end
      end
    endcase
  end
  // end result mux fast

  ///////////////////////////////////////////////////////
  // assertions
  ///////////////////////////////////////////////////////

  //pragma translate_off
  hardware_error_on_response :
  assert property (@(posedge clk_i) disable iff (~rst_ni)
        (valid_o && ex_o.valid && ex_o.cause == riscv::HARDWARE_ERROR)
        |-> (data_rvalid && ypb_load_rsp_i.err))
  else `ASSERT_ERROR("[load_unit] HARDWARE_ERROR reported without an errored load response");
  logic paddr_req_nonidempotent;
  assign paddr_req_nonidempotent = config_pkg::is_inside_nonidempotent_regions(
      CVA6Cfg, 64'(ypb_load_req_o.paddr)
  );
  // A load whose address matched a load trigger does not reach memory.
  logic sdtrig_matched_pending;
  assign sdtrig_matched_pending = CVA6Cfg.TwoPhaseReq ? (ldbuf_w_q && sdtrig_match_q)
                                                      : sdtrig_load_match;
  sdtrig_load_addr_no_access :
  assert property (@(posedge clk_i) disable iff (~rst_ni)
        (CVA6Cfg.SdtrigMcontrol6LoadAddr && sdtrig_matched_pending && ypb_a_state_q == TRANSPARENT)
        |-> !ypb_load_req_o.preq)
  else `ASSERT_ERROR("[load_unit] load sent to memory although its address matched a load trigger");
  // Transaction ID of the load presented on the physical request. With
  // TwoPhaseReq it is the entry recorded in s0. Without, a request sent in its
  // own cycle is only written into the load buffer at the next edge, while a
  // request held for its grant was recorded at aid_q.
  logic [CVA6Cfg.TRANS_ID_BITS-1:0] preq_trans_id;
  assign preq_trans_id = CVA6Cfg.TwoPhaseReq ? ldbuf_q[ldbuf_windex_q].trans_id :
                         (ypb_a_state_q == REGISTRED) ? ldbuf_q[aid_q].trans_id :
                                                        lsu_ctrl_i.trans_id;
  ni_load_at_commit :
  assert property (@(posedge clk_i) disable iff (~rst_ni)
        (CVA6Cfg.NonIdemPotenceEn && ypb_load_req_o.preq && ypb_load_rsp_i.pgnt && paddr_req_nonidempotent)
        |-> (preq_trans_id == commit_tran_id_i &&
             !(CVA6Cfg.SpeculativeSb && commit_drop_i)))
  else `ASSERT_ERROR("[load_unit] non-idempotent load sent to memory before its commit");
  initial
    assert (CVA6Cfg.DcacheIdWidth >= REQ_ID_BITS)
    else `ASSERT_FATAL("DcacheIdWidth parameter is not wide enough to encode pending loads");
  // check invalid offsets, but only issue a warning as these conditions actually trigger a load address misaligned exception
  addr_offset0 :
  assert property (@(posedge clk_i) disable iff (~rst_ni)
        ldbuf_w_q |->  (ldbuf_q[ldbuf_windex_q].operation inside {ariane_pkg::LW, ariane_pkg::LWU}) |-> ldbuf_q[ldbuf_windex_q].vaddr[CVA6Cfg.XLEN_ALIGN_BYTES-1:0] < 5)
  else `ASSERT_WARNING("invalid address offset used with {LW, LWU}");
  addr_offset1 :
  assert property (@(posedge clk_i) disable iff (~rst_ni)
        ldbuf_w_q |->  (ldbuf_q[ldbuf_windex_q].operation inside {ariane_pkg::LH, ariane_pkg::LHU}) |-> ldbuf_q[ldbuf_windex_q].vaddr[CVA6Cfg.XLEN_ALIGN_BYTES-1:0] < 7)
  else `ASSERT_WARNING("invalid address offset used with {LH, LHU}");
  addr_offset2 :
  assert property (@(posedge clk_i) disable iff (~rst_ni)
        ldbuf_w_q |->  (ldbuf_q[ldbuf_windex_q].operation inside {ariane_pkg::LB, ariane_pkg::LBU}) |-> ldbuf_q[ldbuf_windex_q].vaddr[CVA6Cfg.XLEN_ALIGN_BYTES-1:0] < 8)
  else `ASSERT_FATAL("invalid address offset used with {LB, LBU}");
  //pragma translate_on

endmodule
