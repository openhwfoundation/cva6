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

.. _cva6_riscv_instructions_RV32Zbb:

*Applicability of this chapter to configurations:*

.. csv-table::
   :widths: auto
   :align: left
   :header: "Configuration", "Implementation"

   "CV32A60AX", "Implemented extension"
   "CV32A60X", "Implemented extension"
   "CV64A6_MMU", "Implemented extension"

=============================
RVZbb: Basic bit-manipulation
=============================

The following instructions comprise the Zbb extension:

Logical with negate
--------------------
The Logical with Negate instructions can be implemented by inverting the rs2 inputs to the base-required AND, OR, and XOR logic instructions.

+-----------+-----------+-----------------------+
| RV32      | RV64      | Mnemonic              |
+===========+===========+=======================+
| ✔         | ✔         | andn rd, rs1, rs2     |
+-----------+-----------+-----------------------+
| ✔         | ✔         | orn rd, rs1, rs2      |
+-----------+-----------+-----------------------+
| ✔         | ✔         | xnor rd, rs1, rs2     |
+-----------+-----------+-----------------------+

RV32 and RV64 Instructions
~~~~~~~~~~~~~~~~~~~~~~~~~~


- **ANDN**: AND with inverted operand

    **Format**: andn rd, rs1, rs2

    **Description**: This instruction performs the bitwise logical AND operation between rs1 and the bitwise inversion of rs2.

    **Pseudocode**: X(rd) = X(rs1) & ~X(rs2)

    **Invalid values**: NONE

    **Exception raised**: NONE

- **ORN**: OR with inverted operand

    **Format**: orn rd, rs1, rs2 

    **Description**: This instruction performs the bitwise logical AND operation between rs1 and the bitwise inversion of rs2.

    **Pseudocode**: X(rd) = X(rs1) | ~X(rs2)

    **Invalid values**: NONE

    **Exception raised**: NONE

- **XNOR**: Exclusive NOR

    **Format**: xnor rd, rs1, rs2

    **Description**: This instruction performs the bit-wise exclusive-NOR operation on rs1 and rs2.

    **Pseudocode**: X(rd) = ~(X(rs1) ^ X(rs2))

    **Invalid values**: NONE

    **Exception raised**: NONE


Count leading/trailing zero bits
--------------------------------
These instructions are used to count the leading/trailing zero bits.

+-----------+-----------+-----------------------+
| RV32      | RV64      | Mnemonic              |
+===========+===========+=======================+
| ✔         | ✔         | clz rd, rs            |
+-----------+-----------+-----------------------+
|           | ✔         | clzw rd, rs           |
+-----------+-----------+-----------------------+
| ✔         | ✔         | ctz rd, rs            |
+-----------+-----------+-----------------------+
|           | ✔         | ctzw rd, rs           |
+-----------+-----------+-----------------------+

RV32 and RV64 Instructions
~~~~~~~~~~~~~~~~~~~~~~~~~~

- **CLZ**: Count leading zero bits

    **Format**: clz rd, rs 

    **Description**: This instruction counts the number of 0’s before the first 1, starting at the most-significant bit (i.e., XLEN-1) and progressing to bit 0. Accordingly, if the input is 0, the output is XLEN, and if the most-significant bit of the input is a 1, the output is 0

    **Pseudocode**: if [x[i]] == 1 then return(i) else return -1

    **Invalid values**: NONE

    **Exception raised**: NONE

- **CTZ**: Count trailing zeros

    **Format**: ctz rd, rs 

    **Description**: This instruction counts the number of 0’s before the first 1, starting at the least-significant bit (i.e., 0) and progressing to the most-significant bit (i.e., XLEN-1). Accordingly, if the input is 0, the output is XLEN, and if the least-significant bit of the input is a 1, the output is 0.

    **Pseudocode**: if [x[i]] == 1 then return(i) else return xlen;

    **Invalid values**: NONE

    **Exception raised**: NONE

RV64 specific instructions
~~~~~~~~~~~~~~~~~~~~~~~~~~	

