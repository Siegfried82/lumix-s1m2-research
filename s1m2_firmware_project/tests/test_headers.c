/* SPDX-License-Identifier: MIT */
/**
 * @file test_headers.c
 * @brief Unit tests for Panasonic LUMIX S1M2 C headers, offsets, alignments and constants.
 */

#include <stdio.h>
#include <stdlib.h>
#include <stddef.h>
#include <assert.h>

#include "s1m2_types.h"
#include "s1m2_mmap.h"
#include "s1m2_ipcu.h"
#include "s1m2_dsp_xm6.h"
#include "s1m2_npu_cnn.h"
#include "s1m2_eeprom.h"
#include "s1m2_ptp_proto.h"

int main(void) {
    printf("[TEST] Running C Header Static Verification...\n");

    /* 1. Verify Shared Memory Table Offsets */
    assert(offsetof(struct s1m2_shmem_control_table, ipcu_buffer_addr) == S1M2_SHMEM_IPCU_BUF_ADDR_OFF);
    assert(offsetof(struct s1m2_shmem_control_table, ipcu_buffer_size) == S1M2_SHMEM_IPCU_BUF_SIZE_OFF);
    assert(offsetof(struct s1m2_shmem_control_table, ipcu_sync_addr)   == S1M2_SHMEM_IPCU_SYNC_ADDR_OFF);
    assert(offsetof(struct s1m2_shmem_control_table, ipcu_sync_size)   == S1M2_SHMEM_IPCU_SYNC_SIZE_OFF);
    assert(offsetof(struct s1m2_shmem_control_table, movie_buffer_addr) == S1M2_SHMEM_MOVIE_ADDR_OFF);
    assert(offsetof(struct s1m2_shmem_control_table, movie_buffer_size) == S1M2_SHMEM_MOVIE_SIZE_OFF);
    assert(offsetof(struct s1m2_shmem_control_table, audio_buffer_addr) == S1M2_SHMEM_AUDIO_ADDR_OFF);
    assert(offsetof(struct s1m2_shmem_control_table, audio_buffer_size) == S1M2_SHMEM_AUDIO_SIZE_OFF);
    assert(sizeof(struct s1m2_shmem_control_table) == 512);

    /* 2. Verify IPCU Framing & Offsets */
    assert(sizeof(T_IPCU_IF) == 28);
    assert(sizeof(T_IPCU_IF_CARD_DETECT) == 12);
    assert(sizeof(struct io_sni_ipcu_mbox) == 128); /* 32 words * 4 bytes */

    /* 3. Verify ipcufs Actions */
    assert(IFSA_MOUNTING == 0x2000);
    assert(IFSA_UMOUNTING == 0x2001);
    assert(IFSA_LOOKUP == 0x2002);
    assert(IFSA_READDIR == 0x2003);
    assert(IFSA_READPAGE == 0x2004);
    assert(IFSA_WRITEPAGE == 0x2005);
    assert(IFSA_IGET == 0x2006);
    assert(IFSA_CLOSE == 0x200C);

    /* 4. Verify vblk Actions */
    assert(VBLK_GETGEO == 0x3000);
    assert(VBLK_READ == 0x3001);
    assert(VBLK_WRITE == 0x3002);

    /* 5. Verify CEVA XM6 Memory Sizes */
    assert(S1M2_DSP_ITCM_SIZE == 64 * 1024);
    assert(S1M2_DSP_DTCM_SIZE == 512 * 1024);
    assert(S1M2_FSTACK_PING_PONG_FOOTPRINT <= S1M2_DSP_DTCM_SIZE);

    /* 6. Verify CNN Model IDs & Sizes */
    assert(S1M2_CNN_MODEL_NW_1ST == 50);
    assert(S1M2_CNN_MODEL_NW_9TH == 58);
    assert(S1M2_CNN_MODEL_REID == 59);
    assert(S1M2_CNN_MODEL_AI_AWB == 60);

    /* 7. Verify EEPROM Sizes & Offsets */
    assert(sizeof(struct s1m2_eep_license_slot) == 512);
    assert(sizeof(struct s1m2_eep_adj) == 128 * 1024);
    assert(sizeof(struct s1m2_eep_fix) == 128 * 1024);
    assert(sizeof(struct s1m2_eep_history) == 256 * 1024);

    assert(S1M2_FLASH_EEP_ACT_A_OFF == 0x05560000U);
    assert(S1M2_FLASH_EEP_ACT_B_OFF == 0x05580000U);

    /* 8. Verify PTP Vendor OpCodes & Framing */
    assert(S1M2_PTP_OP_GET_PROPERTY == 0x9402U);
    assert(S1M2_PTP_OP_SET_PROPERTY == 0x9403U);
    assert(S1M2_PTP_OP_SETUP_CTRL == 0x9406U);
    assert(S1M2_PTP_OP_GET_SETUP_CONFIG == 0x9421U);
    assert(S1M2_PTP_OP_SET_SETUP_CONFIG == 0x9422U);
    assert(S1M2_PTP_OP_SET_SETUP_NAME == 0x9423U);
    assert(S1M2_PTP_OP_FWUP_SEND_DATA_INFO == 0x9606U);
    assert(S1M2_PTP_OP_FWUP_SEND_DATA == 0x9607U);
    assert(S1M2_PTP_FWUP_CHUNK_SIZE == 512000U);

    /* 9. Verify PTP Wire Structures and Field Offsets */
    assert(sizeof(struct s1m2_ptp_prop_tlv_hdr) == 8);
    assert(sizeof(struct s1m2_ptp_prop_record_u16) == 10);
    assert(offsetof(struct s1m2_ptp_prop_record_u16, tag) == 0);
    assert(offsetof(struct s1m2_ptp_prop_record_u16, len) == 4);
    assert(offsetof(struct s1m2_ptp_prop_record_u16, val) == 8);

    assert(sizeof(struct s1m2_ptp_fwup_send_data_info_u32) == 12);
    assert(offsetof(struct s1m2_ptp_fwup_send_data_info_u32, total_transfer_size) == 0);
    assert(offsetof(struct s1m2_ptp_fwup_send_data_info_u32, target_address) == 4);
    assert(offsetof(struct s1m2_ptp_fwup_send_data_info_u32, data_type) == 8);

    assert(sizeof(struct s1m2_ptp_fwup_send_data_info_u64) == 16);
    assert(offsetof(struct s1m2_ptp_fwup_send_data_info_u64, total_transfer_size) == 0);
    assert(offsetof(struct s1m2_ptp_fwup_send_data_info_u64, target_address) == 4);
    assert(offsetof(struct s1m2_ptp_fwup_send_data_info_u64, data_type) == 12);

    assert(sizeof(struct s1m2_ptp_setup_ctrl_req) == 12);
    assert(offsetof(struct s1m2_ptp_setup_ctrl_req, subcode) == 0);
    assert(offsetof(struct s1m2_ptp_setup_ctrl_req, num_params) == 4);
    assert(offsetof(struct s1m2_ptp_setup_ctrl_req, reserved) == 6);
    assert(offsetof(struct s1m2_ptp_setup_ctrl_req, params) == 8);

    assert(S1M2_DRIVEMODE_READ_SINGLE == 0x0000U);
    assert(S1M2_DRIVEMODE_READ_HRS == 0x000AU);

    printf("[TEST] All header assertions passed successfully!\n");
    return 0;
}
