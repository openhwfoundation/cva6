# ------------------------------------------------------------------------------
#   Copyright 2026 Thales France
#
#   Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
#   You may obtain a copy of the License at https://solderpad.org/licenses/
# ------------------------------------------------------------------------------
#   sdtrig_mcontrol6_exec_match.S
#
#   Fires an mcontrol6 execute trigger on the address of an instruction, with
#   the equality match. The action is the breakpoint exception, so the test
#   needs no debug module to observe the fire: it counts breakpoint traps in its
#   own handler. NAPOT is covered by sdtrig_napot_match_test, and not-equal is
#   not testable this way, for the reason given below.
#
#   tdata1 layout for mcontrol6 on RV32, as the module decodes it:
#     [31:28] type = 6      [22] hit0     [21] select    [18:16] size
#     [15:12] action        [11] chain    [10:7] match   [6] m
#     [4] s   [3] u   [2] execute   [1] store   [0] load
#
#   select = 0 compares the address, select = 1 compares the instruction word.
#   action = 0 raises a breakpoint. m = 1 arms the trigger in machine mode.
#
#   Requires a target with Sdtrig, SdtrigMcontrol6 and SdtrigMcontrol6ExecAddr
#   enabled, and the match types enabled in SdtrigSupportedMatch.
# ------------------------------------------------------------------------------

#include "sdtrig_xlen.h"

    .text
    # Keep every instruction 4 bytes wide: the handler steps over the trapping
    # instruction with mepc + 4, and with C a bare nop would assemble to a
    # 2-byte c.nop.
    .option norvc

    .globl main
main:
    # Install our trap handler and clear the fire counter.
    la   t0, trap_handler
    csrw mtvec, t0
    la   t0, fire_count
    sw   zero, 0(t0)

    # --------------------------------------------------------------------
    # Match type 0, equal: trigger on the exact address of target_insn_eq.
    # --------------------------------------------------------------------
    li   t0, 0
    csrw 0x7a0, t0              # tselect = 0

    la   t1, target_insn_eq
    csrw 0x7a2, t1              # tdata2 = address to match

    # type 6, match 0 (equal), m = 1, execute = 1, action 0 (breakpoint)
    li   t1, TDATA1_VAL(6, 0, 0, 0x0000044)         # [31:28]=6 [6]=m [2]=execute
    csrw 0x7a1, t1

target_insn_eq:
    nop                         # must trap before executing

    # The handler skips the trapping instruction, so we land here.
    la   t0, fire_count
    lw   t1, 0(t0)
    li   t2, 1
    bne  t1, t2, fail           # exactly one fire expected
    la   t0, fire_pc
    LREG t1, 0(t0)
    la   t2, target_insn_eq
    bne  t1, t2, fail           # fired, but not before target_insn_eq

    # Clear tdata1 and tdata2 so that no later instruction matches.
    li   t0, 0
    csrw 0x7a0, t0
    csrw 0x7a1, zero

    # --------------------------------------------------------------------
    # Match type 8, not-equal, is not tested: as a machine-mode execute trigger it
    # also matches the trap handler, which loops. It needs a debug-mode action.

    # --------------------------------------------------------------------
    # Match type 1, NAPOT, is covered by sdtrig_napot_match_test rather than
    # here, a range trigger needing its own handling: armed in machine mode it
    # matches the trap handler too, so the handler has to disarm it before
    # returning.

    # --------------------------------------------------------------------
    # A disarmed trigger must not fire: run a few instructions with every
    # trigger cleared and check the counter stays put.
    # --------------------------------------------------------------------
    la   t0, fire_count
    sw   zero, 0(t0)

    nop
    nop
    nop

    la   t0, fire_count
    lw   t1, 0(t0)
    bnez t1, fail               # no trigger armed, no fire allowed

    # --------------------------------------------------------------------
    li a0, 0
    ret

fail:
    li a0, 1
    ret

    # --------------------------------------------------------------------
    # Trap handler. Counts breakpoint traps and steps over the instruction
    # that trapped so the test can carry on. mcause 3 is the breakpoint.
    # --------------------------------------------------------------------
    .align 6
trap_handler:
    addi sp, sp, -16
    sw   t0, 0(sp)
    sw   t1, 4(sp)
    sw   t2, 8(sp)

    csrr t0, mcause
    li   t1, 3                  # breakpoint
    bne  t0, t1, handler_out

    la   t0, fire_count
    lw   t1, 0(t0)
    addi t1, t1, 1
    sw   t1, 0(t0)

    # Step over the trapping instruction. Every instruction this test traps
    # on is a 4-byte nop, the file being assembled with .option norvc, so
    # mepc + 4 is the next one.
    csrr t0, mepc
    la   t1, fire_pc
    SREG t0, 0(t1)              # last fire, checked by main
    addi t0, t0, 4
    csrw mepc, t0

handler_out:
    lw   t0, 0(sp)
    lw   t1, 4(sp)
    lw   t2, 8(sp)
    addi sp, sp, 16
    mret

    .data
    .align 2
fire_count:
    .word 0
    .align 3
fire_pc:
    PTRWORD 0
