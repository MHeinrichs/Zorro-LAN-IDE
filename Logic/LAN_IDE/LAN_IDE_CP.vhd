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
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

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

	SIGNAL ide: STD_LOGIC;
	SIGNAL autoconfig: STD_LOGIC;
	SIGNAL lan: STD_LOGIC;
	SIGNAL cp: STD_LOGIC;
	signal Dout1:STD_LOGIC_VECTOR(3 downto 0);
	signal AUTO_CONFIG_DONE:STD_LOGIC_VECTOR(1 downto 0);
	signal AUTO_CONFIG_DONE_CYCLE:STD_LOGIC_VECTOR(1 downto 0);
	signal SHUT_UP:STD_LOGIC_VECTOR(2 downto 0);
	signal IDE_BASEADR:STD_LOGIC_VECTOR(7 downto 0);
	signal LAN_BASEADR:STD_LOGIC_VECTOR(7 downto 0);
	signal CP_BASEADR:STD_LOGIC_VECTOR(7 downto 0);
	signal IDE_ENABLE:STD_LOGIC;
	signal ROM_OE_S:STD_LOGIC;
	signal IDE_R_S:STD_LOGIC;
	signal IDE_W_S:STD_LOGIC;
	signal DTACK_S:STD_LOGIC;
   signal AS_D: std_logic;
	signal AMIGA_CLK: std_logic;
	signal LAN_INT_ENABLE: std_logic;
	signal DECODE_RESET: std_logic;
	signal LAN_INT_D0: std_logic;
	signal DS: std_logic;
	signal LAN_RD_S: std_logic;
	signal LAN_WRH_S: std_logic;
	signal LAN_WRL_S: std_logic;
	signal CP_RD_S: std_logic;
	signal CP_WE_S: std_logic;

   Function to_std_logic(X: in Boolean) return Std_Logic is
   variable ret : std_logic;
   begin
   if x then ret := '1';  else ret := '0'; end if;
   return ret;
   end to_std_logic;
	
begin
	
	AMIGA_CLK <= not (C1 xor C3);
	DECODE_RESET <= BERR and reset;
	
	DS <= UDS and LDS;
	
	ADDRESS_DECODE: process(DECODE_RESET,AMIGA_CLK)
	begin
		if(DECODE_RESET ='0')then
			autoconfig <= '0';
			ide <= '0';
			lan <= '0';
			cp  <= '0';
		elsif(rising_edge(AMIGA_CLK))then				
			if(A(23 downto 16) = x"E8" and AUTO_CONFIG_DONE < "11" )then
				autoconfig <= not CFIN;
			else
				autoconfig <='0';
			end if;


			if(A(23 downto 16) = LAN_BASEADR )then					
				lan <= not SHUT_UP(0);					
			else
				lan <= '0';
			end if;				

			if(A(23 downto 16) = CP_BASEADR)then					
				cp <= not SHUT_UP(1);					
			else
				cp <= '0';
			end if;				

			if(A(23 downto 16) = IDE_BASEADR)then					
				ide <= not SHUT_UP(2);					
			else
				ide <= '0';
			end if;				
		end if;				
	end process ADDRESS_DECODE;
	
	--LAN interrupt enable
