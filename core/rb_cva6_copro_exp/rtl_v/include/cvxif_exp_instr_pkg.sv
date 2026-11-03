package cvxif_exp_instr_pkg;

  typedef struct packed {
    logic [31:0]              instr;
    logic [31:0]              mask;
    cvxif_pkg::x_issue_resp_t resp;
  } copro_issue_resp_t;

  // 1 Possible RISCV instructions for Exp Coprocessor
  parameter int unsigned NbInstr = 1;
  parameter copro_issue_resp_t CoproInstr[NbInstr] = '{
      '{
          instr: 32'b00000_00_00000_00000_000_00000_0001011,  // custom0 opcode (func2 : 00)
          mask: 32'b00000_11_00000_00000_000_00000_1111111,
          resp : '{
              accept : 1'b1,
              writeback : 1'b1,
              dualwrite : 1'b0,
              dualread : 1'b0,
              loadstore : 1'b0,
              exc : 1'b0
          }
      }
  };

endpackage
