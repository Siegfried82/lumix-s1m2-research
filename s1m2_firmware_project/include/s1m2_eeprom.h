/* SPDX-License-Identifier: MIT */
/**
 * @file s1m2_eeprom.h
 * @brief EEPROM parameter structures, factory calibration and license slot definitions.
 *
 * Target: Panasonic LUMIX S1M2 (DC-S1M2)
 * Flash Mapping: Blocks located from 0x054E0000 through 0x09380000.
 */

#ifndef S1M2_EEPROM_H
#define S1M2_EEPROM_H

#include "s1m2_types.h"

#ifdef __cplusplus
extern "C" {
#endif

/* ========================================================================= */
/* 1. EEPROM Flash Partition Offsets and Sizes                               */
/* ========================================================================= */

#define S1M2_FLASH_EEP_OW_A_OFF         0x054E0000U
#define S1M2_FLASH_EEP_OW_A_SIZE        0x00020000U /* 128 KiB */

#define S1M2_FLASH_EEP_OW_B_OFF         0x05500000U
#define S1M2_FLASH_EEP_OW_B_SIZE        0x00020000U /* 128 KiB */

#define S1M2_FLASH_EEP_ADJ_OFF          0x05520000U
#define S1M2_FLASH_EEP_ADJ_SIZE         0x00020000U /* 128 KiB: Factory Calibration */

#define S1M2_FLASH_EEP_FIX_OFF          0x05540000U
#define S1M2_FLASH_EEP_FIX_SIZE         0x00020000U /* 128 KiB: Model ID & Region Lock */

#define S1M2_FLASH_EEP_ACT_A_OFF        0x05560000U
#define S1M2_FLASH_EEP_ACT_A_SIZE       0x00000200U /* 512 B: License Slot A (ARRI LogC3) */

#define S1M2_FLASH_EEP_ACT_B_OFF        0x05580000U
#define S1M2_FLASH_EEP_ACT_B_SIZE       0x00000200U /* 512 B: License Slot B (Backup) */

#define S1M2_FLASH_EEP_EXP_A_OFF        0x055A0000U
#define S1M2_FLASH_EEP_EXP_A_SIZE       0x00003000U /* 12 KiB: Exposure Calibration A */

#define S1M2_FLASH_EEP_EXP_B_OFF        0x055C0000U
#define S1M2_FLASH_EEP_EXP_B_SIZE       0x00003000U /* 12 KiB: Exposure Calibration B */

#define S1M2_FLASH_HISTORY_OFF          0x055E0000U
#define S1M2_FLASH_HISTORY_SIZE         0x00040000U /* 256 KiB: Operation History / SHTCNT */

#define S1M2_FLASH_LENS_HIST_OFF        0x05620000U
#define S1M2_FLASH_LENS_HIST_SIZE       0x00060000U /* 384 KiB: Lens Mount History */

#define S1M2_FLASH_KIZU_DATA_OFF        0x07B20000U
#define S1M2_FLASH_KIZU_DATA_SIZE       0x00080000U /* 512 KiB: Static Bad Pixel Map */

#define S1M2_FLASH_VKIZU_DATA_OFF       0x07BA0000U
#define S1M2_FLASH_VKIZU_DATA_SIZE      0x00900000U /* 9.0 MiB: Video Dynamic Defect Map */

#define S1M2_FLASH_DSH_ADJ_OFF          0x09380000U
#define S1M2_FLASH_DSH_ADJ_SIZE         0x00020000U /* 128 KiB: Shutter Waveform Adj */

/* ========================================================================= */
/* 2. Common EEPROM Header & Calibration Structures                          */
/* ========================================================================= */

#define S1M2_EEP_MAGIC                  0x45455052U /* "EEPR" */

struct s1m2_eep_common_hdr {
    u32 magic;                  /* S1M2_EEP_MAGIC */
    u16 version_major;
    u16 version_minor;
    u32 block_type;
    u32 payload_crc32;
    u32 write_sequence_no;
    u32 timestamp;
} __packed;

/**
 * Factory Adjustment (eep_adj): Sensor black level, gain, lens shading
 */
struct s1m2_eep_adj {
    struct s1m2_eep_common_hdr hdr;
    u16 sensor_black_level_r;   /* Optical black pedestal (e.g. 512 / 1024) */
    u16 sensor_black_level_gr;
    u16 sensor_black_level_gb;
    u16 sensor_black_level_b;
    u16 analog_gain_calib_r;    /* Factory gain slope compensation */
    u16 analog_gain_calib_g;
    u16 analog_gain_calib_b;
    u16 dcg_switch_threshold;   /* Dual-Conversion Gain ISO threshold */
    u16 ibis_hall_calib_x;      /* IBIS voice coil neutral offset X */
    u16 ibis_hall_calib_y;      /* IBIS voice coil neutral offset Y */
    u8  shading_mesh_points[512];/* Lens shading correction spline knots */
    u8  reserved[0x20000 - 556];
} __packed;

/**
 * Factory Fixed Identification & Regional Lock (eep_fix)
 */
struct s1m2_eep_fix {
    struct s1m2_eep_common_hdr hdr;
    char model_name[16];        /* "DC-S1M2\0" */
    char serial_number[24];     /* Factory serial string */
    char hardware_revision[8];  /* "EVB" / "MASS" */
    u16  region_code;           /* 0x01: Japan, 0x02: NA, 0x03: EU, 0x04: Global */
    u16  pal_ntsc_default;      /* 0: NTSC (59.94p), 1: PAL (50p) */
    u16  video_rec_limit_flag;  /* 0: No 30-min recording limit */
    u16  wlan_regulatory_domain;/* Country code for 2.4G/5GHz channels */
    u8   factory_mac_addr[6];   /* Wi-Fi MAC Address */
    u8   bt_mac_addr[6];        /* Bluetooth MAC Address */
    u8   reserved[0x20000 - 92];
} __packed;

/* ========================================================================= */
/* 3. Commercial Feature License Slots (eep_act_a / eep_act_b)               */
/* ========================================================================= */

#define S1M2_LIC_MAGIC                  0x41435431U /* "ACT1" */

/* Feature IDs */
#define S1M2_FEAT_ARRI_LOGC3            0x0001U /* ARRI LogC3 Gamma & Cinema Color */
#define S1M2_FEAT_DMW_SFU2_VLOG         0x0002U /* Full V-Log / RAW Output Key */
#define S1M2_FEAT_ANAMORPHIC_DESQUEEZE  0x0004U /* Enhanced Anamorphic Display Modes */
#define S1M2_FEAT_PRORES_RAW_HDMI       0x0008U /* HDMI ProRes RAW 5.9K Output */

/**
 * 512-Byte Feature License Certificate Slot (eep_act_a / eep_act_b)
 */
struct s1m2_eep_license_slot {
    u32 magic;                  /* S1M2_LIC_MAGIC */
    u16 feature_id;             /* Bitmask of enabled commercial features */
    u16 status_flags;           /* 1: Active, 0: Revoked */
    char serial_binding[24];    /* Camera serial number bound to certificate */
    u32 issue_date;             /* Unix timestamp of license generation */
    u32 expiry_date;            /* 0 for perpetual license */
    u8  public_key_fingerprint[32]; /* SHA-256 hash of Panasonic root license key */
    u8  ecdsa_signature_r[32];  /* NIST P-256 ECDSA R signature component */
    u8  ecdsa_signature_s[32];  /* NIST P-256 ECDSA S signature component */
    u8  reserved[376];          /* Pad to exactly 512 bytes (512 - 136 = 376) */
} __packed;

/* ========================================================================= */
/* 4. Operation History & Shutter Actuation Count (history)                  */
/* ========================================================================= */

struct s1m2_eep_history {
    struct s1m2_eep_common_hdr hdr;
    u32 shutter_count_shtcnt;   /* Mechanical shutter release counter */
    u32 elec_shutter_count;     /* Electronic shutter frame counter */
    u32 power_on_cycles;        /* Camera boot counter */
    u32 flash_fired_count;      /* Hotshoe flash sync counter */
    u32 overheat_warning_count; /* Thermal throttle counter */
    u32 sensor_clean_count;     /* Ultrasonic sensor cleaner counter */
    u32 last_error_code;        /* Last fatal error (e.g. lens communication error) */
    u8  error_ring_buffer[512]; /* Recent 64 error entries */
    u8  reserved[0x40000 - 564];/* Pad to 256 KiB */
} __packed;

#ifdef __cplusplus
}
#endif

#endif /* S1M2_EEPROM_H */
