import cvxif_exp_coprocessor_pkg::*;

module cvxif_exp_coprocessor_ctrl (
    input logic clk_i,
    input logic rst_ni,
    input logic [6:0] x_int,  // integer part of x
    input logic efifo_empty,  // Indicate if their is an insturction to execute
    input logic x_result_ready,
    input logic [3:0] add_counter,  // counter for addition (polynomial calculation)
    input logic [3:0] m_counter,  // counter for multiplication (calculation with integer part)
    output logic x_result_valid,
    output logic M_mux,  // Multiplexor for multiplication (0 : x_fract; 1 : ExpIntLUT)
    output logic mc_enable,  // enable m_counter
    output logic [1:0] Add_mux, // Multiplexor for addition (0 : ExpPolyLut; 1 : a+b; 2 : data from mult)
    output logic ac_enable,  // enable add_counter
    output logic we_reg,  // write enable for data_o register
    output logic pop_efifo
);

  exp_coprocessor_state_e state_d, state_q;

  // Combinational of the state
  always_comb begin
    state_d = state_q;
    x_result_valid = 0;
    M_mux = 0;
    Add_mux = '0;
    we_reg = 0;
    pop_efifo = 0;
    mc_enable = 0;
    ac_enable = 0;

    case (state_q)
      IDLE: begin
        if (!efifo_empty) begin
          we_reg    = 1;
          M_mux     = 0;
          Add_mux   = 0;
          ac_enable = 1;
          state_d   = P_LOOP;
        end
      end

      P_LOOP: begin
        we_reg    = 1;
        M_mux     = 0;
        Add_mux   = 1;
        ac_enable = 1;
        state_d   = (add_counter == 4) ? P_TO_EXP : P_LOOP;
      end

      P_TO_EXP: begin
        we_reg    = 1;
        M_mux     = 1;
        Add_mux   = 2;
        mc_enable = 1;
        state_d   = EXP_LOOP;
      end

      EXP_LOOP: begin
        we_reg    = 1;
        M_mux     = 1;
        Add_mux   = 2;
        mc_enable = 1;
        state_d   = (m_counter == 6) ? EXP_END : EXP_LOOP;
      end

      EXP_END: begin
        we_reg         = 0;
        x_result_valid = 1;
        if (x_result_ready) begin
          pop_efifo = 1;
          state_d   = IDLE;
        end
      end
    endcase
  end


  // state register
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) state_q <= IDLE;
    else state_q <= state_d;
  end

endmodule
