// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Michael Rogenmoser <michaero@iis.ee.ethz.ch>

`ifndef OBI_TYPEDEF_SVH
`define OBI_TYPEDEF_SVH

`define OBI_A_CHAN_T(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH, a_optional_t) \
   struct packed {                                                   \
    logic [  ADDR_WIDTH-1:0] addr;                                   \
    logic                    we;                                     \
    logic [DATA_WIDTH/8-1:0] be;                                     \
    logic [  DATA_WIDTH-1:0] wdata;                                  \
    logic [    ID_WIDTH-1:0] aid;                                    \
    a_optional_t             a_optional;                             \
  }
`define OBI_TYPEDEF_A_CHAN_T(a_chan_t, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH, a_optional_t) \
  typedef `OBI_A_CHAN_T(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH, a_optional_t) a_chan_t;

`define OBI_A_TYPE_CHAN_T(addr_t, data_t, strb_t, id_t, a_optional_t) \
  struct packed {                                                     \
      addr_t       addr;                                              \
      logic        we;                                                \
      strb_t       be;                                                \
      data_t       wdata;                                             \
      id_t         aid;                                               \
      a_optional_t a_optional;                                        \
    }
`define OBI_TYPEDEF_TYPE_A_CHAN_T(a_chan_t, addr_t, data_t, strb_t, id_t, a_optional_t) \
  typedef `OBI_A_TYPE_CHAN_T(addr_t, data_t, strb_t, id_t, a_optional_t) a_chan_t;

`define OBI_MINIMAL_A_OPTIONAL(a_optional_t) \
    logic a_optional_t;
`define OBI_TYPEDEF_MINIMAL_A_OPTIONAL(a_optional_t) \
  typedef logic a_optional_t;

`define OBI_ATOP_A_OPTIONAL(a_optional_t) \
  struct packed {                         \
    obi_pkg::atop_t atop;                         \
  }
`define OBI_TYPEDEF_ATOP_A_OPTIONAL \
  typedef OBI_ATOP_A_OPTIONAL a_optional_t;

`define OBI_ALL_A_OPTIONAL(AUSER_WIDTH, WUSER_WIDTH, MID_WIDTH, ACHK_WIDTH) \
   struct packed {                                                          \
     logic [ AUSER_WIDTH-1:0] auser;                                        \
     logic [ WUSER_WIDTH-1:0] wuser;                                        \
     obi_pkg::atop_t          atop;                                         \
     obi_pkg::memtype_t       memtype;                                      \
     logic [   MID_WIDTH-1:0] mid;                                          \
     obi_pkg::prot_t          prot;                                         \
     logic                    dbg;                                          \
     logic [  ACHK_WIDTH-1:0] achk;                                         \
   }
`define OBI_TYPEDEF_ALL_A_OPTIONAL(a_optional_t, AUSER_WIDTH, WUSER_WIDTH, MID_WIDTH, ACHK_WIDTH) \
  typedef `OBI_ALL_A_OPTIONAL(AUSER_WIDTH, WUSER_WIDTH, MID_WIDTH, ACHK_WIDTH) a_optional_t;

`define OBI_R_CHAN_T(RDATA_WIDTH, ID_WIDTH, r_optional_t) \
   struct packed {                                        \
     logic [RDATA_WIDTH-1:0] rdata;                       \
     logic [   ID_WIDTH-1:0] rid;                         \
     logic                   err;                         \
     r_optional_t            r_optional;                  \
   }
`define OBI_TYPEDEF_R_CHAN_T(r_chan_t, RDATA_WIDTH, ID_WIDTH, r_optional_t) \
  typedef `OBI_R_CHAN_T(RDATA_WIDTH, ID_WIDTH, r_optional_t) r_chan_t;

