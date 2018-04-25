/*  ------------------------------------------------------------------------------ */
/*  | Lowlevel Access to memory mapped ENC624J600 in PSP mode                    | */
/*  | Henryk Richter <henryk.richter@gmx.net>                                    | */
/*  ------------------------------------------------------------------------------ */
/*  register definition section */
#ifndef _REGISTERS_H_
#define _REGISTERS_H_

/*  set/clr register offsets */
#define SET_OFFSET 0x0100
#define CLR_OFFSET 0x0180

/*  Register definitions */

/*  SPI Bank 0 registers -------- */
#define ETXST	    0x7E00
#define ETXSTL	    0x7E00
#define ETXSTH	    0x7E01
#define ETXLEN	    0x7E02
#define ETXLENL	    0x7E02
#define ETXLENH	    0x7E03
#define ERXST	    0x7E04
#define ERXSTL	    0x7E04
#define ERXSTH	    0x7E05
#define ERXTAIL	    0x7E06
#define ERXTAILL    0x7E06
#define ERXTAILH    0x7E07
#define ERXHEAD	    0x7E08
#define ERXHEADL    0x7E08
#define ERXHEADH    0x7E09
#define EDMAST	    0x7E0A
#define EDMASTL	    0x7E0A
#define EDMASTH	    0x7E0B
#define EDMALEN	    0x7E0C
#define EDMALENL    0x7E0C
#define EDMALENH    0x7E0D
#define EDMADST	    0x7E0E
#define EDMADSTL    0x7E0E
#define EDMADSTH    0x7E0F
#define EDMACS	    0x7E10
#define EDMACSL	    0x7E10
#define EDMACSH	    0x7E11
#define ETXSTAT	    0x7E12
#define ETXSTATL    0x7E12
#define ETXSTATH    0x7E13
#define ETXWIRE	    0x7E14
#define ETXWIREL    0x7E14
#define ETXWIREH    0x7E15

/*  SPI all bank registers */
#define EUDAST	    0x7E16
#define EUDASTL	    0x7E16
#define EUDASTH	    0x7E17
#define EUDAND	    0x7E18
#define EUDANDL	    0x7E18
#define EUDANDH	    0x7E19
#define ESTAT	    0x7E1A
#define ESTATL	    0x7E1A
#define ESTATH	    0x7E1B
#define EIR	    0x7E1C
#define EIRL	    0x7E1C
#define EIRH	    0x7E1D
#define ECON1	    0x7E1E
#define ECON1L	    0x7E1E
#define ECON1H	    0x7E1F


/*  SPI Bank 1 registers ----- */
#define EHT1	    0x7E20
#define EHT1L	    0x7E20
#define EHT1H	    0x7E21
#define EHT2	    0x7E22
#define EHT2L	    0x7E22
#define EHT2H	    0x7E23
#define EHT3	    0x7E24
#define EHT3L	    0x7E24
#define EHT3H	    0x7E25
#define EHT4	    0x7E26
#define EHT4L	    0x7E26
#define EHT4H	    0x7E27
#define EPMM1	    0x7E28
#define EPMM1L	    0x7E28
#define EPMM1H	    0x7E29
#define EPMM2	    0x7E2A
#define EPMM2L	    0x7E2A
#define EPMM2H	    0x7E2B
#define EPMM3	    0x7E2C
#define EPMM3L	    0x7E2C
#define EPMM3H	    0x7E2D
#define EPMM4	    0x7E2E
#define EPMM4L	    0x7E2E
#define EPMM4H	    0x7E2F
#define EPMCS	    0x7E30
#define EPMCSL	    0x7E30
#define EPMCSH	    0x7E31
#define EPMO	    0x7E32
#define EPMOL	    0x7E32
#define EPMOH	    0x7E33
#define ERXFCON	    0x7E34
#define ERXFCONL    0x7E34
#define ERXFCONH    0x7E35

