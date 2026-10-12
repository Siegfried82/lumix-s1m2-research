/* SPDX-License-Identifier: GPL-2.0 */
#ifndef DT_BINDINGS_MILBEAUT_KARINE_CLOCK_H
#define DT_BINDINGS_MILBEAUT_KARINE_CLOCK_H

/* KARINE onecell_id */
/*	name				onecell_id	rate changeable */
#define KARINE_ACLK_PCIE_ID		0		/* no */
#define KARINE_PCIEAUXCLK_ID		1		/* no */
#define KARINE_HCLK_SDIO_ID		2		/* no */
#define KARINE_SDIOCLK_ID		3		/* yes */
#define KARINE_ACLK_UHS2_ID		4		/* no */
#define KARINE_HCLK_UHS1_ID		5		/* no */
#define KARINE_SD4CLK_ID		6		/* yes */
#define KARINE_SDBCLK_ID		7		/* yes */
#define KARINE_ACLK_EMMC_ID		8		/* no */
#define KARINE_EMMCCLK_ID		9		/* yes */
#define KARINE_RCLK_ID			10		/* yes */
#define KARINE_RCLK64T_ID		11		/* yes */
#define KARINE_WDGCLK_ID		12		/* no */
#define KARINE_PCLK_ARM_ID		13		/* no */
#define KARINE_HCLK_UART_DMA_ID		14		/* no */
#define KARINE_HCLK_PERI_BM_ID		15		/* no */
#define KARINE_HCLK_PERI_MAIN_ID	16		/* no */
#define KARINE_HCLK_PERI_ID		17		/* no */
#define KARINE_PCLK_PERI_ID		18		/* no */
#define KARINE_I3CCLK1_ID		19		/* no */
#define KARINE_I3CCLK0_ID		20		/* no */
#define KARINE_HCLK_SPI3_ID		21		/* no */
#define KARINE_SPICLK3_ID		22		/* yes */
#define KARINE_HCLK_SPI2_ID		23		/* no */
#define KARINE_SPICLK2_ID		24		/* yes */
#define KARINE_HCLK_SPI1_ID		25		/* no */
#define KARINE_SPICLK1_ID		26		/* yes */
#define KARINE_HCLK_SPI0_ID		27		/* no */
#define KARINE_SPICLK0_ID		28		/* yes */
#define KARINE_PCLK_GPIO_ID		29		/* no */
#define KARINE_PCLK_TS_ID		30		/* no */
#define KARINE_PCLK_SYS_ID		31		/* no */
#define KARINE_ACLK_AP_ID		32		/* no */
#define KARINE_CSCLK_ID			33		/* no */
#define KARINE_ACLK_IMEM_ID		34		/* no */
#define KARINE_ACLK_XDMAC_ID		35		/* no */
#define KARINE_ACLK_USB_ID		36		/* no */
#define KARINE_HCLK_HDMAC_ID		37		/* no */
#define KARINE_HCLK_USB_ID		38		/* no */
#define KARINE_ACLK_EXS_ID		39		/* no */
#define KARINE_HCLK_EXS_ID		40		/* no */
#define KARINE_PCLK_EXS_ID		41		/* no */

#define KARINE_NUM_CLKS			42

#endif /* DT_BINDINGS_MILBEAUT_KARINE_CLOCK_H */
