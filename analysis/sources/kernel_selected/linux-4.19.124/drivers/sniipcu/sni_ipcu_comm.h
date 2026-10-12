/*
 * Copyright (C) 2015 Socionext Semiconductor Ltd.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 2 of the License.
 *
 * @file   sni_ipcu_comm.h
 * @author
 * @date
 * @brief  SNI IPCU Communication
 */

#ifndef __SNI_IPCU_COMM_H
#define __SNI_IPCU_COMM_H

#include <linux/completion.h>


#define IO_IPCU_INT_REQ         (0)
#define IO_IPCU_INT_ACK_UNIT    (8)

#define IO_IPCU_MBX_DATA_MAX    (9)
#define IO_IPCU_MBX_CPU0_NUM    (4)

#define IO_IPCU_ACK_MANI_MODE1  (0)
#define IO_IPCU_ACK_MANI_MODE2  (1)
#define IO_IPCU_ACK_AUTO_MODE1  (2)
#define IO_IPCU_ACK_AUTO_MODE2  (3)
#define IO_IPCU_ACK_ATCL_MODE   (4)


struct io_sni_ipcu_mbox {
	u32 source;
	u32 mode;
	u32 send;
	u32 _reserved_mb0;
	u32 dest_set;
	u32 dest_clr;
	u32 dest_stat;
	u32 _reserved_mb1;
	u32 mask_set;
	u32 mask_clr;
	u32 mask_stat;
	u32 _reserved_mb2;
	u32 ack_set;
	u32 ack_clr;
	u32 ack_stat;
	u32 ack_src;
	u32 data[IO_IPCU_MBX_DATA_MAX];
	u32 _reserved_mb[7];
};

struct io_sni_ipcu {
	u32	isr[16];   /* Interrupt Status Register */
	u32	_reserved0[16];
	u32	mbadr[16]; /* Mailbox Address Register  */
	u32	_reserved1[16];
	struct	io_sni_ipcu_mbox mailbox[8];
	u32	_reserved2[0x100];
	u32	mbstat;    /* Mailbox Status Register   */
};

extern int  sni_ipcu_comm_init(u32 unit, u32 ch);
extern int  sni_ipcu_send_req(u32 unit, u32 ch, u32 *data);
extern int  sni_ipcu_send_ack(u32 unit, u32 ch);
extern void sni_ipcu_handle_rec(int irq, u32 unit, u32 ch, u32 *data);
extern void sni_ipcu_handle_ack(int irq, u32 unit, u32 ch);

#endif	/* __SNI_IPCU_COMM_H */
