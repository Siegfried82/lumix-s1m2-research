// SPDX-License-Identifier: GPL-2.0
/*
 * Milbeaut SPI driver
 *
 * Copyright (C) 2019 Socionext Inc.
 */

#include <linux/bitfield.h>
#include <linux/bits.h>
#include <linux/clk.h>
#include <linux/dmaengine.h>
#include <linux/iopoll.h>
#include <linux/module.h>
#include <linux/of_address.h>
#include <linux/of_gpio.h>
#include <linux/platform_device.h>
#include <linux/pm_runtime.h>
#include <linux/spi/spi.h>
#include <linux/dma-mapping.h>

/* SPI register offset */
#define MLB_SPI_TXDATA				0x0
#define MLB_SPI_RXDATA				0x4
#define MLB_SPI_DIV				0x8
#define MLB_SPI_CTRL				0xC
#define MLB_SPI_AUX_CTRL			0x10
#define MLB_SPI_ST				0x14
#define MLB_SPI_SLV_SEL				0x18
#define MLB_SPI_SLV_POL				0x1C
#define MLB_SPI_INT_EN				0x20
#define MLB_SPI_INT_ST				0x24
#define MLB_SPI_INT_CLR				0x28
#define MLB_SPI_TXFIFO				0x2C
#define MLB_SPI_RXFIFO				0x30
#define MLB_SPI_DMA_TO				0x34
#define MLB_SPI_MS_DLY				0x38
#define MLB_SPI_EN				0x3C
#define MLB_SPI_FIFO_DPTH			0x48
#define MLB_SPI_FIFO_WMK			0x4C
#define MLB_SPI_TX_DWR				0x50

/* Bit fields in DIV */
#define MLB_SPI_DIV_DIVISOR			BIT(0)

/* Bit fields in CTRL */
#define MLB_SPI_CTRL_CONTXFER			BIT(0)
#define MLB_SPI_CTRL_DIVENABLE			BIT(1)
#define MLB_SPI_CTRL_MSB1ST			BIT(2)
#define MLB_SPI_CTRL_CPHA			BIT(3)
#define MLB_SPI_CTRL_CPOL			BIT(4)
#define MLB_SPI_CTRL_MASTER			BIT(5)
#define MLB_SPI_CTRL_DMA			BIT(10)
#define MLB_SPI_CTRL_MWAITEN			BIT(11)
#define MLB_SPI_CTRL_MASK	~(MLB_SPI_CTRL_DIVENABLE | \
						MLB_SPI_CTRL_MSB1ST | \
						MLB_SPI_CTRL_CPHA | \
						MLB_SPI_CTRL_CPOL)

/* Bit fields in AUX_CTRL */
#define MLB_SPI_AUX_CTRL_SPIMODE		BIT(0)
#define MLB_SPI_AUX_CTRL_INHIBITDIN		BIT(3)
#define MLB_SPI_AUX_CTRL_XFERFORMAT		BIT(4)
#define MLB_SPI_AUX_CTRL_CONTXFEREXTEND		BIT(7)
#define MLB_SPI_AUX_CTRL_BITSIZE		GENMASK(12, 8)

/* Bit fields in ST */
#define MLB_SPI_ST_XFERIP			BIT(0)
#define MLB_SPI_ST_TXEMPTY			BIT(2)
#define MLB_SPI_ST_TXWMARK			BIT(3)
#define MLB_SPI_ST_TXFULL			BIT(4)
#define MLB_SPI_ST_RXEMPTY			BIT(5)
#define MLB_SPI_ST_RXWMARK			BIT(6)
#define MLB_SPI_ST_RXFULL			BIT(7)
#define MLB_SPI_ST_RXOVERFLOW			BIT(8)
#define MLB_SPI_ST_RXTIMEOUT			BIT(9)

/* Bit fields in SLV_SEL */
#define MLB_SPI_SLV_SEL_SSOUT0			BIT(0)
#define MLB_SPI_SLV_SEL_SSOUT1			BIT(1)
#define MLB_SPI_SLV_SEL_SSOUT2			BIT(2)
#define MLB_SPI_SLV_SEL_SSOUT3			BIT(3)

/* Bit fields in SLV_POL */
#define MLB_SPI_SLV_POL_SSPOL0			BIT(0)
#define MLB_SPI_SLV_POL_SSPOL1			BIT(1)
#define MLB_SPI_SLV_POL_SSPOL2			BIT(2)
#define MLB_SPI_SLV_POL_SSPOL3			BIT(3)

/* Bit fields in INT_EN */
#define MLB_SPI_INT_EN_TXEMPTYPULSE		BIT(0)
#define MLB_SPI_INT_EN_TXWMARKPULSE		BIT(1)
#define MLB_SPI_INT_EN_RXWMARKPULSE		BIT(2)
#define MLB_SPI_INT_EN_RXFULLPULSE		BIT(3)
#define MLB_SPI_INT_EN_XFERDONEPULSE		BIT(4)
#define MLB_SPI_INT_EN_RXFIFOOVERFLOW		BIT(7)
#define MLB_SPI_INT_EN_RXTIMEOUT		BIT(8)

