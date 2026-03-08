----------------------------------------------------------------------------------
-- Company: McGill Univ.
-- Engineer: JF Cliche
--
-- Create Date:    13:54:40 11/19/2010
-- Design Name:    chFPGA
-- Module Name:    UDP_MAC_RX
-- Project Name:   CHIME
-- Target Devices: K7
-- Tool versions:
-- Description: Implements a simplified Gigabit Ethernet UDP/IP/Ethernet Receiver Packetizer and MAC with a GMII output interface.
-- See UDP_MAC for description
--
-- Dependencies:
--
-- Revision:
--    110106 JFC - Implemented basic receiver. Checks incoming MAC/IP/port but tdo not act on them yet.
--    110108 JFC - Tested UDP with PHY. Debugegd the PHY interface with IODELAYS to improve timing.
--    110317 JFC - RX and TX splitted. Created this file.
--    110430 JFC - Added MAC and IP address/PORT parameters. Changed code to use these instead of the RAM values. Had to rewrite the way the IP checksum is pre-computed to make sure this takes into account the changing destination IP address.
--    110XXX JFC:  RX: implemented adderss/validity checks. Auto flush buffer if frame is rejected. Handled Ethernet padding.
--    120302 JFC - Changed the front end (data readout) logic to be AXI4_STREAM compliant. Used an easier to read state machine and eliminated the explicit combinatorial logic
--    120331 JFC - Added ARP request decoding and generate ARP_REQUEST signal for the TX.
--		120709 JFC - Added separate ARP reply addresses to prevent spurious ARP requests from stealing other's sessions
-- Additional Comments:
-- TODO:
--    110112 JFC:  Add the RESET logic to the back end process
-- Possible features:

----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.VComponents.all;

library xpm;
use xpm.vcomponents.all;

-- Implements a simplified Gigabit Ethernet UDP/IP/Ethernet Receiver Packetizer and MAC with a GMII output interface with ARP functionality.
--
-- This module receives 1G Ethernet data from a GMII (8-bit parallel) interface
--
-- Incoming GMII data is decoded on-the-fly using a state machine to inspect each interesting part of the packet.
-- The receiver will answer to broadcast packets to to packets with the MAC and IP addresses specified by corresponding the input ports, as long as they also have the matching destination port number.
-- When it arrives, the UDP payload is written inthe data FIFO. The Flag fifo is then written with 0 or 1 to indicate that the packet is complete, and whether the data is valid (good CRC).
-- ARP requests that have a matching IP address are processed by serring an ARM request flag that will be used to tell the TX module to send an ARM reply.

-- UDP/IP/Ethernet Packet structure
--
-- - Ethernet header
--
--     X"00", X"1b", X"fc", X"43", X"ba", X"ff", -- Ethernet destination MAC address
--     X"12", X"34", X"56", X"78", X"9A", X"BC", -- Ethernet source MAC address
--     X"08", X"00",	-- Ethertype: Ethernet (jumbo = 0x8870)
--
--  -IP header
--
--     X"45", X"00",	-- IP: Version, Header length, DSCP/ECP
--     X"00", X"00",	-- IP: Length. Not used. Actual length value (DATA_LENGTH+28) is transmitted instead. 0x0030 for a 20-byte payload.
--     X"14", X"26",	-- IP: identification (To be overriden)
--     X"00", X"00",	-- IP: Flags and fragments offset
--     X"74",	-- IP: Time to live
--     X"11",	-- IP: protocol =UDP
--     X"00", X"00",	-- IP: Header checksum.  Not used. Actual IP Header checksum computed on the fly is transmitted instead. 0x0A6F for a 20-byte payload
--     X"0A", X"0A", X"0A", X"0B",	-- IP: Source IP
--     X"0A", X"0A", X"0A", X"0A",	-- IP: Destination IP
--
--  - UDP header
--     X"00", X"00",	-- UDP: Source port (still works if zero)
--     X"A0", X"28",	-- UDP: Destination port
--     X"00", X"00",	-- UDP: Length . Not used. Actual length value (DATA_LENGTH+8) is transmitted instead . 0x001C for a 20-byte payload.
--     X"00", X"00",	-- UDP: Checksum (disabled)
--  - UDP payload
--  - Padding (if needed to guarantee minimum frame length)
--  - Ethernet CRC32
--
entity udp_mac_rx is
	generic(
		BROADCAST_IP_PORT: integer := 40999
		);
	port (
		-- User-side streaming interface
		
		local_mac_addr         : in std_logic_vector(47 downto 0);
		local_ip_addr          : in std_logic_vector(31 downto 0);
		local_ip_port          : in std_logic_vector(15 downto 0);
		local_subarray         : in std_logic_vector(1 downto 0);

		latest_remote_mac_addr : out std_logic_vector(47 downto 0);
		latest_remote_ip_addr  : out std_logic_vector(31 downto 0);
		latest_remote_ip_port  : out std_logic_vector(15 downto 0);

		arp_request            : out std_logic;
		arp_remote_mac_addr    : out std_logic_vector(47 downto 0);
		arp_remote_ip_addr     : out std_logic_vector(31 downto 0);

		m_axis_udp_rx_tdata    : out std_logic_vector (7 downto 0);
		m_axis_udp_rx_tvalid   : out std_logic;
		m_axis_udp_rx_tlast    : out std_logic;
		m_axis_udp_rx_tready   : in std_logic;
		clk                    : in  std_logic; -- user-side clock, independent from the receive clock


		-- gmii interface
		
		gmii_rxclk             : in  std_logic; -- receive clock from phy
		gmii_rxctrl_rxdv       : in  std_logic; -- receive data valid
		gmii_rxd               : in  std_logic_vector(7 downto 0); -- receive data

		-- system
		
		rx_overflow            : out std_logic;
		rst                    : in std_logic
		);
