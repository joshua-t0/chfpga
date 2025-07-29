----------------------------------------------------------------------------------
-- Company: McGill University
-- Engineer: J.-F. Cliche
--
-- Create Date:    2025-01-31
-- Design Name:    chFPGA
-- Module Name:    bct
-- Project Name: CHIME, HIRAX, FRB Outriggers
-- Target Devices: Kintex 7
-- Tool versions: Vivado 2022.2

-- Description: Corner-turn engine typically used with IceBoards and backplanes.
-- Performs internal 16x16 corner-turn, and optional 16x16 intra-crate (16 boards) and intercrate (2 crates) corner turns.
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_misc.ALL; -- for and_reduce, etc...
use IEEE.math_real.ALL; -- for ceil()

library UNISIM;
use UNISIM.VComponents.ALL;

use work.chFPGA_Package.ALL;

-- Implement the corner turn operation
---    a) between channels in the same board
--     b) between boards in the same crate (optional)
--     c) between boards in two crates (optional)
--
-- The corner-turn engine is implemented using the following blocks
--
--    - CROSSBAR: channelizer crosbar a.k.a 1st crossbar
--    - CROSSBAR2: shuffle_crossbar
--    - bp_shuffle
--    - CROSSBAR3 shuffle_crossbar
entity bct_engine is
	generic (
		PLATFORM_ID: integer; -- necessary to select the proper FIFOs
		NUMBER_OF_INPUT_LANES: integer := 16; -- Number of channelizer inputs
		BINS_PER_INPUT_WORD: integer   := 2;
		INPUT_WORD_WIDTH: integer      := 32; -- width of the scaler output word

		-- Corner-turning level:
		-- - 1: single-board (local) only (no backplane),
		-- - 2: Option 1 plus 4x4 subbackplane corner-turn (4 boards, using GTY),
		-- - 3: Option 2 + additional 4x4 corner-turn between 2 or 4 sub-backplanes (8 or 16 boards)
		CT_LEVEL: integer := 2;

		-- List indicating the GTY link number associated to each lane. -1 means a bypass  lane (no GTY, stays internal to the board).
		LANE_TO_LINK_MAP: integer_array := ( -- Backplane PCB Lanes
											  0 => -1, -- Bypass lane
											  1 => 0, 2=> 1, 3 => 2, 4 => 3,  5 => 4,  6 => 5,  7 => 6, 8=> 7, 9=> 8, 10=> 9, 11=> 10, 12=> 11, 13=> 12, 14=> 13, 15=> 14,
		-- Backplane QUAD Lanes
											  16 to 19 => -1, -- Bypass lane
											  20 => 15, 21 => 16, 22 => 17, 23=> 18);
		LINK_TO_QUAD_MAP: integer_array   := (0 to 3 => 0, 4 to 7 => 1, 8 to 11=> 2, 12 to 14 => 3, 15 to 18=> 4); -- Indicates which quad is associated to each GTY link.
		QUAD_TO_REFCLK_MAP: integer_array := (0 => 1, 1 => 0, 2 => 0, 3=> 1, 4 => 1); -- Indicates which refclk is associated with each QUAD
		LANE_TO_GROUP_MAP: integer_array  := (0 to 15 => 0, 16 to 23 => 1); -- Indicates to which lane group each lane is associated with


		-- Derived parameters
		OUTPUT_LANE_WIDTH: integer           := 32;
		NUMBER_OF_OUTPUT_LANES: integer      := 8; -- Number of output streams
		OUTPUT_WIDTH: integer                := NUMBER_OF_OUTPUT_LANES * OUTPUT_LANE_WIDTH;  -- assumes inputs are 32 bits wide, and CT preserves data rate
		NUMBER_OF_LINKS: integer             := max(LANE_TO_LINK_MAP) + 1; --  Number of physical data links (GTYs) - Do not override
		NUMBER_OF_REFCLK: integer            := max(QUAD_TO_REFCLK_MAP) + 1; -- Number of reference clocks - Do not override
		NUMBER_OF_CROSSBAR1_OUTPUTS: integer := 16;
		BP_LINK_SPEED: integer               := 0 -- 0: 7.5 Gb/s (txclk_out=244 MHz), 1: 10 Gb/s (txclk_out=322 MHz)
	-- WORDS_PER_BIN_MAX: integer :=4; -- Maximum number of words that can be present in a bin on one input lane. The 2nd crossbar receives up to 4 words. The 3rd crossbar will can have up to 16 words.
	-- BINS_PER_FRAME_MAX: integer :=64; -- Maximum number of bins per frame
	-- BIN_SEL_FIFO_TYPE_MAP: integer_16xN_array := (0 to 15 => (0 to 3=>0, others=>0)); -- 0= Block RAM., 1=Dist RAM. By default, for every BIN_SEL, 10 FIFOS are made of BRAM and the rest is made of distributed RAM to maximize area utilization efficiency
	-- SHUFFLE_FLAGS_MASK: slv32 -- Mask to apply to the shuffle flags to count packet errors
	);
	port (
		-- Non-blocking input stream from the channelizer, synchronous to `clk`
		s_axis_tdata: in slv_array(0 to NUMBER_OF_INPUT_LANES - 1)(INPUT_WORD_WIDTH - 1 downto 0); -- data from each channelizer, each of which contains 4x (4+4)-bit bin values
		s_axis_tuser: in slv_array(0 to NUMBER_OF_INPUT_LANES - 1)(3 downto 0); -- data from each channelizer, each of which contains 4x (4+4)-bit bin values
		s_axis_tvalid: in std_logic;
		s_axis_tlast: in std_logic;

		-- Non-blocking output stream, synchronous to `clk`
		m_axis_tvalid: out std_logic;
		m_axis_tdata: out slv(OUTPUT_WIDTH - 1 downto 0);
		m_axis_tlast: out std_logic;

		--     m_axis_tvalid: out slv(0 to NUMBER_OF_OUTPUT_LANES-1);
		--     m_axis_tdata: out slv_array(0 to NUMBER_OF_OUTPUT_LANES-1);
		--     m_axis_tlast: out slv(0 to NUMBER_OF_OUTPUT_LANES-1);


		-- Backplane data shuffle

		tx_p: out std_logic_vector(0 to NUMBER_OF_LINKS - 1);
		tx_n: out std_logic_vector(0 to NUMBER_OF_LINKS - 1);
		rx_p: in std_logic_vector(0 to NUMBER_OF_LINKS - 1);
		rx_n: in std_logic_vector(0 to NUMBER_OF_LINKS - 1);
		refclk_p: in std_logic_vector(0 to NUMBER_OF_REFCLK - 1); -- 156.250 clock
		refclk_n: in std_logic_vector(0 to NUMBER_OF_REFCLK - 1);

		refclk_div2: out std_logic_vector(0 to NUMBER_OF_REFCLK - 1);
		txclk_div2: out std_logic; -- divided-by-two version of the TX word clock, which is also clk_out

		txclk_out: out std_logic; -- Word clock from the GTY TX link
		-- frame_clk_in: in std_logic;
		clk: in  std_logic; -- AXI-S bus clocks. Tie to clk_out if the backplane links are enabled
		rst: in std_logic;

		align_pulse: out std_logic;

		-- Control interface (command and reply stream buses)
		bsb_cmd_dat: in AXIS8_DAT_STRUCT;
		bsb_cmd_rdy: out AXIS8_RDY_STRUCT;
		bsb_rply_dat: out AXIS8_DAT_STRUCT;
		bsb_rply_rdy: in AXIS8_RDY_STRUCT;
		bsb_clk: in  std_logic;
		bsb_rst: in  std_logic
	);
