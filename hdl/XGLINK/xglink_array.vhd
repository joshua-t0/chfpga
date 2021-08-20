--! @file
----------------------------------------------------------------------------------
-- Company:  McGill University
-- Engineer: JF CLiche
--
-- Create Date: 09/16/2013 04:48:29 PM
-- Design Name:
-- Module Name: xge_udp_mac
-- Project Name: CHIME
-- Target Devices: Kintex 7
-- Tool Versions: Vivado 2013.4
-- Description: Implements an array of packet transmitters and receivers using a GTX operating at 7.5Gbps or 10 Gbps.
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
use IEEE.std_logic_misc.ALL; -- for reduce functions

library UNISIM;
use UNISIM.VComponents.all;

library work;
use work.chFPGA_Package.all;
use work.ip_package.all; -- Import definition of components used in this module

--! @Brief Implements an array of packet transmitters and receivers using a GTX operating at 7.5Gbps or 10 Gbps.
--! The link is implemented by GTX transceivers configured to operate at 7.5 Gbps if LINK_SPEED=0 or at 10 Gbps if LINK_SPEED=1.
--!
--! The module assumes one or multiple 156.25 MHz reference clocks. 7-Series constraints require a reference input to clock a maximum of 3 QUADS (12 lanes), i.e. the QUAD receiving the referece clock, and the quads above and below.
--! NUMBER_OF_REFCLK indicate how many reference clocks are provided, and QUAD_TO_REFCLK_MAP indicate which reference clock (numbered from 0 to NUMBER_OF_REFCLK-1) is to be used for each quad.
--! Also, the LANE_TO_QUAD_MAP generics specify which quad is associated with each lane.

--! *** INPUT (slave AXIS interface)
--! The input is a 32-bit wide, blocking AXI-Streaming interface. Valid data is indicated by tvalid='1'.
--! The data is actually consumed by the module when tready (which is provided by the module) is high.
--! In order to minimize its resource footprint, this module does not implement any FIFO as the flow control is performed entirely by tready, so It is important to change the input data (tdata and tvalid) only when tready='1'.
--! The end of a packet is signaled when tlast='1' on a valid (tvalid='1') word.
--! The start of a packet is implicitely determined as the forst word following the end of a packet.
--! The input data does not have to be contiguous, i.e. we don't have to provide valid data when the transmitter is ready. If no valid data is present, Idle codes will be sent down the link.
--! The transmitter will add a start-of-frame control code at the beginning of the packets, and will add a CRC32 and an end-of-frame code at the end of the packet.
--! The input interface for every transmit lane operate on a single transmit clock, which is generated from the GTX reference clock.
--!
--! *** OUTPUT (master AXIS interface)
--! Each RX lane provides data on its own recovered clock, which is buffered by a BUFH and is therefore available only in the clock region where the receiver is.
--! However, a 512-word deep asynchronous FIFO provides an output data flow on the clock provided by the user on m_axis_rx_clk(i).
--! Typically, every RX clock will be connected to the clock provided by the tranmitter (s_axis_tx_clk) so the logic can operate on a single clock domain.
--! A non-sticky FIFO overflow flag (on the internal rx clock) is available to detect if the FIFO has overflowed.

