/*
 * Copyright (C) 2015 Socionext Semiconductor Ltd.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 2 of the License.
 *
 * @file   sni_ipcu_parts.c
 * @author
 * @date
 * @brief  SNI IPCU Parts
 */

#include "sni_ipcu_drv.h"
#include <linux/sni_ipcu_parts.h>
#include "sni_ipcu_comm.h"

#include <stdbool.h>
#include <linux/spinlock.h>
#include <linux/wait.h>
#include <linux/semaphore.h>
#include <linux/io.h>

#include <trace/events/ipcu.h>

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

struct sni_ipcu_mb_control {
	u32			status;
	wait_queue_head_t	rdq;
	struct semaphore	rds;
};

static DEFINE_SPINLOCK(spinlock_sni_ipcu_init);
static DEFINE_SPINLOCK(lock_shared_mem);
static struct sni_ipcu_mb_config  pSNI_IPCU[IPCU_MAX_UNIT][IPCU_MAX_MB];
static struct sni_ipcu_mb_control sni_ipcu_mbctl[IPCU_MAX_UNIT][IPCU_MAX_MB];


static int sni_ipcu_sanity_check(u32 func, u32 unit, u32 mb, u32 param)
{
	if (unit >= IPCU_MAX_UNIT) {
		pr_err("%s:%d [ERROR] unit is failed. unit=%d\n",
			__func__, __LINE__, unit);
		return -EBADF;
	}
	if (mb >= IPCU_MAX_MB) {
		pr_err("%s:%d [ERROR] mb is failed. mb=%d\n",
			__func__, __LINE__, mb);
		return -EBADF;
	}

	switch (func) {
	case CHECK_FUNC_OPEN:
		if (pSNI_IPCU[unit][mb].direction == param) {
			pr_err("%s:%d [ERROR] direction failed. set-direc=%d rec-direc=%d\n",
				__func__, __LINE__,
				pSNI_IPCU[unit][mb].direction,
				param);
			return -EINVAL;
		}
		break;

	case CHECK_FUNC_CLOS:
		if (pSNI_IPCU[unit][mb].direction != param) {
			pr_err("%s:%d [ERROR] direction failed. set-direc=%d rec-direc=%d\n",
				__func__, __LINE__,
				pSNI_IPCU[unit][mb].direction,
				param);
			return -EINVAL;
		}
		break;

	case CHECK_FUNC_SEND:
		if (pSNI_IPCU[unit][mb].data_size < param) {
			pr_err("%s:%d [ERROR] data size failed. data_size=%d\n",
				__func__, __LINE__,
				pSNI_IPCU[unit][mb].data_size);
			return -EINVAL;
		}
		if (pSNI_IPCU[unit][mb].stat_tx == false) {
			pr_err("%s:%d [ERROR] stat_tx is failed. stat_tx=%d\n",
				__func__, __LINE__,
				pSNI_IPCU[unit][mb].stat_tx);
			return -EACCES;
		}
		if (pSNI_IPCU[unit][mb].direction != SNI_IPCU_DIR_SEND) {
			pr_err("%s:%d [ERROR] direction failed. set-direc=%d\n",
				__func__, __LINE__,
				pSNI_IPCU[unit][mb].direction);
			return -EINVAL;
		}
		break;

	case CHECK_FUNC_RECV:
		if (pSNI_IPCU[unit][mb].data_size < param) {
			pr_err("%s:%d [ERROR] data size failed. data_size=%d\n",
				__func__, __LINE__,
				pSNI_IPCU[unit][mb].data_size);
			return -EINVAL;
		}
		break;

	case CHECK_FUNC_FLSH:
	case CHECK_FUNC_ACKS:
		if (pSNI_IPCU[unit][mb].stat_rx == false) {
			pr_err("%s:%d [ERROR] stat_rx is failed. stat_rx=%d\n",
				__func__, __LINE__,
				pSNI_IPCU[unit][mb].stat_rx);
			return -EACCES;
		}
		if (pSNI_IPCU[unit][mb].direction != SNI_IPCU_DIR_RECV) {
			pr_err("%s:%d [ERROR] direction failed. set-direc=%d\n",
				__func__, __LINE__,
				pSNI_IPCU[unit][mb].direction);
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

static void sni_ipcu_set_magic_code(u32 unit, u32 mb)
{
	iowrite32(SNI_IPCU_MAGIC_CODE,
		  (ipcu_drv_inf[unit].ipcu_magic_mem + (mb << 2)));
}

static void sni_ipcu_clear_magic_code(u32 unit, u32 mb)
{
	iowrite32(0, ipcu_drv_inf[unit].ipcu_magic_mem + (mb << 2));
}

static irqreturn_t sni_ipcu_ack_handler(int irq, void *ipcu_dev)
{
	struct sni_ipcu_device *sni_ipcu_dev =
			(struct sni_ipcu_device *)ipcu_dev;
	u32 unit = sni_ipcu_dev->dest_unit;
	u32 mb = sni_ipcu_dev->dest_mb;

	sni_ipcu_handle_ack(irq, unit, mb);
	return IRQ_HANDLED;
}

static irqreturn_t sni_ipcu_rec_handler(int irq, void *ipcu_dev)
{
	struct sni_ipcu_device *sni_ipcu_dev =
			(struct sni_ipcu_device *)ipcu_dev;
	u32 unit = sni_ipcu_dev->dest_unit;
	u32 mb = sni_ipcu_dev->dest_mb;

	sni_ipcu_handle_rec(irq, unit, mb, pSNI_IPCU[unit][mb].data);

	sni_ipcu_mbctl[unit][mb].status = STATUS_INTERRUPT;
	wake_up(&sni_ipcu_mbctl[unit][mb].rdq);

	return IRQ_HANDLED;
}

int sni_ipcu_mb_init(u32 unit, u32 mb, u32 direction, void *ipcu_dev)
{
	int ret;
	struct sni_ipcu_device *sni_ipcu_dev =
			(struct sni_ipcu_device *)ipcu_dev;

	spin_lock(&spinlock_sni_ipcu_init);

	pSNI_IPCU[unit][mb].direction	= SNI_IPCU_DIR_INIT;
	pSNI_IPCU[unit][mb].stat_tx	= false;
	pSNI_IPCU[unit][mb].stat_rx	= false;
	pSNI_IPCU[unit][mb].data_size	= IPCU_MAX_LEN;
	pSNI_IPCU[unit][mb].data_depth	= IPCU_MAX_DEPTH;

	init_waitqueue_head(&sni_ipcu_mbctl[unit][mb].rdq);
	sema_init(&sni_ipcu_mbctl[unit][mb].rds, 1);
	sni_ipcu_mbctl[unit][mb].status = STATUS_INIT;

	sni_ipcu_comm_init(unit, mb);

	if (direction == SNI_IPCU_DIR_RECV) {
		ret = request_irq(
				ipcu_drv_inf[unit].ipcu_rec_irq[mb],
				sni_ipcu_rec_handler,
				0,
				"sni_ipcu:rec",
				ipcu_dev);
		if (ret != 0) {
			pr_info("%s:%d [ERROR] request_irq REC is failed. ret=%d IRQ=%d devname=[%s]\n",
				__func__, __LINE__,
				ret,
				ipcu_drv_inf[unit].ipcu_rec_irq[mb],
				sni_ipcu_dev->devname);
			spin_unlock(&spinlock_sni_ipcu_init);
			return ret;
		}
	} else if (direction == SNI_IPCU_DIR_SEND) {
		ret = request_irq(
				ipcu_drv_inf[unit].ipcu_ack_irq[mb],
				sni_ipcu_ack_handler,
				0,
				"sni_ipcu:ack",
				ipcu_dev);
		if (ret != 0) {
			pr_info("%s:%d [ERROR] request_irq ACK is failed. ret=%d IRQ=%d devname=[%s]\n",
				__func__, __LINE__,
				ret,
				ipcu_drv_inf[unit].ipcu_ack_irq[mb],
				sni_ipcu_dev->devname);
			spin_unlock(&spinlock_sni_ipcu_init);
			return ret;
		}
	} else {
		pr_err("%s:%d [ERROR] direction failed. direction=%d\n",
			__func__, __LINE__, direction);
	}

	spin_unlock(&spinlock_sni_ipcu_init);

	return 0;
}

void sni_ipcu_mb_exit(u32 unit, u32 mb, void *ipcu_dev)
{
	if (pSNI_IPCU[unit][mb].direction == SNI_IPCU_DIR_SEND) {
		free_irq(ipcu_drv_inf[unit].ipcu_ack_irq[mb], ipcu_dev);
	} else {
		free_irq(ipcu_drv_inf[unit].ipcu_rec_irq[mb], ipcu_dev);
	}
}

int sni_ipcu_openmb(u32 unit, u32 mb, u32 direction)
{
	int result;

	result = sni_ipcu_sanity_check(CHECK_FUNC_OPEN, unit, mb, direction);
	if (result != 0) {
		pr_err("%s:%d [ERROR] parameter check NG.\n",
			__func__, __LINE__);
		return result;
	}

	pSNI_IPCU[unit][mb].direction = direction;
	if (direction == SNI_IPCU_DIR_SEND) {
		if (pSNI_IPCU[unit][mb].stat_tx == true) {
			pr_err("%s:%d [ERROR] stat_tx is failed. stat_tx=%d\n",
				__func__, __LINE__,
				pSNI_IPCU[unit][mb].stat_tx);
			return -EACCES;
		}
		pSNI_IPCU[unit][mb].stat_tx = true;
	} else if (direction == SNI_IPCU_DIR_RECV) {
		if (pSNI_IPCU[unit][mb].stat_rx == true) {
			pr_err("%s:%d [ERROR] stat_rx is failed. stat_rx=%d\n",
				__func__, __LINE__,
				pSNI_IPCU[unit][mb].stat_rx);
			return -EACCES;
		}
		pSNI_IPCU[unit][mb].stat_rx = true;
	} else {
		pr_err("%s:%d [ERROR] direction failed. direction=%d\n",
			__func__, __LINE__, direction);
	}
	trace_ipcu_open_mb(unit, mb, direction);

	return 0;
}

int sni_ipcu_closemb(u32 unit, u32 mb, u32 direction)
{
	int result;

	result = sni_ipcu_sanity_check(CHECK_FUNC_CLOS, unit, mb, direction);
	if (result != 0) {
		pr_err("%s:%d [ERROR] parameter check NG.\n",
			__func__, __LINE__);
		return result;
	}

	pSNI_IPCU[unit][mb].direction  = SNI_IPCU_DIR_INIT;
	if (direction == SNI_IPCU_DIR_SEND) {
		if (pSNI_IPCU[unit][mb].stat_tx == false) {
			pr_err("%s:%d [ERROR] stat_tx is failed. stat_tx=%d\n",
				__func__, __LINE__,
				pSNI_IPCU[unit][mb].stat_tx);
			return -EACCES;
		}
		pSNI_IPCU[unit][mb].stat_tx = false;
	} else if (direction == SNI_IPCU_DIR_RECV) {
		if (pSNI_IPCU[unit][mb].stat_rx == false) {
			pr_err("%s:%d [ERROR] stat_rx is failed. stat_rx=%d\n",
				__func__, __LINE__,
				pSNI_IPCU[unit][mb].stat_rx);
			return -EACCES;
		}
		pSNI_IPCU[unit][mb].stat_rx = false;
	} else {
		pr_err("%s:%d [ERROR] direction failed. direction=%d\n",
			__func__, __LINE__, direction);
	}
	trace_ipcu_close_mb(unit, mb, direction);

	return 0;
}

int sni_ipcu_send_msg(u32 unit, u32 mb, void *buf, u32 len, u32 flags)
{
	unsigned long ret = 0;
	int result;

	result = sni_ipcu_sanity_check(CHECK_FUNC_SEND, unit, mb, len);
	if (result != 0) {
		pr_err("%s:%d [ERROR] parameter check NG.\n",
			__func__, __LINE__);
		return result;
	}

	if (ioread32(ipcu_drv_inf[unit].ipcu_magic_mem + (mb << 2))
						!= SNI_IPCU_MAGIC_CODE) {
		pr_err("%s:%d [ERROR] Not ready destination\n",
			__func__, __LINE__);
		return -EAGAIN;
	}

	ret = copy_from_user(&pSNI_IPCU[unit][mb].data[0], buf, len);
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
		memcpy(data, pSNI_IPCU[unit][mb].data, len);
		ret = sni_ipcu_send_req(unit, mb, data);
		if (ret != 0) {
			pr_err("%s:%d [ERROR] ipcu send error. %d\n",
				__func__, __LINE__, (int)ret);
			return -EBUSY;
		}
	}

	return 0;
}

int sni_ipcu_recv_msg(u32 unit, u32 mb, void *buf, u32 len, u32 flags)
{
	unsigned long timeout;
	unsigned long j, abs_timeout, delta;
	unsigned long ret = 0;
	int result;
	DECLARE_WAITQUEUE(wait, current);

	result = sni_ipcu_sanity_check(CHECK_FUNC_RECV, unit, mb, len);
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

	trace_ipcu_start_recv_msg(unit, mb, buf, flags);

	set_current_state(TASK_INTERRUPTIBLE);
	add_wait_queue(&sni_ipcu_mbctl[unit][mb].rdq, &wait);

	spin_unlock_irq(&lock_shared_mem);

	sni_ipcu_set_magic_code(unit, mb);

	if (timeout == 0x7fffffff) {
		if (sni_ipcu_mbctl[unit][mb].status == STATUS_INIT)
			schedule();
	} else {
		j = jiffies;
		if (abs_timeout >= j)
			delta = abs_timeout - j;
		else
			delta = 0;
		schedule_timeout(delta);
	}

	remove_wait_queue(&sni_ipcu_mbctl[unit][mb].rdq, &wait);

	spin_lock_irq(&lock_shared_mem);
	sni_ipcu_mbctl[unit][mb].status = STATUS_INIT;
	spin_unlock_irq(&lock_shared_mem);

	/* wait was signal */
	if (signal_pending(current)) {
		result = -ERESTARTSYS;	/* EAGAIN? */
		goto end;
	}

	ret = copy_to_user(buf,
			   &pSNI_IPCU[unit][mb].data[0],
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
	sni_ipcu_clear_magic_code(unit, mb);
	trace_ipcu_recv_msg(unit, mb, buf, result);

	return result;
}

int sni_ipcu_recv_flsh(u32 unit, u32 mb)
{
	int result;

	result = sni_ipcu_sanity_check(CHECK_FUNC_FLSH, unit, mb, 0);
	if (result != 0) {
		pr_err("%s:%d [ERROR] parameter check NG.\n",
			__func__, __LINE__);
		return result;
	}

	trace_ipcu_recv_flush(unit, mb);
	wake_up(&sni_ipcu_mbctl[unit][mb].rdq);

	return 0;
}

int sni_ipcu_ack_send(u32 unit, u32 mb)
{
	int result;

	result = sni_ipcu_sanity_check(CHECK_FUNC_ACKS, unit, mb, 0);
	if (result != 0) {
		pr_err("%s:%d [ERROR] parameter check NG.\n",
			__func__, __LINE__);
		return result;
	}

	if (sni_ipcu_send_ack(unit, mb) != 0) {
		pr_err("%s:%d [ERROR] ipcu ack send error\n",
			__func__, __LINE__);
		return -EBUSY;
	}

	return 0;
}

int sni_ipcu_send_msg_kernel(u32 unit, u32 mb,
				void *buf, u32 len, u32 flags)
{
	int result;

	result = sni_ipcu_sanity_check(CHECK_FUNC_SEND, unit, mb, len);
	if (result != 0) {
		pr_err("%s:%d [ERROR] parameter check NG.\n",
			__func__, __LINE__);
		return result;
	}

	if (ioread32(ipcu_drv_inf[unit].ipcu_magic_mem + (mb << 2))
						!= SNI_IPCU_MAGIC_CODE) {
		pr_err("%s:%d [ERROR] Not ready destination\n",
			__func__, __LINE__);
		return -EAGAIN;
	}

	memcpy(&pSNI_IPCU[unit][mb].data[0], buf, len);

	wmb();

	if ((flags & FLAG_SEND_NOTIFY) != 0) {
		if (sni_ipcu_send_req(
				unit, mb,
				pSNI_IPCU[unit][mb].data) != 0) {
			pr_err("%s:%d [ERROR] ipcu send error\n",
				__func__, __LINE__);
			return -EBUSY;
		}
	}

	return 0;
}

int sni_ipcu_recv_msg_kernel(u32 unit, u32 mb,
				void *buf, u32 len, u32 flags)
{
	unsigned long timeout;
	unsigned long j, abs_timeout, delta;
	int result;
	DECLARE_WAITQUEUE(wait, current);

	result = sni_ipcu_sanity_check(CHECK_FUNC_RECV, unit, mb, len);
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

	trace_ipcu_start_recv_msg(unit, mb, buf, flags);

	set_current_state(TASK_INTERRUPTIBLE);
	add_wait_queue(&sni_ipcu_mbctl[unit][mb].rdq, &wait);

	spin_unlock_irq(&lock_shared_mem);

	sni_ipcu_set_magic_code(unit, mb);

	if (timeout == 0x7fffffff) {
		if (sni_ipcu_mbctl[unit][mb].status ==
						STATUS_INIT)
			schedule();
	} else {
		j = jiffies;
		if (abs_timeout >= j)
			delta = abs_timeout - j;
		else
			delta = 0;
		schedule_timeout(delta);
	}

	remove_wait_queue(&sni_ipcu_mbctl[unit][mb].rdq, &wait);

	spin_lock_irq(&lock_shared_mem);
	sni_ipcu_mbctl[unit][mb].status = STATUS_INIT;
	spin_unlock_irq(&lock_shared_mem);

	/* wait was signal */
	if (signal_pending(current)) {
		result = -ERESTARTSYS;
		goto end;
	}

	memcpy(buf, &pSNI_IPCU[unit][mb].data[0],
				(IPCU_MAX_DATA * sizeof(int)));
	wmb();

	if (timeout != 0x7fffffff) {
		j = jiffies;
		if (time_after(j, abs_timeout)) {
			result = -ETIME;
			goto end;
		}
	}
end:
	sni_ipcu_clear_magic_code(unit, mb);
	trace_ipcu_recv_msg(unit, mb, buf, result);

	return result;
}

dma_addr_t ipcu_dma_map_single(int unit, void *ptr,
				size_t size,
				enum dma_data_direction dir)
{
	return dma_map_single(ipcu_drv_inf[unit].dev, ptr, size, dir);
}

void ipcu_dma_unmap_single(int unit, dma_addr_t addr,
				size_t size,
				enum dma_data_direction dir)
{
	dma_unmap_single(ipcu_drv_inf[unit].dev,addr, size, dir);
}

void ipcu_dma_unmap_page(int unit, dma_addr_t addr,
				size_t size,
				enum dma_data_direction dir)
{
	dma_unmap_page(ipcu_drv_inf[unit].dev, addr, size, dir);
}
