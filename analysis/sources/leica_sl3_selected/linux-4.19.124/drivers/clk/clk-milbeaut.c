// SPDX-License-Identifier: GPL-2.0
/*
 * Copyright (C) 2018 Socionext Inc.
 * Copyright (C) 2016 Linaro Ltd.
 */

#include <linux/clk.h>
#include <linux/clk-provider.h>
#include <linux/err.h>
#include <linux/io.h>
#include <linux/iopoll.h>
#include <linux/of_address.h>
#include <linux/of_device.h>
#include <linux/platform_device.h>
#include <linux/slab.h>
#include <linux/spinlock.h>
#include <dt-bindings/clock/milbeaut,m20v-clock.h>
#include <dt-bindings/clock/milbeaut,m10v-clock.h>

#define M10V_CLKSEL1		0x0
#define M10V_CLKSEL(n)	((n - 1) * 4 + M10V_CLKSEL1)
#define M10V_CLKSTOP1		0x54
#define M10V_CLKSTOP(n)	((n - 1) * 4 + M10V_CLKSTOP1)

#define M20V_CLKSEL1		0x0
#define M20V_CLKSEL(n)	((n - 1) * 4 + M20V_CLKSEL1)
#define M20V_CLKSTOP1		0xa0
#define M20V_CLKSTOP(n)	((n - 1) * 4 + M20V_CLKSTOP1)
#define M20V_PLLCNT1		0x40
#define M20V_PLLCNT(n)	((n - 1) * 4 + M20V_PLLCNT1)
#define M20V_CRDMN1		0x2110
#define M20V_CRDMN(n)	((n - 1) * 0x10 + M20V_CRDMN1)

#define M10V_PLL1		"pll1"
#define M10V_PLL1DIV2		"pll1-2"
#define M10V_PLL2		"pll2"
#define M10V_PLL2DIV2		"pll2-2"
#define M10V_PLL6		"pll6"
#define M10V_PLL6DIV2		"pll6-2"
#define M10V_PLL6DIV3		"pll6-3"
#define M10V_PLL7		"pll7"
#define M10V_PLL7DIV2		"pll7-2"
#define M10V_PLL7DIV5		"pll7-5"
#define M10V_PLL9		"pll9"
#define M10V_PLL10		"pll10"
#define M10V_PLL10DIV2		"pll10-2"
#define M10V_PLL11		"pll11"

#define M10V_SPI_PARENT0	"spi-parent0"
#define M10V_SPI_PARENT1	"spi-parent1"
#define M10V_SPI_PARENT2	"spi-parent2"
#define M10V_UHS1CLK2_PARENT0	"uhs1clk2-parent0"
#define M10V_UHS1CLK2_PARENT1	"uhs1clk2-parent1"
#define M10V_UHS1CLK2_PARENT2	"uhs1clk2-parent2"
#define M10V_UHS1CLK1_PARENT0	"uhs1clk1-parent0"
#define M10V_UHS1CLK1_PARENT1	"uhs1clk1-parent1"
#define M10V_NFCLK_PARENT0	"nfclk-parent0"
#define M10V_NFCLK_PARENT1	"nfclk-parent1"
#define M10V_NFCLK_PARENT2	"nfclk-parent2"
#define M10V_NFCLK_PARENT3	"nfclk-parent3"
#define M10V_NFCLK_PARENT4	"nfclk-parent4"
#define M10V_NFCLK_PARENT5	"nfclk-parent5"

#define M20V_UCLKXI		"UCLKXI"
#define M20V_AUMCLKI		"AUMCLKI"
#define M20V_GENCLK		"GENCLK"

#define M20V_PLL01_3		"pll1-3"
#define M20V_PLL01_2		"pll1-2"
#define M20V_PLL05_2		"pll5-2"
#define M20V_PLL07		"pll7"
#define M20V_PLL09		"pll9"

#define M20V_UCLKXIDIV2		"uclk-2"
#define M20V_AUMCLKIDIV4	"aumclk-4"
#define M20V_BUS400MCLK		"bus400m"
#define M20V_BUS200MCLK		"bus200m"
#define M20V_BUS100MCLK		"bus100m"
#define M20V_BUS50MCLK		"bus50m"
#define M20V_BUS200MPERICLK	"bus200mperi"
#define M20V_BUS100MPERICLK	"bus100mperi"
#define M20V_AXI400MCLK		"axi400m"
#define M20V_AHB200MCLK		"ahb200m"
#define M20V_AXIDSPCLK		"axidsp"
#define M20V_AHBDSPCLK		"ahbdsp"
#define M20V_PLL01_2DIV8	"pll1-2-8"
#define M20V_PLL01_2DIV24	"pll1-2-24"
#define M20V_PLL01_2DIV48	"pll1-2-48"
#define M20V_PLL01_3DIV2	"pll1-3-2"
#define M20V_PLL01_3DIV4	"pll1-3-4"
#define M20V_PLL01_3DIV32	"pll1-3-32"
#define M20V_PLL05_2DIV2	"pll5-2-2"
#define M20V_PLL07DIV4		"pll7-4"
#define M20V_PLL09DIV2		"pll9-2"
#define M20V_PLL09DIV4		"pll9-4"
#define M20V_PLL09DIV10		"pll9-10"
#define M20V_NETSEC_PRE4	"netsec-pre4"

#define M20V_DIV_EMMCCLK	"div-emmcclk"
#define M20V_DIV_NFBCHCLK	"div-nfbchclk"
#define M20V_DIV_NFCLK		"div-nfclk"
#define M20V_DIV_SDIOCLK	"div-sdioclk"
#define M20V_DIV_SDBCLK1	"div-sdbclk1"
#define M20V_DIV_SD4CLK1	"div-sd4clk1"
#define M20V_DIV_SDBCLK0	"div-sdbclk0"
#define M20V_DIV_SD4CLK0	"div-sd4clk0"
#define M20V_DIV_NETRCLK	"div-netrclk"
#define M20V_DIV_TL4CLK		"div-tl4clk"
#define M20V_DIV_RCLK		"div-rclk"
#define M20V_DIV_TMR64CLK	"div-tmr64clk"
#define M20V_DIV_SPI2		"div-spi2"
#define M20V_DIV_SPI1		"div-spi1"
#define M20V_DIV_SPI0		"div-spi0"

#define M20V_MUX_CNNCLK		"mux-cnnclk"
#define M20V_MUX_DSPCLK0	"mux-dspclk0"
#define M20V_MUX_DSPCLK1	"mux-dspclk1"
#define M20V_MUX_GPU2D		"mux-gpu2d"
#define M20V_MUX_NETAUCLK	"mux-netauclk"

#define M20V_GPU2D_HANU		"hanu-gpu2d"
#define M20V_DSPCLK0_HANU	"hanu-dspclk0"
#define M20V_DSPCLK1_HANU	"hanu-dspclk1"
#define M20V_CNNCLK_HANU	"hanu-cnnclk"

#define M10V_DCHREQ		1
#define M10V_UPOLL_RATE		1
#define M10V_UTIMEOUT		250

#define M20V_PLL05_MULT160	160
#define M20V_PLL05_MULT180	180

#define M20V_CRITICAL_GATE	(CLK_IGNORE_UNUSED | CLK_IS_CRITICAL)

#define to_mlb_div(_hw)		container_of(_hw, struct mlb_clk_divider, hw)

static struct clk_hw_onecell_data *mlb_clk_data;

static DEFINE_SPINLOCK(mlb_crglock);

struct mlb_clk_pll_factors {
	const char	*name;
	const char	*parent_name;
	u32		div;
	u32		mult;
};

struct mlb_clk_gate_factors {
	const char			*name;
	const char			*parent_name;
	unsigned long			flags;
	u32				offset;
	int				onecell_idx;
	u8				shift;
};

struct mlb_clk_div_factors {
	const char			*name;
	const char			*parent_name;
	const struct clk_div_table	*table;
	unsigned long			div_flags;
	u32				offset;
	int				onecell_idx;
	u8				shift;
	u8				width;
};

struct mlb_clk_div_fixed_data {
	const char	*name;
	const char	*parent_name;
	int		onecell_idx;
	u8		div;
	u8		mult;
};

struct mlb_clk_mux_factors {
	const char		*name;
	const char * const	*parent_names;
	u32			*table;
	unsigned long		mux_flags;
	u32			offset;
	int			onecell_idx;
	u8			num_parents;
	u8			shift;
	u8			mask;
};

static const struct clk_div_table m10v_emmcclk_table[] = {
	{ .val = 0, .div = 8 },
	{ .val = 1, .div = 9 },
	{ .val = 2, .div = 10 },
	{ .val = 3, .div = 15 },
	{ .div = 0 },
};

static const struct clk_div_table m10v_mclk400_table[] = {
	{ .val = 1, .div = 2 },
	{ .val = 3, .div = 4 },
	{ .div = 0 },
};

static const struct clk_div_table m10v_mclk200_table[] = {
	{ .val = 3, .div = 4 },
	{ .val = 7, .div = 8 },
	{ .div = 0 },
};

static const struct clk_div_table m10v_aclk400_table[] = {
	{ .val = 1, .div = 2 },
	{ .val = 3, .div = 4 },
	{ .div = 0 },
};

static const struct clk_div_table m10v_aclk300_table[] = {
	{ .val = 0, .div = 2 },
	{ .val = 1, .div = 3 },
	{ .div = 0 },
};

static const struct clk_div_table m10v_aclk_table[] = {
	{ .val = 3, .div = 4 },
	{ .val = 7, .div = 8 },
	{ .div = 0 },
};

static const struct clk_div_table m10v_aclkexs_table[] = {
	{ .val = 3, .div = 4 },
	{ .val = 4, .div = 5 },
	{ .val = 5, .div = 6 },
	{ .val = 7, .div = 8 },
	{ .div = 0 },
};

static const struct clk_div_table m10v_hclk_table[] = {
	{ .val = 7, .div = 8 },
	{ .val = 15, .div = 16 },
	{ .div = 0 },
};

static const struct clk_div_table m10v_hclkbmh_table[] = {
	{ .val = 3, .div = 4 },
	{ .val = 7, .div = 8 },
	{ .div = 0 },
};

static const struct clk_div_table m10v_pclk_table[] = {
	{ .val = 15, .div = 16 },
	{ .val = 31, .div = 32 },
	{ .div = 0 },
};