end udp_mac_rx;

architecture impl of udp_mac_rx is

	-- RX state machine states
	TYPE RX_STATE_TYPE IS -- States of the RX state machine
		(
		RX_STATE_STDBY,
		RX_STATE_MAC_DEST_ADDR,
		RX_STATE_MAC_SRC_ADDR,
		RX_STATE_ETHERTYPE,
		RX_STATE_IP_TYPE,
		RX_STATE_IP_HEADER,
		RX_STATE_IP_PROTOCOL,
		RX_STATE_IP_CHECKSUM,
		RX_STATE_IP_SRC_ADDR,
		RX_STATE_IP_DEST_ADDR,
		RX_STATE_IP_SRC_PORT,
		RX_STATE_IP_DEST_PORT,
		RX_STATE_UDP_LENGTH,
		RX_STATE_UDP_CHECKSUM,
		RX_STATE_PAYLOAD,
		RX_STATE_SKIP_CRC,
		RX_STATE_CHECK_CRC,
		RX_STATE_SKIP,
		RX_STATE_ARP_TYPE,
		RX_STATE_ARP_OPCODE,
		RX_STATE_ARP_SENDER_MAC,
		RX_STATE_ARP_SENDER_IP,
		RX_STATE_ARP_TARGET_MAC,
		RX_STATE_ARP_TARGET_IP
	);

	signal rx_state: RX_STATE_TYPE := RX_STATE_STDBY; -- Initialization needed
	signal rx_state_ctr: unsigned(7 downto 0) := (others => '0'); -- counts clocks within a state


	signal rx_udp_length: std_logic_vector(15 downto 0); -- udp packet length (including header), to be insterted in udp length field
	signal rx_payload_length: unsigned(15 downto 0); -- payload length
	signal rx_payload_ctr: unsigned(15 downto 0) := (others => '0'); -- payload counter.

	--signal rx_clk: std_logic;
	signal gmii_rx_en: std_logic;
	signal gmii_rx_d: std_logic_vector(7 downto 0 );

	signal rx_data, rx_data_dly, rx_data_dly1, rx_data_dly2, rx_data_dly3, rx_data_dly4: std_logic_vector(7 downto 0 );
	signal rx_data_wide: std_logic_vector(47 downto 0);
	signal rx_start_of_frame,rx_frame: std_logic:='0';

	signal ip_addr_broadcast: std_logic;
	signal latest_remote_mac_addr_temp: std_logic_vector(47 downto 0);
	signal latest_remote_ip_addr_temp: std_logic_vector(31 downto 0);
	signal latest_remote_ip_port_temp: std_logic_vector(15 downto 0);


	signal rx_crc_calc: std_logic:='0'; --
	signal rx_crc_init: std_logic:='1'; --
	signal rx_crc_en: std_logic:='0'; --
	signal rx_crc_out: std_logic_vector(7 downto 0); -- Ethernet CRC byte
	signal rx_crc_reg_out: std_logic_vector(31 downto 0); -- Ethernet CRC word

	-- RX data FIFO signals

	signal rx_data_fifo_wr_en: std_logic :='0'; -- must be initialized
	signal rx_data_fifo_rd_en: std_logic:='0';
	signal rx_data_fifo_almost_full: std_logic;
	signal rx_data_fifo_empty: std_logic;
	signal rx_data_fifo_valid: std_logic;
	signal rx_data_fifo_dout: std_logic_vector(8 downto 0);
	signal rx_data_fifo_din: std_logic_vector(8 downto 0) := (others => '0');
	signal rx_data_fifo_wr_count: std_logic_vector(12 downto 0);
	signal rx_data_fifo_dout64: std_logic_vector(63 downto 0);
	signal rx_data_fifo_dout8: std_logic_vector(7 downto 0);
	signal wr_rst: std_logic; -- write domain reset
	signal rd_rst: std_logic;

	-- RX frame FIFO signals

	signal rx_frame_fifo_dout: std_logic_vector(0 downto 0); --
	signal rx_frame_fifo_din: std_logic_vector(0 downto 0) := (others => '0'); --
	signal rx_frame_fifo_rd_en: std_logic := '0';
	signal rx_frame_fifo_wr_en: std_logic := '0';
	signal rx_frame_fifo_valid: std_logic;
	signal rx_frame_fifo_empty: std_logic;
	signal rx_frame_fifo_full: std_logic;
	signal rx_frame_fifo_overflow: std_logic;
	signal rx_frame_fifo_wr_rst_busy: std_logic;

	signal rx_overflow_int: std_logic;

