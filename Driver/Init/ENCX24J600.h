/*********************************************************************
 *
 * ENC424J600/624J600 Registers and Bits
 *
 *********************************************************************
 * FileName:        ENCX24J600.h
 * Dependencies:    None
 * Processor:       PIC18, PIC24F, PIC24H, dsPIC30F, dsPIC33F, PIC32
 * Compiler:        Microchip C32 v1.05 or higher
 *					Microchip C30 v3.12 or higher
 *					Microchip C18 v3.30 or higher
 *					HI-TECH PICC-18 PRO 9.63PL2 or higher
 * Company:         Microchip Technology, Inc.
 *
 * Software License Agreement
 *
 * Copyright (C) 2002-2009 Microchip Technology Inc.  All rights
 * reserved.
 *
 * Microchip licenses to you the right to use, modify, copy, and
 * distribute:
 * (i)  the Software when embedded on a Microchip microcontroller or
 *      digital signal controller product ("Device") which is
 *      integrated into Licensee's product; or
 * (ii) ONLY the Software driver source files ENC28J60.c, ENC28J60.h,
 *		ENCX24J600.c and ENCX24J600.h ported to a non-Microchip device
 *		used in conjunction with a Microchip ethernet controller for
 *		the sole purpose of interfacing with the ethernet controller.
 *
 * You should refer to the license agreement accompanying this
 * Software for additional information regarding your rights and
 * obligations.
 *
 * THE SOFTWARE AND DOCUMENTATION ARE PROVIDED "AS IS" WITHOUT
 * WARRANTY OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING WITHOUT
 * LIMITATION, ANY WARRANTY OF MERCHANTABILITY, FITNESS FOR A
 * PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT SHALL
 * MICROCHIP BE LIABLE FOR ANY INCIDENTAL, SPECIAL, INDIRECT OR
 * CONSEQUENTIAL DAMAGES, LOST PROFITS OR LOST DATA, COST OF
 * PROCUREMENT OF SUBSTITUTE GOODS, TECHNOLOGY OR SERVICES, ANY CLAIMS
 * BY THIRD PARTIES (INCLUDING BUT NOT LIMITED TO ANY DEFENSE
 * THEREOF), ANY CLAIMS FOR INDEMNITY OR CONTRIBUTION, OR OTHER
 * SIMILAR COSTS, WHETHER ASSERTED ON THE BASIS OF CONTRACT, TORT
 * (INCLUDING NEGLIGENCE), BREACH OF WARRANTY, OR OTHERWISE.
 *
 *
 * Author               Date        Comment
 *~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 * Howard Schlunder		11/30/07	Original
 ********************************************************************/

#ifndef __ENCX24J600_H
#define __ENCX24J600_H
//#include "GenericTypeDefs.h"
//#include "HardwareProfile.h"

#define ENC100_INTERFACE_MODE			3

// Define macro for 8-bit PSP SFR address translation to SPI addresses
#define ENC100_TRANSLATE_TO_PIN_ADDR(a)		(a)
#define ENC100_RAM_SIZE			(24*1024)

//read/write macros
#define WRITEREG(a,b,c) (*(volatile WORD *)((volatile BYTE *)(a)+(b)))=(WORD)(c)//;printf("Write 0x%x at register 0x%lx\n",(WORD)(c),((volatile BYTE *)(a)+(b)))
#define READREG(a,b)		(*(volatile WORD *)((volatile BYTE *)(a)+(b)))//;printf("Read from register 0x%lx\n",((volatile BYTE *)(a)+(b)))

//set/clear register bit macros
#define SETREG(a,b,c)		(*(volatile WORD *)((volatile BYTE *)(a)+((b)+(SET_OFFSET))))=((WORD)(c))//;printf("Set   register 0x%x at register 0x%lx\n",(WORD)(c),(volatile WORD *)((volatile BYTE *)(a)+((b)+(SET_OFFSET)))); 
#define CLRREG(a,b,c)		(*(volatile WORD *)((volatile BYTE *)(a)+((b)+(CLR_OFFSET))))=((WORD)(c))//;printf("Clear register 0x%x at register 0x%lx\n",(WORD)(c),(volatile WORD *)((volatile BYTE *)(a)+((b)+(CLR_OFFSET))))



