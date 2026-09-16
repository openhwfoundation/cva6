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
// Date: 22.05.2017
// Description: Store Unit, takes care of all store requests and atomic memory operations (AMOs)


module store_unit
  import ariane_pkg::*;
#(
    parameter config_pkg::cva6_cfg_t CVA6Cfg = config_pkg::cva6_cfg_empty,
    parameter type ypb_store_req_t = logic,
    parameter type ypb_store_rsp_t = logic,
    parameter type ypb_amo_req_t = logic,
    parameter type ypb_amo_rsp_t = logic,
    parameter type exception_t = logic,
    parameter type lsu_ctrl_t = logic
) (
    // Subsystem Clock - SUBSYSTEM
    input logic clk_i,
    // Asynchronous reset active low - SUBSYSTEM
    input logic rst_ni,
    // Flush - CONTROLLER
    input logic flush_i,
    // TO_BE_COMPLETED - ACC_DISPATCHER
    input logic stall_st_pending_i,
    // No store pending - COMMIT_STAGE
    output logic no_st_pending_o,
    // Store buffer is empty - LOAD_UNIT
    output logic store_buffer_empty_o,
    // Store instruction is valid - ISSUE_STAGE
    input logic valid_i,
    // Data input - ISSUE_STAGE
    input lsu_ctrl_t lsu_ctrl_i,
    // Pop store - LSU_BYPASS
    output logic pop_st_o,
    // Instruction commit - COMMIT_STAGE
    input logic commit_i,
    // Commit queue is ready to accept another commit request - COMMIT_STAGE
    output logic commit_ready_o,
    // TO_BE_COMPLETED - TO_BE_COMPLETED
    input logic amo_valid_commit_i,
    // Store result is valid - ISSUE_STAGE
    output logic valid_o,
    // Transaction ID - ISSUE_STAGE
    output logic [CVA6Cfg.TRANS_ID_BITS-1:0] trans_id_o,
    // Store result - ISSUE_STAGE
    output logic [CVA6Cfg.XLEN-1:0] result_o,
    // Store exception output - ISSUE_STAGE
    output exception_t ex_o,
    // Address translation request - MMU/PMP
    output logic translation_req_o,
    // Virtual address - MMU/PMP
    output logic [CVA6Cfg.VLEN-1:0] vaddr_o,
    // Transformed trap instruction out - TO_BE_COMPLETED
    output logic [31:0] tinst_o,
    // TO_BE_COMPLETED - TO_BE_COMPLETED
    output logic hs_ld_st_inst_o,
    // TO_BE_COMPLETED - TO_BE_COMPLETED
    output logic hlvx_inst_o,
    // Physical address - MMU/PMP
    input logic [CVA6Cfg.PLEN-1:0] paddr_i,
    // Exception raised before store - MMU/PMP
    input exception_t ex_i,
    // Data TLB hit - lsu
    input logic dtlb_hit_i,
    // Address to be checked - load_unit
    input logic [11:0] page_offset_i,
    // Address check result - load_unit
    output logic page_offset_matches_o,
    // Store cache response - DCACHE
    output ypb_store_req_t ypb_store_req_o,
    // Store cache request - DCACHE
    input ypb_store_rsp_t ypb_store_rsp_i,
    // AMO request - DCACHE
    output ypb_amo_req_t ypb_amo_req_o,
    // AMO response - DCACHE
    input ypb_amo_rsp_t ypb_amo_rsp_i
);

  // align data to address e.g.: shift data to be naturally 64
  function automatic [CVA6Cfg.XLEN-1:0] data_align(logic [2:0] addr, logic [63:0] data);
    // Set addr[2] to 1'b0 when 32bits
    logic [ 2:0] addr_tmp = {(addr[2] && CVA6Cfg.IS_XLEN64), addr[1:0]};
    logic [63:0] data_tmp = {64{1'b0}};
    case (addr_tmp)
      3'b000: data_tmp[CVA6Cfg.XLEN-1:0] = {data[CVA6Cfg.XLEN-1:0]};
      3'b001:
      data_tmp[CVA6Cfg.XLEN-1:0] = {data[CVA6Cfg.XLEN-9:0], data[CVA6Cfg.XLEN-1:CVA6Cfg.XLEN-8]};
      3'b010:
      data_tmp[CVA6Cfg.XLEN-1:0] = {data[CVA6Cfg.XLEN-17:0], data[CVA6Cfg.XLEN-1:CVA6Cfg.XLEN-16]};
      3'b011:
      data_tmp[CVA6Cfg.XLEN-1:0] = {data[CVA6Cfg.XLEN-25:0], data[CVA6Cfg.XLEN-1:CVA6Cfg.XLEN-24]};
      default:
      if (CVA6Cfg.IS_XLEN64) begin
        case (addr_tmp)
          3'b100:  data_tmp = {data[31:0], data[63:32]};
          3'b101:  data_tmp = {data[23:0], data[63:24]};
          3'b110:  data_tmp = {data[15:0], data[63:16]};
          3'b111:  data_tmp = {data[7:0], data[63:8]};
          default: data_tmp = {data[63:0]};
        endcase
      end
    endcase
    return data_tmp[CVA6Cfg.XLEN-1:0];
  endfunction

  // it doesn't matter what we are writing back as stores don't return anything
  assign result_o   = lsu_ctrl_i.data;

  // directly forward exception fields (valid bit is set below)
  assign ex_o.cause = ex_i.cause;
  assign ex_o.tval  = ex_i.tval;
  assign ex_o.tval2 = CVA6Cfg.RVH ? ex_i.tval2 : '0;
  assign ex_o.tinst = CVA6Cfg.RVH ? ex_i.tinst : '0;
  assign ex_o.gva   = CVA6Cfg.RVH ? ex_i.gva : 1'b0;

  // store buffer control signals
  logic instr_is_amo;
  assign instr_is_amo = is_amo(lsu_ctrl_i.operation);
  // keep the data and the byte enable for the second cycle (after address translation)
  logic [CVA6Cfg.XLEN-1:0] st_data, st_data_n, st_data_q;
  logic [(CVA6Cfg.XLEN/8)-1:0] st_be, st_be_n, st_be_q;
  logic [1:0] st_data_size, st_data_size_n, st_data_size_q;
  amo_t amo_op, amo_op_d, amo_op_q;

  logic store_buffer_valid, store_buffer_valid_d, store_buffer_valid_q;
  logic store_buffer_valid_no_flush, store_buffer_valid_no_flush_d, store_buffer_valid_no_flush_q;

  logic amo_buffer_valid, amo_buffer_valid_d, amo_buffer_valid_q;

  logic store_buffer_ready, amo_buffer_ready;

  logic [CVA6Cfg.TRANS_ID_BITS-1:0] trans_id_n, trans_id_q;

  logic ex_s0, ex_s1;
  logic stall_translation;

  // output assignments
  assign vaddr_o = lsu_ctrl_i.vaddr;  // virtual address
  assign hs_ld_st_inst_o = CVA6Cfg.RVH ? lsu_ctrl_i.hs_ld_st_inst : 1'b0;
  assign hlvx_inst_o = CVA6Cfg.RVH ? lsu_ctrl_i.hlvx_inst : 1'b0;
  assign tinst_o = CVA6Cfg.RVH ? lsu_ctrl_i.tinst : '0;  // transformed instruction

  assign stall_translation = CVA6Cfg.MmuPresent ? translation_req_o && !dtlb_hit_i : 1'b0;

  assign ex_s0 = CVA6Cfg.MmuPresent && stall_translation && ex_i.valid;
  assign ex_s1 = CVA6Cfg.MmuPresent ? (store_buffer_valid_q || (CVA6Cfg.RVA && amo_buffer_valid_q)) && ex_i.valid : valid_i && ex_i.valid;

  always_comb begin : store_control
    // default assignment
    translation_req_o             = 1'b0;
    valid_o                       = 1'b0;
    amo_buffer_valid_d            = 1'b0;
    store_buffer_valid_d          = 1'b0;
    store_buffer_valid_no_flush_d = 1'b0;
    pop_st_o                      = 1'b0;
    ex_o.valid                    = 1'b0;
    trans_id_n                    = lsu_ctrl_i.trans_id;
    trans_id_o                    = lsu_ctrl_i.trans_id;

    // REQUEST
    if (valid_i) begin
      translation_req_o = 1'b1;
      if (!CVA6Cfg.MmuPresent || !stall_translation) begin
        if (CVA6Cfg.RVA && instr_is_amo) begin
          if (amo_buffer_ready) begin
            pop_st_o = 1'b1;
            amo_buffer_valid_d = !flush_i;
            // RETIRE STORE NO MMU
            if (!CVA6Cfg.MmuPresent) begin
              trans_id_o = lsu_ctrl_i.trans_id;
              valid_o    = 1'b1;
              ex_o.valid = ex_s1;
            end
          end
        end else begin
          if (store_buffer_ready) begin
            pop_st_o = 1'b1;
            store_buffer_valid_d = !flush_i;
            store_buffer_valid_no_flush_d = 1'b1;
            // RETIRE STORE NO MMU
            if (!CVA6Cfg.MmuPresent) begin
              trans_id_o = lsu_ctrl_i.trans_id;
              valid_o    = 1'b1;
              ex_o.valid = ex_s1;
            end
          end
        end
      end
    end
    // RETIRE STORE WITH MMU
    if (CVA6Cfg.MmuPresent) begin
      if (store_buffer_valid_q || (CVA6Cfg.RVA && amo_buffer_valid_q)) begin
        trans_id_o = trans_id_q;
        valid_o    = 1'b1;
        ex_o.valid = ex_s1;
      end else if (ex_s0) begin
        trans_id_o = lsu_ctrl_i.trans_id;
        valid_o    = 1'b1;
        ex_o.valid = 1'b1;
        pop_st_o = dtlb_hit_i;
      end
    end
  end

  // -----------
  // Re-aligner
  // -----------
  // re-align the write data to comply with the address offset
  always_comb begin
    st_be_n = lsu_ctrl_i.be;
    // don't shift the data if we are going to perform an AMO as we still need to operate on this data
    st_data_n = (CVA6Cfg.RVA && instr_is_amo) ? lsu_ctrl_i.data[CVA6Cfg.XLEN-1:0] :
        data_align(lsu_ctrl_i.vaddr[2:0], {{64 - CVA6Cfg.XLEN{1'b0}}, lsu_ctrl_i.data});
    st_data_size_n = extract_transfer_size(lsu_ctrl_i.operation);
    // save AMO op for next cycle
    if (CVA6Cfg.RVA) begin
      case (lsu_ctrl_i.operation)
        AMO_LRW, AMO_LRD:     amo_op_d = AMO_LR;
        AMO_SCW, AMO_SCD:     amo_op_d = AMO_SC;
        AMO_SWAPW, AMO_SWAPD: amo_op_d = AMO_SWAP;
        AMO_ADDW, AMO_ADDD:   amo_op_d = AMO_ADD;
        AMO_ANDW, AMO_ANDD:   amo_op_d = AMO_AND;
        AMO_ORW, AMO_ORD:     amo_op_d = AMO_OR;
        AMO_XORW, AMO_XORD:   amo_op_d = AMO_XOR;
        AMO_MAXW, AMO_MAXD:   amo_op_d = AMO_MAX;
        AMO_MAXWU, AMO_MAXDU: amo_op_d = AMO_MAXU;
        AMO_MINW, AMO_MIND:   amo_op_d = AMO_MIN;
        AMO_MINWU, AMO_MINDU: amo_op_d = AMO_MINU;
        default:              amo_op_d = AMO_NONE;
      endcase
    end else begin
      amo_op_d = AMO_NONE;
    end
  end

  assign st_be = CVA6Cfg.MmuPresent ? st_be_q : st_be_n;
  assign st_data = CVA6Cfg.MmuPresent ? st_data_q : st_data_n;
  assign st_data_size = CVA6Cfg.MmuPresent ? st_data_size_q : st_data_size_n;
  assign amo_op = CVA6Cfg.MmuPresent ? amo_op_q : amo_op_d;
  assign store_buffer_valid = CVA6Cfg.MmuPresent ? store_buffer_valid_q && !ex_s1 : store_buffer_valid_d;
  assign store_buffer_valid_no_flush = CVA6Cfg.MmuPresent ? store_buffer_valid_no_flush_q && !ex_s1 : store_buffer_valid_no_flush_d;
  assign amo_buffer_valid = CVA6Cfg.MmuPresent ? amo_buffer_valid_q && !ex_s1 : amo_buffer_valid_d;

  // ---------------
  // Store Queue
  // ---------------
  store_buffer #(
      .CVA6Cfg(CVA6Cfg),
      .ypb_store_req_t(ypb_store_req_t),
      .ypb_store_rsp_t(ypb_store_rsp_t)
  ) store_buffer_i (
      .clk_i,
      .rst_ni,
      .flush_i,
      .stall_st_pending_i,
      .no_st_pending_o,
      .store_buffer_empty_o,
      .page_offset_i,
      .page_offset_matches_o,
      .commit_i,
      .commit_ready_o,
      .ready_o              (store_buffer_ready),
      .valid_i              (store_buffer_valid),
      // the flush signal can be critical and we need this valid
      // signal to check whether the page_offset matches or not,
      // functionaly it doesn't make a difference whether we use
      // the correct valid signal or not as we are flushing
      // the whole pipeline anyway
      .valid_without_flush_i(store_buffer_valid_no_flush),
      .paddr_i              (paddr_i),
      .data_i               (st_data),
      .be_i                 (st_be),
      .data_size_i          (st_data_size),
      .ypb_store_req_o      (ypb_store_req_o),
      .ypb_store_rsp_i      (ypb_store_rsp_i)
  );

  if (CVA6Cfg.RVA) begin
    amo_buffer #(
        .CVA6Cfg(CVA6Cfg),
        .ypb_amo_req_t(ypb_amo_req_t),
        .ypb_amo_rsp_t(ypb_amo_rsp_t)
    ) i_amo_buffer (
        .clk_i,
        .rst_ni,
        .flush_i,
        .valid_i           (amo_buffer_valid),
        .ready_o           (amo_buffer_ready),
        .paddr_i           (paddr_i),
        .amo_op_i          (amo_op),
        .data_i            (st_data),
        .data_size_i       (st_data_size),
        .ypb_amo_req_o     (ypb_amo_req_o),
        .ypb_amo_rsp_i     (ypb_amo_rsp_i),
        .amo_valid_commit_i(amo_valid_commit_i),
        .no_st_pending_i   (no_st_pending_o)
    );
  end else begin
    assign amo_buffer_ready = '1;
    assign ypb_amo_req_o    = '0;
  end

  // ---------------
  // Registers
  // ---------------
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      st_be_q                       <= '0;
      st_data_q                     <= '0;
      st_data_size_q                <= '0;
      trans_id_q                    <= '0;
      amo_op_q                      <= AMO_NONE;
      amo_buffer_valid_q            <= '0;
      store_buffer_valid_q          <= '0;
      store_buffer_valid_no_flush_q <= '0;
    end else begin
      st_be_q                       <= st_be_n;
      st_data_q                     <= st_data_n;
      trans_id_q                    <= trans_id_n;
      st_data_size_q                <= st_data_size_n;
      amo_op_q                      <= amo_op_d;
      amo_buffer_valid_q            <= amo_buffer_valid_d;
      store_buffer_valid_q          <= store_buffer_valid_d;
      store_buffer_valid_no_flush_q <= store_buffer_valid_no_flush_d;
    end
  end

endmodule
