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
    // Load cache response - DCACHE
    output ypb_load_req_t                             ypb_load_req_o,
    // Load cache request - DCACHE
    input  ypb_load_rsp_t                             ypb_load_rsp_i,

    // Presence of non-idempotent operations in the D$ write buffer - CACHES
    input logic dcache_wbuffer_not_ni_i
);

  // in order to decouple the response interface from the request interface,
  // we need a a buffer which can hold all inflight memory load requests
  typedef struct packed {
    logic [CVA6Cfg.TRANS_ID_BITS-1:0]    trans_id;        // scoreboard identifier
    logic [CVA6Cfg.XLEN_ALIGN_BYTES-1:0] address_offset;  // least significant bits of the address
    fu_op                                operation;       // type of load
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
  ldbuf_id_t ldbuf_windex, ldbuf_windex_q;
  logic      ldbuf_r;
  ldbuf_t    ldbuf_rdata;
  ldbuf_id_t ldbuf_rindex;
  ldbuf_id_t ldbuf_last_id_q;

  logic kill_req_d, kill_req_q;

  logic [CVA6Cfg.PLEN-1:0] paddr_q;
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

    //  In case of flush, raise the flushed flag in all slots.
    if (flush_i) begin
      ldbuf_flushed_d = '1;
    end
    //  Free read entry (in the case of fall-through mode, free the entry
    //  only if there is no pending load)
    if (ldbuf_r && (!LDBUF_FALLTHROUGH || !ldbuf_w)) begin
      ldbuf_valid_d[ldbuf_rindex] = 1'b0;
    end
    // Free on exception
    if (CVA6Cfg.MmuPresent && (ldbuf_w_q && ex_i.valid)) begin
      ldbuf_valid_d[ldbuf_windex_q] = 1'b0;
    end
    //  Track a new outstanding operation in the load buffer
    if (ldbuf_w) begin
      ldbuf_flushed_d[ldbuf_windex] = 1'b0;
      ldbuf_valid_d[ldbuf_windex]   = 1'b1;
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin : ldbuf_ff
    if (!rst_ni) begin
      ldbuf_flushed_q <= '0;
      ldbuf_valid_q   <= '0;
      ldbuf_last_id_q <= '0;
      ldbuf_q         <= '0;
    end else begin
      ldbuf_flushed_q <= ldbuf_flushed_d;
      ldbuf_valid_q   <= ldbuf_valid_d;
      if (ldbuf_w) begin
        ldbuf_last_id_q                      <= ldbuf_windex;
        ldbuf_q[ldbuf_windex].trans_id       <= lsu_ctrl_i.trans_id;
        ldbuf_q[ldbuf_windex].address_offset <= lsu_ctrl_i.vaddr[CVA6Cfg.XLEN_ALIGN_BYTES-1:0];
        ldbuf_q[ldbuf_windex].operation      <= lsu_ctrl_i.operation;
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
  assign ex_o.cause = ex_i.cause;
  assign ex_o.tval = ex_i.tval;
  assign ex_o.tval2 = CVA6Cfg.RVH ? ex_i.tval2 : '0;
  assign ex_o.tinst = CVA6Cfg.RVH ? ex_i.tinst : '0;
  assign ex_o.gva = CVA6Cfg.RVH ? ex_i.gva : 1'b0;

  logic [CVA6Cfg.PLEN-1:0] paddr;

  assign paddr = CVA6Cfg.MmuPresent ? paddr_i : lsu_ctrl_i.vaddr; //paddr_i is delayed in s1, but no s1 in mode no MMU

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
  logic stall_ni;
  assign not_commit_time = commit_tran_id_i != lsu_ctrl_i.trans_id;
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
  logic data_req, data_rvalid;

  assign ypb_load_req_o.kill_req = kill_req_q || kill_s1;

  assign stall_ni = (inflight_stores || not_commit_time) && (paddr_nonidempotent && CVA6Cfg.NonIdemPotenceEn);
  assign stall_ypb = (ypb_a_state_q == REGISTRED);  //&& !ypb_load_rsp_i.pgnt;
  assign stall_translation = CVA6Cfg.MmuPresent ? translation_req_o && !dtlb_hit_i : 1'b0;

  assign ex_s0 = CVA6Cfg.MmuPresent && stall_translation && ex_i.valid;
  assign ex_s1 = ((CVA6Cfg.MmuPresent ? ldbuf_w_q : valid_i) && ex_i.valid);
  assign kill_s1 = CVA6Cfg.MmuPresent ? ex_s1 : 1'b0;

  assign data_rvalid = ypb_load_rsp_i.rvalid && !ldbuf_flushed_q[ldbuf_rindex];
  assign data_req = (CVA6Cfg.MmuPresent ? ldbuf_w_q && !ex_s1 : ldbuf_w);

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

    // REQUEST
    if (valid_i) begin
      translation_req_o = 1'b1;
      if (!page_offset_matches_i) begin
        ypb_load_req_o.vreq = !stall_translation && !stall_ni;
        if (!CVA6Cfg.MmuPresent || ypb_load_rsp_i.vgnt) begin
          if (stall_translation || stall_ni || stall_ypb || ldbuf_full || flush_i) begin
            kill_req_d = 1'b1;  // MmuPresent only: next cycle is s2 but we need to kill because not ready to send tag
          end else begin
            ldbuf_w  = CVA6Cfg.MmuPresent ? 1'b1 : !ex_s1;  // record request into outstanding load fifo and trigger physical request
            pop_ld_o = !ex_s1;  // release lsu_bypass fifo
          end
        end
      end
    end else begin
      kill_req_d = ldbuf_flushed_q;  //if there was a flush, a request might have started s0
    end
    // RETIRE LOAD
    // we got an rvalid and it's corresponding request was not flushed
    if (data_rvalid) begin
      trans_id_o = ldbuf_q[ldbuf_rindex].trans_id;
      valid_o    = 1'b1;
      ex_o.valid = 1'b0;
      // RETIRE EXCEPTION (low priority)
    end else if (ex_s1) begin
      trans_id_o = CVA6Cfg.MmuPresent ? ldbuf_q[ldbuf_windex_q].trans_id : lsu_ctrl_i.trans_id;
      valid_o    = 1'b1;
      ex_o.valid = 1'b1;
      pop_ld_o = !stall_translation;//1'b1; // release lsu_bypass fifo
      // RETIRE EXCEPTION (low priority)
    end else if (CVA6Cfg.MmuPresent && ex_s0) begin
      trans_id_o = lsu_ctrl_i.trans_id;
      valid_o    = 1'b1;
      ex_o.valid = 1'b1;
      pop_ld_o = !stall_translation;//1'b1; // release lsu_bypass fifo
    end

  end


  //default ypb state registred
  assign ypb_load_req_o.paddr = ypb_a_state_q == TRANSPARENT ? paddr : paddr_q;
  assign ypb_load_req_o.we = '0;
  // With an MMU paddr comes from s1 while lsu_ctrl_i already presents the next
  // request, so the registered byte enable is the one belonging to it.
  assign ypb_load_req_o.be = (ypb_a_state_q == TRANSPARENT) && valid_i && !CVA6Cfg.MmuPresent
                             ? lsu_ctrl_i.be : be_q;
  assign ypb_load_req_o.size = (CVA6Cfg.XLEN == 64) ? ariane_pkg::size_gen(
      ypb_load_req_o.be
  ) : ariane_pkg::size_gen_32(
      ypb_load_req_o.be
  );
  assign ypb_load_req_o.wdata = '0;
  assign ypb_load_req_o.aid = (!CVA6Cfg.MmuPresent && (ypb_a_state_q == TRANSPARENT)) ? ldbuf_windex : ldbuf_windex_q;
  assign ypb_load_req_o.atop = ariane_pkg::AMO_NONE;
  assign ypb_load_req_o.cacheable = paddr_is_cacheable;
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
      be_q <= '0;
      kill_req_q <= '0;
      ldbuf_windex_q <= '0;
      ldbuf_w_q <= '0;
    end else begin
      if (ypb_a_state_q == TRANSPARENT) begin
        paddr_q <= paddr;
        if (valid_i) be_q <= lsu_ctrl_i.be;
      end
      ypb_a_state_q <= ypb_a_state_d;
      kill_req_q <= kill_req_d;
      //if (!ex_s1) begin
      ldbuf_windex_q <= ldbuf_windex;
      ldbuf_w_q <= ldbuf_w;
      //end
    end
  end


  // ---------------
  // Retire Load
  // ---------------
  assign ldbuf_rindex = (CVA6Cfg.NrLoadBufEntries > 1) ? ldbuf_id_t'(ypb_load_rsp_i.rid) : 1'b0;
  assign ldbuf_rdata = ldbuf_q[ldbuf_rindex];

  //  read the pending load buffer
  assign ldbuf_r    = ypb_load_rsp_i.rvalid;

  // ---------------
  // Sign Extend
  // ---------------
  logic [CVA6Cfg.XLEN-1:0] shifted_data;

  // realign as needed
  assign shifted_data = ypb_load_rsp_i.rdata >> {ldbuf_rdata.address_offset, 3'b000};

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

  // result mux fast
  logic [        (CVA6Cfg.XLEN/8)-1:0] rdata_sign_bits;
  logic [CVA6Cfg.XLEN_ALIGN_BYTES-1:0] rdata_offset;
  logic rdata_sign_bit, rdata_is_signed, rdata_is_fp_signed;


  // prepare these signals for faster selection in the next cycle
  assign rdata_is_signed    =   ldbuf_rdata.operation inside {ariane_pkg::LW,  ariane_pkg::LH,  ariane_pkg::LB, ariane_pkg::HLV_W, ariane_pkg::HLV_H, ariane_pkg::HLV_B};
  assign rdata_is_fp_signed =   ldbuf_rdata.operation inside {ariane_pkg::FLW, ariane_pkg::FLH, ariane_pkg::FLB};
  assign rdata_offset       = ((ldbuf_rdata.operation inside {ariane_pkg::LW,  ariane_pkg::FLW, ariane_pkg::HLV_W}) & CVA6Cfg.IS_XLEN64) ? ldbuf_rdata.address_offset + 3 :
                                ( ldbuf_rdata.operation inside {ariane_pkg::LH,  ariane_pkg::FLH, ariane_pkg::HLV_H})                     ? ldbuf_rdata.address_offset + 1 :
                                                                                                                         ldbuf_rdata.address_offset;

  for (genvar i = 0; i < (CVA6Cfg.XLEN / 8); i++) begin : gen_sign_bits
    assign rdata_sign_bits[i] = ypb_load_rsp_i.rdata[(i+1)*8-1];
  end


  // select correct sign bit in parallel to result shifter above
  // pull to 0 if unsigned
  assign rdata_sign_bit = rdata_is_signed & rdata_sign_bits[rdata_offset] | (CVA6Cfg.FpPresent && rdata_is_fp_signed);

  // result mux
  always_comb begin
    unique case (ldbuf_rdata.operation)
      ariane_pkg::LW, ariane_pkg::LWU, ariane_pkg::HLV_W, ariane_pkg::HLV_WU, ariane_pkg::HLVX_WU:
      result_o = {{CVA6Cfg.XLEN - 32{rdata_sign_bit}}, shifted_data[31:0]};
      ariane_pkg::LH, ariane_pkg::LHU, ariane_pkg::HLV_H, ariane_pkg::HLV_HU, ariane_pkg::HLVX_HU:
      result_o = {{CVA6Cfg.XLEN - 32 + 16{rdata_sign_bit}}, shifted_data[15:0]};
      ariane_pkg::LB, ariane_pkg::LBU, ariane_pkg::HLV_B, ariane_pkg::HLV_BU:
      result_o = {{CVA6Cfg.XLEN - 32 + 24{rdata_sign_bit}}, shifted_data[7:0]};
      default: begin
        // FLW, FLH and FLB have been defined here in default case to improve Code Coverage
        if (CVA6Cfg.FpPresent) begin
          unique case (ldbuf_rdata.operation)
            ariane_pkg::FLW: begin
              result_o = {{CVA6Cfg.XLEN - 32{rdata_sign_bit}}, shifted_data[31:0]};
            end
            ariane_pkg::FLH: begin
              result_o = {{CVA6Cfg.XLEN - 32 + 16{rdata_sign_bit}}, shifted_data[15:0]};
            end
            ariane_pkg::FLB: begin
              result_o = {{CVA6Cfg.XLEN - 32 + 24{rdata_sign_bit}}, shifted_data[7:0]};
            end
            default: begin
              result_o = shifted_data[CVA6Cfg.XLEN-1:0];
            end
          endcase
        end else begin
          result_o = shifted_data[CVA6Cfg.XLEN-1:0];
        end
      end
    endcase
  end
  // end result mux fast

  ///////////////////////////////////////////////////////
  // assertions
  ///////////////////////////////////////////////////////

  //pragma translate_off
  initial
    assert (CVA6Cfg.DcacheIdWidth >= REQ_ID_BITS)
    else `ASSERT_FATAL("DcacheIdWidth parameter is not wide enough to encode pending loads");
  // check invalid offsets, but only issue a warning as these conditions actually trigger a load address misaligned exception
  addr_offset0 :
  assert property (@(posedge clk_i) disable iff (~rst_ni)
        ldbuf_w_q |->  (ldbuf_q[ldbuf_windex_q].operation inside {ariane_pkg::LW, ariane_pkg::LWU}) |-> ldbuf_q[ldbuf_windex_q].address_offset < 5)
  else `ASSERT_FATAL("invalid address offset used with {LW, LWU}");
  addr_offset1 :
  assert property (@(posedge clk_i) disable iff (~rst_ni)
        ldbuf_w_q |->  (ldbuf_q[ldbuf_windex_q].operation inside {ariane_pkg::LH, ariane_pkg::LHU}) |-> ldbuf_q[ldbuf_windex_q].address_offset < 7)
  else `ASSERT_FATAL("invalid address offset used with {LH, LHU}");
  addr_offset2 :
  assert property (@(posedge clk_i) disable iff (~rst_ni)
        ldbuf_w_q |->  (ldbuf_q[ldbuf_windex_q].operation inside {ariane_pkg::LB, ariane_pkg::LBU}) |-> ldbuf_q[ldbuf_windex_q].address_offset < 8)
  else `ASSERT_FATAL("invalid address offset used with {LB, LBU}");
  //pragma translate_on

endmodule
