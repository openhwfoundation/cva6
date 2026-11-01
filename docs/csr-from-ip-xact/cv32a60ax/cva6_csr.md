# REGISTERS CSR CV32A6

## Floating-Point Accrued Exceptions Register 
### *AddressOffset*: 'h1 
### *Description*:
The fields within the ``fcsr`` can also be accessed individually through different CSR addresses, and separate assembler pseudoinstructions are defined for these accesses. The FRRM instruction reads the Rounding Mode field ``frm`` and copies it into the least-significant three bits of integer register *rd*, with zero in all other bits. FSRM swaps the value in frm by copying the original value into integer register *rd*, and then writing a new value obtained from the three least-significant bits of integer register *rs1* into ``frm``. FRFLAGS and FSFLAGS are defined analogously for the Accrued Exception Flags field ``fflags``.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 4 | NV | Invalid operation | read-write  | The accrued exception flags indicate the exception conditions that have arisen on any floating\-point arithmetic instruction since the field was last reset by software\. The base RISC\-V ISA does not support generating a trap on the setting of a floating\-point exception flag\.|
| 3 | DZ | Divide by zero | read-write  | The accrued exception flags indicate the exception conditions that have arisen on any floating\-point arithmetic instruction since the field was last reset by software\. The base RISC\-V ISA does not support generating a trap on the setting of a floating\-point exception flag\.|
| 2 | OF | Overflow | read-write  | The accrued exception flags indicate the exception conditions that have arisen on any floating\-point arithmetic instruction since the field was last reset by software\. The base RISC\-V ISA does not support generating a trap on the setting of a floating\-point exception flag\.|
| 1 | UF | Underflow | read-write  | The accrued exception flags indicate the exception conditions that have arisen on any floating\-point arithmetic instruction since the field was last reset by software\. The base RISC\-V ISA does not support generating a trap on the setting of a floating\-point exception flag\.|
| 0 | NX | Inexact | read-write  | The accrued exception flags indicate the exception conditions that have arisen on any floating\-point arithmetic instruction since the field was last reset by software\. The base RISC\-V ISA does not support generating a trap on the setting of a floating\-point exception flag\.|

## Floating-Point Dynamic Rounding Mode Register 
### *AddressOffset*: 'h2 
### *Description*:
The fields within the ``fcsr`` can also be accessed individually through different CSR addresses, and separate assembler pseudoinstructions are defined for these accesses. The FRRM instruction reads the Rounding Mode field ``frm`` and copies it into the least-significant three bits of integer register *rd*, with zero in all other bits. FSRM swaps the value in frm by copying the original value into integer register *rd*, and then writing a new value obtained from the three least-significant bits of integer register *rs1* into ``frm``. FRFLAGS and FSFLAGS are defined analogously for the Accrued Exception Flags field ``fflags``.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 2:0 | FRM | Floating-point rounding mode | read-write  | The fields within the ``fcsr`` can also be accessed individually through different CSR addresses, and separate assembler pseudoinstructions are defined for these accesses\. The FRRM instruction reads the Rounding Mode field ``frm`` and copies it into the least\-significant three bits of integer register \*rd\*, with zero in all other bits\. FSRM swaps the value in frm by copying the original value into integer register \*rd\*, and then writing a new value obtained from the three least\-significant bits of integer register \*rs1\* into ``frm``\. FRFLAGS and FSFLAGS are defined analogously for the Accrued Exception Flags field ``fflags``\. // ``Enumerated Values``( "RNE" :0 ) ( "RTZ" :1 ) ( "RDN" :2 ) ( "RUP" :3 ) ( "RMM" :4 ) ( "INVALID_5" :5 ) ( "INVALID_6" :6 ) ( "DYN" :7 ) |

## Floating-Point Control and Status Register Register 
### *AddressOffset*: 'h3 
### *Description*:
The floating-point control and status register, ``fcsr``, is a RISC-V control and status register (CSR). It is a read/write register that selects the dynamic rounding mode for floating-point arithmetic operations and holds the accrued exception flags.

The ``fcsr`` register can be read and written with the FRCSR and FSCSR instructions, which are assembler pseudoinstructions built on the underlying CSR access instructions. FRCSR reads ``fcsr`` by copying it into integer register *rd*. FSCSR swaps the value in ``fcsr`` by copying the original value into integer register *rd*, and then writing a new value obtained from integer register *rs1* into ``fcsr``.

The fields within the ``fcsr`` can also be accessed individually through different CSR addresses, and separate assembler pseudoinstructions are defined for these accesses. The FRRM instruction reads the Rounding Mode field ``frm`` and copies it into the least-significant three bits of integer register *rd*, with zero in all other bits. FSRM swaps the value in frm by copying the original value into integer register *rd*, and then writing a new value obtained from the three least-significant bits of integer register *rs1* into ``frm``. FRFLAGS and FSFLAGS are defined analogously for the Accrued Exception Flags field ``fflags``.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 7:5 | FRM | Floating-point rounding mode | read-write  | Floating\-point operations use either a static rounding mode encoded in the instruction, or a dynamic rounding mode held in ``frm``\. Rounding modes are encoded as shown in the enumerated value\. A value of 111 in the instruction’s \*rm\* field selects the dynamic rounding mode held in ``frm``\. If ``frm`` is set to an invalid value \(101–111\), any subsequent attempt to execute a floating\-point operation with a dynamic rounding mode will raise an illegal instruction exception\. Some instructions, including widening conversions, have the \*rm\* field but are nevertheless unaffected by the rounding mode; software should set their \*rm\* field to RNE \(000\)\. // ``Enumerated Values``( "RNE" :0 ) ( "RTZ" :1 ) ( "RDN" :2 ) ( "RUP" :3 ) ( "RMM" :4 ) ( "INVALID_5" :5 ) ( "INVALID_6" :6 ) ( "DYN" :7 ) |
| 4 | NV | Invalid operation | read-write  | The accrued exception flags indicate the exception conditions that have arisen on any floating\-point arithmetic instruction since the field was last reset by software\. The base RISC\-V ISA does not support generating a trap on the setting of a floating\-point exception flag\.|
| 3 | DZ | Divide by zero | read-write  | The accrued exception flags indicate the exception conditions that have arisen on any floating\-point arithmetic instruction since the field was last reset by software\. The base RISC\-V ISA does not support generating a trap on the setting of a floating\-point exception flag\.|
| 2 | OF | Overflow | read-write  | The accrued exception flags indicate the exception conditions that have arisen on any floating\-point arithmetic instruction since the field was last reset by software\. The base RISC\-V ISA does not support generating a trap on the setting of a floating\-point exception flag\.|
| 1 | UF | Underflow | read-write  | The accrued exception flags indicate the exception conditions that have arisen on any floating\-point arithmetic instruction since the field was last reset by software\. The base RISC\-V ISA does not support generating a trap on the setting of a floating\-point exception flag\.|
| 0 | NX | Inexact | read-write  | The accrued exception flags indicate the exception conditions that have arisen on any floating\-point arithmetic instruction since the field was last reset by software\. The base RISC\-V ISA does not support generating a trap on the setting of a floating\-point exception flag\.|

