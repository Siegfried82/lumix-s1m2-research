/*
 * Driver for emulating a block device over IPCU on Socionext platforms
 *
 * Copyright (C) 2016 Linaro, Ltd
 *  Jassi Brar <<REDACTED_EMAIL>>
 */

#include <linux/module.h>
#include <linux/major.h>
#include <linux/io.h>
#include <linux/blkdev.h>
#include <linux/bio.h>
#include <linux/mutex.h>
#include <linux/genhd.h>
#include <linux/dma-mapping.h>
#include <linux/platform_device.h>
#include <linux/of_platform.h>
#include <linux/hdreg.h>

#include <linux/sni_ipcu_parts.h>
#include <linux/ipcu_userland.h>
#include <linux/shared_mem.h>

#define SECTOR_SHIFT	9
#define IPCU_REQ_SIZE	PAGE_SIZE

#define SHM_OFFSET_SIZE 0x8000

static void *shm;
#ifdef CONFIG_PHYS_ADDR_T_64BIT
static u64 shm_start_addr;
#else
static u32 shm_start_addr;
#endif
static struct workqueue_struct *vblk_wq;
static struct work_struct work;
static u32 ipcu_unit, send_mb, recv_mb;
static struct sni_ipcu_device send_dev, recv_dev;

static struct vblk_device g_vblk;
static int major = 0;

enum vblk_action {
	VBLK_GETGEO = 0x3000,
	VBLK_READ, /* Linux gets data from RTOS */
	VBLK_WRITE, /* Linux sends data to RTOS */
};

struct vblk_geometry {
	u32 sectors; /* Number of 512bytes sectors */
	u32 err;
} __packed;

struct vblk_data_xfer {
	u32 start;  /* starting sector number */
	u32 length; /* number of sectors */
	dma_addr_t addr;   /* physical address of buffer */
	u32 err;
} __packed;

/* Kept similar to 'struct ipcufs_info_table' */
struct vblk_info_table {
	union {
		enum vblk_action action;
		u32 __action;
	} u;

	u32 buffer_num;
	u32 plane_num;
	u32 __reserved[5];

	union {
		struct vblk_geometry geo;
		struct vblk_data_xfer xfer;
		u32 __reserved[24];	/* pad it to 32word */
	} c;
};

struct vblk_device {
	struct vblk_info_table vit;
	struct request_queue *queue;
	struct gendisk *gd;
	struct mutex mlock;
	struct device *dev;
};

static void vblk_work_handler(struct work_struct *work)
{
	int ret = 0;
	int recv_buf[9];

	ret = sni_ipcu_recv_msg_kernel(ipcu_unit, recv_mb, &recv_buf,
					sizeof(T_IPCU_IF), FLAG_RECV_WAIT);
	if (ret < 0)
		pr_err("%s:%d [ERROR] sni_ipcu_recv_msg_kernel(): %d\n",
		       __func__, __LINE__, ret);
}

static int vblk_transfer(void *p, int len)
{
	T_IPCU_IF mssg;
	int ret;

	memcpy_toio(shm, p, len);

	if (ipcu_unit == 0)
		mssg.id = send_mb;
	else
		mssg.id = send_mb + 8;

	mssg.bufl = (u32)shm_start_addr;
#ifdef CONFIG_PHYS_ADDR_T_64BIT
	mssg.bufh = (u32)(shm_start_addr >> 32);
#endif
	mssg.len = len;
	mssg.cont = 0;

	wmb();

	queue_work(vblk_wq, &work);

	ret = sni_ipcu_send_msg_kernel(ipcu_unit, send_mb,
				       &mssg, sizeof(mssg), FLAG_SEND_NOTIFY);

	flush_workqueue(vblk_wq);

	if (ret < 0) {
		pr_err("%s:%d [ERROR] sni_ipcu_send_msg_kernel(): %d\n",
		       __func__, __LINE__, ret);
		return ret;
	}

	memcpy_fromio(p, shm, len);
	rmb();

	ret = sni_ipcu_ack_send(ipcu_unit, recv_mb);
	if (ret < 0)
		pr_err("%s:%d [ERROR] sni_ipcu_send_msg(): %d\n",
			__func__, __LINE__, ret);

	return ret;
}

static int vblk_do_bvec(struct vblk_device *vblk, void *buf,
			unsigned len, int write, sector_t start)
{
	struct vblk_info_table *it = &vblk->vit;
	int ret;

	mutex_lock(&vblk->mlock);

	it->u.action = write ? VBLK_WRITE : VBLK_READ;
	it->c.xfer.start = start;
	it->c.xfer.length = len;
	it->c.xfer.addr = dma_map_single(vblk->dev, buf, len << SECTOR_SHIFT,
				write ? DMA_TO_DEVICE : DMA_FROM_DEVICE);
	if (dma_mapping_error(vblk->dev, it->c.xfer.addr))
		pr_err("Failed to map DMA buffer\n");

	ret = vblk_transfer((void *)it, sizeof(*it));

	dma_unmap_single(NULL, it->c.xfer.addr, len << SECTOR_SHIFT,
				write ? DMA_TO_DEVICE : DMA_FROM_DEVICE);

	if (ret || it->c.xfer.err)
		ret = -EIO;

	mutex_unlock(&vblk->mlock);

	return ret;
}

