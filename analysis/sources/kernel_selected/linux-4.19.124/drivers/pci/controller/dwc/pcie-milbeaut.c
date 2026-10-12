// SPDX-License-Identifier: GPL-2.0
/*
 * PCIe host controller driver for Milbeaut SoCs
 * Copyright 2019 Socionext Inc.
 * Author: Taichi Sugaya <<REDACTED_EMAIL>>
 *
 * Copyright (c) 2020 Panasonic Corporation
 * 2020-07-16 Modified
 *
 * This file may be used subject to the terms and conditions of the
 * GNU General Public License Version 2, or any later version
 * at your option, as published by the Free Software Foundation.
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 */

#include <linux/bitfield.h>
#include <linux/bitops.h>
#include <linux/clk.h>
#include <linux/delay.h>
#include <linux/gpio.h>
#include <linux/gpio/consumer.h>
#include <linux/interrupt.h>
#include <linux/irqchip/chained_irq.h>
#include <linux/irqdomain.h>
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/init.h>
#include <linux/of_device.h>
#include <linux/of_gpio.h>
#include <linux/of_irq.h>
#include <linux/pci.h>
#include <linux/platform_device.h>
#include <linux/resource.h>
#include <linux/signal.h>
#include <linux/types.h>
#include <linux/regmap.h>
#include <linux/reset.h>
#include <linux/pci_regs.h>

#include "pcie-designware.h"
#include "pcie-milbeaut-cfg.h"

#ifdef CONFIG_PCIE_MILBEAUT_MANUAL_LINK_OPE

//#define MILBEAUT_PCIE_LINK_CDEV_ENABLE

#ifdef MILBEAUT_PCIE_LINK_CDEV_ENABLE
#include <linux/io.h>
#include <linux/ioctl.h>
#include <linux/cdev.h>
#include <linux/milbeaut_pcie_drv.h>

#define MILBEAUT_PCIE_LINK_MAJOR		(230)
#define MILBEAUT_PCIE_LINK_MINOR_BASE	(0)
#define MILBEAUT_PCIE_LINK_MINOR_NUM	(1)
#define MILBEAUT_PCIE_LINK_DEVICE_NAME	"mbt_pcie_linkstat"
#endif
#endif /* CONFIG_PCIE_MILBEAUT_MANUAL_LINK_OPE */

/* apb regs */
#define MLB_GEN_CTRL_3				0x58
#define MLB_LTSSM_EN					BIT(0)

#define MLB_GEN_CTRL_4				0x5C
#define MLB_LTSSM_CLR_MASK				BIT(30)

#define MLB_ERR_STS					0xE0
#define MLB_LINK_DOWN_INT_STS			BIT(30)
#define MLB_SUP_LINK_DOWN_INT_STS		BIT(29)
#define MLB_ERR_INT_CTRL			0xE4
#define MLB_LINK_DOWN_INT_EN			BIT(30)
#define MLB_SUP_LINK_DOWN_INT_EN		BIT(29)

#define MLB_INT_STS					0xE8
#define MLB_RADM_INT_EN_SHIFT		  28
#define MLB_RADM_INTERRUPTS_EN		  GENMASK(31, 28)
#define MLB_RADM_INTA_EN				BIT(31)
#define MLB_RADM_INTB_EN				BIT(30)
#define MLB_RADM_INTC_EN				BIT(29)
#define MLB_RADM_INTD_EN				BIT(28)
#define MLB_RADM_INT_STS_SHIFT		  12
#define MLB_RADM_INTERRUPTS_STS		  GENMASK(15, 12)
#define MLB_RADM_INTA_STS				BIT(15)
#define MLB_RADM_INTB_STS				BIT(14)
#define MLB_RADM_INTC_STS				BIT(13)
#define MLB_RADM_INTD_STS				BIT(12)
#define MLB_LINK_EQ_REQ_INT_STS			BIT(10)
#define MLB_BW_MGT_INT_STS				BIT(9)
#define MLB_LINK_AUTO_BW_INT_STS		BIT(8)
#define MLB_SYS_ERR_RC_STS				BIT(7)
#define MLB_HP_INT_STS					BIT(6)
#define MLB_PME_INT_STS					BIT(5)
#define MLB_AER_RC_ERR_INT_STS			BIT(4)
#define MLB_ERR_INT_STS					BIT(2)
#define MLB_RX_MSG_INT_STS				BIT(1)
#define MLB_BEACON_INT_STS				BIT(0)
#define MLB_MISC2MSI_INT_STS		 (MLB_PME_INT_STS | MLB_AER_RC_ERR_INT_STS | MLB_HP_INT_STS)

#define MLB_LINK_DBG_2				0xB4
#define MLB_RDLH_LINK_UP				BIT(7)
#define MLB_SMLH_LINK_UP				BIT(6)

/* pci dbi data */
#define MLB_PCIE_COHE_CNT3			0x8E8
#define MLB_PCI_EXP_CAP				0x70
#define MLB_SLOT_CAP				0x84
#define MLB_SLOT_STATUS				0x88
#define MLB_PCI_EXP_RTCTL			0x8c
#define MLB_ROOT_ERR_CMD_OFF		0x12c
#define MLB_L1SUB_CAP				0x160
#define MLB_PCIE_AUX_CLK_FREQ		0xB40

/* other data */
#define MLB_SHADOW_REG_OFFSET		0x100000
#define MLB_M20V_CPU2BUS_MASK		0x7FFFFF
#define MLB_KARINE_CPU2BUS_MASK		0xFFFFFFFF

#define MLB_PCIE_VENDOR_ID			0x1189
#define MLB_PCIE_DEVICE_ID			0xABCD

enum {
	MLB_PCIE_RC_WITHOUT_BIFUR = 0,
	MLB_PCIE_RC_WITH_BIFUR,
	MLB_PCIE_EP,
	MLB_PCIE_RC_KARINE,
	MLB_PCIE_EP_KARINE
};

enum {
	MLB_PCIE_CID_0 = 0,
	MLB_PCIE_CID_1,

	NUM_OF_MLB_PCIE_CONTROLLERS
};

struct milbeaut_pcie_priv {
	struct dw_pcie			pci;
	struct platform_device  *pdev;
	void __iomem			*base;	// APB registers on EXS
	struct clk				*clk_main;
	struct clk				*clk_bus;
	struct reset_control	*rst_pwr;
	struct reset_control	*rst_soft;
	struct reset_control	*bifu_en;
	struct reset_control	*rcdev;
	struct irq_domain		*lgc_irqd;
	struct gpio_desc		*prsnt2;
	u64						cpu2bus_mask;
	u32						dev_type;
	struct delayed_work		cmd_handler;
	bool					enabled;
};

struct milbeaut_pcie_cap {
	u32 aer;
	u32 pme;
	u32 pciehp;
};

struct milbeaut_pcie_device_ioctl_param {
	int	pcie_controller_id;
};

#define to_milbeaut_pcie(x)	dev_get_drvdata((x)->dev)

static const struct of_device_id milbeaut_pcie_of_match[];

