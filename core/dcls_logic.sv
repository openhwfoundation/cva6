// Copyright 2026 Thales France
//
// Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
// You may obtain a copy of the License at https://solderpad.org/licenses/
//
// Original Author: Valentin Thomazic (valentin.thomazic@thalesgroup.com)

module dcls_logic #(
    parameter type noc_resp_t = logic,
    parameter type core_inputs_t = logic,
    parameter type core_outputs_t = logic,
    parameter int unsigned DCLS_DELAY = 1
) (
    input logic clk_i,
    input logic rst_ni,
    // RESETS
    output logic rst_shadow_no,
    // Core inputs
    input core_inputs_t main_inputs_i,
    output core_inputs_t main_inputs_delayed_o,
    // Core outputs
    input core_outputs_t main_outputs_i,
    input core_outputs_t shadow_outputs_i,
    // Alarms
    output logic [1:0] alarm_o
);
  // SHADOW CORE RESET GEN
  shift_reg #(
      .dtype(logic),
      .Depth(DCLS_DELAY)
  ) i_dcls_shadow_rst_gen (
      .clk_i,
      .rst_ni(rst_ni),
      .d_i(rst_ni),
      .d_o(rst_shadow_no)
  );
  // INPUTS DELAY
  shift_reg #(
      .dtype(core_inputs_t),
      .Depth(DCLS_DELAY)
  ) i_dcls_input_delay (
      .clk_i,
      .rst_ni(rst_ni),
      .d_i(main_inputs_i),
      .d_o(main_inputs_delayed_o)
  );
  // OUTPUTS DELAY
  core_outputs_t main_outputs_delayed, main_outputs_delayed_dup;

  shift_reg #(
      .dtype(core_outputs_t),
      .Depth(DCLS_DELAY)
  ) i_dcls_output_delay (
      .clk_i,
      .rst_ni(rst_ni),
      .d_i(main_outputs_i),
      .d_o(main_outputs_delayed)
  );
  // ALARMS
  for (genvar i = 0; i < 2; i++) begin : gen_dcls_output_comparators
    dcls_comparator #(
        .data_t(core_outputs_t)
    ) i_dcls_comparator (
        .clk_i,
        .rst_ni  (rst_shadow_no),
        .main_i  (main_outputs_delayed),
        .shadow_i(shadow_outputs_i),
        .alarm_o (alarm_o[i])
    );
  end
endmodule
