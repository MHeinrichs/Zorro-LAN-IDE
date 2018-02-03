#define DEBUG 0

/*F*/ /* includes */
#ifndef CLIB_EXEC_PROTOS_H
#include <clib/exec_protos.h>
#include <pragmas/exec_sysbase_pragmas.h>
#endif
#ifndef CLIB_DOS_PROTOS_H
#include <clib/dos_protos.h>
#include <pragmas/dos_pragmas.h>
#endif

#ifndef EXEC_MEMORY_H
#include <exec/memory.h>
#endif

#ifndef DEVICES_SANA2_H
#include <devices/sana2.h>
#endif

#ifndef CLIB_TIME_PROTOS_H
#include <clib/timer_protos.h>
#include <pragmas/timer_pragmas.h>
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
/*E*/

/*F*/ /* defines, types and enums */

   /*
   ** return codes for write_frame()
   */
typedef enum { AW_OK, AW_BUFFER_ERROR, AW_ERROR } AW_RESULT;

   /*
   ** definitions
   */
#define SINGLE_RW	1
#define MAX_READ_PACKAGE	128


/*E*/
/*F*/ /* imports */
   /* external functions */
GLOBAL VOID dotracktype(BASEPTR, ULONG type, ULONG ps, ULONG pr, ULONG bs, ULONG br, ULONG pd);
GLOBAL VOID DevTermIO(BASEPTR, struct IOSana2Req *ios2);
/*E*/
/*F*/ /* exports */
PUBLIC VOID SAVEDS ServerTask(void);
/*E*/
/*F*/ /* private */
PRIVATE struct PLIPBase *startup(void);
PUBLIC REGARGS VOID DoEvent(BASEPTR, long event);
PRIVATE VOID readargs(BASEPTR);
PRIVATE BOOL init(BASEPTR);
PRIVATE REGARGS BOOL goonline(BASEPTR);
PRIVATE REGARGS VOID gooffline(BASEPTR);
PUBLIC REGARGS AW_RESULT write_frame(BASEPTR, struct IOSana2Req *ios2);
PRIVATE REGARGS VOID dowritereqs(BASEPTR);
PRIVATE REGARGS VOID doreadreqs(BASEPTR);
PRIVATE REGARGS VOID dos2reqs(BASEPTR);
/*E*/

   /*
   ** functions to go online/offline
   */
/*F*/ PRIVATE REGARGS VOID rejectpackets(BASEPTR)
{
   struct IOSana2Req *ios2;

   ObtainSemaphore(&pb->pb_WriteListSem);
   while(ios2 = (struct IOSana2Req *)RemHead((struct List*)&pb->pb_WriteList))
   {
      ios2->ios2_Req.io_Error = S2ERR_OUTOFSERVICE;
      ios2->ios2_WireError = S2WERR_UNIT_OFFLINE;
      DevTermIO(pb,ios2);
   }
   ReleaseSemaphore(&pb->pb_WriteListSem);

   ObtainSemaphore(&pb->pb_ReadListSem);
   while(ios2 = (struct IOSana2Req *)RemHead((struct List*)&pb->pb_ReadList))
   {
      ios2->ios2_Req.io_Error = S2ERR_OUTOFSERVICE;
      ios2->ios2_WireError = S2WERR_UNIT_OFFLINE;
      DevTermIO(pb,ios2);
   }
   ReleaseSemaphore(&pb->pb_ReadListSem);

   ObtainSemaphore(&pb->pb_ReadOrphanListSem);
   while(ios2 = (struct IOSana2Req *)RemHead((struct List*)&pb->pb_ReadOrphanList))
   {
      ios2->ios2_Req.io_Error = S2ERR_OUTOFSERVICE;
      ios2->ios2_WireError = S2WERR_UNIT_OFFLINE;
      DevTermIO(pb,ios2);
   }
   ReleaseSemaphore(&pb->pb_ReadOrphanListSem);
}
/*E*/

