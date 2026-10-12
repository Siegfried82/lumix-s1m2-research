/**
 * Copyright (C) 2015 Socionext Semiconductor Ltd.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 2 of the License.
 *
 * @file   sni_dsp_ipcu_drv.c
 * @author
 * @date
 * @brief  SNI IPCU device driver
 */

#include <linux/module.h>
#include <linux/fs.h>
#include <linux/of_platform.h>
#include <linux/uaccess.h>
#include <linux/io.h>
#include <linux/sni_dsp_ipcu_userland.h>

#include "sni_dsp_ipcu_drv.h"
#include <linux/sni_dsp_ipcu_parts.h>
#include "sni_dsp_ipcu_comm.h"

#include <linux/shared_mem.h>

#define DEV_COUNT 1

struct ipcu_driver_info ipcu_dsp_drv_inf;


void print_drv_info(struct ipcu_driver_info *drv_info, unsigned int mb)
{
	pr_debug("--- probe : io_mem=0x%llx, dest_mb=%d, dst_int_ch=%d, src_int_ch=%d\n",
			(u64)drv_info->ipcu_io_mem,
			drv_info->dest_mb[mb], drv_info->dst_int_ch[mb], drv_info->src_int_ch[mb]);
	pr_debug("          : ipcu_rec_irq=%d, ipcu_ack_irq=%d\n",
			drv_info->ipcu_rec_irq[mb], drv_info->ipcu_ack_irq[mb]);
}

