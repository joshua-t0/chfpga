--------------------------------------------------------------------------------
-- @file
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

ENTITY cge_testbench IS
	generic (
		NUMBER_OF_LANES: integer := 6 -- minimum to fit bits on lane monitor source 0
		);
END cge_testbench;


ARCHITECTURE behavior OF cge_testbench IS

   -- Clock period definitions
   -- constant CLK_PERIOD : time := 3.2 ns;

constant CLK_PERIOD : time := 2.5 ns; -- 400 MHz
constant BSB_CLK_PERIOD : time := 8 ns; -- 125 MHz
constant REFCLK_PERIOD : time := 6.4 ns; -- 156.25 MHz


	--Inputs
	--signal reset : std_logic := '0';


	signal refclk: std_logic; 
	signal clk, ctrl_clk: std_logic;
	signal rst, ctrl_rst: std_logic := '1';

	signal txp, txn: std_logic_vector(3 downto 0);
	signal tdata: std_logic_vector(255 downto 0);
	signal tlast, tvalid: std_logic := '0';


	constant NUMBER_OF_PACKETS : integer :=500;

-- Tests
-- Normal mode
-- Borderline delay
-- Missing frame
-- Short frame
-- One lane with bursts on back-to-back 1 word frame
-- All single word, back-to-back packets: cannot work because  too fast for the frame clock processing

	-- signal t1: slv8;
	-- signal t2,t3: std_logic;
begin


	--dut_inst: entity work.cge_test
	--	port map (
	--		tx_p=> txp,
	--		tx_n=> txn,
	--		gt_ref_clk_p => refclk,
	--		gt_ref_clk_n => not refclk
	--	);


	refclk_process: process
	   begin
			refclk <= '0';
			wait for REFCLK_PERIOD/2;
			refclk <= '1';
			wait for REFCLK_PERIOD/2;
	   end process;

	clk_process: process
	   begin
			clk <= '0';
			wait for CLK_PERIOD/2;
			clk <= '1';
			wait for CLK_PERIOD/2;
	   end process;

	bsb_clk_process: process
	   begin
			ctrl_clk <= '0';
			wait for BSB_CLK_PERIOD/2;
			ctrl_clk <= '1';
			wait for BSB_CLK_PERIOD/2;
	   end process;


	cge0: entity work.cge
		generic map (
			IMPLEMENT_PACKET_GENERATOR => TRUE
		 	)
		port map (
			tx_p => txp,
			tx_n => txn,
			refclk_p => refclk,
			refclk_n => not refclk,
			refclk_out => open,
            clk => clk,
            
			s_axis_tx_tdata => tdata,
			s_axis_tx_tvalid => tvalid,
			s_axis_tx_tlast => tlast,

			rst => rst,
			ctrl_clk => ctrl_clk,
			ctrl_rst => ctrl_rst
		 );

--	rst_proc: process(clk)
--	begin
--		if rising_edge(clk) then
--			rst <= '0';
--		end if;
--	end process;


	sim_proc: process
	begin
        ctrl_rst <= '1';
        rst <= '1';
        wait for 1.5 us; -- make sure the GTY PLL is locked and CLK322 is active
		sleep(ctrl_clk, 10);
        ctrl_rst <= '0';
		sleep(clk, 10);
        rst <= '0';
		sleep(clk, 1);
		tdata <= X"0001020304050607202122232425262730313233343536374041424344454647";
		tlast <= '1';
		tvalid <='1';

		sleep(clk,1);
		tlast <= '0';

		sleep(clk,1);

		tvalid <='0';
		wait;
	end process;




--rst_proc : process
--	begin
--		reset <= '1';
--		sleep(out_clk, 10);
--		reset <= '0';
--		sleep(out_clk, 257);


--		wait; -- comment out to implement periodic resets


END;
