// SPDX-License-Identifier: GPL-2.0
/*
 * M20V I2C driver
 *
 * Copyright (C) 2019 Socionext Inc.
 */

#include <linux/bitfield.h>
#include <linux/bits.h>
#include <linux/clk.h>
#include <linux/i2c.h>
#include <linux/interrupt.h>
#include <linux/io.h>
#include <linux/module.h>
#include <linux/platform_device.h>

/* register offset */
#define M20V_I2C_CR			0x0
#define M20V_I2C_SR			0x4
#define M20V_I2C_AR			0x8
#define M20V_I2C_DR			0xC
#define M20V_I2C_ISR		0x10
#define M20V_I2C_TSR		0x14
#define M20V_I2C_SMPR		0x18
#define M20V_I2C_TOR		0x1C
#define M20V_I2C_IMR		0x20
#define M20V_I2C_IER		0x24
#define M20V_I2C_IDR		0x28
#define M20V_I2C_SDAIDR		0x30
#define M20V_I2C_SDAODR		0x34

/* CR bit fields */
#define M20V_I2C_DEV_B		GENMASK(13, 8)
#define M20V_I2C_CLRFIFO	BIT(6)
#define M20V_I2C_ACKEN		BIT(3)
#define M20V_I2C_NEA		BIT(2)
#define M20V_I2C_MS			BIT(1)
#define M20V_I2C_RW			BIT(0)

/* ISR bit fields */
#define M20V_I2C_ARBLOST	BIT(9)
#define M20V_I2C_RXUNF		BIT(7)
#define M20V_I2C_TXOVF		BIT(6)
#define M20V_I2C_RXOVF		BIT(5)
#define M20V_I2C_SLVRDY		BIT(4)
#define M20V_I2C_TO			BIT(3)
#define M20V_I2C_NACK		BIT(2)
#define M20V_I2C_DATA		BIT(1)
#define M20V_I2C_COMP		BIT(0)
#define M20V_I2C_ISR_ALL	(M20V_I2C_ARBLOST | \
					M20V_I2C_RXUNF | \
					M20V_I2C_TXOVF | \
					M20V_I2C_RXOVF | \
					M20V_I2C_SLVRDY | \
					M20V_I2C_TO | \
					M20V_I2C_NACK | \
					M20V_I2C_DATA | \
					M20V_I2C_COMP)

#define M20V_I2C_CLK_CAL_COEFFICIENT	22
#define M20V_I2C_TIMEOUT_MSEC			10000
#define M20V_FIFOSIZE			16
#define M20V_TSR_MAX			31

struct m20v_i2c {
	struct clk *clk;
	struct i2c_adapter adapter;
	struct i2c_msg *msg;
	struct completion completion;
	unsigned long clkrate;
	unsigned int speed;
	unsigned int rwflg;
	unsigned int intr_status;
	unsigned int count_len;
	int irq;
	int ret;
	int done_num;
	unsigned char normal_addr_mode;
	unsigned char msg_comp;
	void __iomem *base;
};