/*  SPI all bank registers from 0x36 to 0x3F */
/*  SPI Bank 2 registers ----- */
#define MACON1	    0x7E40
#define MACON1L	    0x7E40
#define MACON1H	    0x7E41
#define MACON2	    0x7E42
#define MACON2L	    0x7E42
#define MACON2H	    0x7E43
#define MABBIPG	    0x7E44
#define MABBIPGL    0x7E44
#define MABBIPGH    0x7E45
#define MAIPG	    0x7E46
#define MAIPGL	    0x7E46
#define MAIPGH	    0x7E47
#define MACLCON	    0x7E48
#define MACLCONL    0x7E48
#define MACLCONH    0x7E49
#define MAMXFL	    0x7E4A
#define MAMXFLL	    0x7E4A
#define MAMXFLH	    0x7E4B
#define MICMD	    0x7E52
#define MICMDL	    0x7E52
#define MICMDH	    0x7E53
#define MIREGADR    0x7E54
#define MIREGADRL    0x7E54
#define MIREGADRH    0x7E55

/*  SPI all bank registers from 0x56 to 0x5F */
/*  SPI Bank 3 registers ----- */
#define MAADR3	    0x7E60
#define MAADR3L	    0x7E60
#define MAADR3H	    0x7E61
#define MAADR2	    0x7E62
#define MAADR2L	    0x7E62
#define MAADR2H	    0x7E63
#define MAADR1	    0x7E64
#define MAADR1L	    0x7E64
#define MAADR1H	    0x7E65
#define MIWR	    0x7E66
#define MIWRL	    0x7E66
#define MIWRH	    0x7E67
#define MIRD	    0x7E68
#define MIRDL	    0x7E68
#define MIRDH	    0x7E69
#define MISTAT	    0x7E6A
#define MISTATL	    0x7E6A
#define MISTATH	    0x7E6B
#define EPAUS	    0x7E6C
#define EPAUSL	    0x7E6C
#define EPAUSH	    0x7E6D
#define ECON2	    0x7E6E
#define ECON2L	    0x7E6E
#define ECON2H	    0x7E6F
#define ERXWM	    0x7E70
#define ERXWML	    0x7E70
#define ERXWMH	    0x7E71
#define EIE	    0x7E72
#define EIEL	    0x7E72
#define EIEH	    0x7E73
#define EIDLED	    0x7E74
#define EIDLEDL	    0x7E74
#define EIDLEDH	    0x7E75

/*  SPI all bank registers from 0x66 to 0x6F */

/*  SPI Non-banked Special Function Registers */
#define EGPDATA	    0x7E80
#define EGPDATAL    0x7E80
#define ERXDATA	    0x7E82
#define ERXDATAL    0x7E82
#define EUDADATA    0x7E84
#define EUDADATAL    0x7E84
#define EGPRDPT	    0x7E86
#define EGPRDPTL    0x7E86
#define EGPRDPTH    0x7E87
#define EGPWRPT	    0x7E88
#define EGPWRPTL    0x7E88
#define EGPWRPTH    0x7E89
#define ERXRDPT	    0x7E8A
#define ERXRDPTL    0x7E8A
#define ERXRDPTH    0x7E8B
#define ERXWRPT	    0x7E8C
#define ERXWRPTL    0x7E8C
#define ERXWRPTH    0x7E8D
#define EUDARDPT    0x7E8E
#define EUDARDPTL    0x7E8E
#define EUDARDPTH    0x7E8F
#define EUDAWRPT    0x7E90
#define EUDAWRPTL    0x7E90
#define EUDAWRPTH    0x7E91

