// Copyright (c) 2023. RISC-V International. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
// -----------
// This file contains test macros for vector tests

#ifndef RISCV_TEST_SUITE_TEST_MACROS_VECTOR_H
#define RISCV_TEST_SUITE_TEST_MACROS_VECTOR_H

// Define which LMUL fractions are supported based on SEW_MIN and ELEN
#if SEW_MIN == 8
    #if ELEN == 64
        #define LMULf8_SUPPORTED
        #define LMULf4_SUPPORTED
        #define LMULf2_SUPPORTED
    #elif ELEN == 32
        #define LMULf4_SUPPORTED
        #define LMULf2_SUPPORTED
    #elif ELEN == 16
        #define LMULf2_SUPPORTED
    #elif ELEN == 8
    #else
        #error "ELEN unsupported, check SEW_MIN"
    #endif
#elif SEW_MIN == 16
    #if ELEN == 64
        #define LMULf4_SUPPORTED
        #define LMULf2_SUPPORTED
    #elif ELEN == 32
        #define LMULf2_SUPPORTED
    #elif ELEN == 16
    #else
        #error "ELEN unsupported, check SEW_MIN"
    #endif
#elif SEW_MIN == 32
    #if ELEN == 64
        #define LMULf2_SUPPORTED
    #elif ELEN == 32
    #else
        #error "ELEN unsupported, check SEW_MIN"
    #endif
#endif


#endif // RISCV_TEST_SUITE_TEST_MACROS_VECTOR_H
