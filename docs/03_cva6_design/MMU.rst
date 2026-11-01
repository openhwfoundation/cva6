----------------------
Memory Management Unit
----------------------

The Memory Management Unit (MMU) module is a crucial component in the RISC-V-based processor, serving as the backbone for virtual memory management and address translation. 

.. figure:: _static/mmu_in_out.png
   :name: **Figure 1:** Inputs and Outputs of CVA6 MMU
   :align: center
   :width: 100%
   :alt: mmu_in_out

   **Figure 1:** Inputs and Outputs of CVA6 MMU

At its core, the MMU plays a pivotal role in translating virtual addresses into their corresponding physical counterparts. This translation process is paramount for providing memory protection, isolation, and efficient memory management in modern computer systems. Importantly, it handles both instruction and data accesses, ensuring a seamless interaction between the processor and virtual memory. Within the MMU, several major blocks play pivotal roles in this address translation process. These includes:

* Instruction TLB (ITLB)
* Data TLB (DTLB)
* Shared TLB (optional)
* Page Table Walker (PTW)

.. figure:: _static/mmu_major_blocks.png
   :name: **Figure 2:** Major Blocks in CVA6 MMU
   :align: center
   :width: 60%
   :alt: mmu_major_blocks

   **Figure 2:** Major Blocks in CVA6 MMU

The MMU manages privilege levels and access control, enforcing permissions for user and supervisor modes while handling access exceptions. It employs Translation Lookaside Buffers (TLBs) for efficient address translation, reducing the need for page table access. TLB hits yield quick translations, but on misses, the shared TLB is consulted (when used), and if necessary, the Page Table Walker (PTW) performs page table walks, updating TLBs and managing exceptions during the process.

In addition to these functionalities, the MMU seamlessly integrates support for Physical Memory Protection (PMP), enabling it to enforce access permissions and memory protection configurations as specified by the PMP settings. This additional layer of security and control enhances the management of memory accesses

.. raw:: html

        <span style="font-size:18px; font-weight:bold;">Instruction and Data Interfaces</span>

The MMU maintains interfaces with the instruction cache (ICache) and the load-store unit (LSU). It receives virtual addresses from these components and proceeds to translate them into physical addresses, a fundamental task for ensuring proper program execution and memory access.

The MMU block can be parameterized to support sv32, sv39 and sv39x4 virtual memory. In CVA6, some of these parameters are configurable by the user, and some others are calculated depending on other parameters of the core. The available HW configuration parameters are the following:

.. raw:: html

        <span style="font-size:18px; font-weight:bold;">List of configuration parameters for MMU</span>

.. list-table::
   :header-rows: 1

   * - Parameter
     - Description
     - Type
     - Possible values
     - User config

   * - ``InstrTlbEntries``
     - Number of entries in Instruction TLB
     - Natural
     - ``>0 and multiple of 2``
     - Yes

   * - ``DataTlbEntries``
     - Number of entries in Data TLB
     - Natural
     - ``>0 and multiple of 2``
     - Yes

   * - ``SharedTlbDepth``
     - Size of shared TLB
     - Natural
     - ``>0 and multiple of 2``
     - Yes

   * - ``UseSharedTlb``
     - Indicates if the shared TLB optimization is used (1) or not (0)
     - bit
     - 1 or 0
     - Yes
   
   * - ``RVH``
     - Indicates if Hypervisor extension is used (1) or not (0)
     - bit
     - 1 or 0
     - Yes

   * - ``ASIDW``
     - Indicates the width of the Address Space Identifier (ASID)
     - Natural
     - ``>0``
     - No
  
   * - ``VMIDW``
     - Indicates the width of the Virtual Machine space Identifier (VMID) - (used only when Hypervisor extension is enabled)
     - Natural
     - ``>0``
     - No

   * - ``PPNW``
     - Indicates the width of the Physical Page Number (PPN) 
     - Natural
     - ``>0``
     - No

   * - ``GPPNW``
     - Indicates the width of the Guest Physical Page Number (GPPN) - (used only when Hypervisor extension is enabled)
     - Natural
     - ``>0``
     - No

   * - ``SV``
     - Indicates the width of the Virtual Address Space
     - Natural
     - ``>0``
     - No

   * - ``SVX``
     - Indicates the width of the extended Virtual Address Space when Hypervisor is used
     - Natural
     - ``>0``
     - No

   * - ``VpnLen``
     - Length of Virtual Page Number (VPN)
     - Natural
     - ``>12``
     - No

   * - ``PtLevels``
     - Number of page table levels
     - Natural
     - ``log2(CVA6Cfg.XLEN)``
     - No

.. raw:: html

        <span style="font-size:18px; font-weight:bold;">Default Configuration parameters value for sv32, sv39 and sv39x4</span>

.. list-table::
   :header-rows: 1

   * - Parameter
     - sv32
     - sv39
     - sv39x4

   * - ``InstrTlbEntries``
     - 2
     - 16
     - 16

   * - ``DataTlbEntries``
     - 2
     - 16
     - 16

   * - ``SharedTlbDepth``
     - 64
     - 64
     - 64

   * - ``UseSharedTlb``
     - 1
     - 0
     - 0 
   
   * - ``RVH``
     - 0
     - 0
     - 1 

   * - ``ASIDW``
     - 9
     - 16
     - 16
     
   * - ``VMIDW``
     - 7
     - 14
     - 14

   * - ``PPNW``
     - 22
     - 44
     - 44 
   
   * - ``GPPNW``
     - 22
     - 29
     - 29 

   * - ``SV``
     - 32
     - 39
     - 39
     
   * - ``SVX``
     - 34
     - 41
     - 41

   * - ``VpnLen``
     - 20
     - 27
     - 29

   * - ``PtLevels``
     - 2
     - 3
     - 3
  



.. raw:: html

        <span style="font-size:18px; font-weight:bold;">Signal Description of MMU</span>

.. raw:: html

   <p style="text-align:center;"> <b>Table 1:</b> CVA6 MMU Input Output Signals </p>

.. list-table::
   :header-rows: 1

   * - Signal
     - IO
     - Connection Type
     - Type
     - Description

   * - ``clk_i``
     - in
     - Subsystem
     - logic
     - Subsystem Clock

   * - ``rst_ni``
     - in
     - Subsystem
     - logic
     - Asynchronous reset active low
     
   * - ``flush_i``
     - in
     - Controller
     - logic
     - Sfence Committed

   * - ``enable_translation_i``
     - in
     - CSR RegFile
     - logic 
     - Enables address translation request for instruction

   * - ``enable_g_translation_i``
     - in
     - CSR RegFile
     - logic 
     - Enables virtual memory translation for instructions

   * - ``en_ld_st_translation_i``
     - in
     - CSR RegFile
     - logic 
     - Enables address translation request for load or store

   * - ``en_ld_st_g_translation_i``
     - in
     - CSR RegFile
     - logic
     - Enables virtual memory translation for load or store

   * - ``icache_areq_i``
     - in
     - Cache Subsystem
     - icache_arsp_t
     - Icache Response

   * - ``icache_areq_o``
     - out
     - Cache Subsystem
     - icache_areq_t
     - Icache Request

   * - ``misaligned_ex_i``
     - in
     - Load Store Unit
     - exception_t
     - Indicate misaligned exception

   * - ``lsu_req_i``
     - in
     - Load Store Unit
     - logic
     - Request address translation
     
   * - ``lsu_vaddr_i``
     - in
     - Load Store Unit
     - logic [VLEN-1:0]
     - Virtual Address In

   * - ``lsu_tinst_i``
     - in
     - Load Store Unit
     - logic [31:0]
     - Transformed Instruction In when Hypervisor Extension is enabled. Set to 0 (unused) when not.

   * - ``lsu_is_store_i``
     - in
     - Store Unit
     - logic
     - Translation is requested by a store

   * - ``csr_hs_ld_st_inst_o``
     - out
     - CSR RegFile
     - logic
     - Indicate a hypervisor load store instruction. 
   
   * - ``lsu_dtlb_hit_o``
     - out
     - Store / Load Unit
     - logic
     - Indicate a DTLB hit

   * - ``lsu_dtlb_ppn_o``
     - out
     - Load Unit
     - logic [PPNW-1:0]
     - Send PNN to LSU

   * - ``lsu_valid_o``
     - out
     - Load Store Unit
     - logic
     - Indicate a valid translation

   * - ``lsu_paddr_o``
     - out
     - Store / Load Unit
     - logic [PLEN-1:0]
     - Translated Address

   * - ``lsu_exception_o``
     - out
     - Store / Load Unit
     - exception_t
     - Address Translation threw an exception

   * - ``priv_lvl_i``
     - in
     - CSR RegFile
     - priv_lvl_t
     - Privilege level for instruction fetch interface

   * - ``v_i``
     - in
     - CSR RegFile
     - logic
     - Virtualization mode state

   * - ``ld_st_priv_lvl_i``
     - in
     - CSR RegFile
     - priv_lvl_t
     - Indicates the virtualization mode at which load and stores should happen

   * - ``ld_st_v_i``
     - in
     - CSR RegFile
     - logic
     - Virtualization mode state

   * - ``sum_i``
     - in
     - CSR RegFile
     - logic 
     - Supervisor User Memory Access bit in xSTATUS CSR register

   * - ``vs_sum_i``
     - in
     - CSR RegFile
     - logic 
     - Virtual Supervisor User Memory Access bit in xSTATUS CSR register when Hypervisor extension is enabled.

   * - ``mxr_i``
     - in
     - CSR RegFile
     - logic
     - Make Executable Readable bit in xSTATUS CSR register

   * - ``vmxr_i``
     - in
     - CSR RegFile
     - logic
     - Virtual Make Executable Readable bit in xSTATUS CSR register for virtual supervisor when Hypervisor extension is enabled.

   * - ``hlvx_inst_i``
     - in
     - Store / Load Unit
     - logic 
     - Indicates that Instruction is a hypervisor load store with execute permissions 

   * - ``hs_ld_st_inst_i``
     - in
     - CSR RegFile
     - logic 
     - Indicates that Instruction is a hypervisor load store instruction

   * - ``satp_ppn_i``
     - in
     - CSR RegFile
     - logic [PPNW-1:0]
     - PPN of top level page table from SATP register

   * - ``vsatp_ppn_i``
     - in
     - CSR RegFile
     - logic [PPNW-1:0]
     - PPN of top level page table from VSATP register when Hypervisor extension is enabled

   * - ``hgatp_ppn_i``
     - in
     - CSR RegFile
     - logic [PPNW-1:0]
     - PPN of top level page table from HGATP register when Hypervisor extension is enabled

   * - ``asid_i``
     - in
     - CSR RegFile
     - logic [ASIDW-1:0]
     - ASID for the lookup

   * - ``vs_asid_i``
     - in
     - CSR RegFile
     - logic [ASIDW-1:0]
     - ASID for the lookup for virtual supervisor when Hypervisor extension is enabled

   * - ``vmid_i``
     - in
     - CSR RegFile
     - logic [VMIDW-1:0]
     - VMID for the lookup when Hypervisor extension is enabled

   * - ``asid_to_be_flushed_i``
     - in
     - Execute Stage
     - logic [ASIDW-1:0]
     - ASID of the entry to be flushed

   * - ``vmid_to_be_flushed_i``
     - in
     - Execute Stage
     - logic [VMIDW-1:0]
     - VMID of the entry to be flushed when Hypervisor extension is enabled

   * - ``vaddr_to_be_flushed_i``
     - in
     - Execute Stage
     - logic [VLEN-1:0]
     - Virtual address of the entry to be flushed

   * - ``gpaddr_to_be_flushed_i``
     - in
     - Execute Stage
     - logic [GPLEN-1:0]
     - Virtual address of the guest entry to be flushed when Hypervisor extension is enabled

   * - ``flush_tlb_i``
     - in
     - Controller
     - logic 
     - Indicates SFENCE.VMA committed

   * - ``flush_tlb_vvma_i``
     - in
     - Controller
     - logic 
     - Indicates SFENCE.VVMA committed

   * - ``flush_tlb_gvma_i``
     - in
     - Controller
     - logic 
     - Indicates SFENCE.GVMA committed

   * - ``itlb_miss_o``
     - out
     - Performance Counter
     - logic
     - Indicate an ITLB miss

   * - ``dtlb_miss_o``
     - out
     - Performance Counter
     - logic
     - Indicate a DTLB miss

   * - ``req_port_i``
     - in
     - Cache Subsystem
     - dcache_req_o_t
     - D Cache Data Requests

   * - ``req_port_o``
     - out
     - Cache Subsystem
     - dcache_req_i_t
     - D Cache Data Response

   * - ``pmpcfg_i``
     - in
     - CSR RegFile
     - pmpcfg_t [15:0]
     - PMP configurations

   * - ``pmpaddr_i``
     - in
     - CSR RegFile
     - logic [15:0][PLEN-3:0]
     - PMP Address