--	lan_int_proc: process (AMIGA_CLK,reset)
--	begin
--		if(reset ='0') then
--				LAN_INT_ENABLE <='0';
--				LAN_INT_D0 <='0';
--		elsif falling_edge(AMIGA_CLK) then
--			LAN_INT_D0 <= LAN_INT;
--			if(LAN_INT = '1' and LAN_INT_D0 = '0' and AUTO_CONFIG_DONE ="111") then --enable if high and ac completed!
--				LAN_INT_ENABLE <= '1';
--			end if;
--		end if;
--	end process lan_int_proc;
	
	--lan signal generation: all Signals are HIGH active!
	lan_rw_gen: process (AMIGA_CLK)
	begin
		if falling_edge(AMIGA_CLK) then			
			if(lan='1' and DS='0' and reset ='1')then
				LAN_RD_S		<= RW;	
				LAN_WRH_S   <= (not RW) and (not UDS);
				LAN_WRL_S   <= (not RW) and (not LDS);
			else
				LAN_RD_S		<= '0';
				LAN_WRH_S	<= '0';
				LAN_WRL_S	<= '0';
			end if;				
		end if;
	end process lan_rw_gen;
	
	--cp signal generation
	cp_rw_gen: process (AMIGA_CLK)
	begin
		if falling_edge(AMIGA_CLK) then			
			if(cp='1' and DS='0' and reset ='1')then --datastrobe instead of AS!
				CP_RD_S		<= not RW;
				CP_WE_S		<= RW;
			else
				CP_RD_S		<= '1';
				CP_WE_S		<= '1';
			end if;				
		end if;
	end process cp_rw_gen;


	--ide signal generation
	ide_rw_gen: process (AMIGA_CLK)
	begin
		if falling_edge(AMIGA_CLK) then			
			if	(reset = '0') then
				IDE_ENABLE 	<= '1';
				IDE_R_S		<= '1';
				IDE_W_S		<= '1';
				ROM_OE_S		<= '1';
			elsif(ide='1' and AS='0')then
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
--0

	autoconfig_proc: process (reset, AMIGA_CLK)
	begin
		if falling_edge(AMIGA_CLK) then -- no reset, so wait for rising edge of the clock		
			if	reset = '0' then
				-- reset active ...
				AUTO_CONFIG_DONE_CYCLE	<="00";
				Dout1<="1111";
				--Dout2<="1111";
				SHUT_UP	<="111";
				IDE_BASEADR<=x"FF";
				LAN_BASEADR<=x"FF";
				CP_BASEADR<=x"FF";
				AUTO_CONFIG_DONE	<="00";
			elsif(AS='1')then
				AUTO_CONFIG_DONE <= AUTO_CONFIG_DONE_CYCLE;
			elsif(autoconfig= '1' and DS='0') then
				case A(6 downto 1) is
					when "000000"	=> 
						if(AUTO_CONFIG_DONE < "10")then
							Dout1 <= 	"1100" ; --ZII, No-System-Memory, no ROM
						else
							Dout1 <= 	"110"&not(AUTOBOOT_OFF) ; --ZII, no System-Memory, (perhaps)ROM
						end if;
					when "000001"	=> Dout1 <=	"0001" ; --one Card, 64KB =001
					when "000010"	=> 
						if(AUTO_CONFIG_DONE < "10")then
							Dout1 <=	"1000" ; --ProductID high nibble : 7->1000
						else
							Dout1 <=	"1111" ; --ProductID high nibble : 0->1111
						end if;
					when "000011"	=> 
						if(AUTO_CONFIG_DONE = "00")then
							Dout1 <=	"0100" ; --ProductID low nibble: B->0100
						elsif(AUTO_CONFIG_DONE = "01")then
							Dout1 <=	"0011" ; --ProductID low nibble: C->0011
						else
							Dout1 <=	"1001" ; --ProductID low nibble: 6->1001 
						end if;						
					when "001000"	=> Dout1 <=	"1111" ; --Ventor ID 0
					when "001001"	=> 
						if(AUTO_CONFIG_DONE < "10")then
							Dout1 <=	"0101" ; --Ventor ID 1
						else
							Dout1 <=	"0111" ; --Ventor ID 1
						end if;						
					when "001010"	=> 
						if(AUTO_CONFIG_DONE < "10")then
							Dout1 <=	"1110" ; --Ventor ID 2
						else
							Dout1 <=	"1101" ; --Ventor ID 2
						end if;												
					when "001011"	=> 
						if(AUTO_CONFIG_DONE < "10")then
							Dout1 <=	"0011" ; --Ventor ID 3 : $0A1C: A1K.org
						else
							Dout1 <=	"0011" ; --Ventor ID 3 : $082C: BSC
						end if;						
					when "001100"	=> Dout1 <=	"0100" ; --Serial byte 0 (msb) high nibble
					when "001101"	=> Dout1 <=	"1110" ; --Serial byte 0 (msb) low  nibble
					when "001110"	=> Dout1 <=	"1001" ; --Serial byte 1       high nibble
					when "001111"	=> Dout1 <=	"0100" ; --Serial byte 1       low  nibble
					when "010000"	=> Dout1 <=	"1111" ; --Serial byte 2       high nibble
					when "010001"	=> Dout1 <=	"1111" ; --Serial byte 2       low  nibble
					when "010010"	=> Dout1 <=	"0100" ; --Serial byte 3 (lsb) high nibble
					when "010011"	=> Dout1 <=	"1010" ; --Serial byte 3 (lsb) low  nibble: B16B00B5
					--when "010100"	=> Dout1 <=	"1111" ; --Rom vector high byte high nibble 
					--when "010101"	=> Dout1 <=	"1111" ; --Rom vector high byte low  nibble 
					--when "010110"	=> Dout1 <=	"1111" ; --Rom vector low byte high nibble
					when "010111"	=> 
						if(AUTO_CONFIG_DONE = "10")then
							Dout1 <=	"1110" ; --Rom vector low byte low  nibble						
						else
							Dout1 <=	"1111" ; --Rom vector low byte low  nibble						
						end if;
					when "100000"	=> Dout1 <=	"0000" ; --Interrupt config: all zero
					when "100001"	=> Dout1 <=	"0000" ; --Interrupt config: all zero
					when "100100"	=>
						Dout1 <=	"1111" ;
						if(RW='0')then
							if(AUTO_CONFIG_DONE = "00" and SHUT_UP(0) ='1')then
								LAN_BASEADR(7 downto 0)	<= D(15 downto 8); --Base adress
								SHUT_UP(0)				<='0'; --enable board
								AUTO_CONFIG_DONE_CYCLE	<= AUTO_CONFIG_DONE_CYCLE+1; --done here
							elsif(AUTO_CONFIG_DONE = "01" and SHUT_UP(1) ='1')then									
								CP_BASEADR(7 downto 0)	<= D(15 downto 8); --Base adress
								SHUT_UP(1) <= '0'; --enable board
								AUTO_CONFIG_DONE_CYCLE	<= AUTO_CONFIG_DONE_CYCLE+1; --done here
							elsif(AUTO_CONFIG_DONE = "10" and SHUT_UP(2) ='1')then
								IDE_BASEADR(7 downto 0)	<= D(15 downto 8); --Base adress
								SHUT_UP(2) <= '0'; --enable board
								AUTO_CONFIG_DONE_CYCLE	<= AUTO_CONFIG_DONE_CYCLE+1; --done here
							end if;
						end if;
					when "100110"	=>
						Dout1 <=	"1111" ;
						if(RW='0')then
							if(AUTO_CONFIG_DONE = "00")then
								AUTO_CONFIG_DONE_CYCLE	<= AUTO_CONFIG_DONE_CYCLE+1; --done here
							elsif(AUTO_CONFIG_DONE = "01")then								
								AUTO_CONFIG_DONE_CYCLE	<= AUTO_CONFIG_DONE_CYCLE+1; --done here
							elsif(AUTO_CONFIG_DONE = "10")then
								AUTO_CONFIG_DONE_CYCLE	<= AUTO_CONFIG_DONE_CYCLE+1; --done here
							end if;
						end if;
					when others	=> Dout1 <=	"1111" ;
				end case;	
			end if;
		end if;
	end process autoconfig_proc; --- that's all

	LAN_CS	<= lan;
	LAN_WRL	<= LAN_WRL_S when AS='0' else '0';
	LAN_WRH	<= LAN_WRH_S when AS='0' else '0';
	LAN_RD	<= LAN_RD_S  when AS='0' else '0';
	LAN_CFG	<= "ZZZZ";
	
	CP_WE		<= CP_WE_S when AS='0' else '1';
	CP_RD		<= CP_RD_S when AS='0' else '1';
	CP_CS		<= not(cp);

	A_LAN <= A(14 downto 1);-- when lan='1' else A(13 downto 1) &'0';
	--signal assignment
	D	<=	--RAM_D 						when RW='1' and TRANSFER_IN_PROGRES ='1' else
			DQ								when RW='1' and (lan ='1' or cp = '1') and DS='0' else
			Dout1	& x"FFF" 			when RW='1' and autoconfig ='1' and DS='0' else
			"ZZZZZZZZZZZZZZZZ";

	DQ <= 	D 	when RW='0' and DS='0'
							--and (UDS ='0' or LDS='0')
							--and (lan ='1' or cp = '1') 
					else "ZZZZZZZZZZZZZZZZ";
								
	IDE_W <=	IDE_W_S when AS='0' else '1';
	IDE_R <=	IDE_R_S when AS='0' else '1';
	IDE_CS(0)<= not(A(12));			
	IDE_CS(1)<= not(A(13));
	IDE_A(0)	<= A(9);
	IDE_A(1)	<= A(10);
	IDE_A(2)	<= A(11);
	ROM_B	<= "00";
	ROM_OE	<= ROM_OE_S when AS='0' else '1';				

	--INT_OUT <= 'Z';
	INT_OUT <= '0' when 
							--(LAN_INT = '0' and LAN_INT_ENABLE ='1') or 
							CP_IRQ = '0' else 'Z';
	
	OWN 	<= '0' when AS='0' and (autoconfig  = '1' or ide = '1' or lan = '1' or cp = '1') else 'Z';
	SLAVE <= '0' when AS='0' and (autoconfig  = '1' or ide = '1' or lan = '1' or cp = '1') else '1';	
	CFOUT <= '0' when AUTO_CONFIG_DONE="111" else '1';
	
	OVR <= '0' when ide='1' and AS='0' else 'Z';
	
--	DTACK <= DTACK_S when --TRANSFER_IN_PROGRES ='1' or 
--								AUTOCONFIG_IN_PROGRES ='1' 
--						  else 'Z';
	
	DTACK <= '0' when ide='1' and AS='0' and IDE_WAIT='1' else 'Z';

end Behavioral;

