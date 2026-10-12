// SPDX-License-Identifier: GPL-2.0
/*
 * PWM driver for Milbeaut
 *
 * Copyright (C) 2015 Linaro, Ltd
 * Andy Green <<REDACTED_EMAIL>>
 *
 * Copyright (C) 2019 Socionext Inc.
 * Kazuhiro Kasai <<REDACTED_EMAIL>>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * version 2 as published by the Free Software Foundation.
 */

#include <linux/clk.h>
#include <linux/io.h>
#include <linux/module.h>
#include <linux/of.h>
#include <linux/of_device.h>
#include <linux/platform_device.h>
#include <linux/pwm.h>
#include <linux/time.h>

#include <linux/delay.h>

/*
 * Each IP instance / chip contains four 16-bit downcounter-based PWM
 * channels.
 *
 * These are the per-chip registers...
 */

enum regs {
	REG_GCN1		= 0,
		/* shifts to set the 4-bit TSEL field */
		GCN1_TSEL_A_S	= 0,
		GCN1_TSEL_B_S	= 4,
		GCN1_TSEL_C_S	= 8,
		GCN1_TSEL_D_S	= 12,
		/* 4-bit TSEL field meanings */
		GCN1_TSEL__GCN2_EN0	=	0,
		GCN1_TSEL__GCN2_EN1	=	1,
		GCN1_TSEL__GCN2_EN2	=	2,
		GCN1_TSEL__GCN2_EN3	=	3,
		GCN1_TSEL__RELOAD_CH0	=	4,
		GCN1_TSEL__RELOAD_CH1	=	5,
		GCN1_TSEL__EXT0		=	8,
		GCN1_TSEL__EXT1		=	9,
		GCN1_TSEL__EXT2		=	0xa,
		GCN1_TSEL__EXT3		=	0xb,
	REG_GCN2		= 4,
#define GCN2_STOP(n) (BIT(12) << n)
#define GCN2_MASK(n) (BIT(8) << n)
		GCN2__TMEEN	= BIT(7), /* Timer E mode */
		GCN2__CHAS	= BIT(4), /* 0 = ch0123 = ABCD, 1 = CBAD */
#define GCN2_EN(n) (BIT(0) << n)
	REG_TSEL		= 0x58,
		TSEL_SEL__CPU_ACCESS 	=	0,
		TSEL_SEL_TIMER_CH0	=	1,
		TSEL_SEL_TIMER_CH1	=	2,
		TSEL_SEL_TIMER_CH2	=	3,
	REG_PREV		= 0x5c,
		PREV__E0_S	= 8,
	REG_PCHSET0		= 0xc0,
#define PCHSET0__HLD(n) (BIT(12) << n)
#define PCHSET0__FRCVAL(n) (BIT(8) << n)
#define PCHSET0__OSTA(n) (BIT(4) << n)
#define PCHSET0__FRCEN(n) (BIT(0) << n)
	REG_PCHSET1		= 0xc4,
		PCHSET1_RQTIM_S	= 8,
		/* bitfield meanings in RQTIM */
		RQTIM_INTFREE2	= 0,
		RQTIM_INTFREE4	= 1,
		RQTIM_INTFREE6	= 2,
		PCHSET1_UDEN	= BIT(0),	/* enable underrun decel */
	REG_PINTCT0		= 0xc8,		/* interrupt control 0 */
		PINTCT0_UIS	= BIT(12),	/* STATUS underrun error */
		PINTCT0_FIS	= BIT(9),	/* STATUS forced stop */
		PINTCT0_AIS	= BIT(8),	/* STATUS Automatic stop */
		PINTCT0_UIE	= BIT(4),	/* ENABLE underrun error */
		PINTCT0_FIE	= BIT(1),	/* ENABLE forced stop error */
		PINTCT0_AIE	= BIT(0),	/* ENABLE auto stop error */
	REG_PINTCT1		= 0xcc,
		PINTCT1_DRQS	= BIT(15),	/* STATUS DMA req */
		PINTCT1_DRQE	= BIT(7),	/* ENABLE DMA req */
	REG_STMRH		= 0xd0,
	REG_STMRL		= 0xd4,
};

/* ... the remaining registers are per-channel, use the accessors */

enum ofs_ad {
	OFS_AD_PTMR		= 0,
	OFS_AD_PCSR		= 4,
	OFS_AD_PDUT		= 8,
	OFS_AD_PCN		= 0xc,
		PCN__CNTE	= BIT(15),
		PCN__STGR	= BIT(14),
		PCN__MDSE	= BIT(13),
		PCN__RTRG	= BIT(12),
		PCN__CKS_S	= 10,
		PCN__CKS_M	= 3,
		PCN__PGMS	= BIT(9),
		PCN__EGS_S	= 6,
		PCN__EGS_M	= 3,
		/* meanings of EGS field */
		EGS_RISING	= 1,
		EGS_FALLING	= 2,
		EGS_BOTH	= 3,
		PCN__IREN	= BIT(5),
		PCN__IRQF	= BIT(4),
		PCN__IRS_S	= 2,
		PCN__IRS_M	= 3,
		PCN__OSEL	= BIT(0),
		/* meanings of CKS[1,0] field */
		CKS_PASSTHRU	= 0,
		CKS_DIV4	= 1,
		CKS_DIV16	= 2,
		CKS_DIV64	= 3,
};

