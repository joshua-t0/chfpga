----------------------------------------------------------------------------------
-- Company: McGill University
-- Engineer: J.-F. Cliche
--
-- Create Date:    16:32:32 05/02/2011
-- Design Name: chFPGA PoC
-- Module Name:    CHAN_SEL - impl
-- Project Name: CHIME
-- Target Devices: Virtex 6 or 7 series
-- Tool versions: Vivado 2013.4
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
--  2011-07-18 JFC: Modified output interface to 32 bits, with header inserted in the stream
--    Major cleanup of the FIFO writer code to make it more readable (?). Removed all (?) combinatorial signals.
--  2012-05-31 JFC: Modified for AXI4 Streaming interface. Removed the VALID handling. All frames are processed, but the TUSER flags are passed on to the header and output.
--  2012-10-20 JFC: Made the RESET synchronous to allow more flexibility to the Synthesizer and help
--    meet timing constraints. Resized the word counter to LOG2_MAX_NUMBER_OF_WORDS to reduce the
--    load on the RAM output (the mask bit a) determines when to incement the counter and b)is
--    used to mux whether we store length or length+1 in header)
--  2013-12-05 JFC: Added 4-bit mode and multi-frame packing support. Output reset is now same as input reset to avoid saturating the FIFOs unless the right sequence of reset is used.
--  2014-01-14 JFC: Modified into CHAN_SEL with new architecture: Now has a front-end FIFO for alignment/half-word selection/buffer consecutively selected channels. There is no more output fifos.
--    Also added handling of headers and flagging info.
-- Additional Comments:
--
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;
use ieee.std_logic_misc.ALL; -- for and_reduce
use ieee.math_real.ALL; -- for ceil()

library unisim;
use unisim.vcomponents.ALL;
use work.chfpga_package.ALL; -- Get all component definitions

-- Select specific frequency bins across all incoming channelizer data
-- streams and repackage them into output packets of N frames with a
-- header block and data and frame overflow flags repackaged and grouped
-- at the end of each packet.
--
--
-- The purpose of this module is to aggregate into a single stream the data
-- from all channelizers but for a subset of frequency bins, and combine those in packets with headers and flags.
--
-- Both the input and outputs operate on a single clock. Since new data
-- (header, flags) is added to the frame, the clock  must be fast enough to
-- allow for the overhead.
--
-- The frequency channels are selected by writing a bit pattern into a RAM block, where each bit identifies
-- whether the corresponding word (containing a pair of frequency samples) is to passed on to the output.
-- The streams coming from all antennas are filtered using the same pattern.
--
-- No frame is transmitted (not even a header with empty payload) of no data was selected by the filtering process.
--
-- Both inputs and outputs are implemented using the snatdard AXI4 Straming protocol.
-- The input bus is non-blocking, and contains only time or frequency samples.
-- The output bus is blocking and contains a frame header in addition to the filtered and reordered data.
-- A blocking interface was implemented for the output bus because it will eventually be connected to data shuffling logic (MGTs) which might require transmission of data in bursts without interruption.
--
-- The module assumes that channelizers input streams operate on a single clock and are frame-aligned.
--
-- Bypass mode
-- -----------
--

-- In BYPASS mode all bins are selected (both the odd and even), but data comes only from one or two input lanes depending whether we operate in 4-bit or 8-bit mode.
--
-- In 4 bit mode, the 4 MSB bits of each byte of input lanes LANE_NUMBER*2 and LANE_NUMBER*2+1 are
-- packed into a 32 bit output word. This allows the data from 16 channelizers to be packed into 8
-- bin selectors, allowing the data to be ultimately passed to the GPU links.
--
-- In the case of the 4-bit mode, if the FFT is enabled, it make sense to enable the SCALER to scale the FFT output
-- to (4+4) bit complex values. That allows the sending of the pre-corner-turn channelized data to
-- the GPUs. If the FFT is bypassed, The SCALER could be configured to scale each of the 8-bit samples into four 4-bit values.
--
-- If the bypass is use din the 8 bit mode, the 32-bit word from the input lanes LANE_NUMBER is sent directly to the output.
-- 16 bin selectors can therefore forward the 8-bit raw data from all 16 channelizers, but only 8 of those 16 streams can be ultimately forwarded through the 8 GPU links.
--
-- Packet headers are sent normally in bypass mode, but the `send_flags` value is ignored and no
-- data, frame or packet flags are sent  (the data and frame flags are still collected in the FIFOs
-- but they are never read out).
--
-- Word selection map format
-- -------------------------
--
-- Each bit in the RAM block identifies whether a 32-bit word received from the antenna processor module is to be kept or not.
-- The mapping is as follows:
--
-- #Byte | bit | Flag for Word # | Time sample # | Frequency sample #
-- #-----|-----|-----------------|---------------|--------------------
-- #  0  |  0  | Word 0          | 0-3           | 0-1
-- #  0  |  1  | Word 1          | 4-7           | 2-3
-- #...  | ... | ...             |  ...          | ...
-- #  0  |  7  | Word 7          | 28-31         | 14-16
-- #  1  |  0  | Word 8          | 32-35         | 16-17
-- #...  | ... | ...             |               | ...
-- #  63 |  7  | Word 511        | 2044-2047     | 1022-1023
-- #
--

entity chan_bin_sel is
	generic (
		PLATFORM_ID      : integer;
		LANE_NUMBER      : integer; --
		NUMBER_OF_INPUTS : integer  -- Number of lanes to capture simultaneously. Must be a multiple of 4 between 4 and 16.
	);
	port (
		-- Input interface (non-blocking, i.e. always accepts data)

		s_axis_tdata  : in slv32_array(0 to NUMBER_OF_INPUTS - 1);
		s_axis_tuser  : in slv4_array(0 to NUMBER_OF_INPUTS - 1);
		s_axis_tvalid : in std_logic_vector(0 to NUMBER_OF_INPUTS - 1);
		s_axis_tlast  : in std_logic_vector(0 to NUMBER_OF_INPUTS - 1); -- unused

		s_axis_global_tvalid : in std_logic; -- active while the longest packet is active
		s_axis_global_tlast  : in std_logic; -- active when the longest packet is at its last word

		bin_ctr_en  : in std_logic;
		bin_ctr_clr : in std_logic;

		-- Output interface (non-blocking AXI4-Streaming)

		m_axis_tdata  : out slv32;
		m_axis_tvalid : out std_logic;
		m_axis_tlast  : out std_logic;

		clk : in std_logic; -- Input clock, common to all input and output buses
		rst : in std_logic; -- reset, synchronous to clk

		-- BSB Control interface

		s_axis_bsb_tdata  : in std_logic_vector(7 downto 0);
		s_axis_bsb_tvalid : in std_logic;
		s_axis_bsb_tlast  : in std_logic;
		s_axis_bsb_tready : out std_logic;
		m_axis_bsb_tdata  : out std_logic_vector(7 downto 0);
		m_axis_bsb_tvalid : out std_logic;
		m_axis_bsb_tlast  : out std_logic;
		m_axis_bsb_tready : in std_logic;
		bsb_clk           : in std_logic;
		bsb_rst           : in std_logic
	);
end entity chan_bin_sel;

