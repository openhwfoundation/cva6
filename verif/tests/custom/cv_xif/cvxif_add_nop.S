# See LICENSE for license details.

#*****************************************************************************
# Copyright 2022 Thales DIS design services SAS
#
# Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
# You may obtain a copy of the License at https:#solderpad.org/licenses/
#
#----------------------------------------------------------------------------------

#include "cvxif_macros.h"

  #-------------------------------------------------------------
  # Custom tests
  #-------------------------------------------------------------

  .globl main
main:

# core of the test

start0:
    li a0, 0x332211
    li a1, 0xDEADBEEF
    li a2, 0xDEADBEEF
    cus_nop
    cus_add a0, a0, a1
    cus_add a1, a0, a1
    cus_add a0, a1, a1
    lw a0, num1;
    cus_add a2, a0, a1
    lw a1, num2;
    cus_add a0, a1, zero

# Take branch to check for instruction kill
    li a0, 0xCAFE;
    li a1, 0xCAFE;
    xor a2, a0, a1;
    beqz a2, branch2;

branch1:
    cus_add zero, zero, a1
    cus_nop
    cus_nop

branch2:
    cus_add a0, a0, a1
    lw a0, num1;
    cus_add a2, a0, a1
    lw a1, num2;
    cus_add a0, a1, zero

# (example of) final self-check test
  li a0, 0xCAFE;
  li a1, 0xCAFE;
  xor a2, a0, a1;
  beqz a2, pass;

fail:
  # Failure post-processing (messages, ecall setup etc.)
  li a0, 0x0;
  jal exit;

pass:
  # Success post-processing (messages, ecall setup etc.)
  li a0, 0x0;
  jal exit;

.data
    num1:   .word 5      // First number
    num2:   .word 7      // Second number
    result: .word 12      // Result