## Supervisor Status Register 
### *AddressOffset*: 'h100 
### *Description*:
The ``sstatus`` register keeps track of the processor’s current operating state.

The ``sstatus`` register is a subset of the ``mstatus`` register.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 31 | SD | State dirty | read-only  | The SD bit is a read\-only bit that summarizes whether either the FS, VS, or XS fields signal the presence of some dirty state that will require saving extended user context to memory\. If FS, XS, and VS are all read\-only zero, then SD is also always zero\.|
| 19 | MXR | Make executable readable | read-write  | The MXR bit modifies the privilege with which loads access virtual memory\. When MXR=0, only loads from pages marked readable will succeed\. When MXR=1, loads from pages marked either readable or executable \(R=1 or X=1\) will succeed\. MXR has no effect when page\-based virtual memory is not in effect\.|
| 18 | SUM | Supervisor user memory | read-write  | The SUM \(permit Supervisor User Memory access\) bit modifies the privilege with which S\-mode loads and stores access virtual memory\. When SUM=0, S\-mode memory accesses to pages that are accessible by U\-mode will fault\. When SUM=1, these accesses are permitted\. SUM has no effect when page\-based virtual memory is not in effect\. Note that, while SUM is ordinarily ignored when not executing in S\-mode, it \*is\* in effect when MPRV=1 and MPP=S\. SUM is read\-only 0 if S\-mode is not supported or if ``satp``\.MODE is read\-only 0\.|
| 16:15 | XS | Extension state | read-only  | The XS field is used to reduce the cost of context save and restore by setting and tracking the current state of the user\-mode extensions\. The XS field encodes the status of the additional user\-mode extensions and associated state\.  This field can be checked by a context switch routine to quickly determine whether a state save or restore is required\. If a save or restore is required, additional instructions and CSRs are typically required to effect and optimize the process\. // ``Enumerated Values``( "Off" :0 ) ( "Initial" :1 ) ( "Clean" :2 ) ( "Dirty" :3 ) |
| 14:13 | FS | Floating-point unit state | read-write,WARL  | The FS field is used to reduce the cost of context save and restore by setting and tracking the current state of the floating\-point unit\. The FS field encodes the status of the floating\-point unit state, including the floating\-point registers ``f0–f31`` and the CSRs ``fcsr``, ``frm``, and ``fflags``\.  This field can be checked by a context switch routine to quickly determine whether a state save or restore is required\. If a save or restore is required, additional instructions and CSRs are typically required to effect and optimize the process\. // ``Enumerated Values``( "Off" :0 ) ( "Initial" :1 ) ( "Clean" :2 ) ( "Dirty" :3 ) |
| 8 | SPP | Supervisor mode prior privilege | read-write  | SPP bit indicates the privilege level at which a hart was executing before entering supervisor mode\. When a trap is taken, SPP is set to 0 if the trap originated from user mode, or 1 otherwise\. When an SRET instruction is executed to return from the trap handler, the privilege level is set to user mode if the SPP bit is 0, or supervisor mode if the SPP bit is 1; SPP is then set to 0\.|
| 5 | SPIE | Supervisor mode prior interrupt enable | read-write  | The SPIE bit indicates whether supervisor interrupts were enabled prior to trapping into supervisor mode\. When a trap is taken into supervisor mode, SPIE is set to SIE, and SIE is set to 0\. When an SRET instruction is executed, SIE is set to SPIE, then SPIE is set to 1\.|
| 4 | UPIE |  | read-write  | When a URET instruction is executed, UIE is set to UPIE, and UPIE is set to 1\.|
| 1 | SIE | Supervisor mode interrupt enable | read-write  | The SIE bit enables or disables all interrupts in supervisor mode\. When SIE is clear, interrupts are not taken while in supervisor mode\. When the hart is running in user\-mode, the value in SIE is ignored, and supervisor\-level interrupts are enabled\. The supervisor can disable individual interrupt sources using the ``sie`` CSR\.|
| 0 | UIE |  | read-write  | The UIE bit enables or disables user\-mode interrupts\.|

## Supervisor Interrupt Enable Register 
### *AddressOffset*: 'h104 
### *Description*:
The ``sie`` is the register containing supervisor interrupt enable bits.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 14:10 | Reserved_10 | Reserved | read-write,WARL  | Reserved\.``Legal Values:``0\.|
| 9 | SEIE | Supervisor-level external interrupt enable | read-write,WARL  | SEIE is the interrupt\-enable bit for supervisor\-level external interrupts\.|
| 8 | UEIE |  | read-write,WARL  | User\-level external interrupts are disabled when the UEIE bit in the sie register is clear\.``Legal Values:``0\.|
| 7:6 | Reserved_6 | Reserved | read-write,WARL  | Reserved\.``Legal Values:``0\.|
| 5 | STIE | Supervisor-level timer interrupt enable | read-write,WARL  | STIE is the interrupt\-enable bit for supervisor\-level timer interrupts\.|
| 4 | UTIE |  | read-write,WARL  | User\-level timer interrupts are disabled when the UTIE bit in the sie register is clear\.``Legal Values:``0\.|
| 3:2 | Reserved_2 | Reserved | read-write,WARL  | Reserved\.``Legal Values:``0\.|
| 1 | SSIE | Supervisor-level software interrupt enable | read-write,WARL  | SSIE is the interrupt\-enable bit for supervisor\-level software interrupts\.|
| 0 | USIE |  | read-write,WARL  | User\-level software interrupts are disabled when the USIE bit in the sie register is clear\.``Legal Values:``0\.|

## Supervisor Trap Vector Base Address Register 
### *AddressOffset*: 'h105 
### *Description*:
The ``stvec`` register holds trap vector configuration, consisting of a vector base address (BASE) and a vector mode (MODE).
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 31:2 | BASE |  | read-write,WARL  | The BASE field in stvec is a WARL field that can hold any valid virtual or physical address, subject to the following alignment constraints: when MODE=Direct the address must be 4\-byte aligned, and when MODE=Vectored the address must be 256\-byte aligned\.|
| 1:0 | MODE |  | read-write,WARL  | When MODE=Direct, all traps into supervisor mode cause the ``pc`` to be set to the address in the BASE field\. When MODE=Vectored, all synchronous exceptions into supervisor mode cause the ``pc`` to be set to the address in the BASE field, whereas interrupts cause the ``pc`` to be set to the address in the BASE field plus four times the interrupt cause number\.``Legal Values :``0,1\. // ``Enumerated Values``( "Direct" :0 ) ( "Vectored" :1 ) ( "Reserved_2" :2 ) ( "Reserved_3" :3 ) |

