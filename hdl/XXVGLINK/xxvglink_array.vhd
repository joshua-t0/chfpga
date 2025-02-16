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

library xpm;
use xpm.vcomponents.all;

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
	s_axis_tx_tdata: in slv64_array(0 to NUMBER_OF_LANES -1);
	s_axis_tx_tvalid: in std_logic_vector(0 to NUMBER_OF_LANES -1);
	s_axis_tx_tlast: in std_logic_vector(0 to NUMBER_OF_LANES -1);


	-- RX user interface (AXI-Streaming, non-blocking, synchronous to clk_out)
	m_axis_rx_tdata: out slv64_array(0 to NUMBER_OF_LANES-1);
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
	resetdone: out std_logic; -- synchronous to clk_out


	-- Control and reply streams
	CMD_DAT: in AXIS8_DAT_STRUCT := (TDATA=> (others=>'0'), TVALID=>'0', TLAST=>'0');
	CMD_RDY: out AXIS8_RDY_STRUCT;
	RPLY_DAT: out AXIS8_DAT_STRUCT;
	RPLY_RDY: in AXIS8_RDY_STRUCT := (TREADY => '1');
	CTRL_CLK : IN std_logic := '0'; -- control clock
	CTRL_RST : in std_logic := '0'
	);
end;


architecture impl of xxvglink_array is

	-- Attribute definitions

	attribute DONT_TOUCH: string;

	--- Constants

	-- XGLINK_CORE Signals

	--signal reset_reg: std_logic_vector(0 to NUMBER_OF_LANES-1);
	--attribute DONT_TOUCH of reset_reg: signal is "true";

	--signal reset_stats_reg: std_logic_vector(0 to NUMBER_OF_LANES-1);
	--attribute DONT_TOUCH of reset_stats_reg: signal is "true";

	signal xglink_tx_data: slv64_array(0 to NUMBER_OF_LINKS-1);
	signal xglink_tx_header: slv2_array(0 to NUMBER_OF_LINKS-1);
	signal xglink_tx_data_sel: slv64_array(0 to NUMBER_OF_LINKS-1);
	signal xglink_tx_header_sel: slv2_array(0 to NUMBER_OF_LINKS-1);
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


	signal rx_p_dly: std_logic_vector(0 to NUMBER_OF_LINKS-1);
	signal rx_n_dly: std_logic_vector(0 to NUMBER_OF_LINKS-1);


	-- Lane signals
	-- signal s_axis_tx_tdata_int: slv32_array(0 to NUMBER_OF_LANES-1);
	-- signal s_axis_tx_tvalid_int: std_logic_vector(0 to NUMBER_OF_LANES-1);
	-- signal s_axis_tx_tlast_int: std_logic_vector(0 to NUMBER_OF_LANES-1);

	signal m_axis_rx_tdata_int: slv64_array(0 to NUMBER_OF_LANES-1);
	signal m_axis_rx_tvalid_int: std_logic_vector(0 to NUMBER_OF_LANES-1);
	signal m_axis_rx_tlast_int: std_logic_vector(0 to NUMBER_OF_LANES-1);
	signal m_axis_rx_tready_int: std_logic_vector(0 to NUMBER_OF_LANES-1);
	signal m_axis_rx_terror_int: std_logic_vector(0 to NUMBER_OF_LANES-1);

	signal rx_tdata: slv64_array(0 to NUMBER_OF_LANES-1);
	signal rx_tvalid: std_logic_vector(0 to NUMBER_OF_LANES-1);
	signal rx_tlast: std_logic_vector(0 to NUMBER_OF_LANES-1);
	signal rx_terror: std_logic_vector(0 to NUMBER_OF_LANES-1);

	signal tx_fifo_overflow: std_logic_vector(0 to NUMBER_OF_LANES-1);
	signal tx_fifo_overflow_sticky: std_logic_vector(0 to NUMBER_OF_LANES-1);
	signal rx_fifo_overflow: std_logic_vector(0 to NUMBER_OF_LANES-1);
	signal rx_fifo_overflow_sticky: std_logic_vector(0 to NUMBER_OF_LANES-1);

	signal rx_frame_detect: std_logic_vector(0 to NUMBER_OF_LANES-1);
	--signal rx_resetdone_int: std_logic_vector(0 to NUMBER_OF_LANES-1);

	signal lane_sel: integer range 0 to 31; --unsigned(4 downto 0);
	signal lane_mon_type: integer range 0 to 15; --unsigned(3 downto 0);
	signal lane_mon_src: integer range 0 to 3; -- unsigned(1 downto 0);
	signal reset_stats: std_logic; -- resets the fifo overflow  and error counter
	signal bypass: std_logic_vector(NUMBER_OF_LANE_GROUPS-1 downto 0);

    signal tx_mon_word: unsigned(15 downto 0) := (others => '0'); -- init for sims
    -- rx_clk monitoring signals
