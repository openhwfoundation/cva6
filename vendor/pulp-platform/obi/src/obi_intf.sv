// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Michael Rogenmoser <michaero@iis.ee.ethz.ch>

interface OBI_BUS #(
  parameter obi_pkg::obi_cfg_t OBI_CFG          = obi_pkg::ObiDefaultConfig,
  parameter type               obi_a_optional_t = logic,
  parameter type               obi_r_optional_t = logic
) ();
  logic                           req;
  logic                           reqpar;
  logic                           gnt;
  logic                           gntpar;
  logic [  OBI_CFG.AddrWidth-1:0] addr;
  logic                           we;
  logic [OBI_CFG.DataWidth/8-1:0] be;
  logic [  OBI_CFG.DataWidth-1:0] wdata;
  logic [    OBI_CFG.IdWidth-1:0] aid;
  obi_a_optional_t                a_optional;

  logic                           rvalid;
  logic                           rvalidpar;
  logic                           rready;
  logic                           rreadypar;
  logic [  OBI_CFG.DataWidth-1:0] rdata;
  logic [    OBI_CFG.IdWidth-1:0] rid;
  logic                           err;
  obi_r_optional_t                r_optional;

  modport Manager (
    output req,
    output reqpar,
    input  gnt,
    input  gntpar,
    output addr,
    output we,
    output be,
    output wdata,
    output aid,
    output a_optional,

    input  rvalid,
    input  rvalidpar,
    output rready,
    output rreadypar,
    input  rdata,
    input  rid,
    input  err,
    input  r_optional
  );

  modport Subordinate (
    input  req,
    input  reqpar,
    output gnt,
    output gntpar,
    input  addr,
    input  we,
    input  be,
    input  wdata,
    input  aid,
    input  a_optional,

    output rvalid,
    output rvalidpar,
    input  rready,
    input  rreadypar,
    output rdata,
    output rid,
    output err,
    output r_optional
  );

  modport Monitor (
    input req,
    input reqpar,
    input gnt,
    input gntpar,
    input addr,
    input we,
    input be,
    input wdata,
    input aid,
    input a_optional,

    input rvalid,
    input rvalidpar,
    input rready,
    input rreadypar,
    input rdata,
    input rid,
    input err,
    input r_optional
  );


endinterface

interface OBI_BUS_DV #(
  parameter obi_pkg::obi_cfg_t OBI_CFG          = obi_pkg::ObiDefaultConfig,
  parameter type               obi_a_optional_t = logic,
  parameter type               obi_r_optional_t = logic
) (
  input logic clk_i,
  input logic rst_ni
);
  logic                           req;
  logic                           reqpar;
  logic                           gnt;
  logic                           gntpar;
  logic [  OBI_CFG.AddrWidth-1:0] addr;
  logic                           we;
  logic [OBI_CFG.DataWidth/8-1:0] be;
  logic [  OBI_CFG.DataWidth-1:0] wdata;
  logic [    OBI_CFG.IdWidth-1:0] aid;
  obi_a_optional_t                a_optional;

  logic                           rvalid;
  logic                           rvalidpar;
  logic                           rready;
  logic                           rreadypar;
  logic [  OBI_CFG.DataWidth-1:0] rdata;
  logic [    OBI_CFG.IdWidth-1:0] rid;
  logic                           err;
  obi_r_optional_t                r_optional;

  modport Manager (
    output req,
    output reqpar,
    input  gnt,
    input  gntpar,
    output addr,
    output we,
    output be,
    output wdata,
    output aid,
    output a_optional,

    input  rvalid,
    input  rvalidpar,
    output rready,
    output rreadypar,
    input  rdata,
    input  rid,
    input  err,
    input  r_optional
  );

  modport Subordinate (
    input  req,
    input  reqpar,
    output gnt,
    output gntpar,
    input  addr,
    input  we,
    input  be,
    input  wdata,
    input  aid,
    input  a_optional,

    output rvalid,
    output rvalidpar,
    input  rready,
    input  rreadypar,
    output rdata,
    output rid,
    output err,
    output r_optional
  );

  modport Monitor (
    input req,
    input reqpar,
    input gnt,
    input gntpar,
    input addr,
    input we,
    input be,
    input wdata,
    input aid,
    input a_optional,

    input rvalid,
    input rvalidpar,
    input rready,
    input rreadypar,
    input rdata,
    input rid,
    input err,
    input r_optional
  );

// pragma translate_off
`ifndef VERILATOR

  // A channel
  // OBI spec R3.1
  assert property (@(posedge clk_i) disable iff (!rst_ni) req |-> ##[1:$] gnt);
  assert property (@(posedge clk_i) disable iff (!rst_ni) (req && !gnt |=> $stable(addr)));
  assert property (@(posedge clk_i) disable iff (!rst_ni) (req && !gnt |=> $stable(we)));
  assert property (@(posedge clk_i) disable iff (!rst_ni) (req && !gnt |=> $stable(be)));
  assert property (@(posedge clk_i) disable iff (!rst_ni) (req && !gnt |=> $stable(wdata)));
  assert property (@(posedge clk_i) disable iff (!rst_ni) (req && !gnt |=> $stable(aid)));
  assert property (@(posedge clk_i) disable iff (!rst_ni) (req && !gnt |=> $stable(a_optional)));
  assert property (@(posedge clk_i) disable iff (!rst_ni) (req && !gnt |=> req));
  if (OBI_CFG.Integrity) begin : gen_integrity_req_check
    assert property (@(posedge clk_i) disable iff (!rst_ni) (req && ~reqpar));
    assert property (@(posedge clk_i) disable iff (!rst_ni) (gnt && ~gntpar));
    // TODO: achk?
  end

  // R channel
  if (OBI_CFG.UseRReady) begin : gen_rready_checks
    // OBI spec R4.1
    assert property (@(posedge clk_i) disable iff (!rst_ni) rvalid |-> ##[1:$] rready);
    assert property (@(posedge clk_i) disable iff (!rst_ni) (rvalid && !rready |=> $stable(rdata)));
    assert property (@(posedge clk_i) disable iff (!rst_ni) (rvalid && !rready |=> $stable(rid)));
    assert property (@(posedge clk_i) disable iff (!rst_ni) (rvalid && !rready |=> $stable(err)));
    assert property (@(posedge clk_i) disable iff (!rst_ni) (rvalid && !rready |=>
                     $stable(r_optional)));
    assert property (@(posedge clk_i) disable iff (!rst_ni) (rvalid && !rready |=> rvalid));
  end
  if (OBI_CFG.Integrity) begin : gen_integrity_rsp_check
    assert property (@(posedge clk_i) disable iff (!rst_ni) (rvalid && ~rvalidpar));
    if (OBI_CFG.UseRReady) begin : gen_rready_integrity_check
      assert property (@(posedge clk_i) disable iff (!rst_ni) (rready && ~rreadypar));
    end
  end

  if (!OBI_CFG.BeFull) begin : gen_be_checks
    // OBI spec R7
    assert property (@(posedge clk_i) disable iff (!rst_ni) (req && gnt && we |-> be != '0));
    // TODO R7: assert be contiguous
  end

`endif
// pragma translate_on

endinterface
