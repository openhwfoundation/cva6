# See LICENSE for license details.

#*****************************************************************************
# instr-guest-page-fault-rvc0-rv64.S
#-----------------------------------------------------------------------------
#
# Regression for issue #3568.
#
# With RVH=1 and RVC=0, an instruction guest-page fault must remain
# INSTR_GUEST_PAGE_FAULT (mcause=20) when it passes through instr_queue.
#
# A pure G-stage translation is configured:
#   vsatp = Bare
#   hgatp = Sv39x4
#
# The guest instruction address is covered by a valid G-stage leaf PTE
# with execute permission cleared (X=0). Entering VS-mode therefore causes
# an instruction guest-page fault on the first guest instruction fetch.
#
# Expected:
#   mcause = 20
#
# Buggy RTL:
#   instr_queue changes the fault to INSTR_PAGE_FAULT
#   mcause = 12
#

#include "riscv_test.h"
#include "test_macros.h"

.option arch, +h
.option norvc

#define CSR_HGATP   0x680
#define CSR_VSATP   0x280
#define CSR_HEDELEG 0x602

#define HGATP_MODE_SV39X4 8
#define CAUSE_INSTR_GUEST_PAGE_FAULT 20

RVTEST_RV64M
RVTEST_CODE_BEGIN

  # Install the directed M-mode trap handler explicitly.
  # Keep the handler strongly aligned for CVA6 mtvec handling.
  la   t0, mtvec_handler
  csrw mtvec, t0

  # ------------------------------------------------------------------
  # Build a G-stage 1 GiB identity leaf for the DRAM region.
  #
  # GPA 0x80000000 uses root index 2.
  #
  # Deliberately leave PTE_X clear.  The mapping is otherwise valid.
  # A guest instruction fetch through this entry must therefore raise
  # INSTR_GUEST_PAGE_FAULT.
  # ------------------------------------------------------------------
  la   t0, g_root
  li   t1, ((0x80000000 >> 12) << 10) | PTE_V | PTE_R | PTE_W | PTE_U | PTE_A | PTE_D
  sd   t1, (2 * 8)(t0)

  # Configure hgatp = Sv39x4 | g_root.
  la   t0, g_root
  srli t0, t0, 12
  li   t1, HGATP_MODE_SV39X4
  slli t1, t1, 60
  or   t0, t0, t1
  csrw CSR_HGATP, t0

  # Pure G-stage translation.
  csrw CSR_VSATP, zero

  # Keep the exception in M-mode so mcause is easy to inspect.
  csrw CSR_HEDELEG, zero
  csrw medeleg, zero

  hfence.gvma

  # ------------------------------------------------------------------
  # Configure mret to enter VS-mode:
  #   MPP = S
  #   MPV = 1
  # ------------------------------------------------------------------
  li   t0, MSTATUS_MPP
  csrc mstatus, t0

  li   t0, (1 << 11)
  csrs mstatus, t0

  li   t0, 1
  slli t0, t0, 39
  csrs mstatus, t0

  # First VS instruction fetch will use the X=0 G-stage mapping.
  la   t0, guest_code
  csrw mepc, t0

  li   TESTNUM, 2
  mret

guest_code:
  # Reaching guest_code means the expected instruction guest-page fault
  # was not generated. Write an encoded failure value directly to tohost.
  #
  # TESTNUM = 42 would normally produce:
  #   (42 << 1) | 1 = 85
  li   t5, 42
  slli t5, t5, 1
  ori  t5, t5, 1
  la   t4, tohost
  sw   t5, 0(t4)

1:
  j    1b

  .align 8
  .global mtvec_handler
mtvec_handler:
  # Read the architectural exception cause.
  csrr t5, mcause

  # Generate the standard riscv-tests tohost result without taking
  # any branch before the store:
  #
  #   mcause == 20 -> tohost = 1       -> PASS
  #   mcause == N  -> tohost = 2*N+1   -> FAIL with cause N
  #
  # t4 becomes all zeros when mcause == 20 and all ones otherwise.
  li   t6, CAUSE_INSTR_GUEST_PAGE_FAULT
  xor  t4, t5, t6
  sltu t4, zero, t4
  sub  t4, zero, t4

  # Keep mcause only on the failure path.
  and  t5, t5, t4

  # Encode result as (cause << 1) | 1.
  # For the expected cause this becomes exactly 1.
  slli t5, t5, 1
  ori  t5, t5, 1

  # Write the result directly. No taken branch is required before
  # termination, avoiding the unrelated no-RVC branch behavior seen
  # in the previous diagnostic trace.
  la   t4, tohost
  sw   t5, 0(t4)

2:
  j    2b

RVTEST_CODE_END

  .data
RVTEST_DATA_BEGIN
  TEST_DATA

.align 14
g_root:
  .fill 2048, 8, 0

RVTEST_DATA_END
