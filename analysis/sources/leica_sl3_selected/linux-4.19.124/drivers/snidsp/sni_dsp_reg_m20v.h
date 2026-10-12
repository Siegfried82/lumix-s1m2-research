/*
 * Copyright (C) 2019 Socionext Inc.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 2 of the License.
 *
 * @file   sni_dsp_reg_m20v.h
 * @author
 * @date
 * @brief  SNI DSP register
 */

#ifndef __SNI_DSP_REG_M20V_H
#define __SNI_DSP_REG_M20V_H


//----------------------------------------------------------------------------//
// XM6 reg header
//----------------------------------------------------------------------------//

/* structure of DSPCTRL0 */
union io_xm6_dspctrl0 {
	unsigned int		word;
	struct {
		unsigned int	ACSLPD0		:1;
		unsigned int	ACSLPD1		:1;
		unsigned int				:2;
		unsigned int	CTRLPSVMD0	:1;
		unsigned int	CTRLPSVMD1	:1;
		unsigned int				:2;
		unsigned int	SLPD0		:1;
		unsigned int	SLPD1		:1;
		unsigned int				:2;
		unsigned int	SDD0		:1;
		unsigned int	SDD1		:1;
		unsigned int				:2;
		unsigned int				:16;
	}bit;
};

/* structure of DSPCTRL2 */
union io_xm6_dspctrl2 {
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
		unsigned int	SRD0 		:1;
		unsigned int				:7;
		unsigned int	SRD1 		:1;
		unsigned int				:7;
		unsigned int	SRCNN 		:1;
		unsigned int				:15;
	}bit;
};

/* structure of DSPCTRLSR1 */
union io_xm6_dspctrlsr1 {
	unsigned int		word;
	struct {
		unsigned int	SR	 		:1;
		unsigned int				:31;
	}bit;
};

/* structure of TDSEL */
union io_xm6_tdsel {
	unsigned int		word;
	struct {
		unsigned int	TDSEL0 		:1;
		unsigned int				:1;
		unsigned int	TDSEL1 		:1;
		unsigned int				:1;
		unsigned int	TDSEL2 		:1;
		unsigned int				:1;
		unsigned int	TDSEL3 		:1;
		unsigned int				:1;
		unsigned int	TDSEL4 		:1;
		unsigned int				:1;
		unsigned int	TDSEL5 		:1;
		unsigned int				:1;
		unsigned int	TDSEL6 		:1;
		unsigned int				:1;
		unsigned int	TDSEL7 		:1;
		unsigned int				:1;
		unsigned int				:16;
	}bit;
};

/* structure of DSPCTRL3 */
union io_xm6_dspctrl3 {
	unsigned int		word;
	struct {
		unsigned int	MCI0 		:1;
		unsigned int				:3;
		unsigned int	MCI1 		:1;
		unsigned int				:11;
		unsigned int				:16;
	}bit;
};

/* structure of DSPCTRL4 */
union io_xm6_dspctrl4 {
	unsigned int		word;
	struct {
		unsigned int	EXTW0 		:1;
		unsigned int				:7;
		unsigned int	EXTW1 		:1;
		unsigned int				:7;
		unsigned int				:16;
	}bit;
};


/* structure of INTCTRL */
union io_xm6_intctrl {
	unsigned int		word;
	struct {
		unsigned int	NMI0 		:1;
		unsigned int	NMI1 		:1;
		unsigned int				:14;
		unsigned int	VINT0 		:1;
		unsigned int	VINT1 		:1;
		unsigned int				:14;
	}bit;
};

/* structure of VINT_ADDR0 */
union io_xm6_vint_addr0 {
	unsigned int		word;
	struct {
		unsigned int	VINT_ADDR0 	:32;
	}bit;
};

/* structure of VINT_ADDR1 */
union io_xm6_vint_addr1 {
	unsigned int		word;
	struct {
		unsigned int	VINT_ADDR1 	:32;
	}bit;
};

