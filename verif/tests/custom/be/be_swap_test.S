# ------------------------------------------------------------------------------
#   Copyright 2026 Thales France
#
#   Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
#   You may obtain a copy of the License at https://solderpad.org/licenses/
# ------------------------------------------------------------------------------
#   be_swap_test.S
#
#   Exercises the big endian data path. mstatus.MBE selects whether the core
#   treats data memory as big endian; the core stays little endian internally
#   and reverses the byte order as data crosses the load and store boundary.
#
#   The test is built little endian like every other one, and toggles MBE at
#   run time rather than relying on a big endian binary. Mixing the two would
#   cancel out: the compiler would lay the constants out reversed and the core
#   would reverse them back. Toggling MBE alone isolates the swappers.
#
#   What it checks:
#     1. A word stored and loaded back with MBE set reads its own value. Both
#        halves of the round trip swap, so they cancel and the value returns
#        unchanged. This fails if only one direction swaps.
#     2. A word stored with MBE set and read back with MBE clear comes out
#        byte reversed. This is the discriminating check: it fails if the
#        store swapper does nothing.
#     3. A byte access is never swapped, whatever MBE says.
#   4. mstatush reads back the MBE bit, and clearing it restores little
#        endian behaviour.
#
#   MBE is cleared before returning. The tohost protocol the testbench watches
#   is little endian, so a test that exits with MBE set would write a value the
#   tracer cannot read.
#
#   On RV32 MBE is bit 5 of mstatush. On RV64 it is bit 37 of mstatus, and
#   the test also checks doubleword accesses:
#     5. A doubleword stored with MBE set and read back with MBE clear comes
#        out byte reversed. This checks the 64-bit store swapper.
#     6. A doubleword written little endian and loaded with MBE set comes out
#        byte reversed. This checks the 64-bit load swapper on its own, which
#        a round trip cannot do.
#     7. A doubleword round trip under MBE returns the value unchanged.
#     8. (RV32) Setting MBE leaves SBE and UBE at zero when S-mode or U-mode
#        is not implemented: they are read-only zero then.
# ------------------------------------------------------------------------------

#include "encoding.h"

#define MSTATUSH      0x310
#define MSTATUSH_MBE  0x20
#define MSTATUS_MBE_BIT 37

    .text
    .globl main
main:
    mv    s1, ra                # main calls check_sbe_ube

#if __riscv_xlen == 32

    # --------------------------------------------------------------------
    # Scenario 4a: MBE reads back what was written
    # --------------------------------------------------------------------
    li    t0, MSTATUSH_MBE
    csrs  MSTATUSH, t0
    csrr  t1, MSTATUSH
    and   t2, t1, t0
    beqz  t2, fail              # the bit did not stick
    call  check_sbe_ube

    # --------------------------------------------------------------------
    # Scenario 1: a round trip under MBE returns the value unchanged
    # Both the store and the load swap, so the two cancel.
    # --------------------------------------------------------------------
    la    t3, scratch
    li    t4, 0x12345678
    sw    t4, 0(t3)
    lw    t5, 0(t3)
    bne   t5, t4, fail

    # --------------------------------------------------------------------
    # Scenario 3: a byte is never swapped
    # --------------------------------------------------------------------
    li    t4, 0xA5
    sb    t4, 4(t3)
    lbu   t5, 4(t3)
    bne   t5, t4, fail

    # --------------------------------------------------------------------
    # Scenario 2: stored under MBE, read back without it, byte reversed
    # This is what tells a working store swapper from a missing one.
    # --------------------------------------------------------------------
    la    t3, scratch
    li    t4, 0x12345678
    sw    t4, 8(t3)

    li    t0, MSTATUSH_MBE
    csrc  MSTATUSH, t0          # back to little endian

    lw    t5, 8(t3)
    li    t6, 0x78563412        # 0x12345678 with its bytes reversed
    bne   t5, t6, fail

    # --------------------------------------------------------------------
    # Scenario 4b: with MBE clear the round trip is plain again
    # --------------------------------------------------------------------
    li    t4, 0x0BADCAFE
    sw    t4, 12(t3)
    lw    t5, 12(t3)
    bne   t5, t4, fail

    # MBE reads back clear
    csrr  t1, MSTATUSH
    andi  t2, t1, MSTATUSH_MBE
    bnez  t2, fail

