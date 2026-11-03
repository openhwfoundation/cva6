
module cvxif_crc_coprocessor
  import cvxif_pkg::*;
  import cvxif_crc_instr_pkg::*;
  import cvxif_crc_coprocessor_pkg::*;
(
    input  logic        clk_i,        // Clock
    input  logic        rst_ni,       // Asynchronous reset active low
    input  cvxif_req_t  cvxif_req_i,
    output cvxif_resp_t cvxif_resp_o
);

  //Compressed interface
  logic               x_compressed_valid_i;
  logic               x_compressed_ready_o;
  x_compressed_req_t  x_compressed_req_i;
  x_compressed_resp_t x_compressed_resp_o;
  //Issue interface
  logic               x_issue_valid_i;
  logic               x_issue_ready_o;
  x_issue_req_t       x_issue_req_i;
  x_issue_resp_t      x_issue_resp_o;
  //Commit interface
  logic               x_commit_valid_i;
  x_commit_t          x_commit_i;
  //Memory interface
  logic               x_mem_valid_o;
  logic               x_mem_ready_i;
  x_mem_req_t         x_mem_req_o;
  x_mem_resp_t        x_mem_resp_i;
  //Memory result interface
  logic               x_mem_result_valid_i;
  x_mem_result_t      x_mem_result_i;
  //Result interface
  logic               x_result_valid_o;
  logic               x_result_ready_i;
  x_result_t          x_result_o;

  assign x_compressed_valid_i            = cvxif_req_i.x_compressed_valid;
  assign x_compressed_req_i              = cvxif_req_i.x_compressed_req;
  assign x_issue_valid_i                 = cvxif_req_i.x_issue_valid;
  assign x_issue_req_i                   = cvxif_req_i.x_issue_req;
  assign x_commit_valid_i                = cvxif_req_i.x_commit_valid;
  assign x_commit_i                      = cvxif_req_i.x_commit;
  assign x_mem_ready_i                   = cvxif_req_i.x_mem_ready;
  assign x_mem_resp_i                    = cvxif_req_i.x_mem_resp;
  assign x_mem_result_valid_i            = cvxif_req_i.x_mem_result_valid;
  assign x_mem_result_i                  = cvxif_req_i.x_mem_result;
  assign x_result_ready_i                = cvxif_req_i.x_result_ready;

  assign cvxif_resp_o.x_compressed_ready = x_compressed_ready_o;
  assign cvxif_resp_o.x_compressed_resp  = x_compressed_resp_o;
  assign cvxif_resp_o.x_issue_ready      = x_issue_ready_o;
  assign cvxif_resp_o.x_issue_resp       = x_issue_resp_o;
  assign cvxif_resp_o.x_mem_valid        = x_mem_valid_o;
  assign cvxif_resp_o.x_mem_req          = x_mem_req_o;
  assign cvxif_resp_o.x_result_valid     = x_result_valid_o;
  assign cvxif_resp_o.x_result           = x_result_o;

  //Compressed interface - not used
  assign x_compressed_ready_o            = '0;
  assign x_compressed_resp_o.instr       = '0;
  assign x_compressed_resp_o.accept      = '0;

  crc_instr_decoder #(
      .NbInstr   (cvxif_crc_instr_pkg::NbInstr),
      .CoproInstr(cvxif_crc_instr_pkg::CoproInstr)
  ) instr_decoder_i (
      .clk_i         (clk_i),
      .x_issue_req_i ((x_issue_valid_i) ? x_issue_req_i : '0),
      .x_issue_resp_o(x_issue_resp_o)
  );

  typedef struct packed {
    x_issue_req_t  req;
    x_issue_resp_t resp;
  } x_issue_t;

  logic fifo_full, fifo_empty;
  logic x_issue_ready_q;
  logic instr_push, instr_pop;
  x_issue_t req_i;
  x_issue_t req_o;



  assign instr_push = x_issue_resp_o.accept ? 1 : 0;
  assign instr_pop = ~fifo_empty && ((x_commit_i.x_commit_kill && x_commit_valid_i) ||
                                     (x_result_valid_o && x_result_ready_i));

  // if something is in the fifo, the instruction is being processed
  // so we can't receive anything else
  assign x_issue_ready_q = ~fifo_full;
  assign req_i.req = x_issue_req_i;
  assign req_i.resp = x_issue_resp_o;

  always_ff @(posedge clk_i or negedge rst_ni) begin : regs
    if (!rst_ni) begin
      x_issue_ready_o <= 1;
    end else begin
      x_issue_ready_o <= x_issue_ready_q;
    end
  end


  fifo_v3 #(
      .FALL_THROUGH(1),         //data_o ready and pop in the same cycle
      .DATA_WIDTH  (64),
      .DEPTH       (8),
      .dtype       (x_issue_t)
  ) fifo_commit_i (
      .clk_i     (clk_i),
      .rst_ni    (rst_ni),
      .flush_i   (1'b0),
      .testmode_i(1'b0),
      .full_o    (fifo_full),
      .empty_o   (fifo_empty),
      .usage_o   (),
      .data_i    (req_i),
      .push_i    (instr_push),
      .data_o    (req_o),
      .pop_i     (instr_pop)
  );

  // instruction parameters decoding
  crc_size_e crc_size;
  crc_mask_e crc_mask;
  logic crc_in_sel, data_in_sel;
  logic [3:0] xor_en;
  logic [31:0] crc_poly;
  logic [31:0] crc_in;
  logic [31:0] data_in;
  logic [31:0] data_in_swapped;
  logic [31:0] crc_out;


  riscv::instruction_t instr;
  assign instr = riscv::instruction_t'(req_o.req.instr);
  assign crc_size = crc_size_e'(instr.r4type.funct2);
  assign crc_mask = crc_mask_e'(instr.r4type.funct3);
  assign crc_poly = req_o.req.rs[2];  // RS3 = polynomial
  assign data_in = req_o.req.rs[1];  // RS2 = incoming message data
  assign crc_in = req_o.req.rs[0];  // RS1 = current CRC


  // input data endianness swap
  always_comb begin
    if (CRC_ENDIAN_SWAP) begin
      case (crc_size)
        CRC8: data_in_swapped = {data_in[7:0], data_in[15:8], data_in[23:16], data_in[31:24]};
        CRC16: data_in_swapped = {data_in[15:0], data_in[31:16]};
        CRC32: data_in_swapped = data_in;
        default: data_in_swapped = data_in;
      endcase
    end else data_in_swapped = data_in;
  end

  // control FSM
  cvxif_crc_coprocessor_ctrl cvxif_crc_coprocessor_ctrl_i (
      .clk_i        (clk_i),
      .rst_ni       (rst_ni),
      .req_valid_i  (~fifo_empty),
      .crc_size_i   (crc_size),
      .crc_mask_i   (crc_mask),
      .res_valid_o  (x_result_valid_o),
      .res_ready_i  (x_result_ready_i),
      .crc_in_sel_o (crc_in_sel),
      .data_in_sel_o(data_in_sel),
      .xor_en_o     (xor_en)

  );


  // Datapath

  // change to do CRC8 in 2 cycles, 1 pipeline stage in the middle

  cvxif_crc_coprocessor_dp cvxif_crc_coprocessor_dp_i (
      .clk_i(clk_i),  // Clock
      .rst_ni(rst_ni),  // Asynchronous reset active low
      .crc_size_i(crc_size),  // size configuration , must be kept stable during instruction
      .crc_poly_i(crc_poly),  // CRC polynomial
      .data_i(data_in_swapped),  // incoming msg data , stable during the instruciton execution
      .data_sel_i(data_in_sel),
      .xor_en_i(xor_en),
      .crc_i(crc_in),
      .crc_sel_i(crc_in_sel),
      .res_valid_i(x_result_valid_o),
      .crc_o(crc_out)

  );

  //result selection according to size and mask
  always_comb begin
    case (crc_size)
      CRC8:
      case (crc_mask)
        MASK0:   x_result_o.data = {24'b0, crc_out[7:0]};
        MASK1:   x_result_o.data = {24'b0, crc_out[15:8]};
        MASK2:   x_result_o.data = {24'b0, crc_out[7:0]};
        MASK3:   x_result_o.data = {24'b0, crc_out[15:8]};
        default: x_result_o.data = {24'b0, crc_out[7:0]};
      endcase

      CRC16: x_result_o.data = {16'b0, crc_out[15:00]};

      CRC32:   x_result_o.data = crc_out;
      default: x_result_o.data = crc_out;
    endcase
  end

  always_comb begin
    x_result_o.id      = req_o.req.id;
    x_result_o.rd      = req_o.req.instr[11:7];
    x_result_o.we      = req_o.resp.writeback & x_result_valid_o;
    x_result_o.exc     = 0;
    x_result_o.exccode = 0;
  end



  ///////////////////////////////////////////////////////
  // assertions
  ///////////////////////////////////////////////////////

  //pragma translate_off
`ifndef VERILATOR

  initial begin
    // assert wrong parameterizations
    assert (X_NUM_RS == 3)
    else $fatal(1, "CRC coprocessor needs X_NUM_RS ==3 ");

  end

`endif
  //pragma translate_on

endmodule
