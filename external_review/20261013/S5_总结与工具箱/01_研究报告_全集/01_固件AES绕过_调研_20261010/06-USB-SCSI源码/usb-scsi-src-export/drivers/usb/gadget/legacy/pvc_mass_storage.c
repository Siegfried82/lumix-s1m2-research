/*  pvc_mass_storage.c: 
    This mass storage class driver is heavily based on NetChip Technology
	USB Mass Storage Device Driver for Linux2.4, and detail of the NetChip
    driver is described in below.
    Additionally, optional modification for PVC Equipments are implemented
	by Panasonic.
	(c) 2004-2008, Matsushita Electric industrial Co.,Ltd.(Panasonic)
*/

/*  
 * mass_storage.c: USB Mass Storage Device Driver
 *
 * (c) 2003, NetChip Technology, Inc. (http://www.netchip.com/)
 *
 * Copyright (c) 2020 Panasonic Corporation
 * 2020-07-16 Modified
 *
 * This driver implements a mass storage RAM disk on top of the
 * USB Gadget driver.
 *
 * This driver has only been tested on the NetChip NET2280.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2, or (at your option)
 * any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

//#include <asm/system.h>
#include <asm/uaccess.h>

#include <linux/bitops.h>
#include <linux/blkdev.h>
#include <linux/compiler.h>
#include <linux/completion.h>
#include <linux/dcache.h>
#include <linux/delay.h>
#include <linux/device.h>
#include <linux/fcntl.h>
#include <linux/file.h>
#include <linux/fs.h>
#include <linux/init.h>
#include <linux/kernel.h>
#include <linux/kref.h>
#include <linux/kthread.h>
#include <linux/limits.h>
#include <linux/list.h>
#include <linux/module.h>
#include <linux/moduleparam.h>
#include <linux/pagemap.h>
#include <linux/rwsem.h>
#include <linux/sched.h>
#include <linux/signal.h>
#include <linux/slab.h>
#include <linux/spinlock.h>
#include <linux/string.h>
#include <linux/freezer.h>
#include <linux/utsname.h>
#include <linux/poll.h>

#include <linux/usb/ch9.h>
#include <linux/usb/gadget.h>
#include <linux/cdev.h>

#define CONFIG_PVCUSB_LUN 1

#include <linux/pvc_mass_storage.h>

/* Internal macros		*/
/* Driver Information */
//#define DRIVER_DESC             CONFIG_PVCUSB_DRIVER_DESC
#define DRIVER_DESC	"PVC deck"

#define DRIVER_VERSION          "0000"
#define DRIVER_SHORT_NAME       "ms"
//#define DEVICE_MANUFACTURER     "Panasonic"

/* Device Information */
#define DEVICE_VENDOR_NUM       0x04DA  /* Panasonic */
//#define DEVICE_PRODUCT_NUM      CONFIG_PVCUSB_DEVICE_PRODUCT_NUM


//#define DEVICE_PRODUCT_NUM	0x2811		// MPC8377
//#define DEVICE_PRODUCT_NUM	0x2467		// K460		AU-EVA1
#define DEVICE_PRODUCT_NUM		0x2834		// K519(仮)
//#define DEVICE_PRODUCT_NUM	0x2836		// K518(仮)

#define DEVICE_REVISION         0x0001  /* 0.0.0.1 */
#define MAX_USB_POWER           0

#define USB_POWER_SS			0x70	//900mA
#define USB_POWER_HS			0xFA	//500mA

/* Endpoint Information */
#define EP0_MAXPACKET           64
#define USB_BUFSIZ              8192	//512

/* Default size of buffer length. */
#define FSG_BUFLEN	((uint32_t)16384)

/*  Kernel Logging Macros */
//#define PVCUSB_DEBUG
#define PVCUSB_ERROR

