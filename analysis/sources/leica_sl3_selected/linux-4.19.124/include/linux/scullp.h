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

//#define SCULLP_MAJOR		124	/* dynamic major by default */	
#define SCULLP_MAJOR		231	/* dynamic major by default */	
#define DMABUF_NUM 			CONFIG_BUFFER_NUM /* XXX */
#define DMABUF_SIZE_ORDER   CONFIG_BUFFER_SIZE_ORDER	/* = 10 power of 2 --> 1024 pages (4MB) XXX */
#define DMABUF_SIZE_CHUNK	(PAGE_SIZE * (1<<DMABUF_SIZE_ORDER)) /* XXX */
#define RW_BUFFER_SIZE		(512 * 1024) /* XXX */

#define ERR_BUF_COUNT		0xFF

/* Structure for external fo driver  */
typedef struct {
	void *	buf_kaddr;
	void *	buf_phyaddr;
#if defined(CONFIG_BUFFER_DM) /* XXX */
	size_t	buf_size_chunk;
#else /* ! CONFIG_BUFFER_DM */ /* XXX */
	size_t	buf_size;
#endif /* CONFIG_BUFFER_DM */ /* XXX */
	loff_t	buf_offset;
} ScullP_IOC_buf_spec;

typedef struct {
	int		valid_buf_num;	/* number of valid buffer array   */
	ScullP_IOC_buf_spec	buf_list[DMABUF_NUM];
} ScullP_IOC_GETBUFLIST;

/* Ioctl definitions  */
#define IOC_SCULLP_GETBUFLIST 100
#define IOC_SCULLP_GETPHYADDR 101
#define IOC_SCULLP_BUFCPYPTOV 102
#define IOC_SCULLP_BUFCPYVTOP 103

/* Structure for driver itself	*/
typedef struct ScullP_Dev {
	void *	dmabuf[DMABUF_NUM];
	size_t	buf_size_chunk;
	size_t	buf_size;	/* 512KB of the allocated DM buffer #0	*/
	int		buf_num;
} ScullP_Dev;
