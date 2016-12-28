----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    22:08:29 12/13/2016 
-- Design Name: 
-- Module Name:    LAN_IDE_CP - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity LAN_IDE_CP is
    Port ( A : inout  STD_LOGIC_VECTOR (23 downto 1);
           D : inout  STD_LOGIC_VECTOR (15 downto 0);
           DQ : inout  STD_LOGIC_VECTOR (15 downto 0);
           A_LAN : out  STD_LOGIC_VECTOR (13 downto 0);
           OWN : out  STD_LOGIC;
           SLAVE : out  STD_LOGIC;
           CFOUT : out  STD_LOGIC;
           CFIN : in  STD_LOGIC;
           C1 : in  STD_LOGIC;
           C3 : in  STD_LOGIC;
           MTCR : in  STD_LOGIC;
           OVR : out  STD_LOGIC;
           BERR : in  STD_LOGIC;
           MTACK : out  STD_LOGIC;
           DS0 : in  STD_LOGIC;
           DTACK : out  STD_LOGIC;
           UDS : in  STD_LOGIC;
           LDS : in  STD_LOGIC;
           AS : in  STD_LOGIC;
           RW : in  STD_LOGIC;
           Z3 : in  STD_LOGIC;
           DS1 : in  STD_LOGIC;
           FCS : in  STD_LOGIC;
           RESET : in  STD_LOGIC;
           INT_OUT : out  STD_LOGIC;
           AUTOBOOT_OFF : in  STD_LOGIC;
           ROM_B : out  STD_LOGIC_VECTOR (1 downto 0);
           ROM_OE : out  STD_LOGIC;
           IDE_WAIT : in  STD_LOGIC;
           CLK_EXT : in  STD_LOGIC;
           IDE_W : out  STD_LOGIC;
           IDE_R : out  STD_LOGIC;
           IDE_A : out  STD_LOGIC_VECTOR (2 downto 0);
           IDE_CS : out  STD_LOGIC_VECTOR (1 downto 0);
           LAN_CFG : out  STD_LOGIC_VECTOR (4 downto 1);
           LAN_RD : out  STD_LOGIC;
           LAN_CS : out  STD_LOGIC;
           LAN_WRH : out  STD_LOGIC;
           LAN_WRL : out  STD_LOGIC;
           LAN_INT : in  STD_LOGIC;
           CP_RD : out  STD_LOGIC;
           CP_WE : out  STD_LOGIC;
           CP_CS : out  STD_LOGIC;
           CP_IRQ : in  STD_LOGIC);
end LAN_IDE_CP;

architecture Behavioral of LAN_IDE_CP is

	SIGNAL ide: STD_LOGIC:= '0';
	SIGNAL autoconfig: STD_LOGIC:= '0';
	SIGNAL lan: STD_LOGIC:= '0';
	SIGNAL cp: STD_LOGIC:= '0';
	signal Dout1:STD_LOGIC_VECTOR(3 downto 0);
	signal AUTO_CONFIG_DONE:STD_LOGIC_VECTOR(2 downto 0);
	signal AUTO_CONFIG_DONE_CYCLE:STD_LOGIC_VECTOR(2 downto 0);
	signal SHUT_UP:STD_LOGIC_VECTOR(2 downto 0);
	signal IDE_BASEADR:STD_LOGIC_VECTOR(7 downto 0);
	signal LAN_BASEADR:STD_LOGIC_VECTOR(7 downto 0);
	signal CP_BASEADR:STD_LOGIC_VECTOR(7 downto 0);
	signal IDE_ENABLE:STD_LOGIC:= '0';
	signal ROM_OE_S:STD_LOGIC:= '1';
	signal IDE_R_S:STD_LOGIC:= '1';
	signal IDE_W_S:STD_LOGIC:= '1';
	signal DTACK_S:STD_LOGIC:= '1';
   signal AS_D: std_logic:= '1';
	signal AMIGA_CLK: std_logic:= '1';
	signal LAN_INT_ENABLE: std_logic:= '1';

   Function to_std_logic(X: in Boolean) return Std_Logic is
   variable ret : std_logic;
   begin
   if x then ret := '1';  else ret := '0'; end if;
   return ret;
   end to_std_logic;
	
