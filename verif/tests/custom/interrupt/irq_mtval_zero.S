# ------------------------------------------------------------------------------
#   Copyright 2026 Thales France
#
#   Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
#   You may obtain a copy of the License at https://solderpad.org/licenses/
# ------------------------------------------------------------------------------
#   irq_mtval_zero.S
#
#   An interrupt taken into M-mode must write zero to mtval.
#
#   The decoder puts the instruction encoding in ex.tval for every instruction,
#   so that an illegal CSR access found later can report it. When an interrupt
#   is attached to that instruction, the trap logic has to clear tval instead of
#   copying it. It knows the trap is an interrupt from the top bit of the cause,
#   bit XLEN-1.
#
#   The test fills mtval with a known non-zero value, asks for a machine
#   external interrupt with the deterministic hook irq_mei_hook, and checks
#   in the handler that mtval is zero and mcause is 11 with the interrupt bit.
#
#   It checks the clearing on targets with TvalEn=1 only: with TvalEn=0
#   mtval is always zero.
# ------------------------------------------------------------------------------

#include "encoding.h"

#define MIE_MEIE      (1 << 11)
#define MSTATUS_MIE_B (1 << 3)
#define SENTINEL      0x5A5A5A5A

    .text
    .option norvc

    .globl main
main:
    la   t0, trap_handler
    csrw mtvec, t0
    la   t0, irq_count
    sw   zero, 0(t0)

    # mtval starts with a value the interrupt must overwrite.
    li   t0, SENTINEL
    csrw mtval, t0

    li   t0, MIE_MEIE
    csrw mie, t0
    li   t0, MSTATUS_MIE_B
    csrs mstatus, t0

    # --------------------------------------------------------------------
    # Ask for the interrupt, then wait for it. Every instruction of the loop
    # carries its own encoding in ex.tval, so whichever one the interrupt
    # lands on, a trap that copies tval leaves a non-zero mtval.
    # --------------------------------------------------------------------
    .globl irq_mei_hook
irq_mei_hook:
    nop

    # Wait for the handler to count the interrupt, with a bound. The handler
    # does not touch t2: the interrupt may land between the two instructions
    # of the li below, and a value written by the handler would then be
    # overwritten by the addi that resumes after mret.
    li   t2, 4000
wait_loop:
    la   t0, irq_count
    lw   t1, 0(t0)
    bnez t1, wait_done
    addi t2, t2, -1
    bnez t2, wait_loop
wait_done:

    csrw mie, zero
    li   t0, MSTATUS_MIE_B
    csrc mstatus, t0

    la   t0, irq_count
    lw   t1, 0(t0)
    li   t3, 1
    bne  t1, t3, fail           # no interrupt, or more than one

    la   t0, seen_cause
#if __riscv_xlen == 64
    ld   t1, 0(t0)
#else
    lw   t1, 0(t0)
#endif
    li   t3, 1
    slli t3, t3, __riscv_xlen - 1
    ori  t3, t3, 11             # interrupt bit | machine external
    bne  t1, t3, fail

    la   t0, seen_mtval
    lw   t1, 0(t0)
    bnez t1, fail               # tval was copied instead of cleared
#if __riscv_xlen == 64
    lw   t1, 4(t0)
    bnez t1, fail
#endif

    li   a0, 0
    ret

fail:
    csrw mie, zero
    li   a0, 1
    ret

# ------------------------------------------------------------------------------
# s10 and s11 are scratch, main does not use them.
# ------------------------------------------------------------------------------
    .align 6
trap_handler:
    csrr s10, mcause
    la   s11, seen_cause
#if __riscv_xlen == 64
    sd   s10, 0(s11)
#else
    sw   s10, 0(s11)
#endif
    csrr s10, mtval
    la   s11, seen_mtval
#if __riscv_xlen == 64
    sd   s10, 0(s11)
#else
    sw   s10, 0(s11)
#endif

    la   s10, irq_count
    lw   s11, 0(s10)
    addi s11, s11, 1
    sw   s11, 0(s10)

    csrw mie, zero              # one interrupt only

    # An interrupt: mepc already points at the instruction to run again.
    mret

    .data
    .align 3
irq_count:
    .word 0
    .word 0
seen_cause:
    .dword 0
seen_mtval:
    .dword 0
