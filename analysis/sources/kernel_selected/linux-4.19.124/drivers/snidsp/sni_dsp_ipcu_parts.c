/*
 * Copyright (C) 2015 Socionext Semiconductor Ltd.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 2 of the License.
 *
 * @file   sni_dsp_ipcu_parts.c
 * @author
 * @date
 * @brief  SNI DSP IPCU Parts
 */

#include "sni_dsp_ipcu_drv.h"
#include <linux/sni_dsp_ipcu_parts.h>
#include "sni_dsp_ipcu_comm.h"

#include <stdbool.h>
#include <linux/spinlock.h>
#include <linux/wait.h>
#include <linux/semaphore.h>
#include <linux/io.h>

#include <trace/events/dsp_ipcu.h>

#define FLAG_SEND_NOTIFY    (0x80000000)
#define FLAG_RECV_WAIT      (0x80000000)
#define MASK_RECV_TIMEOUT   (0x7fffffff)

#define STATUS_INTERRUPT    (1)
#define STATUS_INIT         (0)

#define CHECK_FUNC_OPEN     (0)
#define CHECK_FUNC_CLOS     (1)
#define CHECK_FUNC_SEND     (2)
#define CHECK_FUNC_RECV     (3)
#define CHECK_FUNC_FLSH     (4)
#define CHECK_FUNC_ACKS     (5)

struct sni_dsp_ipcu_mb_control {
	u32			status;
	wait_queue_head_t	rdq;
	struct semaphore	rds;
};

static DEFINE_SPINLOCK(spinlock_sni_dsp_ipcu_init);
static DEFINE_SPINLOCK(lock_shared_mem);
static struct sni_dsp_ipcu_mb_config  pSNI_DSP_IPCU[IPCU_MAX_MB];
static struct sni_dsp_ipcu_mb_control sni_dsp_ipcu_mbctl[IPCU_MAX_MB];


static int sni_dsp_ipcu_sanity_check(u32 func, u32 mb, u32 param)
{
	if (mb >= IPCU_MAX_MB) {
		pr_err("%s:%d [ERROR] mb is failed. mb=%d\n",
			__func__, __LINE__, mb);
		return -EBADF;
	}

	switch (func) {
	case CHECK_FUNC_OPEN:
		if (pSNI_DSP_IPCU[mb].direction == param) {
			pr_err("%s:%d [ERROR] direction failed. set-direc=%d rec-direc=%d\n",
				__func__, __LINE__,
				pSNI_DSP_IPCU[mb].direction,
				param);
			return -EINVAL;
		}
		break;

	case CHECK_FUNC_CLOS:
		if (pSNI_DSP_IPCU[mb].direction != param) {
			pr_err("%s:%d [ERROR] direction failed. set-direc=%d rec-direc=%d\n",
				__func__, __LINE__,
				pSNI_DSP_IPCU[mb].direction,
				param);
			return -EINVAL;
		}
		break;

	case CHECK_FUNC_SEND:
		if (pSNI_DSP_IPCU[mb].data_size < param) {
			pr_err("%s:%d [ERROR] data size failed. data_size=%d\n",
				__func__, __LINE__,
				pSNI_DSP_IPCU[mb].data_size);
			return -EINVAL;
		}
		if (pSNI_DSP_IPCU[mb].stat_tx == false) {
			pr_err("%s:%d [ERROR] stat_tx is failed. stat_tx=%d\n",
				__func__, __LINE__,
				pSNI_DSP_IPCU[mb].stat_tx);
			return -EACCES;
		}
		if (pSNI_DSP_IPCU[mb].direction != SNI_DSP_IPCU_DIR_SEND) {
			pr_err("%s:%d [ERROR] direction failed. set-direc=%d\n",
				__func__, __LINE__,
				pSNI_DSP_IPCU[mb].direction);
			return -EINVAL;
		}
		break;

	case CHECK_FUNC_RECV:
		if (pSNI_DSP_IPCU[mb].data_size < param) {
			pr_err("%s:%d [ERROR] data size failed. data_size=%d\n",
				__func__, __LINE__,
				pSNI_DSP_IPCU[mb].data_size);
			return -EINVAL;
		}
		break;

	case CHECK_FUNC_FLSH:
	case CHECK_FUNC_ACKS:
		if (pSNI_DSP_IPCU[mb].stat_rx == false) {
			pr_err("%s:%d [ERROR] stat_rx is failed. stat_rx=%d\n",
				__func__, __LINE__,
				pSNI_DSP_IPCU[mb].stat_rx);
			return -EACCES;
		}
		if (pSNI_DSP_IPCU[mb].direction != SNI_DSP_IPCU_DIR_RECV) {
			pr_err("%s:%d [ERROR] direction failed. set-direc=%d\n",
				__func__, __LINE__,
				pSNI_DSP_IPCU[mb].direction);
			return -EINVAL;
		}
		break;

	default:
		pr_err("%s:%d [ERROR] unknown function: %d\n",
					__func__, __LINE__, func);
		return -EINVAL;
	}

	return 0;
}

