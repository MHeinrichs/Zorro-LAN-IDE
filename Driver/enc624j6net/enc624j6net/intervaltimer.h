/*
******************************************************************************
* Name:    intervaltimer.h                                                   *
* Date:    $Date: 2016-12-18 22:20:04 +0100 (So, 18. Dez 2016) $             * 
* Authors: Henryk Richter                                                    *
******************************************************************************
*/
#ifndef _INC_INTERVALTIMER_H
#define _INC_INTERVALTIMER_H

#include <exec/memory.h>
#include <exec/interrupts.h>
#include <exec/tasks.h>
#include <exec/ports.h>
#include <devices/timer.h>

struct	IVT_TimerStruct {
	unsigned long 	 IVT_Interval;
	long		 IVT_Signal;
	struct Task	 *IVT_SigTask;
	struct MsgPort   *IVT_Port;
	struct IORequest *IVT_IORequest;
	struct Device    *IVT_Device;
	struct Interrupt IVT_Int;
	unsigned char    IVT_Init;
	unsigned char 	 IVT_Runflag;
	unsigned char    IVT_Stopflag;
	unsigned char    IVT_Unused;
	unsigned long    IVT_Counter;
};

#if 1
#include	"asminterface.h"
#else
/* self-contained in here as well */
#ifdef __SASC
#define ASM __asm
#define ASMR(x) register __ ## x 
#define ASMREG(x) 
#define SAVEDS __saveds
#else
#define ASM
#define ASMR(x) register
#define ASMREG(x) __asm("" #x "")
#define SAVEDS __saveds
#endif
#endif

ASM SAVEDS int InitIntervalTimer(  ASMR(a1) struct IVT_TimerStruct*  IntervalTimer ASMREG(a1) );
ASM SAVEDS int StartIntervalTimer( ASMR(a1) struct IVT_TimerStruct* IntervalTimer ASMREG(a1),
                                   ASMR(d1) unsigned long           Microsecs     ASMREG(d1) );
ASM SAVEDS int StopIntervalTimer(  ASMR(a1) struct IVT_TimerStruct* IntervalTimer ASMREG(a1) );
ASM SAVEDS int ExitIntervalTimer(  ASMR(a1) struct IVT_TimerStruct*  IntervalTimer ASMREG(a1) );


#endif /* _INC_INTERVALTIMER_H */
