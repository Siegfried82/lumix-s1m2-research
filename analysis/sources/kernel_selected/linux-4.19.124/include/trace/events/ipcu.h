#undef TRACE_SYSTEM
#define TRACE_SYSTEM ipcu

#if !defined(_TRACE_IPCU_H) || defined(TRACE_HEADER_MULTI_READ)
#define _TRACE_IPCU_H
#include <linux/tracepoint.h>

/* Send message is also catched by this event */
TRACE_EVENT(ipcu_send_req,

	TP_PROTO(u32 unit, u32 mb, u32 src, u32 *data),

	TP_ARGS(unit, mb, src, data),

	TP_STRUCT__entry(
		__field(	u32,	unit)
		__field(	u32,	mb)
		__field(	u32,	src)
		__field(unsigned long,	data_ptr)
	),

	TP_fast_assign(
		__entry->unit = unit;
		__entry->mb = mb;
		__entry->src = src;
		__entry->data_ptr = (unsigned long)data;
	),

	TP_printk("unit=%u mb=%u src=%u data=0x%lx",
		__entry->unit, __entry->mb, __entry->src, __entry->data_ptr)
);

TRACE_EVENT(ipcu_send_ack,

	TP_PROTO(u32 unit, u32 mb),

	TP_ARGS(unit, mb),

	TP_STRUCT__entry(
		__field(	u32,	unit)
		__field(	u32,	mb)
	),

	TP_fast_assign(
		__entry->unit = unit;
		__entry->mb = mb;
	),

	TP_printk("unit=%u mb=%u", __entry->unit, __entry->mb)
);

TRACE_EVENT(ipcu_handle_rec,

	TP_PROTO(u32 unit, u32 mb, int irq, u32 *data),

	TP_ARGS(unit, mb, irq, data),

	TP_STRUCT__entry(
		__field(	u32,	unit)
		__field(	u32,	mb)
		__field(	int,	irq)
		__field(unsigned long,	data_ptr)
	),

	TP_fast_assign(
		__entry->unit = unit;
		__entry->mb = mb;
		__entry->irq = irq;
		__entry->data_ptr = (unsigned long)data;
	),

	TP_printk("unit=%u mb=%u irq=%d data=%lx",
		 __entry->unit, __entry->mb, __entry->irq, __entry->data_ptr)
);

TRACE_EVENT(ipcu_handle_ack,

	TP_PROTO(u32 unit, u32 mb, int irq),

	TP_ARGS(unit, mb, irq),

	TP_STRUCT__entry(
		__field(	u32,	unit)
		__field(	u32,	mb)
		__field(	int,	irq)
	),

	TP_fast_assign(
		__entry->unit = unit;
		__entry->mb = mb;
		__entry->irq = irq;
	),

	TP_printk("unit=%u mb=%u irq=%d",
		 __entry->unit, __entry->mb, __entry->irq)
);

TRACE_EVENT(ipcu_open_mb,

	TP_PROTO(u32 unit, u32 mb, u32 direction),

	TP_ARGS(unit, mb, direction),

	TP_STRUCT__entry(
		__field(	u32,	unit)
		__field(	u32,	mb)
		__field(	u32,	dir)
	),

	TP_fast_assign(
		__entry->unit = unit;
		__entry->mb = mb;
		__entry->dir = direction
	),

	TP_printk("unit=%u mb=%u direction=%u", __entry->unit, __entry->mb,
		__entry->dir)
);

TRACE_EVENT(ipcu_close_mb,

	TP_PROTO(u32 unit, u32 mb, u32 direction),

	TP_ARGS(unit, mb, direction),

	TP_STRUCT__entry(
		__field(	u32,	unit)
		__field(	u32,	mb)
		__field(	u32,	dir)
	),

	TP_fast_assign(
		__entry->unit = unit;
		__entry->mb = mb;
		__entry->dir = direction
	),

	TP_printk("unit=%u mb=%u direction=%u", __entry->unit, __entry->mb,
		__entry->dir)
);

TRACE_EVENT(ipcu_recv_flush,

	TP_PROTO(u32 unit, u32 mb),

	TP_ARGS(unit, mb),

	TP_STRUCT__entry(
		__field(	u32,	unit)
		__field(	u32,	mb)
	),

	TP_fast_assign(
		__entry->unit = unit;
		__entry->mb = mb;
	),

	TP_printk("unit=%u mb=%u", __entry->unit, __entry->mb)
);

TRACE_EVENT(ipcu_start_recv_msg,

	TP_PROTO(u32 unit, u32 mb, void *buf, u32 flags),

	TP_ARGS(unit, mb, buf, flags),

	TP_STRUCT__entry(
		__field(	u32,	unit)
		__field(	u32,	mb)
		__field(unsigned long,	buf_ptr)
		__field(	u32,	flags)
	),

	TP_fast_assign(
		__entry->unit = unit;
		__entry->mb = mb;
		__entry->buf_ptr = (unsigned long)buf;
		__entry->flags = flags;
	),

	TP_printk("unit=%u mb=%u buf=%lx flags=%x",
		 __entry->unit, __entry->mb, __entry->buf_ptr, __entry->flags)
);

TRACE_EVENT(ipcu_recv_msg,

	TP_PROTO(u32 unit, u32 mb, void *buf, int result),

	TP_ARGS(unit, mb, buf, result),

	TP_STRUCT__entry(
		__field(	u32,	unit)
		__field(	u32,	mb)
		__field(unsigned long,	buf_ptr)
		__field(	int,	result)
	),

	TP_fast_assign(
		__entry->unit = unit;
		__entry->mb = mb;
		__entry->buf_ptr = (unsigned long)buf;
		__entry->result = result;
	),

	TP_printk("unit=%u mb=%u buf=%lx result=%d",
		 __entry->unit, __entry->mb, __entry->buf_ptr, __entry->result)
);

#endif

/* This part must be outside protection */
#include <trace/define_trace.h>
