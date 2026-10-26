// Copyright 2018 ETH Zurich and University of Bologna.
//
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License. You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// Fabian Schuiki <fschuiki@iis.ee.ethz.ch> (original CDC)
// Manuel Eggimann <meggiman@iis.ee.ethz.ch> (clearability feature)

/// A two-phase clock domain crossing.
///
/// CONSTRAINT: Requires max_delay of min_period(src_clk_i, dst_clk_i) through
/// the paths async_req, async_ack, async_data.
///
///
/// Reset Behavior:
///
/// In contrast to the cdc_2phase version without clear signal, this module
/// supports one-sided warm resets (asynchronously and synchronously). The way
/// this is implemented is described in more detail in the cdc_reset_ctrlr
/// module. To summarize a synchronous clear request i.e. src/dst_clear_i will
/// cause the respective other clock domain to reset as well without introducing
/// any spurious transactions. This is acomplished by an internal module
/// (cdc_reset_ctrlr) that starts a reset sequence on both sides of the CDC in
/// lock-step that first isolates the CDC from the outside world and then resets
/// it. The reset sequencer provides the following behavior:
/// 1. There are no spurious invalid or duplicated transactions regardless how
///    the individual sides are reset (can also happen roughly simultaneosly)
/// 2. The CDC becomes unready at the src side in the next cycle after
///    synchronous reset request until the reset sequence is completed. A currently
///    pending transactions might still complete (if the dst accepts at the
///    exact time the reset is request on the src die).
/// 3. During the reset sequence the dst might withdraw the valid signal. This
///    might violate higher level protocols. If you need this feature you would
///    have to path the existing implementation to wait with the isolate_ack
///    assertion until all open handshakes were acknowledged.
/// 4. If the parameter CLEAR_ON_ASYNC_RESET is enabled, the same behavior as
///    above is also valid for asynchronous resets on either side. However, this
///    increases the minimum number of synchronization stages (SYNC_STAGES
///    parameter) from 2 to 3 (read the cdc_reset_ctrlr header to figure out
///    why).
///
///
/* verilator lint_off DECLFILENAME */

