# Copyright 2026 10x Engineers
#
# Licensed under the Solderpad Hardware Licence, Version 2.0.
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
#
# Each row of the table "Effect of MPRV on the translation and protection of
# explicit memory accesses" (Hypervisor extension, mstatus.MPRV).
#
# Memory:
#   slot k  : VA slots + k * 4 KiB. The physical page holds PAT_M.
#   gslot k : GPA gslots + k * 4 KiB. The physical page holds PAT_G.
#   page_d  : the target of each leaf. It holds PAT_D. Its own GPA is not mapped.
#   scratch : not mapped in a stage. It holds PAT_G.
# Slots 0 to 5 are mapped only by satp. Slots 8 to 23 are mapped only by vsatp,
# to gslot k, and the G-stage maps gslot k to page_d. The G-stage maps the other
# pages to the same address.
# Checks 1 to 87: satp, vsatp and hgatp are on. Checks 90 to 98: one of satp,
# vsatp or hgatp is Bare.
#
#   slot  satp       vsatp      G-stage
#   0     RW  U=0    -          -
#   1     RW  U=1    -          -
#   2     X   U=0    -          -
#   3     X   U=1    -          -
#   4     R   U=0    -          -
#   5     R   U=1    -          -
#   8     -          RW  U=0    RWX
#   9     -          RW  U=1    RWX
#   10    -          X   U=0    RWX
#   11    -          X   U=1    RWX
#   12    -          R   U=0    RWX
#   13    -          R   U=1    RWX
#   14    -          RW  U=0    X
#   15    -          RW  U=1    X
#   16    -          X   U=0    X
#   17    -          X   U=1    X
#   18    -          RW  U=0    invalid
#   19    -          RW  U=1    invalid
#   20    -          RW  U=0    RW with U=0
#   21    -          RW  U=1    RW with U=0
#   22    -          RW  U=0    R
#   23    -          RW  U=1    R
#
# A check fails with exit code N when the trap cause or the data is wrong, and
# with N + 128 when mtval is not the access address.
# Each check starts with empty TLBs. With KEEP_TLB, the checks reuse the TLB
# entries (MXR changes with a TLB hit are issue #3298). With CONTINUE, all checks
# run, each failing code goes to s4 and the exit code is the failure count.

  .option norvc

  .equ MSTATUS_MPP,   0x0000000000001800
  .equ MSTATUS_MPRV,  0x0000000000020000
  .equ MSTATUS_SUM,   0x0000000000040000
  .equ MSTATUS_MXR,   0x0000000000080000
  .equ MSTATUS_MPV,   0x0000008000000000
  .equ HSTATUS_SPVP,  0x0000000000000100
  .equ P_U,           0x0000000000000000
  .equ P_S,           0x0000000000000800
  .equ P_M,           0x0000000000001800
  .equ MPRV,          MSTATUS_MPRV
  .equ MPV,           MSTATUS_MPV
  .equ SUM,           MSTATUS_SUM
  .equ MXR,           MSTATUS_MXR
  .equ ATP_SV39,      0x8000000000000000
  .equ PAT_M,         0x4d4d4d4d4d4d4d4d
  .equ PAT_G,         0x4747474747474747
  .equ PAT_D,         0x4444444444444444

  # Load (op 0), store (op 1) or hlv.d (op 2)
  .equ LD, 0
  .equ ST, 1
  .equ HLV, 2

  # Exception causes
  .equ LPF, 13
  .equ SPF, 15
  .equ LGPF, 21
  .equ SGPF, 23

  # Leaf flags: V R W X U A D
  .equ RW_U0,  0xc7
  .equ RW_U1,  0xd7
  .equ X_U0,   0xc9
  .equ X_U1,   0xd9
  .equ R_U0,   0xc3
  .equ R_U1,   0xd3
  .equ RWX_U1, 0xdf

  .equ VA_SCRATCH, 30
  .equ PG_D, 31

# Fail with the code in a0 when \a and \b are not equal.
  .macro FAIL_NE a, b
#ifdef CONTINUE
  beq \a, \b, 1f
  jal record_fail
1:
#else
  bne \a, \b, fail
#endif
  .endm

# Check \num: set mstatus to \mbits and vsstatus to \vsbits, then do \op at
# \va. \cause is the expected trap cause, 0 for no trap. With no trap, \chk is
# the expected load value, or for a store the physical address of the page that
# must hold the store data at offset 8.
  .macro CASE num, mbits, vsbits, va, op, cause, chk
