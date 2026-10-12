// SPDX-License-Identifier: GPL-2.0
/*
 * Copyright (C) 2020 Socionext Inc.
 */

#include <linux/bits.h>
#include <linux/delay.h>
#include <linux/err.h>
#include <linux/io.h>
#include <linux/module.h>
#include <linux/of.h>
#include <linux/of_device.h>
#include <linux/platform_device.h>
#include <linux/reboot.h>
#include <linux/reset-controller.h>
#include <linux/spinlock.h>
#include <dt-bindings/reset/milbeaut,karine-reset.h>

#define RST_ASSERT	1
#define RST_RELEASE	0
#define PCIE_DEV_TYPE_RC	0x4
#define PCIE_DEV_TYPE_EP	0x0

/* RESET register */
#define REG_RAMSLP       0x0D150704
#define B_RAMSLP_INTMEM  0x100
#define B_RAMSLP_NETSEC  0x80
#define B_RAMSLP_USB3    0x8
#define B_RAMSLP_USB2    0x4
#define B_RAMSLP_PCIE1   0x2
#define B_RAMSLP_PCIE0   0x1
#define REG_RAMSD        0x0D150714
#define B_RAMSD_USB3     0x8
#define B_RAMSD_USB2     0x4
#define B_RAMSD_PCIE1    0x2
#define B_RAMSD_PCIE0    0x1
/* EXS */
#define EXSBASE          0x1BA00000
#define USB2GRU          0x19893000
/* USB3 dev */
#define REG_UL_RSTX      0x600
#define B_UL_SSPHYRSTX   0x4
#define B_UL_FMPHYRSTX   0x2
#define B_UL_RSTX        0x1
/* USB3 HIF */
#define REG_UL_IOCNT     0x604
#define B_UL_VBD_SEL     0x02000000
#define B_UL_VBD_VAL     0x01000000
#define B_UL_VB_SEL      0x00000002
#define B_UL_VB_VAL      0x00000001
/* PCIE */
#define B_PX_SOFT_PHY_RESET  0x4
#define B_PX_SOFT_WARM_RESET 0x2
#define B_PX_SOFT_COLD_RESET 0x1
/* PCIE 0 */
#define PCIE0BASE        0x1BB00000
#define REG_P0_SS_RST_CTRL_1 0xE4C
#define REG_P0X_RSTX     0x700
#define B_P0X_RSTX       0x1
#define REG_P0X_IOCNT    0x704
#define B_P00_PERSTXISEL 0x20
#define B_P00_PERSTXIVAL 0x10
#define B_P00_PERSTXOVAL 0x1
#define REG_P0X_CNT0     0x708
#define MASK_P00DEVICE_TYPE 0xF
/* PCIE 1 */
#define PCIE1BASE        0x1BB80000
#define REG_P1X_RSTX     0x800
#define REG_P1_SS_RST_CTRL_1 0xE4C
#define B_P1X_RSTX       0x1
#define REG_P1X_IOCNT    0x804
#define B_P10_PERSTXISEL 0x20
#define B_P10_PERSTXIVAL 0x10
#define B_P10_PERSTXOVAL 0x1
#define REG_P1X_CNT0     0x808
#define B_P10DEVICE_TYPE 0xF
/* USB2 */
#define USB2BASE		0x19893000
#define REG_USB2_CKCTL		 0x0
#define B_HO_HCLKEN			 0x100
#define B_HDC_HCLKEN		 0x1
#define REG_USB2_RCTL		 0x4
#define B_HO_SRST			 0x100
#define B_HDC_SRST			 0x1
#define REG_USB2_ANPD		 0x8
#define REG_USB2_HFSEL		 0xC
#define REG_USB2_LMODSET	 0x24
#define REG_USB2_IDVBUSCTL	 0x30
#define MASK_USB2_VBDET_SEL	 0x03000000
#define REG_USB2_HDMAC1		 0x38
#define REG_USB2_HDMAC2		 0x3C
/* GPIO */
#define PIN_BASE		0x0D151000

static DEFINE_SPINLOCK(mlb_crglock);

