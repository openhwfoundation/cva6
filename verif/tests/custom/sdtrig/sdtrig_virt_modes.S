# ------------------------------------------------------------------------------
#   Copyright 2026 Thales France
#
#   Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
#   You may obtain a copy of the License at https://solderpad.org/licenses/
# ------------------------------------------------------------------------------
#   sdtrig_virt_modes.S
#
#   mcontrol6 vs and vu bits: with the hypervisor extension, s and u enable a
#   trigger in HS-mode and U-mode, vs and vu in VS-mode and VU-mode.
#
#   An execute address trigger on target_insn is armed with one of the s, u,
#   vs, vu bits, then target_insn runs in one of HS, U, VS, VU (entered with
#   mret, MPP and MPV). The breakpoint must be taken exactly when the bit
#   matches the mode. The ecall that ends the run checks the mode it came from:
#   its cause and mstatus.MPV. Address translation is off (satp, vsatp and
#   hgatp are 0) and no trap is delegated: every trap reaches the M-mode
#   handler.
#
#   The first check reads tdata1 back: vs and vu are writable with RVH.
#
#   The 16 combinations run in order; TESTNUM is the combination number + 2
#   and a failure writes it to tohost.
#
#   Requires RVH, Sdtrig and SdtrigMcontrol6ExecAddr, on RV64.
# ------------------------------------------------------------------------------

#include "riscv_test.h"
#include "test_macros.h"

#define MSTATUS_MPV_BIT 39

// mcontrol6 on RV64: type 6 in [63:60], execute in [2]
#define MC6_TYPE   (6 << 60)
#define MC6_EXEC   (1 << 2)
#define MC6_U      (1 << 3)
#define MC6_S      (1 << 4)
#define MC6_VU     (1 << 23)
#define MC6_VS     (1 << 24)

// modes: MPP value and MPV
#define MODE_HS 0
#define MODE_U  1
#define MODE_VS 2
#define MODE_VU 3

RVTEST_RV64M
RVTEST_CODE_BEGIN

  .align 2
  .option norvc

  la t0, mtvec_handler
  csrw mtvec, t0
  csrw medeleg, zero
  csrw 0x602, zero                  # hedeleg
  csrw satp, zero
  csrw 0x280, zero                  # vsatp
  csrw 0x680, zero                  # hgatp
  li t0, -1                         # PMP: all memory accessible below M
  csrw pmpaddr0, t0
  li t0, 0x1f
  csrw pmpcfg0, t0

  # ----------------------------------------------------------------------
  # vs and vu read back
  # ----------------------------------------------------------------------
  li TESTNUM, 1
  csrw 0x7a0, zero                  # tselect = 0
  li t0, MC6_TYPE | MC6_VS | MC6_VU
  csrw 0x7a1, t0
  csrr t1, 0x7a1
  li t2, MC6_VS | MC6_VU
  and t1, t1, t2
  bne t1, t2, fail

  la t0, target_insn
  csrw 0x7a2, t0                    # tdata2 = address of target_insn

  # ----------------------------------------------------------------------
  # 16 combinations: bit in {s, u, vs, vu} x mode in {HS, U, VS, VU}
  # s4 = bit index, s5 = mode, s6 = 1 if a break is expected
  # ----------------------------------------------------------------------
  li s4, 0
bit_loop:
  li s5, 0
mode_loop:
  slli t0, s4, 2
  add  TESTNUM, t0, s5
  addi TESTNUM, TESTNUM, 2
  # break expected when the bit index equals the mode: s<->HS, u<->U,
  # vs<->VS, vu<->VU
  li s6, 0
  bne s4, s5, 1f
  li s6, 1
1:
  # arm the trigger with the selected mode bit
  la t0, mode_bits
  slli t1, s4, 3
  add t0, t0, t1
  ld t1, 0(t0)
  li t0, MC6_TYPE | MC6_EXEC
  or t0, t0, t1
  csrw 0x7a1, t0

  li s7, 0                          # breaks seen
  jal ra, enter_mode
after_target:
  bne s7, s6, fail

  addi s5, s5, 1
  li t0, 4
  blt s5, t0, mode_loop
  addi s4, s4, 1
  blt s4, t0, bit_loop

  csrw 0x7a1, zero
  j pass

  # ----------------------------------------------------------------------
  # mret into mode s5 at target_insn
  # ----------------------------------------------------------------------
enter_mode:
  la t0, target_insn
  csrw mepc, t0
  li t0, (3 << 11)
  csrc mstatus, t0
  li t0, 1
  slli t0, t0, MSTATUS_MPV_BIT
  csrc mstatus, t0
  # MPP = S for HS and VS, U for U and VU
  andi t1, s5, 1
  bnez t1, 2f
  li t0, (1 << 11)
  csrs mstatus, t0
2:
  # MPV = 1 for VS and VU
  li t1, 2
  blt s5, t1, 3f
  li t0, 1
  slli t0, t0, MSTATUS_MPV_BIT
  csrs mstatus, t0
3:
  mret

  # runs in the mode under test, then comes back with ecall
  .align 3
target_insn:
  nop
  ecall
  j fail

  TEST_PASSFAIL

  # ----------------------------------------------------------------------
  # breakpoint on target_insn: count it, disarm, resume at target_insn.
  # ecall from the mode under test: back to M-mode at after_target.
  # ----------------------------------------------------------------------
  .align 8
  .global mtvec_handler
mtvec_handler:
  csrr t0, mcause
  li t1, CAUSE_BREAKPOINT
  bne t0, t1, not_break
  csrr t0, mepc
  la t1, target_insn
  bne t0, t1, fail
  addi s7, s7, 1
  csrr t0, 0x7a1                    # disarm: clear execute
  li t1, MC6_EXEC
  not t1, t1
  and t0, t0, t1
  csrw 0x7a1, t0
  mret
not_break:
  # the ecall cause and MPV of mode s5
  la t1, ecall_causes
  slli t2, s5, 3
  add t1, t1, t2
  ld t1, 0(t1)
  bne t0, t1, fail
  csrr t0, mstatus
  srli t0, t0, MSTATUS_MPV_BIT
  andi t0, t0, 1
  srli t1, s5, 1
  bne t0, t1, fail
  li t0, (3 << 11)                  # back to M-mode, V=0
  csrs mstatus, t0
  li t0, 1
  slli t0, t0, MSTATUS_MPV_BIT
  csrc mstatus, t0
  la t0, after_target
  csrw mepc, t0
  mret

RVTEST_CODE_END

  .data
RVTEST_DATA_BEGIN
  TEST_DATA
  .align 3
mode_bits:
  .dword MC6_S
  .dword MC6_U
  .dword MC6_VS
  .dword MC6_VU
ecall_causes:
  .dword CAUSE_SUPERVISOR_ECALL     # HS
  .dword CAUSE_USER_ECALL           # U
  .dword 10                        # VS (virtual supervisor ecall)
  .dword CAUSE_USER_ECALL           # VU
RVTEST_DATA_END
