REGISTERS CSR CV32A6
===================

Machine Status Register 
--------------------------
AddressOffset: 'h300 
--------------------------
Description:
--------------------------
The ``mstatus`` register keeps track of and controls the hart’s current operating state.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31 
     - SD
     - State dirty
     - read-only,WARL
     - The SD bit is a read\-only bit\.``Legal Values``:0\.  ``Enumerated Values``( "Not_Dirty" :0)( "Dirty" :1)'\n'
   * - 22 
     - TSR
     - Trap sret
     - read-write,WARL
     - The TSR bit supports intercepting the supervisor exception return instruction, SRET\.  ``Enumerated Values``( "Permitted" :0)( "Not_Permitted" :1)'\n'
   * - 21 
     - TW
     - Timeout wait
     - read-write,WARL
     - The TW bit supports intercepting the WFI instruction\.  ``Enumerated Values``( "Permitted" :0)( "Not_Permitted" :1)'\n'
   * - 20 
     - TVM
     - Trap virtual memory
     - read-write,WARL
     - The TVM bit supports intercepting supervisor virtual\-memory management operations\.  ``Enumerated Values``( "Permitted" :0)( "Not_Permitted" :1)'\n'
   * - 19 
     - MXR
     - Make executable readable
     - read-write
     - The MXR bit modifies the privilege with which loads access virtual memory\.  ``Enumerated Values``( "Not_Executable" :0)( "Executable" :1)'\n'
   * - 18 
     - SUM
     - Supervisor user memory
     - read-write
     - The SUM bit modifies the privilege with which S\-mode loads and stores access virtual memory\.  ``Enumerated Values``( "Not_Permitted" :0)( "Permitted" :1)'\n'
   * - 17 
     - MPRV
     - Modify privilege
     - read-write
     - The MPRV bit modifies the privilege mode at which loads and stores execute\.  ``Enumerated Values``( "Normal" :0)( "Protected" :1)'\n'
   * - 16:15
     - XS
     - Extension state
     - read-only,WARL
     - The XS field encodes the status of the additional user\-mode extensions and associated state\.``Legal Values``:0\.  ``Enumerated Values``( "Off" :0)( "Initial" :1)( "Clean" :2)( "Dirty" :3)'\n'
   * - 14:13
     - FS
     - Floating-point unit state
     - read-only,WARL
     - FS extension is not supported\.``Legal Values``:0\.  ``Enumerated Values``( "Off" :0)( "Initial" :1)( "Clean" :2)( "Dirty" :3)'\n'
   * - 12:11
     - MPP
     - Machine mode prior privilege
     - read-write
     - Holds the previous privilege mode for machine mode\.  ``Enumerated Values``( "U-mode" :0)( "S-mode" :1)( "Reserved" :2)( "M-mode" :3)'\n'
   * - 10:9
     - VS
     - Vector extension state
     - read-only,WARL
     - V extension is not supported\.``Legal Values``:0\.
   * - 8 
     - SPP
     - Supervisor mode prior privilege
     - read-write
     - Holds the previous privilege mode for supervisor mode\.  ``Enumerated Values``( "U-mode" :0)( "Otherwise" :1)'\n'
   * - 7 
     - MPIE
     - Machine mode prior interrupt enable
     - read-write
     - Indicates whether machine interrupts were enabled prior to trapping into machine mode\.  ``Enumerated Values``( "Disabled" :0)( "Enabled" :1)'\n'
   * - 6 
     - UBE
     - User mode bit endianness
     - read-write,WARL
     - UBE controls whether explicit load and store memory accesses made from U\-mode are little\-endian or big\-endian\.``Legal Values``:0\.  ``Enumerated Values``( "Little-endian" :0)( "Big-endian" :1)'\n'
   * - 5 
     - SPIE
     - Supervisor mode prior interrupt enable
     - read-write
     - Indicates whether supervisor interrupts were enabled prior to trapping into supervisor mode\.  ``Enumerated Values``( "Disabled" :0)( "Enabled" :1)'\n'
   * - 3 
     - MIE
     - Machine mode interrupt enable
     - read-write
     - Global interrupt\-enable bit for Machine mode\.  ``Enumerated Values``( "Disabled" :0)( "Enabled" :1)'\n'
   * - 1 
     - SIE
     - Supervisor mode interrupt enable
     - read-write
     - Global interrupt\-enable bit for Supervisor mode\.  ``Enumerated Values``( "Disabled" :0)( "Enabled" :1)'\n'

Machine ISA Register 
--------------------------
AddressOffset: 'h301 
--------------------------
Description:
--------------------------
The misa CSR is reporting the ISA supported by the hart.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:30
     - MXL
     - Machine xlen
     - read-write,WARL
     - The MXL field encodes the native base integer ISA width\.``Legal Values``:1\.  ``Enumerated Values``( "XLEN_32" :1)( "XLEN_64" :2)( "XLEN_128" :3)'\n'
   * - 25:0
     - Extensions
     - Extensions
     - read-write,WARL
     - The Extensions field encodes the presence of the standard extensions, with a single bit per letter of the alphabet\.``Legal Values``:0x141104\.  ``Enumerated Values``( "A" :1)( "B" :2)( "C" :4)( "D" :8)( "E" :16)( "F" :32)( "G" :64)( "H" :128)( "I" :256)( "J" :512)( "K" :1024)( "L" :2048)( "M" :4096)( "N" :8192)( "O" :16384)( "P" :32768)( "Q" :65536)( "R" :131072)( "S" :262144)( "T" :524288)( "U" :1048576)( "V" :2097152)( "W" :4194304)( "X" :8388608)( "Y" :16777216)( "Z" :33554432)'\n'

