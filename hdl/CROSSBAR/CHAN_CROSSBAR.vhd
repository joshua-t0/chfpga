----------------------------------------------------------------------------------
-- Company: McGill University
-- Engineer: J.-F. Cliche
--
-- Create Date:    14:54:33 01/31/2012
-- Design Name: chFPGA PoC
-- Module Name:    CHAN_CROSSBAR - Behavioral
-- Project Name: CHIME
-- Target Devices: 7 Series
-- Tool versions: Vivado 2014.2

-- Description: Implement a channelizer elastic FIFO, frame aligner, lane
-- remapper and bin selector to select a number of frequency bins from all
-- channelizers and package the data in packets suitable for transmission over
-- the shuffle network.
--
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
use IEEE.std_logic_misc.ALL; -- for and_reduce, etc...
use IEEE.math_real.ALL; -- for ceil()

library UNISIM;
use UNISIM.VComponents.all;

use work.chFPGA_Package.all; -- Get all component definitions
use work.ip_package.all; -- Import definition of components used in this module

entity chan_crossbar is
	GENERIC (
		NUMBER_OF_INPUT_LANES: integer :=16; -- Number of input streams
		NUMBER_OF_OUTPUT_LANES: integer :=16; -- Number of output streams
		BINSEL_PBLOCK_MAP: integerArray; -- Inticates to which pblock each BINSEL belongs. This is used to correctly pipeline the data.
		EIGHT_BIT_SUPPORT: boolean:= FALSE --
		);
	PORT(

		-- Input stream from the channelizer (non-blocking)
		s_axis_tvalid: in slv(0 to NUMBER_OF_INPUT_LANES-1);
		s_axis_tdata: in slv32_array(0 to NUMBER_OF_INPUT_LANES-1);
		s_axis_tlast: in slv(0 to NUMBER_OF_INPUT_LANES-1);
		s_axis_tuser: in slv4_array(0 to NUMBER_OF_INPUT_LANES-1);
		-- s_axis_clk: in std_logic_vector(0 to NUMBER_OF_INPUT_LANES-1); -- clock from each channelizer

		-- Output stream to the shuffle module (non-blocking)
		m_axis_tvalid: out slv(0 to NUMBER_OF_OUTPUT_LANES-1);
		m_axis_tdata: out slv32_array(0 to NUMBER_OF_OUTPUT_LANES-1);
		m_axis_tlast: out slv(0 to NUMBER_OF_OUTPUT_LANES-1);

		lane_monitor: out std_logic;

		frame_clk_out: out std_logic;
		clk: in  std_logic; -- clocks all align, remap and bin selection and output bus logic.
		rst: in std_logic; -- reset, synchronous to clk

		-- Control interface (command and reply stream buses)
		ctrl_cmd_dat: in AXIS8_DAT_STRUCT;
		ctrl_cmd_rdy: out AXIS8_RDY_STRUCT;
		ctrl_rply_dat: out AXIS8_DAT_STRUCT;
		ctrl_rply_rdy: in AXIS8_RDY_STRUCT;
		ctrl_clk: in  std_logic;
		ctrl_rst : in  std_logic
		);

end chan_crossbar;

