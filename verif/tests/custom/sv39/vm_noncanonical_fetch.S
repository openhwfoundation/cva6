#=======================================================================
#      Non-canonical virtual address, Sv39
#-----------------------------------------------------------------------
# With Sv39 translation, bits 63:39 of a virtual address must equal bit 38.
# An access to an address that does not satisfy this raises the page fault
# of the access type: INSTR_PAGE_FAULT (12) for a fetch, LOAD_PAGE_FAULT
# (13) for a load, STORE_PAGE_FAULT (15) for a store.
#
# The code runs in S-mode from a 1 GiB identity gigapage. It jumps to a
# non-canonical address, then loads from it and stores to it. The trap
# handler checks mcause and mepc of each trap and resumes at the next step.
# A failure writes 3 to tohost.
#=======================================================================

#include "encoding.h"

#define PTE_LEAF_RWX (PTE_D | PTE_A | PTE_X | PTE_W | PTE_R | PTE_V)

# bit 39 set, bit 38 clear: not canonical. Bits 38:0 fall in the mapped
# gigapage, so the page walk succeeds and only the canonical check faults.
#define NONCANON_VA 0x0000008080000000

.text
.global _start
.option norvc

_start:
    # all memory accessible from S-mode
    li   t2, -1
    csrw pmpaddr0, t2
    li   t2, 0x0F
    csrw pmpcfg0, t2
    la   t1, trap_handler
    csrw mtvec, t1

    # l2[2]: identity gigapage for 0x8000_0000 .. 0xBFFF_FFFF
    li   t0, 0x80000000
    srli t0, t0, 12
    slli t0, t0, 10
    ori  t0, t0, PTE_LEAF_RWX
    la   t1, pgtb_l2
    sd   t0, (2*8)(t1)

    # satp: Sv39, root pgtb_l2
    la   t0, pgtb_l2
    srli t0, t0, 12
    li   t1, 8
    slli t1, t1, 60
    or   t0, t0, t1
    csrw satp, t0
    sfence.vma

    # drop to S-mode at vm_en
    li   t0, MSTATUS_MPP
    csrc mstatus, t0
    li   t0, (MSTATUS_MPP & (MSTATUS_MPP >> 1))
    csrs mstatus, t0
    la   t0, vm_en
    csrw mepc, t0
    mret

vm_en:
    # 1. fetch from a non-canonical address
    li   s2, 1
    li   t1, NONCANON_VA
    la   s3, after_fetch
    jr   t1
after_fetch:
    # 2. load from a non-canonical address
    li   s2, 2
    li   t1, NONCANON_VA
fault_load:
    ld   t0, 0(t1)
    # 3. store to a non-canonical address
    li   s2, 3
    li   t1, NONCANON_VA
fault_store:
    sd   zero, 0(t1)
    # 4. done
    li   s2, 4
    ecall

    # s2 = step, s3 = resume address of step 1
trap_handler:
    csrr t0, mcause
    csrr t1, mepc
    li   t2, 1
    beq  s2, t2, check_fetch
    li   t2, 2
    beq  s2, t2, check_load
    li   t2, 3
    beq  s2, t2, check_store
    li   t2, 4
    beq  s2, t2, check_end
    j    trap_bad

check_fetch:
    li   t2, CAUSE_FETCH_PAGE_FAULT
    bne  t0, t2, trap_bad
    li   t2, NONCANON_VA
    bne  t1, t2, trap_bad
    csrw mepc, s3
    mret

check_load:
    li   t2, CAUSE_LOAD_PAGE_FAULT
    bne  t0, t2, trap_bad
    la   t2, fault_load
    bne  t1, t2, trap_bad
    addi t1, t1, 4
    csrw mepc, t1
    mret

check_store:
    li   t2, CAUSE_STORE_PAGE_FAULT
    bne  t0, t2, trap_bad
    la   t2, fault_store
    bne  t1, t2, trap_bad
    addi t1, t1, 4
    csrw mepc, t1
    mret

check_end:
    li   t2, CAUSE_SUPERVISOR_ECALL
    bne  t0, t2, trap_bad
    li   x1, 0
    j    exit

trap_bad:
    li   x1, 1
exit:
    slli x1, x1, 1
    addi x1, x1, 1
    la   t0, tohost
    sd   x1, 0(t0)
self_loop: j self_loop

.data
.align 12
pgtb_l2:        .zero 4096

.align 4; .global tohost;   tohost:   .dword 0;
.align 4; .global fromhost; fromhost: .dword 0;
