/*
 * arch/arm/mach-milbeaut/milb_cpu_hotplug.c
 * Copyright:	(C) 2019 Socionext
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 */
#include <linux/mutex.h>
#include <linux/of_address.h>
#include <linux/miscdevice.h>
#include <linux/poll.h>
#include <linux/fs.h>
#include <linux/io.h>
#include <linux/sched.h>
#include <linux/irqreturn.h>
#include <linux/of_irq.h>
#include <linux/wait.h>
#include <linux/platform_device.h>
#include <linux/interrupt.h>
#include <linux/module.h>
#include <linux/irqchip/arm-gic.h>
#include <linux/milb_cpu_hotplug.h>

#define DEVICE_NAME "smp-cpuswitch"
#define SELF_CPU	(3)
#define D_SWITCH_CPU_OFF_LINE	(4)
#define D_SWITCH_CPU_ON_LINE	(3)
#define D_RTOS_CPU_ID	(0)
#define D_RESET_CPU0	(0x00000100)
#define D_RESET_CPU1	(0x00000200)
#define D_RESET_CPU2	(0x00000400)
#define D_RESET_CPU012 (D_RESET_CPU0 | D_RESET_CPU1 | D_RESET_CPU2)
#define D_RESET_ALL	(D_RESET_CPU012 | 0x00000800)
#define D_HAVE_NEW_DATA_TO_READ	(0)
#define D_NO_NEW_DATA_TO_READ (1)
#if 0
#define C_TEST_ONLY_LINUX
#endif
typedef enum {
	MLB_IO_RESET_TO_OFF_LINE = 0x10,
	MLB_IO_RESET_TO_ON_LINE,
	MLB_IO_NOTIFY_RTOS,
	MLB_IO_GET_CPU_STATE,
} MLB_IO;
typedef enum {
	INDEX_SRAM_TOP = 0,
	INDEX_SRAM_REST_ADDRESS,
	INDEX_SDRAM_HOT_PLUG_INFO,
	INDEX_SDRAM_SET_CPU_REST_ADDRESS,
	IDEX_END,
} E_IDEX_DEFINE;
typedef struct {
	struct miscdevice miscdev;
	wait_queue_head_t	waitq;
	struct mutex mlock;
	int access_num;
	u32 bootstrap_address;
	u32 read_flag;
	u32 sgi_no;
#if defined(C_TEST_ONLY_LINUX)
	u32 send_sgi_no;
#endif
	void __iomem *cpu_hotplug_mem[IDEX_END];
} T_MLB_CPU_HOTPLUG_INFOR;
typedef union {
	unsigned int word;
	struct {
		unsigned int cpu_no		:4;
		unsigned int possible_status	:1;
		unsigned int present_status	:1;
		unsigned int online_status	:1;
		unsigned int active_status	:1;
		unsigned int			:24;
	} bit;
} U_MLB_CPU_STATE;
static T_MLB_CPU_HOTPLUG_INFOR *mlb_cpu_hotplug_infor_device;

