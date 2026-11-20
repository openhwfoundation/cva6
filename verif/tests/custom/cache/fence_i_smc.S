# ------------------------------------------------------------------------------
#   Copyright 2026 Thales France
#
#   Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
#   You may obtain a copy of the License at https://solderpad.org/licenses/
# ------------------------------------------------------------------------------
#   fence_i_smc.S
#
#   Self-modifying code: a store rewrites an instruction, fence.i makes it
#   visible to the fetch, and the new instruction must be the one that runs.
#
#   The patched function is called once before it is rewritten, so its old
#   encoding is in the instruction cache, and in the data cache too on a
#   write-back data cache, where the store then stays until it is evicted or
#   flushed. fence.i has to get it to the fetch either way. The rewrite is
#   done three times, alternating two encodings, so a stale line left by one
#   round shows on the next.
#
#   Runs on RV32 and RV64, with or without C: the patched instructions are
#   32-bit words stored with sw at a 4-byte aligned address.
# ------------------------------------------------------------------------------

#define LI_A0_1   0x00100513    /* addi a0, x0, 1 */
#define LI_A0_2   0x00200513    /* addi a0, x0, 2 */

    .text
    .option norvc

    .globl main
main:
    mv   s9, ra

    # warm both caches with the original encoding (returns 1)
    jal  ra, patched
    li   t0, 1
    bne  a0, t0, fail

    li   s1, 3                  # rounds
    li   s2, LI_A0_2            # encoding to write
    li   s3, 2                  # value it returns
round:
    la   t0, patched
    sw   s2, 0(t0)
    fence.i
    jal  ra, patched
    bne  a0, s3, fail           # the old instruction ran: fence.i missed it

    # swap to the other encoding for the next round
    li   t0, LI_A0_1
    li   t1, LI_A0_2
    beq  s2, t0, 1f
    mv   s2, t0
    li   s3, 1
    j    2f
1:
    mv   s2, t1
    li   s3, 2
2:
    addi s1, s1, -1
    bnez s1, round

    mv   ra, s9
    li   a0, 0
    ret

fail:
    mv   ra, s9
    li   a0, 1
    ret

    # Rewritten at run time. In .data so it is writable, which the code
    # section may not be; the linker scripts make it executable as well.
    .data
    .balign 64
    .globl patched
patched:
    .word LI_A0_1               # addi a0, x0, 1
    .word 0x00008067            # ret