static irqreturn_t sni_dsp_ipcu_ack_handler(int irq, void *ipcu_dev)
{
	struct sni_dsp_ipcu_device *sni_dsp_ipcu_dev =
			(struct sni_dsp_ipcu_device *)ipcu_dev;
	u32 mb = sni_dsp_ipcu_dev->dest_mb;

	sni_dsp_ipcu_handle_ack(irq, mb);
	return IRQ_HANDLED;
}

static irqreturn_t sni_dsp_ipcu_rec_handler(int irq, void *ipcu_dev)
{
	struct sni_dsp_ipcu_device *sni_dsp_ipcu_dev =
			(struct sni_dsp_ipcu_device *)ipcu_dev;
	u32 mb = sni_dsp_ipcu_dev->dest_mb;

	sni_dsp_ipcu_handle_rec(irq, mb, pSNI_DSP_IPCU[mb].data);

	sni_dsp_ipcu_mbctl[mb].status = STATUS_INTERRUPT;
	wake_up(&sni_dsp_ipcu_mbctl[mb].rdq);

	return IRQ_HANDLED;
}

int sni_dsp_ipcu_mb_init(u32 mb, u32 direction, void *ipcu_dev)
{
	int ret;
	struct sni_dsp_ipcu_device *sni_dsp_ipcu_dev =
			(struct sni_dsp_ipcu_device *)ipcu_dev;

	spin_lock(&spinlock_sni_dsp_ipcu_init);

	pSNI_DSP_IPCU[mb].direction	= SNI_DSP_IPCU_DIR_INIT;
	pSNI_DSP_IPCU[mb].stat_tx	= false;
	pSNI_DSP_IPCU[mb].stat_rx	= false;
	pSNI_DSP_IPCU[mb].data_size	= IPCU_MAX_LEN;
	pSNI_DSP_IPCU[mb].data_depth	= IPCU_MAX_DEPTH;

	init_waitqueue_head(&sni_dsp_ipcu_mbctl[mb].rdq);
	sema_init(&sni_dsp_ipcu_mbctl[mb].rds, 1);
	sni_dsp_ipcu_mbctl[mb].status = STATUS_INIT;

	sni_dsp_ipcu_comm_init(mb);

	if (direction == SNI_DSP_IPCU_DIR_RECV) {
		ret = request_irq(
				ipcu_dsp_drv_inf.ipcu_rec_irq[mb],
				sni_dsp_ipcu_rec_handler,
				0,
				"sni_dsp_ipcu:rec",
				ipcu_dev);
		if (ret != 0) {
			pr_info("%s:%d [ERROR] request_irq REC is failed. ret=%d IRQ=%d devname=[%s]\n",
				__func__, __LINE__,
				ret,
				ipcu_dsp_drv_inf.ipcu_rec_irq[mb],
				sni_dsp_ipcu_dev->devname);
			spin_unlock(&spinlock_sni_dsp_ipcu_init);
			return ret;
		}
	} else if (direction == SNI_DSP_IPCU_DIR_SEND) {
		ret = request_irq(
				ipcu_dsp_drv_inf.ipcu_ack_irq[mb],
				sni_dsp_ipcu_ack_handler,
				0,
				"sni_dsp_ipcu:ack",
				ipcu_dev);
		if (ret != 0) {
			pr_info("%s:%d [ERROR] request_irq ACK is failed. ret=%d IRQ=%d devname=[%s]\n",
				__func__, __LINE__,
				ret,
				ipcu_dsp_drv_inf.ipcu_ack_irq[mb],
				sni_dsp_ipcu_dev->devname);
			spin_unlock(&spinlock_sni_dsp_ipcu_init);
			return ret;
		}
	} else {
		pr_err("%s:%d [ERROR] direction failed. direction=%d\n",
			__func__, __LINE__, direction);
	}

	spin_unlock(&spinlock_sni_dsp_ipcu_init);

	return 0;
}

