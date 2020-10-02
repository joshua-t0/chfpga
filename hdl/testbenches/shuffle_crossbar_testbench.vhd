--------------------------------------------------------------------------------
-- @file
-- Company:
-- Engineer:
--
-- Create Date:   17:23:04 11/17/2010
-- Design Name:
-- Module Name:   C:/Xilinx/work/CHIME/SP605_test2/ADCDAQ/ADC_IOSERDES_testbench.vhd
-- Project Name:  ADCDAQ
-- Target Device:
-- Tool versions:
-- Description:
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes:
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

library work;
USE work.chFPGA_Package.all;
use work.tb_package.all;

ENTITY shuffle_crossbar_testbench IS
	generic (
		NUMBER_OF_INPUT_LANES: integer := 16; -- Must be a multiple of 4
		NUMBER_OF_OUTPUT_LANES: integer := 4;
		NUMBER_OF_OUTPUT_LANES_PER_BIN_SEL: integer := 4;
		COMBINE_DATA_FLAGS: boolean := TRUE
		);
END shuffle_crossbar_testbench;


ARCHITECTURE behavior OF shuffle_crossbar_testbench IS

   -- Clock period definitions

constant IN_CLK_PERIOD : time := 5 ns; -- 200 MHz
constant OUT_CLK_PERIOD : time := 4.096 ns; -- 244 MHz
constant CLK125_period : time := 8 ns;

	-- SYSTEM Port modules
	constant CROSSBAR_BASE_ADDR      : integer := 16#60000#; -- # CROSSBAR top address
	constant CROSSBAR_ADDR_INCREMENT : integer := 16#00800#; --
	constant CROSSBAR_BIN_SEL0_ADDR: integer :=CROSSBAR_BASE_ADDR + 1*CROSSBAR_ADDR_INCREMENT;
	constant CROSSBAR_BIN_SEL1_ADDR: integer :=CROSSBAR_BASE_ADDR + 2*CROSSBAR_ADDR_INCREMENT;
	constant NUMBER_OF_BIN_SEL: integer := NUMBER_OF_OUTPUT_LANES / NUMBER_OF_OUTPUT_LANES_PER_BIN_SEL;
	--Inputs
	signal reset : std_logic := '0';


	signal in_clk: std_logic; --
	signal out_clk: std_logic; --
	signal clk125: std_logic; --
	signal frame_clk_in: std_logic;

	signal s_axis_tdata: slv32;
	signal s_axis_tvalid: std_logic; -- needed for sim. If, U, data will not start
	signal s_axis_tlast: std_logic;
	signal s_axis_tready: std_logic:='1'; -- init needed for sim


	signal s_axis_tdata_int: slv32_array(0 to NUMBER_OF_INPUT_LANES-1);
	signal s_axis_tvalid_int: std_logic_vector(0 to NUMBER_OF_INPUT_LANES-1); -- needed for sim. If, U, data will not start
	signal s_axis_tlast_int: std_logic_vector(0 to NUMBER_OF_INPUT_LANES-1);

	signal m_axis_tdata_int: slv32_array(0 to NUMBER_OF_OUTPUT_LANES-1);
	signal m_axis_tvalid_int: std_logic_vector(0 to NUMBER_OF_OUTPUT_LANES-1); -- needed for sim. If, U, data will not start
	signal m_axis_tlast_int: std_logic_vector(0 to NUMBER_OF_OUTPUT_LANES-1);

	signal m_axis_tdata: slv32;
	signal m_axis_tvalid: std_logic;
	signal m_axis_tlast: std_logic;
	signal m_axis_tuser: slv4;

	signal cmd_tdata: slv8;
	signal cmd_tvalid: std_logic;
	signal cmd_tlast: std_logic;
	signal cmd_tready: std_logic;

	-- constant NUMBER_OF_PACKETS : integer :=5;
	-- type lane_config_type is array (0 to NUMBER_OF_INPUT_LANES-1) of integer_array(0 to NUMBER_OF_PACKETS-1);
	-- -- back to back frames, same length, aligned within timeout
	-- -- constant start_delay: integer_array := (4,0,2);
	-- -- constant interpacket_delay: integer_array := (0,0,0);
	-- -- constant packet_length: integer_array := (8,8,8);

	-- -- -- back to back frames, same length, aligned within timeout except missing frame
	-- -- constant PL: integer := 20;
	-- -- constant PP: integer := 22;
	-- -- constant start_delay: integer_array          := (0=> 4,          1=> 0,          2=> 2);
	-- -- constant packet_length: lane_config_type     := (0=>(others=>PL), 1=>(1=>0, others=>PL), 2=>(others=>PL));
	-- -- constant packet_period: lane_config_type     := (others=> (others=>PP));

	-- constant PL: integer := 20;
	-- constant PP: integer := 22;
	-- constant start_delay: integer_array          := (0=> 0,          1=> 6,          2=> 0);
	-- constant packet_length: lane_config_type     := (0=>(others=>PL), 1=>(1=>0, others=>PL), 2=>(others=>PL));
	-- constant packet_period: lane_config_type     := (others=> (others=>PP));


	-- signal t1: slv8;
	-- signal t2,t3: std_logic;