static const struct clk_div_table m10v_rclk_table[] = {
	{ .val = 0, .div = 8 },
	{ .val = 1, .div = 16 },
	{ .val = 2, .div = 24 },
	{ .val = 3, .div = 32 },
	{ .div = 0 },
};

static const struct clk_div_table m10v_uhs1clk0_table[] = {
	{ .val = 0, .div = 2 },
	{ .val = 1, .div = 3 },
	{ .val = 2, .div = 4 },
	{ .val = 3, .div = 8 },
	{ .val = 4, .div = 16 },
	{ .div = 0 },
};

static const struct clk_div_table m10v_uhs2clk_table[] = {
	{ .val = 0, .div = 9 },
	{ .val = 1, .div = 10 },
	{ .val = 2, .div = 11 },
	{ .val = 3, .div = 12 },
	{ .val = 4, .div = 13 },
	{ .val = 5, .div = 14 },
	{ .val = 6, .div = 16 },
	{ .val = 7, .div = 18 },
	{ .div = 0 },
};

static const struct clk_div_table m10v_nfbchclk_table[] = {
	{ .val = 0, .div = 4 },
	{ .val = 1, .div = 8 },
	{ .div = 0 },
};

static u32 m10v_spi_mux_table[] = {0, 1, 2};
static const char * const m10v_spi_mux_names[] = {
	M10V_SPI_PARENT0, M10V_SPI_PARENT1, M10V_SPI_PARENT2
};

static u32 m10v_uhs1clk2_mux_table[] = {2, 3, 4, 8};
static const char * const m10v_uhs1clk2_mux_names[] = {
	M10V_UHS1CLK2_PARENT0, M10V_UHS1CLK2_PARENT1,
	M10V_UHS1CLK2_PARENT2, M10V_PLL6DIV2
};

static u32 m10v_uhs1clk1_mux_table[] = {3, 4, 8};
static const char * const m10v_uhs1clk1_mux_names[] = {
	M10V_UHS1CLK1_PARENT0, M10V_UHS1CLK1_PARENT1, M10V_PLL6DIV2
};

static u32 m10v_nfclk_mux_table[] = {0, 1, 2, 3, 4, 8};
static const char * const m10v_nfclk_mux_names[] = {
	M10V_NFCLK_PARENT0, M10V_NFCLK_PARENT1, M10V_NFCLK_PARENT2,
	M10V_NFCLK_PARENT3, M10V_NFCLK_PARENT4, M10V_NFCLK_PARENT5
};

static const struct mlb_clk_pll_factors m10v_pll_fixed_data[] = {
	/* name, parent, div, mult */
	{M10V_PLL1, NULL, 1, 40},
	{M10V_PLL2, NULL, 1, 30},
	{M10V_PLL6, NULL, 1, 35},
	{M10V_PLL7, NULL, 1, 40},
	{M10V_PLL9, NULL, 1, 33},
	{M10V_PLL10, NULL, 5, 108},
	{M10V_PLL10DIV2, M10V_PLL10, 2, 1},
	{M10V_PLL11, NULL, 2, 75},
};

static const struct mlb_clk_div_fixed_data m10v_div_fixed_data[] = {
	/* name, parent, onecell_idx, div, mult */
	{"usb3", NULL, M10V_USB3CLK_ID, 1, 1},
	{"usb2", NULL, M10V_USB2CLK_ID, 2, 1},
	{"pcisuppclk", NULL, M10V_PCISUPPCLK_ID, 20, 1},
	{M10V_PLL1DIV2, M10V_PLL1, -1, 2, 1},
	{M10V_PLL2DIV2, M10V_PLL2, -1, 2, 1},
	{M10V_PLL6DIV2, M10V_PLL6, -1, 2, 1},
	{M10V_PLL6DIV3, M10V_PLL6, -1, 3, 1},
	{M10V_PLL7DIV2, M10V_PLL7, -1, 2, 1},
	{M10V_PLL7DIV5, M10V_PLL7, -1, 5, 1},
	{"netsecclk", M10V_PLL11, M10V_NETSECCLK_ID, 6, 1},
	{"ca7wd", M10V_PLL2DIV2, M10V_CA7WDCLK_ID, 12, 1},
	{"pclkca7wd", M10V_PLL1DIV2, -1, 16, 1},
	{M10V_SPI_PARENT0, M10V_PLL10DIV2, -1, 2, 1},
	{M10V_SPI_PARENT1, M10V_PLL10DIV2, -1, 4, 1},
	{M10V_SPI_PARENT2, M10V_PLL7DIV2, -1, 8, 1},
	{M10V_UHS1CLK2_PARENT0, M10V_PLL7, -1, 4, 1},
	{M10V_UHS1CLK2_PARENT1, M10V_PLL7, -1, 8, 1},
	{M10V_UHS1CLK2_PARENT2, M10V_PLL7, -1, 16, 1},
	{M10V_UHS1CLK1_PARENT0, M10V_PLL7, -1, 8, 1},
	{M10V_UHS1CLK1_PARENT1, M10V_PLL7, -1, 16, 1},
	{M10V_NFCLK_PARENT0, M10V_PLL7DIV2, -1, 8, 1},
	{M10V_NFCLK_PARENT1, M10V_PLL7DIV2, -1, 10, 1},
	{M10V_NFCLK_PARENT2, M10V_PLL7DIV2, -1, 13, 1},
	{M10V_NFCLK_PARENT3, M10V_PLL7DIV2, -1, 16, 1},
	{M10V_NFCLK_PARENT4, M10V_PLL7DIV2, -1, 40, 1},
	{M10V_NFCLK_PARENT5, M10V_PLL7DIV5, -1, 10, 1},
};

static const struct mlb_clk_div_factors m10v_div_factor_data[] = {
	/* name, parent, tbl, divflag, offet, onecell_idx, shift, width */
	{"emmc", M10V_PLL11, m10v_emmcclk_table, 0, M10V_CLKSEL(1),	M10V_EMMCCLK_ID, 28,  3},
	{"mclk400", M10V_PLL1DIV2, m10v_mclk400_table, 0, M10V_CLKSEL(10),	-1,	  7,  3},
	{"mclk200", M10V_PLL1DIV2, m10v_mclk200_table, 0, M10V_CLKSEL(10), 	-1,	  3,  4},
	{"aclk400", M10V_PLL1DIV2, m10v_aclk400_table, 0, M10V_CLKSEL(10),	-1,	  0,  3},
	{"aclk300", M10V_PLL2DIV2, m10v_aclk300_table, 0, M10V_CLKSEL(12),	-1,	  0,  2},
	{"aclk", M10V_PLL1DIV2, m10v_aclk_table, 0, M10V_CLKSEL(9),	M10V_ACLK_ID,	 20,  4},
	{"aclkexs", M10V_PLL1DIV2, m10v_aclkexs_table, 0, M10V_CLKSEL(9),	-1,	 16,  4},
	{"hclk", M10V_PLL1DIV2, m10v_hclk_table, 0, M10V_CLKSEL(9),	M10V_HCLK_ID,	  7,  5},
	{"hclkbmh", M10V_PLL1DIV2, m10v_hclkbmh_table, 0, M10V_CLKSEL(9),	-1,	 12,  4},
	{"pclk", M10V_PLL1DIV2, m10v_pclk_table, 0, M10V_CLKSEL(9),	M10V_PCLK_ID,	  0,  7},
	{"uhs1clk0", M10V_PLL7, m10v_uhs1clk0_table, 0, M10V_CLKSEL(1),	M10V_UHS1CLK0_ID, 3,  5},
	{"uhs2clk", M10V_PLL6DIV3, m10v_uhs2clk_table, 0, M10V_CLKSEL(1),
								     M10V_UHS2CLK_ID,	 18,  4},
	{"nfbchclk", M10V_PLL7DIV2, m10v_nfbchclk_table, 0, M10V_CLKSEL(12),
								     M10V_NFBCHCLK_ID,	 19,  2},
};

static const struct mlb_clk_mux_factors m10v_mux_factor_data[] = {
	/* name, parent, tbl, mux_flag, offset, idx, num_parent, shift, mask */
	{"spi", m10v_spi_mux_names, m10v_spi_mux_table, 0, M10V_CLKSEL(8),
		M10V_SPICLK_ID, ARRAY_SIZE(m10v_spi_mux_names), 3, 7 },
	{"uhs1clk2", m10v_uhs1clk2_mux_names, m10v_uhs1clk2_mux_table, 0, M10V_CLKSEL(1),
		M10V_UHS1CLK2_ID, ARRAY_SIZE(m10v_uhs1clk2_mux_names), 13, 31},
	{"uhs1clk1", m10v_uhs1clk1_mux_names, m10v_uhs1clk1_mux_table, 0, M10V_CLKSEL(1),
		M10V_UHS1CLK1_ID, ARRAY_SIZE(m10v_uhs1clk1_mux_names), 8, 31},
	{"nfclk", m10v_nfclk_mux_names, m10v_nfclk_mux_table, 0, M10V_CLKSEL(1),
		M10V_NFCLK_ID, ARRAY_SIZE(m10v_nfclk_mux_names), 22, 127},
};

static const struct clk_div_table m20v_emmcclk_tbl[] = {
	{ .val = 0, .div = 8},
	{ .val = 1, .div = 9},
	{ .val = 2, .div = 11},
	{ .val = 3, .div = 16},
	{ .div = 0},
};

static const struct clk_div_table m20v_nfbchclk_tbl[] = {
	{ .val = 0, .div = 6},
	{ .val = 1, .div = 8},
	{ .val = 2, .div = 12},
	{ .val = 3, .div = 24},
	{ .div = 0},
};

static const struct clk_div_table m20v_nfclk_tbl[] = {
	{ .val = 0, .div = 8},
	{ .val = 1, .div = 16},
	{ .val = 2, .div = 20},
	{ .val = 3, .div = 26},
	{ .val = 4, .div = 32},
	{ .val = 5, .div = 50},
	{ .val = 6, .div = 80},
	{ .div = 0},
};

static const struct clk_div_table m20v_sdioclk_tbl[] = {
	{ .val = 0, .div = 2},
	{ .val = 1, .div = 4},
	{ .val = 2, .div = 5},
	{ .val = 3, .div = 6},
	{ .val = 4, .div = 7},
	{ .val = 5, .div = 8},
	{ .val = 6, .div = 9},
	{ .val = 7, .div = 16},
	{ .div = 0},
};

