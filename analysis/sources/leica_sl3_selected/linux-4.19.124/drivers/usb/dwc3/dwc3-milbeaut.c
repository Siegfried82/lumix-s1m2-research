/**
 * dwc3-milbeaut.c : Support for dwc3 on Socionext Milbeaut platform
 *
 * Copyright (C) 2019 Socionext Inc.
 *
 * Author: Takao Orito <<REDACTED_EMAIL>>
 *
 * Copyright (c) 2020 Panasonic Corporation
 * 2020-07-16 Modified
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 */

#include <linux/bits.h>
#include <linux/clk.h>
#include <linux/io.h>
#include <linux/module.h>
#include <linux/of.h>
#include <linux/of_platform.h>
#include <linux/platform_device.h>
#include <linux/reset.h>
#include <linux/usb/of.h>
#include <linux/usb/otg.h>

/* usb30 glue registers for M10V */
#define USB3_CKCTL		0x0
#define USB3_RCTL		0x4
#define USB3_RCV_SNS	0x8
#define USB3_FSEL		0xC
#define USB3_RFC_CTL	0x10
#define USB3_HO_IF		0x14
#define USB3_JT_ADJ		0x18
#define  USB3_JT_ADJ_OVRCUR_EN  BIT(16)
#define USB3_IDVBUSCTL	0x20

/* usb31 sub system registers for M20V */
#define USB_CTRL_CFG0	0x10
#define  USB_CTRL_BUSFILTER_BYPASS_SFT	14
#define  USB_CTRL_BUSFILTER_BYPASS_MASK	(0xF << USB_CTRL_BUSFILTER_BYPASS_SFT)
#define USB_PHY_CFG0	0x18
#define  USB_PHY_CFG0_CTRL_SEL	BIT(10)
#define  USB_PHY_MPLLA_SSC_FORCE_EN	BIT(6)
#define  USB_PHY_MPLLA_SSC_EN	BIT(5)
#define  USB_PHY_MPLLB_SSC_FORCE_EN	BIT(4)
#define  USB_PHY_MPLLB_SSC_EN	BIT(3)
#define  USB_PHY_CR_PARA_SEL	BIT(1)
#define  USB_PHY_CR_PARA_CLK_EN	BIT(0)
#define USB_MPLLA_CFG0	0x20
#define  USB_MPLLA_CFG0_MPLLA_BD_SFT	15
#define  USB_MPLLA_CFG0_MPLLA_BD_MSK	(0xFFFF << USB_MPLLA_CFG0_MPLLA_BD_SFT)
#define USB_MPLLA_CFG1	0x28
#define  USB_MPLLA_CFG1_MULTIPLIER_SFT	9
#define  USB_MPLLA_CFG1_MULTIPLIER_MSK	(0xFF << USB_MPLLA_CFG1_MULTIPLIER_SFT)
#define USB_PHY_CFG1	0x38
#define  USB_PHY_CFG1_REF_CLK_MPLLA_DIV2_EN	BIT(27)
#define  USB_PHY_CFG1_RX_VREF_CTRL_SFT	18
#define  USB_PHY_CFG1_RX_VREF_CTRL_MSK	(0x1F << USB_PHY_CFG1_RX_VREF_CTRL_SFT)

/**
 * struct sn_dwc3 - dwc3-sn driver private structure
 * @dev:		device pointer
 */
struct sn_dwc3 {
	struct device *dev;
	void __iomem *subsys_base;		/* only for USB31 */
	struct sn_dwc3_config *config;
	enum usb_dr_mode dr_mode;
	struct reset_control *rst;
	struct reset_control *hif_io_en;
	struct clk *apb_busclk;
};

struct sn_dwc3_config {
	void (*init)(struct sn_dwc3 *dwc3_data);
};

static inline u32 dwc3_readl(void __iomem *base, u32 offset)
{
	return readl_relaxed(base + offset);
}

static inline void dwc3_writel(void __iomem *base, u32 offset, u32 value)
{
	writel_relaxed(value, base + offset);
}

void dwc30_subsys_init(struct sn_dwc3 *dwc3_data)
{
	/* over current disable. device mode only */
	if (dwc3_data->dr_mode == USB_DR_MODE_PERIPHERAL) {
		reset_control_assert(dwc3_data->hif_io_en);
	}
}