begin



-- data(0) <= (X"A0A0A0A0", X"A1A1A1A1", X"A2A2A2A2", X"A3A3A3A3", X"A4A4A4A4", X"A5A5A5A5", X"A6A6A6A6", X"A7A7A7A7");


frame_clk_in <= s_axis_tvalid and s_axis_tlast;
s_axis_tdata_int <= (others=> s_axis_tdata);
--s_axis_tvalid_int <= (3=>'0', others=>s_axis_tvalid);
s_axis_tvalid_int <= (others=>s_axis_tvalid);
s_axis_tlast_int <= (others=> s_axis_tlast);
dut0: entity work.shuffle_crossbar
	generic map (
		NUMBER_OF_INPUT_LANES => NUMBER_OF_INPUT_LANES, -- Number of input streams
		NUMBER_OF_OUTPUT_LANES => NUMBER_OF_OUTPUT_LANES, -- Number of output streams
		NUMBER_OF_OUTPUT_LANES_PER_BIN_SEL => NUMBER_OF_OUTPUT_LANES_PER_BIN_SEL,
		COMBINE_DATA_FLAGS => COMBINE_DATA_FLAGS,
		BIN_SEL_FIFO_TYPE_MAP => (0 to NUMBER_OF_OUTPUT_LANES-1 => (others=> 0)),
		SHUFFLE_FLAGS_MASK => X"70000700"
		)
	port map (
		s_axis_tdata  => s_axis_tdata_int,
		s_axis_tvalid => s_axis_tvalid_int,
		s_axis_tlast  => s_axis_tlast_int,
		-- s_axis_tuser  => (others=>"0101"), --(ADC overflow, scaler even, scaler odd, FFT overflow)
		-- s_axis_clk => (others=>in_clk),
		-- s_axis_tready => s_axis_tready,

		m_axis_tdata  => m_axis_tdata_int,
		m_axis_tvalid => m_axis_tvalid_int,
		m_axis_tlast  => m_axis_tlast_int,
		-- m_axis_tready(0)  => '1',

		-- frame_clk_in => frame_clk_in,
		clk =>out_clk,
		rst => reset,

		-- CTRL_CMD_DAT => (TDATA=> cmd_tdata, TVALID => cmd_tvalid, TLAST => cmd_tlast, DUMMY =>'0'),
		CTRL_CMD_DAT.TDATA => cmd_tdata,
		CTRL_CMD_DAT.TVALID => cmd_tvalid,
		CTRL_CMD_DAT.TLAST => cmd_tlast,
		CTRL_CMD_DAT.DUMMY => '0',

		CTRL_CMD_RDY.TREADY =>cmd_tready,
		CTRL_RPLY_DAT => open,
		CTRL_RPLY_RDY => (TREADY => '1'),
		CTRL_CLK => clk125,
		CTRL_RST => reset
	);