architecture Behavioral of chan_crossbar is

	attribute keep:string;
	-- attribute equivalent_register_removal: string;
	attribute async_reg: string;
	attribute shreg_extract: string;
	attribute dont_touch: string;

	constant NUMBER_OF_BINSEL_PBLOCKS: integer := max(BINSEL_PBLOCK_MAP) + 1;
	-- constant NUMBER_OF_BINSEL_PBLOCKS: integer := 4;

	signal ctrl_rst_reg: std_logic;
	signal ctrl_rst_reg2: std_logic_vector(0 to NUMBER_OF_BINSEL_PBLOCKS-1);
	signal rst_reg: std_logic;
	signal rst_reg2: std_logic;
	signal rst_reg3: std_logic;

	attribute dont_touch of ctrl_rst_reg2: signal is "true"; -- make sure the multiple copies of the reset register are not simplified away

	-- Internally routed command buses
	-- We have one bus for global control, and one bus for each bin selector.
	signal xbar_cmd_dat: AXIS8_DAT_STRUCT_ARRAY(NUMBER_OF_OUTPUT_LANES downto 0);
	signal xbar_cmd_rdy: AXIS8_RDY_STRUCT_ARRAY(NUMBER_OF_OUTPUT_LANES downto 0);
	signal xbar_rply_dat: AXIS8_DAT_STRUCT_ARRAY(NUMBER_OF_OUTPUT_LANES downto 0);
	signal xbar_rply_rdy: AXIS8_RDY_STRUCT_ARRAY(NUMBER_OF_OUTPUT_LANES downto 0);


	-- Internal AXI-Streaming buses

	-- signal m_axis_fifo_tvalid: slv(0 to NUMBER_OF_INPUT_LANES-1);
	-- signal m_axis_fifo_tdata: slv32_array(0 to NUMBER_OF_INPUT_LANES-1);
	-- signal m_axis_fifo_tlast: slv(0 to NUMBER_OF_INPUT_LANES-1);
	-- signal m_axis_fifo_tuser: slv4_array(0 to NUMBER_OF_INPUT_LANES-1);
	-- signal m_axis_fifo_tready: slv(0 to NUMBER_OF_INPUT_LANES-1);
	signal frame_clk:slv (0 to NUMBER_OF_INPUT_LANES-1);

	signal m_axis_align_out_tvalid: slv(0 to NUMBER_OF_INPUT_LANES-1);
	signal m_axis_align_out_tdata: slv32_array(0 to NUMBER_OF_INPUT_LANES-1);
	signal m_axis_align_out_tlast: slv(0 to NUMBER_OF_INPUT_LANES-1);
	signal m_axis_align_out_tuser: slv4_array(0 to NUMBER_OF_INPUT_LANES-1);
	signal m_axis_align_out_global_tvalid: std_logic;
	signal m_axis_align_out_global_tlast: std_logic;



	signal m_axis_align_out_tvalid_reg: slv(0 to NUMBER_OF_INPUT_LANES-1);
	signal m_axis_align_out_tdata_reg: slv32_array(0 to NUMBER_OF_INPUT_LANES-1);
	signal m_axis_align_out_tlast_reg: slv(0 to NUMBER_OF_INPUT_LANES-1);
	signal m_axis_align_out_tuser_reg: slv4_array(0 to NUMBER_OF_INPUT_LANES-1);
	signal m_axis_align_out_global_tvalid_reg: std_logic;
	signal m_axis_align_out_global_tlast_reg: std_logic;

	-- signal m_axis_align_out_tvalid_reg: align_tvalid_array(0 to NUMBER_OF_BINSEL_PBLOCKS-1);
	-- signal m_axis_align_out_tdata_reg: align_tdata_array(0 to NUMBER_OF_BINSEL_PBLOCKS-1);
	-- signal m_axis_align_out_tlast_reg: align_tlast_array(0 to NUMBER_OF_BINSEL_PBLOCKS-1);
	-- signal m_axis_align_out_tuser_reg: align_tuser_array(0 to NUMBER_OF_BINSEL_PBLOCKS-1);
	-- signal m_axis_align_out_global_tvalid_reg: std_logic_vector(0 to NUMBER_OF_BINSEL_PBLOCKS-1);
	-- signal m_axis_align_out_global_tlast_reg: std_logic_vector(0 to NUMBER_OF_BINSEL_PBLOCKS-1);

	type align_tvalid_array is array (NATURAL RANGE <>) of slv(0 to NUMBER_OF_INPUT_LANES-1);
	type align_tdata_array is array (NATURAL RANGE <>) of slv32_array(0 to NUMBER_OF_INPUT_LANES-1);
	type align_tlast_array is array (NATURAL RANGE <>) of slv(0 to NUMBER_OF_INPUT_LANES-1);
	type align_tuser_array is array (NATURAL RANGE <>) of slv4_array(0 to NUMBER_OF_INPUT_LANES-1);

	signal m_axis_align_out_tvalid_reg2: align_tvalid_array(0 to NUMBER_OF_BINSEL_PBLOCKS-1);
	signal m_axis_align_out_tdata_reg2: align_tdata_array(0 to NUMBER_OF_BINSEL_PBLOCKS-1);
	signal m_axis_align_out_tlast_reg2: align_tlast_array(0 to NUMBER_OF_BINSEL_PBLOCKS-1);
	signal m_axis_align_out_tuser_reg2: align_tuser_array(0 to NUMBER_OF_BINSEL_PBLOCKS-1);
	signal m_axis_align_out_global_tvalid_reg2: std_logic_vector(0 to NUMBER_OF_BINSEL_PBLOCKS-1);
	signal m_axis_align_out_global_tlast_reg2: std_logic_vector(0 to NUMBER_OF_BINSEL_PBLOCKS-1);

	-- The m_axis_align_out_*_reg2 signals hold multiple copies of the align output. Each copy can be therefore placed closer to its destination pblock.
	-- These registers are equivalent, so we do not want the synthesized to merge them all into one.
	attribute dont_touch of m_axis_align_out_tvalid_reg2: signal is "true"; --
	attribute dont_touch of m_axis_align_out_tdata_reg2: signal is "true"; --
	attribute dont_touch of m_axis_align_out_tlast_reg2: signal is "true"; --
	attribute dont_touch of m_axis_align_out_tuser_reg2: signal is "true"; --
	attribute dont_touch of m_axis_align_out_global_tvalid_reg2: signal is "true"; --
	attribute dont_touch of m_axis_align_out_global_tlast_reg2: signal is "true"; --

	-- attribute shreg_extract of m_axis_align_out_tvalid_reg2: signal is "no"; -- preserve clock net name to facilitate timing constraining and analysis
	-- attribute shreg_extract of m_axis_align_out_tdata_reg2: signal is "no"; -- preserve clock net name to facilitate timing constraining and analysis
	-- -- attribute shreg_extract of m_axis_align_out_tlast_reg2: signal is "no"; -- this signal us not used by chan_bin_sel. Allow it to be removed.
	-- attribute shreg_extract of m_axis_align_out_tuser_reg2: signal is "no"; -- preserve clock net name to facilitate timing constraining and analysis

	-- attribute shreg_extract of m_axis_align_out_global_tvalid_reg2: signal is "no"; -- preserve clock net name to facilitate timing constraining and analysis
	-- attribute shreg_extract of m_axis_align_out_global_tlast_reg2: signal is "no"; -- preserve clock net name to facilitate timing constraining and analysis

	-- signal m_axis_align_out_tvalid_reg3: align_tvalid_array(0 to NUMBER_OF_OUTPUT_LANES/4-1);
	-- signal m_axis_align_out_tdata_reg3: align_tdata_array(0 to NUMBER_OF_OUTPUT_LANES/4-1);
	-- signal m_axis_align_out_tlast_reg3: align_tlast_array(0 to NUMBER_OF_OUTPUT_LANES/4-1);
	-- signal m_axis_align_out_tuser_reg3: align_tuser_array(0 to NUMBER_OF_OUTPUT_LANES/4-1);
	-- signal m_axis_align_out_global_tvalid_reg3: std_logic_vector(0 to NUMBER_OF_OUTPUT_LANES/4-1);
	-- signal m_axis_align_out_global_tlast_reg3: std_logic_vector(0 to NUMBER_OF_OUTPUT_LANES/4-1);

	-- attribute dont_touch of m_axis_align_out_global_tvalid_reg3: signal is "yes"; -- preserve clock net name to facilitate timing constraining and analysis
	-- attribute dont_touch of m_axis_align_out_global_tlast_reg3: signal is "yes"; -- preserve clock net name to facilitate timing constraining and analysis
	-- attribute dont_touch of m_axis_align_out_tvalid_reg3: signal is "yes"; -- preserve clock net name to facilitate timing constraining and analysis
	-- attribute dont_touch of m_axis_align_out_tdata_reg3: signal is "yes"; -- preserve clock net name to facilitate timing constraining and analysis
	-- -- attribute dont_touch of m_axis_align_out_tlast_reg3: signal is "yes"; -- this signal us not used by chan_bin_sel. Allow it to be removed.
	-- attribute dont_touch of m_axis_align_out_tuser_reg3: signal is "yes"; -- preserve clock net name to facilitate timing constraining and analysis

	signal m_axis_tvalid_int: slv(0 to NUMBER_OF_OUTPUT_LANES-1);

	signal align_reset: std_logic;
	signal align_reset_all: std_logic;
	signal reset_stats: std_logic;
	signal align_lane_monitor: slv(0 to NUMBER_OF_INPUT_LANES-1);

	-- signal fifo_reset: std_logic;
	-- signal fifo_reset_all: std_logic;
	-- signal lane_monitor:  std_logic_vector(0 to NUMBER_OF_INPUT_LANES-1);
	signal lane_monitor_reset: std_logic;
	signal lane_monitor_sel: std_logic_vector(3 downto 0);
	signal lane_monitor_source: std_logic_vector(3 downto 0);

	signal delay_capture_ref_word_ctr: unsigned(15 downto 0);
	signal delay_capture_ref_word_ctr_en: std_logic;

	signal input_frame_ctr: slv8_array(0 to NUMBER_OF_INPUT_LANES-1);
	signal align_frame_ctr: slv8_array(0 to NUMBER_OF_INPUT_LANES-1);
	signal align_global_frame_ctr: unsigned(7 downto 0);

	-- signal sof_window_start: std_logic_vector(7 downto 0);
	-- signal sof_window_stop: std_logic_vector(7 downto 0);

	-- signal align_fifo_overflow: std_logic_vector(0 to NUMBER_OF_INPUT_LANES-1);
	signal align_fifo_overflow_sticky: std_logic_vector(0 to NUMBER_OF_INPUT_LANES-1);
	-- signal missing_frame: std_logic_vector(0 to NUMBER_OF_INPUT_LANES-1);
	-- signal missing_frame_sticky: std_logic_vector(0 to NUMBER_OF_INPUT_LANES-1);

	signal delay_capture_word_ctr: u16_array(0 to 3);
	signal delay_capture_word_ctr_en: std_logic_vector(0 to 3);

	-- signal bin_ctr : unsigned(9 downto 0); -- Up to 1024 bins per frame
	-- signal lane_map: slv4_array(0 to NUMBER_OF_INPUT_LANES-1);
	--- Define Control word and its signals
	signal control_bytes: slv8_array(0 to 1); -- default value set in the CMD_SLAVE
	signal status_bytes: slv8_array(0 to 4); --

