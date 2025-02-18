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

-- Ultrascale corner-turn engine -
--
-- Supports 8 channelizer inputs
-- Each channelizer inputs packs four (4+4)-bit bin values into a 32-bit value (low bin in MSB)
entity u_ct_engine is
	GENERIC (
		PLATFORM_ID: integer; -- necessary to select the proper FIFOs
		NUMBER_OF_INPUT_LANES: integer := 8; -- Number of channelizer inputs
        BINS_PER_INPUT_WORD: integer := 4;
        INPUT_WORD_WIDTH: integer := 32;
		CT_LEVEL: integer := 2; -- Corner-turning level: 1: single-board (local) only (no backplane), 2: Option 1 plus 4x4 subbackplane corner-turn (4 boards, using GTY), 3: Option 2 + additional 4x4 corner-turn between 2 or 4 sub-backplanes (8 or 16 boards)
		LANE_TO_LINK_MAP: integer_array  := (-1, 0, 1, 2); -- List indictiong the GTY link number associated to each lane. -1 means a bypass  lane (no GTY, stays internal to the board).
		LINK_TO_QUAD_MAP: integer_array  := (0,1,1); -- Indicates which quad is associated to each GTY link.
		QUAD_TO_REFCLK_MAP: integer_array:= (0,0); -- Indicates which refclk is associated with each QUAD
        LANE_TO_GROUP_MAP: integer_array := (0, 0, 0, 0); -- Indicates to which lane group each lane is associated with

        -- Dervived parameters
        OUTPUT_WIDTH: integer := NUMBER_OF_INPUT_LANES * INPUT_WORD_WIDTH;  -- assumes inputs are 32 bits wide, and CT preserves data rate
        NUMBER_OF_LINKS: integer        := max(LANE_TO_LINK_MAP) + 1; --  Number of physical data links (GTYs) - Do not override
    	NUMBER_OF_REFCLK: integer       := max(QUAD_TO_REFCLK_MAP) + 1; -- Number of reference clocks - Do not override
        BITS_PER_BIN: integer := INPUT_WORD_WIDTH / BINS_PER_INPUT_WORD ;-- Supporting only 4+4 bits/bin
		PRE_DECIMATE: boolean := CT_LEVEL > 1 -- True if we want to decimate the first 256 bins of the spectrum before entering the backplane shuffle
--		NUMBER_OF_OUTPUT_LANES: integer := 8; -- Number of output streams
--		WORDS_PER_BIN_MAX: integer :=4; --! Maximum number of words that can be present in a bin on one input lane. The 2nd crossbar receives up to 4 words. The 3rd crossbar will can have up to 16 words.
--		BINS_PER_FRAME_MAX: integer :=64; --! Maximum number of bins per frame
--		BIN_SEL_FIFO_TYPE_MAP: integer_16xN_array := (0 to 15 => (0 to 3=>0, others=>0)); -- 0= Block RAM., 1=Dist RAM. By default, for every BIN_SEL, 10 FIFOS are made of BRAM and the rest is made of distributed RAM to maximize area utilization efficiency
--		SHUFFLE_FLAGS_MASK: slv32 -- Mask to apply to the shuffle flags to count packet errors
		);
	PORT(

		-- Non-blocking input stream from the channelizer, synchronous to `axis_clk
		-- We assume all lanes are aligned and therefore share a common `tvalid` and `tlast`
		s_axis_tdata: in slv32_array(0 to NUMBER_OF_INPUT_LANES-1); -- data from each channelizer, each of which contains 4x (4+4)-bit bin values
		s_axis_tvalid: in std_logic;
		s_axis_tlast: in std_logic;

		-- Non-blocking output stream, synchronous to `axis_clk`
		m_axis_tvalid: out std_logic;
		m_axis_tdata: out slv(OUTPUT_WIDTH-1 downto 0);
		m_axis_tlast: out std_logic;

		axis_clk: in  std_logic; -- AXI-S bus clocks. Tie to clk_out if the backplane links are enabled

		-- Backplane data shuffle

		tx_p     : out std_logic_vector(0 to NUMBER_OF_LINKS-1);
		tx_n     : out std_logic_vector(0 to NUMBER_OF_LINKS-1);
		rx_p     : in std_logic_vector(0 to NUMBER_OF_LINKS-1);
		rx_n     : in std_logic_vector(0 to NUMBER_OF_LINKS-1);
		refclk_p : in std_logic_vector(0 to NUMBER_OF_REFCLK-1);
		refclk_n : in std_logic_vector(0 to NUMBER_OF_REFCLK-1);

		refclk_div2: out std_logic_vector(0 to NUMBER_OF_REFCLK-1); -- divided-by-two version of the 156.25 MHz reference clock fed to the QUAD PLL
		txclk_div2: out std_logic; -- divided-by-two version of the TX word clock, which is also clk_out

		txclk_out: out std_logic; -- Word clock from the GTY TX link
		-- frame_clk_in: in std_logic;

		rst: in std_logic;
		arst: in std_logic; -- aync reset, NOT synchronized on txclk_out as arst stops the clock
        resetdone: out std_logic;

--		align_pulse: out std_logic;

		-- Control interface (command and reply stream buses)
		bsb_cmd_dat: in AXIS8_DAT_STRUCT;
		bsb_cmd_rdy: out AXIS8_RDY_STRUCT;
		bsb_rply_dat: out AXIS8_DAT_STRUCT;
		bsb_rply_rdy: in AXIS8_RDY_STRUCT;
		bsb_clk: in  std_logic;
		bsb_rst : in  std_logic
		);

end u_ct_engine;

architecture Behavioral of u_ct_engine is

	attribute keep:string;
	attribute equivalent_register_removal: string;
	attribute async_reg: string;
	attribute shreg_extract: string;

	constant CT1_OUTPUT_LANES: integer := BINS_PER_INPUT_WORD;
    constant CT1_LANE_WIDTH: integer := NUMBER_OF_INPUT_LANES * BITS_PER_BIN;

	constant BSB_CT1_BASE_PORT : integer := 0; -- Top-level address of the CT-Engine 1st crossbar.
	constant BSB_CT2_BASE_PORT : integer := 1; -- Top-level address of the CT-Engine 2nd crossbar
	constant BSB_CT3_BASE_PORT : integer := 2; -- Top level address of the CT-Engine 3rd crossbar
	constant BSB_BP_SHUFFLE_BASE_PORT: integer := 3; -- Top level address of the CT-Engine backplane shuffle subsystem.
	constant BSB_ROUTER_PORTS        : integer := 4; -- Total number of router output ports.

--	constant NUMBER_OF_BIN_SEL: integer := NUMBER_OF_OUTPUT_LANES/NUMBER_OF_OUTPUT_LANES_PER_BIN_SEL;

--	signal ctrl_rst_reg: std_logic;
--	signal rst_reg: std_logic;

	-- Routed BSB buses for each device
	signal router_cmd_dat: AXIS8_DAT_STRUCT_ARRAY(0 to BSB_ROUTER_PORTS-1);
	signal router_cmd_rdy: AXIS8_RDY_STRUCT_ARRAY(0 to BSB_ROUTER_PORTS-1);
	signal router_rply_dat: AXIS8_DAT_STRUCT_ARRAY(0 to BSB_ROUTER_PORTS-1);
	signal router_rply_rdy: AXIS8_RDY_STRUCT_ARRAY(0 to BSB_ROUTER_PORTS-1);

    signal bsb_rst_reg: std_logic;
    signal cb1_rst: std_logic;

begin

	ctrl_rst_proc: process(all)
    begin
        if rising_edge(bsb_clk) then
            bsb_rst_reg <= bsb_rst;
        end if; -- RST/CLK
    end process;


	---------------------------------------------------------------------
	-- ROUTER
	---------------------------------------------------------------------
	-- Routes the commands and replies to/from the corner-turn engine submodules

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



	-- First corner turn (internal corner-turn)
	ct1_blk: block

		signal control_bytes: slv8_array(0 to 0); -- default value set in the CMD_SLAVE
		signal status_bytes: slv8_array(0 to 0);

        --signal cb1_in_tdata: slv_array(0 to NUMBER_OF_INPUT_LANES-1)(INPUT_WORD_WIDTH-1 downto 0);
        signal cb1_in_tdata: slv32_array(0 to NUMBER_OF_INPUT_LANES-1);
        signal cb1_in_tvalid: std_logic;
        signal cb1_in_tlast: std_logic;

        signal cb1_out_tdata: slv_array(0 to CT1_OUTPUT_LANES-1)(CT1_LANE_WIDTH-1 downto 0);
        signal cb1_out_tvalid: std_logic;
        signal cb1_out_tlast: std_logic;

	begin

		-- Pipeline BSB reset
		-- Note; Putting two `if rising_edge(clk)`` in the same process crashed Vivado simulator 2008.
		process(all) begin
			if rising_edge(bsb_clk) then
				bsb_rst_reg <= bsb_rst;
			end if; -- bsb_clk
--        end process;

--		process(all) begin
            if rising_edge(axis_clk) then
                cb1_rst <= rst;
            end if; -- RST/CLK
        end process;

		-- Instantiate level-1 corner turning registers
		ct1_regs0: entity work.CTRL_SLAVE
			GENERIC MAP (
				NUMBER_OF_CONTROL_BYTES => control_bytes'LENGTH(1), --
				NUMBER_OF_STATUS_BYTES => status_bytes'LENGTH(1), --
				DEFAULT_CONTROL_BYTES => X"00"
		 	)

			PORT MAP(
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

		-- Perform the crossbar operation
		process(all)
		  variable rlane, rbin: integer; -- reverse lane and bin numbers
		  variable lsb: integer;
		begin
			if rising_edge(axis_clk) then

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
				for bin in 0 to BINS_PER_INPUT_WORD-1 loop -- 0 to 3
				    rbin := BINS_PER_INPUT_WORD-1 - bin;
					for input_lane in 0 to NUMBER_OF_INPUT_LANES-1 loop -- 0 to 7
					   rlane := NUMBER_OF_INPUT_LANES-1 - input_lane; -- reverse input lane,  7 to 0
					   lsb := BITS_PER_BIN * rlane;
					   cb1_out_tdata(bin)(lsb+BITS_PER_BIN-1 downto lsb) <= cb1_in_tdata(input_lane)(BITS_PER_BIN*(rbin+1)-1 downto BITS_PER_BIN*rbin);
					end loop;
				end loop;
                cb1_out_tvalid <= cb1_in_tvalid  when not cb1_rst else '0';
                cb1_out_tlast <= cb1_in_tlast;
            end if; -- clk
		end process;

	-- ******

	ct2_gen: if not (CT_LEVEL >= 2) generate -- If we do NOT have level 2 corner-turning
	begin
		process(all)
		  variable lsb: integer;
		  variable rlane: integer; -- reverse lane
		begin
			-- If there is no level 2 corner-turning, then assign crossbar 1 outputs directly to the output bus
			-- We repack the cb1 output lane into a single word for the correlator.
            -- CT1 lane 0 is in the MSB. Channelizer 0 value is in the MSB. Re part of value is on the MSB.
			if rising_edge(axis_clk) then
			    for lane in 0 to CT1_OUTPUT_LANES-1 loop
                    rlane := CT1_OUTPUT_LANES-1 - lane;
    				m_axis_tdata(CT1_LANE_WIDTH*(rlane+1)-1 downto  CT1_LANE_WIDTH*rlane) <= cb1_out_tdata(lane);
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
		signal align1_rst_reg: std_logic;


		--Control and status bytes
		signal control_bytes: slv8_array(0 to (2 + (NUMBER_OF_CT2_INPUTS+1)/2 + 2)); -- default value set in the CMD_SLAVE
		signal status_bytes: slv8_array(0 to 14);


		-- Remap1 control and status signals
		signal lane_map: slv4_array(0 to NUMBER_OF_CT2_INPUTS-1);

		-- Align1 control and status signals

--		signal bin_ctr : unsigned(9 downto 0); -- Up to 1024 bins per frame
		signal align1_ignore_lane:  slv(0 to NUMBER_OF_CT2_INPUTS-1);
		signal align1_sof_window_stop: std_logic_vector(7 downto 0);


		signal header_capture_enable: std_logic;
		signal header_capture_enable_reg: std_logic;
		attribute ASYNC_REG of header_capture_enable_reg : signal is "true";
		signal header_capture_word_ctr: unsigned(3 downto 0);
		signal frame_number_capture: slv8_array(0 to NUMBER_OF_CT2_INPUTS-1);
		signal stream_id_capture: slv8_array(0 to NUMBER_OF_CT2_INPUTS-1);
		signal frame_number_capture_reg: slv8_array(0 to NUMBER_OF_CT2_INPUTS-1);
		signal stream_id_capture_reg: slv8_array(0 to NUMBER_OF_CT2_INPUTS-1);

		signal align1_lane_monitor_source: std_logic_vector(3 downto 0);
		signal align1_lane_monitor: slv(0 to NUMBER_OF_CT2_INPUTS-1);

		signal align1_lane0_tfirst_mon: std_logic;
		signal align1_fifo_tfirst_mon: std_logic_vector(0 to NUMBER_OF_CT2_INPUTS-1);
		signal align1_fifo_count_mon: slv10_array(0 to NUMBER_OF_CT2_INPUTS-1);
		signal fifo_count_mon_reg: slv10_array(0 to NUMBER_OF_CT2_INPUTS-1);


        ---

        -- resets
        signal remap_rst: std_logic;
        signal bp_rst: std_logic;
        signal align1_rst: std_logic;

        signal word_ctr: unsigned(10 downto 0);

		signal remap_out_tdata: slv_array(0 to NUMBER_OF_CT2_INPUTS-1)(BITS_PER_CT2_LANE_WORD-1 downto 0);
		signal remap_out_tvalid: std_logic_vector(0 to NUMBER_OF_CT2_INPUTS-1);
		signal remap_out_tlast: std_logic_vector(0 to NUMBER_OF_CT2_INPUTS-1);


--		signal bp1_in_tdata: slv64_array(0 to NUMBER_OF_CT2_INPUTS-1);
--		signal bp1_in_tvalid: slv(0 to NUMBER_OF_CT2_INPUTS-1);
--		signal bp1_in_tlast: slv(0 to NUMBER_OF_CT2_INPUTS-1);

		signal bp1_out_tdata: slv_array(0 to NUMBER_OF_CT2_OUTPUTS-1)(BITS_PER_CT2_LANE_WORD-1 downto 0);
		signal bp1_out_tvalid: slv(0 to NUMBER_OF_CT2_OUTPUTS-1);
		signal bp1_out_tlast: slv(0 to NUMBER_OF_CT2_OUTPUTS-1);


        -- Align buses

	    signal align1_out_tdata: slv_array(0 to NUMBER_OF_CT2_OUTPUTS-1)(BITS_PER_CT2_LANE_WORD-1 downto 0);
	    signal align1_out_tvalid: std_logic_vector(0 to NUMBER_OF_CT2_OUTPUTS-1);
	    signal align1_out_tlast: std_logic_vector(0 to NUMBER_OF_CT2_OUTPUTS-1);
	    signal align1_out_global_tvalid: std_logic;
	    signal align1_out_global_tlast: std_logic;


        -- Align monitoring
        signal lane_monitor:  std_logic_vector(0 to NUMBER_OF_CT2_OUTPUTS-1);
    --	signal lane_monitor_sel: unsigned(3 downto 0);
    --	signal lane_monitor_reset: std_logic;
    --	signal input_frame_detection:  std_logic_vector(0 to NUMBER_OF_INPUT_LANES-1);
    --	-- signal fifo_frame_detection:  std_logic_vector(0 to NUMBER_OF_INPUT_LANES-1);
    --	signal align_frame_detection:  std_logic_vector(0 to NUMBER_OF_INPUT_LANES-1);
    --	signal remap_frame_detection:  std_logic_vector(0 to NUMBER_OF_INPUT_LANES-1);
    --	signal output_frame_detection: std_logic_vector(0 to NUMBER_OF_OUTPUT_LANES-1);
    	signal align1_fifo_overflow: std_logic_vector(0 to NUMBER_OF_CT2_OUTPUTS-1);
    	signal align1_fifo_overflow_sticky: std_logic_vector(0 to NUMBER_OF_CT2_OUTPUTS-1);
    	signal align1_missing_frame: std_logic_vector(0 to NUMBER_OF_CT2_OUTPUTS-1);
    --	signal missing_frame_sticky: std_logic_vector(0 to NUMBER_OF_INPUT_LANES-1);
    	signal align1_discarded_data: std_logic_vector(0 to NUMBER_OF_CT2_OUTPUTS-1);
    --	signal discarded_data_sticky: std_logic_vector(0 to NUMBER_OF_INPUT_LANES-1);
    --	signal bad_lane_sticky: std_logic_vector(0 to NUMBER_OF_INPUT_LANES-1);
    --	signal bad_eof_sticky: std_logic_vector(0 to NUMBER_OF_INPUT_LANES-1);

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
			GENERIC MAP (
				NUMBER_OF_CONTROL_BYTES => control_bytes'LENGTH(1), --
				NUMBER_OF_STATUS_BYTES => status_bytes'LENGTH(1), --
				DEFAULT_CONTROL_BYTES => X"80_07_64_0000_0123"
		 	)

			PORT MAP(
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
		--! CONTROL Byte 0
--		header_capture_enable         <= CONTROL_BYTES(0)(7); --!
--		align_reset                   <= CONTROL_BYTES(0)(6); --!
--		remap_reset                   <= CONTROL_BYTES(0)(5); --!
--		lane_monitor_reset            <= CONTROL_BYTES(0)(4); --!
--		lane_monitor_sel              <= unsigned(CONTROL_BYTES(0)(3 downto 0)); --!

		--! CONTROL Byte 1
		-- CONTROL_BYTES(1)(7) unused
		align1_lane_monitor_source <= CONTROL_BYTES(1)(6 downto 3); --!

		--! CONTROL Byte 2
		align1_sof_window_stop <= CONTROL_BYTES(2);

		-- CONTROL Bytes 3-4

		align1_ignore_lane <= reverse_bits_and_dir(to_slv(CONTROL_BYTES(3 to 4))(NUMBER_OF_CT2_INPUTS-1 downto 0));

		--! CONTROL Bytes 5-12 (crossbar2) or 5-8 (crossbar3)
		lane_map_gen: for i in 0 to NUMBER_OF_CT2_INPUTS-1 generate
			lane_map(i) <= CONTROL_BYTES(5+i/2)(((i+1) mod 2)*4+3 downto ((i+1) mod 2)*4); --
		end generate;


		STATUS_BYTES(0)(0) <='0';
--		STATUS_BYTES(0)(1) <= fifo_tfirst_mon(to_integer(lane_monitor_sel));
--		STATUS_BYTES(0)(2) <= bad_eof_sticky(to_integer(lane_monitor_sel));
--		STATUS_BYTES(0)(3) <= bad_lane_sticky(to_integer(lane_monitor_sel));
--		STATUS_BYTES(0)(4) <= discarded_data_sticky(to_integer(lane_monitor_sel));
--		STATUS_BYTES(0)(5) <= missing_frame_sticky(to_integer(lane_monitor_sel));
--		STATUS_BYTES(0)(6) <= align_fifo_overflow_sticky(to_integer(lane_monitor_sel));

		--! STATUS Byte 1
--		STATUS_BYTES(1)(3 downto 0) <= to_slv(NUMBER_OF_OUTPUT_LANES, 4);
--		STATUS_BYTES(1)(7 downto 4) <= to_slv(NUMBER_OF_BIN_SEL, 4);

		--! STATUS Byte 2
--		STATUS_BYTES(2) <= to_slv(input_frame_ctr(to_integer(lane_monitor_sel)));

		--! STATUS Byte 3
--		STATUS_BYTES(3) <= to_slv(align_frame_ctr(to_integer(lane_monitor_sel)));

		--! STATUS Byte 4
--		STATUS_BYTES(4) <= to_slv(output_frame_ctr(to_integer(lane_monitor_sel)));

		--! STATUS Byte 5
--		STATUS_BYTES(5) <= to_slv(clk_ctr);

		--! STATUS Byte 6
		-- STATUS_BYTES(6)(1) <= capture_tvalid;
		-- STATUS_BYTES(6)(2) <= capture_tlast;
		-- STATUS_BYTES(6)(3) <= header_capture_enable;
--		STATUS_BYTES(6)(7) <= '0';
--		STATUS_BYTES(6)(6) <= align1_lane0_tfirst_mon;
--		STATUS_BYTES(6)(5) <= '0';
--		STATUS_BYTES(6)(4 downto 0) <= to_slv(NUMBER_OF_INPUT_LANES, 5);

--		 STATUS_BYTES(7 to 10) <= to_slv8_array(capture_tdata);

--		status_bytes(7)       <= frame_number_capture_reg(to_integer(lane_monitor_sel));
--		status_bytes(8)       <= stream_id_capture_reg(to_integer(lane_monitor_sel));
--		status_bytes(9 to 10) <= to_slv8_array(delay_capture_ref_word_ctr) when lane_monitor_sel=0 else to_slv8_array(delay_capture_word_ctr);
--		status_bytes(11 to 12) <= to_slv8_array(fifo_count_mon_reg(to_integer(lane_monitor_sel)));
--		status_bytes(13 to 14) <= to_slv8_array(packet_error_ctr(to_integer(lane_monitor_sel)));
--		! STATUS Byte 8
--		 STATUS_BYTES(8)<=resize(reverse_bits_and_dir(m_axis_fifo_tvalid),8);

--		! STATUS Byte 0
--		 STATUS_BYTES(0)(7)<=data_fifo_empty(0);
--		 STATUS_BYTES(0)(6)<=DATA_OVERFLOW;
--		 STATUS_BYTES(0)(5)<=reset_all;
--		 STATUS_BYTES(0)(4)<=to_std_logic(EIGHT_BIT_SUPPORT);
--		 STATUS_BYTES(0)(3)<='0'; --or_reduce(in_dat_align_underflow);
--		 STATUS_BYTES(0)(2 downto 0)<=(others=>'0');




--         Lane remap and bin culling

--		 Remap lanes to be fed to the backplane shuffle in order to
--		 route bin sets to specific destination slots. The mapping differs for each slot.

--         Also perform bin culling to allow the data to fit the backplane link bandwidth.
--         To do this, we drop one bin on each of the first 256 words. This means we ibhibit tvalid on one output lane during each of the first 256 words.
--         We rotate the targeted bin on each word, matching the ordering of the bin-rotated order of the FFT, so we end up
--         dropping the first 256 absolute bins of the spectrum.

--         Pre-decimation bandwidth = 400 MHz * 64 bit/output_lane = 25.6 Gbps
--         Post-decimation bandwidth = 400 MHz * 64 bits/output_lane * (8192-256 bins)/(8192 bins) = 24.8 Gbps
		remap_proc: process(all)
			variable source_lane: integer range 0 to NUMBER_OF_CT2_INPUTS-1;
            variable drop_bin: boolean;
		begin
			if rising_edge(axis_clk) then

                if cb1_out_tvalid then
                    word_ctr <= word_ctr + 1 when not cb1_out_tlast else (others => '0');
                end if;
                word_ctr <= (others => '0') when remap_rst;


				for lane in 0 to NUMBER_OF_CT2_INPUTS-1 loop
					source_lane := to_integer(unsigned(lane_map(lane)));
					remap_out_tdata(lane) <= cb1_out_tdata(source_lane);
					drop_bin := PRE_DECIMATE and (word_ctr(10 downto 8) = 0) and (word_ctr(1 downto 0) = source_lane);
	                remap_out_tvalid(lane) <= cb1_out_tvalid when not (??remap_rst or drop_bin) else '0';
					remap_out_tlast(lane) <= cb1_out_tlast;
				end loop;
			end if; -- clk
		end process;



		-- Instantiate backplane links
		-- Used for 1st data shuffle (between 4 boards on the same sub-backplane) and eventually 2nd data shuffle (between sub-backplanes)
		bp_links0: entity work.xxvglink_array
			generic map (
			    LANE_TO_LINK_MAP       => LANE_TO_LINK_MAP, -- 4 logical lane: 1 bypass lane, 3 physical links
				LINK_TO_QUAD_MAP       => LINK_TO_QUAD_MAP, --! Indicates which quad is associated each channel. The QUAD number is an integer between 0 and N-1, where N is the total number of quads used.
				QUAD_TO_REFCLK_MAP     => QUAD_TO_REFCLK_MAP --! Indicates which refclk is associated with each QUAD (N integers from 0 to NUMBER_OF_REFCLK-1).
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

				axis_clk => axis_clk, -- lcock for both AXIS interfaces
                resetdone => resetdone,

				-- Backplane link cloand and related clock monitoring signals
				clk_out    => txclk_out, --! 402.8 MHz clock from TX links (25 Gbps * 66/64 / 64 bits/word =402.83203125 MHz)
				refclk_div2 => refclk_div2, -- divided-by-two version of the 156.25 MHz reference clock fed to the QUAD PLL
				txclk_div2  => txclk_div2, -- divided-by-two version of the TX word clock, which is also clk_out

				-- Control and reply streams
				cmd_dat  => router_cmd_dat(BSB_BP_SHUFFLE_BASE_PORT),
				cmd_rdy  => router_cmd_rdy(BSB_BP_SHUFFLE_BASE_PORT),
				rply_dat => router_rply_dat(BSB_BP_SHUFFLE_BASE_PORT),
				rply_rdy => router_rply_rdy(BSB_BP_SHUFFLE_BASE_PORT),
				ctrl_clk => bsb_clk,
				ctrl_rst => bsb_rst,
				--areset   => bp_shuffle_reset_reg
				areset   => arst -- stops clk_out: must not be sync'ed to clk_out.
			 );

		-- Instantiate packet aligner
		align1: entity work.align64
			generic map (
				NUMBER_OF_LANES => NUMBER_OF_CT2_INPUTS
				)
			port map(
				-- Data from the channelizers outputs (AXI Streaming, blocking)
				s_axis_tvalid => bp1_out_tvalid,
				s_axis_tdata  => bp1_out_tdata,
				s_axis_tlast  => bp1_out_tlast,

				-- Data to the remapper (AXI Streaming, non-blocking)
				m_axis_global_tvalid => align1_out_global_tvalid,
				m_axis_global_tlast  => align1_out_global_tlast,
				m_axis_tvalid        => align1_out_tvalid,
				m_axis_tdata         => align1_out_tdata,
				m_axis_tlast         => align1_out_tlast,


				-- Configuration

				sof_window_stop => align1_sof_window_stop,
				ignore_lane => align1_ignore_lane,

				-- Monitoring

				fifo_overflow => align1_fifo_overflow,
				missing_frame => align1_missing_frame,
				bad_frame_length => align1_discarded_data,
				lane0_tfirst_mon => align1_lane0_tfirst_mon,
				fifo_tfirst_mon => align1_fifo_tfirst_mon,
				fifo_count_mon => align1_fifo_count_mon,


				-- Additional debugging monitoring, not enabled by default
				lane_monitor_source => align1_lane_monitor_source,
				lane_monitor => align1_lane_monitor,

				clk => axis_clk,
				rst => align1_rst
				);

		ct3_gen: if not (CT_LEVEL >= 3) generate
		begin
			-- We have no level-3 corner-turning, so assign the output of the packet aligner to the output bus
			process(all)
			     variable rlane: integer; -- reverse lane number
			begin
				if rising_edge(axis_clk) then
                    for lane in 0 to NUMBER_OF_CT2_INPUTS-1 loop
                        rlane := NUMBER_OF_CT2_INPUTS-1-lane;
                        m_axis_tdata(BITS_PER_CT2_LANE_WORD * (rlane +1) -1  downto BITS_PER_CT2_LANE_WORD * rlane) <= align1_out_tdata(lane);
                    end loop;
					m_axis_tvalid <= '0' when align1_rst_reg else align1_out_global_tvalid;
					m_axis_tlast <= align1_out_global_tlast;
				end if; -- bsb_clk
			end process;

		else generate -- implement Level-3 corner turning

		-- Instantiate registers for level-3 corner turning
			ct3_regs0: entity work.CTRL_SLAVE
				GENERIC MAP (
					NUMBER_OF_CONTROL_BYTES => control_bytes'LENGTH(1), --
					NUMBER_OF_STATUS_BYTES => status_bytes'LENGTH(1), --
					DEFAULT_CONTROL_BYTES => X"00"
			 	)

				PORT MAP(
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

	end block; -- cb1_block


end Behavioral;

