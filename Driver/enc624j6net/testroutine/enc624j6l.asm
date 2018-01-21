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
; HW BUG:
; possible address line mismatch (see RXSTART_INIT)
;  $5000 was set -> frame appears at $3000
;  $4000 was set -> frame appears at $2000
;  $3000 was set -> frame appears at $5000
;  $2000 was set -> frame appears at $4000
;
;TODO:
; - setMAC/getMAC endianess awareness
; - Pattern Matching, MC/MC filtering: Multicast,Broadcast,Unicast(self),MagicPacket,correct CRC,"not me" Unicast
; - _enc624j6l_RXReset -> won't recover from totally unresponsive chip (but exits gracefully)
; - put includes out (for now, self-contained ASM file)
; - RXSTART_INIT = $0c00 -> currently $2000 due to location bug

; enable debugging code block
machine mc68020
DEBUG	EQU	1
;

; FIXME: needs verification
; also: either swap buffer or registers/pointers etc.
_OPT_BUFFER_SWAP	EQU	1	;perform byte swap on buffer ops (1) or assume native endian (0)
_OPT_REG_SWAP		EQU	1	;perform byte swap on register ops (1) or assume native endian (0)
_OPT_ADR_QUIRK		EQU	1	;address lines 12/13 are swapped (1) or linear addressing (0)
_OPT_FLOWCONTROL	EQU	0	;perform flow control on RX (1) or not (0)

;
; options for buffer memory configuration, please reserve some space for private variables
;
PSTART_INIT	EQU	$0BF0	; 16 Bytes private storage for driver
PSTOP_INIT	EQU	$0BFF	; (see below for definitions)

RXSTART_INIT   EQU     $3000  ; start of RX buffer, room for 14 packets
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
PLinkChange	EQU	PSTART_INIT+10	;2 Bytes Link Change (Bit0 used right now)
Punused		EQU	PSTART_INIT+12	;

;------------- TX: double buffering --------------------------------
PSwapTX		EQU	$600		;swap between two TX buffers (one active, one activated after last TX done)
;
;
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

	;transmit/receive functions
	XDEF	_enc624j6l_HaveRecv		;
	XDEF	_enc624j6l_RecvFrame		;
	XDEF	_enc624j6l_TransmitFrame	;

	XDEF	_enc624j6l_IntServer
	XDEF	_enc624j6l_EnableInterrupt
	XDEF	_enc624j6l_DisableInterrupt

	;
	; System includes
	;

	ifnd	_LVOSignal
_LVOSignal	EQU	-324
	endc

	;machine	68020

	section	code,code

;------------------------ UGH! this belongs into a proper .i ------------------------------

; set/clr register offsets
SET_OFFSET	EQU	$0100
CLR_OFFSET	EQU	$0180

; Register definitions

; SPI Bank 0 registers --------
ETXST		EQU    $7E00
ETXSTL		EQU    $7E00
ETXSTH		EQU    $7E01
ETXLEN		EQU    $7E02
ETXLENL		EQU    $7E02
ETXLENH		EQU    $7E03
ERXST		EQU    $7E04
ERXSTL		EQU    $7E04
ERXSTH		EQU    $7E05
ERXTAIL		EQU    $7E06
ERXTAILL	EQU    $7E06
ERXTAILH	EQU    $7E07
ERXHEAD		EQU    $7E08
ERXHEADL	EQU    $7E08
ERXHEADH	EQU    $7E09
EDMAST		EQU    $7E0A
EDMASTL		EQU    $7E0A
EDMASTH		EQU    $7E0B
EDMALEN		EQU    $7E0C
EDMALENL	EQU    $7E0C
EDMALENH	EQU    $7E0D
EDMADST		EQU    $7E0E
EDMADSTL	EQU    $7E0E
EDMADSTH	EQU    $7E0F
EDMACS		EQU    $7E10
EDMACSL		EQU    $7E10
EDMACSH		EQU    $7E11
ETXSTAT		EQU    $7E12
ETXSTATL	EQU    $7E12
ETXSTATH	EQU    $7E13
ETXWIRE		EQU    $7E14
ETXWIREL	EQU    $7E14
ETXWIREH	EQU    $7E15

; SPI all bank registers
EUDAST		EQU    $7E16
EUDASTL		EQU    $7E16
EUDASTH		EQU    $7E17
EUDAND		EQU    $7E18
EUDANDL		EQU    $7E18
EUDANDH		EQU    $7E19
ESTAT		EQU    $7E1A
ESTATL		EQU    $7E1A
ESTATH		EQU    $7E1B
EIR		EQU    $7E1C
EIRL		EQU    $7E1C
EIRH		EQU    $7E1D
ECON1		EQU    $7E1E
ECON1L		EQU    $7E1E
ECON1H		EQU    $7E1F