/* Bit fields in INT_ST */
#define MLB_SPI_INT_ST_TXEMPTYPULSE		BIT(0)
#define MLB_SPI_INT_ST_TXWMARKPULSE		BIT(1)
#define MLB_SPI_INT_ST_RXWMARKPULSE		BIT(2)
#define MLB_SPI_INT_ST_RXFULLPULSE		BIT(3)
#define MLB_SPI_INT_ST_XFERDONEPULSE		BIT(4)
#define MLB_SPI_INT_ST_RXFIFOOVERFLOW		BIT(7)
#define MLB_SPI_INT_ST_RXTIMEOUT		BIT(8)

/* Bit fields in INT_CLR */
#define MLB_SPI_INT_CLR_TXEMPTYPULSE		BIT(0)
#define MLB_SPI_INT_CLR_TXWMARKPULSE		BIT(1)
#define MLB_SPI_INT_CLR_RXWMARKPULSE		BIT(2)
#define MLB_SPI_INT_CLR_RXFULLPULSE		BIT(3)
#define MLB_SPI_INT_CLR_XFERDONEPULSE		BIT(4)
#define MLB_SPI_INT_CLR_RXFIFOOVERFLOW		BIT(7)
#define MLB_SPI_INT_CLR_RXTIMEOUT		BIT(8)

/* Bit fields in TXFIFO */
#define MLB_SPI_TXFIFO_TX_FIFO_LEVEL		BIT(0)

/* Bit fields in RXFIFO */
#define MLB_SPI_RXFIFO_RX_FIFO_LEVEL		BIT(0)

/* Bit fileds in DMA_TO */
#define MLB_SPI_DMA_TO_TIMEOUT			BIT(0)

/* Bit fields in DMA_MS_DLY */
#define MLB_SPI_DMA_MS_DLY_MWAIT		BIT(0)

/* Bit fields in EN */
#define MLB_SPI_EN_ENABLEREQ			BIT(0)
#define MLB_SPI_EN_EXTENSEL			BIT(1)

/* Bit fields in FIFO_DPTH */
#define MLB_SPI_FIFO_DPTH_FIFODEPTH		BIT(0)

/* Bit fields in FIFO_WMK */
#define MLB_SPI_FIFO_WMK_RXWMARKSET		BIT(0)
#define MLB_SPI_FIFO_WMK_TXWMARKSET		BIT(8)

/* Bit fields in TX_DWR */
#define MLB_SPI_TX_DWR_TXDUMMYWR		BIT(0)

#define MLB_SPI_RXBUSY				BIT(0)
#define MLB_SPI_TXBUSY				BIT(1)
#define MLB_SPI_BUSY_MASK	~(MLB_SPI_RXBUSY | MLB_SPI_TXBUSY)

#define MLB_SPI_INT_ALL_BIT_SET			0x000001FF

#define MLB_SPI_MAX_DMA_BYTES			0xFFFF

#define MLB_SPI_CONT_TRANS_INACT_BETWEEN	0
#define MLB_SPI_CONT_TRANS_INACT_FIFO_EMPTY	1
#define MLB_SPI_CONT_TRANS_ACT_FIFO_EMPTY	2

#define MLB_SPI_CS_MAX				4

struct milbeaut_spi_dma_data {
	struct dma_chan *ch;
	enum dma_transfer_direction direction;
	dma_addr_t addr;
};

struct milbeaut_spi {
	struct device *dev;
	struct spi_master *master;
	struct clk *spiclk;
	u32 fifo_len;
	u32 max_freq;
	u32 len;
	u32 speed;
	u32 state;
	u16 mode;
	u8 bpw;
	u8 n_bytes;
	u8 irq;
	u32 ssout_cont[4];
	const void *tx;
	void *rx;
	void __iomem *regs;
	spinlock_t lock;

	bool use_dma;
	bool have_dma;
	unsigned long base_phys;
	struct sg_table tx_sg;
	struct sg_table rx_sg;
	struct milbeaut_spi_dma_data dma_rx;
	struct milbeaut_spi_dma_data dma_tx;
	struct completion dma_rx_completion;
	struct completion dma_tx_completion;
};

