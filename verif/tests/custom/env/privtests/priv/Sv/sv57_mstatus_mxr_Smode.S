// --------------------------------------------------------------------------------------------------------------------------------
// Developed by: Umer Shahid & Muhammad Zain
// --------------------------------------------------------------------------------------------------------------------------------
// Test cases are as follows:
// --------------------------------------------------------------------------------------------------------------------------------
// 1. mstatus.MXR is unset and X bit is set for the page at level 4:
//        Then, in S-Mode, the page is accessed --> required: Load Page Fault, Store page fault
// 2. mstatus.MXR is set and X bit is set for the page at level 4:
//      Then, in S-Mode, the page is accessed --> required: Store page fault
// 3. mstatus.MXR is unset and X bit is set for the page at level 3:
//        Then, in S-Mode, the page is accessed --> required: Load Page Fault, Store page fault
// 4. mstatus.MXR is set and X bit is set for the page at level 3:
//      Then, in S-Mode, the page is accessed --> required: Store page fault
// 5. mstatus.MXR is unset and X bit is set for the page at level 2:
//        Then, in S-Mode, the page is accessed --> required: Load Page Fault, Store page fault
// 6. mstatus.MXR is set and X bit is set for the page at level 2:
//      Then, in S-Mode, the page is accessed --> required: Store page fault
// 7. mstatus.MXR is unset and X bit is set for the page at level 1:
//        Then, in S-Mode, the page is accessed --> required: Load Page Fault, Store page fault
// 8. mstatus.MXR is set and X bit is set for the page at level 1:
//      Then, in S-Mode, the page is accessed --> required: Store page fault
// 9. mstatus.MXR is unset and X bit is set for the page at level 0:
//        Then, in S-Mode, the page is accessed --> required: Load Page Fault, Store page fault
// 10. mstatus.MXR is set and X bit is set for the page at level 0:
//      Then, in S-Mode, the page is accessed --> required: Store page fault
//
// Total Expected Faults :: 15
// --------------------------------------------------------------------------------------------------------------------------------

##### START_TEST_CONFIG #####
# REQUIRED_EXTENSIONS: [I, Sv57]
# MARCH: rv64i_zicsr
##### END_TEST_CONFIG #####

#define TEST_FILE "sv57_mstatus_mxr_Smode.S"
#define SIGUPD_COUNT 35
#define TRAP_SIGUPD_COUNT 70
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
  LI( a2, 0x800)              // Test signature initialization

//---------------------------------------------------------------------------------------------------------------------------------
//                                   Virtual addresses definition for code and test regions
//---------------------------------------------------------------------------------------------------------------------------------

  // Virtual Address of Test section (rvtest_data_1)
  .set va_data,               0x07028500403000

  // Virtual Address for code region
  .set va_rvtest_code_begin,  0x03000080000000


  // PTE setup for Code Region
  SUPERPAGE_PTE_SETUP_SV57(rvtest_code_begin, (PTE_D | PTE_A | PTE_X | PTE_R | PTE_V), va_rvtest_code_begin, LEVEL4)
  sfence.vma

  // Save area setup for code region
  csrr a0, mscratch
  SAVE_AREA_SETUP(va_rvtest_code_begin, rvtest_code_begin, code)

//---------------------------------------------------------------------------------------------------------------------------------
//                                               Test Cases Start from here
//---------------------------------------------------------------------------------------------------------------------------------

  SATP_SETUP_RV64(sv57)                                                  // Set SATP for virtualization
  sfence.vma                                                             // Flush TLB


//---------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------------------------------------------
//                                                  TESTS AT LEVEL 4
//---------------------------------------------------------------------------------------------------------------------------------
//                  256TB PAGE  Region 1 under test at level 4 -- RWX permissions given to the region
//---------------------------------------------------------------------------------------------------------------------------------

  // Test case 1: X bit set and MXR bit unset | Test in S-Mode | X bit set | expected = Store, load page fault
  SUPERPAGE_PTE_SETUP_SV57(rvtest_data_1, (PTE_D | PTE_A | PTE_X | PTE_V ), va_data, LEVEL4)
  sfence.vma

  LI(   t0, MSTATUS_MXR)
  CSRC( mstatus, t0)                                                             // Clear mstatus.MXR
  TEST_CASES_RUNNER Smode, va_data, LEVEL4, test1

//---------------------------------------------------------------------------------------------------------------------------------
//                  256TB PAGE  Region 1 under test at level 4 -- RWX permissions given to the region
//---------------------------------------------------------------------------------------------------------------------------------

  // Test case 2: X bit set and MXR bit set | Test in S-Mode | X bit set | expected = store page fault
  SUPERPAGE_PTE_SETUP_SV57(rvtest_data_1, (PTE_D | PTE_A | PTE_X | PTE_V), va_data, LEVEL4)
  sfence.vma

  LI(   t0, MSTATUS_MXR)
  CSRS( mstatus, t0)                                                             // Set mstatus.MXR
  TEST_CASES_RUNNER Smode, va_data, LEVEL4, test2


