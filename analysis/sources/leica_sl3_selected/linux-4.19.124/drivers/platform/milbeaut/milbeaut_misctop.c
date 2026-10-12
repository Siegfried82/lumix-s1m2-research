// SPDX-License-Identifier: GPL-2.0
/*
 * copyright (C) 2019 Socionext Inc.
 *               Takao Orito <<REDACTED_EMAIL>>
 */

#include <linux/delay.h>
#include <linux/fs.h>
#include <linux/io.h>
#include <linux/ioctl.h>
#include <linux/milbeaut_misctop_drv.h>
#include <linux/miscdevice.h>
#include <linux/module.h>
#include <linux/of_platform.h>
#include <linux/uaccess.h>
#include <linux/version.h>
#include <uapi/linux/milbeaut_misctop.h>

#define DEVICE_NAME	"misctop"

#define DBG(f, x...) \
	pr_debug(DEVICE_NAME " [%s()]: " f, __func__, ## x)

#define RAMSLP3	0x70c
#define RAMSD3	0x71c
#define  WE_BIT_SHIFT	16

#define RAMSLP_MASK	(MISCTOP_RAM_FUNC_NETSEC | MISCTOP_RAM_FUNC_USB \
					| MISCTOP_RAM_FUNC_PCIE0 | MISCTOP_RAM_FUNC_PCIE1)
#define RAMSD_MASK	(MISCTOP_RAM_FUNC_NF | MISCTOP_RAM_FUNC_USB \
					| MISCTOP_RAM_FUNC_PCIE0 | MISCTOP_RAM_FUNC_PCIE1)

struct mlb_misctop_device {
	struct miscdevice miscdev;
	char devname[12];
	struct mutex mlock;
	void __iomem *ioaddr;
};

static struct mlb_misctop_device *mlb_misctop_device_info;

int milbeaut_misctop_set_ramslp(struct milbeaut_misctop_argv *param)
{
	u32 value = (u32)param->func_flag;

	while (mlb_misctop_device_info == NULL) {
		pr_err("%s: %s: device is NOT initialized\n",
			DEVICE_NAME, __func__);
		return -EAGAIN;
	}

	if (value & ~RAMSLP_MASK) {
		pr_err("%s: not supported func flag (0x%08x)\n",
				DEVICE_NAME,
				(unsigned int)(value & ~RAMSLP_MASK));
		return -EINVAL;
	}
	value |= value << WE_BIT_SHIFT;

	writel(value, mlb_misctop_device_info->ioaddr + RAMSLP3);

	DBG("writel: reg=0x%08lx, value=0x%08x\n",
		(unsigned long)(mlb_misctop_device_info->ioaddr + RAMSLP3),
		(unsigned int)value);

	return 0;
}

int milbeaut_misctop_set_ramsd(struct milbeaut_misctop_argv *param)
{
	u32 value = (u32)param->func_flag;

	while (mlb_misctop_device_info == NULL) {
		pr_err("%s: %s: device is NOT initialized\n",
			DEVICE_NAME, __func__);
		return -EAGAIN;
	}

	if (value & ~RAMSD_MASK) {
		pr_err("%s: not supported func flag (0x%08x)\n",
				DEVICE_NAME,
				(unsigned int)(value & ~RAMSD_MASK));
		return -EINVAL;
	}
	value |= value << WE_BIT_SHIFT;

	writel(value, mlb_misctop_device_info->ioaddr + RAMSD3);

	DBG("writel: reg=0x%08lx, value=0x%08x\n",
		(unsigned long)(mlb_misctop_device_info->ioaddr + RAMSD3),
		(unsigned int)value);

	return 0;
}

int milbeaut_misctop_clear_ramslp(struct milbeaut_misctop_argv *param)
{
	u32 value = (u32)param->func_flag;

	while (mlb_misctop_device_info == NULL) {
		pr_err("%s: %s: device is NOT initialized\n",
			DEVICE_NAME, __func__);
		return -EAGAIN;
	}

	if (value & ~RAMSLP_MASK) {
		pr_err("%s: not supported func flag (0x%08x)\n",
				DEVICE_NAME,
				(unsigned int)(value & ~RAMSLP_MASK));
		return -EINVAL;
	}
	value <<= WE_BIT_SHIFT;

	writel(value, mlb_misctop_device_info->ioaddr + RAMSLP3);

	DBG("writel: reg=0x%08lx, value=0x%08x\n",
		(unsigned long)(mlb_misctop_device_info->ioaddr + RAMSLP3),
		(unsigned int)value);

	return 0;
}

int milbeaut_misctop_clear_ramsd(struct milbeaut_misctop_argv *param)
{
	u32 value = (u32)param->func_flag;

	while (mlb_misctop_device_info == NULL) {
		pr_err("%s: %s: device is NOT initialized\n",
			DEVICE_NAME, __func__);
		return -EAGAIN;
	}

	if (value & ~RAMSD_MASK) {
		pr_err("%s: not supported func flag (0x%08x)\n",
				DEVICE_NAME,
				(unsigned int)(value & ~RAMSD_MASK));
		return -EINVAL;
	}
	value <<= WE_BIT_SHIFT;

	writel(value, mlb_misctop_device_info->ioaddr + RAMSD3);

	DBG("writel: reg=0x%08lx, value=0x%08x\n",
		(unsigned long)(mlb_misctop_device_info->ioaddr + RAMSD3),
		(unsigned int)value);

	return 0;
}

