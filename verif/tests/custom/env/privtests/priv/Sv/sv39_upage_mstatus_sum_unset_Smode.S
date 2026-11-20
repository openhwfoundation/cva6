// --------------------------------------------------------------------------------------------------------------------------------
// Developed by: Umer Shahid, Muhammad Abdullah, Muhammad Zain, Hamza Ali and Muhammad Ahmad
// --------------------------------------------------------------------------------------------------------------------------------
// Test cases are as follows:
// --------------------------------------------------------------------------------------------------------------------------------
// 1. mstatus.SUM unset and PTE.U set for the page at level 2 with RWX Permissions (Read, write, execute page):
//        Then, in S-Mode, the page is accessed --> required: Load-page-fault, Store-page-fault, Fetch Page Fault
// 2. mstatus.SUM unset and PTE.U set for the page at level 2 with X Permission (Execute only page):
//        Then, in S-Mode, the page is accessed --> required: Load-page-fault, Store-page-fault, Fetch Page Fault
// 3. mstatus.SUM unset and PTE.U set for the page at level 2 with R,X Permissions (Read, Execute page):
//        Then, in S-Mode, the page is accessed --> required: Load-page-fault, Store-page-fault, Fetch Page Fault
// 4. mstatus.SUM unset and PTE.U set for the page at level 2 with R,W Permissions (Read, Store page):
//        Then, in S-Mode, the page is accessed --> required: Load-page-fault, Store-page-fault, Fetch Page Fault
// 5. mstatus.SUM unset and PTE.U set for the page at level 2 with R Permission (execute page):
//        Then, in S-Mode, the page is accessed --> required: Load-page-fault, Store-page-fault, Fetch Page Fault
// 6. mstatus.SUM unset and PTE.U set for the page at level 1 with RWX Permissions (Read, write, execute page):
//        Then, in S-Mode, the page is accessed --> required: Load-page-fault, Store-page-fault, Fetch Page Fault
// 7. mstatus.SUM unset and PTE.U set for the page at level 1 with X Permission (Execute only page):
//        Then, in S-Mode, the page is accessed --> required: Load-page-fault, Store-page-fault, Fetch Page Fault
// 8. mstatus.SUM unset and PTE.U set for the page at level 1 with R,X Permissions (Read, Execute page):
//        Then, in S-Mode, the page is accessed --> required: Load-page-fault, Store-page-fault, Fetch Page Fault
// 9. mstatus.SUM unset and PTE.U set for the page at level 1 with R,W Permissions (Read, Store page):
//        Then, in S-Mode, the page is accessed --> required: Load-page-fault, Store-page-fault, Fetch Page Fault
// 10. mstatus.SUM unset and PTE.U set for the page at level 1 with R Permission (execute page):
//        Then, in S-Mode, the page is accessed --> required: Load-page-fault, Store-page-fault, Fetch Page Fault
// 11. mstatus.SUM unset and PTE.U set for the page at level 0 with RWX Permissions (Read, write, execute page):
//        Then, in S-Mode, the page is accessed --> required: Load-page-fault, Store-page-fault, Fetch Page Fault
// 12. mstatus.SUM unset and PTE.U set for the page at level 0 with X Permission (Execute only page):
//        Then, in S-Mode, the page is accessed --> required: Load-page-fault, Store-page-fault, Fetch Page Fault
// 13. mstatus.SUM unset and PTE.U set for the page at level 0 with R,X Permissions (Read, Execute page):
//        Then, in S-Mode, the page is accessed --> required: Load-page-fault, Store-page-fault, Fetch Page Fault
// 14. mstatus.SUM unset and PTE.U set for the page at level 0 with R,W Permissions (Read, Store page):
//        Then, in S-Mode, the page is accessed --> required: Load-page-fault, Store-page-fault, Fetch Page Fault
// 15. mstatus.SUM unset and PTE.U set for the page at level 0 with R Permission (execute page):
//        Then, in S-Mode, the page is accessed --> required: Load-page-fault, Store-page-fault, Fetch Page Fault
//
// Total Expected Faults :: 45
//---------------------------------------------------------------------------------------------------------------------------------

##### START_TEST_CONFIG #####
# REQUIRED_EXTENSIONS: [I, Sv39]
# MARCH: rv64i_zicsr
##### END_TEST_CONFIG #####

