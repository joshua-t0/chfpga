----------------------------------------------------------------------------------
-- Company: McGill University
-- Engineer: J.-F. Cliche
--
-- Create Date: 03/24/2023 01:33:49 PM
-- Design Name: UCAP
-- Module Name: ucap - implementation
-- Project Name: CHORD
-- Target Devices: Xilinx Ultrascale+
-- Language: VHDL2008
-- Tool Versions: Vivado 2022.2+
-- Description: UltraRAM-based programmable multirate, 8x dual-input channels, 128-bit AXI4-Streaming packet capture and 8-bit AXI4-Streaming serial streamer
--
-- Dependencies: requires UltraRAM
--
-- Revision control: See git repo
-- Documentation: Implementation docs usually found in the source code below. Detailed documentation found in <repo_folder>/docs.
--
----------------------------------------------------------------------------------


-- Standard libraries
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.vcomponents.all;

library xpm;
use xpm.vcomponents.all;

-- Project libraries
use work.chFPGA_Package.all; -- Get all component definitions

-- ucap: UltraRAM-based raw data capture engine
--
-- `ucap` allows the capture of raw ADC data frames, where a frame is 16384 x 16-bit samples provided 8 sample at a time.
-- `ucap` can store 2 frames for all 8 channels, 4 frames for 4 selected channels, 8 frames for 2 selected channels, or 16 frames for 1 selected channel.
-- Frames are captured Every N frames.
entity ucap is
	generic (
		FPGA_SERIES: integer; -- Used to select the appropriate FIFO memory type
	    NUMBER_OF_CHANNELS: integer := 8; -- Warning: current design works only with NUMBER_OF_CHANNELS = 8
	    NUMBER_OF_SOURCES : integer := 2; -- Warning; current design works only with NUMBER_OF_SOURCES = 2
        CAPTURE_BITS_PER_WORD: integer := 128 -- must be a multiple of 8 bits
	);
    port (
        -- Input data buses, synchronous to s_axis_clk

        s_axis_tdata: in slv_array(0 to NUMBER_OF_CHANNELS-1)(CAPTURE_BITS_PER_WORD -1 downto 0);
        s_axis_tvalid: in std_logic_vector(0 to NUMBER_OF_SOURCES - 1); -- common to all channels
        s_axis_tlast: in std_logic_vector(0 to NUMBER_OF_SOURCES - 1); -- common to all channels

        -- Remote mux control

        source_sel_out: out std_logic_vector(0 to NUMBER_OF_CHANNELS - 1); -- data source request for each channel
        source_sel_in: in std_logic_vector(0 to NUMBER_OF_CHANNELS - 1); -- curent data source on tdata for each channel


        s_axis_clk: in std_logic;
        rst: in std_logic; -- synchronous to s_axis_clk

        -- Output data bus, synchronous to m_axis_clk

        m_axis_tdata: out std_logic_vector(7 downto 0); -- 8-bit output bus
		m_axis_tvalid: out std_logic;
		m_axis_tlast: out std_logic;
		m_axis_tready: in std_logic := '1';
        m_axis_clk: in std_logic;

		-- BSB Control interface
		s_axis_bsb_tdata: in std_logic_vector(7 downto 0) := (others => '0');
		s_axis_bsb_tvalid: in std_logic := '0';
		s_axis_bsb_tlast: in std_logic := '0';
		s_axis_bsb_tready: out std_logic;
		m_axis_bsb_tdata: out std_logic_vector(7 downto 0);
		m_axis_bsb_tvalid: out std_logic;
		m_axis_bsb_tlast: out std_logic;
		m_axis_bsb_tready: in std_logic := '0';
		bsb_clk: in std_logic := '0'; -- control clock
		bsb_rst: in std_logic := '0'
    );
end ucap;

architecture impl of ucap is

    constant NUMBER_OF_BUFFERS: integer := NUMBER_OF_CHANNELS;
    constant NUMBER_OF_CHANNEL_PAIRS: integer := NUMBER_OF_CHANNELS/2;
    constant RAM_LATENCY: integer := 4; -- read latency of the buffers. Used to configure the buffer and align the ram reads

    subtype int8 is integer range 0 to NUMBER_OF_CHANNELS-1; -- used for channel and buffer indexing


	signal control_bytes: slv8_array(0 to 10);
	signal status_bytes: slv8_array(0 to 3);

	signal in_frame_ctr: unsigned(7 downto 0);
	signal out_frame_ctr: unsigned(7 downto 0);

    -- control and status signals
    signal mode: std_logic_vector(1 downto 0) := "11"; -- "00": 8-channel, "01": 4-channel, "10": 2-channel, "11": 1-channel
    signal chan_sel_map : u3_array(0 to NUMBER_OF_CHANNEL_PAIRS-1);
    -- data rate ratio: 3000 Gsps * 2 bytes/sample * 2 frames/capture * 8 channel / 100 Mbyte readout = 960.
	signal base_period: u24_array(0 to NUMBER_OF_SOURCES-1); -- 2 frames * 16 bytes, 3000e6/16384 = 183105.46875 =1s, max period = 91.6s
    signal sub_period: unsigned(4 downto 0);
	signal user_reset, user_reset_reg: std_logic;
	signal overrun: std_logic;
    signal user_stream_id: std_logic_vector(7 downto 0);
    -- Signals used for both write and read processes
    signal chan_pair_sel: u3_array(0 to NUMBER_OF_CHANNEL_PAIRS-1);
	signal capture_timestamp: u48_array(0 to NUMBER_OF_SOURCES-1);
    signal ram_readout_trig: std_logic_vector(0 to NUMBER_OF_BUFFERS-1);
    signal ram_readout_trig_ack: std_logic_vector(0 to NUMBER_OF_BUFFERS-1); -- pulses to '1' when a ram buffer processing is finished
    signal ram_readout_src: std_logic_vector(0 to NUMBER_OF_BUFFERS-1);

    -- RAM signals
	signal ram_wr_addr, ram_rd_addr: slv12_array(0 to NUMBER_OF_BUFFERS-1);
	signal ram_din: slv_array(0 to NUMBER_OF_BUFFERS-1)(CAPTURE_BITS_PER_WORD -1 downto 0);
	signal ram_dout: slv_array(0 to NUMBER_OF_BUFFERS-1)(CAPTURE_BITS_PER_WORD -1 downto 0); -- one for each column;
	signal ram_wr_en: std_logic_vector(0 to NUMBER_OF_BUFFERS-1);  -- one for each row
	signal ram_rd_en: std_logic_vector(0 to NUMBER_OF_BUFFERS-1);  -- one for each column

    -- FIFO signals
	signal fifo_in_tdata: std_logic_vector(7 downto 0);
	signal fifo_in_tvalid: std_logic;
	signal fifo_in_tlast: std_logic;
	signal fifo_full: std_logic;
	signal fifo_overflow: std_logic;
	signal fifo_overflow_sticky: std_logic;
	signal fifo_wr_rst_busy: std_logic;
	signal fifo_rd_rst_busy: std_logic;
	signal m_clk_ctr: unsigned(7 downto 0);