begin
	
	AMIGA_CLK <= not (C1 xor C3);
	
	ADDRESS_DECODE: process(AMIGA_CLK)
	begin
		if(falling_edge(AS))then				
			if(BERR='1') then
				if(A(23 downto 16) = x"E8" and not(AUTO_CONFIG_DONE ="111") and CFIN='0')then
					autoconfig <='1';
				else
					autoconfig <='0';
				end if;


				if(A(23 downto 16) = LAN_BASEADR and SHUT_UP(0) = '0')then					
					lan <='1';					
				else
					lan <='0';
				end if;				

				if(A(23 downto 16) = IDE_BASEADR and SHUT_UP(1) = '0')then					
					ide <='1';					
				else
					ide <='0';
				end if;				

				if(A(23 downto 16) = CP_BASEADR and SHUT_UP(2) = '0')then					
					cp <='1';					
				else
					cp <='0';
				end if;				
			else
				autoconfig <='0';
				ide <='0';
				lan <='0';
				cp  <='0';
			end if;					
		end if;				
	end process ADDRESS_DECODE;
	
	--LAN interrupt enable
	lan_int_proc: process (AMIGA_CLK)
	begin
		if rising_edge(AMIGA_CLK) then
			if(reset ='0') then
				LAN_INT_ENABLE <='0';
			elsif(lan='1' and AS='0' and RW='0')then
				if(A(15 downto 8) = x"8")then
					LAN_INT_ENABLE <=D(15);
				end if;
			end if;
			
		end if;
	end process lan_int_proc;
	
	--ide
		-- this is the clocked process
	ide_rw_gen: process (AMIGA_CLK)
	begin
	
		if rising_edge(AMIGA_CLK) then
			if	(reset = '0') then
				IDE_R_S		<= '1';
				IDE_W_S		<= '1';
				ROM_OE_S		<= '1';
				IDE_ENABLE 	<= '1';
			elsif(AS='0' and ide='1')then
				if(RW='0')then
					--the write goes to the hdd!
					IDE_ENABLE  <= '0'; -- enable IDE on first read
					IDE_W_S		<= '0';	
					IDE_R_S		<= '1';
					ROM_OE_S		<=	'1';
				else
					IDE_W_S		<= '1';						
					IDE_R_S		<= IDE_ENABLE; --read from IDE instead from ROM
					ROM_OE_S		<=	not IDE_ENABLE;						
				end if;	
			else
				IDE_R_S		<= '1';
				IDE_W_S		<= '1';
				ROM_OE_S		<= '1';					
			end if;
				
		end if;
	end process ide_rw_gen;
		
	
	--autoconfig
	
	autoconfig_done: process (reset, AS)
	begin
		if	reset = '0' then
			-- reset active ...
			AUTO_CONFIG_DONE	<="000";
		elsif rising_edge(AS) then -- no reset, so wait for rising edge of the nAS		
			AUTO_CONFIG_DONE <= AUTO_CONFIG_DONE_CYCLE;
		end if;
	end process autoconfig_done;


	autoconfig_proc: process (reset, AMIGA_CLK)
	begin
		if rising_edge(AMIGA_CLK) then -- no reset, so wait for rising edge of the clock		
			if	reset = '0' then
				-- reset active ...
				AUTO_CONFIG_DONE_CYCLE	<="000";
				Dout1<="1111";
				--Dout2<="1111";
				SHUT_UP	<="111";
				IDE_BASEADR<=x"FF";
				LAN_BASEADR<=x"FF";
				CP_BASEADR<=x"FF";
			elsif(autoconfig= '1' and AS='0') then
				if(RW='1') then
					if(AUTO_CONFIG_DONE(0)='0')then
						case A(6 downto 1) is
							when "000000"	=> 
								Dout1 <= 	"1100" ; --ZII, System-Memory, no ROM
							when "000001"	=> Dout1 <=	"0001" ; --one Card, 64KB =001
							when "000010"	=> Dout1 <=	"1000" ; --ProductID high nibble : E->0001
							when "000011"	=> Dout1 <=	"0100" ; --ProductID low nibble: F->0000
							--when "0001000"	=> Dout1 <=	"1111" ; --Config HIGH: 0x20 and no shut down
							--when "0001010"	=> Dout1 <=	"1111" ; --Config LOW
							--when "0010000"	=> Dout1 <=	"1111" ; --Ventor ID 0
							when "001001"	=> Dout1 <=	"0101" ; --Ventor ID 1
							when "001010"	=> Dout1 <=	"1110" ; --Ventor ID 2
							when "001011"	=> Dout1 <=	"0011" ; --Ventor ID 3 : $0A1C: A1K.org
							--when "0011000"	=> Dout1 <=	"1111" ; --Serial byte 0 (msb) high nibble
							--when "0011010"	=> Dout1 <=	"1111" ; --Serial byte 0 (msb) low  nibble
							--when "0011100"	=> Dout1 <=	"1111" ; --Serial byte 1       high nibble
							--when "0011110"	=> Dout1 <=	"1111" ; --Serial byte 1       low  nibble
							--when "0100000"	=> Dout1 <=	"1111" ; --Serial byte 2       high nibble
							--when "0100010"	=> Dout1 <=	"1111" ; --Serial byte 2       low  nibble
							--when "0100100"	=> Dout1 <=	"1111" ; --Serial byte 3 (lsb) high nibble
							--when "010001"	=> Dout1 <=	"1000" ; --Serial byte 2       low  nibble
							when "010011"	=> Dout1 <=	"1110" ; --Serial byte 3 (lsb) low  nibble
							when "100000"	=> Dout1 <=	"0000" ; --Interrupt config: all zero
							when "100001"	=> Dout1 <=	"0000" ; --Interrupt config: all zero
							when others	=> Dout1 <=	"1111" ;
						end case;	
					elsif(AUTO_CONFIG_DONE(1)='0')then
						case A(6 downto 1) is
							when "000000"	=> 
								if(AUTOBOOT_OFF ='0') then
									Dout1 <= 	"1101" ; --ZII, no System-Memory, ROM
								else
									Dout1 <= 	"1100" ; --ZII, no System-Memory, no ROM
								end if;
							when "000001"	=> Dout1 <=	"0001" ; --one Card, 64kb = 001
							--when "0000100"	=> Dout2 <=	"1111" ; --ProductID high nibble : F->0000=0
							when "000011"	=> Dout1 <=	"1001" ; --ProductID low nibble: 9->0110=6
							--when "0001000"	=>                                                                                                                                                                                                                                                                                                                        Dout <=	"1111" ; --Config HIGH: 0x20 and no shut down
							--when "0001010"	=> Dout2 <=	"1111" ; --Config LOW
							--when "0010000"	=> Dout2 <=	"1111" ; --Ventor ID 0
							when "001001"	=> Dout1 <=	"0111" ; --Ventor ID 1
							when "001010"	=> Dout1 <=	"1101" ; --Ventor ID 2
							when "001011"	=> Dout1 <=	"0011" ; --Ventor ID 3 : $082C: BSC
							when "001100"	=> Dout1 <=	"0100" ; --Serial byte 0 (msb) high nibble
							when "001101"	=> Dout1 <=	"1110" ; --Serial byte 0 (msb) low  nibble
							when "001110"	=> Dout1 <=	"1001" ; --Serial byte 1       high nibble
							when "001111"	=> Dout1 <=	"0100" ; --Serial byte 1       low  nibble
							--when "0100000"	=> Dout2 <=	"1111" ; --Serial byte 2       high nibble
							--when "0100010"	=> Dout2 <=	"1111" ; --Serial byte 2       low  nibble
							when "010010"	=> Dout1 <=	"0100" ; --Serial byte 3 (lsb) high nibble
							when "010011"	=> Dout1 <=	"1010" ; --Serial byte 3 (lsb) low  nibble: B16B00B5
							--when "0101000"	=> Dout2 <=	"1111" ; --Rom vector high byte high nibble 
							--when "0101010"	=> Dout2 <=	"1111" ; --Rom vector high byte low  nibble 
							--when "0101100"	=> Dout2 <=	"1111" ; --Rom vector low byte high nibble
							when "010111"	=> Dout1 <=	"1110" ; --Rom vector low byte low  nibble
							when "100000"	=> Dout1 <=	"0000" ; --Interrupt config: all zero
							when "100001"	=> Dout1 <=	"0000" ; --Interrupt config: all zero
							when others	=> Dout1 <=	"1111" ;
						end case;	
					elsif(AUTO_CONFIG_DONE(2)='0')then
						case A(6 downto 1) is
							when "000000"	=> 
								Dout1 <= 	"1100" ; --ZII, System-Memory, no ROM
							when "000001"	=> Dout1 <=	"0001" ; --one Card, 64KB =001
							when "000010"	=> Dout1 <=	"1000" ; --ProductID high nibble : E->0001
							when "000011"	=> Dout1 <=	"0011" ; --ProductID low nibble: F->0000
							--when "0001000"	=> Dout1 <=	"1111" ; --Config HIGH: 0x20 and no shut down
							--when "0001010"	=> Dout1 <=	"1111" ; --Config LOW
							--when "0010000"	=> Dout1 <=	"1111" ; --Ventor ID 0
							when "001001"	=> Dout1 <=	"0101" ; --Ventor ID 1
							when "001010"	=> Dout1 <=	"1110" ; --Ventor ID 2
							when "001011"	=> Dout1 <=	"0011" ; --Ventor ID 3 : $0A1C: A1K.org
							--when "0011000"	=> Dout1 <=	"1111" ; --Serial byte 0 (msb) high nibble
							--when "0011010"	=> Dout1 <=	"1111" ; --Serial byte 0 (msb) low  nibble
							--when "0011100"	=> Dout1 <=	"1111" ; --Serial byte 1       high nibble
							--when "0011110"	=> Dout1 <=	"1111" ; --Serial byte 1       low  nibble
							--when "0100000"	=> Dout1 <=	"1111" ; --Serial byte 2       high nibble
							--when "0100010"	=> Dout1 <=	"1111" ; --Serial byte 2       low  nibble
							--when "0100100"	=> Dout1 <=	"1111" ; --Serial byte 3 (lsb) high nibble
							--when "010001"	=> Dout1 <=	"1000" ; --Serial byte 2       low  nibble
							when "010011"	=> Dout1 <=	"1110" ; --Serial byte 3 (lsb) low  nibble
							when "100000"	=> Dout1 <=	"0000" ; --Interrupt config: all zero
							when "100001"	=> Dout1 <=	"0000" ; --Interrupt config: all zero
							when others	=> Dout1 <=	"1111" ;
						end case;	
					end if;
				else --write
					if( UDS='0' )then
						if(AUTO_CONFIG_DONE(0)='0')then
							if(A (6 downto 1)="100100")then								
								LAN_BASEADR(7 downto 0)	<= D(15 downto 8); --Base adress
								AUTO_CONFIG_DONE_CYCLE(0)	<='1'; --done here
								SHUT_UP(0)				<='0'; --enable board
							elsif(A (6 downto 1)="100110")then
								AUTO_CONFIG_DONE_CYCLE(0)	<='1'; --done here
							end if;
						elsif(AUTO_CONFIG_DONE(1)='0')then
	--						if(AUTO_CONFIG_DONE(1)='0')then
							if(A (6 downto 1)="100100")then
								IDE_BASEADR(7 downto 0)	<= D(15 downto 8); --Base adress
								SHUT_UP(1) <= '0'; --enable board
								AUTO_CONFIG_DONE_CYCLE(1)	<='1'; --done here
							elsif(A (6 downto 1)="100110")then
								AUTO_CONFIG_DONE_CYCLE(1)	<='1'; --done here
							end if;
						elsif(AUTO_CONFIG_DONE(2)='0')then
	--						if(AUTO_CONFIG_DONE(1)='0')then
							if(A (6 downto 1)="100100")then
								CP_BASEADR(7 downto 0)	<= D(15 downto 8); --Base adress
								SHUT_UP(2) <= '0'; --enable board
								AUTO_CONFIG_DONE_CYCLE(2)	<='1'; --done here
							elsif(A (6 downto 1)="100110")then
								AUTO_CONFIG_DONE_CYCLE(2)	<='1'; --done here
							end if;
						end if;
					end if;
				end if;
			end if;
		end if;
	end process autoconfig_proc; --- that's all

	LAN_WRL	<= '1' when AS='0' and RW='0' and lan='1' and LDS = '0' else '0';
	LAN_WRH	<= '1' when AS='0' and RW='0' and lan='1' and UDS = '0' else '0';
	LAN_CS	<= '1';-- when AS='0' and lan='1' else '0';
	LAN_RD	<= '1' when AS='0' and RW='1' and lan='1' else '0';
	LAN_CFG	<= "0010";
	
	CP_WE		<= '0' when AS='0' and RW='0' and cp='1' and (UDS='0' or LDS='0') else '1';
	CP_RD		<= '0' when AS='0' and RW='1' and cp='1' else '1';
	CP_CS		<= '0' when AS='0' and cp='1' else '1';

	A_LAN <= A(14 downto 1) when lan='1' else A(13 downto 1) &'0';
	--signal assignment
	D	<=	--RAM_D 						when RW='1' and TRANSFER_IN_PROGRES ='1' else
			DQ								when RW='1' and (lan ='1' or cp = '1') and AS='0' else
			Dout1	& x"FFF" 			when RW='1' and autoconfig ='1' and AS='0' else
			"ZZZZZZZZZZZZZZZZ";

	DQ <= 	D 	when RW='0' and AS='0'
							--and (UDS ='0' or LDS='0')
							--and (lan ='1' or cp = '1') 
					else "ZZZZZZZZZZZZZZZZ";
								
	IDE_W <=	IDE_W_S;
	IDE_R <=	IDE_R_S;
	IDE_CS(0)<= not(A(12));			
	IDE_CS(1)<= not(A(13));
	IDE_A(0)	<= A(9);
	IDE_A(1)	<= A(10);
	IDE_A(2)	<= A(11);
	ROM_B	<= "00";
	ROM_OE	<= ROM_OE_S;				

	--INT_OUT <= 'Z';
	INT_OUT <= '0' when 
							(LAN_INT = '0' and LAN_INT_ENABLE ='1') or 
							CP_IRQ = '0' else 'Z';
	
	OWN 	<= '0' when AS='0' and (autoconfig  = '1' or ide = '1' or lan = '1' or cp = '1') else 'Z';
	SLAVE <= '0' when AS='0' and (autoconfig  = '1' or ide = '1' or lan = '1' or cp = '1') else '1';
	CFOUT <= '0' when AUTO_CONFIG_DONE="111" else '1';
	
--	DTACK <= DTACK_S when --TRANSFER_IN_PROGRES ='1' or 
--								AUTOCONFIG_IN_PROGRES ='1' 
--						  else 'Z';
	
	DTACK <= 'Z';

end Behavioral;

