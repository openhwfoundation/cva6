// Copyright 2022 Thales DIS design services SAS
//
// Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
// You may obtain a copy of the License at https://solderpad.org/licenses/
//
// Original Author: Jean-Roch COULON - Thales

package cva6_config_pkg;

  localparam CVA6ConfigXlen = 32;

  localparam CVA6ConfigRvfiTrace = 1;

  localparam CVA6ConfigAxiIdWidth = 5;  // axi_pkg.sv
  localparam CVA6ConfigAxiAddrWidth = 64;  // axi_pkg.sv
  localparam CVA6ConfigAxiDataWidth = 64;  // axi_pkg.sv
  localparam CVA6ConfigDataUserWidth = 32;  // axi_pkg.sv

  localparam config_pkg::cva6_user_cfg_t cva6_cfg = '{
      XLEN: unsigned'(CVA6ConfigXlen),
      VLEN: unsigned'(32),
      FpgaEn: bit'(0),
      FpgaAlteraEn: bit'(0),
      TechnoCut: bit'(1),
      SuperscalarEn: bit'(0),
      NrCommitPorts: unsigned'(1),
      AxiAddrWidth: unsigned'(CVA6ConfigAxiAddrWidth),
      AxiDataWidth: unsigned'(CVA6ConfigAxiDataWidth),
      AxiIdWidth: unsigned'(CVA6ConfigAxiIdWidth),
      AxiUserWidth: unsigned'(CVA6ConfigDataUserWidth),
      NrLoadBufEntries: unsigned'(2),
      RVF: bit'(0),
      RVD: bit'(0),
      XF16: bit'(0),
      XF16ALT: bit'(0),
      XF8: bit'(0),
      RVA: bit'(0),
      RVB: bit'(1),
      ZKN: bit'(0),
      RVV: bit'(0),
      RVC: bit'(1),
      RVH: bit'(0),
      RVZCMT: bit'(1),
      RVZCB: bit'(1),
      RVZCMP: bit'(0),
      XFVec: bit'(0),
      CvxifEn: bit'(1),
      CoproType: config_pkg::COPRO_EXAMPLE,
      RVZiCond: bit'(0),
      RVZicntr: bit'(0),
      RVZifencei: bit'(1),
      RVZihpm: bit'(0),
      NrScoreboardEntries: unsigned'(4),
      PerfCounterEn: bit'(0),
      MmuPresent: bit'(0),
      RVS: bit'(0),
      RVU: bit'(0),
      SoftwareInterruptEn: bit'(0),
      HaltAddress: 64'h800,
      ExceptionAddress: 64'h808,
      RASDepth: unsigned'(2),
      BTBEntries: unsigned'(0),
      BHTEntries: unsigned'(32),
      DmBaseAddress: 64'h0,
      TvalEn: bit'(0),
      DirectVecOnly: bit'(1),
      NrPMPEntries: unsigned'(8),
      PMPCfgRstVal: {64{64'h0}},
      PMPAddrRstVal: {64{64'h0}},
      PMPEntryReadOnly: 64'd0,
      PMPNapotEn: bit'(0),
      NOCType: config_pkg::NOC_TYPE_AXI4_ATOP,
      NrNonIdempotentRules: unsigned'(0),
      NonIdempotentAddrBase: 1024'({64'b0, 64'b0}),
      NonIdempotentLength: 1024'({64'b0, 64'b0}),
      NrExecuteRegionRules: unsigned'(0),
      ExecuteRegionAddrBase: 1024'({64'h8000_0000, 64'h1_0000, 64'h0}),
      ExecuteRegionLength: 1024'({64'h40000000, 64'h10000, 64'h1000}),
      NrCachedRegionRules: unsigned'(1),
      CachedRegionAddrBase: 1024'({64'h8000_0000}),
      CachedRegionLength: 1024'({64'h40000000}),
      MaxOutstandingStores: unsigned'(7),
      DebugEn: bit'(0),
      AxiBurstWriteEn: bit'(0),
      IcacheByteSize: unsigned'(2048),
      IcacheSetAssoc: unsigned'(2),
      IcacheLineWidth: unsigned'(128),
      DCacheType: config_pkg::HPDCACHE_WT,
      DcacheByteSize: unsigned'(2048),
      DcacheSetAssoc: unsigned'(2),
      DcacheLineWidth: unsigned'(128),
      DcacheFlushOnFence: bit'(0),
      DcacheInvalidateOnFlush: bit'(0),
      DataUserEn: bit'(1),
      WtDcacheWbufDepth: int'(8),
      FetchUserWidth: unsigned'(32),
      FetchUserEn: bit'(1),
      InstrTlbEntries: int'(2),
      DataTlbEntries: int'(2),
      UseSharedTlb: bit'(1),
      SharedTlbDepth: int'(64),
      NrLoadPipeRegs: int'(0),
      NrStorePipeRegs: int'(0),
      DcacheIdWidth: int'(3),
      ObiVersion: int'(config_pkg::OBI_V1_6),
      PipelineOnly: bit'(1),
      NrStoreInFlight: unsigned'(0),
      DclsEn: bit'(0),
      DclsDelay : unsigned'(1),
      DclsCommonRegfile: bit'(0),
      DclsCommonBHT: bit'(0)
  };

endpackage
