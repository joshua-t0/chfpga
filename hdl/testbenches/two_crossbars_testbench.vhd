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
use IEEE.std_logic_misc.ALL; -- for reduce functions

library work;
USE work.chFPGA_Package.all;
use work.tb_package.all;

ENTITY two_crossbars_testbench IS
	generic (
		NUMBER_OF_INPUT_LANES: integer := 16; -- Must be a multiple of 4
		NUMBER_OF_SHUFFLE_LANES: integer := 2;
		NUMBER_OF_OUTPUT_LANES: integer := 1;
		COMBINE_DATA_FLAGS: boolean := true
		);
END two_crossbars_testbench;


ARCHITECTURE behavior OF two_crossbars_testbench IS

   -- Clock period definitions

constant IN_CLK_PERIOD : time := 5 ns; -- 200 MHz
constant OUT_CLK_PERIOD : time := 4.096 ns; -- 244 MHz
constant CLK125_period : time := 8 ns; -- 125 MHz
constant clk156_PERIOD : time := 6.4 ns; --156.25 MHz

	-- SYSTEM Port modules
	-- SYSTEM Port modules
	constant CROSSBAR1_BASE_ADDR      : integer := 16#20000#; -- # CROSSBAR top address
	constant CROSSBAR1_ADDR_INCREMENT : integer := 16#00800#; --
	constant CROSSBAR1_BIN_SEL0_ADDR: integer :=CROSSBAR1_BASE_ADDR + 1*CROSSBAR1_ADDR_INCREMENT;


	constant CROSSBAR2_BASE_ADDR      : integer := 16#60000#; -- # CROSSBAR top address
	constant CROSSBAR2_ADDR_INCREMENT : integer := 16#00800#; --
	constant CROSSBAR2_BIN_SEL0_ADDR: integer :=CROSSBAR2_BASE_ADDR + 1*CROSSBAR2_ADDR_INCREMENT;

	--Inputs
	signal reset : std_logic := '0';


	signal in_clk: std_logic; --
	signal out_clk: std_logic; --
	signal clk125: std_logic; --
	signal frame_clk_in: std_logic;

	signal init_done : std_logic := '0';

	signal s_axis_tdata: slv32;
	signal s_axis_tvalid: std_logic:='0'; -- needed for sim. If, U, data will not start
	signal s_axis_tlast: std_logic:='0';
	signal s_axis_tready: std_logic:='1'; -- init needed for sim


	signal s_axis_tdata_int: slv32_array(0 to NUMBER_OF_INPUT_LANES-1);
	signal s_axis_tuser_int: slv4_array(0 to NUMBER_OF_INPUT_LANES-1) := (others=> "0000");
	signal s_axis_tvalid_int: std_logic_vector(0 to NUMBER_OF_INPUT_LANES-1) := (others=> '0'); -- needed for sim. If, U, data will not start
	signal s_axis_tlast_int: std_logic_vector(0 to NUMBER_OF_INPUT_LANES-1);
	signal s_axis_clk_int: std_logic_vector(0 to NUMBER_OF_INPUT_LANES-1);

	signal m_axis_fifo_tvalid: slv(0 to NUMBER_OF_INPUT_LANES-1);
	signal m_axis_fifo_tdata: slv32_array(0 to NUMBER_OF_INPUT_LANES-1);
	signal m_axis_fifo_tlast: slv(0 to NUMBER_OF_INPUT_LANES-1);
	signal m_axis_fifo_tuser: slv4_array(0 to NUMBER_OF_INPUT_LANES-1);

	signal axis_shuffle_tdata: slv32_array(0 to NUMBER_OF_SHUFFLE_LANES-1);
	signal axis_shuffle_tvalid: std_logic_vector(0 to NUMBER_OF_SHUFFLE_LANES-1); -- needed for sim. If, U, data will not start
	signal axis_shuffle_tlast: std_logic_vector(0 to NUMBER_OF_SHUFFLE_LANES-1);
	signal axis_shuffle_tready: std_logic_vector(0 to NUMBER_OF_SHUFFLE_LANES-1);

	signal axis_shuffle_tdata_dly1: slv32_array(0 to NUMBER_OF_SHUFFLE_LANES-1);
	signal axis_shuffle_tvalid_dly1: std_logic_vector(0 to NUMBER_OF_SHUFFLE_LANES-1); -- needed for sim. If, U, data will not start
	signal axis_shuffle_tlast_dly1: std_logic_vector(0 to NUMBER_OF_SHUFFLE_LANES-1);

	signal axis_shuffle_tdata_dly2: slv32_array(0 to NUMBER_OF_SHUFFLE_LANES-1);
	signal axis_shuffle_tvalid_dly2: std_logic_vector(0 to NUMBER_OF_SHUFFLE_LANES-1); -- needed for sim. If, U, data will not start
	signal axis_shuffle_tlast_dly2: std_logic_vector(0 to NUMBER_OF_SHUFFLE_LANES-1);

	signal axis_shuffle_tdata_dly3: slv32_array(0 to NUMBER_OF_SHUFFLE_LANES-1);
	signal axis_shuffle_tvalid_dly3: std_logic_vector(0 to NUMBER_OF_SHUFFLE_LANES-1); -- needed for sim. If, U, data will not start
	signal axis_shuffle_tlast_dly3: std_logic_vector(0 to NUMBER_OF_SHUFFLE_LANES-1);

	signal axis_shuffle_tdata_dly: slv32_array(0 to NUMBER_OF_SHUFFLE_LANES-1);
	signal axis_shuffle_tvalid_dly: std_logic_vector(0 to NUMBER_OF_SHUFFLE_LANES-1); -- needed for sim. If, U, data will not start
	signal axis_shuffle_tlast_dly: std_logic_vector(0 to NUMBER_OF_SHUFFLE_LANES-1);

	signal axis_shuffle_out_tdata: slv32_array(0 to NUMBER_OF_SHUFFLE_LANES-1);
	signal axis_shuffle_out_tvalid: std_logic_vector(0 to NUMBER_OF_SHUFFLE_LANES-1); -- needed for sim. If, U, data will not start
	signal axis_shuffle_out_tlast: std_logic_vector(0 to NUMBER_OF_SHUFFLE_LANES-1);

	signal ready: std_logic;
	signal ready_ctr: unsigned(6 downto 0) := (others=>'0');

	signal m_axis_tdata: slv32;
	signal m_axis_tvalid: std_logic;
	signal m_axis_tlast: std_logic;
	signal m_axis_tuser: slv4;

	signal cmd_tdata1: slv8;
	signal cmd_tvalid1: std_logic;
	signal cmd_tlast1: std_logic;
	signal cmd_tready1: std_logic;

	signal cmd_tdata2: slv8;
	signal cmd_tvalid2: std_logic;
	signal cmd_tlast2: std_logic;
	signal cmd_tready2: std_logic;

	signal cmd_tdata3: slv8;
	signal cmd_tvalid3: std_logic;
	signal cmd_tlast3: std_logic;
	signal cmd_tready3: std_logic;


