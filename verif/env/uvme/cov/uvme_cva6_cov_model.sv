//
// Copyright 2020 OpenHW Group
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


`ifndef __UVME_CVA6_COV_MODEL_SV__
`define __UVME_CVA6_COV_MODEL_SV__


/**
 * Component encapsulating CVA6 environment's functional coverage model.
 */
class uvme_cva6_cov_model_c extends uvm_component;

   // Objects
   uvme_cva6_cfg_c    cfg;
   uvme_cva6_cntxt_c  cntxt;

   // Components
   uvme_isa_cov_model_c              isa_covg;
   uvme_cva6_config_covg_c           config_covg;
   uvme_illegal_instr_cov_model_c    illegal_covg;
   uvme_exception_cov_model_c        exception_covg;
   uvme_axi_covg_c                   axi_covg;
   uvme_axi_ext_covg_c               axi_ext_covg;
   uvme_interrupt_covg_c             interrupt_covg;
   
   //
   uvm_analysis_export#(uvma_clknrst_mon_trn_c)  reset_export;

   `uvm_component_utils_begin(uvme_cva6_cov_model_c)
      `uvm_field_object(cfg  , UVM_DEFAULT)
      `uvm_field_object(cntxt, UVM_DEFAULT)
   `uvm_component_utils_end

   /**
    * Default constructor.
    */
   extern function new(string name="uvme_cva6_cov_model", uvm_component parent=null);

   /**
    * Ensures cfg & cntxt handles are not null.
    */
   extern virtual function void build_phase(uvm_phase phase);

   /**
    * Describe uvme_cva6_cov_model_c::run_phase()
    */
   extern virtual task run_phase(uvm_phase phase);

   /**
    * Ensures cfg & cntxt handles are not null.
    */
   extern virtual function void connect_phase(uvm_phase phase);

   /**
    * TODO Describe uvme_cva6_cov_model_c::sample_cfg()
    */
   extern virtual function void sample_cfg();

   /**
    * TODO Describe uvme_cva6_cov_model_c::sample_cntxt()
    */
   extern virtual function void sample_cntxt();

   // TODO Add coverage functions to uvme_cva6_cov_model_c

endclass : uvme_cva6_cov_model_c


function uvme_cva6_cov_model_c::new(string name="uvme_cva6_cov_model", uvm_component parent=null);

   super.new(name, parent);
   reset_export = new("reset_export");
endfunction : new

function void uvme_cva6_cov_model_c::build_phase(uvm_phase phase);

   super.build_phase(phase);

   void'(uvm_config_db#(uvme_cva6_cfg_c)::get(this, "", "cfg", cfg));
   if (!cfg) begin
      `uvm_fatal("CFG", "Configuration handle is null")
   end

   void'(uvm_config_db#(uvme_cva6_cntxt_c)::get(this, "", "cntxt", cntxt));
   if (!cntxt) begin
      `uvm_fatal("CNTXT", "Context handle is null")
   end

   if (cfg.isacov_cfg.cov_model_enabled) begin
      isa_covg = uvme_isa_cov_model_c::type_id::create("isa_covg", this);
      illegal_covg = uvme_illegal_instr_cov_model_c::type_id::create("illegal_covg", this);
      exception_covg = uvme_exception_cov_model_c::type_id::create("exception_covg", this);
      uvm_config_db#(uvme_cva6_cfg_c)::set(this, "isa_covg", "cfg", cfg);
      uvm_config_db#(uvme_cva6_cfg_c)::set(this, "illegal_covg", "cfg", cfg);
      uvm_config_db#(uvme_cva6_cfg_c)::set(this, "exception_covg", "cfg", cfg);
   end
   
   config_covg = uvme_cva6_config_covg_c::type_id::create("config_covg", this);
   uvm_config_db#(uvme_cva6_cfg_c)::set(this, "config_covg", "cfg", cfg);
   uvm_config_db#(uvme_cva6_cntxt_c)::set(this, "config_covg", "cntxt", cntxt);

   if (RTLCVA6Cfg.MemSubsystem != config_pkg::MEM_OBI) begin
      if(cfg.axi_cfg.cov_model_enabled) begin
         axi_covg   = uvme_axi_covg_c::type_id::create("axi_covg", this);
         axi_ext_covg   = uvme_axi_ext_covg_c::type_id::create("axi_ext_covg", this);
         uvm_config_db#(uvme_cva6_cfg_c)::set(this, "axi_covg", "cfg", cfg);
         uvm_config_db#(uvme_cva6_cntxt_c)::set(this, "axi_covg", "cntxt", cntxt);
         uvm_config_db#(uvme_cva6_cfg_c)::set(this, "axi_ext_covg", "cfg", cfg);
         uvm_config_db#(uvme_cva6_cntxt_c)::set(this, "axi_ext_covg", "cntxt", cntxt);
      end
   end

   if(cfg.interrupt_cfg.cov_model_enabled) begin
      interrupt_covg   = uvme_interrupt_covg_c::type_id::create("interrupt_covg", this);
      uvm_config_db#(uvme_cva6_cfg_c)::set(this, "interrupt_covg", "cfg", cfg);
      uvm_config_db#(uvme_cva6_cntxt_c)::set(this, "interrupt_covg", "cntxt", cntxt);
   end

endfunction : build_phase

function void uvme_cva6_cov_model_c::connect_phase(uvm_phase phase);

   super.connect_phase(phase);
   reset_export.connect(config_covg.reset_imp);

endfunction : connect_phase


task uvme_cva6_cov_model_c::run_phase(uvm_phase phase);

   super.run_phase(phase);

   fork
      // Configuration
      forever begin
         cntxt.sample_cfg_e.wait_trigger();
         sample_cfg();
      end

      // Context
      forever begin
         cntxt.sample_cntxt_e.wait_trigger();
         sample_cntxt();
      end

      // TODO Implement uvme_cva6_cov_model_c::run_phase()
      //      Ex: forever begin
      //             debug_fifo.get(debug_trn);
      //             sample_debug();
      //          end
   join_none

endtask : run_phase


function void uvme_cva6_cov_model_c::sample_cfg();

   // TODO Implement uvme_cva6_cov_model_c::sample_cfg();
   //      Ex: cva6_cfg_cg.sample();

endfunction : sample_cfg


function void uvme_cva6_cov_model_c::sample_cntxt();

   // TODO Implement uvme_cva6_cov_model_c::sample_cntxt();
   //      Ex: cva6_cntxt_cg.sample();

endfunction : sample_cntxt


`endif // __UVME_CVA6_COV_MODEL_SV__
