// --------------------------------------------------------------------------------------------------------------------------------
// Developed by: Umer Shahid & Muhammad Zain
// --------------------------------------------------------------------------------------------------------------------------------
// Test cases are as follows:
// --------------------------------------------------------------------------------------------------------------------------------
// 1. A page at level 3 is setup with PTE.RSW = 2'b01:
//        Then, in U-Mode, the page is accessed --> required: Successful access
// 2. A page at level 3 is setup with PTE.RSW = 2'b10:
//        Then, in U-Mode, the page is accessed --> required: Successful access
// 3. A page at level 3 is setup with PTE.RSW = 2'b11:
//        Then, in U-Mode, the page is accessed --> required: Successful access
// 4. A page at level 2 is setup with PTE.RSW = 2'b01:
//        Then, in U-Mode, the page is accessed --> required: Successful access
// 5. A page at level 2 is setup with PTE.RSW = 2'b10:
//        Then, in U-Mode, the page is accessed --> required: Successful access
// 6. A page at level 2 is setup with PTE.RSW = 2'b11:
//        Then, in U-Mode, the page is accessed --> required: Successful access
// 7. A page at level 1 is setup with PTE.RSW = 2'b01:
//        Then, in U-Mode, the page is accessed --> required: Successful access
// 8. A page at level 1 is setup with PTE.RSW = 2'b10:
//        Then, in U-Mode, the page is accessed --> required: Successful access
// 9. A page at level 1 is setup with PTE.RSW = 2'b11:
//        Then, in U-Mode, the page is accessed --> required: Successful access
// 10. A page at level 0 is setup with PTE.RSW = 2'b01:
//        Then, in U-Mode, the page is accessed --> required: Successful access
// 11. A page at level 0 is setup with PTE.RSW = 2'b10:
//        Then, in U-Mode, the page is accessed --> required: Successful access
// 12. A page at level 0 is setup with PTE.RSW = 2'b11:
//        Then, in U-Mode, the page is accessed --> required: Successful access
//
// Total Expected Faults :: 0
// --------------------------------------------------------------------------------------------------------------------------------

##### START_TEST_CONFIG #####
# REQUIRED_EXTENSIONS: [I, Sv48]
# MARCH: rv64i_zicsr
##### END_TEST_CONFIG #####

#define TEST_FILE "sv48_pte_rsw_Umode.S"
#define SIGUPD_COUNT 55
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

  // Read PTE to make sure that the accesses didn't affect the RSW field
  .if \level == LEVEL3
    LA(  a4, rvtest_Sroot_pg_tbl)
    \TEST_CASE\()_read_pte:
    ld   a4, 40(a4)
  .elseif \level == LEVEL2
    LA(  a4, rvtest_slvl2_pg_tbl)
    \TEST_CASE\()_read_pte:
    ld   a4, 160(a4)
  .elseif \level == LEVEL1
    LA(  a4, rvtest_slvl1_pg_tbl)
    \TEST_CASE\()_read_pte:
    ld   a4, 16(a4)
  .elseif \level == LEVEL0
    LA(  a4, rvtest_slvl0_pg_tbl)
    \TEST_CASE\()_read_pte:
    ld   a4, 24(a4)
  .endif
  RVTEST_SIGUPD(x2, x5, x4, a4, \TEST_CASE\()_read_pte, \TEST_CASE\()_read_pte_str)

.endm


main:
  LI( a2, 0x800)              // Test signature initialization

//---------------------------------------------------------------------------------------------------------------------------------
//                                   Virtual addresses definition for code and test regions
//---------------------------------------------------------------------------------------------------------------------------------

  // Virtual Address of Test section (rvtest_data_1)
  .set va_data,               0x028500403000

  // Virtual Address for code region
  .set va_rvtest_code_begin,  0x030080000000


  // PTE setup for Code Region
  SUPERPAGE_PTE_SETUP_SV48(rvtest_code_begin, (PTE_D | PTE_A | PTE_U | PTE_X | PTE_R | PTE_V), va_rvtest_code_begin, LEVEL3)
  sfence.vma

  // Save area setup for code region
  csrr a0, mscratch
  SAVE_AREA_SETUP(va_rvtest_code_begin, rvtest_code_begin, code)

//---------------------------------------------------------------------------------------------------------------------------------
//                                               Test Cases Start from here
//---------------------------------------------------------------------------------------------------------------------------------

  SATP_SETUP_RV64(sv48)                                                  // Set SATP for virtualization
  sfence.vma                                                             // Flush TLB