--	signal rx_clk: std_logic_vector(0 to NUMBER_OF_LINKS-1); -- internal local receiver clock for each receiver. Used for monitoring stats
	signal rx_fifo_in_tvalid: std_logic_vector(0 to NUMBER_OF_LANES-1);
	signal rx_fifo_in_tlast: std_logic_vector(0 to NUMBER_OF_LANES-1);
	signal rx_fifo_in_terror: std_logic_vector(0 to NUMBER_OF_LANES-1);
    signal rx_mon_word: unsigned_array(0 to NUMBER_OF_LANES-1)(15 downto 0);

    signal tx_force_en: std_logic;
    signal tx_force_data: slv64;
    signal tx_force_header: slv2;

    signal rx_capture_en: std_logic;
    signal rx_capture_data: slv64_array(0 to NUMBER_OF_LANES-1);
    signal rx_capture_header: slv2_array(0 to NUMBER_OF_LANES-1);
    signal tx_capture_data: slv64;
    signal tx_capture_header: slv2;
    signal rx_capture_word_number: unsigned(15 downto 0);
    signal rx_reset: std_logic;
	-- Control
	signal control_bytes: slv8_array(4 to 15);
	signal status_bytes: slv8_array(2 to 14);


begin

    -- CONTROL bytes 0-3: Used by core common registers

	-- CONTROL byte 4
	lane_sel        <= to_integer(unsigned(control_bytes(4)(7 downto 3))); -- selects from which lane monitoring data is captured
	reset_stats         <= control_bytes(4)(2); --!
	--tx_test_enable      <= control_bytes(0)(1);
    rx_capture_en <= control_bytes(4)(1);
	rx_reset      <= control_bytes(4)(0);

	-- CONTROL byte 5
	bypass              <= control_bytes(5)(NUMBER_OF_LANE_GROUPS-1 downto 0);

	-- CONTROL byte 6

	lane_mon_src        <= to_integer(unsigned(control_bytes(6)(5 downto 4))); -- selects from which source on selected lane data is being monitored
	lane_mon_type        <= to_integer(unsigned(control_bytes(6)(3 downto 0))); -- selects what kind of data is to be monitored


	-- CONTROL byte 7
    tx_force_en <= control_bytes(7)(2);
    tx_force_header <= control_bytes(7)(1 downto 0);
	-- CONTROL byte 8-15
	tx_force_data <= to_slv(control_bytes(8 to 15));
    rx_capture_word_number <= unsigned(tx_force_data(15 downto 0));

    -- STATUS bytes 0-1: Used by xxvglink_core
	-- STATUS byte 2

	 status_bytes(2)(7 downto 6) <= rx_capture_header(lane_sel) when lane_mon_src=1 else
	 							    tx_capture_header;
	-- status_bytes(0)(7 downto 4) <= to_slv(lsb(ctr, 4));
--	status_bytes(2)(3)          <= tx_fifo_overflow_sticky(lane_sel_int);
--	status_bytes(2)(2)          <= rx_frame_detect(lane_sel_int);
	status_bytes(2)(1)          <= areset;
--	status_bytes(2)(0)          <= rx_fifo_overflow_sticky(lane_sel_int);

	-- STATUS byte 3-4
	status_bytes(3 to 4) <= to_slv8_array(rx_mon_word(lane_sel));

	-- STATUS byte 5-6
	status_bytes(5 to 6) <= to_slv8_array(tx_mon_word);
	-- STATUS byte 7-8
--	status_bytes(7 to 8) <= to_slv8_array(rx_min_frame_length(lane_sel_int));
	-- STATUS bytes 9-10
