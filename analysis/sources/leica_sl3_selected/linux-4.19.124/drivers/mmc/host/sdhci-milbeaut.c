// SPDX-License-Identifier: GPL-2.0
/*
 * Copyright (C) 2013 - 2015 Fujitsu Semiconductor, Ltd
 *			  Vincent Yang <<REDACTED_EMAIL>>
 * Copyright (C) 2015 Linaro Ltd  Andy Green <<REDACTED_EMAIL>>
 * Copyright (C) 2019 Socionext Inc.
 *			  Takao Orito <<REDACTED_EMAIL>>
 * Copyright (c) 2020 Panasonic Corporation
 *   2020-07-27 Modified
 * Copyright (c) 2021 Panasonic Corporation
 *   2021-06-28 Modified
 */

#include <linux/bits.h>
#include <linux/clk.h>
#include <linux/delay.h>
#include <linux/err.h>
#include <linux/gpio/consumer.h>
#include <linux/module.h>
#include <linux/of.h>
#include <linux/of_device.h>
#include <linux/pm_runtime.h>
#include <linux/property.h>
#include "sdhci-pltfm.h"
#include "sdhci_f_sdh30.h"

/* next two registers are available on SDH30 ONLY if SDH40 macro exists. */
#define	MLB_BCLKSEL		0x1E0
#define  MLB_BCLKSEL_REGSEL		BIT(16)
#define  MLB_BCLKSEL_BCLKDIV_SFT	(10)
#define  MLB_BCLKSEL_BCLKSEL		BIT(8)

#define MLB_CS_PORT_CONTROL	0x01E4
#define  MLB_CS_PORT_CONTROL_DATCS_SFT	(16)
#define  MLB_CS_PORT_CONTROL_CMDCS	BIT(8)
#define  MLB_CS_PORT_CONTROL_CLKCS	BIT(0)

/* milbeaut bridge controller register */
#define MLB_SOFT_RESET		0x0200
#define  MLB_SOFT_RESET_RSTX		BIT(0)
#define  MLB_SOFT_RESET_RST2X		BIT(16)

#define MLB_WP_CD_LED_SET	0x0210
#define  MLB_WP_CD_LED_SET_LED_INV  BIT(2)

#define MLB_CR_SET			0x0220
#define  MLB_CR_SET_CR_TOCLKUNIT	   BIT(24)
#define  MLB_CR_SET_CR_TOCLKFREQ_SFT   (16)
#define  MLB_CR_SET_CR_TOCLKFREQ_MASK  (0x3F << MLB_CR_SET_CR_TOCLKFREQ_SFT)
#define  MLB_CR_SET_CR_BCLKFREQ_SFT	(8)
#define  MLB_CR_SET_CR_BCLKFREQ_MASK   (0xFF << MLB_CR_SET_CR_BCLKFREQ_SFT)
#define  MLB_CR_SET_CR_RTUNTIMER_SFT   (4)
#define  MLB_CR_SET_CR_RTUNTIMER_MASK  (0xF << MLB_CR_SET_CR_RTUNTIMER_SFT)

#define MLB_SD_TOCLK_I_DIV  16
#define MLB_TOCLKFREQ_UNIT_THRES	16000000
#define MLB_CAL_TOCLKFREQ_MHZ(rate) (rate / MLB_SD_TOCLK_I_DIV / 1000000)
#define MLB_CAL_TOCLKFREQ_KHZ(rate) (rate / MLB_SD_TOCLK_I_DIV / 1000)
#define MLB_TOCLKFREQ_MAX   63
#define MLB_TOCLKFREQ_MIN	1

#define MLB_SD_BCLK_I_DIV   4
#define MLB_CAL_BCLKFREQ(rate)  (((rate / MLB_SD_BCLK_I_DIV)+999999) / 1000000)
#define MLB_BCLKFREQ_MAX		255
#define MLB_BCLKFREQ_MIN		  1

#define MLB_CDR_SET			0x0230
#define MLB_CDR_SET_CLK2POW16	3

/* Extended Controller registers for UHS-II */
#define MLB_CR_SET2   		0x0224
#define  MLB_CR_SET2_18VDD2SUP		BIT(28)
#define  MLB_CR_SET2_UHS2GAP_SFT	(24)
#define  MLB_CR_SET2_UHS2DAP_SFT	(20)
#define  MLB_CR_SET2_UHS2MAXBLEN_SFT	(8)
#define  MLB_CR_SET2_UHS2NFCU		0x10
#define MLB_PV_SET5		0x0250

#define F_SDH40_MIN_CLOCK  26000000

/* F_SDH40 extended Controller registers */
#define ERS01         (0x0304)
#define  ERS01_SPDR        (BIT(6))
#define HRS32		 (0x0060)
#define  HRS32_LOCK		(BIT(2))
#define HRS38			(0x0078)
#define  HRS38_UHS2PC	  (BIT(0))
#define HRS39		 (0x007C)
#define  HRS39_SDBCLKSTP   (0x1)
#define HRS45		 (0x0094)
#define  HRS45_MASK		(0xFFFF008E)
#define  HRS45_CT_CT	   (0x40 << 8)
#define  HRS45_RCLK2EN_TST (0x1 << 6)
#define  HRS45_CT_NRST	 (0x1 << 4)
#define  HRS45_CTSEL	   (0x1)
#define HRS51		(0x00AC)
#define  HRS51_CPSEL_SRA	(0x4)
#define  HRS51_CPSEL_SRB	(0xB)
#define CRS06		 (0x00FC)
#define SRS51		(0x02CC)
#define SRS48		(0x02C0)
#define SRS17		(0x0244)
#define SRS16		(0x0240)
#define SRS15		(0x023C)
#define SRS14		(0x0238)
#define SRS13		(0x0234)
#define SRS11		(0x022C)
#define SRS10		(0x0228)
#define SRS09		(0x0224)
#define SRS50		(0x02C8)
#define U2IE	(0x01000000)
#define HV4E	(0x10000000)
#define UMS		(0x00070000)
#define CI		(0x00010000)
#define BUS_POWER_VDD1	(0x0100)
#define F_SDH30_SDHCI_HOST_VERSION (0xFC)

u32 core_clock = 800000000;

enum mil_sd_variants {
	/* M10V and SDHCI is 3.0 */
	MIL_SD_VARIANT_M10V_SD30,
	/* M10V and SDHCI is 4.0 */
	MIL_SD_VARIANT_M10V_SD40,
	/* M20V and SDHCI is 3.0 */
	MIL_SD_VARIANT_M20V_SD30,
	/* M20V and SDHCI is 4.0 */
	MIL_SD_VARIANT_M20V_SD40,
	/* KARINE and SDHCI is 3.0 */
	MIL_SD_VARIANT_KARINE_SD30,
};

struct sd30_clock_map {
	unsigned timing;
	u32	input_rate;
	unsigned div;
	u32 sdbase;
	int	delay_fixed;	//1:Fixed, 0=Variable
};

static const struct sd30_clock_map m20v_sd30_clk_table[] = {
	{MMC_TIMING_LEGACY,		200000000,	4,	 50000000,	1},
	{MMC_TIMING_SD_HS,		200000000,	4,	 50000000,	1},
	{MMC_TIMING_UHS_SDR12,	200000000,	4,	 50000000,	1},
	{MMC_TIMING_UHS_SDR25,	200000000,	4,	 50000000,	1},
	{MMC_TIMING_UHS_SDR50,	400000000,	4,	100000000,	0},
	{MMC_TIMING_UHS_SDR104,	800000000,	4,	200000000,	0},
};

