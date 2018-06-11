----------------------------------------------------------------------------------
-- @file
-- Company: McGill University
-- Engineer: J.-F. Cliche
--
-- Create Date:    2013-11-24
-- Design Name: chFPGA
-- Module Name:    ALIGN
-- Project Name: CHIME
-- Target Devices: K7
-- Tool versions: Vivado 2013.3
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_misc.ALL; -- for and_reduce

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;
use work.chFPGA_Package.all; -- Get all component definitions
use work.ip_package.all; -- Import definition of components used in this module

------- ALIGN ENTITY DECLARATION ----------------------
--! @brief Aligns data streams from multiple sources (lanes).
--! Frames that do not start within a programmable window of time relative to a reference frame clock are discarded.
--! This window represents the worst case delay we can expect between lanes.
--! If one or more lanes are not sending data, the module will give up waiting for them at the end of the window and the available frames will be sent at the end on the window
--!
--! The input is a non-blocking AXI4 Streaming bus. All buses must be clocked on a single clock.
--!
--! See the architecture description for more information on how the entity's functionality was implemented.
entity ALIGN is
	GENERIC (
		NUMBER_OF_LANES: INTEGER:=16 --! Number of buses to align
		);
	PORT (
		-- Input interface (non-blocking, i.e. always accepts data)
		s_axis_tvalid: in slv(0 to NUMBER_OF_LANES-1);
		s_axis_tdata: in slv32_array(0 to NUMBER_OF_LANES-1);
		s_axis_tlast: in slv(0 to NUMBER_OF_LANES-1);
		s_axis_tuser: in slv4_array(0 to NUMBER_OF_LANES-1) := (others=> (others=>'0'));
		-- s_axis_tready: out std_logic_vector(0 to NUMBER_OF_LANES-1);

		-- Output interface (non-blocking, i.e. always sends data)
		m_axis_tvalid: out slv(0 to NUMBER_OF_LANES-1);
		m_axis_tdata: out slv32_array(0 to NUMBER_OF_LANES-1);
		m_axis_tlast: out slv(0 to NUMBER_OF_LANES-1);
		m_axis_tuser: out slv4_array(0 to NUMBER_OF_LANES-1);

		m_axis_global_tvalid: out std_logic; --! Active high when data is present on the longest frame. Check the individual lane's tvalid to see if a lane ended up prematurely.
		m_axis_global_tlast: out std_logic; --! Active high on the last word of the longest frame.

		-- Operational parameters
		use_timeout: in std_logic;
		timeout_period: in std_logic_vector(7 downto 0):=(others=>'0'); --!
		sof_window_stop: in std_logic_vector(7 downto 0); --!

		-- Monitoring signals

		fifo_overflow: out slv(0 to NUMBER_OF_LANES-1);
		missing_frame: out slv(0 to NUMBER_OF_LANES-1);
		bad_frame_length: out slv(0 to NUMBER_OF_LANES-1);
		timeout: out slv(0 to NUMBER_OF_LANES-1);

		lane_monitor_source: in std_logic_vector(3 downto 0);
		lane_monitor: out slv(0 to NUMBER_OF_LANES-1);

		lane0_tfirst_mon: out std_logic;
		fifo_tfirst_mon: out std_logic_vector(0 to NUMBER_OF_LANES-1);
		fifo_count_mon: out slv10_array(0 to NUMBER_OF_LANES-1);


		-- frame_clk : in std_logic := '0'; --! Not used. Frame clock used if frame_clk_sel='1'. The SOF window is computed from the rising edge of this signal.
		-- frame_clk_sel: in std_logic := '0'; --! Not used. 0=use incoming lane0; 1: use external frame_clk

		-- ignore_lane: in std_logic_vector(0 to NUMBER_OF_LANES-1) := (others=>'0');
		-- had_timeout: out std_logic;

		clk: in std_logic;
		rst : in STD_LOGIC --! Synchronous  reset synchronized to CLK
 	);