; SPI Bank 1 registers -----
EHT1		EQU    $7E20
EHT1L		EQU    $7E20
EHT1H		EQU    $7E21
EHT2		EQU    $7E22
EHT2L		EQU    $7E22
EHT2H		EQU    $7E23
EHT3		EQU    $7E24
EHT3L		EQU    $7E24
EHT3H		EQU    $7E25
EHT4		EQU    $7E26
EHT4L		EQU    $7E26
EHT4H		EQU    $7E27
EPMM1		EQU    $7E28
EPMM1L		EQU    $7E28
EPMM1H		EQU    $7E29
EPMM2		EQU    $7E2A
EPMM2L		EQU    $7E2A
EPMM2H		EQU    $7E2B
EPMM3		EQU    $7E2C
EPMM3L		EQU    $7E2C
EPMM3H		EQU    $7E2D
EPMM4		EQU    $7E2E
EPMM4L		EQU    $7E2E
EPMM4H		EQU    $7E2F
EPMCS		EQU    $7E30
EPMCSL		EQU    $7E30
EPMCSH		EQU    $7E31
EPMO		EQU    $7E32
EPMOL		EQU    $7E32
EPMOH		EQU    $7E33
ERXFCON		EQU    $7E34
ERXFCONL	EQU    $7E34
ERXFCONH	EQU    $7E35

; SPI all bank registers from 0x36 to 0x3F
; SPI Bank 2 registers -----
MACON1		EQU    $7E40
MACON1L		EQU    $7E40
MACON1H		EQU    $7E41
MACON2		EQU    $7E42
MACON2L		EQU    $7E42
MACON2H		EQU    $7E43
MABBIPG		EQU    $7E44
MABBIPGL	EQU    $7E44
MABBIPGH	EQU    $7E45
MAIPG		EQU    $7E46
MAIPGL		EQU    $7E46
MAIPGH		EQU    $7E47
MACLCON		EQU    $7E48
MACLCONL	EQU    $7E48
MACLCONH	EQU    $7E49
MAMXFL		EQU    $7E4A
MAMXFLL		EQU    $7E4A
MAMXFLH		EQU    $7E4B
MICMD		EQU    $7E52
MICMDL		EQU    $7E52
MICMDH		EQU    $7E53
MIREGADR	EQU    $7E54
MIREGADRL	EQU    $7E54
MIREGADRH	EQU    $7E55

; SPI all bank registers from 0x56 to 0x5F
; SPI Bank 3 registers -----
MAADR3		EQU    $7E60
MAADR3L		EQU    $7E60
MAADR3H		EQU    $7E61
MAADR2		EQU    $7E62
MAADR2L		EQU    $7E62
MAADR2H		EQU    $7E63
MAADR1		EQU    $7E64
MAADR1L		EQU    $7E64
MAADR1H		EQU    $7E65
MIWR		EQU    $7E66
MIWRL		EQU    $7E66
MIWRH		EQU    $7E67
MIRD		EQU    $7E68
MIRDL		EQU    $7E68
MIRDH		EQU    $7E69
MISTAT		EQU    $7E6A
MISTATL		EQU    $7E6A
MISTATH		EQU    $7E6B
EPAUS		EQU    $7E6C
EPAUSL		EQU    $7E6C
EPAUSH		EQU    $7E6D
ECON2		EQU    $7E6E
ECON2L		EQU    $7E6E
ECON2H		EQU    $7E6F
ERXWM		EQU    $7E70
ERXWML		EQU    $7E70
ERXWMH		EQU    $7E71
EIE		EQU    $7E72
EIEL		EQU    $7E72
EIEH		EQU    $7E73
EIDLED		EQU    $7E74
EIDLEDL		EQU    $7E74
EIDLEDH		EQU    $7E75

; SPI all bank registers from 0x66 to 0x6F

; SPI Non-banked Special Function Registers
EGPDATA		EQU    $7E80
EGPDATAL	EQU    $7E80
ERXDATA		EQU    $7E82
ERXDATAL	EQU    $7E82
EUDADATA	EQU    $7E84
EUDADATAL	EQU    $7E84
EGPRDPT		EQU    $7E86
EGPRDPTL	EQU    $7E86
EGPRDPTH	EQU    $7E87
EGPWRPT		EQU    $7E88
EGPWRPTL	EQU    $7E88
EGPWRPTH	EQU    $7E89
ERXRDPT		EQU    $7E8A
ERXRDPTL	EQU    $7E8A
ERXRDPTH	EQU    $7E8B
ERXWRPT		EQU    $7E8C
ERXWRPTL	EQU    $7E8C
ERXWRPTH	EQU    $7E8D
EUDARDPT	EQU    $7E8E
EUDARDPTL	EQU    $7E8E
EUDARDPTH	EQU    $7E8F
EUDAWRPT	EQU    $7E90
EUDAWRPTL	EQU    $7E90
EUDAWRPTH	EQU    $7E91