static const struct clk_div_table m20v_sdclkb_tbl[] = {
	{ .val = 0, .div = 1 },  { .val = 1, .div = 1 },  { .val = 2, .div = 1 },  { .val = 3, .div = 1 },
	{ .val = 4, .div = 1 },  { .val = 5, .div = 1 },  { .val = 6, .div = 1 },  { .val = 7, .div = 1 },
	{ .val = 8, .div = 1 },  { .val = 9, .div = 1 },  { .val = 10, .div = 1 }, { .val = 11, .div = 1 },
	{ .val = 12, .div = 1 }, { .val = 13, .div = 1 }, { .val = 14, .div = 1 }, { .val = 15, .div = 1 },
	{ .val = 16, .div = 1 }, { .val = 17, .div = 1 }, { .val = 18, .div = 1 }, { .val = 19, .div = 1 },
	{ .val = 20, .div = 1 }, { .val = 21, .div = 1 }, { .val = 22, .div = 1 }, { .val = 23, .div = 1 },
	{ .val = 24, .div = 1 }, { .val = 25, .div = 1 }, { .val = 26, .div = 1 }, { .val = 27, .div = 1 },
	{ .val = 28, .div = 1 }, { .val = 29, .div = 1 },
	// valid parameters are below
	{ .val = 30, .div = 31 }, { .val = 31, .div = 32 }, { .val = 32, .div = 33 }, { .val = 33, .div = 34 },
	{ .val = 34, .div = 35 }, { .val = 35, .div = 36 }, { .val = 36, .div = 37 }, { .val = 37, .div = 38 },
	{ .val = 38, .div = 39 }, { .val = 39, .div = 40 }, { .val = 40, .div = 41 }, { .val = 41, .div = 42 },
	{ .val = 42, .div = 43 }, { .val = 43, .div = 44 }, { .val = 44, .div = 45 }, { .val = 45, .div = 46 },
	{ .val = 46, .div = 47 }, { .val = 47, .div = 48 }, { .val = 48, .div = 49 }, { .val = 49, .div = 50 },
	{ .val = 50, .div = 51 }, { .val = 51, .div = 52 }, { .val = 52, .div = 53 }, { .val = 53, .div = 54 },
	{ .val = 54, .div = 55 }, { .val = 55, .div = 56 }, { .val = 56, .div = 57 }, { .val = 57, .div = 58 },
	{ .val = 58, .div = 59 }, { .val = 59, .div = 60 }, { .val = 60, .div = 61 }, { .val = 61, .div = 62 },
	{ .val = 62, .div = 63 }, { .val = 63, .div = 64 },
	// valid parameters are above
	{ .val = 64, .div = 1 }, { .val = 65, .div = 1 }, { .val = 66, .div = 1 }, { .val = 67, .div = 1 },
	{ .val = 68, .div = 1 }, { .val = 69, .div = 1 }, { .val = 70, .div = 1 }, { .val = 71, .div = 1 },
	{ .val = 72, .div = 1 }, { .val = 73, .div = 1 }, { .val = 74, .div = 1 }, { .val = 75, .div = 1 },
	{ .val = 76, .div = 1 }, { .val = 77, .div = 1 }, { .val = 78, .div = 1 }, { .val = 79, .div = 1 },
	{ .val = 80, .div = 1 }, { .val = 81, .div = 1 }, { .val = 82, .div = 1 }, { .val = 83, .div = 1 },
	{ .val = 84, .div = 1 }, { .val = 85, .div = 1 }, { .val = 86, .div = 1 }, { .val = 87, .div = 1 },
	{ .val = 88, .div = 1 }, { .val = 89, .div = 1 }, { .val = 90, .div = 1 }, { .val = 91, .div = 1 },
	{ .val = 92, .div = 1 }, { .val = 93, .div = 1 }, { .val = 94, .div = 1 }, { .val = 95, .div = 1 },
	{ .val = 96, .div = 1 }, { .val = 97, .div = 1 }, { .val = 98, .div = 1 }, { .val = 99, .div = 1 },
	{ .val = 100, .div = 1 }, { .val = 101, .div = 1 }, { .val = 102, .div = 1 }, { .val = 103, .div = 1 },
	{ .val = 104, .div = 1 }, { .val = 105, .div = 1 }, { .val = 106, .div = 1 }, { .val = 107, .div = 1 },
	{ .val = 108, .div = 1 }, { .val = 109, .div = 1 }, { .val = 110, .div = 1 }, { .val = 111, .div = 1 },
	{ .val = 112, .div = 1 }, { .val = 113, .div = 1 }, { .val = 114, .div = 1 }, { .val = 115, .div = 1 },
	{ .val = 116, .div = 1 }, { .val = 117, .div = 1 }, { .val = 118, .div = 1 }, { .val = 119, .div = 1 },
	{ .val = 120, .div = 1 }, { .val = 121, .div = 1 }, { .val = 122, .div = 1 }, { .val = 123, .div = 1 },
	{ .val = 124, .div = 1 }, { .val = 125, .div = 1 }, { .val = 126, .div = 1 }, { .val = 127, .div = 1 },

	{ .div = 0 },
};

static const struct clk_div_table m20v_sdclk4_tbl[] = {
	{ .val =  0, .div = 12 }, { .val =  1, .div = 13 }, { .val =  2, .div = 14 }, { .val =  3, .div = 15 },
	{ .val =  4, .div = 16 }, { .val =  5, .div = 17 }, { .val =  6, .div = 18 }, { .val =  7, .div = 19 },
	{ .val =  8, .div = 20 }, { .val =  9, .div = 21 }, { .val = 10, .div = 22 }, { .val = 11, .div = 23 },
	{ .val = 12, .div = 24 }, { .val = 13, .div = 24 }, { .val = 14, .div = 24 }, { .val = 15, .div = 24 },
	{ .val = 16, .div = 12 }, { .val = 17, .div = 13 }, { .val = 18, .div = 14 }, { .val = 19, .div = 15 },
	{ .val = 20, .div = 16 }, { .val = 21, .div = 17 }, { .val = 22, .div = 18 }, { .val = 23, .div = 19 },
	{ .val = 24, .div = 20 }, { .val = 25, .div = 21 }, { .val = 26, .div = 22 }, { .val = 27, .div = 23 },
	{ .val = 28, .div = 24 }, { .val = 29, .div = 24 }, { .val = 30, .div = 24 }, { .val = 31, .div = 24 },
	{ .val = 32, .div = 12 }, { .val = 33, .div = 13 }, { .val = 34, .div = 14 }, { .val = 35, .div = 15 },
	{ .val = 36, .div = 16 }, { .val = 37, .div = 17 }, { .val = 38, .div = 18 }, { .val = 39, .div = 19 },
	{ .val = 40, .div = 20 }, { .val = 41, .div = 21 }, { .val = 42, .div = 22 }, { .val = 43, .div = 23 },
	{ .val = 44, .div = 24 }, { .val = 45, .div = 24 }, { .val = 46, .div = 24 }, { .val = 47, .div = 24 },
	{ .val = 48, .div = 12 }, { .val = 49, .div = 13 }, { .val = 50, .div = 14 }, { .val = 51, .div = 15 },
	{ .val = 52, .div = 16 }, { .val = 53, .div = 17 }, { .val = 54, .div = 18 }, { .val = 55, .div = 19 },
	{ .val = 56, .div = 20 }, { .val = 57, .div = 21 }, { .val = 58, .div = 22 }, { .val = 59, .div = 23 },
	{ .val = 60, .div = 24 }, { .val = 61, .div = 24 }, { .val = 62, .div = 24 }, { .val = 63, .div = 24 },
	{ .val = 64, .div = 12 }, { .val = 65, .div = 13 }, { .val = 66, .div = 14 }, { .val = 67, .div = 15 },
	{ .val = 68, .div = 16 }, { .val = 69, .div = 17 }, { .val = 70, .div = 18 }, { .val = 71, .div = 19 },
	{ .val = 72, .div = 20 }, { .val = 73, .div = 21 }, { .val = 74, .div = 22 }, { .val = 75, .div = 23 },
	{ .val = 76, .div = 24 }, { .val = 77, .div = 24 }, { .val = 78, .div = 24 }, { .val = 79, .div = 24 },
	{ .val = 80, .div = 12 }, { .val = 81, .div = 13 }, { .val = 82, .div = 14 }, { .val = 83, .div = 15 },
	{ .val = 84, .div = 16 }, { .val = 85, .div = 17 }, { .val = 86, .div = 18 }, { .val = 87, .div = 19 },
	{ .val = 88, .div = 20 }, { .val = 89, .div = 21 }, { .val = 90, .div = 22 }, { .val = 91, .div = 23 },
	{ .val = 92, .div = 24 }, { .val = 93, .div = 24 }, { .val = 94, .div = 24 }, { .val = 95, .div = 24 },
	{ .val = 96, .div = 12 }, { .val = 97, .div = 13 }, { .val = 98, .div = 14 }, { .val = 99, .div = 15 },
	{ .val = 100, .div = 16 }, { .val = 101, .div = 17 }, { .val = 102, .div = 18 }, { .val = 103, .div = 19 },
	{ .val = 104, .div = 20 }, { .val = 105, .div = 21 }, { .val = 106, .div = 22 }, { .val = 107, .div = 23 },
	{ .val = 108, .div = 24 }, { .val = 109, .div = 24 }, { .val = 110, .div = 24 }, { .val = 111, .div = 24 },
	{ .val = 112, .div = 12 }, { .val = 113, .div = 13 }, { .val = 114, .div = 14 }, { .val = 115, .div = 15 },
	{ .val = 116, .div = 16 }, { .val = 117, .div = 17 }, { .val = 118, .div = 18 }, { .val = 119, .div = 19 },
	{ .val = 120, .div = 20 }, { .val = 121, .div = 21 }, { .val = 122, .div = 22 }, { .val = 123, .div = 23 },
	{ .val = 124, .div = 24 }, { .val = 125, .div = 24 }, { .val = 126, .div = 24 }, { .val = 127, .div = 24 },
	{ .div = 0 },
};

static const struct clk_div_table m20v_rclk_tbl[] = {
	{ .val =  0, .div = 20 },
	{ .val =  1, .div = 40 },
	{ .val =  2, .div = 60 },
	{ .val =  3, .div = 80 },
	{ .div = 0 },
};

