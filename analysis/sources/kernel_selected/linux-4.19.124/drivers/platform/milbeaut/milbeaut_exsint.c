// SPDX-License-Identifier: GPL-2.0
/*
 * copyright (C) 2019 Socionext Inc.
 *               Takao Orito <<REDACTED_EMAIL>>
 */

#include <linux/delay.h>
#include <linux/io.h>
#include <linux/ioctl.h>
#include <linux/interrupt.h>
#include <linux/miscdevice.h>
#include <linux/module.h>
#include <linux/of_platform.h>
#include <linux/version.h>

#define DEVICE_NAME	"exsint"

#define DBG(f, x...) \
	pr_debug(DEVICE_NAME " [%s()]: " f, __func__, ## x)

/* M10V */
/* INTMSK */
#define M10V_INTMSK_USB3_VBUS_RISE	BIT(14)
#define M10V_INTMSK_USB3_VBUS_FALL	BIT(15)
/* INTSTAT */
#define M10V_INTSTAT_USB3_VBUS_RISE	BIT(14)
#define M10V_INTSTAT_USB3_VBUS_FALL	BIT(15)

/* M20V */
#define M20V_DEBRSTX	0
#define  DEBRSTX_RSTX	BIT(0)
#define M20V_DEBCNTL	4
/* DEBCNTL04 INTMSK bit */
#define M20V_INTMSK_USB3_VBUS_RISE	BIT(8)
#define M20V_INTMSK_USB3_VBUS_FALL	BIT(9)
/* INTSTAT */
#define M20V_INTSTAT_USB3_VBUS_RISE	BIT(0)
#define M20V_INTSTAT_USB3_VBUS_FALL	BIT(1)

enum mlb_exsint_variants {
	MLB_EXSINT_VAR_M10V,
	MLB_EXSINT_VAR_M20V
};

struct mlb_exsint_device {
	enum mlb_exsint_variants variant;
	struct miscdevice miscdev;
	char devname[12];
	spinlock_t lock;
	void __iomem *iomsk;
	void __iomem *iostat;
	struct device *dev;
	u32	int_r_flag;
	u32	int_f_flag;
	u32	stat;
	struct tasklet_struct tasklet;
};

static void sn_exs_notify_tasklet(unsigned long data)
{
	struct mlb_exsint_device *mlb_exsint = (struct mlb_exsint_device *)data;
	char uchger_state[50] = { 0 };
	char *envp[] = { uchger_state, NULL };
	unsigned long flags;

	spin_lock_irqsave(&mlb_exsint->lock, flags);

	if (mlb_exsint->stat & mlb_exsint->int_r_flag) {
		snprintf(uchger_state, ARRAY_SIZE(uchger_state),
			"UDC_VBUS=%s", "VBUS_PRESENT");
		mlb_exsint->stat &= ~mlb_exsint->int_r_flag;
	} else if (mlb_exsint->stat & mlb_exsint->int_f_flag ) {
		snprintf(uchger_state, ARRAY_SIZE(uchger_state),
			 "UDC_VBUS=%s", "VBUS_ABSENT");
		mlb_exsint->stat &= ~mlb_exsint->int_f_flag;
	}

	kobject_uevent_env(&mlb_exsint->dev->kobj, KOBJ_CHANGE, envp);

	spin_unlock_irqrestore(&mlb_exsint->lock, flags);
}

static irqreturn_t sn_exs_irq(int irq, void *_mlb_exsint)
{
	struct mlb_exsint_device *mlb_exsint = _mlb_exsint;
	u32 val;

	/* Read some exstop register to check vbus flag */
	val = readl_relaxed(mlb_exsint->iostat);
	if (val & mlb_exsint->int_r_flag) {
		mlb_exsint->stat |= mlb_exsint->int_r_flag;
		writel_relaxed(mlb_exsint->int_r_flag, mlb_exsint->iostat);
	} else if (val & mlb_exsint->int_f_flag) {
		mlb_exsint->stat |= mlb_exsint->int_f_flag;
		writel_relaxed(mlb_exsint->int_f_flag, mlb_exsint->iostat);
	}

	tasklet_schedule(&mlb_exsint->tasklet);

	return IRQ_HANDLED;
}

static const struct of_device_id milbeaut_exsint_id[] = {
	{
		.compatible = "socionext,exsint-m10v",
		.data = (void *)MLB_EXSINT_VAR_M10V
	},
	{
		.compatible = "socionext,exsint-m20v",
		.data = (void *)MLB_EXSINT_VAR_M20V
	},
	{},
};
MODULE_DEVICE_TABLE(of, milbeaut_exsint_id);

static int milbeaut_exsint_probe(struct platform_device *pdev)
{
	const struct of_device_id *of_id =
		of_match_device(milbeaut_exsint_id, &pdev->dev);
	struct mlb_exsint_device *mlb_exsint;
	struct device *dev = &pdev->dev;
	struct resource *res;
	int ret, irq;
	u32 reg;

	DBG("probe start\n");

	mlb_exsint = devm_kzalloc(dev, sizeof(struct mlb_exsint_device),
				  GFP_KERNEL);
	if (!mlb_exsint)
		return -ENOMEM;

	mlb_exsint->variant = (uintptr_t)of_id->data;
	tasklet_init(&mlb_exsint->tasklet, sn_exs_notify_tasklet,
		     (unsigned long)mlb_exsint);

	res = platform_get_resource(pdev, IORESOURCE_MEM, 0);
	mlb_exsint->iostat = devm_ioremap_resource(dev, res);
	if (IS_ERR(mlb_exsint->iostat)) {
		ret = PTR_ERR(mlb_exsint->iostat);
		return ret;
	}

	res = platform_get_resource(pdev, IORESOURCE_MEM, 1);
	mlb_exsint->iomsk = devm_ioremap_resource(dev, res);
	if (IS_ERR(mlb_exsint->iomsk)) {
		ret = PTR_ERR(mlb_exsint->iomsk);
		return ret;
	}

	irq = platform_get_irq(pdev, 0); /* EXSTOP IRQ */
	if (irq < 0) {
		dev_err(dev, "unable to get exstop irq\n");
		return irq;
	}
	ret = devm_request_irq(dev, irq, sn_exs_irq, 0, dev_name(dev), mlb_exsint);
	if (ret < 0) {
		dev_err(dev, "unable to request exsint irq %d", irq);
		return ret;
	}

	spin_lock_init(&mlb_exsint->lock);
	memcpy(&mlb_exsint->devname, DEVICE_NAME, sizeof(DEVICE_NAME));
	mlb_exsint->miscdev.name = mlb_exsint->devname;
	mlb_exsint->miscdev.minor = MISC_DYNAMIC_MINOR;
	mlb_exsint->dev = dev;

	platform_set_drvdata(pdev, mlb_exsint);

	/* initialization */
	if(mlb_exsint->variant == MLB_EXSINT_VAR_M20V) {
		mlb_exsint->int_r_flag = M20V_INTSTAT_USB3_VBUS_RISE;
		mlb_exsint->int_f_flag = M20V_INTSTAT_USB3_VBUS_FALL;
		writel_relaxed(M20V_INTSTAT_USB3_VBUS_RISE | M20V_INTSTAT_USB3_VBUS_FALL,
				mlb_exsint->iostat);
		reg = readl_relaxed(mlb_exsint->iomsk + M20V_DEBCNTL);
		reg &= ~(M20V_INTMSK_USB3_VBUS_RISE | M20V_INTMSK_USB3_VBUS_FALL);
		writel_relaxed(reg, mlb_exsint->iomsk + M20V_DEBCNTL);
		writel_relaxed(DEBRSTX_RSTX, mlb_exsint->iomsk + M20V_DEBRSTX);
	} else {
		mlb_exsint->int_r_flag = M10V_INTSTAT_USB3_VBUS_RISE;
		mlb_exsint->int_f_flag = M10V_INTSTAT_USB3_VBUS_FALL;
		writel_relaxed(M10V_INTSTAT_USB3_VBUS_RISE | M10V_INTSTAT_USB3_VBUS_FALL,
				mlb_exsint->iostat);
		writel_relaxed(~(M10V_INTMSK_USB3_VBUS_RISE | M10V_INTMSK_USB3_VBUS_FALL),
				mlb_exsint->iomsk);
	}

	return misc_register(&mlb_exsint->miscdev);
}

static int milbeaut_exsint_remove(struct platform_device *pdev)
{
	struct mlb_exsint_device *mlb_exsint = platform_get_drvdata(pdev);

	devm_iounmap(&pdev->dev, mlb_exsint->iostat);
	devm_iounmap(&pdev->dev, mlb_exsint->iomsk);

	misc_deregister(&mlb_exsint->miscdev);
	return 0;
}

static struct platform_driver milbeaut_exsint_driver = {
	.probe = milbeaut_exsint_probe,
	.remove = milbeaut_exsint_remove,
	.driver = {
		.name = "milbeaut-exsint",
		.of_match_table = milbeaut_exsint_id,
	},
};
module_platform_driver(milbeaut_exsint_driver);

MODULE_DESCRIPTION("MILBEAUT exsint controller driver");
MODULE_AUTHOR("Takao Orito <<REDACTED_EMAIL>>");
MODULE_LICENSE("GPL v2");
