/*********************************************************************
 *
 *	Hardware specific definitions for PIC32 Starter Kit (GP or USB) + 
 *  PIC32 I/O Expansion Board + Ethernet PICtail Plus (ENC28J60) or
 *  Fast 100Mbps Ethernet PICtail Plus (ENC624J600)
 *
 *********************************************************************
 * FileName:        HardwareProfile.h
 * Dependencies:    None
 * Processor:       PIC32
 * Compiler:        Microchip C32 v1.05 or higher
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
 * Author               Date		Comment
 *~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 * Aseem swalah		02/03/09	   Copied from the TCPIP Demo App
 ********************************************************************/
#ifndef __HARDWARE_PROFILE_H
#define __HARDWARE_PROFILE_H

#include "GenericTypeDefs.h"
#include "Compiler.h"


	// Set configuration fuses (but only once)
	#if defined(THIS_IS_STACK_APPLICATION)
		#pragma config FPLLODIV = DIV_1, FPLLMUL = MUL_20, FPLLIDIV = DIV_2, FWDTEN = OFF, FPBDIV = DIV_1, POSCMOD = XT, FNOSC = PRIPLL, CP = OFF
	#endif

    // Clock frequency value.
    // This value is used to calculate Tick Counter value
    #define GetSystemClock()		(80000000ul)      // Hz
    #define GetInstructionClock()	(GetSystemClock()/1)
    #define GetPeripheralClock()	(GetInstructionClock()/1)	// Set your divider according to your Peripheral Bus Frequency configuration fuse setting


	// Specify which SPI to use for the ENC624J600.  
	#define ENC_IN_SPI2

    
    // Hardware mappings
    #define LED0_TRIS			(TRISDbits.TRISD0)	// Ref LED1
	#define LED0_IO				(LATDbits.LATD0)
	#define LED1_TRIS			(TRISDbits.TRISD1)	// Ref LED2
	#define LED1_IO				(LATDbits.LATD1)	
	#define LED2_TRIS			(TRISDbits.TRISD2)	// Ref LED3
	#define LED2_IO				(LATDbits.LATD2)
	#define LED3_TRIS			(LED2_TRIS)			// No such LED
	#define LED3_IO				(LATDbits.LATD6)
	#define LED4_TRIS			(LED2_TRIS)			// No such LED
	#define LED4_IO				(LATDbits.LATD6)
	#define LED5_TRIS			(LED2_TRIS)			// No such LED
	#define LED5_IO				(LATDbits.LATD6)
	#define LED6_TRIS			(LED2_TRIS)			// No such LED
	#define LED6_IO				(LATDbits.LATD6)
	#define LED7_TRIS			(LED2_TRIS)			// No such LED
	#define LED7_IO				(LATDbits.LATD6)
    
	#define LED_GET()			((BYTE)LATD & 0x07)
	#define LED_PUT(a)			do{LATD = (LATD & 0xFFF8) | ((a)&0x07);}while(0)

    #define BUTTON0_TRIS		(TRISDbits.TRISD6)	// Ref SW1
	#define	BUTTON0_IO			(PORTDbits.RD6)
	#define BUTTON1_TRIS		(TRISDbits.TRISD7)	// Ref SW2
	#define	BUTTON1_IO			(PORTDbits.RD7)
	#define BUTTON2_TRIS		(TRISDbits.TRISD13)	// Ref SW3
	#define	BUTTON2_IO			(PORTDbits.RD13)
	#define BUTTON3_TRIS		(TRISDbits.TRISD13)	// No BUTTON3 on this board
	#define	BUTTON3_IO			(1)
    
    

	// ENC624J600 Interface Configuration
	// Comment out ENC100_INTERFACE_MODE if you don't have an ENC624J600 or 
	// ENC424J600.  Otherwise, choose the correct setting for the interface you 
	// are using.  Legal values are:
	//  - Commented out: No ENC424J600/624J600 present or used.  All other 
	//                   ENC100_* macros are ignored.
	//	- 0: SPI mode using CS, SCK, SI, and SO pins
	//  - 1: 8-bit demultiplexed PSP Mode 1 with RD and WR pins
	//  - 2: 8-bit demultiplexed PSP Mode 2 with R/Wbar and EN pins
	//  - 3: 16-bit demultiplexed PSP Mode 3 with RD, WRL, and WRH pins
	//  - 4: 16-bit demultiplexed PSP Mode 4 with R/Wbar, B0SEL, and B1SEL pins
	//  - 5: 8-bit multiplexed PSP Mode 5 with RD and WR pins
	//  - 6: 8-bit multiplexed PSP Mode 6 with R/Wbar and EN pins
	//  - 9: 16-bit multiplexed PSP Mode 9 with AL, RD, WRL, and WRH pins
	//  - 10: 16-bit multiplexed PSP Mode 10 with AL, R/Wbar, B0SEL, and B1SEL 
	//        pins
	#define ENC100_INTERFACE_MODE			3

	// If using a parallel interface, direct RAM addressing can be used (if all 
	// addresses wires are connected), or a reduced number of pins can be used 
	// for indirect addressing.  If using an SPI interface or PSP Mode 9 or 10 
	// (multiplexed 16-bit modes), which require all address lines to always be 
	// connected, then this option is ignored. Comment out or uncomment this 
	// macro to match your hardware connections.
	#define ENC100_PSP_USE_INDIRECT_RAM_ADDRESSING

	// ENC424J600/624J600 parallel indirect address remapping macro function.
	// This section translates SFR and RAM addresses presented to the 
	// ReadMemory() and WriteMemory() APIs in ENCX24J600.c to the actual 
	// addresses that must be presented on the parallel interface.  This macro 
	// must be modified to match your hardware if you are using an indirect PSP 
	// addressing mode (ENC100_PSP_USE_INDIRECT_RAM_ADDRESSING is defined) and 
	// have some of your address lines tied off to Vdd.  If you are using the 
	// SPI interface, then this section can be ignored or deleted.
	#if (ENC100_INTERFACE_MODE == 1) || (ENC100_INTERFACE_MODE == 2) || (ENC100_INTERFACE_MODE == 5) || (ENC100_INTERFACE_MODE == 6) // 8-bit PSP
		#define ENC100_TRANSLATE_TO_PIN_ADDR(a)		((((a)&0x0100)<<6) | ((a)&0x00FF))
	#elif (ENC100_INTERFACE_MODE == 3) || (ENC100_INTERFACE_MODE == 4) // 16-bit PSP
		#define ENC100_TRANSLATE_TO_PIN_ADDR(a)		(a)
	#endif

	// Auto-crossover pins on Fast 100Mbps Ethernet PICtail/PICtail Plus.  If 
	// your circuit doesn't have such a feature, delete these two defines.
	#define ENC100_MDIX_TRIS				(TRISBbits.TRISB3)
	#define ENC100_MDIX_IO					(LATBbits.LATB3)

	// ENC624J600 I/O control and status pins
	// If a pin is not required for your selected ENC100_INTERFACE_MODE 
	// interface selection (ex: WRH/B1SEL for PSP modes 1, 2, 5, and 6), then 
	// you can ignore, delete, or put anything for the pin definition.  Also, 
	// the INT and POR pins are entirely optional.  If not connected, comment 
	// them out.
	#define ENC100_INT_TRIS					(TRISEbits.TRISE9)		// INT signal is optional and currently unused in the Microchip TCP/IP Stack.  Leave this pin disconnected and comment out this pin definition if you don't want it.
	#define ENC100_INT_IO					(PORTEbits.RE9)
	#if (ENC100_INTERFACE_MODE >= 1)	// Parallel mode
		// PSP control signal pinout
		#define ENC100_CS_TRIS					(TRISAbits.TRISA5)	// CS is optional in PSP mode.  If you are not sharing the parallel bus with another device, tie CS to Vdd and comment out this pin definition.
		#define ENC100_CS_IO					(LATAbits.LATA5)
		#define ENC100_POR_TRIS					(TRISCbits.TRISC1)	// POR signal is optional.  If your application doesn't have a power disconnect feature, comment out this pin definition.
		#define ENC100_POR_IO					(LATCbits.LATC1)
		#define ENC100_SO_WR_B0SEL_EN_TRIS		(TRISDbits.TRISD4)
		#define ENC100_SO_WR_B0SEL_EN_IO		(LATDbits.LATD4)
		#define ENC100_SI_RD_RW_TRIS			(TRISDbits.TRISD5)
		#define ENC100_SI_RD_RW_IO				(LATDbits.LATD5)
		#define ENC100_SCK_AL_TRIS				(TRISBbits.TRISB15)
		#define ENC100_SCK_AL_IO				(LATBbits.LATB15)
	#else	
		// SPI pinout
    	#if defined ENC_IN_SPI1
        	#define ENC100_CS_TRIS					(TRISDbits.TRISD14)	// CS is mandatory when using the SPI interface
        	#define ENC100_CS_IO					(LATDbits.LATD14)
        	#define ENC100_POR_TRIS					(TRISDbits.TRISD15)	// POR signal is optional.  If your application doesn't have a power disconnect feature, comment out this pin definition.
        	#define ENC100_POR_IO					(LATDbits.LATD15)
        	#define ENC100_SO_WR_B0SEL_EN_TRIS		(TRISFbits.TRISF7)	// SO is ENCX24J600 Serial Out, which needs to connect to the PIC SDI pin for SPI mode
        	#define ENC100_SO_WR_B0SEL_EN_IO		(PORTFbits.RF7)
        	#define ENC100_SI_RD_RW_TRIS			(TRISFbits.TRISF8)	// SI is ENCX24J600 Serial In, which needs to connect to the PIC SDO pin for SPI mode
        	#define ENC100_SI_RD_RW_IO				(LATFbits.LATF8)
        	#define ENC100_SCK_AL_TRIS				(TRISFbits.TRISF6)
        #elif defined ENC_IN_SPI2
            #define ENC100_CS_TRIS					(TRISFbits.TRISF12)
    		#define ENC100_CS_IO					(LATFbits.LATF12)
    		#define ENC100_POR_TRIS					(TRISFbits.TRISF13)
    		#define ENC100_POR_IO					(LATFbits.LATF13)
    		#define ENC100_SO_WR_B0SEL_EN_TRIS		(TRISGbits.TRISG7)	// NOTE: SO is ENC624J600 Serial Out, which needs to connect to the PIC SDI pin for SPI mode
    		#define ENC100_SO_WR_B0SEL_EN_IO		(PORTGbits.RG7)
    		#define ENC100_SI_RD_RW_TRIS			(TRISGbits.TRISG8)	// NOTE: SI is ENC624J600 Serial In, which needs to connect to the PIC SDO pin for SPI mode
    		#define ENC100_SI_RD_RW_IO				(LATGbits.LATG8)
    		#define ENC100_SCK_AL_TRIS				(TRISGbits.TRISG6)
    		#define ENC100_SCK_AL_IO				(PORTGbits.RG6)		// NOTE: This must be the PORT, not the LATch like it is for the PSP interface.
        #endif
    #endif


	// ENC624J600 SPI SFR register selection (controls which SPI peripheral to 
	// use on PICs with multiple SPI peripherals).  If a parallel interface is 
	// used (ENC100_INTERFACE_MODE is >= 1), then the SPI is not used and this 
	// section can be ignored or deleted.
    #if defined ENC_IN_SPI1
       	#define ENC100_ISR_ENABLE		(IEC0bits.INT2IE)
       	#define ENC100_ISR_FLAG			(IFS0bits.INT2IF)
       	#define ENC100_ISR_POLARITY		(INTCONbits.INT2EP)	
       	#define ENC100_ISR_PRIORITY		(IPC2bits.INT2IP)	
       	#define ENC100_SPI_ENABLE		(ENC100_SPICON1bits.ON)
       	#define ENC100_SPI_IF			(IFS0bits.SPI1RXIF)
       	#define ENC100_SSPBUF			(SPI1BUF)
       	#define ENC100_SPICON1			(SPI1CON)
       	#define ENC100_SPISTATbits		(SPI1STATbits)
       	#define ENC100_SPICON1bits		(SPI1CONbits)
       	#define ENC100_SPIBRG			(SPI1BRG)
    #elif defined ENC_IN_SPI2
        #define ENC100_ISR_ENABLE		(IEC0bits.INT4IE)
        #define ENC100_ISR_FLAG			(IFS0bits.INT4IF)
        #define ENC100_ISR_POLARITY		(INTCONbits.INT4EP)	
        #define ENC100_ISR_PRIORITY		(IPC2bits.INT4IP)	
        #define ENC100_SPI_ENABLE		(ENC100_SPICON1bits.ON)
        #define ENC100_SPI_IF			(IFS1bits.SPI2RXIF)
        #define ENC100_SSPBUF			(SPI2BUF)
        #define ENC100_SPICON1			(SPI2CON)
        #define ENC100_SPISTATbits		(SPI2STATbits)
        #define ENC100_SPICON1bits		(SPI2CONbits)
        #define ENC100_SPIBRG			(SPI2BRG)
    #endif

#endif //__HARDWARE_PROFILE_H