--- ARCHITECTURE DECLARATION and DEFINITION ---------------------
-- Describes the logic that implement the entity's functionnalities. See this architecture for the implementation details.
--
-- The writing process waits for all channels to have valid data, and if the filter bit is '1', the data from each antenna is written in their respective FIFO.
-- Then the filter RAM 'bit' pointer is incremented.
-- When the last word of a frame is detected, the pointer is reset, the header is constructed and is written in the HEADER FIFO.
-- This assumes that all the input data streams are aligned.
--

architecture impl of chan_bin_sel is

	attribute KEEP_HIERARCHY: string;
	attribute keep_hierarchy of impl: architecture is "yes";

	attribute KEEP: string;
	attribute EQUIVALENT_REGISTER_REMOVAL: string;

	constant FPGA_SERIES: integer := FPGA_SERIES_LIST(PLATFORM_ID);

	signal s_axis_global_tfirst: std_logic;

	signal m_axis_tdata_int: slv32;
	signal m_axis_tvalid_int: std_logic;
	signal m_axis_tlast_int: std_logic;
	-- MASK RAM signals
	--  Port A: Control port ( data width: 8 bits)
	signal mask_ram_ctrl_addr: std_logic_vector(6 downto 0);
	-- signal mask_ram_ctrl_rd_en: std_logic;
	signal mask_ram_ctrl_wr_en: std_logic;
	signal mask_ram_ctrl_wr_en_vect: std_logic_vector(0 downto 0);
	signal mask_ram_ctrl_din: std_logic_vector(7 downto 0);
	signal mask_ram_ctrl_dout: std_logic_vector(7 downto 0);

	--  Port B: Data processing port ( data width: 1 bit)
	signal mask_ram_dout: std_logic_vector(1 downto 0);            -- Up to 2 selection flags per word (both flags are used only in dual-channel mode, otherwise only the LSB is used)
	signal mask_ram_addr: unsigned(8 downto 0) := (others => '0'); -- up to 512 flag groups. Initialization needed to prevent 'U' from getting into the RAM before the clock starts and resets this register.

	-- Scaler flags FIFO signals
	signal data_flags_fifo_rd_en: std_logic := '0';
	signal data_flags_fifo_wr_en: std_logic := '0';
	signal data_flags_fifo_empty: std_logic;
	signal data_flags_fifo_valid: std_logic;
	signal data_flags_fifo_overflow: std_logic;
	signal data_flags_fifo_full: std_logic;
	signal data_flags_fifo_din: slv33;
	signal data_flags_fifo_dout: slv33;
	-- signal data_type_fifo_count: std_logic_vector(8 downto 0);

	signal data_flags_fifo_overflow_sticky: std_logic; -- indicates that one of the data FIFO has overflown.

	signal scaler_flags: std_logic_vector(31 downto 0);
	signal scaler_flags_word_ctr: unsigned(11 downto 0); -- cannot exceed the size of the GPU link buffer (16Kbytes = 4Kwords);
	signal scaler_flags_ctr: unsigned(4 downto 0);  -- counts the number of flags in the scaler flag register.
	signal scaler_flags_ctr_max: unsigned(4 downto 0);  --

	-- ADC flags FIFO signals
	signal frame_flags_fifo_rd_en: std_logic := '0';
	signal frame_flags_fifo_wr_en: std_logic := '0';
	signal frame_flags_fifo_empty: std_logic;
	signal frame_flags_fifo_valid: std_logic;
	signal frame_flags_fifo_overflow: std_logic;
	signal frame_flags_fifo_full: std_logic;
	signal frame_flags_fifo_din: slv33     := (others => '0'); -- needed for sims so we don't confuse xglink
	signal frame_flags_fifo_dout: slv33;
	--
	signal frame_flags_fifo_overflow_sticky: std_logic; -- indicates that one of the data FIFO has overflown.

	-- DATA FIFO signals
	signal data_fifo_rd_en: std_logic;
	signal data_fifo_wr_en: std_logic := '0';
	signal data_fifo_wr_ctr: unsigned(1 downto 0);
	signal data_fifo_empty: std_logic;
	signal data_fifo_valid: std_logic;
	signal data_fifo_overflow: std_logic;
	signal data_fifo_full: std_logic;
	signal data_fifo_last: std_logic;

	signal data_fifo_din: slv65_array(0 to NUMBER_OF_INPUTS / 4 - 1) := (others => (others => '0'));
	signal data_fifo_din_sel: slv65;
	signal data_fifo_din32: slv36;

	signal data_fifo_dout: slv65;
	signal data_fifo_dout32: slv36;

	signal data_fifo_overflow_sticky: std_logic; -- indicates that one of the data FIFO has overflown.

	signal store_data: std_logic;

	-- signal IN_DAT_ALIGN: AXIS32_DAT_STRUCT_ARRAY,(0 to NUMBER_OF_INPUTS-1);

	signal frame_header: shuffle_frame_header_struct;
	-- signal timestamp_ctr: unsigned(SHUFFLE_FRAME_HEADER_STRUCT.TIMESTAMP'Range):=(others=>'0');
	signal timestamp_ctr: unsigned(47 downto 0) := (others => '0');
	signal frame_ctr: unsigned(1 downto 0); -- counts the frames within a packet
	signal header_word_ctr: unsigned(bitwidth(SHUFFLE_FRAME_HEADER_WORD_LENGTH - 1) - 1 downto 0);

	signal out_word_ctr: unsigned(9 downto 0)  := (others => '0');
	signal bin_ctr: unsigned(10 downto 0) := (others => '0');
	signal bin_ctr_max: unsigned(10 downto 0);

	signal reset_all: std_logic;

	--- Define Control word and its signals
	signal control_bytes: slv8_array(0 to 4); -- default value set in the CMD_SLAVE
	signal status_bytes: slv8_array(0 to 2); -- default value set in the CMD_SLAVE

	signal stream_id: std_logic_vector(11 downto 0);
	signal user_reset: std_logic;
	signal four_bits: std_logic;
	signal overflow_reset: std_logic;
	signal use_offset_binary: std_logic;
	signal send_flags: std_logic;
	signal number_of_selected_bins: unsigned(10 downto 0); -- number of words that are selected by the word selection map
	signal word_ctr: unsigned(10 downto 0);
	signal frames_per_packet: unsigned(2 downto 0);  -- number of input frames to put in one output frame
	signal packet_frame_ctr: unsigned(7 downto 0);  -- Counts the current number of frames in the output packet
	signal packet_frame_ctr_max: unsigned(7 downto 0);  -- Counts the current number of frames in the output packet
	signal in_frame_ctr: unsigned(7 downto 0);  -- Counts incoming frames. Used for debugging.
	signal bypass: std_logic;
	signal bypass_reg: std_logic;
	signal combine_data_flags: std_logic;

	-- FIFO readout states (one-hot encoding)
	signal send_header: std_logic;
	signal send_data: std_logic;
	signal send_data_flags: std_logic;
	signal send_frame_flags: std_logic;
	signal send_packet_flags: std_logic;
	-- signal send_odd_data_flags: std_logic;
	signal send_strobe: std_logic;

	signal number_of_input_lanes: unsigned(4 downto 0); -- Acceptable values: 4,8,12 or 16
	-- signal fifo_ctr: unsigned(1 downto 0); -- counts the fifo in order to know which oue is read out.
	signal first_fifo_number: unsigned(1 downto 0); --
	signal last_fifo_number: unsigned(1 downto 0); --
	signal last_fifo_number_int: unsigned(1 downto 0); --
	-- signal lane_errors: std_logic_vector(15 downto 0); -- Represents errors received for each lane.
	-- signal half: std_logic;

	signal bin_number: unsigned(9 downto 0); -- Up to 1024 bins per frame

-- constant SELECT_ODD_BIN_BIT: integer := 35;
-- constant SELECT_EVEN_BIN_BIT: integer := 34;
-- constant SCALER_HIGH_OVERFLOW_BIT: integer := 33;
-- constant SCALER_LOW_OVERFLOW_BIT: integer:= 32;

begin

	-----------------------------------------------------------------------------------
	-- CONTROL and STATUS Bytes
	-----------------------------------------------------------------------------------
	-- chan_bin_sel Memory Map
	-- ------------------------------------------------------------------------------
	-- |  Page   | Addr|Bit(s)|     Name             | Description                   |
	-- |---------|-----|------|----------------------|-------------------------------|
	-- | CONTROL |  0  |   7  | user_reset               | Reset the CH_DIST and clears the FIFOs.|
	-- |         |     |   6  | four_bits                | The input data is in 4-bit mode. The word streams will be combined 2-by-2 to pack 4 (4+4) bits samples in the output word|
	-- |         |     |   5  | use_offset_binary        | Indicates if the data is encoded in offset_binary or 2's complement. This is not used by this module, but is passed in the header flags. |
	-- |         |     |   4  | send_flags               | Indicates if we want the packets to contain scaler and adc flags. Need to reset the module if this is changes to ensure proper FIFO synchronization|
	-- |         |     |   3  | overflow_reset           | Resets the overflow counter |
	-- |         |     | 2:0  | frames_per_packet        | Number of input frames to group into an output packet.|
	-- |         |  1  | 7:0  | STREAM_ID(11:4)          | Upper 8 bits of Stream ID to be used for tagging the output frames |
	-- |         |  2  | 7:4  | STREAM_ID(3:0)           | Lower 4 bits of Stream ID |
	-- |         |     | 2:0  | number_of_selected_bins(10:8)| Upper 3 bits of number of selected bins |
	-- |         |  3  | 7:0  | number_of_selected_bins(7:0)| Lower 8 bits of number of selected bins. Indicates the number of words (frequency bin pairs) that are selected. This must match the number of '1' bits in the word selection map.|
	-- |         |  4  | 7:6  | (unused)                 |                               |
	-- |         |     |   5  | bypass                   | Pass data from lane directly to the output without flags.|
	-- |         |     |   4  | combine_data_flags       | Combine data flags |
	-- |         |     | 3:2  | first_fifo_number       | First FIFO number |
	-- |         |     | 1:0  | last_fifo_number         | Last FIFO number |
	-- | STATUS  |  0  |   7  | data_fifo_empty          | EMPTY status flag of the DATA FIFO for antenna processor 0. Active HIGH. |
	-- |         |     |   6  | data_fifo_overflow_sticky| Sticky flag indicating that one of the DATA FIFO has overflown. Cleared only by a reset of the module.|
	-- |         |     |   5  | reset_all                | Reset all status |
	-- |         |     |   4  | 8-bit support (always 0)                 |                               |
	-- |         |     | 3:2  | frame_ctr                | Frame per packet counter (2 bits) |
	-- |         |     |   1  | data_flags_fifo_overflow_sticky | Sticky flag for data flags FIFO overflow |
	-- |         |     |   0  | frame_flags_fifo_overflow_sticky | Sticky flag for frame flags FIFO overflow |
	-- |         |  1  |  7:0 | timestamp_ctr            | Last 8 bits of timestamp counter |
	-- |         |  2  |  7:0 | in_frame_ctr             | Input frame counter |
	-- | RAM     | 0-63 | -   | MASK_RAM                 | Word selection map. Each of the 512 bit indicates whether the corresponding word (frequency bin pair) is retained by this correlator. |
	-- ------------------------------------------------------------------------------
	--
	-- ------------------------------------------------------------------------------------
	-- | overflow_reset | four_bits | Number of selected_bins                | Number of inputs |
	-- |----------|-----------|----------------------------------------|------------------|
	-- |    0     |     0     |                                        | Multiple of 2    |
	-- |    0     |     1     |                                        | Multiple of 4    |
	-- |    1     |     0     | Even, odd-even pair selected together  | Any              |
	-- |    1     |     1     | Even, odd-even pair selected together  | Multiple of 2    |
	-- ------------------------------------------------------------------------------------

	-- CONTROL Byte 0
	user_reset        <= control_bytes(0)(7);                    -- Used in both IN_CLK and OUT_CLK domain
	four_bits         <= control_bytes(0)(6);                    --
	use_offset_binary <= control_bytes(0)(5);                    --
	send_flags        <= control_bytes(0)(4);
	overflow_reset    <= control_bytes(0)(3);
	frames_per_packet <= unsigned(control_bytes(0)(2 downto 0)); -- used in IN_CLK domain

	-- CONTROL Byte 1-3
	stream_id               <= (control_bytes(1) & control_bytes(2)(7 downto 4));                            --
	number_of_selected_bins <= unsigned(std_logic_vector'(control_bytes(2)(2 downto 0) & control_bytes(3))); -- used in IN_CLK domain

	-- CONTROL Byte 4

	bypass             <= control_bytes(4)(5);
	combine_data_flags <= control_bytes(4)(4);
	first_fifo_number  <= unsigned(control_bytes(4)(3 downto 2));
	last_fifo_number   <= unsigned(control_bytes(4)(1 downto 0));
	-- number_of_input_lanes <= unsigned(control_bytes(4)(4 downto 0)); --

	-- STATUS Byte 0
	status_bytes(0)(7)          <= data_fifo_empty;
	status_bytes(0)(6)          <= data_fifo_overflow_sticky;
	status_bytes(0)(5)          <= reset_all;
	status_bytes(0)(4)          <= '0'; -- was to_std_logic(EIGHT_BIT_SUPPORT);
	status_bytes(0)(3 downto 2) <= to_slv(frame_ctr);
	status_bytes(0)(1)          <= data_flags_fifo_overflow_sticky;
	status_bytes(0)(0)          <= frame_flags_fifo_overflow_sticky;

	-- STATUS Byte 1
	status_bytes(1) <= to_slv(lsb(timestamp_ctr, 8));
	status_bytes(2) <= to_slv(in_frame_ctr);
	-- status_bytes(3)<=to_slv(DOUT_FRAME_CTR);

	-- debug ports
	-- status_bytes(4)(6)<= data_fifo_rd_en;
	-- status_bytes(4)(7)<=data_fifo_rd_en;

	-- status_bytes(5)(3 downto 0)<= reverse_bits_and_dir(data_fifo_valid(0 to 3));
	-- status_bytes(5)(7 downto 4)<= reverse_bits_and_dir(data_fifo_overflow(0 to 3));

	-----------------------------------------------------------------------------------
	-- Memory-Mapped interface instantiation
	-----------------------------------------------------------------------------------
	-- Instantiates a memory-mapped interface to the control and status bytes

	bsb_regs0: entity work.bsb_regs
		generic map (
			NUMBER_OF_CONTROL_BYTES => control_bytes'Length(1),
			NUMBER_OF_STATUS_BYTES  => status_bytes'Length(1),
			DEFAULT_CONTROL_BYTES   => X"74_123_010_03",
			RAM_ADDR_WIDTH          => 7,
			RAM_LATENCY             => 2,  -- Control port of RAM has an output register that creates a 2-clock latency total
			USE_RAM_DOUT_RDY        => FALSE
		)

		port map (
			-- Control interface (command and reply stream buses)
			s_axis_bsb_tdata  => s_axis_bsb_tdata,
			s_axis_bsb_tvalid => s_axis_bsb_tvalid,
			s_axis_bsb_tlast  => s_axis_bsb_tlast,
			s_axis_bsb_tready => s_axis_bsb_tready,
			m_axis_bsb_tdata  => m_axis_bsb_tdata,
			m_axis_bsb_tvalid => m_axis_bsb_tvalid,
			m_axis_bsb_tlast  => m_axis_bsb_tlast,
			m_axis_bsb_tready => m_axis_bsb_tready,
			bsb_clk           => bsb_clk,
			bsb_rst           => bsb_rst,

			control_bytes => control_bytes,
			status_bytes  => status_bytes,

			ram_din   => mask_ram_ctrl_din,
			ram_dout  => mask_ram_ctrl_dout,
			ram_addr  => mask_ram_ctrl_addr,
			ram_wr_en => mask_ram_ctrl_wr_en,
			ram_rd_en => open
		);

	------------------------------------------------
	-- Bin selection map RAM instantiation
	------------------------------------------------
	-- Indicates which data is to be stored (one bit per sample)
	-- Dual port RAM used to store the channel selection mask pattern
	-- The control side has 2 clock latency, as we use the embedded output registers to relax timing.
	-- The system-side port uses 2 clock output latency (no output registers) to avoid pipeling the wide data bus unnecessarily to align the ram content with the corresponding word.
	-- Port A is an 8-bit wide interface allowing the control system to program the RAM
	-- Port B is a 2-bit interface that the processing process reads to identify if a word is to be kept.
	-- We need to use a Block RAM (as opposed to distributed RAM) so we can have assymetric aspect ratio
	mask_ram0: entity work.mask_ram
		port map (
			clka   => bsb_clk,
			wea(0) => mask_ram_ctrl_wr_en,
			addra  => mask_ram_ctrl_addr,
			dina   => mask_ram_ctrl_din,
			douta  => mask_ram_ctrl_dout,

			clkb  => clk,
			web   => (others => '0'),
			dinb  => (others => '0'),
			addrb => std_logic_vector(bin_number(9 downto 1)),
			doutb => mask_ram_dout
		);

	---------------------------------------------------
	-- Data FIFOs
	---------------------------------------------------
	-- The DATA FIFO stores the data for the selected bins.
	--
	-- This is a synchronous, First Word Fall-through FIFO, implemented in
	-- BRAM. Reset is synchronous with no default value to save logic. VALID
	-- flag is needed. EMPTY and OVERFLOW flags are used for diagnosis.
	-- Embedded registers are needed to meet timing and save space.
	--
	--
	-- We have a single FIFO for all 16 input stream. The FIFO is 36 bits
	-- wide (32 bit for data, 1 bit for the LAST flag, others unused). It
	-- stores four (4+4) bits complex values at a time in 4-bit mode. All 16
	-- complex values are captured in a holding register and are written
	-- sequentially four at a time in the FIFO.
	--
	--
	-- All data FIFOs are Embedded FIFOs. They are paired with the DATA flag FIFOs which are BRAM-based.
	-- ** No longer supported** : If EIGHT_BIT_SUPPORT is true, a second FIFO is instantiated. The first
	-- FIFO stores the upper nibbles and the second FIFO stores the lower
	-- nibbles of every complex number. The second FIFO is then used only if
	-- eight-bit mode is selected by software. EIGHT-BIT support is generally disabled to save BRAM resources.
	--
	-- This FIFO needs to be deep enough to accomodate:
	--   -( *Not true anymore *) M*N/4 word, where M is the number of selected bins and N is the
	--     number of input lanes. For 16 output lanes, M is typically
	--     1024/16=64 and N=16, which corresponds to a depth of 256 words. A
	--     block RAM offers 512 words. Since the FIFO input is multiplexed by
	--     4:1, selected 'words' have to be separated by at least 3 non-
	--     selected 'words'. We therefore cannot select more than 512 words/frame / 4 * 16/4 lanes =512
	--     words or bins.
	--   - Data is streamed in real time from the FIFO right after the header, without waiting for the end of the packet. Therefore there is no need to store a full packet.
	--     However, the FIFO must be deep enough to buffer incoming data while the header of the current frame or the flags from the previous frame are sent.
	--
	-- A 36-bit wide x 512-word deep FIFO fits in a single 18K BRAM.
	--
	data_fifo_din_sel(63 downto 0) <= data_fifo_din(to_integer(data_fifo_wr_ctr))(63 downto 0);
	data_fifo_din_sel(64)          <= data_fifo_last and to_std_logic(data_fifo_wr_ctr = last_fifo_number_int);

	-- fourbitfifo_gen: if EIGHT_BIT_SUPPORT=FALSE generate

	data_fifo_din32(32)          <= data_fifo_din_sel(64);          -- LAST flag
	data_fifo_din32(31 downto 0) <= data_fifo_din_sel(31 downto 0); -- lower 4-bits of every value is discarded
	data_fifo_dout(64)           <= data_fifo_dout32(32);
	data_fifo_dout(31 downto 0)  <= data_fifo_dout32(31 downto 0);

	-- 7-series have only async resets (rst pin) on their embedded FIFOs, ultrascale+ has only synchronous reset (srst)

	data_fifo_k7: if FPGA_SERIES = FPGA_KINTEX7 generate

		data_fifo0: entity work.chdist_data_embed_fifo
			port map (
				rst => reset_all, -- async reset with builtin FIFO
				clk => clk,

				din   => data_fifo_din32,
				wr_en => data_fifo_wr_en,
				full  => data_fifo_full,

				rd_en => data_fifo_rd_en,
				dout  => data_fifo_dout32,
				valid => data_fifo_valid,
				empty => data_fifo_empty,

				overflow => data_fifo_overflow
			);

	end generate data_fifo_k7;

	data_fifo_up: if FPGA_SERIES = FPGA_ULTRASCALEPLUS generate

		data_fifo0: entity work.chdist_data_embed_fifo_up
			port map (
				srst => reset_all, -- sync reset with builtin FIFO
				clk  => clk,

				din   => data_fifo_din32,
				wr_en => data_fifo_wr_en,
				full  => data_fifo_full,

				rd_en => data_fifo_rd_en,
				dout  => data_fifo_dout32,
				valid => data_fifo_valid,
				empty => data_fifo_empty,

				overflow => data_fifo_overflow
			);

	end generate data_fifo_up;

	-- end generate; -- if EIGHT_BIT_SUPPORT=FALSE

	-- eightbitfifo_gen: if EIGHT_BIT_SUPPORT=TRUE generate
	--   data_fifo1 : CHDIST_DATA_FIFO
	--     port map (
	--       srst      => reset_all,
	--       clk      => clk,

	--       din      => data_fifo_din_sel,
	--       wr_en    => data_fifo_wr_en,
	--       full     => open,-- should be identical to the other FIFO

	--       rd_en    => data_fifo_rd_en,
	--       dout     => data_fifo_dout,
	--       valid    => open, -- should be identical to the other FIFO
	--       empty    => open, -- should be identical to the other FIFO

	--       overflow => open -- should be identical to the other FIFO
	--       );
	-- end generate; -- if EIGHT_BIT_SUPPORT

	---------------------------------------------------
	-- Data flags FIFOs
	---------------------------------------------------
	-- Stores the scaler flags so they can be transmitted at the end of the packet.
	--
	-- This is a synchronous First-Word-Fall-Through BRAM FIFO. VALID is needed.
	-- EMPTY and OVERFLOW are used for diagnosis. We used embedded registers to
	-- meet timing and save resources.
	--
	-- There is one data flag word per selected bin, each word containing
	-- between 4 to 16 flags depending on what input lanes is selected.
	--
	-- The FIFO is 17-bit wide (16 bits for flags, 1 bit for LAST). We need to store:
	--   - 1 word per selected bin per frame. (512/4 max words/frame * 4
	--     frames/packet = 512 word-deep FIFO).
	--
	-- A 17-bit wide x 512-word deep FIFO fits in a single 18K BRAM.
	-- We use a BRAM-based FIFO, so we can have a synchronous reset on any platform
	data_flags_fifo0: entity work.chdist_scaler_flags_fifo
		port map (
			srst => reset_all,
			clk  => clk,

			din   => data_flags_fifo_din,
			wr_en => data_flags_fifo_wr_en, -- we write the flags at the same time as the data words
			full  => data_flags_fifo_full,

			rd_en => data_flags_fifo_rd_en,
			dout  => data_flags_fifo_dout,
			valid => data_flags_fifo_valid,
			empty => data_flags_fifo_empty,

			overflow => data_flags_fifo_overflow
		);

	---------------------------------------------------
	-- Frame flags FIFOs
	---------------------------------------------------
	-- Stores the ADC and FFT saturation flags for each channelizer
	--
	-- Uses a 33-bit word x 16 word deep, synchronous distributed RAM FIFO to save BRAM
	-- resources. We did not use Shift-register FIFO because FWFT is not native
	-- (would need extra logic). We need VALID flag. EMPTY and OVERFLOW are useful for diagnosis.
	--
	-- We need 16 bits for ADC flags, 16 bits for FFT flags, and 1 bit for the
	-- last word indicator. The FIFO must accomodate F words, where F is the
	-- number of frames per packet (typically 4). 16-word deep is the smallest we can get.
	--
	frame_flags_fifo0: entity work.chdist_frame_fifo
		port map (
			rst => reset_all,
			clk => clk,

			din   => frame_flags_fifo_din,
			wr_en => frame_flags_fifo_wr_en,
			full  => frame_flags_fifo_full,

			rd_en => frame_flags_fifo_rd_en,
			dout  => frame_flags_fifo_dout,
			valid => frame_flags_fifo_valid,
			empty => frame_flags_fifo_empty,

			overflow => frame_flags_fifo_overflow
		);

	-- FIFO write process
	-- -------------------
	-- Sequences the data writes to the FIFO

	fifo_wr_proc: process(all)

		variable data_in_even: slv64;
		variable data_in_odd: slv64;
		variable data_in_mux1: slv64;
		variable data_in_mux2: slv64;
		variable scaler_flags_even: slv4;
		variable scaler_flags_odd: slv4;
		variable scaler_flags_mux1: slv4;
		variable scaler_flags_mux2: slv4;
		variable is_last_word_of_frame: std_logic;
		variable is_last_frame_of_packet: std_logic;

	begin
		if rising_edge(clk) then
			reset_all <= rst or user_reset;


			if reset_all = '1' or overflow_reset = '1' then
				data_fifo_overflow_sticky <= '0';
				data_flags_fifo_overflow_sticky <= '0';
				frame_flags_fifo_overflow_sticky <= '0';
			else
				if data_fifo_overflow = '1' then
					data_fifo_overflow_sticky <= '1';
				end if;
				if data_flags_fifo_overflow = '1' then
					data_flags_fifo_overflow_sticky <= '1';
				end if;
				if frame_flags_fifo_overflow = '1' then
					frame_flags_fifo_overflow_sticky <= '1';
				end if;
			end if;

			bypass_reg <= bypass;
			-- FIFO write
			-- Take all 4 words and writes them one after the other into the FIFO

			if bypass_reg = '0' then
				-- last_fifo_number <= min(lsb(number_of_input_lanes(4 downto 2)-1, 2), to_unsigned(NUMBER_OF_INPUTS/4-1,2));
				last_fifo_number_int <= last_fifo_number;
			else -- in bypass mode, we send every word from the input, so we read only one lane.
				last_fifo_number_int <= first_fifo_number;
			end if;


			if bin_ctr_en = '1' then  -- if any lane has valid data
				bin_number <= bin_number + 2; -- we send two bins per clock
				if bin_ctr_clr = '1' then -- if there is any valid EOF
					bin_number <= (others => '0');
				end if;
			end if;

			if reset_all = '1' then
				bin_number <= (others => '0');
			end if;


			-- Count the words written and stop writing after 4 words
			if data_fifo_wr_en = '1' then
				data_fifo_wr_ctr <= data_fifo_wr_ctr + 1;
				if data_fifo_wr_ctr = last_fifo_number_int then
					data_fifo_wr_en <= '0';
					data_fifo_last <= '0'; --
				end if;
			end if;

			-- test flags for better code readability
			is_last_word_of_frame := to_std_logic(word_ctr = number_of_selected_bins - 1);
			is_last_frame_of_packet := to_std_logic(frame_ctr = frames_per_packet - 1);

			-- By default, clear the following flags. Those are overriden below when necessary.
			data_flags_fifo_din(32) <= '0';
			frame_flags_fifo_din(32) <= '0';
			-- data_fifo_wr_en <= '0';
			data_flags_fifo_wr_en <= '0';
			frame_flags_fifo_wr_en <= '0';

			if s_axis_global_tvalid = '1' then
				-- Counts the incoming frames for debugging
				if s_axis_global_tlast = '1' then
					in_frame_ctr <= in_frame_ctr + 1;
				end if;

				-- if anything is selected, enable writing the data and data flags to their respective FIFOs.
				-- We write the fifo if storing is enabled (store_data='1') and if we have selected data to write.
				-- Normally the counter will reach the last word of a frame  with a non-zero selection, so the LAST flag will be written.
				-- If we are still expected to write data (store_data=1) but we reach the last word of the packet, we force a write to make sure we capture the LAST flag.
				-- If we select more words than the specified count, the extra words will be ignored.
				if store_data = '1' then
					if mask_ram_dout /= "00" or bypass_reg = '1' then
						data_fifo_wr_en <= '1';
						data_fifo_wr_ctr <= first_fifo_number;
						data_flags_fifo_wr_en <= to_std_logic(send_flags = '1' and (combine_data_flags = '0' or word_ctr(0) = '1'));
						-- count the words we are writing into the FIFO so we know when to set the LAST flag
						word_ctr <= word_ctr + 1;
					end if;
					-- Stop storing data and counting words if we have reached the last word of the frame.
					-- If bypass=1, never stop: we want to send every word in the frame
					if bypass_reg = '0' and is_last_word_of_frame = '1' and mask_ram_dout /= "00" then
						store_data <= '0';
					end if;
					-- Set the 'LAST' flag on the data FIFO and data flags FIFO when the first of the following happens in the last frame of the packet:
					--   - We reached the last selected word (is_last_word_of_frame='1' and mask_ram_dout/="00") when not in bypass mode
					--   - We reached the last word of the frame (s_axis_global_tlast='1')
					if ((bypass_reg = '0' and is_last_word_of_frame = '1' and mask_ram_dout /= "00") or s_axis_global_tlast = '1') and is_last_frame_of_packet = '1' then
						-- Set the 'LAST' flag in each data FIFO so the readout process knows when this is the last word of the packet for that FIFO.
						data_fifo_last <= '1';
						data_flags_fifo_din(32) <= '1';
						-- frame_flags_fifo_din(32) <= '1';
						-- force a write if we are still expected to send words when the last word of a packet occur so we will be sure to capture the LAST flag.
						-- Normally , if the count matches the number of non-zero select pairs, then  a write will have been initiated on the last word anyway.
						-- If not, this extra word will confuse the user, but the FIFOs readout sequence is safe even if the users misconfigures the system.
						data_fifo_wr_en <= '1';
						data_fifo_wr_ctr <= first_fifo_number;
						data_flags_fifo_wr_en <= send_flags;
					-- And also write the frame flags
					-- frame_flags_fifo_wr_en <= send_flags;
					-- packet_flags_fifo_wr_en <= '1';
					end if;
				end if;

				-- Capture the ADC and FFT flags at the end of each frame
				if s_axis_global_tlast = '1' then
					frame_flags_fifo_din(32) <= is_last_frame_of_packet;
					frame_flags_fifo_wr_en <= send_flags;
				end if;

				-- Count the frames, and reset the word counter at the end of each frame
				if s_axis_global_tlast = '1' then
					word_ctr <= (others => '0');
					store_data <= '1';

					frame_ctr <= frame_ctr + 1;
					if is_last_frame_of_packet = '1' then
						frame_ctr <= (others => '0');
					end if;
				end if;
			end if; -- if global_tvalid

			-- Capture the data, data flags and frame flags
			-- This is done on every clock, but is written only when the corresponding write enable signal is set.
			for i in 0 to NUMBER_OF_INPUTS / 4 - 1 loop
				-- For simplicity, we work with the 64-bit wide bus variables even if EIGHT_BIT_SUPPORT=FALSE. The synthesizer should remove the unused logic if not needed.
				-- Here, we separate the data in odd/even bins, and repack the data  to have all 4-bit values in bits 31:0, and the extra 4 bits on 63:32. The upper 32 bits is only for the extra bits needed in 8-bit mode.
				-- The word contains: (a=even, b=odd, an = (4+4) bit complex value (high nibbles), an* = (4+4) bits additional bits  (low nibbles)
				--     data_in_even(63:0) = a3* a2* a1* a0* a3 a2 a1 a0
				--     data_in_odd(63:0)  = b3* b2* b1* b0* b3 b2 b1 b0
				-- If we have a 32-bit fifo and therefore support only the 4-bit mode, we have all the data we need in the first 32 bits.
				for j in 0 to 3 loop
					-- EVEN bin
					-- Remap high nibble of complex value (used both in 4 and 8 bit mode)
					data_in_even(8 * j + 7 downto 8 * j + 4) := s_axis_tdata(4 * i + j)(31 downto 28); -- get high nibble, Real part, even bin
					data_in_even(8 * j + 3 downto 8 * j) := s_axis_tdata(4 * i + j)(23 downto 20); -- get high nibble, Imag part, even bin

					-- -- Remap low nibble of complex value (used only in 8 bit mode)
					-- data_in_even(32+8*j+7 downto 32+8*j+4) := s_axis_tdata(4*i+j)(27 downto 24); -- get low nibble, Real part, even bin
					-- data_in_even(32+8*j+3 downto 32+8*j) := s_axis_tdata(4*i+j)(19 downto 16); -- get low nibble, Imag part, even bin

					-- ODD bin
					-- Remap high nibble of complex value (used both in 4 and 8 bit mode)
					data_in_odd(8 * j + 7 downto 8 * j + 4) := s_axis_tdata(4 * i + j)(15 downto 12); -- get high nibble, Real part, odd bin
					data_in_odd(8 * j + 3 downto 8 * j) := s_axis_tdata(4 * i + j)(7 downto 4); -- get high nibble, Imag part, odd bin

					-- -- Remap low nibble of complex value (used only in 8 bit mode)
					-- data_in_odd(32+8*j+7 downto 32+8*j+4) := s_axis_tdata(4*i+j)(11 downto 8); -- get low nibble, Real part, odd bin
					-- data_in_odd(32+8*j+3 downto 32+8*j) := s_axis_tdata(4*i+j)(3 downto 0); -- get low nibble, Imag part, odd bin

					-- SCALER flags
					scaler_flags_even(j) := s_axis_tuser(4 * i + j)(TUSER_EVEN_SCALER_OVERFLOW_BIT);
					scaler_flags_odd(j) := s_axis_tuser(4 * i + j)(TUSER_ODD_SCALER_OVERFLOW_BIT);
				end loop;

				-- Select odd/even bin based on bit 0 of selection mask
				if mask_ram_dout(0) = '1' then -- if selection bits are "01" or "11"
					data_in_mux1 := data_in_even; -- grab the even bin
					scaler_flags_mux1 := scaler_flags_even;
				else
					data_in_mux1 := data_in_odd; -- grab the odd bin
					scaler_flags_mux1 := scaler_flags_odd;
				end if;

				data_in_mux2 := data_in_mux1;
				scaler_flags_mux2 := scaler_flags_mux1;

				-- ** Disabled feature **
				-- If we ask for both the odd and even words, then replace the even bin data from lane 2 and 3 with the odd data from lane 0 and 1
				-- Data from lanes 2 & 3 is lost, but at least we can send *all* the bins of the remaining lanes
				-- if mask_ram_dout="11" then
				--   for j in 0 to 1 loop
				--     data_in_mux2(8*(j+2)+7 downto 8*(j+2)) := data_in_odd(8*j+7 downto 8*j); -- replace a2 & a3 with b0 & b1
				--     data_in_mux2(32+8*(j+2)+7 downto 8*(j+2)) := data_in_odd(32+8*j+7 downto 8*j); -- replace a2* & a3* with b0* & b1*
				--     scaler_flags_mux2(j) := s_axis_tuser(4*i+(j+2))(TUSER_ODD_SCALER_OVERFLOW_BIT);
				--   end loop;
				-- end if;

				-- If we bypass, we raw capture all bins from only one lane (8-bit mode) or two lanes (4-bit mode).
				-- So we write only data_fifo_in(0) to save logic. Only that FIFO will be read out anyways.
				-- We also don't care about flags (they ar enot sent in bypass mode) so we do nothing with them to save logic
				if bypass_reg = '1' and i = 0 then
					if four_bits = '0' then
						data_in_mux2(31 downto 0) := s_axis_tdata(LANE_NUMBER);
					else
						data_in_mux2(31 downto 28) := s_axis_tdata((LANE_NUMBER * 2) MOD NUMBER_OF_INPUTS)(31 downto 28); -- get high nibble, Real part
						data_in_mux2(27 downto 24) := s_axis_tdata((LANE_NUMBER * 2) MOD NUMBER_OF_INPUTS)(23 downto 20); -- get high nibble, Real part
						data_in_mux2(23 downto 20) := s_axis_tdata((LANE_NUMBER * 2) MOD NUMBER_OF_INPUTS)(15 downto 12); -- get high nibble, Real part
						data_in_mux2(19 downto 16) := s_axis_tdata((LANE_NUMBER * 2) MOD NUMBER_OF_INPUTS)(7 downto 4);   -- get high nibble, Real part

						data_in_mux2(15 downto 12) := s_axis_tdata((LANE_NUMBER * 2 + 1) MOD NUMBER_OF_INPUTS)(31 downto 28); -- get high nibble, Real part
						data_in_mux2(11 downto 8) := s_axis_tdata((LANE_NUMBER * 2 + 1) MOD NUMBER_OF_INPUTS)(23 downto 20); -- get high nibble, Real part
						data_in_mux2(7 downto 4) := s_axis_tdata((LANE_NUMBER * 2 + 1) MOD NUMBER_OF_INPUTS)(15 downto 12); -- get high nibble, Real part
						data_in_mux2(3 downto 0) := s_axis_tdata((LANE_NUMBER * 2 + 1) MOD NUMBER_OF_INPUTS)(7 downto 4);   -- get high nibble, Real part
					end if;
				end if;

				-- Put the data flags on the input of their respective FIFOs .
				-- These values must be stable until we are finished writing them in the FIFO, so this is why we enable the register loading with the same conditions that make up a data_fifo_wr_en.
				if s_axis_global_tvalid = '1' and store_data = '1' and (mask_ram_dout /= "00" or bypass_reg = '1') then
					data_fifo_din(i)(63 downto 0) <= data_in_mux2;
				end if;
				-- scaler flags are one word long and are always registered in data_flags_fifo_din to avoid clock-enable logic.
				if combine_data_flags = '0' or word_ctr(0) = '0' then
					data_flags_fifo_din(4 * i + 3 + 16 downto 4 * i + 16) <= (others => '0');
					data_flags_fifo_din(4 * i + 3 downto 4 * i) <= scaler_flags_mux2;
				else
					data_flags_fifo_din(4 * i + 3 + 16 downto 4 * i + 16) <= scaler_flags_mux2;
				end if;
				-- Put the ADC and FFT flags of the selected values on the frame FIFO input. These will be written only at the end of each frame
				for j in 0 to 3 loop
					frame_flags_fifo_din(4 * i + j) <= s_axis_tuser(4 * i + j)(TUSER_ADC_OVERFLOW_BIT);
					frame_flags_fifo_din(16 + 4 * i + j) <= s_axis_tuser(4 * i + j)(TUSER_FFT_OVERFLOW_BIT);
				end loop;

			end loop; -- for i in 0 to NUMBER_OF_INPUTS/4-1


			if reset_all = '1' then
				word_ctr <= (others => '0');
				store_data <= '1';
				frame_ctr <= (others => '0');
			end if;

		end if; -- clk
	end process;


	-------------------------------
	-- FIFO Read Process
	-------------------------------
	-- This is a state machine that we implemented explicitely with one-hot states (send_header, send_data, send_data_flags, send_frame_flags, send_packet_flags).
	-- We did not let the synthesizer infer the state machine because we need to use the state variables combinatorially to enable the FIFO read enables.
	-- Why? Because the synthesizer does not take into account the one-hot nature of the encoding of states when the state variable is used outside the process, and will generate extra logic.
	--
	-- The readout of the FIFOS is not throttleled by the destination. We assume the destination can always take the data. This simplifies the logic and makes it easier to meet timing.
	--
	-- The output bus uses the standard non-blocking AXI4 STREAMING protocol
	--
	-- We use a native fall-through FIFOs to make the logic simpler and reduce the latency.
	--
	-- Transmission of the header is triggered by the arrival of the first frame
	-- of a packet, so we don't create a long delay between the header and the
	-- data, which will not please the downstream aligners.
	--
	-- Data is sent first after the header until the data for all frames of the packet is completed. So the data is sent as it comes, and the FIFO does not have to store lots of data.
	-- The data flags and frame flags FIFOs, however, are not sent until data is completed, so they must store a full set of flags for one full packet, plus the extra flags that are arriving while the flag FIFOs are emptied.

	number_of_input_lanes <= shift_left(resize(last_fifo_number - first_fifo_number, number_of_input_lanes'LENGTH), 2); -- number of input lanes included in the output stream. This is just for populating the header.

	-- Build the packet header, to be used by the FIFO readout process
	-- Build the header
	-- Word 0
	frame_header.COOKIE                 <= SHUFFLE_FRAME_HEADER_COOKIE;
	frame_header.PROTOCOL_VERSION       <= SHUFFLE_FRAME_HEADER_PROTOCOL_VERSION;
	frame_header.HEADER_LENGTH_IN_WORDS <= to_slv(SHUFFLE_FRAME_HEADER_WORD_LENGTH, frame_header.HEADER_LENGTH_IN_WORDS'LENGTH);
	frame_header.STREAM_ID(15 downto 4) <= stream_id;
	frame_header.STREAM_ID(3 downto 0)  <= to_slv(LANE_NUMBER, 4);
	-- Word 1
	frame_header.ENCODING           <= (0=> four_bits, 1=> use_offset_binary, 2=> send_flags and not bypass_reg, 3=> bypass_reg);
	frame_header.NUMBER_OF_FRAMES   <= to_slv(frames_per_packet, frame_header.NUMBER_OF_FRAMES'LENGTH);
	frame_header.NUMBER_OF_BINS     <= to_slv(number_of_selected_bins, frame_header.NUMBER_OF_BINS'LENGTH);   -- ** to be fixed : will change for 2nd, 3rd etc  shuffle
	frame_header.NUMBER_OF_ANTENNAS <= to_slv(number_of_input_lanes, frame_header.NUMBER_OF_ANTENNAS'LENGTH); -- ** to be fixed : will change for 2nd, 3rd etc  shuffle
	-- Word 2
	frame_header.ANCILLARY_DATA <= (X"0000" & std_logic_vector(timestamp_ctr(47 downto 32)));
	-- Word 3
	frame_header.TIMESTAMP <= std_logic_vector(timestamp_ctr(31 downto 0));

	-- FIFO Read enables
	-- These are derived sirectly from the state machine state. We use one-hot state machine states to minimize logic depth.
	-- We ignore the fifo valid flag because it will just generate an underflow, which we ignore.

	data_fifo_rd_en        <= send_data;
	data_flags_fifo_rd_en  <= send_data_flags;
	frame_flags_fifo_rd_en <= send_frame_flags;

	-- assign internal bus signals to output port
	m_axis_tdata  <= m_axis_tdata_int;
	m_axis_tvalid <= m_axis_tvalid_int;
	m_axis_tlast  <= m_axis_tlast_int;

	-- Readout process: reads the FIFOs and send the header, data, data flags, frame flags and packet flags
	fifo_rd_proc: process(all)

		-- variable ix: integer range 0 to NUMBER_OF_INPUTS/4-1;
		variable header_word_array: slv32_array(0 to SHUFFLE_FRAME_HEADER_WORD_LENGTH - 1);
		variable data_fifo_dout_mux1: slv32;
		variable data_fifo_dout_mux2: slv32;

	begin
		if rising_edge(clk) then
			------------------------------------
			-- SYNCHRONOUS RESET : See the end of the block
			-------------------------------------

			-- Detect arrival of first word of every incoming frame
			if s_axis_global_tvalid = '1' then
				s_axis_global_tfirst <= s_axis_global_tlast;
			end if;

			--------------
			-- Strobe signal
			--------------
			-- Make sure we don't start sending the header until the first frame of a packet has come in.
			-- Otherwise, if we start sending a header just after reset or just when a previous packet is finished,
			-- we end up with a crazy stretched-out transmission pattern (header, long pause, data burst when the data finally arrives through the channelizer pipeline).  That messes up
			-- the packet aligners downstream. The delay between the end of the header and the first data should be short enough to fit within the aligner window.
			-- Once the first frame is seen and transmission is started, we continuously send data/data flags/frame flags/packet flags until the end of the packet.
			-- Data transmission could still be irregular beause of bin selection patterns, but it should be handled by the aligner if the pattern is not too extreme.

			if s_axis_global_tvalid = '1' and s_axis_global_tfirst = '1' and frame_ctr = 0 then
				send_strobe <= '1'; -- zeroed below when header is finished
			end if;

			-- No data is sent (TVALID=0) by default
			m_axis_tvalid_int <= '0'; -- this is be overriden below


			-----------------------------
			-- FIFO readout state machine
			-----------------------------
			-- Is manually encoded as a one-hot state machine to reduce decoding logic depth

			-----------
			-- SEND HEADER
			-----------
			header_word_array := struct_to_word(frame_header);
			if send_header = '1' and send_strobe = '1' then
				m_axis_tdata_int <= header_word_array(to_integer(header_word_ctr)); --
				m_axis_tvalid_int <= '1';
				m_axis_tlast_int <= '0';
				header_word_ctr <= header_word_ctr + 1;
				if header_word_ctr = SHUFFLE_FRAME_HEADER_WORD_LENGTH - 1 then
					header_word_ctr <= (others => '0'); -- Clear counter in preparation for next header. could be moved up to save logic.
					send_header <= '0';
					send_data <= '1';
					timestamp_ctr <= timestamp_ctr + frames_per_packet; -- Continuously count frames to provide a timestamp (32 bit counter). NOTE: if the FIFO overflows, we will miscount the frame number. That ia a fatal error.
					send_strobe <= '0';
				end if;
			end if;

			-----------
			-- SEND DATA
			-----------
			-- ix := to_integer(fifo_ctr); -- shortcut to the output lane number
			if send_data = '1' and data_fifo_valid = '1' then -- we could possibly always use ix=0
				data_fifo_dout_mux2 := data_fifo_dout(31 downto 0); -- 4-bit mode assumed. Data is already packed. There is only one half to send.

				-- --8-bit mode: repack the data into (8+8) bit complex values
				-- if EIGHT_BIT_SUPPORT=TRUE and four_bits='0' then -- if no 8 bit support (i.e. 32-bit FIFO)
				--   for i in 0 to 3 loop
				--     data_fifo_dout_mux1(16*i+15 downto 16*i+12):= data_fifo_dout(8*i+7 downto 8*i+4); -- Real part, high nibble
				--     data_fifo_dout_mux1(16*i+11 downto 16*i+8) := data_fifo_dout(32+8*i+7 downto 32+8*i+4); -- Real part, low nibble
				--     data_fifo_dout_mux1(16*i+7 downto 16*i+4)  := data_fifo_dout(8*i+4 downto 8*i); -- Imag part, high nibble
				--     data_fifo_dout_mux1(16*i+3 downto 16*i)    := data_fifo_dout(32+8*i+4 downto 32+8*i); -- Imag part, low nibble
				--   end loop;

				--   -- Select the half
				--   if half='0' then
				--     data_fifo_dout_mux2 := data_fifo_dout_mux1(31 downto 0);
				--   else
				--     data_fifo_dout_mux2 := data_fifo_dout_mux1(63 downto 32);
				--   end if;
				-- end if;

				-- assign the output
				m_axis_tdata_int <= data_fifo_dout_mux2;
				m_axis_tvalid_int <= '1';
				m_axis_tlast_int <= '0';

				-- half <= '1'; -- 8-bit support
				-- if EIGHT_BIT_SUPPORT=FALSE or four_bits='0' or half='1' then -- We are finished sending halves if there is no half (4 bit mode) or we are on the last half.
				--   half <= '0';
				if data_fifo_dout(64) = '1' then -- if last data word of the packet, start sending scaler flags
					send_data <= '0';
					-- send_odd_data_flags <= '0';
					if send_flags = '1' and bypass_reg = '0' then
						send_data_flags <= '1';
					else
						send_packet_flags <= '1';
					end if;
				end if; -- if last word of packet
			-- end if; -- half
			end if;

			-----------
			-- SEND DATA FLAGS
			-----------
			-- Send the content of the scaler flags fifo
			if send_data_flags = '1' and data_flags_fifo_valid = '1' then
				m_axis_tdata_int(31 downto 0) <= data_flags_fifo_dout(31 downto 0);
				m_axis_tvalid_int <= '1';
				-- lane_errors <= lane_errors or data_flags_fifo_dout(31 downto 16); -- cumulate lane errors (missing data, etc.) to send later in the packet flags
				m_axis_tlast_int <= '0';  -- This is never the last word we send: there are still the frame flags coming

				if data_flags_fifo_dout(32) = '1' then -- if last word of the packet, start sending frame flags
					send_data_flags <= '0';
					send_frame_flags <= '1';
				end if;
			end if;

			-----------
			-- SEND FRAME FLAGS
			-----------
			-- Send the contents of the ADC flags FIFO
			if send_frame_flags = '1' and frame_flags_fifo_valid = '1' then
				m_axis_tdata_int <= frame_flags_fifo_dout(31 downto 0);
				m_axis_tvalid_int <= '1';
				m_axis_tlast_int <= '0';
				if frame_flags_fifo_dout(32) = '1' then --
					send_frame_flags <= '0';
					send_packet_flags <= '1';
				end if;
			end if;

			-----------
			-- SEND PACKET FLAGS (all zeros)
			-----------
			if send_packet_flags = '1' then
				m_axis_tdata_int(31 downto 0) <= (others => '0');
				-- m_axis_tdata_int(15 downto 0) <= lane_errors;
				m_axis_tvalid_int <= '1';
				m_axis_tlast_int <= '1'; -- this is the last word of the packet.
				send_packet_flags <= '0';
				send_header <= '1';
			end if;

			-----------
			-- SYNCHRONOUS RESET
			-----------
			-- Overrides **only** the variables that may have been set above and need to be reset
			--
			-- We do not implement the synchronus reset as a "if reset (..reset code..) else
			-- (...main code...) end if". because all signals not processed in the reset code would
			-- end up with a clock enable depending on the reset line in the main code. That is
			-- quite a heavy load.
			if reset_all = '1' then
				m_axis_tvalid_int <= '0'; -- needed
				header_word_ctr <= (others => '0');
				timestamp_ctr <= (others => '0');
				send_header <= '1';
				send_data <= '0';
				send_data_flags <= '0';
				send_frame_flags <= '0';
				send_packet_flags <= '0';
				send_strobe <= '0';
				s_axis_global_tfirst <= '1';
			end if; -- reset

		end if; -- clk
	end process;

end architecture impl;

