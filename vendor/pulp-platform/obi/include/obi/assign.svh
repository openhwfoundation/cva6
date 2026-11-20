// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Michael Rogenmoser <michaero@iis.ee.ethz.ch>

`ifndef OBI_ASSIGN_SVH
`define OBI_ASSIGN_SVH

////////////////////////////////////////////////////////////////////////////////////////////////////
// Internal implementation for assigning one ONE struct or interface to another struct or interface.
// The path to the signals on each side is defined by the `__sep*` arguments.  The `__opt_as`
// argument allows to use this standalone (with `__opt_as = assign`) or in assignments inside
// processes (with `__opt_as` void).

`define __OBI_TO_A(__opt_as, __lhs, __lhs_sep, __rhs, __rhs_sep)                       \
  __opt_as __lhs``__lhs_sep``addr       = __rhs``__rhs_sep``addr;                      \
  __opt_as __lhs``__lhs_sep``we         = __rhs``__rhs_sep``we;                        \
  __opt_as __lhs``__lhs_sep``be         = __rhs``__rhs_sep``be;                        \
  __opt_as __lhs``__lhs_sep``wdata      = __rhs``__rhs_sep``wdata;                     \
  __opt_as __lhs``__lhs_sep``aid        = __rhs``__rhs_sep``aid;                       \
  __opt_as __lhs``__lhs_sep``a_optional = __rhs``__rhs_sep``a_optional;
`define __OBI_TO_R(__opt_as, __lhs, __lhs_sep, __rhs, __rhs_sep)                       \
  __opt_as __lhs``__lhs_sep``rdata      = __rhs``__rhs_sep``rdata;                     \
  __opt_as __lhs``__lhs_sep``rid        = __rhs``__rhs_sep``rid;                       \
  __opt_as __lhs``__lhs_sep``err        = __rhs``__rhs_sep``err;                       \
  __opt_as __lhs``__lhs_sep``r_optional = __rhs``__rhs_sep``r_optional;
`define __OBI_TO_REQ(__opt_as, __lhs, __lhs_sep, __rhs, __rhs_sep, __lhscfg, __rhscfg) \
  `__OBI_TO_A(__opt_as, __lhs, __lhs_sep, __rhs, __rhs_sep)                            \
  __opt_as __lhs.req                   = __rhs.req;                                    \
  if (__lhscfg.UseRReady) begin                                                        \
    if (__rhscfg.UseRReady) begin                                                      \
      __opt_as __lhs.rready            = __rhs.rready;                                 \
      if (__lhscfg.Integrity) begin                                                    \
        if (__rhscfg.Integrity) begin                                                  \
          __opt_as __lhs.rreadypar     = __rhs.rreadypar;                              \
        end else begin                                                                 \
          __opt_as __lhs.rreadypar     = ~__rhs.rready;                                \
        end                                                                            \
      end                                                                              \
    end else begin                                                                     \
      __opt_as __lhs.rready            = 1'b1;                                         \
      if (__lhscfg.Integrity) begin                                                    \
        __opt_as __lhs.rreadypar       = 1'b0;                                         \
      end                                                                              \
    end                                                                                \
  end else if (__rhscfg.UseRReady) begin                                               \
    $error("Incompatible Configs! Please assign manually!");                           \
  end                                                                                  \
  if (__lhscfg.Integrity) begin                                                        \
    if (__rhscfg.Integrity) begin                                                      \
      __opt_as __lhs.reqpar           = __rhs.reqpar;                                  \
    end else begin                                                                     \
      __opt_as __lhs.reqpar           = ~__rhs.req;                                    \
    end                                                                                \
  end