Machine Interrupt Enable Register 
--------------------------
AddressOffset: 'h304 
--------------------------
Description:
--------------------------
This register contains machine interrupt enable bits.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 11 
     - MEIE
     - M-mode external interrupt enable
     - read-write,WARL
     - Enables machine mode external interrupts\.
   * - 9 
     - SEIE
     - S-mode external interrupt enable
     - read-write,WARL
     - Enables supervisor mode external interrupts\.
   * - 8 
     - UEIE
     - 
     - read-write,WARL
     - enables U\-mode external interrupts\.``Legal Values:``0\.
   * - 7 
     - MTIE
     - M-mode timer interrupt enable
     - read-write,WARL
     - Enables machine mode timer interrupts\.
   * - 5 
     - STIE
     - S-mode timer interrupt enable
     - read-write,WARL
     - Enables supervisor mode timer interrupts\.
   * - 4 
     - UTIE
     - 
     - read-write,WARL
     - timer interrupt\-enable bit for U\-mode\.``Legal Values:``0\.
   * - 3 
     - MSIE
     - M-mode software interrupt enable
     - read-write
     - Enables machine mode software interrupts\.
   * - 1 
     - SSIE
     - S-mode software interrupt enable
     - read-write,WARL
     - Enables supervisor mode software interrupts\.
   * - 0 
     - USIE
     - 
     - read-write,WARL
     - enable U\-mode software interrupts\.``Legal Values:``0\.

Machine Trap Vector Register 
--------------------------
AddressOffset: 'h305 
--------------------------
Description:
--------------------------
This register holds trap vector configuration, consisting of a vector base address and a vector mode.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:2
     - BASE
     - 
     - read-write,WARL
     - The BASE field in mtvec is a WARL field that can hold any valid virtual or physical address, subject to the following alignment constraints: when MODE=Direct the address must be 4\-byte aligned, and when MODE=Vectored the address must be 256\-byte aligned\.
   * - 1:0
     - MODE
     - 
     - read-write,WARL
     - Imposes additional alignment constraints on the value in the BASE field\.``Legal Values :``0,1\.  ``Enumerated Values``( "Direct" :0)( "Vectored" :1)( "Reserved_2" :2)( "Reserved_3" :3)'\n'

Upper 32-bits of Machine Status Register 
--------------------------
AddressOffset: 'h310 
--------------------------
Description:
--------------------------
The ``mstatush`` is the upper 32-bits of Machine status only for RV32.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 4 
     - SBE
     - Supervisor mode bit endianess
     - read-write,WARL
     - SBE controls whether explicit load and store memory accesses made from S\-mode are little\-endian or big\-endian\.``Legal Values``:0\.  ``Enumerated Values``( "Little-endian" :0)( "Big-endian" :1)'\n'
   * - 5 
     - MBE
     - Machine mode bit endianess
     - read-write,WARL
     - MBE controls whether explicit load and store memory accesses made from M\-mode are little\-endian or big\-endian\.``Legal Values``:0\.  ``Enumerated Values``( "Little-endian" :0)( "Big-endian" :1)'\n'

Machine Hardware Performance-Monitoring Event Selector Register 
--------------------------
AddressOffset: 'h323 
--------------------------
Description:
--------------------------
This register controls which event causes the corresponding counter to increment.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - mhpmevent
     - 
     - WARL
     - This register controls which event causes the corresponding counter to increment\.

Machine Hardware Performance-Monitoring Event Selector Register 
--------------------------
AddressOffset: 'h324 
--------------------------
Description:
--------------------------
This register controls which event causes the corresponding counter to increment.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - mhpmevent
     - 
     - WARL
     - This register controls which event causes the corresponding counter to increment\.

Machine Hardware Performance-Monitoring Event Selector Register 
--------------------------
AddressOffset: 'h325 
--------------------------
Description:
--------------------------
This register controls which event causes the corresponding counter to increment.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - mhpmevent
     - 
     - WARL
     - This register controls which event causes the corresponding counter to increment\.

Machine Hardware Performance-Monitoring Event Selector Register 
--------------------------
AddressOffset: 'h326 
--------------------------
Description:
--------------------------
This register controls which event causes the corresponding counter to increment.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - mhpmevent
     - 
     - WARL
     - This register controls which event causes the corresponding counter to increment\.

Machine Hardware Performance-Monitoring Event Selector Register 
--------------------------
AddressOffset: 'h327 
--------------------------
Description:
--------------------------
This register controls which event causes the corresponding counter to increment.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - mhpmevent
     - 
     - WARL
     - This register controls which event causes the corresponding counter to increment\.

Machine Hardware Performance-Monitoring Event Selector Register 
--------------------------
AddressOffset: 'h328 
--------------------------
Description:
--------------------------
This register controls which event causes the corresponding counter to increment.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - mhpmevent
     - 
     - WARL
     - This register controls which event causes the corresponding counter to increment\.

Machine Hardware Performance-Monitoring Event Selector Register 
--------------------------
AddressOffset: 'h329 
--------------------------
Description:
--------------------------
This register controls which event causes the corresponding counter to increment.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - mhpmevent
     - 
     - WARL
     - This register controls which event causes the corresponding counter to increment\.

Machine Hardware Performance-Monitoring Event Selector Register 
--------------------------
AddressOffset: 'h32a 
--------------------------
Description:
--------------------------
This register controls which event causes the corresponding counter to increment.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - mhpmevent
     - 
     - WARL
     - This register controls which event causes the corresponding counter to increment\.

Machine Hardware Performance-Monitoring Event Selector Register 
--------------------------
AddressOffset: 'h32b 
--------------------------
Description:
--------------------------
This register controls which event causes the corresponding counter to increment.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - mhpmevent
     - 
     - WARL
     - This register controls which event causes the corresponding counter to increment\.

Machine Hardware Performance-Monitoring Event Selector Register 
--------------------------
AddressOffset: 'h32c 
--------------------------
Description:
--------------------------
This register controls which event causes the corresponding counter to increment.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - mhpmevent
     - 
     - WARL
     - This register controls which event causes the corresponding counter to increment\.

Machine Hardware Performance-Monitoring Event Selector Register 
--------------------------
AddressOffset: 'h32d 
--------------------------
Description:
--------------------------
This register controls which event causes the corresponding counter to increment.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - mhpmevent
     - 
     - WARL
     - This register controls which event causes the corresponding counter to increment\.

Machine Hardware Performance-Monitoring Event Selector Register 
--------------------------
AddressOffset: 'h32e 
--------------------------
Description:
--------------------------
This register controls which event causes the corresponding counter to increment.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - mhpmevent
     - 
     - WARL
     - This register controls which event causes the corresponding counter to increment\.

