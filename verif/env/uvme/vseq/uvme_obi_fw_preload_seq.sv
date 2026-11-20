// Copyright 2024 Thales DIS SAS
//
// Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
// You may obtain a copy of the License at https://solderpad.org/licenses/
//
// Original Author: Alae Eddine EZ ZEJJARI (alae-eddine.ez-zejjari@external.thalesgroup.com) – sub-contractor MU-Electronics for Thales group


`ifndef __UVME_OBI_FW_PRELOAD_SEQ_SV__
`define __UVME_OBI_FW_PRELOAD_SEQ_SV__


/**
 * Virtual sequence preloads the CVA6 memory.
 */
class uvme_obi_fw_preload_seq_c extends uvma_obi_memory_fw_preload_seq_c;

   uvml_mem_c mem;
   static uvm_cmdline_processor uvcl = uvm_cmdline_processor::get_inst();

   bit[63:0] value;
   logic [7:0][7:0] mem_row;
   string binary = "";
   longint address;
   longint len;
   byte buffer[];

   `uvm_object_utils(uvme_obi_fw_preload_seq_c)

   /**
    * Default constructor.
    */
   extern function new(string name="uvma_obi_fw_preload_seq");

   extern virtual task body();

endclass : uvme_obi_fw_preload_seq_c

function uvme_obi_fw_preload_seq_c::new(string name="uvma_obi_fw_preload_seq");

   super.new(name);

endfunction : new

task uvme_obi_fw_preload_seq_c::body();

   void'(uvcl.get_arg_value("+elf_file=", binary));

   if (binary != "") begin
      read_elf(binary);
      wait(p_sequencer.cntxt.vif.clk);
      // while there are more sections to process
      while (get_section(address, len)) begin
         automatic int num_words0 = (len+7)/8;
         `uvm_info( "Core Test", $sformatf("Loading Address: %x, Length: %x", address, len), UVM_HIGH)
         buffer = new [num_words0*8];
         read_section_sv(address, buffer);
         // preload memories
         // 64-bit
         for (int i = 0; i < num_words0; i++) begin
            mem_row = '0;
            for (int j = 0; j < 8; j++) begin
                mem_row[j] = buffer[i*8 + j];
            end
            p_sequencer.cntxt.mem.write(address + i*8 + 0, mem_row[0]);
            p_sequencer.cntxt.mem.write(address + i*8 + 1, mem_row[1]);
            p_sequencer.cntxt.mem.write(address + i*8 + 2, mem_row[2]);
            p_sequencer.cntxt.mem.write(address + i*8 + 3, mem_row[3]);
            p_sequencer.cntxt.mem.write(address + i*8 + 4, mem_row[4]);
            p_sequencer.cntxt.mem.write(address + i*8 + 5, mem_row[5]);
            p_sequencer.cntxt.mem.write(address + i*8 + 6, mem_row[6]);
            p_sequencer.cntxt.mem.write(address + i*8 + 7, mem_row[7]);
         end
      end
   end

endtask : body

`endif // __UVME_OBI_FW_PRELOAD_SEQ_SV__