--	status_bytes(9 to 10) <= to_slv8_array(word_ctr);
--	status_bytes(11 to 12) <= to_slv8_array(tx_packet_length);
--	status_bytes(13) <= std_logic_vector(tx_packet_ctr);
	status_bytes(7 to 14) <= to_slv8_array(rx_capture_data(lane_sel)) when lane_mon_src=1 else
	                         to_slv8_array(tx_capture_data);


	-- reset
	--rst_proc: process(tx_clk)
	--begin
	--	if rising_edge(tx_clk) then
	--		reset_reg <= (others => areset);
	--		reset_stats_reg <= (others => reset_stats);
	--	end if; --tx_clk
	--end process;

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


	rstdone_cdc0: xpm_cdc_async_rst
		generic map (RST_ACTIVE_HIGH => 1)
		port map (
			src_arst  => not areset and and(xglink_tx_resetdone) and and(xglink_rx_resetdone),
			dest_clk  => tx_clk,
			dest_arst => resetdone
			);

	--------------------------------------
	-- Output source selection (RX data or TX data (bypass))
	--------------------------------------


	bypass_gen: if IMPLEMENT_RX generate
		bypass_proc: process(all) begin
			if rising_edge(tx_clk) then
				for i in 0 to NUMBER_OF_LANES-1 loop
					if bypass(LANE_GROUP_MAP(i))='1' then
						m_axis_rx_tdata_int(i)  <= s_axis_tx_tdata(i);
						m_axis_rx_tvalid_int(i) <= '0' when not resetdone else s_axis_tx_tvalid(i);
						m_axis_rx_tlast_int(i)  <= s_axis_tx_tlast(i);
						m_axis_rx_terror_int(i) <= '0';
					else
						m_axis_rx_tdata_int(i)  <= rx_tdata(i);
						m_axis_rx_tvalid_int(i) <= '0' when not resetdone else rx_tvalid(i);
						m_axis_rx_tlast_int(i)  <= rx_tlast(i);
						m_axis_rx_terror_int(i) <= rx_terror(i);
					end if;
				end loop;

                -- Set output
                m_axis_rx_tdata <= m_axis_rx_tdata_int;
                m_axis_rx_tvalid <= m_axis_rx_tvalid_int;
                m_axis_rx_tlast <= m_axis_rx_tlast_int;
                m_axis_rx_terror <= m_axis_rx_terror_int;


			end if; -- tx_clk
		end process;
	end generate;

	--------------------------------------
	-- Direct Lanes (No GTX)
	--------------------------------------
	-- Still use FIFOs and send dats 64 clocks out of every 66 clocks to match the non-direct lanes flow rate


	lane_gen: for i in 0 to NUMBER_OF_LANES-1 generate
    	constant link: integer range -1 to NUMBER_OF_LINKS-1 := LANE_TO_LINK_MAP(i);
    begin
		tx_gen: if link < 0 and IMPLEMENT_RX generate
			--tx_resetdone(i) <= '1';
			--rx_resetdone_int(i) <= '1';

			-- Instantiate a direct internal lane, i.e. one that does not go
			-- through a a GTY link. The module simulates the real data throughput
			-- (64 words out of 66 clock). The instance has the input and output
			-- interface of the XGLINK_TX and XGLINK_RX respectively.
			bypass0: entity work.xxvglink_bypass
			  port map (
			  	-- AXI4-Streaming data input, non-blocking, on clk
				s_axis_tx_tdata  => s_axis_tx_tdata(i),
				s_axis_tx_tvalid => s_axis_tx_tvalid(i),
				s_axis_tx_tlast  => s_axis_tx_tlast(i),

				tx_fifo_overflow => tx_fifo_overflow(i), -- non sticky
				rx_fifo_overflow => rx_fifo_overflow(i), -- non sticky

			  	-- AXI4-Streaming data output, non-blocking, on clk
				m_axis_rx_tdata  => rx_tdata(i),
				m_axis_rx_tvalid => rx_tvalid(i),
				m_axis_rx_tlast  => rx_tlast(i),
				m_axis_rx_terror => rx_terror(i),

				clk => tx_clk,
				arst => not resetdone
				);
		elsif link >= 0 generate
			--tx_resetdone(i) <= xglink_tx_resetdone(link);

			--xglink_tx_reset(link) <= not xglink_tx_resetdone(link);

			tx0: entity work.xxvglink_tx
			  port map (
			  	-- AXI4-Streaming data input, non-blocking, on clk
				s_axis_tx_tdata  => s_axis_tx_tdata(i),
				s_axis_tx_tvalid => s_axis_tx_tvalid(i),
				s_axis_tx_tlast  => s_axis_tx_tlast(i),
				s_axis_tx_clk   => tx_clk,

				tx_fifo_overflow => tx_fifo_overflow(i), -- non-sticky

				-- XGLINK_CORE Tx interface
				tx_data   => xglink_tx_data(link), -- 64-bit word
				tx_header => xglink_tx_header(link),
				tx_ready  => xglink_tx_ready(link),
				tx_clk       => tx_clk,

			    arst => not resetdone -- make sure we hold reset until the clock is available, otherwise the reset does not happen
			  );
		end generate; -- tx

		--rx_resetdone <= rx_resetdone_int;

		rx_gen: if LANE_TO_LINK_MAP(i) >= 0 and IMPLEMENT_RX generate
		      constant link: integer range 0 to NUMBER_OF_LINKS-1 := LANE_TO_LINK_MAP(i);
		begin
