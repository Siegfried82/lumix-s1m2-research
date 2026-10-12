// SPDX-License-Identifier: GPL-2.0
/**
 * copyright (C) 2019 Socionext Inc.
 *
 * @file   milbeaut_noc_drv.c
 * @author
 * @date
 * @brief  SNI NOC device driver
 */

#include <linux/delay.h>
#include <linux/fs.h>
#include <linux/io.h>
#include <linux/ioctl.h>
#include <linux/version.h>
#include <linux/miscdevice.h>
#include <linux/module.h>
#include <linux/of_platform.h>
#include <linux/uaccess.h>
#include <linux/milbeaut_noc_drv.h>
#include <uapi/linux/milbeaut_noc.h>

#define DEVICE_NAME	"noc"

#define DBG(f, x...) \
	pr_debug(DEVICE_NAME " [%s()]: " f, __func__, ## x)

#define ARBA_BIT_SHIFT	16
#define BA_BIT_MASK	GENMASK(3, 0)

enum noc_area {
	E_NOC_AREA_02 = 0,
	E_NOC_AREA_11,
	E_NOC_AREA_12,
};

struct noc_regaddr_offset {
	enum E_NOC_BANK_BRIDGE_ID id;
	enum noc_area	area_no;
	int area_offset;
};

const struct noc_regaddr_offset noc_reg_info[] = {
	{E_NOC_BANK_ARM_XDMAC0,		E_NOC_AREA_02, 0},
	{E_NOC_BANK_ARM_XDMAC1,		E_NOC_AREA_02, 4},
	{E_NOC_BANK_PERI_AHB_DMA,	E_NOC_AREA_02, 0x10},
	{E_NOC_BANK_DSP_AHBM,		E_NOC_AREA_02, 0x14},
	{E_NOC_BANK_DSP_XM6_AXIMP0,	E_NOC_AREA_02, 0x18},
	{E_NOC_BANK_DSP_XM6_AXIMD0,	E_NOC_AREA_02, 0x1c},
	{E_NOC_BANK_DSP_XM6_AXIMP1,	E_NOC_AREA_02, 0x20},
	{E_NOC_BANK_DSP_XM6_AXIMD1,	E_NOC_AREA_02, 0x24},
	{E_NOC_BANK_EXS_UHS1_MEM0,	E_NOC_AREA_11, 0},
	{E_NOC_BANK_EXS_UHS1_MEM1,	E_NOC_AREA_11, 4},
	{E_NOC_BANK_EXS_UHS2_MEM0,	E_NOC_AREA_11, 8},
	{E_NOC_BANK_EXS_UHS2_MEM1,	E_NOC_AREA_11, 0xc},
	{E_NOC_BANK_EXS_SDIO_MEM,	E_NOC_AREA_11, 0x10},
	{E_NOC_BANK_EXS_EMMC_MEM,	E_NOC_AREA_11, 0x14},
	{E_NOC_BANK_EXS_XDMAC_MEM,	E_NOC_AREA_12, 0},
	{E_NOC_BANK_EXS_NF_DMA,		E_NOC_AREA_12, 4},
	{E_NOC_BANK_ISP_GPU_2D_GPU2D,	E_NOC_AREA_12, 8},
	{},
};

struct mlb_noc_device {
	struct miscdevice miscdev;
	char devname[12];
	struct mutex mlock;
	void __iomem *ioaddr_bar02;
	void __iomem *ioaddr_bar11;
	void __iomem *ioaddr_bar12;
};

static struct mlb_noc_device *mlb_noc_device_info;

int milbeaut_noc_set_bank(struct milbeaut_noc_bank_argv *param)
{
	int id = 0;
	void __iomem *ioaddr = 0;

	while (mlb_noc_device_info == NULL) {
		pr_err("%s: %s: device is NOT initialized\n",
			DEVICE_NAME, __func__);
		return -EAGAIN;
	}

	if (param->arba & ~BA_BIT_MASK || param->awba & ~BA_BIT_MASK)
		pr_err("%s: arba(%d) or arwa(%d) value is too big\n",
			DEVICE_NAME, param->arba, param->awba);

	while (noc_reg_info[id].id != param->bridge_id &&
		id < E_NOC_BANK_MAX)
		id++;
	if (id >= E_NOC_BANK_MAX) {
		pr_err("%s: not supported bridge_id(%d)\n",
			DEVICE_NAME, id);
		return -EINVAL;
	}
	DBG("bridge_id = %d\n", id);

	switch (noc_reg_info[id].area_no) {
	case E_NOC_AREA_02:
		ioaddr = mlb_noc_device_info->ioaddr_bar02 +
			noc_reg_info[id].area_offset;
		break;
	case E_NOC_AREA_11:
		ioaddr = mlb_noc_device_info->ioaddr_bar11 +
			noc_reg_info[id].area_offset;
		break;
	case E_NOC_AREA_12:
		ioaddr = mlb_noc_device_info->ioaddr_bar12 +
			noc_reg_info[id].area_offset;
		break;
	};

	writel(param->awba << ARBA_BIT_SHIFT | param->arba, ioaddr);

	DBG("writel: add=0x%lx, value=0x%08x\n", (unsigned long)ioaddr,
		(unsigned int)(param->awba << ARBA_BIT_SHIFT | param->arba));

	return 0;
}

int milbeaut_noc_get_bank(struct milbeaut_noc_bank_argv *param)
{
	int id = 0;
	void __iomem *ioaddr = 0;
	u32 val;

	while (noc_reg_info[id].id != param->bridge_id &&
		id < E_NOC_BANK_MAX)
		id++;
	if (id >= E_NOC_BANK_MAX) {
		pr_err("%s: not supported bridge_id(%d)\n",
			DEVICE_NAME, id);
		return -EINVAL;
	}
	DBG("bridge_id = %d\n", id);

	switch (noc_reg_info[id].area_no) {
	case E_NOC_AREA_02:
		ioaddr = mlb_noc_device_info->ioaddr_bar02 +
			noc_reg_info[id].area_offset;
		break;
	case E_NOC_AREA_11:
		ioaddr = mlb_noc_device_info->ioaddr_bar11 +
			noc_reg_info[id].area_offset;
		break;
	case E_NOC_AREA_12:
		ioaddr = mlb_noc_device_info->ioaddr_bar12 +
			noc_reg_info[id].area_offset;
		break;
	};

	val = readl(ioaddr);
	param->awba = val >> ARBA_BIT_SHIFT;
	param->arba = val & BA_BIT_MASK;

	DBG("readl: add=0x%lx, value=0x%08x\n",
		(unsigned long)ioaddr, (unsigned int)val);

	return 0;
}

static long milbeaut_noc_ioctl(struct file *filp,
			       unsigned int cmd,
			       unsigned long arg)
{
	int err = 0;
	struct milbeaut_noc_bank_argv noc_argv;

	if (_IOC_TYPE(cmd) != NOC_IOCTL_MAGIC)
		return -ENOTTY;

	if (_IOC_NR(cmd) > NOC_IOCTL_MAXNR)
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
	case NOC_IOCTL_SET_BANK:
		DBG("iotrl: NOC_IOCTL_SET_BANK\n");
		if (copy_from_user(&noc_argv,
				   (void *)arg,
				   sizeof(struct milbeaut_noc_bank_argv))) {
			pr_err("%s: %s: %d: copy_from_user failed\n",
				DEVICE_NAME, __func__, __LINE__);
			return -EFAULT;
		}

		err = milbeaut_noc_set_bank(&noc_argv);
		break;
	case NOC_IOCTL_GET_BANK:
		DBG("iotrl: NOC_IOCTL_GET_BANK\n");
		if (copy_from_user(&noc_argv,
				   (void *)arg,
				   sizeof(struct milbeaut_noc_bank_argv))) {
			pr_err("%s: %s: %d: copy_from_user failed\n",
				DEVICE_NAME, __func__, __LINE__);
			return -EFAULT;
		}

		err = milbeaut_noc_get_bank(&noc_argv);
		if (err != 0)
			return err;
		if (copy_to_user((void *)arg,
				&noc_argv,
				sizeof(struct milbeaut_noc_bank_argv))) {
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

static int milbeaut_noc_open(struct inode *inode, struct file *file)
{
	struct miscdevice *mdev = file->private_data;
	struct mlb_noc_device *noc_dev =
			container_of(mdev, struct mlb_noc_device, miscdev);
	int ret;


	mutex_lock(&noc_dev->mlock);
	ret = nonseekable_open(inode, file);
	mutex_unlock(&noc_dev->mlock);
	return ret;
}

static int milbeaut_noc_release(struct inode *inode, struct file *file)
{
	return 0;
}

const struct file_operations milbeaut_noc_fops = {
	.owner		= THIS_MODULE,
	.unlocked_ioctl = milbeaut_noc_ioctl,
	.open		= milbeaut_noc_open,
	.release	= milbeaut_noc_release,
	.llseek		= no_llseek,
};

static int milbeaut_noc_probe(struct platform_device *pdev)
{
	struct mlb_noc_device *mlb_noc;
	struct device *dev = &pdev->dev;
	struct resource *res;
	int ret;

	DBG("probe start\n");

	mlb_noc = devm_kzalloc(dev, sizeof(struct mlb_noc_device), GFP_KERNEL);
	if (!mlb_noc)
		return -ENOMEM;

	res = platform_get_resource_byname(pdev, IORESOURCE_MEM,
		"bar02");
	mlb_noc->ioaddr_bar02 = devm_ioremap_resource(dev, res);
	if (IS_ERR(mlb_noc->ioaddr_bar02)) {
		ret = PTR_ERR(mlb_noc->ioaddr_bar02);
		return ret;
	}
	res = platform_get_resource_byname(pdev, IORESOURCE_MEM,
		"bar11");
	mlb_noc->ioaddr_bar11 = devm_ioremap_resource(dev, res);
	if (IS_ERR(mlb_noc->ioaddr_bar11)) {
		ret = PTR_ERR(mlb_noc->ioaddr_bar11);
		return ret;
	}
	res = platform_get_resource_byname(pdev, IORESOURCE_MEM,
		"bar12");
	mlb_noc->ioaddr_bar12 = devm_ioremap_resource(dev, res);
	if (IS_ERR(mlb_noc->ioaddr_bar12)) {
		ret = PTR_ERR(mlb_noc->ioaddr_bar12);
		return ret;
	}

	mutex_init(&mlb_noc->mlock);
	memcpy(&mlb_noc->devname, DEVICE_NAME, sizeof(DEVICE_NAME));
	mlb_noc->miscdev.name = mlb_noc->devname;
	mlb_noc->miscdev.minor = MISC_DYNAMIC_MINOR,
	mlb_noc->miscdev.fops = &milbeaut_noc_fops,

	platform_set_drvdata(pdev, mlb_noc);
	mlb_noc_device_info = mlb_noc;

	return misc_register(&mlb_noc->miscdev);
}

static int milbeaut_noc_remove(struct platform_device *pdev)
{
	struct mlb_noc_device *mlb_noc = platform_get_drvdata(pdev);

	DBG("remove start\n");

	devm_iounmap(&pdev->dev, mlb_noc->ioaddr_bar02);
	devm_iounmap(&pdev->dev, mlb_noc->ioaddr_bar11);
	devm_iounmap(&pdev->dev, mlb_noc->ioaddr_bar12);

	misc_deregister(&mlb_noc->miscdev);
	return 0;
}

static const struct of_device_id milbeaut_noc_id[] = {
	{ .compatible = "socionext,noc-m20v" },
	{},
};
MODULE_DEVICE_TABLE(of, milbeaut_noc_id);

static struct platform_driver milbeaut_noc_driver = {
	.probe = milbeaut_noc_probe,
	.remove = milbeaut_noc_remove,
	.driver = {
		.name = "milbeaut-noc",
		.of_match_table = milbeaut_noc_id,
	},
};
module_platform_driver(milbeaut_noc_driver);

MODULE_LICENSE("GPL");
