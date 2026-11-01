# Module: FENCEI

## Feature: Fetching 

### Sub-feature: 000_Fetching

#### Item: 000

* **Requirement location:** CVA6 User Manual; https://cva6.readthedocs.io/en/latest/01_cva6_user/RISCV_Instructions.html#rv32zifencei-instruction-fetch-fence
* **Feature Description**
  
  Instruction data for the next PC must be fetched after the fence.i instruction has executed (because only then can data-side stores have completed and caches have been updated).
* **Verification Goals**
  
  Check that after a fence.i instruction retires then instr-side obi fetches the next instruction to be executed.
* **Pass/Fail Criteria:** Assertion
* **Test Type:** ENV Capability
* **Coverage Method:** Assertion Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_FENCEI_F000_S000_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
## Feature: StoresVisible

### Sub-feature: 000_StoresVisible

#### Item: 000

* **Requirement location:** The RISC-V Instruction Set Manual
Volume I: Unprivileged ISA
Document Version 20191213
https://riscv.org/wp-content/uploads/2019/12/riscv-spec-20191213.pdf
* **Feature Description**
  
  After a fence.i instruction has been executed, all preceding store instructions shall have their effects visible to the instruction fetch of the instructions that are to be executed after the fence.i instruction.
* **Verification Goals**
  
  Do a fencei, but right before the fencei do a store to the instruction following the fencei, then see that the newly stored value is executed instead of the old instruction (e.g. change addi to use a different immediate).
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_FENCEI_F001_S000_I000
* **Link to Coverage:** 
* **Comments**
  
  TODO must be added to regression lists!
#### Item: 001

* **Requirement location:** The RISC-V Instruction Set Manual
Volume I: Unprivileged ISA
Document Version 20191213
https://riscv.org/wp-content/uploads/2019/12/riscv-spec-20191213.pdf
* **Feature Description**
  
  After a fence.i instruction has been executed, all preceding store instructions shall have their effects visible to the instruction fetch of the instructions that are to be executed after the fence.i instruction.
* **Verification Goals**
  
  Do a fencei followed by any instruction, but let the environment detect when the fencei is being executed and change the memory holding the next instruction, then see that the old instruction is not executed.
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** Directed Non-SelfChk
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_FENCEI_F001_S000_I001
* **Link to Coverage:** 
* **Comments**
  
  TODO missing cover!
#### Item: 002

* **Requirement location:** The RISC-V Instruction Set Manual
Volume I: Unprivileged ISA
Document Version 20191213
https://riscv.org/wp-content/uploads/2019/12/riscv-spec-20191213.pdf
* **Feature Description**
  
  After a fence.i instruction has been executed, all preceding store instructions shall have their effects visible to the instruction fetch of the instructions that are to be executed after the fence.i instruction.
* **Verification Goals**
  
  Let the instruction right before a fence.i write a different instruction to the address following the fence.i, then observe that the written instruction is executed instead of the original one and that no side-effects (csr updates or otherwise) occur (can possibly mix 16bit/32bit instructions to force a noticeable difference).
* **Pass/Fail Criteria:** Self-Check
* **Test Type:** Directed SelfChk
* **Coverage Method:** Testcase
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_FENCEI_F001_S000_I002
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
#### Item: 003

* **Requirement location:** The RISC-V Instruction Set Manual
Volume I: Unprivileged ISA
Document Version 20191213
https://riscv.org/wp-content/uploads/2019/12/riscv-spec-20191213.pdf
* **Feature Description**
  
  After a fence.i instruction has been executed, all preceding store instructions shall have their effects visible to the instruction fetch of the instructions that are to be executed after the fence.i instruction.
* **Verification Goals**
  
  Check that after having read one value from an address, then after storing a value to that same address, if executing that address then the value shall always be that which was written (should work well in both sim/formal).
* **Pass/Fail Criteria:** Assertion
* **Test Type:** ENV Capability
* **Coverage Method:** Assertion Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_FENCEI_F001_S000_I003
* **Link to Coverage:** 
* **Comments**
  
  TODO missing assert. (Note was ignored because of the difficulty of writing this as an assert for fv.)!
