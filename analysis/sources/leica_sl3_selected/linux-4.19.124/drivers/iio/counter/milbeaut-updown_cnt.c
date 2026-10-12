// SPDX-License-Identifier: GPL-2.0
/*
 * Milbeaut Updown counter driver
 *
 * Copyright (C) 2019 Socionext Inc.
 */

#include <linux/bitfield.h>
#include <linux/clk.h>
#include <linux/iio/events.h>
#include <linux/iio/iio.h>
#include <linux/interrupt.h>
#include <linux/module.h>
#include <linux/platform_device.h>
#include <linux/regmap.h>

#include "milbeaut-updown.h"

#define MILBEAUT_UPDOWN_IRQ_NAME		"milbeaut_updown_event"
#define MILBEAUT_UPDOWN_MAX_REGISTER	0x1f

static const struct regmap_config milbeaut_updown_regmap_cfg = {
	.reg_bits = 32,
	.val_bits = 32,
	.reg_stride = sizeof(u32),
	.max_register = MILBEAUT_UPDOWN_MAX_REGISTER,
};
struct milbeaut_updown_cnt {
	struct device *dev;
	struct regmap *regmap;
	struct clk *clk;
	u32 preset;
	u32 polarity;
	u32 quadrature_mode;
};

static int milbeaut_updown_is_enabled(struct milbeaut_updown_cnt *priv)
{
	u32 val;
	int ret;

	ret = regmap_read(priv->regmap, MLB_UPDOWN_CSR, &val);
	if (ret)
		return ret;

	return FIELD_GET(MLB_UPDOWN_CSTR, val);
}

static int milbeaut_updown_setup(struct milbeaut_updown_cnt *priv,
									int val)
{
	int ret;

	if (val) {
		ret = regmap_update_bits(priv->regmap, MLB_UPDOWN_CCR,
				MLB_UPDOWN_CMS | MLB_UPDOWN_RLDE,
				FIELD_PREP(MLB_UPDOWN_CMS, priv->quadrature_mode) |
				MLB_UPDOWN_RLDE);
		if (ret)
			return ret;

		if (priv->quadrature_mode == MLB_UPDOWN_MODE) {
			ret = regmap_update_bits(priv->regmap, MLB_UPDOWN_CCR,
					MLB_UPDOWN_CES, MLB_UPDOWN_RISING_EDGE);
			if (ret)
				return ret;
		}

		ret = regmap_write(priv->regmap, MLB_UPDOWN_RCR, priv->preset);
		if (ret)
			return ret;

		/* interrupt */
		ret = regmap_update_bits(priv->regmap, MLB_UPDOWN_CSR,
						MLB_UPDOWN_UDIE, MLB_UPDOWN_UDIE);
		if (ret)
			return ret;

		ret = regmap_update_bits(priv->regmap, MLB_UPDOWN_CCR,
			MLB_UPDOWN_CTUT | MLB_UPDOWN_FIXED,
			MLB_UPDOWN_CTUT | MLB_UPDOWN_FIXED);
		if (ret)
			return ret;

		val = MLB_UPDOWN_CSTR;
	}

	return regmap_update_bits(priv->regmap, MLB_UPDOWN_CSR,
								MLB_UPDOWN_CSTR, val);
}

static int milbeaut_updown_write_raw(struct iio_dev *indio_dev,
				 struct iio_chan_spec const *chan,
				 int val, int val2, long mask)
{
	struct milbeaut_updown_cnt *priv = iio_priv(indio_dev);
	int ret;

	switch (mask) {
	case IIO_CHAN_INFO_ENABLE:
		if (val < 0 || val > 1)
			return -EINVAL;

		ret = milbeaut_updown_is_enabled(priv);
		if (val && ret)
			return -EBUSY;

		ret = milbeaut_updown_setup(priv, val);

		break;

	default:
		return -EINVAL;
	}

	return ret;
}

static int milbeaut_updown_read_raw(struct iio_dev *indio_dev,
				struct iio_chan_spec const *chan,
				int *val, int *val2, long mask)
{
	struct milbeaut_updown_cnt *priv = iio_priv(indio_dev);
	u32 dat;
	int ret;

	switch (mask) {
	case IIO_CHAN_INFO_RAW:
		ret = regmap_read(priv->regmap, MLB_UPDOWN_UDCR, &dat);
		if (ret)
			return ret;
		*val = dat;
		return IIO_VAL_INT;

	case IIO_CHAN_INFO_ENABLE:
		ret = milbeaut_updown_is_enabled(priv);
		if (ret < 0)
			return ret;
		*val = ret;
		return IIO_VAL_INT;

	default:
		return -EINVAL;
	}
}

static const struct iio_info milbeaut_updown_cnt_iio_info = {
	.read_raw = milbeaut_updown_read_raw,
	.write_raw = milbeaut_updown_write_raw,
};

