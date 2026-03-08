--------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date:   17:23:04 11/17/2010
-- Design Name:
-- Module Name:   C:/Xilinx/work/CHIME/SP605_test2/ADCDAQ/ADC_IOSERDES_testbench.vhd
-- Project Name:  ADCDAQ
-- Target Device:
-- Tool versions:
-- Description:
--
-- VHDL Test Bench Created by ISE for module: ADC_IOSERDES
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
USE ieee.numeric_std.ALL;

library work;
USE work.chFPGA_Package.all;
use work.tb_package.all;

ENTITY xge_udp_mac_tx_testbench IS
END xge_udp_mac_tx_testbench;


ARCHITECTURE behavior OF xge_udp_mac_tx_testbench IS

   -- Clock period definitions
   constant CLK_PERIOD : time := 3.2 ns;


	--Inputs
	signal CPU_RESET : std_logic := '0';

 -- UDP/Ethernet interfaces

signal clk: std_logic; -- 322 MHz GTX clock
signal rst : STD_LOGIC; -- asynchronous reset
signal ctr: unsigned(6 downto 0):=(others=>'0'); -- init for sim
--signal ctr64: unsigned(5 downto 0);

signal s_tx_tdata: slv32;
signal s_tx_tvalid: std_logic;
signal s_tx_tlast: std_logic;
signal s_tx_tready: std_logic :='1'; -- needed for sim if dut32 not connected

--signal s_tx_tdata64: slv64;
--signal s_tx_tvalid64: std_logic;
--signal s_tx_tlast64: std_logic;


signal tx_data: slv32;
signal tx_header: slv2; -- '10' for control, '01' for data
signal tx_ready: std_logic; -- The ata is accepted only on clocks where tx_ready is High
signal xgmii_txd: slv64;
signal xgmii_txc: slv8;

signal tx_ctr: unsigned(7 downto 0):= (others=>'0'); -- init needed for sim

constant data1: slv36_array(0 to 17) := (
	X"1_90E2BA2F", X"1_F88090E2",
	X"1_BA2FF880", X"1_08004500",
	X"1_0034013F", X"1_00000111",
	X"1_D37B0202", X"1_0201E000",
	X"1_00FCC313", X"1_14EB0020",
	X"1_70AC73D4", X"1_00000001",
	X"1_00000000", X"1_00000669",
	X"1_73617461", X"1_70000001",
	X"1_0001B85E", X"3_5E00FD07"
		);
constant data2: slv36_array := (
	0=> X"1_FAFEF1F0",
	1=> X"3_01234567"
	);

constant data3: slv36_array := ( -- works ok
	0=> X"1_FAFEF1F0",
	1=> X"0_00000000",
	2=> X"3_01234567"
	);

constant data4: slv36_array := ( --
	0=> X"1_FAFEF1F0",
	1=> X"0_00000000",
	2=> X"0_00000000",
	3=> X"0_00000000",
	4=> X"0_00000000",
	5=> X"0_00000000",
	6=> X"0_00000000",
	7=> X"3_01234567"
	);

constant data5: slv36_array(0 to 17) := (
	X"1_01010101", X"1_02020202",
	X"1_03030303", X"1_04040404",
	X"3_05050505", X"3_06060606",
	X"1_07070707", X"1_08080808",
	X"1_09090909", X"1_0A0A0A0A",
	X"3_0B0B0B0B", X"1_0C0C0C0C",
	X"3_0D0D0D0D", X"1_0E0E0E0E",
	X"1_0F0F0F0F", X"1_10101010",
	X"1_11111111", X"3_12121212"
		);

constant data6: slv36_array := (
	0=> X"1_a0a1a2a3",
	1=> X"1_b0b1b2b3",
	2=> X"1_c0c1c2c3",
	3=> X"3_d0d1d2d3"
	);

alias data is data6; -- select test patern source

BEGIN


--dut64: entity work.xge_udp_mac_tx_64
--	port map (
--		DIN=>(TDATA=>s_tx_tdata, TVALID=>s_tx_tvalid, TLAST=>s_tx_tlast, TUSER=>"0000"),
--		DIN_CLK=> clk,
----		data_overflow: out std_logic;
----		frame_overflow: out std_logic;
--
--		-- XGMII Interface
--		XGMII_TXD => xgmii_txd,
--		XGMII_TXC => xgmii_txc,
--		XGMII_CLK=> clk,
--
--		RST => CPU_RESET -- asynchronous reset
--
--
--	);

dut32: entity work.xge_udp_mac_tx
	port map (
		s_axis_tx_tdata => s_tx_tdata,
		s_axis_tx_tvalid => s_tx_tvalid,
		s_axis_tx_tlast => s_tx_tlast,
		s_axis_tx_tready => open,
		s_axis_tx_clk => clk,

		tx_data => tx_data,
		tx_header => tx_header,
		tx_ready => tx_ready,
		clk => clk,
		rst => CPU_RESET
	);


tx_ready <= not to_std_logic(tx_ctr(7 downto 1)=32);
--ctr64 <= ctr(ctr'HIGH downto 1);

txproc: process(all)
begin
    if rising_edge(clk) then
      -- if GPIO_BUTTON1='1' then
		if tx_ctr=65 then
			tx_ctr<=(others=>'0');
		else
			tx_ctr <= tx_ctr+1;
		end if;

      	if s_tx_tready then
      		if ctr < data'LENGTH then
				s_tx_tdata  <= data(to_integer(ctr))(31 downto 0);
				s_tx_tvalid <= data(to_integer(ctr))(32);
				s_tx_tlast  <= data(to_integer(ctr))(33);
	       else
				s_tx_tdata  <=X"07070707";
				s_tx_tvalid <='0';
				s_tx_tlast   <='0';
	        end if;

--      		if ctr < data'LENGTH-1 and ctr(0)='0' then
--				s_tx_tdata64  <= (data(to_integer(ctr64))(31 downto 0) & data(to_integer(ctr64)+1)(31 downto 0));
--				s_tx_tvalid64 <= data(to_integer(ctr64)+1)(32);
--				s_tx_tlast64  <= data(to_integer(ctr64)+1)(33);
--	       else
--				s_tx_tdata64  <=X"0707070707070707";
--				s_tx_tvalid64 <='0';
--				s_tx_tlast64   <='0';
--	        end if;

	        ctr<=ctr+1;
		end if;
     end if; --clk
  end process;



clk_process :process
   begin
		clk <= '1';
		wait for CLK_PERIOD/2;
		clk <= '0';
		wait for CLK_PERIOD/2;
   end process;



rst_process: process
	begin
	CPU_RESET<='1';
	wait for 10*CLK_PERIOD;
	CPU_RESET<='0';
	wait for 10*CLK_PERIOD;
	wait;
end process;

END;
