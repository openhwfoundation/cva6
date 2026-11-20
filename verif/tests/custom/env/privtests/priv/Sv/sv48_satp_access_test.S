// --------------------------------------------------------------------------------------------------------------------------------
// Developed by: Umer Shahid & Muhammad Zain
// --------------------------------------------------------------------------------------------------------------------------------
// Test cases are as follows:
// --------------------------------------------------------------------------------------------------------------------------------
//  1. Set satp.MODE to Sv48 -> Successful
//  2. All zeros, ones and walking ones on the PPN field of satp when satp.MODE=Sv48 -> Successful
//  3. All zeros, ones and walking ones on the ASID field of satp when satp.MODE=Sv48 -> Successful
//
// Total Expected Faults :: 0
// --------------------------------------------------------------------------------------------------------------------------------

##### START_TEST_CONFIG #####
# REQUIRED_EXTENSIONS: [I, Sv48]
# MARCH: rv64i_zicsr
##### END_TEST_CONFIG #####

#define TEST_FILE "sv48_satp_access_test.S"
#define SIGUPD_COUNT 70
#define TRAP_SIGUPD_COUNT 10
#define rvtest_mtrap_routine
#define rvtest_strap_routine
#define RVTEST_PRIV_TEST
#define SKIP_MEPC

#include "riscv_arch_test.h"

RVTEST_BEGIN


main:
//---------------------------------------------------------------------------------------------------------------------------------
// Test case 1: Set satp.MODE to Sv48 | Expected: Successful
//---------------------------------------------------------------------------------------------------------------------------------

  LI(a0, SATP_MODE_SV48<<60)      // satp.MODE = 4'b1001 (Sv48)
  CSRW(satp, a0)
  test1_sv48:
  RVTEST_SIGUPD_CSR_READ(satp, a4, test1_sv48, test1_sv48_str)


//---------------------------------------------------------------------------------------------------------------------------------
// Test case 2: Zeros, ones and walking ones on satp.PPN | Expected: Successful
//---------------------------------------------------------------------------------------------------------------------------------

  LI(a1, SATP_MODE_SV48<<60)      // satp.MODE = Sv48

  // satp.PPN = All zeros
  mv   a0, a1
  CSRW(satp, a0)
  test2_zeros:
  RVTEST_SIGUPD_CSR_READ(satp, a4, test2_zeros, test2_zeros_str)

  // satp.PPN = All ones
  LI(  a0, 0xFFFFFFFFFFF)
  or   a0, a1, a0
  CSRW(satp, a0)
  test2_ones:
  RVTEST_SIGUPD_CSR_READ(satp, a4, test2_ones, test2_ones_str)

  // satp.PPN = Walking Ones
  li a2, 1
  .rept(44)
    or   a0, a1, a2
    CSRW(satp, a0)
    5:
    RVTEST_SIGUPD_CSR_READ(satp, a4, 5b, test2_walk_str)
    slli  a2, a2, 1
  .endr


//---------------------------------------------------------------------------------------------------------------------------------
// Test case 3: Zeros, ones and walking ones on satp.ASID | Expected: Successful
//---------------------------------------------------------------------------------------------------------------------------------

  LI(a1, SATP_MODE_SV48<<60)      // satp.MODE = Sv48

  // satp.ASID = All zeros
  mv   a0, a1
  CSRW(satp, a0)
  test3_zeros:
  RVTEST_SIGUPD_CSR_READ(satp, a4, test3_zeros, test3_zeros_str)

  // satp.ASID = All ones
  LI(  a0, 0xFFFF)
  slli a0, a0, 44
  or   a0, a1, a0
  CSRW(satp, a0)
  test3_ones:
  RVTEST_SIGUPD_CSR_READ(satp, a4, test3_ones, test3_ones_str)

  // satp.ASID = Walking Ones
  li   a2, 1
  slli a2, a2, 44
  .rept(16)
    or   a0, a1, a2
    CSRW(satp, a0)
    6:
    RVTEST_SIGUPD_CSR_READ(satp, a4, 6b, test3_walk_str)
    slli  a2, a2, 1
  .endr


//---------------------------------------------------------------------------------------------------------------------------------
RVTEST_CODE_END
RVTEST_DATA_BEGIN


test1_sv48_str:   .string "\"Mismatch on setting satp.MODE=Sv48 in Test Case 1!\""
test2_zeros_str:  .string "\"Mismatch on setting satp.PPN=Zeros in Test Case 2!\""
test2_ones_str:   .string "\"Mismatch on setting satp.PPN=Ones in Test Case 2!\""
test2_walk_str:   .string "\"Mismatch on walking ones in satp.PPN in Test Case 2!\""
test3_zeros_str:  .string "\"Mismatch on setting satp.ASID=Zeros in Test Case 3!\""
test3_ones_str:   .string "\"Mismatch on setting satp.ASID=Ones in Test Case 3!\""
test3_walk_str:   .string "\"Mismatch on walking ones in satp.ASID in Test Case 3!\""

RVTEST_DATA_END
RVTEST_SIG_SETUP