--attribute keep_hierarchy : string;
--attribute keep_hierarchy of binsel_i : label is "yes";

begin


ctrl_rst_proc: process(ctrl_clk)
	begin
		if rising_edge(ctrl_clk) then
			ctrl_rst_reg <= ctrl_rst;
			ctrl_rst_reg2 <= (others => ctrl_rst_reg);
		end if; -- RST/CLK
	end process;

rst_proc: process(clk)
	begin
		if rising_edge(clk) then
			rst_reg <= rst;
			rst_reg2 <= rst_reg;
			rst_reg3 <= rst_reg2;
		end if; -- RST/CLK
	end process;

---------------------------------------------------------------------
--! ROUTER
---------------------------------------------------------------------
--! Routes the commands and replies to/from the crossbar subsystems

crossbar_router0: entity work.CTRL_ROUTER
	GENERIC MAP (
		NUMBER_OF_PORTS => NUMBER_OF_OUTPUT_LANES+1,
		ADDRESS_MASK => "----11111-----------" --'1': used to generate port index, '-' = don't care,
	)
	PORT MAP(
		-- Master control interface
		CMD_IN_DAT   => ctrl_cmd_dat,
		CMD_IN_RDY   => ctrl_cmd_rdy,
		RPLY_OUT_DAT => ctrl_rply_dat,
		RPLY_OUT_RDY => ctrl_rply_rdy,


		CMD_OUT_DAT=> xbar_cmd_dat,
		CMD_OUT_RDY=> xbar_cmd_rdy,
		RPLY_IN_DAT=> xbar_rply_dat,
		RPLY_IN_RDY=> xbar_rply_rdy,

		-- Slave (module) control interface
		CLK => ctrl_clk,
		RST => ctrl_rst_reg
	);



