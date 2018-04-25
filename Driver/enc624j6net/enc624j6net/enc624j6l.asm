; ------------------------------------------------------------------------------
; | Lowlevel Access to memory mapped ENC624J600 in PSP mode                    |
; | Henryk Richter <henryk.richter@gmx.net>                                    |
; ------------------------------------------------------------------------------
; Currently, the following assumptions are implemented:
; - device in Mode 3, i.e. 16 Bit access
; - register addresses shifted by 1 left, i.e. register base * 2 compared
;   to 16 Bit mode of ENC624J600 documentation (8 Bit mode alike)
; - some byte shuffling required - which currently is in a state of flux
;
; Note: This code is in some places intentionally saving more registers than 
;       required by the AmigaOS ABI.
;
;
;TODO:
; - setMAC/getMAC endianess awareness
; - Pattern Matching, MC/MC filtering: Multicast,Broadcast,Unicast(self),MagicPacket,correct CRC,"not me" Unicast
; - _enc624j6l_RXReset -> won't recover from totally unresponsive chip (but exits gracefully)
; - RXSTART_INIT = $0c00 -> currently $2000 due to location bug

	incdir	Temp:Amiga/src/Zorro-LAN-IDE.git/Driver/enc624j6net/
	include "enc624j6net/registers.i"
	include "enc624j6net/macros.i"

; enable debugging code block
DEBUG	EQU	0
;

;------------- <DANGER! APPLY CHANGES HERE ALSO TO enc624j6l.h !!> ------------
;
; options for buffer memory configuration, please reserve some space for private variables
;
PSTART_INIT	EQU	$0BF0	; 16 Bytes private storage for driver
PSTOP_INIT	EQU	$0BFF	; (see below for definitions)

RXSTART_INIT   EQU     $2000  ; start of RX buffer, room for 14 packets
RXSTOP_INIT    EQU     $5fff  ; end of RX buffer
                    
TXSTART_INIT   EQU     $0000  ; start of TX buffer, room for 2 packets
TXSTOP_INIT    EQU     $0BEF  ; end of TX buffer (1536+1520 bytes)
                            
; max frame length which the conroller will accept:
; (note: maximum ethernet frame length would be 1518 w/o 802.1Q)
MAX_FRAMELEN   EQU     1518        

;------------ driver private storage ------------------------------
PNextPacket	EQU	PSTART_INIT	;2 Bytes - private "next packet" pointer for RX
PNextTX		EQU	PSTART_INIT+2	;2 Bytes - private "next packet" pointer for TX (init as 0)
PSigBit		EQU	PSTART_INIT+4	;2 Bytes interrupt bit
PSigTask	EQU	PSTART_INIT+6	;4 Bytes signaled task
PLinkChange	EQU	PSTART_INIT+10	;2 Bytes Link Change (copy of PHYDPX,PHYLNK bits)
Punused		EQU	PSTART_INIT+12	;

;------------- TX: double buffering --------------------------------
PSwapTX		EQU	$600		;swap between two TX buffers (one active, one activated after last TX done)
;
;

;------------- driver init flags -----------------------------------
PIO_INIT_FULL_DUPLEX    EQU	1
PIO_INIT_LOOP_BACK      EQU	2
PIO_INIT_BROAD_CAST     EQU	4
PIO_INIT_FLOW_CONTROL   EQU	8
PIO_INIT_MULTI_CAST     EQU	16
PIO_INIT_PROMISC        EQU	32

;------------- </DANGER! APPLY CHANGES HERE ALSO TO enc624j6l.h !!> -----------


	ifne	DEBUG
;
; these are only for the debug code
;
ENC_MANUFACTURER	EQU	2588	;a1k
ENC_BOARDID		EQU	123	;ZII-IDE-LAN-CP
	endc

	;
	;
	; Hardware dependent routines, exported globals
	;
	;
	XDEF	_enc624j6l_CheckBoard	;check whether board is operating correctly
	
	; get/set MAC address
	XDEF	_enc624j6l_GetMAC	;current state, not necessarily burned in MAC
	XDEF	_enc624j6l_SetMAC	;set user defined MAC address

	;delay min. D0 microseconds (<= $0fffffff)
	XDEF	_enc624j6l_UMinDelay

	;init/shut down board (CheckBoard is not allowed between those two)	
	XDEF	_enc624j6l_Init
	XDEF	_enc624j6l_Shutdown

    ;online/offline
	XDEF	_enc624j6l_SetOffline
	XDEF	_enc624j6l_SetOnline
	XDEF	_enc624j6l_CheckLinkChange

	;transmit/receive functions
	XDEF	_enc624j6l_HaveRecv		;
	XDEF	_enc624j6l_RecvFrame		;
	XDEF	_enc624j6l_TransmitFrame	;

	XDEF	_enc624j6l_IntServer
	XDEF	_enc624j6l_EnableInterrupt
	XDEF	_enc624j6l_DisableInterrupt
	XDEF	_enc624j6l_EnableGlobalInterrupt
	XDEF	_enc624j6l_DisableGlobalInterrupt

	;
	; System includes
	;

	ifnd	_LVOSignal
_LVOSignal	EQU	-324
	endc

	;machine	68020

	section	code,code







; -----------------------------------------------------------------------------
; |                                                                           |
; | Test/Debug code                                                           |
; |                                                                           |
; -----------------------------------------------------------------------------
;
;  DEBUG CODE: main function that checks the board, sends a couple of ICMP frames and
;              receives frames until LMOUSE pressed
;
	ifne 	DEBUG
ExecBase                 EQU    4  ; Exec.Base()
OpenLibrary              EQU -552  ; D0:Base=OpenLibrary(A1:libName,D0:version)
CloseLibrary             EQU -414  ; Exec.CloseLibrary(A1:libBase)
PutStr                   EQU -948  ; DOS.PutStr(D1:str)
_LVODelay		EQU	-198
_LVOFindConfigDev	EQU	-72 ; expansion
cd_BoardAddr		EQU	32  ; structure ConfigDev