static int multiplier = 52;    /* MULTIPLIER at MPLLA_CFG1 */
static int bandwidth = 31;    /* BANDWIDTH at MPLLA_CFG0 */

void dwc31_subsys_init(struct sn_dwc3 *dwc3_data)
{
	u32 val;

	/* phy_ext_mplla_bandwidth = 31 */
	val = dwc3_readl(dwc3_data->subsys_base, USB_MPLLA_CFG0);
	val &= ~USB_MPLLA_CFG0_MPLLA_BD_MSK;
	val |= bandwidth << USB_MPLLA_CFG0_MPLLA_BD_SFT;
	dwc3_writel(dwc3_data->subsys_base, USB_MPLLA_CFG0, val);

	/* ext_mplla_multiplier = 52 */
	val = dwc3_readl(dwc3_data->subsys_base, USB_MPLLA_CFG1);
	val &= ~USB_MPLLA_CFG1_MULTIPLIER_MSK;
	val |= (multiplier << USB_MPLLA_CFG1_MULTIPLIER_SFT);
	dwc3_writel(dwc3_data->subsys_base, USB_MPLLA_CFG1, val);

	/* phy_ext_mplla_word_div2_en = 0 */
	val = dwc3_readl(dwc3_data->subsys_base, USB_PHY_CFG1);
	val &= ~(USB_PHY_CFG1_RX_VREF_CTRL_MSK | USB_PHY_CFG1_REF_CLK_MPLLA_DIV2_EN);
	val |= 17 << USB_PHY_CFG1_RX_VREF_CTRL_SFT;
	dwc3_writel(dwc3_data->subsys_base, USB_PHY_CFG1, val);

	/* phy_ext_ctrl_sel = 1 */
	val = dwc3_readl(dwc3_data->subsys_base, USB_PHY_CFG0);
	val |= USB_PHY_CFG0_CTRL_SEL;
	dwc3_writel(dwc3_data->subsys_base, USB_PHY_CFG0, val);

	if (dwc3_data->dr_mode == USB_DR_MODE_PERIPHERAL) {
		/* reset release */
		reset_control_assert(dwc3_data->hif_io_en);
		val = dwc3_readl(dwc3_data->subsys_base, USB_CTRL_CFG0);
		val &= ~USB_CTRL_BUSFILTER_BYPASS_MASK;
		dwc3_writel(dwc3_data->subsys_base, USB_CTRL_CFG0, val);
	} else {
		/* host */
		reset_control_deassert(dwc3_data->hif_io_en);
		val = dwc3_readl(dwc3_data->subsys_base, USB_CTRL_CFG0);
		val |= USB_CTRL_BUSFILTER_BYPASS_MASK;
		dwc3_writel(dwc3_data->subsys_base, USB_CTRL_CFG0, val);
	}
}

struct sn_dwc3_config m10v_config = {
	.init = dwc30_subsys_init,
};

struct sn_dwc3_config m20v_config = {
	.init = dwc31_subsys_init,
};

extern enum usb_dr_mode sn_dr_mode;

/* this is only for debug, 0=device, 1=host, other=decided by devicetree */
static int hostmode = 2;

