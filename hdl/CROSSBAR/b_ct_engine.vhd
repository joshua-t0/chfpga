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
use UNISIM.VComponents.all;

use work.chFPGA_Package.all;

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
entity b_ct_engine is
	GENERIC (
		PLATFORM_ID: integer; -- necessary to select the proper FIFOs
		NUMBER_OF_INPUT_LANES: integer := 8; -- Number of channelizer inputs
		CT_LEVEL: integer := 2; -- Corner-turning level: 1: single-board (local) only (no backplane), 2: Option 1 plus 4x4 subbackplane corner-turn (4 boards, using GTY), 3: Option 2 + additional 4x4 corner-turn between 2 or 4 sub-backplanes (8 or 16 boards)
		LANE_TO_LINK_MAP: integer_array  := (-1,0,1,2); -- List indictiong the GTY link number associated to each lane. -1 means a bypass  lane (no GTY, stays internal to the board).
		LINK_TO_QUAD_MAP: integer_array  := (0,1,1); -- Indicates which quad is associated to each GTY link.
		QUAD_TO_REFCLK_MAP: integer_array:= (0,0); -- Indicates which refclk is associated with each QUAD
		NUMBER_OF_LINKS: integer        := max(LANE_TO_LINK_MAP) + 1; --  Number of physical data links (GTYs) - Do not override
    	NUMBER_OF_REFCLK: integer       := max(QUAD_TO_REFCLK_MAP) + 1; -- Number of reference clocks - Do not override

		NUMBER_OF_OUTPUT_LANES: integer := 8; -- Number of output streams
		WORDS_PER_BIN_MAX: integer :=4; --! Maximum number of words that can be present in a bin on one input lane. The 2nd crossbar receives up to 4 words. The 3rd crossbar will can have up to 16 words.
		BINS_PER_FRAME_MAX: integer :=64; --! Maximum number of bins per frame
		BIN_SEL_FIFO_TYPE_MAP: integer_16xN_array := (0 to 15 => (0 to 3=>0, others=>0)); -- 0= Block RAM., 1=Dist RAM. By default, for every BIN_SEL, 10 FIFOS are made of BRAM and the rest is made of distributed RAM to maximize area utilization efficiency
		SHUFFLE_FLAGS_MASK: slv32 -- Mask to apply to the shuffle flags to count packet errors
		);
	PORT(

		-- Non-blocking input stream from the channelizer, synchronous to `clk`
		s_axis_tvalid: in slv(0 to NUMBER_OF_INPUT_LANES-1);
		s_axis_tdata: in slv_array(0 to NUMBER_OF_INPUT_LANES-1)(31 downto 0); -- data from each channelizer, each of which contains 4x (4+4)-bit bin values
		s_axis_tlast: in slv(0 to NUMBER_OF_INPUT_LANES-1);

		-- Non-blocking output stream, synchronous to `clk`
		m_axis_tvalid: out slv(0 to NUMBER_OF_OUTPUT_LANES-1);
		m_axis_tdata: out slv_array(0 to NUMBER_OF_OUTPUT_LANES-1);
		m_axis_tlast: out slv(0 to NUMBER_OF_OUTPUT_LANES-1);


		-- Backplane data shuffle

		tx_p     : out  => tx_p;
		tx_n     : out  => tx_n;
		rx_p     : in   => rx_p;
		rx_n     : in  => rx_n;
		refclk_p : in  => refclk_p;
		refclk_n : in  => refclk_n;

		refclk_div2: out std_logic; -- divided-by-two version of the 156.25 MHz reference clock fed to the QUAD PLL
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
		bsb_rst : in  std_logic
		);

end b_ct_engine;

