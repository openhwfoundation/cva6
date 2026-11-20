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


`ifndef __UVME_CVA6_CFG_SV__
`define __UVME_CVA6_CFG_SV__


/**
 * Object encapsulating all parameters for creating, connecting and running
 * CVA6 environment (uvme_cva6_env_c) components.
 */
class uvme_cva6_cfg_c extends uvma_core_cntrl_cfg_c;

   // Integrals
   rand bit                      enabled;

   rand bit                      scoreboard_enabled;
   rand bit                      tandem_enabled;
   rand bit                      cov_model_enabled;
   rand bit                      trn_log_enabled;
   rand bit                      force_disable_csr_checks; // force disable all csr checks in RVFI. Note that all csrs info in instruction from RVFI will be removed
   rand int unsigned             sys_clk_period;

   bit                           performance_mode; // Will force disable coverage, csr checks, scoreboard and loggers

   // Agent cfg handles
   rand uvma_clknrst_cfg_c                clknrst_cfg;
   rand uvma_axi_cfg_c                    axi_cfg;

   rand uvma_obi_memory_cfg_c       obi_memory_instr_cfg;
   rand uvma_obi_memory_cfg_c       obi_memory_store_cfg;
   rand uvma_obi_memory_cfg_c       obi_memory_amo_cfg;
   rand uvma_obi_memory_cfg_c       obi_memory_load_cfg;
   rand uvma_obi_memory_cfg_c       obi_memory_zcmt_cfg;
   rand uvma_obi_memory_cfg_c       obi_memory_mmu_ptw_cfg;

   rand uvma_rvfi_cfg_c#(ILEN,XLEN)       rvfi_cfg;
   rand uvma_isacov_cfg_c                 isacov_cfg;
   rand uvma_interrupt_cfg_c              interrupt_cfg;
   rand uvma_cvxif_cfg_c                  cvxif_cfg;

   // Zicond extension
   rand bit                      ext_zicond_supported;

   // pmp entries
   rand int                      nr_pmp_entries;

   // Zihpm extension
   rand bit                      ext_zihpm_supported;

   // MMU support
   rand bit                      MmuPresent;

   // Software interrupt supported
   rand bit                      sw_int_supported;

   //OBI stall gnt and rvalid
   rand bit                      zero_obi_stall;

   `uvm_object_utils_begin(uvme_cva6_cfg_c)
      `uvm_field_int (                         enabled                     , UVM_DEFAULT          )
      `uvm_field_enum(uvm_active_passive_enum, is_active                   , UVM_DEFAULT          )
      `uvm_field_int (                         scoreboard_enabled          , UVM_DEFAULT          )
      `uvm_field_int (                         tandem_enabled              , UVM_DEFAULT          )
      `uvm_field_int (                         cov_model_enabled           , UVM_DEFAULT          )
      `uvm_field_int (                         trn_log_enabled             , UVM_DEFAULT          )
      `uvm_field_int (                         force_disable_csr_checks    , UVM_DEFAULT          )
      `uvm_field_int (                         ext_zicond_supported        , UVM_DEFAULT          )
      `uvm_field_int (                         nr_pmp_entries              , UVM_DEFAULT          )
      `uvm_field_int (                         ext_zihpm_supported         , UVM_DEFAULT          )
      `uvm_field_int (                         MmuPresent                  , UVM_DEFAULT          )
      `uvm_field_int (                         sw_int_supported            , UVM_DEFAULT          )
      `uvm_field_int (                         zero_obi_stall              , UVM_DEFAULT          )
      `uvm_field_int (                         sys_clk_period            , UVM_DEFAULT + UVM_DEC)
      `uvm_field_int (                         performance_mode            , UVM_DEFAULT          )

      `uvm_field_object(clknrst_cfg, UVM_DEFAULT)

      `uvm_field_object(axi_cfg, UVM_DEFAULT)

      `uvm_field_object(obi_memory_instr_cfg, UVM_DEFAULT)
      `uvm_field_object(obi_memory_store_cfg, UVM_DEFAULT)
      `uvm_field_object(obi_memory_amo_cfg, UVM_DEFAULT)
      `uvm_field_object(obi_memory_load_cfg, UVM_DEFAULT)
      `uvm_field_object(obi_memory_zcmt_cfg, UVM_DEFAULT)
      `uvm_field_object(obi_memory_mmu_ptw_cfg, UVM_DEFAULT)

      // TODO:`uvm_field_object(obi_memory_data_cfg, UVM_DEFAULT)

      `uvm_field_object(rvfi_cfg,    UVM_DEFAULT)

      `uvm_field_object(isacov_cfg,  UVM_DEFAULT)

      `uvm_field_object(interrupt_cfg,  UVM_DEFAULT)

      `uvm_field_object(cvxif_cfg,  UVM_DEFAULT)

   `uvm_object_utils_end


   constraint defaults_cons {
      soft enabled                 == 1;
      soft is_active               == UVM_ACTIVE;
      soft scoreboard_enabled      == 1;
      soft cov_model_enabled       == 1;
      soft trn_log_enabled         == 1;
      soft force_disable_csr_checks == 0;
      soft sys_clk_period          == uvme_cva6_sys_default_clk_period; // see uvme_cva6_constants.sv
   }

   constraint cva6_riscv_cons {
      xlen == RTLCVA6Cfg.XLEN;

      ext_zihpm_supported    == 0;
      ext_zicond_supported   == RTLCVA6Cfg.RVZiCond;

      nr_pmp_entries         == RTLCVA6Cfg.NrPMPEntries;

      unaligned_access_supported     == 0;
      unaligned_access_amo_supported == 0;

      bitmanip_version        == BITMANIP_VERSION_1P00;
      priv_spec_version       == PRIV_VERSION_MASTER;
      endianness              == ENDIAN_LITTLE;

      boot_addr_valid         == 1;
      mtvec_addr_valid        == 1;
      dm_halt_addr_valid      == 1;
      dm_exception_addr_valid == 1;
      nmi_addr_valid          == 1;

      MmuPresent              == RTLCVA6Cfg.MmuPresent;
      sw_int_supported        == RTLCVA6Cfg.SoftwareInterruptEn;
   }

   constraint ext_const {
      if (!ext_c_supported) {
         ext_zcb_supported == 0;
      }
   }

   constraint pmp_const {
      if (!pmp_supported) {
         nr_pmp_entries == 0;
      }
      else {
         //  NrPMPEntries is free-form in the RTL configuration, 8 among others,
         //  so the count is taken from it rather than from a fixed list.
         nr_pmp_entries inside {[0:64]};
      }
   }

   constraint default_cva6_boot_cons {
      (!boot_addr_plusarg_valid)         -> (boot_addr         == 'h8000_0000);
   }

   constraint default_cons {
      if (interrupt_cfg.interrupt_plusarg_valid) {
         interrupt_cfg.enable_interrupt == 'h1;
         zero_obi_stall                 == 'h1;
      }
      else {
         interrupt_cfg.enable_interrupt == 'h0;
      }

      if (cvxif_cfg.cvxif_plusarg_valid) {
         cvxif_cfg.enabled_cvxif == 'h1;
      }
      else {
         cvxif_cfg.enabled_cvxif == 'h0;
      }
   }

   constraint mem_sel_cons {
      if (RTLCVA6Cfg.MemSubsystem != config_pkg::MEM_OBI) {
         interrupt_cfg.mem_axi_sel == 1;
         interrupt_cfg.mem_obi_sel == 0;
      } else {
         interrupt_cfg.mem_axi_sel == 0;
         interrupt_cfg.mem_obi_sel == 1;
      }
   }

   constraint obi_zero_stall_dist_cons {
      zero_obi_stall dist { 0 :/ 9,  1 :/ 1};
   }

   constraint zero_stall_sim_cons {
      if (zero_obi_stall) {
         obi_memory_instr_cfg.drv_slv_gnt_mode    == UVMA_OBI_MEMORY_DRV_SLV_GNT_MODE_CONSTANT;
         obi_memory_instr_cfg.drv_slv_rvalid_mode == UVMA_OBI_MEMORY_DRV_SLV_RVALID_MODE_CONSTANT;

         obi_memory_store_cfg.drv_slv_gnt_mode    == UVMA_OBI_MEMORY_DRV_SLV_GNT_MODE_CONSTANT;
         obi_memory_store_cfg.drv_slv_rvalid_mode == UVMA_OBI_MEMORY_DRV_SLV_RVALID_MODE_CONSTANT;

         obi_memory_amo_cfg.drv_slv_gnt_mode      == UVMA_OBI_MEMORY_DRV_SLV_GNT_MODE_CONSTANT;
         obi_memory_amo_cfg.drv_slv_rvalid_mode   == UVMA_OBI_MEMORY_DRV_SLV_RVALID_MODE_CONSTANT;

         obi_memory_load_cfg.drv_slv_gnt_mode     == UVMA_OBI_MEMORY_DRV_SLV_GNT_MODE_CONSTANT;
         obi_memory_load_cfg.drv_slv_rvalid_mode  == UVMA_OBI_MEMORY_DRV_SLV_RVALID_MODE_CONSTANT;
         
         obi_memory_zcmt_cfg.drv_slv_gnt_mode     == UVMA_OBI_MEMORY_DRV_SLV_GNT_MODE_CONSTANT;
         obi_memory_zcmt_cfg.drv_slv_rvalid_mode  == UVMA_OBI_MEMORY_DRV_SLV_RVALID_MODE_CONSTANT;
         
         obi_memory_mmu_ptw_cfg.drv_slv_gnt_mode    == UVMA_OBI_MEMORY_DRV_SLV_GNT_MODE_CONSTANT;
         obi_memory_mmu_ptw_cfg.drv_slv_rvalid_mode == UVMA_OBI_MEMORY_DRV_SLV_RVALID_MODE_CONSTANT;
      }
     else {
         obi_memory_instr_cfg.drv_slv_gnt_mode    != UVMA_OBI_MEMORY_DRV_SLV_GNT_MODE_CONSTANT;
         obi_memory_instr_cfg.drv_slv_rvalid_mode != UVMA_OBI_MEMORY_DRV_SLV_RVALID_MODE_CONSTANT;

         obi_memory_store_cfg.drv_slv_gnt_mode    != UVMA_OBI_MEMORY_DRV_SLV_GNT_MODE_CONSTANT;
         obi_memory_store_cfg.drv_slv_rvalid_mode != UVMA_OBI_MEMORY_DRV_SLV_RVALID_MODE_CONSTANT;

         obi_memory_amo_cfg.drv_slv_gnt_mode      != UVMA_OBI_MEMORY_DRV_SLV_GNT_MODE_CONSTANT;
         obi_memory_amo_cfg.drv_slv_rvalid_mode   != UVMA_OBI_MEMORY_DRV_SLV_RVALID_MODE_CONSTANT;

         obi_memory_load_cfg.drv_slv_gnt_mode     != UVMA_OBI_MEMORY_DRV_SLV_GNT_MODE_CONSTANT;
         obi_memory_load_cfg.drv_slv_rvalid_mode  != UVMA_OBI_MEMORY_DRV_SLV_RVALID_MODE_CONSTANT;
         
         obi_memory_zcmt_cfg.drv_slv_gnt_mode     != UVMA_OBI_MEMORY_DRV_SLV_GNT_MODE_CONSTANT;
         obi_memory_zcmt_cfg.drv_slv_rvalid_mode  != UVMA_OBI_MEMORY_DRV_SLV_RVALID_MODE_CONSTANT;

         obi_memory_mmu_ptw_cfg.drv_slv_gnt_mode    != UVMA_OBI_MEMORY_DRV_SLV_GNT_MODE_CONSTANT;
         obi_memory_mmu_ptw_cfg.drv_slv_rvalid_mode != UVMA_OBI_MEMORY_DRV_SLV_RVALID_MODE_CONSTANT;
      }
   }

   constraint agent_cfg_cons {
      if (enabled) {
         clknrst_cfg.enabled    == 1;
         isacov_cfg.enabled     == 1;
         rvfi_cfg.enabled       == 1;
         interrupt_cfg.enabled  == 1;
      }

      isacov_cfg.seq_instr_group_x2_enabled == 1;
      isacov_cfg.seq_instr_group_x3_enabled == 0;
      isacov_cfg.seq_instr_group_x4_enabled == 0;
      isacov_cfg.seq_instr_x2_enabled       == 1;
      isacov_cfg.reg_crosses_enabled        == 0;
      isacov_cfg.reg_hazards_enabled        == 1;
      rvfi_cfg.nret                         == RTLCVA6Cfg.NrCommitPorts;
      unified_traps                         == 0;
      axi_cfg.zero_delay_mode               == 1;
      axi_cfg.disable_trs_randomization     == 1;

      obi_memory_instr_cfg.drv_mode                      == UVMA_OBI_MEMORY_MODE_SLV;
      obi_memory_instr_cfg.version                       == UVMA_OBI_MEMORY_VERSION_1P2;
      obi_memory_instr_cfg.auser_width                   == RTLCVA6Cfg.ObiFetchbusCfg.OptionalCfg.AUserWidth;
      obi_memory_instr_cfg.wuser_width                   == RTLCVA6Cfg.ObiFetchbusCfg.OptionalCfg.WUserWidth;
      obi_memory_instr_cfg.ruser_width                   == RTLCVA6Cfg.ObiFetchbusCfg.OptionalCfg.RUserWidth;
      obi_memory_instr_cfg.addr_width                    == RTLCVA6Cfg.ObiFetchbusCfg.AddrWidth ;
      obi_memory_instr_cfg.data_width                    == RTLCVA6Cfg.ObiFetchbusCfg.DataWidth ;
      obi_memory_instr_cfg.id_width                      == RTLCVA6Cfg.ObiFetchbusCfg.IdWidth   ;
      obi_memory_instr_cfg.achk_width                    == RTLCVA6Cfg.ObiFetchbusCfg.OptionalCfg.AChkWidth ;
      obi_memory_instr_cfg.rchk_width                    == RTLCVA6Cfg.ObiFetchbusCfg.OptionalCfg.RChkWidth ;

      obi_memory_store_cfg.drv_mode                      == UVMA_OBI_MEMORY_MODE_SLV;
      obi_memory_store_cfg.version                       == UVMA_OBI_MEMORY_VERSION_1P2;
      obi_memory_store_cfg.auser_width                   == RTLCVA6Cfg.ObiStorebusCfg.OptionalCfg.AUserWidth;
      obi_memory_store_cfg.wuser_width                   == RTLCVA6Cfg.ObiStorebusCfg.OptionalCfg.WUserWidth;
      obi_memory_store_cfg.ruser_width                   == RTLCVA6Cfg.ObiStorebusCfg.OptionalCfg.RUserWidth;
      obi_memory_store_cfg.addr_width                    == RTLCVA6Cfg.ObiStorebusCfg.AddrWidth ;
      obi_memory_store_cfg.data_width                    == RTLCVA6Cfg.ObiStorebusCfg.DataWidth ;
      obi_memory_store_cfg.id_width                      == RTLCVA6Cfg.ObiStorebusCfg.IdWidth   ;
      obi_memory_store_cfg.achk_width                    == RTLCVA6Cfg.ObiStorebusCfg.OptionalCfg.AChkWidth ;
      obi_memory_store_cfg.rchk_width                    == RTLCVA6Cfg.ObiStorebusCfg.OptionalCfg.RChkWidth ;

      obi_memory_amo_cfg.drv_mode                        == UVMA_OBI_MEMORY_MODE_SLV;
      obi_memory_amo_cfg.version                         == UVMA_OBI_MEMORY_VERSION_1P2;
      obi_memory_amo_cfg.auser_width                     == RTLCVA6Cfg.ObiAmobusCfg.OptionalCfg.AUserWidth;
      obi_memory_amo_cfg.wuser_width                     == RTLCVA6Cfg.ObiAmobusCfg.OptionalCfg.WUserWidth;
      obi_memory_amo_cfg.ruser_width                     == RTLCVA6Cfg.ObiAmobusCfg.OptionalCfg.RUserWidth;
      obi_memory_amo_cfg.addr_width                      == RTLCVA6Cfg.ObiAmobusCfg.AddrWidth ;
      obi_memory_amo_cfg.data_width                      == RTLCVA6Cfg.ObiAmobusCfg.DataWidth ;
      obi_memory_amo_cfg.id_width                        == RTLCVA6Cfg.ObiAmobusCfg.IdWidth   ;
      obi_memory_amo_cfg.achk_width                      == RTLCVA6Cfg.ObiAmobusCfg.OptionalCfg.AChkWidth ;
      obi_memory_amo_cfg.rchk_width                      == RTLCVA6Cfg.ObiAmobusCfg.OptionalCfg.RChkWidth ;
      
      
      obi_memory_zcmt_cfg.drv_mode                        == UVMA_OBI_MEMORY_MODE_SLV;
      obi_memory_zcmt_cfg.version                         == UVMA_OBI_MEMORY_VERSION_1P2;
      obi_memory_zcmt_cfg.auser_width                     == RTLCVA6Cfg.ObiZcmtbusCfg.OptionalCfg.AUserWidth;
      obi_memory_zcmt_cfg.wuser_width                     == RTLCVA6Cfg.ObiZcmtbusCfg.OptionalCfg.WUserWidth;
      obi_memory_zcmt_cfg.ruser_width                     == RTLCVA6Cfg.ObiZcmtbusCfg.OptionalCfg.RUserWidth;
      obi_memory_zcmt_cfg.addr_width                      == RTLCVA6Cfg.ObiZcmtbusCfg.AddrWidth ;
      obi_memory_zcmt_cfg.data_width                      == RTLCVA6Cfg.ObiZcmtbusCfg.DataWidth ;
      obi_memory_zcmt_cfg.id_width                        == RTLCVA6Cfg.ObiZcmtbusCfg.IdWidth   ;
      obi_memory_zcmt_cfg.achk_width                      == RTLCVA6Cfg.ObiZcmtbusCfg.OptionalCfg.AChkWidth ;
      obi_memory_zcmt_cfg.rchk_width                      == RTLCVA6Cfg.ObiZcmtbusCfg.OptionalCfg.RChkWidth ;

      obi_memory_load_cfg.drv_mode                      == UVMA_OBI_MEMORY_MODE_SLV;
      obi_memory_load_cfg.version                       == UVMA_OBI_MEMORY_VERSION_1P2;
      obi_memory_load_cfg.auser_width                   == RTLCVA6Cfg.ObiLoadbusCfg.OptionalCfg.AUserWidth;
      obi_memory_load_cfg.wuser_width                   == RTLCVA6Cfg.ObiLoadbusCfg.OptionalCfg.WUserWidth;
      obi_memory_load_cfg.ruser_width                   == RTLCVA6Cfg.ObiLoadbusCfg.OptionalCfg.RUserWidth;
      obi_memory_load_cfg.addr_width                    == RTLCVA6Cfg.ObiLoadbusCfg.AddrWidth ;
      obi_memory_load_cfg.data_width                    == RTLCVA6Cfg.ObiLoadbusCfg.DataWidth ;
      obi_memory_load_cfg.id_width                      == RTLCVA6Cfg.ObiLoadbusCfg.IdWidth   ;
      obi_memory_load_cfg.achk_width                    == RTLCVA6Cfg.ObiLoadbusCfg.OptionalCfg.AChkWidth ;
      obi_memory_load_cfg.rchk_width                    == RTLCVA6Cfg.ObiLoadbusCfg.OptionalCfg.RChkWidth ;

      obi_memory_mmu_ptw_cfg.drv_mode                   == UVMA_OBI_MEMORY_MODE_SLV;
      obi_memory_mmu_ptw_cfg.version                    == UVMA_OBI_MEMORY_VERSION_1P2;
      obi_memory_mmu_ptw_cfg.auser_width                == RTLCVA6Cfg.ObiMmuPtwbusCfg.OptionalCfg.AUserWidth;
      obi_memory_mmu_ptw_cfg.wuser_width                == RTLCVA6Cfg.ObiMmuPtwbusCfg.OptionalCfg.WUserWidth;
      obi_memory_mmu_ptw_cfg.ruser_width                == RTLCVA6Cfg.ObiMmuPtwbusCfg.OptionalCfg.RUserWidth;
      obi_memory_mmu_ptw_cfg.addr_width                 == RTLCVA6Cfg.ObiMmuPtwbusCfg.AddrWidth ;
      obi_memory_mmu_ptw_cfg.data_width                 == RTLCVA6Cfg.ObiMmuPtwbusCfg.DataWidth ;
      obi_memory_mmu_ptw_cfg.id_width                   == RTLCVA6Cfg.ObiMmuPtwbusCfg.IdWidth   ;
      obi_memory_mmu_ptw_cfg.achk_width                 == RTLCVA6Cfg.ObiMmuPtwbusCfg.OptionalCfg.AChkWidth ;
      obi_memory_mmu_ptw_cfg.rchk_width                 == RTLCVA6Cfg.ObiMmuPtwbusCfg.OptionalCfg.RChkWidth ;

      soft obi_memory_instr_cfg.drv_slv_gnt_random_latency_min     == 2;
      soft obi_memory_instr_cfg.drv_slv_gnt_random_latency_max     == 5;
      soft obi_memory_instr_cfg.drv_slv_gnt_fixed_latency          <= 5;
      soft obi_memory_instr_cfg.drv_slv_rvalid_random_latency_min  == 2;
      soft obi_memory_instr_cfg.drv_slv_rvalid_random_latency_max  == 5;
      soft obi_memory_instr_cfg.drv_slv_rvalid_fixed_latency       <= 5;

      soft obi_memory_store_cfg.drv_slv_gnt_random_latency_min     == 2;
      soft obi_memory_store_cfg.drv_slv_gnt_random_latency_max     == 5;
      soft obi_memory_store_cfg.drv_slv_gnt_fixed_latency          <= 5;
      soft obi_memory_store_cfg.drv_slv_rvalid_random_latency_min  == 2;
      soft obi_memory_store_cfg.drv_slv_rvalid_random_latency_max  == 5;
      soft obi_memory_store_cfg.drv_slv_rvalid_fixed_latency       <= 5;

      soft obi_memory_amo_cfg.drv_slv_gnt_random_latency_min       == 2;
      soft obi_memory_amo_cfg.drv_slv_gnt_random_latency_max       == 5;
      soft obi_memory_amo_cfg.drv_slv_gnt_fixed_latency            <= 5;
      soft obi_memory_amo_cfg.drv_slv_rvalid_random_latency_min    == 2;
      soft obi_memory_amo_cfg.drv_slv_rvalid_random_latency_max    == 5;
      soft obi_memory_amo_cfg.drv_slv_rvalid_fixed_latency         <= 5;

      soft obi_memory_load_cfg.drv_slv_gnt_random_latency_min      == 2;
      soft obi_memory_load_cfg.drv_slv_gnt_random_latency_max      == 5;
      soft obi_memory_load_cfg.drv_slv_gnt_fixed_latency           <= 5;
      soft obi_memory_load_cfg.drv_slv_rvalid_random_latency_min   == 2;
      soft obi_memory_load_cfg.drv_slv_rvalid_random_latency_max   == 5;
      soft obi_memory_load_cfg.drv_slv_rvalid_fixed_latency        <= 5;
      
      
      soft obi_memory_zcmt_cfg.drv_slv_gnt_random_latency_min      == 2;
      soft obi_memory_zcmt_cfg.drv_slv_gnt_random_latency_max      == 5;
      soft obi_memory_zcmt_cfg.drv_slv_gnt_fixed_latency           <= 5;
      soft obi_memory_zcmt_cfg.drv_slv_rvalid_random_latency_min   == 2;
      soft obi_memory_zcmt_cfg.drv_slv_rvalid_random_latency_max   == 5;
      soft obi_memory_zcmt_cfg.drv_slv_rvalid_fixed_latency        <= 5;
      soft obi_memory_mmu_ptw_cfg.drv_slv_gnt_random_latency_min      <= 0;
      soft obi_memory_mmu_ptw_cfg.drv_slv_gnt_random_latency_max      <= 10;
      soft obi_memory_mmu_ptw_cfg.drv_slv_gnt_fixed_latency          <= 2;
      soft obi_memory_mmu_ptw_cfg.drv_slv_rvalid_random_latency_min   <= 0;
      soft obi_memory_mmu_ptw_cfg.drv_slv_rvalid_random_latency_max   <= 10;
      soft obi_memory_mmu_ptw_cfg.drv_slv_rvalid_fixed_latency       <= 3;

      if (is_active == UVM_ACTIVE) {
         clknrst_cfg.is_active        == UVM_ACTIVE;
         isacov_cfg.is_active         == UVM_PASSIVE;
         rvfi_cfg.is_active           == UVM_PASSIVE;
         interrupt_cfg.is_active      == UVM_ACTIVE;

         if (RTLCVA6Cfg.MemSubsystem == config_pkg::MEM_OBI) {
            obi_memory_instr_cfg.is_active == UVM_ACTIVE;
            obi_memory_store_cfg.is_active == UVM_ACTIVE;
            obi_memory_amo_cfg.is_active == UVM_ACTIVE;
            obi_memory_load_cfg.is_active == UVM_ACTIVE;
            obi_memory_zcmt_cfg.is_active == UVM_ACTIVE;
            obi_memory_mmu_ptw_cfg.is_active == UVM_ACTIVE;
         } else {
            obi_memory_instr_cfg.is_active == UVM_PASSIVE;
            obi_memory_store_cfg.is_active == UVM_PASSIVE;
            obi_memory_amo_cfg.is_active  == UVM_PASSIVE;
            obi_memory_zcmt_cfg.is_active == UVM_PASSIVE;
            obi_memory_load_cfg.is_active == UVM_PASSIVE;
            obi_memory_mmu_ptw_cfg.is_active == UVM_PASSIVE;
         }
      }

      if (trn_log_enabled) {
         clknrst_cfg.trn_log_enabled   == 0;
         axi_cfg.trn_log_enabled       == 1;
         obi_memory_instr_cfg.trn_log_enabled     == 1;
         obi_memory_store_cfg.trn_log_enabled     == 1;
         obi_memory_zcmt_cfg.trn_log_enabled      == 1;
         obi_memory_amo_cfg.trn_log_enabled       == 1;
         obi_memory_load_cfg.trn_log_enabled      == 1;
         obi_memory_mmu_ptw_cfg.trn_log_enabled   == 1;
         obi_memory_mmu_ptw_cfg.trn_log_enabled   == 1;
         rvfi_cfg.trn_log_enabled      == 1;
         isacov_cfg.trn_log_enabled    == 1;
      } else {
         clknrst_cfg.trn_log_enabled   == 0;
         axi_cfg.trn_log_enabled       == 0;
         obi_memory_instr_cfg.trn_log_enabled     == 0;
         obi_memory_store_cfg.trn_log_enabled     == 0;
         obi_memory_amo_cfg.trn_log_enabled       == 0;
         obi_memory_zcmt_cfg.trn_log_enabled      == 0;
         obi_memory_load_cfg.trn_log_enabled      == 0;
         obi_memory_mmu_ptw_cfg.trn_log_enabled   == 0;
         rvfi_cfg.trn_log_enabled      == 0;
         isacov_cfg.trn_log_enabled    == 0;
      }

      if (cov_model_enabled) {
         isacov_cfg.cov_model_enabled    == 1;
         axi_cfg.cov_model_enabled       == 1;
         obi_memory_instr_cfg.cov_model_enabled == 1;
         obi_memory_store_cfg.cov_model_enabled == 1;
         if (ext_a_supported) {
            obi_memory_amo_cfg.cov_model_enabled == 1;
         } else {
            obi_memory_amo_cfg.cov_model_enabled == 0;
         }
        // if (ext_zcmt_supported) {
        //    obi_memory_zcmt_cfg.cov_model_enabled == 1;
        // } else {
        //    obi_memory_zcmt_cfg.cov_model_enabled == 0;
        // }
         obi_memory_load_cfg.cov_model_enabled == 1;
         obi_memory_mmu_ptw_cfg.cov_model_enabled == 1;
         interrupt_cfg.cov_model_enabled == 1;
      } else {
         isacov_cfg.cov_model_enabled    == 0;
         axi_cfg.cov_model_enabled       == 0;
         obi_memory_instr_cfg.cov_model_enabled == 0;
         obi_memory_store_cfg.cov_model_enabled == 0;
         obi_memory_amo_cfg.cov_model_enabled == 0;
         obi_memory_load_cfg.cov_model_enabled == 0;
         obi_memory_mmu_ptw_cfg.cov_model_enabled == 0;
         interrupt_cfg.cov_model_enabled == 0;
      }

   }

   /**
    * Creates sub-configuration objects.
    */
   extern function new(string name="uvme_cva6_cfg");

      /**
    * Sample the parameters of the DUT via the virtual interface in a context
    */
   extern virtual function void sample_parameters(uvma_core_cntrl_cntxt_c cntxt);

   /**
    * Set unsupported_csr_mask based on extensions/modes supported
    */
   extern virtual function void set_unsupported_csr_mask();

   extern virtual function void read_disable_csr_check_plusargs();

   /**
    * Get irq_addr ack
    */
   extern virtual function bit [XLEN-1:0] get_irq_addr();

endclass : uvme_cva6_cfg_c


function uvme_cva6_cfg_c::new(string name="uvme_cva6_cfg");

   super.new(name);

   clknrst_cfg  = uvma_clknrst_cfg_c::type_id::create("clknrst_cfg");
   axi_cfg      = uvma_axi_cfg_c::type_id::create("axi_cfg");
   obi_memory_instr_cfg      = uvma_obi_memory_cfg_c::type_id::create("obi_memory_instr_cfg");
   obi_memory_store_cfg      = uvma_obi_memory_cfg_c::type_id::create("obi_memory_store_cfg");
   obi_memory_amo_cfg       = uvma_obi_memory_cfg_c::type_id::create("obi_memory_amo_cfg");
   obi_memory_zcmt_cfg      = uvma_obi_memory_cfg_c::type_id::create("obi_memory_zcmt_cfg");
   obi_memory_load_cfg      = uvma_obi_memory_cfg_c::type_id::create("obi_memory_load_cfg");
   obi_memory_mmu_ptw_cfg      = uvma_obi_memory_cfg_c::type_id::create("obi_memory_mmu_ptw_cfg");
   rvfi_cfg     = uvma_rvfi_cfg_c#(ILEN,XLEN)::type_id::create("rvfi_cfg");
   isacov_cfg   = uvma_isacov_cfg_c::type_id::create("isacov_cfg");
   interrupt_cfg   = uvma_interrupt_cfg_c::type_id::create("interrupt_cfg");
   cvxif_cfg       = uvma_cvxif_cfg_c::type_id::create("cvxif_cfg");

   isacov_cfg.core_cfg = this;
   rvfi_cfg.core_cfg = this;

   $value$plusargs("core_name=%s", this.core_name);

   if ($test$plusargs("tb_performance_mode")) begin
      performance_mode = 1;
      `uvm_info(get_type_name(), "Testbench set in performance mode, coverage & csr checks & scoreboard & loggers will be deactivated", UVM_NONE);
   end