//---------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------------------------------------------
//                                                  TESTS AT LEVEL 3
//---------------------------------------------------------------------------------------------------------------------------------
//                  512GB PAGE  Region 1 under test at level 3 -- RWX permissions given to the region
//---------------------------------------------------------------------------------------------------------------------------------

  // Test case 3: X bit set and MXR bit unset | Test in S-Mode | X bit set | expected = Store, load page fault
  PTE_SETUP_SV57(rvtest_slvl3_pg_tbl, (PTE_V), va_data, LEVEL4)
  SUPERPAGE_PTE_SETUP_SV57(rvtest_data_1, (PTE_D | PTE_A | PTE_X | PTE_V ), va_data, LEVEL3)
  sfence.vma

  LI(   t0, MSTATUS_MXR)
  CSRC( mstatus, t0)                                                             // Clear mstatus.MXR
  TEST_CASES_RUNNER Smode, va_data, LEVEL3, test3

//---------------------------------------------------------------------------------------------------------------------------------
//                  512GB PAGE  Region 1 under test at level 3 -- RWX permissions given to the region
//---------------------------------------------------------------------------------------------------------------------------------

  // Test case 4: X bit set and MXR bit set | Test in S-Mode | X bit set | expected = store page fault
  PTE_SETUP_SV57(rvtest_slvl3_pg_tbl, (PTE_V), va_data, LEVEL4)
  SUPERPAGE_PTE_SETUP_SV57(rvtest_data_1, (PTE_D | PTE_A | PTE_X | PTE_V), va_data, LEVEL3)
  sfence.vma

  LI(   t0, MSTATUS_MXR)
  CSRS( mstatus, t0)                                                             // Set mstatus.MXR
  TEST_CASES_RUNNER Smode, va_data, LEVEL3, test4


//---------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------------------------------------------
//                                                  TESTS AT LEVEL 2
//---------------------------------------------------------------------------------------------------------------------------------
//                  1GB PAGE    Region 1 under test at level 2 -- X permissions given to the region
//---------------------------------------------------------------------------------------------------------------------------------

  // Test case 5: X bit set and MXR bit unset | Test in S-Mode | X bit set | expected = Store, load page fault
  PTE_SETUP_SV57(rvtest_slvl3_pg_tbl, (PTE_V), va_data, LEVEL4)
  PTE_SETUP_SV57(rvtest_slvl2_pg_tbl, (PTE_V), va_data, LEVEL3)
  SUPERPAGE_PTE_SETUP_SV57(rvtest_data_1, (PTE_D | PTE_A | PTE_X | PTE_V), va_data, LEVEL2)
  sfence.vma

  LI(   t0, MSTATUS_MXR)
  CSRC( mstatus, t0)                                                             // Clear mstatus.MXR
  TEST_CASES_RUNNER Smode, va_data, LEVEL2, test5

//---------------------------------------------------------------------------------------------------------------------------------
//                  1GB PAGE    Region 1 under test at level 2 -- X permissions given to the region
//---------------------------------------------------------------------------------------------------------------------------------

  // Test case 6: X bit set and MXR bit set | Test in S-Mode | X bit set | expected = store page fault
  PTE_SETUP_SV57(rvtest_slvl3_pg_tbl, (PTE_V), va_data, LEVEL4)
  PTE_SETUP_SV57(rvtest_slvl2_pg_tbl, (PTE_V), va_data, LEVEL3)
  SUPERPAGE_PTE_SETUP_SV57(rvtest_data_1, (PTE_D | PTE_A | PTE_X | PTE_V), va_data, LEVEL2)
  sfence.vma

  LI(   t0, MSTATUS_MXR)
  CSRS( mstatus, t0)                                                             // Set mstatus.MXR
  TEST_CASES_RUNNER Smode, va_data, LEVEL2, test6


//---------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------------------------------------------
//                                                  TESTS AT LEVEL 1
//---------------------------------------------------------------------------------------------------------------------------------
//                  2MB PAGE    Region 1 under test at level 1 -- X permissions given to the region
//---------------------------------------------------------------------------------------------------------------------------------

  // Test case 7: X bit set and MXR bit unset | Test in S-Mode | X bit set | expected = store, load page fault
  PTE_SETUP_SV57(rvtest_slvl3_pg_tbl, (PTE_V), va_data, LEVEL4)
  PTE_SETUP_SV57(rvtest_slvl2_pg_tbl, (PTE_V), va_data, LEVEL3)
  PTE_SETUP_SV57(rvtest_slvl1_pg_tbl, (PTE_V), va_data, LEVEL2)
  SUPERPAGE_PTE_SETUP_SV57(rvtest_data_1, (PTE_D | PTE_A | PTE_X | PTE_V), va_data, LEVEL1)
  sfence.vma

  LI(   t0, MSTATUS_MXR)
  CSRC( mstatus, t0)                                                             // Clear mstatus.MXR
  TEST_CASES_RUNNER Smode, va_data, LEVEL1, test7