architecture Behavioral of b_ct_engine is

	attribute keep:string;
	attribute equivalent_register_removal: string;
	attribute async_reg: string;
	attribute shreg_extract: string;

	constant NUMBER_OF_CB1_OUTPUTS: integer := 4;
	constant NUMBER_OF_LINKS: integer := max(LANE_TO_LINK_MAP) + 1; --  Number of physical data links (GTYs)

	constant BSB_CROSSBAR1_BASE_PORT : integer := 0; -- Top-level address of the CT-Engine 1st crossbar.
	constant BSB_CROSSBAR2_BASE_PORT : integer := 1; -- Top-level address of the CT-Engine 2nd crossbar
	constant BSB_CROSSBAR3_BASE_PORT : integer := 2; -- Top level address of the CT-Engine 3rd crossbar
	constant BSB_BP_SHUFFLE_BASE_PORT: integer := 3; -- Top level address of the CT-Engine backplane shuffle subsystem.
	constant BSB_ROUTER_PORTS        : integer := 4; -- Total number of router output ports.

	constant NUMBER_OF_BIN_SEL: integer := NUMBER_OF_OUTPUT_LANES/NUMBER_OF_OUTPUT_LANES_PER_BIN_SEL;

	signal ctrl_rst_reg: std_logic;
	signal rst_reg: std_logic;

	-- Routed BSB buses for each device
	signal router_cmd_dat: AXIS8_DAT_STRUCT_ARRAY(0 to BSB_ROUTER_PORTS-1);
	signal router_cmd_rdy: AXIS8_RDY_STRUCT_ARRAY(0 to BSB_ROUTER_PORTS-1);
	signal router_rply_dat: AXIS8_DAT_STRUCT_ARRAY(0 to BSB_ROUTER_PORTS-1);
	signal router_rply_rdy: AXIS8_RDY_STRUCT_ARRAY(0 to BSB_ROUTER_PORTS-1);





	signal s_axis_tfirst: slv(0 to NUMBER_OF_INPUT_LANES-1);

	signal m_axis_tvalid_int: slv(0 to NUMBER_OF_OUTPUT_LANES-1);
	signal m_axis_tdata_int: slv32_array(0 to NUMBER_OF_OUTPUT_LANES-1);
	signal m_axis_tlast_int: slv(0 to NUMBER_OF_OUTPUT_LANES-1);
	signal m_axis_terror_int: slv(0 to NUMBER_OF_OUTPUT_LANES-1);

	-- Internal AXI-Streaming buses

	signal m_axis_fifo_tvalid: slv(0 to NUMBER_OF_INPUT_LANES-1);
	signal m_axis_fifo_tdata: slv32_array(0 to NUMBER_OF_INPUT_LANES-1);
	signal m_axis_fifo_tlast: slv(0 to NUMBER_OF_INPUT_LANES-1);
	signal m_axis_fifo_tuser: slv4_array(0 to NUMBER_OF_INPUT_LANES-1);
	signal m_axis_fifo_tready: slv(0 to NUMBER_OF_INPUT_LANES-1);
	-- signal frame_clk:slv (0 to NUMBER_OF_INPUT_LANES-1);

	signal m_axis_align_tvalid: slv(0 to NUMBER_OF_INPUT_LANES-1);
	signal m_axis_align_tdata: slv32_array(0 to NUMBER_OF_INPUT_LANES-1);
	signal m_axis_align_tlast: slv(0 to NUMBER_OF_INPUT_LANES-1);
	signal m_axis_align_tuser: slv4_array(0 to NUMBER_OF_INPUT_LANES-1);
	signal m_axis_align_global_tvalid: std_logic;
	signal m_axis_align_global_tlast: std_logic;

	signal m_axis_remap_tvalid: slv(0 to NUMBER_OF_INPUT_LANES-1);
	signal m_axis_remap_tdata: slv32_array(0 to NUMBER_OF_INPUT_LANES-1);
	signal m_axis_remap_tlast: slv(0 to NUMBER_OF_INPUT_LANES-1);
	-- signal m_axis_remap_tuser: slv4_array(0 to NUMBER_OF_INPUT_LANES-1);
	signal m_axis_remap_global_tvalid: std_logic;
	signal m_axis_remap_global_tlast: std_logic;

	signal m_axis_remap_tvalid_reg: slv(0 to NUMBER_OF_INPUT_LANES-1);
	signal m_axis_remap_tdata_reg: slv32_array(0 to NUMBER_OF_INPUT_LANES-1);
	signal m_axis_remap_tlast_reg: slv(0 to NUMBER_OF_INPUT_LANES-1);
	-- signal m_axis_remap_tuser_reg: slv4_array(0 to NUMBER_OF_INPUT_LANES-1);

	attribute shreg_extract of m_axis_remap_tvalid_reg: signal is "no";
	attribute shreg_extract of m_axis_remap_tdata_reg: signal is "no";
	attribute shreg_extract of m_axis_remap_tlast_reg: signal is "no";



	signal input_frame_ctr: u8_array(0 to NUMBER_OF_INPUT_LANES-1);
	signal align_frame_ctr: u8_array(0 to NUMBER_OF_INPUT_LANES-1);
	signal output_frame_ctr: u8_array(0 to NUMBER_OF_OUTPUT_LANES-1);
	signal packet_error_ctr: u16_array(0 to NUMBER_OF_OUTPUT_LANES-1);
	-- signal enable_fifo_frame_detection: std_logic;
	-- signal enable_align_frame_detection: std_logic;
	-- signal enable_remap_frame_detection: std_logic;
	-- signal enable_output_frame_detection: std_logic;

	signal lane_monitor:  std_logic_vector(0 to NUMBER_OF_INPUT_LANES-1);
	signal lane_monitor_sel: unsigned(3 downto 0);
	signal lane_monitor_reset: std_logic;
	signal input_frame_detection:  std_logic_vector(0 to NUMBER_OF_INPUT_LANES-1);
	-- signal fifo_frame_detection:  std_logic_vector(0 to NUMBER_OF_INPUT_LANES-1);
	signal align_frame_detection:  std_logic_vector(0 to NUMBER_OF_INPUT_LANES-1);
	signal remap_frame_detection:  std_logic_vector(0 to NUMBER_OF_INPUT_LANES-1);
	signal output_frame_detection: std_logic_vector(0 to NUMBER_OF_OUTPUT_LANES-1);
	signal align_fifo_overflow: std_logic_vector(0 to NUMBER_OF_INPUT_LANES-1);
	signal align_fifo_overflow_sticky: std_logic_vector(0 to NUMBER_OF_INPUT_LANES-1);
	signal missing_frame: std_logic_vector(0 to NUMBER_OF_INPUT_LANES-1);
	signal missing_frame_sticky: std_logic_vector(0 to NUMBER_OF_INPUT_LANES-1);
	signal discarded_data: std_logic_vector(0 to NUMBER_OF_INPUT_LANES-1);
	signal discarded_data_sticky: std_logic_vector(0 to NUMBER_OF_INPUT_LANES-1);
	signal bad_lane_sticky: std_logic_vector(0 to NUMBER_OF_INPUT_LANES-1);
	signal bad_eof_sticky: std_logic_vector(0 to NUMBER_OF_INPUT_LANES-1);

	signal frame_clk_sel: std_logic;
	signal align_reset: std_logic;
	signal remap_reset: std_logic;
	signal clk_ctr: unsigned(7 downto 0);
	-- signal frame_clk_ctr: unsigned(7 downto 0);
	-- signal frame_clk_dly: std_logic;
	signal align_reset_all: std_logic;

	--- Define Control word and its signals
	signal CONTROL_BYTES: slv8_array(0 to (2 + (NUMBER_OF_INPUT_LANES+1)/2 + 2)); -- default value set in the CMD_SLAVE
	signal STATUS_BYTES: slv8_array(0 to 14);

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



