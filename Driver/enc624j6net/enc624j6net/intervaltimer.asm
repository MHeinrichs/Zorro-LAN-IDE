******************************************************************************
* Name:    intervaltimer.s                                                   *
* Date:    $Date: 2016-12-18 22:20:04 +0100 (So, 18. Dez 2016) $             * 
* Authors: Henryk Richter                                                    *
******************************************************************************

	;MACHINE	MC68040

	include	exec/types.i
	include	lvo/exec_lib.i
	include	lvo/dos_lib.i
	include	lvo/timer_lib.i
	include	exec/exec.i
	include	dos/dos.i
	include	dos/dostags.i
	include	exec/io.i
	include	dos/dosextens.i
	include exec/lists.i

	ifne	1
		include	"intervaltimer.i"
	else
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
	endc

	xdef	_InterruptIntervalTimer
	xdef	_InitIntervalTimer
	xdef	_ExitIntervalTimer
	xdef	_StartIntervalTimer
	xdef	_StopIntervalTimer

CALLEXEC	macro
		move.l	4.w,a6
		jsr	_LVO\1(a6)
		endm

	section	code,text

TestTimer:
		lea	dos_name,a1		;string base
		moveq	#0,d0
		move.l	4.w,a6
		jsr	_LVOOpenLibrary(a6)
		move.l	d0,dosbase
		beq	.nodos

		move.l	dosbase,a6
		jsr	_LVOOutput(a6)	;get stdout
		move.l	d0,stdout

		lea	timerbase,a1
		bsr	_InitIntervalTimer
		tst.l	d0
		bge	.ok

		move.l	stdout,d0
		move.l	#failtimer,d1
		move.l	dosbase,16
		jsr	_LVOPutStr(a6)
		bra	.error

.ok
		lea	timerbase,a1
		move.l	#10000,d1
		bsr	_StartIntervalTimer

		moveq	#0,d3
.loop
		cmp.l	#10,d3
		bgt.s	.exitloop

		move.l	dosbase,A6
		moveq	#10,d1
		jsr	_LVODelay(a6)

		addq.l	#1,d3
		lea	timerbase,a1
		cmp.l	#100,IVT_Counter(a1)
		blt.s	.loop
.exitloop:

		move.l	#succname,d1
		cmp.l	#10,d3
		ble.s	.succ
		move.l	#failname,d1
.succ:
		jsr	_LVOVPrintf(a6)


		lea	timerbase,a1
		bsr	_StopIntervalTimer
.error
		lea	timerbase,a1
		bsr	_ExitIntervalTimer

		move.l	dosbase,d0
		beq.s	.nodos
		move.l	d0,a1
		move.l	4.w,a6
		jsr	_LVOCloseLibrary(a6)
.nodos:
		rts

; A1 = IVT_TimerStruct 
_InterruptIntervalTimer:
		movem.l	d1-a6,-(sp)
		;<- basic Timer.device ops ->
		move.l	a1,a2

		move.l	IVT_Port(a2),a0
		CALLEXEC	GetMsg
		tst.l	d0
		beq.s	.error

		move.l	IVT_Signal(a2),d0
		move.l	IVT_SigTask(a2),a1
	        CALLEXEC Signal

		tst.b	IVT_Stopflag(a2)
		bne.s	.error			;not exactly an error but same consequence

		move.l	a2,a1
		bsr	_RestartIntervalTimer

		;<- end basic Timer.device ops ->

		;<- useful stuff ->
		addq.l	#1,IVT_Counter(a2)

		;<- useful stuff ->

		bra.s	.endintroutine
.error:
		clr.b	IVT_Runflag(a2)
.endintroutine:
		movem.l	(sp)+,d1-a6
		rts


_InitIntervalTimer:	;prepare timer.device for buffer swap interrupt
			movem.l	d1-a6,-(sp)
			move.l	a1,a2
			move	#IVT_Size-1,d0
.clr
			clr.b	(a1)+	;
			dbf	d0,.clr

			sf	IVT_Init(a2)
			sf	IVT_Runflag(a2)
			;signal to wait for from timer output if output queue full
			moveq	#-1,d0
			CALLEXEC AllocSignal
			move.l	d0,IVT_Signal(a2)
			not.l	d0				; if( d0 == -1 ) d0 = 0
			beq	.error				; error: have to go (shouldn't happen)

			suba.l	a1,a1
			CALLEXEC FindTask
			move.l	d0,IVT_SigTask(a2)

			CALLEXEC CreateMsgPort			;Create MsgPort for timing...
			move.l	d0,IVT_Port(a2)
			beq	.error				;0=error

			move.l	IVT_Port(a2),a0
			move.l	#IOTV_SIZE,d0
			CALLEXEC CreateIORequest
			move.l	d0,IVT_IORequest(a2)
			beq	.error				;0=error

			lea.l	IVT_Int(a2),a0
			lea	_InterruptIntervalTimer(pc),a1
			move.l	a1,IS_CODE(a0)
			move.l	a2,IS_DATA(a0)
			move.b	#NT_INTERRUPT,LN_TYPE(a0)
			move.b	#0,LN_PRI(a0)			;-32,-16,0,16,32

			move.l	IVT_Port(a2),a1
			;move.b	#NT_MSGPORT,LN_TYPE(a1)
			move.b	#PA_SOFTINT,MP_FLAGS(a1)
			move.l	a0,MP_SIGTASK(a1)		;Softint eintragen

			lea	VBtimer_name,a0
			moveq	#UNIT_MICROHZ,d0
			move.l	IVT_IORequest(a2),a1
			moveq	#0,d1
			CALLEXEC OpenDevice
			tst.l	d0
			beq.s	.ok
			moveq	#0,d0
			bra.s	.error
.ok			;OK, timer device is ready
			st	IVT_Init(a2)
			moveq	#1,d0				;OK
.error
			movem.l	(sp)+,d1-a6
			;ret 0 <= err, >0 = ok
			rts

_ExitIntervalTimer:
			;stop timer.device 
			movem.l	d0-a6,-(sp)
			move.l	a1,a2

			sf	IVT_Init(a2)

			move.l	IVT_IORequest(a2),d5
			beq.s	.noIO
			tst.b	IVT_Runflag(a2)
			beq.s	.noAbort
			st	IVT_Stopflag(a2)
		ifne	0
			move.l	d5,a1
			CALLEXEC WaitIO
		else
			move.l	d5,a1
			move.l	IO_DEVICE(a1),a6
			jsr	DEV_ABORTIO(A6)	;clear pending requests
		endc
.noAbort:
			move.l	d5,a1
			CALLEXEC CloseDevice
			move.l	d5,a0
			CALLEXEC DeleteIORequest
			clr.l	IVT_IORequest(a2)
.noIO:
			move.l	IVT_Port(a2),d0
			beq.s	.noPort
			move.l	d0,a0
			CALLEXEC DeleteMsgPort
			clr.l	IVT_Port(a2)
.noPort:
			move.l	IVT_Signal(a2),d0
			cmp.l	#-1,d0
			beq	.nosig
			CALLEXEC FreeSignal
			move.l	#-1,IVT_Signal(a2)
.nosig:
			movem.l	(sp)+,d0-a6
			rts


; input: 
;  A1 = IVT Structure (after init)
;  D1 = Number of Microseconds
_StartIntervalTimer:
		movem.l	d0/a1/a2/a6,-(Sp)
		move.l	a1,a2
		move.l	d1,IVT_Interval(A2)
		sf	IVT_Stopflag(a2)

		tst.b	IVT_Runflag(a2)		;running already ? -> keep it running
		bne.s	.notimer
		move.l	a2,a1
		bsr	_RestartIntervalTimer
.notimer
		movem.l	(sp)+,d0/a1/a2/a6
		rts

; Non-Public
;  A1 - IVT Structure
_RestartIntervalTimer:
		movem.l	d0/a1/a2/a6,-(sp)
		move.l	a1,a2

		move.l	IVT_IORequest(a2),d0
		beq.s	.notimer

		move.l	d0,a1
		move.w	#TR_ADDREQUEST,IO_COMMAND(a1)
		clr.b	IO_FLAGS(a1)
		clr.l	IOTV_TIME+EV_HI(a1)
		move.l	IVT_Interval(A2),IOTV_TIME+EV_LO(a1)

		move.l	IO_DEVICE(a1),a6
		jsr	DEV_BEGINIO(A6)

		st	IVT_Runflag(a2)
.notimer
		movem.l	(sp)+,d0/a1/a2/a6
		rts

_StopIntervalTimer:
		movem.l	d0-a6,-(Sp)
		move.l	a1,a2

		st	IVT_Stopflag(a2)

		tst.b	IVT_Runflag(a2)
		beq.s	.noIO
		move.l	IVT_IORequest(a2),d5
		beq.s	.noIO

		move.l	d5,a1
		move.l	IO_DEVICE(a1),a6
		jsr	DEV_ABORTIO(A6)	;clear pending requests
		sf	IVT_Runflag(a2)
.noIO:
		movem.l	(sp)+,d0-a6
		rts


		section data,data
dosbase:	dc.l	0
stdout:		dc.l	0
timerbase:	ds.b	IVT_Size

dos_name:	dc.b	"dos.library",0
VBtimer_name:	dc.b	"timer.device",0
succname:	dc.b	"success: timer worked",10,0
failname:	dc.b	"failure: timer didn't work",10,0
failtimer:	dc.b	"timer open failure",10,0

	END