#define TEST_FILE "sv39_upage_mstatus_sum_unset_Smode"
#define SIGUPD_COUNT 50
#define TRAP_SIGUPD_COUNT 190
#define rvtest_mtrap_routine
#define rvtest_strap_routine
#define RVTEST_PRIV_TEST
#define SKIP_MEPC

#include "riscv_arch_test.h"

RVTEST_BEGIN

//---------------------------------------------------------------------------------------------------------------------------------
// Test RWX permissions
.macro VERIFICATION_RWX TEST_CASE
  addi a2, a2, 16

  // Test store permission
  \TEST_CASE\()_store:
  sw  a2, 20(a5)
  nop

  // Test load permission
  \TEST_CASE\()_load:
  lw a3, 20(a5)
  nop

  // Test execute permission
  LI(  x4, 0xACCE)            // Store a value which is to be checked in trap handler
  \TEST_CASE\()_exec:
  jalr ra, a5, 0
  nop
.endm

.macro TEST_CASES_RUNNER LOWER_MODE, VA, level, TEST_CASE

  // Adjust offset of VA to point to test region
  .set VA_SHIFT, (\level*9)+12
  LI(a5, (\VA>>VA_SHIFT)<<VA_SHIFT)
  LA(a0, rvtest_data_1)
  slli a0, a0, 64-VA_SHIFT
  srli a0, a0, 64-VA_SHIFT
  add  a5, a5, a0             // Virtual Address

  RVTEST_GOTO_LOWER_MODE \LOWER_MODE

  VERIFICATION_RWX \TEST_CASE

  RVTEST_GOTO_MMODE

  // Signature Update
  RVTEST_SIGUPD(x2, x5, x4, a2, \TEST_CASE\()_store, \TEST_CASE\()_store_str)
  RVTEST_SIGUPD(x2, x5, x4, a3, \TEST_CASE\()_load, \TEST_CASE\()_load_str)
  RVTEST_SIGUPD(x2, x5, x4, a4, \TEST_CASE\()_exec, \TEST_CASE\()_exec_str)
.endm


main:
  LI( a2, 0x800)            // Test signature initialization

//---------------------------------------------------------------------------------------------------------------------------------
//                                   Virtual addresses definition for code and test regions
//---------------------------------------------------------------------------------------------------------------------------------

  // Virtual Address of Test section (rvtest_data_1)
  .set va_data,               0x140802000

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
//                                                    TESTS AT LEVEL 2
//---------------------------------------------------------------------------------------------------------------------------------
//                    1GB PAGE    Region 1 under test at level 2 -- RWX permissions given to the region
//---------------------------------------------------------------------------------------------------------------------------------

  // Test case 1: U bit set | Test in S-Mode | RWX bit set | expected = RWX Fault
  SUPERPAGE_PTE_SETUP_SV39(rvtest_data_1, (PTE_D | PTE_A | PTE_U | PTE_X | PTE_W | PTE_R | PTE_V), va_data, LEVEL2)
  sfence.vma

  TEST_CASES_RUNNER Smode, va_data, LEVEL2, test1

//---------------------------------------------------------------------------------------------------------------------------------
//                    1GB PAGE    Region 2 under test at level 2 -- X permissions given to the region
//---------------------------------------------------------------------------------------------------------------------------------

  // Test case 2: U bit set | Test in S-Mode | X bit set | expected = RWX Fault
  SUPERPAGE_PTE_SETUP_SV39(rvtest_data_1, (PTE_D | PTE_A | PTE_U | PTE_X | PTE_V), va_data, LEVEL2)
  sfence.vma

  TEST_CASES_RUNNER Smode, va_data, LEVEL2, test2

//---------------------------------------------------------------------------------------------------------------------------------
//                    1GB PAGE    Region 3 under test at level 2 -- RX permissions given to the region
//---------------------------------------------------------------------------------------------------------------------------------

  // Test case 3: U bit set | Test in S-Mode | RX bit set | expected = RWX Fault
  SUPERPAGE_PTE_SETUP_SV39(rvtest_data_1, (PTE_D | PTE_A | PTE_U | PTE_R | PTE_X | PTE_V), va_data, LEVEL2)
  sfence.vma

  TEST_CASES_RUNNER Smode, va_data, LEVEL2, test3

