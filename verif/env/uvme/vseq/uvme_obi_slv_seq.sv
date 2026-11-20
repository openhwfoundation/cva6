//
// Copyright 2021 OpenHW Group
// Copyright 2021 Datum Technology Corporation
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the "License"); you may
// not use this file except in compliance with the License, or, at your option,
// the Apache License version 2.0. You may obtain a copy of the License at
//
//     https://solderpad.org/licenses/SHL-2.1/
//
// Unless required by applicable law or agreed to in writing, any work
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// License for the specific language governing permissions and limitations
// under the License.
//


`ifndef __UVME_OBI_SLV_SEQ_SV__
`define __UVME_OBI_SLV_SEQ_SV__


/**
 * Virtual sequence implementing the cva6 virtual peripherals.
 */
class uvme_obi_slv_seq_c extends uvma_obi_memory_slv_seq_c;


   `uvm_object_utils_begin(uvme_obi_slv_seq_c)
   `uvm_object_utils_end

   // Reservation set by LR and consumed by SC. A single reservation is enough
   // here: the testbench drives one hart.
   bit          reservation_valid;
   bit [31:0]   reservation_addr;

function new(string name="uvme_obi_slv_seq_c");
   super.new(name);
endfunction : new

// ---------------------------------------------------------------------------
// Atomic memory operations
// ---------------------------------------------------------------------------
// The OBI agent carries the atomic attribute on the A channel but does not act
// on it, so the operation is resolved here, next to the memory this sequence
// already owns.
//
// Encodings come from obi_pkg (vendor/pulp-platform/obi): bit 5 marks an
// atomic, ATOPLR/ATOPSC are 6'h22/6'h23 and the AMOs are 6'h20 to 6'h3C.

localparam bit [5:0] ATOP_LR      = 6'h22;
localparam bit [5:0] ATOP_SC      = 6'h23;
localparam bit [5:0] ATOP_AMOSWAP = 6'h21;
localparam bit [5:0] ATOP_AMOADD  = 6'h20;
localparam bit [5:0] ATOP_AMOXOR  = 6'h24;
localparam bit [5:0] ATOP_AMOAND  = 6'h2C;
localparam bit [5:0] ATOP_AMOOR   = 6'h28;
localparam bit [5:0] ATOP_AMOMIN  = 6'h30;
localparam bit [5:0] ATOP_AMOMAX  = 6'h34;
localparam bit [5:0] ATOP_AMOMINU = 6'h38;
localparam bit [5:0] ATOP_AMOMAXU = 6'h3C;

// LR is dispatched on its own, to resolve_load_reserved; every other atomic,
// SC included, is resolved by resolve_atomic.
function bit is_atomic_op(bit [5:0] atop);
   return atop[5] && (atop != ATOP_LR);
endfunction : is_atomic_op

// Read the bytes selected by be, least significant byte first.
function bit [63:0] read_mem_word(bit [31:0] addr, bit [7:0] be);
   bit [63:0] value = '0;
   for (int unsigned i = 0; i < 8; i++) begin
      if (be[i]) value[i*8 +: 8] = cntxt.mem.read(addr + i);
   end
   return value;
endfunction : read_mem_word

function void write_mem_word(bit [31:0] addr, bit [7:0] be, bit [63:0] value);
   for (int unsigned i = 0; i < 8; i++) begin
      if (be[i]) cntxt.mem.write(addr + i, value[i*8 +: 8]);
   end
endfunction : write_mem_word

// Number of bits taking part in the operation, so that a 32 bit atomic on a
// 64 bit bus is compared on 32 bits only.
function int unsigned atomic_width(bit [7:0] be);
   int unsigned n = 0;
   for (int unsigned i = 0; i < 8; i++) if (be[i]) n++;
   return n * 8;
endfunction : atomic_width

task resolve_load_reserved(ref uvma_obi_memory_mon_trn_c     mon_req,
                           input bit [31:0]                   addr,
                           ref uvma_obi_memory_slv_seq_item_c slv_rsp);

   slv_rsp.rdata     = read_mem_word(addr, mon_req.be);
   reservation_valid = 1'b1;
   reservation_addr  = addr;

   // the core issues the LR with we set, so the response has to be presented
   // as a read for the driver to return the data on the R channel
   slv_rsp.access_type = UVMA_OBI_MEMORY_ACCESS_READ;

endtask : resolve_load_reserved

