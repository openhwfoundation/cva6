// Copyright 2026 Thales France
//
// Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
// You may obtain a copy of the License at https://solderpad.org/licenses/
//
// Original Author: Valentin Thomazic (valentin.thomazic@thalesgroup.com)

module dcls_comparator #(
    parameter type data_t = logic
) (
    input  logic  clk_i,
    input  logic  rst_ni,
    input  data_t main_i,
    input  data_t shadow_i,
    output logic  alarm_o
);
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) alarm_o <= '0;
    else
      case (main_i)
        shadow_i: alarm_o <= '0;
        default:  alarm_o <= '1;
      endcase
  end
endmodule
