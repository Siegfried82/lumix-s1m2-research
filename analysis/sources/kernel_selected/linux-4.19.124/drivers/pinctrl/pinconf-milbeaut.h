/* SPDX-License-Identifier: GPL-2.0 */
/* linux/drivers/pinctrl/pinconf-milbeaut.h
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * publishhed by the Free Software Foundation.
 *
 */

#ifndef __PINCTRL_MILBEAUT_H
#define __PINCTRL_MILBEAUT_H
#include <linux/pinctrl/pinconf-generic.h>
enum pin_config_param_pravte {
	PIN_CONFIG_MIL_BSTEN_ON = PIN_CONFIG_END + 1,
	PIN_CONFIG_MIL_BSTEN_OFF,
	PIN_CONFIG_MIL_RSEL0,
	PIN_CONFIG_MIL_RSEL1,
	PIN_CONFIG_MIL_CDRV1_ON,
	PIN_CONFIG_MIL_CDRV1_OFF,
	PIN_CONFIG_MIL_CDRV2_ON,
	PIN_CONFIG_MIL_CDRV2_OFF,
	PIN_CONFIG_MIL_END,
};

#endif

