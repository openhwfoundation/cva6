# test_setup.h
# Main riscv-arch-test test macros
# Jordan Carlin jcarlin@hmc.edu October 2025, Sadhvi Narayanan sanarayanan@hmc.edu February 2026
# SPDX-License-Identifier: BSD-3-Clause

/*************************************** RVTEST_BEGIN **************************************/
/**** RVTEST_BEGIN sets up the test environment and is run before the actual test code. ****/
/**** - sets up main entry point labels                                                 ****/
/**** - runs model specific boot code                                                   ****/
/**** - instantiate prologs using RVTEST_TRAP_PROLOG() if rvtests_xtrap_routine defined ****/
/**** - initializes regs                                                                ****/
/**** - defines rvtest_code_begin global label                                          ****/
/*******************************************************************************************/
.macro RVTEST_BEGIN
  // Set text section for code begin
  .section .text.init,"ax",@progbits
  .global rvtest_entry_point
  rvtest_entry_point:

  // Globally disable linker relaxation
  // The linker tries to simplify some code sequences (auipc + addi, jumps, etc.) by default.
  // This disables that behavior to ensure tests match the desired assembly. The unusual structure
  // of the ACT tests (compared to standard production code) also has a tendency to hit bugs in the
  // relaxation process (including incorrect addresses being loaded and c.nops being inserted when
  // they shouldn't be), so just disable it since we don't care about optimizations.
  .option push
  .option norelax

  // Disable assembler/linker optimizations for RVTEST_BEGIN
  // *** not sure this is still needed after recent simplifications.  dh 4/24/26
  .option push
  .option rvc
  .align UNROLLSZ
  .option norvc

  // Include model specific boot code
  // potentially long call to code after the data segment.
  LA(ra, rvmodel_boot)
  jalr ra

  // Create new section so that .align directives in the test code don't affect the
  // entry point address. The assembler increases a section's overall alignment to
  // the largest .align in that section, so any large .align used in a test would
  // increase .text.init's alignment, shifting rvtest_entry_point to an unexpected
  // address. Placing test code in its own section avoids that because the .text.rvtest
  // section will have its own alignment. This requires .text.init and .text.rvtest
  // to be in separate output sections in the linker script.
  .section .text.rvtest,"ax",@progbits

  // Test initialization
  // Start of test
  .global rvtest_code_begin
  rvtest_code_begin:

  .option pop
.endm
/*********************************** end of RVTEST_BEGIN ***********************************/


