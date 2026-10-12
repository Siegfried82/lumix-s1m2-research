/* SPDX-License-Identifier: GPL-2.0 */
/*
 * copyright (C) 2019 Socionext Inc.
 *               Takao Orito <<REDACTED_EMAIL>>
 */

#include <uapi/linux/milbeaut_noc_com.h>

int milbeaut_noc_set_bank(struct milbeaut_noc_bank_argv *param);
int milbeaut_noc_get_bank(struct milbeaut_noc_bank_argv *param);