end ALIGN;

--- ARCHITECTURE DECLARATION and DEFINITION ---------------------
--! This is a pipelined implementation of the aligner that reduces the logic depth to a level
--! where the logic delays are comparable to the FIFO internal delays and can
--! easily meet timing at 322 MHz in a compact placement. However, this
--! introduces a 2-clock dead time between the time the a SOF (start of frame)
--! is detected valid and the time readout begins. This means that the input
--! must have 2 idle cycles (no valid data) on average per frame. Fortunately,
--! these are naturally introduced by clock domain crossing (from 200 MHz to
--! 244 MHz for the channelizer outputs) or by the framing protocol (gigabit
--! shuffle links).
--!
--! The 'valid_lane' vector indicates if the data for the corresponding lane
--! is to be send to the output ('1') or if it is to be discarded ('0').
--!
--! When valid_lane is '0', the input of the FIFO is read continuously in
--! order to flush the data,  but will not read out a SOF if it appears during
--! the SOF window. Since the read clock is faster then the write clock, the
--! FIFO will eventuelly be emptied of any packet that do not start in a valid
--! window.
--!
--! When 'valid_lane' is '1', the FIFO output will be read out only if all
--! currently valid lanes have data (tvalid=1). In that case, the data is
--! passed on to the output.
--!
--! 'valid_lane' is set on the last clock of the SOF window. By that time, any
--! frame that started within the SOF window will have a SOF word waiting at
--! the FIFO's output. 'valid_lane' is set to '1' for any lane where the FIFO
--! offers an SOF, and '0' for the others.
--!
--! When an EOF is read out of a FIFO, its 'valid_lane' is set to 0 to
--! indicate that we should not wait for data on that lane anymore. This is
--! needed in the case where a lane is shorter than the other ones so we don't
--! fill up the FIFO while waiting for data that is not coming.
--!
--! 'valid_lane' is also set to '0' when EOF is read out of the reference
--! lane. Normally all lanes read out their EOF at the same time. However, this will
--! flush a lane that is too long relative to the reference lane.

architecture Behavioral of ALIGN is

--- Signal definitions ------------------------------------


signal s_axis_tfirst: slv(0 to NUMBER_OF_LANES-1);

signal is_sof: slv(0 to NUMBER_OF_LANES-1);
signal is_eof: slv(0 to NUMBER_OF_LANES-1);

-- signal send: slv(0 to NUMBER_OF_LANES-1);
signal bad_frame_length_int: slv(0 to NUMBER_OF_LANES-1);
-- signal ignore: slv(0 to NUMBER_OF_LANES-1);
signal read_en: slv(0 to NUMBER_OF_LANES-1);

signal valid_lane: slv(0 to NUMBER_OF_LANES-1);


signal sof_window_ctr: unsigned(7 downto 0) := (others=>'0'); -- init for sim
signal sof_window: std_logic;
signal is_last_in_sof_window: std_logic;
-- signal eof_window_stop: std_logic_vector(7 downto 0);
-- signal eof_window_ctr: unsigned(7 downto 0) := (others=>'0'); -- init for sim
-- signal eof_window: std_logic;

-- signal data_timeout_ctr: unsigned(width(DATA_TIMEOUT+1)-1 downto 0);
signal data_timeout_ctr: unsigned(7 downto 0);
signal timeout_int: slv(0 to NUMBER_OF_LANES-1);
signal lane0_tfirst: std_logic;

signal data_fifo_din:      slv36_array(0 to NUMBER_OF_LANES-1);
signal data_fifo_dout:     slv36_array(0 to NUMBER_OF_LANES-1);
signal data_fifo_wr_en:    slv(0 to NUMBER_OF_LANES-1);
-- signal data_fifo_rd_en:    slv(0 to NUMBER_OF_LANES-1);
signal data_fifo_empty:    slv(0 to NUMBER_OF_LANES-1);
signal data_fifo_almost_full: slv(0 to NUMBER_OF_LANES-1);
signal data_fifo_valid:    slv(0 to NUMBER_OF_LANES-1);
signal data_fifo_overflow: slv(0 to NUMBER_OF_LANES-1);
signal data_fifo_count:    slv10_array(0 to NUMBER_OF_LANES-1);

