// SPDX-License-Identifier: GPL-2.0
/*
 * qemu_oob.c - sandbox-only in-guest USB gadget "UDC" + FFS OOB driver
 *
 * PURPOSE
 *   The Lumix S1RM2 (S1M2) OSS kernel (linux-4.19.124) contains Panasonic's
 *   patched drivers/usb/gadget/function/f_fs.c. In ffs_func_get_alt()/
 *   ffs_func_set_alt(), the interface index is validated as a u8
 *   (ffs_func_revmap_intf(func, u8 intf)) but then used as a full 32-bit
 *   index into func->current_alt_setting[MAX_CONFIG_INTERFACES] (160 x u32):
 *
 *     composite_setup():  intf = w_index & 0xff;  // bounds-checked, < 160
 *       case USB_REQ_SET_INTERFACE:
 *           f = cdev->config->interface[intf];
 *           value = f->set_alt(f, w_index, w_value);   // FULL 16-bit w_index!
 *       case USB_REQ_GET_INTERFACE:
 *           value = f->get_alt ? f->get_alt(f, w_index) : 0;
 *           *((u8 *)req->buf) = value;                 // 1-byte read oracle
 *
 *   A host sending GET/SET_INTERFACE with wIndex = 0xNN00 (low byte = a
 *   registered interface) reaches current_alt_setting[0xNN00..0xNNFF] -
 *   an OOB slab read (1 byte low) / OOB slab write (u32, high16 zeroed).
 *
 *   QEMU has no guest-as-USB-device controller, so the USB bus cannot be
 *   driven from the host. Instead this module provides a minimal fake UDC
 *   (usb_add_gadget_udc) so the UNMODIFIED stock composite.c + f_fs.c can
 *   bind via configfs exactly as on the real camera, and a procfs interface
 *   injects the identical usb_ctrlrequest values the host would send:
 *
 *     echo "cfg <conf>"            > /proc/qoob   # SET_CONFIGURATION
 *     echo "get <wIndex>"          > /proc/qoob   # GET_INTERFACE (OOB read)
 *     echo "set <wIndex> <wValue>" > /proc/qoob   # SET_INTERFACE (OOB write)
 *     echo "scan <start> <n> <stride>" > /proc/qoob  # batch GET
 *     echo "status"                > /proc/qoob
 *
 *   Each response is printed to the console and kept in /proc/qoob_out.
 *
 * DEPENDS ON (sandbox-only tree patch, clearly marked in composite.c):
 *     int composite_sandbox_setup(struct usb_gadget *, const struct usb_ctrlrequest *);
 *
 * BUILD:  built into the sandbox kernel only (CONFIG_QEMU_OOB=y).
 *         Never present in the camera's production image.
 */
#include <linux/uaccess.h>
#include <linux/usb/gadget.h>
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/slab.h>
#include <linux/device.h>
#include <linux/proc_fs.h>
#include <linux/spinlock.h>
#include <linux/errno.h>
#include <linux/string.h>
#include <linux/usb/gadget.h>
#include <linux/usb/ch9.h>

#define QOOB_NAME	"qoob"

/* sandbox-only wrapper around static composite_setup() (see composite.c) */
extern int composite_sandbox_setup(struct usb_gadget *gadget,
				   const struct usb_ctrlrequest *ctrl);

/* ------------------------------------------------------------------ */
/* fake endpoints                                                      */
/* ------------------------------------------------------------------ */

static DEFINE_SPINLOCK(qoob_lock);
static u8  qoob_resp[512];
static int qoob_resp_len;
static int qoob_setup_ret;
static int qoob_setup_calls;

static int qoob_ep_enable(struct usb_ep *ep,
			  const struct usb_endpoint_descriptor *desc)
{
	return 0;
}

static int qoob_ep_disable(struct usb_ep *ep)
{
	return 0;
}

static void qoob_ep_dispose(struct usb_ep *ep)
{
}