static int dwc3_milbeaut_probe(struct platform_device *pdev)
{
	struct sn_dwc3 *dwc3_data;
	struct resource *res;
	struct device *dev = &pdev->dev;
	struct device_node *node = dev->of_node, *child;
	struct platform_device *child_pdev;
	int ret;
	const char *dr_mode_tmp;

	if (hostmode == 1)
		sn_dr_mode = USB_DR_MODE_HOST;
	else if (hostmode == 0)
		sn_dr_mode = USB_DR_MODE_PERIPHERAL;
	else
		sn_dr_mode = USB_DR_MODE_UNKNOWN;

	dwc3_data = devm_kzalloc(dev, sizeof(*dwc3_data), GFP_KERNEL);
	if (!dwc3_data)
		return -ENOMEM;

	dwc3_data->dev = dev;
	dwc3_data->config =
		(struct sn_dwc3_config *)of_device_get_match_data(dev);
	if (!dwc3_data->config)
		dwc3_data->config = &m20v_config;

	/* SNI glue (reset & config) */
	dwc3_data->rst = devm_reset_control_get(&pdev->dev, "reset");
	if (IS_ERR(dwc3_data->rst)) {
		ret = PTR_ERR(dwc3_data->rst);
		if (ret == -EPROBE_DEFER)
			return ret;
		dwc3_data->rst = NULL;
	}

	dwc3_data->hif_io_en = devm_reset_control_get(&pdev->dev, "hif");
	if (IS_ERR(dwc3_data->hif_io_en)) {
		ret = PTR_ERR(dwc3_data->hif_io_en);
		if (ret == -EPROBE_DEFER)
			return ret;
		dwc3_data->hif_io_en = NULL;
	}

	/* SNI glue (Subsystem) */
	if (dwc3_data->config == &m20v_config) {
		res = platform_get_resource_byname(pdev,
				IORESOURCE_MEM, "reg-subsys");
		dwc3_data->subsys_base = devm_ioremap_resource(dev, res);
		if (IS_ERR(dwc3_data->subsys_base))
			return PTR_ERR(dwc3_data->subsys_base);
		pr_err("=== dwc3_milbeaut_probe: subsys_base = 0x%llx(virt base=0x%lx\n", res->start, (unsigned long)dwc3_data->subsys_base);

		/* m20v: used	*/
		/* EVB : To be initialized on the RTOS side, it isn't used  */
#if 0	/* No used	*/
		dwc3_data->apb_busclk = devm_clk_get(&pdev->dev, "apb_bus");
		if (IS_ERR(dwc3_data->apb_busclk)) {
			ret = PTR_ERR(dwc3_data->apb_busclk);
			goto undo_softreset;
		}

		ret = clk_prepare_enable(dwc3_data->apb_busclk);
		if (ret)
			goto undo_softreset;
#endif
	}

#ifdef CONFIG_PM
	/* for CONFIG PM */
	pm_runtime_enable(&pdev->dev);
	pm_runtime_get_sync(&pdev->dev);
#endif
	/* At the time of USB host movement	*/
	/* USB H/W initializing process is performed by Linux, not RTOS */
	if (hostmode == 1) {
		dwc3_data->apb_busclk = devm_clk_get(&pdev->dev, "apb_bus");
		if (IS_ERR(dwc3_data->apb_busclk)) {
			ret = PTR_ERR(dwc3_data->apb_busclk);
			goto undo_softreset;
		}

		ret = clk_prepare_enable(dwc3_data->apb_busclk);
		if (ret)
			goto undo_softreset;

#ifdef CONFIG_USB_DWC3_MILBEAUT_USED_LINUX_PWM
        }else{
                dwc3_data->apb_busclk = devm_clk_get(&pdev->dev, "apb_bus");
	        if (IS_ERR(dwc3_data->apb_busclk)) {
		        ret = PTR_ERR(dwc3_data->apb_busclk);
		        goto undo_softreset;
	        }

	        ret = clk_prepare_enable(dwc3_data->apb_busclk);
	        if (ret)
		        goto undo_softreset;
        }
#else
        }
#endif
        /* for dwc3 core */
        child = of_get_child_by_name(node, "dwc3");
	if (!child) {
		dev_err(&pdev->dev, "failed to find dwc3 core node\n");
		ret = -ENODEV;
		goto undo_softreset;
	}

	ret = of_property_read_string(child, "dr_mode", &dr_mode_tmp);
	if (ret < 0) {
		dev_err(&pdev->dev, "No dr_mode property on dwc3 core node\n");
		goto undo_softreset;
	}
	if (hostmode == 1)
		dwc3_data->dr_mode = USB_DR_MODE_HOST;
	else if (hostmode == 0)
		dwc3_data->dr_mode = USB_DR_MODE_PERIPHERAL;
	else if (!strcmp(dr_mode_tmp, "peripheral"))
		dwc3_data->dr_mode = USB_DR_MODE_PERIPHERAL;
	else if (!strcmp(dr_mode_tmp, "host"))
		dwc3_data->dr_mode = USB_DR_MODE_HOST;

	// for debug print
	if (dwc3_data->dr_mode == USB_DR_MODE_HOST)
		dev_info(dev, "dwc3: dr_mode is Host\n");
	else if (dwc3_data->dr_mode == USB_DR_MODE_PERIPHERAL)
		dev_info(dev, "dwc3: dr_mode is Peripheral\n");
	else
		dev_info(dev, "dwc3: dr_mode is Unknown or OTG\n");

	dwc3_data->config->init(dwc3_data);

	if (hostmode == 1) {
	  /* Socionext glue logic init */
	  reset_control_deassert(dwc3_data->rst);
#ifdef CONFIG_USB_DWC3_MILBEAUT_USED_LINUX_PWM
        }else{
	  /* Socionext glue logic init */
	  reset_control_deassert(dwc3_data->rst);
#else
        }