.. raw:: html

   <span style="font-size:18px; font-weight:bold;">Struct Description</span>

.. raw:: html

   <p style="text-align:center;"> <b>Table 2:</b> I Cache Request Struct </b>(icache_areq_t</b>) </p>

.. list-table::
   :header-rows: 1

   * - Signal
     - Type
     - Description

   * - ``fetch_valid``
     - logic
     - Address Translation Valid

   * - ``fetch_paddr``
     - logic [PLEN-1:0]
     - Physical Address In

   * - ``fetch_exception``
     - exception_t
     - Exception occurred during fetch

.. raw:: html

   <p style="text-align:center;"> <b>Table 3:</b> I Cache Response Struct </b>(icache_arsq_t</b>) </p>

.. list-table::
   :header-rows: 1

   * - Signal
     - Type
     - Description

   * - ``fetch_req``
     - logic
     - Address Translation Request

   * - ``fetch_vaddr``
     - logic [VLEN-1:0]
     - Virtual Address out

.. raw:: html

   <p style="text-align:center;"> <b>Table 4:</b> Exception Struct </b>(exception_t</b>) </p>

.. list-table::
   :header-rows: 1

   * - Signal
     - Type
     - Description

   * - ``cause``
     - logic [XLEN-1:0]
     - Cause of exception

   * - ``tval``
     - logic [XLEN-1:0]
     - Additional information of causing exception (e.g. instruction causing it), address of LD/ST fault

   * - ``tval2``
     - logic [GPLEN-1:0]
     - Additional information when the causing exception in a guest exception (used only in hypervisor mode)

   * - ``tinst``
     - logic [31:0]
     - Transformed instruction information

   * - ``gva``
     - logic
     - Signals when a guest virtual address is written to tval

   * - ``valid``
     - logic
     - Indicate that exception is valid

.. raw:: html

   <p style="text-align:center;"> <b>Table 5:</b> PMP Configuration Struct </b>(pmpcfg_t</b>) </p>

.. list-table::
   :header-rows: 1

   * - Signal
     - Type
     - Description

   * - ``locked``
     - logic
     - Lock this configuration

   * - ``reserved``
     - logic[1:0]
     - Reserved bits in pmpcfg CSR

   * - ``addr_mode``
     - pmp_addr_mode_t
     - Addressing Modes: OFF, TOR, NA4, NAPOT

   * - ``access_type``
     - pmpcfg_access_t
     - None, read, write, execute

.. raw:: html

   <span style="font-size:18px; font-weight:bold;">Control Flow in MMU Module</span>

.. figure:: _static/mmu_control_flow.png
   :name: **Figure 3:** Control Flow in CVA6 MMU
   :align: center
   :width: 95%
   :alt: mmu_control_flow

   **Figure 3:** Control Flow in CVA6 MMU

.. raw:: html

   <span style="font-size:18px; font-weight:bold;">Exception Sources with Address Translation Enabled</span>

Two potential exception sources exist:

* Hardware Page Table Walker (HPTW) throwing an exception, signifying a page fault exception.
* Access error due to insufficient permissions of PMP, known as an access exception.

.. raw:: html

   <span style="font-size:18px; font-weight:bold;">Instruction Fetch Interface</span>

The IF stage initiates a request to retrieve memory content at a specific virtual address. When the MMU is disabled, the instruction fetch request is directly passed to the I$ without modifications.

.. raw:: html

   <span style="font-size:18px; font-weight:bold;">Address Translation in Instruction Interface</span>

If virtual memory translation is enabled for instruction fetches, the following operations are performed in the instruction interface:

* Compatibility of requested virtual address with selected page based address translation scheme is checked.
* For page translation, the module determines the fetch physical address by combining the physical page number (PPN) from ITLB content and the offset from the virtual address. When hypervisor mode is enabled, the PPN from ITLB content is taken from the stage that is currently doing the translation.
* Depending on the size of the identified page the PPN of the fetch physical address is updated with the corresponding bits of the VPN to ensure alignment for superpage translation.
* If the Instruction TLB (ITLB) lookup hits, the fetch valid signal (which indicates a valid physical address) is activated in response to the input fetch request. Memory region accessibility is checked from the perspective of the fetch operation, potentially triggering a page fault exception in case of an access error or insufficient PMP permission.
* In case of an ITLB miss, if the page table walker (PTW) is active (only active if there is a shared TLB miss or the shared TLB is not used) and handling instruction fetches, the fetch valid signal is determined based on PTW errors or access exceptions.

If the fetch physical address doesn't match any execute region, an Instruction Access Fault is raised. When not translating, PMPs are immediately checked against the physical address for access verification.

.. raw:: html

   <span style="font-size:18px; font-weight:bold;">Data Interface</span>

.. raw:: html

   <span style="font-size:18px; font-weight:bold;">Address Translation in Data Interface</span>

If address translation is enabled for load or store, and no misaligned exception has occurred, the following operations are performed in the data interface:

* Initially, translation is assumed to be invalid, signified by the MMU to LSU.
* The translated physical address is formed by combining the PPN from the Page Table Entry (PTE) and the offset from the virtual address requiring translation. This is sent one cycle later due to the additional bank of registers which delayed the MMU’s answer. The PPN from the PTE is also shared separately with LSU in the same cycle as the hit. When hypervisor mode is enabled, the PPN from the PTE is taken from the stage that is currently doing the translation.
* In the case of superpage translation, the PPN of the translated physical address and the separately shared PPN are updated with the VPN of the virtual address.

If a Data TLB (DTLB) hit occurs, it indicates a valid translation, and various fault checks are performed depending on whether it's a load or store request.

* For store requests, if the page is not writable, the dirty flag isn't set, or privileges are violated, it results in a page fault corresponding to the store access. If PMPs are also violated, it leads to an access fault corresponding to the store access. Page faults take precedence over access faults.
* For load requests, a page fault is triggered if there are insufficient access privileges. PMPs are checked again during load access, resulting in an access fault corresponding to load access if PMPs are violated.

In case of a DTLB miss, potential exceptions are monitored during the page table walk. If the PTW indicates a page fault, the corresponding page fault related to the requested type is signaled. If the PTW indicates an access exception, the load access fault is indicated through address translation because the page table walker can only throw load access faults.