static int vbl_get_size(struct vblk_device *vblk)
{
	struct vblk_info_table *it = &vblk->vit;
	int ret;

	mutex_lock(&vblk->mlock);

	it->u.action = VBLK_GETGEO;
	it->c.geo.sectors = 0;

	ret = vblk_transfer((void *)it, sizeof(*it));
	if (ret || it->c.geo.err)
		ret = 0;
	else
		ret = it->c.geo.sectors;

	mutex_unlock(&vblk->mlock);

	return ret;
}

static blk_qc_t vblk_make_request(struct request_queue *q, struct bio *bio)
{
	struct vblk_device *vblk = bio->bi_disk->private_data;
	struct bio_vec bvec;
	sector_t sector;
	struct bvec_iter iter;

	if (bio_end_sector(bio) > get_capacity(bio->bi_disk)) {
		pr_err("%s:%d Access beyond end!\n", __func__, __LINE__);
		goto io_error;
	}

	sector = bio->bi_iter.bi_sector;
	bio_for_each_segment(bvec, bio, iter) {
		void *buf = kmap(bvec.bv_page) + bvec.bv_offset;
		unsigned len = bvec.bv_len >> SECTOR_SHIFT;
		int err;

		err = vblk_do_bvec(vblk, buf, len,
				bio_data_dir(bio) == WRITE, sector);

		kunmap(bvec.bv_page);

		if (err)
			goto io_error;
		sector += len;
	}

	bio_endio(bio);
	return BLK_QC_T_NONE;

io_error:
	bio_io_error(bio);
	return BLK_QC_T_NONE;
}

static int vblk_geo(struct block_device *bdev, struct hd_geometry *geo)
{
	geo->heads = 1;
	geo->cylinders = 1;
	geo->sectors = get_capacity(bdev->bd_disk);
	return 0;
}

static const struct block_device_operations vblk_fops = {
	.owner = THIS_MODULE,
	.getgeo = vblk_geo,
};

static int vblk_ipcu_init(void)
{
	int rc;

	rc = sni_ipcu_mb_init(ipcu_unit,
			      send_mb, SNI_IPCU_DIR_SEND, (void *)&send_dev);
	if (rc < 0) {
		pr_info("%s:%d Cannot init send ipcu channel. -retry probe-\n",
			__func__, __LINE__);
		goto err4;
	}

	rc = sni_ipcu_openmb(ipcu_unit, send_mb, SNI_IPCU_DIR_SEND);
	if (rc < 0) {
		pr_err("%s:%d sni_ipcu_openmb(): %d -retry probe-\n",
			__func__, __LINE__, rc);
		goto err3;
	}

	rc = sni_ipcu_mb_init(ipcu_unit,
			      recv_mb, SNI_IPCU_DIR_RECV, (void *)&recv_dev);
	if (rc < 0) {
		pr_info("%s:%d Cannot init recv ipcu channel. -retry probe-\n",
			__func__, __LINE__);
		goto err2;
	}

	rc = sni_ipcu_openmb(ipcu_unit, recv_mb, SNI_IPCU_DIR_RECV);
	if (rc < 0) {
		pr_err("%s:%d sni_ipcu_openmb(): %d -retry probe-\n",
			__func__, __LINE__, rc);
		goto err1;
	}
	return 0;

 err1:
	sni_ipcu_mb_exit(ipcu_unit, recv_mb, (void *)&recv_dev);
 err2:
	sni_ipcu_closemb(ipcu_unit, send_mb, SNI_IPCU_DIR_SEND);
 err3:
	sni_ipcu_mb_exit(ipcu_unit, send_mb, (void *)&send_dev);

 err4:
	return -EPROBE_DEFER;
}

static int vblk_ipcu_uninit(void)
{
	int rc;

	rc = sni_ipcu_closemb(ipcu_unit, send_mb, SNI_IPCU_DIR_SEND);
	if (rc < 0) {
		pr_err("%s:%d [ERROR] sni_ipcu_closemb(): %d\n", __func__,
		       __LINE__, rc);
	}

	sni_ipcu_mb_exit(ipcu_unit, send_mb, (void *)&send_dev);

	rc = sni_ipcu_closemb(ipcu_unit, recv_mb, SNI_IPCU_DIR_RECV);
	if (rc < 0) {
		pr_err("%s:%d [ERROR] sni_ipcu_closemb(): %d\n", __func__,
		       __LINE__, rc);
	}

	sni_ipcu_mb_exit(ipcu_unit, recv_mb, (void *)&recv_dev);

	return 0;
}

