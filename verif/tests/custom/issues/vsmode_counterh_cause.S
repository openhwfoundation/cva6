# vsmode_counterh_cause.S
#
# On RV64 an access to a high-half counter CSR (cycleh, instreth,
# hpmcounterNh) is always illegal (cause 2), regardless of mode or
# counter-enable bits: high-half CSRs only exist on RV32.
#
# From M-mode, mcounteren bit0 (cycle) is set and hcounteren bit0 left clear,
# then the test enters VS-mode twice through mret (mstatus.MPP=S, MPV=1):
#
#   1. cycle (0xC00): legal CSR, gated off by hcounteren from V=1, so it
#      raises a virtual-instruction exception (cause 22). This proves the
#      access really runs in VS-mode: in HS-mode or M-mode it would not trap.
#   2. cycleh (0xC80): must raise an illegal-instruction exception (cause 2).
#
# Each trap is delivered to M-mode (no H-delegation configured) and checked
# for its cause, its mepc (the CSR access) and that it came from VS-mode
# (mstatus.MPV=1, MPP=S).

#include "riscv_test.h"
#include "test_macros.h"

#define MSTATUS_MPV_BIT 39

RVTEST_RV64M
RVTEST_CODE_BEGIN

  .align 2
  .option norvc

  li TESTNUM, 2

  la t0, mtvec_handler
  csrw mtvec, t0

  # enable mcounteren bit0 (cycle/cycleh gating); hcounteren bit0 stays clear
  li t0, 1
  csrs mcounteren, t0

  # --------------------------------------------------------------------
  # 1. cycle from VS-mode: cause 22
  # --------------------------------------------------------------------
  li s2, 22                         # expected cause
  la s3, vs_cycle                   # expected mepc
  la s4, after_cycle                # where the handler resumes
  la t0, vs_cycle
  jal ra, enter_vs

after_cycle:
  # --------------------------------------------------------------------
  # 2. cycleh from VS-mode: cause 2
  # --------------------------------------------------------------------
  li TESTNUM, 3
  li s2, 2
  la s3, vs_cycleh
  la s4, pass_label
  la t0, vs_cycleh
  jal ra, enter_vs

  # --------------------------------------------------------------------
  # mret into VS-mode at t0: mstatus.MPP = S, mstatus.MPV = 1
  # --------------------------------------------------------------------
enter_vs:
  csrw mepc, t0
  csrr t0, mstatus
  li t1, ~(3 << 11)
  and t0, t0, t1
  li t1, (1 << 11)
  or t0, t0, t1
  li t1, 1
  slli t1, t1, MSTATUS_MPV_BIT
  or t0, t0, t1
  csrw mstatus, t0
  mret

vs_cycle:
  csrr t0, 0xC00                    # cycle -- must trap, cause 22
  j fail                            # should never retire past the csrr

vs_cycleh:
  csrr t0, 0xC80                    # cycleh -- must trap, cause 2
  j fail

pass_label:
  j pass

  TEST_PASSFAIL

  # --------------------------------------------------------------------
  # Checks the cause, mepc and that the trap came from VS-mode, then resumes
  # in M-mode at s4 (mret with MPP=M, MPV=0).
  # --------------------------------------------------------------------
  .align 8
  .global mtvec_handler
mtvec_handler:
  csrr t0, mcause
  bne t0, s2, fail
  csrr t0, mepc
  bne t0, s3, fail
  csrr t0, mstatus
  srli t1, t0, MSTATUS_MPV_BIT
  andi t1, t1, 1
  beqz t1, fail                     # not taken from V=1
  srli t1, t0, 11
  andi t1, t1, 3
  li t2, 1
  bne t1, t2, fail                  # not taken from S-mode
  # back to M-mode, V=0, at s4
  li t1, 1
  slli t1, t1, MSTATUS_MPV_BIT
  csrc mstatus, t1
  li t1, (3 << 11)
  csrs mstatus, t1
  csrw mepc, s4
  mret

RVTEST_CODE_END

  .data
RVTEST_DATA_BEGIN
  TEST_DATA
RVTEST_DATA_END
