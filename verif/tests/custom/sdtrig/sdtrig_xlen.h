// ------------------------------------------------------------------------------
//   Copyright 2026 Thales France
//
//   Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
//   you may not use this file except in compliance with the License.
//   SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
//   You may obtain a copy of the License at https://solderpad.org/licenses/
// ------------------------------------------------------------------------------
//   sdtrig_xlen.h
//
//   tdata1 values for RV32 and RV64. The type, dmode and hit fields sit at the
//   top of tdata1: [31:28], [27] and [26] on RV32, [63:60], [59] and [58] on
//   RV64. The fields below are at the same position on both.
//
//   TDATA1_VAL(type, dmode, hit, low) gives the value; low holds bits [25:0].
//   LREG/SREG, REGBYTES and PTRWORD store an address (mepc, tdata1) at full
//   register width.
// ------------------------------------------------------------------------------

#ifndef SDTRIG_XLEN_H
#define SDTRIG_XLEN_H

#if __riscv_xlen == 64
#define TDATA1_TYPE_SHIFT 60
#define TDATA1_VAL(type, dmode, hit, low) \
  (((type) << 60) | ((dmode) << 59) | ((hit) << 58) | (low))
#define LREG ld
#define SREG sd
#define REGBYTES 8
#define PTRWORD .dword
#else
#define TDATA1_TYPE_SHIFT 28
#define TDATA1_VAL(type, dmode, hit, low) \
  (((type) << 28) | ((dmode) << 27) | ((hit) << 26) | (low))
#define LREG lw
#define SREG sw
#define REGBYTES 4
#define PTRWORD .word
#endif

#endif
