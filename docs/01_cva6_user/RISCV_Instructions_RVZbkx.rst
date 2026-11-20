.. Licensed under the Solderpad Hardware Licence, Version 2.1 (the "License");
.. you may not use this file except in compliance with the License.
.. SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
.. You may obtain a copy of the License at https://solderpad.org/licenses/

.. Author: Munail Waqar, 10xEngineers
.. Date: 03.05.2025
..
   Copyright (c) 2023 OpenHW Group
   Copyright (c) 2023 10xEngineers

   SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

.. Level 1
   =======

   Level 2
   -------

   Level 3
   ~~~~~~~

   Level 4
   ^^^^^^^

.. _cva6_riscv_instructions_RV32Zbkx:

*Applicability of this chapter to configurations:*

.. csv-table::
   :widths: auto
   :align: left
   :header: "Configuration", "Implementation"

   "CV32A60AX", "Implemented extension"
   "CV64A6_MMU", "Implemented extension"

=========================================
RVZbkx: Crossbar permutation instructions
=========================================

The following instructions comprise the Zbkx extension:

Xperm instructions
--------------------
The xperm instructions perform permutation operations on a register. They use indices extracted from rs2 to select data chunks (bytes for xperm8 or nibbles for xperm4) from rs1. The selected data is then placed into the destination register (rd) at positions corresponding to the extracted indices in rs2. If an index in rs2 is out of range, the corresponding chunk in rd is set to 0.

+-----------+-----------+-----------------------+
| RV32      | RV64      | Mnemonic              |
+===========+===========+=======================+
| ✔         | ✔         | xperm8 rd, rs1, rs2   |
+-----------+-----------+-----------------------+
| ✔         | ✔         | xperm4 rd, rs1, rs2   |
+-----------+-----------+-----------------------+


RV32 and RV64 Instructions
~~~~~~~~~~~~~~~~~~~~~~~~~~


- **XPERM8**: Crossbar permutation (bytes)

    **Format**: xperm8 rd, rs1, rs2

    **Description**: The xperm8 instruction operates on bytes. The rs1 register contains a vector of XLEN/8 8-bit elements. The rs2 register contains a vector of XLEN/8 8-bit indexes. The result is each element in rs2 replaced by the indexed element in rs1, or zero if the index into rs2 is out of bounds.

    **Pseudocode**: foreach (i from 0 to xlen by 8) {
                        if (rs2[i*8+:8]<(xlen/8))
                            X(rd)[i*8+:8] = rs1[rs2[i*8+:8]*8+:8];
                        else
                            X(rd)[i*8+:8] = 8'b0;
                    }

    **Invalid values**: NONE

    **Exception raised**: NONE

- **XPERM4**: Crossbar permutation (nibbles)

    **Format**: xperm4 rd, rs1, rs2 

    **Description**: The xperm4 instruction operates on nibbles. The rs1 register contains a vector of XLEN/4 4-bit elements. The rs2 register contains a vector of XLEN/4 4-bit indexes. The result is each element in rs2 replaced by the indexed element in rs1, or zero if the index into rs2 is out of bounds.

    **Pseudocode**: foreach (i from 0 to xlen by 4) {
                        if (rs2[i*4+:4]<(xlen/4))
                            X(rd)[i*4+:4] = rs1[rs2[i*4+:4]*4+:4];
                        else
                            X(rd)[i*4+:4] = 4'b0;
                    }

    **Invalid values**: NONE

    **Exception raised**: NONE
