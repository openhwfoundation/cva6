# Module: CSR EMBEDDED ACCESS VERIFICATION

## Feature: CVA6 CSRs reset value

### Sub-feature: 000_Read register value after boot

#### Item: 000

* **Requirement location:** https://docs.openhwgroup.org/projects/cva6-user-manual/01_cva6_user/CV32A6_Control_Status_Registers.html
* **Feature Description**
  
  After hardware reset and boot execution, RISC-V CVA6 CSRs registers must initialize to their respective reset value specified in the RISC-V CVA6 user manual. Read reset values should match reference model.
* **Verification Goals**
  
  1.Apply hard reset.  
  2.Read all CSRs using read instructions.  
   3.Ensure that read values of the CSR should be as per CVA6 user manual and match reference model.
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Directed Non-SelfChk
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_csr-embedded-access_F000_S000_I000
* **Link to Coverage:** uvme_cva6_pkg.csr_reg_cov.\*.\*__read_cg
* **Comments**
  
  Applicable to all CSR addresses
## Feature: CVA6 CSRs read after write

### Sub-feature: 000_Read after write RW registers

#### Item: 000

* **Requirement location:** https://docs.openhwgroup.org/projects/cva6-user-manual/01_cva6_user/CV32A6_Control_Status_Registers.html
* **Feature Description**
  
  Check the correctness of RISCV CVA6 CSRs write and read register operations by writing in a random order CSRs with values: Inverted reset, 0xaaaaaaaa, 0x555555 and random values after applying not testable register fields mask to the written value, then read back the CSRs. Read values should match reference model.
* **Verification Goals**
  
  1.Verify that CSR can be written using the appropriate CSR write instructions.  
  2.Ensure correct read operations using CSR read instructions.  
   3.Ensure that read values of the CSR should be as per CVA6 user manual.
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Directed Non-SelfChk
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_csr-embedded-access_F001_S000_I000
* **Link to Coverage:** uvme_cva6_pkg.csr_reg_cov.\*.\*__write_cg; uvme_cva6_pkg.csr_reg_cov.\*.\*__read_cg
* **Comments**
  
  Related RW Registers: mstatus, misa, mie, mtvec, mstatush, mhpmevent[3-31], mscratch, mepc, mcause, mtval, mip, pmpcfg[0-15], icache, mcycle, minstret, mcycleh, minstreth, mhpmcounter[3..31], mhpmcounterh[3..31]
### Sub-feature: 001_Read after write RO registers

#### Item: 000

* **Requirement location:** https://docs.openhwgroup.org/projects/cva6-user-manual/01_cva6_user/CV32A6_Control_Status_Registers.html
* **Feature Description**
  
  Check the correctness of RISCV CVA6 Read-Only CSRs by writing CSRs in a random order values: Inverted reset, 0xaaaaaaaa, 0x555555, random values. Then confirm that write into RO CSRs generates illegal exception. Finally read back the CSR and check register value has not changed and matches reference model.
* **Verification Goals**
  
  1.Attempt to write a RO CSR.  
  2.Check to see that an illegal instruction exception occurred.  
  3.Immediately after returning from the exception handler, read CSR to check that it value has not changed.
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Directed Non-SelfChk
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_csr-embedded-access_F001_S001_I000
* **Link to Coverage:** uvme_cva6_pkg.csr_reg_cov.\*.\*__write_cg; uvme_cva6_pkg.csr_reg_cov.\*.\*__read_cg
* **Comments**
  
  Related RO registers: cycle, instret, cycleh, instreth, mvendorid, marchid, mimpid, mhartid
### Sub-feature: 002_Write and Read all CSR addresses

#### Item: 000

* **Requirement location:** https://docs.openhwgroup.org/projects/cva6-user-manual/01_cva6_user/CV32A6_Control_Status_Registers.html
* **Feature Description**
  
  Check the correctness of RISCV CVA6 all CSR addresses write and read operations by writing random value to CSR address from 0 to 0xFFF in a random order. Then confirm that write into unmapped addresses generates illegal exception. Finaly read the CSRs in a random order and check that it also generates illegal exception in unmapped addresses.