//---------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------------------------------------------
//                                                    TESTS AT LEVEL 3
//---------------------------------------------------------------------------------------------------------------------------------
//                    512GB PAGE    Region 1 under test at level 3 -- RWX permissions given to the region
//---------------------------------------------------------------------------------------------------------------------------------

  // Test case 1: Test in U-Mode | RSW set to 1 | expected = successful page access
  SUPERPAGE_PTE_SETUP_SV48(rvtest_data_1, ((1 << 8) | PTE_D | PTE_A | PTE_U | PTE_X | PTE_W | PTE_R | PTE_V), va_data, LEVEL3)
  sfence.vma

  TEST_CASES_RUNNER Umode, va_data, LEVEL3, test1

//---------------------------------------------------------------------------------------------------------------------------------
//                    512GB PAGE    Region 1 under test at level 3 -- RWX permissions given to the region
//---------------------------------------------------------------------------------------------------------------------------------

  // Test case 2: Test in U-Mode | RSW set to 2 | expected = successful page access
  SUPERPAGE_PTE_SETUP_SV48(rvtest_data_1, ((1 << 9) | PTE_D | PTE_A | PTE_U | PTE_X | PTE_W | PTE_R | PTE_V), va_data, LEVEL3)
  sfence.vma

  TEST_CASES_RUNNER Umode, va_data, LEVEL3, test2

//---------------------------------------------------------------------------------------------------------------------------------
//                    512GB PAGE    Region 1 under test at level 3 -- RWX permissions given to the region
//---------------------------------------------------------------------------------------------------------------------------------

  // Test case 3: Test in U-Mode | RSW set to 3 | expected = successful page access
  SUPERPAGE_PTE_SETUP_SV48(rvtest_data_1, ((1 << 9) | (1 << 8) | PTE_D | PTE_A | PTE_U | PTE_X | PTE_W | PTE_R | PTE_V), va_data, LEVEL3)
  sfence.vma

  TEST_CASES_RUNNER Umode, va_data, LEVEL3, test3


//---------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------------------------------------------
//                                                    TESTS AT LEVEL 2
//---------------------------------------------------------------------------------------------------------------------------------
//                    1GB PAGE    Region 1 under test at level 2 -- RWX permissions given to the region
//---------------------------------------------------------------------------------------------------------------------------------

  // Test case 4: Test in U-Mode | RSW set to 1 | expected = successful page access
  PTE_SETUP_SV48(rvtest_slvl2_pg_tbl, (PTE_V), va_data, LEVEL3)
  SUPERPAGE_PTE_SETUP_SV48(rvtest_data_1, ((1 << 8) | PTE_D | PTE_A | PTE_U | PTE_X | PTE_W | PTE_R | PTE_V), va_data, LEVEL2)
  sfence.vma

  TEST_CASES_RUNNER Umode, va_data, LEVEL2, test4

//---------------------------------------------------------------------------------------------------------------------------------
//                    1GB PAGE    Region 1 under test at level 2 -- RWX permissions given to the region
//---------------------------------------------------------------------------------------------------------------------------------

  // Test case 5: Test in U-Mode | RSW set to 2 | expected = successful page access
  PTE_SETUP_SV48(rvtest_slvl2_pg_tbl, (PTE_V), va_data, LEVEL3)
  SUPERPAGE_PTE_SETUP_SV48(rvtest_data_1, ((1 << 9) | PTE_D | PTE_A | PTE_U | PTE_X | PTE_W | PTE_R | PTE_V), va_data, LEVEL2)
  sfence.vma

  TEST_CASES_RUNNER Umode, va_data, LEVEL2, test5

//---------------------------------------------------------------------------------------------------------------------------------
//                    1GB PAGE    Region 1 under test at level 2 -- RWX permissions given to the region
//---------------------------------------------------------------------------------------------------------------------------------

  // Test case 6: Test in U-Mode | RSW set to 3 | expected = successful page access
  PTE_SETUP_SV48(rvtest_slvl2_pg_tbl, (PTE_V), va_data, LEVEL3)
  SUPERPAGE_PTE_SETUP_SV48(rvtest_data_1, ((1 << 9) | (1 << 8) | PTE_D | PTE_A | PTE_U | PTE_X | PTE_W | PTE_R | PTE_V), va_data, LEVEL2)
  sfence.vma

  TEST_CASES_RUNNER Umode, va_data, LEVEL2, test6


//---------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------------------------------------------
//                                                    TESTS AT LEVEL 1
//---------------------------------------------------------------------------------------------------------------------------------
//                    2MB PAGE    Region 1 under test at level 1 -- RWX permissions given to the region
//---------------------------------------------------------------------------------------------------------------------------------

  // Test case 7: Test in U-Mode | RSW set to 1 | expected = successful page access
  PTE_SETUP_SV48(rvtest_slvl2_pg_tbl, (PTE_V), va_data, LEVEL3)
  PTE_SETUP_SV48(rvtest_slvl1_pg_tbl, (PTE_V), va_data, LEVEL2)
  SUPERPAGE_PTE_SETUP_SV48(rvtest_data_1, ((1 << 8) | PTE_D | PTE_A | PTE_U | PTE_X | PTE_W | PTE_R | PTE_V), va_data, LEVEL1)
  sfence.vma

  TEST_CASES_RUNNER Umode, va_data, LEVEL1, test7

