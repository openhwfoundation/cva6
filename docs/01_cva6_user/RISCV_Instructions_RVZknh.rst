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

.. _cva6_riscv_instructions_RV32Zknh:

*Applicability of this chapter to configurations:*

.. csv-table::
   :widths: auto
   :align: left
   :header: "Configuration", "Implementation"

   "CV32A60AX", "Implemented extension"
   "CV64A6_MMU", "Implemented extension"

==============================================
RVZknh: NIST Suite: Hash Function Instructions
==============================================

The following instructions comprise the Zknh extension:

Hash Function instructions
--------------------------
The Hash Function instructions (Zknh) provide acceleration for the SHA2 family of cryptographic hash functions.

+-----------+-----------+----------------------------+
| RV32      | RV64      | Mnemonic                   |
+===========+===========+============================+
| ✔         | ✔         | sha256sig0 rd, rs1         |
+-----------+-----------+----------------------------+
| ✔         | ✔         | sha256sig1 rd, rs1         |
+-----------+-----------+----------------------------+
| ✔         | ✔         | sha256sum0 rd, rs1         |
+-----------+-----------+----------------------------+
| ✔         | ✔         | sha256sum1 rd, rs1         |
+-----------+-----------+----------------------------+
| ✔         |           | sha512sig0h rd, rs1, rs2   |
+-----------+-----------+----------------------------+
| ✔         |           | sha512sig0l rd, rs1, rs2   |
+-----------+-----------+----------------------------+
| ✔         |           | sha512sig1h rd, rs1, rs2   |
+-----------+-----------+----------------------------+
| ✔         |           | sha512sig1l rd, rs1, rs2   |
+-----------+-----------+----------------------------+
| ✔         |           | sha512sum0r rd, rs1, rs2   |
+-----------+-----------+----------------------------+
| ✔         |           | sha512sum1r rd, rs1, rs2   |
+-----------+-----------+----------------------------+
|           | ✔         | sha512sig0 rd, rs1         |
+-----------+-----------+----------------------------+
|           | ✔         | sha512sig1 rd, rs1         |
+-----------+-----------+----------------------------+
|           | ✔         | sha512sum0 rd, rs1         |
+-----------+-----------+----------------------------+
|           | ✔         | sha512sum1 rd, rs1         |
+-----------+-----------+----------------------------+


RV32 and RV64 Instructions
~~~~~~~~~~~~~~~~~~~~~~~~~~

- **SHA256SIG0**: SHA2-256 Sigma0 instruction

    **Format**: sha256sig0 rd, rs1

    **Description**: Implements the Sigma0 transformation function as used in the SHA2-256 hash function. For RV32, the entire XLEN source register is operated on. For RV64, the low 32 bits of the source register are operated on, and the result sign extended to XLEN bits.

    **Pseudocode**: X(rd) = EXTS(ror32(X(rs1)[31..0], 7) ^ ror32(X(rs1)[31..0], 18) ^ (X(rs1)[31..0] >> 3));

    **Invalid values**: NONE

    **Exception raised**: NONE


- **SHA256SIG1**: SHA2-256 Sigma1 instruction

    **Format**: sha256sig1 rd, rs1

    **Description**: Implements the Sigma1 transformation function as used in the SHA2-256 hash function. For RV32, the entire XLEN source register is operated on. For RV64, the low 32 bits of the source register are operated on, and the result sign extended to XLEN bits.

    **Pseudocode**: X(rd) = EXTS(ror32(X(rs1)[31..0], 17) ^ ror32(X(rs1)[31..0], 19) ^ (X(rs1)[31..0] >> 10));

    **Invalid values**: NONE

    **Exception raised**: NONE


- **SHA256SUM0**: SHA2-256 Sum0 instruction

    **Format**: sha256sum0 rd, rs1

    **Description**: Implements the Sum0 transformation function as used in the SHA2-256 hash function. For RV32, the entire XLEN source register is operated on. For RV64, the low 32 bits of the source register are operated on, and the result sign extended to XLEN bits.

    **Pseudocode**: X(rd) = EXTS(ror32(X(rs1)[31..0], 2) ^ ror32(X(rs1)[31..0], 13) ^ ror32(X(rs1)[31..0] >> 22));

    **Invalid values**: NONE

    **Exception raised**: NONE


- **SHA256SUM1**: SHA2-256 Sum1 instruction

    **Format**: sha256sum1 rd, rs1

    **Description**: Implements the Sum1 transformation function as used in the SHA2-256 hash function. For RV32, the entire XLEN source register is operated on. For RV64, the low 32 bits of the source register are operated on, and the result sign extended to XLEN bits.

    **Pseudocode**: X(rd) = EXTS(ror32(X(rs1)[31..0], 6) ^ ror32(X(rs1)[31..0], 11) ^ ror32(X(rs1)[31..0] >> 25));

    **Invalid values**: NONE

    **Exception raised**: NONE



RV32 specific instructions
~~~~~~~~~~~~~~~~~~~~~~~~~~	

- **SHA512SIG0H**: SHA2-512 Sigma0 high (RV32)

    **Format**: sha512sig0h rd, rs1, rs2

    **Description**: Implements the high half of the Sigma0 transformation, as used in the SHA2-512 hash function. Used to compute the Sigma0 transform of the SHA2-512 hash function in conjunction with the sha512sig0l instruction. The transform is a 64-bit to 64-bit function, so the input and output are each represented by two 32-bit registers.

    **Pseudocode**: X(rd) = EXTS((X(rs1) >> 1) ^ (X(rs1) >> 7) ^ (X(rs1) >> 8) ^ (X(rs2) << 31) ^ (X(rs2) << 24));

    **Invalid values**: NONE

    **Exception raised**: NONE

