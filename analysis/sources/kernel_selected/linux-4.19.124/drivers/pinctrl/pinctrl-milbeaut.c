// SPDX-License-Identifier: GPL-2.0
/*
 * Copyright (C) 2020 Panasonic Corporation
 * Copyright (C) 2018 Socionext Inc.
 * Copyright (C) 2015 Linaro Ltd.
 * Author: Jassi Brar <<REDACTED_EMAIL>>
 */

#include <linux/gpio.h>
#include <linux/interrupt.h>
#include <linux/io.h>
#include <linux/of.h>
#include <linux/of_device.h>
#include <linux/of_irq.h>
#include <linux/pinctrl/machine.h>
#include <linux/pinctrl/pinctrl.h>
#include <linux/pinctrl/pinmux.h>
#include <linux/pinctrl/pinconf.h>
#include <linux/pinctrl/pinconf-generic.h>
#include <linux/platform_device.h>
#include <linux/spinlock.h>

#include "pinctrl-utils.h"

#define SUPPORT_DSC 1  //Panasonic Modify

#define EIMASK		0x0
#define EISRCSEL	0x4
#define EIREQSTA	0x8
#define EIRAWREQSTA	0xc
#define EIREQCLR	0x10
#define EILVL		0x14
#define EIEDG		0x18
#define EISIR		0x1c

#define PDR		0x0
#define PDR_S		0x50
#define PDR_C		0xa0
#define DDR		0x100
#define EPCR		0x200
#define PUDER		0x300
#define PUDCR		0x400

#define WE_OFFSET	16

#define M10V_BANKS	26
#define M10V_PINS_PER_BANK	8
#define M10V_TOTAL_PINS	(M10V_BANKS * M10V_PINS_PER_BANK)

#define M20V_BANKS	22
#define M20V_PINS_PER_BANK	16
#define M20V_TOTAL_PINS	(M20V_BANKS * M20V_PINS_PER_BANK)

#define M20V_PMC_BANKS	4
#define M20V_PMC_PINS_PER_BANK	16
#define M20V_PMC_TOTAL_PINS	(M20V_PMC_BANKS * M20V_PMC_PINS_PER_BANK)

#define PINS_PER_REG	16

#define MAX_IN_M20	(M20V_PMC_TOTAL_PINS > M20V_TOTAL_PINS \
					? M20V_PMC_TOTAL_PINS : M20V_TOTAL_PINS)
#define MAX_IN_M20_M10	(MAX_IN_M20 > M10V_TOTAL_PINS \
					? MAX_IN_M20 : M10V_TOTAL_PINS)
#define MAX_TOTAL_PINS	(MAX_IN_M20_M10)

#define EXIU_PINS	16

#define FPINT_INVALID	-1

struct pin_irq_map {
	int pin; /* offset of pin in the managed range */
	int irq; /* virq of the pin as fpint */
	int type;
	char irqname[8];
};

enum milbeaut_variant {
	VAR_M10V,
	VAR_M20V,
	VAR_M20V_PMC,
};

#ifdef CONFIG_PM_SLEEP
struct milbeaut_saveregs {
	unsigned int ddr[MAX_TOTAL_PINS / PINS_PER_REG];
	unsigned int pdr[MAX_TOTAL_PINS / PINS_PER_REG];
	unsigned int epcr[MAX_TOTAL_PINS / PINS_PER_REG];
	unsigned int puder[MAX_TOTAL_PINS / PINS_PER_REG];
	unsigned int pudcr[MAX_TOTAL_PINS / PINS_PER_REG];
	unsigned int eint[4];
};
#endif

struct milbeaut_pinctrl {
	void __iomem *base;
	void __iomem *exiu;
	struct gpio_chip gc;
	struct pinctrl_desc pd;
	char pin_names[4 * MAX_TOTAL_PINS];
	struct pinctrl_pin_desc pins[MAX_TOTAL_PINS];
	unsigned int gpins[MAX_TOTAL_PINS][1]; /* 1 pin-per-group */
	struct irq_domain *irqdom;
	spinlock_t irq_lock, lock;
	int extints;
	u32 *blacklist;
	unsigned int tbanks;
	enum milbeaut_variant variant;
#ifdef CONFIG_PM_SLEEP
	struct milbeaut_saveregs *save;
#endif
	const struct milbeaut_function *milbeaut_functions;
	struct pin_irq_map fpint[]; /* keep at end */
};

struct milbeaut_function {
	const char		*name;
	const char * const	*groups;
	unsigned int		ngroups;
};

struct mlb_pinctrl_param {
	const struct milbeaut_function *milbeaut_functions;
	const int *exiu_pin_list;
	const char *bank_name;
	const char **gpio_grps;
	int tbanks;
	int gpio_ofs;
	int tpins;
	int pins_per_bank;
	enum milbeaut_variant variant;
};

static const char m10v_bank_name[] = {'0', '1', '2', '3', '4', '5', '6', '7',
				 '8', '9', 'A', 'B', 'C', 'D', 'E', 'F',
				 'G', 'H', 'W', 'J', 'K', 'L', 'M', 'N',
				 'Y', 'P'};
