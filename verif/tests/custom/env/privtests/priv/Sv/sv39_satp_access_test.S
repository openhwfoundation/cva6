// --------------------------------------------------------------------------------------------------------------------------------
// Developed by: Umer Shahid, Muhammad Abdullah, Muhammad Zain, Hamza Ali and Muhammad Ahmad
// --------------------------------------------------------------------------------------------------------------------------------
// Test cases are as follows:
// --------------------------------------------------------------------------------------------------------------------------------
//  1. Accessing satp in M mode -> Successful
//  2. Accessing satp in S mode -> Successful
//  3. Accessing satp in U mode -> 3 Illegal Instruction exceptions
//  4. Set satp.MODE to Sv39 -> Successful
//  5. All zeros, ones and walking ones on the PPN field of satp when satp.MODE=Sv39 -> Successful
//  6. All zeros, ones and walking ones on the ASID field of satp when satp.MODE=Sv39 -> Successful
//
// Total Expected Faults :: 3
// --------------------------------------------------------------------------------------------------------------------------------

##### START_TEST_CONFIG #####
# REQUIRED_EXTENSIONS: [I, Sv39]
# MARCH: rv64i_zicsr
##### END_TEST_CONFIG #####

#define TEST_FILE "sv39_satp_access_test.S"
#define SIGUPD_COUNT 80
#define TRAP_SIGUPD_COUNT 30
#define rvtest_mtrap_routine
#define rvtest_strap_routine
#define RVTEST_PRIV_TEST
#define SKIP_MEPC

#include "riscv_arch_test.h"

RVTEST_BEGIN


main:
//---------------------------------------------------------------------------------------------------------------------------------
// Test case 1: Access satp in M-mode using csrrw, csrrs, csrrc | Expected: Successful access
//---------------------------------------------------------------------------------------------------------------------------------

  li a0, 1
  CSRW(satp, a0)
  test1_csrw:
  RVTEST_SIGUPD_CSR_READ(satp, a4, test1_csrw, test1_csrw_str)

  li a0, 2
  CSRS(satp, a0)
  test1_csrs:
  RVTEST_SIGUPD_CSR_READ(satp, a4, test1_csrs, test1_csrs_str)

  li a0, 1
  CSRC(satp, t0)
  test1_csrc:
  RVTEST_SIGUPD_CSR_READ(satp, a4, test1_csrc, test1_csrc_str)


//---------------------------------------------------------------------------------------------------------------------------------
// Test case 2: Access satp in S-mode using csrrw, csrrs, csrrc | Expected: Successful access
//---------------------------------------------------------------------------------------------------------------------------------

  RVTEST_GOTO_LOWER_MODE Smode

  li a0, 4
  CSRW(satp, a0)
  test2_csrw:
  RVTEST_SIGUPD_CSR_READ(satp, a4, test2_csrw, test2_csrw_str)

  li a0, 8
  CSRS(satp, a0)
  test2_csrs:
  RVTEST_SIGUPD_CSR_READ(satp, a4, test2_csrs, test2_csrs_str)

  li a0, 4
  CSRC(satp, t0)
  test2_csrc:
  RVTEST_SIGUPD_CSR_READ(satp, a4, test2_csrc, test2_csrc_str)

  RVTEST_GOTO_MMODE


//---------------------------------------------------------------------------------------------------------------------------------
// Test case 3: Access satp in U-mode using csrrw, csrrs, csrrc | Expected: 3 Illegal instruction exceptions
//---------------------------------------------------------------------------------------------------------------------------------

  RVTEST_GOTO_LOWER_MODE Umode

  li a0, 3
  CSRW(satp, a0)

  li a0, 12
  CSRS(satp, a0)

  li a0, 6
  CSRC(satp, t0)

  RVTEST_GOTO_MMODE

  test3:
  RVTEST_SIGUPD_CSR_READ(satp, a4, test3, test3_str)