/*F*/ PRIVATE REGARGS BOOL goonline(BASEPTR)
{
   BOOL rc = TRUE;

   d(("trying to go online\n"));

   if (pb->pb_Flags & PLIPF_OFFLINE)
   {
      if (!hw_attach(pb))
      {
         d(("error going online\n"));
         rc = FALSE;
      }
      else
      {
         struct HWBase *hwb = &pb->pb_HWBase;
         
         /* send magic */
         hw_send_magic_pkt(pb, HW_MAGIC_ONLINE);

         GetSysTime(&pb->pb_DevStats.LastStart);
         pb->pb_Flags &= ~PLIPF_OFFLINE;
         DoEvent(pb, S2EVENT_ONLINE);
         d(("i'm now online!\n"));
      }
   }

   return rc;
}
/*E*/
/*F*/ PRIVATE REGARGS VOID gooffline(BASEPTR)
{
   if (!(pb->pb_Flags & PLIPF_OFFLINE))
   {
      hw_send_magic_pkt(pb, HW_MAGIC_OFFLINE);

      hw_detach(pb);

      pb->pb_Flags |= PLIPF_OFFLINE;

      DoEvent(pb, S2EVENT_OFFLINE);
   }
   d(("ok!\n"));
}
/*E*/

   /*
   ** SANA-2 Event management
   */
/*F*/ PUBLIC REGARGS VOID DoEvent(BASEPTR, long event)
{
   struct IOSana2Req *ior, *ior2;

   d(("event is %lx\n",event));

   ObtainSemaphore(&pb->pb_EventListSem );
   
   for(ior = (struct IOSana2Req *) pb->pb_EventList.lh_Head;
       ior2 = (struct IOSana2Req *) ior->ios2_Req.io_Message.mn_Node.ln_Succ;
       ior = ior2 )
   {
      if (ior->ios2_WireError & event)
      {
         Remove((struct Node*)ior);
         DevTermIO(pb, ior);
      }
   }
   
   ReleaseSemaphore(&pb->pb_EventListSem );
}
/*E*/

   /*
   ** writing packets
   */
/*F*/ PUBLIC REGARGS AW_RESULT write_frame(BASEPTR, struct IOSana2Req *ios2)
{
   AW_RESULT rc;
   struct HWFrame *frame = pb->pb_Frame;
   struct BufferManagement *bm;
   UBYTE *frame_ptr;
   
   d(("write: type %08lx, size %ld\n",ios2->ios2_PacketType,
                                      ios2->ios2_DataLength));

   /* copy raw frame: simply overwrite ethernet frame part of plip packet */
   if(ios2->ios2_Req.io_Flags & SANA2IOF_RAW) {
      frame->hwf_Size = ios2->ios2_DataLength;
      frame_ptr = &frame->hwf_DstAddr[0];
   } else {
      frame->hwf_Size = ios2->ios2_DataLength + HW_ETH_HDR_SIZE;
      frame->hwf_Type = (USHORT)ios2->ios2_PacketType;
      memcpy(frame->hwf_SrcAddr, pb->pb_CfgAddr, HW_ADDRFIELDSIZE);
      memcpy(frame->hwf_DstAddr, ios2->ios2_DstAddr, HW_ADDRFIELDSIZE);
      frame_ptr = (UBYTE *)(frame + 1);
   }

   bm = (struct BufferManagement *)ios2->ios2_BufferManagement;

   if (!(*bm->bm_CopyFromBuffer)(frame_ptr,
                               ios2->ios2_Data, ios2->ios2_DataLength))
   {
      rc = AW_BUFFER_ERROR;
   }
   else
   {
      d8(("+hw_send\n"));
      rc = hw_send_frame(pb, frame) ? AW_OK : AW_ERROR;
      d8(("-hw_send\n"));
#if DEBUG&8
      if(rc==AW_ERROR) d8(("Error sending packet (size=%ld)\n", (LONG)pb->pb_Frame->hwf_Size));
#endif
   }

   return rc;
}
/*E*/
/*F*/ PRIVATE REGARGS VOID dowritereqs(BASEPTR)
{
   struct IOSana2Req *currentwrite, *nextwrite;
   AW_RESULT code;

   ObtainSemaphore(&pb->pb_WriteListSem);

   for(currentwrite = (struct IOSana2Req *)pb->pb_WriteList.lh_Head;
       nextwrite = (struct IOSana2Req *) currentwrite->ios2_Req.io_Message.mn_Node.ln_Succ;
       currentwrite = nextwrite )
   {
      code = write_frame(pb, currentwrite);

      if (code == AW_BUFFER_ERROR)  /* BufferManagement callback error */
      {
         d(("buffer error\n"));
         DoEvent(pb, S2EVENT_ERROR | S2EVENT_BUFF | S2EVENT_SOFTWARE);
         pb->pb_SpecialStats[S2SS_TXERRORS].Count++;
         d(("pb->pb_SpecialStats[S2SS_TXERRORS].Count = %ld\n",pb->pb_SpecialStats[S2SS_TXERRORS].Count));
         currentwrite->ios2_Req.io_Error = S2ERR_SOFTWARE;
         currentwrite->ios2_WireError = S2WERR_BUFF_ERROR;
         Remove((struct Node*)currentwrite);
         DevTermIO(pb, currentwrite);
      }
      else if (code == AW_ERROR)
      {
         /*
         ** this is a real line error, upper levels (e.g. Internet TCP) have
         ** to care for reliability!
         */
         d(("error while transmitting packet\n"));
         DoEvent(pb, S2EVENT_ERROR | S2EVENT_TX | S2EVENT_HARDWARE);
         pb->pb_SpecialStats[S2SS_TXERRORS].Count++;
         d(("pb->pb_SpecialStats[S2SS_TXERRORS].Count = %ld\n",pb->pb_SpecialStats[S2SS_TXERRORS].Count));
         currentwrite->ios2_Req.io_Error = S2ERR_TX_FAILURE;
         currentwrite->ios2_WireError = S2WERR_GENERIC_ERROR;
         Remove((struct Node*)currentwrite);
         DevTermIO(pb, currentwrite);
      }
      else /*if (code == AW_OK)*/                             /* well done! */
      {
         d(("packet transmitted successfully\n"));
         pb->pb_DevStats.PacketsSent++;
         dotracktype(pb, (ULONG) pb->pb_Frame->hwf_Type, 1, 0, currentwrite->ios2_DataLength, 0, 0);
         currentwrite->ios2_Req.io_Error = S2ERR_NO_ERROR;
         currentwrite->ios2_WireError = S2WERR_GENERIC_ERROR;
         Remove((struct Node*)currentwrite);
         DevTermIO(pb, currentwrite);
      }
   }

   ReleaseSemaphore(&pb->pb_WriteListSem);
}
/*E*/

