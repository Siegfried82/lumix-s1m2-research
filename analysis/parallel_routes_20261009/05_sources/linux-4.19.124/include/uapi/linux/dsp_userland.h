/******************************************************************************
 *
 *  @file   dsp_userland.h
 *  @brief  Userland Definition
 *
 *  Copyright 2019 Socionext Inc.
 ******************************************************************************/
#ifndef __DSP_USERLAND_H
#define __DSP_USERLAND_H


/********************************************************************
 *  Type define
 ********************************************************************/
/* standard type */
typedef signed char         INT8;
typedef signed short        INT16;
typedef signed int          INT32;
typedef signed long long    INT64;
typedef unsigned char       UINT8;
typedef unsigned short      UINT16;
typedef unsigned int        UINT32;
typedef unsigned long long  UINT64;

/* type definition conversion between cpu_linux-cpu_rtos */
typedef void                VOID;
typedef INT8                CHAR;
typedef INT16               SHORT;
typedef INT32               LONG;
typedef INT64               LLONG;
typedef UINT8               UCHAR;
typedef UINT16              USHORT;
typedef UINT32              ULONG;
typedef UINT64              ULLONG;

/********************************************************************
 *  Common define definition
 ********************************************************************/
#define D_SYS_NO_ERR             (0)
#define D_SYS_ERR_SYSCALL        (-1)
#define D_SYS_ERR_DET_SHM        (-2)
#define D_SYS_ERR_PARAM          (-3)

#define XM6_DEV_NAME            "/dev/xm6_peri"
#define CNN_DEV_NAME            "/dev/cnn_peri"

#define XM6_IOCTL_MAGIC         0x77
#define XM6_IOCTL_MAXNR        31

#define CNN_IOCTL_MAGIC         0x78
#define CNN_IOCTL_MINNR        61
#define CNN_IOCTL_MAXNR       69

#define XM6_IOCTL_AUTOCTL_SRAM	_IOW(XM6_IOCTL_MAGIC, 1, T_DSP_PARAM)
#define XM6_IOCTL_SW_SRAMCTL	_IOW(XM6_IOCTL_MAGIC, 2, T_DSP_PARAM)
#define XM6_IOCTL_SLP_SRAM		_IOW(XM6_IOCTL_MAGIC, 3, T_DSP_PARAM)
#define XM6_IOCTL_SD_SRAM		_IOW(XM6_IOCTL_MAGIC, 4, T_DSP_PARAM)
#define XM6_IOCTL_DIV_CTL		_IOW(XM6_IOCTL_MAGIC, 5, T_DSP_PARAM)
#define XM6_IOCTL_RESET_CORE	_IOW(XM6_IOCTL_MAGIC, 6, T_DSP_PARAM)
#define XM6_IOCTL_GET_CORERST	_IOR(XM6_IOCTL_MAGIC, 7, T_DSP_PARAM)
#define XM6_IOCTL_RESET_PERI	_IOW(XM6_IOCTL_MAGIC, 8, T_DSP_PARAM)
#define XM6_IOCTL_TDSEL			_IOW(XM6_IOCTL_MAGIC, 9, T_DSP_PARAM)
#define XM6_IOCTL_CTL_MCI		_IOW(XM6_IOCTL_MAGIC,10, T_DSP_PARAM)
#define XM6_IOCTL_CTL_EXTWAIT	_IOW(XM6_IOCTL_MAGIC,11, T_DSP_PARAM)
#define XM6_IOCTL_REQ_NMI		_IOW(XM6_IOCTL_MAGIC,12, T_DSP_PARAM)
#define XM6_IOCTL_REQ_VINT		_IOW(XM6_IOCTL_MAGIC,13, T_DSP_PARAM)
#define XM6_IOCTL_GET_INTSTAT	_IOR(XM6_IOCTL_MAGIC,14, T_XM6_INTCTRL)
#define XM6_IOCTL_VINT_ADDR		_IOW(XM6_IOCTL_MAGIC,15, T_DSP_PARAM)
#define XM6_IOCTL_SW_LPMODE		_IOW(XM6_IOCTL_MAGIC,16, T_DSP_PARAM)
#define XM6_IOCTL_CTL_RECOV		_IOW(XM6_IOCTL_MAGIC,17, T_DSP_PARAM)
#define XM6_IOCTL_GET_PSUMON	_IOR(XM6_IOCTL_MAGIC,18, T_XM6_PSUMON)
#define XM6_IOCTL_SET_GPIN		_IOW(XM6_IOCTL_MAGIC,19, T_DSP_PARAM)
#define XM6_IOCTL_GET_GPOUT		_IOR(XM6_IOCTL_MAGIC,20, T_DSP_PARAM)
#define XM6_IOCTL_GET_DSPMON	_IOR(XM6_IOCTL_MAGIC,21, T_XM6_DSPMON)
#define XM6_IOCTL_SW_AXICTL		_IOW(XM6_IOCTL_MAGIC,22, T_DSP_PARAM)
#define XM6_IOCTL_CTL_AXI		_IOW(XM6_IOCTL_MAGIC,23, T_XM6_CTRL_AXI)
#define XM6_IOCTL_CTL_GPOUT		_IOW(XM6_IOCTL_MAGIC,24, T_DSP_PARAM)
#define XM6_IOCTL_MEM_ALLOC _IOW(XM6_IOCTL_MAGIC,25, T_XM6_MEM)
#define XM6_IOCTL_MEM_FREE _IOW(XM6_IOCTL_MAGIC,26, T_XM6_MEM)
#define XM6_IOCTL_IO_REMAP _IOW(XM6_IOCTL_MAGIC,27, T_XM6_MEM)
#define XM6_IOCTL_IO_UNMAP _IOW(XM6_IOCTL_MAGIC,28, T_XM6_MEM)
#define XM6_IOCTL_COPY_U2K  _IOW(XM6_IOCTL_MAGIC,29, T_XM6_COPY)
#define XM6_IOCTL_COPY_K2U  _IOW(XM6_IOCTL_MAGIC,30, T_XM6_COPY)
#define XM6_IOCTL_COPY_K2TCM  _IOW(XM6_IOCTL_MAGIC,31, T_XM6_COPY)