static const struct clk_div_table m20v_tmr64clk_tbl[] = {
	{ .val =  0, .div = 8 },
	{ .val =  1, .div = 25 },
	{ .val =  2, .div = 400 },
	{ .val =  3, .div = 400 },
	{ .div = 0 },
};

static const struct clk_div_table m20v_spi_tbl[] = {
	{ .val = 0, .div = 4 },
	{ .val = 1, .div = 8 },
	{ .div = 0 },
};

static const struct clk_div_table m20v_tl4clk_tbl[] = {
	{ .val =  0, .div = 4 },
	{ .val =  1, .div = 5 },
	{ .val =  2, .div = 6 },
	{ .val =  3, .div = 8 },
	{ .val =  4, .div = 12 },
	{ .val =  5, .div = 24 },
	{ .div = 0 },
};

static u32 m20v_dspclk_mux_table[] = {0, 1};
static const char * const m20v_dspclk_mux_names[] = {
	M20V_PLL01_3DIV2, M20V_PLL09DIV4
};

static u32 m20v_gpu2d_mux_table[] = {0, 1};
static const char * const m20v_gpu2d_mux_names[] = {
	M20V_PLL01_3DIV2, M20V_PLL09DIV4
};

static u32 m20v_cnnclk_mux_table[] = {0, 1};
static const char * const m20v_cnnclk_mux_names[] = {
	M20V_PLL01_3DIV2, M20V_PLL09DIV4
};

static u32 m20v_netau_mux_table[] = {0, 1, 2};
static const char * const m20v_netau_mux_names[] = {
	M20V_PLL07DIV4, M20V_AUMCLKI, M20V_AUMCLKIDIV4
};

static u32 m20v_hanu_mux_table[] = {0, 1, 2, 3, 4, 5, 6, 7};
static const char * const m20v_gpu2d_hanu_mux_names[] = {
	"pre0_gpu2d", "pre1_gpu2d", "pre2_gpu2d", "pre3_gpu2d",
	"pre4_gpu2d", "pre5_gpu2d", "pre6_gpu2d", "pre7_gpu2d",
};

static const char * const m20v_dspclk0_hanu_mux_names[] = {
	"pre0_dspclk0", "pre1_dspclk0", "pre2_dspclk0", "pre3_dspclk0",
	"pre4_dspclk0", "pre5_dspclk0", "pre6_dspclk0", "pre7_dspclk0",
};

static const char * const m20v_dspclk1_hanu_mux_names[] = {
	"pre0_dspclk1", "pre1_dspclk1", "pre2_dspclk1", "pre3_dspclk1",
	"pre4_dspclk1", "pre5_dspclk1", "pre6_dspclk1", "pre7_dspclk1",
};

static const char * const m20v_cnnclk_hanu_mux_names[] = {
	"pre0_cnnclk", "pre1_cnnclk", "pre2_cnnclk", "pre3_cnnclk",
	"pre4_cnnclk", "pre5_cnnclk", "pre6_cnnclk", "pre7_cnnclk",
};

static const struct mlb_clk_pll_factors m20v_pll_fixed_data[] = {
	/* name, parent, div, mult */
	{M20V_PLL01_3, M20V_UCLKXIDIV2, 3, 200},
	{M20V_PLL01_2, M20V_UCLKXIDIV2, 2, 200},
};

static const struct mlb_clk_div_fixed_data m20v_div_fixed_data[] = {
	/* name, parent, onecell_idx, div, mult */
	{M20V_AUMCLKIDIV4, M20V_AUMCLKI, -1, 4, 1},
	{M20V_PLL01_2DIV8, M20V_PLL01_2, -1, 8, 1},
	{M20V_PLL01_2DIV24, M20V_PLL01_2, -1, 24, 1},
	{M20V_PLL01_2DIV48, M20V_PLL01_2, -1, 48, 1},
	{M20V_PLL01_3DIV32, M20V_PLL01_3, -1, 32, 1},
	{M20V_PLL01_3DIV4, M20V_PLL01_3, -1, 4, 1},
	{M20V_PLL01_3DIV2, M20V_PLL01_3, -1, 2, 1},
	{"snap_pclk", M20V_BUS100MCLK, M20V_PCLK100_ID, 1, 1},
//	{M20V_PLL05_2DIV2, M20V_PLL05_2, -1, 2, 1},
	{M20V_PLL07DIV4, M20V_PLL07, -1, 4, 1},
	{M20V_PLL09DIV2, M20V_PLL09, -1, 2, 1},
	{M20V_PLL09DIV4, M20V_PLL09, -1, 4, 1},
	{M20V_PLL09DIV10, M20V_PLL09, -1, 10, 1},
	{M20V_NETSEC_PRE4, M20V_PLL09DIV2, -1, 4, 1},
	{"pre0_gpu2d", M20V_MUX_GPU2D, -1, 8, 8},
	{"pre1_gpu2d", M20V_MUX_GPU2D, -1, 8, 7},
	{"pre2_gpu2d", M20V_MUX_GPU2D, -1, 8, 6},
	{"pre3_gpu2d", M20V_MUX_GPU2D, -1, 8, 5},
	{"pre4_gpu2d", M20V_MUX_GPU2D, -1, 8, 4},
	{"pre5_gpu2d", M20V_MUX_GPU2D, -1, 8, 3},
	{"pre6_gpu2d", M20V_MUX_GPU2D, -1, 8, 2},
	{"pre7_gpu2d", M20V_MUX_GPU2D, -1, 8, 1},
	{"pre0_dspclk0", M20V_MUX_DSPCLK0, -1, 8, 8},
	{"pre1_dspclk0", M20V_MUX_DSPCLK0, -1, 8, 7},
	{"pre2_dspclk0", M20V_MUX_DSPCLK0, -1, 8, 6},
	{"pre3_dspclk0", M20V_MUX_DSPCLK0, -1, 8, 5},
	{"pre4_dspclk0", M20V_MUX_DSPCLK0, -1, 8, 4},
	{"pre5_dspclk0", M20V_MUX_DSPCLK0, -1, 8, 3},
	{"pre6_dspclk0", M20V_MUX_DSPCLK0, -1, 8, 2},
	{"pre7_dspclk0", M20V_MUX_DSPCLK0, -1, 8, 1},
	{"pre0_dspclk1", M20V_MUX_DSPCLK1, -1, 8, 8},
	{"pre1_dspclk1", M20V_MUX_DSPCLK1, -1, 8, 7},
	{"pre2_dspclk1", M20V_MUX_DSPCLK1, -1, 8, 6},
	{"pre3_dspclk1", M20V_MUX_DSPCLK1, -1, 8, 5},
	{"pre4_dspclk1", M20V_MUX_DSPCLK1, -1, 8, 4},
	{"pre5_dspclk1", M20V_MUX_DSPCLK1, -1, 8, 3},
	{"pre6_dspclk1", M20V_MUX_DSPCLK1, -1, 8, 2},
	{"pre7_dspclk1", M20V_MUX_DSPCLK1, -1, 8, 1},
	{"pre0_cnnclk", M20V_MUX_CNNCLK, -1, 8, 8},
	{"pre1_cnnclk", M20V_MUX_CNNCLK, -1, 8, 7},
	{"pre2_cnnclk", M20V_MUX_CNNCLK, -1, 8, 6},
	{"pre3_cnnclk", M20V_MUX_CNNCLK, -1, 8, 5},
	{"pre4_cnnclk", M20V_MUX_CNNCLK, -1, 8, 4},
	{"pre5_cnnclk", M20V_MUX_CNNCLK, -1, 8, 3},
	{"pre6_cnnclk", M20V_MUX_CNNCLK, -1, 8, 2},
	{"pre7_cnnclk", M20V_MUX_CNNCLK, -1, 8, 1},
};

static const struct mlb_clk_div_fixed_data m20v_1_div_fixed_data[] = {
	/* name, parent, onecell_idx, div, mult */
	{M20V_BUS400MCLK, M20V_PLL01_2DIV8, -1, 1, 1},
	{M20V_BUS200MCLK, M20V_PLL01_2DIV8, -1, 2, 1},
	{M20V_BUS100MCLK, M20V_PLL01_2DIV8, -1, 4, 1},
	{M20V_BUS50MCLK, M20V_PLL01_2DIV8, -1,  8, 1},
	{"wdogclk", M20V_PLL01_2DIV8, M20V_CPUWDCLK_ID, 8, 1},
};

static const struct mlb_clk_div_fixed_data m20v_2_div_fixed_data[] = {
	/* name, parent, onecell_idx, div, mult */
	{M20V_BUS400MCLK, M20V_PLL01_3DIV2, -1, 2, 1},
	{M20V_BUS200MCLK, M20V_PLL01_3DIV2, -1, 4, 1},
	{M20V_BUS100MCLK, M20V_PLL01_3DIV2, -1, 8, 1},
	{M20V_BUS50MCLK, M20V_PLL01_3DIV2, -1, 16, 1},
	{"wdogclk", M20V_PLL01_3DIV2, M20V_CPUWDCLK_ID, 16, 1},
};

