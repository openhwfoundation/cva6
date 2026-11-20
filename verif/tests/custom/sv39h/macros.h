//=======================================================================
//      Macros for Sv39 two-stage translation tests
//-----------------------------------------------------------------------
// Sv39 walks three levels of nine VPN bits each over 4KiB pages, and the
// G stage of Sv39x4 adds two bits at the root, so its level 2 table is
// four pages wide and has to be 16KiB aligned.
//
// The hstatus and mstatus virtualisation fields are spelled out here
// because verif/tests/custom/env/encoding.h carries the hypervisor CSR
// numbers but not those bits.
//=======================================================================

#include "../env/encoding.h"

#define _start rvtest_entry_point

#define LEVEL0 0
#define LEVEL1 1
#define LEVEL2 2

// hstatus.SPV selects whether an SRET returns to the virtual world;
// encoding.h carries the hypervisor CSR numbers but not these fields
#define HSTATUS_SPV  0x00000080
#define HSTATUS_SPVP 0x00000100

// an ECALL taken from VS mode reports cause 10, absent from encoding.h
#define CAUSE_VIRTUAL_SUPERVISOR_ECALL 0xA

// mstatus.MPV, the M-mode counterpart, sits above bit 32 on RV64
#define MSTATUS_MPV  0x0000008000000000

#define PTE_LEAF_RW (PTE_D | PTE_A | PTE_W | PTE_R | PTE_V)
#define PTE_LEAF_RX (PTE_D | PTE_A | PTE_X | PTE_R | PTE_V)
#define PTE_LEAF_RWX (PTE_D | PTE_A | PTE_X | PTE_W | PTE_R | PTE_V)
#define PTE_LEAF_U_RW (PTE_U | PTE_LEAF_RW)
#define PTE_LEAF_U_RX (PTE_U | PTE_LEAF_RX)
#define PTE_LEAF_U_RWX (PTE_U | PTE_LEAF_RWX)

// Build a PTE in PA from a physical address and permission bits.
#define PTE_SV39(PA, PR)                                           ;\
    srli PA, PA, RISCV_PGSHIFT                                     ;\
    slli PA, PA, PTE_PPN_SHIFT                                     ;\
    or   PA, PA, PR                                                ;

// Write a PTE mapping VA to PA at LEVEL of the table at PGTB_ADDR.
// PA and VA are clobbered, TMP is scratch.
#define PTE_SETUP_SV39(PA, PR, TMP, VA, PGTB_ADDR, LEVEL)          ;\
    PTE_SV39(PA, PR)                                               ;\
    .if (LEVEL == 2)                                               ;\
        srli VA, VA, 30                                            ;\
    .endif                                                         ;\
    .if (LEVEL == 1)                                               ;\
        srli VA, VA, 21                                            ;\
    .endif                                                         ;\
    .if (LEVEL == 0)                                               ;\
        srli VA, VA, 12                                            ;\
    .endif                                                         ;\
    andi VA, VA, 0x1ff                                             ;\
    slli VA, VA, 3                                                 ;\
    la   TMP, PGTB_ADDR                                            ;\
    add  TMP, TMP, VA                                              ;\
    sd   PA, 0(TMP)                                                ;

// Same, for the root table of a G stage: Sv39x4 widens VPN2 to eleven
// bits, so the index is not masked down to nine.
#define PTE_SETUP_SV39X4_ROOT(PA, PR, TMP, VA, PGTB_ADDR)          ;\
    PTE_SV39(PA, PR)                                               ;\
    srli VA, VA, 30                                                ;\
    andi VA, VA, 0x7ff                                             ;\
    slli VA, VA, 3                                                 ;\
    la   TMP, PGTB_ADDR                                            ;\
    add  TMP, TMP, VA                                              ;\
    sd   PA, 0(TMP)                                                ;

#define SATP_SETUP_SV39(PGTB_ADDR)                                 ;\
    la   t6, PGTB_ADDR                                             ;\
    srli t6, t6, RISCV_PGSHIFT                                     ;\
    li   t5, SATP_MODE_SV39                                        ;\
    slli t5, t5, 60                                                ;\
    or   t6, t6, t5                                                ;\
    csrw satp, t6                                                  ;\
    sfence.vma                                                     ;

#define VSATP_SETUP_SV39(PGTB_ADDR)                                ;\
    la   t6, PGTB_ADDR                                             ;\
    srli t6, t6, RISCV_PGSHIFT                                     ;\
    li   t5, SATP_MODE_SV39                                        ;\
    slli t5, t5, 60                                                ;\
    or   t6, t6, t5                                                ;\
    csrw CSR_VSATP, t6                                             ;\
    hfence.vvma                                                    ;

#define HGATP_SETUP_SV39X4(PGTB_ADDR)                              ;\
    la   t6, PGTB_ADDR                                             ;\
    srli t6, t6, RISCV_PGSHIFT                                     ;\
    li   t5, SATP_MODE_SV39                                        ;\
    slli t5, t5, 60                                                ;\
    or   t6, t6, t5                                                ;\
    csrw CSR_HGATP, t6                                             ;\
    hfence.gvma                                                    ;

#define ALL_MEM_PMP                                                ;\
    li   t2, -1                                                    ;\
    csrw pmpaddr0, t2                                              ;\
    li   t2, 0x0F                                                  ;\
    csrw pmpcfg0, t2                                               ;\
    sfence.vma                                                     ;

// Drop from M to VS mode at MEPC_ADDR: MPP = S and mstatus.MPV = 1.
#define CHANGE_T0_VS_MODE(MEPC_ADDR)                               ;\
    li   t0, MSTATUS_MPP                                           ;\
    csrc mstatus, t0                                               ;\
    li   t1, MSTATUS_MPP & (MSTATUS_MPP >> 1)                      ;\
    csrs mstatus, t1                                               ;\
    li   t2, MSTATUS_MPV                                           ;\
    csrs mstatus, t2                                               ;\
    csrw mepc, MEPC_ADDR                                           ;\
    mret                                                           ;

// Drop from M to HS mode: MPP = S with mstatus.MPV clear.
#define CHANGE_T0_HS_MODE(MEPC_ADDR)                               ;\
    li   t0, MSTATUS_MPP                                           ;\
    csrc mstatus, t0                                               ;\
    li   t1, MSTATUS_MPP & (MSTATUS_MPP >> 1)                      ;\
    csrs mstatus, t1                                               ;\
    li   t2, MSTATUS_MPV                                           ;\
    csrc mstatus, t2                                               ;\
    csrw mepc, MEPC_ADDR                                           ;\
    mret                                                           ;

#define COREV_VERIF_EXIT_LOGIC                                     ;\
exit:                                                              ;\
    slli x1, x1, 1                                                 ;\
    addi x1, x1, 1                                                 ;\
    mv   x30, s1                                                   ;\
    sd   x1, tohost, x30                                           ;\
    self_loop: j self_loop                                         ;
