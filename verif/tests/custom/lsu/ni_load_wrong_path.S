# ------------------------------------------------------------------------------
#   Copyright 2026 Thales France
#
#   Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
#   You may obtain a copy of the License at https://solderpad.org/licenses/
# ------------------------------------------------------------------------------
#   ni_load_wrong_path.S
#
#   A load from a non-idempotent region on the wrong path of a mispredicted
#   branch must not reach memory.
#
#   A taken branch and a load from NI_ADDR share an 8-byte fetch block, so a
#   superscalar core issues them together. The first times round the loop the
#   branch is predicted not taken, which puts the load on the wrong path.
#
#   The load unit assertion ni_load_at_commit reports the access. Requires a
#   target with a non-idempotent region covering NI_ADDR.
# ------------------------------------------------------------------------------

#define NI_ADDR 0x00001000
#define ROUNDS  32

    .text
    .option norvc
    .globl main
main:
    li    s2, NI_ADDR
    li    s3, ROUNDS
    li    s4, 1                 # branch condition: always taken

    .align 3
loop:
    bnez  s4, skip
    lw    t0, 0(s2)             # wrong path
skip:
    addi  s3, s3, -1
    bnez  s3, loop

    li    a0, 0
    ret