Machine Hardware Performance-Monitoring Event Selector Register 
--------------------------
AddressOffset: 'h32f 
--------------------------
Description:
--------------------------
This register controls which event causes the corresponding counter to increment.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - mhpmevent
     - 
     - WARL
     - This register controls which event causes the corresponding counter to increment\.

Machine Hardware Performance-Monitoring Event Selector Register 
--------------------------
AddressOffset: 'h330 
--------------------------
Description:
--------------------------
This register controls which event causes the corresponding counter to increment.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - mhpmevent
     - 
     - WARL
     - This register controls which event causes the corresponding counter to increment\.

Machine Hardware Performance-Monitoring Event Selector Register 
--------------------------
AddressOffset: 'h331 
--------------------------
Description:
--------------------------
This register controls which event causes the corresponding counter to increment.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - mhpmevent
     - 
     - WARL
     - This register controls which event causes the corresponding counter to increment\.

Machine Hardware Performance-Monitoring Event Selector Register 
--------------------------
AddressOffset: 'h332 
--------------------------
Description:
--------------------------
This register controls which event causes the corresponding counter to increment.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - mhpmevent
     - 
     - WARL
     - This register controls which event causes the corresponding counter to increment\.

Machine Hardware Performance-Monitoring Event Selector Register 
--------------------------
AddressOffset: 'h333 
--------------------------
Description:
--------------------------
This register controls which event causes the corresponding counter to increment.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - mhpmevent
     - 
     - WARL
     - This register controls which event causes the corresponding counter to increment\.

Machine Hardware Performance-Monitoring Event Selector Register 
--------------------------
AddressOffset: 'h334 
--------------------------
Description:
--------------------------
This register controls which event causes the corresponding counter to increment.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - mhpmevent
     - 
     - WARL
     - This register controls which event causes the corresponding counter to increment\.

Machine Hardware Performance-Monitoring Event Selector Register 
--------------------------
AddressOffset: 'h335 
--------------------------
Description:
--------------------------
This register controls which event causes the corresponding counter to increment.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - mhpmevent
     - 
     - WARL
     - This register controls which event causes the corresponding counter to increment\.

Machine Hardware Performance-Monitoring Event Selector Register 
--------------------------
AddressOffset: 'h336 
--------------------------
Description:
--------------------------
This register controls which event causes the corresponding counter to increment.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - mhpmevent
     - 
     - WARL
     - This register controls which event causes the corresponding counter to increment\.

Machine Hardware Performance-Monitoring Event Selector Register 
--------------------------
AddressOffset: 'h337 
--------------------------
Description:
--------------------------
This register controls which event causes the corresponding counter to increment.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - mhpmevent
     - 
     - WARL
     - This register controls which event causes the corresponding counter to increment\.

Machine Hardware Performance-Monitoring Event Selector Register 
--------------------------
AddressOffset: 'h338 
--------------------------
Description:
--------------------------
This register controls which event causes the corresponding counter to increment.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - mhpmevent
     - 
     - WARL
     - This register controls which event causes the corresponding counter to increment\.

Machine Hardware Performance-Monitoring Event Selector Register 
--------------------------
AddressOffset: 'h339 
--------------------------
Description:
--------------------------
This register controls which event causes the corresponding counter to increment.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - mhpmevent
     - 
     - WARL
     - This register controls which event causes the corresponding counter to increment\.

Machine Hardware Performance-Monitoring Event Selector Register 
--------------------------
AddressOffset: 'h33a 
--------------------------
Description:
--------------------------
This register controls which event causes the corresponding counter to increment.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - mhpmevent
     - 
     - WARL
     - This register controls which event causes the corresponding counter to increment\.

Machine Hardware Performance-Monitoring Event Selector Register 
--------------------------
AddressOffset: 'h33b 
--------------------------
Description:
--------------------------
This register controls which event causes the corresponding counter to increment.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - mhpmevent
     - 
     - WARL
     - This register controls which event causes the corresponding counter to increment\.

Machine Hardware Performance-Monitoring Event Selector Register 
--------------------------
AddressOffset: 'h33c 
--------------------------
Description:
--------------------------
This register controls which event causes the corresponding counter to increment.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - mhpmevent
     - 
     - WARL
     - This register controls which event causes the corresponding counter to increment\.

Machine Hardware Performance-Monitoring Event Selector Register 
--------------------------
AddressOffset: 'h33d 
--------------------------
Description:
--------------------------
This register controls which event causes the corresponding counter to increment.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - mhpmevent
     - 
     - WARL
     - This register controls which event causes the corresponding counter to increment\.

Machine Hardware Performance-Monitoring Event Selector Register 
--------------------------
AddressOffset: 'h33e 
--------------------------
Description:
--------------------------
This register controls which event causes the corresponding counter to increment.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - mhpmevent
     - 
     - WARL
     - This register controls which event causes the corresponding counter to increment\.

Machine Hardware Performance-Monitoring Event Selector Register 
--------------------------
AddressOffset: 'h33f 
--------------------------
Description:
--------------------------
This register controls which event causes the corresponding counter to increment.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - mhpmevent
     - 
     - WARL
     - This register controls which event causes the corresponding counter to increment\.

Machine Scratch Register 
--------------------------
AddressOffset: 'h340 
--------------------------
Description:
--------------------------
This register is used to hold a value dedicated to Machine mode. Attempts to access without Machine mode level raise illegal instruction exception.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - mscratch
     - Machine scratch
     - read-write
     - This register is used to hold a value dedicated to Machine mode\. Attempts to access without Machine mode level raise illegal instruction exception\.

Machine Exception Program Counter Register 
--------------------------
AddressOffset: 'h341 
--------------------------
Description:
--------------------------
This register must be able to hold all valid virtual addresses.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - mepc
     - Machine exception program counter
     - read-write,WARL
     - This register must be able to hold all valid virtual addresses\.

