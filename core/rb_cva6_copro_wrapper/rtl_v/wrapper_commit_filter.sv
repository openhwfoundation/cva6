// Original Author: Maxime TRAVAILLARD (fixed-term.maxime.travaillard@fr.bosch.com)

// Module to handle commit_kill and dispatch non-speculative instruction to their corresponding coprocessor

module wrapper_commit_filter
  import cvxif_pkg::*;
#(
    parameter COPRO_NBR = cvxif_wrapper_pkg::COPRO_NBR,
    parameter COPRO_BITS_NBR = $clog2(COPRO_NBR)
) (
    input logic clk_i,  // Clock
    input logic rst_ni,  // Asynchronous reset active low
    input x_issue_req_t issue_req_i,
    input logic [COPRO_BITS_NBR-1:0] coprocessor_index_i,
    input logic commit_valid_i,
    input x_commit_t commit_i,
    input logic fifo_empty_i,
    output logic                         pop_o,       // To unqueue an instruction that is sent to a coprocessor or need to be killed
    output x_issue_req_t [COPRO_NBR-1:0] issue_req_o, // array, each column of the array correspond to a issue_req, indexed by his copro_index to go to the corresponding coprocessor
    output logic [COPRO_NBR-1:0]         issue_valid_o // array, each column of the array correspond to a issue_valid, indexed by his copro_index to go to the corresponding coprocessor
);

  // youngest id that need to be executed
  logic [cvxif_pkg::X_ID_WIDTH-1:0] id_searched_q, id_searched_d;

  // state definition
  typedef enum {
    Init,
    InstrToDo,
    InstrToBeKilled,
    InstrToKill
  } commit_filter_state_e;

  commit_filter_state_e commit_filter_state_d, commit_filter_state_q;

  // Combinational of the state
  always_comb begin
    commit_filter_state_d = commit_filter_state_q;
    id_searched_d = id_searched_q;
    pop_o = '0;
    issue_req_o = '0;
    issue_valid_o = 'b0;
    case (commit_filter_state_q)
      Init: begin
        id_searched_d = 0;
        if (commit_valid_i) begin
          id_searched_d = commit_i.id;
          if (!commit_i.x_commit_kill) begin
            if (issue_req_i.id == id_searched_d) begin
              issue_req_o[coprocessor_index_i] = (~fifo_empty_i) ? issue_req_i : '0;
              issue_valid_o[coprocessor_index_i] = ~fifo_empty_i;
              pop_o = ~fifo_empty_i;
              commit_filter_state_d = Init;
            end else begin
              issue_req_o[coprocessor_index_i] = (~fifo_empty_i) ? issue_req_i : '0;
              issue_valid_o[coprocessor_index_i] = ~fifo_empty_i;
              pop_o = ~fifo_empty_i;
              commit_filter_state_d = InstrToDo;
            end
          end else begin
            commit_filter_state_d = InstrToBeKilled;
          end
        end
      end

      InstrToDo: begin
        issue_req_o[coprocessor_index_i] = (~fifo_empty_i) ? issue_req_i : '0;
        issue_valid_o[coprocessor_index_i] = ~fifo_empty_i;
        pop_o = ~fifo_empty_i;
        if (issue_req_i.id == id_searched_d) begin
          commit_filter_state_d = Init;
        end
        if (commit_valid_i) begin
          id_searched_d = commit_i.id;
          commit_filter_state_d = (commit_i.x_commit_kill) ? InstrToBeKilled : InstrToDo;
        end
      end

      InstrToBeKilled: begin
        if (commit_valid_i) begin
          id_searched_d = commit_i.id;
          commit_filter_state_d = InstrToKill;
        end
      end

      InstrToKill: begin
        pop_o = ~fifo_empty_i;
        if (issue_req_i.id == id_searched_d) begin
          issue_req_o[coprocessor_index_i] = (~fifo_empty_i) ? issue_req_i : '0;
          issue_valid_o[coprocessor_index_i] = ~fifo_empty_i;
          commit_filter_state_d = Init;
        end
      end

      default: begin
        commit_filter_state_d = Init;
      end
    endcase

  end

  // state register
  always_ff @(posedge clk_i, negedge rst_ni) begin
    if (!rst_ni | fifo_empty_i) begin
      commit_filter_state_q <= Init;
      id_searched_q <= 0;
    end else begin
      commit_filter_state_q <= commit_filter_state_d;
      id_searched_q <= id_searched_d;
    end
  end

endmodule