// Crypto memory addresses.  These are accessible by the DMA only and therefore 
// have the same addresses no matter what MCU interface is being used (SPI, 
// 8-bit PSP, or 16-bit PSP)
#define ENC100_MODEX_Y			(0x7880)
#define ENC100_MODEX_E			(0x7800)
#define ENC100_MODEX_X			(0x7880)
#define ENC100_MODEX_M			(0x7900)
#define ENC100_HASH_DATA_IN		(0x7A00)
#define ENC100_HASH_IV_IN		(0x7A40)
#define ENC100_HASH_LEN_IN		(0x7A54)
#define ENC100_HASH_DIGEST_OUT	(0x7A70)
#define ENC100_HASH_LEN_OUT		(0x7A84)
#define ENC100_HASH_BASE_ADDR	(0x7A00)
#define ENC100_AES_KEY			(0x7C00)
#define ENC100_AES_TEXTA		(0x7C20)
#define ENC100_AES_TEXTB		(0x7C30)
#define ENC100_AES_XOROUT		(0x7C40)


#define SET_OFFSET			ENC100_TRANSLATE_TO_PIN_ADDR(0x0100)
#define CLR_OFFSET			ENC100_TRANSLATE_TO_PIN_ADDR(0x0180)
	

////////////////////////////////////////////////////
// ENC424J600/624J600 register addresses		  //
////////////////////////////////////////////////////
// SPI Bank 0 registers --------
#define ETXST		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E00)
#define ETXSTL		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E00)
#define ETXSTH		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E01)
#define ETXLEN		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E02)
#define ETXLENL		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E02)
#define ETXLENH		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E03)
#define ERXST		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E04)
#define ERXSTL		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E04)
#define ERXSTH		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E05)
#define ERXTAIL		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E06)
#define ERXTAILL	ENC100_TRANSLATE_TO_PIN_ADDR(0x7E06)
#define ERXTAILH	ENC100_TRANSLATE_TO_PIN_ADDR(0x7E07)
#define ERXHEAD		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E08)
#define ERXHEADL	ENC100_TRANSLATE_TO_PIN_ADDR(0x7E08)
#define ERXHEADH	ENC100_TRANSLATE_TO_PIN_ADDR(0x7E09)
#define EDMAST		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E0A)
#define EDMASTL		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E0A)
#define EDMASTH		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E0B)
#define EDMALEN		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E0C)
#define EDMALENL	ENC100_TRANSLATE_TO_PIN_ADDR(0x7E0C)
#define EDMALENH	ENC100_TRANSLATE_TO_PIN_ADDR(0x7E0D)
#define EDMADST		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E0E)
#define EDMADSTL	ENC100_TRANSLATE_TO_PIN_ADDR(0x7E0E)
#define EDMADSTH	ENC100_TRANSLATE_TO_PIN_ADDR(0x7E0F)
#define EDMACS		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E10)
#define EDMACSL		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E10)
#define EDMACSH		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E11)
#define ETXSTAT		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E12)
#define ETXSTATL	ENC100_TRANSLATE_TO_PIN_ADDR(0x7E12)
#define ETXSTATH	ENC100_TRANSLATE_TO_PIN_ADDR(0x7E13)
#define ETXWIRE		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E14)
#define ETXWIREL	ENC100_TRANSLATE_TO_PIN_ADDR(0x7E14)
#define ETXWIREH	ENC100_TRANSLATE_TO_PIN_ADDR(0x7E15)

// SPI all bank registers
#define EUDAST		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E16)
#define EUDASTL		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E16)
#define EUDASTH		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E17)
#define EUDAND		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E18)
#define EUDANDL		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E18)
#define EUDANDH		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E19)
#define ESTAT		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E1A)
#define ESTATL		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E1A)
#define ESTATH		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E1B)
#define EIR			ENC100_TRANSLATE_TO_PIN_ADDR(0x7E1C)
#define EIRL		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E1C)
#define EIRH		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E1D)
#define ECON1		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E1E)
#define ECON1L		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E1E)
#define ECON1H		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E1F)


