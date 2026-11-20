// ***DELETEME** note to self
// this version adds instret counts to the signature
// this version modifies the LA macro to skip generation if rd=x0 (or X0)
// this version detects ECALL cause even in CLIC mode
// need to ensure that user defined macros that are inline in tests are JALs so that test stays the same length

// -----------
// Copyright (c) 2020-2023. RISC-V International. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
// -----------

        //********************************************************************************
        //********** FIXME: these comments are now completely out of order****************
        //********************************************************************************

// NOTE: Users with a non-conforming M-mode that cannot run this trap handler may
//      need to reimplement this entire file with their own custom version.  Use a custom
//      RVMODEL_BOOT_TO_MMODE to initialize the custom trap handler.
// This file is divided into the following sections:
//      RV Arch Test Constants
//      general test and helper macros, required,  optional, or just useful
//         _ARGn, SIG[BASE/UPD[_F/ID]],BASEUPD,BIT,LA ,LI,RVTEST_[INIT/SAVE]_GPRS, XCSR_RENAME
//      RV ARCH Test Interrupt Macros ****FIXME:spec which regs must not be altered
//      primary macros used by handle: RVTEST_TRAP_[PROLOG/HANDLER/EPILOG/SAVEAREA]
//      required test format spec macros:      RVTEST_[CODE/DATA/SIG]_[BEGIN/_END]
//      macros from Andrew Waterman's risc-v test macros
//      deprecated macro name aliases, just for migration ease

//  The resulting memory layout of the trap handler is (MACRO_NAME, label [function])

//********************************************************
//  (code section) - align to 4k boundary?               *
//********************************************************

//****************************************************************
// RVTEST_CODE_BEGIN                                             *
//      rvtest_init:       [TRAP_PROLOG] (m, ms,  mhsv) init CSRs and maybe trampoline
//                         [INIT_GPRS]   optionally save initial minstret
//      rvtest_code_begin: j rvtest_entry_pt  ***all variable length stuff is there
//****************************************************************
//
//*****************************
//********(body of tests)******
//*****************************
//
//****************************************************************
// RVTEST_CODE_END                                               *
//      rvtest_code_end:   [*optional* SAVE_GPRS routine]        *
//                         [*optional* save instret routine]     *
//                         [RVTEST_GOTO_MMODE] **WARNING**  fails if code/data/sig regions have discontiguous PAs
//      cleanup_epilogs    [TRAP_EPILOG   (m, mu, msu, mhsu)] (jump to exit_cleanup)
//      exit_cleanup:      [RVMODEL_HALT macro or a branch to it]*
//                         [TRAP_HANDLER  (m, mu, msu, mhsu)]    *
//      rvtest_entry_pt:   [RVMODEL_BOOT]  [boot code] (BOOT codealso has RVMODEL macro definitions which are >1 op)
//          j rvtest_init                                        *
//****************************************************************
//
//    *******************************************
//    *  (Data section) - align to 4K boundary  *
//    *******************************************
//
//****************************************************************
// RVTEST_DATA_BEGIN       data needed by trap handler           *
//                                                               *
//    RVTEST_TRAP_SAVEAREA M/H/S/V  per mode handler sv area(m, ms, or msv) temp reg save, CSRs, tramp table, ptrs]
//      <X>tramptbl_sv: contains the boot trap saved trampoline if required
//      <X>save_area: test config data: code/data/sig/virt region addr/ sizes, curr trap sig ptr, saved CSRs,
//      <X>trapreg_sv: Xregs used by trap handler                *
//                                                               *
//      rvtest_data_begin: [input data     (shared by all modes)] includes current trap_sig_ptr
//****************************************************************
//
//    *******************************************
//    *      (Ld/St test data is here)          *
//    *******************************************
//
//****************************************************************
//    RVTEST_DATA_END                                            *
//      RVTEST_ROOT_PG_TBL [sets up identity map (VA=PA)         *
//      sroot_pg_tbl:   (if smode)                               *
//      vroot_pg_tbl:   (if hypervisor)                          *
//      rvtest_data_end:                                         *
//****************************************************************
//
//    *******************************************
//    *   (Sig section) - align to 4K boundary  *
//    *******************************************
//
//****************************************************************
// RVTEST_SIG_BEGIN                                              *
//    RVMODEL_DATA_BEGIN                                         *
//    rvtest_sig_begin:  [signature bgn, used by sign dump, can be used by tests]
//****************************************************************
//
//****************************************************************
// RVTEST_TSIG_BEGIN                                             *
////    trap_sigptr:                                            *
//****************************************************************
//
//    *********************************************
//    *     optional trap Sig section             *
//    *********************************************
//
//****************************************************************
// RVTEST_SIG_END                                                *
//    gpr_save:          [gpr save area (optional, enabled if rvtest_gpr_save is defined)]
//    rvtest_sig_end:   [global test   end signature (shared by all modes)] (shouldn't matter what RVMODEL_DATA_END does)
//    RVMODEL_DATA_END                                           *
//****************************************************************
//--------------------------------end of test--------------------------------

/* The following macros are optional if interrupt tests are enabled (defaulted if not defined):
        RVMODEL_SET_[M/H/S/V][SW]_INT
        RVMODEL_CLR_[M/H/S/V][SW/TIMTER/EXT]_INT
        rvtest_[M/H/S/V]trap_routine
        GOTO_[M/H/S/U]MODE, INSTANTIATE_MODE_MACRO (prolog/handler/epilog/savearea)
   The following are general parameter initialization
        RVMODEL_MTVEC_ALIGN
        RVMODEL_CBZ_BLOCKSIZE
        RVMODEL_CMO_BLOCKSIZE
        RVMODEL_CLEAN_SIG
   The following variables are used     if interrupt tests are enabled (defaulted if not defined):
        NUM_SPECD_INTCAUSES
   The following variables are optional:
        rvtest_gpr_save: if defined, stores GPR contents into signature at test end (for debug)
   The following labels are required and defined by required macros:
        rvtest_code_begin:   defined by RVTEST_CODE_BEGIN  macro (boot code called here, but located in code_end)
        rvtest_code_end:     defined by RVTEST_CODE_END    macro (trap handlers follow this)
        rvtest_data_begin:   defined by RVTEST_DATA_BEGIN  macro
        rvtest_data_end:     defined by RVTEST_DATA_END    macro
        rvtest_sig_begin:    defined by RVTEST_SIG_BEGIN   macro (after  RVMODEL_DATA_BEGIN) defines signature begin
        rvtest_sig_end:      defined by RVTEST_SIG_END     macro (before RVMODEL_DATA_END)   defines signature end
        rvtest_Sroot_pg_tbl: defined inside RVTEST_DATA_BEGIN if Smode implemented
        rvtest_Hroot_pg_tbl: defined inside RVTEST_DATA_BEGIN if HSmode implemented
        rvtest_Vroot_pg_tbl: defined inside RVTEST_DATA_BEGIN if VSmode implemented
        trap_sigptr:         defined by test if traps are possible, else is defaulted
*/
//****WARNING****don't put C-style macros (#define xxx) inside assembly macros; C-style is evaluated before assembly

#define DEFAULT_SIG_REG  x2
#define DEFAULT_DATA_REG x3
#define DEFAULT_TEMP_REG x4
#define DEFAULT_LINK_REG x5

#ifndef T1
  #define T1      x6
#endif
#ifndef T2
  #define T2      x7
#endif
#ifndef T3
  #define T3      x8
#endif
#ifndef T4
  #define T4      x9
#endif
#ifndef T5
  #define T5      x10
#endif
#ifndef T6
  #define T6      x11
#endif

#ifndef RVMODEL_MTVEC_ALIGN
  #define MTVEC_ALIGN 6    // ensure that a trampoline is on a typical cacheline boundary, just in case
#else
  #define MTVEC_ALIGN RVMODEL_MTVEC_ALIGN  //Let the model defined value be used for required trap handler alignment based on implemented MTVEC
#endif

//==============================================================================
// this section has RV Arch Test Constants, mostly YAML based.
// It ensures they're defined  & defaulted if necessary)
//==============================================================================

// set defaults
#ifndef   NUM_SPECD_INTCAUSES
  #define NUM_SPECD_INTCAUSES 24
  #define INT_CAUSE_MSK ((1<<5)-1)
#endif

// set defaults
#ifndef   NUM_SPECD_EXCPTCAUSES
  #define NUM_SPECD_EXCPTCAUSES 24
  #define EXCPT_CAUSE_MSK ((1<<5)-1)
#endif

//==========================================================================================
// By default, ZIFENCE is defined as nop for the implementation that does not support Zifencei
// Implementations that support Zifencei may use the fence.i instruction.
// This only gets executed if xTVEC is not writable to point to the trap trampoline,
// and if it isn't writable, the model better have the zifencei extension implemented.
//==========================================================================================

#ifndef   RVMODEL_FENCEI        /**** if not defaulted must be a single op or a JAL to a rvmodel_fencei routine in rvmodel_boot ****/
  #ifndef ZIFENCE
       #define RVMODEL_FENCEI nop                                // make sure ifetches get new code
  #else
       #define RVMODEL_FENCEI fence.i
  #endif
#endif

#ifndef RVMODEL_CLEAN_SIG
  #define RVMODEL_CLEAN_SIG  RVMODEL_FENCEI
#endif

#ifndef _VA_SZ_
  #if XLEN==32
    #define _VA_SZ_ 32
  #else
    #define _VA_SZ_ 57
  #endif
#endif


//---------------------------mode encoding definitions-----------------------------
.set MMODE_SIG, 3
.set SMODE_SIG, 1
.set HMODE_SIG, 1
.set VMODE_SIG, 2
        /* these macros need to be defined because mode is uppercase in mode specific macros */
        /* note that vs mode uses smode return */

#define GVA_LSB    6    // bit pos of LSB of the hstatus.GVA  field
#define MPP_LSB   11    // bit pos of LSB of the mstatus.MPP  field
#define MODE_LSB  (XLEN-4)
#define MPRV_LSB  17    // bit pos of LSB of the mstatus.MPRV field
#define MPV_LSB    7    // bit pos of prev vmode mstatush.MPV in either mstatush or mstatus upper half
#define MPP_SMODE (1<<MPP_LSB)
#define MPP_HMODE (2<<MPP_LSB)
#define MPP_MMODE (3<<MPP_LSB)
/***************************************************************************************************
 * actual_tramp_sz
 *
 * This macro computes the total size (in bytes) of the trampoline region that is generated for
 * handling all possible interrupt vectors in this privilege mode. The trampoline acts as an
 * intermediary landing area for exceptions and interrupts, ensuring that control is transferred
 * correctly to the common trap handler entry point.
 *
 * ──────────────────────────────────────────────────────────────────────────────────────────────
 * STRUCTURE OF THE TRAMPOLINE
 *  1. VECTOR SPREADER REGION  (XLEN instructions)
 *     --------------------------------------------------------------------
 *     - For each of the NUM_SPECD_INTCAUSES valid interrupt causes:
 *           j trap_<MODE>handler + value     // 1 instruction
 *       (where `value` increments by 12 bytes for each cause, spacing out the trampolines)
 *
 *     - For the remaining (XLEN - NUM_SPECD_INTCAUSES) unused interrupt causes:
 *           j rvtest_<MODE>endtest          // 1 instruction each
 *
 *     ▸ Total instructions in this region: XLEN
 *     ▸ This corresponds to the **first term (XLEN)** in the size calculation.
 *
 *
 *  2. PER-CAUSE HANDLER SPREADERS (3 × NUM_SPECD_INTCAUSES instructions)
 *     --------------------------------------------------------------------
 *     At `trap_<MODE>handler`:
 *         csrrw   sp, CSR_XSCRATCH, sp
 *         SREG    T6, trap_sv_off+6*REGWIDTH(sp)
 *         jal     T6, common_<MODE>handler
 *     - This block is repeated once per valid interrupt cause. Each block takes 3 instructions.
 *     - This corresponds to the **second term (3*NUM_SPECD_INTCAUSES)** in the size calculation.
 *
 *
 *  3. END-OF-TEST TRAMPOLINE (9 instructions)
 *     --------------------------------------------------------------------
 *     At `rvtest_<MODE>endtest`:
 *         LA( T1, rvtest_<MODE>end )
 *         jr T1
 *     - Plus alignment and setup instructions as part of this trampoline tail.
 *
 *     - Total instructions: 9
 *     - This corresponds to the **“+ 9”** in the size calculation.
 *
 *
 *  4. COMMON HANDLER ENTRY POINT (5 instructions)
 *     --------------------------------------------------------------------
 *     At `common_<MODE>handler`:
 *         SREG   T5, trap_sv_off+5*REGWIDTH(sp)
 *         csrrw  T5, CSR_XSCRATCH, sp
 *         SREG   T5, trap_sv_off+7*REGWIDTH(sp)
 *         LREG   T5, tentry_addr_off(sp)
 *         jr     T5
 *     - Total instructions: 5
 *     - This corresponds to the **“+ 5”** in the size calculation.
 *
 * FINAL FORMULA
 *
 *     actual_tramp_sz = ( XLEN                           // vector spreaders (one per possible vector)
 *                       + 3 * NUM_SPECD_INTCAUSES        // per-cause handler spreader code
 *                       + 9                              // end-of-test trampoline tail
 *                       + 5 )                            // common handler entry point
 *                       * 4                              // 4 bytes per instruction
 *
 ***************************************************************************************************/
#define actual_tramp_sz ((XLEN + 3* NUM_SPECD_INTCAUSES + 9 + 5) * 4)
#define tramp_sz        ((actual_tramp_sz+4) & -8)                    // round up to keep alignment for sv area alloc
#define ptr_sv_sz       (16*8)
#define reg_sv_sz       ( 8*REGWIDTH)
#define model_sv_sz     ( 8*REGWIDTH)
#define sv_area_sz      (tramp_sz + ptr_sv_sz + reg_sv_sz + model_sv_sz)           // force dblword alignment
#define int_hndlr_tblsz (XLEN*2*WDBYTSZ)

