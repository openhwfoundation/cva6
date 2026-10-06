// Copyright 2025 Thales DIS France SAS
//
// Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
// You may obtain a copy of the License at https://solderpad.org/licenses/
//
// Authors: Yannick Casamatta
// Date: June, 2025
// Description: CVA6 Interface adapter YPB to OBI

`include "obi_types.svh"

module cva6_obi_adapter_subsystem
//  Parameters
#(
    parameter config_pkg::cva6_cfg_t CVA6Cfg = config_pkg::cva6_cfg_empty,

    // YPB Types
    parameter type ypb_fetch_req_t = logic,
    parameter type ypb_fetch_rsp_t = logic,
    parameter type ypb_store_req_t = logic,
    parameter type ypb_store_rsp_t = logic,
    parameter type ypb_amo_req_t = logic,
    parameter type ypb_amo_rsp_t = logic,
    parameter type ypb_load_req_t = logic,
    parameter type ypb_load_rsp_t = logic,
    parameter type ypb_mmu_ptw_req_t = logic,
    parameter type ypb_mmu_ptw_rsp_t = logic,
    parameter type ypb_zcmt_req_t = logic,
    parameter type ypb_zcmt_rsp_t = logic,

    parameter type noc_req_t  = logic,
    parameter type noc_resp_t = logic

)
//  Ports
(

    // Subsystem Clock - SUBSYSTEM
    input logic clk_i,
    // Asynchronous reset active low - SUBSYSTEM
    input logic rst_ni,

    //  OBI ports to upstream memory/peripherals
    // noc request OBI ports - SUBSYSTEM
    output noc_req_t  noc_req_o,
    // noc response OBI ports - SUBSYSTEM
    input  noc_resp_t noc_resp_i,

    // Fetch Request channel - FRONTEND
    input ypb_fetch_req_t ypb_fetch_req_i,
    // Fetch Response channel - FRONTEND
    output ypb_fetch_rsp_t ypb_fetch_rsp_o,
    // Store cache response - CACHES
    input ypb_store_req_t ypb_store_req_i,
    // Store cache request - CACHES
    output ypb_store_rsp_t ypb_store_rsp_o,
    // AMO cache request - CACHES
    input ypb_amo_req_t ypb_amo_req_i,
    // AMO cache response - CACHES
    output ypb_amo_rsp_t ypb_amo_rsp_o,
    // Load cache request - CACHES
    input ypb_load_req_t ypb_load_req_i,
    // Load cache response - CACHES
    output ypb_load_rsp_t ypb_load_rsp_o,
    // MMU Ptw cache request - CACHES
    input ypb_mmu_ptw_req_t ypb_mmu_ptw_req_i,
    // MMU Ptw cache response - CACHES
    output ypb_mmu_ptw_rsp_t ypb_mmu_ptw_rsp_o,
    // Zcmt cache response - CACHES
    input ypb_zcmt_req_t ypb_zcmt_req_i,
    // Zcmt cache response - CACHES
    output ypb_zcmt_rsp_t ypb_zcmt_rsp_o,

    //  I$
    // Instruction cache enable - CSR_REGFILE
    input  logic icache_en_i,
    // Flush the instruction cache - CONTROLLER
    input  logic icache_flush_i,
    // instructino cache miss - PERF_COUNTERS
    output logic icache_miss_o,

    //  D$
    // Cache management
    // Data cache enable - CSR_REGFILE
    input  logic dcache_enable_i,
    // Data cache flush - CONTROLLER
    input  logic dcache_flush_i,
    // Flush acknowledge - CONTROLLER
    output logic dcache_flush_ack_o,
    // Load or store miss - PERF_COUNTERS
    output logic dcache_miss_o,

    // Write buffer status to know if empty - EX_STAGE
    output logic wbuffer_empty_o,
    // Write buffer status to know if not non idempotent - EX_STAGE
    output logic wbuffer_not_ni_o

);


  //OBI FETCH
  `OBI_LOCALPARAM_TYPE_ALL(obi_fetch, CVA6Cfg.ObiFetchbusCfg);
  //OBI STORE
  `OBI_LOCALPARAM_TYPE_ALL(obi_store, CVA6Cfg.ObiStorebusCfg);
  //OBI AMO
  `OBI_LOCALPARAM_TYPE_ALL(obi_amo, CVA6Cfg.ObiAmobusCfg);
  //OBI LOAD
  `OBI_LOCALPARAM_TYPE_ALL(obi_load, CVA6Cfg.ObiLoadbusCfg);
  //OBI MMU_PTW
  `OBI_LOCALPARAM_TYPE_ALL(obi_mmu_ptw, CVA6Cfg.ObiMmuPtwbusCfg);
  //OBI ZCMT
  `OBI_LOCALPARAM_TYPE_ALL(obi_zcmt, CVA6Cfg.ObiZcmtbusCfg);

  // ----------------------
  // AMO Functions
  // ----------------------
  function automatic logic [5:0] amo_cva6_to_obi(logic [3:0] cva6_amo);
    case (cva6_amo)
      ariane_pkg::AMO_NONE: return obi_pkg::ATOPNONE;
      ariane_pkg::AMO_LR: return obi_pkg::ATOPLR;
      ariane_pkg::AMO_SC: return obi_pkg::ATOPSC;
      ariane_pkg::AMO_SWAP: return obi_pkg::AMOSWAP;
      ariane_pkg::AMO_ADD: return obi_pkg::AMOADD;
      ariane_pkg::AMO_AND: return obi_pkg::AMOAND;
      ariane_pkg::AMO_OR: return obi_pkg::AMOOR;
      ariane_pkg::AMO_XOR: return obi_pkg::AMOXOR;
      ariane_pkg::AMO_MAX: return obi_pkg::AMOMAX;
      ariane_pkg::AMO_MAXU: return obi_pkg::AMOMAXU;
      ariane_pkg::AMO_MIN: return obi_pkg::AMOMIN;
      ariane_pkg::AMO_MINU: return obi_pkg::AMOMINU;
      ariane_pkg::AMO_CAS1:
      return 6'h0C;  // unused, not part of riscv spec, but provided in OpenPiton
      ariane_pkg::AMO_CAS2:
      return 6'h0D;  // unused, not part of riscv spec, but provided in OpenPiton
    endcase
    return 8'b0;
  endfunction

  obi_fetch_req_t obi_fetch_req;
  obi_fetch_rsp_t obi_fetch_rsp;
  obi_store_req_t obi_store_req;
  obi_store_rsp_t obi_store_rsp;
  obi_amo_req_t obi_amo_req;
  obi_amo_rsp_t obi_amo_rsp;
  obi_load_req_t obi_load_req;
  obi_load_rsp_t obi_load_rsp;
  obi_mmu_ptw_req_t obi_mmu_ptw_req;
  obi_mmu_ptw_rsp_t obi_mmu_ptw_rsp;
  obi_zcmt_req_t obi_zcmt_req;
  obi_zcmt_rsp_t obi_zcmt_rsp;

  // Caches signals assignement

  assign dcache_flush_ack_o = dcache_flush_i;
  assign wbuffer_empty_o = 1'b1;
  assign wbuffer_not_ni_o = 1'b1;


  //REQ assignemnts

  assign noc_req_o.obi_fetch_req = obi_fetch_req;
  assign noc_req_o.obi_store_req = obi_store_req;
  assign noc_req_o.obi_amo_req = obi_amo_req;
  assign noc_req_o.obi_load_req = obi_load_req;
  assign noc_req_o.obi_mmu_ptw_req = obi_mmu_ptw_req;
  assign noc_req_o.obi_zcmt_req = obi_zcmt_req;

  assign obi_fetch_req.req = ypb_fetch_req_i.preq;
  assign obi_fetch_req.reqpar = !ypb_fetch_req_i.preq;
  assign obi_fetch_req.a.addr = ypb_fetch_req_i.paddr;
  assign obi_fetch_req.a.we = ypb_fetch_req_i.we;
  assign obi_fetch_req.a.be = ypb_fetch_req_i.be;
  assign obi_fetch_req.a.wdata = ypb_fetch_req_i.wdata;
  assign obi_fetch_req.a.aid = ypb_fetch_req_i.aid;
  assign obi_fetch_req.a.a_optional.auser = '0;
  assign obi_fetch_req.a.a_optional.wuser = '0;
  assign obi_fetch_req.a.a_optional.atop = '0;
  assign obi_fetch_req.a.a_optional.memtype[0] = '0;
  assign obi_fetch_req.a.a_optional.memtype[1] = ypb_fetch_req_i.cacheable;
  assign obi_fetch_req.a.a_optional.mid = '0;
  assign obi_fetch_req.a.a_optional.prot[0] = ypb_fetch_req_i.access_type;
  assign obi_fetch_req.a.a_optional.prot[2:1] = 2'b11;
  assign obi_fetch_req.a.a_optional.dbg = '0;
  assign obi_fetch_req.a.a_optional.achk = '0;
  assign obi_fetch_req.rready = ypb_fetch_req_i.rready;
  assign obi_fetch_req.rreadypar = !ypb_fetch_req_i.rready;

  assign obi_store_req.req = ypb_store_req_i.preq;
  assign obi_store_req.reqpar = !ypb_store_req_i.preq;
  assign obi_store_req.a.addr = ypb_store_req_i.paddr;
  assign obi_store_req.a.we = ypb_store_req_i.we;
  assign obi_store_req.a.be = ypb_store_req_i.be;
  assign obi_store_req.a.wdata = ypb_store_req_i.wdata;
  assign obi_store_req.a.aid = ypb_store_req_i.aid;
  assign obi_store_req.a.a_optional.auser = '0;
  assign obi_store_req.a.a_optional.wuser = '0;
  assign obi_store_req.a.a_optional.atop = '0;
  assign obi_store_req.a.a_optional.memtype[0] = '0;
  assign obi_store_req.a.a_optional.memtype[1] = ypb_store_req_i.cacheable;
  assign obi_store_req.a.a_optional.mid = '0;
  assign obi_store_req.a.a_optional.prot[0] = ypb_store_req_i.access_type;
  assign obi_store_req.a.a_optional.prot[2:1] = 2'b11;
  assign obi_store_req.a.a_optional.dbg = '0;
  assign obi_store_req.a.a_optional.achk = '0;
  assign obi_store_req.rready = ypb_store_req_i.rready;
  assign obi_store_req.rreadypar = !ypb_store_req_i.rready;

  assign obi_amo_req.req = ypb_amo_req_i.preq;
  assign obi_amo_req.reqpar = !ypb_amo_req_i.preq;
  assign obi_amo_req.a.addr = ypb_amo_req_i.paddr;
  assign obi_amo_req.a.we = ypb_amo_req_i.we;
  assign obi_amo_req.a.be = ypb_amo_req_i.be;
  assign obi_amo_req.a.wdata = ypb_amo_req_i.wdata;
  assign obi_amo_req.a.aid = ypb_amo_req_i.aid;
  assign obi_amo_req.a.a_optional.auser = '0;
  assign obi_amo_req.a.a_optional.wuser = '0;
  assign obi_amo_req.a.a_optional.atop = amo_cva6_to_obi(ypb_amo_req_i.atop);
  assign obi_amo_req.a.a_optional.memtype[0] = '0;
  assign obi_amo_req.a.a_optional.memtype[1] = ypb_amo_req_i.cacheable;
  assign obi_amo_req.a.a_optional.mid = '0;
  assign obi_amo_req.a.a_optional.prot[0] = ypb_amo_req_i.access_type;
  assign obi_amo_req.a.a_optional.prot[2:1] = 2'b11;
  assign obi_amo_req.a.a_optional.dbg = '0;
  assign obi_amo_req.a.a_optional.achk = '0;
  assign obi_amo_req.rready = ypb_amo_req_i.rready;
  assign obi_amo_req.rreadypar = !ypb_amo_req_i.rready;

  assign obi_load_req.req = ypb_load_req_i.preq;
  assign obi_load_req.reqpar = !ypb_load_req_i.preq;
  assign obi_load_req.a.addr = ypb_load_req_i.paddr;
  assign obi_load_req.a.we = ypb_load_req_i.we;
  assign obi_load_req.a.be = ypb_load_req_i.be;
  assign obi_load_req.a.wdata = ypb_load_req_i.wdata;
  assign obi_load_req.a.aid = ypb_load_req_i.aid;
  assign obi_load_req.a.a_optional.auser = '0;
  assign obi_load_req.a.a_optional.wuser = '0;
  assign obi_load_req.a.a_optional.atop = '0;
  assign obi_load_req.a.a_optional.memtype[0] = '0;
  assign obi_load_req.a.a_optional.memtype[1] = ypb_load_req_i.cacheable;
  assign obi_load_req.a.a_optional.mid = '0;
  assign obi_load_req.a.a_optional.prot[0] = ypb_load_req_i.access_type;
  assign obi_load_req.a.a_optional.prot[2:1] = 2'b11;
  assign obi_load_req.a.a_optional.dbg = '0;
  assign obi_load_req.a.a_optional.achk = '0;
  assign obi_load_req.rready = ypb_load_req_i.rready;
  assign obi_load_req.rreadypar = !ypb_load_req_i.rready;

  assign obi_mmu_ptw_req.req = ypb_mmu_ptw_req_i.preq;
  assign obi_mmu_ptw_req.reqpar = !ypb_mmu_ptw_req_i.preq;
  assign obi_mmu_ptw_req.a.addr = ypb_mmu_ptw_req_i.paddr;
  assign obi_mmu_ptw_req.a.we = ypb_mmu_ptw_req_i.we;
  assign obi_mmu_ptw_req.a.be = ypb_mmu_ptw_req_i.be;
  assign obi_mmu_ptw_req.a.wdata = ypb_mmu_ptw_req_i.wdata;
  assign obi_mmu_ptw_req.a.aid = ypb_mmu_ptw_req_i.aid;
  assign obi_mmu_ptw_req.a.a_optional.auser = '0;
  assign obi_mmu_ptw_req.a.a_optional.wuser = '0;
  assign obi_mmu_ptw_req.a.a_optional.atop = '0;
  assign obi_mmu_ptw_req.a.a_optional.memtype[0] = '0;
  assign obi_mmu_ptw_req.a.a_optional.memtype[1] = ypb_mmu_ptw_req_i.cacheable;
  assign obi_mmu_ptw_req.a.a_optional.mid = '0;
  assign obi_mmu_ptw_req.a.a_optional.prot[0] = ypb_mmu_ptw_req_i.access_type;
  assign obi_mmu_ptw_req.a.a_optional.prot[2:1] = 2'b11;
  assign obi_mmu_ptw_req.a.a_optional.dbg = '0;
  assign obi_mmu_ptw_req.a.a_optional.achk = '0;
  assign obi_mmu_ptw_req.rready = ypb_mmu_ptw_req_i.rready;
  assign obi_mmu_ptw_req.rreadypar = !ypb_mmu_ptw_req_i.rready;

  assign obi_zcmt_req.req = ypb_zcmt_req_i.preq;
  assign obi_zcmt_req.reqpar = !ypb_zcmt_req_i.preq;
  assign obi_zcmt_req.a.addr = ypb_zcmt_req_i.paddr;
  assign obi_zcmt_req.a.we = ypb_zcmt_req_i.we;
  assign obi_zcmt_req.a.be = ypb_zcmt_req_i.be;
  assign obi_zcmt_req.a.wdata = ypb_zcmt_req_i.wdata;
  assign obi_zcmt_req.a.aid = ypb_zcmt_req_i.aid;
  assign obi_zcmt_req.a.a_optional.auser = '0;
  assign obi_zcmt_req.a.a_optional.wuser = '0;
  assign obi_zcmt_req.a.a_optional.atop = '0;
  assign obi_zcmt_req.a.a_optional.memtype[0] = '0;
  assign obi_zcmt_req.a.a_optional.memtype[1] = ypb_zcmt_req_i.cacheable;
  assign obi_zcmt_req.a.a_optional.mid = '0;
  assign obi_zcmt_req.a.a_optional.prot[0] = ypb_zcmt_req_i.access_type;
  assign obi_zcmt_req.a.a_optional.prot[2:1] = 2'b11;
  assign obi_zcmt_req.a.a_optional.dbg = '0;
  assign obi_zcmt_req.a.a_optional.achk = '0;
  assign obi_zcmt_req.rready = ypb_zcmt_req_i.rready;
  assign obi_zcmt_req.rreadypar = !ypb_zcmt_req_i.rready;


  //RSP assignemnts

  assign obi_fetch_rsp = noc_resp_i.obi_fetch_rsp;
  assign obi_store_rsp = noc_resp_i.obi_store_rsp;
  assign obi_amo_rsp = noc_resp_i.obi_amo_rsp;
  assign obi_load_rsp = noc_resp_i.obi_load_rsp;
  assign obi_mmu_ptw_rsp = noc_resp_i.obi_mmu_ptw_rsp;
  assign obi_zcmt_rsp = noc_resp_i.obi_zcmt_rsp;

  assign ypb_fetch_rsp_o.pgnt = obi_fetch_rsp.gnt;
  assign ypb_fetch_rsp_o.rvalid = obi_fetch_rsp.rvalid;
  assign ypb_fetch_rsp_o.rdata = obi_fetch_rsp.r.rdata;
  assign ypb_fetch_rsp_o.rid = obi_fetch_rsp.r.rid;
  assign ypb_fetch_rsp_o.err = obi_fetch_rsp.r.err;
  assign ypb_fetch_rsp_o.vgnt = '1;

  assign ypb_store_rsp_o.pgnt = obi_store_rsp.gnt;
  assign ypb_store_rsp_o.rvalid = obi_store_rsp.rvalid;
  assign ypb_store_rsp_o.rdata = obi_store_rsp.r.rdata;
  assign ypb_store_rsp_o.rid = obi_store_rsp.r.rid;
  assign ypb_store_rsp_o.err = obi_store_rsp.r.err;
  assign ypb_store_rsp_o.vgnt = '1;

  assign ypb_amo_rsp_o.pgnt = obi_amo_rsp.gnt;
  assign ypb_amo_rsp_o.rvalid = obi_amo_rsp.rvalid;
  assign ypb_amo_rsp_o.rdata = obi_amo_rsp.r.rdata;
  assign ypb_amo_rsp_o.rid = obi_amo_rsp.r.rid;
  assign ypb_amo_rsp_o.err = obi_amo_rsp.r.err;
  assign ypb_amo_rsp_o.vgnt = '1;

  assign ypb_load_rsp_o.pgnt = obi_load_rsp.gnt;
  assign ypb_load_rsp_o.rvalid = obi_load_rsp.rvalid;
  assign ypb_load_rsp_o.rdata = obi_load_rsp.r.rdata;
  assign ypb_load_rsp_o.rid = obi_load_rsp.r.rid;
  assign ypb_load_rsp_o.err = obi_load_rsp.r.err;
  assign ypb_load_rsp_o.vgnt = '1;

  assign ypb_mmu_ptw_rsp_o.pgnt = obi_mmu_ptw_rsp.gnt;
  assign ypb_mmu_ptw_rsp_o.rvalid = obi_mmu_ptw_rsp.rvalid;
  assign ypb_mmu_ptw_rsp_o.rdata = obi_mmu_ptw_rsp.r.rdata;
  assign ypb_mmu_ptw_rsp_o.rid = obi_mmu_ptw_rsp.r.rid;
  assign ypb_mmu_ptw_rsp_o.err = obi_mmu_ptw_rsp.r.err;
  assign ypb_mmu_ptw_rsp_o.vgnt = '1;

  assign ypb_zcmt_rsp_o.pgnt = obi_zcmt_rsp.gnt;
  assign ypb_zcmt_rsp_o.rvalid = obi_zcmt_rsp.rvalid;
  assign ypb_zcmt_rsp_o.rdata = obi_zcmt_rsp.r.rdata;
  assign ypb_zcmt_rsp_o.rid = obi_zcmt_rsp.r.rid;
  assign ypb_zcmt_rsp_o.err = obi_zcmt_rsp.r.err;
  assign ypb_zcmt_rsp_o.vgnt = '1;


endmodule : cva6_obi_adapter_subsystem