endfunction : new

function void uvme_cva6_cfg_c::sample_parameters(uvma_core_cntrl_cntxt_c cntxt);

   uvma_cva6_core_cntrl_cntxt_c cva6_cntxt;

   if (!$cast(cva6_cntxt, cntxt)) begin
      `uvm_fatal("SAMPLECNTXT", "Could not cast cntxt to uvma_cva6_core_cntrl_cntxt_c");
   end

endfunction : sample_parameters

function bit [XLEN-1:0] uvme_cva6_cfg_c::get_irq_addr();

   int unsigned IRQ_ADDR;
   string binary;

    if (!$value$plusargs("irq_addr=%h", IRQ_ADDR)) IRQ_ADDR = '0;
    if (IRQ_ADDR == '0) begin
        if (!$value$plusargs("elf_file=%s", binary)) binary = "";
        if (binary != "") begin
            read_elf(binary);
            read_symbol("int_ack", IRQ_ADDR);
        end
      `uvm_info(get_type_name(), $sformatf("[IRQ] INFO: int_ack_addr: %h", IRQ_ADDR), UVM_NONE)
    end

    return IRQ_ADDR;

endfunction : get_irq_addr

function void uvme_cva6_cfg_c::set_unsupported_csr_mask();

   super.set_unsupported_csr_mask();

   // Add supported CSRs for Embedded configuration
   for (int i = 0; i < MAX_NUM_HPMCOUNTERS; i++) begin
      unsupported_csr_mask[uvma_core_cntrl_pkg::MHPMEVENT3+i] = 0;
      if (xlen == 32) begin
         unsupported_csr_mask[uvma_core_cntrl_pkg::MHPMCOUNTER3+i] = 0;
         unsupported_csr_mask[uvma_core_cntrl_pkg::MHPMCOUNTER3H+i] = 0;
      end
      else if (xlen == 64) begin
         unsupported_csr_mask[uvma_core_cntrl_pkg::MHPMCOUNTER3+i] = 1;
         unsupported_csr_mask[uvma_core_cntrl_pkg::MHPMCOUNTER3H+i] = 1;
      end
   end

   // Zihpm extension CSRs
   if (ext_zihpm_supported) begin
      for (int i = 0; i < MAX_NUM_HPMCOUNTERS; i++) begin
         unsupported_csr_mask[uvma_core_cntrl_pkg::HPMCOUNTER3+i] = 0;
         if (xlen == 32) begin
            unsupported_csr_mask[uvma_core_cntrl_pkg::HPMCOUNTER3H+i] = 0;
         end
         else if (xlen ==64) begin
            unsupported_csr_mask[uvma_core_cntrl_pkg::HPMCOUNTER3H+i] = 1;
         end
      end
   end
   else begin
      for (int i = 0; i < MAX_NUM_HPMCOUNTERS; i++) begin
         unsupported_csr_mask[uvma_core_cntrl_pkg::HPMCOUNTER3+i] = 1;
         unsupported_csr_mask[uvma_core_cntrl_pkg::HPMCOUNTER3H+i] = 1;
      end
   end

   // Upper Machine mode CSRs
   if (xlen == 32) begin
      unsupported_csr_mask[uvma_core_cntrl_pkg::MSTATUSH] = 0;
      unsupported_csr_mask[uvma_core_cntrl_pkg::MCYCLEH] = 0;
      unsupported_csr_mask[uvma_core_cntrl_pkg::MINSTRETH] = 0;
   end
   else if (xlen == 64) begin
      unsupported_csr_mask[uvma_core_cntrl_pkg::MSTATUSH] = 1;
      unsupported_csr_mask[uvma_core_cntrl_pkg::MCYCLEH] = 1;
      unsupported_csr_mask[uvma_core_cntrl_pkg::MINSTRETH] = 1;
   end

   // Remove the pmp CSRs beyond NrPMPEntries: one pmpaddr register per entry,
   // four entries per pmpcfg register on RV32.
   for (int i = 0; i < 64; i++) begin
      unsupported_csr_mask[uvma_core_cntrl_pkg::PMPADDR0+i] = (i >= nr_pmp_entries);
   end
   for (int i = 0; i < 16; i++) begin
      unsupported_csr_mask[uvma_core_cntrl_pkg::PMPCFG0+i] = (i * 4 >= nr_pmp_entries);
   end

endfunction : set_unsupported_csr_mask

function void uvme_cva6_cfg_c::read_disable_csr_check_plusargs();

   super.read_disable_csr_check_plusargs();
   if (force_disable_csr_checks)
      disable_all_csr_checks = 1;

endfunction : read_disable_csr_check_plusargs

`endif // __UVME_CVA6_CFG_SV__
