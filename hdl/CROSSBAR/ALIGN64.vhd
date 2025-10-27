----------------------------------------------------------------------------------
-- Company: McGill University
-- Engineer: J.-F. Cliche
--
-- Create Date:    2025-01-30
-- Design Name: chFPGA
-- Module Name:    ALIGN64
-- Project Name: CHORD
-- Target Devices: Ultrascale+
-- Tool versions: Vivado 2022.2
-- Dependencies:
------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_misc.ALL; -- for and_reduce

library UNISIM;
use UNISIM.VComponents.ALL;

library xpm;
use xpm.vcomponents.all;

use work.chFPGA_Package.ALL; -- Get all component definitions


-- Aligns 64-bit data streams from multiple sources (lanes).
--
-- Buffer the incoming non-blocking streams for a fixed time after the lane 0 has arrived then start sending the data from all lanes.
--
-- Lanes that do not present a start-of-frame word at the FIFO after the window are flushed.
-- Lanes that start before the window, or any data that extends beyond lane 0, are also discarded.
-- Lanes that don't end are flushed until the next window.
--
-- Frames that do not start within a programmable window of time relative to a reference frame clock are discarded.
-- This window represents the worst case delay we can expect between lanes.
--
-- If one or more lanes are not sending data, the module will give up waiting for them at the end of the window and the available frames will be sent at the end on the window
--
-- The input is a non-blocking AXI4 Streaming bus. All buses must be clocked on a single clock.
--
-- See the architecture description for more information on how the entity's functionality was implemented.
entity align64 is
	generic (
		NUMBER_OF_LANES: integer         := 4; -- Number of buses to align
		ENABLE_MONITORING_LOGIC: BOOLEAN := FALSE; -- Enable additional monitoring logic for debugging
		-- Minimun number of words that will be stored before data is sent out. Must be large enough
		-- to account for 1) delay between lanes, plus 2) maximum dead times (tvalid=0) once data
		-- started arriving. Cannot exceed the FIFO depth, which is 512 words. Typical delays between bypass and GTY lanes are 35-45 words.
 		BUFFERING_DEPTH: integer := 64
	);
	port (
		-- Input interface (non-blocking, i.e. always accepts data)

		s_axis_tvalid: in slv(0 to NUMBER_OF_LANES - 1);
		s_axis_tdata: in slv_array(0 to NUMBER_OF_LANES - 1)(63 downto 0);
		s_axis_tlast: in slv(0 to NUMBER_OF_LANES - 1);

		-- Output interface (non-blocking, i.e. always sends data)

		m_axis_tvalid: out std_logic;
		m_axis_tdata: out slv_array(0 to NUMBER_OF_LANES - 1)(63 downto 0);
		m_axis_tlast: out std_logic;

		-- Operational parameters

		ignore_lane: in std_logic_vector(0 to NUMBER_OF_LANES - 1);


		-- Monitoring port (if ENABLE_MONITORING_LOGIC=TRUE)
		mon_reset: in std_logic;
		mon_lane: in std_logic_vector(3 downto 0);
		mon_source: in std_logic_vector(3 downto 0);
		mon_word: out std_logic_vector(15 downto 0);

		clk: in std_logic;
		rst: in std_logic -- Synchronous reset synchronized to CLK
	);
end entity align64;