static irqreturn_t m20v_i2c_isr(int irq, void *data)
{
	struct m20v_i2c *i2c = data;

	i2c->intr_status = readw_relaxed(i2c->base + M20V_I2C_ISR);
	i2c->ret = -EPERM;

	if (i2c->intr_status & M20V_I2C_ARBLOST) {
		/* arbitration lost */
		writew_relaxed(M20V_I2C_ARBLOST, i2c->base + M20V_I2C_ISR);
		i2c->ret = -EAGAIN;
	}
	if (i2c->intr_status & M20V_I2C_RXUNF) {
		/* receive fifo underflow */
		writew_relaxed(M20V_I2C_RXUNF, i2c->base + M20V_I2C_ISR);
		i2c->ret = -EIO;
	}
	if (i2c->intr_status & M20V_I2C_TXOVF) {
		/* send fifo overflow */
		writew_relaxed(M20V_I2C_TXOVF, i2c->base + M20V_I2C_ISR);
		i2c->ret = -EIO;
	}
	if (i2c->intr_status & M20V_I2C_RXOVF) {
		/* receive fifo overflow */
		writew_relaxed(M20V_I2C_RXOVF, i2c->base + M20V_I2C_ISR);
		i2c->ret = -EIO;
	}
	if (i2c->intr_status & M20V_I2C_SLVRDY) {
		/* monitored slave ready */
		writew_relaxed(M20V_I2C_SLVRDY, i2c->base + M20V_I2C_ISR);
		i2c->ret = 0;
	}
	if (i2c->intr_status & M20V_I2C_TO) {
		/* transfer time out */
		writew_relaxed(M20V_I2C_TO, i2c->base + M20V_I2C_ISR);
		i2c->ret = -EAGAIN;
	}
	if (i2c->intr_status & M20V_I2C_NACK) {
		/* transfer not acknowledged */
		writew_relaxed(M20V_I2C_NACK, i2c->base + M20V_I2C_ISR);
		i2c->ret = -EIO;
	}
	if (i2c->intr_status & M20V_I2C_DATA) {
		/* more data */
		writew_relaxed(M20V_I2C_DATA, i2c->base + M20V_I2C_ISR);
		i2c->ret = 0;
	}
	if (i2c->intr_status & M20V_I2C_COMP) {
		/* transfer complete */
		writew_relaxed(M20V_I2C_COMP, i2c->base + M20V_I2C_ISR);
		i2c->ret = 0;
	}
	if(i2c->ret)
		writew_relaxed(M20V_I2C_CLRFIFO, i2c->base + M20V_I2C_CR);

	complete(&i2c->completion);

	return IRQ_HANDLED;
}

static void m20v_i2c_master_init(struct m20v_i2c *i2c)
{
	unsigned int div_b;

	i2c->rwflg = i2c->msg->flags & I2C_M_RD;
	if (i2c->msg->flags & I2C_M_TEN)
		i2c->normal_addr_mode = 0;
	else
		i2c->normal_addr_mode = 1;

	/* set control */
	div_b = (i2c->clkrate/(M20V_I2C_CLK_CAL_COEFFICIENT * i2c->speed)) - 1;
	writew_relaxed(FIELD_PREP(M20V_I2C_DEV_B, div_b) |
			M20V_I2C_ACKEN |
			FIELD_PREP(M20V_I2C_NEA, i2c->normal_addr_mode) |
			M20V_I2C_MS | i2c->rwflg, i2c->base + M20V_I2C_CR);

	/* clear interrupt status */
	writew_relaxed(M20V_I2C_ISR_ALL, i2c->base + M20V_I2C_ISR);
	/* set interrupt all enable */
	writew_relaxed(M20V_I2C_ISR_ALL, i2c->base + M20V_I2C_IER);
	/* other than more data interrupt */
	writew_relaxed(M20V_I2C_DATA, i2c->base + M20V_I2C_IDR);

	i2c->msg_comp = 0;
	i2c->count_len = 0;

	reinit_completion(&i2c->completion);
}

static int m20v_i2c_xfer_write(struct m20v_i2c *i2c)
{
	unsigned long timeout;

	writew_relaxed(i2c->msg->buf[i2c->count_len], i2c->base + M20V_I2C_DR);
	i2c->count_len++;
	writew_relaxed(i2c->msg->addr, i2c->base + M20V_I2C_AR);

	while (i2c->count_len < i2c->msg->len) {
		writew_relaxed(i2c->msg->buf[i2c->count_len],
			       i2c->base + M20V_I2C_DR);
		i2c->count_len++;
		if (readw_relaxed(i2c->base + M20V_I2C_TSR) >= M20V_FIFOSIZE) {
			writew_relaxed(M20V_I2C_DATA, i2c->base + M20V_I2C_ISR);
			writew_relaxed(M20V_I2C_DATA, i2c->base + M20V_I2C_IER);
			timeout = wait_for_completion_timeout(&i2c->completion,
					msecs_to_jiffies(M20V_I2C_TIMEOUT_MSEC));
			if (timeout == 0)
				return -EAGAIN;
			reinit_completion(&i2c->completion);
		}
	}
	writew_relaxed(M20V_I2C_DATA, i2c->base + M20V_I2C_IDR);

	timeout = wait_for_completion_timeout(&i2c->completion,
					msecs_to_jiffies(M20V_I2C_TIMEOUT_MSEC));
	if (timeout == 0)
		return -EAGAIN;

	if (i2c->count_len >= i2c->msg->len) {
		i2c->msg_comp = 1;
	}
	else {
		writew_relaxed(M20V_I2C_ISR_ALL, i2c->base + M20V_I2C_IER);
		reinit_completion(&i2c->completion);
	}

	return i2c->ret;
}