static const struct sd30_clock_map m20v_sd30_clk_table_jitter[] = {
	{MMC_TIMING_LEGACY,		177777778,	4,	 44425000,	1},
	{MMC_TIMING_SD_HS,		177777778,	4,	 44425000,	1},
	{MMC_TIMING_UHS_SDR12,	177777778,	4,	 44425000,	1},
	{MMC_TIMING_UHS_SDR25,	177777778,	4,	 44425000,	1},
	{MMC_TIMING_UHS_SDR50,	320000000,	4,	80000000,	0},
	{MMC_TIMING_UHS_SDR104,	800000000,	4,	200000000,	0},
};

struct f_sdhost_priv {
	enum mil_sd_variants variant;
	struct clk *clk_iface;
	struct clk *clk;
	struct clk *clk_tuning;
	struct clk *clk_aclk;
	struct device *dev;
	bool enable_cmd_dat_delay;
	u16 transfer_data;
	u32 sd40_macro;
	u32 sd40_exe;
	u32 sd40_enable;
	u32 irq_sd30;
	u32 irq_sd40;
	void __iomem *ioaddr_sd30;
	void __iomem *ioaddr_sd40;
	void __iomem *ioaddr_sd40_sn;
	u32 actual_clk30;
	u32 actual_clk40;
	bool def_sdbclk;
	bool max_clock_with_jitter;
};

static inline void save_core_clock(struct f_sdhost_priv *priv)
{
	core_clock = clk_get_rate(priv->clk);
}

static inline void restore_core_clock(struct f_sdhost_priv *priv)
{
	clk_set_rate(priv->clk, core_clock);
}

static inline void sdh30_writel(struct f_sdhost_priv *priv, u32 val, int offs)
{
	writel(val, priv->ioaddr_sd30 + offs);
}

static inline u32 sdh30_readl(struct f_sdhost_priv *priv, int offs)
{
	return readl(priv->ioaddr_sd30 + offs);
}

static inline void sdh40_writel(struct f_sdhost_priv *priv, u32 val, int offs)
{
	writel(val, priv->ioaddr_sd40_sn + offs);
}

static inline u32 sdh40_readl(struct f_sdhost_priv *priv, int offs)
{
	return readl(priv->ioaddr_sd40_sn + offs);
}

static void sdhci_f_sdh40_set_u2ie(struct sdhci_host *host)
{
	struct f_sdhost_priv *priv = sdhci_priv(host);
	u32 val = sdh40_readl(priv, SRS15);

	if ((val & U2IE) == 0) {
		val |= U2IE;
		sdh40_writel(priv, val, SRS15);
		/* wait for 100ns */
		udelay(1);
	}
	val = sdh40_readl(priv, HRS38);
	if ((val & HRS38_UHS2PC) == 0)
		sdh40_writel(priv, HRS38_UHS2PC, HRS38);
}

static int sdhci_f_sdh40_set_version_quirk(struct sdhci_host *host)
{
	struct f_sdhost_priv *priv = sdhci_priv(host);
	int reg;

	if (priv->sd40_exe)
		reg = sdh40_readl(priv, CRS06) >> 16;
	else
		reg = sdhci_readl(host, F_SDH30_SDHCI_HOST_VERSION) >>16;

	return reg;
}

static int sdhci_f_sdh30_clock_change_quirk(struct sdhci_host *host)
{
	int ret = 0;
	ktime_t timeout;
	struct f_sdhost_priv *priv = sdhci_priv(host);
	u32 val;

	if (!priv->sd40_macro)
		/* Because of the additional register is used for only UHS1 */
		/* at the controller include both SD30 & SD40 */
		return ret;

	val = MLB_BCLKSEL_REGSEL | (1 << MLB_BCLKSEL_BCLKDIV_SFT);
	if (priv->def_sdbclk)
		val |= MLB_BCLKSEL_BCLKSEL;

	if(priv->sd40_macro == 0)
	/*Because of the additional register exist on the combination of SD30 and SD40 */
		return ret;

	if (priv->sd40_exe)
	/*Because of the additional register is used for UHS1 only */
		return ret;

	sdh30_writel(priv, val, MLB_BCLKSEL);

	/* If we need to wait, it's nonzero now (some IPs don't need wait) */
	val = sdh30_readl(priv, MLB_BCLKSEL);
	if (!val)
		return ret;

	/* wait for 1ms it to become ready */
	timeout = ktime_add_ms(ktime_get(), 10);
	while (1) {
		bool timedout = ktime_after(ktime_get(), timeout);
		
		if (sdh30_readl(priv, MLB_BCLKSEL) & BIT(0))
			break;
		if (timedout) {
			pr_err("%s:SD Base Clock doesn't stop\n",
				   mmc_hostname(host->mmc));
			sdhci_dumpregs(host);
			ret = -ETIMEDOUT;
		}
		udelay(10);
	}

	/* even if timeout, clear BIT(16) */
	val = (1 << MLB_BCLKSEL_BCLKDIV_SFT);
	if (priv->def_sdbclk)
		val |= MLB_BCLKSEL_BCLKSEL;
	sdh30_writel(priv, val, MLB_BCLKSEL);

	return ret;
}

static void sdhci_milbeaut_soft_voltage_switch(struct sdhci_host *host)
{
	u32 ctrl = 0;

	usleep_range(2500, 3000);
	ctrl = sdhci_readl(host, F_SDH30_IO_CONTROL2);
	ctrl |= F_SDH30_CRES_O_DN;
	sdhci_writel(host, ctrl, F_SDH30_IO_CONTROL2);
	ctrl |= F_SDH30_MSEL_O_1_8;
	sdhci_writel(host, ctrl, F_SDH30_IO_CONTROL2);
	ctrl &= ~F_SDH30_CRES_O_DN;
	sdhci_writel(host, ctrl, F_SDH30_IO_CONTROL2);
	usleep_range(2500, 3000);
	ctrl = sdhci_readl(host, F_SDH30_TUNING_SETTING);
	ctrl |= F_SDH30_CMD_CHK_DIS;
	sdhci_writel(host, ctrl, F_SDH30_TUNING_SETTING);
}

static unsigned int sdhci_milbeaut_get_min_clock(struct sdhci_host *host)
{
	struct f_sdhost_priv *priv = sdhci_priv(host);

	if (priv->sd40_exe)
		return F_SDH40_MIN_CLOCK;
	else
		return F_SDH30_MIN_CLOCK;
}

static unsigned int sdhci_milbeaut_get_max_clock(struct sdhci_host *host)
{
	struct f_sdhost_priv *priv = sdhci_priv(host);
	u32 max_clk;

	if (priv->variant == MIL_SD_VARIANT_M20V_SD40)
		if ((priv->def_sdbclk) || (priv->sd40_exe))
			max_clk = 4 * clk_get_rate(priv->clk);
		else
			max_clk = clk_get_rate(priv->clk_tuning);
	else
		max_clk = clk_get_rate(priv->clk) / 4;

	return max_clk;
}

static void s40_reset(struct f_sdhost_priv *priv,
			struct sdhci_host *host, u8 mask)
{
	unsigned long timeout = 10000;
	int d[4];
	u32 srs48;