// SPI Bank 1 registers -----
#define EHT1		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E20)
#define EHT1L		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E20)
#define EHT1H		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E21)
#define EHT2		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E22)
#define EHT2L		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E22)
#define EHT2H		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E23)
#define EHT3		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E24)
#define EHT3L		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E24)
#define EHT3H		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E25)
#define EHT4		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E26)
#define EHT4L		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E26)
#define EHT4H		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E27)
#define EPMM1		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E28)
#define EPMM1L		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E28)
#define EPMM1H		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E29)
#define EPMM2		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E2A)
#define EPMM2L		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E2A)
#define EPMM2H		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E2B)
#define EPMM3		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E2C)
#define EPMM3L		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E2C)
#define EPMM3H		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E2D)
#define EPMM4		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E2E)
#define EPMM4L		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E2E)
#define EPMM4H		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E2F)
#define EPMCS		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E30)
#define EPMCSL		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E30)
#define EPMCSH		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E31)
#define EPMO		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E32)
#define EPMOL		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E32)
#define EPMOH		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E33)
#define ERXFCON		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E34)
#define ERXFCONL	ENC100_TRANSLATE_TO_PIN_ADDR(0x7E34)
#define ERXFCONH	ENC100_TRANSLATE_TO_PIN_ADDR(0x7E35)

// SPI all bank registers from 0x36 to 0x3F


// SPI Bank 2 registers -----
#define MACON1		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E40)
#define MACON1L		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E40)
#define MACON1H		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E41)
#define MACON2		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E42)
#define MACON2L		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E42)
#define MACON2H		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E43)
#define MABBIPG		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E44)
#define MABBIPGL	ENC100_TRANSLATE_TO_PIN_ADDR(0x7E44)
#define MABBIPGH	ENC100_TRANSLATE_TO_PIN_ADDR(0x7E45)
#define MAIPG		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E46)
#define MAIPGL		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E46)
#define MAIPGH		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E47)
#define MACLCON		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E48)
#define MACLCONL	ENC100_TRANSLATE_TO_PIN_ADDR(0x7E48)
#define MACLCONH	ENC100_TRANSLATE_TO_PIN_ADDR(0x7E49)
#define MAMXFL		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E4A)
#define MAMXFLL		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E4A)
#define MAMXFLH		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E4B)
//#define r			ENC100_TRANSLATE_TO_PIN_ADDR(0x7E4C)
//#define r			ENC100_TRANSLATE_TO_PIN_ADDR(0x7E4D)
//#define r			ENC100_TRANSLATE_TO_PIN_ADDR(0x7E4E)
//#define r			ENC100_TRANSLATE_TO_PIN_ADDR(0x7E4F)
//#define r			ENC100_TRANSLATE_TO_PIN_ADDR(0x7E50)
//#define r			ENC100_TRANSLATE_TO_PIN_ADDR(0x7E51)
#define MICMD		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E52)
#define MICMDL		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E52)
#define MICMDH		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E53)
#define MIREGADR	ENC100_TRANSLATE_TO_PIN_ADDR(0x7E54)
#define MIREGADRL	ENC100_TRANSLATE_TO_PIN_ADDR(0x7E54)
#define MIREGADRH	ENC100_TRANSLATE_TO_PIN_ADDR(0x7E55)

// SPI all bank registers from 0x56 to 0x5F


// SPI Bank 3 registers -----
#define MAADR3		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E60)
#define MAADR3L		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E60)
#define MAADR3H		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E61)
#define MAADR2		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E62)
#define MAADR2L		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E62)
#define MAADR2H		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E63)
#define MAADR1		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E64)
#define MAADR1L		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E64)
#define MAADR1H		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E65)
#define MIWR		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E66)
#define MIWRL		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E66)
#define MIWRH		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E67)
#define MIRD		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E68)
#define MIRDL		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E68)
#define MIRDH		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E69)
#define MISTAT		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E6A)
#define MISTATL		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E6A)
#define MISTATH		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E6B)
#define EPAUS		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E6C)
#define EPAUSL		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E6C)
#define EPAUSH		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E6D)
#define ECON2		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E6E)
#define ECON2L		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E6E)
#define ECON2H		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E6F)
#define ERXWM		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E70)
#define ERXWML		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E70)
#define ERXWMH		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E71)
#define EIE			ENC100_TRANSLATE_TO_PIN_ADDR(0x7E72)
#define EIEL		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E72)
#define EIEH		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E73)
#define EIDLED		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E74)
#define EIDLEDL		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E74)
#define EIDLEDH		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E75)

// SPI all bank registers from 0x66 to 0x6F


