// Copyright 2025 Thales DIS France SAS
//
// Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
// You may obtain a copy of the License at https://solderpad.org/licenses/
//
// Description: CVA6-local OBI type-declaration macros. Depends only on `obi_pkg`.

`ifndef OBI_TYPES_SVH
`define OBI_TYPES_SVH

// Anonymous-struct forms of the vendored `OBI_TYPEDEF_*` macros, usable as type expressions.
`define OBI_DECL_ALL_A_OPTIONAL(AUSER_WIDTH, WUSER_WIDTH, MID_WIDTH, ACHK_WIDTH) \
  struct packed {                                                                \
    logic [ AUSER_WIDTH-1:0] auser;                                              \
    logic [ WUSER_WIDTH-1:0] wuser;                                              \
    obi_pkg::atop_t          atop;                                               \
    obi_pkg::memtype_t       memtype;                                            \
    logic [   MID_WIDTH-1:0] mid;                                                \
    obi_pkg::prot_t          prot;                                               \
    logic                    dbg;                                                \
    logic [  ACHK_WIDTH-1:0] achk;                                               \
  }

`define OBI_DECL_A_CHAN_T(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH, a_optional_t) \
  struct packed {                                                         \
    logic [  ADDR_WIDTH-1:0] addr;                                        \
    logic                    we;                                          \
    logic [DATA_WIDTH/8-1:0] be;                                          \
    logic [  DATA_WIDTH-1:0] wdata;                                       \
    logic [    ID_WIDTH-1:0] aid;                                         \
    a_optional_t             a_optional;                                  \
  }

`define OBI_DECL_INTEGRITY_REQ_T(a_chan_t) \
  struct packed {                          \
    a_chan_t a;                            \
    logic    req;                          \
    logic    rready;                       \
    logic    reqpar;                       \
    logic    rreadypar;                    \
  }

`define OBI_DECL_ALL_R_OPTIONAL(RUSER_WIDTH, RCHK_WIDTH) \
  struct packed {                                        \
    logic [RUSER_WIDTH-1:0] ruser;                       \
    logic                   exokay;                      \
    logic [ RCHK_WIDTH-1:0] rchk;                        \
  }

`define OBI_DECL_R_CHAN_T(RDATA_WIDTH, ID_WIDTH, r_optional_t) \
  struct packed {                                              \
    logic [RDATA_WIDTH-1:0] rdata;                             \
    logic [   ID_WIDTH-1:0] rid;                               \
    logic                   err;                               \
    r_optional_t            r_optional;                        \
  }

`define OBI_DECL_INTEGRITY_RSP_T(r_chan_t) \
  struct packed {                          \
    r_chan_t r;                            \
    logic    gnt;                          \
    logic    gntpar;                       \
    logic    rvalid;                       \
    logic    rvalidpar;                    \
  }

// Same, driven by an `obi_pkg::obi_cfg_t` instead of loose widths.
`define OBI_CFG_ALL_A_OPTIONAL_T(cfg) \
  `OBI_DECL_ALL_A_OPTIONAL(cfg.OptionalCfg.AUserWidth, cfg.OptionalCfg.WUserWidth, cfg.OptionalCfg.MidWidth, cfg.OptionalCfg.AChkWidth)
`define OBI_CFG_A_CHAN_T(cfg, a_optional_t) \
  `OBI_DECL_A_CHAN_T(cfg.AddrWidth, cfg.DataWidth, cfg.IdWidth, a_optional_t)
`define OBI_CFG_INTEGRITY_REQ_T(a_chan_t) \
  `OBI_DECL_INTEGRITY_REQ_T(a_chan_t)
`define OBI_CFG_ALL_R_OPTIONAL_T(cfg) \
  `OBI_DECL_ALL_R_OPTIONAL(cfg.OptionalCfg.RUserWidth, cfg.OptionalCfg.RChkWidth)
`define OBI_CFG_R_CHAN_T(cfg, r_optional_t) \
  `OBI_DECL_R_CHAN_T(cfg.DataWidth, cfg.IdWidth, r_optional_t)
`define OBI_CFG_INTEGRITY_RSP_T(r_chan_t) \
  `OBI_DECL_INTEGRITY_RSP_T(r_chan_t)

// All six types of one OBI bus; `keyword`/`separator` select declaration kind and joiner.
`define OBI_GENERIC_PARAM_TYPE_ALL(obi_t, cfg, keyword, separator)                          \
  keyword type obi_t``_a_optional_t = `OBI_CFG_ALL_A_OPTIONAL_T(cfg) separator              \
  keyword type obi_t``_a_chan_t = `OBI_CFG_A_CHAN_T(cfg, obi_t``_a_optional_t) separator    \
  keyword type obi_t``_req_t = `OBI_CFG_INTEGRITY_REQ_T(obi_t``_a_chan_t) separator         \
  keyword type obi_t``_r_optional_t = `OBI_CFG_ALL_R_OPTIONAL_T(cfg) separator              \
  keyword type obi_t``_r_chan_t = `OBI_CFG_R_CHAN_T(cfg, obi_t``_r_optional_t) separator    \
  keyword type obi_t``_rsp_t = `OBI_CFG_INTEGRITY_RSP_T(obi_t``_r_chan_t)

`define OBI_SEPARATOR_COMMA ,
`define OBI_SEPARATOR_SEMICOLON ;

// Parameter port list: caller adds the trailing comma.
`define OBI_PARAM_TYPE_GLOBAL_ALL(obi_t, cfg) \
  `OBI_GENERIC_PARAM_TYPE_ALL(obi_t, cfg, parameter, `OBI_SEPARATOR_COMMA)
`define OBI_LOCALPARAM_TYPE_GLOBAL_ALL(obi_t, cfg) \
  `OBI_GENERIC_PARAM_TYPE_ALL(obi_t, cfg, parameter, `OBI_SEPARATOR_COMMA)
// Module body: caller adds the trailing semicolon.
`define OBI_LOCALPARAM_TYPE_ALL(obi_t, cfg) \
  `OBI_GENERIC_PARAM_TYPE_ALL(obi_t, cfg, localparam, `OBI_SEPARATOR_SEMICOLON)

`endif  // OBI_TYPES_SVH
