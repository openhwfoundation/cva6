// Copyright 2024 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Author: Georg Rutishauser <georgr@iis.ee.ethz.ch>

module obi_rready_converter #(
  parameter type         obi_a_chan_t = logic,
  parameter type         obi_r_chan_t = logic,
  parameter int unsigned Depth        = 1,
  parameter bit          CombRspReq   = 1'b1
) (
  input  logic        clk_i,
  input  logic        rst_ni,
  input  logic        test_mode_i,

  input  obi_a_chan_t sbr_a_chan_i,
  input  logic        req_i,
  output logic        gnt_o,
  output obi_r_chan_t sbr_r_chan_o,
  output logic        rvalid_o,
  input  logic        rready_i,

  output obi_a_chan_t mgr_a_chan_o,
  output logic        req_o,
  input  logic        gnt_i,
  input  obi_r_chan_t mgr_r_chan_i,
  input  logic        rvalid_i
);

  logic fifo_ready, credit_left;
  stream_fifo #(
    .FALL_THROUGH ( 1'b1         ),
    .DEPTH        ( Depth        ),
    .T            ( obi_r_chan_t )
  ) response_fifo_i (
    .clk_i,
    .rst_ni,
    .flush_i    ( 1'b0         ),
    .testmode_i ( test_mode_i  ),
    .usage_o    (),
    .data_i     ( mgr_r_chan_i ),
    .valid_i    ( rvalid_i     ),
    .ready_o    ( fifo_ready   ),
    .data_o     ( sbr_r_chan_o ),
    .valid_o    ( rvalid_o     ),
    .ready_i    ( rready_i     )
  );

  credit_counter #(
    .NumCredits      ( Depth ),
    .InitCreditEmpty ( 1'b0  )
  ) credit_cntr_i (
    .clk_i,
    .rst_ni,
    .credit_o      (),
    .credit_give_i ( rvalid_o & rready_i ),
    .credit_take_i ( req_o & gnt_i       ),
    .credit_init_i ( 1'b0                ),
    .credit_left_o ( credit_left         ),
    .credit_crit_o (),
    .credit_full_o ()
  );

  // only transmit requests if we have credits left or free a space in the FIFO
  assign req_o = req_i & (credit_left | (CombRspReq & rready_i & rvalid_o));
  // only grant requests if we have credits left or free a space in the FIFO
  assign gnt_o = gnt_i & (credit_left | (CombRspReq & rready_i & rvalid_o));

  assign mgr_a_chan_o = sbr_a_chan_i;

endmodule
