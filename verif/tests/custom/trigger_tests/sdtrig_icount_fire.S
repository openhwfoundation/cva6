// Copyright 2026 10x Engineers
//
// Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
// You may obtain a copy of the License at https://solderpad.org/licenses/
//
// Issue #3647: icount fires on the next instruction to execute. mepc holds
// the address of this instruction. A trigger with count=0 does not fire.

#include "sdtrig_test.h"

  .option norvc
  .section .text.init
  .global _start
_start:
  la t0, m_handler
  csrw mtvec, t0
  // MIE=1 lets a breakpoint fire in M-mode on harts that use the MIE
  // reentrancy rule. No interrupt is enabled in mie.
  csrsi mstatus, MSTATUS_MIE
  li s0, 0x80
  csrw tselect, zero
  li s1, 0                   // test phase
  la s5, scratch

  // 1. count=0. The trigger does not fire.
  li t0, TDATA1_TYPE(TYPE_ICOUNT) | ICOUNT_COUNT(0) | ICOUNT_M
  csrw tdata1, t0
  .rept 20
  nop
  .endr
  csrw tdata1, zero

  // 2. count=1. The write to tdata1 does not count. The csrr counts.
  //    The trigger fires before the store.
  li s1, 2
  li t0, TDATA1_TYPE(TYPE_ICOUNT) | ICOUNT_COUNT(1) | ICOUNT_M
  csrw tdata1, t0
  csrr t1, mstatus
p2_fire:
  SREG t1, 0(s5)
  li a0, 1
  j test_fail

phase3:
  // 3. count=2. The trigger fires before the second addi.
  li s1, 3
  li t0, TDATA1_TYPE(TYPE_ICOUNT) | ICOUNT_COUNT(2) | ICOUNT_M
  csrw tdata1, t0
  csrr t1, mstatus
  addi s4, s4, 1
p3_fire:
  addi s4, s4, 1
  li a0, 2
  j test_fail

  .align 4
m_handler:
  csrr s2, mcause
  csrr s3, mepc
  csrr s6, mtval
  csrw tdata1, zero
  li t2, CAUSE_BREAKPOINT
  CHECK_EQ(s2, t2, 3)
  CHECK_EQ(s6, zero, 4)
  li t2, 2
  bne s1, t2, m_phase3
  la t2, p2_fire
  CHECK_EQ(s3, t2, 5)
  la t0, phase3
  csrw mepc, t0
  mret

m_phase3:
  li t2, 3
  CHECK_EQ(s1, t2, 6)
  la t2, p3_fire
  CHECK_EQ(s3, t2, 7)
  j test_pass

TEST_PASS_FAIL

  .data
  .align 3
scratch:
  .dword 0

TEST_DATA
