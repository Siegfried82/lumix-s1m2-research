/**
 * Copyright (C) 2019 Socionext Inc.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 2 of the License.
 *
 * @file   sni_dsp_drv.c
 * @author
 * @date
 * @brief  SNI XM6/CNN device driver
 */

#include "sni_dsp_drv_karine.h"
#include "sni_dsp_reg_karine.h"

void __iomem *g_io_dsp_mem;

static void dma_callback(void *dma_flag)
{
	printk("... copy to TCM finished\n");
	*((int*)dma_flag) = 1;
}

/* ioctl */
static long sni_dsp_drv_ioctl(struct file *filp,
			       unsigned int cmd,
			       unsigned long arg)
{
	int err = 0;
	//int rc = 0;
	//int is_xm6;
	struct io_sni_dsp *io_dsp_mem;
	struct io_sni_dsp io_dsp;
	T_DSP_PARAM t_param;

	struct miscdevice *mdev = filp->private_data;
	struct sni_dsp_device *sni_dsp_dev =
			container_of(mdev, struct sni_dsp_device, miscdev);

	if (_IOC_TYPE(cmd) != XM6_IOCTL_MAGIC){
			return -ENOTTY;
	}

	if (_IOC_DIR(cmd) & _IOC_READ) {
		err = !access_ok(VERIFY_WRITE,
				(void __user *)arg, _IOC_SIZE(cmd));
	} else if (_IOC_DIR(cmd) & _IOC_WRITE) {
		err = !access_ok(VERIFY_READ,
				(void __user *)arg, _IOC_SIZE(cmd));
	}

	if (err)
		return -EFAULT;

	if (_IOC_NR(cmd) > XM6_IOCTL_MAXNR){
		return -ENOTTY;
	}

	io_dsp_mem = (struct io_sni_dsp *)g_io_dsp_mem;

	if (copy_from_user(&t_param,  (void *)arg, sizeof(t_param))) {
		pr_err("%s:%d copy_from_user failed\n", __func__, __LINE__);
		return -EFAULT;
	}


	switch (cmd) {
	case XM6_IOCTL_AUTOCTL_SRAM:

		io_dsp.DSPCTRL0.word = readl( &(io_dsp_mem->DSPCTRL0.word) );
		io_dsp.DSPCTRL0.bit.ACSL = t_param.val;
		writel( io_dsp.DSPCTRL0.word, &(io_dsp_mem->DSPCTRL0.word) );
		break;


	case XM6_IOCTL_SLP_SRAM:

		io_dsp.DSPCTRL0.word = readl( &(io_dsp_mem->DSPCTRL0.word) );
		io_dsp.DSPCTRL0.bit.SLP = t_param.val;
		writel( io_dsp.DSPCTRL0.word, &(io_dsp_mem->DSPCTRL0.word) );
		break;

	case XM6_IOCTL_SD_SRAM:

		io_dsp.DSPCTRL0.word = readl( &(io_dsp_mem->DSPCTRL0.word) );
		io_dsp.DSPCTRL0.bit.SD = t_param.val;
		writel( io_dsp.DSPCTRL0.word, &(io_dsp_mem->DSPCTRL0.word) );
		break;

	case XM6_IOCTL_DIV_CTL:

		io_dsp.DSPCTRL1.word = readl( &(io_dsp_mem->DSPCTRL1.word) );
		io_dsp.DSPCTRL1.bit.DIV = t_param.val;
		writel(io_dsp.DSPCTRL1.word, &(io_dsp_mem->DSPCTRL1.word) );
		break;

	case XM6_IOCTL_RESET_CORE:

		io_dsp.DSPCTRLSR1.word = readl( &(io_dsp_mem->DSPCTRLSR1.word) );
		io_dsp.DSPCTRLSR1.bit.CORESR = t_param.val;
		writel(io_dsp.DSPCTRLSR1.word, &(io_dsp_mem->DSPCTRLSR1.word) );
		break;

	case XM6_IOCTL_GET_CORERST:

		io_dsp.DSPCTRLSR1.word = readl( &(io_dsp_mem->DSPCTRLSR1.word) );
		t_param.val = io_dsp.DSPCTRLSR1.bit.CORESR;
		if (copy_to_user((void *)arg, &t_param, sizeof(t_param))) {
			pr_err("%s:%d copy_to_user failed\n", __func__, __LINE__);
			return -EFAULT;
		}
		break;

	case XM6_IOCTL_RESET_PERI:

		io_dsp.DSPCTRLSR0.word = readl( &(io_dsp_mem->DSPCTRLSR0.word) );
		io_dsp.DSPCTRLSR0.bit.SR = t_param.val;
		writel(io_dsp.DSPCTRLSR0.word, &(io_dsp_mem->DSPCTRLSR0.word) );
		break;

	case XM6_IOCTL_CTL_MCI:

		io_dsp.DSPCTRLSR1.word = readl( &(io_dsp_mem->DSPCTRLSR1.word) );
		io_dsp.DSPCTRL2.word = readl( &(io_dsp_mem->DSPCTRL2.word) );

			if(io_dsp.DSPCTRLSR1.bit.CORESR == DSP_SET_ON){
				io_dsp.DSPCTRL2.bit.MCI = t_param.val;
			}
			else{
				pr_err("%s:%d DSP core need to be reset state\n", __func__, __LINE__);
				return -EFAULT;
			}

		writel(io_dsp.DSPCTRL2.word, &(io_dsp_mem->DSPCTRL2.word) );

		break;

	case XM6_IOCTL_CTL_EXTWAIT:

		io_dsp.DSPCTRL3.word = readl( &(io_dsp_mem->DSPCTRL3.word) );
		io_dsp.DSPCTRL3.bit.EXTW = t_param.val;
		writel(io_dsp.DSPCTRL3.word, &(io_dsp_mem->DSPCTRL3.word) );
		break;

	case  XM6_IOCTL_REQ_NMI:

		io_dsp.INTCTRL0.word = readl( &(io_dsp_mem->INTCTRL0.word) );

		if(io_dsp.INTCTRL0.bit.NMI == 0){
			io_dsp.INTCTRL0.bit.NMI = 1;
		}
		else{
			pr_err("%s:%d NMI is already assert \n", __func__, __LINE__);
			return -EFAULT;
		}

		writel(io_dsp.INTCTRL0.word, &(io_dsp_mem->INTCTRL0.word) );

		break;

	case  XM6_IOCTL_REQ_VINT:

		io_dsp.INTCTRL0.word = readl( &(io_dsp_mem->INTCTRL0.word) );

		if(io_dsp.INTCTRL0.bit.VINT == 0){
			io_dsp.INTCTRL0.bit.VINT = 1;
		}
		else{
			pr_err("%s:%d VINT is already assert \n", __func__, __LINE__);
			return -EFAULT;
		}

		writel(io_dsp.INTCTRL0.word, &(io_dsp_mem->INTCTRL0.word) );

		break;

	case XM6_IOCTL_GET_INTSTAT:
	{
		T_XM6_INTCTRL intctrl;
		if (copy_from_user(&intctrl,  (void *)arg, sizeof(intctrl))) {
			pr_err("%s:%d copy_from_user failed\n", __func__, __LINE__);
			return -EFAULT;
		}

		io_dsp.INTCTRL0.word = readl( &(io_dsp_mem->INTCTRL0.word) );

		intctrl.NMI = io_dsp.INTCTRL0.bit.NMI;
		intctrl.VINT = io_dsp.INTCTRL0.bit.VINT;
		
		if (copy_to_user((void *)arg, &intctrl, sizeof(intctrl))) {
			pr_err("%s:%d copy_to_user failed\n", __func__, __LINE__);
			return -EFAULT;
		}

		break;
	}

	case  XM6_IOCTL_VINT_ADDR:

		io_dsp.VINT_ADDR.word = readl( &(io_dsp_mem->VINT_ADDR.word) );
		io_dsp.VINT_ADDR.word = t_param.val;
		writel(io_dsp.VINT_ADDR.word, &(io_dsp_mem->VINT_ADDR.word) );
		break;

	case XM6_IOCTL_SW_LPMODE:

		io_dsp.PSUCTRL0.word = readl( &(io_dsp_mem->PSUCTRL0.word) );
		io_dsp.PSUCTRL0.bit.LPREQ = t_param.val;
		writel(io_dsp.PSUCTRL0.word, &(io_dsp_mem->PSUCTRL0.word) );

		break;

	case XM6_IOCTL_CTL_RECOV:

		io_dsp.PSUCTRL0.word = readl( &(io_dsp_mem->PSUCTRL0.word) );
		io_dsp.PSUMON0.word = readl( &(io_dsp_mem->PSUMON0.word) );

		if(t_param.val == DSP_SET_ON){
			if(io_dsp.PSUMON0.bit.CORIDLE == XM6_STATE_IDLE){
				io_dsp.PSUCTRL0.bit.RECOV = 1;
			}
			else{
				pr_err("%s:%d recovery error (state is already not idle)\n", __func__, __LINE__);
				return -EFAULT;
			}
		}
		else{
			io_dsp.PSUCTRL0.bit.RECOV = 0;
		}

		writel(io_dsp.PSUCTRL0.word, &(io_dsp_mem->PSUCTRL0.word) );

		break;

	case XM6_IOCTL_GET_PSUMON:
	{
		T_XM6_PSUMON psumon;
		if (copy_from_user(&psumon,  (void *)arg, sizeof(psumon))) {
			pr_err("%s:%d copy_from_user failed\n", __func__, __LINE__);
			return -EFAULT;
		}

		io_dsp.PSUMON0.word = readl( &(io_dsp_mem->PSUMON0.word) );

		psumon.LPACK = io_dsp.PSUMON0.bit.LPACK;
		psumon.LPACT = io_dsp.PSUMON0.bit.LPACT;
		psumon.DSPIDLE = io_dsp.PSUMON0.bit.DSPIDLE;
		psumon.CORIDLE = io_dsp.PSUMON0.bit.CORIDLE;

		if (copy_to_user((void *)arg, &psumon, sizeof(psumon))) {
			pr_err("%s:%d copy_to_user failed\n", __func__, __LINE__);
			return -EFAULT;
		}

		break;
	}


	case XM6_IOCTL_GET_DSPMON:
	{
		T_XM6_DSPMON dspmon;
		if (copy_from_user(&dspmon,  (void *)arg, sizeof(dspmon))) {
			pr_err("%s:%d copy_from_user failed\n", __func__, __LINE__);
			return -EFAULT;
		}

		io_dsp.DSPMON0.word = readl( &(io_dsp_mem->DSPMON0.word) );

		dspmon.GVI = io_dsp.DSPMON0.bit.DSP_GVI;
		dspmon.JTST = io_dsp.DSPMON0.bit.DSP_JTST;
		dspmon.DEBUG = io_dsp.DSPMON0.bit.DSP_DEBUG;
		dspmon.COREWAIT = io_dsp.DSPMON0.bit.DSP_COREWAIT;
		dspmon.MMIINT = io_dsp.DSPMON0.bit.DSP_MMIINT;

		if (copy_to_user((void *)arg, &dspmon, sizeof(dspmon))) {
			pr_err("%s:%d copy_to_user failed\n", __func__, __LINE__);
			return -EFAULT;
		}

		break;
	}

	case XM6_IOCTL_SW_AXICTL:

		io_dsp.AXISEL.word = readl( &(io_dsp_mem->AXISEL.word) );
		io_dsp.AXISEL.bit.AXISEL = t_param.val;
		writel(io_dsp.AXISEL.word, &(io_dsp_mem->AXISEL.word) );
		break;	

	case XM6_IOCTL_CTL_AXI:
	{
		T_XM6_CTRL_AXI ctrl_axi;
		if (copy_from_user(&ctrl_axi,  (void *)arg, sizeof(ctrl_axi))) {
			pr_err("%s:%d copy_from_user failed\n", __func__, __LINE__);
			return -EFAULT;
		}
		
			io_dsp.EDPAXIRCTL.word = readl( &(io_dsp_mem->EDPAXIRCTL.word) );
			io_dsp.EDPAXIRCTL.bit.EDPRCACHE = ctrl_axi.edp_r.cache_type;
			io_dsp.EDPAXIRCTL.bit.EDPRPROT = ctrl_axi.edp_r.protect_type;
			io_dsp.EDPAXIRCTL.bit.EDPRQOS = ctrl_axi.edp_r.qos_type;
			writel(io_dsp.EDPAXIRCTL.word, &(io_dsp_mem->EDPAXIRCTL.word) );

			io_dsp.EDPAXIWCTL.word = readl( &(io_dsp_mem->EDPAXIWCTL.word) );
			io_dsp.EDPAXIWCTL.bit.EDPWCACHE = ctrl_axi.edp_w.cache_type;
			io_dsp.EDPAXIWCTL.bit.EDPWPROT = ctrl_axi.edp_w.protect_type;
			io_dsp.EDPAXIWCTL.bit.EDPWQOS = ctrl_axi.edp_w.qos_type;
			writel(io_dsp.EDPAXIWCTL.word, &(io_dsp_mem->EDPAXIWCTL.word) );

			io_dsp.EPPAXIRCTL.word = readl( &(io_dsp_mem->EPPAXIRCTL.word) );
			io_dsp.EPPAXIRCTL.bit.EPPRCACHE = ctrl_axi.epp_r.cache_type;
			io_dsp.EPPAXIRCTL.bit.EPPRPROT = ctrl_axi.epp_r.protect_type;
			io_dsp.EPPAXIRCTL.bit.EPPRQOS = ctrl_axi.epp_r.qos_type;
			writel(io_dsp.EPPAXIRCTL.word, &(io_dsp_mem->EPPAXIRCTL.word) );

			io_dsp.EPPAXIWCTL.word = readl( &(io_dsp_mem->EPPAXIWCTL.word) );
			io_dsp.EPPAXIWCTL.bit.EPPWCACHE = ctrl_axi.epp_w.cache_type;
			io_dsp.EPPAXIWCTL.bit.EPPWPROT = ctrl_axi.epp_w.protect_type;
			io_dsp.EPPAXIWCTL.bit.EPPWQOS = ctrl_axi.epp_w.qos_type;
			writel(io_dsp.EPPAXIWCTL.word, &(io_dsp_mem->EPPAXIWCTL.word) );

		break;	
	}


	case XM6_IOCTL_MEM_ALLOC:
	{
		T_XM6_MEM	t_mem;
		INT32 ret;
		struct device *dev = mdev->parent;

		if(copy_from_user(&t_mem, (void*)arg, sizeof(T_XM6_MEM))){
			pr_err("%s:%d copy_from_user failed\n", __func__, __LINE__);
			return -EFAULT;
		}

		ret = dma_set_mask_and_coherent(dev, DMA_BIT_MASK(64));
		if (ret){
			pr_err("%s:%d 64bit DMA mask set failed\n", __func__, __LINE__);
			return -EFAULT;
		}

		t_mem.virtAddr = dma_alloc_coherent(dev, t_mem.size,
		                                  (dma_addr_t*)&(t_mem.physAddr), (GFP_KERNEL | GFP_DMA));

		if(!t_mem.virtAddr){
			pr_err("%s:%d dma alloc coherent failed\n", __func__, __LINE__);
			return -EFAULT;
		}

		if (copy_to_user((void *)arg, &t_mem, sizeof(T_XM6_MEM))){
			pr_err("%s:%d copy_to_user failed\n", __func__, __LINE__);
			return -EFAULT;
		}
		break;
	}

	case XM6_IOCTL_MEM_FREE:
	{
		T_XM6_MEM	t_mem;
		struct device *dev = mdev->parent;

		if(copy_from_user(&t_mem, (void*)arg, sizeof(T_XM6_MEM))){
			pr_err("%s:%d copy_from_user failed\n", __func__, __LINE__);
			return -EFAULT;
		}

		dma_free_coherent(dev, t_mem.size, t_mem.virtAddr, (dma_addr_t)t_mem.physAddr);

		break;
	}

	case XM6_IOCTL_IO_REMAP:
	{
		T_XM6_MEM	t_mem;
		//INT32 ret;
		//struct device *dev = mdev->parent;

		if(copy_from_user(&t_mem, (void*)arg, sizeof(T_XM6_MEM))){
			pr_err("%s:%d copy_from_user failed\n", __func__, __LINE__);
			return -EFAULT;
		}

		t_mem.virtAddr = ioremap((dma_addr_t)t_mem.physAddr, t_mem.size);

		if(!t_mem.virtAddr){
			pr_err("%s:%d ioremap failed\n", __func__, __LINE__);
			return -EFAULT;
		}

		if (copy_to_user((void *)arg, &t_mem, sizeof(T_XM6_MEM))){
			pr_err("%s:%d copy_to_user failed\n", __func__, __LINE__);
			return -EFAULT;
		}
		break;
	}

	case XM6_IOCTL_IO_UNMAP:
		break;


	case XM6_IOCTL_COPY_U2K:
	{
		T_XM6_COPY t_copy;

		if(copy_from_user(&t_copy, (void*)arg, sizeof(T_XM6_COPY))){
			pr_err("%s:%d copy_from_user failed\n", __func__, __LINE__);
			return -EFAULT;
		}

		if(copy_from_user((void*)t_copy.dstAddr, (void*)t_copy.srcAddr, t_copy.size)){
			pr_err("%s:%d copy_from_user (IOCTL_COPY_U2K) failed\n", __func__, __LINE__);
			return -EFAULT;
		}

		break;
	}

	case XM6_IOCTL_COPY_K2U:
	{
		T_XM6_COPY t_copy;

		if(copy_from_user(&t_copy, (void*)arg, sizeof(T_XM6_COPY))){
			pr_err("%s:%d copy_from_user failed\n", __func__, __LINE__);
			return -EFAULT;
		}

		if(copy_to_user((void*)t_copy.dstAddr, (void*)t_copy.srcAddr, t_copy.size)){
			pr_err("%s:%d copy_to_user (IOCTL_COPY_K2U) failed\n", __func__, __LINE__);
			return -EFAULT;
		}

		break;
	}

	case XM6_IOCTL_COPY_K2TCM:
	{
		T_XM6_COPY t_copy;
		dma_addr_t dst_dma_addr;
		dma_addr_t src_dma_addr;
		size_t size;
		struct dma_device *dma_dev;
		struct dma_async_tx_descriptor *tx;
		volatile int dma_flag;

		if(copy_from_user(&t_copy, (void*)arg, sizeof(T_XM6_COPY))){
			pr_err("%s:%d copy_from_user failed\n", __func__, __LINE__);
			return -EFAULT;
		}

		dma_dev = sni_dsp_dev->chan->device;

		dma_flag = 0;
		//dst_dma_addr = D_XM6_DTCM_ADDR;
		dst_dma_addr = (dma_addr_t)t_copy.dstAddr;
		//src_dma_addr = 0xAC908000;
		src_dma_addr = (dma_addr_t)t_copy.srcAddr;
		size = t_copy.size;
		//size = 0x80000;
		tx = dma_dev->device_prep_dma_memcpy(sni_dsp_dev->chan, dst_dma_addr,
                                        src_dma_addr, size, 0);
		if (!tx)
			return -ENOMEM;

		tx->callback = dma_callback;
		tx->callback_param = (void*)&dma_flag;
		dmaengine_submit(tx);
		dma_async_issue_pending(sni_dsp_dev->chan);

		printk("wait for copy to TCM ... (src:%llx dst:%llx size:%ld)\n", src_dma_addr, dst_dma_addr, size);
		while(dma_flag == 0){

		}

		break;
	}


	default:
		pr_err("%s:%d [ERROR] unknown command: %d\n",
					__func__, __LINE__, cmd);
		return -EINVAL;
	}

	return D_SYS_NO_ERR;
}