static irqreturn_t milbeaut_spi_int_handler(int irq, void *dev_id)
{
	unsigned int value;
	struct spi_master *master = dev_id;
	struct milbeaut_spi *mspi = spi_master_get_devdata(master);

	value = readw_relaxed(mspi->regs + MLB_SPI_INT_ST);
	if (value & MLB_SPI_INT_ST_XFERDONEPULSE)
		writew_relaxed(MLB_SPI_INT_CLR_XFERDONEPULSE,
				mspi->regs + MLB_SPI_INT_CLR);
	if (value & MLB_SPI_INT_ST_RXFIFOOVERFLOW)
		writew_relaxed(MLB_SPI_INT_CLR_RXFIFOOVERFLOW,
				mspi->regs + MLB_SPI_INT_CLR);
	if (value & MLB_SPI_INT_ST_TXEMPTYPULSE)
		writew_relaxed(MLB_SPI_INT_CLR_TXEMPTYPULSE,
				mspi->regs + MLB_SPI_INT_CLR);
	if (value & MLB_SPI_INT_ST_TXWMARKPULSE)
		writew_relaxed(MLB_SPI_INT_CLR_TXWMARKPULSE,
				mspi->regs + MLB_SPI_INT_CLR);
	if (value & MLB_SPI_INT_ST_RXWMARKPULSE)
		writew_relaxed(MLB_SPI_INT_CLR_RXWMARKPULSE,
				mspi->regs + MLB_SPI_INT_CLR);
	if (value & MLB_SPI_INT_ST_RXFULLPULSE)
		writew_relaxed(MLB_SPI_INT_CLR_RXFULLPULSE,
				mspi->regs + MLB_SPI_INT_CLR);
	if (value & MLB_SPI_INT_ST_RXTIMEOUT)
		writew_relaxed(MLB_SPI_INT_CLR_RXTIMEOUT,
				mspi->regs + MLB_SPI_INT_CLR);

	return IRQ_HANDLED;
}

static int check_overflow(struct milbeaut_spi *mspi)
{
	return (readw_relaxed(mspi->regs + MLB_SPI_ST) &
			MLB_SPI_INT_ST_RXFIFOOVERFLOW) ? 1 : 0;
}

static int milbeaut_spi_prepare_message(struct spi_master *master,
					struct spi_message *msg)
{
	struct milbeaut_spi *mspi = spi_master_get_devdata(master);
	struct spi_device *spi = msg->spi;

	mspi->mode = spi->mode;

	return 0;
}

static int milbeaut_spi_unprepare_message(struct spi_master *master,
					  struct spi_message *msg)
{
	unsigned long flags;
	struct milbeaut_spi *mspi = spi_master_get_devdata(master);

	spin_lock_irqsave(&mspi->lock, flags);
	if (mspi->use_dma) {
		if (mspi->state & MLB_SPI_RXBUSY)
			dmaengine_terminate_all(mspi->dma_rx.ch);
		if (mspi->state & MLB_SPI_TXBUSY)
			dmaengine_terminate_all(mspi->dma_tx.ch);
	}
	spin_unlock_irqrestore(&mspi->lock, flags);

	return 0;
}

static int milbeaut_spi_pio_readx(struct milbeaut_spi *mspi, void *buf)
{
	if (mspi->bpw > 16) {
		*(u32 *)buf = readl_relaxed(mspi->regs + MLB_SPI_RXDATA);
		return sizeof(u32);
	} else if (mspi->bpw > 8) {
		*(u16 *)buf = readw_relaxed(mspi->regs + MLB_SPI_RXDATA);
		return sizeof(u16);
	}
	*(u8 *)buf = readb_relaxed(mspi->regs + MLB_SPI_RXDATA);

	return sizeof(u8);
}

static int milbeaut_spi_pio_writex(struct milbeaut_spi *mspi, void *buf)
{
	if (mspi->bpw > 16) {
		writel_relaxed(*(u32 *)buf, mspi->regs + MLB_SPI_TXDATA);
		return sizeof(u32);
	} else if (mspi->bpw > 8) {
		writew_relaxed(*(u16 *)buf, mspi->regs + MLB_SPI_TXDATA);
		return sizeof(u16);
	}
	writeb_relaxed(*(u8 *)buf, mspi->regs + MLB_SPI_TXDATA);

	return sizeof(u8);
}

static void milbeaut_spi_check_progress(struct milbeaut_spi *mspi)
{
	unsigned int check;

	while(1){
		check = readl_relaxed(mspi->regs + MLB_SPI_ST);
		check = MLB_SPI_ST_XFERIP & check;
		if(!check)
			break; /* not progress */
	}
}

static void milbeaut_spi_end_process(struct milbeaut_spi *mspi)
{
	milbeaut_spi_check_progress(mspi);
	writew_relaxed(readw_relaxed(mspi->regs + MLB_SPI_CTRL) &
			~MLB_SPI_CTRL_CONTXFER,
			mspi->regs + MLB_SPI_CTRL);
	writew_relaxed(readw_relaxed(mspi->regs + MLB_SPI_AUX_CTRL) &
			~MLB_SPI_AUX_CTRL_CONTXFEREXTEND,
			mspi->regs + MLB_SPI_AUX_CTRL);
	writew_relaxed(0, mspi->regs + MLB_SPI_INT_EN);
	writew_relaxed(0, mspi->regs + MLB_SPI_SLV_SEL);
	writew_relaxed(readw_relaxed(mspi->regs + MLB_SPI_EN) &
			~MLB_SPI_EN_ENABLEREQ, mspi->regs + MLB_SPI_EN);
}

