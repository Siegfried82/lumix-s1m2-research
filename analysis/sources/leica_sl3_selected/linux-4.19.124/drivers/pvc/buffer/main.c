/* -*- C -*-
 * main.c -- the bare scullp char module
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

#include <linux/kernel.h>
#include <linux/fs.h>
#include <linux/errno.h>
#include <linux/types.h>
#include <linux/module.h>
#include <linux/mm.h>
#include <linux/cdev.h>
#include <asm/io.h>
#include <linux/uaccess.h>
#include <linux/scullp.h>


#if defined(CONFIG_MODVERSIONS) && !defined(MODVERSIONS)
# include <config/modversions.h>
# define MODVERSIONS
#endif

#include <asm/string.h>
#include <linux/dma-mapping.h>

#ifdef CONFIG_DM_SUPPORT_P2
extern int get_dm_sd_pages(int slot, unsigned long *virt_addr, unsigned long *phys_addr);
#endif	// CONFIG_DM_SUPPORT_P2

/* Global & Internal definitions.   */
static struct cdev scullp_drv;
int scullp_major =   SCULLP_MAJOR;
static int scullp_open_count = 0;	/* reference counter    */
ScullP_Dev scullp_dev;				/* allocated in scullp_init */
struct semaphore sem;

MODULE_AUTHOR("GPL");
MODULE_LICENSE("GPL");

#if defined(CONFIG_BUFFER_DM) /* XXX */
MODULE_PARM_DESC(scullp_major, "i");
static int buf_size = 0;
module_param(buf_size, int, S_IRUGO);
MODULE_PARM_DESC(buf_size, "i"); 
static int buf0_bus_addr = 0;
module_param(buf0_bus_addr, int, S_IRUGO);
MODULE_PARM_DESC(buf0_bus_addr, "i");
static int buf1_bus_addr = 0;
module_param(buf1_bus_addr, int, S_IRUGO);
MODULE_PARM_DESC(buf1_bus_addr, "i");
static int buf2_bus_addr = 0;
module_param(buf2_bus_addr, int, S_IRUGO);
MODULE_PARM_DESC(buf2_bus_addr, "i");
static int buf3_bus_addr = 0;
MODULE_PARM_DESC(buf3_bus_addr, "i");
module_param(buf3_bus_addr, int, S_IRUGO);
#endif /* CONFIG_BUFFER_DM */ /* XXX */


/* Open and close	*/
int scullp_open(struct inode *inode, struct file *filp)
{
    int num = MINOR(inode->i_rdev);
    ScullP_Dev *dev = &scullp_dev; /* device information */

    /*  check the device number */
    if(num > 0){
        printk("scullp : scullp_open : check device number error\n");
        return -ENODEV;
    }

    /* and use filp->private_data to point to the device data */
    filp->private_data = dev;

	down(&sem);
	scullp_open_count++;
	up(&sem);
    return 0;          /* success */
}

int scullp_release(struct inode *inode, struct file *filp)
{
	down(&sem);
	scullp_open_count--;
	up(&sem);
    return 0;
}

/* Read and write	*/
ssize_t scullp_read(struct file *filp, char *buf, size_t count,
                loff_t *f_pos)
{
    ScullP_Dev *dev = filp->private_data; /* the first listitem */
	int chunk_num = ERR_BUF_COUNT;
    int buf_off = 0;
	int loopCount;

	down(&sem);

	for(loopCount = 0; loopCount < dev->buf_num; loopCount++){
		if((int)*f_pos < (dev->buf_size * (loopCount + 1))){
			chunk_num = loopCount;
			buf_off = (int)*f_pos - (dev->buf_size * loopCount);
                                                                                                            
			if(buf_off + count > dev->buf_size)
				count = dev->buf_size - buf_off;
			break;
		}
	}

	if(chunk_num == ERR_BUF_COUNT){
		printk("scullp : scullp_write : Reqested area is out of range : buf_num = %d, requested buf_num = %d\n", chunk_num, dev->buf_num);
		up(&sem);
		return -EINVAL;
	}

    if(copy_to_user (buf, dev->dmabuf[chunk_num] + buf_off, count)){
        printk("scullp : scullp_read : copy_to_user failed (Read)\n");
		up(&sem);
        return -EFAULT;
    }
    up(&sem);

    *f_pos += count;
    return count;
}