## Supervisor Counter Enable Register 
### *AddressOffset*: 'h106 
### *Description*:
The counter-enable register ``scounteren`` controls the availability of the hardware performance monitoring counters to U-mode.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 31:3 | HPMn | Hpmcountern | read-write  | When HPMn is clear, attempts to read the ``hpmcountern`` register while executing in U\-mode will cause an illegal instruction exception\. When this bit is set, access to the corresponding register is permitted\.|
| 2 | IR | Instret | read-write  | When IR is clear, attempts to read the ``instret`` register while executing in U\-mode will cause an illegal instruction exception\. When this bit is set, access to the corresponding register is permitted\.|
| 1 | TM | Time | read-write  | When TM is clear, attempts to read the ``time`` register while executing in U\-mode will cause an illegal instruction exception\. When this bit is set, access to the corresponding register is permitted\.|
| 0 | CY | Cycle | read-write  | When CY is clear, attempts to read the ``cycle`` register while executing in U\-mode will cause an illegal instruction exception\. When this bit is set, access to the corresponding register is permitted\.|

## Supervisor Scratch Register 
### *AddressOffset*: 'h140 
### *Description*:
The ``sscratch`` register is dedicated for use by the supervisor.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 31:0 | SSCRATCH | Supervisor scratch | read-write  | The ``sscratch`` register is dedicated for use by the supervisor\.|

## Supervisor Exception Program Counter Register 
### *AddressOffset*: 'h141 
### *Description*:
When a trap is taken into S-mode, ``sepc`` is written with the virtual address of the instruction that was interrupted or that encountered the exception. Otherwise, ``sepc`` is never written by the implementation, though it may be explicitly written by software.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 31:0 | SEPC | Supervisor exception program counter | read-write,WARL  | When a trap is taken into S\-mode, ``sepc`` is written with the virtual address of the instruction that was interrupted or that encountered the exception\. Otherwise, ``sepc`` is never written by the implementation, though it may be explicitly written by software\.|

## Supervisor Cause Register 
### *AddressOffset*: 'h142 
### *Description*:
When a trap is taken into S-mode, ``scause`` is written with a code indicating the event that caused the trap. Otherwise, ``scause`` is never written by the implementation, though it may be explicitly written by software.
Supervisor cause register (``scause``) values after trap are shown in the following table.
|Interrupt|Exception Code|Description|
|---------|--------------|-----------|
|1|0|*Reserved*|
|1|1|Supervisor software interrupt|
|1|2-4|*Reserved*|
|1|5|Supervisor timer interrupt|
|1|6-8|*Reserved*|
|1|9|Supervisor external interrupt|
|1|10-15|*Reserved*|
|1|≥16|*Designated for platform use*|
|0|0|Instruction address misaligned|
|0|1|Instruction access fault|
|0|2|Illegal instruction|
|0|3|Breakpoint|
|0|4|Load address misaligned|
|0|5|Load access fault|
|0|6|Store/AMO address misaligned|
|0|7|Store/AMO access fault|
|0|8|Environment call from U-mode|
|0|9|Environment call from S-mode|
|0|10-11|*Reserved*|
|0|12|Instruction page fault|
|0|13|Load page fault|
|0|14|*Reserved*|
|0|15|Store/AMO page fault|
|0|16-23|*Reserved*|
|0|24-31|*Designated for custom use*|
|0|32-47|*Reserved*|
|0|48-63|*Designated for custom use*|
|0|≥64|*Reserved*|

| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 31 | Interrupt |  | read-write  | The Interrupt bit in the ``scause`` register is set if the trap was caused by an interrupt\.|
| 30:0 | Exception_Code | Exception code | read-write,WLRL  | The Exception Code field contains a code identifying the last exception or interrupt\.|

## Supervisor Trap Value Register 
### *AddressOffset*: 'h143 
### *Description*:
When a trap is taken into S-mode, ``stval`` is written with exception-specific information to assist software in handling the trap. Otherwise, ``stval`` is never written by the implementation, though it may be explicitly written by software. The hardware platform will specify which exceptions must set ``stval`` informatively and which may unconditionally set it to zero.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 31:0 | STVAL | Supervisor trap value | read-write,WARL  | When a trap is taken into S\-mode, ``stval`` is written with exception\-specific information to assist software in handling the trap\. Otherwise, ``stval`` is never written by the implementation, though it may be explicitly written by software\. The hardware platform will specify which exceptions must set ``stval`` informatively and which may unconditionally set it to zero\.|

## Supervisor Interrupt Pending Register 
### *AddressOffset*: 'h144 
### *Description*:
The ``sip`` register contains information on pending interrupts.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 14:10 | Reserved_10 | Reserved | read-write,WARL  | Reserved\.``Legal Values:``0\.|
| 9 | SEIP | Supervisor-level external interrupt pending | read-only,WARL  | SEIP is the interrupt\-pending bit for supervisor\-level external interrupts\.|
| 8 | UEIP |  | read-write,WARL  | UEIP may be written by S\-mode software to indicate to U\-mode that an external interrupt is pending\.``Legal Values:``0\.|
| 7:6 | Reserved_6 | Reserved | read-write,WARL  | Reserved\.``Legal Values:``0\.|
| 5 | STIP | Supervisor-level timer interrupt pending | read-only,WARL  | SEIP is the interrupt\-pending bit for supervisor\-level timer interrupts\.|
| 4 | UTIP |  | read-write,WARL  | A user\-level timer interrupt is pending if the UTIP bit in the sip register is set\.``Legal Values:``0\.|
| 3:2 | Reserved_2 | Reserved | read-write,WARL  | Reserved\.``Legal Values:``0\.|
| 1 | SSIP | Supervisor-level software interrupt pending | read-only,WARL  | SSIP is the interrupt\-pending bit for supervisor\-level software interrupts\.|
| 0 | USIP |  | read-write,WARL  | A user\-level software interrupt is triggered on the current hart by writing 1 to its user software interrupt\-pending \(USIP\) bit\.``Legal Values:``0\.|

## Supervisor Address Translation and Protection Register 
### *AddressOffset*: 'h180 
### *Description*:
The ``satp`` register controls supervisor-mode address translation and protection.

The ``satp`` register is considered active when the effective privilege mode is S-mode or U-mode. Executions of the address-translation algorithm may only begin using a given value of ``satp`` when ``satp`` is active.

.. note::
  Writing ``satp`` does not imply any ordering constraints between page-table updates and subsequent address translations, nor does it imply any invalidation of address-translation caches. If the new address space’s page tables have been modified, or if an ASID is reused, it may be necessary to execute an SFENCE.VMA instruction after, or in some cases before, writing ``satp``.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 31 | MODE | Mode | read-write,WARL  | This bitfield selects the current address\-translation scheme\.  When MODE=Bare, supervisor virtual addresses are equal to supervisor physical addresses, and there is no additional memory protection beyond the physical memory protection scheme\.  To select MODE=Bare, software must write zero to the remaining fields of ``satp`` \(bits 30–0\)\. Attempting to select MODE=Bare with a nonzero pattern in the remaining fields has an ``unspecified`` effect on the value that the remaining fields assume and an ``unspecified`` effect on address translation and protection behavior\. // ``Enumerated Values``( "Bare" :0 ) ( "Sv32" :1 ) |
