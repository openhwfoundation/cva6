  .section  .text
  .align    2
  .option   norvc
  .globl    main

main:
  la    t0, trap_handler
  csrw  mtvec, t0
  csrw  medeleg, zero

  li    t0, -1
  csrw  pmpaddr0, t0
  li    t0, 0x1f
  csrw  pmpcfg0, t0

  li    t0, 0x1800
  csrc  mstatus, t0
  li    t0, 0x800
  csrs  mstatus, t0
  li    t0, 1
  slli  t0, t0, 39
  csrs  mstatus, t0

  li    s1, 0
  la    t0, test
  csrw  mepc, t0
  mret

test:
  .word 0x220000f3  # hfence.vvma (rd = 1)
  .word 0x620000f3  # hfence.gvma (rd = 1)

  hfence.vvma       # well formed hfence
  hfence.gvma

  xori  a0, s1, 4
  snez  a0, a0
  j     finish

  .align 2
trap_handler:
  csrr  t0, mcause

  addi  s1, s1, 1
  csrr  t0, mepc
  addi  t0, t0, 4
  csrw  mepc, t0
  mret

finish:
  jal exit