-----------------------------------------------------------------------------------
-- CONTROL and STATUS Bytes
-----------------------------------------------------------------------------------
--! \addtogroup memory_map
--! CH_DIST Module
--! =============
--! ------------------------------------------------------------------------------
--! |  Page   | Addr|Bit(s)|     Name             | Description                   |
--! |---------|-----|------|----------------------|-------------------------------|
--! | CONTROL |  0  |   7  | USER_RESET               | Reset the CH_DIST and clears the FIFOs.|
--! |         |     |   6  | FOUR_BITS                | The input data is in 4-bit mode. The word streams will be combined 2-by-2 to pack 4 (4+4) bits samples in the output word|
--! |         |     |   5  | USE_OFFSET_BINARY        | Indicates if the data is encoded in offset_binary or 2's complement. This is not used by this module, but is passed in the header flags. It must be set consistently with the type of encoding of the source data.|
--! |         |     |   4  | SEND_FLAGS               | Indicates if we want the packets to contain scaler and adc flags.|
--! |         |     |   3  |                          | |
--! |         |     | 2-0  | (unused)                 |   |
--! |         | 1-2 | 15:0 | STREAM_ID                 | Stream ID to be used for tagging the output frames |
--! |         |  3  | 7:0  | number_of_selected_bins  | Indicates the number of words (frequency bin pairs) that are selected. This must match the number of '1' bits in the word selection map.|
--! |         |  4  | 2:0  | frames_per_packet        | Number of input frames to group into an output packet.|
--! |         |  5  | 7:5  |                          |  |
--! |         |     | 4:0  | number_of_input_lanes    | Number of input lanes from which data is gathered. Must be a multiple of 4. |
--! | STATUS  |  0  |   7  |           | EMPTY status flag of the DATA FIFO for antenna processor 0. Active HIGH. |
--! |         |     |   6  |        | Sticky flag indicating that one of the DATA FIFO has overflown. Cleared only by a reset of the module.|
--! |         |     | 5:0  | '0'                      | Unused   |
--! |         |  1  |  7:0 | FRAME_CTR                | Counts the number of frames written into the FIFOs. Rolls over.|
--! | RAM     | 0-63 | -   | MASK_RAM                 | Word selection map. Each of the 512 bit indicates whether the corresponding word (frequency bin pair) is retained by this correlator. |
--! ------------------------------------------------------------------------------
--!
--! ------------------------------------------------------------------------------------
--! | dual_bin | four_bits | Number of selected_bins                | Number of inputs |
--! |----------|-----------|----------------------------------------|------------------|
--! |    0     |     0     |                                        | Multiple of 2    |
--! |    0     |     1     |                                        | Multiple of 4    |
--! |    1     |     0     | Even, odd-even pair selected together  | Any              |
--! |    1     |     1     | Even, odd-even pair selected together  | Multiple of 2    |
--! ------------------------------------------------------------------------------------

