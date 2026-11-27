// Copyright 2023 Commissariat a l'Energie Atomique et aux Energies
//                Alternatives (CEA)
//
// Licensed under the Solderpad Hardware License, Version 2.1 (the “License”);
// you may not use this file except in compliance with the License.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
// You may obtain a copy of the License at https://solderpad.org/licenses/
//
// Authors: Cesar Fuguet
// Date: February, 2023
// Description: Interface adapter for the CVA6 core
//
// Additional contributions by:
// June, 2025 - Yannick Casamatta, Thales : YBP Protocol


module cva6_hpdcache_if_adapter
//  Parameters
//  {{{
#(
    parameter config_pkg::cva6_cfg_t CVA6Cfg = config_pkg::cva6_cfg_empty,
    parameter hpdcache_pkg::hpdcache_cfg_t HPDcacheCfg = '0,
    parameter type hpdcache_tag_t = logic,
    parameter type hpdcache_req_offset_t = logic,
    parameter type hpdcache_req_sid_t = logic,
    parameter type hpdcache_req_t = logic,
    parameter type hpdcache_rsp_t = logic,
    parameter type ypb_store_req_t = logic,
    parameter type ypb_store_rsp_t = logic,
    parameter type ypb_amo_req_t = logic,
    parameter type ypb_amo_rsp_t = logic,
    parameter type ypb_load_req_t = logic,
    parameter type ypb_load_rsp_t = logic,
    parameter type ypb_mmu_ptw_req_t = logic,
    parameter type ypb_mmu_ptw_rsp_t = logic,
    parameter type ypb_zcmt_req_t = logic,
    parameter type ypb_zcmt_rsp_t = logic,
    parameter bit InvalidateOnFlush = 1'b0,
    parameter bit IsLoadPort = 1'b1,
    parameter bit IsMmuPtwPort = 1'b0,
    parameter bit IsZcmtPort = 1'b0
)
//  }}}

