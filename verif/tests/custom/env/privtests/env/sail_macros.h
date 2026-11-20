# sail_macros.h
# RVMODEL macro definitions for Sail reference model
# Jordan Carlin jcarlin@hmc.edu October 2025, Sadhvi Narayana sanarayanan@hmc.edu February 2026
# SPDX-License-Identifier: BSD-3-Clause

// This header is included AFTER rvmodel_macros.h for signature ELF builds
// (non-selfcheck). It overrides DUT-specific macros with Sail-compatible
// implementations for IO, termination, and interrupts. Macros that should
// always come from the DUT (e.g. RVMODEL_ACCESS_FAULT_ADDRESS) are NOT
// redefined here.

#ifndef _SAIL_MACROS_H
#define _SAIL_MACROS_H

#define SAIL_CLINT_BASE_ADDRESS 0x02000000

#undef RVMODEL_DATA_SECTION
#define RVMODEL_DATA_SECTION \
        .pushsection .tohost,"aw",@progbits;                \
        .align 8; .global tohost; tohost: .dword 0;         \
        .align 8; .global fromhost; fromhost: .dword 0;     \
        .popsection

##### STARTUP #####

# Perform boot operations. Can be empty or left undefined unless needed for
# DUT-specific behavior such as turning on a memory controller or
# initializing custom state.
#undef RVMODEL_BOOT
// #define RVMODEL_BOOT

##### TERMINATION #####

// SAIL uses HTIF (Host-Target Interface) to terminate simulation.
// Writing to 'tohost' with value 1 indicates success, 3 indicates failure.

# Terminate test with a pass indication.
# When the test is run in simulation, this should end the simulation.
#undef RVMODEL_HALT_PASS
#define RVMODEL_HALT_PASS  \
  li x1, 1                ;\
  la t0, tohost           ;\
  write_tohost_pass:      ;\
    sw x1, 0(t0)          ;\
    sw x0, 4(t0)          ;\
    j write_tohost_pass   ;\


# Terminate test with a fail indication.
# When the test is run in simulation, this should end the simulation.
#undef RVMODEL_HALT_FAIL
#define RVMODEL_HALT_FAIL \
  li x1, 3                ;\
  la t0, tohost           ;\
  write_tohost_fail:      ;\
    sw x1, 0(t0)          ;\
    sw x0, 4(t0)          ;\
    j write_tohost_fail   ;\


##### IO #####

# Initialization steps needed prior to writing to the console
# _R1, _R2, and _R3 can be used as temporary registers if needed.
# Do not modify any other registers (or make sure to restore them).
# Can be empty or left undefined if no initialization is needed.
#undef RVMODEL_IO_INIT
// #define RVMODEL_IO_INIT(_R1, _R2, _R3)


# Prints a null-terminated string using a DUT specific mechanism.
# A pointer to the string is passed in _STR_PTR.
# _R1, _R2, and _R3 can be used as temporary registers if needed.
# Do not modify any other registers (or make sure to restore them).
#undef RVMODEL_IO_WRITE_STR
// No-op: the CVA6 RTL testbench uses simplified HTIF (bit 0 of tohost = exit
// flag), so HTIF device=1 console sd writes trigger false exits on odd chars.
// Pass/fail is determined by signature comparison, not console strings.
#define RVMODEL_IO_WRITE_STR(_R1, _R2, _R3, _STR_PTR)

##### Machine Timer #####

#undef RVMODEL_MTIMECMP_ADDRESS
#define RVMODEL_MTIMECMP_ADDRESS  0x02004000  /* Address of mtimecmp CSR */

#undef RVMODEL_MTIME_ADDRESS
#define RVMODEL_MTIME_ADDRESS  0x0200BFF8  /* Address of mtime CSR */

##### Machine Interrupts #####

// Interrupt latency configuration
#undef RVMODEL_INTERRUPT_LATENCY
#define RVMODEL_INTERRUPT_LATENCY 10

#undef RVMODEL_TIMER_INT_SOON_DELAY
#define RVMODEL_TIMER_INT_SOON_DELAY 100

#define SAIL_SIG_ADDRESS  (0xC000000 + 0x4)  /* Address of memory mapped simple interrupt generator */
#undef RVMODEL_SET_MEXT_INT
#define RVMODEL_SET_MEXT_INT(_R1, _R2)        \
  li _R1, (1 << 31) | (1 << 11);               \
  li _R2, SAIL_SIG_ADDRESS;    \
  sw _R1, 0(_R2)            ; /* Set MEXT interrupt */ \


#undef RVMODEL_CLR_MEXT_INT
#define RVMODEL_CLR_MEXT_INT(_R1, _R2)        \
  li _R1, (1 << 11);               \
  li _R2, SAIL_SIG_ADDRESS;    \
  sw _R1, 0(_R2)            ; /* Clear MEXT interrupt */ \

#define SAIL_MSIP_ADDRESS (SAIL_CLINT_BASE_ADDRESS + 0x0)
#undef RVMODEL_SET_MSW_INT
#define RVMODEL_SET_MSW_INT(_R1, _R2)        \
  li _R1, 1;                 \
  li _R2, SAIL_MSIP_ADDRESS;              \
  sw _R1, 0(_R2);


#undef RVMODEL_CLR_MSW_INT
#define RVMODEL_CLR_MSW_INT(_R1, _R2)        \
  li _R2, SAIL_MSIP_ADDRESS;              \
  sw zero, 0(_R2);



##### Supervisor Interrupts #####
#undef RVMODEL_SET_SEXT_INT
#define RVMODEL_SET_SEXT_INT(_R1, _R2)        \
  li _R1, (1 << 31) | (1 << 9);               \
  li _R2, SAIL_SIG_ADDRESS;    \
  sw _R1, 0(_R2)            ; /* Set SEXT interrupt */ \

#undef RVMODEL_CLR_SEXT_INT
#define RVMODEL_CLR_SEXT_INT(_R1, _R2)        \
  li _R1, (1 << 9);               \
  li _R2, SAIL_SIG_ADDRESS;    \
  sw _R1, 0(_R2)            ; /* Clear SEXT interrupt */ \

#undef RVMODEL_SET_SSW_INT
#define RVMODEL_SET_SSW_INT(_R1, _R2)        \
  li _R1, (1 << 31) | (1 << 1);               \
  li _R2, SAIL_SIG_ADDRESS;    \
  sw _R1, 0(_R2)            ; /* Set SSW interrupt */ \

#undef RVMODEL_CLR_SSW_INT
#define RVMODEL_CLR_SSW_INT(_R1, _R2)        \
  li _R1, (1 << 1);               \
  li _R2, SAIL_SIG_ADDRESS;    \
  sw _R1, 0(_R2)            ; /* Clear SSW interrupt */ \

#endif // _SAIL_MACROS_H
