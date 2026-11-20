// Copyright 2026 Thales France
//
// Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
// You may obtain a copy of the License at https://solderpad.org/licenses/
//
// Original Author: Valentin Thomazic (valentin.thomazic@thalesgroup.com)

module dcls_common_bht #(
    parameter config_pkg::cva6_cfg_t CVA6Cfg = config_pkg::cva6_cfg_empty,
    parameter type bht_inputs_t = logic,
    parameter type bht_update_t = logic,
    parameter int unsigned DCLS_DELAY = 1
) (
    input logic clk_i,
    input logic rst_ni,
    // MAIN
    input bht_inputs_t from_main_i,
    output ariane_pkg::bht_prediction_t [CVA6Cfg.INSTR_PER_FETCH-1:0] to_main_o,
    // SHADOW
    output ariane_pkg::bht_prediction_t [CVA6Cfg.INSTR_PER_FETCH-1:0] to_shadow_o
);
  bht #(
      .CVA6Cfg   (CVA6Cfg),
      .bht_update_t(bht_update_t),
      .NR_ENTRIES(CVA6Cfg.BHTEntries)
  ) i_bht (
      .clk_i,
      .rst_ni,
      .flush_bp_i(from_main_i.flush_bp),
      .debug_mode_i(from_main_i.debug_mode),
      .vpc_i(from_main_i.vpc),
      .bht_update_i(from_main_i.bht_update),
      .bht_prediction_o(to_main_o)
  );

  shift_reg #(
      .dtype(ariane_pkg::bht_prediction_t[CVA6Cfg.INSTR_PER_FETCH-1:0]),
      .Depth(DCLS_DELAY)
  ) i_dcls_bht_output_delay (
      .clk_i,
      .rst_ni,
      .d_i(to_main_o),
      .d_o(to_shadow_o)
  );
endmodule
