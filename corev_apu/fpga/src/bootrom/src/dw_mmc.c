// SPDX-License-Identifier: GPL-2.0+
/*
 * (C) Copyright 2012 SAMSUNG Electronics
 * Jaehoon Chung <jh80.chung@samsung.com>
 * Rajeshawari Shinde <rajeshwari.s@samsung.com>
 */



#include "bootrom_time.h"
#include "uart.h"
#include "dwmmc.h"
#include "cache.h"
#include "bouncebuf.h"
#include "memalign.h"
// #include "wait_bit.h"

#define PAGE_SIZE 4096
#define FIFO_MODE 1

void write_print(u32_t print,u32_t address, u32_t val){
	writel(val,MMC_BASE_ADDR+address);
	if (print){
		print_uart("WRITE L ADDR: ");
		print_uart_int(MMC_BASE_ADDR+address);
		print_uart(" DATA: ");
		print_uart_int(val);
		print_uart( "\n");
	}

	if(MMC_BASE_ADDR+address == 0x80000000UL){

		print_uart("WRITING TO FIRST ADDRESS: ");
		print_uart("WRITE L ADDR: ");
		print_uart_int(MMC_BASE_ADDR+address);
		print_uart(" DATA: ");
		print_uart_int(val);
		print_uart( "\n");
	}
	
}

u32_t read_print(u32_t print, u32_t address){
	u32_t val = readl(MMC_BASE_ADDR+address);
	if (print){
		print_uart("READ L ADDR: ");
		print_uart_int(MMC_BASE_ADDR+address);
		print_uart("DATA: ");
		print_uart_int(val);
		print_uart( "\n");
	}
	return val;
}
static int dwmci_wait_reset(u32_t value)
{
	unsigned long timeout = 1000;
	u32_t ctrl;

	write_print(0, DWMCI_CTRL, value);

	while (timeout--) {
		ctrl = read_print(0, DWMCI_CTRL);
		if (!(ctrl & DWMCI_RESET_ALL))
			return 1;
	}
	return 0;
}

static void dwmci_set_idma_desc(struct dwmci_idmac *idmac,
		u32_t desc0, u32_t desc1, u32_t desc2)
{
	struct dwmci_idmac *desc = idmac;

	desc->flags = desc0;
	desc->cnt = desc1;
	desc->addr = desc2;
	desc->next_addr = (unsigned long)desc + sizeof(struct dwmci_idmac);
	print_uart("descriptor pointer address: ");
	print_uart_addr((uintptr_t)desc);
	print_uart("set descriptor: flags ");
	print_uart_int(desc->flags);
	print_uart(" cnt ");
	print_uart_int(desc->cnt);
	print_uart(" addr ");
	print_uart_int(desc->addr);
	print_uart(" next_addr ");
	print_uart_int(desc->next_addr);
	print_uart("\n");
}

static void dwmci_prepare_data(struct mmc_data *data,
			       struct dwmci_idmac *cur_idmac,
			       void *bounce_buffer)
{
	unsigned long ctrl;
	unsigned int i = 0, flags, cnt, blk_cnt;
	unsigned long data_start, data_end;


	blk_cnt = data->blocks;

	dwmci_wait_reset(DWMCI_CTRL_FIFO_RESET);

	/* Clear IDMAC interrupt */
	write_print(0, DWMCI_IDSTS, 0xFFFFFFFF);

	data_start = (unsigned long)cur_idmac;
	write_print(0, DWMCI_DBADDR, (unsigned long)cur_idmac);

	do {
		flags = DWMCI_IDMAC_OWN | DWMCI_IDMAC_CH ;
		flags |= (i == 0) ? DWMCI_IDMAC_FS : 0;
		if (blk_cnt <= 8) {
			flags |= DWMCI_IDMAC_LD;
			cnt = data->blocksize * blk_cnt;
		} else
			cnt = data->blocksize * 8;

		dwmci_set_idma_desc(cur_idmac, flags, cnt,
				    (unsigned long)bounce_buffer + (i * PAGE_SIZE));

		cur_idmac++;
		if (blk_cnt <= 8)
			break;
		blk_cnt -= 8;
		i++;
	} while(1);

	print_uart("prepare data, skipping flush! \n");
	// data_end = (unsigned long)cur_idmac;
	// flush_dcache_range(data_start, roundup(data_end, ARCH_DMA_MINALIGN));

	ctrl = read_print(1, DWMCI_CTRL);
	ctrl |= DWMCI_IDMAC_EN | DWMCI_DMA_EN;
	write_print(0, DWMCI_CTRL, ctrl);

	ctrl = read_print(1, DWMCI_BMOD);
	ctrl |= DWMCI_BMOD_IDMAC_FB | DWMCI_BMOD_IDMAC_EN;
	write_print(0, DWMCI_BMOD, ctrl);

	write_print(0, DWMCI_BLKSIZ, data->blocksize);
	write_print(0, DWMCI_BYTCNT, data->blocksize * data->blocks);
}