static const char *const milbeaut_updown_quadrature_modes[] = {
	"non-quadrature",
	"quadrature",
};

static int milbeaut_updown_get_quadrature_mode(struct iio_dev *indio_dev,
					   const struct iio_chan_spec *chan)
{
	struct milbeaut_updown_cnt *priv = iio_priv(indio_dev);

	return priv->quadrature_mode;
}

static int milbeaut_updown_set_quadrature_mode(struct iio_dev *indio_dev,
					   const struct iio_chan_spec *chan,
					   unsigned int type)
{
	struct milbeaut_updown_cnt *priv = iio_priv(indio_dev);

	if (milbeaut_updown_is_enabled(priv))
		return -EBUSY;

	priv->quadrature_mode = type;

	return 0;
}

static const struct iio_enum milbeaut_updown_quadrature_mode_en = {
	.items = milbeaut_updown_quadrature_modes,
	.num_items = ARRAY_SIZE(milbeaut_updown_quadrature_modes),
	.get = milbeaut_updown_get_quadrature_mode,
	.set = milbeaut_updown_set_quadrature_mode,
};

static const char * const milbeaut_updown_cnt_polarity[] = {
	"rising-edge", "falling-edge", "both-edges",
};

static int milbeaut_updown_cnt_get_polarity(struct iio_dev *indio_dev,
					const struct iio_chan_spec *chan)
{
	struct milbeaut_updown_cnt *priv = iio_priv(indio_dev);

	return priv->polarity;
}

static int milbeaut_updown_cnt_set_polarity(struct iio_dev *indio_dev,
					const struct iio_chan_spec *chan,
					unsigned int type)
{
	struct milbeaut_updown_cnt *priv = iio_priv(indio_dev);

	if (milbeaut_updown_is_enabled(priv))
		return -EBUSY;

	priv->polarity = type;

	return 0;
}

static const struct iio_enum milbeaut_updown_cnt_polarity_en = {
	.items = milbeaut_updown_cnt_polarity,
	.num_items = ARRAY_SIZE(milbeaut_updown_cnt_polarity),
	.get = milbeaut_updown_cnt_get_polarity,
	.set = milbeaut_updown_cnt_set_polarity,
};

static ssize_t milbeaut_updown_cnt_get_preset(struct iio_dev *indio_dev,
					  uintptr_t private,
					  const struct iio_chan_spec *chan,
					  char *buf)
{
	struct milbeaut_updown_cnt *priv = iio_priv(indio_dev);

	return snprintf(buf, PAGE_SIZE, "%u\n", priv->preset);
}

static ssize_t milbeaut_updown_cnt_set_preset(struct iio_dev *indio_dev,
					  uintptr_t private,
					  const struct iio_chan_spec *chan,
					  const char *buf, size_t len)
{
	struct milbeaut_updown_cnt *priv = iio_priv(indio_dev);
	u32 check_preset;
	int ret;

	if (milbeaut_updown_is_enabled(priv))
		return -EBUSY;

	ret = kstrtouint(buf, 0, &check_preset);
	if (ret)
		return ret;
	if (check_preset > MLB_UPDOWN_MAX_COUNT)
		return -EINVAL;
	priv->preset = check_preset;

	return len;
}

static const struct iio_chan_spec_ext_info milbeaut_updown_cnt_ext_info[] = {
	{
		.name = "preset",
		.shared = IIO_SEPARATE,
		.read = milbeaut_updown_cnt_get_preset,
		.write = milbeaut_updown_cnt_set_preset,
	},
	IIO_ENUM("polarity", IIO_SEPARATE, &milbeaut_updown_cnt_polarity_en),
	IIO_ENUM_AVAILABLE("polarity", &milbeaut_updown_cnt_polarity_en),
	{}
};

static const struct iio_event_spec milbeaut_updown_cnt_event = {
	.type = IIO_EV_TYPE_ROC,
	.dir = IIO_EV_DIR_RISING,
	.mask_separate = BIT(IIO_EV_INFO_ENABLE),
	.mask_shared_by_type = BIT(IIO_EV_INFO_VALUE),
};

static const struct iio_chan_spec milbeaut_updown_cnt_channels = {
	.type = IIO_COUNT,
	.channel = 0,
	.info_mask_separate = BIT(IIO_CHAN_INFO_RAW) |
			      BIT(IIO_CHAN_INFO_ENABLE) |
			      BIT(IIO_CHAN_INFO_SCALE),
	.ext_info = milbeaut_updown_cnt_ext_info,
	.indexed = 1,
	.event_spec = &milbeaut_updown_cnt_event,
	.num_event_specs = 1,
};