.. raw:: html

   <span style="font-size:18px; font-weight:bold;">Address Translation is Disabled</span>

When address translation is not enabled, the physical address is immediately checked against Physical Memory Protections (PMPs). If there is a request from LSU, no misaligned exception, and PMPs are violated, it results in an access fault corresponding to the request being indicated.

----------------------------
Translation Lookaside Buffer
----------------------------

Page tables are accessed for translating virtual memory addresses to physical memory addresses. This translation needs to be carried out for every load and store instruction and also for every instruction fetch. Since page tables are resident in physical memory, accessing these tables in all these situations has a significant impact on performance. Page table accesses occur in patterns that are closely related in time. Furthermore, the spatial and temporal locality of data accesses or instruction fetches mean that the same page is referenced repeatedly. Taking advantage of these access patterns the processor keeps the information of recent address translations, to enable fast retrieval, in a small cache called the Translation Lookaside Buffer (TLB) or an address-translation cache. 

The CVA6 TLB is structured as a fully associative cache, where the virtual address that needs to be translated is compared against all the individual TLB entries. Given a virtual address, the processor examines the TLB (TLB lookup) to determine if the virtual page number (VPN) of the page being accessed is in the TLB. When a TLB entry is found (TLB hit), the TLB returns the corresponding physical page number (PPN) which is used to calculate the target physical address. If no TLB entry is found (TLB miss) the processor has to read individual page table entries from memory (Table walk). In CVA6 table walking is supported by dedicated hardware. Once the processor finishes the table walk, it has the Physical Page Number (PPN) corresponding to the Virtual Page Number (VPN) that needs to be translated. The processor adds an entry for this address translation to the TLB so future translations of that virtual address will happen quickly through the TLB.  During the table walk the processor may find out that the corresponding physical page is not resident in memory. At this stage a page table exception (Page Fault) is generated which gets handled by the operating system. The operating system places the appropriate page in memory, updates the appropriate page tables and returns execution to the instruction which generated the exception.  

The input and output signals of the TLB are shown in the following figure. 

.. figure:: _static/in_out_tlb.png
   :name: **Figure 4:** Inputs and Outputs of CVA6 TLB
   :align: center
   :width: 100%
   :alt: in_out_tlb
 
   **Figure 4:** Inputs and Outputs of CVA6 TLB

.. raw:: html

   <span style="font-size:18px; font-weight:bold;">Signal Description of TLB</span>

.. raw:: html

   <p style="text-align:center;"> <b>Table 6:</b> CVA6 TLB Input Output Signals </p>

.. list-table::
   :header-rows: 1

  * - Signal
    - IO
    - connection
    - Type
    - Description

  * - ``clk_i``
    - in
    - SUBSYSTEM
    - logic
    - Subsystem Clock

  * - ``rst_ni``
    - in
    - SUBSYSTEM
    - logic
    - Asynchronous reset active low
    
  * - ``flush_i``
    - in
    - Controller
    - logic
    - SFENCE.VMA Committed

  * - ``flush_vvma_i``
    - in
    - Controller
    - logic
    - SFENCE.VVMA Committed

  * - ``flush_gvma_i``
    - in
    - Controller
    - logic
    - SFENCE.GVMA Committed

  * - ``s_st_enbl_i``
    - in
    - Controller
    - logic 
    - Indicates address translation request (s-stage) - used only in Hypervisor mode

  * - ``g_st_enbl_i``
    - in
    - Controller
    - logic 
    - Indicates address translation request (g-stage) - used only in Hypervisor mode

  * - ``v_i``
    - in
    - Controller
    - logic 
    - Indicates the virtualization mode state - used only in Hypervisor mode

  * - ``update_i``
    - in
    - Shared TLB
    - tlb_update_cva6_t
    - Updated tag and content of TLB

  * - ``lu_access_i``
    - in
    - Cache Subsystem
    - logic
    - Signal indicating a lookup access is being requested

  * - ``lu_asid_i``
    - in
    - CVA6 MMU 
    - logic[ASIDW-1:0]
    - ASID for the lookup

  * - ``lu_vmid_i``
    - in
    - CVA6 MMU 
    - logic[VMIDW-1:0]
    - VMID for the lookup when Hypervisor extension is enabled.

  * - ``lu_vaddr_i``
    - in
    - Cache Subsystem
    - logic[VLEN-1:0]
    - Virtual address for the lookup

  * - ``lu_content_o``
    - out
    - CVA6 MMU 
    - pte_cva6_t 
    - Output for the content of the TLB entry

  * - ``lu_g_content_o``
    - out
    - CVA6 MMU 
    - pte_cva6_t 
    - Output for the content of the TLB entry (g-stage)

  * - ``asid_to_be_flushed_i``
    - in
    - Execute Stage
    - logic [ASIDW-1:0]
    - ASID of the entry to be flushed. Vector 1 is the analogous one for virtual supervisor when Hypervisor extension is enabled

  * - ``vmid_to_be_flushed_i``
    - in
    - Execute Stage
    - logic [VMIDW-1:0]
    - VMID of the entry to be flushed when Hypervisor extension is enabled

  * - ``vaddr_to_be_flushed_i``
    - in
    - Execute Stage
    - logic [VLEN-1:0]
    - Virtual address of the entry to be flushed. Vector 1 is the analogous one for virtual supervisor when Hypervisor extension is enabled.

  * - ``gpaddr_to_be_flushed_i``
    - in
    - Execute Stage
    - logic [VLEN-1:0]
    - Virtual address of the guest entry to be flushed when Hypervisor extension is enabled.

  * - ``lu_is_page_o``
    - out
    - CVA6 MMU
    - logic [PT_LEVELS-2:0]
    - Output indicating whether the TLB entry corresponds to any page at the different page table levels

  * - ``lu_hit_o``
    - out
    - CVA6 MMU
    - logic
    - Output indicating whether the lookup resulted in a hit or miss

.. raw:: html

        <span style="font-size:18px; font-weight:bold;">Struct Description</span>

.. raw:: html

   <p style="text-align:center;"> <b>Table 7:</b> CVA6 TLB Update Struct (<b>tlb_update_cva6_t</b>) </p>

.. list-table::
   :header-rows: 1

  * - Signal
    - Type
    - Description

  * - ``valid``
    - logic
    - Indicates whether the TLB update entry is valid or not

  * - ``is_page``
    - logic [PtLevels-2:0][HYP_EXT:0]
    - Indicates if the TLB entry corresponds to a any page at the different levels. When Hypervisor extension is used it includes information also for the G-stage.

  * - ``vpn``
    - logic[VPN_LEN-1:0]
    - Virtual Page Number (VPN) used for updating the TLB

  * - ``asid``
    - logic[ASIDW-1:0] 
    - ASID used for updating the TLB

  * - ``vmid``
    - logic[VMIDW-1:0] 
    - VMID used for updating the TLB when Hypervisor extension is enabled
  
  * - ``v_st_enbl``
    - logic [HYP_EXT*2:0]
    - Used only in Hypervisor mode. Indicates for which stage the translation was requested and for which it is therefore valid (s_stage, g_stage or virtualization enabled).

  * - ``content``
    - pte_cva6_t  
    - Content of the TLB update entry 

  * - ``g_content``
    - pte_cva6_t  
    - Content of the TLB update entry for g stage when Hypervisor extension is enabled

.. raw:: html

   <p style="text-align:center;"> <b>Table 8:</b> CVA6 PTE Struct (<b>pte_cva6_t</b>) </p>

.. list-table::
  :header-rows: 1

  * - Signal
    - Type
    - Description

  * - ``ppn``
    - logic[PPNW-1:0] 
    - Physical Page Number (PPN)

  * - ``rsw``
    - logic[1:0]
    - Reserved for use by supervisor software

  * - ``d``
    - logic
    - | Dirty bit indicating whether the page has been modified (dirty) or not
      | 0: Page is clean i.e., has not been written
      | 1: Page is dirty i.e., has been written

  * - ``a``
    - logic
    - | Accessed bit indicating whether the page has been accessed
      | 0: Virtual page has not been accessed since the last time A bit was cleared
      | 1: Virtual page has been read, written, or fetched from since the last time the A bit was cleared

  * - ``g``
    - logic
    - | Global bit marking a page as part of a global address space valid for all ASIDs
      | 0: Translation is valid for specific ASID
      | 1: Translation is valid for all ASIDs

  * - ``u``
    - logic
    - | User bit indicating privilege level of the page
      | 0: Page is not accessible in user mode but in supervisor mode
      | 1: Page is accessible in user mode but not in supervisor mode

  * - ``x``
    - logic
    - | Execute bit which allows execution of code from the page
      | 0: Code execution is not allowed
      | 1: Code execution is permitted

  * - ``w``
    - logic
    - | Write bit allows the page to be written
      | 0: Write operations are not allowed
      | 1: Write operations are permitted

  * - ``r``
    - logic
    - | Read bit allows read access to the page
      | 0: Read operations are not allowed
      | 1: Read operations are permitted

  * - ``v``
    - logic
    - | Valid bit indicating the page table entry is valid
      | 0: Page is invalid i.e. page is not in DRAM, translation is not valid
      | 1: Page is valid i.e. page resides in the DRAM, translation is valid

.. raw:: html

   <span style="font-size:18px; font-weight:bold;">TLB Entry Fields</span>

