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
 * GNU General Public License for more details. 
 */

#include <linux/ioctl.h>

/* Total number of buffer	*/
#define DMABUF_NUM 2

/* Ioctl definitions  */
#define IOC_SCULLP_GETBUFLIST 100

//typedef struct {
//	void *		buf_kaddr;
//	size_t		buf_size;
//	loff_t		buf_offset;
//} ScullP_IOC_buf_spec;

//typedef struct {
//	size_t		size;			/* size of this struct		*/
//	int			version;		/* version of this struct	*/
//	int			buf_num;		/* number of buffer array	*/
//	ScullP_IOC_buf_spec	buf_list[DMABUF_NUM];
//} ScullP_IOC_GETBUFLIST;

