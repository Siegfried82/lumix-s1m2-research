// SPDX-License-Identifier: GPL-2.0
/*
 * Reference epf driver for MILBEAUT
 *
 * Author: Taichi Sugaya <<REDACTED_EMAIL>>
 */

#include <linux/crc32.h>
#include <linux/delay.h>
#include <linux/io.h>
#include <linux/module.h>
#include <linux/slab.h>
#include <linux/pci_ids.h>
#include <linux/random.h>

#include <linux/pci-epc.h>
#include <linux/pci-epf.h>
#include <linux/pci_regs.h>

#define M20V_PCIE_REG_BASE	0x1b000000
#define M20V_PCIE_DMA_OFS	0x380000

#define M20V_PCIE_DMA_SIZE	0x2000
#define M20V_LINKLIST_SIZE	0x100000

struct pci_epf_milbeaut {
	void			*reg[6];
	struct pci_epf		*epf;
	enum pci_barno		dma_reg_bar;
	enum pci_barno		linklist_bar;
};

static struct pci_epf_header milbeaut_header = {
	.vendorid	= PCI_VENDOR_ID_SOCIONEXT,
	.deviceid	= PCI_DEVICE_ID_SOCIONEXT_TNTTV,
	.baseclass_code = PCI_CLASS_OTHERS,
	.interrupt_pin	= PCI_INTERRUPT_INTA,
};

static size_t bar_size[] = {
	M20V_PCIE_DMA_SIZE, 4096,
	M20V_LINKLIST_SIZE, 4096,
	4096, 4096
};

static void pci_epf_milbeaut_linkup(struct pci_epf *epf)
{
	struct device *dev = &epf->dev;

	dev_info(dev, "link established with RC\n");
}

static void pci_epf_milbeaut_unbind(struct pci_epf *epf)
{
	struct pci_epf_milbeaut *epf_milbeaut = epf_get_drvdata(epf);
	struct pci_epc *epc = epf->epc;
	struct pci_epf_bar *epf_bar;
	int bar;

	pci_epc_stop(epc);
	for (bar = BAR_0; bar <= BAR_5; bar++) {
		epf_bar = &epf->bar[bar];
		pci_epf_free_space(epf, epf_milbeaut->reg[bar], bar);
		pci_epc_clear_bar(epc, epf->func_no, epf_bar);
	}
}

static int pci_epf_milbeaut_set_bar(struct pci_epf *epf)
{
	int bar;
	int ret;
	struct pci_epf_bar *epf_bar;
	struct pci_epc *epc = epf->epc;
	struct device *dev = &epf->dev;
	struct pci_epf_milbeaut *epf_milbeaut = epf_get_drvdata(epf);
	enum pci_barno dma_reg_bar = epf_milbeaut->dma_reg_bar;
	enum pci_barno linklist_bar = epf_milbeaut->linklist_bar;

	for (bar = BAR_0; bar <= BAR_3; bar++) {
		epf_bar = &epf->bar[bar];

		epf_bar->flags |= PCI_BASE_ADDRESS_MEM_TYPE_64;

		ret = pci_epc_set_bar(epc, epf->func_no, epf_bar);
		if (ret) {
			pci_epf_free_space(epf, epf_milbeaut->reg[bar], bar);
			dev_err(dev, "Failed to set BAR%d\n", bar);
			if ((bar == dma_reg_bar) || (bar == linklist_bar))
				return ret;
		}
		/*
		 * pci_epc_set_bar() sets PCI_BASE_ADDRESS_MEM_TYPE_64
		 * if the specific implementation required a 64-bit BAR,
		 * even if we only requested a 32-bit BAR.
		 */
		if (epf_bar->flags & PCI_BASE_ADDRESS_MEM_TYPE_64)
			bar++;
	}

	return 0;
}

