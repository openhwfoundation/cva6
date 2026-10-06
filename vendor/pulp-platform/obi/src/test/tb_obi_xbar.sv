// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Michael Rogenmoser <michaero@iis.ee.ethz.ch>

`include "obi/typedef.svh"
`include "obi/assign.svh"

module tb_obi_xbar;

  localparam int unsigned NumManagers = 32'd6;
  localparam int unsigned NumSubordinates = 32'd8;
  localparam bit          UseIdForRouting = 1'b0;

  localparam int unsigned NumMaxTrans = 32'd8;
  localparam int unsigned AddrWidth = 32;
  localparam int unsigned DataWidth = 32;
  localparam int unsigned MgrIdWidth = 5;
  localparam int unsigned SbrIdWidth = MgrIdWidth+cf_math_pkg::idx_width(NumManagers);
  localparam int unsigned AUserWidth = 4;
  localparam int unsigned WUserWidth = 2;
  localparam int unsigned RUserWidth = 3;

  // TODO CHK!

  localparam int unsigned NumRequests = 32'd10000;

  localparam time CyclTime = 10ns;
  localparam time ApplTime =  2ns;
  localparam time TestTime =  8ns;

  localparam obi_pkg::obi_cfg_t MgrConfig = '{
    UseRReady:      1'b1,
    CombGnt:        1'b0,
    AddrWidth: AddrWidth,
    DataWidth: DataWidth,
    IdWidth:  MgrIdWidth,
    Integrity:      1'b0,
    BeFull:         1'b1,
    OptionalCfg: '{
      UseAtop:          1'b1,
      UseMemtype:       1'b1,
      UseProt:          1'b1,
      UseDbg:           1'b1,
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

  localparam obi_pkg::obi_cfg_t SbrConfig = '{
    UseRReady:      1'b1,
    CombGnt:        1'b0,
    AddrWidth: AddrWidth,
    DataWidth: DataWidth,
    IdWidth:  SbrIdWidth,
    Integrity:      1'b0,
    BeFull:         1'b1,
    OptionalCfg: '{
      UseAtop:          1'b1,
      UseMemtype:       1'b1,
      UseProt:          1'b1,
      UseDbg:           1'b1,
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

  typedef obi_test::obi_rand_subordinate #(
    .ObiCfg ( SbrConfig ),
    .obi_a_optional_t ( sbr_a_optional_t ),
    .obi_r_optional_t ( sbr_r_optional_t ),
    .TA ( ApplTime ),
    .TT ( TestTime )
  ) rand_subordinate_t;

  localparam int unsigned NumRules = 8;
  typedef struct packed {
    int unsigned idx;
    logic [AddrWidth-1:0] start_addr;
    logic [AddrWidth:0] end_addr;
  } rule_t;

  localparam rule_t [NumRules-1:0] AddrMap = '{
    '{idx: 32'd7, start_addr: 32'h0001_0000, end_addr: 32'h0001_1000},
    '{idx: 32'd6, start_addr: 32'h0000_9000, end_addr: 32'h0001_0000},
    '{idx: 32'd5, start_addr: 32'h0000_8000, end_addr: 32'h0000_9000},
    '{idx: 32'd4, start_addr: 32'h0000_7000, end_addr: 32'h0000_8000},
    '{idx: 32'd3, start_addr: 32'h0000_6300, end_addr: 32'h0000_7000},
    '{idx: 32'd2, start_addr: 32'h0000_4000, end_addr: 32'h0000_6300},
    '{idx: 32'd1, start_addr: 32'h0000_3000, end_addr: 32'h0000_4000},
    '{idx: 32'd0, start_addr: 32'h0000_0000, end_addr: 32'h0000_3000}
  };

  logic clk, rst_n;
  logic [NumManagers-1:0] end_of_sim;

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

  for (genvar i = 0; i < NumManagers; i++) begin : gen_mgr_drivers
    initial begin
      automatic rand_manager_t obi_rand_manager = new ( mgr_bus_dv[i], $sformatf("MGR_%0d",i));
      automatic logic [  MgrConfig.DataWidth-1:0] r_rdata    = '0;
      automatic logic [    MgrConfig.IdWidth-1:0] r_rid      = '0;
      automatic logic                             r_err      = '0;
      automatic mgr_r_optional_t                  r_optional = '0;
      end_of_sim[i] <= 1'b0;
      obi_rand_manager.reset();
      @(posedge rst_n);
      obi_rand_manager.write(32'h0000_1100, 4'hF, 32'hDEAD_BEEF, 2,
                             '{auser: '0,
                               wuser: '0,
                               atop: '0,
                               memtype: obi_pkg::memtype_t'('0),
                               mid: '0,
                               prot: obi_pkg::prot_t'('0),
                               dbg: '0,
                               achk: '0}, r_rdata, r_rid, r_err, r_optional);
      obi_rand_manager.read(32'h0000_e100, 2, '{auser: '0,
                                                wuser: '0,
                                                atop: '0,
                                                memtype: obi_pkg::memtype_t'('0),
                                                mid: '0,
                                                prot: obi_pkg::prot_t'('0),
                                                dbg: '0,
                                                achk: '0}, r_rdata, r_rid, r_err, r_optional);
      obi_rand_manager.run(NumRequests);
      end_of_sim[i] <= 1'b1;
    end

    `OBI_ASSIGN(mgr_bus[i], mgr_bus_dv[i], MgrConfig, MgrConfig)
  end

  OBI_BUS_DV #(
    .OBI_CFG          ( SbrConfig ),
    .obi_a_optional_t ( sbr_a_optional_t ),
    .obi_r_optional_t ( sbr_r_optional_t )
  ) sbr_bus_dv [NumSubordinates] (
    .clk_i  ( clk   ),
    .rst_ni ( rst_n )
  );
  OBI_BUS #(
    .OBI_CFG          ( SbrConfig ),
    .obi_a_optional_t ( sbr_a_optional_t ),
    .obi_r_optional_t ( sbr_r_optional_t )
  ) sbr_bus [NumSubordinates] ();

  for (genvar i = 0; i < NumSubordinates; i++) begin : gen_sbr_drivers
    initial begin
      automatic rand_subordinate_t obi_rand_subordinate =
        new ( sbr_bus_dv[i], $sformatf("SBR_%0d",i));
      obi_rand_subordinate.reset();
      @(posedge rst_n);
      obi_rand_subordinate.run();
    end

    `OBI_ASSIGN(sbr_bus_dv[i], sbr_bus[i], SbrConfig, SbrConfig)
  end

  clk_rst_gen #(
    .ClkPeriod    ( CyclTime ),
    .RstClkCycles ( 5        )
  ) i_clk_gen (
    .clk_o  ( clk   ),
    .rst_no ( rst_n )
  );

  // DUT
  obi_xbar_intf #(
    .SbrPortObiCfg   ( MgrConfig       ),
    .MgrPortObiCfg   ( SbrConfig       ),
    .NumSbrPorts     ( NumManagers     ),
    .NumMgrPorts     ( NumSubordinates ),
    .NumMaxTrans     ( NumMaxTrans     ),
    .NumAddrRules    ( NumRules        ),
    .addr_map_rule_t ( rule_t          ),
    .UseIdForRouting ( UseIdForRouting )
  ) i_dut (
    .clk_i            ( clk     ),
    .rst_ni           ( rst_n   ),
    .testmode_i       ( 1'b0    ),
    .sbr_ports        ( mgr_bus ),
    .mgr_ports        ( sbr_bus ),
    .addr_map_i       ( AddrMap ),
    .en_default_idx_i ( '0 ),
    .default_idx_i    ( '0 )
  );

  initial begin
    wait(&end_of_sim);
    repeat (1000) @(posedge clk);
    $display("Simulation stopped as all Masters transferred their data, Success.",);
    $stop();
  end

endmodule
