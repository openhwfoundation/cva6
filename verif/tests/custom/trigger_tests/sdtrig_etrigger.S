// Copyright 2026 10x Engineers
//
// Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
// You may obtain a copy of the License at https://solderpad.org/licenses/
//
// Issue #3620: an etrigger fires only after an exception trap.
// It does not fire when no trap occurs. It does not fire on an interrupt.

#include "sdtrig_test.h"

  .option norvc
  .section .text.init
  .global _start
_start:
  la t0, m_handler
  csrw mtvec, t0
  la t0, s_handler
  csrw stvec, t0
  csrw medeleg, zero
  csrw mideleg, zero
  csrw satp, zero
  PMP_ALLOW_ALL
  li s1, 0                   // number of M-mode traps

  // 1. Exception code 0 is selected. No trap occurs. The trigger does not fire.
  csrw tselect, zero
  li t0, 1
  csrw tdata2, t0
  li t0, TDATA1_TYPE(TYPE_ETRIGGER) | XTRIG_M
  csrw tdata1, t0
  .rept 20
  nop
  .endr
  CHECK_EQ(s1, zero, 1)

  // 2. Exception code 7 is selected. A machine timer interrupt (code 7)
  //    occurs. The trigger does not fire.
  li t0, 1 << 7
  csrw tdata2, t0
  li t0, CLINT_MTIMECMP
  sw zero, 0(t0)
  sw zero, 4(t0)
  li t0, MIP_MTIP
  csrw mie, t0
  csrsi mstatus, MSTATUS_MIE
  li t3, 200
1:
  addi t3, t3, -1
  bnez t3, 1b
  csrci mstatus, MSTATUS_MIE
  csrw mie, zero
  // One trap only: the interrupt.
  li t2, 1
  CHECK_EQ(s1, t2, 2)
  li t2, MCAUSE_INT | 7
  CHECK_EQ(s2, t2, 3)

  // 3. Exception code 2 is selected for U-mode. An illegal instruction in
  //    U-mode traps to S-mode. The trigger fires just before the first
  //    instruction of the S-mode handler. The breakpoint goes to M-mode.
  li s1, 0
  li s3, 0                   // 0: part 3, 1: part 4
  li t0, 1 << CAUSE_ILLEGAL
  csrw tdata2, t0
  li t0, TDATA1_TYPE(TYPE_ETRIGGER) | XTRIG_U
  csrw tdata1, t0
  li t0, 1 << CAUSE_ILLEGAL
  csrw medeleg, t0
  li t0, MSTATUS_MPP_MASK
  csrc mstatus, t0
  la t0, u_code
  csrw mepc, t0
  mret

u_code:
  .word 0                    // illegal instruction
  li a0, 4
  j test_fail

s_code:
  .word 0                    // illegal instruction
  li a0, 11
  j test_fail

  .align 4
s_handler:
  li a0, 5
  j test_fail

  .align 4
m_handler:
  addi s1, s1, 1
  csrr s2, mcause
  bltz s2, m_interrupt
  csrw tdata1, zero
  li t2, CAUSE_BREAKPOINT
  CHECK_EQ(s2, t2, 6)
  csrr t1, mepc
  la t2, s_handler
  CHECK_EQ(t1, t2, 7)
  csrr t1, mtval
  CHECK_EQ(t1, zero, 10)
  csrr t1, scause
  li t2, CAUSE_ILLEGAL
  CHECK_EQ(t1, t2, 8)
  csrr t1, sepc
  la t2, u_code
  beqz s3, 1f
  la t2, s_code
1:
  CHECK_EQ(t1, t2, 9)
  bnez s3, test_pass

  // 4. Exception code 2 is selected for S-mode. An illegal instruction in
  //    S-mode traps to S-mode. The trigger fires just before the first
  //    instruction of the S-mode handler. The breakpoint goes to M-mode.
  li s3, 1
  li t0, TDATA1_TYPE(TYPE_ETRIGGER) | XTRIG_S
  csrw tdata1, t0
  li t0, MSTATUS_MPP_MASK
  csrc mstatus, t0
  li t0, MSTATUS_MPP_S
  csrs mstatus, t0
  la t0, s_code
  csrw mepc, t0
  mret

m_interrupt:
  li t0, CLINT_MTIMECMP
  li t1, -1
  sw t1, 0(t0)
  sw t1, 4(t0)
  mret

TEST_PASS_FAIL

TEST_DATA
