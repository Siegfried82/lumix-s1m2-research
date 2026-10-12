// SPDX-License-Identifier: GPL-2.0
/*
 * Copyright (C) 2020 Socionext Inc.
 * Copyright (C) 2016 Linaro Ltd.
 */

#ifdef CONFIG_ARCH_MILBEAUT_KARINE

#include <dt-bindings/clock/milbeaut,karine-clock.h>

/* KARINE register offset definition */
#define KARINE_CLKSEL1			0x0
#define KARINE_CLKSEL(n)		((n - 1) * 4 + KARINE_CLKSEL1)
#define KARINE_PLLEN			0x100
#define KARINE_PLLSRCSEL		0x104
#define KARINE_PLLDRMLT			0x108
#define KARINE_PLLAPMLT			0x110
#define KARINE_PLLAPFRC			0x114
#define KARINE_PLLDI0MLT		0x118
#define KARINE_PLLDI0FRC		0x11C
#define KARINE_PLLDI1MLT		0x120
#define KARINE_PLLDI1FRC		0x124
#define KARINE_PLLAUFSEL		0x128
#define KARINE_PLLSWFSEL		0x12C
#define KARINE_CLKSTOP1			0x200
#define KARINE_CLKSTOP(n)		((n - 1) * 4 + KARINE_CLKSTOP1)

/* KARINE clock name definition */
#define KARINE_UCLKXI			"UCLKXI"

#define KARINE_PLL24_2			"pll24-2"
#define KARINE_PLL24_3			"pll24-3"
#define KARINE_PLL21			"pll21"
#define KARINE_PLL20			"pll20"

#define KARINE_UCLKXIDIV2		"uclk-2"
#define KARINE_UCLKXIDIV3		"uclk-3"
#define KARINE_BUS400MCLK		"bus400m"
#define KARINE_BUS200MCLK		"bus200m"
#define KARINE_BUS100MCLK		"bus100m"
#define KARINE_AXI400MCLK		"axi400m"

#define KARINE_PLL24_3DIV1		"pll24-3-1"
#define KARINE_PLL24_3DIV2		"pll24-3-2"
#define KARINE_PLL24_3DIV4		"pll24-3-4"
#define KARINE_PLL24_3DIV8		"pll24-3-8"
#define KARINE_PLL24_3DIV16		"pll24-3-16"
#define KARINE_PLL21_DIV10		"pll21-10"
#define KARINE_PLL20_DIV10		"pll20-10"

#define KARINE_DIV_SDIOCLK		"div-sdioclk"
#define KARINE_DIV_SD4CLK		"div-sd4clk"
#define KARINE_DIV_SDBCLK		"div-sdbclk"
#define KARINE_DIV_RCLK			"div-rclk"
#define KARINE_DIV_RCLK64T		"div-rclk64t"
#define KARINE_DIV_EMMCCLK		"duv-emmcclk"
#define KARINE_DIV_SPICLK3		"div-spiclk3"
#define KARINE_DIV_SPICLK2		"div-spiclk2"
#define KARINE_DIV_SPICLK1		"div-spiclk1"
#define KARINE_DIV_SPICLK0		"div-spiclk0"

#define KARINE_CRITICAL_GATE	(CLK_IGNORE_UNUSED | CLK_IS_CRITICAL)

/* KARINE table data */
static const struct clk_div_table karine_emmcclk_tbl[] = {
	{ .val = 0, .div = 8 },
	{ .val = 1, .div = 9 },
	{ .val = 2, .div = 11 },
	{ .val = 3, .div = 16 },
	{ .div = 0 },
};

static const struct clk_div_table karine_sdioclk_tbl[] = {
	{ .val = 0, .div = 2 },
	{ .val = 1, .div = 4 },
	{ .val = 2, .div = 5 },
	{ .val = 3, .div = 6 },
	{ .val = 4, .div = 7 },
	{ .val = 5, .div = 8 },
	{ .val = 6, .div = 9 },
	{ .val = 7, .div = 16 },
	{ .div = 0 },
};

