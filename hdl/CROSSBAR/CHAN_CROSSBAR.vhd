----------------------------------------------------------------------------------
-- Company: McGill University
-- Engineer: J.-F. Cliche
--
-- Create Date:    14:54:33 01/31/2012
-- Design Name: chFPGA PoC
-- Module Name:    CHAN_CROSSBAR - impl
-- Project Name: CHIME
-- Target Devices: 7 Series
-- Tool versions: Vivado 2014.2

-- Description: Implements a frame aligner and an array of bin selector to select a number of
-- frequency bins from all channelizers and package the data in packets suitable for transmission
-- over the shuffle network.
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
use UNISIM.VComponents.ALL;

use work.chFPGA_Package.ALL; -- Get all component definitions

entity chan_crossbar is
	generic (
		PLATFORM_ID: integer;
		NUMBER_OF_INPUT_LANES: integer  := 16; -- Number of input streams
		NUMBER_OF_OUTPUT_LANES: integer := 16; -- Number of output streams
		BINSEL_PBLOCK_MAP: integer_array -- Indicates to which pblock each BINSEL belongs. This is used to correctly pipeline the data.
	);
	port (
		-- Input stream from the channelizer (non-blocking)
		s_axis_tvalid: in std_logic;
		s_axis_tdata: in slv32_array(0 to NUMBER_OF_INPUT_LANES - 1);
		s_axis_tlast: in std_logic;
		s_axis_tuser: in slv4_array(0 to NUMBER_OF_INPUT_LANES - 1);
		-- s_axis_clk: in std_logic_vector(0 to NUMBER_OF_INPUT_LANES-1); -- clock from each channelizer

		-- Output stream to the shuffle module (non-blocking)
		m_axis_tvalid: out slv(0 to NUMBER_OF_OUTPUT_LANES - 1);
		m_axis_tdata: out slv32_array(0 to NUMBER_OF_OUTPUT_LANES - 1);
		m_axis_tlast: out slv(0 to NUMBER_OF_OUTPUT_LANES - 1);

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
		ctrl_rst: in  std_logic
	);
end entity chan_crossbar;

