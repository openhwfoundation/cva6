// Copyright 2020 OpenHW Group
// Copyright 2020 Datum Technology Corporation
// Copyright 2020 Silicon Labs, Inc.
// Copyright 2021 Thales DIS Design Services SAS
//
// Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://solderpad.org/licenses/
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0


`ifndef __UVME_CVA6_PKG_SV__
`define __UVME_CVA6_PKG_SV__


// Pre-processor macros
`include "uvm_macros.svh"
`include "uvml_hrtbt_macros.sv"
`include "uvml_sb_macros.sv"

`include "uvml_mem_macros.sv"
`include "uvma_axi_macros.sv"
`include "uvma_clknrst_macros.sv"
`include "uvma_cvxif_macros.sv"
`include "uvma_isacov_macros.sv"
`include "uvme_cva6_macros.sv"


 /**
 * Encapsulates all the types needed for an UVM environment capable of driving/
 * monitoring and verifying the behavior of an CVA6 design.
 */
package uvme_cva6_pkg;

   import uvm_pkg         ::*;
   import uvml_hrtbt_pkg  ::*;
   import uvml_sb_pkg     ::*;
   import uvml_trn_pkg    ::*;
   import uvma_clknrst_pkg::*;
   import uvma_axi_pkg::*;
   import uvma_obi_memory_pkg::*;
   import uvml_mem_pkg  ::*;
   import uvma_core_cntrl_pkg::*;
   import uvma_rvfi_pkg::*;
   import uvmc_rvfi_scoreboard_pkg::*;
   import uvmc_rvfi_reference_model_pkg::*;
   import uvma_isacov_pkg::*;
   import uvma_interrupt_pkg::*;
   import uvma_cvxif_pkg::*;
   import config_pkg::*;

   import "DPI-C" function void read_elf(input string filename);
   import "DPI-C" function byte get_section(output longint address, output longint len);
   import "DPI-C" context function void read_section_sv(input longint address, inout byte buffer[]);
   import "DPI-C" function byte read_symbol (input string symbol_name, inout longint unsigned address);

  // Default legal opcode and funct7 for RV32I instructions
  bit [6:0]  legal_i_opcode[$] = '{7'b0000011,
                                   7'b0001111,
                                   7'b0010011,
                                   7'b0010111,
                                   7'b0100011,
                                   7'b0110111,
                                   7'b1100011,
                                   7'b0110011,
                                   7'b1100111,
                                   7'b1110011,
                                   7'b1101111};

  bit [6:0]  legal_i_funct7[$] = '{7'b0000000,
                                   7'b0100000};

  parameter config_pkg::cva6_cfg_t RTLCVA6Cfg = build_config_pkg::build_config(cva6_config_pkg::cva6_cfg);

   // Constants / Structs / Enums
   `include "uvme_cva6_constants.sv"
   `include "uvme_cva6_tdefs.sv"

   `include "uvml_mem_vp.sv"

   // Objects
   `include "uvma_cva6_core_cntrl_cntxt.sv"
   `include "uvme_cva6_cfg.sv"
   `include "uvme_cva6_cntxt.sv"

   // Predictor
   `include "uvme_cva6_prd.sv"

   //CSR REG
   `include "reg/cva6_csr_reg_file.sv"
   `include "reg/cva6_csr_reg_block.sv"
   `include "reg/cva6_csr_reg_adapter.sv"
   `include "reg/cva6_csr_reg_predictor.sv"

   // Environment components
   `include "uvma_cva6_core_cntrl_drv.sv"
   `include "uvma_cva6_core_cntrl_agent.sv"
   `include "uvme_cva6_sb.sv"
   `include "uvme_cva6_vsqr.sv"
   `include "uvme_isa_covg.sv"
   `include "uvme_illegal_instr_covg.sv"
   `include "uvme_exception_covg.sv"
   `include "uvme_interrupt_covg.sv"
   `include "uvme_cva6_config_covg.sv"
   `include "uvme_axi_covg.sv"
   `include "uvme_axi_ext_covg.sv"
   `include "uvme_cva6_cov_model.sv"
   `include "uvme_cva6_env.sv"

   // Virtual sequences
   `include "uvme_cva6_base_vseq.sv"
   `include "uvme_cva6_reset_vseq.sv"
   `include "uvme_axi_fw_preload_seq.sv"
   `include "uvme_obi_fw_preload_seq.sv"
   `include "uvme_obi_slv_seq.sv"
//   `include "uvme_cva6_interrupt_noise_vseq.sv"
   `include "uvme_cva6_vseq_lib.sv"

endpackage : uvme_cva6_pkg

`include "uvme_cva6_core_cntrl_if.sv"

`endif // __UVME_CVA6_PKG_SV__
