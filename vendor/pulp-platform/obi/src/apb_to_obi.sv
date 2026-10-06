// Copyright 2025 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Nils Wistoff <nwistoff@iis.ee.ethz.ch>

`include "common_cells/registers.svh"
`include "common_cells/assertions.svh"

/// An APB to OBI adapter.
module apb_to_obi #(
  /// The configuration of the manager port (output port).
  parameter      obi_pkg::obi_cfg_t ObiCfg = obi_pkg::ObiDefaultConfig,
  /// The APB request struct for the subordinate port (input port).
  parameter type apb_req_t = logic, // APB request struct
  /// The APB response struct for the subordinate port (input port).
  parameter type apb_rsp_t = logic, // APB response struct
  /// The OBI request struct for the manager port (output port).
  parameter type obi_req_t = logic,
  /// The OBI response struct for the manager port (output port).
  parameter type obi_rsp_t = logic
) (
  input  logic clk_i,
  input  logic rst_ni,
  // Subordinate APB port.
  input  apb_req_t apb_req_i,
  output apb_rsp_t apb_rsp_o,
  // Manager OBI port.
  output obi_req_t obi_req_o,
  input  obi_rsp_t obi_rsp_i
);

  typedef enum logic {RESP, ADDR} obi_phase_e;
  obi_phase_e obi_phase_d, obi_phase_q;

  // ---------------
  // Request Signals
  // ---------------

  assign obi_req_o.a.addr  = apb_req_i.paddr;
  assign obi_req_o.a.we    = apb_req_i.pwrite;
  // APB sets pstrb to '0 on reads. OBI expects '1.
  assign obi_req_o.a.be    = apb_req_i.pwrite ? apb_req_i.pstrb : '1;
  assign obi_req_o.a.wdata = apb_req_i.pwdata;
  // Only one outstanding transaction supported by APB
  assign obi_req_o.a.aid   = '0;

  // ----------------
  // Response Signals
  // ----------------

  assign apb_rsp_o.prdata  = obi_rsp_i.r.rdata;
  assign apb_rsp_o.pslverr = obi_rsp_i.r.err;

  // ----------------
  // Optional Signals
  // ----------------

  if (ObiCfg.UseRReady) begin : gen_rready
    // The APB requestor is always ready in the OBI response phase.
    assign obi_req_o.rready = 1'b1;
  end

  if (ObiCfg.OptionalCfg.UseAtop) begin : gen_atop
    // Tie to default.
    assign obi_req_o.a.a_optional.atop = obi_pkg::DefaultAtop;
  end


  if (ObiCfg.OptionalCfg.UseMemtype) begin : gen_memtype
    // Tie to default.
    assign obi_req_o.a.a_optional.atop = obi_pkg::DefaultMemtype;
  end

  if (ObiCfg.OptionalCfg.UseProt) begin : gen_prot
    // Bit 0: Inverted bit 2 of corresponding APB field.
    // Bit 1-2: Set to M-mode (2'b11) for privileged accesses,
    //                 U-mode (2'b00) for unprivileged accesses.
    assign obi_req_o.a.a_optional.prot = {{2{apb_req_i.pprot[0]}}, ~apb_req_i.pprot[2]};
  end

  if (ObiCfg.OptionalCfg.UseDbg) begin : gen_dbg
    // Tie off.
    assign obi_req_o.a.a_optional.dbg = 1'b0;
  end

  if (ObiCfg.OptionalCfg.AUserWidth != 0) begin : gen_auser
    // Tie off.
    assign obi_req_o.a.a_optional.auser = 1'b0;
  end

  if (ObiCfg.OptionalCfg.WUserWidth != 0) begin : gen_wuser
    // Tie off.
    assign obi_req_o.a.a_optional.wuser = 1'b0;
  end

  if (ObiCfg.OptionalCfg.MidWidth != 0) begin : gen_mid
    // Tie off.
    assign obi_req_o.a.a_optional.mid = 1'b0;
  end

  if (ObiCfg.OptionalCfg == obi_pkg::ObiMinimalOptionalConfig) begin : gen_min_a
    // Tie off.
    assign obi_req_o.a.a_optional = '0;
  end

  // ----------
  // Handshakes
  // ----------

  always_comb begin : obi_fsm
    obi_req_o.req    = 1'b0;
    apb_rsp_o.pready = 1'b0;
    obi_phase_d      = obi_phase_q;
    unique case (obi_phase_q)
      // Address phase (or idle).
      ADDR: begin
        // Need to wait for APB access phase to sample valid strobe and wdata.
        obi_req_o.req = apb_req_i.psel;
        // Downstream A handshake completed.
        if (obi_req_o.req && obi_rsp_i.gnt) obi_phase_d = RESP;
      end
      // Response phase.
      RESP: begin
        // Downstream R handshake completed.
        if (obi_rsp_i.rvalid) begin
          apb_rsp_o.pready = 1'b1;
          obi_phase_d = ADDR;
        end
      end
      // We should never reach this state.
      default: obi_phase_d = ADDR;
    endcase
  end

  `FF(obi_phase_q, obi_phase_d, ADDR, clk_i, rst_ni)

  // ----------
  // Assertions
  // ----------

  `ASSERT(penable, obi_phase_q == RESP |-> apb_req_i.penable, clk_i, !rst_ni,
      "APB PENABLE must be asserted during OBI RESP phase!")
  `ASSERT_INIT(no_integrity, !ObiCfg.Integrity,
      "Integrity not supported!")
  `ASSERT_INIT(no_achk, ObiCfg.OptionalCfg.AChkWidth == 0,
      "ACHK field not supported!")
  `ASSERT_INIT(equal_wdata_width, $bits(apb_req_i.pwdata) == $bits(obi_req_o.a.wdata),
      "WDATA width mismatch between APB and OBI ports!")
  `ASSERT_INIT(equal_be_width, $bits(apb_req_i.pstrb) == $bits(obi_req_o.a.be),
      "Strobe width mismatch between APB and OBI ports!")
  `ASSERT_INIT(equal_rdata_width, $bits(apb_rsp_o.prdata) == $bits(obi_rsp_i.r.rdata),
      "RDATA width mismatch between APB and OBI ports!")
  `ASSERT_INIT(equal_addr_width, $bits(apb_req_i.paddr) == $bits(obi_req_o.a.addr),
      "Address width mismatch between APB and OBI ports!")

endmodule
