package cvxif_exp_coprocessor_pkg;

  logic [riscv::XLEN-1:0] ExpIntLut[6:0] = {
    32'hF1, 32'hAFE10, 32'h2582AB7, 32'h1152AAA3, 32'h2F16AC6C, 32'h4DA2CBF1, 32'h63AFBE7A
  };

  logic [riscv::XLEN-1:0] ExpPolyLUT[4:0] = {
    32'h7FFFFFFF, 32'h80000001, 32'h3FFCCA80, 32'hEACD510F, 32'h04B5C29A
  };

  typedef enum logic [2:0] {
    IDLE,
    P_LOOP,
    P_TO_EXP,
    EXP_LOOP,
    EXP_END
  } exp_coprocessor_state_e;

endpackage