//---------------------------------------------------------------------------------------------------------------------------------
//                    1GB PAGE    Region 4 under test at level 2 -- RW permissions given to the region
//---------------------------------------------------------------------------------------------------------------------------------

  // Test case 4: U bit set | Test in S-Mode |  RW bit set | expected = RWX Fault
  SUPERPAGE_PTE_SETUP_SV39(rvtest_data_1, (PTE_D | PTE_A | PTE_U | PTE_R | PTE_W | PTE_V), va_data, LEVEL2)
  sfence.vma

  TEST_CASES_RUNNER Smode, va_data, LEVEL2, test4

//---------------------------------------------------------------------------------------------------------------------------------
//                    1GB PAGE    Region 5 under test at level 2 -- R permissions given to the region
//---------------------------------------------------------------------------------------------------------------------------------

  // Test case 5: U bit set | Test in S-Mode | R bit set | expected = RWX Fault
  SUPERPAGE_PTE_SETUP_SV39(rvtest_data_1, (PTE_D | PTE_A | PTE_U | PTE_R | PTE_V), va_data, LEVEL2)
  sfence.vma

  TEST_CASES_RUNNER Smode, va_data, LEVEL2, test5


//---------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------------------------------------------
//                                                    TESTS AT LEVEL 1
//---------------------------------------------------------------------------------------------------------------------------------
//                    2MB PAGE    Region 1 under test at level 1 -- RWX permissions given to the region
//---------------------------------------------------------------------------------------------------------------------------------

  // Test case 6: U bit set | Test in S-Mode | RWX bit set | expected = RWX Fault
  PTE_SETUP_SV39(rvtest_slvl1_pg_tbl, (PTE_V), va_data, LEVEL2)
  SUPERPAGE_PTE_SETUP_SV39(rvtest_data_1, (PTE_D | PTE_A | PTE_U | PTE_X | PTE_W | PTE_R | PTE_V), va_data, LEVEL1)
  sfence.vma

  TEST_CASES_RUNNER Smode, va_data, LEVEL1, test6

//---------------------------------------------------------------------------------------------------------------------------------
//                    2MB PAGE    Region 2 under test at level 1 -- X permissions given to the region
//---------------------------------------------------------------------------------------------------------------------------------

  // Test case 7: U bit set | Test in S-Mode | X bit set | expected = RWX Fault
  PTE_SETUP_SV39(rvtest_slvl1_pg_tbl, (PTE_V), va_data, LEVEL2)
  SUPERPAGE_PTE_SETUP_SV39(rvtest_data_1, (PTE_D | PTE_A | PTE_U | PTE_X | PTE_V), va_data, LEVEL1)
  sfence.vma

  TEST_CASES_RUNNER Smode, va_data, LEVEL1, test7

//---------------------------------------------------------------------------------------------------------------------------------
//                    2MB PAGE    Region 3 under test at level 1 -- RX permissions given to the region
//---------------------------------------------------------------------------------------------------------------------------------

  // Test case 8: U bit set | Test in S-Mode | RX bit set | expected = RWX Fault
  PTE_SETUP_SV39(rvtest_slvl1_pg_tbl, (PTE_V), va_data, LEVEL2)
  SUPERPAGE_PTE_SETUP_SV39(rvtest_data_1, (PTE_D | PTE_A | PTE_U | PTE_R | PTE_X | PTE_V), va_data, LEVEL1)
  sfence.vma

  TEST_CASES_RUNNER Smode, va_data, LEVEL1, test8

//---------------------------------------------------------------------------------------------------------------------------------
//                    2MB PAGE    Region 4 under test at level 1 -- RW permissions given to the region
//---------------------------------------------------------------------------------------------------------------------------------

  // Test case 9: U bit set | Test in S-Mode |  RW bit set | expected = RWX Fault
  PTE_SETUP_SV39(rvtest_slvl1_pg_tbl, (PTE_V), va_data, LEVEL2)
  SUPERPAGE_PTE_SETUP_SV39(rvtest_data_1, (PTE_D | PTE_A | PTE_U | PTE_R | PTE_W | PTE_V), va_data, LEVEL1)
  sfence.vma

  TEST_CASES_RUNNER Smode, va_data, LEVEL1, test9

//---------------------------------------------------------------------------------------------------------------------------------
//                    2MB PAGE    Region 5 under test at level 1 -- R permissions given to the region
//---------------------------------------------------------------------------------------------------------------------------------

  // Test case 10: U bit set | Test in S-Mode | R bit set | expected = RWX Fault
  PTE_SETUP_SV39(rvtest_slvl1_pg_tbl, (PTE_V), va_data, LEVEL2)
  SUPERPAGE_PTE_SETUP_SV39(rvtest_data_1, (PTE_D | PTE_A | PTE_U | PTE_R | PTE_V), va_data, LEVEL1)
  sfence.vma

  TEST_CASES_RUNNER Smode, va_data, LEVEL1, test10


