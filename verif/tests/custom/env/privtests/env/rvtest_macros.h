// Page Table Macros

/* Set up the Page table entry for Sv32 Translation scheme
    Arguments:
    _PAR: Register containing Physical Address
    _PR: Register containing Permissions for Leaf PTE.
        (Note: No-leaf PTE (if-any) has only valid permission (pte.v) set)
    _TR0, _TR1, _TR2: Temporary registers used and modified by function
    VA: Virtual address
    level: Level at which PTE would be setup
        0: Two level translation
        1: Superpage
*/

#define LEVEL0 0x00
#define LEVEL1 0x01
#define LEVEL2 0x02
#define LEVEL3 0x03
#define LEVEL4 0x04

#define sv39 0x00
#define sv48 0x01
#define sv57 0x02

#define CODE code_bgn_off
#define DATA data_bgn_off
#define SIG  sig_bgn_off
#define VMEM vmem_bgn_off


//****NOTE: label `rvtest_Sroot_pg_tbl` must be declared after RVTEST_DATA_END
//          in the test aligned at 4kiB (use .align 12)
#define PTE_SETUP_COMMON(_PAR, _PR, _TR0, _TR1, _VAR, level)      ;\
    srli _VAR, _VAR, (RISCV_PGLEVEL_BITS * level + RISCV_PGSHIFT) ;\
    srli _PAR, _PAR, (RISCV_PGLEVEL_BITS * level + RISCV_PGSHIFT) ;\
    slli _PAR, _PAR, (RISCV_PGLEVEL_BITS * level + RISCV_PGSHIFT) ;\
    LI(_TR0, ((1 << RISCV_PGLEVEL_BITS) - 1))                     ;\
    and _VAR, _VAR, _TR0                                          ;\
    slli _VAR, _VAR, ((XLEN >> 5)+1)                              ;\
    add _TR1, _TR1, _VAR                                          ;\
    srli _PAR, _PAR, 12                                           ;\
    slli _PAR, _PAR, 10                                           ;\
    or _PAR, _PAR, _PR                                            ;\
    SREG _PAR, 0(_TR1);

// Appends 12-bit page offset from PA to VA, and stores it
// to S save area; a0 must point to M save area
#define SAVE_AREA_SETUP(VA, PA_LBL, _REG_NAME)                  ;\
    LI(  t0, VA)                                                ;\
    LA(  t1, PA_LBL)                                            ;\
    srli t0, t0, 12                                             ;\
    slli t0, t0, 12                                             ;\
    LI(  t2, 0xFFF)                                             ;\
    and  t2, t1, t2                                             ;\
    or   t2, t0, t2                                             ;\
    SREG t2, _REG_NAME##_bgn_off+1*sv_area_sz(a0)               ;

// Appends 12-bit page offset from PA to VA, and stores it
// to V save area; a0 must point to M save area
#define GUEST_SAVE_AREA_SETUP(VA, PA_LBL, _REG_NAME)            ;\
    LI(  t0, VA)                                                ;\
    LA(  t1, PA_LBL)                                            ;\
    srli t0, t0, 12                                             ;\
    slli t0, t0, 12                                             ;\
    LI(  t2, 0xFFF)                                             ;\
    and  t2, t1, t2                                             ;\
    or   t2, t0, t2                                             ;\
    addi a0, a0, 2*sv_area_sz                                   ;\
    SREG t2, _REG_NAME##_bgn_off+1*sv_area_sz(a0)               ;\
    addi a0, a0, -2*sv_area_sz                                  ;

#define PTE_SETUP_RV32(_PAR, _PR, _TR0, _TR1, VA, level)        ;\
    srli _PAR, _PAR, 12                                         ;\
    slli _PAR, _PAR, 10                                         ;\
    or _PAR, _PAR, _PR                                          ;\
    .if (level==1)                                              ;\
        LA(_TR1, rvtest_Sroot_pg_tbl)                           ;\
        LI(_TR0, ((VA>>22)&0x3FF)<<2)                           ;\
    .endif                                                      ;\
    .if (level==0)                                              ;\
        LA(_TR1, rvtest_slvl0_pg_tbl)                           ;\
        LI(_TR0, ((VA>>12)&0x3FF)<<2)                           ;\
    .endif                                                      ;\
    add _TR1, _TR1, _TR0                                        ;\
    SREG _PAR, 0(_TR1)                                          ;

