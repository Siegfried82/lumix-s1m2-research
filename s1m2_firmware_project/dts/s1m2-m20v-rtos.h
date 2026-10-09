/* SPDX-License-Identifier: GPL-2.0 */
/**
 * @file s1m2-m20v-rtos.h
 * @brief Device tree RTOS shared memory definitions for Panasonic LUMIX S1M2.
 * SoC: Socionext Milbeaut M20V (SC2006 / MC8241 / MC8243)
 */

#ifndef _S1M2_M20V_RTOS_H
#define _S1M2_M20V_RTOS_H

/* Common Shared Memory Secondary Table Base (0x4_AC00_0000) */
#define SHMEM_TOP_ADDRU                 0x00000004
#define SHMEM_TOP_ADDRL                 0xAC000000
#define SHMEM_TOP_ADDR_SIZE             0x00000200

/* Secondary Table Offsets */
#define SHMEM_IPCU_BUFFER_ADDR_OFFSET   0x08
#define SHMEM_IPCU_BUFFER_SIZE_OFFSET   0x10
#define SHMEM_IPCU_SYNC_ADDR_OFFSET     0x18
#define SHMEM_IPCU_SYNC_SIZE_OFFSET     0x20
#define SHMEM_MOVIE_ADDR_OFFSET         0x28
#define SHMEM_MOVIE_SIZE_OFFSET         0x30
#define SHMEM_AUDIO_ADDR_OFFSET         0x38
#define SHMEM_AUDIO_SIZE_OFFSET         0x40

/* Addressing Macros for Device Tree Nodes */
#define GET_IPCU_BUFFER_ADDRU           SHMEM_TOP_ADDRU
#define GET_IPCU_BUFFER_ADDRL           (SHMEM_TOP_ADDRL + SHMEM_IPCU_BUFFER_ADDR_OFFSET)
#define GET_IPCU_BUFFER_SIZEU           SHMEM_TOP_ADDRU
#define GET_IPCU_BUFFER_SIZEL           (SHMEM_TOP_ADDRL + SHMEM_IPCU_BUFFER_SIZE_OFFSET)
#define GET_IPCU_SYNC_ADDRU             SHMEM_TOP_ADDRU
#define GET_IPCU_SYNC_ADDRL             (SHMEM_TOP_ADDRL + SHMEM_IPCU_SYNC_ADDR_OFFSET)
#define GET_IPCU_SYNC_SIZEU             SHMEM_TOP_ADDRU
#define GET_IPCU_SYNC_SIZEL             (SHMEM_TOP_ADDRL + SHMEM_IPCU_SYNC_SIZE_OFFSET)
#define GET_MOVIE_ADDRU                 SHMEM_TOP_ADDRU
#define GET_MOVIE_ADDRL                 (SHMEM_TOP_ADDRL + SHMEM_MOVIE_ADDR_OFFSET)
#define GET_MOVIE_SIZEU                 SHMEM_TOP_ADDRU
#define GET_MOVIE_SIZEL                 (SHMEM_TOP_ADDRL + SHMEM_MOVIE_SIZE_OFFSET)
#define GET_AUDIO_ADDRU                 SHMEM_TOP_ADDRU
#define GET_AUDIO_ADDRL                 (SHMEM_TOP_ADDRL + SHMEM_AUDIO_ADDR_OFFSET)
#define GET_AUDIO_SIZEU                 SHMEM_TOP_ADDRU
#define GET_AUDIO_SIZEL                 (SHMEM_TOP_ADDRL + SHMEM_AUDIO_SIZE_OFFSET)

#endif /* _S1M2_M20V_RTOS_H */
