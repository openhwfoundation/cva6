#=======================================================================
#      Sv39 translation with big endian data accesses
#-----------------------------------------------------------------------
# Test Description:
# With mstatus.MBE set, M-mode builds the page tables with plain
# doubleword stores, so every PTE is in memory in big endian byte order.
# With SBE set too (it mirrors MBE), S-mode then reads through the
# translation those tables define: the page table walker has to read the
# 64-bit PTEs in big endian byte order to reach the right frames.
#
#   1. page_a maps frame_one and page_b frame_two; S-mode reads both and
#      gets their own doublewords back.
#   2. Each frame holds a doubleword written under MBE; reading it in
#      S-mode, through the translation, returns the value written, and its
#      lowest addressed byte is the most significant one.
#
# A failure or an unexpected trap writes 3 to tohost.
#
# Requires Sv39, S-mode and BigEndianEn.
#=======================================================================
#include "encoding.h"

#define MSTATUS_MBE_BIT 37
#define PTE_LEAF_RWX (PTE_D | PTE_A | PTE_X | PTE_W | PTE_R | PTE_V)
#define PTE_LEAF_RW  (PTE_D | PTE_A | PTE_W | PTE_R | PTE_V)

# Virtual pages: VPN2 = 2, VPN1 = 2, VPN0 = 0 and 1
#define PAGE_A      0x80400000
#define PAGE_B      0x80401000

/* t0 = PTE pointing at the page of \sym, with flags \flags. */
.macro PTE_OF sym, flags
  la   t0, \sym
  srli t0, t0, 12
  slli t0, t0, 10
  ori  t0, t0, \flags
.endm

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

    # big endian data accesses from here on
    li   t0, 1
    slli t0, t0, MSTATUS_MBE_BIT
    csrs mstatus, t0

    # ---------------- frames: doublewords written under MBE --------------
    la   t1, frame_one
    li   t0, 0x1122334455667788
    sd   t0, 0(t1)
    la   t1, frame_two
    li   t0, 0x99aabbccddeeff00
    sd   t0, 0(t1)

    # ---------------- page tables, written under MBE ---------------------
    # l2[2] -> l1 (code at 0x8000_0000 and PAGE_A/PAGE_B share VPN2 = 2)
    PTE_OF pgtb_l1, PTE_V
    la   t1, pgtb_l2
    sd   t0, (2*8)(t1)

    # l1[0] -> l0_code, l1[2] -> l0_data
    PTE_OF pgtb_l0_code, PTE_V
    la   t1, pgtb_l1
    sd   t0, 0(t1)
    PTE_OF pgtb_l0_data, PTE_V
    la   t1, pgtb_l1
    sd   t0, (2*8)(t1)

    # l0_code: identity map the first 2 MiB from 0x8000_0000
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

    # l0_data[0]: PAGE_A -> frame_one, l0_data[1]: PAGE_B -> frame_two
    PTE_OF frame_one, PTE_LEAF_RW
    la   t1, pgtb_l0_data
    sd   t0, 0(t1)
    PTE_OF frame_two, PTE_LEAF_RW
    la   t1, pgtb_l0_data
    sd   t0, 8(t1)

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
    # 1. the walk found frame_one and frame_two
    li   t1, PAGE_A
    ld   t0, 0(t1)
    li   t2, 0x1122334455667788
    bne  t0, t2, fail

    li   t1, PAGE_B
    ld   t0, 0(t1)
    li   t2, 0x99aabbccddeeff00
    bne  t0, t2, fail

    # 2. big endian in S-mode: the lowest addressed byte is the most
    #    significant one
    li   t1, PAGE_A
    lbu  t0, 0(t1)
    li   t2, 0x11
    bne  t0, t2, fail

    li   s2, 1                      # marks the expected ecall
    ecall

fail:
    li   s2, 2
    ecall

trap_handler:
    # the only expected trap is the ecall that ends the test; s2 carries
    # the verdict and any other cause is a failure
    li   x1, 1
    csrr t0, mcause
    li   t1, CAUSE_SUPERVISOR_ECALL
    bne  t0, t1, exit
    li   t1, 1
    bne  s2, t1, exit
    li   x1, 0
exit:
    # back to little endian: the tohost protocol is little endian
    li   t0, 1
    slli t0, t0, MSTATUS_MBE_BIT
    csrc mstatus, t0
    csrw satp, zero
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
pgtb_l0_data:   .zero 4096
frame_one:      .zero 4096
frame_two:      .zero 4096

.align 4; .global tohost;   tohost:   .dword 0;
.align 4; .global fromhost; fromhost: .dword 0;