begin


----------------------------------------------------------------------
--  U D P    R E C E I V E R
----------------------------------------------------------------------

rx_overflow <= rx_overflow_int;

-- Reassign names to clarify the code
--rx_clk <= gmii_rxclk;
gmii_rx_en <= gmii_rxctrl_rxdv; -- receive data valid
gmii_rx_d <= gmii_rxd;

-- Compute UDP payload length from UDP packet length
rx_payload_length <= (unsigned(rx_udp_length)-8);

-- Instantiate CRC32 Engine
crc32_0: entity work.udp_mac_crc32
	port map(
--		crc_reg => eth_crc,
		crc     => rx_crc_out,
		crc_reg => rx_crc_reg_out,
		d       => rx_data_dly4,
		calc    => rx_crc_calc,
		init    => rx_crc_init,
		d_valid => rx_crc_en,
		clk     => gmii_rxclk,
		reset   => rst
	);

-- Instantiate Data FIFO
-- This is a First-Word-Fall-Through FIFO
-- This stored the data frame. Bit 8 indicates wether this is the last byte.
-- DATA_FIFO0 : entity work.udp_mac_rx_data_fifo
--	port map (
--		rst         => rst,
--		wr_clk      => rx_clk,
--		rd_clk      => clk,
--		din         => rx_data_fifo_din,
--		wr_en       => rx_data_fifo_wr_en,
--		rd_en       => rx_data_fifo_rd_en,
--		dout        => rx_data_fifo_dout,
--		full        => open,
--		almost_full => rx_data_fifo_almost_full,
--		empty       => rx_data_fifo_empty,
--		valid       => rx_data_fifo_valid
--		);

-- Independent clock Builtin FWFT FIFO, 9-bit input data width, 9-bit output data width, with output register, latency=0
-- This FIFO stores the data frame. Bit 8 indicates wether this is the last byte of the frame (TLAST).

rx_data_fifo_dout <= rx_data_fifo_dout8(0) & rx_data_fifo_dout64(7 downto 0);
rx_data_fifo_valid <= not rx_data_fifo_empty;

-- Generate the resets
-- - FIFO36 has a async reset, reset must be 5 read and write clocks, no rd/wr_en during reset
-- - XPM FIFO: reset sync to wr_clk, wr_rst_busy seems to extend the whole reset cycle, no rd/rw during reset
--
-- Implementation:
-- - Use a XMP macro to generate a 5 clock reet on the write domain. That is the slowest clock, so we have more clocks on the rd domain. This is used to reset the FIFO and XPM FIFO.
-- - We genrate a reset sync to rd domain until 1) the wr domain reset is completed and the XPM reset busy signal goes low.
-- - wr reset resets the wr state machine and olds the wr_en low.
-- - rd reset masks the rd_en.

-- Write domain reset, assumed to be the slowest clock in the system
data_fifo_rst0: xpm_cdc_async_rst
	generic map (
		RST_ACTIVE_HIGH => 1, -- Active high reset
		DEST_SYNC_FF => 6 -- Reset pulse minimum width
	)
	port map (
		src_arst => rst,
		dest_clk => gmii_rxclk,
		dest_arst => wr_rst
	);
-- Read domain reset
data_fifo_rst1: xpm_cdc_async_rst
	generic map (RST_ACTIVE_HIGH => 1) -- Active high reset
	port map (
		src_arst => wr_rst or rx_frame_fifo_wr_rst_busy, -- write domain reset
		dest_clk => clk,
		dest_arst => rd_rst
	);

-- Data FIFO
--
-- The Data FIFO is implemented directly using a FIFI36 primitive so we can leverage the embedded
-- FIFO logic. This can't be done with a XPM macro. The FIFO is 4Kbytes deep, allowing for large
-- ethernet packets but not quite jumbo frames. Command packets should typically be limited to the
-- standard MTU of less than 1K. Large memories are written page by page.
data_fifo0 : FIFO36E1  -- 7-series
	generic map (
		ALMOST_FULL_OFFSET => 13D"16",    -- ALMOST_FULL asserts 16 bytes before FULL
		DATA_WIDTH => 9,                  -- Data width is 9 bits, meaning that depth = 36K/9 = 4K bytes
		DO_REG => 1,                      -- Enable output register (1-0) Must be 1 if EN_SYN = FALSE
		EN_SYN => FALSE,                  -- Asynchronous FIFO
		FIFO_MODE => "FIFO36",            -- "FIFO36" or "FIFO36_72"
		FIRST_WORD_FALL_THROUGH => TRUE,   -- We want FWFT
		SIM_DEVICE => "7SERIES"
	)
	port map (

		-- Write interfce

		wrclk => gmii_rxclk,              -- 1-bit input: Rising edge write clock.
		wren  => rx_data_fifo_wr_en,  -- 1-bit input: Write enable

		di(63 downto 8) => (others => '0'), -- data bus is 64 bit, only 8 LSBs are used
		di(7 downto 0)  => rx_data_fifo_din(7 downto 0),
		dip(7 downto 1) => (others => '0'), -- Parity bus is 8 bits, only LSB is used
		dip(0)          => rx_data_fifo_din(8),

		WRCOUNT => rx_data_fifo_wr_count, -- for debug

		-- Read interface

		rdclk => clk, -- Read clock
		rden  => rx_data_fifo_rd_en, -- Read enable
		regce => '1', -- 1-bit input: Clock enable

		do  => rx_data_fifo_dout64, -- 64-bit data output. Valid data is in 8 LSBs
		dop => rx_data_fifo_dout8, -- 8 bit parity output. Valid data is on LSB
		-- DO(7 downto 0) => rx_data_fifo_dout(7 downto 0), -- Partial assignment causes a synthesis error
		-- DOP(0) => rx_data_fifo_dout(8), -- Partial assignment causes a synthesis error

		-- Status flags

		almostfull => rx_data_fifo_almost_full, -- 1-bit output: Almost full flag
		empty => rx_data_fifo_empty,            -- 1-bit output: Empty flag
		full => open,                           -- 1-bit output: Full flag


		-- ECC Signals (unused)
		injectdbiterr => '0',
		injectsbiterr => '0',

		-- Resets

		rst    => wr_rst, -- Async -- write domain reset reset, must be high at least 5 cycles of the slowest clock
		rstreg => '0'  -- Output register reset
   );



