# Module: MMU_SV32

## Feature: sv32

### Sub-feature: 000_PMP permissions on Physical Address

#### Item: 000

* **Requirement location:** ISA Volume II: Privilege Architecture Version 20211203, Chapter 3.7, 5.3.2
* **Feature Description**
  
  If PTE has valid and non-reserved RWX permissions, but the translated Physical address (pte.ppn of leaf PTE + offset) does not have (r,w,x) PMP permissions, then accessing the translated Physical address would raise access fault exception.  
  When satp.mode=sv32, and PTE has valid and non-reserved RWX permissions then test the following in supervisor and user privilege mode for level1 and level0 PTE.  
    
  - Remove read PMP permission of translated Physical Address in pmpcfg and test the read access.  
  - Remove write PMP permission of translated Physical Address in pmpcfg and test the write access.  
  - Remove execute PMP permission of translated Physical Address in pmpcfg and test the execute access.
* **Verification Goals**
  
  Access fault exception should be raised according to {x,r,w} access type. Check that:  
  - m/scause must contain the exception number of:  
           - instruction  access fault for execute access.  
           - load page access for read access.  
           - store/AMO access fault for write access.  
  - m/sepc must contain the virtual address of the instruction at which the trap occurs.
* **Pass/Fail Criteria:** Check RM
* **Test Type:** RISC-V Arch-test
* **Coverage Method:** Testcase
* **Applicable Cores:** CV32A6_v0.1.0
* **Unique verification tag:** VP_MMU_SV32_F000_S000_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 001_PMP permissions on PTE

#### Item: 000

* **Requirement location:** ISA Volume II: Privilege Architecture Version 20211203, Chapter 3.7, 5.3.2
* **Feature Description**
  
  If PTE does not have (r,w,x) PMP permissions, then accessing it would raise access fault exception of the corresponding access type.   
  When satp.mode=sv32, then test the following in supervisor and user privilege mode for level0 and level1 PTE.  
  - Remove read PMP permission of PTE address in pmpcfg and test the read access.  
  - Remove write PMP permission of PTE address in pmpcfg and test the write access.  
  - Remove execute PMP permission of PTE address in pmpcfg and test the execute access.
* **Verification Goals**
  
  Access fault exception should be raised according to {x,r,w} access type. Check that:  
  - m/scause must contain the exception number of:  
           - instruction  access fault for execute access.  
           - load page access for read access.  
           - store/AMO access fault for write access.  
  - m/sepc must contain the virtual address of the instruction at which the trap occurs.
* **Pass/Fail Criteria:** NDY (Not Defined Yet)
* **Test Type:** NDY (Not Defined Yet)
* **Coverage Method:** NDY (Not Defined Yet)
* **Applicable Cores:** CV32A6_v0.1.0
* **Unique verification tag:** VP_MMU_SV32_F000_S001_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 002_In-Valid Permission of PTE

#### Item: 000

* **Requirement location:** ISA Volume II: Privilege Architecture Version 20211203, Chapter 5.3.2
* **Feature Description**
  
  If PTE does not have Valid (pte.V=0) permission, then accessing it would raise page fault exception of the corresponding access type.   
  When satp.mode=sv32 and PTE has (r,w,x) PMP permissions, then test the following in supervisor and user privilege mode for level0 and level1 PTE.  
  - Set PTE.V = 0 and test the read access.  
  - Set PTE.V = 0 and test the write access.  
  - Set PTE.V = 0 and test the execute access.  
    
  * For testing at level0, set all the pte permissions at level1 to 0 except pte.v, so that level1 points to level0.  
  * Set pte.U=0 when test in Supervisor mode and Set pte.U=1 when testing in user mode
* **Verification Goals**
  
  Page fault exception should be raised according to {x,r,w} access type. Check that:  
  - m/scause must contain the exception number of:  
           - instruction page fault for execute access.  
           - load page fault for read access.  
           - store/AMO page fault for write access.  
  - m/sepc must contain the virtual address of the instruction at which the trap occurs.
