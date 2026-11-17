# See LICENSE for license details.

#*****************************************************************************
# gstage_prio_repro.S
#-----------------------------------------------------------------------------
#
# Under two-stage translation, when BOTH the VS-stage leaf and the G-stage leaf
# deny the same store, the reported cause depends on DTLB state:
#   DTLB miss (walker decides)   -> cause 15, STORE_PAGE_FAULT        (correct)
#   DTLB hit  (hit path decides) -> cause 23, STORE_GUEST_PAGE_FAULT  (wrong)
# The VS stage is encountered first, so a VS-stage denial wins and the fault is
# an ordinary page fault. cva6_mmu.sv's DTLB-hit path tests the G-stage PTE
# first and only reaches the VS-stage test in the else-if.
#
# The same architectural state is probed twice, differing only in DTLB state:
#   probe 1 (MISS) : store to the test VA with TLBs flushed and that VA never
#                    touched, so the PTW decides the cause.
#   probe 2 (HIT)  : load the test VA first -- a load walk never evaluates W/D,
#                    so it succeeds and installs the entry -- then store it, so
#                    the DTLB-hit path decides the cause.
#
# Mapping (both stages read-only for the test page, A pre-set so no hardware
# A-update is in play):
#   guest code : VA 0x4000_0000+o -VS-> GPA 0xC000_0000+o -G-> PA 0x8000_0000+o  RWX
#   test page  : VA 0x8000_0000+o -VS-> GPA 0x4000_0000+o -G-> PA 0x8000_0000+o  RO,RO
#   VS tables  : GPA 0x8000_0000+o                        -G-> PA 0x8000_0000+o  RWX
#
# tohost = 23 is the defect: the HIT probe reported a guest-page fault where the
# MISS probe on identical state reported a page fault. tohost = 52 means the HIT
# probe's load faulted (setup problem, nothing proven); tohost = 100 + cause
# means the MISS probe itself did not report 15.
#

#include "riscv_test.h"
#include "test_macros.h"

.option arch, +h

#define CSR_HSTATUS  0x600
#define CSR_VSATP    0x280
#define CSR_HEDELEG  0x602
#define CSR_HGATP    0x680

#define HGATP_MODE_SV39X4 8
#define MSTATUS_MPV_BIT   39
#define GVA_SHIFT         0x40000000
#define MAGIC             0x0badc0de
#define CAUSE_STORE_PAGE_FAULT_ 15

/* Read-only leaf: R=1, W=0, X=0, D=0, A pre-set. */
#define PTE_RO_VS  (PTE_V | PTE_R | PTE_A)              /* U=0: guest-supervisor */
#define PTE_RO_G   (PTE_V | PTE_R | PTE_U | PTE_A)      /* U=1 is mandatory at G */
#define PTE_RWX_VS (PTE_V | PTE_R | PTE_W | PTE_X | PTE_A | PTE_D)
#define PTE_RWX_G  (PTE_V | PTE_R | PTE_W | PTE_X | PTE_U | PTE_A | PTE_D)

