# Module: ISA RISC-V 32b

## Feature: RV32I Register-Immediate Instructions

### Sub-feature: 000_ADDI

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  addi rd, rs1, imm[11:0]  
  rd = rs1 + Sext(imm[11:0])  
  Arithmetic overflow is lost and ignored
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
  All possible rd registers are used.  
  All possible register combinations where rs1 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F000_S000_I000
* **Link to Coverage:** isacov.rv32i_addi_cg.cp_rs1
isacov.rv32i_addi_cg.cp_rd
isacov.rv32i_addi_cg.cp_rd_rs1_hazard
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  addi rd, rs1, imm[11:0]  
  rd = rs1 + Sext(imm[11:0])  
  Arithmetic overflow is lost and ignored
* **Verification Goals**
  
  Input operands:  
    
  rs1 value is +ve, -ve and zero  
  immi value is +ve, -ve and zero  
  All combinations of rs1 and immi +ve, -ve, and zero values are used  
  All bits of rs1 are toggled  
  All bits of immi are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F000_S000_I001
* **Link to Coverage:** isacov.rv32i_addi_cg.cp_rs1_value
isacov.rv32i_addi_cg.cp_immi_value
isacov.rv32i_addi_cg.cross_rs1_immi_value
isacov.rv32i_addi_cg.cp_rs1_toggle
isacov.rv32i_addi_cg.cp_immi_toggle
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  addi rd, rs1, imm[11:0]  
  rd = rs1 + Sext(imm[11:0])  
  Arithmetic overflow is lost and ignored
* **Verification Goals**
  
  Output result:  
    
  rd value is +ve, -ve and zero  
  All bits of rd are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F000_S000_I002
* **Link to Coverage:** isacov.rv32i_addi_cg.cp_rd_value
isacov.rv32i_addi_cg.cp_rd_toggle
* **Comments**
  
  *(none)*  
  
### Sub-feature: 001_XORI

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  xori rd, rs1, imm[11:0]  
  rd = rs1 ^ Sext(imm[11:0])  
  Note: this is a bitwise, not logical operation
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
  All possible rd registers are used.  
  All possible register combinations where rs1 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F000_S001_I000
* **Link to Coverage:** isacov.rv32i_xori_cg.cp_rs1
isacov.rv32i_xori_cg.cp_rd
isacov.rv32i_xori_cg.cp_rd_rs1_hazard
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  xori rd, rs1, imm[11:0]  
  rd = rs1 ^ Sext(imm[11:0])  
  Note: this is a bitwise, not logical operation
* **Verification Goals**
  
  Input operands:  
    
  rs1 value is +ve, -ve and zero  
  immi value is +ve, -ve and zero  
  All combinations of rs1 and immi +ve, -ve, and zero values are used  
  All bits of rs1 are toggled  
  All bits of immi are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F000_S001_I001
* **Link to Coverage:** isacov.rv32i_xori_cg.cp_rs1_value
isacov.rv32i_xori_cg.cp_immi_value
isacov.rv32i_xori_cg.cross_rs1_immi_value
isacov.rv32i_xori_cg.cp_rs1_toggle
isacov.rv32i_xori_cg.cp_immi_toggle
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  xori rd, rs1, imm[11:0]  
  rd = rs1 ^ Sext(imm[11:0])  
  Note: this is a bitwise, not logical operation
* **Verification Goals**
  
  Output result:  
    
  rd value is +ve, -ve and zero  
  All bits of rd are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F000_S001_I002
* **Link to Coverage:** isacov.rv32i_xori_cg.cp_rd_value
isacov.rv32i_xori_cg.cp_rd_toggle
* **Comments**
  
  *(none)*  
  
### Sub-feature: 002_ORI

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  ori rd, rs1, imm[11:0]  
  rd = rs1 | Sext(imm[11:0])  
  Note: this is a bitwise, not logical operation
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
  All possible rd registers are used.  
  All possible register combinations where rs1 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F000_S002_I000
* **Link to Coverage:** isacov.rv32i_ori_cg.cp_rs1
isacov.rv32i_ori_cg.cp_rd
isacov.rv32i_ori_cg.cp_rd_rs1_hazard
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  ori rd, rs1, imm[11:0]  
  rd = rs1 | Sext(imm[11:0])  
  Note: this is a bitwise, not logical operation
* **Verification Goals**
  
  Input operands:  
    
  rs1 value is +ve, -ve and zero  
  immi value is +ve, -ve and zero  
  All combinations of rs1 and immi +ve, -ve, and zero values are used  
  All bits of rs1 are toggled  
  All bits of immi are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F000_S002_I001
* **Link to Coverage:** isacov.rv32i_ori_cg.cp_rs1_value
isacov.rv32i_ori_cg.cp_immi_value
isacov.rv32i_ori_cg.cross_rs1_immi_value
isacov.rv32i_ori_cg.cp_rs1_toggle
isacov.rv32i_ori_cg.cp_immi_toggle
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  ori rd, rs1, imm[11:0]  
  rd = rs1 | Sext(imm[11:0])  
  Note: this is a bitwise, not logical operation
* **Verification Goals**
  
  Output result:  
    
  rd value is +ve, -ve and zero  
  All bits of rd are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F000_S002_I002
* **Link to Coverage:** isacov.rv32i_ori_cg.cp_rd_value
isacov.rv32i_ori_cg.cp_rd_toggle
* **Comments**
  
  *(none)*  
  
### Sub-feature: 003_ANDI

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  andi rd, rs1, imm[11:0]  
  rd = rs1 &  Sext(imm[11:0])  
  Note: this is a bitwise, not logical operation
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
  All possible rd registers are used.  
  All possible register combinations where rs1 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F000_S003_I000
* **Link to Coverage:** isacov.rv32i_andi_cg.cp_rs1
isacov.rv32i_andi_cg.cp_rd
isacov.rv32i_andi_cg.cp_rd_rs1_hazard
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  andi rd, rs1, imm[11:0]  
  rd = rs1 &  Sext(imm[11:0])  
  Note: this is a bitwise, not logical operation
* **Verification Goals**
  
  Input operands:  
    
  rs1 value is +ve, -ve and zero  
  immi value is +ve, -ve and zero  
  All combinations of rs1 and immi +ve, -ve, and zero values are used  
  All bits of rs1 are toggled  
  All bits of immi are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F000_S003_I001
* **Link to Coverage:** isacov.rv32i_andi_cg.cp_rs1_value
isacov.rv32i_andi_cg.cp_immi_value
isacov.rv32i_andi_cg.cross_rs1_immi_value
isacov.rv32i_andi_cg.cp_rs1_toggle
isacov.rv32i_andi_cg.cp_immi_toggle
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  andi rd, rs1, imm[11:0]  
  rd = rs1 &  Sext(imm[11:0])  
  Note: this is a bitwise, not logical operation
* **Verification Goals**
  
  Output result:  
    
  rd value is +ve, -ve and zero  
  All bits of rd are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F000_S003_I002
* **Link to Coverage:** isacov.rv32i_andi_cg.cp_rd_value
isacov.rv32i_andi_cg.cp_rd_toggle
* **Comments**
  
  *(none)*  
  
