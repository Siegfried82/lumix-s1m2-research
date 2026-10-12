// SPDX-License-Identifier: GPL-2.0
/*
 * Copyright (C) 2018 Socionext Inc.
 */

#if defined(CONFIG_SERIAL_MILBEAUT_USIO_CONSOLE) && defined(CONFIG_MAGIC_SYSRQ)
#define SUPPORT_SYSRQ
#endif

#include <linux/clk.h>
#include <linux/console.h>
#include <linux/dma-direction.h>
#include <linux/dmaengine.h>
#include <linux/dma-mapping.h>
#include <linux/module.h>
#include <linux/of_irq.h>
#include <linux/of_device.h>
#include <linux/platform_device.h>
#include <linux/psci.h>
#include <linux/serial_core.h>
#include <linux/sni_psci.h>
#include <linux/tty.h>
#include <linux/tty_flip.h>

#define USIO_NAME		"mlb-usio-uart"
#define USIO_UART_DEV_NAME	"ttyUSI"

struct t_mlb_port {
	struct uart_port *port;
	struct dma_chan *rx_ch;  /* dma rx channel            */
	dma_addr_t rx_dma_buf;   /* dma rx buffer bus address */
	unsigned char *rx_buf;   /* dma rx buffer cpu address */
	unsigned short r_siz;	 /* dma rx current trans size */
	struct dma_chan *tx_ch;  /* dma tx channel            */
	dma_addr_t tx_dma_buf;   /* dma tx buffer bus address */
	unsigned char *tx_buf;   /* dma tx buffer cpu address */
	bool tx_dma_busy;        /* dma tx busy               */
};

static struct uart_port mlb_usio_ports[CONFIG_SERIAL_MILBEAUT_USIO_PORTS];
static struct t_mlb_port mlb_ports[CONFIG_SERIAL_MILBEAUT_USIO_PORTS];
static void mlb_usio_console_putchar(struct uart_port *port, int c);
static void (*ram_onoff)(int idx, bool b);
#define PERI_COMMON_KARINE		0xe006000

#define RX	0
#define TX	1
static int mlb_usio_irq[CONFIG_SERIAL_MILBEAUT_USIO_PORTS][2];
#define MLB_USIO_REG_SMR		0
#define MLB_USIO_REG_SCR		1
#define MLB_USIO_REG_ESCR		2
#define MLB_USIO_REG_SSR		3
#define MLB_USIO_REG_DR			4
#define MLB_USIO_REG_BGR		6
#define MLB_USIO_REG_FCR		12
#define MLB_USIO_REG_FBYTE		14

#define MLB_USIO_SMR_SOE		BIT(0)
#define MLB_USIO_SMR_SBL		BIT(3)
#define MLB_USIO_SCR_TXE		BIT(0)
#define MLB_USIO_SCR_RXE		BIT(1)
#define MLB_USIO_SCR_TBIE		BIT(2)
#define MLB_USIO_SCR_TIE		BIT(3)
#define MLB_USIO_SCR_RIE		BIT(4)
#define MLB_USIO_SCR_UPCL		BIT(7)
#define MLB_USIO_ESCR_L_8BIT		0
#define MLB_USIO_ESCR_L_5BIT		1
#define MLB_USIO_ESCR_L_6BIT		2
#define MLB_USIO_ESCR_L_7BIT		3
#define MLB_USIO_ESCR_P			BIT(3)
#define MLB_USIO_ESCR_PEN		BIT(4)
#define MLB_USIO_ESCR_FLWEN		BIT(7)
#define MLB_USIO_SSR_TBI		BIT(0)
#define MLB_USIO_SSR_TDRE		BIT(1)
#define MLB_USIO_SSR_RDRF		BIT(2)
#define MLB_USIO_SSR_ORE		BIT(3)
#define MLB_USIO_SSR_FRE		BIT(4)
#define MLB_USIO_SSR_PE			BIT(5)
#define MLB_USIO_SSR_REC		BIT(7)
#define MLB_USIO_SSR_BRK		BIT(8)
#define MLB_USIO_FCR_FE1		BIT(0)
#define MLB_USIO_FCR_FE2		BIT(1)
#define MLB_USIO_FCR_FCL1		BIT(2)
#define MLB_USIO_FCR_FCL2		BIT(3)
#define MLB_USIO_FCR_FSET		BIT(4)
#define MLB_USIO_FCR_FTIE		BIT(9)
#define MLB_USIO_FCR_FDRQ		BIT(10)
#define MLB_USIO_FCR_FRIIE		BIT(11)

#define TX_BUF				4096
#define RX_BUF				256
static struct uart_pm_regs {
	unsigned char smr, scr, escr;
	unsigned short bgr, fcr, fbyte;
} uart_pm_regs[CONFIG_SERIAL_MILBEAUT_USIO_PORTS];

static void mlb_usio_tx_chars(struct uart_port *port);

static void mlb_usio_stop_tx(struct uart_port *port)
{
	struct t_mlb_port *mlbport = &mlb_ports[port->line];
	unsigned short sval;
	unsigned char bval;

	if (!mlbport->tx_ch) {
		sval = readw(port->membase + MLB_USIO_REG_FCR);
		sval &= ~MLB_USIO_FCR_FTIE;
		writew(sval, port->membase + MLB_USIO_REG_FCR);
		bval = readb(port->membase + MLB_USIO_REG_SCR);
		bval &= ~MLB_USIO_SCR_TBIE;
		writeb(bval, port->membase + MLB_USIO_REG_SCR);
	}
}