/* structure of PSUCTRL0 */
union io_xm6_psuctrl0 {
	unsigned int		word;
	struct {
		unsigned int	LPREQ0 		:1;
		unsigned int				:7;
		unsigned int	RECOV0 		:1;
		unsigned int				:7;
		unsigned int	LPREQ1 		:1;
		unsigned int				:7;
		unsigned int	RECOV1 		:1;
		unsigned int				:7;
	}bit;
};

/* structure of PSUMON0 */
union io_xm6_psumon0 {
	unsigned int		word;
	struct {
		unsigned int	LPACK0 		:1;
		unsigned int	LPACT0 		:1;
		unsigned int	DSPIDLE0 	:1;
		unsigned int	CORIDLE0 	:1;
		unsigned int				:12;
		unsigned int	LPACK1 		:1;
		unsigned int	LPACT1 		:1;
		unsigned int	DSPIDLE1 	:1;
		unsigned int	CORIDLE1 	:1;
		unsigned int				:12;
	}bit;
};

/* structure of PSUMON1 */
union io_xm6_psumon1 {
	unsigned int		word;
	struct {
		unsigned int	PSR0 		:9;
		unsigned int	MRM0 		:7;
		unsigned int	PSR1 		:9;
		unsigned int	MRM1 		:7;
	}bit;
};

/* structure of DSP0_GPIN */
union io_xm6_dsp0_gpin {
	unsigned int		word;
	struct {
		unsigned int	DSP0_GPIN 	:32;
	}bit;
};

/* structure of DSP1_GPIN */
union io_xm6_dsp1_gpin {
	unsigned int		word;
	struct {
		unsigned int	DSP1_GPIN 	:32;
	}bit;
};

/* structure of DSP0_GPOUT */
union io_xm6_dsp0_gpout {
	unsigned int		word;
	struct {
		unsigned int	DSP0_GPOUT 	:32;
	}bit;
};

/* structure of DSP1_GPOUT */
union io_xm6_dsp1_gpout {
	unsigned int		word;
	struct {
		unsigned int	DSP1_GPOUT 	:32;
	}bit;
};

/* structure of DSPMON0 */
union io_xm6_dspmon0 {
	unsigned int		word;
	struct {
		unsigned int	DSP0_GVI	:1;
		unsigned int	DSP1_GVI	:1;
		unsigned int				:2;
		unsigned int	DSP0_JTST	:4;
		unsigned int	DSP1_JTST	:4;
		unsigned int	DSP0_DEBUG	:1;
		unsigned int	DSP1_DEBUG	:1;
		unsigned int				:2;
		unsigned int	DSP0_COREWAIT:1;
		unsigned int	DSP1_COREWAIT:1;
		unsigned int				:2;
		unsigned int	DSP0_MMIINT	:1;
		unsigned int	DSP1_MMIINT	:1;
		unsigned int				:10;
	}bit;
};

/* structure of DSPMON1 */
union io_xm6_dspmon1 {
	unsigned int		word;
	struct {
		unsigned int	DSP0_MMIREAD :32;
	}bit;
};

/* structure of DSPMON2 */
union io_xm6_dspmon2 {
	unsigned int		word;
	struct {
		unsigned int	DSP1_MMIREAD :32;
	}bit;
};


/* structure of AXISEL */
union io_xm6_axisel {
	unsigned int		word;
	struct {
		unsigned int	AXISEL_DSP0	:1;
		unsigned int				:7;
		unsigned int	AXISEL_DSP1	:1;
		unsigned int				:7;
		unsigned int	AXISEL_CNN	:1;
		unsigned int				:15;
	}bit;
};

union io_xm6_edp0axirctl {
	unsigned int		word;
	struct {
		unsigned int	EDP0RCACHE	:4;
		unsigned int				:4;
		unsigned int	EDP0RPROT	:3;
		unsigned int				:5;
		unsigned int	EDP0RQOS	:4;
		unsigned int				:12;
	}bit;
};

union io_xm6_edp0axiwctl {
	unsigned int		word;
	struct {
		unsigned int	EDP0WCACHE	:4;
		unsigned int				:4;
		unsigned int	EDP0WPROT	:3;
		unsigned int				:5;
		unsigned int	EDP0WQOS	:4;
		unsigned int				:12;
	}bit;
};