int milbeaut_misctop_get_ramslp(struct milbeaut_misctop_argv *param)
{
	u32 value;

	while (mlb_misctop_device_info == NULL) {
		pr_err("%s: %s: device is NOT initialized\n",
			DEVICE_NAME, __func__);
		return -EAGAIN;
	}

	value = readl(mlb_misctop_device_info->ioaddr + RAMSLP3);
	value &= RAMSLP_MASK;
	param->func_flag = value;

	DBG("readl: reg=0x%08lx, value=0x%08x\n",
		(unsigned long)(mlb_misctop_device_info->ioaddr + RAMSLP3),
		(unsigned int)value);

	return 0;
}

int milbeaut_misctop_get_ramsd(struct milbeaut_misctop_argv *param)
{
	u32 value;

	while (mlb_misctop_device_info == NULL) {
		pr_err("%s: %s: device is NOT initialized\n",
			DEVICE_NAME, __func__);
		return -EAGAIN;
	}

	value = readl(mlb_misctop_device_info->ioaddr + RAMSD3);
	value &= RAMSD_MASK;
	param->func_flag = value;

	DBG("readl: reg=0x%08lx, value=0x%08x\n",
		(unsigned long)(mlb_misctop_device_info->ioaddr + RAMSD3),
		(unsigned int)value);

	return 0;
}

static long milbeaut_misctop_ioctl(struct file *filp,
			       unsigned int cmd,
			       unsigned long arg)
{
	int err = 0;
//	struct miscdevice *mdev = filp->private_data;
//	struct mlb_misctop_device *misctop_dev =
//			container_of(mdev, struct mlb_misctop_device, miscdev);
	struct milbeaut_misctop_argv misctop_argv;

	if (_IOC_TYPE(cmd) != MISCTOP_IOCTL_MAGIC)
		return -ENOTTY;

	if (_IOC_NR(cmd) > MISCTOP_IOCTL_MAXNR)
		return -ENOTTY;

	if (_IOC_DIR(cmd) & _IOC_READ) {
#if LINUX_VERSION_CODE < KERNEL_VERSION(5, 0, 0)
		err = !access_ok(VERIFY_WRITE,
				(void __user *)arg, _IOC_SIZE(cmd));
#else
		err = !access_ok((void __user *)arg, _IOC_SIZE(cmd));
#endif
	} else if (_IOC_DIR(cmd) & _IOC_WRITE) {
#if LINUX_VERSION_CODE < KERNEL_VERSION(5, 0, 0)
		err = !access_ok(VERIFY_READ,
				(void __user *)arg, _IOC_SIZE(cmd));
#else
		err = !access_ok((void __user *)arg, _IOC_SIZE(cmd));
#endif
	}

	if (err)
		return -EFAULT;

	switch (cmd) {
	case MISCTOP_IOCTL_SET_RAMSLP:
		DBG("MISCTOP_IOCTL_SET_RAMSLP route\n");
		if (copy_from_user(&misctop_argv,
				   (void *)arg,
				   sizeof(struct milbeaut_misctop_argv))) {
			pr_err("%s: %s: %d: copy_from_user failed\n",
						DEVICE_NAME, __func__, __LINE__);
			return -EFAULT;
		}

		err = milbeaut_misctop_set_ramslp(&misctop_argv);
		break;
	case MISCTOP_IOCTL_CLEAR_RAMSLP:
		DBG("MISCTOP_IOCTL_CLEAR_RAMSLP route\n");
		if (copy_from_user(&misctop_argv,
				   (void *)arg,
				   sizeof(struct milbeaut_misctop_argv))) {
			pr_err("%s: %s: %d:  copy_from_user failed\n",
					DEVICE_NAME, __func__, __LINE__);
			return -EFAULT;
		}

		err = milbeaut_misctop_clear_ramslp(&misctop_argv);
		break;
	case MISCTOP_IOCTL_GET_RAMSLP:
		DBG("MISCTOP_IOCTL_GET_RAMSLP route\n");

		err = milbeaut_misctop_get_ramslp(&misctop_argv);
		if (err != 0)
			return err;
		if (copy_to_user((void *)arg,
				&misctop_argv,
				sizeof(struct milbeaut_misctop_argv))) {
			pr_err("%s: %s: %d:  copy_to_user failed\n",
					DEVICE_NAME, __func__, __LINE__);
			return -EFAULT;
		}
		break;
	case MISCTOP_IOCTL_SET_RAMSD:
		DBG("MISCTOP_IOCTL_SET_RAMSD route\n");
		if (copy_from_user(&misctop_argv,
				   (void *)arg,
				   sizeof(struct milbeaut_misctop_argv))) {
			pr_err("%s: %s: %d: copy_from_user failed\n",
						DEVICE_NAME, __func__, __LINE__);
			return -EFAULT;
		}

		err = milbeaut_misctop_set_ramsd(&misctop_argv);
		break;
	case MISCTOP_IOCTL_CLEAR_RAMSD:
		DBG("MISCTOP_IOCTL_CLEAR_RAMSD route\n");
		if (copy_from_user(&misctop_argv,
				   (void *)arg,
				   sizeof(struct milbeaut_misctop_argv))) {
			pr_err("%s: %s: %d:  copy_from_user failed\n",
					DEVICE_NAME, __func__, __LINE__);
			return -EFAULT;
		}

		err = milbeaut_misctop_clear_ramsd(&misctop_argv);
		break;
	case MISCTOP_IOCTL_GET_RAMSD:
		DBG("MISCTOP_IOCTL_GET_RAMSD route\n");

		err = milbeaut_misctop_get_ramsd(&misctop_argv);
		if (err != 0)
			return err;
		if (copy_to_user((void *)arg,
				&misctop_argv,
				sizeof(struct milbeaut_misctop_argv))) {
			pr_err("%s: %s: %d:  copy_to_user failed\n",
					DEVICE_NAME, __func__, __LINE__);
			return -EFAULT;
		}
		break;
	default:
		pr_err("%s:%d [ERROR] unknown command: %d\n",
					__func__, __LINE__, cmd);
		return -EINVAL;
	}

	return err;
}

