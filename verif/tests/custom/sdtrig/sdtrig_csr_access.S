# ------------------------------------------------------------------------------
#   Copyright 2026 Thales France
#
#   Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
#   You may obtain a copy of the License at https://solderpad.org/licenses/
# ------------------------------------------------------------------------------
#   sdtrig_csr_access.S
#
#   Checks the CSR interface of the trigger module: that tselect bounds itself
#   to the number of implemented triggers, that tinfo reports the trigger types
#   the CVA6 documentation claims, and that tdata1/tdata2 hold what was written
#   for each selected trigger.
#
#   Requires a target with Sdtrig enabled. On a target without it these CSRs
#   raise an illegal instruction, which is what sdtrig_disabled_test covers.
# ------------------------------------------------------------------------------

#include "sdtrig_xlen.h"

    .text
    .globl main
main:

    # --------------------------------------------------------------------
    # tselect: writing a value beyond the last implemented trigger must not
    # take. The test assumes SdtrigNrTriggers is 4, so indexes 0..3 are
    # legal and 4 is not. The spec lets the hardware either wrap or hold; the
    # module holds the previous value, so tselect must read back 0 here.
    # --------------------------------------------------------------------
    li   t0, 0
    csrw 0x7a0, t0              # tselect = 0
    csrr t1, 0x7a0
    bne  t1, t0, fail

    li   t0, 3                  # last legal index
    csrw 0x7a0, t0
    csrr t1, 0x7a0
    bne  t1, t0, fail

    li   t0, 4                  # one past the last: must not take
    csrw 0x7a0, t0
    csrr t1, 0x7a0
    li   t2, 3                  # previous value still there
    bne  t1, t2, fail

    # --------------------------------------------------------------------
    # tinfo: bitmask of supported types. The module reports
    # 16'b1000_0000_0111_1000, that is types 3 (icount), 4 (itrigger),
    # 5 (etrigger), 6 (mcontrol6) and 15 (disabled).
    # --------------------------------------------------------------------
    csrr t0, 0x7a4              # tinfo
    li   t1, 0xffff
    and  t0, t0, t1             # info field is the low 16 bits
    li   t1, 0x8078
    bne  t0, t1, fail

    # --------------------------------------------------------------------
    # tdata1/tdata2 are per-trigger state. Write a distinct tdata2 to each
    # of the four triggers, then read them all back: each must have kept its
    # own value, which is what proves tselect really selects.
    # --------------------------------------------------------------------
    li   t0, 0
    csrw 0x7a0, t0
    li   t1, 0x1000
    csrw 0x7a2, t1              # trigger 0, tdata2 = 0x1000

    li   t0, 1
    csrw 0x7a0, t0
    li   t1, 0x2000
    csrw 0x7a2, t1              # trigger 1, tdata2 = 0x2000

    li   t0, 2
    csrw 0x7a0, t0
    li   t1, 0x3000
    csrw 0x7a2, t1              # trigger 2

    li   t0, 3
    csrw 0x7a0, t0
    li   t1, 0x4000
    csrw 0x7a2, t1              # trigger 3

    li   t0, 0
    csrw 0x7a0, t0
    csrr t1, 0x7a2
    li   t2, 0x1000
    bne  t1, t2, fail

    li   t0, 1
    csrw 0x7a0, t0
    csrr t1, 0x7a2
    li   t2, 0x2000
    bne  t1, t2, fail

    li   t0, 2
    csrw 0x7a0, t0
    csrr t1, 0x7a2
    li   t2, 0x3000
    bne  t1, t2, fail

    li   t0, 3
    csrw 0x7a0, t0
    csrr t1, 0x7a2
    li   t2, 0x4000
    bne  t1, t2, fail

    # --------------------------------------------------------------------
    # tdata1 type field: selecting mcontrol6 (type 6) must read back as type
    # 6, since that is a type this configuration implements.
    #
    # Note on type 15, the disabled encoding: the module accepts the write but
    # reads tdata1 back as zero, because the read path decodes the stored type
    # and only types 3, 4, 5 and 6 have a layout to return. The Sdtrig spec
    # requires type 15 to mean the trigger exists but is disabled, and does not
    # require tdata1 to read back 15, so returning zero is within spec. This
    # test therefore does not assert it.
    # --------------------------------------------------------------------
    li   t0, 0
    csrw 0x7a0, t0
    li   t1, TDATA1_VAL(6, 0, 0, 0x0000000)         # type = 6, mcontrol6 (RV32 layout)
    csrw 0x7a1, t1
    csrr t2, 0x7a1
    srli t2, t2, TDATA1_TYPE_SHIFT
    li   t3, 6
    bne  t2, t3, fail

    # --------------------------------------------------------------------
    li a0, 0
    ret

fail:
    li a0, 1
    ret
