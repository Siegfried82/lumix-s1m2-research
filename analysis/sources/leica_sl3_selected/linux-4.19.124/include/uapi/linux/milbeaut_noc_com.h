/* SPDX-License-Identifier: GPL-2.0 */
/*
 * copyright (C) 2019 Socionext Inc.
 *               Takao Orito <<REDACTED_EMAIL>>
 */
#ifndef __NOC_USERLAND_COM_H
#define __NOC_USERLAND_COM_H

/* enum to specify bridge ID */
enum E_NOC_BANK_BRIDGE_ID {
	E_NOC_BANK_ARM_XDMAC0 = 0,
	E_NOC_BANK_ARM_XDMAC1,
	E_NOC_BANK_PERI_AHB_DMA,
	E_NOC_BANK_DSP_AHBM,
	E_NOC_BANK_DSP_XM6_AXIMP0,
	E_NOC_BANK_DSP_XM6_AXIMD0,
	E_NOC_BANK_DSP_XM6_AXIMP1,
	E_NOC_BANK_DSP_XM6_AXIMD1,
	E_NOC_BANK_EXS_UHS1_MEM0,
	E_NOC_BANK_EXS_UHS1_MEM1,
	E_NOC_BANK_EXS_UHS2_MEM0,
	E_NOC_BANK_EXS_UHS2_MEM1,
	E_NOC_BANK_EXS_SDIO_MEM,
	E_NOC_BANK_EXS_EMMC_MEM,
	E_NOC_BANK_EXS_XDMAC_MEM,
	E_NOC_BANK_EXS_NF_DMA,
	E_NOC_BANK_ISP_GPU_2D_GPU2D,
	E_NOC_BANK_MAX
};

/********************************************************************
 *  argument structure
 ********************************************************************/
struct milbeaut_noc_bank_argv {
	/* Bank setting target master */
	enum E_NOC_BANK_BRIDGE_ID	bridge_id;
	/* extend address for read master,
	 * address[35:32] of target address
	 */
	unsigned char arba;
	/* extend address for write master,
	 * address[35:32] of target address
	 */
	unsigned char awba;
};
#endif /* __NOC_USERLAND_COM_H */