--			rx_resetdone_int(i) <= xglink_rx_resetdone(link);
--			xglink_rx_reset(link) <= xglink_rx_resetdone(link); --! make sure we reset the de-framer until the clock is available, otherwise the reset does not happen

			rx0: entity work.xxvglink_rx
				port map (
					rx_data         => xglink_rx_data(link),
					rx_data_valid   => xglink_rx_data_valid(link),
					rx_header       => xglink_rx_header(link),
					rx_header_valid => xglink_rx_header_valid(link),
					rx_clk          => xglink_rx_clk(link),
					-- rx_clk          => rx_clk(NUMBER_OF_BYPASS_LANES + i), -- This does not work in Vivado2014.2 Simulator. The clock transition is never detected in xglink_rx.
					m_axis_rx_tdata  => rx_tdata(i),
					m_axis_rx_tvalid => rx_tvalid(i),
					m_axis_rx_tlast  => rx_tlast(i),
					m_axis_rx_terror => rx_terror(i),
					m_axis_rx_clk    => tx_clk,

					fifo_overflow    => rx_fifo_overflow(i),
					fifo_in_tvalid   => rx_fifo_in_tvalid(i),
					fifo_in_tlast    => rx_fifo_in_tlast(i),
					arst             => not resetdone
				 );
		end generate; -- rx
	end generate; -- for each lane




	--------------------------------------
	-- Core Transmitter/receiver array
	--------------------------------------
	rx_p_dly <= transport rx_p after 27 ns;
	rx_n_dly <= transport rx_n after 27 ns;

    xglink_tx_data_sel <=  (others => tx_force_data) when tx_force_en else xglink_tx_data;
    xglink_tx_header_sel <=  (others => tx_force_header) when tx_force_en else xglink_tx_header;

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
			SIM                         => SIM
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

			tx_data   => xglink_tx_data_sel,
			tx_header => xglink_tx_header_sel,
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
    -- Stats on local receiver clocks
    --------------------------------------
    rxmon_gen: for i in 0 to NUMBER_OF_LANES-1 generate
        constant link: integer range -1 to NUMBER_OF_LINKS-1 := LANE_TO_LINK_MAP(i);
        signal word_ctr: unsigned(15 downto 0) := (others => '0'); -- init for sims
        signal tvalid, tlast, err, fifo_overflow: std_logic;
        signal rst: std_logic;
        signal rx_capture_en_reg: std_logic;
    begin
        rxlink_gen: if link >= 0 generate

        cap_cdc0: xpm_cdc_single
            generic map (SRC_INPUT_REG => 0)
            port map (
                src_clk => ctrl_clk,
                src_in => rx_capture_en,
                dest_clk => xglink_rx_clk(link),
                dest_out => rx_capture_en_reg
            );

        process(all) begin
            if rising_edge(xglink_rx_clk(link)) then
                rst <= reset_stats or not xglink_rx_resetdone(link);

                -- capture word
