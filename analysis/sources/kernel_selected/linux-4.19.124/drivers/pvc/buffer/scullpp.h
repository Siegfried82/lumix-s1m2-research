/*
 * scullp.h -- definitions for the scullp char module
 *
 * Copyright (C) 2001 Alessandro Rubini and Jonathan Corbet
 * Copyright (C) 2001 O'Reilly & Associates
 *
 * Copyright (c) 2020 Panasonic Corporation
 * 2020-07-16 Modified
 *
 * The source code in this file can be freely used, adapted,
 * and redistributed in source or binary form, so long as an
 * acknowledgment appears in derived source files.  The citation
 * should list that the code comes from the book "Linux Device
 * Drivers" by Alessandro Rubini and Jonathan Corbet, published
 * by O'Reilly & Associates.   No warranty is attached;
 * we cannot take responsibility for errors or fitness for use.
 *
 * This file may be used subject to the terms and conditions of the
 * GNU General Public License Version 2, or any later version
 * at your option, as published by the Free Software Foundation.
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details
 */

#include <linux/ioctl.h>

#define SCULLP_MAJOR  124			/* dynamic major by default */

/* Allocate 4MB of GFP Memory */
#define DMABUF_SIZE_ORDER   10		/* = 10 power of 2 --> 1024 pages (4MB)	*/
#define DMABUF_SIZE (1 << DMABUF_SIZE_ORDER) 
#define ERR_BUF_COUNT 0xFF

typedef struct ScullP_Dev {
	void 	*dmabuf[DMABUF_NUM];
	size_t	buf_size;			/* 32-bit will suffice	*/
	int		buf_size_order;		/* 32-bit will suffice	*/
	int		buf_num;
} ScullP_Dev;

extern ScullP_Dev scullp_dev;
extern struct file_operations scullp_fops;
extern int scullp_major;     /* main.c */

