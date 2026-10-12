/*
 * dmdrv.h        ver3.08        2014/09/05
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
#ifndef _DMDRV_H
#define _DMDRV_H
/*****************************************************************************
 *****************************************************************************/
/* for user API */

/* Block Unit Size */
#define DM_BLOCKUNIT_SIZE	0x8000

/* Mask for Block Unit Size */
#define DM_BLOCKUNIT_SIZE_MASK	0x7fff

/* log2(DM_BLOCKUNIT_SIZE) */
#define DM_BLOCKUNIT_SIZE_SHIFT	15

/* Number of block size units */
#if defined(CONFIG_DM_BLOCKUNIT_NUM)
# define DM_BLOCKUNIT_NUM	CONFIG_DM_BLOCKUNIT_NUM
#else /* ! CONFIG_DM_BLOCKUNIT_NUM */
# define DM_BLOCKUNIT_NUM	512  /* 16MB (2008/08/25) */
/* # define DM_BLOCKUNIT_NUM	256 */   /* 8MB (040213tokada) */
#endif /* CONFIG_DM_BLOCKUNIT_NUM */

/* Total memory size for DM */
#define DM_MALLOC_SIZE  	(DM_BLOCKUNIT_SIZE*DM_BLOCKUNIT_NUM)

/* Max size for dm_malloc(see DM_PAGE_BLOCKUNIT_NUM) */
#if defined(CONFIG_DM_MALLOC_MAX_SIZE)
# define DM_MALLOC_MAX_SIZE	CONFIG_DM_MALLOC_MAX_SIZE
#else /* ! CONFIG_DM_MALLOC_MAX_SIZE */
# define DM_MALLOC_MAX_SIZE	0x400000 /* 4MB (2008/08/25) */
/* # define DM_MALLOC_MAX_SIZE	0x200000 */ /* 2MB */
#endif /* CONFIG_DM_MALLOC_MAX_SIZE */

/* for ioctl() */
#define DM_IOCTL_MALLOC			_IOW('y', 1, dm_ioctl_parm)
#define DM_IOCTL_FREE			_IOW('y', 2, dm_ioctl_parm)
#define DM_IOCTL_RESET			_IO ('y', 3)
#define DM_IOCTL_GET_BUS_ADDR	_IOR('y', 4, dm_ioctl_addr)
#define DM_IOCTL_GET_VIRT_ADDR	_IOR('y', 5, dm_ioctl_addr)

/* params for ioctl() */
typedef struct {
	unsigned long	size;	/* size required  */
	long		offset; /* asigned address (offset) */
} dm_ioctl_parm;

typedef struct {
        long            offset;   /* offset */
        void           *bus_addr; /* address */
} dm_ioctl_addr;

/*****************************************************************************
 *****************************************************************************/
#ifdef __KERNEL__
#include <asm/page.h>

/*
  major number of DM
 */
#define DM_MAJOR_NUMBER 243 /* tokada040116 */
#define DM_MINOR_NUMBER		0
#define DM_MINOR_COUNT		1
#define DM_DEVICE_NAME		"dm"

/*
  when you set size of "free list table" on N,
  continuous blocks more than N belong to the Nth list.
  In this system, we prepare list for 1 - 19, and for more than 20.
 */
#if defined(CONFIG_DM_FREELIST_NUM)
# define DM_FREELIST_NUM	CONFIG_DM_FREELIST_NUM /* size of "free list table" */
#else /* ! CONFIG_DM_FREELIST_NUM */
# define DM_FREELIST_NUM		20
#endif /* CONFIG_DM_FREELIST_NUM */

/* 
  This parameter depends on the kernel and the architecture.
  In SH4 on Linux 2.4, PAGE_SIZE=4096B MAX_ORDER=9.
  In MPC83xx on Linux 2.6, PAGE_SIZE=4096B MAX_ORDER=10.
 */
#if defined(CONFIG_DM_ORDER)
# define	DM_ORDER	CONFIG_DM_ORDER
#else /* ! CONFIG_DM_ORDER */
# define	DM_ORDER		10 /* 1024 (2008/08/25) */
#endif /* CONFIG_DM_ORDER */

#define DM_PAGE_SIZE		(PAGE_SIZE << DM_ORDER)	/* 512=2^9 or 1024=2^10 (2008/06/02) */
#define DM_PAGE_SIZE_SHIFT	(PAGE_SHIFT + DM_ORDER) /* 2008/06/02 */

/* number of block units per page */
#define DM_PAGE_BLOCKUNIT_NUM	(DM_PAGE_SIZE/DM_BLOCKUNIT_SIZE)
#define DM_PAGE_BLOCKUNIT_SHIFT		(DM_PAGE_SIZE_SHIFT - DM_BLOCKUNIT_SIZE_SHIFT)    /* log2(DM_PAGE_BLOCKUNIT_NUM) (2008/06/02) */

/* number of pages reserved in initialization */
#define DM_PAGE_NUM		(DM_MALLOC_SIZE/DM_PAGE_SIZE)

void *dm_user_to_kernel(void *add);
int doDM_MALLOC(dm_ioctl_parm *parm);
int doDM_FREE(dm_ioctl_parm *parm);
int doDM_GET_BUS_ADDR(dm_ioctl_addr *addr);
int doDM_GET_VIRT_ADDR(dm_ioctl_addr *addr);

#endif /* __KERNEL__ */
#endif /* _DMDRV_H */
