# ------------------------------------------------------------------------------
#   Copyright 2026 Thales France
#
#   Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
#   You may obtain a copy of the License at https://solderpad.org/licenses/
# ------------------------------------------------------------------------------
#   mcause_warl.S
#
#   mcause is WARL. The core keeps the interrupt bit, bit XLEN-1, and the
#   five low bits of the exception code, which hold every cause it can
#   raise. A write of any other bit reads back as zero.
#
#   The test writes all ones and checks the read value is the interrupt bit
#   and 0x1f. It then writes a value with only middle bits set and checks
#   it reads back as zero.
# ------------------------------------------------------------------------------

    .text
    .globl main
main:
    csrr s0, mcause             # keep the value to restore

    li   t0, -1
    csrw mcause, t0
    csrr t1, mcause
    li   t2, 1
    slli t2, t2, __riscv_xlen - 1
    ori  t2, t2, 0x1f
    bne  t1, t2, fail

    li   t0, 0x7fe0
    csrw mcause, t0
    csrr t1, mcause
    bnez t1, fail

    csrw mcause, s0
    li   a0, 0
    ret

fail:
    csrw mcause, s0
    li   a0, 1
    ret
