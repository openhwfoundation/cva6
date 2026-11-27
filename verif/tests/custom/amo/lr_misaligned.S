.option norvc

.section .text.init
.globl _start
_start:
    la      t0, trap_handler
    csrw    mtvec, t0
    csrw    medeleg, zero
    li      t0, 0x804edc44
    srli    t0, t0, 12
    slli    t0, t0, 10
    ori     t0, t0, 0x1ff
    csrw    pmpaddr0, t0
    li      t0, 0x80000000
    srli    t0, t0, 2
    csrw    pmpaddr1, t0
    li      t0, 0x80400000
    srli    t0, t0, 2
    csrw    pmpaddr2, t0
    li      t0, 0xf009f
    csrw    pmpcfg0, t0
    li      t1, 0x804edc42
    la      t0, lr_w_probe
    csrw    mepc, t0
    li      t0, 0x1800
    csrw    mstatus, t0
    mret
lr_w_probe:
    lr.w    t2, (t1)
1:
    j       1b

lr_d_probe:
    lr.d    t2, (t1)
2:
    j       2b

trap_handler:
    csrr    t0, mcause
    li      t1, 4
    bne     t0, t1, failure
    csrr    t0, mepc
    la      t1, lr_w_probe
    beq     t0, t1, check_lr_w
    la      t1, lr_d_probe
    bne     t0, t1, failure
    csrr    t0, mtval
    li      t1, 0x804edc44
    bne     t0, t1, failure
    j       check_status

check_lr_w:
    csrr    t0, mtval
    li      t1, 0x804edc42
    bne     t0, t1, failure
    li      t1, 0x804edc44
    la      t0, lr_d_probe
    csrw    mepc, t0
    mret

check_status:
    csrr    t0, mstatus
    li      t1, 0x1800
    and     t0, t0, t1
    bne     t0, t1, failure
    li      t0, 1
    la      t1, tohost
    sd      t0, 0(t1)
4:
    j       4b

failure:
    li      t0, 3
    la      t1, tohost
    sd      t0, 0(t1)
5:
    j       5b

.section .tohost,"aw",@progbits
.align 6
.globl tohost
.globl fromhost
tohost:
    .dword 0
fromhost:
    .dword 0

