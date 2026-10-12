// SPDX-License-Identifier: GPL-2.0
/*
 * Copyright (C) 2019 Socionext Inc.
 *
 * Copyright (c) 2021 Panasonic Corporation
 *   2021-09-28 Modified
 */

#include <linux/bits.h>
#include <linux/delay.h>
#include <linux/err.h>
#include <linux/io.h>
#include <linux/module.h>
#include <linux/of.h>
#include <linux/platform_device.h>
#include <linux/reboot.h>
#include <linux/reset-controller.h>
#include <linux/spinlock.h>
#include <dt-bindings/reset/milbeaut,m20v-reset.h>

/* CHIPTOP */
#define RESSIGT0_BASE	0x0d1501ac
#define RESSIGT0	0x0
#define  EMMEINTS	BIT(15)

#define   EMMCCLK_V     0
#if (EMMCCLK_V == 0)
#define MLB_F_EMMC50_CLK 200
#elif (EMMCCLK_V == 1)
#define MLB_F_EMMC50_CLK 178
#elif (EMMCCLK_V == 2)
#define MLB_F_EMMC50_CLK 145
#else
#define MLB_F_EMMC50_CLK 100
#endif


/* offset from H'0_1BA0_0200(EM_SRSTX) */
#define EM_SRSTX	0x0
#define  EMCRSTX         BIT(0)
#define  EMCRSTX_ON      0
#define  EMCRSTX_OFF     1
#define EM_PV_DTIMEC   0x0024
#define  PV_DTIMEC       0x00FFFFFF
#define  PV_DTIMEC_V     0
#define EM_PV_AMPBL    0x0028
#define  PV_AMPBL        0xF
#define  PV_AMPBL_V      0xF
#define EM_CR_SLOTTYPE 0x002C
#define  CR_SLOTTYPE     BIT(0)
#define  CR_SLOTTYPE_V   1
#define EM_CR_BCLKFREQ 0x0030
#define  CR_BCLKFREQ     0xFF
#define EM_CDDET       0x0034
#define  EMPHYLK         BIT(8)
#define  EMCD            BIT(0)
#define  EMCD_V          0

#define NF_RSTX		0x100
#define  NF_RSTREG	BIT(2)
#define  NF_RSTBCH	BIT(1)
#define  NF_RSTN	BIT(0)
#define  NF_RSTALL	(NF_RSTREG | NF_RSTBCH | NF_RSTN)
#define NF_NFWPX_CNT	0x12c

#define EXS_NS_RSTX		0x0200
#define EXS_UL_RSTX		0x0400
#define  UL_RSTX_SSPHY	BIT(2)
#define  UL_RSTX_FMPHY	BIT(1)
#define  UL_RSTX_RSTX	BIT(0)
#define  UL_RSTX_ALL	(UL_RSTX_SSPHY | UL_RSTX_FMPHY | UL_RSTX_RSTX)
#define EXS_UL_ULIOCNT		0x404
#define  UL_ULIOCNT_VBDSEL	BIT(25)
#define  UL_ULIOCNT_VBDVAL	BIT(24)
#define  UL_ULIOCNT_VBSEL	BIT(1)
#define  UL_ULIOCNT_VBVAL	BIT(0)
#define  UL_ULIOCNT_OC_SEL	BIT(17)

#define EXS_P0X_RSTX		0x0500
#define EXS_P0X_IOCNT		0x0504
#define EXS_P0X_CNT0		0x0508

#define APB_SS_RST_CTRL_1	0x004C

#define PCIE_DEV_TYPE_RC	0x4
#define PCIE_DEV_TYPE_EP	0x0

static DEFINE_SPINLOCK(mlb_crglock);

struct mlb_reset_data {
	struct reset_controller_dev rcdev;
	void __iomem *exs_base;
	void __iomem *pcie_apb_base;
};

#define to_data(p) container_of(p, struct mlb_reset_data, rcdev)

static int mlb_reset_restart(struct notifier_block *this, unsigned long mode,
			       void *cmd)
{
	pr_emerg("%s: unable to restart system\n", __func__);
	return NOTIFY_DONE;
}

