/**
 * Copyright (C) 2019 Socionext Inc.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 2 of the License.
 *
 * @file   sni_dsp_drv_karine.h
 * @author
 * @date
 * @brief  SNI XM6/CNN device driver
 */


#ifndef __SNI_DSP_DRV_KARINE_H
#define __SNI_DSP_DRV_KARINE_H

#include <linux/init.h>
#include <linux/sched.h>
#include <linux/module.h>
#include <linux/version.h>
#include <linux/kernel.h>
#include <linux/moduleparam.h>
#include <linux/types.h>
#include <linux/fs.h>
#include <linux/cdev.h>
#include <linux/ioctl.h>
#include <linux/poll.h>
#include <linux/interrupt.h>
#include <linux/io.h>
#include <linux/uaccess.h>

#include <linux/miscdevice.h>
#include <linux/of_platform.h>
#include <linux/clk.h>

#include <linux/dsp_userland.h>
#include <linux/printk.h>
#include <linux/dma-mapping.h>
#include <linux/completion.h>

#include <linux/dmaengine.h>


struct sni_dsp_device {
	struct miscdevice miscdev;
	char devname[24];
	struct mutex mlock;
	struct dma_chan	*chan;
};

struct sni_xm6_ipcu_device {
	struct miscdevice miscdev;
	char devname[24];
	struct mutex mlock;
	unsigned int  unit;
};

#endif	/* __SNI_DSP_DRV_KARINE_H */
