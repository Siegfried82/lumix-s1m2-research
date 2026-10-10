/* Host-side PTP observations; only saved responses were device-validated.
 * Declarations do not prove all commands are supported by S1M2.
 */
/* SPDX-License-Identifier: MIT */
/**
 * @file s1m2_ptp_proto.h
 * @brief Panasonic LUMIX S1M2 Private PTP Vendor Extensions & Protocol Structures.
 *
 * Target: Panasonic LUMIX S1M2 (DC-S1M2)
 * Reverse engineered from:
 *   - LUMIX Tether 2.12 (libLmxptpif.dylib & LUMIX Tether ARM64)
 *   - S1M2 Service Manual (DSC2505007CE)
 *   - Saved read-only baseline responses plus static host update/write paths;
 *     firmware-update and write opcodes were not validated by sending them
 */

#ifndef S1M2_PTP_PROTO_H
#define S1M2_PTP_PROTO_H

#include "s1m2_types.h"

#ifdef __cplusplus
extern "C" {
#endif

/* ========================================================================= */
/* 1. Panasonic Vendor PTP Operation Codes (OpCodes)                         */
/* ========================================================================= */

#define S1M2_PTP_OP_GET_DEVICE_INFO_EX          0x9101U
#define S1M2_PTP_OP_GET_TAG_CAPABILITY          0x9108U
#define S1M2_PTP_OP_GET_STORAGE_INFO_EX         0x9114U
#define S1M2_PTP_OP_GET_PARTIAL_OBJECT_EX       0x9112U

#define S1M2_PTP_OP_GET_PROPERTY                0x9402U /* LmxExt_GetCameraModeInfo */
#define S1M2_PTP_OP_SET_PROPERTY                0x9403U /* LmxExt_SetCameraModeInfo */
#define S1M2_PTP_OP_SETUP_CTRL                  0x9406U /* LmxExt_Setup_Ctrl */
#define S1M2_PTP_OP_GET_MOV_FILTER_INFO         0x9408U
#define S1M2_PTP_OP_STORAGE_CTRL                0x940BU
#define S1M2_PTP_OP_POWER_CTRL                  0x940DU /* LmxExt_Power_Ctrl */
#define S1M2_PTP_OP_PLAY_CTRL                   0x940EU
#define S1M2_PTP_OP_LENS_ZOOM_INFO              0x9414U
#define S1M2_PTP_OP_REC_CTRL_MENU               0x9416U /* Touch coordinate relay */

#define S1M2_PTP_OP_GET_SETUP_CONFIG            0x9421U /* LmxExt_Get_SetupFilesConfigSet_Info */
#define S1M2_PTP_OP_SET_SETUP_CONFIG            0x9422U /* LmxExt_SetSetupFilesConfigSetInfo */
#define S1M2_PTP_OP_SET_SETUP_NAME              0x9423U /* LmxExt_SetSetupFilesConfigSet_Name */

/* Firmware Update Dedicated Channel (0x96xx) */
#define S1M2_PTP_OP_FWUP_CHG_EVENT              0x9603U /* LmxExt_ChgEvntType */
#define S1M2_PTP_OP_FWUP_GET_EVENT_INFO         0x9605U /* LmxExt_Get_Event_Info */
#define S1M2_PTP_OP_FWUP_SEND_DATA_INFO         0x9606U /* LmxExt_Send_Data_Info */
#define S1M2_PTP_OP_FWUP_SEND_DATA              0x9607U /* LmxExt_Send_Data */

/* Live View / Preview Stream (0x97xx) */
#define S1M2_PTP_OP_MNT_GET_INFO                0x9703U /* Version / USB Mode query */
#define S1M2_PTP_OP_GET_LV_STREAM               0x9706U
#define S1M2_PTP_OP_GET_LV_FRAME                0x9707U

/* Standard PTP Opcodes */
#define S1M2_PTP_OP_OPEN_SESSION                0x1002U
#define S1M2_PTP_OP_CLOSE_SESSION               0x1003U
#define S1M2_PTP_OP_INITIATE_CAPTURE            0x100EU

/* ========================================================================= */
/* 2. PTP Sub-Codes & Command Parameters                                     */
/* ========================================================================= */

/* Setup Control Sub-Codes (OpCode 0x9406) */
#define S1M2_PTP_SUBCODE_MENU_SAVE              0x09000011U
#define S1M2_PTP_SUBCODE_SD_FORMAT              0x09000012U
#define S1M2_PTP_SUBCODE_FWUP_PREP              0x09000013U
#define S1M2_PTP_SUBCODE_FWUP_DONE              0x09000014U
#define S1M2_PTP_SUBCODE_SENSOR_CLEANING        0x09000015U
#define S1M2_PTP_SUBCODE_PIXEL_REFRESH          0x09000016U
#define S1M2_PTP_SUBCODE_FWUP_ABORT             0x09000017U
#define S1M2_PTP_SUBCODE_RESET_SETTING          0x09000018U

/* Power Control Sub-Codes (OpCode 0x940d) */
#define S1M2_PTP_SUBCODE_POWER_OFF              0x0A000011U

/* Setup Config Stream Tags (OpCodes 0x9421 ~ 0x9423) */
#define S1M2_PTP_CONFIG_SET_DATA_TAG            0x080000A2U
#define S1M2_PTP_CONFIG_SET_NAME_TAG            0x080000A1U

/* Firmware Update Block Parameters */
#define S1M2_PTP_FWUP_CHUNK_SIZE                0x0007D000U /* 512,000 bytes (500 KB) */

/* ========================================================================= */
/* 3. Vendor Property Tags & Values                                          */
/* ========================================================================= */

/* Drive Mode Tags */
#define S1M2_PTP_TAG_DRIVEMODE_GET              0x02000080U /* LmxExt_GetCameraModeInfo tag */
#define S1M2_PTP_TAG_DRIVEMODE_SET              0x02000081U /* LmxExt_SetCameraModeInfo / TLV tag */
#define S1M2_PTP_TAG_DRIVEMODE_CAPA             0x02000080U

/* Real Camera Readback Values (Tag 0x02000081 uint16 payload) */
#define S1M2_DRIVEMODE_READ_SINGLE              0x0000U /* Observed in S1M2 single shot capture */
#define S1M2_DRIVEMODE_READ_BURST               0x0002U
#define S1M2_DRIVEMODE_READ_BRACKET             0x0003U
#define S1M2_DRIVEMODE_READ_SELFTIMER           0x0004U
#define S1M2_DRIVEMODE_READ_INTERVAL            0x0005U
#define S1M2_DRIVEMODE_READ_HRS                 0x000AU /* Observed in S1M2 high-res capture */

/* Client Application Enum Constants (Tether arrDriveModeVal indices 0..11) */
#define S1M2_DRIVEMODE_ENUM_NONE                0x0000U
#define S1M2_DRIVEMODE_ENUM_SINGLE              0x0001U
#define S1M2_DRIVEMODE_ENUM_BURST               0x0002U
#define S1M2_DRIVEMODE_ENUM_BRACKET             0x0003U
#define S1M2_DRIVEMODE_ENUM_SELFTIMER           0x0004U
#define S1M2_DRIVEMODE_ENUM_INTERVAL            0x0005U
#define S1M2_DRIVEMODE_ENUM_4K6K                0x0006U
#define S1M2_DRIVEMODE_ENUM_FOCUS               0x0007U
#define S1M2_DRIVEMODE_ENUM_BURST1              0x0008U
#define S1M2_DRIVEMODE_ENUM_BURST2              0x0009U
#define S1M2_DRIVEMODE_ENUM_HRS_TRIPOD          0x000AU /* arrDriveModeVal[10] = 0x0a */
#define S1M2_DRIVEMODE_ENUM_HRS_HANDHELD        0x000BU /* arrDriveModeVal[11] = 0x04 */

/* Camera Status Record Tags (8 TLV entries in 0x02000080 response buffer) */
#define S1M2_PTP_TAG_RECINFO_DRIVEMODE          0x02000081U
#define S1M2_PTP_TAG_RECINFO_MODEPOS            0x02000082U
#define S1M2_PTP_TAG_RECINFO_CREATIVE           0x02000083U
#define S1M2_PTP_TAG_RECINFO_IAMODE             0x02000084U
#define S1M2_PTP_TAG_RECINFO_4KMODE             0x02000085U
#define S1M2_PTP_TAG_RECINFO_PARAM6             0x02000086U
#define S1M2_PTP_TAG_RECINFO_PARAM7             0x02000087U
#define S1M2_PTP_TAG_RECINFO_PARAM8             0x02000088U

/* Image Quality Tags */
#define S1M2_PTP_TAG_IMAGE_QUALITY_GET          0x020000A0U
#define S1M2_PTP_TAG_IMAGE_QUALITY_SET          0x020000A2U
#define S1M2_IMG_QUALITY_JPEG_FINE              0x0000U
#define S1M2_IMG_QUALITY_JPEG_STD               0x0001U
#define S1M2_IMG_QUALITY_RAW_ONLY               0x0003U
#define S1M2_IMG_QUALITY_RAW_JPEG_FINE          0x0004U
#define S1M2_IMG_QUALITY_RAW_JPEG_STD           0x0005U

/* Shutter Speed Tags */
#define S1M2_PTP_TAG_SHUTTER_SPEED_GET          0x02000030U
#define S1M2_PTP_TAG_SHUTTER_SPEED_SET          0x02000031U

/* Silent Mode Tag 0x020000b7 */
#define S1M2_PTP_TAG_SILENT_MODE                0x020000B7U

/* ========================================================================= */
/* 4. Protocol Payload Structs                                               */
/* ========================================================================= */

#pragma pack(push, 1)

/**
 * @brief Generic PTP Vendor TLV Property Header (8 bytes).
 */
struct s1m2_ptp_prop_tlv_hdr {
    u32 tag;                /* Property Tag (e.g., 0x02000081) */
    u32 len;                /* Payload length in bytes */
};

/**
 * @brief PTP Property uint16 TLV Record (10 bytes).
 * Exactly matches wire format for drive_before.bin records (8 records * 10 = 80 bytes).
 */
struct s1m2_ptp_prop_record_u16 {
    u32 tag;                /* Property Tag (e.g., 0x02000081) */
    u32 len;                /* Payload length = 0x00000002 */
    u16 val;                /* uint16 property value */
};

/**
 * @brief Firmware Update Send Data Info packet - 32-bit Address framing (12 bytes).
 * Disassembly: mov w24, #0xc (12 bytes), offset 0: total_transfer_size,
 * offset 4: target_address (u32), offset 8: data_type (u32).
 */
struct s1m2_ptp_fwup_send_data_info_u32 {
    u32 total_transfer_size;/* Total firmware image bytes (171,867,648 for V1.4) */
    u32 target_address;     /* 32-bit target memory base address */
    u32 data_type;          /* Data payload category flags */
};

/**
 * @brief Firmware Update Send Data Info packet - 64-bit Address framing (16 bytes).
 * Disassembly: mov w24, #0x10 (16 bytes), offset 0: total_transfer_size,
 * offset 4: target_address (u64), offset 12: data_type (u32).
 */
struct s1m2_ptp_fwup_send_data_info_u64 {
    u32 total_transfer_size;/* Total firmware image bytes (171,867,648 for V1.4) */
    u64 target_address;     /* 64-bit target memory base address */
    u32 data_type;          /* Data payload category flags */
};

/**
 * @brief PTP Vendor Setup Control request framing (OpCode 0x9406) (12 bytes).
 * Disassembly: offset 0: subcode (u32), offset 4: num_params (u16),
 * offset 6: reserved (u16), offset 8: params array (u32[1]).
 */
struct s1m2_ptp_setup_ctrl_req {
    u32 subcode;            /* S1M2_PTP_SUBCODE_* */
    u16 num_params;         /* Parameter word count */
    u16 reserved;           /* Padding / alignment */
    u32 params[1];          /* First parameter (at offset +8) */
};

#pragma pack(pop)

#ifdef __cplusplus
}
#endif

#endif /* S1M2_PTP_PROTO_H */