entity xglink_array is
	generic (
		NUMBER_OF_LANES: integer        := GLOBAL_NUMBER_OF_GPU_LINKS;
		NUMBER_OF_LANE_GROUPS: integer  := 1;
		LANE_GROUP_MAP: integerArray    := (0 to GLOBAL_NUMBER_OF_GPU_LINKS=>0);
		NUMBER_OF_LINKS: integer        := GLOBAL_NUMBER_OF_GPU_LINKS;
		LANE_TO_LINK_MAP: integerArray  := (0=>0, 1=>1, 2=>2, 3=>3, 4=>4, 5=>5, 6=>6, 7=>7);
		NUMBER_OF_REFCLK: integer       := GLOBAL_NUMBER_OF_GPU_REFCLKS;
		LANE_TO_QUAD_MAP: integerArray  := GLOBAL_GPU_CHANNEL_QUAD; --! Indicates which quad is associated each channel. The QUAD number is an integer between 0 and N-1, where N is the total number of quads used.
		QUAD_TO_REFCLK_MAP: integerArray:= GLOBAL_GPU_QUAD_REFCLK; --! Indicates which refclk is associated with each QUAD (N integers from 0 to NUMBER_OF_REFCLK-1).
		IMPLEMENT_RX : boolean          := FALSE;
		LINK_SPEED: integer             := 1;
		SIM: boolean                    := FALSE
		);
	port (
		tx_p: out std_logic_vector(0 to NUMBER_OF_LINKS-1);
		tx_n: out std_logic_vector(0 to NUMBER_OF_LINKS-1);
		rx_p: in std_logic_vector(0 to NUMBER_OF_LINKS-1);
		rx_n: in std_logic_vector(0 to NUMBER_OF_LINKS-1);
		refclk_p : in std_logic_vector(0 to NUMBER_OF_REFCLK-1); --156.250 clock
		refclk_n : in std_logic_vector(0 to NUMBER_OF_REFCLK-1);

		-- TX user interface (AXI-Streaming, blocking)
		s_axis_tx_tdata: in slv32_array(0 to NUMBER_OF_LANES -1);
		s_axis_tx_tvalid: in std_logic_vector(0 to NUMBER_OF_LANES -1);
		s_axis_tx_tlast: in std_logic_vector(0 to NUMBER_OF_LANES -1);
		s_axis_tx_tready: out std_logic_vector(0 to NUMBER_OF_LANES -1);


		-- RX user interface (AXI-Streaming, non-blocking)
		m_axis_rx_tdata: out slv32_array(0 to NUMBER_OF_LANES-1);
		m_axis_rx_tvalid: out std_logic_vector(0 to NUMBER_OF_LANES-1);
		m_axis_rx_tlast: out std_logic_vector(0 to NUMBER_OF_LANES-1);
		m_axis_rx_terror: out std_logic_vector(0 to NUMBER_OF_LANES-1);
		-- m_axis_rx_tready: in std_logic_vector(0 to NUMBER_OF_RX_LANES + NUMBER_OF_BYPASS_LANES -1);
		-- m_axis_rx_tready: out std_logic_vector(0 to NUMBER_OF_RX_LANES-1);
		-- m_axis_rx_clk: in std_logic_vector(0 to NUMBER_OF_RX_LANES + NUMBER_OF_BYPASS_LANES -1); --! AXI-S data clock thet must be used to clock the data in. This is derived from the GTX RX clock. There is one clock *per lane*


		clk: in std_logic; -- Clock for both the TX and RX AXI-S buses. Can be taken from s_axis_tx_clk.

		-- GTX signals
		tx_resetdone: out std_logic_vector(0 to NUMBER_OF_LANES-1);
		rx_resetdone: out std_logic_vector(0 to NUMBER_OF_LANES-1);
		s_axis_tx_clk: out std_logic; --! Data clock generated by the GTX.


		refclk_div2: out std_logic_vector(0 to NUMBER_OF_REFCLK-1); -- 156.25 MHz reference clock
		txclk_div2: out std_logic; -- Tx word clock

		lane_monitor: out std_logic;

		-- bypass: out std_logic; -- user controlled bit that signals the upper logic to bypass this module
		-- Clock monitoring ports
		-- clk156_div2: out std_logic; -- Data clock generated from MMCM
		-- userclk_div2: out std_logic; -- data clock geterated from GTX
		-- refclk_div2: out std_logic; -- 156.25 MHz reference clock

		-- Control and reply streams
		CMD_DAT: in AXIS8_DAT_STRUCT:= (TDATA=> (others=>'0'), TVALID=>'0', TLAST=>'0', DUMMY =>'0');
		CMD_RDY: out AXIS8_RDY_STRUCT;
		RPLY_DAT: out AXIS8_DAT_STRUCT;
		RPLY_RDY: in AXIS8_RDY_STRUCT := (TREADY => '1');
		CTRL_CLK : IN std_logic := '0'; -- control clock
		CTRL_RST : in std_logic := '0';

		areset: in std_logic --! asynchronous reset
	 );
end xglink_array;

architecture Behavioral of xglink_array is

