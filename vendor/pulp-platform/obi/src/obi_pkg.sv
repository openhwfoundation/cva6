// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Michael Rogenmoser <michaero@iis.ee.ethz.ch>

package obi_pkg;

  /// The OBI atomics type, to be expanded.
  typedef logic [5:0] atop_t;

  /// The OBI memtype type, to be expanded.
  typedef logic [1:0] memtype_t;

  /// The OBI prot type, to be expanded.
  typedef logic [2:0] prot_t;

  localparam atop_t    DefaultAtop    = 6'b000000;
  localparam memtype_t DefaultMemtype = 2'b00;
  localparam prot_t    DefaultProt    = 3'b111;

  /// The config type for OBI bus optional fields.
  typedef struct packed {
    bit          UseAtop;
    bit          UseMemtype;
    bit          UseProt;
    bit          UseDbg;
    int unsigned AUserWidth;
    int unsigned WUserWidth;
    int unsigned RUserWidth;
    int unsigned MidWidth;
    int unsigned AChkWidth;
    int unsigned RChkWidth;
  } obi_optional_cfg_t;

  localparam obi_optional_cfg_t ObiMinimalOptionalConfig = '{
    UseAtop:    1'b0,
    UseMemtype: 1'b0,
    UseProt:    1'b0,
    UseDbg:     1'b0,
    AUserWidth:    0,
    WUserWidth:    0,
    RUserWidth:    0,
    MidWidth:      0,
    AChkWidth:     0,
    RChkWidth:     0
  };

  localparam obi_optional_cfg_t ObiAtopOptionalConfig = '{
    UseAtop:    1'b1,
    UseMemtype: 1'b0,
    UseProt:    1'b0,
    UseDbg:     1'b0,
    AUserWidth:    0,
    WUserWidth:    0,
    RUserWidth:    0,
    MidWidth:      0,
    AChkWidth:     0,
    RChkWidth:     0
  };

  function automatic obi_optional_cfg_t obi_all_optional_config(int unsigned AUserWidth,
      int unsigned WUserWidth, int unsigned RUserWidth, int unsigned MidWidth,
      int unsigned AChkWidth, int unsigned RChkWidth);
    obi_all_optional_config = '{
      UseAtop:          1'b1,
      UseMemtype:       1'b1,
      UseProt:          1'b1,
      UseDbg:           1'b1,
      AUserWidth: AUserWidth,
      WUserWidth: WUserWidth,
      RUserWidth: RUserWidth,
      MidWidth:     MidWidth,
      AChkWidth:   AChkWidth,
      RChkWidth:   RChkWidth
    };
  endfunction

  /// The OBI bus config type.
  typedef struct packed {
    bit          UseRReady;
    bit          CombGnt;
    int unsigned AddrWidth;
    int unsigned DataWidth;
    int unsigned IdWidth;
    bit          Integrity;
    bit          BeFull;
    obi_optional_cfg_t OptionalCfg;
  } obi_cfg_t;

  function automatic obi_cfg_t obi_default_cfg(int unsigned AddrWidth, int unsigned DataWidth,
    int unsigned IdWidth, obi_optional_cfg_t OptionalCfg);
    obi_default_cfg = '{
      UseRReady:          1'b0,
      CombGnt:            1'b0,
      AddrWidth:     AddrWidth,
      DataWidth:     DataWidth,
      IdWidth:         IdWidth,
      Integrity:          1'b0,
      BeFull:             1'b1,
      OptionalCfg: OptionalCfg
    };
  endfunction

  /// The default OBI bus config.
  localparam obi_cfg_t ObiDefaultConfig = obi_default_cfg(32, 32, 1, ObiMinimalOptionalConfig);

  function automatic obi_cfg_t mux_grow_cfg(obi_cfg_t ObiCfgIn, int unsigned NumManagers);
    mux_grow_cfg = '{
      UseRReady:   ObiCfgIn.UseRReady,
      CombGnt:     ObiCfgIn.CombGnt,
      AddrWidth:   ObiCfgIn.AddrWidth,
      DataWidth:   ObiCfgIn.DataWidth,
      IdWidth:     ObiCfgIn.IdWidth + cf_math_pkg::idx_width(NumManagers),
      Integrity:   ObiCfgIn.Integrity,
      BeFull:      ObiCfgIn.BeFull,
      OptionalCfg: ObiCfgIn.OptionalCfg
    };
  endfunction

  typedef enum atop_t {
    ATOPLR   = 6'h22,
    ATOPSC   = 6'h23,
    AMOSWAP  = 6'h21,
    AMOADD   = 6'h20,
    AMOXOR   = 6'h24,
    AMOAND   = 6'h2C,
    AMOOR    = 6'h28,
    AMOMIN   = 6'h30,
    AMOMAX   = 6'h34,
    AMOMINU  = 6'h38,
    AMOMAXU  = 6'h3C,
    ATOPNONE = 6'h0
  } obi_atop_e;

endpackage