	if (((sdh40_readl(priv, SRS10) &
			BUS_POWER_VDD1) == 0) ||
			(mask == 4))
	/* When SD bus power off,
	 * reset seem to be not completed.
	 * mask=4 is not exist for UHS2
	 */
		return;
	/* Keep enable */
	if (mask == SDHCI_UHS2_SW_RESET_SD) {
		d[0] = sdh40_readl(priv, SRS13);
		d[1] = sdh40_readl(priv, SRS14);
		d[2] = sdh40_readl(priv, SRS50);
		d[3] = sdh40_readl(priv, SRS51);
	}
	srs48 = sdh40_readl(priv, SRS48);
	srs48 |= mask;
	sdh40_writel(priv, srs48, SRS48);
	if (mask & SDHCI_UHS2_SW_RESET_FULL) {
		host->clock = 0;
		/* Reset-all turns off SD Bus Power */
		if (host->quirks2 & SDHCI_QUIRK2_CARD_ON_NEEDS_BUS_ON)
			sdhci_runtime_pm_bus_off(host);
	}
	/* Wait max 100 ms */
	/* hw clears the bit when it's done */
	while ((srs48 = sdh40_readl(priv, SRS48)) & mask) {
		if (timeout == 0) {
			pr_err("%s: Reset 0x%x never completed.srs48:%x\n",
				mmc_hostname(host->mmc), (int)mask, srs48);
			sdhci_dumpregs(host);
			return;
		}
		timeout--;
		udelay(10);
	}
	if (mask == SDHCI_UHS2_SW_RESET_SD) {
		sdh40_writel(priv, d[0], SRS13);
		sdh40_writel(priv, d[1], SRS14);
		sdh40_writel(priv, d[2], SRS50);
		sdh40_writel(priv, d[3], SRS51);
	}
}

static void s30_reset(struct f_sdhost_priv *priv,
			struct sdhci_host *host, u8 mask)
{
	u16 clk;
	u32 ctl;
	ktime_t timeout;

	clk = sdhci_readl(host, SDHCI_CLOCK_CONTROL);
	clk = (clk & ~SDHCI_CLOCK_CARD_EN) | SDHCI_CLOCK_INT_EN;
	sdhci_writel(host, clk, SDHCI_CLOCK_CONTROL);

	sdhci_reset(host, mask);

	if (mask & SDHCI_RESET_ALL)
		sdhci_f_sdh30_clock_change_quirk(host);

	clk |= SDHCI_CLOCK_CARD_EN;
	sdhci_writel(host, clk, SDHCI_CLOCK_CONTROL);

	timeout = ktime_add_ms(ktime_get(), 10);
	while (1) {
		bool timedout = ktime_after(ktime_get(), timeout);

		clk = sdhci_readl(host, SDHCI_CLOCK_CONTROL);
		if (clk & SDHCI_CLOCK_INT_STABLE)
			break;
		if (timedout) {
			pr_err("%s: Internal clock never stabilised.\n",
				mmc_hostname(host->mmc));
			sdhci_dumpregs(host);
			return;
		}
		udelay(10);
	}

	if ((mask & SDHCI_RESET_ALL) && (priv->sd40_macro)) {
		ctl = MLB_BCLKSEL_REGSEL | (1 << MLB_BCLKSEL_BCLKDIV_SFT);
		if (priv->def_sdbclk)
			ctl |= MLB_BCLKSEL_BCLKSEL;
		sdh30_writel(priv, ctl, MLB_BCLKSEL);
		sdh30_writel(priv,
			(0xf << MLB_CS_PORT_CONTROL_DATCS_SFT) |
			MLB_CS_PORT_CONTROL_CMDCS | MLB_CS_PORT_CONTROL_CLKCS,
			MLB_CS_PORT_CONTROL);
		ctl &= ~MLB_BCLKSEL_REGSEL;
		sdh30_writel(priv, ctl, MLB_BCLKSEL);
	}

	if (priv->enable_cmd_dat_delay) {
		ctl = sdhci_readl(host, F_SDH30_ESD_CONTROL);
		ctl |= F_SDH30_CMD_DAT_DELAY;
		sdhci_writel(host, ctl, F_SDH30_ESD_CONTROL);
	}

}
static void sdhci_milbeaut_reset(struct sdhci_host *host, u8 mask)
{
	struct f_sdhost_priv *priv = sdhci_priv(host);

	if (priv->sd40_exe)
		s40_reset(priv, host, mask);
	else
		s30_reset(priv, host, mask);
}

inline u16 sdhci_mil_read_w(struct sdhci_host *host, int reg)
{
	u32 data;
	u32 shift;

	if (reg == SDHCI_TRANSFER_MODE || reg == SDHCI_UHS2_TRANS_MODE) {
		struct f_sdhost_priv *priv = sdhci_priv(host);

		return priv->transfer_data;
	}

	data = readl(host->ioaddr + (reg & 0xFFFFFFFC));
	shift = 8 * (reg & 0x2);
	data >>= shift;

	return (u16)data;
}

inline u8 sdhci_mil_read_b(struct sdhci_host *host, int reg)
{
	u32 data;
	u32 shift;

	data = readl(host->ioaddr + (reg & 0xFFFFFFFC));
	shift = 8 * (reg & 0x3);
	data >>= shift;

	return (u8)data;
}

inline void sdhci_mil_write_w(struct sdhci_host *host, u16 val, int reg)
{
	u32 addr32;
	u32 data;
	u32 shift;
	u32 mask;
	struct f_sdhost_priv *priv = sdhci_priv(host);

	if (reg == SDHCI_TRANSFER_MODE || reg == SDHCI_UHS2_TRANS_MODE) {
		priv->transfer_data = val;
		return;
	}

	addr32 = reg & 0xFFFFFFFC;

	if (reg == SDHCI_COMMAND || reg == SDHCI_UHS2_COMMAND) {
		data = priv->transfer_data;
		priv->transfer_data = 0;
	} else
		data = readl(host->ioaddr + addr32);

	shift = 8 * (reg & 0x2);
	mask = ~(0xFFFF << shift);
	data = (data & mask) | ((u32)val << shift);
	writel(data, host->ioaddr + addr32);
}

inline void sdhci_mil_write_b(struct sdhci_host *host, u8 val, int reg)
{
	u32 addr32;
	u32 data;
	u32 shift;
	u32 mask;

	addr32 = reg & 0xFFFFFFFC;
	data = readl(host->ioaddr + addr32);
	shift = 8 * (reg & 0x3);
	mask = ~(0xFF << shift);
	data = (data & mask) | ((u32)val << shift);
	writel(data, host->ioaddr + addr32);
}

static inline void sdhci_milbeaut_bridge_reset(struct sdhci_host *host,
						u32 reset_flag)
{
	struct f_sdhost_priv *priv = sdhci_priv(host);

	sdh30_writel(priv, reset_flag, MLB_SOFT_RESET);
	udelay(50);
}