//define a fixed offsets into the save area
#define tramp_sv_off                         ( 0*8) // (Mtramptbl_sv  -Mtramptbl_s Mtrapreg_sv) algned to dblwd

#define code_bgn_off                (tramp_sz+ 0*8) // (Mcode_bgn_ptr -Mtramptbl_sv)
#define code_seg_siz                (tramp_sz+ 1*8) // (Mcode_seg_siz -Mtramptbl_sv)
#define data_bgn_off                (tramp_sz+ 2*8) // (Mdata_bgn_ptr -Mtramptbl_sv) <--update on mapping chg
#define data_seg_siz                (tramp_sz+ 3*8) // (Mdata_seg_siz -Mtramptbl_sv)
#define sig_bgn_off                 (tramp_sz+ 4*8) // ( Msig_bgn_ptr -Mtramptbl_sv) <--update on mapping chg
#define sig_seg_siz                 (tramp_sz+ 5*8) // ( Msig_seg_siz -Mtramptbl_sv)
#define vmem_bgn_off                (tramp_sz+ 6*8) // (Mvmem_bgn_ptr -Mtramptbl_sv) <--update on mapping chg
#define vmem_seg_siz                (tramp_sz+ 7*8) // (Mvmem_seg_siz -Mtramptbl_sv)

#define trapsig_ptr_off             (tramp_sz+ 8*8) // (Mtrap_sig     -Mtramptbl_sv) <-- only Mmode is used
#define xsatp_sv_off                (tramp_sz+ 9*8) // (Msatp_sv      -Mtramptbl_sv)
#define sved_misa_off               (tramp_sz+10*8) // (Ssved_misa    -Mtramptbl_sv) <--update when misa.h chgs, M only
#define sved_hgatp_off   (sv_area_sz+tramp_sz+10*8) // (Ssved_hgatp   -Mtramptbl_sv) <--update when  hgatp chgs, H only
#define sved_mpp_off   (2*sv_area_sz+tramp_sz+10*8) // (Msved_mpp     -Mtramptbl_sv) <--update before mprv test, S only
#define tentry_addr_off             (tramp_sz+11*8) // (Mtentry_sv    -Mtramptbl_sv) <--update on mapping  chg
#define xedeleg_sv_off              (tramp_sz+12*8) // (Medeleg_sv    -Mtramptbl_sv)
#define xtvec_new_off               (tramp_sz+13*8) // (tvec_new      -Mtramptbl_sv)
#define xtvec_sav_off               (tramp_sz+14*8) // (tvec_save     -Mtramptbl_sv)
#define xscr_save_off               (tramp_sz+15*8) // (scratch_save  -Mtramptbl_sv)
#define trap_sv_off                 (tramp_sz+16*8) // (trapreg_sv    -Mtramptbl_sv) 8 registers long, only used by Mmode?
#define rvmodel_sv_off              (tramp_sz+24*8) // (rvmodel_sv    -Mtramptbl_sv) 8 registers long, used by long RVMODEL macros

//sved_mpp_off used for MPV tests from Mmode only
//sved_misa_off used for tests when hypervisor id present
//sved hgatp_off used for if H (and therefore S) is present
//==============================================================================
// this section has  general test helper macros, required,  optional, or just useful
//==============================================================================

#define _ARG5(_1ST,_2ND, _3RD,_4TH,_5TH,...) _5TH
#define _ARG4(_1ST,_2ND, _3RD,_4TH,...) _4TH
#define _ARG3(_1ST,_2ND, _3RD, ...) _3RD
#define _ARG2(_1ST,_2ND, ...) _2ND
#define _ARG1(_1ST,...) _1ST
#define NARG(...) _ARG5(__VA_OPT__(__VA_ARGS__,)4,3,2,1,0)

/*************************************/
/**** valid mode configs are:     ****/
/**** M                           ****/
/**** M  U                        ****/
/**** MS U                        ****/
/**** MH U                        ****/
/**** MHVU                        ****/
/**** Note that S and HS can't    ****/
/**** both exist at the same time ****/
/**** So on misa.h chg, test must ****/
/**** explicitly swap shared CSR  ****/
/**** & sv area                   ****/
/*************************************/

/******************************************************************************/
/**** this is a helper macro that conditionally instantiates the macros    ****/
/**** PROLOG/HANDLER/EPILOG/SAVEAREA depending on test type & mode support ****/
/******************************************************************************/
.macro INSTANTIATE_MODE_MACRO MACRO_NAME
  \MACRO_NAME M       // actual m-mode prolog/epilog/handler code
  #ifdef S_SUPPORTED
    \MACRO_NAME S       // actual s-mode prolog/epilog/handler code
    #ifdef H_SUPPORTED
      \MACRO_NAME H     // actual hs-mode prolog/epilog/handler code
      \MACRO_NAME V     // actual v-mode prolog/epilog/handler code
    #endif
  #endif
.endm

/**************************************************************************/
/**** this is a helper macro defaulting the int macro if its undefined ****/
/**** It builds the macro name from arguments prefix,  mode, and type  ****/
/**** The macro names are RV_MODEL_SET_[M/S/V][SW/TMR,EXT]             ****/
/****  and                RV_MODEL_CLR_[M/S/V][SW]                     ****/
/**************************************************************************/

.macro DFLT_INT_MACRO MACRO_NAME
.set      MACRO_NAME_, \MACRO_NAME
 .ifndef    MACRO_NAME_
  .warning  "MACRO_NAME_ is not defined by target. Executing this will end test."
   #define  MACRO_NAME_     j cleanup_epilogs
 .endif
.endm

/******************************************************************************/
/**** These macros enable parameterization of trap handlers for each mode  ****/
/**** "*" next to the name means there is a "h" version in RV32            ****/
/******************************************************************************/
//+-----------+-----------+-----------+---------+----------+
//|     CSR   |  Mmode    |   HSmode  |   Smode |  VSMode  |
//+-----------+-----------+-----------+---------+----------+
//| Status  * | mstatus   | hstatus   | sstatus | vsstatus | separate for H
//| IntEn     | mie       | hie       | sie     | vsie     | separate for H
//| IntPend   | mip       | hip,      | sip     | vsip     | separate for H
//| AddrTrProt|    x      | hgatp     | satp    | vsatp    | separate for H
//| TrapVal   | mtval     | htval     | stval   | vstval   | separate for H
//+-----------+-----------+-----------+---------+----------+
//| ExDeleg * | medeleg   | hedeleg   |      sedeleg       | separate for, mnged by H
//| Int Deleg | midleg    | hideleg   |      sideleg       | separate for, mnged by H
//| EnvCfg    | menvcfg   | henvcfg   |      senvcfg       | separate for, mnged by H
//| Cnter-En  | mcounteren| hcounteren|   scounteren       | separate for, mnged by H
//+-----------+-----------+-----------+---------+----------+
//| TrapVec   | mtvec     |         stvec       | vstvec   |    HS/S shared
//| Scratch   | mscratch  |         sscratch    | vsscratch|    HS/S shared
//| ExcepPC   | mepc      |         sepc        | vsepc    |    HS/S shared
//| TrapCause | mcause    |         scause      | vscause  |    HS/S shared
//+-----------+-----------+-----------+---------+----------+
//| Timecmp   | mtimecmp  |     x     |stimecmp |vstimecmp |    new for H
//| TimeDelta |    x      | htimedelta|   x     |    x     |    new for H
//| GExtIntEn |    x      | hgeie     |   x     |    x     |    new for H
//| GExtIntPnd|    x      | hgeip     |   x     |    x     |    new for H
//| VextItPndt|    x      | hvip      |   x     |    x     |    new for H
//| TrapInst  |    x      | htinst    |   x     |    x     |    new for H
//| TrapVal2  |  mtval2   |     x     |   x     |    x     |    new for H
//+-----------+-----------+-----------+---------+----------+
.macro _XCSR_RENAME_V
  .set CSR_XSTATUS, CSR_VSSTATUS
  .set CSR_XIE,     CSR_VSIE
  .set CSR_XIP,     CSR_VSIP
  .set CSR_XSATP,   CSR_VSATP
  .set CSR_XTVAL,   CSR_VSTVAL
  .set CSR_XEDELEG, CSR_SEDELEG
  .set CSR_XIDELEG, CSR_SIDELEG
  .set CSR_XENVCFG, CSR_SENVCFG
  .set CSR_XCOUNTEREN, CSR_SCOUNTEREN
  .set CSR_XTVEC,   CSR_VSTVEC
  .set CSR_XSCRATCH,CSR_VSSCRATCH
  .set CSR_XEPC,    CSR_VSEPC
  .set CSR_XCAUSE,  CSR_VSCAUSE
#if (XLEN==32)
  .set CSR_XEDELEGH, CSR_SEDELEGH
#endif
.endm

.macro _XCSR_RENAME_S
  .set CSR_XSTATUS, CSR_SSTATUS
  .set CSR_XIE,     CSR_SIE
  .set CSR_XIP,     CSR_SIP
  .set CSR_XSATP,   CSR_SATP
  .set CSR_XTVAL,   CSR_STVAL
  .set CSR_XEDELEG, CSR_SEDELEG
  .set CSR_XIDELEG, CSR_SIDELEG
  .set CSR_XENVCFG, CSR_SENVCFG
  .set CSR_XCOUNTEREN, CSR_SCOUNTEREN
  .set CSR_XTVEC,   CSR_STVEC
  .set CSR_XSCRATCH,CSR_SSCRATCH
  .set CSR_XEPC,    CSR_SEPC
  .set CSR_XCAUSE,  CSR_SCAUSE
#if (XLEN==32)
  .set CSR_XEDELEGH, CSR_SEDELEGH
#endif
.endm

.macro _XCSR_RENAME_H
  .set CSR_XSTATUS, CSR_HSTATUS
  .set CSR_XIE,     CSR_HIE
  .set CSR_XIP,     CSR_HIP
  .set CSR_XSATP,   CSR_HGATP
  .set CSR_XTVAL,   CSR_HTVAL
  .set CSR_XEDELEG, CSR_HEDELEG
  .set CSR_XIDELEG, CSR_HIDELEG
  .set CSR_XENVCFG, CSR_HENVCFG
  .set CSR_XCOUNTEREN, CSR_HCOUNTEREN
  .set CSR_XTVEC,   CSR_STVEC
  .set CSR_XSCRATCH,CSR_SSCRATCH
  .set CSR_XEPC,    CSR_SEPC
  .set CSR_XCAUSE,  CSR_SCAUSE
 #if (XLEN==32)
  .set CSR_XEDELEGH, CSR_HEDELEGH
 #endif
.endm

.macro _XCSR_RENAME_M
  .set CSR_XSTATUS, CSR_MSTATUS
  .set CSR_XIE,     CSR_MIE
  .set CSR_XIP,     CSR_MIP
  .set CSR_XSATP,   CSR_SATP
  .set CSR_XTVAL,   CSR_MTVAL
  .set CSR_XEDELEG, CSR_MEDELEG
  .set CSR_XIDELEG, CSR_MIDELEG
  .set CSR_XENVCFG, CSR_MENVCFG
  .set CSR_XCOUNTEREN, CSR_MCOUNTEREN
  .set CSR_XTVEC,   CSR_MTVEC
  .set CSR_XSCRATCH,CSR_MSCRATCH
  .set CSR_XEPC,    CSR_MEPC
  .set CSR_XCAUSE,  CSR_MCAUSE
#if (XLEN==32)
  .set CSR_XEDELEGH, CSR_MEDELEGH
#endif
.endm

/**********************************************************************/
/**** this is a helper macro that creates CSR aliases so code that ****/
/**** accesses CSRs in different modes can share the code          ****/
/**********************************************************************/

 .macro XCSR_RENAME __MODE__    // enable CSR names to be parameterized
  .ifc   \__MODE__ , M
       _XCSR_RENAME_M
  .endif
  .ifc   \__MODE__ , H
       _XCSR_RENAME_H
  .endif
  .ifc   \__MODE__ , S
       _XCSR_RENAME_S
  .endif
  .ifc  \__MODE__ ,  V
       _XCSR_RENAME_V
  .endif
.endm

////////////////////////////////////////////////////////////////////////////////////////
//**** This is a helper macro that saves GPRs. Normally used only inside CODE_END ****//
//**** Note: this needs a temp scratch register, & there isn't anything that will ****//
//**** will work, so we always trash some register, determined by macro param     ****//
//**** NOTE: Only be use for debug! Xregs containing addresses won't be relocated ****//
////////////////////////////////////////////////////////////////////////////////////////