// SPI Non-banked Special Function Registers
#define EGPDATA		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E80)
#define EGPDATAL	ENC100_TRANSLATE_TO_PIN_ADDR(0x7E80)
//#define r			ENC100_TRANSLATE_TO_PIN_ADDR(0x7E81)
#define ERXDATA		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E82)
#define ERXDATAL	ENC100_TRANSLATE_TO_PIN_ADDR(0x7E82)
//#define r			ENC100_TRANSLATE_TO_PIN_ADDR(0x7E83)
#define EUDADATA	ENC100_TRANSLATE_TO_PIN_ADDR(0x7E84)
#define EUDADATAL	ENC100_TRANSLATE_TO_PIN_ADDR(0x7E84)
//#define r			ENC100_TRANSLATE_TO_PIN_ADDR(0x7E85)
#define EGPRDPT		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E86)
#define EGPRDPTL	ENC100_TRANSLATE_TO_PIN_ADDR(0x7E86)
#define EGPRDPTH	ENC100_TRANSLATE_TO_PIN_ADDR(0x7E87)
#define EGPWRPT		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E88)
#define EGPWRPTL	ENC100_TRANSLATE_TO_PIN_ADDR(0x7E88)
#define EGPWRPTH	ENC100_TRANSLATE_TO_PIN_ADDR(0x7E89)
#define ERXRDPT		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E8A)
#define ERXRDPTL	ENC100_TRANSLATE_TO_PIN_ADDR(0x7E8A)
#define ERXRDPTH	ENC100_TRANSLATE_TO_PIN_ADDR(0x7E8B)
#define ERXWRPT		ENC100_TRANSLATE_TO_PIN_ADDR(0x7E8C)
#define ERXWRPTL	ENC100_TRANSLATE_TO_PIN_ADDR(0x7E8C)
#define ERXWRPTH	ENC100_TRANSLATE_TO_PIN_ADDR(0x7E8D)
#define EUDARDPT	ENC100_TRANSLATE_TO_PIN_ADDR(0x7E8E)
#define EUDARDPTL	ENC100_TRANSLATE_TO_PIN_ADDR(0x7E8E)
#define EUDARDPTH	ENC100_TRANSLATE_TO_PIN_ADDR(0x7E8F)
#define EUDAWRPT	ENC100_TRANSLATE_TO_PIN_ADDR(0x7E90)
#define EUDAWRPTL	ENC100_TRANSLATE_TO_PIN_ADDR(0x7E90)
#define EUDAWRPTH	ENC100_TRANSLATE_TO_PIN_ADDR(0x7E91)



////////////////////////////////////////////////////
// ENC424J600/624J600 PHY Register Addresses	  //
////////////////////////////////////////////////////
#define PHCON1	0x00
#define PHSTAT1	0x01
#define PHANA	0x04
#define PHANLPA	0x05
#define PHANE	0x06
#define PHCON2	0x11
#define PHSTAT2	0x1B
#define PHSTAT3	0x1F



////////////////////////////////////////////////////
// ENC424J600/624J600 register bits				  //
////////////////////////////////////////////////////
// ESTAT bits ----------
#define ESTAT_INT		((WORD)1<<15)
#define ESTAT_FCIDLE	((WORD)1<<14)
#define ESTAT_RXBUSY	((WORD)1<<13)
#define ESTAT_CLKRDY	((WORD)1<<12)
#define ESTAT_RSTDONE	((WORD)1<<11)
#define ESTAT_PHYDPX	((WORD)1<<10)
#define ESTAT_PHYRDY	((WORD)1<<9)
#define ESTAT_PHYLNK	((WORD)1<<8)
#define ESTAT_PKTCNT7	(1<<7)
#define ESTAT_PKTCNT6	(1<<6)
#define ESTAT_PKTCNT5	(1<<5)
#define ESTAT_PKTCNT4	(1<<4)
#define ESTAT_PKTCNT3	(1<<3)
#define ESTAT_PKTCNT2	(1<<2)
#define ESTAT_PKTCNT1	(1<<1)
#define ESTAT_PKTCNT0	(1)

// EIR bits ------------
#define EIR_CRYPTEN		((WORD)1<<15)
#define EIR_MODEXIF		((WORD)1<<14)
#define EIR_HASHIF		((WORD)1<<13)
#define EIR_AESIF		((WORD)1<<12)
#define EIR_LINKIF		((WORD)1<<11)
#define EIR_PRDYIF		((WORD)1<<10)
#define EIR_r9			((WORD)1<<9)
#define EIR_r8			((WORD)1<<8)
#define EIR_r7			(1<<7)
#define EIR_PKTIF		(1<<6)
#define EIR_DMAIF		(1<<5)
#define EIR_r4			(1<<4)
#define EIR_TXIF		(1<<3)
#define EIR_TXABTIF		(1<<2)
#define EIR_RXABTIF		(1<<1)
#define EIR_PCFULIF		(1)