static int dwmci_fifo_ready(u32_t bit, u32_t *len)
{
	u32_t timeout = 20000;
	// print_uart(" fifo ready get len: ");
	*len = read_print(0, DWMCI_STATUS);
	while (--timeout && (*len & bit)) {
		udelay(200);
		print_uart(" fifo ready get len inside while : ");
		*len = read_print(1, DWMCI_STATUS);
	}

	if (!timeout) {
		print_uart("FIFO underflow timeout\n");
		return -ETIMEDOUT;
	}

	return 0;
}


static int dwmci_data_transfer(struct mmc_data *data)
{
	int ret = 0;
	u32_t timeout, mask, size, i, len = 0;
	u32_t *buf = NULL;
	// unsigned long start = get_timer(0);
	// u32_t fifo_depth = (((host->fifoth_val & RX_WMARK_MASK) >>
	// 		    RX_WMARK_SHIFT) + 1) * 2;

	size = data->blocksize * data->blocks;
	// if (data->flags == MMC_DATA_READ)
		buf = (unsigned int *)data->dest;
	// else
	// 	buf = (unsigned int *)data->src;

	timeout = 1000000;

	size /= 4;
	read_print(0,DWMCI_STATUS);
	for (;;) {
		mask = read_print(0, DWMCI_RINTSTS);
		int val = read_print(0,DWMCI_STATUS);
		// if(val & 0x4)
		// 	print_uart("FIFO empty \n");
		/* Error during data transfer. */
		if (mask & (DWMCI_DATA_ERR | DWMCI_DATA_TOUT)) {
			print_uart("DATA ERROR!\n");
			ret = -EINVAL;
			return ret;
		}
		

		
		if (FIFO_MODE && size!=0) {
			// print_uart("FIFO_MODE && size \n");
			len = 0;
			if (data->flags == MMC_DATA_READ &&
			    (mask & (DWMCI_INTMSK_RXDR | DWMCI_INTMSK_DTO))) {
				write_print(0, DWMCI_RINTSTS,
					     mask & (DWMCI_INTMSK_RXDR |
						     DWMCI_INTMSK_DTO));
				while (size) {
					ret = dwmci_fifo_ready(	DWMCI_FIFO_EMPTY,
							&len);
					if (ret < 0)
						break;

					len = (len >> DWMCI_FIFO_SHIFT) &
						    DWMCI_FIFO_MASK;
					len = min(size, len);
					// print_uart("actually reading! to ");
					// print_uart_int(buf);
					// print_uart("\n");

					// print_uart("size ");
					// print_uart_int(size);
					// print_uart("\n");

					// print_uart("len ");
					// print_uart_int(len);
					// print_uart("\n");
					
					for (i = 0; i < len; i++)
						*buf++ =
						read_print(0, DWMCI_DATA);
					size = size > len ? (size - len) : 0;
				}
			} // else if (data->flags == MMC_DATA_WRITE &&
			// 	   (mask & DWMCI_INTMSK_TXDR)) {
			// 	while (size) {
			// 		ret = dwmci_fifo_ready(host,
			// 				DWMCI_FIFO_FULL,
			// 				&len);
			// 		if (ret < 0)
			// 			break;

			// 		len = fifo_depth - ((len >>
			// 			   DWMCI_FIFO_SHIFT) &
			// 			   DWMCI_FIFO_MASK);
			// 		len = min(size, len);
			// 		for (i = 0; i < len; i++)
			// 			write_print(0, DWMCI_DATA,
			// 				     *buf++);
			// 		size = size > len ? (size - len) : 0;
			// 	}
			// 	write_print(0, DWMCI_RINTSTS,
			// 		     DWMCI_INTMSK_TXDR);
			// }
		}

		/* Data arrived correctly. */
		if (mask & DWMCI_INTMSK_DTO) {
			ret = 0;
			break;
		}

		/* Check for timeout. */
		if (timeout-- > 0) {
			udelay(10);
		}
		else {
			read_print(1,DWMCI_STATUS);
			print_uart("Timeout waiting for data!\n");
			ret = -ETIMEDOUT;
			break;
		}
	}

	write_print(0, DWMCI_RINTSTS, mask);

	return ret;
}