static int pci_epf_milbeaut_alloc_space(struct pci_epf *epf)
{
	struct pci_epf_milbeaut *epf_milbeaut = epf_get_drvdata(epf);
	const struct pci_epc_features *epc_features;
	struct device *dev = &epf->dev;
	size_t align;
	void *base;
	int bar;
	enum pci_barno dma_reg_bar = epf_milbeaut->dma_reg_bar;


	epc_features = pci_epc_get_features(epf->epc, epf->func_no);
	if (!epc_features)
		align = 0;
	else
		align = epc_features->align;

	epf->bar[dma_reg_bar].phys_addr = M20V_PCIE_REG_BASE +
					  M20V_PCIE_DMA_OFS;
	epf->bar[dma_reg_bar].size = bar_size[dma_reg_bar];
	epf->bar[dma_reg_bar].barno = dma_reg_bar;
	epf->bar[dma_reg_bar].flags = PCI_BASE_ADDRESS_SPACE_MEMORY;
	epf_milbeaut->reg[dma_reg_bar] = NULL; // tentative

	for (bar = BAR_0; bar <= BAR_3; bar++) {
		if (bar == dma_reg_bar)
			continue;
		base = pci_epf_alloc_space(epf, bar_size[bar], bar, align);
		if (!base)
			dev_err(dev, "Failed to allocate space for BAR%d\n",
				bar);
		epf_milbeaut->reg[bar] = base;
	}

	/* for DMA driver in RC */
	writeq((u64)epf->bar[BAR_2].phys_addr, epf_milbeaut->reg[BAR_2]);

	return 0;
}

static int pci_epf_milbeaut_bind(struct pci_epf *epf)
{
	int ret;
	struct pci_epf_header *header = epf->header;
	struct pci_epc *epc = epf->epc;
	struct device *dev = &epf->dev;

	if (WARN_ON_ONCE(!epc))
		return -EINVAL;

	ret = pci_epc_write_header(epc, epf->func_no, header);
	if (ret) {
		dev_err(dev, "Configuration header write failed\n");
		return ret;
	}

	ret = pci_epf_milbeaut_alloc_space(epf);
	if (ret)
		return ret;

	ret = pci_epf_milbeaut_set_bar(epf);
	if (ret)
		return ret;

	return 0;
}

static const struct pci_epf_device_id pci_epf_milbeaut_ids[] = {
	{
		.name = "pci_epf_milbeaut",
	},
	{},
};

static int pci_epf_milbeaut_probe(struct pci_epf *epf)
{
	struct pci_epf_milbeaut *epf_milbeaut;
	struct device *dev = &epf->dev;
	enum pci_barno dma_reg_bar = BAR_0;
	enum pci_barno linklist_bar = BAR_2;

	epf_milbeaut = devm_kzalloc(dev, sizeof(*epf_milbeaut), GFP_KERNEL);
	if (!epf_milbeaut)
		return -ENOMEM;

	epf->header = &milbeaut_header;
	epf_milbeaut->epf = epf;
	epf_milbeaut->dma_reg_bar = dma_reg_bar;
	epf_milbeaut->linklist_bar = linklist_bar;

	epf_set_drvdata(epf, epf_milbeaut);
	return 0;
}

static struct pci_epf_ops milbeaut_ops = {
	.unbind	= pci_epf_milbeaut_unbind,
	.bind	= pci_epf_milbeaut_bind,
	.linkup = pci_epf_milbeaut_linkup,
};

static struct pci_epf_driver milbeaut_driver = {
	.driver.name	= "pci_epf_milbeaut",
	.probe		= pci_epf_milbeaut_probe,
	.id_table	= pci_epf_milbeaut_ids,
	.ops		= &milbeaut_ops,
	.owner		= THIS_MODULE,
};

static int __init pci_epf_milbeaut_init(void)
{
	int ret;

	ret = pci_epf_register_driver(&milbeaut_driver);
	if (ret) {
		pr_err("Failed to register pci epf milbeaut driver --> %d\n", ret);
		return ret;
	}

	return 0;
}
module_init(pci_epf_milbeaut_init);

static void __exit pci_epf_milbeaut_exit(void)
{
	pci_epf_unregister_driver(&milbeaut_driver);
}
module_exit(pci_epf_milbeaut_exit);

MODULE_DESCRIPTION("PCI EPF MILBEAUT DRIVER");
MODULE_AUTHOR("Taichi Sugaya <<REDACTED_EMAIL>");
MODULE_LICENSE("GPL v2");
