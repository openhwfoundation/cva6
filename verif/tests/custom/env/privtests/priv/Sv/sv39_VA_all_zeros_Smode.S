// --------------------------------------------------------------------------------------------------------------------------------
// Developed by: Umer Shahid, Muhammad Zain, Muhammad Abdullah, Hamza Ali, Muhammad Ahmad
// --------------------------------------------------------------------------------------------------------------------------------
// Test cases are as follows:
// --------------------------------------------------------------------------------------------------------------------------------
// 1. Perform Load & Store at virtual address 0x0
// 2. Perform Execute at virtual address 0x0
//
// Total Expected Faults :: 0
// --------------------------------------------------------------------------------------------------------------------------------

##### START_TEST_CONFIG #####
# REQUIRED_EXTENSIONS: [I, Sv39]
# MARCH: rv64i_zicsr
##### END_TEST_CONFIG #####

#define TEST_FILE "sv39_VA_all_zeros_Smode.S"
#define SIGUPD_COUNT 10
#define TRAP_SIGUPD_COUNT 10
#define rvtest_mtrap_routine
#define rvtest_strap_routine
#define RVTEST_PRIV_TEST
#define SKIP_MEPC

#include "riscv_arch_test.h"

RVTEST_BEGIN

//---------------------------------------------------------------------------------------------------------------------------------
// Test RW Permissions
.macro TEST_CASES_RUNNER_RW LOWER_MODE, VA, level, TEST_CASE

  RVTEST_GOTO_LOWER_MODE \LOWER_MODE

  LI(a5, \VA)
  addi a2, a2, 16

  // Test store permission
  \TEST_CASE\()_store:
  sw  a2, 0(a5)
  nop

  // Test load permission
  \TEST_CASE\()_load:
  lw  a3, 0(a5)
  nop

  RVTEST_GOTO_MMODE

  // Signature Update
  RVTEST_SIGUPD(x2, x5, x4, a2, \TEST_CASE\()_store, \TEST_CASE\()_store_str)
  RVTEST_SIGUPD(x2, x5, x4, a3, \TEST_CASE\()_load, \TEST_CASE\()_load_str)
.endm

// Test X Permission
.macro TEST_CASES_RUNNER_X LOWER_MODE, VA, level, TEST_CASE

  RVTEST_GOTO_LOWER_MODE \LOWER_MODE

  LI(  a5, \VA)
  LI(  x4, 0xACCE)          // Store a value which is to be checked in trap handler
  \TEST_CASE\()_exec:
  jalr ra, a5, 0
  nop

  RVTEST_GOTO_MMODE

  // Signature Update
  RVTEST_SIGUPD(x2, x5, x4, a4, \TEST_CASE\()_exec, \TEST_CASE\()_exec_str)
.endm


main:
  li a2, 0x12               // Test signature initialization

//---------------------------------------------------------------------------------------------------------------------------------
//                                   Virtual addresses definition for code and test regions
//---------------------------------------------------------------------------------------------------------------------------------

  // Virtual Address of Test section (rvtest_data_1)
  .set va_data,               0x0000000000000000

  // Virtual Address for code region
  .set va_rvtest_code_begin,  0x180000000


  // PTE setup for Code Region
  SUPERPAGE_PTE_SETUP_SV39(rvtest_code_begin, (PTE_D | PTE_A | PTE_X | PTE_R | PTE_V), va_rvtest_code_begin, LEVEL2)
  sfence.vma

  // Save area setup for code region
  csrr a0, mscratch
  SAVE_AREA_SETUP(va_rvtest_code_begin, rvtest_code_begin, code)

//---------------------------------------------------------------------------------------------------------------------------------
//                                               Test Cases Start from here
//---------------------------------------------------------------------------------------------------------------------------------

  SATP_SETUP_RV64(sv39)                                                  // Set SATP for virtualization
  sfence.vma                                                             // Flush TLB

//---------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------------------------------------------
//                                                    TESTS AT LEVEL 0
//---------------------------------------------------------------------------------------------------------------------------------
//                    4KB PAGE    Region 1 under test at level 0 -- RW permissions given to the region
//---------------------------------------------------------------------------------------------------------------------------------

  // Test case 1: Test in S-Mode | RW bit set | expected = successful page access
  PTE_SETUP_SV39(rvtest_slvl1_pg_tbl, (PTE_V), va_data, LEVEL2)
  PTE_SETUP_SV39(rvtest_slvl0_pg_tbl, (PTE_V), va_data, LEVEL1)
  PTE_SETUP_SV39(rvtest_data_1_l0_rw, (PTE_D | PTE_A | PTE_W | PTE_R | PTE_V), va_data, LEVEL0)
  sfence.vma

  TEST_CASES_RUNNER_RW Smode, va_data, LEVEL0, test1

//---------------------------------------------------------------------------------------------------------------------------------
//                    4KB PAGE    Region 1 under test at level 0 -- X permission given to the region
//---------------------------------------------------------------------------------------------------------------------------------

  // Test case 2: Test in S-Mode | X bit set | expected = successful page access
  PTE_SETUP_SV39(rvtest_slvl1_pg_tbl, (PTE_V), va_data, LEVEL2)
  PTE_SETUP_SV39(rvtest_slvl0_pg_tbl, (PTE_V), va_data, LEVEL1)
  PTE_SETUP_SV39(rvtest_data_1_l0_x, (PTE_D | PTE_A | PTE_X | PTE_V), va_data, LEVEL0)
  sfence.vma

  TEST_CASES_RUNNER_X Smode, va_data, LEVEL0, test2


//---------------------------------------------------------------------------------------------------------------------------------
RVTEST_CODE_END
RVTEST_DATA_BEGIN

//---------------------------------------------------------------------------------------------------------------------------------
//                                            PHYSICAL ADDRESS REGIONS FOR TESTING
//---------------------------------------------------------------------------------------------------------------------------------
// This region will be used to Store and then Load back from the first word
.align 12
rvtest_data_1_l0_rw:
  .word 0xbeefcaf1          // Random word
  .word 0xbeefcaf2          // Random word
  .skip ((1 << 10) - 3)*4
  .word 0xbeefcaf3

// This region will be used to execute its first instruction
.align 12
rvtest_data_1_l0_x:
  nop
  addi a4, a2, REGWIDTH
  jr ra
  nop
  .word 0xbeefcaf1          // Random word
  .word 0xbeefcaf2          // Random word
  .skip ((1 << 10) - 7)*4
  jr ra

//---------------------------------------------------------------------------------------------------------------------------------

// Page Tables
.align 12
rvtest_slvl0_pg_tbl:
    .skip(4096)
rvtest_slvl1_pg_tbl:
    .skip(4096)


test1_store_str: .string "\"Mismatch during sw in Test Case 1!\""
test1_load_str:  .string "\"Mismatch during lw in Test Case 1!\""
test2_exec_str:  .string "\"Mismatch during jalr in Test Case 2!\""

RVTEST_DATA_END
RVTEST_SIG_SETUP
