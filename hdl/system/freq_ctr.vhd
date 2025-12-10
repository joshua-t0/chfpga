----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date:    10:43:45 06/01/2011
-- Design Name:
-- Module Name:    FREQ_CTR - impl
-- Project Name:
-- Target Devices:
-- Tool versions:
-- Description: Multiport frequency counter. Measures the frequency of one of 'NUMBER_OF_PORTS' clock signal in addition to that of the CLK200 and CTRL_CLK clocks.
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
--  110601 JFC: Created
--  110922 JFC: Eliminated internal generation of CLK200_DIV2 and CTRL_CLK_DIV2 signals. Those are now provided externally.
--  120406 JFC: Cleanup. Changed for new AXI4S control interface.
--  121105 JFC: Switch to synchronous reset. Removed RST since START_FREQ_CR is pulsed anyway for each read. Added intermediary GATE_TIME registers and end-of-count signals to facilitate timing.
--  121119 JFC: Put the source clock counter process back to async reset to better handle when the source clock is absent
--  130209 JFC: Added an explicit BUFR on SRC_SEL
-- Additional Comments:
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use IEEE.NUMERIC_STD.ALL;
use work.chFPGA_Package.ALL; -- Get all component definitions

library UNISIM;
use UNISIM.VComponents.ALL;

library xpm;
use xpm.vcomponents.ALL;

-- Implements a frequency counter
--
-- This module measures the frequency of a signal relative to the clk200
-- clock. The gate time and operation of the frequency counter is controlled
-- by registers.
--
-- The signal to be measured is a logic line (not a clock line) toggling at half the clock frequency. This signal can be generated easily with a flip-flop and does not require any clocking routing ressources.
-- The gate time is specified by the user to control the resolution of the counter.
-- The accuracy is determined by the accuracy of the reference clock.
entity freq_ctr is
	generic (
		FPGA_SERIES: integer;
		NUMBER_OF_CLK_IN_PORTS: integer := 8
	);
	port (
		-- Control interface
		ctrl_cmd_in_dat: in axis8_dat_struct; -- Command stream input, signals from master (Data, Valid, Last)
		ctrl_cmd_in_rdy: out axis8_rdy_struct; -- Command stream input, signals to master (Ready)
		ctrl_rply_out_dat: out axis8_dat_struct; -- Reply stream output, signals to slave (Data, Valid, Last)
		ctrl_rply_out_rdy: in axis8_rdy_struct; -- Reply stream output,  signals from slave (Ready)
		ctrl_clk: in  std_logic;
		ctrl_rst: in std_logic;

		clk200: in std_logic; -- Reference clock
		clk_in_div2: in std_logic_vector(0 to NUMBER_OF_CLK_IN_PORTS - 1);

		-- System-level signals
		rst: in std_logic -- synchronous to CLK200
	);
end entity freq_ctr;

architecture impl of freq_ctr is

	attribute DONT_TOUCH: string;
	attribute CLOCK_DEDICATED_ROUTE: string;

	--- Define Control word and its signals
	signal control_bytes: slv8_array(0 to 4); -- default value set in the CMD_SLAVE
	signal status_bytes: slv8_array(0 to 4); -- default value set in the CMD_SLAVE


	signal gate_ctr: unsigned(31 downto 0) := (others => '0');
	signal freq_ctr: unsigned(31 downto 0) := (others => '0');
	signal freq_ctr_rdy: std_logic;
	signal freq_ctr_rdy_sync: std_logic;
	signal freq_ctr_start: std_logic := '0';
	signal freq_ctr_start_clk200: std_logic;
	signal freq_ctr_start_srcclk: std_logic;
	signal gate_en: std_logic := '0';
	signal gate_en_sync: std_logic;
	signal freq_ctr_src_sel: unsigned(6 downto 0) := (others => '0');
	signal src_clk: std_logic;
	attribute dont_touch of src_clk: signal is "yes";

	signal src_clk_fabric: std_logic;
	attribute dont_touch of src_clk_fabric: signal is "yes";
	attribute clock_dedicated_route of src_clk_fabric: signal is "false";

	signal gate_period: unsigned(31 downto 0); -- gate_period=40E6 Corresponds to a gate_period/CLK200_FREQ= 0.2s second gate time. Since inputs are divided by 2, real frequency is 100*count.