-- Instantiate Frame FIFO, which contains a single bit flag that indicates that a  frame is in the
-- data FIFO, and whether it is valid or not.
--
-- This is an asynchronous First Word Fall Through FIFO.
--
-- The frame validity flag is written in this FIFO once the data is finished to be written in the
-- DATA FIFO. If the flag is '0', the frame will be discarded.
--FRAME_FIFO0 : entity work.udp_mac_rx_frame_fifo
--	port map (
--		rst    => rst,
--		wr_clk => rx_clk,
--		rd_clk => clk,
--		din    => rx_frame_fifo_din,
--		wr_en  => rx_frame_fifo_wr_en,
--		rd_en  => rx_frame_fifo_rd_en,
--		dout   => rx_frame_fifo_dout,
--		full   => rx_frame_fifo_full,
--		empty  => rx_frame_fifo_empty,
--		valid  => rx_frame_fifo_valid
--		);

frame_fifo0: xpm_fifo_async
    generic map (
       FIFO_MEMORY_TYPE => "dist", -- String
       READ_MODE => "fwft",         -- String
       FIFO_READ_LATENCY => 0,     --must be 0 for READ_MODE=fwft
       WRITE_DATA_WIDTH => 1,     -- DECIMAL
       FIFO_WRITE_DEPTH => 64,   --
       READ_DATA_WIDTH => 1,      -- DECIMAL
       FULL_RESET_VALUE => 0,      -- DECIMAL
       SIM_ASSERT_CHK => 1,        -- DECIMAL; 0=disable simulation messages, 1=enable simulation messages
       USE_ADV_FEATURES => "1000", -- Hex string: bit 0: overflow, 1:prog_full, 2:wr_count, 3:almost_full, 8:underflow, 9:prog_empty, 10:rd_count, 11: almost_empty, [12:valid]
       WR_DATA_COUNT_WIDTH => 11    -- Not needed
    )
    port map (

       rst => wr_rst, -- Reset -- write domain reset, synchronous to wr_clk.
       wr_rst_busy => rx_frame_fifo_wr_rst_busy,

       -- Write domain
       wr_clk => gmii_rxclk,         -- Write clock
       din    => rx_frame_fifo_din,   -- Write Data:
       wr_en  => rx_frame_fifo_wr_en, -- Write Enable: Must be held active-low when rst or wr_rst_busy is active high.
       full   => rx_frame_fifo_full,  -- Full Flag:  Write requests are ignored when the FIFO is full.

        -- Read domain
       rd_clk     => clk,          -- Read clock
       rd_en      => rx_frame_fifo_rd_en,            -- 1-bit input: Read Enable: Must be held low when rd_rst_busy is active high.
       dout       => rx_frame_fifo_dout,              -- Read Data
       data_valid => rx_frame_fifo_valid,       -- Read Data Valid: High when data is available on dout.
       empty      => rx_frame_fifo_empty,            -- Empty Flag: High when FIFO is empty. Read requests are ignored.

       injectdbiterr => '0', -- Double Bit Error Injection: Injects a double bit error
       injectsbiterr => '0', -- Single Bit Error Injection: Injects a single bit error
       sleep => '0'         -- Dynamic power saving: If sleep is High, the memory/fifo block is in power saving mode.
    );


---------------------
-- FIFO readout
---------------------
--
-- Connect the receiver output to the output of the DATA FIFO. Enable the TVALID flag only when a full packet has been buffered and was fully validated, which is signaled bythe frame FIFO.

-- Output data is ready if 1) there is a frame flag in the FRAME FIFO, 2) the frame flag says the frame is valid (i.e. is not being flushed out) and 3) the data fifo has valid data.
m_axis_udp_rx_tvalid <= rx_frame_fifo_valid and rx_frame_fifo_dout(0) and rx_data_fifo_valid; -- fifo_valid is 0 during reset, no need to mask
m_axis_udp_rx_tdata <= rx_data_fifo_dout(7 downto 0);
m_axis_udp_rx_tlast <= rx_data_fifo_dout(8);

