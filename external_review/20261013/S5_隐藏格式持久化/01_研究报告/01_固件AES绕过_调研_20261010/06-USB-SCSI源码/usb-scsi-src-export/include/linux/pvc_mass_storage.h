/*
 * pvc_mass_storage.h - mass storage include file
 *
 * Copyright (c) 2020 Panasonic Corporation
 * 2020-07-16 Modified
 *
 * This file may be used subject to the terms and conditions of the
 * GNU General Public License Version 2, or any later version
 * at your option, as published by the Free Software Foundation.
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 */
 
#ifndef __PVC_MASS_STORAGE_H__
#define __PVC_MASS_STORAGE_H__

#include <linux/types.h>
#include <linux/ioctl.h>

#define PVCUSB_MAX_MANUFACTURER	16
#define PVCUSB_MAX_MODEL		16
#define PVCUSB_MAX_SERIAL		40

#define PVCUSB_INQ_VENDOR		( 8+1)
#define PVCUSB_INQ_PRODUCT		(16+1)
#define PVCUSB_INQ_REVISION		( 4+1)

/* set/clear usb mode	*/
#define PVCUSB_DISABLE_USB_MODE 0
#define PVCUSB_ENABLE_USB_MODE  1

/* ioctl error code		*/
#define PVCUSB_WRONG_PARAM 1
#define PVCUSB_WRONG_STATE 2

/* ineternal macros		*/
#define PVCUSB_STALL       0x01
#define PVCUSB_DO_TRANSFER 0x02
#define PVCUSB_NO_CSW      0x04

/* definition of WhichReturn bit	*/
#define PVCUSB_CBW_BIT     0x0001
#define PVCUSB_CMD_BIT     0x0002
#define PVCUSB_SET_BIT     0x0004
#define PVCUSB_NXT_BIT     0x0008
#define PVCUSB_MRT_BIT     0x0010
#define PVCUSB_ERR_BIT     0x8000

/* definition of ConnectStatus bit	*/
#define PVCUSB_ACT_BIT     0x0001
#define PVCUSB_DACT_BIT    0x0100

/* definition of detail error		*/
#define CBW_REQUEST_ERROR     0x01
#define ALLOC_REQUEST_ERROR   0x02
#define QUEUE_REQUEST_ERROR   0x03
#define ALLOC_CONTEXT_ERROR   0x04
#define DMA_TRANSFER_ERROR    0x05
#define OTHER_TRANSFER_ERROR1 0x06
#define OTHER_TRANSFER_ERROR2 0x07
#define QUEUE_STATE_ERROR     0x08
#define INVALID_STATE_ERROR   0x09

/* GIC/STU/CKG register */
/* GIC */
#define	GICREG_CPU2						0x70011000
#define GICREG_CPU2_SIZE				0x1000
#define GIC_TARGET_CPU0					(0x01)
#define GIC_TARGET_CPU1					(0x02)
#define	GIC_TARGET_CPU2					(0x04)
#define GIC_TARGET_CPU3					(0x08)


/* Bulk-Only Command Structures */
struct PVCUSB_cbw {              /* Command Block Wrapper */
    uint32_t signature;            /* 0x00 CBW Signature */
    uint32_t tag;                  /* 0x04 Command Block Tag */
    uint32_t data_transfer_length; /* 0x08 Number of bytes expected 
                                 *    to be transferred */
    uint8_t flags;                 /* 0x0C   7:Direction of transfer, 
                                   6:Obsolete, 
                                   5-0:Reserved */
    uint8_t lun;                   /* 0x0D 7-4:Reserved, 
                                   3-0:Logical Unit Number */
    uint8_t cb_length;             /* 0x0E 7-5:Reserved, 
                                   4-0:Length of CBWCB (0x00-0x10) */
    uint8_t  cb[16];               /* 0x0F Command Block to be executed */
};

struct PVCUSB_csw {            /* Command Status Wrapper */
    uint32_t signature;       /* 0x00 CSW Signature */
    uint32_t tag;             /* 0x04 Command Status Tag */
    uint32_t data_residue;    /* 0x08 Difference between data expected 
                        and data sent/received */
    uint8_t  status;          /* 0x0C Command Status */
};