static const struct clk_div_table karine_sd4clk_tbl[] = {
	{ .val =  0, .div = 12 }, { .val =  1, .div = 13 },
	{ .val =  2, .div = 14 }, { .val =  3, .div = 15 },
	{ .val =  4, .div = 16 }, { .val =  5, .div = 17 },
	{ .val =  6, .div = 18 }, { .val =  7, .div = 19 },
	{ .val =  8, .div = 20 }, { .val =  9, .div = 21 },
	{ .val = 10, .div = 22 }, { .val = 11, .div = 23 },
	{ .val = 12, .div = 24 }, { .val = 13, .div = 24 },
	{ .val = 14, .div = 24 }, { .val = 15, .div = 24 },
	{ .val = 16, .div = 12 }, { .val = 17, .div = 13 },
	{ .val = 18, .div = 14 }, { .val = 19, .div = 15 },
	{ .val = 20, .div = 16 }, { .val = 21, .div = 17 },
	{ .val = 22, .div = 18 }, { .val = 23, .div = 19 },
	{ .val = 24, .div = 20 }, { .val = 25, .div = 21 },
	{ .val = 26, .div = 22 }, { .val = 27, .div = 23 },
	{ .val = 28, .div = 24 }, { .val = 29, .div = 24 },
	{ .val = 30, .div = 24 }, { .val = 31, .div = 24 },
	{ .val = 32, .div = 12 }, { .val = 33, .div = 13 },
	{ .val = 34, .div = 14 }, { .val = 35, .div = 15 },
	{ .val = 36, .div = 16 }, { .val = 37, .div = 17 },
	{ .val = 38, .div = 18 }, { .val = 39, .div = 19 },
	{ .val = 40, .div = 20 }, { .val = 41, .div = 21 },
	{ .val = 42, .div = 22 }, { .val = 43, .div = 23 },
	{ .val = 44, .div = 24 }, { .val = 45, .div = 24 },
	{ .val = 46, .div = 24 }, { .val = 47, .div = 24 },
	{ .val = 48, .div = 12 }, { .val = 49, .div = 13 },
	{ .val = 50, .div = 14 }, { .val = 51, .div = 15 },
	{ .val = 52, .div = 16 }, { .val = 53, .div = 17 },
	{ .val = 54, .div = 18 }, { .val = 55, .div = 19 },
	{ .val = 56, .div = 20 }, { .val = 57, .div = 21 },
	{ .val = 58, .div = 22 }, { .val = 59, .div = 23 },
	{ .val = 60, .div = 24 }, { .val = 61, .div = 24 },
	{ .val = 62, .div = 24 }, { .val = 63, .div = 24 },
	{ .val = 64, .div = 12 }, { .val = 65, .div = 13 },
	{ .val = 66, .div = 14 }, { .val = 67, .div = 15 },
	{ .val = 68, .div = 16 }, { .val = 69, .div = 17 },
	{ .val = 70, .div = 18 }, { .val = 71, .div = 19 },
	{ .val = 72, .div = 20 }, { .val = 73, .div = 21 },
	{ .val = 74, .div = 22 }, { .val = 75, .div = 23 },
	{ .val = 76, .div = 24 }, { .val = 77, .div = 24 },
	{ .val = 78, .div = 24 }, { .val = 79, .div = 24 },
	{ .val = 80, .div = 12 }, { .val = 81, .div = 13 },
	{ .val = 82, .div = 14 }, { .val = 83, .div = 15 },
	{ .val = 84, .div = 16 }, { .val = 85, .div = 17 },
	{ .val = 86, .div = 18 }, { .val = 87, .div = 19 },
	{ .val = 88, .div = 20 }, { .val = 89, .div = 21 },
	{ .val = 90, .div = 22 }, { .val = 91, .div = 23 },
	{ .val = 92, .div = 24 }, { .val = 93, .div = 24 },
	{ .val = 94, .div = 24 }, { .val = 95, .div = 24 },
	{ .val = 96, .div = 12 }, { .val = 97, .div = 13 },
	{ .val = 98, .div = 14 }, { .val = 99, .div = 15 },
	{ .val = 100, .div = 16 }, { .val = 101, .div = 17 },
	{ .val = 102, .div = 18 }, { .val = 103, .div = 19 },
	{ .val = 104, .div = 20 }, { .val = 105, .div = 21 },
	{ .val = 106, .div = 22 }, { .val = 107, .div = 23 },
	{ .val = 108, .div = 24 }, { .val = 109, .div = 24 },
	{ .val = 110, .div = 24 }, { .val = 111, .div = 24 },
	{ .val = 112, .div = 12 }, { .val = 113, .div = 13 },
	{ .val = 114, .div = 14 }, { .val = 115, .div = 15 },
	{ .val = 116, .div = 16 }, { .val = 117, .div = 17 },
	{ .val = 118, .div = 18 }, { .val = 119, .div = 19 },
	{ .val = 120, .div = 20 }, { .val = 121, .div = 21 },
	{ .val = 122, .div = 22 }, { .val = 123, .div = 23 },
	{ .val = 124, .div = 24 }, { .val = 125, .div = 24 },
	{ .val = 126, .div = 24 }, { .val = 127, .div = 24 },
	{ .div = 0 },
};

