# ------------------------------------------------------------------------------
#   Copyright 2026 Thales France
#
#   Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
#   You may obtain a copy of the License at https://solderpad.org/licenses/
# ------------------------------------------------------------------------------
#   mbe_ro_zero.S
#
#   On a core without big endian support (BigEndianEn=0), the endianness
#   control bits are read-only zero: mstatus.MBE (mstatush.MBE on RV32),
#   mstatus.SBE (mstatush.SBE on RV32) and mstatus.UBE.
#
#   The test sets every one of them, checks they read back zero, and checks
#   that a word stored and read back with a byte access is little endian.
# ------------------------------------------------------------------------------

#include "encoding.h"

#define MSTATUSH        0x310
#define MSTATUSH_SBE    0x10
#define MSTATUSH_MBE    0x20
#define MSTATUS_UBE     0x40
#define MSTATUS_SBE_BIT 36
#define MSTATUS_MBE_BIT 37

    .text
    .globl main
main:

#if __riscv_xlen == 32
    li    t0, MSTATUSH_MBE | MSTATUSH_SBE
    csrs  MSTATUSH, t0
    csrr  t1, MSTATUSH
    and   t1, t1, t0
    bnez  t1, fail
#else
    li    t0, 1
    slli  t0, t0, MSTATUS_MBE_BIT
    li    t1, 1
    slli  t1, t1, MSTATUS_SBE_BIT
    or    t0, t0, t1
    csrs  mstatus, t0
    csrr  t1, mstatus
    and   t1, t1, t0
    bnez  t1, fail
#endif

    li    t0, MSTATUS_UBE
    csrs  mstatus, t0
    csrr  t1, mstatus
    and   t1, t1, t0
    bnez  t1, fail

    # data accesses stay little endian: the lowest address holds the least
    # significant byte
    la    t3, scratch
    li    t4, 0x12345678
    sw    t4, 0(t3)
    lbu   t5, 0(t3)
    li    t6, 0x78
    bne   t5, t6, fail

    li    a0, 0
    ret

fail:
    li    a0, 1
    ret

    .data
    .align 3
scratch:
    .zero 8
