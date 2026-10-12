/******************************************************************************
 *
 *  @file   shared mem.h
 *  @brief  Shared memory Definition
 *
 *  Copyright 2016 Socionext Inc.
 ******************************************************************************/
#ifndef __SHARED_MEM_H
#define __SHARED_MEM_H
/********************************************************************
 *  Common define definition
 ********************************************************************/
typedef enum {
	E_SHARED_MEM_BUFFER = 0,
	E_SHARED_MEM_SYNC
} E_SHARED_MEM;

/********************************************************************
 *  API definition
 ********************************************************************/
void __iomem *shared_mem_get_mem(E_SHARED_MEM mem);

#endif	/* __SHARED_MEM_H */
