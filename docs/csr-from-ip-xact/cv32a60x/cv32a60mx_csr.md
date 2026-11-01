<!--
   Copyright (c) 2023 Thales Silicon Security
   SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
   Author: Mohamed Aziz FRIKHA
-->

# CSR REGISTERS : CV32A6 
### Unimplemented CSR accessing generates an illegal instruction exception.
### Read-Only CSR write access generates an illegal instruction exception.

## MSTATUS : Machine Status Register 
### *AddressOffset*: 'h300 
### *Description*:
The ``mstatus`` register keeps track of and controls the hart’s current operating state.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31 | SD | State dirty | 0x0 | read-only,WARL  | The SD bit is a read\-only bit\.``Legal Values``:0\. // ``Enumerated Values``( "Not_Dirty" :0 ) ( "Dirty" :1 ) |
| 30:23 | reserved_0 | Reserved | 0x0 | read-write,WPRI  | Reserved|
| 22 | TSR | Trap sret | 0x0 | read-write,WARL  | The TSR bit supports intercepting the supervisor exception return instruction, SRET\. // ``Enumerated Values``( "Permitted" :0 ) ( "Not_Permitted" :1 ) |
| 21 | TW | Timeout wait | 0x0 | read-write,WARL  | The TW bit supports intercepting the WFI instruction\. // ``Enumerated Values``( "Permitted" :0 ) ( "Not_Permitted" :1 ) |
| 20 | TVM | Trap virtual memory | 0x0 | read-write,WARL  | The TVM bit supports intercepting supervisor virtual\-memory management operations\. // ``Enumerated Values``( "Permitted" :0 ) ( "Not_Permitted" :1 ) |
| 19 | MXR | Make executable readable | 0x0 | read-write  | The MXR bit modifies the privilege with which loads access virtual memory\. // ``Enumerated Values``( "Not_Executable" :0 ) ( "Executable" :1 ) |
| 18 | SUM | Supervisor user memory | 0x0 | read-write  | The SUM bit modifies the privilege with which S\-mode loads and stores access virtual memory\. // ``Enumerated Values``( "Not_Permitted" :0 ) ( "Permitted" :1 ) |
| 17 | MPRV | Modify privilege | 0x0 | read-write  | The MPRV bit modifies the privilege mode at which loads and stores execute\. // ``Enumerated Values``( "Normal" :0 ) ( "Protected" :1 ) |
| 16:15 | XS | Extension state | 0x0 | read-only,WARL  | The XS field encodes the status of the additional user\-mode extensions and associated state\.``Legal Values``:0\. // ``Enumerated Values``( "Off" :0 ) ( "Initial" :1 ) ( "Clean" :2 ) ( "Dirty" :3 ) |
| 14:13 | FS | Floating-point unit state | 0x0 | read-only,WARL  | FS extension is not supported\.``Legal Values``:0\. // ``Enumerated Values``( "Off" :0 ) ( "Initial" :1 ) ( "Clean" :2 ) ( "Dirty" :3 ) |
| 12:11 | MPP | Machine mode prior privilege | 0x0 | read-write  | Holds the previous privilege mode for machine mode\. // ``Enumerated Values``( "U-mode" :0 ) ( "S-mode" :1 ) ( "Reserved" :2 ) ( "M-mode" :3 ) |
| 10:9 | VS | Vector extension state | 0x0 | read-only,WARL  | V extension is not supported\.``Legal Values``:0\.|
| 8 | SPP | Supervisor mode prior privilege | 0x0 | read-write  | Holds the previous privilege mode for supervisor mode\. // ``Enumerated Values``( "U-mode" :0 ) ( "Otherwise" :1 ) |
| 7 | MPIE | Machine mode prior interrupt enable | 0x0 | read-write  | Indicates whether machine interrupts were enabled prior to trapping into machine mode\. // ``Enumerated Values``( "Disabled" :0 ) ( "Enabled" :1 ) |
| 6 | UBE | User mode bit endianness | 0x0 | read-write,WARL  | UBE controls whether explicit load and store memory accesses made from U\-mode are little\-endian or big\-endian\.``Legal Values``:0\. // ``Enumerated Values``( "Little-endian" :0 ) ( "Big-endian" :1 ) |
| 5 | SPIE | Supervisor mode prior interrupt enable | 0x0 | read-write  | Indicates whether supervisor interrupts were enabled prior to trapping into supervisor mode\. // ``Enumerated Values``( "Disabled" :0 ) ( "Enabled" :1 ) |
| 4 | reserved_1 | Reserved | 0x0 | read-write,WPRI  | Reserved|
| 3 | MIE | Machine mode interrupt enable | 0x0 | read-write  | Global interrupt\-enable bit for Machine mode\. // ``Enumerated Values``( "Disabled" :0 ) ( "Enabled" :1 ) |
| 2 | reserved_2 | Reserved | 0x0 | read-write,WPRI  | Reserved|
| 1 | SIE | Supervisor mode interrupt enable | 0x0 | read-write  | Global interrupt\-enable bit for Supervisor mode\. // ``Enumerated Values``( "Disabled" :0 ) ( "Enabled" :1 ) |
| 0 | reserved_3 | Reserved | 0x0 | read-write,WPRI  | Reserved|

## MISA : Machine ISA Register 
### *AddressOffset*: 'h301 
### *Description*:
The misa CSR is reporting the ISA supported by the hart.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:30 | MXL | Machine xlen | 0x0 | read-write,WARL  | The MXL field encodes the native base integer ISA width\.``Legal Values``:1\. // ``Enumerated Values``( "XLEN_32" :1 ) ( "XLEN_64" :2 ) ( "XLEN_128" :3 ) |
| 29:26 | Reserved_26 | Reserved | 0x0 | read-write,WARL  | Reserved\.``Legal Values:``0\.|
| 25:0 | Extensions | Extensions | 0x141104 | read-write,WARL  | The Extensions field encodes the presence of the standard extensions, with a single bit per letter of the alphabet\.``Legal Values``:0x141104\. // ``Enumerated Values``( "A" :1 ) ( "B" :2 ) ( "C" :4 ) ( "D" :8 ) ( "E" :16 ) ( "F" :32 ) ( "G" :64 ) ( "H" :128 ) ( "I" :256 ) ( "J" :512 ) ( "K" :1024 ) ( "L" :2048 ) ( "M" :4096 ) ( "N" :8192 ) ( "O" :16384 ) ( "P" :32768 ) ( "Q" :65536 ) ( "R" :131072 ) ( "S" :262144 ) ( "T" :524288 ) ( "U" :1048576 ) ( "V" :2097152 ) ( "W" :4194304 ) ( "X" :8388608 ) ( "Y" :16777216 ) ( "Z" :33554432 ) |

