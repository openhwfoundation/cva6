// vim: ts=4 : sts=4 : sw=4 : et
/*
** Copyright 2026 Inria, Universite Grenoble-Alpes
**
** Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
** you may not use this file except in compliance with the License.
** You may obtain a copy of the License at
**
**     https://solderpad.org/licenses/
**
** Unless required by applicable law or agreed to in writing, software
** distributed under the License is distributed on an "AS IS" BASIS,
** WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
** See the License for the specific language governing permissions and
** limitations under the License.
*/
/*
** Author: Cesar Fuguet - Inria, Univ. Grenoble-Alpes
**/
#include <stdint.h>

/*
** No printf: syscall() waits for fromhost, which this testbench never writes.
** The verdict is the return code, which crt.S places in tohost.
*/

static const unsigned int TEST_TIMEOUT = 10000;

/*  DCACHE CSR
 *  XLEN-1           XLEN-2           XLEN-3 ..  28   27  .. 24   23  .. 20
 *  -----------------------------------------------------------------------
 *  eccPresent | eccScrubberPresent |   RESERVED    | dirCorErr | dirUncErr
 *  -----------------------------------------------------------------------
 *
 *  19  .. 16   15  ..  12  11   ..    8  7   ..    2      1           0
 *  -----------------------------------------------------------------------
 *  datCorErr | datUncErr | scrubCycles | scrubPeriod | scrubEn  |  cacheEn
 *  -----------------------------------------------------------------------
 */
static const unsigned int CSR_DCACHE = 0x7c1u;

#define __csr_rw(opcode, val) ({              \
    register uintptr_t ret;                   \
    asm volatile(                             \
        #opcode " %[rd], %[rs1], %[rs2]\n"    \
        : [rd]"=r"(ret)                       \
        : [rs1]"i"(CSR_DCACHE), [rs2]"r"(val) \
        : "memory");                          \
    ret;                                      \
    })

static inline uintptr_t csr_dcache_read_wr(uintptr_t val)
{
    return __csr_rw(csrrw, val);
}

static inline uintptr_t csr_dcache_read_set(uintptr_t mask)
{
    return __csr_rw(csrrs, mask);
}

static inline uintptr_t csr_dcache_read_clr(uintptr_t mask)
{
    return __csr_rw(csrrc, mask);
}


static int testScrubPeriod(int period, int max_cycles)
{
    //  program scrubEn and scrubPeriod (clear then set)
    csr_dcache_read_clr(0x7f << 1);
    csr_dcache_read_clr(0xf << 8); // clear scrubCycles counter
    csr_dcache_read_set((period << 2) | 0x2);

    //  wait for a given number of scrub cycles
    int ret = 1;
    for (int i = 0; i < TEST_TIMEOUT; i++) {
        uintptr_t scrubCycles;
        uintptr_t tmp = csr_dcache_read_set(0);
        scrubCycles = (tmp >> 8) & 0xf;
        if (scrubCycles >= max_cycles) {
            ret = 0;
            break;
        }
    }
    csr_dcache_read_clr(0x2); // disable scrubber
    return ret;
}

int main(int argc, char* arg[])
{
    const int scrubPeriod = 5; // Power of two value (2**N) -> 32 if period=5
    const int xlen = sizeof(uintptr_t) * 8;
    uintptr_t tmp;
    int ret = 0;

    tmp = csr_dcache_read_set(0);

    //  check that eccPresent bit is set: the test only runs on targets with
    //  ECC, so a cleared bit is a failure.
    if (((tmp >> (xlen - 1)) & 0x1) == 0) {
        ret = 1;
        goto exitTest;
    }

    //  check that eccScrubberPresent bit is set
    if (((tmp >> (xlen - 2)) & 0x1) == 0) {
        ret = 1;
        goto exitTest;
    }

    //  start tests
    ret = testScrubPeriod(5/*32*/, 3);
    if (ret > 0) goto exitTest;
    ret = testScrubPeriod(4/*16*/, 5);

exitTest:
    return ret;
}