begin


-- --------------------------------------------
-- UCAP Memory Map
--
--
-- ------------------------------------------------------------------------------
-- |  Page   | Addr|Bit(s)|     Name             | Description                   |
-- |---------|-----|------|----------------------|-------------------------------|
-- | CONTROL |  0  | 7:6  | mode                 | "00": 8-channel mode, "01": 4-channel, "10": 2-channel, "11": 1-channel |
-- |         |     | 5:3  | chan_sel(1)          | Physical Channel connected to logical channel 1 (used only in 4-, 2-channel mode) |
-- |         |     | 2:0  | chan_sel(0)          | Physical Channel connected to logical channel 0 (used only in 4-, 2-, 1-channel mode) |
-- |         |  1  | 7   | user_reset           | When '1', resets the module |
-- |         |     |  6  | (unused)              | (was output_source_sel, now removed; merging handled by axis_merge) |
-- |         |     | 5:3  | chan_sel(3)          | Physical Channel connected to logical channel 3 (used only in 4-channel mode) |
-- |         |     | 2:0  | chan_sel(2)          | Physical Channel connected to logical channel 0 (used only in 4- and 2-channel mode) |
-- |         | 2-4 | 23:0 | base_period(0)       | Capture period for source 0 |
-- |         | 5-7 | 23:0 | base_period(1)       | Capture period for source 1 |
-- |         | 8   | 7:5  | (unused)       | |
-- |         |     | 4:0 | sub-period capture rate               | |
-- |         |  9  | 7:0 | source_sel           | Source selection for each physical channel (bit 0 = channel 0)|
-- | STATUS  |  0  | 7:4 | (unused)        | |
-- |         |  0  |  3  | fifo_overflow_sticky        | |
-- |         |  0  |  2  | overrun        | |
-- |         |  0  |  1  | rst        | |
-- |         |  0  |  0  | user_reset        | |
-- |         |  1  | 7:0 | period_ctr(0)    | Last 8 bits of period counter for source 0 |
-- |         |  2  | 7:0 | source_sel_in     | Source selection input (bit 0 = channel 0) |
-- ------------------------------------------------------------------------------

	bsb_regs0: entity work.bsb_regs
		GENERIC MAP (
			DEFAULT_CONTROL_BYTES=> X"08_1A_02cb41_02cb41_17_00_00",
			NUMBER_OF_CONTROL_BYTES => control_bytes'Length(1), -- Number of bits in the control word
			NUMBER_OF_STATUS_BYTES => status_bytes'Length(1) -- Number of bits in the status word.
		)
		PORT MAP(
			control_bytes => control_bytes,
			status_bytes => status_bytes,

			s_axis_bsb_tdata => s_axis_bsb_tdata,
			s_axis_bsb_tvalid => s_axis_bsb_tvalid,
			s_axis_bsb_tlast => s_axis_bsb_tlast,
			s_axis_bsb_tready => s_axis_bsb_tready,
			m_axis_bsb_tdata => m_axis_bsb_tdata,
			m_axis_bsb_tvalid => m_axis_bsb_tvalid,
			m_axis_bsb_tlast => m_axis_bsb_tlast,
			m_axis_bsb_tready => m_axis_bsb_tready,
			bsb_clk => bsb_clk,
			bsb_rst => bsb_rst
		);

	-- CONTROL byte 0 -1 : mode and channel selection
	mode            <= control_bytes(0)(7 downto 6); -- "00": 8-channel mode, "01": 4-channel, "10": 2-channel, "11": 1-channel
	chan_sel_map(1) <= unsigned(control_bytes(0)(5 downto 3));
	chan_sel_map(0) <= unsigned(control_bytes(0)(2 downto 0));

	user_reset      <= control_bytes(1)(7);
	chan_sel_map(3) <= unsigned(control_bytes(1)(5 downto 3));
	chan_sel_map(2) <= unsigned(control_bytes(1)(2 downto 0));

	-- CONTROL bytes 2-7: base capture period
	base_period(0) <= to_unsigned(control_bytes(2 to 4));
	base_period(1) <= to_unsigned(control_bytes(5 to 7));

	-- CONTROL bytes 8: capture subperiod
	sub_period <= unsigned(control_bytes(8)(4 downto 0));

	-- CONTROL bytes 9: source selection
	source_sel_out <= reverse_bits_and_dir(control_bytes(9)); -- bit 0 = channel 0

	-- CONTROL bytes 10: user stream ID
	user_stream_id <= control_bytes(10);

	-- STATUS byte 0
	status_bytes(0)(0) <= fifo_overflow_sticky;
	status_bytes(0)(1) <= overrun;
	status_bytes(0)(2) <= rst; --debug
	status_bytes(0)(3) <= user_reset_reg; -- debug
	status_bytes(0)(4) <= m_axis_tready;
	status_bytes(0)(5) <= fifo_full;
	status_bytes(0)(6) <= fifo_wr_rst_busy;
	status_bytes(0)(7) <= fifo_rd_rst_busy;
	status_bytes(1) <= std_logic_vector(in_frame_ctr);
	status_bytes(2) <= std_logic_vector(out_frame_ctr);
	status_bytes(3) <= std_logic_vector(m_clk_ctr);

    ------------------------------------------------------------
    -- UltraRAM data buffers
    ------------------------------------------------------------
    -- Generate 8 URAM buffers, each 16-byte wide (128 bit wide) x 4096 words
    -- We need at least 1 buffer per input channel, as we need to write all 8 channels in parallel in mode 0.
    -- Each buffer can store 2 frames. Depending on the mode, the buffers can be used to store:
    --   2 frames from 8 channels (mode "00")
    --   4 frames from 4 channels (mode "01")
    --   8 frames from 2 channels (mode "10")
    --   16 frames from 1 channel (mode "11")
    --
	uram_gen: for i in 0 to NUMBER_OF_BUFFERS-1 generate
		begin
		   	-- xpm_memory_sdpram: Simple Dual Port RAM
		   	-- Xilinx Parameterized Macro, version 2022.1
		   	-- UltraRAM primitive is organized as 4K x 72 bits.
		   	-- Each buffer is organized as 4K x 128 bits (2 URAM per buffer)
		   	-- Addr width: we use all the memory space 4K words.
		   	uram0 : xpm_memory_sdpram
			   	generic map (
			      MEMORY_PRIMITIVE => "ultra",      -- force the use of UltraRAM
                    -- write bus A
			      ADDR_WIDTH_A => 12,               -- 4k (12 bits) per URAM
			      WRITE_DATA_WIDTH_A => CAPTURE_BITS_PER_WORD,        -- 8 byte (64 bits) wide write bus
			      BYTE_WRITE_WIDTH_A => CAPTURE_BITS_PER_WORD,          -- We use 8-bit-wide-byte-enabled write, i.e. we have 8 byte enable bits
                    -- Read bus B
			      ADDR_WIDTH_B => 12,               -- same
			      READ_DATA_WIDTH_B => CAPTURE_BITS_PER_WORD,         -- 8 byte (64 bits) wide read bus
			      --CASCADE_HEIGHT => 4,             -- We castade 4 URAM
			      --MEMORY_OPTIMIZATION => "true",   -- String
			      MEMORY_SIZE => CAPTURE_BITS_PER_WORD * 4096,         -- 128-bit word * 4096 words/URAM
			      --MESSAGE_CONTROL => 0,            -- DECIMAL
			      READ_LATENCY_B => RAM_LATENCY,     -- Needs to be >= of cascade height to allow registering. Synthesis ask for more than 4 to have full pipelining (4 is partial).
			      --READ_RESET_VALUE_B => "0",       -- String
			      --RST_MODE_A => "SYNC",            -- String
			      --RST_MODE_B => "SYNC",            -- String
			      SIM_ASSERT_CHK => 1,             -- DECIMAL; 0=disable simulation messages, 1=enable simulation messages
			      --USE_EMBEDDED_CONSTRAINT => 0,    -- DECIMAL
			      --USE_MEM_INIT => 1,               -- DECIMAL
			      --USE_MEM_INIT_MMI => 0,           -- DECIMAL
			      --WAKEUP_TIME => "disable_sleep",  -- String
			      WRITE_MODE_B => "write_first",     -- URAM is either read_first or write_first
			      WRITE_PROTECT => 1               -- DECIMAL
				)
				port map (
					-- Write port
					dina => ram_din(i),
					addra => ram_wr_addr(i),
					ena => ram_wr_en(i),
					wea => "1",

					-- read port
					doutb => ram_dout(i),
					addrb => ram_rd_addr(i),
					enb => ram_rd_en(i),

					-- clock and reset
					clka => s_axis_clk,
					rstb => rst,

					-- unused signals
					sleep => '0',
					injectsbiterra => '0',
					injectdbiterra => '0',
					regceb => '1',
					clkb => '0'
			   );
	end generate uram_gen;

    -- Write block: writes data to memory
    --
    -- External interfaces:
    --  - capture_timestamp: timestamp of the first frame of the capture
    --  - src_readout_trig: single pulse indicating that the channels associated with the source can be readout
	wr_blk: block
		signal timestamp: u48_array(0 to NUMBER_OF_SOURCES-1);
		signal period_ctr: u24_array(0 to NUMBER_OF_SOURCES-1);

        signal frame_max: unsigned(3 downto 0); -- currently limited to 16. Depends on memory depth (frames/uram block) x number of channels.

  		signal frame: u4_array(0 to NUMBER_OF_SOURCES-1); -- we count up to 16 frames in 1 channel mode (2 frames/memory block * 8 memory blocks)
		signal word_ctr: u11_array(0 to NUMBER_OF_SOURCES-1); -- Counts group of 8 samples. 14-3=11 bits (16k samples / 8 = 2k clocks/frame).
  	    signal capture_en: std_logic_vector(0 to NUMBER_OF_SOURCES-1); -- '1' when tdata shall be written to RAM when tvalid=1
    	signal src_readout_trig: std_logic_vector(0 to NUMBER_OF_SOURCES-1); -- pulse indicating when a source is ready to be read
        signal mux_mode: std_logic;
	begin

	    wr_proc: process(all)
	        variable chan_int: int8; -- selected physical channel number as an integer
		    variable src: std_logic; -- channel source
		    variable src_int: integer range 0 to NUMBER_OF_SOURCES-1; -- channel source as an integer
            variable capture_trig: std_logic_vector(0 to NUMBER_OF_SOURCES-1);
            variable N: integer; -- number of captured channels in current mode
            variable K: integer; -- number of memory blocks per channel in current mode
            variable K_WIDTH: integer; -- number of bits needed to represent the memory block for each channel
            constant FRAMES_PER_BLOCK: integer := 2; -- number of frames that can be stored by each memory block. *Do not change: This parameter is implicitely hardcoded in some logic such as the memory enable and memory address.
	    begin
	        if rising_edge(s_axis_clk) then

	        	-- Register user reset
	            user_reset_reg <= user_reset;

                --------------------------------------------------------------------------------
	            -- Generate capture trigger (capture_trig(i))  for each source
                --------------------------------------------------------------------------------
	            --
	            -- These triggers are generated continuously in parallel, independent of which source is selected,
	            -- so we can keep track of the frame number even if the source is not selected.
	            --
	        	for src in 0 to NUMBER_OF_SOURCES-1 loop
		            src_readout_trig(src) <= '0'; -- single clock pulse signal, overridden below
					if s_axis_tvalid(src) then
						word_ctr(src) <= word_ctr(src) + 1;
						if s_axis_tlast(src) then
							in_frame_ctr <= in_frame_ctr + 1;
							word_ctr(src) <= (others => '0');
							frame(src) <= frame(src) + 1;
							period_ctr(src) <= period_ctr(src) + 1;
							timestamp(src) <= timestamp(src) + 1;
							if frame(src) = frame_max then
	                            frame(src) <= (others => '0');
           						src_readout_trig(src) <= capture_en(src); -- pulse the
								capture_en(src) <= '0';
							end if;
							if period_ctr(src) = base_period(src) or all_ones(period_ctr(src), to_integer(sub_period), 0) then
								capture_en(src) <= '1';
	                            frame(src) <= (others => '0');
								period_ctr(src) <= (others => '0');
								capture_timestamp(src) <= timestamp(src) + 1; -- reuse earlier timestamp+1 logic
							end if;
						end if;
					end if;


					if rst or user_reset_reg then
                        -- block-local signals
						word_ctr(src) <= (others => '0');
						capture_en(src) <= '1'; -- capture the first frame coming out of reset
						frame(src) <= (others => '0');
						period_ctr(src) <= (others => '0');
	                    timestamp(src) <= (others => '0'); -- needed for the first frame header
                        -- external signals under the control of this block
	                    src_readout_trig(src) <= '0';
	                    capture_timestamp(src) <= (others => '0'); -- needed if we reset with capture_en=1
					end if; --rst
				end loop; -- source

                -- status_bytes(1) <= std_logic_vector(period_ctr(0)(7 downto 0));
                -- status_bytes(2) <= std_logic_vector(source_sel_in);


                -- Implement input muxing
                --
                -- We need a multiplexer to select which channels are routed to each of the eight memory banks (aka data buffers).
                -- Depending on the mode, a channel can be routed to multiple memory banks in order to store more frames but from les channels.
                --
                -- The brute force approach would be to put a 8:1 in from of each of the memory
                -- bank, but that would require a lot of logic, and would be overkill as we don't
                -- need to chose the order of the
				-- channels, or select channels multiple times; we just need a few of
                -- the possible muxing combinations, which are summarized in 4 modes:
                --
                --   - mode 0 (8-channel mode): We select all input channels and ignore the selection map: Buffers 0-7 are routed to banks 0-7, in that order.
                --   - mode 1 (4-channel mode): The 4 selected channels are routed to 4 RAM bank pairs
                --   - mode 2 (2-channel mode): The 2 selected channels are routed to 2 groups of 4 RAM banks
                --   - mode 3 (1-channel mode): One selected channel is routed to all eight RAM banks
                --
	            -- In order to implement these modes, we implement four 8:1 muxes that feeds data from 2 programmable channels to a pair of data buffers.
	            -- Mode 1 is simply implemented by driving the selection signal of all 4 muxes directly from the user-settable channel selection registers.
	            -- Modes 2 and 3 are just treated as special cases of mode 1. We simply assign a subset of the user-selected channel(s) to groups of 2 or 4 muxes.
	            -- In order to support mode 0, we add a 2:1 mux on the input of the odd buffers to use their corresponding data inputs
	            -- (channel 1 to buffer 1, channel 3 to buffer 3 etc). If we enable that mux and force the 8:1 muxes to select channels 0, 2, 4 and 6, we have all we need.
				--
				-- So in summary:
	            --    - Even buffers (i = 0,2,4,6) can select any of the 8 input, as described in chan_pair_sel(i/2)
	            --    - Odd buffers (i = 1,3,5,7) can select either the corresponding input (i) (mux_mode=0) or the same data as the even buffer (mux_mode=1)
	            --
				-- This implementation uses half the resources compared to a blunt muxing of all 8
				-- buffer inputs, which is overkill. The modified 4-channel mux is still
				-- over-flexible , which suggests we might still be using more logic than necessary,
				-- but so far we have not found a way to make it smaller. This is good enough.
	            --
	            -- Some more implementation details
	            -- --------------------------------

	            -- -- The synthesizer is not smart
				-- enough to figure out how it can use a four 8:1 and four 2:1 muxes to do all we want instead of eight 8:1 muxes, so we have to spell it out by creating the proper control signals:
	            --
	            -- - ``chan_pair_sel(i)`` (where i ranges from 0 to 3) is the selector signal for each 8:1 mux. The logic sets those based on the mode and the user selected input registers.
				-- - ``mux_mode`` is high when we are *not* in mode 0
				-- - ``chan_sel_map(j)`` (j=0-3) are the user selected input registers
				--
				-- Consequently:
				--
	            --  - Mode 0: mux_mode=0. chan_pair_sel = (0, 2, 4, 6). We ignore the user selections. Even buffers will connect to channels 0, 2, 4, 6, and mux_mode=0  will enable the 2:1 muxes so odd buffers receive channels 1,3,5 and 7.
	            --  - Mode 1: mux_mode=1. chan_pair_sel= (chan_sel_map(0), chan_sel_map(1), chan_pair_sel(2), chan_sel_map(3)). Since mux_mode=1, both buffers in each pair receive the same data.
	            --  - Mode 2: mux_mode=1. chan_pair_sel= (chan_sel_map(0), chan_sel_map(0), chan_pair_sel(1), chan_sel_map(1)). Same comment on mux_mode.
	            --  - Mode 3: mux_mode=1. chan_pair_sel= (chan_sel_map(0), chan_sel_map(0), chan_pair_sel(0), chan_sel_map(0)).
				--



	            --  Prepare the input muxing variables and signals to simplify the code and logic
	            --  -----------------------------------------------------------------------------

                -- Derive the basic readout geometry parameters based on the mode
                -- N: Number of channels to capture
                -- K: Number of memory blocks per channel (2 in mode 1, 4 in mode 2, 8 in mode 3)
                -- K_WIDTH: -- Number of bits to represent the block number (1 in mode 1, 2 in mode 2, 3 in mode 3)
                case mode is
                    when "00" => N :=  8; K := 1; K_WIDTH := 0; -- capturing 8 channels
                    when "01" => N :=  4; K := 2; K_WIDTH := 1; -- capturing 4 channels
                    when "10" => N :=  2; K := 4; K_WIDTH := 2; -- capturing 2 channels
                    when "11" => N :=  1; K := 8; K_WIDTH := 3; -- capturing 1 channel
                    when others =>