* **Verification Goals**
  
  1.Write and read all CSR addresses.  
  2.Check to see that an illegal instruction exception occurred bor both write and read operations in all unmapped address.
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Testcase
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_csr-embedded-access_F001_S002_I000
* **Link to Coverage:** riscv_arithmetic_basic_illegal_csr.S
* **Comments**
  
  Related register addresses: all unoccupied addresses from 0x0 to 0xFFF
## Feature: CVA6 CSRs counters functionality checking

### Sub-feature: 000_Counter value

#### Item: 000

* **Requirement location:** https://docs.openhwgroup.org/projects/cva6-user-manual/01_cva6_user/CV32A6_Control_Status_Registers.html
* **Feature Description**
  
  Check that counter registers cycle/mcycle and cycleh/mcycleh increment at each clock.
* **Verification Goals**
  
  Performing two continuous reads to the same register and ensure that the value of the second read from counter CSR is greater than the value of the initial read.
* **Pass/Fail Criteria:** Self-Check
* **Test Type:** Directed SelfChk
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_csr-embedded-access_F002_S000_I000
* **Link to Coverage:** 
* **Comments**
  
  In a RISC-V 32bits architecture cycle/mcycle and cycleh/mcycleh holds low 32 bits and high 32 bits respectively of the count of clock cycles executed by the processor.
#### Item: 001

* **Requirement location:** https://docs.openhwgroup.org/projects/cva6-user-manual/01_cva6_user/CV32A6_Control_Status_Registers.html
* **Feature Description**
  
  Check that counter registers instret/instreth and minstret/minstreth increment after each instruction and values match reference model.
* **Verification Goals**
  
  Performing two continuous reads to the same register and ensure that the value of the second read from counter CSR is greater than the value of the initial read.
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Directed SelfChk
* **Coverage Method:** Testcase
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_csr-embedded-access_F002_S000_I001
* **Link to Coverage:** 
* **Comments**
  
  In a RISC-V 32bits architecture instret/minstret and instreth/minstreth holds low 32 bits and high 32 bits respectively of the count of executed instructions by the processor.
### Sub-feature: 001_Counter overflow

#### Item: 000

* **Requirement location:** https://docs.openhwgroup.org/projects/cva6-user-manual/01_cva6_user/CV32A6_Control_Status_Registers.html
* **Feature Description**
  
  Check the behaviour of counter CSRs cycle, cycleh, mcycle, mcycleh when reaching maximum value.  
  cycle and mcycle should be 0 after reaching maximum value and cycleh/mcycleh should increment by 1. cycleh/mcycleh should be set to 0 after reaching maximum value.
* **Verification Goals**
  
  1- Write mcycle/mcycleh to higher or maximum 32bit value.  
   2- Perform some random read/write CSR registers.  
  3- Ensure that counters reset to 0.
* **Pass/Fail Criteria:** Self-Check
* **Test Type:** Directed SelfChk
* **Coverage Method:** Testcase
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_csr-embedded-access_F002_S001_I000
* **Link to Coverage:** 
* **Comments**
  
  Related counter registers: cycle, cycleh, mcycle, mcycleh.
#### Item: 001

* **Requirement location:** https://docs.openhwgroup.org/projects/cva6-user-manual/01_cva6_user/CV32A6_Control_Status_Registers.html
* **Feature Description**
  
  Check the behaviour of counter CSRs instret, instreth, minstret, minstreth when reaching maximum value which should match reference model.   
  instret and minstret should be 0 after reaching maximum value and instreth/minstreth should increment by 1. instreth/minstreth should be set to 0 after reaching maximum value.
* **Verification Goals**
  
  1- Write minstret/minstreth to higher or maximum 32bit value.  
   2- Perform some random read/write CSR registers.  
  3- Ensure that counters reset to 0.
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Directed SelfChk
* **Coverage Method:** Testcase
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_csr-embedded-access_F002_S001_I001
* **Link to Coverage:** 
* **Comments**
  
  Related counter registers: instret, instreth, minstret, minstreth.