//---------------------------------------------------------------------------------------------------------------------------------
//                  2MB PAGE    Region 1 under test at level 1 -- RWX permissions given to the region
//---------------------------------------------------------------------------------------------------------------------------------

  // Test case 8: X bit set and MXR bit set | Test in S-Mode | X bit set | expected = store page fault
  PTE_SETUP_SV57(rvtest_slvl3_pg_tbl, (PTE_V), va_data, LEVEL4)
  PTE_SETUP_SV57(rvtest_slvl2_pg_tbl, (PTE_V), va_data, LEVEL3)
  PTE_SETUP_SV57(rvtest_slvl1_pg_tbl, (PTE_V), va_data, LEVEL2)
  SUPERPAGE_PTE_SETUP_SV57(rvtest_data_1, (PTE_D | PTE_A | PTE_X | PTE_V), va_data, LEVEL1)
  sfence.vma

  LI(   t0, MSTATUS_MXR)
  CSRS( mstatus, t0)                                                             // Set mstatus.MXR
  TEST_CASES_RUNNER Smode, va_data, LEVEL1, test8


//---------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------------------------------------------
//                                                  TESTS AT LEVEL 0
//---------------------------------------------------------------------------------------------------------------------------------
//                  4KB PAGE    Region 1 under test at level 0 -- X permissions given to the region
//---------------------------------------------------------------------------------------------------------------------------------

  // Test case 9: X bit set and MXR bit unset | Test in S-Mode | X bit set | expected = store, load page fault
  PTE_SETUP_SV57(rvtest_slvl3_pg_tbl, (PTE_V), va_data, LEVEL4)
  PTE_SETUP_SV57(rvtest_slvl2_pg_tbl, (PTE_V), va_data, LEVEL3)
  PTE_SETUP_SV57(rvtest_slvl1_pg_tbl, (PTE_V), va_data, LEVEL2)
  PTE_SETUP_SV57(rvtest_slvl0_pg_tbl, (PTE_V), va_data, LEVEL1)
  PTE_SETUP_SV57(rvtest_data_1, (PTE_D | PTE_A | PTE_X | PTE_V), va_data, LEVEL0)
  sfence.vma

  LI(   t0, MSTATUS_MXR)
  CSRC( mstatus, t0)                                                             // Clear mstatus.MXR
  TEST_CASES_RUNNER Smode, va_data, LEVEL0, test9

//---------------------------------------------------------------------------------------------------------------------------------
//                  4KB PAGE    Region 1 under test at level 0 -- X permissions given to the region
//---------------------------------------------------------------------------------------------------------------------------------

  // Test case 10: X bit set and MXR bit set | Test in S-Mode | X bit set | expected = store page fault
  PTE_SETUP_SV57(rvtest_slvl3_pg_tbl, (PTE_V), va_data, LEVEL4)
  PTE_SETUP_SV57(rvtest_slvl2_pg_tbl, (PTE_V), va_data, LEVEL3)
  PTE_SETUP_SV57(rvtest_slvl1_pg_tbl, (PTE_V), va_data, LEVEL2)
  PTE_SETUP_SV57(rvtest_slvl0_pg_tbl, (PTE_V), va_data, LEVEL1)
  PTE_SETUP_SV57(rvtest_data_1, (PTE_D | PTE_A | PTE_X | PTE_V), va_data, LEVEL0)
  sfence.vma

  LI(   t0, MSTATUS_MXR)
  CSRS( mstatus, t0)                                                             // Set mstatus.MXR
  TEST_CASES_RUNNER Smode, va_data, LEVEL0, test10


//---------------------------------------------------------------------------------------------------------------------------------
RVTEST_CODE_END
RVTEST_DATA_BEGIN

//---------------------------------------------------------------------------------------------------------------------------------
//                                            PHYSICAL ADDRESS REGION FOR TESTING
//---------------------------------------------------------------------------------------------------------------------------------
// Physical Address region under testing for LEVEL 0, 1, 2, 3 and 4
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
rvtest_slvl2_pg_tbl:
    .skip(4096)
rvtest_slvl3_pg_tbl:
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

RVTEST_DATA_END
RVTEST_SIG_SETUP