architecture impl of chan_crossbar is

	attribute KEEP: string;
	attribute ASYNC_REG: string;
	attribute SHREG_EXTRACT: string;
	attribute DONT_TOUCH: string;

	constant NUMBER_OF_BINSEL_PBLOCKS: integer := max(BINSEL_PBLOCK_MAP) + 1;
	-- constant NUMBER_OF_BINSEL_PBLOCKS: integer := 4;

	signal ctrl_rst_reg: std_logic;
	signal ctrl_rst_reg2: std_logic_vector(0 to NUMBER_OF_BINSEL_PBLOCKS - 1);
	signal rst_reg: std_logic;
	signal rst_reg2: std_logic;
	signal rst_reg3: std_logic;

	attribute dont_touch of ctrl_rst_reg2: signal is "true"; -- make sure the multiple copies of the reset register are not simplified away

	-- Internally routed BSB buses
	-- We have one port for global register, and one port for each bin selector.
	signal bsb_router_cmd_dat: AXIS8_DAT_STRUCT_ARRAY(NUMBER_OF_OUTPUT_LANES downto 0);
	signal bsb_router_cmd_rdy: AXIS8_RDY_STRUCT_ARRAY(NUMBER_OF_OUTPUT_LANES downto 0);
	signal bsb_router_rply_dat: AXIS8_DAT_STRUCT_ARRAY(NUMBER_OF_OUTPUT_LANES downto 0);
	signal bsb_router_rply_rdy: AXIS8_RDY_STRUCT_ARRAY(NUMBER_OF_OUTPUT_LANES downto 0);


	-- Internal AXI-Streaming buses

	signal frame_clk: slv(0 to NUMBER_OF_INPUT_LANES - 1);

	signal binsel_in_tvalid_reg: slv(0 to NUMBER_OF_INPUT_LANES - 1);
	signal binsel_in_tdata_reg: slv32_array(0 to NUMBER_OF_INPUT_LANES - 1);
	signal binsel_in_tlast_reg: slv(0 to NUMBER_OF_INPUT_LANES - 1);
	signal binsel_in_tuser_reg: slv4_array(0 to NUMBER_OF_INPUT_LANES - 1);
	signal binsel_in_global_tvalid_reg: std_logic;
	signal binsel_in_global_tlast_reg: std_logic;

	type align_tvalid_array is array (NATURAL RANGE <>) of slv(0 to NUMBER_OF_INPUT_LANES - 1);
	type align_tdata_array is array (NATURAL RANGE <>) of slv32_array(0 to NUMBER_OF_INPUT_LANES - 1);
	type align_tlast_array is array (NATURAL RANGE <>) of slv(0 to NUMBER_OF_INPUT_LANES - 1);
	type align_tuser_array is array (NATURAL RANGE <>) of slv4_array(0 to NUMBER_OF_INPUT_LANES - 1);

	signal binsel_in_tvalid_reg2: align_tvalid_array(0 to NUMBER_OF_BINSEL_PBLOCKS - 1);
	signal binsel_in_tdata_reg2: align_tdata_array(0 to NUMBER_OF_BINSEL_PBLOCKS - 1);
	signal binsel_in_tlast_reg2: align_tlast_array(0 to NUMBER_OF_BINSEL_PBLOCKS - 1);
	signal binsel_in_tuser_reg2: align_tuser_array(0 to NUMBER_OF_BINSEL_PBLOCKS - 1);
	signal binsel_in_global_tvalid_reg2: std_logic_vector(0 to NUMBER_OF_BINSEL_PBLOCKS - 1);
	signal binsel_in_global_tlast_reg2: std_logic_vector(0 to NUMBER_OF_BINSEL_PBLOCKS - 1);

	-- The align_out_*_reg2 signals hold multiple copies of the align output. Each copy can be therefore placed closer to its destination pblock.
	-- These registers are equivalent, so we do not want the synthesized to merge them all into one.
	attribute DONT_TOUCH of binsel_in_tvalid_reg2, binsel_in_tdata_reg2, binsel_in_tlast_reg2, binsel_in_tuser_reg2: signal is "yes";
	attribute DONT_TOUCH of binsel_in_global_tvalid_reg2, binsel_in_global_tlast_reg2: signal is "yes";


	signal align_reset: std_logic;
	signal align_reset_reg: std_logic;
	attribute shreg_extract of align_reset, align_reset_reg: signal is "no";


	signal align_reset_all: std_logic;
	signal reset_stats: std_logic;
	signal align_lane_monitor: slv(0 to max(NUMBER_OF_INPUT_LANES, 16) - 1);

	signal lane_monitor_reset: std_logic;
	signal lane_monitor_sel: std_logic_vector(3 downto 0);
	signal lane_monitor_source: std_logic_vector(3 downto 0);
	signal lane_monitor_bit: std_logic;
	signal lane_monitor_bit_ctr: unsigned(4 downto 0);

	signal delay_capture_ref_word_ctr: unsigned(15 downto 0);
	signal delay_capture_ref_word_ctr_en: std_logic;

	signal input_frame_ctr: slv8_array(0 to NUMBER_OF_INPUT_LANES - 1);
	signal align_frame_ctr: slv8_array(0 to NUMBER_OF_INPUT_LANES - 1);
	signal align_global_frame_ctr: unsigned(7 downto 0);

	signal align_fifo_overflow_sticky: std_logic_vector(0 to NUMBER_OF_INPUT_LANES - 1);

	signal delay_capture_word_ctr: u16_array(0 to 3);
	signal delay_capture_word_ctr_en: std_logic_vector(0 to 3);

	--- Define Control word and its signals
	signal control_bytes: slv8_array(0 to 1); -- default value set in the CMD_SLAVE
	signal status_bytes: slv8_array(0 to 4); --