//---------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------------------------------------------
//                                                    TESTS AT LEVEL 0
//---------------------------------------------------------------------------------------------------------------------------------
//                    4KB PAGE    Region 1 under test at level 0 -- RWX permissions given to the region
//---------------------------------------------------------------------------------------------------------------------------------

  // Test case 11: U bit set | Test in S-Mode | RWX bit set | expected = RWX Fault
  PTE_SETUP_SV39(rvtest_slvl1_pg_tbl, (PTE_V), va_data, LEVEL2)
  PTE_SETUP_SV39(rvtest_slvl0_pg_tbl, (PTE_V), va_data, LEVEL1)
  PTE_SETUP_SV39(rvtest_data_1, (PTE_D | PTE_A | PTE_U | PTE_X | PTE_W | PTE_R | PTE_V), va_data, LEVEL0)
  sfence.vma

  TEST_CASES_RUNNER Smode, va_data, LEVEL0, test11

//---------------------------------------------------------------------------------------------------------------------------------
//                    4KB PAGE    Region 2 under test at level 0 -- X permissions given to the region
//---------------------------------------------------------------------------------------------------------------------------------

  // Test case 12: U bit set | Test in S-Mode | X bit set | expected = RWX Fault
  PTE_SETUP_SV39(rvtest_slvl1_pg_tbl, (PTE_V), va_data, LEVEL2)
  PTE_SETUP_SV39(rvtest_slvl0_pg_tbl, (PTE_V), va_data, LEVEL1)
  PTE_SETUP_SV39(rvtest_data_1, (PTE_D | PTE_A | PTE_U | PTE_X | PTE_V), va_data, LEVEL0)
  sfence.vma

  TEST_CASES_RUNNER Smode, va_data, LEVEL0, test12

//---------------------------------------------------------------------------------------------------------------------------------
//                    4KB PAGE    Region 3 under test at level 0 -- RX permissions given to the region
//---------------------------------------------------------------------------------------------------------------------------------

  // Test case 13: U bit set | Test in S-Mode | RX bit set | expected = RWX Fault
  PTE_SETUP_SV39(rvtest_slvl1_pg_tbl, (PTE_V), va_data, LEVEL2)
  PTE_SETUP_SV39(rvtest_slvl0_pg_tbl, (PTE_V), va_data, LEVEL1)
  PTE_SETUP_SV39(rvtest_data_1, (PTE_D | PTE_A | PTE_U | PTE_R | PTE_X | PTE_V), va_data, LEVEL0)
  sfence.vma

  TEST_CASES_RUNNER Smode, va_data, LEVEL0, test13

//---------------------------------------------------------------------------------------------------------------------------------
//                    4KB PAGE    Region 4 under test at level 0 -- RW permissions given to the region
//---------------------------------------------------------------------------------------------------------------------------------

  // Test case 14: U bit set | Test in S-Mode | RW bit set | expected = RWX Fault
  PTE_SETUP_SV39(rvtest_slvl1_pg_tbl, (PTE_V), va_data, LEVEL2)
  PTE_SETUP_SV39(rvtest_slvl0_pg_tbl, (PTE_V), va_data, LEVEL1)
  PTE_SETUP_SV39(rvtest_data_1, (PTE_D | PTE_A | PTE_U | PTE_R | PTE_W | PTE_V), va_data, LEVEL0)
  sfence.vma

  TEST_CASES_RUNNER Smode, va_data, LEVEL0, test14

//---------------------------------------------------------------------------------------------------------------------------------
//                    4KB PAGE    Region 5 under test at level 0 -- R permissions given to the region
//---------------------------------------------------------------------------------------------------------------------------------

  // Test case 15: U bit set | Test in S-Mode | R bit set | expected = RWX Fault
  PTE_SETUP_SV39(rvtest_slvl1_pg_tbl, (PTE_V), va_data, LEVEL2)
  PTE_SETUP_SV39(rvtest_slvl0_pg_tbl, (PTE_V), va_data, LEVEL1)
  PTE_SETUP_SV39(rvtest_data_1, (PTE_D | PTE_A | PTE_U | PTE_R | PTE_V), va_data, LEVEL0)
  sfence.vma

  TEST_CASES_RUNNER Smode, va_data, LEVEL0, test15


