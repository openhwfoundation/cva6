# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
#=======================================================================
#      PMP access fault on the PTE read of a page table walk, Sv39
#-----------------------------------------------------------------------
# When the implicit read of a PTE fails its PMP check, the access fault
# must correspond to the original access type: LOAD_ACCESS (5) for a load,
# STORE_ACCESS (7) for a store.
#
# The code runs in S-mode from a 1 GiB identity gigapage. The root PTE that
# maps VA_TGT sits in a PMP region with no permission, and a second region
# gives RWX to the rest of memory, so only the page table walk faults. The
# trap handler checks mcause and mepc of each trap and resumes at the next
# step. A failure writes 3 to tohost.
#=======================================================================

#include "encoding.h"

#define PTE_LEAF_RWX (PTE_D | PTE_A | PTE_X | PTE_W | PTE_R | PTE_V)

# Mapped by l2[4], which is 32-byte aligned in pgtb_l2: a 32-byte NAPOT
# region covers l2[4..7] and leaves l2[2], which maps the code, readable.
#define VA_TGT 0x0000000100000000
#define VA_TGT_L2_OFFSET (4*8)

.text
.global _start
.option norvc

_start:
    # pmpaddr0: l2[4..7], no permission
    la   t2, pgtb_l2
    addi t2, t2, VA_TGT_L2_OFFSET
    srli t2, t2, 2
    ori  t2, t2, 0x3
    csrw pmpaddr0, t2
    # pmpaddr1: all memory, RWX
    li   t2, -1
    csrw pmpaddr1, t2
    li   t2, ((PMP_NAPOT | PMP_X | PMP_W | PMP_R) << 8) | PMP_NAPOT
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
    # l2[4]: VA_TGT, a valid gigapage the walk cannot read
    sd   t0, VA_TGT_L2_OFFSET(t1)

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
    # 1. load: the PTE read faults
    li   s2, 1
    li   t1, VA_TGT
fault_load:
    ld   t0, 0(t1)
    # 2. store: the PTE read faults
    li   s2, 2
    li   t1, VA_TGT
fault_store:
    sd   zero, 0(t1)
    # 3. done
    li   s2, 3
    ecall

    # s2 = step
trap_handler:
    csrr t0, mcause
    csrr t1, mepc
    li   t2, 1
    beq  s2, t2, check_load
    li   t2, 2
    beq  s2, t2, check_store
    li   t2, 3
    beq  s2, t2, check_end
    j    trap_bad

check_load:
    li   t2, CAUSE_LOAD_ACCESS
    bne  t0, t2, trap_bad
    la   t2, fault_load
    bne  t1, t2, trap_bad
    addi t1, t1, 4
    csrw mepc, t1
    mret

check_store:
    li   t2, CAUSE_STORE_ACCESS
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
