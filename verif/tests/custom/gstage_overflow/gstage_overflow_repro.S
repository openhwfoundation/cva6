# See LICENSE for license details.

#*****************************************************************************
# gstage_overflow_repro.S
#-----------------------------------------------------------------------------
#
# Pure G-stage (vsatp=Bare, hgatp=Sv39x4) guest-physical-address overflow:
# per the privileged spec, GPA bits 63:41 must be zero or a GUEST-page fault
# (cause 20/21/23 by access type) is raised. CVA6:
#   - fetch side: pure G-stage GPA overflow incorrectly raises
#     INSTR_PAGE_FAULT (12), where INSTR_GUEST_PAGE_FAULT (20) is required.
#     The default variant mret's directly to a GPA with bit 41 set.
#   - data side: the equivalent load raises LOAD_GUEST_PAGE_FAULT (21),
#     matching Spike. The DATA_SIDE variant is included as a control showing
#     that the observed divergence is specific to instruction fetch.
#
# M-mode handler: expected mcause -> pass; anything else -> tohost = mcause.
# No trap at all (DATA_SIDE) -> tohost = 42.
# G-stage: 16KB Sv39x4 root, entry 2 = identity 1 GiB leaf over DRAM (U|RWX|A|D)
# so the truncated address is always walkable and the check under test is the
# only thing that can fault.
#

#include "riscv_test.h"
#include "test_macros.h"

#define CSR_HGATP   0x680
#define CSR_VSATP   0x280
#define CSR_HEDELEG 0x602
#define HGATP_MODE_SV39X4 8

#if defined(DATA_SIDE)
# define EXPECT_CAUSE 21              /* LOAD_GUEST_PAGE_FAULT */
#else
# define EXPECT_CAUSE 20              /* INSTR_GUEST_PAGE_FAULT */
#endif

RVTEST_RV64M
RVTEST_CODE_BEGIN

  # ---- G-stage root table (Sv39x4): entry 2 -> identity 1G leaf @0x80000000
  la   t0, g_root
  li   t1, ((0x80000000 >> 12) << 10) | PTE_V | PTE_R | PTE_W | PTE_X | PTE_U | PTE_A | PTE_D
  sd   t1, (2*8)(t0)

  la   t0, g_root
  srli t0, t0, 12
  li   t1, HGATP_MODE_SV39X4
  slli t1, t1, 60
  or   t0, t0, t1
  csrw CSR_HGATP, t0                 # hgatp = Sv39x4 | root
  csrw CSR_VSATP, zero               # vsatp = Bare
  csrw CSR_HEDELEG, zero             # nothing delegated: all traps to M
  csrw medeleg, zero

  # ---- enter VS-mode: MPP=S, MPV=1
  li   t0, MSTATUS_MPP
  csrc mstatus, t0
  li   t0, (1 << 11)                 # MPP = S
  csrs mstatus, t0
  li   t0, 1
  slli t0, t0, 39                    # mstatus.MPV
  csrs mstatus, t0

  li   TESTNUM, 2

#if defined(DATA_SIDE)
  la   t0, guest_code
  csrw mepc, t0
  la   a3, gdat
  li   t1, 1
  slli t1, t1, 41
  or   a3, a3, t1                    # data GPA with bit 41 set
  li   TESTNUM, 42                   # 42 = "load did not trap"
  mret                               # -> VS-mode
guest_code:
  ld   a1, 0(a3)                     # must raise LOAD_GUEST_PAGE_FAULT (21)
  j    fail                          # reached only if the load did not trap
#else
  la   t0, guest_code                # any executable, G-mapped address
  li   t1, 1
  slli t1, t1, 41
  or   t0, t0, t1
  csrw mepc, t0                      # mepc = fetch GPA with bit 41 set
  mret                               # fetch must raise cause 20
guest_code:
  j    fail                          # reached only if the bogus fetch "worked"
#endif

  TEST_PASSFAIL

  .align 2
  .global mtvec_handler
mtvec_handler:
  csrr t5, mcause
  li   t6, EXPECT_CAUSE
  beq  t5, t6, 1f
  mv   TESTNUM, t5                   # report the actual cause as tohost
  j    fail
1:
  j    pass

RVTEST_CODE_END

  .data
RVTEST_DATA_BEGIN
  TEST_DATA

.align 14
g_root:  .fill 2048, 8, 0            # 16KB Sv39x4 root (4 pages)
gdat:    .dword 0xdeadbeefcafef00d
RVTEST_DATA_END