/**
* Local static function declear
*/
/**
* Local static function
*/
static int set_reset_data(u32 switch_type,
		const T_MLB_CPU_HOTPLUG_INFOR *cpu_hotplug_infor_device)
{
	int i;
	u32 crrr_reg;
	u32 *sram =
		(u32 *)cpu_hotplug_infor_device->
			cpu_hotplug_mem[INDEX_SRAM_TOP];

	/*
	* Set the program code to SRAM top so that they are used to
	* execute CPU reset
	*/
	writel(0xe59ff018, sram);
	sram++;
	for (i = 1; i < 8; i++) {
		writel(0xeafffffe,
			sram);
		sram++;
	}
	/* Write SRAM 0 to set reset jump address */
	writel(cpu_hotplug_infor_device->bootstrap_address, sram);
	/* Tell bootstrap cpu2 will be used for RTOS */
	writel(switch_type,
		cpu_hotplug_infor_device->
			cpu_hotplug_mem[INDEX_SRAM_REST_ADDRESS] + 0xfc);
	/* Rest CPU */
	crrr_reg = readl(cpu_hotplug_infor_device->
			cpu_hotplug_mem[INDEX_SDRAM_SET_CPU_REST_ADDRESS]
			+ 0x90);
	crrr_reg &= ~D_RESET_CPU2;

	pr_debug("crrr_reg:%X\n", crrr_reg);
	writel(crrr_reg,
		cpu_hotplug_infor_device->
		cpu_hotplug_mem[INDEX_SDRAM_SET_CPU_REST_ADDRESS] + 0x90);

	return 0;
}
static long milb_cpu_hotplug_drv_ioctl(struct file *filp,
			       unsigned int cmd,
			       unsigned long arg)
{
	struct miscdevice *mdev = filp->private_data;
	T_MLB_CPU_HOTPLUG_INFOR *cpu_hotplug_infor_device =
			container_of(mdev, T_MLB_CPU_HOTPLUG_INFOR, miscdev);
	U_MLB_CPU_STATE cpu_status;

	pr_debug("%s %s %d,cmd:%X\n",
			__FILE__, __func__, __LINE__, cmd);
	switch (cmd) {
	case MLB_IO_RESET_TO_OFF_LINE:
		set_reset_data(D_SWITCH_CPU_OFF_LINE,
			cpu_hotplug_infor_device);
		break;
	case MLB_IO_NOTIFY_RTOS:
		gic_send_sgi(D_RTOS_CPU_ID,
			cpu_hotplug_infor_device->sgi_no);
		break;
	case MLB_IO_GET_CPU_STATE:
		cpu_status.word = 0;
		if (copy_from_user(&cpu_status, (void __user *)arg,
			sizeof(U_MLB_CPU_STATE))) {
			pr_err("Parameter error cmd:%d\n", cmd);
			 return -EFAULT;
		}
		cpu_status.bit.possible_status =
			cpu_possible(cpu_status.bit.cpu_no);
		cpu_status.bit.present_status =
			cpu_present(cpu_status.bit.cpu_no);
		cpu_status.bit.online_status =
			cpu_online(cpu_status.bit.cpu_no);
		cpu_status.bit.active_status =
			cpu_active(cpu_status.bit.cpu_no);
		if (copy_to_user((void __user *)arg, &cpu_status,
			sizeof(U_MLB_CPU_STATE))) {
			pr_err("Parameter error cmd:%d\n", cmd);
			return -EFAULT;
		}
		break;
	default:
		/* Do nothing */
		pr_err("Unkonwn cmd:%d\n", cmd);
		break;
	}

	return 0;
}

static u32 milb_cpu_hotplug_drv_poll(struct file *file, poll_table *wait)
{
	u32 mask = 0;
	struct miscdevice *mdev = file->private_data;
	T_MLB_CPU_HOTPLUG_INFOR *cpu_hotplug_infor_device =
			container_of(mdev, T_MLB_CPU_HOTPLUG_INFOR, miscdev);

	pr_debug("%s %s %d\n", __FILE__, __func__, __LINE__);
	poll_wait(file, &cpu_hotplug_infor_device->waitq, wait);
	if (!cpu_hotplug_infor_device->read_flag)
		mask |= POLLIN | POLLRDNORM;

	pr_debug("%s %s %d,mask=%08x\n",
	__FILE__, __func__, __LINE__, mask);
	return mask;

}
static ssize_t milb_cpu_hotplug_drv_read(struct file *file,
				char *buff, size_t count, loff_t *pos)
{
	struct miscdevice *mdev = file->private_data;
	T_MLB_CPU_HOTPLUG_INFOR *cpu_hotplug_infor_device =
			container_of(mdev, T_MLB_CPU_HOTPLUG_INFOR, miscdev);
	int ret = 4;
	u32 read_data;

	read_data = readl(
		cpu_hotplug_infor_device->
			cpu_hotplug_mem[INDEX_SDRAM_HOT_PLUG_INFO]);

	if (copy_to_user(buff, &read_data, sizeof(read_data)))
		ret = -EFAULT;
	else
		/* Set the data had been read flag */
		cpu_hotplug_infor_device->read_flag =
			D_NO_NEW_DATA_TO_READ;

	return ret;
}
static ssize_t milb_cpu_hotplug_drv_write(struct file *file,
		const char __user *buffer,
		size_t count, loff_t *ppos)
{
	struct miscdevice *mdev = file->private_data;
	T_MLB_CPU_HOTPLUG_INFOR *cpu_hotplug_infor_device =
			container_of(mdev, T_MLB_CPU_HOTPLUG_INFOR, miscdev);
	int ret = 4;
	u32 witer_data;
	u32 *writep =
		(u32 *)cpu_hotplug_infor_device->
			cpu_hotplug_mem[INDEX_SDRAM_HOT_PLUG_INFO];
	/**
	* cpu_hotplug_mem[INDEX_SDRAM_HOT_PLUG_INFO] + 4 is
	* the address used for notify to RTOS
	*/
	writep++;
	if (copy_from_user(&witer_data,
		buffer,  sizeof(witer_data)))
		ret = -EFAULT;
	else
		writel(witer_data, writep);

	return ret;
}
/* .open */
static int milb_cpu_hotplug_drv_open(struct inode *inode,
	struct file *file)
{
	struct miscdevice *mdev = file->private_data;
	T_MLB_CPU_HOTPLUG_INFOR *cpu_hotplug_infor_device =
			container_of(mdev, T_MLB_CPU_HOTPLUG_INFOR, miscdev);
	int ret = 0;

