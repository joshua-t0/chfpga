----------------------------------------------------------------------------------
-- Company: McGill Univ.
-- Engineer: JF Cliche
--
-- Create Date:    2026-03-24
-- Module Name:    fifo_reset_sync
-- Target Devices: Kintex 7, Ultrascale+
-- Tool versions: Vivado 2022.2
-- Description: FIFO reset synchronizer / stretcher for hard FIFO primitives.
--
--   This is a FIFO reset synchonizer model based on the FIFO IP core for a 'built-in' asynchronous FIFO. This is not used in the code: it is more of a reference design.
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library xpm;
use xpm.vcomponents.all;

entity fifo_reset_sync is
	generic (
		-- CDC chain depth for xpm_cdc_async_rst (XPM allows 2..10).
		SYNC_STAGES       : integer range 2 to 10 := 3;
		MIN_ASSERT_CYCLES : positive := 5;
		POWER_ON_CYCLES   : natural  := 0
	);
	port (
		clk      : in  std_logic;
		arst     : in  std_logic; -- asynchronous reset request, active high
		rst_out  : out std_logic; -- synchronized/stretched active-high reset
		rst_busy : out std_logic  -- asserted whenever rst_out is asserted
	);
end entity fifo_reset_sync;


architecture impl of fifo_reset_sync is

	signal cdc_rst   : std_logic;
	signal hold_rst  : std_logic := '1';
	signal power_rst : std_logic := '1' when POWER_ON_CYCLES > 0 else '0';

	signal hold_ctr    : natural range 0 to MIN_ASSERT_CYCLES - 1 := 0;
	signal poweron_ctr : natural range 0 to POWER_ON_CYCLES := 0;

begin

	-- Async assert, synchronous deassert (same role as the former shift-register chain).
	rst_cdc0: xpm_cdc_async_rst
		generic map (
			RST_ACTIVE_HIGH => 1,
			DEST_SYNC_FF    => SYNC_STAGES
		)
		port map (
			src_arst  => arst,
			dest_clk  => clk,
			dest_arst => cdc_rst
		);

	process(all)
	begin
		if arst = '1' then
			hold_rst     <= '1';
			hold_ctr     <= 0;
			poweron_ctr  <= 0;
			power_rst    <= '1' when POWER_ON_CYCLES > 0 else '0';

		elsif rising_edge(clk) then
			-- Optional power-on extension, matching the style used by Xilinx FIFO IP
			if POWER_ON_CYCLES = 0 then
				power_rst <= '0';
			elsif poweron_ctr = POWER_ON_CYCLES then
				power_rst <= '0';
			else
				power_rst <= '1';
				poweron_ctr <= poweron_ctr + 1;
			end if;

			-- Hold reset asserted for at least MIN_ASSERT_CYCLES after the
			-- synchronizer starts releasing it.
			if cdc_rst = '1' then
				hold_rst <= '1';
				hold_ctr <= 0;
			elsif hold_rst = '1' then
				if hold_ctr = MIN_ASSERT_CYCLES - 1 then
					hold_rst <= '0';
				else
					hold_ctr <= hold_ctr + 1;
				end if;
			end if;
		end if;
	end process;

	rst_out  <= power_rst or cdc_rst or hold_rst;
	rst_busy <= power_rst or cdc_rst or hold_rst;

end architecture impl;
