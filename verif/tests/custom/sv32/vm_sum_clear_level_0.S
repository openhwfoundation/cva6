#=======================================================================
#  RWX Access of Level0 PTE in Supervisor mode when mstatus.SUM unset
#-----------------------------------------------------------------------
# Test Description:
#
# If PTE belongs to user mode i.e. its U permission bit is set 
# (pte.u = 1) and m/sstatus.SUM = 0, then accessing that PTE in 
# supervisor mode would raise page fault exception of the 
# corresponding access type. 
#
# - Set pte.u=1 & s/mstatus.SUM = 0 and test the read access.
# - Set pte.u=1 & s/mstatus.SUM = 0 and test the write access.
# - Set pte.u=1 & s/mstatus.SUM = 0 and test the execute access.
#
#=======================================================================

#include "macros.h"
#define _MMODE_ "M"
#define _SUMODE_ "SU"

.text
.global _start
.option norvc

_start:
    ALL_MEM_PMP                                                         # PMP permission to all the mem
    la t1,trap_handler                                                  # loads the address of trap handler 
    csrw mtvec,t1                                                       # sets the mtvec to trap handler
    
PTE_LEVEL0:

# ----------------LEVEL 0 PTE Setup for load and store test------------

    la a1,pgtb_l0                                                       # loads the address of label pgtb_l0
    la a0, _start                                                       # VA = PA - Identity Map
    ori a2, x0, ( PTE_V )                                               # sets the permission bits
    PTE_SETUP_RV32(a1, a2, t1, a0, pgtb_l1, LEVEL1)                     # setup the PTE for level1    

    la a1,vm_en                                                         # loads the address of label vm_en
    mv a0, a1                                                           # VA = PA - Identity Map
    ori a2, x0, ( PTE_D | PTE_A | PTE_X | PTE_V )                       # sets the permission bits
    PTE_SETUP_RV32(a1, a2, t1, a0, pgtb_l0, LEVEL0)                     # setup the PTE for level0
 
    la a1,rvtest_data                                                   # loads the address of label rvtest_data
    mv a0, a1                                                           # VA = PA - Identity Map
    # sets the permission bits
    ori a2, x0, ( PTE_D | PTE_A | PTE_U | PTE_W | PTE_R | PTE_V )
    PTE_SETUP_RV32(a1, a2, t1, a0, pgtb_l0, LEVEL0)                     # setup the PTE for level0   

    la a1,rvtest_check                                                  # loads the address of label rvtest_data
    mv a0, a1                                                           # VA = PA - Identity Map                                         
    ori a2, x0, ( PTE_D | PTE_A | PTE_W | PTE_R | PTE_V)                # sets the permission bits
    PTE_SETUP_RV32(a1, a2, t1, a0, pgtb_l0, LEVEL0)                     # setup the PTE for level0

# ----------------Set the SATP and change the mode---------------------


    SATP_SETUP_SV32(pgtb_l1)                                            # set the SATP for virtualization
    li a1, MSTATUS_SUM
    csrc mstatus, a1                                                    # Clear mstatus.SUM
    la a1,vm_en                                                         # loads the address of vm_en
    CHANGE_T0_S_MODE(a1)                                                # changes mode M to S and set the MEPC value to a1

# ----------------Virtualization Enabeled---------------------

vm_en:

# -------------------Load Test Prolog-------------------------

    TEST_PROLOG(check_load, CAUSE_LOAD_PAGE_FAULT)                      # load the addr and expected cause

check_load:                                                             # test the load access

    lw t1,0(a1)  
    TEST_STATUS                                                         # checks the status of the test
    nop

# -------------------Store Test Prolog------------------------

    TEST_PROLOG(check_store, CAUSE_STORE_PAGE_FAULT)                    # load the addr and expected cause

check_store:                                                            # test the store access
    sw t1,0(a1)
    nop          
    TEST_STATUS                                                         # checks the status of the test           
    #ifdef smode
        SMODE_ECALL                                                     # SMODE ecall 
    #else
        UMODE_ECALL                                                     # UMODE ecall 
    #endif