static void mlb_tx_dma_complete(void *arg)
{
	struct uart_port *port = arg;
	struct t_mlb_port *mlbport = &mlb_ports[port->line];

	mlbport->tx_dma_busy = false;

	/* Let's see if we have pending data to send */
	mlb_usio_tx_chars(port);
}

static void mlb_transmit_chars_dma(struct uart_port *port)
{
	struct t_mlb_port *mlbport = &mlb_ports[port->line];
	struct circ_buf *xmit = &port->state->xmit;
	struct dma_async_tx_descriptor *desc = NULL;
	dma_cookie_t cookie;
	unsigned int count;

	if (mlbport->tx_dma_busy)
		return;

	mlbport->tx_dma_busy = true;

	count = uart_circ_chars_pending(xmit);

	if (xmit->tail < xmit->head) {
		memcpy(&mlbport->tx_buf[0], &xmit->buf[xmit->tail], count);
	} else {
		size_t one = UART_XMIT_SIZE - xmit->tail;
		size_t two;

		if (one > count)
			one = count;
		two = count - one;

		memcpy(&mlbport->tx_buf[0], &xmit->buf[xmit->tail], one);
		if (two)
			memcpy(&mlbport->tx_buf[one], &xmit->buf[0], two);
	}

	desc = dmaengine_prep_slave_single(mlbport->tx_ch,
					   mlbport->tx_dma_buf,
					   count,
					   DMA_MEM_TO_DEV,
					   DMA_PREP_INTERRUPT);

	if (!desc) {
		dev_err(port->dev, "uart hdmac error\n");
		return;
	}

	desc->callback = mlb_tx_dma_complete;
	desc->callback_param = port;

	/* Push current DMA TX transaction in the pending queue */
	cookie = dmaengine_submit(desc);

	/* Issue pending DMA TX requests */
	dma_async_issue_pending(mlbport->tx_ch);

	xmit->tail = (xmit->tail + count) & (UART_XMIT_SIZE - 1);
	port->icount.tx += count;
}

static void mlb_usio_tx_chars(struct uart_port *port)
{
	struct circ_buf *xmit = &port->state->xmit;
	struct t_mlb_port *mlb_port = &mlb_ports[port->line];
	int count;
	unsigned short sval;
	unsigned char bval;

	if (!mlb_port->tx_ch) {
		sval = readw(port->membase + MLB_USIO_REG_FCR);
		sval &= ~MLB_USIO_FCR_FTIE;
		writew(sval, port->membase + MLB_USIO_REG_FCR);
	}
	writeb(readb(port->membase + MLB_USIO_REG_SCR) &
	       ~(MLB_USIO_SCR_TIE | MLB_USIO_SCR_TBIE),
	       port->membase + MLB_USIO_REG_SCR);

	if (port->x_char) {
		writew(port->x_char, port->membase + MLB_USIO_REG_DR);
		port->icount.tx++;
		port->x_char = 0;
		return;
	}
	if (uart_circ_empty(xmit) || uart_tx_stopped(port)) {
		mlb_usio_stop_tx(port);
		return;
	}

	if (mlb_port->tx_ch)
		mlb_transmit_chars_dma(port);
	else{
		count = port->fifosize -
			(readw(port->membase + MLB_USIO_REG_FBYTE) & 0xff);

		do {
			writew(xmit->buf[xmit->tail],
			       port->membase + MLB_USIO_REG_DR);

			xmit->tail = (xmit->tail + 1) & (UART_XMIT_SIZE - 1);
			port->icount.tx++;
			if (uart_circ_empty(xmit))
				break;

		} while (--count > 0);

		sval = readw(port->membase + MLB_USIO_REG_FCR);
		sval &= ~MLB_USIO_FCR_FDRQ;
		writew(sval, port->membase + MLB_USIO_REG_FCR);
		bval = readb(port->membase + MLB_USIO_REG_SCR);
		bval |= MLB_USIO_SCR_TBIE;
		writeb(bval, port->membase + MLB_USIO_REG_SCR);
	}

	if (uart_circ_chars_pending(xmit) < WAKEUP_CHARS)
		uart_write_wakeup(port);

	if (uart_circ_empty(xmit))
		mlb_usio_stop_tx(port);
}

static void mlb_usio_start_tx(struct uart_port *port)
{
	struct t_mlb_port *mlb_port = &mlb_ports[port->line];
	u16 fcr = readw(port->membase + MLB_USIO_REG_FCR);

	writew(fcr | MLB_USIO_FCR_FTIE, port->membase + MLB_USIO_REG_FCR);
	if (!(fcr & MLB_USIO_FCR_FDRQ))
		return;

	writeb(readb(port->membase + MLB_USIO_REG_SCR) | MLB_USIO_SCR_TBIE,
	       port->membase + MLB_USIO_REG_SCR);

	if ((readb(port->membase + MLB_USIO_REG_SSR) & MLB_USIO_SSR_TBI)
	    || (mlb_port->tx_ch))
		mlb_usio_tx_chars(port);
}

static void mlb_usio_stop_rx(struct uart_port *port)
{
	writeb(readb(port->membase + MLB_USIO_REG_SCR) & ~MLB_USIO_SCR_RIE,
	       port->membase + MLB_USIO_REG_SCR);
}

