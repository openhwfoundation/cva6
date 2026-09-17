package build_config_pkg;

  function automatic config_pkg::cva6_cfg_t build_config(config_pkg::cva6_user_cfg_t CVA6Cfg);
    bit IS_XLEN32 = (CVA6Cfg.XLEN == 32) ? 1'b1 : 1'b0;
    bit IS_XLEN64 = (CVA6Cfg.XLEN == 32) ? 1'b0 : 1'b1;
    bit FpPresent = CVA6Cfg.RVF | CVA6Cfg.RVD | CVA6Cfg.XF16 | CVA6Cfg.XF16ALT | CVA6Cfg.XF8;
    bit NSX = CVA6Cfg.XF16 | CVA6Cfg.XF16ALT | CVA6Cfg.XF8 | CVA6Cfg.XFVec;  // Are non-standard extensions present?
    int unsigned FLen = CVA6Cfg.RVD ? 64 :  // D ext.
    CVA6Cfg.RVF ? 32 :  // F ext.
    CVA6Cfg.XF16 ? 16 :  // Xf16 ext.
    CVA6Cfg.XF16ALT ? 16 :  // Xf16alt ext.
    CVA6Cfg.XF8 ? 8 :  // Xf8 ext.
    1;  // Unused in case of no FP

    // Transprecision floating-point extensions configuration
    bit RVFVec     = CVA6Cfg.RVF     & CVA6Cfg.XFVec & FLen>32; // FP32 vectors available if vectors and larger fmt enabled
    bit XF16Vec    = CVA6Cfg.XF16    & CVA6Cfg.XFVec & FLen>16; // FP16 vectors available if vectors and larger fmt enabled
    bit XF16ALTVec = CVA6Cfg.XF16ALT & CVA6Cfg.XFVec & FLen>16; // FP16ALT vectors available if vectors and larger fmt enabled
    bit XF8Vec     = CVA6Cfg.XF8     & CVA6Cfg.XFVec & FLen>8;  // FP8 vectors available if vectors and larger fmt enabled

    bit EnableAccelerator = CVA6Cfg.RVV;  // Currently only used by V extension (Ara)
    int unsigned NrWbPorts = (CVA6Cfg.CvxifEn || EnableAccelerator) ? 5 : 4;

    int unsigned ICACHE_INDEX_WIDTH = $clog2(CVA6Cfg.IcacheByteSize / CVA6Cfg.IcacheSetAssoc);
    int unsigned DCACHE_INDEX_WIDTH = $clog2(CVA6Cfg.DcacheByteSize / CVA6Cfg.DcacheSetAssoc);
    int unsigned DCACHE_OFFSET_WIDTH = $clog2(CVA6Cfg.DcacheLineWidth / 8);

    // MMU
    int unsigned VpnLen = (CVA6Cfg.XLEN == 64) ? (CVA6Cfg.RVH ? 29 : 27) : 20;
    int unsigned PtLevels = (CVA6Cfg.XLEN == 64) ? 3 : 2;

    config_pkg::cva6_cfg_t cfg;
    cfg.ObiVersion = CVA6Cfg.ObiVersion;
    cfg.XLEN = CVA6Cfg.XLEN;
    cfg.VLEN = CVA6Cfg.VLEN;
    cfg.PLEN = (CVA6Cfg.XLEN == 32) ? 34 : 56;
    cfg.GPLEN = (CVA6Cfg.XLEN == 32) ? 34 : 41;
    cfg.IS_XLEN32 = IS_XLEN32;
    cfg.IS_XLEN64 = IS_XLEN64;
    cfg.XLEN_ALIGN_BYTES = $clog2(CVA6Cfg.XLEN / 8);
    cfg.ASID_WIDTH = (CVA6Cfg.XLEN == 64) ? 16 : 1;
    cfg.VMID_WIDTH = (CVA6Cfg.XLEN == 64) ? 14 : 1;

    cfg.FpgaEn = CVA6Cfg.FpgaEn;
    cfg.FpgaAlteraEn = CVA6Cfg.FpgaAlteraEn;
    cfg.TechnoCut = CVA6Cfg.TechnoCut;

    cfg.SuperscalarEn = CVA6Cfg.SuperscalarEn;
    cfg.NrCommitPorts = CVA6Cfg.SuperscalarEn ? unsigned'(2) : CVA6Cfg.NrCommitPorts;
    cfg.NrIssuePorts = unsigned'(CVA6Cfg.SuperscalarEn ? 2 : 1);
    cfg.SpeculativeSb = CVA6Cfg.SuperscalarEn;

    cfg.NrLoadPipeRegs = CVA6Cfg.NrLoadPipeRegs;
    cfg.NrStorePipeRegs = CVA6Cfg.NrStorePipeRegs;
    cfg.AxiAddrWidth = CVA6Cfg.AxiAddrWidth;
    cfg.AxiDataWidth = CVA6Cfg.AxiDataWidth;
    cfg.AxiIdWidth = CVA6Cfg.AxiIdWidth;
    cfg.AxiUserWidth = CVA6Cfg.AxiUserWidth;
    cfg.NrLoadBufEntries = cfg.ObiVersion == config_pkg::OBI_NOT_COMPLIANT ? CVA6Cfg.NrLoadBufEntries : 1;  //FIXME: To fix in order response 
    cfg.NrFetchBufEntries = 1;
    cfg.RVF = CVA6Cfg.RVF;
    cfg.RVD = CVA6Cfg.RVD;
    cfg.XF16 = CVA6Cfg.XF16;
    cfg.XF16ALT = CVA6Cfg.XF16ALT;
    cfg.XF8 = CVA6Cfg.XF8;
    cfg.RVA = CVA6Cfg.RVA;
    cfg.RVB = CVA6Cfg.RVB;
    cfg.ZKN = CVA6Cfg.ZKN;
    cfg.RVV = CVA6Cfg.RVV;
    cfg.RVC = CVA6Cfg.RVC;
    cfg.RVH = CVA6Cfg.RVH;
    cfg.RVZCB = CVA6Cfg.RVZCB;
    cfg.RVZCMT = CVA6Cfg.RVZCMT;
    cfg.RVZCMP = CVA6Cfg.RVZCMP;
    cfg.XFVec = CVA6Cfg.XFVec;
    cfg.CvxifEn = CVA6Cfg.CvxifEn;
    cfg.CoproType = CVA6Cfg.CoproType;
    cfg.RVZiCond = CVA6Cfg.RVZiCond;
    cfg.RVZicntr = CVA6Cfg.RVZicntr;
    cfg.RVZifencei = CVA6Cfg.RVZifencei;
    cfg.RVZihpm = CVA6Cfg.RVZihpm;
    cfg.NR_SB_ENTRIES = CVA6Cfg.NrScoreboardEntries;
    cfg.TRANS_ID_BITS = $clog2(CVA6Cfg.NrScoreboardEntries);

    cfg.FpPresent = bit'(FpPresent);
    cfg.NSX = bit'(NSX);
    cfg.FLen = unsigned'(FLen);
    cfg.RVFVec = bit'(RVFVec);
    cfg.XF16Vec = bit'(XF16Vec);
    cfg.XF16ALTVec = bit'(XF16ALTVec);
    cfg.XF8Vec = bit'(XF8Vec);
    // Can take 2 or 3 in single issue. 4 or 6 in dual issue.
    cfg.NrRgprPorts = unsigned'(CVA6Cfg.SuperscalarEn ? 4 : 2);
    // cfg.NrRgprPorts = unsigned'(CVA6Cfg.SuperscalarEn ? 6 : 3);
    cfg.NrWbPorts = unsigned'(NrWbPorts);
    cfg.EnableAccelerator = bit'(EnableAccelerator);
    cfg.PerfCounterEn = CVA6Cfg.PerfCounterEn;
    cfg.MmuPresent = CVA6Cfg.MmuPresent;
    cfg.RVS = CVA6Cfg.RVS;
    cfg.RVU = CVA6Cfg.RVU;
    cfg.SoftwareInterruptEn = CVA6Cfg.SoftwareInterruptEn;

    cfg.HaltAddress = CVA6Cfg.HaltAddress;
    cfg.ExceptionAddress = CVA6Cfg.ExceptionAddress;
    cfg.RASDepth = CVA6Cfg.RASDepth;
    cfg.BTBEntries = CVA6Cfg.BTBEntries;
    cfg.BHTEntries = CVA6Cfg.BHTEntries;
    cfg.DmBaseAddress = CVA6Cfg.DmBaseAddress;
    cfg.TvalEn = CVA6Cfg.TvalEn;
    cfg.DirectVecOnly = CVA6Cfg.DirectVecOnly;
    cfg.NrPMPEntries = CVA6Cfg.NrPMPEntries;
    cfg.PMPCfgRstVal = CVA6Cfg.PMPCfgRstVal;
    cfg.PMPAddrRstVal = CVA6Cfg.PMPAddrRstVal;
    cfg.PMPEntryReadOnly = CVA6Cfg.PMPEntryReadOnly;
    cfg.PMPNapotEn = CVA6Cfg.PMPNapotEn;
    cfg.NOCType = CVA6Cfg.NOCType;
    cfg.NrNonIdempotentRules = CVA6Cfg.NrNonIdempotentRules;
    cfg.NonIdempotentAddrBase = CVA6Cfg.NonIdempotentAddrBase;
    cfg.NonIdempotentLength = CVA6Cfg.NonIdempotentLength;
    cfg.NrExecuteRegionRules = CVA6Cfg.NrExecuteRegionRules;
    cfg.ExecuteRegionAddrBase = CVA6Cfg.ExecuteRegionAddrBase;
    cfg.ExecuteRegionLength = CVA6Cfg.ExecuteRegionLength;
    cfg.NrCachedRegionRules = CVA6Cfg.NrCachedRegionRules;
    cfg.CachedRegionAddrBase = CVA6Cfg.CachedRegionAddrBase;
    cfg.CachedRegionLength = CVA6Cfg.CachedRegionLength;
    cfg.MaxOutstandingStores = CVA6Cfg.MaxOutstandingStores;
    cfg.DebugEn = CVA6Cfg.DebugEn;
    cfg.NonIdemPotenceEn = (CVA6Cfg.NrNonIdempotentRules > 0) && (CVA6Cfg.NonIdempotentLength > 0);
    cfg.AxiBurstWriteEn = CVA6Cfg.AxiBurstWriteEn;

    cfg.ICACHE_SET_ASSOC = CVA6Cfg.IcacheSetAssoc;
    cfg.ICACHE_SET_ASSOC_WIDTH = CVA6Cfg.IcacheSetAssoc > 1 ? $clog2(CVA6Cfg.IcacheSetAssoc) :
        CVA6Cfg.IcacheSetAssoc;
    cfg.ICACHE_INDEX_WIDTH = ICACHE_INDEX_WIDTH;
    cfg.ICACHE_TAG_WIDTH = cfg.PLEN - ICACHE_INDEX_WIDTH;
    cfg.ICACHE_LINE_WIDTH = CVA6Cfg.IcacheLineWidth;
    cfg.ICACHE_USER_LINE_WIDTH = (CVA6Cfg.AxiUserWidth == 1) ? 4 : CVA6Cfg.IcacheLineWidth;
    cfg.DCacheType = CVA6Cfg.DCacheType;
    cfg.DcacheIdWidth = CVA6Cfg.DcacheIdWidth;
    cfg.DCACHE_SET_ASSOC = CVA6Cfg.DcacheSetAssoc;
    cfg.DCACHE_SET_ASSOC_WIDTH = CVA6Cfg.DcacheSetAssoc > 1 ? $clog2(CVA6Cfg.DcacheSetAssoc) :
        CVA6Cfg.DcacheSetAssoc;
    cfg.DCACHE_INDEX_WIDTH = DCACHE_INDEX_WIDTH;
    cfg.DCACHE_TAG_WIDTH = cfg.PLEN - DCACHE_INDEX_WIDTH;
    cfg.DCACHE_LINE_WIDTH = CVA6Cfg.DcacheLineWidth;
    cfg.DCACHE_USER_LINE_WIDTH = (CVA6Cfg.AxiUserWidth == 1) ? 4 : CVA6Cfg.DcacheLineWidth;
    cfg.DCACHE_USER_WIDTH = CVA6Cfg.AxiUserWidth;
    cfg.DCACHE_OFFSET_WIDTH = DCACHE_OFFSET_WIDTH;
    cfg.DCACHE_NUM_WORDS = 2 ** (DCACHE_INDEX_WIDTH - DCACHE_OFFSET_WIDTH);

    cfg.DcacheFlushOnFence = CVA6Cfg.DcacheFlushOnFence;
    cfg.DcacheInvalidateOnFlush = CVA6Cfg.DcacheInvalidateOnFlush;

    cfg.DATA_USER_EN = CVA6Cfg.DataUserEn;
    cfg.WtDcacheWbufDepth = CVA6Cfg.WtDcacheWbufDepth;
    cfg.FETCH_USER_WIDTH = CVA6Cfg.FetchUserWidth;
    cfg.FETCH_USER_EN = CVA6Cfg.FetchUserEn;
    cfg.AXI_USER_EN = CVA6Cfg.DataUserEn | CVA6Cfg.FetchUserEn;

    cfg.FETCH_WIDTH = unsigned'((CVA6Cfg.SuperscalarEn && !CVA6Cfg.PipelineOnly) ? 64 : 32);
    cfg.FETCH_BE_WIDTH = cfg.FETCH_WIDTH / 8;
    cfg.FETCH_ALIGN_BITS = $clog2(cfg.FETCH_BE_WIDTH);
    cfg.INSTR_PER_FETCH = cfg.FETCH_WIDTH / (CVA6Cfg.RVC ? 16 : 32);
    cfg.LOG2_INSTR_PER_FETCH = cfg.INSTR_PER_FETCH > 1 ? $clog2(cfg.INSTR_PER_FETCH) : 1;

    cfg.ModeW = (CVA6Cfg.XLEN == 32) ? 1 : 4;
    cfg.ASIDW = (CVA6Cfg.XLEN == 32) ? 9 : 16;
    cfg.VMIDW = (CVA6Cfg.XLEN == 32) ? 7 : 14;
    cfg.PPNW = (CVA6Cfg.XLEN == 32) ? 22 : 44;
    cfg.GPPNW = (CVA6Cfg.XLEN == 32) ? 22 : 29;
    cfg.MODE_SV = (CVA6Cfg.XLEN == 32) ? config_pkg::ModeSv32 : config_pkg::ModeSv39;
    cfg.SV = (cfg.MODE_SV == config_pkg::ModeSv32) ? 32 : 39;
    cfg.SVX = (cfg.MODE_SV == config_pkg::ModeSv32) ? 34 : 41;
    cfg.InstrTlbEntries = CVA6Cfg.InstrTlbEntries;
    cfg.DataTlbEntries = CVA6Cfg.DataTlbEntries;
    cfg.UseSharedTlb = CVA6Cfg.UseSharedTlb;
    cfg.SharedTlbDepth = CVA6Cfg.SharedTlbDepth;
    cfg.VpnLen = VpnLen;
    cfg.PtLevels = PtLevels;

    cfg.X_NUM_RS = cfg.NrRgprPorts / cfg.NrIssuePorts;
    cfg.X_ID_WIDTH = cfg.TRANS_ID_BITS;
    cfg.X_RFR_WIDTH = cfg.XLEN;
    cfg.X_RFW_WIDTH = cfg.XLEN;
    cfg.X_NUM_HARTS = 1;
    cfg.X_HARTID_WIDTH = cfg.XLEN;
    cfg.X_DUALREAD = 0;
    cfg.X_DUALWRITE = 0;
    cfg.X_ISSUE_REGISTER_SPLIT = 0;

    cfg.IdWidth = cfg.AxiIdWidth;  //to be changed

    cfg.ObiFetchbusCfg.UseRReady = 1'b1;
    cfg.ObiFetchbusCfg.CombGnt = 1'b0;
    cfg.ObiFetchbusCfg.AddrWidth = cfg.PLEN;
    cfg.ObiFetchbusCfg.DataWidth = cfg.FETCH_WIDTH;
    cfg.ObiFetchbusCfg.IdWidth = CVA6Cfg.DcacheIdWidth;
    cfg.ObiFetchbusCfg.Integrity = 1'b0;
    cfg.ObiFetchbusCfg.BeFull = 1'b1;
    cfg.ObiFetchbusCfg.OptionalCfg.UseAtop = 1'b1;
    cfg.ObiFetchbusCfg.OptionalCfg.UseMemtype = 1'b1;
    cfg.ObiFetchbusCfg.OptionalCfg.UseProt = 1'b1;
    cfg.ObiFetchbusCfg.OptionalCfg.UseDbg = 1'b1;
    cfg.ObiFetchbusCfg.OptionalCfg.AUserWidth = 1;
    cfg.ObiFetchbusCfg.OptionalCfg.WUserWidth = cfg.FETCH_USER_WIDTH;
    cfg.ObiFetchbusCfg.OptionalCfg.RUserWidth = cfg.FETCH_USER_WIDTH;
    cfg.ObiFetchbusCfg.OptionalCfg.MidWidth = 1;
    cfg.ObiFetchbusCfg.OptionalCfg.AChkWidth = 1;
    cfg.ObiFetchbusCfg.OptionalCfg.RChkWidth = 1;

    cfg.ObiStorebusCfg.UseRReady = 1'b1;
    cfg.ObiStorebusCfg.CombGnt = 1'b0;
    cfg.ObiStorebusCfg.AddrWidth = cfg.PLEN;
    cfg.ObiStorebusCfg.DataWidth = cfg.XLEN;
    cfg.ObiStorebusCfg.IdWidth = cfg.DcacheIdWidth;
    cfg.ObiStorebusCfg.Integrity = 1'b0;
    cfg.ObiStorebusCfg.BeFull = 1'b1;
    cfg.ObiStorebusCfg.OptionalCfg.UseAtop = 1'b1;
    cfg.ObiStorebusCfg.OptionalCfg.UseMemtype = 1'b1;
    cfg.ObiStorebusCfg.OptionalCfg.UseProt = 1'b1;
    cfg.ObiStorebusCfg.OptionalCfg.UseDbg = 1'b1;
    cfg.ObiStorebusCfg.OptionalCfg.AUserWidth = 1;
    cfg.ObiStorebusCfg.OptionalCfg.WUserWidth = cfg.DCACHE_USER_WIDTH;
    cfg.ObiStorebusCfg.OptionalCfg.RUserWidth = cfg.DCACHE_USER_WIDTH;
    cfg.ObiStorebusCfg.OptionalCfg.MidWidth = 1;
    cfg.ObiStorebusCfg.OptionalCfg.AChkWidth = 1;
    cfg.ObiStorebusCfg.OptionalCfg.RChkWidth = 1;

    cfg.ObiAmobusCfg.UseRReady = 1'b1;
    cfg.ObiAmobusCfg.CombGnt = 1'b0;
    cfg.ObiAmobusCfg.AddrWidth = cfg.PLEN;
    cfg.ObiAmobusCfg.DataWidth = cfg.XLEN;
    cfg.ObiAmobusCfg.IdWidth = cfg.DcacheIdWidth;
    cfg.ObiAmobusCfg.Integrity = 1'b0;
    cfg.ObiAmobusCfg.BeFull = 1'b1;
    cfg.ObiAmobusCfg.OptionalCfg.UseAtop = 1'b1;
    cfg.ObiAmobusCfg.OptionalCfg.UseMemtype = 1'b1;
    cfg.ObiAmobusCfg.OptionalCfg.UseProt = 1'b1;
    cfg.ObiAmobusCfg.OptionalCfg.UseDbg = 1'b1;
    cfg.ObiAmobusCfg.OptionalCfg.AUserWidth = 1;
    cfg.ObiAmobusCfg.OptionalCfg.WUserWidth = cfg.DCACHE_USER_WIDTH;
    cfg.ObiAmobusCfg.OptionalCfg.RUserWidth = cfg.DCACHE_USER_WIDTH;
    cfg.ObiAmobusCfg.OptionalCfg.MidWidth = 1;
    cfg.ObiAmobusCfg.OptionalCfg.AChkWidth = 1;
    cfg.ObiAmobusCfg.OptionalCfg.RChkWidth = 1;

    cfg.ObiLoadbusCfg.UseRReady = 1'b1;
    cfg.ObiLoadbusCfg.CombGnt = 1'b0;
    cfg.ObiLoadbusCfg.AddrWidth = cfg.PLEN;
    cfg.ObiLoadbusCfg.DataWidth = cfg.XLEN;
    cfg.ObiLoadbusCfg.IdWidth = cfg.DcacheIdWidth;
    cfg.ObiLoadbusCfg.Integrity = 1'b0;
    cfg.ObiLoadbusCfg.BeFull = 1'b1;
    cfg.ObiLoadbusCfg.OptionalCfg.UseAtop = 1'b1;
    cfg.ObiLoadbusCfg.OptionalCfg.UseMemtype = 1'b1;
    cfg.ObiLoadbusCfg.OptionalCfg.UseProt = 1'b1;
    cfg.ObiLoadbusCfg.OptionalCfg.UseDbg = 1'b1;
    cfg.ObiLoadbusCfg.OptionalCfg.AUserWidth = 1;
    cfg.ObiLoadbusCfg.OptionalCfg.WUserWidth = cfg.DCACHE_USER_WIDTH;
    cfg.ObiLoadbusCfg.OptionalCfg.RUserWidth = cfg.DCACHE_USER_WIDTH;
    cfg.ObiLoadbusCfg.OptionalCfg.MidWidth = 1;
    cfg.ObiLoadbusCfg.OptionalCfg.AChkWidth = 1;
    cfg.ObiLoadbusCfg.OptionalCfg.RChkWidth = 1;

    cfg.ObiMmuPtwbusCfg.UseRReady = 1'b1;
    cfg.ObiMmuPtwbusCfg.CombGnt = 1'b0;
    cfg.ObiMmuPtwbusCfg.AddrWidth = cfg.PLEN;
    cfg.ObiMmuPtwbusCfg.DataWidth = cfg.XLEN;
    cfg.ObiMmuPtwbusCfg.IdWidth = cfg.DcacheIdWidth;
    cfg.ObiMmuPtwbusCfg.Integrity = 1'b0;
    cfg.ObiMmuPtwbusCfg.BeFull = 1'b1;
    cfg.ObiMmuPtwbusCfg.OptionalCfg.UseAtop = 1'b1;
    cfg.ObiMmuPtwbusCfg.OptionalCfg.UseMemtype = 1'b1;
    cfg.ObiMmuPtwbusCfg.OptionalCfg.UseProt = 1'b1;
    cfg.ObiMmuPtwbusCfg.OptionalCfg.UseDbg = 1'b1;
    cfg.ObiMmuPtwbusCfg.OptionalCfg.AUserWidth = 1;
    cfg.ObiMmuPtwbusCfg.OptionalCfg.WUserWidth = cfg.DCACHE_USER_WIDTH;
    cfg.ObiMmuPtwbusCfg.OptionalCfg.RUserWidth = cfg.DCACHE_USER_WIDTH;
    cfg.ObiMmuPtwbusCfg.OptionalCfg.MidWidth = 1;
    cfg.ObiMmuPtwbusCfg.OptionalCfg.AChkWidth = 1;
    cfg.ObiMmuPtwbusCfg.OptionalCfg.RChkWidth = 1;

    cfg.ObiZcmtbusCfg.UseRReady = 1'b1;
    cfg.ObiZcmtbusCfg.CombGnt = 1'b0;
    cfg.ObiZcmtbusCfg.AddrWidth = cfg.PLEN;
    cfg.ObiZcmtbusCfg.DataWidth = cfg.XLEN;
    cfg.ObiZcmtbusCfg.IdWidth = cfg.IdWidth;
    cfg.ObiZcmtbusCfg.Integrity = 1'b0;
    cfg.ObiZcmtbusCfg.BeFull = 1'b1;
    cfg.ObiZcmtbusCfg.OptionalCfg.UseAtop = 1'b1;
    cfg.ObiZcmtbusCfg.OptionalCfg.UseMemtype = 1'b1;
    cfg.ObiZcmtbusCfg.OptionalCfg.UseProt = 1'b1;
    cfg.ObiZcmtbusCfg.OptionalCfg.UseDbg = 1'b1;
    cfg.ObiZcmtbusCfg.OptionalCfg.AUserWidth = 1;
    cfg.ObiZcmtbusCfg.OptionalCfg.WUserWidth = cfg.DCACHE_USER_WIDTH;
    cfg.ObiZcmtbusCfg.OptionalCfg.RUserWidth = cfg.DCACHE_USER_WIDTH;
    cfg.ObiZcmtbusCfg.OptionalCfg.MidWidth = 1;
    cfg.ObiZcmtbusCfg.OptionalCfg.AChkWidth = 1;
    cfg.ObiZcmtbusCfg.OptionalCfg.RChkWidth = 1;

    cfg.PipelineOnly = CVA6Cfg.PipelineOnly;
    cfg.NrStoreInFlight = CVA6Cfg.NrStoreInFlight;

    cfg.DclsEn = CVA6Cfg.DclsEn;
    cfg.DclsDelay = CVA6Cfg.DclsDelay;
    cfg.DclsCommonRegfile = CVA6Cfg.DclsCommonRegfile;
    cfg.DclsCommonBHT = CVA6Cfg.DclsCommonBHT;
    cfg.DclsCommonModules = CVA6Cfg.DclsCommonBHT | CVA6Cfg.DclsCommonRegfile;

    return cfg;
  endfunction

endpackage
