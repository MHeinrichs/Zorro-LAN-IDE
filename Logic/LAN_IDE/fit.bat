@SET PATH=c:\Xilinx\14.6\ISE_DS\ISE\bin\nt64;C:\Xilinx\14.6\ISE_DS\ISE\lib\nt64
@SET XILINX=c:\Xilinx\14.6\ISE_DS\ISE
cpldfit -intstyle ise -p xc95144xl-10-TQ144 -ofmt vhdl -optimize density -htmlrpt -loc on -slew fast -init low -inputs %1 -pterms %2 -unused float -power std -terminate float LAN_IDE_CP.ngd >log.txt
@IF %ERRORLEVEL% NEQ 0 GOTO NO_SUCCESS
tsim -intstyle ise LAN_IDE_CP LAN_IDE_CP.nga >>log.txt
hprep6 -s IEEE1149 -n LAN_IDE_CP -i LAN_IDE_CP
GOTO END
:NO_SUCCESS
@echo !!!!
@echo error fitting the jed!
@echo !!!!
:END