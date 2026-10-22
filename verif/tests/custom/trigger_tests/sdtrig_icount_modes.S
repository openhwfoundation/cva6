// Copyright 2026 10x Engineers
//
// Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
// You may obtain a copy of the License at https://solderpad.org/licenses/
//
// Issue #3619: icount counts only the instructions and the traps of the
// privilege modes where the trigger is enabled.

#include "sdtrig_test.h"

  .option norvc
  .section .text.init
  .global _start
_start:
  la t0, m_handler
  csrw mtvec, t0
  csrw medeleg, zero
  csrw mideleg, zero
  csrw satp, zero
  PMP_ALLOW_ALL
  li s1, 0                   // test phase
  csrw tselect, zero

  // 1. count=3, u=1. The M-mode instructions and the mret do not count.
  //    The trigger fires before the fourth U-mode instruction.
  li t0, MSTATUS_MPP_MASK
  csrc mstatus, t0
  la t0, u1_code
  csrw mepc, t0
  li t0, TDATA1_TYPE(TYPE_ICOUNT) | ICOUNT_COUNT(3) | ICOUNT_U
  csrw tdata1, t0
  addi x0, x0, 1
  addi x0, x0, 1
  addi x0, x0, 1
  mret
u1_code:
  addi s4, s4, 1
  addi s4, s4, 1
  addi s4, s4, 1
u1_fire:
  addi s4, s4, 1
  li a0, 1
  j test_fail

phase2:
  // 2. count=2, u=1. One U-mode instruction and the ecall trap from U-mode
  //    count. The M-mode handler does not count. The trigger fires before
  //    the next U-mode instruction.
  li s1, 2
  li t0, MSTATUS_MPP_MASK
  csrc mstatus, t0
  la t0, u2_code
  csrw mepc, t0
  li t0, TDATA1_TYPE(TYPE_ICOUNT) | ICOUNT_COUNT(2) | ICOUNT_U
  csrw tdata1, t0
  mret
u2_code:
  addi s4, s4, 1
  ecall
u2_fire:
  addi s4, s4, 1
  li a0, 2
  j test_fail

phase3:
  // 3. count=3, s=1. An illegal instruction in S-mode traps to S-mode. The
  //    trap and the instructions of the S-mode handler count. The trigger
  //    fires before the third instruction of the handler. The breakpoint goes
  //    to M-mode.
  li s1, 3
  la t0, s_handler
  csrw stvec, t0
  li t0, 1 << CAUSE_ILLEGAL
  csrw medeleg, t0
  li t0, TDATA1_TYPE(TYPE_ICOUNT) | ICOUNT_COUNT(3) | ICOUNT_S
  csrw tdata1, t0
  li t0, MSTATUS_MPP_MASK
  csrc mstatus, t0
  li t0, MSTATUS_MPP_S
  csrs mstatus, t0
  la t0, s3_code
  csrw mepc, t0
  mret
s3_code:
  .word 0                    // illegal instruction
  li a0, 3
  j test_fail

  .align 4
s_handler:
  csrr s2, scause
  csrr s3, sepc
s_handler_3:
  li a0, 10                  // the trigger did not fire in the handler
  j test_fail

  .align 4
m_handler:
  csrr s2, mcause
  csrr s3, mepc
  li t2, 3
  beq s1, t2, m_phase3
  li t2, CAUSE_ECALL_U
  beq s2, t2, m_ecall_u
  csrw tdata1, zero
  li t2, CAUSE_BREAKPOINT
  CHECK_EQ(s2, t2, 4)
  csrr t1, mtval
  CHECK_EQ(t1, zero, 5)
  bnez s1, m_phase2

  // Phase 1
  la t2, u1_fire
  CHECK_EQ(s3, t2, 6)
  li t0, MSTATUS_MPP_MASK
  csrs mstatus, t0
  la t0, phase2
  csrw mepc, t0
  mret

m_ecall_u:
  // Phase 2: the ecall. Go back to U-mode after the ecall.
  addi s3, s3, 4
  csrw mepc, s3
  mret

m_phase2:
  la t2, u2_fire
  CHECK_EQ(s3, t2, 7)
  li t0, MSTATUS_MPP_MASK
  csrs mstatus, t0
  la t0, phase3
  csrw mepc, t0
  mret

m_phase3:
  // The trigger fires before s_handler_3
  csrw tdata1, zero
  li t2, CAUSE_BREAKPOINT
  CHECK_EQ(s2, t2, 8)
  la t2, s_handler_3
  CHECK_EQ(s3, t2, 9)
  j test_pass

TEST_PASS_FAIL

TEST_DATA