- **CLZW**: Count leading zero bits in word

    **Format**: clzw rd, rs

    **Description**: This instruction counts the number of 0’s before the first 1 starting at bit 31 and progressing to bit 0. Accordingly, if the least-significant word is 0, the output is 32, and if the most-significant bit of the word (i.e., bit 31) is a 1, the output is 0.

    **Pseudocode**: if [x[i]] == 1 then return(i) else return -1

    **Invalid values**: NONE

    **Exception raised**: NONE

- **CTZW**: Count trailing zero bits in word

    **Format**: ctzw rd, rs 

    **Description**: This instruction counts the number of 0’s before the first 1, starting at the least-significant bit (i.e., 0) and progressing to the most-significant bit of the least-significant word (i.e., 31). Accordingly, if the least-significant word is 0, the output is 32, and if the least-significant bit of the input is a 1, the output is 0.

    **Pseudocode**: if [x[i]] == 1 then return(i) else return 32;

    **Invalid values**: NONE

    **Exception raised**: NONE

	
Count population
-------------------
These instructions count the number of set bits (1-bits). This is also commonly referred to as population count.

+-----------+-----------+-----------------------+
| RV32      | RV64      | Mnemonic              |
+===========+===========+=======================+
| ✔         | ✔         | cpop rd, rs           |
+-----------+-----------+-----------------------+
|           | ✔         | cpopw rd, rs          |
+-----------+-----------+-----------------------+

RV32 and RV64 Instructions
~~~~~~~~~~~~~~~~~~~~~~~~~~

- **CPOP**: Count set bits

    **Format**: cpop rd, rs 

    **Description**: This instructions counts the number of 1’s (i.e., set bits) in the source register.

    **Pseudocode**: if rs[i] == 1 then bitcount = bitcount + 1 else ()

    **Invalid values**: NONE

    **Exception raised**: NONE

RV64 specific instructions
~~~~~~~~~~~~~~~~~~~~~~~~~~	
	
- **CPOPW**: Count set bits in word

    **Format**: cpopw rd, rs 

    **Description**: This instructions counts the number of 1’s (i.e., set bits) in the least-significant word of the source register.

    **Pseudocode**: if rs[i] == 0b1 then bitcount = bitcount + 1 else ()

    **Invalid values**: NONE

    **Exception raised**: NONE



Integer minimum/maximum
--------------------------
The integer minimum/maximum instructions are arithmetic R-type instructions that return the smaller/larger of two operands.

+-----------+-----------+-----------------------+
| RV32      | RV64      | Mnemonic              |
+===========+===========+=======================+
| ✔         | ✔         | max rd, rs1, rs2      |
+-----------+-----------+-----------------------+
| ✔         | ✔         | maxu rd, rs1, rs2     |
+-----------+-----------+-----------------------+
| ✔         | ✔         | min rd, rs1, rs2      |
+-----------+-----------+-----------------------+
| ✔         | ✔         | minu rd, rs1, rs2     |
+-----------+-----------+-----------------------+

RV32 and RV64 Instructions
~~~~~~~~~~~~~~~~~~~~~~~~~~

- **MAX**: Maximum

    **Format**: max rd, rs1, rs2 

    **Description**: This instruction returns the larger of two signed integers.

    **Pseudocode**: if rs1_val <_s rs2_val then rs2_val else rs1_val

    **Invalid values**: NONE

    **Exception raised**: NONE

- **MAXU**: Unsigned maximum

    **Format**: maxu rd, rs1, rs2

    **Description**: This instruction returns the larger of two unsigned integers.

    **Pseudocode**: if rs1_val <_u rs2_val then rs2_val else rs1_val

    **Invalid values**: NONE

    **Exception raised**: NONE

- **MIN**: Minimum

    **Format**: min rd, rs1, rs2

    **Description**: This instruction returns the smaller of two signed integers.

    **Pseudocode**: if rs1_val <_s rs2_val then rs1_val else rs2_val

    **Invalid values**: NONE

    **Exception raised**: NONE

- **MINU**: Unsigned minimum

    **Format**: minu rd, rs1, rs2

    **Description**: This instruction returns the smaller of two unsigned integers.

    **Pseudocode**: if rs1_val <_u rs2_val then rs1_val else rs2_val

    **Invalid values**: NONE

    **Exception raised**: NONE


