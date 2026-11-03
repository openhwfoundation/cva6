
package cvxif_crc_instr_pkg;

  typedef struct packed {
    logic [31:0]              instr;
    logic [31:0]              mask;
    cvxif_pkg::x_issue_resp_t resp;
  } copro_issue_resp_t;

  // 3 Possible RISCV instructions for CRC  Coprocessor
  parameter int unsigned NbInstr = 3;
  parameter copro_issue_resp_t CoproInstr[NbInstr] = '{
      '{
          instr: // custom1 opcode for CRC8, func2 = 01
          32'b00000_01_00000_00000_0_00_00000_0101011,
          mask: 32'b00000_11_00000_00000_0_00_00000_1111111,
          resp : '{
              accept : 1'b1,
              writeback : 1'b1,
              dualwrite : 1'b0,
              dualread : 1'b0,
              loadstore : 1'b0,
              exc : 1'b0
          }
      },
      '{
          instr: // custom1 opcode for CRC16, func2 = 10, func3 = 001 or 011
          32'b 00000_10_00000_00000_0_01_00000_0101011,
          mask: 32'b00000_11_00000_00000_0_01_00000_1111111,
          resp : '{
              accept : 1'b1,
              writeback : 1'b1,
              dualwrite : 1'b0,
              dualread : 1'b0,
              loadstore : 1'b0,
              exc : 1'b0
          }
      },
      '{
          instr: // custom1 opcode for CRC32, func2 = 11, func3 = 011
          32'b 00000_11_00000_00000_0_11_00000_0101011,
          mask: 32'b00000_11_00000_00000_0_11_00000_1111111,
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
