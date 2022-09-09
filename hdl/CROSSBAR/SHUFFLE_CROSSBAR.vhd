----------------------------------------------------------------------------------
-- Company: McGill University
-- Engineer: J.-F. Cliche
--
-- Create Date:    14:54:33 01/31/2012
-- Design Name: chFPGA PoC
-- Module Name:    shuffle_CROSSBAR - Behavioral
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
--use work.ip_package.all; -- Import definition of components used in this module

entity shuffle_crossbar is
	GENERIC (
		NUMBER_OF_INPUT_LANES: integer := 16; -- Number of input streams
		NUMBER_OF_OUTPUT_LANES: integer := 8; -- Number of output streams
		NUMBER_OF_OUTPUT_LANES_PER_BIN_SEL: integer := 1;
		EIGHT_BIT_SUPPORT: boolean := FALSE; --
		COMBINE_DATA_FLAGS: boolean := TRUE;
		WORDS_PER_BIN_MAX: integer :=4; --! Maximum number of words that can be present in a bin on one input lane. The 2nd crossbar receives up to 4 words. The 3rd crossbar will can have up to 16 words.
		BINS_PER_FRAME_MAX: integer :=64; --! Maximum number of bins per frame
		BIN_SEL_FIFO_TYPE_MAP: integer_16xN_array := (0 to 15 => (0 to 3=>0, others=>0)); -- 0= Block RAM., 1=Dist RAM. By default, for every BIN_SEL, 10 FIFOS are made of BRAM and the rest is made of distributed RAM to maximize area utilization efficiency
		SHUFFLE_FLAGS_MASK: slv32 -- Mask to apply to the shuffle flags to count packet errors
		);
	PORT(

		-- Non-blocking input stream from the backplane shuffle receiver
		s_axis_tvalid: in slv(0 to NUMBER_OF_INPUT_LANES-1);
		s_axis_tdata: in slv32_array(0 to NUMBER_OF_INPUT_LANES-1);
		s_axis_tlast: in slv(0 to NUMBER_OF_INPUT_LANES-1);
		-- s_axis_tready: out slv(0 to NUMBER_OF_INPUT_LANES-1);
		-- s_axis_clk: in std_logic_vector(0 to NUMBER_OF_INPUT_LANES-1); -- clock from each channelizer

		-- Non-blocking output stream
		m_axis_tvalid: out slv(0 to NUMBER_OF_OUTPUT_LANES-1);
		m_axis_tdata: out slv32_array(0 to NUMBER_OF_OUTPUT_LANES-1);
		m_axis_tlast: out slv(0 to NUMBER_OF_OUTPUT_LANES-1);
		-- m_axis_tready: in slv(0 to NUMBER_OF_OUTPUT_LANES-1);

		-- frame_clk_in: in std_logic;
		clk: in  std_logic; -- clocks all align, remap and bin selection and output bus logic.
		rst: in std_logic;

		align_pulse: out std_logic;

		-- Control interface (command and reply stream buses)
		ctrl_cmd_dat: in AXIS8_DAT_STRUCT;
		ctrl_cmd_rdy: out AXIS8_RDY_STRUCT;
		ctrl_rply_dat: out AXIS8_DAT_STRUCT;
		ctrl_rply_rdy: in AXIS8_RDY_STRUCT;
		ctrl_clk: in  std_logic;
		ctrl_rst : in  std_logic
		);

end shuffle_crossbar;

