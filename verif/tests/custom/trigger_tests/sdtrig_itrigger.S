// Copyright 2026 10x Engineers
//
// Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
// You may obtain a copy of the License at https://solderpad.org/licenses/
//
// Issue #3646: an itrigger fires after the interrupt trap, just before the
// first instruction of the trap handler. The breakpoint writes 0 to tval.

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
  csrw satp, zero
  PMP_ALLOW_ALL
  li s1, 0                   // test phase

  // 1. Interrupt 1 (supervisor software) is selected for U-mode. The
  //    interrupt is delegated to S-mode. The trigger fires just before the
  //    first instruction of the S-mode handler. The breakpoint goes to M-mode.
  csrw tselect, zero
  li t0, 1 << 1
  csrw tdata2, t0
  li t0, TDATA1_TYPE(TYPE_ITRIGGER) | XTRIG_U
  csrw tdata1, t0
  li t0, MIP_SSIP
  csrw mideleg, t0
  csrw mie, t0
  csrs mip, t0
  li t0, MSTATUS_MPP_MASK
  csrc mstatus, t0
  la t0, u_code
  csrw mepc, t0
  mret

u_code:
  nop
  li a0, 1
  j test_fail

s_code:
  nop
  li a0, 9
  j test_fail

  .align 4
s_handler:
  li a0, 2
  j test_fail

  .align 4
m_handler:
  csrr s2, mcause
  csrr s3, mepc
  csrr s4, mtval
  csrw tdata1, zero
  li t2, CAUSE_BREAKPOINT
  CHECK_EQ(s2, t2, 4)
  CHECK_EQ(s4, zero, 5)

  // Phase 1 and 1b: the breakpoint is on the first instruction of the S-mode handler.
  la t2, s_handler
  CHECK_EQ(s3, t2, 6)
  csrr t1, scause
  li t2, MCAUSE_INT | 1
  CHECK_EQ(t1, t2, 7)
  bnez s1, 1f

  // 1b. The same interrupt is taken from S-mode to S-mode. The trigger with
  //     s=1 fires just before the first instruction of the S-mode handler.
  li s1, 1
  li t0, TDATA1_TYPE(TYPE_ITRIGGER) | XTRIG_S
  csrw tdata1, t0
  li t0, MSTATUS_MPP_MASK
  csrc mstatus, t0
  li t0, MSTATUS_MPP_S | MSTATUS_SIE
  csrs mstatus, t0
  la t0, s_code
  csrw mepc, t0
  mret

1:
  li t0, MSTATUS_SIE
  csrc mstatus, t0
  li t0, MIP_SSIP
  csrc mip, t0
  csrw mie, zero
  j test_pass

TEST_PASS_FAIL

TEST_DATA