	mutex_lock(&cpu_hotplug_infor_device->mlock);
	if (cpu_hotplug_infor_device->access_num > 0) {
		ret = -EBUSY;
	} else {
		ret = nonseekable_open(inode, file);
		if (ret == 0)
			cpu_hotplug_infor_device->access_num++;
	}
	mutex_unlock(&cpu_hotplug_infor_device->mlock);
	/* Set the data had been read flag as initialization */
	cpu_hotplug_infor_device->read_flag = D_NO_NEW_DATA_TO_READ;
	return ret;
}

/* .release */
static int milb_cpu_hotplug_drv_release(struct inode *inode,
		struct file *file)
{
	struct miscdevice *mdev = file->private_data;
	T_MLB_CPU_HOTPLUG_INFOR *cpu_hotplug_infor_device =
			container_of(mdev, T_MLB_CPU_HOTPLUG_INFOR, miscdev);
	int ret = 0;

	mutex_lock(&cpu_hotplug_infor_device->mlock);
	if (cpu_hotplug_infor_device->access_num > 0)
		cpu_hotplug_infor_device->access_num--;
	else
		ret = -EPERM;

	mutex_unlock(&cpu_hotplug_infor_device->mlock);
	return ret;
}
void milb_cpuhot_irq_handler(u32 cpu, u32 sgi_no)
{
	if (mlb_cpu_hotplug_infor_device &&
		mlb_cpu_hotplug_infor_device->sgi_no == sgi_no) {
		/* Set the new data to be read flag */
		mlb_cpu_hotplug_infor_device->read_flag =
			D_HAVE_NEW_DATA_TO_READ;
		 wake_up_interruptible(&mlb_cpu_hotplug_infor_device->waitq);
	} else {
		pr_warn("CPU%u: Unknown IPI message 0x%x\n",
			cpu, sgi_no);
	}
}
/* The file operations for the cpu plug information */
const struct file_operations milb_cpu_hotplug_drv_fops = {
	.owner		= THIS_MODULE,
	.unlocked_ioctl = milb_cpu_hotplug_drv_ioctl,
	.open		= milb_cpu_hotplug_drv_open,
	.release	= milb_cpu_hotplug_drv_release,
	.llseek		= no_llseek,
	.read		= milb_cpu_hotplug_drv_read,
	.write		= milb_cpu_hotplug_drv_write,
	.poll		= milb_cpu_hotplug_drv_poll,
};
#if defined(C_TEST_ONLY_LINUX)
static ssize_t test_store(struct device *dev,
				struct device_attribute *attr,
				const char *buf, size_t count)
{
	u32 send_sgi_no;

	if (kstrtouint(buf, 0, &send_sgi_no) < 0)
		return -EINVAL;
	gic_send_sgi(SELF_CPU, send_sgi_no);
	mlb_cpu_hotplug_infor_device->send_sgi_no = send_sgi_no;

	return count;
}
static ssize_t test_show(struct device *dev,
			struct device_attribute *attr,
			char *buf)
{
	return sprintf(buf, "%u\n", mlb_cpu_hotplug_infor_device->send_sgi_no);
}
static DEVICE_ATTR(test, 0664, test_show, test_store);
#endif
/**
*
*/
static int milb_cpu_hotplug_probe(struct platform_device *pdev)
{
	int ret = 0;
	struct device *dev = &pdev->dev;
	struct device_node *node = dev->of_node;
	int i;

	mlb_cpu_hotplug_infor_device =
		devm_kzalloc(dev,
		sizeof(*mlb_cpu_hotplug_infor_device), GFP_KERNEL);

	if (!mlb_cpu_hotplug_infor_device) {
		ret = -ENOMEM;
		goto error;
	}
	memset(mlb_cpu_hotplug_infor_device,
		0, sizeof(*mlb_cpu_hotplug_infor_device));

	for (i = 0; i < IDEX_END; i++) {
		mlb_cpu_hotplug_infor_device->cpu_hotplug_mem[i]
			= of_iomap(node, i);
		if (!mlb_cpu_hotplug_infor_device->cpu_hotplug_mem[i]) {
			pr_err("cpu_hotplug_mem[%d] error\n", i);
			ret = -ENODEV;
			goto error;
		}
	}
	if (of_property_read_u32(node,
		"bootstrap",
		&mlb_cpu_hotplug_infor_device->bootstrap_address)) {
		pr_err("bootstrap error\n");
		ret = -ENODEV;
		goto error;
	}
	if (of_property_read_u32(node,
		"sgi_no", &mlb_cpu_hotplug_infor_device->sgi_no)) {
		pr_err("sgi_no error\n");
		ret = -ENODEV;
		goto error;
	}
	init_waitqueue_head(&mlb_cpu_hotplug_infor_device->waitq);
	mutex_init(&mlb_cpu_hotplug_infor_device->mlock);

	mlb_cpu_hotplug_infor_device->miscdev.name = DEVICE_NAME;
	mlb_cpu_hotplug_infor_device->miscdev.minor = MISC_DYNAMIC_MINOR;
	mlb_cpu_hotplug_infor_device->miscdev.fops =
		&milb_cpu_hotplug_drv_fops;
#if defined(C_TEST_ONLY_LINUX)
	if (device_create_file(&pdev->dev, &dev_attr_test) < 0) {
		pr_err("device_create_file err.\n");
		ret = -ENODEV;
		goto error;
	}
#endif
	platform_set_drvdata(pdev, mlb_cpu_hotplug_infor_device);


	return misc_register(&mlb_cpu_hotplug_infor_device->miscdev);

 error:
	return ret;
}
static int milb_cpu_hotplug_remove(struct platform_device *pdev)
{
	pr_info("Goodby...\n");
	return 0;
}
static const struct of_device_id milb_cpu_hotplug_of_match[] = {
		{.compatible = "socionext,"DEVICE_NAME },
		{}
};
MODULE_DEVICE_TABLE(of, milb_cpu_hotplug_of_match);
static struct platform_driver milb_cpu_hotplug_driver = {
	.probe = milb_cpu_hotplug_probe,
	.remove = milb_cpu_hotplug_remove,
	.driver = {
		.owner = THIS_MODULE,
		.name = DEVICE_NAME,
		.of_match_table = of_match_ptr(milb_cpu_hotplug_of_match),
	},
};
module_platform_driver(milb_cpu_hotplug_driver);
MODULE_DESCRIPTION("Milbeaut CPU hotplug driver");
MODULE_AUTHOR("sho.ritsugun <<REDACTED_EMAIL>>");
MODULE_LICENSE("GPL");