-- Attribute definitions

	attribute ASYNC_REG : string;
	-- attribute shreg_extract: string;
	attribute dont_touch: string;

--- Constants

-- XGLINK_CORE Signals

signal reset_reg: std_logic_vector(0 to NUMBER_OF_LANES-1);
-- attribute shreg_extract of reset_reg: signal is "no";
attribute dont_touch of reset_reg: signal is "true";

signal reset_stats_reg: std_logic_vector(0 to NUMBER_OF_LANES-1);
-- attribute shreg_extract of reset_stats_reg: signal is "no";
attribute dont_touch of reset_stats_reg: signal is "true";

signal xglink_tx_data: slv32_array(0 to NUMBER_OF_LINKS-1);
signal xglink_tx_header: slv2_array(0 to NUMBER_OF_LINKS-1);
signal xglink_tx_ready: std_logic_vector(0 to NUMBER_OF_LINKS-1);
signal xglink_tx_clk: std_logic;
signal xglink_tx_resetdone: std_logic_vector(0 to NUMBER_OF_LINKS-1);

signal xglink_tx_reset: std_logic_vector(0 to NUMBER_OF_LINKS-1);

signal xglink_rx_data: slv32_array(0 to NUMBER_OF_LINKS-1);
signal xglink_rx_data_valid: std_logic_vector(0 to NUMBER_OF_LINKS-1);
signal xglink_rx_header: slv2_array(0 to NUMBER_OF_LINKS-1);
signal xglink_rx_header_valid: std_logic_vector(0 to NUMBER_OF_LINKS-1);
signal xglink_rx_clk: std_logic_vector(0 to NUMBER_OF_LINKS-1);
signal xglink_rx_resetdone: std_logic_vector(0 to NUMBER_OF_LINKS-1);

signal xglink_rx_reset: std_logic_vector(0 to NUMBER_OF_LINKS-1);

-- signal rx_clk: std_logic_vector(0 to NUMBER_OF_LINKS-1);

signal rx_p_dly: std_logic_vector(0 to NUMBER_OF_LINKS-1);
signal rx_n_dly: std_logic_vector(0 to NUMBER_OF_LINKS-1);


-- Lane signals
-- signal s_axis_tx_tdata_int: slv32_array(0 to NUMBER_OF_LANES-1);
-- signal s_axis_tx_tvalid_int: std_logic_vector(0 to NUMBER_OF_LANES-1);
-- signal s_axis_tx_tlast_int: std_logic_vector(0 to NUMBER_OF_LANES-1);
-- signal s_axis_tx_tready_int: std_logic_vector(0 to NUMBER_OF_LANES-1);

signal m_axis_rx_tdata_int: slv32_array(0 to NUMBER_OF_LANES-1);
signal m_axis_rx_tvalid_int: std_logic_vector(0 to NUMBER_OF_LANES-1);
signal m_axis_rx_tlast_int: std_logic_vector(0 to NUMBER_OF_LANES-1);
signal m_axis_rx_tready_int: std_logic_vector(0 to NUMBER_OF_LANES-1);
signal m_axis_rx_terror_int: std_logic_vector(0 to NUMBER_OF_LANES-1);

signal m_axis_rx_tdata_int2: slv32_array(0 to NUMBER_OF_LANES-1);
signal m_axis_rx_tvalid_int2: std_logic_vector(0 to NUMBER_OF_LANES-1);
signal m_axis_rx_tlast_int2: std_logic_vector(0 to NUMBER_OF_LANES-1);
signal m_axis_rx_terror_int2: std_logic_vector(0 to NUMBER_OF_LANES-1);

signal tx_fifo_overflow: std_logic_vector(0 to NUMBER_OF_LANES-1);
signal tx_fifo_overflow_sticky: std_logic_vector(0 to NUMBER_OF_LANES-1);
signal rx_fifo_overflow: std_logic_vector(0 to NUMBER_OF_LANES-1);
signal rx_fifo_overflow_sticky: std_logic_vector(0 to NUMBER_OF_LANES-1);

signal rx_frame_detect: std_logic_vector(0 to NUMBER_OF_LANES-1);
signal rx_resetdone_int: std_logic_vector(0 to NUMBER_OF_LANES-1);


