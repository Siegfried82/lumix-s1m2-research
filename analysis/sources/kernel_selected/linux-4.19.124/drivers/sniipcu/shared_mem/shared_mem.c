/**
 * Copyright (C) 2016 Socionext Semiconductor Ltd.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 2 of the License.
 *
 * @file   shared_mem.c
 * @author
 * @date
 * @brief  SNI common memory driver
 */

#include <linux/fs.h>
#include <linux/of_platform.h>
#include <linux/io.h>
#include <linux/ipcu_userland.h>
#include <linux/spinlock.h>

#include <linux/shared_mem.h>

static struct device_node *node;
static void __iomem *ipcu_buff_mem = NULL;
static void __iomem *ipcu_sync_mem = NULL;

static DEFINE_SPINLOCK( shared_mem_lock );

void __iomem *shared_mem_get_mem(E_SHARED_MEM mem)
{
	u32 ipcu_buff_addr;
	u32 ipcu_sync_addr;
	u64 ipcu_buff_addr64;
	u64 ipcu_sync_addr64;
	u32 add64 = 0;

	if (!node) {
		node = of_find_compatible_node(NULL, NULL,
					"socionext, shared-commem");
		if (!node) {
			pr_err("get_shared_commem_node failed\n");
			goto end;
		}
	}

	if(of_get_property(node, "address64", NULL)) {
		add64 = 1;
	}

	switch (mem) {
		case E_SHARED_MEM_BUFFER:
			spin_lock(&shared_mem_lock);
			if (!ipcu_buff_mem) {
				if (add64) {
					if (of_property_read_u64(node,
							 "buf-addr", &ipcu_buff_addr64)) {
						pr_err("get ipcu-buffer-addr64 failed\n");
						goto unlock;
					}
					ipcu_buff_mem = ioremap(ipcu_buff_addr64,
								sizeof(u64));
				} else {
					if (of_property_read_u32(node,
							 "buf-addr", &ipcu_buff_addr)) {
						pr_err("get ipcu-buffer-addr failed\n");
						goto unlock;
					}
					ipcu_buff_mem = ioremap(ipcu_buff_addr,
								sizeof(u32));
				}

				if (!ipcu_buff_mem) {
					pr_err("get ipcu-buffer-mem failed\n");
					goto unlock;
				}
			}
			spin_unlock(&shared_mem_lock);
			return ipcu_buff_mem;

		case E_SHARED_MEM_SYNC:
			spin_lock(&shared_mem_lock);
			if (!ipcu_sync_mem) {
				if (add64) {
					if (of_property_read_u64(node,
						"sync-addr", &ipcu_sync_addr64)) {
						pr_err("get ipcu-sync-addr64 failed\n");
						goto unlock;
					}
					ipcu_sync_mem = ioremap(ipcu_sync_addr64,
								sizeof(u64));
				} else {
					if (of_property_read_u32(node,
						"sync-addr", &ipcu_sync_addr)) {
						pr_err("get ipcu-sync-addr failed\n");
						goto unlock;
					}
					ipcu_sync_mem = ioremap(ipcu_sync_addr,
								sizeof(u32));
				}

				if (!ipcu_sync_mem) {
					pr_err("ioremqp ipcu-sync-mem failed\n");
					goto unlock;
				}
			}
			spin_unlock(&shared_mem_lock);
			return ipcu_sync_mem;

		default:
			pr_err("this mem type is not supported.\n");
			goto end;
	}
unlock:
	spin_unlock(&shared_mem_lock);
end:
	return NULL;
}

