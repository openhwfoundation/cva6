// Copyright 2026 Thales France
//
// Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
// You may obtain a copy of the License at https://solderpad.org/licenses/
//
// Original Author: Valentin Thomazic (valentin.thomazic@thalesgroup.com)

module dcls_common_regfile #(
    parameter config_pkg::cva6_cfg_t CVA6Cfg = config_pkg::cva6_cfg_empty,
    parameter type regfile_inputs_t = logic,
    parameter int unsigned DCLS_DELAY = 1
) (
    input logic clk_i,
    input logic rst_ni,
    // MAIN
    input regfile_inputs_t main_i,
    output logic [CVA6Cfg.NrRgprPorts-1:0][CVA6Cfg.XLEN-1:0] main_o,
    // SHADOW
    input regfile_inputs_t shadow_i,
    output logic [CVA6Cfg.NrRgprPorts-1:0][CVA6Cfg.XLEN-1:0] shadow_o,
    // ALARMS
    output logic [1:0] alarms_o
);
  // *********** REGFILE **************
  ariane_regfile #(
      .CVA6Cfg      (CVA6Cfg),
      .DATA_WIDTH   (CVA6Cfg.XLEN),
      .NR_READ_PORTS(CVA6Cfg.NrRgprPorts),
      .ZERO_REG_ZERO(1)
  ) i_ariane_regfile (
      .clk_i,
      .rst_ni,
      .test_en_i(1'b0),
      .raddr_i  (main_i.raddr),
      .rdata_o  (main_o),
      .waddr_i  (main_i.waddr),
      .wdata_i  (main_i.wdata),
      .we_i     (main_i.we)
  );
  // *********** DELAY **************
  regfile_inputs_t main_inputs, main_inputs_delayed;

  assign main_inputs = '{main_i.raddr, main_i.wdata, main_i.waddr, main_i.we};

  shift_reg #(
      .dtype(regfile_inputs_t),
      .Depth(DCLS_DELAY)
  ) i_dcls_regfile_inputs_delay (
      .clk_i,
      .rst_ni,
      .d_i(main_inputs),
      .d_o(main_inputs_delayed)
  );

  shift_reg #(
      .dtype(logic [CVA6Cfg.NrRgprPorts-1:0][CVA6Cfg.XLEN-1:0]),
      .Depth(DCLS_DELAY)
  ) i_dcls_regfile_output_delay (
      .clk_i,
      .rst_ni,
      .d_i(main_o),
      .d_o(shadow_o)
  );
  // *********** COMPARISON **************
  for (genvar i = 0; i < 2; i++) begin : gen_dcls_regfile_comparators
    dcls_comparator #(
        .data_t(regfile_inputs_t)
    ) i_dcls_regfile_comparator (
        .clk_i,
        .rst_ni,
        .main_i  (main_inputs_delayed),
        .shadow_i(shadow_i),
        .alarm_o (alarms_o[i])
    );
  end
endmodule
