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
use work.tb_package.all;

ENTITY bp_shuffle_align_testbench IS
	generic (
		NUMBER_OF_LANES: integer := 3
		);
END bp_shuffle_align_testbench;


ARCHITECTURE behavior OF bp_shuffle_align_testbench IS

   -- Clock period definitions
   -- constant CLK_PERIOD : time := 3.2 ns;

-- constant IN_CLK_PERIOD : time := 5 ns; -- 200 MHz
constant OUT_CLK_PERIOD : time := 4.096 ns; -- 244 MHz
constant REFCLK_PERIOD : time := 3.2 ns;
constant CLK125_period : time := 8 ns;


--Inputs
signal reset : std_logic := '0';


signal in_clk: std_logic; -- 322 MHz GTX clock
signal out_clk: std_logic; -- 322 MHz GTX clock
signal clk125: std_logic; --


signal s_axis_tdata: slv32_array(0 to NUMBER_OF_LANES-1) := (others=> (others=>'0'));
signal s_axis_tvalid: std_logic_vector(0 to NUMBER_OF_LANES-1) := (others=>'0'); -- needed for sim. If, U, data will not start
signal s_axis_tlast: std_logic_vector(0 to NUMBER_OF_LANES-1):= (others=>'0');
signal s_axis_tready: std_logic_vector(0 to NUMBER_OF_LANES-1):=(others=>'1'); -- init needed for sim

signal m_axis_fifo_tdata: slv32_array(0 to NUMBER_OF_LANES-1);
signal m_axis_fifo_tvalid: std_logic_vector(0 to NUMBER_OF_LANES-1);
signal m_axis_fifo_tlast: std_logic_vector(0 to NUMBER_OF_LANES-1);
signal m_axis_fifo_tuser: slv4_array(0 to NUMBER_OF_LANES-1);
signal resetv: std_logic_vector(0 to NUMBER_OF_LANES-1);
-- signal m_axis_fifo_tready: std_logic_vector(0 to NUMBER_OF_LANES-1);

signal m_axis_tdata: slv32_array(0 to NUMBER_OF_LANES-1);
signal m_axis_tvalid: std_logic_vector(0 to NUMBER_OF_LANES-1);
signal m_axis_tlast: std_logic_vector(0 to NUMBER_OF_LANES-1);
signal m_axis_tuser: slv4_array(0 to NUMBER_OF_LANES-1);

signal frame_clk: std_logic;
signal first: std_logic := '1';


signal rx_p: std_logic_vector(0 to NUMBER_OF_LANES-2);
signal rx_n: std_logic_vector(0 to NUMBER_OF_LANES-2);
signal tx_p: std_logic_vector(0 to NUMBER_OF_LANES-2);
signal tx_n: std_logic_vector(0 to NUMBER_OF_LANES-2);
signal refclk_p: std_logic;
signal refclk_n: std_logic;

signal cmd_tdata: slv8;
signal cmd_tvalid: std_logic;
signal cmd_tlast: std_logic;
signal cmd_tready: std_logic;

signal tx_resetdone: std_logic_vector(0 to NUMBER_OF_LANES-1); --
signal rx_resetdone: std_logic_vector(0 to NUMBER_OF_LANES-1); --

constant NUMBER_OF_PACKETS : integer :=5;
type lane_config_type is array (0 to NUMBER_OF_LANES-1) of integer_array(0 to NUMBER_OF_PACKETS-1);
-- back to back frames, same length, aligned within timeout
-- constant start_delay: integer_array := (4,0,2);
-- constant interpacket_delay: integer_array := (0,0,0);
-- constant packet_length: integer_array := (8,8,8);

