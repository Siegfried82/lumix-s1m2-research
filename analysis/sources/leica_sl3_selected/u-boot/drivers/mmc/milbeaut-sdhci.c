// SPDX-License-Identifier: GPL-2.0+
/*
 * Copyright (C) 2019 Socionext Inc.
 *   Author: Kazuhiro Kasai <<REDACTED_EMAIL>>
 */

#include <common.h>
#include <dm.h>
#include <malloc.h>
#include <sdhci.h>
#include <asm/io.h>
#include <linux/bitfield.h>
#include <linux/io.h>

/*
 * Vendor specific registers (0x100 - 0x1ff)
 */
#define MILBEAUT_AHB_CONFIG	0x100
#define  ENDIAN_SEL	BIT(6)
#define  BUSLOCK_SEL	BIT(5)
#define  BUSLOCK_EN	BIT(4)
#define  SIN_EN		BIT(3)
#define  INCR_SEL	GENMASK(2, 0)

#define MILBEAUT_ESD_CONTROL	0x124
#define  CMD_DAT_DELAY	BIT(9)

#define MILBEAUT_BCLKSEL_CONTROL	0x1e0
#define  REGSEL		BIT(16)
#define  BCLKDIV	GENMASK(10, 9)
#define  BCLKSEL	BIT(8)

#define MILBEAUT_CS_PORT_CONTROL	0x1e4
#define  DATCS		GENMASK(23, 16)
#define  CMDCS		BIT(8)
#define  CLKCS		BIT(0)

/*
 * Glue module register (JCTUHS201)
 * TODO: Check if SOFTWARE_RESET_ALL reset these registers or not?
 */
#define MILBEAUT_SOFT_RESET	0x200
#define  RSTX		BIT(0)

#define MILBEAUT_WP_CD_LED_SET	0x210
#define  LED_INV	BIT(2)
#define  WP_INV		BIT(1)
#define  CD_INV		BIT(0)

#define MILBEAUT_CR_SET		0x220
#define  TOCLKUNIT	BIT(24)
#define  TOCLKFREQ	GENMASK(21, 16)
#define  BCLKFREQ	GENMASK(15, 8)
#define  RTUNTIMER	GENMASK(7, 4)

#define MILBEAUT_CDR_SET	0x230
#define  DTIMEC		GENMASK(3, 0)

/*
 * We use the frequency which comes from the capability register.
 */
#define MILBEAUT_SDHCI_MAXIMUM_CLOCK_FREQUENCY	0

/*
 * When the minimum clock frequency is set to 0 (auto-detect), U-Boot
 * sets it to 100 MHz divided by SDHCI_MAX_DIV_SPEC_300, or 48,875 Hz,
 * which results in the controller timing out when trying to
 * communicate with the MMC device.  Hard-code this value to 400000
 * (400 kHz) to prevent this.
 */
#define MILBEAUT_SDHCI_MINIMUM_CLOCK_FREQUENCY	400000

struct milbeaut_sdhci_plat {
	struct mmc_config cfg;
	struct mmc mmc;
};

struct milbeaut_sdhci_host {
	struct sdhci_host host;
	u16 transfer_data;
};

static struct milbeaut_sdhci_host *to_milbeaut_host(struct sdhci_host *host)
{
	return container_of(host, struct milbeaut_sdhci_host, host);
}

static void milbeaut_sdhci_writew(struct sdhci_host *host, u16 val, int reg)
{
	u32 addr32;
	u32 data;
	u32 shift;
	u32 mask;
	struct milbeaut_sdhci_host *mhost = to_milbeaut_host(host);

	if (reg == SDHCI_TRANSFER_MODE) {
		mhost->transfer_data = val;
		return;
	}

	addr32 = reg & 0xFFFFFFFC;

	if (reg == SDHCI_COMMAND) {
		data = mhost->transfer_data;
		mhost->transfer_data = 0;
	}
	else {
		data = readl(host->ioaddr + addr32);
	}

	shift = 8 * (reg & 0x2);
	mask = ~(0xFFFF << shift);
	data = (data & mask) | ((u32)val << shift);
	writel(data, host->ioaddr + addr32);
}

static u16 milbeaut_sdhci_readw(struct sdhci_host *host, int reg)
{
	u32 data;
	u32 shift;
	struct milbeaut_sdhci_host *mhost = to_milbeaut_host(host);

	if (reg == SDHCI_TRANSFER_MODE)
		return mhost->transfer_data;

	data = readl(host->ioaddr + (reg & 0xFFFFFFFC));
	shift = 8 * (reg & 0x2);
	data >>= shift;

	return (u16)data;
}

/* This Host Controller registers are accessible only by 32-bit and 8-bit access. */
static const struct sdhci_ops milbeaut_sdhci_ops = {
	.write_w = milbeaut_sdhci_writew,
	.read_w = milbeaut_sdhci_readw,
};

static int milbeaut_sdhci_always_true(struct udevice *dev)
{
	return 1;
}

static int milbeaut_sdhci_bind(struct udevice *dev)
{
	struct milbeaut_sdhci_plat *plat = dev_get_platdata(dev);

	return sdhci_bind(dev, &plat->mmc, &plat->cfg);
}

static void milbeaut_sdhci_set_cap(struct sdhci_host *host, u32 sd4clk)
{
	u32 tmp;

	/*
	 * Time Out Clock is (SD_SD4CLK_I / 16) MHz
	 * Base Clock is (SD_SD4CLK_I / 4) MHz
	 */
	tmp = FIELD_PREP(TOCLKUNIT, 1) |
		FIELD_PREP(TOCLKFREQ, sd4clk / 16) |
		FIELD_PREP(BCLKFREQ, sd4clk / 4);
	sdhci_writel(host, tmp, MILBEAUT_CR_SET);
}