;;;;;;;;;;;;;;;;;;;;;;;;;;
; ENC424J600/624J600 register bits
;;;;;;;;;;;;;;;;;;;;;;;;;;
; ESTAT bits ----------
ESTAT_INT		EQU    (1<<15)
ESTAT_FCIDLE	EQU    (1<<14)
ESTAT_RXBUSY	EQU    (1<<13)
ESTAT_CLKRDY	EQU    (1<<12)
ESTAT_RSTDONE	EQU    (1<<11)
ESTAT_PHYDPX	EQU    (1<<10)
ESTAT_PHYRDY	EQU    (1<<9)
ESTAT_PHYLNK	EQU    (1<<8)
ESTAT_PKTCNT7	EQU    (1<<7)
ESTAT_PKTCNT6	EQU    (1<<6)
ESTAT_PKTCNT5	EQU    (1<<5)
ESTAT_PKTCNT4	EQU    (1<<4)
ESTAT_PKTCNT3	EQU    (1<<3)
ESTAT_PKTCNT2	EQU    (1<<2)
ESTAT_PKTCNT1	EQU    (1<<1)
ESTAT_PKTCNT0	EQU    (1)

; EIR bits ------------
EIR_CRYPTEN		EQU    (1<<15)
EIR_MODEXIF		EQU    (1<<14)
EIR_HASHIF		EQU    (1<<13)
EIR_AESIF		EQU    (1<<12)
EIR_LINKIF		EQU    (1<<11)
EIR_PRDYIF		EQU    (1<<10)
EIR_r9			EQU    (1<<9)
EIR_r8			EQU    (1<<8)
EIR_r7			EQU    (1<<7)
EIR_PKTIF		EQU    (1<<6)
EIR_DMAIF		EQU    (1<<5)
EIR_r4			EQU    (1<<4)
EIR_TXIF		EQU    (1<<3)
EIR_TXABTIF		EQU    (1<<2)
EIR_RXABTIF		EQU    (1<<1)
EIR_PCFULIF		EQU    (1)

; ECON1 bits ----------
ECON1_MODEXST	EQU    (1<<15)
ECON1_HASHEN	EQU    (1<<14)
ECON1_HASHOP	EQU    (1<<13)
ECON1_HASHLST	EQU    (1<<12)
ECON1_AESST		EQU    (1<<11)
ECON1_AESOP1	EQU    (1<<10)
ECON1_AESOP0	EQU    (1<<9)
ECON1_PKTDEC	EQU    (1<<8)
ECON1_FCOP1		EQU    (1<<7)
ECON1_FCOP0		EQU    (1<<6)
ECON1_DMAST		EQU    (1<<5)
ECON1_DMACPY	EQU    (1<<4)
ECON1_DMACSSD	EQU    (1<<3)
ECON1_DMANOCS	EQU    (1<<2)
ECON1_TXRTS		EQU    (1<<1)
ECON1_RXEN		EQU    (1)

; ETXSTAT bits --------
ETXSTAT_r12		EQU    (1<<12)
ETXSTAT_r11		EQU    (1<<11)
ETXSTAT_LATECOL	EQU    (1<<10)
ETXSTAT_MAXCOL	EQU    (1<<9)
ETXSTAT_EXDEFER	EQU    (1<<8)
ETXSTAT_DEFER	EQU    (1<<7)
ETXSTAT_r6		EQU    (1<<6)
ETXSTAT_r5		EQU    (1<<5)
ETXSTAT_CRCBAD	EQU    (1<<4)
ETXSTAT_COLCNT3 EQU    (1<<3)
ETXSTAT_COLCNT2 EQU    (1<<2)
ETXSTAT_COLCNT1 EQU    (1<<1)
ETXSTAT_COLCNT0 EQU    (1)

; ERXFCON bits --------
ERXFCON_HTEN	EQU    (1<<15)
ERXFCON_MPEN	EQU    (1<<14)
ERXFCON_NOTPM	EQU    (1<<12)
ERXFCON_PMEN3	EQU    (1<<11)
ERXFCON_PMEN2	EQU    (1<<10)
ERXFCON_PMEN1	EQU    (1<<9)
ERXFCON_PMEN0	EQU    (1<<8)
ERXFCON_CRCEEN	EQU    (1<<7)
ERXFCON_CRCEN	EQU    (1<<6)
ERXFCON_RUNTEEN	EQU    (1<<5)
ERXFCON_RUNTEN	EQU    (1<<4)
ERXFCON_UCEN	EQU    (1<<3)
ERXFCON_NOTMEEN	EQU    (1<<2)
ERXFCON_MCEN	EQU    (1<<1)
ERXFCON_BCEN	EQU    (1)

