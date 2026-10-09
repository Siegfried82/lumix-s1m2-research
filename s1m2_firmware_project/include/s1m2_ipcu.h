/* SPDX-License-Identifier: MIT */
/**
 * @file s1m2_ipcu.h
 * @brief Inter-Processor Communication Unit (IPCU) hardware and protocol definitions.
 *
 * Target: Panasonic LUMIX S1M2 (DC-S1M2)
 * SoC: Socionext Milbeaut M20V (Karine / SC2006A / MC8241 / MC8243)
 * Covers: Hardware mailboxes, T_IPCU_IF framing, magic handshake, ipcufs, and vblk.
 */

#ifndef S1M2_IPCU_H
#define S1M2_IPCU_H

#include "s1m2_types.h"

#ifdef __cplusplus
extern "C" {
#endif

/* ========================================================================= */
/* 1. IPCU Hardware Mailbox Constants and Registers                          */
/* ========================================================================= */

#define SNI_IPCU_MAGIC_CODE             0xBEEFCAFEUL
#define SNI_IPCU_MAGIC_SIZE             0x00000020U

#define IPCU_MAX_UNIT                   3U
#define IPCU_MAX_MB                     8U
#define IPCU_MAX_CH                     (IPCU_MAX_MB * 2U)
#define IO_IPCU_MBX_DATA_MAX            9U

/* Directions */
#define IPCU_DIR_INIT                   0U
#define IPCU_DIR_SEND                   1U /* Linux -> RTOS */
#define IPCU_DIR_RECV                   2U /* RTOS -> Linux */

#define IPCU_CHSTAT_OPEN                1U
#define IPCU_CHSTAT_IGN                 2U

#define FLAG_SEND_NOTIFY                0x80000000U
#define FLAG_RECV_WAIT                  0xFFFFFFFFU
#define MASK_RECV_TIMEOUT               0x7FFFFFFFU

/* Hardware Mailbox Register Map */
struct io_sni_ipcu_mbox {
    u32 source;
    u32 mode;
    u32 send;
    u32 _reserved_mb0;
    u32 dest_set;
    u32 dest_clr;
    u32 dest_stat;
    u32 _reserved_mb1;
    u32 mask_set;
    u32 mask_clr;
    u32 mask_stat;
    u32 _reserved_mb2;
    u32 ack_set;
    u32 ack_clr;
    u32 ack_stat;
    u32 ack_src;
    u32 data[IO_IPCU_MBX_DATA_MAX]; /* 9 Data Words: 36 bytes (data[0..6] fit T_IPCU_IF) */
    u32 _reserved_mb[7];
};

struct io_sni_ipcu {
    u32 isr[16];                    /* Interrupt Status Register */
    u32 _reserved0[16];
    u32 mbadr[16];                  /* Mailbox Address Register  */
    u32 _reserved1[16];
    struct io_sni_ipcu_mbox mailbox[8];
    u32 _reserved2[0x100];
    u32 mbstat;                     /* Mailbox Status Register   */
};

/* ========================================================================= */
/* 2. Mailbox Channel Identification                                         */
/* ========================================================================= */

typedef enum {
    E_FJ_IPCU_MB_0 = 0,
    E_FJ_IPCU_MB_1,
    E_FJ_IPCU_MB_2,
    E_FJ_IPCU_MB_3,
    E_FJ_IPCU_MB_4,
    E_FJ_IPCU_MB_5,
    E_FJ_IPCU_MB_6,
    E_FJ_IPCU_MB_7,
    E_FJ_IPCU_MB_8,
    E_FJ_IPCU_MB_9,
    E_FJ_IPCU_MB_10,
    E_FJ_IPCU_MB_11,
    E_FJ_IPCU_MB_12,
    E_FJ_IPCU_MB_13,
    E_FJ_IPCU_MB_14,
    E_FJ_IPCU_MB_15,
    E_FJ_IPCU_MB_16,
    E_FJ_IPCU_MB_17,
    E_FJ_IPCU_MB_18,
    E_FJ_IPCU_MB_19,
    E_FJ_IPCU_MB_20,
    E_FJ_IPCU_MB_21,
    E_FJ_IPCU_MB_22,
    E_FJ_IPCU_MB_23,
    E_FJ_IPCU_MB_MAX = 24
} s1m2_ipcu_mb_t;

/* Device node naming strings */
#define S1M2_DEV_SNRTOS0_0              "/dev/snrtos0_0"
#define S1M2_DEV_SNRTOS0_1              "/dev/snrtos0_1"
#define S1M2_DEV_SNRTOS0_2              "/dev/snrtos0_2"
#define S1M2_DEV_SNRTOS0_3              "/dev/snrtos0_3"
#define S1M2_DEV_SNRTOS0_4              "/dev/snrtos0_4"
#define S1M2_DEV_SNRTOS0_5              "/dev/snrtos0_5"
#define S1M2_DEV_SNRTOS0_6              "/dev/snrtos0_6"
#define S1M2_DEV_SNRTOS0_7              "/dev/snrtos0_7"

#define S1M2_DEV_SNRTOS1_0              "/dev/snrtos1_0"
#define S1M2_DEV_SNRTOS1_1              "/dev/snrtos1_1"
#define S1M2_DEV_SNRTOS1_2              "/dev/snrtos1_2"
#define S1M2_DEV_SNRTOS1_3              "/dev/snrtos1_3"
#define S1M2_DEV_SNRTOS1_4              "/dev/snrtos1_4"
#define S1M2_DEV_SNRTOS1_5              "/dev/snrtos1_5"
#define S1M2_DEV_SNRTOS1_6              "/dev/snrtos1_6"
#define S1M2_DEV_SNRTOS1_7              "/dev/snrtos1_7"

#define S1M2_DEV_SNRTOS2_0              "/dev/snrtos2_0"
#define S1M2_DEV_SNRTOS2_1              "/dev/snrtos2_1"
#define S1M2_DEV_SNRTOS2_2              "/dev/snrtos2_2"
#define S1M2_DEV_SNRTOS2_3              "/dev/snrtos2_3"
#define S1M2_DEV_SNRTOS2_4              "/dev/snrtos2_4"
#define S1M2_DEV_SNRTOS2_5              "/dev/snrtos2_5"
#define S1M2_DEV_SNRTOS2_6              "/dev/snrtos2_6"
#define S1M2_DEV_SNRTOS2_7              "/dev/snrtos2_7"

/* ========================================================================= */
/* 3. IPCU Message Packet Structure (T_IPCU_IF)                              */
/* ========================================================================= */

/**
 * @brief Standard IPCU transport packet (28 bytes in 64-bit architecture)
 * Fits entirely within the 9 mailbox data registers data[0..6]
 */
typedef struct {
    u32 id;             /* Message transaction ID / Command */
    u32 bufl;           /* Lower 32 bits of physical payload buffer */
    u32 bufh;           /* Upper 32 bits of physical payload buffer */
    u32 len;            /* Slice length in bytes */
    u32 cont;           /* Continuation flag (0: Last packet, 1: More packets) */
    u32 total_len;      /* Total transaction length in bytes */
    u32 logical_ch;     /* Logical channel identifier */
} __packed T_IPCU_IF;

/**
 * @brief SD Card detect notification from RTOS to Linux
 */
typedef struct {
    u32 command;        /* 1: Card detect notification */
    u32 card_state;     /* 0: Ejected, 1: Inserted */
    u32 ch;             /* 0: SD Slot 0, 1: SD Slot 1 */
} __packed T_IPCU_IF_CARD_DETECT;

/* ========================================================================= */
/* 4. ipcufs (Remote SD Filesystem Bridge) Commands & Structs                */
/* ========================================================================= */

#define IPCUFS_MAX_PATH_LEN             520U
#define IPCUFS_MAX_NAME_LEN             516U
#define IPCUFS_PAGE_BUF_SIZE            0x2000U
#define IPCUFS_READDIR_MAX              44U

enum ipcufs_action {
    IFSA_MOUNTING   = 0x2000,   /* Notify ipcufs start */
    IFSA_UMOUNTING  = 0x2001,   /* Notify ipcufs end */
    IFSA_LOOKUP     = 0x2002,   /* Lookup file from inode */
    IFSA_READDIR    = 0x2003,   /* Read next directory entry */
    IFSA_READPAGE   = 0x2004,   /* Fill page with file payload */
    IFSA_WRITEPAGE  = 0x2005,   /* Store page payload to SD */
    IFSA_IGET       = 0x2006,   /* Return given inode */
    IFSA_ICREATE    = 0x2007,   /* Create new inode */
    IFSA_IDELETE    = 0x2008,   /* Delete inode */
    IFSA_IRENAME    = 0x2009,   /* Rename inode */
    IFSA_ISTATFS    = 0x200A,   /* Filesystem status (free space) */
    IFSA_OPEN       = 0x200B,   /* Open file */
    IFSA_CLOSE      = 0x200C    /* Close file */
};

struct ipcufs_u_imount {
    u32 drive;                  /* IN: Drive number (0: SD0, 1: SD1) */
    u32 err;                    /* OUT: Return code (0: OK, 1: NG) */
} __packed;

struct ipcufs_u_iget {
    u32 drive;                          /* IN: Drive number */
    char path[IPCUFS_MAX_PATH_LEN];     /* IN: Path string */
    u32 __reserved;
    u64 file_length;                    /* OUT: File size in bytes */
    u32 date;                           /* OUT: Creation date */
    u32 time;                           /* OUT: Creation time */
    u32 m_date;                         /* OUT: Last modification date */
    u32 m_time;                         /* OUT: Last modification time */
    u32 a_date;                         /* OUT: Last access date */
    u32 a_time;                         /* OUT: Last access time */
    u32 type;                           /* OUT: File type */
    u32 err;                            /* OUT: Return code */
} __packed;

struct ipcufs_u_page {
    u32 drive;                          /* IN: Drive number */
    char path[IPCUFS_MAX_PATH_LEN];     /* IN: Path string */
    u64 pa;                             /* IN: Physical address buffer */
    u32 pos;                            /* IN: Offset in file */
    u32 len;                            /* IN: Length to read/write */
    u32 err;                            /* OUT: Return code */
} __packed;

struct ipcufs_u_pages {
    u64 fNo;                            /* File handle / inode */
    char __reserved[IPCUFS_MAX_PATH_LEN - sizeof(u64)];
    u64 offset;                         /* File byte offset */
    u64 pa[64];                         /* 64 Page Physical Addresses */
    u32 len[64];                        /* Length of each page */
    u32 err;                            /* OUT: Return code */
} __packed;

struct ipcufs_u_readdir {
    u32 drive;                          /* IN: Drive number */
    char path[IPCUFS_MAX_PATH_LEN];     /* IN: Path of directory */
    u32 open;                           /* IN: bit 0: opendir, bit 1-31: target order */
    u32 err;                            /* OUT: Return code */
} __packed;

/* ========================================================================= */
/* 5. vblk (Virtual Block Device over IPCU) Commands & Structs               */
/* ========================================================================= */

enum vblk_action {
    VBLK_GETGEO = 0x3000,               /* Get disk geometry */
    VBLK_READ   = 0x3001,               /* Read block from RTOS */
    VBLK_WRITE  = 0x3002                /* Write block to RTOS */
};

struct vblk_geometry {
    u32 sectors;                        /* Number of 512-byte sectors */
    u32 err;                            /* Return code */
} __packed;

struct vblk_data_xfer {
    u32 start;                          /* Starting sector number */
    u32 length;                         /* Number of sectors */
    u64 addr;                           /* Physical DMA address of buffer */
    u32 err;                            /* Return code */
} __packed;

struct vblk_info_table {
    u32 action;                         /* enum vblk_action */
    u32 buffer_num;
    u32 plane_num;
    u32 __reserved[5];
    union {
        struct vblk_geometry geo;
        struct vblk_data_xfer xfer;
        u32 __pad[24];
    } c;
} __packed;

/* ========================================================================= */
/* 6. Userland IPCU IOCTL Definitions                                        */
/* ========================================================================= */

#define IPCU_IOCTL_MAGIC                0x66

struct ipcu_open_close_ch_argv {
    u32 direction;                      /* IPCU_DIR_SEND or IPCU_DIR_RECV */
};

struct ipcu_send_recv_msg_argv {
    void *buf;
    u32  len;
    u32  flags;
};

#ifdef __cplusplus
}
#endif

#endif /* S1M2_IPCU_H */