static void milbeaut_sdhci_ctrl_reset(struct sdhci_host *host, int assert)
{
	u32 val;

	val = sdhci_readl(host, MILBEAUT_SOFT_RESET);
	val &= ~RSTX;
	val |= FIELD_PREP(RSTX, assert);
	sdhci_writel(host, val, MILBEAUT_SOFT_RESET);
}

__maybe_unused
static void milbeaut_sdhci_assert_reset(struct sdhci_host *host)
{
	return milbeaut_sdhci_ctrl_reset(host, 0);
}

static void milbeaut_sdhci_deassert_reset(struct sdhci_host *host)
{
	return milbeaut_sdhci_ctrl_reset(host, 1);
}

static void milbeaut_sdhci_ctrl_io_register(struct sdhci_host *host, int enable)
{
	u32 val;

	val = sdhci_readl(host, MILBEAUT_BCLKSEL_CONTROL);
	val &= ~REGSEL;
	val |= FIELD_PREP(REGSEL, enable);
	sdhci_writel(host, val, MILBEAUT_BCLKSEL_CONTROL);
}

static void milbeaut_sdhci_enable_io_register_access(struct sdhci_host *host)
{
	return milbeaut_sdhci_ctrl_io_register(host, 1);
}

static void milbeaut_sdhci_disable_io_register_access(struct sdhci_host *host)
{
	return milbeaut_sdhci_ctrl_io_register(host, 0);
}

static void milbeaut_sdhci_io_init(struct sdhci_host *host)
{
	u32 tmp;

	milbeaut_sdhci_enable_io_register_access(host);

	tmp = FIELD_PREP(DATCS, 0xf) |
		FIELD_PREP(CMDCS, 1) |
		FIELD_PREP(CLKCS, 1);
	sdhci_writel(host, tmp, MILBEAUT_CS_PORT_CONTROL);

	milbeaut_sdhci_disable_io_register_access(host);
}

static void milbeaut_sdhci_prepare(struct sdhci_host *host)
{
	u32 sd4clk = 200; /* SD_SD4CLK_I must be 200MHz */

	/*
	 * We should set the capability register,
	 * while the controller is in reset.
	 */
	milbeaut_sdhci_set_cap(host, sd4clk);

	milbeaut_sdhci_deassert_reset(host);

	milbeaut_sdhci_io_init(host);
}

static int milbeaut_sdhci_init(struct sdhci_host *host)
{
	u32 tmp;

	/*
	 * sdhci_probe() punch SDHCI_RESET_ALL, io register is cleared.
	 * So we need to call milbeaut_sdhci_io_init() again here.
	 */
	milbeaut_sdhci_io_init(host);

	/* Initialze the vendor specific registers. */
	tmp = FIELD_PREP(SIN_EN, 1) |
		FIELD_PREP(INCR_SEL, 0x7);
	sdhci_writel(host, tmp, MILBEAUT_AHB_CONFIG);

	tmp = FIELD_PREP(CMD_DAT_DELAY, 1);
	sdhci_writel(host, tmp, MILBEAUT_ESD_CONTROL);

	return 0;
}

static int milbeaut_sdhci_probe(struct udevice *dev)
{
	struct mmc_uclass_priv *upriv = dev_get_uclass_priv(dev);
	struct milbeaut_sdhci_plat *plat = dev_get_platdata(dev);
	struct milbeaut_sdhci_host *mhost = dev_get_priv(dev);
	struct sdhci_host *host = &mhost->host;
	struct dm_mmc_ops *ops = mmc_get_ops(dev);
	fdt_addr_t base;
	int ret;

	base = devfdt_get_addr(dev);
	if (base == FDT_ADDR_T_NONE)
		return -EINVAL;

	host->name = dev->name;
	host->ioaddr = devm_ioremap(dev, base, SZ_512);
	host->ops = &milbeaut_sdhci_ops;

	milbeaut_sdhci_prepare(host);

	/*
	 * TODO: It seems that get_cd callback is required to use mmc subsystem,
	 * but I can't find the way to register the callback with the sdhci_ops.
	 * I know this is not the best way, but it's better than nothing.
	 */
	if (!ops->get_cd)
		ops->get_cd = milbeaut_sdhci_always_true;

	ret = sdhci_setup_cfg(&plat->cfg, host,
			      MILBEAUT_SDHCI_MAXIMUM_CLOCK_FREQUENCY,
			      MILBEAUT_SDHCI_MINIMUM_CLOCK_FREQUENCY);
	if (ret)
		return ret;

	upriv->mmc = &plat->mmc;
	host->mmc = &plat->mmc;
	host->mmc->priv = host;

	ret = sdhci_probe(dev);
	if (ret)
		return ret;

	return milbeaut_sdhci_init(host);
}

static const struct udevice_id milbeaut_sdhci_match[] = {
	{ .compatible = "socionext,milbeaut-sdhci" },
	{ }
};

U_BOOT_DRIVER(sdhci_milbeaut) = {
	.name = "milbeaut-sdhci",
	.id = UCLASS_MMC,
	.of_match = milbeaut_sdhci_match,
	.ops = &sdhci_ops,
	.bind = milbeaut_sdhci_bind,
	.probe = milbeaut_sdhci_probe,
	.priv_auto_alloc_size = sizeof(struct milbeaut_sdhci_host),
	.platdata_auto_alloc_size = sizeof(struct milbeaut_sdhci_plat),
};