static int milbeaut_spi_wait_send(struct milbeaut_spi *mspi)
{
	unsigned int value;

	if (readx_poll_timeout(readw_relaxed,
		mspi->regs + MLB_SPI_ST, value,
		!(value & MLB_SPI_ST_TXFULL),
		10, 10000)) {
		dev_err(mspi->dev, "send timeout error!\n");
		return -ETIMEDOUT;
	}

	return 0;
}

static int milbeaut_spi_wait_receive(struct milbeaut_spi *mspi)
{
	unsigned int value;

	if (readx_poll_timeout(readw_relaxed,
		mspi->regs + MLB_SPI_ST, value,
		!(value & MLB_SPI_ST_RXEMPTY),
		10, 10000)) {
		dev_err(mspi->dev, "receive timeout error!\n");
		return -ETIMEDOUT;
	}
	if (check_overflow(mspi)) {
		dev_err(mspi->dev, "buffer overflow error!\n");
		return -EOVERFLOW;
	}

	return 0;
}

static int milbeaut_spi_pio_transfer(struct milbeaut_spi *mspi)
{
	unsigned int num, fifo_depth, ret;
	int remain = mspi->len;
	uint8_t *tx_addr, *rx_addr;

	writeb_relaxed(readw_relaxed(mspi->regs + MLB_SPI_CTRL) &
			~MLB_SPI_CTRL_DMA, mspi->regs + MLB_SPI_CTRL);

	if (mspi->tx){
		tx_addr = (u8 *)mspi->tx;
	}
	if (mspi->rx){
		rx_addr = (u8 *)mspi->rx;
	}
	if (mspi->bpw > 16)
		remain = remain / 4;
	else if (mspi->bpw > 8)
		remain = remain / 2;

	writeb_relaxed(1, mspi->regs + MLB_SPI_EN);

	writew_relaxed(0x780, mspi->regs + MLB_SPI_AUX_CTRL);
	fifo_depth = readw(mspi->regs + MLB_SPI_FIFO_DPTH);
	writew_relaxed(fifo_depth / 2, mspi->regs + MLB_SPI_FIFO_WMK);
	if ((mspi->tx) && (mspi->rx)) {
		for (num = 0; num < remain; num++) {
			tx_addr += milbeaut_spi_pio_writex(mspi, tx_addr);
			ret = milbeaut_spi_wait_send(mspi);
			if (ret)
				return ret;
		}
		for (num = 0; num < remain; num++) {
			ret = milbeaut_spi_wait_receive(mspi);
			if (ret)
				return ret;
			rx_addr += milbeaut_spi_pio_readx(mspi, rx_addr);
		}
		cpu_relax();
	} else if ((mspi->tx) && (!(mspi->rx))) {
		writew_relaxed(readw_relaxed(mspi->regs + MLB_SPI_AUX_CTRL) |
				MLB_SPI_AUX_CTRL_INHIBITDIN,
				mspi->regs + MLB_SPI_AUX_CTRL);
		for (num = 0; num < remain; num++) {
			tx_addr += milbeaut_spi_pio_writex(mspi, tx_addr);
			ret = milbeaut_spi_wait_send(mspi);
			if (ret)
				return ret;
		}
		writew_relaxed(readw_relaxed(mspi->regs + MLB_SPI_AUX_CTRL) &
				~MLB_SPI_AUX_CTRL_INHIBITDIN,
				mspi->regs + MLB_SPI_AUX_CTRL);
		cpu_relax();
	} else if (!(mspi->tx) && (mspi->rx)) {
		writew_relaxed(readw_relaxed(mspi->regs + MLB_SPI_INT_EN) |
				MLB_SPI_INT_EN_TXEMPTYPULSE |
				MLB_SPI_INT_EN_TXWMARKPULSE,
				mspi->regs + MLB_SPI_INT_EN);
		if (fifo_depth < remain) {
			while (fifo_depth < remain) {
				writeb_relaxed(fifo_depth,
					mspi->regs + MLB_SPI_TX_DWR);
				for (num = 0; num < fifo_depth; num++) {
					ret = milbeaut_spi_wait_receive(mspi);
					if (ret)
						return ret;
					rx_addr += milbeaut_spi_pio_readx(mspi,
							rx_addr);
				}
				cpu_relax();
				remain -= fifo_depth;
			}
			writeb_relaxed(fifo_depth, mspi->regs + MLB_SPI_TX_DWR);
			for (num = 0; num < fifo_depth; num++) {
				ret = milbeaut_spi_wait_receive(mspi);
				if (ret)
					return ret;
				rx_addr += milbeaut_spi_pio_readx(mspi,
						rx_addr);
			}
			cpu_relax();
		} else {
			writeb_relaxed(remain, mspi->regs + MLB_SPI_TX_DWR);
			for (num = 0; num < remain; num++) {
				ret = milbeaut_spi_wait_receive(mspi);
				if (ret)
					return ret;
				rx_addr += milbeaut_spi_pio_readx(mspi,
						rx_addr);
			}
			cpu_relax();
		}
	}

	return 0;
}