Machine Cause Register 
--------------------------
AddressOffset: 'h342 
--------------------------
Description:
--------------------------
When a trap is taken into M-mode, mcause is written with a code indicating the event that caused the trap.
Machine cause register (``mcause``) values after trap are shown in the following table.

.. list-table::
    :widths: 20 20 20
    :header-rows: 1

    * - **Interrupt**
      - **Exception Code**
      - **Description**
    * - 1
      - 0
      - *Reserved*
    * - 1
      - 1
      - Supervisor software interrupt
    * - 1
      - 2-4
      - *Reserved*
    * - 1
      - 5
      - Supervisor timer interrupt
    * - 1
      - 6-8
      - *Reserved*
    * - 1
      - 9
      - Supervisor external interrupt
    * - 1
      - 10-15
      - *Reserved*
    * - 1
      - >=16
      - *Designated for platform use*
    * - 0
      - 0
      - Instruction address misaligned
    * - 0
      - 1
      - Instruction access fault
    * - 0
      - 2
      - Illegal instruction
    * - 0
      - 3
      - Breakpoint
    * - 0
      - 4
      - Load address misaligned
    * - 0
      - 5
      - Load access fault
    * - 0
      - 6
      - Store/AMO address misaligned
    * - 0
      - 7
      - Store/AMO access fault
    * - 0
      - 8
      - Environment call from U-mode
    * - 0
      - 9
      - Environment call from S-mode
    * - 0
      - 10-11
      - *Reserved*
    * - 0
      - 12
      - Instruction page fault
    * - 0
      - 13
      - Load page fault
    * - 0
      - 14
      - *Reserved*
    * - 0
      - 15
      - Store/AMO page fault
    * - 0
      - 16-23
      - *Reserved*
    * - 0
      - 24-31
      - *Designated for custom use*
    * - 0
      - 32-47
      - *Reserved*
    * - 0
      - 48-63
      - *Designated for custom use*
    * - 0
      - >=64
      - *Reserved*
    

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31 
     - Interrupt
     - Interrupt
     - read-write
     - This bit is set if the trap was caused by an interrupt\.
   * - 30:0
     - exception_code
     - Exception code
     - read-write,WLRL
     - This field contains a code identifying the last exception or interrupt\.

Machine Trap Value Register 
--------------------------
AddressOffset: 'h343 
--------------------------
Description:
--------------------------
When a trap is taken into M-mode, mtval is either set to zero or written with exception-specific information to assist software in handling the trap.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - mtval
     - Machine trap value
     - read-write,WARL
     - When a trap is taken into M\-mode, mtval is either set to zero or written with exception\-specific information to assist software in handling the trap\.

Machine Interrupt Pending Register 
--------------------------
AddressOffset: 'h344 
--------------------------
Description:
--------------------------
This register contains machine interrupt pending bits.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 11 
     - MEIP
     - M-mode external interrupt pending
     - read-only
     - The interrupt\-pending bit for machine\-level external interrupts\.
   * - 9 
     - SEIP
     - S-mode external interrupt pending
     - read-write
     - The interrupt\-pending bit for supervisor\-level external interrupts\.
   * - 8 
     - UEIP
     - 
     - read-write
     - enables external interrupts\.``Legal Values:``0\.
   * - 7 
     - MTIP
     - M-mode timer interrupt pending
     - read-only
     - The interrupt\-pending bit for machine\-level timer interrupts\.
   * - 5 
     - STIP
     - S-mode timer interrupt pending
     - read-write
     - The interrupt\-pending bit for supervisor\-level timer interrupts\.
   * - 4 
     - UTIP
     - 
     - read-write
     - Correspond to timer interrupt\-pending bits for user interrupt\.``Legal Values:``0\.
   * - 3 
     - MSIP
     - M-mode software interrupt pending
     - read-only
     - The interrupt\-pending bit for machine\-level software interrupts\.
   * - 1 
     - SSIP
     - S-mode software interrupt pending
     - read-write
     - The interrupt\-pending bit for supervisor\-level software interrupts\.
   * - 0 
     - USIP
     - 
     - read-write
     - A hart to directly write its own USIP bits when running in the appropriate mode\.``Legal Values:``0\.

Physical Memory Protection Config 0 Register 
--------------------------
AddressOffset: 'h3a0 
--------------------------
Description:
--------------------------
Holds configuration 0-3.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:24
     - pmp3cfg
     - Physical memory protection 3 config
     - read-write
     - Holds the configuration\.
   * - 23:16
     - pmp2cfg
     - Physical memory protection 2 config
     - read-write
     - Holds the configuration\.
   * - 15:8
     - pmp1cfg
     - Physical memory protection 1 config
     - read-write
     - Holds the configuration\.
   * - 7:0
     - pmp0cfg
     - Physical memory protection 0 config
     - read-write
     - Holds the configuration\.

Physical Memory Protection Config 1 Register 
--------------------------
AddressOffset: 'h3a1 
--------------------------
Description:
--------------------------
Holds configuration 4-7.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:24
     - pmp7cfg
     - Physical memory protection 7 config
     - read-write
     - Holds the configuration\.
   * - 23:16
     - pmp6cfg
     - Physical memory protection 6 config
     - read-write
     - Holds the configuration\.
   * - 15:8
     - pmp5cfg
     - Physical memory protection 5 config
     - read-write
     - Holds the configuration\.
   * - 7:0
     - pmp4cfg
     - Physical memory protection 4 config
     - read-write
     - Holds the configuration\.

Physical Memory Protection Config 2 Register 
--------------------------
AddressOffset: 'h3a2 
--------------------------
Description:
--------------------------
Holds configuration 8-11.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:24
     - pmp11cfg
     - Physical memory protection 11 config
     - read-write
     - Holds the configuration\.
   * - 23:16
     - pmp10cfg
     - Physical memory protection 10 config
     - read-write
     - Holds the configuration\.
   * - 15:8
     - pmp9cfg
     - Physical memory protection 9 config
     - read-write
     - Holds the configuration\.
   * - 7:0
     - pmp8cfg
     - Physical memory protection 8 config
     - read-write
     - Holds the configuration\.