The number of TLB entries can be changed via a design parameter. Each TLB entry is made up of two fields: Tag and Content. The Tag field holds the virtual page number, ASID, VMID and page size along with a valid bit (VALID) indicating that the entry is valid, and a v_st_enbl field that indicates at which level the translation is valid when hypervisor mode is enabled. The virtual page number, is further split into several separate virtual page numbers according to the number of PtLevels used in each configuration. The Content field contains the physical page numbers along with a number of bits which specify various attributes of the physical page. Note that the V bit in the Content field is the V bit which is present in the page table in memory. It is copied from the page table, as is,  and the VALID bit in the Tag is set based on its value. g_content is the equivalent for the g-stage translation. The TLB entry fields are shown in this Figure. Fields colored in grey are used only when H extension is implemented.

.. figure:: _static/cva6_tlb_entry.png
   :name: **Figure 5:** Fields in CVA6 TLB entry
   :align: center
   :width: 100%
   :alt: cva6_tlb_entry

   **Figure 5:** Fields in CVA6 TLB entry

.. raw:: html

   <span style="font-size:18px; font-weight:bold;">CVA6 TLB Management / Implementation</span>

The CVA6 TLB implements the following three functions:

* **Translation:** This function implements the address lookup and match logic.
* **Update and Flush:** This function implements the update and flush logic.
* **Pseudo Least Recently Used Replacement Policy:** This function implements the replacement policy for TLB entries.

.. raw:: html

   <span style="font-size:18px; font-weight:bold;">Translation</span>

This function takes in the virtual address and certain other fields, examines the TLB to determine if the virtual page number of the page being accessed is in the TLB or not. If a TLB entry is found (TLB hit), the TLB returns the corresponding physical page number (PPN) which is then used to calculate the target physical address. The following checks are done as part of this lookup function to find a match in the TLB:

* **Validity Check:** For a TLB hit, the associated TLB entry must be valid .
* **ASID, VMID and Global Flag Check:** The TLB entry's ASID must match the given ASID (ASID associated with the Virtual address). If the TLB entry’s Global bit (G) is set then this check is not done. This ensures that the translation is either specific to the provided ASID, or it is globally applicable. When the hypervisor extension is enabled, either the ASID or the VMID in the TLB entry must match ASID and/or VMID in the input, depending on which level(s) of translation is enabled. For the VMID the check is always applicable, regardless of G bit in the TLB entry.
* **Level VPN match:** CVA6 implements a multi-level page table. As such the virtual address is broken up into multiple parts which are the virtual page number used in the different levels. So the condition that is checked next is that the virtual page number of the virtual address matches the virtual page number of the TLB entry at each level. 
* **Page match:** Without Hypervisor extension, there is a match at a certain level X if the is_page component of the tag is set to 1 at level PtLevels-X. At level 0 page_match is always set to 1. When Hypervisor extension is enabled, the conditions to give a page match vary depending on the level we are at. At the highest level (PT_LEVELS -1), there is a page match at g and s stage (when enabled) if the corresponding is_page bit is set. If a stage is not enabled the is_page is considered a 1. At level 0, page_match is always 1 as in the case of no hypervisor extension. In the intermediate levels, the page_match is determined using the merged final translation size from both stages and their enable signals. 
  **Level match** The last condition to be checked at each page level, for a TLB hit, is that there is a vpn match for the current level and the higher ones, together with a page match at the current one. E.g. If PtLevels=2, a match at level 2 will occur if there is a VPN match at level 2 and a page match at level 2. For level 1, there will be a match if there is a VPN match at levels 2 and 1, together with a page match at level 1.


All the conditions listed above are checked against every TLB entry. If there is a TLB hit then the corresponding bit in the hit array is set. The following Figure Illustrates the TLB hit/miss process listed above.

.. figure:: _static/cva6_tlb_hit.png
   :name: **Figure 6:** Block diagram of CVA6 TLB hit or miss
   :align: center
   :width: 75%
   :alt: cva6_tlb_hit

   **Figure 6:** Block diagram of CVA6 TLB hit or miss

.. raw:: html

   <span style="font-size:18px; font-weight:bold;">Flushing TLB entries</span>

The SFENCE.VMA instruction can be used with certain specific source register specifiers (rs1 & rs2) to flush a specific TLB entry, some set of TLB entries or all TLB entries. Like all instructions this action only takes place when the SFENCE.VMA instruction is committed (shown via the commit_sfence signal in the following figures.) The behavior of the instruction is as follows:

* **If rs1 is not equal to x0 and rs2 is not equal to x0:** Invalidate all TLB entries which contain leaf page table entries corresponding to the virtual address in rs1 (shown below as Virtual Address to be flushed) and that match the address space identifier as specified by integer register rs2 (shown below as asid_to_be_flushed_i), except for entries containing global mappings. This is referred to as the “SFENCE.VMA vaddr asid” case.

.. figure:: _static/sfence_vaddr_asid.png
   :name: **Figure 7:** Invalidate TLB entry if ASID and virtual address match
   :align: center
   :width: 75%
   :alt: sfence_vaddr_asid

   **Figure 7:** Invalidate TLB entry if ASID and virtual address match

* **If rs1 is equal to x0 and rs2 is equal to x0:** Invalidate all TLB entries for all address spaces. This is referred to as the "SFENCE.VMA x0 x0" case.

.. figure:: _static/sfence_x0_x0.png
   :name: **Figure 8:** Invalidate all TLB entries if both source register specifiers are x0
   :align: center
   :width: 62%
   :alt: sfence_x0_x0

   **Figure 8:** Invalidate all TLB entries if both source register specifiers are x0

* **If rs1 is not equal to x0 and rs2 is equal to x0:** invalidate all TLB entries that contain leaf page table entries corresponding to the virtual address in rs1, for all address spaces. This is referred to as the “SFENCE.VMA vaddr x0” case.

.. figure:: _static/sfence_vaddr_x0.png
   :name: **Figure 9:** Invalidate TLB entry with matching virtual address for all address spaces
   :align: center
   :width: 75%
   :alt: sfence_vaddr_x0

   **Figure 9:** Invalidate TLB entry with matching virtual address for all address spaces

* **If rs1 is equal to x0 and rs2 is not equal to x0:** Invalidate all TLB entries matching the address space identified by integer register rs2, except for entries containing global mappings. This is referred to as the “SFENCE.VMA 0 asid” case.

.. figure:: _static/sfence_x0_asid.png
   :name: **Figure 10:** Invalidate TLB entry for matching ASIDs
   :align: center
   :width: 75%
   :alt: sfence_x0_asid

   **Figure 10:** Invalidate TLB entry for matching ASIDs

The TLB fully implements the supervisor flush instructions, i.e., hfence, including filtering by ASID and virtual address. To support nested translation,it supports the two translation stages, including access permissions (rwx) and VMIDs. This is done analogously to the fence cases explained above.

* **HFENCE.VVMA vaddr asid case:** Invalidate all TLB entries which contain leaf page table entries corresponding to the Virtual Address to be flushed and that match the address space identifiers as specified by ASID_to_be_flushed_i and lu_VMID, except for entries containing global mappings.

* **HFENCE.VVMA x0 x0 case:** Invalidate all TLB entries for all address spaces if current VMID matches and ASID is 0 and vaddr to be flushed is 0.

* **HFENCE.VVMA vaddr x0 case:** Invalidate all TLB entries which contain leaf page table entries corresponding to the Virtual Address to be flushed if current VMID matches and ASID to be flushed is 0.

* **HFENCE.VVMA x0 asid case:** Invalidate all TLB entries matching the address space identified by ASID_to_be_flushed_i and lu_VMID when vaddr to be flushed is 0, except for entries containing global mappings.

* **HFENCE.GVMA gpaddr vmid case:** Invalidate all TLB entries which contain leaf page table entries corresponding to the gpaddr to be flushed and that match the VMID.

* **HFENCE.GVMA x0 x0 case:** Invalidate all TLB entries for all address spaces if VMID is 0 and gpaddr to be flushed is 0.

* **HFENCE.GVMA gpaddr x0 case:** Invalidate all TLB entries which contain leaf page table entries corresponding to the gpaddr to be flushed if VMID to be flushed is 0.

* **HFENCE.GVMA x0 vmid case:** Invalidate all TLB entries matching the address space identified by VMID_to_be_flushed_i when gpaddr to be flushed is 0.

.. raw:: html

   <span style="font-size:18px; font-weight:bold;">Updating TLB</span>

When a TLB valid update request is signaled by the shared TLB, and the replacement policy select the update of a specific TLB entry, the corresponding entry's tag is updated with the new tag, and its associated content is refreshed with the information from the update request. This ensures that the TLB entry accurately reflects the new translation information.

.. raw:: html

   <span style="font-size:18px; font-weight:bold;">Pseudo Least Recently Used Replacement Policy</span>

Cache replacement algorithms are used to determine which TLB entry should be replaced, because it is not likely to be used in the near future. The Pseudo-Least-Recently-Used (PLRU) is a cache entry replacement algorithm, derived from Least-Recently-Used (LRU) cache entry replacement algorithm, used by the TLB. Instead of precisely tracking recent usage as the LRU algorithm does, PLRU employs an approximate measure to determine which entry in the cache has not been recently used and as such can be replaced. 

CVA6 implements the PLRU algorithm via the Tree-PLRU method which implements a binary tree. The TLB entries are the leaf nodes of the tree. Each internal node, of the tree, consists of a single bit, referred to as the state bit or plru bit, indicating which subtree contains the (pseudo) least recently used entry (the PLRU); 0 for the left hand tree and 1 for the right hand tree. Following this traversal, the leaf node reached, corresponds to the PLRU entry which can be replaced. Having accessed an entry (so as to replace it) we need to promote that entry to be the Most Recently Used (MRU) entry. This is done by updating the value of each node along the access path to point away from that entry. If the accessed entry is a right child i.e., its parent node value is 1, it is set to 0, and if the parent is the left child of its parent (the grandparent of the accessed node) then its node value is set to 1 and so on all the way up to the root node.

