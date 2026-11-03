// Copyright 2023 Thales DIS France SAS
//
// Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
// You may obtain a copy of the License at https://solderpad.org/licenses/
//
// Original Author: Jean-Roch COULON - Thales

package config_pkg;

  // ---------------
  // Global Config
  // ---------------
  localparam int unsigned ILEN = 32;
  localparam int unsigned NRET = 1;

  /// The NoC type is a top-level parameter, hence we need a bit more
  /// information on what protocol those type parameters are supporting.
  /// Currently two values are supported"
  typedef enum {
    /// The "classic" AXI4 protocol.
    NOC_TYPE_AXI4_ATOP,
    /// In the OpenPiton setting the WT cache is connected to the L15.
    NOC_TYPE_L15_BIG_ENDIAN,
    NOC_TYPE_L15_LITTLE_ENDIAN
  } noc_type_e;

  /// Cache type parameter
  typedef enum logic [1:0] {
    WB = 0,
    WT = 1,
    HPDCACHE = 2
  } cache_type_t;

  /// Data and Address length
  typedef enum logic [3:0] {
    ModeOff  = 0,
    ModeSv32 = 1,
    ModeSv39 = 8,
    ModeSv48 = 9,
    ModeSv57 = 10,
    ModeSv64 = 11
  } vm_mode_t;

  localparam NrMaxRules = 16;

  typedef struct packed {
    // General Purpose Register Size (in bits)
    int unsigned                 XLEN;
    // Atomic RISC-V extension
    bit                          RVA;
    // Bit manipulation RISC-V extension
    bit                          RVB;
    // Vector RISC-V extension
    bit                          RVV;
    // Compress RISC-V extension
    bit                          RVC;
    // Hypervisor RISC-V extension
    bit                          RVH;
    // Zcb RISC-V extension
    bit                          RVZCB;
    // Zcmp RISC-V extension
    bit                          RVZCMP;
    // Zicond RISC-V extension
    bit                          RVZiCond;
    // Floating Point
    bit                          FpuEn;
    // Non standard 16bits Floating Point extension
    bit                          XF16;
    // Non standard 16bits Floating Point Alt extension
    bit                          XF16ALT;
    // Non standard 8bits Floating Point extension
    bit                          XF8;
    // Non standard Vector Floating Point extension
    bit                          XFVec;
    // Supervisor mode
    bit                          RVS;
    // User mode
    bit                          RVU;
    // Debug support
    bit                          DebugEn;
    // Base address of the debug module
    logic [63:0]                 DmBaseAddress;
    // Address to jump when halt request
    logic [63:0]                 HaltAddress;
    // Address to jump when exception
    logic [63:0]                 ExceptionAddress;
    // Tval Support Enable
    bit                          TvalEn;
    // PMP entries number
    int unsigned                 NrPMPEntries;
    // PMP CSR configuration reset values
    logic [15:0][63:0]           PMPCfgRstVal;
    // PMP CSR address reset values
    logic [15:0][63:0]           PMPAddrRstVal;
    // PMP CSR read-only bits
    bit [15:0]                   PMPEntryReadOnly;
    // PMA non idempotent rules number
    int unsigned                 NrNonIdempotentRules;
    // PMA NonIdempotent region base address
    logic [NrMaxRules-1:0][63:0] NonIdempotentAddrBase;
    // PMA NonIdempotent region length
    logic [NrMaxRules-1:0][63:0] NonIdempotentLength;
    // PMA regions with execute rules number
    int unsigned                 NrExecuteRegionRules;
    // PMA Execute region base address
    logic [NrMaxRules-1:0][63:0] ExecuteRegionAddrBase;
    // PMA Execute region address base
    logic [NrMaxRules-1:0][63:0] ExecuteRegionLength;
    // PMA regions with cache rules number
    int unsigned                 NrCachedRegionRules;
    // PMA cache region base address
    logic [NrMaxRules-1:0][63:0] CachedRegionAddrBase;
    // PMA cache region rules
    logic [NrMaxRules-1:0][63:0] CachedRegionLength;
    // CV-X-IF coprocessor interface enable
    bit                          CvxifEn;
    // NOC bus type
    noc_type_e                   NOCType;
    // AXI address width
    int unsigned                 AxiAddrWidth;
    // AXI data width
    int unsigned                 AxiDataWidth;
    // AXI ID width
    int unsigned                 AxiIdWidth;
    // AXI User width
    int unsigned                 AxiUserWidth;
    // AXI burst in write
    bit                          AxiBurstWriteEn;
    // TODO
    int unsigned                 MemTidWidth;
    // Instruction cache size (in bytes)
    int unsigned                 IcacheByteSize;
    // Instruction cache associativity (number of ways)
    int unsigned                 IcacheSetAssoc;
    // Instruction cache line width
    int unsigned                 IcacheLineWidth;
    // Data cache size (in bytes)
    int unsigned                 DcacheByteSize;
    // Data cache associativity (number of ways)
    int unsigned                 DcacheSetAssoc;
    // Data cache line width
    int unsigned                 DcacheLineWidth;
    // User field on data bus enable
    int unsigned                 DataUserEn;
    // User field on fetch bus enable
    int unsigned                 FetchUserEn;
    // Width of fetch user field
    int unsigned                 FetchUserWidth;
    // Is FPGA optimization of CV32A6
    bit                          FpgaEn;
    // Number of commit ports
    int unsigned                 NrCommitPorts;
    // Scoreboard length
    int unsigned                 NrScoreboardEntries;
    // Load buffer entry buffer
    int unsigned                 NrLoadBufEntries;
    // Maximum number of outstanding stores
    int unsigned                 MaxOutstandingStores;
    // Return address stack depth
    int unsigned                 RASDepth;
    // Branch target buffer entries
    int unsigned                 BTBEntries;
    // Branch history entries
    int unsigned                 BHTEntries;
    /// Enable PMP without MMU
    bit                          PmpPresent;
    /// Set Data scratchpad
    bit                          DataScrPresent;
    int unsigned                 DataScrBase;
    int unsigned                 DataScrSize;
    /// Set Instruction scratchpad
    bit InstrScrPresent;
    int unsigned                 InstrScrBase;
    int unsigned                 InstrScrSize;
    /// Set AHB peripheral bus
    bit                          AHBPeriphPresent;
    logic [63:0]                 AHBPeriphSystemBase;
    int unsigned                 AHBPeriphSystemSize;
    logic [63:0]                 AHBPeriphPrivateBase;
    int unsigned                 AHBPeriphPrivateSize;
  } cva6_user_cfg_t;

  typedef struct packed {
    int unsigned XLEN;
    int unsigned VLEN;
    int unsigned PLEN;
    int unsigned GPLEN;
    bit IS_XLEN32;
    bit IS_XLEN64;
    int unsigned XLEN_ALIGN_BYTES;
    int unsigned ASID_WIDTH;
    int unsigned VMID_WIDTH;

    bit          FpgaEn;
    /// Number of commit ports, i.e., maximum number of instructions that the
    /// core can retire per cycle. It can be beneficial to have more commit
    /// ports than issue ports, for the scoreboard to empty out in case one
    /// instruction stalls a little longer.
    int unsigned NrCommitPorts;
    /// AXI parameters.
    int unsigned AxiAddrWidth;
    int unsigned AxiDataWidth;
    int unsigned AxiIdWidth;
    int unsigned AxiUserWidth;
    int unsigned MEM_TID_WIDTH;
    int unsigned NrLoadBufEntries;
    bit          FpuEn;
    bit          XF16;
    bit          XF16ALT;
    bit          XF8;
    bit          RVA;
    bit          RVB;
    bit          RVV;
    bit          RVC;
    bit          RVH;
    bit          RVZCB;
    bit          RVZCMP;
    bit          XFVec;
    bit          CvxifEn;
    bit          RVZiCond;

    int unsigned NR_SB_ENTRIES;
    int unsigned TRANS_ID_BITS;

    bit          RVF;
    bit          RVD;
    bit          FpPresent;
    bit          NSX;
    int unsigned FLen;
    bit          RVFVec;
    bit          XF16Vec;
    bit          XF16ALTVec;
    bit          XF8Vec;
    int unsigned NrRgprPorts;
    int unsigned NrWbPorts;
    bit          EnableAccelerator;
    bit          RVS;                //Supervisor mode
    bit          RVU;                //User mode

    logic [63:0]                 HaltAddress;
    logic [63:0]                 ExceptionAddress;
    int unsigned                 RASDepth;
    int unsigned                 BTBEntries;
    int unsigned                 BHTEntries;
    logic [63:0]                 DmBaseAddress;
    bit                          TvalEn;
    int unsigned                 NrPMPEntries;
    logic [15:0][63:0]           PMPCfgRstVal;
    logic [15:0][63:0]           PMPAddrRstVal;
    bit [15:0]                   PMPEntryReadOnly;
    noc_type_e                   NOCType;
    int unsigned                 NrNonIdempotentRules;
    logic [NrMaxRules-1:0][63:0] NonIdempotentAddrBase;
    logic [NrMaxRules-1:0][63:0] NonIdempotentLength;
    int unsigned                 NrExecuteRegionRules;
    logic [NrMaxRules-1:0][63:0] ExecuteRegionAddrBase;
    logic [NrMaxRules-1:0][63:0] ExecuteRegionLength;
    int unsigned                 NrCachedRegionRules;
    logic [NrMaxRules-1:0][63:0] CachedRegionAddrBase;
    logic [NrMaxRules-1:0][63:0] CachedRegionLength;
    int unsigned                 MaxOutstandingStores;
    bit                          DebugEn;
    bit                          NonIdemPotenceEn;       // Currently only used by V extension (Ara)
    bit                          AxiBurstWriteEn;

    int unsigned ICACHE_SET_ASSOC;
    int unsigned ICACHE_SET_ASSOC_WIDTH;
    int unsigned ICACHE_INDEX_WIDTH;
    int unsigned ICACHE_TAG_WIDTH;
    int unsigned ICACHE_LINE_WIDTH;
    int unsigned ICACHE_USER_LINE_WIDTH;
    int unsigned DCACHE_SET_ASSOC;
    int unsigned DCACHE_SET_ASSOC_WIDTH;
    int unsigned DCACHE_INDEX_WIDTH;
    int unsigned DCACHE_TAG_WIDTH;
    int unsigned DCACHE_LINE_WIDTH;
    int unsigned DCACHE_USER_LINE_WIDTH;
    int unsigned DCACHE_USER_WIDTH;
    int unsigned DCACHE_OFFSET_WIDTH;
    int unsigned DCACHE_NUM_WORDS;

    int unsigned DCACHE_MAX_TX;

    int unsigned DATA_USER_EN;
    int unsigned FETCH_USER_WIDTH;
    int unsigned FETCH_USER_EN;
    int unsigned AXI_USER_EN;

    int unsigned FETCH_WIDTH;
    int unsigned INSTR_PER_FETCH;
    int unsigned LOG2_INSTR_PER_FETCH;

    int unsigned ModeW;
    int unsigned ASIDW;
    int unsigned VMIDW;
    int unsigned PPNW;
    int unsigned GPPNW;
    vm_mode_t MODE_SV;
    int unsigned SV;
    int unsigned SVX;

    bit PmpPresent;
    bit DataScrPresent;
    int unsigned DataScrBase;
    int unsigned DataScrSize;
    bit InstrScrPresent;
    int unsigned InstrScrBase;
    int unsigned InstrScrSize;
    bit AHBPeriphPresent;
    logic [63:0] AHBPeriphSystemBase;
    int unsigned AHBPeriphSystemSize;
    logic [63:0] AHBPeriphPrivateBase;
    int unsigned AHBPeriphPrivateSize;
  } cva6_cfg_t;

  /// Empty configuration to sanity check proper parameter passing. Whenever
  /// you develop a module that resides within the core, assign this constant.
  localparam cva6_cfg_t cva6_cfg_empty = '0;

  /// Utility function being called to check parameters. Not all values make
  /// sense for all parameters, here is the place to sanity check them.
  function automatic void check_cfg(cva6_cfg_t Cfg);
    // pragma translate_off