static int sn_vblk_probe(struct platform_device *pdev)
{
	struct vblk_device *vblk = &g_vblk;
	struct device *dev = &pdev->dev;
	struct gendisk *disk;
	void __iomem *common_mem;
	int offset_size;
	int ret;

	if (major > 0)
		return -EBUSY;

	if (of_property_read_u32(dev->of_node, "ipcu_unit", &ipcu_unit)) {
		dev_err(dev, "%s:%d IPCU Unit Number is not provided\n",
			__func__, __LINE__);
		return -EINVAL;
	}

	if (of_property_read_u32_index(dev->of_node, "ipcu_mb", 0, &send_mb)) {
		dev_err(dev, "%s:%d IPCU Send Channel is not provided\n",
			__func__, __LINE__);
		return -EINVAL;
	}

	if (of_property_read_u32_index(dev->of_node, "ipcu_mb", 1, &recv_mb)) {
		dev_err(dev, "%s:%d IPCU Receive Channel is not provided\n",
			__func__, __LINE__);
		return -EINVAL;
	}

	send_dev.dest_unit = ipcu_unit;
	send_dev.dest_mb = send_mb;

	recv_dev.dest_unit = ipcu_unit;
	recv_dev.dest_mb = recv_mb;

	common_mem = shared_mem_get_mem(E_SHARED_MEM_BUFFER);
	if (!common_mem) {
		dev_err(dev, "get shared_mem failed.\n");
		goto err;
	}

	if (ipcu_unit == 0)
		offset_size = SHM_OFFSET_SIZE * recv_mb;
	else
		offset_size = SHM_OFFSET_SIZE * (recv_mb + 8);
#ifdef CONFIG_PHYS_ADDR_T_64BIT
	shm_start_addr = ioread64(common_mem) + offset_size;
#else
	shm_start_addr = ioread32(common_mem) + offset_size;
#endif

	shm = devm_ioremap(&pdev->dev, shm_start_addr, 0x1000);
	if (!shm) {
		devm_iounmap(&pdev->dev, common_mem);
		dev_err(dev, "%s:%d buff_mem ioremap failed\n", __func__, __LINE__);
		ret = -ENOMEM;
		goto err;
	}

	vblk->dev = &pdev->dev;
	mutex_init(&vblk->mlock);
	INIT_WORK(&work, vblk_work_handler);

	vblk_wq = create_singlethread_workqueue("vblk_recv");
	if (!vblk_wq) {
		ret = -EINVAL;
		goto err1;
	}

	ret = vblk_ipcu_init();
	if (ret)
		goto err2;

	major = register_blkdev(0, "ipcublk");
	if (major < 0) {
		ret = major;
		goto err3;
	}

	vblk->queue = blk_alloc_queue(GFP_KERNEL);
	if (!vblk->queue) {
		ret = -ENOMEM;
		goto err4;
	}

	blk_queue_make_request(vblk->queue, vblk_make_request);
	blk_queue_logical_block_size(vblk->queue, IPCU_REQ_SIZE);

	disk = vblk->gd = alloc_disk(1);
	if (!disk) {
		ret = -ENOMEM;
		goto err5;
	}

	disk->major = major;
	disk->first_minor = 0;
	disk->fops = &vblk_fops;
	disk->private_data = vblk;
	disk->queue = vblk->queue;
	disk->flags = GENHD_FL_EXT_DEVT;
	sprintf(disk->disk_name, "ipcublk");
	set_capacity(disk, vbl_get_size(vblk));
	add_disk(disk);

	return 0;

err5:
	blk_cleanup_queue(vblk->queue);
err4:
	unregister_blkdev(major, "ipcublk");
err3:
	vblk_ipcu_uninit();
err2:
	destroy_workqueue(vblk_wq);
err1:
	devm_iounmap(&pdev->dev, shm);
	shm = NULL;
err:
	major = 0;
	return ret;
}

static int sn_vblk_remove(struct platform_device *pdev)
{
	struct vblk_device *vblk = &g_vblk;

	del_gendisk(vblk->gd);
	put_disk(vblk->gd);
	blk_cleanup_queue(vblk->queue);
	unregister_blkdev(major, "ipcublk");
	vblk_ipcu_uninit();
	destroy_workqueue(vblk_wq);
	devm_iounmap(&pdev->dev, shm);
	shm = NULL;
	major = 0;
	return 0;
}

static const struct of_device_id sn_vblk_rtos_id[] = {
	{.compatible = "socionext,vblk-rtos"},
	{},
};

MODULE_DEVICE_TABLE(of, sn_vblk_rtos_id);

static struct platform_driver sn_vblk_rtos_driver = {
	.probe = sn_vblk_probe,
	.remove = sn_vblk_remove,
	.driver = {
		   .name = "vblk-rtos",
		   .of_match_table = sn_vblk_rtos_id,
		   },
};

module_platform_driver(sn_vblk_rtos_driver);

MODULE_LICENSE("GPL");
MODULE_ALIAS("snivblk");