union io_xm6_edp1axirctl {
	unsigned int		word;
	struct {
		unsigned int	EDP1RCACHE	:4;
		unsigned int				:4;
		unsigned int	EDP1RPROT	:3;
		unsigned int				:5;
		unsigned int	EDP1RQOS	:4;
		unsigned int				:12;
	}bit;
};

union io_xm6_edp1axiwctl {
	unsigned int		word;
	struct {
		unsigned int	EDP1WCACHE	:4;
		unsigned int				:4;
		unsigned int	EDP1WPROT	:3;
		unsigned int				:5;
		unsigned int	EDP1WQOS	:4;
		unsigned int				:12;
	}bit;
};

union io_xm6_epp0axirctl {
	unsigned int		word;
	struct {
		unsigned int	EPP0RCACHE	:4;
		unsigned int				:4;
		unsigned int	EPP0RPROT	:3;
		unsigned int				:5;
		unsigned int	EPP0RQOS	:4;
		unsigned int				:12;
	}bit;
};

union io_xm6_epp0axiwctl {
	unsigned int		word;
	struct {
		unsigned int	EPP0WCACHE	:4;
		unsigned int				:4;
		unsigned int	EPP0WPROT	:3;
		unsigned int				:5;
		unsigned int	EPP0WQOS	:4;
		unsigned int				:12;
	}bit;
};

union io_xm6_epp1axirctl {
	unsigned int		word;
	struct {
		unsigned int	EPP1RCACHE	:4;
		unsigned int				:4;
		unsigned int	EPP1RPROT	:3;
		unsigned int				:5;
		unsigned int	EPP1RQOS	:4;
		unsigned int				:12;
	}bit;
};

union io_xm6_epp1axiwctl {
	unsigned int		word;
	struct {
		unsigned int	EPP1WCACHE	:4;
		unsigned int				:4;
		unsigned int	EPP1WPROT	:3;
		unsigned int				:5;
		unsigned int	EPP1WQOS	:4;
		unsigned int				:12;
	}bit;
};

union io_cnn_axirctl {
	unsigned int		word;
	struct {
		unsigned int	CNNRCACHE	:4;
		unsigned int				:4;
		unsigned int	CNNRPROT	:3;
		unsigned int				:5;
		unsigned int	CNNRQOS		:4;
		unsigned int				:12;
	}bit;
};

union io_cnn_axiwctl {
	unsigned int		word;
	struct {
		unsigned int	CNNWCACHE	:4;
		unsigned int				:4;
		unsigned int	CNNWPROT	:3;
		unsigned int				:5;
		unsigned int	CNNWQOS		:4;
		unsigned int				:12;
	}bit;
};

/* structure of CNN_CTRL0 */
union io_cnn_ctrl0 {
	unsigned int		word;
	struct {
		unsigned int	CSYSREQ		:1;
		unsigned int				:31;
	}bit;
};

/* structure of CNN_CTRL1 */
union io_cnn_ctrl1 {
	unsigned int		word;
	struct {
		unsigned int	CSYSACK		:1;
		unsigned int				:3;
		unsigned int	CACTIVE		:1;
		unsigned int				:3;
		unsigned int	DEBUG_OUT	:8;
		unsigned int				:16;
	}bit;
};

/* structure of GPOUT_CTRL */
union io_xm6_dsp_gpout_ctrl {
	unsigned int		word;
	struct {
		unsigned int	DSP_GPOUT_CTRL	:4;
		unsigned int					:12;
		unsigned int					:16;
	}bit;
};