#define CNN_IOCTL_RESET_CORE	_IOW(CNN_IOCTL_MAGIC,61, T_DSP_PARAM)
#define CNN_IOCTL_GET_CORERST	_IOR(CNN_IOCTL_MAGIC,62, T_DSP_PARAM)
#define CNN_IOCTL_SLP_SRAM		_IOW(CNN_IOCTL_MAGIC, 63, T_DSP_PARAM)
#define CNN_IOCTL_SD_SRAM		_IOW(CNN_IOCTL_MAGIC, 64, T_DSP_PARAM)
#define CNN_IOCTL_RESET_PERI		_IOW(CNN_IOCTL_MAGIC, 65, T_DSP_PARAM)
#define CNN_IOCTL_SW_AXICTL		_IOW(CNN_IOCTL_MAGIC,66, T_DSP_PARAM)
#define CNN_IOCTL_CTL_AXI		_IOW(CNN_IOCTL_MAGIC,67, T_CNN_CTRL_AXI)
#define CNN_IOCTL_REQ_LP		_IOW(CNN_IOCTL_MAGIC,68, T_DSP_PARAM)
#define CNN_IOCTL_GET_STATUS	_IOR(CNN_IOCTL_MAGIC,69, T_CNN_STATUS)

#define DSP_SET_ON          (1)
#define DSP_SET_OFF         (0)

#define XM6_CORE_0    (0)
#define XM6_CORE_1    (1)

#define XM6_SEL_PERI_REG (0)   /**< Select XM6 Peripheral Register. */
#define XM6_SEL_CORE_REG (1)   /**< Select XM6 Core's PSVM Register. */

#define XM6_CLKDIV_0		(0)		/**< DIV_EN is set to 1/2, DIV_EN_IOP is set to 1/8. */
#define XM6_CLKDIV_1		(1)		/**< DIV_EN is set to 1/1, DIV_EN_IOP is set to 1/4. */

#define XM6_TIMER_0		(0)		/**< TIMER0 */
#define XM6_TIMER_1		(1)		/**< TIMER1 */
#define XM6_TIMER_2		(2)		/**< TIMER2 */
#define XM6_TIMER_3		(3)		/**< TIMER3 */
#define XM6_TIMER_4		(4)		/**< TIMER4 */
#define XM6_TIMER_5		(5)		/**< TIMER5 */
#define XM6_TIMER_6		(6)		/**< TIMER6 */
#define XM6_TIMER_7		(7)		/**< TIMER7 */

#define XM6_MODE_STANDBY		(0)		/**< PSU(Power Scaling Unit) Standby mode */
#define XM6_MODE_LIGHT_SLEEP	(1)		/**< PSU(Power Scaling Unit) Light Sleep mode */

#define DSP_AXISEL_REG			(0)		/**< Select the registers' value */
#define DSP_AXISEL_CORE		(1)		/**< Select the DSP core's value */

#define XM6_STATE_IDLE   (1)     /**< XM6 Core state is idle. (lightsleep or stand-by mode ) */

