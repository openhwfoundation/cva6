package cva6_config_pkg;

  localparam CVA6ConfigXlen = 32;

  localparam CVA6ConfigFpuEn = 1;
  localparam CVA6ConfigF16En = 0;
  localparam CVA6ConfigF16AltEn = 0;
  localparam CVA6ConfigF8En = 0;
  localparam CVA6ConfigFVecEn = 0;

  localparam CVA6ConfigCvxifEn = 1;
  localparam CVA6ConfigCExtEn = 1;
  localparam CVA6ConfigZcbExtEn = 1;
  localparam CVA6ConfigZcmpExtEn = 0;
  localparam CVA6ConfigAExtEn = 1;
  localparam CVA6ConfigHExtEn = 0;  // always disabled
  localparam CVA6ConfigBExtEn = 1; // To be inserted in spec
  localparam CVA6ConfigVExtEn = 0;
  localparam CVA6ConfigRVZiCond = 0;

  localparam CVA6ConfigAxiIdWidth = 4;
  localparam CVA6ConfigAxiAddrWidth = 32;
  localparam CVA6ConfigAxiDataWidth = 64;
  localparam CVA6ConfigFetchUserEn = 0; // Not compatible with current implemention, set to DISABLED
  localparam CVA6ConfigFetchUserWidth = CVA6ConfigXlen; // Not compatible with current implemention, set to XLEN
  localparam CVA6ConfigDataUserEn = 0; // Not compatible with current implemention, DISABLED
  localparam CVA6ConfigDataUserWidth = CVA6ConfigXlen; // Not compatible with current implemention, set to XLEN

  localparam CVA6ConfigIcacheByteSize = 16384;
  localparam CVA6ConfigIcacheSetAssoc = 4;
  localparam CVA6ConfigIcacheLineWidth = 128;
  localparam CVA6ConfigDcacheByteSize = 32768; // To be inserted in spec
  localparam CVA6ConfigDcacheSetAssoc = 4;
  localparam CVA6ConfigDcacheLineWidth = 128; // To be inserted in spec

  localparam CVA6ConfigDcacheIdWidth = 1; // To be inserted in spec
  localparam CVA6ConfigMemTidWidth = 4; // To be inserted in spec

  localparam CVA6ConfigWtDcacheWbufDepth = 2;

  localparam CVA6ConfigNrCommitPorts = 2;
  localparam CVA6ConfigNrScoreboardEntries = 4;

  localparam CVA6ConfigFpgaEn = 0;

  localparam CVA6ConfigNrLoadPipeRegs = 0;
  localparam CVA6ConfigNrStorePipeRegs = 0;
  localparam CVA6ConfigNrLoadBufEntries = 2; // To be inserted in spec

  localparam CVA6ConfigInstrTlbEntries = 0; // To be inserted in spec
  localparam CVA6ConfigDataTlbEntries = 0; // To be inserted in spec

  localparam CVA6ConfigRASDepth = 2;
  localparam CVA6ConfigBTBEntries = 32;
  localparam CVA6ConfigBHTEntries = 128;

  localparam CVA6ConfigTvalEn = 0;

  localparam CVA6ConfigNrPMPEntries = 16;

  localparam CVA6ConfigPerfCounterEn = 1;

  localparam config_pkg::cache_type_t CVA6ConfigDcacheType = config_pkg::HPDCACHE;

  localparam CVA6ConfigMmuPresent = 0;
  localparam CVA6ConfigPmpPresent = 1;

  localparam CVA6ConfigRvfiTrace = 1; // To be inserted in spec
  
  
  localparam CVA6ConfigDataScrPresent = 1;
  localparam CVA6ConfigDataScrBase = 64'h20_0000;
  localparam CVA6ConfigDataScrSize = 64'h1_0000; // num of words, 256KB, 65536 words
  
  localparam CVA6ConfigInstrScrPresent = 1;
  localparam CVA6ConfigInstrScrBase = 64'h0;
  localparam CVA6ConfigInstrScrSize = 64'h8000; // num of words, 128KB, 32768 words
  
  localparam CVA6ConfigAHBPeriphPresent = 1;
  localparam CVA6ConfigAHBPeriphSystemBase = 64'h4000_0000;
  localparam CVA6ConfigAHBPeriphSystemSize = 64'h7000; // num of words
  localparam CVA6ConfigAHBPeriphPrivateBase = 64'hE000_0000;
  localparam CVA6ConfigAHBPeriphPrivateSize = 64'h400_1000; // num of words
  
  localparam config_pkg::cva6_user_cfg_t cva6_cfg = '{
      XLEN: unsigned'(CVA6ConfigXlen),
      FpgaEn: bit'(CVA6ConfigFpgaEn),
      NrCommitPorts: unsigned'(CVA6ConfigNrCommitPorts),
      AxiAddrWidth: unsigned'(CVA6ConfigAxiAddrWidth),
      AxiDataWidth: unsigned'(CVA6ConfigAxiDataWidth),
      AxiIdWidth: unsigned'(CVA6ConfigAxiIdWidth),
      AxiUserWidth: unsigned'(CVA6ConfigDataUserWidth),
      MemTidWidth: unsigned'(CVA6ConfigMemTidWidth),
      NrLoadBufEntries: unsigned'(CVA6ConfigNrLoadBufEntries),
      FpuEn: bit'(CVA6ConfigFpuEn),
      XF16: bit'(CVA6ConfigF16En),
      XF16ALT: bit'(CVA6ConfigF16AltEn),
      XF8: bit'(CVA6ConfigF8En),
      RVA: bit'(CVA6ConfigAExtEn),
      RVB: bit'(CVA6ConfigBExtEn),
      RVV: bit'(CVA6ConfigVExtEn),
      RVC: bit'(CVA6ConfigCExtEn),
      RVH: bit'(CVA6ConfigHExtEn),
      RVZCB: bit'(CVA6ConfigZcbExtEn),
      RVZCMP: bit'(CVA6ConfigZcmpExtEn),
      XFVec: bit'(CVA6ConfigFVecEn),
      CvxifEn: bit'(CVA6ConfigCvxifEn),
      RVZiCond: bit'(CVA6ConfigRVZiCond),
      NrScoreboardEntries: unsigned'(CVA6ConfigNrScoreboardEntries),
      RVS: bit'(0),
      RVU: bit'(0),
      HaltAddress: 64'h800,
      ExceptionAddress: 64'h808,
      RASDepth: unsigned'(CVA6ConfigRASDepth),
      BTBEntries: unsigned'(CVA6ConfigBTBEntries),
      BHTEntries: unsigned'(CVA6ConfigBHTEntries),
      DmBaseAddress: 64'hF0000000,
      TvalEn: bit'(CVA6ConfigTvalEn),
      NrPMPEntries: unsigned'(CVA6ConfigNrPMPEntries),
      PMPCfgRstVal: {16{64'h0}},
      PMPAddrRstVal: {16{64'h0}},
      PMPEntryReadOnly: 16'd0,
      NOCType: config_pkg::NOC_TYPE_AXI4_ATOP,
      // idempotent region: CLINT / PLIC
      NrNonIdempotentRules: unsigned'(2),
      NonIdempotentAddrBase: 1024'({64'hE000_0000, 64'hE000_0000}),
      NonIdempotentLength: 1024'({64'h1000, 64'h100_0000}),
      // execute region: Debug Module
      NrExecuteRegionRules: unsigned'(1),
      ExecuteRegionAddrBase: 1024'({64'hF000_0000}),
      ExecuteRegionLength: 1024'({64'h4000}),
      // cached region
      NrCachedRegionRules: unsigned'(1),
      CachedRegionAddrBase: 1024'({64'h0}),
      CachedRegionLength: 1024'({64'hE000_0000}),
      MaxOutstandingStores: unsigned'(7),
      DebugEn: bit'(1),
      AxiBurstWriteEn: bit'(0),
      IcacheByteSize: unsigned'(CVA6ConfigIcacheByteSize),
      IcacheSetAssoc: unsigned'(CVA6ConfigIcacheSetAssoc),
      IcacheLineWidth: unsigned'(CVA6ConfigIcacheLineWidth),
      DcacheByteSize: unsigned'(CVA6ConfigDcacheByteSize),
      DcacheSetAssoc: unsigned'(CVA6ConfigDcacheSetAssoc),
      DcacheLineWidth: unsigned'(CVA6ConfigDcacheLineWidth),
      DataUserEn: unsigned'(CVA6ConfigDataUserEn),
      FetchUserWidth: unsigned'(CVA6ConfigFetchUserWidth),
      FetchUserEn: unsigned'(CVA6ConfigFetchUserEn),
      PmpPresent: bit'(CVA6ConfigPmpPresent),
      DataScrPresent: bit'(CVA6ConfigDataScrPresent),
      DataScrBase: 64'(CVA6ConfigDataScrBase),
      DataScrSize: unsigned'(CVA6ConfigDataScrSize),
      InstrScrPresent: bit'(CVA6ConfigInstrScrPresent),
      InstrScrBase: 64'(CVA6ConfigInstrScrBase),
      InstrScrSize: unsigned'(CVA6ConfigInstrScrSize),
      AHBPeriphPresent: bit'(CVA6ConfigAHBPeriphPresent),
      AHBPeriphSystemBase: 64'(CVA6ConfigAHBPeriphSystemBase),
      AHBPeriphSystemSize: unsigned'(CVA6ConfigAHBPeriphSystemSize),
      AHBPeriphPrivateBase: 64'(CVA6ConfigAHBPeriphPrivateBase),
      AHBPeriphPrivateSize: unsigned'(CVA6ConfigAHBPeriphPrivateSize)
  };

endpackage