ssize_t scullp_write(struct file *filp, const char *buf, size_t count,
                loff_t *f_pos)
{
    ScullP_Dev *dev = filp->private_data; /* the first listitem */
	int chunk_num = ERR_BUF_COUNT;
    int buf_off = 0;
	int loopCount;

    down(&sem);

	for(loopCount = 0; loopCount < dev->buf_num; loopCount++){
		if((int)*f_pos < (dev->buf_size * (loopCount + 1))){
			chunk_num = loopCount;
			buf_off = (int)*f_pos - (dev->buf_size * loopCount);
                                                                                                           
			if(buf_off + count > dev->buf_size)
				count = dev->buf_size - buf_off;
			break;
		}
	}

	if(chunk_num == ERR_BUF_COUNT){
		printk("scullp : scullp_write : Reqested area is out of range : buf_num = %d, requested buf_num = %d\n", chunk_num, dev->buf_num);
		up(&sem);
		return -EINVAL;
	}

    if(copy_from_user (dev->dmabuf[chunk_num] + buf_off, buf, count)){
        printk("scullp : copy_from_user failed (Write)\n");
		up(&sem);
        return -EFAULT;
    }
    up(&sem);

    *f_pos += count;
    return count;
}

/* ioctl() implementation	*/
//int scullp_ioctl(struct inode *inode, struct file *filp,
//                 unsigned int cmd, unsigned long arg)
long scullp_ioctl(struct file *filp, unsigned int cmd, unsigned long arg)
{
    ScullP_Dev *dev = filp->private_data; /* the first listitem */
	void *vaddr;
    int ret = 0;
#if ! defined(CONFIG_BUFFER_DM) /* XXX */
	int lpc;
#endif /* ! CONFIG_BUFFER_DM */ /* XXX */
    ScullP_IOC_GETBUFLIST bl;


    switch(cmd){
    case IOC_SCULLP_GETBUFLIST:
        if(!access_ok(VERIFY_READ, (void *)arg, 4)){
            printk("cullp : scullp_ioctl : VERIFY_READ error\n");
            return -EFAULT;
        }
        if(copy_from_user (&bl, (void *)arg, 4)){
            printk("scullp : scullp_ioctl : copy_from_user error\n");
            return -EFAULT;
        }

#if defined(CONFIG_BUFFER_DM) /* XXX */
	bl.buf_list[0].buf_kaddr = dev->dmabuf[0];
	bl.buf_list[0].buf_size_chunk = dev->buf_size_chunk;
	bl.buf_list[0].buf_offset = 0;

        bl.buf_list[1].buf_kaddr = dev->dmabuf[1];
        bl.buf_list[1].buf_size_chunk = dev->buf_size_chunk;
        bl.buf_list[1].buf_offset = 0;

	bl.buf_list[2].buf_kaddr = dev->dmabuf[2];
	bl.buf_list[2].buf_size_chunk = dev->buf_size_chunk;
	bl.buf_list[2].buf_offset = 0;
#else /* ! CONFIG_BUFFER_DM */
	for( lpc = 0; lpc < DMABUF_NUM; lpc++ ){
	  bl.buf_list[lpc].buf_kaddr = dev->dmabuf[lpc];
	  bl.buf_list[lpc].buf_size = dev->buf_size;
	  bl.buf_list[lpc].buf_offset = 0;
	}
#endif /* CONFIG_BUFFER_DM */

	bl.valid_buf_num = DMABUF_NUM;

        if(!access_ok(VERIFY_WRITE, (void *)arg, sizeof(bl))){
            printk("scullp : scullp_ioctl : VERIFY_WRITE %ld error\n", sizeof(bl));
            return -EFAULT;
        }

        if(copy_to_user ((void *)arg, &bl, sizeof(bl))){
            printk("scullp : scullp_ioctl : copy_to_user %ld error\n", sizeof(bl));
            return -EFAULT;
        }
        return 0;
    
    case IOC_SCULLP_GETPHYADDR:
    if(!access_ok(VERIFY_WRITE, (void *)arg, 4)){
        printk("cullp : scullp_ioctl : VERIFY_WRITE error\n");
        return -EFAULT;
    }
    if(copy_from_user (&bl, (void *)arg, sizeof(bl))){
        printk("scullp : scullp_ioctl : copy_from_user error\n");
        return -EFAULT;
    }
    bl.buf_list[0].buf_phyaddr = (void *)virt_to_phys(bl.buf_list[0].buf_kaddr);
        if(copy_to_user ((void *)arg, &bl, sizeof(bl))){
            printk("scullp : scullp_ioctl : copy_to_user %ld error\n", sizeof(bl));
            return -EFAULT;
        }
    	return 0;

    case IOC_SCULLP_BUFCPYPTOV:
    if(!access_ok(VERIFY_WRITE, (void *)arg, 4)){
        printk("cullp : scullp_ioctl : VERIFY_WRITE error\n");
        return -EFAULT;
    }
    if(copy_from_user (&bl, (void *)arg, sizeof(bl))){
        printk("scullp : scullp_ioctl : copy_from_user error\n");
        return -EFAULT;
    }
	vaddr = ioremap((unsigned long)bl.buf_list[0].buf_phyaddr,bl.buf_list[0].buf_offset);
   	memcpy(bl.buf_list[0].buf_kaddr,vaddr,bl.buf_list[0].buf_offset);
    return 0;
    	
    case IOC_SCULLP_BUFCPYVTOP:
    if(!access_ok(VERIFY_WRITE, (void *)arg, 4)){
        printk("cullp : scullp_ioctl : VERIFY_WRITE error\n");
        return -EFAULT;
    }
    if(copy_from_user (&bl, (void *)arg, sizeof(bl))){
        printk("scullp : scullp_ioctl : copy_from_user error\n");
        return -EFAULT;
    }
	vaddr = ioremap((unsigned long)bl.buf_list[0].buf_phyaddr,bl.buf_list[0].buf_offset);
	memcpy(vaddr,bl.buf_list[0].buf_kaddr,bl.buf_list[0].buf_offset);
    return 0;

    default:
        printk("invalid ioctl code(%d)", cmd);
        return -ENOTTY;
    }
    return ret;
}

