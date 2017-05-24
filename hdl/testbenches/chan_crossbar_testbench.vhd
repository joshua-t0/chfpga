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
--USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.ALL;

library work;
USE work.chFPGA_Package.all;
--use work.util_package.all;
use work.tb_package.all;

ENTITY chan_crossbar_testbench IS
	generic (
		NUMBER_OF_INPUT_LANES: integer := 16; -- Must be a multiple of 4
		NUMBER_OF_OUTPUT_LANES: integer := 16
		);
END chan_crossbar_testbench;


ARCHITECTURE behavior OF chan_crossbar_testbench IS

   -- Clock period definitions

constant IN_CLK_PERIOD : time := 5.0 ns; -- 200 MHz
constant OUT_CLK_PERIOD : time := 4.096 ns; -- 244 MHz
constant CLK125_period : time := 8 ns;

-- SYSTEM Port modules
constant CROSSBAR_BASE_ADDR      : integer := 16#20000#; -- # CROSSBAR top address
constant CROSSBAR_ADDR_INCREMENT : integer := 16#00800#; --
constant CROSSBAR_BIN_SEL0_ADDR: integer := CROSSBAR_BASE_ADDR + 1*CROSSBAR_ADDR_INCREMENT;
constant CROSSBAR_BIN_SEL1_ADDR: integer := CROSSBAR_BASE_ADDR + 2*CROSSBAR_ADDR_INCREMENT;

--Inputs
signal reset : std_logic := '0';


signal in_clk: std_logic; --
signal in_clk_dly: std_logic_vector(0 to NUMBER_OF_INPUT_LANES-1) := (others=>'0'); -- needed for sim. If, U, data will not start
signal out_clk: std_logic; --
signal clk125: std_logic; --
signal config_done: std_logic := '0';

type DELAY_ARRAY is array (natural range <>) of time;
constant CLK_DLY: DELAY_ARRAY(0 to 7) := (0 ns, 625 ps, 2*625 ps, 3*625 ps, 4*625 ps, 5*625 ps, 6*625 ps, 7*625 ps);

signal s_axis_tdata: slv32_array(0 to NUMBER_OF_INPUT_LANES-1) := (others=> (others=>'0'));
signal s_axis_tvalid: std_logic_vector(0 to NUMBER_OF_INPUT_LANES-1) := (others=>'0'); -- needed for sim. If, U, data will not start
signal s_axis_tlast: std_logic_vector(0 to NUMBER_OF_INPUT_LANES-1):= (others=>'0');
signal s_axis_tready: std_logic_vector(0 to NUMBER_OF_INPUT_LANES-1):=(others=>'1'); -- init needed for sim

signal m_axis_fifo_tdata: slv32_array(0 to NUMBER_OF_INPUT_LANES-1);
signal m_axis_fifo_tvalid: std_logic_vector(0 to NUMBER_OF_INPUT_LANES-1);
signal m_axis_fifo_tlast: std_logic_vector(0 to NUMBER_OF_INPUT_LANES-1);
signal m_axis_fifo_tuser: slv4_array(0 to NUMBER_OF_INPUT_LANES-1);
	-- signal m_axis_fifo_tready: std_logic_vector(0 to NUMBER_OF_LANES-1);

signal m_axis_tdata: slv32_array(0 to NUMBER_OF_OUTPUT_LANES-1);
signal m_axis_tvalid: std_logic_vector(0 to NUMBER_OF_OUTPUT_LANES-1);
signal m_axis_tlast: std_logic_vector(0 to NUMBER_OF_OUTPUT_LANES-1);

signal cmd_tdata: slv8;
signal cmd_tvalid: std_logic;
signal cmd_tlast: std_logic;
signal cmd_tready: std_logic := '1'; -- to allow sim without DUT

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

	function create_chan_packet(count: in integer) return slv32_array is
		variable word_array: slv32_array(0 to count-1);
		begin
			for i in 0 to count-1 loop
				word_array(i) := to_slv(i/16 mod 16,4) & "0000" & to_slv(i mod 16,4) & "0000" & to_slv(i,16);
			end loop;
			return word_array;
		end function;

begin