/* ;;;;;;;;;;;;;;;;;;;;;;;;; */
/*  ENC424J600/624J600 register bits */
/* ;;;;;;;;;;;;;;;;;;;;;;;;; */
/*  ESTAT bits ---------- */
#define ESTAT_INT	    (1<<15)
#define ESTAT_FCIDLE    (1<<14)
#define ESTAT_RXBUSY    (1<<13)
#define ESTAT_CLKRDY    (1<<12)
#define ESTAT_RSTDONE    (1<<11)
#define ESTAT_PHYDPX    (1<<10)
#define ESTAT_PHYRDY    (1<<9)
#define ESTAT_PHYLNK    (1<<8)
#define ESTAT_PKTCNT7    (1<<7)
#define ESTAT_PKTCNT6    (1<<6)
#define ESTAT_PKTCNT5    (1<<5)
#define ESTAT_PKTCNT4    (1<<4)
#define ESTAT_PKTCNT3    (1<<3)
#define ESTAT_PKTCNT2    (1<<2)
#define ESTAT_PKTCNT1    (1<<1)
#define ESTAT_PKTCNT0    (1)

/*  EIR bits ------------ */
#define EIR_CRYPTEN	    (1<<15)
#define EIR_MODEXIF	    (1<<14)
#define EIR_HASHIF	    (1<<13)
#define EIR_AESIF	    (1<<12)
#define EIR_LINKIF	    (1<<11)
#define EIR_PRDYIF	    (1<<10)
#define EIR_r9		    (1<<9)
#define EIR_r8		    (1<<8)
#define EIR_r7		    (1<<7)
#define EIR_PKTIF	    (1<<6)
#define EIR_DMAIF	    (1<<5)
#define EIR_r4		    (1<<4)
#define EIR_TXIF	    (1<<3)
#define EIR_TXABTIF	    (1<<2)
#define EIR_RXABTIF	    (1<<1)
#define EIR_PCFULIF	    (1)

/*  ECON1 bits ---------- */
#define ECON1_MODEXST    (1<<15)
#define ECON1_HASHEN    (1<<14)
#define ECON1_HASHOP    (1<<13)
#define ECON1_HASHLST    (1<<12)
#define ECON1_AESST	    (1<<11)
#define ECON1_AESOP1    (1<<10)
#define ECON1_AESOP0    (1<<9)
#define ECON1_PKTDEC    (1<<8)
#define ECON1_FCOP1	    (1<<7)
#define ECON1_FCOP0	    (1<<6)
#define ECON1_DMAST	    (1<<5)
#define ECON1_DMACPY    (1<<4)
#define ECON1_DMACSSD    (1<<3)
#define ECON1_DMANOCS    (1<<2)
#define ECON1_TXRTS	    (1<<1)
#define ECON1_RXEN	    (1)

/*  ETXSTAT bits -------- */
#define ETXSTAT_r12	    (1<<12)
#define ETXSTAT_r11	    (1<<11)
#define ETXSTAT_LATECOL    (1<<10)
#define ETXSTAT_MAXCOL    (1<<9)
#define ETXSTAT_EXDEFER    (1<<8)
#define ETXSTAT_DEFER    (1<<7)
#define ETXSTAT_r6	    (1<<6)
#define ETXSTAT_r5	    (1<<5)
#define ETXSTAT_CRCBAD    (1<<4)
#define ETXSTAT_COLCNT3    (1<<3)
#define ETXSTAT_COLCNT2    (1<<2)
#define ETXSTAT_COLCNT1    (1<<1)
#define ETXSTAT_COLCNT0    (1)

/*  ERXFCON bits -------- */
#define ERXFCON_HTEN    (1<<15)
#define ERXFCON_MPEN    (1<<14)
#define ERXFCON_NOTPM    (1<<12)
#define ERXFCON_PMEN3    (1<<11)
#define ERXFCON_PMEN2    (1<<10)
#define ERXFCON_PMEN1    (1<<9)
#define ERXFCON_PMEN0    (1<<8)
#define ERXFCON_CRCEEN    (1<<7)
#define ERXFCON_CRCEN    (1<<6)
#define ERXFCON_RUNTEEN    (1<<5)
#define ERXFCON_RUNTEN    (1<<4)
#define ERXFCON_UCEN    (1<<3)
#define ERXFCON_NOTMEEN    (1<<2)
#define ERXFCON_MCEN    (1<<1)
#define ERXFCON_BCEN    (1)

