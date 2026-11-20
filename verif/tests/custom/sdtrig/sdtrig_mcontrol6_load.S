# ------------------------------------------------------------------------------
#   Copyright 2026 Thales France
#
#   Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
#   You may obtain a copy of the License at https://solderpad.org/licenses/
# ------------------------------------------------------------------------------
#   sdtrig_mcontrol6_load.S
#
#   mcontrol6 load trigger on the load address, select = 0.
#
#   The trigger is precise: it fires before the load completes, so the
#   destination register keeps whatever it held. Checking that register is what
#   distinguishes a trigger that stopped the access from one that merely reported
#   it afterwards.
#
#   tdata1 layout for mcontrol6 on RV32, as the module decodes it:
#     [31:28] type = 6      [22] hit0     [21] select    [18:16] size
#     [15:12] action        [11] chain    [10:7] match   [6] m
#     [4] s   [3] u   [2] execute   [1] store   [0] load
#
#   Disarming keeps the type at 6 and clears the operation bits instead of
#   writing tdata1 to zero: every trigger type's logic sits under "type == N" in
#   the module, so changing the type strands the internal state and the trigger
#   keeps firing.
#
#   Requires Sdtrig, SdtrigMcontrol6 and SdtrigMcontrol6LoadAddr.
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
    # Arm on the address of watched_word, put a sentinel in the destination
    # register, then load from that address.
    # --------------------------------------------------------------------
    li   t0, 0
    csrw 0x7a0, t0              # tselect = 0
    la   t1, watched_word
    csrw 0x7a2, t1              # tdata2 = address to watch

    # type 6, match 0, m in [6], load in [0], action 0, select = 0
    li   t1, TDATA1_VAL(6, 0, 0, 0x0000041)
    csrw 0x7a1, t1

    li   a4, 0x5A5A5A5A         # sentinel
    la   t0, watched_word
    lw   a4, 0(t0)              # must trap before the load lands

    la   t0, break_count
    lw   t1, 0(t0)
    li   t2, 1
    bne  t1, t2, fail           # exactly one breakpoint expected

    li   t2, 0x5A5A5A5A
    bne  a4, t2, fail           # the load landed: the trigger was not precise

    # --------------------------------------------------------------------
    # A load from a different address must not fire, which separates a working
    # address comparison from one firing on every load.
    # --------------------------------------------------------------------
    la   t0, break_count
    sw   zero, 0(t0)

    li   t0, 0
    csrw 0x7a0, t0
    la   t1, watched_word
    csrw 0x7a2, t1
    li   t1, TDATA1_VAL(6, 0, 0, 0x0000041)
    csrw 0x7a1, t1

    la   t0, other_word         # a different address
    lw   a6, 0(t0)

    # Disarm: keep the type, drop the operation bits.
    li   t1, TDATA1_VAL(6, 0, 0, 0x0000040)
    csrw 0x7a1, t1

    la   t0, break_count
    lw   t1, 0(t0)
    bnez t1, fail               # fired on an address it was not watching

    li   t2, 0x11112222
    bne  a6, t2, fail           # this load was supposed to go through

    # --------------------------------------------------------------------
    li a0, 0
    ret

fail:
    li   t1, TDATA1_VAL(6, 0, 0, 0x0000040)         # keep the type, drop the operation bits
    csrw 0x7a1, t1
    li a0, 1
    ret

    # --------------------------------------------------------------------
    # Counts breakpoints, disarms the trigger, and steps over the load that
    # trapped.
    #
    # No stack, and the trigger is disarmed before any memory access: s10 and
    # s11 are scratch here, main does not use them.
    # --------------------------------------------------------------------
    .align 6
trap_handler:
    li   s10, TDATA1_VAL(6, 0, 0, 0x0000040)        # type 6 kept, load/store/execute cleared
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
watched_word:
    .word 0xCAFEBABE
other_word:
    .word 0x11112222