static void mlb_usio_enable_ms(struct uart_port *port)
{
	writeb(readb(port->membase + MLB_USIO_REG_SCR) |
	       MLB_USIO_SCR_RIE | MLB_USIO_SCR_RXE,
	       port->membase + MLB_USIO_REG_SCR);
}

static void mlb_usio_rx_chars(struct uart_port *port)
{
	struct tty_port *ttyport = &port->state->port;
	unsigned long flag = 0;
	char ch = 0;
	u8 status;
	int max_count = 2;

	while (max_count--) {
		status = readb(port->membase + MLB_USIO_REG_SSR);

		if (!(status & MLB_USIO_SSR_RDRF))
			break;

		if (!(status & (MLB_USIO_SSR_ORE | MLB_USIO_SSR_FRE |
				MLB_USIO_SSR_PE))) {
			ch = readw(port->membase + MLB_USIO_REG_DR);
			flag = TTY_NORMAL;
			port->icount.rx++;
			if (uart_handle_sysrq_char(port, ch))
				continue;
			uart_insert_char(port, status, MLB_USIO_SSR_ORE,
					 ch, flag);
			continue;
		}

#if defined(CONFIG_SERIAL_MILBEAUT_USIO_FRE2BREAK)
		if (status & MLB_USIO_SSR_FRE) {
			status &= ~(MLB_USIO_SSR_ORE | MLB_USIO_SSR_FRE |
				    MLB_USIO_SSR_PE);
			port->icount.brk++;
			if (!uart_handle_break(port))
				flag = MLB_USIO_SSR_BRK;
		} else
#endif
		if (status & MLB_USIO_SSR_PE)
			port->icount.parity++;
#if defined(CONFIG_SERIAL_MILBEAUT_USIO_FRE2BREAK)
		else if (status & MLB_USIO_SSR_FRE)
			port->icount.frame++;
#endif
		if (status & MLB_USIO_SSR_ORE)
			port->icount.overrun++;

		status &= port->read_status_mask;
		if (status & MLB_USIO_SSR_PE) {
			flag = TTY_PARITY;
			ch = 0;
		} else if (status & MLB_USIO_SSR_FRE) {
			flag = TTY_FRAME;
			ch = 0;
		}
		if (flag)
			uart_insert_char(port, status, MLB_USIO_SSR_ORE,
					 ch, flag);

		writeb(readb(port->membase + MLB_USIO_REG_SSR) |
				MLB_USIO_SSR_REC,
				port->membase + MLB_USIO_REG_SSR);

		max_count = readw(port->membase + MLB_USIO_REG_FBYTE) >> 8;
		writew(readw(port->membase + MLB_USIO_REG_FCR) |
		       MLB_USIO_FCR_FE2 | MLB_USIO_FCR_FRIIE,
		port->membase + MLB_USIO_REG_FCR);
	}

	tty_flip_buffer_push(ttyport);
}

static void mlb_usio_rx_chars_dma(struct uart_port *port)
{
	struct tty_port *ttyport = &port->state->port;
	struct t_mlb_port *mlbport = &mlb_ports[port->line];
	unsigned long flag = 0, r_idx = 0;
	char ch = 0;
	unsigned char bval;
	u8 status;

	for (r_idx = 0; r_idx < mlbport->r_siz; r_idx++) {
		ch = mlbport->rx_buf[r_idx];
		port->icount.rx++;
		if (uart_handle_sysrq_char(port, ch))
			continue;
		uart_insert_char(port, status, MLB_USIO_SSR_ORE,
				 ch, TTY_NORMAL);
	}

	status = readb(port->membase + MLB_USIO_REG_SSR);
#if defined(CONFIG_SERIAL_MILBEAUT_USIO_FRE2BREAK)
	if (status & MLB_USIO_SSR_FRE) {
		status &= ~(MLB_USIO_SSR_ORE | MLB_USIO_SSR_FRE |
			    MLB_USIO_SSR_PE);
		port->icount.brk++;
		if (!uart_handle_break(port))
			flag = MLB_USIO_SSR_BRK;
	} else
#endif
	if (status & MLB_USIO_SSR_PE)
		port->icount.parity++;
#if defined(CONFIG_SERIAL_MILBEAUT_USIO_FRE2BREAK)
	else if (status & MLB_USIO_SSR_FRE)
		port->icount.frame++;
#endif
	if (status & MLB_USIO_SSR_ORE)
		port->icount.overrun++;

	status &= port->read_status_mask;
	if (status & MLB_USIO_SSR_PE) {
		flag = TTY_PARITY;
		ch = 0;
	} else if (status & MLB_USIO_SSR_FRE) {
		flag = TTY_FRAME;
		ch = 0;
	}
	if (flag)
		uart_insert_char(port, status, MLB_USIO_SSR_ORE,
				 ch, flag);

	bval = readb(port->membase + MLB_USIO_REG_SSR);
	bval |= MLB_USIO_SSR_REC;
	writeb(bval, port->membase + MLB_USIO_REG_SSR);

	tty_flip_buffer_push(ttyport);
}