`define __OBI_TO_RSP(__opt_as, __lhs, __lhs_sep, __rhs, __rhs_sep, __lhscfg, __rhscfg) \
  `__OBI_TO_R(__opt_as, __lhs, __lhs_sep, __rhs, __rhs_sep)                            \
  __opt_as __lhs.gnt                   = __rhs.gnt;                                    \
  __opt_as __lhs.rvalid                = __rhs.rvalid;                                 \
  if (__lhscfg.Integrity) begin                                                        \
    if (__rhscfg.Integrity) begin                                                      \
      __opt_as __lhs.gntpar              = __rhs.gntpar;                               \
      __opt_as __lhs.rvalidpar           = __rhs.rvalidpar;                            \
    end else begin                                                                     \
      __opt_as __lhs.gntpar              = ~__rhs.gnt;                                 \
      __opt_as __lhs.rvalidpar           = ~__rhs.rvalid;                              \
    end                                                                                \
  end
////////////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////////////////////////
// Assigning one OBI interface to another, as if you would do `assign sbr = mgr;`
//
// The channel assignments `OBI_ASSIGN_XX(dst, src)` assign all payload and the valid signal of the
// `XX` channel from the `src` to the `dst` interface and they assign the ready signal from the
// `src` to the `dst` interface.
// The interface assignment `OBI_ASSIGN(dst, src)` assigns all channels including handshakes as if
// `src` was the manager of `dst`.
//
// Usage Example:
// `OBI_ASSIGN(sbr, mgr)
// `OBI_ASSIGN_A(dst, src)
// `OBI_ASSIGN_R(dst, src)
`define OBI_ASSIGN_A(dst, src, dstcfg, srccfg)               \
  `__OBI_TO_A(assign, dst, ., src, .)                        \
  assign dst.req = src.req;                                  \
  assign src.gnt = dst.gnt;                                  \
  if (dstcfg.Integrity && srccfg.Integrity) begin            \
    assign dst.reqpar = src.reqpar;                          \
    assign src.gntpar = dst.gntpar;                          \
  end else if (dstcfg.Integrity ^ srccfg.Integrity) begin    \
    $error("Incompatible Configs! Please assign manually!"); \
  end
`define OBI_ASSIGN_R(dst, src, dstcfg, srccfg)               \
  `__OBI_TO_R(assign, dst, ., src, .)                        \
  assign dst.rvalid = src.rvalid;                            \
  if (dstcfg.Integrity && srccfg.Integrity) begin            \
    assign dst.rvalidpar = src.rvalidpar;                    \
  end else if (dstcfg.Integrity ^ srccfg.Integrity) begin    \
    $error("Incompatible Configs! Please assign manually!"); \
  end                                                        \
  if (srccfg.UseRReady) begin                                \
    if (dstcfg.UseRReady) begin                              \
      assign src.rready = dst.rready;                        \
      if (srccfg.Integrity && dstcfg.Integrity) begin        \
        assign src.rreadypar = dst.rreadypar;                \
      end                                                    \
    end else begin                                           \
      assign src.rready = 1'b1;                              \
      if (srccfg.Integrity) begin                            \
        assign src.rreadypar = 1'b0;                         \
      end                                                    \
    end                                                      \
  end else if (dstcfg.UseRReady) begin                       \
    $error("Incompatible Configs! Please assign manually!"); \
  end