#define xprintk(level,fmt,args...) \
	printk(level "%s: " fmt, shortname, ## args)

#ifdef PVCUSB_DEBUG
#define PVCDEBUG(fmt,args...)    xprintk(KERN_ERR, fmt, ## args)
#else
#define PVCDEBUG(fmt,args...) while(0) {;}
#endif
#ifdef PVCUSB_ERROR
#define PVCERROR(fmt,args...)    xprintk(KERN_ERR, fmt, ## args)
#else
#define PVCERROR(fmt,args...) while(0) {;}
#endif
/*  
 * These constants describe the driver's name and description used
 * throughout the system.
 */
static struct cdev pvc_ms_dev;

//static const int8_t longname[] = DRIVER_DESC;
static const int8_t shortname[] = DRIVER_SHORT_NAME;
static const int8_t driver_desc[] = DRIVER_DESC;

/* Name of Endpoints for BBB	*/
static const int8_t EP_OUT_NAME[] = "ep1out";	/* name of out ep will be created in the driver to bind	*/
static const int8_t EP_IN_NAME[] = "ep1in";		/* name of in ep will be created in the driver to bind */

/*
 * These are the USB descriptors used for enumeration.  They should function
 * correctly on both full-speed and high-speed hosts.  Details on the meanings  
 * of the values in these structures can be seen in the USB and Mass Storage 
 * Class specs.
 */
#define STRING_MANUFACTURER		1
#define STRING_PRODUCT      	2
#define STRING_SERIAL       	3
#define STRING_INTERFACE    	4
#define STRING_CONFIG_SELF_P 	5
#define STRING_CONFIG_BUS_P 	6

/* Bulk-only class specific requests */
#define USB_BULK_RESET_REQUEST			0xFF
#define USB_BULK_GET_MAX_LUN_REQUEST	0xFE

/* USB Peripheral definition    */
#define USB_PR_BULK 0x50        /* Bulk-only        */
#define USB_SC_SCSI 0x06        /* Transparent SCSI */


#define FSG_VENDOR_ID	0x0525	/* NetChip */
#define FSG_PRODUCT_ID	0xa4a5	/* Linux-USB File-backed Storage Gadget */

/* USB Device Descriptor	*/
static struct usb_device_descriptor device_desc = {
	.bLength = sizeof device_desc,
	.bDescriptorType = USB_DT_DEVICE,

	.bcdUSB = __constant_cpu_to_le16(0x0200),
	.bDeviceClass = USB_CLASS_PER_INTERFACE,
	.bDeviceSubClass = 0,
	.bDeviceProtocol = 0,
	.bMaxPacketSize0 = EP0_MAXPACKET,

	.idVendor = __constant_cpu_to_le16(DEVICE_VENDOR_NUM),
	.idProduct = __constant_cpu_to_le16(DEVICE_PRODUCT_NUM),
	.bcdDevice = __constant_cpu_to_le16(DEVICE_REVISION),
	.iManufacturer = STRING_MANUFACTURER,
	.iProduct = STRING_PRODUCT,
	.iSerialNumber = STRING_SERIAL,

	.bNumConfigurations = 1,
};

/* Configuration Descriptor	*/
static struct usb_config_descriptor config_desc = {
	.bLength = sizeof config_desc,
	.bDescriptorType = USB_DT_CONFIG,
	.bNumInterfaces = 1,
	.bConfigurationValue = 1,
	.iConfiguration = STRING_CONFIG_SELF_P,
	.bmAttributes = USB_CONFIG_ATT_ONE | USB_CONFIG_ATT_SELFPOWER,
	.bMaxPower = MAX_USB_POWER,
};

/* Interface Descriptor		*/
static struct usb_interface_descriptor intf_desc = {
	.bLength = sizeof intf_desc,
	.bDescriptorType = USB_DT_INTERFACE,

	.bNumEndpoints = 2, 		/* Only Bulk IN and Bulk OUT (BBB)	*/
	.bInterfaceClass = USB_CLASS_MASS_STORAGE,
	.bInterfaceSubClass = USB_SC_SCSI, /* SCSI		*//* Modified [SBG-SAV]    */
	.bInterfaceProtocol = USB_PR_BULK, /* BULK ONLY	*//* Modified [SBG-SAV]    */
	.iInterface = STRING_INTERFACE,
};

/* Full Speed Bulk IN Endpoint Descriptor   */
static struct usb_endpoint_descriptor fs_bulk_in_desc = {
    .bLength = USB_DT_ENDPOINT_SIZE,
    .bDescriptorType = USB_DT_ENDPOINT,

	.bEndpointAddress = USB_DIR_IN,
    .bmAttributes = USB_ENDPOINT_XFER_BULK,
    .wMaxPacketSize = __constant_cpu_to_le16(64),
    .bInterval = 0,
};

/* Full Speed Bulk OUT Endpoint Descriptor  */
static struct usb_endpoint_descriptor fs_bulk_out_desc = {
    .bLength = USB_DT_ENDPOINT_SIZE,
    .bDescriptorType = USB_DT_ENDPOINT,

	.bEndpointAddress = USB_DIR_OUT,
    .bmAttributes = USB_ENDPOINT_XFER_BULK,
    .wMaxPacketSize = __constant_cpu_to_le16(64),
    .bInterval = 0,
};

/* High Speed Bulk IN Endpoint Descriptor   */
static struct usb_endpoint_descriptor hs_bulk_in_desc = {
    .bLength = USB_DT_ENDPOINT_SIZE,
    .bDescriptorType = USB_DT_ENDPOINT,

	.bEndpointAddress = USB_DIR_IN,
    .bmAttributes = USB_ENDPOINT_XFER_BULK,
    .wMaxPacketSize = __constant_cpu_to_le16(512),
    .bInterval = 0,
};

/* High Speed Bulk OUT Endpoint Descriptor  */
static struct usb_endpoint_descriptor hs_bulk_out_desc = {
    .bLength = USB_DT_ENDPOINT_SIZE,
    .bDescriptorType = USB_DT_ENDPOINT,

	.bEndpointAddress = USB_DIR_OUT,
    .bmAttributes = USB_ENDPOINT_XFER_BULK,
    .wMaxPacketSize = __constant_cpu_to_le16(512),
    .bInterval = 1,	/* NAK every 1 uframe */
};

/* Super Speed Bulk IN Endpoint Descriptor   */
static struct usb_endpoint_descriptor ss_bulk_in_desc = {
    .bLength = USB_DT_ENDPOINT_SIZE,
    .bDescriptorType = USB_DT_ENDPOINT,

	.bEndpointAddress = USB_DIR_IN,
    .bmAttributes = USB_ENDPOINT_XFER_BULK,
    .wMaxPacketSize = __constant_cpu_to_le16(1024),
    .bInterval = 0,
};

struct usb_ss_ep_comp_descriptor ss_bulk_in_comp_desc = {
	.bLength =		sizeof(ss_bulk_in_comp_desc),
	.bDescriptorType =	USB_DT_SS_ENDPOINT_COMP,

	/*.bMaxBurst =		DYNAMIC, */
};

/* Super Speed Bulk OUT Endpoint Descriptor  */
static struct usb_endpoint_descriptor ss_bulk_out_desc = {
    .bLength = USB_DT_ENDPOINT_SIZE,
    .bDescriptorType = USB_DT_ENDPOINT,

    .bEndpointAddress = USB_DIR_OUT,
    .bmAttributes = USB_ENDPOINT_XFER_BULK,
    .wMaxPacketSize = __constant_cpu_to_le16(1024),
    .bInterval = 0,
};

struct usb_ss_ep_comp_descriptor ss_bulk_out_comp_desc = {
	.bLength =		sizeof(ss_bulk_out_comp_desc),
	.bDescriptorType =	USB_DT_SS_ENDPOINT_COMP,

	/*.bMaxBurst =		DYNAMIC, */
};


/* Device Qualifier Descriptor	*/
static struct usb_qualifier_descriptor dev_qualifier = {
	.bLength = sizeof dev_qualifier,
	.bDescriptorType  = USB_DT_DEVICE_QUALIFIER,
	.bcdUSB = __constant_cpu_to_le16(0x0200),
	.bDeviceClass = USB_CLASS_PER_INTERFACE,
	.bMaxPacketSize0 = EP0_MAXPACKET,
	.bNumConfigurations = 1
};

static const struct usb_descriptor_header *fs_function[] = {
	(struct usb_descriptor_header *) &intf_desc,
	(struct usb_descriptor_header *) &fs_bulk_in_desc,
	(struct usb_descriptor_header *) &fs_bulk_out_desc,
	NULL,
};

static const struct usb_descriptor_header *hs_function[] = {
	(struct usb_descriptor_header *) &intf_desc,
	(struct usb_descriptor_header *) &hs_bulk_in_desc,
	(struct usb_descriptor_header *) &hs_bulk_out_desc,
	NULL,
};

static const struct usb_descriptor_header *ss_function[] = {
	(struct usb_descriptor_header *) &intf_desc,
	(struct usb_descriptor_header *) &ss_bulk_in_desc,
	(struct usb_descriptor_header *) &ss_bulk_in_comp_desc,
	(struct usb_descriptor_header *) &ss_bulk_out_desc,
	(struct usb_descriptor_header *) &ss_bulk_out_comp_desc,
	NULL,
};

/* Endpoint Extraction */
#define ep_desc(g,hs,fs) (((g)->speed==USB_SPEED_HIGH)?(hs):(fs))


/* Big enough to hold our biggest descriptor */
#define EP0_BUFSIZE 1024		// 256

/* current state */
#define POW_ON           0
#define INIT             1
#define CBW_READY        2
#define CBW_DONE         3
#define CMD_READY        4
#define CMD_DONE         5
#define SET_READY_DATA   6
#define SET_READY_CSW    7
#define SET_DONE         8
#define WAIT_NEXT        9

#define MS_DRV_NAME "g_ms"
#define MS_MAJOR 232

/* Bulk-Only Command Constants */
#define CBW_VALID_SIGNATURE     0x43425355
#define CSW_VALID_SIGNATURE     0x53425355
#define CBW_SIZE                0x1F
#define CSW_SIZE                0x0D

#define	MAX_PACKET_SIZE			1024	// USB 3.0

/* Data Status Constants */
#define DATA_OK     0   /* Sent/Recieved some data normally */
#define NO_DATA_REQD    1   /* No data was required - must manually send CSW */
#define DATA_ERR    2   /* Command failed/unimplemented */

/* Gadget Device Structure */
struct ms_dev {
    spinlock_t lock;
    struct usb_gadget *gadget;
    struct usb_request *req;
    uint8_t config;
    struct usb_ep *in_ep;
    struct usb_ep *out_ep;
    struct semaphore mutex_ms_dev;
};

/* Mass Storage state machine definitions */
typedef enum {
    IDLE,           /* Waiting for CBW */
    RESPONSE,       /* Sending/Receiveing command data */
    SEND_CSW        /* Sending CSW */
} ms_state;

/* Status of an executed SCSI command */
typedef enum {
    CMD_OK,         /* Responded correctly to SCSI command */
    CMD_UNIMPLEMENTED,  /* SCSI command not handled */
    CMD_ERROR,      /* Error processing SCSI command */
} ms_command_status;

struct pvc_ms_req {
    struct list_head list_ms_dev;
    uint16_t WhichReturn;
    uint16_t ConnectStatus;
    uint32_t ReturnStatus;
    uint32_t TransferedLength;
};

struct transfer_context {
    ms_state state;
    struct PVCUSB_cbw cmd;
    int32_t status;
    int32_t free_buffer;
    void *extra;
};

/* Device Serial Number	*/
static int8_t manufacturer[PVCUSB_MAX_MANUFACTURER];
static int8_t serial[PVCUSB_MAX_SERIAL];
static int8_t longname[PVCUSB_MAX_MODEL];

static int8_t inq_vendor[PVCUSB_INQ_VENDOR];
static int8_t inq_product[PVCUSB_INQ_PRODUCT];
static int8_t inq_revision[PVCUSB_INQ_REVISION];

static int8_t usbchargereq = 0;
static int8_t usblun = CONFIG_PVCUSB_LUN;

/* String Descriptor				*/
/* Static strings, in UTF-8			*/
static struct usb_string strings[] = {
	{STRING_MANUFACTURER,	manufacturer	},
	{STRING_PRODUCT,		longname		},
	{STRING_SERIAL,			serial			},
	{STRING_INTERFACE,		"Mass Storage"	},
	{STRING_CONFIG_SELF_P,	"Self-Powered"	},
	{STRING_CONFIG_BUS_P,	"Bus-Powered"	},
	{ }
};

/* Sets language and string descriptor to use	*/
static struct usb_gadget_strings stringtab = {
	.language = 0x0409, 	/* en-us			*/
	.strings  = strings,
};

/* Function Prototypes */
static void ep_set_state(struct pvc_ms_req *ms_req, uint16_t whichReturn, uint16_t connectStatus, uint32_t returnStatus, uint32_t transferedLength);
static int32_t config_buf(enum usb_device_speed speed, uint8_t * buf, uint8_t type, uint32_t index);
//extern inline int32_t ms_send_data(void *buf, int32_t buflen, struct usb_ep *ep, struct PVCUSB_cbw cbw, ms_state state, void *extra);
static struct usb_request *alloc_ep_req(struct usb_ep *ep, uint32_t length, void *buf_adr);
static void ms_setup_complete(struct usb_ep *ep, struct usb_request *req);
static int32_t enable_ms_eps(struct ms_dev *dev, int32_t gfp_flags);
static void disable_ms_eps(struct ms_dev *dev);
static int32_t ms_set_config(struct ms_dev *dev, uint32_t number, int32_t gfp_flags);
static void ms_ep_complete(struct usb_ep *ep, struct usb_request *req);
//extern struct usb_request *ms_in_ep_start(struct usb_ep *ep, int32_t gfp_flags);
struct usb_request *ms_out_ep_start(struct usb_ep *ep, int32_t gfp_flags);
static void free_ep_req(struct usb_ep *ep, struct usb_request *req);

static uint8_t CurrentState;
static uint8_t PreviousState;
static uint32_t CurrentSerialNumber = 0;

static PVCUSB_GET_DATA_STRUCT StoreGetData;
static PVCUSB_SET_DATA_STRUCT StoreSetData;
static PVCUSB_COMMAND_STATUS_STRUCT StoreCommandStatus;
static DECLARE_WAIT_QUEUE_HEAD (WaitQueue);

static struct ms_dev *StoreDev;

/* used list_entry	*/
static struct list_head todo_list;

static uint16_t UsbChangeStatus = 0;
static uint16_t StatusQueueError = 0;

static void *ReceiveCbwBuf;
static void *SendCswBuf;
static int32_t g_ms_major = MS_MAJOR;

inline void clear_queue_info(void)
{
	/* clear all queue	*/
	while(!list_empty(todo_list.next)) {
		struct pvc_ms_req *req = NULL;

		req = list_entry(todo_list.next, struct pvc_ms_req, list_ms_dev);
		list_del_init(&req->list_ms_dev);
		kfree(req);
	}
}

/*
 * Copies configuration descriptor to buf.
 * Device has 1 configuration, 1 interace, and 2 endpoints
 */
int32_t config_buf(enum usb_device_speed speed, uint8_t *buf, uint8_t type, uint32_t index)
{
	const struct usb_descriptor_header  **function;

	int32_t len;

	if (index > 0)
		return -EINVAL;

	switch (speed) {
		case USB_SPEED_SUPER_PLUS:
		case USB_SPEED_SUPER:
			function = ss_function;
			break;
		case USB_SPEED_HIGH:
			function = hs_function;
			break;
		default:
			function = fs_function;
			break;
	}

    len = usb_gadget_config_buf(&config_desc, buf, EP0_BUFSIZE, function);
    ((struct usb_config_descriptor *) buf)->bDescriptorType = type;	
	if(0x01 == usbchargereq){
		((struct usb_config_descriptor *) buf)->iConfiguration = STRING_CONFIG_BUS_P;

		switch(speed){
			case USB_SPEED_SUPER_PLUS:
			case USB_SPEED_SUPER:
				((struct usb_config_descriptor *) buf)->bmAttributes = USB_CONFIG_ATT_ONE;
				((struct usb_config_descriptor *) buf)->bMaxPower = USB_POWER_SS;
				break;
			default:
				((struct usb_config_descriptor *) buf)->bmAttributes = USB_CONFIG_ATT_ONE;
				((struct usb_config_descriptor *) buf)->bMaxPower = USB_POWER_HS;
				break;
		}
	}

	return len;
}

/* Creates a request object and I/O buffer for ep */
struct usb_request *alloc_ep_req(struct usb_ep *ep, uint32_t length, void *buf_adr)
{
	struct usb_request *req;    /* Request to return */

	/* Allocate a request object to use with this endpoint */
	req = usb_ep_alloc_request(ep, GFP_ATOMIC);
	if(!req) {
		PVCERROR("Could not allocate request!\n");
		return 0;
	}
	req->length = length;

	if (buf_adr) {
		req->buf = buf_adr;
	}else {
		PVCERROR("Invalid buffer pointer\n");
		usb_ep_free_request(ep, req);
		return 0;
	}

	/* Set default parameters for bulk-only transport */
	req->zero = 0;
	req->short_not_ok = 0;
	req->no_interrupt = 0;
    
	/*  
	 * This is what we usually want.  It will be different for
	 * disk accesses, since they need to perform additional processing.
	 */
	req->complete = ms_ep_complete;

	/* Request and buffer created - return */
	return req;
}

/*
 * Finish responding to setup packet
 * Called when setup request completes
 */
void ms_setup_complete(struct usb_ep *ep, struct usb_request *req)
{
	/*
	 * Everything was already handled.  Show status on
	 * error or if actual bytes transferred != requested bytes  
	 */
	if (req->status || req->actual != req->length)
		PVCDEBUG("setup complete --> %d, %d/%d\n", req->status, req->actual, req->length);

}

/**
 * next_ep_desc() - advance to the next EP descriptor
 * @t: currect pointer within descriptor array
 *
 * Return: next EP descriptor or NULL
 *
 * Iterate over @t until either EP descriptor found or
 * NULL (that indicates end of list) encountered
 */
static struct usb_descriptor_header**
next_ep_desc(struct usb_descriptor_header **t)
{
	for (; *t; t++) {
		if ((*t)->bDescriptorType == USB_DT_ENDPOINT)
			return t;
	}
	return NULL;
}

/*
 * for_each_ep_desc()- iterate over endpoint descriptors in the
 *		descriptors list
 * @start:	pointer within descriptor array.
 * @ep_desc:	endpoint descriptor to use as the loop cursor
 */
#define for_each_ep_desc(start, ep_desc) \
	for (ep_desc = next_ep_desc(start); \
	      ep_desc; ep_desc = next_ep_desc(ep_desc+1))

/**
 * config_ep_by_speed() - configures the given endpoint
 * according to gadget speed.
 * @g: pointer to the gadget
 * @f: usb function
 * @_ep: the endpoint to configure
 *
 * Return: error code, 0 on success
 *
 * This function chooses the right descriptors for a given
 * endpoint according to gadget speed and saves it in the
 * endpoint desc field. If the endpoint already has a descriptor
 * assigned to it - overwrites it with currently corresponding
 * descriptor. The endpoint maxpacket field is updated according
 * to the chosen descriptor.
 * Note: the supplied function should hold all the descriptors
 * for supported speeds
 */
static int32_t config_ep_by_speed(struct usb_gadget *g, struct usb_ep *_ep)
{
	struct usb_endpoint_descriptor *chosen_desc = NULL;
	struct usb_descriptor_header **speed_desc = NULL;

	struct usb_ss_ep_comp_descriptor *comp_desc = NULL;
	int32_t want_comp_desc = 0;

	struct usb_descriptor_header **d_spd; /* cursor for speed desc */

	if (!g || !_ep)
		return -EIO;

	/* select desired speed */
	switch (g->speed) {
	case USB_SPEED_SUPER_PLUS:
		if (gadget_is_superspeed_plus(g)) {
			speed_desc = (struct usb_descriptor_header**)ss_function;
			want_comp_desc = 1;
			break;
		}
		/* else: Fall trough */
	case USB_SPEED_SUPER:
		if (gadget_is_superspeed(g)) {
			speed_desc = (struct usb_descriptor_header**)ss_function;
			want_comp_desc = 1;
			break;
		}
		/* else: Fall trough */
	case USB_SPEED_HIGH:
		if (gadget_is_dualspeed(g)) {
			speed_desc = (struct usb_descriptor_header**)hs_function;
			break;
		}
		/* else: fall through */
	default:
		speed_desc = (struct usb_descriptor_header**)fs_function;
		break;
	}
	/* find descriptors */
	for_each_ep_desc(speed_desc, d_spd) {
		chosen_desc = (struct usb_endpoint_descriptor *)*d_spd;
		if (chosen_desc->bEndpointAddress == _ep->address)
			goto ep_found;
	}

	return -EIO;

ep_found:
	/* commit results */
	_ep->maxpacket = usb_endpoint_maxp(chosen_desc);
	_ep->desc = chosen_desc;
	_ep->comp_desc = NULL;
	_ep->maxburst = 0;
	_ep->mult = 0;
	if (!want_comp_desc)
		return 0;

	/*
	 * Companion descriptor should follow EP descriptor
	 * USB 3.0 spec, #9.6.7
	 */
	comp_desc = (struct usb_ss_ep_comp_descriptor *)*(++d_spd);
	if (!comp_desc ||
	    (comp_desc->bDescriptorType != USB_DT_SS_ENDPOINT_COMP))
		return -EIO;

	_ep->comp_desc = comp_desc;
	if (g->speed >= USB_SPEED_SUPER) {
		switch (usb_endpoint_type(_ep->desc)) {
		case USB_ENDPOINT_XFER_ISOC:
			/* mult: bits 1:0 of bmAttributes */
			_ep->mult = comp_desc->bmAttributes & 0x3;
		case USB_ENDPOINT_XFER_BULK:
		case USB_ENDPOINT_XFER_INT:
			_ep->maxburst = comp_desc->bMaxBurst + 1;
			break;
		default:
			if (comp_desc->bMaxBurst != 0)
				PVCERROR("ep0 bMaxBurst must be 0\n");
			_ep->maxburst = 1;
			break;
		}
	}
	return 0;
}

/*
 * Finish setting the configuration to mass storage
 * Enable endpoints to start processing commands
 */
int32_t enable_ms_eps(struct ms_dev *dev, int32_t gfp_flags)
{
	int32_t result = 0;
	struct usb_ep *ep;
	struct usb_gadget *gadget = dev->gadget;

//	StoreDev = dev;

	gadget_for_each_ep(ep, gadget) {
		/* Loop thru all device endpoints */
		const struct usb_endpoint_descriptor *d;
		PVCDEBUG("Configuring %s\n", ep->name);

		if (strcmp(ep->name, EP_IN_NAME) == 0) {
			/* IN Endpoint */
//			d = ep_desc(gadget, &hs_bulk_in_desc, &fs_bulk_in_desc);
			switch (gadget->speed) {
				case USB_SPEED_SUPER_PLUS:
				case USB_SPEED_SUPER:
					d = &ss_bulk_in_desc;
					break;
				case USB_SPEED_HIGH:
					d = &hs_bulk_in_desc;
					break;
				default:
					d = &fs_bulk_in_desc;
					break;
			}
			ep->desc = d;
			ep->driver_data = dev;
			dev->in_ep = ep;

			/* Enable IN Endpoint */
			PVCDEBUG("ENABLING IN ENDPOINT\n");

			config_ep_by_speed(gadget, ep);
			result = usb_ep_enable(ep);
			if (result == 0) {
				PVCDEBUG("%s enabled!\n", ep->name);
				continue;
			}
		}else
		if (strcmp(ep->name, EP_OUT_NAME) == 0) {
			/* OUT Endpoint */
//			d = ep_desc(gadget, &hs_bulk_out_desc, &fs_bulk_out_desc);
			switch (gadget->speed) {
				case USB_SPEED_SUPER_PLUS:
				case USB_SPEED_SUPER:
					d = &ss_bulk_out_desc;
					break;
				case USB_SPEED_HIGH:
					d = &hs_bulk_out_desc;
					break;
				default:
					d = &fs_bulk_out_desc;
					break;
			}

			ep->desc = d;
			ep->driver_data = dev;
			dev->out_ep = ep;

			/* Enable OUT Endpoint */
			PVCDEBUG("ENABLING OUT ENDPOINT\n");

			config_ep_by_speed(gadget,  ep);
			result = usb_ep_enable(ep);
			PVCDEBUG("%s enabled!\n", ep->name);
			if (result == 0) {
                /* Start waiting for commands */
				if (ms_out_ep_start(ep, gfp_flags)) {
					PVCDEBUG("%s endpoint enabled\n", ep->name);
					continue;
				}else {
					PVCERROR("ms_out_ep_start() failed\n");
					result = -EFAULT;
					break;
				}
			}
		}else {      /* Some other endpoint, don't need it */
			continue;
		}
		PVCDEBUG("Couldn't enabling %s, result %d\n", ep->name, result);
		break;
	}

	/* Endpoints enabled */
	return result;
}

/*
 * Reset configuration.  Disable all endpoints.
 */
void disable_ms_eps(struct ms_dev *dev)
{
	if (dev->config == 0)
		return;
	
	if (dev->in_ep) {
		/* IN was configured - disable it */
		usb_ep_disable(dev->in_ep);
		dev->in_ep = 0;
	}
	if (dev->out_ep) {
		/* OUT was configured - disable it */
		usb_ep_disable(dev->out_ep);
		dev->out_ep = 0;
	}
	/* Device now unconfigured */
	dev->config = 0;

	CurrentState = INIT;
}

/*
 * Enable configuration "number"
 * This function resets the current configuration and calls enable_ms_eps
 * to switch to the Mass Storage configuration.
 *
 * We only use configuration 1.
 */
int32_t ms_set_config(struct ms_dev *dev, uint32_t number, int32_t gfp_flags)
{
	int32_t result = 0;
	struct usb_gadget *gadget = dev->gadget;
	struct pvc_ms_req *ms_req = NULL;

	if (CurrentState == POW_ON) {
		PVCERROR("Could not run ms_set_config in POW_ON\n");
		return -EFAULT;
	}
	if (number == dev->config)
		/* We're already set to that configuration - do nothing. */
		return 0;

	switch (number) {
	/* See what configuration is requested.  We only accept #1 */
	case 1:
    	PVCERROR("in ms_set_config: number=1\n");
		if (CurrentState == INIT) {
			/* Reset configuration just in case */
			disable_ms_eps(dev);

			/* Main configuration number */
			result = enable_ms_eps(dev, gfp_flags);
			if (result == 0) {
				/* clear all queue	*/
				clear_queue_info();
				PVCDEBUG("DACT set:ms_set_config(1)\n");
				UsbChangeStatus = PVCUSB_DACT_BIT;
				StatusQueueError = 0;
				CurrentState = CBW_READY;
			}else {
				PVCERROR("Set config failed(%d)\n", result);
			}
		}
		break;

	default:
		/* Reset configuration just in case */
		disable_ms_eps(dev);

		/* Bad number */
		PVCERROR("in ms_set_config() : default state\n");
		result = -EINVAL;

	case 0:
    	PVCERROR("in ms_set_config() : number=0\n");
		if (CurrentState != INIT) {
			/* Reset configuration just in case */
			disable_ms_eps(dev);

			/* clear all queue	*/
			clear_queue_info();
			ms_req = kzalloc(sizeof *ms_req, GFP_KERNEL);
			if( ms_req ){
				memset(ms_req, 0, sizeof *ms_req);
				list_add_tail(&ms_req->list_ms_dev, &todo_list);
				PVCERROR("list_add_tail(MassStorageReset)\n");
			}else {
				PVCERROR("Couldn't allocate StatusQueue(MassStorageReset)\n");
				result = -ENOMEM;
			}
			UsbChangeStatus = PVCUSB_DACT_BIT;
			CurrentSerialNumber++;
			CurrentState = INIT;
		}
		wake_up_interruptible(&WaitQueue);
		PVCERROR("exit ms_set_config 0(%d)\n", CurrentState);
		return result;
	}

	if (!result && (!dev->in_ep || !dev->out_ep)){
	/*
	 * Either enable_ms_eps failed or   
	 * it didn't create the endpoints
	 */
		PVCERROR("Couldn't not create the endpoints\n");
		result = -ENODEV;
	}

	if (result) {
		/* Setting configuration failed, make sure it's reset */
		PVCERROR("Setting configuration failed, make sure it's reset\n");
		disable_ms_eps(dev);
	} else {
		/* Configuration has been set.  Show status. */
		int8_t *speed;
		switch (gadget->speed) {
			case USB_SPEED_LOW:
				speed = "low-speed";
				break;
			case USB_SPEED_FULL:
				speed = "full-speed";
				break;
			case USB_SPEED_HIGH:
				speed = "high-speed";
				break;
			case USB_SPEED_SUPER:
				speed = "super-speed";
				break;
			case USB_SPEED_SUPER_PLUS:
				speed = "super-speed-plus";
				break;
			default:
				speed = "?";
				break;
		}

		dev->config = number;
		PVCERROR("%s config #%d\n", speed, number);
	}
	PVCERROR("Exit ms_set_config 1(%d)  return = %d\n", CurrentState, result);
	return result;
}

/**
 * bos_desc() - prepares the BOS descriptor.
 * @cdev: pointer to usb_composite device to generate the bos
 *	descriptor for
 *
 * This function generates the BOS (Binary Device Object)
 * descriptor and its device capabilities descriptors. The BOS
 * descriptor should be supported by a SuperSpeed device.
 */
static int32_t bos_desc(struct ms_dev *cdev)
{
	struct usb_ext_cap_descriptor	*usb_ext;
	struct usb_dcd_config_params	dcd_config_params;
	struct usb_bos_descriptor	*bos = cdev->req->buf;

	bos->bLength = USB_DT_BOS_SIZE;
	bos->bDescriptorType = USB_DT_BOS;

	bos->wTotalLength = cpu_to_le16(USB_DT_BOS_SIZE);
	bos->bNumDeviceCaps = 0;

	/*
	 * A SuperSpeed device shall include the USB2.0 extension descriptor
	 * and shall support LPM when operating in USB2.0 HS mode.
	 */
	usb_ext = cdev->req->buf + le16_to_cpu(bos->wTotalLength);
	bos->bNumDeviceCaps++;
	le16_add_cpu(&bos->wTotalLength, USB_DT_USB_EXT_CAP_SIZE);
	usb_ext->bLength = USB_DT_USB_EXT_CAP_SIZE;
	usb_ext->bDescriptorType = USB_DT_DEVICE_CAPABILITY;
	usb_ext->bDevCapabilityType = USB_CAP_TYPE_EXT;
	usb_ext->bmAttributes = cpu_to_le32(USB_LPM_SUPPORT | USB_BESL_SUPPORT);

	/*
	 * The Superspeed USB Capability descriptor shall be implemented by all
	 * SuperSpeed devices.
	 */
	if (gadget_is_superspeed(cdev->gadget)) {
		struct usb_ss_cap_descriptor *ss_cap;

		ss_cap = cdev->req->buf + le16_to_cpu(bos->wTotalLength);
		bos->bNumDeviceCaps++;
		le16_add_cpu(&bos->wTotalLength, USB_DT_USB_SS_CAP_SIZE);
		ss_cap->bLength = USB_DT_USB_SS_CAP_SIZE;
		ss_cap->bDescriptorType = USB_DT_DEVICE_CAPABILITY;
		ss_cap->bDevCapabilityType = USB_SS_CAP_TYPE;
		ss_cap->bmAttributes = 0; /* LTM is not supported yet */
		ss_cap->wSpeedSupported = cpu_to_le16(USB_LOW_SPEED_OPERATION |
						      USB_FULL_SPEED_OPERATION |
						      USB_HIGH_SPEED_OPERATION |
						      USB_5GBPS_OPERATION);
		ss_cap->bFunctionalitySupport = USB_LOW_SPEED_OPERATION;

		/* Get Controller configuration */
		if (cdev->gadget->ops->get_config_params) {
			cdev->gadget->ops->get_config_params(
				&dcd_config_params);
		} else {
			dcd_config_params.bU1devExitLat =
				USB_DEFAULT_U1_DEV_EXIT_LAT;
			dcd_config_params.bU2DevExitLat =
				cpu_to_le16(USB_DEFAULT_U2_DEV_EXIT_LAT);
		}
		ss_cap->bU1devExitLat = dcd_config_params.bU1devExitLat;
		ss_cap->bU2DevExitLat = dcd_config_params.bU2DevExitLat;
	}

	/* The SuperSpeedPlus USB Device Capability descriptor */
	if (gadget_is_superspeed_plus(cdev->gadget)) {
		struct usb_ssp_cap_descriptor *ssp_cap;

		ssp_cap = cdev->req->buf + le16_to_cpu(bos->wTotalLength);
		bos->bNumDeviceCaps++;

		/*
		 * Report typical values.
		 */

		le16_add_cpu(&bos->wTotalLength, USB_DT_USB_SSP_CAP_SIZE(1));
		ssp_cap->bLength = USB_DT_USB_SSP_CAP_SIZE(1);
		ssp_cap->bDescriptorType = USB_DT_DEVICE_CAPABILITY;
		ssp_cap->bDevCapabilityType = USB_SSP_CAP_TYPE;
		ssp_cap->bReserved = 0;
		ssp_cap->wReserved = 0;

		/* SSAC = 1 (2 attributes) */
		ssp_cap->bmAttributes = cpu_to_le32(1);

		/* Min RX/TX Lane Count = 1 */
		ssp_cap->wFunctionalitySupport =
			cpu_to_le16((1 << 8) | (1 << 12));

		/*
		 * bmSublinkSpeedAttr[0]:
		 *   ST  = Symmetric, RX
		 *   LSE =  3 (Gbps)
		 *   LP  =  1 (SuperSpeedPlus)
		 *   LSM = 10 (10 Gbps)
		 */
		ssp_cap->bmSublinkSpeedAttr[0] =
			cpu_to_le32((3 << 4) | (1 << 14) | (0xa << 16));
		/*
		 * bmSublinkSpeedAttr[1] =
		 *   ST  = Symmetric, TX
		 *   LSE =  3 (Gbps)
		 *   LP  =  1 (SuperSpeedPlus)
		 *   LSM = 10 (10 Gbps)
		 */
		ssp_cap->bmSublinkSpeedAttr[1] =
			cpu_to_le32((3 << 4) | (1 << 14) |
				    (0xa << 16) | (1 << 7));
	}

	return le16_to_cpu(bos->wTotalLength);
}

static int32_t
standard_setup_req(struct usb_gadget *gadget, struct usb_request *req, const struct usb_ctrlrequest *ctrl)
{
	struct ms_dev *dev = get_gadget_data(gadget);
	int32_t value = -EOPNOTSUPP;

	enum usb_device_speed	speed = USB_SPEED_UNKNOWN;
	
	/* [SBG-SAV] --> [ENDIAN]   */
	uint16_t wValue  = le16_to_cpu(ctrl->wValue);
	uint16_t wIndex  = le16_to_cpu(ctrl->wIndex);
	uint16_t wLength = le16_to_cpu(ctrl->wLength);

//	uint64_t flags;
	unsigned long flags;

	uint8_t  type = (wValue & 0xff00) >> 8;
	uint8_t  id   =  wValue & 0x00ff;

	/* Ep0 standard request handlers.  These always run in_irq. */
	switch (ctrl->bRequest) {
	case USB_REQ_GET_DESCRIPTOR:
		/*
		 * GET DESCRIPTOR request
		 * Check descriptor type and copy it to req->buf.
		*/
		if (ctrl->bRequestType != USB_DIR_IN)
			break;

		switch (type) {
		/* What kind of descriptor? */
		case USB_DT_DEVICE:
			PVCERROR("USB_DT_DEVICE gadget->speed %d\n", gadget->speed);
			if (gadget_is_superspeed(gadget)) {
				if (gadget->speed >= USB_SPEED_SUPER) {
					device_desc.bcdUSB = cpu_to_le16(0x0310);
					device_desc.bMaxPacketSize0 = 9;	/* 2^9 = 512 Bytes */
				} else {
					device_desc.bcdUSB = cpu_to_le16(0x0200);
					device_desc.bMaxPacketSize0 = EP0_MAXPACKET;
				}
			}

			value = min(wLength, (uint16_t) sizeof device_desc);
			memcpy(req->buf, &device_desc, value);

#if 0
		printk("idVendor %02x \n", *ptr++);
		printk("idVendor %02x \n", *ptr++);
		printk("idProduct %02x \n", *ptr++);
		printk("idProduct %02x \n", *ptr++);
		printk("bcdDevice %02x \n", *ptr++);
		printk("bcdDevice %02x \n", *ptr++);
		printk("iManufacturer %02x \n", *ptr++);
		printk("iProduct %02x \n", *ptr++);
		printk("iSerialNumber %02x \n", *ptr++);
		printk("bNumConfigurations %02x \n", *ptr++);
#endif
			break;

		case USB_DT_DEVICE_QUALIFIER:
			PVCERROR("USB_DT_DEVICE_QUALIFIER\n");
			if (!gadget_is_dualspeed(gadget) ||
			    gadget->speed >= USB_SPEED_SUPER)
				break;

			value = min(wLength, (uint16_t) sizeof dev_qualifier);
			memcpy(req->buf, &dev_qualifier, value);
			break;

		case USB_DT_OTHER_SPEED_CONFIG:
			PVCERROR("USB_DT_OTHER_SPEED_CONFIG\n");
			if (!gadget_is_dualspeed(gadget) ||
			    gadget->speed >= USB_SPEED_SUPER)
				break;
			/* FALLTHROUGH */
		case USB_DT_CONFIG:
			/*
			 * These both do the same thing 
			 * because config_buf will figure out
			 * which config to copy.
			 */
			PVCDEBUG("USB_REQ_GET_DESCRIPTOR \tUSB_DT_CONFIG/OTHER_SPEED_CONFIG\n");
//			value = config_buf(gadget->speed, req->buf, type, id);

			// Support SuperSpeed
			if (gadget->speed == USB_SPEED_SUPER_PLUS) { 
				PVCERROR("USB_DT_CONFIG : Super Speed Plus\n");
				speed = gadget->speed;
			}
			else if (gadget->speed == USB_SPEED_SUPER) { 
				PVCERROR("USB_DT_CONFIG : Super Speed\n");
				speed = gadget->speed;
			}
			else if (gadget_is_dualspeed(gadget)) {
				int32_t	hs = 0;
				if (gadget->speed == USB_SPEED_HIGH)
					hs = 1;
				if (type == USB_DT_OTHER_SPEED_CONFIG)
					hs = !hs;
				if (hs) {
					PVCERROR("USB_DT_CONFIG : High Speed\n");
					speed = USB_SPEED_HIGH;
				}
			}

			value = config_buf(speed, req->buf, type, id);
			if (value >= 0){
				value = min(wLength, (uint16_t)value);
			}


//		ptr = req->buf;
//		int32_t i;
//		for (i=0; i<=value; i++)
//			printk("%02x \n", *ptr++);

			break;

		case USB_DT_STRING:
			PVCDEBUG("USB_REQ_GET_DESCRIPTOR \tUSB_DT_STRING %d\n", id);
			value = usb_gadget_get_string(&stringtab, id, req->buf);
			if (value >= 0){
				value = min(wLength, (uint16_t)value);
			}
			break;

		case USB_DT_BOS:
			PVCERROR("USB_DT_BOS\n");
			if (gadget_is_superspeed(gadget)) {
				value = bos_desc(dev);
				value = min(wLength, (uint16_t) value);
			}
			break;

		default:
			PVCERROR("ms_setup : What kind of descriptor? : Unknown descriptor = %02x\n", type);

		}
		PVCDEBUG("ms_setup : USB_REQ_GET_DESCRIPTOR : End : descriptor = %02x\n", type);
		break;

	case USB_REQ_SET_CONFIGURATION:
		/* SET CONFIGURATION request */
		PVCERROR("USB_REQ_SET_CONFIGURATION : %d\n", wValue);
		if (ctrl->bRequestType != 0)
			break;

		if (wValue)
			spin_lock_irqsave(&dev->lock, flags);
		value = ms_set_config(dev, wValue, GFP_ATOMIC);
		if (wValue)
			spin_unlock_irqrestore(&dev->lock, flags);

		PVCDEBUG("USB_REQ_SET_CONFIGURATION : BREAK : %d\n", value);
		break;

	case USB_REQ_GET_CONFIGURATION:
		/* GET CONFIGURATION request */
		PVCERROR("USB_REQ_GET_CONFIGURATION\n");
		if (ctrl->bRequestType != USB_DIR_IN)
			break;

		*(uint8_t *) req->buf = dev->config;
		value = min(wLength, (uint16_t) 1);
		break;

	case USB_REQ_SET_INTERFACE:
		/* SET INTERFACE request */
		PVCERROR("USB_REQ_SET_INTERFACE\n");
		if (ctrl->bRequestType != USB_RECIP_INTERFACE)
			break;

//		spin_lock_irqsave(&dev->lock, flags);
		if (dev->config && wIndex == 0 && wValue == 0) {
			/* Command is valid */
			uint8_t config = dev->config;
			PVCDEBUG("USB_REQ_SET_INTERFACE \n");

			disable_ms_eps(dev);

			spin_lock_irqsave(&dev->lock, flags);
			ms_set_config(dev, config, GFP_ATOMIC);
			value = 0;
			spin_unlock_irqrestore(&dev->lock, flags);
		}
//		spin_unlock_irqrestore(&dev->lock, flags);
		break;

	case USB_REQ_GET_INTERFACE:
		/* GET INTERFACE command */
		PVCERROR("USB_REQ_GET_INTERFACE\n");
		if (ctrl->bRequestType != (USB_DIR_IN | USB_RECIP_INTERFACE)) {
			break;
		}
		if (!dev->config) {
			break;
		}
		if (wIndex != 0) {
			value = -EDOM;
			break;
		}
		/* Only one interface, so it must be 0 */
		*(uint8_t *) req->buf = 0;
		value = min(wLength, (uint16_t) 1);
		break;

	case USB_REQ_SET_FEATURE:
	case USB_REQ_CLEAR_FEATURE:
		/* SET_FEATURE/CLEAR_FEATURE command	*/
		PVCERROR("USB_REQ_USB_REQ_SET_FEATURE/USB_REQ_CLEAR_FEATURE\n");
		value = 0;
		break;
	}

	if (value == -EOPNOTSUPP)
		PVCERROR("Unknown standard setup request %02x.%02x v%04x i%04x l%u\n",
			ctrl->bRequestType, ctrl->bRequest, wValue, wIndex, wLength);
	return value;
}

static int32_t
class_setup_req(struct usb_gadget *gadget, struct usb_request *req, const struct usb_ctrlrequest *ctrl)
{
	struct ms_dev *dev = get_gadget_data(gadget);
	struct pvc_ms_req *ms_req = NULL;
	int32_t	value = -EOPNOTSUPP;
	uint16_t	wLength = le16_to_cpu(ctrl->wLength);
   
//	uint64_t flags;
	unsigned long flags;

	/* Handle Bulk-only class-specific requests */
	switch (ctrl->bRequest) {
	case USB_BULK_GET_MAX_LUN_REQUEST:
		/* GET_MAX_LUN  */
		PVCERROR("GET_MAX_LUN %d\n", usblun - 1);
		*(uint8_t *) req->buf = usblun - 1;
		value = min(wLength, (uint16_t) 1);
		break;

	case USB_BULK_RESET_REQUEST:
		PVCERROR("BulkOnly MassStorageReset\n");
		/* BulkOnly MassStorageReset    */
       	if( (CurrentState == CBW_READY) ||
			(CurrentState == CBW_DONE) ||
			(CurrentState == CMD_READY) ||
			(CurrentState == CMD_DONE) ||
			(CurrentState == SET_READY_DATA) ||
			(CurrentState == SET_READY_CSW) ||
			(CurrentState == SET_DONE) ||
			(CurrentState == WAIT_NEXT) ) {
			PVCDEBUG("BulkOnly MassStorageReset (%d)\n", CurrentState);

			spin_lock_irqsave(&dev->lock, flags);
			
			/* clear all queue  */
			clear_queue_info();
			PVCDEBUG("DACT set : BulkOnly MassStorageReset\n");
			UsbChangeStatus = PVCUSB_DACT_BIT;

			ms_req = kzalloc(sizeof *ms_req, GFP_KERNEL);
			if( ms_req ){
				memset(ms_req, 0, sizeof *ms_req);
				ep_set_state(ms_req, PVCUSB_MRT_BIT, 0, 0, 0);
				list_add_tail(&ms_req->list_ms_dev, &todo_list);
				PVCERROR("list_add_tail(MassStorageReset)\n");

				/* ready to get CBW data    */
				CurrentState = CBW_READY;
				ms_out_ep_start(dev->out_ep, GFP_ATOMIC);
				value = 0;
			}else {
				PVCERROR("Couldn't allocate StatusQueue(MassStorageReset)\n");
				StatusQueueError = PVCUSB_MRT_BIT | PVCUSB_ERR_BIT;
				value = -EFAULT;
			}

			spin_unlock_irqrestore(&dev->lock, flags);
			wake_up_interruptible(&WaitQueue);

		}else {
			PVCERROR("BulkOnly MassStorageReset (%d), Wrong statement\n", CurrentState);

			ms_req = kzalloc(sizeof *ms_req, GFP_KERNEL);
			if( ms_req ){
				memset(ms_req, 0, sizeof *ms_req);
				ep_set_state(ms_req, (PVCUSB_MRT_BIT | PVCUSB_ERR_BIT), 0, INVALID_STATE_ERROR, 0);
				list_add_tail(&ms_req->list_ms_dev, &todo_list);
				PVCDEBUG("list_add_tail(MassStorageReset)\n");
				PVCERROR("list_add_tail(MassStorageReset)\n");
			}else {
				PVCERROR("Couldn't allocate StatusQueue(MassStorageReset)\n");
				StatusQueueError = PVCUSB_MRT_BIT | PVCUSB_ERR_BIT;
			}
		}
		break;
	}

	if (value == -EOPNOTSUPP)
		PVCERROR("Unknown class-specific setup request %02x.%02x v%04x i%04x l%u\n",
				ctrl->bRequestType, ctrl->bRequest,
				le16_to_cpu(ctrl->wValue), le16_to_cpu(ctrl->wIndex), wLength);
	return value;
}

/*
 * Main setup packet handler.
 * This function is called for every control packet received.  It
 * checks the request type and performs the necessary operations.
 *
 */
static int32_t ms_setup(struct usb_gadget *gadget, const struct usb_ctrlrequest *ctrl)
{
	struct ms_dev *dev = get_gadget_data(gadget);
	struct usb_request *req = dev->req;
	int32_t value = -EOPNOTSUPP;

	if ((ctrl->bRequestType & USB_TYPE_MASK) == USB_TYPE_CLASS){
		value = class_setup_req(gadget, req, ctrl);
	}else {
		value = standard_setup_req(gadget, req, ctrl);
	}

	PVCDEBUG("ms_setup : done [%d]\n", value);
	if (value >= 0) {
		/* We're sending data */
		req->length = value;
		/* Queue up response */

		value = usb_ep_queue(gadget->ep0, req, GFP_ATOMIC);
		if (value < 0) {
			/* usb_ep_queue failed */
			PVCERROR("ep_queue --> %d\n", value);
			req->status = 0;
			ms_setup_complete(gadget->ep0, req);
		}
	}
	return value;
}

/*
 * Free an endpoint request
 */
void free_ep_req(struct usb_ep *ep, struct usb_request *req)
{
	struct transfer_context  *context = (struct transfer_context *)req->context;

	if (!req) {
		PVCERROR("free_ep_req with no reqest : error\n");
		return;
	}
	if (!ep) {
		PVCERROR("free_ep_req with no endpoint available : error\n");
		return;
	}
	/* Free context */
	if (context) {
		kfree(req->context);
	}
	/* Free request */
	/* Fix bug: Modified 2009/09/29 */
	if( ep && req )
		usb_ep_free_request(ep, req);
}

void ep_normal_completion(struct usb_ep *ep, struct usb_request *req)
{
    struct ms_dev *dev = ep->driver_data;
    int32_t status = req->status;
	struct transfer_context *_context;
    struct usb_request *_req;
    int32_t retStatus;
    struct pvc_ms_req *ms_req = NULL;
    static uint32_t cmdTransferLength = 0;
    static uint32_t setTransferLength = 0;
	uint32_t t_val;

	switch (CurrentState) {
	case CBW_READY:
		PVCDEBUG("CBW_READY\n");
		CurrentState = CBW_DONE;
		CurrentSerialNumber++;

		ms_req = kzalloc(sizeof *ms_req, GFP_KERNEL);
		if( ms_req ){
			memset(ms_req, 0, sizeof *ms_req);
			ep_set_state(ms_req, PVCUSB_CBW_BIT, 0, 0, req->actual);
			list_add_tail(&ms_req->list_ms_dev, &todo_list);
			PVCDEBUG("Endpoint request completed (CBW_READY)\n");

			if(req->actual == CBW_SIZE)
			{
				memcpy(&StoreGetData.CbwData, (struct cbw *)req->buf, req->actual);

				/* Swapping endian	*/
				t_val = le32_to_cpu(StoreGetData.CbwData.signature);
				StoreGetData.CbwData.signature = t_val;
				t_val = le32_to_cpu(StoreGetData.CbwData.data_transfer_length);
				StoreGetData.CbwData.data_transfer_length = t_val;
			}else {
				memset(&StoreGetData.CbwData, 0, sizeof(StoreGetData.CbwData));

				PVCERROR("Incorrect CBW actual length %d (ms_ep_complete:CBW_READY)\n", req->actual);
			}
		}else {
			PVCERROR("Couldn't not allocate StatusQueue(ms_ep_complete:CBW_READY)\n");
			StatusQueueError = PVCUSB_CBW_BIT | PVCUSB_ERR_BIT;
		}
		wake_up_interruptible(&WaitQueue);
		break;

	case CMD_READY:
		PVCDEBUG("CMD_READY\n");
		cmdTransferLength = req->actual;
		CurrentState = CMD_DONE;

		ms_req = kzalloc(sizeof *ms_req, GFP_KERNEL);
		if( ms_req ){
			memset(ms_req, 0, sizeof *ms_req);
			ep_set_state(ms_req, PVCUSB_CMD_BIT, 0, 0, cmdTransferLength);
			list_add_tail(&ms_req->list_ms_dev, &todo_list);
			PVCDEBUG("Endpoint request completed (CMD_READY)\n");
		}else {
			PVCERROR("Couldn't not allocate StatusQueue(ms_ep_complete:CMD_READY)\n");
			StatusQueueError = PVCUSB_CMD_BIT | PVCUSB_ERR_BIT;
		}
		wake_up_interruptible(&WaitQueue);
		break;

	case SET_READY_DATA:
		PVCDEBUG("SET_READY_DATA : data length :%d\n", req->actual);
		setTransferLength = req->actual;

		if ( StoreSetData.SetDataTransferInfo & PVCUSB_NO_CSW ) {
			CurrentState = SET_DONE;

			ms_req = kzalloc(sizeof *ms_req, GFP_KERNEL);
			if( ms_req ){
				memset(ms_req, 0, sizeof *ms_req);
				ep_set_state(ms_req, PVCUSB_NXT_BIT, 0, 0, setTransferLength);
				list_add_tail(&ms_req->list_ms_dev, &todo_list);
				PVCDEBUG("Endpoint request completed and wait next request (SET_READY_DATA)\n");
			}else {
				PVCERROR("Couldn't not allocate StatusQueue(ms_ep_complete:SET_READY_DATA)\n");
				StatusQueueError = PVCUSB_NXT_BIT | PVCUSB_ERR_BIT;
			}
			wake_up_interruptible(&WaitQueue);
			break;
		}

		if ( (StoreSetData.SetDataTransferInfo & PVCUSB_DO_TRANSFER) &&
						(StoreSetData.SetDataTransferInfo & PVCUSB_STALL) ) {
			PVCDEBUG("Set STALL after data transfer\n");
			usb_ep_set_halt(dev->in_ep);
		}

		t_val = cpu_to_le32(StoreSetData.CswData.signature);
		StoreSetData.CswData.signature = t_val;
		t_val = cpu_to_le32(StoreSetData.CswData.data_residue);
		StoreSetData.CswData.data_residue = t_val;
		memcpy(SendCswBuf, &StoreSetData.CswData, CSW_SIZE);
		_req = alloc_ep_req(dev->in_ep, CSW_SIZE, (void *)SendCswBuf);
		if (_req) {
			PVCDEBUG("SET_READY_DATA : Going to kmalloc context\n");
			_context = kmalloc(sizeof(struct transfer_context), GFP_ATOMIC);
			if(!_context) {
				ms_req = kzalloc(sizeof *ms_req, GFP_KERNEL);
				if( ms_req ){
					memset(ms_req, 0, sizeof *ms_req);
					ep_set_state(ms_req, (PVCUSB_SET_BIT | PVCUSB_ERR_BIT), 0,
										 ALLOC_CONTEXT_ERROR, setTransferLength);
					list_add_tail(&ms_req->list_ms_dev, &todo_list);
					PVCERROR("Couldn't allocate context (SET_READY_DATA)\n");
					usb_ep_free_request(dev->in_ep, _req);
				}else {
					PVCERROR("Couldn't allocate StatusQueue (SET_READY_DATA)\n");
					StatusQueueError = PVCUSB_SET_BIT | PVCUSB_ERR_BIT;
				}
				wake_up_interruptible(&WaitQueue);
			}else {
				_context->free_buffer = 1;
				_req->context = _context;
				PreviousState = CurrentState;
				CurrentState = SET_READY_CSW;

				retStatus = usb_ep_queue(dev->in_ep, _req, GFP_ATOMIC);
				if (retStatus == 0) {
					PVCDEBUG("start %s --> %d\n", dev->in_ep->name, status);
				} else {
					CurrentState = PreviousState;
					ms_req = kzalloc(sizeof *ms_req, GFP_KERNEL);
					if( ms_req ){
						memset(ms_req, 0, sizeof *ms_req);
						ep_set_state(ms_req, (PVCUSB_SET_BIT | PVCUSB_ERR_BIT), 0, 
                                         QUEUE_REQUEST_ERROR, setTransferLength);
						list_add_tail(&ms_req->list_ms_dev, &todo_list);
						PVCERROR("usb_ep_queue failed with status=%d (SET_READY_DATA)\n", status);
						usb_ep_free_request(dev->in_ep, _req);
					}else {
						PVCERROR("Couldn't not allocate StatusQueue (SET_READY_DATA)\n");
						StatusQueueError = PVCUSB_SET_BIT | PVCUSB_ERR_BIT;
					}
				}
			}
		}else {
			ms_req = kzalloc(sizeof *ms_req, GFP_KERNEL);
			if( ms_req ){
				memset(ms_req, 0, sizeof *ms_req);
				ep_set_state(ms_req, (PVCUSB_SET_BIT | PVCUSB_ERR_BIT), 0,
                                         ALLOC_REQUEST_ERROR, setTransferLength);
				list_add_tail(&ms_req->list_ms_dev, &todo_list);
				PVCDEBUG("Endpoint request completed (SET_READY_DATA))\n");
			}else {
				PVCERROR("Couldn't not allocate StatusQueue (SET_READY_DATA)\n");
				StatusQueueError = PVCUSB_SET_BIT | PVCUSB_ERR_BIT;
			}
			wake_up_interruptible(&WaitQueue);
		}
		break;

	case SET_READY_CSW:
		PVCDEBUG("SET_READY_CSW\n");
		/* calculate transfered data length("DATA + CSW" or "CSW")  */
		if (StoreSetData.SetDataTransferInfo & PVCUSB_DO_TRANSFER) {
			PVCDEBUG("data length:%d\n", setTransferLength);
			PVCDEBUG("csw length :%d\n", req->actual);
			setTransferLength += req->actual;
		}else {
			PVCDEBUG("csw length :%d\n", req->actual);
			setTransferLength = req->actual;
		}

		ms_req = kzalloc(sizeof *ms_req, GFP_KERNEL);
		if( ms_req ){
			memset(ms_req, 0, sizeof *ms_req);
			ep_set_state(ms_req, PVCUSB_SET_BIT, 0, 0, setTransferLength);
			list_add_tail(&ms_req->list_ms_dev, &todo_list);
			PVCDEBUG("Endpoint request completed (SET_READY_CSW)\n");

			PreviousState = CurrentState;
			CurrentState = CBW_READY;

			if (!ms_out_ep_start(dev->out_ep, GFP_ATOMIC)) {
				PVCERROR("ms_out_ep_start() : Failed\n");
				CurrentState = PreviousState;
				ms_req = kzalloc(sizeof *ms_req, GFP_KERNEL);
				if( ms_req ){
					memset(ms_req, 0, sizeof *ms_req);
					ep_set_state(ms_req, (PVCUSB_SET_BIT | PVCUSB_ERR_BIT), 0,
                                         CBW_REQUEST_ERROR, setTransferLength);
					list_add_tail(&ms_req->list_ms_dev, &todo_list);
					PVCDEBUG("Couldn't not start CBW request\n");
				}else {
					PVCERROR("Couldn't not allocate StatusQueue (SET_READY_CSW)\n");
					StatusQueueError = PVCUSB_SET_BIT | PVCUSB_ERR_BIT;
				}
			}
		}else {
			PVCERROR("Couldn't not allocate StatusQueue (SET_READY_CSW)\n");
			StatusQueueError = PVCUSB_SET_BIT | PVCUSB_ERR_BIT;
		}
		wake_up_interruptible(&WaitQueue);
		break;

	default:
		PVCERROR("Endpoint : Invalid status(%d)\n", CurrentState);
		wake_up_interruptible(&WaitQueue);
		break;
	}
}

uint16_t ep_reset_state(void)
{
	uint16_t whichReturn;

	switch (CurrentState) {
	case CBW_READY:
		whichReturn = PVCUSB_CBW_BIT;
		break;

	case CMD_READY:
		whichReturn = PVCUSB_CMD_BIT;
		break;

	case SET_READY_DATA:
	case SET_READY_CSW :
		whichReturn = PVCUSB_SET_BIT;
		break;

	default:
		whichReturn = 0;
		PVCERROR("Endpoint completion error : Invalid state (%d)\n", CurrentState);
		break;
	}
	
	return (uint16_t)whichReturn;
	
} 

void ep_set_state(
	struct pvc_ms_req *ms_req,
	uint16_t whichReturn,
	uint16_t connectStatus,
	uint32_t returnStatus,
	uint32_t transferedLength)
{
	ms_req->WhichReturn = (uint16_t)whichReturn;
	ms_req->ConnectStatus =(uint16_t)connectStatus;
	ms_req->ReturnStatus = (uint32_t)returnStatus;
	ms_req->TransferedLength = (uint32_t)transferedLength;
}

/*
 * This function is called by the gadget driver after a transfer completes.
 * If the request completes with a successful status, it checks the current 
 * state  of the mass storage driver.
 */
void ms_ep_complete(struct usb_ep *ep, struct usb_request *req)
{
	struct ms_dev *dev = ep->driver_data;
	int32_t status = req->status;
	struct transfer_context *context = (struct transfer_context *)req->context;
	struct pvc_ms_req *ms_req = NULL;
//	uint64_t flags; 
	unsigned long flags; 
	uint16_t whichReturn;

	spin_lock_irqsave(&dev->lock, flags);

	PVCDEBUG("enter ms_ep_complete current status =%d / request status = %d\n", CurrentState, status);
	switch (status) {
	case 0:
		/* Normal Completion */
		ep_normal_completion(ep, req);
		break;

	case -ENODATA:
		/* DMA transfer fails	*/
		PVCERROR("DMA fail:%s gone (%d), %d/%d.  Either the host is gone "
				"or you got the endpoints backwards(%d)\n",
				ep->name, status, req->actual, req->length, CurrentState);
		whichReturn = ep_reset_state();
		if (whichReturn) {
			ms_req = kzalloc(sizeof *ms_req, GFP_KERNEL);
			if( ms_req ){
				memset(ms_req, 0, sizeof *ms_req);
				ep_set_state(ms_req, (whichReturn | PVCUSB_ERR_BIT), 0, DMA_TRANSFER_ERROR, req->actual);
				list_add_tail(&ms_req->list_ms_dev, &todo_list);
				PVCERROR("Endpoint request completion error (ERR2)\n");
			}else {
				PVCERROR("Couldn't not allocate StatusQueue (ERR2)\n");
				StatusQueueError = whichReturn | PVCUSB_ERR_BIT; 
			}
			wake_up_interruptible(&WaitQueue);
		}
		break;

	case -ECONNRESET:
	case -ESHUTDOWN:
		/*
		 * This can happen either if the device disappeared or if
		 * an IN transfer was requested when the host was expecting 
		 * an OUT.
		 */
		PVCERROR("%s gone (%d), %d/%d.  Either the host is gone "
			"or you got the endpoints backwards(%d)\n", 
			ep->name, status, req->actual, req->length, CurrentState);

		whichReturn = ep_reset_state();
		if (whichReturn) {
			ms_req = kzalloc(sizeof *ms_req, GFP_KERNEL);
			if( ms_req ){
				memset(ms_req, 0, sizeof *ms_req);
				ep_set_state(ms_req, (whichReturn | PVCUSB_ERR_BIT), 0, OTHER_TRANSFER_ERROR1, req->actual);
				list_add_tail(&ms_req->list_ms_dev, &todo_list);
				PVCDEBUG("Endpoint in shutdown or reconnect-reset state \n");
			}else {
				PVCERROR("Couldn't not allocate StatusQueue (ERR1)\n");
				StatusQueueError = PVCUSB_ERR_BIT;
			}
			wake_up_interruptible(&WaitQueue);
		}
		break;

	case -EOVERFLOW:
	default:
		/*
		 * Unknown status, but it probably means something's wrong.
		 */
		PVCERROR("%s complete (Unknown status) --> %d, %d/%d(%d)\n", ep->name, status,
			req->actual, req->length, CurrentState);

	case -EREMOTEIO:
		whichReturn = ep_reset_state();
		if (whichReturn) {
			ms_req = kzalloc(sizeof *ms_req, GFP_KERNEL);
			if( ms_req ){
				memset(ms_req, 0, sizeof *ms_req);
				ep_set_state(ms_req, (whichReturn | PVCUSB_ERR_BIT), 0, OTHER_TRANSFER_ERROR2, req->actual);
				list_add_tail(&ms_req->list_ms_dev, &todo_list);
				PVCERROR("Endpoint completion error (ERR2)\n");
			}else {
				PVCERROR("Couldn't not allocate StatusQueue (ERR2)\n");
				StatusQueueError = PVCUSB_ERR_BIT;
			}
			wake_up_interruptible(&WaitQueue);
		}
		break;
	}
	PVCDEBUG("ms_ep_complete() : Going to free %d byte request\n", req->actual);

	if(ep && req && context->free_buffer){
		free_ep_req(ep, req);
	}

	spin_unlock_irqrestore(&dev->lock, flags);
	PVCDEBUG("ms_ep_complete() : completed (%d)\n", CurrentState);
}

/*
 * This function is the entry to begin processing CBWs.  It sets up
 * a request (of length CBW_SIZE) and sets the initial state to IDLE.
 * The request is then queued and the function ms_out_ep_complete
 * (pointed to by req->complete) will be called once the data is available.
 */
struct usb_request *ms_out_ep_start(struct usb_ep *ep, int32_t gfp_flags)
{
	struct usb_request *req;
	struct transfer_context *context;
	int32_t status;

	/* Allocate only enough to get one CBW */
//	req = alloc_ep_req(ep, CBW_SIZE, (void *)ReceiveCbwBuf);
	req = alloc_ep_req(ep, ep->maxpacket, (void *)ReceiveCbwBuf);
	if (!req) {
		PVCERROR("Couldn't allocate EP REQ\n");
		return 0;
	}
	PVCDEBUG("Going to kmalloc context\n");
	context = kmalloc(sizeof(struct transfer_context), GFP_ATOMIC);
	if(!context) {
		PVCERROR("Couldn't allocate context\n");
		usb_ep_free_request(ep, req);
		return 0;
	}
	context->free_buffer = 1;
	req->context = context;

	status = usb_ep_queue(ep, req, gfp_flags);
	if (status == 0) {
		PVCDEBUG("Start %s --> %d\n", ep->name, status);
	} else {
		PVCERROR("ms_out_ep_start : Failed with status = %d\n", status);
		usb_ep_free_request(ep, req);
		return 0;
	}
	return req;
}   

/*
 * This function is called when the device is suspended.
 * It simply changes the state only. (It similar to ms_disconnect)
 */
static void ms_suspend(struct usb_gadget *gadget)
{
	struct ms_dev *dev = get_gadget_data(gadget);
//	uint64_t flags;
	unsigned long flags;
	struct pvc_ms_req *ms_req = NULL;

//	spin_lock_irqsave(&dev->lock, flags);
#if 0	/* Modify 2009/03/25	*/
	if (CurrentState == POW_ON) {
		PVCERROR("ms_suspend : Invalid status (POW_ON)\n");
		spin_unlock_irqrestore(&dev->lock, flags);
		return;
	}
#endif

	if (gadget_is_superspeed(gadget)) {
		usb_gadget_vbus_draw(gadget, 2);
	}
	else {
		disable_ms_eps(dev);

		spin_lock_irqsave(&dev->lock, flags);
		/* clear all queue  */
		clear_queue_info();
		PVCDEBUG("ms_suspend : DACT set\n");		
		UsbChangeStatus = PVCUSB_DACT_BIT;

		ms_req = kzalloc(sizeof *ms_req, GFP_KERNEL);
		if( ms_req ){
			memset(ms_req, 0, sizeof *ms_req);
			list_add_tail(&ms_req->list_ms_dev, &todo_list);
			PVCDEBUG("allocate StatusQueue (ms_disconnect)\n");
		}else {
			PVCERROR("Couldn't not allocate StatusQueue (ms_disconnect)\n");
			StatusQueueError = PVCUSB_ERR_BIT;
		}
		/* CurrentState does go INIT, cause disconnects PC  */
		CurrentState = INIT;

		wake_up_interruptible(&WaitQueue);	
		spin_unlock_irqrestore(&dev->lock, flags);
	}
}

/*
 * This function is called when the device is disconnected from the USB.
 * It simply resets the configuration, disabling both endpoints.
 */
static void ms_disconnect(struct usb_gadget *gadget)
{
	struct ms_dev *dev = get_gadget_data(gadget);
//	uint64_t flags;
	unsigned long flags;
	struct pvc_ms_req *ms_req = NULL;

//	spin_lock_irqsave(&dev->lock, flags);
#if 0	/* Modify 2009/03/25    */
	if (CurrentState == POW_ON) {
		PVCERROR("ms_disconnect : Invalid status (POW_ON)\n");
		spin_unlock_irqrestore(&dev->lock, flags);
		return;
	}
#endif
	if (CurrentState == INIT) {
	//	spin_unlock_irqrestore(&dev->lock, flags);
		PVCDEBUG("ms_disconnect : CurrentState == INIT : return\n");
		return;
	}

	disable_ms_eps(dev);

	spin_lock_irqsave(&dev->lock, flags);

	/* clear all queue	*/
	clear_queue_info();
	PVCDEBUG("ms_disconnect : DACT set\n");
	UsbChangeStatus = PVCUSB_DACT_BIT;

	ms_req = kzalloc(sizeof *ms_req, GFP_KERNEL);
	if( ms_req ){
		memset(ms_req, 0, sizeof *ms_req);
		list_add_tail(&ms_req->list_ms_dev, &todo_list);
		PVCDEBUG("allocate StatusQueue (ms_disconnect)\n");
	}else {
		PVCERROR("Couldn't not allocate StatusQueue (ms_disconnect)\n");
		StatusQueueError = PVCUSB_ERR_BIT;
	}
	/* CurrentState does go INIT, cause disconnects PC	*/
	CurrentState = INIT;

	CurrentSerialNumber++;
	wake_up_interruptible(&WaitQueue);

	spin_unlock_irqrestore(&dev->lock, flags);
}

/*
 * This function is called when this module is unloaded.
 * It frees the control endpoint's buffer and requests as
 * well as the device structure.
 */
static void ms_unbind(struct usb_gadget *gadget)
{

	struct ms_dev *dev = get_gadget_data(gadget);
	if (dev->req) {
		kfree(dev->req->buf);
		usb_ep_free_request(gadget->ep0, dev->req);
	}
	/* Free memory from device struct	*/
	kfree(dev);
	set_gadget_data(gadget, 0);

	/* clear all queue	*/
	clear_queue_info();
}

/*
 * This function is called when the driver is loaded.
 * It initializes the device structure and allocates a buffer 
 * and request for the control endpoint
 */
static int32_t ms_bind(struct usb_gadget *gadget,
		struct usb_gadget_driver *driver)
{
	struct ms_dev *dev;
	struct usb_ep       *ep;
	uint32_t		max_burst;

	dev = kzalloc(sizeof *dev, GFP_KERNEL);
	if (!dev)
		return -ENOMEM;
	memset(dev, 0, sizeof *dev);

	spin_lock_init(&dev->lock);

	dev->gadget = gadget;
	set_gadget_data(gadget, dev);

    /* Find all the endpoints we will use */
	usb_ep_autoconfig_reset(gadget);
	ep = usb_ep_autoconfig(gadget, &fs_bulk_in_desc);
	if (!ep)
		goto autoconf_fail;
	ep->driver_data = dev;
	dev->in_ep = ep;

	ep = usb_ep_autoconfig(gadget, &fs_bulk_out_desc);
	if (!ep)
		goto autoconf_fail;
	ep->driver_data = dev;
	dev->out_ep = ep;

    /* Assume that all endpoint addresses are the same for both speeds */
    hs_bulk_in_desc.bEndpointAddress = fs_bulk_in_desc.bEndpointAddress;
    hs_bulk_out_desc.bEndpointAddress = fs_bulk_out_desc.bEndpointAddress;


	/* Calculate bMaxBurst, we know packet size is 1024 */
	max_burst = min_t(uint32_t, FSG_BUFLEN / 1024, 15);

	ss_bulk_in_desc.bEndpointAddress = fs_bulk_in_desc.bEndpointAddress;
	ss_bulk_in_comp_desc.bMaxBurst = max_burst;

	ss_bulk_out_desc.bEndpointAddress = fs_bulk_out_desc.bEndpointAddress;
	ss_bulk_out_comp_desc.bMaxBurst = max_burst;

	/* Allocate request struct for control transfers */
	dev->req = usb_ep_alloc_request(gadget->ep0, GFP_KERNEL);
	if (!dev->req)
		goto enomem;

	/* Allocate I/O buffer for control transfers */
	dev->req->buf = kmalloc(USB_BUFSIZ, GFP_KERNEL);
	if (!dev->req->buf)
		goto enomem;

	dev->req->complete = ms_setup_complete;
	gadget->ep0->driver_data = dev;

	StoreDev = dev;

	printk("%s, version: " DRIVER_VERSION "\n", longname);

	return 0;

autoconf_fail:
	PVCERROR("ms_bind : Failed to autoconfigure all endpoints\n");
	ms_unbind(gadget);
	return -ENOTSUPP;

enomem:
	PVCERROR("ms_bind : ENOMEM\n");
	ms_unbind(gadget);
	return -ENOMEM;
}

/*
 * This is the main driver structure.
 * It points to the basic function used by the
 * gadget driver to access this module.
 */
static struct usb_gadget_driver ms_driver = {
	.max_speed	= USB_SPEED_SUPER_PLUS,
	.function = (int8_t *) longname,
	.bind =			ms_bind,
	.unbind =		ms_unbind,
	.setup =		ms_setup,
	.disconnect =	ms_disconnect,
    .reset =        ms_disconnect,
	.suspend = 		ms_suspend,
	.driver = {
	.name = (int8_t *) shortname,
	.owner      = THIS_MODULE,
		//  release =
		//  suspend =
		//  resume =
	},
};

/*	[SBG-SAV]
	Revised by Panasonic, 2008-02-28
	Following funstions were implemented by NEC-AT 2003-2004
*/
void ms_set_state(
    uint16_t whichReturn,
    uint16_t connectStatus,
    uint32_t returnStatus,
    uint32_t transferedLength)
{
    StoreGetData.WhichReturn = whichReturn;
    StoreGetData.ConnectStatus = connectStatus;
    StoreGetData.ReturnStatus = returnStatus;
    StoreGetData.TransferedLength = transferedLength;
}

int32_t	PVCUSB_get_data(struct pvc_ms_req *ms_req_current, struct pvc_ms_req *ms_req)
{
	int32_t retVal = 0;

	switch (CurrentState) {
	case INIT:
		if (!list_empty(todo_list.next)) {
			ms_req_current = list_entry(todo_list.next, struct pvc_ms_req, list_ms_dev);
			ms_set_state(ms_req_current->WhichReturn, UsbChangeStatus,
				ms_req_current->ReturnStatus, ms_req_current->TransferedLength);
			list_del_init(&ms_req_current->list_ms_dev);
			kfree(ms_req_current);
		}else {
			ms_set_state(StatusQueueError, UsbChangeStatus, QUEUE_STATE_ERROR, 0);
			StatusQueueError = 0;
		}
		UsbChangeStatus = 0;
		break;

	case CBW_READY:
		if (!list_empty(todo_list.next)) {
			ms_req_current = list_entry(todo_list.next, struct pvc_ms_req, list_ms_dev);
			ms_set_state(ms_req_current->WhichReturn, (PVCUSB_ACT_BIT | UsbChangeStatus),
				ms_req_current->ReturnStatus, ms_req_current->TransferedLength);
			list_del_init(&ms_req_current->list_ms_dev);
			kfree(ms_req_current);
		}else {
			ms_set_state(StatusQueueError, (PVCUSB_ACT_BIT | UsbChangeStatus), QUEUE_STATE_ERROR, 0);
			StatusQueueError = 0;
		}
		UsbChangeStatus = 0;
		break;

	case CBW_DONE:
		if (!list_empty(todo_list.next)) {
			ms_req_current = list_entry(todo_list.next, struct pvc_ms_req, list_ms_dev);
			ms_set_state(ms_req_current->WhichReturn, (PVCUSB_ACT_BIT | UsbChangeStatus),
				ms_req_current->ReturnStatus, ms_req_current->TransferedLength);
			UsbChangeStatus = 0;
			if (StoreGetData.WhichReturn & PVCUSB_CBW_BIT) {
				CurrentState = WAIT_NEXT;
				StoreGetData.SerialNumber = CurrentSerialNumber;
			}

			list_del_init(&ms_req_current->list_ms_dev);
			kfree(ms_req_current);
		}else {
			PVCERROR("No queue found (CBW_DONE)\n");
			retVal = -EFAULT;
		}
		break;

	case CMD_READY:
	case SET_READY_DATA:
	case SET_READY_CSW:
	case WAIT_NEXT:
		if (!list_empty(todo_list.next)) {
			PVCERROR("Fault in queue\n");
			retVal = -EFAULT;
		}else {
			ms_set_state(StatusQueueError, (PVCUSB_ACT_BIT | UsbChangeStatus), QUEUE_STATE_ERROR, 0);
			UsbChangeStatus = 0;
			StatusQueueError = 0;
		}
		break;

	case CMD_DONE:
	case SET_DONE:
		if (!list_empty(todo_list.next)) {
			ms_req_current = list_entry(todo_list.next, struct pvc_ms_req, list_ms_dev);
			ms_set_state(ms_req_current->WhichReturn, (PVCUSB_ACT_BIT | UsbChangeStatus),
				ms_req_current->ReturnStatus, ms_req_current->TransferedLength);
			UsbChangeStatus = 0;
			CurrentState = WAIT_NEXT;

			list_del_init(&ms_req_current->list_ms_dev);
			kfree(ms_req_current);
		}else {
			PVCERROR("No queue found\n");
			retVal = -EFAULT;
		}
		break;

	case POW_ON:
		PVCERROR("Not suppoted : POW_ON\n");
		retVal = -EPERM;
		break;

	default:
		PVCERROR("Invalid state(ioctl)\n");
		retVal = -EPERM;
		break;
	}
	return retVal;
}

int32_t PVCUSB_set_data(struct pvc_ms_req *ms_req_current, struct pvc_ms_req *ms_req)
{
	struct usb_request *req;
	int32_t retVal = 0;
    int32_t status;
    struct transfer_context *context;
	uint32_t t_val;

	if ( (StoreSetData.SetDataTransferInfo & PVCUSB_NO_CSW) &&
		 (StoreSetData.SetDataTransferInfo & PVCUSB_STALL) ) {
		PVCERROR("SEND_STALL : Send STALL\n");
		usb_ep_set_halt(StoreDev->in_ep);
		usb_ep_set_halt(StoreDev->out_ep);
	}else if ( !(StoreSetData.SetDataTransferInfo & PVCUSB_DO_TRANSFER) &&
		       !(StoreSetData.SetDataTransferInfo & PVCUSB_STALL) ) {
		PVCDEBUG("SET_DATA : send only CSW \n");

		t_val = cpu_to_le32(StoreSetData.CswData.signature);
		StoreSetData.CswData.signature = t_val;
		t_val = cpu_to_le32(StoreSetData.CswData.data_residue);
		StoreSetData.CswData.data_residue = t_val;

		memcpy(SendCswBuf, &StoreSetData.CswData, CSW_SIZE);
		req = alloc_ep_req(StoreDev->in_ep, CSW_SIZE, (void *)SendCswBuf);
		if (req) {
			PVCDEBUG("SEND_CSW : Going to kmalloc context\n");
			context = kmalloc(sizeof(struct transfer_context), GFP_ATOMIC);
			if(!context) {
				PVCERROR("SEND_CSW failed : Couldn't allocate context\n");
				usb_ep_free_request(StoreDev->in_ep, req);
				retVal = -ENOMEM;
			}else {
				context->free_buffer = 1;
				req->context = context;
				PreviousState = CurrentState;
				CurrentState = SET_READY_CSW;
				status = usb_ep_queue(StoreDev->in_ep, req, GFP_ATOMIC);
				if (status == 0) {
					PVCDEBUG("SEND_CSW : Start %s --> %d\n", StoreDev->in_ep->name, status);
				} else {
					CurrentState = PreviousState;
					PVCERROR("SEND_CSW failed : usb_ep_queue() failed with status = %d\n", status);
					usb_ep_free_request(StoreDev->in_ep, req);
					retVal = -EFAULT;
				}
			}
		}else {
			PVCERROR("SEND_CSW failed : alloc_ep_req failed\n");
			retVal = -ENOMEM;
		}

	}else if (  (StoreSetData.SetDataTransferInfo & PVCUSB_DO_TRANSFER) &&
				!(StoreSetData.SetDataTransferInfo & PVCUSB_STALL) ) {
		PVCDEBUG("SET_DATA : send DATA & CSW \n");
		req = alloc_ep_req(StoreDev->in_ep, StoreSetData.TransferLength,
									(void *)StoreSetData.TransferAddress);
		if (req) {
			PVCDEBUG("SEND_DATA_CSW : Going to kmalloc context\n");
			context = kmalloc(sizeof(struct transfer_context), GFP_ATOMIC);
			if(!context) {
				PVCERROR("SEND_DATA_CSW : Couldn't allocate context\n");
				usb_ep_free_request(StoreDev->in_ep, req);
				retVal = -ENOMEM;
			}else {
				context->free_buffer = 1;
				req->context = context;
				PreviousState = CurrentState;
				CurrentState = SET_READY_DATA;
				status = usb_ep_queue(StoreDev->in_ep, req, GFP_ATOMIC);
				if (status == 0) {
					PVCDEBUG("SEND_DATA_CSW : Start %s --> %d\n", StoreDev->in_ep->name, status);
				} else {
					CurrentState = PreviousState;
					PVCERROR("SEND_DATA_CSW : usb_ep_queue() failed with status = %d\n", status);
					usb_ep_free_request(StoreDev->in_ep, req);
					retVal = -EFAULT;
				}
			}
		}else {
			PVCERROR("SEND_DATA_CSW : Couldn't allocate req\n");
			retVal = -ENOMEM;
		}

	}else if ( !(StoreSetData.SetDataTransferInfo & PVCUSB_DO_TRANSFER) &&
				(StoreSetData.SetDataTransferInfo & PVCUSB_STALL) ) {
		PVCDEBUG("SEND_STALL_CSW : Send STALL & CSW\n");
		usb_ep_set_halt(StoreDev->in_ep);

		t_val = cpu_to_le32(StoreSetData.CswData.signature);
		StoreSetData.CswData.signature = t_val;
		t_val = cpu_to_le32(StoreSetData.CswData.data_residue);
		StoreSetData.CswData.data_residue = t_val;

		memcpy(SendCswBuf, &StoreSetData.CswData, CSW_SIZE);
		req = alloc_ep_req(StoreDev->in_ep, CSW_SIZE, (void *)SendCswBuf);
		if (req) {
			PVCDEBUG("SEND_STALL_CSW : Going to kmalloc context\n");
			context = kmalloc(sizeof(struct transfer_context), GFP_ATOMIC);
			if(!context) {
				PVCERROR("SEND_STALL_CSW : Couldn't allocate context\n");
				usb_ep_free_request(StoreDev->in_ep, req);
				retVal = -ENOMEM;
			}else {
				context->free_buffer = 1;
				req->context = context;
				PreviousState = CurrentState;
				CurrentState = SET_READY_CSW;
				status = usb_ep_queue(StoreDev->in_ep, req, GFP_ATOMIC);
				if (status == 0) {
					PVCDEBUG("SEND_STALL_CSW : Start %s --> %d\n", StoreDev->in_ep->name, status);
				} else {
					CurrentState = PreviousState;
					PVCERROR("SEND_STALL_CSW : usb_ep_queue() failed with status=%d\n", status);
					usb_ep_free_request(StoreDev->in_ep, req);
					retVal = -EFAULT;
				}
			}
		}else {
			PVCERROR("SEND_STALL_CSW : Couldn't allocate req\n");
			retVal = -ENOMEM;
		}

	}else if (  (StoreSetData.SetDataTransferInfo & PVCUSB_DO_TRANSFER) &&
				(StoreSetData.SetDataTransferInfo & PVCUSB_STALL) ) {
		PVCDEBUG("SEND_STALL_CSW : Send DATA & STALL & CSW = (ame as send DATA and CSW)\n");
		req = alloc_ep_req(StoreDev->in_ep, StoreSetData.TransferLength,
						(void *)StoreSetData.TransferAddress);
		if (req) {
			PVCDEBUG("SEND_DATA_STALL_CSW : Going to kmalloc context\n");
			context = kmalloc(sizeof(struct transfer_context), GFP_ATOMIC);
			if(!context) {
				PVCERROR("SEND_DATA_STALL_CSW : Couldn't allocate context\n");
				usb_ep_free_request(StoreDev->in_ep, req);
				retVal = -ENOMEM;
			}else {
				context->free_buffer = 1;
				req->context = context;
				PreviousState = CurrentState;
				CurrentState = SET_READY_DATA;
				status = usb_ep_queue(StoreDev->in_ep, req, GFP_ATOMIC);
				if (status == 0) {
					PVCDEBUG("SEND_DATA_STALL_CSW : Start %s --> %d\n", StoreDev->in_ep->name, status);
				} else {
					CurrentState = PreviousState;
					PVCERROR("SEND_DATA_STALL_CSW : usb_ep_queue() failed with status=%d\n", status);
					usb_ep_free_request(StoreDev->in_ep, req);
					retVal = -EFAULT;
				}
			}
		}else {
			PVCERROR("SEND_DATA_STALL_CSW : Couldn't allocate req\n");
			retVal = -ENOMEM;
		}
	}else {
		PVCERROR("SET_DATA : Unknown state : May be never happen\n");
		retVal = -EACCES;
	}
	return retVal;
}

static int32_t ms_open(struct inode *inode, struct file *file)
{
	/* Initialize CurrentState	*/
	CurrentState = POW_ON;
	return 0;
}

static int32_t ms_release(struct inode *inode, struct file *file)
{
	return 0;
}

static long ms_ioctl(struct file *file, unsigned int cmd, unsigned long arg)
{
	int32_t retVal = 0;
	struct usb_request *req;
	int32_t status;
	struct transfer_context *context;
//	uint64_t flags;
	unsigned long flags;

	uint32_t packetlength;

	struct pvc_ms_req *ms_req_current = NULL;
	struct pvc_ms_req *ms_req = NULL;

	spin_lock_irqsave(&StoreDev->lock, flags);

	PVCDEBUG("Enter ms_ioctl : Command = %x\n", cmd);

	switch(cmd) {
	case PVCUSB_GET_DATA:
		PVCDEBUG("GET_DATA(%d)\n", CurrentState);
		if (access_ok(VERIFY_WRITE, (void *)arg, sizeof(PVCUSB_GET_DATA_STRUCT))) {
			/* Return StatusQueue & CBW data	*/
			retVal = PVCUSB_get_data(ms_req_current, ms_req);
			if (retVal == 0 && copy_to_user((void *)arg, &StoreGetData, sizeof(PVCUSB_GET_DATA_STRUCT))) {
				PVCERROR("Failed getting CBW data ()\n");
				retVal = -EFAULT;
			}
		}else {
			PVCERROR("Unknown error : Failed getting data\n");
			retVal = -EACCES;
		}
		break;

	case PVCUSB_SET_DATA:
		PVCDEBUG("SET_DATA(%d)\n", CurrentState);

		if ((CurrentState == WAIT_NEXT) || (CurrentState == CMD_READY)) {
			if (access_ok(VERIFY_READ, (void *)arg, sizeof(PVCUSB_SET_DATA_STRUCT))) {
				if (copy_from_user(&StoreSetData, (void *)arg, sizeof(PVCUSB_SET_DATA_STRUCT))) {
					PVCERROR("SET_DATA failed : copy_from_user()\n");
					retVal = -EFAULT;
					break;
				}
				if (StoreSetData.SerialNumber != CurrentSerialNumber) {
					PVCERROR("SET_DATA failed : SerialNumber erro (%08X, %08X)\n", StoreSetData.SerialNumber, CurrentSerialNumber);
					retVal = -EFAULT;
					break;
				}

				retVal = PVCUSB_set_data(ms_req_current, ms_req);
				if(retVal != 0){
					PVCERROR("SET_DATA failed : PVCUSB_set_data() error %d\n", retVal);
					retVal = -EFAULT;
				}	
			}else {
				PVCERROR("SET_DATA : Failed SET_DATA\n");
				retVal = -EACCES;
			}
		}else {
			PVCERROR("SET_DATA : Failed SET_DATA : Illegal CurrentState  [CurrentState = %d]\n", CurrentState);
			retVal = -EPERM;
		}
		break;

	case PVCUSB_COMMAND_STATUS:
		PVCDEBUG("COMMAND_STATUS(%d)\n", CurrentState);

		if (CurrentState == WAIT_NEXT) {
			if (access_ok(VERIFY_READ, (void *)arg, sizeof(PVCUSB_COMMAND_STATUS_STRUCT))) {
				if (copy_from_user(&StoreCommandStatus, (void *)arg, sizeof(PVCUSB_COMMAND_STATUS_STRUCT))) {
					PVCERROR("COMMAND_STATUS : Failed COMMAND_STATUS\n");
					retVal = -EFAULT;
					goto PVCUSB_COMMAND_STATUS_ERROR;
				}
				if (StoreCommandStatus.SerialNumber != CurrentSerialNumber) {
					PVCERROR("COMMAND_STATUS failed : Error in SerialNumber(%08X, %08X)\n",
					StoreCommandStatus.SerialNumber,
					CurrentSerialNumber);
					retVal = -EFAULT;
					goto PVCUSB_COMMAND_STATUS_ERROR;
				}

				if (StoreCommandStatus.CommandStatusTransferInfo & PVCUSB_STALL) {
					PVCERROR("COMMAND_STATUS failed : Set STALL\n");
					PreviousState = CurrentState;
					CurrentState = CMD_DONE;
					usb_ep_set_halt(StoreDev->out_ep);
					ms_req = kzalloc(sizeof *ms_req, GFP_KERNEL);
					if( ms_req ){
						memset(ms_req, 0, sizeof *ms_req);
						ep_set_state(ms_req, PVCUSB_CMD_BIT, 0, 0, 0);
						list_add_tail(&ms_req->list_ms_dev, &todo_list);
						PVCERROR("COMMAND_STATUS failed : (COMMAND_STATUS STALL)\n");
					}else {
						CurrentState = PreviousState;
						PVCERROR("Couldn't not allocate StatusQueue (PVCUSB_COMMAND_STATUS)\n");
						retVal = -ENOMEM;
					}
					wake_up_interruptible(&WaitQueue);
				}else {
					if ( (StoreCommandStatus.DmaInfo.Boundary == 0x00) ||
						(StoreCommandStatus.DmaInfo.Boundary == 0x01) ) {
						packetlength = StoreCommandStatus.DmaInfo.TransferLength0;
						if (StoreCommandStatus.DmaInfo.TransferLength0 < StoreDev->out_ep->maxpacket)
							packetlength = StoreDev->out_ep->maxpacket;
						else if ( (StoreCommandStatus.DmaInfo.TransferLength0 % StoreDev->out_ep->maxpacket) ) {
							packetlength = ((StoreCommandStatus.DmaInfo.TransferLength0/StoreDev->out_ep->maxpacket) + 1) * StoreDev->out_ep->maxpacket;
						}
						req = alloc_ep_req(StoreDev->out_ep, packetlength, (void *)StoreCommandStatus.DmaInfo.TransferAddress0);

					}else {
						PVCERROR("COMMAND_STATUS failed : Boundary invalid\n");
						retVal = -EINVAL;
						goto PVCUSB_COMMAND_STATUS_ERROR;
					}
					if (req) {
						PVCDEBUG("COMMAND_STATUS : Going to kmalloc context\n");
						context = kmalloc(sizeof(struct transfer_context), GFP_ATOMIC);
						if(!context) {
							PVCERROR("COMMAND_STATUS failed : Couldn't allocate context\n");
							usb_ep_free_request(StoreDev->out_ep, req);
							retVal = -ENOMEM;
						}else {
							context->free_buffer = 1;
							req->context = context;
							PreviousState = CurrentState;
							CurrentState = CMD_READY;
							status = usb_ep_queue(StoreDev->out_ep, req, GFP_ATOMIC);
							if (status == 0) {
								PVCDEBUG("COMMAND_STATUS : Start %s --> %d\n", StoreDev->out_ep->name, status);
							} else {
								CurrentState = PreviousState;
								PVCERROR("COMMAND_STATUS failed : usb_ep_queue() failed with status=%d\n", status);
								usb_ep_free_request(StoreDev->out_ep, req);
								retVal = -EFAULT;
							}
						}
					}else {
						PVCERROR("COMMAND_STATUS failed : alloc_ep_req fail\n");
						retVal = -ENOMEM;
					}
				}
			}else {
				PVCERROR("COMMAND_STATUS failed :  Failed COMMAND_STATUS\n");
				retVal = -EACCES;
			}

		}else {
			PVCERROR("COMMAND_STATUS failed : Failed COMMAND_STATUS\n");
			retVal = -EPERM;
		}
PVCUSB_COMMAND_STATUS_ERROR:
		break;

	case PVCUSB_SET_STATE:
		PVCDEBUG("SET_STATE(%d)\n", CurrentState);
		if (arg == PVCUSB_DISABLE_USB_MODE) {
			if (CurrentState != POW_ON) {
				retVal = usb_gadget_unregister_driver(&ms_driver);
				if (retVal == 0) {
					PVCDEBUG("Set PVCUSB_DISABLE_USB_MODE (%d)\n", CurrentState);
					/* clear all queue	*/
					clear_queue_info();
					if (CurrentState != INIT){
						CurrentSerialNumber++;
					}
					CurrentState = POW_ON;
				}else {
					PVCERROR("usb_gadget_unregister_driver failed (%d)\n", retVal);
					retVal = -ENODEV;
				}
			}else {
				PVCERROR("State error was occured (%d) : DISABLE_USB\n", CurrentState);
				retVal = -EPERM;
			}
		}else if (arg == PVCUSB_ENABLE_USB_MODE) {

			PVCDEBUG("Set PVCUSB_ENABLE_USB_MODE (%d)\n", CurrentState);
			/* clear all queue  */
			clear_queue_info();
			CurrentState = INIT;
#if 0	
/* The usb_gadget_probe_driver() call back cause unreliable state.	*/
/* The kernel cound not handlekernel paging request?					*/
/* Then we call usb_gadget_probe_driver() from init() function		*/ 
			if (CurrentState == POW_ON) {
				retVal = usb_gadget_probe_driver(&ms_driver);
				if (retVal == 0) {
					PVCDEBUG("Set PVCUSB_ENABLE_USB_MODE (%d)\n", CurrentState);
					/* clear all queue	*/
					clear_queue_info();
					CurrentState = INIT;
				}else {
					PVCERROR("usb_gadget_probe_driver failed (%d)\n", retVal);
					retVal = -ENODEV;
				}
			}else {
				PVCERROR("State error was occured (%d) : ENABLE_USB\n", CurrentState);
				retVal = -EPERM;
			}
#endif
		}else {
			PVCERROR("Unknown argument : neither set or clear\n");
			retVal = -EINVAL;
		}
		break;

	case PVCUSB_SET_STR_DATA:		/* Support High-end shoulder & mobiles	*/
		PVCDEBUG("SET_STR_DATA(%d)\n", CurrentState);
		if (CurrentState == POW_ON) {
			int32_t len;
			PVCUSB_SET_STR_DATA_STRUCT StrData;
			if (copy_from_user(&StrData, (void *)arg, sizeof(PVCUSB_SET_STR_DATA_STRUCT))) {
				PVCERROR("Copy USB string data from user space failed (1)\n");
				retVal = -EFAULT;
				goto PVCUSB_SET_STR_DATA_ERROR;
			}
			len = ( StrData.manufacturer.len > ( PVCUSB_MAX_MANUFACTURER - 1 ) ) ? ( PVCUSB_MAX_MANUFACTURER - 1 ) : StrData.manufacturer.len;
			memset(manufacturer,0,PVCUSB_MAX_MANUFACTURER);
			if (copy_from_user(manufacturer, (void *)StrData.manufacturer.str, len)){
				PVCERROR("Copy USB string data from user space failed (2)\n");
				retVal = -EFAULT;
				goto PVCUSB_SET_STR_DATA_ERROR;
			}
			len = ( StrData.model.len > ( PVCUSB_MAX_MODEL - 1 ) ) ? ( PVCUSB_MAX_MODEL - 1 ) : StrData.model.len;
			memset(longname,0,PVCUSB_MAX_MODEL);
			if (copy_from_user(longname, (void *)StrData.model.str, len)){
				PVCERROR("Copy USB string data from user space failed (3)\n");
				retVal = -EFAULT;
				goto PVCUSB_SET_STR_DATA_ERROR;
			}
			len = ( StrData.serial.len > ( PVCUSB_MAX_SERIAL - 1 ) ) ? ( PVCUSB_MAX_SERIAL - 1 ) : StrData.serial.len;
			memset(serial,0,PVCUSB_MAX_SERIAL);
			if (copy_from_user(serial, (void *)StrData.serial.str, len)){
				PVCERROR("Copy USB string data from user space failed (4)\n");
				retVal = -EFAULT;
				goto PVCUSB_SET_STR_DATA_ERROR;
			}
		}else {
			PVCERROR("Set string data command failed due to current state is !POW_ON\n");
			retVal = -EACCES;
			goto PVCUSB_SET_STR_DATA_ERROR;
		}
		PVCDEBUG("SET_STR_DATA Exit(%d/%d)\n", retVal, CurrentState);
PVCUSB_SET_STR_DATA_ERROR:
		break;

	case PVCUSB_SET_DEV_DATA:	/* Support High-end shoulder & mobiles  */
		PVCDEBUG("SET_DEV_DATA(%d)\n", CurrentState);
		if (CurrentState == POW_ON) {
			PVCUSB_SET_DEV_DATA_STRUCT DevData;
			if (copy_from_user(&DevData, (void *)arg, sizeof(PVCUSB_SET_DEV_DATA_STRUCT))) {
				PVCERROR("Copy USB device data from user space failed\n");
				retVal = -EFAULT;
				goto PVCUSB_SET_DEV_DATA_ERROR;
			}
			device_desc.idVendor  = DevData.vendor;
			device_desc.idProduct = DevData.product;
			device_desc.bcdDevice = DevData.revision;
		}else {
			PVCERROR("Set device data failed due to current state is !POW_ON\n");
			retVal = -EACCES;
			goto PVCUSB_SET_DEV_DATA_ERROR;
		}
		PVCDEBUG("SET_DEV_DATA Exit(%d/%d)\n", retVal, CurrentState);
PVCUSB_SET_DEV_DATA_ERROR:
		break;

	case PVCUSB_SET_INQ_DATA:
		PVCDEBUG("SET_INQ_DATA(%d)\n", CurrentState);
		if (CurrentState == POW_ON){
			PVCUSB_SET_INQ_DATA_STRUCT	InqData;
			if ( copy_from_user( &InqData, (void *)arg, sizeof(PVCUSB_SET_INQ_DATA_STRUCT) ) ) {
				PVCERROR("Copy USB inquiry data from user space failed\n");
				retVal = -EFAULT;
				goto PVCUSB_SET_INQ_DATA_ERROR;
			}
			memcpy( inq_vendor,   (void *)InqData.vendor,   PVCUSB_INQ_VENDOR   );
			memcpy( inq_product,  (void *)InqData.product,  PVCUSB_INQ_PRODUCT  );
			memcpy( inq_revision, (void *)InqData.revision, PVCUSB_INQ_REVISION );
		}else{
			PVCERROR("Set inquiry data Command failed due to current state is !POW_ON\n");
			retVal = -EACCES;
			goto PVCUSB_SET_INQ_DATA_ERROR;
		}
		PVCDEBUG("SET_INQ_DATA EXIT(%d/%d)\n", retVal, CurrentState);
PVCUSB_SET_INQ_DATA_ERROR:
		break;

	case PVCUSB_SET_CHARGE:
		PVCDEBUG("SET_CHARGE(%d)\n", CurrentState);
		if (CurrentState == POW_ON){
			if ( copy_from_user( (void*)&usbchargereq, (void *)arg, sizeof(uint8_t)) ) {
				PVCERROR("Copy USB Charge from user space failed\n");
				retVal = -EFAULT;
				goto PVCUSB_SET_CHARGE_ERROR;
			}
			PVCERROR("SET_CHARGE(%d-%d)\n", CurrentState, usbchargereq);
		}else{
			PVCERROR("Set Charge Command failed due to current state is !POW_ON\n");
			retVal = -EACCES;
			goto PVCUSB_SET_CHARGE_ERROR;
		}
		PVCDEBUG("SET_CHARGE EXIT(%d/%d)\n", retVal, CurrentState);
PVCUSB_SET_CHARGE_ERROR:
		break;
		
	case PVCUSB_SET_LUN:
		PVCDEBUG("SET_LUN(%d)\n", CurrentState);
		if (CurrentState == POW_ON){
			if ( copy_from_user( (void*)&usblun, (void *)arg, sizeof(uint8_t)) ) {
				PVCERROR("Copy USB LUN from user space failed\n");
				retVal = -EFAULT;
				goto PVCUSB_SET_LUN_ERROR;
			}
		}else{
			PVCERROR("Set LUN Command failed due to current state is !POW_ON\n");
			retVal = -EACCES;
			goto PVCUSB_SET_LUN_ERROR;
		}
		PVCDEBUG("SET_LUN EXIT(%d/%d)\n", retVal, CurrentState);
PVCUSB_SET_LUN_ERROR:
		break;

	default:
		PVCERROR("Invalid ioctl command (%d)\n", CurrentState);
		retVal = -EINVAL;
	}

	PVCDEBUG("Exit ms_ioctl : Command = %d completed with status = %x\n", cmd, retVal);
	spin_unlock_irqrestore(&StoreDev->lock, flags);
	return retVal;
}

static uint32_t ms_poll(struct file *flip, poll_table *wait)
{
	uint32_t mask = 0;

	poll_wait(flip, &WaitQueue, wait);

	if (!list_empty(todo_list.next)) {
		mask |= POLLIN | POLLRDNORM;
	}

	return mask;
}

static struct file_operations ms_fops = {
	owner:   THIS_MODULE,
	open:    ms_open,
	release: ms_release,
	unlocked_ioctl:   ms_ioctl,
	poll:    ms_poll,
};

/*
 * Set up module information
 */
MODULE_AUTHOR("NetChip Technology, Inc (http://www.netchip.com)");
MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("Mass Storage Gadget (PVC)");

/*
 * Module entry point.  Called when the
 * module is loaded
 */
static int32_t __init init(void)
{
	int32_t retVal;
	int32_t dev_num;

	/* initialize list head		*/
	INIT_LIST_HEAD (&todo_list);

	/* Initialize CurrentState	*/
	CurrentState = POW_ON;

	/* You should change this to match a real serial number */
	strncpy(serial, "001", sizeof serial);
	serial[sizeof serial - 1] = 0;

	/* Register character device */

	if (g_ms_major) {
		dev_num = MKDEV( g_ms_major, 0 );
		retVal = register_chrdev_region( dev_num, 1, MS_DRV_NAME );
		if( retVal ){
			PVCERROR("register_chardev_region() error\n");
			return -ENODEV;
		}
	}
	else {
		retVal = alloc_chrdev_region(&dev_num, 0, 1, MS_DRV_NAME );
		if(unlikely(retVal < 0)){
			printk("alloc_chrdev_region() failed(%d)", retVal);
			return retVal;
		}
		g_ms_major = MAJOR(dev_num);
	}

	PVCDEBUG("===== [PVC_MASS_STORAGE] =====\n");
	PVCDEBUG("   major   : %d\n", g_ms_major);
	PVCDEBUG("   dev_num : %d\n", dev_num);
	PVCDEBUG("   MKDEV   : %d\n", MKDEV(g_ms_major, 0));
	PVCDEBUG("=============================\n");

	cdev_init( &pvc_ms_dev, &ms_fops );
	pvc_ms_dev.owner = THIS_MODULE;

	retVal = cdev_add( &pvc_ms_dev, dev_num, 1 );
	if (retVal < 0) {
		PVCERROR("cdev_add() error\n");
		unregister_chrdev_region( dev_num, 1 );
		return -ENODEV;
	}

	ReceiveCbwBuf = kmalloc(MAX_PACKET_SIZE, GFP_ATOMIC);
	if (!ReceiveCbwBuf) {
		PVCERROR("CBW memory could not allocated\n");
		unregister_chrdev_region( dev_num, 1 );
		cdev_del( &pvc_ms_dev );
		unregister_chrdev_region( dev_num, 1 );
		return -ENOMEM;
	}

	SendCswBuf = kmalloc(CSW_SIZE, GFP_ATOMIC);
	if (!SendCswBuf) {
		kfree(ReceiveCbwBuf);
		PVCERROR("CSW memory could not allocated\n");
		cdev_del( &pvc_ms_dev );
		unregister_chrdev_region( dev_num, 1 );
		return -ENOMEM;
	}

	retVal = usb_gadget_probe_driver(&ms_driver);
	if (retVal < 0) {
		PVCERROR("usb_gadget_probe_driver() failed %d\n",retVal);
		kfree(ReceiveCbwBuf);
		kfree(SendCswBuf);
		cdev_del( &pvc_ms_dev );
		unregister_chrdev_region( dev_num, 1 );
		return -ENODEV;
	}

	return 0;
}
module_init(init);

/*
 * Called when module is unloaded
 */
static void __exit cleanup(void)
{
	/* Remove /proc/drivers/ms */
	int32_t dev_num = MKDEV( g_ms_major, 0 );

	/* Do nothing for proc	*/

	/* Tell driver of link controller that we're going away */
	usb_gadget_unregister_driver(&ms_driver);

	if (ReceiveCbwBuf)
		kfree(ReceiveCbwBuf);

	cdev_del( &pvc_ms_dev );
	unregister_chrdev_region( dev_num, 1 );

	/* clear all queue	*/
	clear_queue_info();
}
module_exit(cleanup);
