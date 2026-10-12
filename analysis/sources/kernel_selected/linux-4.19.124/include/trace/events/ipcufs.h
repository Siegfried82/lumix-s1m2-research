/* SPDX-License-Identifier: GPL-2.0 */
#undef TRACE_SYSTEM
#define TRACE_SYSTEM ipcufs

#if !defined(_TRACE_IPCUFS_H) || defined(TRACE_HEADER_MULTI_READ)
#define _TRACE_IPCUFS_H
#include <linux/tracepoint.h>

TRACE_EVENT(ipcufs_transfer_enter,

	TP_PROTO(void *data, int len),

	TP_ARGS(data, len),

	TP_STRUCT__entry(
		__field(unsigned long,	data_ptr)
		__field(int,	len)
	),

	TP_fast_assign(
		__entry->data_ptr = (unsigned long)data;
		__entry->len = len;
	),

	TP_printk("data=0x%lx len=%d", __entry->data_ptr, __entry->len)
);

TRACE_EVENT(ipcufs_transfer_exit,

	TP_PROTO(void *data, int len, int ret),

	TP_ARGS(data, len, ret),

	TP_STRUCT__entry(
		__field(unsigned long,	data_ptr)
		__field(int,	len)
		__field(int,	ret)
	),

	TP_fast_assign(
		__entry->data_ptr = (unsigned long)data;
		__entry->len = len;
		__entry->ret = ret;
	),

	TP_printk("data=0x%lx len=%d ret=%d",
		 __entry->data_ptr, __entry->len, __entry->ret)
);

TRACE_EVENT(ipcufs_readpage_enter,

	TP_PROTO(unsigned long ino, void *page),

	TP_ARGS(ino, page),

	TP_STRUCT__entry(
		__field(unsigned long,	ino)
		__field(unsigned long,	page_ptr)
	),

	TP_fast_assign(
		__entry->ino = ino;
		__entry->page_ptr = (unsigned long)page;
	),

	TP_printk("inode=%lu page=%lx", __entry->ino, __entry->page_ptr)
);

TRACE_EVENT(ipcufs_readpage_exit,

	TP_PROTO(unsigned long ino, int ret),

	TP_ARGS(ino, ret),

	TP_STRUCT__entry(
		__field(unsigned long,	ino)
		__field(int,	ret)
	),

	TP_fast_assign(
		__entry->ino = ino;
		__entry->ret = ret;
	),

	TP_printk("inode=%lu ret=%d", __entry->ino, __entry->ret)
);

TRACE_EVENT(ipcufs_readpages_enter,

	TP_PROTO(unsigned long ino, unsigned int nr_pages),

	TP_ARGS(ino, nr_pages),

	TP_STRUCT__entry(
		__field(unsigned long,	ino)
		__field(unsigned int,	nr_pages)
	),

	TP_fast_assign(
		__entry->ino = ino;
		__entry->nr_pages = nr_pages;
	),

	TP_printk("inode=%lu nr_pages=%u", __entry->ino, __entry->nr_pages)
);

TRACE_EVENT(ipcufs_readpages_exit,

	TP_PROTO(unsigned long ino, int ret),

	TP_ARGS(ino, ret),

	TP_STRUCT__entry(
		__field(unsigned long,	ino)
		__field(int,	ret)
	),

	TP_fast_assign(
		__entry->ino = ino;
		__entry->ret = ret;
	),

	TP_printk("inode=%lu ret=%d", __entry->ino, __entry->ret)
);

TRACE_EVENT(ipcufs_write_end,

	TP_PROTO(unsigned long ino, int ret),

	TP_ARGS(ino, ret),

	TP_STRUCT__entry(
		__field(unsigned long,	ino)
		__field(int,	ret)
	),

	TP_fast_assign(
		__entry->ino = ino;
		__entry->ret = ret;
	),

	TP_printk("inode=%lu ret=%d", __entry->ino, __entry->ret)
);

TRACE_EVENT(ipcufs_direct_io_enter,

	TP_PROTO(unsigned long ino, u32 size),

	TP_ARGS(ino, size),

	TP_STRUCT__entry(
		__field(unsigned long,	ino)
		__field(u32,	size)
	),

	TP_fast_assign(
		__entry->ino = ino;
		__entry->size = size;
	),

	TP_printk("inode=%lu size=%u", __entry->ino, __entry->size)
);

TRACE_EVENT(ipcufs_direct_io_exit,

	TP_PROTO(unsigned long ino, u32 size),

	TP_ARGS(ino, size),

	TP_STRUCT__entry(
		__field(unsigned long,	ino)
		__field(s32,	ret)
	),

	TP_fast_assign(
		__entry->ino = ino;
		__entry->ret = (s32)size;
	),

	TP_printk("inode=%lu ret=%u", __entry->ino, __entry->ret)
);

TRACE_EVENT(ipcufs_iget,

	TP_PROTO(unsigned long ino),

	TP_ARGS(ino),

	TP_STRUCT__entry(
		__field(unsigned long,	ino)
	),

	TP_fast_assign(
		__entry->ino = ino;
	),

	TP_printk("inode=%lu", __entry->ino)
);

#endif

/* This part must be outside protection */
#include <trace/define_trace.h>