; MACON1 bits ---------
MACON1_r15		EQU    (1<<15)
MACON1_r14		EQU    (1<<14)
MACON1_r11		EQU    (1<<11)
MACON1_r10		EQU    (1<<10)
MACON1_r9		EQU    (1<<9)
MACON1_r8		EQU    (1<<8)
MACON1_LOOPBK	EQU    (1<<4)
MACON1_r3		EQU    (1<<3)
MACON1_RXPAUS	EQU    (1<<2)
MACON1_PASSALL	EQU    (1<<1)
MACON1_r0		EQU    (1)

; MACON2 bits ---------
MACON2_DEFER	EQU    (1<<14)
MACON2_BPEN		EQU    (1<<13)
MACON2_NOBKOFF	EQU    (1<<12)
MACON2_r9		EQU    (1<<9)
MACON2_r8		EQU    (1<<8)
MACON2_PADCFG2	EQU    (1<<7)
MACON2_PADCFG1	EQU    (1<<6)
MACON2_PADCFG0	EQU    (1<<5)
MACON2_TXCRCEN	EQU    (1<<4)
MACON2_PHDREN	EQU    (1<<3)
MACON2_HFRMEN	EQU    (1<<2)
MACON2_r1		EQU    (1<<1)
MACON2_FULDPX	EQU    (1)

; MABBIPG bits --------
MABBIPG_BBIPG6  EQU    (1<<6)
MABBIPG_BBIPG5  EQU    (1<<5)
MABBIPG_BBIPG4  EQU    (1<<4)
MABBIPG_BBIPG3  EQU    (1<<3)
MABBIPG_BBIPG2  EQU    (1<<2)
MABBIPG_BBIPG1  EQU    (1<<1)
MABBIPG_BBIPG0  EQU    (1)

; MAIPG bits ----------
MAIPG_r14		EQU    (1<<14)
MAIPG_r13		EQU    (1<<13)
MAIPG_r12		EQU    (1<<12)
MAIPG_r11		EQU    (1<<11)
MAIPG_r10		EQU    (1<<10)
MAIPG_r9		EQU    (1<<9)
MAIPG_r8		EQU    (1<<8)
MAIPG_IPG6		EQU    (1<<6)
MAIPG_IPG5		EQU    (1<<5)
MAIPG_IPG4		EQU    (1<<4)
MAIPG_IPG3		EQU    (1<<3)
MAIPG_IPG2		EQU    (1<<2)
MAIPG_IPG1		EQU    (1<<1)
MAIPG_IPG0		EQU    (1)

; MACLCON bits --------
MACLCON_r13		EQU    (1<<13)
MACLCON_r12		EQU    (1<<12)
MACLCON_r11		EQU    (1<<11)
MACLCON_r10		EQU    (1<<10)
MACLCON_r9		EQU    (1<<9)
MACLCON_r8		EQU    (1<<8)
MACLCON_MAXRET3	EQU    (1<<3)
MACLCON_MAXRET2	EQU    (1<<2)
MACLCON_MAXRET1	EQU    (1<<1)
MACLCON_MAXRET0	EQU    (1)

; MICMD bits ----------
MICMD_MIISCAN	EQU    (1<<1)
MICMD_MIIRD		EQU    (1)

; MIREGADR bits -------
MIREGADR_r12	EQU    (1<<12)
MIREGADR_r11	EQU    (1<<11)
MIREGADR_r10	EQU    (1<<10)
MIREGADR_r9		EQU    (1<<9)
MIREGADR_r8		EQU    (1<<8)
MIREGADR_PHREG4	EQU    (1<<4)
MIREGADR_PHREG3	EQU    (1<<3)
MIREGADR_PHREG2	EQU    (1<<2)
MIREGADR_PHREG1	EQU    (1<<1)
MIREGADR_PHREG0	EQU    (1)

; MISTAT bits ---------
MISTAT_r3		EQU    (1<<3)
MISTAT_NVALID	EQU    (1<<2)
MISTAT_SCAN		EQU    (1<<1)
MISTAT_BUSY		EQU    (1)

; ECON2 bits ----------
ECON2_ETHEN		EQU    (1<<15)
ECON2_STRCH		EQU    (1<<14)
ECON2_TXMAC		EQU    (1<<13)
ECON2_SHA1MD5	EQU    (1<<12)
ECON2_COCON3	EQU    (1<<11)
ECON2_COCON2	EQU    (1<<10)
ECON2_COCON1	EQU    (1<<9)
ECON2_COCON0	EQU    (1<<8)
ECON2_AUTOFC	EQU    (1<<7)
ECON2_TXRST		EQU    (1<<6)
ECON2_RXRST		EQU    (1<<5)
ECON2_ETHRST	EQU    (1<<4)
ECON2_MODLEN1	EQU    (1<<3)
ECON2_MODLEN0	EQU    (1<<2)
ECON2_AESLEN1	EQU    (1<<1)
ECON2_AESLEN0	EQU    (1)