static void sdhci_milbeaut_bridge_init(struct sdhci_host *host,
						u32 rate)
{
	struct f_sdhost_priv *priv = sdhci_priv(host);
	u32 val, clk, tuning_clk;

	/* MLB_CR_SET should be set while reset */
	val = sdhci_readl(host, MLB_CR_SET);
	val &= ~(MLB_CR_SET_CR_TOCLKFREQ_MASK | MLB_CR_SET_CR_TOCLKUNIT |
			MLB_CR_SET_CR_BCLKFREQ_MASK);

	if (priv->sd40_macro)
		tuning_clk = clk_get_rate(priv->clk_tuning);
	else
		tuning_clk = rate;
	if (tuning_clk >= MLB_TOCLKFREQ_UNIT_THRES) {
		clk = MLB_CAL_TOCLKFREQ_MHZ(tuning_clk);
		clk = min_t(u32, MLB_TOCLKFREQ_MAX, clk);
		val |= MLB_CR_SET_CR_TOCLKUNIT |
			(clk << MLB_CR_SET_CR_TOCLKFREQ_SFT);
	} else {
		clk = MLB_CAL_TOCLKFREQ_KHZ(tuning_clk);
		clk = min_t(u32, MLB_TOCLKFREQ_MAX, clk);
		clk = max_t(u32, MLB_TOCLKFREQ_MIN, clk);
		val |= clk << MLB_CR_SET_CR_TOCLKFREQ_SFT;
	}

	if (priv->sd40_macro)
		// rate : SD Base clock to SDH30 (after BLKDIV[1:0])
		clk = (rate + 999999) / 1000000;
	else
		clk = MLB_CAL_BCLKFREQ(rate);	// rate : SD4CLK_I to SDH30
	clk = min_t(u32, MLB_BCLKFREQ_MAX, clk);
	clk = max_t(u32, MLB_BCLKFREQ_MIN, clk);
	pr_info("%s: Base Clock Frequency %d (MHz)\n",
		mmc_hostname(host->mmc), clk);
	val |=  clk << MLB_CR_SET_CR_BCLKFREQ_SFT;
	val &= ~MLB_CR_SET_CR_RTUNTIMER_MASK;
	sdhci_writel(host, val, MLB_CR_SET);

	sdhci_writel(host, MLB_CDR_SET_CLK2POW16, MLB_CDR_SET);

	sdhci_writel(host, MLB_WP_CD_LED_SET_LED_INV, MLB_WP_CD_LED_SET);
}

static void sdhci_milbeaut_vendor_init(struct sdhci_host *host)
{
	struct f_sdhost_priv *priv = sdhci_priv(host);
	u32 ctl;

	ctl = sdhci_readl(host, F_SDH30_IO_CONTROL2);
	ctl |= F_SDH30_CRES_O_DN;
	sdhci_writel(host, ctl, F_SDH30_IO_CONTROL2);
	ctl &= ~F_SDH30_MSEL_O_1_8;
	sdhci_writel(host, ctl, F_SDH30_IO_CONTROL2);
	ctl &= ~F_SDH30_CRES_O_DN;
	sdhci_writel(host, ctl, F_SDH30_IO_CONTROL2);

	ctl = sdhci_readl(host, F_SDH30_AHB_CONFIG);
	ctl |= F_SDH30_SIN | F_SDH30_AHB_INCR_16 | F_SDH30_AHB_INCR_8 |
		F_SDH30_AHB_INCR_4;
	ctl &= ~(F_SDH30_AHB_BIGED | F_SDH30_BUSLOCK_EN);
	sdhci_writel(host, ctl, F_SDH30_AHB_CONFIG);

	if (priv->enable_cmd_dat_delay) {
		ctl = sdhci_readl(host, F_SDH30_ESD_CONTROL);
		ctl |= F_SDH30_CMD_DAT_DELAY;
		sdhci_writel(host, ctl, F_SDH30_ESD_CONTROL);
	}

}

static int sdhci_f_sdh40_uhs2_to_uhs1(struct sdhci_host *host,
					irq_handler_t fn0, irq_handler_t fn1)
{
	int val;
	int ret;
	int to;
	u16 clk;
	struct f_sdhost_priv *priv = sdhci_priv(host);
	struct mmc_host *mmc = host->mmc;
	u32 reg;

	/* PHY control */
	val = sdh40_readl(priv, HRS45) & HRS45_MASK;
	val |= HRS45_CT_CT | HRS45_RCLK2EN_TST | HRS45_CT_NRST;
	sdh40_writel(priv, val, HRS45);
	sdh40_writel(priv, val | HRS45_CTSEL, HRS45);
	
	to = 100;
	while (--to && (sdh40_readl(priv, HRS32) & HRS32_LOCK))
		udelay(10);

	if (!to) {
		ret = -ETIMEDOUT;
		pr_err("%s: HRS32 Lock timeout failed %d\n",
			   mmc_hostname(host->mmc), ret);
		return ret;
	}

	sdh40_writel(priv, 0, HRS38);
	udelay(100);
	clk = sdh40_readl(priv, SRS11);
	clk &= ~SDHCI_CLOCK_INT_EN;
	sdh40_writel(priv, clk, SRS11);
	to = 100;
	while (--to && !(sdh40_readl(priv, HRS39) & HRS39_SDBCLKSTP))
		udelay(10);
	if (!to) {
		ret = -ETIMEDOUT;
		pr_err("%s: HRS39 SDBCLKSTP timeout failed %d\n",
			   mmc_hostname(host->mmc), ret);
		return ret;
	}

	val = sdh40_readl(priv, SRS15);
	val &= (~U2IE);
	sdh40_writel(priv, val, SRS15);

	/* Change SD40->SD30 */
	free_irq(host->irq, host);
	host->irq = priv->irq_sd30;

	ret = request_threaded_irq(host->irq, fn0, fn1,
				   IRQF_SHARED, mmc_hostname(mmc), host);

	if (ret) {
		pr_err("%s: Failed to request IRQ %d: %d\n",
			   mmc_hostname(mmc), host->irq, ret);
		return ret;
	}

	host->ioaddr = priv->ioaddr_sd30;
	priv->sd40_exe = 0;

	sdhci_milbeaut_bridge_reset(host, 0);
	udelay(1);
	sdhci_milbeaut_bridge_reset(host, MLB_SOFT_RESET_RSTX);

	/* Set clock for SD30 */
	reg = MLB_BCLKSEL_REGSEL | (0x1 << MLB_BCLKSEL_BCLKDIV_SFT);
	if (priv->def_sdbclk)
		reg |= MLB_BCLKSEL_BCLKSEL;
	sdh30_writel(priv, reg, MLB_BCLKSEL);
	/* Clear after reset. set for UHS1 */ 
	sdh30_writel(priv,
		(0xf << MLB_CS_PORT_CONTROL_DATCS_SFT) |
		MLB_CS_PORT_CONTROL_CMDCS | MLB_CS_PORT_CONTROL_CLKCS,
		MLB_CS_PORT_CONTROL);
	reg &= ~MLB_BCLKSEL_REGSEL;
	sdh30_writel(priv, reg, MLB_BCLKSEL);

	sdhci_milbeaut_vendor_init(host);

	mmc->caps &= ~MMC_CAP_UHS2;
	mmc->flags &= ~(MMC_UHS2_SUPPORT | MMC_UHS2_INITIALIZED);
	mmc->ios.timing = MMC_TIMING_LEGACY;
	mmc->f_min = F_SDH30_MIN_CLOCK;
	mmc->f_max = priv->actual_clk30;
	host->max_clk = mmc->f_max;

	sdhci_writel(host, host->ier, SDHCI_INT_ENABLE);
	sdhci_writel(host, host->ier, SDHCI_SIGNAL_ENABLE);
	/* Reset host version */
	host->version = sdhci_f_sdh40_set_version_quirk(host)
	 & SDHCI_SPEC_VER_MASK;
	return 0;
}