begin

	process(all) begin
		if rising_edge(ctrl_clk) then
			-- Pipeline BSB resets
			ctrl_rst_reg <= ctrl_rst;
			ctrl_rst_reg2 <= (others => ctrl_rst_reg);
		end if; -- RST/CLK
	end process;

	process(all) begin
		if rising_edge(clk) then
			-- Pipeline data resets
			rst_reg <= rst;
			rst_reg2 <= rst_reg;
			rst_reg3 <= rst_reg2;
		end if; -- RST/CLK
	end process;

	---------------------------------------------------------------------
	-- ROUTER
	---------------------------------------------------------------------
	-- Routes the commands and replies to/from the crossbar subsystems

	crossbar_router0: entity work.CTRL_ROUTER
		generic map (
			NUMBER_OF_PORTS => NUMBER_OF_OUTPUT_LANES + 1,
			ADDRESS_MASK    => "---11111-----------" -- '1': used to generate port index, '-' = don't care,
		)
		port map (
			-- Master control interface
			cmd_in_dat   => ctrl_cmd_dat,
			cmd_in_rdy   => ctrl_cmd_rdy,
			rply_out_dat => ctrl_rply_dat,
			rply_out_rdy => ctrl_rply_rdy,


			cmd_out_dat => bsb_router_cmd_dat,
			cmd_out_rdy => bsb_router_cmd_rdy,
			rply_in_dat => bsb_router_rply_dat,
			rply_in_rdy => bsb_router_rply_rdy,

			-- Slave (module) control interface
			clk => ctrl_clk,
			rst => ctrl_rst_reg
		);


	-----------------------------------------------------------------------------------
	-- CONTROL and STATUS Bytes
	-----------------------------------------------------------------------------------
