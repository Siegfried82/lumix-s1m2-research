// SPDX-License-Identifier: GPL-2.0
/*
 * Milbeaut Timer64 driver
 *
 * Copyright (C) 2019 Socionext Inc.
 *
 */

#include <linux/bitfield.h>
#include <linux/clk.h>
#include <linux/dmaengine.h>
#include <linux/iio/events.h>
#include <linux/iio/buffer.h>
#include <linux/iio/iio.h>
#include <linux/iio/buffer-dmaengine.h>
#include <linux/iio/kfifo_buf.h>
#include <linux/interrupt.h>
#include <linux/module.h>
#include <linux/of.h>
#include <linux/of_dma.h>
#include <linux/platform_device.h>
#include <linux/regmap.h>

#define MLB_TIMER64_CSR1	0x00
#define  MLB_TIMER64_CSR1_CSL_SFT	10
#define  MLB_TIMER64_CSR1_CSL_MSK	GENMASK(11, 10)
#define  MLB_TIMER64_CSR1_CNTE	BIT(1)
#define  MLB_TIMER64_CSR1_TRG	BIT(0)
#define MLB_TIMER64_CSR2	0x10
#define  MLB_TIMER64_CSR2_EXRD	BIT(21)
#define  MLB_TIMER64_CSR2_EXFD	BIT(20)
#define  MLB_TIMER64_CSR2_EXM1	BIT(19)
#define  MLB_TIMER64_CSR2_EXM0	BIT(18)
#define  MLB_TIMER64_CSR2_FXE	BIT(17)
#define  MLB_TIMER64_CSR2_FRE	BIT(16)
#define  MLB_TIMER64_CSR2_CVT	BIT(0)

/* Gyro time stamp */
#define MLB_TIMER64_GSTMP	0x20

/* Frame Start time stamp */
#define MLB_TIMER64_FSSTMP_TOP	0x100

/* 64bit timer */
#define MLB_TIMER64_TMR64L	0x300
#define MLB_TIMER64_TMR64H	0x304

#define MILBEAUT_TIMER64_MAX_REGISTER	0x308

#define SENSOR_BANK_SIZE	0x20
#define FRAME_BANK_SIZE		0x100
#define REG_STMP0L		0x0
#define REG_STMP0H		0x4
#define REG_STMP1L		0x8
#define REG_STMP1H		0xc
#define REG_STMP2L		0x10
#define REG_STMP2H		0x14