static int sdhci_f_sdh40_uhs1_to_uhs2(struct sdhci_host *host,
				irq_handler_t fn0, irq_handler_t fn1)
{
	int ret;
	struct f_sdhost_priv *priv = sdhci_priv(host);
	struct mmc_host *mmc = host->mmc;

	if (priv->sd40_macro == 0 || priv->sd40_enable == 1)
		return 0;

	free_irq(host->irq, host);
	host->irq = priv->irq_sd40;

	ret = request_threaded_irq(host->irq, fn0, fn1,
				   IRQF_SHARED, mmc_hostname(mmc), host);

	if (ret) {
		pr_err("%s: Failed to request IRQ %d: %d\n",
			   mmc_hostname(mmc), host->irq, ret);
		return ret;
	}

	/* Reset reg is at UHS1 side */
	sdhci_milbeaut_bridge_reset(host, 0);
	udelay(1);
	sdhci_milbeaut_bridge_reset(host, MLB_SOFT_RESET_RST2X);

	/* turn the "LED" on (power the card) */
	sdhci_writel(host, MLB_WP_CD_LED_SET_LED_INV, MLB_WP_CD_LED_SET);

	host->ioaddr = priv->ioaddr_sd40;
	priv->sd40_exe = 1;


	mmc->caps |= MMC_CAP_UHS2;
	mmc->flags |= MMC_UHS2_SUPPORT;
	mmc->flags &= ~MMC_UHS2_INITIALIZED;
	mmc->ios.timing = MMC_TIMING_UHS2;
	mmc->f_min = F_SDH40_MIN_CLOCK;
	mmc->f_max = priv->actual_clk40;
	host->max_clk = mmc->f_max;

	sdhci_writel(host, host->ier, SDHCI_INT_ENABLE);
	sdhci_writel(host, host->ier, SDHCI_SIGNAL_ENABLE);
	/* Reset host version */
	host->version = sdhci_f_sdh40_set_version_quirk(host)
	 & SDHCI_SPEC_VER_MASK;
	return 0;
}

static void sdhci_milbeaut_set_power(struct sdhci_host *host,
			unsigned char mode, unsigned short vdd,
			unsigned short vdd2)
{
	struct f_sdhost_priv *priv = sdhci_priv(host);

	if (!IS_ERR(host->mmc->supply.vmmc)) {
		struct mmc_host *mmc = host->mmc;

		mmc_regulator_set_ocr(mmc, mmc->supply.vmmc, vdd);
	}
	mdelay(35);
	if (priv->sd40_exe == 0)
		sdhci_set_power_noreg(host, mode, vdd, -1);
	else
		sdhci_set_power_noreg(host, mode, vdd, vdd2);
}

static int sdhci_milbeaut_select_drive_strength(struct mmc_card *card,
			unsigned int max_dtr, int host_drv,
			int card_drv, int *drv_type)
{
	int drv_type_tmp = host_drv & card_drv;
	if (drv_type_tmp & SD_DRIVER_TYPE_B)
		*drv_type = MMC_SET_DRIVER_TYPE_B;
	else
		*drv_type = MMC_SET_DRIVER_TYPE_A;

	return 0;
}

void sdhci_f_sdh40_exit_dormant_quirk(struct sdhci_host *host)
{
	u32 val;
	struct f_sdhost_priv *priv = sdhci_priv(host);

	val = sdh40_readl(priv, ERS01);
	val |= ERS01_SPDR;
	sdh40_writel(priv, val, ERS01);

	if (priv->variant == MIL_SD_VARIANT_M20V_SD40) {
		val = HRS51_CPSEL_SRB;
		sdh40_writel(priv, val, HRS51);
	} else {
		val = HRS45_RCLK2EN_TST | HRS45_CT_CT;
		sdh40_writel(priv, val, HRS45);
		sdh40_writel(priv, val | HRS45_CTSEL, HRS45);
		sdh40_writel(priv, val, HRS45);
	}
}

static void sdhci_milbeaut_read_caps(struct sdhci_host *host)
{
	struct f_sdhost_priv *priv = sdhci_priv(host);

	if (priv->sd40_exe) {
		host->caps = sdh40_readl(priv, SRS16);
		host->caps1 = sdh40_readl(priv, SRS17);
		host->caps1 |= SDHCI_DRIVER_TYPE_A;
		host->caps1 |= SDHCI_SUPPORT_SDR50 | SDHCI_SUPPORT_SDR104;
		host->caps |= SDHCI_CAN_VDD_180;
	} else {
		host->caps = sdh30_readl(priv, SDHCI_CAPABILITIES);
		host->caps1 = sdh30_readl(priv, SDHCI_CAPABILITIES_1);
#ifndef CONFIG_PVC_SELECT_SDIO_SPEED
		if (priv->sd40_macro == 0)
			host->caps1 &= ~(SDHCI_DRIVER_TYPE_A |
						SDHCI_DRIVER_TYPE_C | SDHCI_DRIVER_TYPE_D);
		host->caps1 |= SDHCI_SUPPORT_SDR50 | SDHCI_SUPPORT_SDR104;
#else /* CONFIG_PVC_SELECT_SDIO_SPEED */
		if (priv->sd40_macro == 0) {
			host->caps1 &= ~(SDHCI_DRIVER_TYPE_A |
						SDHCI_DRIVER_TYPE_C | SDHCI_DRIVER_TYPE_D);
			if (host->caps & ~(MMC_CAP_UHS_SDR25)) {
				host->caps1 &= ~(SDHCI_SUPPORT_SDR50 | SDHCI_SUPPORT_SDR104);
			}
		}else {
			host->caps1 |= SDHCI_SUPPORT_SDR50 | SDHCI_SUPPORT_SDR104;
		}
#endif /* CONFIG_PVC_SELECT_SDIO_SPEED */
		host->caps |= SDHCI_CAN_VDD_180;
	}
	pr_info("%s : caps=0x%x, caps1=0x%x\n",
		mmc_hostname(host->mmc), host->caps, host->caps1);
}

static void sdhci_f_uhs2_set_ios(struct sdhci_host *host,
	struct mmc_ios *ios)
{
	u32 clk, val;
	struct f_sdhost_priv *priv = sdhci_priv(host);

	if (ios->power_mode == MMC_POWER_OFF)
		return;

	val = sdh40_readl(priv, SRS09);
	if ((val & CI) == 0)
	/* card no inserted */
		return;
	if (ios->timing == MMC_TIMING_UHS2) {
	/* CR_SET2 has not any registers about clock.
	 * And, CR_SET is not used for UHS2. Therefore they are
	 * not need to set.
	 */
	/* Set U2IE to enable UHS2 interface and UHS2PC
	 *	to  pull-uo off for UHS1 IO
	 */
		sdhci_f_sdh40_set_u2ie(host);
		/* Set ICE */
		clk = sdh40_readl(priv, SRS11);
		if ((clk & SDHCI_CLOCK_INT_EN) == 0) {
			clk |= SDHCI_CLOCK_INT_EN;
			sdh40_writel(priv, clk, SRS11);
			/* Wait 20ms until ICS on */
			if (false == sdhci_wait_clock_stable(host)) {
				pr_err("%s: clock failed to be stable.\n",
					mmc_hostname(host->mmc));
				return;
			}
		}
		/* Should Set BVS,BP,BVS2, but they were set at power-up */
		/* Set UMS and HV4E */
		val = sdh40_readl(priv, SRS15);
		if (((val & UMS) == 0) ||
			((val & HV4E) == 0)) {
			val |= (UMS | HV4E);
			sdh40_writel(priv, val, SRS15);
			/* Wait 35ms */
			mdelay(35);
		}
		/* Set SDCE */
		clk = sdh40_readl(priv, SRS11);
		if ((clk & SDHCI_CLOCK_CARD_EN) == 0) {
			clk |= SDHCI_CLOCK_CARD_EN;
			sdh40_writel(priv, clk, SRS11);
			mdelay(1);
		}
	} else {
		val = sdh40_readl(priv, SRS15);
		val &= ~(U2IE | UMS);
		sdh40_writel(priv, val, SRS15);
	}
}

