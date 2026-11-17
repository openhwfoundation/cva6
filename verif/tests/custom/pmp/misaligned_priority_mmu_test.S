// Copyright 2026 OpenHW Group
//
// Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0

// CVA6 does not support misaligned data accesses, and raises the address
// misaligned exception before address translation and the PMP check.
// A misaligned access that also has a page fault or a PMP fault must give
// the address misaligned exception.
// Data accesses run in U-mode with Sv39 through mstatus.MPRV.
//
// VA 0x1000: data_page, PTE V X U A D (no R, no W).
// VA 0x2000: data_page, PTE V R U A D. PMP makes data_page execute-only.
// VA 0x4000: no valid PTE.

    .equ LD_ADDR_MISALIGNED, 4
    .equ ST_ADDR_MISALIGNED, 6
    .equ MSTATUS_MPP,        0x00001800
    .equ MSTATUS_MPRV,       0x00020000
    .equ SATP_MODE_SV39,     0x8000000000000000

// Do one U-mode access that must trap with the given cause, then check the trap count.
    .macro FAULT num, insn, addr, cause
    li t1, \addr
    li t0, \cause
    call set_expected
    call enable_u_data
    .option push
    .option norvc
    \insn t2, 0(t1)
    .option pop
    call disable_u_data
    li t0, \num
    call check_count
    .endm

    .section .text
    .globl main
main:
    // PMP entry 0: data_page execute-only, entry 1: all memory RWX.
    la t0, data_page
    srli t0, t0, 2
    ori t0, t0, 0x1ff
    csrw pmpaddr0, t0
    li t0, -1
    csrw pmpaddr1, t0
    li t0, 0x1f1c
    csrw pmpcfg0, t0

    // root_pt[0] -> l1_pt, l1_pt[0] -> l0_pt
    la t1, root_pt
    la t0, l1_pt
    srli t0, t0, 12
    slli t0, t0, 10
    ori t0, t0, 1
    sd t0, 0(t1)
    la t1, l1_pt
    la t0, l0_pt
    srli t0, t0, 12
    slli t0, t0, 10
    ori t0, t0, 1
    sd t0, 0(t1)
    // l0_pt[1], l0_pt[2]: data_page. l0_pt[4] stays invalid.
    la t1, l0_pt
    la t0, data_page
    srli t0, t0, 12
    slli t0, t0, 10
    ori t2, t0, 0xd9
    sd t2, 8(t1)
    ori t2, t0, 0xd3
    sd t2, 16(t1)

    la t0, root_pt
    srli t0, t0, 12
    li t1, SATP_MODE_SV39
    or t0, t0, t1
    csrw satp, t0
    sfence.vma

    la t0, trap_count
    sd zero, 0(t0)

    // Misaligned and page fault (no R, no W).
    FAULT 1, lw, 0x1002, LD_ADDR_MISALIGNED
    FAULT 2, sw, 0x1002, ST_ADDR_MISALIGNED
    // Misaligned and page fault (invalid PTE).
    FAULT 3, lw, 0x4002, LD_ADDR_MISALIGNED
    // Misaligned and PMP fault.
    FAULT 4, lw, 0x2002, LD_ADDR_MISALIGNED

    li a0, 0
    tail exit

fail:
    tail exit

// t0: expected mcause, t1: expected mtval
set_expected:
    la t2, expected_cause
    sd t0, 0(t2)
    sd t1, 8(t2)
    ret

// Data accesses use U-mode privilege and translation.
enable_u_data:
    li t0, MSTATUS_MPP
    csrc mstatus, t0
    li t0, MSTATUS_MPRV
    csrs mstatus, t0
    ret

disable_u_data:
    li t0, MSTATUS_MPRV
    csrc mstatus, t0
    ret

// t0: expected number of traps. On a mismatch, the exit code is the check number.
check_count:
    la t1, trap_count
    ld t1, 0(t1)
    mv a0, t0
    bne t0, t1, fail
    ret

    .globl handle_trap
handle_trap:
    li t0, MSTATUS_MPRV
    csrc mstatus, t0
    la t2, trap_count
    ld t3, 0(t2)
    addi t3, t3, 1
    sd t3, 0(t2)
    la t2, expected_cause
    ld t1, 0(t2)
    bne a0, t1, trap_fail
    csrr t0, mtval
    ld t1, 8(t2)
    bne t0, t1, trap_fail
    // crt.S writes the returned address to mepc. Skip the faulting access.
    addi a0, a1, 4
    ret

trap_fail:
    addi a0, t3, 100
    tail exit

    .section .data
    .align 3
expected_cause:
    .dword 0
expected_tval:
    .dword 0
trap_count:
    .dword 0
    .balign 4096
data_page:
    .zero 4096

    .section .page_table, "aw", @progbits
    .balign 4096
root_pt:
    .zero 4096
l1_pt:
    .zero 4096
l0_pt:
    .zero 4096