RVTEST_RV64M
RVTEST_CODE_BEGIN

  # CVA6 denies any S/VS access with no matching PMP entry: cover everything.
  li   t0, -1
  csrw pmpaddr0, t0
  li   t0, 0x1f
  csrw pmpcfg0, t0

  csrw CSR_HEDELEG, zero
  csrw medeleg, zero
  csrw CSR_HSTATUS, zero

  # ---- VS-stage root (Sv39), 1 GiB leaves, index = VA[38:30]
  la   t0, vs_root
  li   t1, ((0xC0000000 >> 12) << 10) | PTE_RWX_VS
  sd   t1, (1*8)(t0)                 /* VA 0x4000_0000 -> GPA 0xC000_0000 */
  li   t1, ((0x40000000 >> 12) << 10) | PTE_RO_VS
  sd   t1, (2*8)(t0)                 /* VA 0x8000_0000 -> GPA 0x4000_0000 */

  # ---- G-stage root (Sv39x4), 1 GiB leaves, index = GPA[40:30]
  la   t0, g_root
  li   t1, ((0x80000000 >> 12) << 10) | PTE_RO_G
  sd   t1, (1*8)(t0)                 /* GPA 0x4000_0000 -> PA 0x8000_0000, RO */
  li   t1, ((0x80000000 >> 12) << 10) | PTE_RWX_G
  sd   t1, (2*8)(t0)                 /* GPA 0x8000_0000 -> PA, holds VS tables */
  sd   t1, (3*8)(t0)                 /* GPA 0xC000_0000 -> PA, guest code */

  # ---- turn both stages on
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

  sfence.vma
  hfence.gvma
  hfence.vvma

  la   s0, probe_target              /* PA == the test guest VA, see mapping above */
  li   s1, -1                        /* cause seen by the MISS probe */
  li   s2, -1                        /* cause seen by the HIT probe  */
  li   s4, 0                         /* HIT probe's load result      */

  # ==================================================================
  # probe 1 (MISS): cold TLB, store straight to the never-touched VA.
  # ==================================================================
  li   TESTNUM, 1
  li   t0, MSTATUS_MPP
  csrc mstatus, t0
  li   t0, (1 << 11)                 /* MPP = S */
  csrs mstatus, t0
  li   t0, 1
  slli t0, t0, MSTATUS_MPV_BIT       /* MPV = 1, so mret lands in VS-mode */
  csrs mstatus, t0
  la   t0, guest_miss
  li   t1, GVA_SHIFT
  sub  t0, t0, t1                    /* mepc must be the GUEST virtual address */
  csrw mepc, t0
  mret

  .balign 4
guest_miss:
  sd   x0, 0(s0)                     /* DTLB miss + store -> the PTW decides */
  ecall                              /* only reached if the store did not fault */

  .balign 4
m_after_miss:
  hfence.gvma                        /* drop anything the failed walk left behind */
  hfence.vvma
  sfence.vma

  # ==================================================================
  # probe 2 (HIT): load installs the entry, then the same store hits it.
  # ==================================================================
  li   TESTNUM, 2
  li   t0, MSTATUS_MPP
  csrc mstatus, t0
  li   t0, (1 << 11)
  csrs mstatus, t0
  li   t0, 1
  slli t0, t0, MSTATUS_MPV_BIT
  csrs mstatus, t0
  la   t0, guest_hit
  li   t1, GVA_SHIFT
  sub  t0, t0, t1
  csrw mepc, t0
  mret

  .balign 4
guest_hit:
  ld   s4, 0(s0)                     /* permitted: installs the DTLB entry */
  sd   x0, 0(s0)                     /* DTLB hit + store -> the hit path decides */
  ecall                              /* only reached if the store did not fault */

  .balign 4
m_after_hit:
  csrw CSR_VSATP, zero
  csrw CSR_HGATP, zero
  sfence.vma
  hfence.gvma
  hfence.vvma

  li   t0, MAGIC
  bne  s4, t0, setup_load_faulted    /* the HIT probe's load must have succeeded */
  li   t0, CAUSE_STORE_PAGE_FAULT_
  bne  s1, t0, setup_miss_wrong      /* the MISS probe must report 15 */
  beq  s2, t0, pass                  /* the HIT probe must report 15 too */
  mv   TESTNUM, s2                   /* THE DEFECT: hit cause != miss cause */
  j    fail

setup_load_faulted:
  li   TESTNUM, 52
  j    fail
setup_miss_wrong:
  li   TESTNUM, 100
  add  TESTNUM, TESTNUM, s1
  j    fail

  TEST_PASSFAIL

  .align 2
  .global mtvec_handler
mtvec_handler:
  csrr t5, mcause
  li   t6, 1
  beq  TESTNUM, t6, 1f
  li   t6, 2
  beq  TESTNUM, t6, 2f
  j    fail
1:
  mv   s1, t5
  j    m_after_miss
2:
  mv   s2, t5
  j    m_after_hit

RVTEST_CODE_END

  .data
RVTEST_DATA_BEGIN
  TEST_DATA

probe_target: .dword MAGIC

.align 12
vs_root: .fill 512, 8, 0
.align 14
g_root:  .fill 2048, 8, 0
RVTEST_DATA_END