void sdhci_milbeaut_enable_clk(struct sdhci_host *host, u16 clk, u32 input_rate)
{
    int ret;
	struct f_sdhost_priv *priv = sdhci_priv(host);

	ret = sdhci_f_sdh30_clock_change_quirk(host);
	if (ret) {
		pr_err("%s: clock change quirk failed %d\n",
		       mmc_hostname(host->mmc), ret);
		return;
	}

	if (priv->sd40_exe)
		clk_set_rate(priv->clk_tuning, input_rate);
	else
		clk_set_rate(priv->clk, input_rate);

	clk |= SDHCI_CLOCK_INT_EN;
	sdhci_writew(host, clk, SDHCI_CLOCK_CONTROL);

	if (false == sdhci_wait_clock_stable(host)) {
		pr_err("%s: clock failed to be stable.\n",
			mmc_hostname(host->mmc));
		return;
	}

	/* We do not set SDHCI_PLL_EN because the SDHCI_PLL_EN
		is not using */
	clk |= SDHCI_CLOCK_CARD_EN;
	sdhci_writew(host, clk, SDHCI_CLOCK_CONTROL);
	/* It need to wait 600us after Enable SD clockBooting */
	udelay(600);
}


static void sdhci_milbeaut_set_clock(struct sdhci_host *host, unsigned int clock)
{
	int i, div = 0;
	int real_div = div;
	unsigned int max_clk;
	u32	input_rate;
	u16 clk;
	struct f_sdhost_priv *priv = sdhci_priv(host);

	if (clock == 0)
		return;

	if ((priv->variant == MIL_SD_VARIANT_M10V_SD30) ||
		(priv->variant == MIL_SD_VARIANT_M10V_SD40)) {
		sdhci_set_clock(host, clock);
		return;
	}

	if (priv->sd40_macro) {
		sdhci_set_clock(host, clock);
	} else {
		host->mmc->actual_clock = 0;

		sdhci_writew(host, 0, SDHCI_CLOCK_CONTROL);

		if (priv->max_clock_with_jitter) {
			for (i = 0;i < ARRAY_SIZE(m20v_sd30_clk_table_jitter); ++i)
				if(host->timing <= m20v_sd30_clk_table_jitter[i].timing)
					break;

			max_clk = m20v_sd30_clk_table_jitter[i].sdbase;
			input_rate = m20v_sd30_clk_table_jitter[i].input_rate;
		} else {
			for (i = 0;i < ARRAY_SIZE(m20v_sd30_clk_table); ++i)
				if(host->timing <= m20v_sd30_clk_table[i].timing)
					break;
			max_clk = m20v_sd30_clk_table[i].sdbase;
			input_rate = m20v_sd30_clk_table[i].input_rate;
		}

		if (max_clk <= clock)
			div = 1;
		else {
			for (div = 2; div < SDHCI_MAX_DIV_SPEC_300; div += 2) {
				if ((max_clk / div) <= clock)
					break;
			}
		}
		real_div = div;
		div >>= 1;

		if(real_div)
			host->mmc->actual_clock = max_clk / real_div;
		clk |= (div & SDHCI_DIV_MASK) << SDHCI_DIVIDER_SHIFT;
		clk |= ((div & SDHCI_DIV_HI_MASK) >> SDHCI_DIV_MASK_LEN)
			<< SDHCI_DIVIDER_HI_SHIFT;


		sdhci_milbeaut_enable_clk(host, clk, input_rate);
	}
}

static void sdhci_milbeaut_select_tuning(struct sdhci_host *host)
{
	u32 mode, result, ctrl;

	mode = sdhci_readl(host, SDHCI_HOST_CONTROL2);
	mode &= SDHCI_CTRL_UHS_MASK;
	if ((mode == SDHCI_CTRL_UHS_SDR50) || (mode == SDHCI_CTRL_UHS_SDR104)) {
		result = sdhci_readl(host, F_SDH30_TUNING_STATUS);
		result &= F_SDH30_TUNING_RES_MASK;
		if (result == F_SDH30_TUNING_RES_MASK) {
			ctrl = sdhci_readl(host, F_SDH30_TUNING_SETTING);
			if ((ctrl & F_SDH30_TUNING_SEL_ENABLE) ==
				F_SDH30_TUNING_SEL_ENABLE)
				return;
			ctrl &= ~F_SDH30_TUNING_SEL_MASK;
			ctrl |= F_SDH30_TUNING_SEL_ENABLE |
				F_SDH30_TUNING_SEL_PHA0;
			sdhci_writel(host, ctrl, F_SDH30_TUNING_SETTING);
		}
	}

	pr_info("%s : select tuning phase 0\n", mmc_hostname(host->mmc));
}

static const struct sdhci_ops sdhci_milbeaut_ops = {
	.voltage_switch = sdhci_milbeaut_soft_voltage_switch,
	.get_min_clock = sdhci_milbeaut_get_min_clock,
	.get_max_clock = sdhci_milbeaut_get_max_clock,
	.reset = sdhci_milbeaut_reset,
	.set_clock = sdhci_milbeaut_set_clock,
	.set_bus_width = sdhci_set_bus_width,
	.set_uhs_signaling = sdhci_set_uhs_signaling,
	.set_power = sdhci_milbeaut_set_power,
	.clock_change_quirk = sdhci_f_sdh30_clock_change_quirk,
	.exit_dormant_quirk = sdhci_f_sdh40_exit_dormant_quirk,
	.read_w = sdhci_mil_read_w,
	.read_b = sdhci_mil_read_b,
	.write_w = sdhci_mil_write_w,
	.write_b = sdhci_mil_write_b,
	.set_version_quirk = sdhci_f_sdh40_set_version_quirk,
	.uhs2_to_uhs1 = sdhci_f_sdh40_uhs2_to_uhs1,
	.uhs1_to_uhs2 = sdhci_f_sdh40_uhs1_to_uhs2,
	.uhs2_set_ios = sdhci_f_uhs2_set_ios,
	.read_caps = sdhci_milbeaut_read_caps,
	.select_tuning_quirk = sdhci_milbeaut_select_tuning,
};

static const struct of_device_id mlb_dt_ids[] = {
	{
		.compatible = "socionext,milbeaut-m10v-sdhci-3.0",
		.data = (void *)MIL_SD_VARIANT_M10V_SD30
	},
	{
		.compatible = "socionext,milbeaut-m10v-sdhci-4.0",
		.data = (void*)MIL_SD_VARIANT_M10V_SD40
	},
	{
		.compatible = "socionext,milbeaut-m20v-sdhci-3.0",
		.data = (void *)MIL_SD_VARIANT_M20V_SD30
	},
	{
		.compatible = "socionext,milbeaut-m20v-sdhci-4.0",
		.data = (void *)MIL_SD_VARIANT_M20V_SD40
	},
	{
		.compatible = "socionext,milbeaut-karine-sdhci-3.0",
		.data = (void *)MIL_SD_VARIANT_KARINE_SD30
	},
	{
		.compatible = "socionext,milbeaut-karine-sdhci-4.0",
		.data = (void *)MIL_SD_VARIANT_M20V_SD40
	},
	{ /* sentinel */ }
};
MODULE_DEVICE_TABLE(of, mlb_dt_ids);