- **SHA512SIG0L**: SHA2-512 Sigma0 low (RV32)

    **Format**: sha512sig0l rd, rs1, rs2

    **Description**: Implements the low half of the Sigma0 transformation, as used in the SHA2-512 hash function. Used to compute the Sigma0 transform of the SHA2-512 hash function in conjunction with the sha512sig0h instruction. The transform is a 64-bit to 64-bit function, so the input and output are each represented by two 32-bit registers.

    **Pseudocode**: X(rd) = EXTS((X(rs1) >> 1) ^ (X(rs1) >> 7) ^ (X(rs1) >> 8) ^ (X(rs2) << 31) ^ (X(rs2) << 25) ^ (X(rs2) << 24));

    **Invalid values**: NONE

    **Exception raised**: NONE

- **SHA512SIG1H**: SHA2-512 Sigma1 high (RV32)

    **Format**: sha512sig1h rd, rs1, rs2

    **Description**: Implements the high half of the Sigma1 transformation, as used in the SHA2-512 hash function. Used to compute the Sigma1 transform of the SHA2-512 hash function in conjunction with the sha512sig1l instruction. The transform is a 64-bit to 64-bit function, so the input and output are each represented by two 32-bit registers.

    **Pseudocode**: X(rd) = EXTS((X(rs1) << 3) ^ (X(rs1) >> 6) ^ (X(rs1) >> 19) ^ (X(rs2) >> 29) ^ (X(rs2) << 13));

    **Invalid values**: NONE

    **Exception raised**: NONE

- **SHA512SIG1L**: SHA2-512 Sigma1 low (RV32)

    **Format**: sha512sig1l rd, rs1, rs2

    **Description**: Implements the low half of the Sigma1 transformation, as used in the SHA2-512 hash function. Used to compute the Sigma1 transform of the SHA2-512 hash function in conjunction with the sha512sig0h instruction. The transform is a 64-bit to 64-bit function, so the input and output are each represented by two 32-bit registers.

    **Pseudocode**: X(rd) = EXTS((X(rs1) << 3) ^ (X(rs1) >> 6) ^ (X(rs1) >> 19) ^ (X(rs2) >> 29) ^ (X(rs2) << 26) ^ (X(rs2) << 13));

    **Invalid values**: NONE

    **Exception raised**: NONE

- **SHA512SUM0R**: SHA2-512 Sum0 (RV32)

    **Format**: sha512sum0r rd, rs1, rs2

    **Description**: Implements the Sum0 transformation, as used in the SHA2-512 hash function. The transform is a 64-bit to 64-bit function, so the input and output are each represented by two 32-bit registers.

    **Pseudocode**: X(rd) = EXTS((X(rs1) << 25) ^ (X(rs1) << 30) ^ (X(rs1) >> 28) ^ (X(rs2) >> 7) ^ (X(rs2) >> 2) ^ (X(rs2) << 4));

    **Invalid values**: NONE

    **Exception raised**: NONE

- **SHA512SUM1R**: SHA2-512 Sum1 (RV32)

    **Format**: sha512sum1r rd, rs1, rs2

    **Description**: Implements the Sum1 transformation, as used in the SHA2-512 hash function. The transform is a 64-bit to 64-bit function, so the input and output are each represented by two 32-bit registers.

    **Pseudocode**: X(rd) = EXTS((X(rs1) << 23) ^ (X(rs1) >> 14) ^ (X(rs1) >> 18) ^ (X(rs2) >> 9) ^ (X(rs2) << 18) ^ (X(rs2) << 14));

    **Invalid values**: NONE

    **Exception raised**: NONE



RV64 specific Instructions
~~~~~~~~~~~~~~~~~~~~~~~~~~

- **SHA512SIG0**: SHA2-512 Sigma0 instruction (RV64)

    **Format**: sha512sig0 rd, rs1

    **Description**: Implements the Sigma0 transformation function as used in the SHA2-512 hash function.

    **Pseudocode**: X(rd) = ror64(X(rs1), 1) ^ ror64(X(rs1), 8) ^ (X(rs1) >> 7);

    **Invalid values**: NONE

    **Exception raised**: NONE

- **SHA512SIG1**: SHA2-512 Sigma1 instruction (RV64)

    **Format**: sha512sig1 rd, rs1

    **Description**: Implements the Sigma1 transformation function as used in the SHA2-512 hash function.

    **Pseudocode**: X(rd) = ror64(X(rs1), 19) ^ ror64(X(rs1), 61) ^ (X(rs1) >> 6);

    **Invalid values**: NONE

    **Exception raised**: NONE

- **SHA512SUM0**: SHA2-512 Sum0 instruction (RV64)

    **Format**: sha512sum0 rd, rs1

    **Description**: Implements the Sum0 transformation function as used in the SHA2-512 hash function.

    **Pseudocode**: X(rd) = ror64(X(rs1), 28) ^ ror64(X(rs1), 34) ^ ror64(X(rs1) ,39);

    **Invalid values**: NONE

    **Exception raised**: NONE

- **SHA512SUM1**: SHA2-512 Sum1 instruction (RV64)

    **Format**: sha512sum1 rd, rs1

    **Description**: Implements the Sum1 transformation function as used in the SHA2-512 hash function.

    **Pseudocode**: X(rd) = ror64(X(rs1), 14) ^ ror64(X(rs1), 18) ^ ror64(X(rs1) ,41);

    **Invalid values**: NONE

    **Exception raised**: NONE
