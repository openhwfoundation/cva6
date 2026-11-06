# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
#=======================================================================
#  PMP Access Fault on the Level 1 PTE Read of a Page Table Walk
#-----------------------------------------------------------------------
# Test Description:
#
# When the implicit read of a PTE fails its PMP check, the access fault
# must correspond to the original access type: a load raises a load
# access fault and a store raises a store/AMO access fault.
#
# The level 1 PTE that maps VA_TGT sits in a PMP region with no
# permissions, so the page table walk for VA_TGT faults before any data
# access. The test checks both causes in supervisor and user modes.
#
#=======================================================================

#include "macros.h"

#define NAPOT_RANGE_32B 0x3                                             # Set 32B range with NAPOT
# VA whose level 1 PTE is PMP protected
#define VA_TGT          0x90000000

#define _MMODE_ "M"
#define _SUMODE_ "SU"

#ifdef smode
    #define SET_PTE_U 0
#else
    #define SET_PTE_U PTE_U
#endif

.text
.global _start
.option norvc

_start:

# -------------------------------- PMP Configurations --------------------------------

    # Region 0: the level 1 PTE of VA_TGT, NAPOT with no permission
    la t2, pgtb_l1
    li t5, (VA_TGT >> SUPERPAGE_SHIFT) << 2
    add t2, t2, t5
    srli t2, t2, PMP_SHIFT
    ori t2, t2, NAPOT_RANGE_32B
    csrw pmpaddr0, t2

    # Region 1: all of memory, NAPOT with RWX. Only the PTE read of the page
    # table walk faults, so the cause comes from the walk alone.
    li t2, -1
    csrw pmpaddr1, t2

    li t2, ((PMP_NAPOT | PMP_X | PMP_W | PMP_R) << 8) | (PMP_NAPOT)
    csrw pmpcfg0, t2
    sfence.vma

    la t1,trap_handler                                                  # loads the address of trap handler
    csrw mtvec,t1                                                       # sets the mtvec to trap handler

# ----------------LEVEL 1 PTE Setup---------------------

    la a1,vm_en                                                         # loads the address of label vm_en
    mv a0, a1                                                           # VA = PA - Identity Map
    ori a2, x0, ( PTE_D | PTE_A | SET_PTE_U | PTE_X | PTE_W | PTE_R | PTE_V )
    PTE_SETUP_RV32(a1, a2, t1, a0, pgtb_l1, LEVEL1)

    la a1,rvtest_check                                                  # loads the address of label rvtest_check
    mv a0, a1                                                           # VA = PA - Identity Map
    ori a2, x0, ( PTE_D | PTE_A | SET_PTE_U | PTE_X | PTE_W | PTE_R | PTE_V )
    PTE_SETUP_RV32(a1, a2, t1, a0, pgtb_l1, LEVEL1)

    la a1,rvtest_data                                                   # VA_TGT maps to rvtest_data
    li a0, VA_TGT
    ori a2, x0, ( PTE_D | PTE_A | SET_PTE_U | PTE_W | PTE_R | PTE_V )
    PTE_SETUP_RV32(a1, a2, t1, a0, pgtb_l1, LEVEL1)

# ----------------Set the SATP and change the mode---------------------

    SATP_SETUP_SV32(pgtb_l1)                                            # set the SATP for virtualization
    la a1,vm_en                                                         # loads the address of vm_en
    #ifdef smode
        CHANGE_T0_S_MODE(a1)                                            # changes mode M to S and set the MEPC value to a1
    #else
        CHANGE_T0_U_MODE(a1)                                            # changes mode M to U and set the MEPC value to a1
    #endif

# ----------------Virtualization Enabled---------------------

vm_en:

# ----------------Load: the PTE read faults, load access fault expected-----

    TEST_PROLOG(check_load, CAUSE_LOAD_ACCESS)                          # load the addr and expected cause
    li a1, VA_TGT

check_load:
    lw t1,0(a1)
    TEST_STATUS

# ----------------Store: the PTE read faults, store access fault expected---

    TEST_PROLOG(check_store, CAUSE_STORE_ACCESS)                        # load the addr and expected cause
    li a1, VA_TGT

check_store:
    sw t1,0(a1)
    TEST_STATUS

    #ifdef smode
        SMODE_ECALL                                                     # SMODE ecall
    #else
        UMODE_ECALL                                                     # UMODE ecall
    #endif

test_pass:

    li x1, 0                                                             # Write 0 in x1 if test pass
    j exit                                                               # Jump to exit

test_fail:

    li x1, 1                                                             # Write 1 in x1 if test failed
    j exit                                                               # Jump to exit

trap_handler:

    csrr t0, mcause                                                      # read the value of mcause
    la t1, rvtest_check                                                  # load the address of rvtest_check

    lw t2, 0(t1)                                                         # if cause expected then load 1 else 0
    lw t3, 4(t1)                                                         # load the expected value of mepc
    lw t4, 8(t1)                                                         # load the expected value of mcause

    li  t1, CAUSE_SUPERVISOR_ECALL                                       # load the value of supervisor ecall
    beq t0,t1,continue_in_m_mode                                         # checks if ecall is occured

    li  t1, CAUSE_USER_ECALL                                             # load the value of user ecall
    beq t0,t1,continue_in_m_mode                                         # checks for ecall is occured

    beqz t2, test_fail                                                   # Jumps to test_fail if cause is not expected

    csrr t5,mepc                                                         # read the value of mepc
    bne t3,t5,test_fail                                                  # check the value of mepc with it's expected value

    bne  t0, t4, test_fail                                               # jumps to test_fail if EXPECTED_CAUSE is'nt equal to mcause

continue_execution:

    INCREMENT_MEPC   _SUMODE_                                            # update the value of mepc
    j trap_epilogs

continue_in_m_mode:

    INCREMENT_MEPC   _MMODE_                                             # update the value of mepc
    li t1,MSTATUS_MPP                                                    # update the MPP to MSTATUS_MPP for M mode
    csrs mstatus,t1                                                      # update the value mstatus MPP

trap_epilogs:

    la t1, rvtest_check                                                   # load the addr of rvtest_check
    li t2, 0
    sw t2, 0(t1)                                                          # Clear the expected cause
    sw t2, 4(t1)                                                          # Clear the exception PC
    sw t2, 8(t1)                                                          # Clear cause execution number
    mret

COREV_VERIF_EXIT_LOGIC                                                    # Exit logic

.data
.align 24
    rvtest_check:

        .word 0xdeadbeef                                                  # 1 for cause expected 0  for no cause
        .word 0xbeefdead                                                  # write the value of mepc here (where  cause is expected)
        .word 0xcafecafe                                                  # write the value of expect cause
.align 22
    rvtest_data:
        .word 0xbeefcafe
        .word 0xdeadcafe
        .word 0x00000000
        .word 0x00000000
.align 12
    pgtb_l1:
        .zero 4096
    pgtb_l0:
        .zero 4096

.align 4; .global tohost;   tohost:   .dword 0;
.align 4; .global fromhost; fromhost: .dword 0;