## Feature: ExternalHandshake

### Sub-feature: 000_ReqHigh

#### Item: 000

* **Requirement location:** CVA6 User Manual; https://cva6.readthedocs.io/en/latest/01_cva6_user/RISCV_Instructions.html#rv32zifencei-instruction-fetch-fence
* **Feature Description**
  
  When executing a fence.i instruction, fencei_flush_req_o shall rise sometime before executing the next instruction.
* **Verification Goals**
  
  Check that when executing a fence.i instruction there will be a rising req before has retired.
* **Pass/Fail Criteria:** Assertion
* **Test Type:** ENV Capability
* **Coverage Method:** Assertion Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_FENCEI_F002_S000_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 001_ReqWaitLsu

#### Item: 000

* **Requirement location:** CVA6 User Manual; https://cva6.readthedocs.io/en/latest/01_cva6_user/RISCV_Instructions.html#rv32zifencei-instruction-fetch-fenceThis is a pointer to the source Requirements document of the Features in question.  The pointer should state the version of the target document.  It is free-form, so it can also indicate the specific section/page/paragraph.
* **Feature Description**
  
  When executing a fence.i instruction, if there is an ongoing store instruction (not limited to rv32i) that has not completed (data_rvalid_i clocked in as 1), then fencei_flush_req_o shall be low.
* **Verification Goals**
  
  Make sure a store instruction is run right before a fence.i, and (possibly using obi stalls) ensure that the fence.i is pending retirement but holds off until the store's data_rvalid_i is clocked in and that fencei_flush_req_o was low until this point where it now goes high.
* **Pass/Fail Criteria:** Assertion
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_FENCEI_F002_S001_I000
* **Link to Coverage:** 
* **Comments**
  
  TODO missing cover!
### Sub-feature: 002_ReqWaitWritebuffer

#### Item: 000

* **Requirement location:** CVA6 User Manual; https://cva6.readthedocs.io/en/latest/01_cva6_user/RISCV_Instructions.html#rv32zifencei-instruction-fetch-fence
* **Feature Description**
  
  When executing a fence.i instruction, if the write buffer is not empty, then fencei_flush_req_o shall be low until the write buffer has been emptied and the corresponding data_rvalid_i have been clocked in as 1.
* **Verification Goals**
  
  Fill up the write buffer prior to executing a fence.i and ensure that fencei_flush_req_o holds off going high until the write buffer to has been emptied.
* **Pass/Fail Criteria:** Assertion
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_FENCEI_F002_S002_I000
* **Link to Coverage:** 
* **Comments**
  
  TODO missing cover!
### Sub-feature: 003_ReqWaitXinterface

#### Item: 000

* **Requirement location:** CVA6 User Manual; https://cva6.readthedocs.io/en/latest/01_cva6_user/RISCV_Instructions.html#rv32zifencei-instruction-fetch-fence
* **Feature Description**
  
  When executing a fence.i instruction, if the X interface is busy with any store operations, then  fencei_flush_req_o shall be low until all the store operations are done
* **Verification Goals**
  
  Issue one or more store instructions that uses the X interface and ensure that fencei_flush_req_o waits until the stores have all completed before going high.
* **Pass/Fail Criteria:** Assertion
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_FENCEI_F002_S003_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 004_ReqWaitObi

#### Item: 000

* **Requirement location:** CVA6 User Manual; https://cva6.readthedocs.io/en/latest/01_cva6_user/RISCV_Instructions.html#rv32zifencei-instruction-fetch-fenceThis is a pointer to the source Requirements document of the Features in question.  The pointer should state the version of the target document.  It is free-form, so it can also indicate the specific section/page/paragraph.
* **Feature Description**
  
  fencei_flush_req_o shall not go high while there are outstanding stores on the obi bus.
* **Verification Goals**
  
  Check vs the OBI monitors that there are no outstanding stores at the time fencei_flush_req_o goes high.
* **Pass/Fail Criteria:** Assertion
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_FENCEI_F002_S004_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 005_ReqLow

#### Item: 000