/* used to ioctl(xx, GET_DATA, xx)	*/
typedef struct _PVCUSB_GET_DATA_STRUCT{
    uint16_t WhichReturn;
    uint16_t ConnectStatus;
    uint32_t ReturnStatus;
    uint32_t TransferedLength;
    uint32_t SerialNumber;
    struct PVCUSB_cbw CbwData;
}PVCUSB_GET_DATA_STRUCT, *PPVCUSB_GET_DATA_STRUCT;

/* used to ioctl(xx, SET_DATA, xx)	*/
typedef struct _PVCUSB_SET_DATA_STRUCT{
    uint64_t TransferAddress;
    uint32_t SetDataTransferInfo;
    uint32_t TransferLength;
    uint32_t SerialNumber;
    struct PVCUSB_csw CswData;
}PVCUSB_SET_DATA_STRUCT, *PPVCUSB_SET_DATA_STRUCT;

/* used to ioctl(xx, COMMAND_STATUS, xx)	*/
typedef struct _PVCUSB_DMA_INFO_STRUCT{
    uint64_t TransferAddress0;
    uint64_t TransferAddress1;
    uint32_t Boundary;
    uint32_t TransferLength0;
    uint32_t TransferLength1;
}PVCUSB_DMA_INFO_STRUCT, *PPVCUSB_DMA_INFO_STRUCT;

typedef struct _PVCUSB_COMMAND_STATUS_STRUCT{
    uint32_t CommandStatusTransferInfo;
    uint32_t SerialNumber;
    PVCUSB_DMA_INFO_STRUCT DmaInfo;
}PVCUSB_COMMAND_STATUS_STRUCT, *PPVCUSB_COMMAND_STATUS_STRUCT;

typedef struct {
    int32_t len;
    const int8_t* str;
} PVCUSB_SET_STR_DATA_SUB;

typedef struct {
	PVCUSB_SET_STR_DATA_SUB	manufacturer;
	PVCUSB_SET_STR_DATA_SUB	model;
	PVCUSB_SET_STR_DATA_SUB	serial;
} PVCUSB_SET_STR_DATA_STRUCT, *PPVCUSB_SET_STR_DATA_STRUCT;

typedef struct {
    uint16_t vendor;
    uint16_t product;
    uint16_t revision;
} PVCUSB_SET_DEV_DATA_STRUCT, *PPVCUSB_SET_DEV_DATA_STRUCT;

typedef struct {
	uint8_t vendor[PVCUSB_INQ_VENDOR];
	uint8_t product[PVCUSB_INQ_PRODUCT];
	uint8_t revision[PVCUSB_INQ_REVISION];
} PVCUSB_SET_INQ_DATA_STRUCT, *PPVCUSB_INQ_DATA_STRUCT;
#endif /* __PVC_MASS_STORAGE_H__ */


/* ioctl code 			*/
#define PVCUSB_GET_DATA         _IOR('g',0, PVCUSB_GET_DATA_STRUCT *)
#define PVCUSB_SET_DATA         _IOW('g',1, PVCUSB_SET_DATA_STRUCT *)
#define PVCUSB_COMMAND_STATUS   _IOR('g',2, PVCUSB_COMMAND_STATUS_STRUCT *)
#define PVCUSB_SET_STATE        _IOW('g',3, uint64_t)
#define PVCUSB_SET_STR_DATA     _IOW('g',4, PVCUSB_SET_STR_DATA_STRUCT *)
#define PVCUSB_SET_DEV_DATA     _IOW('g',5, PVCUSB_SET_DEV_DATA_STRUCT *)
#define PVCUSB_SET_INQ_DATA     _IOW('g',6, PVCUSB_SET_INQ_DATA_STRUCT *)
#define PVCUSB_SET_CHARGE 	    _IOW('g',7, uint8_t)
#define PVCUSB_SET_LUN	 	    _IOW('g',8, uint8_t)
