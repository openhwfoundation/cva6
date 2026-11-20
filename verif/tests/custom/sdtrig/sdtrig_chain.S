# ------------------------------------------------------------------------------
#   Copyright 2026 Thales France
#
#   Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
#   You may obtain a copy of the License at https://solderpad.org/licenses/
# ------------------------------------------------------------------------------
#   sdtrig_chain.S
#
#   Trigger chaining: two mcontrol6 triggers on consecutive tselect indexes, the
#   first with chain set and the last with it clear. Every trigger of the chain
#   has to match before anything fires, and only the last one's action is taken.
#
#   The CVA6 documentation adds a constraint the spec does not: the chain has to
#   be ordered by pipeline stage, earliest event on the lowest index. So an
#   execute trigger comes before a load trigger, the instruction being fetched
#   before its memory access happens.
#
#   What the test checks is the conjunction, from both sides. A load from the
#   watched address coming from another instruction must not fire: only the
#   load link matched. The watched instruction loading another address must
#   not fire either: only the execute link matched. The watched instruction
#   loading the watched address must.
#
#   tdata1 layout for mcontrol6 on RV32, as the module decodes it:
#     [31:28] type = 6      [22] hit0     [21] select    [18:16] size
#     [15:12] action        [11] chain    [10:7] match   [6] m
#     [4] s   [3] u   [2] execute   [1] store   [0] load
#
#   Requires Sdtrig, SdtrigMcontrol6, SdtrigMcontrol6ExecAddr,
#   SdtrigMcontrol6LoadAddr, SdtrigTriggerChaining and at least two triggers.
# ------------------------------------------------------------------------------

#include "sdtrig_xlen.h"

    .text
    .option norvc

    .globl main
main:
    addi sp, sp, -16            # main calls chained_load_call: keep ra
    SREG ra, 0(sp)
    la   t0, trap_handler
    csrw mtvec, t0
    la   t0, break_count
    sw   zero, 0(t0)

    # --------------------------------------------------------------------
    # Link 0: execute at chained_load, chain set.
    # Link 1: load from watched_word, chain clear, action breakpoint.
    # --------------------------------------------------------------------
    li   t0, 0
    csrw 0x7a0, t0              # tselect = 0
    la   t1, chained_load
    csrw 0x7a2, t1              # match the address of the load instruction
    li   t1, TDATA1_VAL(6, 0, 0, 0x0000844)         # type 6, chain in [11], m, execute
    csrw 0x7a1, t1

    li   t0, 1
    csrw 0x7a0, t0              # tselect = 1
    la   t1, watched_word
    csrw 0x7a2, t1              # match the address the load reads
    li   t1, TDATA1_VAL(6, 0, 0, 0x0000041)         # type 6, chain clear, m, load, action 0
    csrw 0x7a1, t1

    # --------------------------------------------------------------------
    # A load from the watched address, but from another instruction: only the
    # second link matches, so the chain must stay silent.
    # --------------------------------------------------------------------
    la   t0, watched_word
    lw   a4, 0(t0)              # not at chained_load: must not fire

    la   t0, break_count
    lw   t1, 0(t0)
    bnez t1, fail               # the load link alone fired the chain

    # --------------------------------------------------------------------
    # The watched instruction, loading another address: only the execute link
    # matches, so the chain must stay silent and the load must complete.
    # --------------------------------------------------------------------
    la   t0, other_word
    li   a5, 0
    jal  ra, chained_load_call

    la   t0, break_count
    lw   t1, 0(t0)
    bnez t1, fail               # the execute link alone fired the chain
    li   t1, 0x12345678
    bne  a5, t1, fail           # the load did not complete

    # --------------------------------------------------------------------
    # The watched instruction, loading the watched address: both links match.
    # --------------------------------------------------------------------
    la   t0, watched_word
    li   a5, 0
    jal  ra, chained_load_call

    la   t0, break_count
    lw   t1, 0(t0)
    li   t2, 1
    bne  t1, t2, fail           # the complete chain did not fire exactly once
    bnez a5, fail               # the breakpoint did not precede the load

    # --------------------------------------------------------------------
    li a0, 0
    LREG ra, 0(sp)
    addi sp, sp, 16
    ret

    # --------------------------------------------------------------------
    # The watched load, reached from two call sites. The handler skips it, so
    # a5 keeps the value it had when the breakpoint was taken before the load.
    # --------------------------------------------------------------------
chained_load_call:
chained_load:
    lw   a5, 0(t0)
    ret

fail:
    li   t1, TDATA1_VAL(6, 0, 0, 0x0000040)         # keep the type, drop the operation bits
    csrw 0x7a0, zero
    csrw 0x7a1, t1
    li   t0, 1
    csrw 0x7a0, t0
    csrw 0x7a1, t1
    li a0, 1
    LREG ra, 0(sp)
    addi sp, sp, 16
    ret

    # --------------------------------------------------------------------
    # Counts breakpoints and disarms both links, keeping the type at 6 so the
    # module's internal state is not stranded. s10 and s11 are scratch.
    # --------------------------------------------------------------------
    .align 6
trap_handler:
    li   s10, TDATA1_VAL(6, 0, 0, 0x0000040)        # type 6 kept, operation bits cleared
    csrw 0x7a0, zero
    csrw 0x7a1, s10
    li   s11, 1
    csrw 0x7a0, s11
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
watched_word:
    .word 0xCAFEBABE
other_word:
    .word 0x12345678