architecture Behavioral of shuffle_crossbar is

	attribute keep:string;
	attribute equivalent_register_removal: string;
	attribute async_reg: string;
	attribute shreg_extract: string;

	constant NUMBER_OF_BIN_SEL: integer := NUMBER_OF_OUTPUT_LANES/NUMBER_OF_OUTPUT_LANES_PER_BIN_SEL;

	signal ctrl_rst_reg: std_logic;
	signal rst_reg: std_logic;

	-- Internally routed command buses
	-- We have one bus for global control, and one bus for each bin selector.
	signal xbar_cmd_dat: AXIS8_DAT_STRUCT_ARRAY(NUMBER_OF_BIN_SEL downto 0);
	signal xbar_cmd_rdy: AXIS8_RDY_STRUCT_ARRAY(NUMBER_OF_BIN_SEL downto 0);
	signal xbar_rply_dat: AXIS8_DAT_STRUCT_ARRAY(NUMBER_OF_BIN_SEL downto 0);
	signal xbar_rply_rdy: AXIS8_RDY_STRUCT_ARRAY(NUMBER_OF_BIN_SEL downto 0);

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


	signal bin_ctr : unsigned(9 downto 0); -- Up to 1024 bins per frame
	signal lane_map: slv4_array(0 to NUMBER_OF_INPUT_LANES-1);
	signal sof_window_stop: std_logic_vector(7 downto 0);
	signal ignore_lane:  slv(0 to NUMBER_OF_INPUT_LANES-1);

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

	signal header_capture_enable: std_logic;
	signal header_capture_enable_reg: std_logic;
	attribute ASYNC_REG of header_capture_enable_reg : signal is "true";
	signal header_capture_word_ctr: unsigned(3 downto 0);
	signal frame_number_capture: slv8_array(0 to NUMBER_OF_INPUT_LANES-1);
	signal stream_id_capture: slv8_array(0 to NUMBER_OF_INPUT_LANES-1);
	signal frame_number_capture_reg: slv8_array(0 to NUMBER_OF_INPUT_LANES-1);
	signal stream_id_capture_reg: slv8_array(0 to NUMBER_OF_INPUT_LANES-1);

	signal align_lane_monitor_source: std_logic_vector(3 downto 0);
	signal align_lane_monitor: slv(0 to NUMBER_OF_INPUT_LANES-1);

	signal lane0_tfirst_mon: std_logic;
	signal fifo_tfirst_mon: std_logic_vector(0 to NUMBER_OF_INPUT_LANES-1);
	signal fifo_count_mon: slv10_array(0 to NUMBER_OF_INPUT_LANES-1);
	signal fifo_count_mon_reg: slv10_array(0 to NUMBER_OF_INPUT_LANES-1);


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

