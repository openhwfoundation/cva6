// Copyright 2018 - 2019 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// Author: Florian Zaruba <zarubaf@iis.ee.ethz.ch>
// Description: Instruction Re-aligner
//
// This module takes cache blocks and extracts the instructions.
// As we are supporting the compressed instruction set extension, in a 32 bit instruction word
// are up to 2 compressed instructions.
// Furthermore those instructions can be arbitrarily interleaved which makes it possible to fetch
// only the lower part of a 32 bit instruction.
// Furthermore we need to handle the case if we want to start fetching from an unaligned
// instruction e.g. a branch.

module instr_realign
  import ariane_pkg::*;
#(
    parameter config_pkg::cva6_cfg_t CVA6Cfg = config_pkg::cva6_cfg_empty
) (
    // Subsystem Clock - SUBSYSTEM
    input logic clk_i,
    // Asynchronous reset active low - SUBSYSTEM
    input logic rst_ni,
    // Fetch flush request - CONTROLLER
    input logic flush_i,
    // 32-bit block is valid - CACHE
    input logic valid_i,
    // Instruction is unaligned - FRONTEND
    output logic serving_unaligned_o,
    // 32-bit block address - CACHE
    input logic [CVA6Cfg.VLEN-1:0] address_i,
    // 32-bit block - CACHE
    input logic [CVA6Cfg.FETCH_WIDTH-1:0] data_i,
    // instruction is valid - FRONTEND
    output logic [CVA6Cfg.INSTR_PER_FETCH-1:0] valid_o,
    // Instruction address - FRONTEND
    output logic [CVA6Cfg.INSTR_PER_FETCH-1:0][CVA6Cfg.VLEN-1:0] addr_o,
    // Instruction - instr_scan&instr_queue
    output logic [CVA6Cfg.INSTR_PER_FETCH-1:0][31:0] instr_o
);
  // as a maximum we support a fetch width of 64-bit, hence there can be 4 compressed instructions
  logic [CVA6Cfg.INSTR_PER_FETCH-1:0] instr_is_compressed;

  for (genvar i = 0; i < CVA6Cfg.INSTR_PER_FETCH; i++) begin
    // LSB != 2'b11
    assign instr_is_compressed[i] = ~&data_i[i*16+:2];
  end

  // save the unaligned part of the instruction to this ff
  logic [15:0] unaligned_instr_d, unaligned_instr_q;
  // the last instruction was unaligned
  logic unaligned_d, unaligned_q;
  // register to save the unaligned address
  logic [CVA6Cfg.VLEN-1:0] unaligned_address_d, unaligned_address_q;
  // we have an unaligned instruction
  assign serving_unaligned_o = unaligned_q;

  // Instruction re-alignment
  if (CVA6Cfg.FETCH_WIDTH == 32) begin : realign_bp_32
    always_comb begin : re_align
      unaligned_d = unaligned_q;
      unaligned_address_d = {address_i[CVA6Cfg.VLEN-1:2], 2'b10};
      unaligned_instr_d = data_i[31:16];

      valid_o[0] = valid_i;
      instr_o[0] = unaligned_q ? {data_i[15:0], unaligned_instr_q} : data_i[31:0];
      addr_o[0] = unaligned_q ? unaligned_address_q : address_i;

      if (CVA6Cfg.INSTR_PER_FETCH != 1) begin
        valid_o[CVA6Cfg.INSTR_PER_FETCH-1] = 1'b0;
        instr_o[CVA6Cfg.INSTR_PER_FETCH-1] = '0;
        addr_o[CVA6Cfg.INSTR_PER_FETCH-1]  = {address_i[CVA6Cfg.VLEN-1:2], 2'b10};
      end
      // this instruction is compressed or the last instruction was unaligned
      if (instr_is_compressed[0] || unaligned_q) begin
        // check if this is instruction is still unaligned e.g.: it is not compressed
        // if its compressed re-set unaligned flag
        // for 32 bit we can simply check the next instruction and whether it is compressed or not
        // if it is compressed the next fetch will contain an aligned instruction
        // is instruction 1 also compressed
        // yes? -> no problem, no -> we've got an unaligned instruction
        if (instr_is_compressed[CVA6Cfg.INSTR_PER_FETCH-1] && CVA6Cfg.RVC) begin
          unaligned_d = 1'b0;
          valid_o[CVA6Cfg.INSTR_PER_FETCH-1] = valid_i;
          instr_o[CVA6Cfg.INSTR_PER_FETCH-1] = {16'b0, data_i[31:16]};
        end else begin
          // save the upper bits for next cycle
          unaligned_d = 1'b1;
          unaligned_instr_d = data_i[31:16];
          unaligned_address_d = {address_i[CVA6Cfg.VLEN-1:2], 2'b10};
        end
      end  // else -> normal fetch

      // we started to fetch on a unaligned boundary with a whole instruction -> wait until we've
      // received the next instruction
      if (valid_i && address_i[1]) begin
        // the instruction is not compressed so we can't do anything in this cycle
        if (!instr_is_compressed[0]) begin
          valid_o = '0;
          unaligned_d = 1'b1;
          unaligned_address_d = {address_i[CVA6Cfg.VLEN-1:2], 2'b10};
          unaligned_instr_d = data_i[15:0];
          // the instruction isn't compressed but only the lower is ready
        end else begin
          valid_o = {{CVA6Cfg.INSTR_PER_FETCH - 1{1'b0}}, 1'b1};
        end
      end
    end
  end else if (CVA6Cfg.FETCH_WIDTH == 64 && !CVA6Cfg.RVC) begin : realign_bp_64_without_c
    // Without the C extension every instruction is 32 bits wide and 4-byte
    // aligned: it never straddles the 64-bit fetch block, so nothing is realigned.
    always_comb begin : re_align
      unaligned_d         = 1'b0;
      unaligned_address_d = unaligned_address_q;
      unaligned_instr_d   = unaligned_instr_q;

      //  the fetch address is 4-byte aligned, so bit 2 selects which of the
      //  two words of the block holds the first instruction
      if (address_i[2]) begin
        //  second half of the block: a single instruction is available
        valid_o    = {{CVA6Cfg.INSTR_PER_FETCH - 1{1'b0}}, valid_i};
        instr_o[0] = data_i[63:32];
        addr_o[0]  = address_i;
        instr_o[1] = '0;
        addr_o[1]  = address_i;
      end else begin
        //  whole block: both words hold an instruction
        valid_o    = {CVA6Cfg.INSTR_PER_FETCH{valid_i}};
        instr_o[0] = data_i[31:0];
        addr_o[0]  = address_i;
        instr_o[1] = data_i[63:32];
        addr_o[1]  = {address_i[CVA6Cfg.VLEN-1:3], 3'b100};
      end
    end
  end else if (CVA6Cfg.FETCH_WIDTH == 64) begin : realign_bp_64
    always_comb begin : re_align
      unaligned_d         = 1'b0;
      unaligned_address_d = unaligned_address_q;
      unaligned_instr_d   = unaligned_instr_q;

      valid_o             = '0;
      instr_o[0]          = '0;
      addr_o[0]           = '0;
      instr_o[1]          = '0;
      addr_o[1]           = '0;
      instr_o[2]          = '0;
      addr_o[2]           = '0;
      instr_o[3]          = {16'b0, data_i[63:48]};
      addr_o[3]           = {address_i[CVA6Cfg.VLEN-1:3], 3'b110};

      case (address_i[2:1])
        2'b00: begin
          valid_o[0]  = valid_i;
          valid_o[1]  = valid_i;

          unaligned_d = unaligned_q;

          // last instruction was unaligned
          if (unaligned_q) begin
            // for 64 bit there exist the following options:
            //     64  48  32  16  0
            //     | 3 | 2 | 1 | 0 | <- instruction slot
            // |   I   |   I   |   U   | -> again unaligned
            // | * | C |   I   |   U   | -> aligned
            // | * |   I   | C |   U   | -> aligned
            // |   I   | C | C |   U   | -> again unaligned
            // | * | C | C | C |   U   | -> aligned
            // Legend: C = compressed, I = 32 bit instruction, U = unaligned upper half

            instr_o[0] = {data_i[15:0], unaligned_instr_q};
            addr_o[0]  = unaligned_address_q;

            instr_o[1] = data_i[47:16];
            addr_o[1]  = {address_i[CVA6Cfg.VLEN-1:3], 3'b010};

            if (instr_is_compressed[1]) begin
              instr_o[2] = data_i[63:32];
              addr_o[2]  = {address_i[CVA6Cfg.VLEN-1:3], 3'b100};
              valid_o[2] = valid_i;

              if (instr_is_compressed[2]) begin
                if (instr_is_compressed[3]) begin
                  unaligned_d = 1'b0;
                  valid_o[3]  = valid_i;
                end else begin
                  unaligned_instr_d   = instr_o[3];
                  unaligned_address_d = addr_o[3];
                end
              end else begin
                unaligned_d = 1'b0;
                valid_o[2]  = valid_i;
              end
            end else begin
              instr_o[2] = instr_o[3];
              addr_o[2]  = addr_o[3];
              if (instr_is_compressed[3]) begin
                unaligned_d = 1'b0;
                valid_o[2]  = valid_i;
              end else begin
                unaligned_instr_d   = instr_o[3];
                unaligned_address_d = addr_o[3];
              end
            end
          end else begin
            instr_o[0] = data_i[31:0];
            addr_o[0]  = address_i;

            if (instr_is_compressed[0]) begin
              instr_o[1] = data_i[47:16];
              addr_o[1]  = {address_i[CVA6Cfg.VLEN-1:3], 3'b010};

              //     64  48  32  16  0
              //     | 3 | 2 | 1 | 0 | <- instruction slot
              // |   I   |   I   | C | -> again unaligned
              // | * | C |   I   | C | -> aligned
              // | * |   I   | C | C | -> aligned
              // |   I   | C | C | C | -> again unaligned
              // | * | C | C | C | C | -> aligned
              if (instr_is_compressed[1]) begin
                instr_o[2] = data_i[63:32];
                addr_o[2]  = {address_i[CVA6Cfg.VLEN-1:3], 3'b100};
                valid_o[2] = valid_i;

                if (instr_is_compressed[2]) begin
                  if (instr_is_compressed[3]) begin
                    valid_o[3] = valid_i;
                  end else begin
                    unaligned_d         = 1'b1;
                    unaligned_instr_d   = instr_o[3];
                    unaligned_address_d = addr_o[3];
                  end
                end
              end else begin
                instr_o[2] = instr_o[3];
                addr_o[2]  = addr_o[3];

                if (instr_is_compressed[3]) begin
                  valid_o[2] = valid_i;
                end else begin
                  unaligned_d         = 1'b1;
                  unaligned_instr_d   = instr_o[3];
                  unaligned_address_d = addr_o[3];
                end
              end
            end else begin
              //     64     32       0
              //     | 3 | 2 | 1 | 0 | <- instruction slot
              // |   I   | C |   I   |
              // | * | C | C |   I   |
              // | * |   I   |   I   |
              instr_o[1] = data_i[63:32];
              addr_o[1]  = {address_i[CVA6Cfg.VLEN-1:3], 3'b100};

              instr_o[2] = instr_o[3];
              addr_o[2]  = addr_o[3];

              if (instr_is_compressed[2]) begin
                if (instr_is_compressed[3]) begin
                  valid_o[2] = valid_i;
                end else begin
                  unaligned_d         = 1'b1;
                  unaligned_instr_d   = instr_o[3];
                  unaligned_address_d = addr_o[3];
                end
              end
            end
          end
        end
        // this means the previous instruction was either compressed or unaligned
        // in any case we don't care
        2'b01: begin
          // 64  48  32  16  0
          // | 3 | 2 | 1 | 0 | <- instruction slot
          // |   I   |   I   | -> again unaligned
          // | * | C |   I   | -> aligned
          // | * |   I   | C | -> aligned
          // |   I   | C | C | -> again unaligned
          // | * | C | C | C | -> aligned
          //   000 110 100 010 <- unaligned address

          instr_o[0] = data_i[31:0];
          addr_o[0]  = {address_i[CVA6Cfg.VLEN-1:3], 3'b010};
          valid_o[0] = valid_i;

          instr_o[2] = data_i[63:32];
          addr_o[2]  = {address_i[CVA6Cfg.VLEN-1:3], 3'b110};

          if (instr_is_compressed[0]) begin
            instr_o[1] = data_i[47:16];
            addr_o[1]  = {address_i[CVA6Cfg.VLEN-1:3], 3'b100};
            valid_o[1] = valid_i;

            if (instr_is_compressed[1]) begin
              if (instr_is_compressed[2]) begin
                valid_o[2] = valid_i;
              end else begin
                unaligned_d         = 1'b1;
                unaligned_instr_d   = instr_o[2];
                unaligned_address_d = addr_o[2];
              end
            end
          end else begin
            instr_o[1] = instr_o[2];
            addr_o[1]  = addr_o[2];

            if (instr_is_compressed[2]) begin
              valid_o[1] = valid_i;
            end else begin
              unaligned_d         = 1'b1;
              unaligned_instr_d   = instr_o[2];
              unaligned_address_d = addr_o[2];
            end
          end
        end
        2'b10: begin
          // 64  48  32  16  0
          // | 3 | 2 | 1 | 0 | <- instruction slot
          // | * |   I   | C | <- unaligned
          // |   *   | C | C | <- aligned
          // |   *   |   I   | <- aligned
          //      1000 110 100 <- unaligned address

          instr_o[0] = data_i[31:0];
          addr_o[0]  = {address_i[CVA6Cfg.VLEN-1:3], 3'b100};
          valid_o[0] = valid_i;

          instr_o[1] = data_i[47:16];
          addr_o[1]  = {address_i[CVA6Cfg.VLEN-1:3], 3'b110};

          if (instr_is_compressed[0]) begin
            if (instr_is_compressed[1]) begin
              valid_o[1] = valid_i;
            end else begin
              unaligned_d         = 1'b1;
              unaligned_instr_d   = instr_o[1];
              unaligned_address_d = addr_o[1];
            end
          end
        end
        // we started to fetch on a unaligned boundary with a whole instruction -> wait until we've
        // received the next instruction
        2'b11: begin
          //     64  48  32  16  0
          // | 3 | 2 | 1 | 0 | <- instruction slot
          // |   *   |   I   | <- unaligned
          // |     *     | C | <- aligned
          //          1000 110 <- unaligned address

          instr_o[0] = data_i[31:0];
          addr_o[0]  = {address_i[CVA6Cfg.VLEN-1:3], 3'b110};

          if (instr_is_compressed[0]) begin
            valid_o[0] = valid_i;
          end else begin
            unaligned_d         = 1'b1;
            unaligned_instr_d   = instr_o[0];
            unaligned_address_d = addr_o[0];
          end
        end
      endcase
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      unaligned_q         <= 1'b0;
      unaligned_address_q <= '0;
      unaligned_instr_q   <= '0;
    end else begin
      if (valid_i) begin
        unaligned_address_q <= unaligned_address_d;
        unaligned_instr_q   <= unaligned_instr_d;
      end

      if (flush_i) begin
        unaligned_q <= 1'b0;
      end else if (valid_i) begin
        unaligned_q <= unaligned_d;
      end
    end
  end
endmodule
