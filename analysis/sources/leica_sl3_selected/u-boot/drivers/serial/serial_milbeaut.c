// SPDX-License-Identifier: GPL-2.0+
/*
 * Copyright (C) 2019 Socionext Inc.
 *   Author: Kazuhiro Kasai <<REDACTED_EMAIL>>
 */

#include <common.h>
#include <dm.h>
#include <linux/bug.h>
#include <linux/io.h>
#include <linux/serial_reg.h>
#include <linux/sizes.h>
#include <linux/errno.h>
#include <serial.h>
#include <fdtdec.h>

struct milbeaut_serial {
	u8 smr;			/* Serial Mode Register */
#define	SOE		BIT(0)
	u8 scr;			/* Serial Control Register */
#define	TXE		BIT(0)
#define	RXE		BIT(1)
	u8 escr;		/* Extension Serial Control Register */
	u8 status;			/* Serial Status Register */
#define	TDR		BIT(1)
#define	RDR		BIT(2)
#define	CLR		BIT(7)
	u16 rx;			/* In:  Receive buffer */
#define	tx rx			/* Out: Transmit buffer */
	u16 rate;		/* Baudrate Generator Register */
	u32 __rsv0;
	u16 fcr;		/* FIFO Control Register */
	u16 fbyte;		/* FIFO Byte Register */
} __packed;

struct milbeaut_serial_priv {
	struct milbeaut_serial __iomem *membase;
	unsigned int uartclk;
};

#define milbeaut_serial_port(dev)	\
	((struct milbeaut_serial_priv *)dev_get_priv(dev))->membase

static int milbeaut_serial_setbrg(struct udevice *dev, int baudrate)
{
	struct milbeaut_serial_priv *priv = dev_get_priv(dev);
	struct milbeaut_serial __iomem *port = milbeaut_serial_port(dev);
	unsigned int divisor;

	divisor = DIV_ROUND_CLOSEST(priv->uartclk, baudrate) - 1;

	writew(divisor, &port->rate);

	return 0;
}

static int milbeaut_serial_getc(struct udevice *dev)
{
	struct milbeaut_serial __iomem *port = milbeaut_serial_port(dev);

	if (!(readb(&port->status) & RDR))
		return -EAGAIN;

	return readw(&port->rx);
}

static int milbeaut_serial_putc(struct udevice *dev, const char c)
{
	struct milbeaut_serial __iomem *port = milbeaut_serial_port(dev);

	if (!(readb(&port->status) & TDR))
		return -EAGAIN;

	writew(c, &port->tx);

	return 0;
}

static int milbeaut_serial_pending(struct udevice *dev, bool input)
{
	struct milbeaut_serial __iomem *port = milbeaut_serial_port(dev);

	if (input)
		return readb(&port->status) & RDR;
	else
		return !(readb(&port->status) & TDR);
}

static void milbeaut_serial_init(struct udevice *dev)
{
	struct milbeaut_serial __iomem *port = milbeaut_serial_port(dev);

	/* Clear status register */
	writeb(CLR, &port->status);

	/* Enable trnasmit and recieve */
	writeb(TXE | RXE, &port->scr);

	/* Enable serial port */
	writeb(SOE, &port->smr);
}

/*
 * SPL does not have enough memory footprint for the clock driver.
 * Hardcode clock frequency for each SoC.
 */
struct milbeaut_serial_clk_data {
	const char *compatible;
	unsigned int clk_rate;
};

static const struct milbeaut_serial_clk_data milbeaut_serial_clk_data[] = {
	{ .compatible = "socionext,milbeaut-sc2006a", .clk_rate = 150000000 },
	{ .compatible = "socionext,milbeaut-sc2006b", .clk_rate = 200000000 },
	{ /* sentinel */ },
};

static int milbeaut_serial_probe(struct udevice *dev)
{
	struct milbeaut_serial_priv *priv = dev_get_priv(dev);
	struct milbeaut_serial __iomem *port;
	const struct milbeaut_serial_clk_data *clk_data;
	ofnode root_node;
	fdt_addr_t base;

	base = devfdt_get_addr(dev);
	if (base == FDT_ADDR_T_NONE)
		return -EINVAL;

	port = devm_ioremap(dev, base, SZ_16);
	if (!port)
		return -ENOMEM;

	priv->membase = port;

	root_node = ofnode_path("/");
	clk_data = milbeaut_serial_clk_data;
	while (clk_data->compatible) {
		if (ofnode_device_is_compatible(root_node,
						clk_data->compatible))
			break;
		clk_data++;
	}

	if (WARN_ON(!clk_data->compatible))
		return -ENOTSUPP;

	priv->uartclk = clk_data->clk_rate;

	milbeaut_serial_init(dev);

	return 0;
}

static const struct udevice_id milbeaut_uart_of_match[] = {
	{ .compatible = "socionext,milbeaut-uart" },
	{ /* sentinel */ }
};

static const struct dm_serial_ops milbeaut_serial_ops = {
	.setbrg = milbeaut_serial_setbrg,
	.getc = milbeaut_serial_getc,
	.putc = milbeaut_serial_putc,
	.pending = milbeaut_serial_pending,
};

U_BOOT_DRIVER(milbeaut_serial) = {
	.name = "milbeaut-uart",
	.id = UCLASS_SERIAL,
	.of_match = milbeaut_uart_of_match,
	.probe = milbeaut_serial_probe,
	.priv_auto_alloc_size = sizeof(struct milbeaut_serial_priv),
	.ops = &milbeaut_serial_ops,
};
