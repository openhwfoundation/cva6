// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Michael Rogenmoser <michaero@iis.ee.ethz.ch>

module obi_sram_shim #(
  /// The OBI configuration for all ports.
  parameter obi_pkg::obi_cfg_t ObiCfg    = obi_pkg::ObiDefaultConfig,
  /// The request struct for all ports.
  parameter type               obi_req_t = logic,
  /// The response struct for all ports.
  parameter type               obi_rsp_t = logic
) (
  input  logic                          clk_i,
  input  logic                          rst_ni,

  input  obi_req_t                      obi_req_i,
  output obi_rsp_t                      obi_rsp_o,

  output logic                          req_o,
  output logic                          we_o,
  output logic [  ObiCfg.AddrWidth-1:0] addr_o,
  output logic [  ObiCfg.DataWidth-1:0] wdata_o,
  output logic [ObiCfg.DataWidth/8-1:0] be_o,

  input  logic                          gnt_i,
  input  logic [  ObiCfg.DataWidth-1:0] rdata_i
);

  if (ObiCfg.OptionalCfg.UseAtop) $error("Please use an ATOP resolver before sram shim.");
  if (ObiCfg.UseRReady) $error("Please use an RReady Fifo before sram shim.");
  if (ObiCfg.Integrity) $error("Integrity not yet supported, WIP");
  if (ObiCfg.OptionalCfg.UseProt) $warning("Prot not checked!");
  if (ObiCfg.OptionalCfg.UseMemtype) $warning("Memtype not checked!");

  logic rvalid_d, rvalid_q;
  logic [ObiCfg.IdWidth-1:0] id_d, id_q;

  assign req_o   = obi_req_i.req;
  assign we_o    = obi_req_i.a.we;
  assign addr_o  = obi_req_i.a.addr;
  assign wdata_o = obi_req_i.a.wdata;
  assign be_o    = obi_req_i.a.be;

  assign obi_rsp_o.gnt     = gnt_i;
  assign obi_rsp_o.rvalid  = rvalid_q;
  assign obi_rsp_o.r.rdata = rdata_i;
  assign obi_rsp_o.r.rid   = id_q;
  assign obi_rsp_o.r.err   = 1'b0;
  assign obi_rsp_o.r.r_optional = '0;

  assign rvalid_d = obi_req_i.req & obi_rsp_o.gnt;
  assign id_d     = obi_req_i.a.aid;

  always_ff @(posedge clk_i or negedge rst_ni) begin : proc_sram_state
    if(!rst_ni) begin
      rvalid_q <= 1'b0;
      id_q     <= '0;
    end else begin
      rvalid_q <= rvalid_d;
      id_q     <= id_d;
    end
  end

endmodule