| 30:22 | ASID | Address space identifier | read-write,WARL  | This bitfield facilitates address\-translation fences on a per\-address\-space basis\.|
| 21:0 | PPN | Physical page number | read-write,WARL  | This bitfield holds the root page table, i\.e\., its supervisor physical address divided by 4 KiB\.|

## Machine Status Register 
### *AddressOffset*: 'h300 
### *Description*:
The ``mstatus`` register keeps track of and controls the hart’s current operating state.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 31 | SD | State dirty | read-only  | The SD bit is a read\-only bit that summarizes whether either the FS, VS, or XS fields signal the presence of some dirty state that will require saving extended user context to memory\. If FS, XS, and VS are all read\-only zero, then SD is also always zero\.|
| 30:23 | WPRI3 | Reserved writes preserve values, reads ignore value | read-write,WPRI  | Reserved Writes Preserve Values, Reads Ignore Value|
| 22 | TSR | Trap sret | read-write,WARL  | The TSR bit supports intercepting the supervisor exception return instruction, SRET\. When TSR=1, attempts to execute SRET while executing in S\-mode will raise an illegal instruction exception\. When TSR=0, this operation is permitted in S\-mode\.|
| 21 | TW | Timeout wait | read-write,WARL  | The TW bit supports intercepting the WFI instruction\. When TW=0, the WFI instruction may execute in lower privilege modes when not prevented for some other reason\. When TW=1, then if WFI is executed in any less\-privileged mode, and it does not complete within an implementation\-specific, bounded time limit, the WFI instruction causes an illegal instruction exception\. The time limit may always be 0, in which case WFI always causes an illegal instruction exception in less\-privileged modes when TW=1\.|
| 20 | TVM | Trap virtual memory | read-write,WARL  | The TVM bit supports intercepting supervisor virtual\-memory management operations\. When TVM=1, attempts to read or write the ``satp`` CSR or execute an SFENCE\.VMA or SINVAL\.VMA instruction while executing in S\-mode will raise an illegal instruction exception\. When TVM=0, these operations are permitted in S\-mode\.|
| 19 | MXR | Make executable readable | read-write  | The MXR bit modifies the privilege with which loads access virtual memory\. When MXR=0, only loads from pages marked readable will succeed\. When MXR=1, loads from pages marked either readable or executable \(R=1 or X=1\) will succeed\. MXR has no effect when page\-based virtual memory is not in effect\.|
| 18 | SUM | Supervisor user memory | read-write  | The SUM \(permit Supervisor User Memory access\) bit modifies the privilege with which S\-mode loads and stores access virtual memory\. When SUM=0, S\-mode memory accesses to pages that are accessible by U\-mode will fault\. When SUM=1, these accesses are permitted\. SUM has no effect when page\-based virtual memory is not in effect\. Note that, while SUM is ordinarily ignored when not executing in S\-mode, it is in effect when MPRV=1 and MPP=S\.|
| 17 | MPRV | Modify privilege | read-write  | The MPRV \(Modify PRiVilege\) bit modifies the effective privilege mode, i\.e\., the privilege level at which loads and stores execute\. When MPRV=0, loads and stores behave as normal, using the translation and protection mechanisms of the current privilege mode\. When MPRV=1, load and store memory addresses are translated and protected, and endianness is applied, as though the current privilege mode were set to MPP\. Instruction address\-translation and protection are unaffected by the setting of MPRV\.|
| 16:15 | XS | Extension state | read-only  | The XS field is used to reduce the cost of context save and restore by setting and tracking the current state of the user\-mode extensions\. The XS field encodes the status of the additional user\-mode extensions and associated state\.  This field can be checked by a context switch routine to quickly determine whether a state save or restore is required\. If a save or restore is required, additional instructions and CSRs are typically required to effect and optimize the process\. // ``Enumerated Values``( "Off" :0 ) ( "Initial" :1 ) ( "Clean" :2 ) ( "Dirty" :3 ) |
| 14:13 | FS | Floating-point unit state | read-write,WARL  | The FS field is used to reduce the cost of context save and restore by setting and tracking the current state of the floating\-point unit\. The FS field encodes the status of the floating\-point unit state, including the floating\-point registers ``f0–f31`` and the CSRs ``fcsr``, ``frm``, and ``fflags``\.  This field can be checked by a context switch routine to quickly determine whether a state save or restore is required\. If a save or restore is required, additional instructions and CSRs are typically required to effect and optimize the process\. // ``Enumerated Values``( "Off" :0 ) ( "Initial" :1 ) ( "Clean" :2 ) ( "Dirty" :3 ) |
| 12:11 | MPP | Machine mode prior privilege | read-write  | Holds the previous privilege mode for machine mode\.|
| 10:9 | VS | Vector extension state | read-only,WARL  | V extension is not supported VS=0\.|
| 8 | SPP | Supervisor mode prior privilege | read-write  | Holds the previous privilege mode for supervisor mode\.|
| 7 | MPIE | Machine mode prior interrupt enable | read-write  | Indicates whether machine interrupts were enabled prior to trapping into machine mode\.|
| 6 | UBE | User breakpoint enable | read-write,WARL  | UBE controls whether explicit load and store memory accesses made from U\-mode are little\-endian \(UBE=0\) or big\-endian \(UBE=1\)\.|
| 5 | SPIE | Supervisor mode prior interrupt enable | read-write  | Indicates whether supervisor interrupts were enabled prior to trapping into supervisor mode\.|
| 4 | WPRI2 | Reserved writes preserve values, reads ignore value | read-write,WPRI  | Reserved Writes Preserve Values, Reads Ignore Value|
| 3 | MIE | Machine mode interrupt enable | read-write  | Global interrupt\-enable bit for Machine mode\.|
| 2 | WPRI1 | Reserved writes preserve values, reads ignore value | read-write,WPRI  | Reserved Writes Preserve Values, Reads Ignore Value|
| 1 | SIE | Supervisor mode interrupt enable | read-write  | Global interrupt\-enable bit for Supervisor mode\.|
| 0 | WPRI0 | Reserved writes preserve values, reads ignore value | read-write,WPRI  | Reserved Writes Preserve Values, Reads Ignore Value|