signal clk156_p: std_logic;
signal clk156_n: std_logic;
signal rx_p: std_logic_vector(0 to NUMBER_OF_SHUFFLE_LANES-2);
signal rx_n: std_logic_vector(0 to NUMBER_OF_SHUFFLE_LANES-2);
signal tx_p: std_logic_vector(0 to NUMBER_OF_SHUFFLE_LANES-2);
signal tx_n: std_logic_vector(0 to NUMBER_OF_SHUFFLE_LANES-2);
signal tx_resetdone: std_logic_vector(0 to NUMBER_OF_SHUFFLE_LANES-1); --
signal rx_resetdone: std_logic_vector(0 to NUMBER_OF_SHUFFLE_LANES-1); --



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

	function create_chan_packet(count, chan: in integer) return slv32_array is
		variable word_array: slv32_array(0 to count-1);
		begin
			for i in 0 to count-1 loop
				-- word_array(i) := to_slv(i/16 mod 16,4) & "0000" & to_slv(i mod 16,4) & "0000" & to_slv(i,16);
				-- word_array(i) := to_slv(chan,4) & X"0" & to_slv(chan,4) & X"1" & to_slv(chan,4) & X"2" & to_slv(chan,4) & X"3";
				word_array(i) := to_slv(chan,4) & X"000" & to_slv(chan,4) & X"000";
			end loop;
			return word_array;
		end function;


	-- signal t1: slv8;
	-- signal t2,t3: std_logic;
