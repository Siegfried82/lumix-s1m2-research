/*
 * Copyright (C) 2015-2019 Socionext Semiconductor Ltd.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 2 of the License.
 *
 * @file   sni_dsp_ipcu_comm.c
 * @author
 * @date
 * @brief  SNI IPCU Communication
 */

#include "sni_dsp_ipcu_drv.h"
#include <linux/sni_dsp_ipcu_parts.h>
#include "sni_dsp_ipcu_comm.h"

#include <stdbool.h>
#include <linux/bits.h>
#include <linux/io.h>
#include <linux/spinlock.h>
#include <linux/mutex.h>

#define CREATE_TRACE_POINTS
#include <trace/events/dsp_ipcu.h>

/* Send reg in MBOX */
#define IPCU_MBOX_SEND_REQUEST	1

/* Mode reg in MBOX */
#define IPCU_MBOX_MODE_MANUAL1	0
#define IPCU_MBOX_MODE_MANUAL2	1
#define IPCU_MBOX_MODE_AUTOACK1	2
#define IPCU_MBOX_MODE_AUTOACK2	3
#define IPCU_MBOX_MODE_AUTOCLR	4

static DEFINE_SPINLOCK(spinlock_sni_dsp_ipcu);

static int sni_dsp_ipcu_com_init_done[IPCU_MAX_MB];


int sni_dsp_ipcu_comm_init(u32 mb)
{
	spin_lock(&spinlock_sni_dsp_ipcu);

	sni_dsp_ipcu_com_init_done[mb] = 1;
	mutex_init(&ipcu_dsp_drv_inf.mb_mutex[mb]);

	spin_unlock(&spinlock_sni_dsp_ipcu);

	return 0;
}

int sni_dsp_ipcu_send_req(u32 mb, u32 *data)
{
	u32 src_num;
	u32 src_bit;
	u32 dst_num;
	u32 mbx_bit;
	u32 mbstat;
	u32 cid;
	int ix;
	struct io_sni_dsp_ipcu *io_sni_dsp_ipcu;

	if (sni_dsp_ipcu_com_init_done[mb] != 1)
		return -EACCES;

	if (mutex_lock_interruptible(
		&ipcu_dsp_drv_inf.mb_mutex[mb]) == -EINTR)
		return -EINTR;

	io_sni_dsp_ipcu = (struct io_sni_dsp_ipcu *)(ipcu_dsp_drv_inf.ipcu_io_mem);

	src_num = ipcu_dsp_drv_inf.src_int_ch[mb];

	dst_num = ipcu_dsp_drv_inf.dst_int_ch[mb];
	cid     = mb;

	src_bit = BIT(src_num);

	mbstat = io_sni_dsp_ipcu->mbstat;
	mbx_bit = BIT(cid);

	if ((mbstat & mbx_bit) != 0) {
		pr_err("%s:%d [ERROR] mbstat:%X, mbx_bit:%X, cid:%X\n",
			__func__, __LINE__, mbstat, mbx_bit, cid);
		mutex_unlock(&ipcu_dsp_drv_inf.mb_mutex[mb]);
		/* no free mailbox */
		return -EBUSY;
	}

	/* Set source */
	writel(src_bit, &io_sni_dsp_ipcu->mailbox[cid].source);
	if (readl(&io_sni_dsp_ipcu->mailbox[cid].source) != src_bit) {
		mutex_unlock(&ipcu_dsp_drv_inf.mb_mutex[mb]);
		return -EFAULT;
	}

	/* Set destination */
	writel(BIT(dst_num), &io_sni_dsp_ipcu->mailbox[cid].dest_set);


	/* Set Mode "Manual Mode 2" */
	writel(IPCU_MBOX_MODE_MANUAL2, &io_sni_dsp_ipcu->mailbox[cid].mode);

	/* Data */
	for (ix = 0; ix < IO_DSP_IPCU_MBX_DATA_MAX; ix++)
		writel_relaxed(data[ix], &io_sni_dsp_ipcu->mailbox[cid].data[ix]);

	wmb();

	/* Start sending */
	writel(IPCU_MBOX_SEND_REQUEST, &io_sni_dsp_ipcu->mailbox[cid].send);
	trace_dsp_ipcu_send_req(cid, src_num, data);
	wait_for_completion(&ipcu_dsp_drv_inf.ack_notify[cid]);

	mutex_unlock(&ipcu_dsp_drv_inf.mb_mutex[mb]);

	return 0;
}

int sni_dsp_ipcu_send_ack(u32 mb)
{
	struct io_sni_dsp_ipcu *io_sni_dsp_ipcu;

	if (sni_dsp_ipcu_com_init_done[mb] != 1)
		return -EACCES;

	io_sni_dsp_ipcu = (struct io_sni_dsp_ipcu *)(ipcu_dsp_drv_inf.ipcu_io_mem);

	/* clear destination */
	writel((BIT(ipcu_dsp_drv_inf.dst_int_ch[mb])),
		&io_sni_dsp_ipcu->mailbox[mb].dest_clr);
	writel((BIT(ipcu_dsp_drv_inf.dst_int_ch[mb])),
		&io_sni_dsp_ipcu->mailbox[mb].ack_set);

	trace_dsp_ipcu_send_ack(mb);
	return 0;
}

void sni_dsp_ipcu_handle_rec(int irq, u32 mb, u32 *data)
{
	int ix;
	struct io_sni_dsp_ipcu *io_sni_dsp_ipcu;

	if (sni_dsp_ipcu_com_init_done[mb] != 1) {
		pr_err("%s:%d [ERROR] No initialization mbox\n",
			__func__, __LINE__);
		return;
	}

	io_sni_dsp_ipcu = (struct io_sni_dsp_ipcu *)ipcu_dsp_drv_inf.ipcu_io_mem;

	for (ix = 0; ix < IO_DSP_IPCU_MBX_DATA_MAX; ix++)
		data[ix] = readl(&io_sni_dsp_ipcu->mailbox[mb].data[ix]);

	/* clear destination */
	writel(BIT(ipcu_dsp_drv_inf.dst_int_ch[mb]),
		&io_sni_dsp_ipcu->mailbox[mb].dest_clr);

	trace_dsp_ipcu_handle_rec(mb, irq, data);
}

void sni_dsp_ipcu_handle_ack(int irq, u32 mb)
{
	u32 ack_reg;
	struct io_sni_dsp_ipcu *io_sni_dsp_ipcu;

	if (sni_dsp_ipcu_com_init_done[mb] != 1) {
		pr_err("%s:%d [ERROR] No initialization mbox\n",
			__func__, __LINE__);
		return;
	}

	io_sni_dsp_ipcu = (struct io_sni_dsp_ipcu *)ipcu_dsp_drv_inf.ipcu_io_mem;

	/* Read acknowldge status */
	ack_reg = readl(&io_sni_dsp_ipcu->mailbox[mb].ack_stat);

	/* Clear acknowlegde */
	writel(ack_reg, &io_sni_dsp_ipcu->mailbox[mb].ack_clr);

	/* Release Mail Box */
	writel(0, &io_sni_dsp_ipcu->mailbox[mb].source);

	trace_dsp_ipcu_handle_ack(mb, irq);
	/* Notify that received ack */
	complete(&ipcu_dsp_drv_inf.ack_notify[mb]);
}

