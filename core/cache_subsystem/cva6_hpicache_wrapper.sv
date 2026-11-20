// Copyright 2023 Commissariat a l'Energie Atomique et aux Energies
//                Alternatives (CEA)
// Copyright 2025 Inria, Universite Grenoble Alpes
//
// Licensed under the Solderpad Hardware License, Version 2.1 (the “License”);
// you may not use this file except in compliance with the License.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
// You may obtain a copy of the License at https://solderpad.org/licenses/
//
// Authors: Cesar Fuguet
// Date: June, 2023
// Description: Wrapper for the Core-V High-Performance L1 data cache (used as
// instruction cache)

`include "hpdcache_typedef.svh"

module cva6_hpicache_wrapper
//  Parameters
//  {{{
#(
    parameter config_pkg::cva6_cfg_t CVA6Cfg = config_pkg::cva6_cfg_empty,
    parameter hpdcache_pkg::hpdcache_cfg_t HPDcacheCfg = '0,
    parameter type ypb_fetch_req_t = logic,
    parameter type ypb_fetch_rsp_t = logic,
    parameter type hpdcache_mem_addr_t = logic,
    parameter type hpdcache_mem_id_t = logic,
    parameter type hpdcache_mem_data_t = logic,
    parameter type hpdcache_mem_be_t = logic,
    parameter type hpdcache_mem_req_t = logic,
    parameter type hpdcache_mem_req_w_t = logic,
    parameter type hpdcache_mem_resp_r_t = logic,
    parameter type hpdcache_mem_resp_w_t = logic,
    parameter type hpdcache_req_offset_t = logic,
    parameter type hpdcache_data_word_t = logic,
    parameter type hpdcache_req_data_t = logic,
    parameter type hpdcache_req_be_t = logic,
    parameter type hpdcache_req_sid_t = logic,
    parameter type hpdcache_req_tid_t = logic,
    parameter type hpdcache_tag_t = logic,
    parameter type hpdcache_req_t = logic,
    parameter type hpdcache_rsp_t = logic,
    parameter type hpdcache_wbuf_timecnt_t = logic,
    parameter type hpdcache_data_be_t = logic,
    localparam type hpdcache_nline_t = logic [HPDcacheCfg.nlineWidth-1:0]
)
//  }}}

//  Ports
//  {{{
(
    // Subsystem Clock - SUBSYSTEM
    input logic clk_i,
    // Asynchronous reset active low - SUBSYSTEM
    input logic rst_ni,

    //  I$
    //  {{{
    //    Cache management
    // Instruction cache enable - CSR_REGFILE
    input  logic icache_enable_i,
    // Instruction cache flush - CONTROLLER
    input  logic icache_flush_i,
    // Instruction Flush acknowledge - CONTROLLER
    output logic icache_flush_ack_o,
    // Fetch miss - PERF_COUNTERS
    output logic icache_miss_o,

    // Fetch request/response - FRONTEND
    input  ypb_fetch_req_t ypb_fetch_req_i,
    output ypb_fetch_rsp_t ypb_fetch_rsp_o,

    input  logic              icache_mem_req_read_ready_i,
    output logic              icache_mem_req_read_valid_o,
    output hpdcache_mem_req_t icache_mem_req_read_o,

    output logic                 icache_mem_resp_read_ready_o,
    input  logic                 icache_mem_resp_read_valid_i,
    input  hpdcache_mem_resp_r_t icache_mem_resp_read_i,

    // Invalidation of a cache line, sent with a read response (OpenPiton L1.5)
    input logic            icache_mem_resp_read_inval_i,
    input hpdcache_nline_t icache_mem_resp_read_inval_nline_i
);

  logic                        icache_req_valid[1];
  logic                        icache_req_ready[1];
  hpdcache_req_t               icache_req      [1];
  logic                        icache_req_abort[1];
  hpdcache_tag_t               icache_req_tag  [1];
  hpdcache_pkg::hpdcache_pma_t icache_req_pma  [1];

  logic                        icache_rsp_valid[1];
  hpdcache_rsp_t               icache_rsp      [1];

  logic icache_read_miss, icache_write_miss;

  cva6_hpicache_if_adapter #(
      .CVA6Cfg              (CVA6Cfg),
      .HPDcacheCfg          (HPDcacheCfg),
      .hpdcache_tag_t       (hpdcache_tag_t),
      .hpdcache_req_offset_t(hpdcache_req_offset_t),
      .hpdcache_req_t       (hpdcache_req_t),
      .hpdcache_rsp_t       (hpdcache_rsp_t),
      .ypb_fetch_req_t      (ypb_fetch_req_t),
      .ypb_fetch_rsp_t      (ypb_fetch_rsp_t)
  ) i_cva6_hpicache_if_adapter (
      .clk_i,
      .rst_ni,

      .ypb_fetch_req_i,
      .ypb_fetch_rsp_o,

      .cva6_icache_flush_i    (icache_flush_i),
      .cva6_icache_flush_ack_o(icache_flush_ack_o),

      .hpicache_req_valid_o(icache_req_valid[0]),
      .hpicache_req_ready_i(icache_req_ready[0]),
      .hpicache_req_o      (icache_req[0]),
      .hpicache_req_abort_o(icache_req_abort[0]),
      .hpicache_req_tag_o  (icache_req_tag[0]),
      .hpicache_req_pma_o  (icache_req_pma[0]),

      .hpicache_rsp_valid_i(icache_rsp_valid[0]),
      .hpicache_rsp_i      (icache_rsp[0])
  );

  hpdcache #(
      .HPDcacheCfg          (HPDcacheCfg),
      .wbuf_timecnt_t       (hpdcache_wbuf_timecnt_t),
      .hpdcache_tag_t       (hpdcache_tag_t),
      .hpdcache_data_word_t (hpdcache_data_word_t),
      .hpdcache_data_be_t   (hpdcache_data_be_t),
      .hpdcache_req_offset_t(hpdcache_req_offset_t),
      .hpdcache_req_data_t  (hpdcache_req_data_t),
      .hpdcache_req_be_t    (hpdcache_req_be_t),
      .hpdcache_req_sid_t   (hpdcache_req_sid_t),
      .hpdcache_req_tid_t   (hpdcache_req_tid_t),
      .hpdcache_req_t       (hpdcache_req_t),
      .hpdcache_rsp_t       (hpdcache_rsp_t),
      .hpdcache_mem_addr_t  (hpdcache_mem_addr_t),
      .hpdcache_mem_id_t    (hpdcache_mem_id_t),
      .hpdcache_mem_data_t  (hpdcache_mem_data_t),
      .hpdcache_mem_be_t    (hpdcache_mem_be_t),
      .hpdcache_mem_req_t   (hpdcache_mem_req_t),
      .hpdcache_mem_req_w_t (hpdcache_mem_req_w_t),
      .hpdcache_mem_resp_r_t(hpdcache_mem_resp_r_t),
      .hpdcache_mem_resp_w_t(hpdcache_mem_resp_w_t)
  ) i_hpicache (
      .clk_i,
      .rst_ni,

      .wbuf_flush_i(1'b0),

      .core_req_valid_i(icache_req_valid),
      .core_req_ready_o(icache_req_ready),
      .core_req_i      (icache_req),
      .core_req_abort_i(icache_req_abort),
      .core_req_tag_i  (icache_req_tag),
      .core_req_pma_i  (icache_req_pma),

      .core_rsp_valid_o(icache_rsp_valid),
      .core_rsp_o      (icache_rsp),

      .mem_req_read_ready_i(icache_mem_req_read_ready_i),
      .mem_req_read_valid_o(icache_mem_req_read_valid_o),
      .mem_req_read_o      (icache_mem_req_read_o),

      .mem_resp_read_ready_o(icache_mem_resp_read_ready_o),
      .mem_resp_read_valid_i(icache_mem_resp_read_valid_i),
      .mem_resp_read_i      (icache_mem_resp_read_i),

      .mem_resp_read_inval_i      (icache_mem_resp_read_inval_i),
      .mem_resp_read_inval_nline_i(icache_mem_resp_read_inval_nline_i),

      .mem_req_write_ready_i(1'b1),
      .mem_req_write_valid_o(),
      .mem_req_write_o      (),

      .mem_req_write_data_ready_i(1'b1),
      .mem_req_write_data_valid_o(),
      .mem_req_write_data_o      (),

      .mem_resp_write_ready_o(),
      .mem_resp_write_valid_i(1'b0),
      .mem_resp_write_i      ('0),

      .evt_cache_write_miss_o (  /* unused */),
      .evt_cache_read_miss_o  (icache_read_miss),
      .evt_cache_dir_unc_err_o(  /* unused */),
      .evt_cache_dir_cor_err_o(  /* unused */),
      .evt_cache_dat_unc_err_o(  /* unused */),
      .evt_cache_dat_cor_err_o(  /* unused */),
      .evt_scrub_complete_o   (  /* unused */),
      .evt_uncached_req_o     (  /* unused */),
      .evt_cmo_req_o          (  /* unused */),
      .evt_write_req_o        (  /* unused */),
      .evt_read_req_o         (  /* unused */),
      .evt_prefetch_req_o     (  /* unused */),
      .evt_req_on_hold_o      (  /* unused */),
      .evt_rtab_rollback_o    (  /* unused */),
      .evt_stall_refill_o     (  /* unused */),
      .evt_stall_o            (  /* unused */),

      .wbuf_empty_o(),

      .cfg_enable_i                       (icache_enable_i),
      .cfg_wbuf_threshold_i               (3'd2),
      .cfg_wbuf_reset_timecnt_on_write_i  (1'b1),
      .cfg_wbuf_sequential_waw_i          (1'b0),
      .cfg_wbuf_inhibit_write_coalescing_i(1'b0),
      .cfg_prefetch_updt_plru_i           (1'b1),
      .cfg_error_on_cacheable_amo_i       (1'b0),
      .cfg_rtab_single_entry_i            (1'b0),
      .cfg_default_wb_i                   (1'b0),
      .cfg_scrub_enable_i                 (1'b0),
      .cfg_scrub_period_i                 ('0),
      .cfg_scrub_restart_i                (1'b0)
  );

  assign icache_miss_o = icache_read_miss;
  //  }}}

endmodule