/************************************* RVTEST_CODE_END *************************************/
/**** RVTEST_CODE_END is run after the actual test code.                                ****/
/**** - Switch to M Mode                                                                ****/
/**** - Instantiate epilogs using RVTEST_TRAP_EPILOG() if rvtests_xtrap_routine defined ****/
/**** - Instantiate trap handlers for each priv mode                                    ****/
/**** - Include headers that contain code (not macros) that would throw off the address ****/
/**** - Terminate test with call to RVMODEL_HALT                                        ****/
/*******************************************************************************************/
.macro RVTEST_CODE_END
  // Disable assembler/linker optimizations for RVTEST_CODE_END
  .option push
  .option norvc
  .global rvtest_code_end       // define the label and make it available
  .global cleanup_epilogs       // ****ALERT: tests must populate x1 with a point to the end of regular sig area TODO: Is this still true?
  /**** MPRV must be clear here !!! ****/

  // Switch to M-mode
  // The following epilog and checks are needed if there is any trap handler.  Right now, it is not
  // invoked unless there is CONFORMING_SM_SUPPORTED.  A user with nonconforming M-mode will need
  // to reimplement many parts of this macro.
  rvtest_code_end:
    #ifdef CONFORMING_SM_SUPPORTED
      RVTEST_GOTO_MMODE
    #endif

  // Restore xTVEC, trampoline, regs for each mode in opposite order that they were saved
  cleanup_epilogs:
    #ifdef CONFORMING_SM_SUPPORTED
      #ifdef S_SUPPORTED
        #ifdef H_SUPPORTED
          RVTEST_TRAP_EPILOG V        // actual v-mode prolog/epilog/handler code
          RVTEST_TRAP_EPILOG H        // actual h-mode prolog/epilog/handler code
        #endif
        RVTEST_TRAP_EPILOG S          // actual s-mode prolog/epilog/handler code
      #endif
      RVTEST_TRAP_EPILOG M            // actual m-mode prolog/epilog/handler code
    #endif

  #ifdef CONFORMING_SM_SUPPORTED
    LI(     T4, 0xBAD0DEAD)           // T5 holds 0xBAD0DEAD if abort_test was executed
    bne     T4, T5, check_trap_sig_offset
    jal     T2, failedtest_trap_x7_x9
    RVTEST_WORD_PTR abort_test
    RVTEST_WORD_PTR abortstr
    .word   CSR_MEPC

    // Check trap signature offset to make sure the correct number of traps occurred
    check_trap_sig_offset:
      LA(     T1, Mtrap_sig)
      LREG    T1, 0(T1)               // Trap signature pointer
      LA(     T2, trap_sigptr)       // Base address of trap signature region
      sub     T1, T1, T2              // Calculate offset
      RVTEST_SIGUPD(x2, x5, x4, T1, check_trap_sig_offset, trap_sig_offset_mismatch)
  #endif

  // Terminate test
  exit_cleanup:
    LA(a0, successstr)
    call rvmodel_io_write_str
    call rvmodel_halt_pass

  // Terminate test with a failure message
  abort_test:
    LI(     T5, 0xBAD0DEAD)
    j       cleanup_epilogs

  // Instantiate trap handlers for each priv mode
  // Guard matches the RVTEST_TRAP_EPILOG guard above: rvtest_Mend (and sibling
  // labels) are defined by RVTEST_TRAP_EPILOG, so the handler that references
  // them must only be emitted when the epilog is also emitted.
  #ifdef CONFORMING_SM_SUPPORTED
  INSTANTIATE_MODE_MACRO RVTEST_TRAP_HANDLER
  #endif

  // Include test failure handling code
  RVTEST_FAILURE_CODE

  // All model-specific (RVMODEL_*) code lives in the dedicated .text.rvmodel
  // section, placed AFTER .data by the linker script. This isolates variable-
  // sized macro expansions (they differ between the DUT build and the Sail
  // reference build) from the .text section so that test-visible symbols in
  // .data (scratch, begin_signature, etc.) have identical addresses in both
  // the .elf and .sig.elf builds.
  .pushsection .text.rvmodel,"ax",@progbits
  // Model specific boot code
  rvmodel_boot:
    #ifdef RVMODEL_BOOT
      RVMODEL_BOOT
    #endif
    #ifdef RVMODEL_IO_INIT
      RVMODEL_IO_INIT(T1, T2, T3)
    #endif
    // always boot to at least M-mode
    RVTEST_BOOT_TO_MMODE
    #ifndef BOOT_TO_MMODE
      // the BOOT_TO_MMODE symbol will be defined in any tests that should run in M-mode.
      // otherwise continue to a lower privilege mode (if one exists) depending on the type of test
      #ifdef S_SUPPORTED
        RVTEST_BOOT_TO_SMODE
      #endif
      #ifndef BOOT_TO_SMODE
        // the BOOT_TO_SMODE symbol will be defined in any tests that should run in S-mode.
        // otherwise continue to U-mode if U-mode supported
        #ifdef U_SUPPORTED
          RVTEST_BOOT_TO_UMODE
        #endif
      #endif
    #endif

    RVTEST_INIT_REGS // Put deterministic values in each register

    LA (T1, rvtest_code_begin)
    jr T1                         // Jump back to the start of the test

  rvmodel_io_write_str:
    // a0 = string pointer; T1-T3 (x6-x8) are scratch. Clobbers ra.
    RVMODEL_IO_WRITE_STR(T1, T2, T3, a0)
    ret

  rvmodel_halt_pass:
    RVMODEL_HALT_PASS
    j . // Explicit non-returning tail if the macro returns (it should not)

  rvmodel_halt_fail:
    RVMODEL_HALT_FAIL
    j . // Explicit non-returning tail if the macro returns (it should not)

  // ***DH 4/8/26 check this is proper gating
  #ifdef CONFORMING_SM_SUPPORTED
    rvtest_set_msw_int:
      RVMODEL_SET_MSW_INT(T2, T5)
      ret

    rvtest_clr_msw_int:
      RVMODEL_CLR_MSW_INT(T2, T5)
      ret

    rvtest_set_mext_int:
      RVMODEL_SET_MEXT_INT(T2, T5)
      ret

    rvtest_clr_mext_int:
      RVMODEL_CLR_MEXT_INT(T2, T5)
      ret
  #endif

  #ifdef S_SUPPORTED
    rvtest_set_ssw_int:
      RVMODEL_SET_SSW_INT(T2, T5)
      ret

    rvtest_clr_ssw_int:
      RVMODEL_CLR_SSW_INT(T2, T5)
      li T2, 2
      csrc mip, T2              /* Always called from M-mode; mip.SSIP must be cleared via mip */
      ret

    rvtest_set_sext_int:
      RVMODEL_SET_SEXT_INT(T2, T5)
      ret

    rvtest_clr_sext_int:
      RVMODEL_CLR_SEXT_INT(T2, T5)
      LI(T3, 512)
      csrc sip, T3 // clear sip.SEIP
      ret
  #endif

  nop // Padding to ensure valid memory at the edge of the section

  .popsection

  .option pop

  // Pop the .option norelax from RVTEST_BEGIN
  .option pop
.endm
/******************************** end of RVTEST_CODE_END ***********************************/