/* "extended" operations	*/
loff_t scullp_llseek(struct file *filp, loff_t off, int whence)
{
    ScullP_Dev *dev = filp->private_data;
    long newpos;

    switch(whence){
    case 0: /* SEEK_SET */
        newpos = off;
        break;

    case 1: /* SEEK_CUR */
        newpos = filp->f_pos + off;
        break;

    case 2: /* SEEK_END */
        newpos = dev->buf_size * dev->buf_num + off;
        break;

    default: /* can't happen */
        printk("scullp : scullp_llseek : Invalid seek code (%d)", whence);
        return -EINVAL;
    }
    if(newpos < 0){
        printk("scullp : scullp_llseek : Seek point lower (%ld)\n", newpos);
        return -EINVAL;
    }
    if(newpos > dev->buf_size * dev->buf_num){
        printk("scullp : scullp_llseek : Seek point higher (%ld)\n", newpos);
        return -EINVAL;
    }
    filp->f_pos = newpos;
    return newpos;
}
 
struct file_operations scullp_fops = {
    llseek:	scullp_llseek,
    read:	scullp_read,
    write:	scullp_write,
    unlocked_ioctl:	scullp_ioctl,
    open:	scullp_open,
    release: scullp_release,
};

int scullp_init(void)
{
    int result = 0;
	int dev_num;

#if ! defined(CONFIG_BUFFER_DM) /* XXX */
	int	lpc;
#endif /* ! CONFIG_BUFFER_DM */ /* XXX */

	/* initializing semaphoe */
	sema_init(&sem, 1);

	if (scullp_major) {
		dev_num = MKDEV( scullp_major, 0 );

		/* Register your major, and accept a dynamic number */
		result = register_chrdev_region( dev_num, 1, "scullp" );
		if( result ){
			printk("scullp : scullp_init : register_chrdev_region() error\n");
			return result;
		}
	}
	else {
		result = alloc_chrdev_region(&dev_num, 0, 1, "scullp");
		if(unlikely(result < 0)){
			printk("alloc_chrdev_region() failed(%d)", result);
			return result;
		}
		scullp_major = MAJOR(dev_num);
	}

	cdev_init( &scullp_drv, &scullp_fops );
	scullp_drv.owner = THIS_MODULE;

	result = cdev_add( &scullp_drv, dev_num, 1 );
	if( result < 0 ){
		printk("scullp : scullp_init : cdev_add() error\n");
		unregister_chrdev_region( dev_num, 1 );
		return result;
	}

#if defined(CONFIG_BUFFER_DM) /* XXX */
	if( buf_size != DMABUF_SIZE_CHUNK ){
		printk("scullp : scullp_init : buffer size error %d\n", buf_size);
		unregister_chrdev_region( dev_num, 1 );
		return -EINVAL;
	}

	/* Read & Write & Seek file operarion are available only first
	   512KB area of scullp_dev.dmabuf[0].
	   Following valid address, we have to inform them to "ua" by
	   the ioctl command											*/
	scullp_dev.buf_num = DMABUF_NUM;
	scullp_dev.buf_size_chunk = DMABUF_SIZE_CHUNK;
	scullp_dev.buf_size = DMABUF_SIZE_CHUNK;
	
	scullp_dev.dmabuf[0] = phys_to_virt((unsigned long)buf0_bus_addr);
    scullp_dev.dmabuf[1] = phys_to_virt((unsigned long)buf1_bus_addr);
	scullp_dev.dmabuf[2] = phys_to_virt((unsigned long)buf2_bus_addr);

	/* buf3_bus_addr are reserved parameters	*/
	printk("scullp : scullp_init : allocated 3 buffers at (%p) & (%p) & (%p)\n",
			phys_to_virt((unsigned long)buf0_bus_addr), phys_to_virt((unsigned long)buf1_bus_addr), phys_to_virt((unsigned long)buf2_bus_addr));

    return 0;

#else /* ! CONFIG_BUFFER_DM */ /* XXX */

	scullp_dev.buf_num = DMABUF_NUM;
	scullp_dev.buf_size = DMABUF_SIZE_CHUNK;

	/* allocate kernel memories 	*/
	for(lpc = 0; lpc < DMABUF_NUM; lpc++){
		scullp_dev.dmabuf[lpc] = (void *)__get_free_pages(GFP_KERNEL, DMABUF_SIZE_ORDER);
		if (!scullp_dev.dmabuf[lpc]) {
			result = -ENOMEM;
			goto fail_malloc;
		}
	}
	printk("scullp : scullp_init : allocated %d buffers\n", DMABUF_NUM);
	for(lpc = 0; lpc < DMABUF_NUM; lpc++){
		printk("scullp : scullp_init : at (%08lX)\n", (unsigned long)(scullp_dev.dmabuf[lpc]));
	}

	printk("scullp : scullp_init : success\n");
    return 0;

fail_malloc:
	for(lpc = 0; lpc < DMABUF_NUM; lpc++){
		if(scullp_dev.dmabuf[lpc]){
			free_pages((unsigned long)scullp_dev.dmabuf[lpc], DMABUF_SIZE_ORDER);
		}
		scullp_dev.dmabuf[lpc] = NULL;
	}
	scullp_dev.buf_num = 0;
	scullp_dev.buf_size = 0;
	
	cdev_del( &scullp_drv );
	unregister_chrdev_region( dev_num, 1 );
	printk("[E: SCULLP] Fatal error was occurred during initialization\n");

	return -1;
#endif /* CONFIG_BUFFER_DM */ /* XXX */
}

void scullp_cleanup(void)
{
	int dev_num = MKDEV( scullp_major, 0 );
#if ! defined(CONFIG_BUFFER_DM) /* XXX */
	int lpc;
#endif /* ! CONFIG_BUFFER_DM */ /* XXX */
	cdev_del( &scullp_drv );
	unregister_chrdev_region( dev_num, 1 );

#if defined(CONFIG_BUFFER_DM) /* XXX */
	scullp_dev.buf_size = 0;
	scullp_dev.dmabuf[0] = scullp_dev.dmabuf[1] = 0;
#else /* ! CONFIG_BUFFER_DM */ /* XXX */
	for( lpc = 0; lpc < DMABUF_NUM; lpc++ ){
		if(scullp_dev.dmabuf[lpc]){
			free_pages((unsigned long)scullp_dev.dmabuf[lpc], DMABUF_SIZE_ORDER);
		}
		scullp_dev.dmabuf[lpc] = NULL;
	}
#endif /* CONFIG_BUFFER_DM */ /* XXX */
}

module_init(scullp_init);
module_exit(scullp_cleanup);