`include "common_cells/registers.svh"

module cdc_2phase_clearable #(
  parameter type T = logic,
  parameter int unsigned SYNC_STAGES = 3,
  parameter int CLEAR_ON_ASYNC_RESET = 1
)(
  input  logic src_rst_ni,
  input  logic src_clk_i,
  input  logic src_clear_i,
  output logic src_clear_pending_o,
  input  T     src_data_i,
  input  logic src_valid_i,
  output logic src_ready_o,

  input  logic dst_rst_ni,
  input  logic dst_clk_i,
  input  logic dst_clear_i,
  output logic dst_clear_pending_o,
  output T     dst_data_o,
  output logic dst_valid_o,
  input  logic dst_ready_i
);
  logic        s_src_clear_req;
  logic        s_src_clear_ack_q;
  logic        s_src_ready;
  logic        s_src_isolate_req;
  logic        s_src_isolate_ack_q;
  logic        s_dst_clear_req;
  logic        s_dst_clear_ack_q;
  logic        s_dst_valid;
  logic        s_dst_isolate_req;
  logic        s_dst_isolate_ack_q;

  // Asynchronous handshake signals between the CDCs
  (* dont_touch = "true" *) logic async_req;
  (* dont_touch = "true" *) logic async_ack;
  (* dont_touch = "true" *) T async_data;

  if (CLEAR_ON_ASYNC_RESET) begin : gen_elaboration_assertion
    if (SYNC_STAGES < 3)
      $error("The clearable 2-phase CDC with async reset",
             "synchronization requires at least 3 synchronizer stages for the FIFO.");
  end else begin : gen_elaboration_assertion
    if (SYNC_STAGES < 2) begin : gen_elaboration_assertion
      $error("A minimum of 2 synchronizer stages is required for proper functionality.");
    end
  end


  // The sender in the source domain.
  cdc_2phase_src_clearable #(
    .T           ( T           ),
    .SYNC_STAGES ( SYNC_STAGES )
  ) i_src (
    .rst_ni       ( src_rst_ni                       ),
    .clk_i        ( src_clk_i                        ),
    .clear_i      ( s_src_clear_req                      ),
    .data_i       ( src_data_i                       ),
    .valid_i      ( src_valid_i & !s_src_isolate_req ),
    .ready_o      ( s_src_ready                      ),
    .async_req_o  ( async_req                        ),
    .async_ack_i  ( async_ack                        ),
    .async_data_o ( async_data                       )
  );

  assign src_ready_o = s_src_ready & !s_src_isolate_req;


  // The receiver in the destination domain.
  cdc_2phase_dst_clearable #(
    .T           ( T           ),
    .SYNC_STAGES ( SYNC_STAGES )
  ) i_dst (
    .rst_ni       ( dst_rst_ni                       ),
    .clk_i        ( dst_clk_i                        ),
    .clear_i      ( s_dst_clear_req                      ),
    .data_o       ( dst_data_o                       ),
    .valid_o      ( s_dst_valid                      ),
    .ready_i      ( dst_ready_i & !s_dst_isolate_req ),
    .async_req_i  ( async_req                        ),
    .async_ack_o  ( async_ack                        ),
    .async_data_i ( async_data                       )
  );

  assign dst_valid_o = s_dst_valid & !s_dst_isolate_req;

  // Synchronize the clear and reset signaling in both directions (see header of
  // the cdc_reset_ctrlr module for more details.)
  cdc_reset_ctrlr #(
    .SYNC_STAGES(SYNC_STAGES-1)
  ) i_cdc_reset_ctrlr (
    .a_clk_i         ( src_clk_i           ),
    .a_rst_ni        ( src_rst_ni          ),
    .a_clear_i       ( src_clear_i         ),
    .a_clear_o       ( s_src_clear_req     ),
    .a_clear_ack_i   ( s_src_clear_ack_q   ),
    .a_isolate_o     ( s_src_isolate_req   ),
    .a_isolate_ack_i ( s_src_isolate_ack_q ),
    .b_clk_i         ( dst_clk_i           ),
    .b_rst_ni        ( dst_rst_ni          ),
    .b_clear_i       ( dst_clear_i         ),
    .b_clear_o       ( s_dst_clear_req     ),
    .b_clear_ack_i   ( s_dst_clear_ack_q   ),
    .b_isolate_o     ( s_dst_isolate_req   ),
    .b_isolate_ack_i ( s_dst_isolate_ack_q )
  );

  // Just delay the isolate request by one cycle. We can ensure isolation within
  // one cycle by just deasserting valid and ready signals on both sides of the CDC.
  always_ff @(posedge src_clk_i, negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      s_src_isolate_ack_q <= 1'b0;
      s_src_clear_ack_q   <= 1'b0;
    end else begin
      s_src_isolate_ack_q <= s_src_isolate_req;
      s_src_clear_ack_q   <= s_src_clear_req;
    end
  end

  always_ff @(posedge dst_clk_i, negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      s_dst_isolate_ack_q <= 1'b0;
      s_dst_clear_ack_q   <= 1'b0;
    end else begin
      s_dst_isolate_ack_q <= s_dst_isolate_req;
      s_dst_clear_ack_q   <= s_dst_clear_req;
    end
  end


  assign src_clear_pending_o = s_src_isolate_req; // The isolate signal stays
  // asserted during the whole
  // clear sequence.
  assign dst_clear_pending_o = s_dst_isolate_req;


`ifndef VERILATOR

  no_valid_i_during_clear_i : assert property (
    @(posedge src_clk_i) disable iff (!src_rst_ni) src_clear_i |-> !src_valid_i
  );

