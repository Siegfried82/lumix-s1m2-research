/* SPDX-License-Identifier: GPL-2.0 */
/*
 * these are the  structs and constants that define the transport of the
 * linux filesystem api
 */

#include <linux/sni_ipcu_parts.h>
#include <uapi/linux/ipcu_userland.h>

#define IPCUFS_MAX_PATH_LEN 520
#define IPCUFS_MAX_NAME_LEN 516

#define IPCU_COMMEM_DOMAIN_SIZE 0x8000
#define IPCUFS_PAGE_BUF_SIZE	0x2000
#define IPCUFS_TABLE_BUF_SIZE	(IPCU_COMMEM_DOMAIN_SIZE - IPCUFS_PAGE_BUF_SIZE)
#define IPCUFS_DIO_BUF_SIZE	(4 << 20)

/* For fake inode table */
#define IPCUFS_MAX_DRV_NUM 16
#define IPCUFS_MAX_INODE_NUM 65536

#define MAX_IPCUFS_PAGES_AT_ONCE 64

#define IPCUFS_TIME_YEAR_OFFSET 1980

#define	IPCUFS_ERR_OK  0
#define	IPCUFS_ERR_NG  1
#define	IPCUFS_ERR_EOF 3

#define	IPCUFS_OPEN_READ  0
#define	IPCUFS_OPEN_WRITE 1

/* this parameter is max nums of readahead at readdir. */
/* it is depend on how many information can be stored in the extended table.*/
/* same parameter exist on the RTOS side, also need to change that */
#define IPCUFS_READDIR_MAX	44

enum ipcufs_action {
	IFSA_MOUNTING = 0x2000,	/* Notify ipcufs start */
	IFSA_UMOUNTING,		/* Notify ipcufs end */
	IFSA_LOOKUP,		/* lookup a file from an inode */
	IFSA_READDIR,		/* get the next dir entry */
	IFSA_READPAGE,		/* fill a 4K page with file payload */
	IFSA_WRITEPAGE,		/* store payload from a 4K page */
	IFSA_IGET,		/* return given inode */
	IFSA_ICREATE,		/* set up a new inode */
	IFSA_IDELETE,		/* delete the inode */
	IFSA_IRENAME,		/* rename the inode */
	IFSA_ISTATFS,		/* get File System status */
	IFSA_OPEN,		/* open file */
	IFSA_CLOSE,		/* close file */
};

/* Messaging sub-data structures */
/* IFSA_MOUNTING */
struct ipcufs_u_imount {
	u32 drive;		/* IN: drive number for mount */
	u32 err;		/* OUT: return code */
} __packed;

/* IFSA_IGET */
struct ipcufs_u_iget {
	u32 drive;			/* IN: drive number */
	char path[IPCUFS_MAX_PATH_LEN];	/* IN: pathname for inode */
	u32 __reserved;
	u64 file_length;	/* OUT: the size of file (in byte) */
	u32 date;		/* OUT: creation date */
	u32 time;		/* OUT: creation time */
	u32 m_date;		/* OUT: last modify date */
	u32 m_time;		/* OUT: last modify time */
	u32 a_date;		/* OUT: last access date */
	u32 a_time;		/* OUT: last access time */
	u32 type;		/* OUT: type of the file */
	u32 err;		/* OUT: return code */
} __packed;

struct ipcufs_u_pages {
	uintptr_t fNo;		/* filled in on entry */
	char __reserved[IPCUFS_MAX_PATH_LEN - sizeof(uintptr_t)];
	u64 offset;		/* filled in on entry */
	uintptr_t pa[64];	/* filled in on entry */
	u32 len[64];		/* filled in on entry */
	u32 err;		/* filled in on return */
} __packed;

struct ipcufs_u_page {
	u32 drive;			/* filled in on entry */
	char path[IPCUFS_MAX_PATH_LEN];	/* filled in on entry */
	uintptr_t pa;			/* filled in on entry */
	u32 pos;			/* filled in on entry */
	u32 len;			/* filled in on entry */
	u32 err;			/* filled in on return */
} __packed;

/* get the next dir entry */
struct ipcufs_u_readdir {
	u32 drive;			/* IN: drive number */
	char path[IPCUFS_MAX_PATH_LEN];	/* IN: pathname of dir */
	u32 open;			/* IN: bit 1-31:target entry order */
					/*     bit 0:opendir */
	char filename[IPCUFS_MAX_NAME_LEN];	/* OUT: filename of entry */
	u32 type;			/* OUT: 1:directory 0:file */
	u32 err;			/* OUT: return code */
	u32 request_nums;		/* IN: request additional file nums */
	u32 response_nums;		/* OUT: responce additional file nums */
	u32 __reserved[3];
	char filenames[IPCUFS_READDIR_MAX][IPCUFS_MAX_NAME_LEN];
					/* OUT: filename of entry */
	u32 types[IPCUFS_READDIR_MAX];	/* OUT: 1:directory 0:file */
	u32 errors[IPCUFS_READDIR_MAX];	/* OUT: return code */
} __packed;

struct ipcufs_u_lookup {
	u32 drive;			/* filled in on entry */
	char path[IPCUFS_MAX_PATH_LEN];	/* filled in on entry */
	u32 err;			/* filled in on return */
} __packed;

struct ipcufs_u_icreate {
	u32 drive;			/* filled in on entry */
	char path[IPCUFS_MAX_PATH_LEN];	/* filled in on entry */
	u32 type;			/* filled in on entry */
	u32 err;			/* filled in on return */
};

struct ipcufs_u_idel {
	u32 drive;			/* filled in on entry */
	char path[IPCUFS_MAX_PATH_LEN];	/* filled in on entry */
	u32 type;			/* filled in on entry */
	u32 err;			/* filled in on return */
};

struct ipcufs_u_iren {
	u32 drive;				/* filled in on entry */
	char path[IPCUFS_MAX_PATH_LEN];		/* filled in on entry */
	u32 renamed_drive;			/* filled in on entry */
	char renamed_path[IPCUFS_MAX_PATH_LEN];	/* filled in on entry */
	u32 err;				/* filled in on return */
};

struct ipcufs_u_istat {
	u32 drive;		/* filled in on entry */
	u32 blksize;		/* filled in on return */
	u32 blocks;		/* filled in on return */
	u32 bfree;		/* filled in on return */
	u32 bbad;		/* filled in on return */
	u32 dstat;		/* filled in on return */
	u32 fstype;		/* filled in on return */
	u32 err;		/* filled in on return */
};

struct ipcufs_u_open {
	u32 drive;			/* filled in on entry */
	char path[IPCUFS_MAX_PATH_LEN];	/* filled in on entry */
	u32 mode;
	uintptr_t fNo;			/* filled in on return */
	u32 err;			/* filled in on return */
};

struct ipcufs_u_close {
	uintptr_t fNo;		/* filled in on entry */
	u32 err;		/* filled in on return */
};

/* Message data structure between RTOS and Linux */
struct ipcufs_info_table {
	union {
		enum ipcufs_action action;
		u32 __action;
	} u;
	u32 buffer_num;
	u32 plane_num;
	u32 __reserved[5];

	union {
		struct ipcufs_u_imount imount;
		struct ipcufs_u_iget iget;
		struct ipcufs_u_page page;
		struct ipcufs_u_pages pages;
		struct ipcufs_u_lookup lookup;
		struct ipcufs_u_icreate icreate;
		struct ipcufs_u_idel idel;
		struct ipcufs_u_iren iren;
		struct ipcufs_u_istat istat;
		struct ipcufs_u_open open;
		struct ipcufs_u_close close;
		u32 __reserved[504];
	} c;
};

/* Message data structure between RTOS and Linux for readdir */
struct ipcufs_info_table_readdir {
	union {
		enum ipcufs_action action;
		u32 __action;
	} u;

	u32 buffer_num;
	u32 plane_num;
	u32 __reserved[5];

	union {
		struct ipcufs_u_readdir rdir;
		u32 __reserved[6136];
	} c;
};