static void mlb_rx_dma_complete(void *arg)
{
	struct uart_port *port = arg;
	struct t_mlb_port *mlbport = &mlb_ports[port->line];
	struct dma_async_tx_descriptor *desc = NULL;
	unsigned short sval;
	dma_cookie_t cookie;

	spin_lock(&port->lock);
	mlb_usio_rx_chars_dma(port);
	spin_unlock(&port->lock);

	sval = (readw(port->membase + MLB_USIO_REG_FBYTE) >> 8);
	if (!sval)
		sval = 1;
	desc = dmaengine_prep_slave_single(mlbport->rx_ch,
					 mlbport->rx_dma_buf,
					 sval, DMA_DEV_TO_MEM,
					 DMA_PREP_INTERRUPT);
	if (!desc) {
		dev_err(port->dev, "rx dma prep failed\n");
		return;
	}
	mlbport->r_siz = sval;
	writew(sval << 8, port->membase + MLB_USIO_REG_FBYTE);

	/* No callback as dma buffer is drained on usart interrupt */
	desc->callback = mlb_rx_dma_complete;
	desc->callback_param = port;

	/* Push current DMA transaction in the pending queue */
	cookie = dmaengine_submit(desc);

	/* Issue pending DMA requests */
	dma_async_issue_pending(mlbport->rx_ch);

}

static irqreturn_t mlb_usio_rx_irq(int irq, void *dev_id)
{
	struct uart_port *port = dev_id;

	spin_lock(&port->lock);
	mlb_usio_rx_chars(port);
	spin_unlock(&port->lock);

	return IRQ_HANDLED;
}

static irqreturn_t mlb_usio_tx_irq(int irq, void *dev_id)
{
	struct uart_port *port = dev_id;

	spin_lock(&port->lock);
	if (readb(port->membase + MLB_USIO_REG_SSR) & MLB_USIO_SSR_TBI)
		mlb_usio_tx_chars(port);
	spin_unlock(&port->lock);

	return IRQ_HANDLED;
}

static unsigned int mlb_usio_tx_empty(struct uart_port *port)
{
	return (readb(port->membase + MLB_USIO_REG_SSR) & MLB_USIO_SSR_TBI) ?
		TIOCSER_TEMT : 0;
}

static void mlb_usio_set_mctrl(struct uart_port *port, unsigned int mctrl)
{
}

static unsigned int mlb_usio_get_mctrl(struct uart_port *port)
{
	return TIOCM_CAR | TIOCM_DSR | TIOCM_CTS;

}

static void mlb_usio_break_ctl(struct uart_port *port, int break_state)
{
}

static int mlb_usio_startup(struct uart_port *port)
{
	const char *portname = to_platform_device(port->dev)->name;
	unsigned long flags;
	int ret, index = port->line;
	unsigned char  escr;

	ret = request_irq(mlb_usio_irq[index][RX], mlb_usio_rx_irq,
				0, portname, port);
	if (ret)
		return ret;
	ret = request_irq(mlb_usio_irq[index][TX], mlb_usio_tx_irq,
				0, portname, port);
	if (ret) {
		free_irq(mlb_usio_irq[index][RX], port);
		return ret;
	}

	if (mlb_ports[index].tx_ch)
		free_irq(mlb_usio_irq[index][TX], port);
	if (mlb_ports[index].rx_ch)
		free_irq(mlb_usio_irq[index][RX], port);

	ram_onoff(index, true);
	escr = readb(port->membase + MLB_USIO_REG_ESCR);
	if (of_property_read_bool(port->dev->of_node, "uart-flow-enable"))
		escr |= MLB_USIO_ESCR_FLWEN;
	spin_lock_irqsave(&port->lock, flags);
	writeb(0, port->membase + MLB_USIO_REG_SCR);
	writeb(escr, port->membase + MLB_USIO_REG_ESCR);
	writeb(MLB_USIO_SCR_UPCL, port->membase + MLB_USIO_REG_SCR);
	writeb(MLB_USIO_SSR_REC, port->membase + MLB_USIO_REG_SSR);
	writew(0, port->membase + MLB_USIO_REG_FCR);
	writew(MLB_USIO_FCR_FCL1 | MLB_USIO_FCR_FCL2,
	       port->membase + MLB_USIO_REG_FCR);
	writew(MLB_USIO_FCR_FE1 | MLB_USIO_FCR_FE2 | MLB_USIO_FCR_FRIIE,
	       port->membase + MLB_USIO_REG_FCR);
	writew(0, port->membase + MLB_USIO_REG_FBYTE);
	writew(BIT(12), port->membase + MLB_USIO_REG_FBYTE);

	writeb(MLB_USIO_SCR_TXE  | MLB_USIO_SCR_RIE | MLB_USIO_SCR_TBIE |
	       MLB_USIO_SCR_RXE, port->membase + MLB_USIO_REG_SCR);
	spin_unlock_irqrestore(&port->lock, flags);

	return 0;
}

static void mlb_usio_shutdown(struct uart_port *port)
{
	int index = port->line;

	free_irq(mlb_usio_irq[index][RX], port);
	free_irq(mlb_usio_irq[index][TX], port);
	ram_onoff(index, false);
}

static void mlb_usio_set_termios(struct uart_port *port,
			struct ktermios *termios, struct ktermios *old)
{
	unsigned int escr, smr = MLB_USIO_SMR_SOE;
	unsigned long flags, baud, quot;

	switch (termios->c_cflag & CSIZE) {
	case CS5:
		escr = MLB_USIO_ESCR_L_5BIT;
		break;
	case CS6:
		escr = MLB_USIO_ESCR_L_6BIT;
		break;
	case CS7:
		escr = MLB_USIO_ESCR_L_7BIT;
		break;
	case CS8:
	default:
		escr = MLB_USIO_ESCR_L_8BIT;
		break;
	}

