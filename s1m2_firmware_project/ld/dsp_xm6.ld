/* SPDX-License-Identifier: MIT */
/**
 * @file dsp_xm6.ld
 * @brief Linker script for CEVA XM6 Vector DSP microcode modules (High-Res & Focus Stacking).
 *
 * SoC: Socionext Milbeaut M20V (Karine / SC2006A)
 * Hardware: Dual-Core CEVA XM6 Vector DSP (64KB ITCM, 512KB DTCM)
 */

OUTPUT_FORMAT("elf32-littlearm", "elf32-bigarm", "elf32-littlearm")
ENTRY(_xm6_reset_vector)

MEMORY
{
    /* Instruction Tightly-Coupled Memory: 64 KiB */
    ITCM (rx) : ORIGIN = 0x1C200000, LENGTH = 0x00010000

    /* Data Tightly-Coupled Memory: 512 KiB */
    DTCM (rw) : ORIGIN = 0x1C000000, LENGTH = 0x00080000
}

SECTIONS
{
    /* Microcode executable text placed into ITCM */
    .itcm_text : ALIGN(16)
    {
        _itcm_start = .;
        KEEP(*(.vector_table))
        *(.text)
        *(.text.*)
        _itcm_end = .;
    } > ITCM

    /* Read-only lookup tables and coefficients in DTCM */
    .rodata : ALIGN(64)
    {
        _rodata_start = .;
        *(.rodata)
        *(.rodata.*)
        _rodata_end = .;
    } > DTCM

    /* Read-write data and state */
    .data : ALIGN(64)
    {
        _data_start = .;
        *(.data)
        *(.data.*)
        _data_end = .;
    } > DTCM

    /* Uninitialized variables */
    .bss : ALIGN(64)
    {
        _bss_start = .;
        *(.bss)
        *(.bss.*)
        *(COMMON)
        _bss_end = .;
    } > DTCM

    /* Focus Stacking Ping-Pong Tiling Workspace (384 KiB footprint) */
    .pingpong_tiling_pool (NOLOAD) : ALIGN(128)
    {
        _tiling_pool_start = .;
        *(.pingpong_tiles)
        _tiling_pool_end = .;
    } > DTCM

    /DISCARD/ :
    {
        *(.comment)
    }
}
