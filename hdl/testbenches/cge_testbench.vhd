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
--use work.tb_package.all;

ENTITY cge_testbench IS
	generic (
		NUMBER_OF_LANES: integer := 6 -- minimum to fit bits on lane monitor source 0
		);
END cge_testbench;


ARCHITECTURE behavior OF cge_testbench IS

   -- Clock period definitions
   -- constant CLK_PERIOD : time := 3.2 ns;

constant REFCLK_PERIOD : time := 6.4 ns; -- 156.25 MHz


	--Inputs
	--signal reset : std_logic := '0';


	signal refclk: std_logic; -- 200 MHz
	--signal out_clk: std_logic; -- 244 MHz


	--signal s_axis_tdata: slv32_array(0 to NUMBER_OF_LANES-1) := (others=> (others=>'0'));
	--signal s_axis_tvalid: std_logic_vector(0 to NUMBER_OF_LANES-1) := (others=>'0'); -- needed for sim. If, U, data will not start
	--signal s_axis_tlast: std_logic_vector(0 to NUMBER_OF_LANES-1):= (others=>'0');
	--signal s_axis_tready: std_logic_vector(0 to NUMBER_OF_LANES-1):=(others=>'1'); -- init needed for sim

	--signal m_axis_fifo_tdata: slv32_array(0 to NUMBER_OF_LANES-1);
	--signal m_axis_fifo_tvalid: std_logic_vector(0 to NUMBER_OF_LANES-1);
	--signal m_axis_fifo_tlast: std_logic_vector(0 to NUMBER_OF_LANES-1);
	--signal m_axis_fifo_tuser: slv4_array(0 to NUMBER_OF_LANES-1);
	---- signal m_axis_fifo_tready: std_logic_vector(0 to NUMBER_OF_LANES-1);

	--signal m_axis_tdata: slv32_array(0 to NUMBER_OF_LANES-1);
	--signal m_axis_tvalid: std_logic_vector(0 to NUMBER_OF_LANES-1);
	--signal m_axis_tlast: std_logic_vector(0 to NUMBER_OF_LANES-1);
	--signal m_axis_tuser: slv4_array(0 to NUMBER_OF_LANES-1);

	--signal m_axis_global_tvalid: std_logic;
	--signal m_axis_global_tlast: std_logic;
	--signal tvalid_error: std_logic_vector(0 to NUMBER_OF_LANES-1);

	--signal fifo_rd_en: std_logic_vector(0 to NUMBER_OF_LANES-1) := (others=> '0');
	--signal fifo_rst: std_logic;
	--signal fifo_inhibit: std_logic;
	--signal fifo_rst_ctr : unsigned(5 downto 0);

	--signal frame_clk: std_logic;
	--signal first: std_logic := '1';
	--signal timeout_ctr: unsigned(7 downto 0);

	signal txp, txn: std_logic_vector(3 downto 0);

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


	dut_inst: entity work.cge_test
		port map (
			tx_p=> txp,
			tx_n=> txn,
			gt_ref_clk_p => refclk,
			gt_ref_clk_n => not refclk
		);



	refclk_process: process
	   begin
			refclk <= '0';
			wait for REFCLK_PERIOD/2;
			refclk <= '1';
			wait for REFCLK_PERIOD/2;
	   end process;


--rst_proc : process
--	begin
--		reset <= '1';
--		sleep(out_clk, 10);
--		reset <= '0';
--		sleep(out_clk, 257);


--		wait; -- comment out to implement periodic resets


END;
