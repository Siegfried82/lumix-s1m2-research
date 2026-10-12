/*
 * dmdrv.c - DM driver
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
/*****************************************************************************
 *****************************************************************************/
#define DM_VERSION "3.09" /* 2014/11/27 */

#if defined(CONFIG_MODVERSIONS) && ! defined(MODVERSIONS)
#include <config/modversions.h>
#define MODVERSIONS
#endif

#include <linux/kernel.h>
#include <linux/errno.h>
#include <linux/fs.h>
#include <linux/module.h>
#include <linux/mm.h>
#include <linux/cdev.h>
#include <linux/uaccess.h>
#include <asm/page.h>
#include <linux/proc_fs.h> /* for proc */
#include <linux/seq_file.h>
#include <linux/semaphore.h> /* for semaphore */
#include <asm/io.h>  /* for virt_to_bus */

#include <linux/dmdrv.h>
#include <linux/dma-mapping.h>

#ifndef __virt_to_bus
#define __virt_to_bus	__virt_to_phys
#define __bus_to_virt	__phys_to_virt
#define __pfn_to_bus(x)	__pfn_to_phys(x)
#define __bus_to_pfn(x)	__phys_to_pfn(x)
#endif

MODULE_AUTHOR("Panasonic");
MODULE_LICENSE("Panasonic");

/*****************************************************************************
 *****************************************************************************/
int 	__init init_dm(void);
void 	*dm_user_to_kernel(void *uaddr);

static int dm_open(struct inode *inode, struct file *file);
static int dm_release(struct inode *inode, struct file *file);
static int dm_mmap(struct file *file, struct vm_area_struct *vma);
static long dm_ioctl(struct file *filp, unsigned int cmd, unsigned long arg);

/*** file operations for DM driver ***/
static struct file_operations fops = {
  .open 			= dm_open,
  .release			= dm_release,
  .mmap				= dm_mmap,
  .unlocked_ioctl	= dm_ioctl,
};

/*** Major number of DM ***/
static int dm_major = DM_MAJOR_NUMBER;
static int dm_open_count = 0;		/* reference counter */
/*****************************************************************************
 *****************************************************************************/
static int	dm_malloc_count;	/* counter for aligned blocks */

/*** page administration ***/
static char 	*dm_pages[DM_PAGE_NUM];	/* table for page administration */
static int	dm_current_page;	/* current handling page */
static int	dm_allocated;		/* number of blocks aligned in a page */

#ifdef CONFIG_DM_SUPPORT_P2
static char			*dm_sd_pages[CONFIG_DM_P2_SLOT];
static dma_addr_t	dm_sd_phys_addr[CONFIG_DM_P2_SLOT];
#endif //CONFIG_DM_SUPPORT_P2

/*** block administaration ***/
typedef struct dm_blockinfo_tag {
	long    offset;                  /* offset address (from the top of DM) */
	struct  dm_blockinfo_tag  *next; /* "free list" */
	int     num;                     /* number of continuous blocks */
	int     allocation_flag;         /* already allocated or not ?
                                             allocated:1, not allocated:0  by Y.Takano */
} dm_blockinfo;

/*** for searching free blocks ***/
static int	book_mark;		/* next starting position of search (0-511) */

/*** table for block administration ***/
static dm_blockinfo dm_blockinfo_tbl[DM_BLOCKUNIT_NUM];

/*** "free list table" */
static dm_blockinfo *dm_freelist[DM_FREELIST_NUM];

/*** current depth of the "free list" */
static int dm_freelist_count[DM_FREELIST_NUM];

/*** max depth of the "free list" */
static int dm_freelist_limit[DM_FREELIST_NUM]
//   ={128,64,42,32,25,21,18,16,14,12,11,10, 9, 9, 8, 8, 7, 7, 6, 6};
//   ={ 32, 3, 3, 3, 3, 3, 3, 3, 3, 3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1}; //040227
     ={  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}; //070613 for fragment problem on 16G ClipCopy
     //  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20more

