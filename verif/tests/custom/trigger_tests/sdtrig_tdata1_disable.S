// Copyright 2026 10x Engineers
//
// Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
// You may obtain a copy of the License at https://solderpad.org/licenses/
//
// Issue #3618: a write of 0 to tdata1 disables the trigger.
// A trigger that exists never reads back as type 0 ("no trigger").

#include "sdtrig_test.h"

  .option norvc
  .section .text.init
  .global _start
_start:
  la t0, trap_handler
  csrw mtvec, t0

  // 1. After reset, the type of trigger 0 to 3 is not 0.
  li s0, 0
  li s1, 4
1:
  csrw tselect, s0
  csrr t1, tselect
  CHECK_EQ(t1, s0, 1)
  csrr t1, tdata1
  srli t1, t1, XLEN - 4
  li a0, 2
  beqz t1, test_fail
  addi s0, s0, 1
  bne s0, s1, 1b

  // 2. Arm an execute trigger on "target", then write 0 to tdata1.
  csrw tselect, zero
  la t0, target
  csrw tdata2, t0
  li t0, TDATA1_TYPE(TYPE_MCONTROL6) | MC6_M | MC6_EXECUTE
  csrw tdata1, t0
  csrw tdata1, zero

  // 3. The trigger reads back as disabled (type 15).
  csrr t1, tdata1
  li t2, TDATA1_TYPE(TYPE_DISABLED)
  CHECK_EQ(t1, t2, 3)

  // 4. The trigger does not fire on "target".
  la t0, target
  jr t0
  .align 3
target:
  nop

  // 5. A write of type 15 reads back as type 15.
  li t0, TDATA1_TYPE(TYPE_DISABLED)
  csrw tdata1, t0
  csrr t1, tdata1
  CHECK_EQ(t1, t0, 5)

  // 6. A write of type 2 (not supported) does not give type 0.
  li t0, TDATA1_TYPE(2) | MC6_M | MC6_EXECUTE
  csrw tdata1, t0
  csrr t1, tdata1
  srli t1, t1, XLEN - 4
  li a0, 6
  beqz t1, test_fail

  j test_pass

  .align 4
trap_handler:
  // A trap is a fail. Code 7 gives the trap.
  li a0, 7
  j test_fail

TEST_PASS_FAIL

TEST_DATA
