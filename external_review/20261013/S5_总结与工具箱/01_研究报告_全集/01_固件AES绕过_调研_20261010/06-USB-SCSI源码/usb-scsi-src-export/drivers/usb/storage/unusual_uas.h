// SPDX-License-Identifier: GPL-2.0+
/*
 * Driver for USB Attached SCSI devices - Unusual Devices File
 *
 *   (c) 2013 Hans de Goede <<REDACTED_EMAIL>>
 *
 * Based on the same file for the usb-storage driver, which is:
 *   (c) 2000-2002 Matthew Dharm (<REDACTED_EMAIL>)
 *   (c) 2000 Adam J. Richter (<REDACTED_EMAIL>), Yggdrasil Computing, Inc.
 */

/*
 * IMPORTANT NOTE: This file must be included in another file which defines
 * a UNUSUAL_DEV macro before this file is included.
 */

/*
 * If you edit this file, please try to keep it sorted first by VendorID,
 * then by ProductID.
 *
 * If you want to add an entry for this file, be sure to include the
 * following information:
 *	- a patch that adds the entry for your device, including your
 *	  email address right above the entry (plus maybe a brief
 *	  explanation of the reason for the entry),
 *	- lsusb -v output for the device
 * Send your submission to Hans de Goede <<REDACTED_EMAIL>>
 * and don't forget to CC: the USB development list <<REDACTED_EMAIL>>
 */

/* Reported-by: Julian Groß <<REDACTED_EMAIL>> */
UNUSUAL_DEV(0x059f, 0x105f, 0x0000, 0x9999,
		"LaCie",
		"2Big Quadra USB3",
		USB_SC_DEVICE, USB_PR_DEVICE, NULL,
		US_FL_NO_REPORT_OPCODES),

/*
 * Apricorn USB3 dongle sometimes returns "USBSUSBSUSBS" in response to SCSI
 * commands in UAS mode.  Observed with the 1.28 firmware; are there others?
 */
UNUSUAL_DEV(0x0984, 0x0301, 0x0128, 0x0128,
		"Apricorn",
		"",
		USB_SC_DEVICE, USB_PR_DEVICE, NULL,
		US_FL_IGNORE_UAS),

/* Reported-by: David Webb <<REDACTED_EMAIL>> */
UNUSUAL_DEV(0x0bc2, 0x331a, 0x0000, 0x9999,
		"Seagate",
		"Expansion Desk",
		USB_SC_DEVICE, USB_PR_DEVICE, NULL,
		US_FL_NO_REPORT_LUNS),

/* Reported-by: Benjamin Tissoires <<REDACTED_EMAIL>> */
UNUSUAL_DEV(0x13fd, 0x3940, 0x0000, 0x9999,
		"Initio Corporation",
		"INIC-3069",
		USB_SC_DEVICE, USB_PR_DEVICE, NULL,
		US_FL_NO_ATA_1X | US_FL_IGNORE_RESIDUE),

/* Reported-by: Tom Arild Naess <<REDACTED_EMAIL>> */
UNUSUAL_DEV(0x152d, 0x0539, 0x0000, 0x9999,
		"JMicron",
		"JMS539",
		USB_SC_DEVICE, USB_PR_DEVICE, NULL,
		US_FL_NO_REPORT_OPCODES),

/* Reported-by: Claudio Bizzarri <<REDACTED_EMAIL>> */
UNUSUAL_DEV(0x152d, 0x0567, 0x0000, 0x9999,
		"JMicron",
		"JMS567",
		USB_SC_DEVICE, USB_PR_DEVICE, NULL,
		US_FL_BROKEN_FUA | US_FL_NO_REPORT_OPCODES),

/* Reported-by: David Kozub <<REDACTED_EMAIL>> */
UNUSUAL_DEV(0x152d, 0x0578, 0x0000, 0x9999,
		"JMicron",
		"JMS567",
		USB_SC_DEVICE, USB_PR_DEVICE, NULL,
		US_FL_BROKEN_FUA),

/* Reported-by: Hans de Goede <<REDACTED_EMAIL>> */
UNUSUAL_DEV(0x2109, 0x0711, 0x0000, 0x9999,
		"VIA",
		"VL711",
		USB_SC_DEVICE, USB_PR_DEVICE, NULL,
		US_FL_NO_ATA_1X),

/* Reported-by: Icenowy Zheng <<REDACTED_EMAIL>> */
UNUSUAL_DEV(0x2537, 0x1068, 0x0000, 0x9999,
		"Norelsys",
		"NS1068X",
		USB_SC_DEVICE, USB_PR_DEVICE, NULL,
		US_FL_IGNORE_UAS),

/*
 * Initially Reported-by: Takeo Nakayama <<REDACTED_EMAIL>>
 * UAS Ignore Reported by Steven Ellis <<REDACTED_EMAIL>>
 */
UNUSUAL_DEV(0x357d, 0x7788, 0x0000, 0x9999,
		"JMicron",
		"JMS566",
		USB_SC_DEVICE, USB_PR_DEVICE, NULL,
		US_FL_NO_REPORT_OPCODES | US_FL_IGNORE_UAS),

/* Reported-by: Hans de Goede <<REDACTED_EMAIL>> */
UNUSUAL_DEV(0x4971, 0x1012, 0x0000, 0x9999,
		"Hitachi",
		"External HDD",
		USB_SC_DEVICE, USB_PR_DEVICE, NULL,
		US_FL_IGNORE_UAS),

/* Reported-by: Richard Henderson <<REDACTED_EMAIL>> */
UNUSUAL_DEV(0x4971, 0x8017, 0x0000, 0x9999,
		"SimpleTech",
		"External HDD",
		USB_SC_DEVICE, USB_PR_DEVICE, NULL,
		US_FL_NO_REPORT_OPCODES),

/* "G-DRIVE" external HDD hangs on write without these.
 * Patch submitted by Alexander Kappner <<REDACTED_EMAIL>>
 */
UNUSUAL_DEV(0x4971, 0x8024, 0x0000, 0x9999,
		"SimpleTech",
		"External HDD",
		USB_SC_DEVICE, USB_PR_DEVICE, NULL,
		US_FL_ALWAYS_SYNC),
