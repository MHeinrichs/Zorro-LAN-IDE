******************************************************************************
* Name:    intervaltimer.i                                                   *
* Date:    $Date: 2016-12-18 22:20:04 +0100 (So, 18. Dez 2016) $             * 
* Authors: Henryk Richter                                                    *
******************************************************************************
	ifnd	_INC_INTERVALTIMER_I
_INC_INTERVALTIMER_I	EQU	1

	include	exec/types.i

	STRUCTURE	IVT_TimerStruct,0
	ULONG	IVT_Interval		;<1e6 in microseconds
	LONG	IVT_Signal		;Signal that is sent back to task from interrupt
	APTR	IVT_SigTask		;Task that is signaled
	APTR	IVT_Port
	APTR	IVT_IORequest
	APTR	IVT_Device
	STRUCT	IVT_Int,IS_SIZE		;
	BYTE	IVT_Init		; !=0 - initialized
	BYTE	IVT_Runflag		; current status ( !=0 = running )
	BYTE	IVT_Stopflag		; stop request if != 0
	BYTE	IVT_Unused		;
	ULONG	IVT_Counter		; Counter (statistics)
	LABEL	IVT_Size

	endc				;_INC_TIMERTEST_I
