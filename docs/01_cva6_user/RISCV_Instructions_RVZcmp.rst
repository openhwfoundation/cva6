..
   Copyright (c) 2023 OpenHW Group
   Copyright (c) 2023 Thales

   SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

.. Level 1
   =======

   Level 2
   -------

   Level 3
   ~~~~~~~

   Level 4
   ^^^^^^^

.. _cva6_riscv_instructions_RVZcmp:

*Applicability of this chapter to configurations:*

.. csv-table::
   :widths: auto
   :align: left
   :header: "Configuration", "Implementation"

   "CV32A60X", "Implemented extension"
   "CV64A6_MMU", "Implemented extension"

**Note**: Zcmp is primarily targeted at embedded class CPUs due to implementation complexity. Additionally, it is not compatible with architecture class profiles.  

RVZcmp Code Size Reduction Instructions
---------------------------------------

Zcmp belongs to group of extensions called RISC-V Code Size Reduction Extension (Zc*). Zc* has become the superset of Standard C extension adding more 16-bit instructions to the ISA.
Zcmp includes 16-bit macro instructions, PUSH/POP and double move, which reuse the encoding for c.fsdsp instruction.
All the Zcmp instructions require at least C extension support with Zcd extension disabled as pre-requisite.

- **CM.PUSH**: Compressed Push

    **Format**: cm.push {reg_list}, -stack_adj

    **Description**: This instruction pushes (stores) the registers in reg_list to the memory below the stack pointer, and then creates the stack frame by decrementing the stack pointer by stack_adj, including any additional stack space requested by the value of spimm.

    **Pseudocode**::

        if (XLEN==32) bytes=4; else bytes=8;
        addr=sp-bytes;
        for(i in 27,26,25,24,23,22,21,20,19,18,9,8,1) {
            if (xreg_list[i]) {
                switch(bytes) {
                    4: asm("sw x[i], 0(addr)");
                    8: asm("sd x[i], 0(addr)");
                }
                addr-=bytes;
            }
        }
        sp-=stack_adj;

    **Invalid values**: reg_list not in [ {ra}, {ra, s0}, {ra, s0-s1}, {ra, s0-s2}, ..., {ra, s0-s8}, {ra, s0-s9}, {ra, s0-s11} ], stack_adj not in [ 16, 32, 48, 64, 80, 96, 112 ] and [ 16, 32, 48, 64, 80, 96, 112, 128, 144, 160 ] for RV32 and RV64 respectively.

    **Exception raised**: NONE

- **CM.POP**: Compressed Pop

    **Format**: cm.pop {reg_list}, stack_abj

    **Description**: Destroy stack frame: load ra and 0 to 12 saved registers from the stack frame, deallocate the stack frame.

    **Pseudocode**::

        if (XLEN==32) bytes=4; else bytes=8;
        addr=sp+stack_adj-bytes;
        for(i in 27,26,25,24,23,22,21,20,19,18,9,8,1) {
            if (xreg_list[i]) {
                switch(bytes) {
                    4: asm("lw x[i], 0(addr)");
                    8: asm("ld x[i], 0(addr)");
                }
                addr-=bytes;
            }
        }
        sp+=stack_adj;

    **Invalid values**: reg_list not in [ {ra}, {ra, s0}, {ra, s0-s1}, {ra, s0-s2}, ..., {ra, s0-s8}, {ra, s0-s9}, {ra, s0-s11} ], stack_adj not in [ 16, 32, 48, 64, 80, 96, 112 ] and [ 16, 32, 48, 64, 80, 96, 112, 128, 144, 160 ] for RV32 and RV64 respectively.

    **Exception raised**: NONE

- **CM.POPRETZ**: Compressed Pop return zero

    **Format**: cm.popretz {reg_list}, stack_adj

    **Description**: Destroy stack frame: load ra and 0 to 12 saved registers from the stack frame, deallocate the stack frame, move zero into a0, return to ra.

    **Pseudocode**::

        if (XLEN==32) bytes=4; else bytes=8;
        addr=sp+stack_adj-bytes;
        for(i in 27,26,25,24,23,22,21,20,19,18,9,8,1) {
            if (xreg_list[i]) {
                switch(bytes) {
                    4: asm("lw x[i], 0(addr)");
                    8: asm("ld x[i], 0(addr)");
                }
                addr-=bytes;
            }
        }
        asm("li a0, 0");
        sp+=stack_adj;
        asm("ret");

    **Invalid values**: reg_list not in [ {ra}, {ra, s0}, {ra, s0-s1}, {ra, s0-s2}, ..., {ra, s0-s8}, {ra, s0-s9}, {ra, s0-s11} ], stack_adj not in [ 16, 32, 48, 64, 80, 96, 112 ] and [ 16, 32, 48, 64, 80, 96, 112, 128, 144, 160 ] for RV32 and RV64 respectively.

    **Exception raised**: NONE

- **CM.POPRET**: Compressed Pop return

    **Format**: cm.popret {reg_list}, stack_adj

    **Description**: Destroy stack frame: load ra and 0 to 12 saved registers from the stack frame, deallocate the stack frame, return to ra.

    **Pseudocode**::

        if (XLEN==32) bytes=4; else bytes=8;
        addr=sp+stack_adj-bytes;
        for(i in 27,26,25,24,23,22,21,20,19,18,9,8,1) {
            if (xreg_list[i]) {
                switch(bytes) {
                    4: asm("lw x[i], 0(addr)");
                    8: asm("ld x[i], 0(addr)");
                }
                addr-=bytes;
            }
        }
        sp+=stack_adj;
        asm("ret");

    **Invalid values**: reg_list not in [ {ra}, {ra, s0}, {ra, s0-s1}, {ra, s0-s2}, ..., {ra, s0-s8}, {ra, s0-s9}, {ra, s0-s11} ], stack_adj not in [ 16, 32, 48, 64, 80, 96, 112 ] and [ 16, 32, 48, 64, 80, 96, 112, 128, 144, 160 ] for RV32 and RV64 respectively.

    **Exception raised**: NONE

- **CM.MVSA01**: Compressed move argument registers into save registers

    **Format**: cm.mvsa01 r1s', r2s'

    **Description**: This instruction moves a0 into r1s' and a1 into r2s'. r1s' and r2s' must be different. The execution is atomic, so it is not possible to observe state where only one of r1s' or r2s' has been updated.

    **Pseudocode**::

        if (RV32E && (r1sc>1 || r2sc>1)) {
            reserved();
        }
        xreg1 = {r1sc[2:1]>0,r1sc[2:1]==0,r1sc[2:0]};
        xreg2 = {r2sc[2:1]>0,r2sc[2:1]==0,r2sc[2:0]};
        X[xreg1] = X[10];
        X[xreg2] = X[11];

    **Invalid values**: r1s' = r2s'

    **Exception raised**: NONE

- **CM.MVA01S**: Compressed move save registers into argument registers

    **Format**: cm.mva01s r1s', r2s'

    **Description**: This instruction moves r1s' into a0 and r2s' into a1. The execution is atomic, so it is not possible to observe state where only one of a0 or a1 have been updated.

    **Pseudocode**::

        if (RV32E && (r1sc>1 || r2sc>1)) {
            reserved();
        }
        xreg1 = {r1sc[2:1]>0,r1sc[2:1]==0,r1sc[2:0]};
        xreg2 = {r2sc[2:1]>0,r2sc[2:1]==0,r2sc[2:0]};
        X[10] = X[xreg1];
        X[11] = X[xreg2];

    **Invalid values**: NONE

    **Exception raised**: NONE