## Machine ISA Register 
### *AddressOffset*: 'h301 
### *Description*:
The misa CSR is reporting the ISA supported by the hart.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 31:30 | MXL | Machine xlen | read-write,WARL  | The MXL field encodes the native base integer ISA width\. // ``Enumerated Values``( "XLEN_32" :1 ) ( "XLEN_64" :2 ) ( "XLEN_128" :3 ) |
| 25:0 | Extensions | Extensions | read-write,WARL  | The Extensions field encodes the presence of the standard extensions, with a single bit per letter of the alphabet\. // ``Enumerated Values``( "A" :1 ) ( "B" :2 ) ( "C" :4 ) ( "D" :8 ) ( "E" :16 ) ( "F" :32 ) ( "G" :64 ) ( "H" :128 ) ( "I" :256 ) ( "J" :512 ) ( "K" :1024 ) ( "L" :2048 ) ( "M" :4096 ) ( "N" :8192 ) ( "O" :16384 ) ( "P" :32768 ) ( "Q" :65536 ) ( "R" :131072 ) ( "S" :262144 ) ( "T" :524288 ) ( "U" :1048576 ) ( "V" :2097152 ) ( "W" :4194304 ) ( "X" :8388608 ) ( "Y" :16777216 ) ( "Z" :33554432 ) |

## Machine Exception Delegation Register 
### *AddressOffset*: 'h302 
### *Description*:
Provides individual read/write bits to indicate that certain exceptions should be processed directly by a lower privilege level.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 31:0 | Synchronous_Exceptions | Synchronous exceptions | read-write,WARL  | Provides individual read/write bits to indicate that certain exceptions should be processed directly by a lower privilege level\.|

## Machine Interrupt Delegation Register 
### *AddressOffset*: 'h303 
### *Description*:
Provides individual read/write bits to indicate that certain interrupts should be processed directly by a lower privilege level.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 31:0 | Interrupts | Interrupts | read-write  | Provides individual read/write bits to indicate that certain interrupts should be processed directly by a lower privilege level\.|

## Machine Interrupt Enable Register 
### *AddressOffset*: 'h304 
### *Description*:
This register contains machine interrupt enable bits.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 15:12 | Reserved_12 | Reserved | read-write,WARL  | Reserved\.``Legal Values:``0\.|
| 11 | MEIE | M-mode external interrupt enable | read-write,WARL  | Enables machine mode external interrupts\.|
| 10 | Reserved_10 | Reserved | read-write,WARL  | Reserved\.``Legal Values:``0\.|
| 9 | SEIE | S-mode external interrupt enable | read-write,WARL  | Enables supervisor mode external interrupts\.|
| 8 | UEIE |  | read-write,WARL  | enables U\-mode external interrupts\.``Legal Values:``0\.|
| 7 | MTIE | M-mode timer interrupt enable | read-write,WARL  | Enables machine mode timer interrupts\.|
| 6 | Reserved_6 | Reserved | read-write,WARL  | Reserved\.``Legal Values:``0\.|
| 5 | STIE | S-mode timer interrupt enable | read-write,WARL  | Enables supervisor mode timer interrupts\.|
| 4 | UTIE |  | read-write,WARL  | timer interrupt\-enable bit for U\-mode\.``Legal Values:``0\.|
| 3 | MSIE | M-mode software interrupt enable | read-write  | Enables machine mode software interrupts\.|
| 2 | Reserved_2 | Reserved | read-write,WARL  | Reserved\.``Legal Values:``0\.|
| 1 | SSIE | S-mode software interrupt enable | read-write,WARL  | Enables supervisor mode software interrupts\.|
| 0 | USIE |  | read-write,WARL  | enable U\-mode software interrupts\.``Legal Values:``0\.|

## Machine Trap Vector Register 
### *AddressOffset*: 'h305 
### *Description*:
This register holds trap vector configuration, consisting of a vector base address and a vector mode.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 31:2 | BASE |  | read-write,WARL  | The BASE field in mtvec is a WARL field that can hold any valid virtual or physical address, subject to the following alignment constraints: when MODE=Direct the address must be 4\-byte aligned, and when MODE=Vectored the address must be 256\-byte aligned\.|
| 1:0 | MODE |  | read-write,WARL  | Imposes additional alignment constraints on the value in the BASE field\.``Legal Values :``0,1\. // ``Enumerated Values``( "Direct" :0 ) ( "Vectored" :1 ) ( "Reserved_2" :2 ) ( "Reserved_3" :3 ) |

## Machine Counter Enable Register 
### *AddressOffset*: 'h306 
### *Description*:
This register controls the availability of the hardware performance-monitoring counters to the next-lowest privileged mode.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 31:3 | HPMn | Hpmcountern | read-write,WARL  | When HPMn is clear, attempts to read the ``hpmcountern`` register while executing in S\-mode or U\-mode will cause an illegal instruction exception\. When this bit is set, access to the corresponding register is permitted in the next implemented privilege mode\.|
| 2 | IR | Instret | read-write  | When IR is clear, attempts to read the ``instret`` register while executing in S\-mode or U\-mode will cause an illegal instruction exception\. When this bit is set, access to the corresponding register is permitted in the next implemented privilege mode\.|
| 1 | TM | Time | read-write  | When TM is clear, attempts to read the ``time`` register while executing in S\-mode or U\-mode will cause an illegal instruction exception\. When this bit is set, access to the corresponding register is permitted in the next implemented privilege mode\.|
| 0 | CY | Cycle | read-write  | When CY is clear, attempts to read the ``cycle`` register while executing in S\-mode or U\-mode will cause an illegal instruction exception\. When this bit is set, access to the corresponding register is permitted in the next implemented privilege mode\.|

## Hardware Performance-Monitoring Event Selector Register 
### *AddressOffset*: 'h323 
### *Description*:
This register controls which event causes the corresponding counter to increment.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 4:0 | mhpmevent |  | read-write,WARL  | This register controls which event causes the corresponding counter to increment\.|

## Machine Scratch Register 
### *AddressOffset*: 'h340 
### *Description*:
This register is used to hold a value dedicated to Machine mode. Attempts to access without Machine mode level raise illegal instruction exception.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 31:0 | mscratch | Machine scratch | read-write  | This register is used to hold a value dedicated to Machine mode\. Attempts to access without Machine mode level raise illegal instruction exception\.|

## Machine Exception Program Counter Register 
### *AddressOffset*: 'h341 
### *Description*:
This register must be able to hold all valid virtual addresses.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 31:0 | mepc | Machine exception program counter | read-write,WARL  | This register must be able to hold all valid virtual addresses\.|

## Machine Cause Register 
### *AddressOffset*: 'h342 
### *Description*:
When a trap is taken into M-mode, mcause is written with a code indicating the event that caused the trap.
Machine cause register (``mcause``) values after trap are shown in the following table.
|Interrupt|Exception Code|Description|
|---------|--------------|-----------|
|1|0|*Reserved*|
|1|1|Supervisor software interrupt|
|1|2-4|*Reserved*|
|1|5|Supervisor timer interrupt|
|1|6-8|*Reserved*|
|1|9|Supervisor external interrupt|
|1|10-15|*Reserved*|
|1|≥16|*Designated for platform use*|
|0|0|Instruction address misaligned|
|0|1|Instruction access fault|
|0|2|Illegal instruction|
|0|3|Breakpoint|
|0|4|Load address misaligned|
|0|5|Load access fault|
|0|6|Store/AMO address misaligned|
|0|7|Store/AMO access fault|
|0|8|Environment call from U-mode|
|0|9|Environment call from S-mode|
|0|10-11|*Reserved*|
|0|12|Instruction page fault|
|0|13|Load page fault|
|0|14|*Reserved*|
|0|15|Store/AMO page fault|
|0|16-23|*Reserved*|
|0|24-31|*Designated for custom use*|
|0|32-47|*Reserved*|
|0|48-63|*Designated for custom use*|
|0|≥64|*Reserved*|

| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 31 | Interrupt | Interrupt | read-write  | This bit is set if the trap was caused by an interrupt\.|
| 30:0 | exception_code | Exception code | read-write,WLRL  | This field contains a code identifying the last exception or interrupt\.|

## Machine Trap Value Register 
### *AddressOffset*: 'h343 
### *Description*:
When a trap is taken into M-mode, mtval is either set to zero or written with exception-specific information to assist software in handling the trap.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 31:0 | mtval | Machine trap value | read-write,WARL  | When a trap is taken into M\-mode, mtval is either set to zero or written with exception\-specific information to assist software in handling the trap\.|

## Machine Interrupt Pending Register 
### *AddressOffset*: 'h344 
### *Description*:
This register contains machine interrupt pending bits.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 15:12 | Reserved_12 | Reserved | read-write,WARL  | Reserved\.``Legal Values:``0\.|
| 11 | MEIP | M-mode external interrupt pending | read-only  | The interrupt\-pending bit for machine\-level external interrupts\.|
| 10 | Reserved_10 | Reserved | read-write,WARL  | Reserved\.``Legal Values:``0\.|
| 9 | SEIP | S-mode external interrupt pending | read-write  | The interrupt\-pending bit for supervisor\-level external interrupts\.|
| 8 | UEIP |  | read-write  | enables external interrupts\.``Legal Values:``0\.|
| 7 | MTIP | M-mode timer interrupt pending | read-only  | The interrupt\-pending bit for machine\-level timer interrupts\.|
| 6 | Reserved_6 | Reserved | read-write,WARL  | Reserved\.``Legal Values:``0\.|
| 5 | STIP | S-mode timer interrupt pending | read-write  | The interrupt\-pending bit for supervisor\-level timer interrupts\.|
| 4 | UTIP |  | read-write  | Correspond to timer interrupt\-pending bits for user interrupt\.``Legal Values:``0\.|
| 3 | MSIP | M-mode software interrupt pending | read-only  | The interrupt\-pending bit for machine\-level software interrupts\.|
| 2 | Reserved_2 | Reserved | read-write,WARL  | Reserved\.``Legal Values:``0\.|
| 1 | SSIP | S-mode software interrupt pending | read-write  | The interrupt\-pending bit for supervisor\-level software interrupts\.|
| 0 | USIP |  | read-write  | A hart to directly write its own USIP bits when running in the appropriate mode\.``Legal Values:``0\.|

## Physical Memory Protection Config 0 Register 
### *AddressOffset*: 'h3A0 
### *Description*:
Holds configuration 0-3.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 31:24 | pmp3cfg | Physical memory protection 3 config | read-write  | Holds the configuration\.|
| 23:16 | pmp2cfg | Physical memory protection 2 config | read-write  | Holds the configuration\.|
| 15:8 | pmp1cfg | Physical memory protection 1 config | read-write  | Holds the configuration\.|
| 7:0 | pmp0cfg | Physical memory protection 0 config | read-write  | Holds the configuration\.|

## Physical Memory Protection Config 1 Register 
### *AddressOffset*: 'h3A1 
### *Description*:
Holds configuration 4-7.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 31:24 | pmp7cfg | Physical memory protection 7 config | read-write  | Holds the configuration\.|
| 23:16 | pmp6cfg | Physical memory protection 6 config | read-write  | Holds the configuration\.|
| 15:8 | pmp5cfg | Physical memory protection 5 config | read-write  | Holds the configuration\.|
| 7:0 | pmp4cfg | Physical memory protection 4 config | read-write  | Holds the configuration\.|

## Physical Memory Protection Config 2 Register 
### *AddressOffset*: 'h3A2 
### *Description*:
Holds configuration 8-11.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 31:24 | pmp11cfg | Physical memory protection 11 config | read-write  | Holds the configuration\.|
| 23:16 | pmp10cfg | Physical memory protection 10 config | read-write  | Holds the configuration\.|
| 15:8 | pmp9cfg | Physical memory protection 9 config | read-write  | Holds the configuration\.|
| 7:0 | pmp8cfg | Physical memory protection 8 config | read-write  | Holds the configuration\.|

## Physical Memory Protection Config 3 Register 
### *AddressOffset*: 'h3A3 
### *Description*:
Holds configuration 12-15.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 31:24 | pmp15cfg | Physical memory protection 15 config | read-write  | Holds the configuration\.|
| 23:16 | pmp14cfg | Physical memory protection 14 config | read-write  | Holds the configuration\.|
| 15:8 | pmp13cfg | Physical memory protection 13 config | read-write  | Holds the configuration\.|
| 7:0 | pmp12cfg | Physical memory protection 12 config | read-write  | Holds the configuration\.|

## Physical Memory Protection Address Register 
### *AddressOffset*: 'h3B0 
### *Description*:
Address register for Physical Memory Protection.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 31:0 | address | Address | read-write,WARL  | Address register for Physical Memory Protection\.|

## Instruction Cache Register 
### *AddressOffset*: 'h7C0 
### *Description*:
Custom Register to enable/disable for Icache [bit 0]
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 0 | icache | Instruction cache | read-write  | Custom Register to enable/disable for Icache \[bit 0\]|

## Data Cache Register 
### *AddressOffset*: 'h7C1 
### *Description*:
Custom Register to enable/disable for Dcache [bit 0]
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 0 | dcache | Data cache | read-write  | Custom Register to enable/disable for Dcache \[bit 0\]|

## Trigger Select Register 
### *AddressOffset*: 'h7A0 
### *Description*:
This register determines which trigger is accessible through the other trigger registers.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 31:0 | index | Index | read-write  | This register determines which trigger is accessible through the other trigger registers\.|

## Trigger Data 1 Register 
### *AddressOffset*: 'h7A1 
### *Description*:
Trigger-specific data.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 31:28 | type | Type | read-write  | Type of trigger\. // ``Enumerated Values``( "no_trigger" :0 ) ( "legacy_address_match_trigger" :1 ) ( "address_data_match_trigger" :2 ) ( "instruction_count_trigger" :3 ) ( "interrupt_trigger" :4 ) ( "exception_trigger" :5 ) ( "Reserved_6" :6 ) ( "Reserved_7" :7 ) ( "Reserved_8" :8 ) ( "Reserved_9" :9 ) ( "Reserved_10" :10 ) ( "Reserved_11" :11 ) ( "Reserved_12" :12 ) ( "Reserved_13" :13 ) ( "Reserved_14" :14 ) ( "trigger_exists" :15 ) |
| 27 | dmode | Debug mode | read-write  | This bit is only writable from Debug Mode\. // ``Enumerated Values``( "D_and_M_mode" :0 ) ( "M_mode_only" :1 ) |
| 26:0 | data | Data | read-write  | Trigger\-specific data\.|

