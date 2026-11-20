// Copyright 2020 OpenHW Group
// Copyright 2020 Datum Technology Corporation
// Copyright 2020 Silicon Labs, Inc.
// Copyright 2021 Thales DIS Design Services SAS
//
// Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://solderpad.org/licenses/
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0


`ifndef __UVME_CVA6_CNTXT_SV__
`define __UVME_CVA6_CNTXT_SV__

/**
 * Object encapsulating all state variables for CVA6 environment
 * (uvme_cva6_env_c) components.
 */
class uvme_cva6_cntxt_c extends uvm_object;

  typedef uvml_mem_c#(cva6_config_pkg::CVA6ConfigAxiAddrWidth)   uvml_mem_cva6;

   // Agent context handles
   uvma_clknrst_cntxt_c    clknrst_cntxt;
   uvma_axi_cntxt_c        axi_cntxt;

   uvma_obi_memory_cntxt_c        obi_memory_instr_cntxt;
   uvma_obi_memory_cntxt_c        obi_memory_store_cntxt;
   uvma_obi_memory_cntxt_c        obi_memory_amo_cntxt;
   uvma_obi_memory_cntxt_c        obi_memory_zcmt_cntxt;
   uvma_obi_memory_cntxt_c        obi_memory_load_cntxt;
   uvma_obi_memory_cntxt_c        obi_memory_mmu_ptw_cntxt;

   uvma_cva6_core_cntrl_cntxt_c  core_cntrl_cntxt;
   uvma_rvfi_cntxt_c             rvfi_cntxt;
   uvma_interrupt_cntxt_c        interrupt_cntxt;
   uvma_cvxif_cntxt_c            cvxif_cntxt;

   // Memory modelling
   rand uvml_mem_cva6   mem;
   rand uvml_mem_c      mem_obi;

   // Handle to debug_req interface
   virtual uvma_debug_if   debug_vif;

   // Events
   uvm_event  sample_cfg_e;
   uvm_event  sample_cntxt_e;


   `uvm_object_utils_begin(uvme_cva6_cntxt_c)
      `uvm_field_object(clknrst_cntxt,   UVM_DEFAULT)
      `uvm_field_object(axi_cntxt,     UVM_DEFAULT)

      `uvm_field_object(obi_memory_instr_cntxt,     UVM_DEFAULT)
      `uvm_field_object(obi_memory_store_cntxt,     UVM_DEFAULT)
      `uvm_field_object(obi_memory_amo_cntxt,     UVM_DEFAULT)
      `uvm_field_object(obi_memory_load_cntxt,     UVM_DEFAULT)
      `uvm_field_object(obi_memory_zcmt_cntxt,     UVM_DEFAULT)
      `uvm_field_object(obi_memory_mmu_ptw_cntxt,     UVM_DEFAULT)

      `uvm_field_object(core_cntrl_cntxt,   UVM_DEFAULT)
      `uvm_field_object(rvfi_cntxt,      UVM_DEFAULT)
      `uvm_field_object(interrupt_cntxt,      UVM_DEFAULT)
      `uvm_field_object(cvxif_cntxt,      UVM_DEFAULT)
      `uvm_field_event(sample_cfg_e  , UVM_DEFAULT)
      `uvm_field_event(sample_cntxt_e, UVM_DEFAULT)
      `uvm_field_object(mem, UVM_DEFAULT)
      `uvm_field_object(mem_obi, UVM_DEFAULT)
   `uvm_object_utils_end

   constraint mem_cfg_cons {
      mem.mem_default == MEM_DEFAULT_0;
      mem_obi.mem_default == MEM_DEFAULT_0;
   }

   /**
    * Builds events and sub-context objects.
    */
   extern function new(string name="uvme_cva6_cntxt");

endclass : uvme_cva6_cntxt_c


function uvme_cva6_cntxt_c::new(string name="uvme_cva6_cntxt");

   super.new(name);

   clknrst_cntxt      = uvma_clknrst_cntxt_c::type_id::create("clknrst_cntxt");
   core_cntrl_cntxt   = uvma_cva6_core_cntrl_cntxt_c::type_id::create("core_cntrl_cntxt");
   if (RTLCVA6Cfg.MemSubsystem != config_pkg::MEM_OBI) begin
      axi_cntxt          = uvma_axi_cntxt_c::type_id::create("axi_cntxt");
   end else begin
      obi_memory_instr_cntxt       = uvma_obi_memory_cntxt_c::type_id::create("obi_memory_instr_cntxt");
      obi_memory_store_cntxt       = uvma_obi_memory_cntxt_c::type_id::create("obi_memory_store_cntxt");
      obi_memory_load_cntxt        = uvma_obi_memory_cntxt_c::type_id::create("obi_memory_load_cntxt");
      if (RTLCVA6Cfg.RVA) begin
         obi_memory_amo_cntxt         = uvma_obi_memory_cntxt_c::type_id::create("obi_memory_amo_cntxt");
      end
      if (RTLCVA6Cfg.RVZCMT) begin
         obi_memory_zcmt_cntxt         = uvma_obi_memory_cntxt_c::type_id::create("obi_memory_zcmt_cntxt");
      end
      if (RTLCVA6Cfg.MmuPresent) begin
         obi_memory_mmu_ptw_cntxt       = uvma_obi_memory_cntxt_c::type_id::create("obi_memory_mmu_ptw_cntxt");
      end
   end

   mem = uvml_mem_cva6::type_id::create("mem");
   mem_obi = uvml_mem_c::type_id::create("mem_obi");
   rvfi_cntxt         = uvma_rvfi_cntxt_c#()::type_id::create("rvfi_cntxt");
   interrupt_cntxt    = uvma_interrupt_cntxt_c::type_id::create("interrupt_cntxt");
   cvxif_cntxt        = uvma_cvxif_cntxt_c::type_id::create("cvxif_cntxt");

   sample_cfg_e   = new("sample_cfg_e"  );
   sample_cntxt_e = new("sample_cntxt_e");

   mem.mem_default = MEM_DEFAULT_0;
   mem_obi.mem_default = MEM_DEFAULT_0;

endfunction : new

`endif // __UVME_CVA6_CNTXT_SV__
