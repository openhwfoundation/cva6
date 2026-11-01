..
   Copyright (c) 2023 OpenHW Group
   Copyright (c) 2023 Thales DIS SAS

   SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1


Traps, Interrupts, Exceptions
=============================
Traps are composed of interrupts and exceptions.
Interrupts are asynchronous events whereas exceptions are synchronous ones.
On one hand, interrupts are occurring independently of the instructions
(mainly raised by peripherals or debug module).
On the other hand, an instruction may raise exceptions synchronously.

Raising Traps
-------------
When a trap is raised, the behaviour of the CVA6 core depends on
several CSRs and some CSRs are modified.

Configuration CSRs
~~~~~~~~~~~~~~~~~~
CSRs having an effect on the core behaviour when a trap occurs are:

* ``mstatus`` and ``sstatus``: several fields control the core behaviour like interrupt enable (``MIE``, ``SIE``)
* ``mtvec`` and ``stvec``: specifies the address of trap handler.
* ``medeleg``: specifies which exceptions can be handled by a lower privileged mode (S-mode)
* ``mideleg``: specifies which interrupts can be handled by a lower privileged mode (S-mode)

Modified CSRs
~~~~~~~~~~~~~
CSRs (or fields) updated by the core when a trap occurs are:

* ``mstatus`` or ``sstatus``: several fields are updated like previous privilege mode (``MPP``, ``SPP``), previous interrupt enabled (``MPIE``, SPIE``)
* ``mepc`` or ``sepc``: updated with the virtual address of the interrupted instruction or the instruction raising the exception.
* ``mcause`` or ``scause``: updated with a code indicating the event causing the trap.
* ``mtval`` or ``stval``: updated with exception specific information like the faulting virtual address

Supported exceptions
~~~~~~~~~~~~~~~~~~~~
The following exceptions are supported by the CVA6:

* instruction address misaligned

  * control flow instruction with misaligned target

* instruction access fault

  * access to PMP region without execute permissions

* illegal instruction:

  * unimplemented CSRs
  * unsupported extensions

* breakpoint (``EBREAK``)
* load address misaligned:

  * ``LH`` at 2n+1 address
  * ``LW`` at 4n+1, 4n+2, 4n+3 address

* load access fault

  * access to PMP region without read permissions

* store/AMO address misaligned

  * ``SH`` at 2n+1 address
  * ``SW`` at 4n+1, 4n+2, 4n+3 address

* store/AMO access fault

  * access to PMP region without write permissions

* environment call (``ECALL``) from U-mode
* environment call (``ECALL``) from S-mode
* environment call (``ECALL``) from M-mode
* instruction page fault
* load page fault

  * access to effective address without read permissions

* store/AMO page fault

  * access to effective address without write permissions

* debug request (custom) via debug interface

Note: all exceptions are supported except the ones linked to the hypervisor extension

Trap return
-----------
Trap handler ends with trap return instruction (``MRET``, ``SRET``). The behaviour of the CVA6 core depends on several CSRs.

Configuration CSRs
~~~~~~~~~~~~~~~~~~
CSRs having an effect on the core behaviour when returning from a trap are:

* ``mstatus``: several fields control the core behaviour like previous privilege mode (``MPP``, ``SPP``), previous interrupt enabled (``MPIE``, ``SPIE``)

Modified CSRs
~~~~~~~~~~~~~
CSRs (or fields) updated by the core when returning from a trap are:

* ``mstatus``: several fields are updated like interrupt enable (``MIE``, ``SIE``), modify privilege (``MPRV``)

Interrupts
----------
* external interrupt: ``irq_i`` signal
* software interrupt (inter-processor interrupt): ``ipi_i`` signal
* timer interrupt: ``time_irq_i`` signal
* debug interrupt: ``debug_req_i`` signal

These signals are level sensitive. It means the interrupt is raised until it is cleared.

The exception code field (``mcause`` CSR) depends on the interrupt source.

Wait for Interrupt
------------------
* CVA6 implementation: ``WFI`` stalls the core. The instruction is not available in U-mode (raise illegal instruction exception). Such exception is also raised when ``TW=1`` in ``mstatus``.
