# ------------------------------------------------------------------------------
#   Copyright 2026 Thales France
#
#   Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
#   You may obtain a copy of the License at https://solderpad.org/licenses/
# ------------------------------------------------------------------------------
#   load_bus_error.S
#
#   A load whose response carries an error raises a HARDWARE_ERROR exception
#   (cause 19), with mepc at the load. The testbench answers the load from
#   load_err_word with the error bit set, once.
#
#   A misaligned load issued right after it must keep its own cause
#   (LOAD_ADDR_MISALIGNED, 4) and not take the hardware error.
#
#   Requires the OBI testbench, which provides the error response.
# ------------------------------------------------------------------------------

#include "encoding.h"

#if __riscv_xlen == 64
#define LREG ld
#define SREG sd
#define REGB 8
#else
#define LREG lw
#define SREG sw
#define REGB 4
#endif

#define CAUSE_HW_ERROR 19

    .text
    .option norvc
    .globl main
main:
    la    t0, trap_handler
    csrw  mtvec, t0
    la    s2, load_err_word
    la    s3, misaligned_word

    # back to back: the errored load, then a misaligned one
err_load:
    lw    t1, 0(s2)
mis_load:
    lw    t2, 1(s3)

    # both trapped, in program order, each with its own cause
    la    t0, trap_count
    LREG  t1, 0(t0)
    li    t2, 2
    bne   t1, t2, fail
    LREG  t1, 1*REGB(t0)
    li    t2, CAUSE_HW_ERROR
    bne   t1, t2, fail
    LREG  t1, 2*REGB(t0)
    la    t2, err_load
    bne   t1, t2, fail
    LREG  t1, 3*REGB(t0)
    li    t2, CAUSE_MISALIGNED_LOAD
    bne   t1, t2, fail
    LREG  t1, 4*REGB(t0)
    la    t2, mis_load
    bne   t1, t2, fail

    li    a0, 0
    ret
fail:
    li    a0, 1
    ret

    # records mcause and mepc of each trap and steps over the load
    .align 6
trap_handler:
    la    s10, trap_count
    LREG  s11, 0(s10)
    slli  s9, s11, 1            # two registers per trap
    addi  s9, s9, 1             # after the count
    slli  s9, s9, (REGB / 4 + 1)
    add   s9, s9, s10
    csrr  t3, mcause
    SREG  t3, 0(s9)
    csrr  t3, mepc
    SREG  t3, REGB(s9)
    addi  s11, s11, 1
    SREG  s11, 0(s10)
    csrr  t3, mepc
    addi  t3, t3, 4
    csrw  mepc, t3
    mret

    .data
    .align 3
    .globl load_err_word
load_err_word:
    .word 0x12345678
misaligned_word:
    .word 0, 0
    .align 3
trap_count:
    .zero 5 * 8