/************************************ RVTEST_DATA_BEGIN ************************************/
/**** RVTEST_DATA_BEGIN appears after RVTEST_CODE_END and creates several data regions  ****/
/**** - Scratch region for temporary data storage                                       ****/
/**** - Save areas for each priv mode trap handler                                      ****/
/**** - Defines the start of the test data region                                       ****/
/*******************************************************************************************/
.macro RVTEST_DATA_BEGIN
  // Scratch region of memory for tests (ie for loads/stores that are not part of signature)
  // Initialized with distinct values so tests can detect unintended zeroing or aliasing,
  // while remaining obviously recognizable as uninitialized scratch defaults.
  // 264 bytes = 33 doublewords (needed for atomic reservation tests with offsets up to 256 bytes)
  .data
  .align 8
  scratch:
    .dword 0xDEAD0001FFFEBEEF, 0xDEAD0002FFFDBEEF
    .dword 0xDEAD0003FFFCBEEF, 0xDEAD0004FFFBBEEF
    .dword 0xDEAD0005FFFABEEF, 0xDEAD0006FFF9BEEF
    .dword 0xDEAD0007FFF8BEEF, 0xDEAD0008FFF7BEEF
    .dword 0xDEAD0009FFF6BEEF, 0xDEAD000AFFF5BEEF
    .dword 0xDEAD000BFFF4BEEF, 0xDEAD000CFFF3BEEF
    .dword 0xDEAD000DFFF2BEEF, 0xDEAD000EFFF1BEEF
    .dword 0xDEAD000FFFF0BEEF, 0xDEAD0010FFEFBEEF
    .dword 0xDEAD0011FFEEBEEF, 0xDEAD0012FFEDBEEF
    .dword 0xDEAD0013FFECBEEF, 0xDEAD0014FFEBBEEF
    .dword 0xDEAD0015FFEABEEF, 0xDEAD0016FFE9BEEF
    .dword 0xDEAD0017FFE8BEEF, 0xDEAD0018FFE7BEEF
    .dword 0xDEAD0019FFE6BEEF, 0xDEAD001AFFE5BEEF
    .dword 0xDEAD001BFFE4BEEF, 0xDEAD001CFFE3BEEF
    .dword 0xDEAD001DFFE2BEEF, 0xDEAD001EFFE1BEEF
    .dword 0xDEAD001FFFE0BEEF, 0xDEAD0020FFDFBEEF
    .dword 0xDEAD0021FFDEBEEF

  .align 4

  // Create separate save areas for each priv mode trap handler
  // Guard matches RVTEST_TRAP_HANDLER guard: RVTEST_TRAP_SAVEAREA references
  // Mtrampoline (and sibling labels) which are only defined when RVTEST_TRAP_HANDLER
  // is instantiated.
  #ifdef CONFORMING_SM_SUPPORTED
  INSTANTIATE_MODE_MACRO RVTEST_TRAP_SAVEAREA
  #endif

  // Data for use in test
  .align 4
  .global rvtest_data_begin
  rvtest_data_begin:
.endm
/********************************** end of RVTEST_DATA_BEGIN *******************************/


/************************************* RVTEST_DATA_END *************************************/
/**** RVTEST_DATA_END appears after test data                                           ****/
/**** - MMU page tables (filled with invalid PTEs)                                      ****/
/**** - End of data region label (rvtest_data_end)                                      ****/
/*******************************************************************************************/
.macro RVTEST_DATA_END

  // Root page tables
  #ifdef S_SUPPORTED
    .align 12
    rvtest_Sroot_pg_tbl:
      .zero(4096)                // 4KB page table
    #ifdef H_SUPPORTED
      .align 14
      rvtest_Hroot_pg_tbl:
        .zero(16384)               // 16KB page table
      .align 12
      rvtest_Vroot_pg_tbl:
        .zero(4096)              // 4KB page table
    #endif
  #endif

  // Failure detection data (strings and scratch space)
  RVTEST_FAILURE_DATA

  // End of data region
  .global rvtest_data_end
  rvtest_data_end:
.endm
/*********************************** end of RVTEST_DATA_END ********************************/


/************************************* RVTEST_SIG_SETUP ************************************/
/**** RVTEST_SIG_SETUP creates signature region to support self-checking tests          ****/
/**** - Main signature region for results from test, initialized with correct values    ****/
/****   for self-checking                                                               ****/
/**** - Trap handler signature region                                                   ****/
/*******************************************************************************************/
.macro RVTEST_SIG_SETUP
  .align 4
  .global begin_signature
  begin_signature:
  .global rvtest_sig_begin
  rvtest_sig_begin:

    // Main signature region
    #ifdef RVTEST_SELFCHECK
        signature_base:
          // Preload signature region with correct values for self-checking
          #include SIGNATURE_FILE
    #else
      // Canary is the first entry in the signature region; the dynamic canary
      // check at test start reads and verifies this value to ensure the signature
      // mechanism is functioning correctly.
      signature_base:
        CANARY
        // Initialize remaining signature region to known value for initial pass
        .fill SIGUPD_COUNT*(SIG_STRIDE>>2),4,0xdeadbeef

      // Signature region for trap handlers
      tsig_begin_canary:
        TRAP_CANARY

      trap_sigptr:
          .fill TRAP_SIGUPD_COUNT*(SIG_STRIDE>>2),4,0xdeadbeef

      // Create canary at end of signature region to detect overwrites
      sig_end_canary:
        CANARY
    #endif

  .align 4
  .global rvtest_sig_end
  rvtest_sig_end:
  .global end_signature
  end_signature:

  // Model specific data region (tohost/fromhost, etc). Defined in rvmodel_macros.h.
  // Placed after the signature so variable-size DUT data does not affect any
  // test-visible symbol addresses.
  RVMODEL_DATA_SECTION