static int m20v_i2c_xfer_read(struct m20v_i2c *i2c)
{
	unsigned long timeout;
	uint16_t readremain;

	writew_relaxed(i2c->msg->addr, i2c->base + M20V_I2C_AR);
	if ((i2c->msg->len - i2c->count_len) > M20V_TSR_MAX)
		readremain = M20V_TSR_MAX;
	else
		readremain = i2c->msg->len - i2c->count_len;
	writew_relaxed(readremain, i2c->base + M20V_I2C_TSR);

	writew_relaxed(M20V_I2C_DATA, i2c->base + M20V_I2C_ISR);
	writew_relaxed(M20V_I2C_DATA, i2c->base + M20V_I2C_IER);
	timeout = wait_for_completion_timeout(&i2c->completion,
				msecs_to_jiffies(M20V_I2C_TIMEOUT_MSEC));
	if (timeout == 0)
		return -EAGAIN;
	reinit_completion(&i2c->completion);

	while (readremain) {
		*(i2c->msg->buf + i2c->count_len) =
			readw_relaxed(i2c->base + M20V_I2C_DR);
		i2c->count_len++;
		readremain--;

		if (i2c->count_len >= i2c->msg->len) {
			i2c->msg_comp = 1;
			return i2c->ret;
		}
		if (readremain == readw_relaxed(i2c->base + M20V_I2C_TSR)) {
			if (!readremain)
				break;
			timeout = wait_for_completion_timeout(&i2c->completion,
				msecs_to_jiffies(M20V_I2C_TIMEOUT_MSEC));
			if (timeout == 0)
				return -EAGAIN;
			reinit_completion(&i2c->completion);
		}

	}

	reinit_completion(&i2c->completion);

	return i2c->ret;
}

static int m20v_i2c_xfer(struct i2c_adapter *adap,
				struct i2c_msg *msgs, int num)
{
	struct m20v_i2c *i2c = i2c_get_adapdata(adap);
	int ret;

	i2c->msg = msgs;

	while (1) {
		m20v_i2c_master_init(i2c);

		while (!i2c->msg_comp) {
			if (i2c->rwflg) {
				ret = m20v_i2c_xfer_read(i2c);
			} else {
				ret = m20v_i2c_xfer_write(i2c);
			}
			if (ret)
				break;
		}
		if (ret) {
			i2c->done_num = 0;
			break;
		} else {
			ret = i2c->done_num++;
			if (i2c->done_num >= num){
				ret = i2c->done_num;
				i2c->done_num = 0;
				break;
			}
			else{
				i2c->msg++; /* next message */
			}
		}
	}
	writew_relaxed(M20V_I2C_ISR_ALL, i2c->base + M20V_I2C_IDR);
	return ret;
}

static u32 m20v_i2c_functionality(struct i2c_adapter *adap)
{
	return I2C_FUNC_I2C | I2C_FUNC_10BIT_ADDR | I2C_FUNC_SMBUS_EMUL;
}

static const struct i2c_algorithm m20v_i2c_algo = {
	.master_xfer   = m20v_i2c_xfer,
	.functionality = m20v_i2c_functionality,
};

static struct i2c_adapter m20v_i2c_adapter_ops = {
	.owner		= THIS_MODULE,
	.name		= "m20v-i2c-adapter",
	.algo		= &m20v_i2c_algo,
	.retries	= 1,
};

