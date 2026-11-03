module cvxif_crc_coprocessor_dp
  import cvxif_pkg::*;
  import cvxif_crc_instr_pkg::*;
  import cvxif_crc_coprocessor_pkg::*;
(
    input logic clk_i,  // Clock
    input logic rst_ni, // Asynchronous reset active low

    input cvxif_crc_coprocessor_pkg::crc_size_e crc_size_i,  // CRC size configuration
    input logic [cvxif_crc_coprocessor_pkg::MAX_CRC_SIZE-1:0] crc_poly_i,  // crc polynomial
    input logic [cvxif_crc_coprocessor_pkg::MAX_CRC_SIZE-1:0] data_i,  // incoming data
    input logic [3:0] xor_en_i,
    input logic [cvxif_crc_coprocessor_pkg::MAX_CRC_SIZE-1:0] crc_i,
    input logic crc_sel_i,
    input logic data_sel_i,
    input logic res_valid_i,
    output logic [cvxif_crc_coprocessor_pkg::MAX_CRC_SIZE-1:0] crc_o
);


  logic [cvxif_crc_coprocessor_pkg::MAX_CRC_SIZE-1:0] crc_out0, crc_out1;
  logic [cvxif_crc_coprocessor_pkg::MAX_CRC_SIZE-1:0] data_in_mux0, data_in_mux1;
  logic [cvxif_crc_coprocessor_pkg::MAX_CRC_SIZE-1:0] crc_in_mux;
  logic [cvxif_crc_coprocessor_pkg::MAX_CRC_SIZE-1:0] crc_d, crc_q;

  // data in selection
  assign data_in_mux0 = data_sel_i ? {16'b0, data_i[31:16]} : data_i;


  // crc in selection
  always_comb begin
    if (crc_sel_i == 1'b1)
      if (crc_size_i == CRC8) crc_in_mux = {24'b0, crc_q[15:8]};
      else crc_in_mux = crc_q;
    else crc_in_mux = crc_i;
  end


  // 1st 32x8 XOR array
  crc32_loop8 crc32_i0 (
      .xor_en  (xor_en_i[0]),   // 1: do the 1st XOR , 0: bypass it // TBD
      .data    (data_in_mux0),  // incoming data
      .crc_in  (crc_in_mux),    // incoming crc
      .crc_poly(crc_poly_i),    // polynomial
      .fb_pos  (crc_size_i),    // feedbak ouput position : 00:8 01:16 1X:32
      .crc_out (crc_out0)       // updated crc
  );

  // 2nd array data selection
  always_comb begin
    case (crc_size_i)
      CRC8: data_in_mux1 = {24'b0, data_in_mux0[16:8]};
      CRC16: data_in_mux1 = data_in_mux0;
      CRC32: data_in_mux1 = data_in_mux0;
      default data_in_mux1 = data_in_mux0;
    endcase
  end


  // 2nd 32x8 XOR array
  crc32_loop8 crc32_i1 (
      .xor_en  (xor_en_i[1]),   // 1: do the 1st XOR , 0: bypass it // TBD
      .data    (data_in_mux1),  // incoming data
      .crc_in  (crc_out0),      // incoming crc
      .crc_poly(crc_poly_i),    // polynomial
      .fb_pos  (crc_size_i),    // feedbak position : 00:8 01:16 1X:32
      .crc_out (crc_out1)       // updated crc
  );


  // registers 2*16 bits, can be used as final 4*8 bit, pipeline+acc 2*16 bits,  "acc" intermediate 32 bits

  always_comb begin
    case (crc_size_i)
      CRC8: crc_d = {crc_q[15:0], crc_out1[7:0], crc_out0[7:0]};
      CRC16: crc_d = {crc_q[15:0], crc_out1[15:0]};
      CRC32: crc_d = crc_out1;
      default: crc_d = crc_out1;
    endcase
    if (res_valid_i) crc_d = crc_q;
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin : crc_reg
    if (!rst_ni) begin
      crc_q <= 32'h0;
    end else begin
      crc_q <= crc_d;
    end
  end

  assign crc_o = crc_q;

endmodule
