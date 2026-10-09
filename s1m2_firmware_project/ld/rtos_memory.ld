/* SPDX-License-Identifier: MIT */
/**
 * @file rtos_memory.ld
 * @brief Linker script for Panasonic LUMIX S1M2 RTOS Domain (TOPPERS/ITRON, Cores 0-2).
 *
 * SoC: Socionext Milbeaut M20V (ARM64 Quad-Core Cortex-A53)
 * Target: CPU 0-2 RTOS Domain (~2.45GB DDR Pool + Vector Table)
 */

OUTPUT_FORMAT("elf64-littleaarch64", "elf64-bigaarch64", "elf64-littleaarch64")
OUTPUT_ARCH(aarch64)
ENTRY(_rtos_reset_entry)

MEMORY
{
    /* Primary Boot & Exception Vector Table (1.5 MB) */
    VECTORS      (rx)  : ORIGIN = 0x400000000, LENGTH = 0x00180000

    /* Core RTOS Execution RAM & RAW Framebuffer Pool (~2.45 GB) */
    RTOS_RAM     (rwx) : ORIGIN = 0x40D700000, LENGTH = 0x09E900000

    /* Shared Memory Secondary Descriptor Pointer Table (512 Bytes) */
    SHMEM_TABLE  (rw)  : ORIGIN = 0x4AC000000, LENGTH = 0x000000200

    /* Liveview Stream & Audio Exchange Pool (~1.3 GB) */
    MEDIA_POOL   (rw)  : ORIGIN = 0x4AC000200, LENGTH = 0x053FFE000
}

SECTIONS
{
    /* Low-Address Interrupt Vector Table */
    .vectors : ALIGN(4096)
    {
        _vectors_start = .;
        KEEP(*(.vectors))
        KEEP(*(.boot_entry))
        _vectors_end = .;
    } > VECTORS

    /* RTOS Kernel and Camera Application Code */
    .text : ALIGN(4096)
    {
        _text_start = .;
        *(.text)
        *(.text.*)
        *(.glue_7)
        *(.glue_7t)
        _text_end = .;
    } > RTOS_RAM

    .rodata : ALIGN(4096)
    {
        _rodata_start = .;
        *(.rodata)
        *(.rodata.*)
        _rodata_end = .;
    } > RTOS_RAM

    .data : ALIGN(4096)
    {
        _data_start = .;
        *(.data)
        *(.data.*)
        _data_end = .;
    } > RTOS_RAM

    .bss : ALIGN(4096)
    {
        _bss_start = .;
        *(.bss)
        *(.bss.*)
        *(COMMON)
        _bss_end = .;
    } > RTOS_RAM

    /* High-Res RAW Frame Buffers (14-bit Bayer, 28MB per frame) */
    .raw_framebuffers (NOLOAD) : ALIGN(65536)
    {
        _raw_buffers_start = .;
        *(.raw_framebuffers)
        *(.raw_framebuffers.*)
        _raw_buffers_end = .;
    } > RTOS_RAM

    /* Inter-core Shared Memory Control Descriptor */
    .shmem_desc : ALIGN(8)
    {
        _shmem_desc_start = .;
        KEEP(*(.shmem_control_table))
        _shmem_desc_end = .;
    } > SHMEM_TABLE

    /* Streaming Video and Audio Ring Buffers */
    .media_pool (NOLOAD) : ALIGN(4096)
    {
        _media_pool_start = .;
        *(.movie_stream_buf)
        *(.audio_pcm_buf)
        _media_pool_end = .;
    } > MEDIA_POOL

    /* Discard unnecessary debugging sections */
    /DISCARD/ :
    {
        *(.comment)
        *(.note.*)
    }
}
