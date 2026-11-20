# ------------------------------------------------------------------------------
#   Copyright 2026 Thales France
#
#   Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
#   You may obtain a copy of the License at https://solderpad.org/licenses/
# ------------------------------------------------------------------------------
#   mstatus_wpri.S
#
#   The reserved (WPRI) fields of mstatus read as zero, whatever is written
#   to them, and writing them raises no exception.
#
#   WPRI bits of mstatus:
#     RV32 and RV64: 0, 2, 4 and 23 to 30
#     RV64 only:     31 and 40 to 62
#   On RV32, mstatush bits other than SBE (4), MBE (5), GVA (6) and MPV (7)
#   are reserved as well.
#
#   The test writes all ones to mstatus, reads it back, restores it, and
#   checks the WPRI bits of the value read. No memory access is made while
#   the all-ones value is in place: it sets MBE, and loads and stores would
#   be big-endian.
#
#   Without RVH, MPV (bit 39 on RV64, mstatush bit 7 on RV32) and GVA
#   (bit 38, mstatush bit 6) are read-only zero as well. The test checks
#   them unless it is built with -DRVH. It does not read misa to find out:
#   the CSR coverage model of the testbench only accepts MXL = 1, and a
#   read of misa on RV64 stops the simulation.
# ------------------------------------------------------------------------------

    .text
    .globl main
main:
    csrr s0, mstatus            # value to restore

    li   t0, -1
    csrw mstatus, t0
    csrr t1, mstatus
    csrw mstatus, s0

    # t2 = WPRI mask of mstatus
    li   t2, 0x7f800015         # bits 30:23, 4, 2, 0
#if __riscv_xlen == 64
    li   t3, 0x7fffff00         # bits 62:40 once shifted by 32
    slli t3, t3, 32
    or   t2, t2, t3
    li   t3, 1
    slli t3, t3, 31             # bit 31
    or   t2, t2, t3
#endif
#ifdef RVH
    li   t4, 1
#else
    li   t4, 0
#endif
#if __riscv_xlen == 64
    bnez t4, 1f
    li   t3, 3
    slli t3, t3, 38             # MPV, GVA
    or   t2, t2, t3
1:
#endif
    and  t1, t1, t2
    bnez t1, fail_mstatus

#if __riscv_xlen == 32
    csrr s1, mstatush
    li   t0, -1
    csrw mstatush, t0
    csrr t1, mstatush
    csrw mstatush, s1
    # reserved: every bit but SBE and MBE, and also MPV and GVA without RVH
    li   t2, ~0x30
    beqz t4, 1f
    li   t2, ~0xf0
1:  and  t1, t1, t2
    bnez t1, fail_mstatush
#endif

    li   a0, 0
    ret

fail_mstatus:
    li   a0, 1
    ret
fail_mstatush:
    li   a0, 2
    ret