//---------------------------------------------------------------------------------------------------------------------------------
//                    2MB PAGE    Region 1 under test at level 1 -- RWX permissions given to the region
//---------------------------------------------------------------------------------------------------------------------------------

  // Test case 8: Test in U-Mode | RSW set to 2 | expected = successful page access
  PTE_SETUP_SV48(rvtest_slvl2_pg_tbl, (PTE_V), va_data, LEVEL3)
  PTE_SETUP_SV48(rvtest_slvl1_pg_tbl, (PTE_V), va_data, LEVEL2)
  SUPERPAGE_PTE_SETUP_SV48(rvtest_data_1, ((1 << 9) | PTE_D | PTE_A | PTE_U | PTE_X | PTE_W | PTE_R | PTE_V), va_data, LEVEL1)
  sfence.vma

  TEST_CASES_RUNNER Umode, va_data, LEVEL1, test8

//---------------------------------------------------------------------------------------------------------------------------------
//                    2MB PAGE    Region 1 under test at level 1 -- RWX permissions given to the region
//---------------------------------------------------------------------------------------------------------------------------------

  // Test case 9: Test in U-Mode | RSW set to 3 | expected = successful page access
  PTE_SETUP_SV48(rvtest_slvl2_pg_tbl, (PTE_V), va_data, LEVEL3)
  PTE_SETUP_SV48(rvtest_slvl1_pg_tbl, (PTE_V), va_data, LEVEL2)
  SUPERPAGE_PTE_SETUP_SV48(rvtest_data_1, ((1 << 9) | (1 << 8) | PTE_D | PTE_A | PTE_U | PTE_X | PTE_W | PTE_R | PTE_V), va_data, LEVEL1)
  sfence.vma

  TEST_CASES_RUNNER Umode, va_data, LEVEL1, test9


//---------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------------------------------------------
//                                                    TESTS AT LEVEL 0
//---------------------------------------------------------------------------------------------------------------------------------
//                    4KB PAGE    Region 1 under test at level 0 -- RWX permissions given to the region
//---------------------------------------------------------------------------------------------------------------------------------

  // Test case 10: Test in U-Mode | RSW set to 1 | expected = successful page access
  PTE_SETUP_SV48(rvtest_slvl2_pg_tbl, (PTE_V), va_data, LEVEL3)
  PTE_SETUP_SV48(rvtest_slvl1_pg_tbl, (PTE_V), va_data, LEVEL2)
  PTE_SETUP_SV48(rvtest_slvl0_pg_tbl, (PTE_V), va_data, LEVEL1)
  PTE_SETUP_SV48(rvtest_data_1, ((1 << 8) | PTE_D | PTE_A | PTE_U | PTE_X | PTE_W | PTE_R | PTE_V), va_data, LEVEL0)
  sfence.vma

  TEST_CASES_RUNNER Umode, va_data, LEVEL0, test10

//---------------------------------------------------------------------------------------------------------------------------------
//                    4KB PAGE    Region 1 under test at level 0 -- RWX permissions given to the region
//---------------------------------------------------------------------------------------------------------------------------------

  // Test case 11: Test in U-Mode | RSW set to 2 | expected = successful page access
  PTE_SETUP_SV48(rvtest_slvl2_pg_tbl, (PTE_V), va_data, LEVEL3)
  PTE_SETUP_SV48(rvtest_slvl1_pg_tbl, (PTE_V), va_data, LEVEL2)
  PTE_SETUP_SV48(rvtest_slvl0_pg_tbl, (PTE_V), va_data, LEVEL1)
  PTE_SETUP_SV48(rvtest_data_1, ((1 << 9) | PTE_D | PTE_A | PTE_U | PTE_X | PTE_W | PTE_R | PTE_V), va_data, LEVEL0)
  sfence.vma

  TEST_CASES_RUNNER Umode, va_data, LEVEL0, test11

//---------------------------------------------------------------------------------------------------------------------------------
//                    4KB PAGE    Region 1 under test at level 0 -- RWX permissions given to the region
//---------------------------------------------------------------------------------------------------------------------------------

  // Test case 12: Test in U-Mode | RSW set to 3 | expected = successful page access
  PTE_SETUP_SV48(rvtest_slvl2_pg_tbl, (PTE_V), va_data, LEVEL3)
  PTE_SETUP_SV48(rvtest_slvl1_pg_tbl, (PTE_V), va_data, LEVEL2)
  PTE_SETUP_SV48(rvtest_slvl0_pg_tbl, (PTE_V), va_data, LEVEL1)
  PTE_SETUP_SV48(rvtest_data_1, ((1 << 9) | (1 << 8) | PTE_D | PTE_A | PTE_U | PTE_X | PTE_W | PTE_R | PTE_V), va_data, LEVEL0)
  sfence.vma

  TEST_CASES_RUNNER Umode, va_data, LEVEL0, test12