Physical Memory Protection Config 3 Register 
--------------------------
AddressOffset: 'h3a3 
--------------------------
Description:
--------------------------
Holds configuration 12-15.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:24
     - pmp15cfg
     - Physical memory protection 15 config
     - read-write
     - Holds the configuration\.
   * - 23:16
     - pmp14cfg
     - Physical memory protection 14 config
     - read-write
     - Holds the configuration\.
   * - 15:8
     - pmp13cfg
     - Physical memory protection 13 config
     - read-write
     - Holds the configuration\.
   * - 7:0
     - pmp12cfg
     - Physical memory protection 12 config
     - read-write
     - Holds the configuration\.

Physical Memory Protection Address Register 
--------------------------
AddressOffset: 'h3b0 
--------------------------
Description:
--------------------------
Address register for Physical Memory Protection.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - address
     - Address
     - read-write,WARL
     - Address register for Physical Memory Protection\.

Physical Memory Protection Address Register 
--------------------------
AddressOffset: 'h3b1 
--------------------------
Description:
--------------------------
Address register for Physical Memory Protection.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - address
     - Address
     - read-write,WARL
     - Address register for Physical Memory Protection\.

Physical Memory Protection Address Register 
--------------------------
AddressOffset: 'h3b2 
--------------------------
Description:
--------------------------
Address register for Physical Memory Protection.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - address
     - Address
     - read-write,WARL
     - Address register for Physical Memory Protection\.

Physical Memory Protection Address Register 
--------------------------
AddressOffset: 'h3b3 
--------------------------
Description:
--------------------------
Address register for Physical Memory Protection.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - address
     - Address
     - read-write,WARL
     - Address register for Physical Memory Protection\.

Physical Memory Protection Address Register 
--------------------------
AddressOffset: 'h3b4 
--------------------------
Description:
--------------------------
Address register for Physical Memory Protection.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - address
     - Address
     - read-write,WARL
     - Address register for Physical Memory Protection\.

Physical Memory Protection Address Register 
--------------------------
AddressOffset: 'h3b5 
--------------------------
Description:
--------------------------
Address register for Physical Memory Protection.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - address
     - Address
     - read-write,WARL
     - Address register for Physical Memory Protection\.

Physical Memory Protection Address Register 
--------------------------
AddressOffset: 'h3b6 
--------------------------
Description:
--------------------------
Address register for Physical Memory Protection.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - address
     - Address
     - read-write,WARL
     - Address register for Physical Memory Protection\.

Physical Memory Protection Address Register 
--------------------------
AddressOffset: 'h3b7 
--------------------------
Description:
--------------------------
Address register for Physical Memory Protection.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - address
     - Address
     - read-write,WARL
     - Address register for Physical Memory Protection\.

Physical Memory Protection Address Register 
--------------------------
AddressOffset: 'h3b8 
--------------------------
Description:
--------------------------
Address register for Physical Memory Protection.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - address
     - Address
     - read-write,WARL
     - Address register for Physical Memory Protection\.

Physical Memory Protection Address Register 
--------------------------
AddressOffset: 'h3b9 
--------------------------
Description:
--------------------------
Address register for Physical Memory Protection.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - address
     - Address
     - read-write,WARL
     - Address register for Physical Memory Protection\.

Physical Memory Protection Address Register 
--------------------------
AddressOffset: 'h3ba 
--------------------------
Description:
--------------------------
Address register for Physical Memory Protection.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - address
     - Address
     - read-write,WARL
     - Address register for Physical Memory Protection\.

Physical Memory Protection Address Register 
--------------------------
AddressOffset: 'h3bb 
--------------------------
Description:
--------------------------
Address register for Physical Memory Protection.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - address
     - Address
     - read-write,WARL
     - Address register for Physical Memory Protection\.

Physical Memory Protection Address Register 
--------------------------
AddressOffset: 'h3bc 
--------------------------
Description:
--------------------------
Address register for Physical Memory Protection.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - address
     - Address
     - read-write,WARL
     - Address register for Physical Memory Protection\.

Physical Memory Protection Address Register 
--------------------------
AddressOffset: 'h3bd 
--------------------------
Description:
--------------------------
Address register for Physical Memory Protection.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - address
     - Address
     - read-write,WARL
     - Address register for Physical Memory Protection\.

Physical Memory Protection Address Register 
--------------------------
AddressOffset: 'h3be 
--------------------------
Description:
--------------------------
Address register for Physical Memory Protection.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - address
     - Address
     - read-write,WARL
     - Address register for Physical Memory Protection\.

Physical Memory Protection Address Register 
--------------------------
AddressOffset: 'h3bf 
--------------------------
Description:
--------------------------
Address register for Physical Memory Protection.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - address
     - Address
     - read-write,WARL
     - Address register for Physical Memory Protection\.

Instruction Cache Register 
--------------------------
AddressOffset: 'h7C0 
--------------------------
Description:
--------------------------
Custom Register to enable/disable for Icache [bit 0]

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 0 
     - icache
     - Instruction cache
     - read-write
     - Custom Register to enable/disable for Icache \[bit 0\]

M-mode Cycle counter Register 
--------------------------
AddressOffset: 'hB00 
--------------------------
Description:
--------------------------
Counts the number of clock cycles executed by the processor core on which the hart is running.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - count
     - Count
     - read-write
     - Counts the number of clock cycles executed by the processor core on which the hart is running\.

Machine Instruction Retired counter Register 
--------------------------
AddressOffset: 'hB02 
--------------------------
Description:
--------------------------
Counts the number of instructions the hart has retired.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - count
     - Count
     - read-write
     - Counts the number of instructions the hart has retired\.

Upper 32-bits of M-mode Cycle counter Register 
--------------------------
AddressOffset: 'hB80 
--------------------------
Description:
--------------------------
Counts the number of clock cycles executed by the processor core on which the hart is running.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - count
     - Count
     - read-write
     - Counts the number of clock cycles executed by the processor core on which the hart is running\.

Upper 32-bits of Machine Instruction Retired counter Register 
--------------------------
AddressOffset: 'hB82 
--------------------------
Description:
--------------------------
Counts the number of instructions the hart has retired.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - count
     - Count
     - read-write
     - Counts the number of instructions the hart has retired\.