static const struct mlb_clk_div_factors m20v_div_factor_data[] = {
	/* name, parent, tbl, divflag, offet, onecell_idx, shift, width */
	{M20V_DIV_EMMCCLK, M20V_PLL01_3, m20v_emmcclk_tbl, 0, M20V_CLKSEL(1),	-1,			28,  4},
	{M20V_DIV_NFBCHCLK, M20V_PLL01_2, m20v_nfbchclk_tbl, 0, M20V_CLKSEL(1), M20V_NF_NFBCLK_ID,	25,  3},
	{M20V_DIV_NFCLK, M20V_PLL01_3, m20v_nfclk_tbl, 0, M20V_CLKSEL(1),	-1,			20,  5},
	{M20V_DIV_SDIOCLK, M20V_PLL01_3, m20v_sdioclk_tbl, 0, M20V_CLKSEL(1),	-1,			16,  4},
	{M20V_DIV_SDBCLK1, M20V_PLL01_3, m20v_sdclkb_tbl, 0, M20V_CLKSEL(1),	-1,			 8,  8},
	{M20V_DIV_SD4CLK1, M20V_PLL01_2, m20v_sdclk4_tbl, 0, M20V_CLKSEL(1),	-1,			 8,  8},
	{M20V_DIV_SDBCLK0, M20V_PLL01_3, m20v_sdclkb_tbl, 0, M20V_CLKSEL(1),	-1,			 0,  8},
	{M20V_DIV_SD4CLK0, M20V_PLL01_2, m20v_sdclk4_tbl, 0, M20V_CLKSEL(1),	-1,	 		 0,  8},

	{M20V_DIV_NETRCLK, M20V_PLL05_2DIV2, m20v_rclk_tbl, 0, M20V_CLKSEL(2),	-1,			29,  3},

	{M20V_DIV_TL4CLK, M20V_PLL01_2, m20v_tl4clk_tbl, 0, M20V_CLKSEL(4),	-1,			 0,  4},

//	{M20V_DIV_RCLK, M20V_PLL05_2DIV2, m20v_rclk_tbl, CLK_DIVIDER_READ_ONLY, M20V_CLKSEL(10), -1,	28,  4},
	{M20V_DIV_TMR64CLK, M20V_PLL01_3DIV2, m20v_tmr64clk_tbl, CLK_DIVIDER_READ_ONLY, M20V_CLKSEL(10),
										-1,			12,  4},
	{M20V_DIV_SPI2, M20V_PLL01_3DIV2, m20v_spi_tbl, 0, M20V_CLKSEL(10),	-1,			 8,  4},
	{M20V_DIV_SPI1, M20V_PLL01_3DIV2, m20v_spi_tbl, 0, M20V_CLKSEL(10),	-1,			 4,  4},
	{M20V_DIV_SPI0, M20V_PLL01_3DIV2, m20v_spi_tbl, 0, M20V_CLKSEL(10),	-1,			 0,  4},
};

static const struct mlb_clk_div_factors m20v_1_div_factor_data[] = {
	/* name, parent, tbl, divflag, offet, onecell_idx, shift, width */
	{M20V_AXI400MCLK, M20V_PLL01_2DIV8, NULL, CLK_DIVIDER_READ_ONLY, M20V_CRDMN(1), -1, 0,  8},
	{M20V_AHB200MCLK, M20V_PLL01_2DIV8, NULL, CLK_DIVIDER_READ_ONLY, M20V_CRDMN(2), -1, 0,  8},
	{M20V_BUS200MPERICLK, M20V_PLL01_2DIV8, NULL, CLK_DIVIDER_READ_ONLY, M20V_CRDMN(7), -1, 0,  8},
	{M20V_BUS100MPERICLK, M20V_PLL01_2DIV8, NULL, CLK_DIVIDER_READ_ONLY, M20V_CRDMN(8), -1, 0,  8},
	{M20V_AXIDSPCLK, M20V_PLL01_2DIV8, NULL, CLK_DIVIDER_READ_ONLY, M20V_CRDMN(11), -1, 0,  8},
	{M20V_AHBDSPCLK, M20V_PLL01_2DIV8, NULL, CLK_DIVIDER_READ_ONLY, M20V_CRDMN(12), -1, 0,  8},
};

static const struct mlb_clk_div_factors m20v_2_div_factor_data[] = {
	/* name, parent, tbl, divflag, offet, onecell_idx, shift, width */
	{M20V_AXI400MCLK, M20V_PLL01_3DIV4, NULL, CLK_DIVIDER_READ_ONLY, M20V_CRDMN(1), -1, 0,  8},
	{M20V_AHB200MCLK, M20V_PLL01_3DIV4, NULL, CLK_DIVIDER_READ_ONLY, M20V_CRDMN(2), -1, 0,  8},
	{M20V_BUS200MPERICLK, M20V_PLL01_3DIV4, NULL, CLK_DIVIDER_READ_ONLY, M20V_CRDMN(7), -1, 0,  8},
	{M20V_BUS100MPERICLK, M20V_PLL01_3DIV4, NULL, CLK_DIVIDER_READ_ONLY, M20V_CRDMN(8), -1, 0,  8},
	{M20V_AXIDSPCLK, M20V_PLL01_3DIV4, NULL, CLK_DIVIDER_READ_ONLY, M20V_CRDMN(11), -1, 0,  8},
	{M20V_AHBDSPCLK, M20V_PLL01_3DIV4, NULL, CLK_DIVIDER_READ_ONLY, M20V_CRDMN(12), -1, 0,  8},
};

static const struct mlb_clk_mux_factors m20v_mux_factor_data[] = {
	/* name, parent, tbl, mux_flag, offset, idx, num_parent, shift, mask */
	{M20V_MUX_CNNCLK, m20v_cnnclk_mux_names, m20v_cnnclk_mux_table, 0, M20V_CLKSEL(2),
		-1, ARRAY_SIZE(m20v_cnnclk_mux_names), 8, 15},
	{M20V_MUX_DSPCLK0, m20v_dspclk_mux_names, m20v_dspclk_mux_table, 0, M20V_CLKSEL(4),
		-1, ARRAY_SIZE(m20v_dspclk_mux_names), 16, 3},
	{M20V_MUX_DSPCLK1, m20v_dspclk_mux_names, m20v_dspclk_mux_table, 0, M20V_CLKSEL(4),
		-1, ARRAY_SIZE(m20v_dspclk_mux_names), 18, 3},
	{M20V_DSPCLK0_HANU, m20v_dspclk0_hanu_mux_names, m20v_hanu_mux_table, 0, M20V_CLKSEL(4),
		-1, ARRAY_SIZE(m20v_dspclk0_hanu_mux_names), 8, 15},
	{M20V_DSPCLK1_HANU, m20v_dspclk1_hanu_mux_names, m20v_hanu_mux_table, 0, M20V_CLKSEL(4),
		-1, ARRAY_SIZE(m20v_dspclk1_hanu_mux_names), 12, 15},
	{M20V_CNNCLK_HANU, m20v_cnnclk_hanu_mux_names, m20v_hanu_mux_table, 0, M20V_CLKSEL(4),
		-1, ARRAY_SIZE(m20v_cnnclk_hanu_mux_names), 4, 15},
	{M20V_MUX_GPU2D, m20v_gpu2d_mux_names, m20v_gpu2d_mux_table, 0, M20V_CLKSEL(9),
		-1, ARRAY_SIZE(m20v_gpu2d_mux_names), 21, 7},
	{M20V_MUX_NETAUCLK, m20v_netau_mux_names, m20v_netau_mux_table, 0, M20V_CLKSEL(9),
		-1, ARRAY_SIZE(m20v_netau_mux_names), 18, 7},
	{M20V_GPU2D_HANU, m20v_gpu2d_hanu_mux_names, m20v_hanu_mux_table, 0, M20V_CLKSEL(9),
		-1, ARRAY_SIZE(m20v_gpu2d_hanu_mux_names), 0, 15},
};