static int dwmci_set_transfer_mode()
{
	unsigned long mode;

	mode = DWMCI_CMD_DATA_EXP;
	// if (data->flags & MMC_DATA_WRITE)
	// 	mode |= DWMCI_CMD_RW;

	return mode;
}


static int dwmci_send_cmd(struct mmc_cmd *cmd,
		struct mmc_data *data)
{

	struct dwmci_idmac *cur_idmac = (struct dwmci_idmac *) (0xFFE30000);

	// ALLOC_CACHE_ALIGN_BUFFER(struct dwmci_idmac, cur_idmac,
				//  data ? DIV_ROUND_UP(data->blocks, 8) : 0);
	int ret = 0, flags = 0, i;
	unsigned int timeout = 500;
	u32_t retry = 100000;
	u32_t mask, ctrl,reg;
	// unsigned long start = get_timer(0);
	struct bounce_buffer bbstate;

	while (read_print(0, DWMCI_STATUS) & DWMCI_BUSY) {
		if (timeout-- > 0)
		{
			udelay(10);
		}
		else {
			read_print(1, DWMCI_STATUS);
			print_uart("Timeout on data busy, continue anyway\n");
			break;
		}
	}

	write_print(0, DWMCI_RINTSTS, DWMCI_INTMSK_ALL);

	if (data) {
		if (FIFO_MODE) {
			write_print(0, DWMCI_BLKSIZ, data->blocksize);
			write_print(0, DWMCI_BYTCNT,
				     data->blocksize * data->blocks);
			dwmci_wait_reset(DWMCI_CTRL_FIFO_RESET);
		} else {
		// 	if (data->flags == MMC_DATA_READ) {
				ret = bounce_buffer_start(&bbstate,
						(void*)data->dest,
						data->blocksize *
						data->blocks, GEN_BB_WRITE);
			// } else {
			// 	ret = bounce_buffer_start(&bbstate,
			// 			(void*)data->src,
			// 			data->blocksize *
			// 			data->blocks, GEN_BB_READ);
			// }

			if (ret)
				return ret;

			dwmci_prepare_data(data, cur_idmac,
					   bbstate.bounce_buffer);
		}
	}

	write_print(0, DWMCI_CMDARG, cmd->cmdarg);

	if (data)
		flags = dwmci_set_transfer_mode();

	if ((cmd->resp_type & MMC_RSP_136) && (cmd->resp_type & MMC_RSP_BUSY))
		return -EBUSY;

	if (cmd->cmdidx == MMC_CMD_STOP_TRANSMISSION)
		flags |= DWMCI_CMD_ABORT_STOP;
	else
		flags |= DWMCI_CMD_PRV_DAT_WAIT;

	if (cmd->resp_type & MMC_RSP_PRESENT) {
		flags |= DWMCI_CMD_RESP_EXP;
		if (cmd->resp_type & MMC_RSP_136)
			flags |= DWMCI_CMD_RESP_LENGTH;
	}

	if (cmd->resp_type & MMC_RSP_CRC)
		flags |= DWMCI_CMD_CHECK_CRC;

	flags |= (cmd->cmdidx | DWMCI_CMD_START | DWMCI_CMD_USE_HOLD_REG);

	// print_uart("Sending CMD\n");

	write_print(0, DWMCI_CMD, flags);

	for (i = 0; i < retry; i++) {
		mask = read_print(0, DWMCI_RINTSTS);
		if (mask & DWMCI_INTMSK_CDONE) {
			if (!data)
				write_print(0, DWMCI_RINTSTS, mask);
			break;
		}
	}

	if (i == retry) {
		print_uart("Timeout. RINTSTS: ");
		print_uart_int(mask);
		print_uart("\n");
		
		return -ETIMEDOUT;
	}

	if (mask & DWMCI_INTMSK_RTO) {
		/*
		 * Timeout here is not necessarily fatal. (e)MMC cards
		 * will splat here when they receive CMD55 as they do
		 * not support this command and that is exactly the way
		 * to tell them apart from SD cards. Thus, this output
		 * below shall be debug(). eMMC cards also do not favor
		 * CMD8, please keep that in mind.
		 */
		print_uart("Response Timeout.\n");
		return -ETIMEDOUT;
	} else if (mask & DWMCI_INTMSK_RE) {
		print_uart("Response Error.\n");
		return -EIO;
	} else if ((cmd->resp_type & MMC_RSP_CRC) &&
		   (mask & DWMCI_INTMSK_RCRC)) {
		print_uart("Response CRC Error.\n");
		return -EIO;
	}


