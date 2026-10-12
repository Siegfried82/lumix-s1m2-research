// SPDX-License-Identifier: GPL-2.0
/*
 * Milbeaut Updown counter parent driver
 * Copyright (C) 2019 SOCIONEXT All Rights Reserved
 */

#include <linux/mfd/milbeaut-updown.h>
#include <linux/module.h>
#include <linux/of_platform.h>

#define MLB_UPDOWN_MAX_REGISTER	0x1f

static const struct regmap_config milbeaut_updown_regmap_cfg = {
	.reg_bits = 32,
	.val_bits = 32,
	.reg_stride = sizeof(u32),
	.max_register = MLB_UPDOWN_MAX_REGISTER,
};

static int milbeaut_updown_probe(struct platform_device *pdev)
{
	struct device *dev = &pdev->dev;
	struct milbeaut_updown *ddata;
	struct resource *res;
	void __iomem *mmio;

	ddata = devm_kzalloc(dev, sizeof(*ddata), GFP_KERNEL);
	if (!ddata) {
		return -ENOMEM;
	}

	res = platform_get_resource(pdev, IORESOURCE_MEM, 0);
	mmio = devm_ioremap_resource(dev, res);
	if (IS_ERR(mmio)) {
		return PTR_ERR(mmio);
	}

	ddata->regmap = devm_regmap_init_mmio_clk(dev, "mux", mmio,
						  &milbeaut_updown_regmap_cfg);
	if (IS_ERR(ddata->regmap)) {
		return PTR_ERR(ddata->regmap);
	}

	ddata->clk = devm_clk_get(dev, NULL);
	if (IS_ERR(ddata->clk)) {
		return PTR_ERR(ddata->clk);
	}

	platform_set_drvdata(pdev, ddata);

	return devm_of_platform_populate(&pdev->dev);
}

static const struct of_device_id milbeaut_updown_of_match[] = {
	{ .compatible = "socionext,milbeaut-updown", },
	{},
};
MODULE_DEVICE_TABLE(of, milbeaut_updown_of_match);

static struct platform_driver milbeaut_updown_driver = {
	.probe = milbeaut_updown_probe,
	.driver = {
		.name = "milbeaut-updown",
		.of_match_table = milbeaut_updown_of_match,
	},
};
module_platform_driver(milbeaut_updown_driver);

MODULE_AUTHOR("SOCIONEXT");
MODULE_DESCRIPTION("Milbeaut Updown");
MODULE_ALIAS("platform:milbeaut_updown");
MODULE_LICENSE("GPL v2");
