/* SPDX-License-Identifier: GPL-2.0 */
/*
 * copyright (C) 2019 Socionext Inc.
 *               Takao Orito <<REDACTED_EMAIL>>
 */
#ifndef __NOC_USERLAND_H
#define __NOC_USERLAND_H

#include <uapi/linux/milbeaut_noc_com.h>

#define NOC_IOCTL_MAGIC         0x68
#define NOC_IOCTL_MAXNR         2

#define NOC_IOCTL_SET_BANK  _IOW(NOC_IOCTL_MAGIC,\
		 1, struct milbeaut_noc_bank_argv)
#define NOC_IOCTL_GET_BANK  _IOW(NOC_IOCTL_MAGIC,\
		 2, struct milbeaut_noc_bank_argv)

#endif  /* __NOC_USERLAND_H */