#ifndef KEEP_TLB
  sfence.vma
  hfence.vvma
  hfence.gvma
#endif
  li t0, MSTATUS_MPRV | MSTATUS_MPP | MSTATUS_MPV | MSTATUS_SUM | MSTATUS_MXR
  csrc mstatus, t0
  li t0, MSTATUS_SUM | MSTATUS_MXR
  csrc vsstatus, t0
  li t0, \vsbits
  csrs vsstatus, t0
  la t3, \va
  li t5, 0x5a00 + \num
  .if (\op == ST) && (\cause == 0)
  la t4, \chk
  sd zero, 8(t4)
  .endif
  li s10, 0
  li s11, 0
  li t2, 0
  li t0, \mbits
  csrs mstatus, t0
  .if \op == LD
  ld t2, 0(t3)
  .elseif \op == ST
  sd t5, 8(t3)
  .else
  hlv.d t2, (t3)
  .endif
  csrc mstatus, s9
  li a0, \num
  li t0, \cause
  FAIL_NE s10, t0
  .if \cause
  li a0, \num + 128
  .if \op == ST
  addi t3, t3, 8
  .endif
  FAIL_NE s11, t3
  .else
  .if \op == ST
  ld t1, 8(t4)
  FAIL_NE t1, t5
  .else
  li t0, \chk
  FAIL_NE t2, t0
  .endif
  .endif
  .endm

# Write the leaf PTE for \va in the level 0 table \l0: \pa with \flags.
  .macro LEAF l0, va, pa, flags
  la a0, \l0
  la a1, \va
  la a2, \pa
  li a3, \flags
  jal map_leaf
  .endm

  .section .text
  .globl main
main:
  # All memory is RWX for S-mode and U-mode.
  li t0, -1
  csrw pmpaddr0, t0
  li t0, 0x1f
  csrw pmpcfg0, t0
  csrr s7, mtvec
  la t0, mprv_trap
  csrw mtvec, t0
  li s9, MSTATUS_MPRV
  li s5, 0
  csrw medeleg, zero
  csrw hedeleg, zero

  # Physical contents
  la t0, slots
  li t1, PAT_M
  la t2, gslots
1:
  sd t1, 0(t0)
  addi t0, t0, 1024
  addi t0, t0, 1024
  addi t0, t0, 1024
  addi t0, t0, 1024
  bltu t0, t2, 1b
  li t1, PAT_G
  la t2, page_d
2:
  sd t1, 0(t0)
  addi t0, t0, 1024
  addi t0, t0, 1024
  addi t0, t0, 1024
  addi t0, t0, 1024
  bltu t0, t2, 2b
  li t1, PAT_D
  sd t1, 0(t2)

  # satp and vsatp tables: root -> l1 -> l0 for the slots
  la a0, hs_root
  la a1, hs_l1
  la a2, hs_l0
  jal link_tables
  la a0, vs_root
  la a1, vs_l1
  la a2, vs_l0
  jal link_tables

  LEAF hs_l0, slots + 0 * 4096, page_d, RW_U0
  LEAF hs_l0, slots + 1 * 4096, page_d, RW_U1
  LEAF hs_l0, slots + 2 * 4096, page_d, X_U0
  LEAF hs_l0, slots + 3 * 4096, page_d, X_U1
  LEAF hs_l0, slots + 4 * 4096, page_d, R_U0
  LEAF hs_l0, slots + 5 * 4096, page_d, R_U1

  LEAF vs_l0, slots + 8 * 4096, gslots + 8 * 4096, RW_U0
  LEAF vs_l0, slots + 9 * 4096, gslots + 9 * 4096, RW_U1
  LEAF vs_l0, slots + 10 * 4096, gslots + 10 * 4096, X_U0
  LEAF vs_l0, slots + 11 * 4096, gslots + 11 * 4096, X_U1
  LEAF vs_l0, slots + 12 * 4096, gslots + 12 * 4096, R_U0
  LEAF vs_l0, slots + 13 * 4096, gslots + 13 * 4096, R_U1
  LEAF vs_l0, slots + 14 * 4096, gslots + 14 * 4096, RW_U0
  LEAF vs_l0, slots + 15 * 4096, gslots + 15 * 4096, RW_U1
  LEAF vs_l0, slots + 16 * 4096, gslots + 16 * 4096, X_U0
  LEAF vs_l0, slots + 17 * 4096, gslots + 17 * 4096, X_U1
  LEAF vs_l0, slots + 18 * 4096, gslots + 18 * 4096, RW_U0
  LEAF vs_l0, slots + 19 * 4096, gslots + 19 * 4096, RW_U1
  LEAF vs_l0, slots + 20 * 4096, gslots + 20 * 4096, RW_U0
  LEAF vs_l0, slots + 21 * 4096, gslots + 21 * 4096, RW_U1
  LEAF vs_l0, slots + 22 * 4096, gslots + 22 * 4096, RW_U0
  LEAF vs_l0, slots + 23 * 4096, gslots + 23 * 4096, RW_U1

  # G-stage: an identity map of the 1 GiB at 0x80000000 with 2 MiB leaves, but
  # the 2 MiB that holds gslots uses g_l0 with 4 KiB leaves.
  la t0, g_l1
  li t1, (0x80000000 >> 12) << 10 | RWX_U1
  li t2, 512
  li t3, (0x200000 >> 12) << 10