* **Pass/Fail Criteria:** Check RM
* **Test Type:** RISC-V Arch-test
* **Coverage Method:** Testcase
* **Applicable Cores:** CV32A6_v0.1.0
* **Unique verification tag:** VP_MMU_SV32_F000_S002_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 003_Reserved RWX permission encodings of PTE

#### Item: 000

* **Requirement location:** ISA Volume II: Privilege Architecture Version 20211203, Chapter 3.7, 5.3.1
* **Feature Description**
  
  If PTE has reserved RWX encodings (pte.w=1 & pte.r=0), then accessing it would raise page fault exception of the corresponding access type.   
  When satp.mode=sv32, PTE has (r,w,x) PMP permissions, and pte.v=1, then test the following in supervisor and user privilege mode for level0 and level1 PTE.  
  - Set pte.w=1 & pte.r=0 and test the read access.  
  - Set pte.w=1 & pte.r=0 and test the write access.  
  - Set pte.w=1 & pte.r=0 and test the execute access.  
    
  * For testing at level0, set all the pte permissions at level1 to 0 except pte.v, so that level1 points to level0.  
  * Set pte.U=0 when test in Supervisor mode and Set pte.U=1 when testing in user mode
* **Verification Goals**
  
  Page fault exception should be raised according to {x,r,w} access type. Check that:  
  - m/scause must contain the exception number of:  
           - instruction page fault for execute access.  
           - load page fault for read access.  
           - store/AMO page fault for write access.  
  - m/sepc must contain the virtual address of the instruction at which the trap occurs.
* **Pass/Fail Criteria:** Check RM
* **Test Type:** RISC-V Arch-test
* **Coverage Method:** Testcase
* **Applicable Cores:** CV32A6_v0.1.0
* **Unique verification tag:** VP_MMU_SV32_F000_S003_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 004_Non-leaf PTE permission at level 0

#### Item: 000

* **Requirement location:** ISA Volume II: Privilege Architecture Version 20211203, Chapter 5.3.2
* **Feature Description**
  
  If PTE at level0 has non-leaf RWX permissions (pte.x=0 & pte.r=0), then accessing it would raise page fault exception of the corresponding access type.   
  When satp.mode=sv32, PTE has (r,w,x) PMP permissions, and pte.v=1, then test the following in supervisor and user privilege mode for level0 PTE.  
  - Set pte.x=0 & pte.r=0 & pte.w=0 and test the read access.  
  - Set pte.x=0 & pte.r=0 & pte.w=0 and test the write access.  
  - Set pte.x=0 & pte.r=0 & pte.w=0 and test the execute access.  
    
  * For testing at level0, set all the pte permissions at level1 to 0 except pte.v, so that level1 points to level0.  
  * Set pte.U=0 when test in Supervisor mode and Set pte.U=1 when testing in user mode
* **Verification Goals**
  
  Page fault exception should be raised according to {x,r,w} access type. Check that:  
  - m/scause must contain the exception number of:  
           - instruction page fault for execute access.  
           - load page fault for read access.  
           - store/AMO page fault for write access.  
  - m/sepc must contain the virtual address of the instruction at which the trap occurs.
* **Pass/Fail Criteria:** Check RM
* **Test Type:** RISC-V Arch-test
* **Coverage Method:** Testcase
* **Applicable Cores:** CV32A6_v0.1.0
* **Unique verification tag:** VP_MMU_SV32_F000_S004_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 005_RWX access on S-mode pages in S-mode

#### Item: 000