-- Control
signal control_bytes: slv8_array(0 to 1);
signal status_bytes: slv8_array(0 to 7);
signal ctr: unsigned(15 downto 0);

-- signal link_enable: std_logic;
signal tx_test_enable: std_logic;
signal tx_test_enable_reg: std_logic;
-- signal rx_test_enable: std_logic;
-- signal rx_ctr: u8_array(0 to NUMBER_OF_LANES-1);
signal rx_frame_ctr: u8_array(0 to NUMBER_OF_LANES-1);

-- signal test_tvalid: std_logic;
-- signal test_tlast: std_logic;
-- signal test_tdata: slv32;
signal lane_sel: unsigned(4 downto 0);
signal reset_stats: std_logic; -- resets the fifo overflow  and error counter
signal bypass: std_logic_vector(NUMBER_OF_LANE_GROUPS-1 downto 0);
signal err_ctr: slv16_array(0 to NUMBER_OF_LANES-1); -- counts rx errors on lane specified uin 'lane_sel'
signal rx_max_frame_length: slv13_array(0 to NUMBER_OF_LANES-1); -- counts rx errors on lane specified uin 'lane_sel'
signal rx_min_frame_length: slv13_array(0 to NUMBER_OF_LANES-1); -- counts rx errors on lane specified uin 'lane_sel'

	-- signal delay_capture_word_ctr: u16_array(0 to NUMBER_OF_LANES-1);
	-- signal delay_capture_word_ctr_en: std_logic_vector(0 to NUMBER_OF_LANES-1);

signal tx_hold: std_logic;

begin


-- link_enable <= control_bytes(0)(0);
-- CONTROL byte 4
lane_sel            <= unsigned(control_bytes(0)(7 downto 3)); --! selects from which lane
reset_stats         <= control_bytes(0)(2); --!
tx_test_enable      <= control_bytes(0)(1);


-- CONTROL byte 5
bypass              <= control_bytes(1)(NUMBER_OF_LANE_GROUPS-1 downto 0);

-- -- CONTROL byte 5
-- rx_fifo_reset       <= control_bytes(1)(0);

-- STATUS byte 2

-- status_bytes(0)(7 downto 4) <= to_slv(lsb(ctr, 4));
status_bytes(0)(3)          <= tx_fifo_overflow_sticky(to_integer(lane_sel));
status_bytes(0)(2)          <= rx_frame_detect(to_integer(lane_sel));
status_bytes(0)(1)          <= areset;
status_bytes(0)(0)          <= rx_fifo_overflow_sticky(to_integer(lane_sel));

-- STATUS byte 3-4
--status_bytes(1) <= (others=>'0');
status_bytes(1 to 2) <= to_slv8_array(err_ctr(to_integer(lane_sel)));
status_bytes(3 to 4) <= to_slv8_array(rx_max_frame_length(to_integer(lane_sel)));
status_bytes(5 to 6) <= to_slv8_array(rx_min_frame_length(to_integer(lane_sel)));

-- status_bytes(5) <= to_slv(rx_ctr(to_integer(lane_sel)));
status_bytes(7) <= to_slv(rx_frame_ctr(to_integer(lane_sel)));

-- status_bytes(9 to 10)<= to_slv8_array(delay_capture_word_ctr(to_integer(unsigned(lane_sel))));



-- reset
rst_proc: process(clk)
begin
	if rising_edge(clk) then
		reset_reg <= (others => areset);
		reset_stats_reg <= (others => reset_stats);
	end if; --clk
end process;

--! Data source selector
--! We implement it as a combinatorial mux because we don't want to implement a FIFO to deal with tready if we can avoid it.

--------------------------------------
-- Test pattern generator
--------------------------------------

-- -- Test pattern generator
-- test_pat_proc: process(clk)
-- 	variable test_byte: std_logic_vector(7 downto 0);
-- begin
-- 	if rising_edge(clk) then

-- 		-- Generate test pattern
-- 		tx_test_enable_reg <= tx_test_enable;

