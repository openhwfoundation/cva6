// Copyright 2024 Thales DIS SAS
//
// Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
// You may obtain a copy of the License at https://solderpad.org/licenses/
//
// Original Author: Ayoub JALALI (ayoub.jalali@external.thalesgroup.com)


`ifndef __UVMA_INTERRUPT_CNTXT_SV__
`define __UVMA_INTERRUPT_CNTXT_SV__


/**
 * Object encapsulating all state variables for all Interrupt agent
 * (uvma_interrupt_agent_c) components.
 */
class uvma_interrupt_cntxt_c extends uvm_object;
   
   // Handle to agent interface
   virtual  uvma_interrupt_if     interrupt_vif;

   // Handle to memory storage to check clear condition
   uvml_mem_c#(MAX_ADDR_WIDTH)    mem_axi;
   uvml_mem_c                     mem_obi;

   // Retired instruction interface, used by the deterministic interrupt mode to
   // spot the hook address committing. Left at the interface defaults: the
   // fields used, rvfi_valid and rvfi_pc_rdata, do not depend on ILEN.
   virtual uvma_rvfi_instr_if rvfi_instr_vif;

   // Integrals
   uvma_interrupt_reset_state_enum  reset_state        = UVMA_INTERRUPT_RESET_STATE_PRE_RESET;

   // Events
   uvm_event  sample_cfg_e;
   uvm_event  sample_cntxt_e;

   `uvm_object_utils_begin(uvma_interrupt_cntxt_c)
      `uvm_field_event(sample_cfg_e  , UVM_DEFAULT)
      `uvm_field_event(sample_cntxt_e, UVM_DEFAULT)
      `uvm_field_enum(uvma_interrupt_reset_state_enum, reset_state, UVM_DEFAULT)
      `uvm_field_object(mem_axi, UVM_DEFAULT)
      `uvm_field_object(mem_obi, UVM_DEFAULT)
   `uvm_object_utils_end
      
   /**
    * Builds events.
    */
   extern function new(string name="uvma_interrupt_cntxt");
   
endclass : uvma_interrupt_cntxt_c

function uvma_interrupt_cntxt_c::new(string name="uvma_interrupt_cntxt");
   
   super.new(name);
   mem_axi = uvml_mem_c#(MAX_ADDR_WIDTH)::type_id::create("mem_axi");
   mem_obi = uvml_mem_c::type_id::create("mem_obi");

   sample_cfg_e   = new("sample_cfg_e"  );
   sample_cntxt_e = new("sample_cntxt_e");
   
endfunction : new


`endif // __UVMA_INTERRUPT_CNTXT_SV__