`define OBI_TYPE_R_CHAN_T(data_t, id_t, r_optional_t) \
   struct packed {                                    \
     data_t       rdata;                              \
     id_t         rid;                                \
     logic        err;                                \
     r_optional_t r_optional;                         \
   } 
`define OBI_TYPEDEF_TYPE_R_CHAN_T(r_chan_t, data_t, id_t, r_optional_t) \
  typedef `OBI_TYPE_R_CHAN_T(data_t, id_t, r_optional_t) r_chan_t;

`define OBI_MINIMAL_R_OPTIONAL(r_optional_t) \
    logic r_optional_t;
`define OBI_TYPEDEF_MINIMAL_R_OPTIONAL(r_optional_t) \
  typedef logic r_optional_t;

`define OBI_ALL_R_OPTIONAL(RUSER_WIDTH, RCHK_WIDTH) \
   struct packed {                                  \
     logic [RUSER_WIDTH-1:0] ruser;                 \
     logic                   exokay;                \
     logic [ RCHK_WIDTH-1:0] rchk;                  \
   }
`define OBI_TYPEDEF_ALL_R_OPTIONAL(r_optional_t, RUSER_WIDTH, RCHK_WIDTH) \
  typedef `OBI_ALL_R_OPTIONAL(RUSER_WIDTH, RCHK_WIDTH) r_optional_t;

`define OBI_DEFAULT_REQ_T(req_t, a_chan_t) \
   struct packed {                         \
     a_chan_t a;                           \
     logic    req;                         \
   }
`define OBI_TYPEDEF_DEFAULT_REQ_T(req_t, a_chan_t) \
  typedef `OBI_DEFAULT_REQ_T(req_t, a_chan_t) req_t;

`define OBI_REQ_T(req_t, a_chan_t) \
  struct packed {                  \
    a_chan_t a;                    \
    logic    req;                  \
    logic    rready;               \
  }
`define OBI_TYPEDEF_REQ_T(req_t, a_chan_t) \
  typedef `OBI_REQ_T(req_t, a_chan_t) req_t;

`define OBI_RSP_T(rsp_t, r_chan_t) \
  struct packed {                  \
    r_chan_t r;                    \
    logic    gnt;                  \
    logic    rvalid;               \
  }
`define OBI_TYPEDEF_RSP_T(rsp_t, r_chan_t) \
  typedef `OBI_RSP_T(rsp_t, r_chan_t) rsp_t;

`define OBI_INTEGRITY_REQ_T(a_chan_t) \
   struct packed {                    \
     a_chan_t a;                      \
     logic    req;                    \
     logic    rready;                 \
     logic    reqpar;                 \
     logic    rreadypar;              \
   }
`define OBI_TYPEDEF_INTEGRITY_REQ_T(req_t, a_chan_t) \
  typedef `OBI_INTEGRITY_REQ_T(a_chan_t) req_t;

`define OBI_INTEGRITY_RSP_T(r_chan_t) \
   struct packed {                    \
     r_chan_t r;                      \
     logic    gnt;                    \
     logic    gntpar;                 \
     logic    rvalid;                 \
     logic    rvalidpar;              \
   }
`define OBI_TYPEDEF_INTEGRITY_RSP_T(rsp_t, r_chan_t) \
  typedef `OBI_INTEGRITY_RSP_T(r_chan_t) rsp_t;

`define OBI_TYPEDEF_ALL(obi_t, cfg)                                                                                                                              \
  `OBI_TYPEDEF_ALL_A_OPTIONAL(obi_t``_a_optional_t, cfg.OptionalCfg.AUserWidth, cfg.OptionalCfg.WUserWidth, cfg.OptionalCfg.MidWidth, cfg.OptionalCfg.AChkWidth) \
  `OBI_TYPEDEF_A_CHAN_T(obi_t``_a_chan_t, cfg.AddrWidth, cfg.DataWidth, cfg.IdWidth, obi_t``_a_optional_t)                                                       \
  `OBI_TYPEDEF_INTEGRITY_REQ_T(obi_t``_req_t, obi_t``_a_chan_t)                                                                                                  \
  `OBI_TYPEDEF_ALL_R_OPTIONAL(obi_t``_r_optional_t, cfg.OptionalCfg.RUserWidth, cfg.OptionalCfg.RChkWidth)                                                       \
  `OBI_TYPEDEF_R_CHAN_T(obi_t``_r_chan_t, cfg.DataWidth, cfg.IdWidth, obi_t``_r_optional_t)                                                                      \
  `OBI_TYPEDEF_INTEGRITY_RSP_T(obi_t``_rsp_t, obi_t``_r_chan_t)

