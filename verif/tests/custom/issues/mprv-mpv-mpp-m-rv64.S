# Copyright 2026 10x Engineers
#
# Licensed under the Solderpad Hardware Licence, Version 2.0.
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
#
# Issue #3399: with MPRV=1 and MPP=M, a load or store is an M-level access
# with no translation, also when MPV=1.
#   1. vsatp Sv39 with an empty root, hgatp Bare: a load from page_a reads page_a.
#   2. vsatp Bare, hgatp Sv39x4 with an empty root: a load from page_a reads page_a.
#   3. vsatp and hgatp as in 2: a store to page_a writes page_a.
# The exit code is the number of the check that fails.

  .equ MSTATUS_MPP,      0x0000000000001800
  .equ MSTATUS_MPRV,     0x0000000000020000
  .equ MSTATUS_MPV,      0x0000008000000000
  .equ SATP_SV39,        0x8000000000000000
  .equ HGATP_SV39X4,     0x8000000000000000
  .equ PATTERN_A,        0x1111111111111111
  .equ PATTERN_C,        0x3333333333333333

# Set MPRV=1, MPV=1 and MPP=M.
  .macro MPRV_ON
  li t0, MSTATUS_MPP | MSTATUS_MPV | MSTATUS_MPRV
  csrs mstatus, t0
  .endm

# Clear MPRV and MPV. The check fails with code \num when the access trapped.
  .macro MPRV_OFF num
  li t0, MSTATUS_MPRV | MSTATUS_MPV
  csrc mstatus, t0
  li a0, \num
  la t0, trap_cause
  ld t1, 0(t0)
  bnez t1, fail
  .endm

  .section .text
  .globl main
main:
  li t0, -1
  csrw pmpaddr0, t0
  li t0, 0x1f
  csrw pmpcfg0, t0
  csrw satp, zero

  li t0, PATTERN_A
  la t3, page_a
  sd t0, 0(t3)

  # 1. vsatp Sv39 with an empty root, hgatp Bare
  csrw hgatp, zero
  la t0, empty_root
  srli t0, t0, 12
  li t1, SATP_SV39
  or t0, t0, t1
  csrw vsatp, t0
  hfence.vvma
  hfence.gvma
  li t2, 0
  MPRV_ON
  .option push
  .option norvc
  ld t2, 0(t3)
  .option pop
  MPRV_OFF 1
  li t1, PATTERN_A
  bne t2, t1, fail

  # 2. vsatp Bare, hgatp Sv39x4 with an empty root
  csrw vsatp, zero
  la t0, empty_gstage_root
  srli t0, t0, 12
  li t1, HGATP_SV39X4
  or t0, t0, t1
  csrw hgatp, t0
  hfence.vvma
  hfence.gvma
  li t2, 0
  MPRV_ON
  .option push
  .option norvc
  ld t2, 0(t3)
  .option pop
  MPRV_OFF 2
  li t1, PATTERN_A
  bne t2, t1, fail

  # 3. Store with the same vsatp and hgatp
  li t2, PATTERN_C
  MPRV_ON
  .option push
  .option norvc
  sd t2, 0(t3)
  .option pop
  MPRV_OFF 3
  ld t1, 0(t3)
  bne t1, t2, fail

  csrw hgatp, zero
  hfence.gvma
  li a0, 0
fail:
  tail exit

  .globl handle_trap
handle_trap:
  li t0, MSTATUS_MPRV | MSTATUS_MPV
  csrc mstatus, t0
  la t0, trap_cause
  sd a0, 0(t0)
  # Skip the access.
  addi a0, a1, 4
  ret

  .section .data
  .align 3
trap_cause:
  .dword 0
  .balign 4096
page_a:
  .zero 4096

  .section .page_table, "aw", @progbits
  # The Sv39x4 root is 16 KiB and 16 KiB aligned.
  .balign 16384
empty_gstage_root:
  .zero 16384
empty_root:
  .zero 4096