/* .open */
static int sni_dsp_drv_open(struct inode *inode, struct file *file)
{
	struct miscdevice *mdev = file->private_data;
	struct sni_dsp_device *sni_dsp_dev =
			container_of(mdev, struct sni_dsp_device, miscdev);
	int ret;

	mutex_lock(&sni_dsp_dev->mlock);
	ret = nonseekable_open(inode, file);
	mutex_unlock(&sni_dsp_dev->mlock);
	return ret;
}

/* .release */
static int sni_dsp_drv_release(struct inode *inode, struct file *file)
{
#if 0
	struct miscdevice *mdev = file->private_data;
	struct sni_dsp_device *sni_dsp_dev =
			container_of(mdev, struct sni_dsp_device, miscdev);
#endif
	return 0;
}

/* The file operations for the rena_share_mem */
struct file_operations sni_dsp_drv_fops = {
	.owner		= THIS_MODULE,
	.unlocked_ioctl = sni_dsp_drv_ioctl,
	.open		= sni_dsp_drv_open,
	.release	= sni_dsp_drv_release,
	.llseek		= no_llseek,
};

static int sni_dsp_drv_probe(struct platform_device *pdev)
{
	struct device *dev = &pdev->dev;
	struct sni_dsp_device *sni_dsp_dev;
	struct resource	*res_mem;
	void __iomem *io_mem;

	sni_dsp_dev = devm_kzalloc(dev, sizeof(*sni_dsp_dev), GFP_KERNEL);
	if (!sni_dsp_dev)
		return -ENOMEM;

	// get & set io (register) address
	res_mem = platform_get_resource(pdev, IORESOURCE_MEM, 0);
	if (!res_mem) {
		dev_err(dev, "No IOMEM found\n");
		return -ENXIO;
	}
	io_mem = devm_ioremap(dev, res_mem->start, resource_size(res_mem));
	if (!io_mem) {
		dev_err(dev, "ioremap failed.\n");
		return -ENXIO;
	}
	g_io_dsp_mem = io_mem;

	mutex_init(&sni_dsp_dev->mlock);

	snprintf(sni_dsp_dev->devname, 24, "xm6_peri");

	sni_dsp_dev->miscdev.name = sni_dsp_dev->devname;
	sni_dsp_dev->miscdev.minor = MISC_DYNAMIC_MINOR,
	sni_dsp_dev->miscdev.fops = &sni_dsp_drv_fops,
	sni_dsp_dev->miscdev.parent = dev;

	platform_set_drvdata(pdev, sni_dsp_dev);

	sni_dsp_dev->chan = dma_request_chan(dev, "your_xdmac");
	if (IS_ERR(sni_dsp_dev->chan)) {
		dev_err(dev, "failed to request dma-controller\n");
		//return -ENODEV;
	}

	return misc_register(&sni_dsp_dev->miscdev);
}

static int sni_dsp_drv_remove(struct platform_device *pdev)
{
	struct sni_dsp_device *sni_dsp_dev = platform_get_drvdata(pdev);


	if (g_io_dsp_mem != NULL) {
		devm_iounmap(&pdev->dev, g_io_dsp_mem);
	}

	misc_deregister(&sni_dsp_dev->miscdev);
	return 0;
}

static const struct of_device_id sni_dsp_peri_id[] = {
	{ .compatible = "socionext,dsp-peri-device" },
	{},
};
MODULE_DEVICE_TABLE(of, sni_dsp_peri_id);

static struct platform_driver sni_dsp_peri_driver = {
	.probe = sni_dsp_drv_probe,
	.remove = sni_dsp_drv_remove,
	.driver = {
		.name = "sni-dsp-peri-driver",
		.of_match_table = sni_dsp_peri_id,
	},
};
module_platform_driver(sni_dsp_peri_driver);

MODULE_LICENSE("GPL");