#define RVTEST_SAVE_GPRS(_BR, _LBL, ...)                ;\
        .option push                                    ;\
        .option norvc                                   ;\
        .set __SV_MASK__,  -1 /* default to save all */ ;\
    .if NARG(__VA_ARGS__) == 1                          ;\
        .set __SV_MASK__,  _ARG1(__VA_OPT__(__VA_ARGS__,0)) ;\
    .endif                                              ;\
    .set offset, 0                                      ;\
    LA(_BR, _LBL)                                       ;\
    .if (__SV_MASK__ &        (0x2)) == 0x2             ;\
    RVTEST_SIGUPD(_BR, x1)                              ;\
    .endif                                              ;\
    .if (__SV_MASK__ &        (0x4)) == 0x4             ;\
    RVTEST_SIGUPD(_BR, x2)                              ;\
    .endif                                              ;\
    .if (__SV_MASK__ &        (0x8)) == 0x8             ;\
    RVTEST_SIGUPD(_BR, x3)                              ;\
    .endif                                              ;\
    .if (__SV_MASK__ &       (0x10)) == 0x10            ;\
    RVTEST_SIGUPD(_BR, x4)                              ;\
    .endif                                              ;\
    .if (__SV_MASK__ &       (0x20)) == 0x20            ;\
    RVTEST_SIGUPD(_BR, x5)                              ;\
    .endif                                              ;\
    .if (__SV_MASK__ &       (0x40)) == 0x40            ;\
    RVTEST_SIGUPD(_BR, x6)                              ;\
    .endif                                              ;\
    .if (__SV_MASK__ &       (0x80)) == 0x80            ;\
    RVTEST_SIGUPD(_BR, x7)                              ;\
    .endif                                              ;\
    .if (__SV_MASK__ &      (0x100)) == 0x100           ;\
    RVTEST_SIGUPD(_BR, x8)                              ;\
    .endif                                              ;\
    .if (__SV_MASK__ &      (0x200)) == 0x200           ;\
    RVTEST_SIGUPD(_BR, x9)                              ;\
    .endif                                              ;\
    .if (__SV_MASK__ &      (0x400)) == 0x400           ;\
    RVTEST_SIGUPD(_BR, x10)                             ;\
    .endif                                              ;\
    .if (__SV_MASK__ &      (0x800)) == 0x800           ;\
    RVTEST_SIGUPD(_BR, x11)                             ;\
    .endif                                              ;\
    .if (__SV_MASK__ &     (0x1000)) == 0x1000          ;\
    RVTEST_SIGUPD(_BR, x12)                             ;\
    .endif                                              ;\
    .if (__SV_MASK__ &     (0x2000)) == 0x2000          ;\
    RVTEST_SIGUPD(_BR, x13)                             ;\
    .endif                                              ;\
    .if (__SV_MASK__ &     (0x4000)) == 0x4000          ;\
    RVTEST_SIGUPD(_BR, x14)                             ;\
    .endif                                              ;\
    .if (__SV_MASK__ &     (0x8000)) == 0x8000          ;\
    RVTEST_SIGUPD(_BR, x15)                             ;\
    .endif                                              ;\
#ifndef RVTEST_E                                        ;\
    .if (__SV_MASK__ &    (0x10000)) == 0x10000         ;\
    RVTEST_SIGUPD(_BR, x16)                             ;\
    .endif                                              ;\
    .if (__SV_MASK__ &    (0x20000)) == 0x20000         ;\
    RVTEST_SIGUPD(_BR, x17)                             ;\
    .endif                                              ;\
    .if (__SV_MASK__ &    (0x40000)) == 0x40000         ;\
    RVTEST_SIGUPD(_BR, x18)                             ;\
    .endif                                              ;\
    .if (__SV_MASK__ &    (0x80000)) == 0x80000         ;\
    RVTEST_SIGUPD(_BR, x19)                             ;\
    .endif                                              ;\
    .if (__SV_MASK__ &   (0x100000)) == 0x100000        ;\
    RVTEST_SIGUPD(_BR, x20)                             ;\
    .endif                                              ;\
    .if (__SV_MASK__ &   (0x200000)) == 0x200000        ;\
    RVTEST_SIGUPD(_BR, x21)                             ;\
    .endif                                              ;\
    .if (__SV_MASK__ &   (0x400000)) == 0x400000        ;\
    RVTEST_SIGUPD(_BR, x22)                             ;\
    .endif                                              ;\
    .if (__SV_MASK__ &   (0x800000)) == 0x800000        ;\
    RVTEST_SIGUPD(_BR, x23)                             ;\
    .endif                                              ;\
    .if (__SV_MASK__ &  (0x1000000)) == 0x1000000       ;\
    RVTEST_SIGUPD(_BR, x24)                             ;\
    .endif                                              ;\
    .if (__SV_MASK__ &  (0x2000000)) == 0x2000000       ;\
    RVTEST_SIGUPD(_BR, x25)                             ;\
    .endif                                              ;\
    .if (__SV_MASK__ &  (0x4000000)) == 0x4000000       ;\
    RVTEST_SIGUPD(_BR, x26)                             ;\
    .endif                                              ;\
    .if (__SV_MASK__ &  (0x8000000)) == 0x8000000       ;\
    RVTEST_SIGUPD(_BR, x27)                             ;\
    .endif                                              ;\
    .if (__SV_MASK__ & (0x10000000)) == 0x10000000      ;\
    RVTEST_SIGUPD(_BR, x28)                             ;\
    .endif                                              ;\
    .if (__SV_MASK__ & (0x20000000)) == 0x20000000      ;\
    RVTEST_SIGUPD(_BR, x29)                             ;\
    .endif                                              ;\
    .if (__SV_MASK__ & (0x40000000)) == 0x40000000      ;\
    RVTEST_SIGUPD(_BR, x30)                             ;\
    .endif                                              ;\
    .if (__SV_MASK__ & (0x80000000)) == 0x80000000      ;\
    RVTEST_SIGUPD(_BR, x31)                             ;\
    .endif                                              ;\
#endif                                                  ;\
    .option pop

/***********************************************************************************/
/**** This must be used before using RVTEST_GOTO_LOWER_MODE and at CODE_END.    ****/
/**** It sets x3 to 0 to signal that this is not an explicit ECALL, and that it  ****/
/**** returns normally. The handler will check that trap cause==ecall, & divert ****/
/**** to a spcl rtn_fm_mmode: handler if x3=0. That code translates MEPC from   ****/
/**** caller's mode to Mmodes BARE mode, restore regs & branches to relocated   ****/
/****  EPC+4, the op immediately following the ECALL, but upgraded to Mmode     ****/
/**** **NOTE**: this destroys T2 and clears t0 (param register)                 ****/
/**** **NOTE**:  MUST not be used if medeleg[<GOTO_M_OP_cause>]==1 to prevent   ****/
/**** infinite delegation loops.                                                ****/
/**** **NOTE: tests that set medeleg[GOTO_M_OP_cause] must replace  GOTO_M_OP   ****/
/****  with an op that causes a different exception cause that isn't delegated. ****/
/***********************************************************************************/

#ifndef GOTO_M_OP
    #define GOTO_M_OP   ecall  // default; this must be called with x3=0
#endif

#ifndef GOTO_S_OP
    #define GOTO_S_OP   ecall  // default; this must be called with x3=0
#endif

#ifndef CAUSE_SPCL_GO2MMODE_OP // make sure this default can be overwritten (e.g. to illegal fetch addr)
    #define ALT_GOTO_M_CAUSE CAUSE_ILLEGAL_INSTRUCTION
    #define ALT_GOTO_M_OP    .word 0
#endif

.macro  RVTEST_GOTO_MMODE
  .option push
  .option norvc
  mv   t0, x3                 // FIXME: Hacky way to preserve x3 by trashing t0 instead
  li   x3, 0                  // Ecall w/x3=0 is handled specially to rtn here
  // Note that if ecalls are delegated, this may infinite loop
  // The solution is to use RVTEST_GOTO_DELEGATED_MMODE instead

  GOTO_M_OP                   /* ECALL: traps always, but returns immediately to
                                the next op if x3=0, else handles trap normally */
  mv   x3, t0
  .option pop
.endm

.macro  RVTEST_GOTO_DELEGATED_MMODE
  .option push
  .option norvc
  // Note that this must be called with ecall traps delegated, else it could infinite loop

  mv   t0, x3                 // FIXME: Hacky way to preserve x3 by trashing t0 instead
  li   x3, 0                  // Ecall w/x3=0 is handled specially to rtn here

  ALT_GOTO_M_OP               /* It will trap and if ecalls are delegated, it will simply
                                  return to op after illegal op, else handles trap normally */
  mv   x3, t0
  .option pop
.endm

// Return from U-mode to S-mode when U-mode ecall (bit 8) is delegated to S-mode
.macro  RVTEST_GOTO_SMODE
  .option push
  .option norvc
  #ifdef  S_SUPPORTED
    mv   t0, x3
    li   x3, 0

    GOTO_S_OP

    mv   x3, t0
  #endif
  .option pop
.endm

/**** This is a helper macro that causes harts to transition from M-mode    ****/
/**** to the following instruction, at lower priv mode. Legal params are    ****/
/**** HSmode, VSmode, VUmode, Smode & Umode. The H,U variations leave       ****/
/**** V unchanged. This modifies T1,T2 & T4.                                ****/
/**** If requested lower mode doesn't exist, is stays in Mmode,             ****/
/**** NOTE: this MUST be executed in M-mode. Precede with GOTO_MMODE        ****/
/**** FIXME - SATP & VSATP must point to the identity map page table        ****/

#define HSmode  0x9
#define VSmode  0x5
#define VUmode  0x4
#define Mmode   0x3
#define Smode   0x1
#define Umode   0x0

.macro RVTEST_GOTO_LOWER_MODE LMODE
.option push
.option norvc

        //****FIXME - this doesn't take into account separate HS mode !!!!
        // first, clear MSTATUS.PP (and .MPV if it will be changed_
        // then set them to the values that represent the lower mode
//**************** handle Vbit
   .if     ((\LMODE\()==VUmode) || (\LMODE\()==VSmode))
     LI    T2, (1<<MPV_LSB)
#if (XLEN==32)
     csrs  CSR_MSTATUSH, T2     /* set V RV32                   */
#else
     slli T2, T2, 32
     csrs  CSR_MSTATUS,  T2     /* set V RV64                   */
#endif
   .elseif ((\LMODE\()==HSmode))
     LI    T2, (1<<MPV_LSB)
#if (XLEN==32)
     csrc  CSR_MSTATUSH, T2     /* clr V RV32                   */
#else
     slli   T2, T2, 32
     csrc   CSR_MSTATUS, T2     /* clr V  RV64                  */
#endif
   .endif                       /* lv  V unchged for S or U     */

//**************** handle mode field
    LI(    T4, MSTATUS_MPP)
  .if (\LMODE\()==Mmode)
    csrs   CSR_MSTATUS, T4      /* set PP alwaysif Mmode        */
  .else                         /* end of MMode handling        */
    csrc   CSR_MSTATUS, T4      /* clr PP always (also Umode    */
    .if (   !((\LMODE\()==VUmode) || (\LMODE\()==Umode)))  /* lv pp clred if umode     */
      .if    ((\LMODE\()==HSmode) || (\LMODE\()==VSmode) || (\LMODE\()==Smode))   /* set pp to S if it exists */
  #ifdef S_SUPPORTED
     LI(  T4, MPP_SMODE)        /* val for Smode                */
  #else
     LI(  T4, MPP_MMODE)        /* val for no Smode             */
  #endif
        csrs CSR_MSTATUS, T4    /* set correct mode             */
      .endif                    /* end of S/Umode handling      */
    .endif                      /* end of not Umode handling    */
  .endif                        /* end of Mmode handling        */

        csrr   T2, CSR_MSCRATCH     /* ensure GPR T2 points to Mmode data area */
        addi   T2, T2, code_bgn_off+sv_area_sz   /* point directly to save area 1 (to handle to large offset) */

        /**** mstatus MPV and PP now set up to desired mode          ****/
        /**** set MEPC to mret+4; requires relocating the pc         ****/
        /****FIXME this has to take into account these sv_area_szs   ****/
        /**** M->HS->VS->VU (0,1,3,3)               ****/
        /**** M->HS->     U (0,1,  2)               ****/
        /**** M-> S->     U (0,2   2)               ****/
        /**** M->         U (0     0)               ****/

  .if     ((\LMODE\() == VSmode) || (\LMODE\() == VUmode)) // get trapsig_ptr & init val up 3 save areas (M->H->S->V)
        LREG    T1, 2*sv_area_sz(T2)     // 3*sv_area_sz is VS/VU

  #ifdef S_SUPPORTED                             // ensure you don't go to S in an M-U system
    #ifdef H_SUPPORTED
      .elseif (\LMODE\() == Smode)                            // get trapsig_ptr & init val up 1 save areas (M->S)
            LREG    T1,  1*sv_area_sz(T2)                     // 2*svarea_sz is Smode
      .elseif (\LMODE\() == HSmode || \LMODE\() == Umode)     // get trapsig_ptr & init val up 1 save areas (M->S)
            LREG    T1, 0*sv_area_sz(T2)                      // 1*svarea_sz is HSmode
    #else
      .elseif (\LMODE\() == Smode || \LMODE\() == Umode)
            LREG    T1,  0*sv_area_sz(T2)                     // 1*svarea_sz is Smode when Hypervisor is not supported
    #endif
  #endif

  .else                            // get trapsig ptr & init val for this Mmode, (M)
        LREG    T1, -1*sv_area_sz(T2)
  .endif

        LREG  T4,   -1*sv_area_sz(T2) /* load the Mmode save area address */
        sub   T1, T1, T4              /* calc addr delta between this mode (M) and lower mode code */
        addi  T1, T1, 4*WDBYTSZ       /* bias by # ops from auipc..mret (2f-1f) to continue at mret+4 */
1:      auipc T4, 0
        add   T4, T4, T1              /* calc addr after mret   in LMODE's VM */
        csrw  CSR_MEPC, T4            /* set rtn addr to mret+4 in LMODE's VM */
        mret                          /* transition to desired mode           */
2:   .option pop
.endm                           // end of RVTEST_GOTO_LOWER_MODE

//==============================================================================
// Helper macro to set defaults for undefined interrupt set/clear
// macros. This is used to populated the interrupt vector table.
// These are only used during interrupt testing, so it is safe to
// define them as empty macros if and only if that particular interrupt
// isn't being tested
//==============================================================================
//****************************************************************
#define RVTEST_DFLT_INT_HNDLR      j cleanup_epilogs

        //Mmode interrupts
#ifndef RVMODEL_SET_MSW_INT
        //.warning "RVMODEL_SET_MSW_INT    not defined. Executing this will end test. Define an empty macro to suppress this warning"
        #define  RVMODEL_SET_MSW_INT     RVTEST_DFLT_INT_HNDLR
