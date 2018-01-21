@set ASM_INCLUDE="C:\Users\Matze\Amiga\SoftwareHacks\NDK_3.1\INCLUDES_LIBS\INCLUDE_I"
del *.o
del TestENC
vasm -quiet -align -Fhunk -I.. -I%ASM_INCLUDE% -ldots -nosym -opt-speed -o enc624j6l.o enc624j6l.asm

vlink -Bstatic -bamigahunk -L"C:\Users\Matze\Amiga\SoftwareHacks\NDK_3.1\INCLUDES_LIBS\LINKER_LIBS" -l"AMIGA" -l"DEBUG" -o"TestENC" -s -F files.txt
