# riscv_arch_test.h
# Top-level riscv-arch-test header file
# Jordan Carlin jcarlin@hmc.edu October 2025
# SPDX-License-Identifier: Apache-2.0

#include "rvtest_config.h"
#include "encoding.h"
#include "utils.h"
#include "rvmodel_macros.h"
#ifndef RVTEST_SELFCHECK
  #include "sail_macros.h"
#endif
#include "check_defines.h"
#include "signature.h"
#include "rvtest_macros.h"
#ifdef RVTEST_VECTOR
  #include "rvtest_macros_vector.h"
#endif
#include "rvtest_trap_handler.h"
#include "rvtest_failure_code.h"
#include "rvtest_setup.h"