signal fifo_tdata:      slv32_array(0 to NUMBER_OF_LANES-1);
signal fifo_tuser:      slv4_array(0 to NUMBER_OF_LANES-1);
signal fifo_tvalid:     slv(0 to NUMBER_OF_LANES-1);
signal fifo_tlast:      slv(0 to NUMBER_OF_LANES-1);
signal fifo_tfirst:     slv(0 to NUMBER_OF_LANES-1);
signal fifo_empty:      slv(0 to NUMBER_OF_LANES-1);

signal all_valid: std_logic;
signal any_valid: std_logic;
-- signal ban_lane: slv(0 to NUMBER_OF_LANES-1);
signal align_pulse: slv(0 to NUMBER_OF_LANES-1);

signal m_axis_global_tvalid_int: std_logic; --! Active high when data is present on the longest frame. Check the individual lane's tvalid to see if a lane ended up prematurely.
signal m_axis_global_tlast_int: std_logic; --! Active high on the last word of the longest frame.

begin

m_axis_global_tvalid <= m_axis_global_tvalid_int;
m_axis_global_tlast <= m_axis_global_tlast_int;
-------------------------------------------------
-- ALIGN FIFOs
-------------------------------------------------
--! Buffer the incoming non-blocking streams so we can hold the data until all lanes are aligned.
--! The FIFOs are FWFT, and their outputs must be registered to make sure they are not the critical path in the timing.
--! The embedded registers are used for this at no cost.
--! The FIFO is 512-deep to accomodate misalignments up to a full frame, although we are limited by the SOF window range (256 plus a few samples)
fifogen: for i in 0 to NUMBER_OF_LANES-1 generate

	data_fifo_din(i)(35 downto 33) <= s_axis_tuser(i)(3 downto 1);
	data_fifo_din(i)(32) <= s_axis_tlast(i);
	data_fifo_din(i)(31 downto 0) <= s_axis_tdata(i);
	data_fifo_wr_en(i) <= s_axis_tvalid(i) and ((not data_fifo_almost_full(i)) or s_axis_tlast(i));

	fifo0: entity work.shuffle_crossbar_align_fifo
		PORT MAP (
			din          => data_fifo_din(i),
			wr_en        => data_fifo_wr_en(i),
			full         => open,
			almost_full  => data_fifo_almost_full(i),
			overflow     => data_fifo_overflow(i),

			dout         => data_fifo_dout(i),
			valid        => data_fifo_valid(i),
			rd_en        => read_en(i),
			empty        => open,
			almost_empty => data_fifo_empty(i),
			data_count   => data_fifo_count(i),
			clk          => clk,
			srst         => rst
		);

		fifo_tuser(i)(3 downto 1) <= data_fifo_dout(i)(35 downto 33);
		fifo_tdata(i)             <= data_fifo_dout(i)(31 downto 0);
		fifo_tlast(i)             <= data_fifo_dout(i)(32);
		fifo_tvalid(i)            <= data_fifo_valid(i);
		fifo_empty(i)             <= data_fifo_empty(i);
		-- data_fifo_rd_en(i)        <= read_en(i);

		-- read_en(i) <= bad_frame_length_int(i) or (valid_lane(i) and all_valid and any_valid);
		-- read_en(i) <= (not valid_lane(i) and not (is_sof(i) and sof_window)) or (valid_lane(i) and all_valid and any_valid);

		-- Read the FIFO if 1) the lane is valid and all lanes that are valid have valid data; or 2) read (flush) the data if the lane is not valid except if we have an SOF within the SOF window.
		read_en(i) <=  all_valid  when valid_lane(i)='1' else not (is_sof(i) and sof_window); -- Note: all_valid='1' when all valid_lane=0, but this is excluded because all_valid is used only if one lane (the current lane) is valid.

