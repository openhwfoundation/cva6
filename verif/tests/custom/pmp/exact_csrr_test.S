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
    #
    # The number of PMP entries is a parameter of the core (NrPMPEntries, 0 to
    # 64), so the test finds it instead of assuming it: implemented entries
    # are the lowest-numbered ones and read back the value written (bit 0
    # reads 0, the entries being OFF); the others are read-only zero. Each of
    # the 64 pmpaddr is written with its own value and read back:
    #   - read == written: implemented, only allowed while no unimplemented
    #     entry has been seen (s0 = 0), counted in s1;
    #   - read == 0: not implemented, sets s0;
    #   - anything else: fail.

    li s0, 0                          # an unimplemented entry has been seen
    li s1, 0                          # number of implemented entries

    .set k, 0
    .rept 64
    li t0, 0xFACADE00 + 2 * k
    csrw 0x3B0 + k, t0                # pmpaddr<k>
    csrr t1, 0x3B0 + k
    csrw 0x3B0 + k, zero
    beq t1, t0, 1f
    bnez t1, fail
    li s0, 1
    j 2f
1:
    bnez s0, fail                     # implemented above an unimplemented one
    addi s1, s1, 1
2:
    .set k, k + 1
    .endr

    # A PMP target has at least the entries the configuration checks below
    # rely on.
    li t0, 8
    bltu s1, t0, fail


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
