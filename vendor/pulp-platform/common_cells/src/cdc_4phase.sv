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
// Manuel Eggimann <meggimann@iis.ee.ethz.ch>

/// A 4-phase clock domain crossing. While this is less efficient than a 2-phase
/// CDC, it doesn't suffer from the same issues during one sided resets since
/// the IDLE state doesn't alternate with every transaction.
///
/// Parameters: T - The type of the data to transmit through the CDC.
///
/// Decoupled - If decoupled is disabled, the 4phase cdc will not consume the
/// src item until the handshake with the other side is completed. This
/// increases the latency of the first transaction but has no effect on
/// throughput. However, critical paths might be slightly longer. Use this mode
/// if you want to ensure that there are no in-flight transactions within the
/// CDC.
///
/// SEND_RESET_MSG - If send reset msg is enabled, the 4phase cdc starts sending
/// the RESET_MSG within its' asynchronous reset state. This can be usefull if
/// we need to transmit a message to the other side of the CDC immediately
/// during an async reset even if there is no clock available. This mode is
/// required for proper functionality of the cdc_reset_ctrlr module.
///
/// CONSTRAINT: Requires max_delay of min_period(src_clk_i, dst_clk_i) through
/// the paths async_req, async_ack, async_data.
/* verilator lint_off DECLFILENAME */
module cdc_4phase #(
  parameter type T = logic,
  parameter bit DECOUPLED = 1'b1,
  parameter bit SEND_RESET_MSG = 1'b0,
  parameter T RESET_MSG = T'('0)
)(
  input  logic src_rst_ni,
  input  logic src_clk_i,
  input  T     src_data_i,
  input  logic src_valid_i,
  output logic src_ready_o,

  input  logic dst_rst_ni,
  input  logic dst_clk_i,
  output T     dst_data_o,
  output logic dst_valid_o,
  input  logic dst_ready_i
);

  // Asynchronous handshake signals.
  (* dont_touch = "true" *) logic async_req;
  (* dont_touch = "true" *) logic async_ack;
  (* dont_touch = "true" *) T async_data;

  // The sender in the source domain.
  cdc_4phase_src #(
    .T(T),
    .DECOUPLED(DECOUPLED),
    .SEND_RESET_MSG(SEND_RESET_MSG),
    .RESET_MSG(RESET_MSG)
  ) i_src (
    .rst_ni       ( src_rst_ni  ),
    .clk_i        ( src_clk_i   ),
    .data_i       ( src_data_i  ),
    .valid_i      ( src_valid_i ),
    .ready_o      ( src_ready_o ),
    .async_req_o  ( async_req   ),
    .async_ack_i  ( async_ack   ),
    .async_data_o ( async_data  )
  );

  // The receiver in the destination domain.
  cdc_4phase_dst #(.T(T), .DECOUPLED(DECOUPLED)) i_dst (
    .rst_ni       ( dst_rst_ni  ),
    .clk_i        ( dst_clk_i   ),
    .data_o       ( dst_data_o  ),
    .valid_o      ( dst_valid_o ),
    .ready_i      ( dst_ready_i ),
    .async_req_i  ( async_req   ),
    .async_ack_o  ( async_ack   ),
    .async_data_i ( async_data  )
  );
endmodule


