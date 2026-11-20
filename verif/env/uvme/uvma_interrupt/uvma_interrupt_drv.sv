// Copyright 2024 Thales DIS SAS
//
// Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
// You may obtain a copy of the License at https://solderpad.org/licenses/
//
// Original Author: Ayoub JALALI (ayoub.jalali@external.thalesgroup.com)

`ifndef __UVMA_INTERRUPT_DRV_SV__
`define __UVMA_INTERRUPT_DRV_SV__

/**
 * Component driving interrupt virtual interface (uvma_interrupt_if).
 */
class uvma_interrupt_drv_c extends uvm_driver#(uvma_interrupt_seq_item_c);

   // Objects
   uvma_interrupt_cfg_c                           cfg;
   uvma_interrupt_cntxt_c                         cntxt;

   uvma_interrupt_seq_item_c                      req_item;

   `uvm_component_utils_begin(uvma_interrupt_drv_c)
      `uvm_field_object(cfg  , UVM_DEFAULT)
      `uvm_field_object(cntxt, UVM_DEFAULT)
   `uvm_component_utils_end

   /**
    * Default constructor.
    */
   extern function new(string name="uvma_interrupt_drv", uvm_component parent=null);

   /**
    * 1. Ensures cfg & cntxt handles are not null.
    * 2. Builds ap.
    */
   extern virtual function void build_phase(uvm_phase phase);

   /**
    * Obtains the reqs from the sequence item port and calls drv_irq()
    */
   extern virtual task run_phase(uvm_phase phase);

   /**
    * Called by run_phase() while agent is in pre-reset state.
    */
   extern task drv_irq_pre_reset();

   /**
    * Called by run_phase() while agent is in reset state.
    */
   extern task drv_irq_in_reset();

   /**
    * Called by run_phase() while agent is in post-reset state.
    */
   extern task drv_irq_post_reset(uvma_interrupt_seq_item_c req);

   /**
    * Assert interrupt request
    */
   extern task assert_irq(uvma_interrupt_seq_item_c req);

endclass : uvma_interrupt_drv_c

function uvma_interrupt_drv_c::new(string name="uvma_interrupt_drv", uvm_component parent=null);

   super.new(name, parent);

endfunction : new


function void uvma_interrupt_drv_c::build_phase(uvm_phase phase);

   super.build_phase(phase);

   void'(uvm_config_db#(uvma_interrupt_cfg_c)::get(this, "", "cfg", cfg));
   if (cfg == null) begin
      `uvm_fatal(get_type_name(), "Configuration handle is null")
   end
   uvm_config_db#(uvma_interrupt_cfg_c)::set(this, "*", "cfg", cfg);

   void'(uvm_config_db#(uvma_interrupt_cntxt_c)::get(this, "", "cntxt", cntxt));
   if (cntxt == null) begin
      `uvm_fatal(get_type_name(), "Context handle is null")
   end
   uvm_config_db#(uvma_interrupt_cntxt_c)::set(this, "*", "cntxt", cntxt);
   
   req_item = uvma_interrupt_seq_item_c::type_id::create("req_item");

endfunction : build_phase

task uvma_interrupt_drv_c::run_phase(uvm_phase phase);

   super.run_phase(phase);

   //Initial the interface before the CPU start
   cntxt.interrupt_vif.irq <= 'h0;

   // Deterministic mode drives the lines too, and does not need the random
   // stimulus to be enabled: a test asks for interrupts through its hooks.
   if(!cfg.enable_interrupt && !cfg.irq_deterministic) begin
      `uvm_info(get_type_name(), "Driving Interrupt request is disabled", UVM_NONE);
      return;
   end

   forever begin
      case (cntxt.reset_state)
         UVMA_INTERRUPT_RESET_STATE_PRE_RESET : drv_irq_pre_reset ();
         UVMA_INTERRUPT_RESET_STATE_IN_RESET  : drv_irq_in_reset  ();
         UVMA_INTERRUPT_RESET_STATE_POST_RESET: begin
              if (cfg.enable_interrupt || cfg.irq_deterministic) begin
                 seq_item_port.get_next_item(req_item);
                 drv_irq_post_reset(req_item);
                 seq_item_port.item_done();
              end
         end

         default: `uvm_fatal(get_type_name(), $sformatf("Invalid reset_state: %0d", cntxt.reset_state))
      endcase
   end

endtask : run_phase


task uvma_interrupt_drv_c::drv_irq_pre_reset();

   cntxt.interrupt_vif.irq <= 1'b0;
   @(posedge cntxt.interrupt_vif.clk);

endtask : drv_irq_pre_reset


task uvma_interrupt_drv_c::drv_irq_in_reset();

   cntxt.interrupt_vif.irq <= 1'b0;
   @(posedge cntxt.interrupt_vif.clk);

endtask : drv_irq_in_reset

task uvma_interrupt_drv_c::drv_irq_post_reset(uvma_interrupt_seq_item_c req);
   `uvm_info(get_type_name(), $sformatf("Driving:\n%s", req.sprint()), UVM_HIGH);

   assert_irq(req);

endtask : drv_irq_post_reset

task uvma_interrupt_drv_c::assert_irq(uvma_interrupt_seq_item_c req);

   for (int i = 0; i < cfg.num_irq_supported; i++) begin
     if (req.interrupt_channel_mask[i] == 1) begin
        cntxt.interrupt_vif.irq[i] <= req.interrupt_vector[i];
     end
   end

   `uvm_info(get_type_name(), $sformatf("Assert interrupt channel(s) %0b", req.interrupt_vector), UVM_HIGH)

endtask : assert_irq

`endif // __UVMA_INTERRUPT_DRV_SV__
