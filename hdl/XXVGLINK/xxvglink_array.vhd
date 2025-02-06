----------------------------------------------------------------------------------
-- Company:  McGill University
-- Engineer: JF CLiche
--
-- Create Date: 2024-01-20
-- Design Name:
-- Module Name: xxvglink_array
-- Project Name: chFPGA
-- Target Devices: Ultrascale+
-- Tool Versions: Vivado 2022.2+
-- Description: Implements an array of 25G packet transmitters and receivers
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

-- Implements an array of simple packet transmitters and receivers at 25 Gbps.
--
-- Packets use 25G Ethernet-like low-level SOF, EOF, Idles and CRCs tht directly encapsulate a raw
-- payload. The protocol implement higher-level Ethernet features such as addressing, FEC etc.
--
-- Data transmission is performed using GTYs. The module assumes there is one or multiple 156.25 MHz
-- reference clocks to provide clocking to the QUADs associated with the target GTYs.
-- ``NUMBER_OF_REFCLK`` indicate how many reference clocks are provided, and ``QUAD_TO_REFCLK_MAP``
-- indicate which reference clock (numbered from 0 to NUMBER_OF_REFCLK-1) is to be used for each
-- quad. Also, the LANE_TO_QUAD_MAP generics specify which quad is associated with each lane.
--
-- Input (slave AXIS interface)
-- ----------------------------
--
-- The input is a 64-bit wide, non-blocking AXI-Streaming interface synchronous to the ``clk_out`` clock provided this module . Valid data is indicated by tvalid='1'.
-- The end of a packet is signaled when ``tlast='1'`` on a valid (``tvalid='1'``) word.
--
-- The input is non-blocking, and data is buffered by a FIFO in each TX module. Since the module
-- does not provide flow control, it is assumed that  the average data rate shall be less than 25
-- Gbps in order to prevent FIFO overflows.
--
-- The input data does not have to be contiguous, i.e. we don't have to provide valid data on every
-- clock. If the Tx FIFO runs out of data, idle codes will be sent down the link. The transmitter
-- will add a start-of-frame control code at the beginning of the packets, and will add a CRC32 and
-- an end-of-frame code at the end of the packet.
--
-- The input interface for every transmit lane operate on a single transmit clock, which is
-- generated from the GTX reference clock.
--
-- Output (master AXIS interface)
-- ------------------------------
--
-- Each RX lane provides data on its own recovered clock.
--
-- (***check) However, a 512-word deep asynchronous FIFO provides an output data flow on the clock provided by the user on m_axis_rx_clk(i).
-- Typically, every RX clock will be connected to the clock provided by the tranmitter (clk_out) so the logic can operate on a single clock domain.
-- A non-sticky FIFO overflow flag (on the internal rx clock) is available to detect if the FIFO has overflowed.
entity xxvglink_array is
	generic (

	LANE_TO_LINK_MAP: integer_array  := (0 => 0, 1 => 1, 2=> 2); -- List indictiong the GTY link number associated to each lane
	LINK_TO_QUAD_MAP: integer_array  := (0 to 1=> 0, 2 => 1); -- Indicates which quad is associated to each GTY link.
	QUAD_TO_REFCLK_MAP: integer_array:= (0 => 0, 1=> 0); -- Indicates which refclk is associated with each QUAD
	IMPLEMENT_RX : boolean          := TRUE;

    -- Derived parameters
	NUMBER_OF_LANES: integer        := LANE_TO_LINK_MAP'LENGTH; -- Number of logical data link - Do not override
	NUMBER_OF_LINKS: integer        := max(LANE_TO_LINK_MAP) + 1; --  Number of physical data links (GTYs) - Do not override
    LANE_GROUP_MAP: integer_array    := (0 to NUMBER_OF_LANES-1 => 0); -- Array indicating the group to which each lane is assiciated with
	NUMBER_OF_LANE_GROUPS: integer  := max(LANE_GROUP_MAP) + 1; -- Do not override
	NUMBER_OF_REFCLK: integer       := max(QUAD_TO_REFCLK_MAP) + 1; -- Number of reference clocks - Do not override

	SIM: boolean                    := FALSE
	);
	port (
	-- GTX interfaces
	tx_p: out std_logic_vector(0 to NUMBER_OF_LINKS-1);
	tx_n: out std_logic_vector(0 to NUMBER_OF_LINKS-1);
	rx_p: in std_logic_vector(0 to NUMBER_OF_LINKS-1);
	rx_n: in std_logic_vector(0 to NUMBER_OF_LINKS-1);
	refclk_p : in std_logic_vector(0 to NUMBER_OF_REFCLK-1); --156.250 clock
	refclk_n : in std_logic_vector(0 to NUMBER_OF_REFCLK-1);

	-- TX user interface (AXI-Streaming, blocking, synchronous to clk_out)
	s_axis_tx_tdata: in slv_array(0 to NUMBER_OF_LANES -1)(63 downto 0);
	s_axis_tx_tvalid: in std_logic_vector(0 to NUMBER_OF_LANES -1);
	s_axis_tx_tlast: in std_logic_vector(0 to NUMBER_OF_LANES -1);


	-- RX user interface (AXI-Streaming, non-blocking, synchronous to clk_out)
	m_axis_rx_tdata: out slv_array(0 to NUMBER_OF_LANES-1)(63 downto 0);
	m_axis_rx_tvalid: out std_logic_vector(0 to NUMBER_OF_LANES-1);
	m_axis_rx_tlast: out std_logic_vector(0 to NUMBER_OF_LANES-1);
	m_axis_rx_terror: out std_logic_vector(0 to NUMBER_OF_LANES-1); -- active high on TLAST=1 if an error occured in the frame


	-- Data pipeline clock & resets
	clk_out: out std_logic; -- Data word clock generated by the GTY
	areset: in std_logic; -- asynchronous reset


	-- Clock monitors
	refclk_div2: out std_logic_vector(0 to NUMBER_OF_REFCLK-1); -- logic signal toggling at half of the 156.25 MHz reference clock frequency
	txclk_div2: out std_logic; -- Logic signal toggling at half of the Tx word clock frequency clk_out

	-- Monitor & debugging signals
	tx_resetdone: out std_logic_vector(0 to NUMBER_OF_LANES-1);
	rx_resetdone: out std_logic_vector(0 to NUMBER_OF_LANES-1);
	lane_monitor: out std_logic;


	-- Control and reply streams
	CMD_DAT: in AXIS8_DAT_STRUCT := (TDATA=> (others=>'0'), TVALID=>'0', TLAST=>'0');
	CMD_RDY: out AXIS8_RDY_STRUCT;
	RPLY_DAT: out AXIS8_DAT_STRUCT;
	RPLY_RDY: in AXIS8_RDY_STRUCT := (TREADY => '1');
	CTRL_CLK : IN std_logic := '0'; -- control clock
	CTRL_RST : in std_logic := '0'
	);