PRIVATE REGARGS BOOL read_frame(struct IOSana2Req *req, struct HWFrame *frame)
{
   int i;
   BOOL broadcast; 
   LONG datasize;
   BYTE *frame_ptr;
   struct BufferManagement *bm;
   BOOL ok;
   
   /* deliver a raw frame: copy data right into ethernet header */
   if(req->ios2_Req.io_Flags & SANA2IOF_RAW) {
      frame_ptr = &frame->hwf_DstAddr[0];
      datasize = frame->hwf_Size;
      req->ios2_Req.io_Flags = SANA2IOF_RAW;
   }
   else {
      frame_ptr = (UBYTE *)(frame + 1);
      datasize = frame->hwf_Size - HW_ETH_HDR_SIZE;
      req->ios2_Req.io_Flags = 0;
   }

   req->ios2_DataLength = datasize;
   
   /* copy packet buffer */
   bm = (struct BufferManagement *)req->ios2_BufferManagement;
   if (!(*bm->bm_CopyToBuffer)(req->ios2_Data, frame_ptr, datasize))
   {
      d(("CopyToBuffer: error\n"));
      req->ios2_Req.io_Error = S2ERR_SOFTWARE;
      req->ios2_WireError = S2WERR_BUFF_ERROR;
      ok = FALSE;
   }
   else
   {
      req->ios2_Req.io_Error = req->ios2_WireError = 0;
      ok = TRUE;
   }
   
   /* now extract addresses from ethernet header */
   memcpy(req->ios2_SrcAddr, frame->hwf_SrcAddr, HW_ADDRFIELDSIZE);
   memcpy(req->ios2_DstAddr, frame->hwf_DstAddr, HW_ADDRFIELDSIZE);
   
   /* need to set broadcast flag? */
   broadcast = TRUE;
   for(i=0;i<HW_ADDRFIELDSIZE;i++) {
      if(frame->hwf_DstAddr[i] != 0xff) {
         broadcast = FALSE;
         break;
      }
   }
   if(broadcast) {
      req->ios2_Req.io_Flags |= SANA2IOF_BCAST;
   }
   
   /* store packet type */
   req->ios2_PacketType = (USHORT)frame->hwf_Type;

   return ok;
}