static int doDM_INIT(void);
static int doDM_RESET(void);

static int doDM_EXIT(void);

//static dm_blockinfo *alloc_newblock(int n);
//static dm_blockinfo *search_freelist(int n);
static dm_blockinfo *search_freeblock(int n);

int dm_read_proc(struct seq_file *s, void *unused);
int dm_param_read_proc(struct seq_file *s, void *unused);

static struct semaphore sem;

static struct cdev dm_drv;

static int proc_dm_open(struct inode *inode, struct file *file)
{
	return single_open(file, dm_read_proc, PDE_DATA(inode));
}

static int proc_dm_param_open(struct inode *inode, struct file *file)
{
	return single_open(file, dm_param_read_proc, PDE_DATA(inode));
}

static struct file_operations dm_proc_ops = {
	.owner		= THIS_MODULE,
	.open		= proc_dm_open,
	.read		= seq_read,
	.release	= single_release,
};

static struct file_operations dm_param_proc_ops = {
	.owner		= THIS_MODULE,
	.open		= proc_dm_param_open,
	.read		= seq_read,
	.release	= single_release,
};

/*****************************************************************************
  <<CLEAN UP>>
 *****************************************************************************/
void __exit cleanup_dm(void)
{
	int devno = MKDEV(dm_major, 0);

	/* remove /proc entry */
	remove_proc_entry("dm", NULL);
	remove_proc_entry("dmparam", NULL); /* Added 2009/01/21 */

	/* remove drive from the drive list */
	cdev_del(&dm_drv);
	unregister_chrdev_region(devno, DM_MINOR_COUNT);

	/* free resources */
	doDM_EXIT();
}

/*****************************************************************************
 << INITIALIZING SEQUENCE >>
 *****************************************************************************/
int __init init_dm(void)
{
	int r, r_init;
	int devno = MKDEV(dm_major, 0);

	/* initializing semaphoe */
	sema_init(&sem, 1);

	/* register the driver */
	r = register_chrdev_region(devno, DM_MINOR_COUNT, DM_DEVICE_NAME);
	if(r) {
		return r;
	}

	cdev_init(&dm_drv, &fops);
	dm_drv.owner = THIS_MODULE;

	r = cdev_add(&dm_drv, devno, 1);
	if (r < 0) {
		unregister_chrdev_region(devno, DM_MINOR_COUNT);
		return r;
	}

	/* initializing the resources */
	r_init = doDM_INIT();

	/* make /proc/driver/dm active */
	proc_create_data("driver/dm", 0, NULL, &dm_proc_ops, NULL);

	/* Added 2009/01/21 */
	proc_create_data("driver/dmparam", 0, NULL, &dm_param_proc_ops, NULL);

	return r_init;
}
/*****************************************************************************
 << entry function for OPEN >>
 *****************************************************************************/
static int dm_open(struct inode *inode, struct file *file)
{
	down(&sem);

	dm_open_count++;

	up(&sem);

	return 0;
}

/*****************************************************************************
 << entry function for CLOSE >>
 *****************************************************************************/
static int dm_release(struct inode *inode, struct file *file)
{
	down(&sem);

	dm_open_count--;

	/* memory leak ? */
	if(dm_open_count == 0 && dm_malloc_count != 0){
	  /* leak! */
	  printk(KERN_ERR "[DM] memory leak! (%d blocks)\n", dm_malloc_count);

	  /* initialize, and solve the problem */
	  doDM_RESET();
	}

	up(&sem);

	return 0;
}

/*****************************************************************************
 << entry function for MMAP >>
 *****************************************************************************/
