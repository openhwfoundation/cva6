# ------------------------------------------------------------------------------
#   Copyright 2026 Thales France
#
#   Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
#   You may obtain a copy of the License at https://solderpad.org/licenses/
# ------------------------------------------------------------------------------
#   sdtrig_loadaddr_two_triggers.S
#
#   Two mcontrol6 load-address triggers are armed at once, on two different
#   addresses. A load that matches only the first one must:
#     - raise a breakpoint (mcause 3) and leave rd unchanged, the trigger
#       being precise;
#     - set hit0 in the tdata1 of the matching trigger only;
#     - leave hit0 clear in the tdata1 of the other trigger.
#
#   The other trigger is set up with action 1 (enter debug mode): if its
#   action were taken, the core would enter debug mode instead of trapping,
#   and the test would not reach the end.
#
#   The test is then repeated with the roles swapped, the second trigger
#   having action 0 and the first action 1, so that the trigger index does
#   not matter.
#
#   tdata1 layout for mcontrol6 on RV32:
#     [31:28] type = 6      [22] hit0     [21] select    [15:12] action
#     [11] chain    [10:7] match   [6] m   [2] execute   [1] store   [0] load
#
#   Disarming keeps the type at 6 and clears the operation bits, see
#   sdtrig_mcontrol6_load.S.
#
#   Requires Sdtrig, SdtrigMcontrol6LoadAddr, and at least two triggers.
# ------------------------------------------------------------------------------

#define TSELECT 0x7a0
#define TDATA1  0x7a1
#define TDATA2  0x7a2

#include "sdtrig_xlen.h"

#define MC6_LOAD_M_ACT0 TDATA1_VAL(6, 0, 0, 0x0000041)  /* type 6, m, load, action 0 */
#define MC6_LOAD_M_ACT1 TDATA1_VAL(6, 0, 0, 0x0001041)  /* type 6, m, load, action 1 */
#define MC6_DISARMED    TDATA1_VAL(6, 0, 0, 0x0000040)  /* type 6, m, no operation   */
#define MC6_HIT0        (1 << 22)

    .text
    .option norvc

    .globl main
main:
    mv   s9, ra                 # main calls helpers, keep the return address
    la   t0, trap_handler
    csrw mtvec, t0

    # ====================================================================
    # Round 1: trigger 0 watches word_a with action 0, trigger 1 watches
    # word_b with action 1. The load hits word_a.
    # ====================================================================
    la   a0, word_a
    li   a1, MC6_LOAD_M_ACT0
    la   a2, word_b
    li   a3, MC6_LOAD_M_ACT1
    jal  arm_both

    la   t0, break_count
    sw   zero, 0(t0)
    li   a4, 0x5A5A5A5A         # sentinel
    la   t0, word_a
    lw   a4, 0(t0)              # must trap before the load lands

    jal  read_hits              # s2 = tdata1[0], s3 = tdata1[1]
    jal  disarm_both

    la   t0, break_count
    lw   t1, 0(t0)
    li   t2, 1
    bne  t1, t2, fail           # exactly one breakpoint
    li   t2, 0x5A5A5A5A
    bne  a4, t2, fail           # the load landed: not precise
    li   t2, MC6_HIT0
    and  t1, s2, t2
    beqz t1, fail               # the matching trigger did not record hit0
    and  t1, s3, t2
    bnez t1, fail               # the other trigger recorded hit0 too

    # ====================================================================
    # Round 2: roles swapped. Trigger 0 watches word_a with action 1,
    # trigger 1 watches word_b with action 0. The load hits word_b.
    # ====================================================================
    la   a0, word_a
    li   a1, MC6_LOAD_M_ACT1
    la   a2, word_b
    li   a3, MC6_LOAD_M_ACT0
    jal  arm_both

    la   t0, break_count
    sw   zero, 0(t0)
    li   a5, 0x5A5A5A5A
    la   t0, word_b
    lw   a5, 0(t0)

    jal  read_hits
    jal  disarm_both

    la   t0, break_count
    lw   t1, 0(t0)
    li   t2, 1
    bne  t1, t2, fail
    li   t2, 0x5A5A5A5A
    bne  a5, t2, fail
    li   t2, MC6_HIT0
    and  t1, s3, t2
    beqz t1, fail               # trigger 1 matched
    and  t1, s2, t2
    bnez t1, fail               # trigger 0 did not

    # ====================================================================
    # Round 3: with both triggers armed, a load from a third address does
    # not fire, and a load from word_a after disarming goes through.
    # ====================================================================
    la   a0, word_a
    li   a1, MC6_LOAD_M_ACT0
    la   a2, word_b
    li   a3, MC6_LOAD_M_ACT0
    jal  arm_both

    la   t0, break_count
    sw   zero, 0(t0)
    la   t0, word_c
    lw   a6, 0(t0)
    jal  disarm_both
    la   t0, word_a
    lw   a7, 0(t0)

    la   t0, break_count
    lw   t1, 0(t0)
    bnez t1, fail
    li   t2, 0x33334444
    bne  a6, t2, fail
    li   t2, 0xCAFEBABE
