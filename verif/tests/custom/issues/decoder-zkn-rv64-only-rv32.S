# SUCCESS(a0=0) iff every RV64-only Zkn encoding (aes64es/esm/ds/dsm/ks2,
# aes64ks1i, aes64im, sha512sig0/1, sha512sum0/1) traps with mcause==2 on RV32,
# and the RV32 forms (aes32esi, sha512sum0r, sha256sum0, rev8) still retire.
# a0 = n (1..11): encoding n retired (bug); a0 = 0x40|mcause: wrong cause;
# a0 = 12: an RV32 control trapped.
  .section .text
  .align 2
  .option norvc
  .globl main
main:
  la t0, th
  csrw mtvec, t0
  # each trapping encoding is followed by "li a0, n; j fin" (8 bytes), which the
  # handler steps over when the encoding traps with mcause==2
  .word 0x327302b3          # aes64es     x5, x6, x7
  li a0, 1
  j fin
  .word 0x367302b3          # aes64esm    x5, x6, x7
  li a0, 2
  j fin
  .word 0x3a7302b3          # aes64ds     x5, x6, x7
  li a0, 3
  j fin
  .word 0x3e7302b3          # aes64dsm    x5, x6, x7
  li a0, 4
  j fin
  .word 0x7e7302b3          # aes64ks2    x5, x6, x7
  li a0, 5
  j fin
  .word 0x31031293          # aes64ks1i   x5, x6, 0
  li a0, 6
  j fin
  .word 0x30031293          # aes64im     x5, x6
  li a0, 7
  j fin
  .word 0x10631293          # sha512sig0  x5, x6
  li a0, 8
  j fin
  .word 0x10731293          # sha512sig1  x5, x6
  li a0, 9
  j fin
  .word 0x10431293          # sha512sum0  x5, x6
  li a0, 10
  j fin
  .word 0x10531293          # sha512sum1  x5, x6
  li a0, 11
  j fin
  # RV32 controls: each must retire; a trap would step over its "addi s2; nop"
  li s2, 0
  .word 0x227302b3          # aes32esi    x5, x6, x7, 0
  addi s2, s2, 1
  nop
  .word 0x507302b3          # sha512sum0r x5, x6, x7
  addi s2, s2, 1
  nop
  .word 0x10031293          # sha256sum0  x5, x6
  addi s2, s2, 1
  nop
  .word 0x69835293          # rev8 x5, x6 (RV32 encoding, imm 0x698)
  addi s2, s2, 1
  nop
  li t1, 4
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
