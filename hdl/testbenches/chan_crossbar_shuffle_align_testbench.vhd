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

ENTITY chan_crossbar_shuffle_align_testbench IS
	generic (
		NUMBER_OF_INPUT_LANES: integer := 16; -- Must be a multiple of 4
		NUMBER_OF_OUTPUT_LANES: integer := 4
		);
END chan_crossbar_shuffle_align_testbench;


ARCHITECTURE behavior OF chan_crossbar_shuffle_align_testbench IS

   -- Clock period definitions

constant IN_CLK_PERIOD : time := 5.000 ns; -- 200 MHz
constant OUT_CLK_PERIOD : time := 4.096 ns; -- 244 MHz
constant CLK125_period : time := 8 ns;
constant REFCLK_PERIOD : time := 6.4 ns; -- 156.25 MHz

-- SYSTEM Port modules
constant CROSSBAR_BASE_ADDR      : integer := 16#20000#; -- # CROSSBAR top address
constant CROSSBAR_ADDR_INCREMENT : integer := 16#00800#; --
constant CROSSBAR_BIN_SEL0_ADDR: integer := CROSSBAR_BASE_ADDR + 1*CROSSBAR_ADDR_INCREMENT;
constant CROSSBAR_BIN_SEL1_ADDR: integer := CROSSBAR_BASE_ADDR + 2*CROSSBAR_ADDR_INCREMENT;
----
--Inputs
signal reset : std_logic := '0';


signal in_clk: std_logic; --
signal in_clk_dly: std_logic_vector(0 to NUMBER_OF_INPUT_LANES-1) := (others=>'0'); -- needed for sim. If, U, data will not start
signal out_clk: std_logic; --
signal clk125: std_logic; --
signal config_done: std_logic := '0';

type DELAY_ARRAY is array (natural range <>) of time;
-- constant CLK_DLY: DELAY_ARRAY(0 to 7) := (0 ns, 625 ps, 2*625 ps, 3*625 ps, 4*625 ps, 5*625 ps, 6*625 ps, 7*625 ps);
constant CLK_DLY: DELAY_ARRAY(0 to 15) := (0 ns, 150 ns, 149 ns, 155 ns, 145 ns, 150 ns, 150 ns, 148 ns, 150 ns, 150 ns, 149 ns, 155 ns, 145 ns, 150 ns, 150 ns, 148 ns);

signal lane_active: slv(0 to NUMBER_OF_OUTPUT_LANES-1) := (2=>'0', others => '1');

signal s_axis_tdata: slv32_array(0 to NUMBER_OF_INPUT_LANES-1) := (others=> (others=>'0'));
signal s_axis_tvalid: std_logic_vector(0 to NUMBER_OF_INPUT_LANES-1) := (others=>'0'); -- needed for sim. If, U, data will not start
signal s_axis_tlast: std_logic_vector(0 to NUMBER_OF_INPUT_LANES-1):= (others=>'0');
signal s_axis_tready: std_logic_vector(0 to NUMBER_OF_INPUT_LANES-1):=(others=>'1'); -- init needed for sim

signal m_axis_fifo_tdata: slv32_array(0 to NUMBER_OF_INPUT_LANES-1);
signal m_axis_fifo_tvalid: std_logic_vector(0 to NUMBER_OF_INPUT_LANES-1);
signal m_axis_fifo_tlast: std_logic_vector(0 to NUMBER_OF_INPUT_LANES-1);
signal m_axis_fifo_tuser: slv4_array(0 to NUMBER_OF_INPUT_LANES-1);

signal axis_cb_out_tdata: slv32_array(0 to NUMBER_OF_OUTPUT_LANES-1);
signal axis_cb_out_tvalid: std_logic_vector(0 to NUMBER_OF_OUTPUT_LANES-1);
signal axis_cb_out_tlast: std_logic_vector(0 to NUMBER_OF_OUTPUT_LANES-1);
signal axis_cb_out_tuser: slv4_array(0 to NUMBER_OF_OUTPUT_LANES-1);
signal axis_cb_out_tready: std_logic_vector(0 to NUMBER_OF_OUTPUT_LANES-1);

signal axis_rx_fifo_in_tdata: slv32_array(0 to NUMBER_OF_OUTPUT_LANES-1);
signal axis_rx_fifo_in_tvalid: std_logic_vector(0 to NUMBER_OF_OUTPUT_LANES-1);
signal axis_rx_fifo_in_tlast: std_logic_vector(0 to NUMBER_OF_OUTPUT_LANES-1);
signal axis_rx_fifo_in_tuser: slv4_array(0 to NUMBER_OF_OUTPUT_LANES-1);
signal axis_rx_fifo_in_clk: slv(0 to NUMBER_OF_OUTPUT_LANES-1);
signal axis_rx_fifo_overflow: slv(0 to NUMBER_OF_OUTPUT_LANES-1);


