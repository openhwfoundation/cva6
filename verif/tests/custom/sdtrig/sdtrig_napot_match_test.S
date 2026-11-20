# ------------------------------------------------------------------------------
#   Copyright 2026 Thales France
#
#   Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
#   You may obtain a copy of the License at https://solderpad.org/licenses/
# ------------------------------------------------------------------------------
#   sdtrig_napot_match_test.S
#
#   Checks the NAPOT range match of an mcontrol6 execute trigger against the
#   encoding of the privileged specification: tdata2 holds the base address
#   followed by a run of low ones, and n trailing ones select a range of
#   2^(n+1) bytes.
#
#   Checked, on an 8-byte range at range_base:
#     - a range based at a real code address matches at all, rather than being
#       rejected for having non-zero address bits;
#     - both words of the range match, range_base and range_base+4, so the
#       mask is not too narrow;
#     - range_base-4, inside the enclosing 16 bytes, does not match, so the
#       mask is not one bit too wide;
#     - range_base+8, just past the end, does not match.
#   Each case records mepc, so a fire on the wrong instruction is told from a
#   fire on the right one.
#
#   The trigger is disarmed inside the handler before returning, because a
#   range trigger armed in machine mode would otherwise match the handler's own
#   instructions and loop.
#
#   Requires Sdtrig, SdtrigMcontrol6, SdtrigMcontrol6ExecAddr and bit 1 of
#   SdtrigSupportedMatch.
# ------------------------------------------------------------------------------

#include "sdtrig_xlen.h"

    .text
    # The handler steps over the trapping instruction with mepc + 4, so every
    # instruction it can land on has to be four bytes wide.
    .option norvc

    .globl main
main:
    mv   s9, ra                 # arm_napot is called with jal
    la   t0, trap_handler
    csrw mtvec, t0
    la   t0, fire_count
    sw   zero, 0(t0)

    # --------------------------------------------------------------------
    # Inside the range: both words of range_in, range_in and range_in+4.
    #
    # tdata2 = range_in | 0b011: two trailing ones, so 2^3 = 8 bytes. The
    # handler disarms the trigger on each fire, so it is armed again before
    # the second word. Reaching it by a jump keeps range_in out of the way.
    # --------------------------------------------------------------------
    la   a0, range_in
    jal  ra, arm_napot
    j    range_in

    .align 3
range_in:
    nop                         # range_in + 0: must trap
in_word1:
    nop                         # range_in + 4: must trap once re-armed
    j    in_done

    # first fire: on range_in, then re-arm and run the second word
in_rearm:
    la   a0, range_in
    jal  ra, arm_napot
    j    in_word1

in_done:
    li   t2, 2
    la   t0, fire_count
    lw   t1, 0(t0)
    bne  t1, t2, fail           # both words of the range must fire
    la   t0, fire_pc
    LREG t1, 0(t0)
    la   t2, range_in
    bne  t1, t2, fail           # first fire on the base
    LREG t1, REGBYTES(t0)
    la   t2, in_word1
    bne  t1, t2, fail           # second fire on base + 4

    # --------------------------------------------------------------------
    # Outside the range: range_out - 4 and range_out + 8.
    #
    # range_out is 8-byte aligned and sits 8 bytes into a 16-byte block, so
    # range_out - 4 is inside the enclosing 16-byte range (it would match if
    # the mask ignored one bit too many) and range_out + 8 is the first word
    # past the end. Neither may fire.
    # --------------------------------------------------------------------
    la   t0, fire_count
    sw   zero, 0(t0)
    la   a0, range_out
    jal  ra, arm_napot
    j    below_range

    .align 4
below_range:                    # range_out - 4: outside
    nop
    j    above_range

    .align 3
range_out:                      # the range, not executed
    nop
    nop
above_range:                    # range_out + 8: outside
    nop

    # Disarm before checking, so a spurious match cannot loop.
    csrw 0x7a0, zero
    csrw 0x7a1, zero

    la   t0, fire_count
    lw   t1, 0(t0)
    bnez t1, fail               # fired outside the 8-byte range

    # --------------------------------------------------------------------
    mv   ra, s9
    li a0, 0
    ret

fail:
    # Disarm on the way out, otherwise an armed range trigger keeps firing.
    li   t0, 0
    csrw 0x7a0, t0
    csrw 0x7a1, zero
    mv   ra, s9
    li a0, 1
    ret

    # --------------------------------------------------------------------
    # Arms trigger 0 as an 8-byte NAPOT execute range at a0 (8-byte aligned).
    # type 6, match 1 (NAPOT) in [10:7], m in [6], execute in [2], action 0.
    # --------------------------------------------------------------------
arm_napot:
    csrw 0x7a0, zero            # tselect = 0
    ori  a0, a0, 0x3            # two trailing ones: 8-byte range
    csrw 0x7a2, a0
    li   a0, TDATA1_VAL(6, 0, 0, 0x00000c4)
    csrw 0x7a1, a0
    ret

    # --------------------------------------------------------------------
    # Counts breakpoint traps, records mepc, disarms the trigger that fired,
    # and steps over the instruction that trapped. The first fire on
    # range_in resumes at in_rearm, to arm the trigger again for the second
    # word.
    # --------------------------------------------------------------------
    .align 6
trap_handler:
    addi sp, sp, -16
    sw   t0, 0(sp)
    sw   t1, 4(sp)

    csrr t0, mcause
    li   t1, 3                  # breakpoint
    bne  t0, t1, handler_out

    # Disarm trigger 0 first: a range trigger left armed in machine mode
    # matches the handler itself, and the loop would never end.
    csrw 0x7a0, zero
    csrw 0x7a1, zero

    # fire_pc[fire_count] = mepc, while there is room for it
    la   t0, fire_count
    lw   t1, 0(t0)
    li   t0, 2
    bgeu t1, t0, 1f
    slli t0, t1, (REGBYTES / 4 + 1)
    la   t1, fire_pc
    add  t1, t1, t0
    csrr t0, mepc
    SREG t0, 0(t1)
1:
    la   t0, fire_count
    lw   t1, 0(t0)
    addi t1, t1, 1
    sw   t1, 0(t0)

    # A fire on range_in resumes at in_rearm, any other at mepc + 4.
    csrr t0, mepc
    la   t1, range_in
    bne  t0, t1, 2f
    la   t0, in_rearm
    csrw mepc, t0
    j    handler_out
2:
    addi t0, t0, 4
    csrw mepc, t0

handler_out:
    lw   t0, 0(sp)
    lw   t1, 4(sp)
    addi sp, sp, 16
    mret

    .data
    .align 2
fire_count:
    .word 0
    .align 3
fire_pc:
    PTRWORD 0, 0