## MIE : Machine Interrupt Enable Register 
### *AddressOffset*: 'h304 
### *Description*:
This register contains machine interrupt enable bits.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 15:12 | Reserved_12 | Reserved | 0x0 | read-write,WARL  | Reserved\.``Legal Values:``0\.|
| 11 | MEIE | M-mode external interrupt enable | 0x0 | read-write,WARL  | Enables machine mode external interrupts\.|
| 10 | Reserved_10 | Reserved | 0x0 | read-write,WARL  | Reserved\.``Legal Values:``0\.|
| 9 | SEIE | S-mode external interrupt enable | 0x0 | read-write,WARL  | Enables supervisor mode external interrupts\.|
| 8 | UEIE |  | 0x0 | read-write,WARL  | enables U\-mode external interrupts\.``Legal Values:``0\.|
| 7 | MTIE | M-mode timer interrupt enable | 0x0 | read-write,WARL  | Enables machine mode timer interrupts\.|
| 6 | Reserved_6 | Reserved | 0x0 | read-write,WARL  | Reserved\.``Legal Values:``0\.|
| 5 | STIE | S-mode timer interrupt enable | 0x0 | read-write,WARL  | Enables supervisor mode timer interrupts\.|
| 4 | UTIE |  | 0x0 | read-write,WARL  | timer interrupt\-enable bit for U\-mode\.``Legal Values:``0\.|
| 3 | MSIE | M-mode software interrupt enable | 0x0 | read-write  | Enables machine mode software interrupts\.|
| 2 | Reserved_2 | Reserved | 0x0 | read-write,WARL  | Reserved\.``Legal Values:``0\.|
| 1 | SSIE | S-mode software interrupt enable | 0x0 | read-write,WARL  | Enables supervisor mode software interrupts\.|
| 0 | USIE |  | 0x0 | read-write,WARL  | enable U\-mode software interrupts\.``Legal Values:``0\.|

## MTVEC : Machine Trap Vector Register 
### *AddressOffset*: 'h305 
### *Description*:
This register holds trap vector configuration, consisting of a vector base address and a vector mode.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:2 | BASE |  | 0x0 | read-write,WARL  | The BASE field in mtvec is a WARL field that can hold any valid virtual or physical address, subject to the following alignment constraints: when MODE=Direct the address must be 4\-byte aligned, and when MODE=Vectored the address must be 256\-byte aligned\.|
| 1:0 | MODE |  | 0x0 | read-write,WARL  | Imposes additional alignment constraints on the value in the BASE field\.``Legal Values :``0,1\. // ``Enumerated Values``( "Direct" :0 ) ( "Vectored" :1 ) ( "Reserved_2" :2 ) ( "Reserved_3" :3 ) |

## MSTATUSH : Upper 32-bits of Machine Status Register 
### *AddressOffset*: 'h310 
### *Description*:
The ``mstatush`` is the upper 32-bits of Machine status only for RV32.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 3:0 | reserved_0 | Reserved | 0x0 | read-write,WPRI  | Reserved|
| 4 | SBE | Supervisor mode bit endianness | 0x0 | read-write,WARL  | SBE controls whether explicit load and store memory accesses made from S\-mode are little\-endian or big\-endian\.``Legal Values``:0\. // ``Enumerated Values``( "Little-endian" :0 ) ( "Big-endian" :1 ) |
| 5 | MBE | Machine mode bit endianness | 0x0 | read-write,WARL  | MBE controls whether explicit load and store memory accesses made from M\-mode are little\-endian or big\-endian\.``Legal Values``:0\. // ``Enumerated Values``( "Little-endian" :0 ) ( "Big-endian" :1 ) |
| 31:6 | reserved_1 | Reserved | 0x0 | read-write,WPRI  | Reserved|

## MHPMEVENT3 : Machine Hardware Performance-Monitoring Event Selector Register 
### *AddressOffset*: 'h323 
### *Description*:
This register controls which event causes the corresponding counter to increment.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | mhpmevent |  | 0x0 | WARL  | Event selector CSRs\.``Legal Values``:0\.|

## MHPMEVENT4 : Machine Hardware Performance-Monitoring Event Selector Register 
### *AddressOffset*: 'h324 
### *Description*:
This register controls which event causes the corresponding counter to increment.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | mhpmevent |  | 0x0 | WARL  | Event selector CSRs\.``Legal Values``:0\.|

## MHPMEVENT5 : Machine Hardware Performance-Monitoring Event Selector Register 
### *AddressOffset*: 'h325 
### *Description*:
This register controls which event causes the corresponding counter to increment.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | mhpmevent |  | 0x0 | WARL  | Event selector CSRs\.``Legal Values``:0\.|

## MHPMEVENT6 : Machine Hardware Performance-Monitoring Event Selector Register 
### *AddressOffset*: 'h326 
### *Description*:
This register controls which event causes the corresponding counter to increment.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | mhpmevent |  | 0x0 | WARL  | Event selector CSRs\.``Legal Values``:0\.|

## MHPMEVENT7 : Machine Hardware Performance-Monitoring Event Selector Register 
### *AddressOffset*: 'h327 
### *Description*:
This register controls which event causes the corresponding counter to increment.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | mhpmevent |  | 0x0 | WARL  | Event selector CSRs\.``Legal Values``:0\.|

## MHPMEVENT8 : Machine Hardware Performance-Monitoring Event Selector Register 
### *AddressOffset*: 'h328 
### *Description*:
This register controls which event causes the corresponding counter to increment.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | mhpmevent |  | 0x0 | WARL  | Event selector CSRs\.``Legal Values``:0\.|