The PLRU binary tree is implemented as an array of node values. Nodes are organized in the array based on levels, with those from lower levels appearing before higher ones. Furthermore those on the left side of a node appear before those on the right side of a node. The figure below shows a tree and the corresponding array.

.. figure:: _static/plru_tree_indexing.png
   :name: **Figure 11:** PLRU Tree Indexing
   :align: center
   :width: 60%
   :alt: plru_tree_indexing

   **Figure 11:** PLRU Tree Indexing

For n-way associative, we require n - 1 internal nodes in the tree. With those nodes, two operations need to be performed efficiently.

* Promote the accessed entry to be MRU
* Identify which entry to replace (i.e. the PLRU entry)

.. raw:: html

   <span style="font-size:18px; font-weight:bold;">Updating the PLRU-Tree</span>

For a TLB entry which is accessed, the following steps are taken to make it the MRU:

1. Iterate through each level of the binary tree.
2. Calculate the index of the leftmost child within the current level. Let us call that index the index base.
3. Calculate the shift amount to identify the relevant node based on the level and TLB entry index.
4. Calculate the new value that the node should have in order to make the accessed entry the Most Recently Used (MRU). The new value of the root node is the opposite of the TLB entry index, MSB at the root node, MSB - 1 at node at next level and so on.
5. Assign this new value to the relevant node, ensuring that the hit entry becomes the MRU within the binary tree structure.

At level 0, no bit of the TLB entry’s index determines the offset from the index base because it’s a root node. At level 1, MSB of entry’s index determines the amount of offset from index base at that level. At level 2, the first two bits of the entry's index from MSB side determine the offset from the index base because there are 4 nodes at the level 2 and so on. 

.. figure:: _static/update_tree.png
   :name: **Figure 12:** Promote Entry to be MRU
   :align: center
   :width: 82%
   :alt: update_tree

   **Figure 12:** Promote Entry to be MRU

In the above figure entry at index 5, is accessed. To make it MRU entry, every node along the access path should point away from it. Entry 5 is a right child, therefore, its parent plru bit set to 0, its parent is a left child, its grand parent’s plru bit set to 1, and great grandparent’s plru bit set to 0.

.. raw:: html

   <span style="font-size:18px; font-weight:bold;">Entry Selection for Replacement</span>

Every TLB entry is checked for the replacement entry. The following steps are taken:

1. Iterate through each level of the binary tree.
2. Calculate the index of the leftmost child within the current level. Let us call that index the index base.
3. Calculate the shift amount to identify the relevant node based on the level and TLB entry index.
4. If the corresponding bit of the entry's index matches the value of the node being traversed at the current level, keep the replacement signal high for that entry; otherwise, set the replacement signal to low.

.. figure:: _static/replacement_entry.png
   :name: **Figure 13:** Possible path traverse for entry selection for replacement
   :align: center
   :width: 65%
   :alt: replacement_entry

   **Figure 13:** Possible path traverse for entry selection for replacement

Figure shows every possible path that traverses to find out the PLRU entry. If the plru bit at each level matches with the corresponding bit of the entry's index, that’s the next entry to replace. Below Table shows the entry selection for replacement.

.. raw:: html

   <p style="text-align:center;"> <b>Table 9:</b> Entry Selection for Replacement </p>

+-------------------+---------------+----------------------+
| **Path Traverse** | **PLRU Bits** | **Entry to replace** |
+-------------------+---------------+----------------------+
| 0 -> 1 -> 3       | 000           | 0                    |
|                   +---------------+----------------------+
|                   | 001           | 1                    |
+-------------------+---------------+----------------------+
| 0 -> 1 -> 4       | 010           | 2                    |
|                   +---------------+----------------------+
|                   | 011           | 3                    |
+-------------------+---------------+----------------------+
| 0 -> 2 -> 5       | 100           | 4                    |
|                   +---------------+----------------------+
|                   | 101           | 5                    |
+-------------------+---------------+----------------------+
| 0 -> 2 -> 6       | 110           | 6                    |
|                   +---------------+----------------------+
|                   | 111           | 7                    |
+-------------------+---------------+----------------------+

-----------------------------------
Shared Translation Lookaside Buffer
-----------------------------------

The CVA6 shared TLB is structured as a 2-way associative cache, where the virtual address requiring translation is compared with the set indicated by the virtual page number. The shared TLB is looked up in case of an Instruction TLB (ITLB) or data TLB (DTLB) miss, signaled by these TLBs. If the entry is found in the shared TLB set, the respective TLB, whose translation is being requested, is updated. If the entry is not found in the shared TLB, then the processor has to perform a page table walk. Once the processor obtains a PPN corresponding to the VPN, the shared TLB is updated with this information. If the physical page is not found in the page table, it results in a page fault, which is handled by the operating system. The operating system will then place the corresponding physical page in memory.

The use of the shared TLB is optional in CVA6, via the ``UseSharedTlb`` parameter. When it is not used, the requests from ITLB and DTLB go directly to the PTW, and the update from the PTW goes directly to the ITLB and DTLB respectively.  

The input and output signals of the shared TLB are shown in the following Figure. 

.. figure:: _static/shared_tlb_in_out.png
   :name: **Figure 14:** Inputs and outputs of CVA6 shared TLB
   :align: center
   :width: 100%
   :alt: shared_tlb_in_out

   **Figure 14:** Inputs and outputs of CVA6 shared TLB

.. raw:: html

   <span style="font-size:18px; font-weight:bold;">Signal Description</span>

.. raw:: html

   <p style="text-align:center;"> <b>Table 10:</b> Signal Description of CVA6 shared TLB </p>

.. list-table::
    :header-rows: 1

    * - Signal
      - IO
      - Connection
      - Type
      - Description

    * - ``clk_i``
      - in
      - Subsystem
      - logic
      - Subsystem Clock

    * - ``rst_ni``
      - in
      - Subsystem
      - logic
      - Asynchronous reset active low

    * - ``flush_i``
      - in
      - Controller
      - logic
      - SFENCE.VMA Committed

    * - ``flush_vvma_i``
      - in
      - Controller
      - logic
      - SFENCE.VVMA Committed

    * - ``flush_gvma_i``
      - in
      - Controller
      - logic
      - SFENCE.GVMA Committed

    * - ``s_st_enbl_i``
      - in
      - Controller
      - logic 
      - Indicates address translation request (s-stage) 

    * - ``g_st_enbl_i``
      - in
      - Controller
      - logic 
      - Indicates address translation request (g-stage) - used only in Hypervisor mode

    * - ``v_i``
      - in
      - Controller
      - logic 
      - Indicates the virtualization mode state - used only in Hypervisor mode

    * - ``s_ld_st_enbl_i``
      - in
      - Controller
      - logic 
      - Indicates address translation request (s-stage) for load stores

    * - ``g_ld_st_enbl_i``
      - in
      - Controller
      - logic 
      - Indicates address translation request (g-stage) for load stores - used only in Hypervisor mode

    * - ``ld_st_v_i``
      - in
      - Controller
      - logic 
      - Indicates the virtualization mode state for load stores


    * - ``dtlb_asid_i``
      - in
      - MMU
      - logic [ASIDW-1:0]
      - ASID for the lookup in case of a DTLB miss 

    * - ``itlb_asid_i``
      - in
      - MMU
      - logic [ASIDW-1:0]
      - ASID for the lookup in case of an ITLB miss 

    * - ``lu_vmid_i``
      - in
      - MMU
      - logic [VMIDW-1:0]
      - VMID for the lookup 

    * - ``itlb_access_i``
      - in
      - Cache Subsystem
      - logic
      - Signal indicating a lookup access in ITLB is being requested.

    * - ``itlb_hit_i``
      - in
      - ITLB
      - logic
      - Signal indicating an ITLB hit

    * - ``itlb_vaddr_i``
      - in
      - Cache Subsystem
      - logic [VLEN-1:0]
      - Virtual address lookup in ITLB

    * - ``dtlb_access_i``
      - in
      - Load/Store Unit
      - logic
      - Signal indicating a lookup access in DTLB is being requested.

    * - ``dtlb_hit_i``
      - in
      - DTLB
      - logic
      - Signal indicating a DTLB hit

    * - ``dtlb_vaddr_i``
      - in
      - Load/Store Unit
      - logic [VLEN-1:0]
      - Virtual address lookup in DTLB

    * - ``itlb_update_o``
      - out
      - ITLB
      - tlb_update_cva6_t
      - Tag and content to update ITLB

    * - ``dtlb_update_o``
      - out
      - DTLB
      - tlb_update_cva6_t
      - Tag and content to update DTLB

    * - ``itlb_miss_o``
      - out
      - Performance Counter
      - logic
      - Signal indicating an ITLB miss

    * - ``dtlb_miss_o``
      - out
      - Performance Counter
      - logic
      - Signal indicating a DTLB miss
      
    * - ``shared_tlb_access_o``
      - out
      - PTW
      - logic
      - Signal indicating a lookup access in shared TLB is being requested

    * - ``shared_tlb_hit_o``
      - out
      - PTW
      - logic
      - Signal indicating a shared TLB hit

    * - ``shared_tlb_vaddr_o``
      - out
      - PTW
      - logic [VLEN-1:0]
      - Virtual address lookup in shared TLB
      
    * - ``itlb_req_o``
      - out
      - PTW
      - logic
      - ITLB Request Output

    * - ``shared_tlb_update_i``
      - in
      - PTW
      - tlb_update_cva6_t
      - Updated tag and content of shared TLB

