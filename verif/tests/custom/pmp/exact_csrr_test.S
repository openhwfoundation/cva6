# ------------------------------------------------------------------------------
#   Copyright 2024 Robert Bosch GmbH
#
#   SPDX-License-Identifier: SHL-0.51
#
#   Original Author: Konstantinos LEVENTOS - Robert Bosch France SAS
# ------------------------------------------------------------------------------
#   exact_csrr_test.S (TST05-1)
# ------------------------------------------------------------------------------

    .text
    .globl main
main:

    # Write in addresses and check what is written.

    # Checking PMP ADDR 0
    li t0, 0xFACADE00
    csrw pmpaddr0, t0
    csrr t1, pmpaddr0
    bne t0, t1, fail
    csrw pmpaddr0, zero

    # Checking PMP ADDR 1
    li t0, 0xFACADE02
    csrw pmpaddr1, t0
    csrr t1, pmpaddr1
    bne t0, t1, fail
    csrw pmpaddr1, zero

    # Checking PMP ADDR 2
    li t0, 0xFACADE04
    csrw pmpaddr2, t0
    csrr t1, pmpaddr2
    bne t0, t1, fail
    csrw pmpaddr2, zero

    # Checking PMP ADDR 3
    li t0, 0xFACADE06
    csrw pmpaddr3, t0
    csrr t1, pmpaddr3
    bne t0, t1, fail
    csrw pmpaddr3, zero

    # Checking PMP ADDR 4
    li t0, 0xFACADE08
    csrw pmpaddr4, t0
    csrr t1, pmpaddr4
    bne t0, t1, fail
    csrw pmpaddr4, zero

    # Checking PMP ADDR 5
    li t0, 0xFACADE0A
    csrw pmpaddr5, t0
    csrr t1, pmpaddr5
    bne t0, t1, fail
    csrw pmpaddr5, zero

    # Checking PMP ADDR 6
    li t0, 0xFACADE0C
    csrw pmpaddr6, t0
    csrr t1, pmpaddr6
    bne t0, t1, fail
    csrw pmpaddr6, zero

    # Checking PMP ADDR 7
    li t0, 0xFACADE0E
    csrw pmpaddr7, t0
    csrr t1, pmpaddr7
    bne t0, t1, fail
    csrw pmpaddr7, zero


    # Write in configurations and check what is written, except for the reserved combinations with R=0 and W=1.

    # Checking PMP CFG 0
    # A pmpcfg register covers 4 entries on RV32 and 8 on RV64, so the value
    # written has to span the whole register to check every entry it holds.
#if __riscv_xlen == 64
    li t0, 0x0405050701030304
#else
    li t0, 0x01030304
#endif
    csrw pmpcfg0, t0
    csrr t1, pmpcfg0
    bne t0, t1, fail
    csrw pmpcfg0, zero

    # Checking PMP CFG 1
    # RV32 only: entries 4-7 live in pmpcfg1 there, while on RV64 they are in
    # the upper half of pmpcfg0 checked above and pmpcfg1 does not exist.
#if __riscv_xlen == 32
    li t0, 0x04050507
    csrw pmpcfg1, t0
    csrr t1, pmpcfg1
    bne t0, t1, fail
    csrw pmpcfg1, zero
#endif


pass:
    # Success post-processing
    li a0, 0x0;
    jal exit;

fail:
    # Failure post-processing
    li a0, 0x1;
    jal exit;