static void milbeaut_pcie_write_ids(struct dw_pcie *pci)
{
	u32 vid,pid,setting_id;
	struct device *dev = pci->dev;
	struct device_node *np = dev->of_node;
	int ret;

	ret = of_property_read_u32(np, "vendorID", &vid);
	if (ret) vid = MLB_PCIE_VENDOR_ID;
	ret = of_property_read_u32(np, "deviceID", &pid);
	if (ret) pid = MLB_PCIE_DEVICE_ID;

	setting_id = dw_pcie_readw_dbi(pci, PCI_VENDOR_ID);
	if(setting_id != vid){
		dw_pcie_dbi_ro_wr_en(pci);
		dw_pcie_writew_dbi(pci, PCI_VENDOR_ID, vid);
		dw_pcie_dbi_ro_wr_dis(pci);
	}

	setting_id = dw_pcie_readw_dbi(pci, PCI_DEVICE_ID);
	if(setting_id != pid){
		dw_pcie_dbi_ro_wr_en(pci);
		dw_pcie_writew_dbi(pci, PCI_DEVICE_ID, pid);
		dw_pcie_dbi_ro_wr_dis(pci);
	}
}


#ifdef CONFIG_PCIE_MILBEAUT_MANUAL_LINK_OPE
static bool milbeaut_pcie_1st_link_up[NUM_OF_MLB_PCIE_CONTROLLERS]= { false, false };

static bool milbeaut_pcie_check_never_linkup(int cid)
{
	if (milbeaut_pcie_1st_link_up[cid]) {
		return false;
	}
	return true;
}

static void milbeaut_pcie_update_linkup_history(int cid)
{
	milbeaut_pcie_1st_link_up[cid] = true;
}
#endif

static struct milbeaut_pcie_priv *mlb_pcie_priv_memo[NUM_OF_MLB_PCIE_CONTROLLERS] = { NULL, NULL };

static void milbeaut_pcie_clear_priv(int cid)
{
	mlb_pcie_priv_memo[cid] = NULL;
}

static void milbeaut_pcie_save_priv(int cid, struct milbeaut_pcie_priv *priv)
{
	mlb_pcie_priv_memo[cid] = priv;
}

static struct milbeaut_pcie_priv *milbeaut_pcie_restore_priv(int cid)
{
	return mlb_pcie_priv_memo[cid];
}

static char	*milbeaut_pcie_node_full_name[NUM_OF_MLB_PCIE_CONTROLLERS] = {
/* MLB_PCIE_CID_0 */	"pcie@1b000000",
/* MLB_PCIE_CID_1 */	"pcie@1b400000"
};

int milbeaut_pcie_get_controller_id(struct device *dev)
{
	const struct device_node *node;
	int i;

	node = dev->of_node;
	if (!node)
		return -1;

	for (i = 0; i < NUM_OF_MLB_PCIE_CONTROLLERS; i++) {
		if (strcmp(node->full_name, milbeaut_pcie_node_full_name[i]) == 0) break;
	}
	if (i < NUM_OF_MLB_PCIE_CONTROLLERS) {
//		printk(">> fulll_name : %s (%d)\n", milbeaut_pcie_node_full_name[i], i);
		return i;
	}
	return -1;
}

static int milbeaut_pcie_gen_type [NUM_OF_MLB_PCIE_CONTROLLERS] = { 0, 0 };
static int milbeaut_pcie_num_lanes[NUM_OF_MLB_PCIE_CONTROLLERS] = { 0, 0 };

static void milbeaut_pcie_set_gen_type(int cid, int gen_num)
{
	milbeaut_pcie_gen_type[cid] = gen_num;
}

int milbeaut_pcie_get_gen_type(int cid)
{
	return milbeaut_pcie_gen_type[cid];
}

static void milbeaut_pcie_set_num_lanes(int cid, int lane_num)
{
	milbeaut_pcie_num_lanes[cid] = lane_num;
}

int milbeaut_pcie_get_num_lanes(int cid)
{
	return milbeaut_pcie_num_lanes[cid];
}

void milbeaut_pcie_select_deemphasis(struct dw_pcie *pci)
{
	u32 val;

	val = dw_pcie_readl_dbi(pci, PCIE_LINK_WIDTH_SPEED_CONTROL);
	val &= ~PORT_LOGIC_DEEMPHASIS_MASK;
	val |= PORT_LOGIC_DEEMPHASIS;
	dw_pcie_writel_dbi(pci,PCIE_LINK_WIDTH_SPEED_CONTROL,val);
}
EXPORT_SYMBOL(milbeaut_pcie_select_deemphasis);

void milbeaut_pcie_compliance_enable(struct dw_pcie *pci, bool enable)
{
	u32 val;

	dw_pcie_read(pci->dbi_base + EXP_CAP_ID_OFFSET + PCI_EXP_LNKCTL2, 2, &val);

	if(enable){
		val |= PCI_EXP_LNKCTL2_EN_CMPTST;
	}else{
		val &= ~PCI_EXP_LNKCTL2_EN_CMPTST;
	}
	dw_pcie_write(pci->dbi_base + EXP_CAP_ID_OFFSET + PCI_EXP_LNKCTL2, 2,val);
}
EXPORT_SYMBOL(milbeaut_pcie_compliance_enable);

void milbeaut_pcie_loopback_enable(struct dw_pcie *pci, bool enable)
{
	u32 val;

	val = dw_pcie_readl_dbi(pci, PCIE_PORT_LINK_CONTROL);

	if(enable){
		val |= PCIE_LOOPBACK_ENABLE;
	}else{
		val &= ~PCIE_LOOPBACK_ENABLE;
	}
	dw_pcie_writel_dbi(pci, PCIE_PORT_LINK_CONTROL, val);
}
EXPORT_SYMBOL(milbeaut_pcie_loopback_enable);

void milbeaut_pcie_get_current_gen_lane(int cid, unsigned int *gen_num, unsigned int *lane_num)
{
	u32 val;
	struct milbeaut_pcie_priv *priv = milbeaut_pcie_restore_priv(cid);
	struct dw_pcie *pci = &priv->pci;

	dw_pcie_read(pci->dbi_base + EXP_CAP_ID_OFFSET + PCI_EXP_LNKSTA, 2, &val);

	*gen_num  = val & PCI_EXP_LNKSTA_CLS;
	*lane_num = ((val & PCI_EXP_LNKSTA_NLW) >> 4);
}
EXPORT_SYMBOL(milbeaut_pcie_get_current_gen_lane);


void milbeaut_pcie_get_max_gen_lane(int cid, unsigned int *gen_num, unsigned int *lane_num)
{
	u32 val;
	struct milbeaut_pcie_priv *priv = milbeaut_pcie_restore_priv(cid);
	struct dw_pcie *pci = &priv->pci;

	dw_pcie_read(pci->dbi_base + EXP_CAP_ID_OFFSET + PCI_EXP_LNKCAP, 2, &val);

	*gen_num  = val & PCI_EXP_LNKCAP_SLS;
	*lane_num = ((val & PCI_EXP_LNKCAP_MLW) >> 4);
}
EXPORT_SYMBOL(milbeaut_pcie_get_max_gen_lane);

int milbeaut_pcie_set_gen_lane(int cid, unsigned int gen_num, unsigned int lane_num)
{
	if((gen_num < 1) || (gen_num > 3)) {
		return -EINVAL;
	}
	switch(lane_num) {
		case 1:
		case 2:
		case 4:
			break;
		default:
			return -EINVAL;
	}

	milbeaut_pcie_set_gen_type(cid, gen_num);
	milbeaut_pcie_set_num_lanes(cid, lane_num);

	return 0;
}
EXPORT_SYMBOL(milbeaut_pcie_set_gen_lane);