Sign and zero-extension
--------------------------
These instructions perform the sign-extension or zero-extension of the least significant 8 bits, 16 bits or 32 bits of the source register.

These instructions replace the generalized idioms slli rD,rS,(XLEN-<size>) + srli (for zero-extension) or slli + srai (for sign-extension) for the sign-extension of 8-bit and 16-bit quantities, and for the zero-extension of 16-bit and 32-bit quantities.

+-----------+-----------+-----------------------+
| RV32      | RV64      | Mnemonic              |
+===========+===========+=======================+
| ✔         | ✔         | sext.b rd, rs         |
+-----------+-----------+-----------------------+
| ✔         | ✔         | sext.h rd, rs         |
+-----------+-----------+-----------------------+
| ✔         | ✔         | zext.h rd, rs         |
+-----------+-----------+-----------------------+

RV32 and RV64 Instructions
~~~~~~~~~~~~~~~~~~~~~~~~~~

- **SEXT.B**: Sign-extend byte

    **Format**: sext.b rd, rs 

    **Description**: This instruction sign-extends the least-significant byte in the source to XLEN by copying the most-significant bit in the byte (i.e., bit 7) to all of the more-significant bits.

    **Pseudocode**: X(rd) = EXTS(X(rs)[7..0])

    **Invalid values**: NONE

    **Exception raised**: NONE

- **SEXT.H**: Sign-extend halfword

    **Format**: sext.h rd, rs

    **Description**: This instruction sign-extends the least-significant halfword in rs to XLEN by copying the most-significant bit in the halfword (i.e., bit 15) to all of the more-significant bits.

    **Pseudocode**: X(rd) = EXTS(X(rs)[15..0])

    **Invalid values**: NONE

    **Exception raised**: NONE

- **ZEXT.H**: Zero-extend halfword

    **Format**: zext.h rd, rs 

    **Description**: This instruction zero-extends the least-significant halfword of the source to XLEN by inserting 0’s into all of the bits more significant than 15.

    **Pseudocode**: X(rd) = EXTZ(X(rs)[15..0])

    **Invalid values**: NONE

    **Exception raised**: NONE

Bitwise Rotation
-------------------
Bitwise rotation instructions are similar to the shift-logical operations from the base spec. However, where the shift-logical instructions shift in zeros, the rotate instructions shift in the bits that were shifted out of the other side of the value. Such operations are also referred to as ‘circular shifts’.

+-----------+-----------+-----------------------+
| RV32      | RV64      | Mnemonic              |
+===========+===========+=======================+
| ✔         | ✔         | rol rd, rs1, rs2      |
+-----------+-----------+-----------------------+
|           | ✔         | rolw rd, rs1, rs2     |
+-----------+-----------+-----------------------+
| ✔         | ✔         | ror rd, rs1, rs2      |
+-----------+-----------+-----------------------+
| ✔         | ✔         | rori rd, rs1, shamt   |
+-----------+-----------+-----------------------+
|           | ✔         | roriw rd, rs1, shamt  |
+-----------+-----------+-----------------------+
|           | ✔         | rorw rd, rs1, rs2     |
+-----------+-----------+-----------------------+

RV32 and RV64 Instructions
~~~~~~~~~~~~~~~~~~~~~~~~~~

- **ROL**: Rotate Left (Register)

    **Format**: rol rd, rs1, rs2

    **Description**: This instruction performs a rotate left of rs1 by the amount in least-significant log2(XLEN) bits of rs2.

    **Pseudocode**: (X(rs1) << log2(XLEN)) | (X(rs1) >> (xlen - log2(XLEN)))

    **Invalid values**: NONE

    **Exception raised**: NONE

- **ROR**: Rotate Right

    **Format**: ror rd, rs1, rs2

    **Description**: This instruction performs a rotate right of rs1 by the amount in least-significant log2(XLEN) bits of rs2.

    **Pseudocode**: (X(rs1) >> log2(XLEN)) | (X(rs1) << (xlen - log2(XLEN)))

    **Invalid values**: NONE

    **Exception raised**: NONE