static irqreturn_t milbeaut_updown_event_handler(int irq, void *private)
{
	struct iio_dev *indio_dev = private;
	struct milbeaut_updown_cnt *priv;
	int ret;

	priv = iio_priv(indio_dev);

	ret = regmap_update_bits(priv->regmap, MLB_UPDOWN_CSR,
			MLB_UPDOWN_CMPF | MLB_UPDOWN_OVFF | MLB_UPDOWN_UDFF,
			0);
	WARN_ON_ONCE(ret < 0);

	iio_push_event(indio_dev,
			       IIO_MOD_EVENT_CODE(IIO_INCLI, 0, 1,
						  IIO_EV_TYPE_ROC, IIO_EV_DIR_RISING),
			       iio_get_time_ns(indio_dev));

	return IRQ_HANDLED;
}

static int milbeaut_updown_cnt_probe(struct platform_device *pdev)
{
	struct milbeaut_updown_cnt *priv;
	struct iio_dev *indio_dev;
	struct resource *res;
	void __iomem *mmio;
	int ret;
	int irq;

	indio_dev = devm_iio_device_alloc(&pdev->dev, sizeof(*priv));
	if (!indio_dev)
		return -ENOMEM;

	priv = iio_priv(indio_dev);
	priv->dev = &pdev->dev;

	res = platform_get_resource(pdev, IORESOURCE_MEM, 0);
	mmio = devm_ioremap_resource(&pdev->dev, res);
	if (IS_ERR(mmio))
		return PTR_ERR(mmio);

	priv->regmap = devm_regmap_init_mmio_clk(&pdev->dev, "mux", mmio,
							  &milbeaut_updown_regmap_cfg);
	if (IS_ERR(priv->regmap))
		return PTR_ERR(priv->regmap);

	priv->clk = devm_clk_get(&pdev->dev, NULL);
	if (IS_ERR(priv->clk))
		return PTR_ERR(priv->clk);

	ret = clk_prepare_enable(priv->clk);
	if (ret) {
		pr_err("%s clk_prepare_enable error\n", __func__);
		return ret;
	}

	priv->preset = MLB_UPDOWN_MAX_COUNT;
	ret = of_property_read_u32(priv->dev->of_node,
				"cms_type", &priv->quadrature_mode);
	if (ret)
		return -ENODEV;

	indio_dev->info = &milbeaut_updown_cnt_iio_info;
	indio_dev->channels = &milbeaut_updown_cnt_channels;
	indio_dev->num_channels = 1;

	irq = platform_get_irq(pdev, 0);
	ret = devm_request_irq(&pdev->dev, irq,
			milbeaut_updown_event_handler, 0,
			MILBEAUT_UPDOWN_IRQ_NAME, indio_dev);
	if (ret < 0) {
		pr_err("%s request irq failed\n", __func__);
		return ret;
	}

	platform_set_drvdata(pdev, indio_dev);

	return devm_iio_device_register(&pdev->dev, indio_dev);
}

static int milbeaut_updown_cnt_suspend(struct device *dev)
{
	struct iio_dev *indio_dev = dev_get_drvdata(dev);
	struct milbeaut_updown_cnt *priv;

	priv = iio_priv(indio_dev);
	clk_disable_unprepare(priv->clk);

	return 0;
}

static int milbeaut_updown_cnt_resume(struct device *dev)
{
	struct iio_dev *indio_dev = dev_get_drvdata(dev);
	struct milbeaut_updown_cnt *priv;
	int ret;

	priv = iio_priv(indio_dev);
	ret = clk_prepare_enable(priv->clk);

	return ret;
}

static int milbeaut_updown_cnt_remove(struct platform_device *pdev)
{
	struct iio_dev *indio_dev = platform_get_drvdata(pdev);
	struct milbeaut_updown_cnt *priv = iio_priv(indio_dev);

	clk_disable_unprepare(priv->clk);

	return 0;
}

static const struct dev_pm_ops milbeaut_updown_cnt_pm = {
	SET_SYSTEM_SLEEP_PM_OPS(milbeaut_updown_cnt_suspend, milbeaut_updown_cnt_resume)
};

static const struct of_device_id milbeaut_updown_cnt_of_match[] = {
	{ .compatible = "socionext,milbeaut-updown-counter", },
	{},
};
MODULE_DEVICE_TABLE(of, milbeaut_updown_cnt_of_match);

static struct platform_driver milbeaut_updown_cnt_driver = {
	.probe = milbeaut_updown_cnt_probe,
	.remove = milbeaut_updown_cnt_remove,
	.driver = {
		.name = "milbeaut-updown-counter",
		.of_match_table = milbeaut_updown_cnt_of_match,
		.pm = &milbeaut_updown_cnt_pm,
	},
};
module_platform_driver(milbeaut_updown_cnt_driver);

MODULE_AUTHOR("Shinji Kanematsu <<REDACTED_EMAIL>>");
MODULE_DESCRIPTION("Milbeaut Updown counter");
MODULE_ALIAS("platform:milbeaut_updown_counter");
MODULE_LICENSE("GPL v2");