#endif
#ifndef RVMODEL_CLR_MSW_INT
        //.warning "RVMODEL_CLR_MSW_INT    not defined. Executing this will end test. Define an empty macro to suppress this warning"
        #define  RVMODEL_CLR_MSW_INT     RVTEST_DFLT_INT_HNDLR
#endif
#ifndef RVMODEL_CLR_MEXT_INT
        //.warning "RVMODEL_CLR_MEXT_INT   not defined. Executing this will end test. Define an empty macro to suppress this warning"
        #define  RVMODEL_CLR_MEXT_INT    RVTEST_DFLT_INT_HNDLR
#endif

//Smode interrupts
#ifndef RVMODEL_SET_SSW_INT
        //.warning "RVMODEL_SET_SSW_INT    not defined. Executing this will end test. Define an empty macro to suppress this warning"
        #define  RVMODEL_SET_SSW_INT     RVTEST_DFLT_INT_HNDLR
#endif
#ifndef RVMODEL_CLR_SSW_INT
        //.warning "RVMODEL_CLR_SSW_INT    not defined. Executing this will end test. Define an empty macro to suppress this warning"
        #define  RVMODEL_CLR_SSW_INT     RVTEST_DFLT_INT_HNDLR
#endif
#ifndef RVMODEL_CLR_STIMER_INT
        //.warning "RVMODEL_CLR_STIMER_INT not defined. Executing this will end test. Define an empty macro to suppress this warning"
        #define  RVMODEL_CLR_STIMER_INT  RVTEST_DFLT_INT_HNDLR
#endif
#ifndef RVMODEL_CLR_SEXT_INT
        //.warning "RVMODEL_CLR_SEXT_INT   not defined. Executing this will end test. Define an empty macro to suppress this warning"
        #define  RVMODEL_CLR_SEXT_INT    RVTEST_DFLT_INT_HNDLR
#endif

//Vmode interrupts
#ifndef RVMODEL_SET_VSW_INT
        //.warning "RVMODEL_SET_VSW_INT    not defined. Executing this will end test. Define an empty macro to suppress this warning"
        #define  RVMODEL_SET_VSW_INT     RVTEST_DFLT_INT_HNDLR
#endif
#ifndef RVMODEL_CLR_VSW_INT
        //.warning "RVMODEL_CLR_VSW_INT    not defined. Executing this will end test. Define an empty macro to suppress this warning"
        #define  RVMODEL_CLR_VSW_INT     RVTEST_DFLT_INT_HNDLR
#endif
#ifndef RVMODEL_CLR_VTIMER_INT
        //.warning "RVMODEL_CLR_VTIMER_INT not defined. Executing this will end test. Define an empty macro to suppress this warning"
        #define  RVMODEL_CLR_VTIMER_INT  RVTEST_DFLT_INT_HNDLR
#endif
#ifndef RVMODEL_CLR_VEXT_INT
        //.warning "RVMODEL_CLR_VEXT_INT   not defined. Executing this will end test. Define an empty macro to suppress this warning"
        #define  RVMODEL_CLR_VEXT_INT    RVTEST_DFLT_INT_HNDLR
#endif

//==============================================================================
// This section defines macros used by these required macros:
// RVTEST_TRAP_PROLOG, RVTEST_TRAP_HANDLER, RVTEST_TRAP_EPILOG
// These are macros instead of inline because they need to be replicated per mode
// These are passed the privmode as an argument to properly rename labels
// The helper INSTANTIATE_MODE_MACRO actually handles the replication
//==============================================================================

.macro  RVTEST_TRAP_PROLOG __MODE__
.option push
.option norvc
  /******************************************************************************/
  /**** this is a mode-configured version of the prolog, which either saves and */
  /**** replaces xtvec, or saves and replaces the code located at xtvec if it   */
  /**** it xtvec isn't arbitrarily writable. If not writable, restore & exit    */
  /******************************************************************************/

  /******************************************************************************/
  /****                 Prolog, to be run before any tests                   ****/
  /****       #include 1 copy of this per mode in rvmodel_boot code?         ****/
  /**** -------------------------------------------------------------------  ****/
  /**** if xTVEC isn't completely RW, then we need to change the code at its ****/
  /**** target. The entire trap trampoline and mtrap handler replaces the    ****/
  /**** area pointed to by mtvec, after saving its original contents first.  ****/
  /**** If it isn't possible to fully write that area, restore and fail.     ****/
  /******************************************************************************/

  // RVTEST_TRAP_PROLOG trap_handler_prolog; enter with T1..T6 available; define specific handler
  // sp will immediately point to the current mode's save area and must not be touched
  //NOTE: this is run in M-mode, so can't use aliased S,V CSR names

.global \__MODE__\()trampoline
        XCSR_RENAME \__MODE__          //retarget XCSR names to this modes CSRs, separate V/S copies

        LA(     T1, \__MODE__\()tramptbl_sv)    // get  ptr to save area (will be stored in xSCRATCH)
//----------------------------------------------------------------------
init_\__MODE__\()scratch:
        csrrw   T3, CSR_XSCRATCH, T1    // swap xscratch with save area ptr (will be used by handler)
        SREG    T3, xscr_save_off(T1)   // save old mscratch in xscratch_save
//----------------------------------------------------------------------

#ifdef RVMODEL_MTIMECMP_BASE            // this looks a bit odd to keep it constant size
init_\__MODE__\()timecmp:               // init MTIMECMP to largest value if its address is defined
        LI(  T2,  -1)
        LI(  T4,  RVMODEL_MTIMECMP_BASE)
        SREG T2,  0(T4)
  .if (XLEN==32)
        SREG T2,  4(T4)
  .endif
        nop                             // deal w/ traps if not accessed in Mmode
#else           /****FIXME we could also abort the test if this isn't defined and Zicntr is ****/
        nop
        nop
        nop
  .if (XLEN==32)
        nop
  .endif
        nop
#endif
//----------------------------------------------------------------------
init_\__MODE__\()edeleg:                // only medeleg and hedeleg ( if H, then there is a lower mode to delegate to)
        li      T2, 0                   // save and clear edeleg so we can exit to Mmode
  .ifc \__MODE__ , M
    #ifdef S_SUPPORTED
        csrrw   T2, CSR_XEDELEG, T2     // this handles M  mode save, but only if Smode exists
    #endif
  .endif
  .ifc \__MODE__ , H
        csrrw   T2, CSR_XEDELEG, T2     // this handles M  mode save, but only if Smode exists
  .endif
       SREG    T2, xedeleg_sv_off(T1)  // now do the save
//----------------------------------------------------------------------
init_\__MODE__\()satp:
.ifnc \__MODE__ , M                      // if HS, S or VS mode **FIXME: fixed offset frm trapreg_sv?
        LA(     T4, rvtest_\__MODE__\()root_pg_tbl)     // rplc xsatp w/ identity-mapped pg table
// Add an identity-map PTE (VA=PA) for the 1GB physical range that holds the S-mode trap
// handler and save area.  When page faults are delegated to S-mode (medeleg), the CPU
// jumps to stvec—a physical address—as a virtual address.  Without this mapping the fetch
// faults immediately, causing an infinite instruction-page-fault loop.
.ifc \__MODE__ , S
        LA(     T5, \__MODE__\()trampoline)    // PA of the S-mode trap trampoline
        srli    T5, T5, 30                     // T5 = PA >> 30  (1 GB page number = VPN2)
        mv      T6, T5                         // T6 = VPN2 (index into L2 root page table)
        slli    T5, T5, 28                     // T5 = PTE PPN field for 1 GB superpage
        //   formula: PPN[2] = PA>>30, sits at PTE[53:28] = (PA>>30) << 28
        //   PPN[1]=PPN[0]=0 (required for a properly-aligned 1 GB superpage)
        LI(     T3, PTE_D | PTE_A | PTE_X | PTE_W | PTE_R | PTE_V)
        or      T5, T5, T3                     // T5 = complete identity-map PTE
        andi    T6, T6, 0x1FF                  // keep 9-bit VPN2 index
        slli    T6, T6, 3                      // byte offset = VPN2 * 8
        add     T6, T4, T6                     // T6 = &Sroot_pg_tbl[VPN2]
        SREG    T5, 0(T6)                      // write identity-map PTE
.endif
        srli T4, T4, 12
      #if (XLEN==32)
        LI(T3, SATP32_MODE)             //enables  SV32 mode
      #elseif (_VA_SZ_ == 39)
        LI(T3, (SATP64_MODE) & (SATP_MODE_SV39 << 60))
      #elseif (_VA_SZ_ == 48)
        LI(T3, (SATP64_MODE) & (SATP_MODE_SV48 << 60))
      #elseif (_VA_SZ_ == 57)
        LI(T3, (SATP64_MODE) & (SATP_MODE_SV57 << 60))
      #endif
        or      T4, T4, T3
        csrrw   T4, CSR_XSATP, T4

        SREG    T4, xsatp_sv_off(T1)
.endif
//----------------------------------------------------------------------
// T1 contains pointer to the top of this mode's save area
// The area consists of the old trampoline storage (if it was overwritten), variables, and orig t1..T6+sp reg values
init_\__MODE__\()tvec:
        csrr    T3, CSR_XTVEC
        SREG    T3, xtvec_sav_off(T1)   // save orig mtvec+mode in tvec_save
        andi    T2, T3, WDBYTMSK        // extract mode bits (2 LSBs)
        LREG    T4, tentry_addr_off(T1) // points to bottom of trampoline_sv area
        addi    T4, T4, -actual_tramp_sz// calc top of trampoline sv (common entry pt) avoiding an LA()
        or      T2, T4, T2              // merge .mode & tramp ptr and store to both XTVEC, tvec_new
        SREG    T2, xtvec_new_off(T1)
        csrw    CSR_XTVEC, T2           // write xtvec with trap_trampoline+mode, so trap will go to the trampoline

        csrr    T5, CSR_XTVEC           // now read new_mtval back & make sure we could write it
#ifndef HANDLER_TESTCODE_ONLY
        beq     T5, T2, rvtest_\__MODE__\()prolog_done // if mtvec==trap_trampoline, mtvec is writable, continue
#endif
        csrw    CSR_XTVEC, T3           // xTVEC not completely writable, restore old value & exit if uninitialized
        beqz    T3, abort\__MODE__\()test       // orig xTVEC not writable, and points to invalid addr, abort
        SREG    T3, xtvec_new_off(T1)   // else update tvec_new with orig mtvec

  /*****************************************************************/
  /**** fixed mtvec, can't move it so move trampoline instead   ****/
  /**** T1=tramptbl_sv, T2=orig tvec, T3=sv end, T4=tramp       ****/
  /*****************************************************************/

init_\__MODE__\()tramp: /**** copy trampoline at mtvec tgt; T4->T2->T1  T3=end of save ****/
        andi    T2, T3, ~WDBYTMSK               // calc bgn of orig tramp area by clring mode bits
        addi    T3, T2, actual_tramp_sz         // calc end of orig tramp area (+4 maybe so dblwd aligned)
        mv      sp, T1                          // make sure sp is initialized to save area
//----------------------------------------------------------------------
overwt_tt_\__MODE__\()loop:                     // now build new tramp table w/ local offsets
        lw      T6, 0(T2)                       //  move original mtvec target to save area
        sw      T6, 0(T1)
        lw      T5, 0(T4)                       //  move traphandler trampoline into orig mtvec target
        sw      T5, 0(T2)
        lw      T6, 0(T2)                       // rd it back to make sure it was written
        bne     T6, T5, endcopy_\__MODE__\()tramp // table isn't fully writable, restore and give up
#ifdef HANDLER_TESTCODE_ONLY
        csrr    T5, CSR_XSCRATCH                // load trapreg_sv from scratch
        addi    T5, T5,256                      // calculate some offset into the save area
        bgt     T5, T1, endcopy_\__MODE__\()tramp // and pretend if couldn't be written
#endif
        addi    T2, T2, WDBYTSZ                 // next tvec  inst. index
        addi    T1, T1, WDBYTSZ                 // next save  inst. index
        addi    T4, T4, WDBYTSZ                 // next tramp inst. index
        bne     T3, T2, overwt_tt_\__MODE__\()loop      // haven't reached end of save area,  loop
//----------------------------------------------------------------------
// RVMODEL_FENCEI is either a single op, or a JAL T1, RVMODEL_FENCE_ROUTINE located in RVMODEL_BOOT
        // This is done to ensure that the code size remains constant, regardless of implementation
        // If Icache is coherent with Dcache, then it can be a nop

endcopy_\__MODE__\()tramp:                      // vector table not writeable, restore
        RVMODEL_FENCEI                          // make sure the overwritten trampoline will be fetched
        csrr    T1, CSR_XSCRATCH                // reload trapreg_sv from scratch
//      SREG    T2, trampend_off(T1)            // no need to save copy progress; used to restore orig tramp
        SREG    T4, tentry_addr_off(T1)         // this is common entry point address, end of orig trampoline
        beq     T3,T2, rvtest_\__MODE__\()prolog_done //full loop, don't exit
abort\__MODE__\()test:
        mv      T3, T2                          // preload shortened length for abort case
        LA(     T6, exit_\__MODE__\()cleanup)   // trampoline rplc failure **FIXME:  precalc& put into savearea?
        jr      T6                              // this branch may be too far away, so longjmp

rvtest_\__MODE__\()prolog_done:
        nop                                     // keep this label from collapsing with the next

.option pop
.endm                                           //end of PROLOG
/*******************************************************************************/
/***************                 end of prolog macro                ************/
/*******************************************************************************/

