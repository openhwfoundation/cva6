//
// Copyright 2020 OpenHW Group
// Copyright 2023 Thales DIS
//
// Licensed under the Solderpad Hardware License, Version 2.0 (the "License");
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

covergroup cg_cva6_config(string name) with function sample(cva6_cfg_t CVA6Cfg);

   option.per_instance = 1;
   option.name = name;

   cp_Xlen : coverpoint CVA6Cfg.XLEN {
      bins Xlen ={32};
   }
   cp_RVF : coverpoint CVA6Cfg.RVF {
      bins RVF ={0};
   }
   cp_F16En : coverpoint CVA6Cfg.XF16 {
      bins F16En ={0};
   }
   cp_F16AltEn : coverpoint CVA6Cfg.XF16ALT {
      bins F16AltEn ={0};
   }
   cp_F8En : coverpoint CVA6Cfg.XF8 {
      bins F8En ={0};
   }
   cp_FVecEn : coverpoint CVA6Cfg.XFVec {
      bins FVecEn ={0};
   }
   cp_CvxifEn : coverpoint CVA6Cfg.CvxifEn {
      bins CvxifEn ={1};
   }
   cp_CExtEn : coverpoint CVA6Cfg.RVC {
      bins CExtEn ={1};
   }
   cp_AExtEn : coverpoint CVA6Cfg.RVA {
      bins AExtEn ={0};
   }
   cp_BExtEn : coverpoint CVA6Cfg.RVB {
      bins BExtEn ={1};
   }
   cp_VExtEn : coverpoint CVA6Cfg.RVV {
      bins VExtEn ={0};
   }
   cp_RVZiCond : coverpoint CVA6Cfg.RVZiCond {
      bins RVZiCond ={0};
   }
   cp_AxiIdWidth : coverpoint CVA6Cfg.AxiIdWidth {
      bins AxiIdWidth ={4};
   }
   cp_AxiAddrWidth : coverpoint CVA6Cfg.AxiAddrWidth {
      bins AxiAddrWidth ={64};
   }
   cp_AxiDataWidth : coverpoint CVA6Cfg.AxiDataWidth {
      bins AxiDataWidth ={64};
   }
   cp_FetchUserEn : coverpoint CVA6Cfg.FETCH_USER_EN {
      bins FetchUserEn ={0};
   }
   cp_FetchUserWidth : coverpoint CVA6Cfg.FETCH_USER_WIDTH {
      bins FetchUserWidth ={32};
   }
   cp_DataUserEn : coverpoint CVA6Cfg.DATA_USER_EN {
      bins DataUserEn ={0};
   }
   cp_IcacheSetAssoc : coverpoint CVA6Cfg.ICACHE_SET_ASSOC {
      bins IcacheSetAssoc ={2};
   }
   cp_IcacheLineWidth : coverpoint CVA6Cfg.ICACHE_LINE_WIDTH {
      bins IcacheLineWidth ={128};
   }
   cp_DcacheSetAssoc : coverpoint CVA6Cfg.DCACHE_SET_ASSOC {
      bins DcacheSetAssoc ={8};
   }
   cp_DcacheLineWidth : coverpoint CVA6Cfg.DCACHE_LINE_WIDTH {
      bins DcacheLineWidth ={128};
   }
   cp_NrCommitPorts : coverpoint CVA6Cfg.NrCommitPorts {
      bins NrCommitPorts ={1};
   }
   cp_FpgaEn : coverpoint CVA6Cfg.FpgaEn {
      bins FpgaEn ={0};
   }
   cp_NrLoadBufEntries : coverpoint CVA6Cfg.NrLoadBufEntries {
      bins NrLoadBufEntries ={2};
   }
   cp_RASDepth : coverpoint CVA6Cfg.RASDepth {
      bins RASDepth ={2};
   }
   cp_BTBEntries : coverpoint CVA6Cfg.BTBEntries {
      bins BTBEntries ={0};
   }
   cp_BHTEntries : coverpoint CVA6Cfg.BHTEntries {
      bins BHTEntries ={32};
   }
   cp_NrPMPEntries : coverpoint CVA6Cfg.NrPMPEntries {
      bins NrPMPEntries ={8};
   }
   cp_HaltAddress : coverpoint CVA6Cfg.HaltAddress {
      bins HaltAddress ={64'h800};
   }
   cp_ExceptionAddress : coverpoint CVA6Cfg.ExceptionAddress {
      bins ExceptionAddress ={64'h810};
   }
endgroup: cg_cva6_config

covergroup cg_cva6_boot_addr(string name) with function sample(uvme_cva6_cfg_c cfg);
   option.per_instance = 1;
   option.name = name;
   
   cp_boot_addr : coverpoint cfg.boot_addr {
      bins BOOT_ADDR_0 ={0};
      bins BOOT_ADDR_LOW ={[1:'h10000_0000]};
      bins BOOT_ADDR_HIGH ={['h10000_0000:$]};
   }
endgroup: cg_cva6_boot_addr

covergroup cg_cva6_clock_period_cg(string name) with function sample(int clock_period_ps);
   option.per_instance = 1;
   option.name = name;
   
   cp_clock_period_ps : coverpoint clock_period_ps {
      bins LOW   = {[0:1500]};
      bins HIGH  = {[1501:6670]};
   }
endgroup: cg_cva6_clock_period_cg

covergroup cg_cva6_reset_cg(string name,int clock_period_ps) with function sample(uvma_clknrst_mon_trn_c trn);
   option.per_instance = 1;
   option.name = name;
   
   cp_reset : coverpoint trn.event_type {
      bins ASSERTED   = {UVMA_CLKNRST_MON_TRN_EVENT_RESET_ASSERTED};
      bins DEASSERTED = {UVMA_CLKNRST_MON_TRN_EVENT_RESET_DEASSERTED};
   }

   cp_reset_duration_ps : coverpoint int'(trn.reset_pulse_length/1ps) iff(trn.event_type == UVMA_CLKNRST_MON_TRN_EVENT_RESET_DEASSERTED) {
      bins SHORT = {[0:clock_period_ps]};
      bins LONG  = {[clock_period_ps+1:$]};
   }

   cp_reset_onthefly_assert : coverpoint trn.event_type {
      bins onthefly_assert   = (UVMA_CLKNRST_MON_TRN_EVENT_RESET_DEASSERTED=>UVMA_CLKNRST_MON_TRN_EVENT_RESET_ASSERTED=>UVMA_CLKNRST_MON_TRN_EVENT_RESET_DEASSERTED);
   }

endgroup: cg_cva6_reset_cg

class uvme_cva6_config_covg_c extends uvm_component;

   // Objects
   uvme_cva6_cfg_c         cfg      ;
   uvme_cva6_cntxt_c       cntxt    ;

   `uvm_analysis_imp_decl(_reset)
   uvm_analysis_imp_reset #(uvma_clknrst_mon_trn_c, uvme_cva6_config_covg_c) reset_imp;
   
   `uvm_component_utils_begin(uvme_cva6_config_covg_c)
      `uvm_field_object(cfg  , UVM_DEFAULT)
      `uvm_field_object(cntxt, UVM_DEFAULT)
   `uvm_component_utils_end

   // Covergroups
   cg_cva6_config          config_cg;
   cg_cva6_boot_addr       boot_addr_cg;
   cg_cva6_clock_period_cg clock_period_cg;
   cg_cva6_reset_cg        reset_cg;
   
   extern function new(string name = "uvme_cva6_config_covg_c", uvm_component parent = null);
   extern function void build_phase(uvm_phase phase);
   extern task run_phase(uvm_phase phase);
   extern function void sample_cva6_config();
   extern function void write_reset(uvma_clknrst_mon_trn_c trn);

endclass : uvme_cva6_config_covg_c

function uvme_cva6_config_covg_c::new(string name = "uvme_cva6_config_covg_c", uvm_component parent = null);

   super.new(name, parent);
   reset_imp = new("rest_imp", this);
endfunction : new

function void uvme_cva6_config_covg_c::build_phase(uvm_phase phase);

   super.build_phase(phase);

   void'(uvm_config_db#(uvme_cva6_cfg_c)::get(this, "", "cfg", cfg));
   if (!cfg) begin
      `uvm_fatal("CFG", "Configuration handle is null")
   end

   void'(uvm_config_db#(uvme_cva6_cntxt_c)::get(this, "", "cntxt", cntxt));
   if (!cntxt) begin
      `uvm_fatal("CNTXT", "Context handle is null")
   end

   config_cg       = new("config_cg");
   boot_addr_cg    = new("boot_addr_cg");
   clock_period_cg = new("clock_period_cg");
   reset_cg        = new("reset_cg",cfg.sys_clk_period);
   
endfunction : build_phase

function void uvme_cva6_config_covg_c::sample_cva6_config();

   config_cg.sample(RTLCVA6Cfg);
   boot_addr_cg.sample(cfg);
   clock_period_cg.sample(cfg.sys_clk_period);
   
endfunction : sample_cva6_config

function void uvme_cva6_config_covg_c::write_reset(uvma_clknrst_mon_trn_c trn);

   reset_cg.sample(trn); 

endfunction

task uvme_cva6_config_covg_c::run_phase(uvm_phase phase);

   super.run_phase(phase);
   
   sample_cva6_config();

endtask : run_phase
