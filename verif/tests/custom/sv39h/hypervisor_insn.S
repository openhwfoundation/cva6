//=======================================================================
//      Hypervisor instruction and CSR coverage
//-----------------------------------------------------------------------
// Test Description:
// Executes the hypervisor fences and accesses the hypervisor CSRs, in HS mode.
//
// What it covers
// --------------
//   - HFENCE.GVMA in its four forms: no operand, address only, VMID only,
//     address and VMID
//   - HFENCE.VVMA in the same four forms
//   - back to back fences, so a second one reaches the commit stage while
//     the first may still be in flight
//   - read and write of the hypervisor CSRs the core implements: hgatp,
//     hstatus, hedeleg, hideleg, htval, htinst, vsatp, vsstatus, vstvec,
//     vsepc
//   - hgatp and vsatp are programmed with real Sv39x4 and Sv39 roots and
//     read back, so the fences carry operands that mean something
//
// What it does NOT cover
// ----------------------
// In HS mode hgatp does not translate, so no guest entry is cached and the
// fences have nothing to invalidate: the GVMA address comparison is not
// checked. That needs a guest running in VS mode.
//
// It catches a decoder that no longer accepts these opcodes, a CSR that is
// no longer reachable, and any elaboration or reset failure on an RVH
// configuration.
//
// Runs in HS mode on RV64 with the hypervisor extension, S-stage Sv39
// identity mapped.
//=======================================================================

#include "macros.h"

.text
.global _start
.option norvc

_start:
    ALL_MEM_PMP
    la   t1, trap_handler
    csrw mtvec, t1
    li   s1, 0

// ---------------- S-stage: identity map the whole test ---------------
    la   a1, pgtb_s_l1
    la   a0, _start
    ori  a2, x0, (PTE_V)
    PTE_SETUP_SV39(a1, a2, t1, a0, pgtb_s_l2, LEVEL2)

    la   a1, pgtb_s_l0
    la   a0, _start
    ori  a2, x0, (PTE_V)
    PTE_SETUP_SV39(a1, a2, t1, a0, pgtb_s_l1, LEVEL1)

    // every 4KiB page of the 2MiB region the test lives in
    la   s3, _start
    li   s4, 512
s_map_loop:
    mv   a1, s3
    mv   a0, s3
    ori  a2, x0, (PTE_LEAF_RWX)
    PTE_SETUP_SV39(a1, a2, t1, a0, pgtb_s_l0, LEVEL0)
    li   t2, 4096
    add  s3, s3, t2
    addi s4, s4, -1
    bnez s4, s_map_loop

// ---------------- program the hypervisor roots -----------------------
// hgatp does not translate from HS mode, but the fences below carry its
// VMID and the core latches the operands either way
    HGATP_SETUP_SV39X4(pgtb_g_l2)
    VSATP_SETUP_SV39(pgtb_vs_l2)
    SATP_SETUP_SV39(pgtb_s_l2)

    la   a1, vm_en
    CHANGE_T0_HS_MODE(a1)

vm_en:

// =======================================================================
// hgatp and vsatp read back what was written
// =======================================================================
    la   t0, pgtb_g_l2
    srli t0, t0, RISCV_PGSHIFT
    li   t1, SATP_MODE_SV39
    slli t1, t1, 60
    or   t0, t0, t1
    csrr t2, CSR_HGATP
    bne  t0, t2, fail

    la   t0, pgtb_vs_l2
    srli t0, t0, RISCV_PGSHIFT
    li   t1, SATP_MODE_SV39
    slli t1, t1, 60
    or   t0, t0, t1
    csrr t2, CSR_VSATP
    bne  t0, t2, fail

// =======================================================================
// HFENCE.GVMA, four forms
// =======================================================================
    // no operand: flush every guest entry, every VMID
    hfence.gvma

    // address only: HFENCE.GVMA takes the guest physical address shifted
    // right by two, the core shifts it back
    la   t0, gpage_a
    srli t0, t0, 2
    hfence.gvma t0, x0

    // VMID only
    li   t1, 1
    hfence.gvma x0, t1

    // address and VMID
    la   t0, gpage_a
    srli t0, t0, 2
    li   t1, 1
    hfence.gvma t0, t1

    // back to back, so the second reaches commit while the first may
    // still be walking
    hfence.gvma
    hfence.gvma

// =======================================================================
// HFENCE.VVMA, four forms
// =======================================================================
    hfence.vvma

    la   t0, gpage_a
    hfence.vvma t0, x0

    li   t1, 1
    hfence.vvma x0, t1

    la   t0, gpage_a
    li   t1, 1
    hfence.vvma t0, t1

    hfence.vvma
    hfence.vvma

// =======================================================================
// The S-stage translation still works after all that flushing
// =======================================================================
    la   t0, scratch
    li   t1, 0x5555555555555555
    sd   t1, 0(t0)
    ld   t2, 0(t0)
    bne  t1, t2, fail

// =======================================================================
// The hypervisor CSRs are reachable
// =======================================================================
    // hstatus: write a value, read it back, restore
    csrr s5, CSR_HSTATUS
    li   t0, HSTATUS_SPVP
    csrs CSR_HSTATUS, t0
    csrr t1, CSR_HSTATUS
    and  t2, t1, t0
    beqz t2, fail
    csrc CSR_HSTATUS, t0
    csrw CSR_HSTATUS, s5

    // the trap value registers of the hypervisor
    csrr t0, CSR_HTVAL
    csrr t0, CSR_HTINST

    // delegation registers
    csrr s5, CSR_HEDELEG
    csrw CSR_HEDELEG, x0
    csrw CSR_HEDELEG, s5
    csrr s5, CSR_HIDELEG
    csrw CSR_HIDELEG, x0
    csrw CSR_HIDELEG, s5

    // the virtual supervisor registers
    csrr s5, CSR_VSSTATUS
    csrw CSR_VSSTATUS, s5

    la   t0, vs_handler
    csrw CSR_VSTVEC, t0
    csrr t1, CSR_VSTVEC
    bne  t0, t1, fail

    la   t0, scratch
    csrw CSR_VSEPC, t0
    csrr t1, CSR_VSEPC
    bne  t0, t1, fail

// =======================================================================
// A final fence, and the translation is still alive
// =======================================================================
    hfence.gvma
    hfence.vvma
    sfence.vma

    la   t0, scratch
    ld   t2, 0(t0)
    li   t1, 0x5555555555555555
    bne  t1, t2, fail

pass:
    li   s1, 0
    ecall

fail:
    li   s1, 1
    ecall

// never reached, only used as a value written to vstvec
vs_handler:
    j    fail

trap_handler:
    // the only expected trap is the ecall that ends the test; anything
    // else, an illegal instruction on one of the fences above in
    // particular, is a failure
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
    scratch:
        .dword 0xdeadbeefdeadbeef
        .zero 4088

.align 12
    gpage_a:
        .zero 4096

// S-stage tables
.align 12
    pgtb_s_l2:
        .zero 4096
    pgtb_s_l1:
        .zero 4096
    pgtb_s_l0:
        .zero 4096

// VS-stage root, programmed into vsatp so the fences carry a real value
.align 12
    pgtb_vs_l2:
        .zero 4096

// G-stage root: Sv39x4 is four pages wide and 16KiB aligned
.align 14
    pgtb_g_l2:
        .zero 16384

.align 4; .global tohost;   tohost:   .dword 0;
.align 4; .global fromhost; fromhost: .dword 0;
