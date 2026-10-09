/* SPDX-License-Identifier: MIT */
/**
 * @file rtos_entry_stub.c
 * @brief Minimal reset vector stub for Panasonic LUMIX S1M2 RTOS domain.
 */

#include "s1m2_types.h"

/* Section attributes for linker placement */
__attribute__((section(".boot_entry"))) void _rtos_reset_entry(void) {
    /* Spin loop stub */
    while (1) {
#if defined(__aarch64__)
        __asm__ volatile("wfe");
#else
        break;
#endif
    }
}