.. raw:: html

   <span style="font-size:18px; font-weight:bold;">Shared TLB Entry Structure</span>

Shared TLB is 2-way associative, with a depth of 64 by default, but can be selected via a user parameter. A single entry in the set contains the valid bit, tag and the content. The Tag segment stores details such as the virtual page number, ASID, VMID and page size. The Content field contains the physical page numbers along with a number of bits which specify various attributes of the physical page.

.. figure:: _static/shared_tlb.png
   :name: **Figure 15:** CVA6 Shared TLB Structure
   :align: center
   :width: 60%
   :alt: shared_tlb

   **Figure 15:** CVA6 Shared TLB Structure

.. raw:: html

   <span style="font-size:18px; font-weight:bold;">Shared TLB Implementation in CVA6</span>

The implementation of a shared TLB in CVA6 is described in the following sections:

* **ITLB and DTLB Miss:** Prepare a shared TLB lookup if the entry is not found in ITLB or DTLB.
* **Tag Comparison:** Look up the provided virtual address in the shared TLB.
* **Update and Flush:** Flush the shared TLB or update it.
* **Replacement Policies:** First non-valid entry and random replacement policy.

.. raw:: html

   <span style="font-size:18px; font-weight:bold;">ITLB and DTLB Miss</span>

Consider a scenario where an entry is found in the ITLB or DTLB. In this case, there is no need to perform a lookup in the shared TLB since the entry has already been found. Next, there are two scenarios: an ITLB miss or a DTLB miss.

To identify an ITLB miss, the following conditions need to be fulfilled:

* Address translation must be enabled.
* There must be an access request to the ITLB.
* The ITLB should indicate an ITLB miss.
* There should be no access request to the DTLB.

During an ITLB miss, access is granted to read the tag and content of the shared TLB from their respective sram. The address for reading the tag and content of the shared TLB entry is calculated using the virtual address for which translation is not found in the ITLB. The ITLB miss is also explicitly indicated by the shared TLB. A request for shared TLB access is initiated.

To identify the DTLB miss, the following conditions need to be fulfilled:

* Address translation for load and stores must be enabled.
* There must be an access request to the DTLB.
* The DTLB should indicate a DTLB miss.

In the case of a DTLB miss, the same logic is employed as described for an ITLB miss.

.. raw:: html

   <span style="font-size:18px; font-weight:bold;">Tag Comparison</span>

Shared TLB lookup for a hit occurs under the same conditions as described for the TLB modules used as ITLB and DTLB. However, there are some distinctions. In both the ITLB and DTLB, the virtual address requiring translation is compared against all TLB entries. In contrast, the shared TLB only compares the tag and content of the set indicated by the provided virtual page number. The index of the set is extracted from the VPN of the requested virtual address. Given that the shared TLB is 2-way associative, each set contains two entries. Consequently, both of these entries are compared. Below figure illustrates how the set is opted for the lookup. In case that the shared TLB is not used, the hit and corresponding update information come directly from the PTW, bypassing the shared TLB block.

.. figure:: _static/shared_tlb_set.png
   :name: **Figure 16:** Set opted for lookup in shared TLB
   :align: center
   :width: 60%
   :alt: shared_tlb_set

   **Figure 16:** Set opted for lookup in shared TLB

.. raw:: html

   <span style="font-size:18px; font-weight:bold;">Update and Flush</span>

Differing from the ITLB and DTLB, a specific virtual address or addressing space cannot be flushed in the shared TLB. When SFENCE.VMA is committed, all entries in the shared TLB are invalidated. (Cases of SFENCE.VMA should also be added in shared TLB)

.. raw:: html

   <span style="font-size:18px; font-weight:bold;">Updating Shared TLB</span>

When the Page Table Walker signals a valid update request, the shared TLB is updated by selecting an entry through the replacement policy and marking it as valid. This also triggers the writing of the new tag and content to the respective SRAM. As stated above, when the shared TLB is not used, the update from PTW goes directly to the ITLB and DTLB depending on which initiated the request, and the SRAM is not instantiated.

.. raw:: html

   <span style="font-size:18px; font-weight:bold;">Replacement Policy Implemented in CVA6 Shared TLB</span>

In CVA6's shared TLB, two replacement policies are employed for replacements based on a specific condition. These replacement policies select the entry within the set indicated by the virtual page number. The two policies are:

* First non-valid encounter replacement policy
* Random replacement policy

First replacement policy failed if all ways are valid. Therefore, a random replacement policy is opted for. 

.. raw:: html

   <span style="font-size:18px; font-weight:bold;">First non-valid encounter replacement policy</span>

The module implemented in CVA6 to find the first non-valid entry in the shared TLB is the Leading Zero Counter (LZC). It takes three parameters as input:

1. **WIDTH:** The width of the input vector.
2. **MODE:** Mode selection - 0 for trailing zero, 1 for leading zero.
3. **CNT WIDTH:** Width of the output signal containing the zero count.

The input signal is the vector to be counted, and the output represents the count of trailing/leading zeros. If all bits in the input vector are zero, it will also be indicated.

When initializing the module, the width of the input vector is set to the number of shared TLB ways. The trailing zero counter mode is selected. The vector of valid bits is set as the input vector, but with negation. This is because we want the index of the first non-valid entry, and LZC returns the count of trailing zeros, which actually corresponds to the index of the first occurrence of 1 from the least significant bit (LSB). if there is at least one non-valid entry, that entry is opted for the replacement, and if not then this is signaled by LZC.

.. figure:: _static/LZC.png
   :name: **Figure 17:** Replacement of First invalid entry.
   :align: center
   :width: 60%
   :alt: LZC

   **Figure 17:** Replacement of First invalid entry.

.. raw:: html

   <span style="font-size:18px; font-weight:bold;">Random replacement policy</span>

If all ways are valid, a random replacement policy is employed for the replacement process. The Linear Feedback Shift Register (LFSR) is utilized to select the replacement entry randomly. LFSR is commonly used in generating sequences of pseudo-random numbers. When the enable signal is active, the current state of the LFSR undergoes a transformation. Specifically, the state is shifted right by one bit, and the result is combined with a predetermined masking pattern. This masking pattern is derived from the predefined “Masks” array, introducing a non-linear behavior to the sequence generation of the LFSR. The masking process involves XOR operations between the shifted state bits and specific pattern bits, contributing to the complexity and unpredictability of the generated sequence.

.. figure:: _static/RR.png
   :name: **Figure 18:** Entry selection for replacement using LFSR
   :align: center
   :width: 95%
   :alt: RR

   **Figure 18:** Entry selection for replacement using LFSR

-----------------
Page Table Walker
-----------------

The "CVA6 Page Table Walker (PTW)" is a hardware module designed to facilitate the translation of virtual addresses into physical addresses, a crucial task in memory access management. The Hypervisor extension specifies a new translation stage (G-stage) to translate guest-physical addresses into host-physical addresses.

.. figure:: _static/ptw_in_out.png
   :name: **Figure 19:** Input and Outputs of Page Table Walker
   :align: center
   :width: 100%
   :alt: ptw_in_out

   **Figure 19:** Input and Outputs of Page Table Walker

.. raw:: html

   <span style="font-size:18px; font-weight:bold;">Operation of PTW Module</span>

The PTW module operates through various states, each with its specific function, such as handling memory access requests, validating page table entries, and responding to errors.

.. raw:: html

   <span style="font-size:18px; font-weight:bold;">Key Features and Capabilities</span>

Key features of this PTW module include support for multiple levels of page tables (PtLevels), accommodating instruction and data page table walks. It rigorously validates and verifies page table entries (PTEs) to ensure translation accuracy and adherence to access permissions. This module seamlessly integrates with the CVA6 processor's memory management unit (MMU), which governs memory access control. It also takes into account global mapping, access flags, and privilege levels during the translation process, ensuring that memory access adheres to the processor's security and privilege settings.

.. raw:: html

   <span style="font-size:18px; font-weight:bold;">Exception Handling</span>

In addition to its translation capabilities, the PTW module is equipped to detect and manage errors, including page-fault exceptions and access exceptions, contributing to the robustness of the memory access system. It works harmoniously with physical memory protection (PMP) configurations, a critical aspect of modern processors' memory security. Moreover, the module efficiently processes virtual addresses, generating corresponding physical addresses, all while maintaining speculative translation, a feature essential for preserving processor performance during memory access operations.

.. raw:: html

   <span style="font-size:18px; font-weight:bold;">Signal Description</span>

.. raw:: html

   <p style="text-align:center;"> <b>Table 12:</b> Signal Description of PTW </p>

