# Copyright 2026 qinkejiu
#
# Licensed under the Solderpad Hardware Licence, Version 2.0
# (the "License"); you may not use this file except in compliance with the
# License. You may obtain a copy of the License at
# https://solderpad.org/licenses/
#
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
#
# Regression test for CVA6 issue #3597:
# "PMP check replaces an instruction guest-page fault with an instruction
#  access fault"
#
# With vsatp.MODE=Bare and hgatp.MODE=Sv39x4, a VS-mode instruction fetch to a
# guest physical address with no G-stage mapping must raise an instruction
# guest-page fault (mcause 20). The privileged spec gives that trap priority
# over an access fault associated with the final physical access: a failed
# G-stage translation has not produced a valid physical address at all.
#
# core/pmp/src/pmp_data_if.sv forwards the walk-failure address to the PMP
# anyway and, before the fix, replaced any exception other than
# INSTR_PAGE_FAULT with INSTR_ACCESS_FAULT. So the reported cause depended on
# whether PMP happened to allow the address the MMU forwarded:
#
#   phase A: PMP entry 0 only (0x8000_0000 + 4 MiB)  -> denied -> mcause 1
#   phase B: PMP entry 1 additionally maps 0x0..0xFFF -> allowed -> mcause 20
#
# Note on the phase B address window: on an ITLB miss the TLB lookup output is
# zero, so the MMU forwards {0, vaddr[11:0]} = 0x0 for the faulting fetch. The
# 0x0..0xFFF window is exactly the one the issue uses to make the fetch survive
# the PMP check.
#
# phase C is the opposite control: the G-stage translation succeeds and the PMP
# then denies the final physical address, which must still report mcause=1, so a
# future change cannot "fix" this issue by disabling the instruction PMP/PMA
# check altogether.
#
# 0x8040_0000 is chosen so that the only remaining reason to fault is PMP:
#   - it is inside the PMA execute region of this configuration
#     (0x8000_0000 + 0x4000_0000 in cv64a6_imafdch_sv39_config_pkg.sv), so the
#     PMA check alone would let the fetch through;
#   - it is just outside PMP entry 0 (0x8000_0000 + 4 MiB), so PMP is the one
#     that denies it;
#   - it is already covered by the 1 GiB identity leaf in root[2], so the
#     G-stage translation itself succeeds and needs no extra mapping.

  .option norvc
  .section .text
  .align 2

  .equ MSTATUS_MPP_MASK, 0x0000000000001800
  .equ MSTATUS_MPP_S,    0x0000000000000800
  .equ MSTATUS_MPV,      0x0000008000000000

  .equ HGATP_MODE_SV39X4,      8
  # 1 GiB leaf, PPN 0x80000 -> PA 0x8000_0000, flags V R W X U A D
  .equ PTE_G_1GIB_IDENTITY,    0x00000000200000DF

  .equ PMP_RWX_NAPOT, 0x1F
  .equ PMPADDR_DRAM,  0x2007FFFF   # NAPOT 0x8000_0000, 4 MiB
  .equ PMPADDR_LOW,   0x000001FF   # NAPOT 0x0000_0000, 4 KiB
  .equ PMP_CFG_TWO_ENTRIES, 0x1F1F  # entry 0 and entry 1, both R/W/X NAPOT

  .equ FAULT_VA,   0xC0000000   # no G-stage mapping in root[3]
  .equ DENIED_VA,  0x80400000   # PMA-executable, G-stage mapped, PMP-denied

  .equ CAUSE_INSTR_ACCESS_FAULT,     1
  .equ CAUSE_INSTR_GUEST_PAGE_FAULT, 20

  .globl main
