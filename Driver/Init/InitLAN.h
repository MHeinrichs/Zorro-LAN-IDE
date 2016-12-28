#include <exec/memory.h>
#include <exec/lists.h>
#include <exec/nodes.h>
#include <stdlib.h>
#include <stdio.h>
#include <libraries/expansion.h>
#include <libraries/expansionbase.h>
#include <libraries/configvars.h>
#include <libraries/configregs.h>
#include <dos/filehandler.h>
#include <resources/filesysres.h>
#include <clib/exec_protos.h>
#include <clib/expansion_protos.h>
#include "ENCX24J600.h"

#define VERSION_STRING "1.1"
#define CIA_TST     (*(volatile BYTE *)(0XBFE301)) //cia call 1.4micro sec
#define CHP_TST     (*(volatile WORD *)(0X000004)) //chip mem call 400ns
#define WRITEREG(a,b,c)		(*(volatile WORD *)((a)+(b)))=((WORD)(c))
#define READREG(a,b)		((WORD)(*(volatile WORD *)((a)+(b))))
#define SETREG(a,b,c)		(*(volatile WORD *)((a)+(b)+(SET_OFFSET)))=((WORD)(c))
#define CLRREG(a,b,c)		(*(volatile WORD *)((a)+(b)+(CLR_OFFSET)))=((WORD)(c))


struct Library *ExpansionBase=NULL;
unsigned long hex2int(char *a);
int SoftReset(APTR *BaseAddress);
APTR LocateBoard(int manufactor, int product);

/**
   Function to wait for 1.4ms
*/
BYTE delayCIA();

/**
   Function to wait for 400ns
*/

WORD delayShort();