`define OBI_GENERIC_PARAM_TYPE_ALL(obi_t, cfg, keyword, separator)                                                                                                                 \
  keyword type obi_t``_a_optional_t = `OBI_ALL_A_OPTIONAL(cfg.OptionalCfg.AUserWidth, cfg.OptionalCfg.WUserWidth, cfg.OptionalCfg.MidWidth, cfg.OptionalCfg.AChkWidth) separator  \
  keyword type obi_t``_a_chan_t = `OBI_A_CHAN_T(cfg.AddrWidth, cfg.DataWidth, cfg.IdWidth, obi_t``_a_optional_t) separator                                                       \
  keyword type obi_t``_req_t = `OBI_INTEGRITY_REQ_T(obi_t``_a_chan_t) separator                                                                                                  \
  keyword type obi_t``_r_optional_t = `OBI_ALL_R_OPTIONAL(cfg.OptionalCfg.RUserWidth, cfg.OptionalCfg.RChkWidth) separator                                                       \
  keyword type obi_t``_r_chan_t = `OBI_R_CHAN_T(cfg.DataWidth, cfg.IdWidth, obi_t``_r_optional_t) separator                                                                      \
  keyword type obi_t``_rsp_t = `OBI_INTEGRITY_RSP_T(obi_t``_r_chan_t)

`define OBI_SEPARATOR_COMMA   ,  
`define OBI_SEPARATOR_SEMICOLON  ;  

`define OBI_PARAM_TYPE_GLOBAL_ALL(obi_t, cfg) `OBI_GENERIC_PARAM_TYPE_ALL(obi_t, cfg, parameter, `OBI_SEPARATOR_COMMA)
`define OBI_LOCALPARAM_TYPE_GLOBAL_ALL(obi_t, cfg) `OBI_GENERIC_PARAM_TYPE_ALL(obi_t, cfg, parameter, `OBI_SEPARATOR_COMMA)                                                                               
`define OBI_LOCALPARAM_TYPE_ALL(obi_t, cfg) `OBI_GENERIC_PARAM_TYPE_ALL(obi_t, cfg, localparam, `OBI_SEPARATOR_SEMICOLON)                                                                                                                  

`define OBI_CFG_ALL_A_OPTIONAL_T(config) `OBI_ALL_A_OPTIONAL(config.OptionalCfg.AUserWidth, config.OptionalCfg.WUserWidth, config.OptionalCfg.MidWidth, config.OptionalCfg.AChkWidth)
`define OBI_CFG_A_CHAN_T(config, optional_t) `OBI_A_CHAN_T(config.AddrWidth, config.DataWidth, config.IdWidth, optional_t)
`define OBI_CFG_INTEGRITY_REQ_T(a_chan_t) `OBI_INTEGRITY_REQ_T(a_chan_t)
`define OBI_CFG_ALL_R_OPTIONAL_T(config) `OBI_ALL_R_OPTIONAL(config.OptionalCfg.RUserWidth, config.OptionalCfg.RChkWidth)
`define OBI_CFG_R_CHAN_T(config, optional_t) `OBI_R_CHAN_T(config.DataWidth, config.IdWidth, optional_t)
`define OBI_CFG_INTEGRITY_RSP_T(r_chan_t) `OBI_INTEGRITY_RSP_T(r_chan_t)



`endif  // OBI_TYPEDEF_SVH