static void milbeaut_spi_dma_rxcb(void *data)
{
	unsigned long flags;
	struct milbeaut_spi *mspi = data;

	spin_lock_irqsave(&mspi->lock, flags);
	mspi->state &= ~MLB_SPI_RXBUSY;
	if (!(mspi->state & MLB_SPI_TXBUSY))
		spi_finalize_current_transfer(mspi->master);
	complete(&mspi->dma_rx_completion);
	spin_unlock_irqrestore(&mspi->lock, flags);
}

static void milbeaut_spi_dma_txcb(void *data)
{
	unsigned long flags;
	struct milbeaut_spi *mspi = data;

	spin_lock_irqsave(&mspi->lock, flags);
	mspi->state &= ~MLB_SPI_TXBUSY;
	if (!(mspi->state & MLB_SPI_RXBUSY))
		spi_finalize_current_transfer(mspi->master);
	complete(&mspi->dma_tx_completion);
	spin_unlock_irqrestore(&mspi->lock, flags);
}

static int milbeaut_spi_prepare_dma(struct milbeaut_spi *mspi)
{
	unsigned long flags;
	struct dma_slave_config rxconf, txconf;
	struct dma_async_tx_descriptor *rxdesc, *txdesc;
	unsigned int fifo_depth;

	spin_lock_irqsave(&mspi->lock, flags);
	mspi->state &= MLB_SPI_BUSY_MASK;
	spin_unlock_irqrestore(&mspi->lock, flags);
	rxdesc = NULL;

	writew_relaxed(0x780, mspi->regs + MLB_SPI_AUX_CTRL);
	fifo_depth = readw(mspi->regs + MLB_SPI_FIFO_DPTH);
	writew_relaxed(fifo_depth / 2, mspi->regs + MLB_SPI_FIFO_WMK);
	writew_relaxed(readw_relaxed(mspi->regs + MLB_SPI_CTRL) |
				FIELD_PREP(MLB_SPI_CTRL_DMA, mspi->have_dma),
				mspi->regs + MLB_SPI_CTRL);

	if (mspi->rx) {
		rxconf.direction = DMA_DEV_TO_MEM;
		rxconf.src_addr = mspi->base_phys + MLB_SPI_RXDATA;
		rxconf.src_addr_width = mspi->n_bytes;
		rxconf.src_maxburst = mspi->n_bytes;
		dmaengine_slave_config(mspi->dma_rx.ch, &rxconf);
		rxdesc = dmaengine_prep_slave_sg(
				mspi->dma_rx.ch,
				mspi->rx_sg.sgl, mspi->rx_sg.nents,
				DMA_DEV_TO_MEM, DMA_PREP_INTERRUPT);
		rxdesc->callback = milbeaut_spi_dma_rxcb;
		rxdesc->callback_param = mspi;
		reinit_completion(&mspi->dma_rx_completion);
	}
	txdesc = NULL;
	if (mspi->tx) {
		txconf.direction = DMA_MEM_TO_DEV;
		txconf.dst_addr = mspi->base_phys + MLB_SPI_TXDATA;
		txconf.dst_addr_width = mspi->n_bytes;
		txconf.dst_maxburst = mspi->n_bytes;
		dmaengine_slave_config(mspi->dma_tx.ch, &txconf);
		txdesc = dmaengine_prep_slave_sg(
				mspi->dma_tx.ch,
				mspi->tx_sg.sgl, mspi->tx_sg.nents,
				DMA_MEM_TO_DEV, DMA_PREP_INTERRUPT);
		txdesc->callback = milbeaut_spi_dma_txcb;
		txdesc->callback_param = mspi;
		reinit_completion(&mspi->dma_tx_completion);
	}
	writeb_relaxed(1, mspi->regs + MLB_SPI_EN);
	if (rxdesc) {
		spin_lock_irqsave(&mspi->lock, flags);
		mspi->state |= MLB_SPI_RXBUSY;
		spin_unlock_irqrestore(&mspi->lock, flags);
		dmaengine_submit(rxdesc);
		dma_async_issue_pending(mspi->dma_rx.ch);
	}
	if (txdesc) {
		spin_lock_irqsave(&mspi->lock, flags);
		mspi->state |= MLB_SPI_TXBUSY;
		spin_unlock_irqrestore(&mspi->lock, flags);
		dmaengine_submit(txdesc);
		dma_async_issue_pending(mspi->dma_tx.ch);
	}

	if ( !(mspi->tx) && (mspi->rx) ) {
		writeb_relaxed(mspi->len, mspi->regs + MLB_SPI_TX_DWR);
	}

	if (rxdesc)
		wait_for_completion(&mspi->dma_rx_completion);
	if (txdesc)
		wait_for_completion(&mspi->dma_tx_completion);

	return 0;
}