-- Generate the data & fame FIFO read enable signals
--
-- There are generated combinatorially, but we run this at 125 MHz, so we don't worry about timing here

-- Fetch the next frame flag when 0) we are not in reset, 1) there is a frame bit available; 2) there is a data byte available; 3) we are reading the last byte of a frame; 4) the AXI-S link has absorbed the data or the flag indicates we are flushing the frame
rx_frame_fifo_rd_en <= '1' when rd_rst = '0' and rx_frame_fifo_valid = '1' and  rx_data_fifo_valid = '1' and rx_data_fifo_dout(8) = '1' and (rx_frame_fifo_dout(0) = '0' or m_axis_udp_rx_tready = '1') else '0';
-- Read the data fifo if 0) we ar enot in reset, 1) we have a frame flag and either: the user read the data or the data is to be flushed according to the frame flag
rx_data_fifo_rd_en <= '1' when rd_rst = '0' and rx_frame_fifo_valid = '1' and (rx_frame_fifo_dout(0) = '0' or m_axis_udp_rx_tready = '1') else '0';


---------------------
-- Frame decoding and FIFO storage
---------------------

-- Async RAM readout. RAM output is valid at the same time as the substate (which is the header byte number)

--rx_ram_dout <= RX_RAM(to_integer(RX_STATE_CTR(5 downto 0))); -- Clock RAM output. Is aligned with data
--rx_ram_match <= '1' when rx_ram_dout =rx_data;

-- Combine the last 5 bytes and the curent byte to generate a 48-bit number (enough to fit a MAC address)
rx_data_wide <= (rx_data_dly4 & rx_data_dly3 & rx_data_dly2 & rx_data_dly1 & rx_data_dly & rx_data);

rx_back_end: process(all)
	variable is_broadcast_var: std_logic;
begin
	if rising_edge(gmii_rxclk) then

		-- Frame detect : monitors the GMII interface, and set rx_start_of_frame and the SOF byte is detected and rx_frame for any subsequent byres. Both are cleared whenever gmii_rx_en =0, signifying the end of frame.
		if not gmii_rx_en then -- no data received, clear frame flag
			rx_frame <= '0';
			rx_start_of_frame <= '0';
			rx_data <= X"00"; -- not needed, just to facilitate simulation
	elsif gmii_rx_en = '1' and gmii_rx_d = X"D5" then -- Found first SOF, set PRE_FRAME so that FRAME will be set for the next byte
			rx_start_of_frame <= '1';
			rx_data <= gmii_rx_d; -- not needed, just to facilitate simulation
		else -- valid data coming, set FRAME and clock data byte
			rx_frame <= rx_start_of_frame;
			rx_data <= gmii_rx_d;
		end if;


		-- Data delay line
		rx_data_dly <= rx_data;
		rx_data_dly1 <= rx_data_dly;
		rx_data_dly2 <= rx_data_dly1;
		rx_data_dly3 <= rx_data_dly2;
		rx_data_dly4 <= rx_data_dly3;

		-- CRC engine control
		--
		-- We set the CRC init/calc/en bits to alow the CRC module to compute its CRC on the specified part of the incoming frame.
		if rx_state = RX_STATE_STDBY then -- initialize CRC while waiting for first data
			rx_crc_init <= '1';
			rx_crc_calc <= '0';
			rx_crc_en <= '1';
		elsif rx_state = rx_state_mac_dest_addr and rx_state_ctr = 4 then -- when 4th byte arrives, data begins to enter the CRC engine after the delay line. Start coomputing the CRC
			rx_crc_init <= '0';
			rx_crc_calc <= '1';
			rx_crc_en <= '1';
		elsif rx_frame = '0' then -- The frame has ended. Stop CRC calculation, The 4 bytes in the delay line are the CRC and we don't want to calculate the CRC on them.
			rx_crc_init <= '0';
			rx_crc_calc <= '0';
			rx_crc_en <= '1';
		end if;



		rx_data_fifo_wr_en <= '0'; -- This is active for one clock cycle. Overriden below.
		rx_frame_fifo_wr_en <= '0'; -- This is active for one clock cycle. Overriden below.

		case rx_state is

			-- STANDBY State
			when RX_STATE_STDBY =>
