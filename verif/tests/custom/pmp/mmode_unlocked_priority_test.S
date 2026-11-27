# ------------------------------------------------------------------------------
#   Copyright 2026 10xEngineers
#
#   SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
#
#   Original Author: Bilal Ahmad
# ------------------------------------------------------------------------------
#   mmode_unlocked_priority_test.S
#
#   The lowest-numbered PMP entry that matches an access decides it. When that
#   entry is unlocked, an M-mode access succeeds, even if a higher-numbered
#   locked entry that also matches grants nothing (privileged specification,
#   "Priority and Matching Logic"). See issue #3177.
#
#   Entry 0: TOR [0, locked_tail), unlocked, RWX
#   Entry 1: OFF, base of entry 2
#   Entry 2: TOR [shared_region, locked_end), locked, no permission
#
#   shared_region matches entries 0 and 2: M-mode loads, stores and fetches
#   there must succeed. TOR only, so that the test also runs on targets without
#   NAPOT. Any trap fails the test.
# ------------------------------------------------------------------------------

    .equ INSTR_LI_A2_0X33, 0x03300613    # addi a2, zero, 0x33
    .equ INSTR_RET,        0x00008067    # jalr zero, 0(ra)

    .text
    .globl main
main:

    # Place "li a2, 0x33; ret" at shared_region before the PMP is set up.
    la t0, shared_region
    li t1, INSTR_LI_A2_0X33
    sw t1, 0(t0)
    li t1, INSTR_RET
    sw t1, 4(t0)
    fence.i

    # Entry 0 ends where the locked-only part of entry 2 begins.
    la t0, locked_tail
    srli t0, t0, 2
    csrw pmpaddr0, t0
    la t0, shared_region
    srli t0, t0, 2
    csrw pmpaddr1, t0
    la t0, locked_end
    srli t0, t0, 2
    csrw pmpaddr2, t0

    # pmp2cfg = L | TOR (0x88), pmp1cfg = OFF, pmp0cfg = TOR | X | W | R (0x0f).
    li t0, 0x0088000f
    csrw pmpcfg0, t0
    csrr t1, pmpcfg0
    bne t0, t1, fail

    # M-mode load from the shared region.
    la t0, shared_region
    lw t1, 8(t0)
    li t2, 0x5a5a5a5a
    bne t1, t2, fail

    # M-mode store to the shared region, read back.
    li t2, 0x0c0ffee0
    sw t2, 12(t0)
    lw t1, 12(t0)
    bne t1, t2, fail

    # M-mode fetch from the shared region.
    li a2, 0
    jalr ra, 0(t0)
    li t1, 0x33
    bne a2, t1, fail

pass:
    # Success post-processing
    li a0, 0x0;
    jal exit;

fail:
    # Failure post-processing
    li a0, 0x1;
    jal exit;

    # No trap is expected.
    .globl handle_trap
handle_trap:
    li a0, 0x1;
    jal exit;

    .section .data, "aw", @progbits
    .balign 4096
shared_region:
    .word 0                              # li a2, 0x33 (written by the test)
    .word 0                              # ret (written by the test)
    .word 0x5a5a5a5a                     # loaded by the test
    .word 0                              # stored by the test
    .balign 4096
locked_tail:
    .word 0
    .balign 4096
locked_end:
