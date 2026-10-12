/******************************************************************************
 *
 *  @file   ipcu_userland.h
 *  @brief  Userland Definition
 *
 *  Copyright 2015 Socionext Inc.
 ******************************************************************************/
#ifndef __IPCU_USERLAND_H
#define __IPCU_USERLAND_H


/********************************************************************
 *  Type define
 ********************************************************************/
/* standard type */
typedef signed char         INT8;
typedef signed short        INT16;
typedef signed int          INT32;
typedef signed long long    INT64;
typedef unsigned char       UINT8;
typedef unsigned short      UINT16;
typedef unsigned int        UINT32;
typedef unsigned long long  UINT64;

/* type definition conversion between cpu_linux-cpu_rtos */
typedef void                VOID;
typedef INT8                CHAR;
typedef INT16               SHORT;
typedef INT32               LONG;
typedef INT64               LLONG;
typedef UINT8               UCHAR;
typedef UINT16              USHORT;
typedef UINT32              ULONG;
typedef UINT64              ULLONG;

/********************************************************************
 *  Common define definition
 ********************************************************************/
#define D_SYS_ON                 (1)
#define D_SYS_OFF                (0)

#define D_SYS_NO_ERR             (0)
#define D_SYS_ERR_SYSCALL        (-1)
#define D_SYS_ERR_DET_SHM        (-2)
#define D_SYS_ERR_PARAM          (-3)

#define D_COM_IPCU_MSG_SIZE_MAX  (256)          /*  max value(message size)  */
#define D_COM_IPCU_MSG_INDEX_MAX (256)          /*  max value(message index) */

#define D_NOT_CONTINUE           (0x00000000)   /* 0:Not Continue */
#define D_CONTINUE               (0x00000001)   /* 1:Continue     */

#define IPCU_DEV_NAME0           "/dev/snrtos0"
#define IPCU_DEV_NAME1           "/dev/snrtos1"
#define IPCU_DEV_NAME2           "/dev/snrtos2"
#define IPCU_DEV_NAME3           "/dev/snrtos3"
#define IPCU_DEV_NAME4           "/dev/snrtos4"
#define IPCU_DEV_NAME5           "/dev/snrtos5"
#define IPCU_DEV_NAME6           "/dev/snrtos6"
#define IPCU_DEV_NAME7           "/dev/snrtos7"

#define IPCU_DEV_NAME0_UNIT0     "/dev/snrtos0_0"
#define IPCU_DEV_NAME1_UNIT0     "/dev/snrtos0_1"
#define IPCU_DEV_NAME2_UNIT0     "/dev/snrtos0_2"
#define IPCU_DEV_NAME3_UNIT0     "/dev/snrtos0_3"
#define IPCU_DEV_NAME4_UNIT0     "/dev/snrtos0_4"
#define IPCU_DEV_NAME5_UNIT0     "/dev/snrtos0_5"
#define IPCU_DEV_NAME6_UNIT0     "/dev/snrtos0_6"
#define IPCU_DEV_NAME7_UNIT0     "/dev/snrtos0_7"
#define IPCU_DEV_NAME0_UNIT1     "/dev/snrtos1_0"
#define IPCU_DEV_NAME1_UNIT1     "/dev/snrtos1_1"
#define IPCU_DEV_NAME2_UNIT1     "/dev/snrtos1_2"
#define IPCU_DEV_NAME3_UNIT1     "/dev/snrtos1_3"
#define IPCU_DEV_NAME4_UNIT1     "/dev/snrtos1_4"
#define IPCU_DEV_NAME5_UNIT1     "/dev/snrtos1_5"
#define IPCU_DEV_NAME6_UNIT1     "/dev/snrtos1_6"
#define IPCU_DEV_NAME7_UNIT1     "/dev/snrtos1_7"
#define IPCU_DEV_NAME0_UNIT2     "/dev/snrtos2_0"
#define IPCU_DEV_NAME1_UNIT2     "/dev/snrtos2_1"
#define IPCU_DEV_NAME2_UNIT2     "/dev/snrtos2_2"
#define IPCU_DEV_NAME3_UNIT2     "/dev/snrtos2_3"
#define IPCU_DEV_NAME4_UNIT2     "/dev/snrtos2_4"
#define IPCU_DEV_NAME5_UNIT2     "/dev/snrtos2_5"
#define IPCU_DEV_NAME6_UNIT2     "/dev/snrtos2_6"
#define IPCU_DEV_NAME7_UNIT2     "/dev/snrtos2_7"

#define IPCU_IOCTL_MAGIC         0x66
#define IPCU_IOCTL_MAXNR         7

#define IPCU_IOCTL_OPENCH        _IOW(IPCU_IOCTL_MAGIC, 1, struct ipcu_open_close_ch_argv)
#define IPCU_IOCTL_CLOSECH       _IOW(IPCU_IOCTL_MAGIC, 2, struct ipcu_open_close_ch_argv)
#define IPCU_IOCTL_SENDMSG       _IOW(IPCU_IOCTL_MAGIC, 3, struct ipcu_send_recv_msg_argv)
#define IPCU_IOCTL_RECVMSG       _IOWR(IPCU_IOCTL_MAGIC, 4, struct ipcu_send_recv_msg_argv)
#define IPCU_IOCTL_ACKSEND       _IOW(IPCU_IOCTL_MAGIC, 5, struct ipcu_send_recv_msg_argv)
#define IPCU_IOCTL_RECV_FLASH    _IOW(IPCU_IOCTL_MAGIC, 6, struct ipcu_send_recv_msg_argv)

#define IPCU_DIR_SEND            (1)             /* channel send   */
#define IPCU_DIR_RECV            (2)             /* channel recive */

#define FLAG_SEND_NOTIFY         (0x80000000)
#define FLAG_RECV_WAIT           (0xFFFFFFFF)
#define MASK_RECV_TIMEOUT        (0x7fffffff)


#define COMMEM_PATH              "/dev/mem"      /* Shared memory path                       */

#define IPCU_CARD_DETECT_COMMAND   (0x0001)

/********************************************************************
 *  Debug print
 ********************************************************************/
/*  Trace log output macro      */
#define M_PRINT_TRACE(STRING, ...) printf("%s:%s()[%d]:-- TRACE  "STRING"\n", __FILE__, __func__, __LINE__, ## __VA_ARGS__)
/*  Error log output macro      */
#define M_PRINT_ERROR(STRING, ...) printf("%s:%s()[%d]:** ERROR  "STRING"\n", __FILE__, __func__, __LINE__, ## __VA_ARGS__)
/*  Debug log output macro      */
#define M_PRINT_DEBUG(STRING, ...) printf("%s:%s()[%d]:=> DEBUG  "STRING"\n", __FILE__, __func__, __LINE__, ## __VA_ARGS__)


/********************************************************************
 * Enum definition that describes each channel of IPCU
 ********************************************************************/
typedef enum {
    E_FJ_IPCU_MAILBOX_TYPE_0 = 0,    /* mailbox-0 and command type-0 */
    E_FJ_IPCU_MAILBOX_TYPE_1,        /* mailbox-1 and command type-1 */
    E_FJ_IPCU_MAILBOX_TYPE_2,        /* mailbox-2 and command type-2 */
    E_FJ_IPCU_MAILBOX_TYPE_3,        /* mailbox-3 and command type-3 */
    E_FJ_IPCU_MAILBOX_TYPE_4,        /* mailbox-4 and command type-4 */
    E_FJ_IPCU_MAILBOX_TYPE_5,        /* mailbox-5 and command type-5 */
    E_FJ_IPCU_MAILBOX_TYPE_6,        /* mailbox-6 and command type-6 */
    E_FJ_IPCU_MAILBOX_TYPE_7,        /* mailbox-7 and command type-7 */
    E_FJ_IPCU_MAILBOX_TYPE_8,        /* mailbox-8 and command type-8 */
    E_FJ_IPCU_MAILBOX_TYPE_9,        /* mailbox-9 and command type-9 */
    E_FJ_IPCU_MAILBOX_TYPE_10,       /* mailbox-10 and command type-10 */
    E_FJ_IPCU_MAILBOX_TYPE_11,       /* mailbox-11 and command type-11 */
    E_FJ_IPCU_MAILBOX_TYPE_12,       /* mailbox-12 and command type-12 */
    E_FJ_IPCU_MAILBOX_TYPE_13,       /* mailbox-13 and command type-13 */
    E_FJ_IPCU_MAILBOX_TYPE_14,       /* mailbox-14 and command type-14 */
    E_FJ_IPCU_MAILBOX_TYPE_15,       /* mailbox-15 and command type-15 */
    E_FJ_IPCU_MAILBOX_TYPE_16,       /* mailbox-16 and command type-16 */
    E_FJ_IPCU_MAILBOX_TYPE_17,       /* mailbox-17 and command type-17 */
    E_FJ_IPCU_MAILBOX_TYPE_18,       /* mailbox-18 and command type-18 */
    E_FJ_IPCU_MAILBOX_TYPE_19,       /* mailbox-19 and command type-19 */
    E_FJ_IPCU_MAILBOX_TYPE_20,       /* mailbox-20 and command type-20 */
    E_FJ_IPCU_MAILBOX_TYPE_21,       /* mailbox-21 and command type-21 */
    E_FJ_IPCU_MAILBOX_TYPE_22,       /* mailbox-22 and command type-22 */
    E_FJ_IPCU_MAILBOX_TYPE_23,       /* mailbox-23 and command type-23 */
    E_FJ_IPCU_MAILBOX_TYPE_MAX
} E_FJ_IPCU_MAILBOX_TYPE;

/********************************************************************
 *  IPCU ioctl structure
 ********************************************************************/
struct ipcu_open_close_ch_argv {
	UINT32      direction;
};

struct ipcu_send_recv_msg_argv {
	void*       buf;
	UINT32      len;
	UINT32      flags;
};

/********************************************************************
 *  IPCU IF structure
 ********************************************************************/
typedef struct {
    UINT32       id;
    UINT32       bufl;
#ifdef CONFIG_PHYS_ADDR_T_64BIT
    UINT32       bufh;
#endif
    UINT32       len;
    UINT32       cont;
    UINT32       total_len;
    UINT32       logical_ch;
}T_IPCU_IF;

/******************************************************************** 
 *  IPCU IF structure between RTOS
 ********************************************************************/
typedef struct {
	UINT32		command;        // 1:notify for card detect
	UINT32		card_state;     // 0:Eject 1:Insert
	UINT32		ch;             // 0:SD0 1:SD1
} T_IPCU_IF_CARD_DETECT;

#endif	/* __IPCU_USERLAND_H */
