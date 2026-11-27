// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// Author: Michael Schaffner <schaffner@iis.ee.ethz.ch>, ETH Zurich
// Date: 19.03.2017
// Description: CVA6 top-level wrapper of the OpenPiton tile: breaks out the
//              L1.5 structs to logic vectors. The module name and the ports
//              are the ones the OpenPiton tile (tile.v.pyv) instantiates.
//
//              The configuration is the one of the cv64a6_openpiton target
//              (cva6_config_pkg), overridden by the parameters the tile
//              passes. The L1.5 types come from l15_pkg (OpenPiton
//              piton/design/chip/tile/l15/rtl/l15_pkg.sv, or
//              core/include/dummy_l15_pkg.sv outside OpenPiton).

`include "rvfi_types.svh"

module ariane_verilog_wrap
  import config_pkg::*;
#(
    // Parameters the OpenPiton tile sets
    parameter int unsigned NrPMPEntries = 8,
    parameter logic [63:0] DmBaseAddress = 64'h0,
    // OpenPiton is big endian: the L1.5 adapter always swaps the byte order
    parameter bit SwapEndianess = 1,
    parameter int unsigned NrExecuteRegionRules = 0,
    parameter logic [config_pkg::NrMaxRules*64-1:0] ExecuteRegionAddrBase = '0,
    parameter logic [config_pkg::NrMaxRules*64-1:0] ExecuteRegionLength = '0,
    parameter int unsigned NrCachedRegionRules = 0,
    parameter logic [config_pkg::NrMaxRules*64-1:0] CachedRegionAddrBase = '0,
    parameter logic [config_pkg::NrMaxRules*64-1:0] CachedRegionLength = '0,
    // Non idempotent regions
    parameter int unsigned NrNonIdempotentRules = 1,
    parameter logic [config_pkg::NrMaxRules*64-1:0] NonIdempotentAddrBase = 64'h00C0000000,
    parameter logic [config_pkg::NrMaxRules*64-1:0] NonIdempotentLength = 64'hFFFFFFFFFF
) (
    input clk_i,
    input reset_l,  // this is an openpiton-specific name, do not change (hier. paths in TB use this)
    output spc_grst_l,  // this is an openpiton-specific name, do not change (hier. paths in TB use this)
    // Core ID, Cluster ID and boot address are considered more or less static
    input [63:0] boot_addr_i,  // reset boot address
    input [63:0] hart_id_i,  // hart id in a multicore environment (reflected in a CSR)
    // Interrupt inputs
    input [1:0] irq_i,  // level sensitive IR lines, mip & sip (async)
    input ipi_i,  // inter-processor interrupts (async)
    // Timer facilities
    input time_irq_i,  // timer interrupt in (async)
    input debug_req_i,  // debug request (async)
    // L15 (memory side)
    output [$bits(l15_pkg::l15_req_t)-1:0] l15_req_o,
    input [$bits(l15_pkg::l15_rtrn_t)-1:0] l15_rtrn_i
);

  //  Configuration: the cv64a6_openpiton target, with the memory map and the
  //  PMP of the tile
  function automatic config_pkg::cva6_user_cfg_t openpiton_user_cfg();
    config_pkg::cva6_user_cfg_t cfg = cva6_config_pkg::cva6_cfg;
    cfg.MemSubsystem = MEM_HPDCACHE_L15;
    cfg.NrPMPEntries = NrPMPEntries;
    cfg.DmBaseAddress = DmBaseAddress;
    cfg.NrNonIdempotentRules = NrNonIdempotentRules;
    cfg.NonIdempotentAddrBase = NonIdempotentAddrBase;
    cfg.NonIdempotentLength = NonIdempotentLength;
    cfg.NrExecuteRegionRules = NrExecuteRegionRules;
    cfg.ExecuteRegionAddrBase = ExecuteRegionAddrBase;
    cfg.ExecuteRegionLength = ExecuteRegionLength;
    cfg.NrCachedRegionRules = NrCachedRegionRules;
    cfg.CachedRegionAddrBase = CachedRegionAddrBase;
    cfg.CachedRegionLength = CachedRegionLength;
    return cfg;
  endfunction

  localparam config_pkg::cva6_cfg_t CVA6Cfg = build_config_pkg::build_config(openpiton_user_cfg());

  if (!SwapEndianess) begin : gen_little_endian_l15_assert
    $fatal(1, "The L1.5 adapter only supports the big endian L1.5 of OpenPiton (SwapEndianess=1)");
  end

  //  RVFI probes, left open (OpenPiton traces the PC with PITON_ARIANE)
  localparam type rvfi_probes_instr_t = `RVFI_PROBES_INSTR_T(CVA6Cfg);
  localparam type rvfi_probes_csr_t = `RVFI_PROBES_CSR_T(CVA6Cfg);
  localparam type rvfi_probes_t = struct packed {
    rvfi_probes_csr_t   csr;
    rvfi_probes_instr_t instr;
  };

  // assign bitvector to packed struct and vice versa
  l15_pkg::l15_req_t  l15_req;
  l15_pkg::l15_rtrn_t l15_rtrn;

  assign l15_req_o = l15_req;
  assign l15_rtrn  = l15_rtrn_i;

  /////////////////////////////
  // Core wakeup mechanism
  /////////////////////////////

  // this is a workaround,
  // we basically wait for 32k cycles such that the SRAMs in openpiton can initialize
  // 128KB..8K cycles
  // 256KB..16K cycles
  // etc, so this should be enough for 512k per tile

  logic [15:0] wake_up_cnt_d, wake_up_cnt_q;
  logic rst_n;

  assign wake_up_cnt_d = (wake_up_cnt_q[$high(wake_up_cnt_q)]) ? wake_up_cnt_q : wake_up_cnt_q + 1;

  always_ff @(posedge clk_i or negedge reset_l) begin : p_regs
    if (~reset_l) begin
      wake_up_cnt_q <= 0;
    end else begin
      wake_up_cnt_q <= wake_up_cnt_d;
    end
  end

  // reset gate this
  assign rst_n = wake_up_cnt_q[$high(wake_up_cnt_q)] & reset_l;

  /////////////////////////////
  // synchronizers
  /////////////////////////////

  logic [1:0] irq;
  logic ipi, time_irq, debug_req;

  // reset synchronization
  synchronizer i_sync (
      .clk        (clk_i),
      .presyncdata(rst_n),
      .syncdata   (spc_grst_l)
  );

  // interrupts
  for (genvar k = 0; k < $size(irq_i); k++) begin : gen_irq_sync
    synchronizer i_irq_sync (
        .clk        (clk_i),
        .presyncdata(irq_i[k]),
        .syncdata   (irq[k])
    );
  end

  synchronizer i_ipi_sync (
      .clk        (clk_i),
      .presyncdata(ipi_i),
      .syncdata   (ipi)
  );

  synchronizer i_timer_sync (
      .clk        (clk_i),
      .presyncdata(time_irq_i),
      .syncdata   (time_irq)
  );

  synchronizer i_debug_sync (
      .clk        (clk_i),
      .presyncdata(debug_req_i),
      .syncdata   (debug_req)
  );

  /////////////////////////////
  // CVA6 instance
  /////////////////////////////

  // The OpenPiton testbench reads the PITON_ARIANE PC probes of this
  // instance at ariane.gen_cva6.i_cva6.i_cva6_pipeline.{piton_pc_vld,piton_pc}
  // (piton/verif/env/manycore/cross_module.h.pyv).
  cva6_top #(
      .CVA6Cfg      (CVA6Cfg),
      .rvfi_probes_t(rvfi_probes_t),
      .noc_req_t    (l15_pkg::l15_req_t),
      .noc_resp_t   (l15_pkg::l15_rtrn_t)
  ) ariane (
      .clk_i        (clk_i),
      .rst_ni       (spc_grst_l),
      .boot_addr_i  (boot_addr_i[CVA6Cfg.VLEN-1:0]),
      .hart_id_i    (hart_id_i[CVA6Cfg.XLEN-1:0]),
      .irq_i        (irq),
      .ipi_i        (ipi),
      .time_irq_i   (time_irq),
      .debug_req_i  (debug_req),
      .rvfi_probes_o(  /* unused */),
      .cvxif_req_o  (  /* unused */),
      .cvxif_resp_i ('0),
      .noc_req_o    (l15_req),
      .noc_resp_i   (l15_rtrn),
      .dcls_alarm_o (  /* unused */)
  );

endmodule  // ariane_verilog_wrap