//---------------------------------------------------------------------------------------------------------------------------------
RVTEST_CODE_END
RVTEST_DATA_BEGIN

//---------------------------------------------------------------------------------------------------------------------------------
//                                            PHYSICAL ADDRESS REGION FOR TESTING
//---------------------------------------------------------------------------------------------------------------------------------
// Physical Address region under testing for LEVEL 0, 1, 2 and 3
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

test1_store_str:     .string "\"Mismatch during sw in Test Case 1!\""
test1_load_str:      .string "\"Mismatch during lw in Test Case 1!\""
test1_exec_str:      .string "\"Mismatch during jalr in Test Case 1!\""
test1_read_pte_str:  .string "\"Mismatch in PTE value in Test Case 1!\""
test2_store_str:     .string "\"Mismatch during sw in Test Case 2!\""
test2_load_str:      .string "\"Mismatch during lw in Test Case 2!\""
test2_exec_str:      .string "\"Mismatch during jalr in Test Case 2!\""
test2_read_pte_str:  .string "\"Mismatch in PTE value in Test Case 2!\""
test3_store_str:     .string "\"Mismatch during sw in Test Case 3!\""
test3_load_str:      .string "\"Mismatch during lw in Test Case 3!\""
test3_exec_str:      .string "\"Mismatch during jalr in Test Case 3!\""
test3_read_pte_str:  .string "\"Mismatch in PTE value in Test Case 3!\""
test4_store_str:     .string "\"Mismatch during sw in Test Case 4!\""
test4_load_str:      .string "\"Mismatch during lw in Test Case 4!\""
test4_exec_str:      .string "\"Mismatch during jalr in Test Case 4!\""
test4_read_pte_str:  .string "\"Mismatch in PTE value in Test Case 4!\""
test5_store_str:     .string "\"Mismatch during sw in Test Case 5!\""
test5_load_str:      .string "\"Mismatch during lw in Test Case 5!\""
test5_exec_str:      .string "\"Mismatch during jalr in Test Case 5!\""
test5_read_pte_str:  .string "\"Mismatch in PTE value in Test Case 5!\""
test6_store_str:     .string "\"Mismatch during sw in Test Case 6!\""
test6_load_str:      .string "\"Mismatch during lw in Test Case 6!\""
test6_exec_str:      .string "\"Mismatch during jalr in Test Case 6!\""
test6_read_pte_str:  .string "\"Mismatch in PTE value in Test Case 6!\""
test7_store_str:     .string "\"Mismatch during sw in Test Case 7!\""
test7_load_str:      .string "\"Mismatch during lw in Test Case 7!\""
test7_exec_str:      .string "\"Mismatch during jalr in Test Case 7!\""
test7_read_pte_str:  .string "\"Mismatch in PTE value in Test Case 7!\""
test8_store_str:     .string "\"Mismatch during sw in Test Case 8!\""
test8_load_str:      .string "\"Mismatch during lw in Test Case 8!\""
test8_exec_str:      .string "\"Mismatch during jalr in Test Case 8!\""
test8_read_pte_str:  .string "\"Mismatch in PTE value in Test Case 8!\""
test9_store_str:     .string "\"Mismatch during sw in Test Case 9!\""
test9_load_str:      .string "\"Mismatch during lw in Test Case 9!\""
test9_exec_str:      .string "\"Mismatch during jalr in Test Case 9!\""
test9_read_pte_str:  .string "\"Mismatch in PTE value in Test Case 9!\""
test10_store_str:     .string "\"Mismatch during sw in Test Case 10!\""
test10_load_str:      .string "\"Mismatch during lw in Test Case 10!\""
test10_exec_str:      .string "\"Mismatch during jalr in Test Case 10!\""
test10_read_pte_str:  .string "\"Mismatch in PTE value in Test Case 10!\""
test11_store_str:     .string "\"Mismatch during sw in Test Case 11!\""
test11_load_str:      .string "\"Mismatch during lw in Test Case 11!\""
test11_exec_str:      .string "\"Mismatch during jalr in Test Case 11!\""
test11_read_pte_str:  .string "\"Mismatch in PTE value in Test Case 11!\""
test12_store_str:     .string "\"Mismatch during sw in Test Case 12!\""
test12_load_str:      .string "\"Mismatch during lw in Test Case 12!\""
test12_exec_str:      .string "\"Mismatch during jalr in Test Case 12!\""
test12_read_pte_str:  .string "\"Mismatch in PTE value in Test Case 12!\""

RVTEST_DATA_END
RVTEST_SIG_SETUP