end generate;

-- all_valid <= and_reduce(not valid_lane or (valid_lane and fifo_tvalid)) and or_reduce(valid_lane); -- All that lanes that should be sent are valid. Is True when no lane are tagged as valid (i.e when holding data until SOF)

all_valid <= and_reduce(not valid_lane or (valid_lane and fifo_tvalid)); -- All that lanes that should be sent are valid. Is True when no lane are tagged as valid (i.e when holding data until SOF)

-- useful flags
is_sof          <= fifo_tvalid and fifo_tfirst;
is_eof          <= fifo_tvalid and fifo_tlast;

--! 1) wait for any SOF and start is_last_in_sof_window counter
--! 2) if all SOF present, start sending all data
--! 3) if is_last_in_sof_window, send available data only.
--! on EOF, truncate any lane and bad_frame_length_int the rest

--! All frames are aligned within a given time window starting when a start of frame is detected on any lane.
--! If a frame is not present within that window, the available frames are sent.
--! When a frame ends one one lane, the frames from all other lanes are truncated and the remaining data is discarded.

--! All frames are aligned and are of the same length (tlast=1 occur at the same time), but some lanes might be missing (tvalid=0)

fifo_overflow <= data_fifo_overflow;
bad_frame_length <= bad_frame_length_int;
lane0_tfirst_mon <= lane0_tfirst;
fifo_tfirst_mon <= fifo_tfirst;
fifo_count_mon <= data_fifo_count;
timeout <= timeout_int;

