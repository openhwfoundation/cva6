#=======================================================================
#      Selective and global SFENCE.VMA against the shared TLB
#-----------------------------------------------------------------------
# Test Description:
# SFENCE.VMA, in its targeted and its global form, against the shared TLB,
# with translation enabled. Over-invalidation is architecturally legal, so
# the test can only detect what is wrong:
#   - under-invalidation: a fence that matches too little leaves a stale
#     entry behind, which scenarios 2 and 3 read back;
#   - a lost fence, a walker that never returns to idle, or a flush_busy
#     handshake that deadlocks the commit stage.
#
# Scenarios
# ---------
#   1. Targeted fence preserves unrelated translations
#      Two pages are mapped and both are walked into the TLB. A fence
#      naming only the first one is issued and the second page must still
#      read back its value.
#
#   2. Targeted fence does take effect on the page it names
#      The first page is remapped to another frame while its entry is
#      still cached, then a fence naming it is issued. The read must
#      return the new frame; a fence matching nothing would return the
#      stale one.
#
#   3. Global fence clears everything
#      Both pages are remapped, two `sfence.vma` with no operands are
#      issued back to back, and both reads must return the new frames.
#      This is the form that short-circuits the set walker, and the second
#      fence reaches the commit stage while the walker may still be busy:
#      without the flush_busy handshake it would lose its pulse and its
#      operands, leaving a stale entry these reads then catch.
#
# Runs on RV32 with Sv32 only, in S-mode, since Sv32 does not translate
# in M-mode.
#=======================================================================

#include "macros.h"

#define PTE_LEAF_RW ( PTE_D | PTE_A | PTE_W | PTE_R | PTE_V )
#define PTE_LEAF_X  ( PTE_D | PTE_A | PTE_X | PTE_R | PTE_V )

.text
.global _start
.option norvc

_start:
    ALL_MEM_PMP
    la   t1, trap_handler
    csrw mtvec, t1

# ---------------- level 1 PTE pointing at the level 0 table ------------
    la   a1, pgtb_l0
    mv   a0, a1
    ori  a2, x0, ( PTE_V )
    PTE_SETUP_RV32(a1, a2, t1, a0, pgtb_l1, LEVEL1)

# ---------------- identity map the code so fetch survives satp ---------
    la   a1, vm_en
    mv   a0, a1
    ori  a2, x0, ( PTE_LEAF_X )
    PTE_SETUP_RV32(a1, a2, t1, a0, pgtb_l0, LEVEL0)

# ---------------- identity map the level 0 table itself ----------------
# scenarios 2 and 3 rewrite PTEs while running in S-mode, so the table
# has to be reachable through the translation it defines
    la   a1, pgtb_l0
    mv   a0, a1
    ori  a2, x0, ( PTE_LEAF_RW )
    PTE_SETUP_RV32(a1, a2, t1, a0, pgtb_l0, LEVEL0)

# ---------------- map page_a to frame_one, page_b to frame_two ---------
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

# =======================================================================
# Scenario 1: a targeted fence leaves an unrelated translation alone
# =======================================================================
    # walk both pages into the TLB
    la   t0, page_a
    lw   t1, 0(t0)
    li   t2, 0x11111111
    bne  t1, t2, fail

    la   t0, page_b
    lw   t1, 0(t0)
    li   t2, 0x22222222
    bne  t1, t2, fail

    # fence naming page_a only; page_b must be untouched
    la   t0, page_a
    sfence.vma t0

    la   t0, page_b
    lw   t1, 0(t0)
    li   t2, 0x22222222
    bne  t1, t2, fail

# =======================================================================
# Scenario 2: a targeted fence does take effect on the page it names
# =======================================================================
    # walk page_a again so its translation to frame_one is cached (the
    # fence of scenario 1 dropped it), then repoint it at frame_three
    la   t0, page_a
    lw   t1, 0(t0)
    li   t2, 0x11111111
    bne  t1, t2, fail

    la   a1, frame_three
    la   a0, page_a
    ori  a2, x0, ( PTE_LEAF_RW )
    PTE_SETUP_RV32(a1, a2, t1, a0, pgtb_l0, LEVEL0)

    # without the fence the stale entry would still answer frame_one
    la   t0, page_a
    sfence.vma t0

    la   t0, page_a
    lw   t1, 0(t0)
    li   t2, 0x33333333
    bne  t1, t2, fail

    # page_b was never named and must still answer frame_two
    la   t0, page_b
    lw   t1, 0(t0)
    li   t2, 0x22222222
    bne  t1, t2, fail

# =======================================================================
# Scenario 3: a global fence clears every entry, walker short-circuited
# =======================================================================
    # repoint both pages while both are cached
    la   a1, frame_two
    la   a0, page_a
    ori  a2, x0, ( PTE_LEAF_RW )
    PTE_SETUP_RV32(a1, a2, t1, a0, pgtb_l0, LEVEL0)

    la   a1, frame_three
    la   a0, page_b
    ori  a2, x0, ( PTE_LEAF_RW )
    PTE_SETUP_RV32(a1, a2, t1, a0, pgtb_l0, LEVEL0)

    # two fences back to back: the second one reaches commit while the
    # walker may still be busy on the first
    sfence.vma
    sfence.vma

    la   t0, page_a
    lw   t1, 0(t0)
    li   t2, 0x22222222
    bne  t1, t2, fail

    la   t0, page_b
    lw   t1, 0(t0)
    li   t2, 0x33333333
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
        .word 0x11111111
        .zero 4092
.align 12
    frame_two:
        .word 0x22222222
        .zero 4092
.align 12
    frame_three:
        .word 0x33333333
        .zero 4092

# virtual pages, never accessed through their own storage
.align 12
    page_a:
        .zero 4096
.align 12
    page_b:
        .zero 4096

.align 4; .global tohost;   tohost:   .dword 0;
.align 4; .global fromhost; fromhost: .dword 0;