/*  MACON1 bits --------- */
#define MACON1_r15	    (1<<15)
#define MACON1_r14	    (1<<14)
#define MACON1_r11	    (1<<11)
#define MACON1_r10	    (1<<10)
#define MACON1_r9	    (1<<9)
#define MACON1_r8	    (1<<8)
#define MACON1_LOOPBK    (1<<4)
#define MACON1_r3	    (1<<3)
#define MACON1_RXPAUS    (1<<2)
#define MACON1_PASSALL    (1<<1)
#define MACON1_r0	    (1)

/*  MACON2 bits --------- */
#define MACON2_DEFER    (1<<14)
#define MACON2_BPEN	    (1<<13)
#define MACON2_NOBKOFF    (1<<12)
#define MACON2_r9	    (1<<9)
#define MACON2_r8	    (1<<8)
#define MACON2_PADCFG2    (1<<7)
#define MACON2_PADCFG1    (1<<6)
#define MACON2_PADCFG0    (1<<5)
#define MACON2_TXCRCEN    (1<<4)
#define MACON2_PHDREN    (1<<3)
#define MACON2_HFRMEN    (1<<2)
#define MACON2_r1	    (1<<1)
#define MACON2_FULDPX    (1)

/*  MABBIPG bits -------- */
#define MABBIPG_BBIPG6     (1<<6)
#define MABBIPG_BBIPG5     (1<<5)
#define MABBIPG_BBIPG4     (1<<4)
#define MABBIPG_BBIPG3     (1<<3)
#define MABBIPG_BBIPG2     (1<<2)
#define MABBIPG_BBIPG1     (1<<1)
#define MABBIPG_BBIPG0     (1)

/*  MAIPG bits ---------- */
#define MAIPG_r14	    (1<<14)
#define MAIPG_r13	    (1<<13)
#define MAIPG_r12	    (1<<12)
#define MAIPG_r11	    (1<<11)
#define MAIPG_r10	    (1<<10)
#define MAIPG_r9	    (1<<9)
#define MAIPG_r8	    (1<<8)
#define MAIPG_IPG6	    (1<<6)
#define MAIPG_IPG5	    (1<<5)
#define MAIPG_IPG4	    (1<<4)
#define MAIPG_IPG3	    (1<<3)
#define MAIPG_IPG2	    (1<<2)
#define MAIPG_IPG1	    (1<<1)
#define MAIPG_IPG0	    (1)

/*  MACLCON bits -------- */
#define MACLCON_r13	    (1<<13)
#define MACLCON_r12	    (1<<12)
#define MACLCON_r11	    (1<<11)
#define MACLCON_r10	    (1<<10)
#define MACLCON_r9	    (1<<9)
#define MACLCON_r8	    (1<<8)
#define MACLCON_MAXRET3    (1<<3)
#define MACLCON_MAXRET2    (1<<2)
#define MACLCON_MAXRET1    (1<<1)
#define MACLCON_MAXRET0    (1)

/*  MICMD bits ---------- */
#define MICMD_MIISCAN    (1<<1)
#define MICMD_MIIRD	    (1)

/*  MIREGADR bits ------- */
#define MIREGADR_r12    (1<<12)
#define MIREGADR_r11    (1<<11)
#define MIREGADR_r10    (1<<10)
#define MIREGADR_r9	    (1<<9)
#define MIREGADR_r8	    (1<<8)
#define MIREGADR_PHREG4    (1<<4)
#define MIREGADR_PHREG3    (1<<3)
#define MIREGADR_PHREG2    (1<<2)
#define MIREGADR_PHREG1    (1<<1)
#define MIREGADR_PHREG0    (1)

/*  MISTAT bits --------- */
#define MISTAT_r3	    (1<<3)
#define MISTAT_NVALID    (1<<2)
#define MISTAT_SCAN	    (1<<1)
#define MISTAT_BUSY	    (1)