static int milbeaut_spi_config(struct spi_device *spi)
{
	struct milbeaut_spi *mspi = spi_master_get_devdata(spi->master);

	writew_relaxed(MLB_SPI_INT_ALL_BIT_SET,
				mspi->regs + MLB_SPI_INT_CLR);
	writew_relaxed(MLB_SPI_INT_EN_XFERDONEPULSE,
				mspi->regs + MLB_SPI_INT_EN);
	writew_relaxed(0, mspi->regs + MLB_SPI_SLV_POL);
	writew_relaxed(0, mspi->regs + MLB_SPI_MS_DLY);
	writew_relaxed(readw_relaxed(mspi->regs + MLB_SPI_CTRL) |
			MLB_SPI_CTRL_MASTER, mspi->regs + MLB_SPI_CTRL);

	return 0;
}

static int milbeaut_spi_transfer_config(struct spi_device *spi)
{
	unsigned int div;
	unsigned int ctrl_value;
	struct milbeaut_spi *mspi = spi_master_get_devdata(spi->master);

	ctrl_value = readw_relaxed(mspi->regs + MLB_SPI_CTRL);
	ctrl_value &= MLB_SPI_CTRL_MASK;
	if (spi->mode & SPI_CPOL)
		ctrl_value |= MLB_SPI_CTRL_CPOL;
	if (spi->mode & SPI_CPHA)
		ctrl_value |= MLB_SPI_CTRL_CPHA;
	if (!(spi->mode & SPI_LSB_FIRST))
		ctrl_value |= MLB_SPI_CTRL_MSB1ST;
	mspi->max_freq = clk_get_rate(mspi->spiclk);
	if (mspi->speed != 0) {
		div = (mspi->max_freq / mspi->speed / 2) - 1;
		if (div < 0 || 255 < div) {
			dev_err(mspi->dev, "div value exceed error!\n");
			return -ERANGE;
		}
		writew_relaxed(div, mspi->regs + MLB_SPI_DIV);
		ctrl_value |= MLB_SPI_CTRL_DIVENABLE;
	} else
		writew_relaxed(0, mspi->regs + MLB_SPI_DIV);
	writew_relaxed(ctrl_value, mspi->regs + MLB_SPI_CTRL);
	writew_relaxed((readw_relaxed(mspi->regs + MLB_SPI_AUX_CTRL) &
			~MLB_SPI_AUX_CTRL_BITSIZE) |
			FIELD_PREP(MLB_SPI_AUX_CTRL_BITSIZE,
			(spi->bits_per_word - 1)),
			mspi->regs + MLB_SPI_AUX_CTRL);
	writew_relaxed(1 << spi->chip_select,
				mspi->regs + MLB_SPI_SLV_SEL);

	return 0;
}

static int milbeaut_spi_transfer_one(
		struct spi_master *master,
		struct spi_device *spi,
		struct spi_transfer *xfer)
{
	int ret;
	struct milbeaut_spi *mspi = spi_master_get_devdata(master);

	if (!xfer->tx_buf && !xfer->rx_buf) {
		dev_err(mspi->dev, "No buffer for transfer\n");
		return -EINVAL;
	}
	if (xfer->len == 0) {
		dev_err(mspi->dev, "No length for transfer\n");
		return -EINVAL;
	}
	mspi->speed = xfer->speed_hz;
	mspi->bpw = xfer->bits_per_word;
	mspi->n_bytes = mspi->bpw >> 3;
	mspi->tx = xfer->tx_buf;
	mspi->rx = xfer->rx_buf;
	mspi->len = xfer->len;
	mspi->tx_sg = xfer->tx_sg;
	mspi->rx_sg = xfer->rx_sg;
	mspi->use_dma = master->can_dma &&
				master->can_dma(master, spi, xfer) &&
				mspi->have_dma;
	ret = milbeaut_spi_transfer_config(spi);
	if (ret)
		return ret;
	if (mspi->use_dma)
		ret = milbeaut_spi_prepare_dma(mspi);
	else
		ret = milbeaut_spi_pio_transfer(mspi);

	return ret;
}

static bool milbeaut_spi_can_dma(struct spi_master *master,
				 struct spi_device *spi,
				 struct spi_transfer *xfer)
{
	struct milbeaut_spi *mspi = spi_master_get_devdata(master);

	return (xfer->len > mspi->fifo_len);
}

static void milbeaut_spi_pre_config(struct milbeaut_spi *mspi,
						u8 chip_select)
{
	if (mspi->ssout_cont[chip_select] ==
			MLB_SPI_CONT_TRANS_ACT_FIFO_EMPTY) {
		writew_relaxed(readw_relaxed(mspi->regs + MLB_SPI_CTRL) |
			MLB_SPI_CTRL_CONTXFER, mspi->regs + MLB_SPI_CTRL);
		writew_relaxed(readw_relaxed(mspi->regs + MLB_SPI_AUX_CTRL) |
			MLB_SPI_AUX_CTRL_CONTXFEREXTEND,
				mspi->regs + MLB_SPI_AUX_CTRL);
	} else if (mspi->ssout_cont[chip_select] ==
			MLB_SPI_CONT_TRANS_INACT_FIFO_EMPTY)
		writew_relaxed(readw_relaxed(mspi->regs + MLB_SPI_CTRL) |
			MLB_SPI_CTRL_CONTXFER, mspi->regs + MLB_SPI_CTRL);
}