#define DEVICE_NAME	"timer64"
#define DBG(f, x...) \
	pr_debug(DEVICE_NAME " [%s(L%d)]: " f, __func__, __LINE__, ## x)

#define MLB_TIMER64_MAX_DMA_BYTES	65536

#define MLB_TIMER64_CLK_DIV_MAX	2

#define MLB_TIMER64_MAX_SENSORNO	3

static const struct regmap_config milbeaut_timer64_regmap_cfg = {
	.reg_bits = 32,
	.val_bits = 32,
	.reg_stride = sizeof(u32),
	.max_register = MILBEAUT_TIMER64_MAX_REGISTER,
};

struct milbeaut_timer64_dma_data {
	struct dma_chan *ch;
	enum dma_transfer_direction direction;
	dma_addr_t addr;
};

struct milbeaut_timer64 {
	struct device *dev;
	struct regmap *regmap;
	void __iomem *baseadd;
	unsigned long basephy;
	struct clk *clk;
	int clk_rate;
	struct milbeaut_timer64_dma_data dma_rx;
	unsigned long max_dma_len;
	u32 frameedge;
	u32 sensorno;
	u32 exttrg_edge;
};

static int milbeaut_timer64_is_enabled(struct milbeaut_timer64 *priv)
{
	u32 val;
	int ret;

	ret = regmap_read(priv->regmap, MLB_TIMER64_CSR1, &val);
	if (ret)
		return ret;

	return FIELD_GET(MLB_TIMER64_CSR1_CNTE, val);
}

static int milbeaut_timer64_setup(struct milbeaut_timer64 *priv, int val)
{
	int ret;
	u32 mask, reg;

	switch (priv->exttrg_edge) {
	case 0:
	default:
		reg = MLB_TIMER64_CSR2_EXRD | MLB_TIMER64_CSR2_EXM0;
		break;
	case 1:
		reg = MLB_TIMER64_CSR2_EXFD | MLB_TIMER64_CSR2_EXM1;
		break;
	case 2:
		reg = MLB_TIMER64_CSR2_EXRD | MLB_TIMER64_CSR2_EXFD |
			 MLB_TIMER64_CSR2_EXM1 | MLB_TIMER64_CSR2_EXM0;
		break;
	}
	if (val)
		reg |= MLB_TIMER64_CSR2_FRE | MLB_TIMER64_CSR2_FXE;
	else
		reg &= ~(MLB_TIMER64_CSR2_FRE | MLB_TIMER64_CSR2_FXE);
	ret = regmap_write(priv->regmap, MLB_TIMER64_CSR2, reg);
	if (ret != 0) {
		DBG("%s failed, ret=%d\n", __func__, ret);
		return ret;
	}

	mask = MLB_TIMER64_CSR1_CNTE | MLB_TIMER64_CSR1_TRG;
	ret = regmap_update_bits(priv->regmap, MLB_TIMER64_CSR1,
		mask, val ? mask : 0);
	if (ret != 0) {
		DBG("%s failed, ret=%d\n", __func__, ret);
	}

	return ret;
}

static int milbeaut_timer64_write_raw(struct iio_dev *indio_dev,
		struct iio_chan_spec const *chan,
		int val, int val2, long mask)
{
	struct milbeaut_timer64 *priv = iio_priv(indio_dev);
	int ret, i;
	u64 clk_rate;
	u32 reg;

	DBG("write_raw: val=%d, val=%d, mask=0x%08x\n", val, val2,
		(unsigned int)mask);

	switch (mask) {
	case IIO_CHAN_INFO_ENABLE:
		if (val != 0 && val != 1)
			return -EINVAL;

		ret = milbeaut_timer64_is_enabled(priv);
		if (val && ret)
			return -EBUSY;

		ret = milbeaut_timer64_setup(priv, val);

		break;
	case IIO_CHAN_INFO_FREQUENCY:
		ret = milbeaut_timer64_is_enabled(priv);
		if (val && ret)
			return -EBUSY;

		clk_rate = clk_get_rate(priv->clk);
		for (i = MLB_TIMER64_CLK_DIV_MAX; i >= 0; i--)
			if (val <= (clk_rate >> (2 * i + 1)))
				break;
		if (i < 0)
			return -EINVAL;

		reg = i << MLB_TIMER64_CSR1_CSL_SFT;
		ret = regmap_update_bits(priv->regmap, MLB_TIMER64_CSR1,
			MLB_TIMER64_CSR1_CSL_MSK, reg);
		if (ret != 0) {
			pr_err("regmap_update_bits failed(%d)\n", ret);
			return ret;
		}
		priv->clk_rate = clk_rate >> (2 * i + 1);
		break;
	default:
		return -EINVAL;
	}

	return ret;
}

static int milbeaut_timer64_read_raw(struct iio_dev *indio_dev,
				struct iio_chan_spec const *chan,
				int *val, int *val2, long mask)
{
	struct milbeaut_timer64 *priv = iio_priv(indio_dev);
	int ret;

	DBG("read_raw: mask=0x%08x\n", (unsigned int)mask);

	switch (mask) {
	case IIO_CHAN_INFO_ENABLE:
		ret = milbeaut_timer64_is_enabled(priv);
		if (ret < 0)
			return ret;
		*val = ret;
		return IIO_VAL_INT;

	case IIO_CHAN_INFO_SCALE:
		*val = 1;
		*val2 = 0;
		return IIO_VAL_INT;

	case IIO_CHAN_INFO_OFFSET:
		*val = 0;
		*val2 = 0;
		return IIO_VAL_INT;
	case IIO_CHAN_INFO_FREQUENCY:
		*val = priv->clk_rate;
		*val2 = 0;
		return IIO_VAL_INT;
	default:
		return -EINVAL;
	}
}

static const struct iio_info milbeaut_timer64_iio_info = {
	.read_raw = milbeaut_timer64_read_raw,
	.write_raw = milbeaut_timer64_write_raw,
};

static int milbeaut_timer64_dma_init(struct iio_dev *indio_dev)
{
	struct milbeaut_timer64 *priv = iio_priv(indio_dev);
	struct dma_slave_config rxconf;
	struct iio_buffer *buffer;

	buffer = iio_dmaengine_buffer_alloc(priv->dev, "rx");
	if (!buffer) {
		pr_err("Ffailed to allocate IIO DMA buffer\n");
		return -ENOMEM;
	}

	rxconf.direction = DMA_DEV_TO_MEM;
	rxconf.src_addr = (unsigned int)priv->basephy + MLB_TIMER64_GSTMP;
	rxconf.src_addr_width = 4;
	rxconf.src_maxburst = 1;
	iio_dmaengine_buffer_slave_config(buffer, &rxconf);

	iio_device_attach_buffer(indio_dev, buffer);
	DBG("iio_device_attach_buffer is done\n");

	priv->max_dma_len = MLB_TIMER64_MAX_DMA_BYTES;

	return 0;
}

static const char * const milbeaut_timer64_frameedge[] = {
	"frame-start", "frame-end",
};

static int milbeaut_timer64_get_frameedge(struct iio_dev *indio_dev,
					const struct iio_chan_spec *chan)
{
	struct milbeaut_timer64 *priv = iio_priv(indio_dev);

	return priv->frameedge;
}

static int milbeaut_timer64_set_frameedge(struct iio_dev *indio_dev,
					const struct iio_chan_spec *chan,
					unsigned int type)
{
	struct milbeaut_timer64 *priv = iio_priv(indio_dev);

	priv->frameedge = type;

	return 0;
}

static const struct iio_enum milbeaut_timer64_frameedge_en = {
	.items = milbeaut_timer64_frameedge,
	.num_items = ARRAY_SIZE(milbeaut_timer64_frameedge),
	.get = milbeaut_timer64_get_frameedge,
	.set = milbeaut_timer64_set_frameedge,
};

static const char * const milbeaut_timer64_exttrg_edge[] = {
	"rise-edge", "fall-edge", "both-edge"
};

static int milbeaut_timer64_get_exttrg_edge(struct iio_dev *indio_dev,
					const struct iio_chan_spec *chan)
{
	struct milbeaut_timer64 *priv = iio_priv(indio_dev);

	return priv->exttrg_edge;
}

static int milbeaut_timer64_set_exttrg_edge(struct iio_dev *indio_dev,
					const struct iio_chan_spec *chan,
					unsigned int type)
{
	struct milbeaut_timer64 *priv = iio_priv(indio_dev);

	priv->exttrg_edge = type;

	return 0;
}

static const struct iio_enum milbeaut_timer64_exttrg_edge_en = {
	.items = milbeaut_timer64_exttrg_edge,
	.num_items = ARRAY_SIZE(milbeaut_timer64_exttrg_edge),
	.get = milbeaut_timer64_get_exttrg_edge,
	.set = milbeaut_timer64_set_exttrg_edge,
};

static ssize_t milbeaut_timer64_get_sensorno(struct iio_dev *indio_dev,
					  uintptr_t private,
					  const struct iio_chan_spec *chan,
					  char *buf)
{
	struct milbeaut_timer64 *priv = iio_priv(indio_dev);

	return snprintf(buf, PAGE_SIZE, "%u\n", priv->sensorno);
}

static ssize_t milbeaut_timer64_set_sensorno(struct iio_dev *indio_dev,
					  uintptr_t private,
					  const struct iio_chan_spec *chan,
					  const char *buf, size_t len)
{
	struct milbeaut_timer64 *priv = iio_priv(indio_dev);
	int ret;
	u32 no;

	ret = kstrtouint(buf, 0, &no);
	if (ret)
		return ret;

	if (no > MLB_TIMER64_MAX_SENSORNO)
		return -EINVAL;

	priv->sensorno = no;

	return len;
}

#define IIO_TIMER64_FSTMP_DESC_RL(__name)			\
static ssize_t milbeaut_timer64_##__name##_readL(		\
			struct iio_dev *indio_dev,		\
			uintptr_t private,			\
			const struct iio_chan_spec *chan,	\
			char *buf)				\
{								\
	struct milbeaut_timer64 *priv = iio_priv(indio_dev);	\
	u32 dat;						\
	int ret, ofs;						\
								\
	if (milbeaut_timer64_is_enabled(priv) == 0)     {       \
		dev_err(priv->dev, "device isn't enabled\n");   \
		return -EIO;                                    \
	}							\
	ofs = MLB_TIMER64_FSSTMP_TOP +				\
		FRAME_BANK_SIZE * (priv->frameedge) +		\
		SENSOR_BANK_SIZE * (priv->sensorno) + REG_##__name;\
	ret = regmap_read(priv->regmap, ofs, &dat);		\
	if (ret) {						\
		dev_err(priv->dev, "Failed reg read(%d)\n", ret);\
		return ret;					\
	}							\
DBG("ofs=0x%08x, dat=0x%08x\n", (unsigned int)ofs, dat);	\
	return snprintf(buf, PAGE_SIZE, "%u\n", dat & 0xFFFF);	\
}

