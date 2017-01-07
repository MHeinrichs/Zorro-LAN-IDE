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



int SoftReset(APTR *BaseAddress){
        int i;
        WORD w,v=0;
        WORD wTestWriteData, wTestReadData;
        // Perform a reset via the PSP interface
				//set the clock to 33mhz: COCON[3..0] = "0001"
        CLRREG(BaseAddress,ECON2, (ECON2_COCON3|ECON2_COCON2|ECON2_COCON1));
        SETREG(BaseAddress,ECON2, ECON2_COCON0);
				

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
                        printf("Read 0x%x at register 0x%x (should be 0x%x)\n",v,EUDAST,w);
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

                // Check to see if the reset operation was successful by
                // checking if EUDAST went back to its reset default.  This test
                // should always pass, but certain special conditions might make
                // this test fail, such as a PSP pin shorted to logic high.
                w=READREG(BaseAddress,EUDAST);
                printf("Read 0x%x at register 0x%x\n",w,EUDAST);
        } while(w != 0);


        // Really ensure reset is done and give some time for power to be stable
        for(i=0; i<1000; ++i){
                        delayCIA();
        }


        // If using PSP, verify all address and data lines are working
				// Parallel direct addressing

        // Initialize RAM contents with a random pattern and read back to verify
        // This step is critical if using a PSP interface since some functionality
        // may appear to work while a solder bridge or disconnect will cause
        // certain memory ranges to fail.

        // Generate and write pattern
        for(w = 0; w < ENC100_RAM_SIZE; w += sizeof(wTestWriteData))
        {
                wTestWriteData = w;
                WRITEREG(BaseAddress, w, w);
        }

        // Read back and verify random pattern

        for(w = 0; w < ENC100_RAM_SIZE; w += sizeof(wTestWriteData))
        {
                wTestWriteData = w;
                wTestReadData = READREG(BaseAddress,w);

                // See if the data matches.  If your application gets stuck here,
                // it means you have a hardware failure.  Check all of your PSP
                // address and data lines.
                if(wTestWriteData != wTestReadData)
                	printf("Error checking memory at adress %lx! Expected %x - got %x\n",(BaseAddress+w),wTestWriteData,wTestReadData);

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
        v=SoftReset(board);
        printf("SoftReset returned %X\n",v);
    }else{
        printf("No board found for manufactor/product %d/%d.\n",manufactor,product);
    }
}