end entity bct_engine;

architecture impl of bct_engine is

	-- Attribute definitions

	attribute KEEP: string;
	attribute EQUIVALENT_REGISTER_REMOVAL: string;
	attribute ASYNC_REG: string;
	attribute SHREG_EXTRACT: string;
	attribute DONT_TOUCH: string;


	constant NUMBER_OF_BP_PCB_SHUFFLE_LANES: integer := count(LANE_TO_GROUP_MAP, 0);
	constant NUMBER_OF_BP_QSFP_SHUFFLE_LANES: integer := count(LANE_TO_GROUP_MAP, 1);
	constant NUMBER_OF_LANES: integer := NUMBER_OF_BP_PCB_SHUFFLE_LANES + NUMBER_OF_BP_QSFP_SHUFFLE_LANES;
	constant NUMBER_OF_GPU_LINKS: integer := NUMBER_OF_BP_QSFP_SHUFFLE_LANES;
	constant NUMBER_OUF_OUT_LANES: integer := NUMBER_OF_GPU_LINKS;

	constant BSB_CROSSBAR1_PORT: integer := 0; -- Top-level address of the CT-Engine 1st crossbar.
	constant BSB_CROSSBAR2_PORT: integer := 1; -- Top-level address of the CT-Engine 2nd crossbar
	constant BSB_CROSSBAR3_PORT: integer := 2; -- Top level address of the CT-Engine 3rd crossbar
	constant BSB_BP_SHUFFLE_PORT: integer := 3; -- Top level address of the CT-Engine backplane shuffle subsystem.
	constant BSB_ROUTER_PORTS: integer := 4; -- Total number of router output ports.

	-- constant NUMBER_OF_BIN_SEL: integer := NUMBER_OF_OUTPUT_LANES/NUMBER_OF_OUTPUT_LANES_PER_BIN_SEL;

	signal bsb_rst_reg: std_logic;
	signal rst_reg: std_logic;

	-- Routed BSB buses for each device
	signal bsb_router_cmd_dat: AXIS8_DAT_STRUCT_ARRAY(0 to BSB_ROUTER_PORTS - 1);
	signal bsb_router_cmd_rdy: AXIS8_RDY_STRUCT_ARRAY(0 to BSB_ROUTER_PORTS - 1);
	signal bsb_router_rply_dat: AXIS8_DAT_STRUCT_ARRAY(0 to BSB_ROUTER_PORTS - 1);
	signal bsb_router_rply_rdy: AXIS8_RDY_STRUCT_ARRAY(0 to BSB_ROUTER_PORTS - 1);


	signal cb1_out_tdata: slv32_array(0 to NUMBER_OF_INPUT_LANES - 1);
	signal cb1_out_tvalid: std_logic_vector(0 to NUMBER_OF_INPUT_LANES - 1);
	signal cb1_out_tlast: std_logic_vector(0 to NUMBER_OF_INPUT_LANES - 1);
	signal cb1_out_rst: std_logic;
	signal cb2_out_rst: std_logic;
	signal bp_shuffle_out_rst: std_logic;


	signal bp_shuffle_out_tdata: slv32_array(0 to NUMBER_OF_LANES - 1);
	signal bp_shuffle_out_tvalid: slv(0 to NUMBER_OF_LANES - 1);
	signal bp_shuffle_out_tlast: slv(0 to NUMBER_OF_LANES - 1);
	--    signal bp_shuffle_out_tdata64: slv64_array(0 to NUMBER_OF_LANES-1);
	-- signal bp_shuffle_out_tuser: slv4_array(0 to NUMBER_OF_LANES-1);
	-- signal bp_shuffle_out_tready: slv(0 to NUMBER_OF_LANES-1);
	-- signal axis_bp_shuffle_out_clk: slv(0 to NUMBER_OF_LANES-1);


	-- unused ?
	signal s_axis_tfirst: slv(0 to NUMBER_OF_INPUT_LANES - 1);

	signal m_axis_tvalid_int: slv(0 to NUMBER_OF_OUTPUT_LANES - 1);
	signal m_axis_tdata_int: slv32_array(0 to NUMBER_OF_OUTPUT_LANES - 1);
	signal m_axis_tlast_int: slv(0 to NUMBER_OF_OUTPUT_LANES - 1);
	signal m_axis_terror_int: slv(0 to NUMBER_OF_OUTPUT_LANES - 1);

	-- Internal AXI-Streaming buses

	signal m_axis_fifo_tvalid: slv(0 to NUMBER_OF_INPUT_LANES - 1);
	signal m_axis_fifo_tdata: slv32_array(0 to NUMBER_OF_INPUT_LANES - 1);
	signal m_axis_fifo_tlast: slv(0 to NUMBER_OF_INPUT_LANES - 1);
	signal m_axis_fifo_tuser: slv4_array(0 to NUMBER_OF_INPUT_LANES - 1);
	signal m_axis_fifo_tready: slv(0 to NUMBER_OF_INPUT_LANES - 1);
	-- signal frame_clk:slv (0 to NUMBER_OF_INPUT_LANES-1);

	signal m_axis_align_tvalid: slv(0 to NUMBER_OF_INPUT_LANES - 1);
	signal m_axis_align_tdata: slv32_array(0 to NUMBER_OF_INPUT_LANES - 1);
	signal m_axis_align_tlast: slv(0 to NUMBER_OF_INPUT_LANES - 1);
	signal m_axis_align_tuser: slv4_array(0 to NUMBER_OF_INPUT_LANES - 1);
	signal m_axis_align_global_tvalid: std_logic;
	signal m_axis_align_global_tlast: std_logic;

	signal m_axis_remap_tvalid: slv(0 to NUMBER_OF_INPUT_LANES - 1);
	signal m_axis_remap_tdata: slv32_array(0 to NUMBER_OF_INPUT_LANES - 1);
	signal m_axis_remap_tlast: slv(0 to NUMBER_OF_INPUT_LANES - 1);
	-- signal m_axis_remap_tuser: slv4_array(0 to NUMBER_OF_INPUT_LANES-1);
	signal m_axis_remap_global_tvalid: std_logic;
	signal m_axis_remap_global_tlast: std_logic;

	signal m_axis_remap_tvalid_reg: slv(0 to NUMBER_OF_INPUT_LANES - 1);
	signal m_axis_remap_tdata_reg: slv32_array(0 to NUMBER_OF_INPUT_LANES - 1);
	signal m_axis_remap_tlast_reg: slv(0 to NUMBER_OF_INPUT_LANES - 1);
	-- signal m_axis_remap_tuser_reg: slv4_array(0 to NUMBER_OF_INPUT_LANES-1);

	attribute shreg_extract of m_axis_remap_tvalid_reg: signal is "no";
	attribute shreg_extract of m_axis_remap_tdata_reg: signal is "no";
	attribute shreg_extract of m_axis_remap_tlast_reg: signal is "no";


	signal input_frame_ctr: u8_array(0 to NUMBER_OF_INPUT_LANES - 1);
	signal align_frame_ctr: u8_array(0 to NUMBER_OF_INPUT_LANES - 1);
	signal output_frame_ctr: u8_array(0 to NUMBER_OF_OUTPUT_LANES - 1);
	signal packet_error_ctr: u16_array(0 to NUMBER_OF_OUTPUT_LANES - 1);
	-- signal enable_fifo_frame_detection: std_logic;
	-- signal enable_align_frame_detection: std_logic;
	-- signal enable_remap_frame_detection: std_logic;
	-- signal enable_output_frame_detection: std_logic;

	signal lane_monitor: std_logic_vector(0 to NUMBER_OF_INPUT_LANES - 1);
	signal lane_monitor_sel: unsigned(3 downto 0);
	signal lane_monitor_reset: std_logic;
	signal input_frame_detection: std_logic_vector(0 to NUMBER_OF_INPUT_LANES - 1);
	-- signal fifo_frame_detection:  std_logic_vector(0 to NUMBER_OF_INPUT_LANES-1);
	signal align_frame_detection: std_logic_vector(0 to NUMBER_OF_INPUT_LANES - 1);
	signal remap_frame_detection: std_logic_vector(0 to NUMBER_OF_INPUT_LANES - 1);
	signal output_frame_detection: std_logic_vector(0 to NUMBER_OF_OUTPUT_LANES - 1);
	signal align_fifo_overflow: std_logic_vector(0 to NUMBER_OF_INPUT_LANES - 1);
	signal align_fifo_overflow_sticky: std_logic_vector(0 to NUMBER_OF_INPUT_LANES - 1);
	signal missing_frame: std_logic_vector(0 to NUMBER_OF_INPUT_LANES - 1);
	signal missing_frame_sticky: std_logic_vector(0 to NUMBER_OF_INPUT_LANES - 1);
	signal discarded_data: std_logic_vector(0 to NUMBER_OF_INPUT_LANES - 1);
	signal discarded_data_sticky: std_logic_vector(0 to NUMBER_OF_INPUT_LANES - 1);
	signal bad_lane_sticky: std_logic_vector(0 to NUMBER_OF_INPUT_LANES - 1);
	signal bad_eof_sticky: std_logic_vector(0 to NUMBER_OF_INPUT_LANES - 1);

	signal frame_clk_sel: std_logic;
	signal align_reset: std_logic;
	signal remap_reset: std_logic;
	signal clk_ctr: unsigned(7 downto 0);
	-- signal frame_clk_ctr: unsigned(7 downto 0);
	-- signal frame_clk_dly: std_logic;
	signal align_reset_all: std_logic;

	--- Define Control word and its signals
	-- signal CONTROL_BYTES: slv8_array(0 to (2 + (NUMBER_OF_INPUT_LANES+1)/2 + 2)); -- default value set in the CMD_SLAVE
	-- signal STATUS_BYTES: slv8_array(0 to 14);

	-- signal capture_word_ctr: unsigned(7 downto 0);
	-- signal capture_word_number: unsigned(7 downto 0);
	-- signal capture_word_ctr_en: std_logic;
	-- signal capture_done: std_logic;
	-- signal capture_tdata: slv32;
	-- signal capture_tvalid:std_logic;
	-- signal capture_tlast:std_logic;


	-- signal delay_capture_word_ctr: u16_array(0 to 1);
	-- signal delay_capture_word_ctr_en: std_logic_vector(0 to 1);
	signal delay_capture_word_ctr: unsigned(15 downto 0);
	signal delay_capture_word_ctr_en: std_logic;
	signal delay_capture_word_ctr_arm: std_logic;

	signal delay_capture_ref_word_ctr: unsigned(15 downto 0);
	signal delay_capture_ref_word_ctr_en: std_logic;


	signal control_bytes: slv8_array(0 to 0); -- default value set in the CMD_SLAVE
	signal status_bytes: slv8_array(0 to 2);