int milbeaut_pcie_direct_gen_change(int cid, unsigned int gen_num)
{
	unsigned int val;
	struct milbeaut_pcie_priv *priv = milbeaut_pcie_restore_priv(cid);
	struct dw_pcie *pci = &priv->pci;

	val = dw_pcie_readl_dbi(pci, PCIE_LCTLSTS2);
	val &= ~PCIE_LCTLSTS2_TGT_LINK_SPEED;

	switch (gen_num) {
	case 1:
		val |= PCIE_LCTLSTS2_TGT_LINK_SPEED_25GT;
		break;
	case 2:
		val |= PCIE_LCTLSTS2_TGT_LINK_SPEED_5GT;
		break;
	case 3:
		val |= PCIE_LCTLSTS2_TGT_LINK_SPEED_8GT;
		break;
//	case 4:
//		val |= PCIE_LCTLSTS2_TGT_LINK_SPEED_16GT;
//		break;
	default:
		dev_err(pci->dev, "GEN %u: invalid value\n", gen_num);
		return -EINVAL;
	}

	dw_pcie_writel_dbi(pci, PCIE_LCTLSTS2, val);

	val = dw_pcie_readl_dbi(pci, PCIE_LINK_WIDTH_SPEED_CONTROL);
	val |= PORT_LOGIC_SPEED_CHANGE;
	dw_pcie_writel_dbi(pci, PCIE_LINK_WIDTH_SPEED_CONTROL, val);

	return 0;
}
EXPORT_SYMBOL(milbeaut_pcie_direct_gen_change);

int milbeaut_pcie_direct_lane_change(int cid, unsigned int lane_num)
{
	unsigned int val;
	struct milbeaut_pcie_priv *priv = milbeaut_pcie_restore_priv(cid);
	struct dw_pcie *pci = &priv->pci;

	/* UpConfigure Multi-lane Control Register lane setting */
	val  = dw_pcie_readl_dbi(pci, PCIE_MULTI_LANE_CONTROL);
	val &= ~PORT_MULTI_LINK_WIDTH_MASK;
	val |=  lane_num;
	val |=  PORT_MULTI_LINK_WIDTH_CHANGE;

	dw_pcie_writel_dbi(pci, PCIE_MULTI_LANE_CONTROL, val);

	return 0;
}
EXPORT_SYMBOL(milbeaut_pcie_direct_lane_change);


static void milbeaut_pcie_ltssm_enable(struct milbeaut_pcie_priv *priv,
				       bool enable)
{
	u32 val;

	val = readl(priv->base + MLB_GEN_CTRL_3);
	if (enable)
		val |= MLB_LTSSM_EN;
	else
		val &= ~MLB_LTSSM_EN;
	writel(val, priv->base + MLB_GEN_CTRL_3);
}

#ifndef CONFIG_PCIE_MILBEAUT_MANUAL_LINK_OPE
static void milbeaut_pcie_irq_enable(struct milbeaut_pcie_priv *priv)
{
	u32 val;

	val = MLB_RADM_INTERRUPTS_EN;
	writel(val, priv->base + MLB_INT_STS);

	val = MLB_LINK_DOWN_INT_EN | MLB_SUP_LINK_DOWN_INT_EN;
	writel(val, priv->base + MLB_ERR_INT_CTRL);
}

static void milbeaut_pcie_irq_disable(struct milbeaut_pcie_priv *priv)
{
	writel(0, priv->base + MLB_INT_STS);
	writel(0, priv->base + MLB_ERR_INT_CTRL);
}
#endif

static void milbeaut_pcie_irq_ack(struct irq_data *d)
{
	struct pcie_port *pp = irq_data_get_irq_chip_data(d);
	struct dw_pcie *pci = to_dw_pcie_from_pp(pp);
	struct milbeaut_pcie_priv *priv = to_milbeaut_pcie(pci);
	u32 val;

	val = readl(priv->base + MLB_INT_STS);
	val &= ~MLB_RADM_INTERRUPTS_STS;
	val |= BIT(irqd_to_hwirq(d) + MLB_RADM_INT_STS_SHIFT);
	writel(val, priv->base + MLB_INT_STS);
}

static void milbeaut_pcie_irq_mask(struct irq_data *d)
{
	struct pcie_port *pp = irq_data_get_irq_chip_data(d);
	struct dw_pcie *pci = to_dw_pcie_from_pp(pp);
	struct milbeaut_pcie_priv *priv = to_milbeaut_pcie(pci);
	u32 val;

	val = readl(priv->base + MLB_INT_STS);
	val &= ~MLB_RADM_INTERRUPTS_EN;
	val &= ~BIT(irqd_to_hwirq(d) + MLB_RADM_INT_EN_SHIFT);
	writel(val, priv->base + MLB_INT_STS);
}

static void milbeaut_pcie_irq_unmask(struct irq_data *d)
{
	struct pcie_port *pp = irq_data_get_irq_chip_data(d);
	struct dw_pcie *pci = to_dw_pcie_from_pp(pp);
	struct milbeaut_pcie_priv *priv = to_milbeaut_pcie(pci);
	u32 val;

	val = readl(priv->base + MLB_INT_STS);
	val &= ~MLB_RADM_INTERRUPTS_EN;
	val |= BIT(irqd_to_hwirq(d) + MLB_RADM_INT_EN_SHIFT);
	writel(val, priv->base + MLB_INT_STS);
}

static struct irq_chip milbeaut_pcie_irq_chip = {
	.name = "PCI",
	.irq_ack = milbeaut_pcie_irq_ack,
	.irq_mask = milbeaut_pcie_irq_mask,
	.irq_unmask = milbeaut_pcie_irq_unmask,
};

static int milbeaut_pcie_intx_map(struct irq_domain *domain, unsigned int irq,
				  irq_hw_number_t hwirq)
{
	irq_set_chip_and_handler(irq, &milbeaut_pcie_irq_chip,
				 handle_level_irq);
	irq_set_chip_data(irq, domain->host_data);

	return 0;
}

static const struct irq_domain_ops milbeaut_intx_domain_ops = {
	.map = milbeaut_pcie_intx_map,
};

static void milbeaut_add_capabilities(struct dw_pcie *pci)
{
	u32 val;

	dw_pcie_dbi_ro_wr_en(pci);
	dw_pcie_writel_dbi(pci, MLB_SLOT_CAP,
			   PCI_EXP_SLTCAP_HPC | PCI_EXP_SLTCAP_HPS);
	val = dw_pcie_readl_dbi(pci, MLB_PCI_EXP_CAP);
	val |= (PCI_EXP_FLAGS_SLOT << 16);
	dw_pcie_writel_dbi(pci, MLB_PCI_EXP_CAP, val);
	dw_pcie_dbi_ro_wr_dis(pci);
}

static void milbeaut_save_capabilities_en(struct dw_pcie *pci,
					  struct milbeaut_pcie_cap *cap)
{
	if (IS_ENABLED(CONFIG_PCIEAER))
		cap->aer = dw_pcie_readl_dbi(pci, MLB_ROOT_ERR_CMD_OFF);
	if (IS_ENABLED(CONFIG_PCIE_PME))
		cap->pme = dw_pcie_readl_dbi(pci, MLB_PCI_EXP_RTCTL);
	if (IS_ENABLED(CONFIG_HOTPLUG_PCI_PCIE))
		cap->pciehp = dw_pcie_readl_dbi(pci, MLB_SLOT_STATUS);
}

