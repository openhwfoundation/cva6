# ------------------------------------------------------------------------------
#   Copyright 2026 Thales France
#
#   Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
#   You may obtain a copy of the License at https://solderpad.org/licenses/
# ------------------------------------------------------------------------------
#   sdtrig_mcontrol6_exec_data.S
#
#   mcontrol6 execute trigger with select = 1, which compares the instruction
#   word itself rather than the address it sits at. Useful to break on every
#   occurrence of a given opcode wherever it appears, as opposed to one
#   particular site.
#
#   The distinction from select = 0 is the point of the test: the same encoding
#   is placed at two different addresses and both must fire, which an address
#   comparison could not do with a single trigger.
#
#   tdata1 layout for mcontrol6 on RV32, as the module decodes it:
#     [31:28] type = 6      [22] hit0     [21] select    [18:16] size
#     [15:12] action        [11] chain    [10:7] match   [6] m
#     [4] s   [3] u   [2] execute   [1] store   [0] load
#
#   Disarming keeps the type at 6 and clears the operation bits: every trigger
#   type's logic sits under "type == N" in the module, so writing tdata1 to zero
#   strands the internal state and the trigger keeps firing.
#
#   Requires Sdtrig, SdtrigMcontrol6 and SdtrigMcontrol6ExecData.
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

    # --------------------------------------------------------------------
    # Watch the encoding of "addi x28, x0, 0x123", which is 0x12300e13, and
    # place that exact instruction twice at different addresses. Both must
    # fire, since the trigger matches the word and not the location.
    #
    # x28 is t3, chosen because nothing else in this test uses it.
    # --------------------------------------------------------------------
    li   t0, 0
    csrw 0x7a0, t0              # tselect = 0

    li   t1, 0x12300e13         # addi t3, zero, 0x123
    csrw 0x7a2, t1              # tdata2 = the instruction word to watch

    # type 6, match 0, m in [6], execute in [2], action 0, select = 1 in [21]
    li   t1, TDATA1_VAL(6, 0, 0, 0x0200044)
    csrw 0x7a1, t1

first_site:
    addi t3, zero, 0x123        # must trap

    la   t0, break_count
    lw   t1, 0(t0)
    li   t2, 1
    bne  t1, t2, fail           # the first occurrence did not fire

    # Re-arm for the second occurrence: the handler disarmed to get us here.
    li   t0, 0
    csrw 0x7a0, t0
    li   t1, 0x12300e13
    csrw 0x7a2, t1
    li   t1, TDATA1_VAL(6, 0, 0, 0x0200044)
    csrw 0x7a1, t1

second_site:
    addi t3, zero, 0x123        # same encoding, different address: must trap too

    la   t0, break_count
    lw   t1, 0(t0)
    li   t2, 2
    bne  t1, t2, fail           # the second occurrence did not fire

    # --------------------------------------------------------------------
    # A different instruction must not fire, which separates a working word
    # comparison from one firing on every instruction.
    # --------------------------------------------------------------------
    la   t0, break_count
    sw   zero, 0(t0)

    li   t0, 0
    csrw 0x7a0, t0
    li   t1, 0x12300e13
    csrw 0x7a2, t1
    li   t1, TDATA1_VAL(6, 0, 0, 0x0200044)
    csrw 0x7a1, t1

    addi t3, zero, 0x456        # a different encoding
    nop
    nop

    # Disarm: keep the type, drop the operation bits.
    li   t1, TDATA1_VAL(6, 0, 0, 0x0200040)
    csrw 0x7a1, t1

    la   t0, break_count
    lw   t1, 0(t0)
    bnez t1, fail               # fired on an instruction it was not watching

    li   t2, 0x456
    bne  t3, t2, fail           # that instruction was supposed to execute

    # --------------------------------------------------------------------
    li a0, 0
    ret

fail:
    li   t1, TDATA1_VAL(6, 0, 0, 0x0200040)         # keep the type, drop the operation bits
    csrw 0x7a1, t1
    li a0, 1
    ret

    # --------------------------------------------------------------------
    # Counts breakpoints, disarms the trigger, steps over the instruction that
    # trapped. s10 and s11 are scratch, main does not use them.
    # --------------------------------------------------------------------
    .align 6
trap_handler:
    li   s10, TDATA1_VAL(6, 0, 0, 0x0200040)        # type 6 kept, execute/store/load cleared
    csrw 0x7a0, zero
    csrw 0x7a1, s10

    csrr s10, mcause
    li   s11, 3                 # breakpoint
    bne  s10, s11, handler_out

    la   s10, break_count
    lw   s11, 0(s10)
    addi s11, s11, 1
    sw   s11, 0(s10)

    csrr s10, mepc
    addi s10, s10, 4
    csrw mepc, s10

handler_out:
    mret

    .data
    .align 2
break_count:
    .word 0
