#=======================================================================
#      Svnapot 64 KiB page, Sv39
#-----------------------------------------------------------------------
# A leaf PTE with N set and PPN[3:0] = 1000 maps a naturally aligned 64 KiB
# region with a single entry. The core replaces PPN[3:0] with VA[15:12] to
# build the physical address, so the sixteen 4 KiB pages of the region all
# go through the same TLB entry.
#
# The test identity maps the code and the page tables with ordinary 4 KiB
# leaves, and maps a 64 KiB virtual region to a 64 KiB physical frame with
# sixteen identical NAPOT PTEs, as the specification requires. The virtual
# and physical regions differ, so a wrong PPN patch reads the wrong data.
#
# In S-mode, with Sv39 translation:
#   1. reads the first word of each 4 KiB page of the region, in increasing
#      order; each holds its own page index;
#   2. reads them again in decreasing order, which hits the TLB entry filled
#      by another page of the region;
#   3. writes a new value in each page through the virtual region and reads
#      it back;
#   4. checks from M-mode, with translation off, that the writes reached the
#      physical frame at the expected offsets.
# A failure writes 3 to tohost; a trap writes 3 as well.
#=======================================================================

#include "encoding.h"

#define PTE_N       (1 << 63)
#define PTE_LEAF_RWX (PTE_D | PTE_A | PTE_X | PTE_W | PTE_R | PTE_V)
#define PTE_LEAF_RW  (PTE_D | PTE_A | PTE_W | PTE_R | PTE_V)

# Virtual base of the NAPOT region: 64 KiB aligned, VPN2 = 2, VPN1 = 0
#define NAPOT_VA    0x80400000

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

    # ---------------- root: VPN2 of the code and of NAPOT_VA -------------
    # Code lives at 0x8000_0000 (VPN2 = 2). NAPOT_VA is also in VPN2 = 2,
    # VPN1 = 2, so both hang off the same level 1 table.
    la   t0, pgtb_l1
    srli t0, t0, 12
    slli t0, t0, 10
    ori  t0, t0, PTE_V
    la   t1, pgtb_l2
    sd   t0, (2*8)(t1)              # l2[2] -> l1

    # l1[0] -> l0_code (identity 4 KiB for the code, tables and data)
    la   t0, pgtb_l0_code
    srli t0, t0, 12
    slli t0, t0, 10
    ori  t0, t0, PTE_V
    la   t1, pgtb_l1
    sd   t0, 0(t1)

    # l1[2] -> l0_napot
    la   t0, pgtb_l0_napot
    srli t0, t0, 12
    slli t0, t0, 10
    ori  t0, t0, PTE_V
    la   t1, pgtb_l1
    sd   t0, (2*8)(t1)

    # l0_code: identity map the first 2 MiB from 0x8000_0000 with 4 KiB leaves
    la   t1, pgtb_l0_code
    li   t2, 0x80000000
    li   t3, 512
    li   t4, PTE_LEAF_RWX
1:  srli t0, t2, 12
    slli t0, t0, 10
    or   t0, t0, t4
    sd   t0, 0(t1)
    addi t1, t1, 8
    li   t5, 4096
    add  t2, t2, t5
    addi t3, t3, -1
    bnez t3, 1b

    # l0_napot: sixteen identical NAPOT PTEs for NAPOT_VA .. +64 KiB, all
    # pointing at the 64 KiB frame napot_frame with PPN[3:0] = 1000
    la   t2, napot_frame
    srli t0, t2, 12                 # PPN of the frame, 64 KiB aligned
    ori  t0, t0, 0x8                # PPN[3:0] = 1000
    slli t0, t0, 10
    li   t4, PTE_LEAF_RW
    or   t0, t0, t4
    li   t4, 1
    slli t4, t4, 63                 # N
    or   t0, t0, t4
    la   t1, pgtb_l0_napot          # index of NAPOT_VA in l0 is 0
    li   t3, 16
2:  sd   t0, 0(t1)
    addi t1, t1, 8
    addi t3, t3, -1
    bnez t3, 2b

    # fill the physical frame: word 0 of page i holds 0x5000 + i
    la   t1, napot_frame
    li   t3, 0
3:  li   t0, 0x5000
    add  t0, t0, t3
    sw   t0, 0(t1)
    li   t5, 4096
    add  t1, t1, t5
    addi t3, t3, 1
    li   t5, 16
    bltu t3, t5, 3b

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
    # 1. increasing order
    li   t1, NAPOT_VA
    li   t3, 0
4:  lw   t0, 0(t1)
    li   t2, 0x5000
    add  t2, t2, t3
    bne  t0, t2, fail
    li   t5, 4096
    add  t1, t1, t5
    addi t3, t3, 1
    li   t5, 16
    bltu t3, t5, 4b

    # 2. decreasing order: hits the entry the last walk left
    li   t3, 15
5:  li   t1, NAPOT_VA
    slli t5, t3, 12
    add  t1, t1, t5
    lw   t0, 0(t1)
    li   t2, 0x5000
    add  t2, t2, t3
    bne  t0, t2, fail
    addi t3, t3, -1
    bgez t3, 5b

    # 3. write 0xA000 + i through the virtual region, read back
    li   t3, 0
6:  li   t1, NAPOT_VA
    slli t5, t3, 12
    add  t1, t1, t5
    li   t2, 0xA000
    add  t2, t2, t3
    sw   t2, 4(t1)
    lw   t0, 4(t1)
    bne  t0, t2, fail
    addi t3, t3, 1
    li   t5, 16
    bltu t3, t5, 6b

    # 4. back to M-mode to check the physical frame
    li   s2, 1                      # marks the expected ecall
    ecall

m_check:
    la   t1, napot_frame
    li   t3, 0
7:  lw   t0, 4(t1)
    li   t2, 0xA000
    add  t2, t2, t3
    bne  t0, t2, fail_m
    li   t5, 4096
    add  t1, t1, t5
    addi t3, t3, 1
    li   t5, 16
    bltu t3, t5, 7b
    li   x1, 0
    j    exit

fail:
    li   s2, 2
    ecall
fail_m:
    li   x1, 1
    j    exit

trap_handler:
    csrr t0, mcause
    li   t1, CAUSE_SUPERVISOR_ECALL
    bne  t0, t1, trap_bad
    li   t1, 1
    bne  s2, t1, trap_bad
    csrw satp, zero
    la   t0, m_check
    csrw mepc, t0
    li   t0, MSTATUS_MPP
    csrs mstatus, t0                # stay in M-mode
    mret
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
pgtb_l1:        .zero 4096
pgtb_l0_code:   .zero 4096
pgtb_l0_napot:  .zero 4096
.align 16
napot_frame:    .zero 65536

.align 4; .global tohost;   tohost:   .dword 0;
.align 4; .global fromhost; fromhost: .dword 0;