-- This is a pipelined implementation of the aligner that reduces the logic depth.
-- This design works on a 400 MHz clock on Ultrascale+.
--
-- This implementation
-- introduces a 2-clock dead time between the time the a SOF (start of frame)
-- is detected valid and the time readout begins. This means that the input
-- must have 2 idle cycles (no valid data) on average per frame. Fortunately,
-- these are naturally introduced by the packet framing protocol.
--
-- The ``valid_lane`` vector indicates if the data for the corresponding lane
-- is to be send to the output ('1') or if it is to be discarded ('0').
--
-- When ``valid_lane(i)`` is '0', the input of the corresponding FIFO is read continuously in
-- order to flush the data, but will not read out a SOF if it appears during
-- the SOF window. Since on average the FIFO is emptied faster than it is filled, the
-- FIFO will eventuelly be emptied of any packet that do not start in a valid
-- window.
--
-- When ``valid_lane(i)`` is '1', the FIFO output will be read out only if all
-- currently valid lanes have data (tvalid=1). In that case, the data is
-- passed on to the output.
--
-- ``valid_lane(i)`` is set on the last clock of the SOF window. By that time, any
-- frame that started within the SOF window will have a SOF word waiting at
-- the FIFO's output. ``valid_lane(i)`` is set to '1' for any lane where the FIFO
-- offers an SOF, and '0' for the others.
--
-- When an EOF is read out of a FIFO, its ``valid_lane(i)`` is set to 0 to
-- indicate that we should not wait for data on that lane anymore. This is
-- needed in the case where a lane is shorter than the other ones so we don't
-- fill up the FIFO while waiting for data that is not coming.
--
-- ``valid_lane(i)`` is also set to '0' when EOF is read out of the reference
-- lane. Normally all lanes read out their EOF at the same time. However, this will
-- flush a lane that is too long relative to the reference lane.
--
architecture impl of align64 is

	-- Attributes

	attribute DONT_TOUCH: string;

	--- Signal definitions ------------------------------------

	signal ignore_lane_reg: std_logic_vector(0 to NUMBER_OF_LANES - 1); -- registered verson of the lanes to be ignored

	signal is_sof: std_logic_vector(0 to NUMBER_OF_LANES - 1);
	signal is_eof: std_logic_vector(0 to NUMBER_OF_LANES - 1);

	signal read_en: std_logic_vector(0 to NUMBER_OF_LANES - 1);

	-- Monitoring signals
	signal valid_lane: std_logic_vector(0 to NUMBER_OF_LANES - 1);
	signal missing_frame: std_logic_vector(0 to NUMBER_OF_LANES - 1);
	signal bad_frame_length: std_logic_vector(0 to NUMBER_OF_LANES - 1);
	signal fifo_tfirst_mon: std_logic_vector(0 to NUMBER_OF_LANES - 1);
	signal fifo_underflow: std_logic_vector(0 to NUMBER_OF_LANES - 1);
	signal fifo_overflow: std_logic_vector(0 to NUMBER_OF_LANES - 1);


	signal fifo_wr_en: slv(0 to NUMBER_OF_LANES - 1);
	signal fifo_tdata: slv64_array(0 to NUMBER_OF_LANES - 1);
	signal fifo_tvalid: slv(0 to NUMBER_OF_LANES - 1);
	signal fifo_tlast: slv(0 to NUMBER_OF_LANES - 1);
	signal fifo_tfirst: slv(0 to NUMBER_OF_LANES - 1);
	signal fifo_rd_en: std_logic_vector(0 to NUMBER_OF_LANES - 1);
	signal fifo_empty: slv(0 to NUMBER_OF_LANES - 1);
	signal fifo_almost_full: slv(0 to NUMBER_OF_LANES - 1);
	signal fifo_almost_empty: slv(0 to NUMBER_OF_LANES - 1);
	signal fifo_lane0_almost_empty_reg: slv(0 to NUMBER_OF_LANES - 1);
	signal fifo_wr_count: slv10_array(0 to NUMBER_OF_LANES - 1);

	attribute DONT_TOUCH of fifo_lane0_almost_empty_reg: signal is "yes"; -- Don't remove equivalent registers, we use those to ease distribution