/*  ECON2 bits ---------- */
#define ECON2_ETHEN	    (1<<15)
#define ECON2_STRCH	    (1<<14)
#define ECON2_TXMAC	    (1<<13)
#define ECON2_SHA1MD5    (1<<12)
#define ECON2_COCON3    (1<<11)
#define ECON2_COCON2    (1<<10)
#define ECON2_COCON1    (1<<9)
#define ECON2_COCON0    (1<<8)
#define ECON2_AUTOFC    (1<<7)
#define ECON2_TXRST	    (1<<6)
#define ECON2_RXRST	    (1<<5)
#define ECON2_ETHRST    (1<<4)
#define ECON2_MODLEN1    (1<<3)
#define ECON2_MODLEN0    (1<<2)
#define ECON2_AESLEN1    (1<<1)
#define ECON2_AESLEN0    (1)

/*  ERXWM bits ---------- */
#define ERXWM_RXFWM7    (1<<15)
#define ERXWM_RXFWM6    (1<<14)
#define ERXWM_RXFWM5    (1<<13)
#define ERXWM_RXFWM4    (1<<12)
#define ERXWM_RXFWM3    (1<<11)
#define ERXWM_RXFWM2    (1<<10)
#define ERXWM_RXFWM1    (1<<9)
#define ERXWM_RXFWM0    (1<<8)
#define ERXWM_RXEWM7    (1<<7)
#define ERXWM_RXEWM6    (1<<6)
#define ERXWM_RXEWM5    (1<<5)
#define ERXWM_RXEWM4    (1<<4)
#define ERXWM_RXEWM3    (1<<3)
#define ERXWM_RXEWM2    (1<<2)
#define ERXWM_RXEWM1    (1<<1)
#define ERXWM_RXEWM0    (1)

/*  EIE bits ------------ */
#define EIE_INTIE	    (1<<15)
#define EIE_MODEXIE	    (1<<14)
#define EIE_HASHIE	    (1<<13)
#define EIE_AESIE	    (1<<12)
#define EIE_LINKIE	    (1<<11)
#define EIE_PRDYIE	    (1<<10)
#define EIE_r9		    (1<<9)
#define EIE_r8		    (1<<8)
#define EIE_r7		    (1<<7)
#define EIE_PKTIE	    (1<<6)
#define EIE_DMAIE	    (1<<5)
#define EIE_r4		    (1<<4)
#define EIE_TXIE	    (1<<3)
#define EIE_TXABTIE	    (1<<2)
#define EIE_RXABTIE	    (1<<1)
#define EIE_PCFULIE	    (1)

/*  EIDLED bits --------- */
#define EIDLED_LACFG3    (1<<15)
#define EIDLED_LACFG2    (1<<14)
#define EIDLED_LACFG1    (1<<13)
#define EIDLED_LACFG0    (1<<12)
#define EIDLED_LBCFG3    (1<<11)
#define EIDLED_LBCFG2    (1<<10)
#define EIDLED_LBCFG1    (1<<9)
#define EIDLED_LBCFG0    (1<<8)
#define EIDLED_DEVID2    (1<<7)
#define EIDLED_DEVID1    (1<<6)
#define EIDLED_DEVID0    (1<<5)
#define EIDLED_REVID4    (1<<4)
#define EIDLED_REVID3    (1<<3)
#define EIDLED_REVID2    (1<<2)
#define EIDLED_REVID1    (1<<1)
#define EIDLED_REVID0    (1)

/*  PHCON1 bits --------- */
#define PHCON1_PRST	    (1<<15)
#define PHCON1_PLOOPBK    (1<<14)
#define PHCON1_SPD100    (1<<13)
#define PHCON1_ANEN	    (1<<12)
#define PHCON1_PSLEEP    (1<<11)
#define PHCON1_r10	    (1<<10)
#define PHCON1_RENEG    (1<<9)
#define PHCON1_PFULDPX    (1<<8)
#define PHCON1_r7	    (1<<7)
#define PHCON1_r6	    (1<<6)
#define PHCON1_r5	    (1<<5)
#define PHCON1_r4	    (1<<4)
#define PHCON1_r3	    (1<<3)
#define PHCON1_r2	    (1<<2)
#define PHCON1_r1	    (1<<1)
#define PHCON1_r0	    (1)