## MHPMEVENT9 : Machine Hardware Performance-Monitoring Event Selector Register 
### *AddressOffset*: 'h329 
### *Description*:
This register controls which event causes the corresponding counter to increment.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | mhpmevent |  | 0x0 | WARL  | Event selector CSRs\.``Legal Values``:0\.|

## MHPMEVENT10 : Machine Hardware Performance-Monitoring Event Selector Register 
### *AddressOffset*: 'h32a 
### *Description*:
This register controls which event causes the corresponding counter to increment.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | mhpmevent |  | 0x0 | WARL  | Event selector CSRs\.``Legal Values``:0\.|

## MHPMEVENT11 : Machine Hardware Performance-Monitoring Event Selector Register 
### *AddressOffset*: 'h32b 
### *Description*:
This register controls which event causes the corresponding counter to increment.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | mhpmevent |  | 0x0 | WARL  | Event selector CSRs\.``Legal Values``:0\.|

## MHPMEVENT12 : Machine Hardware Performance-Monitoring Event Selector Register 
### *AddressOffset*: 'h32c 
### *Description*:
This register controls which event causes the corresponding counter to increment.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | mhpmevent |  | 0x0 | WARL  | Event selector CSRs\.``Legal Values``:0\.|

## MHPMEVENT13 : Machine Hardware Performance-Monitoring Event Selector Register 
### *AddressOffset*: 'h32d 
### *Description*:
This register controls which event causes the corresponding counter to increment.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | mhpmevent |  | 0x0 | WARL  | Event selector CSRs\.``Legal Values``:0\.|

## MHPMEVENT14 : Machine Hardware Performance-Monitoring Event Selector Register 
### *AddressOffset*: 'h32e 
### *Description*:
This register controls which event causes the corresponding counter to increment.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | mhpmevent |  | 0x0 | WARL  | Event selector CSRs\.``Legal Values``:0\.|

## MHPMEVENT15 : Machine Hardware Performance-Monitoring Event Selector Register 
### *AddressOffset*: 'h32f 
### *Description*:
This register controls which event causes the corresponding counter to increment.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | mhpmevent |  | 0x0 | WARL  | Event selector CSRs\.``Legal Values``:0\.|

## MHPMEVENT16 : Machine Hardware Performance-Monitoring Event Selector Register 
### *AddressOffset*: 'h330 
### *Description*:
This register controls which event causes the corresponding counter to increment.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | mhpmevent |  | 0x0 | WARL  | Event selector CSRs\.``Legal Values``:0\.|

## MHPMEVENT17 : Machine Hardware Performance-Monitoring Event Selector Register 
### *AddressOffset*: 'h331 
### *Description*:
This register controls which event causes the corresponding counter to increment.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | mhpmevent |  | 0x0 | WARL  | Event selector CSRs\.``Legal Values``:0\.|

## MHPMEVENT18 : Machine Hardware Performance-Monitoring Event Selector Register 
### *AddressOffset*: 'h332 
### *Description*:
This register controls which event causes the corresponding counter to increment.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | mhpmevent |  | 0x0 | WARL  | Event selector CSRs\.``Legal Values``:0\.|

## MHPMEVENT19 : Machine Hardware Performance-Monitoring Event Selector Register 
### *AddressOffset*: 'h333 
### *Description*:
This register controls which event causes the corresponding counter to increment.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | mhpmevent |  | 0x0 | WARL  | Event selector CSRs\.``Legal Values``:0\.|

## MHPMEVENT20 : Machine Hardware Performance-Monitoring Event Selector Register 
### *AddressOffset*: 'h334 
### *Description*:
This register controls which event causes the corresponding counter to increment.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | mhpmevent |  | 0x0 | WARL  | Event selector CSRs\.``Legal Values``:0\.|

## MHPMEVENT21 : Machine Hardware Performance-Monitoring Event Selector Register 
### *AddressOffset*: 'h335 
### *Description*:
This register controls which event causes the corresponding counter to increment.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | mhpmevent |  | 0x0 | WARL  | Event selector CSRs\.``Legal Values``:0\.|

## MHPMEVENT22 : Machine Hardware Performance-Monitoring Event Selector Register 
### *AddressOffset*: 'h336 
### *Description*:
This register controls which event causes the corresponding counter to increment.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | mhpmevent |  | 0x0 | WARL  | Event selector CSRs\.``Legal Values``:0\.|

## MHPMEVENT23 : Machine Hardware Performance-Monitoring Event Selector Register 
### *AddressOffset*: 'h337 
### *Description*:
This register controls which event causes the corresponding counter to increment.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | mhpmevent |  | 0x0 | WARL  | Event selector CSRs\.``Legal Values``:0\.|

## MHPMEVENT24 : Machine Hardware Performance-Monitoring Event Selector Register 
### *AddressOffset*: 'h338 
### *Description*:
This register controls which event causes the corresponding counter to increment.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | mhpmevent |  | 0x0 | WARL  | Event selector CSRs\.``Legal Values``:0\.|

## MHPMEVENT25 : Machine Hardware Performance-Monitoring Event Selector Register 
### *AddressOffset*: 'h339 
### *Description*:
This register controls which event causes the corresponding counter to increment.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | mhpmevent |  | 0x0 | WARL  | Event selector CSRs\.``Legal Values``:0\.|

## MHPMEVENT26 : Machine Hardware Performance-Monitoring Event Selector Register 
### *AddressOffset*: 'h33a 
### *Description*:
This register controls which event causes the corresponding counter to increment.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | mhpmevent |  | 0x0 | WARL  | Event selector CSRs\.``Legal Values``:0\.|

## MHPMEVENT27 : Machine Hardware Performance-Monitoring Event Selector Register 
### *AddressOffset*: 'h33b 
### *Description*:
This register controls which event causes the corresponding counter to increment.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | mhpmevent |  | 0x0 | WARL  | Event selector CSRs\.``Legal Values``:0\.|

## MHPMEVENT28 : Machine Hardware Performance-Monitoring Event Selector Register 
### *AddressOffset*: 'h33c 
### *Description*:
This register controls which event causes the corresponding counter to increment.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | mhpmevent |  | 0x0 | WARL  | Event selector CSRs\.``Legal Values``:0\.|