void sni_dsp_ipcu_mb_exit(u32 mb, void *ipcu_dev)
{
	if (pSNI_DSP_IPCU[mb].direction == SNI_DSP_IPCU_DIR_SEND) {
		free_irq(ipcu_dsp_drv_inf.ipcu_ack_irq[mb], ipcu_dev);
	} else {
		free_irq(ipcu_dsp_drv_inf.ipcu_rec_irq[mb], ipcu_dev);
	}
}

int sni_dsp_ipcu_openmb(u32 mb, u32 direction)
{
	int result;

	result = sni_dsp_ipcu_sanity_check(CHECK_FUNC_OPEN, mb, direction);
	if (result != 0) {
		pr_err("%s:%d [ERROR] parameter check NG.\n",
			__func__, __LINE__);
		return result;
	}

	pSNI_DSP_IPCU[mb].direction = direction;
	if (direction == SNI_DSP_IPCU_DIR_SEND) {
		if (pSNI_DSP_IPCU[mb].stat_tx == true) {
			pr_err("%s:%d [ERROR] stat_tx is failed. stat_tx=%d\n",
				__func__, __LINE__,
				pSNI_DSP_IPCU[mb].stat_tx);
			return -EACCES;
		}
		pSNI_DSP_IPCU[mb].stat_tx = true;
	} else if (direction == SNI_DSP_IPCU_DIR_RECV) {
		if (pSNI_DSP_IPCU[mb].stat_rx == true) {
			pr_err("%s:%d [ERROR] stat_rx is failed. stat_rx=%d\n",
				__func__, __LINE__,
				pSNI_DSP_IPCU[mb].stat_rx);
			return -EACCES;
		}
		pSNI_DSP_IPCU[mb].stat_rx = true;
	} else {
		pr_err("%s:%d [ERROR] direction failed. direction=%d\n",
			__func__, __LINE__, direction);
	}
	trace_dsp_ipcu_open_mb(mb, direction);

	return 0;
}

int sni_dsp_ipcu_closemb(u32 mb, u32 direction)
{
	int result;

	result = sni_dsp_ipcu_sanity_check(CHECK_FUNC_CLOS, mb, direction);
	if (result != 0) {
		pr_err("%s:%d [ERROR] parameter check NG.\n",
			__func__, __LINE__);
		return result;
	}

	pSNI_DSP_IPCU[mb].direction  = SNI_DSP_IPCU_DIR_INIT;
	if (direction == SNI_DSP_IPCU_DIR_SEND) {
		if (pSNI_DSP_IPCU[mb].stat_tx == false) {
			pr_err("%s:%d [ERROR] stat_tx is failed. stat_tx=%d\n",
				__func__, __LINE__,
				pSNI_DSP_IPCU[mb].stat_tx);
			return -EACCES;
		}
		pSNI_DSP_IPCU[mb].stat_tx = false;
	} else if (direction == SNI_DSP_IPCU_DIR_RECV) {
		if (pSNI_DSP_IPCU[mb].stat_rx == false) {
			pr_err("%s:%d [ERROR] stat_rx is failed. stat_rx=%d\n",
				__func__, __LINE__,
				pSNI_DSP_IPCU[mb].stat_rx);
			return -EACCES;
		}
		pSNI_DSP_IPCU[mb].stat_rx = false;
	} else {
		pr_err("%s:%d [ERROR] direction failed. direction=%d\n",
			__func__, __LINE__, direction);
	}
	trace_dsp_ipcu_close_mb(mb, direction);

	return 0;
}

int sni_dsp_ipcu_send_msg(u32 mb, void *buf, u32 len, u32 flags)
{
	unsigned long ret = 0;
	int result;

	result = sni_dsp_ipcu_sanity_check(CHECK_FUNC_SEND, mb, len);
	if (result != 0) {
		pr_err("%s:%d [ERROR] parameter check NG.\n",
			__func__, __LINE__);
		return result;
	}

	ret = copy_from_user(&pSNI_DSP_IPCU[mb].data[0], buf, len);
	if (ret != 0) {
		pr_err("%s:%d copy_from_user failed.(ret=%lu,src=%p,len=%d)\n",
			__func__, __LINE__, ret, buf, len);
		return -EFAULT;
	}
	wmb();

	if ((flags & FLAG_SEND_NOTIFY) != 0) {
		u32 data[IPCU_MAX_DATA];

		/* sizeof( u32 ) * IPCU_MAX_DATA */
		memset(data, 0, sizeof(data));
		memcpy(data, pSNI_DSP_IPCU[mb].data, len);
		ret = sni_dsp_ipcu_send_req(mb, data);
		if (ret != 0) {
			pr_err("%s:%d [ERROR] ipcu send error. %d\n",
				__func__, __LINE__, (int)ret);
			return -EBUSY;
		}
	}

	return 0;
}

