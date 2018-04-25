/*
 * hw.c - hardware dependent part of driver
 */

#define DEBUG 0
/* 15 */

/*F*/ /* includes */
#ifndef CLIB_EXEC_PROTOS_H
#include <clib/exec_protos.h>
#include <pragmas/exec_sysbase_pragmas.h>
#endif
#ifndef CLIB_DOS_PROTOS_H
#include <clib/dos_protos.h>
#include <pragmas/dos_pragmas.h>
#endif
#ifndef CLIB_CIA_PROTOS_H
#include <clib/cia_protos.h>
#include <pragmas/cia_pragmas.h>
#endif
#ifndef CLIB_MISC_PROTOS_H
#include <clib/misc_protos.h>
#include <pragmas/misc_pragmas.h>
#endif
#ifndef CLIB_TIME_PROTOS_H
#include <clib/timer_protos.h>
#include <pragmas/timer_pragmas.h>
#endif
#ifndef CLIB_UTILITY_PROTOS_H
#include <clib/utility_protos.h>
#include <pragmas/utility_pragmas.h>
#endif

#ifndef EXEC_MEMORY_H
#include <exec/memory.h>
#endif
#ifndef EXEC_INTERRUPTS_H
#include <exec/interrupts.h>
#endif
#ifndef EXEC_DEVICES_H
#include <exec/devices.h>
#endif
#ifndef EXEC_IO_H
#include <exec/io.h>
#endif

#ifndef DEVICES_SANA2_H
#include <devices/sana2.h>
#endif

#ifndef HARDWARE_CIA_H
#include <hardware/cia.h>
#endif

#include <hardware/intbits.h>

#ifndef RESOURCES_MISC_H
#include <resources/misc.h>
#endif

#ifndef _STRING_H
#include <string.h>
#endif

#ifndef __GLOBAL_H
#include "global.h"
#endif
#ifndef __DEBUG_H
#include "debug.h"
#endif
#ifndef __COMPILER_H
#include "compiler.h"
#endif
#ifndef __HW_H
#include "hw.h"
#endif
#include "dev_info.h"

#ifdef PROTO_SDNET
#include "enc28j60.h"
#define  HW_INTERVALDEF 10000L
#endif
#ifdef PROTO_ENC624NET
#include "enc624j6l.h"
#include "registers.h"

/* 10000 without HW interrupt 100000 with HW interrupt */
#define  HW_INTERVALDEF 100000L

/* this is a BIG TODO! Make plipbox source multi-board aware */
#define  BOARD hwb->hwb_boards[0]

/* interrupt (choice here is INTB_EXTER or INTB_PORTS, depending on solder blob */
/*#define  HW_INTSOURCE INTB_EXTER */ /* Int 6 */
#define  HW_INTSOURCE INTB_PORTS /* Int 2 */

/* write_frame, see server.c, too. .oO(move this into .h) */
typedef enum { AW_OK, AW_BUFFER_ERROR, AW_ERROR } AW_RESULT;

#define READREG(_x_,_off_)      *( (volatile USHORT*)( (volatile UBYTE*)(_x_) + (_off_)) )
#define WRITEREG(_x_,_off_,_y_) *( (volatile USHORT*)( (volatile UBYTE*)(_x_) + (_off_)) )    = (_y_);
#define SETREG(_x_,_off_,_y_)   *( (volatile USHORT*)( (volatile UBYTE*)(_x_) + (_off_) + SET_OFFSET )) = (_y_);
#define CLRREG(_x_,_off_,_y_)   *( (volatile USHORT*)( (volatile UBYTE*)(_x_) + (_off_) + CLR_OFFSET )) = (_y_);

#endif

/* this is currently necessary on Apollo Core. We don't have an interrupt on the SD card slot */
/* used also with ENC624 (albeit with 10x longer default waiting) should we miss some interrupts */
#include "intervaltimer.h"
#define  HW_INTERVAL
#define  HW_INTERVALMIN 2500L
#define  HW_INTERVALMAX 500000L

