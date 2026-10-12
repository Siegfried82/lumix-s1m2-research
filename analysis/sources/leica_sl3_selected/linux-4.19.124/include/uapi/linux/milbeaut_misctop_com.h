/* SPDX-License-Identifier: GPL-2.0 */
/*
 * copyright (C) 2019 Socionext Inc.
 *               Takao Orito <<REDACTED_EMAIL>>
 */
#ifndef __MISCTOP_USERLAND_COM_H
#define __MISCTOP_USERLAND_COM_H

/* flag define used for func_flag at struct milbeaut_misctop_argv */
#define	MISCTOP_RAM_FUNC_NETSEC	0x00000100
#define	MISCTOP_RAM_FUNC_NF		0x00000800
#define	MISCTOP_RAM_FUNC_USB	0x00001000
#define	MISCTOP_RAM_FUNC_PCIE1	0x00002000
#define	MISCTOP_RAM_FUNC_PCIE0	0x00004000

/********************************************************************
 *  argument structure
 ********************************************************************/
struct milbeaut_misctop_argv {
	unsigned long func_flag;
};
#endif /* __MISCTOP_USERLAND_COM_H */
