# ------------------------------------------------------------------------------
#   Copyright 2024 Robert Bosch GmbH
#
#   SPDX-License-Identifier: SHL-0.51
#
#   Original Author: Konstantinos LEVENTOS - Robert Bosch France SAS
# ------------------------------------------------------------------------------
#   locked_outside_tor_test.S (TST16-26, TST16-36)
# ------------------------------------------------------------------------------

# A 32 bit load sign extends on RV64, so reading back a word whose bit 31 is set
# does not compare equal to the value stored by li. Use the zero extending form
# there so the check tests the memory access, not the sign extension.
#if __riscv_xlen == 64
#define LW_UNSIGNED lwu
#else
#define LW_UNSIGNED lw
#endif

    .text
    .globl main
main:

    # From 0x0000_0000 to 0x0000_1000 only Execute.
    li t0, 0x00000400
    csrw pmpaddr0, t0

    # From 0x0000_1000 to 0x0001_0000 no Permissions.
    li t0, 0x00004000
    csrw pmpaddr1, t0

    # From 0x0001_0000 to 0x0002_0000 only Execute.
    li t0, 0x00008000
    csrw pmpaddr2, t0

    # From 0x0002_0000 to 0x8000_0000 no Permissions.
    li t0, 0x20000000
    csrw pmpaddr3, t0

    # From 0x8000_0000 to 0xB000_0000 Read-Write-Execute.
    li t0, 0x2C000000
    csrw pmpaddr4, t0

    # Configure the TOR areas with LOCK ON.
    # Entries 0-3 in cfg0, entry 4 next to them.
    # A pmpcfg register holds 4 entries on RV32 and 8 on RV64, so entry 4 lands
    # in pmpcfg1 there but in the upper half of pmpcfg0 here. The odd pmpcfg
    # registers do not exist on RV64.
#if __riscv_xlen == 64
    li t0, 0x0000008f888c888c
    csrw pmpcfg0, t0
    csrr t1, pmpcfg0
    bne t0, t1, fail
#else
    li t0, 0x888c888c
    csrw pmpcfg0, t0
    csrr t1, pmpcfg0
    bne t0, t1, fail
    li t0, 0x0000008f
    csrw pmpcfg1, t0
    csrr t1, pmpcfg1
    bne t0, t1, fail
#endif

    # Check a memory access succeeds when outside the LOCKED entry.
    li t1, 0xB8000000
    li t2, 0xC0D1F1ED
    sw t2, 0(t1)
    LW_UNSIGNED t3, 0(t1)
    bne t2, t3, fail


pass:
    # Success post-processing
    li a0, 0x0;
    jal exit;

fail:
    # Failure post-processing
    li a0, 0x1;
    jal exit;