static const struct mlb_clk_gate_factors m20v_gate_factor_data[] = {
	/* name, parent, gate_flag, offset, onecell_idx, shift */
	{"aclk_pcie1",		M20V_BUS400MCLK, CLK_IGNORE_UNUSED, M20V_CLKSTOP(1), M20V_ACLK_PCIE1_ID, 28},
	{"aclk_pcie0",		M20V_BUS400MCLK, CLK_IGNORE_UNUSED, M20V_CLKSTOP(1), M20V_ACLK_PCIE0_ID, 24},
	{"pcieauxclk",		M20V_UCLKXIDIV2, CLK_IGNORE_UNUSED, M20V_CLKSTOP(1), M20V_PCIEAUXCLK_ID, 20},
	{"hclk_sdio",		M20V_BUS200MCLK, CLK_IGNORE_UNUSED, M20V_CLKSTOP(1), M20V_HCLK_SDIO_ID, 18},
	{"sdioclk",		M20V_DIV_SDIOCLK, CLK_IGNORE_UNUSED, M20V_CLKSTOP(1), M20V_SDIOCLK_ID, 16},
	{"aclk_uhs21",		M20V_BUS200MCLK, CLK_IGNORE_UNUSED, M20V_CLKSTOP(1), M20V_ACLK_UHS21_ID, 14},
	{"hclk_uhs11",		M20V_BUS200MCLK, CLK_IGNORE_UNUSED, M20V_CLKSTOP(1), M20V_HCLK_UHS11_ID, 12},
	{"sd4clk1",		M20V_DIV_SD4CLK1, CLK_IGNORE_UNUSED, M20V_CLKSTOP(1), M20V_SD4CLK1_ID, 10},
	{"sdbclk1",		M20V_DIV_SDBCLK1, CLK_IGNORE_UNUSED, M20V_CLKSTOP(1), M20V_SDBCLK1_ID, 8},
	{"aclk_uhs20",		M20V_BUS200MCLK, CLK_IGNORE_UNUSED, M20V_CLKSTOP(1), M20V_ACLK_UHS20_ID, 6},
	{"hclk_uhs10",		M20V_BUS200MCLK, CLK_IGNORE_UNUSED, M20V_CLKSTOP(1), M20V_HCLK_UHS10_ID, 4},
	{"sd4clk0",		M20V_DIV_SD4CLK0, CLK_IGNORE_UNUSED, M20V_CLKSTOP(1), M20V_SD4CLK0_ID, 2},
	{"sdbclk0",		M20V_DIV_SDBCLK0, CLK_IGNORE_UNUSED, M20V_CLKSTOP(1), M20V_SDBCLK0_ID, 0},

	{"aclk_emmc",		M20V_BUS200MCLK, CLK_IGNORE_UNUSED, M20V_CLKSTOP(2), M20V_ACLK_EMMC_ID, 30},
	{"emmcclk",		M20V_DIV_EMMCCLK, CLK_IGNORE_UNUSED, M20V_CLKSTOP(2), M20V_EMMCCLK_ID, 28},
	{"aclk_nf",		M20V_BUS400MCLK, CLK_IGNORE_UNUSED, M20V_CLKSTOP(2), M20V_ACLK_NF_ID, 26},
	{"nfclk",		M20V_DIV_NFCLK, CLK_IGNORE_UNUSED, M20V_CLKSTOP(2), M20V_NF_NFBCLK_ID, 24},
	{"aclk_nsec",		M20V_BUS400MCLK, CLK_IGNORE_UNUSED, M20V_CLKSTOP(2), M20V_ACLK_NSEC_ID, 22},
	{"pclk_nsec",		M20V_BUS100MCLK, CLK_IGNORE_UNUSED, M20V_CLKSTOP(2), M20V_PCLK_NSEC_ID, 20},
	{"netsecclk",		M20V_NETSEC_PRE4, CLK_IGNORE_UNUSED, M20V_CLKSTOP(2), M20V_NETSECCLK_ID, 18},
	{"netrclk",		M20V_DIV_NETRCLK, CLK_IGNORE_UNUSED, M20V_CLKSTOP(2), M20V_NETRCLK_ID, 16},
//	{"rclk",		M20V_DIV_RCLK, CLK_IGNORE_UNUSED, M20V_CLKSTOP(2), -1, 14},
	{"tmr64clk",		M20V_DIV_TMR64CLK, M20V_CRITICAL_GATE, M20V_CLKSTOP(2), M20V_TMR64CLK_ID, 12},
	{"hclk_peri_dma",	M20V_BUS200MPERICLK, M20V_CRITICAL_GATE, M20V_CLKSTOP(2), -1, 10},
	{"hclk_peri_bm",	M20V_BUS200MPERICLK, M20V_CRITICAL_GATE, M20V_CLKSTOP(2), -1, 8},
	{"hclk_peri_main",	M20V_BUS200MPERICLK, M20V_CRITICAL_GATE, M20V_CLKSTOP(2), M20V_HCLK_PERI_MAIN_ID, 6},
	{"hclk_peri",		M20V_BUS100MPERICLK, M20V_CRITICAL_GATE, M20V_CLKSTOP(2), -1, 4},
	{"pclk_peri_gt",	M20V_BUS100MPERICLK, M20V_CRITICAL_GATE, M20V_CLKSTOP(2), -1, 2},
	{"pclk_peri",		M20V_BUS100MPERICLK, M20V_CRITICAL_GATE, M20V_CLKSTOP(2), M20V_PCLK_PERI_ID, 0},

	{"peri2i3cclk1",	M20V_PLL09DIV10, CLK_IGNORE_UNUSED, M20V_CLKSTOP(4), M20V_PERI2I3CCLK1_ID, 26},
	{"i3cclk0",		M20V_PLL09DIV10, CLK_IGNORE_UNUSED, M20V_CLKSTOP(4), M20V_I3CCLK0_ID, 24},
	{"aclk_usb",		M20V_BUS400MCLK, CLK_IGNORE_UNUSED, M20V_CLKSTOP(4), M20V_ACLK_USB_ID, 14},
	{"netauclk",		M20V_MUX_NETAUCLK, CLK_IGNORE_UNUSED, M20V_CLKSTOP(4), M20V_NETAUCLK_ID, 12},
	{"hclk_peri_spi2",	M20V_BUS200MCLK, CLK_IGNORE_UNUSED, M20V_CLKSTOP(4), M20V_HCLK_PERI_SPI2_ID, 10},
	{"spiclk2",		M20V_DIV_SPI2, CLK_IGNORE_UNUSED, M20V_CLKSTOP(4), M20V_SPICLK2_ID, 8},
	{"hclk_peri_spi1",	M20V_BUS200MCLK, CLK_IGNORE_UNUSED, M20V_CLKSTOP(4), M20V_HCLK_PERI_SPI1_ID, 6},
	{"spiclk1",		M20V_DIV_SPI1, CLK_IGNORE_UNUSED, M20V_CLKSTOP(4), M20V_SPICLK1_ID, 4},
	{"hclk_peri_spi0",	M20V_BUS200MCLK, CLK_IGNORE_UNUSED, M20V_CLKSTOP(4), M20V_HCLK_PERI_SPI0_ID, 2},
	{"spiclk0",		M20V_DIV_SPI0, CLK_IGNORE_UNUSED, M20V_CLKSTOP(4), M20V_SPICLK0_ID, 0},

	{"pm100mclk",		M20V_PLL01_2DIV24, M20V_CRITICAL_GATE, M20V_CLKSTOP(7), -1, 14},

	{"aclk_gpu2d",		M20V_AXI400MCLK, CLK_IGNORE_UNUSED, M20V_CLKSTOP(8), M20V_ACLK_GPU2D_ID, 6},
	{"hclk_gpu2d",		M20V_AHB200MCLK, CLK_IGNORE_UNUSED, M20V_CLKSTOP(8), M20V_HCLK_GPU2D_ID, 4},
	{"gpu2dclk",		M20V_GPU2D_HANU, CLK_IGNORE_UNUSED, M20V_CLKSTOP(8), M20V_GPU2DCLK_ID, 0},

	{"aclk_cnn",		M20V_AXIDSPCLK, CLK_IGNORE_UNUSED, M20V_CLKSTOP(11), M20V_ACLK_CNN_ID, 26},
	{"cnnclk",		M20V_CNNCLK_HANU, CLK_IGNORE_UNUSED, M20V_CLKSTOP(11), M20V_CNNCLK_ID, 24},
	{"tl4timclk",		M20V_PLL01_2DIV48, CLK_IGNORE_UNUSED, M20V_CLKSTOP(11), M20V_TL4TIMCLK_ID, 18},
	{"tl4clk",		M20V_DIV_TL4CLK, CLK_IGNORE_UNUSED, M20V_CLKSTOP(11), M20V_TL4CLK_ID, 16},
	{"hclk_dsp",		M20V_AHBDSPCLK, CLK_IGNORE_UNUSED, M20V_CLKSTOP(11), M20V_HCLK_DSP_ID, 6},
	{"dsptimclk",		M20V_PLL01_3DIV32, CLK_IGNORE_UNUSED, M20V_CLKSTOP(11), M20V_DSPTIMCLK_ID, 4},
	{"dspclk1",		M20V_DSPCLK1_HANU, CLK_IGNORE_UNUSED, M20V_CLKSTOP(11), M20V_DSPCLK1_ID, 2},
	{"dspclk0",		M20V_DSPCLK0_HANU, CLK_IGNORE_UNUSED, M20V_CLKSTOP(11), M20V_DSPCLK0_ID, 0},

	{"pclkts",		M20V_BUS100MCLK, M20V_CRITICAL_GATE, M20V_CLKSTOP(13), -1, 30},
	{"pclksys",		M20V_BUS100MCLK, M20V_CRITICAL_GATE, M20V_CLKSTOP(13), -1, 28},
	{"aclkap",		M20V_BUS400MCLK, M20V_CRITICAL_GATE, M20V_CLKSTOP(13), -1, 14},
	{"atclk",		M20V_PLL01_3DIV4, M20V_CRITICAL_GATE, M20V_CLKSTOP(13), -1, 12},

	{"aclk_imem",		M20V_BUS400MCLK, M20V_CRITICAL_GATE, M20V_CLKSTOP(14), -1, 30},
	{"aclk_xdmac",		M20V_BUS400MCLK, M20V_CRITICAL_GATE, M20V_CLKSTOP(14), -1, 28},
};

static const u32 m20v_pll7rate[] = { 196608000, 147456000, 180633600, 135475200,
					196608000, 147456000, 180633600, 135475200 };

struct mlb_clk_soc_data {
	const struct mlb_clk_div_fixed_data *fixed_table;
	const struct mlb_clk_div_fixed_data *fixed_table2;
	const struct mlb_clk_div_factors *div_table;
	const struct mlb_clk_div_factors *div_table2;
	const struct mlb_clk_mux_factors *mux_table;
	const struct mlb_clk_gate_factors *gate_table;
	const u32 fixed_num;
	const u32 fixed_num2;
	const u32 div_num;
	const u32 div_num2;
	const u32 mux_num;
	const u32 gate_num;
	const u32 onecell_num;
};

static const struct mlb_clk_soc_data m10v_data = {
	.fixed_table = m10v_div_fixed_data,
	.div_table = m10v_div_factor_data,
	.mux_table = m10v_mux_factor_data,
	.gate_table = NULL,
	.fixed_num = ARRAY_SIZE(m10v_div_fixed_data),
	.div_num = ARRAY_SIZE(m10v_div_factor_data),
	.mux_num = ARRAY_SIZE(m10v_mux_factor_data),
	.gate_num = 0,
	.onecell_num = M10V_NUM_CLKS,
};

static const struct mlb_clk_soc_data m20v_1_data = {
	.fixed_table = m20v_div_fixed_data,
	.fixed_table2 = m20v_1_div_fixed_data,
	.div_table = m20v_div_factor_data,
	.div_table2 = m20v_1_div_factor_data,
	.mux_table = m20v_mux_factor_data,
	.gate_table = m20v_gate_factor_data,
	.fixed_num = ARRAY_SIZE(m20v_div_fixed_data),
	.fixed_num2 = ARRAY_SIZE(m20v_1_div_fixed_data),
	.div_num = ARRAY_SIZE(m20v_div_factor_data),
	.div_num2 = ARRAY_SIZE(m20v_1_div_factor_data),
	.mux_num = ARRAY_SIZE(m20v_mux_factor_data),
	.gate_num = ARRAY_SIZE(m20v_gate_factor_data),
	.onecell_num = M20V_NUM_CLKS,
};

static const struct mlb_clk_soc_data m20v_2_data = {
	.fixed_table = m20v_div_fixed_data,
	.fixed_table2 = m20v_2_div_fixed_data,
	.div_table = m20v_div_factor_data,
	.div_table2 = m20v_2_div_factor_data,
	.mux_table = m20v_mux_factor_data,
	.gate_table = m20v_gate_factor_data,
	.fixed_num = ARRAY_SIZE(m20v_div_fixed_data),
	.fixed_num2 = ARRAY_SIZE(m20v_2_div_fixed_data),
	.div_num = ARRAY_SIZE(m20v_div_factor_data),
	.div_num2 = ARRAY_SIZE(m20v_2_div_factor_data),
	.mux_num = ARRAY_SIZE(m20v_mux_factor_data),
	.gate_num = ARRAY_SIZE(m20v_gate_factor_data),
	.onecell_num = M20V_NUM_CLKS,
};

static void mlb_clk_gate_endisable(struct clk_hw *hw, int enable)
{
	struct clk_gate *gate = to_clk_gate(hw);
	int set = gate->flags & CLK_GATE_SET_TO_DISABLE ? 1 : 0;
	unsigned long uninitialized_var(flags);
	u32 reg;

	set ^= enable;

	if (gate->lock)
		spin_lock_irqsave(gate->lock, flags);
	else
		__acquire(gate->lock);

	reg = readl(gate->reg);

	if (set)
		reg |= BIT(gate->bit_idx);
	else
		reg &= ~BIT(gate->bit_idx);
	reg |= BIT(gate->bit_idx + 1);

	writel(reg, gate->reg);

	if (gate->lock)
		spin_unlock_irqrestore(gate->lock, flags);
	else
		__release(gate->lock);
}