/*
** reading packets
*/
/*F*/ PRIVATE REGARGS VOID doreadreqs(BASEPTR)
{
	LONG datasize,haverec;
	struct IOSana2Req *got;
	ULONG pkttyp = 0; /* just to avoid warning with opt build, irrelevant otherwise */
	BOOL rv;
	struct HWFrame *frame = pb->pb_Frame;

	haverec = hw_recv_pending(pb);
	/*allow only a certain number of packets to be serverd per interrupt*/

	if(haverec>MAX_READ_PACKAGE){
		haverec = MAX_READ_PACKAGE;
	}
	while(haverec--){
		d8(("+hw_recv\n"));
		rv = hw_recv_frame(pb, frame);
		d8(("-hw_recv\n"));
		if (rv)
		{
			BOOL ok;
			pb->pb_DevStats.PacketsReceived++;

			pkttyp = frame->hwf_Type;

#if 0
			/* perform internal loop back of magic packets of type 0xfffd */
			if(pkttyp == HW_MAGIC_LOOPBACK) {
				d(("loop back packet (size %ld)\n",frame->hwf_Size));
				hw_send_frame(pb, frame);
				return;
			}

			/* plipbox requests online magic (again) */
			if(pkttyp == HW_MAGIC_ONLINE) {
				d(("request online magic"));
				hw_send_magic_pkt(pb, HW_MAGIC_ONLINE);
				return;
			}
#endif
			datasize = frame->hwf_Size - HW_ETH_HDR_SIZE;

			dotracktype(pb, pkttyp, 0, 1, 0, datasize, 0);

			d(("packet %08lx, size %ld received\n",pkttyp,datasize));

			ok = FALSE;
			ObtainSemaphore(&pb->pb_ReadListSem);

			/* traverse the list of read-requests */
			for(got = (struct IOSana2Req *)pb->pb_ReadList.lh_Head;
			got->ios2_Req.io_Message.mn_Node.ln_Succ;
			got = (struct IOSana2Req *)got->ios2_Req.io_Message.mn_Node.ln_Succ )
			{
				/* check if this one requests for the new packet we got */
				if (got->ios2_PacketType == pkttyp )
				{
					Remove((struct Node*)got);
					ok=TRUE; /* mark, that we found the package and quit list traversing */
					break;
				}
			}

			ReleaseSemaphore(&pb->pb_ReadListSem);

			if(ok){
				/* deliver packet */
				ok = read_frame(got, frame);
				if(!ok) {
					DoEvent(pb, S2EVENT_ERROR | S2EVENT_BUFF | S2EVENT_SOFTWARE);
				}

				d(("packet received, satisfying S2Request\n"));
				DevTermIO(pb, got);
				got = NULL; /* delete the request to indicate that we served it*/
			}
			else {
				/* If no one wanted this packet explicitely, there is one chance
				** left: somebody waiting for orphaned packets. If this fails, too,
				** we will drop it.
				*/
				d(("unknown packet\n"));

				pb->pb_DevStats.UnknownTypesReceived++;

				ObtainSemaphore(&pb->pb_ReadOrphanListSem);
				got = (struct IOSana2Req *)RemHead((struct List*)&pb->pb_ReadOrphanList);
				ReleaseSemaphore(&pb->pb_ReadOrphanListSem);

				if (got)
				{
					ok = read_frame(got, frame);
					if(!ok) {
						DoEvent(pb, S2EVENT_ERROR | S2EVENT_BUFF | S2EVENT_SOFTWARE);
					}

					d(("orphan read\n"));

					DevTermIO(pb, got);
				}
				else
				{
					dotracktype(pb, pkttyp, 0, 0, 0, 0, 1);
					d(("packet thrown away...\n"));
				}
			}
		}
		else
		{
			d(("Error receiving (%ld. len=%ld)\n", rv, frame->hwf_Size));
			/* something went wrong during receipt */
			DoEvent(pb, S2EVENT_HARDWARE | S2EVENT_ERROR | S2EVENT_RX);
			got = NULL;
			pb->pb_DevStats.BadData++;
		}
	}
}
/*E*/

   /*
   ** 2nd level device command dispatcher (~SANA2IOF_QUICK)
   */