static inline u32 ad_reg(int n, enum ofs_ad ofs)
{
	return (n << 4) + 0x10 + ofs;
}

struct milbeaut_pwm_chip {
	struct pwm_chip chip;
	struct clk *clk;
	void __iomem *base;
	u32 count[4];
	u32 duty[4];
};

static const u8 prescaler_fixed[] = { 1, 4, 16, 64 };

static inline struct milbeaut_pwm_chip *to_milbeaut_pwm_chip(struct pwm_chip *c)
{
	return container_of(c, struct milbeaut_pwm_chip, chip);
}

static int milbeaut_pwm_running(struct pwm_device *pwm)
{
	struct milbeaut_pwm_chip *pc = to_milbeaut_pwm_chip(pwm->chip);

	return !(readl(pc->base + REG_GCN2) & GCN2_STOP(pwm->hwpwm));
}

static void milbeaut_pwm_set_counters(struct pwm_device *pwm)
{
	struct milbeaut_pwm_chip *pc = to_milbeaut_pwm_chip(pwm->chip);

	writel(pc->count[pwm->hwpwm], pc->base + ad_reg(pwm->hwpwm, OFS_AD_PCSR));
	writel(pc->duty[pwm->hwpwm], pc->base + ad_reg(pwm->hwpwm, OFS_AD_PDUT));
}

static void milbeaut_pwm_set_enable(struct pwm_chip *chip,
				       struct pwm_device *pwm, bool enable)
{
	struct milbeaut_pwm_chip *pc = to_milbeaut_pwm_chip(chip);
	u32 val;

	val = readl(pc->base + REG_GCN2);
	if (!enable)
		val |= GCN2_STOP(pwm->hwpwm);
	else
		val &= ~GCN2_STOP(pwm->hwpwm);
	writel(val, pc->base + REG_GCN2);

	if (!enable)
		return;

	milbeaut_pwm_set_counters(pwm);

	val = readl(pc->base + ad_reg(pwm->hwpwm, OFS_AD_PCN));
	val &= ~PCN__PGMS;
	val |= PCN__RTRG;
	writel(val, pc->base + ad_reg(pwm->hwpwm, OFS_AD_PCN));
	val |= PCN__STGR;
	writel(val, pc->base + ad_reg(pwm->hwpwm, OFS_AD_PCN));
	val |= PCN__CNTE | (EGS_RISING << PCN__EGS_S);
	writel(val, pc->base + ad_reg(pwm->hwpwm, OFS_AD_PCN));

	val = readl(pc->base + REG_GCN2);
	val |= GCN2_EN(pwm->hwpwm);
	writel(val, pc->base + REG_GCN2);
}

static int milbeaut_pwm_config(struct pwm_chip *chip, struct pwm_device *pwm,
			       int duty_ns, int period_ns)
{
	struct milbeaut_pwm_chip *pc = to_milbeaut_pwm_chip(chip);
	unsigned long period;
	bool already_set = 0;
	u64 clk_rate, limit;
	int ratio = 0;
	int ret;
	u32 val;

	clk_rate = clk_get_rate(pc->clk);

	/*
	 * The chip has /1, /4, /16 or /64 prescaler option
	 *
	 * Choose the fastest (most precise) ratio that can deal
	 * with the requested period
	 */

	while (ratio < 4) {
		/* period in ns of 65536 clocks (max count) */
		limit = NSEC_PER_SEC;
		do_div(limit, clk_rate >> 16);

		if (limit > period_ns / prescaler_fixed[ratio])
			break;

		ratio++;
	}
	if (ratio == 4)
		return -EINVAL;

	period = (limit * prescaler_fixed[ratio]) >> 16;
	if (!period)
		period = 1;

	/* allow the clock to run while we set it up */

	ret = clk_enable(pc->clk);
	if (ret)
		return ret;

	pc->count[pwm->hwpwm] = period_ns / period;
	pc->duty[pwm->hwpwm] = duty_ns / period;

	/* set the selected channel prescaler if changed */

	val = readl(pc->base + ad_reg(pwm->hwpwm, OFS_AD_PCN));
	if ((val & (PCN__CKS_M << PCN__CKS_S)) != (ratio << PCN__CKS_S)) {

		/* we have to stop the pwm unit to change prescaler */

		ret = milbeaut_pwm_running(pwm);
		if (ret)
			milbeaut_pwm_set_enable(chip, pwm, 0);
		val &= ~(PCN__CKS_M << PCN__CKS_S);
		val |= ratio << PCN__CKS_S;
		writel(val, pc->base + ad_reg(pwm->hwpwm, OFS_AD_PCN));
		if (ret) {
			milbeaut_pwm_set_enable(chip, pwm, 1);
			already_set = 1;
		}
	}

	if (!already_set)
		milbeaut_pwm_set_counters(pwm);

	clk_disable(pc->clk);

	return 0;
}