-- signal gate_period_minus_1: unsigned(31 downto 0);

-----------------------------------------------------------------------------------
-- Memory map
--
-- ------------------------------------------------------------------------------
-- |  Page   | Addr|Bit(s)|     Name             | Description                   |
-- |---------|-----|------|----------------------|-------------------------------|
-- | CONTROL | 0:3 | 31:0 | gate_period          | Gate time in CLK200 cycles. The frequency counter counts source clock edges during this period. |
-- |         |  4  |   7  | freq_ctr_start       | Start a frequency measurement. Set to '1' to begin, then clear to '0' before starting a new measurement. |
-- |         |     |  6:0 | freq_ctr_src_sel     | Selects which clock input (0 to 127) to measure. |
-- | STATUS  | 0:3 | 31:0 | freq_ctr             | Measured frequency count (number of source clock edges during gate period). |
-- |         |  4  |  7:1 | (unused)             |                               |
-- |         |     |   0  | freq_ctr_rdy         | Ready flag. Set to '1' when measurement is complete and freq_ctr is valid. |
-- ------------------------------------------------------------------------------

begin

	-- CONTROL Byte 0-3
	gate_period(31 downto 0)    <= to_unsigned(control_bytes(0 to 3)); -- to_unsigned() accepting Byte Arrays is defined in the project package

	-- CONTROL Byte 4

	freq_ctr_start              <= control_bytes(4)(7);
	freq_ctr_src_sel            <= unsigned(control_bytes(4)(6 downto 0));

	-- STATUS bytes 0-3
	status_bytes(0 to 3)        <= to_slv8_array(freq_ctr);

	-- STATUS bytes 4
	status_bytes(4)(7 downto 1) <= (others => '0');
	status_bytes(4)(0)          <= freq_ctr_rdy_sync;

	-- Convert clock inputs into a divided by two logic signal


	bsb_regs0: entity work.bsb_regs
		generic map (
			NUMBER_OF_CONTROL_BYTES => control_bytes'Length(1), -- Length of array in the first dimension: number of bytes
			NUMBER_OF_STATUS_BYTES  => status_bytes'Length(1),
			DEFAULT_CONTROL_BYTES   => X"02625A00_00"
		)

		port map (
			-- Control interface (command and reply stream buses)
			ctrl_cmd_in_dat   => ctrl_cmd_in_dat,
			ctrl_cmd_in_rdy   => ctrl_cmd_in_rdy,
			ctrl_rply_out_dat => ctrl_rply_out_dat,
			ctrl_rply_out_rdy => ctrl_rply_out_rdy,
			ctrl_clk          => ctrl_clk,
			ctrl_rst          => ctrl_rst,

			control_bytes => control_bytes,
			status_bytes  => status_bytes
		);

	-- Select clock to measure
	src_clk_fabric <= clk_in_div2(to_integer(freq_ctr_src_sel));

	-- Pass the selected signal through a clock buffer to facilitate timing and remove tool complaints
	-- A regional/horizontal clock  will suffice as the frequency counter is very localized
	-- For the K7, we use a BUFH, as there usually  are plenty of them (12 per clock regions), where BUFGs are scarce/.
	k7: if FPGA_SERIES = 7 generate

		srcclk0: BUFH
			port map (
				i => src_clk_fabric,
				o => src_clk
			);

	end generate k7;

	-- For the Ultrascale+, we have plenty of BUFGs (24 per clock region). The
	-- clock network is flexible an dallows those to use only localized clocking
	-- tracks. There are no other types of clock buffers apart from varioants of
	-- BUFG.
	--
	-- We also use a BUFG for Virtex 6. There are 32 BUFGs in a chip (16 on top
	-- half, 16 on bottom half). BUFH and BUFR could also potentially be used.
	-- Optimal buffer selection was not done as this is mostly legacy tech now.
	v6: if FPGA_SERIES = FPGA_VIRTEX6 or FPGA_SERIES = FPGA_ULTRASCALEPLUS generate

		srcclk0: BUFG
			port map (
				i => src_clk_fabric, -- 1-bit input: Clock buffer input
				o => src_clk -- 1-bit output: Clock buffer output
			);
	end generate v6;

	-- resynchronize the gate_en signal to the src_clk to make sure we don't mess up the freq_ctr counter operation
	gate_en_cdc: xpm_cdc_single
		port map (
			src_clk  => clk200, -- optional; required when SRC_INPUT_REG = 1
			src_in   => gate_en,
			dest_clk => src_clk,
			dest_out => gate_en_sync
		);

	-- resynchronize the  freq_ctr reset signal
	gate_rst_cdc: xpm_cdc_async_rst
		generic map (
			RST_ACTIVE_HIGH => 0
		)
		port map (
			src_arst  => freq_ctr_start, -- resets when '0'
			dest_clk  => src_clk,
			dest_arst => freq_ctr_start_srcclk
		);

	-- Control signal from ctrl_clk to clk200
	freq_start_cdc: xpm_cdc_single
		port map (
			src_clk  => ctrl_clk, -- optional; required when SRC_INPUT_REG = 1
			src_in   => freq_ctr_start,
			dest_clk => clk200,
			dest_out => freq_ctr_start_clk200
		);

	-- control signal from clk200 to ctrl_clk
	freq_rdy_cdc: xpm_cdc_single
		port map (
			src_clk  => clk200, -- optional; required when SRC_INPUT_REG = 1
			src_in   => freq_ctr_rdy,
			dest_clk => ctrl_clk,
			dest_out => freq_ctr_rdy_sync
		);

	-- Source clock counter process
	--
	-- When freq_ctr_start_clk200 goes down to 0 on the CLK200 edge, gate counter is asynchronously reset, even if there is no src_clk.
	-- When freq_ctr_start_sync goes up, We are certain that  the counter is zero, and gate_en_sync is also zero assuming 1) there is a src_clk and 2) freq_ctr_start_clk200 was held low long enough for gate_en_sync to propagate through the synchronizer.
	-- Since gate_en_sync is zero when  freq_cctr_start_sync goes up, we don't have to worry that any part of the counter will start counting anomalously.
	-- Eventually, the gate_en signal will propagate to gate_en_sync (on the src_clk clk) and count will start.
	-- If gate_en is held high for time T, gate_en_sync will also be held high for the same time, plus or minus a src_clk cycle, since the synchronizer latency is fixed.
	src_ctr_proc: process(src_clk, freq_ctr_start_srcclk)
	begin
		if freq_ctr_start_srcclk = '0' then -- We need an asynchronous reset to clear the counter even in the absence of the source clock
			freq_ctr <= (others => '0');
		elsif rising_edge(src_clk) then
			if gate_en_sync = '1' then
				freq_ctr <= freq_ctr + 1;
			end if;
		end if; -- CLK
	end process;

	-- Reference clock counter
	--
	-- Generates a gate_en pulse of the desired length in terms of the clk200 clock cycles.
	-- gate_period=N will generate a gate_en of N clk200 cycles long.
	-- freq_ctr_rdy is cleared when freq_ctr_start_clk200=0, and is set when the gate period is complete. freq_ctr will stabilize a few stc_slk later after gate_en has time to propagate through the synchronizer.
	-- freq_ctr_start_clk200 is resynchronized to clk200 to make sure all the internal registers of the gate counter start at the same time.
	ref_ctr_proc: process(clk200)
	begin
		if rising_edge(clk200) then
			-- gate_period_minus_1 <= gate_period - 1; -- register the gate period to isolate the timing from the SLAVE. We substract 2 to have an accurate count given the pipelinning delays.

			-- Create a signal that indicates if we reached the total gate time. This is to simplify the logic and facilitate timing closure.
			if gate_ctr = gate_period then
				gate_en <= '0';
				freq_ctr_rdy <= '1';
			else
				gate_en <= '1';
				freq_ctr_rdy <= '0';
				gate_ctr <= gate_ctr + 1;
			end if;

			-- synchronous reset operrides
			if freq_ctr_start_clk200 = '0' then
				gate_ctr <= (others => '0');
				freq_ctr_rdy <= '0';
				gate_en <= '0';
			end if;

		end if; -- CLK
	end process;


end architecture impl;