-- 		if xglink_tx_resetdone(0)='0' then
-- 			ctr <= (others=>'0');
-- 			test_tvalid<='0';
-- 		else
-- 			ctr<=ctr+1;
-- 			if ctr(ctr'HIGH downto 7) =  0 then
-- 				test_tvalid<='1';
-- 				test_byte := std_logic_vector(resize(ctr, 8));
-- 				test_tdata<= test_byte & test_byte & test_byte & test_byte;
-- 				test_tlast<='0';
-- 				if signed(ctr(6 downto 0))=-1 then
-- 					test_tlast<='1';
-- 				end if;
-- 			else
-- 				test_tvalid<='0';
-- 			end if;
-- 		end if;
-- 	end if; --clk
-- end process;

--------------------------------------
-- Data clock
--------------------------------------

s_axis_tx_clk <= xglink_tx_clk;


--------------------------------------
-- TX source selection (user data or test pattern)
--------------------------------------

-- tx_sel_gen: for i in 0 to NUMBER_OF_LANES-1 generate
-- 	-- -- s_axis_tx_tdata_int(i)  <= sel(tx_test_enable_reg='1', test_tdata, s_axis_tx_tdata(i));
-- 	-- s_axis_tx_tdata_int(i)  <= sel(tx_test_enable_reg='1', to_slv(i,32), s_axis_tx_tdata(i)); -- removed tdata because it has to spread to all tx modules and  caused timing issues
-- 	-- s_axis_tx_tvalid_int(i) <= sel(tx_test_enable_reg='1', test_tvalid, s_axis_tx_tvalid(i));
-- 	-- s_axis_tx_tlast_int(i)  <= sel(tx_test_enable_reg='1', test_tlast, s_axis_tx_tlast(i));
-- 	s_axis_tx_tdata_int(i)  <= s_axis_tx_tdata(i); -- removed tdata because it has to spread to all tx modules and  caused timing issues
-- 	s_axis_tx_tvalid_int(i) <= s_axis_tx_tvalid(i);
-- 	s_axis_tx_tlast_int(i)  <= s_axis_tx_tlast(i);
-- end generate;


--------------------------------------
-- Output source selection (RX data or TX data (bypass))
--------------------------------------

m_axis_rx_tdata <= m_axis_rx_tdata_int2;
m_axis_rx_tvalid <= m_axis_rx_tvalid_int2;
m_axis_rx_tlast <= m_axis_rx_tlast_int2;
m_axis_rx_terror <= m_axis_rx_terror_int2;

bypass_gen: if IMPLEMENT_RX generate
	bypass_proc: process(clk)
	begin
		if rising_edge(clk) then
			for i in 0 to NUMBER_OF_LANES-1 loop
				if bypass(LANE_GROUP_MAP(i))='1' then
					m_axis_rx_tdata_int2(i)  <= s_axis_tx_tdata(i);
					m_axis_rx_tvalid_int2(i) <= s_axis_tx_tvalid(i);
					m_axis_rx_tlast_int2(i)  <= s_axis_tx_tlast(i);
					m_axis_rx_terror_int2(i) <= '0';
				else
					m_axis_rx_tdata_int2(i)  <= m_axis_rx_tdata_int(i);
					m_axis_rx_tvalid_int2(i) <= m_axis_rx_tvalid_int(i);
					m_axis_rx_tlast_int2(i)  <= m_axis_rx_tlast_int(i);
					m_axis_rx_terror_int2(i) <= m_axis_rx_terror_int(i);
				end if;
				if reset_reg(i)='1' then -- Add reset to prevent spurious receives after reset
					m_axis_rx_tvalid_int2(i) <= '0';
				end if;
			end loop;
		end if; -- clk
	end process;
end generate;

--------------------------------------
-- Direct Lanes (No GTX)
--------------------------------------
-- Still use FIFOs and send dats 64 clocks out of every 66 clocks to match the non-direct lanes flow rate


lane_gen: for i in 0 to NUMBER_OF_LANES-1 generate

	direct_gen: if LANE_TO_LINK_MAP(i)<0 and IMPLEMENT_RX generate
		tx_resetdone(i) <= '1';
		rx_resetdone_int(i) <= '1';

		direct0: entity work.xglink_bypass
		  port map (
			s_axis_tx_tdata  => s_axis_tx_tdata(i),
			s_axis_tx_tvalid => s_axis_tx_tvalid(i),
			s_axis_tx_tlast  => s_axis_tx_tlast(i),

			reset_stats      => reset_stats_reg(i),
			tx_fifo_overflow => tx_fifo_overflow(i),
			rx_fifo_overflow => rx_fifo_overflow(i),
			rx_frame_detect  => rx_frame_detect(i),
			rx_err_ctr       => err_ctr(i),
			rx_max_frame     => rx_max_frame_length(i),
			rx_min_frame     => rx_min_frame_length(i),

			m_axis_rx_tdata  => m_axis_rx_tdata_int(i),
			m_axis_rx_tvalid => m_axis_rx_tvalid_int(i),
			m_axis_rx_tlast  => m_axis_rx_tlast_int(i),
			m_axis_rx_terror => m_axis_rx_terror_int(i),

			clk => clk,

			rst => reset_reg(i)
			);
	end generate;

	tx_gen: if LANE_TO_LINK_MAP(i) >= 0 generate
		tx_resetdone(i) <= xglink_tx_resetdone(LANE_TO_LINK_MAP(i));

		xglink_tx_reset(LANE_TO_LINK_MAP(i)) <= reset_reg(i) or not xglink_tx_resetdone(LANE_TO_LINK_MAP(i));

		tx0: entity work.xglink_tx
		  port map (
			s_axis_tx_tdata  => s_axis_tx_tdata(i),
			s_axis_tx_tvalid => s_axis_tx_tvalid(i),
			s_axis_tx_tlast  => s_axis_tx_tlast(i),

			s_axis_tx_clk    => clk,

			reset_stats      => reset_stats_reg(i),
			tx_fifo_overflow => tx_fifo_overflow(i),

			tx_data   => xglink_tx_data(LANE_TO_LINK_MAP(i)),
			tx_header => xglink_tx_header(LANE_TO_LINK_MAP(i)),
			tx_ready  => xglink_tx_ready(LANE_TO_LINK_MAP(i)),

			clk       => xglink_tx_clk,

		    rst => xglink_tx_reset(LANE_TO_LINK_MAP(i)) --! make sure we reset until the clock is available, otherwise the reset does not happen
		  );
	end generate;

		rx_resetdone <= rx_resetdone_int;

	rx_gen: if LANE_TO_LINK_MAP(i) >= 0 and IMPLEMENT_RX generate
		rx_resetdone_int(i) <= xglink_tx_resetdone(LANE_TO_LINK_MAP(i));
		xglink_rx_reset(LANE_TO_LINK_MAP(i)) <= reset_reg(i) or not xglink_rx_resetdone(LANE_TO_LINK_MAP(i)); --! make sure we reset the de-framer until the clock is available, otherwise the reset does not happen

		rx0: entity work.xglink_rx
			port map (
				rx_data         => xglink_rx_data(LANE_TO_LINK_MAP(i)),
				rx_data_valid   => xglink_rx_data_valid(LANE_TO_LINK_MAP(i)),
				rx_header       => xglink_rx_header(LANE_TO_LINK_MAP(i)),
				rx_header_valid => xglink_rx_header_valid(LANE_TO_LINK_MAP(i)),
				rx_clk          => xglink_rx_clk(LANE_TO_LINK_MAP(i)), -- this is a BUFH-driven clock that is usable only in the clock region of the receiver
				-- rx_clk          => rx_clk(NUMBER_OF_BYPASS_LANES + i), -- This does not work in Vivado2014.2 Simulator. The clock transition is never detected in xglink_rx.
				m_axis_rx_tdata  => m_axis_rx_tdata_int(i),
				m_axis_rx_tvalid => m_axis_rx_tvalid_int(i),
				m_axis_rx_tlast  => m_axis_rx_tlast_int(i),
				m_axis_rx_terror => m_axis_rx_terror_int(i),
				m_axis_rx_clk    => clk,

				reset_stats      => reset_stats_reg(i),
				rx_fifo_overflow => rx_fifo_overflow(i),
				rx_frame_detect  => rx_frame_detect(i),
				rx_err_ctr       => err_ctr(i),
				rx_max_frame     => rx_max_frame_length(i),
				rx_min_frame     => rx_min_frame_length(i),
				rst              => xglink_rx_reset(LANE_TO_LINK_MAP(i))
			 );

	end generate;


end generate;




--------------------------------------
-- Core Transmitter/receiver array
--------------------------------------
rx_p_dly <= transport rx_p after 27 ns;
rx_n_dly <= transport rx_n after 27 ns;

-- Implement an array of 10G Transmitters/receivers
core0: entity work.xglink_core
	generic map (
		LINK_SPEED                  => LINK_SPEED,
		NUMBER_OF_TX_LANES          => NUMBER_OF_LINKS,
		NUMBER_OF_RX_LANES          => sel(IMPLEMENT_RX, NUMBER_OF_LINKS, 0),
		NUMBER_OF_REFCLK            => NUMBER_OF_REFCLK,
		LANE_TO_QUAD_MAP            => LANE_TO_QUAD_MAP,
		QUAD_TO_REFCLK_MAP          => QUAD_TO_REFCLK_MAP,
		NUMBER_OF_CONTROL_BYTES     => control_bytes'Length(1),
		NUMBER_OF_STATUS_BYTES      => status_bytes'Length(1),
		EXAMPLE_SIMULATION          => 1,
		EXAMPLE_SIM_GTRESET_SPEEDUP => "TRUE",    -- simulation setting for GT SecureIP model
		DONT_RESET_ON_DATA_ERROR_IN => '0',
		SIM                         => TRUE
		)
	port map (
		tx_p => tx_p,
		tx_n => tx_n,
		rx_p => rx_p_dly,
		rx_n => rx_n_dly,
		refclk_p => refclk_p,
		refclk_n => refclk_n,

		refclk_div2 => refclk_div2,
		txclk_div2 => txclk_div2,

		tx_data   => xglink_tx_data,
		tx_header => xglink_tx_header,
		tx_ready  => xglink_tx_ready,
		tx_clk    => xglink_tx_clk,
		tx_resetdone => xglink_tx_resetdone,

		rx_data         => xglink_rx_data,
		rx_data_valid   => xglink_rx_data_valid,
		rx_header       => xglink_rx_header,
		rx_header_valid => xglink_rx_header_valid,
		rx_clk          => xglink_rx_clk,
		rx_resetdone    => xglink_rx_resetdone,

		control_bytes => control_bytes,
		status_bytes => status_bytes,

		-- Control and reply streams
		CMD_DAT => CMD_DAT,
		CMD_RDY => CMD_RDY,
		RPLY_DAT => RPLY_DAT,
		RPLY_RDY=> RPLY_RDY,
		CTRL_CLK => CTRL_CLK,
		CTRL_RST => CTRL_RST,

		-- clk: in std_logic; --! AXI-S data clock. Not related to the 10G Ethernet clocks.
		areset=> areset --! asynchronous reset
	 );




--------------------------------------
-- RX FIFO and stats
--------------------------------------


 --rx_fifo_gen: for i in 0 to sel(IMPLEMENT_RX, NUMBER_OF_LANES, 0)-1 generate


 	-- Gather stats of the RX data stream
 	fifo_overflow_proc: process(clk)
 	begin
 		if rising_edge(clk) then
 			-- Detect TX FIFO overflows
 			for i in 0 to NUMBER_OF_LANES-1 loop
	 			if tx_fifo_overflow(i)='1' then
	 				tx_fifo_overflow_sticky(i) <= '1';
	 			end if;

	 			if rx_fifo_overflow(i)='1' then
	 				rx_fifo_overflow_sticky(i) <= '1';
	 			end if;

	 			if reset_reg(i)='1' or reset_stats_reg(i)='1' or rx_resetdone_int(i)='0' then
	 				rx_fifo_overflow_sticky(i) <= '0';
	 				tx_fifo_overflow_sticky(i) <= '0';
	 			end if; -- reset
 			end loop;

 		end if; --clk
 	end process;

 --end generate;


end Behavioral;