`define OBI_ASSIGN(sbr, mgr, sbrcfg, mgrcfg) \
  `OBI_ASSIGN_A(sbr, mgr, sbrcfg, mgrcfg)    \
  `OBI_ASSIGN_R(mgr, sbr, mgrcfg, sbrcfg)
////////////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////////////////////////
// Setting an interface from channel or request/response structs inside a process.
//
// The channel macros `OBI_SET_FROM_XX(obi_if, xx_struct)` set the payload signals of the `obi_if`
// interface from the signals in `xx_struct`.  They do not set the handshake signals.
// The request macro `OBI_SET_FROM_REQ(obi_if, req_struct)` sets the request channel and the
// request-side handshake signals of the `obi_if` interface from the signals in `req_struct`.
// The response macro `OBI_SET_FROM_RESP(obi_if, rsp_struct)` sets the response channel and the 
// response-side handshake signals of the `obi_if` interface from the signals in `resp_struct`.
//
// Usage Example:
// always_comb begin
//   `OBI_SET_FROM_REQ(my_if, my_req_struct)
// end
`define OBI_SET_FROM_A(obi_if, a_struct)           `__OBI_TO_A(, obi_if, ., a_struct, .)
`define OBI_SET_FROM_R(obi_if, r_struct)           `__OBI_TO_R(, obi_if, ., r_struct, .)
`define OBI_SET_FROM_REQ(obi_if, req_struct, cfg)  `__OBI_TO_REQ(, obi_if, ., req_struct, .a., cfg, cfg)
`define OBI_SET_FROM_RSP(obi_if, rsp_struct, cfg)  `__OBI_TO_RSP(, obi_if, ., rsp_struct, .r., cfg, cfg)
////////////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////////////////////////
// Assigning an interface from channel or request/response structs outside a process.
//
// The channel macros `OBI_ASSIGN_FROM_XX(obi_if, xx_struct)` assign the payload signals of the
// `obi_if` interface from the signals in `xx_struct`.  They do not assign the handshake signals.
// The request macro `OBI_ASSIGN_FROM_REQ(obi_if, req_struct)` assigns the request channel and the
// request-side handshake signals of the `obi_if` interface from the signals in `req_struct`.
// The response macro `OBI_ASSIGN_FROM_RSP(obi_if, rsp_struct)` assigns the response channel and
// the response-side handshake signals of the `obi_if` interface from the signals in `rsp_struct`.
//
// Usage Example:
// `AXI_ASSIGN_FROM_REQ(my_if, my_req_struct)
`define OBI_ASSIGN_FROM_A(obi_if, a_struct)           `__OBI_TO_A(assign, obi_if, ., a_struct, .)
`define OBI_ASSIGN_FROM_R(obi_if, r_struct)           `__OBI_TO_R(assign, obi_if, ., r_struct, .)
`define OBI_ASSIGN_FROM_REQ(obi_if, req_struct, cfg)  `__OBI_TO_REQ(assign, obi_if, ., req_struct, .a., cfg, cfg)
`define OBI_ASSIGN_FROM_RSP(obi_if, rsp_struct, cfg)  `__OBI_TO_RSP(assign, obi_if, ., rsp_struct, .r., cfg, cfg)
////////////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////////////////////////
// Setting channel or request/response structs from an interface inside a process.
//
// The channel macros `OBI_SET_TO_XX(xx_struct, obi_if)` set the signals of `xx_struct` to the
// payload signals of that channel in the `obi_if` interface.  They do not set the handshake
// signals.
// The request macro `OBI_SET_TO_REQ(obi_if, req_struct)` sets all signals of `req_struct` (i.e.,
// request channel payload and request-side handshake signals) to the signals in the `obi_if`
// interface.
// The response macro `OBI_SET_TO_RSP(obi_if, rsp_struct)` sets all signals of `rsp_struct`
// (i.e., response channel payload and response-side handshake signals) to the signals in the
// `obi_if` interface.
//
// Usage Example:
// always_comb begin
//   `OBI_SET_TO_REQ(my_req_struct, my_if)
// end
`define OBI_SET_TO_A(a_struct, obi_if)           `__OBI_TO_A(, a_struct, ., obi_if, .)
`define OBI_SET_TO_R(r_struct, obi_if)           `__OBI_TO_R(, r_struct, ., obi_if, .)
`define OBI_SET_TO_REQ(req_struct, obi_if, cfg)  `__OBI_TO_REQ(, req_struct, .a., obi_if, ., cfg, cfg)
`define OBI_SET_TO_RSP(rsp_struct, obi_if, cfg)  `__OBI_TO_RSP(, rsp_struct, .r., obi_if, ., cfg, cfg)
////////////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////////////////////////
// Assigning channel or request/response structs from an interface outside a process.
//
// The channel macros `OBI_ASSIGN_TO_XX(xx_struct, obi_if)` assign the signals of `xx_struct` to the
// payload signals of that channel in the `obi_if` interface.  They do not assign the handshake
// signals.
// The request macro `OBI_ASSIGN_TO_REQ(obi_if, req_struct)` assigns all signals of `req_struct`
// (i.e., request channel payload and request-side handshake signals) to the signals in the `obi_if`
// interface.
// The response macro `OBI_ASSIGN_TO_RSP(obi_if, rsp_struct)` assigns all signals of `rsp_struct`
// (i.e., response channel payload and response-side handshake signals) to the signals in the
// `obi_if` interface.
//
// Usage Example:
// `OBI_ASSIGN_TO_REQ(my_req_struct, my_if)
`define OBI_ASSIGN_TO_A(a_struct, obi_if)           `__OBI_TO_A(assign, a_struct, ., obi_if, .)
`define OBI_ASSIGN_TO_R(r_struct, obi_if)           `__OBI_TO_R(assign, r_struct, ., obi_if, .)
`define OBI_ASSIGN_TO_REQ(req_struct, obi_if, cfg)  `__OBI_TO_REQ(assign, req_struct, .a., obi_if, ., cfg, cfg)
`define OBI_ASSIGN_TO_RSP(rsp_struct, obi_if, cfg)  `__OBI_TO_RSP(assign, rsp_struct, .r., obi_if, ., cfg, cfg)
////////////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////////////////////////
// Setting channel or request/response structs from another struct inside a process.
//
// The channel macros `OBI_SET_XX_STRUCT(lhs, rhs)` set the fields of the `lhs` channel struct to
// the fields of the `rhs` channel struct.  They do not set the handshake signals, which are not
// part of channel structs.
// The request macro `OBI_SET_REQ_STRUCT(lhs, rhs)` sets all fields of the `lhs` request struct to
// the fields of the `rhs` request struct.  This includes the request channel payload and
// request-side handshake signals.
// The response macro `OBI_SET_RSP_STRUCT(lhs, rhs)` sets all fields of the `lhs` response struct
// to the fields of the `rhs` response struct.  This includes the response channel payload
// and response-side handshake signals.
//
// Usage Example:
// always_comb begin
//   `OBI_SET_REQ_STRUCT(my_req_struct, another_req_struct)
// end
`define OBI_SET_A_STRUCT(lhs, rhs)      `__OBI_TO_A(, lhs, ., rhs, .)
`define OBI_SET_R_STRUCT(lhs, rhs)      `__OBI_TO_R(, lhs, ., rhs, .)
`define OBI_SET_REQ_STRUCT(lhs, rhs)  `__OBI_TO_REQ(, lhs, .a., rhs, .a.)
`define OBI_SET_RSP_STRUCT(lhs, rhs)  `__OBI_TO_RSP(, lhs, .r., rhs, .r.)
////////////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////////////////////////
// Assigning channel or request/response structs from another struct outside a process.
//
// The channel macros `OBI_ASSIGN_XX_STRUCT(lhs, rhs)` assign the fields of the `lhs` channel struct
// to the fields of the `rhs` channel struct.  They do not assign the handshake signals, which are
// not part of the channel structs.
// The request macro `OBI_ASSIGN_REQ_STRUCT(lhs, rhs)` assigns all fields of the `lhs` request
// struct to the fields of the `rhs` request struct.  This includes the request channel payload and
// request-side handshake signals.
// The response macro `OBI_ASSIGN_RSP_STRUCT(lhs, rhs)` assigns all fields of the `lhs` response
// struct to the fields of the `rhs` response struct.  This includes the response channel payload
// and response-side handshake signals.
//
// Usage Example:
// `OBI_ASSIGN_REQ_STRUCT(my_req_struct, another_req_struct)
`define OBI_ASSIGN_A_STRUCT(lhs, rhs)      `__OBI_TO_A(assign, lhs, ., rhs, .)
`define OBI_ASSIGN_R_STRUCT(lhs, rhs)      `__OBI_TO_R(assign, lhs, ., rhs, .)
`define OBI_ASSIGN_REQ_STRUCT(lhs, rhs)  `__OBI_TO_REQ(assign, lhs, .a., rhs, .a.)
`define OBI_ASSIGN_RSP_STRUCT(lhs, rhs)  `__OBI_TO_RSP(assign, lhs, .r., rhs, .r.)
////////////////////////////////////////////////////////////////////////////////////////////////////


`endif // OBI_ASSIGN_SVH
