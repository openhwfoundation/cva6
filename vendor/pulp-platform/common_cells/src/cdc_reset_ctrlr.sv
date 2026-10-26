//-----------------------------------------------------------------------------
// Title : CDC Clear Signaling Synchronization
// -----------------------------------------------------------------------------
// File : cdc_clear_propagator.sv Author : Manuel Eggimann
// <meggimann@iis.ee.ethz.ch> Created : 22.12.2021
// -----------------------------------------------------------------------------
// Description :
//
// This module is mainly used internally to synchronize the clear requests
// between both sides of a CDC module. It aims to solve the problem of
// initiating a CDC clear, reset one-sidedly without running into
// reset-domain-crossing issues and breaking CDC protocol assumption.
//
// Problem Formulation:
//
// CDC implementations usually face the issue that one side of the CDC must not
// be cleared without clearing the other side. E.g. clearing the write-pointer
// without clearing the read-pointer in a gray-counting CDC FIFO results in an
// invalid fill-state an may cause spurious transactions of invalid data to be
// propagated accross the CDC. A similar effect is caused in 2-phase CDC
// implementations.
//
// A naive mitigation technique would be to reset both domains asynchronously
// with the same reset signal. This will cause intra-clock domain RDC issues
// since the asynchronous clear event (assertion of the reset signal) might
// happen close to the active edge of the CDC's periphery and thus might induce
// metastability. A better, but still flawed approach would be to naively
// synchronize assertion AND deassertion (the usual rst sync only synchronize
// deassertion) of the resets into the respective other domain. However, this
// might cause the classic issue of fast-to-slow clock domain crossing where the
// clear signal is not asserted long enough to be captured by the receiving
// side. The common mitigation strategy is to use a feedback acknowledge signal
// to handshake the reset request into the other domain. One even more peculiar
// corner case this approach might suffer is the scenario where the synchronized
// clear signal arrives at the other side of the CDC within or even worse after
// the same clock cylce that the other domain crossing signals (e.g. read/write
// pointers) are cleared. In this scenario, multiple signals change within the
// same clock cycle and due to metastability we cannot be sure, that the other
// side of the CDC sees the reset assertion before the first bits of e.g. the
// write/read pointer start to switch to their reset state. Care must also be
// taken to handle the corner cases where both sides are reset simultaneously or
// the case where one side leaves reset earlier than the other.
//
// How this Module Works
//
// This module has two interfaces, the 'a' side and the 'b' side. Each side can
// be triggered using the a/b_clear_i signal or (optionally) by the asynchronous
// a/b_rst_ni. Once e.g. 'a' is triggered it will initiate a clear sequence that
// first asserts an 'a_isolate_o' signal, waits until the external circuitry
// acknowledges isolation using the 'a_isolate_ack_i'. Then the module asserts
// the 'a_clear_o' signals before some cycles later, the isolate signal is
// deasserted. This sequence ensures that no transactions can arrive to the CDC
// while the state is cleared. Now the important part is, that those four phases
// (asser isolate, assert clear, deassert clear, deassert isolate) are mirrored
// on the other side ('b') in lock-step. The cdc_reset_ctrlr module uses a
// dedicated 4-phase handshaking CDC to transmit the current phase of the clear
// sequence to the other domain. We use a 4-phase rather than a 2-phase CDC to
// avoid the issues of one-sided async reset that might trigger spurious
// transactions. Furthermore, the 4-phase CDC within this module is operated in
// a special mode: DECOUPLED=0 ensures that there are no in-flight transactions.
// The src side only consumes the item once the destination side acknowledged
// the receiption. This property is required to transition through the phases in
// lock-step. Furthermore, (SEND_RESET_MSG=1) will cause the src side of the
// 4-phase CDC to immediately initiate the isolation phase in the dst domain
// upon asynchronous reset regardless how long the async reset stays asserted or
// whether the source clock is gated. Both sides of this module independently
// generate the sequence signals as an initiator (triggered by the clear_i or
// rst_ni signal) or receiver (trigerred for the other side). The or-ed version
// of initiator and receiver are used to generate the actual a/b_isolate_o and
// a/b_clear_o signal. That way, it doesn't matter wheter both sides
// simulatenously trigger a clear sequence, proper sequencing is still
// guaranteed.
//
// The time it takes to complete an entire clear sequence can be bounded as follows:
//
// t_clear <= 20*T+16*SYNC_STAGES*T, with T=max(T_a, T_b) (clock periods of src and dst)
//
// How to Use the Module
//
// Instantiate the module within your CDC and connect a/b_clk_i, the
// asyncrhonous a/b_rst_ni and the synchronous a/b_clear_i signals. The 'a' and
// 'b' port are entirely symetric so it doesn't matter whether you connect src
// to 'a' or 'b'. If you enable support for async reset
// (CLEAR_ON_ASYNC_RESET==1), parametrize the number of synchronization stages
// (for metastability resolution) to be strictly less than the latency of the
// CDC. E.g. if your CDC uses 3 (the minimum) sync stages, parametrize this
// module with SYNC_STAGES < 2! Your CDC must implement a src/dst_clear_i port
// that SYNCHRONOUSLY clears all FFs on the respective side. Connect the CDC's
// src/dst_clear ports to this module's a/b_clear_o port. Once the a/b_isolate_o
// signal is asserted, the respective CDC side (src/dst) must be isolated from
// the outside world (i.e. must no longer accept any transaction on the src side
// and cease presenting or even withdrawing data on the dst side). Once your CDC
// side is isolated (depending on protocol this might take several cycles),
// assert the a/b_isolate_ack_i signal.
//
// -----------------------------------------------------------------------------
// Copyright (C) 2021 ETH Zurich, University of Bologna Copyright and related
// rights are licensed under the Solderpad Hardware License, Version 0.51 (the
// "License"); you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law or
// agreed to in writing, software, hardware and materials distributed under this
// License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS
// OF ANY KIND, either express or implied. See the License for the specific
// language governing permissions and limitations under the License.
// SPDX-License-Identifier: SHL-0.51
// -----------------------------------------------------------------------------

