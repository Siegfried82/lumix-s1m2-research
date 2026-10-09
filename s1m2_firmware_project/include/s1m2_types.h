/* SPDX-License-Identifier: MIT */
/**
 * @file s1m2_types.h
 * @brief Common types and macro definitions for Panasonic LUMIX S1M2 firmware reverse engineering.
 *
 * Target: Panasonic LUMIX S1M2 (DC-S1M2)
 * SoC: Socionext Milbeaut M20V (Karine / SC2006A / MC8241 / MC8243)
 */

#ifndef S1M2_TYPES_H
#define S1M2_TYPES_H

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Fixed width integer shorthand */
typedef uint8_t   u8;
typedef uint16_t  u16;
typedef uint32_t  u32;
typedef uint64_t  u64;

typedef int8_t    s8;
typedef int16_t   s16;
typedef int32_t   s32;
typedef int64_t   s64;

/* Physical 64-bit address type */
typedef uint64_t  phys_addr_t;
typedef uint64_t  dma_addr_t;

/* Volatile register types */
typedef volatile uint8_t   reg8_t;
typedef volatile uint16_t  reg16_t;
typedef volatile uint32_t  reg32_t;
typedef volatile uint64_t  reg64_t;

/* Alignment and packed attributes */
#ifndef __packed
#define __packed __attribute__((__packed__))
#endif

#ifndef __aligned
#define __aligned(x) __attribute__((__aligned__(x)))
#endif

/* Endian conversion utilities */
#define S1M2_SWAP16(x) __builtin_bswap16(x)
#define S1M2_SWAP32(x) __builtin_bswap32(x)
#define S1M2_SWAP64(x) __builtin_bswap64(x)

#ifdef __cplusplus
}
#endif

#endif /* S1M2_TYPES_H */