.endm
/*********************************** end of RVTEST_SIG_SETUP *********************************/


/************************************ RVTEST_BOOT_TO_M_MODE ********************************/
/**** Set up M-mode trap handler and initialize M-mode CSRs                             ****/
/**** Can be overridden by DUT-specific RVMODEL_BOOT_TO_MMODE if no conforming M-mode   ****/
/*******************************************************************************************/
.macro RVTEST_BOOT_TO_MMODE
  #ifdef RVMODEL_BOOT_TO_MMODE
    // Run custom RVMODEL flavor if the DUT provides it to override this default boot
    RVMODEL_BOOT_TO_MMODE
  #else
    rvtest_boot_to_mmode:
    // Default implementation assumes conforming M-mode or no M-mode registers
    // We are in M-mode now at initial boot time

    // Do setup that requires a conforming M-mode
    #ifdef CONFORMING_SM_SUPPORTED

      // Disable interrupts
      csrw mie, zero
      csrw mip, zero

      // disable trap delegation
      #ifdef S_SUPPORTED
        csrw mideleg, zero  // don't delegate interrupts (until S-mode handler is set up)
        csrw medeleg, zero  // don't delegate exceptions (until S-mode handler is set up)
      #endif

      // initialize trap CSRs to known values
      // mtvec is included so the prolog's save/restore captures a deterministic
      // reset value (CVA6 resets mtvec to 0x80000040, Spike resets it to 0;
      // without this write the saved value diverges between simulators).
      csrw mtvec, zero
      csrw mepc, zero
      csrw mtval, zero
      csrw mcause, zero

      // Set up trap handlers for all modes
      // S and H-mode setup could be deferred to RVTEST_BOOT_TO_SMODE, but that is upsetting the linker
      // and there is no harm setting up all the trap handlers here
      RVTEST_TRAP_PROLOG M
      #ifdef S_SUPPORTED
        RVTEST_TRAP_PROLOG S
        #ifdef H_SUPPORTED
          RVTEST_TRAP_PROLOG H
          RVTEST_TRAP_PROLOG V
        #endif
      #endif

    rvtest_boot_to_mmode_csr_init:
      // Initialize M-mode CSRs

      // Put mstatus in a known initial state.
      // mstatus.SIE = 0: Disable S-mode interrupts
      // mstatus.MIE = 0: Disable M-mode interrupts
      // mstatus.SPIE = 0: Clear S-mode previous interrupt enable bit
      // mstatus.UBE = 0: User-mode Little Endian
      // mstatus.MPIE = 0: Clear M-mode previous interrupt enable bit
      // mstatus.SPP = 0: Clear previous privilege mode bit (set to U-mode)
      // mstatus.XS = 00: Set custom state to OFF
      // mstatus.FS = 00: Set floating-point state to OFF
      // mstatus.VS = 00: Set vector state to OFF
      // mstatus.MPRV = 0: Disable MPRV so memory accesses are in M-mode
      // mstatus.SUM = 0: Disable supervisor access to user memory
      // mstatus.MXR = 0: Disable Make eXecutable Readable
      // mstatus.TVM = 0: Disable Trap Virtual Memory
      // mstatus.TW = 0: Disable Timeout Wait
      // mstatus.TSR = 0: Enable SRET instruction when S-mode supported
      // mstatus.MPP = 11: Set previous privilege mode to M-mode
      // mstatus.UXL = XLEN (RV64 only)
      // mstatus.SXL = XLEN (RV64 only)
      // mstatus.SBE = 0: Set S-mode to little endian if supported
      // mstatus.MBE = 0: Set M-mode to little endian if supported
      // mstatus.GVA = 0: Guest virtual address
      // mstatus.MPV = 0: Previous virtualization OFF
      // mstatus.MPELP = 0: Disable landing pads
      // mstatus.MDT = 0: Disable double trap
      #if __riscv_xlen == 64
        #define MSTATUS_UXL_64         0x0000000200000000
        #define MSTATUS_SXL_64         0x0000000800000000
        li t0, MSTATUS_MPP | MSTATUS_UXL_64 | MSTATUS_SXL_64
        csrw mstatus, t0  // Set just all these fields
      #else    // RV32
        li t0, MSTATUS_MPP
        csrw mstatus, t0
        csrw mstatush, zero // Clear all these fields
      #endif

      // Disable all privileged environment configuration, and enable unprivileged configuration
      // Privileged tests that want to use these features should turn them on
      // Unprivileged tests don't make SBI calls so the features should already be enabled
      // menvcfg.STCE = 0: Disable Sstc supervisor timer compare
      // menvcfg.PBMTE = 0: Disable Svpbmt page-based memory types
      // menvcfg.ADUE = 0: Disable Svadu A/D bit update
      // menvcfg.CDE = 0: Disable counter delegation ***check
      // menvcfg.DTE = 0: Disable Ssdbltrp double traps
      // menvcfg.PMM = 00: Disable Smnpm pointer masking at next lower privilege mode
      // menvcfg.SSE = 0: Disable Zicfiss shadow stacks
      // menvcfg.LPE = 0: Disable Zicfilp landing pads
      // menvcfg.FIOM = 0: Disable Fence of I/O Implies Memory
      // menvcfg.CBZE = 1: Enable Zicboz cache block zero instructions
      // menvcfg.CBCFE = 1: Enable Zicbom cache block clean/flush instructions
      // menvcfg.CBIE = 11: Enable Zicbom cache block invalidate instructions to perform invalidate operation
      #ifdef U_SUPPORTED // menvcfg only exists if U-mode is supported
        li t0, MENVCFG_CBIE | MENVCFG_CBCFE | MENVCFG_CBZE
        csrw menvcfg, t0
        #if __riscv_xlen == 32
          csrw menvcfgh, zero // Clear upper bits if they exist
        #endif
      #endif

      // Enable necessary state for unpriv instructions
      // Disable privileged extensions until they are turned on explicitly by tests that need them
      // mstateen0.SE0 = 0: disable access to hststateen0, hstatene0h, ssstateen0
      // mstateen0.ENVCFG = 0: disable access to henvcfg, henvcfgh, senvcfg
      // mstateen0.CSRIND = 0: disable access to Sscrind siselect, sireg* registers (until turned on for those tests)
      // mstateen0.AIA = 0: disable access to Ssaia advanced interrupt architecture state
      // mstateen0.IMSIC = 0: disable access to MISIC state
      // mstateen0.P1P13 = 0: disable access to hedelegh for 1P13 until turned on
      // mstateen0.SRMCFG = 0: disable access to srmcfg for Ssqosid until turned on
      // mstateen0.CTR = 0: disable access to Smctr control transfer records until turned on
      // mstateen0.JVT = 1: Enable jvt for Zcmt
      // mstateen0.FCSR = 1: Enable fcsr access for Zfinx only if supported ZFINX_SUPPORTED (to avoid conflicts with F)
      // mstateen0.C = 0: Disable custom state
      #ifdef SMSTATEEN_SUPPORTED
        #if __riscv_xlen == 64
          li t0, MSTATEEN0_JVT
          csrw mstateen0, t0
        #else    // RV32
          csrw mstateen0h, zero
          li t0, MSTATEEN0_JVT
          csrw mstateen0, t0
        #endif
        #ifdef ZFINX_SUPPORTED
          li t0, MSTATEEN0_FCSR
          csrs mstateen0, t0 // Set mstateen0.FCSR
          li t0, 0
        #endif
      #endif

      // Enable all performance counters if they exist
      // This is reserved if mcountinhibit is not implemented, and might trap or have unspecified behavior
      //   *** need to define a UDB parameter MCOUNTINHIBIT_IMPLEMENTED to determine whether mcountinhibit is implemented
      //   see https://github.com/riscv/riscv-isa-manual/issues/2964
      csrw mcountinhibit, zero

      // Initialize counter event selectors to 0.  They must be implemented.
      csrw mhpmevent3, zero
      csrw mhpmevent4, zero
      csrw mhpmevent5, zero
      csrw mhpmevent6, zero
      csrw mhpmevent7, zero
      csrw mhpmevent8, zero
      csrw mhpmevent9, zero
      csrw mhpmevent10, zero
      csrw mhpmevent11, zero
      csrw mhpmevent12, zero
      csrw mhpmevent13, zero
      csrw mhpmevent14, zero
      csrw mhpmevent15, zero
      csrw mhpmevent16, zero
      csrw mhpmevent17, zero
      csrw mhpmevent18, zero
      csrw mhpmevent19, zero
      csrw mhpmevent20, zero
      csrw mhpmevent21, zero
      csrw mhpmevent22, zero
      csrw mhpmevent23, zero
      csrw mhpmevent24, zero
      csrw mhpmevent25, zero
      csrw mhpmevent26, zero
      csrw mhpmevent27, zero
      csrw mhpmevent28, zero
      csrw mhpmevent29, zero
      csrw mhpmevent30, zero
      csrw mhpmevent31, zero
      #if __riscv_xlen == 32
        csrw mhpmevent3h, zero
        csrw mhpmevent4h, zero
        csrw mhpmevent5h, zero
        csrw mhpmevent6h, zero
        csrw mhpmevent7h, zero
        csrw mhpmevent8h, zero
        csrw mhpmevent9h, zero
        csrw mhpmevent10h, zero
        csrw mhpmevent11h, zero
        csrw mhpmevent12h, zero
        csrw mhpmevent13h, zero
        csrw mhpmevent14h, zero
        csrw mhpmevent15h, zero
        csrw mhpmevent16h, zero
        csrw mhpmevent17h, zero
        csrw mhpmevent18h, zero
        csrw mhpmevent19h, zero
        csrw mhpmevent20h, zero
        csrw mhpmevent21h, zero
        csrw mhpmevent22h, zero
        csrw mhpmevent23h, zero
        csrw mhpmevent24h, zero
        csrw mhpmevent25h, zero
        csrw mhpmevent26h, zero
        csrw mhpmevent27h, zero
        csrw mhpmevent28h, zero
        csrw mhpmevent29h, zero
        csrw mhpmevent30h, zero
        csrw mhpmevent31h, zero
      #endif

      // make counters accessible to a lower privilege mode if one exists
      #ifdef U_SUPPORTED
        li t0, -1
        csrw mcounteren, t0 // Enable all counters for access from next lower priv mode
      #endif

      // msseccfg.MLL, MMWP, RLB, USEED, and SSEED reset to defined values.
      // if Pointer Masking is supported, mseccfg.PMM should be initialized to 0 to turn it off
      // might as well turn off everything
      #ifdef SMMPM_SUPPORTED
        csrw mseccfg, zero
      #endif

      #ifdef SMRNMI_SUPPORTED
        // if Resumable NMI supported, also clear all RNMI-related fields, especially mnstatus.NMIE
        csrw mnstatus, zero // Clear all fields in mnstatus as well if it exists
      #endif

      #if (RVMODEL_NUM_PMPS > 0) && defined(U_SUPPORTED)
        // set up PMP so user and supervisor mode can access full address space
        CSRW(pmpcfg0, 0xF)   // configure PMP0 to TOR RWX
        LI(t0, -1)
        CSRW(pmpaddr0, t0)   // configure PMP0 top of range to 0xFFF...FFF to allow all addresses
        // sfence.vma is required after PMP entries are changed to sync the PMP with the virtual
        // memory system and any PMP or address translation caches. sfence.vma should not be
        // performed in a system that does not support virtual memory because it might raise
        // an illegal instruction.
        #if defined(SV32_SUPPORTED) || defined(SV39_SUPPORTED)
          csrw satp, zero // Sv BARE mode
          sfence.vma
        #endif // SV32 or SV39
      #endif // PMP
    #endif // CONFORMING_M_MODE

  #endif // !RVMODEL_BOOT_TO_MMODE

  // Init floating-point and vector state if necessary, even if the rest of M-mode is not implemented
  INIT_FLOAT_VECTOR_STATE
