#include "riscv_test.h"

RVTEST_RV64M
RVTEST_CODE_BEGIN

	la t0, trap_handler
	csrw mtvec, t0

    la a1, target1
    la t0, __jvt_base$

    sd a1, 0(t0)

    csrw  jvt, t0

    fence.i

    cm.jt 0                 # Perform jump using the index 0 from JVT

    addi x18,x18, 3
    j failure

target1:
    addi x6,x0, 6 
    j success
                

trap_handler:
    la     t0, failure             # Load address of 'failure' (PC-relative, RV32/RV64 safe)
    jalr   x0, 0(t0)

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

// Jump Vector Table (JVT) Section
.section .riscv.jvt, "ax"
.align 6
__jvt_base$:
    .dword 0x80000054
    .dword 0x80000800
    .dword 0x80000802
    .dword 0x80000804


RVTEST_DATA_END