-- Memory Map
-- -----------------------------------------------------------------------------------
-- |  Page   | Addr|Bit(s)|     Name                 | Description                   |
-- |---------|-----|------|--------------------------|-------------------------------|
-- | CONTROL |  0  |   7  | (unused)                |                               |
-- |         |     |   6  | align_reset              | Manually resets the align module |
-- |         |     |   5  | (unused)                 |                               |
-- |         |     |   4  | lane_monitor_reset        | Resets the lane monitoring statistics |
-- |         |     | 3:0  | lane_monitor_sel         | Selects for which lane lane monitoring statistics are presented |
-- |         |  1  | 3:0  | lane_monitor_source      | Lane monitor source selection |
-- | STATUS  |  0  | 7:3  | lane_monitor_bit_ctr     | Lane monitor bit counter |
-- |         |     |   2  | lane_monitor_bit         | Lane monitor bit value |
-- |         |     |   1  | align_fifo_overflow_sticky | Align FIFO overflow sticky flag for selected lane |
-- |         |     |   0  | rst_reg                  | Reset register status |
-- |         |  1  | 7:0  | input_frame_ctr          | Input frame counter for selected lane |
-- |         |  2  | 7:0  | align_frame_ctr          | Align frame counter for selected lane |
-- |         | 3:4 |15:0  | delay_capture_ref_word_ctr | Delay capture reference word counter |
	-- | RAM     |0-63 |  -   | MASK_RAM                 | Word selection map. Each of the 512 bit indicates whether the corresponding word (frequency bin pair) is retained by this correlator. |
	-- ----------------------------------------------------------------------------------
	--
	-- ------------------------------------------------------------------------------------
	-- | dual_bin | four_bits | Number of selected_bins                | Number of inputs |
	-- |----------|-----------|----------------------------------------|------------------|
	-- |    0     |     0     |                                        | Multiple of 2    |
	-- |    0     |     1     |                                        | Multiple of 4    |
	-- |    1     |     0     | Even, odd-even pair selected together  | Any              |
	-- |    1     |     1     | Even, odd-even pair selected together  | Multiple of 2    |
	-- ------------------------------------------------------------------------------------

	-- CONTROL Byte 0
	-- fifo_reset                    <= control_bytes(0)(7); --
	align_reset                   <= control_bytes(0)(6); --
	-- remap_reset                   <= control_bytes(0)(5); -- There is no remap in 1st crossbar
	lane_monitor_reset            <= control_bytes(0)(4);          --
	lane_monitor_sel              <= control_bytes(0)(3 downto 0); --

	-- CONTROL Byte 1
	lane_monitor_source <= control_bytes(1)(3 downto 0);


	-- STATUS Byte 0
	status_bytes(0)(7 downto 3) <= slv(lane_monitor_bit_ctr);
	status_bytes(0)(2)          <= lane_monitor_bit;
	status_bytes(0)(1)          <= align_fifo_overflow_sticky(to_integer(unsigned(lane_monitor_sel)));
	status_bytes(0)(0)          <= rst_reg;

	-- STATUS Byte 1
	status_bytes(1) <= input_frame_ctr(to_integer(unsigned(lane_monitor_sel)));

	-- STATUS Byte 2
	status_bytes(2)      <= align_frame_ctr(to_integer(unsigned(lane_monitor_sel)));
	status_bytes(3 to 4) <= to_slv8_array(delay_capture_ref_word_ctr);

	-----------------------------------------------------------------------------------
	-- Memory-Mapped interface instantiation
	-----------------------------------------------------------------------------------
	-- Instantiates a memory-mapped interface to the control and status bytes
	bsb_regs0: entity work.CTRL_SLAVE
		generic map (
			NUMBER_OF_CONTROL_BYTES => control_bytes'Length(1), --
			NUMBER_OF_STATUS_BYTES  => status_bytes'Length(1), --
			DEFAULT_CONTROL_BYTES   => X"00_04_08"
		)

		port map (
			-- Control interface (command and reply stream buses)
			ctrl_cmd_in_dat   => bsb_router_cmd_dat(0),
			ctrl_cmd_in_rdy   => bsb_router_cmd_rdy(0),
			ctrl_rply_out_dat => bsb_router_rply_dat(0),
			ctrl_rply_out_rdy => bsb_router_rply_rdy(0),
			ctrl_clk          => ctrl_clk,
			ctrl_rst          => ctrl_rst_reg,

			control_bytes => control_bytes,
			status_bytes  => status_bytes
		);


	-- frame_clk_out <= frame_clk(0);
	frame_clk_out <= s_axis_tvalid and s_axis_tlast;



	process(all) begin
		if rising_edge(clk) then
			align_reset_reg <= align_reset;
			align_reset_all <= rst_reg or align_reset_reg;

			reset_stats <= lane_monitor_reset or rst_reg;

			--lane_monitor_bit <= align_lane_monitor(to_integer(unsigned(lane_monitor_sel)));

			--if rst_reg or lane_monitor_reset then
			--	delay_capture_ref_word_ctr <= (others => '0');
			--	delay_capture_ref_word_ctr_en <= '1';
			--	lane_monitor_bit_ctr <= (others => '0');
			--else
			--	lane_monitor_bit_ctr <= lane_monitor_bit_ctr + 1 when lane_monitor_bit;

			--	if delay_capture_ref_word_ctr_en  then
			--		delay_capture_ref_word_ctr <= delay_capture_ref_word_ctr + 1;
			--		if signed(delay_capture_ref_word_ctr) = -2 or align_lane_monitor(to_integer(unsigned(lane_monitor_sel))) = '1' then
			--			delay_capture_ref_word_ctr_en <= '0';
			--		end if;
			--	end if;
			--end if;

			-- Pipeline the output of the ALIGN module to facilitate timing since it goes to every BIN_SEL, which are spread over a large area
			-- We explicitely split the data bus in many branches because the signals physically go in different directions.
			-- This pipeline is necessary to generate a delay of two clocks between the bin counter controls (bin_ctr_*) and the data.
			-- The BIN_SEL requires the bin counter control to be in advance by two clocks relatve to compensate with the lookup RAM latency

			binsel_in_tvalid_reg <= (others => s_axis_tvalid) when not rst_reg else (others => '0');
			binsel_in_tdata_reg <= s_axis_tdata;
			binsel_in_tlast_reg <= (others => s_axis_tlast);
			binsel_in_tuser_reg <= s_axis_tuser;
			binsel_in_global_tvalid_reg <= s_axis_tvalid when not rst_reg else '0';
			binsel_in_global_tlast_reg  <= s_axis_tlast;

			-- Another pipeline level.
			binsel_in_tvalid_reg2 <= (others => binsel_in_tvalid_reg) when not rst_reg2 else (others => (others => '0'));
			binsel_in_tdata_reg2 <= (others => binsel_in_tdata_reg);
			binsel_in_tlast_reg2 <= (others => binsel_in_tlast_reg);
			binsel_in_tuser_reg2 <= (others => binsel_in_tuser_reg);
			binsel_in_global_tvalid_reg2 <= (others => binsel_in_global_tvalid_reg) when not rst_reg2 else (others => '0');
			binsel_in_global_tlast_reg2  <= (others => binsel_in_global_tlast_reg);

		end if; -- clk
	end process;


	bin_sel_gen: for i in 0 to NUMBER_OF_OUTPUT_LANES - 1 generate
	begin
		----------------------------------------
		-- Instantiate the bin selectors
		----------------------------------------

		binsel_i: entity work.chan_bin_sel
			generic map (
				PLATFORM_ID      => PLATFORM_ID,
				LANE_NUMBER      => i,
				NUMBER_OF_INPUTS => NUMBER_OF_INPUT_LANES
			)
			port map (
				-- Input data (AXI-Streaming bus, non blocking)
				s_axis_tdata         => binsel_in_tdata_reg2(BINSEL_PBLOCK_MAP(i)),
				s_axis_tuser         => binsel_in_tuser_reg2(BINSEL_PBLOCK_MAP(i)),
				s_axis_tvalid        => binsel_in_tvalid_reg2(BINSEL_PBLOCK_MAP(i)),
				s_axis_tlast         => binsel_in_tlast_reg2(BINSEL_PBLOCK_MAP(i)),
				s_axis_global_tvalid => binsel_in_global_tvalid_reg2(BINSEL_PBLOCK_MAP(i)),
				s_axis_global_tlast  => binsel_in_global_tlast_reg2(BINSEL_PBLOCK_MAP(i)),

				-- Bin counter signals: must be set two clocks before the data
				bin_ctr_en  => s_axis_tvalid,
				bin_ctr_clr => s_axis_tlast,

				-- Output data (AXI-Streaming bus, non blocking)

				m_axis_tdata  => m_axis_tdata(i),
				m_axis_tvalid => m_axis_tvalid(i),
				m_axis_tlast  => m_axis_tlast(i),

				-- bin_number => std_logic_vector(bin_ctr), -- bin number (0 to 1023), appearing 1 clock before the corresponding data (to allow the RAM to lookup the selection bits, assuming the RAM has 1 clock latency)

				rst => rst_reg2,
				clk => clk, -- common clock for both the input and output

				-- Control Interface

				ctrl_cmd_dat  => bsb_router_cmd_dat(i + 1),
				ctrl_cmd_rdy  => bsb_router_cmd_rdy(i + 1),
				ctrl_rply_dat => bsb_router_rply_dat(i + 1),
				ctrl_rply_rdy => bsb_router_rply_rdy(i + 1),
				ctrl_clk      => ctrl_clk,
				ctrl_rst      => ctrl_rst_reg2(BINSEL_PBLOCK_MAP(i))
			);
	end generate bin_sel_gen;

end architecture impl;

