// Copyright 2026 OpenHW Foundation
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0

#include <stdint.h>

// The TestHarness mock UART uses the AXI SoC map and word-spaced registers.
// Unlike printf via HTIF syscalls, these writes need no host syscall service.
#define UART_BASE ((volatile uint32_t *)(uintptr_t)0x10000000)
#define UART_THR 0
#define UART_LSR 5
#define UART_THRE (1u << 5)
#define UART_TEMT (1u << 6)

int main(void)
{
    const char *message = "0: Hello World !\n";
    while (*message) {
        while (!(UART_BASE[UART_LSR] & UART_THRE))
            ;
        UART_BASE[UART_THR] = (uint32_t)*message++;
        __asm__ volatile ("fence iorw, iorw" ::: "memory");
    }
    while (!(UART_BASE[UART_LSR] & UART_TEMT))
        ;
    __asm__ volatile ("fence iorw, iorw" ::: "memory");
    return 0;
}