static struct notifier_block mlb_reset_restart_nb = {
	.notifier_call = mlb_reset_restart,
	.priority = 192,
};

static int mlb_pcie_pwr_en(struct reset_controller_dev *rcdev,
			     unsigned long asserted)
{
	struct mlb_reset_data *rc = to_data(rcdev);

	writel_relaxed(!asserted, rc->exs_base + EXS_P0X_RSTX);
	return 0;
}

static int mlb_pcie_soft0pwr_en(struct reset_controller_dev *rcdev,
			     unsigned long asserted)
{
	struct mlb_reset_data *rc = to_data(rcdev);
	unsigned int val;
	unsigned long flag = 0;

	spin_lock_irqsave(&mlb_crglock, flag);
	val = readl_relaxed(rc->exs_base + EXS_P0X_IOCNT);
	val &= ~0xFF;
	if (!asserted) {
		val |= 0x31;
	}
	writel_relaxed(val, rc->exs_base + EXS_P0X_IOCNT);
	spin_unlock_irqrestore(&mlb_crglock, flag);

	spin_lock_irqsave(&mlb_crglock, flag);
	val = readl_relaxed(rc->pcie_apb_base + APB_SS_RST_CTRL_1);
	val &= 0x700;
	val |= asserted;
	writel_relaxed(val, rc->pcie_apb_base + APB_SS_RST_CTRL_1);
	spin_unlock_irqrestore(&mlb_crglock, flag);

	return 0;
}

static int mlb_pcie_soft1pwr_en(struct reset_controller_dev *rcdev,
			     unsigned long asserted)
{
	struct mlb_reset_data *rc = to_data(rcdev);
	unsigned int val;
	unsigned long flag = 0;

	spin_lock_irqsave(&mlb_crglock, flag);
	val = readl_relaxed(rc->exs_base + EXS_P0X_IOCNT);
	val &= ~0xFF00;
	if (!asserted) {
		val |= 0x3100;
	}
	writel_relaxed(val, rc->exs_base + EXS_P0X_IOCNT);
	spin_unlock_irqrestore(&mlb_crglock, flag);

	spin_lock_irqsave(&mlb_crglock, flag);
	val = readl_relaxed(rc->pcie_apb_base + APB_SS_RST_CTRL_1);
	val &= 0x7;
	val |= (asserted << 8);
	writel_relaxed(val, rc->pcie_apb_base + APB_SS_RST_CTRL_1);
	spin_unlock_irqrestore(&mlb_crglock, flag);

	return 0;
}

static int mlb_pcie_bifurcation_en(struct reset_controller_dev *rcdev,
			     unsigned long asserted)
{
	struct mlb_reset_data *rc = to_data(rcdev);
//	unsigned int bifur, pwr;
	unsigned int bifur;
	int ret;
	unsigned long flag = 0;

	spin_lock_irqsave(&mlb_crglock, flag);

	bifur = readl_relaxed(rc->exs_base + EXS_P0X_CNT0);
	if (!!(bifur & BIT(16)) == !!asserted) {
		ret = 0; // need not change
		goto jump_to;
	}

#if 0
	pwr = readl_relaxed(rc->pcie_apb_base + APB_SS_RST_CTRL_1);
	if (pwr) {
		pr_err("%s: failed to change bifurcation\n", __func__);
		ret = -EINVAL;
		goto jump_to;
	}
#endif

	bifur &= 0xFFFF;
	bifur |= (asserted << 16);
	writel_relaxed(bifur, rc->exs_base + EXS_P0X_CNT0);
	ret = 0;

jump_to:
	spin_unlock_irqrestore(&mlb_crglock, flag);

	return ret;
}

