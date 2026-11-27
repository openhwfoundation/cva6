# Copyright 2026 10x Engineers
#
# Licensed under the Solderpad Hardware Licence, Version 2.0.
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
#
# Issue #3758: in Vectored mode, an interrupt sets pc to BASE + 4 * cause,
# with BASE read back from stvec or vstvec.
# The test writes BASE = vec_table + 0x80, which is not 256-byte aligned.
# Each 4-byte slot of vec_table jumps to slot_entry, which gets the slot
# address from the link register.
#   1, 2. stvec: an S-mode software interrupt enters at BASE + 4.
#   3, 4. vstvec: a VS-mode software interrupt (VS cause 1) enters at BASE + 4.
#   5, 6. Direct mode keeps any 4-byte aligned BASE in stvec and vstvec.
# The exit code is the number of the check that fails.

  .equ MSTATUS_MPP,      0x0000000000001800
  .equ MSTATUS_MPP_S,    0x0000000000000800
  .equ MSTATUS_MPV,      0x0000008000000000
  .equ SSTATUS_SIE,      0x2
  .equ MIP_SSIP,         0x2
  .equ MIP_VSSIP,        0x4
  .equ CAUSE_SSI,        0x8000000000000001
  .equ CAUSE_ECALL_S,    9
  .equ CAUSE_ECALL_VS,   10

  .section .text
  .globl main
main:
  li t0, -1
  csrw pmpaddr0, t0
  li t0, 0x1f
  csrw pmpcfg0, t0
  csrw satp, zero
  csrw vsatp, zero
  csrw hgatp, zero
  csrw medeleg, zero
  csrw hedeleg, zero

  # 5. Direct mode: stvec keeps BASE.
  la t1, vec_table
  addi t1, t1, 0x84
  csrw stvec, t1
  csrr t2, stvec
  li a0, 5
  bne t1, t2, fail

  # 6. Direct mode: vstvec keeps BASE.
  csrw vstvec, t1
  csrr t2, vstvec
  li a0, 6
  bne t1, t2, fail

  # 1, 2. stvec in Vectored mode, S-mode software interrupt.
  la t0, entry_pc
  sd zero, 0(t0)
  sd zero, 8(t0)
  la t1, vec_table
  addi t1, t1, 0x81
  csrw stvec, t1
  csrr s0, stvec
  andi s0, s0, -4
  addi s0, s0, 4             # expected entry: BASE + 4 * 1
  li t0, MIP_SSIP
  csrw mideleg, t0
  csrs mie, t0
  csrs mip, t0
  li t0, SSTATUS_SIE
  csrs sstatus, t0
  li t0, MSTATUS_MPP | MSTATUS_MPV
  csrc mstatus, t0
  li t0, MSTATUS_MPP_S
  csrs mstatus, t0
  la t0, s_resume
  la t1, resume
  sd t0, 0(t1)
  la t0, guest_code
  csrw mepc, t0
  mret
s_resume:
  li a0, 1
  la t0, entry_pc
  ld t1, 0(t0)
  bne t1, s0, fail
  li a0, 2
  ld t1, 8(t0)
  li t2, CAUSE_SSI
  bne t1, t2, fail

  # 3, 4. vstvec in Vectored mode, VS-mode software interrupt.
  la t0, entry_pc
  sd zero, 0(t0)
  sd zero, 8(t0)
  li t0, MIP_SSIP
  csrc mie, t0
  csrw mideleg, zero
  la t1, vec_table
  addi t1, t1, 0x81
  csrw vstvec, t1
  csrr s0, vstvec
  andi s0, s0, -4
  addi s0, s0, 4             # expected entry: BASE + 4 * 1 (VS cause 1)
  li t0, MIP_VSSIP
  csrw hideleg, t0
  csrs hie, t0
  csrs hvip, t0
  li t0, SSTATUS_SIE
  csrs vsstatus, t0
  li t0, MSTATUS_MPP
  csrc mstatus, t0
  li t0, MSTATUS_MPP_S | MSTATUS_MPV
  csrs mstatus, t0
  la t0, vs_resume
  la t1, resume
  sd t0, 0(t1)
  la t0, guest_code
  csrw mepc, t0
  mret
vs_resume:
  li a0, 3
  la t0, entry_pc
  ld t1, 0(t0)
  bne t1, s0, fail
  li a0, 4
  ld t1, 8(t0)
  li t2, CAUSE_SSI
  bne t1, t2, fail

  li a0, 0
fail:
  tail exit

  # S-mode or VS-mode code that waits for the interrupt.
guest_code:
  nop
  ecall

  # Entered from vec_table: save the slot address and scause, clear the
  # interrupt, and return to M-mode.
slot_entry:
  addi t6, t6, -4
  la t5, entry_pc
  sd t6, 0(t5)
  csrr t6, scause
  sd t6, 8(t5)
  csrci sip, MIP_SSIP
  ecall

  .globl handle_trap
handle_trap:
  li t0, CAUSE_ECALL_S
  beq a0, t0, 1f
  li t0, CAUSE_ECALL_VS
  beq a0, t0, 1f
  # Unexpected trap
  li a0, 20
  tail exit
1:
  li t1, MSTATUS_MPV
  csrc mstatus, t1
  li t1, MIP_VSSIP
  csrc hvip, t1
  la t0, resume
  ld a0, 0(t0)
  ret

  .option push
  .option norvc
  .balign 256
vec_table:
  .rept 128
  jal t6, slot_entry
  .endr
  .option pop

  .section .data
  .align 3
entry_pc:
  .dword 0
  .dword 0
resume:
  .dword 0
