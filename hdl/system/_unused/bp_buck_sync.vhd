----------------------------------------------------------------------------------
-- Company: Mc Gill University
-- Engineer: J.-F. Cliche
--
-- Create Date:    2012-03-28
-- Design Name:
-- Module Name:    bp_buck_sync - impl
-- Project Name: CHIME
-- Target Devices:
-- Tool versions: Vivado 2013.3
-- Description: Generates a self-synchronizing distributed buck converter synchronization signal
--
-- Dependencies:
--
-- Revision:
--   2012-03-28 JFC: Created
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.chFPGA_Package.ALL; -- Get all component definitions

library UNISIM;
use UNISIM.VComponents.ALL;

------------ ENTITY DECLAREATION ------------------
-- This module Generates a self-synchronizing distributed buck converter synchronization signal
--
-- A counter conts up continuously and is reset when  whenever a rising edge is seen or the target period is reached.
-- When half the periiod is reached (counter = tMARK), we force the sync line to zero, and release it when the period is reached (counter=tPERIOD).
-- If a board sees that the sync line stayed high for too long (more than half the period), it will force the line low and will release it half a period later.
-- All the other boards will synchronize their counter to this board, and all boards will then do exactly the same thing.
-- The frequency of the resulting sync line is determined by the frequency of the slowest board.
--
-- Data can be sent by modulating the position of the falling edge of the sync
-- signal. The position of the rising edge, which is detected by the buck
-- regulator, is not changed.
--
entity bp_buck_sync is
	port (
		-- Buck sync
		
		sync: inout std_logic;
		sync_mon: out std_logic;

		-- Data interface - used to encode data by modulating the pulse width

		data_en: in std_logic := '0';
		wr_dat: in std_logic_vector(31 downto 0);
		rd_dat: out std_logic_vector(31 downto 0);
		rd_dat_valid: out std_logic;
		-- release_ctr_mon: out std_logic_vector(7 downto 0);
		-- sync_ctr_mon: out std_logic_vector(7 downto 0);

		-- System-level signals
		
		clk10: in std_logic;
		rst: in std_logic -- synchronous to clk10
	);
end entity bp_buck_sync;

architecture impl of bp_buck_sync is


	constant PERIOD: integer := 10;
	constant TSET_ZERO: integer := 1;
	constant TSAMPLE_ZERO: integer := 2;
	constant TSET_ONE: integer := 3;
	constant TSAMPLE_ONE: integer := 4;
	constant TSET_MARK: integer := 5;
	constant TRELEASE: integer := 8;


	signal sync_in: std_logic;
	signal sync_in_not: std_logic;
	signal sync_in_dly: std_logic;
	signal sync_in_dly2: std_logic;
	signal sync_out: std_logic := '1'; -- init for sim
	signal sync_out_not: std_logic;
	signal is_one: std_logic;
	signal is_zero: std_logic;
	signal send_data: std_logic;
	signal wr_bit: std_logic;
	signal sync_ctr: unsigned(7 downto 0);
	signal bit_ctr: unsigned(4 downto 0);
	signal wr_dat_shreg: std_logic_vector(31 downto 0);
	signal rd_dat_shreg: std_logic_vector(31 downto 0);

begin

	sync_mon <= sync_in;

	-- Output buffers
	iobuf0: IOBUF
		generic map (
			DRIVE => 12,
			SLEW  => "FAST"
		)
		port map (
			io => sync, -- Buffer inout port (connect directly to top-level port)
			i  => sync_out_not, -- Buffer input
			o  => sync_in_not, -- Buffer output. Conversion needed for simulation (converts weak H into '1')
			t  => sync_out_not -- 3-state enable input, high=input, low=output
		);

	sync_out_not <= sync_out;
	sync_in      <= sync_in_not;
	wr_bit       <= wr_dat_shreg(wr_dat_shreg'LEFT);

	buck_proc: process(all) begin
		if rising_edge(clk10) then
			if sync_ctr = TSAMPLE_ZERO then
				is_zero <= not sync_in;
			elsif sync_ctr = TSAMPLE_ONE then
				is_one <= not sync_in;
			end if;

			if (sync_ctr = TSET_ZERO and send_data = '1' and wr_bit = '0' and data_en = '1') or
			   (sync_ctr = TSET_ONE and send_data = '1' and wr_bit = '1' and data_en = '1') or
			   (sync_ctr = TSET_MARK) then
				sync_out <= '0';
			elsif sync_ctr = TRELEASE then
				sync_out <= '1';
				if is_one = '0' and is_zero = '0' then
					send_data <= '1';
					bit_ctr <= (others => '0');
					wr_dat_shreg <= wr_dat;
				else
					wr_dat_shreg <= wr_dat_shreg(30 downto 0) & '0';
					rd_dat_shreg <= rd_dat_shreg (30 downto 0) & (not is_zero);
					if bit_ctr = 31 then
						send_data <= '0';
						rd_dat_valid <= send_data;
						if send_data = '1' then
							rd_dat <= rd_dat_shreg (30 downto 0) & (not is_zero);
						end if;
					else
						bit_ctr <= bit_ctr + 1;
					end if;
				end if;
			end if;

			sync_in_dly <= sync_in;
			-- sync_in_dly2 <= sync_in_dly;
			if (sync_in = '1' and sync_in_dly = '0') or sync_ctr = PERIOD - 1 then -- if we encounter a rising edge
				sync_ctr <= (others => '0');
			else
				sync_ctr <= sync_ctr + 1;
			end if;

			-- Synchronous reset - overrides signals above
			if rst = '1' then
				send_data <= '0';
				-- release_ctr <= to_unsigned(tRELEASE, release_ctr'LENGTH);
				sync_ctr <= (others => '0');
				bit_ctr <= (others => '0');
				sync_out <= '1';
				sync_in_dly <= '0'; -- optional, for sim only
			end if; -- reset
		end if; -- CLK
	end process;


end architecture impl;