Machine Hardware Performance Monitoring Counter Register 
--------------------------
AddressOffset: 'hb03 
--------------------------
Description:
--------------------------
Hardware performance event counter.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - count
     - Count
     - WARL
     - Hardware performance event counter\.

Machine Hardware Performance Monitoring Counter Register 
--------------------------
AddressOffset: 'hb04 
--------------------------
Description:
--------------------------
Hardware performance event counter.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - count
     - Count
     - WARL
     - Hardware performance event counter\.

Machine Hardware Performance Monitoring Counter Register 
--------------------------
AddressOffset: 'hb05 
--------------------------
Description:
--------------------------
Hardware performance event counter.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - count
     - Count
     - WARL
     - Hardware performance event counter\.

Machine Hardware Performance Monitoring Counter Register 
--------------------------
AddressOffset: 'hb06 
--------------------------
Description:
--------------------------
Hardware performance event counter.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - count
     - Count
     - WARL
     - Hardware performance event counter\.

Machine Hardware Performance Monitoring Counter Register 
--------------------------
AddressOffset: 'hb07 
--------------------------
Description:
--------------------------
Hardware performance event counter.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - count
     - Count
     - WARL
     - Hardware performance event counter\.

Machine Hardware Performance Monitoring Counter Register 
--------------------------
AddressOffset: 'hb08 
--------------------------
Description:
--------------------------
Hardware performance event counter.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - count
     - Count
     - WARL
     - Hardware performance event counter\.

Machine Hardware Performance Monitoring Counter Register 
--------------------------
AddressOffset: 'hb09 
--------------------------
Description:
--------------------------
Hardware performance event counter.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - count
     - Count
     - WARL
     - Hardware performance event counter\.

Machine Hardware Performance Monitoring Counter Register 
--------------------------
AddressOffset: 'hb0a 
--------------------------
Description:
--------------------------
Hardware performance event counter.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - count
     - Count
     - WARL
     - Hardware performance event counter\.

Machine Hardware Performance Monitoring Counter Register 
--------------------------
AddressOffset: 'hb0b 
--------------------------
Description:
--------------------------
Hardware performance event counter.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - count
     - Count
     - WARL
     - Hardware performance event counter\.

Machine Hardware Performance Monitoring Counter Register 
--------------------------
AddressOffset: 'hb0c 
--------------------------
Description:
--------------------------
Hardware performance event counter.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - count
     - Count
     - WARL
     - Hardware performance event counter\.

Machine Hardware Performance Monitoring Counter Register 
--------------------------
AddressOffset: 'hb0d 
--------------------------
Description:
--------------------------
Hardware performance event counter.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - count
     - Count
     - WARL
     - Hardware performance event counter\.

Machine Hardware Performance Monitoring Counter Register 
--------------------------
AddressOffset: 'hb0e 
--------------------------
Description:
--------------------------
Hardware performance event counter.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - count
     - Count
     - WARL
     - Hardware performance event counter\.

Machine Hardware Performance Monitoring Counter Register 
--------------------------
AddressOffset: 'hb0f 
--------------------------
Description:
--------------------------
Hardware performance event counter.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - count
     - Count
     - WARL
     - Hardware performance event counter\.

Machine Hardware Performance Monitoring Counter Register 
--------------------------
AddressOffset: 'hb10 
--------------------------
Description:
--------------------------
Hardware performance event counter.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - count
     - Count
     - WARL
     - Hardware performance event counter\.

Machine Hardware Performance Monitoring Counter Register 
--------------------------
AddressOffset: 'hb11 
--------------------------
Description:
--------------------------
Hardware performance event counter.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - count
     - Count
     - WARL
     - Hardware performance event counter\.

Machine Hardware Performance Monitoring Counter Register 
--------------------------
AddressOffset: 'hb12 
--------------------------
Description:
--------------------------
Hardware performance event counter.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - count
     - Count
     - WARL
     - Hardware performance event counter\.

Machine Hardware Performance Monitoring Counter Register 
--------------------------
AddressOffset: 'hb13 
--------------------------
Description:
--------------------------
Hardware performance event counter.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - count
     - Count
     - WARL
     - Hardware performance event counter\.

Machine Hardware Performance Monitoring Counter Register 
--------------------------
AddressOffset: 'hb14 
--------------------------
Description:
--------------------------
Hardware performance event counter.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - count
     - Count
     - WARL
     - Hardware performance event counter\.

Machine Hardware Performance Monitoring Counter Register 
--------------------------
AddressOffset: 'hb15 
--------------------------
Description:
--------------------------
Hardware performance event counter.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - count
     - Count
     - WARL
     - Hardware performance event counter\.

Machine Hardware Performance Monitoring Counter Register 
--------------------------
AddressOffset: 'hb16 
--------------------------
Description:
--------------------------
Hardware performance event counter.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - count
     - Count
     - WARL
     - Hardware performance event counter\.

Machine Hardware Performance Monitoring Counter Register 
--------------------------
AddressOffset: 'hb17 
--------------------------
Description:
--------------------------
Hardware performance event counter.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - count
     - Count
     - WARL
     - Hardware performance event counter\.

Machine Hardware Performance Monitoring Counter Register 
--------------------------
AddressOffset: 'hb18 
--------------------------
Description:
--------------------------
Hardware performance event counter.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - count
     - Count
     - WARL
     - Hardware performance event counter\.

Machine Hardware Performance Monitoring Counter Register 
--------------------------
AddressOffset: 'hb19 
--------------------------
Description:
--------------------------
Hardware performance event counter.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - count
     - Count
     - WARL
     - Hardware performance event counter\.

Machine Hardware Performance Monitoring Counter Register 
--------------------------
AddressOffset: 'hb1a 
--------------------------
Description:
--------------------------
Hardware performance event counter.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - count
     - Count
     - WARL
     - Hardware performance event counter\.

Machine Hardware Performance Monitoring Counter Register 
--------------------------
AddressOffset: 'hb1b 
--------------------------
Description:
--------------------------
Hardware performance event counter.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - count
     - Count
     - WARL
     - Hardware performance event counter\.