#define IIO_TIMER64_FSTMP_DESC_RH(__name)			\
static ssize_t milbeaut_timer64_##__name##_readH(		\
			struct iio_dev *indio_dev,		\
			uintptr_t private,			\
			const struct iio_chan_spec *chan,	\
			char *buf)				\
{								\
	struct milbeaut_timer64 *priv = iio_priv(indio_dev);	\
	u32 dat;						\
								\
	int ret, ofs;						\
	if (milbeaut_timer64_is_enabled(priv) == 0)     {       \
		dev_err(priv->dev, "device isn't enabled\n");   \
		return -EIO;                                    \
	}							\
	ofs = MLB_TIMER64_FSSTMP_TOP +				\
		priv->frameedge * FRAME_BANK_SIZE +		\
		priv->sensorno * SENSOR_BANK_SIZE + REG_##__name;\
	ret = regmap_read(priv->regmap, ofs, &dat);		\
	if (ret) {						\
		dev_err(priv->dev, "Failed reg read(%d)\n", ret);\
		return ret;					\
	}							\
DBG("ofs=0x%08x, dat=0x%08x\n", (unsigned int)ofs, dat);	\
	return snprintf(buf, PAGE_SIZE, "%u\n", (dat >> 16) & 0xFFFF);\
}

IIO_TIMER64_FSTMP_DESC_RL(STMP0L);
IIO_TIMER64_FSTMP_DESC_RH(STMP0L);
IIO_TIMER64_FSTMP_DESC_RL(STMP0H);
IIO_TIMER64_FSTMP_DESC_RH(STMP0H);
IIO_TIMER64_FSTMP_DESC_RL(STMP1L);
IIO_TIMER64_FSTMP_DESC_RH(STMP1L);
IIO_TIMER64_FSTMP_DESC_RL(STMP1H);
IIO_TIMER64_FSTMP_DESC_RH(STMP1H);
IIO_TIMER64_FSTMP_DESC_RL(STMP2L);
IIO_TIMER64_FSTMP_DESC_RH(STMP2L);
IIO_TIMER64_FSTMP_DESC_RL(STMP2H);
IIO_TIMER64_FSTMP_DESC_RH(STMP2H);