* **Requirement location:** ISA Volume II: Privilege Architecture Version 20211203, Chapter 5.3.1
* **Feature Description**
  
  If PTE belongs to supervisor mode i.e. its U permission bit is clear (pte.u = 0), then accessing that PTE in supervisor mode should be successful if the corresponding (r,w,x) permission of PTE is granted. Otherwise raise page fault exception of the corresponding access type.  
  When satp.mode=sv32, PTE has (r,w,x) PMP permissions, PTE has non-reserved RWX encoding, pte.u=0 and pte.v=1, then test the following in supervisor privilege mode for level 0 and level 1 PTE.  
  - Test the read access for both pte.r=1 and for pte.r=0  
  - Test the write access for both pte.w=1 and for pte.w=0  
  - Test the execute access for both pte.x=1 and for pte.x=0  
    
  * For testing at level0, set all the pte permissions at level1 to 0 except pte.v, so that level1 points to level0.
* **Verification Goals**
  
  RWX access should be successful if the corresponding permissions are granted in the PTE. Check that load, store and execute works without any page fault.  
  Page fault exception should be raised according to (x,r,w) access type if the corresponding (r,w,x) permissions are not granted in the PTE. Check that:  
  - m/scause must contain the exception number of:  
           - instruction  page fault for execute.  
           - load page fault for read access.  
           - store/AMO page fault for write access.  
  - m/sepc must contain the virtual address of the instruction at which the trap occurs.
* **Pass/Fail Criteria:** Check RM
* **Test Type:** RISC-V Arch-test
* **Coverage Method:** Testcase
* **Applicable Cores:** CV32A6_v0.1.0
* **Unique verification tag:** VP_MMU_SV32_F000_S005_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 006_RWX access on S-mode pages in U-mode

#### Item: 000

* **Requirement location:** ISA Volume II: Privilege Architecture Version 20211203, Chapter 5.3.2
* **Feature Description**
  
  If PTE belongs to supervisor mode i.e. its U permission bit is clear (pte.u = 0), then accessing that PTE in user mode would raise page fault exception of the corresponding access type.   
  When satp.mode=sv32, PTE has (r,w,x) PMP permissions, PTE has non-reserved RWX encoding, and pte.v=1, then test the following user privilege mode for level0 and level1 PTE.  
  - Set pte.u=0 and test the read access.  
  - Set pte.u=0 and test the write access.  
  - Set pte.u=0 and test the execute access.  
    
  * For testing at level0, set all the pte permissions at level1 to 0 except pte.v, so that level1 points to level0.
* **Verification Goals**
  
  Page fault exception should be raised according to {x,r,w} access type. Check that:  
  - m/scause must contain the exception number of instruction, load, and store/AMO page fault for execute, read and write access type, respectively.  
  - m/sepc must contain the virtual address of the instruction at which the trap occurs.
* **Pass/Fail Criteria:** Check RM
* **Test Type:** RISC-V Arch-test
* **Coverage Method:** Testcase
* **Applicable Cores:** CV32A6_v0.1.0
* **Unique verification tag:** VP_MMU_SV32_F000_S006_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 007_RWX access on U-mode pages in S-mode with mstatus.SUM unset

#### Item: 000

* **Requirement location:** ISA Volume II: Privilege Architecture Version 20211203, Chapter 3.1.6.3, 5.3.2
* **Feature Description**
  
  If PTE belongs to user mode i.e. its U permission bit is set (pte.u = 1) and m/sstatus.SUM = 0, then accessing that PTE in supervisor mode would raise page fault exception of the corresponding access type.   
  When satp.mode=sv32, PTE has (r,w,x) PMP permissions, PTE has non-reserved RWX encoding, and pte.v=1, then test the following in supervisor mode for level 0 and level 1 PTE.  
  - Set pte.u=1 & s/mstatus.SUM = 0 and test the read access.  
  - Set pte.u=1 & s/mstatus.SUM = 0 and test the write access.  
  - Set pte.u=1 & s/mstatus.SUM = 0 and test the execute access.  
    
  * For testing at level0, set all the pte permissions at level1 to 0 except pte.v, so that level1 points to level0.
