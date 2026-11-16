/*
 *  Copyright 2023 CEA*
 *  *Commissariat a l'Energie Atomique et aux Energies Alternatives (CEA)
 *
 *  SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
 *
 *  Licensed under the Solderpad Hardware License v 2.1 (the “License”); you
 *  may not use this file except in compliance with the License, or, at your
 *  option, the Apache License version 2.0. You may obtain a copy of the
 *  License at
 *
 *  https://solderpad.org/licenses/SHL-2.1/
 *
 *  Unless required by applicable law or agreed to in writing, any work
 *  distributed under the License is distributed on an “AS IS” BASIS, WITHOUT
 *  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 *  License for the specific language governing permissions and limitations
 *  under the License.
 */
/*
 *  Authors      : Noelia Oliete, Cesar Fuguet
 *  Creation Date: June, 2023
 *  Description  : Adapter module to connect the HPDC and L1I$ to the native interface of the OpenPiton L1.5 cache.
 *                 L1 Dcache (CV-HPDcache).
 *  History      :
 */
module cva6_hpdcache_subsystem_l15_adapter
  import ariane_pkg::*;
  import wt_cache_pkg::*;
  import hpdcache_pkg::*;
//  Parameters
//  {{{
#(
    parameter config_pkg::cva6_cfg_t CVA6Cfg = config_pkg::cva6_cfg_empty,  // contains cacheable regions

    parameter int                        NumPorts        = 4,
    parameter     [$clog2(NumPorts)-1:0] IcachePort      = 0,
    parameter     [$clog2(NumPorts)-1:0] DcacheReadPort  = 1,
    parameter     [$clog2(NumPorts)-1:0] DcacheWritePort = 2,
    parameter     [$clog2(NumPorts)-1:0] DcacheAmoPort   = 3,

    // Cache parameters
    parameter int HPDcacheMemDataWidth = 128,  //L1D cacheline
    parameter int L15BusWidth = 128,

    // L1 cache types
    parameter type icache_req_t   = logic,
    parameter type icache_rtrn_t  = logic,
    parameter type dcache_req_i_t = logic,
    parameter type dcache_req_o_t = logic,

    //L1.5 cache types
    parameter type l15_req_t  = logic,
    parameter type l15_rtrn_t = logic,

    parameter type hpdcache_mem_req_t = logic,
    parameter type hpdcache_mem_req_w_t = logic,
    parameter type hpdcache_mem_resp_r_t = logic,
    parameter type hpdcache_mem_resp_w_t = logic,
    parameter type hpdcache_mem_id_t = logic,
    parameter type hpdcache_mem_addr_t = logic,
    parameter type req_portid_t = logic,
    parameter type hpdcache_nline_t = logic
)
//  }}}

