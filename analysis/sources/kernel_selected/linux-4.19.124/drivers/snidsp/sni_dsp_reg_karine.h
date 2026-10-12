/*
 * Copyright (C) 2019 Socionext Inc.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 2 of the License.
 *
 * @file   sni_dsp_reg_karine.h
 * @author
 * @date
 * @brief  SNI DSP register
 */

#ifndef __SNI_DSP_REG_KARINE_H
#define __SNI_DSP_REG_KARINE_H


//----------------------------------------------------------------------------//
// XM6 reg header
//----------------------------------------------------------------------------//

/* structure of DSPCTRL0 */
union io_xm6_dspctrl0 {
	unsigned int		word;
	struct {
		unsigned int	ACSL		:1;
		unsigned int				:3;
		unsigned int	SLP		:1;
		unsigned int				:3;
		unsigned int	SD		:1;
		unsigned int				:3;
		unsigned int				:4;
		unsigned int				:16;
	}bit;
};

/* structure of DSPCTRL1 */
union io_xm6_dspctrl1 {
	unsigned int		word;
	struct {
		unsigned int	DIV 		:1;
		unsigned int				:31;
	}bit;
};

/* structure of DSPCTRLSR0 */
union io_xm6_dspctrlsr0 {
	unsigned int		word;
	struct {
		unsigned int	SR 		:1;
		unsigned int				:31;
	}bit;
};

/* structure of DSPCTRLSR1 */
union io_xm6_dspctrlsr1 {
	unsigned int		word;
	struct {
		unsigned int	CORESR	 		:1;
		unsigned int				:31;
	}bit;
};


/* structure of DSPCTRL2 */
union io_xm6_dspctrl2 {
	unsigned int		word;
	struct {
		unsigned int	MCI 		:1;
		unsigned int				:31;
	}bit;
};

/* structure of DSPCTRL3 */
union io_xm6_dspctrl3 {
	unsigned int		word;
	struct {
		unsigned int	EXTW 		:1;
		unsigned int				:31;
	}bit;
};


/* structure of INTCTRL0 */
union io_xm6_intctrl0 {
	unsigned int		word;
	struct {
		unsigned int	NMI 		:1;
		unsigned int				:3;
		unsigned int	VINT 		:1;
		unsigned int				:11;
		unsigned int				:16;
	}bit;
};

/* structure of VINT_ADDR */
union io_xm6_vint_addr {
	unsigned int		word;
	struct {
		unsigned int	VINT_ADDR 	:32;
	}bit;
};


/* structure of PSUCTRL0 */
union io_xm6_psuctrl0 {
	unsigned int		word;
	struct {
		unsigned int	LPREQ 		:1;
		unsigned int				:7;
		unsigned int	RECOV 		:1;
		unsigned int				:7;
		unsigned int				:16;
	}bit;
};

/* structure of PSUMON0 */
union io_xm6_psumon0 {
	unsigned int		word;
	struct {
		unsigned int	LPACK 		:1;
		unsigned int	LPACT 		:1;
		unsigned int	DSPIDLE 	:1;
		unsigned int	CORIDLE 	:1;
		unsigned int				:12;
		unsigned int				:16;
	}bit;
};


/* structure of DSPMON0 */
union io_xm6_dspmon0 {
	unsigned int		word;
	struct {
		unsigned int	DSP_GVI	:1;
		unsigned int				:3;
		unsigned int	DSP_JTST	:4;
		unsigned int	DSP_DEBUG	:1;
		unsigned int				:3;
		unsigned int	DSP_COREWAIT:1;
		unsigned int				:3;
		unsigned int	DSP_MMIINT	:1;
		unsigned int				:15;
	}bit;
};


/* structure of AXISEL */
union io_xm6_axisel {
	unsigned int		word;
	struct {
		unsigned int	AXISEL	:1;
		unsigned int				:7;
		unsigned int	QOS_CONF	:1;
		unsigned int				:7;
		unsigned int				:16;
	}bit;
};

union io_xm6_edpaxirctl {
	unsigned int		word;
	struct {
		unsigned int	EDPRCACHE	:4;
		unsigned int				:4;
		unsigned int	EDPRPROT	:3;
		unsigned int				:5;
		unsigned int	EDPRQOS	:4;
		unsigned int				:12;
	}bit;
};

union io_xm6_edpaxiwctl {
	unsigned int		word;
	struct {
		unsigned int	EDPWCACHE	:4;
		unsigned int				:4;
		unsigned int	EDPWPROT	:3;
		unsigned int				:5;
		unsigned int	EDPWQOS	:4;
		unsigned int				:12;
	}bit;
};