/* ioctl */
static long sni_dsp_ipcu_drv_ioctl(struct file *filp,
			       unsigned int cmd,
			       unsigned long arg)
{
	int err = 0;
	int rc = 0;
	struct ipcu_dsp_open_close_ch_argv ipcu_open_close_channel;
	struct ipcu_dsp_send_recv_msg_argv ipcu_send_recv_message;
	struct miscdevice *mdev = filp->private_data;
	struct sni_dsp_ipcu_device *sni_dsp_ipcu_dev =
			container_of(mdev, struct sni_dsp_ipcu_device, miscdev);


	if (_IOC_TYPE(cmd) != IPCU_DSP_IOCTL_MAGIC)
		return -ENOTTY;

	if (_IOC_NR(cmd) > IPCU_DSP_IOCTL_MAXNR)
		return -ENOTTY;

	if (_IOC_DIR(cmd) & _IOC_READ) {
		err = !access_ok(VERIFY_WRITE,
			(void __user *)arg, _IOC_SIZE(cmd));
	} else if (_IOC_DIR(cmd) & _IOC_WRITE) {
		err = !access_ok(VERIFY_READ,
				(void __user *)arg, _IOC_SIZE(cmd));
	}

	if (err)
		return -EFAULT;

	switch (cmd) {
	case IPCU_DSP_IOCTL_OPENCH:
		if (copy_from_user(&ipcu_open_close_channel,
				   (void *)arg,
				   sizeof(ipcu_open_close_channel))) {
			pr_err("%s:%d copy_from_user failed\n",
						__func__, __LINE__);
			return -EFAULT;
		}

		rc = sni_dsp_ipcu_mb_init(
				sni_dsp_ipcu_dev->dest_mb,
				ipcu_open_close_channel.direction,
				sni_dsp_ipcu_dev);
		if (rc < 0) {
			pr_err("%s:%d [ERROR] cannot init ipcu channel.\n",
							__func__, __LINE__);
			return rc;
		}

		rc = sni_dsp_ipcu_openmb(
				sni_dsp_ipcu_dev->dest_mb,
				ipcu_open_close_channel.direction);
		if (rc < 0) {
			pr_err("%s:%d [ERROR] sni_dsp_ipcu_openmb(): %d\n",
						__func__, __LINE__, rc);
			return rc;
		}
		break;

	case IPCU_DSP_IOCTL_CLOSECH:
		if (copy_from_user(&ipcu_open_close_channel,
				   (void *)arg,
				   sizeof(ipcu_open_close_channel))) {
			pr_err("%s:%d copy_from_user failed\n",
						__func__, __LINE__);
			return -EFAULT;
		}

		sni_dsp_ipcu_mb_exit(
				sni_dsp_ipcu_dev->dest_mb,
				sni_dsp_ipcu_dev);

		rc = sni_dsp_ipcu_closemb(
				sni_dsp_ipcu_dev->dest_mb,
				ipcu_open_close_channel.direction);
		if (rc < 0) {
			pr_err("%s:%d [ERROR] sni_dsp_ipcu_closemb(): %d\n",
						__func__, __LINE__, rc);
			return rc;
		}
		break;

	case IPCU_DSP_IOCTL_SENDMSG:
		if (copy_from_user(&ipcu_send_recv_message,
				   (void *)arg,
				   sizeof(ipcu_send_recv_message))) {
			pr_err("%s:%d copy_from_user failed\n",
						__func__, __LINE__);
			return -EFAULT;
		}

		rc = sni_dsp_ipcu_send_msg(
				sni_dsp_ipcu_dev->dest_mb,
				ipcu_send_recv_message.buf,
				ipcu_send_recv_message.len,
				ipcu_send_recv_message.flags);
		if (rc < 0) {
			pr_err("%s:%d [ERROR] sni_dsp_ipcu_send_msg(): %d\n",
						__func__, __LINE__, rc);
			return rc;
		}
		break;

	case IPCU_DSP_IOCTL_RECVMSG:
		if (copy_from_user(&ipcu_send_recv_message,
				   (void *)arg,
				   sizeof(ipcu_send_recv_message))) {
			pr_err("%s:%d copy_from_user failed\n",
						__func__, __LINE__);
			return -EFAULT;
		}

		rc = sni_dsp_ipcu_recv_msg(
				sni_dsp_ipcu_dev->dest_mb,
				ipcu_send_recv_message.buf,
				ipcu_send_recv_message.len,
				ipcu_send_recv_message.flags);
		if (rc < 0) {
			if (rc != -ERESTARTSYS) {
				pr_err("%s:%d [ERROR]sni_dsp_ipcu_recv_msg():%d\n",
					__func__, __LINE__, rc);
			}
			return rc;
		}

		if (copy_to_user((void *)arg,
				 &ipcu_send_recv_message,
				 sizeof(ipcu_send_recv_message))) {
			pr_err("%s:%d copy_to_user failed\n",
					__func__, __LINE__);
			return -EFAULT;
		}
		break;

	case IPCU_DSP_IOCTL_RECV_FLASH:
		if (copy_from_user(&ipcu_send_recv_message,
				   (void *)arg,
				   sizeof(ipcu_send_recv_message))) {
			pr_err("%s:%d copy_from_user failed\n",
						__func__, __LINE__);
			return -EFAULT;
		}

		rc = sni_dsp_ipcu_recv_flsh(
				sni_dsp_ipcu_dev->dest_mb);
		if (rc < 0) {
			pr_err("%s:%d [ERROR] sni_dsp_ipcu_send_msg(): %d\n",
						__func__, __LINE__, rc);
			return rc;
		}

		break;

	case IPCU_DSP_IOCTL_ACKSEND:
		if (copy_from_user(&ipcu_send_recv_message,
				   (void *)arg,
				   sizeof(ipcu_send_recv_message))) {
			pr_err("%s:%d copy_from_user failed\n",
						__func__, __LINE__);
			return -EFAULT;
		}

		rc = sni_dsp_ipcu_ack_send(
				sni_dsp_ipcu_dev->dest_mb);
		if (rc < 0) {
			pr_err("%s:%d [ERROR] sni_dsp_ipcu_send_msg(): %d\n",
						__func__, __LINE__, rc);
			return rc;
		}

		break;

	default:
		pr_err("%s:%d [ERROR] unknown command: %d\n",
					__func__, __LINE__, cmd);
		return -EINVAL;
	}

	return rc;
}

