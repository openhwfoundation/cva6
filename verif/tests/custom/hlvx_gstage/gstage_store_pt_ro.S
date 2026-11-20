# See LICENSE for license details.

#*****************************************************************************
# gstage_store_pt_ro.S
#-----------------------------------------------------------------------------
#
# A guest store must not need write permission on the G-stage mapping of
# the guest page tables.
#
# During a two-stage walk the PTW reads each VS-stage PTE through the G
# stage (G_INTERMED_STAGE). That read is an implicit load. The store and
# dirty rules of the original access apply only to the final G-stage leaf
# of the data page, not to the pages that hold the VS-stage tables.
#
# Mapping under test:
#   G-stage  : identity 4 KiB leaves over [DRAM_BASE, DRAM_BASE + 2 MiB),
#              V R W X U A D everywhere, EXCEPT the three pages holding
#              vs_root / vs_l1 / vs_l0, which are V R U A (no W, no D).
#   VS-stage : GVA 0x1000 -> GPA target_page, V R W X A D (U=0, SPVP=1).
#
#   probe 1 : hlv.d  (0x1000)  -- load, must pass
#   probe 2 : hsv.d  (0x1000)  -- store, must pass
#   probe 3 : hlv.d  (0x1000)  -- reads back what probe 2 wrote
#
# GSTAGE_PT_RW variant: W and D added to the G-stage leaves that map the
# VS tables. It passes whether or not the rule is right, which isolates
# those two bits as the only variable.
#
# tohost = 23 (TESTNUM 23): probe 2 took a STORE_GUEST_PAGE_FAULT.
# Any other trap reports its own mcause as tohost.
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
#define CAUSE_STORE_GUEST_PAGE_FAULT 23

#define GVA_TARGET   0x1000
#define TARGET_VALUE 0x00c0ffee0badf00d
#define STORE_VALUE  0x1234567890abcdef

/* Ordinary G-stage leaf: identity, executable. */
#define G_LEAF     (PTE_V | PTE_R | PTE_W | PTE_X | PTE_U | PTE_A | PTE_D)

/* G-stage leaf for the pages that HOLD the VS-stage page tables. */
#ifdef GSTAGE_PT_RW
# define G_LEAF_PT (PTE_V | PTE_R | PTE_W | PTE_U | PTE_A | PTE_D)
#else
# define G_LEAF_PT (PTE_V | PTE_R | PTE_U | PTE_A)
#endif

/* VS-stage leaf: readable and writable. */
#define VS_LEAF    (PTE_V | PTE_R | PTE_W | PTE_X | PTE_A | PTE_D)

/* Map the 4 KiB page holding \sym in g_l0 with G_LEAF_PT (no W/D by default). */
.macro GMAP_PT sym
  la   t0, \sym
  srli t1, t0, 12                    /* PPN of the page holding the table */
  slli t2, t1, 10
  li   t3, G_LEAF_PT
  or   t2, t2, t3                    /* the PTE */
  li   t3, (DRAM_BASE >> 12)
  sub  t1, t1, t3                    /* page index within the mapped 2 MiB */
  slli t1, t1, 3
  la   t3, g_l0
  add  t1, t3, t1
  sd   t2, 0(t1)
.endm

/* tmp0 = PTE pointing at \sym's page, with permission bits \perm. */
.macro PTE_FOR sym, perm
  la   t0, \sym
  srli t0, t0, 12
  slli t0, t0, 10
  li   t1, \perm
  or   t0, t0, t1
.endm

RVTEST_RV64M
RVTEST_CODE_BEGIN

  csrw CSR_HEDELEG, zero
  csrw medeleg, zero

  # ------------------------------------------------------------------
  # G-stage l0: identity 4 KiB leaves over [DRAM_BASE, DRAM_BASE + 2 MiB).
  # Everything the guest touches is inside this window.
  # ------------------------------------------------------------------
  la   a4, g_l0
  li   a5, DRAM_BASE
  li   a6, 0