START:
opendos:
	;libs
	move.l	ExecBase,a6
	lea	DosLibrary(pc),a1
	moveq	#0,d0
	jsr	OpenLibrary(a6)
	move.l	d0,_dosbase
	beq	error

	lea	ExpansionLibrary(pc),a1
	moveq	#36,d0
	jsr	OpenLibrary(a6)
	move.l	d0,_expansionbase

	;expansion scan for first board
	move.l	_expansionbase(pc),a6
	suba.l	a0,a0			;find first board
	move.l	#ENC_MANUFACTURER,d0
	moveq	#ENC_BOARDID,d1
	jsr	_LVOFindConfigDev(a6)
	tst.l	d0
	beq	error
	move.l	d0,a5			;board
	move.l	cd_BoardAddr(A5),d0	;base address
	beq	error
	move.l	d0,_boardbase

	;tests
	move.l	_dosbase(pc),a6
	moveq	#0,d7		;no error

	;Board test
	move.l	_boardbase(pc),a0
	bsr	_enc624j6l_CheckBoard
	move.b	d0,board_status

	; MAC address test
	move.l	_boardbase(pc),a0
	lea	mactestr(pc),a1
	bsr	_enc624j6l_GetMAC

	move.l	_boardbase(pc),a0
	lea	mactest(pc),a1
	bsr	_enc624j6l_SetMAC

	lea	macdest(pc),a1
	move.l	_boardbase(pc),a0
	bsr	_enc624j6l_GetMAC	;verify

	lea	mactest(pc),a0		;verify MAC r/w
	lea	macdest(pc),a1
	move.l	(a0)+,d0
	sub.l	(a1)+,d0
	moveq	#0,d1
	move.w	(a0)+,d1
	sub.w	(a1)+,d1
	move.b	#1,mac_status		;OK
	or.l	d1,d0
	beq.s	.macok
	st	mac_status		;error
.macok:

	move.l	_boardbase(pc),a0
	lea	mactestr(pc),a1
	bsr	_enc624j6l_SetMAC	;restore default MAC

	; Initialize board for sending/receiving
	move.l	_boardbase(pc),a0
	bsr	_enc624j6l_Init
	tst.l	d0
	ble	error

	;---------- transmit test stuff ---------------
	moveq	#100,d2
.txtest:	
	move.l	_boardbase(pc),a0
	lea	txtestframe(pc),a1
	move	#txtestlen,d0
	bsr	_enc624j6l_TransmitFrame	;
	dbf	d2,.txtest

	;----------- receive text stuff ---------------
.loop
	move.l	_boardbase(pc),a0
	;READREG	ESTAT,a0,d0
	bsr	_enc624j6l_HaveRecv
	tst.l	d0
	blt	error			;bail out if error
	beq	.noframe		;nothing received

	;debug: disable recv
	move.l	_boardbase(pc),a0
	moveq	#ECON1_RXEN,d0
	CLRREG	ECON1,a0,d0

	move.l	_boardbase(pc),a0
	lea	readframe,a1
	move	#MAX_FRAMELEN,d0
	bsr	_enc624j6l_RecvFrame


.noframe:
	btst	#6,$bfe001
	bne.s	.loop

error:
	rts

regtests:
	READREG	ESTAT,a0,d0
	READREG	ECON1,a0,d1
	READREG MACON2,a0,d2
	READREG MABBIPG,a0,d3
	rts
	

DosLibrary:		dc.b "dos.library",0
ExpansionLibrary:	dc.b "expansion.library",0
		cnop	0,4
_expansionbase:	dc.l	0
_dosbase:	dc.l	0
_boardbase:	dc.l	0

mactest:	dc.b	$00,$80,$10,$b,$a,$ff	;we write this as test MAC
mactestr:	dc.b	0,0,0,0,0,0		;HW MAC
macdest:	dc.b	0,0,0,0,0,0		;MAC verify

status:		
board_status:	dc.b	0			;ok
mac_status:	dc.b	0			;ok
	cnop	0,4

readframe:	ds.b	1536
endf:

txtestframe:
	dc.b	$ff,$ff,$ff,$ff,$ff,$ff	;, /* broadcast */
	dc.b	$00,$80,$10,$0b,$0a,$ff	;, /* own MAC   */
	dc.b	$08,$00			;, /* Type IPv4 */
				;  /* */
	dc.b	$45,$00			;  /* VER, DSCP */
	dc.b	$00,$54			;, /* length */
	dc.b	$A0,$0A			;, /* id */
	dc.b	$00,$00			;, /* flags, fragment offset */
	dc.b	$40			;, /* TTL */
	dc.b	$01			;, /* ICMP */
	dc.b	$00,$00			;, /* header checksum */
	dc.b	192,168,10,12		;, /* SRC IP */
	dc.b	192,168,10,255		;, /* dest IP */
				;  /* */
	dc.b	$08,$00			;, /* Type, Code = ICMP Echo */
	dc.b	$00,$00			;, /* Checksum */
	dc.b	$DE,$AD			;, /* Identifier */
	dc.b	$00,$01			;, /* SeqNum */

	dc.b	$41,$41,$41,$41,$41,$41,$41,$41
	dc.b	$41,$41,$41,$41,$41,$41,$41,$41
	dc.b	$41,$41,$41,$41,$41,$41,$41,$41
	dc.b	$41,$41,$41,$41,$41,$41,$41,$41
	dc.b	$41,$41,$41,$41,$41,$41,$41,$41
	dc.b	$41,$41,$41,$41,$41,$41,$41,$41
	dc.b	$41,$41,$41,$41,$41,$41,$41,$41
txtestlen EQU	*-txtestframe

	cnop	0,4

	endc
; -----------------------------------------------------------------------------
; |                                                                           |
; | END Test/Debug code                                                       |
; |                                                                           |
; -----------------------------------------------------------------------------




;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
;
; HW dependent functions
;
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------


