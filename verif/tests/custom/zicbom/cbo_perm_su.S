# ------------------------------------------------------------------------------
#   Copyright 2026 Thales France
#
#   Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
#   You may obtain a copy of the License at https://solderpad.org/licenses/
# ------------------------------------------------------------------------------
#   cbo_perm_su.S
#
#   Zicbom permissions outside virtualization, in M, S and U mode.
#
#   menvcfg.CBIE (bits 5:4) and menvcfg.CBCFE (bit 6) govern every mode below
#   M; senvcfg.CBIE and senvcfg.CBCFE additionally govern U-mode:
#     - CBIE = 00: cbo.inval raises an illegal instruction (cause 2).
#     - CBIE = 01: cbo.inval is executed as a flush.
#     - CBIE = 11: cbo.inval is executed as an invalidate.
#     - CBCFE = 0: cbo.clean and cbo.flush raise an illegal instruction.
#   An M-mode cbo is never checked. A cbo.inval that CBIE turns into a flush
#   is still governed by CBIE only, not by CBCFE.
#
#   Every case runs one cbo in the requested mode through run_cbo and checks
#   the cause recorded by the M-mode handler, 0 meaning no trap. The cases
#   are restricted to V=0.
#
#   The cbo instructions are encoded with .insn, so the test builds with
#   the march of the target, which does not list Zicbom.
#
#   Requires RVZiCbom, RVS and RVU. PMP entry 0 is opened over the whole
#   address space so that S and U can run the test image.
# ------------------------------------------------------------------------------

#define CSR_MENVCFG 0x30a
#define CSR_SENVCFG 0x10a

#define PRV_U 0
#define PRV_S 1
#define PRV_M 3

#define OP_INVAL 0
#define OP_CLEAN 1
#define OP_FLUSH 2

#define ILL 2

#define ENVCFG(cbie, cbcfe) (((cbie) << 4) | ((cbcfe) << 6))

#if __riscv_xlen == 64
#define SREG sd
#define LREG ld
#else
#define SREG sw
#define LREG lw
#endif

    .text
    .option norvc

    .globl main
main:
    addi sp, sp, -32
    SREG ra, 0(sp)
    SREG s0, 8(sp)              # s0, s1 are callee-saved: crt.S uses s0
    SREG s1, 16(sp)

    la   t0, trap_handler
    csrw mtvec, t0
    csrw medeleg, zero
    csrw mideleg, zero
    csrw satp, zero

    li   t0, -1
    csrw pmpaddr0, t0
    li   t0, 0x0f               # TOR, RWX
    csrw pmpcfg0, t0
    fence

    la   s1, cases
    li   s0, 0                  # case index, reported on failure

next_case:
    lw   t0, 0(s1)              # mode, -1 ends the table
    bltz t0, all_passed
    lw   t1, 4(s1)              # menvcfg
    csrw CSR_MENVCFG, t1
    lw   t1, 8(s1)              # senvcfg
    csrw CSR_SENVCFG, t1

    mv   a0, t0
    lw   a1, 12(s1)             # operation
    jal  run_cbo                # a0 = cause, 0 if none

    lw   t1, 16(s1)             # expected cause
    bne  a0, t1, case_failed

    addi s1, s1, 20
    addi s0, s0, 1
    j    next_case

all_passed:
    csrw CSR_MENVCFG, zero
    csrw CSR_SENVCFG, zero
    li   a0, 0
    j    done
case_failed:
    csrw CSR_MENVCFG, zero
    csrw CSR_SENVCFG, zero
    addi a0, s0, 1              # 1 + index of the failing case
done:
    LREG ra, 0(sp)
    LREG s0, 8(sp)
    LREG s1, 16(sp)
    addi sp, sp, 32
    ret

    # --------------------------------------------------------------------
    # run_cbo(a0 = mode, a1 = operation) -> a0 = cause, 0 if no trap
    #
    # Sets MPP to the requested mode and returns into cbo_body with mret.
    # cbo_body runs the cbo and does an ecall, which the handler turns back
    # into a return to M-mode at run_cbo_back. A cbo that traps is skipped
    # by the handler, whose recorded cause is kept.
    # --------------------------------------------------------------------
run_cbo:
    la   t0, cbo_cause
    sw   zero, 0(t0)
    la   t0, target_line
    mv   t2, a1                 # operation, used by cbo_body
    mv   t3, t0                 # address, used by cbo_body

    li   t1, PRV_M
    beq  a0, t1, cbo_body_m

    li   t1, 0x1800             # MPP mask
    csrc mstatus, t1
    slli t1, a0, 11
    csrs mstatus, t1
    la   t1, cbo_body
    csrw mepc, t1
    mret

