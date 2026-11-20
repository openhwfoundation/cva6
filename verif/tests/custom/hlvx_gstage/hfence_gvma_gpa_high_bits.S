# See LICENSE for license details.

#*****************************************************************************
# hfence_gvma_gpa_high_bits.S
#-----------------------------------------------------------------------------
#
# HFENCE.GVMA with an address invalidates the G-stage translations of that
# guest physical address only. In Sv39x4 the guest physical page number has
# 29 bits: the root level indexes GPA[40:30], two bits more than the 9 bits
# of the other levels.
#
# Mapping under test, VS-stage bare (vsatp = 0), so the G stage alone
# translates guest accesses:
#   GPA_A = 0x00_4000_0000 -> page_a  (root index 0x001)
#   GPA_B = 0x80_4000_0000 -> page_b  (root index 0x201)
# The two addresses differ only by GPA bit 39. GPA_A is not 0: a zero
# address means "every address" to HFENCE.GVMA.
#
#   probe 1 : hlv.d GPA_A and GPA_B: both translations enter the DTLB
#   probe 2 : hfence.gvma GPA_A, then hlv.d GPA_B: it must hit in the DTLB,
#             the DTLB miss counter must not move
#   probe 3 : hlv.d GPA_A: it must miss, its entry was invalidated
#
# mhpmcounter3 counts DTLB misses (mhpmevent3 = 4).
#
# tohost = 2 * TESTNUM + 1 on a wrong value or counter.
#

#include "riscv_test.h"
#include "test_macros.h"

.option arch, +h

#define CSR_HSTATUS  0x600
#define CSR_VSSTATUS 0x200
#define CSR_VSATP    0x280
#define CSR_HEDELEG  0x602
#define CSR_HGATP    0x680

#define HGATP_MODE_SV39X4 8
#define HSTATUS_SPVP      (1 << 8)
#define EVENT_DTLB_MISS   4

#define GPA_A        0x0040000000
#define GPA_B        0x8040000000
#define VALUE_A      0x00000000aaaaaaaa
#define VALUE_B      0x00000000bbbbbbbb

#define G_LEAF     (PTE_V | PTE_R | PTE_W | PTE_X | PTE_U | PTE_A | PTE_D)

/* t0 = non-leaf PTE pointing at \sym. */
.macro PTE_PTR sym
  la   t0, \sym
  srli t0, t0, 12
  slli t0, t0, 10
  ori  t0, t0, PTE_V
.endm

/* t0 = G-stage leaf PTE for the page of \sym. */
.macro PTE_LEAF sym
  la   t0, \sym
  srli t0, t0, 12
  slli t0, t0, 10
  li   t1, G_LEAF
  or   t0, t0, t1
.endm

RVTEST_RV64M
RVTEST_CODE_BEGIN

  csrw CSR_HEDELEG, zero
  csrw medeleg, zero

  # ---- G-stage: root[GPA[40:30]] -> l1[GPA[29:21]] -> l0[GPA[20:12]]
  # GPA_A: root index 0x001, l1 index 0, l0 index 0 -> page_a
  PTE_PTR g_l1_a
  la   t2, g_root
  sd   t0, (((GPA_A >> 30) & 0x7ff) * 8)(t2)
  PTE_PTR g_l0_a
  la   t2, g_l1_a
  sd   t0, 0(t2)
  PTE_LEAF page_a
  la   t2, g_l0_a
  sd   t0, 0(t2)

  # GPA_B: root index 0x201, l1 index 0, l0 index 0 -> page_b
  PTE_PTR g_l1_b
  la   t2, g_root
  li   t3, (((GPA_B >> 30) & 0x7ff) * 8)
  add  t2, t2, t3
  sd   t0, 0(t2)
  PTE_PTR g_l0_b
  la   t2, g_l1_b
  sd   t0, 0(t2)
  PTE_LEAF page_b
  la   t2, g_l0_b
  sd   t0, 0(t2)

  # ---- G-stage on, VS-stage bare
  la   t0, g_root
  srli t0, t0, 12
  li   t1, HGATP_MODE_SV39X4
  slli t1, t1, 60
  or   t0, t0, t1
  csrw CSR_HGATP, t0
  csrw CSR_VSATP, zero

  li   t0, HSTATUS_SPVP              /* HLV runs at effective privilege S */
  csrw CSR_HSTATUS, t0
  csrw CSR_VSSTATUS, zero
  sfence.vma
  hfence.gvma
  hfence.vvma

  # ---- DTLB miss counter
  li   t0, EVENT_DTLB_MISS
  csrw mhpmevent3, t0
  csrw mcountinhibit, zero

  # ==================================================================
  # probe 1: both translations enter the DTLB
  # ==================================================================
  li   TESTNUM, 1
  li   a0, GPA_A
  li   a1, GPA_B
  hlv.d t1, (a0)
  li   t0, VALUE_A
  bne  t1, t0, fail
  hlv.d t1, (a1)
  li   t0, VALUE_B
  bne  t1, t0, fail

  # ==================================================================
  # probe 2: hfence.gvma GPA_A keeps the GPA_B translation
  # rs1 holds GPA >> 2
  # ==================================================================
  li   TESTNUM, 2
  srli t0, a0, 2
  hfence.gvma t0, zero
  csrr s0, mhpmcounter3
  hlv.d t1, (a1)
  csrr s1, mhpmcounter3
  li   t0, VALUE_B
  bne  t1, t0, fail
  bne  s0, s1, fail                  /* GPA_B missed: it was flushed */

  # ==================================================================
  # probe 3: the GPA_A translation was invalidated
  # ==================================================================
  li   TESTNUM, 3
  csrr s0, mhpmcounter3
  hlv.d t1, (a0)
  csrr s1, mhpmcounter3
  li   t0, VALUE_A
  bne  t1, t0, fail
  beq  s0, s1, fail                  /* GPA_A hit: it was not flushed */
  j    pass

  TEST_PASSFAIL

  .align 2
  .global mtvec_handler
mtvec_handler:
  csrr t5, mcause
  mv   TESTNUM, t5                   /* any trap: report its cause */
  j    fail

RVTEST_CODE_END

  .data
RVTEST_DATA_BEGIN
  TEST_DATA

.align 14
g_root:  .fill 2048, 8, 0            /* 16 KiB Sv39x4 root */
.align 12
g_l1_a:  .fill 512, 8, 0
.align 12
g_l0_a:  .fill 512, 8, 0
.align 12
g_l1_b:  .fill 512, 8, 0
.align 12
g_l0_b:  .fill 512, 8, 0
.align 12
page_a:
  .dword VALUE_A
  .fill 511, 8, 0
.align 12
page_b:
  .dword VALUE_B
  .fill 511, 8, 0
RVTEST_DATA_END