.macro RVTEST_TRAP_HANDLER __MODE__
.option push
.option rvc             // temporarily allow compress to allow c.nop alignment
.align MTVEC_ALIGN      // ensure that a trampoline is on a model defined or reasonable boundary
.option pop

  /**********************************************************************/
  /**** This is the entry point for all x-modetraps, vectored or not.****/
  /**** xtvec should either point here, or trampoline code does and  ****/
  /**** trampoline code was copied to wherever xtvec pointed to.     ****/
  /**** At entry, xscratch will contain a pointer to a scratch area. ****/
  /**** This is an array of branches at 4B intervals that spreads out****/
  /**** to an array of 12B xhandler stubs for specd int causes, and  ****/
  /**** to a return for anything above that (which causes a mismatch)****/
  /**********************************************************************/

  XCSR_RENAME \__MODE__                 //retarget XCSR names to this modes CSRs

.global \__MODE__\()trampoline                  // define the label and make it available
.global common_\__MODE__\()entry
.option push
.option norvc

\__MODE__\()trampoline: //****GLOBAL:*****
   .set  value, 0
  .rept NUM_SPECD_INTCAUSES                     // located at each possible int vectors
        j    trap_\__MODE__\()handler+ value    // offset < +/- 1MB
        .set value, value + 12                  // length of xhandler trampoline spreader code
  .endr

  .rept XLEN-NUM_SPECD_INTCAUSES                // fill at each impossible entry
        j rvtest_\__MODE__\()endtest            // end test if this happens
  .endr

  /*********************************************************************/
  /**** this is spreader stub array; it saves enough info (sp &     ****/
  /**** vec-offset) to enable branch to common routine to save rest ****/
  /*********************************************************************/
  /**** !!CSR_xSCRATCH is preloaded w/ xtrapreg_sv in init_xscratch:****/

 trap_\__MODE__\()handler:                      // on exit sp swapped w/ save ptr, T6 is vector addr
  .rept NUM_SPECD_INTCAUSES
        csrrw   sp, CSR_XSCRATCH, sp            // save sp, replace w/trapreg_sv regtmp save ptr
        SREG    T6, trap_sv_off+6*REGWIDTH(sp)  // save T6 in temp save area offset 6
        jal     T6, common_\__MODE__\()handler  // jmp to common code, saving vector in T6
  .endr
  /**********************************************************************/

rvtest_\__MODE__\()endtest:                     // target may be too far away, so longjmp
        LA(     T1, rvtest_\__MODE__\()end)     // FIXME: must be sequentially mapped if its a VA
        jr      T1

  /*********************************************************************/
  /**** common code for all ints & exceptions, will fork to handle  ****/
  /**** each separately. The common handler first stores trap mode+ ****/
  /**** vector, & mcause signatures. Most traps have 4wd sigs, but  ****/
  /**** sw and timer ints only store 3 of the 4, & some hypervisor  ****/
  /**** traps will set store 6 ops                                  ****/
  /**** sig offset Exception    ExtInt       SWInt        TimerInt  ****/
  /****         0: <---------------------  Vect+mode  ---------->   ****/
  /****         4: <----------------------  xcause ------------->   ****/
  /****         8: xepc      <-------------  xip  -------------->   ****/
  /****        12: tval         IntID   <---- x ---------------->   ****/
  /****        16: tval2/x * <--------------  x ---------------->   ****/
  /****        20: tinst/x * <--------------  x ---------------->   ****/
  /****  *  only loaded for Mmode traps when hypervisor implemented ****/
  /*********************************************************************/
  /*   in general, CSRs loaded in T2, addresses into T3                */

        //If we can distinguish between HS and S mode, we can share S and V code.
        //except for prolog code which needs to initialize CSRs, and the save area
        //To do this, we need to read one of the CSRs (e.g. xSCRATCH) and compare
        //it to either Strapreg_sv or Vtrapreg_sv to determine which it is.

common_\__MODE__\()handler:                     // enter with vector addr in T6 (orig T6 is at offset 6*REGWIDTH)
        SREG    T5, trap_sv_off+5*REGWIDTH(sp)  // x30  save remaining regs, starting with T5
        csrrw   T5, CSR_XSCRATCH, sp            // restore ptr to reg sv area, and get old sp
        SREG    T5, trap_sv_off+7*REGWIDTH(sp)  // save old sp
        LREG    T5, tentry_addr_off(sp)         //  get the address of the common entry point
        jr      T5                              // needed if trampoline gets moved elsewhere, else it's effectively a noop

common_\__MODE__\()entry:
        // lpad(0)                                 //auipc x0,0 needed for cfilp (because it the target of a JR?)
        SREG    T4, trap_sv_off+4*REGWIDTH(sp)  //x29 (or x13 for RV32e)
        SREG    T3, trap_sv_off+3*REGWIDTH(sp)  //x28 (or x12 for RV32e)
        SREG    T2, trap_sv_off+2*REGWIDTH(sp)  //x7
        SREG    T1, trap_sv_off+1*REGWIDTH(sp)  //x6  save other temporaries
        csrr    T5, CSR_XCAUSE                  // load xcause into T5 for all priv modes

//**** NOTE: this code exists ONLY for Mmode
//**** If delegated to any other mode then test is buggy since you can't get to Mmode
//**** FIXME: should we abort test if go2Mmode is branched to in any other mode?

  .ifc \__MODE__ ,  M   //spcl case handling for ECALL in GOTO_MMODE mode,)
                        // ****tests can't use ECALL w/ x3=0; rsvd for GOTO_MMODE ****/
spcl_\__MODE__\()2mmode_test:
        LI(T4,(1<<(XLEN-1))+((1<<12)-1))        // make a mask of int bit and cause(11:0).
        and     T4, T4, T5                      // Keep only int bit and cause[11:0], fixing CLIC incompatibility
spcl_\__MODE__\()chk4alt:
        addi    T3,T4, -ALT_GOTO_M_CAUSE        // check for special handling to see if it might be alternate go2mmode
        bnez    T3, spcl_\__MODE__\()chk4ecall  // not the alt gto_m_op, check for std ECALL
spcl_\__MODE__\()param_chk:
        beqz    x3, \__MODE__\()rtn2mmode       // return in mmode if its alt op & x3==0
        j           \__MODE__\()trapsig_ptr_upd // else handle normally
spcl_\__MODE__\()chk4ecall:
        addi    T3, T4, -CAUSE_USER_ECALL       // map cause 8..11 to 0..3,  Mmode should avoid ECALL 0
        srli    T3, T3, 2                       // map cause 0..3 -> 0 (some ecall)
        bnez    T3, \__MODE__\()trapsig_ptr_upd // no, not an ecall either, store normal trap signature
   .endif
                                                // fall thru to chk for selftest fail or rtn2mmode

//****FIXME: what is the correct parameter register? x3=0?

.ifc \__MODE__ ,  M                             // If ecall is delegated, can't go to Mmode
\__MODE__\()goto_mchk:                          // is ECALL, but not failure type; see if its goto_m_mode
        beqz    x3, \__MODE__\()rtn2mmode       // return in mmode if it is, else fall thru to normal trap signature
.endif

.ifc \__MODE__ ,  S                             // RVTEST_GOTO_SMODE U-mode ecall w/ x3=0 returns in S-mode
\__MODE__\()goto_schk:
        LI(T4,(1<<(XLEN-1))+((1<<12)-1))        // make a mask of int bit and cause(11:0)
        and     T4, T4, T5                      // keep only int bit and cause[11:0]
        addi    T3, T4, -CAUSE_USER_ECALL       // check for U-mode ecall
        bnez    T3, \__MODE__\()trapsig_ptr_upd // if not a U-mode ecall, handle normally
        beqz    x3, \__MODE__\()rtn2smode       // return to S-mode
.endif

//------normal trap rtn; pre-update trap_sig pointer so handlers can themselves trap-----
\__MODE__\()trapsig_ptr_upd:                    // calculate entry size based on int vs. exception, interrupt type, and h mode
        li      T2, 4*REGWIDTH                  // standard entry length
        bgez    T5, \__MODE__\()xcpt_sig_sv     // Keep std length if cause is an exception for now (MSB==0)
\__MODE__\()int_sig_sv:
        slli    T3, T5, 1                       // remove MSB, cause<<1
        addi    T3, T3, -(IRQ_M_TIMER)<<1       // is cause (w/o MSB) an external interrupt or larger? ( (cause<<1) > (8<<1) )?
        bgez    T3, \__MODE__\()trap_sig_sv     // yes, keep std length
        li      T2, 3*REGWIDTH                  // no,  its a timer or swint, override preinc to 3*regsz
        j       \__MODE__\()trap_sig_sv

  /**********************************************************************/

\__MODE__\()xcpt_sig_sv:                        // adj the length if hypervisor exception
.ifc \__MODE__ , M                              // exception case, don't adjust if hypervisor mode disabled
#ifdef H_SUPPORTED
        csrr    T1, CSR_MISA
        slli    T1, T1, XLEN-8                  // shift H bit into msb
        bgez    T1, \__MODE__\()trap_sig_sv     // no hypervisor mode, keep std width
        li      T2, 6*REGWIDTH                  // Hmode implemented &  Mmode trap, override preinc to be 6*regsz
#endif
.else
  .ifc \__MODE__ , H                            // HS exception handler, always adjust
        li      T2, 6*REGWIDTH                  // Hmode implemented &  Mmode trap, override preinc to be 6*regsz
  .endif
.endif

\__MODE__\()trap_sig_sv:
        // This replaces an LA(rvtest_trap_sig) calculating initial_Xtrap_sigptr +
        //                                    (trap_sigptr-initial_Mtrap-sigptr)
        // The delta between Mmode_sigptr and Xmode_sigptr are constants
        // Xtrap_sigptr (current priv mode) are in the save area ponted to by sp
        // ****FIXME - this breaks if the signature area cross a page boundary and the mapping isn't contiguous
        // 3*sv_area_sz breaks immediate limit, so temporarily offset to account for it

        .set sv_area_off, (+1*sv_area_sz)       // get trapsig ptr val offset  for Mmode, (M)
.ifc \__MODE__ , H
        .set sv_area_off, ( 0*sv_area_sz)       // get trapsig_ptr val  up 1 save areas   (M<-HS)
.else
   .ifc \__MODE__ , S
     #ifdef H_SUPPORTED
        .set sv_area_off, (-1*sv_area_sz)       // get trapsig_ptr val  up 2 save areas   (M<-S<-HS)
     #else
        .set sv_area_off, ( 0*sv_area_sz)       // get trapsig_ptr val  up 1 save area    (M<-S)
     #endif
   .else
      .ifc \__MODE__ , V
        .set sv_area_off, (-2*sv_area_sz)       // get trapsig ptr val  up 3 save areas,  (M<-S<-HS<-VS)
      .endif
    .endif
.endif
        addi    sp, sp, -1*sv_area_sz           // this offsets Sp to avoid overflowing the offset parameter
//------this should be atomic-------------------------------------
        LREG    T1, trapsig_ptr_off+sv_area_off(sp)  // offset curr ptr to Mmode area
        add     T4, T1, T2                      // this is {3/4/6}*REGWIDTH (4/8)
        SREG    T4, trapsig_ptr_off+sv_area_off(sp)

//------end atomic------------------------------------------------
//  convert trap_sigptr to curr_mode trap_sigptr
        LREG    T3, sig_bgn_off+sv_area_off(sp) // load     Mmode sig begin addr
        sub     T1, T1, T3                      // cvt sigptr to offset from Mmode sig begin
        addi    sp, sp, 1*sv_area_sz            // undo the sp offset
        LREG    T3, sig_bgn_off+          0(sp) // load <currmode>sig begin addr
        add     T1, T1, T3                      // calc offset from sig_begin to curr sig_begin addr
//----------------------------------------------------------------

  /*********************************************************************************************/
  /****   this first entry has this format.                                                 ****/
  /****   The #entries is useful for parsing and is really #bytes/entry                     ****/
  /**** +----------+------------------------------------+----+----+-------+--------+------+ ****/
  /**** |XLEN-1 31 | 30                              13 | 12 | 11 | 10  6 | 5   2  | 1  0 | ****/
  /**** +----------+------------------------------------+----+----+-------+--------+------+ ****/
  /**** | zeroes   | Xstatus[MPRV,SPVP,MPV,GVA,0,[12:0] |XxIP|XxIE|vector |#entries| mode | ****/
  /**** +----------+------------------------------------+----+----+-------+--------+------+ ****/
  /*********************************************************************************************/

sv_\__MODE__\()vect:                            // **FIXME?: breaks if tramp crosses pg && MMU enabled
        LREG    T3, xtvec_new_off(sp)           // get pointer to actual tramp table
        sub     T6, T6, T3                      // cvt spreader-addr to vector offset fm top of tramptable (vector=12*0..23: is 9b max)
        slli    T4, T6, 1                       // mul by 3/32, compressing to 5b
        add     T6, T6, T4
        srli    T6, T6, 5
        slli    T6, T6, 6                       // move to bits 10:6
        or      T6, T6, T2                      // insert entry size into bits 5:2
        addi    T6, T6, \__MODE__\()MODE_SIG    // insert mode# into 1:0

        bgez    T5, 1f                          // if not an interrupt
        li      T3, 0xf
        and     T3, T5, T3                      // mcause[3:0]
        csrr    T4, CSR_XIE
        srl     T4, T4, T3
        andi    T4, T4, 1
        slli    T4, T4, 11
        or      T6, T6, T4                      // deposit XxIE[cause] into bit 11

        csrr    T4, CSR_XIP
        srl     T4, T4, T3
        andi    T4, T4, 1
        slli    T4, T4, 12
        or      T6, T6, T4                      // deposit XxIP[cause] into bit 12

        1:
        csrr    T2, CSR_XSTATUS                 // deposit xstatus(17:0) into [30:13)
        slli    T2, T2, XLEN-17
        srli    T2, T2, XLEN-17-13
        LI(     T3, 0x219FE5)                   // clear 16:13 (XS,FS) 10:9 (VS) and unused bits 4,2,0
        xori    T3, T3, -1
        and     T3, T2, T3
        or      T3, T6, T3                      // merge with other bits