--! CONTROL Byte 0
-- USER_RESET        <= control_bytes(0)(7); --! Used in both IN_CLK and OUT_CLK domain
-- FOUR_BITS         <= control_bytes(0)(6); --!
-- USE_OFFSET_BINARY <= control_bytes(0)(5); --!
-- SEND_FLAGS        <= control_bytes(0)(4);
-- dual_bin          <= control_bytes(0)(3);
--! CONTROL Bytes 1-8
-- lane_map_gen: for i in 0 to NUMBER_OF_INPUT_LANES-1 generate
-- 	lane_map(i) <= control_bytes(8-i/2)((i mod 2)*4+3 downto (i mod 2)*4);
-- end generate;

--! CONTROL Byte 0
-- fifo_reset                    <= control_bytes(0)(7); --!
align_reset                   <= control_bytes(0)(6); --!
-- remap_reset                   <= control_bytes(0)(5); --! There is no remap in 1st crossbar
lane_monitor_reset            <= control_bytes(0)(4); --!
lane_monitor_sel              <= control_bytes(0)(3 downto 0); --!

--! CONTROL Byte 1
lane_monitor_source <= control_bytes(1)(3 downto 0);

--! CONTROL Byte 2
-- sof_window_stop <= control_bytes(2);



-- --! STATUS Byte 0-1
-- with to_integer(unsigned(lane_monitor_sel)) select lane_monitor <=
-- 	(others=> rst_reg)         when 0,
-- 	-- missing_frame              when 3,
-- 	-- missing_frame_sticky       when 4,
-- 	-- align_fifo_overflow        when 5,
-- 	align_fifo_overflow_sticky when 6,
-- 	(others=>'0')              when others;

