/* SPDX-License-Identifier: MIT */
/**
 * @file s1m2_dsp_xm6.h
 * @brief CEVA XM6 Vector DSP architecture, microcode loaders, High-Res and Focus Stacking interfaces.
 *
 * Target: Panasonic LUMIX S1M2 (DC-S1M2)
 * SoC: Socionext Milbeaut M20V (Karine / SC2006A / MC8241 / MC8243)
 * DSP Subsystem: Dual CEVA XM6 Vector DSPs (512-bit SIMD, 64KB ITCM, 512KB DTCM)
 */

#ifndef S1M2_DSP_XM6_H
#define S1M2_DSP_XM6_H

#include "s1m2_types.h"
#include "s1m2_mmap.h"

#ifdef __cplusplus
extern "C" {
#endif

/* ========================================================================= */
/* 1. CEVA XM6 Vector DSP Hardware Architecture                              */
/* ========================================================================= */

#define S1M2_XM6_NUM_CORES              2U
#define S1M2_XM6_VEC_REG_WIDTH_BITS     512U
#define S1M2_XM6_VEC_REG_WIDTH_BYTES    64U
#define S1M2_XM6_NUM_VEC_REGS           32U   /* v0 ~ v31 */

/* ITCM: 64 KiB (0x10000) at 0x1C200000 */
#define S1M2_XM6_ITCM_ADDR              S1M2_DSP_ITCM_BASE
#define S1M2_XM6_ITCM_CAPACITY          S1M2_DSP_ITCM_SIZE

/* DTCM: 512 KiB (0x80000) at 0x1C000000 */
#define S1M2_XM6_DTCM_ADDR              S1M2_DSP_DTCM_BASE
#define S1M2_XM6_DTCM_CAPACITY          S1M2_DSP_DTCM_SIZE

/* DSP Peripheral Control Register Map (0x1D000000) */
struct s1m2_dsp_ctrl_regs {
    reg32_t core_reset;         /* +0x00: Bit 0: Core 0 Reset, Bit 1: Core 1 Reset */
    reg32_t core_run_stall;     /* +0x04: Bit 0: Core 0 Run, Bit 1: Core 1 Run */
    reg32_t itcm_remap;         /* +0x08: ITCM Remap / Protection */
    reg32_t dtcm_remap;         /* +0x0C: DTCM Remap / Protection */
    reg32_t irq_status;         /* +0x10: Interrupt status to host */
    reg32_t irq_mask;           /* +0x14: Interrupt mask */
    reg32_t dma_kick;           /* +0x18: XDMAX trigger */
    reg32_t dma_status;         /* +0x1C: XDMAX busy / complete */
    reg32_t perf_cycle_low;     /* +0x20: Cycle counter lower 32b */
    reg32_t perf_cycle_high;    /* +0x24: Cycle counter upper 32b */
    reg32_t reserved[42];       /* Pad to 0xCC (204 bytes) */
};

/* Microcode Binary Header Descriptor */
#define S1M2_XM6_FW_MAGIC               0x584D3644U /* "XM6D" */

struct s1m2_xm6_microcode_desc {
    u32 magic;                  /* S1M2_XM6_FW_MAGIC */
    u32 component_index;        /* e.g., 34 for hr_c_prog, 44 for dsp_fstack_ */
    u32 target_tcm;             /* 0: ITCM (0x1C200000), 1: DTCM (0x1C000000), 2: DDR */
    u32 load_address;           /* Physical destination address */
    u32 binary_size;            /* Payload byte size */
    u32 entry_point;            /* Execution entry offset */
    u32 checksum;               /* CRC32 or Adler32 */
    u32 core_target;            /* 0: Core 0, 1: Core 1, 2: Both */
} __packed;

/* ========================================================================= */
/* 2. High-Resolution ("高分辨率处理") Microcode Interface                          */
/* ========================================================================= */

/*
 * Firmware Mapping:
 * - 34_hr_c_prog.bin: 64 KiB  -> ITCM microcode
 * - 35_hr_d_prog.bin: 512 KiB -> DTCM data & weights
 * - 36_hr_c_ddr.bin:  512 KiB -> DDR accumulator workspace
 */
#define S1M2_HR_MODE_8FRAME             8U   /* Standard 96MP high-res */
#define S1M2_HR_MODE_16FRAME            16U  /* Handheld / motion suppression high-res */

struct s1m2_hr_subpixel_shift {
    s16 shift_x_eighths;        /* Subpixel displacement X in 1/8 pixel units */
    s16 shift_y_eighths;        /* Subpixel displacement Y in 1/8 pixel units */
};

struct s1m2_hr_burst_config {
    u32 burst_mode;             /* S1M2_HR_MODE_8FRAME or S1M2_HR_MODE_16FRAME */
    u32 image_width;            /* 6000 */
    u32 image_height;           /* 4000 */
    u32 bayer_pattern;          /* 0: RGGB, 1: BGGR, 2: GRBG, 3: GBRG */
    u64 input_raw_addrs[16];    /* Physical addresses of 14-bit Bayer frames in DDR */
    u64 accum_buffer_addr;      /* DDR Accumulator buffer (from hr_c_ddr) */
    u64 output_raw_addr;        /* High-res combined RAW buffer (96MP / 12000x8000) */
    u32 motion_detect_enable;   /* 1: Detect subject motion to suppress ghosting */
} __packed;

/* ========================================================================= */
/* 3. Focus Stacking ("景深合成") Subsystem          */
/* ========================================================================= */

/*
 * Firmware Mapping:
 * - 44_dsp_fstack_.bin: 64 KiB  -> Core 0 ITCM microcode
 * - 45_dsp_fstack_.bin: 64 KiB  -> Core 1 ITCM microcode
 * - 46_fstack_c_ex.bin: 512 KiB -> DTCM Laplacian weighting tables & engine
 */

/* Ping-Pong Tiling Architecture (Optimized for 512KB DTCM) */
#define S1M2_FSTACK_TILE_WIDTH          512U
#define S1M2_FSTACK_TILE_HEIGHT         48U
#define S1M2_FSTACK_TILE_PIXELS         (S1M2_FSTACK_TILE_WIDTH * S1M2_FSTACK_TILE_HEIGHT)
#define S1M2_FSTACK_TILE_BYTES          (S1M2_FSTACK_TILE_PIXELS * 2U) /* 16-bit plane */
#define S1M2_FSTACK_PING_PONG_FOOTPRINT (S1M2_FSTACK_TILE_BYTES * 8U)  /* 384 KiB fits in 512KB DTCM */

struct s1m2_fstack_slice_desc {
    u32 slice_index;            /* Current tile index */
    u32 start_x;
    u32 start_y;
    u32 width;                  /* 512 */
    u32 height;                 /* 48 */
    u64 ddr_src_addr;           /* Source Bayer tile address */
    u64 ddr_dst_addr;           /* Blended output tile address */
    u32 laplacian_threshold;    /* High-frequency edge sensitivity */
} __packed;


/* ========================================================================= */
/* 4. Real-time Defect Pixel & EIS/LDC Subsystems                            */
/* ========================================================================= */

/*
 * Firmware Mapping:
 * - 40_dsp_kizu_c.bin: 64 KiB ITCM Defect filter microcode
 * - 41_dsp_kizu_d.bin: 64 KiB DTCM Defect lookup coordinates
 * - 42_dsp_eisldc_.bin: 64 KiB ITCM Core 0 EIS/LDC microcode
 * - 43_dsp_eisldc_.bin: 64 KiB ITCM Core 1 EIS/LDC microcode
 * - 47_raw_kizu_c.bin: 64 KiB RAW defect corrector microcode
 * - 48_raw_kizu_d.bin: 64 KiB RAW defect corrector data
 */
struct s1m2_dsp_defect_filter_config {
    u32 defect_count;
    u64 coord_table_addr;       /* From 41_dsp_kizu_d */
    u32 replacement_mode;       /* Median, Bilinear, or Nearest neighbor */
} __packed;

struct s1m2_dsp_eis_ldc_config {
    u32 core_id;                /* 0 or 1 */
    s32 gyro_pitch_q16;
    s32 gyro_yaw_q16;
    s32 gyro_roll_q16;
    u64 distortion_mesh_addr;   /* Lens distortion spline coefficients */
} __packed;

#ifdef __cplusplus
}
#endif

#endif /* S1M2_DSP_XM6_H */