static int dm_mmap(struct file *file, struct vm_area_struct *vma)
{
	int i;
	struct page *map, *mapend;
	long size;

	size = vma->vm_end - vma->vm_start;

	down(&sem);

	for(i = 0; i < DM_PAGE_NUM; i++){
		map = virt_to_page(dm_pages[i]);
		mapend = virt_to_page(dm_pages[i]+DM_PAGE_SIZE-1);
		while(map<=mapend){
//			mem_map_reserve(map);	//2007.12.11 Change mem_map_reserve
			SetPageReserved(map);	//           to SetPageReserved by mitsu.
			map++;
		}
//		if(remap_page_range(vma->vm_start+i*DM_PAGE_SIZE,	//2007.12.11 Change remap_page_range
		if(remap_pfn_range(vma, vma->vm_start+i*DM_PAGE_SIZE,	//           to remap_pfn_range by mitsu.
				    __pa(dm_pages[i]) >> PAGE_SHIFT,
				    ((DM_PAGE_SIZE<size)?DM_PAGE_SIZE:size),
				    vma->vm_page_prot)){
		        up(&sem);
			return -EAGAIN;
		}
		size -= DM_PAGE_SIZE;
		if(size <= 0) break;
	}

	up(&sem);

	return 0;
}

/*****************************************************************************
 << entry function for IOCTL >>
 *****************************************************************************/
static long dm_ioctl(struct file *filp, unsigned int cmd, unsigned long arg)
{
        int r;
	dm_ioctl_parm parm;
	dm_ioctl_addr addr;

	down(&sem);

	switch(cmd){
	  case DM_IOCTL_MALLOC:
	        if(copy_from_user(&parm, (dm_ioctl_parm *)arg, sizeof(parm))){
		  printk("[DM:l.%d] copy_from_user error!\n", __LINE__);
			r = -ENOMEM;
			goto End;
		}

		r = doDM_MALLOC(&parm);

		if(copy_to_user((dm_ioctl_parm *)arg, &parm, sizeof(parm))){
		  printk("[DM:l.%d] copy_to_user error!\n", __LINE__);
			r = -ENOMEM;
			goto End;
		}
		break;

	  case DM_IOCTL_FREE:
	        if(copy_from_user(&parm, (dm_ioctl_parm *)arg, sizeof(parm))){
		  printk("[DM:l.%d] copy_from_user error!\n", __LINE__);
			r = -ENOMEM;
			goto End;
		}

		r = doDM_FREE(&parm);
		break;

	  case DM_IOCTL_RESET:
	  	r = doDM_RESET();
		break;

	  case DM_IOCTL_GET_BUS_ADDR:
	        if(copy_from_user(&addr, (dm_ioctl_addr *)arg, sizeof(addr))){
		  printk("[DM:l.%d] copy_from_user error!\n", __LINE__);
			r = -ENOMEM;
			goto End;
		}

		r = doDM_GET_BUS_ADDR(&addr);

		if(copy_to_user((dm_ioctl_addr *)arg, &addr, sizeof(addr))){
		  printk("[DM:l.%d] copy_to_user error!\n", __LINE__);
			r = -ENOMEM;
			goto End;
		}
		break;

	  case DM_IOCTL_GET_VIRT_ADDR:
	        if(copy_from_user(&addr, (dm_ioctl_addr *)arg, sizeof(addr))){
		  printk("[DM:l.%d] copy_from_user error!\n", __LINE__);
			r = -ENOMEM;
			goto End;
		}

		r = doDM_GET_VIRT_ADDR(&addr);

		if(copy_to_user((dm_ioctl_addr *)arg, &addr, sizeof(addr))){
		  printk("[DM:l.%d] copy_to_user error!\n", __LINE__);
			r = -ENOMEM;
			goto End;
		}
		break;

	  default:
	        r = -EINVAL;
		break;
	}

End:
	up(&sem);

	return r;
}

#ifdef CONFIG_DM_SUPPORT_P2
int get_dm_sd_pages(int slot, unsigned long *virt_addr, unsigned long *phys_addr)
{
	if( (slot < 0) || (slot >= CONFIG_DM_P2_SLOT) )
		return -EINVAL;

	if( (virt_addr == NULL) || (phys_addr == NULL) )
		return -EINVAL;

	*virt_addr = (unsigned long)dm_sd_pages[slot];

#ifdef CONFIG_DM_P2_MAP_ADDR_0
	if(slot == 0){
		*phys_addr = CONFIG_DM_P2_MAP_ADDR_0;
		return 0;
	}
#endif //CONFIG_DM_P2_MAP_ADDR_0

	*phys_addr = (unsigned long)dm_sd_phys_addr[slot];

	return 0;
}
EXPORT_SYMBOL(get_dm_sd_pages);