end;


architecture Implementation of xxvglink_array is

	-- Attribute definitions

	attribute DONT_TOUCH: string;

	--- Constants

	-- XGLINK_CORE Signals

	signal reset_reg: std_logic_vector(0 to NUMBER_OF_LANES-1);
	attribute DONT_TOUCH of reset_reg: signal is "true";

	signal reset_stats_reg: std_logic_vector(0 to NUMBER_OF_LANES-1);
	attribute DONT_TOUCH of reset_stats_reg: signal is "true";

	signal xglink_tx_data: slv64_array(0 to NUMBER_OF_LINKS-1);
	signal xglink_tx_header: slv2_array(0 to NUMBER_OF_LINKS-1);
	signal xglink_tx_ready: std_logic_vector(0 to NUMBER_OF_LINKS-1);
	signal tx_clk: std_logic;
	signal xglink_tx_resetdone: std_logic_vector(0 to NUMBER_OF_LINKS-1);

	signal xglink_tx_reset: std_logic_vector(0 to NUMBER_OF_LINKS-1);

	signal xglink_rx_data: slv64_array(0 to NUMBER_OF_LINKS-1);
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

	signal m_axis_rx_tdata_int: slv_array(0 to NUMBER_OF_LANES-1)(63 downto 0);
	signal m_axis_rx_tvalid_int: std_logic_vector(0 to NUMBER_OF_LANES-1);
	signal m_axis_rx_tlast_int: std_logic_vector(0 to NUMBER_OF_LANES-1);
	signal m_axis_rx_tready_int: std_logic_vector(0 to NUMBER_OF_LANES-1);
	signal m_axis_rx_terror_int: std_logic_vector(0 to NUMBER_OF_LANES-1);

	signal m_axis_rx_tdata_int2: slv_array(0 to NUMBER_OF_LANES-1)(63 downto 0);
	signal m_axis_rx_tvalid_int2: std_logic_vector(0 to NUMBER_OF_LANES-1);
	signal m_axis_rx_tlast_int2: std_logic_vector(0 to NUMBER_OF_LANES-1);
	signal m_axis_rx_terror_int2: std_logic_vector(0 to NUMBER_OF_LANES-1);

	signal tx_fifo_overflow: std_logic_vector(0 to NUMBER_OF_LANES-1);
	signal tx_fifo_overflow_sticky: std_logic_vector(0 to NUMBER_OF_LANES-1);
	signal rx_fifo_overflow: std_logic_vector(0 to NUMBER_OF_LANES-1);
	signal rx_fifo_overflow_sticky: std_logic_vector(0 to NUMBER_OF_LANES-1);

	signal rx_frame_detect: std_logic_vector(0 to NUMBER_OF_LANES-1);
	signal rx_resetdone_int: std_logic_vector(0 to NUMBER_OF_LANES-1);

	signal lane_sel: unsigned(4 downto 0);
	signal reset_stats: std_logic; -- resets the fifo overflow  and error counter
	signal bypass: std_logic_vector(NUMBER_OF_LANE_GROUPS-1 downto 0);
	signal err_ctr: slv16_array(0 to NUMBER_OF_LANES-1); -- counts rx errors on lane specified uin 'lane_sel'
	signal rx_max_frame_length: slv13_array(0 to NUMBER_OF_LANES-1); -- counts rx errors on lane specified uin 'lane_sel'
	signal rx_min_frame_length: slv13_array(0 to NUMBER_OF_LANES-1); -- counts rx errors on lane specified uin 'lane_sel'
    signal word_ctr: unsigned(15 downto 0) := (others => '0'); -- init for sims
    signal tx_packet_length: unsigned(15 downto 0):= (others => '0'); -- init for sims
    signal tx_packet_ctr: unsigned(7 downto 0) := (others => '0'); -- init for sims

	-- Control
	signal control_bytes: slv8_array(0 to 1);
	signal status_bytes: slv8_array(0 to 11);