static void milbeaut_restore_capabilities_en(struct dw_pcie *pci,
					  struct milbeaut_pcie_cap *cap)
{
	u32 val;

	if (IS_ENABLED(CONFIG_PCIEAER)) {
		val = dw_pcie_readl_dbi(pci, MLB_ROOT_ERR_CMD_OFF);
		val &= ~GENMASK(2, 0);
		val |= cap->aer;
		dw_pcie_writel_dbi(pci, MLB_ROOT_ERR_CMD_OFF, val);
	}
	if (IS_ENABLED(CONFIG_PCIE_PME)) {
		val = dw_pcie_readl_dbi(pci, MLB_PCI_EXP_RTCTL);
		val &= ~BIT(3);
		val |= cap->pme;
		dw_pcie_writel_dbi(pci, MLB_PCI_EXP_RTCTL, val);
	}
	if (IS_ENABLED(CONFIG_HOTPLUG_PCI_PCIE)) {
		val = dw_pcie_readl_dbi(pci, MLB_SLOT_STATUS);
		val &= ~GENMASK(15, 0);
		val |= cap->pciehp;
		dw_pcie_writel_dbi(pci, MLB_SLOT_STATUS, val);
	}
}

static void milbeaut_serve_ref_clock(struct dw_pcie *pci)
{
	u32 pos, val;

	for (pos = MLB_L1SUB_CAP; pos <= MLB_L1SUB_CAP + 16; pos = pos + 16) {
		val = dw_pcie_readl_dbi(pci, pos);
		if (FIELD_GET(GENMASK(15, 0), val) == PCI_EXT_CAP_ID_L1SS)
			break;
	}
	if (pos == MLB_L1SUB_CAP + 32)
		dev_err(pci->dev, "L1SS_CAP not exist\n");
	else {
		val = dw_pcie_readl_dbi(pci, pos + PCI_L1SS_CTL1);
		val |= PCI_L1SS_CTL1_L1SS_MASK;
		dw_pcie_writel_dbi(pci, pos + PCI_L1SS_CTL1, val);
	}
}

static void milbeaut_speed_change_control(struct dw_pcie *pci)
{
	u32 val, i;

	for (i = 0; i < 10; i++) {
		val = dw_pcie_readl_dbi(pci, PCIE_LINK_WIDTH_SPEED_CONTROL);
		val |= PORT_LOGIC_SPEED_CHANGE;
		dw_pcie_writel_dbi(pci, PCIE_LINK_WIDTH_SPEED_CONTROL, val);
		usleep_range(9000, 10000);
		val = dw_pcie_readl_dbi(pci, PCIE_LINK_WIDTH_SPEED_CONTROL);
		if (val & PORT_LOGIC_SPEED_CHANGE)
			return;
	}
	dev_err(pci->dev, "can't verify PORT_LOGIC_SPEED_CHANGE or linkup has finished\n");
}

void milbeaut_pcie_restart(struct work_struct *work)
{
	struct milbeaut_pcie_priv *priv = container_of(work,
					  struct milbeaut_pcie_priv,
					  cmd_handler.work);
	struct dw_pcie *pci = &priv->pci;
	struct milbeaut_pcie_cap cap;

	milbeaut_save_capabilities_en(pci, &cap);
	milbeaut_pcie_ltssm_enable(priv, true);
	milbeaut_restore_capabilities_en(pci, &cap);
	milbeaut_serve_ref_clock(pci);
	milbeaut_speed_change_control(pci);
}

static u32 milbeaut_pcie_misc_isr(struct pcie_port *pp)
{
	struct dw_pcie *pci = to_dw_pcie_from_pp(pp);
	struct milbeaut_pcie_priv *priv = to_milbeaut_pcie(pci);
	u32 val, virq;

	val = readl(priv->base + MLB_INT_STS);
	if (val & MLB_LINK_EQ_REQ_INT_STS)
		dev_dbg(pci->dev, "LINK_EQ_REQ_INT\n");
	if (val & MLB_BW_MGT_INT_STS)
		dev_dbg(pci->dev, "BW_MGT_INT\n");
	if (val & MLB_LINK_AUTO_BW_INT_STS)
		dev_dbg(pci->dev, "LINK_AUTO_BW_INT\n");
	if (val & MLB_SYS_ERR_RC_STS)
		dev_dbg(pci->dev, "SYS_ERR_RC\n");
	if (val & MLB_ERR_INT_STS)
		dev_dbg(pci->dev, "ERR_INT\n");
	if (val & MLB_RX_MSG_INT_STS)
		dev_dbg(pci->dev, "RX_MSG_INT\n");
	if (val & MLB_BEACON_INT_STS)
		dev_dbg(pci->dev, "BEACON_INT\n");

	if (pci_msi_enabled() && (val & MLB_MISC2MSI_INT_STS)) {
		if (val & MLB_HP_INT_STS)
			dev_dbg(pci->dev, "HP_INT\n");
		if (val & MLB_PME_INT_STS)
			dev_dbg(pci->dev, "PME_INT\n");
		if (val & MLB_AER_RC_ERR_INT_STS)
			dev_dbg(pci->dev, "AER_RC_ERR_INT\n");
		virq = irq_linear_revmap(pp->irq_domain, 0);
		generic_handle_irq(virq);
	}

	return val;
}

static void milbeaut_pcie_irq_handler(struct irq_desc *desc)
{
	struct pcie_port *pp = irq_desc_get_handler_data(desc);
	struct dw_pcie *pci = to_dw_pcie_from_pp(pp);
	struct milbeaut_pcie_priv *priv = to_milbeaut_pcie(pci);
	struct irq_chip *chip = irq_desc_get_chip(desc);
	unsigned long reg;
	u32 val, bit, virq;

	/* link down INT for debug */
	val = readl(priv->base + MLB_ERR_STS);
#ifndef CONFIG_PCIE_MILBEAUT_MANUAL_LINK_OPE
	if (val & MLB_LINK_DOWN_INT_STS) {
		dev_dbg(pci->dev, "link_down occurs\n");
		schedule_delayed_work(&priv->cmd_handler,
				      msecs_to_jiffies(100));
	}
	if (val & MLB_SUP_LINK_DOWN_INT_STS)
		dev_dbg(pci->dev, "surprise_link_down occurs\n");
#endif
	writel(val, priv->base + MLB_ERR_STS);

	val = milbeaut_pcie_misc_isr(pp);

	reg = FIELD_GET(MLB_RADM_INTERRUPTS_STS, val);
	val &= ~MLB_RADM_INTERRUPTS_STS;
	writel(val, priv->base + MLB_INT_STS);

	/* INTx */
	chained_irq_enter(chip, desc);

	for_each_set_bit(bit, &reg, PCI_NUM_INTX) {
		virq = irq_linear_revmap(priv->lgc_irqd, bit);
		generic_handle_irq(virq);
	}

	chained_irq_exit(chip, desc);
}