/* .open */
static int sni_dsp_ipcu_drv_open(struct inode *inode, struct file *file)
{
	struct miscdevice *mdev = file->private_data;
	struct sni_dsp_ipcu_device *sni_dsp_ipcu_dev =
			container_of(mdev, struct sni_dsp_ipcu_device, miscdev);
	int ret;


	mutex_lock(&sni_dsp_ipcu_dev->mlock);
	ret = nonseekable_open(inode, file);
	mutex_unlock(&sni_dsp_ipcu_dev->mlock);
	return ret;
}

/* .release */
static int sni_dsp_ipcu_drv_release(struct inode *inode, struct file *file)
{
#if 0
	struct miscdevice *mdev = file->private_data;
	struct sni_dsp_ipcu_device *sni_dsp_ipcu_dev =
			container_of(mdev, struct sni_dsp_ipcu_device, miscdev);
#endif
	return 0;
}

/* The file operations for the rena_share_mem */
struct file_operations sni_dsp_ipcu_drv_fops = {
	.owner		= THIS_MODULE,
	.unlocked_ioctl = sni_dsp_ipcu_drv_ioctl,
	.open		= sni_dsp_ipcu_drv_open,
	.release	= sni_dsp_ipcu_drv_release,
	.llseek		= no_llseek,
};

