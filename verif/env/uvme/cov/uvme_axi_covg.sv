// Copyright 2023 Thales DIS SAS
//
// Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
// You may obtain a copy of the License at https://solderpad.org/licenses/
//
// Original Author: Alae Eddine EZ ZEJJARI (alae-eddine.ez-zejjari@external.thalesgroup.com) – sub-contractor MU-Electronics for Thales group


`ifndef __UVME_AXI_COVG_SV__
`define __UVME_AXI_COVG_SV__

   /*
   * Covergroups
   * Declared at package-level to enable multiple instances per monitor class (e.g. read/write)
   */

covergroup cg_axi_w_channel(string name)
   with function sample(uvma_axi_transaction_c item, bit RVA);

   option.per_instance = 1;
   option.name         = name;

   awready_to_valid: coverpoint (item.ready_delay_cycle_chan_ax) {
      bins dly[] = {[0:16]};
   }

   wready_to_valid: coverpoint (item.ready_delay_cycle_chan_w[0]) {
      bins dly[] = {[0:16]};
   }

   awsize: coverpoint (item.m_size){
      bins size[] = {[0:3]};
      ignore_bins IGN_SIZE3 = {3} iff(uvme_cva6_pkg::XLEN == 32);
   }

   awlock: coverpoint (item.m_lock){
      bins lock[]    = {[0:1]};
      ignore_bins IGN_EXCLUSIVE = {1} iff(!RVA);
   }

   wstrb: coverpoint (item.m_wstrb[0]) {
      bins strb1   = {1};
      bins strb2   = {2};
      bins strb3   = {3};
      bins strb4   = {4};
      bins strb8   = {8};
      bins strb12  = {12};
      bins strb15  = {15};
      bins strb16  = {16};
      bins strb32  = {32};
      bins strb48  = {48};
      bins strb64  = {64};
      bins strb128 = {128};
      bins strb192 = {192};
      bins strb240 = {240};
      bins strb255 = {255};
      ignore_bins IGN_STRB255 = {255} iff(uvme_cva6_pkg::XLEN == 32);
   }

   aw_axi_cross: cross awready_to_valid, wready_to_valid, awsize, awlock{
   illegal_bins ILLEGAL_BINS = binsof(awlock) intersect{1} &&
                               binsof(awsize) intersect{[0:1]};
   ignore_bins IGN_CROSS = binsof(awsize) intersect{3} iff(uvme_cva6_pkg::XLEN == 32);
   }
endgroup : cg_axi_w_channel

covergroup cg_axi_b_channel(string name)
   with function sample(uvma_axi_transaction_c item);

   option.per_instance = 1;
   option.name         = name;

   bresp: coverpoint (item.m_resp[0]){
      bins zero  = {0};
      bins one   = {1};
      bins two   = {2};
      bins three = {3};
   }
endgroup : cg_axi_b_channel

covergroup cg_axi_ar_channel(string name)
   with function sample(uvma_axi_transaction_c item, bit RVA);

   option.per_instance = 1;
   option.name         = name;

   arlen: coverpoint (item.m_len) {
      bins LEN[] = {[0:1]};
   }

   arsize: coverpoint (item.m_size) {
      bins SIZE[] = {[0:3]} iff(item.m_len == 0);
   }

   arready_to_valid: coverpoint (item.ready_delay_cycle_chan_ax) {
      bins dly[] = {[0:16]};
   }

   arlock: coverpoint (item.m_lock){
      bins lock[]    = {[0:1]};
      ignore_bins IGN_EXCLUSIVE = {1} iff(!RVA);
   }

   ar_axi_cross: cross arready_to_valid, arlen;

   ar_lock_size_axi_cross: cross arready_to_valid, arlock, arsize{
   illegal_bins ILLEGAL_BINS = binsof(arlock) intersect{1} &&
                              binsof(arsize) intersect{[0:1]};
   ignore_bins IGN_CROSS = binsof(arlock) intersect{0} &&  binsof(arsize) intersect{3} iff(uvme_cva6_pkg::XLEN == 32);
   }

endgroup : cg_axi_ar_channel

covergroup cg_axi_r_channel(string name)
   with function sample(uvma_axi_transaction_c item, int index);

   option.per_instance = 1;
   option.name         = name;

   rlast: coverpoint (item.m_last[index]);

   rresp: coverpoint (item.m_resp[index]){
      bins zero  = {0};
      bins one   = {1};
      bins two   = {2};
      bins three = {3};
   }

   r_axi_cross: cross rlast, rresp;
endgroup : cg_axi_r_channel

/**
 * Component encapsulating Open Bus Interface functional coverage model.
 */
