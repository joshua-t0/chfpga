--------------------------------------------------------------------------------
-- @file
-- Company: McGill University 
-- Engineer: JF Cliche
--
-- Create Date:   2013-04-12
-- Design Name:   
-- Module Name:   
-- Project Name:  CHIME
-- Target Device: Kintex 7 on KC705 
-- Tool versions: Vivado 2012.4 
-- Description: VHDL test bench for XGMII UDP MAC   
-- 
-- -- Dependencies:
-- 
-- Revision:
--
-- Notes: 
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

library work;
USE work.chFPGA_Package.all;
 
ENTITY XGMII_UDP_MAC_testbench IS
END XGMII_UDP_MAC_testbench;


ARCHITECTURE behavior OF XGMII_UDP_MAC_testbench IS 

   -- Clock period definitions
   constant CLK_period : time := 5 ns;
   constant XGMII_CLK_period : time := 3.2 ns;

   --Inputs
   signal RST : std_logic := '0';
   signal CLK : std_logic := '0';
   signal XGMII_CLK : std_logic := '0';
   signal SYSCLK_N : std_logic := '0';

   signal DIN: AXIS32_DAT_STRUCT;
   signal XGMII_TXD:  STD_LOGIC_VECTOR(63 downto 0); -- Transmit data word
   signal XGMII_TXC: STD_LOGIC_VECTOR(7 downto 0); -- Transmit control flags

BEGIN


--	-- Instantiate the Unit Under Test (UUT)
UDP0: XGMII_UDP_MAC_TX 
	PORT MAP(
	MAC_SRC_ADDR=>X"010203040506",
	IP_SRC_ADDR=>X"0A0B0C0D",
	MAC_DEST_ADDR=>X"112233445566",
	IP_DEST_ADDR=>X"AABBCCDD",
	IP_DEST_PORT=>X"A028",
	DIN=>DIN,
	DIN_CLK=>CLK,

	-- XGMII Interface
	XGMII_TXD=>XGMII_TXD,
	XGMII_TXC=>XGMII_TXC,
	XGMII_CLK=>XGMII_CLK, 

	RST=>RST
		);

 

CLK_process :process
   begin
		CLK <= '0';
		wait for CLK_period/2;
		CLK <= '1';
		wait for CLK_period/2;
   end process;

XGMII_CLK_process :process
  begin
	XGMII_CLK <= '0';
	wait for XGMII_CLK_period/2;
	XGMII_CLK <= '1';
	wait for XGMII_CLK_period/2;
  end process;



phy_process: process
	variable data1: Word32Array(0 to 1):= (X"01010101",X"02020202");
	variable data2: Word32Array(0 to 2):= (X"03030303",X"04040404",X"05050505");
	begin
	RST<='1';
	wait for 10*CLK_period;	
	RST<='0';
	wait for 10*CLK_period;	

	axis32_write_buffer(data1, DIN, CLK);
	axis32_write_buffer(data1, DIN, CLK);
	axis32_write_buffer(data2, DIN, CLK);
	axis32_write_buffer(data1, DIN, CLK);
	axis32_write_buffer(data2, DIN, CLK);
	axis32_write_buffer(data2, DIN, CLK);

	wait;
	end process;
	
END;