	if (termios->c_cflag & CSTOPB)
		smr |= MLB_USIO_SMR_SBL;

	if (termios->c_cflag & PARENB) {
		escr |= MLB_USIO_ESCR_PEN;
		if (termios->c_cflag & PARODD)
			escr |= MLB_USIO_ESCR_P;
	}
	/* Set hard flow control */
	if (of_property_read_bool(port->dev->of_node, "uart-flow-enable") ||
			(termios->c_cflag & CRTSCTS))
		escr |= MLB_USIO_ESCR_FLWEN;

	baud = uart_get_baud_rate(port, termios, old, 0, port->uartclk);
	if (baud > 1)
		quot = port->uartclk / baud - 1;
	else
		quot = 0;

	spin_lock_irqsave(&port->lock, flags);
	uart_update_timeout(port, termios->c_cflag, baud);
	port->read_status_mask = MLB_USIO_SSR_ORE | MLB_USIO_SSR_RDRF |
				 MLB_USIO_SSR_TDRE;
	if (termios->c_iflag & INPCK)
		port->read_status_mask |= MLB_USIO_SSR_FRE | MLB_USIO_SSR_PE;

	port->ignore_status_mask = 0;
	if (termios->c_iflag & IGNPAR)
		port->ignore_status_mask |= MLB_USIO_SSR_FRE | MLB_USIO_SSR_PE;
	if ((termios->c_iflag & IGNBRK) && (termios->c_iflag & IGNPAR))
		port->ignore_status_mask |= MLB_USIO_SSR_ORE;
	if ((termios->c_cflag & CREAD) == 0)
		port->ignore_status_mask |= MLB_USIO_SSR_RDRF;

	ram_onoff(port->line, true);
	writeb(0, port->membase + MLB_USIO_REG_SCR);
	writeb(MLB_USIO_SCR_UPCL, port->membase + MLB_USIO_REG_SCR);
	writeb(MLB_USIO_SSR_REC, port->membase + MLB_USIO_REG_SSR);
	writew(0, port->membase + MLB_USIO_REG_FCR);
	writeb(smr, port->membase + MLB_USIO_REG_SMR);
	writeb(escr, port->membase + MLB_USIO_REG_ESCR);
	writew(quot, port->membase + MLB_USIO_REG_BGR);
	writew(0, port->membase + MLB_USIO_REG_FCR);
	writew(MLB_USIO_FCR_FCL1 | MLB_USIO_FCR_FCL2 | MLB_USIO_FCR_FE1 |
	       MLB_USIO_FCR_FE2 | MLB_USIO_FCR_FRIIE,
	       port->membase + MLB_USIO_REG_FCR);
	writew(0, port->membase + MLB_USIO_REG_FBYTE);
	writew(BIT(12), port->membase + MLB_USIO_REG_FBYTE);
	writeb(MLB_USIO_SCR_RIE | MLB_USIO_SCR_RXE | MLB_USIO_SCR_TBIE |
	       MLB_USIO_SCR_TXE, port->membase + MLB_USIO_REG_SCR);
	spin_unlock_irqrestore(&port->lock, flags);
}

static const char *mlb_usio_type(struct uart_port *port)
{
	return ((port->type == PORT_MLB_USIO) ? USIO_NAME : NULL);
}

static void mlb_usio_config_port(struct uart_port *port, int flags)
{
	if (flags & UART_CONFIG_TYPE)
		port->type = PORT_MLB_USIO;
}
#ifdef CONFIG_CONSOLE_POLL
static int mlb_usio_poll_init(struct uart_port *port)
{
	return 0;
}
static int mlb_usio_get_poll_char(struct uart_port *port)
{
	unsigned long flags = 0;
	int c;

	spin_lock_irqsave(&port->lock, flags);

	if(readb(port->membase + MLB_USIO_REG_SSR) & MLB_USIO_SSR_RDRF)
		c = readw(port->membase + MLB_USIO_REG_DR);
	else
		c = NO_POLL_CHAR;
	spin_unlock_irqrestore(&port->lock, flags);
	return c;
}
static void mlb_usio_put_poll_char(struct uart_port *port, unsigned char c)
{
	unsigned long flags = 0;
	spin_lock_irqsave(&port->lock, flags);
	mlb_usio_console_putchar(port, c);
	spin_unlock_irqrestore(&port->lock, flags);
	return;
}
#endif
static const struct uart_ops mlb_usio_ops = {
	.tx_empty	= mlb_usio_tx_empty,
	.set_mctrl	= mlb_usio_set_mctrl,
	.get_mctrl	= mlb_usio_get_mctrl,
	.stop_tx	= mlb_usio_stop_tx,
	.start_tx	= mlb_usio_start_tx,
	.stop_rx	= mlb_usio_stop_rx,
	.enable_ms	= mlb_usio_enable_ms,
	.break_ctl	= mlb_usio_break_ctl,
	.startup	= mlb_usio_startup,
	.shutdown	= mlb_usio_shutdown,
	.set_termios	= mlb_usio_set_termios,
	.type		= mlb_usio_type,
	.config_port	= mlb_usio_config_port,
#ifdef CONFIG_CONSOLE_POLL
	.poll_init	= mlb_usio_poll_init,
	.poll_get_char = mlb_usio_get_poll_char,
	.poll_put_char = mlb_usio_put_poll_char,
#endif
};