begin

	ctrl_rst_proc: process(ctrl_clk)
		begin
			if rising_edge(ctrl_clk) then
				ctrl_rst_reg <= ctrl_rst;
			end if; -- RST/CLK
		end process;

	rst_proc: process(clk)
		begin
			if rising_edge(clk) then
				rst_reg <= rst;
			end if; -- RST/CLK
		end process;

	---------------------------------------------------------------------
	--! ROUTER
	---------------------------------------------------------------------
	--! Routes the commands and replies to/from the crossbar subsystems

	bsb_router0: entity work.CTRL_ROUTER
		GENERIC MAP (
			NUMBER_OF_PORTS => BSB_ROUTER_PORTS,
			ADDRESS_MASK => "---11--------------" -- 4 ports max, 14-bit internal address range per port
		)
		PORT MAP(
			-- Master control interface
			CMD_IN_DAT   => bsb_cmd_dat,
			CMD_IN_RDY   => bsb_cmd_rdy,
			RPLY_OUT_DAT => bsb_rply_dat,
			RPLY_OUT_RDY => bsb_rply_rdy,


			CMD_OUT_DAT => router_cmd_dat,
			CMD_OUT_RDY => router_cmd_rdy,
			RPLY_IN_DAT => router_rply_dat,
			RPLY_IN_RDY => router_rply_rdy,

			CLK => bsb_clk,
			RST => bsb_rst_reg
		);




---------------------------------------------------------------------
-- CHANNELIZER CROSSBAR
---------------------------------------------------------------------
--! Route specified frequency channels from all channelizers to individual streams



crossbar0_gen: if IMPLEMENT_CROSSBAR1 generate

	constant N_INPUTS: integer := min(NUMBER_OF_CHANNELIZERS, NUMBER_OF_CROSSBAR_INPUTS);

	signal crossbar1_cmd_dat: AXIS8_DAT_STRUCT;
	signal crossbar1_cmd_rdy: AXIS8_RDY_STRUCT;
	signal crossbar1_rply_dat: AXIS8_DAT_STRUCT;
	signal crossbar1_rply_rdy: AXIS8_RDY_STRUCT;

	signal axis_crossbar1_in_tdata_reg: slv32_array(0 to NUMBER_OF_CROSSBAR_INPUTS-1);
	signal axis_crossbar1_in_tuser_reg: slv4_array(0 to NUMBER_OF_CROSSBAR_INPUTS-1);
	signal axis_crossbar1_in_tvalid_reg: slv(0 to NUMBER_OF_CROSSBAR_INPUTS-1);
	signal axis_crossbar1_in_tlast_reg: slv(0 to NUMBER_OF_CROSSBAR_INPUTS-1);

	signal axis_crossbar1_in_tdata_reg2: slv32_array(0 to NUMBER_OF_CROSSBAR_INPUTS-1);
	signal axis_crossbar1_in_tuser_reg2: slv4_array(0 to NUMBER_OF_CROSSBAR_INPUTS-1);
	signal axis_crossbar1_in_tvalid_reg2: slv(0 to NUMBER_OF_CROSSBAR_INPUTS-1);
	signal axis_crossbar1_in_tlast_reg2: slv(0 to NUMBER_OF_CROSSBAR_INPUTS-1);

	attribute shreg_extract of axis_crossbar1_in_tdata_reg: signal is "no";
	attribute shreg_extract of axis_crossbar1_in_tuser_reg: signal is "no";
	attribute shreg_extract of axis_crossbar1_in_tvalid_reg: signal is "no";
	attribute shreg_extract of axis_crossbar1_in_tlast_reg: signal is "no";

	attribute shreg_extract of axis_crossbar1_in_tdata_reg2: signal is "no";
	attribute shreg_extract of axis_crossbar1_in_tuser_reg2: signal is "no";
	attribute shreg_extract of axis_crossbar1_in_tvalid_reg2: signal is "no";
	attribute shreg_extract of axis_crossbar1_in_tlast_reg2: signal is "no";

    signal crossbar1_ctrl_rst: std_logic;
    attribute DONT_TOUCH of crossbar1_ctrl_rst: signal is "true";

	signal cb1_reset: std_logic;
	signal cb1_reset_reg: std_logic;
	signal cb1_reset_reg2: std_logic;
    attribute DONT_TOUCH of cb1_reset, cb1_reset_reg, cb1_reset_reg2 : signal is "true";