void get_sd_free_pages(int slot, void **virt_addr, dma_addr_t *phys_addr)
{
#ifdef CONFIG_DM_P2_MAP_ADDR_0
	if(slot == 0){
		*virt_addr = ioremap_nocache(CONFIG_DM_P2_MAP_ADDR_0, PAGE_SIZE << 10);
		*phys_addr = CONFIG_DM_P2_MAP_ADDR_0;
		return;
	}
#endif //CONFIG_DM_P2_MAP_ADDR_0

	*virt_addr = dma_alloc_coherent(NULL, PAGE_SIZE << 10, phys_addr, GFP_KERNEL);
}

void sd_free_pages(int slot, void *virt_addr, dma_addr_t phys_addr)
{
#ifdef CONFIG_DM_P2_MAP_ADDR_0
	if(slot == 0){
		iounmap(virt_addr);
		return;
	}
#endif //CONFIG_DM_P2_MAP_ADDR_0
	dma_free_coherent(NULL, PAGE_SIZE << 10, virt_addr, phys_addr);
}
#endif //CONFIG_DM_SUPPORT_P2

/*****************************************************************************
 << INITIALIZING THE MEMORY RESOURCE >>
*****************************************************************************/
static int doDM_INIT()
{
	int i;

	/* show version no. */
	printk(KERN_INFO "[DM] dm driver ver%s \n",DM_VERSION);
	
#ifdef CONFIG_DM_SUPPORT_P2
	for(i = 0; i < CONFIG_DM_P2_SLOT; i++){
		get_sd_free_pages(i, (void**)&dm_sd_pages[i], &dm_sd_phys_addr[i]);
		if (dm_sd_pages[i] == NULL){
			while(i > 0){
				i--;
				sd_free_pages(i, dm_sd_pages[i], dm_sd_phys_addr[i]);
			}
			printk(KERN_ERR "[DM] can't get free pages for sd-driver i=%x\n",i);
			return -ENOMEM;
		}
	}
#endif //CONFIG_DM_SUPPORT_P2

	/* get pages (2MB) DM_PAGE_NUM times */
	for(i = 0; i < DM_PAGE_NUM; i++){
		dm_pages[i] = (char *)__get_free_pages(GFP_KERNEL, DM_ORDER);
		if (dm_pages[i] == NULL){
#ifdef CONFIG_DM_SUPPORT_P2
			int j;
			for(j = 0; j < CONFIG_DM_P2_SLOT; j++){
				sd_free_pages(j, dm_sd_pages[j], dm_sd_phys_addr[j]);
			}
#endif //CONFIG_DM_SUPPORT_P2
			while(i > 0){
				i--;
				free_pages((unsigned long)dm_pages[i], 
				            DM_ORDER);
			}
			printk(KERN_ERR "[DM] can't get free pages i=%x\n",i);
			return -ENOMEM;
		}
	}
	/* initializing the memory allocation information */
	doDM_RESET();

	return 0;
}

/*****************************************************************************
 << FREE THE RESERVED MEMORY RESOURCE >>
 *****************************************************************************/
static int doDM_EXIT()
{
	int i;
	struct page *map, *mapend;

	/* free all of the allocated pages */
	for(i = 0; i < DM_PAGE_NUM; i++){
		/* Add by mitsu */
		map = virt_to_page(dm_pages[i]);
		mapend = virt_to_page(dm_pages[i]+DM_PAGE_SIZE-1);
		while(map<=mapend){
			ClearPageReserved(map);	//           to SetPageReserved by mitsu.
			map++;
		}
		/*---------------*/

		free_pages((unsigned long)dm_pages[i], DM_ORDER);
	}

#ifdef CONFIG_DM_SUPPORT_P2
	for(i = 0; i < CONFIG_DM_P2_SLOT; i++){
		sd_free_pages(i, dm_sd_pages[i], dm_sd_phys_addr[i]);
	}
#endif //CONFIG_DM_SUPPORT_P2

	return 0;
}