#if __riscv_xlen == 64
    sext.w t2, t2                # lw sign-extends the word
#endif
    bne  a7, t2, fail

    li   a0, 0
    mv   ra, s9
    ret

fail:
    jal  disarm_both
    li   a0, 1
    mv   ra, s9
    ret

    # --------------------------------------------------------------------
    # arm_both(a0 = addr0, a1 = tdata1 0, a2 = addr1, a3 = tdata1 1)
    # Each tdata1 is written with hit0 clear.
    # --------------------------------------------------------------------
arm_both:
    csrw TSELECT, zero
    li   t0, MC6_DISARMED
    csrw TDATA1, t0
    csrw TDATA2, a0
    csrw TDATA1, a1
    li   t0, 1
    csrw TSELECT, t0
    li   t0, MC6_DISARMED
    csrw TDATA1, t0
    csrw TDATA2, a2
    csrw TDATA1, a3
    ret

    # --------------------------------------------------------------------
    # read_hits: s2 = tdata1 of trigger 0, s3 = tdata1 of trigger 1.
    # --------------------------------------------------------------------
read_hits:
    csrw TSELECT, zero
    csrr s2, TDATA1
    li   t0, 1
    csrw TSELECT, t0
    csrr s3, TDATA1
    ret

disarm_both:
    li   t0, MC6_DISARMED
    csrw TSELECT, zero
    csrw TDATA1, t0
    li   t1, 1
    csrw TSELECT, t1
    csrw TDATA1, t0
    ret

    # --------------------------------------------------------------------
    # Counts breakpoints and steps over the load that trapped. Before any
    # memory access it clears the load bit of both triggers, which leaves
    # their hit bits as the core set them. s10 and s11 are scratch here,
    # main does not use them; s9 holds the return address of main.
    # --------------------------------------------------------------------
    .align 6
trap_handler:
    csrr s10, mcause
    li   s11, 3                 # breakpoint
    bne  s10, s11, unexpected

    # The breakpoint handler touches memory: disable both load triggers
    # without clearing their hit bits, by clearing only the load bit.
    csrr s11, TSELECT
    csrw TSELECT, zero
    csrci TDATA1, 1
    li   s10, 1
    csrw TSELECT, s10
    csrci TDATA1, 1
    csrw TSELECT, s11

    la   s10, break_count
    lw   s11, 0(s10)
    addi s11, s11, 1
    sw   s11, 0(s10)

    csrr s10, mepc
    addi s10, s10, 4
    csrw mepc, s10
    mret

unexpected:
    # Any other trap ends the test as a failure.
    li   a0, 1
    j    exit

    .data
    .align 2
break_count:
    .word 0
word_a:
    .word 0xCAFEBABE
    .align 4
word_b:
    .word 0x11112222
    .align 4
word_c:
    .word 0x33334444
