Board Support Package (BSP) for CV32 Verification
=================================================

This BSP provides the code to support running programs on the CV32 verification
target. It performs initialization tasks (`crt0.S`), handles
interrupts/exceptions (`vectors.S`, `handlers.S`), provides syscall
implementations (`syscalls.c`) and includes a linker script (`link.ld`) to
control the placement of sections in the binary.

Each file is described in more detail below followed by instructions for
building and using the BSP.

C Runtime Initialization
------------------------

The C Runtime file `crt0.S` provides the `_start` function which is the entry
point of the program and performs the following tasks:
  * Initialize global and stack pointer.
  * Store the address of `vector_table` in `mtvec`, setting the lower two bits
  to `0x2` to select vectored interrupt mode.
  * Zero the BSS section.
  * Invoke initialization of C constructors and set destructors to be called on
  exit.
  * Zero `argc` and `argv` (the stack is not initialized, so these are zeroed
  to prevent uninitialized values causing a mismatch against the reference
  result).
  * Call `main`.
  * If `main` returns, call `exit` with its return code.

Interrupt and Exception Handling
--------------------------------

When a RISC-V core traps on an interrupt/exception, the `pc` is stored in `mepc`
and the reason for the trap is stored in `mcause`. The `MSB` of `mcause`
is set to `0` for an exception and `1` for an interrupt; the remaining bits
`mcause[MXLEN-2:0]` contain the exception code. The table of `mcause` values is
defined in Table 3.6 of the [RISC-V Instruction Set Manual Volume II: Privileged
Architecture Version 20190608-Priv-MSU-Ratified](https://github.com/riscv/riscv-isa-manual/releases/download/Ratified-IMFDQC-and-Priv-v1.11/riscv-privileged-20190608.pdf).

The core jumps to a location in the vector table according to the `BASE` address
of the vector table stored in `mtvec` and the value of the exception code in
`mcause`. In vectored mode, all exceptions jump to `BASE` and interrupts jump to
`BASE+4*mcause[XLEN-2:0]`. Note that because user software interrupts have
exception code `0`, they jump to the same location as exceptions, therefore the
user software interrupt handler must also handle exceptions.

The vector table is defined in `vectors.S` and may jump to one of the
following interrupt request handlers in `handlers.S`:
  * `u_sw_irq_handler` - handles user software interrupts and all exceptions.
  Saves all caller saved registers then checks `mcause` and jumps to the
  appropriate handler as follows:
    - Breakpoint: jump to `handle_ebreak`.
    - Illegal instruction: jump to `handle_illegal`.
    - Environment call from M-mode: jump to `handle_ecall`.
    - Any other exception or user software interrupt: jump to `handle_unknown`.
  * `m_software_irq_handler` - handles machine-mode software interrupts
    - Currently jumps to `__no_irq_handler`.  Behavior to be defined in future commit.
  * `m_timer_irq_handler` - handles machine-mode timer interrupts
    - Currently jumps to `__no_irq_handler`.  Behavior to be defined in future commit.
  * `m_external_irq_handler` - handles machine-mode external interrupts
    - Currently jumps to `__no_irq_handler`.  Behavior to be defined in future commit.
  * `m_fast0_irq_handler` - handles machine-mode fast external interrupts (platform extension for CV32)  
    - Currently jumps to `__no_irq_handler`.  Behavior to be defined in future commit.
  * `m_fast1_irq_handler` - handles machine-mode fast external interrupts (platform extension for CV32)
    - Currently jumps to `__no_irq_handler`.  Behavior to be defined in future commit.
  * `m_fast2_irq_handler` - handles machine-mode fast external interrupts (platform extension for CV32)
    - Currently jumps to `__no_irq_handler`.  Behavior to be defined in future commit.
  * `m_fast3_irq_handler` - handles machine-mode fast external interrupts (platform extension for CV32)
    - Currently jumps to `__no_irq_handler`.  Behavior to be defined in future commit.
  * `m_fast4_irq_handler` - handles machine-mode fast external interrupts (platform extension for CV32)
    - Currently jumps to `__no_irq_handler`.  Behavior to be defined in future commit.
  * `m_fast5_irq_handler` - handles machine-mode fast external interrupts (platform extension for CV32)
    - Currently jumps to `__no_irq_handler`.  Behavior to be defined in future commit.
  * `m_fast6_irq_handler` - handles machine-mode fast external interrupts (platform extension for CV32)
    - Currently jumps to `__no_irq_handler`.  Behavior to be defined in future commit.
  * `m_fast7_irq_handler` - handles machine-mode fast external interrupts (platform extension for CV32)
    - Currently jumps to `__no_irq_handler`.  Behavior to be defined in future commit.
  * `m_fast8_irq_handler` - handles machine-mode fast external interrupts (platform extension for CV32)
    - Currently jumps to `__no_irq_handler`.  Behavior to be defined in future commit.
  * `m_fast9_irq_handler` - handles machine-mode fast external interrupts (platform extension for CV32)
    - Currently jumps to `__no_irq_handler`.  Behavior to be defined in future commit.
  * `m_fast10_irq_handler` - handles machine-mode fast external interrupts (platform extension for CV32)
    - Currently jumps to `__no_irq_handler`.  Behavior to be defined in future commit.
  * `m_fast11_irq_handler` - handles machine-mode fast external interrupts (platform extension for CV32)
    - Currently jumps to `__no_irq_handler`.  Behavior to be defined in future commit.
  * `m_fast12_irq_handler` - handles machine-mode fast external interrupts (platform extension for CV32)
    - Currently jumps to `__no_irq_handler`.  Behavior to be defined in future commit.
  * `m_fast13_irq_handler` - handles machine-mode fast external interrupts (platform extension for CV32)
    - Currently jumps to `__no_irq_handler`.  Behavior to be defined in future commit.
  * `m_fast14_irq_handler` - handles machine-mode fast external interrupts (platform extension for CV32)
    - Currently jumps to `__no_irq_handler`.  Behavior to be defined in future commit.
  * `m_fast15_irq_handler` - handles machine-mode fast external interrupts (platform extension for CV32)
    - Currently jumps to `__no_irq_handler`.  Behavior to be defined in future commit.
  * `__no_irq_handler` - loops printing "no exception handler installed".

The following exception handlers may be called from `u_sw_irq_handler`:
  * `handle_ecall` - calls `handle_syscall` which checks the syscall number and
  calls the corresponding syscall function.
  * `handle_ebreak` - currently just prints "ebreak exception handler entered"
  * `handle_illegal_insn` - prints "illegal instruction exception handler
  entered"
  * `unknown_handler` - called when there is no handler for the interrupt/
  exception. This is the only case where `mepc` is not incremented, because we
  do not know the appropriate action to take.

Returning from the `u_sw_irq_handler`. All handlers called by `u_sw_irq_handler`
increment `mepc` before calling `mret`, except for `unknown_handler`. Handlers
that require `mepc` to be incremented jump to `end_handler_incr_mepc` otherwise
they jump to `end_handler_ret`. All caller saved registers are restored before
finally calling `mret`.

Some test cases require the ability to override the default handlers. In future,
these handlers will be made overridable by defining their labels as `.weak`
symbols. Test cases can then provide their own handlers where necessary.

System Calls
------------

On a bare-metal system there is no OS to handle system calls, therefore, we
define our own system calls in `syscalls.c`. For example, the implementation of
`_write` outputs a byte at a time to the virtual printer peripheral. Many of the
functions provide minimal implementations that simply fail gracefully due to
lack of necessary OS support e.g. no file system.

The [RISC-V Instruction Set Manual Volume I: Unprivileged ISA Version 20191213](
https://content.riscv.org/wp-content/uploads/2019/06/riscv-spec.pdf) states that
for an `ecall` the "ABI for the system will define how parameters for the
environment request are passed". This BSP follows the convention used for RISC-V
in `newlib`. Parameters are passed in registers `a0` to `a5` and system call ID
in `a7` (`t0` on RV32E). When handling an `ecall`, `handle_ecall` calls
`handle_syscall` which then calls the appropriate function that implements the
system call, passing parameters as necessary.

Linker Script
-------------

The linker script defines the memory layout and controls the mapping of input
sections from object files to output sections in the output binary.

The `link.ld` script is based on the standard upstream RV32 linker script, with
some changes required for CV32:
  * Memory layout is defined as follows:
    * `ram` start=0x0, length=4MB
    * `dbg` start=0x1A110800, length=2KB
  * Changes to output section placement are as follows:
    - `.vectors` start=ORIGIN(`ram`)
    - `.init` start=0x80
    - `.heap` starts at end of data and grows upwards
    - `.stack` starts at the end of `ram` and grows downwards
    - `.debugger` start=ORIGIN(`dbg`)
    - `.debugger_exception` start=0x1A110C00
    - `.debugger_stack` follows `.debugger_exception`

Building and using the BSP Library
----------------------------------

The BSP can be built in this directory as follows:
```
make
```
This produces libcv-verif.a which can then be linked with a test program as
follows:

```
gcc test-program.c -nostartfiles -T/path/to/bsp/link.ld -L/path/to/bsp/ -lcv-verif
```
