// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Author: Michael Rogenmoser <michaero@iis.ee.ethz.ch>

module obi_sim_mem import obi_pkg::*; #(
  parameter obi_pkg::obi_cfg_t ObiCfg = obi_pkg::ObiDefaultConfig,
  parameter type obi_req_t = logic,
  parameter type obi_rsp_t = logic,
  parameter type obi_r_chan_t = logic,
  parameter bit WarnUninitialized = 1'b0,
  parameter bit ClearErrOnAccess = 1'b0,
  parameter time ApplDelay = 0ps,
  parameter time AcqDelay = 0ps
) (
  input  logic clk_i,
  input  logic rst_ni,
  input  obi_req_t obi_req_i,
  output obi_rsp_t obi_rsp_o,

  output logic                          mon_valid_o,
  output logic                          mon_we_o,
  output logic [  ObiCfg.AddrWidth-1:0] mon_addr_o,
  output logic [  ObiCfg.DataWidth-1:0] mon_wdata_o,
  output logic [ObiCfg.DataWidth/8-1:0] mon_be_o,
  output logic [    ObiCfg.IdWidth-1:0] mon_id_o
);
  if (ObiCfg.OptionalCfg.UseAtop) $error("Please use an ATOP resolver before sim mem.");
  if (ObiCfg.Integrity) $error("Integrity not supported");
  if (ObiCfg.OptionalCfg.UseProt) $warning("Prot not checked!");
  if (ObiCfg.OptionalCfg.UseMemtype) $warning("Memtype not checked!");

  typedef logic [ObiCfg.AddrWidth-1:0] addr_t;

  obi_r_chan_t rsp_queue[$];

  logic [7:0] mem[addr_t];
  logic rsp_ready;

  if (ObiCfg.UseRReady) begin : gen_rready
    assign rsp_ready = obi_req_i.rready;
  end else begin : gen_no_rready
    assign rsp_ready = 1'b1;
  end

  logic mon_valid;
  logic mon_we;
  logic [ObiCfg.AddrWidth-1:0] mon_addr;
  logic [ObiCfg.DataWidth-1:0] mon_wdata;
  logic [ObiCfg.DataWidth/8-1:0] mon_be;
  logic [ObiCfg.IdWidth-1:0] mon_id;

  assign mon_we    = obi_req_i.a.we;
  assign mon_addr  = obi_req_i.a.addr;
  assign mon_wdata = obi_req_i.a.wdata;
  assign mon_be    = obi_req_i.a.be;
  assign mon_id    = obi_req_i.a.aid;

  initial begin
    fork
      // Request Handling
      forever begin
        // Start cycle
        @(posedge clk_i);
        #(ApplDelay);
        // Indicate ready
        obi_rsp_o.gnt = 1'b1;
        mon_valid = 1'b0;
        // End of cycle
        #(AcqDelay-ApplDelay);
        // If requesting
        if (obi_req_i.req) begin
          mon_valid = 1'b1;
          if (obi_req_i.a.we) begin
            automatic obi_r_chan_t write_rsp;
            // write memory
            for (int i = 0; i < ObiCfg.DataWidth/8; i++) begin
              if (obi_req_i.a.be[i]) begin
                mem[obi_req_i.a.addr+i] = obi_req_i.a.wdata[8*i+:8];
              end
            end
            // write response
            write_rsp = 'x;
            write_rsp.rid = obi_req_i.a.aid;
            write_rsp.err = 1'b0;
            write_rsp.r_optional = '0;
            rsp_queue.push_back(write_rsp);
          end else begin
            // read response
            automatic obi_r_chan_t read_rsp = 'x;
            if (!mem.exists(obi_req_i.a.addr)) begin
              if (WarnUninitialized) begin
                $warning("%t - Access to non-initialized address at 0x%016x by ID 0x%x.",
                         $realtime, obi_req_i.a.addr, obi_req_i.a.aid);
              end
            end else begin
              for (int i = 0; i < ObiCfg.DataWidth/8; i++) begin
                read_rsp.rdata[8*i+:8] = mem[obi_req_i.a.addr+i];
              end
            end
            read_rsp.rid = obi_req_i.a.aid;
            read_rsp.err = 1'b0;
            read_rsp.r_optional = '0;
            rsp_queue.push_back(read_rsp);
          end
        end
      end
      // Response Handling
      forever begin
        // Start cycle
        @(posedge clk_i);
        #(ApplDelay);
        obi_rsp_o.rvalid = 1'b0;
        if (rsp_queue.size() != 0) begin
          obi_rsp_o.r = rsp_queue[0];
          obi_rsp_o.rvalid = 1'b1;
          // End of cycle
          #(AcqDelay-ApplDelay);
          if (rsp_ready) begin
            void'(rsp_queue.pop_front());
          end
        end
      end
    join
  end

  initial begin
    mon_valid_o = '0;
    mon_we_o = '0;
    mon_addr_o = '0;
    mon_wdata_o = '0;
    mon_be_o = '0;
    mon_id_o = '0;
    wait (rst_ni);
    forever begin
      @(posedge clk_i);
      mon_valid_o <= #(ApplDelay) mon_valid;
      mon_we_o <= #(ApplDelay) mon_we;
      mon_addr_o <= #(ApplDelay) mon_addr;
      mon_wdata_o <= #(ApplDelay) mon_wdata;
      mon_be_o <= #(ApplDelay) mon_be;
      mon_id_o <= #(ApplDelay) mon_id;
    end
  end
endmodule

`include "obi/typedef.svh"
`include "obi/assign.svh"

module obi_sim_mem_intf import obi_pkg::*; #(
  parameter obi_pkg::obi_cfg_t ObiCfg = obi_pkg::ObiDefaultConfig,
  parameter bit WarnUninitialized = 1'b0,
  parameter bit ClearErrOnAccess = 1'b0,
  parameter time ApplDelay = 0ps,
  parameter time AcqDelay = 0ps
) (
  input logic clk_i,
  input logic rst_ni,
  OBI_BUS.Subordinate obi_sbr,

  output logic                          mon_valid_o,
  output logic                          mon_we_o,
  output logic [  ObiCfg.AddrWidth-1:0] mon_addr_o,
  output logic [  ObiCfg.DataWidth-1:0] mon_wdata_o,
  output logic [ObiCfg.DataWidth/8-1:0] mon_be_o,
  output logic [    ObiCfg.IdWidth-1:0] mon_id_o
);

  `OBI_TYPEDEF_ALL(obi, ObiCfg)

  obi_req_t obi_req;
  obi_rsp_t obi_rsp;

  `OBI_ASSIGN_TO_REQ(obi_req, obi_sbr, ObiCfg)
  `OBI_ASSIGN_FROM_RSP(obi_sbr, obi_rsp, ObiCfg)

  obi_sim_mem #(
    .ObiCfg           (ObiCfg),
    .obi_req_t        (obi_req_t),
    .obi_rsp_t        (obi_rsp_t),
    .obi_r_chan_t     (obi_r_chan_t),
    .WarnUninitialized(WarnUninitialized),
    .ClearErrOnAccess (ClearErrOnAccess),
    .ApplDelay        (ApplDelay),
    .AcqDelay         (AcqDelay)
  ) i_obi_sim_mem (
    .clk_i,
    .rst_ni,
    .obi_req_i(obi_req),
    .obi_rsp_o(obi_rsp),

    .mon_valid_o,
    .mon_we_o,
    .mon_addr_o,
    .mon_wdata_o,
    .mon_be_o,
    .mon_id_o
  );

endmodule
