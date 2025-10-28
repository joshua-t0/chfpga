----------------------------------------------------------------------------------
-- Company: McGill University
-- Engineer: J.-F. Cliche
--
-- Create Date:    2025-01-31
-- Design Name:    chFPGA
-- Module Name:    u-ct
-- Project Name: CHORD
-- Target Devices: Ultrascale+
-- Tool versions: Vivado 2012.2

-- Description: Corner-turn engine typically used with CRS boards and backplanes. Performs single-board (8 inputs) and 4-board (32 inputs) corner turns.
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

-- Ultrascale corner-turn engine -
--
-- Supports 8 channelizer inputs
-- Each channelizer inputs packs four (4+4)-bit bin values into a 32-bit value (low bin in MSB)
entity uct_engine is
	generic (
		PLATFORM_ID: integer; -- necessary to select the proper FIFOs
		NUMBER_OF_INPUT_LANES: integer := 8; -- Number of channelizer inputs
		BINS_PER_INPUT_WORD: integer   := 4;
		INPUT_WORD_WIDTH: integer      := 32; -- width of the scaler output word
		-- Corner-turning level: 1: single-board (local) only (no backplane), 2: Option 1 plus 4x4
		-- subbackplane corner-turn (4 boards, using GTY), 3: Option 2 + additional 4x4 corner-turn
		-- between 2 or 4 sub-backplanes (8 or 16 boards)
		CT_LEVEL: integer := 2;

		LANE_TO_LINK_MAP: integer_array   := (-1, 0, 1, 2); -- List indictiong the GTY link number associated to each lane. -1 means a bypass  lane (no GTY, stays internal to the board).
		LINK_TO_QUAD_MAP: integer_array   := (0, 1, 1); -- Indicates which quad is associated to each GTY link.
		QUAD_TO_REFCLK_MAP: integer_array := (0, 0); -- Indicates which refclk is associated with each QUAD
		LANE_TO_GROUP_MAP: integer_array  := (0, 0, 0, 0); -- Indicates to which lane group each lane is associated with

		-- Dervived parameters
		OUTPUT_WIDTH: integer     := NUMBER_OF_INPUT_LANES * INPUT_WORD_WIDTH;  -- assumes inputs are 32 bits wide, and CT preserves data rate
		NUMBER_OF_LINKS: integer  := max(LANE_TO_LINK_MAP) + 1; --  Number of physical data links (GTYs) - Do not override
		NUMBER_OF_REFCLK: integer := max(QUAD_TO_REFCLK_MAP) + 1; -- Number of reference clocks - Do not override
		PRE_DECIMATE: boolean     := CT_LEVEL > 1 -- True if we want to decimate the first 256 bins of the spectrum before entering the backplane shuffle
	);
	port (
		-- Non-blocking input stream from the channelizer, synchronous to `axis_clk
		-- We assume all lanes are aligned and therefore share a common `tvalid` and `tlast`
		s_axis_tdata: in slv_array(0 to NUMBER_OF_INPUT_LANES - 1)(INPUT_WORD_WIDTH-1 downto 0); -- data from each channelizer, each of which contains 4x (4+4)-bit bin values
		s_axis_tvalid: in std_logic;
		s_axis_tlast: in std_logic;

		-- Non-blocking output stream, synchronous to `axis_clk`
		m_axis_tvalid: out std_logic;
		m_axis_tdata: out slv(OUTPUT_WIDTH - 1 downto 0);
		m_axis_tlast: out std_logic;

		axis_clk: in  std_logic; -- AXI-S bus clocks. Tie to clk_out if the backplane links are enabled

		-- Backplane data shuffle

		tx_p: out std_logic_vector(0 to NUMBER_OF_LINKS - 1);
		tx_n: out std_logic_vector(0 to NUMBER_OF_LINKS - 1);
		rx_p: in std_logic_vector(0 to NUMBER_OF_LINKS - 1)      := (others => '0');
		rx_n: in std_logic_vector(0 to NUMBER_OF_LINKS - 1)      := (others => '1');
		refclk_p: in std_logic_vector(0 to NUMBER_OF_REFCLK - 1) := (others => '0');
		refclk_n: in std_logic_vector(0 to NUMBER_OF_REFCLK - 1) := (others => '1');

		refclk_div2: out std_logic_vector(0 to NUMBER_OF_REFCLK - 1); -- divided-by-two version of the 156.25 MHz reference clock fed to the QUAD PLL
		txclk_div2: out std_logic; -- divided-by-two version of the TX word clock, which is also clk_out

		txclk_out: out std_logic; -- Word clock from the GTY TX link
		-- frame_clk_in: in std_logic;

		rst: in std_logic; -- sync reset, synchronous to axis_clk
		arst: in std_logic; -- aync reset, NOT synchronized on txclk_out as arst stops the clock
		resetdone: out std_logic;

		--    align_pulse: out std_logic;

		-- Control interface (command and reply stream buses)
		bsb_cmd_dat: in AXIS8_DAT_STRUCT  := (TDATA => X"00", TVALID => '0', TLAST => '0');
		bsb_cmd_rdy: out AXIS8_RDY_STRUCT := (TREADY=> '1');
		bsb_rply_dat: out AXIS8_DAT_STRUCT;
		bsb_rply_rdy: in AXIS8_RDY_STRUCT := (TREADY => '1');
		bsb_clk: in  std_logic;
		bsb_rst: in  std_logic
	);
end entity uct_engine;

architecture impl of uct_engine is

	attribute KEEP: string;
	attribute EQUIVALENT_REGISTER_REMOVAL: string;
	attribute ASYNC_REG: string;
	attribute SHREG_EXTRACT: string;

	constant BITS_PER_BIN: integer := INPUT_WORD_WIDTH / BINS_PER_INPUT_WORD; -- There could be 16 bits per bin, even if we eventually use only 8

	constant CT1_OUTPUT_LANES: integer := BINS_PER_INPUT_WORD;
	constant CT1_LANE_WIDTH: integer := NUMBER_OF_INPUT_LANES * BITS_PER_BIN;

	constant BSB_CT1_BASE_PORT: integer := 0; -- Top-level address of the CT-Engine 1st crossbar.
	constant BSB_CT2_BASE_PORT: integer := 1; -- Top-level address of the CT-Engine 2nd crossbar
	constant BSB_CT3_BASE_PORT: integer := 2; -- Top level address of the CT-Engine 3rd crossbar
	constant BSB_BP_SHUFFLE_BASE_PORT: integer := 3; -- Top level address of the CT-Engine backplane shuffle subsystem.
	constant BSB_ROUTER_PORTS: integer := 4; -- Total number of router output ports.

	--  constant NUMBER_OF_BIN_SEL: integer := NUMBER_OF_OUTPUT_LANES/NUMBER_OF_OUTPUT_LANES_PER_BIN_SEL;

	--  signal ctrl_rst_reg: std_logic;
	--  signal rst_reg: std_logic;

	-- Routed BSB buses for each device
	signal router_cmd_dat: AXIS8_DAT_STRUCT_ARRAY(BSB_ROUTER_PORTS - 1 downto 0);
	signal router_cmd_rdy: AXIS8_RDY_STRUCT_ARRAY(BSB_ROUTER_PORTS - 1 downto 0) := (others => (TREADY => '1'));
	signal router_rply_dat: AXIS8_DAT_STRUCT_ARRAY(BSB_ROUTER_PORTS - 1 downto 0);
	signal router_rply_rdy: AXIS8_RDY_STRUCT_ARRAY(BSB_ROUTER_PORTS - 1 downto 0);

	signal bsb_rst_reg: std_logic;
	signal cb1_rst: std_logic;

begin

	ctrl_rst_proc: process(all) begin
		if rising_edge(bsb_clk) then
			bsb_rst_reg <= bsb_rst;
		end if; -- RST/CLK
	end process;

	---------------------------------------------------------------------
	-- ROUTER
	---------------------------------------------------------------------
	-- Routes the commands and replies to/from the corner-turn engine submodules

	bsb_router0: entity work.CTRL_ROUTER
		generic map (
			NUMBER_OF_PORTS => BSB_ROUTER_PORTS,
			ADDRESS_MASK    => "---11--------------" -- 4 ports max (CT1, CT2, CT3, XXVGLINK),  14-bit internal address range per port
		)
		port map (
			-- Master control interface
			cmd_in_dat   => bsb_cmd_dat,
			cmd_in_rdy   => bsb_cmd_rdy,
			rply_out_dat => bsb_rply_dat,
			rply_out_rdy => bsb_rply_rdy,


			cmd_out_dat => router_cmd_dat,
			cmd_out_rdy => router_cmd_rdy,
			rply_in_dat => router_rply_dat,
			rply_in_rdy => router_rply_rdy,

			clk => bsb_clk,
			rst => bsb_rst_reg
		);


	-- First corner turn (internal corner-turn)
	ct1_blk: block is
		signal control_bytes: slv8_array(0 to 0); -- default value set in the CMD_SLAVE
		signal status_bytes: slv8_array(0 to 2);

		-- signal cb1_in_tdata: slv_array(0 to NUMBER_OF_INPUT_LANES-1)(INPUT_WORD_WIDTH-1 downto 0);
		signal cb1_in_tdata: slv_array(0 to NUMBER_OF_INPUT_LANES - 1)(INPUT_WORD_WIDTH-1 downto 0);
		signal cb1_in_tvalid: std_logic;
		signal cb1_in_tlast: std_logic;
		attribute shreg_extract of cb1_in_tdata, cb1_in_tvalid, cb1_in_tlast: signal is "no"; -- prevent the tool form inferring a shift register


		signal cb1_out_tdata: slv_array(0 to CT1_OUTPUT_LANES - 1)(CT1_LANE_WIDTH - 1 downto 0);
		signal cb1_out_tvalid: std_logic;
		signal cb1_out_tlast: std_logic;
		attribute shreg_extract of cb1_out_tdata, cb1_out_tvalid, cb1_out_tlast: signal is "true"; -- prevent the tool form inferring a shift register

		signal in_frame_ctr, out_frame_ctr: unsigned(7 downto 0);
	begin

		-- Pipeline BSB reset
		process(all) begin
			if rising_edge(bsb_clk) then
				bsb_rst_reg <= bsb_rst;
			end if; -- bsb_clk
		end process;

		-- Pipeline corner-turn reset
		-- Note; Putting two `if rising_edge(clk)`` in the same process crashed Vivado simulator 2008.
		process(all) begin
			if rising_edge(axis_clk) then
				cb1_rst <= rst;
			end if; -- RST/CLK
		end process;

		-- Instantiate level-1 corner turning registers
		ct1_regs0: entity work.CTRL_SLAVE
			generic map (
				NUMBER_OF_CONTROL_BYTES => control_bytes'LENGTH(1), --
				NUMBER_OF_STATUS_BYTES  => status_bytes'LENGTH(1), --
				DEFAULT_CONTROL_BYTES   => X"00"
			)

			port map (
				ctrl_cmd_in_dat   => router_cmd_dat(BSB_CT1_BASE_PORT),
				ctrl_cmd_in_rdy   => router_cmd_rdy(BSB_CT1_BASE_PORT),
				ctrl_rply_out_dat => router_rply_dat(BSB_CT1_BASE_PORT),
				ctrl_rply_out_rdy => router_rply_rdy(BSB_CT1_BASE_PORT),

				ctrl_clk => bsb_clk,
				ctrl_rst => bsb_rst_reg,

				control_bytes => control_bytes,
				status_bytes  => status_bytes
			);

		-- Connect CT level 1 registers
		status_bytes(0)(1 downto 0) <= to_slv(CT_LEVEL, 2);
		status_bytes(0)(2)          <= cb1_rst;
		status_bytes(0)(3)          <= rst;
		status_bytes(0)(4)          <= arst;
		status_bytes(1)             <= std_logic_vector(in_frame_ctr);
		status_bytes(2)             <= std_logic_vector(out_frame_ctr);


		-- Perform the crossbar operation
		process(all)

			variable rchan, rbin: integer; -- reverse lane and bin numbers
			variable lsb: integer;

		begin
			if rising_edge(axis_clk) then
				-- count CT1 input and output words

				in_frame_ctr <= in_frame_ctr + 1 when s_axis_tvalid and s_axis_tlast;
				out_frame_ctr <= out_frame_ctr + 1 when m_axis_tvalid and m_axis_tlast;

				-- pipeline channelizer data
				-- This CT engine assumes that the channelizer data is aligned, i.e. all lanes share a common tvalid and tlast
				cb1_in_tdata <= s_axis_tdata;
				cb1_in_tvalid <= s_axis_tvalid when not cb1_rst else '0';
				cb1_in_tlast <= s_axis_tlast;

				-- Implement a hardwired CROSSBAR1.
				-- We take  NUMBER_OF_INPUT_LANES lanes, each word containing values from BINS_PER_INPUT_WORD different bins.
				-- We generate BINS_PER_INPUT_WORD lanes each word containing the NUMBER_OF_INPUT_LANES values from the same bin
				-- We pack the values with the lower input lane being in the MSB of the output word.
				-- Outlut lane 0 is for low bins, which are in the MSB of the input words
				for bin in 0 to BINS_PER_INPUT_WORD - 1 loop -- 0 to 3
				    rbin := BINS_PER_INPUT_WORD - 1 - bin;
					for chan in 0 to NUMBER_OF_INPUT_LANES - 1 loop -- 0 to 7
					   rchan := NUMBER_OF_INPUT_LANES - 1 - chan; -- reverse input lane,  7 to 0
					   lsb := BITS_PER_BIN * rchan;
						cb1_out_tdata(bin)(lsb + BITS_PER_BIN - 1 downto lsb) <= cb1_in_tdata(chan)(BITS_PER_BIN * (rbin + 1) - 1 downto BITS_PER_BIN * rbin);
					end loop;

				end loop;

				cb1_out_tvalid <= cb1_in_tvalid when not cb1_rst else '0';
				cb1_out_tlast <= cb1_in_tlast;
			end if; -- clk
		end process;

		-- ******

		ct2_gen: if not (CT_LEVEL >= 2) generate -- If we do NOT have level 2 corner-turning

			process(all)

				variable lsb: integer;
				variable rlane: integer; -- reverse lane

			begin
				-- If there is no level 2 corner-turning, then assign crossbar 1 outputs directly to the output bus
				-- We repack the cb1 output lane into a single word for the correlator.
				-- CT1 lane 0 is in the MSB. Channelizer 0 value is in the MSB. Re part of value is on the MSB.
				if rising_edge(axis_clk) then
					for lane in 0 to CT1_OUTPUT_LANES - 1 loop
                    rlane := CT1_OUTPUT_LANES - 1 - lane;
						m_axis_tdata(CT1_LANE_WIDTH * (rlane + 1) - 1 downto  CT1_LANE_WIDTH * rlane) <= cb1_out_tdata(lane);
					end loop;

					m_axis_tvalid <= cb1_out_tvalid when not cb1_rst else '0';
					m_axis_tlast <= cb1_out_tlast;
					resetdone <= not cb1_rst;
				end if; -- bsb_clk
			end process;

		else generate -- If we have level 2 corner-turning

			constant NUMBER_OF_CT2_INPUTS: integer := BINS_PER_INPUT_WORD;
			constant NUMBER_OF_CT2_OUTPUTS: integer := NUMBER_OF_CT2_INPUTS;
			constant BITS_PER_CT2_LANE_WORD: integer := BITS_PER_BIN * NUMBER_OF_INPUT_LANES;
			signal   align1_rst_reg: std_logic;


			-- Control and status bytes

			signal control_bytes: slv8_array(0 to (2 + (NUMBER_OF_CT2_INPUTS + 1) / 2 + (NUMBER_OF_CT2_OUTPUTS + 1) / 2 + 2)); -- default value set in the CMD_SLAVE
			signal status_bytes: slv8_array(0 to 14);


			-- Remap1 control and status signals

			signal lane_map: slv4_array(0 to NUMBER_OF_CT2_INPUTS - 1);
			signal lane_postmap: slv4_array(0 to NUMBER_OF_CT2_OUTPUTS - 1);

			-- Align1 control and status signals

			signal align1_ignore_lane: slv(0 to NUMBER_OF_CT2_INPUTS - 1);
			signal align1_sof_window_stop: std_logic_vector(7 downto 0);

			signal align1_lane0_tfirst_mon: std_logic;
			signal align1_fifo_tfirst_mon: std_logic_vector(0 to NUMBER_OF_CT2_INPUTS - 1);
			signal align1_fifo_count_mon: slv10_array(0 to NUMBER_OF_CT2_INPUTS - 1);
			signal fifo_count_mon_reg: slv10_array(0 to NUMBER_OF_CT2_INPUTS - 1);



			-- resets
			signal remap_rst: std_logic;
			signal bp_rst: std_logic;
			signal align1_rst: std_logic;

			signal word_ctr: unsigned(10 downto 0);

			signal remap_out_tdata: slv_array(0 to NUMBER_OF_CT2_INPUTS - 1)(BITS_PER_CT2_LANE_WORD - 1 downto 0);
			signal remap_out_tvalid: std_logic_vector(0 to NUMBER_OF_CT2_INPUTS - 1);
			signal remap_out_tlast: std_logic_vector(0 to NUMBER_OF_CT2_INPUTS - 1);

			signal bp1_out_tdata: slv_array(0 to NUMBER_OF_CT2_OUTPUTS - 1)(BITS_PER_CT2_LANE_WORD - 1 downto 0);
			signal bp1_out_tvalid: slv(0 to NUMBER_OF_CT2_OUTPUTS - 1);
			signal bp1_out_tlast: slv(0 to NUMBER_OF_CT2_OUTPUTS - 1);

			-- Align buses

			signal align1_out_tdata: slv_array(0 to NUMBER_OF_CT2_OUTPUTS - 1)(BITS_PER_CT2_LANE_WORD - 1 downto 0);
			signal align1_out_tvalid: std_logic;
			signal align1_out_tlast: std_logic;


			-- Align monitoring

			signal align1_mon_reset: std_logic;
			signal align1_mon_lane: std_logic_vector(3 downto 0);
			signal align1_mon_source: std_logic_vector(3 downto 0);
			signal align1_mon_word: std_logic_vector(15 downto 0);

			-- CT2 output

			signal ct2_out_tdata: slv_array(0 to NUMBER_OF_CT2_OUTPUTS - 1)(BITS_PER_CT2_LANE_WORD - 1 downto 0);
			signal ct2_out_tvalid: std_logic;
			signal ct2_out_tlast: std_logic;


			-- used

			signal align_reset: std_logic;
			signal remap_reset: std_logic;


		begin
			-- Pipeline resets for Level 2 CT logic
			process(all) begin
				if rising_edge(axis_clk) then
					remap_rst <= cb1_rst;
					bp_rst <= remap_rst;
					align1_rst <= bp_rst;
				end if; -- bsb_clk
			end process;

			-- Instantiate registers for Level 2 corner turning
			ct2_regs0: entity work.CTRL_SLAVE
				generic map (
					NUMBER_OF_CONTROL_BYTES => control_bytes'LENGTH(1), --
					NUMBER_OF_STATUS_BYTES  => status_bytes'LENGTH(1), --
					DEFAULT_CONTROL_BYTES   => X"80_01_64_0000_0123_0123"
				)

				port map (
					ctrl_cmd_in_dat   => router_cmd_dat(BSB_CT2_BASE_PORT),
					ctrl_cmd_in_rdy   => router_cmd_rdy(BSB_CT2_BASE_PORT),
					ctrl_rply_out_dat => router_rply_dat(BSB_CT2_BASE_PORT),
					ctrl_rply_out_rdy => router_rply_rdy(BSB_CT2_BASE_PORT),

					ctrl_clk => bsb_clk,
					ctrl_rst => bsb_rst_reg,

					control_bytes => control_bytes,
					status_bytes  => status_bytes
				);

			-- Assign registers for level-2 corner-turning

			-- CONTROL Byte 0
			align1_mon_reset <= control_bytes(0)(0);

			-- CONTROL Byte 1
			-- CONTROL_BYTES(1)(7) unused
			align1_mon_source <= control_bytes(1)(7 downto 4);
			align1_mon_lane   <= control_bytes(1)(3 downto 0);

			-- CONTROL Byte 2
			align1_sof_window_stop <= control_bytes(2);

			-- CONTROL Bytes 3-4

			align1_ignore_lane <= reverse_bits_and_dir(to_slv(control_bytes(3 to 4))(NUMBER_OF_CT2_INPUTS - 1 downto 0));

			-- CONTROL Bytes 5-6 (lane premap) and 7-8 (lane postmap)
			lane_map_gen: for i in 0 to NUMBER_OF_CT2_INPUTS - 1 generate
				lane_map(i) <= control_bytes(5 + i / 2)(((i + 1) mod 2) * 4 + 3 downto ((i + 1) mod 2) * 4); --
			end generate lane_map_gen;

			lane_postmap_gen: for i in 0 to NUMBER_OF_CT2_OUTPUTS - 1 generate
				lane_postmap(i) <= control_bytes(5 + NUMBER_OF_CT2_INPUTS / 2 + i / 2)(((i + 1) mod 2) * 4 + 3 downto ((i + 1) mod 2) * 4); --
			end generate lane_postmap_gen;


			status_bytes(0)(0) <= '0';

			-- STATUS Byte 1
			status_bytes(1 to 2) <= to_slv8_array(align1_mon_word);


			--         Lane remap and bin culling

			--     Remap lanes to be fed to the backplane shuffle in order to
			--     route bin sets to specific destination slots. The mapping differs for each slot.

			--         Also perform bin culling to allow the data to fit the backplane link bandwidth.
			--         To do this, we drop one bin on each of the first 256 words. This means we ibhibit tvalid on one output lane during each of the first 256 words.
			--         We rotate the targeted bin on each word, matching the ordering of the bin-rotated order of the FFT, so we end up
			--         dropping the first 256 absolute bins of the spectrum.

			--         Pre-decimation bandwidth = 400 MHz * 64 bit/output_lane = 25.6 Gbps
			--         Post-decimation bandwidth = 400 MHz * 64 bits/output_lane * (8192-256 bins)/(8192 bins) = 24.8 Gbps
			remap_proc: process(all)

				variable source_lane: integer range 0 to NUMBER_OF_CT2_INPUTS - 1;
				variable drop_bin: boolean;

			begin
				if rising_edge(axis_clk) then
					-- Remap and cull enough bins to fit the data in backplane links
					if cb1_out_tvalid then
						word_ctr <= word_ctr + 1 when not cb1_out_tlast else (others => '0');
					end if;
					word_ctr <= (others => '0') when remap_rst;


					for lane in 0 to NUMBER_OF_CT2_INPUTS - 1 loop
					source_lane := to_integer(unsigned(lane_map(lane)));
					remap_out_tdata(lane) <= cb1_out_tdata(source_lane);
					drop_bin := PRE_DECIMATE and (word_ctr(10 downto 8) = 0) and (word_ctr(1 downto 0) = source_lane); -- Drop first 256 bins by following FFT's bin rotation
					--drop_bin := word_ctr(10 downto 6) = 0; -- drop first 64 words
					--drop_bin := (word_ctr(4 downto 0) = 16) and cb1_out_tlast='0'; -- drop word 16 for every 32 words. 2048/32 = 64 words dropped total
					remap_out_tvalid(lane) <= cb1_out_tvalid when not (??remap_rst or drop_bin) else '0';
					remap_out_tlast(lane) <= cb1_out_tlast;
					end loop;

				end if; -- clk
			end process;


			-- Instantiate backplane links
			-- Used for 1st data shuffle (between 4 boards on the same sub-backplane) and eventually 2nd data shuffle (between sub-backplanes)
			bp_links0: entity work.xxvglink_array
				generic map (
					LANE_TO_LINK_MAP   => LANE_TO_LINK_MAP, -- 4 logical lane: 1 bypass lane, 3 physical links
					LINK_TO_QUAD_MAP   => LINK_TO_QUAD_MAP, -- Indicates which quad is associated each channel. The QUAD number is an integer between 0 and N-1, where N is the total number of quads used.
					QUAD_TO_REFCLK_MAP => QUAD_TO_REFCLK_MAP -- Indicates which refclk is associated with each QUAD (N integers from 0 to NUMBER_OF_REFCLK-1).
				)
				port map (
					-- Backplane link signals
					tx_p     => tx_p,
					tx_n     => tx_n,
					rx_p     => rx_p,
					rx_n     => rx_n,
					refclk_p => refclk_p,
					refclk_n => refclk_n,

					-- TX user interface (AXI-Streaming, non-blocking, on clk_out)
					s_axis_tx_tdata  => remap_out_tdata,
					s_axis_tx_tvalid => remap_out_tvalid,
					s_axis_tx_tlast  => remap_out_tlast,

					-- RX user interface (AXI-Streaming, non-blocking, on clk_out)
					m_axis_rx_tdata  => bp1_out_tdata,
					m_axis_rx_tvalid => bp1_out_tvalid,
					m_axis_rx_tlast  => bp1_out_tlast,

					axis_clk  => axis_clk, -- lcock for both AXIS interfaces
					resetdone => resetdone,

					-- Backplane link cloand and related clock monitoring signals
					clk_out     => txclk_out, -- 402.8 MHz clock from TX links (25 Gbps * 66/64 / 64 bits/word =402.83203125 MHz)
					refclk_div2 => refclk_div2, -- divided-by-two version of the 156.25 MHz reference clock fed to the QUAD PLL
					txclk_div2  => txclk_div2, -- divided-by-two version of the TX word clock, which is also clk_out

					-- Control and reply streams
					cmd_dat  => router_cmd_dat(BSB_BP_SHUFFLE_BASE_PORT),
					cmd_rdy  => router_cmd_rdy(BSB_BP_SHUFFLE_BASE_PORT),
					rply_dat => router_rply_dat(BSB_BP_SHUFFLE_BASE_PORT),
					rply_rdy => router_rply_rdy(BSB_BP_SHUFFLE_BASE_PORT),
					ctrl_clk => bsb_clk,
					ctrl_rst => bsb_rst,
					-- areset   => bp_shuffle_reset_reg
					areset => arst -- stops clk_out: must not be sync'ed to clk_out.
				);

			-- Instantiate packet aligner
			align1: entity work.align64
				generic map (
					NUMBER_OF_LANES         => NUMBER_OF_CT2_INPUTS,
					ENABLE_MONITORING_LOGIC => TRUE
				)
				port map (
					-- Data from the channelizers outputs (AXI Streaming, blocking)
					s_axis_tvalid => bp1_out_tvalid,
					s_axis_tdata  => bp1_out_tdata,
					s_axis_tlast  => bp1_out_tlast,

					-- Data to the remapper (AXI Streaming, non-blocking)
					m_axis_tvalid        => align1_out_tvalid,
					m_axis_tdata         => align1_out_tdata,
					m_axis_tlast         => align1_out_tlast,


					-- Aligner configuration
					ignore_lane     => align1_ignore_lane,

					-- Monitoring (if enabled)
					mon_reset  => align1_mon_reset,
					mon_lane   => align1_mon_lane,
					mon_source => align1_mon_source,
					mon_word   => align1_mon_word,

					clk => axis_clk,
					rst => align1_rst
				);

			postmap_proc: process(all)

				variable source_lane: integer range 0 to NUMBER_OF_CT2_INPUTS - 1;

			begin
				if rising_edge(axis_clk) then
					-- Remap output bins to fit the data in backplane links
					for lane in 0 to NUMBER_OF_CT2_INPUTS - 1 loop
					source_lane := to_integer(unsigned(lane_postmap(lane)));
						ct2_out_tdata(lane) <= align1_out_tdata(source_lane);
					end loop;

					ct2_out_tvalid <= '0' when align1_rst_reg else align1_out_tvalid;
					ct2_out_tlast <= align1_out_tlast;
				end if; -- clk
			end process;


			mon_proc: process(all) begin
				if rising_edge(axis_clk) then
				--                if
				--                out_frame_ctr
				end if; -- clk
			end process;


			ct3_gen: if not (CT_LEVEL >= 3) generate
			begin
				-- We have no level-3 corner-turning, so assign the output of the packet aligner to the output bus
				process(all)

					variable rlane: integer; -- reverse lane number

				begin
					if rising_edge(axis_clk) then
						for lane in 0 to NUMBER_OF_CT2_INPUTS - 1 loop
                        rlane := NUMBER_OF_CT2_INPUTS - 1 - lane;
							m_axis_tdata(BITS_PER_CT2_LANE_WORD * (rlane + 1) - 1  downto BITS_PER_CT2_LANE_WORD * rlane) <= ct2_out_tdata(lane);
						end loop;

						m_axis_tvalid <= '0' when align1_rst_reg else ct2_out_tvalid;
						m_axis_tlast <= ct2_out_tlast;
					end if; -- bsb_clk
				end process;

			else generate -- implement Level-3 corner turning

				-- Instantiate registers for level-3 corner turning
				ct3_regs0: entity work.CTRL_SLAVE
					generic map (
						NUMBER_OF_CONTROL_BYTES => control_bytes'LENGTH(1), --
						NUMBER_OF_STATUS_BYTES  => status_bytes'LENGTH(1), --
						DEFAULT_CONTROL_BYTES   => X"00"
					)

					port map (
						ctrl_cmd_in_dat   => router_cmd_dat(BSB_CT3_BASE_PORT),
						ctrl_cmd_in_rdy   => router_cmd_rdy(BSB_CT3_BASE_PORT),
						ctrl_rply_out_dat => router_rply_dat(BSB_CT3_BASE_PORT),
						ctrl_rply_out_rdy => router_rply_rdy(BSB_CT3_BASE_PORT),

						ctrl_clk => bsb_clk,
						ctrl_rst => bsb_rst_reg,

						control_bytes => control_bytes,
						status_bytes  => status_bytes
					);

				assert FALSE report "Level-3 corner-turn not yet supported" severity FAILURE;

			-- 2nd set of BP links is activated
			-- CB2: redistribute align1 outputs to 2-word deep FIFO
			-- connect CB2 out to BP in
			-- Align2

			end generate ct3_gen; -- if CT_LEVEL >= 3

		end generate ct2_gen; -- if CT_LEVEL >= 2

	end block ct1_blk; -- cb1_block


end architecture impl;