/*  PHSTAT1 bits -------- */
#define PHSTAT1_r15	    (1<<15)
#define PHSTAT1_FULL100    (1<<14)
#define PHSTAT1_HALF100    (1<<13)
#define PHSTAT1_FULL10    (1<<12)
#define PHSTAT1_HALF10    (1<<11)
#define PHSTAT1_r10	    (1<<10)
#define PHSTAT1_r9	    (1<<9)
#define PHSTAT1_r8	    (1<<8)
#define PHSTAT1_r7	    (1<<7)
#define PHSTAT1_r6	    (1<<6)
#define PHSTAT1_ANDONE    (1<<5)
#define PHSTAT1_LRFAULT    (1<<4)
#define PHSTAT1_ANABLE    (1<<3)
#define PHSTAT1_LLSTAT    (1<<2)
#define PHSTAT1_r1	    (1<<1)
#define PHSTAT1_EXTREGS    (1)

/*  PHANA bits ---------- */
#define PHANA_ADNP	    (1<<15)
#define PHANA_r14	    (1<<14)
#define PHANA_ADFAULT    (1<<13)
#define PHANA_r12	    (1<<12)
#define PHANA_ADPAUS1    (1<<11)
#define PHANA_ADPAUS0    (1<<10)
#define PHANA_r9	    (1<<9)
#define PHANA_AD100FD    (1<<8)
#define PHANA_AD100	    (1<<7)
#define PHANA_AD10FD    (1<<6)
#define PHANA_AD10	    (1<<5)
#define PHANA_ADIEEE4    (1<<4)
#define PHANA_ADIEEE3    (1<<3)
#define PHANA_ADIEEE2    (1<<2)
#define PHANA_ADIEEE1    (1<<1)
#define PHANA_ADIEEE0    (1)

/*  PHANLPA bits -------- */
#define PHANLPA_LPNP    (1<<15)
#define PHANLPA_LPACK    (1<<14)
#define PHANLPA_LPFAULT    (1<<13)
#define PHANLPA_r12	    (1<<12)
#define PHANLPA_LPPAUS1    (1<<11)
#define PHANLPA_LPPAUS0    (1<<10)
#define PHANLPA_LP100T4    (1<<9)
#define PHANLPA_LP100FD    (1<<8)
#define PHANLPA_LP100    (1<<7)
#define PHANLPA_LP10FD    (1<<6)
#define PHANLPA_LP10    (1<<5)
#define PHANLPA_LPIEEE4    (1<<4)
#define PHANLPA_LPIEEE3    (1<<3)
#define PHANLPA_LPIEEE2    (1<<2)
#define PHANLPA_LPIEEE1    (1<<1)
#define PHANLPA_LPIEEE0    (1)

/*  PHANE bits ---------- */
#define PHANE_r15	    (1<<15)
#define PHANE_r14	    (1<<14)
#define PHANE_r13	    (1<<13)
#define PHANE_r12	    (1<<12)
#define PHANE_r11	    (1<<11)
#define PHANE_r10	    (1<<10)
#define PHANE_r9	    (1<<9)
#define PHANE_r8	    (1<<8)
#define PHANE_r7	    (1<<7)
#define PHANE_r6	    (1<<6)
#define PHANE_r5	    (1<<5)
#define PHANE_PDFLT	    (1<<4)
#define PHANE_r3	    (1<<3)
#define PHANE_r2	    (1<<2)
#define PHANE_LPARCD    (1<<1)
#define PHANA_LPANABL    (1)