static const struct clk_div_table karine_sdclkb_tbl[] = {
	{ .val = 0, .div = 1 }, { .val = 1, .div = 1 },
	{ .val = 2, .div = 1 }, { .val = 3, .div = 1 },
	{ .val = 4, .div = 1 }, { .val = 5, .div = 1 },
	{ .val = 6, .div = 1 }, { .val = 7, .div = 1 },
	{ .val = 8, .div = 1 }, { .val = 9, .div = 1 },
	{ .val = 10, .div = 1 }, { .val = 11, .div = 1 },
	{ .val = 12, .div = 1 }, { .val = 13, .div = 1 },
	{ .val = 14, .div = 1 }, { .val = 15, .div = 1 },
	{ .val = 16, .div = 1 }, { .val = 17, .div = 1 },
	{ .val = 18, .div = 1 }, { .val = 19, .div = 1 },
	{ .val = 20, .div = 1 }, { .val = 21, .div = 1 },
	{ .val = 22, .div = 1 }, { .val = 23, .div = 1 },
	{ .val = 24, .div = 1 }, { .val = 25, .div = 1 },
	{ .val = 26, .div = 1 }, { .val = 27, .div = 1 },
	{ .val = 28, .div = 1 }, { .val = 29, .div = 1 },
	/* valid parameters are below */
	{ .val = 30, .div = 31 }, { .val = 31, .div = 32 },
	{ .val = 32, .div = 33 }, { .val = 33, .div = 34 },
	{ .val = 34, .div = 35 }, { .val = 35, .div = 36 },
	{ .val = 36, .div = 37 }, { .val = 37, .div = 38 },
	{ .val = 38, .div = 39 }, { .val = 39, .div = 40 },
	{ .val = 40, .div = 41 }, { .val = 41, .div = 42 },
	{ .val = 42, .div = 43 }, { .val = 43, .div = 44 },
	{ .val = 44, .div = 45 }, { .val = 45, .div = 46 },
	{ .val = 46, .div = 47 }, { .val = 47, .div = 48 },
	{ .val = 48, .div = 49 }, { .val = 49, .div = 50 },
	{ .val = 50, .div = 51 }, { .val = 51, .div = 52 },
	{ .val = 52, .div = 53 }, { .val = 53, .div = 54 },
	{ .val = 54, .div = 55 }, { .val = 55, .div = 56 },
	{ .val = 56, .div = 57 }, { .val = 57, .div = 58 },
	{ .val = 58, .div = 59 }, { .val = 59, .div = 60 },
	{ .val = 60, .div = 61 }, { .val = 61, .div = 62 },
	{ .val = 62, .div = 63 }, { .val = 63, .div = 64 },
	/* valid parameters are above */
	{ .val = 64, .div = 1 }, { .val = 65, .div = 1 },
	{ .val = 66, .div = 1 }, { .val = 67, .div = 1 },
	{ .val = 68, .div = 1 }, { .val = 69, .div = 1 },
	{ .val = 70, .div = 1 }, { .val = 71, .div = 1 },
	{ .val = 72, .div = 1 }, { .val = 73, .div = 1 },
	{ .val = 74, .div = 1 }, { .val = 75, .div = 1 },
	{ .val = 76, .div = 1 }, { .val = 77, .div = 1 },
	{ .val = 78, .div = 1 }, { .val = 79, .div = 1 },
	{ .val = 80, .div = 1 }, { .val = 81, .div = 1 },
	{ .val = 82, .div = 1 }, { .val = 83, .div = 1 },
	{ .val = 84, .div = 1 }, { .val = 85, .div = 1 },
	{ .val = 86, .div = 1 }, { .val = 87, .div = 1 },
	{ .val = 88, .div = 1 }, { .val = 89, .div = 1 },
	{ .val = 90, .div = 1 }, { .val = 91, .div = 1 },
	{ .val = 92, .div = 1 }, { .val = 93, .div = 1 },
	{ .val = 94, .div = 1 }, { .val = 95, .div = 1 },
	{ .val = 96, .div = 1 }, { .val = 97, .div = 1 },
	{ .val = 98, .div = 1 }, { .val = 99, .div = 1 },
	{ .val = 100, .div = 1 }, { .val = 101, .div = 1 },
	{ .val = 102, .div = 1 }, { .val = 103, .div = 1 },
	{ .val = 104, .div = 1 }, { .val = 105, .div = 1 },
	{ .val = 106, .div = 1 }, { .val = 107, .div = 1 },
	{ .val = 108, .div = 1 }, { .val = 109, .div = 1 },
	{ .val = 110, .div = 1 }, { .val = 111, .div = 1 },
	{ .val = 112, .div = 1 }, { .val = 113, .div = 1 },
	{ .val = 114, .div = 1 }, { .val = 115, .div = 1 },
	{ .val = 116, .div = 1 }, { .val = 117, .div = 1 },
	{ .val = 118, .div = 1 }, { .val = 119, .div = 1 },
	{ .val = 120, .div = 1 }, { .val = 121, .div = 1 },
	{ .val = 122, .div = 1 }, { .val = 123, .div = 1 },
	{ .val = 124, .div = 1 }, { .val = 125, .div = 1 },
	{ .val = 126, .div = 1 }, { .val = 127, .div = 1 },
	{ .div = 0 },
};

