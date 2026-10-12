/* SPDX-License-Identifier: GPL-2.0 */
#ifndef DT_BINDINGS_MILBEAUT_M20V_CLOCK_H
#define DT_BINDINGS_MILBEAUT_M20V_CLOCK_H

/*	name			onecell_id	rate changeable */
#define M20V_ACLK_PCIE1_ID	0		// no
#define M20V_ACLK_PCIE0_ID	1		// no
#define M20V_PCIEAUXCLK_ID	2		// no
#define M20V_HCLK_SDIO_ID	3		// no
#define M20V_SDIOCLK_ID		4		// yes
#define M20V_ACLK_UHS21_ID	5		// no
#define M20V_HCLK_UHS11_ID	6		// no
#define M20V_SD4CLK1_ID		7		// no(depends on SDBCLK1)
#define M20V_SDBCLK1_ID		8		// yes
#define M20V_ACLK_UHS20_ID	9		// no
#define M20V_HCLK_UHS10_ID	10		// no
#define M20V_SD4CLK0_ID		11		// no(depends on SDBCLK0)
#define M20V_SDBCLK0_ID		12		// yes
#define M20V_ACLK_NF_ID		13		// no
#define M20V_NF_NFBCLK_ID	14		// yes
#define M20V_ACLK_NSEC_ID	15		// no
#define M20V_PCLK_NSEC_ID	16		// no
#define M20V_NETSECCLK_ID	17		// no
#define M20V_NETRCLK_ID		18		// yes
#define M20V_ACLK_USB_ID	19		// no
#define M20V_NETAUCLK_ID	20		// yes
#define M20V_ACLK_GPU2D_ID	21		// no
#define M20V_HCLK_GPU2D_ID	22		// no
#define M20V_GPU2DCLK_ID	23		// yes
#define M20V_ACLK_CNN_ID	24		// no
#define M20V_CNNCLK_ID		25		// yes
#define M20V_TL4TIMCLK_ID	26		// no
#define M20V_TL4CLK_ID		27		// yes
#define M20V_HCLK_DSP_ID	28		// no
#define M20V_DSPTIMCLK_ID	29		// no
#define M20V_DSPCLK1_ID		30		// yes
#define M20V_DSPCLK0_ID		31		// yes
#define M20V_RCLK_ID		32		// no
#define M20V_TMR64CLK_ID	33		// no
#define M20V_CPUWDCLK_ID	34		// no
#define M20V_PCLK100_ID		35		// no
#define M20V_PCLK_PERI_ID	36		// no
#define M20V_HCLK_PERI_MAIN_ID	37		// no
#define M20V_HCLK_PERI_SPI0_ID	38		// no
#define M20V_HCLK_PERI_SPI1_ID	39		// no
#define M20V_HCLK_PERI_SPI2_ID	40		// no
#define M20V_SPICLK0_ID		41		// no
#define M20V_SPICLK1_ID		42		// no
#define M20V_SPICLK2_ID		43		// no
#define M20V_I3CCLK0_ID		44		// no
#define M20V_ACLK_EMMC_ID	45		// no
#define M20V_EMMCCLK_ID		46		// yes
#define M20V_PERI2I3CCLK1_ID	47		// no

#define M20V_NUM_CLKS 		48


#endif /* DT_BINDINGS_MILBEAUT_M20V_CLOCK_H */
