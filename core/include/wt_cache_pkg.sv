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
// Author: Michael Schaffner <schaffner@iis.ee.ethz.ch>, ETH Zurich
// Date: 15.08.2018
// Description: Package for OpenPiton compatible L1 cache subsystem

// this is needed to propagate the
// configuration in case Ariane is
// instantiated in OpenPiton
`ifdef PITON_ARIANE
`include "l15.tmp.h"
`include "define.tmp.h"
`endif

package wt_cache_pkg;

  // these parameters need to coincide with the
  // L1.5 parameterization, do not change
`ifdef PITON_ARIANE

`ifndef CONFIG_L15_ASSOCIATIVITY
  `define CONFIG_L15_ASSOCIATIVITY 4
`endif

`ifndef TLB_CSM_WIDTH
  `define TLB_CSM_WIDTH 33
`endif

  localparam L15_SET_ASSOC = `CONFIG_L15_ASSOCIATIVITY;
  localparam L15_TLB_CSM_WIDTH = `TLB_CSM_WIDTH;
`else
  localparam L15_TLB_CSM_WIDTH = 33;
`endif

  // FIFO depths of L15 adapter
  localparam ADAPTER_REQ_FIFO_DEPTH = 2;
  localparam ADAPTER_RTRN_FIFO_DEPTH = 2;


  // TX status registers are indexed with the transaction ID
  // they basically store which bytes from which buffer entry are part
  // of that transaction

  // local interfaces between caches and L15 adapter
  typedef enum logic [1:0] {
    DCACHE_STORE_REQ,
    DCACHE_LOAD_REQ,
    DCACHE_ATOMIC_REQ,
    DCACHE_INT_REQ
  } dcache_out_t;

  typedef enum logic [2:0] {
    DCACHE_INV_REQ,  // no ack from the core required
    DCACHE_STORE_ACK,  // note: this may contain an invalidation vector, too
    DCACHE_LOAD_ACK,
    DCACHE_ATOMIC_ACK,
    DCACHE_INT_ACK
  } dcache_in_t;

  typedef enum logic [0:0] {
    ICACHE_INV_REQ,   // no ack from the core required
    ICACHE_IFILL_ACK
  } icache_in_t;

  // taken from iop.h in openpiton
  // to l1.5 (only marked subset is used)
  typedef enum logic [4:0] {
    L15_LOAD_RQ    = 5'b00000,  // load request
    L15_IMISS_RQ   = 5'b10000,  // instruction fill request
    L15_STORE_RQ   = 5'b00001,  // store request
    L15_ATOMIC_RQ  = 5'b00110,  // atomic op
    //L15_CAS1_RQ     = 5'b00010, // compare and swap1 packet (OpenSparc atomics)
    //L15_CAS2_RQ     = 5'b00011, // compare and swap2 packet (OpenSparc atomics)
    //L15_SWAP_RQ     = 5'b00110, // swap packet (OpenSparc atomics)
    L15_STRLOAD_RQ = 5'b00100,  // unused
    L15_STRST_RQ   = 5'b00101,  // unused
    L15_STQ_RQ     = 5'b00111,  // unused
    L15_INT_RQ     = 5'b01001,  // interrupt request
    L15_FWD_RQ     = 5'b01101,  // unused
    L15_FWD_RPY    = 5'b01110,  // unused
    L15_RSVD_RQ    = 5'b11111   // unused
  } l15_reqtypes_t;

  // from l1.5 (only marked subset is used)
  typedef enum logic [3:0] {
    L15_LOAD_RET               = 4'b0000,  // load packet
    // L15_INV_RET                = 4'b0011, // invalidate packet, not unique...
    L15_ST_ACK                 = 4'b0100,  // store ack packet
    //L15_AT_ACK                 = 4'b0011, // unused, not unique...
    L15_INT_RET                = 4'b0111,  // interrupt packet
    L15_TEST_RET               = 4'b0101,  // unused
    L15_FP_RET                 = 4'b1000,  // unused
    L15_IFILL_RET              = 4'b0001,  // instruction fill packet
    L15_EVICT_REQ              = 4'b0011,  // eviction request
    L15_ERR_RET                = 4'b1100,  // unused
    L15_STRLOAD_RET            = 4'b0010,  // unused
    L15_STRST_ACK              = 4'b0110,  // unused
    L15_FWD_RQ_RET             = 4'b1010,  // unused
    L15_FWD_RPY_RET            = 4'b1011,  // unused
    L15_RSVD_RET               = 4'b1111,  // unused
    L15_CPX_RESTYPE_ATOMIC_RES = 4'b1110   // custom type for atomic responses
  } l15_rtrntypes_t;

  // swap endianness in a 64bit word
  function automatic logic [63:0] swendian64(input logic [63:0] in);
    automatic logic [63:0] out;
    for (int k = 0; k < 64; k += 8) begin
      out[k+:8] = in[63-k-:8];
    end
    return out;
  endfunction

  function automatic logic [5:0] popcnt64(input logic [63:0] in);
    logic [5:0] cnt = 0;
    foreach (in[k]) begin
      cnt += 6'(in[k]);
    end
    return cnt;
  endfunction : popcnt64

  // note: this is openpiton specific. cannot transmit unaligned words.
  // hence we default to individual bytes in that case, and they have to be transmitted
  // one after the other
  function automatic logic [1:0] toSize64(input logic [7:0] be);
    logic [1:0] size;
    unique case (be)
      8'b1111_1111:                                           size = 2'b11;  // dword
      8'b0000_1111, 8'b1111_0000:                             size = 2'b10;  // word
      8'b1100_0000, 8'b0011_0000, 8'b0000_1100, 8'b0000_0011: size = 2'b01;  // hword
      default:                                                size = 2'b00;  // individual bytes
    endcase  // be
    return size;
  endfunction : toSize64


  function automatic logic [1:0] toSize32(input logic [3:0] be);
    logic [1:0] size;
    unique case (be)
      4'b1111:          size = 2'b10;  // word
      4'b1100, 4'b0011: size = 2'b01;  // hword
      default:          size = 2'b00;  // individual bytes
    endcase  // be
    return size;
  endfunction : toSize32

endpackage