--                    assert FALSE report "Unhandled mode" severity FAILURE;
                end case;

                -- Set the 2:1 mux mode. mux_mode=0 will enable the 2:1 muxes to override the odd buffer inputs
                mux_mode <= '0' when mode = "00" else '1';


                -- Set the source for each 8:1 mux
                --   mode 0: chan_pair_sel = (0, 2, 4, 6)
                --   mode 1: chan_pair_sel = (map(0), map(1), map(2), map(3)),
                --   mode 2: chan_pair_sel = (map(0), map(0), map(1), map(1)),
                --   mode 3: chan_pair_sel = (map(0), map(0), map(0), map(0))
                for i in 0 to NUMBER_OF_CHANNEL_PAIRS-1 loop -- one mux per channel pair
                    chan_pair_sel(i) <= to_unsigned(2*i/K, 3) when mode = "00" else
                                        chan_sel_map(2*i/K);
                end loop;

                -- Set the maximum frame number stored for each channel
                frame_max <= to_unsigned(FRAMES_PER_BLOCK*K-1, 4); -- mode 1: 4 frames, mode 2: 8 frames, mode 3: 16 frames

                -- Set the memory enable and address
                -- Determine when buffers will capture data based on the mode and frame number.
                -- mode 0: Each buffer capture every frame
                -- Mode 1: Even buffers capture even frames, odd buffers capture odd frames
                -- Mode 2, 3: etc.
	          	ram_wr_en <= (others => '0'); -- overridden below to select which buffer is write-enabled depending on the mode and frame number
	          	ram_readout_trig <= ram_readout_trig and not ram_readout_trig_ack; -- clear the trig signal when buffer readout is completed
                for i in 0 to NUMBER_OF_CHANNELS-1 loop -- for each selected channel
                    if i < N then
                        chan_int := i when mode = "00" else
                                    to_integer(chan_sel_map(i)) when i<4; -- integer representation of user-selected selected channel number
                        src := source_sel_in(chan_int); -- data source associated with the channel
                        src_int := to_integer(to_unsigned(src)); -- data source associated with the channel
                        -- Enable the one memory block to that will receive the data for each channel
                        -- based on the current frame number
                        ram_wr_en(K*i + to_integer(frame(src_int)(K_WIDTH downto 1))) <= s_axis_tvalid(src_int) and capture_en(src_int);
                        -- Set the write address for the memory blocks for each channel.
                        -- All blocks have the same address, but only one was enabled above.
                        -- The address depends on the word counter and the last bit of the frame counter (since there are 2 frames per memory)
                        for j in 0 to NUMBER_OF_BUFFERS-1 loop
                            if j >= K*i and j < K*(i+1) then
                                ram_wr_addr(j) <= std_logic_vector(frame(src_int)(0) & std_logic_vector(word_ctr(src_int))); -- 14-3 bits + 1 bit = 12 bits, 4k words/URAM
                                if src_readout_trig(src_int) then
                                    -- If we try to set a readout trigger that is already triggered, set the overrun flag.
                                    if ram_readout_trig(j) then
                                        overrun <= '1';
                                    end if;
                                    ram_readout_trig(j) <= '1';
                                    ram_readout_src(j) <= source_sel_in(chan_int); -- source that has filled this buffer. Used to select the correct timestamp.
                                end if; -- if src_readout_trig
                            end if; -- if j
                        end loop;
                     end if; -- if i < N
                end loop;

				if rst or user_reset_reg then
	               overrun <= '0';
	               ram_readout_trig <= (others => '0');
                end if; -- reset

                -- Implement the muxes
                -- -------------------
	            -- Implement the four 8:1 and four 2:1 muxes.
	            --
	            --   - The 8:1 muxes feed both even and odd buffers with the same data, and select their data from chan_pair_sel
	            --   - The 2:1 mux is enabled if mux_mode = '0', in which case the odd buffers
	            --     select the odd channels, while the logic forced the 8:1 mux on the even bins
	            --     to select the even channels.
	            --
	            -- The code is optimized to minimize resources. Muxing logic handles pair of buffers. We need:
	            --    even buffers: 112*4 x  8:1 muxes (8:1 muxes = 2x LUT8 + F7= 4 mux/CLB, 448 x 8:1 muxes = 112 CLBs)
	            --    odd buffers: 112*4 x  2:1 muxes (2:1 mux = 1x LUT3 = 16 mux/CLB,  448x 2:1 muxes = 28 CLBs )
	            --  We confirm this design uses 896 LUT6 + 448 LUT3, 448 F7)
	            --
   	            -- As a comparison, eight 8:1 muxes would use:
	            -- 	 - 28 CLB x 8 = 224 CLB, 8*28*8 = 1792 LUTs with 112*8 F7s
	            -- 	 - M8 + M4: 230 CLBs, 1833 LUTs
	            -- 	 - M8+M4+M2+M1: tota of 2525 LUTs

	            for i in 0 to NUMBER_OF_CHANNEL_PAIRS-1 loop
		           chan_int := to_integer(unsigned(chan_pair_sel(i)));

	               if not mux_mode then -- Assign input channel x to buffer x
	                   ram_din(2*i)(CAPTURE_BITS_PER_WORD-1 downto 0) <= s_axis_tdata(chan_int); -- When mux_mode=0, chan_pair_sel(i) is forced to 2*i. We don't assign the input directly becasue the synthesizer would infer an additional mux, which is redundant.
	                   ram_din(2*i+1)(CAPTURE_BITS_PER_WORD-1 downto 0) <= s_axis_tdata(2*i+1);
	               else -- Select the same even and odd input channel for each buffer pair
	                   ram_din(2*i)(CAPTURE_BITS_PER_WORD-1 downto 0) <= s_axis_tdata(chan_int);
	                   ram_din(2*i+1)(CAPTURE_BITS_PER_WORD-1 downto 0) <= s_axis_tdata(chan_int);
	               end if;
	            end loop;

	            end if; --s_axis_clk
	    end process;
	end block wr_blk;


	-- Read and stream out
	----------------------
	rd_blk: block
        -- read sequencer signals
		type READ_SEQ_STATE_TYPE IS (READ_SEQ_WAIT, READ_SEQ_SEND_HEADER, READ_SEQ_SEND_DATA);
		signal read_seq_state: READ_SEQ_STATE_TYPE;
		signal header_byte_ctr: integer range 0 to FRAME_HEADER_BYTE_LENGTH; -- counts header bytes in the read sequencer
        signal read_seq_byte_ctr: unsigned(15 downto 0);  -- counts frame (0-1), word and byte for the read sequencer
        --   15:15: frame number( 4 bits, 16 frames/capture,  counts both frame and channels. We always have a total of 16 frames from 1, 2,4, or 8 channels.)
        --   14:4: word number (11 bits, 16384/8=2048 words)
		--   3:0: byte number (4 bits, 8 samples/word = 16 bytes/word)
        signal ram_readout_mask: std_logic_vector(0 to NUMBER_OF_BUFFERS-1); -- bit pattern indicating the buffers being processed as a batch

        -- read processor
        type READ_PROC_OP_TYPE is (
            READ_PROC_NOP, -- "000"
            READ_PROC_UNUSED1, -- "001"
            READ_PROC_SEND_HEADER, --"010"
            READ_PROC_SEND_LAST_HEADER, --"011"
            READ_PROC_SEND_DATA, --"100"
            READ_PROC_SEND_LAST_PACKET_DATA, --"101"
            READ_PROC_UNUSED2,   --"110"
            READ_PROC_SEND_LAST_DATA); -- "111"
        type READ_PROC_OP_ARRAY is array (NATURAL RANGE <>) of READ_PROC_OP_TYPE;
                -- Processing operations
                --      DV HV L
                --      0 0 X : NOP
                --      0 1 0: Send header byte, byte +=1
                --      0 1 1: Send last header byte, byte =0
                --      1 X 0: Send data byte, byte += 1
                --      1 0 1: Send last data byte, byte=0, pkt+=1
                --      1 1 1: Send last data byte of last packet, byte=0, pkt=0
        signal read_proc_op:  READ_PROC_OP_ARRAY(RAM_LATENCY downto 0); -- delay line for the read processor operation
        signal buf_ix: u3_array(RAM_LATENCY downto 0); -- delay line for the read processor buffer index

		signal read_proc_pkt_ctr: unsigned(2 downto 0);  -- counts packets within each buffer (8 packets/ buffer)
        signal read_proc_byte_ctr: unsigned(3 downto 0); -- counts bytes in words

	begin


	    rd_proc: process(all)
		    variable frame_header: FRAME_HEADER_STRUCT;
            variable chan_int: integer range 0 to NUMBER_OF_CHANNELS-1;
            variable chan_sel_int: integer range 0 to 3;
            variable byte_int: integer range 0 to 15;
		    variable frame_header_bytes: slv8_array(0 to FRAME_HEADER_BYTE_LENGTH-1);
		    variable timestamp_incr: unsigned(3 downto 0);
            variable buf: unsigned(2 downto 0);
            variable src: std_logic; -- channel source
            variable src_int: integer range 0 to 1; -- channel source as an integer
            variable ram_readout_ack_var: std_logic_vector(0 to NUMBER_OF_BUFFERS-1);

	    begin
	        if rising_edge(s_axis_clk) then

	            -- Pipeline the read opcode and buffer index to compendate for the RAM readout latency
	            -- This needs to be placed before the RAM read sequencer, which overrides the input of the shift register

                -- a) Right-shift the read processor command in the delay line
            	read_proc_op(read_proc_op'LEFT-1 downto 0) <= read_proc_op(read_proc_op'LEFT downto 1);
                read_proc_op(read_proc_op'LEFT) <= READ_PROC_NOP; -- insert a default NOP processor command, to be overridden below when needed

                -- b) Right-shift the buffer number in the delay line
                buf_ix(buf_ix'LEFT-1 downto 0) <= buf_ix(buf_ix'LEFT downto 1);
                buf_ix(buf_ix'LEFT) <= (others => '0'); -- default value to simplify logic
                -- Find position of the first '1' bit in the buffer readout mask vector
                for i in 0 to NUMBER_OF_BUFFERS-1 loop
                    if ram_readout_mask(i) then
                        buf_ix(buf_ix'LEFT) <= to_unsigned(i,buf_ix(0)'LENGTH);
                        exit;
                    end if;
                end loop;


                -- RAM Read sequencer
                --
                -- The following state machine drives the readout process by generating the RAM read
                -- addresses and sending out signals to the next stage on what to do when the data
                -- arrives a few clocks later. It also generates the read_proc_op (read processor
                -- opcode) signal that tells the RAM data processing logic what to do with the data.
                -- That opcode signal is pipelined in order to arrive at the same time as the data.
                --
                -- We use fifo_full signal to throttle the readout machine. Since we receive it while there is data
                -- in the pipeline, we will stop writing too late. The full threshold MUST
                -- therefore be set before the FIFO is actually full (by using the almost_full
                -- signal instead) so the fifo can accomodate a few extra writes after fifo_full is
                -- raised. This greatly simplifies the logic.
		    	ram_rd_addr <= (others => std_logic_vector(read_seq_byte_ctr(15 downto 4)));
		    	ram_rd_en <= (others => '0'); -- the active read line will be overridden below
		    	ram_readout_trig_ack <= (others => '0'); -- Single pulse buffer readout completion signal. Overridden below when appropriate.
	            case read_seq_state is
	            	when READ_SEQ_WAIT =>
                        header_byte_ctr <= 0;
                        -- If any buffer is ready for transmission, grab the trigger pattern so we can process them as a batch.
	            		if any_one(ram_readout_trig and not ram_readout_trig_ack) then -- ack won't affect trig until the next clock. Anticipate the result.
                            ram_readout_mask <= ram_readout_trig;
                            read_seq_state <= READ_SEQ_SEND_HEADER;
	            		end if;
                    when READ_SEQ_SEND_HEADER => -- Instruct the readout logic to send header data
	                    if not fifo_full then
	                        read_proc_op(read_proc_op'LEFT) <= READ_PROC_SEND_HEADER;
	                        header_byte_ctr <= header_byte_ctr + 1;
	                        if header_byte_ctr = FRAME_HEADER_BYTE_LENGTH-1 then -- if this is the last header byte
	                             read_proc_op(read_proc_op'LEFT) <= READ_PROC_SEND_LAST_HEADER;
                                 header_byte_ctr <= 0; -- get ready for the next time we get here
	                             read_seq_state <= READ_SEQ_SEND_DATA; -- start sending the data
	                        end if;
	                    end if; -- if header fifo & send_delay & dest_ready
	                when READ_SEQ_SEND_DATA => -- Instruct the readout logic to send buffer data
	                    if not fifo_full then
	                        read_seq_byte_ctr <= read_seq_byte_ctr + 1;
                            read_proc_op(read_proc_op'LEFT) <= READ_PROC_SEND_DATA;
                            -- Pulse the RAM rd_en only on byte 0 to save power
                            if read_seq_byte_ctr(3 downto 0) = 0 then
                                chan_int := to_integer(buf_ix(buf_ix'LEFT)); -- is stable by the time we get to this state
                		    	ram_rd_en(chan_int) <= '1'; -- read only when ready to save power
                            end if;


                            if all_ones(read_seq_byte_ctr(12 downto 0)) then -- every 512 words x 16 bytes = 8K
                                read_seq_state <= READ_SEQ_SEND_HEADER;
                                read_proc_op(read_proc_op'LEFT) <= READ_PROC_SEND_LAST_PACKET_DATA;
                            end if;

                            if all_ones(read_seq_byte_ctr) then -- if all bytes in the buffer has been sent
                                read_proc_op(read_proc_op'LEFT) <= READ_PROC_SEND_LAST_DATA;
                                read_seq_byte_ctr <= (others => '0');
                                -- Clear the mask bit for the current buffer so we will continue processing the next buffer.
                                -- The new buffer index will be put on the delay pipeline 2 clocks later, but we don't need it
                                -- immediately since we are first sending the header for a few clocks.
                                ram_readout_ack_var :=  (others => '0');
                                ram_readout_ack_var(to_integer(buf_ix(buf_ix'LEFT))) := '1'; -- current buffer bit
                                ram_readout_mask <= ram_readout_mask and not ram_readout_ack_var; -- clear the current buffer bit in the mask register.
                                ram_readout_trig_ack <= ram_readout_ack_var; -- signal the write process we have finished with this buffer
                                if ram_readout_mask = ram_readout_ack_var then -- if this was the last buffer in the mask
                                    read_seq_state <= READ_SEQ_WAIT; -- Go back to wait mode to check for new buffers
                                else
                                end if; -- more buffers to process?
                            end if;


    	                end if; -- HEADER or DATA ready to be sent
	            end case;




                -- Convert useful signals to variables and integers for ease of use
                buf := buf_ix(0);
                src := ram_readout_src(to_integer(buf));
                src_int := to_integer(to_unsigned(src));

	            -- Prepare the frame information.
	            --
	            -- The header info is used in the data processor machine below.
	            -- The signals used to build the header (high bits of read_seq_byte_ctr, timestamp) changes with the RAM read address,
	            -- i.e. a few clocks before the frame header data it is actually used.
	            -- Since we  have plenty of data to send before the next header is processed,
	            -- but we have finished reading the header well before its value changes again.
	            frame_header.PROBE_ID := X"A0";
	            frame_header.PROBE_ID(0) := src; -- current source;
	            frame_header.SERIAL_FLAGS := "0000"; -- serial_flags(2 downto 0) & in_dat(source).TUSER(TUSER_SERIAL_FLAGS_BIT);
	            frame_header.FLAGS := mode & std_logic_vector(read_proc_pkt_ctr(1 downto 0)); --mode and subframe number;
	            -- Override the capture flag withthe overflow flags so we know  from the packet header if somewhing is amiss with the stream
	            --frame_header.FLAGS(TUSER_CAPTURE_BIT) := data_fifo_overflow_sticky or header_fifo_overflow_sticky;
	            frame_header.TIMESTAMP := std_logic_vector(capture_timestamp(src_int));
	            -- Set the STREAM ID. Format is: 4-bit frame , 8-bit crate/slot, 4-bit channel
				frame_header.STREAM_ID := (others => '0'); -- make sure unassigned bits are zero
				frame_header.STREAM_ID(11 downto 4) := user_stream_id;
	            case mode is
	                when  "00" => -- 8 channel mode (pkt ctr = 3 bit chan, 1 bit seq, 2 bit subframe)
	                    -- STREAM_ID = "000" [1-bit frame #] [8-bit crate/slot #] "0" [3-bit chan #]
			            frame_header.STREAM_ID(12) := read_proc_pkt_ctr(2); -- frame (0-1)
			            frame_header.STREAM_ID(2 downto 0) := std_logic_vector(buf); -- channel (0-7)
	                when "01" => -- 4-channel mode   (pkt ctr = 2 bit chan, 2 bit seq, 2 bit subframe)
	                    -- STREAM_ID = "00" [2-bit frame #] [8-bit crate/slot #] "0" [3-bit chan #]
			            frame_header.STREAM_ID(13 downto 12) := std_logic_vector'(buf(0) & read_proc_pkt_ctr(2)); -- frame (0-3)
			            frame_header.STREAM_ID(2 downto 0) := std_logic_vector(chan_pair_sel(to_integer(buf(2 downto 1)))); -- channel (0-7) from chan_pair_sel(buf/2)
	                when "10" => -- 2-channel mode (pkt ctr = 1 bit chan, 3 bit seq, 2 bit subframe)
	                    -- STREAM_ID = "0" [3-bit frame #] [8-bit crate/slot #] "0" [3-bit chan #]
			            frame_header.STREAM_ID(14 downto 12) := std_logic_vector(buf(1 downto 0) & read_proc_pkt_ctr(2));
			            frame_header.STREAM_ID(2 downto 0) := std_logic_vector(chan_pair_sel(to_integer(buf(2 downto 1)))); -- channel (0-7) from chan_pair_sel(buf/2)
	                when "11" => -- 1-channel mode (pkt ctr =  4 bit seq, 2 bit subframe)
	                    -- STREAM_ID = [4-bit frame #] [8-bit crate/slot #] "0" [3-bit chan #]
			            frame_header.STREAM_ID(15 downto 12) := std_logic_vector(buf(2 downto 0) & read_proc_pkt_ctr(2));
			            frame_header.STREAM_ID(2 downto 0) := std_logic_vector(chan_pair_sel(to_integer(buf(2 downto 1)))); -- channel (0-7) from chan_pair_sel(buf/2)
                    when others =>
--                        assert False report "Unhandled mode" severity failure;
	            end case;
                -- Convert to an array of bytes
	            frame_header_bytes := struct_to_bytes(frame_header);

                -- RAM data processor
                --
                -- This logic processes words coming out of RAM after the read latency period.
                -- The processing is based on the opcode sent by the read sequencer, which is delayed to arrive at the same time as the data.
                -- The process sets the write control signals of the FIFO: tdata (8 bits), tvalid & tlast.

                -- Default values for the FIFO signals
                fifo_in_tvalid <= '0';
                fifo_in_tlast <= '0';


                case read_proc_op(0) is

                    when READ_PROC_SEND_HEADER | READ_PROC_SEND_LAST_HEADER =>
                        -- Send the data as per the instructions from the control signals
                        byte_int := to_integer(read_proc_byte_ctr); -- Read in natural array order
                        fifo_in_tdata <= frame_header_bytes(byte_int);
                        fifo_in_tvalid <= '1';
                        read_proc_byte_ctr <= read_proc_byte_ctr + 1;
                        if read_proc_op(0) = READ_PROC_SEND_LAST_HEADER then
                            read_proc_byte_ctr <= (others => '0');
                        end if;

                    when READ_PROC_SEND_DATA | READ_PROC_SEND_LAST_PACKET_DATA |READ_PROC_SEND_LAST_DATA =>
                        -- get the right byte from the right data buffer
                        -- The logic implies a combinatorial 16x 8:1 mux followed by  8x 16:1 mux. Might limit logic speed.
                        byte_int := to_integer(not read_proc_byte_ctr); -- invert bits to read from MSB to LSB
                        fifo_in_tdata <= ram_dout(to_integer(buf))(8*byte_int+7 downto 8*byte_int);
                        fifo_in_tvalid <= '1';
                        read_proc_byte_ctr <= read_proc_byte_ctr + 1;
                        if read_proc_op(0) = READ_PROC_SEND_LAST_PACKET_DATA or read_proc_op(0) = READ_PROC_SEND_LAST_DATA then
                            fifo_in_tlast <= '1';
                            read_proc_byte_ctr <= (others => '0');
                            read_proc_pkt_ctr <= read_proc_pkt_ctr + 1;
                            if read_proc_op(0) = READ_PROC_SEND_LAST_DATA then
                                read_proc_pkt_ctr <= (others => '0');
                            end if;
                        end if;
                    when others =>
                        -- Do nothing

                    end case;

                -- keep track of fifo overflows
                if fifo_overflow then
                    fifo_overflow_sticky <= '1';
                end if;

                -- synchronous reset
	            if rst or user_reset_reg then
                    fifo_overflow_sticky <= '0';
	                fifo_in_tvalid <= '0'; -- needed
	                read_seq_byte_ctr <= (others => '0');
	                read_seq_state <= READ_SEQ_WAIT; -- needed to make sure we start with header transmission
                    read_proc_byte_ctr <= (others=> '0'); -- needed for the first frame header transmission
                    read_proc_pkt_ctr <= (others=> '0'); -- needed for the first frame header transmission
	            end if; -- reset

	        end if; --s_axis_clk
	    end process;
    end block rd_blk;

    -- Readout FIFO: takes the 8-bit data from the read sequencer, stores it, and
    -- trickles it out on the output clock domain.
    --
    -- Asynchronous FIFO, 9-bit wide (8 data + 1 tlast) x 512 deep, FWFT, with prog_full.
    --
    -- FIFO depth requirements: There is a considerable delay between the time the read side sees there is data on the write side (4-5 slow clocks, which is equivalent to 16-20 fast clocks).
    -- If the FIFO is not deep enough, the readout stops needlessly. Data is good, but bandwidth is reduced needlessly.
    --
    -- prog_full requirements: We have to set the full threshold to 16-6 = 12 to make sure that flushing the writes in the pipeline won't overflow the FIFO.
    -- This means the depth of the FIFO should be ~6 + 20 = 26. The FIFO does not work properly in simulation with values not multiples of 16.
    fifo_blk: block
        signal fifo_dout: std_logic_vector(8 downto 0);
    begin

		process(all) begin
			if rising_edge(m_axis_clk) then
				m_clk_ctr <= m_clk_ctr + 1;
				out_frame_ctr <= out_frame_ctr + 1 when m_axis_tvalid and m_axis_tlast;
			end if;
		end process;

        -- Connect FIFO output to output port of this entity
        (m_axis_tlast, m_axis_tdata) <= fifo_dout;

        fifo0: entity work.generic_fifo
            generic map (
                FPGA_SERIES      => FPGA_SERIES,
                MEMORY_TYPE      => "embedded",
                IS_ASYNC         => TRUE,
                IS_FWFT          => TRUE,
                DATA_WIDTH       => 9,       -- 8 data + 1 tlast. Default depth is 512 words so a FIFO18 will be used.
                PROG_FULL_THRESH => 256      -- Must be big enough to handle the throttling signal latency
            )
            port map (
                wr_clk      => s_axis_clk,
                wr_en       => fifo_in_tvalid,
                din         => (8 => fifo_in_tlast, 7 downto 0 => fifo_in_tdata),
                prog_full   => fifo_full,
                overflow    => fifo_overflow,
				wr_rst_busy => fifo_wr_rst_busy,
                rd_clk      => m_axis_clk,
                rd_en       => m_axis_tready and m_axis_tvalid,
                dout        => fifo_dout,
                valid       => m_axis_tvalid,
				rd_rst_busy => fifo_rd_rst_busy,
                rst         => rst or user_reset_reg
            );
    end block;

end impl;
