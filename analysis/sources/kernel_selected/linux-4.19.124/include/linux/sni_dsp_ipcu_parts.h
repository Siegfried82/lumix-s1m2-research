/**
 * @file sni_dsp_ipcu_parts.h
 * @author
 * @date  
 * @brief SNI IPCU Parts
 */
/* Copyright 2015 Socionext Inc. */

#ifndef __SNI_DSP_IPCU_PARTS_H
#define __SNI_DSP_IPCU_PARTS_H


#include <linux/types.h>
#include <linux/completion.h>
#include <linux/dma-mapping.h>
#include <linux/miscdevice.h>


/* definition of interface constant value */
#define SNI_DSP_IPCU_DIR_INIT 0
#define SNI_DSP_IPCU_DIR_SEND 1
#define SNI_DSP_IPCU_DIR_RECV 2

#define SNI_DSP_IPCU_CHSTAT_OPEN 1  /* this mb is used by someone    */
#define SNI_DSP_IPCU_CHSTAT_IGN  2  /* this mb is ignored after user */

/* make a bitmap data from mb_id */
#define SNI_DSP_IPCU_BITMAP(id) (1 << (id))

/**
 * @brief Tentative definition
 */
#define IPCU_MAX_DEPTH 256
#define IPCU_MAX_LEN   2048
#define IPCU_MAX_MB    (8)
#define IPCU_MAX_CH    (6)
#define IPCU_MAX_DATA  9

/**
 * @brifef data body definition for static reserved.
 */
//struct sni_dsp_ipcu_data {
//    u32 array[IPCU_MAX_DEPTH][IPCU_MAX_LEN / sizeof( u32 )];
//};

/**
 * @note
 * memory map between CPUs. this memory area is configured to uncacheable.
 * for RTOS developer, memory map image is described as follows:
 *
 */
struct sni_dsp_ipcu_mb_config {
    u32 mb_id;     /* mb id                                     */
    u32 direction;      /* data direction 1:Linux->RTOS 2:RTOS->Linux     */
    u32 stat_tx;        /* status of TX mb                           */
    u32 stat_rx;        /* status of RX mb                           */
    u32 data_size;      /* size of data, in Bytes.                        */
    u32 data_depth;     /* number of data.                                */
    u32 offset2dat;     /* offset from top of shared memory between CPUs. */
    u32 rd_idx;
    u32 wr_idx;
    u32 data[IPCU_MAX_DATA];
//    struct sni_dsp_ipcu_data data;
};

struct sni_dsp_ipcu_device {
	struct miscdevice miscdev;
	char devname[24];
	struct mutex mlock;
	unsigned dest_mb;     /* destination mailbox i/f */
};

struct ipcu_driver_info {
	void __iomem *ipcu_io_mem;
	unsigned int dest_mb[IPCU_MAX_MB];
	unsigned int dst_int_ch[IPCU_MAX_CH];
	unsigned int src_int_ch[IPCU_MAX_CH];
	int ipcu_rec_irq[IPCU_MAX_CH];
	int ipcu_ack_irq[IPCU_MAX_CH];
	struct mutex mb_mutex[IPCU_MAX_MB];
	struct completion ack_notify[IPCU_MAX_CH];
	struct device *dev;
};

extern struct ipcu_driver_info ipcu_dsp_drv_inf;

/**
 *@brief initialize IPCU.
 *
 */
int sni_dsp_ipcu_mb_init(u32 mb, u32 direction, void* ipcu_dev);

/**
 *@brief exit IPCU.
 *
 */
void sni_dsp_ipcu_mb_exit(u32 mb, void* ipcu_dev);

/**
 *@brief Open mailbox.
 *
 */
int sni_dsp_ipcu_openmb(u32 mb, u32 direction);

/**
 *@brief Close mb.
 *
 */
int sni_dsp_ipcu_closemb(u32 mb, u32 direction);

/**
 * @brief Send Message
 */
int sni_dsp_ipcu_send_msg(u32 mb, void* buf, u32 len, u32 flags);

/**
 * @brief Recive Message
 */
int sni_dsp_ipcu_recv_msg(u32 mb, void* buf, u32 len, u32 flags);

/**
 * @brief Send Ack
 */
int sni_dsp_ipcu_ack_send(u32 mb);

/**
 * @brief Recive Message flash
 */
int sni_dsp_ipcu_recv_flsh(u32 mb);

/**
 * @brief mapping memory
 */
dma_addr_t dsp_ipcu_dma_map_single(void *ptr,
				size_t size,
				enum dma_data_direction dir);

/**
 * @brief unmapping memory
 */
void dsp_ipcu_dma_unmap_single(dma_addr_t addr,
				size_t size,
				enum dma_data_direction dir);

#endif  /* __SNI_DSP_IPCU_PARTS_H */