- **RORI**: Rotate Right (Immediate)

    **Format**: rori rd, rs1, shamt 

    **Description**: This instruction performs a rotate right of rs1 by the amount in the least-significant log2(XLEN) bits of shamt. For RV32, the encodings corresponding to shamt[5]=1 are reserved.

    **Pseudocode**: (X(rs1) >> log2(XLEN)) | (X(rs1) << (xlen - log2(XLEN)));

    **Invalid values**: NONE

    **Exception raised**: NONE

RV64 specific instructions
~~~~~~~~~~~~~~~~~~~~~~~~~~	
	
- **ROLW**: Rotate Left Word (Register)

    **Format**: rolw rd, rs1, rs2

    **Description**: This instruction performs a rotate left on the least-significant word of rs1 by the amount in least-significant 5 bits of rs2. The resulting word value is sign-extended by copying bit 31 to all of the more-significant bits.

    **Pseudocode**: EXTS((rs1 << X(rs2)[4..0];) | (rs1 >> (32 - X(rs2)[4..0];)))

    **Invalid values**: NONE

    **Exception raised**: NONE

- **RORIW**: Rotate Right Word by Immediate

    **Format**: roriw rd, rs1, shamt

    **Description**: This instruction performs a rotate right on the least-significant word of rs1 by the amount in the least-significant log2(XLEN) bits of shamt. The resulting word value is sign-extended by copying bit 31 to all of the more-significant bits.

    **Pseudocode**: (rs1_data >> shamt[4..0]) | (rs1_data << (32 - shamt[4..0]))

    **Invalid values**: NONE

    **Exception raised**: NONE

- **RORW**: Rotate Right Word (Register)

    **Format**: rorw rd, rs1, rs2 

    **Description**: This instruction performs a rotate right on the least-significant word of rs1 by the amount in least-significant 5 bits of rs2. The resultant word is sign-extended by copying bit 31 to all of the more-significant bits.

    **Pseudocode**: (rs1 >> X(rs2)[4..0]) | (rs1 << (32 - X(rs2)[4..0]))

    **Invalid values**: NONE

    **Exception raised**: NONE
	
OR Combine
------------
orc.b sets the bits of each byte in the result rd to all zeros if no bit within the respective byte of rs is set, or to all ones if any bit within the respective byte of rs is set.

One use-case is string-processing functions, such as strlen and strcpy, which can use orc.b to test for the terminating zero byte by counting the set bits in leading non-zero bytes in a word.

+-----------+-----------+-----------------------+
| RV32      | RV64      | Mnemonic              |
+===========+===========+=======================+
| ✔         | ✔         | orc.b rd, rs          |
+-----------+-----------+-----------------------+

RV32 and RV64 Instructions
~~~~~~~~~~~~~~~~~~~~~~~~~~

- **ORC.B**: Bitwise OR-Combine, byte granule

    **Format**: orc.b rd, rs 

    **Description**: Combines the bits within each byte using bitwise logical OR. This sets the bits of each byte in the result rd to all zeros if no bit within the respective byte of rs is set, or to all ones if any bit within the respective byte of rs is set.

    **Pseudocode**: if { input[(i + 7)..i] == 0 then 0b00000000 else 0b11111111

    **Invalid values**: NONE

    **Exception raised**: NONE

Byte-reverse
------------
rev8 reverses the byte-ordering of rs.

+-----------+-----------+-----------------------+
| RV32      | RV64      | Mnemonic              |
+===========+===========+=======================+
| ✔         | ✔         | rev8 rd, rs           |
+-----------+-----------+-----------------------+

RV32 and RV64 Instructions
~~~~~~~~~~~~~~~~~~~~~~~~~~

- **REV8**: Byte-reverse register

    **Format**:  rev8 rd, rs

    **Description**: This instruction reverses the order of the bytes in rs.

    **Pseudocode**: output[i..(i + 7)] = input[(j - 7)..j]

    **Invalid values**: NONE

    **Exception raised**: NONE