begin


	-- CONTROL byte 4
	lane_sel            <= unsigned(control_bytes(0)(7 downto 3)); --! selects from which lane
	reset_stats         <= control_bytes(0)(2); --!
	--tx_test_enable      <= control_bytes(0)(1);


	-- CONTROL byte 5
	bypass              <= control_bytes(1)(NUMBER_OF_LANE_GROUPS-1 downto 0);

	-- -- CONTROL byte 5
	-- rx_fifo_reset       <= control_bytes(1)(0);

	-- STATUS byte 2

	-- status_bytes(0)(7 downto 4) <= to_slv(lsb(ctr, 4));
	status_bytes(2-2)(3)          <= tx_fifo_overflow_sticky(to_integer(lane_sel));
	status_bytes(2-2)(2)          <= rx_frame_detect(to_integer(lane_sel));
	status_bytes(2-2)(1)          <= areset;
	status_bytes(2-2)(0)          <= rx_fifo_overflow_sticky(to_integer(lane_sel));

	-- STATUS byte 3-4
	status_bytes(3-2 to 4-2) <= to_slv8_array(err_ctr(to_integer(lane_sel)));

	-- STATUS byte 5-6
	status_bytes(5-2 to 6-2) <= to_slv8_array(rx_max_frame_length(to_integer(lane_sel)));
	-- STATUS byte 7-8
	status_bytes(7-2 to 8-2) <= to_slv8_array(rx_min_frame_length(to_integer(lane_sel)));
	-- STATUS bytes 9-10
	status_bytes(9-2 to 10-2) <= to_slv8_array(word_ctr);
	status_bytes(11-2 to 12-2) <= to_slv8_array(tx_packet_length);
	status_bytes(13-2) <= std_logic_vector(tx_packet_ctr);


	-- reset
	rst_proc: process(tx_clk)
	begin
		if rising_edge(tx_clk) then
			reset_reg <= (others => areset);
			reset_stats_reg <= (others => reset_stats);
		end if; --tx_clk
	end process;

	--! Data source selector
	--! We implement it as a combinatorial mux because we don't want to implement a FIFO to deal with tready if we can avoid it.

	--------------------------------------
	-- Test pattern generator
	--------------------------------------

	-- -- Test pattern generator
	-- test_pat_proc: process(tx_clk)
	-- 	variable test_byte: std_logic_vector(7 downto 0);
	-- begin
	-- 	if rising_edge(tx_clk) then

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
	-- 	end if; --tx_clk
	-- end process;

	--------------------------------------
	-- Data clock
	--------------------------------------

	clk_out <= tx_clk;


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
		bypass_proc: process(tx_clk)
		begin
			if rising_edge(tx_clk) then
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
			end if; -- tx_clk
		end process;
	end generate;

	--------------------------------------
	-- Direct Lanes (No GTX)
	--------------------------------------
	-- Still use FIFOs and send dats 64 clocks out of every 66 clocks to match the non-direct lanes flow rate


	lane_gen: for i in 0 to NUMBER_OF_LANES-1 generate

		tx_gen: if LANE_TO_LINK_MAP(i) < 0 and IMPLEMENT_RX generate
			tx_resetdone(i) <= '1';
			rx_resetdone_int(i) <= '1';

			-- Instantiate a direct internal lane, i.e. one that does not go
			-- through a a GTY link. The module simulates the real data throughput
			-- (64 words out of 66 clock). The instance has the input and output
			-- interface of the XGLINK_TX and XGLINK_RX respectively.
			direct0: entity work.xxvglink_bypass
			  port map (
			  	-- AXI4-Streaming data input, non-blocking, on clk
				s_axis_tx_tdata  => s_axis_tx_tdata(i),
				s_axis_tx_tvalid => s_axis_tx_tvalid(i),
				s_axis_tx_tlast  => s_axis_tx_tlast(i),

				tx_fifo_overflow => tx_fifo_overflow(i), -- non sticky
				rx_fifo_overflow => rx_fifo_overflow(i), -- non sticky
				reset_stats      => reset_stats_reg(i), -- for rx stats below only
				rx_frame_detect  => rx_frame_detect(i),
				rx_err_ctr       => err_ctr(i),
				rx_max_frame     => rx_max_frame_length(i),
				rx_min_frame     => rx_min_frame_length(i),

			  	-- AXI4-Streaming data output, non-blocking, on clk
				m_axis_rx_tdata  => m_axis_rx_tdata_int(i),
				m_axis_rx_tvalid => m_axis_rx_tvalid_int(i),
				m_axis_rx_tlast  => m_axis_rx_tlast_int(i),
				m_axis_rx_terror => m_axis_rx_terror_int(i),

				clk => tx_clk,
				rst => reset_reg(i)
				);
		elsif LANE_TO_LINK_MAP(i) >= 0 generate
			tx_resetdone(i) <= xglink_tx_resetdone(LANE_TO_LINK_MAP(i));

			xglink_tx_reset(LANE_TO_LINK_MAP(i)) <= reset_reg(i) or not xglink_tx_resetdone(LANE_TO_LINK_MAP(i));

			tx0: entity work.xxvglink_tx
			  port map (
			  	-- AXI4-Streaming data input, non-blocking, on clk
				s_axis_tx_tdata  => s_axis_tx_tdata(i),
				s_axis_tx_tvalid => s_axis_tx_tvalid(i),
				s_axis_tx_tlast  => s_axis_tx_tlast(i),

				tx_fifo_overflow => tx_fifo_overflow(i), -- non-sticky

				-- XGLINK_CORE Tx interface
				tx_data   => xglink_tx_data(LANE_TO_LINK_MAP(i)), -- 32-bit word
				tx_header => xglink_tx_header(LANE_TO_LINK_MAP(i)),
				tx_ready  => xglink_tx_ready(LANE_TO_LINK_MAP(i)),

				clk       => tx_clk,

			    rst => xglink_tx_reset(LANE_TO_LINK_MAP(i)) --! make sure we hold reset until the clock is available, otherwise the reset does not happen
			  );
		end generate; -- tx

		rx_resetdone <= rx_resetdone_int;

		rx_gen: if LANE_TO_LINK_MAP(i) >= 0 and IMPLEMENT_RX generate
			rx_resetdone_int(i) <= xglink_rx_resetdone(LANE_TO_LINK_MAP(i));
			xglink_rx_reset(LANE_TO_LINK_MAP(i)) <= reset_reg(i) or not xglink_rx_resetdone(LANE_TO_LINK_MAP(i)); --! make sure we reset the de-framer until the clock is available, otherwise the reset does not happen

			rx0: entity work.xxvglink_rx
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
					m_axis_rx_clk    => tx_clk,

					reset_stats      => reset_stats_reg(i),
					rx_fifo_overflow => rx_fifo_overflow(i),
					rx_frame_detect  => rx_frame_detect(i),
					rx_err_ctr       => err_ctr(i),
					rx_max_frame     => rx_max_frame_length(i),
					rx_min_frame     => rx_min_frame_length(i),
					rst              => xglink_rx_reset(LANE_TO_LINK_MAP(i))
				 );
		end generate; -- rx
	end generate; -- for each lane




	--------------------------------------
	-- Core Transmitter/receiver array
	--------------------------------------
	rx_p_dly <= transport rx_p after 27 ns;
	rx_n_dly <= transport rx_n after 27 ns;

	-- Implement an array of 10G Transmitters/receivers
	core0: entity work.xxvglink_core
		generic map (
			IMPLEMENT_RX                => IMPLEMENT_RX,
			LINK_TO_QUAD_MAP            => LINK_TO_QUAD_MAP,
			QUAD_TO_REFCLK_MAP          => QUAD_TO_REFCLK_MAP,
			NUMBER_OF_CONTROL_BYTES     => control_bytes'LENGTH(1),
			NUMBER_OF_STATUS_BYTES      => status_bytes'LENGTH(1),
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
			tx_clk    => tx_clk,
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
	-- Stats
	--------------------------------------

 	-- Gather stats of the RX data stream
 	fifo_overflow_proc: process(tx_clk)
 	begin
 		if rising_edge(tx_clk) then
            -- Count words
            if s_axis_tx_tvalid(0)='1' then
                word_ctr <= word_ctr + 1;
                if  s_axis_tx_tlast(0)='1' then
                    word_ctr <= (others => '0');
                    tx_packet_ctr <= tx_packet_ctr + 1;
                    tx_packet_length <= word_ctr when word_ctr > tx_packet_length;
                end if;

            end if;
            if areset or reset_stats_reg(0) then
                tx_packet_length <= (others =>'0');
                tx_packet_ctr <= (others =>'0');
            end if;

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

 		end if; --tx_clk
 	end process;

 --end generate;


end Implementation;
