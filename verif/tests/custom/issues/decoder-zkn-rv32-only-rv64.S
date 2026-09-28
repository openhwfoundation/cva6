# SUCCESS(a0=0) iff every RV32-only Zkn encoding (aes32*, sha512sig0h/0l/1h/1l,
# sha512sum0r/1r) and the RV32 rev8 encoding trap with mcause==2 on RV64, and the
# RV64 forms (aes64es/esm, sha512sum0, sha512sig0, rev8) still retire.
# a0 = n (1..11): encoding n retired (bug); a0 = 0x40|mcause: wrong cause;
# a0 = 12: an RV64 control trapped.
  .section .text
  .align 2
  .option norvc
  .globl main
main:
  la t0, th
  csrw mtvec, t0
  csrw medeleg, zero
  # each trapping encoding is followed by "li a0, n; j fin" (8 bytes), which the
  # handler steps over when the encoding traps with mcause==2
  .word 0x227302b3          # aes32esi    x5, x6, x7, 0
  li a0, 1
  j fin
  .word 0x267302b3          # aes32esmi   x5, x6, x7, 0
  li a0, 2
  j fin
  .word 0x2a7302b3          # aes32dsi    x5, x6, x7, 0
  li a0, 3
  j fin
  .word 0x2e7302b3          # aes32dsmi   x5, x6, x7, 0
  li a0, 4
  j fin
  .word 0x507302b3          # sha512sum0r x5, x6, x7
  li a0, 5
  j fin
  .word 0x527302b3          # sha512sum1r x5, x6, x7
  li a0, 6
  j fin
  .word 0x547302b3          # sha512sig0l x5, x6, x7
  li a0, 7
  j fin
  .word 0x5c7302b3          # sha512sig0h x5, x6, x7
  li a0, 8
  j fin
  .word 0x567302b3          # sha512sig1l x5, x6, x7
  li a0, 9
  j fin
  .word 0x5e7302b3          # sha512sig1h x5, x6, x7
  li a0, 10
  j fin
  .word 0x69835293          # rev8 x5, x6 (RV32 encoding, imm 0x698)
  li a0, 11
  j fin
  # RV64 controls: each must retire; a trap would step over its "addi s2; nop"
  li s2, 0
  .word 0x327302b3          # aes64es     x5, x6, x7
  addi s2, s2, 1
  nop
  .word 0x367302b3          # aes64esm    x5, x6, x7
  addi s2, s2, 1
  nop
  .word 0x10431293          # sha512sum0  x5, x6
  addi s2, s2, 1
  nop
  .word 0x10631293          # sha512sig0  x5, x6
  addi s2, s2, 1
  nop
  .word 0x6b835293          # rev8 x5, x6 (RV64 encoding, imm 0x6b8)
  addi s2, s2, 1
  nop
  li t1, 5
  li a0, 12
  bne s2, t1, fin
  li a0, 0
  j fin
  .align 2
th:
  csrr t0, mcause
  li t1, 2
  bne t0, t1, wc
  csrr t0, mepc
  addi t0, t0, 12
  csrw mepc, t0
  mret
wc:
  ori a0, t0, 0x40
fin:
  jal exit
