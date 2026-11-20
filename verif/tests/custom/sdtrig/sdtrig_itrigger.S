# ------------------------------------------------------------------------------
#   Copyright 2026 Thales France
#
#   Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
#   You may obtain a copy of the License at https://solderpad.org/licenses/
# ------------------------------------------------------------------------------
#   sdtrig_itrigger.S
#
#   itrigger: fires on the cause of an interrupt, the asynchronous counterpart of
#   etrigger. tdata2 is a bitmask indexed by the low bits of the cause, so bit 11
#   selects a machine external interrupt.
#
#   The interrupt is deterministic. This test defines irq_mei_hook and calls it;
#   the interrupt agent raises irq[0] a fixed number of cycles after that label
#   retires, which puts the interrupt where the test needs it. That control is
#   required here rather than convenient: the module only fires this trigger once
#   an mret has been seen,
#
#     e_matched_q && priv_match && mret_reg_q && (commit_ack != 0)
#
#   so the interrupt has to arrive after the test has taken and returned from an
#   unrelated trap. A randomly timed interrupt lands before that and is lost.
#
#   What is checked is the substitution: the handler must see cause 3, the
#   breakpoint, instead of cause 11. A trigger that fired without replacing the
#   cause would be indistinguishable from no trigger at all.
#
#   tdata1 layout for itrigger on RV32, as the module decodes it:
#     [31:28] type = 4   [27] dmode   [26] hit
#     [9] m   [7] s   [6] u   [5:0] action
#
#   Disarming keeps the type at 4 and sets hit: the whole itrigger block of the
#   module sits under "type == 4", including the branch that latches hit, so
#   writing tdata1 to zero would strand the state and the trigger would keep
#   firing.
# ------------------------------------------------------------------------------

#include "sdtrig_xlen.h"

    .text
    .option norvc

    .globl main
main:
    la   t0, trap_handler
    csrw mtvec, t0
    la   t0, break_count
    sw   zero, 0(t0)
    la   t0, seen_cause
    sw   zero, 0(t0)

    # --------------------------------------------------------------------
    # Take an unrelated trap and return from it, so mret_reg is set.
    # --------------------------------------------------------------------
    .word 0x00000000            # illegal instruction

    # --------------------------------------------------------------------
    # Arm the itrigger on machine external interrupt, cause 11.
    #   tdata1 = (4 << 28) | (1 << 9) = 0x40000200
    #   tdata2 = 1 << 11 = 0x800
    # --------------------------------------------------------------------
    li   t0, 0
    csrw 0x7a0, t0              # tselect = 0
    li   t1, 0x800
    csrw 0x7a2, t1
    li   t1, TDATA1_VAL(4, 0, 0, 0x0000200)
    csrw 0x7a1, t1

    # Let machine external interrupts through.
    li   t1, 0x800              # MEIE
    csrw mie, t1
    li   t1, 0x8                # MIE
    csrs mstatus, t1

    # --------------------------------------------------------------------
    # Ask for the interrupt, then wait for it. The handler cuts the loop short.
    # --------------------------------------------------------------------
    .globl irq_mei_hook
irq_mei_hook:
    nop

    #  Generous: the interrupt arrives a few tens of cycles in, and the loop
    #  costs nothing on a test this short.
    li   t2, 4000
wait_loop:
    addi t2, t2, -1
    bnez t2, wait_loop

    # --------------------------------------------------------------------
    la   t0, break_count
    lw   t1, 0(t0)
    beqz t1, fail               # nothing fired: the trigger never matched

    la   t0, seen_cause
    lw   t1, 0(t0)
    li   t2, 3                  # breakpoint, not 11
    bne  t1, t2, fail           # the trigger did not replace the cause

    li a0, 0
    ret

fail:
    li   t1, TDATA1_VAL(4, 0, 1, 0x0000200)         # type 4 kept, hit set
    csrw 0x7a0, zero
    csrw 0x7a1, t1
    csrw mie, zero
    li a0, 1
    ret

    # --------------------------------------------------------------------
    # s10 and s11 are scratch, main does not use them.
    # --------------------------------------------------------------------
    .align 6
trap_handler:
    csrr s10, mcause
    la   s11, seen_cause
    sw   s10, 0(s11)

    li   s11, 3
    bne  s10, s11, warmup_trap

    la   s10, break_count
    lw   s11, 0(s10)
    addi s11, s11, 1
    sw   s11, 0(s10)

    li   s10, TDATA1_VAL(4, 0, 1, 0x0000200)        # spend the trigger: type kept, hit set
    csrw 0x7a0, zero
    csrw 0x7a1, s10
    csrw mie, zero
    li   t2, 1                  # leave the wait loop

    # An itrigger fires on an interrupt: mepc holds the interrupted instruction,
    # which has to be re-executed. Only the synchronous warm-up trap advances mepc.
    mret

warmup_trap:
    csrr s10, mepc
    addi s10, s10, 4
    csrw mepc, s10
    mret

    .data
    .align 2
break_count:
    .word 0
seen_cause:
    .word 0
