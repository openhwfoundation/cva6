// Copyright 2017-2019 ETH Zurich and University of Bologna.
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
// Date: 19.03.2017
// Description: CVA6 Top-level module

`include "rvfi_types.svh"
`include "cvxif_types.svh"
`include "ypb_types.svh"
`include "utils_macros.svh"

module cva6
  import ariane_pkg::*;
#(
    // CVA6 config
    parameter config_pkg::cva6_cfg_t CVA6Cfg = config_pkg::cva6_cfg_empty,

    // RVFI PROBES
    parameter type rvfi_probes_t = logic,

    // NOC Types AXI bus or several OBI bus
    parameter type noc_req_t  = logic,
    parameter type noc_resp_t = logic,

    // DCLS
    parameter type regfile_inputs_t = logic,
    parameter type bht_inputs_t = logic,
    parameter type dcls_common_modules_ctrl_t = logic,
    parameter type dcls_common_modules_data_t = logic,

    // CVXIF Types
    localparam type readregflags_t = `READREGFLAGS_T(CVA6Cfg),
    localparam type writeregflags_t = `WRITEREGFLAGS_T(CVA6Cfg),
    localparam type id_t = `ID_T(CVA6Cfg),
    localparam type hartid_t = `HARTID_T(CVA6Cfg),
    localparam type x_compressed_req_t = `X_COMPRESSED_REQ_T(CVA6Cfg, hartid_t),
    localparam type x_compressed_resp_t = `X_COMPRESSED_RESP_T(CVA6Cfg),
    localparam type x_issue_req_t = `X_ISSUE_REQ_T(CVA6Cfg, hartid_t, id_t),
    localparam type x_issue_resp_t = `X_ISSUE_RESP_T(CVA6Cfg, writeregflags_t, readregflags_t),
    localparam type x_register_t = `X_REGISTER_T(CVA6Cfg, hartid_t, id_t, readregflags_t),
    localparam type x_commit_t = `X_COMMIT_T(CVA6Cfg, hartid_t, id_t),
    localparam type x_result_t = `X_RESULT_T(CVA6Cfg, hartid_t, id_t, writeregflags_t),
    localparam type cvxif_req_t =
    `CVXIF_REQ_T(CVA6Cfg, x_compressed_req_t, x_issue_req_t, x_register_t, x_commit_t),
    localparam type cvxif_resp_t =
    `CVXIF_RESP_T(CVA6Cfg, x_compressed_resp_t, x_issue_resp_t, x_result_t)
) (
    // Subsystem Clock - SUBSYSTEM
    input logic clk_i,
    // Asynchronous reset active low - SUBSYSTEM
    input logic rst_ni,
    // Reset boot address - SUBSYSTEM
    input logic [CVA6Cfg.VLEN-1:0] boot_addr_i,
    // Hard ID reflected as CSR - SUBSYSTEM
    input logic [CVA6Cfg.XLEN-1:0] hart_id_i,
    // Level sensitive (async) interrupts - SUBSYSTEM
    input logic [1:0] irq_i,
    // Inter-processor (async) interrupt - SUBSYSTEM
    input logic ipi_i,
    // Timer (async) interrupt - SUBSYSTEM
    input logic time_irq_i,
    // Debug (async) request - SUBSYSTEM
    input logic debug_req_i,
    // Probes to build RVFI, can be left open when not used - RVFI
    output rvfi_probes_t rvfi_probes_o,
    // CVXIF request - SUBSYSTEM
    output cvxif_req_t cvxif_req_o,
    // CVXIF response - SUBSYSTEM
    input cvxif_resp_t cvxif_resp_i,
    // noc request, can be AXI or OpenPiton - SUBSYSTEM
    output noc_req_t noc_req_o,
    // noc response, can be AXI or OpenPiton - SUBSYSTEM
    input noc_resp_t noc_resp_i,
    // DCLS
    input dcls_common_modules_data_t dcls_from_common_i,
    output dcls_common_modules_ctrl_t dcls_to_common_o
);


  localparam type ypb_fetch_req_t = `YPB_REQ_T(CVA6Cfg, CVA6Cfg.FETCH_WIDTH);
  localparam type ypb_fetch_rsp_t = `YPB_RSP_T(CVA6Cfg, CVA6Cfg.FETCH_WIDTH);
  localparam type ypb_store_req_t = `YPB_REQ_T(CVA6Cfg, CVA6Cfg.XLEN);
  localparam type ypb_store_rsp_t = `YPB_RSP_T(CVA6Cfg, CVA6Cfg.XLEN);
  localparam type ypb_amo_req_t = `YPB_REQ_T(CVA6Cfg, CVA6Cfg.XLEN);
  localparam type ypb_amo_rsp_t = `YPB_RSP_T(CVA6Cfg, CVA6Cfg.XLEN);
  localparam type ypb_load_req_t = `YPB_REQ_T(CVA6Cfg, CVA6Cfg.XLEN);
  localparam type ypb_load_rsp_t = `YPB_RSP_T(CVA6Cfg, CVA6Cfg.XLEN);
  localparam type ypb_mmu_ptw_req_t = `YPB_REQ_T(CVA6Cfg, CVA6Cfg.XLEN);
  localparam type ypb_mmu_ptw_rsp_t = `YPB_RSP_T(CVA6Cfg, CVA6Cfg.XLEN);
  localparam type ypb_zcmt_req_t = `YPB_REQ_T(CVA6Cfg, CVA6Cfg.XLEN);
  localparam type ypb_zcmt_rsp_t = `YPB_RSP_T(CVA6Cfg, CVA6Cfg.XLEN);


  logic icache_enable;
  logic icache_flush;
  logic icache_miss;

  logic dcache_enable;
  logic dcache_scrub_enable;
  logic [5:0] dcache_scrub_period;
  logic dcache_scrub_cycle;
  logic dcache_dat_cor_err, dcache_dat_unc_err;
  logic dcache_dir_cor_err, dcache_dir_unc_err;
  logic dcache_flush;
  logic dcache_flush_ack;
  logic dcache_miss;

  logic wbuffer_empty;
  logic wbuffer_not_ni;


  ypb_fetch_req_t ypb_fetch_req;
  ypb_fetch_rsp_t ypb_fetch_rsp;

  ypb_store_req_t ypb_store_req;
  ypb_store_rsp_t ypb_store_rsp;

  ypb_amo_req_t ypb_amo_req;
  ypb_amo_rsp_t ypb_amo_rsp;

  ypb_load_req_t ypb_load_req;
  ypb_load_rsp_t ypb_load_rsp;

  ypb_mmu_ptw_req_t ypb_mmu_ptw_req;
  ypb_mmu_ptw_rsp_t ypb_mmu_ptw_rsp;

  ypb_zcmt_req_t ypb_zcmt_req;
  ypb_zcmt_rsp_t ypb_zcmt_rsp;

  // -------------------
  // Supported configurations
  // -------------------
  // Checked at elaboration: the units they concern do not build, or compute
  // wrong results, for these configurations.
  `CVA6_CFG_CHECK(ras_depth, CVA6Cfg.RASDepth > 0, "RASDepth must be at least 1")
  `CVA6_CFG_CHECK(btb_entries, (CVA6Cfg.BTBEntries & (CVA6Cfg.BTBEntries - 1)) == 0,
                  "BTBEntries must be 0 or a power of two")
  `CVA6_CFG_CHECK(bht_entries, (CVA6Cfg.BHTEntries & (CVA6Cfg.BHTEntries - 1)) == 0,
                  "BHTEntries must be 0 or a power of two")
  `CVA6_CFG_CHECK(nr_nonidempotent_rules, CVA6Cfg.NrNonIdempotentRules <= config_pkg::NrMaxRules,
                  "NrNonIdempotentRules must be at most NrMaxRules")
  `CVA6_CFG_CHECK(nr_execute_region_rules, CVA6Cfg.NrExecuteRegionRules <= config_pkg::NrMaxRules,
                  "NrExecuteRegionRules must be at most NrMaxRules")
  `CVA6_CFG_CHECK(nr_cached_region_rules, CVA6Cfg.NrCachedRegionRules <= config_pkg::NrMaxRules,
                  "NrCachedRegionRules must be at most NrMaxRules")
  `CVA6_CFG_CHECK(nr_bufferable_region_rules,
                  CVA6Cfg.NrBufferableRegionRules <= config_pkg::NrMaxRules,
                  "NrBufferableRegionRules must be at most NrMaxRules")
  // A data cache that only writes back cannot honour a cacheable region that
  // is not bufferable (write-through).
  for (genvar k = 0; k < CVA6Cfg.NrCachedRegionRules; k++) begin : gen_cached_region
    localparam bit Bufferable = config_pkg::is_region_inside_bufferable_regions(
        CVA6Cfg, CVA6Cfg.CachedRegionAddrBase[k], CVA6Cfg.CachedRegionLength[k]
    );
    `CVA6_CFG_CHECK(write_back_bufferable,
                    CVA6Cfg.MemSubsystem == config_pkg::MEM_OBI ||
                    CVA6Cfg.CacheWritePolicy != config_pkg::CACHE_WB || Bufferable,
                    "A write-back only data cache needs every cacheable region bufferable")
  end
  `CVA6_CFG_CHECK(nr_pmp_entries, CVA6Cfg.NrPMPEntries <= 64, "NrPMPEntries must be at most 64")
  `CVA6_CFG_CHECK(fetch_width, CVA6Cfg.FETCH_WIDTH == 32 || CVA6Cfg.FETCH_WIDTH == 64,
                  "The fetch width must be 32 or 64 bits")
  // Disabling MIP.MSIP and MIE.MSIE is only supported with M-mode alone.
  `CVA6_CFG_CHECK(rvs_software_interrupt, !CVA6Cfg.RVS || CVA6Cfg.SoftwareInterruptEn,
                  "Supervisor mode (RVS) needs SoftwareInterruptEn")
  `CVA6_CFG_CHECK(rvh_software_interrupt, !CVA6Cfg.RVH || CVA6Cfg.SoftwareInterruptEn,
                  "The hypervisor extension (RVH) needs SoftwareInterruptEn")
  `CVA6_CFG_CHECK(zcmt_mmu, !(CVA6Cfg.RVZCMT && CVA6Cfg.MmuPresent),
                  "Zcmt (RVZCMT) is not supported with an MMU")
  // Zcmp reuses the opcodes of Zcd, present whenever C and D are.
  `CVA6_CFG_CHECK(zcmp_zcd, !(CVA6Cfg.RVZCMP && CVA6Cfg.RVC && CVA6Cfg.RVD),
                  "Zcmp (RVZCMP) is not supported with C and D (Zcd)")
  // AMOs are computed in the byte order of the memory subsystem, not mstatus.MBE.
  `CVA6_CFG_CHECK(big_endian_amo, !(CVA6Cfg.BigEndianEn && CVA6Cfg.RVA),
                  "Big endian with atomic memory operations (RVA) is not supported")
  // D and the non-standard XF16, XF16ALT and XF8 formats (smallFloat) extend
  // F: they use its FP register file, FPU and fcsr.
  `CVA6_CFG_CHECK(fp_needs_f,
                  CVA6Cfg.RVF || !(CVA6Cfg.RVD || CVA6Cfg.XF16 || CVA6Cfg.XF16ALT || CVA6Cfg.XF8),
                  "D, XF16, XF16ALT and XF8 need F (RVF)")
  // With FLEN 32 the division and square root unit of fpnew that serves
  // several formats (THMULTI) takes every operand for a NaN.
  `CVA6_CFG_CHECK(smallfloat_rv64,
                  !((CVA6Cfg.XF16 || CVA6Cfg.XF16ALT || CVA6Cfg.XF8) && CVA6Cfg.IS_XLEN32),
                  "XF16, XF16ALT and XF8 are only supported on RV64")
  // The FPU takes its operands from and returns its result on the XLEN-wide
  // execution datapath, and the FP register file is FLEN bits wide: the
  // floating-point extensions are supported when FLEN equals XLEN, F on RV32
  // and F with D on RV64. RV32 with D (FLEN 64) and RV64 with F alone (FLEN 32)
  // are not.
  `CVA6_CFG_CHECK(flen_xlen, !CVA6Cfg.FpPresent || CVA6Cfg.FLen == CVA6Cfg.XLEN,
                  "The floating-point extensions need FLEN == XLEN: F on RV32, F and D on RV64")
  // The hypervisor extension is only implemented on RV64 (Sv39x4).
  `CVA6_CFG_CHECK(rvh_rv64, !(CVA6Cfg.RVH && CVA6Cfg.IS_XLEN32),
                  "The hypervisor extension (RVH) is only supported on RV64")
  // The core does not execute vector instructions: V is provided by a
  // coprocessor on the CV-X-IF.
  `CVA6_CFG_CHECK(rvv_cvxif, !CVA6Cfg.RVV || CVA6Cfg.CvxifEn,
                  "The vector extension (RVV) needs a CV-X-IF coprocessor (CvxifEn)")

  // -------------------
  // Pipeline
  // -------------------

  cva6_pipeline #(
      // CVA6 config
      .CVA6Cfg                   (CVA6Cfg),
      // RVFI PROBES
      .rvfi_probes_t             (rvfi_probes_t),
      // YPB 
      .ypb_fetch_req_t           (ypb_fetch_req_t),
      .ypb_fetch_rsp_t           (ypb_fetch_rsp_t),
      .ypb_store_req_t           (ypb_store_req_t),
      .ypb_store_rsp_t           (ypb_store_rsp_t),
      .ypb_amo_req_t             (ypb_amo_req_t),
      .ypb_amo_rsp_t             (ypb_amo_rsp_t),
      .ypb_load_req_t            (ypb_load_req_t),
      .ypb_load_rsp_t            (ypb_load_rsp_t),
      .ypb_mmu_ptw_req_t         (ypb_mmu_ptw_req_t),
      .ypb_mmu_ptw_rsp_t         (ypb_mmu_ptw_rsp_t),
      .ypb_zcmt_req_t            (ypb_zcmt_req_t),
      .ypb_zcmt_rsp_t            (ypb_zcmt_rsp_t),
      // CVXIF
      .readregflags_t            (readregflags_t),
      .writeregflags_t           (writeregflags_t),
      .id_t                      (id_t),
      .hartid_t                  (hartid_t),
      .x_compressed_req_t        (x_compressed_req_t),
      .x_compressed_resp_t       (x_compressed_resp_t),
      .x_issue_req_t             (x_issue_req_t),
      .x_issue_resp_t            (x_issue_resp_t),
      .x_register_t              (x_register_t),
      .x_commit_t                (x_commit_t),
      .x_result_t                (x_result_t),
      .cvxif_req_t               (cvxif_req_t),
      .cvxif_resp_t              (cvxif_resp_t),
      .regfile_inputs_t          (regfile_inputs_t),
      .bht_inputs_t              (bht_inputs_t),
      .dcls_common_modules_ctrl_t(dcls_common_modules_ctrl_t),
      .dcls_common_modules_data_t(dcls_common_modules_data_t)
      //
  ) i_cva6_pipeline (
      .clk_i(clk_i),
      .rst_ni(rst_ni),
      .boot_addr_i(boot_addr_i),
      .hart_id_i(hart_id_i),
      .irq_i(irq_i),
      .ipi_i(ipi_i),
      .time_irq_i(time_irq_i),
      .debug_req_i(debug_req_i),
      .rvfi_probes_o(rvfi_probes_o),
      .cvxif_req_o(cvxif_req_o),
      .cvxif_resp_i(cvxif_resp_i),

      // FROM/TO ICACHE SUBSYSTEM

      .icache_enable_o(icache_enable),
      .icache_flush_o (icache_flush),
      .icache_miss_i  (icache_miss),

      .ypb_fetch_req_o(ypb_fetch_req),
      .ypb_fetch_rsp_i(ypb_fetch_rsp),

      // FROM/TO DCACHE SUBSYSTEM

      .dcache_enable_o      (dcache_enable),
      .dcache_scrub_enable_o(dcache_scrub_enable),
      .dcache_scrub_period_o(dcache_scrub_period),
      .dcache_scrub_cycle_i (dcache_scrub_cycle),
      .dcache_dat_cor_err_i (dcache_dat_cor_err),
      .dcache_dat_unc_err_i (dcache_dat_unc_err),
      .dcache_dir_cor_err_i (dcache_dir_cor_err),
      .dcache_dir_unc_err_i (dcache_dir_unc_err),
      .dcache_flush_o       (dcache_flush),
      .dcache_flush_ack_i   (dcache_flush_ack),
      .dcache_miss_i        (dcache_miss),

      .ypb_store_req_o  (ypb_store_req),
      .ypb_store_rsp_i  (ypb_store_rsp),
      .ypb_amo_req_o    (ypb_amo_req),
      .ypb_amo_rsp_i    (ypb_amo_rsp),
      .ypb_load_req_o   (ypb_load_req),
      .ypb_load_rsp_i   (ypb_load_rsp),
      .ypb_mmu_ptw_req_o(ypb_mmu_ptw_req),
      .ypb_mmu_ptw_rsp_i(ypb_mmu_ptw_rsp),
      .ypb_zcmt_req_o   (ypb_zcmt_req),
      .ypb_zcmt_rsp_i   (ypb_zcmt_rsp),

      .dcache_wbuffer_empty_i (wbuffer_empty),
      .dcache_wbuffer_not_ni_i(wbuffer_not_ni),
      .dcls_from_common_i,
      .dcls_to_common_o
  );


  if (CVA6Cfg.MemSubsystem == config_pkg::MEM_OBI) begin : gen_obi_adapter

    // -------------------
    // OBI Adapter
    // -------------------

    cva6_obi_adapter_subsystem #(
        .CVA6Cfg          (CVA6Cfg),
        .ypb_fetch_req_t  (ypb_fetch_req_t),
        .ypb_fetch_rsp_t  (ypb_fetch_rsp_t),
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
        .noc_req_t        (noc_req_t),
        .noc_resp_t       (noc_resp_t)

    ) i_cva6_obi_adapter_subsystem (
        .clk_i (clk_i),
        .rst_ni(rst_ni),

        // FROM/TO PIPELINE (YPB)

        .ypb_fetch_req_i  (ypb_fetch_req),
        .ypb_fetch_rsp_o  (ypb_fetch_rsp),
        .ypb_store_req_i  (ypb_store_req),
        .ypb_store_rsp_o  (ypb_store_rsp),
        .ypb_amo_req_i    (ypb_amo_req),
        .ypb_amo_rsp_o    (ypb_amo_rsp),
        .ypb_load_req_i   (ypb_load_req),
        .ypb_load_rsp_o   (ypb_load_rsp),
        .ypb_mmu_ptw_req_i(ypb_mmu_ptw_req),
        .ypb_mmu_ptw_rsp_o(ypb_mmu_ptw_rsp),
        .ypb_zcmt_req_i   (ypb_zcmt_req),
        .ypb_zcmt_rsp_o   (ypb_zcmt_rsp),

        // CACHE CONTROL (NO USED)

        .icache_en_i       (icache_enable),
        .icache_flush_i    (icache_flush),
        .icache_miss_o     (icache_miss),
        .dcache_enable_i   (dcache_enable),
        .dcache_flush_i    (dcache_flush),
        .dcache_flush_ack_o(dcache_flush_ack),
        .dcache_miss_o     (dcache_miss),
        .wbuffer_empty_o   (wbuffer_empty),
        .wbuffer_not_ni_o  (wbuffer_not_ni),

        // FROM/TO NOC (OBI)

        .noc_req_o (noc_req_o),
        .noc_resp_i(noc_resp_i)
    );

    // No data cache, so no ECC to scrub nor to report on
    assign dcache_scrub_cycle = 1'b0;
    assign dcache_dat_cor_err = 1'b0;
    assign dcache_dat_unc_err = 1'b0;
    assign dcache_dir_cor_err = 1'b0;
    assign dcache_dir_unc_err = 1'b0;

  end else begin : gen_cache_subsystem

    // -------------------
    // Cache Subsystem
    // -------------------

    cva6_hpdcache_subsystem #(
        .CVA6Cfg          (CVA6Cfg),
        .ypb_fetch_req_t  (ypb_fetch_req_t),
        .ypb_fetch_rsp_t  (ypb_fetch_rsp_t),
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
        .noc_req_t        (noc_req_t),
        .noc_resp_t       (noc_resp_t)
    ) i_cache_subsystem (
        .clk_i (clk_i),
        .rst_ni(rst_ni),

        // FROM/TO FETCH

        .icache_enable_i(icache_enable),
        .icache_flush_i (icache_flush),
        .icache_miss_o  (icache_miss),

        // FETCH FROM/TO PIPELINE (YPB)

        .ypb_fetch_req_i(ypb_fetch_req),
        .ypb_fetch_rsp_o(ypb_fetch_rsp),

        // FROM/TO LSU

        .dcache_enable_i      (dcache_enable),
        .dcache_scrub_enable_i(dcache_scrub_enable),
        .dcache_scrub_period_i(dcache_scrub_period),
        .dcache_scrub_cycle_o (dcache_scrub_cycle),
        .dcache_dat_cor_err_o (dcache_dat_cor_err),
        .dcache_dat_unc_err_o (dcache_dat_unc_err),
        .dcache_dir_cor_err_o (dcache_dir_cor_err),
        .dcache_dir_unc_err_o (dcache_dir_unc_err),
        .dcache_flush_i       (dcache_flush),
        .dcache_flush_ack_o   (dcache_flush_ack),
        .dcache_miss_o        (dcache_miss),

        // DATA FROM/TO PIPELINE (YPB)

        .ypb_store_req_i  (ypb_store_req),
        .ypb_store_rsp_o  (ypb_store_rsp),
        .ypb_amo_req_i    (ypb_amo_req),
        .ypb_amo_rsp_o    (ypb_amo_rsp),
        .ypb_load_req_i   (ypb_load_req),
        .ypb_load_rsp_o   (ypb_load_rsp),
        .ypb_mmu_ptw_req_i(ypb_mmu_ptw_req),
        .ypb_mmu_ptw_rsp_o(ypb_mmu_ptw_rsp),
        .ypb_zcmt_req_i   (ypb_zcmt_req),
        .ypb_zcmt_rsp_o   (ypb_zcmt_rsp),

        .wbuffer_empty_o (wbuffer_empty),
        .wbuffer_not_ni_o(wbuffer_not_ni),

        // FROM/TO HW PREFETCHER

        .hwpf_base_set_i    ('0  /*FIXME*/),
        .hwpf_base_i        ('0  /*FIXME*/),
        .hwpf_base_o        (  /*FIXME*/),
        .hwpf_param_set_i   ('0  /*FIXME*/),
        .hwpf_param_i       ('0  /*FIXME*/),
        .hwpf_param_o       (  /*FIXME*/),
        .hwpf_throttle_set_i('0  /*FIXME*/),
        .hwpf_throttle_i    ('0  /*FIXME*/),
        .hwpf_throttle_o    (  /*FIXME*/),
        .hwpf_status_o      (  /*FIXME*/),

        // FROM/TO NOC (AXI)

        .noc_req_o (noc_req_o),
        .noc_resp_i(noc_resp_i)
    );

  end

endmodule  // ariane
