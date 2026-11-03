// Original Author: Maxime TRAVAILLARD (fixed-term.maxime.travaillard@fr.bosch.com)

// Top level of the coprocessor wrapper

// To use this wrapper, you need to know which instruction your coprocessor is supporting (which opcode custom and if it use the full opcode)
// You also need to know a bit about the signals used in the CV-X-IF interface, to at least connect the right signals togethers.
// I recommend you to first implement you coprocessor with the CVA6 before setting your parameters in the package.
// for more information to make the parameter, look inside the cvxif_wrapper_pkg

module cvxif_coprocessor_wrapper
  import cvxif_pkg::*;
#(
    parameter COPRO_NBR = cvxif_wrapper_pkg::COPRO_NBR,
    parameter COPRO_BITS_NBR = $clog2(COPRO_NBR),
    parameter SAME_COPRO_NBR = cvxif_wrapper_pkg::SAME_COPRO_NBR,
    parameter SCT_SIZE = (SAME_COPRO_NBR == 0) ? 0 : SAME_COPRO_NBR-1,
    parameter logic [COPRO_BITS_NBR:0] SAME_COPRO_TABLE[0:SCT_SIZE] = cvxif_wrapper_pkg::SAME_COPRO_TABLE,
    parameter int unsigned DECODING_TYPE = cvxif_wrapper_pkg::DECODING_TYPE,
    parameter int unsigned deco_LUT_size =   (DECODING_TYPE == 0) ? 2**2 : ((DECODING_TYPE == 1) ? 2**4 : ((DECODING_TYPE == 2) ? 2**5 : ((DECODING_TYPE == 3) ? 2**7 : 0))),
    parameter logic [COPRO_BITS_NBR:0] decoding_LUT [0:deco_LUT_size-1] = cvxif_wrapper_pkg::decoding_LUT,
    parameter logic [5:0] i_resp_LUT[COPRO_NBR-1:0] = cvxif_wrapper_pkg::i_resp_LUT
) (
    input  logic                        clk_i,             // Clock
    input  logic                        rst_ni,            // Asynchronous reset active low
    input  cvxif_req_t                  cvxif_req_i,
    output cvxif_req_t  [COPRO_NBR-1:0] cvxif_req_copro,
    input  cvxif_resp_t [COPRO_NBR-1:0] cvxif_resp_copro,
    output cvxif_resp_t                 cvxif_resp_o
);

  typedef struct packed {
    cvxif_pkg::x_issue_req_t   x_issue_req;
    logic [COPRO_BITS_NBR-1:0] coprocessor_index;
  } x_issue_indexed_t;

  // type source_signal;

  // decoder outputs
  x_issue_req_t decoder_issue_req;
  logic [COPRO_BITS_NBR-1:0] decoder_coprocessor_index;
  logic decoder_push;

  // sfifo outputs
  x_issue_req_t sfifo_issue_req;
  logic [COPRO_BITS_NBR-1:0] sfifo_coprocessor_index;
  logic sfifo_full;
  logic sfifo_empty;

  // commit filter outputs
  logic commit_filter_pop;  // used to pop from sfifo and to push into corresponding coprocessor

  // coprocessors inputs/outputs
  x_issue_req_t [COPRO_NBR-1:0] copros_issue_req;
  logic [COPRO_NBR-1:0] copros_issue_rdy;
  logic [COPRO_NBR-1:0] copros_issue_vld;
  x_result_t [COPRO_NBR-1:0] copros_result;
  logic [COPRO_NBR-1:0] copros_result_vld;
  logic [COPRO_NBR-1:0] copros_result_rdy;
  logic [COPRO_NBR-1:0] issue_rdy_cmp;

  // Decoder :
  wrapper_decoder #(
      .COPRO_NBR       (COPRO_NBR),
      .SAME_COPRO_NBR  (SAME_COPRO_NBR),
      .SCT_SIZE (SCT_SIZE),
      .SAME_COPRO_TABLE(SAME_COPRO_TABLE),
      .DECODING_TYPE   (DECODING_TYPE),
      .decoding_LUT    (decoding_LUT),
      .i_resp_LUT      (i_resp_LUT)
  ) decoder (
      .clk_i              (clk_i),
      .rst_ni             (rst_ni),
      .issue_req_i        (cvxif_req_i.x_issue_req),
      .issue_valid_i      (cvxif_req_i.x_issue_valid),
      .fifo_full_i        (sfifo_full),
      .issue_req_o        (decoder_issue_req),
      .issue_resp_o       (cvxif_resp_o.x_issue_resp),
      .coprocessor_index_o(decoder_coprocessor_index),
      .push_sfifo_o       (decoder_push)
  );

  // Speculative FIFO :
  fifo_v3 #(
      .FALL_THROUGH(1),  //data_o ready and pop in the same cycle
      .DATA_WIDTH(64),
      .DEPTH(cva6_config_pkg::CVA6ConfigNrScoreboardEntries),  // CVA6 scoreboard size
      .dtype(x_issue_indexed_t)  // correspond to concatenation of x_issue and copro_index
  ) sfifo (  // need to check parameter ( bit width )
      .clk_i(clk_i),
      .rst_ni(rst_ni),
      .flush_i(1'b0),
      .testmode_i(1'b0),
      .full_o(sfifo_full),  // used by decoder to not push when full
      .empty_o(sfifo_empty),  // used by commit filter to not pop when empty
      .usage_o(),
      .data_i({decoder_issue_req, decoder_coprocessor_index}),
      .push_i(decoder_push),
      .data_o({sfifo_issue_req, sfifo_coprocessor_index}),
      .pop_i(commit_filter_pop)
  );

  // Commit Filter :
  wrapper_commit_filter #(
      .COPRO_NBR(COPRO_NBR)
  ) commit_filter (
      .clk_i              (clk_i),
      .rst_ni             (rst_ni),
      .issue_req_i        (sfifo_issue_req),
      .coprocessor_index_i(sfifo_coprocessor_index),
      .commit_valid_i     (cvxif_req_i.x_commit_valid),
      .commit_i           (cvxif_req_i.x_commit),
      .fifo_empty_i       (sfifo_empty),
      .pop_o              (commit_filter_pop),
      .issue_req_o        (copros_issue_req),
      .issue_valid_o      (copros_issue_vld)
  );

  // Coprocessor : cvxif signals for coprocessors
  always_comb begin : gen_cvxif_req
    for (int i = 0; i < COPRO_NBR; i++) begin
      cvxif_req_copro[i].x_compressed_valid = '0;
      cvxif_req_copro[i].x_compressed_req = '0;
      cvxif_req_copro[i].x_mem_ready = '0;
      cvxif_req_copro[i].x_mem_resp = '0;
      cvxif_req_copro[i].x_mem_result_valid = '0;
      cvxif_req_copro[i].x_mem_result = '0;
      cvxif_req_copro[i].x_result_ready = copros_result_rdy[i];
      cvxif_req_copro[i].x_issue_req = copros_issue_req[i];
      cvxif_req_copro[i].x_issue_valid = copros_issue_vld[i];
      cvxif_req_copro[i].x_commit_valid = copros_issue_vld[i];
      cvxif_req_copro[i].x_commit.id = (copros_issue_vld[i]) ? copros_issue_req[i].id : 0;
      cvxif_req_copro[i].x_commit.x_commit_kill = '0;

      copros_issue_rdy[i] = cvxif_resp_copro[i].x_issue_ready;

      copros_result[i] = cvxif_resp_copro[i].x_result;
      copros_result_vld[i] = cvxif_resp_copro[i].x_result_valid;
    end
  end


  // round robin arbiter, comming from PULP platform
  rr_arb_tree #(
      .NumIn    (COPRO_NBR),
      .DataType (x_result_t),
      .AxiVldRdy(1'b1)
  ) arbiter (
      .clk_i(clk_i),
      .rst_ni(rst_ni),
      .flush_i(1'b0),
      .rr_i(2'b00),
      .req_i(copros_result_vld),  // result valid from coprocessors
      .gnt_o(copros_result_rdy),  // result ready for coprocressors
      .data_i(copros_result),  // result from coprocessors
      .req_o(cvxif_resp_o.x_result_valid),  // result valid for CV-X-IF
      .gnt_i(cvxif_req_i.x_result_ready),  // result ready from CV-X-IF
      .data_o(cvxif_resp_o.x_result),  // x_result for CV-X-IF
      .idx_o() // could be useful if commit handling is changed by using a scoreboard instead of sfifo + filter after decoder, it give the index of the input that is sending it result
  );

  assign issue_rdy_cmp = '1;

  // not supported in CVA6 :
  assign cvxif_resp_o.x_mem_valid = '0;
  assign cvxif_resp_o.x_mem_req = '0;
  assign cvxif_resp_o.x_compressed_ready = '0;
  assign cvxif_resp_o.x_compressed_resp = '0;
  assign cvxif_resp_o.x_issue_ready = ~sfifo_full & (copros_issue_rdy == issue_rdy_cmp);
  // cvxif_resp result handled by the arbiter
  // cvxif_resp issue handled by the decoder

endmodule : cvxif_coprocessor_wrapper
