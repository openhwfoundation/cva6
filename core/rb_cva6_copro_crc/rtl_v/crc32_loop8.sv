module crc32_loop8 (
    input  logic        xor_en,    // 1: do the 1st XOR , 0: bypass it
    input  logic [31:0] data,      // incoming data
    input  logic [31:0] crc_in,    // incoming CRC
    input  logic [31:0] crc_poly,  // polynomial
    input  logic [ 1:0] fb_pos,    // feedbak position : 00:8 01:16 1X:32
    output logic [31:0] crc_out    // updated CRC
);

  logic [32:0] crc[9];
  logic [ 7:0] fb;
  integer i, j;

  always_comb begin

    if (xor_en) crc[0] = data ^ crc_in;
    else crc[0] = crc_in;

    for (i = 0; i < 8; i = i + 1) begin
      if (fb[i]) crc[i+1] = (crc[i] << 1) ^ (crc_poly);
      else crc[i+1] = crc[i] << 1;
    end
  end


  always_comb begin
    for (j = 0; j < 8; j = j + 1) begin
      case (fb_pos)
        2'b01:   fb[j] = crc[j][7];
        2'b10:   fb[j] = crc[j][15];
        2'b11:   fb[j] = crc[j][31];
        default: fb[j] = crc[j][31];
      endcase
    end
  end
  assign crc_out = crc[8][31:0];

endmodule