/* TODO: remove. I think I won't need this for the SDnet */
PRIVATE ULONG ASM SAVEDS exceptcode(REG(d0) ULONG sigmask, REG(a1) struct PLIPBase *hwb);

const char *intname = "ENC624Net_HWInterrupt";


/* just to make SAS/C happy, no other function */
int _avoid_sasc_warning_about_global_symbols( void );
int _avoid_sasc_warning_about_global_symbols( void )
{
 return 0;
}

#ifdef PROTO_ENC624NET
PRIVATE void stopInt(struct PLIPBase *pb, struct HWBase *hwb, APTR board )
{
	if( hwb->hwb_Interrupt.is_Data )
	{
		hwb->hwb_Interrupt.is_Data = (0);
		enc624j6l_DisableInterrupt( board );

		RemIntServer( HW_INTSOURCE, &hwb->hwb_Interrupt );
	    hwb->hwb_Interrupt.is_Code = (0);
	}
}

PRIVATE void startInt(struct PLIPBase *pb, struct HWBase *hwb, APTR board )
{
	if( hwb->hwb_Interrupt.is_Data )
		stopInt( pb, hwb, board );

	enc624j6l_EnableInterrupt( BOARD, FindTask(0), (int)hwb->hwb_IntSig, 0 );
	
	hwb->hwb_Interrupt.is_Code = (void(*)())enc624j6l_IntServer;
	hwb->hwb_Interrupt.is_Data = board;
	hwb->hwb_Interrupt.is_Node.ln_Type = NT_INTERRUPT;
	hwb->hwb_Interrupt.is_Node.ln_Pri = 51;
	hwb->hwb_Interrupt.is_Node.ln_Name = (char*)intname;
	AddIntServer( HW_INTSOURCE, &hwb->hwb_Interrupt );
}
#endif

/* write_frame moved from server.c to here, because it directly interfaces with
   network module in this driver, active only when ENC624_OPT is given on compiler
   command line */
#ifdef ENC624_OPT
   /*
   ** write frames direcly to HW
   * CAUTION: don't mix up with hw_send_frame() / enc624j6l_TransmitFrame -- 
   *          the double buffered write location is not shared right now
   * 
   * logic in here
   *  - swap buffer
   *  - write into buffer
   *  - wait for previous frame to finish (most likely there is no waiting time)
   *  - issue HW TX command
   *
   */
