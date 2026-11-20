# ------------------------------------------------------------------------------
#   Copyright 2026 Thales France
#
#   Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
#   You may obtain a copy of the License at https://solderpad.org/licenses/
# ------------------------------------------------------------------------------
#   write_policy.S
#
#   Checks the write policy of the data cache in two cacheable regions: wb_word
#   at 0x8010_0000 and wt_word at 0x8020_0000, each in its own cache line.
#   CBO.INVAL invalidates a line without writing it back, so it shows whether a
#   store reached the memory:
#     - write-back: the store stays in the cache, the invalidated line is lost
#       and a load reads the old value back from memory;
#     - write-through: the store went to memory as well, a load reads the new
#       value.
#
#   For each word: load it (the line is allocated in the cache), store NEW,
#   invalidate the line, load it again. Then NEW is stored again in wb_word
#   and its line is flushed with CBO.FLUSH, which writes a dirty line back to
#   memory and invalidates it: the load reads the memory and must find NEW
#   whatever the policy.
#
#   The policy expected for each word is given at build time:
#     -DWB_WORD_WRITES_BACK=0|1  -DWT_WORD_WRITES_BACK=0|1
#   A target whose data cache only writes through expects 0 for both, one that
#   only writes back 1 for both, and one with both policies 1 for wb_word,
#   which it puts in a bufferable region, and 0 for wt_word, outside of it.
#
#   CBO.INVAL runs in M-mode, where it always invalidates; it is encoded with
#   .insn, so the test builds with the march of the target, which does not
#   list Zicbom. Requires RVZiCbom. Runs on RV32 and RV64.
# ------------------------------------------------------------------------------

#ifndef WB_WORD_WRITES_BACK
#error "WB_WORD_WRITES_BACK is not defined"
#endif
#ifndef WT_WORD_WRITES_BACK
#error "WT_WORD_WRITES_BACK is not defined"
#endif

#define OLD_VALUE 0x0123abcd
#define NEW_VALUE 0x4567ef01

    .text
    .globl main
main:
    mv   s9, ra

    # wb_word
    la   a0, wb_word
    li   a1, WB_WORD_WRITES_BACK
    jal  ra, check_word
    bnez a0, fail_wb

    # wt_word
    la   a0, wt_word
    li   a1, WT_WORD_WRITES_BACK
    jal  ra, check_word
    bnez a0, fail_wt

    # A dirty write-back line goes back to memory on CBO.FLUSH
    la   t5, wb_word
    li   t1, NEW_VALUE
    sw   t1, 0(t5)
    fence rw, rw
    .insn i 0x0f, 2, x0, 2(t5)       # cbo.flush (t5)
    fence rw, rw
    lw   t0, 0(t5)
    bne  t0, t1, fail_flush

    li   a0, 0
    j    end
fail_flush:
    li   a0, 3
    j    end
fail_wb:
    li   a0, 1
    j    end
fail_wt:
    li   a0, 2
end:
    mv   ra, s9
    ret

# a0: address of the word, a1: 1 if it writes back, 0 if it writes through
# returns a0 = 0 when the word behaves as expected
check_word:
    mv   t6, ra
    mv   t5, a0

    # allocate the line in the cache
    lw   t0, 0(t5)
    li   t1, OLD_VALUE
    bne  t0, t1, bad

    # store, then drop the line without writing it back
    li   t1, NEW_VALUE
    sw   t1, 0(t5)
    fence rw, rw
    .insn i 0x0f, 2, x0, 0(t5)       # cbo.inval (t5)
    fence rw, rw

    lw   t0, 0(t5)
    li   t1, OLD_VALUE              # write-back: the store was lost
    bnez a1, 1f
    li   t1, NEW_VALUE              # write-through: the store reached memory
1:
    bne  t0, t1, bad

    li   a0, 0
    mv   ra, t6
    ret
bad:
    li   a0, 1
    mv   ra, t6
    ret

    # At fixed addresses, so that a target can put wb_word in a bufferable
    # region and leave wt_word out of it: the image of a test stays well
    # below 1 MiB from 0x8000_0000, and both are in cacheable memory.
    .section .write_policy_wb, "aw", @progbits
    .globl wb_word
wb_word:
    .word OLD_VALUE
    .section .write_policy_wt, "aw", @progbits
    .globl wt_word
wt_word:
    .word OLD_VALUE
