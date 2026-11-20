// Copyright 2024 Thales DIS SAS
//
// Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
// You may obtain a copy of the License at https://solderpad.org/licenses/
//
// Original Author: Ayoub JALALI (ayoub.jalali@external.thalesgroup.com)


`ifndef __UVMA_INTERRUPT_SEQ_SV__
`define __UVMA_INTERRUPT_SEQ_SV__

class uvma_interrupt_seq_c extends uvma_interrupt_base_seq_c;

   `uvm_object_utils(uvma_interrupt_seq_c)
   `uvm_declare_p_sequencer(uvma_interrupt_sqr_c)

   bit [XLEN-1:0] IRQ_ACK_VALUE = 'h0;
   int unsigned   IRQ_TIMEOUT;

   /**
    * Default constructor.
    */
   extern function new(string name="uvma_interrupt_seq");

   extern virtual task automatic clear_irq_channel(int channel, uvma_interrupt_seq_item_c  req_item);

   extern virtual task automatic drive_hooked_channel(int channel,
                                                     bit [XLEN-1:0] hook_addr,
                                                     int unsigned delay_cycles);

   extern virtual task body();

endclass : uvma_interrupt_seq_c

task automatic uvma_interrupt_seq_c::clear_irq_channel(int channel, uvma_interrupt_seq_item_c  req_item);

   IRQ_TIMEOUT = cfg.irq_timeout;
   while(1) begin
      if (cfg.mem_axi_sel) IRQ_ACK_VALUE = cntxt.mem_axi.read(cfg.irq_addr); //read from axi memory if where using AXI
      else if (cfg.mem_obi_sel) IRQ_ACK_VALUE = cntxt.mem_obi.read(cfg.irq_addr); //read from obi memory if where using OBI
      if (IRQ_ACK_VALUE[channel]) begin
        req_item.interrupt_vector[channel] = 1'h0;
        `uvm_info(get_type_name(), $sformatf("Clear interrupt channel N-%2d -> mem = 0x%x",channel, IRQ_ACK_VALUE), UVM_NONE);
        IRQ_TIMEOUT = cfg.irq_timeout;
        break;
      end
      else begin
        if (IRQ_TIMEOUT == 0) begin
          `uvm_fatal(get_type_name(), $sformatf("Timeout : failed to write into irq_add to clear pending interrupts"));
        end
        IRQ_TIMEOUT = IRQ_TIMEOUT - 1;
      end
      @(posedge cntxt.interrupt_vif.clk);
   end

endtask : clear_irq_channel