#ifdef CONFIG_SERIAL_MILBEAUT_USIO_CONSOLE

static void mlb_usio_console_putchar(struct uart_port *port, int c)
{
	while (!(readb(port->membase + MLB_USIO_REG_SSR) & MLB_USIO_SSR_TDRE))
		cpu_relax();

	writew(c, port->membase + MLB_USIO_REG_DR);
}

static void mlb_usio_console_write(struct console *co, const char *s,
			       unsigned int count)
{
	struct uart_port *port = &mlb_usio_ports[co->index];

	uart_console_write(port, s, count, mlb_usio_console_putchar);
}

static int __init mlb_usio_console_setup(struct console *co, char *options)
{
	struct uart_port *port;
	int baud = 115200;
	int parity = 'n';
	int flow = 'n';
	int bits = 8;

	if (co->index >= CONFIG_SERIAL_MILBEAUT_USIO_PORTS)
		return -ENODEV;

	port = &mlb_usio_ports[co->index];
	if (!port->membase)
		return -ENODEV;


	if (options)
		uart_parse_options(options, &baud, &parity, &bits, &flow);

	if (of_property_read_bool(port->dev->of_node, "uart-flow-enable"))
		flow = 'r';

	return uart_set_options(port, co, baud, parity, bits, flow);
}


static struct uart_driver mlb_usio_uart_driver;
static struct console mlb_usio_console = {
	.name   = USIO_UART_DEV_NAME,
	.write  = mlb_usio_console_write,
	.device = uart_console_device,
	.setup  = mlb_usio_console_setup,
	.flags  = CON_PRINTBUFFER,
	.index  = -1,
	.data   = &mlb_usio_uart_driver,
};

static int __init mlb_usio_console_init(void)
{
	register_console(&mlb_usio_console);
	return 0;
}
console_initcall(mlb_usio_console_init);


static void mlb_usio_early_console_write(struct console *co, const char *s,
					u_int count)
{
	struct earlycon_device *dev = co->data;

	uart_console_write(&dev->port, s, count, mlb_usio_console_putchar);
}

static int __init mlb_usio_early_console_setup(struct earlycon_device *device,
						const char *opt)
{
	if (!device->port.membase)
		return -ENODEV;
	if (!(readb(device->port.membase + MLB_USIO_REG_SCR)
	      & MLB_USIO_SCR_TXE))
		return -ENODEV;


	device->con->write = mlb_usio_early_console_write;
	return 0;
}

OF_EARLYCON_DECLARE(mlb_usio, "socionext,milbeaut-usio-uart",
			mlb_usio_early_console_setup);
OF_EARLYCON_DECLARE(mlb_usio, "socionext,milbeaut-karine-usio-uart",
			mlb_usio_early_console_setup);

#define USIO_CONSOLE	(&mlb_usio_console)
#else
#define USIO_CONSOLE	NULL
#endif

static struct  uart_driver mlb_usio_uart_driver = {
	.owner		= THIS_MODULE,
	.driver_name	= USIO_NAME,
	.dev_name	= USIO_UART_DEV_NAME,
	.cons           = USIO_CONSOLE,
	.nr		= CONFIG_SERIAL_MILBEAUT_USIO_PORTS,
};

static int mlb_of_dma_rx_probe(struct t_mlb_port *mlbport,
				 struct platform_device *pdev)
{
	struct uart_port *port = mlbport->port;
	struct device *dev = &pdev->dev;
	struct dma_slave_config config;
	struct dma_async_tx_descriptor *desc = NULL;
	dma_cookie_t cookie;
	int ret;

	/* Request DMA RX channel */
	mlbport->rx_ch = dma_request_slave_channel(dev, "rx");
	if (!mlbport->rx_ch) {
		dev_info(dev, "rx dma alloc failed\n");
		return -ENODEV;
	}
	mlbport->rx_buf = dma_alloc_coherent(&pdev->dev, RX_BUF,
						 &mlbport->rx_dma_buf,
						 GFP_KERNEL);
	if (!mlbport->rx_buf) {
		ret = -ENOMEM;
		goto alloc_err;
	}

	/* Configure DMA channel */
	memset(&config, 0, sizeof(config));
	config.src_addr = port->mapbase + MLB_USIO_REG_DR;
	config.src_addr_width = DMA_SLAVE_BUSWIDTH_1_BYTE;
	config.src_maxburst = DMA_SLAVE_BUSWIDTH_1_BYTE;

	ret = dmaengine_slave_config(mlbport->rx_ch, &config);
	if (ret < 0) {
		dev_err(dev, "rx dma channel config failed\n");
		ret = -ENODEV;
		goto config_err;
	}

	desc = dmaengine_prep_slave_single(mlbport->rx_ch,
					 mlbport->rx_dma_buf,
					 1, DMA_DEV_TO_MEM,
					 DMA_PREP_INTERRUPT);
	if (!desc) {
		dev_err(dev, "rx dma prep failed\n");
		ret = -ENODEV;
		goto config_err;
	}
	mlbport->r_siz = 1;

	/* No callback as dma buffer is drained on usart interrupt */
	desc->callback = mlb_rx_dma_complete;
	desc->callback_param = port;

	/* Push current DMA transaction in the pending queue */
	cookie = dmaengine_submit(desc);

