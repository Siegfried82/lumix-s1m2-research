// SPDX-License-Identifier: GPL-2.0
/*
 * copyright (C) 2020 Socionext Inc.
 *               Takao Orito <<REDACTED_EMAIL>>
 */

#include <linux/bitfield.h>
#include <linux/delay.h>
#include <linux/io.h>
#include <linux/module.h>
#include <linux/slab.h>

#include <linux/init.h>
#include <linux/types.h>
#include <linux/kernel.h>
#include <linux/fs.h>
#include <linux/cdev.h>
#include <linux/sched.h>
#include <linux/device.h>
#include <linux/i2c.h>
#include <linux/workqueue.h>
#include <asm/uaccess.h>

#define DEVICE_NAME	"ptn515a"

#define DBG(f, x...) \
	pr_debug(DEVICE_NAME "[%s()]:--- " f, __func__, ## x)

#define CC_STAT_NOCABLE	0
#define CC_STAT_CC1		1
#define CC_STAT_CC2		2

#define PTN5150A_ID		0x1

#define PTN5150A_CCSTATUS	0x4
#define PTN5150A_CCSTATUS_POL_MASK	GENMASK(1,0)
#define PTN5150A_CCSTATUS_POL_CC1	1
#define PTN5150A_CCSTATUS_POL_CC2	2

#define PTN5150A_INTSTATUS	0x19
#define PTN5150A_INTSTATUS_ORI_FOUND	BIT(2)

#define POLLING_VBUS_PERIOD	500
#define POLLING_CC_PERIOD	50

static atomic_t run = ATOMIC_INIT(1);

static struct i2c_device_id cclogic_i2c_idtable[] = {
	{"cclogic_dev", 0},
	{}
};
MODULE_DEVICE_TABLE(i2c, cclogic_i2c_idtable);

struct mil_cclogic {
	struct i2c_client *client;
	const struct i2c_device_id *id;
	char devname[12];
	spinlock_t lock;
	u32	stat;
	struct workqueue_struct *wq;
	struct delayed_work detect;
};


static void sn_exs_detect(struct work_struct *work)
{
	struct mil_cclogic *dev_data = container_of(work, struct mil_cclogic, detect.work);
	struct i2c_client *client = dev_data->client;
	char uchger_state[50] = { 0 };
	char *envp[] = { uchger_state, NULL };
	unsigned long flags;
	int ret;

	DBG("start\n");

	while (atomic_read(&run)) {
		ret = i2c_smbus_read_byte_data(client, PTN5150A_INTSTATUS);
		if (ret < 0) {
			/* VBUS is not connected */
			msleep(POLLING_VBUS_PERIOD);
			continue;
		} else if (ret == 0) {
			/* VBUS is not connected */
			msleep(POLLING_VBUS_PERIOD);
			continue;
		} else if ((ret & PTN5150A_INTSTATUS_ORI_FOUND) == 0){
			/* wait detection of orientation */
			msleep(POLLING_CC_PERIOD);
			continue;
		} else {
			DBG("i2c[%d]: : read = 0x%02x\n", __LINE__, ret);
		}

		ret = i2c_smbus_read_byte_data(client, PTN5150A_CCSTATUS);
		if ((ret & PTN5150A_CCSTATUS_POL_MASK) == PTN5150A_CCSTATUS_POL_CC1) {
			DBG(": CC1 id detected\n");
			spin_lock_irqsave(&dev_data->lock, flags);
			snprintf(uchger_state, ARRAY_SIZE(uchger_state),
				"UDC_VBUS=%s", "CC1_PRESENT");
			dev_data->stat = CC_STAT_CC1;
			kobject_uevent_env(&client->dev.kobj, KOBJ_CHANGE, envp);
			spin_unlock_irqrestore(&dev_data->lock, flags);
		} else if ((ret & PTN5150A_CCSTATUS_POL_MASK) == PTN5150A_CCSTATUS_POL_CC2) {
			DBG(": CC2 is detected\n");
			spin_lock_irqsave(&dev_data->lock, flags);
			snprintf(uchger_state, ARRAY_SIZE(uchger_state),
				"UDC_VBUS=%s", "CC2_PRESENT");
			dev_data->stat = CC_STAT_CC2;
			kobject_uevent_env(&client->dev.kobj, KOBJ_CHANGE, envp);
			spin_unlock_irqrestore(&dev_data->lock, flags);
		} else
			pr_err(DEVICE_NAME ": other(0x%02x) is detected\n", ret);
	}
}

static const struct of_device_id cclogic_of_match[] = {
	{
		.compatible = "sni,usbcclogic",
	},
	{},
};
MODULE_DEVICE_TABLE(of, cclogic_of_match);

static int cclogic_probe(struct i2c_client *client, const struct i2c_device_id *id)
{
	struct mil_cclogic *dev_data;
	int reg;
	unsigned long onesec;
	char uchger_state[50] = { 0 };
	char *envp[] = { uchger_state, NULL };
	unsigned long flags;

	DBG("start\n");

	dev_data = kzalloc(sizeof(struct mil_cclogic), GFP_KERNEL);
	if (!dev_data)
		return -ENOMEM;

	spin_lock_init(&dev_data->lock);
	memcpy(dev_data->devname, DEVICE_NAME, sizeof(DEVICE_NAME));

	dev_data->client = client;
	dev_data->id = id;

	reg = i2c_smbus_read_byte_data(client, PTN5150A_ID);
	if (reg >= 0) {
		pr_info(DEVICE_NAME "ID=0x%02x\n", reg);

		reg = i2c_smbus_read_byte_data(client, PTN5150A_CCSTATUS);
		if ((reg & PTN5150A_CCSTATUS_POL_MASK) == PTN5150A_CCSTATUS_POL_CC1) {
			DBG(": CC1 id detected\n");
			spin_lock_irqsave(&dev_data->lock, flags);
			snprintf(uchger_state, ARRAY_SIZE(uchger_state),
				"UDC_VBUS=%s", "CC1_PRESENT");
			dev_data->stat = CC_STAT_CC1;
			kobject_uevent_env(&client->dev.kobj, KOBJ_CHANGE, envp);
			spin_unlock_irqrestore(&dev_data->lock, flags);
		} else if ((reg & PTN5150A_CCSTATUS_POL_MASK) == PTN5150A_CCSTATUS_POL_CC2) {
			DBG(": CC2 is detected\n");
			spin_lock_irqsave(&dev_data->lock, flags);
			snprintf(uchger_state, ARRAY_SIZE(uchger_state),
				"UDC_VBUS=%s", "CC2_PRESENT");
			dev_data->stat = CC_STAT_CC2;
			kobject_uevent_env(&client->dev.kobj, KOBJ_CHANGE, envp);
			spin_unlock_irqrestore(&dev_data->lock, flags);
		}
	} else
		DBG(": Cable is not connected\n");

	i2c_set_clientdata(client, dev_data);

	atomic_set(&run, 1);

	onesec = msecs_to_jiffies(500);
	INIT_DELAYED_WORK(&dev_data->detect, sn_exs_detect);
	if (!dev_data->wq)
		dev_data->wq = create_singlethread_workqueue("cclogic");
	if(dev_data->wq)
		queue_delayed_work(dev_data->wq, &dev_data->detect, onesec);

	return 0;
}

static int cclogic_remove(struct i2c_client *client)
{
	struct mil_cclogic *dev_data = i2c_get_clientdata(client);

	DBG("runs\n");

	atomic_set(&run, 0);
	cancel_work_sync(&dev_data->detect.work);
	destroy_workqueue(dev_data->wq);

	return 0;
}

static struct i2c_driver cclogic_driver = {
	.driver = {
		.name = "milbeaut-cclogic",
		.owner = THIS_MODULE,
		.of_match_table = cclogic_of_match,
	},
	.id_table = cclogic_i2c_idtable,
	.probe = cclogic_probe,
	.remove = cclogic_remove,
};

static int cclogic_init(void)
{
	DBG("runs\n");
	i2c_add_driver(&cclogic_driver);
	return 0;
}

static void cclogic_exit(void)
{
	DBG("%s runs\n", __func__);
	i2c_del_driver(&cclogic_driver);
}

module_init(cclogic_init);
module_exit(cclogic_exit);

MODULE_DESCRIPTION("MILBEAUT cclogic controller driver");
MODULE_AUTHOR("Takao Orito <<REDACTED_EMAIL>>");
MODULE_LICENSE("GPL v2");