begin

    bsb_rst_proc: process (ctrl_clk)
    begin
        if rising_edge(ctrl_clk) then
            crossbar1_ctrl_rst  <= ctrl_rst;
        end if;
    end process;

	-- Index the command bus into an intermediary signal to mitigate simulator problems with indexing record arrays stright in the instantiation
	crossbar1_cmd_dat             <= top_cmd_dat(CROSSBAR1_BASE_PORT);
	top_cmd_rdy(CROSSBAR1_BASE_PORT)  <= crossbar1_cmd_rdy;
	crossbar1_rply_rdy            <= top_rply_rdy(CROSSBAR1_BASE_PORT);
	top_rply_dat(CROSSBAR1_BASE_PORT) <= crossbar1_rply_dat;

	--! Pipeline and connect the channelizer output to the 1st crossbar inputs.
	--! The pipelining is there to help meeting timing closure, as we need to route long distance from the channelizer to the first crossbar
	cb1_pipe_proc: process(ct_clk)
	begin
		if rising_edge(ct_clk) then
			-- Pipeline 1
			cb1_reset <= ct_reset_reg;
			for i in 0 to N_INPUTS-1 loop
				axis_crossbar1_in_tdata(i) <= axis_chan_out_tdata(i);
				axis_crossbar1_in_tuser(i) <= axis_chan_out_tuser(i);
				axis_crossbar1_in_tlast(i) <= axis_chan_out_tlast(i);
				axis_crossbar1_in_tvalid(i) <= axis_chan_out_tvalid(i);
				-- JFC: Why was this commenetd out?
				if ct_reset_reg = '1' then
					axis_crossbar1_in_tvalid(i) <= '0';
				end if;
			end loop;

			-- Pipeline 2
			cb1_reset_reg <= cb1_reset;
			for i in 0 to N_INPUTS-1 loop
				axis_crossbar1_in_tdata_reg(i) <= axis_crossbar1_in_tdata(i);
				axis_crossbar1_in_tuser_reg(i) <= axis_crossbar1_in_tuser(i);
				axis_crossbar1_in_tlast_reg(i) <= axis_crossbar1_in_tlast(i);
				axis_crossbar1_in_tvalid_reg(i) <= axis_crossbar1_in_tvalid(i);
				-- JFC: Why was this commenetd out?
				if cb1_reset = '1' then
					axis_crossbar1_in_tvalid_reg(i) <= '0';
				end if;
			end loop;

			-- Pipeline 3
			cb1_reset_reg2 <= cb1_reset_reg;
			for i in 0 to N_INPUTS-1 loop
				axis_crossbar1_in_tdata_reg2(i) <= axis_crossbar1_in_tdata_reg(i);
				axis_crossbar1_in_tuser_reg2(i) <= axis_crossbar1_in_tuser_reg(i);
				axis_crossbar1_in_tlast_reg2(i) <= axis_crossbar1_in_tlast_reg(i);
				axis_crossbar1_in_tvalid_reg2(i) <= axis_crossbar1_in_tvalid_reg(i);
				if cb1_reset_reg = '1' then
					axis_crossbar1_in_tvalid_reg2(i) <= '0';
				end if;
			end loop;
		end if;
	end process cb1_pipe_proc;

	cb1_gen: case CROSSBAR1_TYPE generate
	   when "BRAM" =>
	       chan_crossbar0: entity work.CHAN_CROSSBAR
			generic map (
			 	PLATFORM_ID => PLATFORM_ID,  -- needed to select family-dependent FIFOs
				NUMBER_OF_INPUT_LANES  => NUMBER_OF_CROSSBAR_INPUTS,
				NUMBER_OF_OUTPUT_LANES => NUMBER_OF_CROSSBAR1_OUTPUTS,
				-- BINSEL_PBLOCK_MAP => (0 to 4 => 0, 5 to 8 => 1, 9 to 12 => 2, 13 to 15 => 3),
				BINSEL_PBLOCK_MAP => (0 to 4 => 0, 5 to 8 => 1, 9 to 12 => 1, 13 to 15 => 0),
				EIGHT_BIT_SUPPORT      => FALSE
			)
			port map (
				-- Input stream from the channelizer (AXI4-streaming, non-blocking, on clk)
				s_axis_tvalid => axis_crossbar1_in_tvalid_reg2,
				s_axis_tdata  => axis_crossbar1_in_tdata_reg2,
				s_axis_tlast  => axis_crossbar1_in_tlast_reg2,
				s_axis_tuser  => axis_crossbar1_in_tuser_reg2,

				-- Output stream to the shuffle module (AXI4-streaming, non-blocking, on clk)
				m_axis_tdata  => axis_crossbar1_out_tdata,
				m_axis_tvalid => axis_crossbar1_out_tvalid,
				m_axis_tlast  => axis_crossbar1_out_tlast,
				-- m_axis_tready => axis_crossbar1_out_tready,

				frame_clk_out => open,
				clk           => ct_clk,
				rst           => cb1_reset_reg2,

				lane_monitor => debug2,
				-- Control interface (command and reply stream buses)
				ctrl_cmd_dat  => crossbar1_cmd_dat,
				ctrl_cmd_rdy  => crossbar1_cmd_rdy,
				ctrl_rply_dat => crossbar1_rply_dat,
				ctrl_rply_rdy => crossbar1_rply_rdy,
				ctrl_clk      => ctrl_clk,
				ctrl_rst      => crossbar1_ctrl_rst
			);
        when uram_case:"URAM" =>
            signal cb_in_tdata: std_logic_vector(255 downto 0);
            signal cb_in_tvalid: std_logic;
            signal cb_in_tlast: std_logic;

            signal cb_out_tdata: std_logic_vector(255 downto 0);
            signal cb_out_tvalid: std_logic;
            signal cb_out_tlast: std_logic;

        begin

            -- remap the 8x32-bit buses into a single 256-bit bus, 1st lane on the MSB.
            tdata_gen: for i in 0 to 7 generate
                cb_in_tdata(32*(7-i)+31 downto 32*(7-i)) <= axis_crossbar1_in_tdata_reg2(i);
                axis_crossbar1_out_tdata(i) <= cb_out_tdata(32*(7-i)+31 downto 32*(7-i));
                --axis_crossbar1_out_tvalid(i) <= cb_out_tvalid;
                --axis_crossbar1_out_tlast(i) <= cb_out_tlast;
            end generate;
            axis_crossbar1_out_tvalid(0) <= cb_out_tvalid;
            axis_crossbar1_out_tlast(0) <= cb_out_tlast;
            cb_in_tvalid <= axis_crossbar1_in_tvalid_reg2(0);
            cb_in_tlast <= axis_crossbar1_in_tlast_reg2(0);

            uram0: entity work.uram_ct
                port map (
                    -- input data bus
                    s_axis_in_tdata => cb_in_tdata,
                    s_axis_in_tvalid => cb_in_tvalid,
                    s_axis_in_tlast=> cb_in_tlast,

                    -- Output data bus
                    m_axis_out_tdata => uct_tdata,
                    m_axis_out_tvalid => uct_tvalid,
                    m_axis_out_tlast=> uct_tlast,

                    clk => ct_clk,
                    rst => cb1_reset_reg2, -- synchrounous reset

                    --debug_out => debug_out,

                    -- BSB interface
                    cmd_dat=> crossbar1_cmd_dat,
                    cmd_rdy => crossbar1_cmd_rdy,
                    rply_dat => crossbar1_rply_dat,
                    rply_rdy => crossbar1_rply_rdy,
                    ctrl_clk => ctrl_clk,
                    ctrl_rst => crossbar1_ctrl_rst
                );
        end uram_case;

	    when u64_case:"U64" =>

			signal top_bp_shuffle_cmd_dat: AXIS8_DAT_STRUCT;
			signal top_bp_shuffle_cmd_rdy: AXIS8_RDY_STRUCT;
			signal top_bp_shuffle_rply_dat: AXIS8_DAT_STRUCT;
			signal top_bp_shuffle_rply_rdy: AXIS8_RDY_STRUCT;

	    begin


			top_bp_shuffle_cmd_dat             <= top_cmd_dat(BP_SHUFFLE_BASE_PORT);
			top_cmd_rdy(BP_SHUFFLE_BASE_PORT)  <= top_bp_shuffle_cmd_rdy;
			top_bp_shuffle_rply_rdy            <= top_rply_rdy(BP_SHUFFLE_BASE_PORT);
			top_rply_dat(BP_SHUFFLE_BASE_PORT) <= top_bp_shuffle_rply_dat;

            -- Implement 1st shuffle between the 4 boards in the sub-backplane
			gtlinks0: entity work.xxvglink_array
				generic map (
				    LANE_TO_LINK_MAP       => (-1,0,1,2), -- 4 logical lane: 1 bypass lane, 3 physical links
					LINK_TO_QUAD_MAP       => (0,1,1), --! Indicates which quad is associated each channel. The QUAD number is an integer between 0 and N-1, where N is the total number of quads used.
					QUAD_TO_REFCLK_MAP     => (0,0) --! Indicates which refclk is associated with each QUAD (N integers from 0 to NUMBER_OF_REFCLK-1).
					)
				port map (
					tx_p     => bp_shuffle_tx_p,
					tx_n     => bp_shuffle_tx_n,
					rx_p     => bp_shuffle_rx_p,
					rx_n     => bp_shuffle_rx_n,
					refclk_p => bp_shuffle_refclk_p,
					refclk_n => bp_shuffle_refclk_n,

					-- TX user interface (AXI-Streaming, non-blocking, on clk_out)
					s_axis_tx_tdata  => cb1_out_tdata,
					s_axis_tx_tvalid => cb1_out_tvalid,
					s_axis_tx_tlast  => cb1_out_tlast,

					-- RX user interface (AXI-Streaming, non-blocking, on clk_out)
					m_axis_rx_tdata  => axis_bp_shuffle_out_tdata64,
					m_axis_rx_tvalid => axis_bp_shuffle_out_tvalid,
					m_axis_rx_tlast  => axis_bp_shuffle_out_tlast,

					clk_out    => bp_shuffle_txclk, --! 244 or 322 MHz clock generated by the backplane shuffle transmitter from the reference clock. Must be used to clock all the Tx (slave) interface data.  There is one single clock per array.

					-- Clock monitoring ports
					refclk_div2 => bp_shuffle_refclk_div2, -- divided-by-two version of the 156.25 MHz reference clock fed to the QUAD PLL
					txclk_div2  => bp_shuffle_txclk_div2, -- divided-by-two version of the TX word clock, which is also clk_out

					-- Debug signals
					lane_monitor => open,

					-- User bypass control line
					-- bypass      => axis_bp_shuffle_bypass,

					-- Control and reply streams
					CMD_DAT  => top_bp_shuffle_cmd_dat,
					CMD_RDY  => top_bp_shuffle_cmd_rdy,
					RPLY_DAT => top_bp_shuffle_rply_dat,
					RPLY_RDY => top_bp_shuffle_rply_rdy,
					CTRL_CLK => CTRL_CLK,
					CTRL_RST => bp_shuffle_CTRL_RST_reg,
					--areset   => bp_shuffle_reset_reg
					areset   => corr_reset -- stops clk_out: must not be sync'ed to clk_out.
				 );

				 -- todo: implement data align
				 -- todo: implement 2nd crossbar
				 -- feed to correlator
		end u64_case;

        when others =>
            assert FALSE report "Invalid CROSSBAR1_TYPE" severity FAILURE;

    end generate cb1_gen;
