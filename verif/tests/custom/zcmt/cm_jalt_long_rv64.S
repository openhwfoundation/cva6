#include "riscv_test.h"

RVTEST_RV64M
RVTEST_CODE_BEGIN

    la t0, trap_handler
    csrw mtvec, t0

    la a1, target1
    la t0, __jvt_base$

    sd a1, 512(t0)       // cm.jalt entry start from index >=32

    csrw jvt, t0

    fence.i
    //Perform jump using the index from JVT
    cm.jalt 64

    li t1, 1
    addi x20, x20, 9
    j failure

target1:
    li x2, 99
    j success

trap_handler:
    j failure

// jump to this label to signal that the test failed
failure:
    li x1, 1
	slli x1, x1, 1
	addi x1, x1, 1
	sw x1, tohost, t5
	self_loop_2: j self_loop_2

// jump to this label to signal that the test passed
success:
    li x1, 0
	slli x1, x1, 1
	addi x1, x1, 1
	sw x1, tohost, t5
	self_loop: j self_loop


RVTEST_CODE_END

.data
RVTEST_DATA_BEGIN
    // Jump Vector Table (JVT)
    .align 6
__jvt_base$:
    .space 512              //Reserve space for indices 0-63 (unused)
    .dword 0                //Entry 64 (will be overwritten by test)
RVTEST_DATA_END