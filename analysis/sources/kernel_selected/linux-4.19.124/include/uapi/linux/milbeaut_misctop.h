/* SPDX-License-Identifier: GPL-2.0 */
/*
 * copyright (C) 2019 Socionext Inc.
 *               Takao Orito <<REDACTED_EMAIL>>
 */
#ifndef __MISCTOP_USERLAND_H
#define __MISCTOP_USERLAND_H

/* #include <linux/miscdevice.h> */
#include <uapi/linux/milbeaut_misctop_com.h>

#define MISCTOP_IOCTL_MAGIC         0x67
#define MISCTOP_IOCTL_MAXNR         6

#define MISCTOP_IOCTL_SET_RAMSLP	_IOW(MISCTOP_IOCTL_MAGIC, 1, struct milbeaut_misctop_argv)
#define MISCTOP_IOCTL_CLEAR_RAMSLP	_IOW(MISCTOP_IOCTL_MAGIC, 2, struct milbeaut_misctop_argv)
#define MISCTOP_IOCTL_GET_RAMSLP	_IOW(MISCTOP_IOCTL_MAGIC, 3, struct milbeaut_misctop_argv)
#define MISCTOP_IOCTL_SET_RAMSD		_IOW(MISCTOP_IOCTL_MAGIC, 4, struct milbeaut_misctop_argv)
#define MISCTOP_IOCTL_CLEAR_RAMSD	_IOW(MISCTOP_IOCTL_MAGIC, 5, struct milbeaut_misctop_argv)
#define MISCTOP_IOCTL_GET_RAMSD		_IOW(MISCTOP_IOCTL_MAGIC, 6, struct milbeaut_misctop_argv)

#endif	/* __MISCTOP_USERLAND_H */