/*F*/ PRIVATE REGARGS VOID dos2reqs(BASEPTR)
{
   struct IOSana2Req *ios2;

   /*
   ** Every pending IO message will be GetMsg()'ed and processed. At the
   ** end of the loop it will be DevTermIO()'ed back to the sender,
   ** _but_only_if_ it is non-NULL. In such cases the message has been
   ** put in a separate queue to be DevTermIO()'ed later (i.e. CMD_WRITEs
   ** and similar stuff).
   ** You find the same mimique in the 1st level dispatcher (device.c)
   */
   while(ios2 = (struct IOSana2Req *)GetMsg(pb->pb_ServerPort))
   {
      if (hw_recv_pending(pb))
      {
         d(("incoming data!"));
         break;
      }

      d(("sana2req %ld from serverport\n", ios2->ios2_Req.io_Command));

      switch (ios2->ios2_Req.io_Command)
      {
         case S2_ONLINE:
            if (!goonline(pb))
            {
               ios2->ios2_Req.io_Error = S2ERR_NO_RESOURCES;
               ios2->ios2_WireError = S2WERR_GENERIC_ERROR;
            }
         break;

         case S2_OFFLINE:
            gooffline(pb);
            rejectpackets(pb); /* reject all pending requests */
         break;

         case S2_CONFIGINTERFACE:
            /* copy address from src addr */
            memcpy(pb->pb_CfgAddr, ios2->ios2_SrcAddr, HW_ADDRFIELDSIZE);
            
            /* if already online then first go offline */
            if(!(pb->pb_Flags & PLIPF_OFFLINE)) {
               gooffline(pb);
            }
            
            /* now go online */
            if (!goonline(pb))
            {
               ios2->ios2_Req.io_Error = S2ERR_NO_RESOURCES;
               ios2->ios2_WireError = S2WERR_GENERIC_ERROR;
            }
         break;
      }

      if (ios2) DevTermIO(pb,ios2);
   }
}
/*E*/

   /*
   ** startup,initialisation and termination functions
   */
/*F*/ PRIVATE struct PLIPBase *startup(void)
{
   struct ServerStartup *ss;
   struct Process *we;
   struct PLIPBase *base;
   LOCALSYSBASE;

   we = (struct Process*)FindTask(NULL);

   d(("waiting for startup msg...\n"));
   WaitPort(&we->pr_MsgPort);
   ss = (struct ServerStartup *)GetMsg(&we->pr_MsgPort);
   base = ss->ss_PLIPBase;
   base->pb_Startup = ss;
   d(("go startup msg at %lx, PLIPBase is %lx\n", ss, ss->ss_PLIPBase));

   /* we will keep the startup message, to inform mother if we
   ** really could come up or if we failed to obtain some
   ** resource.
   */
   return base;
}
/*E*/

#define PLIP_MINPRIORITY         -128
#define PLIP_MAXPRIORITY         127

/*F*/ PRIVATE VOID readargs(BASEPTR)
{
   struct RDArgs *rda;
   struct TemplateConfig args = { 0 };
   BPTR cfginput, oldinput;

   d(("entered\n"));

   hw_config_init(pb);

   if (cfginput = Open(CONFIGFILE, MODE_OLDFILE))
   {
      d(("opened cfg\n"));
      oldinput = SelectInput(cfginput);      
      rda = ReadArgs(COMMON_TEMPLATE TEMPLATE, (LONG *)&args, NULL);
      if(rda)
      {
         d(("got args\n"));

         /* common options */
         if (args.common.priority)
            SetTaskPri((struct Task*)pb->pb_Server,
                  BOUNDS(*args.common.priority, PLIP_MINPRIORITY, PLIP_MAXPRIORITY));

         if (args.common.nospecialstats)
            pb->pb_ExtFlags |= PLIPEF_NOSPECIALSTATS;

         if(args.common.mtu)
            pb->pb_MTU = *args.common.mtu;

         if(args.common.bps)
            pb->pb_BPS = *args.common.bps;

         /* special config */
         hw_config_update(pb, &args);

         FreeArgs(rda);
      }

      Close(SelectInput(oldinput));
   }

   /* dump default config options */
   d(("pri %ld, flags %08lx\n", (LONG)pb->pb_Server->pr_Task.tc_Node.ln_Pri, pb->pb_Flags));
   hw_config_dump(pb);

   d(("left\n"));
}
/*E*/
/*F*/ PRIVATE BOOL init(BASEPTR)
{
   BOOL rc = FALSE;

   readargs(pb);
      
   if ((pb->pb_ServerPort = CreateMsgPort()))
   {  
      /* init hardware */
      if(hw_init(pb)) {
         ULONG size = (ULONG)sizeof(struct HWFrame);

	 if( pb->pb_MTU > 1518 )
		size += pb->pb_MTU + 16;
	 else	size += 1518 + 4;

         d(("allocating 0x%lx/%ld bytes frame buffer\n",size,size));
         if ((pb->pb_Frame = AllocVec(size, MEMF_CLEAR|MEMF_ANY)))
         {
            rc = TRUE;
         }
         else
         {
            d(("couldn't allocate frame buffer\n"));
         }
      }
      else
      {
         d(("hw init failed\n"));
      }
   }
   else
   {
      d(("no server port\n"));
   }

   d(("left %ld\n",rc));

   return rc;
}
/*E*/
/*F*/ PRIVATE VOID cleanup(BASEPTR)
{
   struct BufferManagement *bm;

   gooffline(pb);

   while(bm = (struct BufferManagement *)RemHead((struct List *)&pb->pb_BufferManagement))
      FreeVec(bm);

   if (pb->pb_Frame) FreeVec(pb->pb_Frame);

   hw_cleanup(pb);

   if (pb->pb_ServerPort) DeleteMsgPort(pb->pb_ServerPort);

   if (pb->pb_Flags & PLIPF_REPLYSS)
   {
      Forbid();
      ReplyMsg((struct Message*)pb->pb_Startup);
   }
}
/*E*/

   /*
   ** entry point, mainloop
   */
