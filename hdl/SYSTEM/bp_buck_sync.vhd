----------------------------------------------------------------------------------
--! @file
--! @brief IIC interface
-- Company: Mc Gill University
-- Engineer: J.-F. Cliche
--
-- Create Date:    2012-03-28
-- Design Name:
-- Module Name:    I2C - Behavioral
-- Project Name: CHIME
-- Target Devices:
-- Tool versions: ISE 13.4
-- Description: Implements a I2C interface
--
-- Dependencies:
--
-- Revision:
--   2012-03-28 JFC: Created
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.chFPGA_Package.all; -- Get all component definitions

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

------------ ENTITY DECLAREATION ------------------
--! @brief
--! This module implements I^2C interface that is compliant with the I2C and PMBUs standard.
--! The interface operate at a fixed speed of about 100 KHz.
--! The I2C transaction can be performed in 1 or 2 phases:
--!  Phase 1: The I2C address is sent, and BYTES1 bytes are read or written depending on the R/W bit of the command
--!  Phase 2: if
entity bp_buck_sync is
    port (
		--Buck sync
		sync: inout std_logic;
		sync_mon: out std_logic;

		data_en: in std_logic := '0';
		wr_dat: in std_logic_vector(31 downto 0);
		rd_dat: out std_logic_vector(31 downto 0);
		rd_dat_valid: out std_logic;
		release_ctr_mon: out std_logic_vector(7 downto 0);
		sync_ctr_mon: out std_logic_vector(7 downto 0);
		-- System-level signals
		clk10: in STD_LOGIC;
		rst: in STD_LOGIC -- synchronous to clk10
	);
end bp_buck_sync;

architecture Behavioral of bp_buck_sync is


constant PERIOD: integer := 10;
constant tSET_ZERO: integer := 1;
constant tSAMPLE_ZERO: integer := 2;
constant tSET_ONE: integer := 3;
constant tSAMPLE_ONE: integer := 4;
constant tSET_MARK: integer := 5;
constant tRELEASE: integer := 8;


signal sync_in: std_logic;
signal sync_in_not: std_logic;
signal sync_in_dly: std_logic;
signal sync_in_dly2: std_logic;
signal sync_out: std_logic := '1'; -- init for sim
signal sync_out_not: std_logic;
signal is_one: std_logic;
signal is_zero: std_logic;
signal send_data: std_logic;
signal release_ctr: unsigned(7 downto 0);
signal wr_bit: std_logic;
signal sync_ctr: unsigned(7 downto 0);
signal bit_ctr: unsigned(4 downto 0);
signal wr_dat_shreg: std_logic_vector(31 downto 0);
signal rd_dat_shreg: std_logic_vector(31 downto 0);

begin
sync_mon <= sync_in;
release_ctr_mon <= std_logic_vector(release_ctr);
sync_ctr_mon <= std_logic_vector(sync_ctr);

-- Output buffers
IOBUF0 : IOBUF
	generic map (
		DRIVE => 12,
		SLEW => "FAST"
		)
	port map (
		IO => sync, -- Buffer inout port (connect directly to top-level port)
		I => sync_out_not, -- Buffer input
		O => sync_in_not, -- Buffer output. Conversion needed for simulation (converts weak H into '1')
		T => sync_out_not -- 3-state enable input, high=input, low=output
	);

sync_out_not <= sync_out;
sync_in <= sync_in_not;
wr_bit <= wr_dat_shreg(wr_dat_shreg'LEFT);
buck_proc: process(clk10)
	begin
		if rising_edge(clk10) then

			if sync_ctr = tSAMPLE_ZERO then
				is_zero <= not sync_in;
			elsif sync_ctr = tSAMPLE_ONE then
				is_one <= not sync_in;
			end if;

			if (sync_ctr = tSET_ZERO and send_data='1' and wr_bit='0' and data_en='1') or
			   (sync_ctr = tSET_ONE and send_data='1' and wr_bit='1' and data_en='1') or
			   (sync_ctr = tSET_MARK) then
				sync_out <= '0';
			elsif sync_ctr = tRELEASE then
				sync_out <= '1';
				if is_one='0' and is_zero='0' then
					send_data <= '1';
					bit_ctr <= (others=>'0');
					wr_dat_shreg <= wr_dat;
				else
					wr_dat_shreg <= wr_dat_shreg(30 downto 0) &  '0';
					rd_dat_shreg <= rd_dat_shreg (30 downto 0) & (not is_zero);
					if bit_ctr=31 then
						send_data <= '0';
						rd_dat_valid <= send_data;
						if send_data='1' then
							rd_dat <= rd_dat_shreg (30 downto 0) & (not is_zero);
						end if;
					else
						bit_ctr <= bit_ctr + 1;
					end if;
				end if;
			end if;

			sync_in_dly <= sync_in;
			-- sync_in_dly2 <= sync_in_dly;
			if (sync_in='1' and sync_in_dly='0') or sync_ctr=PERIOD-1 then -- if we encounter a rising edge
				sync_ctr <= (others=>'0');
			else
				sync_ctr <= sync_ctr + 1;
			end if;

			-- Synchronous reset - overrides signals above
			if rst='1' then
				send_data <= '0';
				-- release_ctr <= to_unsigned(tRELEASE, release_ctr'LENGTH);
				sync_ctr <= (others=>'0');
				bit_ctr <= (others=>'0');
				sync_out <= '1';
				sync_in_dly <= '0'; -- optional, for sim only
			end if; -- reset
		end if; -- CLK

	end process;


end Behavioral;

