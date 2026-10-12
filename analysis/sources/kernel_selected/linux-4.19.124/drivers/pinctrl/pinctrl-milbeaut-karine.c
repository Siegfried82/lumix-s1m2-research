// SPDX-License-Identifier: GPL-2.0
/*
 * Copyright (C) 2020 Socionext Inc.
 * Copyright (C) 2015 Linaro Ltd.
 * Author: Jassi Brar <<REDACTED_EMAIL>>
 */
#include <linux/gpio.h>
#include <linux/interrupt.h>
#include <linux/io.h>
#include <linux/of.h>
#include <linux/of_device.h>
#include <linux/of_address.h>
#include <linux/of_irq.h>
#include <linux/pinctrl/machine.h>
#include <linux/pinctrl/pinctrl.h>
#include <linux/pinctrl/pinmux.h>
#include <linux/pinctrl/pinconf.h>
#include <linux/platform_device.h>
#include <linux/spinlock.h>

#include <linux/bsearch.h>

#include "pinctrl-utils.h"
#include "pinconf-milbeaut.h"

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
#define DDR_KARINE	(0x4)
#define EPCR_KARINE	(0x8)
#define WE_OFFSET	16

#define M10V_PINS_PER_BANK	8

#define M20V_PINS_PER_BANK	16

#define M20V_PMC_PINS_PER_BANK	16

#define PINS_PER_REG	16

#define EXIU_PINS	16

#define FPINT_INVALID	-1

#define D_EXIU_UINT_NUM	(2)

#define PERPIN_NAME_SIZE	(7)
#define PULL_ON	(0)
#define PULL_OFF (1)
#define PULL_UP	(1)
#define PULL_DOWN	(0)
#define BSTEN_ON	(1)
#define BSTEN_OFF	(0)
#define RESL0	(0)
#define RESL1	(1)
#define CDRV_ON	(1)
#define CDRV_OFF	(0)

