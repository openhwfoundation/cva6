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


`ifndef __UVME_CVA6_VSQR_SV__
`define __UVME_CVA6_VSQR_SV__


/**
 * Component on which all CVA6 virtual sequences are run.
 */
class uvme_cva6_vsqr_c extends uvm_sequencer#(
   .REQ(uvm_sequence_item),
   .RSP(uvm_sequence_item)
);

   // Objects
   uvme_cva6_cfg_c    cfg;
   uvme_cva6_cntxt_c  cntxt;

   // Sequencer handles
   uvma_clknrst_sqr_c     clknrst_sequencer;
   uvma_axi_vsqr_c        axi_vsequencer;
   uvma_interrupt_sqr_c   interrupt_sequencer;
   uvma_cvxif_vsqr_c      cvxif_vsequencer;
   uvma_obi_memory_sqr_c  obi_memory_instr_sequencer;
   uvma_obi_memory_sqr_c  obi_memory_store_sequencer;
   uvma_obi_memory_sqr_c  obi_memory_amo_sequencer;
   uvma_obi_memory_sqr_c  obi_memory_zcmt_sequencer;
   uvma_obi_memory_sqr_c  obi_memory_load_sequencer;
   uvma_obi_memory_sqr_c  obi_memory_mmu_ptw_sequencer;



   `uvm_component_utils_begin(uvme_cva6_vsqr_c)
      `uvm_field_object(cfg  , UVM_DEFAULT)
      `uvm_field_object(cntxt, UVM_DEFAULT)
   `uvm_component_utils_end


   /**
    * Default constructor.
    */
   extern function new(string name="uvme_cva6_sqr", uvm_component parent=null);

   /**
    * Ensures cfg & cntxt handles are not null.
    */
   extern virtual function void build_phase(uvm_phase phase);

endclass : uvme_cva6_vsqr_c


function uvme_cva6_vsqr_c::new(string name="uvme_cva6_sqr", uvm_component parent=null);

   super.new(name, parent);

endfunction : new


function void uvme_cva6_vsqr_c::build_phase(uvm_phase phase);

   super.build_phase(phase);

   void'(uvm_config_db#(uvme_cva6_cfg_c)::get(this, "", "cfg", cfg));
   if (!cfg) begin
      `uvm_fatal("CFG", "Configuration handle is null")
   end

   void'(uvm_config_db#(uvme_cva6_cntxt_c)::get(this, "", "cntxt", cntxt));
   if (!cntxt) begin
      `uvm_fatal("CNTXT", "Context handle is null")
   end

endfunction : build_phase


`endif // __UVME_CVA6_VSQR_SV__