//---------------------------------------------------------------------------------------------------------------------------------
// Test case 4: Set satp.MODE to Sv39 | Expected: Successful
//---------------------------------------------------------------------------------------------------------------------------------

  LI(a0, SATP_MODE_SV39<<60)      // satp.MODE = 4'b1000 (Sv39)
  CSRW(satp, a0)
  test4_sv39:
  RVTEST_SIGUPD_CSR_READ(satp, a4, test4_sv39, test4_sv39_str)


//---------------------------------------------------------------------------------------------------------------------------------
// Test case 5: Zeros, ones and walking ones on satp.PPN | Expected: Successful
//---------------------------------------------------------------------------------------------------------------------------------

  LI(a1, SATP_MODE_SV39<<60)      // satp.MODE = Sv39

  // satp.PPN = All zeros
  mv   a0, a1
  CSRW(satp, a0)
  test5_zeros:
  RVTEST_SIGUPD_CSR_READ(satp, a4, test5_zeros, test5_zeros_str)

  // satp.PPN = All ones
  LI(  a0, 0xFFFFFFFFFFF)
  or   a0, a1, a0
  CSRW(satp, a0)
  test5_ones:
  RVTEST_SIGUPD_CSR_READ(satp, a4, test5_ones, test5_ones_str)

  // satp.PPN = Walking Ones
  li a2, 1
  .rept(44)
    or   a0, a1, a2
    CSRW(satp, a0)
    5:
    RVTEST_SIGUPD_CSR_READ(satp, a4, 5b, test5_walk_str)
    slli  a2, a2, 1
  .endr


//---------------------------------------------------------------------------------------------------------------------------------
// Test case 6: Zeros, ones and walking ones on satp.ASID | Expected: Successful
//---------------------------------------------------------------------------------------------------------------------------------

  LI(a1, SATP_MODE_SV39<<60)      // satp.MODE = Sv39

  // satp.ASID = All zeros
  mv   a0, a1
  CSRW(satp, a0)
  test6_zeros:
  RVTEST_SIGUPD_CSR_READ(satp, a4, test6_zeros, test6_zeros_str)

  // satp.ASID = All ones
  LI(  a0, 0xFFFF)
  slli a0, a0, 44
  or   a0, a1, a0
  CSRW(satp, a0)
  test6_ones:
  RVTEST_SIGUPD_CSR_READ(satp, a4, test6_ones, test6_ones_str)

  // satp.ASID = Walking Ones
  li   a2, 1
  slli a2, a2, 44
  .rept(16)
    or   a0, a1, a2
    CSRW(satp, a0)
    6:
    RVTEST_SIGUPD_CSR_READ(satp, a4, 6b, test6_walk_str)
    slli  a2, a2, 1
  .endr


//---------------------------------------------------------------------------------------------------------------------------------
RVTEST_CODE_END
RVTEST_DATA_BEGIN


test1_csrw_str:   .string "\"Mismatch on csrw in Test Case 1!\""
test1_csrs_str:   .string "\"Mismatch on csrs in Test Case 1!\""
test1_csrc_str:   .string "\"Mismatch on csrc in Test Case 1!\""
test2_csrw_str:   .string "\"Mismatch on csrw in Test Case 2!\""
test2_csrs_str:   .string "\"Mismatch on csrs in Test Case 2!\""
test2_csrc_str:   .string "\"Mismatch on csrc in Test Case 2!\""
test3_str:        .string "\"Mismatch in Test Case 3!\""
test4_sv39_str:   .string "\"Mismatch on setting satp.MODE=Sv39 in Test Case 4!\""
test5_zeros_str:  .string "\"Mismatch on setting satp.PPN=Zeros in Test Case 5!\""
test5_ones_str:   .string "\"Mismatch on setting satp.PPN=Ones in Test Case 5!\""
test5_walk_str:   .string "\"Mismatch on walking ones in satp.PPN in Test Case 5!\""
test6_zeros_str:  .string "\"Mismatch on setting satp.ASID=Zeros in Test Case 6!\""
test6_ones_str:   .string "\"Mismatch on setting satp.ASID=Ones in Test Case 6!\""
test6_walk_str:   .string "\"Mismatch on walking ones in satp.ASID in Test Case 6!\""

RVTEST_DATA_END
RVTEST_SIG_SETUP
