// Copyright 2025 Thales DIS France SAS
//
// Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
// You may obtain a copy of the License at https://solderpad.org/licenses/
//
// Original Author: Yannick Casamatta - Thales
// Date: June, 2025

`ifndef AXI_TYPEDEF_SVH
`define AXI_TYPEDEF_SVH

`define AXI_AR_CHAN_T(cfg) \
  struct packed { \
    logic [cfg.AxiIdWidth-1:0]   id; \
    logic [cfg.AxiAddrWidth-1:0] addr; \
    axi_pkg::len_t                   len; \
    axi_pkg::size_t                  size; \
    axi_pkg::burst_t                 burst; \
    logic                            lock; \
    axi_pkg::cache_t                 cache; \
    axi_pkg::prot_t                  prot; \
    axi_pkg::qos_t                   qos; \
    axi_pkg::region_t                region; \
    logic [cfg.AxiUserWidth-1:0] user; \
  }

`define AXI_AW_CHAN_T(cfg) \
  struct packed { \
    logic [cfg.AxiIdWidth-1:0]   id; \
    logic [cfg.AxiAddrWidth-1:0] addr; \
    axi_pkg::len_t                   len; \
    axi_pkg::size_t                  size; \
    axi_pkg::burst_t                 burst; \
    logic                            lock; \
    axi_pkg::cache_t                 cache; \
    axi_pkg::prot_t                  prot; \
    axi_pkg::qos_t                   qos; \
    axi_pkg::region_t                region; \
    axi_pkg::atop_t                  atop; \
    logic [cfg.AxiUserWidth-1:0] user; \
  }

`define AXI_W_CHAN_T(cfg) \
  struct packed { \
    logic [cfg.AxiDataWidth-1:0]     data; \
    logic [(cfg.AxiDataWidth/8)-1:0] strb; \
    logic                                last; \
    logic [cfg.AxiUserWidth-1:0]     user; \
  }

`define AXI_B_CHAN_T(cfg) \
  struct packed { \
    logic [cfg.AxiIdWidth-1:0]   id; \
    axi_pkg::resp_t                  resp; \
    logic [cfg.AxiUserWidth-1:0] user; \
  }

`define AXI_R_CHAN_T(cfg) \
  struct packed { \
    logic [cfg.AxiIdWidth-1:0]   id; \
    logic [cfg.AxiDataWidth-1:0] data; \
    axi_pkg::resp_t                  resp; \
    logic                            last; \
    logic [cfg.AxiUserWidth-1:0] user; \
  }

`define AXI_REQ_T(cfg) \
  struct packed { \
    axi_aw_chan_t aw; \
    logic         aw_valid; \
    axi_w_chan_t  w; \
    logic         w_valid; \
    logic         b_ready; \
    axi_ar_chan_t ar; \
    logic         ar_valid; \
    logic         r_ready; \
  }

`define AXI_RSP_T(cfg) \
  struct packed { \
    logic    aw_ready; \
    logic    ar_ready; \
    logic    w_ready; \
    logic    b_valid; \
    axi_b_chan_t b; \
    logic    r_valid; \
    axi_r_chan_t r; \
  }

`endif  // AXI_TYPEDEF_SVH