3:
  sd t1, 0(t0)
  add t1, t1, t3
  addi t0, t0, 8
  addi t2, t2, -1
  bnez t2, 3b
  la t0, g_l0
  la t1, gslots
  li t2, ~0x1fffff
  and t1, t1, t2
  srli t1, t1, 12
  slli t1, t1, 10
  ori t1, t1, RWX_U1
  li t2, 512
  li t3, 1 << 10
4:
  sd t1, 0(t0)
  add t1, t1, t3
  addi t0, t0, 8
  addi t2, t2, -1
  bnez t2, 4b
  # g_root[2] -> g_l1, g_l1[gslots VPN1] -> g_l0
  la a0, g_root + 2 * 8
  la a1, g_l1
  jal write_ptr
  la a1, gslots
  srli a1, a1, 21
  andi a1, a1, 511
  slli a1, a1, 3
  la a0, g_l1
  add a0, a0, a1
  la a1, g_l0
  jal write_ptr

  LEAF g_l0, gslots + 8 * 4096, page_d, RWX_U1
  LEAF g_l0, gslots + 9 * 4096, page_d, RWX_U1
  LEAF g_l0, gslots + 10 * 4096, page_d, RWX_U1
  LEAF g_l0, gslots + 11 * 4096, page_d, RWX_U1
  LEAF g_l0, gslots + 12 * 4096, page_d, RWX_U1
  LEAF g_l0, gslots + 13 * 4096, page_d, RWX_U1
  LEAF g_l0, gslots + 14 * 4096, page_d, X_U1
  LEAF g_l0, gslots + 15 * 4096, page_d, X_U1
  LEAF g_l0, gslots + 16 * 4096, page_d, X_U1
  LEAF g_l0, gslots + 17 * 4096, page_d, X_U1
  LEAF g_l0, gslots + 18 * 4096, page_d, 0
  LEAF g_l0, gslots + 19 * 4096, page_d, 0
  LEAF g_l0, gslots + 20 * 4096, page_d, RW_U0
  LEAF g_l0, gslots + 21 * 4096, page_d, RW_U0
  LEAF g_l0, gslots + 22 * 4096, page_d, R_U1
  LEAF g_l0, gslots + 23 * 4096, page_d, R_U1
  LEAF g_l0, scratch, scratch, 0
  LEAF g_l0, page_d, page_d, 0

  la t0, hs_root
  srli t0, t0, 12
  li t1, ATP_SV39
  or t0, t0, t1
  csrw satp, t0
  la t0, vs_root
  srli t0, t0, 12
  or t0, t0, t1
  csrw vsatp, t0
  la t0, g_root
  srli t0, t0, 12
  or t0, t0, t1
  csrw hgatp, t0
  sfence.vma
  hfence.vvma
  hfence.gvma

  # MPRV=0: the access uses M-mode, with no translation.
  CASE 1, P_S | MPV, 0, scratch, LD, 0, PAT_G
  CASE 2, P_U, 0, scratch, LD, 0, PAT_G
  CASE 3, P_S | MPV, 0, scratch, ST, 0, scratch
  CASE 4, P_S | SUM | MXR, 0, slots, LD, 0, PAT_M

  # MPRV=1, MPV=0, MPP=U: U-level access with satp only.
  CASE 10, MPRV | P_U, 0, slots + 1 * 4096, LD, 0, PAT_D
  CASE 11, MPRV | P_U, 0, slots + 1 * 4096, ST, 0, page_d
  CASE 12, MPRV | P_U, 0, slots + 0 * 4096, LD, LPF, 0
  CASE 13, MPRV | P_U, 0, slots + 0 * 4096, ST, SPF, 0
  CASE 14, MPRV | P_U | SUM, 0, slots + 0 * 4096, LD, LPF, 0
  CASE 15, MPRV | P_U, 0, slots + 3 * 4096, LD, LPF, 0
  CASE 16, MPRV | P_U | MXR, 0, slots + 3 * 4096, LD, 0, PAT_D
  CASE 17, MPRV | P_U, MXR, slots + 3 * 4096, LD, LPF, 0
  CASE 18, MPRV | P_U, 0, slots + 5 * 4096, ST, SPF, 0
  CASE 19, MPRV | P_U, 0, slots + 9 * 4096, LD, LPF, 0

  # MPRV=1, MPV=0, MPP=S: HS-level access with satp only.
  CASE 21, MPRV | P_S, 0, slots + 0 * 4096, LD, 0, PAT_D
  CASE 22, MPRV | P_S, 0, slots + 0 * 4096, ST, 0, page_d
  CASE 23, MPRV | P_S, 0, slots + 1 * 4096, LD, LPF, 0
  CASE 24, MPRV | P_S, 0, slots + 1 * 4096, ST, SPF, 0
  CASE 25, MPRV | P_S | SUM, 0, slots + 1 * 4096, LD, 0, PAT_D
  CASE 26, MPRV | P_S | SUM, 0, slots + 1 * 4096, ST, 0, page_d
  CASE 27, MPRV | P_S, SUM, slots + 1 * 4096, LD, LPF, 0
  CASE 28, MPRV | P_S, 0, slots + 2 * 4096, LD, LPF, 0
  CASE 29, MPRV | P_S | MXR, 0, slots + 2 * 4096, LD, 0, PAT_D
  CASE 30, MPRV | P_S, MXR, slots + 2 * 4096, LD, LPF, 0
  CASE 31, MPRV | P_S, 0, slots + 4 * 4096, ST, SPF, 0
  CASE 32, MPRV | P_S, 0, slots + 4 * 4096, LD, 0, PAT_D
  CASE 33, MPRV | P_S, 0, slots + 8 * 4096, LD, LPF, 0

  # MPRV=1, MPP=M: M-level access with no translation, for MPV=0 and MPV=1.
  CASE 35, MPRV | P_M, 0, scratch, LD, 0, PAT_G
  CASE 36, MPRV | P_M | MPV, 0, scratch, LD, 0, PAT_G
  CASE 37, MPRV | P_M | MPV, 0, scratch, ST, 0, scratch
  CASE 38, MPRV | P_M | MPV | SUM | MXR, 0, slots, LD, 0, PAT_M

  # MPRV=1, MPV=1, MPP=U: VU-level access with two-stage translation.
  CASE 40, MPRV | MPV | P_U, 0, slots + 9 * 4096, LD, 0, PAT_D
  CASE 41, MPRV | MPV | P_U, 0, slots + 9 * 4096, ST, 0, page_d
  CASE 42, MPRV | MPV | P_U, 0, slots + 8 * 4096, LD, LPF, 0
  CASE 43, MPRV | MPV | P_U, 0, slots + 8 * 4096, ST, SPF, 0
  CASE 44, MPRV | MPV | P_U, SUM, slots + 8 * 4096, LD, LPF, 0
  CASE 45, MPRV | MPV | P_U, 0, slots + 11 * 4096, LD, LPF, 0
  CASE 46, MPRV | MPV | P_U | MXR, 0, slots + 11 * 4096, LD, 0, PAT_D
  CASE 47, MPRV | MPV | P_U, MXR, slots + 11 * 4096, LD, 0, PAT_D
  CASE 48, MPRV | MPV | P_U, 0, slots + 15 * 4096, LD, LGPF, 0
  CASE 49, MPRV | MPV | P_U, MXR, slots + 15 * 4096, LD, LGPF, 0
  CASE 50, MPRV | MPV | P_U | MXR, 0, slots + 15 * 4096, LD, 0, PAT_D
  CASE 51, MPRV | MPV | P_U, MXR, slots + 17 * 4096, LD, LGPF, 0
  CASE 52, MPRV | MPV | P_U | MXR, 0, slots + 17 * 4096, LD, 0, PAT_D
  CASE 53, MPRV | MPV | P_U, 0, slots + 17 * 4096, LD, LPF, 0
  CASE 54, MPRV | MPV | P_U, 0, slots + 19 * 4096, LD, LGPF, 0
  CASE 55, MPRV | MPV | P_U, 0, slots + 21 * 4096, LD, LGPF, 0
  CASE 56, MPRV | MPV | P_U, 0, slots + 23 * 4096, ST, SGPF, 0
  CASE 57, MPRV | MPV | P_U, 0, slots + 23 * 4096, LD, 0, PAT_D
  CASE 58, MPRV | MPV | P_U, 0, slots + 13 * 4096, ST, SPF, 0
  CASE 59, MPRV | MPV | P_U, 0, slots + 1 * 4096, LD, LPF, 0

  # MPRV=1, MPV=1, MPP=S: VS-level access with two-stage translation.
  CASE 60, MPRV | MPV | P_S, 0, slots + 8 * 4096, LD, 0, PAT_D
  CASE 61, MPRV | MPV | P_S, 0, slots + 8 * 4096, ST, 0, page_d
  CASE 62, MPRV | MPV | P_S, 0, slots + 9 * 4096, LD, LPF, 0
  CASE 63, MPRV | MPV | P_S, 0, slots + 9 * 4096, ST, SPF, 0
  CASE 64, MPRV | MPV | P_S | SUM, 0, slots + 9 * 4096, LD, LPF, 0
  CASE 65, MPRV | MPV | P_S, SUM, slots + 9 * 4096, LD, 0, PAT_D
  CASE 66, MPRV | MPV | P_S, SUM, slots + 9 * 4096, ST, 0, page_d
  CASE 67, MPRV | MPV | P_S, 0, slots + 10 * 4096, LD, LPF, 0
  CASE 68, MPRV | MPV | P_S | MXR, 0, slots + 10 * 4096, LD, 0, PAT_D
  CASE 69, MPRV | MPV | P_S, MXR, slots + 10 * 4096, LD, 0, PAT_D
  CASE 70, MPRV | MPV | P_S, 0, slots + 14 * 4096, LD, LGPF, 0
  CASE 71, MPRV | MPV | P_S, MXR, slots + 14 * 4096, LD, LGPF, 0
  CASE 72, MPRV | MPV | P_S | MXR, 0, slots + 14 * 4096, LD, 0, PAT_D
  CASE 73, MPRV | MPV | P_S, MXR, slots + 16 * 4096, LD, LGPF, 0
  CASE 74, MPRV | MPV | P_S | MXR, 0, slots + 16 * 4096, LD, 0, PAT_D
  CASE 75, MPRV | MPV | P_S, 0, slots + 16 * 4096, LD, LPF, 0
  CASE 76, MPRV | MPV | P_S, 0, slots + 18 * 4096, LD, LGPF, 0
  CASE 77, MPRV | MPV | P_S, 0, slots + 20 * 4096, LD, LGPF, 0
  CASE 78, MPRV | MPV | P_S, 0, slots + 22 * 4096, ST, SGPF, 0
  CASE 79, MPRV | MPV | P_S, 0, slots + 22 * 4096, LD, 0, PAT_D
  CASE 80, MPRV | MPV | P_S, 0, slots + 12 * 4096, ST, SPF, 0
  CASE 81, MPRV | MPV | P_S, 0, slots + 0 * 4096, LD, LPF, 0

  # MPRV does not change HLV: hstatus.SPVP gives the privilege.
  li t0, HSTATUS_SPVP
  csrs hstatus, t0
  CASE 85, MPRV | P_U, 0, slots + 8 * 4096, HLV, 0, PAT_D
  li t0, HSTATUS_SPVP
  csrc hstatus, t0
  CASE 86, MPRV | MPV | P_M, 0, slots + 9 * 4096, HLV, 0, PAT_D
  CASE 87, MPRV | MPV | P_S, 0, slots + 8 * 4096, HLV, LPF, 0

  # Each stage uses its own MODE. slots and gslots are in one 2 MiB, so the
  # G-stage maps slot k to itself.
  # satp Bare: the VS stage still uses vsatp.
  csrw satp, zero
  sfence.vma
  hfence.vvma
  hfence.gvma
  CASE 90, MPRV | MPV | P_S, 0, slots + 8 * 4096, LD, 0, PAT_D
  CASE 91, MPRV | MPV | P_U, 0, slots + 9 * 4096, LD, 0, PAT_D
  CASE 92, MPRV | P_S, 0, slots + 0 * 4096, LD, 0, PAT_M

  # vsatp Bare: MPV=1 gives the G-stage only, MPV=0 still uses satp.
  la t0, hs_root
  srli t0, t0, 12
  li t1, ATP_SV39
  or t0, t0, t1
  csrw satp, t0
  csrw vsatp, zero
  sfence.vma
  hfence.vvma
  hfence.gvma
  CASE 93, MPRV | MPV | P_S, 0, slots + 0 * 4096, LD, 0, PAT_M
  CASE 94, MPRV | MPV | P_S, 0, scratch, LD, LGPF, 0
  CASE 95, MPRV | P_S, 0, slots + 0 * 4096, LD, 0, PAT_D

  # hgatp Bare: MPV=1 gives the VS stage only.
  la t0, vs_root
  srli t0, t0, 12
  li t1, ATP_SV39
  or t0, t0, t1
  csrw vsatp, t0
  csrw hgatp, zero
  sfence.vma
  hfence.vvma
  hfence.gvma
  CASE 96, MPRV | MPV | P_S, 0, slots + 8 * 4096, LD, 0, PAT_G
  CASE 97, MPRV | MPV | P_S, 0, slots + 14 * 4096, LD, 0, PAT_G
  CASE 98, MPRV | MPV | P_U, 0, slots + 19 * 4096, ST, 0, gslots + 19 * 4096

  csrw satp, zero
  csrw vsatp, zero
  csrw hgatp, zero
  sfence.vma
  hfence.vvma
  hfence.gvma
  li a0, 0
