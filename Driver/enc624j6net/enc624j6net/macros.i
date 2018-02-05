; ------------------------------------------------------------------------------
; | Lowlevel Access to memory mapped ENC624J600 in PSP mode                    |
; | Henryk Richter <henryk.richter@gmx.net>                                    |
; ------------------------------------------------------------------------------
; macro section

;------------------ options, some depend on hardware (CPLD) configuration -------------------------
_OPT_BUFFER_SWAP	EQU	0	;perform byte swap on buffer ops (1) or assume native endian (0)
_OPT_REG_SWAP		EQU	0	;perform byte swap on register ops (1) or assume native endian (0)
_OPT_ADR_QUIRK		EQU	0	;address lines 12/13 are swapped (1) or linear addressing (0)
_OPT_FLOWCONTROL	EQU	0	;perform flow control on RX (1) or not (0)
_OPT_RECV		EQU	1	;faster recv (1) or generic (0)

;\1 register offset (without CLEAR offset)
;\2 address register of board I/O base
;\3 register with clear mask
	ifne	_OPT_REG_SWAP

CLRREG	macro	
	rol.w	#8,\3
	move.w	\3,\1+CLR_OFFSET(\2)
	rol.w	#8,\3
	endm
;\1 register offset (without SET offset)
;\2 address register of board I/O base
;\3 register with set mask
SETREG	macro
	rol.w	#8,\3
	move.w	\3,\1+SET_OFFSET(\2)
	rol.w	#8,\3
	endm
;\1 register offset (e.g. ESTAT)
;\2 address register of board I/O base (e.g. a0)
;\3 destination register to be written (e.g. d0)
READREG	macro
	rol.w	#8,\3
	move.w	\1(\2),\3
	rol.w	#8,\3
	endm
;\1 register offset (e.g. ESTAT)
;\2 address register of board I/O base (e.g. a0)
;\3 soure register copied to HW register (e.g. d0)
WRITEREG macro
	rol.w	#8,\3
	move.w	\3,\1(\2)
	rol.w	#8,\3
	endm


	else

CLRREG	macro	
	move.w	\3,\1+CLR_OFFSET(\2)
	endm
;\1 register offset (without SET offset)
;\2 address register of board I/O base
;\3 register with set mask
SETREG	macro
	move.w	\3,\1+SET_OFFSET(\2)
	endm
;\1 register offset (e.g. ESTAT)
;\2 address register of board I/O base (e.g. a0)
;\3 destination register to be written (e.g. d0)
READREG	macro
	move.w	\1(\2),\3
	endm
;\1 register offset (e.g. ESTAT)
;\2 address register of board I/O base (e.g. a0)
;\3 soure register copied to HW register (e.g. d0)
WRITEREG macro
	move.w	\3,\1(\2)
	endm

	endc

	;read with address shuffling or direct from SRAM (affects $2000-$5000)
	ifne	_OPT_ADR_QUIRK
;\1 = address register
;\2 = data register, offset
;\3 = destination
READSRAM macro
	eor.w	#$6000,\2
	move.w	(\1,\2.w),\3
	eor.w	#$6000,\2
	endm
	else
READSRAM macro
	move.w	(\1,\2),\3
	endm
	endc

	;read with address shuffling or direct from SRAM (affects $2000-$5000)
	ifne	_OPT_ADR_QUIRK
;\1 = address register
;\2 = data register, offset
;\3 = destination
READSRAM_LONG macro
	eor.w	#$6000,\2
	move.l	(\1,\2.w),\3
	eor.w	#$6000,\2
	endm
	else
READSRAM_LONG macro
	move.l	(\1,\2),\3
	endm
	endc


; wrap position index (in bytes) \1 (data register .w)
;
; if position >RXSTOP_INIT-1
;  position = (position-RXSTOP_INIT+RXSTART_INIT)
; endif
WRAPINDEX macro
	cmp.w	#RXSTOP_INIT&$fffe,\1 ;wrap Dn if beyond buffer
	ble.s	.nowrap\0\@
	add.w	#RXSTART_INIT-RXSTOP_INIT-1,\1
.nowrap\0\@
	endm			