### Sub-feature: 004_SLTI

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  slti rd, rs1, imm[11:0]  
  rd = (rs1 < Sext(imm[11:0]) ? 1 : 0  
  Both imm and rs1 treated as signed numbers
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
  All possible rd registers are used.  
  All possible register combinations where rs1 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F000_S004_I000
* **Link to Coverage:** isacov.rv32i_slti_cg.cp_rs1
isacov.rv32i_slti_cg.cp_rd
isacov.rv32i_slti_cg.cp_rd_rs1_hazard
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  slti rd, rs1, imm[11:0]  
  rd = (rs1 < Sext(imm[11:0]) ? 1 : 0  
  Both imm and rs1 treated as signed numbers
* **Verification Goals**
  
  Input operands:  
    
  rs1 value is +ve, -ve and zero  
  immi value is +ve, -ve and zero  
  All combinations of rs1 and immi +ve, -ve, and zero values are used  
  All bits of rs1 are toggled  
  All bits of immi are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F000_S004_I001
* **Link to Coverage:** isacov.rv32i_slti_cg.cp_rs1_value
isacov.rv32i_slti_cg.cp_immi_value
isacov.rv32i_slti_cg.cross_rs1_immi_value
isacov.rv32i_slti_cg.cp_rs1_toggle
isacov.rv32i_slti_cg.cp_immi_toggle
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  slti rd, rs1, imm[11:0]  
  rd = (rs1 < Sext(imm[11:0]) ? 1 : 0  
  Both imm and rs1 treated as signed numbers
* **Verification Goals**
  
  Output result:  
    
  rd value is in [0,1]
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F000_S004_I002
* **Link to Coverage:** isacov.rv32i_slti_cg.cp_rd_value
* **Comments**
  
  *(none)*  
  
### Sub-feature: 005_SLTIU

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  sltiu rd, rs1, imm[11:0]  
  rd = (rs1 < Sext(imm[11:0]) ? 1 : 0  
  Both imm and rs1 treated as unsigned numbers
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
  All possible rd registers are used.  
  All possible register combinations where rs1 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F000_S005_I000
* **Link to Coverage:** isacov.rv32i_sltiu_cg.cp_rs1
isacov.rv32i_sltiu_cg.cp_rd
isacov.rv32i_sltiu_cg.cp_rd_rs1_hazard
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  sltiu rd, rs1, imm[11:0]  
  rd = (rs1 < Sext(imm[11:0]) ? 1 : 0  
  Both imm and rs1 treated as unsigned numbers
* **Verification Goals**
  
  Input operands:  
    
  rs1 value is +ve, -ve and zero  
  immi value is +ve, -ve and zero  
  All combinations of rs1 and immi +ve, -ve, and zero values are used  
  All bits of rs1 are toggled  
  All bits of immi are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F000_S005_I001
* **Link to Coverage:** isacov.rv32i_sltiu_cg.cp_rs1_value
isacov.rv32i_sltiu_cg.cp_immi_value
isacov.rv32i_sltiu_cg.cross_rs1_immi_value
isacov.rv32i_sltiu_cg.cp_rs1_toggle
isacov.rv32i_sltiu_cg.cp_immi_toggle
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  sltiu rd, rs1, imm[11:0]  
  rd = (rs1 < Sext(imm[11:0]) ? 1 : 0  
  Both imm and rs1 treated as unsigned numbers
* **Verification Goals**
  
  Output result:  
    
  rd value is in [0,1]
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F000_S005_I002
* **Link to Coverage:** isacov.rv32i_sltiu_cg.cp_rd_value
* **Comments**
  
  *(none)*  
  
### Sub-feature: 006_SLLI

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  slli rd, rs, imm[4:0]  
  rd = rs << imm[4:0]  
  Zeros are shifted into lower bits
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
  All possible rd registers are used.  
  All possible register combinations where rs1 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F000_S006_I000
* **Link to Coverage:** isacov.rv32i_slli_cg.cp_rs1
isacov.rv32i_slli_cg.cp_rd
isacov.rv32i_slli_cg.cp_rd_rs1_hazard
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  slli rd, rs, imm[4:0]  
  rd = rs << imm[4:0]  
  Zeros are shifted into lower bits
* **Verification Goals**
  
  Input operands:  
    
  rs1 value is +ve, -ve and zero  
  immediate shamt value is [0,31]  
  All combinations of rs1 and immi +ve, -ve, and zero values are used  
  All bits of rs1 are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F000_S006_I001
* **Link to Coverage:** isacov.rv32i_slli_cg.cp_rs1_value
isacov.rv32i_slli_cg.cp_immi_value
isacov.rv32i_slli_cg.cross_rs1_immi_value
isacov.rv32i_slli_cg.cp_rs1_toggle
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  slli rd, rs, imm[4:0]  
  rd = rs << imm[4:0]  
  Zeros are shifted into lower bits
* **Verification Goals**
  
  Output result:  
    
  rd value is +ve, -ve and zero  
  All bits of rd are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F000_S006_I002
* **Link to Coverage:** isacov.rv32i_slli_cg.cp_rd_value
isacov.rv32i_slli_cg.cp_rd_toggle
* **Comments**
  
  *(none)*  
  
### Sub-feature: 007_SRLI

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  srli rd, rs, imm[4:0]  
  rd = rs >> imm[4:0]  
  Zeros are shifted into upper bits
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
  All possible rd registers are used.  
  All possible register combinations where rs1 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F000_S007_I000
* **Link to Coverage:** isacov.rv32i_srli_cg.cp_rs1
isacov.rv32i_srli_cg.cp_rd
isacov.rv32i_srli_cg.cp_rd_rs1_hazard
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  srli rd, rs, imm[4:0]  
  rd = rs >> imm[4:0]  
  Zeros are shifted into upper bits
* **Verification Goals**
  
  Input operands:  
    
  rs1 value is +ve, -ve and zero  
  immediate shamt value is [0,31]  
  All combinations of rs1 and immi +ve, -ve, and zero values are used  
  All bits of rs1 are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F000_S007_I001
* **Link to Coverage:** isacov.rv32i_srli_cg.cp_rs1_value
isacov.rv32i_srli_cg.cp_immi_value
isacov.rv32i_srli_cg.cross_rs1_immi_value
isacov.rv32i_srli_cg.cp_rs1_toggle
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  srli rd, rs, imm[4:0]  
  rd = rs >> imm[4:0]  
  Zeros are shifted into upper bits
* **Verification Goals**
  
  Output result:  
    
  rd value is +ve, -ve and zero  
  All bits of rd are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F000_S007_I002
* **Link to Coverage:** isacov.rv32i_srli_cg.cp_rd_value
isacov.rv32i_srli_cg.cp_rd_toggle
* **Comments**
  
  *(none)*  
  
### Sub-feature: 008_SRAI

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  srli rd, rs, imm[4:0]  
  rd = rs >> imm[4:0]  
  The original sign bit is copied into the vacated upper bits
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
  All possible rd registers are used.  
  All possible register combinations where rs1 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F000_S008_I000
* **Link to Coverage:** isacov.rv32i_srai_cg.cp_rs1
isacov.rv32i_srai_cg.cp_rd
isacov.rv32i_srai_cg.cp_rd_rs1_hazard
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  srli rd, rs, imm[4:0]  
  rd = rs >> imm[4:0]  
  The original sign bit is copied into the vacated upper bits
* **Verification Goals**
  
  Input operands:  
    
  rs1 value is +ve, -ve and zero  
  immediate shamt value is [0,31]  
  All combinations of rs1 and immi +ve, -ve, and zero values are used  
  All bits of rs1 are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F000_S008_I001
* **Link to Coverage:** isacov.rv32i_srai_cg.cp_rs1_value
isacov.rv32i_srai_cg.cp_immi_value
isacov.rv32i_srai_cg.cross_rs1_immi_value
isacov.rv32i_srai_cg.cp_rs1_toggle
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  srli rd, rs, imm[4:0]  
  rd = rs >> imm[4:0]  
  Zeros are shifted into upper bits
* **Verification Goals**
  
  Output result:  
    
  rd value is +ve, -ve and zero  
  All bits of rd are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F000_S008_I002
* **Link to Coverage:** isacov.rv32i_srai_cg.cp_rd_value
isacov.rv32i_srai_cg.cp_rd_toggle
* **Comments**
  
  *(none)*  
  
### Sub-feature: 009_LUI

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  lui rd, imm[19:0]  
  rd = imm[19:0] << 12  
  rd[11:0] is zero-filled.
* **Verification Goals**
  
  Register operands:  
    
  All possible rd registers are used.
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F000_S009_I000
* **Link to Coverage:** isacov.rv32i_lui_cg.cp_rd
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  lui rd, imm[19:0]  
  rd = imm[19:0] << 12  
  rd[11:0] is zero-filled.
* **Verification Goals**
  
  Input operands:  
    
  rs1 value is +ve, -ve and zero  
  immediate value is zero and non-zero  
  All bits of immu are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F000_S009_I001
* **Link to Coverage:** isacov.rv32i_lui_cg.cp_immu_value
isacov.rv32i_lui_cg.cp_immu_toggle
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  lui rd, imm[19:0]  
  rd = imm[19:0] << 12  
  rd[11:0] is zero-filled.
* **Verification Goals**
  
  Output result:  
    
  rd value is zero and non-zero  
  All bits of rd[31:12] are toggled (11:0 are deposited with 0)
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F000_S009_I002
* **Link to Coverage:** isacov.rv32i_lui_cg.cp_rd_value
isacov.rv32i_lui_cg.cp_rd_toggle
* **Comments**
  
  *(none)*  
  
### Sub-feature: 010_AUIPC

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  auipc rd, imm[19:0]  
  rd = pc + (imm[19:0] << 12)  
  pc is address of auipc instruction  
    
  Assumption: arithmetic overflow is lost and ignored.
* **Verification Goals**
  
  Register operands:  
    
  All possible rd registers are used.
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F000_S010_I000
* **Link to Coverage:** isacov.rv32i_auipc_cg.cp_rd
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  auipc rd, imm[19:0]  
  rd = pc + (imm[19:0] << 12)  
  pc is address of auipc instruction  
    
  Assumption: arithmetic overflow is lost and ignored.
* **Verification Goals**
  
  Input operands:  
    
  rs1 value is +ve, -ve and zero  
  immediate value is zero and non-zero  
  All bits of immu are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F000_S010_I001
* **Link to Coverage:** isacov.rv32i_auipc_cg.cp_immu_value
isacov.rv32i_auipc_cg.cp_immu_toggle
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  auipc rd, imm[19:0]  
  rd = pc + (imm[19:0] << 12)  
  pc is address of auipc instruction  
    
  Assumption: arithmetic overflow is lost and ignored.
* **Verification Goals**
  
  Output result:  
    
  rd value is zero and non-zero  
  All bits of rd[31:12] are toggled (11:0 are deposited with 0)
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F000_S010_I002
* **Link to Coverage:** isacov.rv32i_auipc_cg.cp_rd_value
isacov.rv32i_auipc_cg.cp_rd_toggle
* **Comments**
  
  *(none)*  
  
## Feature: RV32I Register-Register Instructions

### Sub-feature: 000_ADD

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  add rd, rs1, rs2  
  rd = rs1 + rs2  
  Arithmetic overflow is lost and ignored
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
  All possible rs2 registers are used.  
  All possible rd registers are used.  
  All possible register combinations where rs1 == rd are used  
  All possible register combinations where rs2 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F001_S000_I000
* **Link to Coverage:** isacov.rv32i_add_cg.cp_rs1
isacov.rv32i_add_cg.cp_rs2
isacov.rv32i_add_cg.cp_rd
isacov.rv32i_add_cg.cp_rd_rs1_hazard
isacov.rv32i_add_cg.cp_rd_rs2_hazard
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  add rd, rs1, rs2  
  rd = rs1 + rs2  
  Arithmetic overflow is lost and ignored
* **Verification Goals**
  
  Input operands:  
    
  rs1 value is +ve, -ve and zero  
  rs2 value is +ve, -ve and zero  
  All combinations of rs1 and rs2 +ve, -ve, and zero values are used  
  All bits of rs1 are toggled  
  All bits of rs2 are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F001_S000_I001
* **Link to Coverage:** isacov.rv32i_add_cg.cp_rs1_value
isacov.rv32i_add_cg.cp_rs2_value
isacov.rv32i_add_cg.cross_rs1_rs2_value
isacov.rv32i_add_cg.cp_rs1_toggle
isacov.rv32i_add_cg.cp_rs2_toggle
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  add rd, rs1, rs2  
  rd = rs1 + rs2  
  Arithmetic overflow is lost and ignored
* **Verification Goals**
  
  Output result:  
    
  rd value is +ve, -ve and zero  
  All bits of rd are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F001_S000_I002
* **Link to Coverage:** isacov.rv32i_add_cg.cp_rd_value
isacov.rv32i_add_cg.cp_rd_toggle
* **Comments**
  
  *(none)*  
  
### Sub-feature: 001_SUB

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  sub rd, rs1, rs2  
  rd = rs1 - rs2  
  Arithmetic underflow is ignored
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
  All possible rs2 registers are used.  
  All possible rd registers are used.  
  All possible register combinations where rs1 == rd are used  
  All possible register combinations where rs2 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F001_S001_I000
* **Link to Coverage:** isacov.rv32i_sub_cg.cp_rs1
isacov.rv32i_sub_cg.cp_rs2
isacov.rv32i_sub_cg.cp_rd
isacov.rv32i_sub_cg.cp_rd_rs1_hazard
isacov.rv32i_sub_cg.cp_rd_rs2_hazard
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  sub rd, rs1, rs2  
  rd = rs1 - rs2  
  Arithmetic underflow is ignored
* **Verification Goals**
  
  Input operands:  
    
  rs1 value is +ve, -ve and zero  
  rs2 value is +ve, -ve and zero  
  All combinations of rs1 and rs2 +ve, -ve, and zero values are used  
  All bits of rs1 are toggled  
  All bits of rs2 are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F001_S001_I001
* **Link to Coverage:** isacov.rv32i_sub_cg.cp_rs1_value
isacov.rv32i_sub_cg.cp_rs2_value
isacov.rv32i_sub_cg.cross_rs1_rs2_value
isacov.rv32i_sub_cg.cp_rs1_toggle
isacov.rv32i_sub_cg.cp_rs2_toggle
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  sub rd, rs1, rs2  
  rd = rs1 - rs2  
  Arithmetic underflow is ignored
* **Verification Goals**
  
  Output result:  
    
  rd value is +ve, -ve and zero  
  All bits of rd are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F001_S001_I002
* **Link to Coverage:** isacov.rv32i_sub_cg.cp_rd_value
isacov.rv32i_sub_cg.cp_rd_toggle
* **Comments**
  
  *(none)*  
  
### Sub-feature: 002_AND

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  and rd, rs1, rs2  
  rd = rs1 & rs2  
  Note: this is a bitwise, not logical operation
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
  All possible rs2 registers are used.  
  All possible rd registers are used.  
  All possible register combinations where rs1 == rd are used  
  All possible register combinations where rs2 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F001_S002_I000
* **Link to Coverage:** isacov.rv32i_and_cg.cp_rs1
isacov.rv32i_and_cg.cp_rs2
isacov.rv32i_and_cg.cp_rd
isacov.rv32i_and_cg.cp_rd_rs1_hazard
isacov.rv32i_and_cg.cp_rd_rs2_hazard
isacov.rv32i_and_cg.cp_rs1
isacov.rv32i_and_cg.cp_rs2
isacov.rv32i_and_cg.cp_rd
isacov.rv32i_and_cg.cp_rd_rs1_hazard
isacov.rv32i_and_cg.cp_rd_rs2_hazard
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  and rd, rs1, rs2  
  rd = rs1 & rs2  
  Note: this is a bitwise, not logical operation
* **Verification Goals**
  
  Input operands:  
    
  rs1 value is +ve, -ve and zero  
  rs2 value is +ve, -ve and zero  
  All combinations of rs1 and rs2 +ve, -ve, and zero values are used  
  All bits of rs1 are toggled  
  All bits of rs2 are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F001_S002_I001
* **Link to Coverage:** isacov.rv32i_and_cg.cp_rs1_value
isacov.rv32i_and_cg.cp_rs2_value
isacov.rv32i_and_cg.cross_rs1_rs2_value
isacov.rv32i_and_cg.cp_rs1_toggle
isacov.rv32i_and_cg.cp_rs2_toggle
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  and rd, rs1, rs2  
  rd = rs1 & rs2  
  Note: this is a bitwise, not logical operation
* **Verification Goals**
  
  Output result:  
    
  rd value is +ve, -ve and zero  
  All bits of rd are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F001_S002_I002
* **Link to Coverage:** isacov.rv32i_and_cg.cp_rd_value
isacov.rv32i_and_cg.cp_rd_toggle
* **Comments**
  
  *(none)*  
  
### Sub-feature: 003_OR

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  or rd, rs1, rs2  
  rd = rs1 | rs2  
  Note: this is a bitwise, not logical operation
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
  All possible rs2 registers are used.  
  All possible rd registers are used.  
  All possible register combinations where rs1 == rd are used  
  All possible register combinations where rs2 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F001_S003_I000
* **Link to Coverage:** isacov.rv32i_or_cg.cp_rs1
isacov.rv32i_or_cg.cp_rs2
isacov.rv32i_or_cg.cp_rd
isacov.rv32i_or_cg.cp_rd_rs1_hazard
isacov.rv32i_or_cg.cp_rd_rs2_hazard
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  or rd, rs1, rs2  
  rd = rs1 | rs2  
  Note: this is a bitwise, not logical operation
* **Verification Goals**
  
  Input operands:  
    
  rs1 value is +ve, -ve and zero  
  rs2 value is +ve, -ve and zero  
  All combinations of rs1 and rs2 +ve, -ve, and zero values are used  
  All bits of rs1 are toggled  
  All bits of rs2 are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F001_S003_I001
* **Link to Coverage:** isacov.rv32i_or_cg.cp_rs1_value
isacov.rv32i_or_cg.cp_rs2_value
isacov.rv32i_or_cg.cross_rs1_rs2_value
isacov.rv32i_or_cg.cp_rs1_toggle
isacov.rv32i_or_cg.cp_rs2_toggle
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  or rd, rs1, rs2  
  rd = rs1 | rs2  
  Note: this is a bitwise, not logical operation
* **Verification Goals**
  
  Output result:  
    
  rd value is +ve, -ve and zero  
  All bits of rd are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F001_S003_I002
* **Link to Coverage:** isacov.rv32i_or_cg.cp_rd_value
isacov.rv32i_or_cg.cp_rd_toggle
* **Comments**
  
  *(none)*  
  
### Sub-feature: 004_XOR

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  xor rd, rs1, rs2  
  rd = rs1 ^ rs2  
  Note: this is a bitwise, not logical operation
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
  All possible rs2 registers are used.  
  All possible rd registers are used.  
  All possible register combinations where rs1 == rd are used  
  All possible register combinations where rs2 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F001_S004_I000
* **Link to Coverage:** isacov.rv32i_xor_cg.cp_rs1
isacov.rv32i_xor_cg.cp_rs2
isacov.rv32i_xor_cg.cp_rd
isacov.rv32i_xor_cg.rd_rs1_hazard
isacov.rv32i_xor_cg.rd_rs2_hazard
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  xor rd, rs1, rs2  
  rd = rs1 ^ rs2  
  Note: this is a bitwise, not logical operation
* **Verification Goals**
  
  Input operands:  
    
  rs1 value is +ve, -ve and zero  
  rs2 value is +ve, -ve and zero  
  All combinations of rs1 and rs2 +ve, -ve, and zero values are used  
  All bits of rs1 are toggled  
  All bits of rs2 are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F001_S004_I001
* **Link to Coverage:** isacov.rv32i_xor_cg.cp_rs1_value
isacov.rv32i_xor_cg.cp_rs2_value
isacov.rv32i_xor_cg.cross_rs1_rs2_value
isacov.rv32i_xor_cg.cp_rs1_toggle
isacov.rv32i_xor_cg.cp_rs2_toggle
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  xor rd, rs1, rs2  
  rd = rs1 ^ rs2  
  Note: this is a bitwise, not logical operation
* **Verification Goals**
  
  Output result:  
    
  rd value is +ve, -ve and zero  
  All bits of rd are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F001_S004_I002
* **Link to Coverage:** isacov.rv32i_xor_cg.cp_rd_value
isacov.rv32i_xor_cg.cp_rd_toggle
* **Comments**
  
  *(none)*  
  
### Sub-feature: 005_SLT

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  slt rd, rs1, rs2  
  rd = (rs1 < rs2) ? 1 : 0  
  Both rs1 ad rs2 treated as signed numbers
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
  All possible rs2 registers are used.  
  All possible rd registers are used.  
  All possible register combinations where rs1 == rd are used  
  All possible register combinations where rs2 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F001_S005_I000
* **Link to Coverage:** isacov.rv32i_slt_cg.cp_rs1
isacov.rv32i_slt_cg.cp_rs2
isacov.rv32i_slt_cg.cp_rd
isacov.rv32i_slt_cg.cp_rd_rs1_hazard
isacov.rv32i_slt_cg.cp_rd_rs2_hazard
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  slt rd, rs1, rs2  
  rd = (rs1 < rs2) ? 1 : 0  
  Both rs1 ad rs2 treated as signed numbers
* **Verification Goals**
  
  Input operands:  
    
  rs1 value is +ve, -ve and zero  
  rs2 value is +ve, -ve and zero  
  All combinations of rs1 and rs2 +ve, -ve, and zero values are used  
  All bits of rs1 are toggled  
  All bits of rs2 are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F001_S005_I001
* **Link to Coverage:** isacov.rv32i_slt_cg.cp_rs1_value
isacov.rv32i_slt_cg.cp_rs2_value
isacov.rv32i_slt_cg.cross_rs1_rs2_value
isacov.rv32i_slt_cg.cp_rs1_toggle
isacov.rv32i_slt_cg.cp_rs2_toggle
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  slt rd, rs1, rs2  
  rd = (rs1 < rs2) ? 1 : 0  
  Both rs1 ad rs2 treated as signed numbers
* **Verification Goals**
  
  Output result:  
    
  rd value is [0,1]
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F001_S005_I002
* **Link to Coverage:** isacov.rv32i_slt_cg.cp_rd_value
* **Comments**
  
  *(none)*  
  
### Sub-feature: 006_SLTU

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  sltu rd, rs1, imm[11:0]  
  rd = (rs1 < rs2) ? 1 : 0  
  Both rs1 and rs2 treated as unsigned numbers
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
  All possible rs2 registers are used.  
  All possible rd registers are used.  
  All possible register combinations where rs1 == rd are used  
  All possible register combinations where rs2 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F001_S006_I000
* **Link to Coverage:** isacov.rv32i_sltu_cg.cp_rs1
isacov.rv32i_sltu_cg.cp_rs2
isacov.rv32i_sltu_cg.cp_rd
isacov.rv32i_sltu_cg.cp_rd_rs1_hazard
isacov.rv32i_sltu_cg.cp_rd_rs2_hazard
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  sltu rd, rs1, imm[11:0]  
  rd = (rs1 < rs2) ? 1 : 0  
  Both rs1 and rs2 treated as unsigned numbers
* **Verification Goals**
  
  Input operands:  
    
  rs1 value is non-zero and zero  
  rs2 value is non-zero and zero  
  All combinations of rs1 and rs2 non-zero and zero values are used  
  All bits of rs1 are toggled  
  All bits of rs2 are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F001_S006_I001
* **Link to Coverage:** isacov.rv32i_sltu_cg.cp_rs1_value
isacov.rv32i_sltu_cg.cp_rs2_value
isacov.rv32i_sltu_cg.cross_rs1_rs2_value
isacov.rv32i_sltu_cg.cp_rs1_toggle
isacov.rv32i_sltu_cg.cp_rs2_toggle
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  sltu rd, rs1, imm[11:0]  
  rd = (rs1 < rs2) ? 1 : 0  
  Both rs1 and rs2 treated as unsigned numbers
* **Verification Goals**
  
  Output result:  
    
  rd value is [0,1]
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F001_S006_I002
* **Link to Coverage:** isacov.rv32i_sltu_cg.cp_rd_value
* **Comments**
  
  *(none)*  
  
### Sub-feature: 007_SLL

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  sll rd, rs1, rs2  
  rd = rs1 << rs2[4:0]  
  Zeros are shifted into lower bits
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
  All possible rs2 registers are used.  
  All possible rd registers are used.  
  All possible register combinations where rs1 == rd are used  
  All possible register combinations where rs2 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F001_S007_I000
* **Link to Coverage:** isacov.rv32i_sll_cg.cp_rs1
isacov.rv32i_sll_cg.cp_rs2
isacov.rv32i_sll_cg.cp_rd
isacov.rv32i_sll_cg.cp_rd_rs1_hazard
isacov.rv32i_sll_cg.cp_rd_rs2_hazard
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  sll rd, rs1, rs2  
  rd = rs1 << rs2[4:0]  
  Zeros are shifted into lower bits
* **Verification Goals**
  
  Input operands:  
    
  rs1 value is non-zero and zero  
  rs2 value is tested from [0,31]  
  All combinations of rs1 and rs2 non-zero and zero values with all shift values are used  
  All bits of rs1 are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F001_S007_I001
* **Link to Coverage:** isacov.rv32i_sll_cg.cp_rs1_value
isacov.rv32i_sll_cg.cp_rs2_value
isacov.rv32i_sll_cg.cross_rs1_rs2_value
isacov.rv32i_sll_cg.cp_rs1_toggle
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  sll rd, rs1, rs2  
  rd = rs1 << rs2[4:0]  
  Zeros are shifted into lower bits
* **Verification Goals**
  
  Output result:  
    
  rd value is non-zero and zero.  
  All bits of rd are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F001_S007_I002
* **Link to Coverage:** isacov.rv32i_sll_cg.cp_rd_value
isacov.rv32i_sll_cg.cp_rd_toggle
isacov.rv32i_sll_cg.cp_rd_value
isacov.rv32i_sll_cg.cp_rd_toggle
* **Comments**
  
  *(none)*  
  
### Sub-feature: 008_SRL

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  srl rd, rs1, rs2  
  rd = rs1 >> rs2[4:0]  
  Zeros are shifted into upper bits
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
  All possible rs2 registers are used.  
  All possible rd registers are used.  
  All possible register combinations where rs1 == rd are used  
  All possible register combinations where rs2 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F001_S008_I000
* **Link to Coverage:** isacov.rv32i_srl_cg.cp_rs1
isacov.rv32i_srl_cg.cp_rs2
isacov.rv32i_srl_cg.cp_rd
isacov.rv32i_srl_cg.cp_rd_rs1_hazard
isacov.rv32i_srl_cg.cp_rd_rs2_hazard
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  srl rd, rs1, rs2  
  rd = rs1 >> rs2[4:0]  
  Zeros are shifted into upper bits
* **Verification Goals**
  
  Input operands:  
    
  rs1 value is non-zero and zero  
  rs2 value is tested from [0,31]  
  All combinations of rs1 and rs2 non-zero and zero values with all shift values are used  
  All bits of rs1 are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F001_S008_I001
* **Link to Coverage:** isacov.rv32i_srl_cg.cp_rs1_value
isacov.rv32i_srl_cg.cp_rs2_value
isacov.rv32i_srl_cg.cross_rs1_rs2_value
isacov.rv32i_srl_cg.cp_rs1_toggle
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  srl rd, rs1, rs2  
  rd = rs1 >> rs2[4:0]  
  Zeros are shifted into upper bits
* **Verification Goals**
  
  Output result:  
    
  rd value is non-zero and zero.  
  All bits of rd are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F001_S008_I002
* **Link to Coverage:** isacov.rv32i_srl_cg.cp_rd_value
isacov.rv32i_srl_cg.cp_rd_toggle
* **Comments**
  
  *(none)*  
  
### Sub-feature: 009_SRA

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  sra rd, rs1, rs2  
  rd = rs1 >> rs2[4:0]  
  The original sign bit is copied into the vacated upper bits
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
  All possible rs2 registers are used.  
  All possible rd registers are used.  
  All possible register combinations where rs1 == rd are used  
  All possible register combinations where rs2 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F001_S009_I000
* **Link to Coverage:** isacov.rv32i_sra_cg.cp_rs1
isacov.rv32i_sra_cg.cp_rs2
isacov.rv32i_sra_cg.cp_rd
isacov.rv32i_sra_cg.cp_rd_rs1_hazard
isacov.rv32i_sra_cg.cp_rd_rs2_hazard
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  sra rd, rs1, rs2  
  rd = rs1 >> rs2[4:0]  
  The original sign bit is copied into the vacated upper bits
* **Verification Goals**
  
  Input operands:  
    
  rs1 value is +ve, -ve, and zero  
  rs2 value is tested from [0,31]  
  All combinations of rs1 and rs2 +ve, -ve and zero values with all shift values are used  
  All bits of rs1 are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F001_S009_I001
* **Link to Coverage:** isacov.rv32i_sra_cg.cp_rs1_value
isacov.rv32i_sra_cg.cp_rs2_value
isacov.rv32i_sra_cg.cross_rs1_rs2_value
isacov.rv32i_sra_cg.cp_rs1_toggle
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  sra rd, rs1, rs2  
  rd = rs1 >> rs2[4:0]  
  Zeros are shifted into upper bits
* **Verification Goals**
  
  Output result:  
    
  rd value is +ve, -ve, and zero.  
  All bits of rd are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F001_S009_I002
* **Link to Coverage:** isacov.rv32i_sra_cg.cp_rd_value
isacov.rv32i_sra_cg.cp_rd_toggle
* **Comments**
  
  *(none)*  
  
## Feature: RV32I Control Transfer Instructions

### Sub-feature: 000_JAL

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  jal rd, imm[20:1]  
  rd = pc+4; pc += Sext({imm[20:1], 1’b0})  
  pc is calculated using signed arithmetic  
    
  jal x0, imm[20:1] (special case: unconditional jump)  
  pc += Sext({imm[20:1], 1’b0})
* **Verification Goals**
  
  Register operands:  
    
  All possible rd registers are used.
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F002_S000_I000
* **Link to Coverage:** isacov.rv32i_jal_cg.cp_rd
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  jal rd, imm[20:1]  
  rd = pc+4; pc += Sext({imm[20:1], 1’b0})  
  pc is calculated using signed arithmetic  
    
  jal x0, imm[20:1] (special case: unconditional jump)  
  pc += Sext({imm[20:1], 1’b0})
* **Verification Goals**
  
  Input operands:  
    
  immj value is +ve, -ve, and zero  
  All bits of immj are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F002_S000_I001
* **Link to Coverage:** isacov.rv32i_jal_cg.cp_immj_value
isacov.rv32i_jal_cg.cp_immj_toggle
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  jal rd, imm[20:1]  
  rd = pc+4; pc += Sext({imm[20:1], 1’b0})  
  pc is calculated using signed arithmetic  
    
  jal x0, imm[20:1] (special case: unconditional jump)  
  pc += Sext({imm[20:1], 1’b0})
* **Verification Goals**
  
  Output result:  
    
  All bits of rd are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F002_S000_I002
* **Link to Coverage:** isacov.rv32i_jal_cg.cp_rd_toggle
* **Comments**
  
  *(none)*  
  
### Sub-feature: 001_JALR

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  jalr rd, rs1, imm[11:0]  
  rd = pc+4; pc = rs1 + Sext(imm[11:0])  
  pc is calculated using signed arithmetic
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
  All possible rd registers are used.  
  All possible register combinations where rs1 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F002_S001_I000
* **Link to Coverage:** isacov.rv32i_jalr_cg.cp_rs1
isacov.rv32i_jalr_cg.cp_rd
isacov.rv32i_jalr_cg.cp_rd_rs1_hazard
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  jalr rd, rs1, imm[11:0]  
  rd = pc+4; pc = rs1 + Sext(imm[11:0])  
  pc is calculated using signed arithmetic
* **Verification Goals**
  
  Input operands:  
    
  immi value is +ve, -ve, and zero  
  All bits of immi are toggled  
  All bits of rs1 are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F002_S001_I001
* **Link to Coverage:** isacov.rv32i_jalr_cg.cp_immi_value
isacov.rv32i_jalr_cg.cp_immi_toggle
isacov.rv32i_jalr_cg.cp_rs1_toggle
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  jalr rd, rs1, imm[11:0]  
  rd = pc+4; pc = rs1 + Sext(imm[11:0])  
  pc is calculated using signed arithmetic
* **Verification Goals**
  
  Output result:  
    
  All bits of rd are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F002_S001_I002
* **Link to Coverage:** isacov.rv32i_jalr_cg.cp_rd_toggle
* **Comments**
  
  *(none)*  
  
### Sub-feature: 002_BEQ

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  beq rs1, rs2, imm[12:1]  
  pc += Sext({imm[12:1], 1’b0}) if (rs1==rs2) else pc += 4  
  pc is calculated using signed arithmetic
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
  All possible rs2 registers are used.
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F002_S002_I000
* **Link to Coverage:** isacov.rv32i_beq_cg.cp_rs1
isacov.rv32i_beq_cg.cp_rs2
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  beq rs1, rs2, imm[12:1]  
  pc += Sext({imm[12:1], 1’b0}) if (rs1==rs2) else pc += 4  
  pc is calculated using signed arithmetic
* **Verification Goals**
  
  Input operands:  
    
  immb value is +ve, -ve, and zero  
  All bits of immb are toggled  
  All bits of rs1 are toggled  
  All bits of rs2 are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F002_S002_I001
* **Link to Coverage:** isacov.rv32i_beq_cg.cp_immb_value
isacov.rv32i_beq_cg.cp_rs1_toggle
isacov.rv32i_beq_cg.cp_rs2_toggle
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  beq rs1, rs2, imm[12:1]  
  pc += Sext({imm[12:1], 1’b0}) if (rs1==rs2) else pc += 4  
  pc is calculated using signed arithmetic
* **Verification Goals**
  
  Output result:  
    
  Branch taken or not-taken
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F002_S002_I002
* **Link to Coverage:** isacov.rv32i_beq_cg.cp_branch_taken
* **Comments**
  
  *(none)*  
  
### Sub-feature: 003_BNE

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  bne rs1, rs2, imm[12:1]  
  pc += Sext({imm[12:1], 1’b0}) if (rs1!=rs2) else pc += 4  
  pc is calculated using signed arithmetic
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
  All possible rs2 registers are used.
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F002_S003_I000
* **Link to Coverage:** isacov.rv32i_bne_cg.cp_rs1
isacov.rv32i_bne_cg.cp_rs2
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  bne rs1, rs2, imm[12:1]  
  pc += Sext({imm[12:1], 1’b0}) if (rs1!=rs2) else pc += 4  
  pc is calculated using signed arithmetic
* **Verification Goals**
  
  Input operands:  
    
  immb value is +ve, -ve, and zero  
  All bits of immb are toggled  
  All bits of rs1 are toggled  
  All bits of rs2 are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F002_S003_I001
* **Link to Coverage:** isacov.rv32i_bne_cg.cp_immb_value
isacov.rv32i_bne_cg.cp_rs1_toggle
isacov.rv32i_bne_cg.cp_rs2_toggle
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  bne rs1, rs2, imm[12:1]  
  pc += Sext({imm[12:1], 1’b0}) if (rs1!=rs2) else pc += 4  
  pc is calculated using signed arithmetic
* **Verification Goals**
  
  Output result:  
    
  Branch taken or not-taken
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F002_S003_I002
* **Link to Coverage:** isacov.rv32i_bne_cg.cp_branch_taken
* **Comments**
  
  *(none)*  
  
### Sub-feature: 004_BLT

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  blt rs1, rs2, imm[12:1]  
  pc += Sext({imm[12:1], 1’b0}) if (rs1 < rs2) else pc += 4  
  pc is calculated using signed arithmetic
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
  All possible rs2 registers are used.
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F002_S004_I000
* **Link to Coverage:** isacov.rv32i_blt_cg.cp_rs1
isacov.rv32i_blt_cg.cp_rs2
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  blt rs1, rs2, imm[12:1]  
  pc += Sext({imm[12:1], 1’b0}) if (rs1 < rs2) else pc += 4  
  pc is calculated using signed arithmetic
* **Verification Goals**
  
  Input operands:  
    
  immb value is +ve, -ve, and zero  
  All bits of immb are toggled  
  All bits of rs1 are toggled  
  All bits of rs2 are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F002_S004_I001
* **Link to Coverage:** isacov.rv32i_blt_cg.cp_immb_value
isacov.rv32i_blt_cg.cp_rs1_toggle
isacov.rv32i_blt_cg.cp_rs2_toggle
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  blt rs1, rs2, imm[12:1]  
  pc += Sext({imm[12:1], 1’b0}) if (rs1 < rs2) else pc += 4  
  pc is calculated using signed arithmetic
* **Verification Goals**
  
  Output result:  
    
  Branch taken or not-taken
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F002_S004_I002
* **Link to Coverage:** isacov.rv32i_blt_cg.cp_branch_taken
* **Comments**
  
  *(none)*  
  
### Sub-feature: 005_BGE

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  bge rs1, rs2, imm[12:1]  
  pc += Sext({imm[12:1], 1’b0}) if (rs1 >= rs2) else pc += 4  
  pc is calculated using signed arithmetic
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
  All possible rs2 registers are used.
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F002_S005_I000
* **Link to Coverage:** isacov.rv32i_bge_cg.cp_rs1
isacov.rv32i_bge_cg.cp_rs2
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  bge rs1, rs2, imm[12:1]  
  pc += Sext({imm[12:1], 1’b0}) if (rs1 >= rs2) else pc += 4  
  pc is calculated using signed arithmetic
* **Verification Goals**
  
  Input operands:  
    
  immb value is +ve, -ve, and zero  
  All bits of immb are toggled  
  All bits of rs1 are toggled  
  All bits of rs2 are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F002_S005_I001
* **Link to Coverage:** isacov.rv32i_bge_cg.cp_immb_value
isacov.rv32i_bge_cg.cp_rs1_toggle
isacov.rv32i_bge_cg.cp_rs2_toggle
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  bge rs1, rs2, imm[12:1]  
  pc += Sext({imm[12:1], 1’b0}) if (rs1 >= rs2) else pc += 4  
  pc is calculated using signed arithmetic
* **Verification Goals**
  
  Output result:  
    
  Branch taken or not-taken
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F002_S005_I002
* **Link to Coverage:** isacov.rv32i_bge_cg.cp_branch_taken
* **Comments**
  
  *(none)*  
  
### Sub-feature: 006_BLTU

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  bltu rs1, rs2, imm[12:1]  
  pc += Sext({imm[12:1], 1’b0}) if (rs1 < rs2) else pc += 4  
  pc is calculated using unsigned arithmetic
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
  All possible rs2 registers are used.
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F002_S006_I000
* **Link to Coverage:** isacov.rv32i_bltu_cg.cp_rs1
isacov.rv32i_bltu_cg.cp_rs2
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  bltu rs1, rs2, imm[12:1]  
  pc += Sext({imm[12:1], 1’b0}) if (rs1 < rs2) else pc += 4  
  pc is calculated using unsigned arithmetic
* **Verification Goals**
  
  Input operands:  
    
  immb value is +ve, -ve, and zero  
  All bits of immb are toggled  
  All bits of rs1 are toggled  
  All bits of rs2 are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F002_S006_I001
* **Link to Coverage:** isacov.rv32i_bltu_cg.cp_immb_value
isacov.rv32i_bltu_cg.cp_rs1_toggle
isacov.rv32i_bltu_cg.cp_rs2_toggle
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  bltu rs1, rs2, imm[12:1]  
  pc += Sext({imm[12:1], 1’b0}) if (rs1 < rs2) else pc += 4  
  pc is calculated using unsigned arithmetic
* **Verification Goals**
  
  Output result:  
    
  Branch taken or not-taken
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F002_S006_I002
* **Link to Coverage:** isacov.rv32i_bltu_cg.cp_branch_taken
* **Comments**
  
  *(none)*  
  
### Sub-feature: 007_BGEU

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  bgeu rs1, rs2, imm[12:1]  
  pc += Sext({imm[12:1], 1’b0}) if (rs1 >= rs2) else pc += 4  
  pc is calculated using unsigned arithmetic
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
  All possible rs2 registers are used.
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F002_S007_I000
* **Link to Coverage:** isacov.rv32i_bgeu_cg.cp_rs1
isacov.rv32i_bgeu_cg.cp_rs2
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  bgeu rs1, rs2, imm[12:1]  
  pc += Sext({imm[12:1], 1’b0}) if (rs1 >= rs2) else pc += 4  
  pc is calculated using unsigned arithmetic
* **Verification Goals**
  
  Input operands:  
    
  immb value is +ve, -ve, and zero  
  All bits of immb are toggled  
  All bits of rs1 are toggled  
  All bits of rs2 are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F002_S007_I001
* **Link to Coverage:** isacov.rv32i_bgeu_cg.cp_immb_value
isacov.rv32i_bgeu_cg.cp_rs1_toggle
isacov.rv32i_bgeu_cg.cp_rs2_toggle
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  bgeu rs1, rs2, imm[12:1]  
  pc += Sext({imm[12:1], 1’b0}) if (rs1 >= rs2) else pc += 4  
  pc is calculated using unsigned arithmetic
* **Verification Goals**
  
  Output result:  
    
  Branch taken or not-taken
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F002_S007_I002
* **Link to Coverage:** isacov.rv32i_bgeu_cg.cp_branch_taken
* **Comments**
  
  *(none)*  
  
## Feature: RV32I Load and Store Instructions

### Sub-feature: 000_LB

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  lb rd, rs1, imm  
  rd = Sext(M[rs1+imm][0:7])  
  rd is calculated using signed arithmetic
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
  All possible rd registers are used.  
  All possible register combinations where rs1 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F003_S000_I000
* **Link to Coverage:** isacov.rv32i_lb_cg.cp_rs1
isacov.rv32i_lb_cg.cp_rd
isacov.rv32i_lb_cg.cp_rd_rs1_hazard
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  lb rd, rs1, imm  
  rd = Sext(M[rs1+imm][0:7])  
  rd is calculated using signed arithmetic
* **Verification Goals**
  
  Input operands:  
    
  immi value is +ve, -ve and zero  
  All combinations of rs1 and immi +ve, -ve, and zero values are used  
  All bits of rs1 are toggled  
  All bits of immi are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F003_S000_I001
* **Link to Coverage:** isacov.rv32i_lb_cg.cp_immi_value
isacov.rv32i_lb_cg.cp_rs1_toggle
isacov.rv32i_lb_cg.cp_immi_toggle
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  lb rd, rs1, imm  
  rd = Sext(M[rs1+imm][0:7])  
  rd is calculated using signed arithmetic
* **Verification Goals**
  
  Output result:  
    
  rd value is +ve, -ve and zero  
  All bits of rd are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F003_S000_I002
* **Link to Coverage:** isacov.rv32i_lb_cg.cp_rd_value
isacov.rv32i_lb_cg.cp_rd_toggle
* **Comments**
  
  *(none)*  
  
### Sub-feature: 001_LH

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  lh rd, rs1, imm  
  rd = Sext(M[rs1+imm][0:15])  
  rd is calculated using signed arithmetic
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
  All possible rd registers are used.  
  All possible register combinations where rs1 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F003_S001_I000
* **Link to Coverage:** isacov.rv32i_lh_cg.cp_rs1
isacov.rv32i_lh_cg.cp_rd
isacov.rv32i_lh_cg.cp_rd_rs1_hazard
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  lh rd, rs1, imm  
  rd = Sext(M[rs1+imm][0:15])  
  rd is calculated using signed arithmetic
* **Verification Goals**
  
  Input operands:  
    
  immi value is +ve, -ve and zero  
  All combinations of rs1 and immi +ve, -ve, and zero values are used  
  All bits of rs1 are toggled  
  All bits of immi are toggled  
  Unaligned and aligned accesses from memory
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F003_S001_I001
* **Link to Coverage:** isacov.rv32i_lh_cg.cp_immi_value
isacov.rv32i_lh_cg.cp_rs1_toggle
isacov.rv32i_lh_cg.cp_immi_toggle
isacov.rv32i_lh_cg.cp_aligned
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  lh rd, rs1, imm  
  rd = Sext(M[rs1+imm][0:15])  
  rd is calculated using signed arithmetic
* **Verification Goals**
  
  Output result:  
    
  rd value is +ve, -ve and zero  
  All bits of rd are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F003_S001_I002
* **Link to Coverage:** isacov.rv32i_lh_cg.cp_rd_value
isacov.rv32i_lh_cg.cp_rd_toggle
* **Comments**
  
  *(none)*  
  
### Sub-feature: 002_LW

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  lw rd, rs1, imm  
  rd = Sext(M[rs1+imm][0:31])  
  rd is calculated using signed arithmetic
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
  All possible rd registers are used.  
  All possible register combinations where rs1 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F003_S002_I000
* **Link to Coverage:** isacov.rv32i_lw_cg.cp_rs1
isacov.rv32i_lw_cg.cp_rd
isacov.rv32i_lw_cg.cp_rd_rs1_hazard
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  lw rd, rs1, imm  
  rd = Sext(M[rs1+imm][0:31])  
  rd is calculated using signed arithmetic
* **Verification Goals**
  
  Input operands:  
    
  immi value is +ve, -ve and zero  
  All combinations of rs1 and immi +ve, -ve, and zero values are used  
  All bits of rs1 are toggled  
  All bits of immi are toggled  
  Unaligned and aligned accesses from memory
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F003_S002_I001
* **Link to Coverage:** isacov.rv32i_lw_cg.cp_immi_value
isacov.rv32i_lw_cg.cp_rs1_toggle
isacov.rv32i_lw_cg.cp_immi_toggle
isacov.rv32i_lw_cg.cp_aligned
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  lw rd, rs1, imm  
  rd = Sext(M[rs1+imm][0:31])  
  rd is calculated using signed arithmetic
* **Verification Goals**
  
  Output result:  
    
  rd value is +ve, -ve and zero  
  All bits of rd are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F003_S002_I002
* **Link to Coverage:** isacov.rv32i_lw_cg.cp_rd_value
isacov.rv32i_lw_cg.cp_rd_toggle
* **Comments**
  
  *(none)*  
  
### Sub-feature: 003_LBU

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  lbu rd, rs1, imm  
  rd = Zext(M[rs1+imm][0:7])  
  rd is calculated using unsigned arithmetic
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
  All possible rd registers are used.  
  All possible register combinations where rs1 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F003_S003_I000
* **Link to Coverage:** isacov.rv32i_lbu_cg.cp_rs1
isacov.rv32i_lbu_cg.cp_rd
isacov.rv32i_lbu_cg.cp_rd_rs1_hazard
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  lbu rd, rs1, imm  
  rd = Zext(M[rs1+imm][0:7])  
  rd is calculated using unsigned arithmetic
* **Verification Goals**
  
  Input operands:  
    
  immi value is +ve, -ve and zero  
  All combinations of rs1 and immi +ve, -ve, and zero values are used  
  All bits of rs1 are toggled  
  All bits of immi are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F003_S003_I001
* **Link to Coverage:** isacov.rv32i_lbu_cg.cp_immi_value
isacov.rv32i_lbu_cg.cp_rs1_toggle
isacov.rv32i_lbu_cg.cp_immi_toggle
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  lbu rd, rs1, imm  
  rd = Zext(M[rs1+imm][0:7])  
  rd is calculated using unsigned arithmetic
* **Verification Goals**
  
  Output result:  
    
  rd value is +ve, -ve and zero  
  All bits of rd[7:0] are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F003_S003_I002
* **Link to Coverage:** isacov.rv32i_lbu_cg.cp_rd_value
isacov.rv32i_lbu_cg.cp_rd_toggle
* **Comments**
  
  *(none)*  
  
### Sub-feature: 004_LHU

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  lhu rd, rs1, imm  
  rd = Zext(M[rs1+imm][0:15])  
  rd is calculated using unsigned arithmetic
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
  All possible rd registers are used.  
  All possible register combinations where rs1 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F003_S004_I000
* **Link to Coverage:** isacov.rv32i_lhu_cg.cp_rs1
isacov.rv32i_lhu_cg.cp_rd
isacov.rv32i_lhu_cg.cp_rd_rs1_hazard
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  lhu rd, rs1, imm  
  rd = Zext(M[rs1+imm][0:15])  
  rd is calculated using unsigned arithmetic
* **Verification Goals**
  
  Input operands:  
    
  immi value is +ve, -ve and zero  
  All combinations of rs1 and immi +ve, -ve, and zero values are used  
  All bits of rs1 are toggled  
  All bits of immi are toggled  
  Unaligned and aligned accesses from memory
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F003_S004_I001
* **Link to Coverage:** isacov.rv32i_lhu_cg.cp_immi_value
isacov.rv32i_lhu_cg.cp_rs1_toggle
isacov.rv32i_lhu_cg.cp_immi_toggle
isacov.rv32i_lhu_cg.cp_aligned
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  lhu rd, rs1, imm  
  rd = Zext(M[rs1+imm][0:15])  
  rd is calculated using unsigned arithmetic
* **Verification Goals**
  
  Output result:  
    
  rd value is +ve, -ve and zero  
  All bits of rd[15:0] are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F003_S004_I002
* **Link to Coverage:** isacov.rv32i_lhu_cg.cp_rd_value
isacov.rv32i_lhu_cg.cp_rd_toggle
* **Comments**
  
  *(none)*  
  
### Sub-feature: 005_SB

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  sb rs1, rs2, imm  
  M[rs1+imm][0:7] = rs2[0:7]
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
  All possible rs2 registers are used.
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F003_S005_I000
* **Link to Coverage:** isacov.rv32i_sb_cg.cp_rs1
isacov.rv32i_sb_cg.cp_rs2
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  sb rs1, rs2, imm  
  M[rs1+imm][0:7] = rs2[0:7]
* **Verification Goals**
  
  Input operands:  
    
  imms value is +ve, -ve and zero  
  All bits of rs1 are toggled  
  All bits of rs2 are toggled  
  All bits of imms are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F003_S005_I001
* **Link to Coverage:** isacov.rv32i_sb_cg.cp_imms_value
isacov.rv32i_sb_cg.cp_rs1_toggle
isacov.rv32i_sb_cg.cp_rs2_toggle
isacov.rv32i_sb_cg.cp_imms_toggle
* **Comments**
  
  *(none)*  
  
### Sub-feature: 006_SH

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  sh rs1, rs2, imm  
  M[rs1+imm][0:15] = rs2[0:15]
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
  All possible rs2 registers are used.
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F003_S006_I000
* **Link to Coverage:** isacov.rv32i_sh_cg.cp_rs1
isacov.rv32i_sh_cg.cp_rs2
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  sh rs1, rs2, imm  
  M[rs1+imm][0:15] = rs2[0:15]
* **Verification Goals**
  
  Input operands:  
    
  imms value is +ve, -ve and zero  
  All bits of rs1 are toggled  
  All bits of rs2 are toggled  
  All bits of imms are toggled  
  Unaligned and aligned accesses to memory
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F003_S006_I001
* **Link to Coverage:** isacov.rv32i_sh_cg.cp_imms_value
isacov.rv32i_sh_cg.cp_rs1_toggle
isacov.rv32i_sh_cg.cp_rs2_toggle
isacov.rv32i_sh_cg.cp_imms_toggle
isacov.rv32i_sh_cg.cp_aligned
* **Comments**
  
  *(none)*  
  
### Sub-feature: 007_SW

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  sw rs1, rs2, imm  
  M[rs1+imm][0:31] = rs2[0:31]
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
  All possible rs2 registers are used.
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F003_S007_I000
* **Link to Coverage:** isacov.rv32i_sw_cg.cp_rs1
isacov.rv32i_sw_cg.cp_rs2
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  sw rs1, rs2, imm  
  M[rs1+imm][0:31] = rs2[0:31]
* **Verification Goals**
  
  Input operands:  
    
  imms value is +ve, -ve and zero  
  All bits of rs1 are toggled  
  All bits of rs2 are toggled  
  All bits of imms are toggled  
  Unaligned and aligned accesses to memory
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F003_S007_I001
* **Link to Coverage:** isacov.rv32i_sw_cg.cp_imms_value
isacov.rv32i_sw_cg.cp_rs1_toggle
isacov.rv32i_sw_cg.cp_rs2_toggle
isacov.rv32i_sw_cg.cp_imms_toggle
isacov.rv32i_sw_cg.cp_aligned
* **Comments**
  
  *(none)*  
  
## Feature: RV32I Memory Ordering Instructions

### Sub-feature: 000_FENCE

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  Fence operation executed  
  Implementation is microarchitecture specific
* **Verification Goals**
  
  Instruction executed
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F004_S000_I000
* **Link to Coverage:** isacov.rv32i_fence.cp_fixed
* **Comments**
  
  *(none)*  
  
## Feature: RV32I Environment Call and Breakpoints

### Sub-feature: 000_ECALL

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  Software exception vector entered
* **Verification Goals**
  
  Instruction executed
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F005_S000_I000
* **Link to Coverage:** isacov.rv32i_ecall.cp_fixed
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  Return control to a debugger
* **Verification Goals**
  
  Instruction executed
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F005_S000_I001
* **Link to Coverage:** isacov.rv32i_ebreak.cp_fixed
* **Comments**
  
  *(none)*  
  
### Sub-feature: 001_EBREAK

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  Return control to a debugger
* **Verification Goals**
  
  Instruction executed
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F005_S001_I000
* **Link to Coverage:** isacov.rv32i_ebreak.cp_fixed
* **Comments**
  
  *(none)*  
  
## Feature: RV32M Multiplication Operations

### Sub-feature: 000_MUL

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  mul rd, rs1, rs2  
  x[rd] = x[rs1] * x[rs2]  
  Arithmetic overflow is ignored.
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
  All possible rs2 registers are used.  
  All possible rd registers are used.  
  All possible register combinations where rs1 == rd are used  
  All possible register combinations where rs2 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F006_S000_I000
* **Link to Coverage:** isacov.rv32m_mul_cg.cp_rs1
isacov.rv32m_mul_cg.cp_rs2
isacov.rv32m_mul_cg.cp_rd
isacov.rv32m_mul_cg.cp_rd_rs1_hazard
isacov.rv32m_mul_cg.cp_rd_rs2_hazard
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  mul rd, rs1, rs2  
  x[rd] = x[rs1] * x[rs2]  
  Arithmetic overflow is ignored.
* **Verification Goals**
  
  Input operands:  
    
  rs1 value is non-zero and zero  
  rs2 value is non-zero and zero  
  All combinations of rs1 and rs2 non-zero and zero values are used  
  All bits of rs1 are toggled  
  All bits of rs2 are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F006_S000_I001
* **Link to Coverage:** isacov.rv32m_mul_cg.cp_rs1_value
isacov.rv32m_mul_cg.cp_rs2_value
isacov.rv32m_mul_cg.cross_rs1_rs2_value
isacov.rv32m_mul_cg.cp_rs1_toggle 
isacov.rv32m_mul_cg.cp_rs2_toggle
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  mul rd, rs1, rs2  
  x[rd] = x[rs1] * x[rs2]  
  Arithmetic overflow is ignored.
* **Verification Goals**
  
  Output result:  
    
  rd value is non-zero and zero  
  All bits of rd are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F006_S000_I002
* **Link to Coverage:** isacov.rv32m_mul_cg.cp_rd_value
isacov.rv32m_mul_cg.cp_rd_toggle
* **Comments**
  
  *(none)*  
  
### Sub-feature: 001_MULH

#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  mulh rd, rs1, rs2  
  x[rd] = (x[rs1] * x[rs2]) >>s XLEN  
  Both rs1 and rs2 treated as signed numbers
* **Verification Goals**
  
  Output result:  
    
  rd value is +ve, -ve and zero  
  All bits of rd are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F006_S001_I002
* **Link to Coverage:** isacov.rv32m_mulh_cg.cp_rd_value
isacov.rv32m_mulh_cg.cp_rd_toggle
* **Comments**
  
  *(none)*  
  
### Sub-feature: 002_MULHU

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  mulhu rd, rs1, rs2  
  x[rd] = (x[rs1] * x[rs2]) >> XLEN  
  Both rs1 and rs2 treated as unsigned numbers
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
  All possible rs2 registers are used.  
  All possible rd registers are used.  
  All possible register combinations where rs1 == rd are used  
  All possible register combinations where rs2 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F006_S002_I000
* **Link to Coverage:** isacov.rv32m_mulhu_cg.cp_rs1
isacov.rv32m_mulhu_cg.cp_rs2
isacov.rv32m_mulhu_cg.cp_rd
isacov.rv32m_mulhu_cg.cp_rd_rs1_hazard
isacov.rv32m_mulhu_cg.cp_rd_rs2_hazard
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  mulhu rd, rs1, rs2  
  x[rd] = (x[rs1] * x[rs2]) >> XLEN  
  Both rs1 and rs2 treated as unsigned numbers
* **Verification Goals**
  
  Input operands:  
    
  rs1 value is non-zero and zero  
  rs2 value is non-zero and zero  
  All combinations of rs1 and rs2 non-zero and zero values are used  
  All bits of rs1 are toggled  
  All bits of rs2 are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F006_S002_I001
* **Link to Coverage:** isacov.rv32m_mulhu_cg.cp_rs1_value
isacov.rv32m_mulhu_cg.cp_rs2_value
isacov.rv32m_mulhu_cg.cross_rs1_rs2_value
isacov.rv32m_mulhu_cg.cp_rs1_toggle 
isacov.rv32m_mulhu_cg.cp_rs2_toggle
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  mulhu rd, rs1, rs2  
  x[rd] = (x[rs1] * x[rs2]) >> XLEN  
  Both rs1 and rs2 treated as unsigned numbers
* **Verification Goals**
  
  Output result:  
    
  rd value is non-zero and zero  
  All bits of rd are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F006_S002_I002
* **Link to Coverage:** isacov.rv32m_mulhu_cg.cp_rd_value
isacov.rv32m_mulhu_cg.cp_rd_toggle
* **Comments**
  
  *(none)*  
  
### Sub-feature: 003_MULHSU

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  mulhsu rd, rs1, rs2  
  x[rd] = (x[rs1] * x[rs2]) >>s XLEN  
  rs1 treated as signed number, rs2 treated as unsigned number
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
  All possible rs2 registers are used.  
  All possible rd registers are used.  
  All possible register combinations where rs1 == rd are used  
  All possible register combinations where rs2 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F006_S003_I000
* **Link to Coverage:** isacov.rv32m_mulhsu_cg.cp_rs1
isacov.rv32m_mulhsu_cg.cp_rs2
isacov.rv32m_mulhsu_cg.cp_rd
isacov.rv32m_mulhsu_cg.cp_rd_rs1_hazard
isacov.rv32m_mulhsu_cg.cp_rd_rs2_hazard
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  mulhsu rd, rs1, rs2  
  x[rd] = (x[rs1] * x[rs2]) >>s XLEN  
  rs1 treated as signed number, rs2 treated as unsigned number
* **Verification Goals**
  
  Input operands:  
    
  rs1 value is +ve, -ve and zero  
  rs2 value is non-zero and zero  
  All combinations of rs1 and rs2 +ve, -ve, and zero values are used  
  All bits of rs1 are toggled  
  All bits of rs2 are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F006_S003_I001
* **Link to Coverage:** isacov.rv32m_mulhsu_cg.cp_rs1_value
isacov.rv32m_mulhsu_cg.cp_rs2_value
isacov.rv32m_mulhsu_cg.cross_rs1_rs2_value
isacov.rv32m_mulhsu_cg.cp_rs1_toggle 
isacov.rv32m_mulhsu_cg.cp_rs2_toggle
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  mulhsu rd, rs1, rs2  
  x[rd] = (x[rs1] * x[rs2]) >>s XLEN  
  rs1 treated as signed number, rs2 treated as unsigned number
* **Verification Goals**
  
  Output result:  
    
  rd value is +ve, -ve and zero  
  All bits of rd are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F006_S003_I002
* **Link to Coverage:** isacov.rv32m_mulhsu_cg.cp_rd_value
isacov.rv32m_mulhsu_cg.cp_rd_toggle
* **Comments**
  
  *(none)*  
  
## Feature: RV32M Division Operations

### Sub-feature: 000_DIV

#### Item: 000

* **Requirement location:** Unprivileged ISA
Chapter 7.2
* **Feature Description**
  
  div rd, rs1, rs2  
  x[rd] = x[rs1] / x[rs2]  
  rd is calculated using signed arithmetic; rounding towards zero
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
  All possible rs2 registers are used.  
  All possible rd registers are used.  
  All possible register combinations where rs1 == rd are used  
  All possible register combinations where rs2 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F007_S000_I000
* **Link to Coverage:** isacov.rv32m_div_cg.cp_rs1
isacov.rv32m_div_cg.cp_rs2
isacov.rv32m_div_cg.cp_rd
isacov.rv32m_div_cg.cp_rd_rs1_hazard
isacov.rv32m_div_cg.cp_rd_rs2_hazard
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** Unprivileged ISA
Chapter 7.2
* **Feature Description**
  
  div rd, rs1, rs2  
  x[rd] = x[rs1] / x[rs2]  
  rd is calculated using signed arithmetic; rounding towards zero
* **Verification Goals**
  
  Input operands:  
    
  rs1 value is +ve, -ve and zero  
  rs2 value is +ve, -ve and zero  
  All combinations of rs1 and rs2 +ve, -ve, and zero values are used  
  All bits of rs1 are toggled  
  All bits of rs2 are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F007_S000_I001
* **Link to Coverage:** isacov.rv32m_div_cg.cp_rs1_value
isacov.rv32m_div_cg.cp_rs2_value
isacov.rv32m_div_cg.cross_rs1_rs2_value
isacov.rv32m_div_cg.cp_rs1_toggle 
isacov.rv32m_div_cg.cp_rs2_toggle
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** Unprivileged ISA
Chapter 7.2
* **Feature Description**
  
  div rd, rs1, rs2  
  x[rd] = x[rs1] / x[rs2]  
  rd is calculated using signed arithmetic; rounding towards zero
* **Verification Goals**
  
  Output result:  
    
  rd value is +ve, -ve and zero  
  All bits of rd are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F007_S000_I002
* **Link to Coverage:** isacov.rv32m_div_cg.cp_rs1_value
isacov.rv32m_div_cg.cp_rs2_value
isacov.rv32m_div_cg.cross_rs1_rs2_value
isacov.rv32m_div_cg.cp_rs1_toggle 
isacov.rv32m_div_cg.cp_rs2_toggle
* **Comments**
  
  *(none)*  
  
#### Item: 003

* **Requirement location:** Unprivileged ISA
Chapter 7.2
* **Feature Description**
  
  div rd, rs1, rs2  
  x[rd] = x[rs1] / x[rs2]  
  rd is calculated using signed arithmetic; rounding towards zero
* **Verification Goals**
  
  Exercise arithmetic overflow (rs1 = -2^31; rs2 = -1; returns rd = -2^31).  
  Exercise division by zero (returns -1 ; all bits set)
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F007_S000_I003
* **Link to Coverage:** isacov.rv32m_div_results_cg.cp_div_special_results
isacov.rv32m_div_results_cg.cp_div_arithmetic_overflow
* **Comments**
  
  *(none)*  
  
### Sub-feature: 001_REM

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  rem rd, rs1, rs2  
  x[rd] = x[rs1] % x[rs2]  
  rd is calculated using signed arithmetic; remainder from the same division than DIV (the sign of rd equals the sign of rs1)
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
  All possible rs2 registers are used.  
  All possible rd registers are used.  
  All possible register combinations where rs1 == rd are used  
  All possible register combinations where rs2 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F007_S001_I000
* **Link to Coverage:** isacov.rv32m_rem_cg.cp_rs1
isacov.rv32m_rem_cg.cp_rs2
isacov.rv32m_rem_cg.cp_rd
isacov.rv32m_rem_cg.cp_rd_rs1_hazard
isacov.rv32m_rem_cg.cp_rd_rs2_hazard
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  rem rd, rs1, rs2  
  x[rd] = x[rs1] % x[rs2]  
  rd is calculated using signed arithmetic; remainder from the same division than DIV (the sign of rd equals the sign of rs1)
* **Verification Goals**
  
  Input operands:  
    
  rs1 value is +ve, -ve and zero  
  rs2 value is +ve, -ve and zero  
  All combinations of rs1 and rs2 +ve, -ve, and zero values are used  
  All bits of rs1 are toggled  
  All bits of rs2 are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F007_S001_I001
* **Link to Coverage:** isacov.rv32m_rem_cg.cp_rs1_value
isacov.rv32m_rem_cg.cp_rs2_value
isacov.rv32m_rem_cg.cross_rs1_rs2_value
isacov.rv32m_rem_cg.cp_rs1_toggle 
isacov.rv32m_rem_cg.cp_rs2_toggle
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  rem rd, rs1, rs2  
  x[rd] = x[rs1] % x[rs2]  
  rd is calculated using signed arithmetic; remainder from the same division than DIV (the sign of rd equals the sign of rs1)
* **Verification Goals**
  
  Output result:  
    
  rd value is +ve, -ve and zero  
  All bits of rd are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F007_S001_I002
* **Link to Coverage:** isacov.rv32m_rem_cg.cp_rd_value
isacov.rv32m_rem_cg.cp_rd_toggle
* **Comments**
  
  *(none)*  
  
#### Item: 003

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  rem rd, rs1, rs2  
  x[rd] = x[rs1] % x[rs2]  
  rd is calculated using signed arithmetic; remainder from the same division than DIV (the sign of rd equals the sign of rs1)
* **Verification Goals**
  
  Exercise arithmetic overflow (rs1 = -2^31; rs2 = -1; returns rd = 0).  
  Exercise division by zero (returns rs1)
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F007_S001_I003
* **Link to Coverage:** isacov.rv32m_rem_results_cg.cp_div_zero
isacov.rv32m_rem_results_cg.cp_div_arithmetic_overflow
* **Comments**
  
  *(none)*  
  
### Sub-feature: 002_DIVU

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  divu rd, rs1, rs2  
  x[rd] = x[rs1] u/ x[rs2]  
  rd is calculated using unsigned arithmetic; rounding towards zero
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
  All possible rs2 registers are used.  
  All possible rd registers are used.  
  All possible register combinations where rs1 == rd are used  
  All possible register combinations where rs2 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F007_S002_I000
* **Link to Coverage:** isacov.rv32m_divu_cg.cp_rs1
isacov.rv32m_divu_cg.cp_rs2
isacov.rv32m_divu_cg.cp_rd
isacov.rv32m_divu_cg.cp_rd_rs1_hazard
isacov.rv32m_divu_cg.cp_rd_rs2_hazard
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  divu rd, rs1, rs2  
  x[rd] = x[rs1] u/ x[rs2]  
  rd is calculated using unsigned arithmetic; rounding towards zero
* **Verification Goals**
  
  Input operands:  
    
  rs1 value is non-zero and zero  
  rs2 value is non-zero and zero  
  All combinations of rs1 and rs2 non-zero and zero values are used  
  All bits of rs1 are toggled  
  All bits of rs2 are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F007_S002_I001
* **Link to Coverage:** isacov.rv32m_divu_cg.cp_rs1_value
isacov.rv32m_divu_cg.cp_rs2_value
isacov.rv32m_divu_cg.cross_rs1_rs2_value
isacov.rv32m_divu_cg.cp_rs1_toggle 
isacov.rv32m_divu_cg.cp_rs2_toggle
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  divu rd, rs1, rs2  
  x[rd] = x[rs1] u/ x[rs2]  
  rd is calculated using unsigned arithmetic; rounding towards zero
* **Verification Goals**
  
  Output result:  
    
  rd value is non-zero and zero  
  All bits of rd are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F007_S002_I002
* **Link to Coverage:** isacov.rv32m_divu_cg.cp_rd_value
isacov.rv32m_divu_cg.cp_rd_toggle
* **Comments**
  
  *(none)*  
  
#### Item: 003

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  divu rd, rs1, rs2  
  x[rd] = x[rs1] u/ x[rs2]  
  rd is calculated using unsigned arithmetic; rounding towards zero
* **Verification Goals**
  
  Exercise division by zero (returns 2^32-1 ; all bits set)
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F007_S002_I003
* **Link to Coverage:** isacov.rv32m_divu_results_cg.cp_div_zero
* **Comments**
  
  *(none)*  
  
### Sub-feature: 003_REMU

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  remu rd, rs1, rs2  
  x[rd] = x[rs1] % x[rs2]  
  rd is calculated using unsigned arithmetic; remainder from the same division than DIVU
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
  All possible rs2 registers are used.  
  All possible rd registers are used.  
  All possible register combinations where rs1 == rd are used  
  All possible register combinations where rs2 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F007_S003_I000
* **Link to Coverage:** isacov.rv32m_remu_cg.cp_rs1
isacov.rv32m_remu_cg.cp_rs2
isacov.rv32m_remu_cg.cp_rd
isacov.rv32m_remu_cg.cp_rd_rs1_hazard
isacov.rv32m_remu_cg.cp_rd_rs2_hazard
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  remu rd, rs1, rs2  
  x[rd] = x[rs1] % x[rs2]  
  rd is calculated using unsigned arithmetic; remainder from the same division than DIVU
* **Verification Goals**
  
  Input operands:  
    
  rs1 value is non-zero and zero  
  rs2 value is non-zero and zero  
  All combinations of rs1 and rs2 non-zero and zero values are used  
  All bits of rs1 are toggled  
  All bits of rs2 are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F007_S003_I001
* **Link to Coverage:** isacov.rv32m_remu_cg.cp_rs1_value
isacov.rv32m_remu_cg.cp_rs2_value
isacov.rv32m_remu_cg.cross_rs1_rs2_value
isacov.rv32m_remu_cg.cp_rs1_toggle 
isacov.rv32m_remu_cg.cp_rs2_toggle
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  remu rd, rs1, rs2  
  x[rd] = x[rs1] % x[rs2]  
  rd is calculated using unsigned arithmetic; remainder from the same division than DIVU
* **Verification Goals**
  
  Output result:  
    
  rd value is non-zero and zero  
  All bits of rd are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F007_S003_I002
* **Link to Coverage:** isacov.rv32m_remu_cg.cp_rd_value
isacov.rv32m_remu_cg.cp_rd_toggle
* **Comments**
  
  *(none)*  
  
#### Item: 003

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  remu rd, rs1, rs2  
  x[rd] = x[rs1] % x[rs2]  
  rd is calculated using unsigned arithmetic; remainder from the same division than DIVU
* **Verification Goals**
  
  Exercise division by zero (returns rs1)
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F007_S003_I003
* **Link to Coverage:** isacov.rv32m_remu_results_cg.cp_div_zero
* **Comments**
  
  *(none)*  
  
## Feature: RV32A Load-Reserved/Store-Conditional Instructions

### Sub-feature: 000_LR.W

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  lr.w rd, (rs1)  
  rd = [rs1]  
  A load occurs to address at rs1 with the results loaded to rd.  
  Misaligned address should cause an exception
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
  All possible rd registers are used.  
  All possible register combinations where rs1 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F008_S000_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  lr.w rd, (rs1)  
  rd = [rs1]  
  A load occurs to address at rs1 with the results loaded to rd.  
  Misaligned address should cause an exception
* **Verification Goals**
  
  Input operands:  
    
  All bits of rs1 are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F008_S000_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  lr.w rd, (rs1)  
  rd = [rs1]  
  A load occurs to address at rs1 with the results loaded to rd.  
  Misaligned address should cause an exception
* **Verification Goals**
  
  Output result:  
    
  All bits of rd are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F008_S000_I002
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 003

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  lr.w rd, (rs1)  
  rd = [rs1]  
  A load occurs to address at rs1 with the results loaded to rd.  
  Misaligned address should cause an exception
* **Verification Goals**
  
  Exception:  
    
  Misaligned address (non-32-bit aligned) will always cause exception
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F008_S000_I003
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 001_SC.W

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  sc.w rd, rs2, (rs1)  
  [rs1] = rs2  
  rd = exokay ? 0 : 1  
  A store occurs to address at rs1  with data from rs2.  
  If the reservation set from a previous LR.W fails, then rd is set to a non-zero value and the store does not occur.  
  If the reservation set passes, then rd is set to a zero-value and the store succeeds.
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
  All possible rd registers are used.  
  All possible register combinations where rs1 == rd are used  
  All possible register combinations where rs2 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F008_S001_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  sc.w rd, rs2, (rs1)  
  [rs1] = rs2  
  rd = exokay ? 0 : 1  
  A store occurs to address at rs1  with data from rs2.  
  If the reservation set from a previous LR.W fails, then rd is set to a non-zero value and the store does not occur.  
  If the reservation set passes, then rd is set to a zero-value and the store succeeds.
* **Verification Goals**
  
  Input operands:  
    
  All bits of rs1 are toggled  
  All bits of rs2 are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F008_S001_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  sc.w rd, rs2, (rs1)  
  [rs1] = rs2  
  rd = exokay ? 0 : 1  
  A store occurs to address at rs1  with data from rs2.  
  If the reservation set from a previous LR.W fails, then rd is set to a non-zero value and the store does not occur.  
  If the reservation set passes, then rd is set to a zero-value and the store succeeds.
* **Verification Goals**
  
  Output result:  
    
  rd is either zero or non-zero to indicate success or failure, respectively
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F008_S001_I002
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 003

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  sc.w rd, rs2, (rs1)  
  [rs1] = rs2  
  rd = exokay ? 0 : 1  
  A store occurs to address at rs1  with data from rs2.  
  If the reservation set from a previous LR.W fails, then rd is set to a non-zero value and the store does not occur.  
  If the reservation set passes, then rd is set to a zero-value and the store succeeds.
* **Verification Goals**
  
  Exception:  
    
  Misaligned address (non-32-bit aligned) will always cause exception
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F008_S001_I003
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
## Feature: RV32A Atomic Memory Operations

### Sub-feature: 000_AMOSWAP.W

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  amoswap.w rd, rs2, (rs1)  
  rd = [rs1]  
  [rs1] = rs2  
  A load occurs from the address at rs1 into rd.  
  The value at rs2 is then written back to the address at (rs1)
* **Verification Goals**
  
  Input operands:  
    
  All possible rs1 registers are used.  
  All possible rs2 registers are used.  
  All possible rd registers are used.  
  All possible register combinations where rs1 == rd are used  
  All possible register combinations where rs2 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F009_S000_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  amoswap.w rd, rs2, (rs1)  
  rd = [rs1]  
  [rs1] = rs2  
  A load occurs from the address at rs1 into rd.  
  The value at rs2 is then written back to the address at (rs1)
* **Verification Goals**
  
  Input operands:  
    
  All bits of rs1 are toggled  
  All bits of rs2 are toggled  
  Zero and non-zero values of rs2 are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F009_S000_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  amoswap.w rd, rs2, (rs1)  
  rd = [rs1]  
  [rs1] = rs2  
  A load occurs from the address at rs1 into rd.  
  The value at rs2 is then written back to the address at (rs1)
* **Verification Goals**
  
  Output result:   
    
  All bits of rd are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F009_S000_I002
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 003

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  amoswap.w rd, rs2, (rs1)  
  rd = [rs1]  
  [rs1] = rs2  
  A load occurs from the address at rs1 into rd.  
  The value at rs2 is then written back to the address at (rs1)
* **Verification Goals**
  
  Exception:  
    
  Misaligned address (non-32-bit aligned) will always cause exception
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F009_S000_I003
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 001_AMOADD.W

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  amoadd.w rd, rs2, (rs1)  
  rd = [rs1]  
  [rs1] = rs2 + [rs1]  
  A load occurs from the address at rs1 into rd.  
  The values in rd and rs2 and added using signed arithmetic and the result iis then written back to the address at (rs1)
* **Verification Goals**
  
  Input operands:  
    
  All possible rs1 registers are used.  
  All possible rs2 registers are used.  
  All possible rd registers are used.  
  All possible register combinations where rs1 == rd are used  
  All possible register combinations where rs2 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F009_S001_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  amoadd.w rd, rs2, (rs1)  
  rd = [rs1]  
  [rs1] = rs2 + [rs1]  
  A load occurs from the address at rs1 into rd.  
  The values in rd and rs2 and added using signed arithmetic and the result iis then written back to the address at (rs1)
* **Verification Goals**
  
  Input operands:  
    
  All bits of rs1 are toggled  
  All bits of rs2 are toggled  
  +ve, -ve and zero values of rs2 are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F009_S001_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  amoadd.w rd, rs2, (rs1)  
  rd = [rs1]  
  [rs1] = rs2 + [rs1]  
  A load occurs from the address at rs1 into rd.  
  The values in rd and rs2 and added using signed arithmetic and the result iis then written back to the address at (rs1)
* **Verification Goals**
  
  Output result:   
    
  +ve, -ve and zero values of rd are used  
  All bits of rd are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F009_S001_I002
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 003

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  amoadd.w rd, rs2, (rs1)  
  rd = [rs1]  
  [rs1] = rs2 + [rs1]  
  A load occurs from the address at rs1 into rd.  
  The values in rd and rs2 and added using signed arithmetic and the result iis then written back to the address at (rs1)
* **Verification Goals**
  
  Exception:  
    
  Misaligned address (non-32-bit aligned) will always cause exception
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F009_S001_I003
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 002_AMOAND.W

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  amoand.w rd, rs2, (rs1)  
  rd = [rs1]  
  [rs1] = rs2 & rs[1]  
  A load occurs from the address at rs1 into rd.  
  The values in rd and rs2 and bit-wise ANDed and the result iis then written back to the address at (rs1)
* **Verification Goals**
  
  Input operands:  
    
  All possible rs1 registers are used.  
  All possible rs2 registers are used.  
  All possible rd registers are used.  
  All possible register combinations where rs1 == rd are used  
  All possible register combinations where rs2 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F009_S002_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  amoand.w rd, rs2, (rs1)  
  rd = [rs1]  
  [rs1] = rs2 & rs[1]  
  A load occurs from the address at rs1 into rd.  
  The values in rd and rs2 and bit-wise ANDed and the result iis then written back to the address at (rs1)
* **Verification Goals**
  
  Input operands:  
    
  All bits of rs1 are toggled  
  All bits of rs2 are toggled  
  Zero and non-zero values of rs2 are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F009_S002_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  amoand.w rd, rs2, (rs1)  
  rd = [rs1]  
  [rs1] = rs2 & rs[1]  
  A load occurs from the address at rs1 into rd.  
  The values in rd and rs2 and bit-wise ANDed and the result iis then written back to the address at (rs1)
* **Verification Goals**
  
  Output result:   
    
  All bits of rd are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F009_S002_I002
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 003

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  amoand.w rd, rs2, (rs1)  
  rd = [rs1]  
  [rs1] = rs2 & rs[1]  
  A load occurs from the address at rs1 into rd.  
  The values in rd and rs2 and bit-wise ANDed and the result iis then written back to the address at (rs1)
* **Verification Goals**
  
  Exception:  
    
  Misaligned address (non-32-bit aligned) will always cause exception
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F009_S002_I003
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 003_AMOOR.W

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  amoor.w rd, rs2, (rs1)  
  rd = [rs1]  
  [rs1] = rs2 | [rs1]  
  A load occurs from the address at rs1 into rd.  
  The values in rd and rs2 and bit-wise ORed and the result iis then written back to the address at (rs1)
* **Verification Goals**
  
  Input operands:  
    
  All possible rs1 registers are used.  
  All possible rs2 registers are used.  
  All possible rd registers are used.  
  All possible register combinations where rs1 == rd are used  
  All possible register combinations where rs2 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F009_S003_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  amoor.w rd, rs2, (rs1)  
  rd = [rs1]  
  [rs1] = rs2 | [rs1]  
  A load occurs from the address at rs1 into rd.  
  The values in rd and rs2 and bit-wise ORed and the result iis then written back to the address at (rs1)
* **Verification Goals**
  
  Input operands:  
    
  All bits of rs1 are toggled  
  All bits of rs2 are toggled  
  Zero and non-zero values of rs2 are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F009_S003_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  amoor.w rd, rs2, (rs1)  
  rd = [rs1]  
  [rs1] = rs2 | [rs1]  
  A load occurs from the address at rs1 into rd.  
  The values in rd and rs2 and bit-wise ORed and the result iis then written back to the address at (rs1)
* **Verification Goals**
  
  Output result:   
    
  All bits of rd are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F009_S003_I002
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 003

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  amoor.w rd, rs2, (rs1)  
  rd = [rs1]  
  [rs1] = rs2 | [rs1]  
  A load occurs from the address at rs1 into rd.  
  The values in rd and rs2 and bit-wise ORed and the result iis then written back to the address at (rs1)
* **Verification Goals**
  
  Exception:  
    
  Misaligned address (non-32-bit aligned) will always cause exception
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F009_S003_I003
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 004_AMOXOR.W

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  amoxor.w rd, rs2, (rs1)  
  rd = [rs1]  
  [rs1] = rs2 ^ [rs1]  
  A load occurs from the address at rs1 into rd.  
  The values in rd and rs2 and bit-wise XORRed and the result iis then written back to the address at (rs1)
* **Verification Goals**
  
  Input operands:  
    
  All possible rs1 registers are used.  
  All possible rs2 registers are used.  
  All possible rd registers are used.  
  All possible register combinations where rs1 == rd are used  
  All possible register combinations where rs2 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F009_S004_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  amoxor.w rd, rs2, (rs1)  
  rd = [rs1]  
  [rs1] = rs2 ^ [rs1]  
  A load occurs from the address at rs1 into rd.  
  The values in rd and rs2 and bit-wise XORRed and the result iis then written back to the address at (rs1)
* **Verification Goals**
  
  Input operands:  
    
  All bits of rs1 are toggled  
  All bits of rs2 are toggled  
  Zero and non-zero values of rs2 are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F009_S004_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  amoxor.w rd, rs2, (rs1)  
  rd = [rs1]  
  [rs1] = rs2 ^ [rs1]  
  A load occurs from the address at rs1 into rd.  
  The values in rd and rs2 and bit-wise XORRed and the result iis then written back to the address at (rs1)
* **Verification Goals**
  
  Output result:   
    
  All bits of rd are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F009_S004_I002
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 003

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  amoxor.w rd, rs2, (rs1)  
  rd = [rs1]  
  [rs1] = rs2 ^ [rs1]  
  A load occurs from the address at rs1 into rd.  
  The values in rd and rs2 and bit-wise XORRed and the result iis then written back to the address at (rs1)
* **Verification Goals**
  
  Exception:  
    
  Misaligned address (non-32-bit aligned) will always cause exception
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F009_S004_I003
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 005_AMOMAX.W

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  amomax.w rd, rs2, (rs1)  
  rd = [rs1]  
  [rs1] = max_signed(rs2, [rs1])  
  A load occurs from the address at rs1 into rd.  
  The values in rd and rs2 and compared assuming signed numbers and the largest value is then written back to the address at (rs1)
* **Verification Goals**
  
  Input operands:  
    
  All possible rs1 registers are used.  
  All possible rs2 registers are used.  
  All possible rd registers are used.  
  All possible register combinations where rs1 == rd are used  
  All possible register combinations where rs2 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F009_S005_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  amomax.w rd, rs2, (rs1)  
  rd = [rs1]  
  [rs1] = max_signed(rs2, [rs1])  
  A load occurs from the address at rs1 into rd.  
  The values in rd and rs2 and compared assuming signed numbers and the largest value is then written back to the address at (rs1)
* **Verification Goals**
  
  Input operands:  
    
  All bits of rs1 are toggled  
  All bits of rs2 are toggled  
  +ve, -ve and zero values of rs2 are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F009_S005_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  amomax.w rd, rs2, (rs1)  
  rd = [rs1]  
  [rs1] = max_signed(rs2, [rs1])  
  A load occurs from the address at rs1 into rd.  
  The values in rd and rs2 and compared assuming signed numbers and the largest value is then written back to the address at (rs1)
* **Verification Goals**
  
  Output result:   
    
  +ve, -ve and zero values of rd are used  
  All bits of rd are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F009_S005_I002
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 003

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  amomax.w rd, rs2, (rs1)  
  rd = [rs1]  
  [rs1] = max_signed(rs2, [rs1])  
  A load occurs from the address at rs1 into rd.  
  The values in rd and rs2 and compared assuming signed numbers and the largest value is then written back to the address at (rs1)
* **Verification Goals**
  
  Exception:  
    
  Misaligned address (non-32-bit aligned) will always cause exception
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F009_S005_I003
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 006_AMOMAXU.W

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  amomaxu.w rd, rs2, (rs1)  
  rd = [rs1]  
  [rs1] = max_unsigned(rs2, [rs1])  
  A load occurs from the address at rs1 into rd.  
  The values in rd and rs2 and compared assuming unsigned numbers and the largest value is then written back to the address at (rs1)
* **Verification Goals**
  
  Input operands:  
    
  All possible rs1 registers are used.  
  All possible rs2 registers are used.  
  All possible rd registers are used.  
  All possible register combinations where rs1 == rd are used  
  All possible register combinations where rs2 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F009_S006_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  amomaxu.w rd, rs2, (rs1)  
  rd = [rs1]  
  [rs1] = max_unsigned(rs2, [rs1])  
  A load occurs from the address at rs1 into rd.  
  The values in rd and rs2 and compared assuming unsigned numbers and the largest value is then written back to the address at (rs1)
* **Verification Goals**
  
  Input operands:  
    
  All bits of rs1 are toggled  
  All bits of rs2 are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F009_S006_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  amomaxu.w rd, rs2, (rs1)  
  rd = [rs1]  
  [rs1] = max_unsigned(rs2, [rs1])  
  A load occurs from the address at rs1 into rd.  
  The values in rd and rs2 and compared assuming unsigned numbers and the largest value is then written back to the address at (rs1)
* **Verification Goals**
  
  Output result:   
    
  All bits of rd are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F009_S006_I002
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 003

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  amomaxu.w rd, rs2, (rs1)  
  rd = [rs1]  
  [rs1] = max_unsigned(rs2, [rs1])  
  A load occurs from the address at rs1 into rd.  
  The values in rd and rs2 and compared assuming unsigned numbers and the largest value is then written back to the address at (rs1)
* **Verification Goals**
  
  Exception:  
    
  Misaligned address (non-32-bit aligned) will always cause exception
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F009_S006_I003
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 007_AMOMIN.W

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  amomin.w rd, rs2, (rs1)  
  rd = [rs1]  
  [rs1] = min_signed(rs2, [rs1])  
  A load occurs from the address at rs1 into rd.  
  The values in rd and rs2 and compared assuming signed numbers and the smaller value is then written back to the address at (rs1)
* **Verification Goals**
  
  Input operands:  
    
  All possible rs1 registers are used.  
  All possible rs2 registers are used.  
  All possible rd registers are used.  
  All possible register combinations where rs1 == rd are used  
  All possible register combinations where rs2 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F009_S007_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  amomin.w rd, rs2, (rs1)  
  rd = [rs1]  
  [rs1] = min_signed(rs2, [rs1])  
  A load occurs from the address at rs1 into rd.  
  The values in rd and rs2 and compared assuming signed numbers and the smaller value is then written back to the address at (rs1)
* **Verification Goals**
  
  Input operands:  
    
  All bits of rs1 are toggled  
  All bits of rs2 are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F009_S007_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  amomin.w rd, rs2, (rs1)  
  rd = [rs1]  
  [rs1] = min_signed(rs2, [rs1])  
  A load occurs from the address at rs1 into rd.  
  The values in rd and rs2 and compared assuming signed numbers and the smaller value is then written back to the address at (rs1)
* **Verification Goals**
  
  Output result:   
    
  +ve, -ve and zero values of rd are used  
  All bits of rd are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F009_S007_I002
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 003

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  amomin.w rd, rs2, (rs1)  
  rd = [rs1]  
  [rs1] = min_signed(rs2, [rs1])  
  A load occurs from the address at rs1 into rd.  
  The values in rd and rs2 and compared assuming signed numbers and the smaller value is then written back to the address at (rs1)
* **Verification Goals**
  
  Exception:  
    
  Misaligned address (non-32-bit aligned) will always cause exception
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F009_S007_I003
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 008_AMOMINU.W

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  amominu.w rd, rs2, (rs1)  
  rd = [rs1]  
  [rs1] = min_unsigned(rs2, [rs1])  
  A load occurs from the address at rs1 into rd.  
  The values in rd and rs2 and compared assuming unsigned numbers and the smaller value is then written back to the address at (rs1)
* **Verification Goals**
  
  Input operands:  
    
  All possible rs1 registers are used.  
  All possible rs2 registers are used.  
  All possible rd registers are used.  
  All possible register combinations where rs1 == rd are used  
  All possible register combinations where rs2 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F009_S008_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  amominu.w rd, rs2, (rs1)  
  rd = [rs1]  
  [rs1] = min_unsigned(rs2, [rs1])  
  A load occurs from the address at rs1 into rd.  
  The values in rd and rs2 and compared assuming unsigned numbers and the smaller value is then written back to the address at (rs1)
* **Verification Goals**
  
  Input operands:  
    
  All bits of rs1 are toggled  
  All bits of rs2 are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F009_S008_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  amominu.w rd, rs2, (rs1)  
  rd = [rs1]  
  [rs1] = min_unsigned(rs2, [rs1])  
  A load occurs from the address at rs1 into rd.  
  The values in rd and rs2 and compared assuming unsigned numbers and the smaller value is then written back to the address at (rs1)
* **Verification Goals**
  
  Output result:   
    
  All bits of rd are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F009_S008_I002
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 003

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  amominu.w rd, rs2, (rs1)  
  rd = [rs1]  
  [rs1] = min_unsigned(rs2, [rs1])  
  A load occurs from the address at rs1 into rd.  
  The values in rd and rs2 and compared assuming unsigned numbers and the smaller value is then written back to the address at (rs1)
* **Verification Goals**
  
  Exception:  
    
  Misaligned address (non-32-bit aligned) will always cause exception
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F009_S008_I003
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
## Feature: RV32C Integer Computational Instructions

### Sub-feature: 000_C.LI

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.li rd, imm[5:0]  
  x[rd] = sext(imm)  
  Expands to addi rd, x0, imm[5:0]. Invalid when rd=x0.  
  rd is calculated using signed arithmetic
* **Verification Goals**
  
  Input operands:  
    
  All bits of imm[5:0] are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F010_S000_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.li rd, imm[5:0]  
  x[rd] = sext(imm)  
  Expands to addi rd, x0, imm[5:0]. Invalid when rd=x0.  
  rd is calculated using signed arithmetic
* **Verification Goals**
  
  Output result:  
    
  All bits of rd are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F010_S000_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 001_C.LUI

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.lui rd, nzimm[17:12]  
  x[rd] = sext(nzimm[17:12] << 12)  
  Expands to lui rd, nzimm[17:12]. Invalid when rd = {x0, x2} or imm = 0.  
  rd is calculated using signed arithmetic.
* **Verification Goals**
  
  Input operands:  
    
  All bits of imm[17:12] are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F010_S001_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.lui rd, nzimm[17:12]  
  x[rd] = sext(nzimm[17:12] << 12)  
  Expands to lui rd, nzimm[17:12]. Invalid when rd = {x0, x2} or imm = 0.  
  rd is calculated using signed arithmetic.
* **Verification Goals**
  
  Output result:  
    
  All bits of rd[31:12] are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F010_S001_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 002_C.ADDI

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.addi rd, nzimm[5:0]  
  x[rd] = x[rd] + sext(nzimm[5:0])  
  Expands to addi rd, rd, nzimm[5:0].  
  Invalid when rd=x0 or nzimm = 0. Arithmetic overflow is lost and ignored.  
  rd is calculated using signed arithmetic.
* **Verification Goals**
  
  Register operands:  
    
  All possible rd registers are used.
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F010_S002_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.addi rd, nzimm[5:0]  
  x[rd] = x[rd] + sext(nzimm[5:0])  
  Expands to addi rd, rd, nzimm[5:0].  
  Invalid when rd=x0 or nzimm = 0. Arithmetic overflow is lost and ignored.  
  rd is calculated using signed arithmetic.
* **Verification Goals**
  
  Input operands:  
    
  All inputs bits of rd before instruction execution are toggled  
  All bits of nzimm are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F010_S002_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.addi rd, nzimm[5:0]  
  x[rd] = x[rd] + sext(nzimm[5:0])  
  Expands to addi rd, rd, nzimm[5:0].  
  Invalid when rd=x0 or nzimm = 0. Arithmetic overflow is lost and ignored.  
  rd is calculated using signed arithmetic.
* **Verification Goals**
  
  Output result:  
    
  All bits of rd are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F010_S002_I002
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 003_C.ADDI16SP

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.addi16sp nzimm[9:4]  
  x[2] = x[2] + sext(nzimm[9:4])  
  Expands to addi x2, x2, nzimm[9:4]. Invalid when nzimm=0.  
  rd is calculated using signed arithmetic.
* **Verification Goals**
  
  Input operands:  
    
  +ve and -ve values of nzimm are used  
  All bits of nzimm[9:4] are toggled  
  All bits of x2 before instruction execution are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F010_S003_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.addi16sp nzimm[9:4]  
  x[2] = x[2] + sext(nzimm[9:4])  
  Expands to addi x2, x2, nzimm[9:4]. Invalid when nzimm=0.  
  rd is calculated using signed arithmetic.
* **Verification Goals**
  
  Output result:  
    
  All bits of x2 are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F010_S003_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 004_C.ADDI4SPN

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.addi4spn rd', nzuimm[9:2]  
  x[8+rd'] = x[2] + nzuimm[9:2]  
  Expands to addi rd', x2, nzuimm[9:2]. Invalid when nzuimm = 0.  
  rd is calculated using signed arithmetic.
* **Verification Goals**
  
  Register operands:  
    
  All possible rd` registers are used.
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F010_S004_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.addi4spn rd', nzuimm[9:2]  
  x[8+rd'] = x[2] + nzuimm[9:2]  
  Expands to addi rd', x2, nzuimm[9:2]. Invalid when nzuimm = 0.  
  rd is calculated using signed arithmetic.
* **Verification Goals**
  
  Input operands:  
    
  All bits of nzuimm[9:2] are toggled  
  All bits of x2 before instruction execution are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F010_S004_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.addi4spn rd', nzuimm[9:2]  
  x[8+rd'] = x[2] + nzuimm[9:2]  
  Expands to addi rd', x2, nzuimm[9:2]. Invalid when nzuimm = 0.  
  rd is calculated using signed arithmetic.
* **Verification Goals**
  
  Output result:  
    
  All bits of rd` are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F010_S004_I002
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 005_C.SLLI

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.slli rd, uimm[5:0]  
  x[rd] = x[rd] << uimm[5:0]  
  Expands to slli rd, rd, uimm[5:0]. Invalid when uimm[5] = 1, or uimm=0, or rd=x0.
* **Verification Goals**
  
  Register operands:  
    
  All possible rd registers are used.
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F010_S005_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.slli rd, uimm[5:0]  
  x[rd] = x[rd] << uimm[5:0]  
  Expands to slli rd, rd, uimm[5:0]. Invalid when uimm[5] = 1, or uimm=0, or rd=x0.
* **Verification Goals**
  
  Input operands:  
    
  All shift amounts from [0:31] are used  
  All bits of rd before instruction execution are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F010_S005_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.slli rd, uimm[5:0]  
  x[rd] = x[rd] << uimm[5:0]  
  Expands to slli rd, rd, uimm[5:0]. Invalid when uimm[5] = 1, or uimm=0, or rd=x0.
* **Verification Goals**
  
  Output result:  
    
  All bits of rd are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F010_S005_I002
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 006_C.SRLI

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.srli rd', uimm[5:0]  
  x[8+rd'] = x[8+rd'] >>u uimm[5:0]  
  Expands to srli rd', rd', uimm[5:0]. Invalid when uimm[5] = 1, or uimm=0,
* **Verification Goals**
  
  Register operands:  
    
  All possible rd` registers are used.
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F010_S006_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.srli rd', uimm[5:0]  
  x[8+rd'] = x[8+rd'] >>u uimm[5:0]  
  Expands to srli rd', rd', uimm[5:0]. Invalid when uimm[5] = 1, or uimm=0,
* **Verification Goals**
  
  Input operands:  
    
  All shift amounts from [0:31] are used  
  All bits of rd before instruction execution are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F010_S006_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.srli rd', uimm[5:0]  
  x[8+rd'] = x[8+rd'] >>u uimm[5:0]  
  Expands to srli rd', rd', uimm[5:0]. Invalid when uimm[5] = 1, or uimm=0,
* **Verification Goals**
  
  Output result:  
    
  All bits of rd are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F010_S006_I002
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 007_C.SRAI

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.srai rd', uimm[5:0]  
  x[8+rd'] = x[8+rd'] >> uimm[5:0]  
  Expands to srai rd', rd', uimm[5:0].
* **Verification Goals**
  
  Register operands:  
    
  All possible rd` registers are used.
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F010_S007_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.srai rd', uimm[5:0]  
  x[8+rd'] = x[8+rd'] >> uimm[5:0]  
  Expands to srai rd', rd', uimm[5:0].
* **Verification Goals**
  
  Input operands:  
    
  All shift amounts from [0:31] are used  
  +ve, -ve and zero values of rd` are used  
  All bits of rd` before instruction execution are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F010_S007_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.srai rd', uimm[5:0]  
  x[8+rd'] = x[8+rd'] >> uimm[5:0]  
  Expands to srai rd', rd', uimm[5:0].
* **Verification Goals**
  
  Output result:  
    
  All bits of rd` are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F010_S007_I002
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 008_C.ANDI

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.andi rd', imm[5:0]  
  x[8+rd'] = x[8+rd'] & sext(imm[5:0])  
  Expands to andi rd', rd', imm[5:0].  
  imm treated as signed number
* **Verification Goals**
  
  Register operands:  
    
  All possible rd` registers are used.
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F010_S008_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.andi rd', imm[5:0]  
  x[8+rd'] = x[8+rd'] & sext(imm[5:0])  
  Expands to andi rd', rd', imm[5:0].  
  imm treated as signed number
* **Verification Goals**
  
  Input operands:  
    
  All shift amounts from [0:31] are used  
  +ve, -ve and zero values of imm are used  
  All bits of rd` before instruction execution are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F010_S008_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.andi rd', imm[5:0]  
  x[8+rd'] = x[8+rd'] & sext(imm[5:0])  
  Expands to andi rd', rd', imm[5:0].  
  imm treated as signed number
* **Verification Goals**
  
  Output result:  
    
  All bits of rd` are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F010_S008_I002
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 009_C.MV

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.mv rd, rs2  
  x[rd] = x[rs2]  
  Expands to add rd, x0, rs2  
  Invalid when rs2=x0 or rd=x0.
* **Verification Goals**
  
  Register operands:  
    
  All possible rd registers are used.  
  All possible register combinations where rs2 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F010_S009_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.mv rd, rs2  
  x[rd] = x[rs2]  
  Expands to add rd, x0, rs2  
  Invalid when rs2=x0 or rd=x0.
* **Verification Goals**
  
  Input operands:  
    
  All bits of rs2 are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F010_S009_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.mv rd, rs2  
  x[rd] = x[rs2]  
  Expands to add rd, x0, rs2  
  Invalid when rs2=x0 or rd=x0.
* **Verification Goals**
  
  Output result:  
    
  All bits of rd are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F010_S009_I002
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 010_C.ADD

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.add rd, rs2  
  x[rd] = x[rd] + x[rs2]  
  Expands to add rd, rd, rs2. Invalid when rd=x0 or rs2=x0.  
  Arithmetic overflow is lost and ignored
* **Verification Goals**
  
  Register operands:  
    
  All possible rd registers are used.
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F010_S010_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.add rd, rs2  
  x[rd] = x[rd] + x[rs2]  
  Expands to add rd, rd, rs2. Invalid when rd=x0 or rs2=x0.  
  Arithmetic overflow is lost and ignored
* **Verification Goals**
  
  Input operands:  
    
  +ve,-ve and zero values of rs2 are used  
  +ve,-ve, and zero values of rdrs1 are used  
  All bits of rs2 are toggled  
  All bits of rd before instruction execution are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F010_S010_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.add rd, rs2  
  x[rd] = x[rd] + x[rs2]  
  Expands to add rd, rd, rs2. Invalid when rd=x0 or rs2=x0.  
  Arithmetic overflow is lost and ignored
* **Verification Goals**
  
  Output result:  
    
  All bits of rd are toggled  
  +ve,-ve and zero values of rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F010_S010_I002
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 011_C.AND

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.and rd', rs2'  
  x[8+rd'] = x[8+rd'] & x[8+rs2']  
  Expands to and rd', rd', rs2'.
* **Verification Goals**
  
  Register operands:  
    
  All possible rd` registers are used.
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F010_S011_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.and rd', rs2'  
  x[8+rd'] = x[8+rd'] & x[8+rs2']  
  Expands to and rd', rd', rs2'.
* **Verification Goals**
  
  Input operands:  
    
  Non-zero and zero values of rs2` are used  
  Non-zero and zero values of rd` are used  
  All bits of rs2` are toggled  
  All bits of rd` before instruction execution are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F010_S011_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.and rd', rs2'  
  x[8+rd'] = x[8+rd'] & x[8+rs2']  
  Expands to and rd', rd', rs2'.
* **Verification Goals**
  
  Output result:  
    
  All bits of rd` are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F010_S011_I002
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 012_C.OR

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.or rd', rs2'  
  x[8+rd'] = x[8+rd'] | x[8+rs2']  
  Expands to or rd', rd', rs2'.
* **Verification Goals**
  
  Register operands:  
    
  All possible rd` registers are used.
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F010_S012_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.or rd', rs2'  
  x[8+rd'] = x[8+rd'] | x[8+rs2']  
  Expands to or rd', rd', rs2'.
* **Verification Goals**
  
  Input operands:  
    
  Non-zero and zero values of rs2` are used  
  Non-zero and zero values of rd` are used  
  All bits of rs2` are toggled  
  All bits of rd` before instruction execution are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F010_S012_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.or rd', rs2'  
  x[8+rd'] = x[8+rd'] | x[8+rs2']  
  Expands to or rd', rd', rs2'.
* **Verification Goals**
  
  Output result:  
    
  All bits of rd` are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F010_S012_I002
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 013_C.XOR

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.xor rd', rs2'  
  x[8+rd'] = x[8+rd'] ^ x[8+rs2']  
  Expands to xor rd', rd', rs2'.
* **Verification Goals**
  
  Register operands:  
    
  All possible rd` registers are used.
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F010_S013_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.xor rd', rs2'  
  x[8+rd'] = x[8+rd'] ^ x[8+rs2']  
  Expands to xor rd', rd', rs2'.
* **Verification Goals**
  
  Input operands:  
    
  Non-zero and zero values of rs2` are used  
  Non-zero and zero values of rd` are used  
  All bits of rs2` are toggled  
  All bits of rd` before instruction execution are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F010_S013_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.xor rd', rs2'  
  x[8+rd'] = x[8+rd'] ^ x[8+rs2']  
  Expands to xor rd', rd', rs2'.
* **Verification Goals**
  
  Output result:  
    
  All bits of rd` are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F010_S013_I002
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 014_C.SUB

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.sub rd', rs2'  
  x[8+rd'] = x[8+rd'] - x[8+rs2']  
  Expands to sub rd', rd', rs2'. Arithmetic underflow is ignored
* **Verification Goals**
  
  Register operands:  
    
  All possible rd` registers are used.
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F010_S014_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.sub rd', rs2'  
  x[8+rd'] = x[8+rd'] - x[8+rs2']  
  Expands to sub rd', rd', rs2'. Arithmetic underflow is ignored
* **Verification Goals**
  
  Input operands:  
    
  +ve,-ve and zero values of rs2` are used  
  +ve, -ve, and zero values of rd` are used  
  All bits of rs2` are toggled  
  All bits of rd` before instruction execution are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F010_S014_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.sub rd', rs2'  
  x[8+rd'] = x[8+rd'] - x[8+rs2']  
  Expands to sub rd', rd', rs2'. Arithmetic underflow is ignored
* **Verification Goals**
  
  Output result:  
    
  All bits of rd` are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F010_S014_I002
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 015_C.EBREAK

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.ebreak  
  RaiseException(Breakpoint)  
  Expands to ebreak.
* **Verification Goals**
  
  Instruction executed
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F010_S015_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
## Feature: RV32C Control Transfer Instructions

### Sub-feature: 000_C.J

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.j imm[11:1]  
  pc += sext(imm)  
  pc is calculated using signed arithmetic  
  Expands to jal x0, imm[11:1].
* **Verification Goals**
  
  Input operands:  
    
  uimm value is non-zero and zero  
  All bits of uimm are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F011_S000_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 001_C.JAL

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.jal imm[11:1]  
  x[1] = pc+2; pc += sext(imm)  
  pc is calculated using signed arithmetic.
* **Verification Goals**
  
  Input operands:  
    
  uimm value is non-zero and zero  
  All bits of uimm are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F011_S001_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.jal imm[11:1]  
  x[1] = pc+2; pc += sext(imm)  
  pc is calculated using signed arithmetic.
* **Verification Goals**
  
  Output result:  
    
  All bits of x1 are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F011_S001_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 002_C.JR

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.jr rs1  
  pc = x[rs1]  
  Expands to jalr x0, 0(rs1).   
  Invalid when rs1=x0.
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F011_S002_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.jr rs1  
  pc = x[rs1]  
  Expands to jalr x0, 0(rs1).   
  Invalid when rs1=x0.
* **Verification Goals**
  
  Input operands:  
    
  All bits of rs1 are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F011_S002_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 003_C.JALR

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.jalr rs1  
  t = pc + 2; pc = x[rs1]; x[1] = t  
  Expands to jalr x1, 0(rs1).   
  Invalid when rs1=x0.
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F011_S003_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.jalr rs1  
  t = pc + 2; pc = x[rs1]; x[1] = t  
  Expands to jalr x1, 0(rs1).   
  Invalid when rs1=x0.
* **Verification Goals**
  
  Input operands:  
    
  All bits of rs1 are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F011_S003_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.jalr rs1  
  t = pc + 2; pc = x[rs1]; x[1] = t  
  Expands to jalr x1, 0(rs1).   
  Invalid when rs1=x0.
* **Verification Goals**
  
  Output result:  
    
  All bits of x1 are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F011_S003_I002
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 004_C.BEQZ

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.beqz rs1', imm[8:1]  
  if (x[8+rs1'] == 0) pc += sext(imm)  
  Expands to beq rs1', x0, imm[8:1]. pc is calculated using signed arithmetic.
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1` registers are used.
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F011_S004_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.beqz rs1', imm[8:1]  
  if (x[8+rs1'] == 0) pc += sext(imm)  
  Expands to beq rs1', x0, imm[8:1]. pc is calculated using signed arithmetic.
* **Verification Goals**
  
  Input operands:  
    
  All bits of rs1` are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F011_S004_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.beqz rs1', imm[8:1]  
  if (x[8+rs1'] == 0) pc += sext(imm)  
  Expands to beq rs1', x0, imm[8:1]. pc is calculated using signed arithmetic.
* **Verification Goals**
  
  Output result:  
    
  Branch taken or not-taken
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F011_S004_I002
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 005_C.BNEZ

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.bnez  rs1', imm[8:1]  
  if (x[8+rs1'] ≠ 0) pc += sext(imm)  
  Expands to bne rs1', x0, imm[8:1]. pc is calculated using signed arithmetic.
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1` registers are used.
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F011_S005_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.bnez  rs1', imm[8:1]  
  if (x[8+rs1'] ≠ 0) pc += sext(imm)  
  Expands to bne rs1', x0, imm[8:1]. pc is calculated using signed arithmetic.
* **Verification Goals**
  
  Input operands:  
    
  All bits of rs1 are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F011_S005_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.bnez  rs1', imm[8:1]  
  if (x[8+rs1'] ≠ 0) pc += sext(imm)  
  Expands to bne rs1', x0, imm[8:1]. pc is calculated using signed arithmetic.
* **Verification Goals**
  
  Output result:  
    
  Branch taken or not-taken
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F011_S005_I002
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
## Feature: RV32C Load and Store Instructions

### Sub-feature: 000_C.LWSP

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.lwsp rd, uimm(x2)  
  x[rd] = sext(M[x[2] + uimm][0:31])  
  Expands to lw rd, uimm[7:2](x2).   
  Invalid when rd=x0.  
  uimm treated as unsigned number
* **Verification Goals**
  
  Register operands:  
    
  All possible rd registers are used.
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F012_S000_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.lwsp rd, uimm(x2)  
  x[rd] = sext(M[x[2] + uimm][0:31])  
  Expands to lw rd, uimm[7:2](x2).   
  Invalid when rd=x0.  
  uimm treated as unsigned number
* **Verification Goals**
  
  Input operands:  
    
  uimm value is non-zero and zero  
  All bits of uimm are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F012_S000_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.lwsp rd, uimm(x2)  
  x[rd] = sext(M[x[2] + uimm][0:31])  
  Expands to lw rd, uimm[7:2](x2).   
  Invalid when rd=x0.  
  uimm treated as unsigned number
* **Verification Goals**
  
  Output result:  
    
  rd value is non-zero and zero  
  All bits of rd are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F012_S000_I002
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 001_C.SWSP

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.swsp rs2, uimm(x2)  
  M[x[2] + uimm][0:31] = x[rs2]  
  Expands to sw rs2, uimm[7:2](x2).  
  uimm treated as unsigned number
* **Verification Goals**
  
  Register operands:  
    
  All possible rs2 registers are used.
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F012_S001_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.swsp rs2, uimm(x2)  
  M[x[2] + uimm][0:31] = x[rs2]  
  Expands to sw rs2, uimm[7:2](x2).  
  uimm treated as unsigned number
* **Verification Goals**
  
  Input operands:  
    
  uimm value is non-zero and zero  
  All bits of uimm are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F012_S001_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 002_C.LW

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.lw rd', uimm(rs1')  
  x[rd] = sext(M[x[rs1] + uimm][0:31]), where rd=8+rd' and rs1=8+rs1'  
  Expands to lw rd', uimm[6:2](rs1')
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1` registers are used.  
  All possible rd` registers are used.  
  All possible register combinations where rs1` == rd` are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F012_S002_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.lw rd', uimm(rs1')  
  x[rd] = sext(M[x[rs1] + uimm][0:31]), where rd=8+rd' and rs1=8+rs1'  
  Expands to lw rd', uimm[6:2](rs1')
* **Verification Goals**
  
  Input operands:  
    
  uimm value is non-zero and zero  
  All bits of uimm are toggled  
  All bits of rs1` are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F012_S002_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.lw rd', uimm(rs1')  
  x[rd] = sext(M[x[rs1] + uimm][0:31]), where rd=8+rd' and rs1=8+rs1'  
  Expands to lw rd', uimm[6:2](rs1')
* **Verification Goals**
  
  Output result:  
    
  rd` value is non-zero and zero  
  All bits of rd are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F012_S002_I002
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 003_C.SW

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.sw rs2', uimm(rs1')  
  M[x[rs1] + uimm][0:31] = x[rs2], where rs2=8+rs2' and rs1=8+rs1'  
  Expands to sw rs2', uimm[6:2](rs1').
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1` registers are used.  
  All possible rd` registers are used.  
  All possible register combinations where rs1` == rd` are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F012_S003_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.sw rs2', uimm(rs1')  
  M[x[rs1] + uimm][0:31] = x[rs2], where rs2=8+rs2' and rs1=8+rs1'  
  Expands to sw rs2', uimm[6:2](rs1').
* **Verification Goals**
  
  Input operands:  
    
  uimm value is non-zero and zero  
  All bits of uimm are toggled  
  All bits of rs1` are toggled  
  All bits of rs2` are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F012_S003_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
## Feature: RV32Zicsr Control and Status Register (CSR) Instructions

### Sub-feature: 000_CSRRW

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  csrrw rd, rs1, csr  
  rd = Zext([csr]); csr = [rs1]
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used  
  All possible rd registers are used  
  All supported CSRs are used  
  All possible register combinations where rs1 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F013_S000_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  csrrw rd, rs1, csr  
  rd = Zext([csr]); csr = [rs1]
* **Verification Goals**
  
  Input operand:  
    
  Non-zero and zero rs1 operands are used (if rs1 != x0)
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F013_S000_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 001_CSRRS

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  csrrs rd, rs1, csr  
  rd = Zext([csr]); csr = [rs1] | csr  
  Note that not all bits of csr will be writable.
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used  
  All possible rd registers are used  
  All supported CSRs are used  
  All possible register combinations where rs1 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F013_S001_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  csrrs rd, rs1, csr  
  rd = Zext([csr]); csr = [rs1] | csr  
  Note that not all bits of csr will be writable.
* **Verification Goals**
  
  Input operand:  
    
  Non-zero and zero rs1 operands are used (if rs1 != x0)
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F013_S001_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 002_CSRRC

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  csrrs rd, rs1, csr  
  rd = Zext([csr]); csr = ~[rs1] | csr  
  Note that not all bits of csr will be writable.
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used  
  All possible rd registers are used  
  All supported CSRs are used  
  All possible register combinations where rs1 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F013_S002_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  csrrs rd, rs1, csr  
  rd = Zext([csr]); csr = ~[rs1] | csr  
  Note that not all bits of csr will be writable.
* **Verification Goals**
  
  Input operand:  
    
  Non-zero and zero rs1 operands are used (if rs1 != x0)
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F013_S002_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 003_CSRRWI

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  csrrwi rd, imm[4:0], csr  
  rd = Zext([csr]); csr = Zext(imm[4:0])  
  If rd == x0 then CSR is not read.
* **Verification Goals**
  
  Register operands:  
    
  All possible rd registers are used  
  All supported CSRs are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F013_S003_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  csrrwi rd, imm[4:0], csr  
  rd = Zext([csr]); csr = Zext(imm[4:0])  
  If rd == x0 then CSR is not read.
* **Verification Goals**
  
  Input operand:  
    
  Non-zero and zero imm[4:0] operands are used  
  All bits of imm[4:0] are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F013_S003_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 004_CSRRSI

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  csrrsi rd, imm[4:0], csr  
  rd = Zext([csr]); csr = Zext(imm[4:0]) | csr  
  Note that not all bits of csr will be writable.
* **Verification Goals**
  
  Register operands:  
    
  All possible rd registers are used  
  All supported CSRs are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F013_S004_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  csrrsi rd, imm[4:0], csr  
  rd = Zext([csr]); csr = Zext(imm[4:0]) | csr  
  Note that not all bits of csr will be writable.
* **Verification Goals**
  
  Input operand:  
    
  Non-zero and zero imm[4:0] operands are used  
  All bits of imm[4:0] are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F013_S004_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 005_CSRRCI

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  csrrs rd, imm[4:0], csr  
  rd = Zext([csr]); csr = ~(Zext(imm[4:0])) | csr  
  Note that not all bits of csr will be writable.
* **Verification Goals**
  
  Register operands:  
    
  All possible rd registers are used  
  All supported CSRs are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F013_S005_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  csrrs rd, imm[4:0], csr  
  rd = Zext([csr]); csr = ~(Zext(imm[4:0])) | csr  
  Note that not all bits of csr will be writable.
* **Verification Goals**
  
  Input operand:  
    
  Non-zero and zero imm[4:0] operands are used  
  All bits of imm[4:0] are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F013_S005_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
## Feature: RV32Zifencei Instruction-Fetch Fence

### Sub-feature: 000_FENCE.I

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  Fence.I instruction executed  
  Implementation is core-specific
* **Verification Goals**
  
  Fence.I instruction is executed
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F014_S000_I000
* **Link to Coverage:** isacov.rv32zifencei_fence_i_cg
* **Comments**
  
  *(none)*  
  
## Feature: Instruction execution sequences

### Sub-feature: 000_Instruction Execution

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  All supported instructions for the core are executed
* **Verification Goals**
  
  Instruction is executed
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F015_S000_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  All supported instructions for the core are executed
* **Verification Goals**
  
  All back-to-back supported instruction sequences are executed
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F015_S000_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 001_Instruction Group Execution

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  All defined instruction groups for a core are executed
* **Verification Goals**
  
  For the core under test, all instruction groups are executed in the core
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F015_S001_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  All defined instruction groups are executed in sequence
* **Verification Goals**
  
  Depending on the length of the pipeline in the processor, sequence chains of 2,3,or 4 instruction groups are checked for execution
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F015_S001_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 002_GPR Hazard

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  An instruction reads from  register that was written to in the previous instruction
* **Verification Goals**
  
  All instruction groups are tested across GPR hazards
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F015_S002_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 003_CSR Hazard

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  CSR writes from the program are executed in conjunction with all instruction groups
* **Verification Goals**
  
  CSR write instruction attempts to write to a supported CSR  
  This does not include csr set or clear instructions where rs1 is x0 (bypassing the write)
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F015_S003_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  CSR writes from the program are executed in conjunction with all instruction groups
* **Verification Goals**
  
  Each instruction group is executed after each supported CSR is written with a Zicsri write instruction
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F015_S003_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
## Feature: RV32Zicond Integer Conditional Instructions

### Sub-feature: 000_CZERO.EQZ

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  czero.eqz rd, rs1, rs2  
  if (x[rs2] == 0) x[rd] = 0 else x[rs1]  
   Set rd's value to zero if rs2 is equal to zero, otherwise moves rs1 into rd
* **Verification Goals**
  
  Register operands:  
    
  All possible rd registers are used  
  All possible rs1 registers are used  
  All possible rs2 registers are used  
  All possible register combinations where rs1 == rd are used  
  All possible register combinations where rs2 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F016_S000_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  czero.eqz rd, rs1, rs2  
  if (x[rs2] == 0) x[rd] = 0 else x[rs1]  
   Set rd's value to zero if rs2 is equal to zero, otherwise moves rs1 into rd
* **Verification Goals**
  
  Input operands:  
    
  rs1 value is +ve, -ve and zero  
  rs2 value is +ve, -ve and zero  
  All combinations of rs1 and rs2 +ve, -ve, and zero values are used  
  All bits of rs1 are toggled  
  All bits of rs2 are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F016_S000_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  czero.eqz rd, rs1, rs2  
  if (x[rs2] == 0) x[rd] = 0 else x[rs1]  
   Set rd's value to zero if rs2 is equal to zero, otherwise moves rs1 into rd
* **Verification Goals**
  
  Output result:  
    
  rd value is +ve, -ve and zero  
  All bits of rd are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F016_S000_I002
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 001_CZERO.NEZ

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  czero.nez rd, rs1, rs2  
  if (x[rs2] != 0) x[rd] = 0 else x[rs1]  
   Set rd's value to zero if rs2 isn't equal to zero, otherwise moves rs1 into rd
* **Verification Goals**
  
  Register operands:  
    
  All possible rd registers are used  
  All possible rs1 registers are used  
  All possible rs2 registers are used  
  All possible register combinations where rs1 == rd are used  
  All possible register combinations where rs2 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F016_S001_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  czero.nez rd, rs1, rs2  
  if (x[rs2] != 0) x[rd] = 0 else x[rs1]  
   Set rd's value to zero if rs2 isn't equal to zero, otherwise moves rs1 into rd
* **Verification Goals**
  
  Input operands:  
    
  rs1 value is +ve, -ve and zero  
  rs2 value is +ve, -ve and zero  
  All combinations of rs1 and rs2 +ve, -ve, and zero values are used  
  All bits of rs1 are toggled  
  All bits of rs2 are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F016_S001_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  czero.nez rd, rs1, rs2  
  if (x[rs2] != 0) x[rd] = 0 else x[rs1]  
   Set rd's value to zero if rs2 isn't equal to zero, otherwise moves rs1 into rd
* **Verification Goals**
  
  Output result:  
    
  rd value is +ve, -ve and zero  
  All bits of rd are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F016_S001_I002
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
## Feature: RV32Zcb Integer Computational Instructions

### Sub-feature: 000_C.ZEXT.B

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.zext.b rd'  
  x[8 + rd'] = zext(x[8 + rd'][7:0])  
  It zero-extends the least-significant byte of the operand
* **Verification Goals**
  
  Register operands:  
    
  All possible rd` registers are used.
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32 EMBEDDED_F016_S000_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.zext.b rd'  
  x[8 + rd'] = zext(x[8 + rd'][7:0])  
  It zero-extends the least-significant byte of the operand
* **Verification Goals**
  
  Output result:  
    
  All bits of rd'[7:0] are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32 EMBEDDED_F016_S000_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 001_C.SEXT.B

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.sext.b rd'  
  x[8 + rd'] = sext(x[8 + rd'][7:0])  
  It sign-extends the least-significant byte of the operand
* **Verification Goals**
  
  Register operands:  
    
  All possible rd' are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32 EMBEDDED_F016_S001_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.sext.b rd'  
  x[8 + rd'] = sext(x[8 + rd'][7:0])  
  It sign-extends the least-significant byte of the operand
* **Verification Goals**
  
  Output operands:  
    
  All bits of rd' are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32 EMBEDDED_F016_S001_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 002_C.ZEXT.H

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.zext.h rd'  
  x[8 + rd'] = zext(x[8 + rd'][15:0])  
  It zero-extends the least-significant half-word of the operand
* **Verification Goals**
  
  Register operands:  
    
  All possible rd' registers are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32 EMBEDDED_F016_S002_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.zext.h rd'  
  x[8 + rd'] = zext(x[8 + rd'][15:0])  
  It zero-extends the least-significant half-word of the operand
* **Verification Goals**
  
  Output result:  
    
  All bits of rd'[15:0] are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32 EMBEDDED_F016_S002_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 003_C.SEXT.H

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.sext.h rd'  
  x[8 + rd'] = sext(x[8 + rd'][15:0])  
  It sign-extends the least-significant half-word of the operand
* **Verification Goals**
  
  Register operands:  
    
  All possible rd' registers are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32 EMBEDDED_F016_S003_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.sext.h rd'  
  x[8 + rd'] = sext(x[8 + rd'][15:0])  
  It sign-extends the least-significant half-word of the operand
* **Verification Goals**
  
  Output result:  
    
  All bits of rd' are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32 EMBEDDED_F016_S003_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 005_C.NOT

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.not rd'  
  x[8 + rd'] = x[8 + rd']^ -1
* **Verification Goals**
  
  Register operands:  
    
  All possible rd' registers are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32 EMBEDDED_F016_S005_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.not rd'  
  x[8 + rd'] = x[8 + rd']^ -1
* **Verification Goals**
  
  Output result:  
    
  All bits of rd' are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32 EMBEDDED_F016_S005_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 006_C.MUL

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.mul rd',rs2'  
  x[8 + rd'] = x[8 + rd'] * x[8 + rs2']  
  Arithmetic overflow is ignored.
* **Verification Goals**
  
  Register operands:  
    
  All possible rd' registers are used  
   All possible register combinations where rs2' == rd' are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32 EMBEDDED_F016_S006_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.mul rd',rs2'  
  x[8 + rd'] = x[8 + rd'] * x[8 + rs2']  
  Arithmetic overflow is ignored.
* **Verification Goals**
  
  Input operands:  
    
  All bits of rs2' are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32 EMBEDDED_F016_S006_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.mul rd',rs2'  
  x[8 + rd'] = x[8 + rd'] * x[8 + rs2']  
  Arithmetic overflow is ignored.
* **Verification Goals**
  
  Output result:  
    
  All bits of rd' are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32 EMBEDDED_F016_S006_I002
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
## Feature: RV32Zcb Load and Store Instructions

### Sub-feature: 000_C.LBU

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.lbu rd', uimm(rs1')  
  x[8 + rd'] = zext(M[x[8 + rd'] + zext(uimm[1:0])][7:0])
* **Verification Goals**
  
  Register operands:  
    
  All possible rd' register are used  
  All possible rs1' register are used  
  ALl possible combinations where rd' == rs1' are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32 EMBEDDED_F017_S000_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.lbu rd', uimm(rs1')  
  x[8 + rd'] = zext(M[x[8 + rd'] + zext(uimm[1:0])][7:0])
* **Verification Goals**
  
  Input operands:  
    
  uimm value is non-zero and zero  
  All bits of uimm are toggled  
  All bits of rs1' are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32 EMBEDDED_F017_S000_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.lbu rd', uimm(rs1')  
  x[8 + rd'] = zext(M[x[8 + rd'] + zext(uimm[1:0])][7:0])
* **Verification Goals**
  
  Output result:  
    
  rd' value is non-zero and zero  
  All bits of rd' are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32 EMBEDDED_F017_S000_I002
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 001_C.SB

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.sb rs1', uimm(rs2')  
  M[x[8 + rs1'] + zext(uimm[1:0])][7:0] = x[8 + rs2']
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1' register are used  
   All possible rs2' register are used  
  All possible combinations where rs1' = rs2' register are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32 EMBEDDED_F017_S001_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.sb rs1', uimm(rs2')  
  M[x[8 + rs1'] + zext(uimm[1:0])][7:0] = x[8 + rs2']
* **Verification Goals**
  
  Input operands:  
    
  uimm value is non-zero and zero  
  All bits of uimm are toggled  
  All bits of rs1' are toggled  
  All bits of rs2' are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32 EMBEDDED_F017_S001_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 002_C.LHU

#### Item: 000

* **Requirement location:** ./RISCV_Instructions
* **Feature Description**
  
  c.lhu rd', uimm(rs1')  
  x[8 + rd'] = zext(M[x[8 + rd'] + zext(uimm[1])][15:0])
* **Verification Goals**
  
  Register operands:  
    
  All possible rd' register are used  
  All possible rs1' register are used  
  ALl possible combinations where rd' == rs1' are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32 EMBEDDED_F017_S002_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions
* **Feature Description**
  
  c.lhu rd', uimm(rs1')  
  x[8 + rd'] = zext(M[x[8 + rd'] + zext(uimm[1])][15:0])