/*F*/ GLOBAL REGARGS AW_RESULT write_frame(BASEPTR, struct IOSana2Req *ios2)
{
   AW_RESULT rc;
   struct HWBase *hwb = &pb->pb_HWBase;

   struct BufferManagement *bm;
   ULONG tl,totsize;
   unsigned short *s_wrptr,*s_tmp1;
   UBYTE *b_hwio_ptr = BOARD; /* somewhere $e80000 and beyond */

   /* Note Link Change check moved to main loop */

   d(("owrite: type %08lx, size %ld\n",ios2->ios2_PacketType,
                                       ios2->ios2_DataLength));

   hwb->hwb_txdbuf = (hwb->hwb_txdbuf & PSwapTX) ^ PSwapTX; /* swap buffers (+sanity check by "&") */
   s_wrptr = (USHORT*)(b_hwio_ptr + hwb->hwb_txdbuf);         /* next write location (byte->short)   */

   if(!(ios2->ios2_Req.io_Flags & SANA2IOF_RAW)) 
   {  /* structured SANAII Request, not a valid Ethernet Frame (yet) */
      /* Q: What about a length field and SNAP ? -> relevant here? */

      /* write Ethernet header by hand: DMAC,SMAC,TYPE */
      s_tmp1 = (USHORT*)ios2->ios2_DstAddr;
      *s_wrptr++ = *s_tmp1++; *s_wrptr++ = *s_tmp1++; *s_wrptr++ = *s_tmp1; /* copy 6 bytes */

      s_tmp1 = (USHORT*)pb->pb_CfgAddr;
      *s_wrptr++ = *s_tmp1++; *s_wrptr++ = *s_tmp1++; *s_wrptr++ = *s_tmp1; /* copy 6 bytes */

      *s_wrptr++ = (USHORT)ios2->ios2_PacketType; /* copy 2 bytes TYPE field */

      totsize = HW_ETH_HDR_SIZE + ios2->ios2_DataLength; /* 14; */
   }
   else
   {  /* RAW, pre-formatted Ethernet frame (sans CRC32) */
      totsize = ios2->ios2_DataLength; /* */
   }

   /* copy frame to HW without a step in between (i.e. directly to mmapped card) */
   bm = (struct BufferManagement *)ios2->ios2_BufferManagement;

   if( (*bm->bm_CopyFromBuffer)(s_wrptr, ios2->ios2_Data, ios2->ios2_DataLength) )
   { 
      /* buffer delivered to HW, now trigger actual TX */
      /* waste time should the last frame still be in TX (unlikely) */
      /* 100 MBit/s frame time is max. 0.12 ms (without inter-frame spacing) */
      tl=0;
      while( READREG(b_hwio_ptr,ECON1) & ECON1_TXRTS ) 
      { 
         if( ++tl > 100000 ) /* this read cylces through ZII/ZIII and still not finished ? */
         {
                CLRREG( b_hwio_ptr, ECON1, ECON1_TXRTS ); /* give up, cancel last transmission */
                break;
         }
      }

      /*------ set new frame parameters ----------- */
      WRITEREG( b_hwio_ptr, ETXST, hwb->hwb_txdbuf ); /* write location */
      WRITEREG( b_hwio_ptr, ETXLEN,totsize );         /* frame TX length (-CRC) */
      SETREG(   b_hwio_ptr, ECON1, ECON1_TXRTS );     /* trigger TX */

      rc = AW_OK;
   }
   else
   {
      /* meh: What's so hard about copying some bytes ? */
      rc = AW_BUFFER_ERROR;
   }

   return rc;
}
#endif

   /*
   ** check for link change
   * - call ASM file for that task
   * - the relevant flag is set by the interrupt handler and in that case,
   *   a number of registers is reconfigured accordingly
   *
   */
/*F*/ GLOBAL REGARGS void hw_check_link_change( BASEPTR )
{
   struct HWBase *hwb = &pb->pb_HWBase;

   enc624j6l_CheckLinkChange(BOARD); /* somewhere $e80000 and beyond */
}


/* 
  magic: HW_MAGIC_OFFLINE, HW_MAGIC_ONLINE
  return TRUE/FALSE
*/
GLOBAL REGARGS BOOL hw_send_magic_pkt(struct PLIPBase *pb, USHORT magic)
{
  struct HWBase *hwb = &pb->pb_HWBase;

   if( magic == HW_MAGIC_ONLINE )
   {
#ifdef PROTO_ENC624NET
	enc624j6l_SetMAC( BOARD, pb->pb_CfgAddr );
    enc624j6l_SetOnline( BOARD );
    startInt(pb, hwb, BOARD );
#else
	enc28j60_setMAC( pb->pb_CfgAddr ); /* update MAC address (just in case) */
	enc28j60_setOnline(); /* acticate RX */
#endif
#ifdef HW_INTERVAL
	StartIntervalTimer( &hwb->hwb_ivtimer, hwb->hwb_timervalue ); /* 10000L */
#endif
   }
   if( magic == HW_MAGIC_OFFLINE )
   {
#ifdef PROTO_ENC624NET
    stopInt(pb, hwb, BOARD );
	enc624j6l_SetOffline( BOARD );
#else
	enc28j60_setOffline(); /* stop RX */
#endif
#ifdef HW_INTERVAL
	StopIntervalTimer( &hwb->hwb_ivtimer );
#endif
   }

   return TRUE;
}