m_axis_tdata  <= m_axis_tdata_int(0);
m_axis_tvalid <= m_axis_tvalid_int(0);
m_axis_tlast  <= m_axis_tlast_int(0);

in_clk_process :process
   begin
		in_clk <= '0';
		wait for IN_CLK_PERIOD/2;
		in_clk <= '1';
		wait for IN_CLK_PERIOD/2;
   end process;

out_clk_process :process
   begin
		out_clk <= '0';
		wait for OUT_CLK_PERIOD/2;
		out_clk <= '1';
		wait for OUT_CLK_PERIOD/2;
   end process;

clk125_process :process
   begin
		clk125 <= '0';
		wait for clk125_period/2;
		clk125 <= '1';
		wait for clk125_period/2;
   end process;

stim_proc : process
	variable number_of_selected_bins: integer :=64;
	variable number_of_bins_per_frame: integer :=64;
	variable number_of_words_per_bin: integer :=4;
	variable first_lane: integer := 0;
	variable last_lane: integer := 1;
	variable number_of_frames_per_packet: integer :=1;
	variable number_of_input_data_flags_words_per_bin: integer := 1;
	begin
		reset <= '1';
		sleep(out_clk, 10);
		reset <= '0';
		sleep(clk125, 10); -- make sure we start command transmission on a CLK125 edge or we will lose some data
		-- fpga_write_control(clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, CROSSBAR_BASE_ADDR + 0, 0); --

		for i in 0 to NUMBER_OF_BIN_SEL-1 loop
			fpga_write_control(       clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, CROSSBAR_BIN_SEL0_ADDR + i*CROSSBAR_ADDR_INCREMENT + 0, number_of_input_data_flags_words_per_bin * 16 + first_lane); -- Set the number of words to select
			fpga_write_control(       clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, CROSSBAR_BIN_SEL0_ADDR + i*CROSSBAR_ADDR_INCREMENT + 3, number_of_bins_per_frame); -- Set the number of words to select
			fpga_write_control(       clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, CROSSBAR_BIN_SEL0_ADDR + i*CROSSBAR_ADDR_INCREMENT + 4, number_of_words_per_bin); -- Set the number of words to select
			fpga_write_control(       clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, CROSSBAR_BIN_SEL0_ADDR + i*CROSSBAR_ADDR_INCREMENT + 5, number_of_frames_per_packet*32 + last_lane); -- Set the range of inputs to capture (0 to NUMBER_OF_CROSSBAR_INPUTS-1)
			fpga_select_bins( clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, CROSSBAR_BIN_SEL0_ADDR + i*CROSSBAR_ADDR_INCREMENT, first_bin=>0, bin_step=>1, number_of_bins=>number_of_selected_bins); -- Enable storage and transmission of N frequency bins.
			-- wait for 2*64*SYSCLK_period; -- prevent the buffers from overflowing by allowing time to send the ethernet framing
			-- fpga_read(       clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, CROSSBAR_BIN_SEL0_ADDR + 16#200#, 3); -- Re-read the first 8 bytes of the map for debugging
		end loop;

		sleep(out_clk,20);
		-- sleep(clk,start_delay(i));
		for j in 0 to 100 loop
			send_axis32_packet(out_clk, s_axis_tdata, s_axis_tvalid, s_axis_tlast, s_axis_tready,
				create_packet(16#FA#, j ,
				4 + number_of_frames_per_packet * (number_of_words_per_bin * number_of_bins_per_frame + number_of_bins_per_frame + 1) + 1),
				number_of_frames_per_packet * 624); -- 512*244/200=625 clocks = actual duration of  the incoming frames
			-- sleep(clk,1);
		end loop;
		wait;
	end process ; -- lane0_proc

END;