## MHPMEVENT29 : Machine Hardware Performance-Monitoring Event Selector Register 
### *AddressOffset*: 'h33d 
### *Description*:
This register controls which event causes the corresponding counter to increment.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | mhpmevent |  | 0x0 | WARL  | Event selector CSRs\.``Legal Values``:0\.|

## MHPMEVENT30 : Machine Hardware Performance-Monitoring Event Selector Register 
### *AddressOffset*: 'h33e 
### *Description*:
This register controls which event causes the corresponding counter to increment.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | mhpmevent |  | 0x0 | WARL  | Event selector CSRs\.``Legal Values``:0\.|

## MHPMEVENT31 : Machine Hardware Performance-Monitoring Event Selector Register 
### *AddressOffset*: 'h33f 
### *Description*:
This register controls which event causes the corresponding counter to increment.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | mhpmevent |  | 0x0 | WARL  | Event selector CSRs\.``Legal Values``:0\.|

## MSCRATCH : Machine Scratch Register 
### *AddressOffset*: 'h340 
### *Description*:
This register is used to hold a value dedicated to Machine mode. Attempts to access without Machine mode level raise illegal instruction exception.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | mscratch | Machine scratch | 0x0 | read-write  | Holds a value dedicated to Machine mode\.|

## MEPC : Machine Exception Program Counter Register 
### *AddressOffset*: 'h341 
### *Description*:
This register must be able to hold all valid virtual addresses.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | mepc | Machine exception program counter | 0x0 | read-write,WARL  | When a trap is taken into M\-mode, ``mepc`` is written with the virtual address of the instruction that was interrupted or that encountered the exception\.|

## MCAUSE : Machine Cause Register 
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

| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31 | Interrupt | Interrupt | 0x0 | read-write  | This bit is set if the trap was caused by an interrupt\.|
| 30:0 | exception_code | Exception code | 0x0 | read-write,WLRL  | This field contains a code identifying the last exception or interrupt\.|

## MTVAL : Machine Trap Value Register 
### *AddressOffset*: 'h343 
### *Description*:
When a trap is taken into M-mode, mtval is either set to zero or written with exception-specific information to assist software in handling the trap.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | mtval | Machine trap value | 0x0 | read-write,WARL  | If ``mtval`` is written with a nonzero value when a breakpoint, address\-misaligned, access\-fault, or page\-fault exception occurs on an instruction fetch, load, or store, then mtval will contain the faulting virtual address\. If ``mtval`` is written with a nonzero value when a misaligned load or store causes an access\-fault or page\-fault exception, then ``mtval`` will contain the virtual address of the portion of the access that caused the fault\. If ``mtval`` is written with a nonzero value when an instruction access\-fault or page\-fault exception occurs on a system with variable\-length instructions, then ``mtval`` will contain the virtual address of the portion of the instruction that caused the fault, while ``mepc`` will point to the beginning of the instruction\.|

## MIP : Machine Interrupt Pending Register 
### *AddressOffset*: 'h344 
### *Description*:
This register contains machine interrupt pending bits.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 15:12 | Reserved_12 | Reserved | 0x0 | read-write,WARL  | Reserved\.``Legal Values:``0\.|
| 11 | MEIP | M-mode external interrupt pending | 0x0 | read-only  | The interrupt\-pending bit for machine\-level external interrupts\.|
| 10 | Reserved_10 | Reserved | 0x0 | read-write,WARL  | Reserved\.``Legal Values:``0\.|
| 9 | SEIP | S-mode external interrupt pending | 0x0 | read-write  | The interrupt\-pending bit for supervisor\-level external interrupts\.|
| 8 | UEIP |  | 0x0 | read-write  | enables external interrupts\.``Legal Values:``0\.|
| 7 | MTIP | M-mode timer interrupt pending | 0x0 | read-only  | The interrupt\-pending bit for machine\-level timer interrupts\.|
| 6 | Reserved_6 | Reserved | 0x0 | read-write,WARL  | Reserved\.``Legal Values:``0\.|
| 5 | STIP | S-mode timer interrupt pending | 0x0 | read-write  | The interrupt\-pending bit for supervisor\-level timer interrupts\.|
| 4 | UTIP |  | 0x0 | read-write  | Correspond to timer interrupt\-pending bits for user interrupt\.``Legal Values:``0\.|
| 3 | MSIP | M-mode software interrupt pending | 0x0 | read-only  | The interrupt\-pending bit for machine\-level software interrupts\.|
| 2 | Reserved_2 | Reserved | 0x0 | read-write,WARL  | Reserved\.``Legal Values:``0\.|
| 1 | SSIP | S-mode software interrupt pending | 0x0 | read-write  | The interrupt\-pending bit for supervisor\-level software interrupts\.|
| 0 | USIP |  | 0x0 | read-write  | A hart to directly write its own USIP bits when running in the appropriate mode\.``Legal Values:``0\.|

## PMPCFG0 : Physical Memory Protection Config 0 Register 
### *AddressOffset*: 'h3a0 
### *Description*:
Holds configuration 0-3.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:24 | pmp3cfg | Physical memory protection 3 config | 0x0 | read-write  | Holds the configuration\.|
| 23:16 | pmp2cfg | Physical memory protection 2 config | 0x0 | read-write  | Holds the configuration\.|
| 15:8 | pmp1cfg | Physical memory protection 1 config | 0x0 | read-write  | Holds the configuration\.|
| 7:0 | pmp0cfg | Physical memory protection 0 config | 0x0 | read-write  | Holds the configuration\.|

## PMPCFG1 : Physical Memory Protection Config 1 Register 
### *AddressOffset*: 'h3a1 
### *Description*:
Holds configuration 4-7.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:24 | pmp7cfg | Physical memory protection 7 config | 0x0 | read-write  | Holds the configuration\.|
| 23:16 | pmp6cfg | Physical memory protection 6 config | 0x0 | read-write  | Holds the configuration\.|
| 15:8 | pmp5cfg | Physical memory protection 5 config | 0x0 | read-write  | Holds the configuration\.|
| 7:0 | pmp4cfg | Physical memory protection 4 config | 0x0 | read-write  | Holds the configuration\.|