task resolve_atomic(ref uvma_obi_memory_mon_trn_c     mon_req,
                    input bit [31:0]                   addr,
                    ref uvma_obi_memory_slv_seq_item_c slv_rsp);

   bit [63:0]   old_value;
   bit [63:0]   operand;
   bit [63:0]   result;
   int unsigned width;
   longint      old_signed;
   longint      operand_signed;
   bit          sc_success;

   width     = atomic_width(mon_req.be);
   old_value = read_mem_word(addr, mon_req.be);
   operand   = mon_req.data;

   // signed views, sized to the access, so MIN/MAX compare correctly
   old_signed     = $signed(old_value << (64 - width)) >>> (64 - width);
   operand_signed = $signed(operand   << (64 - width)) >>> (64 - width);

   sc_success = 1'b1;

   case (mon_req.atop)
      ATOP_SC: begin
         sc_success = reservation_valid && (reservation_addr == addr);
         result     = operand;
      end
      ATOP_AMOSWAP : result = operand;
      ATOP_AMOADD  : result = old_value + operand;
      ATOP_AMOXOR  : result = old_value ^ operand;
      ATOP_AMOAND  : result = old_value & operand;
      ATOP_AMOOR   : result = old_value | operand;
      ATOP_AMOMIN  : result = (old_signed < operand_signed) ? old_value : operand;
      ATOP_AMOMAX  : result = (old_signed > operand_signed) ? old_value : operand;
      ATOP_AMOMINU : result = (old_value  < operand)        ? old_value : operand;
      ATOP_AMOMAXU : result = (old_value  > operand)        ? old_value : operand;
      default: begin
         `uvm_error("SLV_SEQ", $sformatf("Unsupported atomic operation atop=0x%02x", mon_req.atop))
         result = operand;
      end
   endcase

   if (mon_req.atop == ATOP_SC) begin
      if (sc_success) write_mem_word(addr, mon_req.be, result);
      // an SC returns 0 on success and a non zero value on failure
      slv_rsp.rdata = sc_success ? '0 : 64'd1;
      // any SC clears the reservation, whether it succeeded or not
      reservation_valid = 1'b0;
   end
   else begin
      write_mem_word(addr, mon_req.be, result);
      // an AMO returns the value held before the operation
      slv_rsp.rdata = old_value;
      // a write to the reserved location breaks the reservation
      if (reservation_valid && (reservation_addr == addr)) reservation_valid = 1'b0;
   end

   // The driver only drives rdata for a read access, and an atomic is a write
   // on the A channel. Present the response as a read so the returned value
   // reaches the R channel, without touching the shared OBI agent.
   slv_rsp.access_type = UVMA_OBI_MEMORY_ACCESS_READ;

endtask : resolve_atomic

task do_response(ref uvma_obi_memory_mon_trn_c mon_req);

   automatic uvma_obi_memory_mon_trn_c curr_req = mon_req;

   fork
      begin
        super.do_response(curr_req);
      end
   join_none

endtask : do_response

task do_mem_operation(ref uvma_obi_memory_mon_trn_c mon_req);
   bit [31:0] word_aligned_addr;
   int unsigned align_bits = $clog2(cfg.data_width / 8);

   uvma_obi_memory_slv_seq_item_c  slv_rsp;
   `uvm_create(slv_rsp)
   slv_rsp.orig_trn = mon_req;
   slv_rsp.access_type = mon_req.access_type;

   word_aligned_addr = (mon_req.address >> align_bits) << align_bits;

   `uvm_info("SLV_SEQ", $sformatf("Performing operation:\n%s", mon_req.sprint()), UVM_HIGH)
   if (mon_req.atop == ATOP_LR) begin
      // LR is issued with we set: dispatched on atop, not on the access type
      resolve_load_reserved(mon_req, word_aligned_addr, slv_rsp);
   end
   else if (is_atomic_op(mon_req.atop)) begin
      resolve_atomic(mon_req, word_aligned_addr, slv_rsp);
   end
   else if (mon_req.access_type == UVMA_OBI_MEMORY_ACCESS_WRITE) begin
      if (mon_req.be[7]) cntxt.mem.write(word_aligned_addr+7, mon_req.data[63:56]);
      if (mon_req.be[6]) cntxt.mem.write(word_aligned_addr+6, mon_req.data[55:48]);
      if (mon_req.be[5]) cntxt.mem.write(word_aligned_addr+5, mon_req.data[47:40]);
      if (mon_req.be[4]) cntxt.mem.write(word_aligned_addr+4, mon_req.data[39:32]);
      if (mon_req.be[3]) cntxt.mem.write(word_aligned_addr+3, mon_req.data[31:24]);
      if (mon_req.be[2]) cntxt.mem.write(word_aligned_addr+2, mon_req.data[23:16]);
      if (mon_req.be[1]) cntxt.mem.write(word_aligned_addr+1, mon_req.data[15:08]);
      if (mon_req.be[0]) cntxt.mem.write(word_aligned_addr+0, mon_req.data[07:00]);
      // a plain store to the reserved location breaks the reservation
      if (reservation_valid && (reservation_addr == word_aligned_addr)) begin
         reservation_valid = 1'b0;
      end
   end
   else begin
      if (mon_req.be[7]) slv_rsp.rdata[63:56] = cntxt.mem.read(word_aligned_addr+7);
      if (mon_req.be[6]) slv_rsp.rdata[55:48] = cntxt.mem.read(word_aligned_addr+6);
      if (mon_req.be[5]) slv_rsp.rdata[47:40] = cntxt.mem.read(word_aligned_addr+5);
      if (mon_req.be[4]) slv_rsp.rdata[39:32] = cntxt.mem.read(word_aligned_addr+4);
      if (mon_req.be[3]) slv_rsp.rdata[31:24] = cntxt.mem.read(word_aligned_addr+3);
      if (mon_req.be[2]) slv_rsp.rdata[23:16] = cntxt.mem.read(word_aligned_addr+2);
      if (mon_req.be[1]) slv_rsp.rdata[15:08] = cntxt.mem.read(word_aligned_addr+1);
      if (mon_req.be[0]) slv_rsp.rdata[07:00] = cntxt.mem.read(word_aligned_addr+0);
   end

   add_r_fields(mon_req, slv_rsp);
   slv_rsp.set_sequencer(p_sequencer);
   `uvm_send(slv_rsp)

endtask : do_mem_operation


endclass : uvme_obi_slv_seq_c
`endif // __UVME_OBI_SLV_SEQ_SV__