//  Ports
//  {{{
(
    input logic clk_i,
    input logic rst_ni,

    //  Interfaces from/to I$
    //  {{{
    input  logic        icache_miss_valid_i,
    output logic        icache_miss_ready_o,
    input  icache_req_t icache_miss_i,

    output logic         icache_miss_resp_valid_o,
    output icache_rtrn_t icache_miss_resp_o,
    //  }}}

    //  Interfaces from/to D$
    //  {{{
    output logic              dcache_read_ready_o,
    input  logic              dcache_read_valid_i,
    input  hpdcache_mem_req_t dcache_read_i,

    input  logic                 dcache_read_resp_ready_i,
    output logic                 dcache_read_resp_valid_o,
    output hpdcache_mem_resp_r_t dcache_read_resp_o,

    output logic            dcache_inval_valid_o,
    output hpdcache_nline_t dcache_inval_o,

    output logic              dcache_write_ready_o,
    input  logic              dcache_write_valid_i,
    input  hpdcache_mem_req_t dcache_write_i,

    output logic                dcache_write_data_ready_o,
    input  logic                dcache_write_data_valid_i,
    input  hpdcache_mem_req_w_t dcache_write_data_i,

    input  logic                 dcache_write_resp_ready_i,
    output logic                 dcache_write_resp_valid_o,
    output hpdcache_mem_resp_w_t dcache_write_resp_o,
    //  }}}

    //    Ports to/from L1.5 
    //  {{{
    output l15_req_t  l15_req_o,
    input  l15_rtrn_t l15_rtrn_i
    //  }}}
);
  //  }}}

  // Internal types of the adapter
  // {{{
  typedef logic [CVA6Cfg.ICACHE_LINE_WIDTH-1:0] icache_resp_data_t;
  typedef logic [L15BusWidth-1:0] l15_resp_data_t;

  //Unified structure for r and w responses
  typedef struct packed {

    hpdcache_mem_error_e     mem_resp_error;          //mem_resp_r_error/mem_resp_w_error
    hpdcache_mem_id_t        mem_resp_id;             //mem_resp_r_id/mem_resp_w_id
    l15_resp_data_t          mem_resp_r_data;
    logic                    mem_resp_r_last;
    logic                    mem_resp_w_is_atomic;
    logic                    mem_inval_icache_valid;
    logic                    mem_inval_dcache_valid;
    logic [CVA6Cfg.PLEN-1:0] mem_inval;
  } hpdcache_mem_resp_t;
  //  }}}

  //  Adapt the I$ interface to the HPDcache memory interface
  //  {{{
  localparam int ICACHE_CL_WORDS = CVA6Cfg.ICACHE_LINE_WIDTH / 64;
  localparam int ICACHE_CL_WORD_INDEX = $clog2(ICACHE_CL_WORDS);
  localparam int ICACHE_CL_SIZE = $clog2(CVA6Cfg.ICACHE_LINE_WIDTH / 8);
  localparam int ICACHE_WORD_SIZE = $clog2(CVA6Cfg.XLEN / 8);
  localparam int ICACHE_MEM_REQ_CL_LEN  = (CVA6Cfg.ICACHE_LINE_WIDTH + HPDcacheMemDataWidth - 1)/HPDcacheMemDataWidth;
  localparam int ICACHE_MEM_REQ_CL_SIZE = (HPDcacheMemDataWidth <= CVA6Cfg.ICACHE_LINE_WIDTH) ? $clog2(
      HPDcacheMemDataWidth / 8
  ) : ICACHE_CL_SIZE;

  //    I$ request
  //    {{{
  hpdcache_mem_req_t icache_miss_req_wdata;
  logic icache_miss_req_w, icache_miss_req_wok;

  hpdcache_mem_req_t icache_miss_req_rdata;
  logic icache_miss_req_r, icache_miss_req_rok;

  //  This FIFO has two functionnalities:
  //  -  Stabilize the ready-valid protocol. The ICACHE can abort a valid
  //     transaction without receiving the corresponding ready signal. This
  //     behavior is not supported by AXI.
  //  -  Cut a possible long timing path.
  hpdcache_fifo_reg #(
      .FIFO_DEPTH (1),
      .fifo_data_t(hpdcache_mem_req_t)
  ) i_icache_miss_req_fifo (
      .clk_i,
      .rst_ni,

      .w_i    (icache_miss_req_w),
      .wok_o  (icache_miss_req_wok),
      .wdata_i(icache_miss_req_wdata),

      .r_i    (icache_miss_req_r),
      .rok_o  (icache_miss_req_rok),
      .rdata_o(icache_miss_req_rdata)
  );

  assign icache_miss_req_w = icache_miss_valid_i, icache_miss_ready_o = icache_miss_req_wok;

  assign icache_miss_req_wdata.mem_req_addr = icache_miss_i.paddr,
      icache_miss_req_wdata.mem_req_len = '0,
      icache_miss_req_wdata.mem_req_size      = icache_miss_i.nc ? ICACHE_WORD_SIZE : ICACHE_MEM_REQ_CL_SIZE,
      icache_miss_req_wdata.mem_req_id = icache_miss_i.tid,
      icache_miss_req_wdata.mem_req_command = hpdcache_pkg::HPDCACHE_MEM_READ,
      icache_miss_req_wdata.mem_req_atomic = hpdcache_pkg::hpdcache_mem_atomic_e'(0),
      icache_miss_req_wdata.mem_req_cacheable = ~icache_miss_i.nc,
      icache_miss_req_wdata.mem_req_bufferable = 1'b0;
  //    }}}


  //    I$ response
  //    {{{
  logic icache_miss_resp_w, icache_miss_resp_wok;
  hpdcache_mem_resp_t icache_miss_resp_wdata;

  logic icache_miss_resp_data_w, icache_miss_resp_data_wok;
  logic              icache_miss_resp_data_r;
  icache_resp_data_t icache_miss_resp_data_rdata;

  logic icache_miss_resp_meta_w, icache_miss_resp_meta_wok;
  logic icache_miss_resp_meta_r, icache_miss_resp_meta_rok;
  hpdcache_mem_id_t                    icache_miss_resp_meta_id;
  logic             [CVA6Cfg.PLEN-1:0] icache_miss_resp_inval_address;

  //Translate the request from HPDC format to ariane's format
  assign icache_miss_resp_valid_o = icache_miss_resp_meta_rok,
      icache_miss_resp_o.rtype = (icache_miss_resp_wdata.mem_inval_icache_valid) ?  wt_cache_pkg::ICACHE_INV_REQ : wt_cache_pkg::ICACHE_IFILL_ACK,
      icache_miss_resp_o.data = icache_miss_resp_data_rdata,
      icache_miss_resp_o.user = '0,
      icache_miss_resp_o.inv.idx = {
        icache_miss_resp_inval_address[CVA6Cfg.ICACHE_INDEX_WIDTH-1:4], 4'b0000
      },
      icache_miss_resp_o.inv.all = icache_miss_resp_wdata.mem_inval_icache_valid,
      icache_miss_resp_o.inv.way = '0,
      icache_miss_resp_o.inv.vld = '0,
      icache_miss_resp_o.tid = icache_miss_resp_meta_id;

  assign icache_miss_resp_meta_rok = icache_miss_resp_w,
      icache_miss_resp_wok = 1'b1,
      icache_miss_resp_meta_id = icache_miss_resp_wdata.mem_resp_id,
      icache_miss_resp_data_rdata = icache_miss_resp_wdata.mem_resp_r_data[CVA6Cfg.ICACHE_LINE_WIDTH-1:0],
      icache_miss_resp_inval_address = icache_miss_resp_wdata.mem_inval;
  //    }}}
  //  }}}

  //  L1.5 Request arbiter
  //  {{{

  // Requests
  logic                mem_req_ready     [NumPorts-2:0];
  logic                mem_req_valid     [NumPorts-2:0];
  hpdcache_mem_req_t   mem_req           [NumPorts-2:0];


  logic                mem_req_ready_arb;
  logic                mem_req_valid_arb;
  hpdcache_mem_req_t   mem_req_arb;

  // Data
  logic                mem_req_data_ready[NumPorts-2:0];
  logic                mem_req_data_valid[NumPorts-2:0];
  hpdcache_mem_req_w_t mem_req_data      [NumPorts-2:0];
  hpdcache_mem_req_w_t mem_req_data_arb;

  // Port of the Request, NumPorts-1 available request ports
  req_portid_t         mem_req_pid       [NumPorts-2:0];
  req_portid_t         mem_req_pid_arb;

  // Request type selected
  logic                mem_req_index_arb [NumPorts-2:0];
  // LR/SC back-off
  logic                sc_backoff_over;


  //Request types
  //IFILL
  assign icache_miss_req_r = mem_req_ready[IcachePort],
      mem_req_valid[IcachePort] = icache_miss_req_rok,
      mem_req_pid[IcachePort] = IcachePort,
      mem_req[IcachePort] = icache_miss_req_rdata,
      mem_req_data_valid[IcachePort] = 1'b1,  //There is no data for this request -> always valid
      mem_req_data[IcachePort] = '0;

  //Read
  assign dcache_read_ready_o = mem_req_ready[DcacheReadPort],
      mem_req_valid[DcacheReadPort] = dcache_read_valid_i,
      mem_req_pid[DcacheReadPort] = DcacheReadPort,
      mem_req[DcacheReadPort] = dcache_read_i,
      mem_req_data_valid[DcacheReadPort]       = 1'b1, //There is no data for this request -> always valid
      mem_req_data[DcacheReadPort] = '0;

  //Write
  assign dcache_write_ready_o = mem_req_ready[DcacheWritePort],
      mem_req_valid[DcacheWritePort] = dcache_write_valid_i,
      mem_req_pid[DcacheWritePort] = DcacheWritePort,
      mem_req[DcacheWritePort] = dcache_write_i;

  assign dcache_write_data_ready_o            = mem_req_ready[DcacheWritePort], //Ready at the same time as the request
      mem_req_data_valid[DcacheWritePort] = dcache_write_data_valid_i,
      mem_req_data[DcacheWritePort] = dcache_write_data_i;

  hpdcache_l15_req_arbiter #(
      .N                   (NumPorts - 1),
      .hpdcache_mem_req_t  (hpdcache_mem_req_t),
      .hpdcache_mem_req_w_t(hpdcache_mem_req_w_t),
      .req_portid_t        (req_portid_t)
  ) i_l15_req_arbiter (
      .clk_i,
      .rst_ni,
      //Request
      .mem_req_ready_o(mem_req_ready),
      .mem_req_valid_i(mem_req_valid),
      .mem_req_pid_i  (mem_req_pid),
      .mem_req_i      (mem_req),

      //Data
      .mem_req_data_valid_i(mem_req_data_valid),
      .mem_req_data_i      (mem_req_data),
      //Arbiter 
      .mem_req_ready_i     (mem_req_ready_arb),
      .mem_req_valid_o     (mem_req_valid_arb),   //Valid when both request and data are valid. 

      //Req & Data selected 
      .mem_req_pid_o  (mem_req_pid_arb),
      .mem_req_o      (mem_req_arb),
      //Data output
      //Arbiter ready is the same for the request and the valid==1 if
      //the request and the optional date are also valid
      .mem_req_data_o (mem_req_data_arb),
      .mem_req_index_o(mem_req_index_arb)

  );
  //  }}}

  //  L1.5 Response demultiplexor
  //  {{{
  logic               mem_resp_ready;
  logic               mem_resp_valid;
  hpdcache_mem_resp_t mem_resp;

  logic               mem_resp_ready_arb[NumPorts-1:0];
  logic               mem_resp_valid_arb[NumPorts-1:0];
  hpdcache_mem_resp_t mem_resp_arb      [NumPorts-1:0];

  //Port IcachePort -> ICACHE, Port DcacheReadPort -> Read, Port DcacheWritePort -> Write, Port DcacheUncReadPort -> UC Read, Port DcacheUncWritePort -> UC Write DcacheAmoPort -> Atomic operations
  req_portid_t        mem_resp_pid;

  // L1.5 Invalidation request to dcache
  logic               inval_ready;
  logic               inval_valid;
  hpdcache_nline_t    inval;

  hpdcache_l15_resp_demux #(
      .N           (NumPorts),
      .resp_t      (hpdcache_mem_resp_t),
      .resp_id_t   (hpdcache_mem_id_t),
      .req_portid_t(req_portid_t)
  ) i_l15_resp_demux (
      .clk_i,
      .rst_ni,
      //From arbiter
      .mem_resp_ready_o(mem_resp_ready),
      .mem_resp_valid_i(mem_resp_valid),
      .mem_resp_i      (mem_resp),
      //To HPDC
      .mem_resp_ready_i(mem_resp_ready_arb),
      .mem_resp_valid_o(mem_resp_valid_arb),
      .mem_resp_o      (mem_resp_arb),
      //Port selecter
      .mem_sel_i       (mem_resp_pid)
  );

  // Responses 
  // IFILL
  assign icache_miss_resp_w = mem_resp_valid_arb[IcachePort],
      icache_miss_resp_wdata = mem_resp_arb[IcachePort],
      mem_resp_ready_arb[IcachePort] = icache_miss_resp_wok;
  // Read & AMO responses
  assign dcache_read_resp_valid_o            = mem_resp_valid_arb[DcacheAmoPort] || mem_resp_valid_arb[DcacheReadPort] || inval_valid,
      dcache_read_resp_o.mem_resp_r_data  = mem_resp_valid_arb[DcacheAmoPort] ? mem_resp_arb[DcacheAmoPort].mem_resp_r_data[HPDcacheMemDataWidth-1:0] :
                                                                                   mem_resp_arb[DcacheReadPort].mem_resp_r_data[HPDcacheMemDataWidth-1:0],
      dcache_read_resp_o.mem_resp_r_error = mem_resp_valid_arb[DcacheAmoPort] ? mem_resp_arb[DcacheAmoPort].mem_resp_error :
                                                                                   mem_resp_arb[DcacheReadPort].mem_resp_error,
      dcache_read_resp_o.mem_resp_r_id    = mem_resp_valid_arb[DcacheAmoPort] ? mem_resp_arb[DcacheAmoPort].mem_resp_id :
                                                                                   mem_resp_arb[DcacheReadPort].mem_resp_id,
      dcache_read_resp_o.mem_resp_r_last  = mem_resp_valid_arb[DcacheAmoPort] ? mem_resp_arb[DcacheAmoPort].mem_resp_r_last :
                                                                                   mem_resp_arb[DcacheReadPort].mem_resp_r_last,
      dcache_inval_valid_o = inval_valid,
      dcache_inval_o = inval,
      mem_resp_ready_arb[DcacheReadPort] = dcache_read_resp_ready_i;

  // Write
  assign dcache_write_resp_valid_o                       = mem_resp_valid_arb[DcacheAmoPort] || mem_resp_valid_arb[DcacheWritePort],
      dcache_write_resp_o.mem_resp_w_is_atomic        = mem_resp_valid_arb[DcacheAmoPort] ? mem_resp_arb[DcacheAmoPort].mem_resp_w_is_atomic :
                                                                                               mem_resp_arb[DcacheWritePort].mem_resp_w_is_atomic,
      dcache_write_resp_o.mem_resp_w_error            = mem_resp_valid_arb[DcacheAmoPort] ? mem_resp_arb[DcacheAmoPort].mem_resp_error :
                                                                                               mem_resp_arb[DcacheWritePort].mem_resp_error,
      dcache_write_resp_o.mem_resp_w_id               = mem_resp_valid_arb[DcacheAmoPort] ? mem_resp_arb[DcacheAmoPort].mem_resp_id :
                                                                                               mem_resp_arb[DcacheWritePort].mem_resp_id,
      mem_resp_ready_arb[DcacheWritePort] = dcache_write_resp_ready_i;

  // Atomic operations send the response to both Read and Write ports
  assign mem_resp_ready_arb[DcacheAmoPort] = dcache_read_resp_ready_i & dcache_write_resp_ready_i;

  // L1.5 Invalidation request to dcache 
  assign inval_ready = dcache_read_resp_ready_i, // Refill ready declares if hpdc is ready to receive an invalidation
      inval_valid = mem_resp.mem_inval_dcache_valid,
      inval = mem_resp.mem_inval[$bits(
          hpdcache_mem_addr_t
      )-1:$clog2(
          HPDcacheMemDataWidth/8
      )];  // Convert address to cacheline number

  //  }}}

  //  L15 Adapter
  //  {{{

  l15_req_t  l15_req;
  l15_rtrn_t l15_rtrn;
  logic      dcache_inval_ready;

  hpdcache_to_l15 #(
      .NumPorts(NumPorts),  // Number of request types
      .IcachePort(IcachePort),
      .DcacheReadPort(DcacheReadPort),
      .DcacheWritePort(DcacheWritePort),
      .DcacheAmoPort(DcacheAmoPort),
      .WriteByteMaskEnabled(1'b0),  //TODO!!!!!
      .SwapEndianness(1'b1),  // the L1.5 of OpenPiton is big endian
      .HPDcacheMemDataWidth(HPDcacheMemDataWidth),
      .hpdcache_mem_req_t(hpdcache_mem_req_t),
      .hpdcache_mem_req_w_t(hpdcache_mem_req_w_t),
      .hpdcache_mem_id_t(hpdcache_mem_id_t),
      .hpdcache_mem_addr_t(hpdcache_mem_addr_t),
      .hpdcache_mem_resp_t(hpdcache_mem_resp_t),
      .req_portid_t(req_portid_t),
      .l15_req_t(l15_req_t),
      .l15_rtrn_t(l15_rtrn_t)
  ) i_hpdcache_to_l15 (

      .clk_i,
      .rst_ni,

      //HPDC to Adapter
      .req_ready_o       (mem_req_ready_arb),  // L1.5 is ready to receive
      .req_valid_i       (mem_req_valid_arb),  // Request and optional data are valid
      .req_pid_i         (mem_req_pid_arb),
      .req_i             (mem_req_arb),
      .req_data_i        (mem_req_data_arb),
      .req_index_i       (mem_req_index_arb),  // Identify the type of request
      //Adapter to HPDC
      .resp_ready_i      (mem_resp_ready),
      .resp_valid_o      (mem_resp_valid),
      .resp_pid_o        (mem_resp_pid),
      .resp_o            (mem_resp),
      //HPDC Inval ready
      .hpdc_inval_ready_i(inval_ready),
      //Back-off parameter to guarantee the LR/SC completion
      .sc_backoff_over_o (sc_backoff_over),

      //Adapter to L1.5, sending request
      .l15_req_o (l15_req),  // L1.5 Request
      //L1.5 to Adapter
      .l15_rtrn_i(l15_rtrn)  // L1.5 Response
  );

  assign l15_req_o = l15_req;
  assign l15_rtrn  = l15_rtrn_i;
  //  }}}
endmodule : cva6_hpdcache_subsystem_l15_adapter