static int mlb_pcie_controller0_rc(struct reset_controller_dev *rcdev,
				   unsigned long rc_en)
{
	struct mlb_reset_data *rc = to_data(rcdev);
	unsigned int val, device_type;
	unsigned long flag = 0;

	if (rc_en)
		device_type = PCIE_DEV_TYPE_RC;
	else
		device_type = PCIE_DEV_TYPE_EP;

	spin_lock_irqsave(&mlb_crglock, flag);
	val = readl_relaxed(rc->exs_base + EXS_P0X_CNT0);
	val &= ~0x0F;
	val |= device_type;
	writel_relaxed(val, rc->exs_base + EXS_P0X_CNT0);
	spin_unlock_irqrestore(&mlb_crglock, flag);

	return 0;
}

static int mlb_pcie_controller1_rc(struct reset_controller_dev *rcdev,
				   unsigned long rc_en)
{
	struct mlb_reset_data *rc = to_data(rcdev);
	unsigned int val, device_type = PCIE_DEV_TYPE_RC; // cnt1 is always rc
	unsigned long flag = 0;

	spin_lock_irqsave(&mlb_crglock, flag);
	val = readl_relaxed(rc->exs_base + EXS_P0X_CNT0);
	val &= ~0xF00;
	val |= (device_type << 8);
	writel_relaxed(val, rc->exs_base + EXS_P0X_CNT0);
	spin_unlock_irqrestore(&mlb_crglock, flag);

	return 0;
}

static int mlb_netsec_soft_reset(struct reset_controller_dev *rcdev,
					 unsigned long asserted)
{
	struct mlb_reset_data *rc = to_data(rcdev);
	unsigned long flag = 0;

	spin_lock_irqsave(&mlb_crglock, flag);
	writel_relaxed(!asserted, rc->exs_base + EXS_NS_RSTX);
	spin_unlock_irqrestore(&mlb_crglock, flag);

	return 0;
}

static int mlb_usb_soft_reset(struct reset_controller_dev *rcdev,
					 unsigned long asserted)
{
	struct mlb_reset_data *rc = to_data(rcdev);
	unsigned long flag = 0;

	spin_lock_irqsave(&mlb_crglock, flag);
	writel_relaxed(asserted ? 0 : UL_RSTX_ALL, rc->exs_base + EXS_UL_RSTX);
	spin_unlock_irqrestore(&mlb_crglock, flag);

	return 0;
}

#if 0
static int mlb_usb_hif_reset(struct reset_controller_dev *rcdev,
					 unsigned long asserted)
{
	struct mlb_reset_data *rc = to_data(rcdev);
	unsigned long flag = 0;

	spin_lock_irqsave(&mlb_crglock, flag);
	writel_relaxed(asserted ? 0 :	/* peripheral */
		UL_ULIOCNT_VBDSEL | UL_ULIOCNT_VBDVAL |	/* host */
		UL_ULIOCNT_VBSEL | UL_ULIOCNT_VBVAL,
		rc->exs_base + EXS_UL_ULIOCNT);
	spin_unlock_irqrestore(&mlb_crglock, flag);

	return 0;
}
#else
static int mlb_usb_hif_reset(struct reset_controller_dev *rcdev,
					 unsigned long asserted)
{
	struct mlb_reset_data *rc = to_data(rcdev);
	unsigned long flag = 0;
	unsigned int val;

	// EXS_UL_ULIOCNT_OC_SELは					//
	// RTOS側で設定した値を保持するようにする   //
	spin_lock_irqsave(&mlb_crglock, flag);
	val = readl_relaxed(rc->exs_base + EXS_UL_ULIOCNT);
	val = (val & UL_ULIOCNT_OC_SEL);

	writel_relaxed(asserted ? val :	/* peripheral */
		UL_ULIOCNT_VBDSEL | UL_ULIOCNT_VBDVAL |	/* host */
		UL_ULIOCNT_VBSEL | UL_ULIOCNT_VBVAL | UL_ULIOCNT_OC_SEL,
		rc->exs_base + EXS_UL_ULIOCNT);
	spin_unlock_irqrestore(&mlb_crglock, flag);

	return 0;
}
#endif

