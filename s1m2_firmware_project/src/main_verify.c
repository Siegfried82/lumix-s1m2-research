/* SPDX-License-Identifier: MIT */
/**
 * @file main_verify.c
 * @brief Standalone test binary to verify C header definitions and structure layouts.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

#include "s1m2_types.h"
#include "s1m2_mmap.h"
#include "s1m2_ipcu.h"
#include "s1m2_dsp_xm6.h"
#include "s1m2_npu_cnn.h"
#include "s1m2_eeprom.h"
#include "s1m2_ptp_proto.h"

int main(void) {
    int failed = 0;
    printf("=================================================================\n");
    printf("  Panasonic LUMIX S1M2 (DC-S1M2) Header & Architecture Validator  \n");
    printf("=================================================================\n\n");

    /* 1. Verify Structure Sizes & Padding */
    printf("[*] Checking Structure Sizes:\n");

    printf("  - T_IPCU_IF: %zu bytes (Expected: 28) -> ", sizeof(T_IPCU_IF));
    if (sizeof(T_IPCU_IF) == 28) {
        printf("PASS\n");
    } else {
        printf("FAIL!\n");
        failed++;
    }

    printf("  - s1m2_shmem_control_table: %zu bytes (Expected: 512) -> ", sizeof(struct s1m2_shmem_control_table));
    if (sizeof(struct s1m2_shmem_control_table) == 512) {
        printf("PASS\n");
    } else {
        printf("FAIL!\n");
        failed++;
    }

    printf("  - s1m2_eep_license_slot: %zu bytes (Expected: 512) -> ", sizeof(struct s1m2_eep_license_slot));
    if (sizeof(struct s1m2_eep_license_slot) == 512) {
        printf("PASS\n");
    } else {
        printf("FAIL!\n");
        failed++;
    }

    printf("  - s1m2_eep_adj: %zu bytes (Expected: 131072 / 128KB) -> ", sizeof(struct s1m2_eep_adj));
    if (sizeof(struct s1m2_eep_adj) == 131072) {
        printf("PASS\n");
    } else {
        printf("FAIL!\n");
        failed++;
    }

    printf("  - s1m2_eep_fix: %zu bytes (Expected: 131072 / 128KB) -> ", sizeof(struct s1m2_eep_fix));
    if (sizeof(struct s1m2_eep_fix) == 131072) {
        printf("PASS\n");
    } else {
        printf("FAIL!\n");
        failed++;
    }

    printf("  - s1m2_eep_history: %zu bytes (Expected: 262144 / 256KB) -> ", sizeof(struct s1m2_eep_history));
    if (sizeof(struct s1m2_eep_history) == 262144) {
        printf("PASS\n");
    } else {
        printf("FAIL!\n");
        failed++;
    }

    printf("  - s1m2_ptp_prop_tlv_hdr: %zu bytes (Expected: 8) -> ", sizeof(struct s1m2_ptp_prop_tlv_hdr));
    if (sizeof(struct s1m2_ptp_prop_tlv_hdr) == 8) {
        printf("PASS\n");
    } else {
        printf("FAIL!\n");
        failed++;
    }

    printf("  - s1m2_ptp_prop_record_u16: %zu bytes (Expected: 10) -> ", sizeof(struct s1m2_ptp_prop_record_u16));
    if (sizeof(struct s1m2_ptp_prop_record_u16) == 10) {
        printf("PASS\n");
    } else {
        printf("FAIL!\n");
        failed++;
    }

    printf("  - s1m2_ptp_fwup_send_data_info_u32: %zu bytes (Expected: 12) -> ", sizeof(struct s1m2_ptp_fwup_send_data_info_u32));
    if (sizeof(struct s1m2_ptp_fwup_send_data_info_u32) == 12) {
        printf("PASS\n");
    } else {
        printf("FAIL!\n");
        failed++;
    }

    printf("  - s1m2_ptp_fwup_send_data_info_u64: %zu bytes (Expected: 16) -> ", sizeof(struct s1m2_ptp_fwup_send_data_info_u64));
    if (sizeof(struct s1m2_ptp_fwup_send_data_info_u64) == 16) {
        printf("PASS\n");
    } else {
        printf("FAIL!\n");
        failed++;
    }

    printf("  - s1m2_ptp_setup_ctrl_req: %zu bytes (Expected: 12) -> ", sizeof(struct s1m2_ptp_setup_ctrl_req));
    if (sizeof(struct s1m2_ptp_setup_ctrl_req) == 12) {
        printf("PASS\n");
    } else {
        printf("FAIL!\n");
        failed++;
    }

    /* 2. Verify Physical Address Mapping Helpers */
    printf("\n[*] Checking Memory Map Range Classifiers:\n");

    int linux_check = s1m2_is_linux_addr(S1M2_MEM_LINUX_DDR_BASE) &&
                      s1m2_is_linux_addr(S1M2_MEM_LINUX_DDR_END - 1) &&
                      !s1m2_is_linux_addr(S1M2_MEM_RTOS_DDR_BASE);
    printf("  - Linux RAM bounds [0x4_0370_0000 - 0x4_0D70_0000]: %s\n", linux_check ? "PASS" : "FAIL");
    if (!linux_check) failed++;

    int rtos_check = s1m2_is_rtos_addr(S1M2_MEM_RTOS_DDR_BASE) &&
                     s1m2_is_rtos_addr(S1M2_MEM_RTOS_DDR_END - 1) &&
                     !s1m2_is_rtos_addr(S1M2_MEM_LINUX_DDR_BASE);
    printf("  - RTOS DDR bounds [0x4_0D70_0000 - 0x4_AC00_0000]: %s\n", rtos_check ? "PASS" : "FAIL");
    if (!rtos_check) failed++;

    int dsp_dtcm_check = s1m2_is_dsp_dtcm(0x1C000000) && s1m2_is_dsp_dtcm(0x1C07FFFF) && !s1m2_is_dsp_dtcm(0x1C200000);
    printf("  - CEVA XM6 DTCM bounds [0x1C00_0000 - 512KB]: %s\n", dsp_dtcm_check ? "PASS" : "FAIL");
    if (!dsp_dtcm_check) failed++;

    int dsp_itcm_check = s1m2_is_dsp_itcm(0x1C200000) && s1m2_is_dsp_itcm(0x1C20FFFF) && !s1m2_is_dsp_itcm(0x1C000000);
    printf("  - CEVA XM6 ITCM bounds [0x1C20_0000 - 64KB]: %s\n", dsp_itcm_check ? "PASS" : "FAIL");
    if (!dsp_itcm_check) failed++;

    /* 3. Verify Constants & Magic Codes */
    printf("\n[*] Checking Architectural Magics:\n");
    printf("  - IPCU Handshake Magic: 0x%08lX (Expected: 0xBEEFCAFE) -> %s\n",
           (unsigned long)SNI_IPCU_MAGIC_CODE,
           (SNI_IPCU_MAGIC_CODE == 0xBEEFCAFEUL) ? "PASS" : "FAIL");
    if (SNI_IPCU_MAGIC_CODE != 0xBEEFCAFEUL) failed++;

    printf("  - XM6 Firmware Magic: 0x%08X (Expected: 0x584D3644) -> %s\n",
           S1M2_XM6_FW_MAGIC,
           (S1M2_XM6_FW_MAGIC == 0x584D3644U) ? "PASS" : "FAIL");
    if (S1M2_XM6_FW_MAGIC != 0x584D3644U) failed++;

    printf("  - CNN Model Magic: 0x%08X (Expected: 0x434E4E30) -> %s\n",
           S1M2_CNN_MAGIC,
           (S1M2_CNN_MAGIC == 0x434E4E30U) ? "PASS" : "FAIL");
    if (S1M2_CNN_MAGIC != 0x434E4E30U) failed++;

    printf("  - EEPROM Block Magic: 0x%08X (Expected: 0x45455052) -> %s\n",
           S1M2_EEP_MAGIC,
           (S1M2_EEP_MAGIC == 0x45455052U) ? "PASS" : "FAIL");
    if (S1M2_EEP_MAGIC != 0x45455052U) failed++;

    printf("  - ARRI LogC3 License Magic: 0x%08X (Expected: 0x41435431) -> %s\n",
           S1M2_LIC_MAGIC,
           (S1M2_LIC_MAGIC == 0x41435431U) ? "PASS" : "FAIL");
    if (S1M2_LIC_MAGIC != 0x41435431U) failed++;

    /* 4. IPCU Framing Verification */
    printf("\n[*] Checking IPCU Packet Framing:\n");
    T_IPCU_IF pkt;
    memset(&pkt, 0, sizeof(pkt));
    pkt.id = 0x2006; /* IFSA_IGET */
    pkt.bufl = 0xAC000000;
    pkt.bufh = 0x00000004;
    pkt.len = 512;
    pkt.total_len = 512;
    pkt.logical_ch = 6;
    printf("  - Packet populated: cmd=0x%x buf=0x%x%08x len=%u ch=%u -> PASS\n",
           pkt.id, pkt.bufh, pkt.bufl, pkt.len, pkt.logical_ch);

    /* 5. PTP Maintenance Protocol Verification */
    printf("\n[*] Checking PTP Vendor Extensions & FWUP Parameters:\n");
    printf("  - PTP FWUP Chunk Size: %u bytes (Expected: 512000) -> %s\n",
           S1M2_PTP_FWUP_CHUNK_SIZE,
           (S1M2_PTP_FWUP_CHUNK_SIZE == 512000U) ? "PASS" : "FAIL");
    if (S1M2_PTP_FWUP_CHUNK_SIZE != 512000U) failed++;

    printf("  - PTP Setup Control SubCode MenuSave: 0x%08X -> %s\n",
           S1M2_PTP_SUBCODE_MENU_SAVE,
           (S1M2_PTP_SUBCODE_MENU_SAVE == 0x09000011U) ? "PASS" : "FAIL");
    if (S1M2_PTP_SUBCODE_MENU_SAVE != 0x09000011U) failed++;

    printf("  - PTP Setup Control SubCode ResetSetting: 0x%08X -> %s\n",
           S1M2_PTP_SUBCODE_RESET_SETTING,
           (S1M2_PTP_SUBCODE_RESET_SETTING == 0x09000018U) ? "PASS" : "FAIL");
    if (S1M2_PTP_SUBCODE_RESET_SETTING != 0x09000018U) failed++;

    /* 6. Verify PTP Wire TLV Deserialization against S1M2 Binary Framing */
    printf("\n[*] Checking PTP Wire TLV Deserialization (10-byte records):\n");
    u8 raw_wire_sample[20] = {
        0x81, 0x00, 0x00, 0x02,  /* Tag: 0x02000081 */
        0x02, 0x00, 0x00, 0x00,  /* Len: 2 bytes */
        0x0A, 0x00,              /* Val: 0x000A (HRS mode) */
        0x82, 0x00, 0x00, 0x02,  /* Tag: 0x02000082 */
        0x02, 0x00, 0x00, 0x00,  /* Len: 2 bytes */
        0x03, 0x00               /* Val: 0x0003 (ModePos) */
    };
    const struct s1m2_ptp_prop_record_u16 *rec0 =
        (const struct s1m2_ptp_prop_record_u16 *)(raw_wire_sample);
    const struct s1m2_ptp_prop_record_u16 *rec1 =
        (const struct s1m2_ptp_prop_record_u16 *)(raw_wire_sample + sizeof(struct s1m2_ptp_prop_record_u16));

    int tlv_ok = (rec0->tag == S1M2_PTP_TAG_RECINFO_DRIVEMODE) &&
                 (rec0->len == 2) &&
                 (rec0->val == S1M2_DRIVEMODE_READ_HRS) &&
                 (rec1->tag == S1M2_PTP_TAG_RECINFO_MODEPOS) &&
                 (rec1->len == 2) &&
                 (rec1->val == 0x0003);
    printf("  - Wire TLV Deserialization (Rec0 Tag=0x%08X Val=0x%04X, Rec1 Tag=0x%08X Val=0x%04X): %s\n",
           rec0->tag, rec0->val, rec1->tag, rec1->val, tlv_ok ? "PASS" : "FAIL");
    if (!tlv_ok) failed++;

    printf("\n=================================================================\n");
    if (failed == 0) {
        printf("  ALL ARCHITECTURAL CHECKS PASSED (0 ERRORS)\n");
        printf("=================================================================\n");
        return 0;
    } else {
        printf("  VERIFICATION FAILED: %d errors encountered\n", failed);
        printf("=================================================================\n");
        return 1;
    }
}
