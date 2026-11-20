#include "riscv_test.h"

RVTEST_RV32M
RVTEST_CODE_BEGIN

    la t0, trap_handler
    csrw mtvec, t0

    la a1, target1
    la t0, __jvt_base$

    sw a1, 256(t0)       // cm.jalt entry start from index >=32

    csrw jvt, t0

    fence.i
    cm.jalt 64

    li t1, 1
    addi x20, x20, 9
    j success


// trap handler
trap_handler:
    la     t0, failure             # Load address of 'failure' (PC-relative, RV32/RV64 safe)
    jalr   x0, 0(t0)

// cm.jalt target label
target1:
    li x2, 99
    ret


// failure path
failure:
    li x1, 1
    slli x1, x1, 1
    addi x1, x1, 1
    sw x1, tohost, t5
    self_loop_2: j self_loop_2

// success path
success:
    li x1, 0
    slli x1, x1, 1
    addi x1, x1, 1
    sw x1, tohost, t5
    self_loop: j self_loop

RVTEST_CODE_END

.data
RVTEST_DATA_BEGIN

    .align 6
__jvt_base$:
    .space 256              //Reserve space for indices 0-63 (unused)
    .word 0                 //Entry 64 (will be overwritten by test)
RVTEST_DATA_END