static struct usb_request *qoob_alloc_request(struct usb_ep *ep, gfp_t gfp)
{
	return kzalloc(sizeof(struct usb_request), gfp);
}

static void qoob_free_request(struct usb_ep *ep, struct usb_request *req)
{
	kfree(req);
}

/*
 * composite_setup() queues the control response on ep0 (see composite.c
 * check_value:) with req->complete = composite_setup_complete (which
 * frees the request). Capture the data, then complete immediately.
 * The 1-byte response buf kmalloc'd by composite_setup is leaked on
 * purpose (sandbox: avoids touching the persistent os_desc_req buf).
 */
static int qoob_ep_queue(struct usb_ep *ep, struct usb_request *req,
			 gfp_t gfp)
{
	unsigned long flags;

	if (req->length > 0 && req->buf) {
		int n = min_t(int, req->length, (int)sizeof(qoob_resp));

		spin_lock_irqsave(&qoob_lock, flags);
		memcpy(qoob_resp, req->buf, n);
		qoob_resp_len = n;
		spin_unlock_irqrestore(&qoob_lock, flags);
	}

	if (req->complete)
		req->complete(ep, req);
	else
		usb_ep_free_request(ep, req);
	return 0;
}

static int qoob_ep_dequeue(struct usb_ep *ep, struct usb_request *req)
{
	return 0;
}

static const struct usb_ep_ops qoob_ep_ops = {
	.enable		= qoob_ep_enable,
	.disable	= qoob_ep_disable,
	.dispose	= qoob_ep_dispose,
	.alloc_request	= qoob_alloc_request,
	.free_request	= qoob_free_request,
	.queue		= qoob_ep_queue,
	.dequeue	= qoob_ep_dequeue,
};

static struct usb_endpoint_descriptor qoob_ep0_desc = {
	.bLength		= sizeof(struct usb_endpoint_descriptor),
	.bDescriptorType	= USB_DT_ENDPOINT,
	.bEndpointAddress	= 0x00,
	.bmAttributes		= USB_ENDPOINT_XFER_CONTROL,
	.wMaxPacketSize	= cpu_to_le16(64),
};

static struct usb_endpoint_descriptor qoob_ep1_desc = {
	.bLength		= sizeof(struct usb_endpoint_descriptor),
	.bDescriptorType	= USB_DT_ENDPOINT,
	.bEndpointAddress	= USB_DIR_IN | 0x01,
	.bmAttributes		= USB_ENDPOINT_XFER_BULK,
	.wMaxPacketSize	= cpu_to_le16(512),
};

static struct usb_endpoint_descriptor qoob_ep2_desc = {
	.bLength		= sizeof(struct usb_endpoint_descriptor),
	.bDescriptorType	= USB_DT_ENDPOINT,
	.bEndpointAddress	= 0x02,
	.bmAttributes		= USB_ENDPOINT_XFER_BULK,
	.wMaxPacketSize	= cpu_to_le16(512),
};

static struct usb_endpoint_descriptor qoob_ep3_desc = {
	.bLength		= sizeof(struct usb_endpoint_descriptor),
	.bDescriptorType	= USB_DT_ENDPOINT,
	.bEndpointAddress	= USB_DIR_IN | 0x03,
	.bmAttributes		= USB_ENDPOINT_XFER_BULK,
	.wMaxPacketSize	= cpu_to_le16(512),
};

static struct usb_endpoint_descriptor qoob_ep4_desc = {
	.bLength		= sizeof(struct usb_endpoint_descriptor),
	.bDescriptorType	= USB_DT_ENDPOINT,
	.bEndpointAddress	= 0x04,
	.bmAttributes		= USB_ENDPOINT_XFER_BULK,
	.wMaxPacketSize	= cpu_to_le16(512),
};