signal axis_rx_fifo_out_tdata: slv32_array(0 to NUMBER_OF_OUTPUT_LANES-1);
signal axis_rx_fifo_out_tvalid: std_logic_vector(0 to NUMBER_OF_OUTPUT_LANES-1);
signal axis_rx_fifo_out_tlast: std_logic_vector(0 to NUMBER_OF_OUTPUT_LANES-1);
signal axis_rx_fifo_out_tuser: slv4_array(0 to NUMBER_OF_OUTPUT_LANES-1);

signal axis_align_in_tdata: slv32_array(0 to NUMBER_OF_OUTPUT_LANES-1);
signal axis_align_in_tvalid: std_logic_vector(0 to NUMBER_OF_OUTPUT_LANES-1);
signal axis_align_in_tlast: std_logic_vector(0 to NUMBER_OF_OUTPUT_LANES-1);

signal axis_align_out_tdata: slv32_array(0 to NUMBER_OF_OUTPUT_LANES-1);
signal axis_align_out_tvalid: std_logic_vector(0 to NUMBER_OF_OUTPUT_LANES-1);
signal axis_align_out_tlast: std_logic_vector(0 to NUMBER_OF_OUTPUT_LANES-1);
signal axis_align_out_tuser: slv4_array(0 to NUMBER_OF_OUTPUT_LANES-1);

signal rx_p: std_logic_vector(0 to NUMBER_OF_OUTPUT_LANES-2);
signal rx_n: std_logic_vector(0 to NUMBER_OF_OUTPUT_LANES-2);
signal tx_p: std_logic_vector(0 to NUMBER_OF_OUTPUT_LANES-2);
signal tx_n: std_logic_vector(0 to NUMBER_OF_OUTPUT_LANES-2);
signal refclk_p: std_logic;
signal refclk_n: std_logic;
signal tx_resetdone: std_logic_vector(0 to NUMBER_OF_OUTPUT_LANES-1); --
signal rx_resetdone: std_logic_vector(0 to NUMBER_OF_OUTPUT_LANES-1); --

	-- signal m_axis_fifo_tready: std_logic_vector(0 to NUMBER_OF_LANES-1);

signal m_axis_tdata: slv32;
signal m_axis_tvalid: std_logic;
signal m_axis_tlast: std_logic;
signal m_axis_tuser: slv4;

signal cmd_tdata: slv8;
signal cmd_tvalid: std_logic;
signal cmd_tlast: std_logic;
signal cmd_tready: std_logic := '1'; -- to allow sim without DUT

signal bp_cmd_tdata: slv8;
signal bp_cmd_tvalid: std_logic := '0';
signal bp_cmd_tlast: std_logic;
signal bp_cmd_tready: std_logic := '1'; -- to allow sim without DUT

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
----
in_clk_process :process
   begin
		in_clk <= '0';
		wait for IN_CLK_PERIOD/2;
		in_clk <= '1';
		wait for IN_CLK_PERIOD/2;
   end process;

-- out_clk_process :process
--    begin
-- 		out_clk <= '0';
-- 		wait for OUT_CLK_PERIOD/2;
-- 		out_clk <= '1';
-- 		wait for OUT_CLK_PERIOD/2;
--    end process;

clk125_process :process
   begin
		clk125 <= '0';
		wait for clk125_period/2;
		clk125 <= '1';
		wait for clk125_period/2;
   end process;

refclk_process :process
   begin
		refclk_p <= '0';
		refclk_n <= '1';
		wait for REFCLK_PERIOD/2;
		refclk_p <= '1';
		refclk_n <= '0';
		wait for REFCLK_PERIOD/2;
   end process;


chan_fifo_gen: for i in 0 to NUMBER_OF_INPUT_LANES-1 generate

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

			rst => reset
		);

end generate;

chan_cb: entity work.chan_crossbar
	generic map (
		NUMBER_OF_INPUT_LANES => NUMBER_OF_INPUT_LANES, -- Number of input streams
		NUMBER_OF_OUTPUT_LANES => NUMBER_OF_OUTPUT_LANES -- Number of output streams
		)
	port map (
		s_axis_tvalid => m_axis_fifo_tvalid,
		s_axis_tdata  => m_axis_fifo_tdata,
		s_axis_tlast  => m_axis_fifo_tlast,
		s_axis_tuser  => m_axis_fifo_tuser, -- scaler and adc flags

		m_axis_tdata  => axis_cb_out_tdata,
		m_axis_tvalid => axis_cb_out_tvalid,
		m_axis_tlast  => axis_cb_out_tlast,

		clk => out_clk,
		rst => reset,

		CTRL_CMD_DAT.TDATA => cmd_tdata,
		CTRL_CMD_DAT.TVALID => cmd_tvalid,
		CTRL_CMD_DAT.TLAST => cmd_tlast,
		CTRL_CMD_DAT.DUMMY =>'0',
		CTRL_CMD_RDY.TREADY =>cmd_tready,
		CTRL_RPLY_DAT => open,
		CTRL_RPLY_RDY.TREADY => '1',
		CTRL_CLK => clk125,
		CTRL_RST => reset
	);


