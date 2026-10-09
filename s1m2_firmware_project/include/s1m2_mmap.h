/* SPDX-License-Identifier: MIT */
/**
 * @file s1m2_mmap.h
 * @brief Memory Map definitions for Panasonic LUMIX S1M2 (DC-S1M2) firmware.
 *
 * SoC: Socionext Milbeaut M20V (Karine / SC2006A / MC8241 / MC8243)
 * Architecture: Quad-core ARM Cortex-A53 (AMP: CPU 0-2 RTOS, CPU 3 Linux)
 */

#ifndef S1M2_MMAP_H
#define S1M2_MMAP_H

#include "s1m2_types.h"

#ifdef __cplusplus
extern "C" {
#endif

/* ========================================================================= */
/* 1. Low Peripheral I/O Address Space (32-bit physical bus)                  */
/* ========================================================================= */

/* Inter-Processor Communication Unit (IPCU) Controllers */
#define S1M2_IO_IPCU_UNIT0_BASE         0x0C851000ULL  /* Linux <-> RTOS commands & ipcufs */
#define S1M2_IO_IPCU_UNIT1_BASE         0x0C852000ULL  /* Streaming & Media transport */
#define S1M2_IO_IPCU_UNIT2_BASE         0x0C853000ULL  /* Status & Async Notifications */
#define S1M2_IO_IPCU_UNIT_SIZE          0x00001000ULL  /* 4 KiB per IPCU Unit */

/* CEVA XM6 Vector DSP Subsystem */
#define S1M2_DSP_DTCM_BASE              0x1C000000ULL  /* Data Tightly-Coupled Memory */
#define S1M2_DSP_DTCM_SIZE              0x00080000ULL  /* 512 KiB */
#define S1M2_DSP_ITCM_BASE              0x1C200000ULL  /* Instruction Tightly-Coupled Memory */
#define S1M2_DSP_ITCM_SIZE              0x00010000ULL  /* 64 KiB */

#define S1M2_DSP_CTRL_BASE              0x1D000000ULL  /* DSP Peripheral Control Block */
#define S1M2_DSP_CTRL_SIZE              0x000000CCULL
#define S1M2_DSP_IPCU_REG_BASE          0x1D001000ULL  /* DSP Dedicated Mailbox Regs */
#define S1M2_DSP_IPCU_REG_SIZE          0x00000904ULL

/* CNN Deep Learning Hardware Accelerator */
#define S1M2_CNN_CTRL_BASE              0x1D000000ULL  /* Shared bus control base */
#define S1M2_CNN_EXTRA_REG_BASE         0x1D04042CULL  /* CNN Extra control register */
#define S1M2_CNN_EXTRA_REG_SIZE         0x00000004ULL

/* External Interrupt Controller (EXIU/EXSINT) */
#define S1M2_EXSINT_STAT_REG            0x1BA01010ULL  /* Interrupt status register */
#define S1M2_EXSINT_MSK_REG             0x1BA00020ULL  /* Interrupt mask register */

/* ========================================================================= */
/* 2. High DDR Physical Memory Layout (4GB+ Physical Window: 0x4_0000_0000+)  */
/* ========================================================================= */

#define S1M2_DDR_PHYS_BASE              0x400000000ULL /* Base of 4GB+ DDR pool */

/* Primary Boot & RTOS Vector Table (1.5 MB) */
#define S1M2_MEM_BOOT_BASE              0x400000000ULL
#define S1M2_MEM_BOOT_SIZE              0x000180000ULL /* 1.5 MiB */

/* U-Boot Running Text & Stack (CONFIG_SYS_TEXT_BASE) */
#define S1M2_MEM_UBOOT_BASE             0x400180000ULL
#define S1M2_MEM_UBOOT_SIZE             0x000080000ULL /* 512 KiB */

/* Linux Kernel Image (ZKERNEL - Image.gz) */
#define S1M2_MEM_ZKERNEL_BASE           0x400200000ULL
#define S1M2_MEM_ZKERNEL_SIZE           0x01090000ULL /* 16.5625 MiB */

/* Linux Device Tree Blob (DTB) */
#define S1M2_MEM_DTB_BASE               0x401290000ULL
#define S1M2_MEM_DTB_SIZE               0x000010000ULL /* 64 KiB */

/* slram0: Initramfs Root Filesystem */
#define S1M2_MEM_SLRAM0_BASE            0x4012A0000ULL
#define S1M2_MEM_SLRAM0_SIZE            0x000400000ULL /* 4.0 MiB */

/* slram1: SquashFS Compressed System Image */
#define S1M2_MEM_SLRAM1_BASE            0x4016A0000ULL
#define S1M2_MEM_SLRAM1_SIZE            0x02060000ULL /* 32.375 MiB */

/* Linux 4.19 Dedicated System RAM (Assigned to cpu@3 in DTS) */
#define S1M2_MEM_LINUX_DDR_BASE         0x403700000ULL
#define S1M2_MEM_LINUX_DDR_SIZE         0x00A000000ULL /* 160 MiB */
#define S1M2_MEM_LINUX_DDR_END          (S1M2_MEM_LINUX_DDR_BASE + S1M2_MEM_LINUX_DDR_SIZE)

/* RTOS Execution Pool & Image Framebuffer Pool (Cores 0-2) */
#define S1M2_MEM_RTOS_DDR_BASE          0x40D700000ULL
#define S1M2_MEM_RTOS_DDR_SIZE          0x09E900000ULL /* ~2.477 GiB (0x4_AC00_0000 - 0x4_0D70_0000) */
#define S1M2_MEM_RTOS_DDR_END           0x4AC000000ULL

/* RTOS RAW Frame Buffer Metrics (14-bit Bayer) */
#define S1M2_RAW_FRAME_WIDTH            6000U
#define S1M2_RAW_FRAME_HEIGHT           4000U
#define S1M2_RAW_FRAME_BPP              14U
#define S1M2_RAW_FRAME_STRIDE           10500U         /* (6000 * 14) / 8 */
#define S1M2_RAW_FRAME_SIZE             (S1M2_RAW_FRAME_STRIDE * 4000U) /* ~28 MB per frame */
#define S1M2_HIGHRES_8FRAME_SIZE        (S1M2_RAW_FRAME_SIZE * 8U)     /* ~224 MB */
#define S1M2_HIGHRES_16FRAME_SIZE       (S1M2_RAW_FRAME_SIZE * 16U)    /* ~448 MB */

/* Shared Memory Control Top Descriptor Table */
#define S1M2_SHMEM_TOP_ADDR             0x4AC000000ULL
#define S1M2_SHMEM_TOP_SIZE             0x000000200ULL /* 512 Bytes */

/* Secondary Pointer Offsets within S1M2_SHMEM_TOP_ADDR */
#define S1M2_SHMEM_IPCU_BUF_ADDR_OFF    0x08U
#define S1M2_SHMEM_IPCU_BUF_SIZE_OFF    0x10U
#define S1M2_SHMEM_IPCU_SYNC_ADDR_OFF   0x18U
#define S1M2_SHMEM_IPCU_SYNC_SIZE_OFF   0x20U
#define S1M2_SHMEM_MOVIE_ADDR_OFF       0x28U
#define S1M2_SHMEM_MOVIE_SIZE_OFF       0x30U
#define S1M2_SHMEM_AUDIO_ADDR_OFF       0x38U
#define S1M2_SHMEM_AUDIO_SIZE_OFF       0x40U

/* Liveview Stream & Audio PCM Pool */
#define S1M2_MEM_MEDIA_POOL_BASE        0x4AC000200ULL
#define S1M2_MEM_MEDIA_POOL_END         0x4FFFFFFFFULL
#define S1M2_MEM_MEDIA_POOL_SIZE        (S1M2_MEM_MEDIA_POOL_END - S1M2_MEM_MEDIA_POOL_BASE + 1ULL) /* ~1.3 GiB */

/* ========================================================================= */
/* 3. Shared Memory Table C Structures                                       */
/* ========================================================================= */

/**
 * @brief Secondary Shared Memory Pointer Descriptor Table at 0x4_AC00_0000
 */
struct s1m2_shmem_control_table {
    u64 header_reserved;      /* +0x00: Status / Magic code */
    u64 ipcu_buffer_addr;     /* +0x08: IPCU data payload buffer base */
    u64 ipcu_buffer_size;     /* +0x10: IPCU data payload buffer size */
    u64 ipcu_sync_addr;       /* +0x18: IPCU synchronization area base */
    u64 ipcu_sync_size;       /* +0x20: IPCU synchronization area size */
    u64 movie_buffer_addr;    /* +0x28: Liveview / video stream buffer base */
    u64 movie_buffer_size;    /* +0x30: Liveview / video stream buffer size */
    u64 audio_buffer_addr;    /* +0x38: Audio PCM buffer base */
    u64 audio_buffer_size;    /* +0x40: Audio PCM buffer size */
    u8  reserved[0x200 - 0x48];/* Pad to 512 bytes */
} __packed;

/* Helper Macros to Validate DDR Regions */
static inline bool s1m2_is_linux_addr(phys_addr_t addr) {
    return (addr >= S1M2_MEM_LINUX_DDR_BASE && addr < S1M2_MEM_LINUX_DDR_END);
}

static inline bool s1m2_is_rtos_addr(phys_addr_t addr) {
    return (addr >= S1M2_MEM_RTOS_DDR_BASE && addr < S1M2_MEM_RTOS_DDR_END);
}

static inline bool s1m2_is_media_addr(phys_addr_t addr) {
    return (addr >= S1M2_MEM_MEDIA_POOL_BASE && addr <= S1M2_MEM_MEDIA_POOL_END);
}

static inline bool s1m2_is_dsp_dtcm(phys_addr_t addr) {
    return (addr >= S1M2_DSP_DTCM_BASE && addr < (S1M2_DSP_DTCM_BASE + S1M2_DSP_DTCM_SIZE));
}

static inline bool s1m2_is_dsp_itcm(phys_addr_t addr) {
    return (addr >= S1M2_DSP_ITCM_BASE && addr < (S1M2_DSP_ITCM_BASE + S1M2_DSP_ITCM_SIZE));
}

#ifdef __cplusplus
}
#endif

#endif /* S1M2_MMAP_H */