* **Verification Goals**
  
  Page fault exception should be raised according to {x,r,w} access type. Check that:  
  - m/scause must contain the exception number of:  
           - instruction page fault for execute access.  
           - load page fault for read access.  
           - store/AMO page fault for write access.  
  - m/sepc must contain the virtual address of the instruction at which the trap occurs.
* **Pass/Fail Criteria:** Check RM
* **Test Type:** RISC-V Arch-test
* **Coverage Method:** Testcase
* **Applicable Cores:** CV32A6_v0.1.0
* **Unique verification tag:** VP_MMU_SV32_F000_S007_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 008_RWX access on U-mode pages in S-mode with mstatus.SUM set

#### Item: 000

* **Requirement location:** ISA Volume II: Privilege Architecture Version 20211203, Chapter 3.1.6.3, 5.3.2
* **Feature Description**
  
  If PTE belongs to user mode i.e. its U permission bit is set (pte.u = 1) and m/sstatus.SUM = 1, then RW access to that PTE in supervisor mode would be successful but eXecute access would raise instruction page fault exception in s-mode.  
  When satp.mode=sv32, PTE has (r,w,x) PMP permissions, PTE has non-reserved RWX encoding, and pte.v=1, then test the following in supervisor mode for level0 and level1 PTE.  
  - Set pte.r=1 & pte.u=1 & s/mstatus.SUM = 1 and test the read access.  
  - Set pte.w=1 & pte.u=1 & s/mstatus.SUM = 1 and test the write access.  
  - Set pte.x=1 & pte.u=1 & s/mstatus.SUM = 1 and test the execute access.  
    
  * For testing at level0, set all the pte permissions at level1 to 0 except pte.v, so that level1 points to level0.
* **Verification Goals**
  
  Read and Write access to the PTE should be successful. So, check that the load and store works without page fault and expected data is stored to and loaded from the memory, respectively.  
    
  Execute access should raise instruction page fault. Check that:  
  - m/scause must contain the exception number of instruction instruction access fault.   
  - m/sepc must contain the virtual address of the instruction at which the trap occurs.
* **Pass/Fail Criteria:** Check RM
* **Test Type:** RISC-V Arch-test
* **Coverage Method:** Testcase
* **Applicable Cores:** CV32A6_v0.1.0
* **Unique verification tag:** VP_MMU_SV32_F000_S008_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 009_RWX access on U-mode pages in U-mode

#### Item: 000

* **Requirement location:** ISA Volume II: Privilege Architecture Version 20211203, Chapter 5.3.2
* **Feature Description**
  
  If PTE belongs to user mode i.e. its U permission bit is set (pte.u = 1), then accessing that PTE in user mode should be successful if the corresponding (r,w,x) permission of PTE is granted. Otherwise raise page fault exception of the corresponding access type.  
  When satp.mode=sv32, PTE has (r,w,x) PMP permissions, PTE has non-reserved RWX encoding, pte.u=1 and pte.v=1, then test the following in user privilege mode for level0 and level1 PTE.  
  - Test the read access for both pte.r=1 and for pte.r=0  
  - Test the write access for both pte.w=1 and for pte.w=0  
  - Test the execute access for both pte.x=1 and for pte.x=0  
    
  * For testing at level0, set all the pte permissions at level1 to 0 except pte.v, so that level1 points to level0.
* **Verification Goals**
  
  RWX access should be successful if the corresponding permissions are granted in the PTE. Check that load, store and execute works without any page fault.  
    
  Page fault exception should be raised if the corresponding rwx PTE permissions are not granted. Check that:  
  - m/scause must contain the exception number of:  
           - instruction page fault for execute access.  
           - load page fault for read access.  
           - store/AMO page fault for write access.  
  - m/sepc must contain the virtual address of the instruction at which the trap occurs.
* **Pass/Fail Criteria:** Check RM
* **Test Type:** RISC-V Arch-test
* **Coverage Method:** Testcase
* **Applicable Cores:** CV32A6_v0.1.0
* **Unique verification tag:** VP_MMU_SV32_F000_S009_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 010_Make Executable Page Readable with s/mstatus.MXR unset