class uvme_axi_covg_c extends uvm_component;

   // Objects
   uvme_cva6_cntxt_c         cntxt;
   uvme_cva6_cfg_c           cfg;
   bit RVA;

   // TLM
   uvm_tlm_analysis_fifo #(uvma_axi_transaction_c)    uvme_axi_cov_aw_req_fifo;
   uvm_tlm_analysis_fifo #(uvma_axi_transaction_c)    uvme_axi_cov_b_resp_fifo;
   uvm_tlm_analysis_fifo #(uvma_axi_transaction_c)    uvme_axi_cov_ar_req_fifo;
   uvm_tlm_analysis_fifo #(uvma_axi_transaction_c)    uvme_axi_cov_r_resp_fifo;

   // Covergroup instances
   cg_axi_w_channel       w_axi_cg;
   cg_axi_b_channel       b_axi_cg;
   cg_axi_ar_channel      ar_axi_cg;
   cg_axi_r_channel       r_axi_cg;

   `uvm_component_utils_begin(uvme_axi_covg_c)
      `uvm_field_object(cfg, UVM_DEFAULT)
      `uvm_field_object(cntxt, UVM_DEFAULT)
   `uvm_component_utils_end


   /**
    * Default constructor.
    */
   extern function new(string name="uvma_axi_cov_model", uvm_component parent=null);

   /**
    * 1. Ensures cfg & cntxt handles are not null.
    * 2. Builds fifos.
    */
   extern virtual function void build_phase(uvm_phase phase);

   /**
    * Forks all sampling loops
    */
   extern virtual task run_phase(uvm_phase phase);

endclass : uvme_axi_covg_c


function uvme_axi_covg_c::new(string name="uvma_axi_cov_model", uvm_component parent=null);

   super.new(name, parent);

endfunction : new


// A significant chunk of the build_phase method is common between this
// coverage model and the sequencer (uvma_obi_memory_sqr).  This is
// appropriate so the duplicated code has a lint waiver.
//
function void uvme_axi_covg_c::build_phase(uvm_phase phase);

   super.build_phase(phase);

   void'(uvm_config_db#(uvme_cva6_cfg_c)::get(this, "", "cfg", cfg));
   if (cfg == null) begin
      `uvm_fatal("cfg", "Context handle is null")
   end

   void'(uvm_config_db#(uvme_cva6_cntxt_c)::get(this, "", "cntxt", cntxt));
   if (cntxt == null) begin
      `uvm_fatal("CNTXT", "Context handle is null")
   end

   RVA = cfg.ext_a_supported;

   uvme_axi_cov_b_resp_fifo  = new("uvme_axi_cov_b_resp_fifo"   , this);
   uvme_axi_cov_r_resp_fifo  = new("uvme_axi_cov_r_resp_fifo"   , this);
   uvme_axi_cov_ar_req_fifo  = new("uvme_axi_cov_ar_req_fifo"   , this);
   uvme_axi_cov_aw_req_fifo  = new("uvme_axi_cov_aw_req_fifo"   , this);

   w_axi_cg  = new("w_axi_cg");
   b_axi_cg  = new("b_axi_cg");
   ar_axi_cg = new("ar_axi_cg");
   r_axi_cg  = new("r_axi_cg");

endfunction : build_phase

task uvme_axi_covg_c::run_phase(uvm_phase phase);

   super.run_phase(phase);
   `uvm_info(get_type_name(), $sformatf("cov_model_enabled = %d", cfg.cov_model_enabled), UVM_HIGH)
   `uvm_info(get_type_name(), $sformatf("ATOMIC ENABLE = %d", RVA), UVM_HIGH)
   forever begin
      uvma_axi_transaction_c  aw_item;
      uvma_axi_transaction_c  b_item;
      uvma_axi_transaction_c  ar_item;
      uvma_axi_transaction_c  r_item;

     fork
        uvme_axi_cov_b_resp_fifo.get(b_item);
        uvme_axi_cov_r_resp_fifo.get(r_item);
        uvme_axi_cov_ar_req_fifo.get(ar_item);
        uvme_axi_cov_aw_req_fifo.get(aw_item);
     join_any
     disable fork;

     if(aw_item != null) begin
         `uvm_info(get_type_name(), $sformatf("WRITE REQ ITEM DETECTED"), UVM_HIGH)
         w_axi_cg.sample(aw_item, RVA);
      end

     if(b_item != null) begin
         `uvm_info(get_type_name(), $sformatf("WRITE RESP ITEM DETECTED"), UVM_HIGH)
         b_axi_cg.sample(b_item);
      end

      if(ar_item != null) begin
         `uvm_info(get_type_name(), $sformatf("READ ADDRESS ITEM DETECTED"), UVM_HIGH)
         ar_axi_cg.sample(ar_item, RVA);
      end

      if(r_item != null) begin
         `uvm_info(get_type_name(), $sformatf("READ DATA ITEM DETECTED"), UVM_HIGH)
         for(int i = 0; i <= r_item.m_len; i++) begin
            r_axi_cg.sample(r_item, i);
         end
      end

   end

endtask : run_phase

`endif // __UVME_AXI_COVG_SV__