begin

-- s_axis_tdata_int  <= (others=>s_axis_tdata);
-- s_axis_tvalid_int <= (others=>s_axis_tvalid);
-- s_axis_tlast_int  <= (others=>s_axis_tlast);
-- s_axis_tuser_int  <= (others=>"0101"); --(ADC overflow, scaler even, scaler odd, FFT overflow;

in_clk_process :process
   begin
		in_clk <= '0';
		wait for IN_CLK_PERIOD/2;
		in_clk <= '1';
		wait for IN_CLK_PERIOD/2;
   end process;

clk125_process :process
   begin
		clk125 <= '0';
		wait for clk125_period/2;
		clk125 <= '1';
		wait for clk125_period/2;
   end process;

clk156_process :process
   begin
		clk156_p <= '0';
		clk156_n <= '1';
		wait for clk156_PERIOD/2;
		clk156_p <= '1';
		clk156_n <= '0';
		wait for clk156_PERIOD/2;
   end process;



fifo_gen: for i in 0 to NUMBER_OF_INPUT_LANES-1 generate

	-- s_axis_clk_int(i) <= (others=>in_clk);
	s_axis_clk_int(i) <= in_clk after i*IN_CLK_PERIOD/8;

	fifo0: entity work.chan_fifo
		port map (
			-- Input interface (non-blocking, i.e. always accept data)

			s_axis_tvalid => s_axis_tvalid_int(i),
			s_axis_tdata => s_axis_tdata_int(i),
			s_axis_tlast => s_axis_tlast_int(i),
			s_axis_tuser => s_axis_tuser_int(i),
			s_axis_clk => s_axis_clk_int(i),

			m_axis_tvalid => m_axis_fifo_tvalid(i),
			m_axis_tdata => m_axis_fifo_tdata(i),
			m_axis_tlast => m_axis_fifo_tlast(i),
			m_axis_tuser => m_axis_fifo_tuser(i),
			m_axis_tready => '1',
			m_axis_clk => out_clk,
			frame_clk => open, --! Frame clock, toggling on the first word of each frame fed INTO the fifo. The data will appear a few FIFO latency cycles later. This is used by the frame aligner to detect frame timeout.
			rst => reset
		);
end generate;

crossbar1: entity work.chan_crossbar
	generic map (
		NUMBER_OF_INPUT_LANES=>NUMBER_OF_INPUT_LANES, -- Number of input streams
		NUMBER_OF_OUTPUT_LANES=>NUMBER_OF_SHUFFLE_LANES -- Number of output streams
		)
	port map (
		s_axis_tdata  => m_axis_fifo_tdata,
		s_axis_tvalid => m_axis_fifo_tvalid,
		s_axis_tlast  => m_axis_fifo_tlast,
		s_axis_tuser  => m_axis_fifo_tuser,
		-- s_axis_clk    => s_axis_clk_int,
		-- s_axis_tready => s_axis_tready,

		m_axis_tdata  => axis_shuffle_tdata,
		m_axis_tvalid => axis_shuffle_tvalid,
		m_axis_tlast  => axis_shuffle_tlast,
		m_axis_tready  => axis_shuffle_tready,

		clk => out_clk,
		rst => reset,

		-- CTRL_CMD_DAT => (TDATA=> cmd_tdata1, TVALID => cmd_tvalid1, TLAST => cmd_tlast1),
		CTRL_CMD_DAT.TDATA => cmd_tdata1,
		CTRL_CMD_DAT.TVALID => cmd_tvalid1,
		CTRL_CMD_DAT.TLAST => cmd_tlast1,
		CTRL_CMD_RDY.TREADY =>cmd_tready1,
		CTRL_RPLY_DAT => open,
		CTRL_RPLY_RDY => (TREADY => '1'),
		CTRL_CLK => clk125,
		CTRL_RST => reset
	);

rx_p <= tx_p;
rx_n <= tx_n;

bp_links0: entity work.xglink_array
	generic map (
		LINK_SPEED  => 0,
		NUMBER_OF_BYPASS_LANES => 1,
		NUMBER_OF_TX_LANES => NUMBER_OF_SHUFFLE_LANES-1,
		NUMBER_OF_RX_LANES => NUMBER_OF_SHUFFLE_LANES-1,
		NUMBER_OF_REFCLK => 1,
		LANE_TO_QUAD_MAP => (0 to NUMBER_OF_SHUFFLE_LANES-2 => 0),
		QUAD_TO_REFCLK_MAP => (0=>0),
		SIM => True
		)
	port map (

		tx_p => tx_p,
		tx_n => tx_n,
		rx_p => rx_p,
		rx_n => rx_n,
		refclk_p => (others=> clk156_p),
		refclk_n => (others=> clk156_n),

		s_axis_tx_tdata  => axis_shuffle_tdata,
		s_axis_tx_tvalid => axis_shuffle_tvalid,
		s_axis_tx_tlast  => axis_shuffle_tlast,
		s_axis_tx_tready => axis_shuffle_tready,
		s_axis_tx_clk    => out_clk,
		tx_resetdone => tx_resetdone,

		m_axis_rx_tdata  => axis_shuffle_out_tdata,
		m_axis_rx_tvalid => axis_shuffle_out_tvalid,
		m_axis_rx_tlast  => axis_shuffle_out_tlast,
		m_axis_rx_clk    => (others => out_clk),
		m_axis_rx_tready => (others => '1'),
		rx_resetdone => rx_resetdone,

		areset => reset,

		CMD_DAT => (TDATA=> cmd_tdata3, TVALID => cmd_tvalid3, TLAST => cmd_tlast3),
		CMD_RDY.TREADY =>cmd_tready3,
		RPLY_DAT => open,
		RPLY_RDY => (TREADY => '1'),
		CTRL_CLK => clk125,
		CTRL_RST => reset

	);



-- data(0) <= (X"A0A0A0A0", X"A1A1A1A1", X"A2A2A2A2", X"A3A3A3A3", X"A4A4A4A4", X"A5A5A5A5", X"A6A6A6A6", X"A7A7A7A7");


frame_clk_in <= s_axis_tvalid and s_axis_tlast;
-- s_axis_tdata_int <= (others=> s_axis_tdata);
-- s_axis_tvalid_int <= (3=>'0', others=>s_axis_tvalid);
-- s_axis_tlast_int <= (others=> s_axis_tlast);

crossbar2: entity work.shuffle_crossbar
	generic map (
		NUMBER_OF_INPUT_LANES=>NUMBER_OF_SHUFFLE_LANES, -- Number of input streams
		NUMBER_OF_OUTPUT_LANES=>NUMBER_OF_OUTPUT_LANES, -- Number of output streams
		COMBINE_DATA_FLAGS => COMBINE_DATA_FLAGS,
		BIN_SEL_FIFO_TYPE_MAP => (0 to NUMBER_OF_OUTPUT_LANES-1 => (others=> 1))
		)
	port map (
		s_axis_tdata  => axis_shuffle_out_tdata,
		s_axis_tvalid => axis_shuffle_out_tvalid,
		s_axis_tlast  => axis_shuffle_out_tlast,

		-- s_axis_tdata  => (0=>axis_shuffle_tdata(0), 1=>axis_shuffle_tdata_dly(1), others=>(others=>'0')),
		-- s_axis_tvalid => (0 =>axis_shuffle_tvalid(0), 1=> axis_shuffle_tvalid_dly(1), others=>'0'),
		-- s_axis_tlast  => (0 =>axis_shuffle_tlast(0), 1=> axis_shuffle_tlast_dly(1), others=>'0'),
		-- s_axis_tuser  => (others=>"0101"), --(ADC overflow, scaler even, scaler odd, FFT overflow)
		-- s_axis_clk => (others=>in_clk),
		-- s_axis_tready => s_axis_tready,

		m_axis_tdata(0)  => m_axis_tdata,
		m_axis_tvalid(0) => m_axis_tvalid,
		m_axis_tlast(0)  => m_axis_tlast,
		-- m_axis_tready(0)  => '1',

		frame_clk_in => frame_clk_in,
		clk =>out_clk,
		rst => reset,

		-- CTRL_CMD_DAT => (TDATA=> cmd_tdata, TVALID => cmd_tvalid, TLAST => cmd_tlast, DUMMY =>'0'),
		CTRL_CMD_DAT.TDATA => cmd_tdata2,
		CTRL_CMD_DAT.TVALID => cmd_tvalid2,
		CTRL_CMD_DAT.TLAST => cmd_tlast2,

		CTRL_CMD_RDY.TREADY =>cmd_tready2,
		CTRL_RPLY_DAT => open,
		CTRL_RPLY_RDY => (TREADY => '1'),
		CTRL_CLK => clk125,
		CTRL_RST => reset
	);



-- out_clk_process :process
--    begin
-- 		out_clk <= '0';
-- 		wait for OUT_CLK_PERIOD/2;
-- 		out_clk <= '1';
-- 		wait for OUT_CLK_PERIOD/2;
--    end process;

-- dly_proc : process(out_clk)
-- 	variable ready_vect: std_logic_vector(0 to NUMBER_OF_SHUFFLE_LANES-1);
-- 	begin
-- 		if rising_edge(out_clk) then

-- 			if ready_ctr=65 then
-- 				ready_ctr<=(others=>'0');
-- 			else
-- 				ready_ctr <= ready_ctr + 1;
-- 			end if;

-- 			ready <= not to_std_logic(ready_ctr=64 or ready_ctr=65);

-- 			ready_vect(0) := '1';
-- 			ready_vect(1 to NUMBER_OF_SHUFFLE_LANES-1) := (others=> ready);
-- 			axis_shuffle_tvalid_dly1 <=  axis_shuffle_tvalid and ready_vect;
-- 			axis_shuffle_tdata_dly1 <=  axis_shuffle_tdata;
-- 			axis_shuffle_tlast_dly1 <=  axis_shuffle_tlast;

-- 			axis_shuffle_tvalid_dly2 <=  axis_shuffle_tvalid_dly1;
-- 			axis_shuffle_tdata_dly2 <=  axis_shuffle_tdata_dly1;
-- 			axis_shuffle_tlast_dly2 <=  axis_shuffle_tlast_dly1;

-- 			axis_shuffle_tvalid_dly3 <=  axis_shuffle_tvalid_dly2;
-- 			axis_shuffle_tdata_dly3 <=  axis_shuffle_tdata_dly2;
-- 			axis_shuffle_tlast_dly3 <=  axis_shuffle_tlast_dly2;

-- 			axis_shuffle_tvalid_dly <=  axis_shuffle_tvalid_dly3;
-- 			axis_shuffle_tdata_dly <=  axis_shuffle_tdata_dly3;
-- 			axis_shuffle_tlast_dly <=  axis_shuffle_tlast_dly3;

-- 		end if;
-- 	end process ; -- lane0_proc


stim_proc : process
	variable number_of_frames_per_packet: integer :=4;
	variable number_of_cb1_input_lanes: integer := 16;
	variable number_of_cb1_selected_bins: integer :=48;
	variable cb1_bin_spacing: integer :=16;
	variable number_of_words_per_bin: integer :=number_of_cb1_input_lanes/4;
	variable number_of_cb2_input_lanes: integer := 2;
	variable number_of_cb2_selected_bins: integer :=1;
	variable cb2_bin_spacing: integer :=8;
	begin
		reset <= '1';
		sleep(out_clk, 10);
		reset <= '0';
		sleep(clk125, 10); -- make sure we start command transmission on a CLK125 edge or we will lose some data
		fpga_write(clk125, cmd_tdata1, cmd_tvalid1, cmd_tlast1, cmd_tready1, CROSSBAR1_BASE_ADDR + 0, 0); --

		-- Initialize CROSSBAR1
		for i in 0 to NUMBER_OF_SHUFFLE_LANES-1 loop
			-- fpga_write(       clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, CROSSBAR_BIN_SEL0_ADDR + i*CROSSBAR_ADDR_INCREMENT + 4, 1); -- Set the number of frames per packet
			fpga_write(       clk125, cmd_tdata1, cmd_tvalid1, cmd_tlast1, cmd_tready1, CROSSBAR1_BIN_SEL0_ADDR + i*CROSSBAR1_ADDR_INCREMENT + 3, number_of_cb1_selected_bins); -- Set the number of words to select
			fpga_write(       clk125, cmd_tdata1, cmd_tvalid1, cmd_tlast1, cmd_tready1, CROSSBAR1_BIN_SEL0_ADDR + i*CROSSBAR1_ADDR_INCREMENT + 4, number_of_cb1_input_lanes); -- Set the range of inputs to capture (0 to NUMBER_OF_CROSSBAR_INPUTS-1)
			fpga_write(       clk125, cmd_tdata1, cmd_tvalid1, cmd_tlast1, cmd_tready1, CROSSBAR1_BIN_SEL0_ADDR + i*CROSSBAR1_ADDR_INCREMENT + 0, 16#70# + number_of_frames_per_packet); -- Set the range of inputs to capture (0 to NUMBER_OF_CROSSBAR_INPUTS-1)
			fpga_select_bins( clk125, cmd_tdata1, cmd_tvalid1, cmd_tlast1, cmd_tready1, CROSSBAR1_BIN_SEL0_ADDR + i*CROSSBAR1_ADDR_INCREMENT, first_bin=>0, bin_step=>cb1_bin_spacing, number_of_bins=>number_of_cb1_selected_bins); -- Enable storage and transmission of N frequency bins.
			-- wait for 2*64*SYSCLK_period; -- prevent the buffers from overflowing by allowing time to send the ethernet framing
			-- fpga_read(       clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, CROSSBAR_BIN_SEL0_ADDR + 16#200#, 3); -- Re-read the first 8 bytes of the map for debugging
		end loop;


		-- Initialize CROSSBAR2
		for i in 0 to NUMBER_OF_OUTPUT_LANES-1 loop
			fpga_write(       clk125, cmd_tdata2, cmd_tvalid2, cmd_tlast2, cmd_tready2, CROSSBAR2_BIN_SEL0_ADDR + i*CROSSBAR2_ADDR_INCREMENT + 3, number_of_cb1_selected_bins); -- Set the number of words to select
			fpga_write(       clk125, cmd_tdata2, cmd_tvalid2, cmd_tlast2, cmd_tready2, CROSSBAR2_BIN_SEL0_ADDR + i*CROSSBAR2_ADDR_INCREMENT + 4, number_of_words_per_bin); -- Set the number of words to select
			fpga_write(       clk125, cmd_tdata2, cmd_tvalid2, cmd_tlast2, cmd_tready2, CROSSBAR2_BIN_SEL0_ADDR + i*CROSSBAR2_ADDR_INCREMENT + 5, number_of_frames_per_packet*32 + number_of_cb2_input_lanes); -- Set the range of inputs to capture (0 to NUMBER_OF_CROSSBAR_INPUTS-1)
			fpga_select_bins( clk125, cmd_tdata2, cmd_tvalid2, cmd_tlast2, cmd_tready2, CROSSBAR2_BIN_SEL0_ADDR + i*CROSSBAR2_ADDR_INCREMENT, first_bin=>0, bin_step=>cb2_bin_spacing, number_of_bins=>number_of_cb2_selected_bins); -- Enable storage and transmission of N frequency bins.
			-- wait for 2*64*SYSCLK_period; -- prevent the buffers from overflowing by allowing time to send the ethernet framing
			-- fpga_read(       clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, CROSSBAR_BIN_SEL0_ADDR + 16#200#, 3); -- Re-read the first 8 bytes of the map for debugging
		end loop;

		sleep(in_clk,20);
		init_done <= '1';
		-- sleep(clk,start_delay(i));
		wait;
	end process ; -- lane0_proc

chandata_gen: for i in 0 to NUMBER_OF_INPUT_LANES-1 generate
-- chandata_gen: for i in 0 to 1 generate
	process
	begin
		wait until init_done='1' and and_reduce(rx_resetdone)='1' and and_reduce(tx_resetdone)='1';
		sleep(s_axis_clk_int(i),20);
		for j in 0 to 100 loop
			send_axis32_packet(s_axis_clk_int(i), s_axis_tdata_int(i), s_axis_tvalid_int(i), s_axis_tlast_int(i), s_axis_tready, create_chan_packet(512, i));
			-- sleep(in_clk, 2);
		end loop;
		wait;
	end process;
end generate;

END;