-- -- back to back frames, same length, aligned within timeout except missing frame
-- constant PL: integer := 20;
-- constant PP: integer := 22;
-- constant start_delay: integer_array          := (0=> 4,          1=> 0,          2=> 2);
-- constant packet_length: lane_config_type     := (0=>(others=>PL), 1=>(1=>0, others=>PL), 2=>(others=>PL));
-- constant packet_period: lane_config_type     := (others=> (others=>PP));
constant lane_active: integer_array := (0 to 1 => 1, 2 => 0);
constant PL: integer := 37; -- packet length
constant PP: integer := 512; -- packet period (packet length + interpacket delay)
constant start_delay: integer_array          := (0=> 1,          1=> 0,          2=> 0); -- normal delay
-- constant start_delay: integer_array          := (0=> 0,          1=> 9,          2=> 1); -- borderline delay
-- constant packet_length: lane_config_type     := (0=>(others=>PL), 1=>(1=>0, others=>PL), 2=>(others=>PL)); -- missing frame
-- constant packet_period: lane_config_type     := (others=> (others=>PP));
-- constant packet_length: lane_config_type     := (1=>(others=>1), others=> (others=>PL)); -- Lane 1 single word
-- constant packet_period: lane_config_type     := (1=>(others=>1), others=> (others=>PP)); -- lane 1 single word back to back
-- constant packet_length: lane_config_type     := (2=>(others=>0), others=>(others=>PL)); -- Missing lane 3
-- constant packet_length: lane_config_type     := (2=>(others=>PL-1), others=>(others=>PL)); -- Lane 2 sends shorter packets
constant packet_length: lane_config_type     := (others=>(others=>PL)); -- All lanes normal
constant packet_period: lane_config_type     := (others=>(others=>PP)); -- All lanes normal, with interpacket space


-- Tests
-- Normal mode
-- Borderline delay
-- Missing frame
-- Short frame
-- One lane with bursts on back-to-back 1 word frame
-- All single word, back-to-back packets: cannot work because  too fast for the frame clock processing

	-- signal t1: slv8;
	-- signal t2,t3: std_logic;
begin


-- in_clk_process :process
--    begin
-- 		in_clk <= '0';
-- 		wait for IN_CLK_PERIOD/2;
-- 		in_clk <= '1';
-- 		wait for IN_CLK_PERIOD/2;
--    end process;

out_clk_process :process
   begin
		out_clk <= '0';
		wait for OUT_CLK_PERIOD/2;
		out_clk <= '1';
		wait for OUT_CLK_PERIOD/2;
   end process;

-- clk_process :process
--    begin
-- 		clk <= '0';
-- 		wait for CLK_PERIOD/2;
-- 		clk <= '1';
-- 		wait for CLK_PERIOD/2;
--    end process;

refclk_process :process
   begin
		refclk_p <= '0';
		refclk_n <= '1';
		wait for REFCLK_PERIOD/2;
		refclk_p <= '1';
		refclk_n <= '0';
		wait for REFCLK_PERIOD/2;
   end process;

clk125_process :process
   begin
		clk125 <= '0';
		wait for clk125_period/2;
		clk125 <= '1';
		wait for clk125_period/2;
   end process;


-- 5 back-to back frames, all same length, aligned: ok
-- 5 frames, 1 clock spacing, same length, aligned: ok
-- 5 frames, same_length, aligned within timeout: ok
-- 5 frames, same_length, lane2 delayed by frame length:

-- data(0) <= (X"A0A0A0A0", X"A1A1A1A1", X"A2A2A2A2", X"A3A3A3A3", X"A4A4A4A4", X"A5A5A5A5", X"A6A6A6A6", X"A7A7A7A7");

rx_p <= tx_p;
rx_n <= tx_n;