// ECON1 bits ----------
#define ECON1_MODEXST	((WORD)1<<15)
#define ECON1_HASHEN	((WORD)1<<14)
#define ECON1_HASHOP	((WORD)1<<13)
#define ECON1_HASHLST	((WORD)1<<12)
#define ECON1_AESST		((WORD)1<<11)
#define ECON1_AESOP1	((WORD)1<<10)
#define ECON1_AESOP0	((WORD)1<<9)
#define ECON1_PKTDEC	((WORD)1<<8)
#define ECON1_FCOP1		(1<<7)
#define ECON1_FCOP0		(1<<6)
#define ECON1_DMAST		(1<<5)
#define ECON1_DMACPY	(1<<4)
#define ECON1_DMACSSD	(1<<3)
#define ECON1_DMANOCS	(1<<2)
#define ECON1_TXRTS		(1<<1)
#define ECON1_RXEN		(1)

// ETXSTAT bits --------
#define ETXSTAT_r12		((WORD)1<<12)
#define ETXSTAT_r11		((WORD)1<<11)
#define ETXSTAT_LATECOL	((WORD)1<<10)
#define ETXSTAT_MAXCOL	((WORD)1<<9)
#define ETXSTAT_EXDEFER	((WORD)1<<8)
#define ETXSTAT_DEFER	(1<<7)
#define ETXSTAT_r6		(1<<6)
#define ETXSTAT_r5		(1<<5)
#define ETXSTAT_CRCBAD	(1<<4)
#define ETXSTAT_COLCNT3 (1<<3)
#define ETXSTAT_COLCNT2 (1<<2)
#define ETXSTAT_COLCNT1 (1<<1)
#define ETXSTAT_COLCNT0 (1)

// ERXFCON bits --------
#define ERXFCON_HTEN	((WORD)1<<15)
#define ERXFCON_MPEN	((WORD)1<<14)
#define ERXFCON_NOTPM	((WORD)1<<12)
#define ERXFCON_PMEN3	((WORD)1<<11)
#define ERXFCON_PMEN2	((WORD)1<<10)
#define ERXFCON_PMEN1	((WORD)1<<9)
#define ERXFCON_PMEN0	((WORD)1<<8)
#define ERXFCON_CRCEEN	(1<<7)
#define ERXFCON_CRCEN	(1<<6)
#define ERXFCON_RUNTEEN	(1<<5)
#define ERXFCON_RUNTEN	(1<<4)
#define ERXFCON_UCEN	(1<<3)
#define ERXFCON_NOTMEEN	(1<<2)
#define ERXFCON_MCEN	(1<<1)
#define ERXFCON_BCEN	(1)

// MACON1 bits ---------
#define MACON1_r15		((WORD)1<<15)
#define MACON1_r14		((WORD)1<<14)
#define MACON1_r11		((WORD)1<<11)
#define MACON1_r10		((WORD)1<<10)
#define MACON1_r9		((WORD)1<<9)
#define MACON1_r8		((WORD)1<<8)
#define MACON1_LOOPBK	(1<<4)
#define MACON1_r3		(1<<3)
#define	MACON1_RXPAUS	(1<<2)
#define	MACON1_PASSALL	(1<<1)
#define MACON1_r0		(1)

// MACON2 bits ---------
#define	MACON2_DEFER	((WORD)1<<14)
#define	MACON2_BPEN		((WORD)1<<13)
#define	MACON2_NOBKOFF	((WORD)1<<12)
#define MACON2_r9		((WORD)1<<9)
#define MACON2_r8		((WORD)1<<8)
#define	MACON2_PADCFG2	(1<<7)
#define	MACON2_PADCFG1	(1<<6)
#define	MACON2_PADCFG0	(1<<5)
#define	MACON2_TXCRCEN	(1<<4)
#define	MACON2_PHDREN	(1<<3)
#define	MACON2_HFRMEN	(1<<2)
#define MACON2_r1		(1<<1)
#define	MACON2_FULDPX	(1)

// MABBIPG bits --------
#define MABBIPG_BBIPG6  (1<<6)
#define MABBIPG_BBIPG5  (1<<5)
#define MABBIPG_BBIPG4  (1<<4)
#define MABBIPG_BBIPG3  (1<<3)
#define MABBIPG_BBIPG2  (1<<2)
#define MABBIPG_BBIPG1  (1<<1)
#define MABBIPG_BBIPG0  (1)