static int milbeaut_pcie_config_legacy_irq(struct pcie_port *pp)
{
	struct dw_pcie *pci = to_dw_pcie_from_pp(pp);
	struct milbeaut_pcie_priv *priv = to_milbeaut_pcie(pci);
	struct device_node *np = pci->dev->of_node;
	struct device_node *np_intc;

	np_intc = of_get_child_by_name(np, "legacy-interrupt-controller");
	if (!np_intc) {
		dev_err(pci->dev, "Failed to get legacy-interrupt-controller node\n");
		return -EINVAL;
	}

	pp->irq = irq_of_parse_and_map(np_intc, 0);
	if (!pp->irq) {
		dev_err(pci->dev, "Failed to get an IRQ entry in legacy-interrupt-controller\n");
		return -EINVAL;
	}

	priv->lgc_irqd = irq_domain_add_linear(np_intc, PCI_NUM_INTX,
					       &milbeaut_intx_domain_ops, pp);
	if (!priv->lgc_irqd) {
		dev_err(pci->dev, "Failed to get INTx domain\n");
		return -ENODEV;
	}

	irq_set_chained_handler_and_data(pp->irq,
					 milbeaut_pcie_irq_handler,
					 pp);

	return 0;
}

static void milbeaut_pcie_stop_link(struct dw_pcie *pci)
{
	struct milbeaut_pcie_priv *priv = to_milbeaut_pcie(pci);

	milbeaut_pcie_ltssm_enable(priv, false);
}

static void dw_plat_set_num_vectors(struct pcie_port *pp)
{
	pp->num_vectors = MAX_MSI_IRQS;
}

static int milbeaut_pcie_establish_link(struct dw_pcie *pci)
{
	struct milbeaut_pcie_priv *priv = to_milbeaut_pcie(pci);

	if (dw_pcie_link_up(pci))
		return 0;

	milbeaut_pcie_ltssm_enable(priv, true);

	return dw_pcie_wait_for_link(pci);
}

static int milbeaut_pcie_link_up(struct dw_pcie *pci)
{
	struct milbeaut_pcie_priv *priv = to_milbeaut_pcie(pci);
	u32 val, mask;

	val = readl(priv->base + MLB_LINK_DBG_2);
	mask = MLB_RDLH_LINK_UP | MLB_SMLH_LINK_UP;

	return (val & mask) == mask;
}

static u64 milbeaut_pcie_cpu_addr_fixup(struct dw_pcie *pci, u64 pci_addr)
{
	struct milbeaut_pcie_priv *priv = to_milbeaut_pcie(pci);
	return pci_addr & priv->cpu2bus_mask;
}

static const struct dw_pcie_ops milbeaut_pcie_ops = {
	.cpu_addr_fixup = milbeaut_pcie_cpu_addr_fixup,
	.start_link = milbeaut_pcie_establish_link,
	.stop_link = milbeaut_pcie_stop_link,
	.link_up = milbeaut_pcie_link_up,
};

static int milbeaut_pcie_host_init(struct pcie_port *pp)
{
	struct dw_pcie *pci = to_dw_pcie_from_pp(pp);
#ifndef CONFIG_PCIE_MILBEAUT_MANUAL_LINK_OPE
	struct milbeaut_pcie_priv *priv = to_milbeaut_pcie(pci);
#endif
	int ret;

#ifndef CONFIG_PCIE_MILBEAUT_MANUAL_LINK_OPE
	ret = milbeaut_pcie_config_legacy_irq(pp);
	if (ret)
		return ret;

	milbeaut_pcie_irq_enable(priv);
#endif

	dw_pcie_setup_rc(pp);

	milbeaut_pcie_write_ids(pci);

	ret = milbeaut_pcie_establish_link(pci);
	if (ret)
		dev_info(pci->dev, "But probe goes on\n");

	if (IS_ENABLED(CONFIG_PCI_MSI))
		dw_pcie_msi_init(pp);

#ifndef CONFIG_PCIE_MILBEAUT_MANUAL_LINK_OPE
	return 0;
#else
	return ret;
#endif
}

static const struct dw_pcie_host_ops milbeaut_pcie_host_ops = {
	.host_init = milbeaut_pcie_host_init,
	.set_num_vectors = dw_plat_set_num_vectors,
};

static int milbeaut_add_pcie_port(struct milbeaut_pcie_priv *priv,
				  struct platform_device *pdev)
{
	struct dw_pcie *pci = &priv->pci;
	struct pcie_port *pp = &pci->pp;
	struct device *dev = &pdev->dev;
	int ret;

	pp->ops = &milbeaut_pcie_host_ops;

	if (IS_ENABLED(CONFIG_PCI_MSI)) {
		pp->msi_irq = platform_get_irq_byname(pdev, "msi");
		if (pp->msi_irq < 0)
			return pp->msi_irq;
	}

	/* Add Hotplug capability to do Hotplug */
	milbeaut_add_capabilities(pci);

	/* For serving reference clock */
	milbeaut_serve_ref_clock(pci);

#ifdef CONFIG_PCIE_MILBEAUT_MANUAL_LINK_OPE
	ret = milbeaut_pcie_config_legacy_irq(pp);
	if (ret)
		return ret;
#endif

	/* To restart from Link Down */
#ifndef CONFIG_PCIE_MILBEAUT_MANUAL_LINK_OPE
	INIT_DELAYED_WORK(&priv->cmd_handler, milbeaut_pcie_restart);
#endif

	ret = dw_pcie_host_init(pp);
	if (ret)
		dev_err(dev, "Failed to initialize host\n");

	return 0;
}

static void milbeaut_pcie_ep_init(struct dw_pcie_ep *ep)
{
	struct dw_pcie *pci = to_dw_pcie_from_ep(ep);
	struct pci_epc *epc = ep->epc;
	enum pci_barno bar;

	for (bar = BAR_0; bar <= BAR_5; bar++)
		dw_pcie_ep_reset_bar(pci, bar);

	epc->features |= EPC_FEATURE_NO_LINKUP_NOTIFIER;
	epc->features |= EPC_FEATURE_MSIX_AVAILABLE;
}

static int milbeaut_pcie_ep_raise_irq(struct dw_pcie_ep *ep, u8 func_no,
				     enum pci_epc_irq_type type,
				     u16 interrupt_num)
{
	struct dw_pcie *pci = to_dw_pcie_from_ep(ep);

	switch (type) {
	case PCI_EPC_IRQ_LEGACY:
		return dw_pcie_ep_raise_legacy_irq(ep, func_no);
	case PCI_EPC_IRQ_MSI:
		return dw_pcie_ep_raise_msi_irq(ep, func_no, interrupt_num);
	case PCI_EPC_IRQ_MSIX:
		return dw_pcie_ep_raise_msix_irq(ep, func_no, interrupt_num);
	default:
		dev_err(pci->dev, "UNKNOWN IRQ type\n");
	}

	return 0;
}

static struct dw_pcie_ep_ops pcie_ep_ops = {
	.ep_init = milbeaut_pcie_ep_init,
	.raise_irq = milbeaut_pcie_ep_raise_irq,
};

static int milbeaut_add_pcie_ep(struct milbeaut_pcie_priv *priv,
				struct platform_device *pdev)
{
	int ret;
	struct dw_pcie_ep *ep;
	struct resource *res;
	struct device *dev = &pdev->dev;
	struct dw_pcie *pci = &priv->pci;

	ep = &pci->ep;
	ep->ops = &pcie_ep_ops;

	if (IS_ERR(pci->dbi_base))
		return -EINVAL;

