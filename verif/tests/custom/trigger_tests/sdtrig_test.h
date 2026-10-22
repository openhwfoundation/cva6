// Copyright 2026 10x Engineers
//
// Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
// You may obtain a copy of the License at https://solderpad.org/licenses/
//
// Common definitions for the Sdtrig tests. The tests are the same for RV32
// and RV64. A test writes 1 to tohost when it passes. When check N fails, it
// writes (N << 1) | 1 to tohost.

#ifndef SDTRIG_TEST_H
#define SDTRIG_TEST_H

#if __riscv_xlen == 64
#define XLEN 64
#define SREG sd
#define LREG ld
#else
#define XLEN 32
#define SREG sw
#define LREG lw
#endif

#define CSR_TSELECT 0x7a0
#define CSR_TDATA1  0x7a1
#define CSR_TDATA2  0x7a2

// tdata1 fields common to all types
#define TDATA1_TYPE(t)     ((t) << (XLEN - 4))
#define TDATA1_DMODE       (1 << (XLEN - 5))
#define TYPE_ICOUNT        3
#define TYPE_ITRIGGER      4
#define TYPE_ETRIGGER      5
#define TYPE_MCONTROL6     6
#define TYPE_DISABLED      15

// mcontrol6
#define MC6_ACTION(a)      ((a) << 12)
#define MC6_M              (1 << 6)
#define MC6_S              (1 << 4)
#define MC6_U              (1 << 3)
#define MC6_EXECUTE        (1 << 2)

// icount
#define ICOUNT_COUNT(c)    ((c) << 10)
#define ICOUNT_M           (1 << 9)
#define ICOUNT_S           (1 << 7)
#define ICOUNT_U           (1 << 6)

// itrigger and etrigger
#define XTRIG_M            (1 << 9)
#define XTRIG_S            (1 << 7)
#define XTRIG_U            (1 << 6)

// action field of icount, itrigger and etrigger
#define ACTION(a)          (a)

#define MSTATUS_MIE        (1 << 3)
#define MSTATUS_SIE        (1 << 1)
#define MSTATUS_SPP        (1 << 8)
#define MSTATUS_MPP_MASK   (3 << 11)
#define MSTATUS_MPP_S      (1 << 11)
#define MIP_SSIP           (1 << 1)
#define MIP_MTIP           (1 << 7)
#define MCAUSE_INT         (1 << (XLEN - 1))

#define CAUSE_ILLEGAL      2
#define CAUSE_BREAKPOINT   3
#define CAUSE_ECALL_U      8
#define CAUSE_ECALL_M      11

#define CLINT_MTIMECMP     0x02004000
#define CLINT_MTIME        0x0200bff8

// Check a condition. When it is not true, stop the test with code n.
#define CHECK_EQ(r1, r2, n) \
  li a0, n;                 \
  bne r1, r2, test_fail

// Give all of the address space to S-mode and U-mode with one PMP entry.
#define PMP_ALLOW_ALL       \
  li t0, -1;                \
  csrw pmpaddr0, t0;        \
  li t0, 0x1f;              \
  csrw pmpcfg0, t0

// Write the result to tohost. The test stops here.
#define TEST_PASS_FAIL      \
test_pass:                  \
  li a0, 1;                 \
  j test_end;               \
test_fail:                  \
  slli a0, a0, 1;           \
  ori a0, a0, 1;            \
test_end:                   \
  la t0, tohost;            \
  sw a0, 0(t0);             \
  sw zero, 4(t0);           \
1:                          \
  j 1b

#define TEST_DATA                       \
  .section .tohost, "aw", @progbits;    \
  .align 6;                             \
  .global tohost;                       \
tohost: .dword 0;                       \
  .align 6;                             \
  .global fromhost;                     \
fromhost: .dword 0

#endif