.endm

/************************************ RVTEST_BOOT_TO_S_MODE ********************************/
/**** Set up S-mode trap handler and initialize S-mode CSRs                             ****/
/**** Switch into S-mode                                                                ****/
/*******************************************************************************************/
.macro RVTEST_BOOT_TO_SMODE
  // We start in M-mode after initial boot but cannot assume it is conforming
  // so access to M-mode features must be through a SBI

  // Run custom RVMODEL flavor if the DUT provides it to override this default boot
  #ifdef RVMODEL_BOOT_TO_SMODE
    RVMODEL_BOOT_TO_SMODE
  #else
    rvtest_boot_to_smode:
    // Default implementation assumes conforming M-mode
    // We are in M-mode now at initial boot time
    // The M-mode boot already set up S, HS, VS trap handlers if applicable.

    // Delegate exceptions to S-mode, except those that must be directed to M-mode
    // medeleg[0] = 1: delegate instruction address misaligned exception
    // medeleg[1] = 1: delegate instruction access fault exception
    // medeleg[2] = 1: delegate illegal instruction exception
    // medeleg[3] = 1: delegate breakpoint exception
    // medeleg[4] = 1: delegate load address misaligned exception
    // medeleg[5] = 1: delegate load access fault exception
    // medeleg[6] = 1: delegate store/AMO address misaligned exception
    // medeleg[7] = 1: delegate store/AMO access fault exception
    // medeleg[8] = 1: delegate environment call from U-mode exception
    // medeleg[9] = 0: do not delegate environment call from S/HS-mode exception because SBI needs to reach M-mode
    // medeleg[10] = 1: delegate environment call from VS-mode exception
    // medeleg[11] = 0: do not delegate environment call from M-mode because that makes no sense
    // medeleg[12] = 1: delegate instruction page fault exception
    // medeleg[13] = 1: delegate load page fault exception
    // medeleg[14] = 0: reserved
    // medeleg[15] = 1: delegate store/AMO page fault exception
    // medeleg[16] = 0: do not delegate double trap because this is a M-mode feature
    // medeleg[17] = 0: reserved
    // medeleg[18] = 1: delegate software check
    // medeleg[19] = 1: delegate hardware check
    // mideleg[20] = 1: delegate instruction guest-page fault
    // mideleg[21] = 1: delegate load guest-page fault
    // medeleg[22] = 1: delegate virtual instruction
    // mideleg[23] = 1: delegate store guest-page fault
    // higher bits are reserved or custom
    li t0, 0x0FCB5FF
    li t0, 0x0FCB0FF # *** dh 4/24/26 temporary don't delegate any ecalls until SBI forwarding is implemented
    csrw medeleg, t0

    // Delegate supervisor interrupts to S-mode. Do not delege M-mode interrupts.
    // mideleg.SSIP = 1: delegate supervisor software interrupts
    // mideleg.STIP = 1: delegate supervisor timer interrupts
    // mideleg.SEIP = 1: delegate supervisor external interrupts
    // mideleg.VSSIP = 1: delegate virtual supervisor software interrupts if applicable
    // mideleg.VSTIP = 1: delegate virtual supervisor timer interrupts if applicable
    // mideleg.VSEIP = 1: delegate virtual supervisor external interrupts if applicable
    // mideleg.LCOFIP = 1: delegate counter overflow interrupts if applicable
    // mideleg.SGEIP = 1: delegate supervisor guest external interrupts if applicable
    // mideleg.MSIP = 0: don't delegate machine software interrupts
    // mideleg.MTIP = 0: don't delegate machine timer interrupts
    // mideleg.MEIP = 0: don't delegate machine external interrupts
    li t0, 0x3666
    csrw mideleg, t0

    // Enable necessary state for access from lower privilege modes
    // mstateen0.SE0 = 1: enable access to hststateen0, hstatene0h, ssstateen0
    // mstateen0.ENVCFG = 1: enable access to henvcfg, henvcfgh, senvcfg
    // sstateen0.JVT = 1: Enable jvt for Zcmt
    // sstateen0.FCSR = 1: Enable fcsr access for Zfinx only if supported ZFINX_SUPPORTED (to avoid conflicts with F)
    // sstateen0.C = 0: Disable custom state

    #ifdef SMSTATEEN_SUPPORTED
      #if __riscv_xlen == 64
        li t0, MSTATEEN_HSTATEEN | MSTATEEN0_HENVCFG
        csrs mstateen0, t0  // Set these fields
      #else    // RV32
        li t0, MSTATEENH_HSTATEEN | MSTATEEN0H_HENVCFG
        csrs mstateen0h, t0 // Set these fields
      #endif
    #endif
    #ifdef SSSTATEEN_SUPPORTED
      li t0, SMSTATEEN0_JVT | SMSTATEEN0_FCSR
      csrs sstateen0, t0 // enable access from lower privilege mode
    #endif

    // Initialize S-mode CSRs

    // make counters accessible to a lower privilege mode if one exists
    li t0, -1
    csrw scounteren, t0 // Enable all counters for access from next lower priv mode

    // Disable all privileged environment configuration, and enable unprivileged configuration
    // Privileged tests that want to use these features should turn them on
    // Unprivileged tests don't make SBI calls so the features should already be enabled
    // senvcfg.PMM = 00: Disable Smnpm pointer masking at next lower privilege mode (RV64 only)
    // senvcfg.SSE = 0: Disable Zicfiss shadow stacks
    // senvcfg.LPE = 0: Disable Zicfilp landing pads
    // senvcfg.FIOM = 0: Disable Fence of I/O Implies Memory
    // senvcfg.CBZE = 1: Enable Zicboz cache block zero instructions
    // senvcfg.CBCFE = 1: Enable Zicbom cache block clean/flush instructions
    // senvcfg.CBIE = 11: Enable Zicbom cache block invalidate instructions to perform invalidate operation
    li t0, SENVCFG_CBIE | SENVCFG_CBCFE | SENVCFG_CBZE
    csrw senvcfg, t0

    // Boot into S-mode
    # RVMODEL_GOTO_LOWER_MODE SMODE
  #endif
