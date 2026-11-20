// Copyright 2022 Thales DIS SAS
//
// Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
// You may obtain a copy of the License at https://solderpad.org/licenses/
//
// Original Author: Alae Eddine EZ ZEJJARI (alae-eddine.ez-zejjari@external.thalesgroup.com) – sub-contractor MU-Electronics for Thales group

// *************************** AXI features supported by CVA6  ************************** //

`include "uvm_macros.svh"

module  uvmt_cva6_axi_assert#(config_pkg::cva6_cfg_t CVA6Cfg = config_pkg::cva6_cfg_empty)
        (uvma_axi_intf axi_assert_if);

   import uvm_pkg::*;

   //Check if user-defined extension for read address channel is equal to 0b00
   property AXI4_CVA6_ARUSER;
      @(posedge axi_assert_if.clk && axi_assert_if.axi_assertion_enabled) disable iff (!axi_assert_if.rst_n) axi_assert_if.ar_valid |-> axi_assert_if.ar_user == 0;
   endproperty

   //Check if user-defined extension for write address channel is equal to 0b00
   property AXI4_CVA6_AWUSER;
      @(posedge axi_assert_if.clk && axi_assert_if.axi_assertion_enabled) disable iff (!axi_assert_if.rst_n) axi_assert_if.aw_valid |-> axi_assert_if.aw_user == 0;
   endproperty

   //Check if Quality of Service identifier for write transaction is equal to 0b0000
   property AXI4_CVA6_AWQOS;
      @(posedge axi_assert_if.clk && axi_assert_if.axi_assertion_enabled) disable iff (!axi_assert_if.rst_n) axi_assert_if.aw_valid |-> axi_assert_if.aw_qos == 0;
   endproperty

   //Check if Quality of Service identifier for read transaction is equal to 0b0000
   property AXI4_CVA6_ARQOS;
      @(posedge axi_assert_if.clk && axi_assert_if.axi_assertion_enabled) disable iff (!axi_assert_if.rst_n) axi_assert_if.ar_valid |-> axi_assert_if.ar_qos == 0;
   endproperty

   //Check if Region indicator for write transaction is equal to 0b0000
   property AXI4_CVA6_AWREGION;
      @(posedge axi_assert_if.clk && axi_assert_if.axi_assertion_enabled) disable iff (!axi_assert_if.rst_n) axi_assert_if.aw_valid |-> axi_assert_if.aw_region == 0;
   endproperty

   //Check if Region indicator for read transaction is equal to 0b0000
   property AXI4_CVA6_ARREGION;
      @(posedge axi_assert_if.clk && axi_assert_if.axi_assertion_enabled) disable iff (!axi_assert_if.rst_n) axi_assert_if.ar_valid |-> axi_assert_if.ar_region == 0;
   endproperty

   //Check if Protection attributes for write transaction always take the 0b000
   property AXI4_CVA6_AWPROT;
      @(posedge axi_assert_if.clk && axi_assert_if.axi_assertion_enabled) disable iff (!axi_assert_if.rst_n) axi_assert_if.aw_valid |-> axi_assert_if.aw_prot == 0;
   endproperty

   //Check if Protection attributes for read transaction always take the 0b000
   property AXI4_CVA6_ARPROT;
      @(posedge axi_assert_if.clk && axi_assert_if.axi_assertion_enabled) disable iff (!axi_assert_if.rst_n) axi_assert_if.ar_valid |-> axi_assert_if.ar_prot == 0;
   endproperty

   //Check if all write transaction performed by CVA6 are of type INCR
   property AXI4_CVA6_AWBURST;
      @(posedge axi_assert_if.clk && axi_assert_if.axi_assertion_enabled) disable iff (!axi_assert_if.rst_n) axi_assert_if.aw_valid |-> axi_assert_if.aw_burst == 1;
   endproperty

   //Check if all read transaction performed by CVA6 are of type INCR
   property AXI4_CVA6_ARBURST;
      @(posedge axi_assert_if.clk && axi_assert_if.axi_assertion_enabled) disable iff (!axi_assert_if.rst_n) axi_assert_if.ar_valid |-> axi_assert_if.ar_burst == 1;
   endproperty

   //Check if all write transaction performed by CVA6 are single beats. Not
   //true of a write-back HPDcache, which evicts whole lines in bursts.
   property AXI4_CVA6_AWLEN;
      @(posedge axi_assert_if.clk && (CVA6Cfg.CacheWritePolicy == config_pkg::CACHE_WT) && axi_assert_if.axi_assertion_enabled) disable iff (!axi_assert_if.rst_n) axi_assert_if.aw_valid |-> axi_assert_if.aw_len == 0;
   endproperty

   //Check if all Read transaction performed by CVA6 are equal to 0 or 1
   property AXI4_CVA6_ARLEN;
      @(posedge axi_assert_if.clk && axi_assert_if.axi_assertion_enabled) disable iff (!axi_assert_if.rst_n) axi_assert_if.ar_valid |-> axi_assert_if.ar_len == 0 || axi_assert_if.ar_len == 1;
   endproperty

   //Check if all Write transaction performed by CVA6 are of type Non atomic, AtomicLoad or AtomicSwap
   property AXI4_CVA6_AWATOP;
      @(posedge axi_assert_if.clk && axi_assert_if.axi_assertion_enabled) disable iff (!axi_assert_if.rst_n) axi_assert_if.aw_valid |-> (axi_assert_if.aw_atop[5:4] == 0 || axi_assert_if.aw_atop[5:4] == 2 || axi_assert_if.aw_atop[5:4] == 3) && axi_assert_if.aw_atop[3] == 0;
   endproperty

   //Memory type of a transaction (AxCACHE) against the PMA of its address:
   //modifiable always, bufferable in a bufferable region, read and write
   //allocate in a cacheable one. An exclusive access is normal non-cacheable
   //non-bufferable. An atomic transaction (AWATOP), which the memory executes,
   //is non-cacheable with the bufferable attribute of its region. A
   //transaction never crosses a region: it is at most a cache line.
   function automatic logic [3:0] pma_cache(logic [63:0] addr);
      return {{2{config_pkg::is_inside_cacheable_regions(CVA6Cfg, addr)}},
              1'b1,
              config_pkg::is_inside_bufferable_regions(CVA6Cfg, addr)};
   endfunction

   property AXI4_CVA6_ARCACHE;
      @(posedge axi_assert_if.clk && axi_assert_if.axi_assertion_enabled) disable iff (!axi_assert_if.rst_n) axi_assert_if.ar_valid |->
         axi_assert_if.ar_cache == (axi_assert_if.ar_lock ? 4'b0010 : pma_cache(64'(axi_assert_if.ar_addr)));
   endproperty

   property AXI4_CVA6_AWCACHE;
      @(posedge axi_assert_if.clk && axi_assert_if.axi_assertion_enabled) disable iff (!axi_assert_if.rst_n) axi_assert_if.aw_valid |->
         axi_assert_if.aw_cache == (axi_assert_if.aw_lock ? 4'b0010 :
                                    (axi_assert_if.aw_atop != 0) ? (pma_cache(64'(axi_assert_if.aw_addr)) & 4'b0011) :
                                    pma_cache(64'(axi_assert_if.aw_addr)));
   endproperty

/********************************************** Assert Property ******************************************************/

   cva6_aruser              : assert property (AXI4_CVA6_ARUSER)
                         else `uvm_error (" AXI4 protocol checks assertion ", "Violation of AXI4_CVA6_ARUSER");

   cva6_awuser              : assert property (AXI4_CVA6_AWUSER)
                         else `uvm_error (" AXI4 protocol checks assertion ", "Violation of AXI4_CVA6_AWUSER");

   cva6_arqos               : assert property (AXI4_CVA6_ARQOS)
                         else `uvm_error (" AXI4 protocol checks assertion ", "Violation of AXI4_CVA6_ARQOS");

   cva6_awqos               : assert property (AXI4_CVA6_AWQOS)
                         else `uvm_error (" AXI4 protocol checks assertion ", "Violation of AXI4_CVA6_AWQOS");

   cva6_arregion            : assert property (AXI4_CVA6_ARREGION)
                         else `uvm_error (" AXI4 protocol checks assertion ", "Violation of AXI4_CVA6_ARREGION");

   cva6_awregion            : assert property (AXI4_CVA6_AWREGION)
                         else `uvm_error (" AXI4 protocol checks assertion ", "Violation of AXI4_CVA6_AWREGION");

   cva6_arprot              : assert property (AXI4_CVA6_ARPROT)
                         else `uvm_error (" AXI4 protocol checks assertion ", "Violation of AXI4_CVA6_ARPROT");

   cva6_awprot              : assert property (AXI4_CVA6_AWPROT)
                         else `uvm_error (" AXI4 protocol checks assertion ", "Violation of AXI4_CVA6_AWPROT");

   cva6_arburst             : assert property (AXI4_CVA6_ARBURST)
                         else `uvm_error (" AXI4 protocol checks assertion ", "Violation of AXI4_CVA6_ARBURST");

   cva6_awburst             : assert property (AXI4_CVA6_AWBURST)
                         else `uvm_error (" AXI4 protocol checks assertion ", "Violation of AXI4_CVA6_AWBURST");

   cva6_arlen               : assert property (AXI4_CVA6_ARLEN)
                         else `uvm_error (" AXI4 protocol checks assertion ", "Violation of AXI4_CVA6_ARLEN");

   cva6_awlen               : assert property (AXI4_CVA6_AWLEN)
                         else `uvm_error (" AXI4 protocol checks assertion ", "Violation of AXI4_CVA6_AWLEN");

   cva6_awatop              : assert property (AXI4_CVA6_AWATOP)
                         else `uvm_error (" AXI4 protocol checks assertion ", "Violation of AXI4_CVA6_AWATOP");

   cva6_arcache             : assert property (AXI4_CVA6_ARCACHE)
                         else `uvm_error (" AXI4 protocol checks assertion ", "Violation of AXI4_CVA6_ARCACHE");

   cva6_awcache             : assert property (AXI4_CVA6_AWCACHE)
                         else `uvm_error (" AXI4 protocol checks assertion ", "Violation of AXI4_CVA6_AWCACHE");

