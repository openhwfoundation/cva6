// --------------------------------------------------------------------------------------------------------------------------------
// Developed by: Umer Shahid, Muhammad Zain, Muhammad Abdullah, Hamza Ali and Muhammad Ahmad
// --------------------------------------------------------------------------------------------------------------------------------
// Test cases are as follows:
// --------------------------------------------------------------------------------------------------------------------------------
// 1. PTE.G set for the page at level 2:
//      Then, in U-Mode, the page is accessed --> required: Successful page table walk
//      sfence.vma with ASID flushes TLB entries for that ASID, keeping global (G=1) entries intact.
//      Since the page is global, it remains accessible without a new page table walk on second access.
// 2. PTE.G set for the page at level 1:
//      Then, in U-Mode, the page is accessed --> required: Successful page table walk
//      sfence.vma with ASID flushes TLB entries for that ASID, keeping global (G=1) entries intact.
//      Since the page is global, it remains accessible without a new page table walk on second access.
// 3. PTE.G set for the page at level 0:
//      Then, in U-Mode, the page is accessed --> required: Successful page table walk
//      sfence.vma with ASID flushes TLB entries for that ASID, keeping global (G=1) entries intact.
//      Since the page is global, it remains accessible without a new page table walk on second access.
//
// NOTE: ACTs can't check if a page table walk occurred. This test only makes sure that the second access
//       succeeds after invalidating the TLB.
//
// Total Expected Faults :: 0
//---------------------------------------------------------------------------------------------------------------------------------

##### START_TEST_CONFIG #####
# REQUIRED_EXTENSIONS: [I, Sv39]
# MARCH: rv64i_zicsr
##### END_TEST_CONFIG #####

#define TEST_FILE "sv39_global_pte_Umode.S"
#define SIGUPD_COUNT 25
#define TRAP_SIGUPD_COUNT 10
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
  SUPERPAGE_PTE_SETUP_SV39(rvtest_code_begin, (PTE_D | PTE_A | PTE_U | PTE_X | PTE_R | PTE_V), va_rvtest_code_begin, LEVEL2)
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

  // Test case 1: Test in U-Mode | G bit set | expected = successful page access
  SUPERPAGE_PTE_SETUP_SV39(rvtest_data_1, (PTE_D | PTE_A | PTE_G | PTE_U | PTE_X | PTE_W | PTE_R | PTE_V), va_data, LEVEL2)
  sfence.vma

  TEST_CASES_RUNNER Umode, va_data, LEVEL2, test1_access1

  CSRR( t0, satp)                                          // Extract ASID (Sv39, ASID is in bits 59:44 of satp)
  slli  t0, t0, 4
  srli  t0, t0, 48
  sfence.vma x0, t0                                        // Invalidate TLB entries for the ASID (Global entries remain valid)

  TEST_CASES_RUNNER Umode, va_data, LEVEL2, test1_access2  // No pagetable walk, as the PTE is not invalidated by sfence.vma

//---------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------------------------------------------
//                                                    TESTS AT LEVEL 1
//---------------------------------------------------------------------------------------------------------------------------------
//                    2MB PAGE    Region 1 under test at level 1 -- RWX permissions given to the region
//---------------------------------------------------------------------------------------------------------------------------------

  // Test case 2: Test in U-Mode | G bit set | expected = successful page access
  PTE_SETUP_SV39(rvtest_slvl1_pg_tbl, (PTE_V), va_data, LEVEL2)
  SUPERPAGE_PTE_SETUP_SV39(rvtest_data_1, (PTE_D | PTE_A | PTE_G | PTE_U | PTE_X | PTE_W | PTE_R | PTE_V), va_data, LEVEL1)
  sfence.vma

  TEST_CASES_RUNNER Umode, va_data, LEVEL1, test2_access1

  CSRR( t0, satp)                                          // Extract ASID (Sv39, ASID is in bits 59:44 of satp)
  slli  t0, t0, 4
  srli  t0, t0, 48
  sfence.vma x0, t0                                        // Invalidate TLB entries for the ASID (Global entries remain valid)

  TEST_CASES_RUNNER Umode, va_data, LEVEL1, test2_access2  // No pagetable walk, as the PTE is not invalidated by sfence.vma

//---------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------------------------------------------
//                                                    TESTS AT LEVEL 0
//---------------------------------------------------------------------------------------------------------------------------------
//                    2MB PAGE    Region 1 under test at level 0 -- RWX permissions given to the region
//---------------------------------------------------------------------------------------------------------------------------------

  // Test case 3: Test in U-Mode | G bit set | expected = successful page access
  PTE_SETUP_SV39(rvtest_slvl1_pg_tbl, (PTE_V), va_data, LEVEL2)
  PTE_SETUP_SV39(rvtest_slvl0_pg_tbl, (PTE_V), va_data, LEVEL1)
  PTE_SETUP_SV39(rvtest_data_1, (PTE_D | PTE_A | PTE_G | PTE_U | PTE_X | PTE_W | PTE_R | PTE_V), va_data, LEVEL0)
  sfence.vma

  TEST_CASES_RUNNER Umode, va_data, LEVEL0, test3_access1

  CSRR( t0, satp)                                          // Extract ASID (Sv39, ASID is in bits 59:44 of satp)
  slli  t0, t0, 4
  srli  t0, t0, 48
  sfence.vma x0, t0                                        // Invalidate TLB entries for the ASID (Global entries remain valid)

  TEST_CASES_RUNNER Umode, va_data, LEVEL0, test3_access2  // No pagetable walk, as the PTE is not invalidated by sfence.vma


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


test1_access1_store_str: .string "\"Mismatch during sw in Test Case 1, Access 1!\""
test1_access1_load_str:  .string "\"Mismatch during lw in Test Case 1, Access 1!\""
test1_access1_exec_str:  .string "\"Mismatch during jalr in Test Case 1, Access 1!\""
test1_access2_store_str: .string "\"Mismatch during sw in Test Case 1, Access 2!\""
test1_access2_load_str:  .string "\"Mismatch during lw in Test Case 1, Access 2!\""
test1_access2_exec_str:  .string "\"Mismatch during jalr in Test Case 1, Access 2!\""
test2_access1_store_str: .string "\"Mismatch during sw in Test Case 2, Access 1!\""
test2_access1_load_str:  .string "\"Mismatch during lw in Test Case 2, Access 1!\""
test2_access1_exec_str:  .string "\"Mismatch during jalr in Test Case 2, Access 1!\""
test2_access2_store_str: .string "\"Mismatch during sw in Test Case 2, Access 2!\""
test2_access2_load_str:  .string "\"Mismatch during lw in Test Case 2, Access 2!\""
test2_access2_exec_str:  .string "\"Mismatch during jalr in Test Case 2, Access 2!\""
test3_access1_store_str: .string "\"Mismatch during sw in Test Case 3, Access 1!\""
test3_access1_load_str:  .string "\"Mismatch during lw in Test Case 3, Access 1!\""
test3_access1_exec_str:  .string "\"Mismatch during jalr in Test Case 3, Access 1!\""
test3_access2_store_str: .string "\"Mismatch during sw in Test Case 3, Access 2!\""
test3_access2_load_str:  .string "\"Mismatch during lw in Test Case 3, Access 2!\""
test3_access2_exec_str:  .string "\"Mismatch during jalr in Test Case 3, Access 2!\""

RVTEST_DATA_END
RVTEST_SIG_SETUP