static const struct clk_div_table karine_rclk_tbl[] = {
	{ .val =  0, .div = 4 },
	{ .val =  1, .div = 8 },
	{ .val =  2, .div = 12 },
	{ .val =  3, .div = 16 },
	{ .div = 0 },
};

static const struct clk_div_table karine_rclk64t_tbl[] = {
	{ .val =  0, .div = 8 },
	{ .val =  1, .div = 25 },
	{ .val =  2, .div = 400 },
	{ .val =  3, .div = 400 },
	{ .div = 0 },
};

static const struct clk_div_table karine_spiclk_tbl[] = {
	{ .val = 0, .div = 4 },
	{ .val = 1, .div = 8 },
	{ .div = 0 },
};

/* KARINE fixed pll value table */
static const struct mlb_clk_pll_factors karine_pll_fixed_data[] = {
	/* name,		parent,			div,	mult */
	{KARINE_PLL24_3,	KARINE_UCLKXIDIV2,	3,	200 },
	{KARINE_PLL24_2,	KARINE_UCLKXIDIV2,	2,	200 },
	{KARINE_PLL21,		KARINE_UCLKXIDIV2,	2,	180 },
	{KARINE_PLL20,		KARINE_UCLKXIDIV3,	1,	125 },
};

/* KARINE fixed divider value table */
static const struct mlb_clk_div_fixed_data karine_div_fixed_data[] = {
	/* name,		parent,			onecell_idx,		div,	mult */
	{KARINE_PLL24_3DIV1,	KARINE_PLL24_3,		-1,			1,	1 },
	{KARINE_PLL24_3DIV2,	KARINE_PLL24_3,		-1,			2,	1 },
	{KARINE_PLL24_3DIV4,	KARINE_PLL24_3,		-1,			4,	1 },
	{KARINE_PLL24_3DIV8,	KARINE_PLL24_3,		-1,			8,	1 },
	{KARINE_PLL24_3DIV16,	KARINE_PLL24_3,		-1,			16,	1 },
	{KARINE_PLL21_DIV10,	KARINE_PLL21,		-1,			10,	1 },
	{KARINE_PLL20_DIV10,	KARINE_PLL20,		-1,			10,	1 },
	{KARINE_BUS400MCLK,	KARINE_PLL24_3DIV4,	-1,			1,	1 },
	{KARINE_BUS200MCLK,	KARINE_PLL24_3DIV4,	-1,			2,	1 },
	{KARINE_BUS100MCLK,	KARINE_PLL24_3DIV4,	-1,			4,	1 },
	{KARINE_AXI400MCLK,	KARINE_PLL24_3DIV4,	-1,			1,	1 },
	{"wdogclk",		KARINE_PLL24_3DIV4,	KARINE_WDGCLK_ID,	8,	1 },
	{"apb_pclk",		KARINE_BUS100MCLK,	KARINE_PCLK_ARM_ID,	1,	1 },
};