Machine Hardware Performance Monitoring Counter Register 
--------------------------
AddressOffset: 'hb1c 
--------------------------
Description:
--------------------------
Hardware performance event counter.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - count
     - Count
     - WARL
     - Hardware performance event counter\.

Machine Hardware Performance Monitoring Counter Register 
--------------------------
AddressOffset: 'hb1d 
--------------------------
Description:
--------------------------
Hardware performance event counter.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - count
     - Count
     - WARL
     - Hardware performance event counter\.

Machine Hardware Performance Monitoring Counter Register 
--------------------------
AddressOffset: 'hb1e 
--------------------------
Description:
--------------------------
Hardware performance event counter.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - count
     - Count
     - WARL
     - Hardware performance event counter\.

Machine Hardware Performance Monitoring Counter Register 
--------------------------
AddressOffset: 'hb1f 
--------------------------
Description:
--------------------------
Hardware performance event counter.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - count
     - Count
     - WARL
     - Hardware performance event counter\.

Upper 32 bits of Machine Hardware Performance Monitoring Counter Register 
--------------------------
AddressOffset: 'hb83 
--------------------------
Description:
--------------------------
Hardware performance event counter only for RV32.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - count
     - Count
     - WARL
     - Hardware performance event counter only for RV32\.

Upper 32 bits of Machine Hardware Performance Monitoring Counter Register 
--------------------------
AddressOffset: 'hb84 
--------------------------
Description:
--------------------------
Hardware performance event counter only for RV32.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - count
     - Count
     - WARL
     - Hardware performance event counter only for RV32\.

Upper 32 bits of Machine Hardware Performance Monitoring Counter Register 
--------------------------
AddressOffset: 'hb85 
--------------------------
Description:
--------------------------
Hardware performance event counter only for RV32.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - count
     - Count
     - WARL
     - Hardware performance event counter only for RV32\.

Upper 32 bits of Machine Hardware Performance Monitoring Counter Register 
--------------------------
AddressOffset: 'hb86 
--------------------------
Description:
--------------------------
Hardware performance event counter only for RV32.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - count
     - Count
     - WARL
     - Hardware performance event counter only for RV32\.

Upper 32 bits of Machine Hardware Performance Monitoring Counter Register 
--------------------------
AddressOffset: 'hb87 
--------------------------
Description:
--------------------------
Hardware performance event counter only for RV32.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - count
     - Count
     - WARL
     - Hardware performance event counter only for RV32\.

Upper 32 bits of Machine Hardware Performance Monitoring Counter Register 
--------------------------
AddressOffset: 'hb88 
--------------------------
Description:
--------------------------
Hardware performance event counter only for RV32.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - count
     - Count
     - WARL
     - Hardware performance event counter only for RV32\.

Upper 32 bits of Machine Hardware Performance Monitoring Counter Register 
--------------------------
AddressOffset: 'hb89 
--------------------------
Description:
--------------------------
Hardware performance event counter only for RV32.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - count
     - Count
     - WARL
     - Hardware performance event counter only for RV32\.

Upper 32 bits of Machine Hardware Performance Monitoring Counter Register 
--------------------------
AddressOffset: 'hb8a 
--------------------------
Description:
--------------------------
Hardware performance event counter only for RV32.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - count
     - Count
     - WARL
     - Hardware performance event counter only for RV32\.

Upper 32 bits of Machine Hardware Performance Monitoring Counter Register 
--------------------------
AddressOffset: 'hb8b 
--------------------------
Description:
--------------------------
Hardware performance event counter only for RV32.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - count
     - Count
     - WARL
     - Hardware performance event counter only for RV32\.

Upper 32 bits of Machine Hardware Performance Monitoring Counter Register 
--------------------------
AddressOffset: 'hb8c 
--------------------------
Description:
--------------------------
Hardware performance event counter only for RV32.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - count
     - Count
     - WARL
     - Hardware performance event counter only for RV32\.

Upper 32 bits of Machine Hardware Performance Monitoring Counter Register 
--------------------------
AddressOffset: 'hb8d 
--------------------------
Description:
--------------------------
Hardware performance event counter only for RV32.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - count
     - Count
     - WARL
     - Hardware performance event counter only for RV32\.

Upper 32 bits of Machine Hardware Performance Monitoring Counter Register 
--------------------------
AddressOffset: 'hb8e 
--------------------------
Description:
--------------------------
Hardware performance event counter only for RV32.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - count
     - Count
     - WARL
     - Hardware performance event counter only for RV32\.

Upper 32 bits of Machine Hardware Performance Monitoring Counter Register 
--------------------------
AddressOffset: 'hb8f 
--------------------------
Description:
--------------------------
Hardware performance event counter only for RV32.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - count
     - Count
     - WARL
     - Hardware performance event counter only for RV32\.

Upper 32 bits of Machine Hardware Performance Monitoring Counter Register 
--------------------------
AddressOffset: 'hb90 
--------------------------
Description:
--------------------------
Hardware performance event counter only for RV32.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - count
     - Count
     - WARL
     - Hardware performance event counter only for RV32\.

Upper 32 bits of Machine Hardware Performance Monitoring Counter Register 
--------------------------
AddressOffset: 'hb91 
--------------------------
Description:
--------------------------
Hardware performance event counter only for RV32.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - count
     - Count
     - WARL
     - Hardware performance event counter only for RV32\.

Upper 32 bits of Machine Hardware Performance Monitoring Counter Register 
--------------------------
AddressOffset: 'hb92 
--------------------------
Description:
--------------------------
Hardware performance event counter only for RV32.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - count
     - Count
     - WARL
     - Hardware performance event counter only for RV32\.

Upper 32 bits of Machine Hardware Performance Monitoring Counter Register 
--------------------------
AddressOffset: 'hb93 
--------------------------
Description:
--------------------------
Hardware performance event counter only for RV32.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - count
     - Count
     - WARL
     - Hardware performance event counter only for RV32\.

Upper 32 bits of Machine Hardware Performance Monitoring Counter Register 
--------------------------
AddressOffset: 'hb94 
--------------------------
Description:
--------------------------
Hardware performance event counter only for RV32.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - count
     - Count
     - WARL
     - Hardware performance event counter only for RV32\.