## Trigger Data 2 Register 
### *AddressOffset*: 'h7A2 
### *Description*:
Trigger-specific data.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 31:0 | data | Data | read-write  | Trigger\-specific data\.|

## Trigger Data 3 Register 
### *AddressOffset*: 'h7A3 
### *Description*:
Trigger-specific data.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 31:0 | data | Data | read-write  | Trigger\-specific data\.|

## Trigger Info Register 
### *AddressOffset*: 'h7A4 
### *Description*:
Shows trigger information.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 15:0 | info | Info | read-only  | Shows trigger information\.|

## Debug Control and Status Register 
### *AddressOffset*: 'h7B0 
### *Description*:
Debug control and status register.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 31:28 | xdebugver | Debug version | read-only  | Shows the version of the debug support\. // ``Enumerated Values``( "no_ext_debug" :0 ) ( "ext_debug_spec" :4 ) ( "ext_debug_no_spec" :15 ) |
| 15 | ebreakm | Environment breakpoint m-mode | read-write  | Shows the behavior of the ``ebreak`` instruction in machine mode\. // ``Enumerated Values``( "break_as_spec" :0 ) ( "break_to_debug" :1 ) |
| 13 | ebreaks | Environment breakpoint s-mode | read-write  | Shows the behavior of the ``ebreak`` instruction in supervisor mode\. // ``Enumerated Values``( "break_as_spec" :0 ) ( "break_to_debug" :1 ) |
| 12 | ebreaku | Environment breakpoint u-mode | read-write  | Shows the behavior of the ``ebreak`` instruction in user mode\. // ``Enumerated Values``( "break_as_spec" :0 ) ( "break_to_debug" :1 ) |
| 11 | stepie | Stepping interrupt enable | read-write,WARL  | Enables/disables interrupts for single stepping\.  The debugger must not change the value of this bit while the hart is running\. // ``Enumerated Values``( "disabled" :0 ) ( "enabled" :1 ) |
| 10 | stopcount | Stop counters | read-write,WARL  | Starts/stops incrementing counters in debug mode\. // ``Enumerated Values``( "increment_counters" :0 ) ( "dont_increment_counters" :1 ) |
| 9 | stoptime | Stop timers | read-write,WARL  | Starts/stops incrementing timers in debug mode\. // ``Enumerated Values``( "increment_timers" :0 ) ( "dont_increment_timers" :1 ) |
| 8:6 | cause | Cause | read-write  | Explains why Debug Mode was entered\.  When there are multiple reasons to enter Debug Mode in a single cycle, hardware sets ``cause`` to the cause with the highest priority\. // ``Enumerated Values``( "ebreak_instruction" :1 ) ( "trigger_module" :2 ) ( "debugger_request" :3 ) ( "single_step" :4 ) ( "reset_halt" :5 ) |
| 4 | mprven | Modify privilege enable | read-write,WARL  | Enables/disables the modify privilege setting in debug mode\. // ``Enumerated Values``( "disable_mprv" :0 ) ( "enable_mprv" :1 ) |
| 3 | nmip | Non-maskable interrupt pending | read-only  | When set, there is a Non\-Maskable\-Interrupt \(NMI\) pending for the hart\.|
| 2 | step | Step | read-write  | When set and not in Debug Mode, the hart will only execute a single instruction and then enter Debug Mode\. If the instruction does not complete due to an exception, the hart will immediately enter Debug Mode before executing the trap handler, with appropriate exception registers set\. The debugger must not change the value of this bit while the hart is running\.|
| 1:0 | prv | Privilege level | read-write  | Contains the privilege level the hart was operating in when Debug Mode was entered\. A debugger can change this value to change the hart’s privilege level when exiting Debug Mode\. // ``Enumerated Values``( "User" :0 ) ( "Supervisor" :1 ) ( "Machine" :3 ) |

## Debug PC Register 
### *AddressOffset*: 'h7B1 
### *Description*:
Upon entry to debug mode, ``dpc`` is updated with the virtual address of the next instruction to be executed.

When resuming, the hart’s PC is updated to the virtual address stored in ``dpc``. A debugger may write ``dpc`` to change where the hart resumes.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 31:0 | dpc |  | read-write  | Upon entry to debug mode, ``dpc`` is updated with the virtual address of the next instruction to be executed\.  When resuming, the hart’s PC is updated to the virtual address stored in ``dpc``\. A debugger may write ``dpc`` to change where the hart resumes\.|

## Debug Scratch Register Register 
### *AddressOffset*: 'h7B2 
### *Description*:
Optional scratch register. A debugger must not write to this register unless ``hartinfo`` explicitly mentions it.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 31:0 | dscratch |  | read-write  | Optional scratch register\. A debugger must not write to this register unless ``hartinfo`` explicitly mentions it\.|

##  Register 
### *AddressOffset*: 'h800 
### *Description*:
Floating Point Custom CSR
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 6:0 | ftran |  | read-write  | Floating Point Custom CSR|

## M-mode Cycle counter Register 
### *AddressOffset*: 'hB00 
### *Description*:
Counts the number of clock cycles executed by the processor core on which the hart is running.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | read-write  | Counts the number of clock cycles executed by the processor core on which the hart is running\.|

## Machine Instruction Retired counter Register 
### *AddressOffset*: 'hB02 
### *Description*:
Counts the number of instructions the hart has retired.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | read-write  | Counts the number of instructions the hart has retired\.|

## L1 Inst Cache Miss Register 
### *AddressOffset*: 'hB03 
### *Description*:
Hardware performance event counter.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | read-write  | Hardware performance event counter\.|

## L1 Data Cache Miss Register 
### *AddressOffset*: 'hB04 
### *Description*:
Hardware performance event counter.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | read-write  | Hardware performance event counter\.|

## ITLB Miss Register 
### *AddressOffset*: 'hB05 
### *Description*:
Hardware performance event counter.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | read-write  | Hardware performance event counter\.|

## DTLB Miss Register 
### *AddressOffset*: 'hB06 
### *Description*:
Hardware performance event counter.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | read-write  | Hardware performance event counter\.|

## Loads Register 
### *AddressOffset*: 'hB07 
### *Description*:
Hardware performance event counter.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | read-write  | Hardware performance event counter\.|

## Stores Register 
### *AddressOffset*: 'hB08 
### *Description*:
Hardware performance event counter.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | read-write  | Hardware performance event counter\.|

