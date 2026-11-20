# ------------------------------------------------------------------------------
#   Copyright 2026 Thales France
#
#   Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
#   You may obtain a copy of the License at https://solderpad.org/licenses/
# ------------------------------------------------------------------------------
#   alu_chain_test.S
#
#   Exercises pairs of dependent ALU instructions, the shape a superscalar
#   configuration can fuse by chaining ALU1 into ALU2. The arithmetic is the
#   same whether the pair is fused or stalled, so this test does not tell one
#   from the other: it checks that the results stay correct either way, and it
#   gives the fused path something to work on.
#
#   CPOP and CPOPW are covered on purpose: popcount is the slowest operator of
#   the ALU, so it is excluded from the fusion and takes a separate operand path.
#
#   Runs on RV32 and RV64. The Zbb instructions are emitted only when the
#   toolchain reports Zbb, so a target without bitmanip still runs the rest.
# ------------------------------------------------------------------------------

    .text
    .globl main
main:

    # --------------------------------------------------------------------
    # Dependency through rs1: the second instruction reads the result of
    # the first.
    # --------------------------------------------------------------------
    li  t0, 0x100
    li  t1, 0x020
    add t2, t0, t1              # t2 = 0x120
    add t3, t2, t1              # t3 = 0x140, rs1 depends on t2
    li  t4, 0x140
    bne t3, t4, fail

    # --------------------------------------------------------------------
    # Dependency through rs2.
    # --------------------------------------------------------------------
    li  t0, 0x7
    li  t1, 0x3
    sub t2, t0, t1              # t2 = 0x4
    add t3, t1, t2              # t3 = 0x7, rs2 depends on t2
    li  t4, 0x7
    bne t3, t4, fail

    # --------------------------------------------------------------------
    # Both operands come from the same producer.
    # --------------------------------------------------------------------
    li  t0, 0x11
    li  t1, 0x22
    add t2, t0, t1              # t2 = 0x33
    add t3, t2, t2              # t3 = 0x66, rs1 and rs2 both depend on t2
    li  t4, 0x66
    bne t3, t4, fail

    # --------------------------------------------------------------------
    # A chain of four, each reading the one before.
    # --------------------------------------------------------------------
    li   t0, 1
    addi t1, t0, 1              # 2
    addi t2, t1, 1              # 3
    addi t3, t2, 1              # 4
    addi t4, t3, 1              # 5
    li   t5, 5
    bne  t4, t5, fail

    # --------------------------------------------------------------------
    # Destination x0: the result is discarded, and an instruction reading x0
    # right after must get zero, not the dropped value. The pair matches the
    # dependency check on register numbers (rs == rd == 0), so it is what
    # tells a forwarding that honours x0 from one that does not.
    # --------------------------------------------------------------------
    #
    # .insn spells each add out as R-type OP, funct3 0, funct7 0: the
    # assembler would otherwise turn add rd, x0, rs into c.mv, which reads
    # no x0 at all.
    li  t0, 0x55
    li  t1, 0x0A
    li  t3, 0x0A
    .insn r OP, 0, 0, x0, t0, t1    # add x0, t0, t1: discarded
    .insn r OP, 0, 0, t2, x0, t1    # add t2, x0, t1: rs1 = x0, t2 = 0x0A
    bne t2, t3, fail

    .insn r OP, 0, 0, x0, t0, t1    # add x0, t0, t1: discarded
    .insn r OP, 0, 0, t2, t1, x0    # add t2, t1, x0: rs2 = x0, t2 = 0x0A
    bne t2, t3, fail

    .insn r OP, 0, 0, x0, t0, t1    # add x0, t0, t1: discarded
    .insn r OP, 0, 0, t2, x0, x0    # add t2, x0, x0: both, t2 = 0
    bnez t2, fail

    # --------------------------------------------------------------------
    # The older instruction of the pair is a branch. A branch only issues on
    # the branch-capable ALU, so this pair cannot be fused.
    # --------------------------------------------------------------------
    li  t0, 0x8
    li  t1, 0x8
    beq t0, t1, taken
    j   fail
taken:
    add t2, t0, t1              # t2 = 0x10
    li  t3, 0x10
    bne t2, t3, fail

    # --------------------------------------------------------------------
    # Logic and shifts, still as dependent pairs.
    # --------------------------------------------------------------------
    li   t0, 0xF0
    li   t1, 0x3C
    xor  t2, t0, t1             # 0xCC
    and  t3, t2, t1             # 0x0C
    li   t4, 0x0C
    bne  t3, t4, fail

    li   t0, 0x1
    slli t1, t0, 4              # 0x10
    srli t2, t1, 2              # 0x04
    li   t3, 0x04
    bne  t2, t3, fail

    # --------------------------------------------------------------------
    # CPOP and CPOPW, excluded from the fusion.
    # --------------------------------------------------------------------
#ifdef __riscv_zbb
    # A producer feeding cpop: the pair must not be fused, and cpop must
    # still see the value produced.
    li   t0, 0x00FF
    li   t1, 0x0F00
    or   t2, t0, t1             # 0x0FFF, twelve bits set
    cpop t3, t2
    li   t4, 12
    bne  t3, t4, fail

    # cpop as the producer of the next instruction.
    li   t0, 0xFF               # eight bits set
    cpop t1, t0
    addi t2, t1, 1              # 9
    li   t3, 9
    bne  t2, t3, fail

    # Two cpop in a row.
    li   t0, 0x7
    cpop t1, t0                 # 3
    cpop t2, t1                 # popcount(3) = 2
    li   t3, 2
    bne  t2, t3, fail

#if __riscv_xlen == 64
    # CPOPW counts the low word only. Bits set above bit 31 must be ignored,
    # which is what the dedicated operand path has to preserve.
    li    t0, 0x0F
    slli  t1, t0, 32            # bits 32..35 set, low word empty
    ori   t2, t1, 0xFF          # eight bits in the low word
    cpopw t3, t2
    li    t4, 8
    bne   t3, t4, fail

    # A producer feeding cpopw.
    li    t0, 0x3
    slli  t1, t0, 30            # bits 30 and 31
    cpopw t2, t1
    li    t3, 2
    bne   t2, t3, fail
#endif
#endif

    # --------------------------------------------------------------------
    li a0, 0
    ret

fail:
    li a0, 1
    ret