/* KARINE variable divider value table */
static const struct mlb_clk_div_factors karine_div_factor_data[] = {
	/* name,		parent,			tbl,			divflag,	offset,			onecell_idx,	shift,	width */
	{KARINE_DIV_EMMCCLK,	KARINE_PLL24_3,		karine_emmcclk_tbl,	0,		KARINE_CLKSEL(1),	-1,		24,	4 },
	{KARINE_DIV_SDIOCLK,	KARINE_PLL24_3,		karine_sdioclk_tbl,	0,		KARINE_CLKSEL(1),	-1,		16,	4 },
	{KARINE_DIV_SD4CLK,	KARINE_PLL24_2,		karine_sd4clk_tbl,	0,		KARINE_CLKSEL(1),	-1,		8,	8 },
	{KARINE_DIV_SDBCLK,	KARINE_PLL24_3,		karine_sdclkb_tbl,	0,		KARINE_CLKSEL(1),	-1,		0,	8 },
	{KARINE_DIV_RCLK,	KARINE_PLL21_DIV10,	karine_rclk_tbl,	0,		KARINE_CLKSEL(11),	-1,		28,	4 },
	{KARINE_DIV_RCLK64T,	KARINE_PLL24_3DIV2,	karine_rclk64t_tbl,	0,		KARINE_CLKSEL(11),	-1,		16,	4 },
	{KARINE_DIV_SPICLK3,	KARINE_PLL24_3DIV2,	karine_spiclk_tbl,	0,		KARINE_CLKSEL(11),	-1,		12,	4 },
	{KARINE_DIV_SPICLK2,	KARINE_PLL24_3DIV2,	karine_spiclk_tbl,	0,		KARINE_CLKSEL(11),	-1,		8,	4 },
	{KARINE_DIV_SPICLK1,	KARINE_PLL24_3DIV2,	karine_spiclk_tbl,	0,		KARINE_CLKSEL(11),	-1,		4,	4 },
	{KARINE_DIV_SPICLK0,	KARINE_PLL24_3DIV2,	karine_spiclk_tbl,	0,		KARINE_CLKSEL(11),	-1,		0,	4 },
};

#define KARINE_CRITICAL_GATE	(CLK_IGNORE_UNUSED | CLK_IS_CRITICAL)