static struct usb_ep qoob_ep0 = {
	.name		= "ep0",
	.desc		= &qoob_ep0_desc,
	.ops		= &qoob_ep_ops,
	.maxpacket	= 64,
	.maxpacket_limit = 64,
	.caps		= USB_EP_CAPS(USB_EP_CAPS_TYPE_CONTROL,
				      USB_EP_CAPS_DIR_ALL),
};
static struct usb_ep qoob_ep1 = {
	.name		= "ep1in",
	.desc		= &qoob_ep1_desc,
	.ops		= &qoob_ep_ops,
	.maxpacket	= 512,
	.maxpacket_limit = 512,
	.caps		= USB_EP_CAPS(USB_EP_CAPS_TYPE_BULK,
				      USB_EP_CAPS_DIR_IN),
};
static struct usb_ep qoob_ep2 = {
	.name		= "ep2out",
	.desc		= &qoob_ep2_desc,
	.ops		= &qoob_ep_ops,
	.maxpacket	= 512,
	.maxpacket_limit = 512,
	.caps		= USB_EP_CAPS(USB_EP_CAPS_TYPE_BULK,
				      USB_EP_CAPS_DIR_OUT),
};
static struct usb_ep qoob_ep3 = {
	.name		= "ep3in",
	.desc		= &qoob_ep3_desc,
	.ops		= &qoob_ep_ops,
	.maxpacket	= 512,
	.maxpacket_limit = 512,
	.caps		= USB_EP_CAPS(USB_EP_CAPS_TYPE_BULK,
				      USB_EP_CAPS_DIR_IN),
};
static struct usb_ep qoob_ep4 = {
	.name		= "ep4out",
	.desc		= &qoob_ep4_desc,
	.ops		= &qoob_ep_ops,
	.maxpacket	= 512,
	.maxpacket_limit = 512,
	.caps		= USB_EP_CAPS(USB_EP_CAPS_TYPE_BULK,
				      USB_EP_CAPS_DIR_OUT),
};

/* ------------------------------------------------------------------ */
/* fake gadget                                                         */
/* ------------------------------------------------------------------ */

static void qoob_gadget_release(struct device *dev)
{
	/* static struct: nothing to free */
}

static struct device_type qoob_gadget_type = {
	.name = "usb_gadget_qoob",
};

static void qoob_parent_release(struct device *dev)
{
}

static struct device_type qoob_parent_type = {
	.name = "qoob_parent",
};

static struct device qoob_parent = {
	.init_name	= QOOB_NAME,
	.type		= &qoob_parent_type,
	.release	= qoob_parent_release,
};

static int qoob_udc_start(struct usb_gadget *g, struct usb_gadget_driver *d)
{
	return 0;
}

static int qoob_udc_stop(struct usb_gadget *g)
{
	return 0;
}

static int qoob_pullup(struct usb_gadget *g, int is_on)
{
	return 0;
}

static const struct usb_gadget_ops qoob_gadget_ops = {
	.udc_start	= qoob_udc_start,
	.udc_stop	= qoob_udc_stop,
	.pullup		= qoob_pullup,
};

static struct usb_gadget qoob_gadget = {
	.name		= QOOB_NAME,
	.ops		= &qoob_gadget_ops,
	.ep0		= &qoob_ep0,
	.speed		= USB_SPEED_HIGH,
	.max_speed	= USB_SPEED_HIGH,
	.is_selfpowered	= 1,
	.dev = {
		.type		= &qoob_gadget_type,
		.release	= qoob_gadget_release,
	},
};

/* ------------------------------------------------------------------ */
/* control request injection                                           */
/* ------------------------------------------------------------------ */

/*
 * Drive the composite setup callback - the same entry point the real UDC
 * hardware path uses (usb_gadget_driver.setup -> composite_setup()).
 */
