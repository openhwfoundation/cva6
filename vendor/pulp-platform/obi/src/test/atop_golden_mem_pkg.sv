// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Author: Michael Rogenmoser <michaero@iis.ee.ethz.ch>

interface OBI_ATOP_MONITOR_BUS #(
  parameter int unsigned AddrWidth = 0,
  parameter int unsigned DataWidth = 0,
  parameter int unsigned IdWidth   = 0,
  parameter int unsigned UserWidth = 0
) (
  input logic clk_i
);

  typedef logic [IdWidth-1:0]   id_t;
  typedef logic [AddrWidth-1:0] addr_t;
  typedef logic [DataWidth-1:0] data_t;
  typedef logic [DataWidth/8-1:0] be_t;
  typedef logic [UserWidth-1:0] user_t;

  logic  valid;
  logic  we;
  addr_t addr;
  data_t data;
  be_t   be;
  id_t   id;
  user_t user;

  modport Manager (output valid, we, addr, data, be, id, user);
  modport Subordinate (input valid, we, addr, data, be, id, user);

endinterface

package atop_golden_mem_pkg;

  class atop_golden_mem #(
    parameter int unsigned ObiAddrWidth = 32,
    parameter int unsigned ObiDataWidth = 32,
    parameter int unsigned ObiIdWidthM  = 5,
    parameter int unsigned ObiIdWidthS  = 8,
    parameter int unsigned ObiUserWidth = 5,
    parameter int unsigned NumMgrWidth = 2,
    parameter time ApplDelay = 0ns,
    parameter time AcqDelay  = 0ns
  );

    typedef logic [ObiAddrWidth-1:0] mem_addr_t;

    static logic [7:0] memory [mem_addr_t];

    virtual OBI_ATOP_MONITOR_BUS #(
      .AddrWidth(ObiAddrWidth),
      .DataWidth(ObiDataWidth),
      .IdWidth  (ObiIdWidthS),
      .UserWidth(ObiUserWidth)
    ) monitor;

    function new(virtual OBI_ATOP_MONITOR_BUS  #(
        .AddrWidth(ObiAddrWidth),
        .DataWidth(ObiDataWidth),
        .IdWidth  (ObiIdWidthS),
        .UserWidth(ObiUserWidth)
      ) monitor
    );
      this.monitor = monitor;
      assert (randomize(memory));
    endfunction

    function automatic logic [ObiIdWidthS-1:0] subordinate_id(logic [ObiIdWidthM-1:0] mgr_id,
                                                              logic [NumMgrWidth-1:0] mgr_channel);
      subordinate_id = '0;
      if (ObiIdWidthS > ObiIdWidthM) begin
        subordinate_id |= (mgr_channel) << ObiIdWidthM;
      end
      subordinate_id[ObiIdWidthM-1:0] = mgr_id;
    endfunction

    task set_memory(logic [ObiAddrWidth-1:0] addr, logic [ObiDataWidth-1:0] data,
                    logic [ObiDataWidth/8-1:0] be);
      #(ApplDelay);
      // $display("set 0x%x at 0x%x",data, addr);
      for (int i = 0; i < ObiDataWidth/8; i++) begin
        if (be[i]) begin
          memory[addr+i] = data[i*8+:8];
        end
      end
    endtask

    function logic [ObiDataWidth-1:0] get_memory(logic [ObiAddrWidth-1:0] addr);
      get_memory = '0;
      for (int i = 0; i < ObiDataWidth/8; i++) begin
        get_memory[i*8+:8] = memory[addr+i];
      end
      // $display("got 0x%x at 0x%x",get_memory, addr);
    endfunction




    task write(
      input  logic [  ObiAddrWidth-1:0] addr,
      input  logic [  ObiDataWidth-1:0] wdata,
      input  logic [ObiDataWidth/8-1:0] be,
      input  logic [   ObiIdWidthM-1:0] m_id,
      // input  logic [  ObiUserWidth-1:0] user,
      input  logic [   NumMgrWidth-1:0] manager = 0,
      input  obi_pkg::atop_t            atop = '0,
      output logic [  ObiDataWidth-1:0] rdata,
      output logic                      err,
      output logic                      exokay
    );

      automatic logic [ObiIdWidthS-1:0] res_id = subordinate_id(m_id, manager);
      automatic logic unsigned [ObiDataWidth-1:0] data_ui  = $unsigned(wdata);
      automatic logic unsigned [ObiDataWidth-1:0] data_uo  = 0;
      automatic logic   signed [ObiDataWidth-1:0] data_si  = $signed(wdata);
      automatic logic   signed [ObiDataWidth-1:0] data_so  = 0;

      // $display("Writing 0x%x to 0x%x and atop 0x%x", wdata, addr, atop);


      if (atop == obi_pkg::ATOPSC) begin

        // TODO

      end else if (atop == obi_pkg::ATOPNONE) begin

        wait_write_rsp(res_id);
        set_memory(addr, wdata, be);
        rdata = '0;
        err = '0;
        exokay = '0;

      end else if (atop == obi_pkg::AMOSWAP) begin

        wait_write_rsp(res_id);
        rdata = get_memory(addr);
        set_memory(addr, wdata, be);
        err = '0;
        exokay = '0;

      end else if (atop == obi_pkg::AMOADD  || atop == obi_pkg::AMOXOR ||
                   atop == obi_pkg::AMOAND  || atop == obi_pkg::AMOOR  ||
                   atop == obi_pkg::AMOMIN  || atop == obi_pkg::AMOMAX ||
                   atop == obi_pkg::AMOMINU || atop == obi_pkg::AMOMAXU ) begin

        wait_write_rsp(res_id);

        data_uo = $unsigned(get_memory(addr));
        data_so = $unsigned(get_memory(addr));

        rdata = data_uo;

        unique case (atop)
          obi_pkg::AMOADD: begin
            set_memory(addr, data_uo + data_ui, be);
          end
          obi_pkg::AMOXOR: begin
            set_memory(addr, data_uo ^ data_ui, be);
          end
          obi_pkg::AMOAND: begin
            set_memory(addr, data_uo & data_ui, be);
          end
          obi_pkg::AMOOR: begin
            set_memory(addr, data_uo | data_ui, be);
          end
          obi_pkg::AMOMIN: begin
            set_memory(addr, data_so > data_si ? data_si : data_so, be);
          end
          obi_pkg::AMOMAX: begin
            set_memory(addr, data_so > data_si ? data_so : data_si, be);
          end
          obi_pkg::AMOMINU: begin
            set_memory(addr, data_uo > data_ui ? data_ui : data_uo, be);
          end
          obi_pkg::AMOMAXU: begin
            set_memory(addr, data_uo > data_ui ? data_uo : data_ui, be);
          end
          default: begin
            set_memory(addr, data_uo, be);
          end
        endcase
        err = '0;
        exokay = '0;

      end else begin
        err = 1'b1;
        exokay = 1'b0;
        rdata = '0;
      end

    endtask

    task read(
      input  logic [ObiAddrWidth-1:0] addr,
      input  logic [ ObiIdWidthM-1:0] m_id,
      // input  logic [ObiUserWidth-1:0] user,
      input  logic [ NumMgrWidth-1:0] manager = 0,
      input  obi_pkg::atop_t          atop = '0,
      output logic [ObiDataWidth-1:0] rdata,
      output logic                    err,
      output logic                    exokay
    );
      automatic logic [ObiIdWidthS-1:0] res_id = subordinate_id(m_id, manager);

      wait_read(res_id);
      rdata = get_memory(addr);
      err = '0;

      if (atop == obi_pkg::ATOPLR) begin
      end

      exokay = '0;

    endtask

    task wait_write_rsp(
      input logic [ObiIdWidthS-1:0] id
    );
      forever begin
        @(posedge monitor.clk_i)
        #(AcqDelay);
        if (monitor.valid && monitor.we && monitor.id == id) begin
          break;
        end
      end
    endtask

    task wait_read(
      input logic [ObiIdWidthS-1:0] id
    );
      forever begin
        @(posedge monitor.clk_i)
        #(AcqDelay);
        if (monitor.valid && !monitor.we && monitor.id == id) begin
          break;
        end
      end
    endtask


  endclass

endpackage