## PMPCFG2 : Physical Memory Protection Config 2 Register 
### *AddressOffset*: 'h3a2 
### *Description*:
Holds configuration 8-11.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:24 | pmp11cfg | Physical memory protection 11 config | 0x0 | read-write  | Holds the configuration\.|
| 23:16 | pmp10cfg | Physical memory protection 10 config | 0x0 | read-write  | Holds the configuration\.|
| 15:8 | pmp9cfg | Physical memory protection 9 config | 0x0 | read-write  | Holds the configuration\.|
| 7:0 | pmp8cfg | Physical memory protection 8 config | 0x0 | read-write  | Holds the configuration\.|

## PMPCFG3 : Physical Memory Protection Config 3 Register 
### *AddressOffset*: 'h3a3 
### *Description*:
Holds configuration 12-15.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:24 | pmp15cfg | Physical memory protection 15 config | 0x0 | read-write  | Holds the configuration\.|
| 23:16 | pmp14cfg | Physical memory protection 14 config | 0x0 | read-write  | Holds the configuration\.|
| 15:8 | pmp13cfg | Physical memory protection 13 config | 0x0 | read-write  | Holds the configuration\.|
| 7:0 | pmp12cfg | Physical memory protection 12 config | 0x0 | read-write  | Holds the configuration\.|

## PMPADDR0 : Physical Memory Protection Address Register 
### *AddressOffset*: 'h3b0 
### *Description*:
Address register for Physical Memory Protection.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | address | Address | 0x0 | read-write,WARL  | Encodes bits 33\-2 of a 34\-bit physical address\.|

## PMPADDR1 : Physical Memory Protection Address Register 
### *AddressOffset*: 'h3b1 
### *Description*:
Address register for Physical Memory Protection.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | address | Address | 0x0 | read-write,WARL  | Encodes bits 33\-2 of a 34\-bit physical address\.|

## PMPADDR2 : Physical Memory Protection Address Register 
### *AddressOffset*: 'h3b2 
### *Description*:
Address register for Physical Memory Protection.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | address | Address | 0x0 | read-write,WARL  | Encodes bits 33\-2 of a 34\-bit physical address\.|

## PMPADDR3 : Physical Memory Protection Address Register 
### *AddressOffset*: 'h3b3 
### *Description*:
Address register for Physical Memory Protection.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | address | Address | 0x0 | read-write,WARL  | Encodes bits 33\-2 of a 34\-bit physical address\.|

## PMPADDR4 : Physical Memory Protection Address Register 
### *AddressOffset*: 'h3b4 
### *Description*:
Address register for Physical Memory Protection.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | address | Address | 0x0 | read-write,WARL  | Encodes bits 33\-2 of a 34\-bit physical address\.|

## PMPADDR5 : Physical Memory Protection Address Register 
### *AddressOffset*: 'h3b5 
### *Description*:
Address register for Physical Memory Protection.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | address | Address | 0x0 | read-write,WARL  | Encodes bits 33\-2 of a 34\-bit physical address\.|

## PMPADDR6 : Physical Memory Protection Address Register 
### *AddressOffset*: 'h3b6 
### *Description*:
Address register for Physical Memory Protection.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | address | Address | 0x0 | read-write,WARL  | Encodes bits 33\-2 of a 34\-bit physical address\.|

## PMPADDR7 : Physical Memory Protection Address Register 
### *AddressOffset*: 'h3b7 
### *Description*:
Address register for Physical Memory Protection.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | address | Address | 0x0 | read-write,WARL  | Encodes bits 33\-2 of a 34\-bit physical address\.|

## PMPADDR8 : Physical Memory Protection Address Register 
### *AddressOffset*: 'h3b8 
### *Description*:
Address register for Physical Memory Protection.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | address | Address | 0x0 | read-write,WARL  | Encodes bits 33\-2 of a 34\-bit physical address\.|

## PMPADDR9 : Physical Memory Protection Address Register 
### *AddressOffset*: 'h3b9 
### *Description*:
Address register for Physical Memory Protection.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | address | Address | 0x0 | read-write,WARL  | Encodes bits 33\-2 of a 34\-bit physical address\.|

## PMPADDR10 : Physical Memory Protection Address Register 
### *AddressOffset*: 'h3ba 
### *Description*:
Address register for Physical Memory Protection.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | address | Address | 0x0 | read-write,WARL  | Encodes bits 33\-2 of a 34\-bit physical address\.|

## PMPADDR11 : Physical Memory Protection Address Register 
### *AddressOffset*: 'h3bb 
### *Description*:
Address register for Physical Memory Protection.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | address | Address | 0x0 | read-write,WARL  | Encodes bits 33\-2 of a 34\-bit physical address\.|

## PMPADDR12 : Physical Memory Protection Address Register 
### *AddressOffset*: 'h3bc 
### *Description*:
Address register for Physical Memory Protection.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | address | Address | 0x0 | read-write,WARL  | Encodes bits 33\-2 of a 34\-bit physical address\.|

## PMPADDR13 : Physical Memory Protection Address Register 
### *AddressOffset*: 'h3bd 
### *Description*:
Address register for Physical Memory Protection.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | address | Address | 0x0 | read-write,WARL  | Encodes bits 33\-2 of a 34\-bit physical address\.|

## PMPADDR14 : Physical Memory Protection Address Register 
### *AddressOffset*: 'h3be 
### *Description*:
Address register for Physical Memory Protection.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | address | Address | 0x0 | read-write,WARL  | Encodes bits 33\-2 of a 34\-bit physical address\.|

## PMPADDR15 : Physical Memory Protection Address Register 
### *AddressOffset*: 'h3bf 
### *Description*:
Address register for Physical Memory Protection.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | address | Address | 0x0 | read-write,WARL  | Encodes bits 33\-2 of a 34\-bit physical address\.|

## ICACHE : Instruction Cache Register 
### *AddressOffset*: 'h7C0 
### *Description*:
Custom Register to enable/disable for Icache [bit 0]
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:1 | reserved_0 | Reserved | 0x0 | read-only  | Reserved|
| 0 | icache | Instruction cache | 0x1 | read-write  | Custom Register|

## MCYCLE : M-mode Cycle counter Register 
### *AddressOffset*: 'hB00 
### *Description*:
Counts the number of clock cycles executed by the processor core on which the hart is running.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | 0x0 | read-write  | Counts the number of clock cycles executed by the processor core\.|