	/* Issue pending DMA requests */
	dma_async_issue_pending(mlbport->rx_ch);

	return 0;

config_err:
	dma_free_coherent(&pdev->dev,
			  RX_BUF, mlbport->rx_buf,
			  mlbport->rx_dma_buf);

alloc_err:
	dma_release_channel(mlbport->rx_ch);
	mlbport->rx_ch = NULL;

	return ret;
}

static int mlb_of_dma_tx_probe(struct t_mlb_port *mlbport,
			       struct platform_device *pdev)
{
	struct uart_port *port = mlbport->port;
	struct device *dev = &pdev->dev;
	struct dma_slave_config config;
	int ret;

	mlbport->tx_dma_busy = false;

	/* Request DMA TX channel */
	mlbport->tx_ch = dma_request_slave_channel(dev, "tx");
	if (!mlbport->tx_ch) {
		dev_info(dev, "tx dma alloc failed or no properties\n");
		return -ENODEV;
	}
	mlbport->tx_buf = dma_alloc_coherent(&pdev->dev, TX_BUF,
						 &mlbport->tx_dma_buf,
						 GFP_KERNEL);
	if (!mlbport->tx_buf) {
		ret = -ENOMEM;
		goto alloc_err;
	}

	/* Configure DMA channel */
	memset(&config, 0, sizeof(config));
	config.dst_addr = port->mapbase + MLB_USIO_REG_DR;
	config.dst_addr_width = DMA_SLAVE_BUSWIDTH_1_BYTE;
	config.dst_maxburst = DMA_SLAVE_BUSWIDTH_1_BYTE;

	ret = dmaengine_slave_config(mlbport->tx_ch, &config);
	if (ret < 0) {
		dev_err(dev, "tx dma channel config failed\n");
		ret = -ENODEV;
		goto config_err;
	}

	return 0;

config_err:
	dma_free_coherent(&pdev->dev,
			  TX_BUF, mlbport->tx_buf,
			  mlbport->tx_dma_buf);

alloc_err:
	dma_release_channel(mlbport->tx_ch);
	mlbport->tx_ch = NULL;

	return ret;
}

static void mlb_usio_ram_onoff_karine(int idx, bool onoff)
{
	void __iomem *peri_common_base;
	unsigned int val;

	peri_common_base = ioremap(PERI_COMMON_KARINE, 0x4);
#ifdef CONFIG_ARCH_MILBEAUT_KARINE
	psci_ops.sni_spinl(SPINL_ID_PERISLP, SNI_SPINLOCK_LOCK);
#endif
	val = readl(peri_common_base);
	if (onoff)
		val &= ~BIT(idx);
	else
		val |= BIT(idx);
	writel(val, peri_common_base);

#ifdef CONFIG_ARCH_MILBEAUT_KARINE
	psci_ops.sni_spinl(SPINL_ID_PERISLP, SNI_SPINLOCK_UNLOCK);
#endif
	iounmap(peri_common_base);
}

static void mlb_usio_ram_onoff(int idx, bool onoff)
{
}

static const struct of_device_id mlb_usio_dt_ids[];

static int mlb_usio_probe(struct platform_device *pdev)
{
	struct clk *clk = devm_clk_get(&pdev->dev, 0);
	struct device *dev = &pdev->dev;
	struct uart_port *port;
	struct resource *res;
	const struct of_device_id *match;
	int index;
	int ret;

	match = of_match_device(mlb_usio_dt_ids, dev);
	if (!match)
		return -EINVAL;

	if (IS_ERR(clk)) {
		dev_err(&pdev->dev, "Missing clock\n");
		return PTR_ERR(clk);
	}
	ret = clk_prepare_enable(clk);
	if (ret) {
		dev_err(&pdev->dev, "Clock enable failed: %d\n", ret);
		return ret;
	}
	if (of_property_read_u32(pdev->dev.of_node, "index", &index)) {
		dev_err(&pdev->dev, "Missing index\n");
		ret = -EINVAL;
		goto failed;
	}

	if (!match->data) {
		ret = -EINVAL;
		goto failed;
	}
	ram_onoff = match->data;
	port = &mlb_usio_ports[index];

	port->private_data = (void *)clk;
	res = platform_get_resource(pdev, IORESOURCE_MEM, 0);
	if (res == NULL) {
		dev_err(&pdev->dev, "Missing regs\n");
		ret = -ENODEV;
		goto failed;
	}
	port->mapbase = res->start;
	port->membase = ioremap(res->start, (res->end - res->start + 1));
	port->membase = devm_ioremap(&pdev->dev, res->start,
				resource_size(res));
	mlb_ports[index].port = port;

	ret = platform_get_irq_byname(pdev, "rx");
	if (ret <= 0) {
		dev_err(&pdev->dev, "Missing rx interrupt\n");
		goto failed1;
	}
	mlb_usio_irq[index][RX] = ret;

	ret = platform_get_irq_byname(pdev, "tx");
	if (ret <= 0) {
		dev_err(&pdev->dev, "Missing tx interrupt\n");
		goto failed1;
	}
	mlb_usio_irq[index][TX] = ret;

	ret = mlb_of_dma_rx_probe(&mlb_ports[index], pdev);
	if (ret)
		dev_info(&pdev->dev, "interrupt mode used for rx (no dma)\n");
	ret = mlb_of_dma_tx_probe(&mlb_ports[index], pdev);
	if (ret)
		dev_info(&pdev->dev, "interrupt mode used for tx (no dma)\n");

	port->irq = mlb_usio_irq[index][RX];
	port->uartclk = clk_get_rate(clk);
	port->fifosize = 128;
	port->iotype = UPIO_MEM32;
	port->flags = UPF_BOOT_AUTOCONF | UPF_SPD_VHI;
	port->line = index;
	port->ops = &mlb_usio_ops;
	port->dev = &pdev->dev;

	ret = uart_add_one_port(&mlb_usio_uart_driver, port);
	if (ret) {
		dev_err(&pdev->dev, "Adding port failed: %d\n", ret);
		goto failed1;
	}
	platform_set_drvdata(pdev, port);
	return 0;

failed1:
	iounmap(port->membase);

failed:
	clk_disable_unprepare(clk);

	return ret;
}