static ssize_t milbeaut_timer64_TMR64L_readL(
			struct iio_dev *indio_dev,
			uintptr_t private,
			const struct iio_chan_spec *chan,
			char *buf)
{
	struct milbeaut_timer64 *priv = iio_priv(indio_dev);
	u32 dat;
	int ret;

	if (milbeaut_timer64_is_enabled(priv) == 0) {
		dev_err(priv->dev, "device isn't enabled\n");
		return -EIO;
	}
	ret = regmap_update_bits(priv->regmap, MLB_TIMER64_CSR2,
		MLB_TIMER64_CSR2_CVT, MLB_TIMER64_CSR2_CVT);
	if (ret != 0) {
		dev_err(priv->dev,
			"Failed to update CSR2 reg's CVT bit(%d)\n", ret);
		return ret;
	}
	ret = regmap_read(priv->regmap, MLB_TIMER64_TMR64L, &dat);
	if (ret) {
		dev_err(priv->dev, "Failed reg read(%d)\n", ret);
		return ret;
	}
	return snprintf(buf, PAGE_SIZE, "%u\n", dat & 0xFFFF);
}

static ssize_t milbeaut_timer64_TMR64H_readL(
			struct iio_dev *indio_dev,
			uintptr_t private,
			const struct iio_chan_spec *chan,
			char *buf)
{
	struct milbeaut_timer64 *priv = iio_priv(indio_dev);
	u32 dat;
	int ret;

	if (milbeaut_timer64_is_enabled(priv) == 0) {
		dev_err(priv->dev, "device isn't enabled\n");
		return -EIO;
	}
	ret = regmap_read(priv->regmap, MLB_TIMER64_TMR64H, &dat);
	if (ret) {
		dev_err(priv->dev, "Failed reg read(%d)\n", ret);
		return ret;
	}
	return snprintf(buf, PAGE_SIZE, "%u\n", dat & 0xFFFF);
}