static int mlb_clk_gate_enable(struct clk_hw *hw)
{
	mlb_clk_gate_endisable(hw, 1);

	return 0;
}

static void mlb_clk_gate_disable(struct clk_hw *hw)
{
	mlb_clk_gate_endisable(hw, 0);
}

const struct clk_ops mlb_clk_gate_ops = {
	.enable = mlb_clk_gate_enable,
	.disable = mlb_clk_gate_disable,
	.is_enabled = clk_gate_is_enabled,
};

struct clk_hw *mlb_clk_hw_register_gate(struct device *dev, const char *name,
		const char *parent_name, unsigned long flags,
		void __iomem *reg, u8 bit_idx,
		u8 clk_gate_flags, spinlock_t *lock)
{
	struct clk_gate *gate;
	struct clk_hw *hw;
	struct clk_init_data init;
	int ret;

	/* allocate the gate */
	gate = kzalloc(sizeof(*gate), GFP_KERNEL);
	if (!gate)
		return ERR_PTR(-ENOMEM);

	init.name = name;
	init.ops = &mlb_clk_gate_ops;
	init.flags = flags;
	init.parent_names = parent_name ? &parent_name : NULL;
	init.num_parents = parent_name ? 1 : 0;

	/* struct clk_gate assignments */
	gate->reg = reg;
	gate->bit_idx = bit_idx;
	gate->flags = clk_gate_flags | CLK_GATE_SET_TO_DISABLE;
	gate->lock = lock;
	gate->hw.init = &init;

	hw = &gate->hw;
	ret = clk_hw_register(dev, hw);
	if (ret) {
		kfree(gate);
		hw = ERR_PTR(ret);
	}

	return hw;
}

static u8 mlb_mux_get_parent(struct clk_hw *hw)
{
	struct clk_mux *mux = to_clk_mux(hw);
	u32 val;

	val = readl(mux->reg) >> mux->shift;
	val &= mux->mask;

	return clk_mux_val_to_index(hw, mux->table, mux->flags, val);
}

static int mlb_mux_set_parent(struct clk_hw *hw, u8 index)
{
	struct clk_mux *mux = to_clk_mux(hw);
	u32 val = clk_mux_index_to_val(mux->table, mux->flags, index);
	unsigned long flags = 0;
	u32 reg;
	u32 write_en;

	if(!mux->mask)
		return -EINVAL;

	if (mux->lock)
		spin_lock_irqsave(mux->lock, flags);
	else
		__acquire(mux->lock);

	reg = readl(mux->reg);
	reg &= ~(mux->mask << mux->shift);

	write_en = BIT(fls(mux->mask) - 1);
	val = (val | write_en) << mux->shift;
	reg |= val;
	writel(reg, mux->reg);

	if (mux->lock)
		spin_unlock_irqrestore(mux->lock, flags);
	else
		__release(mux->lock);

	return 0;
}

static const struct clk_ops mlb_mux_ops = {
	.get_parent = mlb_mux_get_parent,
	.set_parent = mlb_mux_set_parent,
	.determine_rate = __clk_mux_determine_rate,
};

static struct clk_hw *mlb_clk_hw_register_mux(struct device *dev,
			const char *name, const char * const *parent_names,
			u8 num_parents, unsigned long flags, void __iomem *reg,
			u8 shift, u32 mask, u8 clk_mux_flags, u32 *table,
			spinlock_t *lock)
{
	struct clk_mux *mux;
	struct clk_hw *hw;
	struct clk_init_data init;
	int ret;

	mux = kzalloc(sizeof(*mux), GFP_KERNEL);
	if (!mux)
		return ERR_PTR(-ENOMEM);

	init.name = name;
	init.ops = &mlb_mux_ops;
	init.flags = flags;
	init.parent_names = parent_names;
	init.num_parents = num_parents;

	mux->reg = reg;
	mux->shift = shift;
	mux->mask = mask;
	mux->flags = clk_mux_flags;
	mux->lock = lock;
	mux->table = table;
	mux->hw.init = &init;

	hw = &mux->hw;
	ret = clk_hw_register(dev, hw);
	if (ret) {
		kfree(mux);
		hw = ERR_PTR(ret);
	}

	return hw;

}

struct mlb_clk_divider {
	struct clk_hw	hw;
	void __iomem	*reg;
	u8		shift;
	u8		width;
	u8		flags;
	const struct clk_div_table	*table;
	spinlock_t	*lock;
	void __iomem	*write_valid_reg;
};

static unsigned long mlb_clk_divider_recalc_rate(struct clk_hw *hw,
		unsigned long parent_rate)
{
	struct mlb_clk_divider *divider = to_mlb_div(hw);
	unsigned int val;

	val = readl(divider->reg) >> divider->shift;
	val &= clk_div_mask(divider->width);

	return divider_recalc_rate(hw, parent_rate, val, divider->table,
				   divider->flags, divider->width);
}

static long mlb_clk_divider_round_rate(struct clk_hw *hw, unsigned long rate,
				unsigned long *prate)
{
	struct mlb_clk_divider *divider = to_mlb_div(hw);

	/* if read only, just return current value */
	if (divider->flags & CLK_DIVIDER_READ_ONLY) {
		u32 val;

		val = readl(divider->reg) >> divider->shift;
		val &= clk_div_mask(divider->width);

		return divider_ro_round_rate(hw, rate, prate, divider->table,
					     divider->width, divider->flags,
					     val);
	}

	return divider_round_rate(hw, rate, prate, divider->table,
				  divider->width, divider->flags);
}

static int mlb_clk_divider_set_rate(struct clk_hw *hw, unsigned long rate,
				unsigned long parent_rate)
{
	struct mlb_clk_divider *divider = to_mlb_div(hw);
	int value;
	unsigned long flags = 0;
	u32 val;
	u32 write_en = BIT(divider->width - 1);

	value = divider_get_val(rate, parent_rate, divider->table,
				divider->width, divider->flags);
	if (value < 0)
		return value;

	if (divider->lock)
		spin_lock_irqsave(divider->lock, flags);
	else
		__acquire(divider->lock);

	val = readl(divider->reg);
	val &= ~(clk_div_mask(divider->width) << divider->shift);

	val |= ((u32)value | write_en) << divider->shift;
	writel(val, divider->reg);

	if (divider->write_valid_reg) {
		writel(M10V_DCHREQ, divider->write_valid_reg);
		if (readl_poll_timeout(divider->write_valid_reg, val,
			!val, M10V_UPOLL_RATE, M10V_UTIMEOUT))
			pr_err("%s:%s couldn't stabilize\n",
				__func__, divider->hw.init->name);
	}

	if (divider->lock)
		spin_unlock_irqrestore(divider->lock, flags);
	else
		__release(divider->lock);

	return 0;
}

static const struct clk_ops mlb_clk_divider_ops = {
	.recalc_rate = mlb_clk_divider_recalc_rate,
	.round_rate = mlb_clk_divider_round_rate,
	.set_rate = mlb_clk_divider_set_rate,
};

static const struct clk_ops mlb_clk_divider_ro_ops = {
	.recalc_rate = mlb_clk_divider_recalc_rate,
	.round_rate = mlb_clk_divider_round_rate,
};

static struct clk_hw *mlb_clk_hw_register_divider(struct device *dev,
		const char *name, const char *parent_name, unsigned long flags,
		void __iomem *reg, u8 shift, u8 width,
		u8 clk_divider_flags, const struct clk_div_table *table,
		spinlock_t *lock, void __iomem *write_valid_reg)
{
	struct mlb_clk_divider *div;
	struct clk_hw *hw;
	struct clk_init_data init;
	int ret;

	div = kzalloc(sizeof(*div), GFP_KERNEL);
	if (!div)
		return ERR_PTR(-ENOMEM);

	init.name = name;
	if (clk_divider_flags & CLK_DIVIDER_READ_ONLY)
		init.ops = &mlb_clk_divider_ro_ops;
	else
		init.ops = &mlb_clk_divider_ops;
	init.flags = flags;
	init.parent_names = &parent_name;
	init.num_parents = 1;

	div->reg = reg;
	div->shift = shift;
	div->width = width;
	div->flags = clk_divider_flags;
	div->lock = lock;
	div->hw.init = &init;
	div->table = table;
	div->write_valid_reg = write_valid_reg;

	/* register the clock */
	hw = &div->hw;
	ret = clk_hw_register(dev, hw);
	if (ret) {
		kfree(div);
		hw = ERR_PTR(ret);
	}

	return hw;
}