	pci->dbi_base2 = pci->dbi_base + MLB_SHADOW_REG_OFFSET;
	if (IS_ERR(pci->dbi_base2))
		return PTR_ERR(pci->dbi_base2);

	res = platform_get_resource_byname(pdev, IORESOURCE_MEM, "addr_space");
	if (!res)
		return -EINVAL;

	ep->phys_base = res->start;
	ep->addr_size = resource_size(res);

	/* For PCIe AXI Master */
	dw_pcie_writel_dbi(pci, MLB_PCIE_COHE_CNT3, 0x7878);

	ret = dw_pcie_ep_init(ep);
	if (ret) {
		dev_err(dev, "Failed to initialize endpoint\n");
		return ret;
	}

	return 0;
}

static int milbeaut_pcie_enable(struct milbeaut_pcie_priv *priv)
{
	int ret, val;
	struct dw_pcie *pci = &priv->pci;
	u32 auxclk;

	switch (priv->dev_type) {
	case MLB_PCIE_RC_WITH_BIFUR:
		ret = reset_control_assert(priv->bifu_en); // bifur on
		if (ret)
			return ret;
		ret = reset_control_assert(priv->rcdev);   // to RC
		if (ret)
			return ret;
		break;
	case MLB_PCIE_RC_WITHOUT_BIFUR:
		ret = reset_control_deassert(priv->bifu_en); // bifur off
		if (ret)
			return ret;
		ret = reset_control_assert(priv->rcdev);     // to RC
		if (ret)
			return ret;
		break;
	case MLB_PCIE_RC_KARINE:
		ret = reset_control_assert(priv->rcdev);     // to RC
		if (ret)
			return ret;
		break;
	case MLB_PCIE_EP:
		ret = reset_control_deassert(priv->bifu_en); // bifur off
		if (ret)
			return ret;
		ret = reset_control_deassert(priv->rcdev);   // to EP
		if (ret)
			return ret;
		break;
	case MLB_PCIE_EP_KARINE:
		ret = reset_control_deassert(priv->rcdev);   // to EP
		if (ret)
			return ret;
		break;
	default:
		return -EINVAL;
	}

	ret = clk_prepare_enable(priv->clk_main); // PCIEAUXCLK un-gating
	if (ret)
		return ret;

	ret = clk_prepare_enable(priv->clk_bus); // ACLK_PCIEx un-gating
	if (ret)
		goto out_clk_main_disable;

	ret = reset_control_deassert(priv->rst_soft); // cold reset deassert
	if (ret)
		goto out_clk_bus_disable;

	ret = reset_control_deassert(priv->rst_pwr); // power_up_rst_n deassert
	if (ret)
		goto out_rst_soft_disable;

	val = readl(priv->base + MLB_GEN_CTRL_4);
	val |= MLB_LTSSM_CLR_MASK;
	writel(val, priv->base + MLB_GEN_CTRL_4);

	ret = dma_set_mask_and_coherent(pci->dev, DMA_BIT_MASK(64));
	if (ret)
		dev_err(pci->dev, "Failed to set 64-bit DMA mask.\n");

	if (priv->prsnt2) {
		gpiod_set_value_cansleep(priv->prsnt2, 0);
		usleep_range(1000, 1500);
	}

	auxclk = clk_get_rate(priv->clk_main);
	dw_pcie_writel_dbi(pci, MLB_PCIE_AUX_CLK_FREQ, auxclk/1000000);

	priv->enabled = true;

	return 0;

out_rst_soft_disable:
	reset_control_assert(priv->rst_soft);
out_clk_bus_disable:
	clk_disable_unprepare(priv->clk_bus);
out_clk_main_disable:
	clk_disable_unprepare(priv->clk_main);

	return ret;
}

static int mlb_pcie_get_resource_common(struct platform_device *pdev,
				  struct milbeaut_pcie_priv *priv)
{
	struct device *dev = &pdev->dev;
	struct resource *res;

	res = platform_get_resource_byname(pdev, IORESOURCE_MEM, "dbi");
	priv->pci.dbi_base = devm_ioremap_resource(dev, res);
	if (IS_ERR(priv->pci.dbi_base))
		return PTR_ERR(priv->pci.dbi_base);

	res = platform_get_resource_byname(pdev, IORESOURCE_MEM, "ctrl");
	priv->base = devm_ioremap_resource(dev, res);
	if (IS_ERR(priv->base))
		return PTR_ERR(priv->base);

	priv->rst_pwr = devm_reset_control_get_shared(dev, "pwr");
	if (IS_ERR(priv->rst_pwr))
		return PTR_ERR(priv->rst_pwr);
	priv->rst_soft = devm_reset_control_get(dev, "soft");
	if (IS_ERR(priv->rst_soft))
		return PTR_ERR(priv->rst_soft);
	priv->bifu_en = devm_reset_control_get(dev, "bifu");
	if (IS_ERR(priv->bifu_en))
		return PTR_ERR(priv->bifu_en);
	priv->rcdev = devm_reset_control_get(dev, "dev");
	if (IS_ERR(priv->rcdev))
		return PTR_ERR(priv->rcdev);

	return 0;
}

static int mlb_pcie_get_resource_common_karine(struct platform_device *pdev,
				  struct milbeaut_pcie_priv *priv)
{
	struct device *dev = &pdev->dev;
	struct resource *res;

	res = platform_get_resource_byname(pdev, IORESOURCE_MEM, "dbi");
	priv->pci.dbi_base = devm_ioremap_resource(dev, res);
	if (IS_ERR(priv->pci.dbi_base))
		return PTR_ERR(priv->pci.dbi_base);

	res = platform_get_resource_byname(pdev, IORESOURCE_MEM, "ctrl");
	priv->base = devm_ioremap_resource(dev, res);
	if (IS_ERR(priv->base))
		return PTR_ERR(priv->base);

	priv->rst_pwr = devm_reset_control_get_shared(dev, "pwr");
	if (IS_ERR(priv->rst_pwr))
		return PTR_ERR(priv->rst_pwr);
	priv->rst_soft = devm_reset_control_get(dev, "soft");
	if (IS_ERR(priv->rst_soft))
		return PTR_ERR(priv->rst_soft);
	priv->rcdev = devm_reset_control_get(dev, "dev");
	if (IS_ERR(priv->rcdev))
		return PTR_ERR(priv->rcdev);

	return 0;
}

static int milbeaut_pcie_get_resource_rc(struct platform_device *pdev,
				  struct milbeaut_pcie_priv *priv)
{
	int ret;

	ret = mlb_pcie_get_resource_common(pdev, priv);
	if (ret)
		return ret;

	priv->cpu2bus_mask = MLB_M20V_CPU2BUS_MASK;
	priv->dev_type = MLB_PCIE_RC_WITHOUT_BIFUR;

	return 0;
}

static int milbeaut_pcie_get_resource_rcbifur(struct platform_device *pdev,
				  struct milbeaut_pcie_priv *priv)
{
	int ret;

	ret = mlb_pcie_get_resource_common(pdev, priv);
	if (ret)
		return ret;

	priv->cpu2bus_mask = MLB_M20V_CPU2BUS_MASK;
	priv->dev_type = MLB_PCIE_RC_WITH_BIFUR;

	return 0;
}

