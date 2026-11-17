// Copyright 2026 OpenHW Group
//
// Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0

// LR is a load: PMP and the MMU must check it with read permission, and a
// fault must use the load cause. SC and the AMOs stay stores.
// Data accesses run in U-mode through mstatus.MPRV.
//
// PMP: page_x is execute-only, page_r is read-only, all other memory is RWX.
// Sv39: VA 0x1000 maps page_ok with PTE V R W U A (D = 0).
//       VA 0x2000 maps page_ok with PTE V X U A D (no R).
//       VA 0x4000 has no valid PTE.

    .equ LOAD_ACCESS_FAULT, 5
    .equ LOAD_PAGE_FAULT,   13
    .equ STORE_PAGE_FAULT,  15
    .equ MSTATUS_MPP,       0x00001800
    .equ MSTATUS_MPRV,      0x00020000
    .equ SATP_MODE_SV39,    0x8000000000000000
    .equ PATTERN,           0x1122334455667788

// One U-mode access that must trap with the given cause.
    .macro FAULT num, insn, addr, cause
    la t1, \addr
    li t0, \cause
    call set_expected
    call enable_u_data
    .option push
    .option norvc
    \insn
    .option pop
    call disable_u_data
    li t0, \num
    call check_count
    .endm

// One U-mode lr.d that must not trap and must read PATTERN.
    .macro LR_OK num, addr
    la t1, \addr
    call enable_u_data
    .option push
    .option norvc
    lr.d t2, (t1)
    .option pop
    call disable_u_data
    li t0, \num
    call check_count
    li t0, PATTERN
    li a0, \num
    bne t2, t0, fail
    .endm

    .section .text
    .globl main
main:
    // PMP entry 0: page_x execute-only, entry 1: page_r read-only,
    // entry 2: all memory RWX.
    la t0, page_x
    srli t0, t0, 2
    ori t0, t0, 0x1ff
    csrw pmpaddr0, t0
    la t0, page_r
    srli t0, t0, 2
    ori t0, t0, 0x1ff
    csrw pmpaddr1, t0
    li t0, -1
    csrw pmpaddr2, t0
    li t0, 0x1f191c
    csrw pmpcfg0, t0

    li t0, PATTERN
    la t1, page_r
    sd t0, 0(t1)
    la t1, page_ok
    sd t0, 0(t1)

    la t0, trap_count
    sd zero, 0(t0)

    // No address translation: PMP checks LR as a read.
    csrw satp, zero
    sfence.vma
    LR_OK 0, page_r
    FAULT 1, "lr.d t2, (t1)", page_x, LOAD_ACCESS_FAULT

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
    // l0_pt[1]: VA 0x1000, V R W U A. l0_pt[2]: VA 0x2000, V X U A D.
    la t1, l0_pt
    la t0, page_ok
    srli t0, t0, 12
    slli t0, t0, 10
    ori t2, t0, 0x57
    sd t2, 8(t1)
    ori t2, t0, 0xd9
    sd t2, 16(t1)

    la t0, root_pt
    srli t0, t0, 12
    li t1, SATP_MODE_SV39
    or t0, t0, t1
    csrw satp, t0

    // Page table walk: LR needs R only, a fault is a load page fault.
    sfence.vma
    LR_OK 1, va_rw_clean
    FAULT 2, "lr.d t2, (t1)", va_x, LOAD_PAGE_FAULT
    FAULT 3, "lr.d t2, (t1)", va_invalid, LOAD_PAGE_FAULT
    // An AMO is still a store: D = 0 gives a store page fault.
    sfence.vma
    FAULT 4, "amoswap.d t2, t2, (t1)", va_rw_clean, STORE_PAGE_FAULT
    // DTLB hit after LR filled the DTLB: SC still needs D = 1.
    sfence.vma
    LR_OK 4, va_rw_clean
    FAULT 5, "sc.d t2, t2, (t1)", va_rw_clean, STORE_PAGE_FAULT
    // DTLB hit: LR to a page without R is a load page fault.
    FAULT 6, "lr.d t2, (t1)", va_x, LOAD_PAGE_FAULT

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
    la t3, trap_count
    ld t3, 0(t3)
    mv a0, t0
    bne t0, t3, fail
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

    .equ va_rw_clean, 0x1000
    .equ va_x,        0x2000
    .equ va_invalid,  0x4000

    .section .data
    .align 3
expected_cause:
    .dword 0
expected_tval:
    .dword 0
trap_count:
    .dword 0
    .balign 4096
page_x:
    .zero 4096
page_r:
    .zero 4096
page_ok:
    .zero 4096

    .section .page_table, "aw", @progbits
    .balign 4096
root_pt:
    .zero 4096
l1_pt:
    .zero 4096
l0_pt:
    .zero 4096