static int mlb_nand_reset(struct reset_controller_dev *rcdev,
					 unsigned long asserted)
{
	struct mlb_reset_data *rc = to_data(rcdev);
	unsigned long flag = 0;

	spin_lock_irqsave(&mlb_crglock, flag);
	writel_relaxed(asserted ? 0 : NF_RSTALL, rc->exs_base + NF_RSTX);
	spin_unlock_irqrestore(&mlb_crglock, flag);

	spin_lock_irqsave(&mlb_crglock, flag);
	writel_relaxed(!asserted, rc->exs_base + NF_NFWPX_CNT);
	spin_unlock_irqrestore(&mlb_crglock, flag);

	return 0;
}

static void f_emmc_dset(void __iomem *base, u32 offset, u32 mask, u32 in)
{
	u32 data;
	u32 shift = 1;

	if (in) {
		while (!(mask & shift))
			shift <<= 1;
		data = (readl(base + offset) & ~mask) | (in * shift);
	}
	else
		data = readl(base + offset) & ~mask;

	writel(data, base + offset);
}

static int mlb_f_emmc50_reset(struct reset_controller_dev *rcdev,
							  unsigned long asserted)
{
	struct mlb_reset_data *rc = to_data(rcdev);
	int ret = 0;
	void __iomem *io_base;
	void __iomem *exs_base;

	io_base = ioremap(RESSIGT0_BASE, 0x10);	/* RESSIGT0 bit 15 should be 0*/
	exs_base = rc->exs_base;

	f_emmc_dset(io_base, RESSIGT0, EMMEINTS, 0);

	f_emmc_dset(exs_base, EM_SRSTX, EMCRSTX, EMCRSTX_ON);
	f_emmc_dset(exs_base, EM_CR_SLOTTYPE, CR_SLOTTYPE, CR_SLOTTYPE_V);
	f_emmc_dset(exs_base, EM_CR_BCLKFREQ, CR_BCLKFREQ,
				MLB_F_EMMC50_CLK);
	f_emmc_dset(exs_base, EM_PV_DTIMEC, PV_DTIMEC, PV_DTIMEC_V);
	f_emmc_dset(exs_base, EM_PV_AMPBL, PV_AMPBL, PV_AMPBL_V);
	f_emmc_dset(exs_base, EM_CDDET, EMCD, EMCD_V);
	udelay(1);
	f_emmc_dset(exs_base, EM_SRSTX, EMCRSTX, EMCRSTX_OFF);

	iounmap(io_base);

	return ret;
}

static int mlb_assert(struct reset_controller_dev *rcdev,
			     unsigned long id)
{
	switch (id) {
	case M20V_PCIE_RESET_PWR:
		return mlb_pcie_pwr_en(rcdev, 1);
	case M20V_PCIE_RESET_SOFT0:
		return mlb_pcie_soft0pwr_en(rcdev, 1);
	case M20V_PCIE_RESET_SOFT1:
		return mlb_pcie_soft1pwr_en(rcdev, 1);
	case M20V_PCIE_RESET_BIFU0:
	case M20V_PCIE_RESET_BIFU1:
		return mlb_pcie_bifurcation_en(rcdev, 1);
	case M20V_PCIE_RESET_CNT0_MODE:
		return mlb_pcie_controller0_rc(rcdev, 1);
	case M20V_PCIE_RESET_CNT1_MODE:
		return mlb_pcie_controller1_rc(rcdev, 1);
	case M20V_NETSEC_RESET:
		return mlb_netsec_soft_reset(rcdev, 1);
	case M20V_USB_RESET:
		return mlb_usb_soft_reset(rcdev, 1);
	case M20V_USB_HIF:
		return mlb_usb_hif_reset(rcdev, 1);
	case M20V_NAND_RESET:
		return mlb_nand_reset(rcdev, 1);
	case M20V_EMMC_RESET:
		return mlb_f_emmc50_reset(rcdev, 1);
	default:
		pr_err("%s: RESET(%lu) not implemented yet\n", __func__, id);
		return -EINVAL;
	}

}