static int milbeaut_pcie_get_resource_ep(struct platform_device *pdev,
				  struct milbeaut_pcie_priv *priv)
{
	int ret;

	ret = mlb_pcie_get_resource_common(pdev, priv);
	if (ret)
		return ret;

	priv->cpu2bus_mask = MLB_M20V_CPU2BUS_MASK;
	priv->dev_type = MLB_PCIE_EP;

	return 0;
}

static int milbeaut_pcie_get_resource_rc_karine(struct platform_device *pdev,
				  struct milbeaut_pcie_priv *priv)
{
	int ret;

	ret = mlb_pcie_get_resource_common_karine(pdev, priv);
	if (ret)
		return ret;

	priv->cpu2bus_mask = MLB_KARINE_CPU2BUS_MASK;
	priv->dev_type = MLB_PCIE_RC_KARINE;

	return 0;
}

static int milbeaut_pcie_get_resource_ep_karine(struct platform_device *pdev,
				  struct milbeaut_pcie_priv *priv)
{
	int ret;

	ret = mlb_pcie_get_resource_common_karine(pdev, priv);
	if (ret)
		return ret;

	priv->cpu2bus_mask = MLB_KARINE_CPU2BUS_MASK;
	priv->dev_type = MLB_PCIE_EP_KARINE;

	return 0;
}

static void milbeaut_pcie_disable(struct milbeaut_pcie_priv *priv)
{
	struct dw_pcie *pci = &priv->pci;
	struct device *dev = pci->dev;
	int cid;

	cid = milbeaut_pcie_get_controller_id(dev);
	if (cid < 0) return;

#ifndef CONFIG_PCIE_MILBEAUT_MANUAL_LINK_OPE
	cancel_delayed_work_sync(&priv->cmd_handler);
	milbeaut_pcie_irq_disable(priv);
#endif
	if (priv->enabled) {
		reset_control_assert(priv->rst_pwr);
		reset_control_assert(priv->rst_soft);
		clk_disable_unprepare(priv->clk_main);
		clk_disable_unprepare(priv->clk_bus);
	}

	milbeaut_pcie_set_gen_type (cid, 0);
	milbeaut_pcie_set_num_lanes(cid, 0);

	priv->enabled = false;
}

#ifdef CONFIG_PM_SLEEP
static int milbeaut_pcie_suspend(struct device *dev)
{
	struct milbeaut_pcie_priv *priv = dev_get_drvdata(dev);

	if ((priv->dev_type == MLB_PCIE_EP) ||
	    (priv->dev_type == MLB_PCIE_EP_KARINE))
		return -EINVAL;

	milbeaut_pcie_disable(priv);
	return 0;
}

static int milbeaut_pcie_resume(struct device *dev)
{
	struct milbeaut_pcie_priv *priv = dev_get_drvdata(dev);
	struct dw_pcie *pci = &priv->pci;
	struct pcie_port *pp = &pci->pp;
	u64 msi_target = (u64)pp->msi_data;

	if ((priv->dev_type == MLB_PCIE_EP) ||
	    (priv->dev_type == MLB_PCIE_EP_KARINE))
		return -EINVAL;

	if (priv->enabled) {
		milbeaut_pcie_enable(priv);
#ifndef CONFIG_PCIE_MILBEAUT_MANUAL_LINK_OPE
		milbeaut_pcie_irq_enable(priv);
#endif
		milbeaut_add_capabilities(pci);		// to do HOTPLUG
		dw_pcie_setup_rc(pp);				// restore general registers

		if (IS_ENABLED(CONFIG_PCI_MSI)) {	// resume MSI target
			dw_pcie_write(pci->dbi_base + PCIE_MSI_ADDR_LO, 4,
				      lower_32_bits(msi_target));
			dw_pcie_write(pci->dbi_base + PCIE_MSI_ADDR_HI, 4,
				      upper_32_bits(msi_target));
		}
	}
#ifndef CONFIG_PCIE_MILBEAUT_MANUAL_LINK_OPE
	schedule_delayed_work(&priv->cmd_handler, msecs_to_jiffies(130));
#endif
	return 0;
}
#endif

#ifdef CONFIG_PCIE_MILBEAUT_MANUAL_LINK_OPE
int milbeaut_pcie_host_link_up(int cid, bool link_up)
{
	struct milbeaut_pcie_priv *priv = milbeaut_pcie_restore_priv(cid);
	struct dw_pcie *pci = &priv->pci;
	struct platform_device *pdev = priv->pdev;
	struct pcie_port *pp = &pci->pp;
	int ret = 0;

	if ((priv->dev_type == MLB_PCIE_EP) ||
	    (priv->dev_type == MLB_PCIE_EP_KARINE))
		return -EINVAL;

	milbeaut_pcie_enable(priv);

	if(milbeaut_pcie_check_never_linkup(cid)){
		switch (priv->dev_type) {
		case MLB_PCIE_RC_WITH_BIFUR:
		case MLB_PCIE_RC_WITHOUT_BIFUR:
		case MLB_PCIE_RC_KARINE:
			ret = milbeaut_add_pcie_port(priv, pdev);
			if (ret < 0)
				return ret;
			break;
		case MLB_PCIE_EP:
		case MLB_PCIE_EP_KARINE:
			ret = milbeaut_add_pcie_ep(priv, pdev);
			if (ret < 0)
				return ret;
			break;
		default:
			dev_err(pci->dev, "INVALID device type %d\n", priv->dev_type);
			ret = -EINVAL;
		}
	}

	milbeaut_serve_ref_clock(pci);

	if (IS_ENABLED(CONFIG_PCI_MSI))
		dw_pcie_msi_init(pp);

	if(!link_up) return 0;

	if(milbeaut_pcie_check_never_linkup(cid)){
		ret = dw_pcie_host_link_start(pp);
		if (ret)
			dev_err(pci->dev, "Failed to initialize host\n");
		milbeaut_pcie_update_linkup_history(cid);
	}else{
		msleep(1);
		ret = milbeaut_pcie_host_init(pp);
		if (ret)
			dev_err(pci->dev, "Failed to initialize host\n");
	}
	
	return ret;
}
EXPORT_SYMBOL(milbeaut_pcie_host_link_up);

int milbeaut_pcie_host_link_down(int cid)
{
	struct milbeaut_pcie_priv *priv = milbeaut_pcie_restore_priv(cid);

	milbeaut_pcie_disable(priv);

	return 0;
}
EXPORT_SYMBOL(milbeaut_pcie_host_link_down);

#ifdef MILBEAUT_PCIE_LINK_CDEV_ENABLE
static int milbeaut_pcie_device_open(struct inode *inode, struct file  *file)
{
	printk(KERN_ERR "%s\n",__func__);
	return 0;
}

static int milbeaut_pcie_device_close(struct inode *inode, struct file  *file)
{
	printk(KERN_ERR "%s\n",__func__);
	return 0;
}

static long milbeaut_pcie_device_ioctl(struct file *filp, unsigned int cmd, unsigned long arg)
{
	struct milbeaut_pcie_device_ioctl_param *p = (struct milbeaut_pcie_device_ioctl_param *)arg;
	int ret;
	printk(KERN_ERR "%s\n",__func__);

	switch(cmd){
		case PCIE_IOCTL_SET_LINKUP:
			ret = milbeaut_pcie_host_link_up(p->pcie_controller_id, true);
			break;
		case PCIE_IOCTL_SET_LINKDOWN:
			ret = milbeaut_pcie_host_link_down(p->pcie_controller_id);
			break;
		default:
			ret = -EFAULT;
			break;
	}
	return ret;
}