-- bp_link_gen: for i in 0 to NUMBER_OF_OUTPUT_LANES-1 generate

-- 	axis_rx_fifo_in_tvalid(i) <= transport axis_cb_out_tvalid(i) and lane_active(i) after CLK_DLY(i);
-- 	axis_rx_fifo_in_tlast(i) <= transport axis_cb_out_tlast(i) after CLK_DLY(i);
-- 	axis_rx_fifo_in_tdata(i) <= transport axis_cb_out_tdata(i) and (31 downto 0 => lane_active(i)) after CLK_DLY(i);
-- 	axis_rx_fifo_in_tuser(i) <= transport axis_cb_out_tuser(i) after CLK_DLY(i);
-- 	axis_rx_fifo_in_clk(i) <= transport out_clk after CLK_DLY(i);

-- 	rx_fifo0: entity work.XGLINK_RX_DATA_FIFO
-- 		PORT MAP (

-- 			s_aclk          => axis_rx_fifo_in_clk(i),
-- 			s_aresetn       => not reset,

-- 			s_axis_tvalid   => axis_rx_fifo_in_tvalid(i),
-- 			s_axis_tdata    => axis_rx_fifo_in_tdata(i),
-- 			s_axis_tlast    => axis_rx_fifo_in_tlast(i),
-- 			s_axis_tuser    => axis_rx_fifo_in_tuser(i)(0 downto 0),
-- 			s_axis_tready   => open, -- always receive. The receiver output is non-blocking.

-- 			m_aclk          => out_clk,
-- 			m_axis_tvalid   => axis_rx_fifo_out_tvalid(i),
-- 			m_axis_tdata    => axis_rx_fifo_out_tdata(i),
-- 			m_axis_tlast    => axis_rx_fifo_out_tlast(i),
-- 			m_axis_tuser    => axis_rx_fifo_out_tuser(i)(0 downto 0),
-- 			m_axis_tready   => '1',

-- 			axis_overflow => axis_rx_fifo_overflow(i) -- on s_aclk clock
-- 		);

-- end generate;

rx_p <= tx_p;
rx_n <= tx_n;

bp_shuffle0: entity work.xglink_array
	generic map (
		LINK_SPEED             => 0, -- 0: 7.5 Gb/s (244 MHz word clock), 1: 10 Gb/s (322 MHz word clock)
		IMPLEMENT_RX           => TRUE,
		NUMBER_OF_LANES        => NUMBER_OF_OUTPUT_LANES,
		NUMBER_OF_LINKS        => NUMBER_OF_OUTPUT_LANES-1,
		LANE_TO_LINK_MAP       => (0=>-1, 1=>0, 2=>1, 3=>2),
		NUMBER_OF_REFCLK       => 1,
		LANE_TO_QUAD_MAP       => (0 to NUMBER_OF_OUTPUT_LANES-1 => 0), --! Indicates which quad is associated each channel. The QUAD number is an integer between 0 and N-1, where N is the total number of quads used.
		QUAD_TO_REFCLK_MAP     => (0 => 0), --! Indicates which refclk is associated with each QUAD (N integers from 0 to NUMBER_OF_REFCLK-1).
		SIM                    => TRUE
		)
	port map (
		tx_p => tx_p,
		tx_n => tx_n,
		rx_p => rx_p,
		rx_n => rx_n,
		refclk_p => (others=> refclk_p),
		refclk_n => (others=> refclk_n),

		-- TX user interface (AXI-Streaming, blocking)
		s_axis_tx_tdata  => axis_cb_out_tdata,
		s_axis_tx_tvalid => axis_cb_out_tvalid,
		s_axis_tx_tlast  => axis_cb_out_tlast,
		s_axis_tx_tready => axis_cb_out_tready,
		s_axis_tx_clk    => out_clk, --! 244 or 322 MHz clock generated by the backplane shuffle transmitter from the reference clock. Must be used to clock all the Tx (slave) interface data.  There is one single clock per array.
		tx_resetdone     => tx_resetdone,

		-- RX user interface (AXI-Streaming, non-blocking)
		m_axis_rx_tdata  => axis_rx_fifo_out_tdata,
		m_axis_rx_tvalid => axis_rx_fifo_out_tvalid,
		m_axis_rx_tlast  => axis_rx_fifo_out_tlast,
		-- m_axis_rx_tready => std_logic_vector'(0 to NUMBER_OF_OUTPUT_LANES-1 => '1'), -- we use a non-blocking output stream so we can easily pipeline it to the align region of the 2nd crossbar. There can be one independent clock per Rx lane, but we resynchronize everything to the Tx clock.
		-- m_axis_rx_clk    => std_logic_vector'(0 to NUMBER_OF_OUTPUT_LANES-1 => out_clk), --! Clock to which each Rx data is resynchronized
		rx_resetdone     => rx_resetdone,

		clk => out_clk,
		-- Clock monitoring ports
		refclk_div2 => open,
		txclk_div2  => open,

		-- -- User bypass control line
		-- bypass      => open,

		-- Control and reply streams
		CMD_DAT.TDATA   => bp_cmd_tdata,
		CMD_DAT.TVALID  => bp_cmd_tvalid,
		CMD_DAT.TLAST   => bp_cmd_tlast,
		CMD_DAT.DUMMY   =>'0',
		CMD_RDY.TREADY  => bp_cmd_tready,
		RPLY_DAT        => open,
		RPLY_RDY.TREADY => '1',
		CTRL_CLK        => clk125,
		CTRL_RST        => reset,
		areset   => reset

	 );

