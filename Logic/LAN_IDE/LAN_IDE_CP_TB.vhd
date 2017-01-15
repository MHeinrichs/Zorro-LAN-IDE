--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   23:59:54 01/15/2017
-- Design Name:   
-- Module Name:   C:/Users/Matze/Amiga/Hardwarehacks/Zorro-LAN-IDE/Logic/LAN_IDE/LAN_IDE_CP_TB.vhd
-- Project Name:  LAN_IDE
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: LAN_IDE_CP
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY LAN_IDE_CP_TB IS
END LAN_IDE_CP_TB;
 
ARCHITECTURE behavior OF LAN_IDE_CP_TB IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT LAN_IDE_CP
    PORT(
         A : INOUT  std_logic_vector(23 downto 1);
         D : INOUT  std_logic_vector(15 downto 0);
         DQ : INOUT  std_logic_vector(15 downto 0);
         A_LAN : OUT  std_logic_vector(13 downto 0);
         OWN : OUT  std_logic;
         SLAVE : OUT  std_logic;
         CFOUT : OUT  std_logic;
         CFIN : IN  std_logic;
         C1 : IN  std_logic;
         C3 : IN  std_logic;
         MTCR : IN  std_logic;
         OVR : OUT  std_logic;
         BERR : IN  std_logic;
         MTACK : OUT  std_logic;
         DS0 : IN  std_logic;
         DTACK : OUT  std_logic;
         UDS : IN  std_logic;
         LDS : IN  std_logic;
         AS : IN  std_logic;
         RW : IN  std_logic;
         Z3 : IN  std_logic;
         DS1 : IN  std_logic;
         FCS : IN  std_logic;
         RESET : IN  std_logic;
         INT_OUT : OUT  std_logic;
         AUTOBOOT_OFF : IN  std_logic;
         ROM_B : OUT  std_logic_vector(1 downto 0);
         ROM_OE : OUT  std_logic;
         IDE_WAIT : IN  std_logic;
         CLK_EXT : IN  std_logic;
         IDE_W : OUT  std_logic;
         IDE_R : OUT  std_logic;
         IDE_A : OUT  std_logic_vector(2 downto 0);
         IDE_CS : OUT  std_logic_vector(1 downto 0);
         LAN_CFG : OUT  std_logic_vector(4 downto 1);
         LAN_RD : OUT  std_logic;
         LAN_CS : OUT  std_logic;
         LAN_WRH : OUT  std_logic;
         LAN_WRL : OUT  std_logic;
         LAN_INT : IN  std_logic;
         CP_RD : OUT  std_logic;
         CP_WE : OUT  std_logic;
         CP_CS : OUT  std_logic;
         CP_IRQ : IN  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal CFIN : std_logic := '0';
   signal C1 : std_logic := '0';
   signal C3 : std_logic := '0';
   signal MTCR : std_logic := '0';
   signal BERR : std_logic := '0';
   signal DS0 : std_logic := '0';
   signal UDS : std_logic := '0';
   signal LDS : std_logic := '0';
   signal AS : std_logic := '0';
   signal RW : std_logic := '0';
   signal Z3 : std_logic := '0';
   signal DS1 : std_logic := '0';
   signal FCS : std_logic := '0';
   signal RESET : std_logic := '0';
   signal AUTOBOOT_OFF : std_logic := '0';
   signal IDE_WAIT : std_logic := '0';
   signal CLK_EXT : std_logic := '0';
   signal LAN_INT : std_logic := '0';
   signal CP_IRQ : std_logic := '0';

	--BiDirs
   signal A : std_logic_vector(23 downto 1);
   signal D : std_logic_vector(15 downto 0);
   signal DQ : std_logic_vector(15 downto 0);

 	--Outputs
   signal A_LAN : std_logic_vector(13 downto 0);
   signal OWN : std_logic;
   signal SLAVE : std_logic;
   signal CFOUT : std_logic;
   signal OVR : std_logic;
   signal MTACK : std_logic;
   signal DTACK : std_logic;
   signal INT_OUT : std_logic;
   signal ROM_B : std_logic_vector(1 downto 0);
   signal ROM_OE : std_logic;
   signal IDE_W : std_logic;
   signal IDE_R : std_logic;
   signal IDE_A : std_logic_vector(2 downto 0);
   signal IDE_CS : std_logic_vector(1 downto 0);
   signal LAN_CFG : std_logic_vector(4 downto 1);
   signal LAN_RD : std_logic;
   signal LAN_CS : std_logic;
   signal LAN_WRH : std_logic;
   signal LAN_WRL : std_logic;
   signal CP_RD : std_logic;
   signal CP_WE : std_logic;
   signal CP_CS : std_logic;

   -- Clock period definitions
   signal AMIGA_CLK :std_logic;
	
	constant CLK_EXT_period : time := 40 ns;
   constant CLK_AMIGA_period : time := 140 ns;
	
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: LAN_IDE_CP PORT MAP (
          A => A,
          D => D,
          DQ => DQ,
          A_LAN => A_LAN,
          OWN => OWN,
          SLAVE => SLAVE,
          CFOUT => CFOUT,
          CFIN => CFIN,
          C1 => C1,
          C3 => C3,
          MTCR => MTCR,
          OVR => OVR,
          BERR => BERR,
          MTACK => MTACK,
          DS0 => DS0,
          DTACK => DTACK,
          UDS => UDS,
          LDS => LDS,
          AS => AS,
          RW => RW,
          Z3 => Z3,
          DS1 => DS1,
          FCS => FCS,
          RESET => RESET,
          INT_OUT => INT_OUT,
          AUTOBOOT_OFF => AUTOBOOT_OFF,
          ROM_B => ROM_B,
          ROM_OE => ROM_OE,
          IDE_WAIT => IDE_WAIT,
          CLK_EXT => CLK_EXT,
          IDE_W => IDE_W,
          IDE_R => IDE_R,
          IDE_A => IDE_A,
          IDE_CS => IDE_CS,
          LAN_CFG => LAN_CFG,
          LAN_RD => LAN_RD,
          LAN_CS => LAN_CS,
          LAN_WRH => LAN_WRH,
          LAN_WRL => LAN_WRL,
          LAN_INT => LAN_INT,
          CP_RD => CP_RD,
          CP_WE => CP_WE,
          CP_CS => CP_CS,
          CP_IRQ => CP_IRQ
        );
	
	AMIGA_CLK <= not (C1 xor C3);
   
	-- Clock process definitions
   CLK_EXT_process :process
   begin
		CLK_EXT <= '0';
		wait for CLK_EXT_period/2;
		CLK_EXT <= '1';
		wait for CLK_EXT_period/2;
   end process;
 
   -- Clock process definitions
   CLK_13_process :process
   begin
		C1 <= '1';
		C3 <= '0';
		wait for CLK_AMIGA_period/2;
		C1 <= '0';
		C3 <= '0';
		wait for CLK_AMIGA_period/2;
		C1 <= '0';
		C3 <= '1';
		wait for CLK_AMIGA_period/2;
		C1 <= '1';
		C3 <= '1';
		wait for CLK_AMIGA_period/2;
   end process;


   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
		RESET <='0';
		AS		<='1';
		BERR	<='1';
		D		<= (others=>'Z');
		DQ		<= (others=>'Z');
		A		<= (others=>'Z');
		RW		<='1';
		UDS 	<='1';
		LDS 	<='1';
		CFIN <='0';
		
		MTCR 	<='1';
		DS0 	<='1';
		Z3 	<='0';
		DS1 	<='1';
		FCS 	<='1';
		AUTOBOOT_OFF <='1';
		IDE_WAIT <='1';
		LAN_INT <='1';
		CP_IRQ <='1';		
		
      wait for 100 ns;	
		reset <='1';

      wait for CLK_AMIGA_period*10;
		
		--make a quick autoconfig
		wait until rising_edge(AMIGA_CLK);		--S0
		RW <='1';
		wait until falling_edge(AMIGA_CLK);		--S1
		A(23 downto 16) <= x"E8";
		A(15 downto 8)  <= x"00";
		A(7 downto 1)   <= "0100100";
		wait until rising_edge(AMIGA_CLK);		--S2
		AS<='0';
		RW<='0';
		wait until falling_edge(AMIGA_CLK);		--S3
		D <= x"EAEA"; --address config 1
		wait until rising_edge(AMIGA_CLK);		--S4
		UDS <='0'; 
		wait until falling_edge(AMIGA_CLK);		--S5
		wait until rising_edge(AMIGA_CLK);		--S6
		wait until falling_edge(AMIGA_CLK);		--S7
		AS <='1';
		UDS 	<='1';
		LDS 	<='1';
		D		<= (others=>'Z');


		wait until rising_edge(AMIGA_CLK);		--S0
		RW <='1';
		wait until falling_edge(AMIGA_CLK);		--S1
		A(23 downto 16) <= x"E8";
		A(15 downto 8)  <= x"00";
		A(7 downto 1)   <= "0100100";
		wait until rising_edge(AMIGA_CLK);		--S2
		AS<='0';
		RW<='0';
		wait until falling_edge(AMIGA_CLK);		--S3
		D <= x"EBEB"; --address config 2
		wait until rising_edge(AMIGA_CLK);		--S4
		UDS <='0';
		wait until falling_edge(AMIGA_CLK);		--S5
		wait until rising_edge(AMIGA_CLK);		--S6
		wait until falling_edge(AMIGA_CLK);		--S7
		AS <='1';
		UDS 	<='1';
		LDS 	<='1';
		D		<= (others=>'Z');

		wait until rising_edge(AMIGA_CLK);		--S0
		RW <='1';
		wait until falling_edge(AMIGA_CLK);		--S1
		A(23 downto 16) <= x"E8";
		A(15 downto 8)  <= x"00";
		A(7 downto 1)   <= "0100100";
		wait until rising_edge(AMIGA_CLK);		--S2
		AS<='0';
		RW<='0';
		wait until falling_edge(AMIGA_CLK);		--S3
		D <= x"ECEC"; --address config 3
		wait until rising_edge(AMIGA_CLK);		--S4
		UDS <='0';
		wait until falling_edge(AMIGA_CLK);		--S5
		wait until rising_edge(AMIGA_CLK);		--S6
		wait until falling_edge(AMIGA_CLK);		--S7
		AS <='1';
		UDS 	<='1';
		LDS 	<='1';
		D		<= (others=>'Z');
		
		--now do some I/O on LAN
		wait until rising_edge(AMIGA_CLK);		--S0
		RW <='1';
		wait until falling_edge(AMIGA_CLK);		--S1
		A(23 downto 16) <= x"EA";
		A(15 downto 8)  <= x"00";
		A(7 downto 1)   <= "0100100";
		wait until rising_edge(AMIGA_CLK);		--S2
		AS<='0';
		RW<='0';
		wait until falling_edge(AMIGA_CLK);		--S3
		D <= x"B00B"; --Testdata
		wait until rising_edge(AMIGA_CLK);		--S4
		UDS <='0';
		LDS <='0';
		wait until falling_edge(AMIGA_CLK);		--S5
		wait until rising_edge(AMIGA_CLK);		--S6
		wait until falling_edge(AMIGA_CLK);		--S7
		AS <='1';
		UDS 	<='1';
		LDS 	<='1';
		D		<= (others=>'Z');
		
		wait until rising_edge(AMIGA_CLK);		--S0
		RW <='1';
		wait until falling_edge(AMIGA_CLK);		--S1
		A(23 downto 16) <= x"EA";
		A(15 downto 8)  <= x"00";
		A(7 downto 1)   <= "0100100";
		wait until rising_edge(AMIGA_CLK);		--S2
		AS<='0';
		RW<='1';
		UDS <='0';
		LDS <='0';
		wait until falling_edge(AMIGA_CLK);		--S3
		wait until rising_edge(AMIGA_CLK);		--S4
		wait until falling_edge(AMIGA_CLK);		--S5
		wait until rising_edge(AMIGA_CLK);		--S6
		wait until falling_edge(AMIGA_CLK);		--S7
		AS <='1';
		UDS 	<='1';
		LDS 	<='1';
		D		<= (others=>'Z');
		
		--now do some I/O on CS
		wait until rising_edge(AMIGA_CLK);		--S0
		RW <='1';
		wait until falling_edge(AMIGA_CLK);		--S1
		A(23 downto 16) <= x"EB";
		A(15 downto 8)  <= x"00";
		A(7 downto 1)   <= "0100100";
		wait until rising_edge(AMIGA_CLK);		--S2
		AS<='0';
		RW<='0';
		wait until falling_edge(AMIGA_CLK);		--S3
		D <= x"B00B"; --Testdata
		wait until rising_edge(AMIGA_CLK);		--S4
		UDS <='0';
		LDS <='0';
		wait until falling_edge(AMIGA_CLK);		--S5
		wait until rising_edge(AMIGA_CLK);		--S6
		wait until falling_edge(AMIGA_CLK);		--S7
		AS <='1';
		UDS 	<='1';
		LDS 	<='1';
		D		<= (others=>'Z');
		
		wait until rising_edge(AMIGA_CLK);		--S0
		RW <='1';
		wait until falling_edge(AMIGA_CLK);		--S1
		A(23 downto 16) <= x"EB";
		A(15 downto 8)  <= x"00";
		A(7 downto 1)   <= "0100100";
		wait until rising_edge(AMIGA_CLK);		--S2
		AS<='0';
		RW<='1';
		UDS <='0';
		LDS <='0';
		wait until falling_edge(AMIGA_CLK);		--S3
		wait until rising_edge(AMIGA_CLK);		--S4
		wait until falling_edge(AMIGA_CLK);		--S5
		wait until rising_edge(AMIGA_CLK);		--S6
		wait until falling_edge(AMIGA_CLK);		--S7
		AS <='1';
		UDS 	<='1';
		LDS 	<='1';
		D		<= (others=>'Z');

		--now do some I/O on IDE		
		wait until rising_edge(AMIGA_CLK);		--S0
		RW <='1';
		wait until falling_edge(AMIGA_CLK);		--S1
		A(23 downto 16) <= x"EC";
		A(15 downto 8)  <= x"00";
		A(7 downto 1)   <= "0100100";
		wait until rising_edge(AMIGA_CLK);		--S2
		AS<='0';
		RW<='0';
		wait until falling_edge(AMIGA_CLK);		--S3
		D <= x"B00B"; --Testdata
		wait until rising_edge(AMIGA_CLK);		--S4
		UDS <='0';
		LDS <='0';
		wait until falling_edge(AMIGA_CLK);		--S5
		wait until rising_edge(AMIGA_CLK);		--S6
		wait until falling_edge(AMIGA_CLK);		--S7
		AS <='1';
		UDS 	<='1';
		LDS 	<='1';
		D		<= (others=>'Z');
		
		wait until rising_edge(AMIGA_CLK);		--S0
		RW <='1';
		wait until falling_edge(AMIGA_CLK);		--S1
		A(23 downto 16) <= x"EC";
		A(15 downto 8)  <= x"00";
		A(7 downto 1)   <= "0100100";
		wait until rising_edge(AMIGA_CLK);		--S2
		AS<='0';
		RW<='1';
		UDS <='0';
		LDS <='0';
		wait until falling_edge(AMIGA_CLK);		--S3
		wait until rising_edge(AMIGA_CLK);		--S4
		wait until falling_edge(AMIGA_CLK);		--S5
		wait until rising_edge(AMIGA_CLK);		--S6
		wait until falling_edge(AMIGA_CLK);		--S7
		AS <='1';
		UDS 	<='1';
		LDS 	<='1';
		D		<= (others=>'Z');

		wait until rising_edge(AMIGA_CLK);		
		wait until falling_edge(AMIGA_CLK);		
      wait;
   end process;

END;
