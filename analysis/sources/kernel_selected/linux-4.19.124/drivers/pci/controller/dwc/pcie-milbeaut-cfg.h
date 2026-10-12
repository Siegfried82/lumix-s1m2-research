/*
 * pcie-milbeaut-cfg.h - PCIe config defined
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


#ifndef _PCIE_MILBEAUT_CFG_H
#define _PCIE_MILBEAUT_CFG_H

/* de-enphasis setting */
#define PORT_LOGIC_DEEMPHASIS_6		(0x00 << 20)	// de-emphasis 6dB
#define PORT_LOGIC_DEEMPHASIS_3P5	(0x01 << 20)	// de-emphasis 3.5dB

#define PORT_LOGIC_DEEMPHASIS		PORT_LOGIC_DEEMPHASIS_6

#endif /* _PCIE_MILBEAUT_CFG_H */