* **Requirement location:** CVA6 User Manual; https://cva6.readthedocs.io/en/latest/01_cva6_user/RISCV_Instructions.html#rv32zifencei-instruction-fetch-fenceThis is a pointer to the source Requirements document of the Features in question.  The pointer should state the version of the target document.  It is free-form, so it can also indicate the specific section/page/paragraph.
* **Feature Description**
  
  When fencei_flush_req_o is high, it shall stay high until fencei_flush_req_o and fencei_flush_ack_i has been sampled high simultaneously, and then then it shall go low.
* **Verification Goals**
  
  Check that when fencei_flush_req_o is high, then it behaves correctly with regards to fencei_flush_ack_i.
* **Pass/Fail Criteria:** Assertion
* **Test Type:** ENV Capability
* **Coverage Method:** Assertion Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_FENCEI_F002_S005_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 006_AckChange

#### Item: 000

* **Requirement location:** CVA6 User Manual; https://cva6.readthedocs.io/en/latest/01_cva6_user/RISCV_Instructions.html#rv32zifencei-instruction-fetch-fenceThis is a pointer to the source Requirements document of the Features in question.  The pointer should state the version of the target document.  It is free-form, so it can also indicate the specific section/page/paragraph.
* **Feature Description**
  
  fencei_flush_ack_i is allowed to change freely on any clock cycle: It can be permanently high, go high without fence.i and retract, go high at the same cycle as the req, it can delay arbitrarily after req and then go high, etc
* **Verification Goals**
  
  Drive ack to test all permutations of rising/falling before/after/on req, acking without req, retracting an early ack, delaying ack after req, etc.
* **Pass/Fail Criteria:** Any/All
* **Test Type:** ENV Capability
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_FENCEI_F002_S006_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 007_AckWithhold

#### Item: 000

* **Requirement location:** CVA6 User Manual; https://cva6.readthedocs.io/en/latest/01_cva6_user/RISCV_Instructions.html#rv32zifencei-instruction-fetch-fence
* **Feature Description**
  
  If req is high, but ack never comes, then the core keeps on stalling and the fence.i is blocked from completing.
* **Verification Goals**
  
  Upon a req, try withholding ack for a long time and see that the fence.i can be stalled arbitrarily long (should have covers for ack delays of at least {[0:5]}).
* **Pass/Fail Criteria:** Assertion
* **Test Type:** ENV Capability
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_FENCEI_F002_S007_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 008_BranchInitiated

#### Item: 000

* **Requirement location:** CVA6 User Manual; https://cva6.readthedocs.io/en/latest/01_cva6_user/RISCV_Instructions.html#rv32zifencei-instruction-fetch-fenceThis is a pointer to the source Requirements document of the Features in question.  The pointer should state the version of the target document.  It is free-form, so it can also indicate the specific section/page/paragraph.
* **Feature Description**
  
  After req and ack has been sampled simultaneously high and when req is low again, then the core takes a branch to the instruction after the fence.i instruction.
* **Verification Goals**
  
  Check that the branch is taken at the point after req and ack has been simultaneously high.
* **Pass/Fail Criteria:** Assertion
* **Test Type:** ENV Capability
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_FENCEI_F002_S008_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 009_ShadowingBranch

#### Item: 000

* **Requirement location:** CVA6 User Manual; https://cva6.readthedocs.io/en/latest/01_cva6_user/RISCV_Instructions.html#rv32zifencei-instruction-fetch-fence
* **Feature Description**
  
  If the fence.i ends up not retiring because it was preceded by a taken branch or a jump, then the fencei_flush_req_o shall not go high
* **Verification Goals**
  
  Take a branch or do a jump to skip a fence.i, and ensure that fencei_flush_req_o doesn't go high.
* **Pass/Fail Criteria:** Assertion
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_FENCEI_F002_S009_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
## Feature: MultiCycle

### Sub-feature: 000_MultiCycle

#### Item: 000