Upper 32 bits of Machine Hardware Performance Monitoring Counter Register 
--------------------------
AddressOffset: 'hb95 
--------------------------
Description:
--------------------------
Hardware performance event counter only for RV32.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - count
     - Count
     - WARL
     - Hardware performance event counter only for RV32\.

Upper 32 bits of Machine Hardware Performance Monitoring Counter Register 
--------------------------
AddressOffset: 'hb96 
--------------------------
Description:
--------------------------
Hardware performance event counter only for RV32.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - count
     - Count
     - WARL
     - Hardware performance event counter only for RV32\.

Upper 32 bits of Machine Hardware Performance Monitoring Counter Register 
--------------------------
AddressOffset: 'hb97 
--------------------------
Description:
--------------------------
Hardware performance event counter only for RV32.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - count
     - Count
     - WARL
     - Hardware performance event counter only for RV32\.

Upper 32 bits of Machine Hardware Performance Monitoring Counter Register 
--------------------------
AddressOffset: 'hb98 
--------------------------
Description:
--------------------------
Hardware performance event counter only for RV32.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - count
     - Count
     - WARL
     - Hardware performance event counter only for RV32\.

Upper 32 bits of Machine Hardware Performance Monitoring Counter Register 
--------------------------
AddressOffset: 'hb99 
--------------------------
Description:
--------------------------
Hardware performance event counter only for RV32.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - count
     - Count
     - WARL
     - Hardware performance event counter only for RV32\.

Upper 32 bits of Machine Hardware Performance Monitoring Counter Register 
--------------------------
AddressOffset: 'hb9a 
--------------------------
Description:
--------------------------
Hardware performance event counter only for RV32.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - count
     - Count
     - WARL
     - Hardware performance event counter only for RV32\.

Upper 32 bits of Machine Hardware Performance Monitoring Counter Register 
--------------------------
AddressOffset: 'hb9b 
--------------------------
Description:
--------------------------
Hardware performance event counter only for RV32.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - count
     - Count
     - WARL
     - Hardware performance event counter only for RV32\.

Upper 32 bits of Machine Hardware Performance Monitoring Counter Register 
--------------------------
AddressOffset: 'hb9c 
--------------------------
Description:
--------------------------
Hardware performance event counter only for RV32.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - count
     - Count
     - WARL
     - Hardware performance event counter only for RV32\.

Upper 32 bits of Machine Hardware Performance Monitoring Counter Register 
--------------------------
AddressOffset: 'hb9d 
--------------------------
Description:
--------------------------
Hardware performance event counter only for RV32.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - count
     - Count
     - WARL
     - Hardware performance event counter only for RV32\.

Upper 32 bits of Machine Hardware Performance Monitoring Counter Register 
--------------------------
AddressOffset: 'hb9e 
--------------------------
Description:
--------------------------
Hardware performance event counter only for RV32.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - count
     - Count
     - WARL
     - Hardware performance event counter only for RV32\.

Upper 32 bits of Machine Hardware Performance Monitoring Counter Register 
--------------------------
AddressOffset: 'hb9f 
--------------------------
Description:
--------------------------
Hardware performance event counter only for RV32.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - count
     - Count
     - WARL
     - Hardware performance event counter only for RV32\.

Cycle counter Register 
--------------------------
AddressOffset: 'hC00 
--------------------------
Description:
--------------------------
Cycle counter for RDCYCLE instruction. Shadow of mcycle.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - count
     - Count
     - read-only
     - Cycle counter for RDCYCLE instruction\. Shadow of mcycle\.

Instruction Retired counter Register 
--------------------------
AddressOffset: 'hC02 
--------------------------
Description:
--------------------------
Instructions-retired counter for RDINSTRET instruction. Shadow of minstret.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - count
     - Count
     - read-only
     - Instructions\-retired counter for RDINSTRET instruction\. Shadow of minstret\.

Upper 32-bits of Cycle counter Register 
--------------------------
AddressOffset: 'hC80 
--------------------------
Description:
--------------------------
Cycle counter for RDCYCLE instruction. Shadow of mcycleh.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - count
     - Count
     - read-only
     - Cycle counter for RDCYCLE instruction\. Shadow of mcycleh\.

Upper 32-bits of Instruction Retired counter Register 
--------------------------
AddressOffset: 'hC82 
--------------------------
Description:
--------------------------
Instructions-retired counter for RDINSTRET instruction. Shadow of minstreth.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - count
     - Count
     - read-only
     - Instructions\-retired counter for RDINSTRET instruction\. Shadow of minstreth\.

Machine Vendor ID Register 
--------------------------
AddressOffset: 'hF11 
--------------------------
Description:
--------------------------
This register provides the JEDEC manufacturer ID of the provider of the core.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:7
     - bank
     - Bank
     - read-only
     - Contain encoding for number of one\-byte continuation codes discarding the parity bit\.
   * - 6:0
     - offset
     - Offset
     - read-only
     - Contain encoding for the final byte discarding the parity bit\.

Machine Architecture ID Register 
--------------------------
AddressOffset: 'hF12 
--------------------------
Description:
--------------------------
This register encodes the base microarchitecture of the hart.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - architecture_id
     - Architecture id
     - read-only
     - This register encodes the base microarchitecture of the hart\.

Machine Implementation ID Register 
--------------------------
AddressOffset: 'hF13 
--------------------------
Description:
--------------------------
Provides a unique encoding of the version of the processor implementation.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - implementation
     - Implementation
     - read-only
     - Provides a unique encoding of the version of the processor implementation\.

Machine Hardware Thread ID Register 
--------------------------
AddressOffset: 'hF14 
--------------------------
Description:
--------------------------
This register contains the integer ID of the hardware thread running the code.

.. list-table::
   :widths: 20 20 15 15 40
   :header-rows: 1

   * - **BIT**
     - **NAME**
     - **displayName**
     - **RIGHT**
     - **Description**
   * - 31:0
     - hart_id
     - Hart id
     - read-only
     - This register contains the integer ID of the hardware thread running the code\.
