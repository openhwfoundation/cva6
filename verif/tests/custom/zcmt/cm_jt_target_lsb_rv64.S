.globl _start
_start:
    la t0, trap_handler
    csrw mtvec, t0

    # Configure the Jump Vector Table.
    la t0, __jvt_base$

    # JVT CSR = 0x017.
    # Use the numeric CSR address so this test does not depend on
    # assembler support for the Zcmt CSR name.
    csrw 0x017, t0

    fence.i

    # JVT entry 0 contains cm_jt_target + 1. cm.jt must clear bit 0
    # before using the loaded value as the jump target.
    #
    # cm.jt 0 encoding = 0xa002
    .2byte 0xa002

    # cm.jt must not fall through.
    j fail

.balign 2
cm_jt_target:
    # Verify that the architectural PC has bit 0 cleared.
    auipc t1, 0
    andi t1, t1, 1
    bnez t1, fail

    j pass

.balign 4
trap_handler:
    j fail

pass:
    # RISC-V test convention: tohost = 1 means success.
    li x1, 1
    j write_tohost

fail:
    # An odd value greater than one represents failure.
    li x1, 3

write_tohost:
    la t0, tohost
    sw x1, 0(t0)

1:
    j 1b

.section .riscv.jvt, "ax"
.align 6
__jvt_base$:
    .dword cm_jt_target + 1

.section .data
.align 6
.global tohost
tohost:
    .dword 0

.align 6
.global fromhost
fromhost:
    .dword 0