/********************************************** Cover Property ******************************************************/

   cov_cva6_aruser      : cover property(AXI4_CVA6_ARUSER);

   cov_cva6_awuser      : cover property(AXI4_CVA6_AWUSER);

   cov_cva6_arqos       : cover property(AXI4_CVA6_ARQOS);

   cov_cva6_awqos       : cover property(AXI4_CVA6_AWQOS);

   cov_cva6_arregion    : cover property(AXI4_CVA6_ARREGION);

   cov_cva6_awregion    : cover property(AXI4_CVA6_AWREGION);

   cov_cva6_arprot      : cover property(AXI4_CVA6_ARPROT);

   cov_cva6_awprot      : cover property(AXI4_CVA6_AWPROT);

   cov_cva6_arburst     : cover property(AXI4_CVA6_ARBURST);

   cov_cva6_awburst     : cover property(AXI4_CVA6_AWBURST);

   cov_cva6_arlen       : cover property(AXI4_CVA6_ARLEN);

   cov_cva6_awlen       : cover property(AXI4_CVA6_AWLEN);

   cov_cva6_awatop       : cover property(AXI4_CVA6_AWATOP);

   cov_cva6_arcache      : cover property(AXI4_CVA6_ARCACHE);

   cov_cva6_awcache      : cover property(AXI4_CVA6_AWCACHE);

endmodule : uvmt_cva6_axi_assert