;------------------------------------------------------------------------------
;
;  Purpose: check whether the board is operating as needed;
;
;  input:   A0 - mmapped board base address
;
;  output:  success/failure
;            >0 - all fine
;	   <=0 - problem (codes undefined yet)
;
;  notes:   The Olimex module on the Matze/Scrat ZII IDE LAN CP prototype
;           tends to boot in SPI mode instead of PSP (parallel) mode.
;           That case is detected by writing/reading data. If both bytes
;           of the words are equal to the last written byte, the board is likely
;           showing this issue.
;           Please note that this call will overwrite Board registers and
;           buffer memory. Call before initialization.
_enc624j6l_CheckBoard:	;check whether board is operating correctly
	movem.l	d1-d2/a0-a1,-(sp)

	move.l	a0,d0
	beq	.err

	moveq	#60,d0			;let the board settle in if there was
	bsr	_enc624j6l_UMinDelay	;a reset or POR (unlikely)


	; ----------------- quick check for operational mode ------------------
	move.w	#$1234,d1
	WRITEREG EUDAST,a0,d1	;write data
	tst.l	4.w		;clear BUS
	READREG	EUDAST,a0,d0
	cmp.w	d0,d1		;do we get the register back ?
	bne.s	.err		;no -> complain


	; ------------------------- reset device ------------------------------
	moveq	#ECON2_ETHRST,d0
	WRITEREG ECON2,a0,d0		;reset board

	moveq	#64-1,d1		;number of loops to test (max. 7.6 ms)
.loop:
	moveq	#120,d0			;wait patiently
	bsr	_enc624j6l_UMinDelay	;

	READREG	ESTAT,a0,d0
	and	#(ESTAT_CLKRDY|ESTAT_RSTDONE|ESTAT_PHYRDY),d0
	cmp	#(ESTAT_CLKRDY|ESTAT_RSTDONE|ESTAT_PHYRDY),d0
	beq	.rstsuccess

	dbf	d1,.loop
	bra.s	.err			;error: device gone after reset