typedef int (*reset_func)(struct reset_controller_dev *rcdev, int assert);
struct mlb_reset_data {
	struct reset_controller_dev rcdev;
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

static void readmodify_writel32(unsigned int bit,
			void __iomem *addr, char assert)
{
	unsigned int r;
	unsigned int w;

	r = readl_relaxed(addr);
	if (assert == 'h')
		w = (r & ~bit) | bit;
	else
		w = r & ~bit;
	writel_relaxed(w, addr);
}

static void spinlock_rmodify_writel32(unsigned int bit,
			void __iomem *addr, char assert)
{
	unsigned long flag = 0;
	unsigned int r;
	unsigned int w;

	spin_lock_irqsave(&mlb_crglock, flag);
	r = readl_relaxed(addr);
	if (assert == 'h')
		w = (r & ~bit) | bit;
	else
		w = r & ~bit;
	writel_relaxed(w, addr);
	spin_unlock_irqrestore(&mlb_crglock, flag);
}
static void spinlock_regwritel(unsigned int mask, unsigned long val,
			void __iomem *addr)
{
	unsigned long flag = 0;
	unsigned int r;
	unsigned int w;

	spin_lock_irqsave(&mlb_crglock, flag);
	r = readl_relaxed(addr);
	w = (r & ~mask) | val;
	writel_relaxed(w, addr);
	spin_unlock_irqrestore(&mlb_crglock, flag);
}

static int set_port_for_usb3(void)
{
	void __iomem *pinbase;
	unsigned int val;

	pinbase = ioremap(PIN_BASE, 0x1000);

	/* _2 does not use */
	val = readl_relaxed(pinbase + 0x1B0);
	val &= 0x0F00;
	writel_relaxed(val, pinbase + 0x1B0);
	/* PDRN */
	val = readl_relaxed(pinbase + 0x170);
	val &=	~(BIT(1)  | BIT(4));
	val |=(BIT(17) | BIT(20));
	writel_relaxed(val, pinbase + 0x170);
	/* EPCRN */
	val = readl_relaxed(pinbase + 0x178);
	val |=(BIT(1) | BIT(4) | BIT(17) | BIT(20));
	writel_relaxed(val, pinbase + 0x178);
	/* DDRN */
	val = readl_relaxed(pinbase + 0x174);
	val &= ~(BIT(0)  | BIT(2) | BIT(3));
	val |= (BIT(16)  | BIT(18) | BIT(19)
	      | BIT(1) | BIT(4) | BIT(17) | BIT(20));
	writel_relaxed(val, pinbase + 0x174);

	iounmap(pinbase);
	return 0;
}

static int
karine_usb3_reset(struct reset_controller_dev *rcdev, int assert)
{
	void __iomem *membase;
	char assert_char;

	if (assert == RST_RELEASE)
		assert_char = 'h';
	else
		assert_char = 'l';

	membase = ioremap(EXSBASE, 0x1000);
	spinlock_rmodify_writel32(
			B_UL_SSPHYRSTX | B_UL_FMPHYRSTX | B_UL_RSTX,
			membase + REG_UL_RSTX,
			assert_char);
	set_port_for_usb3();
	iounmap(membase);
	return 0;
}

static int set_port_for_usb2(void)
{
	void __iomem *pinbase;
	unsigned int val;

	pinbase = ioremap(PIN_BASE, 0x1000);
	/* *_2 does not use*/
	val = readl_relaxed(pinbase + 0x1B0);
	val &= 0xF0;
	writel_relaxed(val, pinbase + 0x1B0);
	/* PDRL */
	/* EPCRL */
	val = readl_relaxed(pinbase + 0x158);
	val |= (BIT(9) | BIT(12) | BIT(25) | BIT(28));
	writel_relaxed(val, pinbase + 0x158);
	/* DDRL */
	val = readl_relaxed(pinbase + 0x154);
	val &= ~(BIT(8) | BIT(10) | BIT(11));
	val |= (BIT(24) | BIT(26) | BIT(27));
	writel_relaxed(val, pinbase + 0x154);

	iounmap(pinbase);
	return 0;
}

static int
usb2_reset(struct reset_controller_dev *rcdev, int assert, unsigned long id)
{
	void __iomem *membase;

	membase = ioremap(USB2GRU, 0x1000);
	if (assert == RST_RELEASE) {
		set_port_for_usb2();
		writel_relaxed(0x0, membase + REG_USB2_ANPD);
		if (id == KARINE_USB2_RESET) {
			writel_relaxed(0x0, membase + REG_USB2_HFSEL);
			writel_relaxed(0x01000000, membase + REG_USB2_IDVBUSCTL);
			writel_relaxed(0x8, membase + REG_USB2_LMODSET);
			readmodify_writel32(B_HDC_HCLKEN, membase + REG_USB2_CKCTL, 'h');
			udelay(1);
			readmodify_writel32(B_HDC_SRST, membase + REG_USB2_RCTL, 'h');
			writel_relaxed(0x300, membase + REG_USB2_HDMAC1);
			writel_relaxed(0x300, membase + REG_USB2_HDMAC2);
		} else {
			writel_relaxed(0x1, membase + REG_USB2_HFSEL);
			writel_relaxed(0x100, membase + REG_USB2_IDVBUSCTL);
			writel_relaxed(0x4, membase + REG_USB2_LMODSET);
			readmodify_writel32(B_HO_HCLKEN, membase + REG_USB2_CKCTL, 'h');
			udelay(1);
			readmodify_writel32(B_HO_SRST, membase + REG_USB2_RCTL, 'h');
		}
	} else {
		if (id == KARINE_USB2_RESET) {
			readmodify_writel32(B_HDC_SRST, membase + REG_USB2_RCTL, 'l');
			readmodify_writel32(B_HDC_HCLKEN, membase + REG_USB2_CKCTL, 'l');
		} else {
			readmodify_writel32(B_HO_SRST, membase + REG_USB2_RCTL, 'l');
			readmodify_writel32(B_HO_HCLKEN, membase + REG_USB2_CKCTL, 'l');
		}
		writel_relaxed(0x1, membase + REG_USB2_ANPD);
	}
	iounmap(membase);
	return 0;
}

static int
karine_usb2_reset(struct reset_controller_dev *rcdev, int assert)
{
	return usb2_reset(rcdev, assert, KARINE_USB2_RESET);
}

static int
karine_usb2_ehci_reset(struct reset_controller_dev *rcdev, int assert)
{
	return usb2_reset(rcdev, assert, KARINE_USB2_EHCI_RESET);
}

static int
karine_usb3_hif_reset(struct reset_controller_dev *rcdev, int assert)
{
	void __iomem *membase;
	char assert_char;

	if (assert == RST_RELEASE)
		assert_char = 'h';
	else
		assert_char = 'l';

	membase = ioremap(EXSBASE, 0x1000);
	spinlock_rmodify_writel32(
			B_UL_VBD_SEL | B_UL_VBD_VAL |
			B_UL_VB_SEL | B_UL_VB_VAL,
			membase + REG_UL_IOCNT,
			assert_char);
	set_port_for_usb3();
	iounmap(membase);
	return 0;
}

static int
karine_pcie0_reset_pwr(struct reset_controller_dev *rcdev, int assert)
{
	void __iomem *membase;
	char assert_char;

	if (assert == RST_RELEASE)
		assert_char = 'h';
	else
		assert_char = 'l';

	membase = ioremap(EXSBASE, 0x1000);
	readmodify_writel32(
			B_P0X_RSTX,
			membase + REG_P0X_RSTX,
			assert_char);
	iounmap(membase);
	return 0;
}

static int
karine_pcie1_reset_pwr(struct reset_controller_dev *rcdev, int assert)
{
	void __iomem *membase;
	char assert_char;

	if (assert == RST_RELEASE)
		assert_char = 'h';
	else
		assert_char = 'l';

	membase = ioremap(EXSBASE, 0x1000);
	spinlock_rmodify_writel32(
			B_P1X_RSTX,
			membase + REG_P1X_RSTX,
			assert_char);
	iounmap(membase);
	return 0;
}

static int
pcie_reset_cnt0(struct reset_controller_dev *rcdev, int assert, unsigned long id)
{
	void __iomem *membase;
	unsigned long reg_ofs_cnt0, reg_ofs_iocnt;
	unsigned long val;

	membase = ioremap(EXSBASE, 0x1000);
	if (id == KARINE_PCIE0_RESET_CNT0) {
		reg_ofs_cnt0 = REG_P0X_CNT0;
		reg_ofs_iocnt = REG_P0X_IOCNT;
	} else {
		reg_ofs_cnt0 = REG_P1X_CNT0;
		reg_ofs_iocnt = REG_P1X_IOCNT;
	}
	if (assert == RST_ASSERT)
		val = PCIE_DEV_TYPE_RC;
	else
		val = PCIE_DEV_TYPE_EP;
	spinlock_regwritel(MASK_P00DEVICE_TYPE, val, membase + reg_ofs_cnt0);
	spinlock_rmodify_writel32(
			B_P00_PERSTXISEL | B_P00_PERSTXIVAL | B_P00_PERSTXOVAL,
			membase + reg_ofs_iocnt,
			'h');
	iounmap(membase);
	return 0;
}

static int
karine_pcie0_reset_cnt0(struct reset_controller_dev *rcdev, int assert)
{
	return pcie_reset_cnt0(rcdev, assert, KARINE_PCIE0_RESET_CNT0);
}

static int
karine_pcie1_reset_cnt0(struct reset_controller_dev *rcdev, int assert)
{
	return pcie_reset_cnt0(rcdev, assert, KARINE_PCIE1_RESET_CNT0);
}

static int
pcie_reset_soft(struct reset_controller_dev *rcdev, int assert, unsigned long id)
{
	void __iomem *mem;
	unsigned long val;

	if (id == KARINE_PCIE0_RESET_SOFT)
		mem = ioremap(PCIE0BASE + REG_P0_SS_RST_CTRL_1, 4);
	else
		mem = ioremap(PCIE1BASE + REG_P1_SS_RST_CTRL_1, 4);

	if (assert == RST_ASSERT)
		val = 1;
	else
		val = 0;
	spinlock_regwritel(
		B_PX_SOFT_PHY_RESET | B_PX_SOFT_WARM_RESET | B_PX_SOFT_COLD_RESET,
		val,
		mem);
	iounmap(mem);
	return 0;
}

static int
karine_pcie0_reset_soft(struct reset_controller_dev *rcdev, int assert)
{
	return pcie_reset_soft(rcdev, assert, KARINE_PCIE0_RESET_SOFT);
}

static int
karine_pcie1_reset_soft(struct reset_controller_dev *rcdev, int assert)
{
	return pcie_reset_soft(rcdev, assert, KARINE_PCIE1_RESET_SOFT);
}

static const reset_func rst_tables[] = {
[KARINE_USB2_RESET]			=	karine_usb2_reset,
[KARINE_USB3_RESET]			=	karine_usb3_reset,
[KARINE_USB3_HIF_RESET]		=	karine_usb3_hif_reset,
[KARINE_PCIE0_RESET_PWR]	=	karine_pcie0_reset_pwr,
[KARINE_PCIE1_RESET_PWR]	=	karine_pcie1_reset_pwr,
[KARINE_PCIE0_RESET_CNT0]	=	karine_pcie0_reset_cnt0,
[KARINE_PCIE1_RESET_CNT0]	=	karine_pcie1_reset_cnt0,
[KARINE_PCIE0_RESET_SOFT]	=	karine_pcie0_reset_soft,
[KARINE_PCIE1_RESET_SOFT]	=	karine_pcie1_reset_soft,
[KARINE_USB2_EHCI_RESET]	=	karine_usb2_ehci_reset,
};

static int
reset_release(struct reset_controller_dev *rcdev,
			     unsigned long id, char assert)
{
	if (id < KARINE_RESET_MAX)
		rst_tables[id](rcdev, assert);
	else
		return -EINVAL;

	return 0;
}

static int
mlb_assert(struct reset_controller_dev *rcdev, unsigned long id)
{
	return reset_release(rcdev, id, RST_ASSERT);
}

static int
mlb_deassert(struct reset_controller_dev *rcdev, unsigned long id)
{
	return reset_release(rcdev, id, RST_RELEASE);
}

static int
mlb_reset(struct reset_controller_dev *rcdev, unsigned long id)
{
	mlb_assert(rcdev, id);
	mlb_deassert(rcdev, id);
	return 0;
}

static struct reset_control_ops mlb_reset_ops = {
	.reset = mlb_reset,
	.assert = mlb_assert,
	.deassert = mlb_deassert,
};

static int mlb_reset_probe(struct platform_device *pdev)
{
	struct mlb_reset_data *rc;
	//struct device *dev = &pdev->dev;
	//struct resource *res;
	int ret;

	rc = devm_kzalloc(&pdev->dev, sizeof(*rc), GFP_KERNEL);
	if (!rc)
		return -ENOMEM;

	rc->rcdev.owner = THIS_MODULE;
	rc->rcdev.nr_resets = KARINE_RESET_MAX;
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
	{	.compatible = "socionext,milbeaut-karine-reset"}
};
MODULE_DEVICE_TABLE(of, mlb_reset_match);

static struct platform_driver milbeaut_karine_reset_driver = {
	.probe	= mlb_reset_probe,
	.remove	= mlb_reset_remove,
	.driver	= {
		.name		= "milbeaut-karine-reset",
		.of_match_table	= mlb_reset_match,
	},
};
module_platform_driver(milbeaut_karine_reset_driver);
MODULE_LICENSE("GPL v2");
