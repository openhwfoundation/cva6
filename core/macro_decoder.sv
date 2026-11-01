// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// Author: Rohan Arshid, 10xEngineers
// Date: 22.01.2024
// Description: Contains the logic for decoding cm.push, cm.pop, cm.popret, 
//              cm.popretz, cm.mvsa01, and cm.mva01s instructions of the 
//              Zcmp Extension

module macro_decoder #(
    parameter config_pkg::cva6_cfg_t CVA6Cfg = config_pkg::cva6_cfg_empty
) (
    input  logic [31:0] instr_i,
    input  logic        clk_i,                      // Clock
    input  logic        rst_ni,                     // Synchronous reset
    input  logic        flush_i,                    // Drop a macro instruction being expanded
    input  logic        is_macro_instr_i,           // Instruction is of macro extension
    input  logic        illegal_instr_i,            // From compressed decoder
    input  logic        is_compressed_i,
    input  logic        issue_ack_i,                // Check if the instruction is acknowledged
    output logic [31:0] instr_o,
    output logic        illegal_instr_o,
    output logic        is_compressed_o,
    output logic        fetch_stall_o,              // Wait while push/pop/move instructions expand
    output logic        is_last_macro_instr_o,
    output logic        is_double_rd_macro_instr_o
);

  // FSM States
  enum logic [2:0] {
    IDLE,
    INIT,
    PUSH_ADDI,
    POPRETZ_1,
    MOVE,
    PUSH_POP_INSTR_2
  }
      state_d, state_q;

  // Instruction Types
  enum logic [2:0] {
    PUSH,
    POP,
    POPRETZ,
    POPRET,
    MVA01S,
    MVSA01
  } macro_instr_type;

  // Temporary registers
  logic [3:0] reg_numbers, reg_numbers_q, reg_numbers_d;
  logic [11:0] stack_adj;
  logic [4:0] xreg1, xreg2, store_reg, store_reg_q, store_reg_d;
  logic [1:0] popretz_inst_q, popretz_inst_d;
  logic [11:0] offset_reg, offset_q, offset_d;
  logic [31:0] instr_o_reg;

  riscv::itype_t itype_inst;
  assign instr_o = instr_o_reg;

  // Size of a saved register: the stack slots are 4 bytes apart on RV32 and
  // 8 bytes on RV64, accessed with sw/lw or sd/ld.
  localparam logic [11:0] REGB = CVA6Cfg.IS_XLEN64 ? 12'd8 : 12'd4;
  localparam logic [11:0] MINUS_REGB = -REGB;
  localparam logic [2:0] MEM_FUNCT3 = CVA6Cfg.IS_XLEN64 ? 3'h3 : 3'h2;

  // Store and load of a saved register at sp + offset.
  function automatic logic [31:0] st_sp(logic [4:0] rs2, logic [11:0] offset);
    return {offset[11:5], rs2, 5'h2, MEM_FUNCT3, offset[4:0], riscv::OpcodeStore};
  endfunction
  function automatic logic [31:0] ld_sp(logic [4:0] rd, logic [11:0] offset);
    return {offset, 5'h2, MEM_FUNCT3, rd, riscv::OpcodeLoad};
  endfunction
  always_comb begin
    illegal_instr_o            = 1'b0;
    fetch_stall_o              = 1'b0;
    is_last_macro_instr_o      = 1'b0;
    is_double_rd_macro_instr_o = 1'b0;
    is_compressed_o            = is_macro_instr_i ? 1'b1 : is_compressed_i;
    reg_numbers                = '0;
    stack_adj                  = '0;
    macro_instr_type           = PUSH;
    xreg1                      = '0;
    xreg2                      = '0;
    store_reg                  = '0;
    offset_reg                 = '0;
    itype_inst                 = '0;
    instr_o_reg                = instr_i;
    state_d                    = state_q;
    offset_d                   = offset_q;
    reg_numbers_d              = reg_numbers_q;
    store_reg_d                = store_reg_q;
    popretz_inst_d             = popretz_inst_q;

    if (is_macro_instr_i) begin

      unique case (instr_i[12:10])
        // push or pop
        3'b110: begin
          // rlist values 0 to 3 are reserved for a future EABI variant
          if (instr_i[7:4] < 4'b0100) begin
            illegal_instr_o = 1'b1;
            instr_o_reg     = instr_i;
          end

          unique case (instr_i[9:8])
            2'b00: begin
              macro_instr_type = PUSH;
            end
            2'b10: begin
              macro_instr_type = POP;
            end
            default: begin
              illegal_instr_o = 1'b1;
              instr_o_reg     = instr_i;
            end
          endcase
        end
        // popret or popretz
        3'b111: begin
          // rlist values 0 to 3 are reserved for a future EABI variant
          if (instr_i[7:4] < 4'b0100) begin
            illegal_instr_o = 1'b1;
            instr_o_reg     = instr_i;
          end

          unique case (instr_i[9:8])
            2'b00: begin
              macro_instr_type = POPRETZ;
            end
            2'b10: begin
              macro_instr_type = POPRET;
            end
            default: begin
              illegal_instr_o = 1'b1;
              instr_o_reg     = instr_i;
            end
          endcase
        end
        // mvq01s or mvsa01
        3'b011: begin
          unique case (instr_i[6:5])
            2'b01: begin
              macro_instr_type = MVSA01;
            end
            2'b11: begin
              macro_instr_type = MVA01S;
            end
            default: begin
              illegal_instr_o = 1'b1;
              instr_o_reg     = instr_i;
            end
          endcase
        end
        default: begin
          illegal_instr_o = 1'b1;
          instr_o_reg     = instr_i;
        end
      endcase

      // Calculate xreg1 & xreg2 for move instructions
      if (macro_instr_type == MVSA01 || macro_instr_type == MVA01S) begin
        // Only cm.mvsa01 requires its two registers to differ: it writes both,
        // so naming the same one twice has no defined meaning. cm.mva01s reads
        // them into a0 and a1 and is well defined when they are the same.
        if (macro_instr_type == MVA01S || instr_i[9:7] != instr_i[4:2]) begin
          xreg1 = {instr_i[9:8] > 0, instr_i[9:8] == 0, instr_i[9:7]};
          xreg2 = {instr_i[4:3] > 0, instr_i[4:3] == 0, instr_i[4:2]};
        end else begin
          illegal_instr_o = 1'b1;
          instr_o_reg     = instr_i;
        end
      end else begin
        xreg1 = '0;
        xreg2 = '0;
      end

      // push/pop/popret/popretz instructions
      unique case (instr_i[7:4])
        4'b0100: reg_numbers = 4'b0001;  // 4
        4'b0101: reg_numbers = 4'b0010;  // 5
        4'b0110: reg_numbers = 4'b0011;  // 6
        4'b0111: reg_numbers = 4'b0100;  // 7
        4'b1000: reg_numbers = 4'b0101;  // 8
        4'b1001: reg_numbers = 4'b0110;  // 9
        4'b1010: reg_numbers = 4'b0111;  // 10
        4'b1011: reg_numbers = 4'b1000;  // 11
        4'b1100: reg_numbers = 4'b1001;  // 12
        4'b1101: reg_numbers = 4'b1010;  // 13
        4'b1110: reg_numbers = 4'b1011;  // 14
        4'b1111: reg_numbers = 4'b1100;  // 15
        default: reg_numbers = '0;
      endcase

      if (CVA6Cfg.IS_XLEN32) begin
        unique case (instr_i[7:4])
          4'b0100, 4'b0101, 4'b0110, 4'b0111: begin
            unique case (instr_i[3:2])
              2'b00: stack_adj = 16;
              2'b01: stack_adj = 32;
              2'b10: stack_adj = 48;
              2'b11: stack_adj = 64;
            endcase
          end
          4'b1000, 4'b1001, 4'b1010, 4'b1011: begin
            unique case (instr_i[3:2])
              2'b00: stack_adj = 32;
              2'b01: stack_adj = 48;
              2'b10: stack_adj = 64;
              2'b11: stack_adj = 80;
            endcase
          end
          4'b1100, 4'b1101, 4'b1110: begin
            unique case (instr_i[3:2])
              2'b00: stack_adj = 48;
              2'b01: stack_adj = 64;
              2'b10: stack_adj = 80;
              2'b11: stack_adj = 96;
            endcase
          end
          4'b1111: begin
            unique case (instr_i[3:2])
              2'b00: stack_adj = 64;
              2'b01: stack_adj = 80;
              2'b10: stack_adj = 96;
              2'b11: stack_adj = 112;
            endcase
          end
          default: ;
        endcase
      end else begin
        unique case (instr_i[7:4])
          4'b0100, 4'b0101: begin
            unique case (instr_i[3:2])
              2'b00: stack_adj = 16;
              2'b01: stack_adj = 32;
              2'b10: stack_adj = 48;
              2'b11: stack_adj = 64;
            endcase
          end
          4'b0110, 4'b0111: begin
            unique case (instr_i[3:2])
              2'b00: stack_adj = 32;
              2'b01: stack_adj = 48;
              2'b10: stack_adj = 64;
              2'b11: stack_adj = 80;
            endcase
          end
          4'b1000, 4'b1001: begin
            unique case (instr_i[3:2])
              2'b00: stack_adj = 48;
              2'b01: stack_adj = 64;
              2'b10: stack_adj = 80;
              2'b11: stack_adj = 96;
            endcase
          end
          4'b1010, 4'b1011: begin
            unique case (instr_i[3:2])
              2'b00: stack_adj = 64;
              2'b01: stack_adj = 80;
              2'b10: stack_adj = 96;
              2'b11: stack_adj = 112;
            endcase
          end
          4'b1100, 4'b1101: begin
            unique case (instr_i[3:2])
              2'b00: stack_adj = 80;
              2'b01: stack_adj = 96;
              2'b10: stack_adj = 112;
              2'b11: stack_adj = 128;
            endcase
          end
          4'b1110: begin
            unique case (instr_i[3:2])
              2'b00: stack_adj = 96;
              2'b01: stack_adj = 112;
              2'b10: stack_adj = 128;
              2'b11: stack_adj = 144;
            endcase
          end
          4'b1111: begin
            unique case (instr_i[3:2])
              2'b00: stack_adj = 112;
              2'b01: stack_adj = 128;
              2'b10: stack_adj = 144;
              2'b11: stack_adj = 160;
            endcase
          end
          default: ;
        endcase
      end

      //Take 2's compliment in case of PUSH instruction
      if (macro_instr_type == PUSH) begin
        itype_inst.imm = ~stack_adj + 1'b1;
      end else begin
        itype_inst.imm = stack_adj - REGB;
      end
    end else begin
      illegal_instr_o = illegal_instr_i;
      instr_o_reg     = instr_i;
    end

    unique case (state_q)
      IDLE: begin
        if (is_macro_instr_i && !illegal_instr_o) begin
          reg_numbers_d = reg_numbers - 1'b1;
          state_d = issue_ack_i ? INIT : IDLE;
          case (macro_instr_type)
            PUSH: begin
              offset_d = MINUS_REGB + MINUS_REGB;
            end
            POP, POPRETZ, POPRET: begin
              offset_d   = itype_inst.imm + MINUS_REGB;
              offset_reg = itype_inst.imm;
              case (macro_instr_type)
                POPRETZ: begin
                  popretz_inst_d = 2'b11;
                end
                POPRET: begin
                  popretz_inst_d = 2'b01;
                end
                default: begin
                  popretz_inst_d = 'b0;
                end
              endcase
            end
            default: ;
          endcase
          // when rlist is 4, max reg is x18 i.e. 14(const) + 4
          // when rlist is 12, max reg is x27 i.e. 15(const) + 12 
          if (reg_numbers == 4'b1100) begin
            store_reg_d = 4'b1110 + reg_numbers;
            store_reg   = 4'b1111 + reg_numbers;
          end else begin
            store_reg_d = 4'b1101 + reg_numbers;
            store_reg   = 4'b1110 + reg_numbers;
          end

          if (macro_instr_type == MVSA01) begin
            fetch_stall_o = 1;
            is_double_rd_macro_instr_o = 1;
            // addi xreg1, a0, 0
            instr_o_reg = {12'h0, 5'hA, 3'h0, xreg1, riscv::OpcodeOpImm};
            if (issue_ack_i) begin
              state_d = MOVE;
            end
          end

          if (macro_instr_type == MVA01S) begin
            fetch_stall_o = 1;
            is_double_rd_macro_instr_o = 1;
            // addi a0, xreg1, 0
            instr_o_reg = {12'h0, xreg1, 3'h0, 5'hA, riscv::OpcodeOpImm};
            if (issue_ack_i) begin
              state_d = MOVE;
            end
          end

          if (macro_instr_type == PUSH) begin

            fetch_stall_o = 1'b1;  // stall inst fetch

            if (reg_numbers == 4'b0001) begin
              instr_o_reg = st_sp(5'h1, MINUS_REGB);
              if (issue_ack_i) begin
                state_d = PUSH_ADDI;
              end
            end

            if (reg_numbers == 4'b0010) begin
              instr_o_reg = st_sp(5'h8, MINUS_REGB);
            end

            if (reg_numbers == 4'b0011) begin
              instr_o_reg = st_sp(5'h9, MINUS_REGB);

            end

            if (reg_numbers >= 4 && reg_numbers <= 12) begin
              instr_o_reg = st_sp(store_reg, MINUS_REGB);

              if (reg_numbers == 12 && issue_ack_i) begin
                state_d = PUSH_POP_INSTR_2;
              end
            end
          end

          if ((macro_instr_type == POP || macro_instr_type == POPRETZ || macro_instr_type == POPRET)) begin
            fetch_stall_o = 1;  // stall inst fetch
            if (reg_numbers == 1) begin
              instr_o_reg = ld_sp(5'h1, offset_reg);
              if (issue_ack_i) begin
                unique case (macro_instr_type)
                  PUSH, POP, POPRET: begin
                    state_d = PUSH_ADDI;
                  end
                  POPRETZ: begin
                    state_d = POPRETZ_1;
                  end
                  default: ;
                endcase
              end
            end

            if (reg_numbers == 2) begin
              instr_o_reg = ld_sp(5'h8, offset_reg);
            end

            if (reg_numbers == 3) begin
              instr_o_reg = ld_sp(5'h9, offset_reg);
            end

            if (reg_numbers >= 4 && reg_numbers <= 12) begin
              instr_o_reg = ld_sp(store_reg, offset_reg);

              if (reg_numbers == 12 && issue_ack_i) begin
                state_d = PUSH_POP_INSTR_2;
              end
            end
          end
        end
      end
      INIT: begin
        fetch_stall_o = is_macro_instr_i;  // stall inst fetch
        if (issue_ack_i && is_macro_instr_i && macro_instr_type == PUSH) begin
          if (reg_numbers_q == 4'b0001) begin
            instr_o_reg = st_sp(5'h1, offset_d);
            state_d = PUSH_ADDI;
          end

          if (reg_numbers_q == 4'b0010) begin
            instr_o_reg = st_sp(5'h8, offset_d);
            reg_numbers_d = reg_numbers_q - 1;
            offset_d = offset_q + MINUS_REGB;
          end

          if (reg_numbers_q == 4'b0011) begin
            instr_o_reg = st_sp(5'h9, offset_d);
            reg_numbers_d = reg_numbers_q - 1;
            offset_d = offset_q + MINUS_REGB;
          end

          if (reg_numbers_q >= 4 && reg_numbers_q <= 12) begin
            instr_o_reg = st_sp(store_reg_q, offset_d);
            reg_numbers_d = reg_numbers_q - 1;
            store_reg_d = store_reg_q - 1;
            offset_d = offset_q + MINUS_REGB;
            if (reg_numbers_q == 12) begin
              state_d = PUSH_POP_INSTR_2;
            end
          end
        end

        if (issue_ack_i && is_macro_instr_i && (macro_instr_type == POP || macro_instr_type == POPRETZ || macro_instr_type == POPRET)) begin

          if (reg_numbers_q == 1) begin
            instr_o_reg = ld_sp(5'h1, offset_d);
            unique case (macro_instr_type)
              PUSH, POP, POPRET: begin
                state_d = PUSH_ADDI;
              end
              POPRETZ: begin
                state_d = POPRETZ_1;
              end
              default: ;
            endcase
          end

          if (reg_numbers_q == 2) begin
            instr_o_reg = ld_sp(5'h8, offset_d);
            reg_numbers_d = reg_numbers_q - 1;
            offset_d = offset_q + MINUS_REGB;
          end

          if (reg_numbers_q == 3) begin
            instr_o_reg = ld_sp(5'h9, offset_d);
            reg_numbers_d = reg_numbers_q - 1;
            offset_d = offset_q + MINUS_REGB;
          end

          if (reg_numbers_q >= 4 && reg_numbers_q <= 12) begin
            instr_o_reg = ld_sp(store_reg_q, offset_d);
            reg_numbers_d = reg_numbers_q - 1;
            store_reg_d = store_reg_q - 1;
            offset_d = offset_q + MINUS_REGB;
            if (reg_numbers_q == 12) begin
              state_d = PUSH_POP_INSTR_2;
            end
          end
        end
      end

      MOVE: begin
        case (macro_instr_type)
          MVSA01: begin
            if (issue_ack_i) begin
              // addi xreg2, a1, 0
              instr_o_reg = {12'h0, 5'hB, 3'h0, xreg2, riscv::OpcodeOpImm};
              fetch_stall_o = 0;
              is_last_macro_instr_o = 1;
              is_double_rd_macro_instr_o = 1;
              state_d = IDLE;
            end
          end
          MVA01S: begin
            if (issue_ack_i) begin
              // addi a1, xreg2, 0
              instr_o_reg = {12'h0, xreg2, 3'h0, 5'hB, riscv::OpcodeOpImm};
              fetch_stall_o = 0;
              is_last_macro_instr_o = 1;
              is_double_rd_macro_instr_o = 1;
              state_d = IDLE;
            end
          end
          default: begin
            illegal_instr_o = 1'b1;
            instr_o_reg     = instr_i;
          end
        endcase
      end

      PUSH_ADDI: begin
        if (issue_ack_i && is_macro_instr_i && macro_instr_type == PUSH) begin
          // addi sp, sp, -stack_adj
          instr_o_reg = {itype_inst.imm, 5'h2, 3'h0, 5'h2, riscv::OpcodeOpImm};
        end else begin
          if (issue_ack_i) begin
            // addi sp, sp, stack_adj
            instr_o_reg = {stack_adj, 5'h2, 3'h0, 5'h2, riscv::OpcodeOpImm};
          end
        end
        if (issue_ack_i && is_macro_instr_i && (macro_instr_type == POPRETZ || macro_instr_type == POPRET)) begin
          state_d = POPRETZ_1;
          fetch_stall_o = 1;
        end else begin
          if (issue_ack_i) begin
            state_d = IDLE;
            fetch_stall_o = 0;
            is_last_macro_instr_o = 1;
          end else begin
            fetch_stall_o = 1;
          end
        end
      end

      PUSH_POP_INSTR_2: begin
        case (macro_instr_type)
          PUSH: begin
            if (issue_ack_i) begin
              instr_o_reg = st_sp(store_reg_q, offset_d);
              offset_d = offset_q + MINUS_REGB;
              store_reg_d = store_reg_q - 1;
              state_d = INIT;
            end
          end
          POP, POPRETZ, POPRET: begin
            if (issue_ack_i) begin
              instr_o_reg = ld_sp(store_reg_q, offset_d);
              offset_d = offset_q + MINUS_REGB;
              store_reg_d = store_reg_q - 1;
              state_d = INIT;
            end
          end
          default: begin
            illegal_instr_o = 1'b1;
            instr_o_reg     = instr_i;
          end
        endcase
        fetch_stall_o = 1;
      end

      POPRETZ_1: begin
        unique case (popretz_inst_q)
          2'b11: begin
            if (issue_ack_i) begin
              instr_o_reg = {20'h0, 5'hA, riscv::OpcodeLui};  //lui a0, 0x0
              popretz_inst_d = popretz_inst_q - 1;
            end
            fetch_stall_o = 1;
          end
          2'b10: begin
            if (issue_ack_i) begin
              instr_o_reg = {12'h0, 5'hA, 3'h0, 5'hA, riscv::OpcodeOpImm};  //addi a0, a0, 0x0
              popretz_inst_d = popretz_inst_q - 1;
              state_d = PUSH_ADDI;
            end
            fetch_stall_o = 1;
          end
          2'b01: begin
            if (issue_ack_i) begin
              instr_o_reg = {12'h0, 5'h1, 3'h0, 5'h0, riscv::OpcodeJalr};  //ret - jalr x0, x1, 0
              state_d = IDLE;
              fetch_stall_o = 0;
              is_last_macro_instr_o = 1;
              popretz_inst_d = popretz_inst_q - 1;
            end
          end
          default: begin
            illegal_instr_o = 1'b1;
            instr_o_reg     = instr_i;
          end
        endcase
      end
      default: begin
        state_d = IDLE;
      end
    endcase
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      state_q <= IDLE;
      offset_q <= '0;
      popretz_inst_q <= '0;
      reg_numbers_q <= '0;
      store_reg_q <= '0;
    end else begin
      // A flushed macro instruction leaves its expansion: the next one starts
      // from IDLE, not from the micro-op the flushed one stopped at
      state_q <= flush_i ? IDLE : state_d;
      offset_q <= offset_d;
      reg_numbers_q <= reg_numbers_d;
      store_reg_q <= store_reg_d;
      popretz_inst_q <= popretz_inst_d;
    end
  end
endmodule
