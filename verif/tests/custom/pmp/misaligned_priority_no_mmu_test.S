// Copyright 2026 OpenHW Group
//
// Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0

// With no address translation, PMP checks the physical address of each data
// access. A misaligned access that PMP also denies must give the address
// misaligned exception, because CVA6 raises it before the PMP check.
// Data accesses run in U-mode through mstatus.MPRV, with satp = 0.
// PMP makes data_page execute-only. ok_page has no PMP restriction.

    .equ LOAD_ACCESS_FAULT,  5
    .equ STORE_ACCESS_FAULT, 7
    .equ LD_ADDR_MISALIGNED, 4
    .equ ST_ADDR_MISALIGNED, 6
    .equ MSTATUS_MPP,        0x00001800
    .equ MSTATUS_MPRV,       0x00020000

// Do one U-mode access that must trap with the given cause, then check the trap count.
    .macro FAULT num, insn, addr, cause
    la t1, \addr
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
    csrw satp, zero
    sfence.vma

    la t0, trap_count
    sd zero, 0(t0)

    // PMP fault only.
    FAULT 1, lw, data_page, LOAD_ACCESS_FAULT
    FAULT 2, sw, data_page, STORE_ACCESS_FAULT
    // Misaligned and PMP fault.
    FAULT 3, lw, data_page + 2, LD_ADDR_MISALIGNED
    FAULT 4, sw, data_page + 2, ST_ADDR_MISALIGNED
    // Misaligned only.
    FAULT 5, lw, ok_page + 2, LD_ADDR_MISALIGNED

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

// Data accesses use U-mode privilege.
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
ok_page:
    .zero 4096