/*****************************************************************************
 << INITIALIZING THE ALLOCATION INFORMATION >>
 *****************************************************************************/
static int doDM_RESET()
{
	int i;
	dm_blockinfo *ptr;

	/* initializing tables */
	memset(dm_blockinfo_tbl, 0, sizeof(dm_blockinfo_tbl));
	memset(dm_freelist, 0, sizeof(dm_freelist));
	memset(dm_freelist_count, 0, sizeof(dm_freelist_count));

	/* set offset values in block administration data */
	for(i = 0; i < DM_BLOCKUNIT_NUM; i++){
		ptr = dm_blockinfo_tbl + i;
		ptr->offset = i << DM_BLOCKUNIT_SIZE_SHIFT;
	}

	/* initialize allocation data */
	dm_current_page	= 0;
	dm_allocated	= 0;
	dm_malloc_count	= 0;

	/* initialize the start position for search */
	book_mark = DM_BLOCKUNIT_NUM / 2; /* from the half position of DM */

	return 0;
}

/*****************************************************************************
 << MEMORY ALLOCATION (DM_MALLOC) >>
 *****************************************************************************/
int doDM_MALLOC(dm_ioctl_parm *parm)
{
	unsigned long size;
	int n;
	dm_blockinfo *ptr;

	size = parm->size;	

	/* (1)size != Ingeter * DM_BLOCKUNIT_SIZE */
	/* (2)size < DM_BLOCKUNIT_SIZE            */
	/* (3)size > DM_MALLOC_MAX_SIZE           */
	/* we supporse that (1),(2) and (3) are blocked in library layer */
	
	/* get number of required blocks */
	n = size >> DM_BLOCKUNIT_SIZE_SHIFT;

	/* find from "free list" */
#if 0 //This code includes bug which return same area.
	ptr = search_freelist(n);
	if(ptr == NULL){
		/* finding from "free list" failed, so execute fast search */
		ptr = alloc_newblock(n);
		if(ptr == NULL){
			/* fast search failed, find from whole fo DM */
			ptr = search_freeblock(n);
			if(ptr == NULL){
				/* All failed */
				parm->offset = -1;
				printk(KERN_ERR "[DM] %s failed!\n", __FUNCTION__);
				return (-ENOMEM);
			}
		}
	}
#else
	/* find from whole fo DM */
	ptr = search_freeblock(n);
	if(ptr == NULL){
		/* All failed */
		parm->offset = -1;
		printk(KERN_ERR "[DM] %s failed!\n", __FUNCTION__);
		return (-ENOMEM);
	}
#endif

	/* in case you got space to allocate ... */

	/* copy the information to user area */
	parm->offset = ptr->offset;

	/* increment total number of allocated blocks */
	dm_malloc_count += n;

	return 0;

}
/*****************************************************************************
 << FREE LIST SEARCH >>
 *****************************************************************************/