static int qoob_send(u8 reqtype, u8 req, u16 wvalue, u16 windex, u16 wlength)
{
	struct usb_ctrlrequest cr = {
		.bRequestType = reqtype,
		.bRequest	= req,
		.wValue	= cpu_to_le16(wvalue),
		.wIndex	= cpu_to_le16(windex),
		.wLength	= cpu_to_le16(wlength),
	};
	unsigned long flags;
	mm_segment_t old_fs;
	int ret;

	if (!get_gadget_data(&qoob_gadget))
		return -ENODEV;

	spin_lock_irqsave(&qoob_lock, flags);
	qoob_resp_len = 0;
	spin_unlock_irqrestore(&qoob_lock, flags);

	old_fs = get_fs();
	set_fs(KERNEL_DS);
	ret = composite_sandbox_setup(&qoob_gadget, &cr);
	set_fs(old_fs);
	qoob_setup_ret = ret;
	qoob_setup_calls++;
	return ret;
}

/* GET_INTERFACE: bRequestType = 0x81 (IN | INTERFACE), bRequest = 11 */
static int qoob_get_alt(u16 windex, u8 *out_byte)
{
	int ret = qoob_send(USB_DIR_IN | USB_RECIP_INTERFACE,
			    USB_REQ_GET_INTERFACE, 0, windex, 1);
	if (ret >= 0 && qoob_resp_len > 0) {
		*out_byte = qoob_resp[0];
		return 0;
	}
	return ret < 0 ? ret : -EIO;
}

/* SET_INTERFACE: bRequestType = 0x01 (OUT | INTERFACE), bRequest = 12 */
static int qoob_set_alt(u16 windex, u16 wvalue)
{
	return qoob_send(USB_RECIP_INTERFACE, USB_REQ_SET_INTERFACE,
			 wvalue, windex, 0);
}

static int qoob_set_config(u16 config)
{
	return qoob_send(USB_RECIP_DEVICE, USB_REQ_SET_CONFIGURATION,
			 config, 0, 0);
}

/* ------------------------------------------------------------------ */
/* procfs                                                              */
/* ------------------------------------------------------------------ */

static char qoob_lastout[2048];
static int qoob_lastout_len;

static void qoob_report(const char *msg)
{
	int n;

	n = snprintf(qoob_lastout + qoob_lastout_len,
		     sizeof(qoob_lastout) - qoob_lastout_len, "%s", msg);
	if (n > 0)
		qoob_lastout_len += n;
	pr_info("qoob: %s", msg);
}

static int qoob_do_cmd(const char *line)
{
	char buf[160];
	int n;
	unsigned long a, b, c;

	qoob_lastout_len = 0;

	if (sscanf(line, "cfg %lu", &a) == 1) {
		int ret = qoob_set_config(a);
		n = snprintf(buf, sizeof(buf), "SET_CONFIGURATION(%lu) ret=%d\n",
			     a, ret);
		qoob_report(buf);
		return 0;
	}
	if (sscanf(line, "get %lx", &a) == 1) {
		u8 v;
		int ret = qoob_get_alt(a, &v);
		n = snprintf(buf, sizeof(buf), "GET_INTERFACE wIndex=0x%04lx ret=%d byte=0x%02x\n",
			     a, ret, ret == 0 ? v : 0);
		qoob_report(buf);
		return 0;
	}
	if (sscanf(line, "set %lx %lx", &a, &b) == 2) {
		int ret = qoob_set_alt(a, b);
		n = snprintf(buf, sizeof(buf), "SET_INTERFACE wIndex=0x%04lx wValue=0x%04lx ret=%d\n",
			     a, b, ret);
		qoob_report(buf);
		return 0;
	}
	if (sscanf(line, "scan %lx %lu %lx", &a, &b, &c) == 3) {
		unsigned long i;

		qoob_report("wIndex    ret byte\n");
		for (i = 0; i < b; i++, a += c) {
			u8 v;
			int ret = qoob_get_alt(a, &v);
			n = snprintf(buf, sizeof(buf), "0x%04lx  %4d  0x%02x\n",
				     a, ret, ret == 0 ? v : 0);
			qoob_report(buf);
		}
		return 0;
	}
	if (!strncmp(line, "status", 6)) {
		n = snprintf(buf, sizeof(buf),
			     "gadget=%s speed=%d composite_bound=%s setup_calls=%d\n",
			     qoob_gadget.name, qoob_gadget.speed,
			     get_gadget_data(&qoob_gadget) ? "yes" : "no",
			     qoob_setup_calls);
		qoob_report(buf);
		return 0;
	}
	n = snprintf(buf, sizeof(buf), "unknown cmd: %s\n", line);
	qoob_report(buf);
	return -EINVAL;
}

static ssize_t qoob_read(struct file *file, char __user *buf,
			 size_t count, loff_t *ppos)
{
	if (*ppos > 0)
		return 0;
	if (count > (size_t)qoob_lastout_len)
		count = qoob_lastout_len;
	if (count && __copy_to_user(buf, qoob_lastout, count))
		return -EFAULT;
	*ppos += count;
	return count;
}

static ssize_t qoob_write(struct file *file, const char __user *buf,
			  size_t count, loff_t *ppos)
{
	char *kbuf;

	if (count == 0 || count > 256)
		return -EINVAL;
	kbuf = kmalloc(count + 1, GFP_KERNEL);
	if (!kbuf)
		return -ENOMEM;
	if (__copy_from_user(kbuf, buf, count)) {
		kfree(kbuf);
		return -EFAULT;
	}
	kbuf[count] = 0;
	kbuf[strcspn(kbuf, "\r\n")] = 0;
	qoob_do_cmd(kbuf);
	kfree(kbuf);
	return count;
}
static const struct file_operations qoob_fops = {
	.owner	= THIS_MODULE,
	.read	= qoob_read,
	.write	= qoob_write,
};

static const struct file_operations qoob_out_fops = {
	.owner	= THIS_MODULE,
	.read	= qoob_read,
};

/* ------------------------------------------------------------------ */
/* init / exit                                                         */
/* ------------------------------------------------------------------ */

static struct proc_dir_entry *qoob_proc;
static struct proc_dir_entry *qoob_proc_out;

static int __init qoob_init(void)
{
	int ret;

	INIT_LIST_HEAD(&qoob_gadget.ep_list);
	list_add_tail(&qoob_ep1.ep_list, &qoob_gadget.ep_list);
	list_add_tail(&qoob_ep2.ep_list, &qoob_gadget.ep_list);
	list_add_tail(&qoob_ep3.ep_list, &qoob_gadget.ep_list);
	list_add_tail(&qoob_ep4.ep_list, &qoob_gadget.ep_list);

	ret = device_register(&qoob_parent);
	if (ret)
		return ret;

	ret = usb_add_gadget_udc(&qoob_parent, &qoob_gadget);
	if (ret) {
		pr_err("qoob: usb_add_gadget_udc failed: %d\n", ret);
		device_unregister(&qoob_parent);
		return ret;
	}

	qoob_proc = proc_create("qoob", 0600, NULL, &qoob_fops);
	qoob_proc_out = proc_create("qoob_out", 0444, NULL, &qoob_out_fops);
	if (!qoob_proc || !qoob_proc_out) {
		ret = -ENOENT;
		goto err_proc;
	}

	pr_info("qoob: fake UDC %s registered (ep0-ep4, HS); "
		"bind a configfs gadget and use /proc/qoob\n", QOOB_NAME);
	return 0;

err_proc:
	usb_del_gadget_udc(&qoob_gadget);
	device_unregister(&qoob_parent);
	return ret;
}

static void __exit qoob_exit(void)
{
	proc_remove(qoob_proc);
	proc_remove(qoob_proc_out);
	usb_del_gadget_udc(&qoob_gadget);
	device_unregister(&qoob_parent);
}

module_init(qoob_init);
module_exit(qoob_exit);
MODULE_LICENSE("GPL");
MODULE_AUTHOR("firmware_analysis sandbox");
MODULE_DESCRIPTION("fake UDC + f_fs OOB control-request driver (QEMU sandbox only)");