/*F*/ PUBLIC VOID SAVEDS ServerTask(void)
{
   BASEPTR;

   d(("server running\n"));

   if (pb = startup())
   {      
         /* if we fail to allocate all resources, this flag reminds cleanup()
         ** to ReplyMsg() the startup message
         */
      pb->pb_Flags |= PLIPF_REPLYSS;

      if (init(pb))
      {
         ULONG recv=0, portsigmask, recvsigmask, wmask,specialmask;
         LONG  haverec;
         BOOL running;
         struct IOSana2Req *wr;

         /* Ok, we are fine and will tell this mother personally :-) */
         pb->pb_Startup->ss_Error = 0;
         /* don't forget this, or we will have to keep a warm place */
         /* in our coffin for the system */
         pb->pb_Flags &= ~PLIPF_REPLYSS;
         ReplyMsg((struct Message*)pb->pb_Startup);

         portsigmask = 1 << pb->pb_ServerPort->mp_SigBit;
         recvsigmask = hw_recv_sigmask(pb);
         specialmask = portsigmask | SIGBREAKF_CTRL_C;
      
         wmask = SIGBREAKF_CTRL_F | SIGBREAKF_CTRL_C | portsigmask | recvsigmask;

         /* main loop of server task */
         d(("--- server main loop: %08lx ---\n", wmask));
         for(running=TRUE;running;)
         {
            d4(("** wmask is 0x%08lx\n", wmask));

            /* send packets if any */
            d2(("*+ do_write\n"));
			      wr = (struct IOSana2Req *)pb->pb_WriteList.lh_Head;
            if( wr->ios2_Req.io_Message.mn_Node.ln_Succ )
            {
	            dowritereqs(pb);
	          }
            d2(("*- do_write\n"));

            /* if no recv is pending then wait for incoming signals */
		        haverec = hw_recv_pending(pb);
		        recv = 0;
	          if( !haverec )
    	      {
        	       d2(("**> wait\n"));
        	       hw_enable_global_int(pb);
        	       recv = Wait(wmask);
            	   d2(("**> wait: got 0x%08lx\n", recv));
            	   haverec = hw_recv_pending(pb);
            }
						hw_disable_global_int(pb);

            /* accept pending receive and start reading */
            if( haverec>0 )
            {
               d2(("*+ do_read\n"));
               doreadreqs(pb);
               d2(("*- do_read\n"));
            }

		        if( recv & specialmask )
		        {
            	/* handle SANA-II send requests */
            	if (recv & portsigmask)
            	{
            	   d(("SANA-II request(s)\n"));
            	   dos2reqs(pb);
            	   recv &= ~portsigmask;
            	}
	            /* stop server task */
    	        if (recv & SIGBREAKF_CTRL_C)
    	        {
        	       d(("received break signal\n"));
        	       running = FALSE;
        	    }
        	  }
         } /*main loop of server task*/
      }
      else
         d(("init() failed\n"));

      d(("--- server exit main loop ---\n"));
      cleanup(pb);

      /* Exec will enable it's scheduler after we're dead. */
      Forbid();
      /* signal mother we're done */
      if (pb->pb_ServerStoppedSigMask)
         Signal(pb->pb_Task, pb->pb_ServerStoppedSigMask);
      pb->pb_Flags |= PLIPF_SERVERSTOPPED;
   }
   else
      d(("no startup packet\n"));
}
/*E*/