#define PTE_SETUP_RV64(_PAR, _PR, _TR0, _TR1, VA, level, mode)  ;\
    srli _PAR, _PAR, 12                                         ;\
    slli _PAR, _PAR, 10                                         ;\
    or _PAR, _PAR, _PR                                          ;\
    .if (mode == sv39)                                          ;\
        .if (level == 2)                                        ;\
            LA(_TR1, rvtest_Sroot_pg_tbl)                       ;\
            .set vpn, ((VA >> 30) & 0x1FF) << 3                 ;\
        .endif                                                  ;\
        .if (level == 1)                                        ;\
            LA(_TR1, rvtest_slvl1_pg_tbl)                       ;\
            .set vpn, ((VA >> 21) & 0x1FF) << 3                 ;\
        .endif                                                  ;\
        .if (level == 0)                                        ;\
            LA(_TR1, rvtest_slvl0_pg_tbl)                       ;\
            .set vpn, ((VA >> 12) & 0x1FF) << 3                 ;\
        .endif                                                  ;\
    .endif                                                      ;\
    .if (mode == sv48)                                          ;\
        .if (level == 3)                                        ;\
            LA(_TR1, rvtest_Sroot_pg_tbl)                       ;\
            .set vpn, ((VA >> 39) & 0x1FF) << 3                 ;\
        .endif                                                  ;\
        .if (level == 2)                                        ;\
            LA(_TR1, rvtest_slvl2_pg_tbl)                       ;\
            .set vpn, ((VA >> 30) & 0x1FF) << 3                 ;\
        .endif                                                  ;\
        .if (level == 1)                                        ;\
            LA(_TR1, rvtest_slvl1_pg_tbl)                       ;\
            .set vpn, ((VA >> 21) & 0x1FF) << 3                 ;\
        .endif                                                  ;\
        .if (level == 0)                                        ;\
            LA(_TR1, rvtest_slvl0_pg_tbl)                       ;\
            .set vpn, ((VA >> 12) & 0x1FF) << 3                 ;\
        .endif                                                  ;\
    .endif                                                      ;\
    .if (mode == sv57)                                          ;\
        .if (level == 4)                                        ;\
            LA(_TR1, rvtest_Sroot_pg_tbl)                       ;\
            .set vpn, ((VA >> 48) & 0x1FF) << 3                 ;\
        .endif                                                  ;\
        .if (level == 3)                                        ;\
            LA(_TR1, rvtest_slvl3_pg_tbl)                       ;\
            .set vpn, ((VA >> 39) & 0x1FF) << 3                 ;\
        .endif                                                  ;\
        .if (level == 2)                                        ;\
            LA(_TR1, rvtest_slvl2_pg_tbl)                       ;\
            .set vpn, ((VA >> 30) & 0x1FF) << 3                 ;\
        .endif                                                  ;\
        .if (level == 1)                                        ;\
            LA(_TR1, rvtest_slvl1_pg_tbl)                       ;\
            .set vpn, ((VA >> 21) & 0x1FF) << 3                 ;\
        .endif                                                  ;\
        .if (level == 0)                                        ;\
            LA(_TR1, rvtest_slvl0_pg_tbl)                       ;\
            .set vpn, ((VA >> 12) & 0x1FF) << 3                 ;\
        .endif                                                  ;\
    .endif                                                      ;\
    LI(_TR0, vpn)                                               ;\
    add _TR1, _TR1, _TR0                                        ;\
    SREG _PAR, 0(_TR1)                                          ;

#define PTE_SETUP_SV32(PA_LBL, PERMS, VA, level)                ;\
    LA(a0, PA_LBL)                                              ;\
    LI(a1, PERMS)                                               ;\
    PTE_SETUP_RV32(a0, a1, t0, t1, VA, level)                   ;

#define SUPERPAGE_PTE_SETUP_SV32(PA_LBL, PERMS, VA, level)      ;\
    LA(a0, (PA_LBL))                                            ;\
    srli a0, a0, 22                                             ;\
    slli a0, a0, 22                                             ;\
    LI(a1, PERMS)                                               ;\
    PTE_SETUP_RV32(a0, a1, t0, t1, VA, level)                   ;