static struct cdev	milbeaut_pcie_link_cdev;

static struct file_operations milbeaut_pcie_link_fops = {
	.open 		=	milbeaut_pcie_device_open,
	.release	=	milbeaut_pcie_device_close,
	.unlocked_ioctl	= 	milbeaut_pcie_device_ioctl,
	.compat_ioctl	= 	milbeaut_pcie_device_ioctl,
};

int milbeaut_pcie_link_register_cdev(void)
{
	dev_t dev = MKDEV(MILBEAUT_PCIE_LINK_MAJOR,0);
	int result;

	result = register_chrdev_region(dev,1,MILBEAUT_PCIE_LINK_DEVICE_NAME);
	if(result < 0)
	{
		return result;
	}
	cdev_init(&milbeaut_pcie_link_cdev, &milbeaut_pcie_link_fops);
	result = cdev_add(&milbeaut_pcie_link_cdev, dev,1);
	if(result < 0)
	{
		unregister_chrdev_region(dev,1);
		return result;
	}
	return result;
}
#endif
#endif /* CONFIG_PCIE_MILBEAUT_MANUAL_LINK_OPE */

static bool bifur_node_is_available(struct device *dev)
{
	const __be32 *prop;
	struct device_node *bifur;

	prop = of_get_property(dev_of_node(dev), "bifur-node", NULL);
	if (!prop)
		return false;

	bifur = of_find_node_by_phandle(be32_to_cpup(prop));
	if (!bifur)
		return false;

	return of_device_is_available(bifur);
}

static int milbeaut_pcie_probe(struct platform_device *pdev)
{
	struct device *dev = &pdev->dev;
	struct milbeaut_pcie_priv *priv;
	struct dw_pcie *pci;
	int ret;
	const struct of_device_id *match;
	int (*mil_func)(struct platform_device *pdev,
			struct milbeaut_pcie_priv *priv);
	int cid;

	match = of_match_device(milbeaut_pcie_of_match, dev);
	if (!match)
		return -EINVAL;

	cid = milbeaut_pcie_get_controller_id(dev);
	if (cid < 0)
		return -EINVAL;

	priv = devm_kzalloc(dev, sizeof(*priv), GFP_KERNEL);
	if (!priv)
		return -ENOMEM;

	priv->enabled = false;

	priv->pdev = pdev;
	dev_set_drvdata(dev, priv);

	milbeaut_pcie_save_priv(cid, priv);
	pci = &priv->pci;

	pci->dev = dev;
	pci->ops = &milbeaut_pcie_ops;

	priv->clk_main = devm_clk_get(dev, "auxclk");
	if (IS_ERR(priv->clk_main))
		return PTR_ERR(priv->clk_main);

	priv->clk_bus = devm_clk_get(dev, "busclk");
	if (IS_ERR(priv->clk_bus))
		return PTR_ERR(priv->clk_bus);

#ifdef CONFIG_PCIE_MILBEAUT_MANUAL_LINK_OPE
#ifdef MILBEAUT_PCIE_LINK_CDEV_ENABLE
	ret = milbeaut_pcie_link_register_cdev();
	if(ret){
		printk(KERN_ERR "%s line:%d milbeaut_pcie_link_register_cdev err\n",__func__,__LINE__);
	}
#endif
#endif /* CONFIG_PCIE_MILBEAUT_MANUAL_LINK_OPE */

	mil_func = match->data;
	ret = (*mil_func)(pdev, priv);
	if (ret)
		return ret;

	if (priv->dev_type == MLB_PCIE_RC_WITHOUT_BIFUR &&
	    !bifur_node_is_available(dev)) {
		/* RC without bifurcation board may need prsnt2 setting */
		priv->prsnt2 = devm_gpiod_get_optional(dev, "prsnt2",
						       GPIOD_OUT_LOW);
		if (IS_ERR(priv->prsnt2))
			return PTR_ERR(priv->prsnt2);
	}

#ifndef CONFIG_PCIE_MILBEAUT_MANUAL_LINK_OPE
	ret = milbeaut_pcie_enable(priv);
	if (ret)
		return ret;

	switch (priv->dev_type) {
	case MLB_PCIE_RC_WITH_BIFUR:
	case MLB_PCIE_RC_WITHOUT_BIFUR:
	case MLB_PCIE_RC_KARINE:
		ret = milbeaut_add_pcie_port(priv, pdev);
		if (ret < 0)
			return ret;
		break;
	case MLB_PCIE_EP:
	case MLB_PCIE_EP_KARINE:
		ret = milbeaut_add_pcie_ep(priv, pdev);
		if (ret < 0)
			return ret;
		break;
	default:
		dev_err(dev, "INVALID device type %d\n", priv->dev_type);
		ret = -EINVAL;
	}
#else
	reset_control_assert(priv->rcdev);		// to RC (PCIE_CLKREQ_L <- Hi-Z)
	reset_control_assert(priv->rst_soft);
#endif

	return ret;
}

static int milbeaut_pcie_remove(struct platform_device *pdev)
{
	struct milbeaut_pcie_priv *priv = platform_get_drvdata(pdev);
	int cid;

	cid = milbeaut_pcie_get_controller_id((priv->pci).dev);
	if (cid < 0)
		return -EINVAL;

	milbeaut_pcie_disable(priv);

	milbeaut_pcie_clear_priv(cid);

	return 0;
}

static const struct of_device_id milbeaut_pcie_of_match[] = {
	{
		.compatible = "socionext,milbeaut-pcie-rc",
		.data = (void *)&milbeaut_pcie_get_resource_rc,
	},
	{
		.compatible = "socionext,milbeaut-pcie-rc-bifur",
		.data = (void *)&milbeaut_pcie_get_resource_rcbifur,
	},
	{
		.compatible = "socionext,milbeaut-pcie-ep",
		.data = (void *)&milbeaut_pcie_get_resource_ep,
	},
	{
		.compatible = "socionext,milbeaut-pcie-rc-karine",
		.data = (void *)&milbeaut_pcie_get_resource_rc_karine,
	},
	{
		.compatible = "socionext,milbeaut-pcie-ep-karine",
		.data = (void *)&milbeaut_pcie_get_resource_ep_karine,
	},
	{}
};
MODULE_DEVICE_TABLE(of, milbeaut_pcie_match);

static const struct dev_pm_ops milbeaut_pcie_pm_ops = {
	SET_NOIRQ_SYSTEM_SLEEP_PM_OPS(milbeaut_pcie_suspend,
				      milbeaut_pcie_resume)
};

static struct platform_driver milbeaut_pcie_driver = {
	.driver = {
		.name	= "milbeaut-pcie",
		.of_match_table = milbeaut_pcie_of_match,
		.pm = &milbeaut_pcie_pm_ops,
	},
	.probe = milbeaut_pcie_probe,
	.remove = milbeaut_pcie_remove,
};
builtin_platform_driver(milbeaut_pcie_driver);

MODULE_AUTHOR("Taichi Sugaya <<REDACTED_EMAIL>>");
MODULE_DESCRIPTION("Milbeaut PCIe host controller driver");
MODULE_LICENSE("GPL v2");