//if  MMode and RV32 move mstatush[ 7: 6] into bit 15:14
//if  MMode and RV64 move mstatus [39:38] into bit 15:14
//if HSMode          move hstatus [ 8: 6] into bit 16:14
.ifc \__MODE__ , M
  #if (XLEN==64)
        srli    T4, T4, XLEN-32                 // align to mstatush
  #else
        csrr    T4, CSR_MSTATUSH
  #endif
.else
  .ifc \__MODE__ , H
        csrr    T4, CSR_HSTATUS                 // already aligned with mstatush
  .endif
.endif
        andi    T4, T4, 0x1C0                   // deposit SPVP?,xPV, GVA (8:6) into 16:14
        slli    T4, T4, 14-6
        or      T3, T3, T4
        TRAP_SIGUPD(T4, T3, 0, sv_\__MODE__\()vect, sv_\__MODE__\()vect_str)    // Save 1st signature (vec-offset, entrysz, trapmode)

//----------------------------------------------------------------
sv_\__MODE__\()cause:
        mv      T3, T5                          // move xcause (T5) into T3 so all trap sig stores use T3
        TRAP_SIGUPD(T4, T3, 1, sv_\__MODE__\()cause, sv_\__MODE__\()cause_str)  // Save XCAUSE
//----------------------------------------------------------------
        bltz    T5, common_\__MODE__\()int_handler // split off if this is an interrupt

  /*******************************************************************************/
  /**** This is exception specific code, storing relative mepc & tval sigs    ****/
  /**** The mepc sig is relocated by data or code start, depending on whether ****/
  /**** on whether it's in the data area or not, & restored bumped by 2..6B   ****/
  /**** depending op alignment so trapped op isn't re-executed                ****/
  /*******************************************************************************/

common_\__MODE__\()excpt_handler:

  //********************************************************************************
  // figure out if relocation is needed, whenever all translation levels are bare
  // Note that if Strap_routine is undefined, then force relocations
  // 1 * means can't be read, but must or would have value indicated
  // all other values are illegal
  // lvs result in T4 to be used during relocation, (so doesn't touch sp)
  // can use T3, T6 because relocation will overwrite them
  //********************************************************************************

        /****FIXME - I think the Mmode handler has to override MPRV if it came from hypervisor op ****/

        // create an index from these values: vMPP, x.GVA , H-ext

  // +------+------+------+-------+-------+-------+
  // | Trap | VPP  | satp | Mstat | vsatp |       |
  // | Mode |      | Mode |  PV   |  mode | reloc | <--VPP == mstatus.MPRV ? Test_saved.MPP : mstatus.MPP
  // +------+------+------+-------+-------+-------+
  // | ==M  | ==M  |   x  |   x   |   x   | reloc | M<--       M,  no VA at all
  // | ==M  |  x   | !=0  |   x   |   x   | skip  | M<--[V]U/S,  came directly from a          VA   mode
  // | ==M  |  x   |   x  |   0   |   x   | reloc | M<--U/[H]S,  came directly from a non-virt bare mode
  // | ==M  |  x   |   x  |   x   |  !=0  | skip  | M<--[V]U/S,  came thru bare mode from virt  VA  mode
  // | ==M  |  x   |   x  |   x   |  ==0  | reloc | M<--[V]U/S,  came thru bare mode from virt bare mode
  // +------+------+------+-------+-------+-------+

  // +------+------+------+-------+-------+-------+
  // | Trap | VPP  |hgatp | hstat | vsatp |       |
  // | Mode |      | Mode |  SPV  | Mode  | reloc |<-- test must swap stvec/sscratch/sepc/scause whenever misa.H set
  // +------+------+------+-------+-------+-------+
  // |  HS  |  x   | !=0  |   x   |   x   | skip  |   HS<--[x]S/U, came directly from a non-virt  VA  mode
  // |  HS  |  x   |   x  |   0   |   x   | reloc |   HS<--  HS/U, came directly from a non-virt bare mode
  // |  HS  |  x   |   x  |   x   |  !=0  | skip  |   HS<--[V]S/U, came through bare   from virt  VA  mode
  // |  HS  |  x   |   x  |   x   |  ==0  | reloc |   HS<- [V]S/U, came through bare   from virt bare mode
  // +------+------+------+-------+-------+-------+

  // +------+------+------+-------+-------+-------+
  // | Trap | VPP  | satp | sstat | ssatp |       |
  // | Mode |      | Mode |  SPV  | Mode  | reloc |<-- test must swap stvec/sscratch/sepc/scause whenever misa.H cleared
  // +------+------+------+-------+-------+-------+
  // |  S   |  x   | !=0  |   x   |   x   | skip  |  S<-- S/U, came directly from a non-virt  VA  mode
  // |  S   |  x   | ==0  |   x   |   x   | reloc |  S<-  S/U, came directly from a non-virt bare mode
  // +------+------+------+-------+-------+-------+

  // +------+------+------+-------+-------+-------+
  // | Trap |  -   |vsatp | hstat |hgsatp |       |<- when HS changes hgsatp, hstatus saved in VS save area
  // | Mode |      | Mode |  SPV  | Mode* | reloc |
  // +------+------+------+-------+-------+-------+
  // | VS   |  x   | !=0  |   x   |   x   | skip  | VS<--V[U/S], came directly  from   a     virt  VA  mode
  // | VS   |  x   |  x   |   x   | !=0   | skip  | VS<--V[U/S], higher level is       a non-virt  VA  mode
  // | VS   |  x   |  x   |   x   | ==0   | reloc | VS<--V[U/S], higher level and this are   virt bare modes
  // +------+------+------+-------+-------+-------+

  // where vMPP = m.PRV ? svedMPP : m.MPP
  // +-------+-------+-----------+
  // | Hndlr |  m    |           |
  // | Mode  | MPRV  |   vMPP    |
  // +-------+-------+-----------+
  // |   M   |   0   | mstat.MPP |
  // |   M   |   1   | saved.MPP |
  // +-------+-------+-----------+

        csrr    T3, CSR_XEPC
        mv      T4, sp                  // Use T4 to point to trapping mode sv_area

.ifc \__MODE__ , M
 #ifndef S_SUPPORTED
        j       vmem_adj_\__MODE__\()epc        /* force PA relocation if no Smode      */
 #else
        csrr    T6, CSR_MSTATUS
 // select MPP based on MPRV; if MPRV=1, substitute saved mstatus (with MPP bits)
        slli    T2, T6, XLEN-MPRV_LSB-1         /* put MPRV [17] into sign bit & test   */
        bgez    T2, 1f
        LI(     T6, sved_mpp_off)
        add     T6, T6, sp
        LREG    T6, 0(T6)            /* use saved MPP, since MPP overwritten if MPRV=1 */

1:
 // extract & test selected MPP=3, force reloc if coming from Mmode
        srli    T2, T6,  MPP_LSB
        andi    T2, T2,  MMODE_SIG
        addi    T2, T2, -MMODE_SIG
        beqz    T2, vmem_adj_\__MODE__\()epc

 // extract and test satp.MODE from trapping mode; if !=bare, VA, skip reloc
        csrr    T2, CSR_SATP
#ifdef H_SUPPORTED
        csrr    T6, CSR_MISA           // select effective xATP based on misa[7] (H)
        slli    T6, T6, XLEN-7-1
        bgez    T6, 1f                 // keep  SATP      if no hypervisor
        csrr    T2, CSR_HGATP          // substitute HGATP if    hypervisor
1:
#endif
        srli    T2, T2, MODE_LSB
        addi    T4, sp, 1*sv_area_sz   // T4 points to HS/S mode sv_area
        bnez    T2, sv_\__MODE__\()epc // skip reloc if not bare mode

 // extract and test mstatus.MPV; if 0, single translation & bare mode, force reloc
        #if (XLEN==64)
                csrr    T6, CSR_MSTATUS
        #else
                csrr    T6, CSR_MSTATUSH
        #endif
        slli    T2, T6, WDSZ-MPV_LSB-1
        bgez    T2, vmem_adj_\__MODE__\()epc

 // 2 lvl translation;  extract and test vsatp.MODE!=bare; if so, VA, skip reloc
        csrr    T2, CSR_VSATP
        srli    T2, T2, MODE_LSB
        LI(     T4, 3*sv_area_sz)               // VS/VU mode sv_area
        add     T4, T4, sp
        bnez    T2, sv_\__MODE__\()epc          // mode is bare, fall through to force reloc
  #endif   /* end of Smode_implemented handling */
.endif     /* end of MMode epc reloc handler    */

 .ifc \__MODE__ ,  H
 //  extract and test curr level satp.MODE; if !=bare, VA, skip reloc */
        csrr    T2, CSR_HGATP
        srli    T2, T2, MODE_LSB
        bnez    T2, sv_\__MODE__\()epc          // its a VA, skip adj
 // extract and test hstatus.SPV; if 0, no lower mode, so bare mode, force reloc
        csrr    T2, CSR_HSTATUS
        slli    T2, T2, XLEN-MPV_LSB-1
        bgez    T2, vmem_adj_\__MODE__\()epc
 // extract and test vsatp.MODE!=bare; if so, VA, skip reloc
        csrr    T2, CSR_VSATP
        srli    T2, T2, MODE_LSB
        LI(     T4, 2*sv_area_sz)
        add     T4, T4, sp                      // T4 points to VS/VU mode sv_area
        bnez    T2, sv_\__MODE__\()epc
 // mode is bare, fall through to force reloc
.endif

.ifc \__MODE__ ,  S
//  extract and test curr level satp.MODE!=bare; if so, skip reloc */
        csrr    T2, CSR_SATP
        srli    T2, T2, MODE_LSB
        bnez    T2, sv_\__MODE__\()epc
// mode is bare, fall through to force reloc
.endif

.ifc \__MODE__ ,  V
 //  extract and test curr level satp.MODE!=bare; if so, skip reloc
        csrr    T2, CSR_SATP
        srli    T2, T2, MODE_LSB
        bnez    T2, sv_\__MODE__\()epc
 // extract and test higher level satp.mode!=bare
        LREG    T2, sved_hgatp_off(sp)     /*saved when HS chgs its SATP */
        srli    T2, T2, MODE_LSB
        bnez    T2, sv_\__MODE__\()epc
 // mode is bare, fall through to force reloc
  .endif

  //********************************************************************************
  // offset epc by start addr for code/data/signature/vmem segment start Phys addr
  // since everything must be physical, use start PA from current mode
  // offset still required (until Sail can use same address map
  // Note: Boot code and all RVMODEL routines must be outside of code/data/sig/virtual
  //********************************************************************************

vmem_adj_\__MODE__\()epc:                       // see if epc is in the vmem area
#ifdef SKIP_MEPC
        // skip checking if there are no access faults
        #ifdef RVMODEL_ACCESS_FAULT_ADDRESS
                LI(     T2, RVMODEL_ACCESS_FAULT_ADDRESS)
                beq     T3, T2, sv_\__MODE__\()epc      // Skip checks if XEPC = RVMODEL_ACCESS_FAULT_ADDRESS
                addi    T2, T2, 2
                beq     T3, T2, sv_\__MODE__\()epc      // Skip checks if XEPC = RVMODEL_ACCESS_FAULT_ADDRESS+2
        #endif
#endif
        LREG    T2, vmem_bgn_off(T4)            // T4 points to trapping mode sv_area
        LREG    T6, vmem_seg_siz(T4)
        add     T6, T6, T2                      // construct vmem seg end
        bgeu    T3, T6, code_adj_\__MODE__\()epc// epc > rvtest_vmem_end, try data adj
        bgeu    T3, T2,      adj_\__MODE__\()epc// epc >=rvtest_vmem_begin, adj and save

code_adj_\__MODE__\()epc:
        LREG    T2, code_bgn_off(T4)            // see if epc is in the code area
        LREG    T6, code_seg_siz(T4)
        add     T6, T6, T2                      // construct code seg end
        bgeu    T3, T6, data_adj_\__MODE__\()epc// epc > rvtest_code_end, try data adj
        bgeu    T3, T2,      adj_\__MODE__\()epc// epc >=rvtest_code_begin, adj and save

data_adj_\__MODE__\()epc:
        LREG    T2, data_bgn_off(T4)            // see if epc is in the data area
        LREG    T6, data_seg_siz(T4)
        add     T6, T6, T2                      // construct data seg end
        bgeu    T3, T6, abort_test              // mepc > rvtest_code_end,  (outside data seg), abort
        bltu    T3, T2, abort_test              // mepc < rvtest_code_begin (outside data seg), abort

adj_\__MODE__\()epc:
        sub     T3, T3, T2                      // Offset adjustment

sv_\__MODE__\()epc:
        TRAP_SIGUPD(T4, T3, 2, sv_\__MODE__\()epc, sv_\__MODE__\()epc_str)  // Save XEPC
        csrr    T3, CSR_XEPC                    // As T3 was adjusted for TRAP_SIGUPD, read XEPC again

#ifdef SKIP_MEPC                                //**** spcl case so fetch faults don't rtn to EPC+4
                                                //**** checks if gp=spcl_value & cause=fetch-xx-fault
        LI(     T6, 0xACCE)                     // this is spcl value to compare to x4, set only if SKIP_MEPC defined
        bne     x4, T6, adj_\__MODE__\()epc_rtn // If not called from macro, then skip force of EPC
        csrr    T2, CSR_XCAUSE                  // Read xcause to check trap type
        LI(     T6, CAUSE_FETCH_PAGE_FAULT)     // if CAUSE = FETCH_PAGE_FAULT (0xC) force EPC
        beq     T2, T6, 1f
        LI(     T6, CAUSE_FETCH_ACCESS)         // if CAUSE = FETCH_ACCESS (0xC) force EPC
        beq     T2, T6, 1f
        LI(     T6, CAUSE_FETCH_GUEST_PAGE_FAULT)
        bne     T2, T6, adj_\__MODE__\()epc_rtn // CAUSE_FETCH_ACCESS = 0x14
