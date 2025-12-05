--------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date:  2023-02
-- Project Name:  CHORD
-- Target Device: Ultrascale+
-- Tool versions:
-- Description: testbench for the UltraRAM-based, 8 channel, 8k bins, 16 frames corner-turn engine.
--
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

library work;
USE work.chFPGA_Package.all;
use work.tb_package.all;

ENTITY cge_test_testbench IS
	generic (
		USE_CHAN_DATA: boolean := TRUE -- minimum to fit bits on lane monitor source 0
		);
END cge_test_testbench;


ARCHITECTURE behavior OF cge_test_testbench IS

   -- Clock period definitions
   -- constant CLK_PERIOD : time := 3.2 ns;

constant CLK_PERIOD : time := 1000000/375 * 1 ps; -- 375 MHz
constant CTRL_CLK_PERIOD : time := 5 ns; --
constant REFCLK_PERIOD : time := 6.4 ns; -- 156.25 MHz


	--Inputs
	--signal reset : std_logic := '0';


	signal clk, clkb: std_logic; -- 375 MHz
	signal ctrl_clk, ctrl_clkb: std_logic; -- 100 MHz
	signal refclk, refclkb: std_logic; -- 156.25 MHz

	signal txp, txn: std_logic_vector(3 downto 0);

	signal rst: std_logic := '1';
	signal tlast_in, tlast_out, tvalid_in, tvalid_out: std_logic;
	signal tdata_in, tdata_out: std_logic_vector(255 downto 0);
    signal cmd_dat: axis8_dat_struct := (TDATA=>(others=>'0'), TVALID=>'0', TLAST=>'0');
    signal cmd_rdy: axis8_rdy_struct;
    signal rply_dat: axis8_dat_struct;
    signal rply_rdy: axis8_rdy_struct := (TREADY=>'0');

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
	--		gt_ref_clk_p => clk,
	--		gt_ref_clk_n => not clk
	--	);


--	refclk_process: process
--	   begin
--			clk <= '0';
--			wait for CLK_PERIOD/2;
--			clk <= '1';
--			wait for CLK_PERIOD/2;
--	   end process;

    bsbclk_process: process
	   begin
			ctrl_clk <= '0';
			wait for CTRL_CLK_PERIOD/2;
			ctrl_clk <= '1';
			wait for CTRL_CLK_PERIOD/2;
	   end process;
--    ctrl_clk <= clk;
     ctrl_clkb <= not ctrl_clk;

	refclk_process: process
	   begin
			refclk <= '0';
			wait for REFCLK_PERIOD/2;
			refclk <= '1';
			wait for REFCLK_PERIOD/2;
	   end process;
     refclkb <= not refclk;

	plclk_process: process
	   begin
			clk <= '0';
			wait for CLK_PERIOD/2;
			clk <= '1';
			wait for CLK_PERIOD/2;
	   end process;
     clkb <= not clk;


	DUT0: entity work.cge_test
		--generic map (
		--	IMPLEMENT_PACKET_GENERATOR => TRUE
		-- 	)
		port map (
			tx_p => txp,
			tx_n => txn,
			gt_ref_clk_p => refclk,
			gt_ref_clk_n => refclkb,
			clk100_p => ctrl_clk,
			clk100_n => ctrl_clkb,
			pl_clk_p => clk,
			pl_clk_n => clkb
		 );



	sim_proc: process

        variable data: std_logic_vector(255 downto 0);
        variable addr, eop, eot: integer;
	begin

		sleep(ctrl_clk, 10);
		sleep(clk,10);



		wait;
	end process;




END;