// MAIPG bits ----------
#define MAIPG_r14		((WORD)1<<14)
#define MAIPG_r13		((WORD)1<<13)
#define MAIPG_r12		((WORD)1<<12)
#define MAIPG_r11		((WORD)1<<11)
#define MAIPG_r10		((WORD)1<<10)
#define MAIPG_r9		((WORD)1<<9)
#define MAIPG_r8		((WORD)1<<8)
#define MAIPG_IPG6		(1<<6)
#define MAIPG_IPG5		(1<<5)
#define MAIPG_IPG4		(1<<4)
#define MAIPG_IPG3		(1<<3)
#define MAIPG_IPG2		(1<<2)
#define MAIPG_IPG1		(1<<1)
#define MAIPG_IPG0		(1)

// MACLCON bits --------
#define MACLCON_r13		((WORD)1<<13)
#define MACLCON_r12		((WORD)1<<12)
#define MACLCON_r11		((WORD)1<<11)
#define MACLCON_r10		((WORD)1<<10)
#define MACLCON_r9		((WORD)1<<9)
#define MACLCON_r8		((WORD)1<<8)
#define MACLCON_MAXRET3	(1<<3)
#define MACLCON_MAXRET2	(1<<2)
#define MACLCON_MAXRET1	(1<<1)
#define MACLCON_MAXRET0	(1)

// MICMD bits ----------
#define	MICMD_MIISCAN	(1<<1)
#define	MICMD_MIIRD		(1)

// MIREGADR bits -------
#define MIREGADR_r12	((WORD)1<<12)
#define MIREGADR_r11	((WORD)1<<11)
#define MIREGADR_r10	((WORD)1<<10)
#define MIREGADR_r9		((WORD)1<<9)
#define MIREGADR_r8		((WORD)1<<8)
#define MIREGADR_PHREG4	(1<<4)
#define MIREGADR_PHREG3	(1<<3)
#define MIREGADR_PHREG2	(1<<2)
#define MIREGADR_PHREG1	(1<<1)
#define MIREGADR_PHREG0	(1)

// MISTAT bits ---------
#define MISTAT_r3		(1<<3)
#define	MISTAT_NVALID	(1<<2)
#define	MISTAT_SCAN		(1<<1)
#define	MISTAT_BUSY		(1)

// ECON2 bits ----------
#define ECON2_ETHEN		((WORD)1<<15)
#define ECON2_STRCH		((WORD)1<<14)
#define ECON2_TXMAC		((WORD)1<<13)
#define ECON2_SHA1MD5	((WORD)1<<12)
#define ECON2_COCON3	((WORD)1<<11)
#define ECON2_COCON2	((WORD)1<<10)
#define ECON2_COCON1	((WORD)1<<9)
#define ECON2_COCON0	((WORD)1<<8)
#define ECON2_AUTOFC	(1<<7)
#define ECON2_TXRST		(1<<6)
#define ECON2_RXRST		(1<<5)
#define ECON2_ETHRST	(1<<4)
#define ECON2_MODLEN1	(1<<3)
#define ECON2_MODLEN0	(1<<2)
#define ECON2_AESLEN1	(1<<1)
#define ECON2_AESLEN0	(1)

// ERXWM bits ----------
#define ERXWM_RXFWM7	((WORD)1<<15)
#define ERXWM_RXFWM6	((WORD)1<<14)
#define ERXWM_RXFWM5	((WORD)1<<13)
#define ERXWM_RXFWM4	((WORD)1<<12)
#define ERXWM_RXFWM3	((WORD)1<<11)
#define ERXWM_RXFWM2	((WORD)1<<10)
#define ERXWM_RXFWM1	((WORD)1<<9)
#define ERXWM_RXFWM0	((WORD)1<<8)
#define ERXWM_RXEWM7	(1<<7)
#define ERXWM_RXEWM6	(1<<6)
#define ERXWM_RXEWM5	(1<<5)
#define ERXWM_RXEWM4	(1<<4)
#define ERXWM_RXEWM3	(1<<3)
#define ERXWM_RXEWM2	(1<<2)
#define ERXWM_RXEWM1	(1<<1)
#define ERXWM_RXEWM0	(1)

