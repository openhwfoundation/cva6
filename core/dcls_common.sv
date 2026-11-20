// Copyright 2026 Thales France
//
// Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
// You may obtain a copy of the License at https://solderpad.org/licenses/
//
// Original Author: Valentin Thomazic (valentin.thomazic@thalesgroup.com)

module dcls_common #(
    parameter config_pkg::cva6_cfg_t CVA6Cfg = config_pkg::cva6_cfg_empty,
    parameter type dcls_common_modules_data_t = logic,
    parameter type dcls_common_modules_ctrl_t = logic,
    parameter type bht_inputs_t = logic,
    parameter type regfile_inputs_t = logic,
    parameter type bht_update_t = logic,
    parameter int unsigned DCLS_DELAY = 1
) (
    input logic clk_i,
    input logic rst_ni,
    // MAIN
    input dcls_common_modules_ctrl_t from_main_i,
    output dcls_common_modules_data_t to_main_o,
    // SHADOW
    input dcls_common_modules_ctrl_t from_shadow_i,
    output dcls_common_modules_data_t to_shadow_o,
    // ALARM
    output logic [1:0] alarms_o
);
  if (CVA6Cfg.DclsCommonRegfile) begin : gen_dcls_common_regfile
    dcls_common_regfile #(
        .CVA6Cfg         (CVA6Cfg),
        .regfile_inputs_t(regfile_inputs_t),
        .DCLS_DELAY      (DCLS_DELAY)
    ) i_dcls_common_regfile (
        .clk_i,
        .rst_ni,
        .main_i  (from_main_i.regfile_inputs),
        .main_o  (to_main_o.regfile_rdata),
        .shadow_i(from_shadow_i.regfile_inputs),
        .shadow_o(to_shadow_o.regfile_rdata),
        .alarms_o(alarms_o)
    );
  end else begin : gen_dcls_no_common_regfile
    assign alarms_o = '0;
    assign to_main_o.regfile_rdata = '0;
    assign to_shadow_o.regfile_rdata = '0;
  end
  if (CVA6Cfg.DclsCommonBHT) begin : gen_dcls_common_bht
    dcls_common_bht #(
        .CVA6Cfg     (CVA6Cfg),
        .bht_inputs_t(bht_inputs_t),
        .bht_update_t(bht_update_t),
        .DCLS_DELAY  (DCLS_DELAY)
    ) i_dcls_common_bht (
        .clk_i,
        .rst_ni,
        .from_main_i(from_main_i.bht_inputs),
        .to_main_o  (to_main_o.bht_prediction),
        .to_shadow_o(to_shadow_o.bht_prediction)
    );
  end else begin : gen_dcls_no_common_bht
    assign to_main_o.bht_prediction   = '0;
    assign to_shadow_o.bht_prediction = '0;
  end
endmodule