#if 0
static dm_blockinfo *search_freelist(int n)
{
	dm_blockinfo *ptr, *ptrsft, *prev;
	int j;

	if (n < DM_FREELIST_NUM){
		/* prepared size ? */
		if(dm_freelist[n-1] != NULL){
			/* found in free list */
			ptr = dm_freelist[n-1];
			dm_freelist[n-1] = ptr->next;
			dm_freelist_count[n-1] --; /* decrement the depth of the list */
			/* update the information of n th list */
			for(j = 0; j < n; j++){
				ptrsft = ptr + j;
				/* ptrsft->offset = (i + j) * DM_BLOCKUNIT_SIZE; */
				/* ptrsft->num  = n - j; */
				ptrsft->next = NULL;
				/* ptrsft->page = dm_current_page; */
				ptrsft->allocation_flag = 1;
			}
		} else {
			/* search failed */
			ptr = NULL;
		}

	} else {
		/* required size exceeds the prepared one */
	        ptr = dm_freelist[DM_FREELIST_NUM-1]; /* list for unprepared size */
		prev = NULL;
		
		while(ptr != NULL){
		        /* if(ptr->num >= n) break; */
			if(ptr->num == n) break;
			prev = ptr;
			ptr = ptr->next;
		}
		if(ptr != NULL){
			/* found in free list */
			if(prev == NULL){
				dm_freelist[DM_FREELIST_NUM-1] = ptr->next;
			} else {
				prev->next = ptr->next;
			}
			
			dm_freelist_count[DM_FREELIST_NUM-1] --; /* decrement the depth of the list */

			/* update the information of n th list */
			for(j = 0; j < n; j++){
				ptrsft = ptr + j;
				/* ptrsft->offset = (i + j) * DM_BLOCKUNIT_SIZE; */
				/* ptrsft->num  = n - j; */
				ptrsft->next = NULL;
				/* ptrsft->page = dm_current_page; */
				ptrsft->allocation_flag = 1;
			}
		} else {
			/* search in free list failed */
			ptr = NULL;
		}
	}
	return (ptr);
}
#endif

/*****************************************************************************
 << ALLOCATION OF NEW BLOCKS (fast search) >>
 *****************************************************************************/
#if 0
static dm_blockinfo *alloc_newblock(int n)
{
	dm_blockinfo *ptr;
	dm_blockinfo *ptrsft;
	int i,j;
	
	/* cases except (0 < size <= DM_PAGE_SIZE) are blocked in library layer.
	  if(n > DM_PAGE_BLOCKUNIT_NUM){
		return NULL;
	}
	*/

	if(n > DM_PAGE_BLOCKUNIT_NUM - dm_allocated){
		/* we can't find enogh space, go next page */
		if(dm_current_page+1 >= DM_PAGE_NUM){
			/* no "next page" */
			return(NULL);
		}else{
			/* set "next page" */
			dm_current_page++; 
			dm_allocated = 0;
		}
	}

	/* allocate new blocks */
	i = (dm_allocated + DM_PAGE_BLOCKUNIT_NUM * dm_current_page);
	ptr = dm_blockinfo_tbl + i;

	/* update search pointer */
	dm_allocated += n;

	/* set information for each blocks */
	for(j = 0; j < n; j++){
		ptrsft = dm_blockinfo_tbl + i + j;
		/* ptrsft = dm_blockinfo_tbl[i + j]??????;*/
		/* ptrsft->offset = (i + j) * DM_BLOCKUNIT_SIZE; */
		ptrsft->num  = n - j;
		ptrsft->next = NULL;
		/* ptrsft->page = dm_current_page; */
		ptrsft->allocation_flag = 1;
	}

	return(ptr); /* return the address of the top block */
}
#endif

/*****************************************************************************
 << SEARCHING IN WHOLE OF DM >>
 *****************************************************************************/
static dm_blockinfo *search_freeblock(int n)
{
  	dm_blockinfo *ptr;
	dm_blockinfo *ptrsft;
	int j;
	int blknum;
	int cont;

	cont = 0; /* continuance counter */
	ptr = NULL;

	for(j = 0; j < DM_BLOCKUNIT_NUM; j++){
	  /* whole search (start position stored in book_mark) */
		blknum = (book_mark + j) % DM_BLOCKUNIT_NUM;

		/* page boundary */
		if(blknum % DM_PAGE_BLOCKUNIT_NUM == 0){
			cont = 0; 
		}

		/* look up block information table */
		ptr = dm_blockinfo_tbl + blknum;

		/* empty block and not stored in free list ? */
		if((ptr->allocation_flag == 0)&&(ptr->num == 0)){ 
			cont ++;
			if(cont == n){ /* found required blocks */
			        book_mark = blknum + 1; /* prepare for next search */
				ptr = dm_blockinfo_tbl + blknum - n + 1; /* get the top of the continuous blocks */

				/*  set information for each blocks */
				for(j = 0; j < n; j++){
					ptrsft = ptr + j;
					/* ptrsft->offset = (i + j) * DM_BLOCKUNIT_SIZE; */
					ptrsft->num  = n - j;
					ptrsft->next = NULL;
					/* ptrsft->page = dm_current_page; */
					ptrsft->allocation_flag = 1;
				}
				return(ptr); /* return the top of the blocks */
			}
		}else{
			cont = 0;
		}
	}

	return(NULL); /* search failed */
}