#endif

	/* Allocate and initialize the core */
	ret = of_platform_populate(node, NULL, NULL, dev);
	if (ret) {
		dev_err(dev, "failed to add dwc3 core\n");
		goto undo_softreset;
	}

	child_pdev = of_find_device_by_node(child);
	if (!child_pdev) {
		dev_err(dev, "failed to find dwc3 core device\n");
		ret = -ENODEV;
		goto undo_softreset;
	}

	platform_set_drvdata(pdev, dwc3_data);

undo_softreset:
#ifdef CONFIG_PM
	/* for CONFIG PM */
	pm_runtime_put_sync(&pdev->dev);
#endif

pr_err("<<< %s:%d: end\n", __func__, __LINE__);
	return ret;
}


static int dwc3_milbeaut_remove(struct platform_device *pdev)
{
	struct device *dev = &pdev->dev;
	struct sn_dwc3 *dwc3_data = dev_get_drvdata(dev);

	of_platform_depopulate(&pdev->dev);

#ifdef CONFIG_PM
	/* for CONFIG PM */
	pm_runtime_put_sync(&pdev->dev);
	pm_runtime_disable(&pdev->dev);
#endif
	if (dwc3_data->config == &m20v_config)
		clk_disable_unprepare(dwc3_data->apb_busclk);
	return 0;
}

#ifdef CONFIG_PM
static int dwc3_milbeaut_suspend(struct device *dev)
{
	struct sn_dwc3 *dwc3_data = dev_get_drvdata(dev);

	pm_runtime_put_sync(dev);

	reset_control_assert(dwc3_data->rst);

	return 0;
}

static int dwc3_milbeaut_resume(struct device *dev)
{
	struct sn_dwc3 *dwc3_data = dev_get_drvdata(dev);

	pm_runtime_get_sync(dev);

	/* Socionext glue logic init */
	reset_control_deassert(dwc3_data->rst);
	dwc3_data->config->init(dwc3_data);

	return 0;
}

static SIMPLE_DEV_PM_OPS(sn_dwc3_dev_pm_ops,
				dwc3_milbeaut_suspend, dwc3_milbeaut_resume);
#define DEV_PM_OPS	(&sn_dwc3_dev_pm_ops)

#else
#define DEV_PM_OPS	NULL
#endif /* CONFIG_PM */

static const struct of_device_id dwc3_milbeaut_match[] = {
	{
		.compatible = "socionext,f_usb30dr_fp_m10v",
		.data = &m10v_config,
	},
	{
		.compatible = "socionext,f_usb31drd_m20v",
		.data = &m20v_config,
	},
	{ /* sentinel */ },
};

MODULE_DEVICE_TABLE(of, dwc3_milbeaut_match);

static struct platform_driver dwc3_milbeaut_driver = {
	.probe = dwc3_milbeaut_probe,
	.remove = dwc3_milbeaut_remove,
	.driver = {
		.name = "dwc3-milbeaut",
		.of_match_table = dwc3_milbeaut_match,
		.pm = DEV_PM_OPS,
	},
};

module_platform_driver(dwc3_milbeaut_driver);

module_param(hostmode, int, S_IRUGO | S_IWUSR);
MODULE_PARM_DESC(hostmode, "Override for host mode");

module_param(multiplier, int, S_IRUGO | S_IWUSR);
MODULE_PARM_DESC(multiplier, "Override multiplier for MPLLA");

module_param(bandwidth, int, S_IRUGO | S_IWUSR);
MODULE_PARM_DESC(bandwidth, "Override bandwidth for MPLLA");

MODULE_AUTHOR("Takao Orito <<REDACTED_EMAIL>>");
MODULE_DESCRIPTION("DesignWare USB3 SNI Glue Layer");
MODULE_LICENSE("GPL v2");
