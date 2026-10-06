// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Author: Samuel Riedel <sriedel@iis.ee.ethz.ch>
// Author: Michael Rogenmoser <michaero@iis.ee.ethz.ch>

`include "common_cells/registers.svh"

/// Handles atomics. Hence, it needs to be instantiated in front of a memory region over which the
/// bus has exclusive access.
module obi_atop_resolver
  import obi_pkg::*;
#(
    /// The configuration of the subordinate ports (input ports).
    parameter obi_pkg::obi_cfg_t SbrPortObiCfg             = obi_pkg::ObiDefaultConfig,
    /// The configuration of the manager port (output port).
    parameter obi_pkg::obi_cfg_t MgrPortObiCfg             = SbrPortObiCfg,
    /// The request struct for the subordinate port (input ports).
    parameter type               sbr_port_obi_req_t        = logic,
    /// The response struct for the subordinate port (input ports).
    parameter type               sbr_port_obi_rsp_t        = logic,
    /// The request struct for the manager port (output port).
    parameter type               mgr_port_obi_req_t        = sbr_port_obi_req_t,
    /// The response struct for the manager ports (output ports).
    parameter type               mgr_port_obi_rsp_t        = sbr_port_obi_rsp_t,
    ///
    parameter type               mgr_port_obi_a_optional_t = logic,
    parameter type               mgr_port_obi_r_optional_t = logic,
    /// Enable LR & SC AMOS
    parameter bit                LrScEnable                = 1,
    /// Cut path between request and response at the cost of increased AMO latency
    parameter bit                RegisterAmo               = 1'b0,
    // Word width of the widest RISC-V processor that can issue requests to this module.
    // 32 for RV32; 64 for RV64, where both 32-bit (.W suffix) and 64-bit (.D suffix) AMOs are
    // supported if `aw_strb` is set correctly.
    parameter int unsigned       RiscvWordWidth            = 32
) (
    input logic clk_i,
    input logic rst_ni,
    input logic testmode_i,

    input  sbr_port_obi_req_t sbr_port_req_i,
    output sbr_port_obi_rsp_t sbr_port_rsp_o,

    output mgr_port_obi_req_t mgr_port_req_o,
    input  mgr_port_obi_rsp_t mgr_port_rsp_i
);

  if (!SbrPortObiCfg.OptionalCfg.UseAtop) $fatal(1, "Atomics require atop to be enabled");
  if (MgrPortObiCfg.OptionalCfg.UseAtop)
    $fatal(1, "Filter requires atop to be disabled on manager port");
  if (SbrPortObiCfg.Integrity || MgrPortObiCfg.Integrity) $error("Integrity not supported");

  logic meta_valid, meta_ready;
  logic rdata_valid, rdata_ready;

  // read signal before register
  logic [SbrPortObiCfg.DataWidth-1:0] out_rdata;

  logic pop_resp;
  logic last_amo_wb;

  typedef enum logic [1:0] {
    Idle,
    DoAMO,
    WriteBackAMO
  } amo_state_e;

  amo_state_e state_q, state_d;

  logic                                    load_amo;
  obi_atop_e                               amo_op_q;
  logic                                    amo_wb;
  logic      [SbrPortObiCfg.AddrWidth-1:0] addr_q;

  logic      [  SbrPortObiCfg.IdWidth-1:0] aid_q;

  localparam int unsigned AxiAluRatio = SbrPortObiCfg.DataWidth / RiscvWordWidth;
  logic [AxiAluRatio-1:0][RiscvWordWidth-1:0] amo_operand_a;
  logic [AxiAluRatio-1:0][RiscvWordWidth-1:0] amo_operand_a_q;
  logic [AxiAluRatio-1:0][RiscvWordWidth-1:0] amo_operand_b_q;
  logic [$clog2(SbrPortObiCfg.DataWidth/8)-$clog2(RiscvWordWidth/8)-1:0]
      amo_operand_addr, amo_operand_addr_q;
  logic [AxiAluRatio-1:0][RiscvWordWidth-1:0] amo_result, amo_result_q;

  // Selection of the RiscvWordWidth word within the wide atomic request.
  logic [SbrPortObiCfg.DataWidth/8-1:0] be_q;
  logic [$clog2(SbrPortObiCfg.DataWidth/8)-1:0] lz_cnt;
  assign amo_operand_addr = lz_cnt >> $clog2(RiscvWordWidth / 8);

  lzc #(
      .WIDTH(SbrPortObiCfg.DataWidth / 8),
      .MODE (1'b0)
  ) i_count_addr (
      .in_i   (be_q),
      .cnt_o  (lz_cnt),
      .empty_o(  /*Unused*/)
  );

  // Store the metadata at handshake
  spill_register #(
      .T     (logic [SbrPortObiCfg.IdWidth-1:0]),
      .Bypass(1'b0)
  ) i_metadata_register (
      .clk_i,
      .rst_ni,
      .valid_i(sbr_port_req_i.req && sbr_port_rsp_o.gnt),
      .ready_o(meta_ready),
      .data_i (sbr_port_req_i.a.aid),
      .valid_o(meta_valid),
      .ready_i(pop_resp),
      .data_o (sbr_port_rsp_o.r.rid)
  );

  // Store response if it's not accepted immediately
  logic rdata_full, rdata_empty;
  logic rdata_usage;

  assign rdata_ready = !rdata_usage && !rdata_full;
  assign rdata_valid = !rdata_empty;

  logic sc_successful_or_lr_d, sc_successful_or_lr_q;
  logic sc_q;

  typedef struct packed {
    logic [SbrPortObiCfg.DataWidth-1:0] data;
    logic                               err;
    logic                               exokay;
    mgr_port_obi_r_optional_t           optional;
  } out_buffer_t;
  out_buffer_t out_buf_fifo_in, out_buf_fifo_out;

  assign out_buf_fifo_in = '{
          data: out_rdata,
          err: mgr_port_rsp_i.r.err,
          exokay: sc_successful_or_lr_q,
          optional: mgr_port_rsp_i.r.r_optional
      };

  assign sbr_port_rsp_o.r.rdata = out_buf_fifo_out.data;
  assign sbr_port_rsp_o.r.err = out_buf_fifo_out.err;
  assign sbr_port_rsp_o.r.r_optional.exokay = out_buf_fifo_out.exokay;
  if (SbrPortObiCfg.OptionalCfg.RUserWidth) begin : gen_ruser
    if (MgrPortObiCfg.OptionalCfg.RUserWidth) begin : gen_ruser_assign
      always_comb begin
        sbr_port_rsp_o.r.r_optional.ruser = '0;
        sbr_port_rsp_o.r.r_optional.ruser = out_buf_fifo_in.optional.ruser;
      end
    end else begin : gen_no_ruser
      assign sbr_port_rsp_o.r.r_optional.ruser = '0;
    end
  end

  fifo_v3 #(
      .FALL_THROUGH(1'b1),
      .dtype       (out_buffer_t),
      .DEPTH       (2)
  ) i_rdata_fifo (
      .clk_i,
      .rst_ni,
      .testmode_i,
      .flush_i(1'b0),
      .full_o (rdata_full),
      .empty_o(rdata_empty),
      .usage_o(rdata_usage),
      .data_i (out_buf_fifo_in),
      .push_i (~last_amo_wb & mgr_port_rsp_i.rvalid),
      .data_o (out_buf_fifo_out),
      .pop_i  (pop_resp & ~rdata_empty)
  );

  // In case of a SC we must forward SC result from the cycle earlier.
  assign out_rdata = (sc_q && LrScEnable) ? $unsigned(
      !sc_successful_or_lr_q
  ) : mgr_port_rsp_i.r.rdata;

  // Ready to output data if both meta and read data
  // are available (the read data will always be last)
  assign sbr_port_rsp_o.rvalid = meta_valid & rdata_valid;
  // Only pop the data from the registers once both registers are ready
  if (SbrPortObiCfg.UseRReady) begin : gen_pop_rready
    assign pop_resp = sbr_port_rsp_o.rvalid & sbr_port_req_i.rready;
  end else begin : gen_pop_norready
    assign pop_resp = sbr_port_rsp_o.rvalid;
  end

  // Buffer amo_wb signal to ensure wb rdata is not used
  `FFL(last_amo_wb, amo_wb, mgr_port_req_o.req, 1'b0, clk_i, rst_ni);

  // ----------------
  // LR/SC
  // ----------------

  if (LrScEnable) begin : gen_lrsc
    // unique requester identifier, does not necessarily match core_id
    logic [SbrPortObiCfg.IdWidth-1:0] unique_requester_id;

    typedef struct packed {
      /// Is the reservation valid.
      logic                               valid;
      /// On which address is the reservation placed.
      /// This address is aligned to the memory size
      /// implying that the reservation happen on a set size
      /// equal to the word width of the memory (32 or 64 bit).
      logic [SbrPortObiCfg.AddrWidth-1:0] addr;
      /// Which requester made this reservation. Important to
      /// track the reservations from different requesters and
      /// to prevent any live-locking.
      logic [SbrPortObiCfg.IdWidth-1:0]   requester;
    } reservation_t;
    reservation_t reservation_d, reservation_q;

    `FF(sc_successful_or_lr_q, sc_successful_or_lr_d, 1'b0, clk_i, rst_ni);
    `FF(reservation_q, reservation_d, 1'b0, clk_i, rst_ni);
    `FF(sc_q,
        sbr_port_req_i.req &
              sbr_port_rsp_o.gnt &
              (obi_atop_e'(sbr_port_req_i.a.a_optional.atop) == ATOPSC),
        1'b0, clk_i, rst_ni);

    always_comb begin
      unique_requester_id = sbr_port_req_i.a.aid;

      reservation_d = reservation_q;
      sc_successful_or_lr_d = 1'b0;
      // new valid transaction
      if (sbr_port_req_i.req && sbr_port_rsp_o.gnt) begin

        // An SC can only pair with the most recent LR in program order.
        // Place a reservation on the address if there isn't already a valid reservation.
        // We prevent a live-lock by don't throwing away the reservation of a hart unless
        // it makes a new reservation in program order or issues any SC.
        if (obi_atop_e'(sbr_port_req_i.a.a_optional.atop) == ATOPLR &&
            (!reservation_q.valid || reservation_q.requester == unique_requester_id)) begin
          reservation_d.valid = 1'b1;
          reservation_d.addr = sbr_port_req_i.a.addr;
          reservation_d.requester = unique_requester_id;
          sc_successful_or_lr_d = 1'b1;
        end

        // An SC may succeed only if no store from another hart (or other device) to
        // the reservation set can be observed to have occurred between
        // the LR and the SC, and if there is no other SC between the
        // LR and itself in program order.

        // check whether another requester has made a write attempt
        if ((unique_requester_id != reservation_q.requester) &&
            (sbr_port_req_i.a.addr == reservation_q.addr) &&
            (!((obi_atop_e'(sbr_port_req_i.a.a_optional.atop) inside {ATOPLR, ATOPSC}) ||
               !sbr_port_req_i.a.a_optional.atop[5]) || sbr_port_req_i.a.we)) begin
          reservation_d.valid = 1'b0;
        end

        // An SC from the same hart clears any pending reservation.
        if (reservation_q.valid && obi_atop_e'(sbr_port_req_i.a.a_optional.atop) == ATOPSC
            && reservation_q.requester == unique_requester_id) begin
          reservation_d.valid   = 1'b0;
          sc_successful_or_lr_d = (reservation_q.addr == sbr_port_req_i.a.addr);
        end
      end
    end  // always_comb
  end else begin : gen_disable_lrcs
    assign sc_q = 1'b0;
    assign sc_successful_or_lr_d = 1'b0;
    assign sc_successful_or_lr_q = 1'b0;
  end

  // ----------------
  // Atomics
  // ----------------

  mgr_port_obi_a_optional_t a_optional;
  if (MgrPortObiCfg.OptionalCfg.AUserWidth) begin : gen_auser
    if (SbrPortObiCfg.OptionalCfg.AUserWidth) begin : gen_auser_assign
      always_comb begin
        a_optional.auser = '0;
        a_optional.auser = sbr_port_req_i.a.a_optional.auser;
      end
    end else begin : gen_no_auser
      assign a_optional.auser = '0;
    end
  end
  if (MgrPortObiCfg.OptionalCfg.WUserWidth) begin : gen_wuser
    if (SbrPortObiCfg.OptionalCfg.WUserWidth) begin : gen_wuser_assign
      always_comb begin
        a_optional.wuser = '0;
        a_optional.wuser = sbr_port_req_i.a.a_optional.wuser;
      end
    end else begin : gen_no_wuser
      assign a_optional.wuser = '0;
    end
  end
  if (MgrPortObiCfg.OptionalCfg.UseProt) begin : gen_prot
    if (SbrPortObiCfg.OptionalCfg.UseProt) begin : gen_prot_assign
      assign a_optional.prot = sbr_port_req_i.a.a_optional.prot;
    end else begin : gen_no_prot
      assign a_optional.prot = obi_pkg::DefaultProt;
    end
  end
  if (MgrPortObiCfg.OptionalCfg.UseMemtype) begin : gen_memtype
    if (SbrPortObiCfg.OptionalCfg.UseMemtype) begin : gen_memtype_assign
      assign a_optional.memtype = sbr_port_req_i.a.a_optional.memtype;
    end else begin : gen_no_memtype
      assign a_optional.memtype = obi_pkg::DefaultMemtype;
    end
  end
  if (MgrPortObiCfg.OptionalCfg.MidWidth) begin : gen_mid
    if (SbrPortObiCfg.OptionalCfg.MidWidth) begin : gen_mid_assign
      always_comb begin
        a_optional.mid = '0;
        a_optional.mid = sbr_port_req_i.a.a_optional.mid;
      end
    end else begin : gen_no_mid
      assign a_optional.mid = '0;
    end
  end
  if (MgrPortObiCfg.OptionalCfg.UseDbg) begin : gen_dbg
    if (SbrPortObiCfg.OptionalCfg.UseDbg) begin : gen_dbg_assign
      assign a_optional.dbg = sbr_port_req_i.a.a_optional.dbg;
    end else begin : gen_no_dbg
      assign a_optional.dbg = '0;
    end
  end

  if (!MgrPortObiCfg.OptionalCfg.AUserWidth &&
      !MgrPortObiCfg.OptionalCfg.WUserWidth &&
      !MgrPortObiCfg.OptionalCfg.UseProt &&
      !MgrPortObiCfg.OptionalCfg.UseMemtype &&
      !MgrPortObiCfg.OptionalCfg.MidWidth &&
      !MgrPortObiCfg.OptionalCfg.UseDbg) begin : gen_no_optional
    assign a_optional = '0;
  end

  always_comb begin
    // feed-through
    sbr_port_rsp_o.gnt = rdata_ready & mgr_port_rsp_i.gnt;
    mgr_port_req_o.req = sbr_port_req_i.req & rdata_ready;
    mgr_port_req_o.a.addr = sbr_port_req_i.a.addr;
    mgr_port_req_o.a.we         = obi_atop_e'(sbr_port_req_i.a.a_optional.atop) != ATOPSC ?
                                  sbr_port_req_i.a.we : sc_successful_or_lr_d;
    mgr_port_req_o.a.wdata = sbr_port_req_i.a.wdata;
    mgr_port_req_o.a.be = sbr_port_req_i.a.be;
    mgr_port_req_o.a.aid = sbr_port_req_i.a.aid;
    mgr_port_req_o.a.a_optional = a_optional;

    state_d = state_q;
    load_amo = 1'b0;
    amo_wb = 1'b0;

    unique case (state_q)
      Idle: begin
        if (sbr_port_req_i.req &
            sbr_port_rsp_o.gnt &
            !((obi_atop_e'(sbr_port_req_i.a.a_optional.atop) inside {ATOPLR, ATOPSC}) ||
              !sbr_port_req_i.a.a_optional.atop[5])) begin
          load_amo = 1'b1;
          state_d  = DoAMO;
          if (obi_atop_e'(sbr_port_req_i.a.a_optional.atop) inside {AMOSWAP, AMOADD, AMOXOR,
                                                                    AMOAND, AMOOR, AMOMIN, AMOMAX,
                                                                    AMOMINU, AMOMAXU}) begin
            mgr_port_req_o.a.we = 1'b0;
          end
        end
      end
      // Claim the memory interface
      DoAMO, WriteBackAMO: begin
        sbr_port_rsp_o.gnt = 1'b0;
        if (mgr_port_rsp_i.gnt) begin
          state_d = (RegisterAmo && state_q != WriteBackAMO) ? WriteBackAMO : Idle;
        end
        // Commit AMO
        amo_wb                = 1'b1;
        mgr_port_req_o.req    = 1'b1;
        mgr_port_req_o.a.we   = 1'b1;
        mgr_port_req_o.a.addr = addr_q;
        mgr_port_req_o.a.aid  = aid_q;
        mgr_port_req_o.a.be   = '0;
        // serve from register if we cut the path
        if (RegisterAmo) begin
          mgr_port_req_o.a.wdata = amo_result_q;
          mgr_port_req_o.a.be = {RiscvWordWidth/8{1'b1}} <<
          (amo_operand_addr_q * RiscvWordWidth/8);
        end else begin
          mgr_port_req_o.a.wdata = amo_result;
          mgr_port_req_o.a.be = {RiscvWordWidth/8{1'b1}} <<
          (amo_operand_addr * RiscvWordWidth/8);
        end
      end
      default: ;
    endcase
  end

  if (RegisterAmo) begin : gen_amo_slice
    `FFLNR(amo_result_q, amo_result, (state_q == DoAMO), clk_i)
    `FFLNR(amo_operand_addr_q, amo_operand_addr, (state_q == DoAMO), clk_i)
  end else begin : gen_amo_slice
    assign amo_result_q = '0;
    assign amo_operand_addr_q = '0;
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      state_q         <= Idle;
      amo_op_q        <= obi_atop_e'('0);
      addr_q          <= '0;
      be_q            <= '0;
      amo_operand_b_q <= '0;
      aid_q           <= '0;
    end else begin
      state_q <= state_d;
      if (load_amo) begin
        amo_op_q        <= obi_atop_e'(sbr_port_req_i.a.a_optional.atop);
        addr_q          <= sbr_port_req_i.a.addr;
        be_q            <= sbr_port_req_i.a.be;
        aid_q           <= sbr_port_req_i.a.aid;
        amo_operand_b_q <= sbr_port_req_i.a.wdata;
      end else begin
        amo_op_q <= ATOPNONE;
      end
    end
  end

  // ----------------
  // AMO ALU
  // ----------------
  logic [RiscvWordWidth+1:0] adder_sum;
  logic [RiscvWordWidth:0] adder_operand_a, adder_operand_b;

  `FFL(amo_operand_a_q, mgr_port_rsp_i.r.rdata, mgr_port_rsp_i.rvalid, '0, clk_i, rst_ni)
  assign amo_operand_a = mgr_port_rsp_i.rvalid ? mgr_port_rsp_i.r.rdata : amo_operand_a_q;
  assign adder_sum = adder_operand_a + adder_operand_b;

  /* verilator lint_off WIDTH */
  always_comb begin : amo_alu

    adder_operand_a = $signed(amo_operand_a[amo_operand_addr]);
    adder_operand_b = $signed(amo_operand_b_q[amo_operand_addr]);

    amo_result = amo_operand_b_q;

    unique case (amo_op_q)
      // the default is to output operand_b
      AMOSWAP: ;
      AMOADD: amo_result[amo_operand_addr] = adder_sum[RiscvWordWidth-1:0];
      AMOAND:
      amo_result[amo_operand_addr] = amo_operand_a[amo_operand_addr] &
      amo_operand_b_q[amo_operand_addr];
      AMOOR:
      amo_result[amo_operand_addr] = amo_operand_a[amo_operand_addr] |
      amo_operand_b_q[amo_operand_addr];
      AMOXOR:
      amo_result[amo_operand_addr] = amo_operand_a[amo_operand_addr] ^
      amo_operand_b_q[amo_operand_addr];
      AMOMAX: begin
        adder_operand_b = -$signed(amo_operand_b_q[amo_operand_addr]);
        amo_result[amo_operand_addr] = adder_sum[RiscvWordWidth] ?
        amo_operand_b_q[amo_operand_addr] : amo_operand_a[amo_operand_addr];
      end
      AMOMIN: begin
        adder_operand_b = -$signed(amo_operand_b_q[amo_operand_addr]);
        amo_result[amo_operand_addr] = adder_sum[RiscvWordWidth] ?
        amo_operand_a[amo_operand_addr] : amo_operand_b_q[amo_operand_addr];
      end
      AMOMAXU: begin
        adder_operand_a = $unsigned(amo_operand_a[amo_operand_addr]);
        adder_operand_b = -$unsigned(amo_operand_b_q[amo_operand_addr]);
        amo_result[amo_operand_addr] = adder_sum[RiscvWordWidth] ?
        amo_operand_b_q[amo_operand_addr] : amo_operand_a[amo_operand_addr];
      end
      AMOMINU: begin
        adder_operand_a = $unsigned(amo_operand_a[amo_operand_addr]);
        adder_operand_b = -$unsigned(amo_operand_b_q[amo_operand_addr]);
        amo_result[amo_operand_addr] = adder_sum[RiscvWordWidth] ?
        amo_operand_a[amo_operand_addr] : amo_operand_b_q[amo_operand_addr];
      end
      default: amo_result = '0;
    endcase
  end

  // pragma translate_off
  // Check for unsupported parameters
  if (RiscvWordWidth != 32) begin : gen_datawidth_err
    $error($sformatf({"Module currently only supports RiscvWordWidth = 32 (Currently %0d)."
    }, RiscvWordWidth));
  end

`ifndef VERILATOR
  assert_rdata_full :
  assert property (@(posedge clk_i) disable iff (~rst_ni) (sbr_port_rsp_o.gnt |-> !rdata_full))
  else $fatal(1, "Trying to push new data although the i_rdata_register is not ready.");
`endif
  // pragma translate_on

endmodule

`include "obi/typedef.svh"
`include "obi/assign.svh"

module obi_atop_resolver_intf
  import obi_pkg::*;
#(
    /// The configuration of the subordinate ports (input ports).
    parameter obi_pkg::obi_cfg_t SbrPortObiCfg = obi_pkg::ObiDefaultConfig,
    /// The configuration of the manager port (output port).
    parameter obi_pkg::obi_cfg_t MgrPortObiCfg = SbrPortObiCfg,
    /// Enable LR & SC AMOS
    parameter bit                LrScEnable    = 1,
    /// Cut path between request and response at the cost of increased AMO latency
    parameter bit                RegisterAmo   = 1'b0
) (
    input logic clk_i,
    input logic rst_ni,
    input logic testmode_i,

    OBI_BUS.Subordinate sbr_port,

    OBI_BUS.Manager mgr_port
);

  `OBI_TYPEDEF_ALL(sbr_port_obi, SbrPortObiCfg)
  `OBI_TYPEDEF_ALL(mgr_port_obi, MgrPortObiCfg)

  sbr_port_obi_req_t sbr_port_req;
  sbr_port_obi_rsp_t sbr_port_rsp;

  mgr_port_obi_req_t mgr_port_req;
  mgr_port_obi_rsp_t mgr_port_rsp;

  `OBI_ASSIGN_TO_REQ(sbr_port_req, sbr_port, SbrPortObiCfg)
  `OBI_ASSIGN_FROM_RSP(sbr_port, sbr_port_rsp, SbrPortObiCfg)

  `OBI_ASSIGN_FROM_REQ(mgr_port, mgr_port_req, MgrPortObiCfg)
  `OBI_ASSIGN_TO_RSP(mgr_port_rsp, mgr_port, MgrPortObiCfg)

  obi_atop_resolver #(
      .SbrPortObiCfg            (SbrPortObiCfg),
      .MgrPortObiCfg            (MgrPortObiCfg),
      .sbr_port_obi_req_t       (sbr_port_obi_req_t),
      .sbr_port_obi_rsp_t       (sbr_port_obi_rsp_t),
      .mgr_port_obi_req_t       (mgr_port_obi_req_t),
      .mgr_port_obi_rsp_t       (mgr_port_obi_rsp_t),
      .mgr_port_obi_a_optional_t(mgr_port_obi_a_optional_t),
      .mgr_port_obi_r_optional_t(mgr_port_obi_r_optional_t),
      .LrScEnable               (LrScEnable),
      .RegisterAmo              (RegisterAmo)
  ) i_obi_atop_resolver (
      .clk_i,
      .rst_ni,
      .testmode_i,
      .sbr_port_req_i(sbr_port_req),
      .sbr_port_rsp_o(sbr_port_rsp),
      .mgr_port_req_o(mgr_port_req),
      .mgr_port_rsp_i(mgr_port_rsp)
  );

endmodule
