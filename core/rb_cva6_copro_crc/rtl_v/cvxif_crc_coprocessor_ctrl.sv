



module cvxif_crc_coprocessor_ctrl
  import cvxif_pkg::*;
  import cvxif_crc_instr_pkg::*;
  import cvxif_crc_coprocessor_pkg::*;
(
    input  logic            clk_i,         // Clock
    input  logic            rst_ni,        // Asynchronous reset active low
    input  logic            req_valid_i,
    input  crc_size_e       crc_size_i,
    input  crc_mask_e       crc_mask_i,
    input  logic            res_ready_i,
    output logic            res_valid_o,
    output logic      [3:0] xor_en_o,
    output logic            crc_in_sel_o,
    output logic            data_in_sel_o
);


  crc_coprocessor_state_e state_d, state_q;


  always_ff @(posedge clk_i or negedge rst_ni) begin : p_regs
    if (!rst_ni) state_q <= IDLE;
    else state_q <= state_d;
  end

  /* xor_en :
  CRC8 :
    1 1 1 1 cycle 1
    1 1 1 1 cycle 2

  CRC16:
    1 0 0 0 Cycle 1
    1 0 0 0 Cycle 2

  CRC32:
    1 0 0 0 Cycle 1
    0 0 0 0 Cycle 2
  */

  always_comb begin : p_fsm
    // default assignment
    state_d       = state_q;
    xor_en_o      = 4'b1111;
    res_valid_o   = 1'b0;
    crc_in_sel_o  = 1'b0;
    data_in_sel_o = 1'b0;
    // FSM states definitns es
    case (state_q)
      //////////////////////////////////
      // wait for an incoming request
      IDLE:
      if (req_valid_i) begin
        case (crc_size_i)
          CRC8: state_d = CRC8_1;
          CRC16: state_d = CRC16_1;
          CRC32: state_d = CRC32_1;
          default: state_d = CRC32_1;
        endcase

        case (crc_size_i)
          CRC8: xor_en_o = 4'b1111;
          CRC16: xor_en_o = 4'b1101;
          CRC32: xor_en_o = 4'b1101;
          default: xor_en_o = 4'b1111;
        endcase
      end

      //CRC8, cycle 1
      CRC8_1: begin
        xor_en_o      = 4'b1111;
        crc_in_sel_o  = 1'b1;  // loop CRC_out reg => CRC_in
        data_in_sel_o = 1'b1;
        if (crc_mask_i == MASK0 || crc_mask_i == MASK1) begin  // done for 8 and 16 bits
          res_valid_o = 1;
          if (res_ready_i) begin
            state_d = IDLE;
          end
        end else begin
          state_d = CRC8_2;
        end
      end

      //CRC8, cycle 2 for 3*8 bits or 4*8bits
      CRC8_2: begin
        xor_en_o = 4'b1111;
        res_valid_o = 1;
        if (res_ready_i) begin
          state_d = IDLE;
        end
      end

      //CRC16, cycle1
      CRC16_1: begin
        xor_en_o      = 4'b1101;
        crc_in_sel_o  = 1'b1;  // loop CRC_out reg => CRC_in
        data_in_sel_o = 1'b1;
        if (crc_mask_i == MASK1) begin  // done for 16 bits
          res_valid_o = 1;
          if (res_ready_i) begin
            state_d = IDLE;
          end
        end else begin
          state_d = CRC16_2;
        end
      end

      //CRC16, cycle2
      CRC16_2: begin
        res_valid_o = 1;
        if (res_ready_i) begin
          state_d = IDLE;
        end
      end

      //CRC32, cycle1
      CRC32_1: begin
        xor_en_o     = 4'b1100;
        crc_in_sel_o = 1'b1;  // loop CRC_out reg => CRC_in
        state_d      = CRC32_2;
      end

      //CRC32, cycle2
      CRC32_2: begin
        res_valid_o  = 1;
        crc_in_sel_o = 1'b0;
        xor_en_o     = 4'b1100;
        if (res_ready_i) begin
          state_d = IDLE;
        end
      end

      // Default case : should not occur
      default: state_d = IDLE;
    endcase  // state_q
  end
endmodule
