// Copyright 2026 Thales France
//
// Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
// You may obtain a copy of the License at https://solderpad.org/licenses/
//
// Original Author: Valentin Thomazic (valentin.thomazic@thalesgroup.com)

`include "rvfi_types.svh"
`include "cvxif_types.svh"
`include "ypb_types.svh"

module cva6_top
  import ariane_pkg::*;
#(
    // CVA6 config
    parameter config_pkg::cva6_cfg_t CVA6Cfg = config_pkg::cva6_cfg_empty,

    // RVFI PROBES
    parameter type rvfi_probes_t = logic,

    // NOC Types AXI bus or several OBI bus
    parameter type noc_req_t  = logic,
    parameter type noc_resp_t = logic,

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
    `CVXIF_RESP_T(CVA6Cfg, x_compressed_resp_t, x_issue_resp_t, x_result_t),
    // --- DCLS ---
    //  Types
    localparam type core_inputs_t = struct packed {
      logic [1:0] irq;
      logic ipi;
      logic time_irq;
      logic debug_req;
      cvxif_resp_t cvxif_resp;
      noc_resp_t noc_resp;
    },
    localparam type core_outputs_t = struct packed {
      cvxif_req_t cvxif_req;
      noc_req_t   noc_req;
    },
    localparam type regfile_inputs_t = struct packed {
      logic [CVA6Cfg.NrRgprPorts-1:0][4:0] raddr;
      logic [CVA6Cfg.NrCommitPorts-1:0][CVA6Cfg.XLEN-1:0] wdata;
      logic [CVA6Cfg.NrCommitPorts-1:0][4:0] waddr;
      logic [CVA6Cfg.NrCommitPorts-1:0] we;
    },
    localparam type bht_update_t = struct packed {
      logic                    valid;
      logic [CVA6Cfg.VLEN-1:0] pc;     // update at PC
      logic                    taken;
    },
    localparam type bht_inputs_t = struct packed {
      logic flush_bp;
      logic debug_mode;
      logic [CVA6Cfg.VLEN-1:0] vpc;
      bht_update_t bht_update;
    },
    localparam type dcls_common_modules_ctrl_t = struct packed {
      regfile_inputs_t regfile_inputs;
      bht_inputs_t bht_inputs;
    },
    localparam type dcls_common_modules_data_t = struct packed {
      logic [CVA6Cfg.NrRgprPorts-1:0][CVA6Cfg.XLEN-1:0] regfile_rdata;
      bht_prediction_t [CVA6Cfg.INSTR_PER_FETCH-1:0] bht_prediction;
    }
    // -----
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
    // DCLS alarm
    output logic [3:0] dcls_alarm_o
);
  if (CVA6Cfg.DclsEn) begin : gen_cva6_dcls
    // ********* CORES IO *********
    core_inputs_t main_inputs, main_inputs_delayed;
    core_outputs_t main_outputs, shadow_outputs;

    assign main_inputs  = '{irq_i, ipi_i, time_irq_i, debug_req_i, cvxif_resp_i, noc_resp_i};
    assign main_outputs = '{cvxif_req_o, noc_req_o};
    // ********* DCLS CTRL *********
    logic rst_shadow;

    dcls_logic #(
        .noc_resp_t(noc_resp_t),
        .core_inputs_t(core_inputs_t),
        .core_outputs_t(core_outputs_t),
        .DCLS_DELAY(CVA6Cfg.DclsDelay)
    ) i_dcls_logic (
        .clk_i,
        .rst_ni,
        .rst_shadow_no(rst_shadow),
        .main_inputs_i(main_inputs),
        .main_inputs_delayed_o(main_inputs_delayed),
        .main_outputs_i(main_outputs),
        .shadow_outputs_i(shadow_outputs),
        .alarm_o(dcls_alarm_o[1:0])
    );
    // ********* CORES COMM *********
    dcls_common_modules_ctrl_t common_from_main, common_from_shadow;
    dcls_common_modules_data_t common_to_main, common_to_shadow;

    if (CVA6Cfg.DclsCommonModules) begin : gen_dcls_common_modules
      dcls_common #(
          .CVA6Cfg                   (CVA6Cfg),
          .regfile_inputs_t          (regfile_inputs_t),
          .bht_update_t              (bht_update_t),
          .bht_inputs_t              (bht_inputs_t),
          .dcls_common_modules_ctrl_t(dcls_common_modules_ctrl_t),
          .dcls_common_modules_data_t(dcls_common_modules_data_t),
          .DCLS_DELAY                (CVA6Cfg.DclsDelay)
      ) i_dcls_common_modules (
          .clk_i,
          .rst_ni,
          .from_main_i(common_from_main),
          .to_main_o(common_to_main),
          .from_shadow_i(common_from_shadow),
          .to_shadow_o(common_to_shadow),
          .alarms_o(dcls_alarm_o[3:2])
      );
    end else begin : gen_dcls_no_common_modules
      assign dcls_alarm_o[3:2] = '0;
      assign common_to_main = '0;
      assign common_to_shadow = '0;
    end
    // ********* CORES *********
    cva6 #(
        .CVA6Cfg                   (CVA6Cfg),
        .rvfi_probes_t             (rvfi_probes_t),
        .noc_req_t                 (noc_req_t),
        .noc_resp_t                (noc_resp_t),
        .regfile_inputs_t          (regfile_inputs_t),
        .bht_inputs_t              (bht_inputs_t),
        .dcls_common_modules_ctrl_t(dcls_common_modules_ctrl_t),
        .dcls_common_modules_data_t(dcls_common_modules_data_t)
    ) i_cva6_main (
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
        .dcls_from_common_i(common_to_main),
        .dcls_to_common_o(common_from_main)
    );
    cva6 #(
        .CVA6Cfg                   (CVA6Cfg),
        .rvfi_probes_t             (rvfi_probes_t),
        .noc_req_t                 (noc_req_t),
        .noc_resp_t                (noc_resp_t),
        .regfile_inputs_t          (regfile_inputs_t),
        .bht_inputs_t              (bht_inputs_t),
        .dcls_common_modules_ctrl_t(dcls_common_modules_ctrl_t),
        .dcls_common_modules_data_t(dcls_common_modules_data_t)
    ) i_cva6_shadow (
        .clk_i(clk_i),
        .rst_ni(rst_shadow),
        .boot_addr_i(boot_addr_i),
        .hart_id_i(hart_id_i),
        .irq_i(main_inputs_delayed.irq),
        .ipi_i(main_inputs_delayed.ipi),
        .time_irq_i(main_inputs_delayed.time_irq),
        .debug_req_i(main_inputs_delayed.debug_req),
        .rvfi_probes_o(),
        .cvxif_req_o(shadow_outputs.cvxif_req),
        .cvxif_resp_i(main_inputs_delayed.cvxif_resp),
        .noc_req_o(shadow_outputs.noc_req),
        .noc_resp_i(main_inputs_delayed.noc_resp),
        .dcls_from_common_i(common_to_shadow),
        .dcls_to_common_o(common_from_shadow)
    );
  end else begin : gen_cva6
    cva6 #(
        .CVA6Cfg      (CVA6Cfg),
        .rvfi_probes_t(rvfi_probes_t),
        .noc_req_t    (noc_req_t),
        .noc_resp_t   (noc_resp_t)
    ) i_cva6 (
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
        .dcls_from_common_i('0),
        .dcls_to_common_o()
    );
    assign dcls_alarm_o = '0;
  end
endmodule