module cdc_reset_ctrlr
  import cdc_reset_ctrlr_pkg::*;
 #(
  /// The number of synchronization stages to use for the
  //clear signal request/acknowledge. Must be less or
  //equal to the number of sync stages used in the CDC
  parameter int unsigned SYNC_STAGES = 2,
  /// Whether an asynchronous reset shall cause a clear
  /// request to be sent to the other side.
  parameter logic CLEAR_ON_ASYNC_RESET = 1'b1
)(
  // Side A (both sides are symmetric)
  input logic  a_clk_i,
  input logic  a_rst_ni,
  input logic  a_clear_i,
  output logic a_clear_o,
  input logic a_clear_ack_i,
  output logic a_isolate_o,
  input logic  a_isolate_ack_i,
  // Side B (both sides are symmetric)
  input logic  b_clk_i,
  input logic  b_rst_ni,
  input logic  b_clear_i,
  output logic b_clear_o,
  input logic  b_clear_ack_i,
  output logic b_isolate_o,
  input logic  b_isolate_ack_i
);

  (* dont_touch = "true" *)
  logic        async_a2b_req, async_b2a_ack;
  (* dont_touch = "true" *)
  clear_seq_phase_e async_a2b_next_phase;
  (* dont_touch = "true" *)
  logic        async_b2a_req, async_a2b_ack;
  (* dont_touch = "true" *)
  clear_seq_phase_e async_b2a_next_phase;

  cdc_reset_ctrlr_half #(
    .SYNC_STAGES          ( SYNC_STAGES          ),
    .CLEAR_ON_ASYNC_RESET ( CLEAR_ON_ASYNC_RESET )
  ) i_cdc_reset_ctrlr_half_a (
    .clk_i              ( a_clk_i              ),
    .rst_ni             ( a_rst_ni             ),
    .clear_i            ( a_clear_i            ),
    .clear_o            ( a_clear_o            ),
    .clear_ack_i        ( a_clear_ack_i        ),
    .isolate_o          ( a_isolate_o          ),
    .isolate_ack_i      ( a_isolate_ack_i      ),
    (* async *) .async_next_phase_o ( async_a2b_next_phase ),
    (* async *) .async_req_o        ( async_a2b_req        ),
    (* async *) .async_ack_i        ( async_b2a_ack        ),
    (* async *) .async_next_phase_i ( async_b2a_next_phase ),
    (* async *) .async_req_i        ( async_b2a_req        ),
    (* async *) .async_ack_o        ( async_a2b_ack        )
  );

    cdc_reset_ctrlr_half #(
    .SYNC_STAGES          ( SYNC_STAGES          ),
    .CLEAR_ON_ASYNC_RESET ( CLEAR_ON_ASYNC_RESET )
  ) i_cdc_reset_ctrlr_half_b (
    .clk_i              ( b_clk_i              ),
    .rst_ni             ( b_rst_ni             ),
    .clear_i            ( b_clear_i            ),
    .clear_o            ( b_clear_o            ),
    .clear_ack_i        ( b_clear_ack_i        ),
    .isolate_o          ( b_isolate_o          ),
    .isolate_ack_i      ( b_isolate_ack_i      ),
    (* async *) .async_next_phase_o ( async_b2a_next_phase ),
    (* async *) .async_req_o        ( async_b2a_req        ),
    (* async *) .async_ack_i        ( async_a2b_ack        ),
    (* async *) .async_next_phase_i ( async_a2b_next_phase ),
    (* async *) .async_req_i        ( async_a2b_req        ),
    (* async *) .async_ack_o        ( async_b2a_ack        )
  );
