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
// Author: Florian Zaruba, ETH Zurich - Andreas Traber, ACP
// Date: 30.05.2017
// Description: Instruction tracer single instruction item

`ifndef VERILATOR
function string printPCexpr(input logic [63:0] imm);
  // check if the sign bit is set
  if ($signed(imm) > 0) begin
      return $sformatf("pc + %0d", $signed(imm));
  end else begin
      return $sformatf("pc - %0d", $signed(-imm));
  end
endfunction

class instr_trace_item #(
    parameter config_pkg::cva6_cfg_t CVA6Cfg = config_pkg::cva6_cfg_empty,
    parameter type bp_resolve_t = logic,
    parameter type scoreboard_entry_t = logic
);
    // keep a couple of general purpose information inside this instruction item
    time               simtime;
    longint unsigned   cycle;
    scoreboard_entry_t sbe;
    logic [31:0]       pc;
    logic [31:0]       instr;
    logic [63:0]       gp_reg_file [32];
    logic [63:0]       fp_reg_file [32];
    logic [4:0]        read_regs [$];
    logic              read_fpr [$];
    logic [4:0]        result_regs [$];
    logic              result_fpr [$];
    logic [63:0]       imm;
    logic [63:0]       result;
    logic              dest_we_valid;
    logic              dest_is_fp;
    logic [CVA6Cfg.PLEN-1:0]       paddr;
    string             priv_lvl;
    bp_resolve_t       bp;

    logic [4:0] rs1, rs2, rs3, rd;

    // constructor creating a new instruction trace item, e.g.: a single instruction with all relevant information
    function new (time simtime, longint unsigned cycle, scoreboard_entry_t sbe, logic [31:0] instr, logic [63:0] gp_reg_file [32],
                logic [63:0] fp_reg_file [32], logic [63:0] result, logic dest_we_valid, logic dest_is_fp, logic [CVA6Cfg.PLEN-1:0] paddr, riscv::priv_lvl_t priv_lvl, logic debug_mode, bp_resolve_t bp);
        this.simtime  = simtime;
        this.cycle    = cycle;
        this.pc       = sbe.pc;
        this.sbe      = sbe;
        this.gp_reg_file = gp_reg_file;
        this.fp_reg_file = fp_reg_file;
        this.result   = result;
        this.dest_we_valid = dest_we_valid;
        this.dest_is_fp = dest_is_fp;
        this.paddr    = paddr;
        this.bp       = bp;
        this.priv_lvl = (debug_mode) ? "D" : getPrivLevel(priv_lvl);
        this.rs1      = sbe.rs1[4:0];
        this.rs2      = sbe.rs2[4:0];
        this.rs3      = instr[31:27];
        this.rd       = sbe.rd[4:0];
        if (instr[1:0] != 2'b11) begin
            this.instr    = {16'b0, instr[15:0]};
        end else begin
            this.instr    = instr;
        end
    endfunction

    // convert gp register address to ABI compatible form
    function string regAddrToStr(logic [5:0] addr);
        case (addr[4:0])
            0: return "x0";
            1: return "ra";
            2: return "sp";
            3: return "gp";
            4: return "tp";
            5, 6, 7: return $sformatf("t%0d", (addr[4:0] - 5));
            8, 9: return $sformatf("s%0d", (addr[4:0] - 8));
            10, 11, 12, 13, 14, 15, 16, 17: return $sformatf("a%0d", (addr[4:0] - 10));
            28, 29, 30, 31: return $sformatf("t%0d", (addr[4:0] - 25));
            default: return $sformatf("s%0d", (addr[4:0] - 16));
        endcase
    endfunction
    // convert fp register address to ABI compatible form
    function string fpRegAddrToStr(logic [5:0] addr);
        case (addr) inside
            [0:7]   : return $sformatf("ft%0d", addr);
            [8:9]   : return $sformatf("fs%0d", (addr - 8));
            [10:17] : return $sformatf("fa%0d", (addr - 10));
            [18:27] : return $sformatf("fs%0d", (addr - 16));
            [28:31] : return $sformatf("ft%0d", (addr - 20));
        endcase
    endfunction

    function string fpFmtToStr(logic [1:0] fmt);
        case (fmt)
            2'b00 : return "s";
            2'b01 : return "d";
            2'b10 : return "h";
            2'b11 : return "b";
            default : return "XX";
        endcase
    endfunction

    function string fmvFpFmtToStr(logic [1:0] fmt);
        case (fmt)
            2'b00 : return "w";
            2'b01 : return "d";
            2'b10 : return "h";
            2'b11 : return "b";
            default : return "XX";
        endcase
    endfunction

    function string intFmtToStr(logic [1:0] ifmt);
        case (ifmt)
            2'b00 : return "w";
            2'b01 : return "wu";
            2'b10 : return "l";
            2'b11 : return "lu";
            default : return "XX";
        endcase
    endfunction

    function string fpRmToStr(logic [2:0] rm);
        case (rm)
            3'b000 : return "rne";
            3'b001 : return "rtz";
            3'b010 : return "rdn";
            3'b011 : return "rup";
            3'b100 : return "rmm";
            3'b111 : return "dyn"; // what is this called in rv binutils?
            default: return "INVALID";
        endcase
    endfunction

    function string csrAddrToStr(logic [11:0] addr);
        case (addr)
            riscv::CSR_FFLAGS:     return "fflags";
            riscv::CSR_FRM:        return "frm";
            riscv::CSR_FCSR:       return "fcsr";
            riscv::CSR_SSTATUS:    return "sstatus";
            riscv::CSR_SIE:        return "sie";
            riscv::CSR_STVEC:      return "stvec";
            riscv::CSR_SCOUNTEREN: return "scounteren";
            riscv::CSR_SSCRATCH:   return "sscratch";
            riscv::CSR_SEPC:       return "sepc";
            riscv::CSR_SCAUSE:     return "scause";
            riscv::CSR_STVAL:      return "stval";
            riscv::CSR_SIP:        return "sip";
            riscv::CSR_SATP:       return "satp";

            riscv::CSR_MSTATUS:    return "mstatus";
            riscv::CSR_MISA:       return "misa";
            riscv::CSR_MEDELEG:    return "medeleg";
            riscv::CSR_MIDELEG:    return "mideleg";
            riscv::CSR_MIE:        return "mie";
            riscv::CSR_MTVEC:      return "mtvec";
            riscv::CSR_MCOUNTEREN: return "mcounteren";
            riscv::CSR_MSCRATCH:   return "mscratch";
            riscv::CSR_MEPC:       return "mepc";
            riscv::CSR_MCAUSE:     return "mcause";
            riscv::CSR_MTVAL:      return "mtval";
            riscv::CSR_MIP:        return "mip";
            riscv::CSR_PMPCFG0:    return "pmpcfg0";
            riscv::CSR_PMPADDR0:   return "pmpaddr0";
            riscv::CSR_MVENDORID:  return "mvendorid";
            riscv::CSR_MARCHID:    return "marchid";
            riscv::CSR_MIMPID:     return "mimpid";
            riscv::CSR_MHARTID:    return "mhartid";
            riscv::CSR_MCYCLE:     return "mcycle";
            riscv::CSR_MINSTRET:   return "minstret";

            riscv::CSR_TSELECT:    return "tselect";
            riscv::CSR_TDATA1:     return "tdata1";
            riscv::CSR_TDATA2:     return "tdata2";
            riscv::CSR_TDATA3:     return "tdata3";
            riscv::CSR_TINFO:      return "tinfo";

            riscv::CSR_DCSR:       return "dcsr";
            riscv::CSR_DPC:        return "dpc";
            riscv::CSR_DSCRATCH0:  return "dscratch0";
            riscv::CSR_DSCRATCH1:  return "dscratch1";

            riscv::CSR_CYCLE:      return "cycle";
            riscv::CSR_TIME:       return "time";
            riscv::CSR_INSTRET:    return "instret";

            default:        return $sformatf("%0h", addr);
        endcase
    endfunction

    function logic scoreboardDestIsFp();
        if (sbe.fu inside {ariane_pkg::FPU, ariane_pkg::FPU_VEC}) begin
            return ariane_pkg::fd_changes_rd_state(sbe.op);
        end
        return ariane_pkg::is_rd_fpr(sbe.op);
    endfunction

    function logic rawDestIsFp();
        if (dest_we_valid) begin
            return dest_is_fp;
        end
        return scoreboardDestIsFp();
    endfunction

    function logic fpInstrForcesGprDest();
        logic [6:0] opcode = instr[6:0];
        logic [4:0] funct5 = instr[31:27];
        logic [2:0] rm     = instr[14:12];

        if (opcode == riscv::OpcodeOpFp) begin
            if (funct5 == 5'b11000) begin
                // fcvt.*.* instructions that target an integer register
                return 1'b1;
            end

            if (funct5 == 5'b10100) begin
                // fle.*, flt.*, feq.* comparisons produce integer results.
                return 1'b1;
            end

            if (funct5 == 5'b11100) begin
                // fmv.x.* (rm == 000) and fclass (rm == 001) always write GPRs.
                if ((rm == 3'b000) || (rm == 3'b001)) begin
                    return 1'b1;
                end
                // Alternate encodings when FP16ALT is enabled mirror rm encodings.
                if (CVA6Cfg.XF16ALT && ((rm == 3'b100) || (rm == 3'b101))) begin
                    return 1'b1;
                end
            end
        end

        return 1'b0;
    endfunction

    function logic effectiveDestIsFp();
        logic dest_is_fp_raw = rawDestIsFp();

        if (fpInstrForcesGprDest()) begin
            return 1'b0;
        end

        return dest_is_fp_raw;
    endfunction

    function void adjustResultRegKinds();
        logic final_dest_is_fp = effectiveDestIsFp();
        foreach (result_fpr[i]) begin
            result_fpr[i] = final_dest_is_fp;
        end
    endfunction

    function string printInstr();
        string s;

        case (instr) inside
             // Aliases
            instr_tracer_pkg::INSTR_NOP:      s = this.printMnemonic("nop");
            // Regular opcodes
            instr_tracer_pkg::INSTR_LUI:      s = this.printUInstr("lui");
            instr_tracer_pkg::INSTR_AUIPC:    s = this.printUInstr("auipc");
            instr_tracer_pkg::INSTR_JAL:      s = this.printJump("jal");
            instr_tracer_pkg::INSTR_JALR:     s = this.printJump("jalr");
            // BRANCH
            instr_tracer_pkg::INSTR_BEQZ:     s = this.printSBInstr("beqz");
            instr_tracer_pkg::INSTR_BEQ:      s = this.printSBInstr("beq");
            instr_tracer_pkg::INSTR_BNEZ:     s = this.printSBInstr("bnez");
            instr_tracer_pkg::INSTR_BNE:      s = this.printSBInstr("bne");
            instr_tracer_pkg::INSTR_BLTZ:     s = this.printSBInstr("bltz");
            instr_tracer_pkg::INSTR_BLT:      s = this.printSBInstr("blt");
            instr_tracer_pkg::INSTR_BGEZ:     s = this.printSBInstr("bgez");
            instr_tracer_pkg::INSTR_BGE:      s = this.printSBInstr("bge");
            instr_tracer_pkg::INSTR_BLTU:     s = this.printSBInstr("bltu");
            instr_tracer_pkg::INSTR_BGEU:     s = this.printSBInstr("bgeu");
            // OPIMM
            instr_tracer_pkg::INSTR_LI:       s = this.printIInstr("li");
            instr_tracer_pkg::INSTR_ADDI:     s = this.printIInstr("addi");
            instr_tracer_pkg::INSTR_SLTI:     s = this.printIInstr("slti");
            instr_tracer_pkg::INSTR_SLTIU:    s = this.printIInstr("sltiu");
            instr_tracer_pkg::INSTR_XORI:     s = this.printIInstr("xori");
            instr_tracer_pkg::INSTR_ORI:      s = this.printIInstr("ori");
            instr_tracer_pkg::INSTR_ANDI:     s = this.printIInstr("andi");
            instr_tracer_pkg::INSTR_SLLI:     s = this.printIuInstr("slli");
            instr_tracer_pkg::INSTR_SRLI:     s = this.printIuInstr("srli");
            instr_tracer_pkg::INSTR_SRAI:     s = this.printIuInstr("srai");
            // OPIMM32
            instr_tracer_pkg::INSTR_ADDIW:    s = this.printIInstr("addiw");
            instr_tracer_pkg::INSTR_SLLIW:    s = this.printIuInstr("slliw");
            instr_tracer_pkg::INSTR_SRLIW:    s = this.printIuInstr("srliw");
            instr_tracer_pkg::INSTR_SRAIW:    s = this.printIuInstr("sraiw");
            // OP
            instr_tracer_pkg::INSTR_ADD:      s = this.printRInstr("add");
            instr_tracer_pkg::INSTR_SUB:      s = this.printRInstr("sub");
            instr_tracer_pkg::INSTR_SLL:      s = this.printRInstr("sll");
            instr_tracer_pkg::INSTR_SLT:      s = this.printRInstr("slt");
            instr_tracer_pkg::INSTR_SLTU:     s = this.printRInstr("sltu");
            instr_tracer_pkg::INSTR_XOR:      s = this.printRInstr("xor");
            instr_tracer_pkg::INSTR_SRL:      s = this.printRInstr("srl");
            instr_tracer_pkg::INSTR_SRA:      s = this.printRInstr("sra");
            instr_tracer_pkg::INSTR_OR:       s = this.printRInstr("or");
            instr_tracer_pkg::INSTR_AND:      s = this.printRInstr("and");
            instr_tracer_pkg::INSTR_MUL:      s = this.printMulInstr(1'b0);
            // OP32
            instr_tracer_pkg::INSTR_ADDW:     s = this.printRInstr("addw");
            instr_tracer_pkg::INSTR_SUBW:     s = this.printRInstr("subw");
            instr_tracer_pkg::INSTR_SLLW:     s = this.printRInstr("sllw");
            instr_tracer_pkg::INSTR_SRLW:     s = this.printRInstr("srlw");
            instr_tracer_pkg::INSTR_SRAW:     s = this.printRInstr("sraw");
            instr_tracer_pkg::INSTR_MULW:     s = this.printMulInstr(1'b1);
            // FP
            instr_tracer_pkg::INSTR_FMADD:    s = this.printR4Instr("fmadd");
            instr_tracer_pkg::INSTR_FMSUB:    s = this.printR4Instr("fmsub");
            instr_tracer_pkg::INSTR_FNSMSUB:  s = this.printR4Instr("fnmsub");
            instr_tracer_pkg::INSTR_FNMADD:   s = this.printR4Instr("fnmadd");

            instr_tracer_pkg::INSTR_FADD:     s = this.printRFBCInstr("fadd", 1'b1);
            instr_tracer_pkg::INSTR_FSUB:     s = this.printRFBCInstr("fsub", 1'b1);
            instr_tracer_pkg::INSTR_FMUL:     s = this.printRFInstr("fmul", 1'b1);
            instr_tracer_pkg::INSTR_FDIV:     s = this.printRFInstr("fdiv", 1'b1);
            instr_tracer_pkg::INSTR_FSQRT:    s = this.printRFInstr1Op("fsqrt", 1'b1);
            instr_tracer_pkg::INSTR_FSGNJ:    s = this.printRFInstr("fsgnj", 1'b0);
            instr_tracer_pkg::INSTR_FSGNJN:   s = this.printRFInstr("fsgnjn", 1'b0);
            instr_tracer_pkg::INSTR_FSGNJX:   s = this.printRFInstr("fsgnjx", 1'b0);
            instr_tracer_pkg::INSTR_FMIN:     s = this.printRFInstr("fmin", 1'b0);
            instr_tracer_pkg::INSTR_FMAX:     s = this.printRFInstr("fmax", 1'b0);
            instr_tracer_pkg::INSTR_FLE:      s = this.printRFInstr("fle", 1'b0);
            instr_tracer_pkg::INSTR_FLT:      s = this.printRFInstr("flt", 1'b0);
            instr_tracer_pkg::INSTR_FEQ:      s = this.printRFInstr("feq", 1'b0);

            instr_tracer_pkg::INSTR_FCLASS:   s = this.printRFInstr1Op("fclass", 1'b0);

            instr_tracer_pkg::INSTR_FCVT_F2F,
            instr_tracer_pkg::INSTR_FMV_F2X,
            instr_tracer_pkg::INSTR_FMV_X2F,
            instr_tracer_pkg::INSTR_FCVT_F2I,
            instr_tracer_pkg::INSTR_FCVT_I2F: s = this.printFpSpecialInstr(); // these are a mess to do nicely
            // FENCE
            instr_tracer_pkg::INSTR_FENCE:    s = this.printMnemonic("fence");
            instr_tracer_pkg::INSTR_FENCEI:   s = this.printMnemonic("fence.i");
            // SYSTEM (CSR manipulation)
            instr_tracer_pkg::INSTR_CSRW:     s = this.printCSRInstr("csrw");
            instr_tracer_pkg::INSTR_CSRRW:    s = this.printCSRInstr("csrrw");
            instr_tracer_pkg::INSTR_CSRR:     s = this.printCSRInstr("csrr");
            instr_tracer_pkg::INSTR_CSRRS:    s = this.printCSRInstr("csrrs");
            instr_tracer_pkg::INSTR_CSRS:     s = this.printCSRInstr("csrs");
            instr_tracer_pkg::INSTR_CSRRC:    s = this.printCSRInstr("csrrc");
            instr_tracer_pkg::INSTR_CSRC:     s = this.printCSRInstr("csrc");

            instr_tracer_pkg::INSTR_CSRWI:    s = this.printCSRInstr("csrwi");
            instr_tracer_pkg::INSTR_CSRRWI:   s = this.printCSRInstr("csrrwi");
            instr_tracer_pkg::INSTR_CSRSI:    s = this.printCSRInstr("csrsi");
            instr_tracer_pkg::INSTR_CSRRSI:   s = this.printCSRInstr("csrrsi");
            instr_tracer_pkg::INSTR_CSRCI:    s = this.printCSRInstr("csrci");
            instr_tracer_pkg::INSTR_CSRRCI:   s = this.printCSRInstr("csrrci");
            // SYSTEM (others)
            instr_tracer_pkg::INSTR_ECALL:    s = this.printMnemonic("ecall");
            instr_tracer_pkg::INSTR_EBREAK:   s = this.printMnemonic("ebreak");
            instr_tracer_pkg::INSTR_MRET:     s = this.printMnemonic("mret");
            instr_tracer_pkg::INSTR_SRET:     s = this.printMnemonic("sret");
            instr_tracer_pkg::INSTR_DRET:     s = this.printMnemonic("dret");
            instr_tracer_pkg::INSTR_WFI:      s = this.printMnemonic("wfi");
            instr_tracer_pkg::INSTR_SFENCE:   s = this.printMnemonic("sfence.vma");
            // loads and stores
            instr_tracer_pkg::LB:             s = this.printLoadInstr("lb");
            instr_tracer_pkg::LH:             s = this.printLoadInstr("lh");
            instr_tracer_pkg::LW:             s = this.printLoadInstr("lw");
            instr_tracer_pkg::LD:             s = this.printLoadInstr("ld");
            instr_tracer_pkg::LBU:            s = this.printLoadInstr("lbu");
            instr_tracer_pkg::LHU:            s = this.printLoadInstr("lhu");
            instr_tracer_pkg::LWU:            s = this.printLoadInstr("lwu");
            instr_tracer_pkg::FLW:            s = this.printLoadInstr("flw");
            instr_tracer_pkg::FLD:            s = this.printLoadInstr("fld");
            instr_tracer_pkg::FLQ:            s = this.printLoadInstr("flq");
            instr_tracer_pkg::SB:             s = this.printStoreInstr("sb");
            instr_tracer_pkg::SH:             s = this.printStoreInstr("sh");
            instr_tracer_pkg::SW:             s = this.printStoreInstr("sw");
            instr_tracer_pkg::SD:             s = this.printStoreInstr("sd");
            instr_tracer_pkg::FSW:            s = this.printStoreInstr("fsw");
            instr_tracer_pkg::FSD:            s = this.printStoreInstr("fsd");
            instr_tracer_pkg::FSQ:            s = this.printStoreInstr("fsq");
            instr_tracer_pkg::INSTR_AMO:      s = this.printAMOInstr();
            // Compressed Instructions
            instr_tracer_pkg::C_FLD:          s = this.printLoadInstr("c.fld");
            instr_tracer_pkg::C_LW:           s = this.printLoadInstr("c.lw");
            instr_tracer_pkg::C_LD:           s = this.printLoadInstr("c.ld");
            instr_tracer_pkg::C_LWSP:         s = this.printLoadInstr("c.lwsp");
            instr_tracer_pkg::C_LDSP:         s = this.printLoadInstr("c.ldsp");
            instr_tracer_pkg::C_FLDSP:        s = this.printLoadInstr("c.fldsp");
            instr_tracer_pkg::C_SDSP:         s = this.printStoreInstr("c.sdsp");
            instr_tracer_pkg::C_SWSP:         s = this.printStoreInstr("c.swsp");
            instr_tracer_pkg::C_FSDSP:        s = this.printStoreInstr("c.fsdsp");
            instr_tracer_pkg::C_SW:           s = this.printStoreInstr("c.sw");
            instr_tracer_pkg::C_SD:           s = this.printStoreInstr("c.sd");
            instr_tracer_pkg::C_FSD:          s = this.printStoreInstr("c.fsd");
            instr_tracer_pkg::C_J:            s = this.printJump("c.j");
            instr_tracer_pkg::C_JR:           s = this.printJump("c.jr");
            instr_tracer_pkg::C_JALR:         s = this.printJump("c.jalr");
            instr_tracer_pkg::C_MV:           s = this.printRInstr("c.mv");
            instr_tracer_pkg::C_ADD:          s = this.printRInstr("c.add");
            instr_tracer_pkg::C_BEQZ:         s = this.printSBInstr("c.beqz");
            instr_tracer_pkg::C_BNEZ:         s = this.printSBInstr("c.bnez");
            instr_tracer_pkg::C_LUI:          s = this.printUInstr("c.lui");
            instr_tracer_pkg::C_LI:           s = this.printIInstr("c.li");
            instr_tracer_pkg::C_ADDI:         s = this.printIInstr("c.addi");
            instr_tracer_pkg::C_ADDI16SP:     s = this.printIInstr("c.addi16sp");
            instr_tracer_pkg::C_ADDIW:        s = this.printIInstr("c.addiw");
            instr_tracer_pkg::C_SLLI:         s = this.printIInstr("c.slli");
            instr_tracer_pkg::C_SRLI:         s = this.printIInstr("c.srli");
            instr_tracer_pkg::C_SRAI:         s = this.printIInstr("c.srai");
            instr_tracer_pkg::C_ANDI:         s = this.printIInstr("c.andi");
            instr_tracer_pkg::C_ADDI4SPN:     s = this.printIInstr("c.addi4spn");
            instr_tracer_pkg::C_SUB:          s = this.printRInstr("c.sub");
            instr_tracer_pkg::C_XOR:          s = this.printRInstr("c.xor");
            instr_tracer_pkg::C_OR:           s = this.printRInstr("c.or");
            instr_tracer_pkg::C_AND:          s = this.printRInstr("c.and");
            instr_tracer_pkg::C_SUBW:         s = this.printRInstr("c.subw");
            instr_tracer_pkg::C_ADDW:         s = this.printRInstr("c.addw");
            instr_tracer_pkg::C_NOP:          s = this.printMnemonic("c.nop");
            instr_tracer_pkg::C_EBREAK:       s = this.printMnemonic("c.ebreak");
            default:                          s = this.printMnemonic("INVALID");
        endcase

        s = $sformatf("%8dns %8d %s %h %h %h %-36s", simtime,
                                             cycle,
                                             priv_lvl,
                                             sbe.pc,
                                             bp.is_mispredict & bp.valid,
                                             instr,
                                             s);

        // s = $sformatf("%s %h %h %-36s",
        //                                      priv_lvl,
        //                                      sbe.pc,
        //                                      instr,
        //                                      s);

        adjustResultRegKinds();

        foreach (result_regs[i]) begin
            if (result_fpr[i])
                s = $sformatf("%s %-4s:%16x", s, fpRegAddrToStr(result_regs[i]), this.result);
            else if (result_regs[i] != 0)
                s = $sformatf("%s %-4s:%16x", s, regAddrToStr(result_regs[i]), this.result);
        end

        foreach (read_regs[i]) begin
            if (read_fpr[i])
                s = $sformatf("%s %-4s:%16x", s, fpRegAddrToStr(read_regs[i]), fp_reg_file[read_regs[i]]);
            else if (read_regs[i] != 0)
                s = $sformatf("%s %-4s:%16x", s, regAddrToStr(read_regs[i]), gp_reg_file[read_regs[i]]);
        end

        case (instr) inside
            // check of the instruction was a load or store
            instr_tracer_pkg::C_SDSP,
            instr_tracer_pkg::C_SWSP,
            instr_tracer_pkg::C_FSWSP,
            instr_tracer_pkg::C_FSDSP,
            instr_tracer_pkg::C_SW,
            instr_tracer_pkg::C_SD,
            instr_tracer_pkg::C_FSW,
            instr_tracer_pkg::C_FSD,
            instr_tracer_pkg::SB,
            instr_tracer_pkg::SH,
            instr_tracer_pkg::SW,
            instr_tracer_pkg::SD,
            instr_tracer_pkg::FSW,
            instr_tracer_pkg::FSD,
            instr_tracer_pkg::FSQ: begin
                logic [CVA6Cfg.VLEN-1:0] vaddress = gp_reg_file[read_regs[1]] + this.imm;
                s = $sformatf("%s VA: %x PA: %x", s, vaddress, this.paddr);
            end

            instr_tracer_pkg::C_FLD,
            instr_tracer_pkg::C_FLW,
            instr_tracer_pkg::C_LW,
            instr_tracer_pkg::C_LD,
            instr_tracer_pkg::C_LWSP,
            instr_tracer_pkg::C_LDSP,
            instr_tracer_pkg::C_FLWSP,
            instr_tracer_pkg::C_FLDSP,
            instr_tracer_pkg::LB,
            instr_tracer_pkg::LH,
            instr_tracer_pkg::LW,
            instr_tracer_pkg::LD,
            instr_tracer_pkg::LBU,
            instr_tracer_pkg::LHU,
            instr_tracer_pkg::LWU,
            instr_tracer_pkg::FLW,
            instr_tracer_pkg::FLD,
            instr_tracer_pkg::FLQ: begin
                logic [CVA6Cfg.VLEN-1:0] vaddress = gp_reg_file[read_regs[0]] + this.imm;
                s = $sformatf("%s VA: %x PA: %x", s, vaddress, this.paddr);
            end
        endcase
        return s;
    endfunction : printInstr

    // Return the current privilege level as a string
    function string getPrivLevel(input riscv::priv_lvl_t priv_lvl);
        case (priv_lvl)
            riscv::PRIV_LVL_M: return "M";
            riscv::PRIV_LVL_S: return "S";
            riscv::PRIV_LVL_U: return "U";
        endcase
    endfunction : getPrivLevel

    function string printMnemonic(input string mnemonic);
        return mnemonic;
    endfunction // printMnemonic

    function string printRInstr(input string mnemonic);

        result_regs.push_back(rd);
        result_fpr.push_back(1'b0);
        read_regs.push_back(rs1);
        read_fpr.push_back(1'b0);
        read_regs.push_back(rs2);
        read_fpr.push_back(1'b0);

        return $sformatf("%-12s %4s, %s, %s", mnemonic, regAddrToStr(rd), regAddrToStr(rs1), regAddrToStr(rs2));
    endfunction // printRInstr

    function string printRFBCInstr(input string mnemonic, input bit use_rnd);

        logic dest_fp = effectiveDestIsFp();
        result_regs.push_back(rd);
        result_fpr.push_back(dest_fp);
        read_regs.push_back(rs2);
        read_fpr.push_back(ariane_pkg::is_rs2_fpr(sbe.op));
        read_regs.push_back(sbe.result[4:0]);
        read_fpr.push_back(ariane_pkg::is_imm_fpr(sbe.op));

        if (use_rnd && instr[14:12]!=3'b111)
            return $sformatf("%-12s %4s, %s, %s, %s", $sformatf("%s.%s",mnemonic, fpFmtToStr(instr[26:25])), dest_fp?fpRegAddrToStr(rd):regAddrToStr(rd), ariane_pkg::is_rs2_fpr(sbe.op)?fpRegAddrToStr(rs2):regAddrToStr(rs2), ariane_pkg::is_imm_fpr(sbe.op)?fpRegAddrToStr(sbe.result[4:0]):regAddrToStr(sbe.result[4:0]), fpRmToStr(instr[14:12]));
        else
            return $sformatf("%-12s %4s, %s, %s", $sformatf("%s.%s",mnemonic, fpFmtToStr(instr[26:25])), dest_fp?fpRegAddrToStr(rd):regAddrToStr(rd), ariane_pkg::is_rs2_fpr(sbe.op)?fpRegAddrToStr(rs2):regAddrToStr(rs2), ariane_pkg::is_imm_fpr(sbe.op)?fpRegAddrToStr(sbe.result[4:0]):regAddrToStr(sbe.result[4:0]));
    endfunction // printRFInstr

    function string printRFInstr(input string mnemonic, input bit use_rnd);

        logic dest_fp = effectiveDestIsFp();
        result_regs.push_back(rd);
        result_fpr.push_back(dest_fp);
        read_regs.push_back(rs1);
        read_fpr.push_back(ariane_pkg::is_rs1_fpr(sbe.op));
        read_regs.push_back(rs2);
        read_fpr.push_back(ariane_pkg::is_rs2_fpr(sbe.op));

        if (use_rnd && instr[14:12]!=3'b111)
            return $sformatf("%-12s %4s, %s, %s, %s", $sformatf("%s.%s",mnemonic, fpFmtToStr(instr[26:25])), dest_fp?fpRegAddrToStr(rd):regAddrToStr(rd), ariane_pkg::is_rs1_fpr(sbe.op)?fpRegAddrToStr(rs1):regAddrToStr(rs1), ariane_pkg::is_rs2_fpr(sbe.op)?fpRegAddrToStr(rs2):regAddrToStr(rs2), fpRmToStr(instr[14:12]));
        else
            return $sformatf("%-12s %4s, %s, %s", $sformatf("%s.%s",mnemonic, fpFmtToStr(instr[26:25])), dest_fp?fpRegAddrToStr(rd):regAddrToStr(rd), ariane_pkg::is_rs1_fpr(sbe.op)?fpRegAddrToStr(rs1):regAddrToStr(rs1), ariane_pkg::is_rs2_fpr(sbe.op)?fpRegAddrToStr(rs2):regAddrToStr(rs2));
    endfunction // printRFInstr

    function string printRFInstr1Op(input string mnemonic, input bit use_rnd);

        logic dest_fp = effectiveDestIsFp();
        result_regs.push_back(rd);
        result_fpr.push_back(dest_fp);
        read_regs.push_back(rs1);
        read_fpr.push_back(ariane_pkg::is_rs1_fpr(sbe.op));

        if (use_rnd && instr[14:12]!=3'b111)
            return $sformatf("%-12s %4s, %s, %s", $sformatf("%s.%s",mnemonic, fpFmtToStr(instr[26:25])), dest_fp?fpRegAddrToStr(rd):regAddrToStr(rd), ariane_pkg::is_rs1_fpr(sbe.op)?fpRegAddrToStr(rs1):regAddrToStr(rs1), fpRmToStr(instr[14:12]));
        else
            return $sformatf("%-12s %4s, %s", $sformatf("%s.%s",mnemonic, fpFmtToStr(instr[26:25])), dest_fp?fpRegAddrToStr(rd):regAddrToStr(rd), ariane_pkg::is_rs1_fpr(sbe.op)?fpRegAddrToStr(rs1):regAddrToStr(rs1));
    endfunction // printRFInstr1Op

    function string printR4Instr(input string mnemonic);

        result_regs.push_back(rd);
        result_fpr.push_back(1'b1);
        read_regs.push_back(rs1);
        read_fpr.push_back(1'b1);
        read_regs.push_back(rs2);
        read_fpr.push_back(1'b1);
        read_regs.push_back(rs3);
        read_fpr.push_back(1'b1);

        return $sformatf("%-12s %4s, %s, %s, %s, %s", $sformatf("%s.%s",mnemonic, fpFmtToStr(instr[26:25])), fpRegAddrToStr(rd), fpRegAddrToStr(rs1), fpRegAddrToStr(rs2), fpRegAddrToStr(instr[31:27]), fpRmToStr(instr[14:12]));
    endfunction // printR4Instr

    function string printFpSpecialInstr();

        logic dest_fp = effectiveDestIsFp();
        result_regs.push_back(rd);
        result_fpr.push_back(dest_fp);
        read_regs.push_back(rs1);
        read_fpr.push_back(ariane_pkg::is_rs1_fpr(sbe.op));

        case (sbe.op)
            instr_tracer_pkg::INSTR_FCVT_F2F : return $sformatf("%-12s %4s, %s, %s", $sformatf("fcvt.%s.%s", fpFmtToStr(instr[26:25]), fpFmtToStr(instr[21:20])), fpRegAddrToStr(rd), fpRegAddrToStr(rs1), fpRmToStr(instr[14:12]));
            instr_tracer_pkg::INSTR_FCVT_F2I : return $sformatf("%-12s %4s, %s, %s", $sformatf("fcvt.%s.%s", intFmtToStr(instr[21:20]), fpFmtToStr(instr[26:25])), regAddrToStr(rd), fpRegAddrToStr(rs1), fpRmToStr(instr[14:12]));
            instr_tracer_pkg::INSTR_FCVT_I2F : return $sformatf("%-12s %4s, %s, %s", $sformatf("fcvt.%s.%s", fpFmtToStr(instr[26:25]), intFmtToStr(instr[21:20])), fpRegAddrToStr(rd), regAddrToStr(rs1), fpRmToStr(instr[14:12]));
            instr_tracer_pkg::INSTR_FMV_F2X  : return $sformatf("%-12s %4s, %s", $sformatf("fmv.x.%s", fmvFpFmtToStr(instr[26:25])), regAddrToStr(rd), fpRegAddrToStr(rs1));
            instr_tracer_pkg::INSTR_FMV_X2F  : return $sformatf("%-12s %4s, %s", $sformatf("fmv.%s.x", fmvFpFmtToStr(instr[26:25])), fpRegAddrToStr(rd), regAddrToStr(rs1));
        endcase
    endfunction

    function string printIInstr(input string mnemonic);

        result_regs.push_back(rd);
        result_fpr.push_back(1'b0);
        read_regs.push_back(rs1);
        read_fpr.push_back(1'b0);

        if (rs1 == 0)
            return $sformatf("%-12s %4s, %0d", mnemonic, regAddrToStr(rd), $signed(sbe.result));

        return $sformatf("%-12s %4s, %s, %0d", mnemonic, regAddrToStr(rd), regAddrToStr(rs1), $signed(sbe.result));
    endfunction // printIInstr

    function string printIuInstr(input string mnemonic);

        result_regs.push_back(rd);
        result_fpr.push_back(1'b0);
        read_regs.push_back(rs1);
        read_fpr.push_back(1'b0);

        return $sformatf("%-12s %4s, %s, 0x%0x", mnemonic, regAddrToStr(rd), regAddrToStr(rs1), sbe.result);
    endfunction // printIuInstr

    function string printSBInstr(input string mnemonic);

        read_regs.push_back(rs1);
        read_fpr.push_back(1'b0);
        read_regs.push_back(rs2);
        read_fpr.push_back(1'b0);

        if (rs2 == 0) begin
            return $sformatf("%-12s %4s, %s", mnemonic, regAddrToStr(rs1), printPCexpr(sbe.result));
        end else begin
            return $sformatf("%-12s %4s, %s, %s", mnemonic, regAddrToStr(rs1), regAddrToStr(rs2), printPCexpr(sbe.result));
        end
    endfunction // printIuInstr

    function string printUInstr(input string mnemonic);

        result_regs.push_back(rd);
        result_fpr.push_back(1'b0);

        return $sformatf("%-12s %4s, 0x%0h", mnemonic, regAddrToStr(rd), sbe.result[31:12]);
    endfunction // printUInstr

    function string printJump(input string mnemonic);
        case (instr[6:0])
            riscv::OpcodeJalr: begin
                // is this a return?
                if (rd == 'b0 && (rs1 == 'h1 || rs1 == 'h5)) return this.printMnemonic("ret");
            end
            riscv::OpcodeJal: begin
                if (rd == 'b0) return this.printUJInstr("j");
            end
        endcase
        return this.printIInstr(mnemonic);
    endfunction

    function string printUJInstr(input string mnemonic);

        result_regs.push_back(rd);
        result_fpr.push_back(1'b0);
        // jump instruction
        if (rd == 0)
            return $sformatf("%-12s   %s", mnemonic, printPCexpr(sbe.result));
        else
            return $sformatf("%-12s %4s, %s", mnemonic, regAddrToStr(rd), printPCexpr(sbe.result));
    endfunction // printUJInstr

    function string printCSRInstr(input string mnemonic);

        result_regs.push_back(rd);
        result_fpr.push_back(1'b0);
        if (instr[14] == 0) begin
        read_regs.push_back(rs1);
        read_fpr.push_back(1'b0);
            if (rd != 0 && rs1 != 0) begin
                  return $sformatf("%-12s %4s, %s, %s", mnemonic, regAddrToStr(rd), regAddrToStr(rs1), csrAddrToStr(sbe.result[11:0]));
            // don't display instructions which write to zero
            end else if (rd == 0) begin
                  return $sformatf("%-12s %4s, %s", mnemonic, regAddrToStr(rs1), csrAddrToStr(sbe.result[11:0]));
            end else if (rs1 == 0) begin
                return $sformatf("%-12s %4s, %s", mnemonic, regAddrToStr(rd), csrAddrToStr(sbe.result[11:0]));
            end
        end else begin
            if (rd != 0 && rs1 != 0) begin
                  return $sformatf("%-12s %4s, %d, %s", mnemonic, regAddrToStr(rd), $unsigned(rs1), csrAddrToStr(sbe.result[11:0]));
            // don't display instructions which write to zero
            end else if (rd == 0) begin
                  return $sformatf("%-14s %2d, %s", mnemonic, $unsigned(rs1), csrAddrToStr(sbe.result[11:0]));
            end else if (rs1 == 0) begin
                return $sformatf("%-12s %4s, %s", mnemonic, regAddrToStr(rd), csrAddrToStr(sbe.result[11:0]));
            end
        end
    endfunction // printCSRInstr

    function string printLoadInstr(input string mnemonic);
        logic dest_fp = effectiveDestIsFp();
        result_regs.push_back(rd);
        result_fpr.push_back(dest_fp);
        read_regs.push_back(rs1);
        read_fpr.push_back(1'b0);
        // save the immediate for calculating the virtual address
        this.imm = sbe.result;

        if (instr[6:0] == riscv::OpcodeLoadFp)
            return $sformatf("%-12s %4s, %0d(%s)", mnemonic, fpRegAddrToStr(rd), $signed(sbe.result), regAddrToStr(rs1));
        else
            return $sformatf("%-12s %4s, %0d(%s)", mnemonic, regAddrToStr(rd), $signed(sbe.result), regAddrToStr(rs1));
    endfunction

    function string printStoreInstr(input string mnemonic);
        read_regs.push_back(rs2);
        read_fpr.push_back(ariane_pkg::is_rs2_fpr(sbe.op));
        read_regs.push_back(rs1);
        read_fpr.push_back(1'b0);
        // save the immediate for calculating the virtual address
        this.imm = sbe.result;

        if (instr[6:0] == riscv::OpcodeStoreFp)
            return $sformatf("%-12s %4s, %0d(%s)", mnemonic, fpRegAddrToStr(rs2), $signed(sbe.result), regAddrToStr(rs1));
        else
            return $sformatf("%-12s %4s, %0d(%s)", mnemonic, regAddrToStr(rs2), $signed(sbe.result), regAddrToStr(rs1));
    endfunction // printSInstr

    function string printAMOInstr();
        string mnemonic;
        // words
        if (instr[14:12] == 3'h2) begin
            case (instr[31:27])
                5'h0:  mnemonic = "amoadd.w";
                5'h1:  mnemonic = "amoswap.w";
                5'h2:  mnemonic = "lr.w";
                5'h3:  mnemonic = "sc.w";
                5'h4:  mnemonic = "amoxor.w";
                5'h8:  mnemonic = "amoor.w";
                5'hC:  mnemonic = "amoand.w";
                5'h10: mnemonic = "amomin.w";
                5'h14: mnemonic = "amomax.w";
                5'h18: mnemonic = "amominu.w";
                5'h1C: mnemonic = "amomax.w";
                default: return printMnemonic("INVALID");
            endcase
        // doubles
        end else if (instr[14:12] == 3'h3) begin
            case (instr[31:27])
                5'h0:  mnemonic = "amoadd.d";
                5'h1:  mnemonic = "amoswap.d";
                5'h2:  mnemonic = "lr.d";
                5'h3:  mnemonic = "sc.d";
                5'h4:  mnemonic = "amoxor.d";
                5'h8:  mnemonic = "amoor.d";
                5'hC:  mnemonic = "amoand.d";
                5'h10: mnemonic = "amomin.d";
                5'h14: mnemonic = "amomax.d";
                5'h18: mnemonic = "amominu.d";
                5'h1C: mnemonic = "amomax.d";
                default: return printMnemonic("INVALID");
            endcase
        end else return printMnemonic("INVALID");

        result_regs.push_back(sbe.rd);
        read_regs.push_back(sbe.rs2);
        read_regs.push_back(sbe.rs1);
        // save the immediate for calculating the virtual address
        this.imm = 0;

        return $sformatf("%-16s %s, %s,(%s)", mnemonic, regAddrToStr(sbe.rd), regAddrToStr(sbe.rs2), regAddrToStr(sbe.rs1));
    endfunction

    function string printMulInstr(logic is_op32);
        string s = "";
        case (this.instr[14:12])
            3'b000: s = "mul";
            3'b001: s = "mulh";
            3'b010: s = "mulhsu";
            3'b011: s = "mulhu";
            3'b100: s = "div";
            3'b101: s = "divu";
            3'b110: s = "rem";
            3'b111: s = "remu";
        endcase
        // if it is a 32 bit instruction concatenate a w on it
        if (is_op32) s = {s, "w"};
        return this.printRInstr(s);
    endfunction
  endclass
`endif