* **Requirement location:** CVA6 User Manual; https://cva6.readthedocs.io/en/latest/01_cva6_user/RISCV_Instructions.html#rv32zifencei-instruction-fetch-fence
* **Feature Description**
  
  Given zero stalls on neither instr-side and data-side obi nor on fencei_flush_ack_i, then the execution of fence.i takes a fixed number of cycles.
* **Verification Goals**
  
  Check that, given ideal conditions, the cycle count of fence.i is as expected.
* **Pass/Fail Criteria:** Assertion
* **Test Type:** ENV Capability
* **Coverage Method:** Assertion Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_FENCEI_F003_S000_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
## Feature: StoresComplete

### Sub-feature: 000_StoresComplete

#### Item: 000

* **Requirement location:** CVA6 User Manual; https://cva6.readthedocs.io/en/latest/01_cva6_user/RISCV_Instructions.html#rv32zifencei-instruction-fetch-fenceThis is a pointer to the source Requirements document of the Features in question.  The pointer should state the version of the target document.  It is free-form, so it can also indicate the specific section/page/paragraph.
* **Feature Description**
  
  Any store instruction that is successfully executed before a fence.i will fully complete and have its effect visible (this is not about synchronization with instruction fetch, but rather seeing that the stores are not aborted).
* **Verification Goals**
  
  Check that all stores (either to next pc or other places) preceding a fence.i will complete on the bus (excluding exceptions/interrupts/etc) and be readable afterwards (particularly, ensure that the write buffer isn't just purged).
* **Pass/Fail Criteria:** Self-Check
* **Test Type:** Directed SelfChk
* **Coverage Method:** Testcase
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_FENCEI_F004_S000_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 001_StoresComplete

#### Item: 000

* **Requirement location:** CVA6 User Manual; https://cva6.readthedocs.io/en/latest/01_cva6_user/RISCV_Instructions.html#rv32zifencei-instruction-fetch-fence
* **Feature Description**
  
  Any store instruction that is successfully executed before a fence.i will fully complete and have its effect visible (this is not about synchronization with instruction fetch, but rather seeing that the stores are not aborted).
* **Verification Goals**
  
  Check that all stores (either to next pc or other places) preceding a fence.i will complete on the bus (excluding exceptions/interrupts/etc) and be readable afterwards (particularly, ensure that the write buffer isn't just purged).
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Testcase
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_FENCEI_F004_S001_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
## Feature: Flush

### Sub-feature: 000_Flush

#### Item: 000

* **Requirement location:** CVA6 User Manual; https://cva6.readthedocs.io/en/latest/01_cva6_user/RISCV_Instructions.html#rv32zifencei-instruction-fetch-fence
* **Feature Description**
  
  When fence.i is executed, then any prefetched instructions shall be flushed; meaning that pipeline stages are flushed, prefetcher is flushed, write buffer is flushed, and data_req_o is eventually suppressed.
* **Verification Goals**
  
  Check that a fence.i will cause flushing of the pipeline, prefetcher, write buffer, and data_req_o.
* **Pass/Fail Criteria:** Assertion
* **Test Type:** ENV Capability
* **Coverage Method:** Assertion Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_FENCEI_F005_S000_I000
* **Link to Coverage:** 
* **Comments**
  
  TODO missing assert. (Have not checked/covered that the pipeline/writebuffer content is actually purged. Or that any memory change WILL be the next instr word.)!
## Feature: UnusedFields

### Sub-feature: 000_UnusedFields

#### Item: 000

* **Requirement location:** The RISC-V Instruction Set Manual
Volume I: Unprivileged ISA
Document Version 20191213
https://riscv.org/wp-content/uploads/2019/12/riscv-spec-20191213.pdf
* **Feature Description**
  
  imm[11:0], rs1, rd are reserved for future extensions, and implementations shall ignore them
* **Verification Goals**
  
  Try giving random values in those fields and see that all else works as expected
* **Pass/Fail Criteria:** Check RM
* **Test Type:** Constrained Random
* **Coverage Method:** Functional Coverage
* **Applicable Cores:** CV32A6_v0.1.0, CV32A6-step2, CV64A6-step3
* **Unique verification tag:** VP_FENCEI_F006_S000_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