/* KARINE gate value table */
static const struct mlb_clk_gate_factors karine_gate_factor_data[] = {
	/* name,		parent,			gate_flag,		offset,			onecell_idx,			shift */
	{"aclk_pcie",		KARINE_BUS400MCLK,	CLK_IGNORE_UNUSED,	KARINE_CLKSTOP(1),	KARINE_ACLK_PCIE_ID,		28 },
	{"pcieauxclk",		KARINE_UCLKXIDIV2,	CLK_IGNORE_UNUSED,	KARINE_CLKSTOP(1),	KARINE_PCIEAUXCLK_ID,		20 },
	{"hclk_sdio",		KARINE_BUS200MCLK,	CLK_IGNORE_UNUSED,	KARINE_CLKSTOP(1),	KARINE_HCLK_SDIO_ID,		18 },
	{"sdioclk",		KARINE_DIV_SDIOCLK,	CLK_IGNORE_UNUSED,	KARINE_CLKSTOP(1),	KARINE_SDIOCLK_ID,		16 },
	{"aclk_uhs2",		KARINE_BUS200MCLK,	CLK_IGNORE_UNUSED,	KARINE_CLKSTOP(1),	KARINE_ACLK_UHS2_ID,		6 },
	{"hclk_uhs1",		KARINE_BUS200MCLK,	CLK_IGNORE_UNUSED,	KARINE_CLKSTOP(1),	KARINE_HCLK_UHS1_ID,		4 },
	{"sd4clk",		KARINE_DIV_SD4CLK,	CLK_IGNORE_UNUSED,	KARINE_CLKSTOP(1),	KARINE_SD4CLK_ID,		2 },
	{"sdbclk",		KARINE_DIV_SDBCLK,	CLK_IGNORE_UNUSED,	KARINE_CLKSTOP(1),	KARINE_SDBCLK_ID,		0 },
	{"aclk_emmc",		KARINE_BUS200MCLK,	CLK_IGNORE_UNUSED,	KARINE_CLKSTOP(2),	KARINE_ACLK_EMMC_ID,		30 },
	{"emmcclk",		KARINE_DIV_EMMCCLK,	CLK_IGNORE_UNUSED,	KARINE_CLKSTOP(2),	KARINE_EMMCCLK_ID,		28 },
/*
 * rclk is registered in advance in karine_cc_init.
 * to use information in timer32 initialization.
 */
/*	{"rclk",		KARINE_DIV_RCLK,	KARINE_CRITICAL_GATE,	KARINE_CLKSTOP(2),	KARINE_RCLK_ID,			14 }, */
	{"rclk64t",		KARINE_DIV_RCLK64T,	KARINE_CRITICAL_GATE,	KARINE_CLKSTOP(2),	KARINE_RCLK64T_ID,		12 },
	{"hclk_uart_dma",	KARINE_BUS200MCLK,	KARINE_CRITICAL_GATE,	KARINE_CLKSTOP(2),	KARINE_HCLK_UART_DMA_ID,	10 },
	{"hclk_peri_bm",	KARINE_BUS200MCLK,	KARINE_CRITICAL_GATE,	KARINE_CLKSTOP(2),	KARINE_HCLK_PERI_BM_ID,		8 },
	{"hclk_peri_main",	KARINE_BUS200MCLK,	KARINE_CRITICAL_GATE,	KARINE_CLKSTOP(2),	KARINE_HCLK_PERI_MAIN_ID,	6 },
	{"hclk_peri",		KARINE_BUS100MCLK,	KARINE_CRITICAL_GATE,	KARINE_CLKSTOP(2),	KARINE_HCLK_PERI_ID,		4 },
	{"pclk_peri",		KARINE_BUS100MCLK,	KARINE_CRITICAL_GATE,	KARINE_CLKSTOP(2),	KARINE_PCLK_PERI_ID,		0 },
	{"i3cclk1",		KARINE_PLL20_DIV10,	CLK_IGNORE_UNUSED,	KARINE_CLKSTOP(4),	KARINE_I3CCLK1_ID,		26 },
	{"i3cclk0",		KARINE_PLL20_DIV10,	CLK_IGNORE_UNUSED,	KARINE_CLKSTOP(4),	KARINE_I3CCLK0_ID,		24 },
	{"hclk_spi3",		KARINE_BUS200MCLK,	CLK_IGNORE_UNUSED,	KARINE_CLKSTOP(4),	KARINE_HCLK_SPI3_ID,		14 },
	{"spiclk3",		KARINE_DIV_SPICLK3,	CLK_IGNORE_UNUSED,	KARINE_CLKSTOP(4),	KARINE_SPICLK3_ID,		12 },
	{"hclk_spi2",		KARINE_BUS200MCLK,	CLK_IGNORE_UNUSED,	KARINE_CLKSTOP(4),	KARINE_HCLK_SPI2_ID,		10 },
	{"spiclk2",		KARINE_DIV_SPICLK2,	CLK_IGNORE_UNUSED,	KARINE_CLKSTOP(4),	KARINE_SPICLK2_ID,		8 },
	{"hclk_spi1",		KARINE_BUS200MCLK,	CLK_IGNORE_UNUSED,	KARINE_CLKSTOP(4),	KARINE_HCLK_SPI1_ID,		6 },
	{"spiclk1",		KARINE_DIV_SPICLK1,	CLK_IGNORE_UNUSED,	KARINE_CLKSTOP(4),	KARINE_SPICLK1_ID,		4 },
	{"hclk_spi0",		KARINE_BUS200MCLK,	CLK_IGNORE_UNUSED,	KARINE_CLKSTOP(4),	KARINE_HCLK_SPI0_ID,		2 },
	{"spiclk0",		KARINE_DIV_SPICLK0,	CLK_IGNORE_UNUSED,	KARINE_CLKSTOP(4),	KARINE_SPICLK0_ID,		0 },
	{"pclk_gpio",		KARINE_BUS100MCLK,	KARINE_CRITICAL_GATE,	KARINE_CLKSTOP(10),	KARINE_PCLK_GPIO_ID,		12 },
	{"pclk_ts",		KARINE_BUS100MCLK,	KARINE_CRITICAL_GATE,	KARINE_CLKSTOP(14),	KARINE_PCLK_TS_ID,		30 },
	{"pclk_sys",		KARINE_BUS100MCLK,	KARINE_CRITICAL_GATE,	KARINE_CLKSTOP(14),	KARINE_PCLK_SYS_ID,		28 },
	{"aclk_ap",		KARINE_AXI400MCLK,	KARINE_CRITICAL_GATE,	KARINE_CLKSTOP(14),	KARINE_ACLK_AP_ID,		14 },
	{"csclk",		KARINE_PLL24_3DIV4,	CLK_IGNORE_UNUSED,	KARINE_CLKSTOP(14),	KARINE_CSCLK_ID,		12 },
	{"aclk_imem",		KARINE_BUS400MCLK,	KARINE_CRITICAL_GATE,	KARINE_CLKSTOP(15),	KARINE_ACLK_IMEM_ID,		30 },
	{"aclk_xdmac",		KARINE_BUS400MCLK,	KARINE_CRITICAL_GATE,	KARINE_CLKSTOP(15),	KARINE_ACLK_XDMAC_ID,		28 },
	{"aclk_usb",		KARINE_BUS400MCLK,	CLK_IGNORE_UNUSED,	KARINE_CLKSTOP(15),	KARINE_ACLK_USB_ID,		26 },
	{"hclk_hdmac",		KARINE_BUS200MCLK,	CLK_IGNORE_UNUSED,	KARINE_CLKSTOP(15),	KARINE_HCLK_HDMAC_ID,		18 },
	{"hclk_usb",		KARINE_BUS200MCLK,	CLK_IGNORE_UNUSED,	KARINE_CLKSTOP(15),	KARINE_HCLK_USB_ID,		16 },
	{"aclk_exs",		KARINE_BUS400MCLK,	CLK_IGNORE_UNUSED,	KARINE_CLKSTOP(15),	KARINE_ACLK_EXS_ID,		0 },
	{"hclk_exs",		KARINE_BUS200MCLK,	CLK_IGNORE_UNUSED,	KARINE_CLKSTOP(15),	KARINE_HCLK_EXS_ID,		0 },
	{"pclk_exs",		KARINE_BUS100MCLK,	CLK_IGNORE_UNUSED,	KARINE_CLKSTOP(15),	KARINE_PCLK_EXS_ID,		0 },
};