1:
  slli t0, a6, 12
  add  t0, t0, a5                    /* physical address of this page */
  srli t1, t0, 12
  slli t1, t1, 10
  li   t2, G_LEAF
  or   t1, t1, t2
  slli t2, a6, 3
  add  t2, a4, t2
  sd   t1, 0(t2)
  addi a6, a6, 1
  li   t0, 512
  blt  a6, t0, 1b

  # ------------------------------------------------------------------
  # The three pages holding the VS-stage tables are read-only at the G
  # stage. This is the only thing the control variant changes.
  # ------------------------------------------------------------------
  GMAP_PT vs_root
  GMAP_PT vs_l1
  GMAP_PT vs_l0

  # ---- G-stage upper levels: g_root[GPA[40:30]] -> g_l1[GPA[29:21]] -> g_l0
  PTE_FOR g_l0, PTE_V
  la   t2, g_l1
  li   t3, ((DRAM_BASE >> 21) & 0x1ff)
  slli t3, t3, 3
  add  t2, t2, t3
  sd   t0, 0(t2)

  PTE_FOR g_l1, PTE_V
  la   t2, g_root
  li   t3, (DRAM_BASE >> 30)         /* Sv39x4 root index, 2048 entries */
  slli t3, t3, 3
  add  t2, t2, t3
  sd   t0, 0(t2)

  # ---- VS-stage (Sv39): GVA_TARGET -> target_page.  VPN2 = VPN1 = 0.
  PTE_FOR vs_l1, PTE_V
  la   t2, vs_root
  sd   t0, (((GVA_TARGET >> 30) & 0x1ff) * 8)(t2)

  PTE_FOR vs_l0, PTE_V
  la   t2, vs_l1
  sd   t0, (((GVA_TARGET >> 21) & 0x1ff) * 8)(t2)

  /* GPA == PA here, because the G-stage window is an identity map. */
  PTE_FOR target_page, VS_LEAF
  la   t2, vs_l0
  sd   t0, (((GVA_TARGET >> 12) & 0x1ff) * 8)(t2)

  # ---- turn translation on
  la   t0, g_root
  srli t0, t0, 12
  li   t1, HGATP_MODE_SV39X4
  slli t1, t1, 60
  or   t0, t0, t1
  csrw CSR_HGATP, t0

  la   t0, vs_root
  srli t0, t0, 12
  li   t1, SATP_MODE_SV39
  slli t1, t1, 60
  or   t0, t0, t1
  csrw CSR_VSATP, t0

  li   t0, HSTATUS_SPVP              /* HLV/HSV run at effective privilege S */
  csrw CSR_HSTATUS, t0
  csrw CSR_VSSTATUS, zero            /* vsstatus.MXR = 0 */
  li   t0, SSTATUS_MXR
  csrc sstatus, t0                   /* sstatus.MXR = 0 */
  sfence.vma
  hfence.gvma
  hfence.vvma

  # ==================================================================
  # probe 1: guest load. The G_INTERMED reads need only R, which the
  # table pages have. Any trap here is a setup problem.
  # ==================================================================
  li   TESTNUM, 1
  li   a0, GVA_TARGET
  hlv.d t1, (a0)
  li   t0, TARGET_VALUE
  bne  t1, t0, fail

  # Force a fresh walk: no DTLB or G-stage entry may survive into probe 2.
  hfence.vvma
  hfence.gvma
  sfence.vma

  # ==================================================================
  # probe 2: guest store, same address, same tables. The data page is
  # writable at both stages, so this must retire.
  # ==================================================================
  li   TESTNUM, 2
  li   t1, STORE_VALUE
  hsv.d t1, (a0)

  # ==================================================================
  # probe 3: the store reached memory
  # ==================================================================
  li   TESTNUM, 3
  hfence.vvma
  hfence.gvma
  hlv.d t2, (a0)
  li   t0, STORE_VALUE
  bne  t2, t0, fail
  j    pass

  TEST_PASSFAIL

  .align 2
  .global mtvec_handler
mtvec_handler:
  csrr t5, mcause
  li   t6, 2
  bne  TESTNUM, t6, 1f
  li   t6, CAUSE_STORE_GUEST_PAGE_FAULT
  bne  t5, t6, 1f
  li   TESTNUM, 23                   /* store guest page fault: W/D wrongly */
  j    fail                          /* required on the G-stage map of a VS table */
1:
  mv   TESTNUM, t5                   /* anything else: report the cause */
  j    fail

RVTEST_CODE_END

  .data
RVTEST_DATA_BEGIN
  TEST_DATA

.align 12
vs_root: .fill 512, 8, 0
.align 12
vs_l1:   .fill 512, 8, 0
.align 12
vs_l0:   .fill 512, 8, 0
.align 14
g_root:  .fill 2048, 8, 0            /* 16 KiB Sv39x4 root */
.align 12
g_l1:    .fill 512, 8, 0
.align 12
g_l0:    .fill 512, 8, 0
.align 12
target_page:
  .dword TARGET_VALUE
  .fill 511, 8, 0
RVTEST_DATA_END