# -------------------Execute Test Prolog-----------------------

    TEST_PROLOG(check_execute, CAUSE_FETCH_PAGE_FAULT)                  # load the addr and expected cause
  

PTE_LEVEL0_EXECUTE:

# -------------LEVEL 1 PTE Setup for execute test------------------------
                                                                        # Setup a new PTE to test execute 
    la a1,check_execute                                                 # loads the address of label vm_en
    mv a0, a1                                                           # VA = PA - Identity Map
    # sets the permission bits
    ori a2, x0, ( PTE_D | PTE_A | PTE_U | PTE_X | PTE_V )
    PTE_SETUP_RV32(a1, a2, t1, a0, pgtb_l0, LEVEL0)                     # setup the PTE for level0

# ----------------Set the SATP and change the mode---------------------

    SATP_SETUP_SV32(pgtb_l1)                                            # set the SATP for virtualization
    la a1,check_execute                                                 # loads the address of check_execute
    CHANGE_T0_S_MODE(a1)                                                # changes mode M to S and set the MEPC 

check_execute:                                                          # test the execute access
    li t1, 0x45                                                         # page fault should raise
    TEST_STATUS                                                         # checks the status of the test   
    j test_pass

trap_handler:
    csrr t0, mcause                                                     # read the value of mcause
    la t1, rvtest_check                                                 # load the address of trvtest_check

    lw t2, 0(t1)                                                        # if cause expected then load 1 else 0
    lw t3, 4(t1)                                                        # load the expected value of mepc
    lw t4, 8(t1)                                                        # load the expected value of mcause

    li  t1, CAUSE_SUPERVISOR_ECALL                                      # load the value of supervisor ecall
    beq t0,t1,continue_in_m_mode                                        # checks if ecall is occurred

    li  t1, CAUSE_USER_ECALL                                            # load the value of user ecall
    beq t0,t1,continue_in_m_mode                                        # checks for ecall is occurred

    beqz t2, test_fail                                                  # Jumps to exit if cause is not expected
    csrr t5,mepc                                                        # read the value of mepc

    bne t3,t5, test_fail                                                # check the value of mepc with it's expected value
    bne t0, t4, test_fail                                               # jumps to exit if EXPECTED_CAUSE is'nt equal to mcause

    li t5, CAUSE_FETCH_PAGE_FAULT                                       # load the value of fetch page fault exception
    beq t0,t5,continue_in_m_mode                                        # if fetch page fault jump to next instr in M mode

continue_execution:

    INCREMENT_MEPC   _SUMODE_                                           # update the value of mepc
    j trap_epilogs

continue_in_m_mode:

    INCREMENT_MEPC   _MMODE_                                            # update the value of mepc
    li t1,MSTATUS_MPP                                                   # update the MPP to MSTATUS_MPP for M mode
    csrs mstatus,t1                                                     # update the value mstatus MPP

trap_epilogs:
    la t1, rvtest_check                                                 # load the addr of rvtest_check
    li t2, 0
    sw t2, 0(t1)                                                        # Clear the expected cause
    sw t2, 4(t1)                                                        # Clear the exception PC
    sw t2, 8(t1)                                                        # Clear cause execution number
    mret

test_pass:
    li x1, 0                                                            # Write 0 in x1 if test pass
    j exit                                                              # Jump to exit

test_fail:
    li x1, 1                                                            # Write 1 in x1 if test failed

COREV_VERIF_EXIT_LOGIC                                                  # Exit logic 

.data
rvtest_check: 

    .word 0xdeadbeef                                                    # 1 for cause expected 0  for no cause 
    .word 0xbeefdead                                                    # write the value of mepc here (where  cause is expected)
    .word 0xcafecafe                                                    # write the value of expect cause 
.align 12                                   
rvtest_data:   
    .word 0xbeefcafe                                                 
    .word 0xdeadcafe                                                 
    .word 0xcafecafe                                                 
    .word 0xbeefdead  
.align 12                                                      
    pgtb_l1:                                                       
        .zero 4096                                                 
    pgtb_l0:                                                       
        .zero 4096                                                                                                     

.align 4; .global tohost;   tohost:   .dword 0;
.align 4; .global fromhost; fromhost: .dword 0;