--                rx_capture_en_reg <= rx_capture_en;
                if rx_capture_en_reg='1' and (rx_capture_word_number = X"FFFF" or rx_capture_word_number=word_ctr) then
                    rx_capture_data(i) <= xglink_rx_data(link) when xglink_rx_data_valid(link);
                    rx_capture_header(i) <= xglink_rx_header(link) when xglink_rx_header_valid(link);
                end if;

                tvalid <= rx_fifo_in_tvalid(i);
                tlast <= rx_fifo_in_tlast(i);
                err <= rx_fifo_in_terror(i);

                if tvalid then
                    word_ctr <= (others => '0') when tlast else word_ctr + 1;
                end if;

                case lane_mon_type is
                    when 0 => -- clock counter
                        rx_mon_word(i) <= rx_mon_word(i) + 1;
                    when 1 => -- word counter
                        rx_mon_word(i) <= word_ctr;
                    when 2 => -- frame counter
                        rx_mon_word(i) <= (others => '0') when rst else rx_mon_word(i)+1 when tvalid and tlast;
                    when 3 => -- frame length
                        rx_mon_word(i) <= (others => '0') when rst else word_ctr when tvalid and tlast;
                    when 4 => -- min frame len
                        rx_mon_word(i) <= (others => '1') when rst else word_ctr when ??(tvalid and tlast) and word_ctr < rx_mon_word(i);
                    when 5 => -- max frame len
                        rx_mon_word(i) <= (others => '0') when rst else word_ctr when ??(tvalid and tlast) and word_ctr > rx_mon_word(i);
                    when 6 => -- error counter
                        rx_mon_word(i) <= (others => '0') when rst else (rx_mon_word(i) + 1) when (tvalid='1' and tlast='1' and err='1' and signed(rx_mon_word(i))/=-1);
                     when others => -- flags
                        rx_mon_word(i) <= (
                            0 => tvalid,
                            1 => tlast,
                            4 => rst,
                            others => '0');
                end case; -- lane_mon_sel
            end if; -- clk
        end process;
    else generate
        rx_mon_word(i) <= (others => '0');
    end generate; -- if link is present
    end generate; -- for lane


   txmon_blk: block
        signal word_ctr: unsigned(15 downto 0) := (others => '0'); -- init for sims
        signal rst: std_logic;
        signal tvalid, tlast, err, fifo_overflow: std_logic;
    begin

    	cap_blk: block
    	    signal link: integer range -1 to NUMBER_OF_LINKS-1;
            signal capture_en_reg: std_logic;
        begin
            link <= LANE_TO_LINK_MAP(lane_sel);
	        cap_cdc0: xpm_cdc_single
	            generic map (SRC_INPUT_REG => 0)
	            port map (
	                src_clk => ctrl_clk,
	                src_in => rx_capture_en,
	                dest_clk => tx_clk,
	                dest_out => capture_en_reg
	            );

	        process(all) begin
	            if rising_edge(tx_clk) then
	                -- capture word
	                if capture_en_reg then
	                    tx_capture_data <= xglink_tx_data(link) when xglink_tx_ready(link);
	                    tx_capture_header <= xglink_tx_header(link) when xglink_tx_ready(link);
	                end if;
	            end if; -- clk
	        end process;
	    end block;

     -- Gather stats of the RX data stream
        process(all) begin
            if rising_edge(tx_clk) then
                rst <= reset_stats or not resetdone;

                case lane_mon_src is
                    when 0 =>
                        tvalid <= s_axis_tx_tvalid(lane_sel);
                        tlast <= s_axis_tx_tlast(lane_sel);
                        err <= '0';
                        fifo_overflow <= tx_fifo_overflow(lane_sel);
                    when 1 =>
                        tvalid <= m_axis_rx_tvalid(lane_sel);
                        tlast <= m_axis_rx_tlast(lane_sel);
                        err <= m_axis_rx_terror(lane_sel);
                        fifo_overflow <= rx_fifo_overflow(lane_sel);
                    when others =>
                        tvalid <= '0';
                        tlast <= '0';
                        err <= '0';
                        fifo_overflow <= '0';
                         -- do nothing
                end case;

                -- Count words
                if tvalid then
                    word_ctr <= (others => '0') when tlast else word_ctr + 1;
                end if;

                case lane_mon_type is
                    when 0 => -- clock counter
                        tx_mon_word <= tx_mon_word + 1;
                    when 1 => -- word counter
                        tx_mon_word <= word_ctr;
                    when 2 => -- frame counter
                        tx_mon_word <= (others => '0') when rst else tx_mon_word+1 when tvalid and tlast;
                    when 3 => -- frame length
                        tx_mon_word <= (others => '0') when rst else word_ctr when tvalid and tlast;
                    when 4 => -- min frame len
                        tx_mon_word <= (others => '1') when rst else word_ctr when ??(tvalid and tlast) and word_ctr < tx_mon_word;
                    when 5 => -- max frame len
                        tx_mon_word <= (others => '0') when rst else word_ctr when ??(tvalid and tlast) and word_ctr > tx_mon_word;
                    when 6 => -- error counter
                        tx_mon_word <= (others => '0') when rst else (tx_mon_word + 1) when (tvalid='1' and tlast='1' and err='1' and signed(tx_mon_word)/=-1);
                    when 7 => -- fifo overflow counter
                        tx_mon_word <= (others => '0') when rst else tx_mon_word + 1 when fifo_overflow='1' and not all_ones(tx_mon_word);
                    when others => -- flags
                        tx_mon_word <= (
                            0 => tvalid,
                            1 => tlast,
                            2 => err,
                            3 => fifo_overflow,
                            4 => rst,
                            others => '0');
                end case; -- lane_mon_sel
            end if; -- clk
        end process;
    end block; -- tx mon

 end impl;
