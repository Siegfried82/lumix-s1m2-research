/* SPDX-License-Identifier: MIT */
/**
 * @file linux_memory.ld
 * @brief Memory layout linker script for Panasonic LUMIX S1M2 Linux Domain (Core 3).
 *
 * Target: Linux 4.19 Kernel & Modules, slram0 (initramfs), slram1 (squashfs)
 */

OUTPUT_FORMAT("elf64-littleaarch64", "elf64-bigaarch64", "elf64-littleaarch64")
OUTPUT_ARCH(aarch64)
ENTRY(_stext)

MEMORY
{
    /* Compressed Kernel Image in RAM */
    ZKERNEL   (rx) : ORIGIN = 0x400200000, LENGTH = 0x01090000 /* 16.5625 MB */

    /* Device Tree Binary */
    DTB       (r)  : ORIGIN = 0x401290000, LENGTH = 0x00010000 /* 64 KB */

    /* slram0: Initramfs Rootfs */
    INITRAMFS (r)  : ORIGIN = 0x4012A0000, LENGTH = 0x00400000 /* 4 MB */

    /* slram1: SquashFS System Image */
    SQUASHFS  (r)  : ORIGIN = 0x4016A0000, LENGTH = 0x02060000 /* 32.375 MB */

    /* Linux Execution System DDR (160 MB dedicated) */
    LINUX_DDR (rwx): ORIGIN = 0x403700000, LENGTH = 0x00A000000 /* 160 MB */
}

SECTIONS
{
    .head.text : ALIGN(4096)
    {
        _stext = .;
        *(.head.text)
    } > LINUX_DDR

    .text : ALIGN(4096)
    {
        *(.text)
        *(.text.*)
        _etext = .;
    } > LINUX_DDR

    .rodata : ALIGN(4096)
    {
        *(.rodata)
        *(.rodata.*)
    } > LINUX_DDR

    .data : ALIGN(4096)
    {
        *(.data)
        *(.data.*)
        _edata = .;
    } > LINUX_DDR

    .bss : ALIGN(4096)
    {
        _sbss = .;
        *(.bss)
        *(.bss.*)
        *(COMMON)
        _ebss = .;
    } > LINUX_DDR

    /DISCARD/ :
    {
        *(.comment)
        *(.note.*)
    }
}