out_proc: process(clk)
	-- variable start_send_var: std_logic;
	-- variable valid_lane_var: slv(0 to NUMBER_OF_LANES-1);

	begin
		if rising_edge(clk) then

			for i in 0 to NUMBER_OF_LANES-1 loop
				if rst='1' then
					s_axis_tfirst(i) <= '1';
				elsif s_axis_tvalid(i)='1' then
					s_axis_tfirst(i) <= s_axis_tlast(i);
				end if;

				if s_axis_tvalid(0)='1' and s_axis_tfirst(0)='1' then
					align_pulse(i) <= '1';
				elsif s_axis_tvalid(i)='1' and s_axis_tfirst(i)='1' then
					align_pulse(i) <= '0';
				end if;
			end loop;


			case to_integer(unsigned(lane_monitor_source)) is
				when 0 =>
					lane_monitor <= (
						0 => is_last_in_sof_window,
						1 => all_valid,
						2 => sof_window,
						-- 3 => lane0_tfirst and s_axis_tvalid(0) ,
						-- 4 => any_valid,
						-- 5 => is_last_in_sof_window and not is_sof(0),
						-- 6 => m_axis_global_tvalid_int,
						-- 7 => m_axis_global_tlast_int,
						others => '0');
				when 1 =>
					lane_monitor <= is_sof;
				when 2 =>
					lane_monitor <= is_eof;
				when 3 =>
					lane_monitor <= valid_lane;
				when 4 =>
					lane_monitor <= read_en;
				when 5 =>
					lane_monitor <= bad_frame_length_int;
				when 6 =>
					lane_monitor <= fifo_tvalid;
				when 7 =>
					lane_monitor <= fifo_tlast;
				when 8 =>
					lane_monitor <= fifo_empty;
				when 9 =>
					lane_monitor <= fifo_tfirst;
				when 10 =>
					lane_monitor <= s_axis_tvalid;
				when 11 =>
					lane_monitor <= s_axis_tlast;
				-- when 12 =>
				-- 	lane_monitor <= ban_lane;
				when 13 =>
					lane_monitor <= data_fifo_overflow;
				when 14 =>
					lane_monitor <= align_pulse;
				when others =>
					lane_monitor <= (others => '0');
			end case;


			-- eof_window_stop <= std_logic_vector(unsigned(sof_window_stop) + 8);

			--! Detect SOF on the incoming (unbufferred) lane 0 to derive a frame clock used as a timing reference.
			if s_axis_tvalid(0)='1' then
				lane0_tfirst <= s_axis_tlast(0);
			end if;

			-- Identify the first word of each frame.
			-- tfirst is set whenever the _last word of a frame is read out (tvalid=1 and tready=1) and stays there until the first word is read out itself.
			for i in 0 to NUMBER_OF_LANES-1 loop
				if fifo_tvalid(i)='1' and read_en(i) = '1' then
					fifo_tfirst(i) <= fifo_tlast(i);
				end if;
			end loop;


			-- SOF window generator
			-- Pulse ``is_last_in_sof_window`` for one clock ``is_last_in_sof_window`` after the beginning of a frame on lane 0.
			is_last_in_sof_window <='0'; -- flag lasts only one clock
			if lane0_tfirst='1' and s_axis_tvalid(0)='1' then
				sof_window_ctr <= (others=>'0');
				sof_window <= '1';
			elsif sof_window='1' then
				sof_window_ctr <= sof_window_ctr + 1; -- overriden below
			 	if sof_window_ctr = unsigned(sof_window_stop) then
					is_last_in_sof_window <='1'; -- indicate that a SOF timeout condition has occured
				end if;
			end if;
			if is_last_in_sof_window='1' then
				sof_window <= '0';
			end if;

			-- -- EOF window
			-- if s_axis_tvalid(0)='1' and s_axis_tlast(0)='1' then
			-- 	eof_window_ctr <= (others=>'0');
			-- 	eof_window <= '1';
			-- elsif eof_window='1' then
			-- -- elsif is_last_in_sof_window='1' then
			-- 	eof_window_ctr <= eof_window_ctr + 1; -- overriden below
			--  	if eof_window_ctr = unsigned(eof_window_stop) then
			-- 		eof_window <= '0';
			-- 	end if;
			-- end if;
			timeout_int <= (others=> '0');
			if all_valid='1' or use_timeout='0' then -- if all valid lanes have data or if no lanes are selected, clear the timeout counter
				data_timeout_ctr <= (others=>'0');
			elsif data_timeout_ctr = unsigned(timeout_period) then
				timeout_int <= valid_lane and not fifo_tvalid;
				-- had_timeout <= '1'; -- sticky timeout
			else
				data_timeout_ctr <= data_timeout_ctr + 1;
			end if;

			-- if data_timeout_ctr = unsigned(timeout_period) then
			-- end if;

			-- any_valid <= or_reduce(valid_lane_var);
			-- all_valid <= and_reduce(not valid_lane or (valid_lane and fifo_tvalid)) and or_reduce(valid_lane); -- All that lanes that should be sent are valid. Is True when no lane are tagged as valid (i.e when holding data until SOF)

			for i in 0 to NUMBER_OF_LANES-1 loop

				-- valid_lane_var(i) := valid_lane(i);

				--If a lane was expected to send data but no data was received
				--for a number of clocks, ban the lane and start discarding
				--its data.
				-- JFC: disabled for debugging. Not really used anyway
				-- if data_timeout_ctr = unsigned(timeout_period) and data_timeout_ctr /= 0 and fifo_tvalid(i)='0' and valid_lane(i)='1' then
				-- 	valid_lane_var(i) := '0';
				-- 	bad_frame_length_int(i) <= '1';
				-- 	ban_lane(i) <= '1';
				-- end if;

				if timeout_int(i)='1' then
					valid_lane(i) <= '0';
				end if;

				-- If the frame ends, stop sending data
				-- from that lane so the next SOF will be kept waiting in the
				-- FIFO for the next frame. However, if the frame ends too early (before the
				-- pre-FIFO reference lane ends, which should not happen) we probably have a bad lane and dont
				-- want the data to fill up the FIFO, so we discarding its
				-- data.
				bad_frame_length_int(i) <= '0';
				if (is_eof(i)='1' and read_en(i)='1') or (is_eof(0)='1' and read_en(0)='1') then --
					valid_lane(i) <= '0';
					-- bad_frame_length_int(i) <= '0'; -- debug: simplifying
					-- bad_frame_length_int(i) <= not eof_window; -- debug
					bad_frame_length_int(i) <= not is_eof(i) or not is_eof(0); -- Misaligned EOF / bad frame length
				end if;

				-- If we are pulling out the EOF from the reference lane FIFO and
				-- the current lane is not EOF, we have an over-long frame.
				-- We stop considering this lane as having valid data and
				-- start discarting its data.
				-- JFC Fix: if the lane is discarding, its EOF is lost and it gets discarded again forever... So bad_frame_length_int on EOF only if lane was supposed to be valid.
				-- if is_eof(0)='1' and read_en(0)='1' and valid_lane(i)='1' then --
				-- 	valid_lane(i) <= '0';
				-- 	bad_frame_length_int(i) <= not is_eof(i);
				-- end if;

				-- Start sending all lanes that have a SOF flag at the end of
				-- the SOF window, and bad_frame_length_int the rest. Banned lanes will
				-- always be discarded. The ban can be lifted if
				-- auto_unban='1' and the lane 0 FIFO is less than 25% full.
				missing_frame(i) <= '0';
				if is_last_in_sof_window='1' then
					-- start_send_var := is_sof(i) and not bad_frame_length_int(i) and not (ignore_lane(i) or ban_lane(i));
					-- start_send_var := is_sof(i);
					valid_lane(i) <= is_sof(i);
					-- bad_frame_length_int(i) <= not is_sof(i);
					missing_frame(i) <= not is_sof(i);
					-- if msb(data_fifo_count(0), 4)="0000" and auto_unban='1' then
					-- 	ban_lane(i) <= '0';
					-- end if;
				end if;

				-- valid_lane(i) <= valid_lane_var(i);

			end loop;



			for i in 0 to NUMBER_OF_LANES-1 loop
				m_axis_tvalid(i) <= all_valid and valid_lane(i); -- A transfer occurs only when all the data lines are valid.  all_valid is 1 when no lane is valid, but the second term implies that at least one lane (the current lane) is valid.
				m_axis_tdata(i) <= fifo_tdata(i);
				m_axis_tlast(i) <= fifo_tlast(i) and valid_lane(i); -- Set the last flag from te FIFO if the lane is still being sent. If it was interrupted early and data is being discarder, EOF will not appear wit global_tlast.
				m_axis_tuser(i)(3 downto 1) <= fifo_tuser(i)(3 downto 1);
				m_axis_tuser(i)(0) <= '0';
			end loop;

			m_axis_global_tvalid_int <= all_valid and valid_lane(0); -- There is valid data if any lane that should be sending data has valid data
			m_axis_global_tlast_int <= fifo_tlast(0);

			-- Synchronous reset
			-- The reset code is placed at the end to avoid the non-resetted signals to hold their value during reset (which requires additional logic).
			if rst='1' then
				data_timeout_ctr <= (others=>'0');
				sof_window <= '0';
				-- eof_window <= '0';
				is_last_in_sof_window <= '0';
				fifo_tfirst <= (others=>'1');
				lane0_tfirst <= '1'; -- Make sure we trig on the first incoming packet after reset. Otherwise we will buffer a full frame before sending data.
				-- send <= (others=>'0');
				bad_frame_length_int <= (others=>'0');
				missing_frame <= (others=>'0');
				-- ignore <= (others=>'0');
				valid_lane <= (others=>'0');
				-- ban_lane <= (others=>'0');
				m_axis_tvalid <= (others=>'0');
				-- had_timeout <= '0';
			end if; -- rst


		end if; -- clk
	end process;




end Behavioral;