/*****************************************************************************
 FREE BLOCKS (DM_FREE)
 *****************************************************************************/
int doDM_FREE(dm_ioctl_parm *parm)
{
	long offset;
	int n, m;
	int i, j;
	dm_blockinfo *ptr;
	dm_blockinfo *ptrsft;

	offset = parm->offset;

	/* calc the index of the block unit */
	/* i = offset/DM_BLOCKUNIT_SIZE; */
	i = offset >> DM_BLOCKUNIT_SIZE_SHIFT;
	
	/* valid index value ? */
	if(i < 0 || i > DM_BLOCKUNIT_NUM - 1){
		printk(KERN_ERR "[DM] doDM_FREE invalid i=%x,offset=%x\n",i,(int)offset);
		return -EINVAL;
	}

	/* get the pointer of block information indicated by the index value */
	ptr = dm_blockinfo_tbl + i;

	/*  already freed ? -> abort */
	if (ptr->allocation_flag == 0) {
	  printk(KERN_ERR "[DM] doDM_FREE already freed i=%x,offset=%x\n",i,(int)offset);
	  return -EINVAL;
	}

	/* get size from block information */
	n = ptr->num;

	/* decrese the total number of allocated blocks */
	dm_malloc_count -= n;

	/* if dm_malloc_count = 0, initalize tables and abort */
	if(dm_malloc_count <= 0){
		return doDM_RESET();
	}

	/* clean up information about indicated blocks */
    for(j = 0; j < n; j++){
		ptrsft = dm_blockinfo_tbl + i + j;
		/* ptrsft->offset = (i + j) * DM_BLOCKUNIT_SIZE; */
		/* ptrsft->num  = 0; */
		ptrsft->next = NULL;
		/* ptrsft->page = 0; */
		ptrsft->allocation_flag = 0;
	}

	/* gather the continuous blocks with unprepared depth */
	if(n > DM_FREELIST_NUM){
		m = DM_FREELIST_NUM; /* m=(int)n */
	}else{
		m = n;
	}

	/* connect it if the depth of the list is less than limit */
	if(dm_freelist_count[m-1] < dm_freelist_limit[m-1]){
		ptr->next = dm_freelist[m-1];
		dm_freelist[m-1] = ptr;
		dm_freelist_count[m-1] ++; /* increse the depth counter */
	}else{
	/* when the current depth exceeds the limit,
	   don't connect, and initalize "num".
	   (num=0 when it is  not stored in the list) */
    	for(j = 0; j < n; j++){
			ptrsft = dm_blockinfo_tbl + i + j;
			/* ptrsft->offset = (i + j) * DM_BLOCKUNIT_SIZE; */
			ptrsft->num  = 0;
			/* ptrsft->next = NULL; */
			/* ptrsft->page = 0; */
			/* ptrsft->allocation_flag = 0; */
		}
	}

	return 0;
}

/*****************************************************************************
 << ADDRESS CONVERSION (from User area to Kernel area)>>
 *****************************************************************************/