; ERXWM bits ----------
ERXWM_RXFWM7	EQU    (1<<15)
ERXWM_RXFWM6	EQU    (1<<14)
ERXWM_RXFWM5	EQU    (1<<13)
ERXWM_RXFWM4	EQU    (1<<12)
ERXWM_RXFWM3	EQU    (1<<11)
ERXWM_RXFWM2	EQU    (1<<10)
ERXWM_RXFWM1	EQU    (1<<9)
ERXWM_RXFWM0	EQU    (1<<8)
ERXWM_RXEWM7	EQU    (1<<7)
ERXWM_RXEWM6	EQU    (1<<6)
ERXWM_RXEWM5	EQU    (1<<5)
ERXWM_RXEWM4	EQU    (1<<4)
ERXWM_RXEWM3	EQU    (1<<3)
ERXWM_RXEWM2	EQU    (1<<2)
ERXWM_RXEWM1	EQU    (1<<1)
ERXWM_RXEWM0	EQU    (1)

; EIE bits ------------
EIE_INTIE		EQU    (1<<15)
EIE_MODEXIE		EQU    (1<<14)
EIE_HASHIE		EQU    (1<<13)
EIE_AESIE		EQU    (1<<12)
EIE_LINKIE		EQU    (1<<11)
EIE_PRDYIE		EQU    (1<<10)
EIE_r9			EQU    (1<<9)
EIE_r8			EQU    (1<<8)
EIE_r7			EQU    (1<<7)
EIE_PKTIE		EQU    (1<<6)
EIE_DMAIE		EQU    (1<<5)
EIE_r4			EQU    (1<<4)
EIE_TXIE		EQU    (1<<3)
EIE_TXABTIE		EQU    (1<<2)
EIE_RXABTIE		EQU    (1<<1)
EIE_PCFULIE		EQU    (1)

; EIDLED bits ---------
EIDLED_LACFG3	EQU    (1<<15)
EIDLED_LACFG2	EQU    (1<<14)
EIDLED_LACFG1	EQU    (1<<13)
EIDLED_LACFG0	EQU    (1<<12)
EIDLED_LBCFG3	EQU    (1<<11)
EIDLED_LBCFG2	EQU    (1<<10)
EIDLED_LBCFG1	EQU    (1<<9)
EIDLED_LBCFG0	EQU    (1<<8)
EIDLED_DEVID2	EQU    (1<<7)
EIDLED_DEVID1	EQU    (1<<6)
EIDLED_DEVID0	EQU    (1<<5)
EIDLED_REVID4	EQU    (1<<4)
EIDLED_REVID3	EQU    (1<<3)
EIDLED_REVID2	EQU    (1<<2)
EIDLED_REVID1	EQU    (1<<1)
EIDLED_REVID0	EQU    (1)

; PHCON1 bits ---------
PHCON1_PRST		EQU    (1<<15)
PHCON1_PLOOPBK	EQU    (1<<14)
PHCON1_SPD100	EQU    (1<<13)
PHCON1_ANEN		EQU    (1<<12)
PHCON1_PSLEEP	EQU    (1<<11)
PHCON1_r10		EQU    (1<<10)
PHCON1_RENEG	EQU    (1<<9)
PHCON1_PFULDPX	EQU    (1<<8)
PHCON1_r7		EQU    (1<<7)
PHCON1_r6		EQU    (1<<6)
PHCON1_r5		EQU    (1<<5)
PHCON1_r4		EQU    (1<<4)
PHCON1_r3		EQU    (1<<3)
PHCON1_r2		EQU    (1<<2)
PHCON1_r1		EQU    (1<<1)
PHCON1_r0		EQU    (1)

; PHSTAT1 bits --------
PHSTAT1_r15		EQU    (1<<15)
PHSTAT1_FULL100	EQU    (1<<14)
PHSTAT1_HALF100	EQU    (1<<13)
PHSTAT1_FULL10	EQU    (1<<12)
PHSTAT1_HALF10	EQU    (1<<11)
PHSTAT1_r10		EQU    (1<<10)
PHSTAT1_r9		EQU    (1<<9)
PHSTAT1_r8		EQU    (1<<8)
PHSTAT1_r7		EQU    (1<<7)
PHSTAT1_r6		EQU    (1<<6)
PHSTAT1_ANDONE	EQU    (1<<5)
PHSTAT1_LRFAULT	EQU    (1<<4)
PHSTAT1_ANABLE	EQU    (1<<3)
PHSTAT1_LLSTAT	EQU    (1<<2)
PHSTAT1_r1		EQU    (1<<1)
PHSTAT1_EXTREGS	EQU    (1)

