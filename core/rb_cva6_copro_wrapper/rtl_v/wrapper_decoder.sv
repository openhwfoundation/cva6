// Original Author: Maxime TRAVAILLARD (fixed-term.maxime.travaillard@fr.bosch.com)

// Decoder to handle issue response and give coprocessor index for each instruction
// If the instruction is not for 

module wrapper_decoder
  import cvxif_pkg::*;
#(
    parameter COPRO_NBR = cvxif_wrapper_pkg::COPRO_NBR,
    parameter COPRO_BITS_NBR = $clog2(COPRO_NBR),
    parameter SAME_COPRO_NBR = cvxif_wrapper_pkg::SAME_COPRO_NBR,
    parameter SCT_SIZE = (SAME_COPRO_NBR == 0) ? 0 : SAME_COPRO_NBR-1,
    parameter logic [COPRO_BITS_NBR:0] SAME_COPRO_TABLE[0:SCT_SIZE] = cvxif_wrapper_pkg::SAME_COPRO_TABLE,
    parameter int unsigned DECODING_TYPE = cvxif_wrapper_pkg::DECODING_TYPE,
    parameter int unsigned deco_LUT_size =   (DECODING_TYPE == 0) ? 2**2 : ((DECODING_TYPE == 1) ? 2**4 : ((DECODING_TYPE == 2) ? 2**5 : ((DECODING_TYPE == 3) ? 2**7 : 2**2))),
    parameter logic [COPRO_BITS_NBR:0] decoding_LUT [0:deco_LUT_size-1] = cvxif_wrapper_pkg::decoding_LUT,
    parameter logic [5:0] i_resp_LUT[COPRO_NBR-1:0] = cvxif_wrapper_pkg::i_resp_LUT
) (
    input logic clk_i,  // Clock
    input logic rst_ni,  // Asynchronous reset active low
    input x_issue_req_t issue_req_i,
    input logic issue_valid_i,
    input logic fifo_full_i,
    output x_issue_req_t issue_req_o,
    output x_issue_resp_t issue_resp_o,
    output logic [COPRO_BITS_NBR-1:0] coprocessor_index_o,
    output logic push_sfifo_o
);

  logic [COPRO_BITS_NBR:0] decoding_LUT_q[0:deco_LUT_size-1];
  int same_copro_current_index;
  logic to_do_instr;  // this signal handle when a given instr is not supported by any coprocessor

  always_comb begin
    // getting the index of the corresponding coprocessor
    if (issue_valid_i & ~fifo_full_i) begin
      //checking if it is a supported instruction (veryfing if it is a custom opcode and in the LUT as the LUT do not cover cover the full opcode size to make it easier to fill)
      case (DECODING_TYPE)
        1: begin
          to_do_instr = ((COPRO_NBR-1 >= decoding_LUT_q[{issue_req_i.instr[6:5],issue_req_i.instr[26:25]}]) && ((issue_req_i.instr[6:0] == riscv::OpcodeCustom0) || (issue_req_i.instr[6:0] == riscv::OpcodeCustom1) || (issue_req_i.instr[6:0] == riscv::OpcodeCustom2) || (issue_req_i.instr[6:0] == riscv::OpcodeCustom3)));
          coprocessor_index_o = to_do_instr ? decoding_LUT_q[{issue_req_i.instr[6:5],issue_req_i.instr[26:25]}] : 0; // sending the copro index
        end

        2: begin
          to_do_instr = ((COPRO_NBR-1 >= decoding_LUT_q[{issue_req_i.instr[6:5],issue_req_i.instr[14:12]}]) && ((issue_req_i.instr[6:0] == riscv::OpcodeCustom0) || (issue_req_i.instr[6:0] == riscv::OpcodeCustom1) || (issue_req_i.instr[6:0] == riscv::OpcodeCustom2) || (issue_req_i.instr[6:0] == riscv::OpcodeCustom3)));
          coprocessor_index_o = to_do_instr ? decoding_LUT_q[{issue_req_i.instr[6:5],issue_req_i.instr[14:12]}] : 0; // sending the copro index
        end

        3: begin
          to_do_instr = ((COPRO_NBR-1 >= decoding_LUT_q[{issue_req_i.instr[6:5],issue_req_i.instr[26:25]}]) && ((issue_req_i.instr[6:0] == riscv::OpcodeCustom0) || (issue_req_i.instr[6:0] == riscv::OpcodeCustom1) || (issue_req_i.instr[6:0] == riscv::OpcodeCustom2) || (issue_req_i.instr[6:0] == riscv::OpcodeCustom3)));
          coprocessor_index_o = to_do_instr ? decoding_LUT_q[{issue_req_i.instr[6:5],issue_req_i.instr[14:12],issue_req_i.instr[26:25]}] : 0; // sending the copro index
        end

        default: begin
          to_do_instr = ((COPRO_NBR-1 >= decoding_LUT_q[issue_req_i.instr[6:5]]) && ((issue_req_i.instr[6:0] == riscv::OpcodeCustom0) || (issue_req_i.instr[6:0] == riscv::OpcodeCustom1) || (issue_req_i.instr[6:0] == riscv::OpcodeCustom2) || (issue_req_i.instr[6:0] == riscv::OpcodeCustom3)));
          coprocessor_index_o = to_do_instr ? decoding_LUT_q[issue_req_i.instr[6:5]] : 0; // sending the copro index
        end
      endcase

    end else begin
      to_do_instr = 0;
      coprocessor_index_o = '0;
    end
  end


  assign  issue_req_o  = to_do_instr ? issue_req_i : '0;  //sending the incomming issue to the sfifo
  assign  issue_resp_o = to_do_instr ? i_resp_LUT[coprocessor_index_o] : '0; // sending the issue response to the core, for now, we consider that a coprocessor have the same response for each instruction, if not, you can make the same than the other LUT.
  assign  push_sfifo_o = to_do_instr;  // used to push the req + copro_index in the sfifo

  // initializing the LUT
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      decoding_LUT_q = decoding_LUT;
      same_copro_current_index = 0;
    end
    // checking if the coprocessor index is corresponding to a same coprocessor
    if ((SAME_COPRO_NBR >= 2) && (coprocessor_index_o == SAME_COPRO_TABLE[same_copro_current_index]) && to_do_instr) begin
      // incrementing the counter and going back to zero when at the end
      if (same_copro_current_index == (SAME_COPRO_NBR - 1)) begin
        same_copro_current_index = 0;
      end else begin
        same_copro_current_index++;
      end
      // updating the LUT with the corresponding index
      for (int i = 0; i < deco_LUT_size; i++) begin
        decoding_LUT_q[i]  = (decoding_LUT[i] == SAME_COPRO_TABLE[0]) ? SAME_COPRO_TABLE[same_copro_current_index] : decoding_LUT[i];
      end
    end
  end

endmodule