#else

    li    t0, 1
    slli  t0, t0, MSTATUS_MBE_BIT   # t0 = mstatus.MBE
    la    t3, scratch
    li    t4, 0x0123456789ABCDEF
    li    t6, 0xEFCDAB8967452301    # t4 with its bytes reversed

    # --------------------------------------------------------------------
    # Scenario 4a: MBE reads back what was written
    # --------------------------------------------------------------------
    csrs  mstatus, t0
    csrr  t1, mstatus
    and   t2, t1, t0
    beqz  t2, fail              # the bit did not stick

    # --------------------------------------------------------------------
    # Scenario 7: a doubleword round trip under MBE returns the value
    # --------------------------------------------------------------------
    sd    t4, 0(t3)
    ld    t5, 0(t3)
    bne   t5, t4, fail

    # --------------------------------------------------------------------
    # Scenario 1: a word round trip under MBE returns the value
    # --------------------------------------------------------------------
    li    a1, 0x12345678
    sw    a1, 8(t3)
    lwu   a2, 8(t3)
    bne   a2, a1, fail

    # --------------------------------------------------------------------
    # Scenario 5: stored under MBE, read back without it, byte reversed
    # --------------------------------------------------------------------
    sd    t4, 16(t3)
    csrc  mstatus, t0           # back to little endian
    ld    t5, 16(t3)
    bne   t5, t6, fail

    # --------------------------------------------------------------------
    # Scenario 6: written little endian, loaded under MBE, byte reversed
    # --------------------------------------------------------------------
    sd    t4, 24(t3)
    csrs  mstatus, t0
    ld    t5, 24(t3)
    csrc  mstatus, t0
    bne   t5, t6, fail

    # --------------------------------------------------------------------
    # Scenario 4b: with MBE clear the round trip is plain again
    # --------------------------------------------------------------------
    sd    t4, 32(t3)
    ld    t5, 32(t3)
    bne   t5, t4, fail
    csrr  t1, mstatus
    and   t2, t1, t0
    bnez  t2, fail

#endif

pass:
    li    a0, 0
    mv    ra, s1
    ret

#if __riscv_xlen == 32
    # --------------------------------------------------------------------
    # Scenario 8, with MBE just set: SBE and UBE are read-only zero when the
    # mode they control is not implemented (misa.S, misa.U). Leaf function:
    # uses t1, t2, a3 only and does no memory access, MBE being set.
    # RV32 only: every RV64 target has S-mode and U-mode, and the RV64 misa
    # read trips the MXL coverage of the testbench register model.
    # --------------------------------------------------------------------
check_sbe_ube:
    csrr  a3, misa
    srli  t2, a3, 18            # misa.S
    andi  t2, t2, 1
    bnez  t2, 1f
    csrr  t1, MSTATUSH
    andi  t1, t1, 0x10          # mstatush.SBE
    bnez  t1, fail
1:
    srli  t2, a3, 20            # misa.U
    andi  t2, t2, 1
    bnez  t2, 2f
    csrr  t1, mstatus
    andi  t1, t1, 0x40          # mstatus.UBE
    bnez  t1, fail
2:
    ret
#endif

fail:
    # leave the core little endian whatever happens, so the exit path works
#if __riscv_xlen == 32
    li    t0, MSTATUSH_MBE
    csrc  MSTATUSH, t0
#else
    li    t0, 1
    slli  t0, t0, MSTATUS_MBE_BIT
    csrc  mstatus, t0
#endif
    li    a0, 1
    mv    ra, s1
    ret

    .data
    .align 6
scratch:
    .zero 64