1:      csrw    CSR_XEPC, ra                    // Force xepc to address in x1 (ra)
        j skp_adj_\__MODE__\()epc
#endif


adj_\__MODE__\()epc_rtn:                // adj mepc so there is at least 4B of padding after op
        andi    T3, T3, ~WDBYTMSK       // adjust mepc to prev 4B alignment (if 2B aligned)
        addi    T3, T3,  2*WDBYTSZ      // adjust mepc so it skips past op, has padding & 4B aligned
        csrw    CSR_XEPC, T3            // restore adjusted value, w/ 2,4 or 6B of padding

skp_adj_\__MODE__\()epc:

        csrr    T3, CSR_XTVAL

sv_\__MODE__\()tval:
        TRAP_SIGUPD(T4, T3, 3, sv_\__MODE__\()tval, sv_\__MODE__\()tval_str)  // Save XTVAL

skp_\__MODE__\()tval:

  .ifc \__MODE__ , M
        csrr    T3, CSR_MISA            // skip mtval2, mtinst save if hypervisor is enabled (misa[7] (H)-1)
        slli    T3, T3, XLEN-7-1
        bgez    T3, 1f
  .endif
  .ifnc \__MODE__ , S
    .ifnc \__MODE__ , V                 // must be either M with H enabled or H
      #ifdef H_SUPPORTED
        sv_\__MODE__\()Mtval2:
        csrr    T3, CSR_MTVAL2          // **** FIXME: does this need reloc also? Its a guest phys addr
        TRAP_SIGUPD(T4, T3, 4, sv_\__MODE__\()Mtval2, sv_Mtval2_str)  // Save MTVAL2
        sv_\__MODE__\()Mtinst:
        csrr    T3, CSR_MTINST
        TRAP_SIGUPD(T4, T3, 5, sv_\__MODE__\()Mtinst, sv_Mtinst_str)  // Save MTINST
      #endif
    .endif
  .endif

1:
chk_\__MODE__\()trapsig_overrun:        // sv_area_off is defined above at Xtrap_sig_sv:
 //This is the same code used at xtrap_sig_sv to get the shared copy of trap signature pointer
        addi    sp, sp, -1*sv_area_sz   // offset sp to avoid overflow
        LREG    T4, sv_area_off+trapsig_ptr_off(sp)
        LREG    T2, sv_area_off+sig_bgn_off(sp)
        LREG    T1, sv_area_off+sig_seg_siz(sp)
        addi    sp, sp, 1*sv_area_sz

// now see if the pointer has overrun sig_end
        add     T1, T1, T2                      // construct segment end address
        bgtu    T4, T1, abort_test              // abort test if pre-incremented value overruns

  /**** vector to exception special handling routines ****/
        li      T2, int_hndlr_tblsz             // offset of exception dispatch table base
        j       spcl_\__MODE__\()handler        // jump to shared interrupt/exception spcl handling dispatcher

 /**** common return code for both interrupts and exceptions ****/
resto_\__MODE__\()rtn:                  // restore and return
        LREG    T1, trap_sv_off+1*REGWIDTH(sp)
        LREG    T2, trap_sv_off+2*REGWIDTH(sp)
        LREG    T3, trap_sv_off+3*REGWIDTH(sp)
        LREG    T4, trap_sv_off+4*REGWIDTH(sp)
        LREG    T5, trap_sv_off+5*REGWIDTH(sp)
        LREG    T6, trap_sv_off+6*REGWIDTH(sp)
        LREG    sp, trap_sv_off+7*REGWIDTH(sp)      // restore temporaries

  .ifc \__MODE__ , M
        mret
  .else
        sret                            // this returns to VS if PV=1, or HS/S otherwise
  .endif

 /**************************************************************/
 /**** This is the interrupt specific code. It attempts     ****/
 /**** to clear the int and saves int-specific CSRS         ****/
 /**** NOTE! also clrs IE in case clring ip bit doesn't work****/
 /**************************************************************/
common_\__MODE__\()int_handler:         // T1 has sig ptr, T5 has mcause, sp has save area
        li      T3, 1
 //**FIXME** - make sure this is kept up-to-date with fast int extension and others
        andi    T2, T5, INT_CAUSE_MSK   // clr INT & unarched arched bits (**NOTE expand if future extns use them)
        sll     T3, T3, T2              // create mask 1<<xcause **NOTE**: that MSB is ignored in shift amt
        csrrc   T4, CSR_XIE, T3         // read, then attempt to clear int enable bit??
        csrrc   T3, CSR_XIP, T3         // read, then attempt to clear int pend bit
sv_\__MODE__\()ip:                      // note: clear has no effect on MxIP
        TRAP_SIGUPD(T4, T3, 2, sv_\__MODE__\()ip, sv_\__MODE__\()ip_str)  // Save XIP

        LI(     T2, 0)                  // index of interrupt dispatch table base

/**************************************************************/
/**** spcl int/excp dispatcher. T5 has mcause, T2 holds    ****/
/**** int table (0) or exception tbl (int_tbl_sz) offset   ****/
/**** This loads an entry @(table_base+table_off+mcause*8  ****/
/**** if entry=0, it should never be taken, error return   ****/
/**** if entry is odd, it has cause<<1,  skip disptaching  ****/
/**** otherwise if even & >0, it is the handler address    ****/
/**** There is an optional check that cause==mcause        ****/
/**************************************************************/

spcl_\__MODE__\()handler:               // case table branch to special handler code, depending on mcause
        auipc   T3, 0                   // shortcut for LA(clrint_\__MODE__\()tbl) (might be 4 too large)
        addi    T3, T3, 15*4            // shortcut to avoid LA clrint_xtbl - this is might be 4 too large
        add     T3, T3, T2              // offset into the correct interrupt/exception dispatch table
        slli    T2, T5, 3               // index into 8b aligned dispatch entry and jump through it
        add     T3, T3, T2
        andi    T3, T3, -8              // make sure this is dblwd aligned, correct if it is 4 too large
        LREG    T3, 0(T3)
spcl_\__MODE__\()dispatch_handling:
        beqz    T3, 1f                  // if address is 0, this is an error, exit test
        slli    T2, T3, XLEN-1          // look at LSB and dispatch if even
        bge     T2, x0, spcl_\__MODE__\()dispatch
        srli    T3, T3,1                //odd entry>0, remove LSB, normalizing to cause range
        beq     T5, T3, resto_\__MODE__\()rtn // case range matches, not an error, just noop
1:
        j       abort_test

spcl_\__MODE__\()dispatch:
        jr      T3                      // not a default, jump to handler
//**** WARNING!!! - all routines pointed to by this table need their 1st op to be lpad(0)(for cfilp) !!!

/**** this is the table of interrupt clearing routine pointers  ****/
/**** They could include special handlers                       ****/
/**** They default to model supplied RVMODEL macros above,      ****/
/**** Note that external int routines rtn with intID in T3      ****/
        //**** FIXME: make sure this is up to date with priv1.13
        //**** FIXME: is there any reason these are mode specific? i.e.
        //**** any specific interrupt special handler will only be in one mode,
        //**** so let the test change the pointer when delegation changes

        .align 3                        //make sure this is a dblwd boundary
clrint_\__MODE__\()tbl:                              //this code should only touch T2..T6
#if defined(H_SUPPORTED)   //  M/S/V/U
        .dword  0                        // int cause  0 is rsvd, error
        .dword  \__MODE__\()clr_Ssw_int  // int cause  1  Smode SW int
        .dword  \__MODE__\()clr_Vsw_int  // int cause  2  Vmode SW int
        .dword  \__MODE__\()clr_Msw_int  // int cause  3  Mmode SW int
 //****************************************************************
        .dword  0                        // int cause  4 is rsvd, error
        .dword  \__MODE__\()clr_Stmr_int // int cause  5  Smode Tmr int
        .dword  \__MODE__\()clr_Vtmr_int // int cause  6  Vmode Tmr int
        .dword  \__MODE__\()clr_Mtmr_int // int cause  7  Mmode Tmr int
 //****************************************************************
        .dword  0                        // int cause  8 is rsvd, error
        .dword  \__MODE__\()clr_Sext_int // int cause  9  Smode Ext int
        .dword  \__MODE__\()clr_Vext_int // int cause  A  Vmode Ext int
        .dword  \__MODE__\()clr_Mext_int // int cause  B  Mmode Ext int
 //****************************************************************
#else
  #if defined(H_SUPPORTED) || defined(S_SUPPORTED)   // M/H/S/U only
        .dword  0                        // int cause  0 is rsvd, error
        .dword  \__MODE__\()clr_Ssw_int  // int cause  1  Smode SW int
        .dword  1                        // int cause  2  no Vmode
        .dword  \__MODE__\()clr_Msw_int  // int cause  3  Mmode SW int
 //****************************************************************
        .dword  0                        // int cause  4 is rsvd, error
        .dword  \__MODE__\()clr_Stmr_int // int cause  5  Smode Tmr int
        .dword  1                        // int cause  6 no vmode
        .dword  \__MODE__\()clr_Mtmr_int // int cause  7  Mmode Tmr int
 //****************************************************************
        .dword  0                        // int cause  8 is reserved, error
        .dword  \__MODE__\()clr_Sext_int // int cause  9  Smode Ext int
        .dword  1                        // int cause  A no vmode
        .dword  \__MODE__\()clr_Mext_int // int cause  B  Mmode Ext int
 //****************************************************************
  #else   // M(/U)mode only
        .dword  0                        // int cause  0 is rsvd, error
        .dword  1                        // int cause  1  no Smode
        .dword  1                        // int cause  2  no Vmode
        .dword  \__MODE__\()clr_Msw_int  // int cause  3  Mmode SW int
 //****************************************************************
        .dword  0                        // int cause  4 is svd, error
        .dword  1                        // int cause  5 no Smode
        .dword  1                        // int cause  6 no vmode
        .dword  \__MODE__\()clr_Mtmr_int // int cause  7  Mmode Tmr int
 //****************************************************************
        .dword  0                        // int cause  8 is svd, error
        .dword  1                        // int cause  9 no Smode
        .dword  1                        // int cause  A no vmode
        .dword  \__MODE__\()clr_Mext_int // int cause  B  Mmode Ext int
//****************************************************************
  #endif
#endif

 .rept NUM_SPECD_INTCAUSES-0xC
        .dword  1                       // int cause c..NUM_SPECD_INTCAUSES is reserved, just return
 .endr
 .rept XLEN-NUM_SPECD_INTCAUSES
        .dword  0                       // impossible, quit test by jumping to  epilogs
 .endr
//****************************************************************

/**** this is the table of exception handling routine pointers, which ****/
/****  could include special handlers. They default to the rtn code   ****/
excpt_\__MODE__\()hndlr_tbl:            // handler code should only touch T2..T6 ****<<--must be speced!****
 .set causeidx, 0
 .rept NUM_SPECD_EXCPTCAUSES
        .dword  causeidx*2+1            // default, marked by @*cause+2just return
        .set    causeidx, causeidx+1
 .endr
 .rept XLEN-NUM_SPECD_EXCPTCAUSES
        .dword  0                       // impossible, quit test by jumping to epilogs
 .endr

/**** These are invocations of the model supplied interrupt clearing macros   ****/
/**** Note there is a copy per mode, though they could all be the same code   ****/
/**** !!! Note: These macros should only touch T2..T6, unless                 ****/
/****  test is aware of other modified registers and knows they are dead.     ****/
/****  T1=sig ptr, sp=sv area ptr; not to be modified under any circumstances ****/
/**** !!! Note: the ext interrupt clearing macros must leave intID in T3 !!!  ****/
// **FIXME** : the spec needs to be updated with the per/mode versions, not just one
// do these need per/mode versions? presumably they are written so the lowest
// priv mode that is it delegated to will work
// Move interrupt handler stubs to .text.rvmodel so that RVMODEL macro size
// differences between DUT and reference don't affect .text.rvtest size (which
// would shift .data addresses and break page table setups).
.pushsection .text.rvmodel, "ax"

//------------- MMode----------------
\__MODE__\()clr_Msw_int:                // int 3 default to just return if not defined
        RVMODEL_CLR_MSW_INT(T2, T5)
        j       resto_\__MODE__\()rtn

\__MODE__\()clr_Mtmr_int:               // int 7 default to just return
        li T5, -1
        # skip if RVMODEL_MTIMECMP_ADDRESS is not defined
        #ifdef RVMODEL_MTIMECMP_ADDRESS
                la T2, RVMODEL_MTIMECMP_ADDRESS
                SREG T5, 0(T2)
        #endif
        #if __riscv_xlen == 32
                sw T5, 4(T2)
        #endif
        j       resto_\__MODE__\()rtn

\__MODE__\()clr_Mext_int:               // int11 default to just return after saving IntID in T3
        RVMODEL_CLR_MEXT_INT(T2, T5)
        TRAP_SIGUPD(T4, T3, 3, \__MODE__\()clr_Mext_int, \__MODE__\()clr_Mext_int_str)  // Save intID
        j       resto_\__MODE__\()rtn

//------------- [H]SMode----------------
\__MODE__\()clr_Ssw_int:                // int 1 default to just return if not defined
                                        // SSIP can be set via CSR write or external controller; clear both
        .ifc \__MODE__ , M              // M-mode: mideleg.SSIP=0 so sip.SSIP is read-only; clear via mip
            li T2, 2
            csrc mip, T2
            RVMODEL_CLR_SSW_INT(T2, T5)
        .else
                .ifc \__MODE__ , S      // S-mode: mideleg.SSIP=1 so sip.SSIP mirrors mip and is writable
                        li T2, 2
                        csrc sip, T2
                        RVMODEL_CLR_SSW_INT(T2, T5)
                .else
                        li T2, 2
                        csrc sip, T2
                        RVMODEL_CLR_SSW_INT(T2, T5)
                .endif
        .endif

        j       resto_\__MODE__\()rtn