#### Item: 000

* **Requirement location:** ISA Volume II: Privilege Architecture Version 20211203, Chapter 3.1.6.3, 5.3.2
* **Feature Description**
  
  If PTE has only execute permission (pte.x = 1) and s/mstatus.MXR=0, then read access on that PTE should raise load page fault exception.  
  When satp.mode=sv32, PTE has (r,w,x) PMP permissions, and pte.v=1, then test the following in supervisor and user privilege mode for level0 and level1 PTE.  
  - Set pte.r=0 & pte.w=0 & pte.x=1 & s/mstatus.MXR=0 and test the read access.  
    
  * For testing at level0, set all the pte permissions at level1 to 0 except pte.v, so that level1 points to level0.  
  * Set pte.U=0 when test in Supervisor mode and Set pte.U=1 when testing in user mode
* **Verification Goals**
  
  Load Page fault exception should be raised. Check that:  
  - m/scause must contain the exception number of load page fault for read access.  
  - m/sepc must contain the virtual address of the instruction at which the trap occurs.
* **Pass/Fail Criteria:** Signature
* **Test Type:** RISC-V Arch-test
* **Coverage Method:** Testcase
* **Applicable Cores:** CV32A6_v0.1.0
* **Unique verification tag:** VP_MMU_SV32_F000_S010_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 011_Make Executable Page Readable with s/mstatus.MXR set

#### Item: 000

* **Requirement location:** ISA Volume II: Privilege Architecture Version 20211203, Chapter 3.1.6.3 ,5.3.2
* **Feature Description**
  
  If PTE has only execute permission (pte.x = 1) and s/mstatus.MXR=1, then read access on that PTE should be successful without having explicit read permission (pte.r=0).  
  When satp.mode=sv32, PTE has (r,w,x) PMP permissions, and pte.v=1, then test the following in supervisor and user privilege mode for level0 and level1 PTE.  
  - Set pte.r=0 & pte.w=0 & pte.x=1 & s/mstatus.MXR=1 and test the read access.  
    
  * For testing at level0, set all the pte permissions at level1 to 0 except pte.v, so that level1 points to level0.  
  * Set pte.U=0 when test in Supervisor mode and Set pte.U=1 when testing in user mode
* **Verification Goals**
  
  Read access to the PTE should be successful. Check that load instructions works without any load page fault exception and expected data is loaded from the memory.
* **Pass/Fail Criteria:** Check RM
* **Test Type:** RISC-V Arch-test
* **Coverage Method:** Testcase
* **Applicable Cores:** CV32A6_v0.1.0
* **Unique verification tag:** VP_MMU_SV32_F000_S011_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 012_Global mapping 

#### Item: 000

* **Requirement location:** ISA Volume II: Privilege Architecture Version 20211203, Chapter 5.3.1
* **Feature Description**
  
  For two different processes having same Virtual address and different satp.ASID, maps to same Physical address, and the pte.G is set; then one process will go through the address translation and update the TLB while the 2nd process will not go through the translation if pte.G is set and Physical address exist in TLB.
* **Verification Goals**
  
  Show that two different processes having same VA to PA mapping can access the translated PA from TLB (if exist) and not go through complete translation.
* **Pass/Fail Criteria:** Check RM
* **Test Type:** RISC-V Arch-test
* **Coverage Method:** Testcase
* **Applicable Cores:** CV32A6_v0.1.0
* **Unique verification tag:** VP_MMU_SV32_F000_S012_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 013_Access bit implementation

#### Item: 000

