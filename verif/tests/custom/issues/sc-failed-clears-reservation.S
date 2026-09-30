// Copyright 2026 OpenHW Group
//
// Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0

    .section .text
    .globl main

main:
    // Establish a reservation on address A.
    la      t0, address_a
    lr.d    t1, (t0)

    // An SC to a different address must fail because the reservation is for A.
    la      t2, address_b
    li      t3, 1
    sc.d    t4, t3, (t2)
    beqz    t4, fail

    // A failed SC must clear the hart reservation.
    // Therefore this SC to the original address A must also fail.
    sc.d    t4, t3, (t0)
    beqz    t4, fail

pass:
    li      a0, 0
    tail    exit

fail:
    li      a0, 1
    tail    exit

    .section .data, "aw", @progbits
    .align 3
address_a:
    .dword 0
address_b:
    .dword 0
