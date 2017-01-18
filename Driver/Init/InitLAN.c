#include "InitLAN.h"


unsigned long hex2int(char *a)
{
    int i,len=0;
    unsigned long val = 0;

                while(a[len])
                        len++;

    for(i=0;i<len;i++)
       if(a[i] <= 57)
        val += (a[i]-48)*(1<<(4*(len-1-i)));
       else
        val += (a[i]-55)*(1<<(4*(len-1-i)));

    return val;
}


BYTE delayCIA(){ //one CIA acces: 1.4 micro sec
   return (CIA_TST);
}

WORD delayShort(){
    return (CHP_TST);
}

int TestMemory(APTR *BaseAddress){
        int i;
        WORD w=0;
        WORD wTestWriteData, wTestReadData;

        // Generate and write pattern
        for(w = 0; w < ENC100_RAM_SIZE; w += sizeof(wTestWriteData))
        {
                wTestWriteData = w;
                WRITEREG(BaseAddress, w, w);
        }

        // Read back and verify random pattern
				i=0;
        for(w = 0; w < ENC100_RAM_SIZE; w += sizeof(wTestWriteData))
        {
                wTestWriteData = w;
                wTestReadData = READREG(BaseAddress,w);

                // See if the data matches.  If your application gets stuck here,
                // it means you have a hardware failure.  Check all of your PSP
                // address and data lines.
                if(wTestWriteData != wTestReadData){
                	printf("Error checking memory at adress x%lx! Expected x%x - got x%x\n",((volatile BYTE *)BaseAddress+w),wTestWriteData,wTestReadData);
                	++i;
                }
        }
        return i;
}

int SetClock(APTR *BaseAddress,int Clock){
	WORD s=0,c=0;
	
	switch(Clock){
		case 0:
			//disable clock
			c=(ECON2_COCON3|ECON2_COCON2|ECON2_COCON1|ECON2_COCON0);
			s=0;
			break;
		case 3:
			//3.125Mhz
			c=(ECON2_COCON1|ECON2_COCON0);
			s=(ECON2_COCON3|ECON2_COCON2);
			break;
		case 4:
			//4Mhz
			c=(ECON2_COCON2);
			s=(ECON2_COCON3|ECON2_COCON1|ECON2_COCON0);
			break;
		case 5:
			//5Mhz
			c=(ECON2_COCON2|ECON2_COCON0);
			s=(ECON2_COCON3|ECON2_COCON1);
			break;
		case 6:
			//6.25Mhz
			c=(ECON2_COCON2|ECON2_COCON1);
			s=(ECON2_COCON3|ECON2_COCON0);
			break;
		case 8:
			//8.333Mhz
			c=(ECON2_COCON3);
			s=(ECON2_COCON2|ECON2_COCON1|ECON2_COCON0);
			break;
		case 10:
			//10Mhz
			c=(ECON2_COCON3|ECON2_COCON0);
			s=(ECON2_COCON2|ECON2_COCON1);
			break;
		case 12:
			//12.5Mhz
			c=(ECON2_COCON3|ECON2_COCON1);
			s=(ECON2_COCON2|ECON2_COCON0);
			break;
		case 16:
			//16.667Mhz
			c=(ECON2_COCON3|ECON2_COCON1|ECON2_COCON0);
			s=(ECON2_COCON2);
			break;
		case 20:
			//20Mhz
			c=(ECON2_COCON3|ECON2_COCON2);
			s=(ECON2_COCON1|ECON2_COCON0);
			break;
		case 25:
			//25Mhz
			c=(ECON2_COCON3|ECON2_COCON2|ECON2_COCON0);
			s=(ECON2_COCON1);
			break;
		case 33:
			//33.333Mhz
			c=(ECON2_COCON3|ECON2_COCON2|ECON2_COCON1);
			s=(ECON2_COCON0);
			break;
		default: 
			//disable clock
			c=(ECON2_COCON3|ECON2_COCON2|ECON2_COCON1|ECON2_COCON0);
			s=0;
			break;
	}	

  CLRREG(BaseAddress,ECON2, c);
  SETREG(BaseAddress,ECON2, s);

	return 0;
}

int SoftReset(APTR *BaseAddress){
        int i;
        WORD w,v=0;
        // Perform a reset via the PSP interface
        do
        {

                // Set and clear a few bits that clears themselves upon reset.
                // If EUDAST cannot be written to and your code gets stuck in this
                // loop, you have a hardware problem of some sort (SPI or PMP not
                // initialized correctly, I/O pins aren't connected or are
                // shorted to something, power isn't available, etc.)
           		w= 0x1234;
                do
                {
                        WRITEREG(BaseAddress,EUDAST, w);
                        v=READREG(BaseAddress, EUDAST);
                        printf("Read 0x%x at register 0x%lx (should be 0x%x)\n",v,(volatile BYTE *)(BaseAddress)+(EUDAST),w);
                } while(v != w);

                // Issue a reset and wait for it to complete
                SETREG(BaseAddress,ECON2, ECON2_ETHRST);
                w = (WORD)(ESTAT_CLKRDY | ESTAT_RSTDONE | ESTAT_PHYRDY);
                do{
             
	                delayCIA();
 	                v = (WORD) READREG(BaseAddress,ESTAT);
 	                v &= (WORD) w;
                  printf("Read 0x%x at register 0x%x (should be 0x%x)\n",v,ESTAT,w);
                	
                }while(v != w);

				        /*
				          In software, wait at least 25 µs for the Reset to
				          take place and the SPI/PSP interface to begin
				          operating again.
				        */
        				for(i=0; i<25; ++i){
                	delayCIA();
        				}

                // Check to see if the reset operation was successful by
                // checking if EUDAST went back to its reset default.  This test
                // should always pass, but certain special conditions might make
                // this test fail, such as a PSP pin shorted to logic high.
                w=READREG(BaseAddress,EUDAST);
                printf("Read 0x%x at register 0x%x\n",w,EUDAST);
        } while(w != 0);

       	/*
       	Wait at least 256 µs for the PHY registers and PHY status bits to become available.
       	*/
        for(i=0; i<256; ++i){
        	delayCIA();
        }
        return v;
}

/*
** **********************************************
** LocateBoard()
** **********************************************
**
** Locates Host Controller hardware
**
*/
APTR LocateBoard(int manufactor, int product)
{
    APTR board;

    board = NULL; // Board not found (yet)

    if ( ExpansionBase = OpenLibrary( "expansion.library", 36 ) ) {

        struct ConfigDev *cfg;


        // *** Find board

        if (cfg = FindConfigDev( NULL, manufactor, product ))
                {
                        board = cfg->cd_BoardAddr; // Get board base adr.
                }

        CloseLibrary( ExpansionBase );
    }

    return( board ); // Return board ptr (or NULL)
}


main(int argc, char *argv[])
{
    int manufactor = 2588;
    int product = 123;
    int v =0;
    if(argc==2){
    	product =atoi(argv[1]);
    }
    if(argc==3){
    	manufactor =atoi(argv[1]);
    	product =atoi(argv[2]);
    }
    
    			
    
    APTR board = LocateBoard(manufactor,product);
    if(board){
        printf("Found board for manufactor/product %d/%d at address 0x%lx.\n",manufactor,product, board);
        SetClock(board,33);
        v=SoftReset(board);
        printf("SoftReset returned %X\n",v);
        v=TestMemory(board);
        printf("Memory passed with %d errors\n",v);
    }else{
        printf("No board found for manufactor/product %d/%d.\n",manufactor,product);
    }
}