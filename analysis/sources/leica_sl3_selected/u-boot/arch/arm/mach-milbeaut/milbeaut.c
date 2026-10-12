// SPDX-License-Identifier: GPL-2.0+
/*
 * Copyright (C) 2019 Socionext Inc.
 */

#include <common.h>
#include <linux/types.h>
#include <asm/armv8/mmu.h>
#include <asm/io.h>

#define CRSWR 0x0d154024

void reset_cpu(unsigned long ignored)
{
	puts ("reset cpu ...\n");

	udelay (50000);				/* wait 50 ms */

	writel(0x1, CRSWR);

	while (1)
		;
}

static struct mm_region sc2006a_mem_map[] = {
#if 0
	{
		.virt = 0x00000000,
		.phys = 0x00000000,
		.size = 0x0c000000,
		.attrs = PTE_BLOCK_MEMTYPE(MT_DEVICE_NGNRNE) |
			 PTE_BLOCK_NON_SHARE |
			 PTE_BLOCK_PXN | PTE_BLOCK_UXN
	},
#endif
	{
		.virt = 0x0c000000,
		.phys = 0x0c000000,
		.size = 0x3f400000,
		.attrs = PTE_BLOCK_MEMTYPE(MT_DEVICE_NGNRNE) |
			 PTE_BLOCK_NON_SHARE |
			 PTE_BLOCK_PXN | PTE_BLOCK_UXN
	},
	{
		.virt = 0x400000000,
		.phys = 0x400000000,
		.size = 0x100000000,
		.attrs = PTE_BLOCK_MEMTYPE(MT_NORMAL) |
			 PTE_BLOCK_INNER_SHARE
	},
	{ /* sentinel */ }
};

struct mm_region *mem_map = sc2006a_mem_map;

int print_cpuinfo(void)
{
	/*
	 * TO DO:
	 * please implement this :)
	 */
	return 0;
}

__weak int dram_init(void)
{
	/*
	 * Since I use DT for driver, I call fdt helper, fdtdec_setup_mem_size_base(),
	 * to initialize gd->ram_base instead of defining CONFIG_SYS_SDRAM_BASE.
	 */
	if (fdtdec_setup_mem_size_base() != 0) {
		printf("fdtdec_setup_mem_size_base() has failed\n");
		return -EINVAL;
	}

	return 0;
}

int dram_init_banksize(void)
{
	/*
	 * This is called after reserve_board(), which allocate "new" bd_t area.
	 * So you can set up the boad information of dram, gd->bd->bi_dram.
	 *
	 * NOTE: I don't use CONFIG_SYS_SDRAM_BASE, gd->ram_base and size are
	 * initialized in fdtdec_setup_mem_size_base(). For consystency of board
	 * information, I use fdtdec_setup_memory_banksize().
	 */
	if (fdtdec_setup_memory_banksize() !=0) {
		printf("fdtdec_setup_memory_banksize() has failed\n");
		return -EINVAL;
	}

	return 0;
}
