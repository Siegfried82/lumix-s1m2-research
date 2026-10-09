/* SPDX-License-Identifier: GPL-2.0 */
/**
 * @file s1m2-m20v-gpio.h
 * @brief GPIO and pinmux configuration definitions for Panasonic LUMIX S1M2.
 */

#ifndef _S1M2_M20V_GPIO_H
#define _S1M2_M20V_GPIO_H

/* Power and Voltage Regulator Control Pins */
#define GPIO_SD0_VCC_EN                 12
#define GPIO_SD1_VCC_EN                 13
#define GPIO_WIFI_PWR_ON                24
#define GPIO_BT_REG_ON                  25
#define GPIO_USB_VBUS_DET               36
#define GPIO_HDMI_HPD                   42

/* Shutter Trigger Interlock */
#define GPIO_SHUTTER_HALF_PRESS         80
#define GPIO_SHUTTER_FULL_PRESS         81

#endif /* _S1M2_M20V_GPIO_H */
