# ------------------------------------------------------------------------------
#   Copyright 2026 Thales France
#
#   Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
#   You may obtain a copy of the License at https://solderpad.org/licenses/
# ------------------------------------------------------------------------------
#   sdtrig_icount.S
#
#   icount trigger: a countdown on committed instructions that raises a
#   breakpoint when it reaches zero. The only trigger type that compares neither
#   an address nor a value.
#
#   tdata1 layout for icount on RV32, as the module decodes it:
#     [31:28] type = 3   [27] dmode   [24] hit   [23:10] count
#     [9] m   [8] pending   [7] s   [6] u   [5:0] action
#
#   Two constraints of the trigger module that matter for any trigger test:
#
#   - Disarming by writing tdata1 to zero does not work. Every trigger type's
#     logic sits under "type == N" in the module, including the branches that
#     clear pending and latch hit. Changing the type strands that state and the
#     trigger fires forever. The handler keeps the type and sets hit instead.
#
#   - A total trap count proves nothing, the module re-entering the handler once
#     on its own while its internal state settles. Counting breakpoints by cause
#     is what tells the countdown apart from noise.
#
#   Requires Sdtrig and SdtrigIcount.
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
    # Arm a countdown of three instructions with the breakpoint action, then run
    # a stretch of nops long enough for it to expire.
    #
    # tdata1 = type 3, count 3, m, action 0:
    #   (3 << 28) | (3 << 10) | (1 << 9) = 0x30000e00
    # --------------------------------------------------------------------
    li   t0, 0
    csrw 0x7a0, t0              # tselect = 0

    li   t1, TDATA1_VAL(3, 0, 0, 0x0000e00)
    csrw 0x7a1, t1

    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop

    la   t0, break_count
    lw   t1, 0(t0)
    beqz t1, fail               # the countdown never expired

    # --------------------------------------------------------------------
    # The handler set hit, so the trigger is spent: a second stretch of nops
    # must not produce another breakpoint. This separates a countdown that
    # expires once from a trigger firing on every instruction.
    # --------------------------------------------------------------------
    la   t0, break_count
    sw   zero, 0(t0)

    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop

    la   t0, break_count
    lw   t1, 0(t0)
    bnez t1, fail               # fired again although hit was set

    # --------------------------------------------------------------------
    li a0, 0
    ret

fail:
    li   t0, TDATA1_VAL(3, 0, 0, 0x1fffe00)         # type 3 kept, hit set, count reloaded
    csrw 0x7a0, zero
    csrw 0x7a1, t0
    li a0, 1
    ret

    # --------------------------------------------------------------------
    # Counts breakpoints and spends the trigger by setting its hit bit while
    # keeping the type at 3, see the note at the top of the file.
    #
    # s10 and s11 are scratch, main does not use them.
    # --------------------------------------------------------------------
    .align 6
trap_handler:
    # type 3, count 0x3fff, hit set, m:
    #   (3 << 28) | (0x3fff << 10) | (1 << 24) | (1 << 9)
    li   s10, TDATA1_VAL(3, 0, 0, 0x1fffe00)
    csrw 0x7a0, zero
    csrw 0x7a1, s10

    csrr s10, mcause
    li   s11, 3                 # breakpoint
    bne  s10, s11, handler_out

    la   s10, break_count
    lw   s11, 0(s10)
    addi s11, s11, 1
    sw   s11, 0(s10)

    # Step over the instruction the break points at (four bytes, .option norvc):
    # returning onto it would re-arm the trigger.
    csrr s10, mepc
    addi s10, s10, 4
    csrw mepc, s10

handler_out:
    mret

    .data
    .align 2
break_count:
    .word 0
