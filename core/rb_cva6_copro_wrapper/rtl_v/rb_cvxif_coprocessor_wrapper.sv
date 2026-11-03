// Original Author: Maxime TRAVAILLARD (fixed-term.maxime.travaillard@fr.bosch.com)

// Top level of the coprocessor wrapper

module rb_cvxif_coprocessor_wrapper
  import cvxif_pkg::*;
(
    input logic clk_i,  // Clock
    input logic rst_ni, // Asynchronous reset active low

    // CVXIF_REQ signals
    // compressed
    input logic                                    x_compressed_valid_i,
    input logic [           15:0]                  x_compressed_instr_i,
    input logic [            1:0]                  x_compressed_mode_i,
    input logic [ X_ID_WIDTH-1:0]                  x_compressed_id_i,
    // issue
    input logic                                    x_issue_valid_i,
    input logic [           31:0]                  x_issue_instr_i,
    input logic [            1:0]                  x_issue_mode_i,
    input logic [ X_ID_WIDTH-1:0]                  x_issue_id_i,
    input logic [   X_NUM_RS-1:0][X_RFR_WIDTH-1:0] x_issue_rs_i,
    input logic [   X_NUM_RS-1:0]                  x_issue_rs_valid_i,
    // commit
    input logic                                    x_commit_valid_i,
    input logic [ X_ID_WIDTH-1:0]                  x_commit_id_i,
    input logic                                    x_commit_kill_i,
    // memory
    input logic                                    x_mem_ready_i,
    input logic                                    x_mem_exc_i,
    input logic [            5:0]                  x_mem_exccode_i,
    input logic                                    x_mem_result_valid_i,
    input logic [ X_ID_WIDTH-1:0]                  x_mem_id_i,
    input logic [X_MEM_WIDTH-1:0]                  x_mem_rdata_i,
    input logic                                    x_mem_err_i,
    //result
    input logic                                    x_result_ready,


    // CVXIF_RESP signals
    // compressed
    output logic                   x_compressed_ready_o,
    output logic [           31:0] x_compressed_instr_o,
    output logic                   x_compressed_accept_o,
    // issue
    output logic                   x_issue_ready_o,
    output logic                   x_issue_accept_o,
    output logic                   x_issue_writeback_o,
    output logic                   x_issue_dualwrite_o,
    output logic                   x_issue_dualread_o,
    output logic                   x_issue_loadstore_o,
    output logic                   x_issue_exc_o,
    // memory
    output logic                   x_mem_valid_o,
    output logic [ X_ID_WIDTH-1:0] x_mem_id_o,
    output logic [           31:0] x_mem_addr_o,
    output logic [            1:0] x_mem_mode_o,
    output logic                   x_mem_we_o,
    output logic [            1:0] x_mem_size_o,
    output logic [X_MEM_WIDTH-1:0] x_mem_wdata_o,
    output logic                   x_mem_last_o,
    output logic                   x_mem_spec_o,
    // result 
    output logic                   x_result_valid_o,
    output logic [ X_ID_WIDTH-1:0] x_result_id_o,
    output logic [X_RFW_WIDTH-1:0] x_result_data_o,
    output logic [            4:0] x_result_rd_o,
    output logic                   x_result_we_o,
    output logic                   x_result_exc_o,
    output logic [            5:0] x_result_exccode_o
);

  cvxif_pkg::cvxif_req_t cvxif_req_i;
  cvxif_pkg::cvxif_resp_t cvxif_resp_o;
  cvxif_pkg::cvxif_req_t [cvxif_wrapper_pkg::COPRO_NBR-1:0] cvxif_req_copro;

  // ---------------------
  // CVXIF_REQ assignment
  // ---------------------
  // compressed
  assign cvxif_req_i.x_compressed_valid = x_compressed_valid_i;
  assign cvxif_req_i.x_compressed_req.instr = x_compressed_instr_i;
  assign cvxif_req_i.x_compressed_req.mode = x_compressed_mode_i;
  assign cvxif_req_i.x_compressed_req.id = x_compressed_id_i;
  // issue
  assign cvxif_req_i.x_issue_valid = x_issue_valid_i;
  assign cvxif_req_i.x_issue_req.instr = x_issue_instr_i;
  assign cvxif_req_i.x_issue_req.mode = x_issue_mode_i;
  assign cvxif_req_i.x_issue_req.id = x_issue_id_i;
  assign cvxif_req_i.x_issue_req.rs = x_issue_rs_i;
  assign cvxif_req_i.x_issue_req.rs_valid = x_issue_rs_valid_i;
  // commit
  assign cvxif_req_i.x_commit_valid = x_commit_valid_i;
  assign cvxif_req_i.x_commit.id = x_commit_id_i;
  assign cvxif_req_i.x_commit.x_commit_kill = x_commit_kill_i;
  // memory
  assign cvxif_req_i.x_mem_ready = x_mem_ready_i;
  assign cvxif_req_i.x_mem_resp.exc = x_mem_exc_i;
  assign cvxif_req_i.x_mem_resp.exccode = x_mem_exccode_i;
  assign cvxif_req_i.x_mem_result_valid = x_mem_result_valid_i;
  assign cvxif_req_i.x_mem_result.id = x_mem_id_i;
  assign cvxif_req_i.x_mem_result.rdata = x_mem_rdata_i;
  assign cvxif_req_i.x_mem_result.err = x_mem_err_i;
  // result
  assign cvxif_req_i.x_result_ready = x_result_ready;

  // ---------------------
  // CVXIF_RESP assignment
  // ---------------------
  // compressed
  assign x_compressed_ready_o = cvxif_resp_o.x_compressed_ready;
  assign x_compressed_instr_o = cvxif_resp_o.x_compressed_resp.instr;  // useful for filter ?
  assign x_compressed_accept_o = cvxif_resp_o.x_compressed_resp.accept;
  // issue
  assign x_issue_ready_o = cvxif_resp_o.x_issue_ready;
  assign x_issue_accept_o = cvxif_resp_o.x_issue_resp.accept;
  assign x_issue_writeback_o = cvxif_resp_o.x_issue_resp.writeback;
  assign x_issue_dualwrite_o = cvxif_resp_o.x_issue_resp.dualwrite;
  assign x_issue_dualread_o = cvxif_resp_o.x_issue_resp.dualread;
  assign x_issue_loadstore_o = cvxif_resp_o.x_issue_resp.loadstore;
  assign x_issue_exc_o = cvxif_resp_o.x_issue_resp.exc;
  // memory
  assign x_mem_valid_o = cvxif_resp_o.x_mem_valid;
  assign x_mem_id_o = cvxif_resp_o.x_mem_req.id;
  assign x_mem_addr_o = cvxif_resp_o.x_mem_req.addr;
  assign x_mem_mode_o = cvxif_resp_o.x_mem_req.mode;
  assign x_mem_we_o = cvxif_resp_o.x_mem_req.we;
  assign x_mem_size_o = cvxif_resp_o.x_mem_req.size;
  assign x_mem_wdata_o = cvxif_resp_o.x_mem_req.wdata;
  assign x_mem_last_o = cvxif_resp_o.x_mem_req.last;
  assign x_mem_spec_o = cvxif_resp_o.x_mem_req.spec;
  // result
  assign x_result_valid_o = cvxif_resp_o.x_result_valid;
  assign x_result_id_o = cvxif_resp_o.x_result.id;
  assign x_result_data_o = cvxif_resp_o.x_result.data;
  assign x_result_rd_o = cvxif_resp_o.x_result.rd;
  assign x_result_we_o = cvxif_resp_o.x_result.we;
  assign x_result_exc_o = cvxif_resp_o.x_result.exc;
  assign x_result_exccode_o = cvxif_resp_o.x_result.exccode;

  /*
    // Signals not supported by this implementation
    assign cvxif_resp_o.x_compressed_ready = '0;
    assign cvxif_resp_o.x_compressed_resp.instr = '0;
    assign cvxif_resp_o.x_compressed_resp.accept = '0;
    assign cvxif_resp_o.x_mem_valid = '0;
    assign cvxif_resp_o.x_mem_req.id = '0;
    assign cvxif_resp_o.x_mem_req.addr = '0;
    assign cvxif_resp_o.x_mem_req.mode = '0;
    assign cvxif_resp_o.x_mem_req.we = '0;
    assign cvxif_resp_o.x_mem_req.size = '0;
    assign cvxif_resp_o.x_mem_req.wdata = '0;
    assign cvxif_resp_o.x_mem_req.last = '0;
    assign cvxif_resp_o.x_mem_req.spec = '0;*/

  cvxif_coprocessor_wrapper #(
      .COPRO_NBR     (cvxif_wrapper_pkg::COPRO_NBR),
      .SAME_COPRO_NBR(cvxif_wrapper_pkg::SAME_COPRO_NBR),
      .decoding_LUT  (cvxif_wrapper_pkg::decoding_LUT),
      .i_resp_LUT    (cvxif_wrapper_pkg::i_resp_LUT)
  ) copro_wrapper (
      .clk_i           (clk_i),
      .rst_ni          (rst_ni),
      .cvxif_req_i     (cvxif_req_i),
      .cvxif_req_copro (cvxif_req_copro),
      .cvxif_resp_copro('0),
      .cvxif_resp_o    (cvxif_resp_o)
  );

endmodule : rb_cvxif_coprocessor_wrapper