endmodule


module cdc_reset_ctrlr_half
  import cdc_reset_ctrlr_pkg::*;
#(
  /// The number of synchronization stages to use for the
  //clear signal request/acknowledge. Must be less or
  //equal to the number of sync stages used in the CDC
  parameter int unsigned SYNC_STAGES = 2,
  /// Whether an asynchronous reset shall cause a clear
  /// request to be sent to the other side.
  parameter logic CLEAR_ON_ASYNC_RESET = 1'b1
)(
  // Synchronous side
  input logic                clk_i,
  input logic                rst_ni,
  input logic                clear_i,
  output logic               isolate_o,
  input logic                isolate_ack_i,
  output logic               clear_o,
  input logic                clear_ack_i,
  // Asynchronous clear sequence hanshaking
  output clear_seq_phase_e   async_next_phase_o,
  output logic               async_req_o,
  input logic                async_ack_i,
  input clear_seq_phase_e    async_next_phase_i,
  input logic                async_req_i,
  output logic               async_ack_o
);


  // How this module works:

  // The module is split into two parts. The initiator part consists of an FSM
  // that is triggered by the clear_i signal and transitions through reset
  // sequence. During those transitions, the `initiator_isolate_out` and
  // `initiator_clear_out` signals are asserted appropriately.

  // The receiver part receives the state transitions from the other clock
  // domain (initiator part of the `cdc_reset_ctrlr_half` instance in the other
  // clock domain) and asserts the `receiver_isolate_out` and
  // `receiver_clear_out` appropriately (considering the `isolate_ack_i`
  // signal).

  // In both, the initiator and the receiver part, the respective FSM
  // transitions through 4 phases. In the ISOLATE phase, the isolate signal is
  // asserted and the connected CDCs are expected to block all further
  // interactions with the outside world and acknowledge the isolation with the
  // isolate_ack_i signal. In the CLEAR phase, the clear signal is asserted
  // which resets the internal state of the CDC while keeping the isolate signal
  // asserted. In the POST_CLEAR phase, the clear signal is deasserted. Finally,
  // when returning to the IDLE phase, the isolate signal is deasserted to
  // continue normal operation. The FSM uses a dedicated 4-phase handshaking CDC
  // to transition between the phases in lock-step and transmits the current
  // state to the other domain to avoid issues if the other domain is reset
  // asynchronously while a clear procedure is pending.

  //---------------------- Initiator Side ----------------------
  // Sends clear sequence state transitions to the other side.
   typedef enum logic[3:0] {
     IDLE,
     ISOLATE,
     WAIT_ISOLATE_PHASE_ACK,
     WAIT_ISOLATE_ACK,
     CLEAR,
     WAIT_CLEAR_PHASE_ACK,
     WAIT_CLEAR_ACK,
     POST_CLEAR,
     FINISHED
  } initiator_state_e;
  initiator_state_e initiator_state_d, initiator_state_q;

  // The current phase of the clear sequence, sent to the other side using a
  // 4-phase CDC
  clear_seq_phase_e          initiator_clear_seq_phase;
  logic                      initiator_phase_transition_req;
  logic                      initiator_phase_transition_ack;
  logic                      initiator_isolate_out;
  logic                      initiator_clear_out;

  always_comb begin
    initiator_state_d              = initiator_state_q;
    initiator_phase_transition_req = 1'b0;
    initiator_isolate_out          = 1'b0;
    initiator_clear_out            = 1'b0;
    initiator_clear_seq_phase      = CLEAR_PHASE_IDLE;

    case (initiator_state_q)
      IDLE: begin
        if (clear_i) begin
          initiator_state_d = ISOLATE;
        end
      end

      ISOLATE: begin
        initiator_phase_transition_req = 1'b1;
        initiator_clear_seq_phase      = CLEAR_PHASE_ISOLATE;
        initiator_isolate_out          = 1'b1;
        initiator_clear_out            = 1'b0;
        if (initiator_phase_transition_ack && isolate_ack_i) begin
          initiator_state_d = CLEAR;
        end else if (initiator_phase_transition_ack) begin
          initiator_state_d = WAIT_ISOLATE_ACK;
        end else if (isolate_ack_i) begin
          initiator_state_d = WAIT_ISOLATE_PHASE_ACK;
        end
      end

      WAIT_ISOLATE_ACK: begin
        initiator_isolate_out     = 1'b1;
        initiator_clear_out       = 1'b0;
        initiator_clear_seq_phase = CLEAR_PHASE_ISOLATE;
        if (isolate_ack_i) begin
          initiator_state_d = CLEAR;
        end
      end

      WAIT_ISOLATE_PHASE_ACK: begin
        initiator_phase_transition_req = 1'b1;
        initiator_clear_seq_phase      = CLEAR_PHASE_ISOLATE;
        initiator_isolate_out          = 1'b1;
        initiator_clear_out            = 1'b0;
        if (initiator_phase_transition_ack) begin
          initiator_state_d = CLEAR;
        end
      end

      CLEAR: begin
        initiator_isolate_out          = 1'b1;
        initiator_clear_out            = 1'b1;
        initiator_phase_transition_req = 1'b1;
        initiator_clear_seq_phase      = CLEAR_PHASE_CLEAR;
        if (initiator_phase_transition_ack && clear_ack_i) begin
          initiator_state_d = POST_CLEAR;
        end else if (initiator_phase_transition_ack) begin
          initiator_state_d = WAIT_CLEAR_ACK;
        end else if (clear_ack_i) begin
          initiator_state_d = WAIT_CLEAR_PHASE_ACK;
        end
      end

      WAIT_CLEAR_ACK: begin
        initiator_isolate_out     = 1'b1;
        initiator_clear_out       = 1'b1;
        initiator_clear_seq_phase = CLEAR_PHASE_CLEAR;
        if (clear_ack_i) begin
          initiator_state_d = POST_CLEAR;
        end
      end

      WAIT_CLEAR_PHASE_ACK: begin
        initiator_phase_transition_req = 1'b1;
        initiator_clear_seq_phase      = CLEAR_PHASE_CLEAR;
        initiator_isolate_out          = 1'b1;
        initiator_clear_out            = 1'b1;
        if (initiator_phase_transition_ack) begin
          initiator_state_d = POST_CLEAR;
        end
      end

      POST_CLEAR: begin
        initiator_isolate_out          = 1'b1;
        initiator_clear_out            = 1'b0;
        initiator_phase_transition_req = 1'b1;
        initiator_clear_seq_phase      = CLEAR_PHASE_POST_CLEAR;
        if (initiator_phase_transition_ack) begin
          initiator_state_d = FINISHED;
        end
      end

      FINISHED: begin
        initiator_isolate_out          = 1'b1;
        initiator_clear_out            = 1'b0;
        initiator_phase_transition_req = 1'b1;
        initiator_clear_seq_phase      = CLEAR_PHASE_IDLE;
        if (initiator_phase_transition_ack) begin
          initiator_state_d = IDLE;
        end
      end

      default: begin
        initiator_state_d = ISOLATE;
      end
    endcase
  end

  always_ff @(posedge clk_i, negedge rst_ni) begin
    if (!rst_ni) begin
      if (CLEAR_ON_ASYNC_RESET) begin
        initiator_state_q <= ISOLATE; // Start in the ISOLATE state which is
                                        // the first state of a clear sequence.
      end else begin
        initiator_state_q <= IDLE;
      end
    end else begin
      initiator_state_q <= initiator_state_d;
    end
  end

  // Initiator CDC SRC
  // We use 4 phase handshaking. That way it doesn't matter if one side is
  // sudenly reset asynchronously. With a 2phase CDC, one-sided async resets might
  // introduce spurios transactions.

  cdc_4phase_src #(
    .T(clear_seq_phase_e),
    .SYNC_STAGES(2),
    .DECOUPLED(0), // Important! The CDC must not be in decoupled mode.
                   // Otherwise we will proceed to the next state without
                   // waiting for the new state to arrive on the other side.
    .SEND_RESET_MSG(CLEAR_ON_ASYNC_RESET), // Send the ISOLATE phase request immediately on async
                                           // reset if async reset synchronization is enabled.
    .RESET_MSG(CLEAR_PHASE_ISOLATE)
  ) i_state_transition_cdc_src(
    .clk_i,
    .rst_ni,
    .data_i(initiator_clear_seq_phase),
    .valid_i(initiator_phase_transition_req),
    .ready_o(initiator_phase_transition_ack),
    .async_req_o,
    .async_ack_i,
    .async_data_o(async_next_phase_o)
  );


  //---------------------- Receiver Side ----------------------
  // This part of the circuit receives clear sequence state transitions from the
  // other side.

  clear_seq_phase_e receiver_phase_q;
  clear_seq_phase_e receiver_next_phase;
  logic receiver_phase_req, receiver_phase_ack;

  logic receiver_isolate_out;
  logic receiver_clear_out;

  cdc_4phase_dst #(
    .T(clear_seq_phase_e),
    .SYNC_STAGES(2),
    .DECOUPLED(0) // Important! The CDC must not be in decoupled mode. Otherwise
                  // we will proceed to the next state without waiting for the
                  // new state to arrive on the other side.
  ) i_state_transition_cdc_dst(
    .clk_i,
    .rst_ni,
    .data_o(receiver_next_phase),
    .valid_o(receiver_phase_req),
    .ready_i(receiver_phase_ack),
    .async_req_i,
    .async_ack_o,
    .async_data_i(async_next_phase_i)
  );

  always_ff @(posedge clk_i, negedge rst_ni) begin
    if (!rst_ni) begin
      receiver_phase_q <= CLEAR_PHASE_IDLE;
    end else if (receiver_phase_req && receiver_phase_ack) begin
      receiver_phase_q <= receiver_next_phase;
    end
  end

  always_comb begin
    receiver_isolate_out = 1'b0;
    receiver_clear_out   = 1'b0;
    receiver_phase_ack   = 1'b0;

    // If there is a new phase requestd, checkout which one it is and act accordingly
    if (receiver_phase_req) begin
      case (receiver_next_phase)
        CLEAR_PHASE_IDLE: begin
          receiver_clear_out   = 1'b0;
          receiver_isolate_out = 1'b0;
          receiver_phase_ack   = 1'b1;
        end

        CLEAR_PHASE_ISOLATE: begin
          receiver_clear_out   = 1'b0;
          receiver_isolate_out = 1'b1;
          // Wait for the isolate to be acknowledged before ack'ing the phase
          receiver_phase_ack = isolate_ack_i;
        end

        CLEAR_PHASE_CLEAR: begin
          receiver_clear_out   = 1'b1;
          receiver_isolate_out = 1'b1;
          // Wait for the clear to be acknowledged before ack'ing the phase
          receiver_phase_ack   = clear_ack_i;
        end

        CLEAR_PHASE_POST_CLEAR: begin
          receiver_clear_out   = 1'b0;
          receiver_isolate_out = 1'b1;
          receiver_phase_ack   = 1'b1;
        end

        default: begin
          receiver_clear_out   = 1'b0;
          receiver_isolate_out = 1'b0;
          receiver_phase_ack   = 1'b0;
        end
      endcase

    end else begin
      // No phase change is requested for the moment. Act according to the
      // current phase signal
      case (receiver_phase_q)
        CLEAR_PHASE_IDLE: begin
          receiver_clear_out   = 1'b0;
          receiver_isolate_out = 1'b0;
        end

        CLEAR_PHASE_ISOLATE: begin
          receiver_clear_out   = 1'b0;
          receiver_isolate_out = 1'b1;
        end

        CLEAR_PHASE_CLEAR: begin
          receiver_clear_out   = 1'b1;
          receiver_isolate_out = 1'b1;
        end

        CLEAR_PHASE_POST_CLEAR: begin
          receiver_clear_out   = 1'b0;
          receiver_isolate_out = 1'b1;
        end

        default: begin
          receiver_clear_out   = 1'b0;
          receiver_isolate_out = 1'b0;
          receiver_phase_ack   = 1'b0;
        end
      endcase
    end
  end

  // Output Assignment

  // The clear and isolate signal are the OR combination of the receiver and
  // initiator's clear/isolate signal. This ensures that the correct sequence is
  // followed even if both sides are cleared independently at roughly the same
  // time.
  assign clear_o = initiator_clear_out || receiver_clear_out;
  assign isolate_o = initiator_isolate_out || receiver_isolate_out;

endmodule : cdc_reset_ctrlr_half
