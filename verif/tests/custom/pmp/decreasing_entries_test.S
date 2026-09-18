# ------------------------------------------------------------------------------
#   Copyright 2024 Robert Bosch GmbH
#
#   SPDX-License-Identifier: SHL-0.51
#
#   Original Author: Konstantinos LEVENTOS - Robert Bosch France SAS
# ------------------------------------------------------------------------------
#   decreasing_entries_test.S (TST04-4)
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

    # Configure PMP using decreasing entries of TOR.

    # From 0xB000_0000 to 0xC000_0000 Read-Write-Execute.
    li t0, 0x30000000
    csrw pmpaddr7, t0

    # From 0xA000_0000 to 0xB000_0000 Read-Write-Execute.
    li t0, 0x2c000000
    csrw pmpaddr6, t0

    # From 0x9000_0000 to 0xA000_0000 Read-Write-Execute.
    li t0, 0x28000000
    csrw pmpaddr5, t0

    # From 0x8000_0000 to 0x9000_0000 Read-Write-Execute.
    li t0, 0x24000000
    csrw pmpaddr4, t0

    # From 0x0002_0000 to 0x8000_0000 no Permissions.
    li t0, 0x20000000
    csrw pmpaddr3, t0

    # From 0x0001_0000 to 0x0002_0000 only Execute.
    li t0, 0x00008000
    csrw pmpaddr2, t0

    # From 0x0000_1000 to 0x0001_0000 no Permissions.
    li t0, 0x00004000
    csrw pmpaddr1, t0

    # From 0x0000_0000 to 0x0000_1000 only Execute.
    li t0, 0x00000400
    csrw pmpaddr0, t0


    # Entries 0-7 configs, with LOCK OFF, and TOR.
    # A pmpcfg register holds 4 entries on RV32 and 8 on RV64, so entries 0-7
    # need pmpcfg0 and pmpcfg1 there but fit in pmpcfg0 here. The odd pmpcfg
    # registers do not exist on RV64.
#if __riscv_xlen == 64
    li t0, 0x0f0f0f0f080c080c
    csrw pmpcfg0, t0
#else
    # Addr 4-7 configs, written in cfg1, with LOCK OFF, and TOR.
    li t0, 0x0f0f0f0f
    csrw pmpcfg1, t0

    # Addr 0-3 configs, written in cfg0, with LOCK OFF, and TOR.
    li t0, 0x080c080c
    csrw pmpcfg0, t0
#endif


    # Do the READ-WRITE test.

    # Check 1 read-write test, at 0x8800_0000.
    li t1, 0x88000000
    li t2, 0xEFFACED1
    sw t2, 0(t1)
    LW_UNSIGNED t3, 0(t1)
    bne t2, t3, fail

    # Check 2 read-write test, at 0x9800_0000.
    li t1, 0x98000000
    li t2, 0xACCEDED2
    sw t2, 0(t1)
    LW_UNSIGNED t3, 0(t1)
    bne t2, t3, fail

    # Check 3 read-write test, at 0xA800_0000.
    li t1, 0xA8000000
    li t2, 0xDEFACED3
    sw t2, 0(t1)
    LW_UNSIGNED t3, 0(t1)
    bne t2, t3, fail

    # Check 4 read-write test, at 0xB800_0000.
    li t1, 0xB8000000
    li t2, 0xDEC0DED4
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