static void sdhci_milbeaut_init(struct sdhci_host *host)
{
	struct f_sdhost_priv *priv = sdhci_priv(host);
	u32 rate;
	u32 val;

	if (priv->variant == MIL_SD_VARIANT_M20V_SD40) {
		if (priv->def_sdbclk) {
			rate = clk_get_rate(priv->clk);
			rate *= 4;      /* *16*(1/4)(by BLKDIV(at BLKSEL) */
			pr_info("%s: base clk for SD30:%d\n",
				mmc_hostname(host->mmc), rate);
		} else {
			rate = clk_get_rate(priv->clk_tuning);
			/* rate is equal to base clock. */
			/* *1/4(by UHS201)*16*(1/4)(by BLKDIV at BLKSEL reg) */
			pr_info("%s: base clk for SD30:%d\n",
				mmc_hostname(host->mmc), rate);
		}
	}
	else {
		rate = clk_get_rate(priv->clk);
		pr_info("%s: input clk for SD30:%d\n",
			mmc_hostname(host->mmc), rate);
	}

	if (priv->sd40_macro) {
		priv->actual_clk40 = rate;
		priv->actual_clk30 = rate;
	}
	host->quirks2 |= SDHCI_QUIRK2_OPS_SD_POWER_CONTROL;

	sdhci_milbeaut_bridge_init(host, rate);
	if (priv->sd40_exe) {
		val = MLB_CR_SET2_18VDD2SUP |
			(1 << MLB_CR_SET2_UHS2GAP_SFT) |
			(1 << MLB_CR_SET2_UHS2DAP_SFT) |
			(0x200 << MLB_CR_SET2_UHS2MAXBLEN_SFT) |
			MLB_CR_SET2_UHS2NFCU;
		sdhci_writel(host, val, MLB_CR_SET2);
		sdhci_writel(host, 0x00003200, MLB_PV_SET5); // PV_DTIMEC
		sdhci_milbeaut_bridge_reset(host, MLB_SOFT_RESET_RST2X);
	}
	else {
		sdhci_milbeaut_bridge_reset(host, MLB_SOFT_RESET_RSTX);
		sdhci_milbeaut_vendor_init(host);
	}
	if (priv->sd40_macro) {
		val = MLB_BCLKSEL_REGSEL | (1 << MLB_BCLKSEL_BCLKDIV_SFT);
		if (priv->def_sdbclk)
			val |= MLB_BCLKSEL_BCLKSEL;
		sdh30_writel(priv, val, MLB_BCLKSEL);
		val &= ~MLB_BCLKSEL_REGSEL;
		sdh30_writel(priv, val, MLB_BCLKSEL);
	}

}

static int sdhci_milbeaut_probe(struct platform_device *pdev)
{
	const struct of_device_id *of_id =
		of_match_device(mlb_dt_ids, &pdev->dev);
	struct sdhci_host *host;
	struct device *dev = &pdev->dev;
	struct resource *res;
	int irq, ret = 0;
	struct f_sdhost_priv *priv;

	irq = platform_get_irq(pdev, 0);
	if (irq < 0) {
		dev_err(dev, "%s: no irq specified\n", __func__);
		return irq;
	}

	host = sdhci_alloc_host(dev, sizeof(struct f_sdhost_priv));
	if (IS_ERR(host))
		return PTR_ERR(host);

	priv = sdhci_priv(host);
	priv->dev = dev;
	priv->variant = (uintptr_t)of_id->data;

	host->quirks = SDHCI_QUIRK_NO_ENDATTR_IN_NOPDESC |
			   SDHCI_QUIRK_INVERTED_WRITE_PROTECT |
			   SDHCI_QUIRK_CLOCK_BEFORE_RESET |
			   SDHCI_QUIRK_CAP_CLOCK_BASE_BROKEN |
			   SDHCI_QUIRK_DELAY_AFTER_POWER;
	host->quirks2 = SDHCI_QUIRK2_SUPPORT_SINGLE |
			SDHCI_QUIRK2_TUNING_WORK_AROUND |
			SDHCI_QUIRK2_PRESET_VALUE_BROKEN |
			SDHCI_QUIRK2_BROKEN_SDR50_TUNING;

	if (of_get_property(dev->of_node, "quirk-host-off-card-on", NULL))
		host->quirks2 |= SDHCI_QUIRK2_HOST_OFF_CARD_ON;

	priv->enable_cmd_dat_delay = device_property_read_bool(dev,
						"fujitsu,cmd-dat-delay-select");

	priv->max_clock_with_jitter = device_property_read_bool(dev,
						"max-clock-with-jitter");

	ret = mmc_of_parse(host->mmc);
	if (ret)
		goto err;
	if (priv->variant == MIL_SD_VARIANT_M20V_SD40)
		host->mmc->caps |= MMC_CAP_DRIVER_TYPE_A;

	platform_set_drvdata(pdev, host);

	host->hw_name = "f_sdh30";
	host->ops = &sdhci_milbeaut_ops;
	host->mmc_host_ops.select_drive_strength =
		sdhci_milbeaut_select_drive_strength;
	host->irq = irq;

	res = platform_get_resource(pdev, IORESOURCE_MEM, 0);
	host->ioaddr = devm_ioremap_resource(&pdev->dev, res);
	if (IS_ERR(host->ioaddr)) {
		ret = PTR_ERR(host->ioaddr);
		goto err;
	}

	if (dev_of_node(dev)) {
		sdhci_get_of_property(pdev);

		priv->ioaddr_sd30 = host->ioaddr;
		priv->irq_sd30	= host->irq;

		res = platform_get_resource_byname(pdev, IORESOURCE_MEM, "uhs2");
		if (res) {
			priv->sd40_macro = 1;
			priv->ioaddr_sd40 = devm_ioremap_resource(&pdev->dev, res);
			if (IS_ERR(priv->ioaddr_sd40)) {
				ret = PTR_ERR(priv->ioaddr_sd40);
				goto err;
			}

			res = platform_get_resource_byname(pdev, IORESOURCE_MEM, "uhs2_sn");
			priv->ioaddr_sd40_sn = devm_ioremap_resource(&pdev->dev, res);
			if (IS_ERR(priv->ioaddr_sd40_sn)) {
				ret = PTR_ERR(priv->ioaddr_sd40_sn);
				goto err;
			}

			priv->irq_sd40 = platform_get_irq_byname(pdev, "uhs2");
			if (priv->irq_sd40 == 0) {
				dev_err(dev, "%s: no irq specified for sd40\n", __func__);
				return priv->irq_sd40;
			}

			if (of_get_property(dev->of_node, "sd40_enable", NULL)) {
				priv->sd40_exe = 1;
				priv->sd40_enable = 0;
			}
			else {
				priv->sd40_enable = 1;
				priv->sd40_exe = 0;
			}
		}
		else {
			priv->sd40_macro = 0;
			priv->sd40_exe = 0;
		}
		priv->clk_iface = devm_clk_get(&pdev->dev, "iface");
		if (IS_ERR(priv->clk_iface)) {
			ret = PTR_ERR(priv->clk_iface);
			goto err;
		}

		ret = clk_prepare_enable(priv->clk_iface);
		if (ret)
			goto err;

		priv->clk = devm_clk_get(&pdev->dev, "core");
		save_core_clock( priv );
		
		
		if (IS_ERR(priv->clk)) {
			ret = PTR_ERR(priv->clk);
			goto err_clk;
		}

		ret = clk_prepare_enable(priv->clk);
		if (ret)
			goto err_clk;

		if (priv->variant == MIL_SD_VARIANT_M20V_SD40) {
			priv->clk_tuning = devm_clk_get(&pdev->dev,
				"tuning");
			if (IS_ERR(priv->clk_tuning)) {
				ret = PTR_ERR(priv->clk_tuning);
				goto err;
			}
			ret = clk_prepare_enable(priv->clk_tuning);
			if (ret)
				goto err;
			priv->clk_aclk = devm_clk_get(&pdev->dev, "aclk");
			if (IS_ERR(priv->clk_aclk)) {
				ret = PTR_ERR(priv->clk_aclk);
				goto err;
			}
			ret = clk_prepare_enable(priv->clk_aclk);
			if (ret)
				goto err;
			if (device_property_read_bool(dev,
						      "default-sdbclk"))
				priv->def_sdbclk = true;
		} else
			priv->def_sdbclk = false;
	}

	sdhci_milbeaut_init(host);

	if (priv->sd40_exe) {
		host->ioaddr = priv->ioaddr_sd40;
		host->mmc->f_min = F_SDH40_MIN_CLOCK;
		host->mmc->f_max =
		host->max_clk = priv->actual_clk40;

		sdhci_f_sdh40_set_u2ie(host);

		host->irq = priv->irq_sd40;
		host->quirks |= SDHCI_QUIRK_BROKEN_TIMEOUT_VAL;
	} else
		host->irq = priv->irq_sd30;

	ret = sdhci_add_host(host);
	if (ret)
		goto err_add_host;

	pm_runtime_enable(dev);
	pm_runtime_get_sync(dev);

	return 0;

err_add_host:
	clk_disable_unprepare(priv->clk);
err_clk:
	clk_disable_unprepare(priv->clk_iface);
err:
	sdhci_free_host(host);
	return ret;
}