void *dm_user_to_kernel(void *uaddr)
{
        /* uaddr is offset address in DM */
	int i;
	int nr_page;
	void *kaddr;

	/* calc the index value for block information */
 	/* i = (unsigned long)uaddr/DM_BLOCKUNIT_SIZE; */
 	i = (unsigned long)uaddr >> DM_BLOCKUNIT_SIZE_SHIFT;
	
	/* valid index value ? */
	if(i > DM_BLOCKUNIT_NUM - 1){
		printk(KERN_ERR "[DM] dm_user_to_kernel invalid i=%x,uaddr=%x\n",i,(int)uaddr);
		return NULL;
	}

	/* calc the pointer (of Kernel area) from the block information */
	nr_page = i  >> DM_PAGE_BLOCKUNIT_SHIFT;
	kaddr = (void *)(dm_pages[nr_page]
			         +((unsigned long)uaddr%DM_PAGE_SIZE));

	/* tokada DEBUG */
	/* printk(KERN_INFO "uaddr = %08x, kaddr = %08x\n",(int)uaddr,(int)kaddr); */


	return kaddr;
	
}

/*****************************************************************************
 Convert DM address to Bus address (GetChunkAddress)  by S.Horita
 *****************************************************************************/
int doDM_GET_BUS_ADDR(dm_ioctl_addr *addr)
{
  void *virt_addr;

  virt_addr = dm_user_to_kernel( (void *)(addr->offset) );

  addr->bus_addr = (virt_addr == NULL) ? NULL : (void *)__virt_to_bus((unsigned long)virt_addr);

  return 0;
}


/*****************************************************************************
 Convert DM address to virtual address (GetChunkVirtAddress)
 *****************************************************************************/
int doDM_GET_VIRT_ADDR(dm_ioctl_addr *addr)
{
  addr->bus_addr = dm_user_to_kernel( (void *)(addr->offset) );
  return 0;
}


/*****************************************************************************
 << SHOW /proc/dm >>
******************************************************************************/
int dm_read_proc(struct seq_file *s, void *unused)
{
	int j;
	dm_blockinfo *ptr;


	seq_printf(s, "dm_malloc_count: %d\n", dm_malloc_count);
	seq_printf(s, "dm_current_page: %d\n", dm_current_page);
	seq_printf(s, "dm_allocated: %d\n", dm_allocated);

	for(j = 0; j < DM_PAGE_NUM; j++){
		seq_printf(s, "dm_pages[%d]: logic adr=%08x, phy adr=%08x\n",
		                   j, (int)dm_pages[j],(int)__pa(dm_pages[j]));
	}

	seq_printf(s, "dm_freelist_count: \n");
	for(j = 0; j < DM_FREELIST_NUM; j++){
		seq_printf(s, "[%04d] %04d\n",j+1,dm_freelist_count[j]);
	}


	seq_printf(s, "dm_blockinfo_tbl: \n");
	seq_printf(s, "[blk][offset][num][next][flg]\n");
	for(j = 0; j < DM_BLOCKUNIT_NUM; j++){
		ptr = dm_blockinfo_tbl + j;
		seq_printf(s, "%04d %08x %04d %08x %01d\n",
		           j, (unsigned int)ptr->offset, ptr->num,
		           (unsigned int)ptr->next, ptr->allocation_flag);
	}

	return 0;
}

/*****************************************************************************
 << SHOW /proc/dmparam >>  added 2009/01/21
******************************************************************************/
int dm_param_read_proc(struct seq_file *s, void *unused)
{
	seq_printf(s, "DM driver ver%s\n", DM_VERSION);
	seq_printf(s, "DM_BLOCKUNIT_NUM: %d\n", (int)CONFIG_DM_BLOCKUNIT_NUM);
	seq_printf(s, "DM_MALLOC_MAX_SIZE: 0x%X\n", (int)CONFIG_DM_MALLOC_MAX_SIZE);
	seq_printf(s, "DM_ORDER: %d\n", (int)CONFIG_DM_ORDER);
	seq_printf(s, "DM_FREELIST_NUM: %d\n", (int)CONFIG_DM_FREELIST_NUM);

	return 0;
}

EXPORT_SYMBOL(dm_user_to_kernel);

#ifdef MODULE
module_init(init_dm);
module_exit(cleanup_dm)
#else
core_initcall(init_dm);
#endif