## MINSTRET : Machine Instruction Retired counter Register 
### *AddressOffset*: 'hB02 
### *Description*:
Counts the number of instructions the hart has retired.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | 0x0 | read-write  | Counts the number of instructions the hart has retired\.|

## MCYCLEH : Upper 32-bits of M-mode Cycle counter Register 
### *AddressOffset*: 'hB80 
### *Description*:
Counts the number of clock cycles executed by the processor core on which the hart is running.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | 0x0 | read-write  | Counts the number of clock cycles executed by the processor core\.|

## MINSTRETH : Upper 32-bits of Machine Instruction Retired counter Register 
### *AddressOffset*: 'hB82 
### *Description*:
Counts the number of instructions the hart has retired.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | 0x0 | read-write  | Counts the number of instructions the hart has retired\.|

## MHPMCOUNTER3 : Machine Hardware Performance Monitoring Counter Register 
### *AddressOffset*: 'hb03 
### *Description*:
Hardware performance event counter.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | 0x0 | WARL  | ``Legal Values``: 0\.|

## MHPMCOUNTER4 : Machine Hardware Performance Monitoring Counter Register 
### *AddressOffset*: 'hb04 
### *Description*:
Hardware performance event counter.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | 0x0 | WARL  | ``Legal Values``: 0\.|

## MHPMCOUNTER5 : Machine Hardware Performance Monitoring Counter Register 
### *AddressOffset*: 'hb05 
### *Description*:
Hardware performance event counter.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | 0x0 | WARL  | ``Legal Values``: 0\.|

## MHPMCOUNTER6 : Machine Hardware Performance Monitoring Counter Register 
### *AddressOffset*: 'hb06 
### *Description*:
Hardware performance event counter.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | 0x0 | WARL  | ``Legal Values``: 0\.|

## MHPMCOUNTER7 : Machine Hardware Performance Monitoring Counter Register 
### *AddressOffset*: 'hb07 
### *Description*:
Hardware performance event counter.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | 0x0 | WARL  | ``Legal Values``: 0\.|

## MHPMCOUNTER8 : Machine Hardware Performance Monitoring Counter Register 
### *AddressOffset*: 'hb08 
### *Description*:
Hardware performance event counter.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | 0x0 | WARL  | ``Legal Values``: 0\.|

## MHPMCOUNTER9 : Machine Hardware Performance Monitoring Counter Register 
### *AddressOffset*: 'hb09 
### *Description*:
Hardware performance event counter.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | 0x0 | WARL  | ``Legal Values``: 0\.|

## MHPMCOUNTER10 : Machine Hardware Performance Monitoring Counter Register 
### *AddressOffset*: 'hb0a 
### *Description*:
Hardware performance event counter.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | 0x0 | WARL  | ``Legal Values``: 0\.|

## MHPMCOUNTER11 : Machine Hardware Performance Monitoring Counter Register 
### *AddressOffset*: 'hb0b 
### *Description*:
Hardware performance event counter.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | 0x0 | WARL  | ``Legal Values``: 0\.|

## MHPMCOUNTER12 : Machine Hardware Performance Monitoring Counter Register 
### *AddressOffset*: 'hb0c 
### *Description*:
Hardware performance event counter.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | 0x0 | WARL  | ``Legal Values``: 0\.|

## MHPMCOUNTER13 : Machine Hardware Performance Monitoring Counter Register 
### *AddressOffset*: 'hb0d 
### *Description*:
Hardware performance event counter.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | 0x0 | WARL  | ``Legal Values``: 0\.|

## MHPMCOUNTER14 : Machine Hardware Performance Monitoring Counter Register 
### *AddressOffset*: 'hb0e 
### *Description*:
Hardware performance event counter.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | 0x0 | WARL  | ``Legal Values``: 0\.|

## MHPMCOUNTER15 : Machine Hardware Performance Monitoring Counter Register 
### *AddressOffset*: 'hb0f 
### *Description*:
Hardware performance event counter.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | 0x0 | WARL  | ``Legal Values``: 0\.|

## MHPMCOUNTER16 : Machine Hardware Performance Monitoring Counter Register 
### *AddressOffset*: 'hb10 
### *Description*:
Hardware performance event counter.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | 0x0 | WARL  | ``Legal Values``: 0\.|

## MHPMCOUNTER17 : Machine Hardware Performance Monitoring Counter Register 
### *AddressOffset*: 'hb11 
### *Description*:
Hardware performance event counter.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | 0x0 | WARL  | ``Legal Values``: 0\.|

## MHPMCOUNTER18 : Machine Hardware Performance Monitoring Counter Register 
### *AddressOffset*: 'hb12 
### *Description*:
Hardware performance event counter.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | 0x0 | WARL  | ``Legal Values``: 0\.|

## MHPMCOUNTER19 : Machine Hardware Performance Monitoring Counter Register 
### *AddressOffset*: 'hb13 
### *Description*:
Hardware performance event counter.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | 0x0 | WARL  | ``Legal Values``: 0\.|

## MHPMCOUNTER20 : Machine Hardware Performance Monitoring Counter Register 
### *AddressOffset*: 'hb14 
### *Description*:
Hardware performance event counter.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | 0x0 | WARL  | ``Legal Values``: 0\.|

## MHPMCOUNTER21 : Machine Hardware Performance Monitoring Counter Register 
### *AddressOffset*: 'hb15 
### *Description*:
Hardware performance event counter.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | 0x0 | WARL  | ``Legal Values``: 0\.|

## MHPMCOUNTER22 : Machine Hardware Performance Monitoring Counter Register 
### *AddressOffset*: 'hb16 
### *Description*:
Hardware performance event counter.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | 0x0 | WARL  | ``Legal Values``: 0\.|

## MHPMCOUNTER23 : Machine Hardware Performance Monitoring Counter Register 
### *AddressOffset*: 'hb17 
### *Description*:
Hardware performance event counter.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | 0x0 | WARL  | ``Legal Values``: 0\.|

## MHPMCOUNTER24 : Machine Hardware Performance Monitoring Counter Register 
### *AddressOffset*: 'hb18 
### *Description*:
Hardware performance event counter.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | 0x0 | WARL  | ``Legal Values``: 0\.|