#ifdef CONTINUE
  mv a0, s5
#endif
fail:
  li t0, MSTATUS_MPRV
  csrc mstatus, t0
  csrw mtvec, s7
  tail exit

# Trap vector for the checks. It clears MPRV before it does a memory access,
# keeps mcause in s10 and mtval in s11, and skips the access.
  .align 2
mprv_trap:
  csrc mstatus, s9
  csrr s10, mcause
  csrr s11, mtval
  csrr s8, mepc
  addi s8, s8, 4
  csrw mepc, s8
  mret

#ifdef CONTINUE
record_fail:
  mv s4, a0
  addi s5, s5, 1
  ret
#endif

# Write a pointer PTE to *a0 for the table at a1.
write_ptr:
  srli a1, a1, 12
  slli a1, a1, 10
  ori a1, a1, 1
  sd a1, 0(a0)
  ret

# a0 root, a1 l1, a2 l0: link the tables for the VA of slots.
link_tables:
  mv t6, ra
  la t0, slots
  srli t1, t0, 30
  andi t1, t1, 511
  slli t1, t1, 3
  add a0, a0, t1
  mv a3, a1
  jal write_ptr
  la t0, slots
  srli t1, t0, 21
  andi t1, t1, 511
  slli t1, t1, 3
  add a0, a3, t1
  mv a1, a2
  jal write_ptr
  mv ra, t6
  ret

# a0 l0 table, a1 VA, a2 PA, a3 flags: write the leaf PTE.
map_leaf:
  srli a1, a1, 12
  andi a1, a1, 511
  slli a1, a1, 3
  add a0, a0, a1
  srli a2, a2, 12
  slli a2, a2, 10
  or a2, a2, a3
  sd a2, 0(a0)
  ret

  .section .data
  # The two areas are 256 KiB and 256 KiB aligned, so they are in one 2 MiB.
  .balign 262144
slots:
  .zero 32 * 4096
gslots:
  .zero 30 * 4096
scratch:
  .zero 4096
page_d:
  .zero 4096

  .section .page_table, "aw", @progbits
  # The Sv39x4 root is 16 KiB and 16 KiB aligned.
  .balign 16384
g_root:
  .zero 16384
g_l1:
  .zero 4096
g_l0:
  .zero 4096
hs_root:
  .zero 4096
hs_l1:
  .zero 4096
hs_l0:
  .zero 4096
vs_root:
  .zero 4096
vs_l1:
  .zero 4096
vs_l0:
  .zero 4096