static void milbeaut_spi_set_cs(struct spi_device *spi, bool enable)
{
	struct milbeaut_spi *mspi = spi_master_get_devdata(spi->master);

	if (enable)
		milbeaut_spi_end_process(mspi);
	else
		milbeaut_spi_pre_config(mspi, spi->chip_select);
}

static void milbeaut_spi_dma_exit(struct milbeaut_spi *mspi)
{
	if (mspi->dma_rx.ch) {
		dma_release_channel(mspi->dma_rx.ch);
		mspi->dma_rx.ch = NULL;
	}
	if (mspi->dma_tx.ch) {
		dma_release_channel(mspi->dma_tx.ch);
		mspi->dma_tx.ch = NULL;
	}
}

static int milbeaut_spi_dma_init(struct device *dev, struct milbeaut_spi *mspi,
			     struct spi_master *master)
{
	int ret;

	mspi->dma_tx.ch = dma_request_slave_channel_reason(dev, "tx");
	if (IS_ERR(mspi->dma_tx.ch)) {
		ret = PTR_ERR(mspi->dma_tx.ch);
		pr_err("%s: can't get the TX DMA channel\n", __func__);
		mspi->dma_tx.ch = NULL;
		goto err;
	}
	mspi->dma_rx.ch = dma_request_slave_channel_reason(dev, "rx");
	if (IS_ERR(mspi->dma_rx.ch)) {
		ret = PTR_ERR(mspi->dma_rx.ch);
		pr_err("%s: can't get the RX DMA channel\n", __func__);
		master->dma_rx = NULL;
		goto err;
	}
	init_completion(&mspi->dma_rx_completion);
	init_completion(&mspi->dma_tx_completion);
	master->can_dma = milbeaut_spi_can_dma;
	master->max_dma_len = MLB_SPI_MAX_DMA_BYTES;
	writew_relaxed(readw_relaxed(mspi->regs + MLB_SPI_CTRL) |
			FIELD_PREP(MLB_SPI_CTRL_DMA, mspi->have_dma),
			mspi->regs + MLB_SPI_CTRL);

	return 0;
err:
	milbeaut_spi_dma_exit(mspi);
	return ret;
}

static int milbeaut_spi_probe(struct platform_device *pdev)
{
	int n = 0;
	int irq_err, ret;
	u32 num_cs;
	struct milbeaut_spi *mspi;
	struct resource *res;
	struct spi_master *master;
	struct device_node *child;
	resource_size_t irq;

	master = spi_alloc_master(&pdev->dev, sizeof(struct milbeaut_spi));
	if (!master){
		return -ENOMEM;
	}
	platform_set_drvdata(pdev, master);
	mspi = spi_master_get_devdata(master);
	memset(mspi, 0, sizeof(struct milbeaut_spi));
	mspi->regs = of_iomap(pdev->dev.of_node, 0);
	if (IS_ERR(mspi->regs)) {
		ret =  PTR_ERR(mspi->regs);
		goto err_ioremap_resource;
	}
	res = platform_get_resource(pdev, IORESOURCE_MEM, 0);
	mspi->base_phys = res->start;
	if (of_property_read_u32(pdev->dev.of_node, "num-cs", &num_cs))
		num_cs = MLB_SPI_CS_MAX;
	else {
		if (num_cs > MLB_SPI_CS_MAX)
			num_cs = MLB_SPI_CS_MAX;
	}
	master->num_chipselect = num_cs;
	for_each_available_child_of_node(pdev->dev.of_node, child) {
		ret = of_property_read_u32(child, "ssout-cont",
				&mspi->ssout_cont[n]);
		if (ret)
			mspi->ssout_cont[n] = MLB_SPI_CONT_TRANS_ACT_FIFO_EMPTY;
		n++;
	}
	irq = platform_get_irq(pdev, 0);
	if (!irq) {
		dev_err(&pdev->dev, "could not get IRQ\n");
		goto err_ioremap_resource;
	}
	mspi->irq = irq;
	irq_err = devm_request_irq(&pdev->dev, mspi->irq,
			milbeaut_spi_int_handler, 0, "sni_spi", master);
	if (irq_err) {
		dev_err(&pdev->dev, "No IRQ found\n");
		goto err_ioremap_resource;
	}
	mspi->spiclk = devm_clk_get(&pdev->dev, NULL);
	if (IS_ERR(mspi->spiclk)) {
		dev_err(&pdev->dev, "Failed to get clk\n");
		ret = PTR_ERR(mspi->spiclk);
		goto err_ioremap_resource;
	}
	ret = clk_prepare_enable(mspi->spiclk);
	if (ret) {
		dev_err(&pdev->dev, "Failed to enable clk\n");
		goto err_spiclk_enable;
	}
	mspi->master = master;
	mspi->dev = &pdev->dev;
	mspi->max_freq = clk_get_rate(mspi->spiclk);
	ret = of_property_read_u32(pdev->dev.of_node,
						"fifo-size", &mspi->fifo_len);
	if (ret)
		mspi->fifo_len = 16;

	ret = dma_set_mask_and_coherent(&pdev->dev, DMA_BIT_MASK(40));

	ret = of_property_read_u32(pdev->dev.of_node,
				"dma-mode",
				(unsigned int *)&mspi->have_dma);
	if (ret)
		mspi->have_dma = 0;
	if (mspi->have_dma) {
		ret = milbeaut_spi_dma_init(&pdev->dev, mspi, master);
		if (ret)
			pr_err("%s: dma init error %d\n", __func__, ret);
	}
	spin_lock_init(&mspi->lock);
	pm_runtime_set_active(&pdev->dev);
	pm_runtime_enable(&pdev->dev);
	master->auto_runtime_pm = true;
	master->bus_num = pdev->id;
	master->mode_bits = SPI_CPOL | SPI_CPHA | SPI_LOOP | SPI_LSB_FIRST;
	master->dev.of_node = pdev->dev.of_node;
	master->set_cs = milbeaut_spi_set_cs;
	master->prepare_message = milbeaut_spi_prepare_message;
	master->unprepare_message = milbeaut_spi_unprepare_message;
	master->transfer_one = milbeaut_spi_transfer_one;
	master->setup = milbeaut_spi_config;
	master->can_dma = milbeaut_spi_can_dma;
	ret = devm_spi_register_master(&pdev->dev, master);
	if (ret) {
		dev_err(&pdev->dev, "Failed to register master\n");
		goto err_register_master;
	}

	return 0;

err_register_master:
	milbeaut_spi_dma_exit(mspi);
	clk_disable_unprepare(mspi->spiclk);
err_spiclk_enable:
err_ioremap_resource:
	spi_master_put(master);

	return ret;
}

