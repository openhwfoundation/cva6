// Copyright 2025 Thales DIS France SAS
//
// Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
// You may obtain a copy of the License at https://solderpad.org/licenses/
//
// Original Author: Yannick Casamatta - Thales
// Date: June, 2025

`ifndef YPB_TYPEDEF_SVH
`define YPB_TYPEDEF_SVH

`define YPB_REQ_T(cfg, DATA_WIDTH) \
  struct packed { \
    logic                             vreq;          \
    logic                             preq;          \
    logic [cfg.VLEN-1:0]              vaddr;         \
    logic [cfg.PLEN-1:0]              paddr;         \
    logic [DATA_WIDTH/8-1:0]          be;            \
    logic [1:0]                       size;          \
    logic                             we;            \
    logic [DATA_WIDTH-1:0]            wdata;         \
    logic [cfg.IdWidth-1:0]           aid;           \
    ariane_pkg::amo_t                 atop;          \
    ariane_pkg::fu_op                 cbo_op;        \
    logic                             access_type;   \
    logic                             cacheable;     \
    logic                             bufferable;    \
    logic                             kill_req;      \
    logic                             rready;        \
  }

`define YPB_RSP_T(cfg, DATA_WIDTH) \
  struct packed {                                    \
    logic                             vgnt;          \
    logic                             pgnt;          \
    logic                             rvalid;        \
    logic [DATA_WIDTH-1:0]            rdata;         \
    logic [cfg.IdWidth-1:0]           rid;           \
    logic                             err;           \
  }

`endif  // YPB_TYPEDEF_SVH
