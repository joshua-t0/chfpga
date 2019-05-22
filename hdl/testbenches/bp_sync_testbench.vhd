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
--USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.ALL;

library work;
USE work.chFPGA_Package.all;
use work.tb_package.all;

ENTITY bp_buck_sync_testbench IS
END bp_buck_sync_testbench;


ARCHITECTURE behavior OF bp_buck_sync_testbench IS

   -- Clock period definitions
constant CLK_PERIOD : time := 100 ns;
constant CLK_PERIOD1 : time := 90 ns;
constant NUMBER_OF_SLOTS: integer := 16;
constant NUMBER_OF_IMPLEMENTED_SLOTS: integer := 16;


signal clk: std_logic; -- 322 MHz GTX clock
signal clk1: std_logic; -- 322 MHz GTX clock
signal rst : STD_LOGIC; -- asynchronous reset
signal ctr: unsigned(6 downto 0):=(others=>'0'); -- init for sim
signal buck_sync: std_logic;
signal rd_dat: std_logic_vector(31 downto 0);
signal wr_dat: std_logic_vector(31 downto 0) := (others=>'0');

signal rst1 : STD_LOGIC; -- asynchronous reset
signal rd_dat1: std_logic_vector(31 downto 0);
signal wr_dat1: std_logic_vector(31 downto 0) := (others=>'0');

signal clk_vect: std_logic_vector(0 to NUMBER_OF_SLOTS-1);
signal rst_vect: std_logic_vector(0 to NUMBER_OF_SLOTS-1);
type time_array is array (natural range <>) of time;
constant delay_vect: time_array(0 to NUMBER_OF_SLOTS-1) := (1 ns, 10.1 ns , 5 ns, 170.3 ns, 333.3 ns, 453.7 ns, 113.1 ns, 723.7 ns, 263.6 ns, 43 ns, 43.1 ns, 223.2 ns, 443.4 ns, 203 ns, 303 ns, 403.1 ns);
signal rd_dat_vect: slv32_array(0 to NUMBER_OF_SLOTS-1);
signal rd_dat_valid: std_logic_vector(0 to NUMBER_OF_SLOTS-1);

BEGIN

buck_sync <= 'H'; -- pull-up
wr_dat <= X"12345678";

-- clk_vect <= (1=> clk1, others=> clk);
dut_gen: for i in 0 to NUMBER_OF_IMPLEMENTED_SLOTS-1 generate

	clk_proc :process
	begin
	-- wait for delay_vect(i);
	wait for 17.3 ns;
		loop
			clk_vect(i) <= '1';
			wait for CLK_PERIOD/2;
			clk_vect(i) <= '0';
			wait for CLK_PERIOD/2;
		end loop;
	end process;

	rst_proc: process
	begin
		rst_vect(i) <= '1';
		sleep(clk_vect(i),10);
		rst_vect(i) <= '0';
		sleep(clk_vect(i),10);
		wait;
	end process;

	-- rst_vect(i) <= transport rst after delay_vect(i);
	-- -- clk_vect(i) <= transport clk after delay_vect(i);

	dut0: entity work.bp_buck_sync
		port map (
			sync => buck_sync,
			wr_dat => wr_dat,
			rd_dat => rd_dat_vect(i),
			rd_dat_valid=> rd_dat_valid(i),
			clk10 => clk_vect(i),
			rst => rst_vect(i)
		);
end generate;

-- dut1: entity work.bp_buck_sync
-- 	port map (
-- 		sync => buck_sync,
-- 		wr_dat => wr_dat1,
-- 		rd_dat => rd_dat1,
-- 		clk200 => clk1,
-- 		rst => rst1
-- 	);


-- clk_process :process
--    begin
-- 		clk <= '1';
-- 		wait for CLK_PERIOD/2;
-- 		clk <= '0';
-- 		wait for CLK_PERIOD/2;
--    end process;



-- txproc: process
-- begin

-- 	rst <= '1';
-- 	sleep(clk,10);
-- 	rst <= '0';
-- 	sleep(clk,10);
-- 	wr_dat <= X"12345678";
-- 	wait;
-- end process;

END;