/*
  setup defaults in plipbase
*/
GLOBAL REGARGS void hw_config_init(struct PLIPBase *pb)
{
  struct HWBase *hwb = &pb->pb_HWBase;

  hwb->hwb_timervalue = HW_INTERVALDEF;
  hwb->hwb_fullduplex = 0;
#ifndef PROTO_ENC624NET  
  hwb->hwb_spispeed   = 1; /* optimistic default */
#endif
  hwb->hwb_multicast  = 0;
  hwb->hwb_flowcontrol= 0; /* no flow control by default */
}


GLOBAL REGARGS void hw_config_update(struct PLIPBase *pb, struct TemplateConfig *args)
{
  struct HWBase *hwb = &pb->pb_HWBase;
 
  if( args->timervalue )
  {
	hwb->hwb_timervalue = BOUNDS(*args->timervalue, HW_INTERVALMIN, HW_INTERVALMAX );
  }
#ifndef PROTO_ENC624NET
  if( args->spispeed )
  {
	hwb->hwb_spispeed = BOUNDS(*args->spispeed, 1, 20 );
  }
#endif
  if( args->fullduplex )
  {
	hwb->hwb_fullduplex = 1;
  }
  if( args->multicast )
  {
  	hwb->hwb_multicast = 1;
  }
  if( args->flowcontrol )
  {
  	hwb->hwb_flowcontrol = 1;
  }
}



GLOBAL REGARGS void hw_config_dump(struct PLIPBase *pb)
{
/*
#if DEBUG & 1
  struct HWBase *hwb = &pb->pb_HWBase;
#endif
  d(("timeOut %ld.%ld\n", hwb->hwb_TimeOutSecs, hwb->hwb_TimeOutMicros));
  d(("burstSize %ld\n", (ULONG)hwb->hwb_BurstSize));
*/
}



GLOBAL REGARGS BOOL hw_init(struct PLIPBase *pb)
{
   struct HWBase *hwb = &pb->pb_HWBase;
   /*ULONG tst;*/
   
   BOOL rc = FALSE;
   
   /* clone sys base, process */
   hwb->hwb_SysBase = pb->pb_SysBase;
   hwb->hwb_Server = pb->pb_Server;
   hwb->hwb_MaxFrameSize = (UWORD)pb->pb_MTU + HW_ETH_HDR_SIZE;
   d2(("sysbase=%08lx, server=%08lx, hwb=%08lx, maxFrameSize=%ld\n",
      hwb->hwb_SysBase, hwb->hwb_Server, hwb, (ULONG)hwb->hwb_MaxFrameSize));

   hwb->hwb_Interrupt.is_Data = (0);	/* prepare interrupt */
   hwb->hwb_Interrupt.is_Code = (0);
   /*tst = AllocSignal(-1);*/
   /* interesting: we get CTRL-F by default. Indidentally the same signal used for the write queue */
   if ((hwb->hwb_IntSig = AllocSignal(-1)) != -1)
   {
      hwb->hwb_IntSigMask = 1L << hwb->hwb_IntSig;
      d2(("int sigmask=%08lx\n",hwb->hwb_IntSigMask));
      /*FreeSignal(tst);*/

      if ((hwb->hwb_TimeoutPort = CreateMsgPort()))
      {
         ULONG sigmask;
         struct Process *proc = pb->pb_Server;
         
         /* save old exception setup */
         hwb->hwb_OldExcept = SetExcept(0, 0xffffffff); /* turn'em off */
         hwb->hwb_OldExceptCode = proc->pr_Task.tc_ExceptCode;
         hwb->hwb_OldExceptData = proc->pr_Task.tc_ExceptData;

         /* create new exception setup */
         proc->pr_Task.tc_ExceptCode = (APTR)&exceptcode;
         proc->pr_Task.tc_ExceptData = (APTR)pb;
         sigmask = 1 << hwb->hwb_TimeoutPort->mp_SigBit;
         SetSignal(0, sigmask);
         SetExcept(sigmask, sigmask);

         /* enter port address */
         hwb->hwb_TimeoutReq.tr_node.io_Message.mn_ReplyPort = hwb->hwb_TimeoutPort;
         if (!OpenDevice("timer.device", UNIT_MICROHZ, (struct IORequest*)&hwb->hwb_TimeoutReq, 0))
         {
             TimerBase = (struct Library *)hwb->hwb_TimeoutReq.tr_node.io_Device;

             /* setup the timeout stuff */
             hwb->hwb_TimeoutReq.tr_node.io_Flags = IOF_QUICK;
             hwb->hwb_TimeoutReq.tr_node.io_Command = TR_ADDREQUEST;
             hwb->hwb_TimeoutSet = 0xff;
#ifdef HW_INTERVAL
	     if( InitIntervalTimer( &hwb->hwb_ivtimer ) > 0 )
	     {
		hwb->hwb_IntervalSigMask = hwb->hwb_ivtimer.IVT_Signal;
	     }
	     else
	     {
	     	d(("couldn't open Interval Timer"));
	     }
#endif
             rc = TRUE;
          }
          else
          {
             d(("couldn't open timer.device"));
          }
       }
       else
       {
          d(("no port for timeout handling\n"));
       }
    } 
    else 
    {
       d(("no interrupt signal\n",rc));
    }
    
    return rc;              
}


GLOBAL REGARGS VOID hw_cleanup(struct PLIPBase *pb)
{
   struct HWBase *hwb = &pb->pb_HWBase;

#ifdef HW_INTERVAL
   ExitIntervalTimer( &hwb->hwb_ivtimer );
#endif
  
   if (hwb->hwb_TimeoutPort)
   {
      struct Process *proc = pb->pb_Server;
      
      /* restore old exception setup */
      SetExcept(0, 0xffffffff);    /* turn'em off */
      proc->pr_Task.tc_ExceptCode = hwb->hwb_OldExceptCode;
      proc->pr_Task.tc_ExceptData = hwb->hwb_OldExceptData;
      SetExcept(hwb->hwb_OldExcept, 0xffffffff);

      if (TimerBase)
      {
         WaitIO((struct IORequest*)&hwb->hwb_TimeoutReq);
         CloseDevice((struct IORequest*)&hwb->hwb_TimeoutReq);
      }
      DeleteMsgPort(hwb->hwb_TimeoutPort);
   }
   
   if (hwb->hwb_IntSig != -1) {
      FreeSignal(hwb->hwb_IntSig);
   }
}


/*
 * hwattach - setup hardware if device gets online
 */
GLOBAL REGARGS BOOL hw_attach(struct PLIPBase *pb)
{
   struct HWBase *hwb = &pb->pb_HWBase;
   BOOL rc = TRUE;
   unsigned char flags;
   
   flags = PIO_INIT_BROAD_CAST;
   if( hwb->hwb_multicast )
	   flags |= PIO_INIT_MULTI_CAST;
   if( hwb->hwb_fullduplex )
	   flags |= PIO_INIT_FULL_DUPLEX;
   if( hwb->hwb_flowcontrol )
	   flags |= PIO_INIT_FLOW_CONTROL;
#ifdef PROTO_ENC624NET
   if( enc624j6l_Init( BOARD, (unsigned long)flags ) <= 0 )
	   rc = FALSE; /* ERROR IN CASE OF DEVICE NOT FOUND */
#else
   if( enc28j60_init( pb->pb_CfgAddr, flags ) != PIO_OK )
   	rc = FALSE;	/* ERROR IN CASE OF DEVICE NOT FOUND */
   enc28j60_SetSPISpeed( (unsigned long)hwb->hwb_spispeed );
#endif

   return rc;
}

