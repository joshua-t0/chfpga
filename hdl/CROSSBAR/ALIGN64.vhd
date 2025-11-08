----------------------------------------------------------------------------------
-- Company: McGill University
-- Engineer: J.-F. Cliche
--
-- Description: Robustly aligns multiple AXI-S streams to a common TVALID/TLAST framing 
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
-- Lane 0 is used as a reference for the alignment, and the output tvalid/tlast are delayed verison of it.
-- tvalid/tlast will always be present even if a lane is missing, misalign etc. 
-- ``lane_error`` indicates that the data on a specific lane is no longer reliable.
--
-- Lanes that do not start at the same time as lane 0 after the FIFO are flushed from the FIFO until the FIFO is empty and an TLAST is encountered, and re-alignment is tested on the next Lane 0 start.

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

        lane_error: out std_logic_vector(0 to NUMBER_OF_LANES - 1);

		-- Optional Monitoring port (if ENABLE_MONITORING_LOGIC=TRUE)

		mon_reset: in std_logic := '0';
		mon_lane: in std_logic_vector(3 downto 0) := (others => '0');
		mon_source: in std_logic_vector(3 downto 0) := (others => '0');
		mon_word: out std_logic_vector(15 downto 0);

		clk: in std_logic;
		rst: in std_logic -- Synchronous to CLK
	);
end entity align64;