begin

	-------------------------------------------------
	-- ALIGN FIFOs
	-------------------------------------------------
	-- Buffer the incoming non-blocking streams so we can hold the data until all lanes are aligned.
	-- The FIFOs are FWFT, and their outputs must be registered to make sure they are not the critical path in the timing.
	-- The design assumes zero latency, but the embedded registers on an Ultrascale+ Embedded synchronous FIFO can be  used with no latency cost.
	-- The FIFO is 512-deep, although the maximum we need is the Delay between lane 0 and the other lanes (typically about 30-40 words), plus some margin
	-- to absorb the longest period of tvalid=0.
	--
	fifogen: for i in 0 to NUMBER_OF_LANES - 1 generate

		-- Write the FIFO except when almost full so we has room to write the TLAST frame
		fifo_wr_en(i) <= s_axis_tvalid(i) and ((not fifo_almost_full(i)) or s_axis_tlast(i));

		-- Read FIFO only if read is requested and lane 0 is not almost empty. Almost empty
		-- threshold should be large enough so data from other lanes are guaranteed to have arrived
		-- by the time lane 0 is not almost empty.
		fifo_rd_en(i) <= read_en(i) and not fifo_lane0_almost_empty_reg(i);

		fifo0: entity work.align64_fifo
			generic map (
				ALMOST_EMPTY_THRESH => BUFFERING_DEPTH
				)
			port map (
				s_axis_tvalid => fifo_wr_en(i),
				s_axis_tdata  => s_axis_tdata(i),
				s_axis_tlast  => s_axis_tlast(i),

				m_axis_tvalid => fifo_tvalid(i),
				m_axis_tdata  => fifo_tdata(i),
				m_axis_tlast  => fifo_tlast(i),
				m_axis_tready => fifo_rd_en(i),

				empty       => fifo_empty(i),
				almost_full => fifo_almost_full(i),
				almost_empty => fifo_almost_empty(i),
				wr_count    => fifo_wr_count(i),

				clk => clk,
				rst => rst
			);

	end generate fifogen;

	-- useful flags
	is_sof          <= fifo_tvalid and fifo_tfirst;
	is_eof          <= fifo_tvalid and fifo_tlast;

	out_proc: process(all) begin
		if rising_edge(clk) then
			-- register the ignore_lane flags to facilitate timing closure.
			ignore_lane_reg <= ignore_lane;


			-- Generate a tfirst signal for the data coming out of the FIFO. Used to generate is_sof()
			for i in 0 to NUMBER_OF_LANES - 1 loop
				fifo_tfirst(i) <= fifo_tlast(i) when fifo_tvalid(i) and read_en(i);
			end loop;


			for i in 0 to NUMBER_OF_LANES - 1 loop

				-- Register and distribute the Lane 0 almost empty flag that will be used by each FIFO.
				fifo_lane0_almost_empty_reg(i) <= fifo_almost_empty(0);

				fifo_underflow(i) <= fifo_rd_en(i) and not fifo_tvalid(i);
				fifo_overflow(i) <= fifo_almost_full(i);

				-- bad_frame_length is pulsed if we read out an EOF on lane i but not on lane 0
				bad_frame_length(i) <= '0' when ignore_lane_reg(i) else (is_eof(i) and fifo_rd_en(i)) and not (is_eof(0) and fifo_rd_en(0));
				-- missing_frame is pulsed if lane i is not SOF when lane 0 is
				missing_frame(i) <= '0' when ignore_lane_reg(i) else not is_sof(i) and is_sof(0);
				-- valid_lane is '1' if lane i starts at the same time as lane 0
				valid_lane(i) <= '1' when ignore_lane_reg(i) else is_sof(i) when is_sof(0);


				-- Always start reading the FIFO when we have a lane 0 SOF window to eigher read valid data or flush bad one.
				-- Stop reading the FIFO when an EOF has been read out.
				read_en(i) <= '1' when is_sof(0) or ignore_lane_reg(i) else
				           '0' when is_eof(i) and fifo_rd_en(i);
				-- Note
				--  - If the frame is longer than a period, bad_frame_length and valid_frame will be flagged and flushing reads will continue
				--  - If there is no data, flush reading will be still enabled. If the frame comes later, it will be flushed.

				-- Register the FIFO output data
				m_axis_tdata(i) <= fifo_tdata(i);
			end loop;
			m_axis_tvalid <= fifo_tvalid(0) and fifo_rd_en(0); -- A transfer occurs only when all the data lines are valid.  all_valid is 1 when no lane is valid, but the second term implies that at least one lane (the current lane) is valid.
			m_axis_tlast <= fifo_tlast(0); -- Set the last flag from the FIFO if the lane is still being sent. If it was interrupted early and data is being discarded, EOF will not appear with global_tlast.

			-- Synchronous reset
			-- The reset code is placed at the end to avoid the non-resetted signals to hold their value during reset (which requires additional logic).
			if rst = '1' then
				fifo_tfirst <= (others => '1');
				--bad_frame_length <= (others => '0');
				--missing_frame <= (others => '0');
				valid_lane <= (others => '1');
				read_en <= (others => '0');
				m_axis_tvalid <= '0';
			end if; -- rst

		end if; -- clk
	end process;

	-- This block implement logic to monitor the packet aligner internal states.
	-- ``mon_lane`` and ``mon_source`` selects which lane and which signal are being monitored on the ``mon_word`` bus.
	-- Stats/counter/sticky bits are reset when ``mon_reset`` is high.
	--
	mon_gen: if ENABLE_MONITORING_LOGIC generate
		signal mon_reset_all: std_logic;
		signal s_axis_tfirst: std_logic_vector(0 to NUMBER_OF_LANES - 1);
		signal clk_ctr: unsigned(15 downto 0);
		signal lane_delay: unsigned(15 downto 0);
		signal flags: unsigned(15 downto 0);
		signal sticky_flags: unsigned(15 downto 0);
		signal fifo_overflow_sticky: std_logic_vector(0 to NUMBER_OF_LANES - 1);
		signal fifo_underflow_sticky: std_logic_vector(0 to NUMBER_OF_LANES - 1);
		signal missing_frame_sticky: std_logic_vector(0 to NUMBER_OF_LANES - 1);
		signal bad_frame_length_sticky: std_logic_vector(0 to NUMBER_OF_LANES - 1);
		signal valid_lane_sticky: std_logic_vector(0 to NUMBER_OF_LANES - 1);
		signal mon_word_int: unsigned(15 downto 0);
	begin

		-- Make sure the reset from the BSB register is synchronous to clk to prevent counter glitches when it is released
		rst_cdc0: xpm_cdc_async_rst
			generic map (RST_ACTIVE_HIGH => 0)
			port map (
				src_arst  => mon_reset or rst,
				dest_clk  => clk,
				dest_arst => mon_reset_all
				);

		mon_proc: process(all)
			variable lane: integer;
		begin
			mon_word <= std_logic_vector(mon_word_int);

			if rising_edge(clk) then
				lane := to_integer(unsigned(mon_lane));

				-- Generate a tfirst signal for the incoming data. Used for incoming data differential delay monitoring.
				for i in 0 to NUMBER_OF_LANES - 1 loop
					s_axis_tfirst(i) <= '0' when mon_reset_all else s_axis_tlast(i) when s_axis_tvalid(i);
				end loop;

				clk_ctr <= (others => '0') when mon_reset_all or (s_axis_tvalid(0) and s_axis_tfirst(0)) else clk_ctr + 1 when not all_ones(clk_ctr);
				lane_delay <= (others => '0') when mon_reset_all else clk_ctr when (s_axis_tvalid(lane) and s_axis_tfirst(lane));

				fifo_overflow_sticky <= (others => '0') when mon_reset_all else (fifo_overflow_sticky or fifo_overflow);
				fifo_underflow_sticky <= (others => '0') when mon_reset_all else (fifo_underflow_sticky or fifo_underflow);
				missing_frame_sticky <= (others => '0') when mon_reset_all else (missing_frame_sticky or missing_frame);

				bad_frame_length_sticky <= (others => '0') when mon_reset_all = '1' else (bad_frame_length_sticky or bad_frame_length);
				valid_lane_sticky <= (others => '1') when mon_reset_all else valid_lane_sticky and valid_lane;

				case to_integer(unsigned(mon_source)) is

					when 0 => -- Overall error flags (all lanes). Use to assess aligner global state in a single read.
						mon_word_int <=
						(
						 8      => or fifo_overflow_sticky,
						 9      => or fifo_underflow_sticky,
						 10      => or missing_frame_sticky,
						 11      => or bad_frame_length_sticky,
						 12      => or (not valid_lane_sticky),
						 others => '0'
						);

					when 1 => -- flags (sticky or not)
						mon_word_int <=
						(
						 0      => fifo_overflow(lane),
						 1      => fifo_underflow(lane),
						 3      => missing_frame(lane),
						 4      => bad_frame_length(lane),
						 5      => not valid_lane(lane),

						 8      => fifo_overflow_sticky(lane),
						 9      => fifo_underflow_sticky(lane),
						 10      => missing_frame_sticky(lane),
						 11      => bad_frame_length_sticky(lane),
						 12      => not valid_lane_sticky(lane),
						 others => '0'
						);

					when 3 => -- FIFO occupancy
						mon_word_int <= resize(unsigned(fifo_wr_count(lane)), 16);

					when 4 => -- lane delay
						mon_word_int <= lane_delay;

					when 5 => -- FIFO overflow counter
						mon_word_int <= (others => '0') when mon_reset_all else mon_word_int + 1 when fifo_overflow(lane);

					when 6 => -- missing frame counter
						mon_word_int <= (others => '0') when mon_reset_all else mon_word_int + 1 when missing_frame(lane);

					when 7 => -- bad frame length counter
						mon_word_int <= (others => '0') when mon_reset_all else mon_word_int + 1 when bad_frame_length(lane);

					when 8 => -- invalid lane counter
						mon_word_int <= (others => '0') when mon_reset_all else mon_word_int + 1 when not valid_lane(lane);

					when 9 => -- clock counter since lane 0 tfirst
						mon_word_int <= clk_ctr;

					when others =>
						mon_word_int <= (others => '0');

				end case;
			end if; -- clk
		end process;

	end generate mon_gen;

end architecture impl;
