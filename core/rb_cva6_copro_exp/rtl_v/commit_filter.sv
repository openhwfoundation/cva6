// Original Author: Maxime TRAVAILLARD (fixed-term.maxime.travaillard@fr.bosch.com)

// Module to handle commit signals and send instr or not to the executing fifo

module commit_filter
  import cvxif_pkg::*;
(
    input  logic         clk_i,           // Clock
    input  logic         rst_ni,          // Asynchronous reset active low
    input  x_issue_req_t issue_req_i,
    input  logic         commit_valid_i,
    input  x_commit_t    commit_i,
    input  logic         sfifo_empty_i,   // speculative FIFO or sFIFO
    input  logic         efifo_full_i,    // executive FIFO or eFIFO
    output logic         pop_o,           // poping issue in sFIFO
    output x_issue_req_t issue_req_o,     // issue that need ot be executed
    output logic         push_o           // pushing issue in eFIFO
);

  // youngest id that need to be executed
  logic [cva6_config_pkg::CVA6ConfigNrScoreboardEntries-1:0] id_searched_q, id_searched_d;

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
    push_o = 'b0;
    case (commit_filter_state_q)
      Init: begin
        id_searched_d = 0;
        if (commit_valid_i) begin
          id_searched_d = commit_i.id;
          if (!commit_i.x_commit_kill) begin
            if (~efifo_full_i) begin
              if (issue_req_i.id == id_searched_d) begin
                // id searched is oldest id in FIFO, just pop and send and don't change state
                issue_req_o = (~sfifo_empty_i) ? issue_req_i : '0;
                push_o = ~sfifo_empty_i;
                pop_o = ~sfifo_empty_i;
                commit_filter_state_d = Init;
              end else begin
                issue_req_o = (~sfifo_empty_i) ? issue_req_i : '0;
                push_o = ~sfifo_empty_i;
                pop_o = ~sfifo_empty_i;
                commit_filter_state_d = InstrToDo;
              end
            end else begin
              commit_filter_state_d = InstrToDo;
            end
          end else begin
            commit_filter_state_d = InstrToBeKilled;
          end
        end
      end

      InstrToDo: begin
        if (~efifo_full_i) begin
          issue_req_o = (~sfifo_empty_i) ? issue_req_i : '0;
          push_o = ~sfifo_empty_i;
          pop_o = ~sfifo_empty_i;
          if (issue_req_i.id == id_searched_d) begin
            commit_filter_state_d = Init;
          end
        end
      end

      InstrToBeKilled: begin
        if (commit_valid_i) begin
          id_searched_d = commit_i.id;
          commit_filter_state_d = InstrToKill;
        end
      end

      InstrToKill: begin
        pop_o = ~sfifo_empty_i;
        if (issue_req_i.id == id_searched_d) begin
          // id searched correspond to a valid instr so it is sent.
          issue_req_o = (~sfifo_empty_i) ? issue_req_i : '0;
          push_o = ~sfifo_empty_i;
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
    if (!rst_ni | sfifo_empty_i) begin
      commit_filter_state_q <= Init;
      id_searched_q <= 0;
    end else begin
      commit_filter_state_q <= commit_filter_state_d;
      id_searched_q <= id_searched_d;
    end
  end

endmodule
