/*
 * milbeaut_pcie_com.h - PCIe driver common include file
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

#ifndef __PCIE__H
#define __PCIE_COM_H

#include <linux/ioctl.h>


#define PCIE_IOCTL_MAGIC         'P'
#define PCIE_IOCTL_MAXNR         2

#define PCIE_IOCTL_SET_LINKUP  _IOW(PCIE_IOCTL_MAGIC, 1, int)
#define PCIE_IOCTL_SET_LINKDOWN  _IOW(PCIE_IOCTL_MAGIC, 2, int)


#endif	/* __PCIE_COM_H */