#define XM6_0_GPOUT_7_0	(0)		/**< Select XM6-0 cevaxm6_gpout[7:0] */
#define XM6_0_GPOUT_15_8	(1)		/**< Select XM6-0 cevaxm6_gpout[15:8] */
#define XM6_0_GPOUT_23_16	(2)		/**< Select XM6-0 cevaxm6_gpout[23:16] */
#define XM6_0_GPOUT_31_24	(3)		/**< Select XM6-0 cevaxm6_gpout[31:24] */
#define XM6_1_GPOUT_7_0	(4)		/**< Select XM6-1 cevaxm6_gpout[7:0] */
#define XM6_1_GPOUT_15_8	(5)		/**< Select XM6-1 cevaxm6_gpout[15:8] */
#define XM6_1_GPOUT_23_16	(6)		/**< Select XM6-1 cevaxm6_gpout[23:16] */
#define XM6_1_GPOUT_31_24	(7)		/**< Select XM6-1 cevaxm6_gpout[31:24] */
#define CNN_DEBUGOUT_7_0	(8)		/**< Select CNN DEBUG_OUT[7:0] */

/********************************************************************
 *  Debug print
 ********************************************************************/
/*  Trace log output macro      */
#define M_PRINT_TRACE(STRING, ...) printf("%s:%s()[%d]:-- TRACE  "STRING"\n", __FILE__, __func__, __LINE__, ## __VA_ARGS__)
/*  Error log output macro      */
#define M_PRINT_ERROR(STRING, ...) printf("%s:%s()[%d]:** ERROR  "STRING"\n", __FILE__, __func__, __LINE__, ## __VA_ARGS__)
/*  Debug log output macro      */
#define M_PRINT_DEBUG(STRING, ...) printf("%s:%s()[%d]:=> DEBUG  "STRING"\n", __FILE__, __func__, __LINE__, ## __VA_ARGS__)


/********************************************************************
 * Enum definition that describes each channel of XM6
 ********************************************************************/


/********************************************************************
 *  XM6 ioctl structure
 ********************************************************************/
typedef struct{
  UINT32      core;       /**< Set the define "XM6_CORE_0" or "XM6_CORE_1" */
  UINT32      val;        /**< setting value */
}T_DSP_PARAM;

/** INTCTRL status */
typedef struct {
  UINT32        core;     /**< xm6 core */
  UINT8         NMI;      /**< NMI status */
  UINT8         VINT;     /**< VINT status */
} T_XM6_INTCTRL;

/** Power Save Monitor status */
typedef struct {
  UINT32        core;     /**< xm6 core */
  UINT8         LPACK;    /**< AXI Low Power Acknowledge */
  UINT8         LPACT;    /**< AXI Low Power Active indication */
  UINT8         DSPIDLE;  /**< DSP Idle Indication */
  UINT8         CORIDLE;  /**< CORE Idle Indication */
  UINT16        PSR;      /**< Power Shutdown Request per unit domains */
  UINT16        MRM;      /**< Memories Retention Mode */
} T_XM6_PSUMON;

/** DSP Monitor status */
typedef struct {
  UINT32        core;     /**< xm6 core */
  UINT8         GVI;      /**< General Violation Indication */
  UINT8         JTST;     /**< JTAG state */
  UINT8         DEBUG;    /**< OCEM debug mode indication */
  UINT8         COREWAIT; /**< Wait indication from the core */
  UINT8         MMIINT;   /**< Multicore Messaging Interface interrupt */
  UINT32        MMIREAD;  /**< Multicore Messaging Interface read indication */
} T_XM6_DSPMON;

/** AXI Control parameters */
typedef struct {
  UINT8         cache_type;		/**< cache type (4bits)	*/
  UINT8         protect_type;	/**< protect type (3bits) */
  UINT8         qos_type;     /**< Quality of Service type (4bits) */
} T_DSP_CTRL_AXI_TYPE;


/** AXI Control structure */
typedef struct {
  UINT32                  core;     /**< xm6 core */
  T_DSP_CTRL_AXI_TYPE  edp_r;    /**< AXI Ctrl EDP Read */
  T_DSP_CTRL_AXI_TYPE  edp_w;    /**< AXI Ctrl EDP Write */
  T_DSP_CTRL_AXI_TYPE  epp_r;    /**< AXI Ctrl EPP Read */
  T_DSP_CTRL_AXI_TYPE  epp_w;    /**< AXI Ctrl EPP Write */
} T_XM6_CTRL_AXI;

/** AXI Control structure */
typedef struct {
  T_DSP_CTRL_AXI_TYPE  cnn_r;    /**< AXI Ctrl CNN Read */
  T_DSP_CTRL_AXI_TYPE  cnn_w;    /**< AXI Ctrl CNN Write */
} T_CNN_CTRL_AXI;

/** CNN status */
typedef struct {
  UINT8         CSYSACK;    /**< Low Power Acknoledge */
  UINT8         CACTIVE;    /**< CNN Clock Active pin state */
  UINT8         DEBUG_OUT;  /**< DEBUG_OUT pin state */
} T_CNN_STATUS;

typedef struct{
  void*       virtAddr;
   void*       physAddr;
   size_t  size;
} T_XM6_MEM;

typedef struct{
  void* srcAddr;
  void* dstAddr;
  UINT32  size;
} T_XM6_COPY;


#endif	/* __DSP_USERLAND_H */