bp_shuffle0: entity work.xglink_array
	generic map (
		LINK_SPEED             => 0, -- 0: 7.5 Gb/s (244 MHz word clock), 1: 10 Gb/s (322 MHz word clock)
		NUMBER_OF_BYPASS_LANES => 1,
		NUMBER_OF_TX_LANES     => NUMBER_OF_LANES-1,
		NUMBER_OF_RX_LANES     => NUMBER_OF_LANES-1,
		NUMBER_OF_REFCLK       => 1,
		LANE_TO_QUAD_MAP       => (0 to 3 => 0), --! Indicates which quad is associated each channel. The QUAD number is an integer between 0 and N-1, where N is the total number of quads used.
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
		s_axis_tx_tdata  => s_axis_tdata,
		s_axis_tx_tvalid => s_axis_tvalid,
		s_axis_tx_tlast  => s_axis_tlast,
		s_axis_tx_tready => s_axis_tready,
		s_axis_tx_clk    => in_clk, --! 244 or 322 MHz clock generated by the backplane shuffle transmitter from the reference clock. Must be used to clock all the Tx (slave) interface data.  There is one single clock per array.
		tx_resetdone     => tx_resetdone,

		-- RX user interface (AXI-Streaming, non-blocking)
		m_axis_rx_tdata  => m_axis_fifo_tdata,
		m_axis_rx_tvalid => m_axis_fifo_tvalid,
		m_axis_rx_tlast  => m_axis_fifo_tlast,
		m_axis_rx_tready => std_logic_vector'(0 to NUMBER_OF_LANES-1 => '1'), -- we use a non-blocking output stream so we can easily pipeline it to the align region of the 2nd crossbar. There can be one independent clock per Rx lane, but we resynchronize everything to the Tx clock.
		m_axis_rx_clk    => std_logic_vector'(0 to NUMBER_OF_LANES-1 => out_clk), --! Clock to which each Rx data is resynchronized
		rx_resetdone     => rx_resetdone,

		-- Clock monitoring ports
		refclk_div2 => open,
		txclk_div2  => open,

		-- User bypass control line
		bypass      => open,

		-- Control and reply streams
		CMD_DAT => (TDATA=> cmd_tdata, TVALID => cmd_tvalid, TLAST => cmd_tlast),
		CMD_RDY.TREADY =>cmd_tready,
		RPLY_DAT => open,
		RPLY_RDY => (TREADY => '1'),
		CTRL_CLK => clk125,
		CTRL_RST => reset,
		areset   => reset

	 );

reset <= resetv(0);

lane_gen: for i in 0 to NUMBER_OF_LANES-1 generate

	lane_proc : process
		begin
			-- wait until reset='0' and signed(tx_resetdone)=-1 and signed(rx_resetdone)=-1;
			resetv(i) <= '1';
			sleep(out_clk, 10);
			resetv(i) <= '0';
			sleep(out_clk, 1);
			wait for 6 us;
			sleep(clk125, 5);
			-- fpga_write_control(clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, 4, 2); -- test_enable=1
			sleep(in_clk, 5);
			if lane_active(i) /= 0 then
				sleep(in_clk, start_delay(i));
				for j in 0 to NUMBER_OF_PACKETS-1 loop
					send_axis32_packet(in_clk, s_axis_tdata(i), s_axis_tvalid(i), s_axis_tlast(i), s_axis_tready(i), create_packet(i,j, packet_length(i)(j)), packet_period(i)(j));
				end loop;
			end if;
			sleep(in_clk, 50);
			resetv(i) <= '1';
			sleep(in_clk, 16);
			resetv(i) <= '0';
			sleep(in_clk, 16);
			if lane_active(i) /= 0 then
				sleep(in_clk, start_delay(i));
				for j in 0 to NUMBER_OF_PACKETS-1 loop
					send_axis32_packet(in_clk, s_axis_tdata(i), s_axis_tvalid(i), s_axis_tlast(i), s_axis_tready(i), create_packet(i,j, packet_length(i)(j)), packet_period(i)(j));
				end loop;
			end if;

			wait;
		end process ; -- lane0_proc

end generate;

process(in_clk) begin
	if rising_edge(in_clk) then
		if s_axis_tvalid(0)='1' then
			first <= s_axis_tlast(0);
		end if;
	frame_clk <= s_axis_tvalid(0) and first;
	end if;
end process;

-- frame_clk <= s_axis_tvalid and s_axis_tlast;
align0: entity work.align
	generic map (
		NUMBER_OF_LANES => NUMBER_OF_LANES
		)
	port map (
		s_axis_tdata  => m_axis_fifo_tdata,
		s_axis_tvalid => m_axis_fifo_tvalid,
		s_axis_tlast  => m_axis_fifo_tlast,
		s_axis_tuser  => (others=>"1100"),

		frame_clk_sel => '0',
		m_axis_tdata  => m_axis_tdata,
		m_axis_tvalid => m_axis_tvalid,
		m_axis_tlast  => m_axis_tlast,
		m_axis_tuser  => m_axis_tuser,

		clk => out_clk,
		sof_window_start => to_slv(0,8),
		sof_window_stop => to_slv(25,8),
		-- frame_clk => frame_clk,
		rst => reset
	);


END;