\__MODE__\()clr_Stmr_int:               // int 5 default to just return
                                        // S-mode timer interrupts need to be reset differently when raised in M or S mode
        .ifc \__MODE__ , M              // Select the interrupt handler function based on current privilege mode
            RVTEST_CLR_STIMER_INT
        .else
                .ifc \__MODE__ , S
                        RVTEST_CLR_STIMER_INT
                .else
                        RVTEST_CLR_STIMER_INT
                .endif
        .endif
        j       resto_\__MODE__\()rtn

\__MODE__\()clr_Sext_int:               // int 9 default to just return after saving IntID in T3
        RVMODEL_CLR_SEXT_INT(T2, T5)
        TRAP_SIGUPD(T4, T3, 3, \__MODE__\()clr_Sext_int, \__MODE__\()clr_Sext_int_str)  // Save intID
        j       resto_\__MODE__\()rtn

//------------- VSmode----------------
\__MODE__\()clr_Vsw_int:                // int 2 default to just return if not defined
        RVMODEL_CLR_VSW_INT
        j       resto_\__MODE__\()rtn

\__MODE__\()clr_Vtmr_int:               // int 6 default to just return
        RVMODEL_CLR_VTIMER_INT
        j       resto_\__MODE__\()rtn

\__MODE__\()clr_Vext_int:               // int 10 default to just return after saving IntID in T3
        RVMODEL_CLR_VEXT_INT
        TRAP_SIGUPD(T4, T3, 3, \__MODE__\()clr_Vext_int, \__MODE__\()clr_Vext_int_str)  // Save intID
        j       resto_\__MODE__\()rtn

.popsection

.ifc \__MODE__ , M

/***************  Spcl handler for returning from GOTO_MMODE.            ********/
/***************  Only gets executed if GOTO_MMODE not called from Mmode ********/
/***************  Executed in M-mode. Enter w/ T1=ptr to Mregsave, T2=0  ********/
/***************  NOTE: Ecall must NOT delegate when T2=0 or this fails  ********/

\__MODE__\()rtn2mmode:                  //T4 contains masked ECALL-8 (so 0 is Umode Ecall, 3 is Mmode Ecall
        csrr    T2, CSR_MSTATUS
        srli    T4, T2,  MPP_LSB
        andi    T4, T4,  MMODE_SIG
        addi    T3, T4, -MMODE_SIG
        csrr    T2, CSR_MEPC
        li      T4, 0
        beqz    T3, rtn_fm_mmode        /* shortcut if called from Mmode        */
// find callers save area
        addi    sp, sp, sv_area_sz      //preadjust svarea ptr to avoid to large offset

  #if (XLEN==32)
        csrr    T2, CSR_MSTATUSH        /* find Vbit  if RV32                   */
  #else
        csrr    T2, CSR_MSTATUS
  #endif
        slli    T2, T2, WDSZ-1-MPV_LSB  /* but V into MSB  ****FIXME if RV128   */
        bgez    T2, from_hs_u           /* H enabled,  V==0, Smode  *1 offset   */
from_vs:
        addi    sp, sp, sv_area_sz      // readjust svarea ptr to avoid larger offset
        LREG    T6, code_bgn_off+1*sv_area_sz(sp) /* V=1 & VSmode;  *3 offset   */
        addi    sp, sp, -sv_area_sz
        j       1f
from_hs_u:
  #ifdef S_SUPPORTED
        LREG    T6, code_bgn_off+0*sv_area_sz(sp) /* V=0& H=1, HS;  *1 offset   */
  #else
        LREG    T6, code_bgn_off-1*sv_area_sz(sp) /* Use M-mode save area       */
  #endif
//calc callerEPC-callerBgn
1:
        csrr    T2, CSR_MEPC            /* get rtn addr in orig mode's VM */
        sub     T2, T2, T6              /* calc reloc amt callerEPC-callerBgn   */
        addi    sp, sp, -sv_area_sz     //undo preadjust
        LREG    T4, code_bgn_off-0*sv_area_sz(sp)    /* get M   mode code begin */
rtn_fm_mmode:
        add     T2, T4, T2              /* calc rtn_addr in Mmode VM            */

        LREG    T1, trap_sv_off+1*REGWIDTH(sp)
 //     LREG    T2, trap_sv_off+2*REGWIDTH(sp) /*this holds the return address  */
        LREG    T3, trap_sv_off+3*REGWIDTH(sp)
        LREG    T4, trap_sv_off+4*REGWIDTH(sp)
        LREG    T5, trap_sv_off+5*REGWIDTH(sp)
        LREG    T6, trap_sv_off+6*REGWIDTH(sp)
        LREG    sp, trap_sv_off+7*REGWIDTH(sp)      // restore temporaries
        jr      4(T2)                   /* return after GOTO_MMODE in M-mode    */

//****FIXME GOTO_MMODE macro must have an lpad(0) following the GOTO_MMODE for cfiplp

.endif

// Returning from RVTEST_GOTO_SMODE
// Used when U-mode ecall (bit 8) is delegated to S-mode

.ifc \__MODE__ , S

\__MODE__\()rtn2smode:
        csrr    T3, CSR_XEPC                    // sepc = address of ecall in U-mode
        addi    T3, T3, 4                       // skip ecall
        csrw    CSR_XEPC, T3                    // returns to instruction after ecall
        LI(T3, SSTATUS_SPP)                     // T3 = 0x100
        csrs    CSR_XSTATUS, T3                 // set SPP=1 to return to S-mode
        j       resto_\__MODE__\()rtn
.endif
.option pop
.endm                                   // end of HANDLER

/*******************************************************************************/
/***************                 end of handler macro               ************/
/*******************************************************************************/
/*******************************************************************************/
/**************** cleanup code; restore xtvec or where it points to ************/
/********* Assumption: in M-mode, because GOTO_MMODE always ends tests *********/
/********* Assumption: XSCRATCH pnts to save area for appropriate mode *********/
/*******************************************************************************/

.macro RVTEST_TRAP_EPILOG __MODE__
.option push
.option norvc

        XCSR_RENAME \__MODE__                   // retarget XCSR names to this modes CSRs, no V/S aiasing
        LI(T3, actual_tramp_sz)                 // this loads full size of trampoline area
exit_\__MODE__\()cleanup:                       // if you enter here from the abort sequence, T3 might be shorter
        // lpad(0)                                 // is target of a jr, so landing pad needed
        csrr  T1, mscratch                      // ptr to top of mode save area, adjust to this modes area, dflt is M
      .ifc \__MODE__ , H
        addi T1, T1, 1*sv_area_sz
      .else
        .ifc \__MODE__ , S
          addi T1, T1, 2*sv_area_sz
        .else
          .ifc \__MODE__ , V
             addi T1, T1, 1*sv_area_sz          // 3*sv_area_sz to large, break it up
             addi T1, T1, 2*sv_area_sz
          .endif
        .endif
      .endif

//----------------------
// Guard below must match init_edeleg. If init skips the csrw (e.g. no S-mode),
// restore must skip it too. Mismatch causes infinite trap loop on configs where
// the CSR does not exist. See issue #1050.
resto_\__MODE__\()edeleg:
        LREG    T2,   xedeleg_sv_off(T1)        // get saved xedeleg
#if (XLEN==32)
        LREG    T4, 4+xedeleg_sv_off(T1)        // get saved xedelegh
#endif
.ifnc \__MODE__ , S
  .ifnc \__MODE__ , V
#ifdef S_SUPPORTED
        csrw    CSR_XEDELEG,  T2
    .ifc \_MODE__ , M   // TODO: Remove this .ifc when sail supports hedelegh (if Smstateen is supported, set mstateen0.P1P13)
      #if (XLEN==32)
        csrw    CSR_XEDELEGH, T4
      #endif
    .endif
#endif
  .endif
.endif

//----------------------
resto_\__MODE__\()satp:
        LREG    T2, xsatp_sv_off(T1)            // restore saved xsatp (if it exists)
.ifc \__MODE__ , H
        csrw    CSR_HGATP,  T2
.else
  .ifc \__MODE__ , S
        csrw    CSR_SATP,   T2
  .endif
        .endif

//----------------------
resto_\__MODE__\()scratch:
        LREG    T4, xscr_save_off(T1)           // restore saved xscratch
        csrw    CSR_XSCRATCH, T4

//----------------------
resto_\__MODE__\()xtvec:
        LREG    T4, xtvec_sav_off(T1)           // restore  orig xtvec addr & load current one
        csrrw   T2, CSR_XTVEC, T4
        andi    T4, T4, ~WDBYTMSK               // remove mode, so both word aligned
        andi    T2, T2, ~WDBYTMSK
        bne     T4, T2, 1f                      // if saved!=curr mtvec, done, else need to restore tramp

//----------------------
// T3 contains the end of the trampoline, either from abort sequence or beginning of epilog
resto_\__MODE__\()tramp:                        // T2 now contains where to restore to
        addi    T4, T1, tramp_sv_off            // T4 now contains where to restore from


resto_\__MODE__\()loop:
        lw      T6, 0(T4)                       // read saved tramp entry
        sw      T6, 0(T2)                       // restore original tramp entry
        addi    T2, T2, WDBYTSZ                 // next tgt  index
        addi    T4, T4, WDBYTSZ                 // next save index
        blt     T2, T3, resto_\__MODE__\()loop  // didn't get to end, continue
  1:
        RVMODEL_FENCEI                          // make sure the overwritten trampoline will be fetched

//----------------------
.global rvtest_\__MODE__\()end
rvtest_\__MODE__\()end:
        // lpad(0)                                 //this is target of jr, needs landing pad
#ifdef HANDLER_TESTCODE_ONLY
        //**FIXME**: add conditional code to compare original trampoline with
        // restored trampoline and store the deltas in the trap signature region
        // as an added check? must work for each mode
#endif
 .option pop
 .endm                                          //end of EPILOG
/*******************************************************************************/
/**** end epilog cleanup code; fall thru from V->S->H->M into RVMODEL_HALT *****/
/*******************************************************************************/

/*******************************************************************************/
/**** This macro defines per/mode save areas for mmode for each mode        ****/
/**** note that it is the code area, not the data area, and                 ****/
/**** must be multiple of 8B, so multiple instantiations stay aligned       ****/
/**** This is preceded by the current signature pointer, (@Mtrpreg_sv -64?  ****/
/*******************************************************************************/
.macro RVTEST_TRAP_SAVEAREA __MODE__

.option push
.option norvc
.global \__MODE__\()tramptbl_sv

//****ASSERT: this should be a 64B boundary******//
\__MODE__\()tramptbl_sv:        // save area of existing trampoline table,     // also stored in XSCRATCH!!!
.rept (tramp_sz>>2)             // size in words (technically, length of j op) padded to be 8B aligned
        j       .+0             // prototype jump instruction, offset to be filled in
.endr
\__MODE__\()save_area:
\__MODE__\()code_bgn_ptr:  .dword rvtest_code_begin // ptr to code bgn area using this mode's mapping trampsvend+0*8
\__MODE__\()code_seg_sz:   .dword rvtest_code_end-rvtest_code_begin      // code seg size in any mode trampsvend+1*8
\__MODE__\()data_bgn_ptr:  .dword rvtest_data_begin // ptr to data bgn area using this mode's mapping trampsvend+2*8
\__MODE__\()data_seg_sz:   .dword rvtest_data_end-rvtest_data_begin      // code seg size in any mode trampsvend+3*8
\__MODE__\()sig_bgn_ptr:   .dword rvtest_sig_begin  // ptr to sig  bgn area using this mode's mapping trampsvend+4*8
\__MODE__\()sig_seg_sz:    .dword rvtest_sig_end-rvtest_sig_begin        // code seg size in any mode trampsvend+5*8
\__MODE__\()vmem_bgn_ptr:  .dword rvtest_code_begin // dflt to code bgn area  w/  this mode's mapping trampsvend+6*8
\__MODE__\()vmem_seg_sz:   .dword rvtest_code_end-rvtest_code_begin      // vmem seg size in any mode trampsvend+7*8

\__MODE__\()trap_sig:      .dword  trap_sigptr  // ptr to next trapsig  (applies to all modes)        trampsvend+8*8
\__MODE__\()satp_sv:       .dword 0             // sv area for incoming xsatp                         trampsvend+9*8
\__MODE__\()sved_misa:                          // sved when misa.h changes               ***only Mmode sv area vers
\__MODE__\()sved_hgatp:                         // sved when hgatp.mode chgs              ***only Hmode sv area vers
\__MODE__\()sved_mpp:                           // sved during Mmode test with MPRV set   ***only Smode sv area vers
\__MODE__\()unused:        .dword  0                                                              //  trampsvend+10*8
\__MODE__\()tentry_sv:     .dword  \__MODE__\()trampoline + actual_tramp_sz  // sv comm trpentry pt   trampsvend+11*8
\__MODE__\()edeleg_sv:     .dword  0           // save loc for edeleg CSR                             trampsvend+12*8
\__MODE__\()tvec_new:      .dword  0           // points to in-use tvec, actual tramp table used      trampsvend+13*8
\__MODE__\()tvec_save:     .dword  0           // save area for incoming mtvec                        trampsvend+14*8
\__MODE__\()scratch_save:  .dword  0           // save area for incoming mscratch                     trampsvend+15*8
\__MODE__\()trapreg_sv:    .fill   8, REGWIDTH, 0xdeadbeef // hndler regsv area ****onlyMMode used    trampsvend+16*8
                                                //T1..T6,sp+spare to keep dbl algn
\__MODE__\()rvmodel_sv:    .fill   8, REGWIDTH, 0xdeadbeef // rvmodel macro regsv area                trampsvend+24*8
\__MODE__\()sv_area_end:        // used to calc size, which is used to avoid CSR read trampsvend+32*8

.option pop
.endm                           // end of TRAP_SAVEAREA
