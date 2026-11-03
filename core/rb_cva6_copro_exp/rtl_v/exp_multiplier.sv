
module exp_multiplier (
    input  logic [riscv::XLEN-1:0] data_a,
    input  logic [riscv::XLEN-1:0] data_b,
    input  logic                   M_mux,
    output logic [riscv::XLEN-1:0] data_o
);

  // intermediary data on 64 bits
  logic [2*riscv::XLEN-1:0] data_c;

  always_comb begin
    if (data_a == 1) begin
      data_c = 0;
      data_o = data_b;
    end else begin
      data_c = $signed(data_a) * $signed(data_b);
      data_o = data_c >>> riscv::XLEN - 1;
    end
  end

endmodule