/*  PHCON2 bits --------- */
#define PHCON2_r15	    (1<<15)
#define PHCON2_r14	    (1<<14)
#define PHCON2_EDPWRDN    (1<<13)
#define PHCON2_r12	    (1<<12)
#define PHCON2_EDTHRES    (1<<11)
#define PHCON2_r10	    (1<<10)
#define PHCON2_r9	    (1<<9)
#define PHCON2_r8	    (1<<8)
#define PHCON2_r7	    (1<<7)
#define PHCON2_r6	    (1<<6)
#define PHCON2_r5	    (1<<5)
#define PHCON2_r4	    (1<<4)
#define PHCON2_r3	    (1<<3)
#define PHCON2_FRCLNK    (1<<2)
#define PHCON2_EDSTAT    (1<<1)
#define PHCON2_r0	    (1)

/*  PHSTAT2 bits --------- */
#define PHSTAT2_r15	    (1<<15)
#define PHSTAT2_r14	    (1<<14)
#define PHSTAT2_r13	    (1<<13)
#define PHSTAT2_r12	    (1<<12)
#define PHSTAT2_r11	    (1<<11)
#define PHSTAT2_r10	    (1<<10)
#define PHSTAT2_r9	    (1<<9)
#define PHSTAT2_r8	    (1<<8)
#define PHSTAT2_r7	    (1<<7)
#define PHSTAT2_r6	    (1<<6)
#define PHSTAT2_r5	    (1<<5)
#define PHSTAT2_PLRITY    (1<<4)
#define PHSTAT2_r3	    (1<<3)
#define PHSTAT2_r2	    (1<<2)
#define PHSTAT2_r1	    (1<<1)
#define PHSTAT2_r0	    (1)

/*  PHSTAT3 bits -------- */
#define PHSTAT3_r15	    (1<<15)
#define PHSTAT3_r14	    (1<<14)
#define PHSTAT3_r13	    (1<<13)
#define PHSTAT3_r12	    (1<<12)
#define PHSTAT3_r11	    (1<<11)
#define PHSTAT3_r10	    (1<<10)
#define PHSTAT3_r9	    (1<<9)
#define PHSTAT3_r8	    (1<<8)
#define PHSTAT3_r7	    (1<<7)
#define PHSTAT3_r6	    (1<<6)
#define PHSTAT3_r5	    (1<<5)
#define PHSTAT3_SPDDPX2    (1<<4)
#define PHSTAT3_SPDDPX1    (1<<3)
#define PHSTAT3_SPDDPX0    (1<<2)
#define PHSTAT3_r1	    (1<<1)
#define PHSTAT3_r0	    (1)

/* ------------------------------ internal defaults ---------------------------------- */
/* 33.333Mhz clock out frequency */
#define CLOCK_33_CLR (ECON2_COCON3|ECON2_COCON2|ECON2_COCON1)	/* clr mask */
#define CLOCK_33_SET (ECON2_COCON0)					/* set mask */
/* 25 MHz */
#define CLOCK_25_CLR (ECON2_COCON3|ECON2_COCON2|ECON2_COCON0)	/* clr mask */
#define CLOCK_25_SET (ECON2_COCON1)					/* set mask */
/* 20 MHz */
#define CLOCK_20_CLR (ECON2_COCON3|ECON2_COCON2)			/* clr mask */
#define CLOCK_20_SET (ECON2_COCON1|ECON2_COCON0)			/* set mask */
/* 16 MHz */
#define CLOCK_16_CLR (ECON2_COCON3|ECON2_COCON0|ECON2_COCON1)	/* clr mask */
#define CLOCK_16_SET (ECON2_COCON2)					/* set mask */
/* 4 MHz (after reset) */
#define CLOCK_4_CLR (ECON2_COCON2)					/* clr mask */
#define CLOCK_4_SET (ECON2_COCON3|ECON2_COCON0|ECON2_COCON1)	/* set mask */

#define CLOCK_DEF_CLR CLOCK_33_CLR
#define CLOCK_DEF_SET CLOCK_33_SET

#endif /* _REGISTERS_H_ */