static const char * const usio0_m10v_grps[] = {"PE2", "PE3", "PF0"};
static const char * const usio1_m10v_grps[] = {"PE4", "PE5", "PF1"};
static const char * const usio2_m10v_grps[] = {"PE0", "PE1"};
static const char * const usio3_m10v_grps[] = {"PY0", "PY1", "PY2"};
static const char * const usio4_m10v_grps[] = {"PP0", "PP1", "PP2"};
static const char * const usio5_m10v_grps[] = {"PM0", "PM1", "PM3"};
static const char * const usio6_m10v_grps[] = {"PN0", "PN1", "PN3"};
static const char * const usio7_m10v_grps[] = {"PY3", "PY5", "PY6"};
static const char *gpio_m10v_grps[M10V_TOTAL_PINS];

static const struct milbeaut_function m10v_functions[] = {
#define FUNC_M10V(fname)					\
	{						\
		.name = #fname,				\
		.groups = fname##_m10v_grps,		\
		.ngroups = ARRAY_SIZE(fname##_m10v_grps),	\
	}
	FUNC_M10V(gpio), /* GPIO always at index 0 */
	FUNC_M10V(usio0),
	FUNC_M10V(usio1),
	FUNC_M10V(usio2),
	FUNC_M10V(usio3),
	FUNC_M10V(usio4),
	FUNC_M10V(usio5),
	FUNC_M10V(usio6),
	FUNC_M10V(usio7),
};

static const int m10v_exiu_pin_list[] = {48, 49, 50, 51, 52, 53, 54, 55,
				56, 57, 58, 59, 60, 61, 62, 63};

static const char m20v_bank_name[] = {'4', '5', '6', '7', '8', '9', 'A', 'B',
				      'C', 'D', 'E', 'F', 'G', 'H', 'J', 'K',
				      'L', 'M', 'N', 'P', 'R', 'T'};
static const char *gpio_m20v_grps[M20V_TOTAL_PINS];

static const struct milbeaut_function m20v_functions[] = {
#define FUNC_M20V(fname)					\
	{						\
		.name = #fname,				\
		.groups = fname##_m20v_grps,		\
		.ngroups = ARRAY_SIZE(fname##_m20v_grps),	\
	}
	FUNC_M20V(gpio), /* GPIO always at index 0 */
};

static const int m20v_exiu_pin_list[] = {337, 338, 339, 340, /* for eintxx_3 */
					 341, 342, 343, 344,
					 345, 346, 347, 348,
					 349, 350, 351, 320
};

static const char m20v_pmc_bank_name[] = {'0', '1', '2', '3'};
static const char *gpio_m20v_pmc_grps[M20V_PMC_TOTAL_PINS];

static const struct milbeaut_function m20v_pmc_functions[] = {
#define FUNC_M20V_PMC(fname)					\
	{						\
		.name = #fname,				\
		.groups = fname##_m20v_pmc_grps,		\
		.ngroups = ARRAY_SIZE(fname##_m20v_pmc_grps),	\
	}
	FUNC_M20V_PMC(gpio), /* GPIO always at index 0 */
};

static const int m20v_pmc_exiu_pin_list[] = { 0,  1,  2,  3, /* for eintxx_0 */
					      4,  8,  9, 10,
					     11, 12, 13, -1,
					     -1, -1, -1, -1
};

static bool milbeaut_pin_is_black(struct milbeaut_pinctrl *pctl, int pin)
{
	unsigned int reg;
	u8 shift, offset;

	reg = pin / PINS_PER_REG * 4;
	offset = pin % PINS_PER_REG;

	if (!pctl->blacklist)
		return false;

	switch (pctl->variant) {
	case VAR_M20V:
	default:
		shift = M20V_PINS_PER_BANK / 8;
		break;
	case VAR_M20V_PMC:
		shift = M20V_PMC_PINS_PER_BANK / 8;
		break;
	case VAR_M10V:
		shift = M10V_PINS_PER_BANK / 8;
		break;
	}
	if (pctl->blacklist[reg >> shift] & BIT(offset))
		return true;
	else
		return false;
}


static int milbeaut_pconf_group_set(struct pinctrl_dev *pctldev,
				 unsigned int group,
				 unsigned long *configs,
				 unsigned int num_configs)
{
	struct milbeaut_pinctrl *pctl = pinctrl_dev_get_drvdata(pctldev);
	u32 pin, val, reg, offset;
	unsigned long flags = 0;
	int i;

	pin = pctl->gpins[group][0];
	reg = pin / PINS_PER_REG * 4;
	offset = pin % PINS_PER_REG;

	if (milbeaut_pin_is_black(pctl, pin)) {
		printk(KERN_WARNING
			"You are trying to touch a pin%03d on BL\n", pin);
		WARN_ON(1);
	}

	if (pctl->variant == VAR_M10V)
		spin_lock_irqsave(&pctl->lock, flags);

	for (i = 0; i < num_configs; i++) {
		switch (pinconf_to_config_param(configs[i])) {
		case PIN_CONFIG_BIAS_PULL_UP:
			/* enable Pull-Up/Down resistance */
			if ((pctl->variant == VAR_M20V) || (pctl->variant == VAR_M20V_PMC))
				val = BIT(offset + WE_OFFSET) + BIT(offset);
			else {
				val = readl_relaxed(pctl->base + PUDER + reg);
				val |= BIT(offset);
			}
			writel_relaxed(val, pctl->base + PUDER + reg);
			/* enable Pull-Up */
			if ((pctl->variant == VAR_M20V) || (pctl->variant == VAR_M20V_PMC))
				val = BIT(offset + WE_OFFSET) + BIT(offset);
			else {
				val = readl_relaxed(pctl->base + PUDCR + reg);
				val |= BIT(offset);
			}
			writel_relaxed(val, pctl->base + PUDCR + reg);
			break;
		case PIN_CONFIG_BIAS_PULL_DOWN:
			/* enable Pull-Up/Down resistance */
			if ((pctl->variant == VAR_M20V) || (pctl->variant == VAR_M20V_PMC))
				val = BIT(offset + WE_OFFSET) + BIT(offset);
			else {
				val = readl_relaxed(pctl->base + PUDER + reg);
				val |= BIT(offset);
			}
			writel_relaxed(val, pctl->base + PUDER + reg);
			/* enable Pull-Down */
			if ((pctl->variant == VAR_M20V) || (pctl->variant == VAR_M20V_PMC))
				val = BIT(offset + WE_OFFSET);
			else {
				val = readl_relaxed(pctl->base + PUDCR + reg);
				val &= ~BIT(offset);
			}
			writel_relaxed(val, pctl->base + PUDCR + reg);
			break;
		case PIN_CONFIG_BIAS_DISABLE:
			if ((pctl->variant == VAR_M20V) || (pctl->variant == VAR_M20V_PMC))
				val = BIT(offset + WE_OFFSET);
			else {
				val = readl_relaxed(pctl->base + PUDER + reg);
				val &= ~BIT(offset);
			}
			writel_relaxed(val, pctl->base + PUDER + reg);
			break;
		default:
			break;
		}
	}

	if (pctl->variant == VAR_M10V)
		spin_unlock_irqrestore(&pctl->lock, flags);

	return 0;
}

static const struct pinconf_ops milbeaut_pconf_ops = {
	.pin_config_group_set	= milbeaut_pconf_group_set,
	.pin_config_set = milbeaut_pconf_group_set,
};

static int milbeaut_pctrl_get_groups_count(struct pinctrl_dev *pctldev)
{
	struct milbeaut_pinctrl *pctl = pinctrl_dev_get_drvdata(pctldev);

	switch (pctl->variant) {
	case VAR_M10V:
		return M10V_TOTAL_PINS;
	case VAR_M20V:
	default:
		return M20V_TOTAL_PINS;
	case VAR_M20V_PMC:
		return M20V_PMC_TOTAL_PINS;
	}
}

static const char *milbeaut_pctrl_get_group_name(struct pinctrl_dev *pctldev,
					      unsigned int pin)
{
	struct milbeaut_pinctrl *pctl = pinctrl_dev_get_drvdata(pctldev);

	return &pctl->pin_names[4 * pin];
}

static int milbeaut_pctrl_get_group_pins(struct pinctrl_dev *pctldev,
				      unsigned int group,
				      const unsigned int **pins,
				      unsigned int *num_pins)
{
	struct milbeaut_pinctrl *pctl = pinctrl_dev_get_drvdata(pctldev);

	*pins = pctl->gpins[group];
	*num_pins = 1;
	return 0;
}

static const struct pinctrl_ops milbeaut_pctrl_ops = {
	.get_groups_count	= milbeaut_pctrl_get_groups_count,
	.get_group_name		= milbeaut_pctrl_get_group_name,
	.get_group_pins		= milbeaut_pctrl_get_group_pins,
	.dt_node_to_map		= pinconf_generic_dt_node_to_map_group,
	.dt_free_map		= pinctrl_utils_free_map,
};

static int milbeaut_pmx_get_funcs_cnt(struct pinctrl_dev *pctldev)
{
	struct milbeaut_pinctrl *pctl = pinctrl_dev_get_drvdata(pctldev);

	switch (pctl->variant) {
	case VAR_M10V:
		return ARRAY_SIZE(m10v_functions);
	case VAR_M20V:
	default:
		return ARRAY_SIZE(m20v_functions);
	case VAR_M20V_PMC:
		return ARRAY_SIZE(m20v_pmc_functions);
	}
}

static const char *milbeaut_pmx_get_func_name(struct pinctrl_dev *pctldev,
					   unsigned int function)
{
	struct milbeaut_pinctrl *pctl = pinctrl_dev_get_drvdata(pctldev);

	return pctl->milbeaut_functions[function].name;
}

static int milbeaut_pmx_get_func_groups(struct pinctrl_dev *pctldev,
				     unsigned int function,
				     const char * const **groups,
				     unsigned * const num_groups)
{
	struct milbeaut_pinctrl *pctl = pinctrl_dev_get_drvdata(pctldev);

	*groups = pctl->milbeaut_functions[function].groups;
	*num_groups = pctl->milbeaut_functions[function].ngroups;
	return 0;
}

static void _set_mux(struct milbeaut_pinctrl *pctl, unsigned int pin, bool gpio)
{
	u32 val, reg, offset;
	unsigned long flags;

	reg = pin / PINS_PER_REG * 4;
	offset = pin % PINS_PER_REG;

	if (milbeaut_pin_is_black(pctl, pin)) {
		printk(KERN_WARNING
			"You are trying to touch a pin%03d on BL\n", pin);
		WARN_ON(1);
	}

	reg += EPCR;


	if ((pctl->variant == VAR_M20V) || (pctl->variant == VAR_M20V_PMC)) {
		if (gpio)
			val = BIT(offset + WE_OFFSET);
		else
			val = BIT(offset + WE_OFFSET) + BIT(offset);
		writel_relaxed(val, pctl->base + reg);
	} else {
		spin_lock_irqsave(&pctl->lock, flags);

		val = readl_relaxed(pctl->base + reg);

		if (gpio)
			val &= ~BIT(offset);
		else
			val |= BIT(offset);
		writel_relaxed(val, pctl->base + reg);

		spin_unlock_irqrestore(&pctl->lock, flags);
	}
}

static int milbeaut_pmx_set_mux(struct pinctrl_dev *pctldev,
			     unsigned int function,
			     unsigned int group)
{
	struct milbeaut_pinctrl *pctl = pinctrl_dev_get_drvdata(pctldev);
	u32 pin = pctl->gpins[group][0]; /* each group has exactly 1 pin */

	_set_mux(pctl, pin, !function);

	return 0;
}

static int _set_direction(struct milbeaut_pinctrl *pctl,
			unsigned int pin, bool input)
{
	u32 val, reg, offset;
	unsigned long flags;

	reg = pin / PINS_PER_REG * 4;
	offset = pin % PINS_PER_REG;

	if (milbeaut_pin_is_black(pctl, pin)) {
		printk(KERN_WARNING
			"You are trying to touch a pin%03d on BL\n", pin);
		WARN_ON(1);
	}

	reg += DDR;

	if ((pctl->variant == VAR_M20V) || (pctl->variant == VAR_M20V_PMC)) {
		if (input)
			val = BIT(offset + WE_OFFSET);
		else
			val = BIT(offset + WE_OFFSET) + BIT(offset);
		writel_relaxed(val, pctl->base + reg);
	} else {
		spin_lock_irqsave(&pctl->lock, flags);

		val = readl_relaxed(pctl->base + reg);

		if (input)
			val &= ~BIT(offset);
		else
			val |= BIT(offset);
		writel_relaxed(val, pctl->base + reg);

		spin_unlock_irqrestore(&pctl->lock, flags);
	}

	return 0;
}

static int
milbeaut_pmx_gpio_set_direction(struct pinctrl_dev *pctldev,
			struct pinctrl_gpio_range *range,
			unsigned int pin, bool input)
{
	struct milbeaut_pinctrl *pctl = pinctrl_dev_get_drvdata(pctldev);

	return _set_direction(pctl, pin, input);
}

static int
milbeaut_pmx_gpio_request_enable(struct pinctrl_dev *pctldev,
			    struct pinctrl_gpio_range *range,
			    unsigned int pin)
{
	struct milbeaut_pinctrl *pctl = pinctrl_dev_get_drvdata(pctldev);

	_set_mux(pctl, pin, true);
	return 0;
}

static const struct pinmux_ops milbeaut_pmx_ops = {
	.get_functions_count	= milbeaut_pmx_get_funcs_cnt,
	.get_function_name	= milbeaut_pmx_get_func_name,
	.get_function_groups	= milbeaut_pmx_get_func_groups,
	.set_mux		= milbeaut_pmx_set_mux,
	.gpio_set_direction	= milbeaut_pmx_gpio_set_direction,
	.gpio_request_enable	= milbeaut_pmx_gpio_request_enable,
};

static int milbeaut_gpio_get(struct gpio_chip *gc, unsigned int group)
{
	struct milbeaut_pinctrl *pctl =
		container_of(gc, struct milbeaut_pinctrl, gc);
	u32 pin, val, reg, offset;

	pin = pctl->gpins[group][0];
	reg = PDR + pin / PINS_PER_REG * 4;
	offset = pin % PINS_PER_REG;
	val = readl_relaxed(pctl->base + reg);

	return !!(val & BIT(offset));
}

static void milbeaut_gpio_set(struct gpio_chip *gc, unsigned int group, int set)
{
	struct milbeaut_pinctrl *pctl =
		container_of(gc, struct milbeaut_pinctrl, gc);
	u32 pin, reg, offset, val;

	pin = pctl->gpins[group][0];
	reg = PDR + pin / PINS_PER_REG * 4;
	offset = pin % PINS_PER_REG;

	if (milbeaut_pin_is_black(pctl, pin)) {
		printk(KERN_WARNING
			"You are trying to touch a pin%03d on BL\n", pin);
		WARN_ON(1);
	}

	val = BIT(offset + WE_OFFSET);
	if (set)
		val |= BIT(offset);

	writel_relaxed(val, pctl->base + reg);
}

static void (*gpio_set)(struct gpio_chip *, unsigned int, int);

static int milbeaut_gpio_direction_input(struct gpio_chip *gc,
		unsigned int offset)
{
	return pinctrl_gpio_direction_input(gc->base + offset);
}

static int milbeaut_gpio_direction_output(struct gpio_chip *gc,
		unsigned int offset, int value)
{
	int ret;

	ret = pinctrl_gpio_direction_output(gc->base + offset);
	if (!ret)
		gpio_set(gc, offset, value);

	return ret;
}

static int milbeaut_gpio_to_irq(struct gpio_chip *gc, unsigned int offset)
{
	struct milbeaut_pinctrl *pctl =
		container_of(gc, struct milbeaut_pinctrl, gc);

	return irq_linear_revmap(pctl->irqdom, offset);
}

static struct lock_class_key gpio_lock_class;
static struct lock_class_key gpio_request_class;

static int pin_to_extint(struct milbeaut_pinctrl *pctl, int pin)
{
	int extint;

	if (milbeaut_pin_is_black(pctl, pin))
		return -1;

	for (extint = 0; extint < pctl->extints; extint++)
		if (pctl->fpint[extint].pin == pin)
			break;

	if (extint == pctl->extints)
		return -1;

	return extint;
}

static void update_trigger(struct milbeaut_pinctrl *pctl, int extint)
{
	int type = pctl->fpint[extint].type;
	int pin = pctl->fpint[extint].pin;
	u32 masked, val, eilvl, eiedg;
	int lvl;
	u32 reg, offset;

	reg = pin / PINS_PER_REG * 4;
	offset = pin % PINS_PER_REG;

	if (milbeaut_pin_is_black(pctl, pin))
		return;

	/* sense gpio */
	val = readl_relaxed(pctl->base + PDR + reg);
	lvl = (val >> offset) & 1;

	eilvl = readl_relaxed(pctl->exiu + EILVL);
	eiedg = readl_relaxed(pctl->exiu + EIEDG);

	if (type == IRQ_TYPE_LEVEL_LOW ||
			(lvl && (type & IRQ_TYPE_LEVEL_LOW))) {
		eilvl &= ~BIT(extint);
		eiedg &= ~BIT(extint);
	}

	if (type == IRQ_TYPE_EDGE_FALLING ||
			(lvl && (type & IRQ_TYPE_EDGE_FALLING))) {
		eilvl &= ~BIT(extint);
		eiedg |= BIT(extint);
	}

	if (type == IRQ_TYPE_LEVEL_HIGH ||
			(!lvl && (type & IRQ_TYPE_LEVEL_HIGH))) {
		eilvl |= BIT(extint);
		eiedg &= ~BIT(extint);
	}

	if (type == IRQ_TYPE_EDGE_RISING ||
			(!lvl && (type & IRQ_TYPE_EDGE_RISING))) {
		eilvl |= BIT(extint);
		eiedg |= BIT(extint);
	}

	/* Mask the interrupt */
	val = readl_relaxed(pctl->exiu + EIMASK);
	masked = val & BIT(extint); /* save status */
	val |= BIT(extint);
	writel_relaxed(val, pctl->exiu + EIMASK);

	/* Program trigger */
	writel_relaxed(eilvl, pctl->exiu + EILVL);
	writel_relaxed(eiedg, pctl->exiu + EIEDG);

	if (masked)
		return;

	/* UnMask the interrupt */
	val = readl_relaxed(pctl->exiu + EIMASK);
	val &= ~BIT(extint);
	writel_relaxed(val, pctl->exiu + EIMASK);
}

static irqreturn_t milbeaut_gpio_irq_handler(int irq, void *data)
{
	struct milbeaut_pinctrl *pctl = data;
	int i, pin;
	u32 val;

	for (i = 0; i < pctl->extints; i++)
		if (pctl->fpint[i].irq == irq)
			break;
	if (i == pctl->extints) {
		pr_err("%s:%d IRQ(%d)!\n", __func__, __LINE__, irq);
		return IRQ_NONE;
	}

	if (!pctl->exiu)
		return IRQ_NONE;

	val = readl_relaxed(pctl->exiu + EIREQSTA);
	if (!(val & BIT(i))) {
		pr_err("%s:%d i=%d EIREQSTA=0x%x IRQ(%d)!\n",
				__func__, __LINE__, i, val, irq);
		return IRQ_NONE;
	}

	pin = pctl->fpint[i].pin;
	generic_handle_irq(irq_linear_revmap(pctl->irqdom, pin));

	return IRQ_HANDLED;
}

static void milbeaut_gpio_irq_enable(struct irq_data *data)
{
	struct milbeaut_pinctrl *pctl = irq_data_get_irq_chip_data(data);
	int extint = pin_to_extint(pctl, irqd_to_hwirq(data));
	unsigned long flags;
	u32 val;

	if (extint < 0 || !pctl->exiu)
		return;

	_set_mux(pctl, irqd_to_hwirq(data), true);
	_set_direction(pctl, irqd_to_hwirq(data), true);

	spin_lock_irqsave(&pctl->irq_lock, flags);

	/* Clear before enabling */
	writel_relaxed(BIT(extint), pctl->exiu + EIREQCLR);

	/* UnMask the interrupt */
	val = readl_relaxed(pctl->exiu + EIMASK);
	val &= ~BIT(extint);
	writel_relaxed(val, pctl->exiu + EIMASK);

	spin_unlock_irqrestore(&pctl->irq_lock, flags);
}

static void milbeaut_gpio_irq_disable(struct irq_data *data)
{
	struct milbeaut_pinctrl *pctl = irq_data_get_irq_chip_data(data);
	int extint = pin_to_extint(pctl, irqd_to_hwirq(data));
	unsigned long flags;
	u32 val;

	if (extint < 0 || !pctl->exiu)
		return;

	spin_lock_irqsave(&pctl->irq_lock, flags);

	/* Mask the interrupt */
	val = readl_relaxed(pctl->exiu + EIMASK);
	val |= BIT(extint);
	writel_relaxed(val, pctl->exiu + EIMASK);

	spin_unlock_irqrestore(&pctl->irq_lock, flags);
}

static int milbeaut_gpio_irq_set_type(struct irq_data *data, unsigned int type)
{
	struct milbeaut_pinctrl *pctl = irq_data_get_irq_chip_data(data);
	int extint = pin_to_extint(pctl, irqd_to_hwirq(data));
	unsigned long flags;

	if (extint < 0 || !pctl->exiu)
		return -EINVAL;

	spin_lock_irqsave(&pctl->irq_lock, flags);

	pctl->fpint[extint].type = type;
	update_trigger(pctl, extint);

	spin_unlock_irqrestore(&pctl->irq_lock, flags);

	return 0;
}

void milbeaut_gpio_irq_ack(struct irq_data *data)
{
	struct milbeaut_pinctrl *pctl = irq_data_get_irq_chip_data(data);
	int extint = pin_to_extint(pctl, irqd_to_hwirq(data));

	if (extint < 0 || !pctl->exiu)
		return;

	writel_relaxed(BIT(extint), pctl->exiu + EIREQCLR);
}

void milbeaut_gpio_irq_mask(struct irq_data *data)
{
	struct milbeaut_pinctrl *pctl = irq_data_get_irq_chip_data(data);
	int extint = pin_to_extint(pctl, irqd_to_hwirq(data));
	unsigned long flags;
	u32 val;

	if (extint < 0 || !pctl->exiu)
		return;

	spin_lock_irqsave(&pctl->irq_lock, flags);

	val = readl_relaxed(pctl->exiu + EIMASK);
	val |= BIT(extint);
	writel_relaxed(val, pctl->exiu + EIMASK);

	spin_unlock_irqrestore(&pctl->irq_lock, flags);
}

void milbeaut_gpio_irq_unmask(struct irq_data *data)
{
	struct milbeaut_pinctrl *pctl = irq_data_get_irq_chip_data(data);
	int extint = pin_to_extint(pctl, irqd_to_hwirq(data));
	unsigned long flags;
	u32 val;

	if (extint < 0 || !pctl->exiu)
		return;

	spin_lock_irqsave(&pctl->irq_lock, flags);

	update_trigger(pctl, extint);

	val = readl_relaxed(pctl->exiu + EIMASK);
	val &= ~BIT(extint);
	writel_relaxed(val, pctl->exiu + EIMASK);

	spin_unlock_irqrestore(&pctl->irq_lock, flags);
}

static int milbeaut_gpio_get_blacklist(struct platform_device *pdev,
				       struct milbeaut_pinctrl *pctl,
				       int tbanks)
{
	int ret;
	u32 *blacklist;

	blacklist = devm_kzalloc(&pdev->dev, tbanks * 4, GFP_KERNEL);
	if (!blacklist)
		return -ENOMEM;
	ret = of_property_read_u32_array(pdev->dev.of_node, "blacklist",
		blacklist, tbanks);
	if (ret)
		dev_err(&pdev->dev, "blacklist is something odd\n");
	pctl->blacklist = blacklist;
	return 0;
}

static struct irq_chip milbeaut_gpio_irq_chip = {
	.name = "milbeaut-pin-irq",
	.irq_enable = milbeaut_gpio_irq_enable,
	.irq_disable = milbeaut_gpio_irq_disable,
	.irq_set_type = milbeaut_gpio_irq_set_type,
	.irq_mask = milbeaut_gpio_irq_mask,
	.irq_unmask = milbeaut_gpio_irq_unmask,
	.irq_ack = milbeaut_gpio_irq_ack,
};

#ifdef CONFIG_PM_SLEEP
static int milbeaut_pinctrl_suspend(struct platform_device *pdev,
				     pm_message_t state)
{
#if SUPPORT_DSC
	return 0;
#else	
	struct milbeaut_pinctrl *pctl;
	struct milbeaut_saveregs *save;
	unsigned int pin, bank;
	unsigned char bit_ofs;

	pctl = dev_get_drvdata(&pdev->dev);
	save = devm_kzalloc(&pdev->dev, sizeof(*save), GFP_KERNEL);
	if (!save)
		return -ENOMEM;
	pctl->save = save;

	if (pctl->exiu) {
		save->eint[0] = readl(pctl->exiu + EIMASK);
		save->eint[1] = readl(pctl->exiu + EISRCSEL);
		save->eint[2] = readl(pctl->exiu + EILVL);
		save->eint[3] = readl(pctl->exiu + EIEDG);
	}

	for (bank = 0; bank < pctl->tbanks; bank++) {
		save->ddr[bank] = readl(pctl->base + DDR + bank * 4);
		save->pdr[bank] = readl(pctl->base + PDR + bank * 4);
		save->epcr[bank] = readl(pctl->base + EPCR + bank * 4);
		save->puder[bank] = readl(pctl->base + PUDER + bank * 4);
		save->pudcr[bank] = readl(pctl->base + PUDCR + bank * 4);
	}

	// select pins that should be kept by blacklist
	for (pin = 0; (pin / PINS_PER_REG) < pctl->tbanks; pin++) {
		if (milbeaut_pin_is_black(pctl, pin))
			continue;
		bank = pin / PINS_PER_REG;
		bit_ofs = pin % PINS_PER_REG;
		save->pdr[bank] |= BIT(bit_ofs + 16);

		if ((pctl->variant == VAR_M20V) ||
		    (pctl->variant == VAR_M20V_PMC)) {
			save->ddr[bank] |= BIT(bit_ofs + 16);
			save->epcr[bank] |= BIT(bit_ofs + 16);
			save->puder[bank] |= BIT(bit_ofs + 16);
			save->pudcr[bank] |= BIT(bit_ofs + 16);
		}
	}
	return 0;
#endif
}

static int milbeaut_pinctrl_resume(struct platform_device *pdev)
{
#if SUPPORT_DSC
	return 0;
#else
	struct milbeaut_pinctrl *pctl;
	struct milbeaut_saveregs *save;
	unsigned int bank;

	pctl = dev_get_drvdata(&pdev->dev);
	if (!pctl->save)
		return -EINVAL;
	save = pctl->save;

	for (bank = 0; bank < pctl->tbanks; bank++) {
		writel(save->pdr[bank], pctl->base + PDR + bank * 4);
		if ((pctl->variant == VAR_M20V) ||
		    (pctl->variant == VAR_M20V_PMC)) {
			writel(save->ddr[bank],
				pctl->base + DDR + bank * 4);
			writel(save->epcr[bank],
				pctl->base + EPCR + bank * 4);
			writel(save->puder[bank],
				pctl->base + PUDER + bank * 4);
			writel(save->pudcr[bank],
				pctl->base + PUDCR + bank * 4);
		}
	}

	if (pctl->exiu) {
		writel(save->eint[0], pctl->exiu + EIMASK);
		writel(save->eint[1], pctl->exiu + EISRCSEL);
		writel(save->eint[2], pctl->exiu + EILVL);
		writel(save->eint[3], pctl->exiu + EIEDG);
	}
	return 0;
#endif
}
#endif

static const struct mlb_pinctrl_param m10v_pin_param = {
	m10v_functions,
	m10v_exiu_pin_list,
	m10v_bank_name,
	gpio_m10v_grps,
	M10V_BANKS,
	0x0,
	M10V_TOTAL_PINS,
	M10V_PINS_PER_BANK,
	VAR_M10V,
};

static const struct mlb_pinctrl_param m20v_pin_param = {
	m20v_functions,
	m20v_exiu_pin_list,
	m20v_bank_name,
	gpio_m20v_grps,
	M20V_BANKS,
	0x10,
	M20V_TOTAL_PINS,
	M20V_PINS_PER_BANK,
	VAR_M20V,
};

static const struct mlb_pinctrl_param m20v_pmc_pin_param = {
	m20v_pmc_functions,
	m20v_pmc_exiu_pin_list,
	m20v_pmc_bank_name,
	gpio_m20v_pmc_grps,
	M20V_PMC_BANKS,
	0x0,
	M20V_PMC_TOTAL_PINS,
	M20V_PMC_PINS_PER_BANK,
	VAR_M20V_PMC,
};

static const struct of_device_id milbeaut_pmatch[] = {
	{
		.compatible = "socionext,milbeaut-m10v-pinctrl",
		.data = (void *)&m10v_pin_param,
	},
	{
		.compatible = "socionext,milbeaut-m20v-pinctrl",
		.data = (void *)&m20v_pin_param,
	},
	{
		.compatible = "socionext,milbeaut-m20v-pmc-pinctrl",
		.data = (void *)&m20v_pmc_pin_param,
	},
	{},
};

static int milbeaut_pinctrl_probe(struct platform_device *pdev)
{
	struct device_node *np = pdev->dev.of_node;
	struct pinctrl_dev *pctl_dev;
	struct pin_irq_map fpint[32];
	struct milbeaut_pinctrl *pctl;
	struct pinctrl_desc *pd;
	struct gpio_chip *gc;
	struct resource *res;
	int i, ret, extints, tpins, gpio_ofs, p_p_bank;
	const int *exiu_pin_list;
	const struct of_device_id *match;
	struct mlb_pinctrl_param *pparam;
	const char **gpio_grps;
	const char *bank_name;

	match = of_match_device(milbeaut_pmatch, &pdev->dev);
	if (!match)
		return -ENODEV;

	pparam = (struct mlb_pinctrl_param *)match->data;

	extints = EXIU_PINS;

	pctl = devm_kzalloc(&pdev->dev,	sizeof(*pctl) +
				sizeof(struct pin_irq_map) * extints,
				GFP_KERNEL);
	if (!pctl)
		return -ENOMEM;

	pctl->variant = pparam->variant;
	bank_name = pparam->bank_name;
	pctl->tbanks = pparam->tbanks;
	gpio_grps = pparam->gpio_grps;
	gpio_ofs = pparam->gpio_ofs;
	pctl->milbeaut_functions = pparam->milbeaut_functions;
	tpins = pparam->tpins;
	p_p_bank = pparam->pins_per_bank;
	exiu_pin_list = pparam->exiu_pin_list;

	gpio_set = milbeaut_gpio_set;

	pd = &pctl->pd;
	gc = &pctl->gc;
	spin_lock_init(&pctl->lock);
	spin_lock_init(&pctl->irq_lock);
	res = platform_get_resource_byname(pdev, IORESOURCE_MEM, "pinctrl");
	pctl->base = devm_ioremap_resource(&pdev->dev, res);
	if (!pctl->base)
		return -EINVAL;
	pctl->base += gpio_ofs;

	res = platform_get_resource_byname(pdev, IORESOURCE_MEM, "exiu");
	if (res)
		pctl->exiu = devm_ioremap_resource(&pdev->dev, res);
	if (res && !IS_ERR(pctl->exiu)) {
		writel_relaxed(~0, pctl->exiu + EIMASK); /* mask all */
		writel_relaxed(~0, pctl->exiu + EIREQCLR); /* eoi all */
		writel_relaxed(0, pctl->exiu + EISRCSEL); /* all fpint */
		writel_relaxed(~0, pctl->exiu + EILVL); /* rising edge type*/
		writel_relaxed(~0, pctl->exiu + EIEDG);
	} else {
		dev_info(&pdev->dev, "continuing without EXIU support\n");
		pctl->exiu = NULL;
	}

	for (i = 0; i < tpins; i++) {
		pctl->pins[i].number = i;
		pctl->pins[i].name = &pctl->pin_names[4 * i];
		snprintf(&pctl->pin_names[4 * i], 4, "P%c%X",
			 bank_name[i / p_p_bank], i % p_p_bank);
		gpio_grps[i] = &pctl->pin_names[4 * i];
		pctl->gpins[i][0] = i;
	}
	/* absent or incomplete entries allow all access */
	if (of_property_read_bool(np, "blacklist")) {
		ret = milbeaut_gpio_get_blacklist(pdev, pctl, pctl->tbanks);
		if (ret)
			return ret;
	}

	pd->name = dev_name(&pdev->dev);
	pd->pins = pctl->pins;
	pd->npins = tpins;
	pd->pctlops = &milbeaut_pctrl_ops;
	pd->pmxops = &milbeaut_pmx_ops;
	pd->confops = &milbeaut_pconf_ops;
	pd->owner = THIS_MODULE;
	pctl_dev = pinctrl_register(pd, &pdev->dev, pctl);
	if (!pctl_dev) {
		dev_err(&pdev->dev, "couldn't register pinctrl driver\n");
		return -EINVAL;
	}

	pctl->extints = extints;

	pctl->irqdom = irq_domain_add_linear(np, tpins,
						&irq_domain_simple_ops, pctl);
	for (i = 0; i < pctl->extints ; i++) {
		int irq;

		snprintf(fpint[i].irqname, 8, "pin-%d", exiu_pin_list[i]);
		irq = platform_get_irq_byname(pdev, fpint[i].irqname);
		if (irq < 0) {
			fpint[i].irq = FPINT_INVALID;
			fpint[i].pin = FPINT_INVALID;
			continue;
		}
		fpint[i].irq = irq;
		fpint[i].pin = exiu_pin_list[i];
	}

	for (i = 0; i < pctl->extints; i++) {
		int j = 0, irq = platform_get_irq(pdev, i);
		if (irq < 0)
			continue;
		while (fpint[j].irq != irq) {
			j++;
			if (j == pctl->extints)
				break;
		}

		snprintf(pctl->fpint[j].irqname, 8, "pin-%d", fpint[j].pin);
		pctl->fpint[j].irq = fpint[j].irq;
		pctl->fpint[j].pin = fpint[j].pin;
	}
	for (i = 0; i < pctl->extints; i++) {
		if (pctl->fpint[i].irq == 0) {
			pctl->fpint[i].irq = FPINT_INVALID;
			pctl->fpint[i].pin = FPINT_INVALID;
			pctl->fpint[i].irqname[0] = 0;
		}
	}


	for (i = 0; i < pctl->extints; i++) {
		int irq, err;
		if (pctl->fpint[i].irq == FPINT_INVALID)
			continue;
		err = devm_request_irq(&pdev->dev, pctl->fpint[i].irq,
					milbeaut_gpio_irq_handler, IRQF_SHARED,
					pctl->fpint[i].irqname, pctl);
		if (err)
			continue;
		irq = irq_create_mapping(pctl->irqdom, pctl->fpint[i].pin);
		irq_set_lockdep_class(irq, &gpio_lock_class, &gpio_request_class);
		irq_set_chip_and_handler(irq, &milbeaut_gpio_irq_chip,
					 handle_level_irq);
		irq_set_chip_data(irq, pctl);
	}

	platform_set_drvdata(pdev, pctl);

	gc->base = -1;
	gc->ngpio = tpins;
	gc->label = dev_name(&pdev->dev);
	gc->owner = THIS_MODULE;
	gc->of_node = np;
	gc->direction_input = milbeaut_gpio_direction_input;
	gc->direction_output = milbeaut_gpio_direction_output;
	gc->get = milbeaut_gpio_get;
	gc->set = gpio_set;
	gc->to_irq = milbeaut_gpio_to_irq;
	gc->request = gpiochip_generic_request;
	gc->free = gpiochip_generic_free;
	ret = gpiochip_add(gc);
	if (ret) {
		dev_err(&pdev->dev, "Failed register gpiochip\n");
		return ret;
	}

	ret = gpiochip_add_pin_range(gc, dev_name(&pdev->dev),
					0, 0, tpins);
	if (ret) {
		dev_err(&pdev->dev, "Failed to add pin range\n");
		gpiochip_remove(gc);
		return ret;
	}

	return 0;
}

static struct platform_driver milbeaut_pinctrl_driver = {
	.probe	= milbeaut_pinctrl_probe,
#ifdef CONFIG_PM_SLEEP
	.suspend = milbeaut_pinctrl_suspend,
	.resume = milbeaut_pinctrl_resume,
#endif
	.driver	= {
		.name		= "milbeaut-pinctrl",
		.of_match_table	= milbeaut_pmatch,
	},
};

static int __init milbeaut_pinctrl_init(void)
{
	return platform_driver_register(&milbeaut_pinctrl_driver);
}
arch_initcall(milbeaut_pinctrl_init);