-- This is a pipelined implementation of the aligner that reduces the combinatorial logic depth.
-- This design works at 400 MHz clock on Ultrascale+.
--
-- Principle of operations:
--
-- 
-- We implement an array of FIFOs, one per lane, to absorb time difference between lanes.
-- The challenge is to make the alignment process resilient to mangled or missing frames, while avoiding combinatorial logic between FIFOs.
--
-- Lane 0 is our time reference. Our goal is to align all lanes to lane 0 at the output of the FIFOs.
-- Lane 0 is ALWAYS read when the buffer has at least  BUFFERING_DEPTH words in it, whatever happens to the other lanes. This is effectively a delay line, and ensures that all the other lanes have had time to catch up on lane 0, which is assumed to be faster than the other lanes.
-- If LANE 0 delay is long enough, the other lanes will also always have some words queued up in in the FIFO. This brings many key benefits:
--
-- - This guarantees that data exists on other lanes when lane 0 is read. So no need to have combinatorial read-enable logic that immediately reacts to the FIFO status.
-- - We can tolerate a latency between the almost_full and actual FIFO read enable, allowing the registering of the read enable signal distributed between FIFOs.
--
-- All lanes are completely independent from each other. The only signal that is shared between lanes is Lane 0 read enable signal, which is a registered version of ``not almost_empty``..
--
-- A simple state machine controls the readout of each lane.
--
-- In the READ state, all lanes are extected to be aligned, and we simultaneously read words from all lanes when lane 0 does so. 
-- If a lane is not starting when lane 0 starts, we enter the FLUSH_UNTIL_EMPTY to bring the FIFO to almost empty, then enter FLUSH_UNTIL_EOF to continue flushing but stop after TLAST is read out.
-- We then hold the following SOF (if anything is coming) until the next Lane 0 SOF which puts us back in READ mode. If SOF alignment is not yet acheived, we repeat te process, otherwise we stay in READ mode.
--
-- Flushing down to almost_empty is performed to prevent the FIFO from having its occupancy gradually creep up when bad alignments happen.
--
-- Flushing works only if the incoming data is not valid on every clock cycle. These dead times are necessary for the flush operation to empty the FIFO faster than it fills up.
--
architecture impl of align64 is

	-- Attributes

	attribute DONT_TOUCH: string;

	--- Signal definitions ------------------------------------

	signal is_sof: std_logic_vector(0 to NUMBER_OF_LANES - 1);
	signal is_eof: std_logic_vector(0 to NUMBER_OF_LANES - 1);

	signal fifo_wr_en: slv(0 to NUMBER_OF_LANES - 1);
	signal fifo_tdata: slv64_array(0 to NUMBER_OF_LANES - 1);
	signal fifo_tvalid: slv(0 to NUMBER_OF_LANES - 1);
	signal fifo_tlast: slv(0 to NUMBER_OF_LANES - 1);
	signal fifo_tfirst: slv(0 to NUMBER_OF_LANES - 1);
	signal fifo_rd_en: std_logic_vector(0 to NUMBER_OF_LANES - 1);
	signal fifo_empty: slv(0 to NUMBER_OF_LANES - 1);
	signal fifo_almost_full: slv(0 to NUMBER_OF_LANES - 1);
	signal fifo_almost_empty: slv(0 to NUMBER_OF_LANES - 1);
	signal fifo_wr_count: slv10_array(0 to NUMBER_OF_LANES - 1);

	signal fifo_lane0_rd_en: slv(0 to NUMBER_OF_LANES - 1);
	attribute DONT_TOUCH of fifo_lane0_rd_en: signal is "yes"; -- Don't remove equivalent registers, we use those to ease distribution

	type LANE_STATE_TYPE is (READ, FLUSH_UNTIL_EMPTY, FLUSH_UNTIL_EOF, HOLD);
	type lane_state_array is array(0 to NUMBER_OF_LANES - 1) of LANE_STATE_TYPE;
	signal lane_state: LANE_STATE_ARRAY;

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

		-- Write the FIFO except when almost full so we has room to write the TLAST frame which will help recovering sync faster
		fifo_wr_en(i) <= s_axis_tvalid(i) and ((not fifo_almost_full(i)) or s_axis_tlast(i));

		-- Read FIFO only if read is requested and lane 0 is not almost empty. Almost empty
		-- threshold should be large enough so data from other lanes are guaranteed to have arrived
		-- by the time lane 0 is not almost empty.
		fifo_rd_en(i) <= '1' when lane_state(i)=READ and fifo_lane0_rd_en(i)='1' else
		                 '1' when lane_state(i)=FLUSH_UNTIL_EMPTY else
		                 '1' when lane_state(i)=FLUSH_UNTIL_EOF else
		                 '0';

		fifo0: entity work.align64_fifo
			generic map (
				ALMOST_EMPTY_THRESH => BUFFERING_DEPTH,
				ALMOST_FULL_THRESH => 500  -- keep enough room to make sure we don't miss any TLAST flags
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

			for i in 0 to NUMBER_OF_LANES - 1 loop

    			-- Generate a tfirst signal for the data coming out of the FIFO. Used to generate is_sof()
				fifo_tfirst(i) <= fifo_tlast(i) when fifo_tvalid(i) and fifo_rd_en(i);

				-- Register and distribute the Lane 0 almost empty flag that will be used by each FIFO.
				fifo_lane0_rd_en(i) <= not fifo_almost_empty(0);

				-- FLag lane alignment errors
				lane_error(i) <= '1' when fifo_rd_en(0) and ((is_sof(0) xor is_sof(i)) or (is_eof(0) xor is_eof(i))) else
				                 '0' when fifo_rd_en(0) and is_sof(0) and is_sof(i);

                -- Manage lane state
				lane_state(i) <= READ when fifo_lane0_rd_en(i)='1' and is_eof(0)='1' else -- All lanes go to read state so they are ready for alignment test
							     FLUSH_UNTIL_EMPTY when lane_state(i)=READ and fifo_lane0_rd_en(i)='1' and is_sof(0) /= is_sof(i)  else -- Start flushing if a lane does not start when lane 0 starts
				                 FLUSH_UNTIL_EOF when lane_state(i)=FLUSH_UNTIL_EMPTY and fifo_almost_empty(i)='1' else -- Wait until an EOF is found and flushed
				                 HOLD when lane_state(i)=FLUSH_UNTIL_EOF and is_eof(i)='1'; -- hold the following SOF

				-- Register the FIFO output data
				m_axis_tdata(i) <= fifo_tdata(i);
			end loop;
			m_axis_tvalid <= fifo_tvalid(0) and fifo_lane0_rd_en(0); -- A transfer occurs only when all the data lines are valid.  all_valid is 1 when no lane is valid, but the second term implies that at least one lane (the current lane) is valid.
			m_axis_tlast <= fifo_tlast(0); -- Set the last flag from the FIFO if the lane is still being sent. If it was interrupted early and data is being discarded, EOF will not appear with global_tlast.

			-- Synchronous resets
			if rst  then
				fifo_tfirst <= (others => '1');
				lane_error <= (others => '0');
                lane_state <= (others => READ);
				m_axis_tvalid <= '0';
			end if; -- rst

		end if; -- clk
	end process;

	-- This block implement logic to monitor the packet aligner internal states.
	-- ``mon_lane`` and ``mon_source`` selects which lane and which signal are being monitored on the ``mon_word`` bus.
	-- Stats/counter/sticky bits are reset when ``mon_reset`` is high.
	--
	mon_gen: if ENABLE_MONITORING_LOGIC generate

        -- Monitoring signals
        signal missing_frame: std_logic_vector(0 to NUMBER_OF_LANES - 1);
        signal bad_frame_length: std_logic_vector(0 to NUMBER_OF_LANES - 1);
        signal fifo_tfirst_mon: std_logic_vector(0 to NUMBER_OF_LANES - 1);
        signal fifo_underflow: std_logic_vector(0 to NUMBER_OF_LANES - 1);
        signal fifo_overflow: std_logic_vector(0 to NUMBER_OF_LANES - 1);
    
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
		signal lane_error_sticky: std_logic_vector(0 to NUMBER_OF_LANES - 1);
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

                    -- Flags for monitoring only
                    fifo_underflow(i) <= fifo_rd_en(i) and not fifo_tvalid(i);
                    fifo_overflow(i) <= fifo_almost_full(i);
                    bad_frame_length(i) <=  (is_eof(i) and fifo_rd_en(i)) and not (is_eof(0) and fifo_rd_en(0));
                    missing_frame(i) <=  is_sof(0) and fifo_rd_en(0) and not is_sof(i);
    

				end loop;

				clk_ctr <= (others => '0') when mon_reset_all or (s_axis_tvalid(0) and s_axis_tfirst(0)) else clk_ctr + 1 when not all_ones(clk_ctr);
				lane_delay <= (others => '0') when mon_reset_all else clk_ctr when (s_axis_tvalid(lane) and s_axis_tfirst(lane));

				fifo_overflow_sticky <= (others => '0') when mon_reset_all else (fifo_overflow_sticky or fifo_overflow);
				fifo_underflow_sticky <= (others => '0') when mon_reset_all else (fifo_underflow_sticky or fifo_underflow);
				missing_frame_sticky <= (others => '0') when mon_reset_all else (missing_frame_sticky or missing_frame);

				bad_frame_length_sticky <= (others => '0') when mon_reset_all = '1' else (bad_frame_length_sticky or bad_frame_length);
				lane_error_sticky <= (others => '0') when mon_reset_all else lane_error_sticky or lane_error;

				case to_integer(unsigned(mon_source)) is

					when 0 => -- Overall error flags (all lanes). Use to assess aligner global state in a single read.
						mon_word_int <=
						(
						 8      => or fifo_overflow_sticky,
						 9      => or fifo_underflow_sticky,
						 10      => or missing_frame_sticky,
						 11      => or bad_frame_length_sticky,
						 12      => or lane_error_sticky,
						 others => '0'
						);

					when 1 => -- flags (sticky or not)
						mon_word_int <=
						(
						 0      => fifo_overflow(lane),
						 1      => fifo_underflow(lane),
						 3      => missing_frame(lane),
						 4      => bad_frame_length(lane),
						 5      => lane_error(lane),

						 8      => fifo_overflow_sticky(lane),
						 9      => fifo_underflow_sticky(lane),
						 10      => missing_frame_sticky(lane),
						 11      => bad_frame_length_sticky(lane),
						 12      => lane_error_sticky(lane),
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
						mon_word_int <= (others => '0') when mon_reset_all else mon_word_int + 1 when lane_error(lane);

					when 9 => -- clock counter since lane 0 tfirst
						mon_word_int <= clk_ctr;

					when others =>
						mon_word_int <= (others => '0');

				end case;
			end if; -- clk
		end process;

	end generate mon_gen;

end architecture impl;