cbo_body_m:
    # M-mode: run the body directly, the ecall returns here as well.
    j    cbo_body

run_cbo_back:
    la   t0, cbo_cause
    lw   a0, 0(t0)
    ret

    .align 3
cbo_body:
    li   t1, OP_CLEAN
    beq  t2, t1, do_clean
    li   t1, OP_FLUSH
    beq  t2, t1, do_flush
do_inval:
    .insn i 0x0f, 2, x0, 0(t3)        # cbo.inval (t3)
    j    body_end
do_clean:
    .insn i 0x0f, 2, x0, 1(t3)        # cbo.clean (t3)
    j    body_end
do_flush:
    .insn i 0x0f, 2, x0, 2(t3)        # cbo.flush (t3)
body_end:
    ecall

    # --------------------------------------------------------------------
    # M-mode handler. An ecall from any mode ends the case and returns to
    # run_cbo_back in M-mode. Any other trap is recorded in cbo_cause and
    # skipped. s10/s11 are scratch, main does not use them.
    # --------------------------------------------------------------------
    .align 6
trap_handler:
    csrr s10, mcause
    li   s11, 8                 # ecall from U
    beq  s10, s11, back_to_m
    li   s11, 9                 # ecall from S
    beq  s10, s11, back_to_m
    li   s11, 11                # ecall from M
    beq  s10, s11, back_to_m

    la   s11, cbo_cause
    sw   s10, 0(s11)
    csrr s10, mepc
    addi s10, s10, 4
    csrw mepc, s10
    mret

back_to_m:
    li   s10, 0x1800            # MPP = M
    csrs mstatus, s10
    la   s10, run_cbo_back
    csrw mepc, s10
    mret

    .data
    .align 2
cbo_cause:
    .word 0

    # mode, menvcfg, senvcfg, operation, expected cause
cases:
    # M-mode is never checked.
    .word PRV_M, ENVCFG(0,0), ENVCFG(0,0), OP_INVAL, 0
    .word PRV_M, ENVCFG(0,0), ENVCFG(0,0), OP_CLEAN, 0
    .word PRV_M, ENVCFG(0,0), ENVCFG(0,0), OP_FLUSH, 0
    # S-mode: menvcfg only.
    .word PRV_S, ENVCFG(0,0), ENVCFG(3,1), OP_INVAL, ILL
    .word PRV_S, ENVCFG(1,0), ENVCFG(0,0), OP_INVAL, 0     # flush, CBCFE ignored
    .word PRV_S, ENVCFG(3,0), ENVCFG(0,0), OP_INVAL, 0
    .word PRV_S, ENVCFG(3,0), ENVCFG(3,1), OP_CLEAN, ILL
    .word PRV_S, ENVCFG(3,0), ENVCFG(3,1), OP_FLUSH, ILL
    .word PRV_S, ENVCFG(0,1), ENVCFG(0,0), OP_CLEAN, 0
    .word PRV_S, ENVCFG(0,1), ENVCFG(0,0), OP_FLUSH, 0
    # U-mode: menvcfg and senvcfg.
    .word PRV_U, ENVCFG(0,1), ENVCFG(3,1), OP_INVAL, ILL   # menvcfg.CBIE=00
    .word PRV_U, ENVCFG(3,1), ENVCFG(0,1), OP_INVAL, ILL   # senvcfg.CBIE=00
    .word PRV_U, ENVCFG(3,0), ENVCFG(1,0), OP_INVAL, 0     # flush, CBCFE ignored
    .word PRV_U, ENVCFG(1,0), ENVCFG(3,0), OP_INVAL, 0
    .word PRV_U, ENVCFG(3,1), ENVCFG(3,1), OP_INVAL, 0
    .word PRV_U, ENVCFG(3,1), ENVCFG(3,0), OP_CLEAN, ILL   # senvcfg.CBCFE=0
    .word PRV_U, ENVCFG(3,0), ENVCFG(3,1), OP_CLEAN, ILL   # menvcfg.CBCFE=0
    .word PRV_U, ENVCFG(3,1), ENVCFG(3,0), OP_FLUSH, ILL
    .word PRV_U, ENVCFG(0,1), ENVCFG(0,1), OP_CLEAN, 0
    .word PRV_U, ENVCFG(0,1), ENVCFG(0,1), OP_FLUSH, 0
    .word -1

    .align 6
target_line:
    .space 64