* **Verification Goals**
  
  Input operands:  
    
  uimm value is non-zero and zero  
  All bits of uimm are toggled  
  All bits of rs1' are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32 EMBEDDED_F017_S002_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions
* **Feature Description**
  
  c.lhu rd', uimm(rs1')  
  x[8 + rd'] = zext(M[x[8 + rd'] + zext(uimm[1])][15:0])
* **Verification Goals**
  
  Output result:  
    
  rd' value is non-zero and zero  
  All bits of rd' are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32 EMBEDDED_F017_S002_I002
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 003_C.LH

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.lh rd', uimm(rs1')  
  x[8 + rd'] = sext(M[x[8 + rd'] + zext(uimm[1])][15:0])
* **Verification Goals**
  
  Register operands:  
    
  All possible rd' register are used  
  All possible rs1' register are used  
  ALl possible combinations where rd' == rs1' are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32 EMBEDDED_F017_S003_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.lh rd', uimm(rs1')  
  x[8 + rd'] = sext(M[x[8 + rd'] + zext(uimm[1])][15:0])
* **Verification Goals**
  
  Input operands:  
    
  uimm value is non-zero and zero  
  All bits of uimm are toggled  
  All bits of rs1' are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32 EMBEDDED_F017_S003_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.lh rd', uimm(rs1')  
  x[8 + rd'] = sext(M[x[8 + rd'] + zext(uimm[1])][15:0])
