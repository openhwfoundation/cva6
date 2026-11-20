// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Author: Samuel Riedel <sriedel@iis.ee.ethz.ch>
// Author: Michael Rogenmoser <michaero@iis.ee.ethz.ch>

`include "obi/typedef.svh"
`include "obi/assign.svh"

module tb_obi_atop_resolver;
  import obi_pkg::*;

  localparam int unsigned MaxTimeout = 10000;

  localparam int unsigned NumManagers = 32'd10;
  localparam int unsigned NumMaxTrans = 32'd8;
  localparam int unsigned AddrWidth = 32;
  localparam int unsigned DataWidth = 32;
  localparam int unsigned MgrIdWidth = 5;
  localparam int unsigned SbrIdWidth = MgrIdWidth+$clog2(NumManagers);
  localparam int unsigned AUserWidth = 4;
  localparam int unsigned WUserWidth = 2;
  localparam int unsigned RUserWidth = 3;

  localparam time CyclTime = 10ns;
  localparam time ApplTime =  2ns;
  localparam time TestTime =  8ns;

  localparam obi_pkg::obi_cfg_t MgrConfig = '{
    UseRReady:      1'b0,
    CombGnt:        1'b0,
    AddrWidth: AddrWidth,
    DataWidth: DataWidth,
    IdWidth:  MgrIdWidth,
    Integrity:      1'b0,
    BeFull:         1'b1,
    OptionalCfg: '{
      UseAtop:          1'b1,
      UseMemtype:       1'b0,
      UseProt:          1'b0,
      UseDbg:           1'b0,
      AUserWidth: AUserWidth,
      WUserWidth: WUserWidth,
      RUserWidth: RUserWidth,
      MidWidth:            0,
      AChkWidth:           0,
      RChkWidth:           0
    }
  };
  `OBI_TYPEDEF_ALL_A_OPTIONAL(mgr_a_optional_t, AUserWidth, WUserWidth, 0, 0)
  `OBI_TYPEDEF_ALL_R_OPTIONAL(mgr_r_optional_t, RUserWidth, 0)
  typedef obi_test::obi_rand_manager #(
    .ObiCfg           ( MgrConfig ),
    .obi_a_optional_t ( mgr_a_optional_t ),
    .obi_r_optional_t ( mgr_r_optional_t ),
    .TA ( ApplTime ),
    .TT ( TestTime ),
    .MinAddr (32'h0000_0000),
    .MaxAddr (32'h0001_3000)
  ) rand_manager_t;

  localparam obi_pkg::obi_cfg_t MgrMuxedConfig = '{
    UseRReady:      1'b0,
    CombGnt:        1'b0,
    AddrWidth: AddrWidth,
    DataWidth: DataWidth,
    IdWidth:  SbrIdWidth,
    Integrity:      1'b0,
    BeFull:         1'b1,
    OptionalCfg: '{
      UseAtop:          1'b1,
      UseMemtype:       1'b0,
      UseProt:          1'b0,
      UseDbg:           1'b0,
      AUserWidth: AUserWidth,
      WUserWidth: WUserWidth,
      RUserWidth: RUserWidth,
      MidWidth:            0,
      AChkWidth:           0,
      RChkWidth:           0
    }
  };


  localparam obi_pkg::obi_cfg_t SbrConfig = '{
    UseRReady:      1'b0,
    CombGnt:        1'b0,
    AddrWidth: AddrWidth,
    DataWidth: DataWidth,
    IdWidth:  SbrIdWidth,
    Integrity:      1'b0,
    BeFull:         1'b1,
    OptionalCfg: '{
      UseAtop:          1'b0,
      UseMemtype:       1'b0,
      UseProt:          1'b0,
      UseDbg:           1'b0,
      AUserWidth: AUserWidth,
      WUserWidth: WUserWidth,
      RUserWidth: RUserWidth,
      MidWidth:            0,
      AChkWidth:           0,
      RChkWidth:           0
    }
  };
  `OBI_TYPEDEF_ALL_A_OPTIONAL(sbr_a_optional_t, AUserWidth, WUserWidth, 0, 0)
  `OBI_TYPEDEF_ALL_R_OPTIONAL(sbr_r_optional_t, RUserWidth, 0)

  logic clk, rst_n;
  logic [NumManagers-1:0] end_of_sim;
  int unsigned num_errors = 0;

  OBI_BUS_DV #(
    .OBI_CFG          ( MgrConfig ),
    .obi_a_optional_t ( mgr_a_optional_t ),
    .obi_r_optional_t ( mgr_r_optional_t )
  ) mgr_bus_dv [NumManagers] (
    .clk_i  ( clk   ),
    .rst_ni ( rst_n )
  );
  OBI_BUS #(
    .OBI_CFG          ( MgrConfig ),
    .obi_a_optional_t ( mgr_a_optional_t ),
    .obi_r_optional_t ( mgr_r_optional_t )
  ) mgr_bus [NumManagers] ();

  OBI_BUS #(
    .OBI_CFG          ( MgrMuxedConfig ),
    .obi_a_optional_t ( mgr_a_optional_t ),
    .obi_r_optional_t ( mgr_r_optional_t )
  ) mgr_bus_muxed ();

  rand_manager_t obi_rand_managers[NumManagers];

  for (genvar i = 0; i < NumManagers; i++) begin : gen_mgr_drivers
    initial begin
      obi_rand_managers[i] = new ( mgr_bus_dv[i], $sformatf("MGR_%0d",i));
      end_of_sim[i] <= 1'b0;
      obi_rand_managers[i].reset();

    end

    `OBI_ASSIGN(mgr_bus[i], mgr_bus_dv[i], MgrConfig, MgrConfig)
  end

  OBI_BUS #(
    .OBI_CFG          ( SbrConfig ),
    .obi_a_optional_t ( sbr_a_optional_t ),
    .obi_r_optional_t ( sbr_r_optional_t )
  ) sbr_bus ();

  OBI_ATOP_MONITOR_BUS #(
    .DataWidth ( DataWidth  ),
    .AddrWidth ( AddrWidth  ),
    .IdWidth   ( SbrIdWidth ),
    .UserWidth ( AUserWidth )
  ) mem_monitor_dv (
    .clk_i ( clk )
  );

  clk_rst_gen #(
    .ClkPeriod    ( CyclTime ),
    .RstClkCycles ( 5        )
  ) i_clk_gen (
    .clk_o  ( clk   ),
    .rst_no ( rst_n )
  );

  obi_mux_intf #(
    .SbrPortObiCfg   ( MgrConfig      ),
    .MgrPortObiCfg   ( MgrMuxedConfig ),
    .NumSbrPorts     ( NumManagers    ),
    .NumMaxTrans     ( 2              ),
    .UseIdForRouting ( 1'b0           )
  ) i_obi_mux (
    .clk_i      ( clk           ),
    .rst_ni     ( rst_n         ),
    .testmode_i ( 1'b0          ),
    .sbr_ports  ( mgr_bus       ),
    .mgr_port   ( mgr_bus_muxed )
  );

  obi_atop_resolver_intf #(
    .SbrPortObiCfg ( MgrMuxedConfig ),
    .MgrPortObiCfg ( SbrConfig      ),
    .LrScEnable    ( 1              ),
    .RegisterAmo   ( 1'b0           )
  ) i_atop_resolver (
    .clk_i      ( clk           ),
    .rst_ni     ( rst_n         ),
    .testmode_i ( '0            ),
    .sbr_port   ( mgr_bus_muxed ),
    .mgr_port   ( sbr_bus       )
  );

  obi_sim_mem_intf #(
    .ObiCfg            ( SbrConfig ),
    .ClearErrOnAccess  ( 1'b0      ),
    .WarnUninitialized ( 1'b0      ),
    .ApplDelay         ( ApplTime  ),
    .AcqDelay          ( TestTime  )
  ) i_sim_mem (
    .clk_i       ( clk                  ),
    .rst_ni      ( rst_n                ),
    .obi_sbr     ( sbr_bus              ),
    .mon_valid_o ( mem_monitor_dv.valid ),
    .mon_we_o    ( mem_monitor_dv.we    ),
    .mon_addr_o  ( mem_monitor_dv.addr  ),
    .mon_wdata_o ( mem_monitor_dv.data  ),
    .mon_be_o    ( mem_monitor_dv.be    ),
    .mon_id_o    ( mem_monitor_dv.id    )
  );

  atop_golden_mem_pkg::atop_golden_mem #(
    .ObiAddrWidth ( AddrWidth           ),
    .ObiDataWidth ( DataWidth           ),
    .ObiIdWidthM  ( MgrIdWidth          ),
    .ObiIdWidthS  ( SbrIdWidth          ),
    .ObiUserWidth ( AUserWidth          ),
    .NumMgrWidth  ( $clog2(NumManagers) ),
    .ApplDelay    ( ApplTime            ),
    .AcqDelay     ( TestTime            )
  ) golden_memory = new(mem_monitor_dv);
  assign mem_monitor_dv.user = '0;

  /*====================================================================
  =                                Main                                =
  ====================================================================*/

  initial begin
    wait (rst_n);
    @(posedge clk);

    // Run tests!
    test_all_amos();
    test_same_address();
    test_amo_write_consistency();
    // // test_interleaving();
    test_atomic_counter();
    // random_amo();
    // overtake_r();
    test_lr_sc();

    end_of_sim <= '1;
  end

  /*====================================================================
  =                               Timeout                              =
  ====================================================================*/

  initial begin
    automatic int unsigned timeout = 0;
    automatic logic [1:0] handshake = 2'b00;

    @(posedge clk);
    wait (rst_n);

    fork
      while (timeout < MaxTimeout) begin
        handshake = {sbr_bus.req, sbr_bus.gnt};
        @(posedge clk);
        if (handshake != {sbr_bus.req, sbr_bus.gnt}) begin
          timeout = 0;
        end else begin
          timeout += 1;
        end
      end
      wait (&end_of_sim);
    join_any

    if (&end_of_sim && num_errors == 0) begin
        $display("\nSUCCESS\n");
    end else if (&end_of_sim) begin
        $display("\nFINISHED\n");
        if (num_errors > 0) begin
            $fatal(1, "Encountered %d errors.", num_errors);
        end else begin
            $display("All tests passed.");
        end
    end else begin
        $fatal(1, "TIMEOUT");
    end

    $stop;
  end

  /*====================================================================
  =                         Hand crafted tests                         =
  ====================================================================*/

  task automatic test_all_amos();

    automatic logic [AddrWidth-1:0] address;
    automatic logic [DataWidth-1:0] data_init;
    automatic logic [DataWidth-1:0] data_amo;
    automatic atop_t                atop;

    $display("%t - Test all possible amos with a single thread...\n", $realtime);

    for (int j = 0; j < 9; j++) begin
      // Go through standard AMOs
      if (j == 0) atop = AMOSWAP;
      if (j == 1) atop = AMOADD;
      if (j == 2) atop = AMOXOR;
      if (j == 3) atop = AMOAND;
      if (j == 4) atop = AMOOR;
      if (j == 5) atop = AMOMIN;
      if (j == 6) atop = AMOMAX;
      if (j == 7) atop = AMOMINU;
      if (j == 8) atop = AMOMAXU;

      assert (randomize(address));
      assert (randomize(data_init));
      assert (randomize(data_amo));

      write_amo_read_cycle(0, address, data_init, data_amo, 0, 0, atop);

    end

  endtask

  // Test if the adapter protects the atomic region correctly
  task automatic test_same_address();
    parameter int unsigned          NumIterations = 64;
    parameter logic [AddrWidth-1:0] Address       = 'h01004000;

    automatic logic [ AddrWidth-1:0] address         = Address;
    automatic logic [ DataWidth-1:0] rdata_init;
    automatic logic [MgrIdWidth-1:0] rid_init;
    automatic logic                  err_init;
    automatic mgr_r_optional_t       r_optional_init;
    automatic logic [ DataWidth-1:0] exp_data_init;
    automatic logic                  exp_err_init;
    automatic logic                  exp_exokay_init;

    $display("%t - Test random accesses to the same memory location...\n", $realtime);

    // Initialize memory with 0
    fork
      obi_rand_managers[0].write(address, '1, '0, '0, '0, rdata_init, rid_init, err_init,
                                 r_optional_init);
      golden_memory.write(address, '0, '1, '0, 0, '0, exp_data_init, exp_err_init,
                          exp_exokay_init);
    join

    for (int i = 0; i < NumManagers; i++) begin
      automatic int                    m          = i;
      automatic logic [MgrIdWidth-1:0] id;
      automatic logic [SbrIdWidth-1:0] s_id;
      automatic logic [ DataWidth-1:0] wdata;
      automatic mgr_a_optional_t       a_optional;
      automatic logic [ DataWidth-1:0] rdata;
      automatic logic [ DataWidth-1:0] exp_data;
      automatic logic [MgrIdWidth-1:0] rid;
      automatic logic [MgrIdWidth-1:0] exp_rid;
      automatic logic                  err;
      automatic logic                  exp_err;
      automatic mgr_r_optional_t       r_optional;
      automatic logic                  exp_exokay;
      automatic atop_t                 atop;

      fork
        for (int j = 0; j < NumIterations; j++) begin
          assert (randomize(id));
          assert (randomize(wdata));
          do begin
            assert (randomize(atop));
          end while (!(obi_atop_e'(atop) inside {AMOSWAP, AMOADD, AMOXOR, AMOAND, AMOOR, AMOMIN,
                                                 AMOMAX, AMOMINU, AMOMAXU, ATOPNONE}));
          a_optional.atop = atop;
          fork
            obi_rand_managers[m].write(address, '1, wdata, id, a_optional, rdata, rid, err,
                                       r_optional);
            golden_memory.write(address, wdata, '1, id, m, atop, exp_data, exp_err, exp_exokay);
          join
          assert (err == exp_err && r_optional.exokay == exp_exokay) else begin
            $warning("%t - Response codes did not match! got: 0x%b, exp: 0x%b", $realtime,
                     {err, r_optional.exokay}, {exp_err, exp_exokay});
            num_errors += 1;
          end
          if (atop != ATOPNONE) begin
            assert (rdata == exp_data) else begin
              $warning("%t - ATOP data did not match! got: 0x%x, exp: 0x%x with op 0x%x",
                       $realtime, rdata, exp_data, atop);
              num_errors += 1;
            end
          end
        end
      join_none
    end

    wait fork;

    #1000ns;

  endtask

  // Test if the adapter protects the atomic region correctly
  task automatic test_amo_write_consistency();
    parameter int unsigned          NumIterations = 64;
    parameter logic [AddrWidth-1:0] Address       = 'h01004000;

    automatic logic [ AddrWidth-1:0] address         = Address;

    $display("%t - Test write consistency...\n", $realtime);

    // Initialize to 0
    write_amo_read_cycle(0, address, '0, '0, '0, 0, '0);

    for (int i = 0; i < NumManagers; i++) begin
      automatic int m = i;
      automatic logic [MgrIdWidth-1:0] id;
      automatic logic [ DataWidth-1:0] data;
      automatic logic [ DataWidth-1:0] data_amo;
      automatic atop_t                 atop;

      fork
        for (int j = 0; j < NumIterations; j++) begin
          do begin
            assert (randomize(atop));
          end while (!(obi_atop_e'(atop) inside {AMOSWAP, AMOADD, AMOXOR, AMOAND, AMOOR, AMOMIN,
                                                 AMOMAX, AMOMINU, AMOMAXU, ATOPNONE}));
          assert (randomize(data));
          assert (randomize(data_amo));
          assert (randomize(id));

          write_amo_read_cycle(m, address, data, data_amo, id, 0, atop);
        end
      join_none
    end

    wait fork;


  endtask

  // Test multiple atomic accesses to the same address
  task automatic test_atomic_counter();
    parameter int unsigned          NumIterations = 64;
    parameter logic [AddrWidth-1:0] Address       = 'h01002000;

    automatic logic [ AddrWidth-1:0] address    = Address;
    automatic logic [ DataWidth-1:0] rdata;
    automatic logic [MgrIdWidth-1:0] rid;
    automatic logic                  err;
    automatic mgr_r_optional_t       r_optional;

    $display("%t - Test atomic counter...\n", $realtime);

    // Initialize to 0
    obi_rand_managers[0].write(address, '1, '0, '0, '0, rdata, rid, err, r_optional);

    for (int i = 0; i < NumManagers; i++) begin
      automatic int m = i;
      fork
        for (int j = 0; j < NumIterations; j++) begin
          obi_rand_managers[m].write(address, '1, 1, '0, '{atop: AMOADD, default: '0}, rdata, rid,
                                     err, r_optional);
        end
      join_none
    end

    wait fork;

    obi_rand_managers[0].read(address, '0, '0, rdata, rid, err, r_optional);

    if (rdata == NumIterations*NumManagers) begin
      $display("%t - Adder result correct: %d", $realtime, rdata);
    end else begin
      $display("%t - Adder result wrong: %d (Expected: %d)", $realtime, rdata,
               NumIterations*NumManagers);
      num_errors += 1;
    end

  endtask

  // Test LR/SC accesses
  task automatic test_lr_sc();
    automatic logic [ AddrWidth-1:0] address;
    automatic logic [ AddrWidth-1:0] address_2;
    automatic logic [ DataWidth-1:0] data;
    automatic logic [ DataWidth-1:0] data_2;
    automatic logic [MgrIdWidth-1:0] trans_id;
    automatic mgr_a_optional_t       a_optional = '0;
    automatic logic [ DataWidth-1:0] rdata;
    automatic logic [MgrIdWidth-1:0] rid;
    automatic logic                  err;
    automatic mgr_r_optional_t       r_optional;

    $display("%t - Test LR/SC...\n", $realtime);

    // SC without acquiring lock -> !exokay
    ///////////////////////////////////////
    assert (randomize(address));
    address[$clog2(DataWidth/8)-1:0] = '0;
    assert (randomize(data));
    assert (randomize(trans_id));
    // Initialize address
    obi_rand_managers[0].write(address, '1, '0, trans_id, a_optional, rdata, rid, err, r_optional);

    a_optional.atop = ATOPSC;
    obi_rand_managers[0].write(address, '1, data, trans_id, a_optional, rdata, rid, err,
                               r_optional);

    assert (r_optional.exokay == 1'b0 && rdata != '0) else begin
      $warning("%t - SC without LR returned exokay", $realtime);
      num_errors += 1;
    end

    // Ensure SC did not store
    a_optional.atop = ATOPNONE;
    obi_rand_managers[0].read(address, trans_id, a_optional, rdata, rid, err, r_optional);
    assert (rdata == '0 && rdata != data) else begin
      $warning("%t - SC without LR stored data 0x%x", $realtime, rdata);
      num_errors += 1;
    end

    // LR/SC sequence -> exokay
    ///////////////////////////
    assert (randomize(address));
    address[$clog2(DataWidth/8)-1:0] = '0;
    assert (randomize(trans_id));
    // Initialize address
    obi_rand_managers[0].write(address, '1, '0, trans_id, a_optional, rdata, rid, err, r_optional);

    a_optional.atop = ATOPLR;
    obi_rand_managers[0].read(address, trans_id, a_optional, rdata, rid, err, r_optional);

    assert (r_optional.exokay == 1'b1) else begin
      $warning("%t - LR did not return exokay", $realtime);
      num_errors += 1;
    end

    assert (randomize(data));
    a_optional.atop = ATOPSC;
    obi_rand_managers[0].write(address, '1, data, trans_id, a_optional, rdata, rid, err,
                               r_optional);

    assert (r_optional.exokay == 1'b1) else begin
      $warning("%t - SC with LR did not return exokay", $realtime);
      num_errors += 1;
    end

    // Ensure SC did store
    a_optional.atop = ATOPNONE;
    obi_rand_managers[0].read(address, trans_id, a_optional, rdata, rid, err, r_optional);
    assert (rdata == data) else begin
      $warning("%t - SC with LR did not store data", $realtime);
      num_errors += 1;
    end

    // LR then different SC -> !exokay
    //////////////////////////////////
    assert (randomize(address));
    address[$clog2(DataWidth/8)-1:0] = '0;
    assert (randomize(trans_id));
    // Initialize address
    obi_rand_managers[0].write(address, '1, '0, trans_id, a_optional, rdata, rid, err, r_optional);

    a_optional.atop = ATOPLR;
    obi_rand_managers[0].read(address, trans_id, a_optional, rdata, rid, err, r_optional);

    assert (r_optional.exokay == 1'b1) else begin
      $warning("%t - LR did not return exokay", $realtime);
      num_errors += 1;
    end

    do begin
      assert (randomize(address_2));
      address_2[$clog2(DataWidth/8)-1:0] = '0;
    end while (address_2 == address);
    assert (randomize(data));
    a_optional.atop = ATOPSC;
    obi_rand_managers[0].write(address_2, '1, data, trans_id, a_optional, rdata, rid, err,
                               r_optional);

    assert (r_optional.exokay == 1'b0) else begin
      $warning("%t - SC with LR to different address returned exokay", $realtime);
      num_errors += 1;
    end

    // LR, other core store, SC -> !exokay
    //////////////////////////////////////
    assert (randomize(address));
    address[$clog2(DataWidth/8)-1:0] = '0;
    assert (randomize(trans_id));
    // Initialize address
    obi_rand_managers[0].write(address, '1, '0, trans_id, a_optional, rdata, rid, err, r_optional);

    a_optional.atop = ATOPLR;
    obi_rand_managers[0].read(address, trans_id, a_optional, rdata, rid, err, r_optional);

    assert (r_optional.exokay == 1'b1) else begin
      $warning("%t - LR did not return exokay", $realtime);
      num_errors += 1;
    end

    assert (randomize(data));
    a_optional.atop = ATOPNONE;
    obi_rand_managers[1].write(address, '1, data, trans_id, a_optional, rdata, rid, err,
                               r_optional);

    assert (randomize(data_2));
    a_optional.atop = ATOPSC;
    obi_rand_managers[0].write(address, '1, data_2, trans_id, a_optional, rdata, rid, err,
                               r_optional);

    assert (r_optional.exokay == 1'b0) else begin
      $warning("%t - SC with LR and injected store returned exokay", $realtime);
      num_errors += 1;
    end

    // Ensure SC did not store
    a_optional.atop = ATOPNONE;
    obi_rand_managers[0].read(address, trans_id, a_optional, rdata, rid, err, r_optional);
    assert (rdata == data && rdata != data_2) else begin
      $warning("%t - SC without LR stored data (stored: 0x%x, SC: 0x%x, rdata: 0x%x)", $realtime,
               data, data_2, rdata);
      num_errors += 1;
    end

  endtask


  /*====================================================================
  =                          Helper Functions                          =
  ====================================================================*/

  task automatic write_amo_read_cycle(
    input int unsigned           driver,
    input logic [ AddrWidth-1:0] address,
    input logic [ DataWidth-1:0] data_init,
    input logic [ DataWidth-1:0] data_amo,
    input logic [MgrIdWidth-1:0] id,
    input logic [AUserWidth-1:0] user,
    input atop_t                 atop
  );

    automatic logic [MgrIdWidth-1:0] trans_id = id;
    automatic logic [ DataWidth-1:0] rdata;
    automatic logic [ DataWidth-1:0] exp_data;
    automatic logic [ DataWidth-1:0] act_data;
    automatic logic                  err;
    automatic logic                  exokay;
    automatic logic                  exp_err;
    automatic logic                  exp_exokay;
    automatic logic [MgrIdWidth-1:0] rid;
    automatic mgr_a_optional_t       a_optional = '0;
    automatic mgr_r_optional_t       r_optional;

    a_optional.atop = '0;
    exokay = r_optional.exokay;

    if (!id) begin
      assert (randomize(trans_id));
    end
    // Preload data
    fork
      obi_rand_managers[driver].write(address, '1, data_init, trans_id, a_optional, rdata, rid,
                                      err, r_optional);
      golden_memory.write(address, data_init, '1, trans_id, driver, '0, exp_data, exp_err,
                          exp_exokay);
    join
    if (!id) begin
      assert (randomize(trans_id));
    end
    // Execute AMO
    a_optional.atop = atop;
    fork
      obi_rand_managers[driver].write(address, '1, data_amo, trans_id, a_optional, rdata, rid, err,
                                      r_optional);
      golden_memory.write(address, data_amo, '1, trans_id, driver, atop, exp_data, exp_err,
                          exp_exokay);
    join
    exokay = r_optional.exokay;
    assert (err == exp_err && exokay == exp_exokay) else begin
      $warning("%t - Response codes did not match! got: 0x%b, exp: 0x%b", $realtime, {err, exokay},
               {exp_err, exp_exokay});
      num_errors += 1;
    end
    if (atop != '0) begin
      assert (rdata == exp_data) else begin
        $warning("%t - ATOP data did not match! got: 0x%x, exp: 0x%x at addr: 0x%x with op 0x%x",
                 $realtime, rdata, exp_data, address, atop);
        num_errors += 1;
      end
    end
    if (!id) begin
      assert (randomize(trans_id));
    end
    // Check stored data
    a_optional.atop = '0;
    fork
      obi_rand_managers[driver].read(address, trans_id, a_optional, act_data, rid, err, r_optional);
      golden_memory.read(address, trans_id, driver, '0, exp_data, exp_err, exp_exokay);
    join
    assert(act_data == exp_data) else begin
      $warning("%t - Stored data did not match! got: 0x%x, exp: 0x%x at addr: 0x%x with op 0x%x",
               $realtime, act_data, exp_data, address, atop);
      num_errors += 1;
    end

  endtask

endmodule