static int m20v_i2c_probe(struct platform_device *pdev)
{
	struct resource *res;
	struct m20v_i2c *i2c;
	int ret = 0;

	i2c = devm_kzalloc(&pdev->dev, sizeof(*i2c), GFP_KERNEL);
	if (!i2c)
		return -ENOMEM;

	if (of_property_read_u32(pdev->dev.of_node,
			"clock-frequency", &i2c->speed))
		i2c->speed = 100000; /* 100KHz */

	i2c->clk = devm_clk_get(&pdev->dev, NULL);
	if (IS_ERR(i2c->clk)) {
		dev_err(&pdev->dev, "input clock not found.\n");
		return PTR_ERR(i2c->clk);
	}
	i2c->clkrate = clk_get_rate(i2c->clk);
	ret = clk_prepare_enable(i2c->clk);
	if (ret)
		dev_err(&pdev->dev, "Unable to enable clock.\n");

	res = platform_get_resource(pdev, IORESOURCE_MEM, 0);
	i2c->base = devm_ioremap_resource(&pdev->dev, res);
	if (IS_ERR(i2c->base))
		return PTR_ERR(i2c->base);

	i2c->irq = platform_get_irq(pdev, 0);
	if (i2c->irq < 0) {
		ret = i2c->irq;
		goto err_irq;
	}
	ret = devm_request_irq(&pdev->dev, i2c->irq,
				m20v_i2c_isr, 0,
				dev_name(&pdev->dev), i2c);
	if (ret)
		goto err_irq;

	init_completion(&i2c->completion);
	i2c->adapter = m20v_i2c_adapter_ops;
	i2c->adapter.dev.parent = &pdev->dev;
	i2c->adapter.dev.of_node = of_node_get(pdev->dev.of_node);
	i2c->adapter.nr = pdev->id;
	i2c_set_adapdata(&i2c->adapter, i2c);
	ret = i2c_add_numbered_adapter(&i2c->adapter);
	if (ret < 0)
		goto err_adapter;

	platform_set_drvdata(pdev, i2c);

	return 0;

err_irq:
err_adapter:
	clk_disable_unprepare(i2c->clk);
	return ret;
}

static int m20v_i2c_remove(struct platform_device *pdev)
{
	struct m20v_i2c *i2c = platform_get_drvdata(pdev);

	i2c_del_adapter(&i2c->adapter);
	clk_disable_unprepare(i2c->clk);

	return 0;
};

static int m20v_i2c_suspend(struct device *dev)
{
	struct m20v_i2c *i2c = dev_get_drvdata(dev);

	clk_disable_unprepare(i2c->clk);

	return 0;
}

static int m20v_i2c_resume(struct device *dev)
{
	struct m20v_i2c *i2c = dev_get_drvdata(dev);
	int ret;

	ret = clk_prepare_enable(i2c->clk);

	return ret;
}

static const struct dev_pm_ops m20v_i2c_pm = {
	SET_SYSTEM_SLEEP_PM_OPS(m20v_i2c_suspend, m20v_i2c_resume)
};

static const struct of_device_id m20v_i2c_dt_ids[] = {
	{ .compatible = "socionext,m20v-i2c", },
	{ .compatible = "socionext,karine-i2c", },
	{ },
};

MODULE_DEVICE_TABLE(of, m20v_i2c_dt_ids);

static struct platform_driver m20v_i2c_driver = {
	.probe   = m20v_i2c_probe,
	.remove  = m20v_i2c_remove,
	.driver  = {
		.name = "i2c-m20v",
		.of_match_table = m20v_i2c_dt_ids,
		.pm = &m20v_i2c_pm,
	},
};

module_platform_driver(m20v_i2c_driver);

MODULE_AUTHOR("Shinji Kanematsu <<REDACTED_EMAIL>>");
MODULE_DESCRIPTION("M20V I2C");
MODULE_LICENSE("GPL v2");