`endif

endmodule


/// Half of the two-phase clock domain crossing located in the source domain.
module cdc_2phase_src_clearable #(
  parameter type T = logic,
  parameter int unsigned SYNC_STAGES = 2
) (
  input  logic rst_ni,
  input  logic clk_i,
  input  logic clear_i,
  input  T     data_i,
  input  logic valid_i,
  output logic ready_o,
  output logic async_req_o,
  input  logic async_ack_i,
  output T     async_data_o
);

  (* dont_touch = "true" *)
  logic  req_src_d, req_src_q, ack_synced;
  (* dont_touch = "true" *)
  T data_src_d, data_src_q;

  // Synchronize the async ACK
  sync #(
    .STAGES(SYNC_STAGES)
  ) i_sync(
    .clk_i,
    .rst_ni,
    .serial_i( async_ack_i ),
    .serial_o( ack_synced  )
  );

  // If we receive the clear signal clear the content of the request flip-flop
  // and the data register
  always_comb begin
    data_src_d = data_src_q;
    req_src_d  = req_src_q;
    if (clear_i) begin
      req_src_d  = 1'b0;
    // The req_src and data_src registers change when a new data item is accepted.
    end else if (valid_i && ready_o) begin
      req_src_d  = ~req_src_q;
      data_src_d = data_i;
    end
  end

  `FFNR(data_src_q, data_src_d, clk_i)

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      req_src_q  <= 0;
    end else begin
      req_src_q  <= req_src_d;
    end
  end

  // Output assignments.
  assign ready_o = (req_src_q == ack_synced);
  assign async_req_o = req_src_q;
  assign async_data_o = data_src_q;

// Assertions
`ifndef VERILATOR
  // pragma translate_off
  no_clear_and_request: assume property (
     @(posedge clk_i) disable iff(~rst_ni) (clear_i |-> ~valid_i))
    else $fatal(1, "No request allowed while clear_i is asserted.");

  // pragma translate_on
`endif

endmodule


/// Half of the two-phase clock domain crossing located in the destination
/// domain.
module cdc_2phase_dst_clearable #(
  parameter type T = logic,
  parameter int unsigned SYNC_STAGES = 2
)(
  input  logic rst_ni,
  input  logic clk_i,
  input  logic clear_i,
  output T     data_o,
  output logic valid_o,
  input  logic ready_i,
  input  logic async_req_i,
  output logic async_ack_o,
  input  T     async_data_i
);

  (* dont_touch = "true" *)
  (* async_reg = "true" *)
 logic ack_dst_d, ack_dst_q, req_synced, req_synced_q1;
  (* dont_touch = "true" *)
  T data_dst_d, data_dst_q;


  //Synchronize the request
  sync #(
    .STAGES(SYNC_STAGES)
  ) i_sync(
    .clk_i,
    .rst_ni,
    .serial_i( async_req_i ),
    .serial_o( req_synced  )
  );

  // The ack_dst register changes when a new data item is accepted.
  always_comb begin
    ack_dst_d = ack_dst_q;
    if (clear_i) begin
      ack_dst_d = 1'b0;
    end else if (valid_o && ready_i) begin
      ack_dst_d = ~ack_dst_q;
    end
  end

  // The data_dst register samples when a new data item is presented. This is
  // indicated by a transition in the req_synced line.
  always_comb begin
    data_dst_d = data_dst_q;
    if (req_synced != req_synced_q1 && !valid_o) begin
      data_dst_d = async_data_i;
    end
  end

  `FFNR(data_dst_q, data_dst_d, clk_i)

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      ack_dst_q     <= 0;
      req_synced_q1 <= 1'b0;
    end else begin
      ack_dst_q     <= ack_dst_d;
      // The req_synced_q1 is the delayed version of the synchronized req_synced
      // used to detect transitions in the request.
      req_synced_q1 <= req_synced;
    end
  end

  // Output assignments.
  assign valid_o = (ack_dst_q != req_synced_q1);
  assign data_o = data_dst_q;
  assign async_ack_o = ack_dst_q;

endmodule
/* verilator lint_on DECLFILENAME */