* **Requirement location:** ISA Volume II: Privilege Architecture Version 20211203, Chapter 5.3.1, 5.3.2
* **Feature Description**
  
  If implementation does not sets the pte.A on accessing the PTE, and PTE has pte.A=0, then accessing it would raise page fault exception of the corresponding access type.   
  When satp.mode=sv32, PTE has (r,w,x) PMP permissions, and pte.v=1, then test the following in supervisor and user privilege mode for level0 and level1 PTE. Execute sfence.vma before accessing the PTE.  
  - Set pte.r=1 & pte.a=0 and test the read access.   
  - Set pte.w=1 & pte.a=0 and test the write access.  
  - Set pte.x=1 & pte.a=0 and test the execute access.  
    
  * For testing at level0, set all the pte permissions at level1 to 0 except pte.v, so that level1 points to level0.  
  * Set pte.U=0 when test in Supervisor mode and Set pte.U=1 when testing in user mode.
* **Verification Goals**
  
  Page fault exception should be raised according to {x,r,w} access type. Check that:  
  - m/scause must contain the exception number of:  
           - instruction page fault for execute access.  
           - load page fault for read access.  
           - store/AMO page fault for write access.  
  - m/sepc must contain the virtual address of the instruction at which the trap occurs.
* **Pass/Fail Criteria:** Check RM
* **Test Type:** RISC-V Arch-test
* **Coverage Method:** Testcase
* **Applicable Cores:** CV32A6_v0.1.0
* **Unique verification tag:** VP_MMU_SV32_F000_S013_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 014_Dirty bit Implementation

#### Item: 000

* **Requirement location:** ISA Volume II: Privilege Architecture Version 20211203, Chapter 5.3.1, 5.3.2
* **Feature Description**
  
  If implementation does not sets the pte.D when PTE is written, and PTE has pte.D=0, then attempting to store on that PTE would raise Store/AMO page fault exception.  
  When satp.mode=sv32, PTE has (r,w,x) PMP permissions, pte.a=1 and pte.v=1, then test the following in supervisor and user privilege mode for level0 and level1 PTE. Execute sfence.vma before accessing the PTE.  
  - Set pte.w=1 & pte.d=0 and test the write access.  
    
  * For testing at level0, set all the pte permissions at level1 to 0 except pte.v, so that level1 points to level0.  
  * Set pte.U=0 when test in Supervisor mode and Set pte.U=1 when testing in user mode.
* **Verification Goals**
  
  Store/AMO page fault exception should be raised. Check that:  
  - m/scause must contain the exception number of store/AMO page fault for write access.  
  - m/sepc must contain the virtual address of the instruction at which the trap occurs.
* **Pass/Fail Criteria:** Check RM
* **Test Type:** RISC-V Arch-test
* **Coverage Method:** Testcase
* **Applicable Cores:** CV32A6_v0.1.0
* **Unique verification tag:** VP_MMU_SV32_F000_S014_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 015_Misaligned Superpage

#### Item: 000

* **Requirement location:** ISA Volume II: Privilege Architecture Version 20211203, Chapter 5.3.1, 5.3.2
* **Feature Description**
  
  If PTE at level1 is leaf PTE (superpage) and its pte.ppn[0]=0, then it is a misaligned superpage and accessing that PTE would raise page fault exception of the corresponding access type.  
  When satp.mode=sv32, PTE has (r,w,x) PMP permissions, PTE has non-reserved RWX encodings, (pte.r | pte.x)=1, and pte.v=1, then test the following in supervisor and user privilege mode for level1 PTE.  
  -set pte.ppn[0]=0 and test for read, write and execute access.  
    
  * Set pte.U=0 when test in Supervisor mode and Set pte.U=1 when testing in user mode.
* **Verification Goals**
  
  Page fault exception should be raised according to {x,r,w} access type. Check that:  
  - m/scause must contain the exception number of:  
           - instruction page fault for execute access.  
           - load page fault for read access.  
           - store/AMO page fault for write access.  
  - m/sepc must contain the virtual address of the instruction at which the trap occurs.