//---------------------------------------------------------------------------------------------------------------------------------
RVTEST_CODE_END
RVTEST_DATA_BEGIN

//---------------------------------------------------------------------------------------------------------------------------------
//                                            PHYSICAL ADDRESS REGION FOR TESTING
//---------------------------------------------------------------------------------------------------------------------------------
// Physical Address region under testing for LEVEL 0, 1 and 2
.align 12
rvtest_data_1:
  nop
  addi a4, a2, 4
  jr ra
  nop
  .word 0xbeefcaf1          // Random word
  .word 0xbeefcaf2          // Random word
  nop
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
test1_exec_str:  .string "\"Mismatch during jalr in Test Case 1!\""
test2_store_str: .string "\"Mismatch during sw in Test Case 2!\""
test2_load_str:  .string "\"Mismatch during lw in Test Case 2!\""
test2_exec_str:  .string "\"Mismatch during jalr in Test Case 2!\""
test3_store_str: .string "\"Mismatch during sw in Test Case 3!\""
test3_load_str:  .string "\"Mismatch during lw in Test Case 3!\""
test3_exec_str:  .string "\"Mismatch during jalr in Test Case 3!\""
test4_store_str: .string "\"Mismatch during sw in Test Case 4!\""
test4_load_str:  .string "\"Mismatch during lw in Test Case 4!\""
test4_exec_str:  .string "\"Mismatch during jalr in Test Case 4!\""
test5_store_str: .string "\"Mismatch during sw in Test Case 5!\""
test5_load_str:  .string "\"Mismatch during lw in Test Case 5!\""
test5_exec_str:  .string "\"Mismatch during jalr in Test Case 5!\""
test6_store_str: .string "\"Mismatch during sw in Test Case 6!\""
test6_load_str:  .string "\"Mismatch during lw in Test Case 6!\""
test6_exec_str:  .string "\"Mismatch during jalr in Test Case 6!\""
test7_store_str: .string "\"Mismatch during sw in Test Case 7!\""
test7_load_str:  .string "\"Mismatch during lw in Test Case 7!\""
test7_exec_str:  .string "\"Mismatch during jalr in Test Case 7!\""
test8_store_str: .string "\"Mismatch during sw in Test Case 8!\""
test8_load_str:  .string "\"Mismatch during lw in Test Case 8!\""
test8_exec_str:  .string "\"Mismatch during jalr in Test Case 8!\""
test9_store_str: .string "\"Mismatch during sw in Test Case 9!\""
test9_load_str:  .string "\"Mismatch during lw in Test Case 9!\""
test9_exec_str:  .string "\"Mismatch during jalr in Test Case 9!\""
test10_store_str: .string "\"Mismatch during sw in Test Case 10!\""
test10_load_str:  .string "\"Mismatch during lw in Test Case 10!\""
test10_exec_str:  .string "\"Mismatch during jalr in Test Case 10!\""
test11_store_str: .string "\"Mismatch during sw in Test Case 11!\""
test11_load_str:  .string "\"Mismatch during lw in Test Case 11!\""
test11_exec_str:  .string "\"Mismatch during jalr in Test Case 11!\""
test12_store_str: .string "\"Mismatch during sw in Test Case 12!\""
test12_load_str:  .string "\"Mismatch during lw in Test Case 12!\""
test12_exec_str:  .string "\"Mismatch during jalr in Test Case 12!\""
test13_store_str: .string "\"Mismatch during sw in Test Case 13!\""
test13_load_str:  .string "\"Mismatch during lw in Test Case 13!\""
test13_exec_str:  .string "\"Mismatch during jalr in Test Case 13!\""
test14_store_str: .string "\"Mismatch during sw in Test Case 14!\""
test14_load_str:  .string "\"Mismatch during lw in Test Case 14!\""
test14_exec_str:  .string "\"Mismatch during jalr in Test Case 14!\""
test15_store_str: .string "\"Mismatch during sw in Test Case 15!\""
test15_load_str:  .string "\"Mismatch during lw in Test Case 15!\""
test15_exec_str:  .string "\"Mismatch during jalr in Test Case 15!\""

RVTEST_DATA_END
RVTEST_SIG_SETUP