static int milbeaut_spi_remove(struct platform_device *pdev)
{
	struct spi_master *master = spi_master_get(platform_get_drvdata(pdev));
	struct milbeaut_spi *mspi = spi_master_get_devdata(master);

	pm_runtime_disable(&pdev->dev);
	milbeaut_spi_dma_exit(mspi);

	return 0;
}

#ifdef CONFIG_PM_SLEEP
static int milbeaut_spi_suspend(struct device *dev)
{
	int ret;
	struct spi_master *master = dev_get_drvdata(dev);
	struct milbeaut_spi *mspi = spi_master_get_devdata(master);

	ret = spi_master_suspend(mspi->master);
	if (ret < 0)
		return ret;
	if (!pm_runtime_suspended(dev))
		clk_disable_unprepare(mspi->spiclk);

	return ret;
}

static int milbeaut_spi_resume(struct device *dev)
{
	int ret;
	struct spi_master *master = dev_get_drvdata(dev);
	struct milbeaut_spi *mspi = spi_master_get_devdata(master);

	if (!pm_runtime_suspended(dev)) {
		ret = clk_prepare_enable(mspi->spiclk);
		if (ret < 0)
			return ret;
	}
	ret = spi_master_resume(mspi->master);
	if (ret < 0)
		clk_disable_unprepare(mspi->spiclk);

	return ret;
}
#endif /* CONFIG_PM_SLEEP */

#ifdef CONFIG_PM
static int milbeaut_spi_runtime_suspend(struct device *dev)
{
	struct spi_master *master = dev_get_drvdata(dev);
	struct milbeaut_spi *mspi = spi_master_get_devdata(master);

	clk_disable_unprepare(mspi->spiclk);

	return 0;
}

static int milbeaut_spi_runtime_resume(struct device *dev)
{
	struct spi_master *master = dev_get_drvdata(dev);
	struct milbeaut_spi *mspi = spi_master_get_devdata(master);

	return clk_prepare_enable(mspi->spiclk);
}
#endif /* CONFIG_PM */

static const struct dev_pm_ops milbeaut_spi_pm = {
	SET_SYSTEM_SLEEP_PM_OPS(milbeaut_spi_suspend, milbeaut_spi_resume)
	SET_RUNTIME_PM_OPS(milbeaut_spi_runtime_suspend,
			   milbeaut_spi_runtime_resume, NULL)
};

static const struct of_device_id milbeaut_spi_dt_match[] = {
	{ .compatible = "socionext,milbeaut-spi", },
	{ },
};
MODULE_DEVICE_TABLE(of, milbeaut_spi_dt_match);

static struct platform_driver milbeaut_spi_driver = {
	.driver = {
		.name	= "spi-milbeaut",
		.pm = &milbeaut_spi_pm,
		.of_match_table = of_match_ptr(milbeaut_spi_dt_match),
	},
	.probe = milbeaut_spi_probe,
	.remove = milbeaut_spi_remove,
};

module_platform_driver(milbeaut_spi_driver);

MODULE_AUTHOR("Shinji Kanematsu <<REDACTED_EMAIL>>");
MODULE_DESCRIPTION("Milbeaut SPI");
MODULE_LICENSE("GPL v2");
