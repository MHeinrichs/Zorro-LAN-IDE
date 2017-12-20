/* hwbase.h - hardware specific part of driver structure */
#ifndef __HWBASE_H
#define __HWBASE_H

#include "intervaltimer.h"

/* ----- base structure for hardware ----- */

/* reported BPS (bits! per second) for this device */
#define HW_BPS (10000000L) /* 10 MBit/s */

/* ENC624: MAX. Zorro Boards (untested, probably doesn't work) */
#define HW_MAXBOARDS 3

struct HWBase
{
   /* used in asm module */
   struct Library          *   hwb_SysBase;
   struct Process          *   hwb_Server;
   ULONG                       hwb_IntSigMask;
   UWORD                       hwb_MaxFrameSize;
   volatile UBYTE              hwb_TimeoutSet;/* if != 0, a timeout occurred */
   volatile UBYTE              hwb_Flags;
   /* NOT used in asm */
   ULONG                       hwb_IntSig;        /* sent from int to server */
   ULONG                       hwb_IntervalSigMask;
   struct MsgPort          *   hwb_TimeoutPort;      /* for timeout handling */
   struct Library          *   hwb_TimerBase;
   struct Library          *   hwb_MiscBase;          /* various libs & res. */
   APTR                        hwb_OldExceptCode;
   APTR                        hwb_OldExceptData;
   ULONG                       hwb_OldExcept;
   struct Interrupt            hwb_Interrupt;        /* for AddICRVector() */
   struct timerequest          hwb_TimeoutReq;       /* for timeout handling */
   ULONG                       hwb_AllocFlags;
   APTR						   hwb_boards[HW_MAXBOARDS+1]; /* 0-terminated */

   struct  IVT_TimerStruct     hwb_ivtimer; /* Timer interval handling (via Interrupt) */

   /* config options */
   ULONG                       hwb_timervalue;    /* timer speed */
   ULONG                       hwb_fullduplex;    /* full duplex */
   ULONG                       hwb_spispeed;      /* SPI speed   */
   ULONG                       hwb_multicast;     /* multicast enable */
};

#define HWB_RECV_PENDING           0
#define HWB_COLL_TIMER_RUNNING     1

#define HWF_RECV_PENDING           (1 << HWB_RECV_PENDING)

/* transparently map proto lib bases to structure */
#define MiscBase     hwb->hwb_MiscBase
#define CIAABase     hwb->hwb_CIAABase
#define CiaBase      hwb->hwb_CIAABase
#define TimerBase    hwb->hwb_TimerBase

/* ----- config ----- */

#define CONFIGFILE "ENV:SANA2/sdnet.config"
#define TEMPLATE "TIMER/K/N,FULLDUPLEX/S,SPISPEED/K/N,MULTICAST/S"

/* structure to be filled by ReadArgs template */ 
struct TemplateConfig
{
   struct CommonConfig common;
   ULONG *timervalue;
   ULONG fullduplex;
   ULONG *spispeed;
   ULONG multicast;
};

#endif