end generate crossbar0_gen;
---------------------------------------------------------------------
-- BACKPLANE PCB and QSFP DATA LINKS
---------------------------------------------------------------------
--! Implements the GTX links to exchange the packetized data over to other boards on the backplane (over the backplane PCB links) or to boards on another crate (using the backplane QSFP links).

BPSHFGEN: if IMPLEMENT_CROSSBAR2_AND_CROSSBAR3 generate

	signal top_bp_shuffle_cmd_dat: AXIS8_DAT_STRUCT;
	signal top_bp_shuffle_cmd_rdy: AXIS8_RDY_STRUCT;
	signal top_bp_shuffle_rply_dat: AXIS8_DAT_STRUCT;
	signal top_bp_shuffle_rply_rdy: AXIS8_RDY_STRUCT;


begin
	-- Index the system control buses as a separate signal here , because the simulator will make errors if we index it directly on the instantiation
	top_bp_shuffle_cmd_dat             <= top_cmd_dat(BP_SHUFFLE_BASE_PORT);
	top_cmd_rdy(BP_SHUFFLE_BASE_PORT)  <= top_bp_shuffle_cmd_rdy;
	top_bp_shuffle_rply_rdy            <= top_rply_rdy(BP_SHUFFLE_BASE_PORT);
	top_rply_dat(BP_SHUFFLE_BASE_PORT) <= top_bp_shuffle_rply_dat;

	-- Pipeline the channelizer crossbar output to the backplane PCB shuffle input
	bp_pcb_shuffle_in_pipe_proc: process(ct_clk)
	begin
		if rising_edge(ct_clk) then
			bp_shuffle_reset <= (others=> ct_reset_reg);
			bp_shuffle_reset_reg <= bp_shuffle_reset(0);

			for i in 0 to NUMBER_OF_BP_PCB_SHUFFLE_LANES-1 loop
				axis_bp_shuffle_in_tdata(i) <= axis_crossbar1_out_tdata(i);
				axis_bp_shuffle_in_tvalid(i) <= axis_crossbar1_out_tvalid(i);
				axis_bp_shuffle_in_tlast(i) <= axis_crossbar1_out_tlast(i);
				if bp_shuffle_reset(i) = '1' then
					axis_bp_shuffle_in_tvalid(i) <= '0';
				end if;
			end loop;
			for i in 0 to NUMBER_OF_BP_QSFP_SHUFFLE_LANES-1 loop
				axis_bp_shuffle_in_tdata(NUMBER_OF_BP_PCB_SHUFFLE_LANES + i) <= axis_crossbar2_out_tdata(i);
				axis_bp_shuffle_in_tvalid(NUMBER_OF_BP_PCB_SHUFFLE_LANES + i) <= axis_crossbar2_out_tvalid(i);
				axis_bp_shuffle_in_tlast(NUMBER_OF_BP_PCB_SHUFFLE_LANES + i) <= axis_crossbar2_out_tlast(i);
				if bp_shuffle_reset(NUMBER_OF_BP_PCB_SHUFFLE_LANES + i) = '1' then
					axis_bp_shuffle_in_tvalid(NUMBER_OF_BP_PCB_SHUFFLE_LANES + i) <= '0';
				end if;
			end loop;
		end if;
	end process;

	bp_shuffle0: entity work.xglink_array -- use component instantiation to delay binding in this if-generate block and prevent errors
		generic map (
			LINK_SPEED             => BP_LINK_SPEED, -- 0: 7.5 Gb/s (244 MHz word clock), 1: 10 Gb/s (322 MHz word clock)
			NUMBER_OF_LANES        => NUMBER_OF_BP_PCB_SHUFFLE_LANES + NUMBER_OF_BP_QSFP_SHUFFLE_LANES,
			NUMBER_OF_LANE_GROUPS  => 2,
			-- LANE_GROUP_MAP         => (0 to NUMBER_OF_BP_PCB_SHUFFLE_LANES-1 => 0, NUMBER_OF_BP_PCB_SHUFFLE_LANES to NUMBER_OF_BP_PCB_SHUFFLE_LANES + NUMBER_OF_BP_QSFP_SHUFFLE_LANES-1 => 1),
			LANE_GROUP_MAP         => IntegerArray'(0 to 15 => 0, 16 to 23 => 1), -- We cast to make sure the synthesizer can unambiguously determine the final type and infer the entity in case the entity file is not needed (if-generate is False) and not included in the project
			NUMBER_OF_LINKS        => NUMBER_OF_BP_SHUFFLE_LINKS,
			LANE_TO_LINK_MAP       => BP_SHUFFLE_LANE_MAP,
			NUMBER_OF_REFCLK       => NUMBER_OF_BP_SHUFFLE_REFCLKS,
			LANE_TO_QUAD_MAP       => BP_SHUFFLE_LANE_TO_QUAD_MAP, --! Indicates which quad is associated each channel. The QUAD number is an integer between 0 and N-1, where N is the total number of quads used.
			QUAD_TO_REFCLK_MAP     => BP_SHUFFLE_QUAD_TO_REFCLK_MAP, --! Indicates which refclk is associated with each QUAD (N integers from 0 to NUMBER_OF_REFCLK-1).
			IMPLEMENT_RX           => TRUE,
			SIM                    => FALSE
			)
		port map (
			tx_p     => bp_shuffle_tx_p,
			tx_n     => bp_shuffle_tx_n,
			rx_p     => bp_shuffle_rx_p,
			rx_n     => bp_shuffle_rx_n,
			refclk_p => bp_shuffle_refclk_p,
			refclk_n => bp_shuffle_refclk_n,

			-- TX user interface (AXI-Streaming, non-blocking, on clk_out)
			s_axis_tx_tdata  => axis_bp_shuffle_in_tdata,
			s_axis_tx_tvalid => axis_bp_shuffle_in_tvalid,
			s_axis_tx_tlast  => axis_bp_shuffle_in_tlast,

			-- RX user interface (AXI-Streaming, non-blocking, on clk_out)
			m_axis_rx_tdata  => axis_bp_shuffle_out_tdata,
			m_axis_rx_tvalid => axis_bp_shuffle_out_tvalid,
			m_axis_rx_tlast  => axis_bp_shuffle_out_tlast,

			clk_out    => bp_shuffle_txclk, --! 244 or 322 MHz clock generated by the backplane shuffle transmitter from the reference clock. Must be used to clock all the Tx (slave) interface data.  There is one single clock per array.

			-- Clock monitoring ports
			refclk_div2 => bp_shuffle_refclk_div2, -- divided-by-two version of the 156.25 MHz reference clock fed to the QUAD PLL
			txclk_div2  => bp_shuffle_txclk_div2, -- divided-by-two version of the TX word clock, which is also clk_out

			-- Debug signals
			lane_monitor => open,

			-- User bypass control line
			-- bypass      => axis_bp_shuffle_bypass,

			-- Control and reply streams
			CMD_DAT  => top_bp_shuffle_cmd_dat,
			CMD_RDY  => top_bp_shuffle_cmd_rdy,
			RPLY_DAT => top_bp_shuffle_rply_dat,
			RPLY_RDY => top_bp_shuffle_rply_rdy,
			CTRL_CLK => CTRL_CLK,
			CTRL_RST => bp_shuffle_CTRL_RST_reg,
			areset   => bp_shuffle_reset_reg
		 );

