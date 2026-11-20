// Copyright 2024 Thales DIS SAS
//
// Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
// You may obtain a copy of the License at https://solderpad.org/licenses/
//
// Original Author: Ayoub JALALI (ayoub.jalali@external.thalesgroup.com)


`ifndef __UVMA_INTERRUPT_PKG_SV__
`define __UVMA_INTERRUPT_PKG_SV__


// Pre-processor macros
`include "uvm_macros.svh"
`include "uvml_hrtbt_macros.sv"
`include "uvma_interrupt_macros.sv"
`include "uvma_axi_macros.sv"
/**
 * Encapsulates all the types needed for an UVM agent capable of driving and/or
 * monitoring Clock & Reset.
 */

package uvma_interrupt_pkg;

   import uvm_pkg       ::*;
   import uvml_mem_pkg::*;
   import uvml_hrtbt_pkg::*;
   import uvml_trn_pkg  ::*;
   import uvml_logs_pkg ::*;
   // For the retired instruction interface used by the deterministic mode. The
   // RVFI package is compiled before this one, see uvmt_cva6.flist.
   import uvma_rvfi_pkg ::*;

   parameter XLEN = 32;
   parameter int MAX_ADDR_WIDTH    = `UVMA_AXI_ADDR_MAX_WIDTH    ; // subjective maximum

   // Constants / Structs / Enums
   `include "uvma_interrupt_constants.sv"
   `include "uvma_interrupt_tdefs.sv"

   // Objects
   `include "uvma_interrupt_cfg.sv"
   `include "uvma_interrupt_cntxt.sv"

   // High-level transactions
   `include "uvma_interrupt_seq_item.sv"
   
   // Agent components
   `include "uvma_interrupt_cov_model.sv"
   `include "uvma_interrupt_mon.sv"
   `include "uvma_interrupt_drv.sv"
   `include "uvma_interrupt_sqr.sv"
   `include "uvma_interrupt_agent.sv"

   // Sequences
   `include "uvma_interrupt_base_seq.sv"
   `include "uvma_interrupt_seq.sv"
   
endpackage : uvma_interrupt_pkg

   // Interface(s) / Module(s) / Checker(s)
   `include "uvma_interrupt_if.sv"

`endif // __UVMA_INTERRUPT_PKG_SV__