static int mlb_deassert(struct reset_controller_dev *rcdev,
			     unsigned long id)
{
	switch (id) {
	case M20V_PCIE_RESET_PWR:
		return mlb_pcie_pwr_en(rcdev, 0);
	case M20V_PCIE_RESET_SOFT0:
		return mlb_pcie_soft0pwr_en(rcdev, 0);
	case M20V_PCIE_RESET_SOFT1:
		return mlb_pcie_soft1pwr_en(rcdev, 0);
	case M20V_PCIE_RESET_BIFU0:
	case M20V_PCIE_RESET_BIFU1:
		return mlb_pcie_bifurcation_en(rcdev, 0);
	case M20V_PCIE_RESET_CNT0_MODE:
		return mlb_pcie_controller0_rc(rcdev, 0);
	case M20V_PCIE_RESET_CNT1_MODE:
		return mlb_pcie_controller1_rc(rcdev, 0);
	case M20V_NETSEC_RESET:
		return mlb_netsec_soft_reset(rcdev, 0);
	case M20V_USB_RESET:
		return mlb_usb_soft_reset(rcdev, 0);
	case M20V_USB_HIF:
		return mlb_usb_hif_reset(rcdev, 0);
	case M20V_NAND_RESET:
		return mlb_nand_reset(rcdev, 0);
	case M20V_EMMC_RESET:
		return mlb_f_emmc50_reset(rcdev, 0);
	default:
		pr_err("%s: RESET(%lu) not implemented yet\n", __func__, id);
		return -EINVAL;
	}

}

static struct reset_control_ops mlb_reset_ops = {
	.assert = mlb_assert,
	.deassert = mlb_deassert,
};

static int mlb_reset_probe(struct platform_device *pdev)
{
	struct mlb_reset_data *rc;
	struct resource *res;
	int ret;

	rc = devm_kzalloc(&pdev->dev, sizeof(*rc), GFP_KERNEL);
	if (!rc)
		return -ENOMEM;

	res = platform_get_resource_byname(pdev, IORESOURCE_MEM, "exstop");
	rc->exs_base = devm_ioremap_resource(&pdev->dev, res);
	if (IS_ERR(rc->exs_base))
		return PTR_ERR(rc->exs_base);

	res = platform_get_resource_byname(pdev, IORESOURCE_MEM, "pcie_apb");
	rc->pcie_apb_base = devm_ioremap_resource(&pdev->dev, res);
	if (IS_ERR(rc->pcie_apb_base))
		return PTR_ERR(rc->pcie_apb_base);

	rc->rcdev.owner = THIS_MODULE;
	rc->rcdev.nr_resets = M20V_RESET_MAX;
	rc->rcdev.ops = &mlb_reset_ops;
	rc->rcdev.of_node = pdev->dev.of_node;

	platform_set_drvdata(pdev, rc);

	ret = reset_controller_register(&rc->rcdev);
	if (ret) {
		dev_err(&pdev->dev, "unable to register device\n");
		return ret;
	}

	ret = register_restart_handler(&mlb_reset_restart_nb);
	if (ret)
		dev_warn(&pdev->dev, "failed to register restart handler\n");

	return 0;
}

static int mlb_reset_remove(struct platform_device *pdev)
{
	struct mlb_reset_data *rc = platform_get_drvdata(pdev);
	int ret;

	ret = unregister_restart_handler(&mlb_reset_restart_nb);
	if (ret)
		dev_warn(&pdev->dev, "failed to unregister restart handler\n");

	reset_controller_unregister(&rc->rcdev);

	return 0;
}

static const struct of_device_id mlb_reset_match[] = {
	{ .compatible = "socionext,milbeaut-m20v-reset" },
	{ }
};
MODULE_DEVICE_TABLE(of, mlb_reset_match);

static struct platform_driver milbeaut_reset_driver = {
	.probe	= mlb_reset_probe,
	.remove	= mlb_reset_remove,
	.driver	= {
		.name		= "milbeaut-reset",
		.of_match_table	= mlb_reset_match,
	},
};
module_platform_driver(milbeaut_reset_driver);
MODULE_LICENSE("GPL v2");