* **Pass/Fail Criteria:** Check RM
* **Test Type:** RISC-V Arch-test
* **Coverage Method:** Testcase
* **Applicable Cores:** CV32A6_v0.1.0
* **Unique verification tag:** VP_MMU_SV32_F000_S015_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
## Feature: mstatus.TVM

### Sub-feature: 000_Accessing satp and sfence.vma CSRs

#### Item: 000

* **Requirement location:** ISA Volume II: Privilege Architecture Version 20211203, Chapter 3.1.6.5
* **Feature Description**
  
  If mstatus.TVM=1, read and write access to the satp and sfence.vma will raise illegal instruction exception in S-mode.
* **Verification Goals**
  
  Show that:  
  - s/mcause contains the exception number of illegal instruction exception.  
  - m/sepc must contain the virtual address of the instruction at which the trap occurs.
* **Pass/Fail Criteria:** Check RM
* **Test Type:** RISC-V Arch-test
* **Coverage Method:** Testcase
* **Applicable Cores:** CV32A6_v0.1.0
* **Unique verification tag:** VP_MMU_SV32_F001_S000_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
## Feature: satp

### Sub-feature: 000_access permission

#### Item: 000

* **Requirement location:** ISA Volume II: Privilege Architecture Version 20211203, Chapter 5.1.11
* **Feature Description**
  
  Access satp in M, S, and U mode using csrrw, csrrc, csrrs
* **Verification Goals**
  
  Show that satp is only accessible in M and S mode and illegal instruction exception is generated when accessed in lower privilege mode
* **Pass/Fail Criteria:** Check RM
* **Test Type:** RISC-V Arch-test
* **Coverage Method:** Testcase
* **Applicable Cores:** CV32A6_v0.1.0
* **Unique verification tag:** VP_MMU_SV32_F002_S000_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 001_MODE field

#### Item: 000

* **Requirement location:** ISA Volume II: Privilege Architecture Version 20211203, Chapter 5.1.11
* **Feature Description**
  
  Allows to select different schemes of address translation. Writes to satp are ignored when unsupported mode is selected.
* **Verification Goals**
  
  Show that supported address translation scheme i.e sv32 is selected by writing satp.mode=sv32 and reading back the satp
* **Pass/Fail Criteria:** Check RM
* **Test Type:** RISC-V Arch-test
* **Coverage Method:** Testcase
* **Applicable Cores:** CV32A6_v0.1.0
* **Unique verification tag:** VP_MMU_SV32_F002_S001_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 002_MODE=Bare

#### Item: 000

* **Requirement location:** ISA Volume II: Privilege Architecture Version 20211203, Chapter 5.1.11
* **Feature Description**
  
  Selecting MODE=Bare the remaining field should be zero. Other encoding for remaining field in satp is reserved
* **Verification Goals**
  
  Show writing {zero, non-zero} value to satp when mode=bare the behaviour follows the design implementation
* **Pass/Fail Criteria:** Check RM
* **Test Type:** RISC-V Arch-test
* **Coverage Method:** Testcase
* **Applicable Cores:** CV32A6_v0.1.0
* **Unique verification tag:** VP_MMU_SV32_F002_S002_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
### Sub-feature: 003_ASIDLEN

#### Item: 000

* **Requirement location:** ISA Volume II: Privilege Architecture Version 20211203, Chapter 5.1.11
* **Feature Description**
  
  ASIDLEN is the number of ASID bits implemented. MAXASID bits for sv32 is 9
* **Verification Goals**
  
  Determine by writing one to every bit position in the ASID field, then reading back the value in satp to see which bit positions in the ASID field hold a one. Show that ASIDLEN is equal to the expected ASIDLEN
* **Pass/Fail Criteria:** Check RM
* **Test Type:** RISC-V Arch-test
* **Coverage Method:** Testcase
* **Applicable Cores:** CV32A6_v0.1.0
* **Unique verification tag:** VP_MMU_SV32_F002_S003_I000
* **Link to Coverage:** 
* **Comments**
  
  *(none)*  
  