; PHANA bits ----------
PHANA_ADNP		EQU    (1<<15)
PHANA_r14		EQU    (1<<14)
PHANA_ADFAULT	EQU    (1<<13)
PHANA_r12		EQU    (1<<12)
PHANA_ADPAUS1	EQU    (1<<11)
PHANA_ADPAUS0	EQU    (1<<10)
PHANA_r9		EQU    (1<<9)
PHANA_AD100FD	EQU    (1<<8)
PHANA_AD100		EQU    (1<<7)
PHANA_AD10FD	EQU    (1<<6)
PHANA_AD10		EQU    (1<<5)
PHANA_ADIEEE4	EQU    (1<<4)
PHANA_ADIEEE3	EQU    (1<<3)
PHANA_ADIEEE2	EQU    (1<<2)
PHANA_ADIEEE1	EQU    (1<<1)
PHANA_ADIEEE0	EQU    (1)

; PHANLPA bits --------
PHANLPA_LPNP	EQU    (1<<15)
PHANLPA_LPACK	EQU    (1<<14)
PHANLPA_LPFAULT	EQU    (1<<13)
PHANLPA_r12		EQU    (1<<12)
PHANLPA_LPPAUS1	EQU    (1<<11)
PHANLPA_LPPAUS0	EQU    (1<<10)
PHANLPA_LP100T4	EQU    (1<<9)
PHANLPA_LP100FD	EQU    (1<<8)
PHANLPA_LP100	EQU    (1<<7)
PHANLPA_LP10FD	EQU    (1<<6)
PHANLPA_LP10	EQU    (1<<5)
PHANLPA_LPIEEE4	EQU    (1<<4)
PHANLPA_LPIEEE3	EQU    (1<<3)
PHANLPA_LPIEEE2	EQU    (1<<2)
PHANLPA_LPIEEE1	EQU    (1<<1)
PHANLPA_LPIEEE0	EQU    (1)

; PHANE bits ----------
PHANE_r15		EQU    (1<<15)
PHANE_r14		EQU    (1<<14)
PHANE_r13		EQU    (1<<13)
PHANE_r12		EQU    (1<<12)
PHANE_r11		EQU    (1<<11)
PHANE_r10		EQU    (1<<10)
PHANE_r9		EQU    (1<<9)
PHANE_r8		EQU    (1<<8)
PHANE_r7		EQU    (1<<7)
PHANE_r6		EQU    (1<<6)
PHANE_r5		EQU    (1<<5)
PHANE_PDFLT		EQU    (1<<4)
PHANE_r3		EQU    (1<<3)
PHANE_r2		EQU    (1<<2)
PHANE_LPARCD	EQU    (1<<1)
PHANA_LPANABL	EQU    (1)

; PHCON2 bits ---------
PHCON2_r15		EQU    (1<<15)
PHCON2_r14		EQU    (1<<14)
PHCON2_EDPWRDN	EQU    (1<<13)
PHCON2_r12		EQU    (1<<12)
PHCON2_EDTHRES	EQU    (1<<11)
PHCON2_r10		EQU    (1<<10)
PHCON2_r9		EQU    (1<<9)
PHCON2_r8		EQU    (1<<8)
PHCON2_r7		EQU    (1<<7)
PHCON2_r6		EQU    (1<<6)
PHCON2_r5		EQU    (1<<5)
PHCON2_r4		EQU    (1<<4)
PHCON2_r3		EQU    (1<<3)
PHCON2_FRCLNK	EQU    (1<<2)
PHCON2_EDSTAT	EQU    (1<<1)
PHCON2_r0		EQU    (1)

; PHSTAT2 bits ---------
PHSTAT2_r15		EQU    (1<<15)
PHSTAT2_r14		EQU    (1<<14)
PHSTAT2_r13		EQU    (1<<13)
PHSTAT2_r12		EQU    (1<<12)
PHSTAT2_r11		EQU    (1<<11)
PHSTAT2_r10		EQU    (1<<10)
PHSTAT2_r9		EQU    (1<<9)
PHSTAT2_r8		EQU    (1<<8)
PHSTAT2_r7		EQU    (1<<7)
PHSTAT2_r6		EQU    (1<<6)
PHSTAT2_r5		EQU    (1<<5)
PHSTAT2_PLRITY	EQU    (1<<4)
PHSTAT2_r3		EQU    (1<<3)
PHSTAT2_r2		EQU    (1<<2)
PHSTAT2_r1		EQU    (1<<1)
PHSTAT2_r0		EQU    (1)