// EIE bits ------------
#define EIE_INTIE		((WORD)1<<15)
#define EIE_MODEXIE		((WORD)1<<14)
#define EIE_HASHIE		((WORD)1<<13)
#define EIE_AESIE		((WORD)1<<12)
#define EIE_LINKIE		((WORD)1<<11)
#define EIE_PRDYIE		((WORD)1<<10)
#define EIE_r9			((WORD)1<<9)
#define EIE_r8			((WORD)1<<8)
#define EIE_r7			(1<<7)
#define EIE_PKTIE		(1<<6)
#define EIE_DMAIE		(1<<5)
#define EIE_r4			(1<<4)
#define EIE_TXIE		(1<<3)
#define EIE_TXABTIE		(1<<2)
#define EIE_RXABTIE		(1<<1)
#define EIE_PCFULIE		(1)

// EIDLED bits ---------
#define EIDLED_LACFG3	((WORD)1<<15)
#define EIDLED_LACFG2	((WORD)1<<14)
#define EIDLED_LACFG1	((WORD)1<<13)
#define EIDLED_LACFG0	((WORD)1<<12)
#define EIDLED_LBCFG3	((WORD)1<<11)
#define EIDLED_LBCFG2	((WORD)1<<10)
#define EIDLED_LBCFG1	((WORD)1<<9)
#define EIDLED_LBCFG0	((WORD)1<<8)
#define EIDLED_DEVID2	(1<<7)
#define EIDLED_DEVID1	(1<<6)
#define EIDLED_DEVID0	(1<<5)
#define EIDLED_REVID4	(1<<4)
#define EIDLED_REVID3	(1<<3)
#define EIDLED_REVID2	(1<<2)
#define EIDLED_REVID1	(1<<1)
#define EIDLED_REVID0	(1)

// PHCON1 bits ---------
#define PHCON1_PRST		((WORD)1<<15)
#define PHCON1_PLOOPBK	((WORD)1<<14)
#define PHCON1_SPD100	((WORD)1<<13)
#define PHCON1_ANEN		((WORD)1<<12)
#define PHCON1_PSLEEP	((WORD)1<<11)
#define PHCON1_r10		((WORD)1<<10)
#define PHCON1_RENEG	((WORD)1<<9)
#define PHCON1_PFULDPX	((WORD)1<<8)
#define PHCON1_r7		(1<<7)
#define PHCON1_r6		(1<<6)
#define PHCON1_r5		(1<<5)
#define PHCON1_r4		(1<<4)
#define PHCON1_r3		(1<<3)
#define PHCON1_r2		(1<<2)
#define PHCON1_r1		(1<<1)
#define PHCON1_r0		(1)

// PHSTAT1 bits --------
#define PHSTAT1_r15		((WORD)1<<15)
#define PHSTAT1_FULL100	((WORD)1<<14)
#define PHSTAT1_HALF100	((WORD)1<<13)
#define PHSTAT1_FULL10	((WORD)1<<12)
#define PHSTAT1_HALF10	((WORD)1<<11)
#define PHSTAT1_r10		((WORD)1<<10)
#define PHSTAT1_r9		((WORD)1<<9)
#define PHSTAT1_r8		((WORD)1<<8)
#define PHSTAT1_r7		(1<<7)
#define PHSTAT1_r6		(1<<6)
#define PHSTAT1_ANDONE	(1<<5)
#define PHSTAT1_LRFAULT	(1<<4)
#define PHSTAT1_ANABLE	(1<<3)
#define PHSTAT1_LLSTAT	(1<<2)
#define PHSTAT1_r1		(1<<1)
#define PHSTAT1_EXTREGS	(1)

// PHANA bits ----------
#define PHANA_ADNP		((WORD)1<<15)
#define PHANA_r14		((WORD)1<<14)
#define PHANA_ADFAULT	((WORD)1<<13)
#define PHANA_r12		((WORD)1<<12)
#define PHANA_ADPAUS1	((WORD)1<<11)
#define PHANA_ADPAUS0	((WORD)1<<10)
#define PHANA_r9		((WORD)1<<9)
#define PHANA_AD100FD	((WORD)1<<8)
#define PHANA_AD100		(1<<7)
#define PHANA_AD10FD	(1<<6)
#define PHANA_AD10		(1<<5)
#define PHANA_ADIEEE4	(1<<4)
#define PHANA_ADIEEE3	(1<<3)
#define PHANA_ADIEEE2	(1<<2)
#define PHANA_ADIEEE1	(1<<1)
#define PHANA_ADIEEE0	(1)

