// Copyright 2026 Thales France
//
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
//
// Hello world of Zephyr, ended for a simulation: the testbench ends the run
// on the write of (exit code << 1 | 1) into tohost.

#include <stdint.h>
#include <zephyr/kernel.h>
#include <zephyr/sys/printk.h>

volatile uint64_t tohost __aligned(8);
volatile uint64_t fromhost __aligned(8);

int main(void)
{
	printk("Hello World! %s\n", CONFIG_BOARD_TARGET);
	tohost = 1;
	return 0;
}
