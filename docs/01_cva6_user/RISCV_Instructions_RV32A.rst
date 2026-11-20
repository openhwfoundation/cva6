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

.. _cva6_riscv_instructions_RV32A:

*Applicability of this chapter to configurations:*

.. csv-table::
   :widths: auto
   :align: left
   :header: "Configuration", "Implementation"

   "CV32A60AX", "Implemented extension"
   "CV32A60X", "Not implemented extension"
   "CV64A6_MMU", "Not implemented extension"

**Note**: This chapter is specific to CV32A6 configurations. CV64A6 configurations implement as an option RV64A, that includes additional instructions.
   

RV32A Atomic Instructions
--------------------------------

The standard atomic instruction extension is denoted by instruction subset name “A”, and contains instructions that atomically read-modify-write memory to support synchronization between
multiple RISC-V harts running in the same memory space. The two forms of atomic instruction
provided are load-reserved/store-conditional instructions and atomic fetch-and-op memory instructions. Both types of atomic instruction support various memory consistency orderings including
unordered, acquire, release, and sequentially consistent semantics.

Load-Reserved/Store-Conditional Instructions
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

- **LR.W**: Load-Reserved Word

    **Format**: lr.w rd, (rs1)

    **Description**: LR loads a word from the address in rs1, places the sign-extended value in rd, and registers a reservation on the memory address.

    **Pseudocode**: x[rd] = LoadReserved32(M[x[rs1]])

    **Invalid values**: NONE

    **Exception raised**: If the address is not naturally aligned (4-byte boundary), a Load/AMO address misaligned exception will be generated.

- **SC.W**: Store-Conditional Word

    **Format**: sc.w rd, rs2, (rs1)

    **Description**: SC writes a word in rs2 to the address in rs1, provided a valid reservation still exists on that address. SC writes zero to rd on success or a nonzero code on failure.

    **Pseudocode**: x[rd] = StoreConditional32(M[x[rs1]], x[rs2])

    **Invalid values**: NONE

    **Exception raised**: If the address is not naturally aligned (4-byte boundary), a Store/AMO address misaligned exception will be generated.

Atomic Memory Operations
^^^^^^^^^^^^^^^^^^^^^^^^^^

- **AMOADD.W**: Atomic Memory Operation: Add Word

    **Format**: amoadd.w rd, rs2, (rs1)

    **Description**: AMOADD.W atomically loads a data value from the address in rs1, places the value into register rd, then adds the loaded value and the original value in rs2, then stores the result back to the address in rs1.

    **Pseudocode**: x[rd] = AMO32(M[x[rs1]] + x[rs2])

    **Invalid values**: NONE

    **Exception raised**: If the address is not naturally aligned (4-byte boundary), a misaligned address exception will be generated.

- **AMOAND.W**: Atomic Memory Operation: And Word

    **Format**: amoand.w rd, rs2, (rs1)

    **Description**: AMOAND.W atomically loads a data value from the address in rs1, places the value into register rd, then performs an AND between the loaded value and the original value in rs2, then stores the result back to the address in rs1.

    **Pseudocode**: x[rd] = AMO32(M[x[rs1]] & x[rs2])

    **Invalid values**: NONE

    **Exception raised**: If the address is not naturally aligned (4-byte boundary), a misaligned address exception will be generated.

- **AMOOR.W**: Atomic Memory Operation: Or Word

    **Format**: amoor.w rd, rs2, (rs1)

    **Description**: AMOOR.W atomically loads a data value from the address in rs1, places the value into register rd, then performs an OR between the loaded value and the original value in rs2, then stores the result back to the address in rs1.

    **Pseudocode**: x[rd] = AMO32(M[x[rs1]] | x[rs2])

    **Invalid values**: NONE

    **Exception raised**: If the address is not naturally aligned (4-byte boundary), a misaligned address exception will be generated.

- **AMOXOR.W**: Atomic Memory Operation: Xor Word

    **Format**: amoxor.w rd, rs2, (rs1)

    **Description**: AMOXOR.W atomically loads a data value from the address in rs1, places the value into register rd, then performs a XOR between the loaded value and the original value in rs2, then stores the result back to the address in rs1.

    **Pseudocode**: x[rd] = AMO32(M[x[rs1]] ^ x[rs2])

    **Invalid values**: NONE

    **Exception raised**: If the address is not naturally aligned (4-byte boundary), a misaligned address exception will be generated.

- **AMOSWAP.W**: Atomic Memory Operation: Swap Word

    **Format**: amoswap.w rd, rs2, (rs1)

    **Description**: AMOSWAP.W atomically loads a data value from the address in rs1, places the value into register rd, then performs a SWAP between the loaded value and the original value in rs2, then stores the result back to the address in rs1.

    **Pseudocode**: x[rd] = AMO32(M[x[rs1]] SWAP x[rs2])

    **Invalid values**: NONE

    **Exception raised**: If the address is not naturally aligned (4-byte boundary), a misaligned address exception will be generated.

- **AMOMIN.W**: Atomic Memory Operation: Minimum Word

    **Format**: amomin.d rd, rs2, (rs1)

    **Description**: AMOMIN.W atomically loads a data value from the address in rs1, places the value into register rd, then chooses the minimum between the loaded value and the original value in rs2, then stores the result back to the address in rs1.

    **Pseudocode**: x[rd] = AMO32(M[x[rs1]] MIN x[rs2])

    **Invalid values**: NONE

    **Exception raised**: If the address is not naturally aligned (4-byte boundary), a misaligned address exception will be generated.

- **AMOMINU.W**: Atomic Memory Operation: Minimum Word, Unsigned

    **Format**: amominu.d rd, rs2, (rs1)

    **Description**: AMOMINU.W atomically loads a data value from the address in rs1, places the value into register rd, then chooses the minimum (the values treated as unsigned) between the loaded value and the original value in rs2, then stores the result back to the address in rs1.

    **Pseudocode**: x[rd] = AMO32(M[x[rs1]] MINU x[rs2])

    **Invalid values**: NONE

    **Exception raised**: If the address is not naturally aligned (4-byte boundary), a misaligned address exception will be generated.

- **AMOMAX.W**: Atomic Memory Operation: Maximum Word, Unsigned

    **Format**: amomax.d rd, rs2, (rs1)

    **Description**: AMOMAX.W atomically loads a data value from the address in rs1, places the value into register rd, then chooses the maximum between the loaded value and the original value in rs2, then stores the result back to the address in rs1.

    **Pseudocode**: x[rd] = AMO32(M[x[rs1]] MAX x[rs2])

    **Invalid values**: NONE

    **Exception raised**: If the address is not naturally aligned (4-byte boundary), a misaligned address exception will be generated.

- **AMOMAXU.W**: Atomic Memory Operation: Maximum Word, Unsigned

    **Format**: amomaxu.d rd, rs2, (rs1)

    **Description**: AMOMAXU.W atomically loads a data value from the address in rs1, places the value into register rd, then chooses the maximum (the values treated as unsigned) between the loaded value and the original value in rs2, then stores the result back to the address in rs1.

    **Pseudocode**: x[rd] = AMO32(M[x[rs1]] MAXU x[rs2])

    **Invalid values**: NONE

    **Exception raised**: If the address is not naturally aligned (4-byte boundary), a misaligned address exception will be generated.

