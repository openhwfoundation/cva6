# ------------------------------------------------------------------------------
#   Copyright 2026 Thales France
#
#   Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
#   You may obtain a copy of the License at https://solderpad.org/licenses/
# ------------------------------------------------------------------------------
#   sdtrig_etrigger.S
#
#   etrigger: fires on the cause of an exception rather than on an address or a
#   value. tdata2 is a bitmask indexed by exception cause, so bit 2 selects an
#   illegal instruction.
#
#   An illegal instruction is used rather than an ecall: it raises its
#   exception without a privilege transition.
#
#   The trigger replaces the exception it matched, so the handler sees cause 3,
#   the breakpoint, instead of cause 2: that substitution is what the test checks.
#
#   tdata1 layout for etrigger on RV32, as the module decodes it:
#     [31:28] type = 5   [27] dmode   [26] hit
#     [9] m   [7] s   [6] u   [5:0] action
#
#   On disarming: every trigger type's logic sits under "type == N" in the
#   module, including the branch that latches hit and the one that clears the
#   internal match flag. Writing tdata1 to zero changes the type, those branches
#   stop running, the match flag stays set and the trigger re-fires on the
#   handler's own first instruction forever. So the handler leaves the type in
#   place and empties the cause mask instead.
#
#   Requires Sdtrig and SdtrigEtrigger.
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
    # Arm on illegal instruction, cause 2, then execute one.
    #
    # tdata1 = type 5, m, action 0: (5 << 28) | (1 << 9) = 0x50000200
    # tdata2 = 1 << 2 = 0x4
    # --------------------------------------------------------------------
    li   t0, 0
    csrw 0x7a0, t0              # tselect = 0

    li   t1, 0x4                # cause 2, illegal instruction
    csrw 0x7a2, t1

    li   t1, TDATA1_VAL(5, 0, 0, 0x0000200)
    csrw 0x7a1, t1

    .word 0x00000000            # illegal: traps, reported as a breakpoint

    # --------------------------------------------------------------------
    # The handler emptied the cause mask, so nothing is armed any more.
    # --------------------------------------------------------------------
    la   t0, break_count
    lw   t1, 0(t0)
    li   t2, 1
    bne  t1, t2, fail           # the cause was substituted exactly once

    # --------------------------------------------------------------------
    # With the cause mask empty, a second illegal instruction must trap with its
    # own cause, 2, untouched. This separates a working mask from one matching
    # anything.
    # --------------------------------------------------------------------
    la   t0, seen_cause
    sw   zero, 0(t0)

    .word 0x00000000            # illegal again

    la   t0, seen_cause
    lw   t1, 0(t0)
    li   t2, 2                  # original cause, the trigger staying out
    bne  t1, t2, fail

    la   t0, break_count
    lw   t1, 0(t0)
    li   t2, 1
    bne  t1, t2, fail           # no new substitution with the mask emptied

    # --------------------------------------------------------------------
    li a0, 0
    ret

fail:
    csrw 0x7a2, zero            # empty the mask, keep the type
    li a0, 1
    ret

    # --------------------------------------------------------------------
    # Records the cause it was entered with, steps over the instruction, and empties
    # the cause mask so the trigger cannot match again. The type is left at 5,
    # see the note at the top of the file.
    #
    # s10 and s11 are scratch, main does not use them.
    # --------------------------------------------------------------------
    .align 6
trap_handler:
    # The trigger is still armed when the handler starts, and the module needs a
    # cycle to make its latched hit bit visible, so it fires once more on
    # whatever instruction lands here first. Absorb that with nops before doing
    # anything that matters, then empty the cause mask.
    nop
    nop
    nop
    csrw 0x7a2, zero            # empty cause mask: cannot match again

    csrr s10, mcause
    la   s11, seen_cause
    sw   s10, 0(s11)

    # Count breakpoints separately from every other cause. The module re-enters
    # the handler once on its own, the internal match flag still being set when
    # the handler starts, so a total trap count says nothing. What matters is how
    # many times the cause was substituted.
    li   s11, 3
    bne  s10, s11, not_a_break
    la   s10, break_count
    lw   s11, 0(s10)
    addi s11, s11, 1
    sw   s11, 0(s10)
not_a_break:

    csrr s10, mepc
    addi s10, s10, 4
    csrw mepc, s10
    # The nested entry's mret left MPP at U: return to M-mode, where main runs.
    li   s10, 0x1800
    csrs mstatus, s10
    mret

    .data
    .align 2
break_count:
    .word 0
seen_cause:
    .word 0
