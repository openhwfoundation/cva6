# check_defines.h
# Ensures all RVMODEL macros are defined
# Jordan Carlin jcarlin@hmc.edu December 2025
# SPDX-License-Identifier: BSD-3-Clause

########## test.S CHECKS ##########
#ifndef TEST_FILE
  #error "TEST_FILE not defined. It should be defined at the beginning of the test file."
#endif

#ifndef SIGUPD_COUNT
  #error "SIGUPD_COUNT not defined. It should be defined at the beginning of the test file."
#endif

#ifndef TRAP_SIGUPD_COUNT
  #define TRAP_SIGUPD_COUNT 15000
#endif

########## GLOBAL XLEN CHECK  ##########
#ifndef __riscv_xlen
  #error "__riscv_xlen not defined."
#endif

########## rvmodel_macros.h CHECKS ##########
#ifndef RVMODEL_DATA_SECTION
  #error "RVMODEL_DATA_SECTION not defined. Make sure to define it in rvmodel_macros.h."
#endif

##### TERMINATION #####
#ifndef RVMODEL_HALT_PASS
  #error "RVMODEL_HALT_PASS not defined. Make sure to define it in rvmodel_macros.h."
#endif

#ifndef RVMODEL_HALT_FAIL
  #error "RVMODEL_HALT_FAIL not defined. Make sure to define it in rvmodel_macros.h."
#endif

##### IO #####
#ifndef RVMODEL_IO_WRITE_STR
  #error "RVMODEL_IO_WRITE_STR not defined. Make sure to define it in rvmodel_macros.h."
#endif

##### ADDRESSES #####
// If RVMODEL_ACCESS_FAULT_ADDRESS is not defined, no access faults are tested

##### MTIME #####
// If RVMODEL_MTIME_ADDRESS is not defined, no machine timer interrupts are tested

#ifdef RVMODEL_MTIME_ADDRESS
  // If RVMODEL_MTIME_ADDRESS is defined, these other MTIME-related macros must also be defined
  // because the tests will need them to cause timer interrupts and test timer functionality.
  // If these macros are not defined, the tests will fail to assemble due to the checks below.
  #ifndef RVMODEL_MTIMECMP_ADDRESS
    #error "RVMODEL_MTIMECMP_ADDRESS not defined. Make sure to define it in rvmodel_macros.h."
  #endif
#endif

##### Interrupt Delays #####
#ifndef RVMODEL_INTERRUPT_LATENCY
  #error "RVMODEL_INTERRUPT_LATENCY not defined. Make sure to define it in rvmodel_macros.h."
#endif
#ifndef RVMODEL_TIMER_INT_SOON_DELAY
  #error "RVMODEL_TIMER_INT_SOON_DELAY not defined. Make sure to define it in rvmodel_macros.h."
#endif

##### Machine Interrupts #####
#ifndef RVMODEL_SET_MEXT_INT
  #error "RVMODEL_SET_MEXT_INT not defined. Make sure to define it in rvmodel_macros.h."
#endif

#ifndef RVMODEL_CLR_MEXT_INT
  #error "RVMODEL_CLR_MEXT_INT not defined. Make sure to define it in rvmodel_macros.h."
#endif

#ifndef RVMODEL_SET_MSW_INT
  #error "RVMODEL_SET_MSW_INT not defined. Make sure to define it in rvmodel_macros.h."
#endif

#ifndef RVMODEL_CLR_MSW_INT
  #error "RVMODEL_CLR_MSW_INT not defined. Make sure to define it in rvmodel_macros.h."
#endif

##### Supervisor Interrupts #####
#ifndef RVMODEL_SET_SEXT_INT
  #error "RVMODEL_SET_SEXT_INT not defined. Make sure to define it in rvmodel_macros.h."
#endif

#ifndef RVMODEL_CLR_SEXT_INT
  #error "RVMODEL_CLR_SEXT_INT not defined. Make sure to define it in rvmodel_macros.h."
#endif

#ifndef RVMODEL_SET_SSW_INT
  #error "RVMODEL_SET_SSW_INT not defined. Make sure to define it in rvmodel_macros.h."
#endif

#ifndef RVMODEL_CLR_SSW_INT
  #error "RVMODEL_CLR_SSW_INT not defined. Make sure to define it in rvmodel_macros.h."
#endif