union io_xm6_eppaxirctl {
	unsigned int		word;
	struct {
		unsigned int	EPPRCACHE	:4;
		unsigned int				:4;
		unsigned int	EPPRPROT	:3;
		unsigned int				:5;
		unsigned int	EPPRQOS	:4;
		unsigned int				:12;
	}bit;
};

union io_xm6_eppaxiwctl {
	unsigned int		word;
	struct {
		unsigned int	EPPWCACHE	:4;
		unsigned int				:4;
		unsigned int	EPPWPROT	:3;
		unsigned int				:5;
		unsigned int	EPPWQOS	:4;
		unsigned int				:12;
	}bit;
};


union io_xm6_npeaxirctl {
	unsigned int		word;
	struct {
		unsigned int	NPERCACHE	:4;
		unsigned int				:4;
		unsigned int	NPERPROT	:3;
		unsigned int				:5;
		unsigned int	NPERQOS		:4;
		unsigned int				:12;
	}bit;
};

union io_xm6_npeaxiwctl {
	unsigned int		word;
	struct {
		unsigned int	NPEWCACHE	:4;
		unsigned int				:4;
		unsigned int	NPEWPROT	:3;
		unsigned int				:5;
		unsigned int	NPEWQOS		:4;
		unsigned int				:12;
	}bit;
};


/* structure of COMPSEL */
union io_xm6_compsel {
	unsigned int		word;
	struct {
		unsigned int	RID0		:4;
		unsigned int	CMPENR0	:2;
		unsigned int				:2;
		unsigned int	RID1		:4;
		unsigned int	CMPENR1	:2;
		unsigned int				:2;
		unsigned int	WID0		:4;
		unsigned int	CMPENW0	:2;
		unsigned int				:2;
		unsigned int	WID1		:4;
		unsigned int	CMPENW1	:2;
		unsigned int				:2;
	}bit;
};


/* Define I/O Mapping JMLDSPM20VH */
struct io_sni_dsp {
	union io_xm6_dspctrl0		DSPCTRL0;		// 1D00_(0000 - 0003)
	union io_xm6_dspctrl1		DSPCTRL1;		// 1D00_(0004 - 0007)
	union io_xm6_dspctrlsr1		DSPCTRLSR1;		// 1D00_(0008 - 000B)
	unsigned char 				dmy_000C_001F[0x0020-0x000C];
	union io_xm6_dspctrlsr0		DSPCTRLSR0;		// 1D00_(0020 - 0023)
	union io_xm6_dspctrl2		DSPCTRL2;		// 1D00_(0024 - 0027)
	union io_xm6_dspctrl3		DSPCTRL3;		// 1D00_(0028 - 002B)
	union io_xm6_intctrl0		INTCTRL0;		// 1D00_(002C - 002F)
	union io_xm6_compsel		COMPSEL;		// 1D00_(0030 - 0034)
	unsigned char 				dmy_0034_003F[0x0040-0x0034];
	union io_xm6_vint_addr		VINT_ADDR;		// 1D00_(0040 - 0043)
	unsigned char 				dmy_0044_004F[0x0050-0x0044];
	union io_xm6_psuctrl0		PSUCTRL0;		// 1D00_(0050 - 0053)
	union io_xm6_psumon0		PSUMON0;		// 1D00_(0054 - 0057)
	unsigned char 				dmy_0058_0060[0x0060-0x0058];
	union io_xm6_dspmon0		DSPMON0;		// 1D00_(0060 - 0063)
	unsigned char 				dmy_0064_007F[0x0080-0x0064];
	union io_xm6_axisel			AXISEL;			// 1D00_(0080 - 0083)
	union io_xm6_edpaxirctl	EDPAXIRCTL;	// 1D00_(0084 - 0087)
	union io_xm6_edpaxiwctl	EDPAXIWCTL;	// 1D00_(0088 - 008B)
	union io_xm6_eppaxirctl	EPPAXIRCTL;	// 1D00_(008C - 008F)
	union io_xm6_eppaxiwctl	EPPAXIWCTL;	// 1D00_(0090 - 0093)
	unsigned char 				dmy_0094_009B[0x009C-0x0094];
	union io_xm6_npeaxirctl		NPEAXIRCTL;		// 1D00_(009C - 009F)
	union io_xm6_npeaxiwctl		NPEAXIWCTL;		// 1D00_(00A0 - 00A4)
};



#endif	/* __SNI_DSP_REG_KARINE_H */
