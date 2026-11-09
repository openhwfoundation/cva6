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
// Date: February, 2023
// Description: CVA6 cache subsystem integrating standard CVA6's
//              instruction cache and the Core-V High-Performance L1
//              data cache (CV-HPDcache).

`include "axi_types.svh"


module cva6_hpdcache_subsystem
//  Parameters
//  {{{
#(
    parameter config_pkg::cva6_cfg_t CVA6Cfg = config_pkg::cva6_cfg_empty,
    parameter type ypb_fetch_req_t = logic,
    parameter type ypb_fetch_rsp_t = logic,
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

    parameter int NrHwPrefetchers = 4,

    parameter type noc_req_t  = logic,
    parameter type noc_resp_t = logic
)
//  }}}

//  Ports
//  {{{
(

    // Subsystem Clock - SUBSYSTEM
    input logic clk_i,
    // Asynchronous reset active low - SUBSYSTEM
    input logic rst_ni,

    //  AXI port to upstream memory/peripherals
    //  {{{
    // noc request, can be AXI or OpenPiton - SUBSYSTEM
    output noc_req_t  noc_req_o,
    // noc response, can be AXI or OpenPiton - SUBSYSTEM
    input  noc_resp_t noc_resp_i,
    //  }}}

    //  I$
    //  {{{
    // Instruction cache enable - CSR_REGFILE
    input logic icache_enable_i,
    // Flush the instruction cache - CONTROLLER
    input logic icache_flush_i,
    // instruction cache miss - PERF_COUNTERS
    output logic icache_miss_o,
    // Fetch Request channel - FRONTEND
    input ypb_fetch_req_t ypb_fetch_req_i,
    // Fetch Response channel - FRONTEND
    output ypb_fetch_rsp_t ypb_fetch_rsp_o,
    //   }}}

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


    // Store cache response - CACHES
    input ypb_store_req_t ypb_store_req_i,
    // Store cache request - CACHES
    output ypb_store_rsp_t ypb_store_rsp_o,
    // AMO cache request - CACHES
    input ypb_amo_req_t ypb_amo_req_i,
    // AMO cache response - CACHES
    output ypb_amo_rsp_t ypb_amo_rsp_o,
    // Load cache request - CACHES
    input ypb_load_req_t ypb_load_req_i,
    // Load cache response - CACHES
    output ypb_load_rsp_t ypb_load_rsp_o,
    // MMU Ptw cache request - CACHES
    input ypb_mmu_ptw_req_t ypb_mmu_ptw_req_i,
    // MMU Ptw cache response - CACHES
    output ypb_mmu_ptw_rsp_t ypb_mmu_ptw_rsp_o,
    // Zcmt cache response - CACHES
    input ypb_zcmt_req_t ypb_zcmt_req_i,
    // Zcmt cache response - CACHES
    output ypb_zcmt_rsp_t ypb_zcmt_rsp_o,

    // Write buffer status to know if empty - EX_STAGE
    output logic wbuffer_empty_o,
    // Write buffer status to know if not non idempotent - EX_STAGE
    output logic wbuffer_not_ni_o,

    //  Hardware memory prefetcher configuration
    // TO_BE_COMPLETED - TO_BE_COMPLETED
    input  logic [NrHwPrefetchers-1:0]       hwpf_base_set_i,
    // TO_BE_COMPLETED - TO_BE_COMPLETED
    input  logic [NrHwPrefetchers-1:0][63:0] hwpf_base_i,
    // TO_BE_COMPLETED - TO_BE_COMPLETED
    output logic [NrHwPrefetchers-1:0][63:0] hwpf_base_o,
    // TO_BE_COMPLETED - TO_BE_COMPLETED
    input  logic [NrHwPrefetchers-1:0]       hwpf_param_set_i,
    // TO_BE_COMPLETED - TO_BE_COMPLETED
    input  logic [NrHwPrefetchers-1:0][63:0] hwpf_param_i,
    // TO_BE_COMPLETED - TO_BE_COMPLETED
    output logic [NrHwPrefetchers-1:0][63:0] hwpf_param_o,
    // TO_BE_COMPLETED - TO_BE_COMPLETED
    input  logic [NrHwPrefetchers-1:0]       hwpf_throttle_set_i,
    // TO_BE_COMPLETED - TO_BE_COMPLETED
    input  logic [NrHwPrefetchers-1:0][63:0] hwpf_throttle_i,
    // TO_BE_COMPLETED - TO_BE_COMPLETED
    output logic [NrHwPrefetchers-1:0][63:0] hwpf_throttle_o,
    // TO_BE_COMPLETED - TO_BE_COMPLETED
    output logic [               63:0]       hwpf_status_o
    //  }}}
);
  //  }}}

  localparam type axi_ar_chan_t = `AXI_AR_CHAN_T(CVA6Cfg);
  localparam type axi_aw_chan_t = `AXI_AW_CHAN_T(CVA6Cfg);
  localparam type axi_w_chan_t = `AXI_W_CHAN_T(CVA6Cfg);
  localparam type axi_b_chan_t = `AXI_B_CHAN_T(CVA6Cfg);
  localparam type axi_r_chan_t = `AXI_R_CHAN_T(CVA6Cfg);

  function int unsigned __minu(int unsigned x, int unsigned y);
    return x < y ? x : y;
  endfunction

  function int unsigned __maxu(int unsigned x, int unsigned y);
    return y < x ? x : y;
  endfunction

  `include "hpdcache_typedef.svh"

  //  I$ instantiation
  //  {{{
  function automatic hpdcache_pkg::hpdcache_user_cfg_t hpicacheSetConfig();
    hpdcache_pkg::hpdcache_user_cfg_t userCfg = '0;
    userCfg.nRequesters = 1;
    userCfg.paWidth = CVA6Cfg.PLEN;
    userCfg.wordWidth = 32;
    userCfg.sets = 2 ** (CVA6Cfg.ICACHE_INDEX_WIDTH - $clog2(CVA6Cfg.ICACHE_LINE_WIDTH / 8));
    userCfg.ways = CVA6Cfg.ICACHE_SET_ASSOC;
    userCfg.clWords = CVA6Cfg.ICACHE_LINE_WIDTH / userCfg.wordWidth;
    userCfg.reqWords = CVA6Cfg.FETCH_WIDTH / userCfg.wordWidth;
    userCfg.reqTransIdWidth = 1;
    userCfg.reqSrcIdWidth = 1;
    userCfg.victimSel = hpdcache_pkg::HPDCACHE_VICTIM_RANDOM;
    userCfg.dataWaysPerRamWord = __minu(CVA6Cfg.ICACHE_SET_ASSOC, 128 / userCfg.wordWidth);
    userCfg.dataSetsPerRam = userCfg.sets;
    userCfg.accessWords = __maxu(CVA6Cfg.AxiDataWidth / userCfg.wordWidth, userCfg.reqWords);
    userCfg.mshrSets = 1;
    userCfg.mshrWays = 1;
    userCfg.mshrWaysPerRamWord = userCfg.mshrWays;
    userCfg.mshrSetsPerRam = userCfg.mshrSets;
    userCfg.mshrRamByteEnable = 1'b0;
    userCfg.mshrUseRegbank = 1'b1;
    userCfg.refillCoreRspFeedthrough = 1'b1;
    userCfg.refillFifoDepth = 2 * (userCfg.clWords / userCfg.accessWords);
    userCfg.wbufDirEntries = 0;
    userCfg.wbufDataEntries = 0;
    userCfg.wbufWords = 0;
    userCfg.wbufTimecntWidth = 3;
    userCfg.rtabEntries = 1;
    userCfg.flushEntries = 0;
    userCfg.flushFifoDepth = 0;
    userCfg.memAddrWidth = CVA6Cfg.AxiAddrWidth;
    userCfg.memIdWidth = CVA6Cfg.AxiIdWidth - 1;
    userCfg.memDataWidth = CVA6Cfg.AxiDataWidth;
    userCfg.wtEn = 1'b0;
    userCfg.wbEn = 1'b0;
    userCfg.lowLatency = 1'b1;
    return userCfg;
  endfunction

  localparam hpdcache_pkg::hpdcache_user_cfg_t HPIcacheUserCfg = hpicacheSetConfig();
  localparam hpdcache_pkg::hpdcache_cfg_t HPIcacheCfg = hpdcache_pkg::hpdcacheBuildConfig(
      HPIcacheUserCfg
  );

  `HPDCACHE_TYPEDEF_MEM_ATTR_T(hpdcache_mem_addr_t, hpdcache_mem_id_t, hpdcache_mem_data_t,
                               hpdcache_mem_be_t, HPIcacheCfg);
  `HPDCACHE_TYPEDEF_MEM_REQ_T(hpdcache_mem_req_t, hpdcache_mem_addr_t, hpdcache_mem_id_t);
  `HPDCACHE_TYPEDEF_MEM_RESP_R_T(hpdcache_mem_resp_r_t, hpdcache_mem_id_t, hpdcache_mem_data_t);
  `HPDCACHE_TYPEDEF_MEM_REQ_W_T(hpdcache_mem_req_w_t, hpdcache_mem_data_t, hpdcache_mem_be_t);
  `HPDCACHE_TYPEDEF_MEM_RESP_W_T(hpdcache_mem_resp_w_t, hpdcache_mem_id_t);

  `HPDCACHE_TYPEDEF_REQ_ATTR_T(hpicache_req_offset_t, hpicache_data_word_t, hpicache_data_be_t,
                               hpicache_req_data_t, hpicache_req_be_t, hpicache_req_sid_t,
                               hpicache_req_tid_t, hpicache_tag_t, HPIcacheCfg);
  `HPDCACHE_TYPEDEF_REQ_T(hpicache_req_t, hpicache_req_offset_t, hpicache_req_data_t,
                          hpicache_req_be_t, hpicache_req_sid_t, hpicache_req_tid_t,
                          hpicache_tag_t);
  `HPDCACHE_TYPEDEF_RSP_T(hpicache_rsp_t, hpicache_req_data_t, hpicache_req_sid_t,
                          hpicache_req_tid_t);

  typedef logic [HPIcacheCfg.u.wbufTimecntWidth-1:0] hpicache_wbuf_timecnt_t;

  logic icache_miss_ready;
  logic icache_miss_valid;
  hpdcache_mem_req_t icache_miss;

  logic icache_miss_resp_ready;
  logic icache_miss_resp_valid;
  hpdcache_mem_resp_r_t icache_miss_resp;

  cva6_hpicache_wrapper #(
      .CVA6Cfg    (CVA6Cfg),
      .HPDcacheCfg(HPIcacheCfg),

      .ypb_fetch_req_t(ypb_fetch_req_t),
      .ypb_fetch_rsp_t(ypb_fetch_rsp_t),

      .hpdcache_mem_addr_t    (hpdcache_mem_addr_t),
      .hpdcache_mem_id_t      (hpdcache_mem_id_t),
      .hpdcache_mem_data_t    (hpdcache_mem_data_t),
      .hpdcache_mem_be_t      (hpdcache_mem_be_t),
      .hpdcache_mem_req_t     (hpdcache_mem_req_t),
      .hpdcache_mem_req_w_t   (hpdcache_mem_req_w_t),
      .hpdcache_mem_resp_r_t  (hpdcache_mem_resp_r_t),
      .hpdcache_mem_resp_w_t  (hpdcache_mem_resp_w_t),
      .hpdcache_req_offset_t  (hpicache_req_offset_t),
      .hpdcache_data_word_t   (hpicache_data_word_t),
      .hpdcache_req_data_t    (hpicache_req_data_t),
      .hpdcache_req_be_t      (hpicache_req_be_t),
      .hpdcache_req_sid_t     (hpicache_req_sid_t),
      .hpdcache_req_tid_t     (hpicache_req_tid_t),
      .hpdcache_tag_t         (hpicache_tag_t),
      .hpdcache_req_t         (hpicache_req_t),
      .hpdcache_rsp_t         (hpicache_rsp_t),
      .hpdcache_wbuf_timecnt_t(hpicache_wbuf_timecnt_t),
      .hpdcache_data_be_t     (hpicache_data_be_t)
  ) i_icache (
      .clk_i (clk_i),
      .rst_ni(rst_ni),

      .icache_enable_i   (icache_enable_i),
      .icache_flush_i    (icache_flush_i),
      .icache_flush_ack_o(  /*empty*/),
      .icache_miss_o     (icache_miss_o),

      .ypb_fetch_req_i(ypb_fetch_req_i),
      .ypb_fetch_rsp_o(ypb_fetch_rsp_o),

      .icache_mem_req_read_ready_i(icache_miss_ready),
      .icache_mem_req_read_valid_o(icache_miss_valid),
      .icache_mem_req_read_o      (icache_miss),

      .icache_mem_resp_read_ready_o(icache_miss_resp_ready),
      .icache_mem_resp_read_valid_i(icache_miss_resp_valid),
      .icache_mem_resp_read_i      (icache_miss_resp)
  );
  //  }}}

  //  D$ instantiation
  //  {{{
  //    0: Page-Table Walk (PTW)
  //    1: Load unit
  //    2: Accelerator load
  //    3: Store/AMO
  //    .
  //    .
  //    .
  //    NumPorts: Hardware Memory Prefetcher (hwpf)
  localparam int HPDCACHE_NREQUESTERS = 3 + (CVA6Cfg.MmuPresent ? 1 : 0) + (CVA6Cfg.RVZCMT ? 1 : 0);
  localparam int NUM_SNOOP_PORTS = 2;

  localparam int MMU_PTW_INDEX = 0;
  localparam int ZCMT_INDEX = (CVA6Cfg.MmuPresent ? 1 : 0);
  localparam int LOAD_INDEX = (CVA6Cfg.RVZCMT ? ZCMT_INDEX + 1 : ZCMT_INDEX);
  localparam int STORE_AMO_INDEX = LOAD_INDEX + 1;
  localparam int HWPF_INDEX = STORE_AMO_INDEX + 1;

  function automatic hpdcache_pkg::hpdcache_user_cfg_t hpdcacheSetConfig();
    hpdcache_pkg::hpdcache_user_cfg_t userCfg = '0;
    userCfg.nRequesters = HPDCACHE_NREQUESTERS;
    userCfg.paWidth = CVA6Cfg.PLEN;
    userCfg.wordWidth = CVA6Cfg.XLEN;
    userCfg.sets = CVA6Cfg.DCACHE_NUM_WORDS;
    userCfg.ways = CVA6Cfg.DCACHE_SET_ASSOC;
    userCfg.clWords = CVA6Cfg.DCACHE_LINE_WIDTH / userCfg.wordWidth;
    userCfg.reqWords = 1;
    userCfg.reqTransIdWidth = CVA6Cfg.DcacheIdWidth;
    userCfg.reqSrcIdWidth = 3;  // Up to 8 requesters
    userCfg.victimSel = hpdcache_pkg::HPDCACHE_VICTIM_RANDOM;
    userCfg.dataWaysPerRamWord = __minu(CVA6Cfg.DCACHE_SET_ASSOC, 128 / CVA6Cfg.XLEN);
    userCfg.dataSetsPerRam = CVA6Cfg.DCACHE_NUM_WORDS;
    userCfg.accessWords = __maxu(CVA6Cfg.AxiDataWidth / userCfg.wordWidth, userCfg.reqWords);
    userCfg.mshrSets = CVA6Cfg.NrLoadBufEntries < 16 ? 1 : CVA6Cfg.NrLoadBufEntries / 2;
    userCfg.mshrWays = CVA6Cfg.NrLoadBufEntries < 16 ? CVA6Cfg.NrLoadBufEntries : 2;
    userCfg.mshrWaysPerRamWord = CVA6Cfg.NrLoadBufEntries < 16 ? CVA6Cfg.NrLoadBufEntries : 2;
    userCfg.mshrSetsPerRam = CVA6Cfg.NrLoadBufEntries < 16 ? 1 : CVA6Cfg.NrLoadBufEntries / 2;
    userCfg.mshrRamByteEnable = 1'b1;
    userCfg.mshrUseRegbank = (CVA6Cfg.NrLoadBufEntries < 16);
    userCfg.cbufEntries = CVA6Cfg.WtDcacheWbufDepth;
    userCfg.refillCoreRspFeedthrough = 1'b1;
    //  Deep enough to hold a whole cache line in flight: two beats per NoC
    //  transfer, and a line takes DCACHE_LINE_WIDTH / AxiDataWidth of them.
    userCfg.refillFifoDepth = 2 * (CVA6Cfg.DCACHE_LINE_WIDTH / CVA6Cfg.AxiDataWidth);
    userCfg.wbufDirEntries = CVA6Cfg.WtDcacheWbufDepth;
    userCfg.wbufDataEntries = CVA6Cfg.WtDcacheWbufDepth;
    userCfg.wbufWords = 1;
    userCfg.wbufTimecntWidth = 3;
    userCfg.rtabEntries = 4;
    userCfg.flushEntries = CVA6Cfg.WtDcacheWbufDepth;  /*FIXME add additional CVA6 parameter*/
    userCfg.flushFifoDepth = CVA6Cfg.WtDcacheWbufDepth;  /*FIXME add additional CVA6 parameter*/
    userCfg.memAddrWidth = CVA6Cfg.AxiAddrWidth;
    userCfg.memIdWidth = CVA6Cfg.AxiIdWidth - 1;
    userCfg.memDataWidth = CVA6Cfg.AxiDataWidth;
    userCfg.wtEn =
        (CVA6Cfg.CacheWritePolicy == config_pkg::CACHE_WT) ||
        (CVA6Cfg.CacheWritePolicy == config_pkg::CACHE_WT_WB);
    userCfg.wbEn =
        (CVA6Cfg.CacheWritePolicy == config_pkg::CACHE_WB) ||
        (CVA6Cfg.CacheWritePolicy == config_pkg::CACHE_WT_WB);
    userCfg.lowLatency = 1'b1;
    userCfg.eccEn = CVA6Cfg.DcacheEccEnable;
    userCfg.eccScrubberEn = CVA6Cfg.DcacheEccScrubberEnable;
    return userCfg;
  endfunction

  localparam hpdcache_pkg::hpdcache_user_cfg_t HPDcacheUserCfg = hpdcacheSetConfig();
  localparam hpdcache_pkg::hpdcache_cfg_t HPDcacheCfg = hpdcache_pkg::hpdcacheBuildConfig(
      HPDcacheUserCfg
  );

  `HPDCACHE_TYPEDEF_REQ_ATTR_T(hpdcache_req_offset_t, hpdcache_data_word_t, hpdcache_data_be_t,
                               hpdcache_req_data_t, hpdcache_req_be_t, hpdcache_req_sid_t,
                               hpdcache_req_tid_t, hpdcache_tag_t, HPDcacheCfg);
  `HPDCACHE_TYPEDEF_REQ_T(hpdcache_req_t, hpdcache_req_offset_t, hpdcache_req_data_t,
                          hpdcache_req_be_t, hpdcache_req_sid_t, hpdcache_req_tid_t,
                          hpdcache_tag_t);
  `HPDCACHE_TYPEDEF_RSP_T(hpdcache_rsp_t, hpdcache_req_data_t, hpdcache_req_sid_t,
                          hpdcache_req_tid_t);

  typedef logic [HPDcacheCfg.u.wbufTimecntWidth-1:0] hpdcache_wbuf_timecnt_t;

  logic                 dcache_read_ready;
  logic                 dcache_read_valid;
  hpdcache_mem_req_t    dcache_read;

  logic                 dcache_read_resp_ready;
  logic                 dcache_read_resp_valid;
  hpdcache_mem_resp_r_t dcache_read_resp;

  logic                 dcache_write_ready;
  logic                 dcache_write_valid;
  hpdcache_mem_req_t    dcache_write;

  logic                 dcache_write_data_ready;
  logic                 dcache_write_data_valid;
  hpdcache_mem_req_w_t  dcache_write_data;

  logic                 dcache_write_resp_ready;
  logic                 dcache_write_resp_valid;
  hpdcache_mem_resp_w_t dcache_write_resp;

  cva6_hpdcache_wrapper #(
      .CVA6Cfg          (CVA6Cfg),
      .HPDcacheCfg      (HPDcacheCfg),
      .ypb_store_req_t  (ypb_store_req_t),
      .ypb_store_rsp_t  (ypb_store_rsp_t),
      .ypb_amo_req_t    (ypb_amo_req_t),
      .ypb_amo_rsp_t    (ypb_amo_rsp_t),
      .ypb_load_req_t   (ypb_load_req_t),
      .ypb_load_rsp_t   (ypb_load_rsp_t),
      .ypb_mmu_ptw_req_t(ypb_mmu_ptw_req_t),
      .ypb_mmu_ptw_rsp_t(ypb_mmu_ptw_rsp_t),
      .ypb_zcmt_req_t   (ypb_zcmt_req_t),
      .ypb_zcmt_rsp_t   (ypb_zcmt_rsp_t),

      .HPDCACHE_NREQUESTERS(HPDCACHE_NREQUESTERS),
      .NUM_SNOOP_PORTS     (NUM_SNOOP_PORTS),
      .MMU_PTW_INDEX       (MMU_PTW_INDEX),
      .ZCMT_INDEX          (ZCMT_INDEX),
      .LOAD_INDEX          (LOAD_INDEX),
      .STORE_AMO_INDEX     (STORE_AMO_INDEX),
      .HWPF_INDEX          (HWPF_INDEX),

      .NrHwPrefetchers        (NrHwPrefetchers),
      .hpdcache_mem_addr_t    (hpdcache_mem_addr_t),
      .hpdcache_mem_id_t      (hpdcache_mem_id_t),
      .hpdcache_mem_data_t    (hpdcache_mem_data_t),
      .hpdcache_mem_be_t      (hpdcache_mem_be_t),
      .hpdcache_mem_req_t     (hpdcache_mem_req_t),
      .hpdcache_mem_req_w_t   (hpdcache_mem_req_w_t),
      .hpdcache_mem_resp_r_t  (hpdcache_mem_resp_r_t),
      .hpdcache_mem_resp_w_t  (hpdcache_mem_resp_w_t),
      .hpdcache_req_offset_t  (hpdcache_req_offset_t),
      .hpdcache_data_word_t   (hpdcache_data_word_t),
      .hpdcache_req_data_t    (hpdcache_req_data_t),
      .hpdcache_req_be_t      (hpdcache_req_be_t),
      .hpdcache_req_sid_t     (hpdcache_req_sid_t),
      .hpdcache_req_tid_t     (hpdcache_req_tid_t),
      .hpdcache_tag_t         (hpdcache_tag_t),
      .hpdcache_req_t         (hpdcache_req_t),
      .hpdcache_rsp_t         (hpdcache_rsp_t),
      .hpdcache_wbuf_timecnt_t(hpdcache_wbuf_timecnt_t),
      .hpdcache_data_be_t     (hpdcache_data_be_t)
  ) i_dcache (
      .clk_i(clk_i),
      .rst_ni(rst_ni),
      .dcache_enable_i(dcache_enable_i),
      .dcache_scrub_enable_i(dcache_scrub_enable_i),
      .dcache_scrub_period_i(dcache_scrub_period_i),
      .dcache_scrub_cycle_o(dcache_scrub_cycle_o),
      .dcache_dat_cor_err_o(dcache_dat_cor_err_o),
      .dcache_dat_unc_err_o(dcache_dat_unc_err_o),
      .dcache_dir_cor_err_o(dcache_dir_cor_err_o),
      .dcache_dir_unc_err_o(dcache_dir_unc_err_o),
      .dcache_flush_i(dcache_flush_i),
      .dcache_flush_ack_o(dcache_flush_ack_o),
      .dcache_miss_o(dcache_miss_o),
      .ypb_store_req_i(ypb_store_req_i),
      .ypb_store_rsp_o(ypb_store_rsp_o),
      .ypb_amo_req_i(ypb_amo_req_i),
      .ypb_amo_rsp_o(ypb_amo_rsp_o),
      .ypb_load_req_i(ypb_load_req_i),
      .ypb_load_rsp_o(ypb_load_rsp_o),
      .ypb_mmu_ptw_req_i(ypb_mmu_ptw_req_i),
      .ypb_mmu_ptw_rsp_o(ypb_mmu_ptw_rsp_o),
      .ypb_zcmt_req_i(ypb_zcmt_req_i),
      .ypb_zcmt_rsp_o(ypb_zcmt_rsp_o),
      .wbuffer_empty_o(wbuffer_empty_o),
      .wbuffer_not_ni_o(wbuffer_not_ni_o),
      .hwpf_base_set_i(hwpf_base_set_i),
      .hwpf_base_i(hwpf_base_i),
      .hwpf_base_o(hwpf_base_o),
      .hwpf_param_set_i(hwpf_param_set_i),
      .hwpf_param_i(hwpf_param_i),
      .hwpf_param_o(hwpf_param_o),
      .hwpf_throttle_set_i(hwpf_throttle_set_i),
      .hwpf_throttle_i(hwpf_throttle_i),
      .hwpf_throttle_o(hwpf_throttle_o),
      .hwpf_status_o(hwpf_status_o),

      .dcache_mem_req_read_ready_i(dcache_read_ready),
      .dcache_mem_req_read_valid_o(dcache_read_valid),
      .dcache_mem_req_read_o(dcache_read),

      .dcache_mem_resp_read_ready_o(dcache_read_resp_ready),
      .dcache_mem_resp_read_valid_i(dcache_read_resp_valid),
      .dcache_mem_resp_read_i(dcache_read_resp),

      .dcache_mem_resp_read_inval_i(1'b0),
      .dcache_mem_resp_read_inval_nline_i('0),

      .dcache_mem_req_write_ready_i(dcache_write_ready),
      .dcache_mem_req_write_valid_o(dcache_write_valid),
      .dcache_mem_req_write_o(dcache_write),

      .dcache_mem_req_write_data_ready_i(dcache_write_data_ready),
      .dcache_mem_req_write_data_valid_o(dcache_write_data_valid),
      .dcache_mem_req_write_data_o(dcache_write_data),

      .dcache_mem_resp_write_ready_o(dcache_write_resp_ready),
      .dcache_mem_resp_write_valid_i(dcache_write_resp_valid),
      .dcache_mem_resp_write_i(dcache_write_resp)
  );
  //  }}}

  //  AXI arbiter instantiation
  //  {{{
  cva6_hpdcache_subsystem_axi_arbiter #(
      .CVA6Cfg              (CVA6Cfg),
      .hpdcache_mem_addr_t  (hpdcache_mem_addr_t),
      .hpdcache_mem_id_t    (hpdcache_mem_id_t),
      .hpdcache_mem_data_t  (hpdcache_mem_data_t),
      .hpdcache_mem_req_t   (hpdcache_mem_req_t),
      .hpdcache_mem_req_w_t (hpdcache_mem_req_w_t),
      .hpdcache_mem_resp_r_t(hpdcache_mem_resp_r_t),
      .hpdcache_mem_resp_w_t(hpdcache_mem_resp_w_t),
      .hpdcache_mem_be_t    (hpdcache_mem_be_t),

      .AxiAddrWidth (CVA6Cfg.AxiAddrWidth),
      .AxiDataWidth (CVA6Cfg.AxiDataWidth),
      .AxiIdWidth   (CVA6Cfg.AxiIdWidth),
      .AxiUserWidth (CVA6Cfg.AxiUserWidth),
      .axi_ar_chan_t(axi_ar_chan_t),
      .axi_aw_chan_t(axi_aw_chan_t),
      .axi_w_chan_t (axi_w_chan_t),
      .axi_b_chan_t (axi_b_chan_t),
      .axi_r_chan_t (axi_r_chan_t),
      .axi_req_t    (noc_req_t),
      .axi_rsp_t    (noc_resp_t)
  ) i_axi_arbiter (
      .clk_i,
      .rst_ni,

      .icache_miss_ready_o(icache_miss_ready),
      .icache_miss_valid_i(icache_miss_valid),
      .icache_miss_i      (icache_miss),

      .icache_miss_resp_ready_i(icache_miss_resp_ready),
      .icache_miss_resp_valid_o(icache_miss_resp_valid),
      .icache_miss_resp_o      (icache_miss_resp),

      .dcache_read_ready_o(dcache_read_ready),
      .dcache_read_valid_i(dcache_read_valid),
      .dcache_read_i      (dcache_read),

      .dcache_read_resp_ready_i(dcache_read_resp_ready),
      .dcache_read_resp_valid_o(dcache_read_resp_valid),
      .dcache_read_resp_o      (dcache_read_resp),

      .dcache_write_ready_o(dcache_write_ready),
      .dcache_write_valid_i(dcache_write_valid),
      .dcache_write_i      (dcache_write),

      .dcache_write_data_ready_o(dcache_write_data_ready),
      .dcache_write_data_valid_i(dcache_write_data_valid),
      .dcache_write_data_i      (dcache_write_data),

      .dcache_write_resp_ready_i(dcache_write_resp_ready),
      .dcache_write_resp_valid_o(dcache_write_resp_valid),
      .dcache_write_resp_o      (dcache_write_resp),

      .axi_req_o (noc_req_o),
      .axi_resp_i(noc_resp_i)
  );
  //  }}}

  //  Assertions
  //  {{{
`ifndef HPDCACHE_ASSERT_OFF
  if (HPDcacheCfg.u.reqSrcIdWidth < $clog2(
          HPDcacheCfg.u.nRequesters
      )) begin : hpdcache_srcid_width_assert
    $fatal(1, "HPDcacheCfg.u.reqSrcIdWidth is not wide enough");
  end

  if ((CVA6Cfg.AxiIdWidth - 1) < ($clog2(
          HPDcacheCfg.u.mshrSets * HPDcacheCfg.u.mshrWays
      ) + 1)) begin : axi_id_width_dcache_mshr_assert
    $fatal(1, "CVA6Cfg.AxiIdWidth shall allow to uniquely identify all D$ miss requests");
  end

  if ((CVA6Cfg.AxiIdWidth - 1) < ($clog2(
          HPDcacheCfg.u.wbufDirEntries
      ) + 1)) begin : axi_id_width_dcache_wbuf_assert
    $fatal(1, "CVA6Cfg.AxiIdWidth shall allow to uniquely identify all D$ write requests");
  end

  if ((CVA6Cfg.AxiIdWidth - 1) < ($clog2(
          HPIcacheCfg.u.mshrSets * HPIcacheCfg.u.mshrWays
      ) + 1)) begin : axi_id_width_icache_mshr_assert
    $fatal(1, "CVA6Cfg.AxiIdWidth shall allow to uniquely identify all I$ miss requests");
  end

  a_invalid_instruction_fetch :
  assert property (
    @(posedge clk_i) disable iff (~rst_ni) (ypb_fetch_rsp_o.rvalid && ypb_fetch_req_i.rready) |-> (|ypb_fetch_rsp_o.rdata) !== 1'hX)
  else
    $warning(1, "[l1 icache] FETCH reading invalid instructions: data=%08X", ypb_fetch_rsp_o.rdata);

  a_invalid_read_amo :
  assert property (
    @(posedge clk_i) disable iff (~rst_ni) (ypb_amo_rsp_o.rvalid && ypb_amo_req_i.rready) |-> (|ypb_amo_rsp_o.rdata) !== 1'hX)
  else $warning(1, "[l1 dcache] AMO reading invalid data: data=%08X", ypb_amo_rsp_o.rdata);

  a_invalid_read_load :
  assert property (
    @(posedge clk_i) disable iff (~rst_ni) (ypb_load_rsp_o.rvalid && ypb_load_req_i.rready) |-> (|ypb_load_rsp_o.rdata) !== 1'hX)
  else $warning(1, "[l1 dcache] LOAD reading invalid data: data=%08X", ypb_amo_rsp_o.rdata);

  //  a_invalid_read_mmu_ptw :
  //  assert property (
  //    @(posedge clk_i) disable iff (~rst_ni) (ypb_mmu_ptw_rsp_o.rvalid && !ypb_mmu_ptw_rsp_o.invalid_data) |-> (|ypb_mmu_ptw_rsp_o.rdata) !== 1'hX)
  //  else
  //    $warning(
  //        1,
  //        "[l1 dcache] MMU PTW reading invalid data: data=%08X",
  //        ypb_mmu_ptw_rsp_o.rdata
  //    );

  //  a_invalid_read_zcmt :
  //  assert property (
  //    @(posedge clk_i) disable iff (~rst_ni) (ypb_zcmt_rsp_o.rvalid && !ypb_zcmt_rsp_o.invalid_data) |-> (|ypb_zcmt_rsp_o.rdata) !== 1'hX)
  //  else
  //    $warning(
  //        1,
  //        "[l1 dcache] ZCMT reading invalid data: data=%08X",
  //        ypb_zcmt_rsp_o.rdata
  //    );

  a_invalid_write_store :
  assert property (
    @(posedge clk_i) disable iff (~rst_ni) (ypb_store_req_i.preq && ypb_store_rsp_o.pgnt) |-> (|ypb_store_req_i.wdata) !== 1'hX)
  else
    $warning(
        1,
        "[l1 dcache] STORE writing invalid data: paddr=%016X, be=%02X, data=%016X",
        ypb_store_req_i.paddr,
        ypb_store_req_i.be,
        ypb_store_req_i.wdata
    );

  a_invalid_write_amo :
  assert property (
    @(posedge clk_i) disable iff (~rst_ni) (ypb_amo_req_i.preq && ypb_amo_rsp_o.pgnt) |-> (|ypb_amo_req_i.wdata) !== 1'hX)
  else
    $warning(
        1,
        "[l1 dcache] AMO writing invalid data: paddr=%016X, be=%02X, data=%016X",
        ypb_amo_req_i.paddr,
        ypb_amo_req_i.be,
        ypb_amo_req_i.wdata
    );
`endif
  //  }}}

endmodule : cva6_hpdcache_subsystem
