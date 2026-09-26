..
   Copyright 2024 Thales DIS France SAS
   Licensed under the Solderpad Hardware License, Version 2.1 (the "License");
   you may not use this file except in compliance with the License.
   SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
   You may obtain a copy of the License at https://solderpad.org/licenses/

   Original Author: Jean-Roch COULON - Thales

.. _cva6_user_cfg_doc:

.. list-table:: ``cva6_user_cfg_t`` parameters
   :header-rows: 1

   * - Name
     - Type
     - Description

   * - ``XLEN``
     - ``int unsigned``
     - General Purpose Register Size (in bits)

   * - ``VLEN``
     - ``int unsigned``
     - Virtual address Size (in bits)

   * - ``RVA``
     - ``bit``
     - Atomic RISC-V extension

   * - ``RVB``
     - ``bit``
     - Bit manipulation RISC-V extension

   * - ``ZKN``
     - ``bit``
     - Scalar Cryptography RISC-V extension

   * - ``RVV``
     - ``bit``
     - Vector RISC-V extension

   * - ``RVC``
     - ``bit``
     - Compress RISC-V extension

   * - ``RVH``
     - ``bit``
     - Hypervisor RISC-V extension

   * - ``RVZCB``
     - ``bit``
     - Zcb RISC-V extension

   * - ``RVZCMP``
     - ``bit``
     - Zcmp RISC-V extension

   * - ``RVZCMT``
     - ``bit``
     - Zcmt RISC-V extension

   * - ``RVZiCond``
     - ``bit``
     - Zicond RISC-V extension

   * - ``RVZiCbom``
     - ``bit``
     - Zicbom RISC-V extension (cache management / CBO)

   * - ``RVZicntr``
     - ``bit``
     - Zicntr RISC-V extension

   * - ``RVZifencei``
     - ``bit``
     - Zifencei RISC-V extension

   * - ``RVZihpm``
     - ``bit``
     - Zihpm RISC-V extension

   * - ``RVF``
     - ``bit``
     - Floating Point

   * - ``RVD``
     - ``bit``
     - Floating Point

   * - ``XF16``
     - ``bit``
     - Non standard 16bits Floating Point extension

   * - ``XF16ALT``
     - ``bit``
     - Non standard 16bits Floating Point Alt extension

   * - ``XF8``
     - ``bit``
     - Non standard 8bits Floating Point extension

   * - ``XFVec``
     - ``bit``
     - Non standard Vector Floating Point extension

   * - ``PerfCounterEn``
     - ``bit``
     - Perf counters

   * - ``MmuPresent``
     - ``bit``
     - MMU

   * - ``RVS``
     - ``bit``
     - Supervisor mode

   * - ``RVU``
     - ``bit``
     - User mode

   * - ``SoftwareInterruptEn``
     - ``bit``
     - Software interrupts are enabled

   * - ``DebugEn``
     - ``bit``
     - Debug support

   * - ``DmBaseAddress``
     - ``logic [63:0]``
     - Base address of the debug module

   * - ``HaltAddress``
     - ``logic [63:0]``
     - Address to jump when halt request

   * - ``ExceptionAddress``
     - ``logic [63:0]``
     - Address to jump when exception

   * - ``TvalEn``
     - ``bit``
     - Tval Support Enable

   * - ``DirectVecOnly``
     - ``bit``
     - MTVEC CSR supports only direct mode

   * - ``NrPMPEntries``
     - ``int unsigned``
     - PMP entries number

   * - ``PMPCfgRstVal``
     - ``logic [63:0][63:0]``
     - PMP CSR configuration reset values

   * - ``PMPAddrRstVal``
     - ``logic [63:0][63:0]``
     - PMP CSR address reset values

   * - ``PMPEntryReadOnly``
     - ``bit [63:0]``
     - PMP CSR read-only bits

   * - ``PMPNapotEn``
     - ``bit``
     - PMP NA4 and NAPOT mode enable

   * - ``NrNonIdempotentRules``
     - ``int unsigned``
     - PMA non idempotent rules number

   * - ``NonIdempotentAddrBase``
     - ``logic [NrMaxRules-1:0][63:0]``
     - PMA NonIdempotent region base address

   * - ``NonIdempotentLength``
     - ``logic [NrMaxRules-1:0][63:0]``
     - PMA NonIdempotent region length

   * - ``NrExecuteRegionRules``
     - ``int unsigned``
     - PMA regions with execute rules number

   * - ``ExecuteRegionAddrBase``
     - ``logic [NrMaxRules-1:0][63:0]``
     - PMA Execute region base address

   * - ``ExecuteRegionLength``
     - ``logic [NrMaxRules-1:0][63:0]``
     - PMA Execute region address base

   * - ``NrCachedRegionRules``
     - ``int unsigned``
     - PMA regions with cache rules number

   * - ``CachedRegionAddrBase``
     - ``logic [NrMaxRules-1:0][63:0]``
     - PMA cache region base address

   * - ``CachedRegionLength``
     - ``logic [NrMaxRules-1:0][63:0]``
     - PMA cache region rules

   * - ``CvxifEn``
     - ``bit``
     - CV-X-IF coprocessor interface enable

   * - ``CoproType``
     - ``copro_type_t``
     - Coprocessor type

   * - ``NOCType``
     - ``noc_type_e``
     - NOC bus type

   * - ``AxiAddrWidth``
     - ``int unsigned``
     - AXI address width

   * - ``AxiDataWidth``
     - ``int unsigned``
     - AXI data width

   * - ``AxiIdWidth``
     - ``int unsigned``
     - AXI ID width

   * - ``AxiUserWidth``
     - ``int unsigned``
     - AXI User width

   * - ``AxiBurstWriteEn``
     - ``bit``
     - AXI burst in write

   * - ``IcacheByteSize``
     - ``int unsigned``
     - Instruction cache size (in bytes)

   * - ``IcacheSetAssoc``
     - ``int unsigned``
     - Instruction cache associativity (number of ways)

   * - ``IcacheLineWidth``
     - ``int unsigned``
     - Instruction cache line width

   * - ``DCacheType``
     - ``cache_type_t``
     - Cache Type

   * - ``DcacheIdWidth``
     - ``int unsigned``
     - Data cache ID

   * - ``DcacheByteSize``
     - ``int unsigned``
     - Data cache size (in bytes)

   * - ``DcacheSetAssoc``
     - ``int unsigned``
     - Data cache associativity (number of ways)

   * - ``DcacheLineWidth``
     - ``int unsigned``
     - Data cache line width

   * - ``DcacheFlushOnFence``
     - ``bit``
     - DcacheInvalidateOnFlush causes dcache to also be invalidated when flushed

   * - ``DcacheFlushOnFenceI``
     - ``bit``
     - TO_BE_COMPLETED

   * - ``DcacheInvalidateOnFlush``
     - ``bit``
     - TO_BE_COMPLETED

   * - ``DataUserEn``
     - ``bit``
     - User field on data bus enable

   * - ``WtDcacheWbufDepth``
     - ``int unsigned``
     - Write-through data cache write buffer depth

   * - ``FetchUserEn``
     - ``bit``
     - User field on fetch bus enable

   * - ``FetchUserWidth``
     - ``int unsigned``
     - Width of fetch user field

   * - ``FpgaEn``
     - ``bit``
     - Is FPGA optimization of CV32A6 for Xilinx and Altera

   * - ``FpgaAlteraEn``
     - ``bit``
     - Is FPGA optimization for Altera FPGA

   * - ``TechnoCut``
     - ``bit``
     - Is Techno Cut instantiated

   * - ``SuperscalarEn``
     - ``bit``
     - Enable superscalar* with 2 issue ports and 2 commit ports.

   * - ``ALUBypass``
     - ``bit``
     - Enable ALU-ALU bypass (superscalar mode only)

   * - ``NrCommitPorts``
     - ``int unsigned``
     - Number of commit ports. Forced to 2 if SuperscalarEn.

   * - ``NrLoadPipeRegs``
     - ``int unsigned``
     - Load cycle latency number

   * - ``NrStorePipeRegs``
     - ``int unsigned``
     - Store cycle latency number

   * - ``NrScoreboardEntries``
     - ``int unsigned``
     - Scoreboard length

   * - ``NrLoadBufEntries``
     - ``int unsigned``
     - Load buffer entry buffer

   * - ``MaxOutstandingStores``
     - ``int unsigned``
     - Maximum number of outstanding stores

   * - ``RASDepth``
     - ``int unsigned``
     - Return address stack depth

   * - ``BTBEntries``
     - ``int unsigned``
     - Branch target buffer entries

   * - ``BHTEntries``
     - ``int unsigned``
     - Branch history entries

   * - ``InstrTlbEntries``
     - ``int unsigned``
     - MMU instruction TLB entries

   * - ``DataTlbEntries``
     - ``int unsigned``
     - MMU data TLB entries

   * - ``UseSharedTlb``
     - ``bit unsigned``
     - MMU option to use shared TLB

   * - ``SharedTlbDepth``
     - ``int unsigned``
     - MMU depth of shared TLB

   * - ``SvnapotEn``
     - ``bit``
     - Option to enable Svnapot extension

   * - ``ObiVersion``
     - ``int unsigned``
     - OBI version compliance, 0 means not compliant -> best performance

   * - ``PipelineOnly``
     - ``bit``
     - Configuration defines cva6_pipeline module as top instead of cva6 (no cache and OBI instead of AXI)

   * - ``NrStoreInFlight``
     - ``int unsigned``
     - the store bus and the memory.

   * - ``DclsEn``
     - ``bit``
     - DCLS parameters

   * - ``DclsDelay``
     - ``int unsigned``
     - Number of cycles o

   * - ``DclsCommonRegfile``
     - ``bit``
     - TO_BE_COMPLETED

   * - ``DclsCommonBHT``
     - ``bit``
     - TO_BE_COMPLETED