--! STATUS Byte 0
status_bytes(0)(7 downto 2) <= (others=>'0');
status_bytes(0)(1) <= align_fifo_overflow_sticky(to_integer(unsigned(lane_monitor_sel)));
status_bytes(0)(0) <= rst_reg;

--! STATUS Byte 1
status_bytes(1) <= input_frame_ctr(to_integer(unsigned(lane_monitor_sel)));

--! STATUS Byte 2
status_bytes(2) <= align_frame_ctr(to_integer(unsigned(lane_monitor_sel)));
status_bytes(3 to 4) <= to_slv8_array(delay_capture_ref_word_ctr);

-- status_bytes(0 to 1) <= to_slv8_array(resize(reverse_bits_and_dir(lane_monitor), 16));
-- status_bytes(2) <= to_slv(lsb(bin_ctr, 8));
--! STATUS Byte 2
-- none


--! STATUS Byte 5

-- status_bytes(5) <= align_frame_ctr(0); -- this is redundant: remove!


-----------------------------------------------------------------------------------
-- Memory-Mapped interface instantiation
-----------------------------------------------------------------------------------
--! Instantiates a memory-mapped interface to the control and status bytes
CTRL_SLAVE0: entity work.CTRL_SLAVE
	GENERIC MAP (
		NUMBER_OF_CONTROL_BYTES=>control_bytes'Length(1), --
		NUMBER_OF_STATUS_BYTES=>status_bytes'Length(1), --
		DEFAULT_CONTROL_BYTES=> X"00_04_08",
		USE_FIFO => FALSE
 	)

	PORT MAP(
		-- Control interface (command and reply stream buses)
		CTRL_CMD_IN_DAT => xbar_cmd_dat(0),
		CTRL_CMD_IN_RDY => xbar_cmd_rdy(0),
		CTRL_RPLY_OUT_DAT => xbar_rply_dat(0),
		CTRL_RPLY_OUT_RDY => xbar_rply_rdy(0),
		CTRL_CLK => CTRL_CLK,
		CTRL_RST => ctrl_rst_reg,

		control_bytes => control_bytes,
		status_bytes => status_bytes,
		CLK => clk,
		RST => rst_reg
	);


