// SPDX-License-Identifier: GPL-2.0+
/*
 * Generic bounce buffer implementation
 *
 * Copyright (C) 2012 Marek Vasut <marex@denx.de>
 */

// #include <common.h>
// #include <cpu_func.h>
// #include <log.h>
// #include <malloc.h>
// #include <errno.h>
#include "bouncebuf.h"
#include "cache.h"
#include "dma-mapping.h"
#include "uart.h"
#include "bootrom_errno.h"
#include <string.h>

// void flush_dcache_range(unsigned long start, unsigned long end)
// {
// 	if (start >= end)
// 		return;

// 	/*
// 	 * ARCv1                                 -> call __dc_line_op
// 	 * ARCv2 && L1 D$ disabled               -> nothing
// 	 * ARCv2 && L1 D$ enabled && IOC enabled -> nothing
// 	 * ARCv2 && L1 D$ enabled && no IOC      -> call __dc_line_op; call __slc_rgn_op
// 	 */
// 	// if (!_config_enabled(CONFIG_ISA_ARCV2,0)|| !ioc_enabled())
// 		__dc_line_op(start, end - start, OP_FLUSH);

// 	// if (_config_enabled(CONFIG_ISA_ARCV2,0) && !ioc_enabled() && !slc_data_bypass())
// 	// 	__slc_rgn_op(start, end - start, OP_FLUSH);
// }

static int addr_aligned(struct bounce_buffer *state)
{
	const unsigned long align_mask = ARCH_DMA_MINALIGN - 1;

	/* Check if start is aligned */
	if ((unsigned long)state->user_buffer & align_mask) {
		print_uart("Unaligned buffer address ");
		print_uart_addr((uintptr_t)state->user_buffer);
		print_uart("align mask");
		print_uart_int(align_mask);
		print_uart("(unsigned long)state->user_buffer & align_mask");
		print_uart_int((unsigned long)state->user_buffer & align_mask);
		print_uart("\n");
		return 0;
	}

	/* Check if length is aligned */
	if (state->len != state->len_aligned) {
		print_uart("Unaligned buffer length");
		print_uart_int(state->len);
		print_uart("\n");
		return 0;
	}

	/* Aligned */
	return 1;
}

int bounce_buffer_start_extalign(struct bounce_buffer *state, void *data,
				 u32_t len, unsigned int flags,
				 u32_t alignment,
				 int (*addr_is_aligned)(struct bounce_buffer *state))
{
	state->user_buffer = data;
	state->bounce_buffer = data;
	state->len = len;
	state->len_aligned = roundup(len, alignment);
	state->flags = flags;

	// if (!addr_is_aligned(state)) {
	// 	print_uart("call mem align \n");
	// 	state->bounce_buffer = memalign(alignment,
	// 					state->len_aligned);
	// 	if (!state->bounce_buffer){
	// 		print_uart("return enomem \n");
	// 		return -ENOMEM;
	// 	}

	// 	if (state->flags & GEN_BB_READ){
	// 		print_uart("memcpy \n");
	// 		memcpy(state->bounce_buffer, state->user_buffer,
	// 			state->len);
	// 	}
	// }

	/*
	 * Flush data to RAM so DMA reads can pick it up,
	 * and any CPU writebacks don't race with DMA writes
	 */
	print_uart("dma map single\n");
	dma_map_single(state->bounce_buffer,
		       state->len_aligned,
		       DMA_BIDIRECTIONAL);
	print_uart("return 0\n");
	return 0;
}

int bounce_buffer_start(struct bounce_buffer *state, void *data,
			u32_t len, unsigned int flags)
{
	return bounce_buffer_start_extalign(state, data, len, flags,
					    ARCH_DMA_MINALIGN,
					    addr_aligned);
}

int bounce_buffer_stop(struct bounce_buffer *state)
{
	if (state->flags & GEN_BB_WRITE) {
		/* Invalidate cache so that CPU can see any newly DMA'd data */
		dma_unmap_single((dma_addr_t)(uintptr_t)state->bounce_buffer,
				 state->len_aligned,
				 DMA_BIDIRECTIONAL);
	}

	if (state->bounce_buffer == state->user_buffer)
		return 0;

	// if (state->flags & GEN_BB_WRITE)
	// 	memcpy(state->user_buffer, state->bounce_buffer, state->len);

	// free(state->bounce_buffer);

	return 0;
}