.. list-table::
    :header-rows: 1

    * - Signal
      - IO
      - Connection
      - Type
      - Description

    * - ``clk_i``
      - in
      - Subsystem
      - logic
      - Subsystem Clock

    * - ``rst_ni``
      - in
      - Subsystem
      - logic
      - Asynchronous reset active low

    * - ``flush_i``
      - in
      - Controller
      - logic
      - Sfence Committed

    * - ``ptw_active_o``
      - out
      - MMU
      - logic
      - Output signal indicating whether the Page Table Walker (PTW) is currently active

    * - ``walking_instr_o``
      - out
      - MMU
      - logic
      - Indicating it's an instruction page table walk or not

    * - ``ptw_error_o``
      - out
      - MMU
      - logic
      - Output signal indicating that an error occurred during PTW operation

    * - ``ptw_error_at_g_st_o``
      - out
      - MMU
      - logic
      - Output signal indicating that an error occurred during PTW operation at the G stage

    * - ``ptw_err_at_g_int_st_o``
      - out
      - MMU
      - logic
      - Output signal indicating that an error occurred during PTW operation at the G stage during S stage

    * - ``ptw_access_exception_o``
      - out
      - MMU
      - logic
      - Output signal indicating that a PMP (Physical Memory Protection) access exception occurred during PTW operation.

    * - ``enable_translation_i``
      - in
      - CSR RegFile
      - logic 
      - Enables address translation request for instruction

    * - ``enable_g_translation_i``
      - in
      - CSR RegFile
      - logic 
      - Enables virtual memory translation for instrucionts

    * - ``en_ld_st_translation_i``
      - in
      - CSR RegFile
      - logic
      - Enables address translation request for load or store

    * - ``en_ld_st_g_translation_i``
      - in
      - CSR RegFile
      - logic
      - Enables virtual memory translation for load or store

    * - ``v_i``
      - in
      - CSR RegFile
      - logic
      - Virtualization mode state

    * - ``ld_st_v_i``
      - in
      - CSR RegFile
      - logic
      - Virtualization mode state
    
    * - ``hlvx_inst_i``
      - in
      - Store / Load Unit
      - logic 
      - Indicates that Instruction is a hypervisor load store with execute permissions 
    
    * - ``lsu_is_store_i``
      - in
      - Store Unit
      - logic
      - Input signal indicating whether the translation was triggered by a store operation.

    * - ``req_port_i``
      - in
      - Cache Subsystem
      - dcache_req_o_t
      - D Cache Data Requests

    * - ``req_port_o``
      - out
      - Cache Subsystem / Perf Counter
      - dcache_req_u_t
      - D Cache Data Response

    * - ``shared_tlb_update_o``
      - out
      - Shared TLB
      - tlb_update_cva6_t
      - Updated tag and content of shared TLB

    * - ``update_vaddr_o``
      - out
      - MMU
      - logic[VLEN-1:0]
      - Updated VADDR from shared TLB

    * - ``asid_i``
      - in
      - CSR RegFile
      - logic [ASIDW-1:0]
      - ASID for the lookup

    * - ``vs_asid_i``
      - in
      - CSR RegFile
      - logic [ASIDW-1:0]
      - ASID for the lookup for virtual supervisor when Hypervisor extension is enabled

    * - ``vmid_i``
      - in
      - CSR RegFile
      - logic [VMIDW-1:0]
      - VMID for the lookup when Hypervisor extension is enabled

    * - ``shared_tlb_access_i``
      - in
      - Shared TLB
      - logic
      - Access request of shared TLB

    * - ``shared_tlb_hit_i``
      - in
      - Shared TLB
      - logic
      - Indicate shared TLB hit

    * - ``shared_tlb_vaddr_i``
      - in
      - Shared TLB
      - logic[VLEN-1:0]
      - Virtual Address from shared TLB

    * - ``itlb_req_i``
      - in
      - Shared TLB
      - logic
      - Indicate request to ITLB

    * - ``satp_ppn_i``
      - in
      - CSR RegFile
      - logic [PPNW-1:0]
      - PPN of top level page table from SATP register

    * - ``vsatp_ppn_i``
      - in
      - CSR RegFile
      - logic [PPNW-1:0]
      - PPN of top level page table from VSATP register when Hypervisor extension is enabled

    * - ``hgatp_ppn_i``
      - in
      - CSR RegFile
      - logic [PPNW-1:0]
      - PPN of top level page table from HGATP register when Hypervisor extension is enabled

    * - ``mxr_i``
      - in
      - CSR RegFile
      - logic
      - Make Executable Readable bit in xSTATUS CSR register

    * - ``vmxr_i``
      - in
      - CSR RegFile
      - logic
      - Virtual Make Executable Readable bit in xSTATUS CSR register for virtual supervisor when Hypervisor extension is enabled.

    * - ``shared_tlb_miss_o``
      - out
      - OPEN
      - logic
      - Indicate a shared TLB miss

    * - ``pmpcfg_i``
      - in
      - CSR RegFile
      - pmpcfg_t[15:0]
      - PMP configuration

    * - ``pmpaddr_i``
      - in
      - CSR RegFile
      - logic[15:0][PLEN-3:0]
      - PMP Address

    * - ``bad_paddr_o``
      - out
      - MMU
      - logic[PLEN-1:0]
      - Bad Physical Address in case of access exception

    * - ``bad_gpaddr_o``
      - out
      - MMU
      - logic[GPLEN-1:0]
      - Bad Guest Physical Address in case of access exception when Hypervisor is enabled.

.. raw:: html

   <span style="font-size:18px; font-weight:bold;">Struct Description</span>

.. raw:: html

   <p style="text-align:center;"> <b>Table 13:</b> D Cache Response Struct </b>(dcache_req_i_t</b>) </p>

.. list-table::
   :header-rows: 1

   * - Signal
     - Type
     - Description
     
   * - ``address_index``
     - logic [DCACHE_INDEX_WIDTH-1:0]
     - Index of the Dcache Line

   * - ``address_tag``
     - logic [DCACHE_TAG_WIDTH-1:0]
     - Tag of the Dcache Line

   * - ``data_wdata``
     - xlen_t
     - Data to write in the Dcache

   * - ``data_wuser``
     - logic [DCACHE_USER_WIDTH-1:0]
     - data_wuser

   * - ``data_req``
     - logic
     - Data Request

   * - ``data_we``
     - logic
     - Data Write enabled

   * - ``data_be``
     - logic [(XLEN/8)-1:0]
     - Data Byte enable

   * - ``data_size``
     - logic [1:0]
     - Size of data

   * - ``data_id``
     - logic [DCACHE_TID_WIDTH-1:0]
     - Data ID

   * - ``kill_req``
     - logic
     - Kill the D cache request

   * - ``tag_valid``
     - logic
     - Indicate that teh tag is valid

.. raw:: html

   <p style="text-align:center;"> <b>Table 14:</b> D Cache Request Struct </b>(dcache_req_o_t</b>) </p>

.. list-table::
   :header-rows: 1

   * - Signal
     - Type
     - Description

   * - ``data_gnt``
     - logic
     - Grant of data is given in response to the data request

   * - ``data_rvalid``
     - logic
     - Indicate that data is valid which is sent by D cache

   * - ``data_rid``
     - logic [DCACHE_TID_WIDTH-1:0]
     - Requested data ID

   * - ``data_rdata``
     - xlen_t
     - Data from D cache

   * - ``data_ruser``
     - logic [DCACHE_USER_WIDTH-1:0]
     - Requested data user

.. raw:: html

   <span style="font-size:18px; font-weight:bold;">PTW State Machine</span>

Page Table Walker is implemented as a finite state machine. It listens to shared TLB for incoming translation requests. If there is a shared TLB miss, it saves the virtual address and starts the page table walk. Page table walker transitions between 7 states in CVA6.

* **IDLE:** The initial state where the PTW is awaiting a trigger, often a Shared TLB miss, to initiate a memory access request. In the case of the Hypervisor extension, the stage to which the translation belongs is determined by the enable_translation_XX and en_ld_st_translation_XX signals. There are 3 possible stages: (i) S-Stage - the PTW current state is translating a guest-virtual address into a guest-physical address; (ii) G-Stage Intermed - the PTW current state is translating memory access made from the VS-Stage during the walk to host-physical address; and (iii) G-Stage Final - the PTW current state is translating the final output address from VS-Stage into a host-physical address. When Hypervisor is not enabled PTW is always in S_STAGE.
* **WAIT_GRANT:** Request memory access and wait for data grant
* **PTE_LOOKUP:** Once granted access, the PTW examines the valid Page Table Entry (PTE), checking attributes to determine the appropriate course of action. Depending on the STAGE determined in the previous state, pptr and other attributes are updated accordingly.
* **PROPAGATE_ERROR:** If the PTE is invalid, this state handles the propagation of an error, often leading to a page-fault exception due to non-compliance with access conditions.
* **PROPAGATE_ACCESS_ERROR:** Propagate access fault if access is not allowed from a PMP perspective
* **WAIT_RVALID:** After processing a PTE, the PTW waits for a valid data signal, indicating that relevant data is ready for further processing.
* **LATENCY:** Introduces a delay to account for synchronization or timing requirements between states.

The next figure shows the state diagram of the PTW FSM. The blue lines correspond to transitions that exist only when hypervisor extension is enabled.

.. figure:: _static/ptw_state_diagram.png
   :name: **Figure 20:** State Machine Diagram of CVA6 PTW
   :align: center
   :width: 95%
   :alt: ptw_state_diagram

   **Figure 20:** State Machine Diagram of CVA6 PTW

.. raw:: html

   <span style="font-size:18px; font-weight:bold;">IDLE state</span>

In the IDLE state of the Page Table Walker (PTW) finite state machine, the system awaits a trigger to initiate the page table walk process. This trigger is often prompted by a Shared Translation Lookaside Buffer (TLB) miss, indicating that the required translation is not present in the shared TLB cache. The PTW's behavior in this state is explained as follows:

1. The top-most page table is selected for the page table walk. In all configurations, the walk starts at level 0.
2. In the IDLE state, translations are assumed to be invalid in all addressing spaces.
3. The signal indicating the instruction page table walk is set to 0.
4. A conditional check is performed: if there is a shared TLB access request and the entry is not found in the shared TLB (indicating a shared TLB miss), the following steps are executed:

   a. The address of the desired Page Table Entry within the level 0 page table is calculated by multiplying the Physical Page Number (PPN) of the level 0 page table from the SATP register by the page size. This result is then added to the product of the Virtual Page Number, and the size of a page table entry. Depending on the translation indicated by enable_translation_XX, en_ld_st_translation_XX and v_i signals,  the corresponding register (satp_ppn_i, vsatp_ppn_i or hgatp_ppn_i) and bits of the VPN are used.