## MHPMCOUNTER25 : Machine Hardware Performance Monitoring Counter Register 
### *AddressOffset*: 'hb19 
### *Description*:
Hardware performance event counter.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | 0x0 | WARL  | ``Legal Values``: 0\.|

## MHPMCOUNTER26 : Machine Hardware Performance Monitoring Counter Register 
### *AddressOffset*: 'hb1a 
### *Description*:
Hardware performance event counter.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | 0x0 | WARL  | ``Legal Values``: 0\.|

## MHPMCOUNTER27 : Machine Hardware Performance Monitoring Counter Register 
### *AddressOffset*: 'hb1b 
### *Description*:
Hardware performance event counter.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | 0x0 | WARL  | ``Legal Values``: 0\.|

## MHPMCOUNTER28 : Machine Hardware Performance Monitoring Counter Register 
### *AddressOffset*: 'hb1c 
### *Description*:
Hardware performance event counter.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | 0x0 | WARL  | ``Legal Values``: 0\.|

## MHPMCOUNTER29 : Machine Hardware Performance Monitoring Counter Register 
### *AddressOffset*: 'hb1d 
### *Description*:
Hardware performance event counter.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | 0x0 | WARL  | ``Legal Values``: 0\.|

## MHPMCOUNTER30 : Machine Hardware Performance Monitoring Counter Register 
### *AddressOffset*: 'hb1e 
### *Description*:
Hardware performance event counter.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | 0x0 | WARL  | ``Legal Values``: 0\.|

## MHPMCOUNTER31 : Machine Hardware Performance Monitoring Counter Register 
### *AddressOffset*: 'hb1f 
### *Description*:
Hardware performance event counter.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | 0x0 | WARL  | ``Legal Values``: 0\.|

## MHPMCOUNTERH3 : Upper 32 bits of Machine Hardware Performance Monitoring Counter Register 
### *AddressOffset*: 'hb83 
### *Description*:
Hardware performance event counter only for RV32.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | 0x0 | WARL  | ``Legal Values``: 0\.|

## MHPMCOUNTERH4 : Upper 32 bits of Machine Hardware Performance Monitoring Counter Register 
### *AddressOffset*: 'hb84 
### *Description*:
Hardware performance event counter only for RV32.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | 0x0 | WARL  | ``Legal Values``: 0\.|

## MHPMCOUNTERH5 : Upper 32 bits of Machine Hardware Performance Monitoring Counter Register 
### *AddressOffset*: 'hb85 
### *Description*:
Hardware performance event counter only for RV32.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | 0x0 | WARL  | ``Legal Values``: 0\.|

## MHPMCOUNTERH6 : Upper 32 bits of Machine Hardware Performance Monitoring Counter Register 
### *AddressOffset*: 'hb86 
### *Description*:
Hardware performance event counter only for RV32.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | 0x0 | WARL  | ``Legal Values``: 0\.|

## MHPMCOUNTERH7 : Upper 32 bits of Machine Hardware Performance Monitoring Counter Register 
### *AddressOffset*: 'hb87 
### *Description*:
Hardware performance event counter only for RV32.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | 0x0 | WARL  | ``Legal Values``: 0\.|

## MHPMCOUNTERH8 : Upper 32 bits of Machine Hardware Performance Monitoring Counter Register 
### *AddressOffset*: 'hb88 
### *Description*:
Hardware performance event counter only for RV32.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | 0x0 | WARL  | ``Legal Values``: 0\.|

## MHPMCOUNTERH9 : Upper 32 bits of Machine Hardware Performance Monitoring Counter Register 
### *AddressOffset*: 'hb89 
### *Description*:
Hardware performance event counter only for RV32.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | 0x0 | WARL  | ``Legal Values``: 0\.|

## MHPMCOUNTERH10 : Upper 32 bits of Machine Hardware Performance Monitoring Counter Register 
### *AddressOffset*: 'hb8a 
### *Description*:
Hardware performance event counter only for RV32.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | 0x0 | WARL  | ``Legal Values``: 0\.|

## MHPMCOUNTERH11 : Upper 32 bits of Machine Hardware Performance Monitoring Counter Register 
### *AddressOffset*: 'hb8b 
### *Description*:
Hardware performance event counter only for RV32.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | 0x0 | WARL  | ``Legal Values``: 0\.|

## MHPMCOUNTERH12 : Upper 32 bits of Machine Hardware Performance Monitoring Counter Register 
### *AddressOffset*: 'hb8c 
### *Description*:
Hardware performance event counter only for RV32.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | 0x0 | WARL  | ``Legal Values``: 0\.|

## MHPMCOUNTERH13 : Upper 32 bits of Machine Hardware Performance Monitoring Counter Register 
### *AddressOffset*: 'hb8d 
### *Description*:
Hardware performance event counter only for RV32.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | 0x0 | WARL  | ``Legal Values``: 0\.|

## MHPMCOUNTERH14 : Upper 32 bits of Machine Hardware Performance Monitoring Counter Register 
### *AddressOffset*: 'hb8e 
### *Description*:
Hardware performance event counter only for RV32.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | 0x0 | WARL  | ``Legal Values``: 0\.|

## MHPMCOUNTERH15 : Upper 32 bits of Machine Hardware Performance Monitoring Counter Register 
### *AddressOffset*: 'hb8f 
### *Description*:
Hardware performance event counter only for RV32.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | 0x0 | WARL  | ``Legal Values``: 0\.|

## MHPMCOUNTERH16 : Upper 32 bits of Machine Hardware Performance Monitoring Counter Register 
### *AddressOffset*: 'hb90 
### *Description*:
Hardware performance event counter only for RV32.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | 0x0 | WARL  | ``Legal Values``: 0\.|

## MHPMCOUNTERH17 : Upper 32 bits of Machine Hardware Performance Monitoring Counter Register 
### *AddressOffset*: 'hb91 
### *Description*:
Hardware performance event counter only for RV32.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | 0x0 | WARL  | ``Legal Values``: 0\.|

## MHPMCOUNTERH18 : Upper 32 bits of Machine Hardware Performance Monitoring Counter Register 
### *AddressOffset*: 'hb92 
### *Description*:
Hardware performance event counter only for RV32.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | 0x0 | WARL  | ``Legal Values``: 0\.|

