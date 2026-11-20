#=======================================================================
#      Sv32 translation with big endian data accesses
#-----------------------------------------------------------------------
# Test Description:
# With mstatus.MBE set, M-mode builds the page tables with plain word
# stores, so every PTE is in memory in big endian byte order. With SBE
# set too (it mirrors MBE), S-mode then reads through the translation
# those tables define: the page table walker has to read the PTEs in big
# endian byte order to reach the right frames.
#
#   1. page_a maps frame_one and page_b frame_two; S-mode reads both and
#      gets their own words back.
#   2. Each frame holds a word written under MBE; reading it in S-mode,
#      through the translation, returns the value written, and its lowest
#      addressed byte is the most significant one.
#
# Requires Sv32, S-mode and BigEndianEn.
#=======================================================================

#include "macros.h"

#define MSTATUSH       0x310
#define MSTATUSH_MBE   0x20
#define PTE_LEAF_RW ( PTE_D | PTE_A | PTE_W | PTE_R | PTE_V )
#define PTE_LEAF_X  ( PTE_D | PTE_A | PTE_X | PTE_R | PTE_V )

.text
.global _start
.option norvc

_start:
    ALL_MEM_PMP
    la   t1, trap_handler
    csrw mtvec, t1

    # big endian data accesses from here on, in M-mode and S-mode
    li   t0, MSTATUSH_MBE
    csrs MSTATUSH, t0

# ---------------- frames: words written under MBE ---------------------
    la   t0, frame_one
    li   t1, 0x11223344
    sw   t1, 0(t0)
    la   t0, frame_two
    li   t1, 0x55667788
    sw   t1, 0(t0)

# ---------------- level 1 PTE pointing at the level 0 table ------------
    la   a1, pgtb_l0
    mv   a0, a1
    ori  a2, x0, ( PTE_V )
    PTE_SETUP_RV32(a1, a2, t1, a0, pgtb_l1, LEVEL1)

# ---------------- identity map the code --------------------------------
    la   a1, vm_en
    mv   a0, a1
    ori  a2, x0, ( PTE_LEAF_X )
    PTE_SETUP_RV32(a1, a2, t1, a0, pgtb_l0, LEVEL0)

# ---------------- page_a -> frame_one, page_b -> frame_two -------------
    la   a1, frame_one
    la   a0, page_a
    ori  a2, x0, ( PTE_LEAF_RW )
    PTE_SETUP_RV32(a1, a2, t1, a0, pgtb_l0, LEVEL0)

    la   a1, frame_two
    la   a0, page_b
    ori  a2, x0, ( PTE_LEAF_RW )
    PTE_SETUP_RV32(a1, a2, t1, a0, pgtb_l0, LEVEL0)

# ---------------- enable translation -----------------------------------
    SATP_SETUP_SV32(pgtb_l1)
    la   a1, vm_en
    CHANGE_T0_S_MODE(a1)

vm_en:
    # 1. the walk found frame_one and frame_two
    la   t0, page_a
    lw   t1, 0(t0)
    li   t2, 0x11223344
    bne  t1, t2, fail

    la   t0, page_b
    lw   t1, 0(t0)
    li   t2, 0x55667788
    bne  t1, t2, fail

    # 2. big endian in S-mode: the lowest addressed byte is the most
    #    significant one
    la   t0, page_a
    lbu  t1, 0(t0)
    li   t2, 0x11
    bne  t1, t2, fail

pass:
    li   s1, 0
    ecall

fail:
    li   s1, 1
    ecall

trap_handler:
    # the only expected trap is the ecall that ends the test; s1 carries
    # the verdict and any other cause is a failure
    csrr t0, mcause
    li   t1, CAUSE_SUPERVISOR_ECALL
    beq  t0, t1, trap_exit
    li   s1, 1
trap_exit:
    # back to little endian: the tohost protocol is little endian
    li   t0, MSTATUSH_MBE
    csrc MSTATUSH, t0
    mv   x1, s1
    j    exit

COREV_VERIF_EXIT_LOGIC

.data
.align 12
    pgtb_l1:
        .zero 4096
    pgtb_l0:
        .zero 4096

.align 12
    frame_one:
        .zero 4096
.align 12
    frame_two:
        .zero 4096

# virtual pages, never accessed through their own storage
.align 12
    page_a:
        .zero 4096
.align 12
    page_b:
        .zero 4096

.align 4; .global tohost;   tohost:   .dword 0;
.align 4; .global fromhost; fromhost: .dword 0;
