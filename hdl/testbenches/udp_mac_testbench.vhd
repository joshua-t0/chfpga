--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   03:55:28 11/21/2010
-- Design Name:   
-- Module Name:   C:/Xilinx/work/CHIME/101119 - SP605_SFP_test/src/UDP_Ethernet_GMII_MAC/UDP_MAC_Testbench.vhd
-- Project Name:  UDP_Ethernet_GMII_MAC
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: UDP_Ethernet_GMII_MAC
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
USE ieee.numeric_std.ALL;
 
ENTITY UDP_MAC_Testbench IS
END UDP_MAC_Testbench;
 
ARCHITECTURE behavior OF UDP_MAC_Testbench IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT UDP_MAC
    PORT(
         TX_EN : IN  std_logic;
         TX_FRAME : IN  std_logic;
         TXD : IN  std_logic_vector(7 downto 0);
         RXD : OUT  std_logic_vector(7 downto 0);
         CLK125 : IN  std_logic;
         RST : IN  std_logic;
         GMII_RESET_L : OUT  std_logic;
         GMII_RXCLK : IN  std_logic;
         GMII_RXCTRL_RXDV : IN  std_logic;
         GMII_RXD : IN  std_logic_vector(7 downto 0);
         GMII_TXER : OUT  std_logic;
         GMII_TXCLK : IN  std_logic;
         GMII_TXC_GTXCLK : OUT  std_logic;
         GMII_TXEN : OUT  std_logic;
         GMII_TXD : OUT  std_logic_vector(7 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal TX_EN : std_logic := '0';
   signal TX_FRAME : std_logic := '0';
   signal TXD : std_logic_vector(7 downto 0) := (others => '0');
   signal CLK125 : std_logic := '0';
   signal RST : std_logic := '0';
   signal GMII_RXCLK : std_logic := '0';
   signal GMII_RXCTRL_RXDV : std_logic := '0';
   signal GMII_RXD : std_logic_vector(7 downto 0) := (others => '0');
   signal GMII_TXCLK : std_logic := '0';

 	--Outputs
   signal RXD : std_logic_vector(7 downto 0);
   signal GMII_RESET_L : std_logic;
   signal GMII_TXER : std_logic;
   signal GMII_TXC_GTXCLK : std_logic;
   signal GMII_TXEN : std_logic;
   signal GMII_TXD : std_logic_vector(7 downto 0);

   -- Clock period definitions
   constant CLK125_period : time := 8 ns;

	-- Test signals
	
	signal CTR: UNSIGNED(10 downto 0) := (others=>'0');
	signal START_SIM : std_logic;


 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: UDP_MAC PORT MAP (
          TX_EN => TX_EN,
          TX_FRAME => TX_FRAME,
          TXD => TXD,
          RXD => RXD,
          CLK125 => CLK125,
          RST => RST,
          GMII_RESET_L => GMII_RESET_L,
          GMII_RXCLK => GMII_RXCLK,
          GMII_RXCTRL_RXDV => GMII_RXCTRL_RXDV,
          GMII_RXD => GMII_RXD,
          GMII_TXER => GMII_TXER,
          GMII_TXCLK => GMII_TXCLK,
          GMII_TXC_GTXCLK => GMII_TXC_GTXCLK,
          GMII_TXEN => GMII_TXEN,
          GMII_TXD => GMII_TXD
        );

-- look back GMII output lines to input lines for a loopback test
GMII_RXD<=GMII_TXD;
GMII_RXCTRL_RXDV<=GMII_TXEN;
GMII_RXCLK<=CLK125;

   -- Clock process definitions
   CLK125_process :process
   begin
		CLK125 <= '0';
		wait for CLK125_period/2;
		CLK125 <= '1';
		wait for CLK125_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
		RST<='1';
      wait for CLK125_period*10;	
		RST<='0';
      wait for CLK125_period*10;
		START_SIM<='1';
		
      -- insert stimulus here 

      wait;
   end process;

generate_data: process(all)
   begin		
		if (CLK125'event and CLK125='1' and START_SIM='1') then
--			if(CTR=20) then
--				TX_EN<='0';
--				TX_FRAME<='0';
--				CTR<=(others=>'0');
--			else
--				TX_EN<='1';
--				TX_FRAME<='1';
--				TXD<=STD_LOGIC_VECTOR(CTR(7 downto 0));
--				CTR<=CTR+1;
--			end if;

			TX_EN<='1';
			TXD<=STD_LOGIC_VECTOR(CTR(7 downto 0));
			if (CTR=19) then
				TX_FRAME<='0';
			elsif (CTR=25) then	
				CTR<=(others=>'0');
				TX_FRAME<='1';
			else
				CTR<=CTR+1;
			end if;

		end if ; -- CLK125

   end process;


END;