main:
  # Route every trap to M-mode.
  la      t0, trap_handler
  csrw    mtvec, t0
  csrw    medeleg, zero
  csrw    hedeleg, zero

  # Pure G-stage translation: vsatp is left Bare, only hgatp is enabled.
  csrw    vsatp, zero

  # Sv39x4 root table: index 2 is a 1 GiB identity leaf covering the program,
  # index 3 (0xC000_0000) stays invalid so the guest fetch cannot translate.
  la      s0, g_root
  li      t0, PTE_G_1GIB_IDENTITY
  sd      t0, 16(s0)                 # root[2]
  sd      zero, 24(s0)               # root[3] -- must be invalid

  la      t0, g_root
  srli    t0, t0, 12
  li      t1, HGATP_MODE_SV39X4
  slli    t1, t1, 60
  or      t0, t0, t1
  csrw    hgatp, t0
  hfence.gvma

  # PMP entry 0 permits the program, the G-stage table and the stack.
  # Entry 1 stays disabled for phase A.
  li      t0, PMPADDR_DRAM
  csrw    pmpaddr0, t0
  li      t0, PMP_RWX_NAPOT
  csrw    pmpcfg0, t0

  # ---- phase A: the address the MMU forwards for the faulting fetch is not
  # permitted, so the PMP check must not turn cause 20 into cause 1.
  li      s4, 1
  li      s5, FAULT_VA
  j       enter_guest

phase_b:
  # An extra 4 KiB window at 0x0 makes the PMP allow what the MMU forwarded,
  # which is the control run of the issue report.
  li      t0, PMPADDR_LOW
  csrw    pmpaddr1, t0
  li      t0, PMP_CFG_TWO_ENTRIES
  csrw    pmpcfg0, t0
  li      s4, 2
  li      s5, FAULT_VA
  j       enter_guest

phase_c:
  # Back to entry 0 only, so the fetch of DENIED_VA translates and passes the
  # PMA execute-region check but is denied by PMP.
  li      t0, PMP_RWX_NAPOT
  csrw    pmpcfg0, t0
  li      s4, 3
  li      s5, DENIED_VA

# Enter VS-mode at the address in s5; the fetch itself is expected to fault.
enter_guest:
  csrw    mepc, s5
  csrr    t0, mstatus
  li      t1, MSTATUS_MPP_MASK
  not     t1, t1
  and     t0, t0, t1
  li      t1, MSTATUS_MPP_S
  or      t0, t0, t1
  li      t1, MSTATUS_MPV
  or      t0, t0, t1
  csrw    mstatus, t0
  # PMP and the G-stage page table were just modified: synchronise the cached
  # translations before the guest fetch, as software is required to do.
  hfence.gvma
  mret

  .align 2
trap_handler:
  csrr    t0, mcause
  csrr    t1, mepc

  li      t2, 3
  beq     s4, t2, check_access_fault

  # Phases A and B: failed G-stage translation, mcause must stay 20.
  li      t2, CAUSE_INSTR_GUEST_PAGE_FAULT
  bne     t0, t2, fail_cause
  li      t2, FAULT_VA
  bne     t1, t2, fail_mepc
  li      t2, 1
  beq     s4, t2, phase_a_done
  j       phase_c

phase_a_done:
  j       phase_b

check_access_fault:
  # Phase C: translation succeeded, PMP denied the final physical address.
  li      t2, CAUSE_INSTR_ACCESS_FAULT
  bne     t0, t2, fail_cause
  li      t2, DENIED_VA
  bne     t1, t2, fail_mepc
  j       pass

pass:
  li      a0, 0
  j       exit

fail_cause:
  # Exit code = (phase << 6) | mcause, so the phase and the observed cause can
  # be read back without the two fields overlapping.
  csrr    a0, mcause
  slli    t1, s4, 6
  or      a0, a0, t1
  j       exit

fail_mepc:
  # Exit code = 0x100 | phase, outside the fail_cause range.
  li      a0, 0x100
  or      a0, a0, s4
  j       exit

  # G-stage root table, 16 KiB aligned (SV39x4).
  .section .page_table,"aw",@progbits
  .align 14
g_root:
  .zero 16384
