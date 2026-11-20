// Copyright 2024 Thales DIS SAS
//
// Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
// You may obtain a copy of the License at https://solderpad.org/licenses/
//
// Original Author: Ayoub JALALI (ayoub.jalali@external.thalesgroup.com)


`ifndef __UVMA_INTERRUPT_CFG_SV__
`define __UVMA_INTERRUPT_CFG_SV__


class uvma_interrupt_cfg_c extends uvm_object;
   
   // Common options
   rand bit                      enabled;
   rand uvm_active_passive_enum  is_active;

   rand bit                      cov_model_enabled;
   rand bit                      trn_log_enabled;

   rand bit                      enable_interrupt;
   bit                           interrupt_plusarg_valid;

   // Number of Interrupt vector supported
   rand int unsigned             num_irq_supported;

   // Interrupt memory ack
   rand bit [XLEN-1:0]           irq_addr;
   // Select axi mem
   rand bit                      mem_axi_sel;
   // Select obi mem
   rand bit                      mem_obi_sel;

   // enable/disable clear mechanism
   rand bit                      enable_clear_irq;

   // Number of cycle before Timeout if the agent failed to write into irq_add
   rand int unsigned             irq_timeout;

   // Deterministic interrupts, driven from software rather than randomly.
   //
   // A test defines a label, irq_mei_hook, irq_timer_hook or irq_ipi_hook, and
   // calls it wherever it wants that interrupt. The run recipe passes the address
   // of the label here, and the sequence raises the channel a fixed number of
   // cycles after the instruction at that address retires. Calling the label
   // again asks for another interrupt, so a test controls both how many and when
   // without any of it being expressed on the command line.
   //
   // An address of zero means the test defined no hook for that channel, which is
   // the case of every test that does not use the feature, and the channel is
   // left alone. The three channels are independent and can be used together.
   //
   //   mei   -> irq[0] -> mip[IRQ_M_EXT],   cause 11
   //   timer -> irq[1] -> mip[IRQ_M_TIMER], cause 7
   //   ipi   -> irq[2] -> mip[IRQ_M_SOFT],  cause 3, needs SoftwareInterruptEn
   bit [XLEN-1:0]                irq_mei_addr;
   bit [XLEN-1:0]                irq_timer_addr;
   bit [XLEN-1:0]                irq_ipi_addr;
   int unsigned                  irq_mei_delay;
   int unsigned                  irq_timer_delay;
   int unsigned                  irq_ipi_delay;
   // True as soon as one hook is set, which is what tells the sequence to run in
   // deterministic mode instead of the random one.
   bit                           irq_deterministic;

   `uvm_object_utils_begin(uvma_interrupt_cfg_c)
      `uvm_field_int (                         enabled           , UVM_DEFAULT)
      `uvm_field_enum(uvm_active_passive_enum, is_active         , UVM_DEFAULT)   
      `uvm_field_int (                         cov_model_enabled , UVM_DEFAULT)
      `uvm_field_int (                         trn_log_enabled   , UVM_DEFAULT)
      `uvm_field_int (                         enable_interrupt  , UVM_DEFAULT)
      `uvm_field_int (                         interrupt_plusarg_valid  , UVM_DEFAULT)
      `uvm_field_int (                         num_irq_supported  , UVM_DEFAULT)
      `uvm_field_int (                         irq_addr           , UVM_DEFAULT)
      `uvm_field_int (                         mem_axi_sel        , UVM_DEFAULT)
      `uvm_field_int (                         mem_obi_sel        , UVM_DEFAULT)
      `uvm_field_int (                         enable_clear_irq   , UVM_DEFAULT)
      `uvm_field_int (                         irq_timeout        , UVM_DEFAULT)
      `uvm_object_utils_end
   

   constraint defaults_cons {   
      soft enabled           == 1;
      soft is_active         == UVM_PASSIVE;
      soft cov_model_enabled == 1;
      soft trn_log_enabled   == 1;
      
   }

  constraint default_enable_irq_cons {
      soft enable_interrupt  == 0;
      soft num_irq_supported == 2;
      soft enable_clear_irq  == 1;
      soft irq_timeout       == 10_000;
      soft mem_axi_sel       == 1;
      soft mem_obi_sel       == 0;
   }

   /**
    * Default constructor.
    */
   extern function new(string name="uvma_interrupt_cfg");

endclass : uvma_interrupt_cfg_c

function uvma_interrupt_cfg_c::new(string name="uvma_interrupt_cfg");
   
   super.new(name);

   // Read plusargs for defaults
   if ($test$plusargs("enable_interrupt")) begin
      interrupt_plusarg_valid = 1;
   end

   // Deterministic interrupt hooks. Addresses come from the symbols of the ELF,
   // extracted at compile time by the sw-compile recipe.
   if (!$value$plusargs("irq_mei_addr=%h", irq_mei_addr)) irq_mei_addr = '0;
   if (!$value$plusargs("irq_timer_addr=%h", irq_timer_addr)) irq_timer_addr = '0;
   if (!$value$plusargs("irq_ipi_addr=%h", irq_ipi_addr)) irq_ipi_addr = '0;
   if (!$value$plusargs("irq_mei_delay=%d", irq_mei_delay)) irq_mei_delay = 10;
   if (!$value$plusargs("irq_timer_delay=%d", irq_timer_delay)) irq_timer_delay = 10;
   if (!$value$plusargs("irq_ipi_delay=%d", irq_ipi_delay)) irq_ipi_delay = 10;

   irq_deterministic = (irq_mei_addr != 0) || (irq_timer_addr != 0) || (irq_ipi_addr != 0);

endfunction : new

`endif // __UVMA_INTERRUPT_CFG_SV__
