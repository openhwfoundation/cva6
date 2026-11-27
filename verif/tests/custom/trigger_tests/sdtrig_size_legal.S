// Copyright 2026 10x Engineers
//
// Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
// You may obtain a copy of the License at https://solderpad.org/licenses/
//
// Issue #3689: the trigger module does not filter on the access size, so
// mcontrol6 size reads back as 0 (any size). A load address trigger written
// with size=1 (8-bit only) matches a load of XLEN bits.

#include "sdtrig_test.h"

#define MC6_LOAD           (1 << 0)
#define MC6_SIZE(s)        ((s) << 16)

  .option norvc
  .section .text.init
  .global _start
_start:
  la t0, trap_handler
  csrw mtvec, t0
  // MIE=1 lets a breakpoint fire in M-mode. No interrupt is enabled in mie.
  csrsi mstatus, MSTATUS_MIE
  csrw tselect, zero

  // 1. size=1 reads back as size=0
  li t0, TDATA1_TYPE(TYPE_MCONTROL6) | MC6_SIZE(1) | MC6_M | MC6_LOAD
  csrw tdata1, t0
  csrr t1, tdata1
  li t2, TDATA1_TYPE(TYPE_MCONTROL6) | MC6_M | MC6_LOAD
  CHECK_EQ(t1, t2, 1)

  // 2. The trigger matches a load of XLEN bits from the address in tdata2
  la t0, data
  csrw tdata2, t0
  li s0, 0
target:
  LREG t1, 0(t0)
  // The trap handler sets s0 to 1.
  li t2, 1
  CHECK_EQ(s0, t2, 2)
  j test_pass

  .align 4
trap_handler:
  // Disable the trigger, then do the checks of the trap.
  csrw tdata1, zero
  csrr t1, mcause
  li t2, CAUSE_BREAKPOINT
  CHECK_EQ(t1, t2, 3)
  csrr t1, mepc
  la t2, target
  CHECK_EQ(t1, t2, 4)
  li s0, 1
  addi t1, t1, 4
  csrw mepc, t1
  mret

TEST_PASS_FAIL

  .section .data
  .align 3
data:
  .dword 0x1122334455667788

TEST_DATA