-- frame_clk_out <= frame_clk(0);
frame_clk_out <= s_axis_tvalid(0) and s_axis_tlast(0);


---------------------------------------------------------------------
--! ALIGN
---------------------------------------------------------------------
--! Control the Channelizer FIFO readout in  order to align the frames.
--! Aligning the frames is necessary because we need to grab data from multiple lanes at a time based on a single selection map.
--!
--! The align module also handles missing and malformed frames, but this is not an issue here since
--! data is coming straight from the channelizer through the internal FPGA routing, which will not cause packet loss.
 --! The only exception to this are for channels that do not send data due to missing ADC cards, inwhich case the ALIGN will handle those automatically.

align_reset_all <= rst_reg or align_reset;
align0: entity work.CHAN_ALIGN
	generic map (
		NUMBER_OF_LANES => NUMBER_OF_INPUT_LANES
		-- DATA_TIMEOUT => 2
	)
	port map(
		-- Data from the channelizers outputs (AXI Streaming, blocking)
		s_axis_tvalid => s_axis_tvalid,
		s_axis_tdata  => s_axis_tdata,
		s_axis_tlast  => s_axis_tlast,
		s_axis_tuser  => s_axis_tuser,
		-- s_axis_tready => m_axis_fifo_tready,

		-- Data to the remapper (AXI Streaming, non-blocking)
		m_axis_tvalid => m_axis_align_out_tvalid,
		m_axis_tdata  => m_axis_align_out_tdata,
		m_axis_tlast  => m_axis_align_out_tlast,
		m_axis_tuser  => m_axis_align_out_tuser,

		m_axis_global_tvalid => m_axis_align_out_global_tvalid,
		m_axis_global_tlast  => m_axis_align_out_global_tlast,

		lane_monitor => align_lane_monitor,
		lane_monitor_source => lane_monitor_source,

		reset_stats   => reset_stats,
		overflow      => align_fifo_overflow_sticky,
		-- missing_frame => missing_frame_sticky,
		in_frame_ctr  => input_frame_ctr,
		out_frame_ctr => align_frame_ctr,


		clk => clk,
		rst => align_reset_all
		);

bin_ctr_proc: process(clk)
begin
	if rising_edge(clk) then

		reset_stats <= lane_monitor_reset or rst_reg;

		lane_monitor <= align_lane_monitor(to_integer(unsigned(lane_monitor_sel)));


		if rst_reg='1' or lane_monitor_reset='1' then
			delay_capture_ref_word_ctr <= (others=> '0');
			delay_capture_ref_word_ctr_en <= '1';
		else
			if delay_capture_ref_word_ctr_en = '1'  then
				delay_capture_ref_word_ctr <= delay_capture_ref_word_ctr + 1;
				if signed(delay_capture_ref_word_ctr)=-2 or align_lane_monitor(to_integer(unsigned(lane_monitor_sel)))='1' then
					delay_capture_ref_word_ctr_en <= '0';
				end if;
			end if;
		end if;

		-- Pipeline the output of the ALIGN module to facilitate timing since it goes to every BIN_SEL, which are spread over a large area
		-- We explicitely split the data bus in many branches because the signals physically go in different directions.
		-- This pipeline is necessary to generate a delay of two clocks between the bin counter controls (bin_ctr_*) and the data.
		-- The BIN_SEL requires the bin counter control to be in advance by two clocks relatve to compensate with the lookup RAM latency

		if rst_reg='1' then
			m_axis_align_out_tvalid_reg <= (others => '0');
		else
			m_axis_align_out_tvalid_reg <= m_axis_align_out_tvalid;
		end if;
		m_axis_align_out_tdata_reg <= m_axis_align_out_tdata;
		m_axis_align_out_tlast_reg <= m_axis_align_out_tlast;
		m_axis_align_out_tuser_reg <= m_axis_align_out_tuser;

		-- Another pipeline level.
		if rst_reg2='1' then
			m_axis_align_out_tvalid_reg2 <= (others => (others =>'0'));
		else
			m_axis_align_out_tvalid_reg2 <= (others=> m_axis_align_out_tvalid_reg);
		end if;
		m_axis_align_out_tdata_reg2 <= (others=> m_axis_align_out_tdata_reg);
		m_axis_align_out_tlast_reg2 <= (others=> m_axis_align_out_tlast_reg);
		m_axis_align_out_tuser_reg2 <= (others=> m_axis_align_out_tuser_reg);


		if rst_reg='1' then
			m_axis_align_out_global_tvalid_reg <= '0';
		else
			m_axis_align_out_global_tvalid_reg <= m_axis_align_out_global_tvalid;
		end if;
		m_axis_align_out_global_tlast_reg  <= m_axis_align_out_global_tlast;

		if rst_reg2='1' then
			m_axis_align_out_global_tvalid_reg2 <= (others=> '0');
		else
			m_axis_align_out_global_tvalid_reg2 <= (others=>m_axis_align_out_global_tvalid_reg);
		end if;
		m_axis_align_out_global_tlast_reg2  <= (others=>m_axis_align_out_global_tlast_reg);

	end if; -- clk
