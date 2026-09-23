// Copyright 2025 Thales DIS France SAS
//
// Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
// You may obtain a copy of the License at https://solderpad.org/licenses/
//
// Authors: Yannick Casamatta
// Date: June, 2025
// Description: CVA6 in OBI configuration

`include "rvfi_types.svh"
`include "cvxif_types.svh"
`include "obi_types.svh"

module cva6_example_obi
  import ariane_pkg::*;
#(
    // CVA6 config
    parameter config_pkg::cva6_cfg_t CVA6Cfg = build_config_pkg::build_config(
        cva6_config_pkg::cva6_cfg
    ),

    // RVFI PROBES
    localparam type rvfi_probes_instr_t = `RVFI_PROBES_INSTR_T(CVA6Cfg),
    localparam type rvfi_probes_csr_t = `RVFI_PROBES_CSR_T(CVA6Cfg),
    parameter type rvfi_probes_t = struct packed {
`ifdef RVFI_ENABLE  // Allow to perform IP level CVA6 elab without RVFI ports (>1000)
      rvfi_probes_csr_t csr;
      rvfi_probes_instr_t instr;
`else
      logic csr;
      logic instr;
`endif
    },

    // NOC Types AXI bus or several OBI bus

    //OBI Fetch Types
    localparam type obi_fetch_a_optional_t = `OBI_CFG_ALL_A_OPTIONAL_T(CVA6Cfg.ObiFetchbusCfg),
    localparam type obi_fetch_a_chan_t =
    `OBI_CFG_A_CHAN_T(CVA6Cfg.ObiFetchbusCfg, obi_fetch_a_optional_t),
    localparam type obi_fetch_req_t = `OBI_CFG_INTEGRITY_REQ_T(obi_fetch_a_chan_t),
    localparam type obi_fetch_r_optional_t = `OBI_CFG_ALL_R_OPTIONAL_T(CVA6Cfg.ObiFetchbusCfg),
    localparam type obi_fetch_r_chan_t =
    `OBI_CFG_R_CHAN_T(CVA6Cfg.ObiFetchbusCfg, obi_fetch_r_optional_t),
    localparam type obi_fetch_rsp_t = `OBI_CFG_INTEGRITY_RSP_T(obi_fetch_r_chan_t),

    //OBI Store Types
    localparam type obi_store_a_optional_t = `OBI_CFG_ALL_A_OPTIONAL_T(CVA6Cfg.ObiStorebusCfg),
    localparam type obi_store_a_chan_t =
    `OBI_CFG_A_CHAN_T(CVA6Cfg.ObiStorebusCfg, obi_store_a_optional_t),
    localparam type obi_store_req_t = `OBI_CFG_INTEGRITY_REQ_T(obi_store_a_chan_t),
    localparam type obi_store_r_optional_t = `OBI_CFG_ALL_R_OPTIONAL_T(CVA6Cfg.ObiStorebusCfg),
    localparam type obi_store_r_chan_t =
    `OBI_CFG_R_CHAN_T(CVA6Cfg.ObiStorebusCfg, obi_store_r_optional_t),
    localparam type obi_store_rsp_t = `OBI_CFG_INTEGRITY_RSP_T(obi_store_r_chan_t),

    //OBI Amo Types
    localparam type obi_amo_a_optional_t = `OBI_CFG_ALL_A_OPTIONAL_T(CVA6Cfg.ObiAmobusCfg),
    localparam type obi_amo_a_chan_t =
    `OBI_CFG_A_CHAN_T(CVA6Cfg.ObiAmobusCfg, obi_amo_a_optional_t),
    localparam type obi_amo_req_t = `OBI_CFG_INTEGRITY_REQ_T(obi_amo_a_chan_t),
    localparam type obi_amo_r_optional_t = `OBI_CFG_ALL_R_OPTIONAL_T(CVA6Cfg.ObiAmobusCfg),
    localparam type obi_amo_r_chan_t =
    `OBI_CFG_R_CHAN_T(CVA6Cfg.ObiAmobusCfg, obi_amo_r_optional_t),
    localparam type obi_amo_rsp_t = `OBI_CFG_INTEGRITY_RSP_T(obi_amo_r_chan_t),

    //OBI Load Types
    localparam type obi_load_a_optional_t = `OBI_CFG_ALL_A_OPTIONAL_T(CVA6Cfg.ObiLoadbusCfg),
    localparam type obi_load_a_chan_t =
    `OBI_CFG_A_CHAN_T(CVA6Cfg.ObiLoadbusCfg, obi_load_a_optional_t),
    localparam type obi_load_req_t = `OBI_CFG_INTEGRITY_REQ_T(obi_load_a_chan_t),
    localparam type obi_load_r_optional_t = `OBI_CFG_ALL_R_OPTIONAL_T(CVA6Cfg.ObiLoadbusCfg),
    localparam type obi_load_r_chan_t =
    `OBI_CFG_R_CHAN_T(CVA6Cfg.ObiLoadbusCfg, obi_load_r_optional_t),
    localparam type obi_load_rsp_t = `OBI_CFG_INTEGRITY_RSP_T(obi_load_r_chan_t),

    //OBI Mmu Ptw Types
    localparam type obi_mmu_ptw_a_optional_t = `OBI_CFG_ALL_A_OPTIONAL_T(CVA6Cfg.ObiMmuPtwbusCfg),
    localparam type obi_mmu_ptw_a_chan_t =
    `OBI_CFG_A_CHAN_T(CVA6Cfg.ObiMmuPtwbusCfg, obi_mmu_ptw_a_optional_t),
    localparam type obi_mmu_ptw_req_t = `OBI_CFG_INTEGRITY_REQ_T(obi_mmu_ptw_a_chan_t),
    localparam type obi_mmu_ptw_r_optional_t = `OBI_CFG_ALL_R_OPTIONAL_T(CVA6Cfg.ObiMmuPtwbusCfg),
    localparam type obi_mmu_ptw_r_chan_t =
    `OBI_CFG_R_CHAN_T(CVA6Cfg.ObiMmuPtwbusCfg, obi_mmu_ptw_r_optional_t),
    localparam type obi_mmu_ptw_rsp_t = `OBI_CFG_INTEGRITY_RSP_T(obi_mmu_ptw_r_chan_t),

    //OBI Zcmt Types
    localparam type obi_zcmt_a_optional_t = `OBI_CFG_ALL_A_OPTIONAL_T(CVA6Cfg.ObiZcmtbusCfg),
    localparam type obi_zcmt_a_chan_t =
    `OBI_CFG_A_CHAN_T(CVA6Cfg.ObiZcmtbusCfg, obi_zcmt_a_optional_t),
    localparam type obi_zcmt_req_t = `OBI_CFG_INTEGRITY_REQ_T(obi_zcmt_a_chan_t),
    localparam type obi_zcmt_r_optional_t = `OBI_CFG_ALL_R_OPTIONAL_T(CVA6Cfg.ObiZcmtbusCfg),
    localparam type obi_zcmt_r_chan_t =
    `OBI_CFG_R_CHAN_T(CVA6Cfg.ObiZcmtbusCfg, obi_zcmt_r_optional_t),
    localparam type obi_zcmt_rsp_t = `OBI_CFG_INTEGRITY_RSP_T(obi_zcmt_r_chan_t),

    parameter type noc_req_t = struct packed {
      obi_fetch_req_t   obi_fetch_req;
      obi_store_req_t   obi_store_req;
      obi_load_req_t    obi_load_req;
      obi_amo_req_t     obi_amo_req;
      obi_mmu_ptw_req_t obi_mmu_ptw_req;
      obi_zcmt_req_t    obi_zcmt_req;
    },
    parameter type noc_resp_t = struct packed {
      obi_fetch_rsp_t   obi_fetch_rsp;
      obi_store_rsp_t   obi_store_rsp;
      obi_load_rsp_t    obi_load_rsp;
      obi_amo_rsp_t     obi_amo_rsp;
      obi_mmu_ptw_rsp_t obi_mmu_ptw_rsp;
      obi_zcmt_rsp_t    obi_zcmt_rsp;
    },

    // CVXIF Types
    localparam type readregflags_t = `READREGFLAGS_T(CVA6Cfg),
    localparam type writeregflags_t = `WRITEREGFLAGS_T(CVA6Cfg),
    localparam type id_t = `ID_T(CVA6Cfg),
    localparam type hartid_t = `HARTID_T(CVA6Cfg),
    localparam type x_compressed_req_t = `X_COMPRESSED_REQ_T(CVA6Cfg, hartid_t),
    localparam type x_compressed_resp_t = `X_COMPRESSED_RESP_T(CVA6Cfg),
    localparam type x_issue_req_t = `X_ISSUE_REQ_T(CVA6Cfg, hartit_t, id_t),
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
    // DCLS Alarms on core outputs & common modules inputs - DCLS
    output logic [3:0] dcls_alarm_o
);

  cva6_top #(
      .CVA6Cfg      (CVA6Cfg),
      .rvfi_probes_t(rvfi_probes_t),
      .noc_req_t    (noc_req_t),
      .noc_resp_t   (noc_resp_t)
  ) i_cva6_top (
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
      .noc_req_o(noc_req_o),
      .noc_resp_i(noc_resp_i),
      .dcls_alarm_o
  );

endmodule  // ariane