static int mlb_clk_probe(struct platform_device *pdev)
{
	int id;
	const struct mlb_clk_soc_data *mlb_soc_data;
	struct resource *res;
	struct device *dev = &pdev->dev;
	struct device_node *np = dev->of_node;
	struct clk_hw *hw;
	void __iomem *base, *write_valid_reg;
	const char *parent_name;

	res = platform_get_resource(pdev, IORESOURCE_MEM, 0);
	base = devm_ioremap_resource(dev, res);
	if (IS_ERR(base))
		return PTR_ERR(base);

	mlb_soc_data = of_device_get_match_data(dev);
	if (!mlb_soc_data) {
		dev_err(dev, "no match data\n");
		return -EINVAL;
	}

	parent_name = of_clk_get_parent_name(np, 0);

	for (id = 0; id < mlb_soc_data->div_num; ++id) {
		const struct mlb_clk_div_factors *dfd =
				&mlb_soc_data->div_table[id];
		/*
		 * The registers on M10V_CLKSEL(9) or M10V_CLKSEL(10) need additional
		 * writing to become valid.
		 */
		if (((dfd->offset == M10V_CLKSEL(9)) || (dfd->offset == M10V_CLKSEL(10)))
			&& (mlb_soc_data->div_table == m10v_div_factor_data))
			write_valid_reg = base + M10V_CLKSEL(11);
		else
			write_valid_reg = NULL;
		hw = mlb_clk_hw_register_divider(NULL, dfd->name,
					dfd->parent_name,
					CLK_SET_RATE_PARENT,
					base + dfd->offset, dfd->shift,
					dfd->width, dfd->div_flags, dfd->table,
					&mlb_crglock, write_valid_reg);
		if (dfd->onecell_idx >= 0)
			mlb_clk_data->hws[dfd->onecell_idx] = hw;
	}

	for (id = 0; id < mlb_soc_data->div_num2; ++id) {
		const struct mlb_clk_div_factors *dfd =
				&mlb_soc_data->div_table2[id];
		write_valid_reg = NULL;
		hw = mlb_clk_hw_register_divider(NULL, dfd->name,
					dfd->parent_name,
					CLK_SET_RATE_PARENT,
					base + dfd->offset, dfd->shift,
					dfd->width, dfd->div_flags, dfd->table,
					&mlb_crglock, write_valid_reg);
		if (dfd->onecell_idx >= 0)
			mlb_clk_data->hws[dfd->onecell_idx] = hw;
	}

	for (id = 0; id < mlb_soc_data->fixed_num; ++id) {
		const struct mlb_clk_div_fixed_data *dfd =
				&mlb_soc_data->fixed_table[id];
		const char *pn = dfd->parent_name ?
				dfd->parent_name : parent_name;
		hw = clk_hw_register_fixed_factor(NULL, dfd->name,
					pn, 0, dfd->mult, dfd->div);
		if (dfd->onecell_idx >= 0)
			mlb_clk_data->hws[dfd->onecell_idx] = hw;
	}

	for (id = 0; id < mlb_soc_data->fixed_num2; ++id) {
		const struct mlb_clk_div_fixed_data *dfd =
				&mlb_soc_data->fixed_table2[id];
		const char *pn = dfd->parent_name ?
				dfd->parent_name : parent_name;
		hw = clk_hw_register_fixed_factor(NULL, dfd->name,
					pn, 0, dfd->mult, dfd->div);
		if (dfd->onecell_idx >= 0)
			mlb_clk_data->hws[dfd->onecell_idx] = hw;
	}

	for (id = 0; id < mlb_soc_data->mux_num; ++id) {
		const struct mlb_clk_mux_factors *mfd =
				&mlb_soc_data->mux_table[id];
		hw = mlb_clk_hw_register_mux(NULL, mfd->name,
					mfd->parent_names, mfd->num_parents,
					CLK_SET_RATE_PARENT,
					base + mfd->offset, mfd->shift,
					mfd->mask, mfd->mux_flags, mfd->table,
					&mlb_crglock);
		if (mfd->onecell_idx >= 0)
			mlb_clk_data->hws[mfd->onecell_idx] = hw;
	}

	for (id = 0; id < mlb_soc_data->gate_num; ++id) {
		const struct mlb_clk_gate_factors *gfd =
				&mlb_soc_data->gate_table[id];
		hw = mlb_clk_hw_register_gate(NULL, gfd->name, gfd->parent_name,
					CLK_SET_RATE_PARENT | gfd->flags,
					base + gfd->offset, gfd->shift,
					0, &mlb_crglock);
		if (gfd->onecell_idx >= 0)
			mlb_clk_data->hws[gfd->onecell_idx] = hw;
	}

	for (id = 0; id < mlb_soc_data->onecell_num; id++) {
		if (IS_ERR(mlb_clk_data->hws[id]))
			return PTR_ERR(mlb_clk_data->hws[id]);
	}

	return 0;
}

#include "clk-milbeaut-karine.c"

static const struct of_device_id mlb_clk_dt_ids[] = {
	{ .compatible = "socionext,milbeaut-m10v-ccu", .data = &m10v_data},
	{ .compatible = "socionext,milbeaut-m20v-1-ccu", .data = &m20v_1_data},
	{ .compatible = "socionext,milbeaut-m20v-2-ccu", .data = &m20v_2_data},
	{ .compatible = "socionext,milbeaut-karine-ccu", .data = &karine_data},
	{ }
};

static struct platform_driver mlb_clk_driver = {
	.probe  = mlb_clk_probe,
	.driver = {
		.name = "milbeaut-ccu",
		.of_match_table = mlb_clk_dt_ids,
	},
};
builtin_platform_driver(mlb_clk_driver);

static void __init m10v_cc_init(struct device_node *np)
{
	int id;
	void __iomem *base;
	const char *parent_name;
	struct clk_hw *hw;

	mlb_clk_data = kzalloc(struct_size(mlb_clk_data, hws,
					M10V_NUM_CLKS),
					GFP_KERNEL);
	if (!mlb_clk_data)
		return;

	base = of_iomap(np, 0);
	parent_name = of_clk_get_parent_name(np, 0);
	if (!parent_name)
		goto err;

	/*
	 * This way all clocks fetched before the platform device probes,
	 * except those we assign here for early use, will be deferred.
	 */
	for (id = 0; id < M10V_NUM_CLKS; id++)
		mlb_clk_data->hws[id] = ERR_PTR(-EPROBE_DEFER);

	/*
	 * PLLs are set by bootloader so this driver registers them as the
	 * fixed factor.
	 */
	for (id = 0; id < ARRAY_SIZE(m10v_pll_fixed_data); ++id) {
		const struct mlb_clk_pll_factors *pfd =
				&m10v_pll_fixed_data[id];
		hw = clk_hw_register_fixed_factor(NULL, pfd->name,
			pfd->parent_name ? pfd->parent_name : parent_name,
			0, pfd->mult, pfd->div);
		if(IS_ERR(hw))
			goto err;
	}

	/*
	 * timer consumes "rclk" so it needs to register here.
	 */
	hw = mlb_clk_hw_register_divider(NULL, "rclk", M10V_PLL10DIV2, 0,
					base + M10V_CLKSEL(1), 0, 3, 0, m10v_rclk_table,
					&mlb_crglock, 0);
	if(IS_ERR(hw))
		goto err;
	mlb_clk_data->hws[M10V_RCLK_ID] = hw;

	mlb_clk_data->num = M10V_NUM_CLKS;
	of_clk_add_hw_provider(np, of_clk_hw_onecell_get, mlb_clk_data);
	return;

err:
	kfree(mlb_clk_data);
}
CLK_OF_DECLARE_DRIVER(m10v_cc, "socionext,milbeaut-m10v-ccu", m10v_cc_init);

static void __init m20v_cc_init(struct device_node *np)
{
	int id;
	u32 mult;
	u8 pll7sel;
	bool genclk_is = true;
	void __iomem *base;
	const char *parent_name;
	struct clk_hw *hw;
	struct clk *uclk, *aumclk, *genclk;

	uclk = of_clk_get_by_name(np, M20V_UCLKXI);
	if (IS_ERR(uclk))
		return;
	aumclk = of_clk_get_by_name(np, M20V_AUMCLKI);
	if (IS_ERR(aumclk))
		return;
	genclk = of_clk_get_by_name(np, M20V_GENCLK);
	if (IS_ERR(genclk))
		genclk_is = false;

	mlb_clk_data = kzalloc(struct_size(mlb_clk_data, hws,
					M20V_NUM_CLKS),
					GFP_KERNEL);
	if (!mlb_clk_data)
		return;

	base = of_iomap(np, 0);
	if (!base) {
		goto err;
	}

	/*
	 * This way all clocks fetched before the platform device probes,
	 * except those we assign here for early use, will be deferred.
	 */
	for (id = 0; id < M20V_NUM_CLKS; id++)
		mlb_clk_data->hws[id] = ERR_PTR(-EPROBE_DEFER);

	/*
	 * PLLs are set by bootloader so this driver registers them as the
	 * fixed factor.
	 */
	for (id = 0; id < ARRAY_SIZE(m20v_pll_fixed_data); ++id) {
		const struct mlb_clk_pll_factors *pfd =
				&m20v_pll_fixed_data[id];
		hw = clk_hw_register_fixed_factor(NULL, pfd->name,
			pfd->parent_name, 0, pfd->mult, pfd->div);
		if(IS_ERR(hw))
			goto err;
	}
	hw = clk_hw_register_fixed_factor(NULL, M20V_PLL09,
					  __clk_get_name(uclk), 0, 125, 3);
	if (IS_ERR(hw)) {
		goto err;
	}
	hw = clk_hw_register_fixed_factor(NULL, M20V_UCLKXIDIV2,
					  __clk_get_name(uclk), 0, 1, 2);
	if (IS_ERR(hw)) {
		goto err;
	}

	/* PLL5 */
	if (readl(base + M20V_PLLCNT(3)) & BIT(5)) {
		if (!genclk_is)
			goto err;
		parent_name = __clk_get_name(genclk);
		mult = M20V_PLL05_MULT160;
	} else {
		parent_name = M20V_UCLKXIDIV2;
		mult = M20V_PLL05_MULT180;
	}
	hw = clk_hw_register_fixed_factor(NULL, M20V_PLL05_2, parent_name,
					  0, mult, 2);
	if (IS_ERR(hw))
		goto err;

	/* PLL7 */
	pll7sel = (readl(base + M20V_PLLCNT(3)) >> 16) & 7;
	hw = clk_hw_register_fixed_rate(NULL, M20V_PLL07, NULL, 0,
					m20v_pll7rate[pll7sel]);
	if(IS_ERR(hw))
		goto err;

	/*
	 * MLB timer consumes "rclk" so it needs to register here.
	 */
	clk_hw_register_fixed_factor(NULL, M20V_PLL05_2DIV2, M20V_PLL05_2, 0, 1, 2);
	mlb_clk_hw_register_divider(NULL, M20V_DIV_RCLK, M20V_PLL05_2DIV2,
					CLK_SET_RATE_PARENT, base + M20V_CLKSEL(10),
					28, 4, CLK_DIVIDER_READ_ONLY, m20v_rclk_tbl,
					&mlb_crglock, 0);
	hw = mlb_clk_hw_register_gate(NULL, "rclk", M20V_DIV_RCLK,
					CLK_SET_RATE_PARENT | M20V_CRITICAL_GATE,
					base + M20V_CLKSTOP(2), 14, 0, &mlb_crglock);
	if(IS_ERR(hw))
		goto err;

	mlb_clk_data->hws[M20V_RCLK_ID] = hw;

	mlb_clk_data->num = M20V_NUM_CLKS;
	of_clk_add_hw_provider(np, of_clk_hw_onecell_get, mlb_clk_data);
	return;

err:
	kfree(mlb_clk_data);
}
CLK_OF_DECLARE_DRIVER(m20v_1_cc, "socionext,milbeaut-m20v-1-ccu", m20v_cc_init);
CLK_OF_DECLARE_DRIVER(m20v_2_cc, "socionext,milbeaut-m20v-2-ccu", m20v_cc_init);
CLK_OF_DECLARE_DRIVER(karine_cc, "socionext,milbeaut-karine-ccu", karine_cc_init);
