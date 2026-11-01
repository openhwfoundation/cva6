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


`ifndef __UVMT_CVA6_TB_SV__
`define __UVMT_CVA6_TB_SV__

`include "rvfi_types.svh"
`include "uvm_macros.svh"
`include "uvmt_cva6_macros.sv"

/**
 * Module encapsulating the CVA6 DUT wrapper, and associated SV interfaces.
 * Also provide UVM environment entry and exit points.
 */
`default_nettype none
module uvmt_cva6_tb;

   import uvm_pkg::*;
   import uvmt_cva6_pkg::*;
   import uvme_cva6_pkg::*;

   // CVA6 config
   localparam config_pkg::cva6_cfg_t CVA6Cfg = build_config_pkg::build_config(cva6_config_pkg::cva6_cfg);
   localparam RVFI_NRET = CVA6Cfg.NrCommitPorts;

   // RVFI
   localparam type rvfi_instr_t = `RVFI_INSTR_T(CVA6Cfg);
   localparam type rvfi_csr_elmt_t = `RVFI_CSR_ELMT_T(CVA6Cfg);
   localparam type rvfi_csr_t = `RVFI_CSR_T(CVA6Cfg, rvfi_csr_elmt_t);
   localparam type rvfi_to_iti_t = `RVFI_TO_ITI_T(CVA6Cfg);

   // RVFI PROBES
   localparam type rvfi_probes_instr_t = `RVFI_PROBES_INSTR_T(CVA6Cfg);
   localparam type rvfi_probes_csr_t = `RVFI_PROBES_CSR_T(CVA6Cfg);
   localparam type rvfi_probes_t = struct packed {
      rvfi_probes_csr_t csr;
      rvfi_probes_instr_t instr;
   };

   localparam NUM_WORDS         = 2**24;

   // ENV (testbench) parameters
   parameter int ENV_PARAM_INSTR_ADDR_WIDTH  = 32;
   parameter int ENV_PARAM_INSTR_DATA_WIDTH  = 32;
   parameter int ENV_PARAM_RAM_ADDR_WIDTH    = 22;

   // Agent interfaces
   uvma_clknrst_if              clknrst_if(); // clock and resets from the clknrst agent
   uvma_debug_if                debug_if(); // debug

   uvma_axi_intf                axi_if(
                                         .clk(clknrst_if.clk),
                                         .rst_n(clknrst_if.reset_n)
                                      );
   uvmt_axi_switch_intf         axi_switch_vif();

   //OBI interfaces
   uvma_obi_memory_if         obi_fetch_if  (
                                        .clk(clknrst_if.clk),
                                        .reset_n(clknrst_if.reset_n)
                                );
   uvma_obi_memory_if        obi_store_if  (
                                        .clk(clknrst_if.clk),
                                        .reset_n(clknrst_if.reset_n)
                                );
   uvma_obi_memory_if         obi_load_if  (
                                        .clk(clknrst_if.clk),
                                        .reset_n(clknrst_if.reset_n)
                                );
   uvma_obi_memory_if         obi_amo_if  (
                                        .clk(clknrst_if.clk),
                                        .reset_n(clknrst_if.reset_n)
                                );
   uvma_obi_memory_if         obi_mmu_ptw_if  (
                                        .clk(clknrst_if.clk),
                                        .reset_n(clknrst_if.reset_n)
                                );
   uvma_obi_memory_if         obi_zcmt_if  (
                                        .clk(clknrst_if.clk),
                                        .reset_n(clknrst_if.reset_n)
                                );

   uvma_interrupt_if            interrupt_vif(
                                         .clk(clknrst_if.clk),
                                         .reset_n(clknrst_if.reset_n)
                                );

   uvma_cvxif_intf              cvxif_vif(
                                         .clk(clknrst_if.clk),
                                         .reset_n(clknrst_if.reset_n)
                                );

   if (CVA6Cfg.MemSubsystem != config_pkg::MEM_OBI) begin
      //bind assertion module for axi interface
      bind uvmt_cva6_dut_wrap
         uvmt_axi_assert #(CVA6Cfg)                      axi_assert(.axi_assert_if(axi_if));
   end else begin
      //bind assertion module for obi interface
      bind uvmt_cva6_dut_wrap uvma_obi_memory_assert_if_wrp #(
                          .AUSER_WIDTH(CVA6Cfg.ObiFetchbusCfg.OptionalCfg.AUserWidth),
                          .WUSER_WIDTH(CVA6Cfg.ObiFetchbusCfg.OptionalCfg.WUserWidth),
                          .RUSER_WIDTH(CVA6Cfg.ObiFetchbusCfg.OptionalCfg.RUserWidth),
                          .ADDR_WIDTH(CVA6Cfg.ObiFetchbusCfg.AddrWidth),
                          .DATA_WIDTH(CVA6Cfg.ObiFetchbusCfg.DataWidth),
                          .ID_WIDTH(CVA6Cfg.ObiFetchbusCfg.IdWidth),
                          .ACHK_WIDTH(CVA6Cfg.ObiFetchbusCfg.OptionalCfg.AChkWidth),
                          .RCHK_WIDTH(CVA6Cfg.ObiFetchbusCfg.OptionalCfg.RChkWidth),
                          .IS_1P2(1)) obi_fetch_assert(.obi(obi_fetch_if));
      bind uvmt_cva6_dut_wrap uvma_obi_memory_assert_if_wrp #(
                          .AUSER_WIDTH(CVA6Cfg.ObiStorebusCfg.OptionalCfg.AUserWidth),
                          .WUSER_WIDTH(CVA6Cfg.ObiStorebusCfg.OptionalCfg.WUserWidth),
                          .RUSER_WIDTH(CVA6Cfg.ObiStorebusCfg.OptionalCfg.RUserWidth),
                          .ADDR_WIDTH(CVA6Cfg.ObiStorebusCfg.AddrWidth),
                          .DATA_WIDTH(CVA6Cfg.ObiStorebusCfg.DataWidth),
                          .ID_WIDTH(CVA6Cfg.ObiStorebusCfg.IdWidth),
                          .ACHK_WIDTH(CVA6Cfg.ObiStorebusCfg.OptionalCfg.AChkWidth),
                          .RCHK_WIDTH(CVA6Cfg.ObiStorebusCfg.OptionalCfg.RChkWidth),
                          .IS_1P2(1)) obi_store_assert(.obi(obi_store_if));
      if (CVA6Cfg.RVA) begin
         bind uvmt_cva6_dut_wrap uvma_obi_memory_assert_if_wrp #(
                             .AUSER_WIDTH(CVA6Cfg.ObiAmobusCfg.OptionalCfg.AUserWidth),
                             .WUSER_WIDTH(CVA6Cfg.ObiAmobusCfg.OptionalCfg.WUserWidth),
                             .RUSER_WIDTH(CVA6Cfg.ObiAmobusCfg.OptionalCfg.RUserWidth),
                             .ADDR_WIDTH(CVA6Cfg.ObiAmobusCfg.AddrWidth),
                             .DATA_WIDTH(CVA6Cfg.ObiAmobusCfg.DataWidth),
                             .ID_WIDTH(CVA6Cfg.ObiAmobusCfg.IdWidth),
                             .ACHK_WIDTH(CVA6Cfg.ObiAmobusCfg.OptionalCfg.AChkWidth),
                             .RCHK_WIDTH(CVA6Cfg.ObiAmobusCfg.OptionalCfg.RChkWidth),
                             .IS_1P2(1)) obi_amo_assert(.obi(obi_amo_if));
      end
      if (CVA6Cfg.RVZCMT) begin
         bind uvmt_cva6_dut_wrap uvma_obi_memory_assert_if_wrp #(
                             .AUSER_WIDTH(CVA6Cfg.ObiZcmtbusCfg.OptionalCfg.AUserWidth),
                             .WUSER_WIDTH(CVA6Cfg.ObiZcmtbusCfg.OptionalCfg.WUserWidth),
                             .RUSER_WIDTH(CVA6Cfg.ObiZcmtbusCfg.OptionalCfg.RUserWidth),
                             .ADDR_WIDTH(CVA6Cfg.ObiZcmtbusCfg.AddrWidth),
                             .DATA_WIDTH(CVA6Cfg.ObiZcmtbusCfg.DataWidth),
                             .ID_WIDTH(CVA6Cfg.ObiZcmtbusCfg.IdWidth),
                             .ACHK_WIDTH(CVA6Cfg.ObiZcmtbusCfg.OptionalCfg.AChkWidth),
                             .RCHK_WIDTH(CVA6Cfg.ObiZcmtbusCfg.OptionalCfg.RChkWidth),
                             .IS_1P2(1)) obi_zcmt_assert(.obi(obi_zcmt_if));
      end
      bind uvmt_cva6_dut_wrap uvma_obi_memory_assert_if_wrp #(
                          .AUSER_WIDTH(CVA6Cfg.ObiLoadbusCfg.OptionalCfg.AUserWidth),
                          .WUSER_WIDTH(CVA6Cfg.ObiLoadbusCfg.OptionalCfg.WUserWidth),
                          .RUSER_WIDTH(CVA6Cfg.ObiLoadbusCfg.OptionalCfg.RUserWidth),
                          .ADDR_WIDTH(CVA6Cfg.ObiLoadbusCfg.AddrWidth),
                          .DATA_WIDTH(CVA6Cfg.ObiLoadbusCfg.DataWidth),
                          .ID_WIDTH(CVA6Cfg.ObiLoadbusCfg.IdWidth),
                          .ACHK_WIDTH(CVA6Cfg.ObiLoadbusCfg.OptionalCfg.AChkWidth),
                          .RCHK_WIDTH(CVA6Cfg.ObiLoadbusCfg.OptionalCfg.RChkWidth),
                          .IS_1P2(1)) obi_load_assert(.obi(obi_load_if));
      if (CVA6Cfg.MmuPresent) begin
         bind uvmt_cva6_dut_wrap uvma_obi_memory_assert_if_wrp #(
                          .AUSER_WIDTH(CVA6Cfg.ObiMmuPtwbusCfg.OptionalCfg.AUserWidth),
                          .WUSER_WIDTH(CVA6Cfg.ObiMmuPtwbusCfg.OptionalCfg.WUserWidth),
                          .RUSER_WIDTH(CVA6Cfg.ObiMmuPtwbusCfg.OptionalCfg.RUserWidth),
                          .ADDR_WIDTH(CVA6Cfg.ObiMmuPtwbusCfg.AddrWidth),
                          .DATA_WIDTH(CVA6Cfg.ObiMmuPtwbusCfg.DataWidth),
                          .ID_WIDTH(CVA6Cfg.ObiMmuPtwbusCfg.IdWidth),
                          .ACHK_WIDTH(CVA6Cfg.ObiMmuPtwbusCfg.OptionalCfg.AChkWidth),
                          .RCHK_WIDTH(CVA6Cfg.ObiMmuPtwbusCfg.OptionalCfg.RChkWidth),
                          .IS_1P2(1)) obi_mmu_ptw_assert(.obi(obi_mmu_ptw_if));
      end
   end

   uvme_cva6_core_cntrl_if      core_cntrl_if();
   uvma_rvfi_instr_if #(
     uvme_cva6_pkg::ILEN,
     uvme_cva6_pkg::XLEN
   ) rvfi_instr_if [RVFI_NRET-1:0] ();

    uvma_rvfi_csr_if#(uvme_cva6_pkg::XLEN)        rvfi_csr_if [RVFI_NRET-1:0]();

    uvmt_default_inputs_intf         default_inputs_vif();

   //bind assertion module for cvxif interface
   bind uvmt_cva6_dut_wrap
      uvma_cvxif_assert #(
      CVA6Cfg.X_HARTID_WIDTH,
      CVA6Cfg.X_ID_WIDTH,
      CVA6Cfg.X_NUM_RS
   ) cvxif_assert(.cvxif_assert(cvxif_vif));

   // DUT Wrapper Interfaces
   uvmt_rvfi_if #(
     // RVFI
     .CVA6Cfg           ( CVA6Cfg      ),
     .rvfi_instr_t      ( rvfi_instr_t ),
     .rvfi_csr_t        ( rvfi_csr_t   )
   ) rvfi_if(
                                                 .rvfi_o(),
                                                 .rvfi_csr_o()
                                                 ); // Status information generated by the Virtual Peripherals in the DUT WRAPPER memory.
    uvmt_tb_exit_if tb_exit_if ( .tb_exit_o());

    assign debug_if.clk         = clknrst_if.clk;
    assign debug_if.reset_n     = clknrst_if.reset_n;
  /**
   * DUT WRAPPER instance
   */

   uvmt_cva6_dut_wrap #(
     .CVA6Cfg           ( CVA6Cfg                ),
     .rvfi_instr_t      ( rvfi_instr_t           ),
     .rvfi_csr_elmt_t   ( rvfi_csr_elmt_t        ),
     .rvfi_csr_t        ( rvfi_csr_t             ),
     .rvfi_probes_instr_t(rvfi_probes_instr_t    ),
     .rvfi_probes_csr_t ( rvfi_probes_csr_t      ),
     .rvfi_probes_t     ( rvfi_probes_t          ),
     .rvfi_to_iti_t     ( rvfi_to_iti_t          ),
     //
     .AXI_USER_EN       (CVA6Cfg.AXI_USER_EN),
     .NUM_WORDS         (NUM_WORDS)
   ) cva6_dut_wrap (
                    .clknrst_if(clknrst_if),
                    .debug_if(debug_if),
                    .axi_if    (axi_if),
                    .obi_fetch_if    (obi_fetch_if),
                    .obi_store_if    (obi_store_if),
                    .obi_amo_if      (obi_amo_if),
                    .obi_load_if     (obi_load_if),
                    .obi_mmu_ptw_if    (obi_mmu_ptw_if),
                    .obi_zcmt_if    (obi_zcmt_if),
                    .axi_switch_vif    (axi_switch_vif),
                    .default_inputs_vif    (default_inputs_vif),
                    .core_cntrl_if(core_cntrl_if),
                    .interrupt_vif(interrupt_vif),
                    .cvxif_vif(cvxif_vif),
                    .tb_exit_o(tb_exit_if.tb_exit_o),
                    .rvfi_o(rvfi_if.rvfi_o),
                    .rvfi_csr_o(rvfi_if.rvfi_csr_o)
                    );

   for (genvar i = 0; i < RVFI_NRET; i++) begin
      assign  rvfi_instr_if[i].clk            = clknrst_if.clk;
      assign  rvfi_instr_if[i].reset_n        = clknrst_if.reset_n;
      assign  rvfi_instr_if[i].rvfi_valid     = rvfi_if.rvfi_o[i].valid;
      assign  rvfi_instr_if[i].rvfi_order     = rvfi_if.rvfi_o[i].order;
      assign  rvfi_instr_if[i].rvfi_insn      = rvfi_if.rvfi_o[i].insn;
      assign  rvfi_instr_if[i].rvfi_trap      = (rvfi_if.rvfi_o[i].trap | (rvfi_if.rvfi_o[i].cause << 1));
      assign  rvfi_instr_if[i].rvfi_halt      = rvfi_if.rvfi_o[i].halt;
      assign  rvfi_instr_if[i].rvfi_intr      = rvfi_if.rvfi_o[i].intr;
      assign  rvfi_instr_if[i].rvfi_mode      = rvfi_if.rvfi_o[i].mode;
      assign  rvfi_instr_if[i].rvfi_ixl       = rvfi_if.rvfi_o[i].ixl;
      assign  rvfi_instr_if[i].rvfi_pc_rdata  = rvfi_if.rvfi_o[i].pc_rdata;
      assign  rvfi_instr_if[i].rvfi_pc_wdata  = rvfi_if.rvfi_o[i].pc_wdata;
      assign  rvfi_instr_if[i].rvfi_rs1_addr  = rvfi_if.rvfi_o[i].rs1_addr;
      assign  rvfi_instr_if[i].rvfi_rs1_rdata = rvfi_if.rvfi_o[i].rs1_rdata;
      assign  rvfi_instr_if[i].rvfi_rs2_addr  = rvfi_if.rvfi_o[i].rs2_addr;
      assign  rvfi_instr_if[i].rvfi_rs2_rdata = rvfi_if.rvfi_o[i].rs2_rdata;
      assign  rvfi_instr_if[i].rvfi_rd1_addr  = rvfi_if.rvfi_o[i].rd_addr;
      assign  rvfi_instr_if[i].rvfi_rd1_wdata = rvfi_if.rvfi_o[i].rd_wdata;
      assign  rvfi_instr_if[i].rvfi_mem_addr  = rvfi_if.rvfi_o[i].mem_addr;
      assign  rvfi_instr_if[i].rvfi_mem_rdata = rvfi_if.rvfi_o[i].mem_rdata;
      assign  rvfi_instr_if[i].rvfi_mem_rmask = rvfi_if.rvfi_o[i].mem_rmask;
      assign  rvfi_instr_if[i].rvfi_mem_wdata = rvfi_if.rvfi_o[i].mem_wdata;
      assign  rvfi_instr_if[i].rvfi_mem_wmask = rvfi_if.rvfi_o[i].mem_wmask;
   end

   `RVFI_CSR_ASSIGN(fflags)
   `RVFI_CSR_ASSIGN(frm)
   `RVFI_CSR_ASSIGN(fcsr)
   `RVFI_CSR_ASSIGN(ftran)
   `RVFI_CSR_ASSIGN(dcsr)
   `RVFI_CSR_ASSIGN(dpc)
   `RVFI_CSR_ASSIGN(dscratch0)
   `RVFI_CSR_ASSIGN(dscratch1)
   `RVFI_CSR_ASSIGN(sstatus)
   `RVFI_CSR_ASSIGN(sie)
   `RVFI_CSR_ASSIGN(sip)
   `RVFI_CSR_ASSIGN(stvec)
   `RVFI_CSR_ASSIGN(scounteren)
   `RVFI_CSR_ASSIGN(sscratch)
   `RVFI_CSR_ASSIGN(sepc)
   `RVFI_CSR_ASSIGN(scause)
   `RVFI_CSR_ASSIGN(stval)
   `RVFI_CSR_ASSIGN(satp)
   `RVFI_CSR_ASSIGN(mstatus)
   `RVFI_CSR_ASSIGN(mstatush)
   `RVFI_CSR_ASSIGN(misa)
   `RVFI_CSR_ASSIGN(medeleg)
   `RVFI_CSR_ASSIGN(mideleg)
   `RVFI_CSR_ASSIGN(mie)
   `RVFI_CSR_ASSIGN(mtvec)
   `RVFI_CSR_ASSIGN(mcounteren)
   `RVFI_CSR_ASSIGN(mscratch)
   `RVFI_CSR_ASSIGN(mepc)
   `RVFI_CSR_ASSIGN(mcause)
   `RVFI_CSR_ASSIGN(mtval)
   `RVFI_CSR_ASSIGN(mtinst)
   `RVFI_CSR_ASSIGN(mtval2)
   `RVFI_CSR_ASSIGN(mip)
   `RVFI_CSR_ASSIGN(menvcfg)
   `RVFI_CSR_ASSIGN(menvcfgh)
   `RVFI_CSR_ASSIGN(mvendorid)
   `RVFI_CSR_ASSIGN(marchid)
   `RVFI_CSR_ASSIGN(mhartid)
   `RVFI_CSR_ASSIGN(mcountinhibit)
   `RVFI_CSR_ASSIGN(mcycle)
   `RVFI_CSR_ASSIGN(mcycleh)
   `RVFI_CSR_ASSIGN(minstret)
   `RVFI_CSR_ASSIGN(minstreth)
   `RVFI_CSR_ASSIGN(cycle)
   `RVFI_CSR_ASSIGN(cycleh)
   `RVFI_CSR_ASSIGN(instret)
   `RVFI_CSR_ASSIGN(instreth)
   `RVFI_CSR_ASSIGN(dcache)
   `RVFI_CSR_ASSIGN(icache)

   `RVFI_CSR_ASSIGN(pmpcfg0)
   `RVFI_CSR_ASSIGN(pmpcfg1)
   `RVFI_CSR_ASSIGN(pmpcfg2)
   `RVFI_CSR_ASSIGN(pmpcfg3)

   `RVFI_CSR_SUFFIX_ASSIGN(pmpaddr, 0)
   `RVFI_CSR_SUFFIX_ASSIGN(pmpaddr, 1)
   `RVFI_CSR_SUFFIX_ASSIGN(pmpaddr, 2)
   `RVFI_CSR_SUFFIX_ASSIGN(pmpaddr, 3)
   `RVFI_CSR_SUFFIX_ASSIGN(pmpaddr, 4)
   `RVFI_CSR_SUFFIX_ASSIGN(pmpaddr, 5)
   `RVFI_CSR_SUFFIX_ASSIGN(pmpaddr, 6)
   `RVFI_CSR_SUFFIX_ASSIGN(pmpaddr, 7)
   `RVFI_CSR_SUFFIX_ASSIGN(pmpaddr, 8)
   `RVFI_CSR_SUFFIX_ASSIGN(pmpaddr, 9)
   `RVFI_CSR_SUFFIX_ASSIGN(pmpaddr, 10)
   `RVFI_CSR_SUFFIX_ASSIGN(pmpaddr, 11)
   `RVFI_CSR_SUFFIX_ASSIGN(pmpaddr, 12)
   `RVFI_CSR_SUFFIX_ASSIGN(pmpaddr, 13)
   `RVFI_CSR_SUFFIX_ASSIGN(pmpaddr, 14)
   `RVFI_CSR_SUFFIX_ASSIGN(pmpaddr, 15)

   assign  default_inputs_vif.hart_id   = 64'h0000_0000_0000_0000;
   assign  default_inputs_vif.irq       = 2'b00;
   assign  default_inputs_vif.ipi       = 1'b0;
   assign  default_inputs_vif.time_irq  = 1'b0;
   assign  default_inputs_vif.debug_req = 1'b0;


   for (genvar i = 0; i < RVFI_NRET; i++) begin
      initial  begin
         uvm_config_db#(virtual uvma_rvfi_instr_if )::set(null,"*", $sformatf("instr_vif%0d", i), rvfi_instr_if[i]);

         // set CSRs interface
         `RVFI_CSR_UVM_CONFIG_DB_SET(fflags, i)
         `RVFI_CSR_UVM_CONFIG_DB_SET(frm, i)
         `RVFI_CSR_UVM_CONFIG_DB_SET(fcsr, i)
         `RVFI_CSR_UVM_CONFIG_DB_SET(ftran, i)
         `RVFI_CSR_UVM_CONFIG_DB_SET(dcsr, i)
         `RVFI_CSR_UVM_CONFIG_DB_SET(dpc, i)
         `RVFI_CSR_UVM_CONFIG_DB_SET(dscratch0, i)
         `RVFI_CSR_UVM_CONFIG_DB_SET(dscratch1, i)
         `RVFI_CSR_UVM_CONFIG_DB_SET(sstatus, i)
         `RVFI_CSR_UVM_CONFIG_DB_SET(sie, i)
         `RVFI_CSR_UVM_CONFIG_DB_SET(sip, i)
         `RVFI_CSR_UVM_CONFIG_DB_SET(stvec, i)
         `RVFI_CSR_UVM_CONFIG_DB_SET(scounteren, i)
         `RVFI_CSR_UVM_CONFIG_DB_SET(sscratch, i)
         `RVFI_CSR_UVM_CONFIG_DB_SET(sepc, i)
         `RVFI_CSR_UVM_CONFIG_DB_SET(scause, i)
         `RVFI_CSR_UVM_CONFIG_DB_SET(stval, i)
         `RVFI_CSR_UVM_CONFIG_DB_SET(satp, i)
         `RVFI_CSR_UVM_CONFIG_DB_SET(mstatus, i)
         `RVFI_CSR_UVM_CONFIG_DB_SET(mstatush, i)
         `RVFI_CSR_UVM_CONFIG_DB_SET(marchid, i)
         `RVFI_CSR_UVM_CONFIG_DB_SET(misa, i)
         `RVFI_CSR_UVM_CONFIG_DB_SET(medeleg, i)
         `RVFI_CSR_UVM_CONFIG_DB_SET(mideleg, i)
         `RVFI_CSR_UVM_CONFIG_DB_SET(mie, i)
         `RVFI_CSR_UVM_CONFIG_DB_SET(mtvec, i)
         `RVFI_CSR_UVM_CONFIG_DB_SET(mcounteren, i)
         `RVFI_CSR_UVM_CONFIG_DB_SET(mscratch, i)
         `RVFI_CSR_UVM_CONFIG_DB_SET(mepc, i)
         `RVFI_CSR_UVM_CONFIG_DB_SET(mcause, i)
         `RVFI_CSR_UVM_CONFIG_DB_SET(mtval, i)
         `RVFI_CSR_UVM_CONFIG_DB_SET(mtinst, i)
         `RVFI_CSR_UVM_CONFIG_DB_SET(mtval2, i)
         `RVFI_CSR_UVM_CONFIG_DB_SET(mip, i)
         `RVFI_CSR_UVM_CONFIG_DB_SET(menvcfg, i)
         `RVFI_CSR_UVM_CONFIG_DB_SET(menvcfgh, i)
         `RVFI_CSR_UVM_CONFIG_DB_SET(marchid, i)
         `RVFI_CSR_UVM_CONFIG_DB_SET(mhartid, i)
         `RVFI_CSR_UVM_CONFIG_DB_SET(mcountinhibit, i)
         `RVFI_CSR_UVM_CONFIG_DB_SET(mcycle, i)
         `RVFI_CSR_UVM_CONFIG_DB_SET(mcycleh, i)
         `RVFI_CSR_UVM_CONFIG_DB_SET(minstret, i)
         `RVFI_CSR_UVM_CONFIG_DB_SET(minstreth, i)
         `RVFI_CSR_UVM_CONFIG_DB_SET(cycle, i)
         `RVFI_CSR_UVM_CONFIG_DB_SET(cycleh, i)
         `RVFI_CSR_UVM_CONFIG_DB_SET(instret, i)
         `RVFI_CSR_UVM_CONFIG_DB_SET(instreth, i)
         `RVFI_CSR_UVM_CONFIG_DB_SET(dcache, i)
         `RVFI_CSR_UVM_CONFIG_DB_SET(icache, i)

         `RVFI_CSR_UVM_CONFIG_DB_SET(pmpcfg0, i)
         `RVFI_CSR_UVM_CONFIG_DB_SET(pmpcfg1, i)
         `RVFI_CSR_UVM_CONFIG_DB_SET(pmpcfg2, i)
         `RVFI_CSR_UVM_CONFIG_DB_SET(pmpcfg3, i)

         `RVFI_CSR_UVM_CONFIG_DB_SET(pmpaddr0, i)
         `RVFI_CSR_UVM_CONFIG_DB_SET(pmpaddr1, i)
         `RVFI_CSR_UVM_CONFIG_DB_SET(pmpaddr2, i)
         `RVFI_CSR_UVM_CONFIG_DB_SET(pmpaddr3, i)
         `RVFI_CSR_UVM_CONFIG_DB_SET(pmpaddr4, i)
         `RVFI_CSR_UVM_CONFIG_DB_SET(pmpaddr5, i)
         `RVFI_CSR_UVM_CONFIG_DB_SET(pmpaddr6, i)
         `RVFI_CSR_UVM_CONFIG_DB_SET(pmpaddr7, i)
         `RVFI_CSR_UVM_CONFIG_DB_SET(pmpaddr8, i)
         `RVFI_CSR_UVM_CONFIG_DB_SET(pmpaddr9, i)
         `RVFI_CSR_UVM_CONFIG_DB_SET(pmpaddr10, i)
         `RVFI_CSR_UVM_CONFIG_DB_SET(pmpaddr11, i)
         `RVFI_CSR_UVM_CONFIG_DB_SET(pmpaddr12, i)
         `RVFI_CSR_UVM_CONFIG_DB_SET(pmpaddr13, i)
         `RVFI_CSR_UVM_CONFIG_DB_SET(pmpaddr14, i)
         `RVFI_CSR_UVM_CONFIG_DB_SET(pmpaddr15, i)

         //TO-DO - Not yet supported
         for (int j = 3; j < 32; j++) begin
            uvm_config_db#(virtual uvma_rvfi_csr_if )::set(null,"*", $sformatf("csr_mhpmevent%0d_vif%0d", j, i),         rvfi_csr_if[i]);
            uvm_config_db#(virtual uvma_rvfi_csr_if )::set(null,"*", $sformatf("csr_mhpmcounter%0d_vif%0d", j, i),       rvfi_csr_if[i]);
            uvm_config_db#(virtual uvma_rvfi_csr_if )::set(null,"*", $sformatf("csr_mhpmcounter%0dh_vif%0d", j, i),      rvfi_csr_if[i]);
            uvm_config_db#(virtual uvma_rvfi_csr_if )::set(null,"*", $sformatf("csr_hpmcounter%0d_vif%0d", j, i),        rvfi_csr_if[i]);
            uvm_config_db#(virtual uvma_rvfi_csr_if )::set(null,"*", $sformatf("csr_hpmcounter%0dh_vif%0d", j, i),       rvfi_csr_if[i]);
         end
         for (int j = 4; j < 16; j++) begin
            uvm_config_db#(virtual uvma_rvfi_csr_if )::set(null,"*", $sformatf("csr_pmpcfg%0d_vif%0d", j, i),            rvfi_csr_if[i]);
         end
         for (int j = 16; j < 64; j++) begin
            uvm_config_db#(virtual uvma_rvfi_csr_if )::set(null,"*", $sformatf("csr_pmpaddr%0d_vif%0d", j, i),            rvfi_csr_if[i]);
         end

         uvm_config_db#(virtual uvma_rvfi_csr_if )::set(null,"*", $sformatf("csr_mvendorid_vif%0d", i),                  rvfi_csr_if[i]);
         uvm_config_db#(virtual uvma_rvfi_csr_if )::set(null,"*", $sformatf("csr_marchid_vif%0d", i),                    rvfi_csr_if[i]);
         uvm_config_db#(virtual uvma_rvfi_csr_if )::set(null,"*", $sformatf("csr_ustatus_vif%0d", i),                    rvfi_csr_if[i]);
         uvm_config_db#(virtual uvma_rvfi_csr_if )::set(null,"*", $sformatf("csr_utvec_vif%0d", i),                      rvfi_csr_if[i]);
         uvm_config_db#(virtual uvma_rvfi_csr_if )::set(null,"*", $sformatf("csr_utval_vif%0d", i),                      rvfi_csr_if[i]);
         uvm_config_db#(virtual uvma_rvfi_csr_if )::set(null,"*", $sformatf("csr_uepc_vif%0d", i),                       rvfi_csr_if[i]);
         uvm_config_db#(virtual uvma_rvfi_csr_if )::set(null,"*", $sformatf("csr_ucause_vif%0d", i),                     rvfi_csr_if[i]);
         uvm_config_db#(virtual uvma_rvfi_csr_if )::set(null,"*", $sformatf("csr_uip_vif%0d", i),                        rvfi_csr_if[i]);
         uvm_config_db#(virtual uvma_rvfi_csr_if )::set(null,"*", $sformatf("csr_uie_vif%0d", i),                        rvfi_csr_if[i]);
         uvm_config_db#(virtual uvma_rvfi_csr_if )::set(null,"*", $sformatf("csr_mimpid_vif%0d", i),                     rvfi_csr_if[i]);
         uvm_config_db#(virtual uvma_rvfi_csr_if )::set(null,"*", $sformatf("csr_mcontext_vif%0d", i),                   rvfi_csr_if[i]);
         uvm_config_db#(virtual uvma_rvfi_csr_if )::set(null,"*", $sformatf("csr_uscratch_vif%0d", i),                   rvfi_csr_if[i]);
         uvm_config_db#(virtual uvma_rvfi_csr_if )::set(null,"*", $sformatf("csr_scontext_vif%0d", i),                   rvfi_csr_if[i]);
         uvm_config_db#(virtual uvma_rvfi_csr_if )::set(null,"*", $sformatf("csr_tselect_vif%0d", i),                    rvfi_csr_if[i]);
         uvm_config_db#(virtual uvma_rvfi_csr_if )::set(null,"*", $sformatf("csr_tdata1_vif%0d", i),                     rvfi_csr_if[i]);
         uvm_config_db#(virtual uvma_rvfi_csr_if )::set(null,"*", $sformatf("csr_tdata2_vif%0d", i),                     rvfi_csr_if[i]);
         uvm_config_db#(virtual uvma_rvfi_csr_if )::set(null,"*", $sformatf("csr_tdata3_vif%0d", i),                     rvfi_csr_if[i]);
         uvm_config_db#(virtual uvma_rvfi_csr_if )::set(null,"*", $sformatf("csr_tinfo_vif%0d", i),                      rvfi_csr_if[i]);
         uvm_config_db#(virtual uvma_rvfi_csr_if )::set(null,"*", $sformatf("csr_tcontrol_vif%0d", i),                   rvfi_csr_if[i]);
         uvm_config_db#(virtual uvma_rvfi_csr_if )::set(null,"*", $sformatf("csr_mconfigptr_vif%0d", i),                 rvfi_csr_if[i]);
         uvm_config_db#(virtual uvma_rvfi_csr_if )::set(null,"*", $sformatf("csr_time_vif%0d", i),                       rvfi_csr_if[i]);
         uvm_config_db#(virtual uvma_rvfi_csr_if )::set(null,"*", $sformatf("csr_timeh_vif%0d", i),                      rvfi_csr_if[i]);
         uvm_config_db#(virtual uvma_rvfi_csr_if )::set(null,"*", $sformatf("csr_sedeleg_vif%0d", i),                    rvfi_csr_if[i]);
         uvm_config_db#(virtual uvma_rvfi_csr_if )::set(null,"*", $sformatf("csr_sideleg_vif%0d", i),                    rvfi_csr_if[i]);
    end
   end
   /**
    * Test bench entry point.
    */
   initial begin : test_bench_entry_point
     bit axi_assert_on;

     // Specify time format for simulation (units_number, precision_number, suffix_string, minimum_field_width)
     $timeformat(-9, 3, " ns", 8);

     if (CVA6Cfg.MemSubsystem != config_pkg::MEM_OBI) begin
        axi_if.aw_assertion_enabled      = 1;
        axi_if.w_assertion_enabled       = 1;
        axi_if.b_assertion_enabled       = 1;
        axi_if.ar_assertion_enabled      = 1;
        axi_if.r_assertion_enabled       = 1;
        axi_if.axi_assertion_enabled     = 1;
        axi_if.axi_amo_assertion_enabled = 1;
     end else if($value$plusargs("uvmt_set_axi_assert_cfg=%0d", axi_assert_on)) begin
        axi_if.aw_assertion_enabled      = axi_assert_on;
        axi_if.w_assertion_enabled       = axi_assert_on;
        axi_if.b_assertion_enabled       = axi_assert_on;
        axi_if.ar_assertion_enabled      = axi_assert_on;
        axi_if.r_assertion_enabled       = axi_assert_on;
        axi_if.axi_assertion_enabled     = axi_assert_on;
        axi_if.axi_amo_assertion_enabled = axi_assert_on;
     end else begin
        axi_if.aw_assertion_enabled      = 0;
        axi_if.w_assertion_enabled       = 0;
        axi_if.b_assertion_enabled       = 0;
        axi_if.ar_assertion_enabled      = 0;
        axi_if.r_assertion_enabled       = 0;
        axi_if.axi_assertion_enabled     = 0;
        axi_if.axi_amo_assertion_enabled = 0;
     end

     // Add interfaces handles to uvm_config_db
     uvm_config_db#(virtual uvma_clknrst_if )::set(.cntxt(null), .inst_name("*.env.clknrst_agent"), .field_name("vif"),       .value(clknrst_if));
     uvm_config_db#(virtual uvma_debug_if   )::set(.cntxt(null), .inst_name("*.env"),               .field_name("debug_vif"), .value(debug_if));
     uvm_config_db#(virtual uvma_axi_intf   )::set(.cntxt(null), .inst_name("*"),                   .field_name("axi_vif"),    .value(axi_if));
     uvm_config_db#(virtual uvmt_axi_switch_intf  )::set(.cntxt(null), .inst_name("*.env"),             .field_name("axi_switch_vif"),   .value(axi_switch_vif));
     uvm_config_db#(virtual uvma_obi_memory_if)::set(.cntxt(null), .inst_name("*obi_memory_instr_agent"),   .field_name("vif"),    .value(obi_fetch_if));
     uvm_config_db#(virtual uvma_obi_memory_if)::set(.cntxt(null), .inst_name("*obi_memory_store_agent"),   .field_name("vif"),    .value(obi_store_if));
     uvm_config_db#(virtual uvma_obi_memory_if)::set(.cntxt(null), .inst_name("*obi_memory_load_agent"),     .field_name("vif"),    .value(obi_load_if));
     uvm_config_db#(virtual uvma_obi_memory_if)::set(.cntxt(null), .inst_name("*obi_memory_amo_agent"),     .field_name("vif"),    .value(obi_amo_if));
     uvm_config_db#(virtual uvma_obi_memory_if)::set(.cntxt(null), .inst_name("*obi_memory_zcmt_agent"),     .field_name("vif"),    .value(obi_zcmt_if));
     uvm_config_db#(virtual uvma_obi_memory_if)::set(.cntxt(null), .inst_name("*obi_memory_mmu_ptw_agent"),     .field_name("vif"),    .value(obi_mmu_ptw_if));
     uvm_config_db#(virtual uvmt_rvfi_if#( .CVA6Cfg(CVA6Cfg), .rvfi_instr_t(rvfi_instr_t), .rvfi_csr_t (rvfi_csr_t)))::set(.cntxt(null), .inst_name("*"), .field_name("rvfi_vif"),  .value(rvfi_if));
     uvm_config_db#(virtual uvme_cva6_core_cntrl_if)::set(.cntxt(null), .inst_name("*"), .field_name("core_cntrl_vif"),  .value(core_cntrl_if));
     uvm_config_db#(virtual uvma_interrupt_if)::set(.cntxt(null), .inst_name("*"), .field_name("interrupt_vif"),  .value(interrupt_vif));
     uvm_config_db#(virtual uvma_cvxif_intf)::set(.cntxt(null), .inst_name("*"), .field_name("vif"),  .value(cvxif_vif));

     uvm_config_db#(virtual uvmt_tb_exit_if)::set(.cntxt(null), .inst_name("*"), .field_name("tb_exit_vif"), .value(tb_exit_if));

     // DUT and ENV parameters
     uvm_config_db#(int)::set(.cntxt(null), .inst_name("*"), .field_name("ENV_PARAM_INSTR_ADDR_WIDTH"),  .value(ENV_PARAM_INSTR_ADDR_WIDTH) );
     uvm_config_db#(int)::set(.cntxt(null), .inst_name("*"), .field_name("ENV_PARAM_INSTR_DATA_WIDTH"),  .value(ENV_PARAM_INSTR_DATA_WIDTH) );
     uvm_config_db#(int)::set(.cntxt(null), .inst_name("*"), .field_name("ENV_PARAM_RAM_ADDR_WIDTH"),    .value(ENV_PARAM_RAM_ADDR_WIDTH)   );

     // Run test
     uvm_top.enable_print_topology = 0; // ENV coders enable this as a debug aid
     uvm_top.finish_on_completion  = 1;
     uvm_top.run_test();
   end : test_bench_entry_point

   assign core_cntrl_if.clk = clknrst_if.clk;

   /**
    * End-of-test summary printout.
    */
   final begin: end_of_test
      string             summary_string;
      uvm_report_server  rs;
      int                err_count;
      int                warning_count;
      int                fatal_count;
      static bit         sim_finished = 0;
      static int         test_exit_code = 0;

      static string  red   = "\033[31m\033[1m";
      static string  green = "\033[32m\033[1m";
      static string  reset = "\033[0m";

      rs            = uvm_top.get_report_server();
      err_count     = rs.get_severity_count(UVM_ERROR);
      warning_count = rs.get_severity_count(UVM_WARNING);
      fatal_count   = rs.get_severity_count(UVM_FATAL);

      void'(uvm_config_db#(bit)::get(null, "", "sim_finished", sim_finished));
      void'(uvm_config_db#(int)::get(null, "", "test_exit_code", test_exit_code));

      $display("\n%m: *** Test Summary ***\n");

      if (sim_finished && (test_exit_code == 0) && (err_count == 0) && (fatal_count == 0)) begin
         $display("    PPPPPPP    AAAAAA    SSSSSS    SSSSSS   EEEEEEEE  DDDDDDD     ");
         $display("    PP    PP  AA    AA  SS    SS  SS    SS  EE        DD    DD    ");
         $display("    PP    PP  AA    AA  SS        SS        EE        DD    DD    ");
         $display("    PPPPPPP   AAAAAAAA   SSSSSS    SSSSSS   EEEEE     DD    DD    ");
         $display("    PP        AA    AA        SS        SS  EE        DD    DD    ");
         $display("    PP        AA    AA  SS    SS  SS    SS  EE        DD    DD    ");
         $display("    PP        AA    AA   SSSSSS    SSSSSS   EEEEEEEE  DDDDDDD     ");
         $display("    ----------------------------------------------------------");
         if (warning_count == 0) begin
           $display("                        SIMULATION PASSED                     ");
         end
         else begin
           $display("                 SIMULATION PASSED with WARNINGS              ");
         end
         $display("                 test exit code = %0d (0x%h)", test_exit_code, test_exit_code);
         $display("    ----------------------------------------------------------");
      end
      else begin
         $display("    FFFFFFFF   AAAAAA   IIIIII  LL        EEEEEEEE  DDDDDDD       ");
         $display("    FF        AA    AA    II    LL        EE        DD    DD      ");
         $display("    FF        AA    AA    II    LL        EE        DD    DD      ");
         $display("    FFFFF     AAAAAAAA    II    LL        EEEEE     DD    DD      ");
         $display("    FF        AA    AA    II    LL        EE        DD    DD      ");
         $display("    FF        AA    AA    II    LL        EE        DD    DD      ");
         $display("    FF        AA    AA  IIIIII  LLLLLLLL  EEEEEEEE  DDDDDDD       ");
         $display("    ----------------------------------------------------------");
         if (sim_finished == 0) begin
            $display("                   SIMULATION FAILED - ABORTED              ");
         end
         else begin
            $display("                       SIMULATION FAILED                    ");
            $display("                 test exit code = %0d (0x%h)", test_exit_code, test_exit_code);
         end
         $display("    ----------------------------------------------------------");
      end
   end

endmodule : uvmt_cva6_tb
`default_nettype wire

`endif // __UVMT_CVA6_TB_SV__
