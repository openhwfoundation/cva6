# ------------------------------------------------------------------------------
#   Copyright 2026 Thales France
#
#   Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
#   You may obtain a copy of the License at https://solderpad.org/licenses/
# ------------------------------------------------------------------------------
#   cm_jt_upper_target_rv64.S
#
#   cm.jt reads a 64-bit jump table entry on RV64. The entry holds a target
#   whose upper 32 bits are not the sign extension of the lower ones
#   (0x0000_0002_0000_0000, more than 2 GiB from the code): a core keeping only
#   32 bits of the entry, or of the offset to the target, jumps elsewhere. Nothing
#   is mapped there, so the jump must raise an instruction access fault, with
#   mepc and mtval at the full 64-bit target.
# ------------------------------------------------------------------------------

#include "riscv_test.h"

#define TARGET 0x0000000200000000

RVTEST_RV64M
RVTEST_CODE_BEGIN

    la t0, trap_handler
    csrw mtvec, t0

    la t0, __jvt_base$
    csrw jvt, t0
    fence.i

    cm.jt 0

    j failure

    .align 2
trap_handler:
    csrr t0, mcause
    li t1, CAUSE_FETCH_ACCESS
    bne t0, t1, failure
    csrr t0, mepc
    li t1, TARGET
    bne t0, t1, failure
    j success

failure:
    li x1, 3
    sw x1, tohost, t5
    self_loop_2: j self_loop_2

success:
    li x1, 1
    sw x1, tohost, t5
    self_loop: j self_loop

RVTEST_CODE_END

.data
RVTEST_DATA_BEGIN
    .align 6
__jvt_base$:
    .dword TARGET
RVTEST_DATA_END