static int mlb_usio_remove(struct platform_device *pdev)
{
	struct uart_port *port = platform_get_drvdata(pdev);
	struct clk *clk = port->private_data;

	uart_remove_one_port(&mlb_usio_uart_driver, port);
	clk_disable_unprepare(clk);

	return 0;
}

static int usio_suspend(struct platform_device *pdev, pm_message_t state)
{
	struct uart_port *port = platform_get_drvdata(pdev);
	struct uart_pm_regs *pm_regs = &uart_pm_regs[port->line];
	unsigned long flags;

	spin_lock_irqsave(&port->lock, flags);
	pm_regs->smr = readb(port->membase + MLB_USIO_REG_SMR);
	pm_regs->scr = readb(port->membase + MLB_USIO_REG_SCR);
	pm_regs->escr = readb(port->membase + MLB_USIO_REG_ESCR);
	pm_regs->bgr = readw(port->membase + MLB_USIO_REG_BGR);
	pm_regs->fcr = readw(port->membase + MLB_USIO_REG_FCR);
	pm_regs->fbyte = readw(port->membase + MLB_USIO_REG_FBYTE);
	ram_onoff(port->line, false);
	spin_unlock_irqrestore(&port->lock, flags);

	return 0;
}

static int usio_resume(struct platform_device *pdev)
{
	struct uart_port *port = platform_get_drvdata(pdev);
	struct uart_pm_regs *pm_regs = &uart_pm_regs[port->line];
	unsigned long flags;

	spin_lock_irqsave(&port->lock, flags);
	ram_onoff(port->line, true);
	writeb(0, port->membase + MLB_USIO_REG_SCR);
	writeb(MLB_USIO_SCR_UPCL, port->membase + MLB_USIO_REG_SCR);
	writeb(MLB_USIO_SSR_REC, port->membase + MLB_USIO_REG_SSR);
	writew(0, port->membase + MLB_USIO_REG_FCR);
	writeb(pm_regs->smr, port->membase + MLB_USIO_REG_SMR);
	writeb(pm_regs->escr, port->membase + MLB_USIO_REG_ESCR);
	writew(pm_regs->bgr, port->membase + MLB_USIO_REG_BGR);
	writew(0, port->membase + MLB_USIO_REG_FCR);
	writew(pm_regs->fcr | MLB_USIO_FCR_FCL1 | MLB_USIO_FCR_FCL2,
	       port->membase + MLB_USIO_REG_FCR);
	writew(0, port->membase + MLB_USIO_REG_FBYTE);
	writew(pm_regs->fbyte, port->membase + MLB_USIO_REG_FBYTE);
	writeb(pm_regs->scr, port->membase + MLB_USIO_REG_SCR);
	spin_unlock_irqrestore(&port->lock, flags);

	return 0;
}

static const struct of_device_id mlb_usio_dt_ids[] = {
	{ .compatible = "socionext,milbeaut-usio-uart",
	  .data = (void *)&mlb_usio_ram_onoff
	},
	{ .compatible = "socionext,milbeaut-karine-usio-uart",
	  .data = (void *)&mlb_usio_ram_onoff_karine
	},
	{ /* sentinel */ }
};
MODULE_DEVICE_TABLE(of, mlb_usio_dt_ids);

static struct platform_driver mlb_usio_driver = {
	.probe          = mlb_usio_probe,
	.suspend        = usio_suspend,
	.resume         = usio_resume,
	.remove         = mlb_usio_remove,
	.driver         = {
		.name   = USIO_NAME,
		.of_match_table = mlb_usio_dt_ids,
	},
};

static int __init mlb_usio_init(void)
{
	int ret = uart_register_driver(&mlb_usio_uart_driver);

	if (ret) {
		pr_err("%s: uart registration failed: %d\n", __func__, ret);
		return ret;
	}
	ret = platform_driver_register(&mlb_usio_driver);
	if (ret) {
		uart_unregister_driver(&mlb_usio_uart_driver);
		pr_err("%s: drv registration failed: %d\n", __func__, ret);
		return ret;
	}

	return 0;
}

static void __exit mlb_usio_exit(void)
{
	platform_driver_unregister(&mlb_usio_driver);
	uart_unregister_driver(&mlb_usio_uart_driver);
}

module_init(mlb_usio_init);
module_exit(mlb_usio_exit);

MODULE_AUTHOR("SOCIONEXT");
MODULE_DESCRIPTION("MILBEAUT_USIO/UART Driver");
MODULE_LICENSE("GPL");