#define PTE_SETUP_SV39(PA_LBL, PERMS, VA, level)                ;\
    LA(a0, PA_LBL)                                              ;\
    LI(a1, PERMS)                                               ;\
    PTE_SETUP_RV64(a0, a1, t0, t1, VA, level, sv39)             ;

#define SUPERPAGE_PTE_SETUP_SV39(PA_LBL, PERMS, VA, level)      ;\
    .set PA_SHIFT, (level*9)+12                                 ;\
    LA(a0, (PA_LBL))                                            ;\
    srli a0, a0, PA_SHIFT                                       ;\
    slli a0, a0, PA_SHIFT                                       ;\
    LI(a1, PERMS)                                               ;\
    PTE_SETUP_RV64(a0, a1, t0, t1, VA, level, sv39)             ;

#define PTE_SETUP_SV48(PA_LBL, PERMS, VA, level)                ;\
    LA(a0, PA_LBL)                                              ;\
    LI(a1, PERMS)                                               ;\
    PTE_SETUP_RV64(a0, a1, t0, t1, VA, level, sv48)             ;

#define SUPERPAGE_PTE_SETUP_SV48(PA_LBL, PERMS, VA, level)      ;\
    .set PA_SHIFT, (level*9)+12                                 ;\
    LA(a0, (PA_LBL))                                            ;\
    srli a0, a0, PA_SHIFT                                       ;\
    slli a0, a0, PA_SHIFT                                       ;\
    LI(a1, PERMS)                                               ;\
    PTE_SETUP_RV64(a0, a1, t0, t1, VA, level, sv48)             ;

#define PTE_SETUP_SV57(PA_LBL, PERMS, VA, level)                ;\
    LA(a0, PA_LBL)                                              ;\
    LI(a1, PERMS)                                               ;\
    PTE_SETUP_RV64(a0, a1, t0, t1, VA, level, sv57)             ;

#define SUPERPAGE_PTE_SETUP_SV57(PA_LBL, PERMS, VA, level)      ;\
    .set PA_SHIFT, (level*9)+12                                 ;\
    LA(a0, (PA_LBL))                                            ;\
    srli a0, a0, PA_SHIFT                                       ;\
    slli a0, a0, PA_SHIFT                                       ;\
    LI(a1, PERMS)                                               ;\
    PTE_SETUP_RV64(a0, a1, t0, t1, VA, level, sv57)             ;

#define PTE_PERMUPD_RV32(_PR, _TR0, _TR1, VA, level)            ;\
    .if (level==1)                                              ;\
        LA(_TR1, rvtest_Sroot_pg_tbl)                           ;\
        .set vpn, ((VA>>22)&0x3FF)<<2                           ;\
    .endif                                                      ;\
    .if (level==0)                                              ;\
        LA(_TR1, rvtest_slvl1_pg_tbl)                           ;\
        .set vpn, ((VA>>12)&0x3FF)<<2                           ;\
    .endif                                                      ;\
    LI(_TR0, vpn)                                               ;\
    add _TR1, _TR1, _TR0                                        ;\
    LREG _TR0, 0(_TR1)                                          ;\
    srli _TR0, _TR0, 10                                         ;\
    slli _TR0, _TR0, 10                                         ;\
    or _TR0, _TR0, _PR                                          ;\
    SREG _TR0, 0(_TR1)                                          ;

#define SATP_SETUP_SV32                                         ;\
    LA(t6, rvtest_Sroot_pg_tbl)                                 ;\
    LI(t5, SATP32_MODE)                                         ;\
    srli t6, t6, 12                                             ;\
    or t6, t6, t5                                               ;\
    csrw satp, t6                                               ;

#define SATP_SETUP_RV64(MODE)                                   ;\
    LA(t6, rvtest_Sroot_pg_tbl)                                 ;\
    .if (MODE == sv39)                                          ;\
    LI(t5, (SATP64_MODE) & (SATP_MODE_SV39 << 60))              ;\
    .endif                                                      ;\
    .if (MODE == sv48)                                          ;\
    LI(t5, (SATP64_MODE) & (SATP_MODE_SV48 << 60))              ;\
    .endif                                                      ;\
    .if (MODE == sv57)                                          ;\
    LI(t5, (SATP64_MODE) & (SATP_MODE_SV57 << 60))              ;\
    .endif                                                      ;\
    srli t6, t6, 12                                             ;\
    or t6, t6, t5                                               ;\
    csrw satp, t6                                               ;