## Taken Exceptions Register 
### *AddressOffset*: 'hB09 
### *Description*:
Hardware performance event counter.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | read-write  | Hardware performance event counter\.|

## Exception Return Register 
### *AddressOffset*: 'hB0A 
### *Description*:
Hardware performance event counter.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | read-write  | Hardware performance event counter\.|

## Software Change of PC Register 
### *AddressOffset*: 'hB0B 
### *Description*:
Hardware performance event counter.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | read-write  | Hardware performance event counter\.|

## Procedure Call Register 
### *AddressOffset*: 'hB0C 
### *Description*:
Hardware performance event counter.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | read-write  | Hardware performance event counter\.|

## Procedure Return Register 
### *AddressOffset*: 'hB0D 
### *Description*:
Hardware performance event counter.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | read-write  | Hardware performance event counter\.|

## Branch mis-predicted Register 
### *AddressOffset*: 'hB0E 
### *Description*:
Hardware performance event counter.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | read-write  | Hardware performance event counter\.|

## Scoreboard Full Register 
### *AddressOffset*: 'hB0F 
### *Description*:
Hardware performance event counter.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | read-write  | Hardware performance event counter\.|

## Instruction Fetch Queue Empty Register 
### *AddressOffset*: 'hB10 
### *Description*:
Hardware performance event counter.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | read-write  | Hardware performance event counter\.|

## Upper 32-bits of M-mode Cycle counter Register 
### *AddressOffset*: 'hB80 
### *Description*:
Counts the number of clock cycles executed by the processor core on which the hart is running.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | read-write  | Counts the number of clock cycles executed by the processor core on which the hart is running\.|

## Upper 32-bits of Machine Instruction Retired counter Register 
### *AddressOffset*: 'hB82 
### *Description*:
Counts the number of instructions the hart has retired.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | read-write  | Counts the number of instructions the hart has retired\.|

## Upper 32-bits of Machine Hardware Performance Monitoring Counter Register 
### *AddressOffset*: 'hB83 
### *Description*:
Hardware performance event counter.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | read-write  | Hardware performance event counter\.|

## Cycle counter Register 
### *AddressOffset*: 'hC00 
### *Description*:
Cycle counter for RDCYCLE instruction.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | read-only  | Cycle counter for RDCYCLE instruction\.|

## Timer Register 
### *AddressOffset*: 'hC01 
### *Description*:
Timer for RDTIME instruction.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | read-only  | Timer for RDTIME instruction\.|

## Instruction Retired counter Register 
### *AddressOffset*: 'hC02 
### *Description*:
Instructions-retired counter for RDINSTRET instruction
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | read-only  | Instructions\-retired counter for RDINSTRET instruction|

## L1 Inst Cache Miss Register 
### *AddressOffset*: 'hC03 
### *Description*:
Hardware performance event counter.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | read-only  | Hardware performance event counter\.|

## L1 Data Cache Miss Register 
### *AddressOffset*: 'hC04 
### *Description*:
Hardware performance event counter.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | read-only  | Hardware performance event counter\.|

## ITLB Miss Register 
### *AddressOffset*: 'hC05 
### *Description*:
Hardware performance event counter.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | read-only  | Hardware performance event counter\.|

## DTLB Miss Register 
### *AddressOffset*: 'hC06 
### *Description*:
Hardware performance event counter.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | read-only  | Hardware performance event counter\.|

## Loads Register 
### *AddressOffset*: 'hC07 
### *Description*:
Hardware performance event counter.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | read-only  | Hardware performance event counter\.|

## Stores Register 
### *AddressOffset*: 'hC08 
### *Description*:
Hardware performance event counter.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | read-only  | Hardware performance event counter\.|

## Taken Exceptions Register 
### *AddressOffset*: 'hC09 
### *Description*:
Hardware performance event counter.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | read-only  | Hardware performance event counter\.|

## Exception Return Register 
### *AddressOffset*: 'hC0A 
### *Description*:
Hardware performance event counter.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | read-only  | Hardware performance event counter\.|

## Software Change of PC Register 
### *AddressOffset*: 'hC0B 
### *Description*:
Hardware performance event counter.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | read-only  | Hardware performance event counter\.|

## Procedure Call Register 
### *AddressOffset*: 'hC0C 
### *Description*:
Hardware performance event counter.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | read-only  | Hardware performance event counter\.|

## Procedure Return Register 
### *AddressOffset*: 'hC0D 
### *Description*:
Hardware performance event counter.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | read-only  | Hardware performance event counter\.|

## Branch mis-predicted Register 
### *AddressOffset*: 'hC0E 
### *Description*:
Hardware performance event counter.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | read-only  | Hardware performance event counter\.|

## Scoreboard Full Register 
### *AddressOffset*: 'hC0F 
### *Description*:
Hardware performance event counter.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | read-only  | Hardware performance event counter\.|

## Instruction Fetch Queue Empty Register 
### *AddressOffset*: 'hC10 
### *Description*:
Hardware performance event counter.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | read-only  | Hardware performance event counter\.|

## Upper 32-bits of Cycle counter Register 
### *AddressOffset*: 'hC80 
### *Description*:
Cycle counter for RDCYCLE instruction.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | read-only  | Cycle counter for RDCYCLE instruction\.|

## Upper 32-bit of Timer Register 
### *AddressOffset*: 'hC81 
### *Description*:
Timer for RDTIME instruction.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | read-only  | Timer for RDTIME instruction\.|

## Upper 32-bits of Instruction Retired counter Register 
### *AddressOffset*: 'hC82 
### *Description*:
Instructions-retired counter for RDINSTRET instruction
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | read-only  | Instructions\-retired counter for RDINSTRET instruction|

## Machine Vendor ID Register 
### *AddressOffset*: 'hF11 
### *Description*:
This register provides the JEDEC manufacturer ID of the provider of the core.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 31:7 | bank | Bank | read-only  | Contain encoding for number of one\-byte continuation codes discarding the parity bit\.|
| 6:0 | offset | Offset | read-only  | Contain encoding for the final byte discarding the parity bit\.|

## Machine Architecture ID Register 
### *AddressOffset*: 'hF12 
### *Description*:
This register encodes the base microarchitecture of the hart.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 31:0 | architecture_id | Architecture id | read-only  | This register encodes the base microarchitecture of the hart\.|

## Machine Implementation ID Register 
### *AddressOffset*: 'hF13 
### *Description*:
Provides a unique encoding of the version of the processor implementation.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 31:0 | implementation | Implementation | read-only  | Provides a unique encoding of the version of the processor implementation\.|

## Machine Hardware Thread ID Register 
### *AddressOffset*: 'hF14 
### *Description*:
This register contains the integer ID of the hardware thread running the code.
| BIT |  NAME       | displayName        | RIGHT  | Description                                                          |
| --- | ----------- | ------------       | ------ | -------------------------------------------------------------------- |
| 31:0 | hart_id | Hart id | read-only  | This register contains the integer ID of the hardware thread running the code\.|