.rstsuccess:
	READREG	EUDAST,A0,d0
	tst.w	d0			;should have gone to 0 after reset
	bne.s	.err			;(see above, we've written $1234)

	;---------- short RAM check - write phase ----------------------------
	;---------- (device is not receiving after reset) --------------------
	moveq	#3,d1
	move.w	#$3000-1,d0
	lea	(a0),a1
.wrloop
;	move.w	d1,(a1)+	
	clr.w	(a1)+
	rol.l	d1
	eor.b	#3,d1
	dbf	d0,.wrloop


	;---------- short RAM check - read phase ------------------------------
	moveq	#3,d1
	move.w	#$3000-1,d0
	lea	(a0),a1
.rdloop
	move.w	(a1)+,d2
	eor.w	d1,d2
;	bne.s	.err
	rol.l	d1
	eor.b	#3,d1
	dbf	d0,.rdloop

	;---------- satisfied, return our sincere happiness -------------------

	moveq	#1,d0	;all fine
	bra.s	.ret
.err:
	moveq	#0,d0
.ret
	movem.l	(sp)+,d1-d2/a0-a1
	rts


;------------------------------------------------------------------------------
;
; Get current MAC address of board
;
; return the 6 Bytes of the MAC address in buffer at A1. Please note that this 
; call either returns the burned in Address (if unchanged) or the current 
; user-set address if the registers were modified before.
;
; In: A0 - Board base address
;     A1 - Pointer to buffer where to store 48 Bit
;
; Out:
;  D0 <= 0 - failure
;        1 
;
; Trash: A0/A1
;
_enc624j6l_GetMAC:			;current state, not necessarily burned in MAC
	move.l	a0,d0
	beq.s	.err
	lea	MAADR1L+2(a0),a0	;after first pair of bytes

	rept	3
		move.w	-(a0),d0
		rol.w	#8,d0
		move.w	d0,(a1)+
	endr

	moveq	#1,d0			;success
.err:	; we land at .err with d0 == 0
	rts


;---------------------------------------------------------------------------------------
;
; Set current MAC address of board
;
; set the 6 Bytes of the MAC address from buffer at A1.
;
; In: A0 - Board base address
;     A1 - Pointer to buffer where to read 48 Bit from
;
; Out:
;  D0 <= 0 - failure
;        1 
;
; Trash: A0/A1
;
_enc624j6l_SetMAC:			;set user defined MAC address
	move.l	a0,d0
	beq.s	.err
	lea	MAADR1L+2(a0),a0	;after first pair of bytes

	move	(a1)+,d0
	rol.w	#8,d0
	move.w	d0,-(a0)

	move	(a1)+,d0
	rol.w	#8,d0
	move.w	d0,-(a0)

	move	(a1)+,d0
	rol.w	#8,d0
	move.w	d0,-(a0)

	moveq	#1,d0
.err:
	rts
	

;---------------------------------------------------------------------------------------
;
; Initialize hardware for send/recv
;
; This call could/should have been done in C. My reason for doing this in ASM was easy 
; testing with low turnaround time.
;
; In: A0 - Board base address
;     D1 - flags
;
; Out:
;  D0 <= 0 - failure
;        1 - OK
;
; Notes: 
;
_enc624j6l_Init:
	move.l	a0,d0
	beq	.err

	READREG	ESTAT,a0,d0
	and	#(ESTAT_CLKRDY|ESTAT_PHYRDY),d0
	cmp	#(ESTAT_CLKRDY|ESTAT_PHYRDY),d0
	beq.s	.goon			;this state is ok for us

	bsr	_enc624j6l_CheckBoard	;preserves all regs
	tst.l	d0			;board reset unsuccessful ?
	ble.w	.err			;-> bail out
.goon:
	;-------------- configure clockout ----------------------
	moveq	#ECON1_RXEN,d0		;no RX, my dear (yet)
	CLRREG	ECON1,a0,d0		;

	;33.333Mhz clock out frequency (see defines above)
	move.w	#CLOCK_DEF_CLR,d0	;clr mask
	CLRREG	ECON2,a0,d0
	move.w	#CLOCK_DEF_SET,d0	;set mask
	SETREG	ECON2,a0,d0

	; disable crypto engine and all interrupts
	move	#EIR_CRYPTEN|EIR_MODEXIF|EIR_HASHIF|EIR_AESIF|EIR_LINKIF|EIR_PRDYIF|EIR_PKTIF|EIR_DMAIF|EIR_TXIF|EIR_TXABTIF|EIR_RXABTIF|EIR_PCFULIF,d0
	CLRREG	EIR,a0,d0

	;--------------- RX configuration -----------------------
	move	#RXSTART_INIT,d0
	WRITEREG ERXST,a0,d0		;set RX start pointer (end will be $5fff)
	WRITEREG PNextPacket,a0,d0	;set user read pointer

	;Multicast,Broadcast,Unicast(self),MagicPacket,correct CRC,filter runts
	;"not me" Unicast == |ERXFCON_NOTMEEN
	moveq	#PIO_INIT_MULTI_CAST,d0
	and	d1,d0
	beq.s	.no_multicast
	move	#ERXFCON_MCEN|ERXFCON_BCEN|ERXFCON_UCEN|ERXFCON_MPEN|ERXFCON_CRCEN|ERXFCON_RUNTEN,d0
	bra.s	.setfilter
.no_multicast
	move	#ERXFCON_BCEN|ERXFCON_UCEN|ERXFCON_MPEN|ERXFCON_CRCEN|ERXFCON_RUNTEN,d0
.setfilter
	WRITEREG ERXFCON,a0,d0 ;set filter TODO: pattern matching stuff

	move	#RXSTOP_INIT&$fffe,d0
	WRITEREG ERXTAIL,a0,d0 ;tail pointer in buffer = rx-2, wraparound

;	ifne	_OPT_FLOWCONTROL
	moveq	#PIO_INIT_FLOW_CONTROL,d0
	and	d1,d0
	beq.s	.init_noflow

	 move	#(128<<8)|(32),d0	;128*96=12288 high water mark, 32*96=3072 low water mark
	 WRITEREG ERXWM,a0,d0
	 moveq	#MACON1_RXPAUS,d0
	 SETREG	MACON1,a0,d0
	 move	#ECON2_AUTOFC,d0
	 SETREG	ECON2,a0,d0
	 bra.s	.init_flowdone
;	else
.init_noflow:
	 move	#ECON2_AUTOFC,d0
	 CLRREG	ECON2,a0,d0		;disable automatic flow control
.init_flowdone:
;	endc


	;--------------- TX configuration -----------------------
	; no padding, no proprietary header
	move	#MACON2_PADCFG2|MACON2_PADCFG1|MACON2_PADCFG0|MACON2_PHDREN,d0
	CLRREG	MACON2,a0,d0
	; add CRC by ENC Chip
	move	#MACON2_PADCFG2|MACON2_PADCFG0|MACON2_TXCRCEN,d0 ;
	SETREG	MACON2,a0,d0
	
	move	#MAX_FRAMELEN,d0
	WRITEREG MAMXFL,a0,d0	;set maximum frame length
	moveq	#0,d0
	WRITEREG PNextTX,a0,d0	;private pointer, "last written, maybe still pending frame"

	moveq	#0,d0
	WRITEREG PLinkChange,a0,d0	;no detected/acknowledged link right now, i.e. LNK and DPX bits = 0

	;--------------- DONE: enable reception -----------------
	moveq	#ECON1_RXEN,d0
	SETREG	ECON1,a0,d0

	moveq	#1,d0
.err:
	rts


;---------------------------------------------------------------------------------------
;
; Shutdown hardware
;
; This call could/should have been done in C. My reason for doing this in ASM was easy 
; testing with low turnaround time.
;
; In: A0 - Board base address
;
; Out:
;  D0 <= 0 - failure
;        1 - OK
;
_enc624j6l_Shutdown:
	move.l	a0,d0
	beq	.err

	bsr	_enc624j6l_SetOffline

	moveq	#1,d0
.err:
	rts


;---------------------------------------------------------------------------------------
;
; Bring device online 
;
; In: A0 - Board base address
;
; Out:
;  D0 <= 0 - failure
;        1 - OK
;
; Notes: - assumes that init() was called before, also please note that init
;          will bring the device online by itself
;        - it will take a while until the device is properly configured (several hundred
;          milliseconds), therefore a delay is advised after calling this (preferably Delay() in DOS)
; 
_enc624j6l_SetOnline:
	move.l	a0,d0
	beq.s	.err

	move	#ECON2_ETHEN|ECON2_STRCH,d0
	SETREG	ECON2,a0,d0

;	move	#PHCON1_PSLEEP,d0
;	CLRREG	PHCON1,a0,d0

	moveq	#ECON1_RXEN,d0
	SETREG	ECON1,a0,d0

	moveq	#0,d0
	WRITEREG PLinkChange,a0,d0	;no detected/acknowledged link right now, i.e. LNK and DPX bits = 0
	
	;moveq	#1,d0	;already set, see above
.err
	rts


;---------------------------------------------------------------------------------------
;
; Bring device offline 
;
; In: A0 - Board base address
;
; Out:
;  D0 <= 0 - failure
;        1 - OK
;
; Notes: assumes that init() was called before
; 
_enc624j6l_SetOffline:
	move.l	a0,d0
	beq.s	.err

	; disable crypto engine and all interrupts
	move	#EIR_CRYPTEN|EIR_MODEXIF|EIR_HASHIF|EIR_AESIF|EIR_LINKIF|EIR_PRDYIF|EIR_PKTIF|EIR_DMAIF|EIR_TXIF|EIR_TXABTIF|EIR_RXABTIF|EIR_PCFULIF,d0
	CLRREG	EIR,a0,d0

	moveq	#ECON1_RXEN,d0
	CLRREG	ECON1,a0,d0

;	move	#PHCON1_PSLEEP,d0
;	SETREG	PHCON1,a0,d0

	move	#ECON2_ETHEN|ECON2_STRCH,d0
	CLRREG	ECON2,a0,d0

	moveq	#1,d0
.err:
	rts


;---------------------------------------------------------------------------------------
;
; Enable Hardware Interrupt
;
; In: A0 - Board base address
;     A1 - Signal Task - task to receive signal
;     D0 - Signal Bit  - the interrupt will send a signal to the given task (BIT, NOT SIGNAL MASK!!)
;     D1 - Interrupt mask (pass 0 for now)
;
; Out:
;  D0 <= 0 - failure
;        1 - OK
;
; Notes: assumes that init() was called before
; 
_enc624j6l_EnableInterrupt:
	move.l	a0,d1
	beq.s	.err

	WRITEREG	PSigBit,a0,d0	;save signal bit

	move.l	a1,d0
	WRITEREG	PSigTask+2,a0,d0 ;lower two bytes
	swap	d0		 ;
	WRITEREG	PSigTask,a0,d0   ;upper two bytes

	; enable interrupt for incoming packet
	moveq	#-1,d0			;magic trick: the board enables Interrupts
	lea	$4000(a0),a0
	move.w	d0,($4000,a0)
	lea	-$4000(a0),a0

	move	#EIE_PKTIE|EIE_INTIE,d0
	SETREG	EIE,a0,d0

	moveq	#1,d0
.rts
	rts
.err:
	moveq	#0,d0
	bra.s	.rts

;---------------------------------------------------------------------------------------
;
; Enable Global Hardware Interrupt
;
; In: A0 - Board base address
;
; Out:
;  D0 <= 0 - failure
;        1 - OK
;
; Notes: assumes that init() was called before
; 
_enc624j6l_EnableGlobalInterrupt:
	move	#EIE_INTIE,d0
	SETREG	EIE,a0,d0
	moveq	#1,d0
.rts
	rts

;---------------------------------------------------------------------------------------
;
; Disable Global Hardware Interrupt
;
; In: A0 - Board base address
;
; Out:
;  D0 <= 0 - failure
;        1 - OK
;
; Notes: assumes that init() was called before
; 
_enc624j6l_DisableGlobalInterrupt:
	move	#EIE_INTIE,d0
	CLRREG	EIE,a0,d0
	moveq	#1,d0
.rts
	rts



;---------------------------------------------------------------------------------------
;
; Disable Hardware Interrupt
;
; In: A0 - Board base address
;
; Out:
;  D0 <= 0 - failure
;        1 - OK
;
; Notes: assumes that init() was called before
; 
_enc624j6l_DisableInterrupt:
	move.l	a0,d0
	beq.s	.err

	moveq	#0,d0			;magic trick: the board enables Interrupts
	lea	$4000(a0),a0
	move.w	d0,($4002.l,a0)
	lea	-$4000(a0),a0
	
	;WRITEREG $8000,a0,d0		;only with this "sesame"

    ;disables all interrupts 
	move	#EIE_INTIE|EIE_PKTIE|EIE_LINKIE|EIE_AESIE|EIE_MODEXIE|EIE_HASHIE|EIE_PRDYIE|EIE_DMAIE|EIE_TXIE|EIE_TXABTIE|EIE_RXABTIE|EIE_PCFULIE,d0
	CLRREG	EIE,a0,d0

	moveq		#0,d0
	WRITEREG	PSigTask+2,a0,d0 ;lower two bytes
	WRITEREG	PSigTask,a0,d0   ;upper two bytes
	
	moveq	#1,d0
.err:
	rts


;---------------------------------------------------------------------------------------
;
; Hardware interrupt service routine
;
; In: A1 - is_data = board base address
;
; Out:   -
;
; Notes: assumes that init() was called before
; 
_enc624j6l_IntServer:
	move.l	a1,d0				;no pointer supplied ? -> return
	beq.s	.rts

	moveq	#EIR_PKTIF,d1
	READREG	EIR,a1,d0			;get interrupt status reg
	and	d1,d0
	beq.s	.rts				;exit quickly when no packet pending
	;CLRREG	EIR,a1,d1			;clear interrupt bit

	;move	#$C000,d0			;disable board interrupt until /INT from ENC toggles
	;lea	$4000(a1),a1			;D0: Bit15 = overall board int enable, Bit14 = ignore int until toggle (1)
	;move.w	d0,($4000,a1)
	;lea	-$4000(a1),a1
	
	move	#EIE_INTIE,D0 ;disable board interrupt until someone enables it again
	CLRREG	EIE,A1,d0
	
	READREG	PSigTask,a1,d0		;upper two bytes
	swap	d0	;
	READREG	PSigTask+2,a1,d0	;lower two bytes
	tst.l	d0			; no task ?
	beq.s	.rts
	move.l	d0,a0			; signaled task

	moveq	#0,d0
	READREG	PSigBit,a1,d1		;get signal bit
	bset	d1,d0			;signal mask
	move.l	a0,a1			;task

	move.l	4.w,a6
	jsr		_LVOSignal(a6)

.rts
	moveq	#0,d0		;set Z flag
	rts


;---------------------------------------------------------------------------------------
;
; check for link change events
;
; In:  A0 = board base address
;
; Out: D0  <0 error
;          =0 ok, no link change handled
;          >0 ok, link change handled
;
; Notes: assumes that init() was called before
; 
_enc624j6l_CheckLinkChange:
	move.l	a0,d0
	beq.s	.rts

	; link change events are captured with Interrupts and stored
	; in the (custom) PLinkChange location (per board) by init and
	; the int server (0 -> no link change, !=0 -> link change)
	READREG PLinkChange,a0,d0		;last known status of LNK and DPX
	READREG	ESTAT,a0,d1
	and	#ESTAT_PHYLNK|ESTAT_PHYDPX,d1	;
	eor.w	d1,d0				;compare
	beq	.nochg

	WRITEREG PLinkChange,a0,d1		;remember last parsed settings

	;check for link down before setting registers
	;also be aware of shutting down FDX mode
	;
	move	#ESTAT_PHYLNK,d0
	and	d1,d0
	bne.s	.linkup

	;
	; offline
	;
	; D1 = ESTAT & (ESTAT_PHYDPX|ESTAT_PHYLNK)
	;

	moveq	#MACON2_FULDPX,d0
	CLRREG	MACON2,a0,d0	;clear fullduplex bit when offline
	moveq	#$12,d0
	WRITEREG MABBIPG,a0,d0	;half duplex when offline

	bra.s	.endchg
.linkup:
	;
	; online
	;
	; D1 = ESTAT & (ESTAT_PHYDPX|ESTAT_PHYLNK)
	;

	; link up and configured
	bfextu	d1{21:1},d1	;get Bit 10 to Bit 0  (ESTAT_PHYDPX -> MACON2_FULDPX)
	READREG	MACON2,a0,d0
	bclr	#0,d0		;clear FDX bit
	or.l	d1,d0		;set if active
	WRITEREG MACON2,a0,d0

	moveq	#$12,d1		;half duplex $12
	btst	#0,d0
	beq.s	.nofdx
	moveq	#$15,d1		;full duplex $15
.nofdx:
	WRITEREG MABBIPG,a0,d1

.endchg:
	moveq	#1,d0
	bra.s	.rts
.nochg:
	moveq	#0,d0
.rts:
	rts


;---------------------------------------------------------------------------------------
;
; Reset Receive pointers 
;
; INTERNAL: re-initialize receive buffer in case of problems (limited testing so far!)
;
; In: A0 - Board base address
;     D1 - flags
;
; Out:
;  D0 <= 0 - failure
;        1 - OK
;
; Notes: - Doesn't check for Board Pointer (!)
;        - doesn't re-enable RX (!)
; 
_enc624j6l_RXReset:

	moveq	#ECON2_RXRST,d0		;RX Reset, clears RXEN
	SETREG	ECON2,a0,d0		;
	;moveq	#ECON1_RXEN,d0		;done by RX reset
	;CLRREG	ECON1,a0,d0		;

	;-------------- manually decrement ESTAT packet count ---------------
	move.w	#$100,d1		;max. loops
.clearESTAT
	READREG	ESTAT,a0,d0
	tst.b	d0			;ESTAT_PKTCNT7...ESTAT_PKTCNT0
	beq.s	.empty
	move	#ECON1_PKTDEC,d0
	SETREG	ECON1,a0,d0		;set packet decrement ("frame", actually)
	dbf	d1,.clearESTAT

	;oh. ESTAT didn't move. This is bad. Full Reset needed
	;(unimplemented yet, pretend we're good)
.empty
	;----------------- restart RX with proper pointers -----------------
	moveq	#ECON2_RXRST,d0		;bring RX out of reset (RXEN still off)
	CLRREG	ECON2,a0,d0		;

	move	#RXSTART_INIT,d0
	WRITEREG ERXST,a0,d0		;set RX start pointer (end will be $5fff)
	WRITEREG PNextPacket,a0,d0	;set user read pointer

	;Multicast,Broadcast,Unicast(self),MagicPacket,correct CRC,"not me" Unicast
	move	#ERXFCON_MCEN|ERXFCON_BCEN|ERXFCON_UCEN|ERXFCON_MPEN|ERXFCON_CRCEN|ERXFCON_NOTMEEN,d0
	WRITEREG ERXFCON,a0,d0 ;set filter TODO: pattern matching stuff
	move	#RXSTOP_INIT&$fffe,d0
	WRITEREG ERXTAIL,a0,d0 ;tail pointer in buffer = rx-2, wraparound

	move	#MAX_FRAMELEN,d0
	WRITEREG MAMXFL,a0,d0	;set maximum frame length

	;moveq	#ECON1_RXEN,d0	;uncomment these for Auto RX re-enabling
	;SETREG	ECON1,a0,d0

	rts

;---------------------------------------------------------------------------------------
;
; check for pending receive frames
;
;  input:  A0 - mmapped board base address
;
;  output:  D0 <0  - error
;               0  - no pending frames
;              >0  - number of pending frames
;
;  trash:   -
;
;  notes:   Interrupt-safe, meant to return quickly
;
_enc624j6l_HaveRecv:
	move.l	a0,d0
	beq.s	.err

	READREG	ESTAT,a0,d0
	and.l	#$ff,d0	;ESTAT_PKTCNT7...ESTAT_PKTCNT0
.rts:
	rts
.err:	moveq	#-1,d0
	bra.s	.rts
	

;---------------------------------------------------------------------------------------
;
; receive single frame from HW into supplied memory buffer
;
;  input:  A0 - APTR   mmapped board base address
;          A1 - APTR   buffer for received frame
;          D0 - SHORT  maximum size in buffer
;
;  output:  D0 <0  - error (i.e. frame too large)
;               0  - no pending frames
;              >0  - size of received frame in buffer
;
;  trash:   -
;
;  notes:  
;
_enc624j6l_RecvFrame:		;
	movem.l	d2-d7/a1-a3,-(sp)
	move.l	a0,d1
	beq	.err

	READREG	ESTAT,a0,d0	;number of pending frames
	and.l	#$ff,d0		;clear out count (ESTAT_PKTCNT7...ESTAT_PKTCNT0)
	beq	.rts		;nothing in buffer, return sheer emptiness
	;at least one frame in buffer

	READREG	ERXHEAD,A0,d4
	READREG	ERXTAIL,A0,d5

	;----------- check next packet pointer and verify expected state -----------
	READREG PNextPacket,a0,d7	;get user read pointer from private space
	;lea	(a0,d7.w),a2		;read ptr for next packet address
	;READREG 0,a2,d0		;next packet pointer

	READSRAM a0,d7,d0		;move (a0,d7.w),d0
	ifeq	_OPT_BUFFER_SWAP
	 rol.w	#8,d0			;swap pointer to Big Endian
	endc

	;verify next packet pointer, re-initialize recv if this is invalid
	cmp	#RXSTOP_INIT,d0		;bad pointer (<0 or >end of memory)
	bhi.w	.recv_err
	cmp	d0,d7
	bgt.s	.maybewrap
	;unwrapped next packet
	move	d0,d1
	bra.s	.ptrcheck
.maybewrap:
	;wrapped next packet ?
	move	#RXSTOP_INIT+1-RXSTART_INIT,d1	;unwrap distance
	add.w	d0,d1				;next pkt + unwrap distance
.ptrcheck:
	sub.w	d7,d1				;length of pkt
	cmp	#MAX_FRAMELEN+2+6,d1		;must be smaller than max framelen + ptr + status vector
	bhi	.recv_err			;-> reinit recv (am I paranoid ? -> try ENC28J60, then you know why...)

	;debug: collect packet positions 
	;move.l	recvptr,a2
	;move	d0,(a2)+
	;move.l	a2,recvptr
	;addq.l	#1,recvcount
	;cmp.l	#65536,recvcount
	;bgt	.recv_err

	WRITEREG PNextPacket,a0,d0	;write pointer for next packet

	;------------------ check receive status vector -----------------------------
	addq.w	#2,d7			;increment pointer
	WRAPINDEX d7			;wrap D7 if beyond buffer
	;lea	(a0,d7.w),a2		;read ptr for first control word
	;READREG 0,a2,d0		;last control word = length (byte count)
	READSRAM a0,d7,d0		;move (a0,d7.w),d0
	ifeq	_OPT_BUFFER_SWAP
	 rol.w	#8,d0			;swap pointer to Big Endian
	endc

	and.w	#$f800,d0		;verify (should be all zeros in upper 9 bits)
	bne	.recv_err		;receive buffer is wrong -> re-initialize

	addq.w	#4,d7			;increment pointer
	WRAPINDEX d7			;wrap D7 if beyond buffer
	;lea	(a0,d7.w),a2		;new read pointer for length
	;READREG 0,a2,d0		;last control word = length (byte count)
	READSRAM a0,d7,d0		;move (a0,d7.w),d0
	ifeq	_OPT_BUFFER_SWAP
	 rol.w	#8,d0			;swap pointer to Big Endian
	endc

	ifne	1
	;D1 is the distance to the next frame = stored length + recv vevtor
	sub	#6+2,d1			;STATUS VECTOR, Pointer
	move	d1,d0			;

	else

	cmp	#2,d0
	blt	.recv_err		;can't be: SRC MAC 6 DST MAC 6 LEN/TYPE 2 CRC 4 (discounting variable data)
	cmp	#MAX_FRAMELEN,d0
	bgt	.recv_err
	
	endc

	subq	#4,d0			;subtract CRC length

	addq.w	#2,d7			;increment pointer (skip status vector length field)
	WRAPINDEX d7			;wrap D7 if beyond buffer
	
	;d0.w: length (without crc)
	;d7.w: read position (beginning of frame, dest MAC)
	;a0:   board I/O
	;a1:   dest pointer
	move.l	a1,a3

	ifne	_OPT_RECV
		move.l	d7,d1			;start
		;and.l	#$FFFF,d1		;keep only lower address
		add.w	d0,d1			;start+bytes
		bvs.s	.nooptrecv		;what? beyond 16 Bit ? -> we really should consider this an error, really :-)
		cmp.w	#RXSTOP_INIT,d1		;
		bgt.s	.nooptrecv		;sadly, we cannot use faster routine atm, because we have a wrap around in the SRAM buffer

	ifne	_OPT_ADR_QUIRK
		eor.w	#$6000,d7
	endc
		lea	(a0,d7.w),a2		;read pointer
		moveq	#3,d1			;round bytes up
		add	d0,d1			;byte count + 3
		lsr	#2,d1			;converted to dword count = ceil(bytes/4)
		subq	#1,d1			;longwords - 1
.opt_read:
	ifne	_OPT_BUFFER_SWAP
		move.l	(a2)+,d2		;get current word
		rol.w	#8,d2			;swap buffer to Big Endian
		swap D2
		rol.w	#8,d2			;swap buffer to Big Endian
		swap D2
		move.l	d2,(a1)+
	else
		move.l	(a2)+,(a1)+
	endc
		dbf	d1,.opt_read
		bra.s	.end_read
.nooptrecv:
	endc	;_OPT_RECV

	;generic loop: check for position overflows with each word
	;
	;CAUTION: DWORD loop doesn`t apply here since buffer is organized
	;         in multiples of two bytes, same for frame lengths and
	;         possible wraparounds
	;
	moveq	#1,d2			;mask for lower bit
	move	d0,d1			;byte count
	lsr	#1,d1			;converted to word count
	and.l	d0,d2			;if lower bits are set ->
	bne.s	.generic_read		;read 1 word more if impair byte/word count
	subq	#1,d1			;words - 1
.generic_read:
	move.w	(a0,d7.w),d2		;get current word
	ifne	_OPT_BUFFER_SWAP
	 rol.w	#8,d2			;swap buffer to Big Endian
	endc
	move.w	d2,(a1)+		; store currend word
	addq	#2,d7			;increment position
	WRAPINDEX d7			;wrap D7 if beyond buffer
	dbf	d1,.generic_read

.end_read:
	;frame copied, now advance HW pointer
	READREG PNextPacket,a0,d1	;write pointer for next packet
	cmp	#RXSTART_INIT,d1
	bne.s	.tail_nowrap
	move	#(RXSTOP_INIT&$fffe)+2,d1
.tail_nowrap:
	subq	#2,d1
	WRITEREG ERXTAIL,a0,d1 		;tail pointer in buffer = rx-2, wraparound

	move	#ECON1_PKTDEC,d1
	SETREG	ECON1,a0,d1		;set packet decrement ("frame", actually)

	ext.l	d0
	cmp.w	#14,d0
	bge.s	.rts

	moveq	#0,d0

;	cmp.l	#$d8803977,6(a3)
;	beq	.rts
;	moveq	#0,d0
;	clr.l	6(a3)

.rts:
	movem.l	(sp)+,d2-d7/a1-a3
	rts
.err:	moveq	#-1,d0		;receive error
	bra.s	.rts
.recv_err:
	;serious problem: we need to re-initialize the recv buffer here
	bsr	_enc624j6l_RXReset

	moveq	#ECON1_RXEN,d0	;re-enable reception
	SETREG	ECON1,a0,d0

	moveq	#0,d0
	bra.s	.rts


;---------------------------------------------------------------------------------------
;
; send single frame from HW
;
;  input:  A0 - APTR   mmapped board base address
;          A1 - APTR   buffer for sent frame (without CRC, appended by the ENC)
;          D0 - SHORT  size of frame in buffer
;
;  output:  D0 <0  - error (i.e. frame too large)
;               0  - no pending frames
;              >0  - size of received frame in buffer
;
;  trash:   -
;
;  notes:  
;
_enc624j6l_TransmitFrame:
	movem.l	d2-d4/a2,-(sp)

	;---------------- parameter check -------------------------------------

	move.l	a0,d1		;no base PTR
	beq.w	.err		;exit

		; this check moved to server.c -> hw.c -> enc624j6l_CheckLinkChange()
		; instead of checking with every TX frame, do it before going to sleep
	ifne	_OPT_CHECKLINK_TX

		READREG PLinkChange,a0,d1		;last known status of LNK and DPX
		READREG	ESTAT,a0,d2			;
		and	#ESTAT_PHYLNK|ESTAT_PHYDPX,d2	;
		eor.w	d2,d1				;compare
		bne.s	.linkchg			;jump to parameter adjust
.linkchgdone:						;.linkchg returns here with another branch

	endc

	move.l	a1,d1		;no send frame ?
	beq.w	.err		;exit

	move.w	d0,d4		;still need length later
	addq	#7,d0		;round up
	asr.w	#3,d0		;size/8 = words
	subq.w	#1,d0		;dbf...
	blt.w	.err		;size<2 ? bail out


	;------ double-buffered frame copy to send buffer ---------------------
	READREG PNextTX,a0,d2	;"last written, maybe still pending frame"
	and.w	#PSwapTX,d2	;sanity, leave only desired bits
	eor.w	#PSwapTX,d2	;swap buffer
	WRITEREG PNextTX,a0,d2	;remember pointer (d2 also for ETXST later)

	lea	(a0,d2.w),a2	;write pointer for frame
	swap	d4
	move.w	#8,d4
.txcopy:
	ifne	_OPT_BUFFER_SWAP
	 move.l	(a1)+,d1
	 move.l	(a1)+,d3
	 ; byte swap in 16 Bit words
	 rol.w	d4,d1
	 rol.w	d4,d3
	 swap	d1
	 swap	d3
	 rol.w	d4,d1
	 rol.w	d4,d3
	 swap	d1
	 swap	d3
	 move.l	d1,(a2)+	;save to SRAM
 	 move.l	d3,(a2)+	;save to SRAM
 	else
	 move.l	(a1)+,(a2)+	;save to SRAM
	 move.l	(a1)+,(a2)+	;save to SRAM 	
	endc

	dbf	d0,.txcopy
	swap	d4

	;---------------- wait on last frame ----------------------------------
	move	#200,d3
.txwait:
	READREG	ECON1,a0,d1
	and.w	#ECON1_TXRTS,d1
	beq.s	.txrdy
	;100 MBit/s frame time is max. 0.12 ms (without inter-frame spacing)

	;wait 20 us via CIA
	moveq	#120,d0
	bsr	_enc624j6l_UMinDelay
	dbf	d3,.txwait		;approx. 4ms max. wait

	;hmpf. abort last transmission
	move	#ECON1_TXRTS,d1		;
	CLRREG	ECON1,a0,d1		;

.txrdy:
	;----------------- set new frame parameters ---------------------------

	WRITEREG	ETXST,a0,d2		;set new TX pointer
	WRITEREG	ETXLEN,a0,d4		;set TX length

	move	#ECON1_TXRTS,d1		;issue "send" command on ENC chip
	SETREG	ECON1,a0,d1		;

.err:
	movem.l	(sp)+,d2-d4/a2
	rts

	ifne	_OPT_CHECKLINK_TX
		;branch here for link change events and adjust parameters in case
.linkchg:
		movem.l	d0-d1/a0-a1,-(sp)
		bsr	_enc624j6l_CheckLinkChange
		movem.l	(sp)+,d0-d1/a0-a1
		bra.s	.linkchgdone

	endc

;------------------------------------------------------------------------------------------------
;------------------------------------------------------------------------------------------------
;
; Generic HW independent functions
;
;------------------------------------------------------------------------------------------------
;------------------------------------------------------------------------------------------------

;
;delay at least D0 microseconds (<= $0fffffff or ~268.000.000)
;
; Important:
;  No guarantee can be given right now by how much the given delay time is exceeded.
;  All this function tries to achieve is to wait long enough in order to meet certain 
;  mimimal hardware delay requirements
;
; Notes: 
;  clipping/saturation of input argument included
; 
;Input:  D0 = delay in microseconds
;
;Output: void
;
_enc624j6l_UMinDelay:
	movem.l	d0/d1,-(sp)

	moveq	#-1,d1
	lsr.l	#4,d1		;$0fffffff
	cmp.l	d1,d0
	blo.s	.ok		;unsigned compare
	move.l	d1,d0		;268 seconds
.ok
	lsl.l	#3,d0		;us * 8

	moveq	#12,d1		;1.5
.loop
	eor.b	#7,d1		;switch between 12/8 and 11/8 -> 1.4375 effective count per CIA access
	tst.b	$BFE301		;1 CIA access = 1.4 us
	sub.l	d1,d0		;us*8 - (1.5 or 1.375)*8
	bgt.s	.loop

	movem.l	(sp)+,d0/d1
	rts

;debug: collect packet positions
;recvptr:	dc.l	recvlist
;recvcount:	dc.l	0
;recvlist:	ds.w	65536

	END