//#define CO_DEBUG
#ifdef CO_DEBUG
#define	Print_debug(fmt, ...) \
	pr_err(pr_fmt(fmt), ##__VA_ARGS__)
#else
	#define	Print_debug(fmt, ...)
#endif
enum milbeaut_variant {
	VAR_M10V,
	VAR_M20V,
	VAR_M20V_PMC,
	VAR_KARINE,
};

/* struct define */
struct pin_irq_map {
	int pin; /* offset of pin in the managed range */
	int irq; /* virq of the pin as fpint */
	int type;
	char irqname[8];
};

union gpio_ioreg {
	u32	word;
	struct {
		u32	cdrv1	:1;
		u32	cdrv2	:1;
		u32	cres	:1;
		u32	pucnt	:1;
		u32	bsten	:1;
		u32 reserve1:11;
		u32	rsel	:1;
		u32 reserve2:15;
	} bit;
};

#ifdef CONFIG_PM_SLEEP
struct eint_reg {
	u32 eint[4];/* 4 reg for EXIU */
};

struct gpio_reg {
	u32 ddr;
	u32 pdr;
	u32 epcr;
	u32 puder;
	u32 pudcr;
};
struct milbeaut_saveregs {
	struct gpio_reg *save_reg;
	union gpio_ioreg *io_reg;
	struct eint_reg *save_exiu;
};
#endif

/* A data define for an interrupt from EXIU */
union exiu_int {
	u32 word;
	struct {
	/* Exiu's No. occur the interrupt. same as child No. */
		u8 exio_no;
	/*Occurred interrupt pin index at a
	 * function list(pin_list).
	 */
		u8 exiu_pin_index;
	/*Occurred interrupt pin index at a
	 *	fpint.
	 */
		u8 fint_index;
		u8 reserve;
	} exiu_no_int;
};

struct milbeaut_function {
	const char		*name;/* Set from child node name */
	const char * const	*groups;/* Point to func_group_pin */
	u32		ngroups;/*Size of groups */
	void __iomem *func_reg;
	/* There are all pin's NO. at this function */
	u32 *pin_list;
	/* pin_list's size */
	int pin_list_num;
	/*Every pin's name which is at the pin_list */
	char **func_group_pin;
};

struct mlb_pinctrl_param {
	int pins_per_bank;
	enum milbeaut_variant variant;
};

struct milbeaut_pinctrl {
	/* Golobal data */
	void __iomem *base;
	struct gpio_chip gc;
	struct pinctrl_desc pd;
	struct pinctrl_pin_desc *pins;
	/* Bank data */
	u32 tbanks;/* Total bank nums */
	u32 *bank_offset;/* Every bank's offset to the base is set */
	/* Group data */
	u32 *gpins;/* Size is tpins. Every Pin No. is set */
	/* Total Pin nums */
	int tpins;
	char **pin_names;/* Every pin name */
	/* Interrupt data */
	struct irq_domain *irqdom;
	spinlock_t irq_lock, lock;
	struct pin_irq_map *fpint;
	/*  fpint's valid counter */
	int fpint_counter;
	struct lock_class_key gpio_lock_class;
	struct lock_class_key gpio_request_class;
	/* Blacklist */
	u32 *blacklist;
	/* Pin list which has IO function reg */
	/* There are all Pin's No. with IO function */
	u32 *pin_list_with_iofunc;
	/* There are all Pin's IO function reg offset from the base*/
	u32 *pin_offset_list_with_iofunc;
	/* The nums of pin_offset_list_with_iofunc and pin_list_with_iofunc*/
	u32 pin_list_with_iofunc_nums;
#ifdef CONFIG_PM_SLEEP
	struct milbeaut_saveregs save;
#endif
	/* Specifical data for differrnt chip version */
	struct mlb_pinctrl_param *pinctrl_param;
	/* Function data */
	struct milbeaut_function *milb_functions;
	int functions_cnt; /* milb_function's elements */
	int func_nums;/* Except for gpio's function num. = functions_cnt-1*/
};

/* Local data define */
static const struct mlb_pinctrl_param karine_pin_param = {
	.pins_per_bank = M20V_PINS_PER_BANK,
	.variant = VAR_KARINE,
};

static const struct mlb_pinctrl_param m20v_pin_param = {
	.pins_per_bank = M20V_PINS_PER_BANK,
	.variant = VAR_M20V,
};
static const struct mlb_pinctrl_param m20v_pmc_pin_param = {
	.pins_per_bank = M20V_PMC_PINS_PER_BANK,
	.variant = VAR_M20V_PMC,
};

/* Local function declare */

/* interrupt handler */
static irqreturn_t milbeaut_gpio_irq_handler(int irq, void *data)
{
	struct milbeaut_pinctrl *pctl = data;
	int i, j, pin, k = 0;
	u32 val;
	irqreturn_t ret = IRQ_NONE;

	Print_debug("%s %s:%d\n", __FILE__,
				__func__, __LINE__);

	for (j = 1; j < pctl->functions_cnt; j++) {
		for (i = 0;
			i < pctl->milb_functions[j].pin_list_num; i++) {
			Print_debug("%s:%d i=%d IRQ(%d)!\n",
				__func__, __LINE__, i, irq);
			if (pctl->fpint[k].irq == irq) {
				val = readl_relaxed(
					pctl->milb_functions[j].func_reg
					+ EIREQSTA);
				Print_debug("%s:%d,STA:%08x,WSTA:%08x\n",
				__func__, __LINE__, val,
					readl_relaxed(
					pctl->milb_functions[j].func_reg
					+ EIRAWREQSTA));
				if ((val & BIT(i)) == 0) {
					ret = IRQ_NONE;
					Print_debug("%s:%d i=%d IRQ(%d)!\n",
						__func__, __LINE__, i, irq);
					goto end_milbeaut_gpio_irq_handler;
				}
				/* ack will clear this interrupt */
				pin = pctl->fpint[k].pin;
				generic_handle_irq(
					irq_linear_revmap(pctl->irqdom,
					pin));
				ret = IRQ_HANDLED;
				Print_debug("%s:%d,STA:%08x,WSTA:%08x\n",
				__func__, __LINE__, readl_relaxed(
					pctl->milb_functions[j].func_reg
					+ EIREQSTA),
					readl_relaxed(
					pctl->milb_functions[j].func_reg
					+ EIRAWREQSTA));
				goto end_milbeaut_gpio_irq_handler;
			} else if (pctl->fpint[k].irq == FPINT_INVALID) {
				ret = IRQ_NONE;
				Print_debug("%s:%d i=%d IRQ(%d)!\n",
					__func__, __LINE__, i, irq);
				goto end_milbeaut_gpio_irq_handler;
			}
			k++;
		}
	}
end_milbeaut_gpio_irq_handler:
	Print_debug("%s:%d IRQ(%d)!\n", __func__, __LINE__, irq);
	return IRQ_NONE;
}

/* Local function body */
static u32 get_reg_from_pin(
		struct milbeaut_pinctrl *pctl, int pin)
{
	u32 b_inedx = pin / pctl->pinctrl_param->pins_per_bank;

	return pctl->bank_offset[b_inedx];
}
/*
 * Check a pin if it is at blacklist.
 */
static bool milbeaut_pin_is_black(
		struct milbeaut_pinctrl *pctl, int pin)
{
	u32 reg;
	u32 shift, offset;
	bool ret;

	reg = pin / PINS_PER_REG * 4;
	offset = pin % PINS_PER_REG;
	shift = pctl->pinctrl_param->pins_per_bank / 8;

	if (!pctl->blacklist)
		ret = false;
	else if (pctl->blacklist[reg >> shift] & BIT(offset))
		ret = true;
	else
		ret = false;
	return ret;
}

/*
 * Read blacklist from device tree.
 */
static int milbeaut_gpio_get_blacklist(struct platform_device *pdev,
				       struct milbeaut_pinctrl *pctl,
				       int tbanks)
{
	u32 *blacklist;

	Print_debug("%s %s:%d\n", __FILE__,
							__func__, __LINE__);

	blacklist = devm_kzalloc(&pdev->dev,
		tbanks * sizeof(*pctl->blacklist), GFP_KERNEL);
	if (!blacklist)
		return -ENOMEM;
	memset(blacklist, 0, tbanks * sizeof(*pctl->blacklist));
	of_property_read_u32_array(pdev->dev.of_node,
			"blacklist", blacklist,
				   tbanks);
	pctl->blacklist = blacklist;
	return 0;
}

/*
 * Set EPCR by the pin.
 */
static void _set_mux(struct milbeaut_pinctrl *pctl,	u32 pin, bool gpio)
{
	u32 val, reg, offset;
	unsigned long flags;

	reg = get_reg_from_pin(pctl, pin);
	if (pctl->pinctrl_param->variant == VAR_KARINE)
		reg += EPCR_KARINE;
	else
		reg += EPCR;
	offset = pin % PINS_PER_REG;

	if (milbeaut_pin_is_black(pctl, pin)) {
		pr_warn(
			"You are trying to touch a pin%03d on BL\n", pin);
		WARN_ON(1);
	}

	switch (pctl->pinctrl_param->variant) {
	case VAR_M20V:
	case VAR_M20V_PMC:
		if (gpio)
			val = BIT(offset + WE_OFFSET);
		else
			val = BIT(offset + WE_OFFSET) + BIT(offset);
		writel_relaxed(val, pctl->base + reg);
		break;
	case VAR_KARINE:
	default:
		spin_lock_irqsave(&pctl->lock, flags);

		val = readl_relaxed(pctl->base + reg);

		if (gpio)
			val &= ~BIT(offset);
		else
			val |= BIT(offset);
		writel_relaxed(val, pctl->base + reg);

		spin_unlock_irqrestore(&pctl->lock, flags);
		break;
	}
	Print_debug("%s %s:%d,pin:%u,reg=%x,off:%u:%x\n"
		, __FILE__, __func__, __LINE__,
		pin, reg, offset, val);
}

/*
 * Set DDR by the pin.
 */
static int _set_direction(struct milbeaut_pinctrl *pctl,
			u32 pin, bool input)
{
	u32 val, reg, offset;
	unsigned long flags;

	reg = get_reg_from_pin(pctl, pin);
	if (pctl->pinctrl_param->variant == VAR_KARINE)
		reg += DDR_KARINE;
	else
		reg += DDR;
	offset = pin % PINS_PER_REG;

	if (milbeaut_pin_is_black(pctl, pin)) {
		pr_warn(
			"You are trying to touch a pin%03d on BL\n", pin);
		WARN_ON(1);
	}

	switch (pctl->pinctrl_param->variant) {
	case VAR_M20V:
	case VAR_M20V_PMC:
		if (input)
			val = BIT(offset + WE_OFFSET);
		else
			val = BIT(offset + WE_OFFSET) + BIT(offset);
		writel_relaxed(val, pctl->base + reg);
		break;
	case VAR_KARINE:
	default:
		spin_lock_irqsave(&pctl->lock, flags);
		val = readl_relaxed(pctl->base + reg);
		if (input)
			val &= ~BIT(offset);
		else
			val |= BIT(offset);
		writel_relaxed(val, pctl->base + reg);
		spin_unlock_irqrestore(&pctl->lock, flags);
		break;
	}
	Print_debug("%s %s:%d,pin:%u,reg=%x,off:%u:%x\n"
		, __FILE__, __func__, __LINE__,
		pin, reg, offset, val);
	return 0;
}

/*
 * Find some information relatied EXIU by pin No.
 */
static union exiu_int get_exint(struct milbeaut_pinctrl *pctl, int pin)
{
	u32 i, j, k = 0;
	union exiu_int extint = {-1};

	for (i = 1; i < pctl->functions_cnt; i++) {
		for (j = 0;
			j < pctl->milb_functions[i].pin_list_num; j++) {
			Print_debug("%s,[%d]:%d\n",
				__func__, k,
				pctl->fpint[k].pin);
			if (pctl->fpint[k].pin == pin) {
				extint.exiu_no_int.exiu_pin_index = j;
				extint.exiu_no_int.exio_no = i;
				extint.exiu_no_int.fint_index = k;
				goto escap_loop;
			} else if (pctl->fpint[k].pin == FPINT_INVALID) {
				goto escap_loop;
			}
			k++;
		}
	}

escap_loop:
	return extint;
}

/*
 * Check the pin if it is at the BL and start to
 * find some information relatied EXIU by pin No.
 */
static union exiu_int pin_to_extint(
			struct milbeaut_pinctrl *pctl, int pin)
{
	union exiu_int extint;

	Print_debug("%s %s:%d, pin:%d\n", __FILE__,
			__func__, __LINE__, pin);

	if (milbeaut_pin_is_black(pctl, pin)) {
		extint.word = -1;
		pr_warn("You are trying to touch a pin%03d on BL\n",
			pin);
		WARN_ON(1);
	} else {
		extint = get_exint(pctl, pin);
	}
	return extint;
}

/*
 * Update the trigger of EXIU.
 */
static void update_trigger(struct milbeaut_pinctrl *pctl,
				union exiu_int extint)
{
	int type = pctl->fpint[extint.exiu_no_int.fint_index].type;
	int pin = pctl->fpint[extint.exiu_no_int.fint_index].pin;
	u32 masked, val, eilvl, eiedg;
	int lvl;
	u32 reg, offset;

	Print_debug("%s %s:%d\n", __FILE__,
							__func__, __LINE__);
	reg = get_reg_from_pin(pctl, pin);
	offset = pin % PINS_PER_REG;

	if (milbeaut_pin_is_black(pctl, pin))
		return;

	/* sense gpio */
	val = readl_relaxed(pctl->base + PDR + reg);
	lvl = (val >> offset) & 1;

	eilvl = readl_relaxed(
		pctl->milb_functions[extint.exiu_no_int.exio_no].func_reg
		+ EILVL);
	eiedg = readl_relaxed(
		pctl->milb_functions[extint.exiu_no_int.exio_no].func_reg
		+ EIEDG);

	if (type == IRQ_TYPE_LEVEL_LOW ||
			(lvl && (type & IRQ_TYPE_LEVEL_LOW))) {
		eilvl &= ~BIT(extint.exiu_no_int.exiu_pin_index);
		eiedg &= ~BIT(extint.exiu_no_int.exiu_pin_index);
	}

	if (type == IRQ_TYPE_EDGE_FALLING ||
			(lvl && (type & IRQ_TYPE_EDGE_FALLING))) {
		eilvl &= ~BIT(extint.exiu_no_int.exiu_pin_index);
		eiedg |= BIT(extint.exiu_no_int.exiu_pin_index);
	}

	if (type == IRQ_TYPE_LEVEL_HIGH ||
			(!lvl && (type & IRQ_TYPE_LEVEL_HIGH))) {
		eilvl |= BIT(extint.exiu_no_int.exiu_pin_index);
		eiedg &= ~BIT(extint.exiu_no_int.exiu_pin_index);
	}

	if (type == IRQ_TYPE_EDGE_RISING ||
			(!lvl && (type & IRQ_TYPE_EDGE_RISING))) {
		eilvl |= BIT(extint.exiu_no_int.exiu_pin_index);
		eiedg |= BIT(extint.exiu_no_int.exiu_pin_index);
	}

	/* Mask the interrupt */
	val = readl_relaxed(
		pctl->milb_functions[extint.exiu_no_int.exio_no].func_reg
		+ EIMASK);
	 /* save status */
	masked = val & BIT(extint.exiu_no_int.exiu_pin_index);
	val |= BIT(extint.exiu_no_int.exiu_pin_index);
	writel_relaxed(val,
		pctl->milb_functions[extint.exiu_no_int.exio_no].func_reg
		+ EIMASK);

	/* Program trigger */
	writel_relaxed(eilvl,
		pctl->milb_functions[extint.exiu_no_int.exio_no].func_reg
		+ EILVL);
	writel_relaxed(eiedg,
		pctl->milb_functions[extint.exiu_no_int.exio_no].func_reg
		+ EIEDG);

	if (masked)
		return;

	/* UnMask the interrupt */
	val = readl_relaxed(
		pctl->milb_functions[extint.exiu_no_int.exio_no].func_reg
		+ EIMASK);
	val &= ~BIT(extint.exiu_no_int.exiu_pin_index);
	writel_relaxed(val,
		pctl->milb_functions[extint.exiu_no_int.exio_no].func_reg
		+ EIMASK);
}

/*
 * Initialize EXIU.
 */
static int init_exiu(void __iomem *func_reg)
{
#ifdef CO_DEBUG
	int i;

	for (i = 0; i < 0x20; i += 4)
		Print_debug("%s %s %d %px: %08x\n"
		, __FILE__, __func__, __LINE__, func_reg + i,
		readl_relaxed(func_reg + i));
#endif

	writel_relaxed(0, func_reg + EISRCSEL); /* all fpint */
	writel_relaxed(~0, func_reg + EILVL); /* rising edge type*/
	writel_relaxed(~0, func_reg + EIEDG);
	writel_relaxed(~0, func_reg + EIREQCLR); /* eoi all */
	writel_relaxed(~0, func_reg + EIMASK); /* mask all */

#ifdef CO_DEBUG
	for (i = 0; i < 0x20; i += 4)
		Print_debug("%s %s %d %px: %08x\n"
		, __FILE__, __func__, __LINE__, func_reg + i,
		readl_relaxed(func_reg + i));
#endif
	return 0;
}

/*
 * A call back function for bsearch.
 */
static int get_pin_index(const void *a, const void *b)
{
	int aa = *((int *)a);
	int bb = *((int *)b);

	return (aa - bb);
}

/*
 * Copy the pin name from pin_names
 * to the function pin name.
 * variable named func_group_pin.
 * milb_functions: The function respond to the child node.
 * func_pin_index: The index of array pin list at the child node.
 * pin_index: The index of array pin_names.
 */
static int copy_pin_name(
				struct milbeaut_pinctrl *pctl,
				struct milbeaut_function *milb_functions,
				int func_pin_index, int pin_index)
{
	int ret = 0;

	if (!milb_functions->func_group_pin[func_pin_index]) {
		ret = -ENOMEM;
		Print_debug("%s %s %d\n",
		__FILE__, __func__, __LINE__);
	} else {
		strncpy(
			milb_functions->func_group_pin[func_pin_index],
			pctl->pin_names[pin_index],
			PERPIN_NAME_SIZE);
		Print_debug("%s %s %d,(%d)(%d):, %s\n",
			__FILE__, __func__, __LINE__,
			func_pin_index, pin_index,
			milb_functions->func_group_pin[func_pin_index]);
	}
	return ret;
}

/*
 * Search a pin from pin list and hunt memory for the pin name.
 * milb_functions: The function respond to the child node.
 * func_pin_index: The index of array pin list at the child node.
 */
static int search_pin_name(struct platform_device *pdev,
				struct milbeaut_pinctrl *pctl,
				struct milbeaut_function *milb_functions,
				int func_pin_index)
{
	int ret = 0;
	u32 *pin_list =
		bsearch(&milb_functions->pin_list[func_pin_index],
			pctl->gpins,
			pctl->tpins,
			sizeof(*pctl->gpins), get_pin_index);

	if (pin_list) {
		int pin_index = (int)(pin_list -
			pctl->gpins);

		milb_functions->func_group_pin[func_pin_index] =
			devm_kzalloc(&pdev->dev,
			sizeof(*milb_functions->func_group_pin[func_pin_index])
			* PERPIN_NAME_SIZE, GFP_KERNEL);
		ret = copy_pin_name(pctl, milb_functions,
				func_pin_index, pin_index);
	} else {
		Print_debug("%s %s %d\n",
		__FILE__, __func__, __LINE__);
	}
	return ret;
}

/*
 * Set all pin name which are in the child node.
 * milb_functions: The function respond to the child node.
 */
static int set_func_pin_name(struct platform_device *pdev,
		struct milbeaut_pinctrl *pctl,
		struct milbeaut_function *milb_functions)
{
	int ret = 0;
	int j;

	for (j = 0; j < milb_functions->pin_list_num; j++)
		ret = search_pin_name(pdev, pctl, milb_functions, j);

	milb_functions->groups =
		(const char * const*)milb_functions->func_group_pin;
	milb_functions->ngroups =
		milb_functions->pin_list_num;
	return ret;
}

/*
 * Read a child node's data to the array pin_list in
 * the milb_functions. Initialize the EXIU register if
 * the node is EXIU.
 * child: child node.
 * func_index: child index from 1 not 0.
 */
static int get_child_data(
				struct platform_device *pdev,
				struct milbeaut_pinctrl *pctl,
				struct device_node **child,
				int func_index
				)
{
	struct device_node *np = pdev->dev.of_node;
	struct resource res;
	int ret = 0;

	*child = of_get_next_available_child(np, *child);
	if (of_address_to_resource(*child, 0, &res) == 0) {
		pctl->milb_functions[func_index].func_reg =
			devm_ioremap_resource(&pdev->dev, &res);
		Print_debug("%s %s %d,%llx,%llx, %px,%px\n",
			__FILE__, __func__, __LINE__,
			res.start, res.end,
			pctl->base, pctl->milb_functions[func_index].func_reg);
		if (!pctl->milb_functions[func_index].func_reg) {
			Print_debug("%s %s %d\n",
			__FILE__, __func__, __LINE__);
			ret = -ENOMEM;
			goto err;
		}
		/* Initialize func_reg */
		if (strncmp((*child)->name, "exiu", 4) == 0)
			init_exiu(pctl->milb_functions[func_index].func_reg);
	}
	if (!of_get_property(*child, "pin_list",
		&pctl->milb_functions[func_index].pin_list_num)) {
		ret = -EINVAL;
		Print_debug("%s %s %d\n",
		__FILE__, __func__, __LINE__);
		goto err;
	}
	pctl->milb_functions[func_index].pin_list =
		devm_kzalloc(&pdev->dev,
			pctl->milb_functions[func_index].pin_list_num,
			GFP_KERNEL);
	if (!pctl->milb_functions[func_index].pin_list) {
		ret = -ENOMEM;
		Print_debug("%s %s %d\n",
		__FILE__, __func__, __LINE__);
		goto err;
	}
	pctl->milb_functions[func_index].pin_list_num /=
		sizeof(*pctl->milb_functions[func_index].pin_list);
	if (of_property_read_u32_array(*child,
		"pin_list",
		pctl->milb_functions[func_index].pin_list,
		pctl->milb_functions[func_index].pin_list_num) != 0) {
		ret = -EINVAL;
		Print_debug("%s %s %d\n",
			__FILE__, __func__, __LINE__);
		goto err;
	}
	pctl->milb_functions[func_index].func_group_pin =
		devm_kzalloc(&pdev->dev,
		sizeof(*pctl->milb_functions[func_index].func_group_pin)
		* pctl->milb_functions[func_index].pin_list_num, GFP_KERNEL);
	if (!pctl->milb_functions[func_index].func_group_pin) {
		ret = -ENOMEM;
		Print_debug("%s %s %d\n",
			__FILE__, __func__, __LINE__);
		goto err;
	}
err:
	return ret;

}

/*
 * Read all children data to the array milb_functions.
 * Note the milb_functions[0] must be always set to GPIO.
 */
static int get_func_infor(struct platform_device *pdev,
				struct milbeaut_pinctrl *pctl)
{
	int i;
	int ret = 0;
	struct device_node *child = NULL;

		/* Set function */
	pctl->functions_cnt = (pctl->func_nums + 1);
	pctl->milb_functions =
		devm_kzalloc(&pdev->dev,
			sizeof(*pctl->milb_functions) * pctl->functions_cnt,
				GFP_KERNEL);
	if (!pctl->milb_functions) {
		ret = -ENOMEM;
		dev_err(&pdev->dev, "%s %s %d\n",
			__FILE__, __func__, __LINE__);
		goto err;
	}
	/* No.1 function must be gpio */
	pctl->milb_functions[0].name = "gpio";
	pctl->milb_functions[0].groups =
		(const char * const*)pctl->pin_names;
	pctl->milb_functions[0].ngroups = pctl->tpins;
	if (pctl->func_nums  <= 0) {
		/* No func_reg */
		dev_info(&pdev->dev,
			"continuing without EXIU support\n");
		goto err;
	}
	for (i = 1; i < pctl->functions_cnt; i++) {

		ret = get_child_data(pdev, pctl, &child, i);
		if (ret != 0)
			goto err;
		ret = set_func_pin_name(pdev,
			pctl, &pctl->milb_functions[i]);
		if (ret != 0)
			goto err;
		pctl->milb_functions[i].name = child->name;
	}

#ifdef CONFIG_PM_SLEEP
	pctl->save.save_exiu =
		devm_kzalloc(&pdev->dev, pctl->func_nums *
			sizeof(*pctl->save.save_exiu),
				GFP_KERNEL);
	if (!pctl->save.save_exiu) {
		Print_debug("%s %s %d\n",
			__FILE__, __func__, __LINE__);
		ret = -ENOMEM;
		goto err;
	}
#endif
err:
	return ret;
}

/*
 * Generate all pin name in the bank.
 * They are named as following:
 * Pxxx-y.
 * xxx: a bank name which is defiend at bank-offset in device tree.
 * y: pin No. with hex at that bank. it will be 0~f.
 * bank: Bank No.
 */
static int get_pin_names(struct platform_device *pdev,
				struct milbeaut_pinctrl *pctl,
				int bank)
{
	int j, k;
	int ret = 0;

	for (j = 0;
		j < pctl->pinctrl_param->pins_per_bank; j++) {
		k = bank * pctl->pinctrl_param->pins_per_bank + j;
		pctl->pin_names[k] =
			devm_kzalloc(&pdev->dev, PERPIN_NAME_SIZE,
				GFP_KERNEL);
		if (!pctl->pin_names[k]) {
			ret = -ENOMEM;
			dev_err(&pdev->dev, "%s %s %d\n",
				__FILE__, __func__, __LINE__);
			goto err;
		}
		snprintf(pctl->pin_names[k],
			PERPIN_NAME_SIZE, "P%03x-%X",
			 pctl->bank_offset[bank], j);
		Print_debug("pin_names[%d]:%s\n",
			k, pctl->pin_names[k]);
	}
err:
	return ret;
}

/*
 * Read the io_pin_list/io_pin_offset to pin_list_with_iofunc
 * and pin_offset_list_with_iofunc. It is a pin list in which
 * they have IO function item register. It's nums will be set
 * to pin_list_with_iofunc_nums.
 * Return pin_list_with_iofunc_nums to 0 if they are not defined.
 * They are defined only at the chip karine.
 */
static int get_io_func_offset(struct platform_device *pdev,
				struct milbeaut_pinctrl *pctl)
{
	int ret = 0, i;
	struct device_node *np = pdev->dev.of_node;

	if (!of_get_property(np, "io_pin_list",
		&pctl->pin_list_with_iofunc_nums)) {
		pctl->pin_list_with_iofunc_nums = 0;
	} else {
		pctl->pin_list_with_iofunc = devm_kzalloc(&pdev->dev,
			sizeof(*pctl->pin_list_with_iofunc) *
			pctl->pin_list_with_iofunc_nums,
			GFP_KERNEL);
		pctl->pin_offset_list_with_iofunc =
			devm_kzalloc(&pdev->dev,
			sizeof(*pctl->pin_offset_list_with_iofunc) *
			pctl->pin_list_with_iofunc_nums, GFP_KERNEL);
		if (!pctl->pin_list_with_iofunc ||
			!pctl->pin_offset_list_with_iofunc) {
			Print_debug("%s %s %d\n",
				__FILE__, __func__, __LINE__);
			ret = -ENOMEM;
			goto err;
		}
		pctl->pin_list_with_iofunc_nums /= sizeof(u32);
		if (of_property_read_u32_array(np,
			"io_pin_list",
			pctl->pin_list_with_iofunc,
			pctl->pin_list_with_iofunc_nums) != 0) {
			ret = -EINVAL;
			dev_err(&pdev->dev, "%s %s %d\n",
				__FILE__, __func__, __LINE__);
			goto err;
		}
		if (of_property_read_u32_array(np,
			"io_pin_offset",
			pctl->pin_offset_list_with_iofunc,
			pctl->pin_list_with_iofunc_nums) != 0) {
			ret = -EINVAL;
			dev_err(&pdev->dev, "%s %s %d\n",
				__FILE__, __func__, __LINE__);
			goto err;
		}
		for (i = 0; i < pctl->pin_list_with_iofunc_nums;
				i++)
			Print_debug("%s %s %d,io_pin[%d]:%u,%x\n",
				__FILE__, __func__, __LINE__,
				i, pctl->pin_list_with_iofunc[i],
				pctl->pin_offset_list_with_iofunc[i]
				);

	}
err:
	return ret;
}

/*
 * Read the bank-offset from device tree to bank_offset.
 * And set it's nums to tbanks.
 */
static int get_bank_fm_dtb(struct platform_device *pdev,
				struct milbeaut_pinctrl *pctl)
{
	int ret = 0;
	struct device_node *np = pdev->dev.of_node;

	/* Get function nums */
	pctl->func_nums = of_get_available_child_count(np);

	if (!of_get_property(np, "bank-offset",
				&pctl->tbanks)) {
		ret = -EINVAL;
		Print_debug("%s %s %d\n",
			 __FILE__, __func__, __LINE__);
		goto err;
	}
	pctl->bank_offset =
		devm_kzalloc(&pdev->dev,
			pctl->tbanks * sizeof(*pctl->bank_offset),
				GFP_KERNEL);
	if (!pctl->bank_offset) {
		ret = -ENOMEM;
		Print_debug("%s %s %d\n",
			__FILE__, __func__, __LINE__);
		goto err;
	}
	pctl->tbanks /= sizeof(*pctl->bank_offset);
	if (of_property_read_u32_array(np,
			"bank-offset",
			pctl->bank_offset,
			pctl->tbanks) != 0) {
		ret = -EINVAL;
		Print_debug("%s %s %d\n",
		__FILE__, __func__, __LINE__);
		goto err;
	}
err:
	return ret;
}

/*
 * Get the pin No. and pin name.
 * They are generated from bank-offset.
 */
static int get_all_pin_fm_dtb(struct platform_device *pdev,
				struct milbeaut_pinctrl *pctl)
{
	int ret = 0, i;

	/* Set all pin nums */
	pctl->tpins = pctl->pinctrl_param->pins_per_bank * pctl->tbanks;

	pctl->pin_names =
		devm_kzalloc(&pdev->dev,
			pctl->tpins * sizeof(*pctl->pin_names),
				GFP_KERNEL);
	if (!pctl->pin_names) {
		ret = -ENOMEM;
		Print_debug("%s %s %d\n",
			__FILE__, __func__, __LINE__);
		goto err;
	}
	pctl->pins =
		devm_kzalloc(&pdev->dev, pctl->tpins * sizeof(*pctl->pins),
				GFP_KERNEL);
	if (!pctl->pins) {
		ret = -ENOMEM;
		dev_err(&pdev->dev, "%s %s %d\n",
			__FILE__, __func__, __LINE__);
		goto err;
	}

	for (i = 0; i < pctl->tbanks; i++) {
		ret = get_pin_names(pdev, pctl, i);
		if (ret != 0)
			goto err;
	}
	pctl->gpins =
		devm_kzalloc(&pdev->dev, pctl->tpins * sizeof(*pctl->gpins),
				GFP_KERNEL);
	if (!pctl->gpins) {
		ret = -ENOMEM;
		dev_err(&pdev->dev, "%s %s %d\n",
			__FILE__, __func__, __LINE__);
		goto err;
	}

	for (i = 0; i < pctl->tpins; i++) {
		pctl->pins[i].number = i;
		pctl->pins[i].name = pctl->pin_names[i];
		pctl->gpins[i] = i;
	}
err:
	return ret;
}

/*
 * Get the data from device tree.
 * They are included as following:
 * bank-offset, io_pin_list, io_pin_offset
 * and all child node data.
 */
static int get_bank(struct platform_device *pdev,
				struct milbeaut_pinctrl *pctl)
{
	int ret = get_bank_fm_dtb(pdev, pctl);

	if (ret != 0)
		goto err;

	ret = get_all_pin_fm_dtb(pdev, pctl);
	if (ret != 0)
		goto err;

	ret = get_io_func_offset(pdev, pctl);

#ifdef CONFIG_PM_SLEEP
	pctl->save.save_reg = devm_kzalloc(&pdev->dev,
		sizeof(*pctl->save.save_reg) * pctl->tbanks, GFP_KERNEL);
	if (pctl->pin_list_with_iofunc_nums > 0) {
		pctl->save.io_reg = devm_kzalloc(&pdev->dev,
			sizeof(*pctl->save.io_reg) *
				pctl->pin_list_with_iofunc_nums,
			GFP_KERNEL);
		if (!pctl->save.io_reg) {
			dev_err(&pdev->dev, "%s %s %d\n",
				__FILE__, __func__, __LINE__);
			ret = -ENOMEM;
			goto err;
		}
	}
#endif
	if (get_func_infor(pdev, pctl) != 0) {
		ret = -EINVAL;
		dev_err(&pdev->dev, "%s %s %d\n",
			__FILE__, __func__, __LINE__);
		goto err;
	}
err:
	return ret;
}

/*
 * Get the IO function item's register offset by pin No..
 * Return -1 if it is not found.
 */
static int get_io_reg_fm_pin_karine(
				struct milbeaut_pinctrl *pctl, u32 pin)
{
	int i;
	int reg = -1;

	for (i = 0; i < pctl->pin_list_with_iofunc_nums; i++) {
		if (pin == pctl->pin_list_with_iofunc[i]) {
			reg = pctl->pin_offset_list_with_iofunc[i];
			goto end_this;
		}
	}
end_this:
	return reg;
}

/*
 * Set pull down/up and other IO function items.
 * It is used for the chip karine only.
 */
static union gpio_ioreg get_io_func_val(
						union gpio_ioreg io_reg,
						int config_param)
{
	switch (config_param) {
	case PIN_CONFIG_BIAS_PULL_UP:
		/* enable Pull-Up/Down resistance */
		io_reg.bit.cres = PULL_ON;/* 0: Enable 1:Disable */
		io_reg.bit.pucnt = PULL_UP;
		break;
	case PIN_CONFIG_BIAS_PULL_DOWN:
		/* enable Pull-Up/Down resistance */
		io_reg.bit.cres = PULL_ON;/* 0: Enable 1:Disable */
		io_reg.bit.pucnt = PULL_DOWN;
		break;
	case PIN_CONFIG_BIAS_DISABLE:
		io_reg.bit.cres = PULL_OFF;/* 0: Enable 1:Disable */
		break;
	case PIN_CONFIG_MIL_BSTEN_ON:
		io_reg.bit.bsten = BSTEN_ON;
		break;
	case PIN_CONFIG_MIL_BSTEN_OFF:
		io_reg.bit.bsten = BSTEN_OFF;
		break;
	case PIN_CONFIG_MIL_RSEL0:
		io_reg.bit.rsel = RESL0;
		break;
	case PIN_CONFIG_MIL_RSEL1:
		io_reg.bit.rsel = RESL1;
		break;
	case PIN_CONFIG_MIL_CDRV1_ON:
		io_reg.bit.cdrv1 = CDRV_ON;
		break;
	case PIN_CONFIG_MIL_CDRV1_OFF:
		io_reg.bit.cdrv1 = CDRV_OFF;
		break;
	case PIN_CONFIG_MIL_CDRV2_ON:
		io_reg.bit.cdrv2 = CDRV_ON;
		break;
	case PIN_CONFIG_MIL_CDRV2_OFF:
		io_reg.bit.cdrv2 = CDRV_OFF;
		break;
	default:
		break;
	}
	return io_reg;
}

#ifdef CONFIG_PM_SLEEP
/*
 * Save all GPIO registers.
 * It is used for the chip expect karine.
 */
static int save_m20(struct milbeaut_pinctrl *pctl)
{
	u32 bank;

	for (bank = 0; bank < pctl->tbanks; bank++) {
		pctl->save.save_reg[bank].ddr =
			readl(pctl->base + DDR + bank * 4);
		pctl->save.save_reg[bank].pdr =
			readl(pctl->base + PDR + bank * 4);
		pctl->save.save_reg[bank].epcr =
			readl(pctl->base + EPCR + bank * 4);
		pctl->save.save_reg[bank].puder =
			readl(pctl->base + PUDER + bank * 4);
		pctl->save.save_reg[bank].pudcr =
			readl(pctl->base + PUDCR + bank * 4);
	}
	return 0;
}

/*
 * Save all GPIO registers.
 * It is used for the chip karine only.
 */
static int save_karine(struct milbeaut_pinctrl *pctl)
{
	int io_pin;
	u32 bank;

	for (bank = 0; bank < pctl->tbanks; bank++) {
		pctl->save.save_reg[bank].pdr =
			readl(pctl->base +
				pctl->bank_offset[bank]);
		pctl->save.save_reg[bank].ddr =
			readl(pctl->base +
				pctl->bank_offset[bank] +
				DDR_KARINE);
		pctl->save.save_reg[bank].epcr =
			readl(pctl->base +
				pctl->bank_offset[bank] +
				EPCR_KARINE);
	}
	for (io_pin = 0;
		io_pin < pctl->pin_list_with_iofunc_nums;
		io_pin++)
		pctl->save.io_reg[io_pin].word =
			readl(pctl->base +
			pctl->pin_offset_list_with_iofunc[io_pin]);

	return 0;
}

/*
 * Save all exiu registers.
 * Now, the child with register is exiu only.
 */
static int save_exiu(struct milbeaut_pinctrl *pctl)
{
	int i;

	for (i = 0; i < pctl->func_nums; i++) {
		if (pctl->milb_functions[i + 1].func_reg) {
			pctl->save.save_exiu[i].eint[0] =
				readl(
					pctl->milb_functions[i + 1].func_reg
					+ EIMASK);
			pctl->save.save_exiu[i].eint[1] =
				readl(
					pctl->milb_functions[i + 1].func_reg
					+ EISRCSEL);
			pctl->save.save_exiu[i].eint[2] =
				readl(
					pctl->milb_functions[i + 1].func_reg
					+ EILVL);
			pctl->save.save_exiu[i].eint[3] =
					readl(
					pctl->milb_functions[i + 1].func_reg
					+ EIEDG);
		}
	}
	return 0;
}

/*
 * Resume all exiu registers.
 * Now, the child with register is exiu only.
 */
static int restroe_exiu(struct milbeaut_pinctrl *pctl)
{
	int i;

	for (i = 0; i < pctl->func_nums; i++) {
		if (pctl->milb_functions[i + 1].func_reg) {
			writel(pctl->save.save_exiu[i].eint[0],
				pctl->milb_functions[i + 1].func_reg
				+ EIMASK);
			writel(pctl->save.save_exiu[i].eint[1],
				pctl->milb_functions[i + 1].func_reg
				+ EISRCSEL);
			writel(pctl->save.save_exiu[i].eint[2],
				pctl->milb_functions[i + 1].func_reg
				+ EILVL);
			writel(pctl->save.save_exiu[i].eint[3],
				pctl->milb_functions[i + 1].func_reg
				+ EIEDG);
		}
	}
	return 0;
}

/*
 * Resume all bank's GPIO registers of karine soc only.
 */
static int resume_gpio_karine(struct milbeaut_pinctrl *pctl)
{
	int io_pin, pin;
	u32 bank;

	for (bank = 0; bank < pctl->tbanks; bank++) {
		writel(pctl->save.save_reg[bank].pdr,
			pctl->base +
			pctl->bank_offset[bank]);
		writel(pctl->save.save_reg[bank].ddr,
			pctl->base +
			pctl->bank_offset[bank] +
			DDR_KARINE);
		writel(pctl->save.save_reg[bank].epcr,
			pctl->base +
			pctl->bank_offset[bank] +
			EPCR_KARINE);
	}
	for (io_pin = 0;
		io_pin < pctl->pin_list_with_iofunc_nums;
		io_pin++) {
		pin = pctl->pin_list_with_iofunc[io_pin];
		if (!milbeaut_pin_is_black(pctl, pin))
			writel(pctl->save.io_reg[io_pin].word,
			pctl->base +
			pctl->pin_offset_list_with_iofunc[io_pin]);
	}
	return 0;
}

/*
 * Resume all bank's GPIO registers exclude karine soc.
 */
static int resume_gpio_ordiany(struct milbeaut_pinctrl *pctl)
{
	u32 bank;

	for (bank = 0; bank < pctl->tbanks; bank++) {
		/* Needn't check the BL because they are not set
		 * write bit at suspend
		 */
		writel(pctl->save.save_reg[bank].pdr,
			pctl->base + PDR + bank * 4);
		writel(pctl->save.save_reg[bank].ddr,
			pctl->base + DDR + bank * 4);
		writel(pctl->save.save_reg[bank].epcr,
			pctl->base + EPCR + bank * 4);
		writel(pctl->save.save_reg[bank].puder,
			pctl->base + PUDER + bank * 4);
		writel(pctl->save.save_reg[bank].pudcr,
			pctl->base + PUDCR + bank * 4);
	}
	return 0;
}
#endif /* CONFIG_PM_SLEEP */
/* Call back function define */
static int milbeaut_pconf_group_set_karine(
					struct pinctrl_dev *pctldev,
				 u32 group,
				 unsigned long *configs,
				 u32 num_configs)
{
	struct milbeaut_pinctrl *pctl = pinctrl_dev_get_drvdata(pctldev);
	u32 pin;
	int reg;
	int i;
	union gpio_ioreg io_reg;
	int ret = 0;

	Print_debug("%s %s:%d\n", __FILE__,
			__func__, __LINE__);
	pin = pctl->gpins[group];
	reg = get_io_reg_fm_pin_karine(pctl, pin);
	if (reg <= 0) {
		ret = -EINVAL;
		pr_err(
			"Not found this pin(%d)'s offset.\n", pin);
		goto err;
	}

	io_reg.word = readl_relaxed(pctl->base + reg);
	if (milbeaut_pin_is_black(pctl, pin)) {
		pr_warn("You are trying to touch a pin%03d on BL\n",
			pin);
		WARN_ON(1);
	}

	for (i = 0; i < num_configs; i++)
		io_reg = get_io_func_val(io_reg,
			(int)pinconf_to_config_param(configs[i]));

	writel_relaxed(io_reg.word, pctl->base + reg);
err:
	return ret;
}

static int milbeaut_pctrl_get_groups_count(struct pinctrl_dev *pctldev)
{
	struct milbeaut_pinctrl *pctl = pinctrl_dev_get_drvdata(pctldev);

	Print_debug("%s %s:%d, %s:count:%d\n", __FILE__,
			__func__, __LINE__, pctl->pd.name, pctl->tpins);
	return pctl->tpins;
}

static const char *milbeaut_pctrl_get_group_name(
					struct pinctrl_dev *pctldev, u32 pin)
{
	struct milbeaut_pinctrl *pctl = pinctrl_dev_get_drvdata(pctldev);

	Print_debug("%s %s:%d,%s gr-name[%u]:%s\n", __FILE__,
		__func__, __LINE__,
		pctl->pd.name, pin, pctl->pin_names[pin]);
	return pctl->pin_names[pin];
}

static int milbeaut_pctrl_get_group_pins(struct pinctrl_dev *pctldev,
				      u32 group,
				      const u32 **pins,
				      u32 *num_pins)
{
	struct milbeaut_pinctrl *pctl = pinctrl_dev_get_drvdata(pctldev);

	Print_debug("%s %s:%d %s %u\n", __FILE__,
				__func__, __LINE__, pctl->pd.name, group);
	*pins = &pctl->gpins[group];
	*num_pins = 1;
	return 0;
}

static int milbeaut_pmx_get_funcs_cnt(struct pinctrl_dev *pctldev)
{
	struct milbeaut_pinctrl *pctl = pinctrl_dev_get_drvdata(pctldev);

	Print_debug("%s %s:%d,%s:cnt:%d\n", __FILE__,
		__func__, __LINE__,
		pctl->pd.name, pctl->functions_cnt);
	return pctl->functions_cnt;
}

static const char *milbeaut_pmx_get_func_name(
					struct pinctrl_dev *pctldev,
					u32 function)
{
	struct milbeaut_pinctrl *pctl = pinctrl_dev_get_drvdata(pctldev);

	Print_debug("%s %s:%d,%s function:%u,%s\n", __FILE__,
		__func__, __LINE__, pctl->pd.name,
		function, pctl->milb_functions[function].name);
	return pctl->milb_functions[function].name;
}

static int milbeaut_pmx_get_func_groups(
				struct pinctrl_dev *pctldev,
				u32 function,
				const char * const **groups,
				u32 * const num_groups)
{
	struct milbeaut_pinctrl *pctl = pinctrl_dev_get_drvdata(pctldev);

	Print_debug("%s %s:%d, %s func:%u\n", __FILE__,
		__func__, __LINE__,
		pctl->pd.name, function);
	*groups = pctl->milb_functions[function].groups;
	*num_groups = pctl->milb_functions[function].ngroups;
	return 0;
}

static int milbeaut_pmx_set_mux(struct pinctrl_dev *pctldev,
			     u32 function,
			     u32 group)
{
	struct milbeaut_pinctrl *pctl =
		pinctrl_dev_get_drvdata(pctldev);
	/* each group has exactly 1 pin */
	u32 pin = pctl->gpins[group];

	Print_debug("%s %s %s f:%u g:%u\n", __FILE__,
		__func__,
		pctl->pd.name, function, group);
	_set_mux(pctl, pin, !function);

	return 0;
}

static int
milbeaut_pmx_gpio_set_direction(struct pinctrl_dev *pctldev,
			struct pinctrl_gpio_range *range,
			u32 pin, bool input)
{
	struct milbeaut_pinctrl *pctl = pinctrl_dev_get_drvdata(pctldev);

	Print_debug("%s %s:%d %s,pin:%u,input:%u\n", __FILE__,
		__func__, __LINE__,	pctl->pd.name, pin, input);

	return _set_direction(pctl, pin, input);
}

static int
milbeaut_pmx_gpio_request_enable(struct pinctrl_dev *pctldev,
			    struct pinctrl_gpio_range *range,
			    u32 pin)
{
	struct milbeaut_pinctrl *pctl = pinctrl_dev_get_drvdata(pctldev);

	Print_debug("%s %s:%d,%s %u\n", __FILE__,
				__func__, __LINE__,
		pctl->pd.name, pin);
	_set_mux(pctl, pin, true);
	return 0;
}

static int milbeaut_gpio_get(struct gpio_chip *gc, u32 group)
{
	struct milbeaut_pinctrl *pctl =
		container_of(gc, struct milbeaut_pinctrl, gc);
	u32 pin, val, reg, offset;

	pin = pctl->gpins[group];
	reg = get_reg_from_pin(pctl, pin);
	offset = pin % PINS_PER_REG;
	val = readl_relaxed(pctl->base + reg);

	Print_debug("%s %s:%d,gropu:%u,val:%x\n", __FILE__,
			__func__, __LINE__, group, val);
	return !!(val & BIT(offset));
}

static void milbeaut_gpio_set(
		struct gpio_chip *gc, u32 group, int set)
{
	struct milbeaut_pinctrl *pctl =
		container_of(gc, struct milbeaut_pinctrl, gc);
	u32 pin, reg, offset, val;
	unsigned long flags;

	pin = pctl->gpins[group];
	reg = get_reg_from_pin(pctl, pin);

	offset = pin % PINS_PER_REG;

	if (milbeaut_pin_is_black(pctl, pin)) {
		pr_warn(
			"You are trying to touch a pin%03d on BL\n", pin);
		WARN_ON(1);
	}

	switch (pctl->pinctrl_param->variant) {
	case VAR_KARINE:
		spin_lock_irqsave(&pctl->lock, flags);
		val = readl_relaxed(pctl->base + reg);
		val |= BIT(offset + WE_OFFSET);
		if (set)
			val |=  BIT(offset);
		else
			val &= ~BIT(offset);
		writel_relaxed(val, pctl->base + reg);
		spin_unlock_irqrestore(&pctl->lock, flags);
		break;
	case VAR_M20V:
	case VAR_M20V_PMC:
	default:
		val = BIT(offset + WE_OFFSET);
		if (set)
			val |= BIT(offset);
		writel_relaxed(val, pctl->base + reg);
		break;
	}

	Print_debug("%s,pin:%u,gropu:%u,set:%d,reg:%x,offset:%x,val:%x\n"
		, __func__,
		pin, group, set, reg, offset, val);
}

static int milbeaut_gpio_direction_input(
		struct gpio_chip *gc, u32 offset)
{
	Print_debug("%s %s:%d\n", __FILE__,
							__func__, __LINE__);

	return pinctrl_gpio_direction_input(gc->base + offset);
}

static int milbeaut_gpio_direction_output(struct gpio_chip *gc,
		u32 offset, int value)
{
	int ret;

	ret = pinctrl_gpio_direction_output(gc->base + offset);
	if (!ret)
		milbeaut_gpio_set(gc, offset, value);

	Print_debug("%s %s:%d,ret:%d\n", __FILE__,
				__func__, __LINE__, ret);
	return ret;
}

static int milbeaut_gpio_to_irq(struct gpio_chip *gc, u32 offset)
{
	struct milbeaut_pinctrl *pctl =
		container_of(gc, struct milbeaut_pinctrl, gc);

	Print_debug("%s %s:%d,offset:%u\n", __FILE__,
				__func__, __LINE__, offset);

	return irq_linear_revmap(pctl->irqdom, offset);
}

static void milbeaut_gpio_irq_enable(struct irq_data *data)
{
	struct milbeaut_pinctrl *pctl = irq_data_get_irq_chip_data(data);
	union exiu_int extint = pin_to_extint(pctl, irqd_to_hwirq(data));
	unsigned long flags;
	u32 val;

	Print_debug("%s %s:%d, exio_no:%u,exiu_pin_index:%u,fint_index:%d\n",
		 __FILE__, __func__, __LINE__,
		extint.exiu_no_int.exio_no,
		extint.exiu_no_int.exiu_pin_index,
		extint.exiu_no_int.fint_index);

	if ((int)extint.exiu_no_int.exiu_pin_index < 0 ||
		!pctl->milb_functions[extint.exiu_no_int.exio_no].func_reg)
		return;

	_set_mux(pctl, irqd_to_hwirq(data), true);
	_set_direction(pctl, irqd_to_hwirq(data), true);

	spin_lock_irqsave(&pctl->irq_lock, flags);

	/* Clear before enabling */
	writel_relaxed(BIT(extint.exiu_no_int.exiu_pin_index),
		pctl->milb_functions[extint.exiu_no_int.exio_no].func_reg
		+ EIREQCLR);

	/* UnMask the interrupt */
	val = readl_relaxed(
		pctl->milb_functions[extint.exiu_no_int.exio_no].func_reg
			+ EIMASK);
	val &= ~BIT(extint.exiu_no_int.exiu_pin_index);
	writel_relaxed(val,
		pctl->milb_functions[extint.exiu_no_int.exio_no].func_reg
			+ EIMASK);

	spin_unlock_irqrestore(&pctl->irq_lock, flags);
}

static void milbeaut_gpio_irq_disable(struct irq_data *data)
{
	struct milbeaut_pinctrl *pctl = irq_data_get_irq_chip_data(data);
	union exiu_int extint = pin_to_extint(pctl, irqd_to_hwirq(data));
	unsigned long flags;
	u32 val;

	Print_debug("%s %s:%d\n", __FILE__,
				__func__, __LINE__);

	if ((int)extint.exiu_no_int.exiu_pin_index < 0 ||
		!pctl->milb_functions[extint.exiu_no_int.exio_no].func_reg)
		return;

	spin_lock_irqsave(&pctl->irq_lock, flags);

	/* Mask the interrupt */
	val = readl_relaxed(
		pctl->milb_functions[extint.exiu_no_int.exio_no].func_reg
			+ EIMASK);
	val |= BIT(extint.exiu_no_int.exiu_pin_index);
	writel_relaxed(val,
		pctl->milb_functions[extint.exiu_no_int.exio_no].func_reg
			+ EIMASK);

	spin_unlock_irqrestore(&pctl->irq_lock, flags);
}

static int milbeaut_gpio_irq_set_type(struct irq_data *data, u32 type)
{
	struct milbeaut_pinctrl *pctl = irq_data_get_irq_chip_data(data);
	union exiu_int extint = pin_to_extint(pctl, irqd_to_hwirq(data));
	unsigned long flags;

	Print_debug("%s,exio_no:%u,ExPidx:%u,F_idx:%d,ty:%d\n",
		__func__,
		extint.exiu_no_int.exio_no,
		extint.exiu_no_int.exiu_pin_index,
		extint.exiu_no_int.fint_index,
		type);

	if ((int)extint.exiu_no_int.exiu_pin_index < 0 ||
		!pctl->milb_functions[extint.exiu_no_int.exio_no].func_reg)
		return -EINVAL;

	spin_lock_irqsave(&pctl->irq_lock, flags);

	pctl->fpint[extint.exiu_no_int.fint_index].type = type;
	update_trigger(pctl, extint);

	spin_unlock_irqrestore(&pctl->irq_lock, flags);

	return 0;
}

static void milbeaut_gpio_irq_ack(struct irq_data *data)
{
	struct milbeaut_pinctrl *pctl = irq_data_get_irq_chip_data(data);
	union exiu_int extint = pin_to_extint(pctl, irqd_to_hwirq(data));

	Print_debug("%s %s:%d,i:%d,no:%d\n",
		__FILE__, __func__, __LINE__,
		extint.exiu_no_int.exiu_pin_index,
		extint.exiu_no_int.exio_no);
		Print_debug("%s:%d,EIREQSTA:%08x,EIRAWREQSTA:%08x\n",
		__func__, __LINE__, readl_relaxed(
		pctl->milb_functions[extint.exiu_no_int.exio_no].func_reg
		+ EIREQSTA),
		readl_relaxed(
		pctl->milb_functions[extint.exiu_no_int.exio_no].func_reg
		+ EIRAWREQSTA));

	if ((int)extint.exiu_no_int.exiu_pin_index < 0 ||
		!pctl->milb_functions[extint.exiu_no_int.exio_no].func_reg)
		return;

	writel_relaxed(BIT(extint.exiu_no_int.exiu_pin_index),
		 pctl->milb_functions[extint.exiu_no_int.exio_no].func_reg
				+ EIREQCLR);
	Print_debug("%s:%d,EIREQSTA:%08x,EIRAWREQSTA:%08x\n",
	__func__, __LINE__, readl_relaxed(
	pctl->milb_functions[extint.exiu_no_int.exio_no].func_reg
	+ EIREQSTA),
	readl_relaxed(
	pctl->milb_functions[extint.exiu_no_int.exio_no].func_reg
	+ EIRAWREQSTA));
}

static void milbeaut_gpio_irq_mask(struct irq_data *data)
{
	struct milbeaut_pinctrl *pctl = irq_data_get_irq_chip_data(data);
	union exiu_int  extint = pin_to_extint(pctl, irqd_to_hwirq(data));
	unsigned long flags;
	u32 val;

	Print_debug("%s %s:%d\n", __FILE__,
				__func__, __LINE__);

	if ((int)extint.exiu_no_int.exiu_pin_index < 0 ||
		!pctl->milb_functions[extint.exiu_no_int.exio_no].func_reg)
		return;

	spin_lock_irqsave(&pctl->irq_lock, flags);

	val = readl_relaxed(
		pctl->milb_functions[extint.exiu_no_int.exio_no].func_reg
			+ EIMASK);
	val |= BIT(extint.exiu_no_int.exiu_pin_index);
	writel_relaxed(val,
		pctl->milb_functions[extint.exiu_no_int.exio_no].func_reg
			+ EIMASK);

	spin_unlock_irqrestore(&pctl->irq_lock, flags);
}

static void milbeaut_gpio_irq_unmask(struct irq_data *data)
{
	struct milbeaut_pinctrl *pctl = irq_data_get_irq_chip_data(data);
	union exiu_int extint = pin_to_extint(pctl, irqd_to_hwirq(data));
	unsigned long flags;
	u32 val;

	Print_debug("%s %s:%d\n", __FILE__,
				__func__, __LINE__);

	if ((int)extint.exiu_no_int.exiu_pin_index < 0 ||
		!pctl->milb_functions[extint.exiu_no_int.exio_no].func_reg)
		return;

	spin_lock_irqsave(&pctl->irq_lock, flags);

	update_trigger(pctl, extint);

	val = readl_relaxed(
		pctl->milb_functions[extint.exiu_no_int.exio_no].func_reg
			+ EIMASK);
	val &= ~BIT(extint.exiu_no_int.exiu_pin_index);
	writel_relaxed(val,
		pctl->milb_functions[extint.exiu_no_int.exio_no].func_reg
			+ EIMASK);

	spin_unlock_irqrestore(&pctl->irq_lock, flags);
}

#ifdef CONFIG_PM_SLEEP
static int milbeaut_pinctrl_suspend(struct platform_device *pdev,
				     pm_message_t state)
{
	struct milbeaut_pinctrl *pctl;
	u32 bank;
	int pin;
	u8 bit_ofs;

	Print_debug("%s %s:%d\n", __FILE__,
							__func__, __LINE__);
	pctl = dev_get_drvdata(&pdev->dev);

	save_exiu(pctl);

	if (pctl->pinctrl_param->variant == VAR_KARINE)
		save_karine(pctl);
	else
		save_m20(pctl);
	/* select pins that should be kept by blacklist */
	for (pin = 0;
		(pin / PINS_PER_REG) < pctl->tbanks; pin++) {
		if (milbeaut_pin_is_black(pctl, pin))
			continue;
		bank = pin / PINS_PER_REG;
		bit_ofs = pin % PINS_PER_REG;
		pctl->save.save_reg[bank].pdr |= BIT(bit_ofs + 16);

		switch (pctl->pinctrl_param->variant) {
		case VAR_M20V:
		case VAR_M20V_PMC:
		case VAR_KARINE:
			pctl->save.save_reg[bank].ddr |=
				BIT(bit_ofs + 16);
			pctl->save.save_reg[bank].epcr |=
				BIT(bit_ofs + 16);
			if (pctl->pinctrl_param->variant != VAR_KARINE) {
				pctl->save.save_reg[bank].puder |=
				BIT(bit_ofs + 16);
				pctl->save.save_reg[bank].pudcr |=
				BIT(bit_ofs + 16);
			}
			break;
		default:
			break;
		}
	}

	return 0;
}

static int milbeaut_pinctrl_resume(struct platform_device *pdev)
{
	struct milbeaut_pinctrl *pctl =
			dev_get_drvdata(&pdev->dev);

	Print_debug("%s %s:%d\n", __FILE__,
				__func__, __LINE__);
	switch (pctl->pinctrl_param->variant) {
	case VAR_M20V:
	case VAR_M20V_PMC:
		resume_gpio_ordiany(pctl);
		break;
	case VAR_KARINE:
		resume_gpio_karine(pctl);
		break;
	default:
		break;
	}
	restroe_exiu(pctl);
	return 0;
}
#endif /* CONFIG_PM_SLEEP */

static const struct of_device_id milbeaut_pmatch[] = {
	{
		.compatible = "socionext,milbeaut-karine-pinctrl",
		.data = (void *)&karine_pin_param,
	},
	{},
};

/* ops define */
static const struct pinconf_ops milbeaut_pconf_ops = {
	.pin_config_group_set	= milbeaut_pconf_group_set_karine,
	.pin_config_set = milbeaut_pconf_group_set_karine,
};

static const struct pinctrl_ops milbeaut_pctrl_ops = {
	.get_groups_count	= milbeaut_pctrl_get_groups_count,
	.get_group_name		= milbeaut_pctrl_get_group_name,
	.get_group_pins		= milbeaut_pctrl_get_group_pins,
	.dt_node_to_map		= pinconf_generic_dt_node_to_map_group,
	.dt_free_map		= pinctrl_utils_free_map,
};

static const struct pinmux_ops milbeaut_pmx_ops = {
	.get_functions_count	= milbeaut_pmx_get_funcs_cnt,
	.get_function_name	= milbeaut_pmx_get_func_name,
	.get_function_groups	= milbeaut_pmx_get_func_groups,
	.set_mux		= milbeaut_pmx_set_mux,
	.gpio_set_direction	= milbeaut_pmx_gpio_set_direction,
	.gpio_request_enable	= milbeaut_pmx_gpio_request_enable,
};

static struct irq_chip milbeaut_gpio_irq_chip = {
	.name = "milbeaut-pin-irq",
	.irq_enable = milbeaut_gpio_irq_enable,
	.irq_disable = milbeaut_gpio_irq_disable,
	.irq_set_type = milbeaut_gpio_irq_set_type,
	.irq_mask = milbeaut_gpio_irq_mask,
	.irq_unmask = milbeaut_gpio_irq_unmask,
	.irq_ack = milbeaut_gpio_irq_ack,
};

/* Local function for probe only */
/*
 * Register the interrupt which is indeicated by the
 * variable named fpint_index to system.
 * fpint_index: an index of the array variable named fpint
 */
static int register_irq(struct platform_device *pdev,
			struct milbeaut_pinctrl *pctl,
			int fpint_index)
{
	int ret = 0;
	int err =
		devm_request_irq(
			&pdev->dev, pctl->fpint[fpint_index].irq,
			milbeaut_gpio_irq_handler, IRQF_SHARED,
			pctl->fpint[fpint_index].irqname, pctl);

	Print_debug("%s %s %d,[%d],%s,irq:%d,pin:%u,err:%d\n",
		__FILE__, __func__, __LINE__,
		fpint_index,
		pctl->fpint[fpint_index].irqname,
		pctl->fpint[fpint_index].irq,
		pctl->fpint[fpint_index].pin, err);
	if (err == 0) {
		int irq;

		irq = irq_create_mapping(pctl->irqdom,
			pctl->fpint[fpint_index].pin);
		if (irq > 0) {
			irq_set_lockdep_class(irq, &pctl->gpio_lock_class,
				&pctl->gpio_request_class);
			irq_set_chip_and_handler(irq,
				&milbeaut_gpio_irq_chip,
				handle_level_irq);
			irq_set_chip_data(irq, pctl);
		} else {
			dev_err(&pdev->dev, "%s %s %d\n",
				__FILE__, __func__, __LINE__);
			ret = -EINVAL;
		}

	}
	return ret;
}

/*
 * Set the variable named fpint.
 * Check all pins at the child node.
 * Get IRQ from device tree by the "pin-xx" which
 * is generated by the pin list at the child node.
 * Start to register interrupt to system.
 * func_no: The function No. which is from first
 * child to last the one.
 */
static int set_fpint(struct platform_device *pdev,
			struct milbeaut_pinctrl *pctl,
			int func_no)
{
	int irq, j;
	int ret = 0;

	for (j = 0;
		j < pctl->milb_functions[func_no].pin_list_num;
		j++) {
		/* initialize */
		pctl->fpint[pctl->fpint_counter].irq
			= FPINT_INVALID;
		pctl->fpint[pctl->fpint_counter].pin
			= FPINT_INVALID;
		snprintf(
			pctl->fpint[pctl->fpint_counter].irqname, 8,
			"pin-%u", pctl->milb_functions[func_no].pin_list[j]);
		irq = platform_get_irq_byname(
			pdev, pctl->fpint[pctl->fpint_counter].irqname);
		if (irq < 0) {
			Print_debug("%s %s %d, No irq %s,pin:%u\n"
				, __FILE__, __func__, __LINE__,
				pctl->fpint[pctl->fpint_counter].irqname,
				pctl->milb_functions[func_no].pin_list[j]);
			pctl->fpint[pctl->fpint_counter].irqname[0] = 0;
		} else {
			pctl->fpint[pctl->fpint_counter].irq = irq;
			pctl->fpint[pctl->fpint_counter].pin =
				pctl->milb_functions[func_no].pin_list[j];
			ret = register_irq(pdev, pctl, pctl->fpint_counter);
			if (ret != 0)
				break;
			pctl->fpint_counter++;
		}
	}
	return ret;
}

/*
 * Get memory of the variable named fpint.
 * The nums is the total child nodes. Though it may
 * not be used if there are not any interrupt at some children.
 * Register IRQ domain.
 */
static int set_gpio_interrupt(struct platform_device *pdev,
				struct milbeaut_pinctrl *pctl)
{
	int i;
	int ret = 0;
	struct device_node *np = pdev->dev.of_node;
	int pin_list_num = 0;

	for (i = 1; i <= pctl->func_nums; i++)
		pin_list_num += pctl->milb_functions[i].pin_list_num;

	if (pin_list_num == 0)
		goto err;

	pctl->fpint =
		devm_kzalloc(&pdev->dev,
			pin_list_num * sizeof(*pctl->fpint),
			GFP_KERNEL);
	if (!pctl->fpint) {
		ret = -ENOMEM;
		goto err;
	}
	pctl->fpint_counter = 0;
	pctl->irqdom = irq_domain_add_linear(np, pctl->tpins,
						&irq_domain_simple_ops, pctl);
	for (i = 1; i <= pctl->func_nums; i++)
		set_fpint(pdev, pctl, i);
err:
	return ret;
}

static int milbeaut_pinctrl_probe(struct platform_device *pdev)
{
	struct device_node *np = pdev->dev.of_node;
	struct pinctrl_dev *pctl_dev;
	struct milbeaut_pinctrl *pctl;
	struct pinctrl_desc *pd;
	struct gpio_chip *gc;
	struct resource *res;
	int ret = 0;
	const struct of_device_id *match;

	Print_debug("%s %s %d\n", __FILE__, __func__, __LINE__);
	pctl = devm_kzalloc(&pdev->dev,	sizeof(*pctl), GFP_KERNEL);
	if (!pctl) {
		ret = -ENOMEM;
		goto err;
	}
	match = of_match_device(milbeaut_pmatch, &pdev->dev);
	if (!match) {
		ret = -ENODEV;
		goto err;
	}

	pctl->pinctrl_param = (struct mlb_pinctrl_param *)match->data;
	pd = &pctl->pd;
	gc = &pctl->gc;
	spin_lock_init(&pctl->lock);
	spin_lock_init(&pctl->irq_lock);
	res = platform_get_resource_byname(pdev, IORESOURCE_MEM, "pinctrl");
	pctl->base = devm_ioremap_resource(&pdev->dev, res);
	if (!pctl->base) {
		ret = -EINVAL;
		goto err;
	}
	/* Get bank */
	ret = get_bank(pdev, pctl);
	if (ret != 0) {
		dev_err(&pdev->dev, "%s %s %d\n",
			__FILE__, __func__, __LINE__);
		goto err;
	}
	/* absent or incomplete entries allow all access */
	if (of_property_read_bool(np, "blacklist")) {
		ret = milbeaut_gpio_get_blacklist(pdev, pctl, pctl->tbanks);
		if (ret)
			goto err;
	}

	pd->name = dev_name(&pdev->dev);
	pd->pins = pctl->pins;
	pd->npins = pctl->tpins;
	pd->pctlops = &milbeaut_pctrl_ops;
	pd->pmxops = &milbeaut_pmx_ops;
	pd->confops = &milbeaut_pconf_ops;
	pd->owner = THIS_MODULE;
	pctl_dev = pinctrl_register(pd, &pdev->dev, pctl);
	if (!pctl_dev) {
		dev_err(&pdev->dev, "couldn't register pinctrl driver\n");
		ret = -EINVAL;
		goto err;
	}
	Print_debug("%s %s %d,name:%s tpins:%d\n",
			__FILE__, __func__, __LINE__,
			pd->name,
			pd->npins);

	/* Set interrupt */
	set_gpio_interrupt(pdev, pctl);


	platform_set_drvdata(pdev, pctl);

	gc->base = -1;
	gc->ngpio = pctl->tpins;
	gc->label = dev_name(&pdev->dev);
	gc->owner = THIS_MODULE;
	gc->of_node = np;
	gc->direction_input = milbeaut_gpio_direction_input;
	gc->direction_output = milbeaut_gpio_direction_output;
	gc->get = milbeaut_gpio_get;
	gc->set = milbeaut_gpio_set;
	gc->to_irq = milbeaut_gpio_to_irq;
	gc->request = gpiochip_generic_request;
	gc->free = gpiochip_generic_free;
	ret = gpiochip_add(gc);
	if (ret) {
		dev_err(&pdev->dev, "Failed register gpiochip\n");
		goto err;
	}

	ret = gpiochip_add_pin_range(gc, dev_name(&pdev->dev),
					0, 0, pctl->tpins);
	if (ret) {
		dev_err(&pdev->dev, "Failed to add pin range\n");
		gpiochip_remove(gc);
		goto err;
	}
	Print_debug("%s %s %d,name:%s ngpio:%d\n",
			__FILE__, __func__, __LINE__,
			gc->label,
			gc->ngpio);

err:
	return ret;

}
static struct platform_driver milbeaut_pinctrl_driver = {
	.probe	= milbeaut_pinctrl_probe,
#ifdef CONFIG_PM_SLEEP
	.suspend = milbeaut_pinctrl_suspend,
	.resume = milbeaut_pinctrl_resume,
#endif
	.driver	= {
		.name		= "milbeaut-pinctrl-karine",
		.of_match_table	= milbeaut_pmatch,
	},
};

static int __init milbeaut_pinctrl_init(void)
{
	return platform_driver_register(&milbeaut_pinctrl_driver);
}
arch_initcall(milbeaut_pinctrl_init);