//  Ports
//  {{{
(
    //  Clock and active-low reset pins
    input logic clk_i,
    input logic rst_ni,

    //  Port ID
    input hpdcache_req_sid_t hpdcache_req_sid_i,

    //  Request/response ports from/to the CVA6 core
    input  ypb_store_req_t   ypb_store_req_i,
    output ypb_store_rsp_t   ypb_store_rsp_o,
    input  ypb_amo_req_t     ypb_amo_req_i,
    output ypb_amo_rsp_t     ypb_amo_rsp_o,
    input  ypb_load_req_t    ypb_load_req_i,
    output ypb_load_rsp_t    ypb_load_rsp_o,
    input  ypb_mmu_ptw_req_t ypb_mmu_ptw_req_i,
    output ypb_mmu_ptw_rsp_t ypb_mmu_ptw_rsp_o,
    input  ypb_zcmt_req_t    ypb_zcmt_req_i,
    output ypb_zcmt_rsp_t    ypb_zcmt_rsp_o,

    //  Dcache flush signal
    input  logic cva6_dcache_flush_i,
    output logic cva6_dcache_flush_ack_o,

    //  Request port to the L1 Dcache
    output logic                        hpdcache_req_valid_o,
    input  logic                        hpdcache_req_ready_i,
    output hpdcache_req_t               hpdcache_req_o,
    output logic                        hpdcache_req_abort_o,
    output hpdcache_tag_t               hpdcache_req_tag_o,
    output hpdcache_pkg::hpdcache_pma_t hpdcache_req_pma_o,

    //  Response port from the L1 Dcache
    input logic          hpdcache_rsp_valid_i,
    input hpdcache_rsp_t hpdcache_rsp_i
);
  //  }}}

  //  Internal nets and registers
  //  {{{
  typedef enum {
    FLUSH_IDLE,
    FLUSH_PEND
  } flush_fsm_t;

  // ----------------------
  // Addr split Functions
  // ----------------------
  // extract tag from plen addr
  function automatic logic [CVA6Cfg.DCACHE_TAG_WIDTH-1:0] get_paddr_tag(
      logic [CVA6Cfg.PLEN-1:0] addr);
    return addr[CVA6Cfg.DCACHE_TAG_WIDTH+CVA6Cfg.DCACHE_INDEX_WIDTH-1 : CVA6Cfg.DCACHE_INDEX_WIDTH];
  endfunction

  // extract index/offset from vlen addr
  function automatic logic [CVA6Cfg.DCACHE_TAG_WIDTH-1:0] get_vaddr_index(
      logic [CVA6Cfg.VLEN-1:0] addr);
    return addr[CVA6Cfg.DCACHE_INDEX_WIDTH-1:0];
  endfunction

  // extract index/offset from plen addr
  function automatic logic [CVA6Cfg.DCACHE_TAG_WIDTH-1:0] get_paddr_index(
      logic [CVA6Cfg.PLEN-1:0] addr);
    return addr[CVA6Cfg.DCACHE_INDEX_WIDTH-1:0];
  endfunction

  // Write policy of a request. A data cache with both policies writes back in
  // a bufferable region and writes through elsewhere; a data cache with a
  // single policy applies it.
  function automatic hpdcache_pkg::hpdcache_wr_policy_hint_t get_wr_policy_hint(logic bufferable);
    if (CVA6Cfg.CacheWritePolicy != config_pkg::CACHE_WT_WB) begin
      return hpdcache_pkg::HPDCACHE_WR_POLICY_AUTO;
    end
    return bufferable ? hpdcache_pkg::HPDCACHE_WR_POLICY_WB : hpdcache_pkg::HPDCACHE_WR_POLICY_WT;
  endfunction

  logic forward_store, forward_amo;
  logic hpdcache_req_is_uncacheable;
  hpdcache_req_t hpdcache_req;
  //  }}}

  //  Request forwarding
  //  {{{
  generate
    //  LOAD request
    //  {{{
    if (IsLoadPort == 1'b1) begin : load_port_gen

      logic [1:0] load_data_size;

      //    Request forwarding YPB channel A

      assign hpdcache_req.wdata = '0;
      assign hpdcache_req.op = hpdcache_pkg::HPDCACHE_REQ_LOAD;
      assign hpdcache_req.size = ypb_load_req_i.size;
      assign hpdcache_req.sid = hpdcache_req_sid_i;

      assign hpdcache_req.need_rsp = 1'b1;

      assign hpdcache_req_abort_o = ypb_load_req_i.kill_req;

      if (CVA6Cfg.TwoPhaseReq) begin
        // The request is done in 2 phases, s0: index, s1: tag
        assign hpdcache_req.phys_indexed = 1'b0;
        assign hpdcache_req_valid_o = ypb_load_req_i.vreq;
        assign hpdcache_req.addr_offset = get_vaddr_index(ypb_load_req_i.vaddr);
        assign hpdcache_req.addr_tag = '0;  // unused on virtually indexed request
        assign hpdcache_req.be = ypb_load_req_i.be;
        assign hpdcache_req.tid = ypb_load_req_i.aid;
        assign hpdcache_req.pma.uncacheable = 1'b0;  // unused on virtually indexed request
        assign hpdcache_req.pma.bufferable = 1'b0;  // unused on virtually indexed request
        assign hpdcache_req.pma.io = 1'b0;  // unused on virtually indexed request
        assign hpdcache_req.pma.wr_policy_hint = hpdcache_pkg::HPDCACHE_WR_POLICY_AUTO;  // unused on virtually indexed request

        assign hpdcache_req_pma_o.uncacheable = !ypb_load_req_i.cacheable;
        assign hpdcache_req_pma_o.bufferable = ypb_load_req_i.bufferable;
        assign hpdcache_req_pma_o.io = 1'b0;
        assign hpdcache_req_pma_o.wr_policy_hint = get_wr_policy_hint(ypb_load_req_i.bufferable);
        assign hpdcache_req_tag_o = get_paddr_tag(ypb_load_req_i.paddr);
        assign ypb_load_rsp_o.vgnt = hpdcache_req_ready_i;
        assign ypb_load_rsp_o.pgnt = 1'b1;  //if hpdcache is always ready to accept tag in s1

      end else begin
        // The request is done in 1 phase, s0: index and tag
        assign hpdcache_req.phys_indexed = 1'b1;
        assign hpdcache_req_valid_o = ypb_load_req_i.preq;
        assign hpdcache_req.addr_offset = get_paddr_index(ypb_load_req_i.paddr);
        assign hpdcache_req.addr_tag = get_paddr_tag(ypb_load_req_i.paddr);
        assign hpdcache_req.be = ypb_load_req_i.be;
        assign hpdcache_req.tid = ypb_load_req_i.aid;
        assign hpdcache_req.pma.uncacheable = !ypb_load_req_i.cacheable;
        assign hpdcache_req.pma.bufferable = ypb_load_req_i.bufferable;
        assign hpdcache_req.pma.io = 1'b0;
        assign hpdcache_req.pma.wr_policy_hint = get_wr_policy_hint(ypb_load_req_i.bufferable);

        assign hpdcache_req_pma_o.uncacheable = '0;  // unused on physically indexed request
        assign hpdcache_req_pma_o.bufferable = '0;  // unused on physically indexed request
        assign hpdcache_req_pma_o.io = '0;  // unused on physically indexed request
        assign hpdcache_req_pma_o.wr_policy_hint = hpdcache_pkg::HPDCACHE_WR_POLICY_AUTO;
        ;  // unused on physically indexed request
        assign hpdcache_req_tag_o  = '0;  // unused on physically indexed request

        assign ypb_load_rsp_o.vgnt = 1'b0;
        assign ypb_load_rsp_o.pgnt = ypb_load_req_i.preq && hpdcache_req_ready_i;
      end

      //    Response forwarding ypb channel R

      assign ypb_load_rsp_o.rvalid = hpdcache_rsp_valid_i && !hpdcache_rsp_i.aborted;
      assign ypb_load_rsp_o.rid = hpdcache_rsp_i.tid;
      assign ypb_load_rsp_o.err = hpdcache_rsp_i.error;
      assign ypb_load_rsp_o.rdata = hpdcache_rsp_i.rdata;

      //  Assertions
      //  {{{
      //    pragma translate_off
      flush_on_load_port_assert :
      assert property (@(posedge clk_i) disable iff (rst_ni !== 1'b1) (cva6_dcache_flush_i == 1'b0))
      else $error("Flush unsupported on load adapters");
      // The HPDcache reads the tag of a virtually indexed request in the cycle
      // after it accepts it: the physical phase follows at once, or the request
      // is killed.
      if (CVA6Cfg.TwoPhaseReq) begin : gen_vipt_tag_next_cycle_assert
        vipt_tag_next_cycle_assert :
        assert property (@(posedge clk_i) disable iff (rst_ni !== 1'b1)
            (ypb_load_req_i.vreq && hpdcache_req_ready_i)
            |=> (ypb_load_req_i.preq || ypb_load_req_i.kill_req))
        else $error("Virtually indexed load accepted without a tag or a kill in the next cycle");
      end
      //    pragma translate_on
      //  }}}
    end  //  }}}

         //  {{{

    else if (IsMmuPtwPort == 1'b1) begin : mmu_ptw_port_gen
      //  MMU request
      //  {{{
      // TODO Check why it's not physically indexed
      //    Request forwarding
      assign hpdcache_req_valid_o = ypb_mmu_ptw_req_i.vreq;
      assign hpdcache_req.addr_offset = get_vaddr_index(ypb_mmu_ptw_req_i.vaddr);
      assign hpdcache_req.wdata = '0;
      assign hpdcache_req.op = hpdcache_pkg::HPDCACHE_REQ_LOAD;
      assign hpdcache_req.be = ypb_mmu_ptw_req_i.be;
      assign hpdcache_req.size = ypb_mmu_ptw_req_i.size;
      assign hpdcache_req.sid = hpdcache_req_sid_i;
      assign hpdcache_req.tid = ypb_mmu_ptw_req_i.aid;
      assign hpdcache_req.need_rsp = 1'b1;
      assign hpdcache_req.phys_indexed = 1'b0;
      assign hpdcache_req.addr_tag = '0;  // unused on virtually indexed request
      assign hpdcache_req.pma.uncacheable = 1'b0;  // unused on virtually indexed request
      assign hpdcache_req.pma.bufferable = 1'b0;  // unused on virtually indexed request
      assign hpdcache_req.pma.io = 1'b0;  // unused on virtually indexed request
      assign hpdcache_req.pma.wr_policy_hint = hpdcache_pkg::HPDCACHE_WR_POLICY_AUTO;

      assign hpdcache_req_abort_o = ypb_mmu_ptw_req_i.kill_req;
      assign hpdcache_req_tag_o = get_paddr_tag(ypb_mmu_ptw_req_i.paddr);

      assign hpdcache_req_pma_o.uncacheable = !ypb_mmu_ptw_req_i.cacheable;
      assign hpdcache_req_pma_o.bufferable = ypb_mmu_ptw_req_i.bufferable;
      assign hpdcache_req_pma_o.io = 1'b0;
      assign hpdcache_req_pma_o.wr_policy_hint = get_wr_policy_hint(ypb_mmu_ptw_req_i.bufferable);

      //    Response forwarding
      assign ypb_mmu_ptw_rsp_o.rvalid = hpdcache_rsp_valid_i;
      assign ypb_mmu_ptw_rsp_o.rdata = hpdcache_rsp_i.rdata;
      assign ypb_mmu_ptw_rsp_o.rid = hpdcache_rsp_i.tid;
      assign ypb_mmu_ptw_rsp_o.vgnt = hpdcache_req_ready_i;
      assign ypb_mmu_ptw_rsp_o.pgnt = hpdcache_req_ready_i;

      //  Assertions
      //  {{{
      //    pragma translate_off
      flush_on_load_port_assert :
      assert property (@(posedge clk_i) disable iff (rst_ni !== 1'b1) (cva6_dcache_flush_i == 1'b0))
      else $error("Flush unsupported on mmu adapters");
      //    pragma translate_on
      //  }}}
    end  //  }}}
else if (IsZcmtPort == 1'b1) begin : zcmt_port_gen
      //  ZCMT request
      //  {{{


      //    Request forwarding
      assign hpdcache_req_valid_o = ypb_zcmt_req_i.preq;
      assign hpdcache_req.addr_offset = get_paddr_index(ypb_zcmt_req_i.paddr);
      assign hpdcache_req.wdata = '0;
      assign hpdcache_req.op = hpdcache_pkg::HPDCACHE_REQ_LOAD;
      assign hpdcache_req.be = ypb_zcmt_req_i.be;
      assign hpdcache_req.size = ypb_zcmt_req_i.size;
      assign hpdcache_req.sid = hpdcache_req_sid_i;
      assign hpdcache_req.tid = ypb_zcmt_req_i.aid;
      assign hpdcache_req.need_rsp = 1'b1;
      assign hpdcache_req.phys_indexed = 1'b0;
      assign hpdcache_req.addr_tag = '0;  // unused on virtually indexed request
      assign hpdcache_req.pma.uncacheable = '0;  // unused on virtually indexed request
      assign hpdcache_req.pma.bufferable = '0;  // unused on virtually indexed request
      assign hpdcache_req.pma.io = 1'b0;
      assign hpdcache_req.pma.wr_policy_hint = hpdcache_pkg::HPDCACHE_WR_POLICY_AUTO;

      assign hpdcache_req_abort_o = ypb_zcmt_req_i.kill_req;
      assign hpdcache_req_tag_o = get_paddr_tag(ypb_zcmt_req_i.paddr);

      assign hpdcache_req_pma_o.uncacheable = !ypb_zcmt_req_i.cacheable;
      assign hpdcache_req_pma_o.bufferable = ypb_zcmt_req_i.bufferable;
      assign hpdcache_req_pma_o.io = 1'b0;
      assign hpdcache_req_pma_o.wr_policy_hint = get_wr_policy_hint(ypb_zcmt_req_i.bufferable);

      //    Response forwarding
      assign ypb_zcmt_rsp_o.rvalid = hpdcache_rsp_valid_i;
      assign ypb_zcmt_rsp_o.rdata = hpdcache_rsp_i.rdata;
      assign ypb_zcmt_rsp_o.rid = hpdcache_rsp_i.tid;
      assign ypb_zcmt_rsp_o.vgnt = hpdcache_req_ready_i;
      assign ypb_zcmt_rsp_o.pgnt = hpdcache_req_ready_i;

      //  Assertions
      //  {{{
      //    pragma translate_off
      flush_on_load_port_assert :
      assert property (@(posedge clk_i) disable iff (rst_ni !== 1'b1) (cva6_dcache_flush_i == 1'b0))
      else $error("Flush unsupported on Zcmt adapters");
      //    pragma translate_on
      //  }}}
    end  //  }}}

         //  {{{
    else begin : store_amo_gen
      //  STORE/AMO request
      logic amo_is_word, amo_is_word_hi;
      logic                           [63:0] amo_data;
      logic                           [ 7:0] amo_data_be;
      logic                           [ 1:0] amo_data_size;
      logic                           [ 1:0] store_data_size;

      hpdcache_pkg::hpdcache_req_op_t        amo_op;
      logic                           [31:0] amo_resp_word;
      logic                                  amo_pending_q;

      hpdcache_req_t                         hpdcache_req_amo;
      hpdcache_req_t                         hpdcache_req_store;
      hpdcache_req_t                         hpdcache_req_flush;

      flush_fsm_t flush_fsm_q, flush_fsm_d;

      logic forward_store, forward_amo, forward_flush;
      logic flush_not_sent;
      hpdcache_pkg::hpdcache_req_op_t store_op;

      //  DCACHE flush request
      //  {{{
      always_ff @(posedge clk_i or negedge rst_ni) begin : flush_ff
        if (!rst_ni) begin
          flush_fsm_q <= FLUSH_IDLE;
          flush_not_sent <= '0;
        end else begin
          flush_fsm_q <= flush_fsm_d;

          if (flush_fsm_q == FLUSH_IDLE && cva6_dcache_flush_i && !hpdcache_req_ready_i)
            flush_not_sent <= '1;
          else flush_not_sent <= forward_flush;

        end
      end

      always_comb begin : flush_comb
        forward_flush = 1'b0;
        cva6_dcache_flush_ack_o = 1'b0;

        flush_fsm_d = flush_fsm_q;

        case (flush_fsm_q)
          FLUSH_IDLE: begin
            if (cva6_dcache_flush_i || flush_not_sent) begin
              forward_flush = 1'b1;
              if (hpdcache_req_ready_i) begin
                flush_fsm_d = FLUSH_PEND;
              end
            end
          end
          FLUSH_PEND: begin
            if (hpdcache_rsp_valid_i) begin
              if (hpdcache_rsp_i.tid == '0) begin
                cva6_dcache_flush_ack_o = 1'b1;
                flush_fsm_d = FLUSH_IDLE;
              end
            end
          end
          default: begin
          end
        endcase
      end
      //  }}}

      // CBO logic
      //  {{{
      always_comb begin : store_cmo_comb
        store_op = hpdcache_pkg::HPDCACHE_REQ_STORE;

        if (CVA6Cfg.RVZiCbom) begin
          case (ypb_store_req_i.cbo_op)
            ariane_pkg::CBO_INVAL: store_op = hpdcache_pkg::HPDCACHE_REQ_CMO_INVAL_NLINE;
            ariane_pkg::CBO_CLEAN: store_op = hpdcache_pkg::HPDCACHE_REQ_CMO_FLUSH_NLINE;
            ariane_pkg::CBO_FLUSH: store_op = hpdcache_pkg::HPDCACHE_REQ_CMO_FLUSH_INVAL_NLINE;
            default: ;  // store - above
          endcase
        end
      end
      //  }}}

      //  AMO logic
      //  {{{

      always_comb begin : amo_op_comb
        unique case (ypb_amo_req_i.atop)
          ariane_pkg::AMO_LR:   amo_op = hpdcache_pkg::HPDCACHE_REQ_AMO_LR;
          ariane_pkg::AMO_SC:   amo_op = hpdcache_pkg::HPDCACHE_REQ_AMO_SC;
          ariane_pkg::AMO_SWAP: amo_op = hpdcache_pkg::HPDCACHE_REQ_AMO_SWAP;
          ariane_pkg::AMO_ADD:  amo_op = hpdcache_pkg::HPDCACHE_REQ_AMO_ADD;
          ariane_pkg::AMO_AND:  amo_op = hpdcache_pkg::HPDCACHE_REQ_AMO_AND;
          ariane_pkg::AMO_OR:   amo_op = hpdcache_pkg::HPDCACHE_REQ_AMO_OR;
          ariane_pkg::AMO_XOR:  amo_op = hpdcache_pkg::HPDCACHE_REQ_AMO_XOR;
          ariane_pkg::AMO_MAX:  amo_op = hpdcache_pkg::HPDCACHE_REQ_AMO_MAX;
          ariane_pkg::AMO_MAXU: amo_op = hpdcache_pkg::HPDCACHE_REQ_AMO_MAXU;
          ariane_pkg::AMO_MIN:  amo_op = hpdcache_pkg::HPDCACHE_REQ_AMO_MIN;
          ariane_pkg::AMO_MINU: amo_op = hpdcache_pkg::HPDCACHE_REQ_AMO_MINU;
          default:              amo_op = hpdcache_pkg::HPDCACHE_REQ_LOAD;
        endcase
      end
      //  }}}

      //  Request forwarding
      //  {{{
      assign amo_data_size = ypb_amo_req_i.size;
      assign amo_is_word = (amo_data_size == 2'b10);
      assign amo_is_word_hi = ypb_amo_req_i.paddr[2];
      if (CVA6Cfg.IS_XLEN64) begin : amo_data_64_gen
        assign amo_data = amo_is_word ? {2{ypb_amo_req_i.wdata[0+:32]}} : ypb_amo_req_i.wdata;
        assign amo_data_be = amo_is_word_hi ? 8'hf0 : amo_is_word ? 8'h0f : 8'hff;
      end else begin : amo_data_32_gen
        assign amo_data    = {32'b0, ypb_amo_req_i.wdata};
        assign amo_data_be = 8'h0f;
      end

      assign hpdcache_req_amo = '{
              addr_offset: get_paddr_index(ypb_amo_req_i.paddr),
              wdata: amo_data,
              op: amo_op,
              be: amo_data_be,
              size: ypb_amo_req_i.size,
              sid: hpdcache_req_sid_i,
              tid: '1,
              need_rsp: 1'b1,
              phys_indexed: 1'b1,
              addr_tag: get_paddr_tag(ypb_amo_req_i.paddr),
              pma: '{
                  bufferable: ypb_amo_req_i.bufferable,
                  uncacheable: !ypb_amo_req_i.cacheable,
                  io: 1'b0,
                  wr_policy_hint: get_wr_policy_hint(ypb_amo_req_i.bufferable)
              }
          };

      assign hpdcache_req_store = '{
              addr_offset: get_paddr_index(ypb_store_req_i.paddr),
              wdata: ypb_store_req_i.wdata,
              op: store_op,
              be: ypb_store_req_i.be,
              size: ypb_store_req_i.size,
              sid: hpdcache_req_sid_i,
              tid: '0,
              need_rsp: 1'b1,
              phys_indexed: 1'b1,
              addr_tag: get_paddr_tag(ypb_store_req_i.paddr),
              pma: '{
                  bufferable: ypb_store_req_i.bufferable,
                  uncacheable: !ypb_store_req_i.cacheable,
                  io: 1'b0,
                  wr_policy_hint: get_wr_policy_hint(ypb_store_req_i.bufferable)
              }
          };

      assign hpdcache_req_flush = '{
              addr_offset: '0,
              addr_tag: '0,
              wdata: '0,
              op:
              InvalidateOnFlush
              ?
              hpdcache_pkg::HPDCACHE_REQ_CMO_FLUSH_INVAL_ALL
              :
              hpdcache_pkg::HPDCACHE_REQ_CMO_FLUSH_ALL,
              be: '0,
              size: '0,
              sid: hpdcache_req_sid_i,
              tid: '0,
              need_rsp: 1'b1,
              phys_indexed: 1'b0,
              pma: '{
                  bufferable: 1'b0,
                  uncacheable: 1'b0,
                  io: 1'b0,
                  wr_policy_hint: hpdcache_pkg::HPDCACHE_WR_POLICY_AUTO
              }
          };

      assign forward_store = ypb_store_req_i.preq;
      assign forward_amo = CVA6Cfg.RVA ? ypb_amo_req_i.preq : '0;

      assign hpdcache_req_valid_o = (forward_amo & ~amo_pending_q) | forward_store | forward_flush;

      assign hpdcache_req = forward_amo   ? hpdcache_req_amo :
                            forward_store ? hpdcache_req_store : hpdcache_req_flush;

      assign hpdcache_req_abort_o = 1'b0;  // unused on physically indexed requests
      assign hpdcache_req_tag_o = '0;  // unused on physically indexed requests
      assign hpdcache_req_pma_o.uncacheable = 1'b0;
      assign hpdcache_req_pma_o.bufferable = 1'b0;
      assign hpdcache_req_pma_o.io = 1'b0;
      assign hpdcache_req_pma_o.wr_policy_hint = hpdcache_pkg::HPDCACHE_WR_POLICY_AUTO;
      //  }}}

      //  Response forwarding
      //  {{{
      if (CVA6Cfg.IS_XLEN64) begin : amo_resp_64_gen
        assign amo_resp_word = amo_is_word_hi
                             ? hpdcache_rsp_i.rdata[0][32 +: 32]
                             : hpdcache_rsp_i.rdata[0][0  +: 32];
      end else begin : amo_resp_32_gen
        assign amo_resp_word = hpdcache_rsp_i.rdata[0];
      end

      logic ypb_store_valid;
      logic ypb_amo_valid;

      assign ypb_store_valid = hpdcache_rsp_valid_i && (hpdcache_rsp_i.tid != '1);
      assign ypb_amo_valid = hpdcache_rsp_valid_i && (hpdcache_rsp_i.tid == '1);

      //ypb
      assign ypb_store_rsp_o.pgnt = ypb_store_req_i.preq & hpdcache_req_ready_i;
      assign ypb_store_rsp_o.rvalid = ypb_store_valid;
      assign ypb_store_rsp_o.rid = '0;
      assign ypb_store_rsp_o.err = '0;
      assign ypb_store_rsp_o.rdata = '0;
      assign ypb_store_rsp_o.vgnt = '0;


      assign ypb_amo_rsp_o.pgnt = hpdcache_req_ready_i & forward_amo;
      assign ypb_amo_rsp_o.rvalid = ypb_amo_valid;
      assign ypb_amo_rsp_o.rid = '0;
      assign ypb_amo_rsp_o.err = '0;
      assign ypb_amo_rsp_o.rdata = amo_is_word ? {{32{amo_resp_word[31]}}, amo_resp_word}
                                                        : hpdcache_rsp_i.rdata[0];
      assign ypb_amo_rsp_o.vgnt = '0;

      //  }}}

      always_ff @(posedge clk_i or negedge rst_ni) begin : amo_pending_ff
        if (!rst_ni) begin
          amo_pending_q <= 1'b0;
        end else begin
          //  Set when a new atomic request is accepted, held until its response.
          amo_pending_q <=
              (~amo_pending_q &  ypb_amo_req_i.preq & hpdcache_req_ready_i) |
              ( amo_pending_q & ~ypb_amo_valid);
        end
      end

      //  Assertions
      //  {{{
      //    pragma translate_off
      forward_one_request_assert :
      assert property (@(posedge clk_i) disable iff (rst_ni !== 1'b1) ($onehot0(
          {forward_store, forward_amo, forward_flush}
      )))
      else $error("Only one request shall be forwarded");
      //    pragma translate_on
      //  }}}
    end
    //  }}}
  endgenerate
  //  }}}

  assign hpdcache_req_o = hpdcache_req;
  //  }}}
endmodule