end generate BPSHFGEN;

---------------------------------------------------------------------
-- CROSSBARS 2 & 3
---------------------------------------------------------------------

CROSSBAR23_GEN: if IMPLEMENT_CROSSBAR2_AND_CROSSBAR3 generate

    signal axis_crossbar2_in_reset: std_logic;
    signal axis_crossbar2_in_reset_reg: std_logic;
    attribute shreg_extract of axis_crossbar2_in_reset_reg: signal is "no";

    signal axis_crossbar2_in_tdata_reg: slv32_array(0 to NUMBER_OF_BP_PCB_SHUFFLE_LANES-1);
    signal axis_crossbar2_in_tvalid_reg: slv(0 to NUMBER_OF_BP_PCB_SHUFFLE_LANES-1);
    signal axis_crossbar2_in_tlast_reg: slv(0 to NUMBER_OF_BP_PCB_SHUFFLE_LANES-1);

    attribute shreg_extract of axis_crossbar2_in_tdata_reg: signal is "no";
    attribute shreg_extract of axis_crossbar2_in_tvalid_reg: signal is "no";
    attribute shreg_extract of axis_crossbar2_in_tlast_reg: signal is "no";

    signal axis_crossbar2_in_tdata: slv32_array(0 to NUMBER_OF_BP_PCB_SHUFFLE_LANES-1);
    signal axis_crossbar2_in_tvalid: slv(0 to NUMBER_OF_BP_PCB_SHUFFLE_LANES-1);
    signal axis_crossbar2_in_tlast: slv(0 to NUMBER_OF_BP_PCB_SHUFFLE_LANES-1);


    signal axis_crossbar3_in_tdata: slv32_array(0 to NUMBER_OF_BP_QSFP_SHUFFLE_LANES-1);
    signal axis_crossbar3_in_tvalid: slv(0 to NUMBER_OF_BP_QSFP_SHUFFLE_LANES-1);
    signal axis_crossbar3_in_tlast: slv(0 to NUMBER_OF_BP_QSFP_SHUFFLE_LANES-1);

    signal axis_crossbar3_reset: std_logic;
    signal axis_crossbar3_reset_reg: std_logic;
    signal axis_crossbar3_reset_reg2: std_logic;

	signal crossbar2_cmd_dat: AXIS8_DAT_STRUCT;
	signal crossbar2_cmd_rdy: AXIS8_RDY_STRUCT;
	signal crossbar2_rply_dat: AXIS8_DAT_STRUCT;
	signal crossbar2_rply_rdy: AXIS8_RDY_STRUCT;


	signal crossbar3_cmd_dat: AXIS8_DAT_STRUCT;
	signal crossbar3_cmd_rdy: AXIS8_RDY_STRUCT;
	signal crossbar3_rply_dat: AXIS8_DAT_STRUCT;
	signal crossbar3_rply_rdy: AXIS8_RDY_STRUCT;

    signal crossbar2_ctrl_rst: std_logic;
    signal crossbar3_ctrl_rst: std_logic;

    attribute DONT_TOUCH of crossbar2_ctrl_rst: signal is "true";