crossbar_router0: entity work.CTRL_ROUTER
	GENERIC MAP (
		NUMBER_OF_PORTS => NUMBER_OF_BIN_SEL + 1,  -- one bus per BIN_SEL, plus one common register bank
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
--! SHUFFLE_CROSSBAR Memory Map
--! ------------------------------------------------------------------------------
--! |  Page   | Addr|Bit(s)|     Name             | Description                   |
--! |---------|-----|------|----------------------|-------------------------------|
--! | CONTROL |  0  |   7  | header_capture_enable    | |
--! |         |     |   6  | align_reset              | manually resets the align module |
--! |         |     |   5  | remap_reset              | manually resets the remap module |
--! |         |     |   4  | lane_monitor_reset       | resets the lane monitoring statistics|
--! |         |     |  3:0 | lane_monitor_sel         | Selects for which lane lane monitoring statistics are presented|
--! |         |  1  |  7   | (unused)                 | Unused|
--! |         |     | 6:3  | align_lane_monitor_source| Selects the Align module lane monitoring signal (only if compile option is provided) |
--! |         |     | 2:0 | (unused)                  | Unused |
--! |         |  2  | 7:0  | sof_window_stop          | Sets how long after the start of lane 0 ALIGN will wait for the start of the other lanes. Passed this, late lanes will be discarded. |
--! |         |3-6/10| 7:0  | lane_map                | Lanes input map. N/s bytes, where N is the numeb rof input lanes. Each 4-bit nibble is an input lane number.|
--! | STATUS  |  0  |   7  | data_fifo_empty          | EMPTY status flag of the DATA FIFO for antenna processor 0. Active HIGH. |
--! |         |     |   6  | data_align_fifo_overflow       | Sticky flag indicating that one of the DATA FIFO has overflown. Cleared only by a reset of the module.|
--! |         |     | 5:0  | '0'                      | Unused   |
--! |         |  1  |  7:0 | FRAME_CTR                | Counts the number of frames written into the FIFOs. Rolls over.|
--! | RAM     | 0-63 | -   | MASK_RAM                 | Word selection map. Each of the 512 bit indicates whether the corresponding word (frequency bin pair) is retained by this correlator. |
--! ------------------------------------------------------------------------------


--! CONTROL Byte 0
header_capture_enable         <= CONTROL_BYTES(0)(7); --!
align_reset                   <= CONTROL_BYTES(0)(6); --!
remap_reset                   <= CONTROL_BYTES(0)(5); --!
lane_monitor_reset            <= CONTROL_BYTES(0)(4); --!
lane_monitor_sel              <= unsigned(CONTROL_BYTES(0)(3 downto 0)); --!

--! CONTROL Byte 1
-- CONTROL_BYTES(1)(7) unused
align_lane_monitor_source <= CONTROL_BYTES(1)(6 downto 3); --!

--! CONTROL Byte 2
sof_window_stop <= CONTROL_BYTES(2);

-- CONTROL Bytes 3-4

ignore_lane <= reverse_bits_and_dir(to_slv(CONTROL_BYTES(3 to 4))(NUMBER_OF_INPUT_LANES-1 downto 0));

--! CONTROL Bytes 5-12 (crossbar2) or 5-8 (crossbar3)
lane_map_gen: for i in 0 to NUMBER_OF_INPUT_LANES-1 generate
	lane_map(i) <= CONTROL_BYTES(5+i/2)((i mod 2)*4+3 downto (i mod 2)*4); --
end generate;


STATUS_BYTES(0)(0) <='0';
STATUS_BYTES(0)(1) <= fifo_tfirst_mon(to_integer(lane_monitor_sel));
STATUS_BYTES(0)(2) <= bad_eof_sticky(to_integer(lane_monitor_sel));
STATUS_BYTES(0)(3) <= bad_lane_sticky(to_integer(lane_monitor_sel));
STATUS_BYTES(0)(4) <= discarded_data_sticky(to_integer(lane_monitor_sel));
STATUS_BYTES(0)(5) <= missing_frame_sticky(to_integer(lane_monitor_sel));
STATUS_BYTES(0)(6) <= align_fifo_overflow_sticky(to_integer(lane_monitor_sel));

--! STATUS Byte 1
STATUS_BYTES(1)(3 downto 0) <= to_slv(NUMBER_OF_OUTPUT_LANES, 4);
STATUS_BYTES(1)(7 downto 4) <= to_slv(NUMBER_OF_BIN_SEL, 4);

--! STATUS Byte 2
STATUS_BYTES(2) <= to_slv(input_frame_ctr(to_integer(lane_monitor_sel)));

--! STATUS Byte 3
STATUS_BYTES(3) <= to_slv(align_frame_ctr(to_integer(lane_monitor_sel)));

--! STATUS Byte 4
STATUS_BYTES(4) <= to_slv(output_frame_ctr(to_integer(lane_monitor_sel)));

--! STATUS Byte 5
STATUS_BYTES(5) <= to_slv(clk_ctr);

--! STATUS Byte 6
-- STATUS_BYTES(6)(1) <= capture_tvalid;
-- STATUS_BYTES(6)(2) <= capture_tlast;
-- STATUS_BYTES(6)(3) <= header_capture_enable;
STATUS_BYTES(6)(7) <= '0';
STATUS_BYTES(6)(6) <= lane0_tfirst_mon;
STATUS_BYTES(6)(5) <= '0';
STATUS_BYTES(6)(4 downto 0) <= to_slv(NUMBER_OF_INPUT_LANES, 5);

-- STATUS_BYTES(7 to 10) <= to_slv8_array(capture_tdata);

status_bytes(7)       <= frame_number_capture_reg(to_integer(lane_monitor_sel));
status_bytes(8)       <= stream_id_capture_reg(to_integer(lane_monitor_sel));
status_bytes(9 to 10) <= to_slv8_array(delay_capture_ref_word_ctr) when lane_monitor_sel=0 else to_slv8_array(delay_capture_word_ctr);
status_bytes(11 to 12) <= to_slv8_array(fifo_count_mon_reg(to_integer(lane_monitor_sel)));
status_bytes(13 to 14) <= to_slv8_array(packet_error_ctr(to_integer(lane_monitor_sel)));
--! STATUS Byte 8
-- STATUS_BYTES(8)<=resize(reverse_bits_and_dir(m_axis_fifo_tvalid),8);

--! STATUS Byte 0
-- STATUS_BYTES(0)(7)<=data_fifo_empty(0);
-- STATUS_BYTES(0)(6)<=DATA_OVERFLOW;
-- STATUS_BYTES(0)(5)<=reset_all;
-- STATUS_BYTES(0)(4)<=to_std_logic(EIGHT_BIT_SUPPORT);
-- STATUS_BYTES(0)(3)<='0'; --or_reduce(in_dat_align_underflow);
-- STATUS_BYTES(0)(2 downto 0)<=(others=>'0');


-----------------------------------------------------------------------------------
-- Memory-Mapped interface instantiation
-----------------------------------------------------------------------------------
--! Instantiates a memory-mapped interface to the control and status bytes
CTRL_SLAVE0: entity work.CTRL_SLAVE
	GENERIC MAP (
		NUMBER_OF_CONTROL_BYTES=>CONTROL_BYTES'Length(1), --
		NUMBER_OF_STATUS_BYTES=>STATUS_BYTES'Length(1), --
		DEFAULT_CONTROL_BYTES=> X"80_07_64_1032547698BADCFE0000",
		USE_FIFO => FALSE
 	)

	PORT MAP(
		-- Control interface (command and reply stream buses)
		-- CTRL_CMD_IN_DAT => (TDATA=>xbar_cmd_dat(0).TDATA, TVALID=>xbar_cmd_dat(0).TVALID, TLAST=>xbar_cmd_dat(0).TLAST, DUMMY =>'0'),
		CTRL_CMD_IN_DAT => xbar_cmd_dat(0),
		-- CTRL_CMD_IN_RDY => xbar_cmd_rdy(0), -- does not work in sim
		CTRL_CMD_IN_RDY.TREADY => xbar_cmd_rdy(0).TREADY, --works in sim
		CTRL_RPLY_OUT_DAT => xbar_rply_dat(0),
		CTRL_RPLY_OUT_RDY.TREADY => xbar_rply_rdy(0).TREADY,
		CTRL_CLK => CTRL_CLK,
		CTRL_RST => ctrl_rst_reg,

		CONTROL_BYTES => CONTROL_BYTES,
		STATUS_BYTES => STATUS_BYTES
	);

---------------------------------------------------------------------
--! CHANNELIZER FIFO
---------------------------------------------------------------------
--! Implements an elastic FIFO that allows for frame alignment to compensate
--! for the multiphase channelizer clocks and compensate for the programmable
--! data acquisition delay used to compensate cable length.
--!
--! The reading of each the FIFO is orchestrated by the ALIGN module in order to allow the frames to be aligned.
--!
--! The Channelizer FIFO block below also generates a pre-FIFO frame clock that is used as a fixed timing reference by the ALIGN module to determining when the frames should start.
--! This is needed to avoid the ALIGNER to accumulate delays beyond the capacity of the FIFO.
--!
--! The channelizer FIFO is instantiated here instead of the Channelizer module because the channelizer data can be easily pipelined since it is a non-blocking AXI-Streamig interface.
--! Also, the ALIGN module has a large number of combinatorial connections to the FIFO module.
--! Keeping the two close will make timing colure easier to acheive.

-- frame_ctr_proc: process(clk)
-- 	begin
-- 		if rising_edge(clk) then
-- 			if s_axis_tvalid(0)='1' and s_axis_tlast(0)='1' then  -- if any lane has valid data
-- 				input_frame_ctr <= input_frame_ctr + 1;
-- 			end if;
-- 		end if; -- clk
-- 	end process;

indet_gen: for i in 0 to NUMBER_OF_INPUT_LANES-1 generate
	in_frame_det_proc: process(clk)
	begin
		if rising_edge(clk) then
			if rst_reg='1' then
				s_axis_tfirst(i) <= '1';
			elsif s_axis_tvalid(i)='1' then
				s_axis_tfirst(i) <= s_axis_tlast(i);
			end if;

			if lane_monitor_reset='1' or rst_reg='1' then
				input_frame_detection(i)<='0';
				input_frame_ctr(i) <= (others=> '0');
			elsif s_axis_tvalid(i)='1' and s_axis_tlast(i)='1' then  -- if end of frame
				input_frame_detection(i)<='1';
				input_frame_ctr(i) <= input_frame_ctr(i) + 1;
			end if;
		end if; -- clk
	end process;
end generate;

-- Capture various stats on the internal signals
capture_proc: process(clk)
begin
	if rising_edge(clk) then
		-- if rst_reg='1' then
		-- 	capture_word_ctr <= (others=> '0');
		-- 	capture_word_ctr_en <= '0';
		-- 	capture_done <= '0';
		-- elsif s_axis_tvalid(0)='1' then
		-- 	capture_word_ctr_en <= '1';
		-- end if;
		-- if capture_word_ctr_en = '1' and capture_done='0' then
		-- 	capture_word_ctr <= capture_word_ctr +1;
		-- 	if capture_word_ctr = capture_word_number then
		-- 		capture_done <= '1';
		-- 		capture_tdata <= s_axis_tdata(to_integer(lane_monitor_sel));
		-- 		capture_tvalid <= s_axis_tvalid(to_integer(lane_monitor_sel));
		-- 		capture_tlast <= s_axis_tlast(to_integer(lane_monitor_sel));
		-- 	end if;
		-- end if;
		header_capture_enable_reg <= header_capture_enable;

		-- Capture header information
		if rst_reg='1' then
			header_capture_word_ctr <= (others=>'0');
		elsif m_axis_align_global_tvalid='1' then
			if m_axis_align_global_tlast='1' then
				header_capture_word_ctr <= (others=>'0');
			elsif signed(header_capture_word_ctr) /= -1 then
				header_capture_word_ctr <= header_capture_word_ctr + 1 ;
			end if;


			for i in 0 to NUMBER_OF_INPUT_LANES-1 loop
				if header_capture_enable_reg = '1' and header_capture_word_ctr=0 then
					stream_id_capture(i) <= m_axis_align_tdata(i)(23 downto 16);
				end if;
				if header_capture_enable_reg = '1' and header_capture_word_ctr=3 then
					frame_number_capture(i) <= m_axis_align_tdata(i)(7 downto 0);
				end if;
			end loop;
		end if;

		-- Pipeline as an attempt to facilitate routing
		stream_id_capture_reg <= stream_id_capture;
		frame_number_capture_reg <= frame_number_capture;
		fifo_count_mon_reg <= fifo_count_mon;

		-- Capture delay between lane 0 and selected lane
		-- if rst_reg='1' then
		-- 	delay_capture_word_ctr <= (others=> (others=> '0'));
		-- 	delay_capture_word_ctr_en <= (others=> '1');
		-- else
		-- 	for i in 0 to 1 loop
		-- 		if delay_capture_word_ctr_en(i) = '1'  then
		-- 			delay_capture_word_ctr(i) <= delay_capture_word_ctr(i) + 1;
		-- 			if signed(delay_capture_word_ctr(i))=-2 or s_axis_tvalid(i)='1' then
		-- 				delay_capture_word_ctr_en(i) <= '0';
		-- 			end if;
		-- 		end if;
		-- 	end loop;
		-- end if;

		-- counter: -2: saturate, -1: no start of frame, 0: start and end on same clock, >0, delay between start and end
		if lane_monitor_reset='1' or rst_reg='1' then
			delay_capture_word_ctr <= (others=> '1');
			delay_capture_word_ctr_en <= '0';
			delay_capture_word_ctr_arm <= '1';
		else
			-- start counting on ref start of frame
			if delay_capture_word_ctr_arm = '1' and s_axis_tvalid(0)='1' and s_axis_tfirst(0)='1' then
				delay_capture_word_ctr <= (0=>'1', others=> '0');
				delay_capture_word_ctr_en <= '1';
				delay_capture_word_ctr_arm <= '0';
			end if;
			-- stop counting on target lane end of frame
			if signed(delay_capture_word_ctr)=-3 or (s_axis_tvalid(to_integer(lane_monitor_sel))='1' and s_axis_tfirst(to_integer(lane_monitor_sel))='1') then
				delay_capture_word_ctr_en <= '0';
			end if;
			if delay_capture_word_ctr_en = '1'  then
				delay_capture_word_ctr <= delay_capture_word_ctr + 1;
			end if;
		end if;

		align_pulse <= align_lane_monitor(to_integer(lane_monitor_sel));


		if rst_reg='1' then
			delay_capture_ref_word_ctr <= (others=> '0');
			delay_capture_ref_word_ctr_en <= '1';
		else
			if delay_capture_ref_word_ctr_en = '1'  then
				delay_capture_ref_word_ctr <= delay_capture_ref_word_ctr + 1;
				if signed(delay_capture_ref_word_ctr)=-2 or s_axis_tvalid(0)='1' then
					delay_capture_ref_word_ctr_en <= '0';
				end if;
			end if;
		end if;

	end if; -- clk
end process;


---------------------------------------------------------------------
--! ALIGN
---------------------------------------------------------------------
--! Control the Channelizer FIFO readout in  order to align the frames.
--! Aligning the frames is necessary because we need to grab data from multiple lanes at a time based on a single selection map.
--!
--! The align module also handles missing and malformed frames, but this is not an issue here since
--! data is coming straight from the channelizer through the internal FPGA routing, which will not cause packet loss.
 --! The only exception to this are for channels that do not send data due to missing ADC cards, inwhich case the ALIGN will handle those automatically.
align_rst_prog: process(clk)
	begin
	if rising_edge(clk) then
		align_reset_all <= rst_reg or align_reset;
	end if;
end process;

align0: entity work.ALIGN
	generic map (
		NUMBER_OF_LANES => NUMBER_OF_INPUT_LANES
		)
	port map(
		-- Data from the channelizers outputs (AXI Streaming, blocking)
		s_axis_tvalid => s_axis_tvalid,
		s_axis_tdata  => s_axis_tdata,
		s_axis_tlast  => s_axis_tlast,

		-- Data to the remapper (AXI Streaming, non-blocking)
		m_axis_global_tvalid => m_axis_align_global_tvalid,
		m_axis_global_tlast  => m_axis_align_global_tlast,
		m_axis_tvalid        => m_axis_align_tvalid,
		m_axis_tdata         => m_axis_align_tdata,
		m_axis_tlast         => m_axis_align_tlast,

		sof_window_stop => sof_window_stop,
		ignore_lane => ignore_lane,


		fifo_overflow => align_fifo_overflow,
		missing_frame => missing_frame,
		bad_frame_length => discarded_data,
		lane0_tfirst_mon => lane0_tfirst_mon,
		fifo_tfirst_mon => fifo_tfirst_mon,
		fifo_count_mon => fifo_count_mon,


		-- Additional debugging monitoring, not enabled by default
		lane_monitor_source => align_lane_monitor_source,
		lane_monitor => align_lane_monitor,

		clk => clk,
		rst => align_reset_all
		);

--- Bypass the align module for debugging
-- m_axis_align_tvalid <= s_axis_tvalid;
-- m_axis_align_tdata <= s_axis_tdata;
-- m_axis_align_tlast <= s_axis_tlast;

---------------------------------------------------------------------
-- REMAP
---------------------------------------------------------------------
-- Routes any data stream from any any input lane to internal REMAP/BIN_SEL
-- lane. This is used to compensate for slot-dependent lane ordering caused by
-- the backplane wiring, or for reordering bin order depending on whether we
-- use a crate shuffle or not.
--
-- The REMAP module is a non-blocking AXI-S interface.
--
-- It is instantiated here in the data chain since we need to delay the data
-- relative to the bin counter as required by the bin selector module (to allow
-- it time to lookup its bin selection map RAM).
--
remap0: entity work.remap
	generic map (
		NUMBER_OF_INPUT_LANES => NUMBER_OF_INPUT_LANES,
		NUMBER_OF_OUTPUT_LANES => NUMBER_OF_INPUT_LANES
		)
    port map (
		-- Input from the align module (non-blocking, i.e. always accept data)
		s_axis_tvalid => m_axis_align_tvalid,
		s_axis_tdata  => m_axis_align_tdata,
		s_axis_tlast  => m_axis_align_tlast,

		-- Output to the bin selector (non-blocking, i.e. always sends data)
		m_axis_tvalid => m_axis_remap_tvalid,
		m_axis_tdata  => m_axis_remap_tdata,
		m_axis_tlast  => m_axis_remap_tlast,

		lane_map => lane_map,
		clk => clk,
		rst => rst_reg or remap_reset
  );



bin_ctr_proc: process(clk)
	begin
		if rising_edge(clk) then

			-- Add a pipelining level to facilitate routing. This signal goes to many places across the chip.
			m_axis_remap_tdata_reg <= m_axis_remap_tdata;
			m_axis_remap_tlast_reg <= m_axis_remap_tlast;
			m_axis_remap_tvalid_reg <= m_axis_remap_tvalid;
			if rst_reg = '1' then -- reset the pipeline
				m_axis_remap_tvalid_reg <= (others=> '0');
			end if;

			clk_ctr <= clk_ctr + 1;
			-- frame_clk_dly <= frame_clk(0);

			-- if frame_clk(0)='1' and frame_clk_dly='0' then
			-- 	frame_clk_ctr <= frame_clk_ctr + 1 ;
			-- end if;


			-- if m_axis_align_global_tvalid='1' and m_axis_align_global_tlast='1' then  -- if any lane has valid data
			-- 	align_frame_ctr <= align_frame_ctr + 1;
			-- end if;


			if rst_reg='1' or lane_monitor_reset='1' then
				align_fifo_overflow_sticky <= (others=>'0');
				missing_frame_sticky <= (others=>'0');
				discarded_data_sticky <= (others=>'0');
			else
				align_fifo_overflow_sticky <= align_fifo_overflow_sticky or align_fifo_overflow;
				missing_frame_sticky <= missing_frame_sticky or missing_frame;
				discarded_data_sticky <= discarded_data_sticky or discarded_data;
			end if;

			for i in 0 to NUMBER_OF_INPUT_LANES-1 loop
				if lane_monitor_reset='1' or rst_reg='1' then
					align_frame_detection(i)<='0';
					align_frame_ctr(i) <= (others => '0');
				elsif m_axis_align_tvalid(i)='1' and m_axis_align_tlast(i)='1'  then  -- if end of frame
					align_frame_detection(i)<='1';
					align_frame_ctr(i) <= align_frame_ctr(i) + 1;
				end if;

				if lane_monitor_reset='1' or rst_reg='1' then
					remap_frame_detection(i)<='0';
				elsif m_axis_remap_tvalid(i)='1' and m_axis_remap_tlast(i)='1'  then  -- if end of frame
					remap_frame_detection(i)<='1';
				end if;

				if lane_monitor_reset='1' or rst_reg='1' then
					bad_lane_sticky(i) <='0';
					bad_eof_sticky(i) <='0';
				else
					if m_axis_align_global_tvalid='1' and m_axis_align_tvalid(i)='0' then
						bad_lane_sticky(i) <= '1';
					end if;
					if m_axis_align_global_tvalid='1' and m_axis_align_tvalid(i)='1' and (m_axis_align_global_tlast /= m_axis_align_tlast(i)) then
						bad_eof_sticky(i) <= '1';
					end if;
				end if;

			end loop;

			for i in 0 to NUMBER_OF_OUTPUT_LANES-1 loop
				if lane_monitor_reset='1' or rst_reg='1' then
					output_frame_detection(i)<='0';
					output_frame_ctr(i) <= (others=> '0');
					packet_error_ctr(i) <= (others=> '0');
				elsif m_axis_tvalid_int(i)='1' and m_axis_tlast_int(i)='1'  then  -- if end of frame
					output_frame_detection(i) <= '1';
					output_frame_ctr(i) <= output_frame_ctr(i) + 1;
					if m_axis_terror_int(i)='1' and signed(packet_error_ctr(i)) /= -1 then
						packet_error_ctr(i) <= packet_error_ctr(i) + 1;
					end if;
				end if;
			end loop;
		end if; -- clk
	end process;


m_axis_tdata <= m_axis_tdata_int;
m_axis_tvalid <= m_axis_tvalid_int;
m_axis_tlast <= m_axis_tlast_int;

BIN_SEL_GEN: for i in 0 to NUMBER_OF_BIN_SEL-1 generate
	----------------------------------------
	--! Instantiate a bin selector
	----------------------------------------
	binsel_i: entity work.shuffle_bin_sel
		GENERIC MAP (
			BIN_SEL_NUMBER => i,
			NUMBER_OF_INPUTS => NUMBER_OF_INPUT_LANES,
			NUMBER_OF_OUTPUTS => NUMBER_OF_OUTPUT_LANES_PER_BIN_SEL,
			COMBINE_DATA_FLAGS => COMBINE_DATA_FLAGS,
			WORDS_PER_BIN_MAX => WORDS_PER_BIN_MAX,
			BINS_PER_FRAME_MAX => BINS_PER_FRAME_MAX,
			FIFO_TYPE_MAP => BIN_SEL_FIFO_TYPE_MAP(i)
			)
		PORT MAP(
			-- Input from remap (non blocking)

			s_axis_global_tvalid => m_axis_align_global_tvalid, -- This signal must precede the actual data by 2 clocks
			s_axis_global_tlast  => m_axis_align_global_tlast, -- This signal must precede the actual data by 2 clocks
			s_axis_tdata         => m_axis_remap_tdata_reg,
			s_axis_tvalid        => m_axis_remap_tvalid_reg,
			s_axis_tlast         => m_axis_remap_tlast_reg,


			-- Output to the shuffle module (non blocking)
			m_axis_tdata => m_axis_tdata_int(i*NUMBER_OF_OUTPUT_LANES_PER_BIN_SEL to (i+1)*NUMBER_OF_OUTPUT_LANES_PER_BIN_SEL-1),
			m_axis_tvalid => m_axis_tvalid_int(i*NUMBER_OF_OUTPUT_LANES_PER_BIN_SEL to (i+1)*NUMBER_OF_OUTPUT_LANES_PER_BIN_SEL-1),
			m_axis_tlast => m_axis_tlast_int(i*NUMBER_OF_OUTPUT_LANES_PER_BIN_SEL to (i+1)*NUMBER_OF_OUTPUT_LANES_PER_BIN_SEL-1),
			m_axis_terror => m_axis_terror_int(i*NUMBER_OF_OUTPUT_LANES_PER_BIN_SEL to (i+1)*NUMBER_OF_OUTPUT_LANES_PER_BIN_SEL-1),

			-- lane_map => lane_map,

			rst => rst_reg,
			clk => clk, --! common clock for both the input and output

			shuffle_flags_mask => SHUFFLE_FLAGS_MASK,

			-- Control Interface
			-- ctrl_cmd_dat=> (TVALID=>xbar_cmd_dat(i+1).TVALID, TDATA=>xbar_cmd_dat(i+1).TDATA, TLAST=>xbar_cmd_dat(i+1).TLAST, DUMMY=>'0'),
			ctrl_cmd_dat=> xbar_cmd_dat(i+1),
			ctrl_cmd_rdy=> xbar_cmd_rdy(i+1),
			ctrl_rply_dat=> xbar_rply_dat(i+1),
			ctrl_rply_rdy=> xbar_rply_rdy(i+1),
			ctrl_clk => CTRL_CLK,
			ctrl_rst=> ctrl_rst_reg
		);
end generate;

end Behavioral;