## MHPMCOUNTERH19 : Upper 32 bits of Machine Hardware Performance Monitoring Counter Register 
### *AddressOffset*: 'hb93 
### *Description*:
Hardware performance event counter only for RV32.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | 0x0 | WARL  | ``Legal Values``: 0\.|

## MHPMCOUNTERH20 : Upper 32 bits of Machine Hardware Performance Monitoring Counter Register 
### *AddressOffset*: 'hb94 
### *Description*:
Hardware performance event counter only for RV32.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | 0x0 | WARL  | ``Legal Values``: 0\.|

## MHPMCOUNTERH21 : Upper 32 bits of Machine Hardware Performance Monitoring Counter Register 
### *AddressOffset*: 'hb95 
### *Description*:
Hardware performance event counter only for RV32.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | 0x0 | WARL  | ``Legal Values``: 0\.|

## MHPMCOUNTERH22 : Upper 32 bits of Machine Hardware Performance Monitoring Counter Register 
### *AddressOffset*: 'hb96 
### *Description*:
Hardware performance event counter only for RV32.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | 0x0 | WARL  | ``Legal Values``: 0\.|

## MHPMCOUNTERH23 : Upper 32 bits of Machine Hardware Performance Monitoring Counter Register 
### *AddressOffset*: 'hb97 
### *Description*:
Hardware performance event counter only for RV32.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | 0x0 | WARL  | ``Legal Values``: 0\.|

## MHPMCOUNTERH24 : Upper 32 bits of Machine Hardware Performance Monitoring Counter Register 
### *AddressOffset*: 'hb98 
### *Description*:
Hardware performance event counter only for RV32.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | 0x0 | WARL  | ``Legal Values``: 0\.|

## MHPMCOUNTERH25 : Upper 32 bits of Machine Hardware Performance Monitoring Counter Register 
### *AddressOffset*: 'hb99 
### *Description*:
Hardware performance event counter only for RV32.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | 0x0 | WARL  | ``Legal Values``: 0\.|

## MHPMCOUNTERH26 : Upper 32 bits of Machine Hardware Performance Monitoring Counter Register 
### *AddressOffset*: 'hb9a 
### *Description*:
Hardware performance event counter only for RV32.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | 0x0 | WARL  | ``Legal Values``: 0\.|

## MHPMCOUNTERH27 : Upper 32 bits of Machine Hardware Performance Monitoring Counter Register 
### *AddressOffset*: 'hb9b 
### *Description*:
Hardware performance event counter only for RV32.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | 0x0 | WARL  | ``Legal Values``: 0\.|

## MHPMCOUNTERH28 : Upper 32 bits of Machine Hardware Performance Monitoring Counter Register 
### *AddressOffset*: 'hb9c 
### *Description*:
Hardware performance event counter only for RV32.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | 0x0 | WARL  | ``Legal Values``: 0\.|

## MHPMCOUNTERH29 : Upper 32 bits of Machine Hardware Performance Monitoring Counter Register 
### *AddressOffset*: 'hb9d 
### *Description*:
Hardware performance event counter only for RV32.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | 0x0 | WARL  | ``Legal Values``: 0\.|

## MHPMCOUNTERH30 : Upper 32 bits of Machine Hardware Performance Monitoring Counter Register 
### *AddressOffset*: 'hb9e 
### *Description*:
Hardware performance event counter only for RV32.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | 0x0 | WARL  | ``Legal Values``: 0\.|

## MHPMCOUNTERH31 : Upper 32 bits of Machine Hardware Performance Monitoring Counter Register 
### *AddressOffset*: 'hb9f 
### *Description*:
Hardware performance event counter only for RV32.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | 0x0 | WARL  | ``Legal Values``: 0\.|

## CYCLE : Cycle counter Register 
### *AddressOffset*: 'hC00 
### *Description*:
Cycle counter for RDCYCLE instruction. Shadow of mcycle.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | 0x0 | read-only  | Count|

## INSTRET : Instruction Retired counter Register 
### *AddressOffset*: 'hC02 
### *Description*:
Instructions-retired counter for RDINSTRET instruction. Shadow of minstret.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | 0x0 | read-only  | Count|

## CYCLEH : Upper 32-bits of Cycle counter Register 
### *AddressOffset*: 'hC80 
### *Description*:
Cycle counter for RDCYCLE instruction. Shadow of mcycleh.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | 0x0 | read-only  | Count|

## INSTRETH : Upper 32-bits of Instruction Retired counter Register 
### *AddressOffset*: 'hC82 
### *Description*:
Instructions-retired counter for RDINSTRET instruction. Shadow of minstreth.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | count | Count | 0x0 | read-only  | Count|

## MVENDORID : Machine Vendor ID Register 
### *AddressOffset*: 'hF11 
### *Description*:
This register provides the JEDEC manufacturer ID of the provider of the core.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:7 | bank | Bank | 0xC | read-only  | Contain encoding for number of one\-byte continuation codes discarding the parity bit\.|
| 6:0 | offset | Offset | 0x2 | read-only  | Contain encoding for the final byte discarding the parity bit\.|

## MARCHID : Machine Architecture ID Register 
### *AddressOffset*: 'hF12 
### *Description*:
This register encodes the base microarchitecture of the hart.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | architecture_id | Architecture id | 0x3 | read-only  | Provide Encoding the base microarchitecture of the hart\.|

## MIMPID : Machine Implementation ID Register 
### *AddressOffset*: 'hF13 
### *Description*:
Provides a unique encoding of the version of the processor implementation.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | implementation | Implementation | 0x0 | read-only  | Provides unique encoding of the version of the processor implementation\.|

## MHARTID : Machine Hardware Thread ID Register 
### *AddressOffset*: 'hF14 
### *Description*:
This register contains the integer ID of the hardware thread running the code.
| BIT |  NAME       | displayName        |Reset| RIGHT  | Description                                                          |
| --- | ----------- | ------------       |-----| ------ | -------------------------------------------------------------------- |
| 31:0 | hart_id | Hart id | 0x0 | read-only  | Contains the integer ID of the hardware thread running the code\.|