attribute DONT_TOUCH of crossbar3_ctrl_rst: signal is "true";

begin
    -- select the crossbar 2 & 3 BSB bus
	crossbar2_cmd_dat<= top_cmd_dat(CROSSBAR2_BASE_PORT);
	top_cmd_rdy(CROSSBAR2_BASE_PORT) <= crossbar2_cmd_rdy;
	crossbar2_rply_rdy<= top_rply_rdy(CROSSBAR2_BASE_PORT);
	top_rply_dat(CROSSBAR2_BASE_PORT) <= crossbar2_rply_dat;

	crossbar3_cmd_dat<= top_cmd_dat(CROSSBAR3_BASE_PORT);
	top_cmd_rdy(CROSSBAR3_BASE_PORT) <= crossbar3_cmd_rdy;
	crossbar3_rply_rdy<= top_rply_rdy(CROSSBAR3_BASE_PORT);
	top_rply_dat(CROSSBAR3_BASE_PORT) <= crossbar3_rply_dat;


	-- pipeline the bsb resets
    bsb_rst_proc: process (ctrl_clk)
    begin
        if rising_edge(ctrl_clk) then
            crossbar2_ctrl_rst  <= ctrl_rst;
			crossbar3_ctrl_rst  <= ctrl_rst;
        end if;
    end process;

    -- Pipeline the backplane PCB shuffle output to the shuffle crossbar input
    crossbar2_in_pipe_proc: process(ct_clk)
        begin
            if rising_edge(ct_clk) then
                axis_crossbar2_in_reset <= ct_reset_reg;
                axis_crossbar2_in_reset_reg <= axis_crossbar2_in_reset;

                for i in 0 to NUMBER_OF_BP_PCB_SHUFFLE_LANES-1 loop
                        axis_crossbar2_in_tdata(i)  <= axis_bp_shuffle_out_tdata(i);
                        axis_crossbar2_in_tvalid(i) <= axis_bp_shuffle_out_tvalid(i);
                        axis_crossbar2_in_tlast(i)  <= axis_bp_shuffle_out_tlast(i);
                end loop;
                if ct_reset_reg = '1' then
                    axis_crossbar2_in_tvalid <= (others=>'0');
                end if;

                axis_crossbar2_in_tdata_reg  <= axis_crossbar2_in_tdata;
                axis_crossbar2_in_tvalid_reg <= axis_crossbar2_in_tvalid;
                axis_crossbar2_in_tlast_reg  <= axis_crossbar2_in_tlast;
                if axis_crossbar2_in_reset = '1' then
                    axis_crossbar2_in_tvalid_reg <= (others=>'0');
                end if;

            end if;
        end process;

	crossbar2: entity work.shuffle_crossbar -- use component instantiation to delay binding in if-generate block and prevent errors during elaboration
		generic map (
		 	PLATFORM_ID => PLATFORM_ID,  -- needed to select family-dependent FIFOs
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
			s_axis_tdata  => axis_crossbar2_in_tdata_reg,
			s_axis_tvalid => axis_crossbar2_in_tvalid_reg,
			s_axis_tlast  => axis_crossbar2_in_tlast_reg,
			-- s_axis_tready => axis_bp_crossbar2_in_tready,

			-- Non-blocking AXI-Streaming output
			m_axis_tdata  => axis_crossbar2_out_tdata,
			m_axis_tvalid => axis_crossbar2_out_tvalid,
			m_axis_tlast  => axis_crossbar2_out_tlast,
			-- m_axis_tready => axis_crossbar2_out_tready,

			clk => ct_clk,
			rst => axis_crossbar2_in_reset_reg,

			align_pulse => debug1,
			-- Control interface (command and reply stream buses)
			ctrl_cmd_dat=> crossbar2_cmd_dat,
			ctrl_cmd_rdy=> crossbar2_cmd_rdy,
			ctrl_rply_dat=> crossbar2_rply_dat,
			ctrl_rply_rdy=> crossbar2_rply_rdy,
			ctrl_clk => CTRL_CLK,
			ctrl_rst => crossbar2_CTRL_RST
		);

	-- Pipeline the backplane PCB shuffle output to the shuffle crossbar input
	crossbar3_in_pipe_proc: process(ct_clk)
	begin
		if rising_edge(ct_clk) then
			axis_crossbar3_reset <= ct_reset_reg;
			axis_crossbar3_reset_reg <= axis_crossbar3_reset;
			for i in 0 to NUMBER_OF_BP_QSFP_SHUFFLE_LANES-1 loop
				axis_crossbar3_in_tdata(i)  <= axis_bp_shuffle_out_tdata(NUMBER_OF_BP_PCB_SHUFFLE_LANES + i); -- QSFP shuffle lanes are concatenated after PCB shuffle lanes
				axis_crossbar3_in_tvalid(i) <= axis_bp_shuffle_out_tvalid(NUMBER_OF_BP_PCB_SHUFFLE_LANES + i);
				axis_crossbar3_in_tlast(i)  <= axis_bp_shuffle_out_tlast(NUMBER_OF_BP_PCB_SHUFFLE_LANES + i);
			end loop;
			if axis_crossbar3_reset = '1' then
				axis_crossbar3_in_tvalid <= (others => '0');
			end if;
		end if;
	end process;


	crossbar3: entity work.shuffle_crossbar -- use component instantiation to delay binding in if-generate block and prevent errors during elaboration
		generic map (
		 	PLATFORM_ID => PLATFORM_ID,  -- needed to select family-dependent FIFOs
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
			s_axis_tdata  => axis_crossbar3_in_tdata,
			s_axis_tvalid => axis_crossbar3_in_tvalid,
			s_axis_tlast  => axis_crossbar3_in_tlast,
			-- s_axis_tready => axis_bp_crossbar2_in_tready,

			-- Non-blocking AXI-Streaming output
			m_axis_tdata  => axis_crossbar3_out_tdata,
			m_axis_tvalid => axis_crossbar3_out_tvalid,
			m_axis_tlast  => axis_crossbar3_out_tlast,
			-- m_axis_tready => axis_crossbar2_out_tready,

			clk => ct_clk,
			rst => axis_crossbar3_reset_reg,

			-- Control interface (command and reply stream buses)
			ctrl_cmd_dat=> crossbar3_cmd_dat,
			ctrl_cmd_rdy=> crossbar3_cmd_rdy,
			ctrl_rply_dat=> crossbar3_rply_dat,
			ctrl_rply_rdy=> crossbar3_rply_rdy,
			ctrl_clk => CTRL_CLK,
			ctrl_rst => crossbar3_CTRL_RST
		);

end generate CROSSBAR23_GEN;

-- If there are no shuffle links, connect directly to the output of the 1st crossbar if there are aly lanes there
-- Note: There should be at least as many 1st crossbar outputs as the number of GPU lanes.
--NOXBAR2_GEN: if not IMPLEMENT_CROSSBAR2_AND_CROSSBAR3 generate
--	axis_crossbar2_out_tdata <= axis_crossbar1_out_tdata(0 to NUMBER_OF_GPU_LINKS-1);
--	axis_crossbar2_out_tvalid <= axis_crossbar1_out_tvalid(0 to NUMBER_OF_GPU_LINKS-1);
--	axis_crossbar2_out_tlast <= axis_crossbar1_out_tlast(0 to NUMBER_OF_GPU_LINKS-1);
--	-- axis_crossbar1_out_tready(0 to NUMBER_OF_GPU_LINKS-1) <= (others=>'1');
--	ct_clk <= CORR_CLK;
--end generate;

end generate;

end Behavioral;