--					rx_store_frame <= '0'; -- write frame data in the FRAME FIFO.
				if rx_start_of_frame  then
					if rx_frame_fifo_full = '1'  or unsigned(local_ip_port) = 0 then -- skip the frame if the frame FIFO is full since we won't have room to store it anyway, or if we haven't defined a valid port yet.
						rx_state <= RX_STATE_SKIP;
					else
						--mac_addr_match <= '0';
						--ip_addr_match <= '0';
						rx_state <= RX_STATE_MAC_DEST_ADDR;
						rx_state_ctr <= (others => '0');
					end if;
				end if;

			-- Check Destination MAC Address
			when RX_STATE_MAC_DEST_ADDR => -- At this point, rx_data contains the first MAC Destination word, state_ctr = 0
				if rx_frame = '0' then
					rx_state <= RX_STATE_STDBY; -- fall back to standby state if frame is interrupted during the header
				elsif rx_state_ctr = 6-1 then
					if rx_data_wide = X"FFFFFFFFFFFF" then
						is_broadcast_var := '1';
					else
						is_broadcast_var := '0';
					end if;
					if (rx_data_wide = local_mac_addr or is_broadcast_var='1') then -- if this packet is destined to us (by exact address or by broadcast)
						--mac_addr_match <= '1';
						--mac_addr_broadcast <= is_broadcast_var;
						rx_state_ctr <= (others => '0');
						rx_state <= RX_STATE_MAC_SRC_ADDR;
					else
						rx_state <= RX_STATE_SKIP;
					end if;
				else
					rx_state_ctr <= rx_state_ctr + 1;
				end if;

			-- Source MAC address
			when RX_STATE_MAC_SRC_ADDR =>
				if rx_frame = '0' then
					rx_state <= RX_STATE_STDBY; -- fall back to standby state if frame is interrupted during the header
				elsif rx_state_ctr = 6-1 then
--					if RX_FIRST_SRC='1' then
					latest_remote_mac_addr_temp <= rx_data_wide; -- Store MAC address of first received packet