static int sni_dsp_ipcu_drv_probe(struct platform_device *pdev)
{
	struct device *dev = &pdev->dev;
	struct sni_dsp_ipcu_device *sni_dsp_ipcu_dev;
	struct resource	*res_mem;
	struct resource	*res_irq;
	void __iomem *io_mem;
	u32 dest_mb = 0;
	u32 src_int_ch = 0, dst_int_ch = 0;
	int ret;

	sni_dsp_ipcu_dev = devm_kzalloc(dev, sizeof(*sni_dsp_ipcu_dev), GFP_KERNEL);
	if (!sni_dsp_ipcu_dev)
		return -ENOMEM;

	if (of_property_read_u32(dev->of_node, "dst-mb",
							&dest_mb)) {
		dev_err(dev, "%s:%d No RTOS channel i/f provided\n",
						__func__, __LINE__);
		return -EINVAL;
	}
	if (dest_mb >= IPCU_MAX_MB) {
		dev_err(dev, "Invalid destination mb i/f %d\n",
							dest_mb);
		return -EINVAL;
	}
	sni_dsp_ipcu_dev->dest_mb = dest_mb;

	if (of_property_read_u32(dev->of_node, "src-int-ch",
							&src_int_ch))
		src_int_ch = dest_mb + IO_DSP_IPCU_INT_ACK_UNIT;
	if (src_int_ch >= IPCU_MAX_CH) {
		dev_err(dev, "Invalid src_int_ch i/f %d\n",
							src_int_ch);
		return -EINVAL;
	}
	if (of_property_read_u32(dev->of_node, "dst-int-ch",
							&dst_int_ch)) {
		dst_int_ch = dest_mb;
	}
	if (dst_int_ch >= IPCU_MAX_CH) {
		dev_err(dev, "Invalid dst_int_ch i/f %d\n",
							dst_int_ch);
		return -EINVAL;
	}

	if (dest_mb == 0) {
		res_mem = platform_get_resource(pdev, IORESOURCE_MEM, 0);
		if (!res_mem) {
			dev_err(dev, "No IOMEM found\n");
			return -ENXIO;
		}

		io_mem = devm_ioremap(dev,
				res_mem->start,
				resource_size(res_mem));
		if (!io_mem) {
			dev_err(dev, "ioremap failed.\n");
			return -ENXIO;
		}
		ipcu_dsp_drv_inf.ipcu_io_mem = io_mem;
		ipcu_dsp_drv_inf.dev = dev;
	}

	res_irq = platform_get_resource(pdev, IORESOURCE_IRQ, 0);
	if (!res_irq) {
		dev_err(dev, "No IRQ found\n");
		return -ENXIO;
	}

	ret = dma_set_mask_and_coherent(&pdev->dev, DMA_BIT_MASK(40));
	if (ret < 0)
		dev_err(dev, "dma_set_mask_and_coherent failed\n");

	if (of_property_match_string(dev->of_node,
					"direction",
					"recv") == 0) {
		ipcu_dsp_drv_inf.ipcu_rec_irq[dest_mb] = res_irq->start;
		ipcu_dsp_drv_inf.ipcu_ack_irq[dest_mb] = -1;
		pr_debug("--- dest_mb=%d recv irq=%lld\n", dest_mb, res_irq->start);
	} else if (of_property_match_string(dev->of_node,
					"direction",
					"send") == 0) {
		ipcu_dsp_drv_inf.ipcu_rec_irq[dest_mb] = -1;
		ipcu_dsp_drv_inf.ipcu_ack_irq[dest_mb] = res_irq->start;
		pr_debug("--- dest_mb=%d send irq=%lld\n", dest_mb, res_irq->start);
	} else {
		dev_err(dev, "%s:%d Direction not found\n",
			__func__, __LINE__);
		return -EINVAL;
	}

	ipcu_dsp_drv_inf.src_int_ch[dest_mb] = src_int_ch;
	ipcu_dsp_drv_inf.dst_int_ch[dest_mb] = dst_int_ch;

	mutex_init(&sni_dsp_ipcu_dev->mlock);

	snprintf(sni_dsp_ipcu_dev->devname, 24, "dsp_ipcu%d",
					sni_dsp_ipcu_dev->dest_mb);
	sni_dsp_ipcu_dev->miscdev.name = sni_dsp_ipcu_dev->devname;
	sni_dsp_ipcu_dev->miscdev.minor = MISC_DYNAMIC_MINOR,
	sni_dsp_ipcu_dev->miscdev.fops = &sni_dsp_ipcu_drv_fops,

	print_drv_info(&ipcu_dsp_drv_inf, dest_mb);
	pr_debug("--- probe : %s, dest_mb=%d\n", sni_dsp_ipcu_dev->devname, sni_dsp_ipcu_dev->dest_mb);

	platform_set_drvdata(pdev, sni_dsp_ipcu_dev);

	init_completion(&ipcu_dsp_drv_inf.ack_notify[dest_mb]);

	return misc_register(&sni_dsp_ipcu_dev->miscdev);
}

static int sni_dsp_ipcu_drv_remove(struct platform_device *pdev)
{
	struct sni_dsp_ipcu_device *sni_dsp_ipcu_dev = platform_get_drvdata(pdev);

	if (sni_dsp_ipcu_dev->dest_mb == 0) {
		if (ipcu_dsp_drv_inf.ipcu_io_mem != NULL) {
			devm_iounmap(
			&pdev->dev,
			ipcu_dsp_drv_inf.ipcu_io_mem);
		}
	}

	misc_deregister(&sni_dsp_ipcu_dev->miscdev);
	return 0;
}

static const struct of_device_id sni_dsp_ipcu_id[] = {
	{ .compatible = "socionext,dsp-ipcu-device" },
	{},
};
MODULE_DEVICE_TABLE(of, sni_dsp_ipcu_id);

static struct platform_driver sni_dsp_ipcu_driver = {
	.probe = sni_dsp_ipcu_drv_probe,
	.remove = sni_dsp_ipcu_drv_remove,
	.driver = {
		.name = "sni-dsp-ipcu-driver",
		.of_match_table = sni_dsp_ipcu_id,
	},
};
module_platform_driver(sni_dsp_ipcu_driver);

MODULE_LICENSE("GPL");