.endm

/************************************ RVTEST_BOOT_TO_U_MODE ********************************/
/**** Switch into U-mode                                                                ****/
/*******************************************************************************************/
.macro RVTEST_BOOT_TO_UMODE
  // We arrive here in S-mode if S_SUPPORTED, else in M-mode.

  // Run custom RVMODEL flavor if the DUT provides it to override this default boot
  #ifdef RVMODEL_BOOT_TO_UMODE
    RVMODEL_BOOT_TO_UMODE
  #else
    rvtest_boot_to_umode:
    // Boot into U-mode
    #ifdef S_SUPPORTED
      // RVTEST_GOTO_LOWER_MODE UMODE // *** need a version that works from S-mode
    #else
      // if S-mode not supported, we must be in M-mode, so we can just switch to U-mode without an SBI call
      // RVTEST_GOTO_LOWER_MODE UMODE
    #endif
  #endif
  nop
.endm

/************************************ INIT_FLOAT_VECTOR_STATE ********************************/
/**** Initialize floating-point and vector state                                          ****/
/*******************************************************************************************/
.macro INIT_FLOAT_VECTOR_STATE

    // Additional setup that applies even without conforming M-mode
    // mstatus.FS = 11: Set floating-point state to dirty if supported (F or Zfinx)
    // mstatus.VS = 11: Set vector state to dirty if supported (V)
    // If mstatus is not writable at boot time, use a custom RVMODEL_BOOT_TO_MMODE to set up the necessary state
    // for floating-point and vector
    #if defined(F_SUPPORTED) || defined(ZFINX_SUPPORTED)
      li t0, MSTATUS_FS
      csrs mstatus, t0 // Set FS to dirty to enable floating-point
      csrw fcsr, zero // Initialize fcsr
    #endif
    #ifdef ZVL32B_SUPPORTED  // this should be defined if there is any vector support whatsoever
      li t0, MSTATUS_VS
      csrs mstatus, t0 // Set VS to dirty to enable vector
    #endif