--					end if;
					rx_state <= RX_STATE_ETHERTYPE;
					rx_state_ctr <= (others => '0');
				else
					rx_state_ctr <= rx_state_ctr + 1;
				end if;

			-- Ethertype
			when RX_STATE_ETHERTYPE =>
				if rx_frame = '0' then
					rx_state <= RX_STATE_STDBY; -- fall back to standby state if frame is interrupted during the header
				elsif rx_state_ctr = 2-1 then
					if rx_data_wide(15 downto 0) = X"0800" then -- if IP packet
						rx_state_ctr <= (others => '0');
						rx_state <= RX_STATE_IP_TYPE;
					elsif rx_data_wide(15 downto 0) = X"0806" then -- if ARP packet
						arp_request <= '0';
						rx_state_ctr <= (others => '0');
						rx_state <= RX_STATE_ARP_TYPE;
					else -- otherwise not a known type, skip ethernet frame
						rx_state <= RX_STATE_SKIP;
					end if;
				else
					rx_state_ctr <= rx_state_ctr + 1;
				end if;

			when RX_STATE_IP_TYPE =>
				if rx_frame = '0' then
					rx_state <= RX_STATE_STDBY; -- fall back to standby state if frame is interrupted during the header
				elsif rx_data/=X"45" then
					rx_state <= RX_STATE_SKIP;
				else
					rx_state <= RX_STATE_IP_HEADER;
					rx_state_ctr <= (others => '0');
				end if;

			when RX_STATE_IP_HEADER =>
				if rx_frame = '0' then
					rx_state <= RX_STATE_STDBY; -- fall back to standby state if frame is interrupted during the header
				elsif rx_state_ctr = 8-1 then
					rx_state <= RX_STATE_IP_PROTOCOL;
					rx_state_ctr <= (others => '0');
				else
					rx_state_ctr <= rx_state_ctr + 1;
				end if;

			when RX_STATE_IP_PROTOCOL =>
				if rx_frame = '0' then
					rx_state <= RX_STATE_STDBY; -- fall back to standby state if frame is interrupted during the header
				elsif rx_data /= X"11" then
					rx_state <= RX_STATE_SKIP;
				else
					rx_state <= RX_STATE_IP_CHECKSUM;
					rx_state_ctr <= (others => '0');
				end if;

			when RX_STATE_IP_CHECKSUM =>
				if rx_frame = '0' then
					rx_state <= RX_STATE_STDBY; -- fall back to standby state if frame is interrupted during the header
				elsif rx_state_ctr = 2-1 then
					rx_state <= RX_STATE_IP_SRC_ADDR;
					rx_state_ctr <= (others => '0');
				else
					rx_state_ctr <= rx_state_ctr + 1;
				end if;

			when RX_STATE_IP_SRC_ADDR =>
				if rx_frame = '0' then
					rx_state <= RX_STATE_STDBY; -- fall back to standby state if frame is interrupted during the header
				elsif rx_state_ctr = 4-1 then
					latest_remote_ip_addr_temp <= rx_data_wide(31 downto 0); -- Store source IP address of first received packet
					rx_state <= RX_STATE_IP_DEST_ADDR;
					rx_state_ctr <= (others => '0');
				else
					rx_state_ctr <= rx_state_ctr + 1;
				end if;

			when RX_STATE_IP_DEST_ADDR =>
				if rx_frame = '0' then
					rx_state <= RX_STATE_STDBY; -- fall back to standby state if frame is interrupted during the header
				elsif rx_state_ctr = 4-1 then
					if rx_data_wide(31 downto 0) = X"FFFFFFFF" then
						is_broadcast_var := '1';
					else
						is_broadcast_var := '0';
					end if;
					if (rx_data_wide(31 downto 0) = local_IP_ADDR) or (is_broadcast_var='1') then
						--ip_addr_match <= '1';
						ip_addr_broadcast <= is_broadcast_var;
						rx_state <= RX_STATE_IP_SRC_PORT;
						rx_state_ctr <= (others => '0');
					else
						rx_state <= RX_STATE_SKIP;
					end if;
				else
					rx_state_ctr <= rx_state_ctr + 1;
				end if;

			when RX_STATE_IP_SRC_PORT =>
				if rx_frame = '0' then
					rx_state <= RX_STATE_STDBY; -- fall back to standby state if frame is interrupted during the header
				elsif rx_state_ctr = 2-1 then
					latest_remote_ip_port_temp <= rx_data_wide(15 downto 0); -- Store the IP port number
					rx_state <= RX_STATE_IP_DEST_PORT;
					rx_state_ctr <= (others => '0');
				else
					rx_state_ctr <= rx_state_ctr + 1;
				end if;

			when RX_STATE_IP_DEST_PORT =>
				if rx_frame = '0' then
					rx_state <= RX_STATE_STDBY; -- fall back to standby state if frame is interrupted during the header
				elsif rx_state_ctr = 2-1 then
					if (ip_addr_broadcast='0' and rx_data_wide(15 downto 0) = local_ip_port) or (ip_addr_broadcast='1' and rx_data_wide(15 downto 0) = (std_logic_vector(to_unsigned(BROADCAST_IP_PORT/4,14)) & local_subarray)) then
						-- if mac_addr_match='1' and ip_addr_match='1' then
						if ip_addr_broadcast='0' or (ip_addr_broadcast='1' and local_subarray(0)='1') then
							latest_remote_mac_addr <= latest_remote_mac_addr_temp; -- Store MAC address of received packet to be used by the transmitter as a reply address
							latest_remote_ip_addr <= latest_remote_ip_addr_temp; -- Store source IP address
							latest_remote_ip_port <= latest_remote_ip_port_temp; -- Store the IP port number
						end if;
						rx_state <= RX_STATE_UDP_LENGTH;
						rx_state_ctr <= (others => '0');
					else
						rx_state <= RX_STATE_SKIP;
					end if;
				else
					rx_state_ctr <= rx_state_ctr + 1;
				end if;

			when RX_STATE_UDP_LENGTH => -- Store UDP length
				if rx_frame = '0' then -- if frame is interrupted
					rx_state <= RX_STATE_STDBY; -- fall back to standby state
				elsif rx_state_ctr = 2-1 then
					rx_udp_length <= rx_data_wide(rx_udp_length'Range);
					rx_state <= RX_STATE_UDP_CHECKSUM;
					rx_state_ctr <= (others => '0');
				else
					rx_state_ctr <= rx_state_ctr + 1;
				end if;

			when RX_STATE_UDP_CHECKSUM => -- Store UDP length
				if rx_frame = '0' then -- frame is interrupted
					rx_state <= RX_STATE_STDBY; -- fall back to standby
				elsif rx_state_ctr = 2-1 then
					if(rx_payload_length = 0) then
						rx_state <= RX_STATE_SKIP_CRC;
					else
						rx_state <= RX_STATE_PAYLOAD;
						rx_payload_ctr <= rx_payload_length; -- Number of data bytes to read (rx_payload_length = RX_UDP_LENGTH-8)
					end if;
				else
					rx_state_ctr <= rx_state_ctr + 1;
				end if;

			when RX_STATE_PAYLOAD =>

				if rx_frame = '0' or rx_data_fifo_almost_full='1' then -- Packet is interrupted or data FIFO is almost full
					-- Register that an overflow has occured
					rx_overflow_int <= rx_overflow_int or rx_data_fifo_almost_full;
					-- Write a dummy data byte with the LAST flag (there are a few bytes of space left in the FIFO to write it because we used the almost_full flag)
					rx_data_fifo_din(8) <= '1';
					rx_data_fifo_wr_en <= '1';
					-- Store a flag in the frame FIFO to indicate that an invalid data frame is present and should be flushed
					rx_frame_fifo_din(0) <= '0'; -- Frame is invalid and should be flushed
					rx_frame_fifo_wr_en <= '1'; -- write frame data in the FRAME FIFO .
					rx_state <= RX_STATE_STDBY; -- fall back to standby state
				else
					rx_data_fifo_wr_en <= '1'; -- write bytes into FIFO
					rx_data_fifo_din(7 downto 0) <= rx_data; -- write bytes into FIFO
					rx_data_fifo_din(8) <='0'; -- by default this is not the last byte
					if(rx_payload_ctr = 1) then -- if last byte, proceed to flush rest of frame (to discard padding) and compute crc
						rx_data_fifo_din(8) <='1'; -- indicate this is the last byte
						-- we do not write the FRAME flag yet. We will first check the CRC to flag the frame appropriately.
						rx_state <= RX_STATE_SKIP_CRC;
					else
						rx_payload_ctr <= rx_payload_ctr - 1;
					end if;
				end if;

			when RX_STATE_SKIP_CRC => -- skip remaining bytes of frame (which includes padding and the CRC). CRC is still being computed on the delayed data stream
				if(rx_frame = '0') then
					rx_state <= RX_STATE_CHECK_CRC;
					rx_state_ctr <= (others => '0');
				end if;

			when RX_STATE_CHECK_CRC => -- The data frame has ended, but the CRC engine now outputs the 4 CRC bytes
				if rx_data_dly4 /= rx_crc_out then
					rx_frame_fifo_din(0) <= '0'; -- Bad CRC. Frame is invalid and should be flushed
					rx_frame_fifo_wr_en <= '1'; -- write frame data in the FRAME FIFO .
					rx_state <= RX_STATE_STDBY; -- go back to standby
				elsif rx_frame = '1' then -- a new frame began while we were processing the CRC (which violates the minimum interframe delay)
					rx_frame_fifo_din(0) <= '0'; --  Frame is invalid and should be flushed
					rx_frame_fifo_wr_en <= '1'; -- write frame data in the FRAME FIFO .
					rx_state <= RX_STATE_SKIP; -- go back to standby
				elsif rx_state_ctr = 4 - 1 then
					rx_frame_fifo_din(0) <= '1'; -- Everything checked out - rame is valid
					rx_frame_fifo_wr_en <= '1'; -- write frame data in the FRAME FIFO .
					rx_state <= RX_STATE_STDBY;
				else
					rx_state_ctr <= rx_state_ctr + 1;
				end if;

			when  RX_STATE_SKIP=> -- skip remaining bytes of frame
				if rx_frame = '0' then
					rx_state <= RX_STATE_STDBY;
					rx_state_ctr <= (others => '0');
				end if;

			------- ARP STATES ---------

			when RX_STATE_ARP_TYPE =>
				if rx_frame = '0' then
					rx_state <= RX_STATE_STDBY; -- fall back to standby state if frame is interrupted during the header
				elsif rx_state_ctr = 6-1 then
					if rx_data_wide = X"000108000604" then -- if htype = Ethernet, proto = IP, hsize = 6 and pize = 4
						rx_state_ctr <= (others => '0');
						rx_state <= RX_STATE_ARP_OPCODE;
					else -- otherwise not a known type, skip ethernet frame
						rx_state <= RX_STATE_SKIP;
					end if;
				else
					rx_state_ctr <= rx_state_ctr + 1;
				end if;

			when RX_STATE_ARP_OPCODE =>
				if rx_frame = '0' then
					rx_state <= RX_STATE_STDBY; -- fall back to standby state if frame is interrupted during the header
				elsif rx_state_ctr = 2-1 then
					if rx_data_wide(15 downto 0)=X"0001" then -- if opcode = request
						rx_state_ctr <= (others => '0');
						rx_state <= RX_STATE_ARP_SENDER_MAC;
					else -- otherwise not a known type, skip ethernet frame
						rx_state <= RX_STATE_SKIP;
					end if;
				else
					rx_state_ctr <= rx_state_ctr + 1;
				end if;

			when RX_STATE_ARP_SENDER_MAC =>
				if rx_frame = '0' then
					rx_state <= RX_STATE_STDBY; -- fall back to standby state if frame is interrupted during the header
				elsif rx_state_ctr = 6-1 then
					arp_remote_mac_addr <= rx_data_wide; -- Store MAC address of sender to be used to reply
					rx_state <= RX_STATE_ARP_SENDER_IP;
					rx_state_ctr <= (others => '0');
				else
					rx_state_ctr <= rx_state_ctr + 1;
				end if;

			when RX_STATE_ARP_SENDER_IP =>
				if rx_frame = '0' then
					rx_state <= RX_STATE_STDBY; -- fall back to standby state if frame is interrupted during the header
				elsif rx_state_ctr = 4-1 then
					arp_remote_ip_addr <= rx_data_wide(31 downto 0); -- Store source IP address of sender to be used to reply
					--rx_first_src <= '0';
					rx_state <= RX_STATE_ARP_TARGET_MAC;
					rx_state_ctr <= (others => '0');
				else
					rx_state_ctr <= rx_state_ctr + 1;
				end if;

			when RX_STATE_ARP_TARGET_MAC =>
				if rx_frame = '0' then
					rx_state <= RX_STATE_STDBY; -- fall back to standby state if frame is interrupted during the header
				elsif rx_state_ctr = 6-1 then
					rx_state <= RX_STATE_ARP_TARGET_IP;
					rx_state_ctr <= (others => '0');
				else
					rx_state_ctr <= rx_state_ctr + 1;
				end if;

			when RX_STATE_ARP_TARGET_IP =>
				if not rx_frame then
					rx_state <= RX_STATE_STDBY; -- fall back to standby state if frame is interrupted during the header
				elsif rx_state_ctr = 4-1 then
					if rx_data_wide(31 downto 0)=local_IP_ADDR then
						arp_request <= '1';
					end if;
					rx_state <= RX_STATE_SKIP;
				else
					rx_state_ctr <= rx_state_ctr + 1;
				end if;
		end case;

		-- sync reset
		if wr_rst  then
			arp_request <= '0';
			rx_overflow_int <= '0';
			rx_data_fifo_wr_en <= '0';
			rx_frame_fifo_wr_en <= '0';
			rx_state <= RX_STATE_STDBY;
		end if;

	end if; -- gmii_rxclk
end process; -- rx_back_end




end impl;



