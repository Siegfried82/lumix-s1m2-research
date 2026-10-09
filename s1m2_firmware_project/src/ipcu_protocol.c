/* SPDX-License-Identifier: MIT */
/**
 * @file ipcu_protocol.c
 * @brief IPCU message packet framing and protocol validation routines.
 */

#include "s1m2_ipcu.h"
#include <string.h>

int s1m2_ipcu_pack_message(T_IPCU_IF *pkt, u32 cmd_id, phys_addr_t phys_buf, u32 len, u32 ch) {
    if (!pkt) {
        return -1;
    }
    pkt->id = cmd_id;
    pkt->bufl = (u32)(phys_buf & 0xFFFFFFFFULL);
    pkt->bufh = (u32)((phys_buf >> 32) & 0xFFFFFFFFULL);
    pkt->len = len;
    pkt->cont = 0;
    pkt->total_len = len;
    pkt->logical_ch = ch;
    return 0;
}

int s1m2_ipcu_verify_magic(u64 val) {
    u32 low = (u32)(val & 0xFFFFFFFFULL);
    if (low == SNI_IPCU_MAGIC_CODE || val == (u64)SNI_IPCU_MAGIC_CODE) {
        return 0;
    }
    return -1;
}

int s1m2_ipcu_format_card_detect(T_IPCU_IF_CARD_DETECT *pkt, u32 slot, bool inserted) {
    if (!pkt) {
        return -1;
    }
    pkt->command = 1; /* IPCU_CARD_DETECT_COMMAND */
    pkt->card_state = inserted ? 1 : 0;
    pkt->ch = slot;
    return 0;
}
