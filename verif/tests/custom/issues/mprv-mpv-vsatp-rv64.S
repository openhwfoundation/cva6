# Copyright 2026 10x Engineers
#
# Licensed under the Solderpad Hardware Licence, Version 2.0.
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
#
# Issue #3759: with MPRV=1, MPV=1 and MPP=S, vsatp controls the VS stage of
# the load, not satp. hgatp is Bare, so the guest physical address is the
# physical address.
# VA 0x1000 maps page_b in the Sv39 tables at pt_root.
#   1. satp Bare, vsatp Sv39: a load from VA 0x1000 reads page_b.
#   2. satp Sv39 with an empty root, vsatp Bare: a load from page_a reads page_a.
#   3. MPV=0: satp Sv39, vsatp Bare: a load from VA 0x1000 reads page_b.
# The exit code is the number of the check that fails.

  .equ MSTATUS_MPP,      0x0000000000001800
  .equ MSTATUS_MPP_S,    0x0000000000000800
  .equ MSTATUS_MPRV,     0x0000000000020000
  .equ MSTATUS_MPV,      0x0000008000000000
  .equ SATP_SV39,        0x8000000000000000
  .equ PATTERN_A,        0x1111111111111111
  .equ PATTERN_B,        0x2222222222222222
  .equ VA_PAGE_B,        0x1000

# Load from the address in t3 with MPRV=1, MPP=S and MPV=\mpv. The check
# fails with code \num when the load traps or does not read \value.
  .macro MPRV_LOAD num, mpv, value
  li t0, MSTATUS_MPP | MSTATUS_MPV
  csrc mstatus, t0
  li t0, MSTATUS_MPP_S | (\mpv * MSTATUS_MPV) | MSTATUS_MPRV
  csrs mstatus, t0
  li t2, 0
  .option push
  .option norvc
  ld t2, 0(t3)
  .option pop
  li t0, MSTATUS_MPRV
  csrc mstatus, t0
  li a0, \num
  la t0, trap_cause
  ld t1, 0(t0)
  bnez t1, fail
  li t1, \value
  bne t2, t1, fail
  .endm

  .section .text
  .globl main
main:
  # All memory is RWX for S-mode and U-mode.
  li t0, -1
  csrw pmpaddr0, t0
  li t0, 0x1f
  csrw pmpcfg0, t0
  csrw hgatp, zero

  li t0, PATTERN_A
  la t1, page_a
  sd t0, 0(t1)
  li t0, PATTERN_B
  la t1, page_b
  sd t0, 0(t1)

  # pt_root[0] -> pt_l1, pt_l1[0] -> pt_l0, pt_l0[1]: VA 0x1000 -> page_b, V R W A D
  la t1, pt_root
  la t0, pt_l1
  srli t0, t0, 12
  slli t0, t0, 10
  ori t0, t0, 1
  sd t0, 0(t1)
  la t1, pt_l1
  la t0, pt_l0
  srli t0, t0, 12
  slli t0, t0, 10
  ori t0, t0, 1
  sd t0, 0(t1)
  la t1, pt_l0
  la t0, page_b
  srli t0, t0, 12
  slli t0, t0, 10
  ori t0, t0, 0xc7
  sd t0, 8(t1)

  # 1. satp Bare, vsatp Sv39
  csrw satp, zero
  la t0, pt_root
  srli t0, t0, 12
  li t1, SATP_SV39
  or t0, t0, t1
  csrw vsatp, t0
  sfence.vma
  hfence.vvma
  li t3, VA_PAGE_B
  MPRV_LOAD 1, 1, PATTERN_B

  # 2. satp Sv39 with an empty root, vsatp Bare
  la t0, empty_root
  srli t0, t0, 12
  li t1, SATP_SV39
  or t0, t0, t1
  csrw satp, t0
  csrw vsatp, zero
  sfence.vma
  hfence.vvma
  la t3, page_a
  MPRV_LOAD 2, 1, PATTERN_A

  # 3. MPV=0: satp Sv39, vsatp Bare
  la t0, pt_root
  srli t0, t0, 12
  li t1, SATP_SV39
  or t0, t0, t1
  csrw satp, t0
  sfence.vma
  li t3, VA_PAGE_B
  MPRV_LOAD 3, 0, PATTERN_B

  csrw satp, zero
  sfence.vma
  li a0, 0
fail:
  tail exit

  .globl handle_trap
handle_trap:
  li t0, MSTATUS_MPRV
  csrc mstatus, t0
  la t0, trap_cause
  sd a0, 0(t0)
  # Skip the load.
  addi a0, a1, 4
  ret

  .section .data
  .align 3
trap_cause:
  .dword 0
  .balign 4096
page_a:
  .zero 4096
page_b:
  .zero 4096

  .section .page_table, "aw", @progbits
  .balign 4096
pt_root:
  .zero 4096
pt_l1:
  .zero 4096
pt_l0:
  .zero 4096
empty_root:
  .zero 4096