// Raise one channel every time its hook address retires.
//
// The address is a label the test defines and calls; the sw-compile recipe puts
// its address in the build manifest and the run recipe passes it here. Detection
// is on the RVFI, so it is the retirement that counts and a speculatively
// fetched hook never fires.
//
// The channel is held until the core takes the interrupt, then lowered so the
// next call to the hook produces a new edge.
task automatic uvma_interrupt_seq_c::drive_hooked_channel(int channel,
                                                          bit [XLEN-1:0] hook_addr,
                                                          int unsigned delay_cycles);

   uvma_interrupt_seq_item_c req_item;

   if (hook_addr == 0) return;  // no hook for this channel in this test

   // Out of reset the RVFI fields are not meaningful yet and the comparison below
   // can match by accident.
   while (cntxt.reset_state != UVMA_INTERRUPT_RESET_STATE_POST_RESET) begin
      @(posedge cntxt.interrupt_vif.clk);
   end

   forever begin
      // Wait for the hook instruction to retire.
      do begin
         @(posedge cntxt.interrupt_vif.clk);
      end while (!(cntxt.rvfi_instr_vif.reset_n &&
                   cntxt.rvfi_instr_vif.rvfi_valid &&
                   cntxt.rvfi_instr_vif.rvfi_pc_rdata == hook_addr));

      repeat (delay_cycles) @(posedge cntxt.interrupt_vif.clk);

      req_item = uvma_interrupt_seq_item_c::type_id::create("req_item");
      req_item.interrupt_channel_mask = 1 << channel;
      req_item.interrupt_vector = 1 << channel;
      start_item(req_item);
      finish_item(req_item);
      `uvm_info(get_type_name(),
                $sformatf("Deterministic IRQ: channel %0d raised, hook %h + %0d cycles",
                          channel, hook_addr, delay_cycles), UVM_LOW);

      // Hold the line until the core takes the interrupt (rvfi_intr): a level
      // interrupt lowered earlier could be retracted before it is taken. The
      // bound is only a safety net.
      begin : hold
         int unsigned guard = 0;
         while (guard < 4096) begin
            @(posedge cntxt.interrupt_vif.clk);
            guard++;
            if (cntxt.rvfi_instr_vif.rvfi_valid && cntxt.rvfi_instr_vif.rvfi_intr) break;
         end
      end

      req_item = uvma_interrupt_seq_item_c::type_id::create("req_item");
      req_item.interrupt_channel_mask = 1 << channel;
      req_item.interrupt_vector = '0;
      start_item(req_item);
      finish_item(req_item);
   end

endtask : drive_hooked_channel

function uvma_interrupt_seq_c::new(string name="uvma_interrupt_seq");

   super.new(name);

endfunction : new

task uvma_interrupt_seq_c::body();

  if (cfg.irq_deterministic) begin
     // Deterministic mode: one thread per hooked channel, each waiting for its
     // own address to retire. Nothing is randomised and nothing is raised unless
     // the software asks, so a test gets exactly the interrupts it calls for.
     `uvm_info(get_type_name(),
               $sformatf("Deterministic interrupts: mei@%h/%0d timer@%h/%0d ipi@%h/%0d",
                         cfg.irq_mei_addr, cfg.irq_mei_delay,
                         cfg.irq_timer_addr, cfg.irq_timer_delay,
                         cfg.irq_ipi_addr, cfg.irq_ipi_delay), UVM_NONE);
     fork
        drive_hooked_channel(0, cfg.irq_mei_addr, cfg.irq_mei_delay);
        drive_hooked_channel(1, cfg.irq_timer_addr, cfg.irq_timer_delay);
        drive_hooked_channel(2, cfg.irq_ipi_addr, cfg.irq_ipi_delay);
     join
  end
  else if (cfg.enable_interrupt) begin
      for (int i = 0; i < cfg.num_irq_supported; i++) begin
          automatic int ii = i;
          automatic uvma_interrupt_seq_item_c  req_item_c;
            fork begin
               forever begin
                      // Set interrupt request per channel
                      req_item_c = uvma_interrupt_seq_item_c::type_id::create("req_item_c");
                      start_item(req_item_c);
                      if (!req_item_c.randomize() with {
                         req_item_c.interrupt_vector[ii] inside {0 , 1};
                         req_item_c.interrupt_channel_mask == 1<<ii;
                      })
                      `uvm_error(get_type_name(), "req_item_c.randomize() failed!")
                      finish_item(req_item_c);
                      #req_item_c.irq_set_delay;
                      // Clear interrupt request per channel
                      if (req_item_c.interrupt_vector[ii]) begin
                         req_item_c = uvma_interrupt_seq_item_c::type_id::create("req_item_c");
                         if (cfg.enable_clear_irq) begin
                            clear_irq_channel(ii, req_item_c);
                            start_item(req_item_c);
                            finish_item(req_item_c);
                            #req_item_c.irq_clear_delay;
                         end
                         else begin
                           req_item_c.interrupt_vector[ii] = 'h0;
                           start_item(req_item_c);
                           finish_item(req_item_c);
                           #req_item_c.irq_clear_delay;
                         end
                      end
                   end
               end
         join_none
      end
      wait fork;
  end
  else begin
     `uvm_info(get_type_name(), $sformatf("Interrupts are disabled"), UVM_NONE);
  end

endtask : body

`endif // __UVMA_INTERRUPT_SEQ_SV__
