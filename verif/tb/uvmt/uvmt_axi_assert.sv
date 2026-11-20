// Copyright 2022 Thales DIS SAS
//
// Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
// You may obtain a copy of the License at https://solderpad.org/licenses/
//
// Original Author: Alae Eddine EZ ZEJJARI (alae-eddine.ez-zejjari@external.thalesgroup.com) – sub-contractor MU-Electronics for Thales group

module  uvmt_axi_assert#(config_pkg::cva6_cfg_t CVA6Cfg = config_pkg::cva6_cfg_empty)
  (uvma_axi_intf axi_assert_if);

   import uvm_pkg::*;

   uvma_axi_assert            axi_mix_assert(.axi_assert(axi_assert_if));

   uvma_axi_aw_assert         axi_aw_assert(.axi_assert(axi_assert_if));

   uvma_axi_ar_assert         axi_ar_assert(.axi_assert(axi_assert_if));

   uvma_axi_w_assert #(.CHECK_STROBE(1)) axi_w_assert(.axi_assert(axi_assert_if));

   uvma_axi_r_assert          axi_r_assert(.axi_assert(axi_assert_if));

   uvma_axi_b_assert          axi_b_assert(.axi_assert(axi_assert_if));

   uvma_axi_amo_assert        axi_amo_assert(.axi_assert(axi_assert_if));

   uvmt_cva6_axi_assert#(CVA6Cfg)        cva6_axi_assert(.axi_assert_if(axi_assert_if));


endmodule : uvmt_axi_assert