static int milbeaut_pwm_set_polarity(struct pwm_chip *chip,
				     struct pwm_device *pwm,
				     enum pwm_polarity polarity)
{
	struct milbeaut_pwm_chip *pc = to_milbeaut_pwm_chip(chip);
	u32 val;

	val = readl(pc->base + ad_reg(pwm->hwpwm, OFS_AD_PCN));
	val &= ~(PCN__OSEL);
	if (polarity == PWM_POLARITY_INVERSED)
		val |= PCN__OSEL;
	writel(val, pc->base + ad_reg(pwm->hwpwm, OFS_AD_PCN));

	return 0;
}

static int milbeaut_pwm_enable(struct pwm_chip *chip, struct pwm_device *pwm)
{
	struct milbeaut_pwm_chip *pc = to_milbeaut_pwm_chip(chip);
	int ret;

	ret = clk_enable(pc->clk);
	if (ret)
		return ret;

	milbeaut_pwm_set_enable(chip, pwm, true);

	return 0;
}

static void milbeaut_pwm_disable(struct pwm_chip *chip, struct pwm_device *pwm)
{
	struct milbeaut_pwm_chip *pc = to_milbeaut_pwm_chip(chip);

	milbeaut_pwm_set_enable(chip, pwm, false);

	clk_disable(pc->clk);
}

static const struct pwm_ops milbeaut_pwm_ops = {
	.config = milbeaut_pwm_config,
	.set_polarity = milbeaut_pwm_set_polarity,
	.enable = milbeaut_pwm_enable,
	.disable = milbeaut_pwm_disable,
	.owner = THIS_MODULE,
};

static const struct of_device_id milbeaut_pwm_dt_ids[] = {
	{ .compatible = "socionext,milbeaut-pwm" },
	{ /* sentinel */ }
};
MODULE_DEVICE_TABLE(of, milbeaut_pwm_dt_ids);

static int milbeaut_pwm_probe(struct platform_device *pdev)
{
	struct milbeaut_pwm_chip *pc;
	struct resource *r;
	u32 rate;
	int ret;

	pc = devm_kzalloc(&pdev->dev, sizeof(*pc), GFP_KERNEL);
	if (!pc)
		return -ENOMEM;

	r = platform_get_resource(pdev, IORESOURCE_MEM, 0);
	pc->base = devm_ioremap_resource(&pdev->dev, r);
	if (IS_ERR(pc->base))
		return PTR_ERR(pc->base);

	pc->clk = of_clk_get(pdev->dev.of_node, 0);
	if (IS_ERR(pc->clk))
		return PTR_ERR(pc->clk);

	if (!of_property_read_u32(pdev->dev.of_node, "base-rate", &rate))
		clk_set_rate(pc->clk, rate);

	ret = clk_prepare(pc->clk);
	if (ret)
		return ret;

	pc->chip.dev = &pdev->dev;
	pc->chip.ops = &milbeaut_pwm_ops;
	pc->chip.base = -1;
	pc->chip.npwm = 4;

	ret = pwmchip_add(&pc->chip);
	if (ret < 0) {
		clk_unprepare(pc->clk);
		dev_err(&pdev->dev, "pwmchip_add() failed: %d\n", ret);
	}

	platform_set_drvdata(pdev, pc);

	return ret;
}

static int milbeaut_pwm_remove(struct platform_device *pdev)
{
	struct milbeaut_pwm_chip *pc = platform_get_drvdata(pdev);
	int ret;

	ret =  pwmchip_remove(&pc->chip);
	if (ret)
		return ret;

	clk_unprepare(pc->clk);
	clk_put(pc->clk);

	return 0;
}

static struct platform_driver milbeaut_pwm_driver = {
	.driver = {
		.name = "milbeaut-pwm",
		.of_match_table = milbeaut_pwm_dt_ids,
	},
	.probe = milbeaut_pwm_probe,
	.remove = milbeaut_pwm_remove,
};
module_platform_driver(milbeaut_pwm_driver);

MODULE_AUTHOR("Andy Green <<REDACTED_EMAIL>>");
MODULE_AUTHOR("Kazuhiro Kasai <<REDACTED_EMAIL>>");
MODULE_DESCRIPTION("Socionext Milbeaut PWM driver");
MODULE_LICENSE("GPL v2");