`ifndef VERILATOR
    assert (Cfg.RASDepth > 0);
    assert (Cfg.BTBEntries == 0 || (2 ** $clog2(Cfg.BTBEntries) == Cfg.BTBEntries));
    assert (Cfg.BHTEntries == 0 || (2 ** $clog2(Cfg.BHTEntries) == Cfg.BHTEntries));
    assert (Cfg.NrNonIdempotentRules <= NrMaxRules);
    assert (Cfg.NrExecuteRegionRules <= NrMaxRules);
    assert (Cfg.NrCachedRegionRules <= NrMaxRules);
    assert (Cfg.NrPMPEntries <= 16);
`endif
    // pragma translate_on
  endfunction

  function automatic logic range_check(logic [63:0] base, logic [63:0] len, logic [63:0] address);
    // if len is a power of two, and base is properly aligned, this check could be simplified
    // Extend base by one bit to prevent an overflow.
    return (address >= base) && (({1'b0, address}) < (65'(base) + len));
  endfunction : range_check


  function automatic logic is_inside_nonidempotent_regions(cva6_cfg_t Cfg, logic [63:0] address);
    logic [NrMaxRules-1:0] pass;
    pass = '0;
    for (int unsigned k = 0; k < Cfg.NrNonIdempotentRules; k++) begin
      pass[k] = range_check(Cfg.NonIdempotentAddrBase[k], Cfg.NonIdempotentLength[k], address);
    end
    return |pass;
  endfunction : is_inside_nonidempotent_regions

  function automatic logic is_inside_execute_regions(cva6_cfg_t Cfg, logic [63:0] address);
    // if we don't specify any region we assume everything is accessible
    logic [NrMaxRules-1:0] pass;
    pass = '0;
    for (int unsigned k = 0; k < Cfg.NrExecuteRegionRules; k++) begin
      pass[k] = range_check(Cfg.ExecuteRegionAddrBase[k], Cfg.ExecuteRegionLength[k], address);
    end
    return |pass;
  endfunction : is_inside_execute_regions

  function automatic logic is_inside_cacheable_regions(cva6_cfg_t Cfg, logic [63:0] address);
    automatic logic [NrMaxRules-1:0] pass;
    pass = '0;
    for (int unsigned k = 0; k < Cfg.NrCachedRegionRules; k++) begin
      pass[k] = range_check(Cfg.CachedRegionAddrBase[k], Cfg.CachedRegionLength[k], address);
    end
    return |pass;
  endfunction : is_inside_cacheable_regions

endpackage