* **Verification Goals**
  
  Output result:  
    
  rd' value is non-zero and zero  
  All bits of rd' are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32 EMBEDDED_F017_S003_I002
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 004_C.SH

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.sh rs1', uimm(rs2')  
  M[x[8 + rs1'] + zext(uimm[1])][15:0] = x[8 + rs2']
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1' register are used  
   All possible rs2' register are used  
  All possible combinations where rs1' = rs2' are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32 EMBEDDED_F017_S004_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  c.sh rs1', uimm(rs2')  
  M[x[8 + rs1'] + zext(uimm[1])][15:0] = x[8 + rs2']
* **Verification Goals**
  
  Input operands:  
    
  uimm value is non-zero and zero  
  All bits of uimm are toggled  
  All bits of rs1' are toggled  
  All bits of rs2' are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32 EMBEDDED_F017_S004_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
## Feature: RV32Zba Address generation instructions

### Sub-feature: 000_SH1ADD

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  sh1add rd, rs1, rs2  
  x[rd] = (x[rs1] << 1) + x[rs2]  
  Shift the value in rs1 by 1 bit, add to it rs2 and store the result in rd.
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
   All possible rs2 registers are used.  
  All possible rd registers are used.  
   All possible register combinations where rs1 == rd are used  
  All possible register combinations where rs2 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F019_S000_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  sh1add rd, rs1, rs2  
  x[rd] = (x[rs1] << 1) + x[rs2]  
  Shift the value in rs1 by 1 bit, add to it rs2 and store the result in rd.
* **Verification Goals**
  
  Input operands:  
    
  rs1 value is +ve, -ve and zero  
  rs2 value is +ve, -ve and zero  
  All combinations of rs1 and rs2 +ve, -ve, and zero values are used  
  All bits of rs1 are toggled  
  All bits of rs2 are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F019_S000_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  sh1add rd, rs1, rs2  
  x[rd] = (x[rs1] << 1) + x[rs2]  
  Shift the value in rs1 by 1 bit, add to it rs2 and store the result in rd.
* **Verification Goals**
  
  Output result:  
    
  rd value is +ve, -ve and zero  
  All bits of rd are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F019_S000_I002
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 001_SH2ADD

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  sh2add rd, rs1, rs2  
  x[rd] = (x[rs1] << 2) + x[rs2]  
  Shift the value in rs1 by 2 bits, add to it rs2 and store the result in rd.
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
   All possible rs2 registers are used.  
  All possible rd registers are used.  
   All possible register combinations where rs1 == rd are used  
  All possible register combinations where rs2 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F019_S001_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  sh2add rd, rs1, rs2  
  x[rd] = (x[rs1] << 2) + x[rs2]  
  Shift the value in rs1 by 2 bits, add to it rs2 and store the result in rd.
* **Verification Goals**
  
  Input operands:  
    
  rs1 value is +ve, -ve and zero  
  rs2 value is +ve, -ve and zero  
  All combinations of rs1 and rs2 +ve, -ve, and zero values are used  
  All bits of rs1 are toggled  
  All bits of rs2 are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F019_S001_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  sh2add rd, rs1, rs2  
  x[rd] = (x[rs1] << 2) + x[rs2]  
  Shift the value in rs1 by 2 bits, add to it rs2 and store the result in rd.
* **Verification Goals**
  
  Output result:  
    
  rd value is +ve, -ve and zero  
  All bits of rd are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F019_S001_I002
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 002_SH3ADD

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  sh3add rd, rs1, rs2  
  x[rd] = (x[rs1] << 3) + x[rs2]  
  Shift the value in rs1 by 3 bits, add to it rs2 and store the result in rd.
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
   All possible rs2 registers are used.  
  All possible rd registers are used.  
   All possible register combinations where rs1 == rd are used  
  All possible register combinations where rs2 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F019_S002_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  sh3add rd, rs1, rs2  
  x[rd] = (x[rs1] << 3) + x[rs2]  
  Shift the value in rs1 by 3 bits, add to it rs2 and store the result in rd.
* **Verification Goals**
  
  Input operands:  
    
  rs1 value is +ve, -ve and zero  
  rs2 value is +ve, -ve and zero  
  All combinations of rs1 and rs2 +ve, -ve, and zero values are used  
  All bits of rs1 are toggled  
  All bits of rs2 are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F019_S002_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  sh3add rd, rs1, rs2  
  x[rd] = (x[rs1] << 3) + x[rs2]  
  Shift the value in rs1 by 3 bits, add to it rs2 and store the result in rd.
* **Verification Goals**
  
  Output result:  
    
  rd value is +ve, -ve and zero  
  All bits of rd are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F019_S002_I002
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
## Feature: RV32Zbc Carry-less multiplication

### Sub-feature: 000_CLMUL

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  clmul rd, rs1, rs2  
  x[rd] = carry_less_product(rs1, rs2)  
  The lower-half on the carry-less product of rs1 and rs2 is placed in rd.
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
   All possible rs2 registers are used.  
  All possible rd registers are used.  
   All possible register combinations where rs1 == rd are used  
  All possible register combinations where rs2 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F020_S000_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  clmul rd, rs1, rs2  
  x[rd] = carry_less_product(rs1, rs2)  
  The lower-half on the carry-less product of rs1 and rs2 is placed in rd.
* **Verification Goals**
  
  Input operands:  
    
  rs1 value is No-zero and zero  
  rs2 value is No-zero and zero  
  All bits of rs1 are toggled  
  All bits of rs2 are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F020_S000_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  clmul rd, rs1, rs2  
  x[rd] = carry_less_product(rs1, rs2)  
  The lower-half on the carry-less product of rs1 and rs2 is placed in rd.
* **Verification Goals**
  
  Output result:  
    
  rd value is No-zero and zero  
  All bits of rd are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F020_S000_I002
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 001_CLMULH

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  clmulh rd, rs1, rs2  
  x[rd] = carry_less_product(rs1, rs2) >> 32  
  The upper-half on the carry-less product of rs1 and rs2 is placed in rd.
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
   All possible rs2 registers are used.  
  All possible rd registers are used.  
   All possible register combinations where rs1 == rd are used  
  All possible register combinations where rs2 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F020_S001_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  clmulh rd, rs1, rs2  
  x[rd] = carry_less_product(rs1, rs2) >> 32  
  The upper-half on the carry-less product of rs1 and rs2 is placed in rd.
* **Verification Goals**
  
  Input operands:  
    
  rs1 value is No-zero and zero  
  rs2 value is No-zero and zero  
  All bits of rs1 are toggled  
  All bits of rs2 are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F020_S001_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  clmulh rd, rs1, rs2  
  x[rd] = carry_less_product(rs1, rs2) >> 32  
  The upper-half on the carry-less product of rs1 and rs2 is placed in rd.
* **Verification Goals**
  
  Output result:  
    
  rd value is No-zero and zero  
  All bits of rd are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F020_S001_I002
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 002_CLMULR

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  clmulr rd, rs1, rs2  
  x[rd] = carry_less_product(rs1, rs2) >> 32  
  clmulr produces bits 2.XLEN-2:XLEN-1 of the 2.XLEN carry-less product.
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
   All possible rs2 registers are used.  
  All possible rd registers are used.  
   All possible register combinations where rs1 == rd are used  
  All possible register combinations where rs2 == rd are used
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F020_S002_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  clmulr rd, rs1, rs2  
  x[rd] = carry_less_product(rs1, rs2) >> 32  
  clmulr produces bits 2.XLEN-2:XLEN-1 of the 2.XLEN carry-less product.
* **Verification Goals**
  
  Input operands:  
    
  rs1 value is No-zero and zero  
  rs2 value is No-zero and zero  
  All bits of rs1 are toggled  
  All bits of rs2 are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F020_S002_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  clmulr rd, rs1, rs2  
  x[rd] = carry_less_product(rs1, rs2) >> 32  
  clmulr produces bits 2.XLEN-2:XLEN-1 of the 2.XLEN carry-less product.
* **Verification Goals**
  
  Output result:  
    
  rd value is No-zero and zero  
  All bits of rd are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F020_S002_I002
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
## Feature: RV32Zbb Basic bit-manipulation

### Sub-feature: 000_ANDN

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  andn rd, rs1, rs2  
  x[rd] = x[rs1] & ~x[rs2]  
  Bit-wise AND rs1 with the bit-wise inverted rs2 value and store the result in rd.
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
   All possible rs2 registers are used.  
  All possible rd registers are used.  
   All possible register combinations where rs1 == rd are used  
  All possible register combinations where rs2 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F021_S000_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  andn rd, rs1, rs2  
  x[rd] = x[rs1] & ~x[rs2]  
  Bit-wise AND rs1 with the bit-wise inverted rs2 value and store the result in rd.
* **Verification Goals**
  
  Input operands:  
    
  rs1 value is No-zero and zero  
  rs2 value is No-zero and zero  
  All bits of rs1 are toggled  
  All bits of rs2 are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F021_S000_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  andn rd, rs1, rs2  
  x[rd] = x[rs1] & ~x[rs2]  
  Bit-wise AND rs1 with the bit-wise inverted rs2 value and store the result in rd.
* **Verification Goals**
  
  Output result:  
    
  rd value is No-zero and zero  
  All bits of rd are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F021_S000_I002
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 001_CLZ

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  clz rd, rs1  
  x[rd] = countzeroesmsb(rs1)  
  counts the number of 0's before the first 1, starting at the MSB bit.
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
   All possible rd registers are used.  
  All possible register combinations where rs1 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F021_S001_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  clz rd, rs1  
  x[rd] = countzeroesmsb(rs1)  
  counts the number of 0's before the first 1, starting at the MSB bit.
* **Verification Goals**
  
  Input operands:  
    
  rs1 value is No-zero and zero  
  All bits of rs1 are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F021_S001_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  clz rd, rs1  
  x[rd] = countzeroesmsb(rs1)  
  counts the number of 0's before the first 1, starting at the MSB bit.
* **Verification Goals**
  
  Output result:  
    
  rd value is No-zero and zero  
  All bits of rd are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F021_S001_I002
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 002_CPOP

#### Item: 000

* **Requirement location:** ./RISCV_Instruction.rst
* **Feature Description**
  
  cpop rd, rs1  
  x[rd] = countones(rs1)  
  Counts the number of 1's in the source register, and place the value in rd.
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
   All possible rd registers are used.  
  All possible register combinations where rs1 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F021_S002_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instruction.rst
* **Feature Description**
  
  cpop rd, rs1  
  x[rd] = countones(rs1)  
  Counts the number of 1's in the source register, and place the value in rd.
* **Verification Goals**
  
  Input operands:  
    
  rs1 value is No-zero and zero  
  All bits of rs1 are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F021_S002_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instruction.rst
* **Feature Description**
  
  cpop rd, rs1  
  x[rd] = countones(rs1)  
  Counts the number of 1's in the source register, and place the value in rd.
* **Verification Goals**
  
  Output result:  
    
  rd value is No-zero and zero  
  All bits of rd are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F021_S002_I002
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 003_CTZ

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  ctz rd, rs1  
  x[rd] = countzeroeslsb(rs1)  
  counts the number of 0's before the first 1, starting at the LSB bit.
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
   All possible rd registers are used.  
  All possible register combinations where rs1 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F021_S003_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  ctz rd, rs1  
  x[rd] = countzeroeslsb(rs1)  
  counts the number of 0's before the first 1, starting at the LSB bit.
* **Verification Goals**
  
  Input operands:  
    
  rs1 value is No-zero and zero  
  All bits of rs1 are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F021_S003_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  ctz rd, rs1  
  x[rd] = countzeroeslsb(rs1)  
  counts the number of 0's before the first 1, starting at the LSB bit.
* **Verification Goals**
  
  Output result:  
    
  rd value is No-zero and zero  
  All bits of rd are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F021_S003_I002
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 004_MAX

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  max rd, rs1, rs2  
  x[rd] = max_signed(rs1, rs2)  
  Place the greater value between rs1, rs2 (signed values) into rd.
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
   All possible rs2 registers are used.  
  All possible rd registers are used.  
   All possible register combinations where rs1 == rd are used  
  All possible register combinations where rs2 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F021_S004_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  max rd, rs1, rs2  
  x[rd] = max_signed(rs1, rs2)  
  Place the greater value between rs1, rs2 (signed values) into rd.
* **Verification Goals**
  
  Input operands:  
    
  rs1 value is +ve, -ve and zero  
  rs2 value is +ve, -ve and zero  
  All combinations of rs1 and rs2 +ve, -ve, and zero values are used  
  All bits of rs1 are toggled  
  All bits of rs2 are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F021_S004_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  max rd, rs1, rs2  
  x[rd] = max_signed(rs1, rs2)  
  Place the greater value between rs1, rs2 (signed values) into rd.
* **Verification Goals**
  
  Output result:  
    
  rd value is +ve, -ve and zero  
  All bits of rd are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F021_S004_I002
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 005_MAXU

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  maxu rd, rs1, rs2  
  x[rd] = max_unsigned(rs1, rs2)  
  Place the greater value between rs1, rs2 (unsigned values) into rd.
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
   All possible rs2 registers are used.  
  All possible rd registers are used.  
   All possible register combinations where rs1 == rd are used  
  All possible register combinations where rs2 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F021_S005_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  maxu rd, rs1, rs2  
  x[rd] = max_unsigned(rs1, rs2)  
  Place the greater value between rs1, rs2 (unsigned values) into rd.
* **Verification Goals**
  
  Input operands:  
    
  rs1 value is No-zero and zero  
  rs2 value is No-zero and zero  
  All bits of rs1 are toggled  
  All bits of rs2 are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F021_S005_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  maxu rd, rs1, rs2  
  x[rd] = max_unsigned(rs1, rs2)  
  Place the greater value between rs1, rs2 (unsigned values) into rd.
* **Verification Goals**
  
  Output result:  
    
  rd value is No-zero and zero  
  All bits of rd are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F021_S005_I002
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 006_MIN

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  min rd, rs1, rs2  
  x[rd] = min_signed(rs1, rs2)  
  Place the lesser value between rs1, rs2 (signed values) into rd.
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
   All possible rs2 registers are used.  
  All possible rd registers are used.  
   All possible register combinations where rs1 == rd are used  
  All possible register combinations where rs2 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F021_S006_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  min rd, rs1, rs2  
  x[rd] = min_signed(rs1, rs2)  
  Place the lesser value between rs1, rs2 (signed values) into rd.
* **Verification Goals**
  
  Input operands:  
    
  rs1 value is +ve, -ve and zero  
  rs2 value is +ve, -ve and zero  
  All combinations of rs1 and rs2 +ve, -ve, and zero values are used  
  All bits of rs1 are toggled  
  All bits of rs2 are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F021_S006_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  min rd, rs1, rs2  
  x[rd] = min_signed(rs1, rs2)  
  Place the lesser value between rs1, rs2 (signed values) into rd.
* **Verification Goals**
  
  Output result:  
    
  rd value is +ve, -ve and zero  
  All bits of rd are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F021_S006_I002
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 007_MINU

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  minu rd, rs1, rs2  
  x[rd] = min_unsigned(rs1, rs2)  
  Place the lesser value between rs1, rs2 (unsigned values) into rd.
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
   All possible rs2 registers are used.  
  All possible rd registers are used.  
   All possible register combinations where rs1 == rd are used  
  All possible register combinations where rs2 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F021_S007_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  minu rd, rs1, rs2  
  x[rd] = min_unsigned(rs1, rs2)  
  Place the lesser value between rs1, rs2 (unsigned values) into rd.
* **Verification Goals**
  
  Input operands:  
    
  rs1 value is No-zero and zero  
  rs2 value is No-zero and zero  
  All bits of rs1 are toggled  
  All bits of rs2 are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F021_S007_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  minu rd, rs1, rs2  
  x[rd] = min_unsigned(rs1, rs2)  
  Place the lesser value between rs1, rs2 (unsigned values) into rd.
* **Verification Goals**
  
  Output result:  
    
  rd value is No-zero and zero  
  All bits of rd are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F021_S007_I002
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 008_ORC_B

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  orc.b rd, rs1  
  x[rd] = {rs1[31:24] ? 8'hff : 8'h00,   
           rs1[23:16] ? 8'hff : 8'h00,  
           rs1[15:8] ? 8'hff : 8'h00,  
           rs1[7:0] ? 8'hff : 8'h00}  
    
  For each byte of rs1, if the value is zero, the corresponding output value byte is set to all zeroes, otherwise ones.
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
   All possible rd registers are used.  
  All possible register combinations where rs1 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F021_S008_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  orc.b rd, rs1  
  x[rd] = {rs1[31:24] ? 8'hff : 8'h00,   
           rs1[23:16] ? 8'hff : 8'h00,  
           rs1[15:8] ? 8'hff : 8'h00,  
           rs1[7:0] ? 8'hff : 8'h00}  
    
  For each byte of rs1, if the value is zero, the corresponding output value byte is set to all zeroes, otherwise ones.
* **Verification Goals**
  
  Input operands:  
    
  rs1 value is No-zero and zero  
  All bits of rs1 are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F021_S008_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  orc.b rd, rs1  
  x[rd] = {rs1[31:24] ? 8'hff : 8'h00,   
           rs1[23:16] ? 8'hff : 8'h00,  
           rs1[15:8] ? 8'hff : 8'h00,  
           rs1[7:0] ? 8'hff : 8'h00}  
    
  For each byte of rs1, if the value is zero, the corresponding output value byte is set to all zeroes, otherwise ones.
* **Verification Goals**
  
  Output result:  
    
  rd value is No-zero and zero  
  All bits of rd are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F021_S008_I002
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 009_ORN

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  orn rd, rs1, rs2  
  x[rd] = x[rs1] | ~x[rs2]  
  Bit-wise OR rs1 with the bit-wise inverted rs2 value and store the result in rd.
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
   All possible rs2 registers are used.  
  All possible rd registers are used.  
   All possible register combinations where rs1 == rd are used  
  All possible register combinations where rs2 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F021_S009_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  orn rd, rs1, rs2  
  x[rd] = x[rs1] | ~x[rs2]  
  Bit-wise OR rs1 with the bit-wise inverted rs2 value and store the result in rd.
* **Verification Goals**
  
  Input operands:  
    
  rs1 value is No-zero and zero  
  rs2 value is No-zero and zero  
  All bits of rs1 are toggled  
  All bits of rs2 are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F021_S009_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  orn rd, rs1, rs2  
  x[rd] = x[rs1] | ~x[rs2]  
  Bit-wise OR rs1 with the bit-wise inverted rs2 value and store the result in rd.
* **Verification Goals**
  
  Output result:  
    
  rd value is No-zero and zero  
  All bits of rd are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F021_S009_I002
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 010_REV8

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  rev8 rd, rs1  
  x[rd] = {rs1[7:0], rs1[15:8], rs1[23:16], rs1[31:24]}  
   Perform an endian swap by swapping bytes in the value in rs1 and place it in rd.
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
   All possible rd registers are used.  
  All possible register combinations where rs1 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F021_S010_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  rev8 rd, rs1  
  x[rd] = {rs1[7:0], rs1[15:8], rs1[23:16], rs1[31:24]}  
   Perform an endian swap by swapping bytes in the value in rs1 and place it in rd.
* **Verification Goals**
  
  Input operands:  
    
  rs1 value is No-zero and zero  
  All bits of rs1 are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F021_S010_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  rev8 rd, rs1  
  x[rd] = {rs1[7:0], rs1[15:8], rs1[23:16], rs1[31:24]}  
   Perform an endian swap by swapping bytes in the value in rs1 and place it in rd.
* **Verification Goals**
  
  Output result:  
    
  rd value is No-zero and zero  
  All bits of rd are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F021_S010_I002
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 011_ROR

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  ror rd, rs1, rs2  
  x[rd] = rs1 rotate_right rs2[4:0]  
  rs1 is shifted right by the number of bits in rs2[4:0].  
  Any bits shifted out of the LSB are shifted into the MSB of the output value.
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
   All possible rs2 registers are used.  
  All possible rd registers are used.  
   All possible register combinations where rs1 == rd are used  
  All possible register combinations where rs2 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F021_S011_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  ror rd, rs1, rs2  
  x[rd] = rs1 rotate_right rs2[4:0]  
  rs1 is shifted right by the number of bits in rs2[4:0].  
  Any bits shifted out of the LSB are shifted into the MSB of the output value.
* **Verification Goals**
  
  Input operands:  
    
  rs1 value is No-zero and zero  
  rs2 value is No-zero and zero  
  All bits of rs1 are toggled  
  All bits of rs2 are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F021_S011_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  ror rd, rs1, rs2  
  x[rd] = rs1 rotate_right rs2[4:0]  
  rs1 is shifted right by the number of bits in rs2[4:0].  
  Any bits shifted out of the LSB are shifted into the MSB of the output value.
* **Verification Goals**
  
  Output result:  
    
  rd value is No-zero and zero  
  All bits of rd are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F021_S011_I002
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 012_ROL

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  rol rd, rs1, rs2  
  x[rd] = rs1 rotate_left rs2[4:0]  
  rs1 is shifted left by the number of bits in rs2[4:0].  
  Any bits shifted out of the MSB are shifted into the LSB of the output value.
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
   All possible rs2 registers are used.  
  All possible rd registers are used.  
   All possible register combinations where rs1 == rd are used  
  All possible register combinations where rs2 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F021_S012_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  rol rd, rs1, rs2  
  x[rd] = rs1 rotate_left rs2[4:0]  
  rs1 is shifted left by the number of bits in rs2[4:0].  
  Any bits shifted out of the MSB are shifted into the LSB of the output value.
* **Verification Goals**
  
  Input operands:  
    
  rs1 value is No-zero and zero  
  rs2 value is No-zero and zero  
  All bits of rs1 are toggled  
  All bits of rs2 are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F021_S012_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  rol rd, rs1, rs2  
  x[rd] = rs1 rotate_left rs2[4:0]  
  rs1 is shifted left by the number of bits in rs2[4:0].  
  Any bits shifted out of the MSB are shifted into the LSB of the output value.
* **Verification Goals**
  
  Output result:  
    
  rd value is No-zero and zero  
  All bits of rd are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F021_S012_I002
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 013_RORI

#### Item: 000

* **Requirement location:** 
* **Feature Description**
  
  rori rd, rs1, imm  
  x[rd] = rs1 rotate_right imm  
  rs1 is shifted right by the number of bits in immediate value.  
  Any bits shifted out of the LSB are shifted into the MSB of the output value.
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
   All possible rd registers are used.  
  All possible register combinations where rs1 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F021_S013_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** 
* **Feature Description**
  
  rori rd, rs1, imm  
  x[rd] = rs1 rotate_right imm  
  rs1 is shifted right by the number of bits in immediate value.  
  Any bits shifted out of the LSB are shifted into the MSB of the output value.
* **Verification Goals**
  
  Input operands:  
    
  rs1 value is No-zero and zero  
  All bits of rs1 are toggled  
  All bits of imm are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F021_S013_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** 
* **Feature Description**
  
  rori rd, rs1, imm  
  x[rd] = rs1 rotate_right imm  
  rs1 is shifted right by the number of bits in immediate value.  
  Any bits shifted out of the LSB are shifted into the MSB of the output value.
* **Verification Goals**
  
  Output result:  
    
  rd value is No-zero and zero  
  All bits of rd are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F021_S013_I002
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 014_SEXT_B

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  sext.b rd, rs1  
  x[rd] = sext(x[rs1][7:0])  
  It sign-extends the least-significant byte of rs1, and store result in rd.
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
   All possible rd registers are used.  
  All possible register combinations where rs1 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F021_S014_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  sext.b rd, rs1  
  x[rd] = sext(x[rs1][7:0])  
  It sign-extends the least-significant byte of rs1, and store result in rd.
* **Verification Goals**
  
  Input operands:  
    
  rs1 value is +ve, -ve and zero  
  All bits of rs1 are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F021_S014_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  sext.b rd, rs1  
  x[rd] = sext(x[rs1][7:0])  
  It sign-extends the least-significant byte of rs1, and store result in rd.
* **Verification Goals**
  
  Output result:  
    
  rd value is +127, -128 and zero  
  All bits of rd are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F021_S014_I002
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 015_SEXT_H

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  sext.h rd, rs1  
  x[rd] = sext(x[rs1][15:0])  
  It sign-extends the least-significant half-word of rs1, and store result in rd.
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
   All possible rd registers are used.  
  All possible register combinations where rs1 == rd are used
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F021_S015_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  sext.h rd, rs1  
  x[rd] = sext(x[rs1][15:0])  
  It sign-extends the least-significant half-word of rs1, and store result in rd.
* **Verification Goals**
  
  Input operands:  
    
  rs1 value is no-zero and zero  
  All bits of rs1 are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F021_S015_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  sext.h rd, rs1  
  x[rd] = sext(x[rs1][15:0])  
  It sign-extends the least-significant half-word of rs1, and store result in rd.
* **Verification Goals**
  
  Output result:  
    
  rd value is +ve, -ve and zero  
  All bits of rd are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F021_S015_I002
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 016_XNOR

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  xnor rd, rs1, rs2  
  x[rd] = x[rs1] ^ ~x[rs2]  
  Bit-wise XOR rs1 with the bit-wise inverted rs2 value and store the result in rd.
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
   All possible rs2 registers are used.  
  All possible rd registers are used.  
   All possible register combinations where rs1 == rd are used  
  All possible register combinations where rs2 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F021_S016_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  xnor rd, rs1, rs2  
  x[rd] = x[rs1] ^ ~x[rs2]  
  Bit-wise XOR rs1 with the bit-wise inverted rs2 value and store the result in rd.
* **Verification Goals**
  
  Input operands:  
    
  rs1 value is No-zero and zero  
  rs2 value is No-zero and zero  
  All bits of rs1 are toggled  
  All bits of rs2 are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F021_S016_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  xnor rd, rs1, rs2  
  x[rd] = x[rs1] ^ ~x[rs2]  
  Bit-wise XOR rs1 with the bit-wise inverted rs2 value and store the result in rd.
* **Verification Goals**
  
  Output result:  
    
  rd value is No-zero and zero  
  All bits of rd are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F021_S016_I002
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 017_ZEXT_H

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  zext.h rd, rs1  
  x[rd] = zext(x[rs1][15:0])  
  It zero-extends the least-significant half-word of rs1, and store result in rd.
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
   All possible rd registers are used.  
  All possible register combinations where rs1 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F021_S017_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  zext.h rd, rs1  
  x[rd] = zext(x[rs1][15:0])  
  It zero-extends the least-significant half-word of rs1, and store result in rd.
* **Verification Goals**
  
  Input operands:  
    
  rs1 value is No-zero and zero  
  All bits of rs1 are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F021_S017_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  zext.h rd, rs1  
  x[rd] = zext(x[rs1][15:0])  
  It zero-extends the least-significant half-word of rs1, and store result in rd.
* **Verification Goals**
  
  Output result:  
    
  rd value is No-zero and zero  
  All bits of rd are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F021_S017_I002
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
## Feature: RV32Zbs Single-bit instructions

### Sub-feature: 000_BCLR

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  bclr rd, rs1, rs2  
  x[rd] = x[rs1] & ~(0x1 << x[rs2[4:0]])  
  The bit position defined by the lower log2(XLEN) bits of rs2 is cleared in rs1 and placed in rd.
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
   All possible rs2 registers are used.  
  All possible rd registers are used.  
   All possible register combinations where rs1 == rd are used  
  All possible register combinations where rs2 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F022_S000_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  bclr rd, rs1, rs2  
  x[rd] = x[rs1] & ~(0x1 << x[rs2[4:0]])  
  The bit position defined by the lower log2(XLEN) bits of rs2 is cleared in rs1 and placed in rd.
* **Verification Goals**
  
  Input operands:  
    
  rs1 value is No-zero and zero  
  rs2 value is No-zero and zero  
  All bits of rs1 are toggled  
  All bits of rs2 are toggled
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F022_S000_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  bclr rd, rs1, rs2  
  x[rd] = x[rs1] & ~(0x1 << x[rs2[4:0]])  
  The bit position defined by the lower log2(XLEN) bits of rs2 is cleared in rs1 and placed in rd.
* **Verification Goals**
  
  Output result:  
    
  rd value is No-zero and zero  
  All bits of rd are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F022_S000_I002
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 001_BCLRI

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  bclri rd, rs1, imm[4:0]  
  x[rd] = x[rs1] & ~(0x1 << imm)  
  The bit position defined by the lower log2(XLEN) bits of immediate is cleared in rs1 and placed in rd.
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
   All possible rd registers are used.  
  All possible register combinations where rs1 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F022_S001_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  bclri rd, rs1, imm[4:0]  
  x[rd] = x[rs1] & ~(0x1 << imm)  
  The bit position defined by the lower log2(XLEN) bits of immediate is cleared in rs1 and placed in rd.
* **Verification Goals**
  
  Input operands:  
    
  rs1 value is No-zero and zero  
  All bits of rs1 are toggled  
  All bits of imm are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F022_S001_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  bclri rd, rs1, imm[4:0]  
  x[rd] = x[rs1] & ~(0x1 << imm)  
  The bit position defined by the lower log2(XLEN) bits of immediate is cleared in rs1 and placed in rd.
* **Verification Goals**
  
  Output result:  
    
  rd value is No-zero and zero  
  All bits of rd are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F022_S001_I002
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 002_BEXT

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  bext rd, rs1, rs2  
  x[rd] = (x[rs1] >> x[rs2[4:0]]) & 0x1  
  The bit position defined by the lower log2(XLEN) bits of rs2 is extract in rs1 and placed in LSB of rd.
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
   All possible rs2 registers are used.  
  All possible rd registers are used.  
   All possible register combinations where rs1 == rd are used  
  All possible register combinations where rs2 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F022_S002_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  bext rd, rs1, rs2  
  x[rd] = (x[rs1] >> x[rs2[4:0]]) & 0x1  
  The bit position defined by the lower log2(XLEN) bits of rs2 is extract in rs1 and placed in LSB of rd.
* **Verification Goals**
  
  Input operands:  
    
  rs1 value is No-zero and zero  
  rs2 value is No-zero and zero  
  All bits of rs1 are toggled  
  All bits of rs2 are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F022_S002_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  bext rd, rs1, rs2  
  x[rd] = (x[rs1] >> x[rs2[4:0]]) & 0x1  
  The bit position defined by the lower log2(XLEN) bits of rs2 is extract in rs1 and placed in LSB of rd.
* **Verification Goals**
  
  Output result:  
    
  rd value is No-zero and zero  
  All bits of rd are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F022_S002_I002
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 003_BEXTI

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  bexti rd, rs1, imm[4:0]  
  x[rd] = (x[rs1] >> imm) & 0x1  
  The bit position defined by the lower log2(XLEN) bits of immediate is extract in rs1 and placed in LSB of rd.
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
   All possible rd registers are used.  
  All possible register combinations where rs1 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F022_S003_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  bexti rd, rs1, imm[4:0]  
  x[rd] = (x[rs1] >> imm) & 0x1  
  The bit position defined by the lower log2(XLEN) bits of immediate is extract in rs1 and placed in LSB of rd.
* **Verification Goals**
  
  Input operands:  
    
  rs1 value is No-zero and zero  
  All bits of rs1 are toggled  
  All bits of imm are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F022_S003_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  bexti rd, rs1, imm[4:0]  
  x[rd] = (x[rs1] >> imm) & 0x1  
  The bit position defined by the lower log2(XLEN) bits of immediate is extract in rs1 and placed in LSB of rd.
* **Verification Goals**
  
  Output result:  
    
  rd value is No-zero and zero  
  All bits of rd are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F022_S003_I002
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 004_BINV

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  binv rd, rs1, rs2  
  x[rd] = x[rs1] ^ (0x1 << x[rs2[4:0]])  
  The bit position defined by the lower log2(XLEN) bits of rs2 is inverted in rs1 and placed in rd.
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
   All possible rs2 registers are used.  
  All possible rd registers are used.  
   All possible register combinations where rs1 == rd are used  
  All possible register combinations where rs2 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F022_S004_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  binv rd, rs1, rs2  
  x[rd] = x[rs1] ^ (0x1 << x[rs2[4:0]])  
  The bit position defined by the lower log2(XLEN) bits of rs2 is inverted in rs1 and placed in rd.
* **Verification Goals**
  
  Input operands:  
    
  rs1 value is No-zero and zero  
  rs2 value is No-zero and zero  
  All bits of rs1 are toggled  
  All bits of rs2 are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F022_S004_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  binv rd, rs1, rs2  
  x[rd] = x[rs1] ^ (0x1 << x[rs2[4:0]])  
  The bit position defined by the lower log2(XLEN) bits of rs2 is inverted in rs1 and placed in rd.
* **Verification Goals**
  
  Output result:  
    
  rd value is No-zero and zero  
  All bits of rd are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F022_S004_I002
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 005_BINVI

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  binvi rd, rs1, imm[4:0]  
  x[rd] = x[rs1] ^ (0x1 << imm)  
  The bit position defined by the lower log2(XLEN) bits of immediate is inverted in rs1 and placed in rd.
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
   All possible rd registers are used.  
  All possible register combinations where rs1 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F022_S005_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  binvi rd, rs1, imm[4:0]  
  x[rd] = x[rs1] ^ (0x1 << imm)  
  The bit position defined by the lower log2(XLEN) bits of immediate is inverted in rs1 and placed in rd.
* **Verification Goals**
  
  Input operands:  
    
  rs1 value is No-zero and zero  
  All bits of rs1 are toggled  
  All bits of imm are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F022_S005_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  binvi rd, rs1, imm[4:0]  
  x[rd] = x[rs1] ^ (0x1 << imm)  
  The bit position defined by the lower log2(XLEN) bits of immediate is inverted in rs1 and placed in rd.
* **Verification Goals**
  
  Output result:  
    
  rd value is No-zero and zero  
  All bits of rd are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F022_S005_I002
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 006_BSET

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  bset rd, rs1, rs2  
  x[rd] = x[rs1] | (0x1 << x[rs2[4:0]])  
  The bit position defined by the lower log2(XLEN) bits of rs2 is set in rs1 and placed in rd.
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
   All possible rs2 registers are used.  
  All possible rd registers are used.  
   All possible register combinations where rs1 == rd are used  
  All possible register combinations where rs2 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F022_S006_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  bset rd, rs1, rs2  
  x[rd] = x[rs1] | (0x1 << x[rs2[4:0]])  
  The bit position defined by the lower log2(XLEN) bits of rs2 is set in rs1 and placed in rd.
* **Verification Goals**
  
  Input operands:  
    
  rs1 value is No-zero and zero  
  rs2 value is No-zero and zero  
  All bits of rs1 are toggled  
  All bits of rs2 are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F022_S006_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  bset rd, rs1, rs2  
  x[rd] = x[rs1] | (0x1 << x[rs2[4:0]])  
  The bit position defined by the lower log2(XLEN) bits of rs2 is set in rs1 and placed in rd.
* **Verification Goals**
  
  Output result:  
    
  rd value is No-zero and zero  
  All bits of rd are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F022_S006_I002
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 007_BSETI

#### Item: 000

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  bseti rd, rs1, imm[4:0]  
  x[rd] = x[rs1] | (0x1 << imm)  
  The bit position defined by the lower log2(XLEN) bits of immediate is set in rs1 and placed in rd.
* **Verification Goals**
  
  Register operands:  
    
  All possible rs1 registers are used.  
   All possible rd registers are used.  
  All possible register combinations where rs1 == rd are used
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F022_S007_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 001

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  bseti rd, rs1, imm[4:0]  
  x[rd] = x[rs1] | (0x1 << imm)  
  The bit position defined by the lower log2(XLEN) bits of immediate is set in rs1 and placed in rd.
* **Verification Goals**
  
  Input operands:  
    
  rs1 value is No-zero and zero  
  All bits of rs1 are toggled  
  All bits of imm are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F022_S007_I001
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 002

* **Requirement location:** ./RISCV_Instructions.rst
* **Feature Description**
  
  bseti rd, rs1, imm[4:0]  
  x[rd] = x[rs1] | (0x1 << imm)  
  The bit position defined by the lower log2(XLEN) bits of immediate is set in rs1 and placed in rd.
* **Verification Goals**
  
  Output result:  
    
  rd value is No-zero and zero  
  All bits of rd are toggled
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_ISA_RV32_F022_S007_I002
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
