/* SPDX-License-Identifier: GPL-2.0 */
/*
 * Milbeaut Updown parent driver
 * Copyright (C) 2019 Socionext Inc.
 */

#ifndef _LINUX_MILBEAUT_UPDOWN_H_
#define _LINUX_MILBEAUT_UPDOWN_H_

#define MLB_UPDOWN_UDCR		0x0		/* Updown Count Reg		*/
#define MLB_UPDOWN_RCR		0x4		/* Reload Compare Reg	*/
#define MLB_UPDOWN_CSR		0xC		/* Counter Status Reg	*/
#define MLB_UPDOWN_CCR		0x14	/* Counter Control Reg	*/

/* MLB_UPDOWN_CSR - bit fields */
#define MLB_UPDOWN_CSTR		BIT(7)
#define MLB_UPDOWN_UDIE		BIT(5)
#define MLB_UPDOWN_CMPF		BIT(4)
#define MLB_UPDOWN_OVFF		BIT(3)
#define MLB_UPDOWN_UDFF		BIT(2)

/* MLB_UPDOWN_CCR - bit fields */
#define MLB_UPDOWN_FIXED	BIT(15)
#define MLB_UPDOWN_CMS		GENMASK(11, 10)
#define MLB_UPDOWN_CES		GENMASK(9, 8)
#define MLB_UPDOWN_CTUT		BIT(6)
#define MLB_UPDOWN_RLDE		BIT(4)

/* MLB_UPDOWN max count value */
#define MLB_UPDOWN_MAX_COUNT	0xFFFF

/* MLB_UPDOWN rising edge detection */
#define MLB_UPDOWN_RISING_EDGE		BIT(9)

/* MLB_UPDOWN mode */
#define MLB_UPDOWN_MODE		1

#endif
