// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Michael Rogenmoser <michaero@iis.ee.ethz.ch>

package obi_test;
  import obi_pkg::*;

  class obi_driver #(
    parameter obi_cfg_t ObiCfg           = ObiDefaultConfig,
    parameter type      obi_a_optional_t = logic,
    parameter type      obi_r_optional_t = logic,
    parameter time      TA               = 0ns,
    parameter time      TT               = 0ns
  );
    virtual OBI_BUS_DV #(
      .OBI_CFG          ( ObiCfg           ),
      .obi_a_optional_t ( obi_a_optional_t ),
      .obi_r_optional_t ( obi_r_optional_t )
    ) obi;

    function new(
      virtual OBI_BUS_DV #(
        .OBI_CFG          ( ObiCfg           ),
        .obi_a_optional_t ( obi_a_optional_t ),
        .obi_r_optional_t ( obi_r_optional_t )
      ) obi
    );
      this.obi = obi;
    endfunction

    function void reset_manager();
      obi.req        <= '0;
      obi.reqpar     <= '1;
      obi.addr       <= '0;
      obi.we         <= '0;
      obi.be         <= '0;
      obi.wdata      <= '0;
      obi.aid        <= '0;
      obi.a_optional <= '0;
      obi.rready     <= '0;
      obi.rreadypar  <= '1;
    endfunction

    function void reset_subordinate();
      obi.gnt        <= '0;
      obi.gntpar     <= '1;
      obi.rvalid     <= '0;
      obi.rvalidpar  <= '1;
      obi.rdata      <= '0;
      obi.rid        <= '0;
      obi.r_optional <= '0;
    endfunction

    task cycle_start;
      #TT;
    endtask

    task cycle_end;
      @(posedge obi.clk_i);
    endtask

    task send_a (
      input logic [  ObiCfg.AddrWidth-1:0] addr,
      input logic                          we,
      input logic [ObiCfg.DataWidth/8-1:0] be,
      input logic [  ObiCfg.DataWidth-1:0] wdata,
      input logic [    ObiCfg.IdWidth-1:0] aid,
      input obi_a_optional_t               a_optional
    );
      obi.req        <= #TA 1'b1;
      obi.reqpar     <= #TA 1'b0;
      obi.addr       <= #TA addr;
      obi.we         <= #TA we;
      obi.be         <= #TA be;
      obi.wdata      <= #TA wdata;
      obi.aid        <= #TA aid;
      obi.a_optional <= #TA a_optional;
      cycle_start();
      while (obi.gnt != 1'b1) begin cycle_end(); cycle_start(); end
      cycle_end();
      obi.req        <= #TA 1'b0;
      obi.reqpar     <= #TA 1'b1;
      obi.addr       <= #TA '0;
      obi.we         <= #TA '0;
      obi.be         <= #TA '0;
      obi.wdata      <= #TA '0;
      obi.aid        <= #TA '0;
      obi.a_optional <= #TA '0;
    endtask

    task send_r (
      input logic [ObiCfg.DataWidth-1:0] rdata,
      input logic [  ObiCfg.IdWidth-1:0] rid,
      input obi_r_optional_t             r_optional
    );
      obi.rvalid     <= #TA 1'b1;
      obi.rvalidpar  <= #TA 1'b0;
      obi.rdata      <= #TA rdata;
      obi.rid        <= #TA rid;
      obi.r_optional <= #TA r_optional;
      cycle_start();
      if (ObiCfg.UseRReady) begin
        while (obi.rready != 1'b1) begin cycle_end(); cycle_start(); end
      end
      cycle_end();
      obi.rvalid     <= #TA 1'b0;
      obi.rvalidpar  <= #TA 1'b1;
      obi.rdata      <= #TA '0;
      obi.rid        <= #TA '0;
      obi.r_optional <= #TA '0;
    endtask

    task recv_a (
      output logic [  ObiCfg.AddrWidth-1:0] addr,
      output logic                          we,
      output logic [ObiCfg.DataWidth/8-1:0] be,
      output logic [  ObiCfg.DataWidth-1:0] wdata,
      output logic [    ObiCfg.IdWidth-1:0] aid,
      output obi_a_optional_t               a_optional
    );
      obi.gnt    <= #TA 1'b1;
      obi.gntpar <= #TA 1'b0;
      cycle_start();
      while (obi.req != 1'b1) begin cycle_end(); cycle_start(); end
      addr       = obi.addr;
      we         = obi.we;
      be         = obi.be;
      wdata      = obi.wdata;
      aid        = obi.aid;
      a_optional = obi.a_optional;
      cycle_end();
      obi.gnt    <= #TA 1'b0;
      obi.gntpar <= #TA 1'b1;
    endtask

    task recv_r (
      output logic [ObiCfg.DataWidth-1:0] rdata,
      output logic [  ObiCfg.IdWidth-1:0] rid,
      output logic                        err,
      output obi_r_optional_t             r_optional
    );
      obi.rready    <= #TA 1'b1;
      obi.rreadypar <= #TA 1'b0;
      cycle_start();
      while (obi.rvalid != 1'b1) begin cycle_end(); cycle_start(); end
      rdata      = obi.rdata;
      rid        = obi.rid;
      err        = obi.err;
      r_optional = obi.r_optional;
      cycle_end();
      if (ObiCfg.UseRReady) begin
        obi.rready    <= #TA 1'b0;
        obi.rreadypar <= #TA 1'b1;
      end
    endtask

  endclass

  class obi_rand_manager #(
    // Obi Parameters
    parameter obi_cfg_t    ObiCfg           = ObiDefaultConfig,
    parameter type         obi_a_optional_t = logic,
    parameter type         obi_r_optional_t = logic,
    // Stimuli Parameters
    parameter time         TA               = 2ns,
    parameter time         TT               = 8ns,
    // Manager Parameters
    parameter int unsigned MinAddr          = 32'h0000_0000,
    parameter int unsigned MaxAddr          = 32'hffff_ffff,
    // Wait Parameters
    parameter int unsigned AMinWaitCycles   = 0,
    parameter int unsigned AMaxWaitCycles   = 100,
    parameter int unsigned RMinWaitCycles   = 0,
    parameter int unsigned RMaxWaitCycles   = 100
  );
    typedef obi_test::obi_driver #(
      .ObiCfg           ( ObiCfg           ),
      .obi_a_optional_t ( obi_a_optional_t ),
      .obi_r_optional_t ( obi_r_optional_t ),
      .TA               ( TA               ),
      .TT               ( TT               )
    ) obi_driver_t;

    typedef logic [ObiCfg.AddrWidth-1:0] addr_t;

    string       name;
    obi_driver_t drv;
    addr_t       a_queue[$];
    logic        r_queue[$];

    function new(
      virtual OBI_BUS_DV #(
        .OBI_CFG          ( ObiCfg           ),
        .obi_a_optional_t ( obi_a_optional_t ),
        .obi_r_optional_t ( obi_r_optional_t )
      ) obi,
      input string name
    );
      this.drv  = new(obi);
      this.name = name;
      assert(ObiCfg.AddrWidth != 0) else $fatal(1, "ObiCfg.AddrWidth must be non-zero!");
      assert(ObiCfg.DataWidth != 0) else $fatal(1, "ObiCfg.DataWidth must be non-zero!");
    endfunction

    function void reset();
      drv.reset_manager();
    endfunction

    task automatic rand_wait(input int unsigned min, input int unsigned max);
      int unsigned rand_success, cycles;
      rand_success = std::randomize(cycles) with {
        cycles >= min;
        cycles <= max;
      };
      assert (rand_success) else $error("Failed to randomize wait cycles!");
      repeat (cycles) @(posedge this.drv.obi.clk_i);
    endtask

    task automatic send_as(input int unsigned n_reqs);
      automatic addr_t                         a_addr;
      automatic logic                          a_we;
      automatic logic [ObiCfg.DataWidth/8-1:0] a_be;
      automatic logic [  ObiCfg.DataWidth-1:0] a_wdata;
      automatic logic [    ObiCfg.IdWidth-1:0] a_aid;
      automatic obi_a_optional_t               a_optional;

      repeat (n_reqs) begin
        rand_wait(AMinWaitCycles, AMaxWaitCycles);

        a_addr     = addr_t'($urandom_range(MinAddr, MaxAddr));
        a_we       = $urandom() % 2;
        a_be       = $urandom() % (1 << (ObiCfg.DataWidth/8));
        a_wdata    = $urandom() % (1 << ObiCfg.DataWidth);
        a_aid      = $urandom() % (1 << ObiCfg.IdWidth);
        a_optional = obi_a_optional_t'($urandom());

        this.a_queue.push_back(a_addr);
        this.drv.send_a(a_addr, a_we, a_be, a_wdata, a_aid, a_optional);
      end
    endtask

    task automatic recv_rs(input int unsigned n_rsps);
      automatic addr_t                       a_addr;
      automatic logic [ObiCfg.DataWidth-1:0] r_rdata;
      automatic logic [  ObiCfg.IdWidth-1:0] r_rid;
      automatic logic                        r_err;
      automatic obi_r_optional_t             r_optional;
      repeat (n_rsps) begin
        wait (a_queue.size() > 0);
        a_addr = this.a_queue.pop_front();
        rand_wait(RMinWaitCycles, RMaxWaitCycles);
        drv.recv_r(r_rdata, r_rid, r_err, r_optional);
      end
    endtask

    task automatic run(int unsigned n_reqs);
      $display("Run for Reqs: %0d", n_reqs);
      fork
        this.send_as(n_reqs);
        this.recv_rs(n_reqs);
      join
    endtask

    task automatic write(
      input  addr_t                         addr,
      input  logic [ObiCfg.DataWidth/8-1:0] be,
      input  logic [  ObiCfg.DataWidth-1:0] wdata,
      input  logic [    ObiCfg.IdWidth-1:0] aid,
      input  obi_a_optional_t               a_optional,
      output logic [  ObiCfg.DataWidth-1:0] r_rdata,
      output logic [    ObiCfg.IdWidth-1:0] r_rid,
      output logic                          r_err,
      output obi_r_optional_t               r_optional
    );
      this.drv.send_a(addr, 1'b1, be, wdata, aid, a_optional);
      this.drv.recv_r(r_rdata, r_rid, r_err, r_optional);
    endtask

    task automatic read(
      input  addr_t                       addr,
      input  logic [  ObiCfg.IdWidth-1:0] aid,
      input  obi_a_optional_t             a_optional,
      output logic [ObiCfg.DataWidth-1:0] r_rdata,
      output logic [  ObiCfg.IdWidth-1:0] r_rid,
      output logic                        r_err,
      output obi_r_optional_t             r_optional
    );
      this.drv.send_a(addr, 1'b0, '1, '0, aid, a_optional);
      this.drv.recv_r(r_rdata, r_rid, r_err, r_optional);
    endtask

  endclass

  class obi_rand_subordinate #(
    // Obi Parameters
    parameter obi_cfg_t    ObiCfg           = ObiDefaultConfig,
    parameter type         obi_a_optional_t = logic,
    parameter type         obi_r_optional_t = logic,
    // Stimuli Parameters
    parameter time         TA               = 2ns,
    parameter time         TT               = 8ns,
    // Wait Parameters
    parameter int unsigned AMinWaitCycles   = 0,
    parameter int unsigned AMaxWaitCycles   = 100,
    parameter int unsigned RMinWaitCycles   = 0,
    parameter int unsigned RMaxWaitCycles   = 100
  );
    typedef obi_test::obi_driver #(
      .ObiCfg           ( ObiCfg           ),
      .obi_a_optional_t ( obi_a_optional_t ),
      .obi_r_optional_t ( obi_r_optional_t ),
      .TA               ( TA               ),
      .TT               ( TT               )
    ) obi_driver_t;

    typedef logic [ObiCfg.AddrWidth-1:0] addr_t;
    typedef logic [  ObiCfg.IdWidth-1:0] id_t;

    string       name;
    obi_driver_t drv;
    addr_t       a_queue[$];
    id_t         id_queue[$];
    logic        r_queue[$];

    function new(
      virtual OBI_BUS_DV #(
        .OBI_CFG          ( ObiCfg           ),
        .obi_a_optional_t ( obi_a_optional_t ),
        .obi_r_optional_t ( obi_r_optional_t )
      ) obi,
      input string name
    );
      this.drv  = new(obi);
      this.name = name;
      assert(ObiCfg.AddrWidth != 0) else $fatal(1, "ObiCfg.AddrWidth must be non-zero!");
      assert(ObiCfg.DataWidth != 0) else $fatal(1, "ObiCfg.DataWidth must be non-zero!");
    endfunction

    function void reset();
      drv.reset_subordinate();
    endfunction

    task automatic rand_wait(input int unsigned min, input int unsigned max);
      int unsigned rand_success, cycles;
      rand_success = std::randomize(cycles) with {
        cycles >= min;
        cycles <= max;
      };
      assert (rand_success) else $error("Failed to randomize wait cycles!");
      repeat (cycles) @(posedge this.drv.obi.clk_i);
    endtask

    task automatic recv_as();
      forever begin
        automatic addr_t                         a_addr;
        automatic logic [ObiCfg.DataWidth/8-1:0] a_be;
        automatic logic                          a_we;
        automatic logic [  ObiCfg.DataWidth-1:0] a_wdata;
        automatic logic [    ObiCfg.IdWidth-1:0] a_aid;
        automatic obi_a_optional_t               a_optional;

        this.drv.recv_a(a_addr, a_we, a_be, a_wdata, a_aid, a_optional);
        this.a_queue.push_back(a_addr);
        this.id_queue.push_back(a_aid);
      end
    endtask

    task automatic send_rs();
      forever begin
        automatic logic                        rand_success;
        automatic addr_t                       a_addr;
        automatic logic [ObiCfg.DataWidth-1:0] r_rdata;
        automatic logic [  ObiCfg.IdWidth-1:0] r_rid;
        automatic obi_r_optional_t             r_optional;

        wait (a_queue.size() > 0);
        wait (id_queue.size() > 0);

        a_addr = this.a_queue.pop_front();
        r_rid  = this.id_queue.pop_front();
        rand_success = std::randomize(r_rdata); assert(rand_success);
        rand_success = std::randomize(r_optional); assert(rand_success);
        this.drv.send_r(r_rdata, r_rid, r_optional);
      end
    endtask

    task automatic run();
      fork
        recv_as();
        send_rs();
      join
    endtask

  endclass

endpackage
