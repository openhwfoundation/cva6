// Copyright 2026 10x Engineers
//
// Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
// You may obtain a copy of the License at https://solderpad.org/licenses/
//
// Issue #3622: tdata1 never holds dmode=0 with action=1.
// A write from M-mode cannot set dmode. Thus action=1 becomes action=0.

#include "sdtrig_test.h"

#define WRITE_READ_CHECK(wval, rval, n) \
  li t0, wval;                          \
  csrw tdata1, t0;                      \
  csrr t1, tdata1;                      \
  li t2, rval;                          \
  CHECK_EQ(t1, t2, n)

  .option norvc
  .section .text.init
  .global _start
_start:
  la t0, trap_handler
  csrw mtvec, t0
  // MIE=1 lets a breakpoint fire in M-mode on harts that use the MIE
  // reentrancy rule. No interrupt is enabled in mie.
  csrsi mstatus, MSTATUS_MIE
  csrw tselect, zero

  // 1. mcontrol6 with dmode=1 and action=1
  WRITE_READ_CHECK(TDATA1_TYPE(TYPE_MCONTROL6) | TDATA1_DMODE | MC6_ACTION(1) | MC6_M | MC6_EXECUTE,
                   TDATA1_TYPE(TYPE_MCONTROL6) | MC6_M | MC6_EXECUTE, 1)
  // 2. mcontrol6 with dmode=0 and action=1
  WRITE_READ_CHECK(TDATA1_TYPE(TYPE_MCONTROL6) | MC6_ACTION(1) | MC6_M | MC6_EXECUTE,
                   TDATA1_TYPE(TYPE_MCONTROL6) | MC6_M | MC6_EXECUTE, 2)
  // 3. icount with dmode=1 and action=1
  WRITE_READ_CHECK(TDATA1_TYPE(TYPE_ICOUNT) | TDATA1_DMODE | ICOUNT_COUNT(5) | ICOUNT_U | ACTION(1),
                   TDATA1_TYPE(TYPE_ICOUNT) | ICOUNT_COUNT(5) | ICOUNT_U, 3)
  // 4. etrigger with dmode=0 and action=1
  WRITE_READ_CHECK(TDATA1_TYPE(TYPE_ETRIGGER) | XTRIG_U | ACTION(1),
                   TDATA1_TYPE(TYPE_ETRIGGER) | XTRIG_U, 4)
  // 5. itrigger with dmode=1 and action=1
  WRITE_READ_CHECK(TDATA1_TYPE(TYPE_ITRIGGER) | TDATA1_DMODE | XTRIG_U | ACTION(1),
                   TDATA1_TYPE(TYPE_ITRIGGER) | XTRIG_U, 5)

  // 6. An execute trigger written with action=1 from M-mode gives a
  //    breakpoint exception on "target". It does not enter Debug Mode.
  la t0, target
  csrw tdata2, t0
  li t0, TDATA1_TYPE(TYPE_MCONTROL6) | MC6_ACTION(1) | MC6_M | MC6_EXECUTE
  csrw tdata1, t0
  li s0, 0
target:
  nop
  // The trap handler sets s0 to 1.
  li t2, 1
  CHECK_EQ(s0, t2, 6)
  j test_pass

  .align 4
trap_handler:
  // Disable the trigger, then do the checks of the trap.
  csrw tdata1, zero
  csrr t1, mcause
  li t2, CAUSE_BREAKPOINT
  CHECK_EQ(t1, t2, 7)
  csrr t1, mepc
  la t2, target
  CHECK_EQ(t1, t2, 8)
  li s0, 1
  mret

TEST_PASS_FAIL

TEST_DATA