.endm

/*****************************************************************/
/**** helper macro to initialize regs, just to make sure you catch any errors ****/
/*****************************************************************/

.macro DBLSHIFTR dstreg,     oldreg,    tmpreg, shamt       //this is just a rotate  using xtmp as a tmp
        slli    \tmpreg\(), \oldreg\(),   XLEN-\shamt
        srli    \dstreg\(), \oldreg\(),        \shamt
        or      \dstreg\(), \dstreg\(), \tmpreg\()
.endm

/************************************ RVTEST_INIT_REGS ********************************/
/**** Initialize registers and signature/data pointers                             ****/
/**************************************************************************************/
.macro RVTEST_INIT_REGS
  /* init regs, to ensure you catch any errors */
  rvtest_init_regs:

  #ifndef RVTEST_E
    LI (x16, (0x7D5BFDDB7D5BFDDB & MASK))
    DBLSHIFTR x17, x16, x15, 7
    DBLSHIFTR x18, x17, x15, 7
    DBLSHIFTR x19, x18, x15, 7
    DBLSHIFTR x20, x19, x15, 7
    DBLSHIFTR x21, x20, x15, 7
    DBLSHIFTR x22, x21, x15, 7
    DBLSHIFTR x23, x22, x15, 7
    DBLSHIFTR x24, x23, x15, 7
    DBLSHIFTR x25, x24, x15, 7
    DBLSHIFTR x26, x25, x15, 7
    DBLSHIFTR x27, x26, x15, 7
    DBLSHIFTR x28, x27, x15, 7
    DBLSHIFTR x29, x28, x15, 7
    DBLSHIFTR x30, x29, x15, 7
    DBLSHIFTR x31, x30, x15, 7
  #endif
    LI (x1,  (0xFEEDBEADFEEDBEAD & MASK))
    DBLSHIFTR x2,  x1,  x15, 7
    DBLSHIFTR x3,  x2,  x15, 7
    DBLSHIFTR x4,  x3,  x15, 7
    DBLSHIFTR x5,  x4,  x15, 7
    DBLSHIFTR x6,  x5,  x15, 7
    DBLSHIFTR x7,  x6,  x15, 7
    DBLSHIFTR x8,  x7,  x15, 7
    DBLSHIFTR x9,  x8,  x15, 7
    DBLSHIFTR x10, x9,  x15, 7
    DBLSHIFTR x11, x10, x15, 7
    DBLSHIFTR x12, x11, x15, 7
    DBLSHIFTR x13, x12, x15, 7
    DBLSHIFTR x14, x13, x15, 7
    LI (x15, (0xFAB7FBB6FAB7FBB6 & MASK))

    // Initialize signature pointer
    LA(DEFAULT_SIG_REG, signature_base)

    // Initial signature check to confirm self-checking is working
    canary_check:
    LI(T1, CANARY_VALUE)
    #ifdef RVTEST_SELFCHECK
      // Can't use DEFAULT_*_REG macros here because of macro expansion order
      // DEFAULT_SIG_REG = x2, DEFAULT_TEMP_REG = x4, DEFAULT_LINK_REG = x5
      RVTEST_SIGUPD(x2, x5, x4, T1, canary_check, canary_mismatch) # signature_base canary
    #else
      // Increment sig pointer to skip the CANARY
      addi DEFAULT_SIG_REG, DEFAULT_SIG_REG, SIG_STRIDE
      // NOPs to keep the emitted code size/bytes aligned with the RVTEST_SIGUPD sequence
      // used in self-check mode (including its embedded pointer words/dwords).
      nop
      nop
      nop
      nop
      nop
      #if __riscv_xlen == 64
        nop
        nop
      #endif
    #endif
    // Initialize test data pointer
    LA(DEFAULT_DATA_REG, rvtest_data_begin)
.endm
