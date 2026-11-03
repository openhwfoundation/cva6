module cvxif_exp_coprocessor
  import cvxif_pkg::*;
  import cvxif_exp_instr_pkg::*;
  import cvxif_exp_coprocessor_pkg::*;
(
    input  logic        clk_i,        // Clock
    input  logic        rst_ni,       // Asynchronous reset active low
    input  cvxif_req_t  cvxif_req_i,
    output cvxif_resp_t cvxif_resp_o
);

  // Compressed interface
  logic               x_compressed_valid_i;
  logic               x_compressed_ready_o;
  x_compressed_req_t  x_compressed_req_i;
  x_compressed_resp_t x_compressed_resp_o;
  // Issue interface
  logic               x_issue_valid_i;
  logic               x_issue_ready_o;
  x_issue_req_t       x_issue_req_i;
  x_issue_resp_t      x_issue_resp_o;
  // Commit interface
  logic               x_commit_valid_i;
  x_commit_t          x_commit_i;
  // Memory interface
  logic               x_mem_valid_o;
  logic               x_mem_ready_i;
  x_mem_req_t         x_mem_req_o;
  x_mem_resp_t        x_mem_resp_i;
  // Memory result interface
  logic               x_mem_result_valid_i;
  x_mem_result_t      x_mem_result_i;
  // Result interface
  logic               x_result_valid_o;
  logic               x_result_ready_i;
  x_result_t          x_result_o;


  // Speculative FIFO
  logic               sfifo_full;
  logic               sfifo_empty;
  x_issue_req_t       sfifo_issue_req;

  // Commit filter
  logic               cf_pop;
  logic               cf_push;
  x_issue_req_t       cf_issue_req;

  // Executive FIFO
  logic               efifo_full;
  logic               efifo_empty;
  x_issue_req_t       efifo_issue_req;

  // FSM
  logic [3:0] add_counter_q, m_counter_q;
  logic                   mc_enable;  // Mult counter
  logic                   M_mux;
  logic [            1:0] Add_mux;
  logic                   ac_enable;  // Add counter
  logic                   we_reg;
  logic                   pop_efifo;

  // Datapath
  logic [            6:0] x_int;
  logic [riscv::XLEN-1:0] x_fract;
  logic [riscv::XLEN-1:0] mult_result;
  logic [riscv::XLEN-1:0] x_result_data_d, x_result_data_q;  //reg

  assign x_compressed_valid_i = cvxif_req_i.x_compressed_valid;
  assign x_compressed_req_i = cvxif_req_i.x_compressed_req;
  assign x_issue_valid_i = cvxif_req_i.x_issue_valid;
  assign x_issue_req_i = cvxif_req_i.x_issue_req;
  assign x_commit_valid_i = cvxif_req_i.x_commit_valid;
  assign x_commit_i = cvxif_req_i.x_commit;
  assign x_mem_ready_i = cvxif_req_i.x_mem_ready;
  assign x_mem_resp_i = cvxif_req_i.x_mem_resp;
  assign x_mem_result_valid_i = cvxif_req_i.x_mem_result_valid;
  assign x_mem_result_i = cvxif_req_i.x_mem_result;
  assign x_result_ready_i = cvxif_req_i.x_result_ready;

  assign cvxif_resp_o.x_compressed_ready = x_compressed_ready_o;
  assign cvxif_resp_o.x_compressed_resp = x_compressed_resp_o;
  assign cvxif_resp_o.x_issue_ready = x_issue_ready_o;
  assign cvxif_resp_o.x_issue_resp = x_issue_resp_o;
  assign cvxif_resp_o.x_mem_valid = x_mem_valid_o;
  assign cvxif_resp_o.x_mem_req = x_mem_req_o;
  assign cvxif_resp_o.x_result_valid = x_result_valid_o;
  assign cvxif_resp_o.x_result = x_result_o;

  // Compressed interface - not used 
  assign x_compressed_ready_o = '0;
  assign x_compressed_resp_o.instr = '0;
  assign x_compressed_resp_o.accept = '0;

  // Memory interface  - not used
  assign x_mem_valid_o = 0;
  assign x_mem_req_o = '0;

  assign x_int = efifo_issue_req.rs[0][riscv::XLEN-1:riscv::XLEN-7];  // x_int in [31:0] with 2 bits for float
  assign x_fract = {3'b0, efifo_issue_req.rs[0][riscv::XLEN-8:0], 4'b0};  // x_fract in [0:1[

  assign x_issue_ready_o = ~efifo_full & ~sfifo_full;

  exp_instr_decoder #(
      .NbInstr   (cvxif_exp_instr_pkg::NbInstr),
      .CoproInstr(cvxif_exp_instr_pkg::CoproInstr)
  ) instr_decoder_i (
      .clk_i         (clk_i),
      .x_issue_req_i ((x_issue_valid_i & x_issue_ready_o) ? x_issue_req_i : '0),
      .x_issue_resp_o(x_issue_resp_o)
  );

  // Speculative FIFO :
  fifo_v3 #(
      .FALL_THROUGH(1),  //data_o ready and pop in the same cycle
      .DEPTH(cva6_config_pkg::CVA6ConfigNrScoreboardEntries),  // CVA6 scoreboard size
      .dtype(x_issue_req_t)
  ) sFIFO (  // need to check parameter ( bit width )
      .clk_i     (clk_i),
      .rst_ni    (rst_ni),
      .flush_i   (1'b0),
      .testmode_i(1'b0),
      .full_o    (sfifo_full),             // used by decoder to not push when full
      .empty_o   (sfifo_empty),            // used by commit filter to not pop when empty
      .usage_o   (),
      .data_i    (x_issue_req_i),
      .push_i    (x_issue_resp_o.accept),
      .data_o    (sfifo_issue_req),
      .pop_i     (cf_pop)
  );

  // Commit Filter :
  commit_filter exp_commit_filter (
      .clk_i         (clk_i),
      .rst_ni        (rst_ni),
      .issue_req_i   (sfifo_issue_req),
      .commit_valid_i(x_commit_valid_i),
      .commit_i      (x_commit_i),
      .sfifo_empty_i (sfifo_empty),
      .efifo_full_i  (efifo_full),
      .pop_o         (cf_pop),
      .issue_req_o   (cf_issue_req),
      .push_o        (cf_push)
  );

  // Executive FIFO :
  fifo_v3 #(
      .FALL_THROUGH(1),  //data_o ready and pop in the same cycle
      .DEPTH(cva6_config_pkg::CVA6ConfigNrScoreboardEntries),  // CVA6 scoreboard size
      .dtype(x_issue_req_t)
  ) eFIFO (  // need to check parameter ( bit width )
      .clk_i     (clk_i),
      .rst_ni    (rst_ni),
      .flush_i   (1'b0),
      .testmode_i(1'b0),
      .full_o    (efifo_full),       // used by decoder to not push when full
      .empty_o   (efifo_empty),      // used by commit filter to not pop when empty
      .usage_o   (),
      .data_i    (cf_issue_req),
      .push_i    (cf_push),
      .data_o    (efifo_issue_req),
      .pop_i     (pop_efifo)
  );


  // Control path :
  cvxif_exp_coprocessor_ctrl exp_ctrl (
      .clk_i         (clk_i),
      .rst_ni        (rst_ni),
      .x_int         (x_int),
      .efifo_empty   (efifo_empty),
      .x_result_ready(x_result_ready_i),
      .add_counter   (add_counter_q),
      .m_counter     (m_counter_q),
      .x_result_valid(x_result_valid_o),
      .M_mux         (M_mux),
      .mc_enable     (mc_enable),
      .Add_mux       (Add_mux),
      .ac_enable     (ac_enable),
      .we_reg        (we_reg),
      .pop_efifo     (pop_efifo)
  );

  // Counter for Mult :
  always_ff @(posedge clk_i or negedge rst_ni) begin : m_counter_gen
    if (!rst_ni) m_counter_q <= '0;
    else m_counter_q <= (mc_enable) ? m_counter_q + 1 : 0;
  end

  // Counter for Add :
  always_ff @(posedge clk_i or negedge rst_ni) begin : add_counter_gen
    if (!rst_ni) add_counter_q <= '0;
    else add_counter_q <= (ac_enable) ? add_counter_q + 1 : 0;
  end

  // Data Path :
  // Multiplier :
  exp_multiplier exp_mult (
      .data_a(M_mux ? (x_int[m_counter_q] ? ExpIntLut[m_counter_q] : 1) : x_fract),
      .data_b(x_result_data_q),
      .M_mux (M_mux),
      .data_o(mult_result)
  );


  // Adder : 
  exp_adder adder (
      .exp_poly_i(ExpPolyLUT[add_counter_q]),
      .exp_mult_i(mult_result),
      .add_mux_i (Add_mux),
      .add_o     (x_result_data_d)
  );

  always_ff @(posedge clk_i or negedge rst_ni) begin : data_path_reg
    if (!rst_ni) x_result_data_q <= '0;
    else x_result_data_q <= (we_reg) ? x_result_data_d : x_result_data_q;
  end

  always_comb begin
    x_result_o.data    = ~efifo_empty ? x_result_data_q : 0;
    x_result_o.id      = ~efifo_empty ? efifo_issue_req.id : 0;
    x_result_o.rd      = ~efifo_empty ? efifo_issue_req.instr[11:7] : 0;
    x_result_o.we      = ~efifo_empty ? x_result_valid_o : 0;
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
    assert (riscv::XLEN == 32)
    else $fatal(1, "Expneg coprocessor needs XLEN = 32 ");

  end

`endif
  //pragma translate_on

endmodule
