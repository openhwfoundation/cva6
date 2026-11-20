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
// Author: Stefan Mach, ETH Zurich
// Date: 12.04.2018
// Description: Wrapper for the floating-point unit


module fpu_wrap
  import ariane_pkg::*;
#(
    parameter config_pkg::cva6_cfg_t CVA6Cfg = config_pkg::cva6_cfg_empty,
    parameter type exception_t = logic,
    parameter type fu_data_t = logic
) (
    input  logic     clk_i,
    input  logic     rst_ni,
    input  logic     flush_i,
    input  logic     fpu_valid_i,
    output logic     fpu_ready_o,
    input  fu_data_t fu_data_i,

    input  logic       [                      1:0] fpu_fmt_i,
    input  logic       [                      2:0] fpu_rm_i,
    input  logic       [                      2:0] fpu_frm_i,
    input  logic       [                      6:0] fpu_prec_i,
    output logic       [CVA6Cfg.TRANS_ID_BITS-1:0] fpu_trans_id_o,
    output logic       [         CVA6Cfg.FLen-1:0] result_o,
    output logic                                   fpu_valid_o,
    output exception_t                             fpu_exception_o,
    output logic                                   fpu_early_valid_o
);

  // this is a workaround
  // otherwise compilation might issue an error if FLEN=0
  enum logic {
    READY,
    STALL
  }
      state_q, state_d;
  if (CVA6Cfg.FpPresent) begin : fpu_gen
    logic [CVA6Cfg.FLen-1:0] operand_a_i;
    logic [CVA6Cfg.FLen-1:0] operand_b_i;
    logic [CVA6Cfg.FLen-1:0] operand_c_i;
    assign operand_a_i = fu_data_i.operand_a[CVA6Cfg.FLen-1:0];
    assign operand_b_i = fu_data_i.operand_b[CVA6Cfg.FLen-1:0];
    assign operand_c_i = fu_data_i.imm[CVA6Cfg.FLen-1:0];

    //-----------------------------------
    // FPnew config from FPnew package
    //-----------------------------------
    localparam OPBITS = fpnew_pkg::OP_BITS;
    localparam FMTBITS = $clog2(fpnew_pkg::NUM_FP_FORMATS);
    localparam IFMTBITS = $clog2(fpnew_pkg::NUM_INT_FORMATS);

    // Features (enabled formats, vectors etc.)
    localparam fpnew_pkg::fpu_features_t FPU_FEATURES = '{
        Width: unsigned'(CVA6Cfg.FLen),  // parameterized using CVA6Cfg.FLen
        EnableVectors: CVA6Cfg.XFVec,
        EnableNanBox: 1'b1,
        FpFmtMask: {CVA6Cfg.RVF, CVA6Cfg.RVD, CVA6Cfg.XF16, CVA6Cfg.XF8, CVA6Cfg.XF16ALT},
        IntFmtMask: {
          CVA6Cfg.XFVec && CVA6Cfg.XF8,
          CVA6Cfg.XFVec && (CVA6Cfg.XF16 || CVA6Cfg.XF16ALT),
          1'b1,
          1'b1
        }
    };

    // Division and square root unit. The C910 one (THMULTI) works on 64-bit
    // operands and checks the NaN-boxing of a single-precision operand in their
    // upper half, which fpnew fills with zeros when FLEN is 32: it would take
    // every operand for a NaN. An FPU with single precision only uses the E906
    // unit (TH32), which supports exactly that.
    localparam fpnew_pkg::divsqrt_unit_t DIVSQRT_SEL =
        (CVA6Cfg.RVF && !CVA6Cfg.RVD && !CVA6Cfg.XF16 && !CVA6Cfg.XF16ALT && !CVA6Cfg.XF8) ?
        fpnew_pkg::TH32 : fpnew_pkg::THMULTI;

    // Implementation (number of registers etc)
    localparam fpnew_pkg::fpu_implementation_t FPU_IMPLEMENTATION = '{
        PipeRegs: '{  // FP32, FP64, FP16, FP8, FP16alt
            '{
                unsigned'(LAT_COMP_FP32),
                unsigned'(LAT_COMP_FP64),
                unsigned'(LAT_COMP_FP16),
                unsigned'(LAT_COMP_FP8),
                unsigned'(LAT_COMP_FP16ALT)
            },  // ADDMUL
            '{default: unsigned'(LAT_DIVSQRT)},  // DIVSQRT
            '{default: unsigned'(LAT_NONCOMP)},  // NONCOMP
            '{default: unsigned'(LAT_CONV)}
        },  // CONV
        UnitTypes: '{
            '{default: fpnew_pkg::PARALLEL},  // ADDMUL
            '{default: fpnew_pkg::MERGED},  // DIVSQRT
            '{default: fpnew_pkg::PARALLEL},  // NONCOMP
            '{default: fpnew_pkg::MERGED}
        },  // CONV
        PipeConfig: fpnew_pkg::DISTRIBUTED
    };

    //-------------------------------------------------
    // Inputs to the FPU and protocol inversion buffer
    //-------------------------------------------------
    logic [CVA6Cfg.FLen-1:0] operand_a_d, operand_a_q, operand_a;
    logic [CVA6Cfg.FLen-1:0] operand_b_d, operand_b_q, operand_b;
    logic [CVA6Cfg.FLen-1:0] operand_c_d, operand_c_q, operand_c;
    logic [OPBITS-1:0] fpu_op_d, fpu_op_q, fpu_op;
    logic fpu_op_mod_d, fpu_op_mod_q, fpu_op_mod;
    logic [FMTBITS-1:0] fpu_srcfmt_d, fpu_srcfmt_q, fpu_srcfmt;
    logic [FMTBITS-1:0] fpu_dstfmt_d, fpu_dstfmt_q, fpu_dstfmt;
    logic [IFMTBITS-1:0] fpu_ifmt_d, fpu_ifmt_q, fpu_ifmt;
    logic [2:0] fpu_rm_d, fpu_rm_q, fpu_rm;
    logic fpu_vec_op_d, fpu_vec_op_q, fpu_vec_op;

    logic [CVA6Cfg.TRANS_ID_BITS-1:0] fpu_tag_d, fpu_tag_q, fpu_tag;

    logic fpu_in_ready, fpu_in_valid;
    logic fpu_out_ready, fpu_out_valid;

    logic [4:0] fpu_status;

    // FSM to handle protocol inversion
    logic hold_inputs;
    logic use_hold;

    //-----------------------------
    // Translate inputs
    //-----------------------------

    always_comb begin : input_translation

      automatic logic vec_replication;  // control honoring of replication flag
      automatic logic replicate_c;  // replicate operand C instead of B (for ADD/SUB)
      automatic logic check_ah;  // Decide for AH from RM field encoding

      // Default Values
      operand_a_d     = operand_a_i;
      operand_b_d     = operand_b_i;  // immediates come through this port unless used as operand
      operand_c_d     = operand_c_i;  // immediates come through this port unless used as operand
      fpu_op_d        = fpnew_pkg::SGNJ;  // sign injection by default
      fpu_op_mod_d    = 1'b0;
      fpu_dstfmt_d    = fpnew_pkg::FP32;
      fpu_ifmt_d      = fpnew_pkg::INT32;
      fpu_rm_d        = fpu_rm_i;
      fpu_vec_op_d    = fu_data_i.fu == FPU_VEC;
      fpu_tag_d       = fu_data_i.trans_id;
      vec_replication = fpu_rm_i[0];  // replication bit is sent via rm field
      replicate_c     = 1'b0;
      check_ah        = 1'b0;  // whether set scalar AH encoding from MSB of rm_i

      // Scalar Rounding Modes - some ops encode inside RM but use smaller range
      if (!(fpu_rm_i inside {[3'b000 : 3'b100]})) fpu_rm_d = fpu_frm_i;

      // Vectorial ops always consult FRM
      if (fpu_vec_op_d) fpu_rm_d = fpu_frm_i;

      // Formats
      unique case (fpu_fmt_i)
        // FP32
        2'b00:   fpu_dstfmt_d = fpnew_pkg::FP32;
        // FP64 or FP16ALT (vectorial)
        2'b01:   fpu_dstfmt_d = fpu_vec_op_d ? fpnew_pkg::FP16ALT : fpnew_pkg::FP64;
        // FP16 or FP16ALT (scalar)
        2'b10: begin
          if (!fpu_vec_op_d && fpu_rm_i == 3'b101) fpu_dstfmt_d = fpnew_pkg::FP16ALT;
          else fpu_dstfmt_d = fpnew_pkg::FP16;
        end
        // FP8
        default: fpu_dstfmt_d = fpnew_pkg::FP8;
      endcase

      // By default, set src=dst
      fpu_srcfmt_d = fpu_dstfmt_d;

      // Operations (this can modify the rounding mode field and format!)
      unique case (fu_data_i.operation)
        // Addition
        FADD: begin
          fpu_op_d    = fpnew_pkg::ADD;
          replicate_c = 1'b1; // second operand is in C
        end
        // Subtraction is modified ADD
        FSUB: begin
          fpu_op_d     = fpnew_pkg::ADD;
          fpu_op_mod_d = 1'b1;
          replicate_c  = 1'b1;  // second operand is in C
        end
        // Multiplication
        FMUL:    fpu_op_d = fpnew_pkg::MUL;
        // Division
        FDIV:    fpu_op_d = fpnew_pkg::DIV;
        // Min/Max - OP is encoded in rm (000-001)
        FMIN_MAX: begin
          fpu_op_d = fpnew_pkg::MINMAX;
          fpu_rm_d = {1'b0, fpu_rm_i[1:0]};  // mask out AH encoding bit
          check_ah = 1'b1;  // AH has RM MSB encoding
        end
        // Square Root
        FSQRT:   fpu_op_d = fpnew_pkg::SQRT;
        // Fused Multiply Add
        FMADD:   fpu_op_d = fpnew_pkg::FMADD;
        // Fused Multiply Subtract is modified FMADD
        FMSUB: begin
          fpu_op_d     = fpnew_pkg::FMADD;
          fpu_op_mod_d = 1'b1;
        end
        // Fused Negated Multiply Subtract
        FNMSUB:  fpu_op_d = fpnew_pkg::FNMSUB;
        // Fused Negated Multiply Add is modified FNMSUB
        FNMADD: begin
          fpu_op_d     = fpnew_pkg::FNMSUB;
          fpu_op_mod_d = 1'b1;
        end
        // Float to Int Cast - Op encoded in lowest two imm bits or rm
        FCVT_F2I: begin
          fpu_op_d = fpnew_pkg::F2I;
          // Vectorial Ops encoded in R bit
          if (fpu_vec_op_d) begin
            fpu_op_mod_d    = fpu_rm_i[0];
            vec_replication = 1'b0;  // no replication, R bit used for op
            unique case (fpu_fmt_i)
              2'b00: fpu_ifmt_d = fpnew_pkg::INT32;
              2'b01, 2'b10: fpu_ifmt_d = fpnew_pkg::INT16;
              2'b11: fpu_ifmt_d = fpnew_pkg::INT8;
            endcase
            // Scalar casts encoded in imm
          end else begin
            fpu_op_mod_d = operand_c_i[0];
            if (operand_c_i[1]) fpu_ifmt_d = fpnew_pkg::INT64;
            else fpu_ifmt_d = fpnew_pkg::INT32;
          end
        end
        // Int to Float Cast - Op encoded in lowest two imm bits or rm
        FCVT_I2F: begin
          fpu_op_d = fpnew_pkg::I2F;
          // Vectorial Ops encoded in R bit
          if (fpu_vec_op_d) begin
            fpu_op_mod_d    = fpu_rm_i[0];
            vec_replication = 1'b0;  // no replication, R bit used for op
            unique case (fpu_fmt_i)
              2'b00: fpu_ifmt_d = fpnew_pkg::INT32;
              2'b01, 2'b10: fpu_ifmt_d = fpnew_pkg::INT16;
              2'b11: fpu_ifmt_d = fpnew_pkg::INT8;
            endcase
            // Scalar casts encoded in imm
          end else begin
            fpu_op_mod_d = operand_c_i[0];
            if (operand_c_i[1]) fpu_ifmt_d = fpnew_pkg::INT64;
            else fpu_ifmt_d = fpnew_pkg::INT32;
          end
        end
        // Float to Float Cast - Source format encoded in lowest two/three imm bits
        FCVT_F2F: begin
          fpu_op_d = fpnew_pkg::F2F;
          // Vectorial ops encoded in lowest two imm bits
          if (fpu_vec_op_d) begin
            vec_replication = 1'b0;  // no replication for casts (not needed)
            unique case (operand_c_i[1:0])
              2'b00: fpu_srcfmt_d = fpnew_pkg::FP32;
              2'b01: fpu_srcfmt_d = fpnew_pkg::FP16ALT;
              2'b10: fpu_srcfmt_d = fpnew_pkg::FP16;
              2'b11: fpu_srcfmt_d = fpnew_pkg::FP8;
            endcase
            // Scalar ops encoded in lowest three imm bits
          end else begin
            unique case (operand_c_i[2:0])
              3'b000:  fpu_srcfmt_d = fpnew_pkg::FP32;
              3'b001:  fpu_srcfmt_d = fpnew_pkg::FP64;
              3'b010:  fpu_srcfmt_d = fpnew_pkg::FP16;
              3'b110:  fpu_srcfmt_d = fpnew_pkg::FP16ALT;
              3'b011:  fpu_srcfmt_d = fpnew_pkg::FP8;
              default: ;  // Do nothing
            endcase
          end
        end
        // Scalar Sign Injection - op encoded in rm (000-010)
        FSGNJ: begin
          fpu_op_d = fpnew_pkg::SGNJ;
          fpu_rm_d = {1'b0, fpu_rm_i[1:0]};  // mask out AH encoding bit
          check_ah = 1'b1;  // AH has RM MSB encoding
        end
        // Move from FPR to GPR - mapped to SGNJ-passthrough since no recoding
        FMV_F2X: begin
          fpu_op_d        = fpnew_pkg::SGNJ;
          fpu_rm_d        = 3'b011;  // passthrough without checking nan-box
          fpu_op_mod_d    = 1'b1;  // no NaN-Boxing
          check_ah        = 1'b1;  // AH has RM MSB encoding
          vec_replication = 1'b0;  // no replication, we set second operand
        end
        // Move from GPR to FPR - mapped to NOP since no recoding
        FMV_X2F: begin
          fpu_op_d        = fpnew_pkg::SGNJ;
          fpu_rm_d        = 3'b011;  // passthrough without checking nan-box
          check_ah        = 1'b1;  // AH has RM MSB encoding
          vec_replication = 1'b0;  // no replication, we set second operand
        end
        // Scalar Comparisons - op encoded in rm (000-010)
        FCMP: begin
          fpu_op_d = fpnew_pkg::CMP;
          fpu_rm_d = {1'b0, fpu_rm_i[1:0]};  // mask out AH encoding bit
          check_ah = 1'b1;  // AH has RM MSB encoding
        end
        // Classification
        FCLASS: begin
          fpu_op_d = fpnew_pkg::CLASSIFY;
          fpu_rm_d = {
            1'b0, fpu_rm_i[1:0]
          };  // mask out AH encoding bit - CLASS doesn't care anyways
          check_ah = 1'b1;  // AH has RM MSB encoding
        end
        // Vectorial Minimum - set up scalar encoding in rm
        VFMIN: begin
          fpu_op_d = fpnew_pkg::MINMAX;
          fpu_rm_d = 3'b000;  // min
        end
        // Vectorial Maximum - set up scalar encoding in rm
        VFMAX: begin
          fpu_op_d = fpnew_pkg::MINMAX;
          fpu_rm_d = 3'b001;  // max
        end
        // Vectorial Sign Injection - set up scalar encoding in rm
        VFSGNJ: begin
          fpu_op_d = fpnew_pkg::SGNJ;
          fpu_rm_d = 3'b000;  // sgnj
        end
        // Vectorial Negated Sign Injection - set up scalar encoding in rm
        VFSGNJN: begin
          fpu_op_d = fpnew_pkg::SGNJ;
          fpu_rm_d = 3'b001;  // sgnjn
        end
        // Vectorial Xored Sign Injection - set up scalar encoding in rm
        VFSGNJX: begin
          fpu_op_d = fpnew_pkg::SGNJ;
          fpu_rm_d = 3'b010;  // sgnjx
        end
        // Vectorial Equals - set up scalar encoding in rm
        VFEQ: begin
          fpu_op_d = fpnew_pkg::CMP;
          fpu_rm_d = 3'b010;  // eq
        end
        // Vectorial Not Equals - set up scalar encoding in rm
        VFNE: begin
          fpu_op_d     = fpnew_pkg::CMP;
          fpu_op_mod_d = 1'b1;  // invert output
          fpu_rm_d     = 3'b010;  // eq
        end
        // Vectorial Less Than - set up scalar encoding in rm
        VFLT: begin
          fpu_op_d = fpnew_pkg::CMP;
          fpu_rm_d = 3'b001;  // lt
        end
        // Vectorial Greater or Equal - set up scalar encoding in rm
        VFGE: begin
          fpu_op_d     = fpnew_pkg::CMP;
          fpu_op_mod_d = 1'b1;  // invert output
          fpu_rm_d     = 3'b001;  // lt
        end
        // Vectorial Less or Equal - set up scalar encoding in rm
        VFLE: begin
          fpu_op_d = fpnew_pkg::CMP;
          fpu_rm_d = 3'b000;  // le
        end
        // Vectorial Greater Than - set up scalar encoding in rm
        VFGT: begin
          fpu_op_d     = fpnew_pkg::CMP;
          fpu_op_mod_d = 1'b1;  // invert output
          fpu_rm_d     = 3'b000;  // le
        end
        // Vectorial Convert-and-Pack from FP32, lower 4 entries
        VFCPKAB_S: begin
          fpu_op_d        = fpnew_pkg::CPKAB;
          fpu_op_mod_d    = fpu_rm_i[0];  // A/B selection from R bit
          vec_replication = 1'b0;  // no replication, R bit used for op
          fpu_srcfmt_d    = fpnew_pkg::FP32;  // Cast from FP32
        end
        // Vectorial Convert-and-Pack from FP32, upper 4 entries
        VFCPKCD_S: begin
          fpu_op_d        = fpnew_pkg::CPKCD;
          fpu_op_mod_d    = fpu_rm_i[0];  // C/D selection from R bit
          vec_replication = 1'b0;  // no replication, R bit used for op
          fpu_srcfmt_d    = fpnew_pkg::FP32;  // Cast from FP32
        end
        // Vectorial Convert-and-Pack from FP64, lower 4 entries
        VFCPKAB_D: begin
          fpu_op_d        = fpnew_pkg::CPKAB;
          fpu_op_mod_d    = fpu_rm_i[0];  // A/B selection from R bit
          vec_replication = 1'b0;  // no replication, R bit used for op
          fpu_srcfmt_d    = fpnew_pkg::FP64;  // Cast from FP64
        end
        // Vectorial Convert-and-Pack from FP64, upper 4 entries
        VFCPKCD_D: begin
          fpu_op_d        = fpnew_pkg::CPKCD;
          fpu_op_mod_d    = fpu_rm_i[0];  // C/D selection from R bit
          vec_replication = 1'b0;  // no replication, R bit used for op
          fpu_srcfmt_d    = fpnew_pkg::FP64;  // Cast from FP64
        end
        // No changes per default
        default: ;  //nothing
      endcase

      // Scalar AH encoding fixing
      if (!fpu_vec_op_d && check_ah) if (fpu_rm_i[2]) fpu_dstfmt_d = fpnew_pkg::FP16ALT;

      // Replication
      if (fpu_vec_op_d && vec_replication) begin
        if (replicate_c) begin
          unique case (fpu_dstfmt_d)
            fpnew_pkg::FP32:
            operand_c_d = CVA6Cfg.RVD ? CVA6Cfg.FLen'({2{operand_c_i[31:0]}}) : operand_c_i;
            fpnew_pkg::FP16, fpnew_pkg::FP16ALT:
            operand_c_d = CVA6Cfg.RVD ? CVA6Cfg.FLen'({4{operand_c_i[15:0]}}) :
                                          CVA6Cfg.FLen'({2{operand_c_i[15:0]}});
            fpnew_pkg::FP8:
            operand_c_d = CVA6Cfg.RVD ? CVA6Cfg.FLen'({8{operand_c_i[7:0]}}) :
                                          CVA6Cfg.FLen'({4{operand_c_i[7:0]}});
            default: ;  // Do nothing
          endcase  // fpu_dstfmt_d
        end else begin
          unique case (fpu_dstfmt_d)
            fpnew_pkg::FP32:
            operand_b_d = CVA6Cfg.RVD ? CVA6Cfg.FLen'({2{operand_b_i[31:0]}}) : operand_b_i;
            fpnew_pkg::FP16, fpnew_pkg::FP16ALT:
            operand_b_d = CVA6Cfg.RVD ? CVA6Cfg.FLen'({4{operand_b_i[15:0]}}) :
                                          CVA6Cfg.FLen'({2{operand_b_i[15:0]}});
            fpnew_pkg::FP8:
            operand_b_d = CVA6Cfg.RVD ? CVA6Cfg.FLen'({8{operand_b_i[7:0]}}) :
                                          CVA6Cfg.FLen'({4{operand_b_i[7:0]}});
            default: ;  // Do nothing
          endcase  // fpu_dstfmt_d
        end
      end
    end


    //---------------------------------------------------------
    // Upstream protocol inversion: InValid depends on InReady
    //---------------------------------------------------------

    always_comb begin : p_inputFSM
      // Default Values
      fpu_ready_o  = 1'b0;
      fpu_in_valid = 1'b0;
      hold_inputs  = 1'b0;  // hold register disabled
      use_hold     = 1'b0;  // inputs go directly to unit
      state_d      = state_q;  // stay in the same state

      // FSM
      unique case (state_q)
        // Default state, ready for instructions
        READY: begin
          fpu_ready_o  = 1'b1;  // Act as if FPU ready
          fpu_in_valid = fpu_valid_i;  // Forward input valid to FPU
          // There is a transaction but the FPU can't handle it
          if (fpu_valid_i & ~fpu_in_ready) begin
            fpu_ready_o = 1'b0;  // No token given to Issue
            hold_inputs = 1'b1;  // save inputs to the holding register
            state_d     = STALL;  // stall future incoming requests
          end
        end
        // We're stalling the upstream (ready=0)
        STALL: begin
          fpu_in_valid = 1'b1;  // we have data for the FPU
          use_hold     = 1'b1;  // the data comes from the hold reg
          // Wait until it's consumed
          if (fpu_in_ready) begin
            fpu_ready_o = 1'b1;  // Give a token to issue
            state_d     = READY;  // accept future requests
          end
        end
        // Default: emit default values
        default: ;
      endcase

      // Flushing will override issue and go back to idle
      if (flush_i) begin
        state_d = READY;
      end

    end

    // Buffer register and FSM state holding
    always_ff @(posedge clk_i or negedge rst_ni) begin : fp_hold_reg
      if (~rst_ni) begin
        state_q      <= READY;
        operand_a_q  <= '0;
        operand_b_q  <= '0;
        operand_c_q  <= '0;
        fpu_op_q     <= '0;
        fpu_op_mod_q <= '0;
        fpu_srcfmt_q <= '0;
        fpu_dstfmt_q <= '0;
        fpu_ifmt_q   <= '0;
        fpu_rm_q     <= '0;
        fpu_vec_op_q <= '0;
        fpu_tag_q    <= '0;
      end else begin
        state_q <= state_d;
        // Hold register is [TRIGGERED] by FSM
        if (hold_inputs) begin
          operand_a_q  <= operand_a_d;
          operand_b_q  <= operand_b_d;
          operand_c_q  <= operand_c_d;
          fpu_op_q     <= fpu_op_d;
          fpu_op_mod_q <= fpu_op_mod_d;
          fpu_srcfmt_q <= fpu_srcfmt_d;
          fpu_dstfmt_q <= fpu_dstfmt_d;
          fpu_ifmt_q   <= fpu_ifmt_d;
          fpu_rm_q     <= fpu_rm_d;
          fpu_vec_op_q <= fpu_vec_op_d;
          fpu_tag_q    <= fpu_tag_d;
        end
      end
    end

    // Select FPU input data: from register if valid data in register, else directly from input
    assign operand_a  = use_hold ? operand_a_q : operand_a_d;
    assign operand_b  = use_hold ? operand_b_q : operand_b_d;
    assign operand_c  = use_hold ? operand_c_q : operand_c_d;
    assign fpu_op     = use_hold ? fpu_op_q : fpu_op_d;
    assign fpu_op_mod = use_hold ? fpu_op_mod_q : fpu_op_mod_d;
    assign fpu_srcfmt = use_hold ? fpu_srcfmt_q : fpu_srcfmt_d;
    assign fpu_dstfmt = use_hold ? fpu_dstfmt_q : fpu_dstfmt_d;
    assign fpu_ifmt   = use_hold ? fpu_ifmt_q : fpu_ifmt_d;
    assign fpu_rm     = use_hold ? fpu_rm_q : fpu_rm_d;
    assign fpu_vec_op = use_hold ? fpu_vec_op_q : fpu_vec_op_d;
    assign fpu_tag    = use_hold ? fpu_tag_q : fpu_tag_d;

    // Consolidate operands
    logic [2:0][CVA6Cfg.FLen-1:0] fpu_operands;

    assign fpu_operands[0] = operand_a;
    assign fpu_operands[1] = operand_b;
    assign fpu_operands[2] = operand_c;

    //---------------
    // FPU instance
    //---------------

    fpnew_top #(
        .Features      (FPU_FEATURES),
        .Implementation(FPU_IMPLEMENTATION),
        .DivSqrtSel    (DIVSQRT_SEL),
        .TagType       (logic [CVA6Cfg.TRANS_ID_BITS-1:0])
    ) i_fpnew_bulk (
        .clk_i,
        .rst_ni,
        .operands_i    (fpu_operands),
        .rnd_mode_i    (fpnew_pkg::roundmode_e'(fpu_rm)),
        .op_i          (fpnew_pkg::operation_e'(fpu_op)),
        .op_mod_i      (fpu_op_mod),
        .src_fmt_i     (fpnew_pkg::fp_format_e'(fpu_srcfmt)),
        .dst_fmt_i     (fpnew_pkg::fp_format_e'(fpu_dstfmt)),
        .int_fmt_i     (fpnew_pkg::int_format_e'(fpu_ifmt)),
        .vectorial_op_i(fpu_vec_op),
        .tag_i         (fpu_tag),
        .simd_mask_i   (1'b1),
        .in_valid_i    (fpu_in_valid),
        .in_ready_o    (fpu_in_ready),
        .flush_i,
        .result_o,
        .status_o      (fpu_status),
        .tag_o         (fpu_trans_id_o),
        .out_valid_o   (fpu_out_valid),
        .out_ready_i   (fpu_out_ready),
        .busy_o        (  /* unused */),
        .early_valid_o (fpu_early_valid_o)
    );

    // Pack status flag into exception cause, tval ignored in wb, exception is always invalid
    assign fpu_exception_o.cause = CVA6Cfg.XLEN'(fpu_status);
    assign fpu_exception_o.valid = 1'b0;
    assign fpu_exception_o.tval = '0;
    assign fpu_exception_o.tval2 = '0;
    assign fpu_exception_o.tinst = '0;
    assign fpu_exception_o.gva = '0;
    assign fpu_exception_o.timing = '0;

    // Downstream write port is dedicated to FPU and always ready
    assign fpu_out_ready = 1'b1;

    // Downstream valid from unit
    assign fpu_valid_o = fpu_out_valid;

  end
endmodule