lane_gen: for i in 0 to NUMBER_OF_INPUT_LANES-1 generate

	fifo0: entity work.chan_fifo
		port map (
			-- Input interface (non-blocking, i.e. always accept data)

			s_axis_tvalid => s_axis_tvalid(i),
			s_axis_tdata => s_axis_tdata(i),
			s_axis_tlast => s_axis_tlast(i),
			s_axis_tuser => "1100", --(ADC overflow, scaler even, scaler odd, FFT overflow)
			s_axis_clk => in_clk_dly(i),

			m_axis_tvalid => m_axis_fifo_tvalid(i),
			m_axis_tdata => m_axis_fifo_tdata(i),
			m_axis_tlast => m_axis_fifo_tlast(i),
			m_axis_tuser => m_axis_fifo_tuser(i),
			m_axis_tready => '1', -- always stream data
			m_axis_clk => out_clk,

			-- frame_clk => frame_clk(i), --! Frame clock, toggling on the first word of each frame fed INTO the fifo. The data will appear a few FIFO latency cycles later. This is used by the frame aligner to detect frame timeout.

			rst => reset
		);

end generate;

dut0: entity work.chan_crossbar
	generic map (
		NUMBER_OF_INPUT_LANES=>NUMBER_OF_INPUT_LANES, -- Number of input streams
		NUMBER_OF_OUTPUT_LANES=>NUMBER_OF_OUTPUT_LANES -- Number of output streams
		)
	port map (
		s_axis_tdata  => m_axis_fifo_tdata,
		s_axis_tvalid => m_axis_fifo_tvalid,
		s_axis_tlast  => m_axis_fifo_tlast,
		s_axis_tuser  => m_axis_fifo_tuser,
		-- s_axis_tready => s_axis_tready,

		m_axis_tdata  => m_axis_tdata,
		m_axis_tvalid => m_axis_tvalid,
		m_axis_tlast  => m_axis_tlast,
		-- m_axis_tready(0)  => '1',

		clk => out_clk,
		rst => reset,

		CTRL_CMD_DAT.TDATA => cmd_tdata,
		CTRL_CMD_DAT.TVALID => cmd_tvalid,
		CTRL_CMD_DAT.TLAST => cmd_tlast,
		CTRL_CMD_DAT.DUMMY =>'0',
		CTRL_CMD_RDY.TREADY =>cmd_tready,
		CTRL_RPLY_DAT => open,
		CTRL_RPLY_RDY => (TREADY => '1'),
		CTRL_CLK => clk125,
		CTRL_RST => reset
	);

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

conf_proc : process
	variable number_of_selected_bins: integer :=128;
	variable first_fifo_var: integer := 0;
	variable last_fifo_var: integer := 3;
	variable combine_data_flags_var: integer := 0;
	begin
		reset <= '1';
		sleep(out_clk, 10);
		reset <= '0';
		report "RESET done!";
		sleep(clk125, 10); -- make sure we start command transmission on a CLK125 edge or we will lose some data
		report "Starting configuration";
		fpga_write_control(clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready,  0, 0); --
		-- crash_me(clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready,  0, 0); --

		for i in 1 to NUMBER_OF_OUTPUT_LANES loop
			-- fpga_write(       clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, CROSSBAR_BIN_SEL0_ADDR + i*CROSSBAR_ADDR_INCREMENT + 4, 1); -- Set the number of frames per packet
			fpga_write_control(       clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, i*CROSSBAR_ADDR_INCREMENT + 3, number_of_selected_bins); -- Set the number of words to select
			fpga_write_control(       clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, i*CROSSBAR_ADDR_INCREMENT + 4, combine_data_flags_var*16 + first_fifo_var*4 + last_fifo_var); -- Set the range of inputs to capture (0 to NUMBER_OF_CROSSBAR_INPUTS-1)
			fpga_select_bins( clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, i*CROSSBAR_ADDR_INCREMENT, first_bin=>0, bin_step=>8, number_of_bins=>number_of_selected_bins); -- Enable storage and transmission of N frequency bins.
			-- wait for 2*64*SYSCLK_period; -- prevent the buffers from overflowing by allowing time to send the ethernet framing
			-- fpga_read(       clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, CROSSBAR_BIN_SEL0_ADDR + 16#200#, 3); -- Re-read the first 8 bytes of the map for debugging
		end loop;
		report "Done configuration";
		config_done <= '1';
		sleep(clk125, 10);
		wait;
	end process ;

packet_gen: for i in 0 to NUMBER_OF_INPUT_LANES-1 generate

	-- in_clk_dly(i) <= in_clk after i*10 ps;
	in_clk_dly(i) <= transport in_clk after (i mod 8)*625 ps;
	packet_proc : process
		begin
			wait until config_done='1';
			sleep(in_clk_dly(i), 10);
			for j in 0 to 100 loop
				send_axis32_packet(in_clk_dly(i), s_axis_tdata(i), s_axis_tvalid(i), s_axis_tlast(i), s_axis_tready(i), create_chan_packet(512));
				-- sleep(clk,1);
			end loop;
			wait;
		end process;
end generate;

END;