static const struct mlb_clk_soc_data karine_data = {
	.fixed_table = karine_div_fixed_data,
	.fixed_table2 = NULL,
	.div_table = karine_div_factor_data,
	.div_table2 = NULL,
	.mux_table = NULL,
	.gate_table = karine_gate_factor_data,
	.fixed_num = ARRAY_SIZE(karine_div_fixed_data),
	.fixed_num2 = 0,
	.div_num = ARRAY_SIZE(karine_div_factor_data),
	.div_num2 = 0,
	.mux_num = 0,
	.gate_num = ARRAY_SIZE(karine_gate_factor_data),
	.onecell_num = KARINE_NUM_CLKS,
};

static void __init karine_cc_init(struct device_node *np)
{
	int id;
	void __iomem *base;
	struct clk_hw *hw;
	struct clk *uclk;

	/* get clock source information */
	uclk = of_clk_get_by_name(np, KARINE_UCLKXI);
	if (IS_ERR(uclk))
		return;

	mlb_clk_data = kzalloc(struct_size(mlb_clk_data, hws,
					KARINE_NUM_CLKS),
					GFP_KERNEL);
	if (!mlb_clk_data)
		return;

	base = of_iomap(np, 0);
	if (!base)
		goto err;

	/*
	 * This way all clocks fetched before the platform device probes,
	 * except those we assign here for early use, will be deferred.
	 */
	for (id = 0; id < KARINE_NUM_CLKS; id++)
		mlb_clk_data->hws[id] = ERR_PTR(-EPROBE_DEFER);

	/*
	 * Register fixed divider before PLL
	 */
	hw = clk_hw_register_fixed_factor(NULL, KARINE_UCLKXIDIV2,
					  __clk_get_name(uclk), 0, 1, 2);
	if (IS_ERR(hw))
		goto err;

	hw = clk_hw_register_fixed_factor(NULL, KARINE_UCLKXIDIV3,
					  __clk_get_name(uclk), 0, 1, 3);
	if (IS_ERR(hw))
		goto err;

	/*
	 * PLLs are set by bootloader so this driver registers them as the
	 * fixed factor.
	 */
	for (id = 0; id < ARRAY_SIZE(karine_pll_fixed_data); ++id) {
		const struct mlb_clk_pll_factors *pfd =
				&karine_pll_fixed_data[id];
		hw = clk_hw_register_fixed_factor(NULL, pfd->name,
			pfd->parent_name, 0, pfd->mult, pfd->div);
		if (IS_ERR(hw))
			goto err;
	}
	/*
	 * MLB timer consumes "rclk" so it needs to register here.
	 */
	clk_hw_register_fixed_factor(NULL, KARINE_PLL21_DIV10, KARINE_PLL21,
					-1, 1, 10);
	mlb_clk_hw_register_divider(NULL, KARINE_DIV_RCLK, KARINE_PLL21_DIV10,
				CLK_SET_RATE_PARENT, base + KARINE_CLKSEL(11),
				28, 4, CLK_DIVIDER_READ_ONLY, karine_rclk_tbl,
				&mlb_crglock, 0);
	hw = mlb_clk_hw_register_gate(NULL, "rclk", KARINE_DIV_RCLK,
				CLK_SET_RATE_PARENT | KARINE_CRITICAL_GATE,
				base + KARINE_CLKSTOP(2),
				14, 0, &mlb_crglock);
	if (IS_ERR(hw))
		goto err;

	mlb_clk_data->hws[KARINE_RCLK_ID] = hw;

	mlb_clk_data->num = KARINE_NUM_CLKS;
	of_clk_add_hw_provider(np, of_clk_hw_onecell_get, mlb_clk_data);
	return;

err:
	kfree(mlb_clk_data);
}
#else
static const struct mlb_clk_soc_data karine_data = {
};

static void __init karine_cc_init(struct device_node *np)
{
}
#endif