/// Half of the 4-phase clock domain crossing located in the source domain.
module cdc_4phase_src #(
  parameter type T = logic,
  parameter int unsigned SYNC_STAGES = 2,
  parameter bit DECOUPLED = 1'b1,
  parameter bit SEND_RESET_MSG = 1'b0,
  parameter T RESET_MSG = T'('0)
)(
  input  logic rst_ni,
  input  logic clk_i,
  input  T     data_i,
  input  logic valid_i,
  output logic ready_o,
  output logic async_req_o,
  input  logic async_ack_i,
  output T     async_data_o
);

  (* dont_touch = "true" *)
  logic  req_src_d, req_src_q;
  (* dont_touch = "true" *)
  T data_src_d, data_src_q;
  (* dont_touch = "true" *)
  logic  ack_synced;

  typedef enum logic[1:0] {IDLE, WAIT_ACK_ASSERT, WAIT_ACK_DEASSERT} state_e;
  state_e state_d, state_q;

  // Synchronize the async ACK
  sync #(
    .STAGES(SYNC_STAGES)
  ) i_sync(
    .clk_i,
    .rst_ni,
    .serial_i( async_ack_i ),
    .serial_o( ack_synced  )
  );

  // FSM for the 4-phase handshake
  always_comb begin
    state_d    = state_q;
    req_src_d  = 1'b0;
    data_src_d = data_src_q;
    ready_o    = 1'b0;
    case (state_q)
      IDLE: begin
        // If decoupling is disabled, defer assertion of ready until the
        // handshake with the dst is completed
        if (DECOUPLED) begin
          ready_o = 1'b1;
        end else begin
          ready_o = 1'b0;
        end
        // Sample a new item when the valid signal is asserted.
        if (valid_i) begin
          data_src_d = data_i;
          req_src_d  = 1'b1;
          state_d = WAIT_ACK_ASSERT;
        end
      end
      WAIT_ACK_ASSERT: begin
        req_src_d = 1'b1;
        if (ack_synced == 1'b1) begin
          req_src_d = 1'b0;
          state_d   = WAIT_ACK_DEASSERT;
        end
      end
      WAIT_ACK_DEASSERT: begin
        if (ack_synced == 1'b0) begin
          state_d = IDLE;
          if (!DECOUPLED) begin
            ready_o = 1'b1;
          end
        end
      end
      default: begin
        state_d = IDLE;
      end
    endcase
  end

  always_ff @(posedge clk_i, negedge rst_ni) begin
    if (!rst_ni) begin
      state_q <= IDLE;
    end else begin
      state_q <= state_d;
    end
  end

  // Sample the data and the request signal to filter combinational glitches
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      if (SEND_RESET_MSG) begin
        req_src_q  <= 1'b1;
        data_src_q <= RESET_MSG;
      end else begin
        req_src_q  <= 1'b0;
        data_src_q <= T'('0);
      end
    end else begin
      req_src_q  <= req_src_d;
      data_src_q <= data_src_d;
    end
  end

  // Async output assignments.
  assign async_req_o = req_src_q;
  assign async_data_o = data_src_q;

endmodule


/// Half of the 4-phase clock domain crossing located in the destination
/// domain.
module cdc_4phase_dst #(
  parameter type T = logic,
  parameter int unsigned SYNC_STAGES = 2,
  parameter bit DECOUPLED = 1
)(
  input  logic rst_ni,
  input  logic clk_i,
  output T     data_o,
  output logic valid_o,
  input  logic ready_i,
  input  logic async_req_i,
  output logic async_ack_o,
  input  T     async_data_i
);

  (* dont_touch = "true" *)
  logic  ack_dst_d, ack_dst_q;
  (* dont_touch = "true" *)
  logic  req_synced;

  logic  data_valid;

  logic  output_ready;


  typedef enum logic[1:0] {IDLE, WAIT_DOWNSTREAM_ACK, WAIT_REQ_DEASSERT} state_e;
  state_e state_d, state_q;

  //Synchronize the request
  sync #(
    .STAGES(SYNC_STAGES)
  ) i_sync(
    .clk_i,
    .rst_ni,
    .serial_i( async_req_i ),
    .serial_o( req_synced  )
  );

  // FSM for the 4-phase handshake
  always_comb begin
    state_d    = state_q;
    data_valid = 1'b0;
    ack_dst_d  = 1'b0;

    case (state_q)
      IDLE: begin
        // Sample the data upon a new request and transition to the next state
        if (req_synced == 1'b1) begin
          data_valid = 1'b1;
          if (output_ready == 1'b1) begin
            state_d = WAIT_REQ_DEASSERT;
          end else begin
            state_d = WAIT_DOWNSTREAM_ACK;
          end
        end
      end

      WAIT_DOWNSTREAM_ACK: begin
        data_valid       = 1'b1;
        if (output_ready == 1'b1) begin
          state_d    = WAIT_REQ_DEASSERT;
          ack_dst_d  = 1'b1;
        end
      end

      WAIT_REQ_DEASSERT: begin
        ack_dst_d = 1'b1;
        if (req_synced == 1'b0) begin
          ack_dst_d = 1'b0;
          state_d   = IDLE;
        end
      end

      default: begin
        state_d = IDLE;
      end
    endcase
  end

  always_ff @(posedge clk_i, negedge rst_ni) begin
    if (!rst_ni) begin
      state_q <= IDLE;
    end else begin
      state_q <= state_d;
    end
  end

  // Filter glitches on ack signal before sending it through the asynchronous channel
  always_ff @(posedge clk_i, negedge rst_ni) begin
    if (!rst_ni) begin
      ack_dst_q <= 1'b0;
    end else begin
      ack_dst_q <= ack_dst_d;
    end
  end

  if (DECOUPLED) begin : gen_decoupled
    // Decouple the output from the asynchronous data bus without introducing
    // additional latency by inserting a spill register
    spill_register #(
      .T(T),
      .Bypass(1'b0)
    ) i_spill_register (
      .clk_i,
      .rst_ni,
      .valid_i(data_valid),
      .ready_o(output_ready),
      .data_i(async_data_i),
      .valid_o,
      .ready_i,
      .data_o
    );
  end else begin : gen_not_decoupled
    assign valid_o      = data_valid;
    assign output_ready = ready_i;
    assign data_o       = async_data_i;
  end

  // Output assignments.
  assign async_ack_o = ack_dst_q;

endmodule
/* verilator lint_on DECLFILENAME */
