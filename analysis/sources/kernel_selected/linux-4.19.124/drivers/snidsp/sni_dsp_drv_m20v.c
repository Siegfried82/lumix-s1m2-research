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

#include "sni_dsp_drv_m20v.h"
#include "sni_dsp_reg_m20v.h"

void __iomem *g_io_dsp_mem;
void __iomem *g_io_mem_cnn_sram; 

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
	int is_xm6;
	struct io_sni_dsp *io_dsp_mem;
	struct io_sni_dsp io_dsp;
	T_DSP_PARAM t_param;

	struct miscdevice *mdev = filp->private_data;
	struct sni_dsp_device *sni_dsp_dev =
			container_of(mdev, struct sni_dsp_device, miscdev);

	if ((_IOC_TYPE(cmd) != XM6_IOCTL_MAGIC) &&
		(_IOC_TYPE(cmd) != CNN_IOCTL_MAGIC)){
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

	is_xm6 = sni_dsp_dev->is_xm6;

	if(is_xm6){
		if (_IOC_NR(cmd) > XM6_IOCTL_MAXNR){
			return -ENOTTY;
		}
	}
	else{
		if ((_IOC_NR(cmd) > CNN_IOCTL_MAXNR ) || 
			(_IOC_NR(cmd) < CNN_IOCTL_MINNR )){
			return -ENOTTY;
		}
	}

	io_dsp_mem = (struct io_sni_dsp *)g_io_dsp_mem;

	if (copy_from_user(&t_param,  (void *)arg, sizeof(t_param))) {
		pr_err("%s:%d copy_from_user failed\n", __func__, __LINE__);
		return -EFAULT;
	}


	switch (cmd) {
	case XM6_IOCTL_AUTOCTL_SRAM:

		io_dsp.DSPCTRL0.word = readl( &(io_dsp_mem->DSPCTRL0.word) );

		if(t_param.core == 0)
			io_dsp.DSPCTRL0.bit.ACSLPD0 = t_param.val;
		else
			io_dsp.DSPCTRL0.bit.ACSLPD1 = t_param.val;

		writel( io_dsp.DSPCTRL0.word, &(io_dsp_mem->DSPCTRL0.word) );

		break;

	case XM6_IOCTL_SW_SRAMCTL:

		io_dsp.DSPCTRL0.word = readl( &(io_dsp_mem->DSPCTRL0.word) );

		if(t_param.core == 0)
			io_dsp.DSPCTRL0.bit.CTRLPSVMD0 = t_param.val;
		else
			io_dsp.DSPCTRL0.bit.CTRLPSVMD1 = t_param.val;

		writel( io_dsp.DSPCTRL0.word, &(io_dsp_mem->DSPCTRL0.word) );

		break;

	case XM6_IOCTL_SLP_SRAM:

		io_dsp.DSPCTRL0.word = readl( &(io_dsp_mem->DSPCTRL0.word) );

		if(t_param.core == 0)
			io_dsp.DSPCTRL0.bit.SLPD0 = t_param.val;
		else
			io_dsp.DSPCTRL0.bit.SLPD1 = t_param.val;

		writel( io_dsp.DSPCTRL0.word, &(io_dsp_mem->DSPCTRL0.word) );

		break;

	case XM6_IOCTL_SD_SRAM:

		io_dsp.DSPCTRL0.word = readl( &(io_dsp_mem->DSPCTRL0.word) );

		if(t_param.core == 0)
			io_dsp.DSPCTRL0.bit.SDD0 = t_param.val;
		else
			io_dsp.DSPCTRL0.bit.SDD1 = t_param.val;

		writel( io_dsp.DSPCTRL0.word, &(io_dsp_mem->DSPCTRL0.word) );

		break;

	case XM6_IOCTL_DIV_CTL:

		io_dsp.DSPCTRL2.word = readl( &(io_dsp_mem->DSPCTRL2.word) );

		io_dsp.DSPCTRL2.bit.DIV = t_param.val;
		//DSPCTRL2 has only one register.
		//It does not distinguish between XM6-0 and XM6-1.

		writel(io_dsp.DSPCTRL2.word, &(io_dsp_mem->DSPCTRL2.word) );

		break;

	case XM6_IOCTL_RESET_CORE:

		mutex_lock(&sni_dsp_dev->mlock);
		io_dsp.DSPCTRLSR0.word = readl( &(io_dsp_mem->DSPCTRLSR0.word) );

		if(t_param.core == 0)
			io_dsp.DSPCTRLSR0.bit.SRD0 = t_param.val;
		else
			io_dsp.DSPCTRLSR0.bit.SRD1 = t_param.val;

		writel(io_dsp.DSPCTRLSR0.word, &(io_dsp_mem->DSPCTRLSR0.word) );
		mutex_unlock(&sni_dsp_dev->mlock);

		break;

	case XM6_IOCTL_GET_CORERST:

		io_dsp.DSPCTRLSR0.word = readl( &(io_dsp_mem->DSPCTRLSR0.word) );

		if(t_param.core == 0)
			t_param.val = io_dsp.DSPCTRLSR0.bit.SRD0;
		else
			t_param.val = io_dsp.DSPCTRLSR0.bit.SRD1;

		if (copy_to_user((void *)arg, &t_param, sizeof(t_param))) {
			pr_err("%s:%d copy_to_user failed\n", __func__, __LINE__);
			return -EFAULT;
		}

		break;

	case XM6_IOCTL_RESET_PERI:

		io_dsp.DSPCTRLSR1.word = readl( &(io_dsp_mem->DSPCTRLSR1.word) );

		io_dsp.DSPCTRLSR1.bit.SR = t_param.val;
		//DSPCTRLSR1 has only one register.
		//It does not distinguish between XM6-0 and XM6-1.

		writel(io_dsp.DSPCTRLSR1.word, &(io_dsp_mem->DSPCTRLSR1.word) );

		break;

	case XM6_IOCTL_TDSEL:

		io_dsp.TDSEL.word = readl( &(io_dsp_mem->TDSEL.word) );

		switch( t_param.val ){
			case  XM6_TIMER_0:
				if(t_param.core == 0)
					io_dsp.TDSEL.bit.TDSEL0 = 0;
				else
					io_dsp.TDSEL.bit.TDSEL0 = 1;
				break;
			case  XM6_TIMER_1:
				if(t_param.core == 0)
					io_dsp.TDSEL.bit.TDSEL1 = 0;
				else
					io_dsp.TDSEL.bit.TDSEL1 = 1;
				break;
			case  XM6_TIMER_2:
				if(t_param.core == 0)
					io_dsp.TDSEL.bit.TDSEL2 = 0;
				else
					io_dsp.TDSEL.bit.TDSEL2 = 1;
				break;
			case  XM6_TIMER_3:
				if(t_param.core == 0)
					io_dsp.TDSEL.bit.TDSEL3 = 0;
				else
					io_dsp.TDSEL.bit.TDSEL3 = 1;
				break;
			case  XM6_TIMER_4:
				if(t_param.core == 0)
					io_dsp.TDSEL.bit.TDSEL4 = 0;
				else
					io_dsp.TDSEL.bit.TDSEL4 = 1;
				break;
			case  XM6_TIMER_5:
				if(t_param.core == 0)
					io_dsp.TDSEL.bit.TDSEL5 = 0;
				else
					io_dsp.TDSEL.bit.TDSEL5 = 1;
				break;
			case  XM6_TIMER_6:
				if(t_param.core == 0)
					io_dsp.TDSEL.bit.TDSEL6 = 0;
				else
					io_dsp.TDSEL.bit.TDSEL6 = 1;
				break;
			case  XM6_TIMER_7:
				if(t_param.core == 0)
					io_dsp.TDSEL.bit.TDSEL7 = 0;
				else
					io_dsp.TDSEL.bit.TDSEL7 = 1;
				break;
			default:
				pr_err("%s:%d XM6_IOCTL_TDSEL error\n", __func__, __LINE__);
				return -EFAULT;
		}

		writel(io_dsp.TDSEL.word, &(io_dsp_mem->TDSEL.word) );

		break;

	case XM6_IOCTL_CTL_MCI:

		io_dsp.DSPCTRLSR0.word = readl( &(io_dsp_mem->DSPCTRLSR0.word) );
		io_dsp.DSPCTRL3.word = readl( &(io_dsp_mem->DSPCTRL3.word) );

		if(t_param.core == 0){
			if(io_dsp.DSPCTRLSR0.bit.SRD0 == DSP_SET_ON){
				io_dsp.DSPCTRL3.bit.MCI0 = t_param.val;
			}
			else{
				pr_err("%s:%d DSP core need to be reset state\n", __func__, __LINE__);
				return -EFAULT;
			}
		}
		else{
			if(io_dsp.DSPCTRLSR0.bit.SRD1 == DSP_SET_ON){
				io_dsp.DSPCTRL3.bit.MCI1 = t_param.val;
			}
			else{
				pr_err("%s:%d DSP core need to be reset state\n", __func__, __LINE__);
				return -EFAULT;
			}
		}

		writel(io_dsp.DSPCTRL3.word, &(io_dsp_mem->DSPCTRL3.word) );

		break;

	case XM6_IOCTL_CTL_EXTWAIT:

		io_dsp.DSPCTRL4.word = readl( &(io_dsp_mem->DSPCTRL4.word) );

		if(t_param.core == 0)
			io_dsp.DSPCTRL4.bit.EXTW0 = t_param.val;
		else
			io_dsp.DSPCTRL4.bit.EXTW1 = t_param.val;

		writel(io_dsp.DSPCTRL4.word, &(io_dsp_mem->DSPCTRL4.word) );

		break;

	case  XM6_IOCTL_REQ_NMI:

		io_dsp.INTCTRL.word = readl( &(io_dsp_mem->INTCTRL.word) );

		if(t_param.core == 0){
			if(io_dsp.INTCTRL.bit.NMI0 == 0){
				io_dsp.INTCTRL.bit.NMI0 = 1;
			}
			else{
				pr_err("%s:%d NMI is already assert \n", __func__, __LINE__);
				return -EFAULT;
			}
		}
		else{
			if(io_dsp.INTCTRL.bit.NMI1 == 0){
				io_dsp.INTCTRL.bit.NMI1 = 1;
			}
			else{
				pr_err("%s:%d NMI is already assert \n", __func__, __LINE__);
				return -EFAULT;
			}
		}

		writel(io_dsp.INTCTRL.word, &(io_dsp_mem->INTCTRL.word) );

		break;

	case  XM6_IOCTL_REQ_VINT:

		io_dsp.INTCTRL.word = readl( &(io_dsp_mem->INTCTRL.word) );

		if(t_param.core == 0){
			if(io_dsp.INTCTRL.bit.VINT0 == 0){
				io_dsp.INTCTRL.bit.VINT0 = 1;
			}
			else{
				pr_err("%s:%d VINT is already assert \n", __func__, __LINE__);
				return -EFAULT;
			}
		}
		else{
			if(io_dsp.INTCTRL.bit.VINT1 == 0){
				io_dsp.INTCTRL.bit.VINT1 = 1;
			}
			else{
				pr_err("%s:%d VINT is already assert \n", __func__, __LINE__);
				return -EFAULT;
			}
		}

		writel(io_dsp.INTCTRL.word, &(io_dsp_mem->INTCTRL.word) );

		break;

	case XM6_IOCTL_GET_INTSTAT:
	{
		T_XM6_INTCTRL intctrl;
		if (copy_from_user(&intctrl,  (void *)arg, sizeof(intctrl))) {
			pr_err("%s:%d copy_from_user failed\n", __func__, __LINE__);
			return -EFAULT;
		}

		io_dsp.INTCTRL.word = readl( &(io_dsp_mem->INTCTRL.word) );

		if(intctrl.core == 0){
			intctrl.NMI = io_dsp.INTCTRL.bit.NMI0;
			intctrl.VINT = io_dsp.INTCTRL.bit.VINT0;
		}
		else{
			intctrl.NMI = io_dsp.INTCTRL.bit.NMI1;
			intctrl.VINT = io_dsp.INTCTRL.bit.VINT1;
		}
		
		if (copy_to_user((void *)arg, &intctrl, sizeof(intctrl))) {
			pr_err("%s:%d copy_to_user failed\n", __func__, __LINE__);
			return -EFAULT;
		}

		break;
	}

	case  XM6_IOCTL_VINT_ADDR:

		if(t_param.core == 0){
			io_dsp.VINT_ADDR0.word = readl( &(io_dsp_mem->VINT_ADDR0.word) );
			io_dsp.VINT_ADDR0.word = t_param.val;
			writel(io_dsp.VINT_ADDR0.word, &(io_dsp_mem->VINT_ADDR0.word) );
		}
		else{
			io_dsp.VINT_ADDR1.word = readl( &(io_dsp_mem->VINT_ADDR1.word) );
			io_dsp.VINT_ADDR1.word = t_param.val;
			writel(io_dsp.VINT_ADDR1.word, &(io_dsp_mem->VINT_ADDR1.word) );
		}

		break;

	case XM6_IOCTL_SW_LPMODE:

		io_dsp.PSUCTRL0.word = readl( &(io_dsp_mem->PSUCTRL0.word) );

		if(t_param.core == 0)
			io_dsp.PSUCTRL0.bit.LPREQ0 = t_param.val;
		else
			io_dsp.PSUCTRL0.bit.LPREQ1 = t_param.val;

		writel(io_dsp.PSUCTRL0.word, &(io_dsp_mem->PSUCTRL0.word) );

		break;

	case XM6_IOCTL_CTL_RECOV:

		io_dsp.PSUCTRL0.word = readl( &(io_dsp_mem->PSUCTRL0.word) );
		io_dsp.PSUMON0.word = readl( &(io_dsp_mem->PSUMON0.word) );

		if(t_param.core == 0){
			if(t_param.val == DSP_SET_ON){
				if(io_dsp.PSUMON0.bit.CORIDLE0 == XM6_STATE_IDLE){
					io_dsp.PSUCTRL0.bit.RECOV0 = 1;
				}
				else{
					pr_err("%s:%d recovery error (state is already not idle)\n", __func__, __LINE__);
					return -EFAULT;
				}
			}
			else{
				io_dsp.PSUCTRL0.bit.RECOV0 = 0;
			}
		}
		else{
			if(t_param.val == DSP_SET_ON){
				if(io_dsp.PSUMON0.bit.CORIDLE1 == XM6_STATE_IDLE){
					io_dsp.PSUCTRL0.bit.RECOV1 = 1;
				}
				else{
					pr_err("%s:%d recovery error (state is already not idle)\n", __func__, __LINE__);
					return -EFAULT;
				}
			}
			else{
				io_dsp.PSUCTRL0.bit.RECOV1 = 0;
			}
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
		io_dsp.PSUMON1.word = readl( &(io_dsp_mem->PSUMON1.word) );

		if(psumon.core == 0){
			psumon.LPACK = io_dsp.PSUMON0.bit.LPACK0;
			psumon.LPACT = io_dsp.PSUMON0.bit.LPACT0;
			psumon.DSPIDLE = io_dsp.PSUMON0.bit.DSPIDLE0;
			psumon.CORIDLE = io_dsp.PSUMON0.bit.CORIDLE0;
			psumon.PSR = io_dsp.PSUMON1.bit.PSR0;
			psumon.MRM = io_dsp.PSUMON1.bit.MRM0;
		}
		else{
			psumon.LPACK = io_dsp.PSUMON0.bit.LPACK1;
			psumon.LPACT = io_dsp.PSUMON0.bit.LPACT1;
			psumon.DSPIDLE = io_dsp.PSUMON0.bit.DSPIDLE1;
			psumon.CORIDLE = io_dsp.PSUMON0.bit.CORIDLE1;
			psumon.PSR = io_dsp.PSUMON1.bit.PSR1;
			psumon.MRM = io_dsp.PSUMON1.bit.MRM1;
		}

		if (copy_to_user((void *)arg, &psumon, sizeof(psumon))) {
			pr_err("%s:%d copy_to_user failed\n", __func__, __LINE__);
			return -EFAULT;
		}

		break;
	}

	case XM6_IOCTL_SET_GPIN:

		io_dsp.DSP0_GPIN.word = readl( &(io_dsp_mem->DSP0_GPIN.word) );
		io_dsp.DSP1_GPIN.word = readl( &(io_dsp_mem->DSP1_GPIN.word) );

		if(t_param.core == 0)
			io_dsp.DSP0_GPIN.word = t_param.val;
		else
			io_dsp.DSP1_GPIN.word = t_param.val;

		writel(io_dsp.DSP0_GPIN.word, &(io_dsp_mem->DSP0_GPIN.word) );
		writel(io_dsp.DSP1_GPIN.word, &(io_dsp_mem->DSP1_GPIN.word) );

		break;

	case XM6_IOCTL_GET_GPOUT:

		if(t_param.core == 0)
			t_param.val = readl( &(io_dsp_mem->DSP0_GPOUT.word) );
		else
			t_param.val = readl( &(io_dsp_mem->DSP1_GPOUT.word) );

		if (copy_to_user((void *)arg, &t_param, sizeof(t_param))) {
			pr_err("%s:%d copy_to_user failed\n", __func__, __LINE__);
			return -EFAULT;
		}

		break;

	case XM6_IOCTL_GET_DSPMON:
	{
		T_XM6_DSPMON dspmon;
		if (copy_from_user(&dspmon,  (void *)arg, sizeof(dspmon))) {
			pr_err("%s:%d copy_from_user failed\n", __func__, __LINE__);
			return -EFAULT;
		}

		io_dsp.DSPMON0.word = readl( &(io_dsp_mem->DSPMON0.word) );

		if(dspmon.core == 0){
			dspmon.GVI = io_dsp.DSPMON0.bit.DSP0_GVI;
			dspmon.JTST = io_dsp.DSPMON0.bit.DSP0_JTST;
			dspmon.DEBUG = io_dsp.DSPMON0.bit.DSP0_DEBUG;
			dspmon.COREWAIT = io_dsp.DSPMON0.bit.DSP0_COREWAIT;
			dspmon.MMIINT = io_dsp.DSPMON0.bit.DSP0_MMIINT;
			dspmon.MMIREAD = readl( &(io_dsp_mem->DSPMON1.word) );
		}
		else{
			dspmon.GVI = io_dsp.DSPMON0.bit.DSP1_GVI;
			dspmon.JTST = io_dsp.DSPMON0.bit.DSP1_JTST;
			dspmon.DEBUG = io_dsp.DSPMON0.bit.DSP1_DEBUG;
			dspmon.COREWAIT = io_dsp.DSPMON0.bit.DSP1_COREWAIT;
			dspmon.MMIINT = io_dsp.DSPMON0.bit.DSP1_MMIINT;
			dspmon.MMIREAD = readl( &(io_dsp_mem->DSPMON2.word) );
		}

		if (copy_to_user((void *)arg, &dspmon, sizeof(dspmon))) {
			pr_err("%s:%d copy_to_user failed\n", __func__, __LINE__);
			return -EFAULT;
		}

		break;
	}

	case XM6_IOCTL_SW_AXICTL:

		mutex_lock(&sni_dsp_dev->mlock);
		io_dsp.AXISEL.word = readl( &(io_dsp_mem->AXISEL.word) );

		if(t_param.core == 0)
			io_dsp.AXISEL.bit.AXISEL_DSP0 = t_param.val;
		else
			io_dsp.AXISEL.bit.AXISEL_DSP1 = t_param.val;

		writel(io_dsp.AXISEL.word, &(io_dsp_mem->AXISEL.word) );
		mutex_unlock(&sni_dsp_dev->mlock);

		break;	

	case XM6_IOCTL_CTL_AXI:
	{
		T_XM6_CTRL_AXI ctrl_axi;
		if (copy_from_user(&ctrl_axi,  (void *)arg, sizeof(ctrl_axi))) {
			pr_err("%s:%d copy_from_user failed\n", __func__, __LINE__);
			return -EFAULT;
		}
		
		if(ctrl_axi.core == 0){

			io_dsp.EDP0AXIRCTL.word = readl( &(io_dsp_mem->EDP0AXIRCTL.word) );
			io_dsp.EDP0AXIRCTL.bit.EDP0RCACHE = ctrl_axi.edp_r.cache_type;
			io_dsp.EDP0AXIRCTL.bit.EDP0RPROT = ctrl_axi.edp_r.protect_type;
			io_dsp.EDP0AXIRCTL.bit.EDP0RQOS = ctrl_axi.edp_r.qos_type;
			writel(io_dsp.EDP0AXIRCTL.word, &(io_dsp_mem->EDP0AXIRCTL.word) );

			io_dsp.EDP0AXIWCTL.word = readl( &(io_dsp_mem->EDP0AXIWCTL.word) );
			io_dsp.EDP0AXIWCTL.bit.EDP0WCACHE = ctrl_axi.edp_w.cache_type;
			io_dsp.EDP0AXIWCTL.bit.EDP0WPROT = ctrl_axi.edp_w.protect_type;
			io_dsp.EDP0AXIWCTL.bit.EDP0WQOS = ctrl_axi.edp_w.qos_type;
			writel(io_dsp.EDP0AXIWCTL.word, &(io_dsp_mem->EDP0AXIWCTL.word) );

			io_dsp.EPP0AXIRCTL.word = readl( &(io_dsp_mem->EPP0AXIRCTL.word) );
			io_dsp.EPP0AXIRCTL.bit.EPP0RCACHE = ctrl_axi.epp_r.cache_type;
			io_dsp.EPP0AXIRCTL.bit.EPP0RPROT = ctrl_axi.epp_r.protect_type;
			io_dsp.EPP0AXIRCTL.bit.EPP0RQOS = ctrl_axi.epp_r.qos_type;
			writel(io_dsp.EPP0AXIRCTL.word, &(io_dsp_mem->EPP0AXIRCTL.word) );

			io_dsp.EPP0AXIWCTL.word = readl( &(io_dsp_mem->EPP0AXIWCTL.word) );
			io_dsp.EPP0AXIWCTL.bit.EPP0WCACHE = ctrl_axi.epp_w.cache_type;
			io_dsp.EPP0AXIWCTL.bit.EPP0WPROT = ctrl_axi.epp_w.protect_type;
			io_dsp.EPP0AXIWCTL.bit.EPP0WQOS = ctrl_axi.epp_w.qos_type;
			writel(io_dsp.EPP0AXIWCTL.word, &(io_dsp_mem->EPP0AXIWCTL.word) );

		}
		else{

			io_dsp.EDP1AXIRCTL.word = readl( &(io_dsp_mem->EDP1AXIRCTL.word) );
			io_dsp.EDP1AXIRCTL.bit.EDP1RCACHE = ctrl_axi.edp_r.cache_type;
			io_dsp.EDP1AXIRCTL.bit.EDP1RPROT = ctrl_axi.edp_r.protect_type;
			io_dsp.EDP1AXIRCTL.bit.EDP1RQOS = ctrl_axi.edp_r.qos_type;
			writel(io_dsp.EDP1AXIRCTL.word, &(io_dsp_mem->EDP1AXIRCTL.word) );

			io_dsp.EDP1AXIWCTL.word = readl( &(io_dsp_mem->EDP1AXIWCTL.word) );
			io_dsp.EDP1AXIWCTL.bit.EDP1WCACHE = ctrl_axi.edp_w.cache_type;
			io_dsp.EDP1AXIWCTL.bit.EDP1WPROT = ctrl_axi.edp_w.protect_type;
			io_dsp.EDP1AXIWCTL.bit.EDP1WQOS = ctrl_axi.edp_w.qos_type;
			writel(io_dsp.EDP1AXIWCTL.word, &(io_dsp_mem->EDP1AXIWCTL.word) );

			io_dsp.EPP1AXIRCTL.word = readl( &(io_dsp_mem->EPP1AXIRCTL.word) );
			io_dsp.EPP1AXIRCTL.bit.EPP1RCACHE = ctrl_axi.epp_r.cache_type;
			io_dsp.EPP1AXIRCTL.bit.EPP1RPROT = ctrl_axi.epp_r.protect_type;
			io_dsp.EPP1AXIRCTL.bit.EPP1RQOS = ctrl_axi.epp_r.qos_type;
			writel(io_dsp.EPP1AXIRCTL.word, &(io_dsp_mem->EPP1AXIRCTL.word) );

			io_dsp.EPP1AXIWCTL.word = readl( &(io_dsp_mem->EPP1AXIWCTL.word) );
			io_dsp.EPP1AXIWCTL.bit.EPP1WCACHE = ctrl_axi.epp_w.cache_type;
			io_dsp.EPP1AXIWCTL.bit.EPP1WPROT = ctrl_axi.epp_w.protect_type;
			io_dsp.EPP1AXIWCTL.bit.EPP1WQOS = ctrl_axi.epp_w.qos_type;
			writel(io_dsp.EPP1AXIWCTL.word, &(io_dsp_mem->EPP1AXIWCTL.word) );

		}

		break;	
	}

	case XM6_IOCTL_CTL_GPOUT:

		io_dsp.DSP_GPOUT_CTRL.word = readl( &(io_dsp_mem->DSP_GPOUT_CTRL.word) );

		io_dsp.DSP_GPOUT_CTRL.bit.DSP_GPOUT_CTRL = t_param.val;
		//DSP_GPOUT_CTRL has only one register.
		//It does not distinguish between XM6-0 and XM6-1.

		writel(io_dsp.DSP_GPOUT_CTRL.word, &(io_dsp_mem->DSP_GPOUT_CTRL.word) );

		break;	



	case CNN_IOCTL_RESET_CORE:

		mutex_lock(&sni_dsp_dev->mlock);

		io_dsp.DSPCTRLSR0.word = readl( &(io_dsp_mem->DSPCTRLSR0.word) );
		io_dsp.DSPCTRLSR0.bit.SRCNN = t_param.val;
		writel(io_dsp.DSPCTRLSR0.word, &(io_dsp_mem->DSPCTRLSR0.word) );

		mutex_unlock(&sni_dsp_dev->mlock);

		break;

	case CNN_IOCTL_GET_CORERST:

		io_dsp.DSPCTRLSR0.word = readl( &(io_dsp_mem->DSPCTRLSR0.word) );

		t_param.val = io_dsp.DSPCTRLSR0.bit.SRCNN;

		if (copy_to_user((void *)arg, &t_param, sizeof(t_param))) {
			pr_err("%s:%d copy_to_user failed\n", __func__, __LINE__);
			return -EFAULT;
		}

		break;

	case CNN_IOCTL_SLP_SRAM:
	{
		unsigned int val = readl(g_io_mem_cnn_sram);
		if(t_param.val == DSP_SET_ON){
			if(val & 0x00000100){
				pr_err("%s:%d cnn sram already sleep\n", __func__, __LINE__);
			}
			val |= 0x00000100;
			writel(val, g_io_mem_cnn_sram);
			val |= 0x00000200;
			writel(val, g_io_mem_cnn_sram);
			val |= 0x00000400;
			writel(val, g_io_mem_cnn_sram);
		}
		else if(t_param.val == DSP_SET_OFF){
			if( !(val & 0x00000100) ){
				pr_err("%s:%d cnn sram already wake up\n", __func__, __LINE__);
			}
			val &= 0xFFFFFBFF;
			writel(val, g_io_mem_cnn_sram);
			val &= 0xFFFFFDFF;
			writel(val, g_io_mem_cnn_sram);
			val &= 0xFFFFFEFF;
			writel(val, g_io_mem_cnn_sram);
		}
		else{
			pr_err("%s:%d param error !!\n", __func__, __LINE__);
			return -EFAULT;
		}
		break;
	}

	case CNN_IOCTL_SD_SRAM:
	{
		unsigned int val = readl(g_io_mem_cnn_sram);
		if(t_param.val == DSP_SET_ON){
			if(val & 0x00000001){
				pr_err("%s:%d cnn sram already run\n", __func__, __LINE__);
			}
			val |= 0x00000001;
			writel(val, g_io_mem_cnn_sram);
			val |= 0x00000002;
			writel(val, g_io_mem_cnn_sram);
			val |= 0x00000004;
			writel(val, g_io_mem_cnn_sram);
		}
		else if(t_param.val == DSP_SET_OFF){
			if( !(val & 0x00000001) ){
				pr_err("%s:%d cnn sram already shutdown\n", __func__, __LINE__);
			}
			val &= 0xFFFFFFFB;
			writel(val, g_io_mem_cnn_sram);
			val &= 0xFFFFFFFD;
			writel(val, g_io_mem_cnn_sram);
			val &= 0xFFFFFFFE;
			writel(val, g_io_mem_cnn_sram);
		}
		else{
			pr_err("%s:%d param error !!\n", __func__, __LINE__);
			return -EFAULT;
		}
		break;
	}

	case CNN_IOCTL_RESET_PERI:

		mutex_lock(&sni_dsp_dev->mlock);

		io_dsp.DSPCTRLSR1.word = readl( &(io_dsp_mem->DSPCTRLSR1.word) );
		io_dsp.DSPCTRLSR1.bit.SR = t_param.val;
		writel(io_dsp.DSPCTRLSR1.word, &(io_dsp_mem->DSPCTRLSR1.word) );

		mutex_unlock(&sni_dsp_dev->mlock);
		break;


	case CNN_IOCTL_SW_AXICTL:

		mutex_lock(&sni_dsp_dev->mlock);
		
		io_dsp.AXISEL.word = readl( &(io_dsp_mem->AXISEL.word) );
		io_dsp.AXISEL.bit.AXISEL_CNN = t_param.val;
		writel(io_dsp.AXISEL.word, &(io_dsp_mem->AXISEL.word) );

		mutex_unlock(&sni_dsp_dev->mlock);

		break;

	case CNN_IOCTL_CTL_AXI:
	{
		T_CNN_CTRL_AXI ctrl_axi;
		if (copy_from_user(&ctrl_axi,  (void *)arg, sizeof(ctrl_axi))) {
			pr_err("%s:%d copy_from_user failed\n", __func__, __LINE__);
			return -EFAULT;
		}

		io_dsp.CNNAXIRCTL.word = readl( &(io_dsp_mem->CNNAXIRCTL.word) );
		io_dsp.CNNAXIRCTL.bit.CNNRCACHE = ctrl_axi.cnn_r.cache_type;
		io_dsp.CNNAXIRCTL.bit.CNNRPROT = ctrl_axi.cnn_r.protect_type;
		io_dsp.CNNAXIRCTL.bit.CNNRQOS = ctrl_axi.cnn_r.qos_type;
		writel(io_dsp.CNNAXIRCTL.word, &(io_dsp_mem->CNNAXIRCTL.word) );

		io_dsp.CNNAXIWCTL.word = readl( &(io_dsp_mem->CNNAXIWCTL.word) );
		io_dsp.CNNAXIWCTL.bit.CNNWCACHE = ctrl_axi.cnn_w.cache_type;
		io_dsp.CNNAXIWCTL.bit.CNNWPROT = ctrl_axi.cnn_w.protect_type;
		io_dsp.CNNAXIWCTL.bit.CNNWQOS = ctrl_axi.cnn_w.qos_type;
		writel(io_dsp.CNNAXIWCTL.word, &(io_dsp_mem->CNNAXIWCTL.word) );

		break;
	}

	case CNN_IOCTL_REQ_LP:
	
		io_dsp.CNN_CTRL0.word = readl( &(io_dsp_mem->CNN_CTRL0.word) );
		io_dsp.CNN_CTRL0.bit.CSYSREQ = t_param.val;
		writel(io_dsp.CNN_CTRL0.word, &(io_dsp_mem->CNN_CTRL0.word) );

		break;

	case CNN_IOCTL_GET_STATUS:
	{
		T_CNN_STATUS status;

		io_dsp.CNN_CTRL1.word = readl( &(io_dsp_mem->CNN_CTRL1.word) );

		status.CSYSACK = io_dsp.CNN_CTRL1.bit.CSYSACK;
		status.CACTIVE = io_dsp.CNN_CTRL1.bit.CACTIVE;
		status.DEBUG_OUT = io_dsp.CNN_CTRL1.bit.DEBUG_OUT;

		if (copy_to_user((void *)arg, &status, sizeof(status))) {
			pr_err("%s:%d copy_to_user failed\n", __func__, __LINE__);
			return -EFAULT;
		}

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
	u32 is_xm6 = 0;

	sni_dsp_dev = devm_kzalloc(dev, sizeof(*sni_dsp_dev), GFP_KERNEL);
	if (!sni_dsp_dev)
		return -ENOMEM;

	if (!of_property_read_u32(dev->of_node, "is-xm6", &is_xm6)) {
		if (is_xm6 >= 2) {
			dev_err(dev, "Invalid is-xm6:%d\n", is_xm6);
			return -EINVAL;
		}
		sni_dsp_dev->is_xm6 = is_xm6;
	}

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

#if 0
	if(is_xm6 == 1){
		res_mem = platform_get_resource(pdev, IORESOURCE_MEM, 1);
		if (!res_mem) {
			dev_err(dev, "No IOMEM found\n");
			return -ENXIO;
		}
		io_mem = devm_ioremap(dev, res_mem->start, resource_size(res_mem));
		if (!io_mem) {
			dev_err(dev, "ioremap failed.\n");
			return -ENXIO;
		}
		g_io_xm6_dtcm = io_mem;

		res_mem = platform_get_resource(pdev, IORESOURCE_MEM, 2);
		if (!res_mem) {
			dev_err(dev, "No IOMEM found\n");
			return -ENXIO;
		}
		io_mem = devm_ioremap(dev, res_mem->start, resource_size(res_mem));
		if (!io_mem) {
			dev_err(dev, "ioremap failed.\n");
			return -ENXIO;
		}
		g_io_xm6_ptcm = io_mem;
	}
#endif

	if(is_xm6 == 0){
		res_mem = platform_get_resource(pdev, IORESOURCE_MEM, 1);
		if (!res_mem) {
			dev_err(dev, "No IOMEM found\n");
			return -ENXIO;
		}
		io_mem = devm_ioremap(dev, res_mem->start, resource_size(res_mem));
		if (!io_mem) {
			dev_err(dev, "ioremap failed.\n");
			return -ENXIO;
		}
		g_io_mem_cnn_sram = io_mem;
	}

	mutex_init(&sni_dsp_dev->mlock);

	if(is_xm6 == 1)
		snprintf(sni_dsp_dev->devname, 24, "xm6_peri");
	else
		snprintf(sni_dsp_dev->devname, 24, "cnn_peri");

	sni_dsp_dev->miscdev.name = sni_dsp_dev->devname;
	sni_dsp_dev->miscdev.minor = MISC_DYNAMIC_MINOR,
	sni_dsp_dev->miscdev.fops = &sni_dsp_drv_fops,
	sni_dsp_dev->miscdev.parent = dev;

	platform_set_drvdata(pdev, sni_dsp_dev);

#if 1
	if(is_xm6 == 1){
		sni_dsp_dev->chan = dma_request_chan(dev, "your_xdmac");
		if (IS_ERR(sni_dsp_dev->chan)) {
			dev_err(dev, "failed to request dma-controller\n");
			return -ENODEV;
		}
	}
#endif

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