int sni_dsp_ipcu_recv_msg(u32 mb, void *buf, u32 len, u32 flags)
{
	unsigned long timeout;
	unsigned long j, abs_timeout, delta;
	unsigned long ret = 0;
	int result;
	DECLARE_WAITQUEUE(wait, current);

	result = sni_dsp_ipcu_sanity_check(CHECK_FUNC_RECV, mb, len);
	if (result != 0) {
		pr_err("%s:%d [ERROR] parameter check NG.\n",
			__func__, __LINE__);
		return result;
	}

	timeout = (flags & MASK_RECV_TIMEOUT);

	j = jiffies;
	if (timeout == 0x7fffffff)
		abs_timeout = 0;
	else
		abs_timeout = j + timeout * HZ / 1000;

	spin_lock_irq(&lock_shared_mem);

	/* no message */
	if ((flags & FLAG_RECV_WAIT) == 0) {
		spin_unlock_irq(&lock_shared_mem);
		return -ENOBUFS;
	}

	trace_dsp_ipcu_start_recv_msg(mb, buf, flags);

	set_current_state(TASK_INTERRUPTIBLE);
	add_wait_queue(&sni_dsp_ipcu_mbctl[mb].rdq, &wait);

	spin_unlock_irq(&lock_shared_mem);

	if (timeout == 0x7fffffff) {
		if (sni_dsp_ipcu_mbctl[mb].status == STATUS_INIT)
			schedule();
	} else {
		j = jiffies;
		if (abs_timeout >= j)
			delta = abs_timeout - j;
		else
			delta = 0;
		schedule_timeout(delta);
	}

	remove_wait_queue(&sni_dsp_ipcu_mbctl[mb].rdq, &wait);

	spin_lock_irq(&lock_shared_mem);
	sni_dsp_ipcu_mbctl[mb].status = STATUS_INIT;
	spin_unlock_irq(&lock_shared_mem);

	/* wait was signal */
	if (signal_pending(current)) {
		result = -ERESTARTSYS;	/* EAGAIN? */
		goto end;
	}

	ret = copy_to_user(buf,
			   &pSNI_DSP_IPCU[mb].data[0],
			   (IPCU_MAX_DATA * sizeof(int)));
	if (ret != 0) {
		pr_err("%s:%d [ERROR] copy_to_user failed! (ret=%lu,dest=%p,len=%d)\n",
			__func__, __LINE__, ret, buf, len);
		result = -EFAULT;
		goto end;
	}
	wmb();

	if (timeout != 0x7fffffff) {
		j = jiffies;
		if (time_after(j, abs_timeout)) {
			result = -ETIME;
			goto end;
		}
	}

end:
	trace_dsp_ipcu_recv_msg(mb, buf, result);

	return result;
}

int sni_dsp_ipcu_recv_flsh(u32 mb)
{
	int result;

	result = sni_dsp_ipcu_sanity_check(CHECK_FUNC_FLSH, mb, 0);
	if (result != 0) {
		pr_err("%s:%d [ERROR] parameter check NG.\n",
			__func__, __LINE__);
		return result;
	}

	trace_dsp_ipcu_recv_flush(mb);
	wake_up(&sni_dsp_ipcu_mbctl[mb].rdq);

	return 0;
}

int sni_dsp_ipcu_ack_send(u32 mb)
{
	int result;

	result = sni_dsp_ipcu_sanity_check(CHECK_FUNC_ACKS, mb, 0);
	if (result != 0) {
		pr_err("%s:%d [ERROR] parameter check NG.\n",
			__func__, __LINE__);
		return result;
	}

	if (sni_dsp_ipcu_send_ack(mb) != 0) {
		pr_err("%s:%d [ERROR] ipcu ack send error\n",
			__func__, __LINE__);
		return -EBUSY;
	}

	return 0;
}

dma_addr_t dsp_ipcu_dma_map_single(void *ptr,
				size_t size,
				enum dma_data_direction dir)
{
	return dma_map_single(ipcu_dsp_drv_inf.dev, ptr, size, dir);
}

void dsp_ipcu_dma_unmap_single(dma_addr_t addr,
				size_t size,
				enum dma_data_direction dir)
{
	dma_unmap_single(ipcu_dsp_drv_inf.dev,addr, size, dir);
}