	if (cmd->resp_type & MMC_RSP_PRESENT) {
		if (cmd->resp_type & MMC_RSP_136) {
			cmd->response[0] = read_print(0, DWMCI_RESP3);
			cmd->response[1] = read_print(0, DWMCI_RESP2);
			cmd->response[2] = read_print(0, DWMCI_RESP1);
			cmd->response[3] = read_print(0, DWMCI_RESP0);
		} else {
			cmd->response[0] = read_print(0, DWMCI_RESP0);
		}
	}

	if (data) {
		ret = dwmci_data_transfer(data);

		/* only dma mode need it */
		if (!FIFO_MODE) {
		// 	if (data->flags == MMC_DATA_READ)
				mask = DWMCI_IDINTEN_RI;
			// else
			// 	mask = DWMCI_IDINTEN_TI;

			timeout = 1000;
			ret = 1;

			while(timeout-- > 0){
				reg = read_print(0,DWMCI_IDSTS);
				if ((reg & mask) == mask){
					ret = 0;
					break;
				}
					
				udelay(10);
			}
			// ret = wait_for_bit_le32(MMC_BASE_ADDR + DWMCI_IDSTS,
			// 			mask, true, 1000, false);
			if (ret){
				print_uart_int(reg);
				print_uart(" DWMCI_IDINTEN mask  timeout.\n");
				return ret;
			}
			/* clear interrupts */
			write_print(0, DWMCI_IDSTS, DWMCI_IDINTEN_MASK);

			ctrl = read_print(1, DWMCI_CTRL);
			ctrl &= ~(DWMCI_DMA_EN);
			write_print(0, DWMCI_CTRL, ctrl);
			bounce_buffer_stop(&bbstate);
		}
	}

	udelay(100);

	return ret;
}


// Set the number of block to read from the SD card.
static u8_t set_block_count(u32_t blkcnt)
{
	u8_t err = 0;
	struct mmc_cmd cmd23;

	cmd23.cmdidx = MMC_CMD_SET_BLOCK_COUNT;
	cmd23.cmdarg = blkcnt;
	cmd23.resp_type = MMC_RSP_R1;

	// mmc_trace_before_send(&cmd23);
	err = dwmci_send_cmd(&cmd23, NULL);
	// mmc_trace_after_send(&cmd23, err);	

	return err;
}


// Copies the data blocks from the SD card to dst by sending the read command. The blkcnt argument type is u64_t because lbas are 64 bits integer in the gpt format. But the block size argument of the read command is a u32_t. Since blkcnt is the result of the subtraction between two lbas and given the size of the linux image, we assume blkcnt will NEVER be above the maximum value of a u32_t. We can then safely cast blkcnt from u64_t to u32_t.
u8_t sd_copy_mmc(void *dst, u64_t src_lba, u64_t blkcnt)
{
	u8_t err = 0;

	struct mmc_cmd cmd18;
	struct mmc_data data;

	if (blkcnt > 1)
	{
		err = set_block_count(blkcnt);
		if (err)
			return err;
		cmd18.cmdidx = MMC_CMD_READ_MULTIPLE_BLOCK;
	}
	else
		cmd18.cmdidx = MMC_CMD_READ_SINGLE_BLOCK;

	/*
	We assume the card is high capacity as all SD Card today are.
	The check of the SD card high capacity property is done during "Send Operating Condition Command (ACMD41)" in the OCR register.
	*/
	// if (g_dwc_mshc->high_capacity)
		cmd18.cmdarg = src_lba;
	// else
	// 	cmd18.cmdarg = src_lba * g_dwc_mshc->read_bl_len;

	cmd18.resp_type = MMC_RSP_R1;

	data.dest = dst;
	// The blkcnt argument type is u64_t because lbas are 64 bits integer in the gpt format. But the block size argument of the read command is a u32_t. Since blkcnt is the result of the subtraction between two lbas and given the size of the linux image, we assume blkcnt will NEVER be above the maximum value of a u32_t. We can then safely cast blkcnt from u64_t to u32_t.
	data.blocks = (u32_t) blkcnt;
	data.blocksize = 0x200; // blocksize is 512 by default
	data.flags = MMC_DATA_READ;

	// mmc_trace_before_send(&cmd18);
	err = dwmci_send_cmd(&cmd18, &data);
	// mmc_trace_after_send(&cmd18, err);	

	return err;
}