static int milbeaut_misctop_open(struct inode *inode, struct file *file)
{
	struct miscdevice *mdev = file->private_data;
	struct mlb_misctop_device *misctop_dev =
			container_of(mdev, struct mlb_misctop_device, miscdev);
	int ret;


	mutex_lock(&misctop_dev->mlock);
	ret = nonseekable_open(inode, file);
	mutex_unlock(&misctop_dev->mlock);
	return ret;
}

static int milbeaut_misctop_release(struct inode *inode, struct file *file)
{
#if 0
	struct miscdevice *mdev = file->private_data;
	struct mlb_misctop_device *misctop_dev =
			container_of(mdev, struct mlb_misctop_device, miscdev);
#endif
	return 0;
}

struct file_operations milbeaut_misctop_fops = {
	.owner		= THIS_MODULE,
	.unlocked_ioctl = milbeaut_misctop_ioctl,
	.open		= milbeaut_misctop_open,
	.release	= milbeaut_misctop_release,
	.llseek		= no_llseek,
};

static int milbeaut_misctop_probe(struct platform_device *pdev)
{
	struct mlb_misctop_device *mlb_misctop;
	struct device *dev = &pdev->dev;
	struct resource *res;
	int ret;

	DBG("probe start\n");

	mlb_misctop = devm_kzalloc(dev, sizeof(struct mlb_misctop_device), GFP_KERNEL);
	if (!mlb_misctop)
		return -ENOMEM;

	res = platform_get_resource(pdev, IORESOURCE_MEM, 0);
	mlb_misctop->ioaddr = devm_ioremap_resource(dev, res);
	if (IS_ERR(mlb_misctop->ioaddr)) {
		ret = PTR_ERR(mlb_misctop->ioaddr);
		return ret;
	}

	mutex_init(&mlb_misctop->mlock);
	memcpy(&mlb_misctop->devname, DEVICE_NAME, sizeof(DEVICE_NAME));
	mlb_misctop->miscdev.name = mlb_misctop->devname;
	mlb_misctop->miscdev.minor = MISC_DYNAMIC_MINOR;
	mlb_misctop->miscdev.fops = &milbeaut_misctop_fops;

	platform_set_drvdata(pdev, mlb_misctop);
	mlb_misctop_device_info = mlb_misctop;

	return misc_register(&mlb_misctop->miscdev);
}

static int milbeaut_misctop_remove(struct platform_device *pdev)
{
	struct mlb_misctop_device *mlb_misctop = platform_get_drvdata(pdev);

	DBG("remove start\n");

	devm_iounmap(&pdev->dev, mlb_misctop->ioaddr);

	misc_deregister(&mlb_misctop->miscdev);
	return 0;
}

static const struct of_device_id milbeaut_misctop_id[] = {
	{ .compatible = "socionext,misctop-m20v" },
	{},
};
MODULE_DEVICE_TABLE(of, milbeaut_misctop_id);

static struct platform_driver milbeaut_misctop_driver = {
	.probe = milbeaut_misctop_probe,
	.remove = milbeaut_misctop_remove,
	.driver = {
		.name = "milbeaut-misctop",
		.of_match_table = milbeaut_misctop_id,
	},
};
module_platform_driver(milbeaut_misctop_driver);

MODULE_DESCRIPTION("MILBEAUT MISCTOP controller driver");
MODULE_AUTHOR("Takao Orito <<REDACTED_EMAIL>>");
MODULE_LICENSE("GPL v2");