// PHANLPA bits --------
#define PHANLPA_LPNP	((WORD)1<<15)
#define PHANLPA_LPACK	((WORD)1<<14)
#define PHANLPA_LPFAULT	((WORD)1<<13)
#define PHANLPA_r12		((WORD)1<<12)
#define PHANLPA_LPPAUS1	((WORD)1<<11)
#define PHANLPA_LPPAUS0	((WORD)1<<10)
#define PHANLPA_LP100T4	((WORD)1<<9)
#define PHANLPA_LP100FD	((WORD)1<<8)
#define PHANLPA_LP100	(1<<7)
#define PHANLPA_LP10FD	(1<<6)
#define PHANLPA_LP10	(1<<5)
#define PHANLPA_LPIEEE4	(1<<4)
#define PHANLPA_LPIEEE3	(1<<3)
#define PHANLPA_LPIEEE2	(1<<2)
#define PHANLPA_LPIEEE1	(1<<1)
#define PHANLPA_LPIEEE0	(1)

// PHANE bits ----------
#define PHANE_r15		((WORD)1<<15)
#define PHANE_r14		((WORD)1<<14)
#define PHANE_r13		((WORD)1<<13)
#define PHANE_r12		((WORD)1<<12)
#define PHANE_r11		((WORD)1<<11)
#define PHANE_r10		((WORD)1<<10)
#define PHANE_r9		((WORD)1<<9)
#define PHANE_r8		((WORD)1<<8)
#define PHANE_r7		(1<<7)
#define PHANE_r6		(1<<6)
#define PHANE_r5		(1<<5)
#define PHANE_PDFLT		(1<<4)
#define PHANE_r3		(1<<3)
#define PHANE_r2		(1<<2)
#define PHANE_LPARCD	(1<<1)
#define PHANA_LPANABL	(1)

// PHCON2 bits ---------
#define PHCON2_r15		((WORD)1<<15)
#define PHCON2_r14		((WORD)1<<14)
#define PHCON2_EDPWRDN	((WORD)1<<13)
#define PHCON2_r12		((WORD)1<<12)
#define PHCON2_EDTHRES	((WORD)1<<11)
#define PHCON2_r10		((WORD)1<<10)
#define PHCON2_r9		((WORD)1<<9)
#define PHCON2_r8		((WORD)1<<8)
#define PHCON2_r7		(1<<7)
#define PHCON2_r6		(1<<6)
#define PHCON2_r5		(1<<5)
#define PHCON2_r4		(1<<4)
#define PHCON2_r3		(1<<3)
#define PHCON2_FRCLNK	(1<<2)
#define PHCON2_EDSTAT	(1<<1)
#define PHCON2_r0		(1)

// PHSTAT2 bits ---------
#define PHSTAT2_r15		((WORD)1<<15)
#define PHSTAT2_r14		((WORD)1<<14)
#define PHSTAT2_r13		((WORD)1<<13)
#define PHSTAT2_r12		((WORD)1<<12)
#define PHSTAT2_r11		((WORD)1<<11)
#define PHSTAT2_r10		((WORD)1<<10)
#define PHSTAT2_r9		((WORD)1<<9)
#define PHSTAT2_r8		((WORD)1<<8)
#define PHSTAT2_r7		(1<<7)
#define PHSTAT2_r6		(1<<6)
#define PHSTAT2_r5		(1<<5)
#define PHSTAT2_PLRITY	(1<<4)
#define PHSTAT2_r3		(1<<3)
#define PHSTAT2_r2		(1<<2)
#define PHSTAT2_r1		(1<<1)
#define PHSTAT2_r0		(1)

// PHSTAT3 bits --------
#define PHSTAT3_r15		((WORD)1<<15)
#define PHSTAT3_r14		((WORD)1<<14)
#define PHSTAT3_r13		((WORD)1<<13)
#define PHSTAT3_r12		((WORD)1<<12)
#define PHSTAT3_r11		((WORD)1<<11)
#define PHSTAT3_r10		((WORD)1<<10)
#define PHSTAT3_r9		((WORD)1<<9)
#define PHSTAT3_r8		((WORD)1<<8)
#define PHSTAT3_r7		(1<<7)
#define PHSTAT3_r6		(1<<6)
#define PHSTAT3_r5		(1<<5)
#define PHSTAT3_SPDDPX2	(1<<4)
#define PHSTAT3_SPDDPX1	(1<<3)
#define PHSTAT3_SPDDPX0	(1<<2)
#define PHSTAT3_r1		(1<<1)
#define PHSTAT3_r0		(1)


#endif