begin

	ctrl_rst_proc: process(all) begin
		bsb_rst_reg <= bsb_rst when rising_edge(bsb_clk);
	end process;

	-- Pipeline corner-turn reset
	process(all) begin
		rst_reg <= rst when rising_edge(clk);
	end process;

	---------------------------------------------------------------------
	-- ROUTER
	---------------------------------------------------------------------
	-- Routes the commands and replies to/from the crossbar subsystems

	bsb_router0: entity work.CTRL_ROUTER
		generic map (
			NUMBER_OF_PORTS => BSB_ROUTER_PORTS,
			ADDRESS_MASK    => "---11--------------" -- 4 ports max, 14-bit internal address range per port
		)
		port map (
			-- Master control interface
			cmd_in_dat   => bsb_cmd_dat,
			cmd_in_rdy   => bsb_cmd_rdy,
			rply_out_dat => bsb_rply_dat,
			rply_out_rdy => bsb_rply_rdy,


			cmd_out_dat => bsb_router_cmd_dat,
			cmd_out_rdy => bsb_router_cmd_rdy,
			rply_in_dat => bsb_router_rply_dat,
			rply_in_rdy => bsb_router_rply_rdy,

			clk => bsb_clk,
			rst => bsb_rst_reg
		);


	---------------------------------------------------------------------
	-- CHANNELIZER CROSSBAR
	---------------------------------------------------------------------

	crossbar0_gen: if CT_LEVEL = 1 generate
		constant IN_BITS_PER_BIN: integer  := INPUT_WORD_WIDTH / BINS_PER_INPUT_WORD; -- 32/2 = 16
		constant OUT_BITS_PER_BIN: integer := 4 + 4;
		constant CT1_OUTPUT_LANES: integer := NUMBER_OF_CROSSBAR1_OUTPUTS;
		constant CT1_LANE_WIDTH: integer   := OUT_BITS_PER_BIN * NUMBER_OF_INPUT_LANES; -- 8*16 = 128 bits/bin

		signal in_frame_ctr, out_frame_ctr: unsigned(7 downto 0);

		signal cb1_in_tdata: slv_array(0 to NUMBER_OF_INPUT_LANES - 1)(INPUT_WORD_WIDTH - 1 downto 0);
		signal cb1_in_tvalid: std_logic;
		signal cb1_in_tlast: std_logic;
		signal cb1_in_rst: std_logic;
		attribute shreg_extract of cb1_in_tdata, cb1_in_tvalid, cb1_in_tlast: signal is "no";
		attribute shreg_extract of cb1_in_rst: signal is "no";

		signal resetdone: std_logic;

	begin
		-- If we have CT_LEVEL=1, we perform a fixed wired internal corner-turn
		process(all)

			variable rchan, rbin: integer; -- reverse lane and bin numbers
			variable lsb: integer;

		begin
			if rising_edge(clk) then
				-- count CT1 input and output words
				in_frame_ctr  <= in_frame_ctr + 1 when s_axis_tvalid and s_axis_tlast;
				out_frame_ctr <= out_frame_ctr + 1 when m_axis_tvalid and m_axis_tlast;

				-- pipeline channelizer data
				-- This CT engine assumes that the channelizer data is aligned, i.e. all lanes share a common tvalid and tlast
				cb1_in_tdata  <= s_axis_tdata;
				cb1_in_tvalid <= s_axis_tvalid when not rst_reg else '0';
				cb1_in_tlast  <= s_axis_tlast;
				cb1_in_rst    <= rst_reg;

				-- Implement a hardwired CROSSBAR1.
				-- We take  the dana from NUMBER_OF_INPUT_LANES lanes, each word containing values from BINS_PER_INPUT_WORD different bins,
				-- and pack them in a single vector where data is grouped by bins (low bin on SB), each bin containing lanes (low lane on MSB),
				-- then each lane containing 4+4 bit real/Imag components (Re in MSB)
				for bin in 0 to BINS_PER_INPUT_WORD - 1 loop -- 0 to 3
					rbin := BINS_PER_INPUT_WORD - 1 - bin;

					for chan in 0 to NUMBER_OF_INPUT_LANES - 1 loop -- 0 to 7
					   rchan := NUMBER_OF_INPUT_LANES - 1 - chan; -- reverse input channel,  7 to 0
					   lsb := CT1_LANE_WIDTH * rbin + OUT_BITS_PER_BIN * rchan;
						m_axis_tdata(lsb + OUT_BITS_PER_BIN - 1 downto lsb) <= cb1_in_tdata(chan)(IN_BITS_PER_BIN * (rbin + 1) - 1 downto IN_BITS_PER_BIN * (rbin + 1) - OUT_BITS_PER_BIN);
					end loop;

				end loop;

				m_axis_tvalid <= cb1_in_tvalid when not cb1_in_rst else '0';
				m_axis_tlast <= cb1_in_tlast;
				resetdone <= not cb1_in_rst;
			end if; -- clk
		end process;

	else generate -- if CT_LEVEL >=2, we implement the three crossbars and BP_SHUFFLE

		signal cb1_in_rst: std_logic;

		signal cb1_in_tdata_reg1: slv_array(0 to NUMBER_OF_INPUT_LANES - 1)(INPUT_WORD_WIDTH - 1 downto 0);
		signal cb1_in_tuser_reg1: slv_array(0 to NUMBER_OF_INPUT_LANES - 1)(3 downto 0);
		signal cb1_in_tvalid_reg1: std_logic;
		signal cb1_in_tlast_reg1: std_logic;
		attribute shreg_extract of cb1_in_tdata_reg1, cb1_in_tuser_reg1, cb1_in_tvalid_reg1, cb1_in_tlast_reg1: signal is "no";

		signal cb1_in_tdata_reg2: slv_array(0 to NUMBER_OF_INPUT_LANES - 1)(INPUT_WORD_WIDTH - 1 downto 0);
		signal cb1_in_tuser_reg2: slv_array(0 to NUMBER_OF_INPUT_LANES - 1)(3 downto 0);
		signal cb1_in_tvalid_reg2: std_logic;
		signal cb1_in_tlast_reg2: std_logic;
		attribute shreg_extract of cb1_in_tdata_reg2, cb1_in_tuser_reg2, cb1_in_tvalid_reg2, cb1_in_tlast_reg2: signal is "no";

		signal cb1_in_tdata_reg3: slv32_array(0 to NUMBER_OF_INPUT_LANES - 1);
		signal cb1_in_tuser_reg3: slv4_array(0 to NUMBER_OF_INPUT_LANES - 1);
		signal cb1_in_tvalid_reg3: std_logic;
		signal cb1_in_tlast_reg3: std_logic;
		attribute shreg_extract of cb1_in_tdata_reg3, cb1_in_tuser_reg3, cb1_in_tvalid_reg3, cb1_in_tlast_reg3: signal is "no";

		signal cb1_bsb_rst: std_logic;
		signal cb1_in_rst_reg1, cb1_in_rst_reg2, cb1_in_rst_reg3: std_logic;
	begin

		bsb_rst_proc: process(all) begin
			if rising_edge(bsb_clk) then
				cb1_bsb_rst  <= bsb_rst;
			end if;
		end process;

		-- Pipeline and connect the channelizer output to the 1st crossbar inputs.
		-- The pipelining is there to help meeting timing closure, as we need to route long distance from the channelizer to the first crossbar
		cb1_pipe_proc: process(all) begin
			if rising_edge(clk) then
				-- Pipeline 1
				-- pipeline channelizer data
				-- This CT engine assumes that the channelizer data is aligned, i.e. all lanes share a common tvalid and tlast
				cb1_in_tdata_reg1 <= s_axis_tdata;
				cb1_in_tuser_reg1 <= s_axis_tuser;
				cb1_in_tvalid_reg1 <= s_axis_tvalid when not rst_reg else '0';
				cb1_in_tlast_reg1 <= s_axis_tlast;
				cb1_in_rst_reg1 <= rst_reg;

				-- Pipeline 2
				cb1_in_tdata_reg2 <= cb1_in_tdata_reg1;
				cb1_in_tuser_reg2 <= cb1_in_tuser_reg1;
				cb1_in_tvalid_reg2 <= cb1_in_tvalid_reg1 when not cb1_in_rst_reg1 else '0';
				cb1_in_tlast_reg2 <= cb1_in_tlast_reg1;
				cb1_in_rst_reg2 <= cb1_in_rst_reg1;

				-- Pipeline 3
				-- for now convert from slv_array to slv32_array until we fix this
				for i in 0 to NUMBER_OF_INPUT_LANES - 1 loop
					cb1_in_tdata_reg3(i) <= cb1_in_tdata_reg2(i);
					cb1_in_tuser_reg3(i) <= cb1_in_tuser_reg2(i);
				end loop;

				cb1_in_tvalid_reg3 <= cb1_in_tvalid_reg2 when not cb1_in_rst_reg2 else '0';
				cb1_in_tlast_reg3 <= cb1_in_tlast_reg2;
				cb1_in_rst_reg3 <= cb1_in_rst_reg2;

				cb1_out_rst <= cb1_in_rst_reg3;
			end if; -- clk
		end process cb1_pipe_proc;

		-- Instantiate the CHAN crossbar, which includes:

		chan_crossbar0: entity work.CHAN_CROSSBAR
			generic map (
				PLATFORM_ID            => PLATFORM_ID,  -- needed to select family-dependent FIFOs
				NUMBER_OF_INPUT_LANES  => NUMBER_OF_INPUT_LANES,
				NUMBER_OF_OUTPUT_LANES => NUMBER_OF_CROSSBAR1_OUTPUTS,
				BINSEL_PBLOCK_MAP      => (0 to 4 => 0, 5 to 8 => 1, 9 to 12 => 1, 13 to 15 => 0),
				EIGHT_BIT_SUPPORT      => FALSE
			)
			port map (
				-- Input stream from the channelizer (AXI4-streaming, non-blocking, on clk)
				s_axis_tuser  => cb1_in_tuser_reg3,
				s_axis_tvalid => (others => cb1_in_tvalid_reg3),
				s_axis_tdata  => cb1_in_tdata_reg3,
				s_axis_tlast  => (others => cb1_in_tlast_reg3),

				-- Output stream to the shuffle module (AXI4-streaming, non-blocking, on clk)
				m_axis_tdata  => cb1_out_tdata,
				m_axis_tvalid => cb1_out_tvalid,
				m_axis_tlast  => cb1_out_tlast,

				clk => clk,
				rst => cb1_in_rst_reg3,

				--            lane_monitor => debug2,

				-- Control interface (command and reply stream buses)
				ctrl_cmd_dat  => bsb_router_cmd_dat(BSB_CROSSBAR1_PORT),
				ctrl_cmd_rdy  => bsb_router_cmd_rdy(BSB_CROSSBAR1_PORT),
				ctrl_rply_dat => bsb_router_rply_dat(BSB_CROSSBAR1_PORT),
				ctrl_rply_rdy => bsb_router_rply_rdy(BSB_CROSSBAR1_PORT),
				ctrl_clk      => bsb_clk,
				ctrl_rst      => cb1_bsb_rst
			);


	end generate crossbar0_gen;

	---------------------------------------------------------------------
	-- BACKPLANE PCB and QSFP DATA LINKS
	---------------------------------------------------------------------
	-- Implements the GTX links to exchange the packetized data over to other boards on the backplane (over the backplane PCB links) or to boards on another crate (using the backplane QSFP links).

	bpshfgen: if CT_LEVEL >= 2 generate

		--   signal top_bp_shuffle_cmd_dat: AXIS8_DAT_STRUCT;
		--   signal top_bp_shuffle_cmd_rdy: AXIS8_RDY_STRUCT;
		--   signal top_bp_shuffle_rply_dat: AXIS8_DAT_STRUCT;
		--   signal top_bp_shuffle_rply_rdy: AXIS8_RDY_STRUCT;

		-- PCB and QSFP lanes are concatenated into a single vector to be handled by a single xlink_array module.

		-- signal axis_bp_shuffle_bypass: std_logic;

		signal axis_bp_shuffle_in_tdata: slv32_array(0 to NUMBER_OF_LANES - 1);
		signal axis_bp_shuffle_in_tdata64: slv64_array(0 to NUMBER_OF_LANES - 1);
		signal axis_bp_shuffle_in_tvalid: slv(0 to NUMBER_OF_LANES - 1);
		signal axis_bp_shuffle_in_tlast: slv(0 to NUMBER_OF_LANES - 1);
		-- signal axis_bp_shuffle_in_tready: slv(0 to NUMBER_OF_LANES-1);


		signal bp_shuffle_in_rst: std_logic_vector(0 to NUMBER_OF_BP_PCB_SHUFFLE_LANES + NUMBER_OF_BP_QSFP_SHUFFLE_LANES - 1);
		signal bp_shuffle_in_rst_reg: std_logic;
		attribute shreg_extract of bp_shuffle_in_rst_reg: signal is "no";

		signal bp_shuffle_bsb_rst: std_logic;
	begin
		-- Index the system control buses as a separate signal here , because the simulator will make errors if we index it directly on the instantiation
		--   top_bp_shuffle_cmd_dat             <= top_cmd_dat(BP_SHUFFLE_PORT);
		--   top_cmd_rdy(BP_SHUFFLE_PORT)  <= top_bp_shuffle_cmd_rdy;
		--   top_bp_shuffle_rply_rdy            <= top_rply_rdy(BP_SHUFFLE_PORT);
		--   top_rply_dat(BP_SHUFFLE_PORT) <= top_bp_shuffle_rply_dat;

		bsb_rst_proc: process(all) begin
			if rising_edge(bsb_clk) then
				bp_shuffle_bsb_rst  <= bsb_rst;
			end if;
		end process;

		-- Pipeline the channelizer crossbar output to the backplane PCB shuffle input
		bp_pcb_shuffle_in_pipe_proc: process(all) begin
			if rising_edge(clk) then
				bp_shuffle_in_rst <= (others => cb1_out_rst);
				bp_shuffle_in_rst_reg <= bp_shuffle_in_rst(0);
				bp_shuffle_out_rst <= bp_shuffle_in_rst_reg;

				for i in 0 to NUMBER_OF_LANES - 1 loop
					axis_bp_shuffle_in_tdata(i) <= cb1_out_tdata(i);
					axis_bp_shuffle_in_tvalid(i) <= cb1_out_tvalid(i) when not bp_shuffle_in_rst(i) else '0';
					axis_bp_shuffle_in_tlast(i) <= cb1_out_tlast(i);
				end loop;

			end if;
		end process;

		bp_shuffle0: entity work.xglink_array -- use component instantiation to delay binding in this if-generate block and prevent errors
			generic map (
				LINK_SPEED            => BP_LINK_SPEED, -- 0: 7.5 Gb/s (244 MHz word clock), 1: 10 Gb/s (322 MHz word clock)
				NUMBER_OF_LANES       => NUMBER_OF_LANES,
				NUMBER_OF_LANE_GROUPS => max(LANE_TO_GROUP_MAP) - 1,  -- should be +1?
				-- LANE_GROUP_MAP     => (0 to NUMBER_OF_BP_PCB_SHUFFLE_LANES-1 => 0, NUMBER_OF_BP_PCB_SHUFFLE_LANES to NUMBER_OF_BP_PCB_SHUFFLE_LANES + NUMBER_OF_BP_QSFP_SHUFFLE_LANES-1 => 1),
				LANE_GROUP_MAP     => integerarray(LANE_TO_GROUP_MAP), -- We cast to make sure the synthesizer can unambiguously determine the final type and infer the entity in case the entity file is not needed (if-generate is False) and not included in the project
				NUMBER_OF_LINKS    => NUMBER_OF_LINKS,
				LANE_TO_LINK_MAP   => integerarray(LANE_TO_LINK_MAP),
				NUMBER_OF_REFCLK   => NUMBER_OF_REFCLK,
				LANE_TO_QUAD_MAP   => integerarray(LINK_TO_QUAD_MAP), -- Indicates which quad is associated each channel. The QUAD number is an integer between 0 and N-1, where N is the total number of quads used.
				QUAD_TO_REFCLK_MAP => integerarray(QUAD_TO_REFCLK_MAP), -- Indicates which refclk is associated with each QUAD (N integers from 0 to NUMBER_OF_REFCLK-1).
				IMPLEMENT_RX       => TRUE,
				SIM                => FALSE
			)
			port map (
				tx_p     => tx_p,
				tx_n     => tx_n,
				rx_p     => rx_p,
				rx_n     => rx_n,
				refclk_p => refclk_p,
				refclk_n => refclk_n,

				-- TX user interface (AXI-Streaming, non-blocking, on clk_out)
				s_axis_tx_tdata  => axis_bp_shuffle_in_tdata,
				s_axis_tx_tvalid => axis_bp_shuffle_in_tvalid,
				s_axis_tx_tlast  => axis_bp_shuffle_in_tlast,

				-- RX user interface (AXI-Streaming, non-blocking, on clk_out)
				m_axis_rx_tdata  => bp_shuffle_out_tdata,
				m_axis_rx_tvalid => bp_shuffle_out_tvalid,
				m_axis_rx_tlast  => bp_shuffle_out_tlast,

				clk_out => txclk_out, -- 244 or 322 MHz clock generated by the backplane shuffle transmitter from the reference clock. Must be used to clock all the Tx (slave) interface data.  There is one single clock per array.
				areset  => bp_shuffle_in_rst_reg,

				-- Clock monitoring ports
				refclk_div2 => refclk_div2, -- divided-by-two version of the 156.25 MHz reference clock fed to the QUAD PLL
				txclk_div2  => txclk_div2, -- divided-by-two version of the TX word clock, which is also clk_out

				-- Debug signals
				lane_monitor => open,

				-- User bypass control line
				-- bypass      => axis_bp_shuffle_bypass,

				-- Control and reply streams
				cmd_dat  => bsb_router_cmd_dat(BSB_BP_SHUFFLE_PORT),
				cmd_rdy  => bsb_router_cmd_rdy(BSB_BP_SHUFFLE_PORT),
				rply_dat => bsb_router_rply_dat(BSB_BP_SHUFFLE_PORT),
				rply_rdy => bsb_router_rply_rdy(BSB_BP_SHUFFLE_PORT),
				ctrl_clk => bsb_clk,
				ctrl_rst => bp_shuffle_bsb_rst
			);

	end generate bpshfgen;

	---------------------------------------------------------------------
	-- CROSSBARS 2 & 3
	---------------------------------------------------------------------

	crossbar23_gen: if CT_LEVEL >= 2 generate


		signal cb2_in_reset: std_logic;
		signal cb2_in_reset_reg: std_logic;
		attribute shreg_extract of cb2_in_reset, cb2_in_reset_reg: signal is "no";

		signal cb2_in_tdata_reg: slv32_array(0 to NUMBER_OF_BP_PCB_SHUFFLE_LANES - 1);
		signal cb2_in_tvalid_reg: slv(0 to NUMBER_OF_BP_PCB_SHUFFLE_LANES - 1);
		signal cb2_in_tlast_reg: slv(0 to NUMBER_OF_BP_PCB_SHUFFLE_LANES - 1);
		attribute shreg_extract of cb2_in_tdata_reg, cb2_in_tvalid_reg, cb2_in_tlast_reg: signal is "no";

		signal cb2_in_tdata: slv32_array(0 to NUMBER_OF_BP_PCB_SHUFFLE_LANES - 1);
		signal cb2_in_tvalid: slv(0 to NUMBER_OF_BP_PCB_SHUFFLE_LANES - 1);
		signal cb2_in_tlast: slv(0 to NUMBER_OF_BP_PCB_SHUFFLE_LANES - 1);
		attribute shreg_extract of cb2_in_tdata, cb2_in_tvalid, cb2_in_tlast: signal is "no";

		signal cb2_out_tdata: slv32_array(0 to NUMBER_OF_BP_QSFP_SHUFFLE_LANES - 1);
		signal cb2_out_tvalid: slv(0 to NUMBER_OF_BP_QSFP_SHUFFLE_LANES - 1);
		signal cb2_out_tlast: slv(0 to NUMBER_OF_BP_QSFP_SHUFFLE_LANES - 1);
		attribute shreg_extract of cb2_out_tdata, cb2_out_tvalid, cb2_out_tlast: signal is "no";


		signal cb3_in_tdata: slv32_array(0 to NUMBER_OF_BP_QSFP_SHUFFLE_LANES - 1);
		signal cb3_in_tvalid: slv(0 to NUMBER_OF_BP_QSFP_SHUFFLE_LANES - 1);
		signal cb3_in_tlast: slv(0 to NUMBER_OF_BP_QSFP_SHUFFLE_LANES - 1);
		attribute shreg_extract of cb3_in_tdata, cb3_in_tvalid, cb3_in_tlast: signal is "no";


		signal cb3_out_tdata: slv32_array(0 to NUMBER_OF_GPU_LINKS - 1);
		signal cb3_out_tvalid: slv(0 to NUMBER_OF_GPU_LINKS - 1);
		signal cb3_out_tlast: slv(0 to NUMBER_OF_GPU_LINKS - 1);
		attribute shreg_extract of cb3_out_tdata, cb3_out_tvalid, cb3_out_tlast: signal is "no";

		-- signal cb2_out_tready: slv(0 to NUMBER_OF_GPU_LINKS-1);

		signal cb3_in_rst: std_logic;


		signal cb2_bsb_rst: std_logic;
		signal cb3_bsb_rst: std_logic;
		attribute shreg_extract of cb2_bsb_rst, cb3_bsb_rst: signal is "no";

		signal resetdone: std_logic;

	begin
		-- pipeline the bsb resets
		bsb_rst_proc: process(all) begin
			if rising_edge(bsb_clk) then
				cb2_bsb_rst  <= bsb_rst;
				cb3_bsb_rst  <= cb2_bsb_rst;
			end if;
		end process;

		-- Pipeline the backplane PCB shuffle output to the shuffle crossbar input
		crossbar2_in_pipe_proc: process(all) begin
			if rising_edge(clk) then
				cb2_in_reset <= bp_shuffle_out_rst;
				cb2_in_reset_reg <= cb2_in_reset;
				cb2_out_rst <= cb2_in_reset_reg;

				cb2_in_tdata  <= bp_shuffle_out_tdata(0 to NUMBER_OF_BP_PCB_SHUFFLE_LANES - 1);
				cb2_in_tvalid <= bp_shuffle_out_tvalid(0 to NUMBER_OF_BP_PCB_SHUFFLE_LANES - 1) when not bp_shuffle_out_rst else (others => '0');
				cb2_in_tlast  <= bp_shuffle_out_tlast(0 to NUMBER_OF_BP_PCB_SHUFFLE_LANES - 1);

				cb2_in_tdata_reg  <= cb2_in_tdata;
				cb2_in_tvalid_reg <= cb2_in_tvalid when not cb2_in_reset_reg else (others => '0');
				cb2_in_tlast_reg  <= cb2_in_tlast;

				-- Assign outputs
				for lane in 0 to NUMBER_OF_OUTPUT_LANES - 1 loop -- 0 to 7
					m_axis_tdata(OUTPUT_LANE_WIDTH * (lane + 1) - 1 downto OUTPUT_LANE_WIDTH * lane) <= cb3_out_tdata(lane);
				end loop;

				m_axis_tvalid <= cb3_out_tvalid(0) when not cb2_out_rst else '0';
				m_axis_tlast <= cb3_out_tlast(0);
				resetdone <= not cb2_out_rst;


			end if;
		end process;

		crossbar2: entity work.shuffle_crossbar -- use component instantiation to delay binding in if-generate block and prevent errors during elaboration
			generic map (
				PLATFORM_ID                        => PLATFORM_ID,  -- needed to select family-dependent FIFOs
				NUMBER_OF_INPUT_LANES              => NUMBER_OF_BP_PCB_SHUFFLE_LANES, -- Number of input streams
				NUMBER_OF_OUTPUT_LANES             => NUMBER_OF_BP_QSFP_SHUFFLE_LANES, -- Number of output streams
				NUMBER_OF_OUTPUT_LANES_PER_BIN_SEL => 4,
				WORDS_PER_BIN_MAX                  => 4,  -- 1st crossbar outputs data for 16 channels max = 4 words
				BINS_PER_FRAME_MAX                 => 128, -- need 128 bins in case i'm in 16
				COMBINE_DATA_FLAGS                 => TRUE,
				SHUFFLE_FLAGS_MASK                 => slv32'(X"00070000") -- count errors from crossbar 2 only
			)
			port map (
				-- Non-blocking AXI-Streaming input
				s_axis_tdata  => cb2_in_tdata_reg,
				s_axis_tvalid => cb2_in_tvalid_reg,
				s_axis_tlast  => cb2_in_tlast_reg,
				-- s_axis_tready => axis_bp_crossbar2_in_tready,

				-- Non-blocking AXI-Streaming output
				m_axis_tdata  => cb2_out_tdata,
				m_axis_tvalid => cb2_out_tvalid,
				m_axis_tlast  => cb2_out_tlast,
				-- m_axis_tready => cb2_out_tready,

				clk => clk,
				rst => cb2_in_reset,

				--       align_pulse => debug1,
				-- Control interface (command and reply stream buses)
				ctrl_cmd_dat  => bsb_router_cmd_dat(BSB_CROSSBAR2_PORT),
				ctrl_cmd_rdy  => bsb_router_cmd_rdy(BSB_CROSSBAR2_PORT),
				ctrl_rply_dat => bsb_router_rply_dat(BSB_CROSSBAR2_PORT),
				ctrl_rply_rdy => bsb_router_rply_rdy(BSB_CROSSBAR2_PORT),
				ctrl_clk      => bsb_clk,
				ctrl_rst      => cb2_bsb_rst
			);

		-- Pipeline the backplane PCB shuffle output to the shuffle crossbar input
		crossbar3_in_pipe_proc: process(all) begin
			if rising_edge(clk) then
				cb3_in_tdata  <= bp_shuffle_out_tdata(NUMBER_OF_BP_PCB_SHUFFLE_LANES to NUMBER_OF_LANES - 1); -- QSFP shuffle lanes are concatenated after PCB shuffle lanes
				cb3_in_tvalid <= bp_shuffle_out_tvalid(NUMBER_OF_BP_PCB_SHUFFLE_LANES to NUMBER_OF_LANES - 1) when not bp_shuffle_out_rst else (others => '0');
				cb3_in_tlast  <= bp_shuffle_out_tlast(NUMBER_OF_BP_PCB_SHUFFLE_LANES to NUMBER_OF_LANES - 1);
				cb3_in_rst <= bp_shuffle_out_rst;
			end if; -- clk
		end process;


		crossbar3: entity work.shuffle_crossbar -- use component instantiation to delay binding in if-generate block and prevent errors during elaboration
			generic map (
				PLATFORM_ID                        => PLATFORM_ID,  -- needed to select family-dependent FIFOs
				NUMBER_OF_INPUT_LANES              => NUMBER_OF_BP_QSFP_SHUFFLE_LANES, -- Number of input streams
				NUMBER_OF_OUTPUT_LANES             => NUMBER_OF_GPU_LINKS, -- Number of output streams
				NUMBER_OF_OUTPUT_LANES_PER_BIN_SEL => 1,
				COMBINE_DATA_FLAGS                 => FALSE,
				WORDS_PER_BIN_MAX                  => 16,
				BINS_PER_FRAME_MAX                 => 64,
				BIN_SEL_FIFO_TYPE_MAP              => integer_16xN_array'(0 to 15 => (0 to 1=>0, others=>0)),
				SHUFFLE_FLAGS_MASK                 => slv32'(X"70000700") -- Count errors from both crossbars. Use a qualified axpression to ensure type is known.

			)
			port map (
				-- Non-blocking AXI-Streaming input
				s_axis_tdata  => cb3_in_tdata,
				s_axis_tvalid => cb3_in_tvalid,
				s_axis_tlast  => cb3_in_tlast,
				-- s_axis_tready => axis_bp_crossbar2_in_tready,

				-- Non-blocking AXI-Streaming output
				m_axis_tdata  => cb3_out_tdata,
				m_axis_tvalid => cb3_out_tvalid,
				m_axis_tlast  => cb3_out_tlast,
				-- m_axis_tready => cb2_out_tready,

				clk => clk,
				rst => cb3_in_rst,

				-- Control interface (command and reply stream buses)
				ctrl_cmd_dat  => bsb_router_cmd_dat(BSB_CROSSBAR3_PORT),
				ctrl_cmd_rdy  => bsb_router_cmd_rdy(BSB_CROSSBAR3_PORT),
				ctrl_rply_dat => bsb_router_rply_dat(BSB_CROSSBAR3_PORT),
				ctrl_rply_rdy => bsb_router_rply_rdy(BSB_CROSSBAR3_PORT),
				ctrl_clk      => bsb_clk,
				ctrl_rst      => cb3_bsb_rst
			);

	end generate crossbar23_gen;

-- If there are no shuffle links, connect directly to the output of the 1st crossbar if there are aly lanes there
-- Note: There should be at least as many 1st crossbar outputs as the number of GPU lanes.
-- NOXBAR2_GEN: if not IMPLEMENT_CROSSBAR2_AND_CROSSBAR3 generate
--   cb2_out_tdata <= axis_crossbar1_out_tdata(0 to NUMBER_OF_GPU_LINKS-1);
--   cb2_out_tvalid <= axis_crossbar1_out_tvalid(0 to NUMBER_OF_GPU_LINKS-1);
--   cb2_out_tlast <= axis_crossbar1_out_tlast(0 to NUMBER_OF_GPU_LINKS-1);
--   -- axis_crossbar1_out_tready(0 to NUMBER_OF_GPU_LINKS-1) <= (others=>'1');
--   ct_clk <= CORR_CLK;
-- end generate;


end architecture impl;