#define IIO_TIMER64_STMP_DESC_RH(__name)				\
static ssize_t milbeaut_timer64_##__name##_readH(		\
			struct iio_dev *indio_dev,		\
			uintptr_t private,			\
			const struct iio_chan_spec *chan,	\
			char *buf)				\
{								\
	struct milbeaut_timer64 *priv = iio_priv(indio_dev);	\
	u32 dat;						\
	int ret;						\
	if (milbeaut_timer64_is_enabled(priv) == 0)     {       \
		dev_err(priv->dev, "device isn't enabled\n");   \
		return -EIO;                                    \
	}							\
	ret = regmap_read(priv->regmap, MLB_TIMER64_##__name, &dat);\
	if (ret) {						\
		dev_err(priv->dev, "Failed reg read(%d)\n", ret);\
		return ret;					\
	}							\
	return snprintf(buf, PAGE_SIZE, "%u\n", (dat >> 16) & 0xFFFF);\
}

IIO_TIMER64_STMP_DESC_RH(TMR64L);
IIO_TIMER64_STMP_DESC_RH(TMR64H);

static const struct iio_chan_spec_ext_info milbeaut_timer64_ext_info[] = {
	{
		.name = "SensorNo",
		.shared = IIO_SEPARATE,
		.read = milbeaut_timer64_get_sensorno,
		.write = milbeaut_timer64_set_sensorno,
	},
	IIO_ENUM("FrameEdge", IIO_SEPARATE, &milbeaut_timer64_frameedge_en),
	IIO_ENUM("ExtTrigEdge", IIO_SEPARATE, &milbeaut_timer64_exttrg_edge_en),
//	IIO_ENUM_AVAILABLE("FrameEdge", &milbeaut_timer64_frameedge_en),
	{
		.name = "STMP0L_L",
		.shared = IIO_SEPARATE,
		.read = milbeaut_timer64_STMP0L_readL,
	},
	{
		.name = "STMP0L_H",
		.shared = IIO_SEPARATE,
		.read = milbeaut_timer64_STMP0L_readH,
	},
	{
		.name = "STMP0H_L",
		.shared = IIO_SEPARATE,
		.read = milbeaut_timer64_STMP0H_readL,
	},
	{
		.name = "STMP0H_H",
		.shared = IIO_SEPARATE,
		.read = milbeaut_timer64_STMP0H_readH,
	},
	{
		.name = "STMP1L_L",
		.shared = IIO_SEPARATE,
		.read = milbeaut_timer64_STMP1L_readL,
	},
	{
		.name = "STMP1L_H",
		.shared = IIO_SEPARATE,
		.read = milbeaut_timer64_STMP1L_readH,
	},
	{
		.name = "STMP1H_L",
		.shared = IIO_SEPARATE,
		.read = milbeaut_timer64_STMP1H_readL,
	},
	{
		.name = "STMP1H_H",
		.shared = IIO_SEPARATE,
		.read = milbeaut_timer64_STMP1H_readH,
	},
	{
		.name = "STMP2L_L",
		.shared = IIO_SEPARATE,
		.read = milbeaut_timer64_STMP2L_readL,
	},
	{
		.name = "STMP2L_H",
		.shared = IIO_SEPARATE,
		.read = milbeaut_timer64_STMP2L_readH,
	},
	{
		.name = "STMP2H_L",
		.shared = IIO_SEPARATE,
		.read = milbeaut_timer64_STMP2H_readL,
	},
	{
		.name = "STMP2H_H",
		.shared = IIO_SEPARATE,
		.read = milbeaut_timer64_STMP2H_readH,
	},
	{
		.name = "TMR64L_L",
		.shared = IIO_SEPARATE,
		.read = milbeaut_timer64_TMR64L_readL,
	},
	{
		.name = "TMR64L_H",
		.shared = IIO_SEPARATE,
		.read = milbeaut_timer64_TMR64L_readH,
	},
	{
		.name = "TMR64H_L",
		.shared = IIO_SEPARATE,
		.read = milbeaut_timer64_TMR64H_readL,
	},
	{
		.name = "TMR64H_H",
		.shared = IIO_SEPARATE,
		.read = milbeaut_timer64_TMR64H_readH,
	},
	{}
};

static const struct iio_chan_spec milbeaut_timer64_channels = {
	.type = IIO_COUNT,
	.channel = 0,
	.scan_index = 0,
	.scan_type = {
		.sign = 'u',
		.realbits = 64,
		.storagebits = 64,
	},
	.info_mask_separate = BIT(IIO_CHAN_INFO_RAW) |
			      BIT(IIO_CHAN_INFO_ENABLE) |
			      BIT(IIO_CHAN_INFO_SCALE) |
			      BIT(IIO_CHAN_INFO_OFFSET) |
			      BIT(IIO_CHAN_INFO_FREQUENCY),
	.ext_info = milbeaut_timer64_ext_info,
	.indexed = 1,
};

static const unsigned long miltimer64_scan_mask[] = { 0x1, 0, };

static int milbeaut_timer64_probe(struct platform_device *pdev)
{
	struct milbeaut_timer64 *priv;
	struct iio_dev *indio_dev;
	struct resource *res;
	int ret, clk_div;
	u32 dat;
	u64 clk_rate;

	indio_dev = devm_iio_device_alloc(&pdev->dev, sizeof(*priv));
	if (!indio_dev)
		return -ENOMEM;

	priv = iio_priv(indio_dev);
	priv->dev = &pdev->dev;

	res = platform_get_resource(pdev, IORESOURCE_MEM, 0);
	priv->basephy = res->start;
	priv->baseadd = devm_ioremap_resource(&pdev->dev, res);
	if (IS_ERR(priv->baseadd))
		return PTR_ERR(priv->baseadd);

	priv->regmap = devm_regmap_init_mmio_clk(&pdev->dev, "base",
			priv->baseadd, &milbeaut_timer64_regmap_cfg);
	if (IS_ERR(priv->regmap))
		return PTR_ERR(priv->regmap);

	priv->clk = devm_clk_get(&pdev->dev, NULL);
	if (IS_ERR(priv->clk))
		return PTR_ERR(priv->clk);

	ret = milbeaut_timer64_dma_init(indio_dev);
	if (ret) {
		pr_err("%s: dma init error %d\n", __func__, ret);
		return ret;
	}

	ret = clk_prepare_enable(priv->clk);
	if (ret)
		return ret;

	clk_rate = clk_get_rate(priv->clk);
	ret = regmap_read(priv->regmap, MLB_TIMER64_CSR1, &dat);
	if (ret)
		goto err;
	clk_div = (dat & MLB_TIMER64_CSR1_CSL_MSK) >> MLB_TIMER64_CSR1_CSL_SFT;
	clk_rate >>= 2 * clk_div + 1;
	priv->clk_rate = clk_rate;
	priv->exttrg_edge = 0;

	indio_dev->modes = INDIO_BUFFER_HARDWARE;
	indio_dev->name = dev_name(&pdev->dev);
	indio_dev->dev.parent = &pdev->dev;
	indio_dev->dev.of_node = pdev->dev.of_node;
	indio_dev->info = &milbeaut_timer64_iio_info;
	indio_dev->channels = &milbeaut_timer64_channels;
	indio_dev->num_channels = 1;
	indio_dev->available_scan_masks = miltimer64_scan_mask;

	platform_set_drvdata(pdev, indio_dev);

	return devm_iio_device_register(&pdev->dev, indio_dev);
err:
	clk_disable_unprepare(priv->clk);
	return ret;
}

static int milbeaut_timer64_remove(struct platform_device *pdev)
{
	struct iio_dev *indio_dev = platform_get_drvdata(pdev);
	struct milbeaut_timer64 *priv = iio_priv(indio_dev);

	milbeaut_timer64_setup(priv, 0);

	iio_dmaengine_buffer_free(indio_dev->buffer);

	clk_disable_unprepare(priv->clk);

	return 0;
}

static const struct of_device_id milbeaut_timer64_of_match[] = {
	{ .compatible = "socionext,milbeaut-timer64", },
	{},
};
MODULE_DEVICE_TABLE(of, milbeaut_timer64_of_match);

static struct platform_driver milbeaut_timer64_driver = {
	.driver = {
		.name = "milbeaut-timer64",
		.of_match_table = milbeaut_timer64_of_match,
	},
	.probe = milbeaut_timer64_probe,
	.remove = milbeaut_timer64_remove,
};
module_platform_driver(milbeaut_timer64_driver);

MODULE_AUTHOR("Takao Orito <<REDACTED_EMAIL>>");
MODULE_DESCRIPTION("Milbeaut Timer64");
MODULE_ALIAS("platform:milbeaut_timer64");
MODULE_LICENSE("GPL v2");

