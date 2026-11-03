module exp_adder (
    input logic [riscv::XLEN-1:0] exp_poly_i,
    input logic [riscv::XLEN-1:0] exp_mult_i,
    input logic [1:0] add_mux_i,
    output logic [riscv::XLEN-1:0] add_o
);

  always_comb begin
    case (add_mux_i)
      2'b00: add_o = exp_poly_i;

      2'b01: add_o = exp_poly_i + exp_mult_i;

      2'b10: add_o = exp_mult_i;

      default: add_o = exp_poly_i + exp_mult_i;
    endcase
  end

endmodule