end process;



BIN_SEL_GEN: for i in 0 to NUMBER_OF_OUTPUT_LANES-1 generate
begin
	----------------------------------------
	--! Instantiate the bin selectors
	----------------------------------------
	m_axis_tvalid(i) <= m_axis_tvalid_int(i);
	binsel_i: entity work.chan_bin_sel
		GENERIC MAP (
			LANE_NUMBER => i,
			NUMBER_OF_INPUTS => NUMBER_OF_INPUT_LANES
			)
		PORT MAP(
			-- Input from remap (non blocking AXI-Streaming bus)
			s_axis_tdata         => m_axis_align_out_tdata_reg2(BINSEL_PBLOCK_MAP(i)),
			s_axis_tuser         => m_axis_align_out_tuser_reg2(BINSEL_PBLOCK_MAP(i)),
			s_axis_tvalid        => m_axis_align_out_tvalid_reg2(BINSEL_PBLOCK_MAP(i)),
			s_axis_tlast         => m_axis_align_out_tlast_reg2(BINSEL_PBLOCK_MAP(i)),
			s_axis_global_tvalid => m_axis_align_out_global_tvalid_reg2(BINSEL_PBLOCK_MAP(i)),
			s_axis_global_tlast  => m_axis_align_out_global_tlast_reg2(BINSEL_PBLOCK_MAP(i)),

			-- Bin counter signals: must be set two clocks before the data
			bin_ctr_en => m_axis_align_out_global_tvalid,
			bin_ctr_clr => m_axis_align_out_global_tlast,

			-- Output to the shuffle module (blocking AXI-Streaming bus)
			m_axis_tdata  => m_axis_tdata(i),
			m_axis_tvalid => m_axis_tvalid_int(i),
			m_axis_tlast  => m_axis_tlast(i),

			-- bin_number => std_logic_vector(bin_ctr), -- bin number (0 to 1023), appearing 1 clock before the corresponding data (to allow the RAM to lookup the selection bits, assuming the RAM has 1 clock latency)

			rst => rst_reg2,
			clk => clk, --! common clock for both the input and output

			-- Control Interface
			ctrl_cmd_dat  => xbar_cmd_dat(i+1),
			ctrl_cmd_rdy  => xbar_cmd_rdy(i+1),
			ctrl_rply_dat => xbar_rply_dat(i+1),
			ctrl_rply_rdy => xbar_rply_rdy(i+1),
			ctrl_clk      => CTRL_CLK,
			ctrl_rst      => ctrl_rst_reg2(BINSEL_PBLOCK_MAP(i))
		);
end generate;

end Behavioral;