/* Define I/O Mapping JMLDSPM20VH */
struct io_sni_dsp {
	union io_xm6_dspctrl0		DSPCTRL0;		// 1D00_(0000 - 0003)
	unsigned char 				dmy_0004_0007[0x0008-0x0004];
	union io_xm6_dspctrl2		DSPCTRL2;		// 1D00_(0008 - 000B)
	union io_xm6_dspctrlsr0		DSPCTRLSR0;		// 1D00_(000C - 000F)
	unsigned char 				dmy_0010_001F[0x0020-0x0010];
	union io_xm6_dspctrlsr1		DSPCTRLSR1;		// 1D00_(0020 - 0023)
	union io_xm6_tdsel			TDSEL;			// 1D00_(0024 - 0027)
	union io_xm6_dspctrl3		DSPCTRL3;		// 1D00_(0028 - 002B)
	union io_xm6_dspctrl4		DSPCTRL4;		// 1D00_(002C - 002F)
	union io_xm6_intctrl		INTCTRL;		// 1D00_(0030 - 0033)
	unsigned char 				dmy_0034_003F[0x0040-0x0034];
	union io_xm6_vint_addr0		VINT_ADDR0;		// 1D00_(0040 - 0043)
	union io_xm6_vint_addr1		VINT_ADDR1;		// 1D00_(0044 - 0047)
	unsigned char 				dmy_0048_004F[0x0050-0x0048];
	union io_xm6_psuctrl0		PSUCTRL0;		// 1D00_(0050 - 0053)
	union io_xm6_psumon0		PSUMON0;		// 1D00_(0054 - 0057)
	union io_xm6_psumon1		PSUMON1;		// 1D00_(0058 - 005B)
	unsigned char 				dmy_005C_005F[0x0060-0x005C];
	union io_xm6_dsp0_gpin		DSP0_GPIN;		// 1D00_(0060 - 0063)
	union io_xm6_dsp1_gpin		DSP1_GPIN;		// 1D00_(0064 - 0067)
	union io_xm6_dsp0_gpout		DSP0_GPOUT;		// 1D00_(0068 - 006B)
	union io_xm6_dsp1_gpout		DSP1_GPOUT;		// 1D00_(006C - 006F)
	union io_xm6_dspmon0		DSPMON0;		// 1D00_(0070 - 0073)
	union io_xm6_dspmon1		DSPMON1;		// 1D00_(0074 - 0077)
	union io_xm6_dspmon2		DSPMON2;		// 1D00_(0078 - 007B)
	unsigned char 				dmy_007C_007F[0x0080-0x007C];
	union io_xm6_axisel			AXISEL;			// 1D00_(0080 - 0083)
	union io_xm6_edp0axirctl	EDP0AXIRCTL;	// 1D00_(0084 - 0087)
	union io_xm6_edp0axiwctl	EDP0AXIWCTL;	// 1D00_(0088 - 008B)
	union io_xm6_edp1axirctl	EDP1AXIRCTL;	// 1D00_(008C - 008F)
	union io_xm6_edp1axiwctl	EDP1AXIWCTL;	// 1D00_(0090 - 0093)
	union io_xm6_epp0axirctl	EPP0AXIRCTL;	// 1D00_(0094 - 0097)
	union io_xm6_epp0axiwctl	EPP0AXIWCTL;	// 1D00_(0098 - 009B)
	union io_xm6_epp1axirctl	EPP1AXIRCTL;	// 1D00_(009C - 009F)
	union io_xm6_epp1axiwctl	EPP1AXIWCTL;	// 1D00_(00A0 - 00A3)
	union io_cnn_axirctl		CNNAXIRCTL;		// 1D00_(00A4 - 00A7)
	union io_cnn_axiwctl		CNNAXIWCTL;		// 1D00_(00A8 - 00AB)
	unsigned char 				dmy_00AC_00BF[0x00C0-0x00AC];
	union io_cnn_ctrl0			CNN_CTRL0;		// 1D00_(00C0 - 00C3)
	union io_cnn_ctrl1			CNN_CTRL1;		// 1D00_(00C4 - 00C7)
	union io_xm6_dsp_gpout_ctrl	DSP_GPOUT_CTRL;	// 1D00_(00C8 - 00CB)
	//unsigned char 				dmy_00CC_0FFF[0x1000-0x00CC];
};



#endif	/* __SNI_DSP_REG_M20V_H */