; PHSTAT3 bits --------
PHSTAT3_r15		EQU    (1<<15)
PHSTAT3_r14		EQU    (1<<14)
PHSTAT3_r13		EQU    (1<<13)
PHSTAT3_r12		EQU    (1<<12)
PHSTAT3_r11		EQU    (1<<11)
PHSTAT3_r10		EQU    (1<<10)
PHSTAT3_r9		EQU    (1<<9)
PHSTAT3_r8		EQU    (1<<8)
PHSTAT3_r7		EQU    (1<<7)
PHSTAT3_r6		EQU    (1<<6)
PHSTAT3_r5		EQU    (1<<5)
PHSTAT3_SPDDPX2	EQU    (1<<4)
PHSTAT3_SPDDPX1	EQU    (1<<3)
PHSTAT3_SPDDPX0	EQU    (1<<2)
PHSTAT3_r1		EQU    (1<<1)
PHSTAT3_r0		EQU    (1)

;------------------------------ internal defaults ----------------------------------
;33.333Mhz clock out frequency
CLOCK_33_CLR	EQU	(ECON2_COCON3|ECON2_COCON2|ECON2_COCON1)	;clr mask
CLOCK_33_SET	EQU	(ECON2_COCON0)					;set mask
;25 MHz
CLOCK_25_CLR	EQU	(ECON2_COCON3|ECON2_COCON2|ECON2_COCON0)	;clr mask
CLOCK_25_SET	EQU	(ECON2_COCON1)					;set mask
;20 MHz
CLOCK_20_CLR	EQU	(ECON2_COCON3|ECON2_COCON2)			;clr mask
CLOCK_20_SET	EQU	(ECON2_COCON1|ECON2_COCON0)			;set mask
;16 MHz
CLOCK_16_CLR	EQU	(ECON2_COCON3|ECON2_COCON0|ECON2_COCON1)	;clr mask
CLOCK_16_SET	EQU	(ECON2_COCON2)					;set mask
;4 MHz (after reset)
CLOCK_4_CLR	EQU	(ECON2_COCON2)					;clr mask
CLOCK_4_SET	EQU	(ECON2_COCON3|ECON2_COCON0|ECON2_COCON1)	;set mask

CLOCK_DEF_CLR	EQU	CLOCK_33_CLR
CLOCK_DEF_SET	EQU	CLOCK_33_SET

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


; wrap position index (in bytes) \1 (data register .w)
;
; if position >RXSTOP_INIT-1
;  position = (position-RXSTOP_INIT+RXSTART_INIT)
; endif
WRAPINDEX macro
	cmp.w	#RXSTOP_INIT&$fffe,\1 ;wrap Dn if beyond buffer
	ble.s	.nowrap\0\@
	add.w	#RXSTART_INIT-RXSTOP_INIT,\1
.nowrap\0\@
	endm			





; -----------------------------------------------------------------------------
; |                                                                           |
; | Test/Debug code                                                           |
; |                                                                           |
; -----------------------------------------------------------------------------
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
	move.w	#CLOCK_DEF_SET,d1	;set mask
	CLRREG	ECON2,a0,d0
	SETREG	ECON2,a0,d1

	; disable crypto engine and all interrupts
	move	#EIR_CRYPTEN|EIR_MODEXIF|EIR_HASHIF|EIR_AESIF|EIR_LINKIF|EIR_PRDYIF|EIR_PKTIF|EIR_DMAIF|EIR_TXIF|EIR_TXABTIF|EIR_RXABTIF|EIR_PCFULIF,d0
	CLRREG	EIR,a0,d0

	;--------------- RX configuration -----------------------
	move	#RXSTART_INIT,d0
	WRITEREG ERXST,a0,d0		;set RX start pointer (end will be $5fff)
	WRITEREG PNextPacket,a0,d0	;set user read pointer

	;Multicast,Broadcast,Unicast(self),MagicPacket,correct CRC,filter runts
	;"not me" Unicast == |ERXFCON_NOTMEEN
	move	#ERXFCON_MCEN|ERXFCON_BCEN|ERXFCON_UCEN|ERXFCON_MPEN|ERXFCON_CRCEN|ERXFCON_RUNTEN,d0
	WRITEREG ERXFCON,a0,d0 ;set filter TODO: pattern matching stuff
	move	#RXSTOP_INIT&$fffe,d0
	WRITEREG ERXTAIL,a0,d0 ;tail pointer in buffer = rx-2, wraparound

	ifne	_OPT_FLOWCONTROL
	 move	#(128<<8)|(32),d0	;128*96=12288 high water mark, 32*96=3072 low water mark
	 WRITEREG ERXWM,a0,d0
	 moveq	#MACON1_RXPAUS,d0
	 SETREG	MACON1,a0,d0
	 move	#ECON2_AUTOFC,d0
	 SETREG	ECON2,a0,d0
	else
	 move	#ECON2_AUTOFC,d0
	 CLRREG	ECON2,a0,d0		;disable automatic flow control
	endc


	;--------------- TX configuration -----------------------
	; no padding, no proprietary header
	move	#MACON2_PADCFG2|MACON2_PADCFG1|MACON2_PADCFG0|MACON2_PHDREN,d0
	CLRREG	MACON2,a0,d0
	; add CRC by ENC Chip
	move	#MACON2_PADCFG1|MACON2_PADCFG0|MACON2_TXCRCEN,d0
	SETREG	MACON2,a0,d0
	
	move	#MAX_FRAMELEN,d0
	WRITEREG MAMXFL,a0,d0	;set maximum frame length
	moveq	#0,d0
	WRITEREG PNextTX,a0,d0	;private pointer, "last written, maybe still pending frame"


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

	moveq	#1,d0
	WRITEREG PLinkChange,a0,d0
	
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
	move.w	d0,($4002.l,a0)
	lea	-$4000(a0),a0
	;WRITEREG $8002,a0,d0		;only with this "sesame"

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
	and		d1,d0
	beq.s	.rts				;exit quickly when no packet pending
	;CLRREG	EIR,a1,d1			;clear interrupt bit
	
	READREG	PSigTask,a1,d0     ;upper two bytes
	swap	d0	;
	READREG	PSigTask+2,a1,d0   ;lower two bytes
	tst.l	d0					; no task ?
	beq.s	.rts
	move.l	d0,a0				; signaled task

	moveq	#0,d0
	READREG		PSigBit,a1,d1	;get signal bit
	bset	d1,d0				;signal mask
	move.l	a0,a1				;task

	move.l	4.w,a6
	jsr		_LVOSignal(a6)