axis_align_in_tdata <= axis_rx_fifo_out_tdata;
axis_align_in_tvalid <= axis_rx_fifo_out_tvalid and lane_active;
axis_align_in_tlast <= axis_rx_fifo_out_tlast and lane_active;

shuffle_align0: entity work.align
	generic map (
		NUMBER_OF_LANES => NUMBER_OF_OUTPUT_LANES
		)
	port map (
		s_axis_tdata  => axis_align_in_tdata,
		s_axis_tvalid => axis_align_in_tvalid,
		s_axis_tlast  => axis_align_in_tlast,
		s_axis_tuser  => (others=>"1100"),

		m_axis_tdata  => axis_align_out_tdata,
		m_axis_tvalid => axis_align_out_tvalid,
		m_axis_tlast  => axis_align_out_tlast,
		m_axis_tuser  => axis_align_out_tuser,

		sof_window_stop => to_slv(64,8),
		timeout_period => to_slv(32,8),
		auto_unban => '0',
		clk => out_clk,
		rst => reset
	);
--


conf_proc : process
	variable number_of_selected_bins: integer :=64;
	variable number_of_input_lanes_var: integer := 16;
	variable frames_per_packet: integer := 4;
	variable bypass: integer := 0;
	variable bin_sel_addr: integer;

	begin
		reset <= '1';
		sleep(out_clk, 10);
		reset <= '0';
		report "RESET done!";
		sleep(clk125, 10); -- make sure we start command transmission on a CLK125 edge or we will lose some data
		report "Starting configuration";
		fpga_write_control(clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready,  0, 0); --

		-- Configure all bin selectors
		for i in 0 to NUMBER_OF_OUTPUT_LANES-1 loop
			bin_sel_addr := (i+1) * CROSSBAR_ADDR_INCREMENT;
			fpga_write_control(       clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, bin_sel_addr + 0, 16#70# + frames_per_packet); --
			fpga_write_control(       clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, bin_sel_addr + 3, number_of_selected_bins); -- Set the number of words to select
			fpga_write_control(       clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, bin_sel_addr + 4, number_of_input_lanes_var + bypass*32); -- Set the range of inputs to capture (0 to NUMBER_OF_CROSSBAR_INPUTS-1)
			fpga_select_bins( clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, bin_sel_addr, first_bin => (4*i) mod 16, bin_step => 16, number_of_bins => number_of_selected_bins); -- Enable storage and transmission of N frequency bins.
			-- wait for 2*64*SYSCLK_period; -- prevent the buffers from overflowing by allowing time to send the ethernet framing
			-- fpga_read(       clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, CROSSBAR_BIN_SEL0_ADDR + 16#200#, 3); -- Re-read the first 8 bytes of the map for debugging
		end loop;
		report "Done configuration";
		sleep(clk125, 800); -- Make sure the descrambler has time to lock on the data stream
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
			-- if lane_active(i)>0 then
				sleep(in_clk_dly(i), 10);
				for j in 0 to 30 loop
					send_axis32_packet(in_clk_dly(i), s_axis_tdata(i), s_axis_tvalid(i), s_axis_tlast(i), s_axis_tready(i), create_chan_packet(512));
					-- sleep(clk,1);
				end loop;
			-- end if;
			wait;
		end process;
end generate;

END;
