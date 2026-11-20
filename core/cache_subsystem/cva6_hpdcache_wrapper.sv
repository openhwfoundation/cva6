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
// Description: Wrapper for the Core-V High-Performance L1 data cache (CV-HPDcache)

`include "hpdcache_typedef.svh"

module cva6_hpdcache_wrapper
//  Parameters
//  {{{
#(
    parameter config_pkg::cva6_cfg_t CVA6Cfg = config_pkg::cva6_cfg_empty,
    parameter hpdcache_pkg::hpdcache_cfg_t HPDcacheCfg = '0,
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
    parameter int HPDCACHE_NREQUESTERS,
    parameter int NUM_SNOOP_PORTS,
    parameter int MMU_PTW_INDEX,
    parameter int ZCMT_INDEX,
    parameter int LOAD_INDEX,
    parameter int STORE_AMO_INDEX,
    parameter int HWPF_INDEX,
    parameter int NrHwPrefetchers = 4,

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

    //  D$
    //  {{{
    //    Cache management
    // Data cache enable - CSR_REGFILE
    input logic dcache_enable_i,
    // Data cache scrubber enable - CSR_REGFILE
    input logic dcache_scrub_enable_i,
    // Data cache scrubber period - CSR_REGFILE
    input logic [5:0] dcache_scrub_period_i,
    // Data cache scrubber completed a cycle - CSR_REGFILE
    output logic dcache_scrub_cycle_o,
    // Data cache data error corrected - CSR_REGFILE
    output logic dcache_dat_cor_err_o,
    // Data cache data error detected but not corrected - CSR_REGFILE
    output logic dcache_dat_unc_err_o,
    // Data cache tag error corrected - CSR_REGFILE
    output logic dcache_dir_cor_err_o,
    // Data cache tag error detected but not corrected - CSR_REGFILE
    output logic dcache_dir_unc_err_o,
    // Data cache flush - CONTROLLER
    input logic dcache_flush_i,
    // Flush acknowledge - CONTROLLER
    output logic dcache_flush_ack_o,
    // Load or store miss - PERF_COUNTERS
    output logic dcache_miss_o,

    // Load cache input request/response ports - EX_STAGE
    input  ypb_load_req_t    ypb_load_req_i,
    output ypb_load_rsp_t    ypb_load_rsp_o,
    // AMO request/response - EX_STAGE
    input  ypb_amo_req_t     ypb_amo_req_i,
    output ypb_amo_rsp_t     ypb_amo_rsp_o,
    // Data cache request/response - EX_STAGE
    input  ypb_store_req_t   ypb_store_req_i,
    output ypb_store_rsp_t   ypb_store_rsp_o,
    // MMU PTW cache request/response - EX_STAGE
    input  ypb_mmu_ptw_req_t ypb_mmu_ptw_req_i,
    output ypb_mmu_ptw_rsp_t ypb_mmu_ptw_rsp_o,
    // ZCMT cache request/response - ID_STAGE
    input  ypb_zcmt_req_t    ypb_zcmt_req_i,
    output ypb_zcmt_rsp_t    ypb_zcmt_rsp_o,

    // Write buffer status to know if empty - EX_STAGE
    output logic wbuffer_empty_o,
    output logic wbuffer_not_ni_o,

    //  Hardware memory prefetcher configuration
    input  logic [NrHwPrefetchers-1:0]       hwpf_base_set_i,
    input  logic [NrHwPrefetchers-1:0][63:0] hwpf_base_i,
    output logic [NrHwPrefetchers-1:0][63:0] hwpf_base_o,
    input  logic [NrHwPrefetchers-1:0]       hwpf_param_set_i,
    input  logic [NrHwPrefetchers-1:0][63:0] hwpf_param_i,
    output logic [NrHwPrefetchers-1:0][63:0] hwpf_param_o,
    input  logic [NrHwPrefetchers-1:0]       hwpf_throttle_set_i,
    input  logic [NrHwPrefetchers-1:0][63:0] hwpf_throttle_i,
    output logic [NrHwPrefetchers-1:0][63:0] hwpf_throttle_o,
    output logic [               63:0]       hwpf_status_o,

    input  logic              dcache_mem_req_read_ready_i,
    output logic              dcache_mem_req_read_valid_o,
    output hpdcache_mem_req_t dcache_mem_req_read_o,

    output logic                 dcache_mem_resp_read_ready_o,
    input  logic                 dcache_mem_resp_read_valid_i,
    input  hpdcache_mem_resp_r_t dcache_mem_resp_read_i,

    input logic            dcache_mem_resp_read_inval_i,
    input hpdcache_nline_t dcache_mem_resp_read_inval_nline_i,

    input  logic              dcache_mem_req_write_ready_i,
    output logic              dcache_mem_req_write_valid_o,
    output hpdcache_mem_req_t dcache_mem_req_write_o,

    input  logic                dcache_mem_req_write_data_ready_i,
    output logic                dcache_mem_req_write_data_valid_o,
    output hpdcache_mem_req_w_t dcache_mem_req_write_data_o,

    output logic                 dcache_mem_resp_write_ready_o,
    input  logic                 dcache_mem_resp_write_valid_i,
    input  hpdcache_mem_resp_w_t dcache_mem_resp_write_i
);


  typedef logic [63:0] hwpf_stride_param_t;

  logic                        dcache_req_valid[HPDCACHE_NREQUESTERS];
  logic                        dcache_req_ready[HPDCACHE_NREQUESTERS];
  hpdcache_req_t               dcache_req      [HPDCACHE_NREQUESTERS];
  logic                        dcache_req_abort[HPDCACHE_NREQUESTERS];
  hpdcache_tag_t               dcache_req_tag  [HPDCACHE_NREQUESTERS];
  hpdcache_pkg::hpdcache_pma_t dcache_req_pma  [HPDCACHE_NREQUESTERS];
  logic                        dcache_rsp_valid[HPDCACHE_NREQUESTERS];
  hpdcache_rsp_t               dcache_rsp      [HPDCACHE_NREQUESTERS];
  logic dcache_read_miss, dcache_write_miss;

  logic                                   [NUM_SNOOP_PORTS-1:0] snoop_valid;
  logic                                   [NUM_SNOOP_PORTS-1:0] snoop_abort;
  hpdcache_req_offset_t                   [NUM_SNOOP_PORTS-1:0] snoop_addr_offset;
  hpdcache_tag_t                          [NUM_SNOOP_PORTS-1:0] snoop_addr_tag;
  logic                                   [NUM_SNOOP_PORTS-1:0] snoop_phys_indexed;

  hwpf_stride_pkg::hwpf_stride_throttle_t [NrHwPrefetchers-1:0] hwpf_throttle_in;
  hwpf_stride_pkg::hwpf_stride_throttle_t [NrHwPrefetchers-1:0] hwpf_throttle_out;

  if (CVA6Cfg.MmuPresent) begin : gen_mmu_ptw_if_adapter

    cva6_hpdcache_if_adapter #(
        .CVA6Cfg              (CVA6Cfg),
        .HPDcacheCfg          (HPDcacheCfg),
        .hpdcache_tag_t       (hpdcache_tag_t),
        .hpdcache_req_offset_t(hpdcache_req_offset_t),
        .hpdcache_req_sid_t   (hpdcache_req_sid_t),
        .hpdcache_req_t       (hpdcache_req_t),
        .hpdcache_rsp_t       (hpdcache_rsp_t),
        .ypb_store_req_t      (ypb_store_req_t),
        .ypb_store_rsp_t      (ypb_store_rsp_t),
        .ypb_amo_req_t        (ypb_amo_req_t),
        .ypb_amo_rsp_t        (ypb_amo_rsp_t),
        .ypb_load_req_t       (ypb_load_req_t),
        .ypb_load_rsp_t       (ypb_load_rsp_t),
        .ypb_mmu_ptw_req_t    (ypb_mmu_ptw_req_t),
        .ypb_mmu_ptw_rsp_t    (ypb_mmu_ptw_rsp_t),
        .ypb_zcmt_req_t       (ypb_zcmt_req_t),
        .ypb_zcmt_rsp_t       (ypb_zcmt_rsp_t),
        .InvalidateOnFlush    (CVA6Cfg.DcacheInvalidateOnFlush),
        .IsLoadPort           (1'b0),
        .IsMmuPtwPort         (1'b1),
        .IsZcmtPort           (1'b0)
    ) i_cva6_hpdcache_mmu_ptw_if_adapter (
        .clk_i,
        .rst_ni,

        .hpdcache_req_sid_i(hpdcache_req_sid_t'(MMU_PTW_INDEX)),

        .ypb_store_req_i  ('0),
        .ypb_store_rsp_o  (  /* unused */),
        .ypb_amo_req_i    ('0),
        .ypb_amo_rsp_o    (  /* unused */),
        .ypb_load_req_i   ('0),
        .ypb_load_rsp_o   (  /* unused */),
        .ypb_mmu_ptw_req_i(ypb_mmu_ptw_req_i),
        .ypb_mmu_ptw_rsp_o(ypb_mmu_ptw_rsp_o),
        .ypb_zcmt_req_i   ('0),
        .ypb_zcmt_rsp_o   (  /* unused */),

        .cva6_dcache_flush_i    ('0),
        .cva6_dcache_flush_ack_o(  /* unused */),

        .hpdcache_req_valid_o(dcache_req_valid[MMU_PTW_INDEX]),
        .hpdcache_req_ready_i(dcache_req_ready[MMU_PTW_INDEX]),
        .hpdcache_req_o      (dcache_req[MMU_PTW_INDEX]),
        .hpdcache_req_abort_o(dcache_req_abort[MMU_PTW_INDEX]),
        .hpdcache_req_tag_o  (dcache_req_tag[MMU_PTW_INDEX]),
        .hpdcache_req_pma_o  (dcache_req_pma[MMU_PTW_INDEX]),

        .hpdcache_rsp_valid_i(dcache_rsp_valid[MMU_PTW_INDEX]),
        .hpdcache_rsp_i      (dcache_rsp[MMU_PTW_INDEX])
    );

  end

  if (CVA6Cfg.RVZCMT) begin : gen_zcmt_if_adapter

    cva6_hpdcache_if_adapter #(
        .CVA6Cfg              (CVA6Cfg),
        .HPDcacheCfg          (HPDcacheCfg),
        .hpdcache_tag_t       (hpdcache_tag_t),
        .hpdcache_req_offset_t(hpdcache_req_offset_t),
        .hpdcache_req_sid_t   (hpdcache_req_sid_t),
        .hpdcache_req_t       (hpdcache_req_t),
        .hpdcache_rsp_t       (hpdcache_rsp_t),
        .ypb_store_req_t      (ypb_store_req_t),
        .ypb_store_rsp_t      (ypb_store_rsp_t),
        .ypb_amo_req_t        (ypb_amo_req_t),
        .ypb_amo_rsp_t        (ypb_amo_rsp_t),
        .ypb_load_req_t       (ypb_load_req_t),
        .ypb_load_rsp_t       (ypb_load_rsp_t),
        .ypb_mmu_ptw_req_t    (ypb_mmu_ptw_req_t),
        .ypb_mmu_ptw_rsp_t    (ypb_mmu_ptw_rsp_t),
        .ypb_zcmt_req_t       (ypb_zcmt_req_t),
        .ypb_zcmt_rsp_t       (ypb_zcmt_rsp_t),
        .InvalidateOnFlush    (CVA6Cfg.DcacheInvalidateOnFlush),
        .IsLoadPort           (1'b0),
        .IsMmuPtwPort         (1'b0),
        .IsZcmtPort           (1'b1)
    ) i_cva6_hpdcache_zcmt_if_adapter (
        .clk_i,
        .rst_ni,

        .hpdcache_req_sid_i(hpdcache_req_sid_t'(MMU_PTW_INDEX)),

        .ypb_store_req_i  ('0),
        .ypb_store_rsp_o  (  /* unused */),
        .ypb_amo_req_i    ('0),
        .ypb_amo_rsp_o    (  /* unused */),
        .ypb_load_req_i   ('0),
        .ypb_load_rsp_o   (  /* unused */),
        .ypb_mmu_ptw_req_i('0),
        .ypb_mmu_ptw_rsp_o(  /* unused */),
        .ypb_zcmt_req_i   (ypb_zcmt_req_i),
        .ypb_zcmt_rsp_o   (ypb_zcmt_rsp_o),

        .cva6_dcache_flush_i    ('0),
        .cva6_dcache_flush_ack_o(  /* unused */),

        .hpdcache_req_valid_o(dcache_req_valid[ZCMT_INDEX]),
        .hpdcache_req_ready_i(dcache_req_ready[ZCMT_INDEX]),
        .hpdcache_req_o      (dcache_req[ZCMT_INDEX]),
        .hpdcache_req_abort_o(dcache_req_abort[ZCMT_INDEX]),
        .hpdcache_req_tag_o  (dcache_req_tag[ZCMT_INDEX]),
        .hpdcache_req_pma_o  (dcache_req_pma[ZCMT_INDEX]),

        .hpdcache_rsp_valid_i(dcache_rsp_valid[ZCMT_INDEX]),
        .hpdcache_rsp_i      (dcache_rsp[ZCMT_INDEX])
    );

  end

  cva6_hpdcache_if_adapter #(
      .CVA6Cfg              (CVA6Cfg),
      .HPDcacheCfg          (HPDcacheCfg),
      .hpdcache_tag_t       (hpdcache_tag_t),
      .hpdcache_req_offset_t(hpdcache_req_offset_t),
      .hpdcache_req_sid_t   (hpdcache_req_sid_t),
      .hpdcache_req_t       (hpdcache_req_t),
      .hpdcache_rsp_t       (hpdcache_rsp_t),
      .ypb_store_req_t      (ypb_store_req_t),
      .ypb_store_rsp_t      (ypb_store_rsp_t),
      .ypb_amo_req_t        (ypb_amo_req_t),
      .ypb_amo_rsp_t        (ypb_amo_rsp_t),
      .ypb_load_req_t       (ypb_load_req_t),
      .ypb_load_rsp_t       (ypb_load_rsp_t),
      .ypb_mmu_ptw_req_t    (ypb_mmu_ptw_req_t),
      .ypb_mmu_ptw_rsp_t    (ypb_mmu_ptw_rsp_t),
      .ypb_zcmt_req_t       (ypb_zcmt_req_t),
      .ypb_zcmt_rsp_t       (ypb_zcmt_rsp_t),
      .InvalidateOnFlush    (CVA6Cfg.DcacheInvalidateOnFlush),
      .IsLoadPort           (1'b1),
      .IsMmuPtwPort         (1'b0),
      .IsZcmtPort           (1'b0)
  ) i_cva6_hpdcache_load_if_adapter (
      .clk_i,
      .rst_ni,

      .hpdcache_req_sid_i(hpdcache_req_sid_t'(LOAD_INDEX)),

      .ypb_store_req_i  ('0),
      .ypb_store_rsp_o  (  /* unused */),
      .ypb_amo_req_i    ('0),
      .ypb_amo_rsp_o    (  /* unused */),
      .ypb_load_req_i   (ypb_load_req_i),
      .ypb_load_rsp_o   (ypb_load_rsp_o),
      .ypb_mmu_ptw_req_i('0),
      .ypb_mmu_ptw_rsp_o(  /* unused */),
      .ypb_zcmt_req_i   ('0),
      .ypb_zcmt_rsp_o   (  /* unused */),

      .cva6_dcache_flush_i    ('0),
      .cva6_dcache_flush_ack_o(  /* unused */),

      .hpdcache_req_valid_o(dcache_req_valid[LOAD_INDEX]),
      .hpdcache_req_ready_i(dcache_req_ready[LOAD_INDEX]),
      .hpdcache_req_o      (dcache_req[LOAD_INDEX]),
      .hpdcache_req_abort_o(dcache_req_abort[LOAD_INDEX]),
      .hpdcache_req_tag_o  (dcache_req_tag[LOAD_INDEX]),
      .hpdcache_req_pma_o  (dcache_req_pma[LOAD_INDEX]),

      .hpdcache_rsp_valid_i(dcache_rsp_valid[LOAD_INDEX]),
      .hpdcache_rsp_i      (dcache_rsp[LOAD_INDEX])
  );

  cva6_hpdcache_if_adapter #(
      .CVA6Cfg              (CVA6Cfg),
      .HPDcacheCfg          (HPDcacheCfg),
      .hpdcache_tag_t       (hpdcache_tag_t),
      .hpdcache_req_offset_t(hpdcache_req_offset_t),
      .hpdcache_req_sid_t   (hpdcache_req_sid_t),
      .hpdcache_req_t       (hpdcache_req_t),
      .hpdcache_rsp_t       (hpdcache_rsp_t),
      .ypb_store_req_t      (ypb_store_req_t),
      .ypb_store_rsp_t      (ypb_store_rsp_t),
      .ypb_amo_req_t        (ypb_amo_req_t),
      .ypb_amo_rsp_t        (ypb_amo_rsp_t),
      .ypb_load_req_t       (ypb_load_req_t),
      .ypb_load_rsp_t       (ypb_load_rsp_t),
      .ypb_mmu_ptw_req_t    (ypb_mmu_ptw_req_t),
      .ypb_mmu_ptw_rsp_t    (ypb_mmu_ptw_rsp_t),
      .ypb_zcmt_req_t       (ypb_zcmt_req_t),
      .ypb_zcmt_rsp_t       (ypb_zcmt_rsp_t),
      .InvalidateOnFlush    (CVA6Cfg.DcacheInvalidateOnFlush),
      .IsLoadPort           (1'b0),
      .IsMmuPtwPort         (1'b0),
      .IsZcmtPort           (1'b0)
  ) i_cva6_hpdcache_store_if_adapter (
      .clk_i,
      .rst_ni,

      .hpdcache_req_sid_i(hpdcache_req_sid_t'(STORE_AMO_INDEX)),

      .ypb_store_req_i  (ypb_store_req_i),
      .ypb_store_rsp_o  (ypb_store_rsp_o),
      .ypb_amo_req_i    (ypb_amo_req_i),
      .ypb_amo_rsp_o    (ypb_amo_rsp_o),
      .ypb_load_req_i   ('0),
      .ypb_load_rsp_o   (  /* unused */),
      .ypb_mmu_ptw_req_i('0),
      .ypb_mmu_ptw_rsp_o(  /* unused */),
      .ypb_zcmt_req_i   ('0),
      .ypb_zcmt_rsp_o   (  /* unused */),

      .cva6_dcache_flush_i    (dcache_flush_i),
      .cva6_dcache_flush_ack_o(dcache_flush_ack_o),

      .hpdcache_req_valid_o(dcache_req_valid[STORE_AMO_INDEX]),
      .hpdcache_req_ready_i(dcache_req_ready[STORE_AMO_INDEX]),
      .hpdcache_req_o      (dcache_req[STORE_AMO_INDEX]),
      .hpdcache_req_abort_o(dcache_req_abort[STORE_AMO_INDEX]),
      .hpdcache_req_tag_o  (dcache_req_tag[STORE_AMO_INDEX]),
      .hpdcache_req_pma_o  (dcache_req_pma[STORE_AMO_INDEX]),

      .hpdcache_rsp_valid_i(dcache_rsp_valid[STORE_AMO_INDEX]),
      .hpdcache_rsp_i      (dcache_rsp[STORE_AMO_INDEX])
  );

  //  Snoop load port
  assign snoop_valid[0] = dcache_req_valid[LOAD_INDEX] & dcache_req_ready[LOAD_INDEX],
      snoop_abort[0] = dcache_req_abort[LOAD_INDEX],
      snoop_addr_offset[0] = dcache_req[LOAD_INDEX].addr_offset,
      snoop_addr_tag[0] = dcache_req_tag[LOAD_INDEX],
      snoop_phys_indexed[0] = dcache_req[LOAD_INDEX].phys_indexed;

  //  Snoop Store/AMO port
  assign snoop_valid[1] = dcache_req_valid[STORE_AMO_INDEX] & dcache_req_ready[STORE_AMO_INDEX],
      snoop_abort[1] = dcache_req_abort[STORE_AMO_INDEX],
      snoop_addr_offset[1] = dcache_req[STORE_AMO_INDEX].addr_offset,
      snoop_addr_tag[1] = dcache_req_tag[STORE_AMO_INDEX],
      snoop_phys_indexed[1] = dcache_req[STORE_AMO_INDEX].phys_indexed;

  generate
    for (genvar h = 0; h < NrHwPrefetchers; h++) begin : gen_hwpf_throttle
      assign hwpf_throttle_in[h] = hwpf_stride_pkg::hwpf_stride_throttle_t'(hwpf_throttle_i[h]);
      assign hwpf_throttle_o[h]  = hwpf_stride_pkg::hwpf_stride_param_t'(hwpf_throttle_out[h]);
    end
  endgenerate

  hwpf_stride_wrapper #(
      .HPDcacheCfg          (HPDcacheCfg),
      .NUM_HW_PREFETCH      (NrHwPrefetchers),
      .NUM_SNOOP_PORTS      (NUM_SNOOP_PORTS),
      .hpdcache_tag_t       (hpdcache_tag_t),
      .hpdcache_req_offset_t(hpdcache_req_offset_t),
      .hpdcache_req_data_t  (hpdcache_req_data_t),
      .hpdcache_req_be_t    (hpdcache_req_be_t),
      .hpdcache_req_sid_t   (hpdcache_req_sid_t),
      .hpdcache_req_tid_t   (hpdcache_req_tid_t),
      .hpdcache_req_t       (hpdcache_req_t),
      .hpdcache_rsp_t       (hpdcache_rsp_t)
  ) i_hwpf_stride_wrapper (
      .clk_i,
      .rst_ni,

      .hwpf_stride_base_set_i    (hwpf_base_set_i),
      .hwpf_stride_base_i        (hwpf_base_i),
      .hwpf_stride_base_o        (hwpf_base_o),
      .hwpf_stride_param_set_i   (hwpf_param_set_i),
      .hwpf_stride_param_i       (hwpf_param_i),
      .hwpf_stride_param_o       (hwpf_param_o),
      .hwpf_stride_throttle_set_i(hwpf_throttle_set_i),
      .hwpf_stride_throttle_i    (hwpf_throttle_in),
      .hwpf_stride_throttle_o    (hwpf_throttle_out),
      .hwpf_stride_status_o      (hwpf_status_o),

      .snoop_valid_i       (snoop_valid),
      .snoop_abort_i       (snoop_abort),
      .snoop_addr_offset_i (snoop_addr_offset),
      .snoop_addr_tag_i    (snoop_addr_tag),
      .snoop_phys_indexed_i(snoop_phys_indexed),

      .hpdcache_req_sid_i(hpdcache_req_sid_t'(HWPF_INDEX)),

      .hpdcache_req_valid_o(dcache_req_valid[HWPF_INDEX]),
      .hpdcache_req_ready_i(dcache_req_ready[HWPF_INDEX]),
      .hpdcache_req_o      (dcache_req[HWPF_INDEX]),
      .hpdcache_req_abort_o(dcache_req_abort[HWPF_INDEX]),
      .hpdcache_req_tag_o  (dcache_req_tag[HWPF_INDEX]),
      .hpdcache_req_pma_o  (dcache_req_pma[HWPF_INDEX]),
      .hpdcache_rsp_valid_i(dcache_rsp_valid[HWPF_INDEX]),
      .hpdcache_rsp_i      (dcache_rsp[HWPF_INDEX])
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
  ) i_hpdcache (
      .clk_i,
      .rst_ni,

      .wbuf_flush_i(dcache_flush_i),

      .core_req_valid_i(dcache_req_valid),
      .core_req_ready_o(dcache_req_ready),
      .core_req_i      (dcache_req),
      .core_req_abort_i(dcache_req_abort),
      .core_req_tag_i  (dcache_req_tag),
      .core_req_pma_i  (dcache_req_pma),

      .core_rsp_valid_o(dcache_rsp_valid),
      .core_rsp_o      (dcache_rsp),

      .mem_req_read_ready_i(dcache_mem_req_read_ready_i),
      .mem_req_read_valid_o(dcache_mem_req_read_valid_o),
      .mem_req_read_o      (dcache_mem_req_read_o),

      .mem_resp_read_ready_o(dcache_mem_resp_read_ready_o),
      .mem_resp_read_valid_i(dcache_mem_resp_read_valid_i),
      .mem_resp_read_i      (dcache_mem_resp_read_i),

      .mem_resp_read_inval_i      (dcache_mem_resp_read_inval_i),
      .mem_resp_read_inval_nline_i(dcache_mem_resp_read_inval_nline_i),

      .mem_req_write_ready_i(dcache_mem_req_write_ready_i),
      .mem_req_write_valid_o(dcache_mem_req_write_valid_o),
      .mem_req_write_o      (dcache_mem_req_write_o),

      .mem_req_write_data_ready_i(dcache_mem_req_write_data_ready_i),
      .mem_req_write_data_valid_o(dcache_mem_req_write_data_valid_o),
      .mem_req_write_data_o      (dcache_mem_req_write_data_o),

      .mem_resp_write_ready_o(dcache_mem_resp_write_ready_o),
      .mem_resp_write_valid_i(dcache_mem_resp_write_valid_i),
      .mem_resp_write_i      (dcache_mem_resp_write_i),

      .evt_cache_write_miss_o (dcache_write_miss),
      .evt_cache_read_miss_o  (dcache_read_miss),
      .evt_cache_dir_unc_err_o(dcache_dir_unc_err_o),
      .evt_cache_dir_cor_err_o(dcache_dir_cor_err_o),
      .evt_cache_dat_unc_err_o(dcache_dat_unc_err_o),
      .evt_cache_dat_cor_err_o(dcache_dat_cor_err_o),
      .evt_scrub_complete_o   (dcache_scrub_cycle_o),
      .evt_uncached_req_o     (  /* unused */),
      .evt_cmo_req_o          (  /* unused */),
      .evt_write_req_o        (  /* unused */),
      .evt_read_req_o         (  /* unused */),
      .evt_prefetch_req_o     (  /* unused */),
      .evt_req_on_hold_o      (  /* unused */),
      .evt_rtab_rollback_o    (  /* unused */),
      .evt_stall_refill_o     (  /* unused */),
      .evt_stall_o            (  /* unused */),

      .wbuf_empty_o(wbuffer_empty_o),

      .cfg_enable_i                       (dcache_enable_i),
      .cfg_wbuf_threshold_i               (3'd2),
      .cfg_wbuf_reset_timecnt_on_write_i  (1'b1),
      .cfg_wbuf_sequential_waw_i          (1'b0),
      .cfg_wbuf_inhibit_write_coalescing_i(1'b0),
      .cfg_prefetch_updt_plru_i           (1'b1),
      .cfg_error_on_cacheable_amo_i       (1'b0),
      .cfg_rtab_single_entry_i            (1'b0),
      .cfg_default_wb_i                   (1'b0),
      .cfg_scrub_enable_i                 (dcache_scrub_enable_i),
      .cfg_scrub_period_i                 (dcache_scrub_period_i),
      //  The scrubber stops after one pass unless restart is set: following the
      //  enable keeps it scrubbing the cache every scrub period.
      .cfg_scrub_restart_i                (dcache_scrub_enable_i)
  );

  assign dcache_miss_o = dcache_read_miss, wbuffer_not_ni_o = wbuffer_empty_o;
  //  }}}

endmodule : cva6_hpdcache_wrapper