.rts
	moveq	#0,d0		;set Z flag
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

	and.w	#$f800,d0		;verify (should be all zeros in upper 9 bits)
	bne	.recv_err		;receive buffer is wrong -> re-initialize

	addq.w	#4,d7			;increment pointer
	WRAPINDEX d7			;wrap D7 if beyond buffer
	;lea	(a0,d7.w),a2		;new read pointer for length
	;READREG 0,a2,d0		;last control word = length (byte count)
	READSRAM a0,d7,d0		;move (a0,d7.w),d0

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

	;generic loop: check for position overflows with each word
	move	d0,d1			;byte count
	lsr	#1,d1			;converted to word count
	bcs.s	.generic_read		;read 1 byte more if impair byte count
	subq	#1,d1			;words - 1
.generic_read:
	READSRAM a0,d7,d2		;get current word
	;move	(a0,d7.w),d2		;get current word
	addq	#2,d7			;increment position
	ifne	_OPT_BUFFER_SWAP
	 rol.w	#8,d2			;swap buffer to Big Endian
	endc
	WRAPINDEX d7			;wrap D7 if beyond buffer
	move	d2,(a1)+
	dbf	d1,.generic_read

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

	READREG PLinkChange,a0,d1
	tst	d1
	beq	.linkup
	; link up and configured

	READREG ESTAT,a0,d1	;Bit 10 is FULL DUPLEX (ESTAT_PHYDPX)
	bfextu	d1{21:1},d1	;get Bit 10 to Bit 0  (MACON2_FULDPX)
	READREG	MACON2,a0,d2
	bclr	#0,d2		;clear FDX bit
	or.l	d1,d2		;set if active
	WRITEREG MACON2,a0,d2

	moveq	#$12,d1		;half duplex $12
	btst	#0,d2
	beq.s	.nofdx
	moveq	#$15,d1		;full duplex $15
.nofdx:
	WRITEREG MABBIPG,a0,d1

	moveq	 #0,d1
	WRITEREG PLinkChange,a0,d1
.linkup:

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
	move.l	(a1)+,d1
	move.l	(a1)+,d3

	ifne	_OPT_BUFFER_SWAP
	 ; byte swap in 16 Bit words
	 rol.w	d4,d1
	 rol.w	d4,d3
	 swap	d1
	 swap	d3
	 rol.w	d4,d1
	 rol.w	d4,d3
	 swap	d1
	 swap	d3
	endc
	move.l	d1,(a2)+	;save to SRAM
	move.l	d3,(a2)+	;save to SRAM

	dbf	d0,.txcopy
	swap	d4

	;---------------- wait on last frame ----------------------------------
	moveq	#100,d3
.txwait:
	READREG	ECON1,a0,d1
	and.w	#ECON1_TXRTS,d1
	beq.s	.txrdy
	;100 MBit/s frame time is max. 0.12 ms (without inter-frame spacing)

	;wait 50 us via CIA
	moveq	#50,d0
	bsr	_enc624j6l_UMinDelay
	dbf	d3,.txwait		;approx. 5ms max. wait

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