static int sdhci_milbeaut_remove(struct platform_device *pdev)
{
	struct sdhci_host *host = platform_get_drvdata(pdev);
	struct f_sdhost_priv *priv = sdhci_priv(host);
	struct device *dev = &pdev->dev;

	restore_core_clock(priv);
	
	sdhci_remove_host(host, sdhci_readl(host, SDHCI_INT_STATUS) ==
			  0xffffffff);

	clk_disable_unprepare(priv->clk_iface);
	clk_disable_unprepare(priv->clk);

	pm_runtime_put_sync(dev);
	pm_runtime_disable(dev);

	sdhci_free_host(host);
	platform_set_drvdata(pdev, NULL);

	return 0;
}

#ifdef CONFIG_PM_SLEEP
static int milbeaut_resume(struct sdhci_host *host)
{
	struct f_sdhost_priv *priv = sdhci_priv(host);
	int ret;
	struct mmc_host *mmc = host->mmc;

	sdhci_milbeaut_bridge_reset(host, 0);
	ret = clk_prepare_enable(priv->clk_iface);
	if (ret) {
		pr_err("%s %d ret:%d\n",
			__func__, __LINE__, ret);
		goto err;
	}
	ret = clk_prepare_enable(priv->clk);
	if (ret) {
		pr_err("%s %d ret:%d\n",
			__func__, __LINE__, ret);
		goto err;
	}
	if (priv->variant == MIL_SD_VARIANT_M20V_SD40) {
		if (!IS_ERR(priv->clk_tuning)) {
			ret = clk_prepare_enable(priv->clk_tuning);
			if (ret) {
				pr_err("%s %d ret:%d\n",
					__func__, __LINE__, ret);
				goto err;
			}
		}
		if (!IS_ERR(priv->clk_aclk)) {
			ret = clk_prepare_enable(priv->clk_aclk);
			if (ret) {
				pr_err("%s %d ret:%d\n",
					__func__, __LINE__, ret);
				goto err;
			}
		}
	}

	if (priv->sd40_macro == 1 &&
		priv->sd40_enable == 0)
		priv->sd40_exe = 1;

	host->ioaddr = priv->ioaddr_sd30;
	sdhci_milbeaut_init(host);

	if (priv->sd40_macro == 1 &&
		priv->sd40_enable == 0) {
		host->ioaddr = priv->ioaddr_sd40;
		mmc->f_min =
		host->mmc->f_min = F_SDH40_MIN_CLOCK;
		host->mmc->f_max =
		host->max_clk = priv->actual_clk40;
		host->irq = priv->irq_sd40;

		mmc->caps |= MMC_CAP_UHS2;
		mmc->flags |= MMC_UHS2_SUPPORT;
		mmc->flags &= ~MMC_UHS2_INITIALIZED;
		mmc->ios.timing = MMC_TIMING_UHS2;
	}
	/* Reset host version */
	host->version = sdhci_f_sdh40_set_version_quirk(host);
err:
	return ret;
}

static int sdhci_milbeaut_suspend(struct device *dev)
{
	struct sdhci_host *host = dev_get_drvdata(dev);

	if (host->tuning_mode != SDHCI_TUNING_MODE_3)
		mmc_retune_needed(host->mmc);

	return sdhci_suspend_host(host);
}

static int sdhci_milbeaut_resume(struct device *dev)
{
	struct sdhci_host *host = dev_get_drvdata(dev);

	milbeaut_resume(host);
	return sdhci_resume_host(host);
}
#endif

#ifdef CONFIG_PM
static int sdhci_milbeaut_runtime_suspend(struct device *dev)
{
	struct sdhci_host *host = dev_get_drvdata(dev);

	return sdhci_runtime_suspend_host(host);
}
static int sdhci_milbeaut_runtime_resume(struct device *dev)
{
	struct sdhci_host *host = dev_get_drvdata(dev);

	return sdhci_runtime_resume_host(host);
}

static const struct dev_pm_ops sdhci_milbeaut_pmops = {
	SET_SYSTEM_SLEEP_PM_OPS(sdhci_milbeaut_suspend, sdhci_milbeaut_resume)
	SET_RUNTIME_PM_OPS(sdhci_milbeaut_runtime_suspend,
				sdhci_milbeaut_runtime_resume, NULL)
};

#define SDHCI_MILBEAUT_PMOPS (&sdhci_milbeaut_pmops)

#else
#define SDHCI_MILBEAUT_PMOPS (&sdhci_pltfm_pmops)
#endif

static struct platform_driver sdhci_milbeaut_driver = {
	.driver = {
		.name = "sdhci-milbeaut",
		.of_match_table = of_match_ptr(mlb_dt_ids),
		.pm	= SDHCI_MILBEAUT_PMOPS,
	},
	.probe	= sdhci_milbeaut_probe,
	.remove	= sdhci_milbeaut_remove,
};

module_platform_driver(sdhci_milbeaut_driver);

MODULE_DESCRIPTION("MILBEAUT SD Card Controller driver");
MODULE_AUTHOR("Takao Orito <<REDACTED_EMAIL>>");
MODULE_LICENSE("GPL v2");
MODULE_ALIAS("platform:sdhci-milbeaut");