.. figure:: _static/ptw_nlvl.png
   :name: **Figure 27:** Address of desired PTE at next level of Page Table
   :align: center
   :width: 70%
   :alt: ptw_nlvl

   **Figure 21:** Address of desired PTE at next level of Page Table


.. _example:

   b. The signal indicating whether it's an instruction page table walk is updated based on the itlb_req_i signal.
   c. The ASID, VMID and virtual address are saved for the page table walk.
   d. A shared TLB miss is indicated.

.. raw:: html

   <span style="font-size:18px; font-weight:bold;">WAIT GRANT state</span>

In the **WAIT_GRANT** state of the Page Table Walker's finite state machine, a data request is sent to retrieve memory information. It waits for a data grant signal from the Dcache controller, remaining in this state until granted. Once granted, it activates a tag valid signal, marking data validity. The state then transitions to "PTE_LOOKUP" for page table entry lookup.

.. raw:: html

   <span style="font-size:18px; font-weight:bold;">PTE LOOKUP state</span>

In the **PTE_LOOKUP** state of the Page Table Walker (PTW) finite state machine, the PTW performs the actual lookup and evaluation of the page table entry (PTE) based on the virtual address translation. The behavior and operations performed in this state are detailed as follows:

1. The state waits for a valid signal indicating that the data from the memory subsystem, specifically the page table entry, is available for processing.
2. Upon receiving the valid signal, the PTW proceeds with examining the retrieved page table entry to determine its properties and validity.
3. The state checks if the global mapping bit in the PTE is set, and if so, sets the global mapping signal to indicate that the translation applies globally across all address spaces.
4. The state distinguishes between two cases: Invalid PTE and Valid PTE.

   a. If the valid bit of the PTE is not set, or if the PTE has reserved RWX field encodings, it signifies an Invalid PTE. In such cases, the state transitions to the "PROPAGATE_ERROR" state, indicating a page-fault exception due to an invalid translation.

.. figure:: _static/ptw_pte_1.png
   :name: **Figure 22:** Invalid PTE and reserved RWX encoding leads to page fault
   :align: center
   :width: 70%
   :alt: ptw_pte_1

   **Figure 22:** Invalid PTE and reserved RWX encoding leads to page fault

.. _example1:

   b. If the PTE is valid, by default, the state advances to the "LATENCY" state, indicating a period of processing latency. Additionally, if the "read" flag (pte.r) or the "execute" flag (pte.x) is set, the PTE is considered valid.

5. Within the Valid PTE scenario, the ptw_stage is checked to decide the next state. When no Hypervisor Extension is used, the stage is always S_STAGE and has no impact on the progress of the table walk. However, when the Hypervisor Extension is used, if the stage is not the G_FINAL_STAGE, it has to continue advancing the different stages before proceeding with the translation (nested translation). The next diagram shows the evolution of ptw_stage through the nested translation process:

.. figure:: _static/nested_translation.png
   :name: **Figure 23:** Nested translation: ptw_stage
   :align: center
   :width: 90%
   :alt: ptw_stage

   **Figure 23:** Nested translation: ptw_stage

   In this case (valid PTE), the state machine goes back to WAIT_GRANT state. Afterwards, the state performs further checks based on whether the translation is intended for instruction fetching or data access:

   a. For instruction page table walk, if the page is not executable (pte.x is not set) or not marked as accessible (pte.a is not set), the state transitions to the "PROPAGATE_ERROR" state. Otherwise, the translation is valid. In case that the Hypervisor Extension is enabled, a valid translation requires being in the G_FINAL_STAGE, or the G stage being disabled.

.. figure:: _static/ptw_iptw.png
   :name: **Figure 24:** For Instruction Page Table Walk
   :align: center
   :width: 70%
   :alt: ptw_iptw

   **Figure 24:** For Instruction Page Table Walk

.. _example2:

   b. For data page table walk, the state checks if the page is readable (pte.r is set) or if the page is executable only but made readable by setting the MXR bit in xSTATUS CSR register. If either condition is met, it indicates a valid translation. If not, the state transitions to the "PROPAGATE_ERROR" state. When Hypervisor Extension is enabled, a valid translation also requires that it is in the G_FINAL_STAGE or the G stage is not enabled.

.. figure:: _static/ptw_dptw.png
   :name: **Figure 25:** Data Access Page Table Walk
   :width: 70%
   :alt: ptw_dptw

   **Figure 25:** Data Access Page Table Walk

.. _example3:

   c. If the access is intended for storing data, additional checks are performed: If the page is not writable (pte.w is not set) or if it is not marked as dirty (pte.d is not set), the state transitions to the "PROPAGATE_ERROR" state.

.. figure:: _static/ptw_dptw_s.png
   :name: **Figure 26:** Data Access Page Table Walk, Store requested
   :align: center
   :width: 70%
   :alt: ptw_dptw_s

   **Figure 26:** Data Access Page Table Walk, Store requested

6. The state also checks for potential misalignment issues in the translation: If the current page table level is the first level and if the PPN in PTE is not zero, it indicates a misaligned superpage, leading to a transition to the "PROPAGATE_ERROR" state.

.. figure:: _static/ptw_mis_sup.png
   :name: **Figure 27:** Misaligned Superpage Check
   :align: center
   :width: 70%
   :alt: ptw_mis_sup

   **Figure 27:** Misaligned Superpage Check

7. If the PTE is valid but the page is neither readable nor executable, the PTW recognizes the PTE as a pointer to the next level of the page table, indicating that additional translation information can be found in the referenced page table at a lower level.
8. If the current page table level is not the last level, the PTW proceeds to switch to the next level page table, updating the next level pointer and calculating the address for the next page table entry using the Physical Page Number from the PTE and the index from virtual address. Depending on the level and ptw_stage, the pptr is updated accordingly.
9. The state then transitions to the "WAIT_GRANT" state, indicating that the PTW is awaiting the grant signal to proceed with requesting the next level page table entry. If Hypervisor Extension is used and the page has already been accessed, is dirty or is accessible only in user mode, the state goes to PROPAGATE_ERROR.
10. If the current level is already the last level, an error is flagged, and the state transitions to the "PROPAGATE_ERROR" state, signifying an unexpected situation where the PTW is already at the last level page table.
11. If the translation access is found to be restricted by the Physical Memory Protection (PMP) settings (allow_access is false), the state updates the shared TLB update signal to indicate that the TLB entry should not be updated. Additionally, the saved address for the page table walk is restored to its previous value, and the state transitions to the "PROPAGATE_ACCESS_ERROR" state.
12. Lastly, if the data request for the page table entry was granted, the state indicates to the cache subsystem that the tag associated with the data is now valid.

.. figure:: _static/ptw_pte_flowchart.png
   :name: **28:** Flow Chart of PTE LOOKUP State
   :align: center
   :alt: ptw_pte_flowchart

   **Figure 28:** Flow Chart of PTE LOOKUP State

.. raw:: html

   <span style="font-size:18px; font-weight:bold;">PROPAGATE ERROR state</span>

This state indicates a detected error in the page table walk process, and an error signal is asserted to indicate the Page Table Walker's error condition, triggering a transition to the "LATENCY" state for error signal propagation.

.. raw:: html

   <span style="font-size:18px; font-weight:bold;">PROPAGATE ACCESS ERROR state</span>

This state indicates a detected access error in the page table walk process, and an access error signal is asserted to indicate the Page Table Walker's access error condition, triggering a transition to the "LATENCY" state for access error signal propagation.

.. raw:: html

   <span style="font-size:18px; font-weight:bold;">WAIT RVALID state</span>

This state waits until it gets the "read valid" signal, and when it does, it's ready to start a new page table walk.

.. raw:: html

   <span style="font-size:18px; font-weight:bold;">LATENCY state</span>

The LATENCY state introduces a latency period to allow for necessary system actions or signals to stabilize. After the latency period, the FSM transitions back to the IDLE state, indicating that the system is prepared for a new translation request.

.. raw:: html

   <span style="font-size:18px; font-weight:bold;">Flush Scenario</span>

The first step when a flush is triggered is to check whether the Page Table Entry (PTE) lookup process is currently in progress. If the PTW (Page Table Walker) module is indeed in the middle of a PTE lookup operation, the code then proceeds to evaluate a specific aspect of this operation.

* **Check for Data Validity (rvalid):** Within the PTE lookup operation, it's important to ensure that the data being used for the translation is valid. In other words, the code checks whether the "rvalid" signal (which likely indicates the validity of the data) is not active. If the data is not yet valid, it implies that the PTW module is waiting for the data to become valid before completing the lookup. In such a case, the code takes appropriate action to wait for the data to become valid before proceeding further.

* **Check for Waiting on Grant:** The second condition the code checks for during a flush scenario is whether the PTW module is currently waiting for a "grant." This "grant" signal is typically used to indicate permission or authorization to proceed with an operation. If the PTW module is indeed in a state of waiting for this grant signal, it implies that it requires authorization before continuing its task.

   * **Waiting for Grant:** If the PTW module is in a state of waiting for the grant signal, the code ensures that it continues to wait for the grant signal to be asserted before proceeding further.

* **Return to Idle State if Neither Condition is Met:** After evaluating the above two conditions, the code determines whether either of these conditions is true. If neither of these conditions applies, it suggests that the PTW module can return to its idle state, indicating that it can continue normal operations without any dependencies on the flush condition.