/*
 * shutdown hardware if device gets offline
 */
GLOBAL REGARGS VOID hw_detach(struct PLIPBase *pb)
{
#ifdef PROTO_ENC624NET
    struct HWBase *hwb = &pb->pb_HWBase;

    stopInt(pb, hwb, BOARD );
	enc624j6l_Shutdown( BOARD );
#else
   enc28j60_exit();
#endif
}

PRIVATE ULONG ASM SAVEDS exceptcode(REG(d0) ULONG sigmask, REG(a1) struct PLIPBase *pb)
{
   struct HWBase *hwb = &pb->pb_HWBase;
   
   d8(("+ex\n"));
   
   /*extern void KPrintF(char *,...);
   KPrintF("exceptcode\n");*/

   /* remove the I/O Block from the port */
   WaitIO((struct IORequest*)&hwb->hwb_TimeoutReq);

   /* this tells the xfer routines to cease polling */
   hwb->hwb_TimeoutSet = 0xff;
   
   d8(("-ex\n"));
   return sigmask;            /* re-enable the signal */
}


GLOBAL REGARGS BOOL hw_send_frame(struct PLIPBase *pb, struct HWFrame *frame)
{
   BOOL rc = TRUE;
#ifdef PROTO_ENC624NET
   struct HWBase *hwb = &pb->pb_HWBase;
   unsigned char *frm = (unsigned char*)frame;
   enc624j6l_TransmitFrame( BOARD, frm+sizeof(USHORT), frame->hwf_Size );
;   frame->hwf_Size = 0;
#else
   const u08 *frm = (const u08*)frame;
   enc28j60_send(frm+sizeof(USHORT), frame->hwf_Size );
#endif
   return rc;
}


GLOBAL REGARGS LONG hw_recv_pending(struct PLIPBase *pb)
{
#ifdef PROTO_ENC624NET
   struct HWBase *hwb = &pb->pb_HWBase;
   LONG num = enc624j6l_HaveRecv( BOARD );
#else
   u08 num;
   num = enc28j60_has_recv();
#endif
   return (LONG)num;
}

GLOBAL REGARGS void hw_enable_global_int(struct PLIPBase *pb){
#ifdef PROTO_ENC624NET
   struct HWBase *hwb = &pb->pb_HWBase;
   enc624j6l_EnableGlobalInterrupt( BOARD );
#endif
}

GLOBAL REGARGS void hw_disable_global_int(struct PLIPBase *pb){
#ifdef PROTO_ENC624NET
   struct HWBase *hwb = &pb->pb_HWBase;
   enc624j6l_DisableGlobalInterrupt( BOARD );
#endif
}



/* important: don't call this without enc28j60_has_recv() > 0 check */
GLOBAL REGARGS BOOL hw_recv_frame(struct PLIPBase *pb, struct HWFrame *frame)
{
#ifdef PROTO_ENC624NET
   int len;
   BOOL rc = FALSE;
   unsigned char *ptr = (unsigned char*)frame;
   struct HWBase *hwb = &pb->pb_HWBase;

   len = enc624j6l_RecvFrame( BOARD, ptr+sizeof(USHORT), 1522 );
   frame->hwf_Size = len;

   if( len > 0 )
   	rc = TRUE;
#else
   BOOL rc = FALSE;
   u08 *ptr = (u08*)frame;

   if( PIO_OK == enc28j60_recv( ptr+sizeof(USHORT), 1518, &frame->hwf_Size ) )
   	rc = TRUE;

#endif
   return rc;
}

GLOBAL REGARGS ULONG hw_recv_sigmask(struct PLIPBase *pb)
{
   struct HWBase *hwb = &pb->pb_HWBase;
   return hwb->hwb_IntSigMask | hwb->hwb_IntervalSigMask;
}
