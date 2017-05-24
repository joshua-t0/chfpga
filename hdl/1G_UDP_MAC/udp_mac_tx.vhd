----------------------------------------------------------------------------------
-- Company: McGill Univ.
-- Engineer: JF Cliche
--
-- Create Date:    13:54:40 11/19/2010
-- Design Name:
-- Module Name:    UDP_MAC_TX
-- Project Name:
-- Target Devices:
-- Tool versions:
-- Description: Implements a simplified Gigabit Ethernet UDP/IP/Ethernet Transmitter Packetizer and MAC with a GMII output interface.
--   See UDP_MAC for a description.
--
-- Dependencies:
--
-- Revision:
-- 	101121 JFC - File Created
--    101121 JFC - Interframe delay counter implemented
--    110103 JFC - Implemented automatic IP header checksum computation
--               - Implemented auto IP and UDP length computation
--               - restructure CRC and IP_CHECKSUM signalling. CALC & INIT lines now controlled by ACTION state, which is now set when data is assigned in the main state machine.
--               - general cleanup
--    110105 JFC - Implemented frame FIFO, front-end logic. Now supports FRAME going down on the last byte (while s_axis_udp_tx_tvalid=1) of after the last byte (when s_axis_udp_tx_tvalid=0)
--                 Modified/simplified all of the tx state machine. IDLE1 and IDLE2 states were removed.
--                 IP pre-computation moved during Preamble transmission.
--                 Interframe state added after CRC transmission, and jumps right into preamble if FRAME FIFO not empty to allow for full-speed transmission.
--                 VHDL version of the CRC32 implemented.
--    110108 JFC - Tested UDP with PHY. Debugegd the PHY interface with IODELAYS to improve timing.
--    110112 JFC - Added zero padding to make sure that the ethernet frame length (including checksum) is always >=64 bytes.
--    110317 JFC - RX and TX splitted in two files. This file was created.
--    110430 JFC - Added MAC and IP address/PORT parameters. Changed code to use these instead of the RAM values. Had to rewrite the way the IP checksum is pre-computed to make sure this takes into account the changing destination IP address.
--    110501 JFC - Added port selection. Used bit 16 in the FRAME FIFO word to select the port (remote_ip_base_port or remote_ip_base_port+1). The bit is read with the last byte of the frame (works for both framing approaches)
--		110501 JFC - Major rewrite of the transmitter. Eliminated header RAM and associated logic. Header values are loaded in a 6-byte register (TX_SREG) in the state machine for transmission. Removed TX_REG and associated logic.
--		120709 JFC - Added separate address for ARP replies
--		120922 JFC - Implemented 2-bit port offset
-- Additional Comments:
-- TODO:
--    110102 JFC:  Update code to make sure the transmitter works on an independenr TX clock. We might need to add a data clock.
--    110112 JFC:  Make sure RESET also resets the frame length counters
--
-- Possible features:
--    110105 JFC: allow Dest MAC,IP&port to be specified. A config vector could tell which of those are passed. These could be stored in the DATA FIFO . Dst MAC would be ready on time, but we need the Dst IP for header checksum pre-comp...

----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--library work;
--use work.CRC32;
--use work.ip_package.all; -- Import definition of components for IP cores used in this module

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

use work.ip_package.all; -- Import definition of components for IP cores used in this module

entity UDP_MAC_TX is

	PORT (
			-- User-side streaming interface
		local_mac_addr: in STD_LOGIC_VECTOR(47 downto 0);
		local_ip_addr: in STD_LOGIC_VECTOR(31 downto 0);

		-- Primary destination (tx_port_offset = 0)
		remote_mac_addr0: in STD_LOGIC_VECTOR(47 downto 0);
		remote_ip_addr0: in STD_LOGIC_VECTOR(31 downto 0);
		remote_ip_port0: in STD_LOGIC_VECTOR(15 downto 0);

		-- Secondary destination (tx_port_offset = 1)
		remote_mac_addr1: in STD_LOGIC_VECTOR(47 downto 0);
		remote_ip_addr1: in STD_LOGIC_VECTOR(31 downto 0);
		remote_ip_port1: in STD_LOGIC_VECTOR(15 downto 0);

		arp_request : in STD_LOGIC;
		arp_remote_mac_addr: in STD_LOGIC_VECTOR(47 downto 0);
		arp_remote_ip_addr: in STD_LOGIC_VECTOR(31 downto 0);

		-- User-side streaming interface

		s_axis_udp_tx_tvalid : in std_logic;
		s_axis_udp_tx_tdata : in  std_logic_vector (7 downto 0); -- will be axis_udp_tx_tdata
		s_axis_udp_tx_tlast : in std_logic;
		s_axis_udp_tx_tready: out std_logic;

		tx_port_offset: in std_logic_vector(1 downto 0):="00"; -- will be axis_udp_tx_tuser
		tx_clk : in  std_logic; -- data bus clock

		tx_overflow: out std_logic;
		rst : in std_logic;

		-- GMII Interface

--		GMII_RESET_L: out STD_LOGIC; -- GMII interface reset (logic low)

		gmii_txclk : in  std_logic; --  transmit clock
		gmii_txer: out std_logic; -- Transmit error flag
--		gmii_txclk: in std_logic; --  10-100BASE_T Transmit clock supplied by the PHY. We do not use it.
		gmii_txc_gtxclk: out std_logic; -- Transmit clock we generate for the PHY
		gmii_txen: out std_logic;  -- Transmit word enable
		gmii_txd: out  std_logic_vector(7 downto 0) -- Transmit word
		);


end UDP_MAC_TX;

architecture Behavioral of UDP_MAC_TX is







-- Signals



signal LINK_SPEED: STD_LOGIC_VECTOR(1 downto 0) := "10"; -- Freeze link speed to 1000BASE-T. We do not support lower speeds in this simple MAC.

-- TX state machine
TYPE TX_STATE_TYPE IS (TX_STATE_STDBY,TX_STATE_TX_PREAMBLE,TX_STATE_TX_HEADER,TX_STATE_TX_ARP,TX_STATE_TX_PAYLOAD,TX_STATE_TX_PADDING, TX_STATE_TX_ETH_CHECKSUM,TX_STATE_INTERFRAME); -- States of the TX state machine
signal TX_STATE: TX_STATE_TYPE:=TX_STATE_STDBY; -- Initialization needed

-- TX Source selection. Determines from where the data will be taken on the next clock to be sent on the GMII TX port.
TYPE TX_SRC_SEL_TYPE IS (TX_SRC_SEL_IDLE,TX_SRC_SEL_PREAMBLE, TX_SRC_SEL_SREG, TX_SRC_SEL_FIFO);
signal TX_SRC_SEL: TX_SRC_SEL_TYPE;
signal TX_REG: STD_LOGIC_VECTOR(7 downto 0); -- Temporary storage for the outgoing TX byte to delay its transmission by one clock and align it with the FIFO latency


signal TX_PAYLOAD_LENGTH: UNSIGNED(15 downto 0):= (others=>'0'); -- Amount of data to transfer in UDP packet
signal UDP_LENGTH: STD_LOGIC_VECTOR(15 downto 0); -- UDP packet length (including header), to be insterted in UDP Length field
signal IP_LENGTH: STD_LOGIC_VECTOR(15 downto 0); -- IP packet length (including header), to be insterted in IP Length field


signal TX_CTR: UNSIGNED(15 downto 0) := (others=>'0'); -- General purpose counter. Indexes the header RAM.
--signal HEADER_BYTE: STD_LOGIC_VECTOR(7 downto 0); -- General purpose counter. Indexes the header RAM.
signal GMII_TXD_OUT,GMII_TXD_OUT2: STD_LOGIC_VECTOR(7 downto 0); --
signal GMII_TXEN_OUT: STD_LOGIC:='0'; --


TYPE CRC_ACTION_TYPE IS (CRC_ACTION_INIT,CRC_ACTION_CALC, CRC_ACTION_INSERT);
signal CRC_ACTION: CRC_ACTION_TYPE:=CRC_ACTION_INIT; -- Initialization is needed

signal ETH_CRC: STD_LOGIC_VECTOR(31 downto 0):=X"12345678"; -- Ethernet frame CRC32
signal CRC_CALC: STD_LOGIC:='0'; --
signal CRC_INIT: STD_LOGIC:='0'; --
signal CRC_EN: STD_LOGIC:='0'; --
signal CRC_OUT: STD_LOGIC_VECTOR(7 downto 0); -- Ethernet CRC byte
signal CRC_INSERT: STD_LOGIC:='0'; --


TYPE IP_CHECKSUM_ACTION_TYPE IS (IP_CHECKSUM_ACTION_INIT,IP_CHECKSUM_ACTION_CALC,IP_CHECKSUM_ACTION_HOLD, IP_CHECKSUM_ACTION_INSERT);
signal IP_CHECKSUM_ACTION: IP_CHECKSUM_ACTION_TYPE:=IP_CHECKSUM_ACTION_INIT; -- Initialization is needed

signal IP_CHECKSUM_REG: UNSIGNED(20 downto 0); -- IP header Checksum computation register.
signal IP_CHECKSUM_OUT16: UNSIGNED(15 downto 0);
signal IP_CHECKSUM_IN,IP_CHECKSUM_OUT,IP_CHECKSUM_MSB: STD_LOGIC_VECTOR(7 downto 0);
signal IP_CHECKSUM_IS_MSB : STD_LOGIC:='1';
signal IP_CHECKSUM_CALC: STD_LOGIC:='0'; --
signal IP_CHECKSUM_INIT: STD_LOGIC:='1'; --
signal IP_CHECKSUM_INSERT: STD_LOGIC:='0'; --

signal tx_fifo_dout: std_logic_vector(7 downto 0); -- TX FIFO output data
signal tx_fifo_rd_en: std_logic:='0'; -- TX FIFO Read enable
signal tx_fifo_wr_en: std_logic:='0'; -- TX FIFO Write enable
signal tx_fifo_empty: std_logic; -- TX FIFO empty flag (on the read side)
signal tx_fifo_full: std_logic; -- TX FIFO full flag

signal s_axis_udp_tx_tready_int: std_logic;

signal TX_FRAME_FIFO_DIN,TX_FRAME_FIFO_DOUT: STD_LOGIC_VECTOR(17 downto 0); --
signal TX_FRAME_LENGTH: UNSIGNED(15 downto 0) :=(0=>'1', others=>'0'); -- needed in case there is no reset
signal TX_FRAME_LENGTH_PLUS_ONE: UNSIGNED(15 downto 0);

signal TX_FRAME_FIFO_WR_EN: STD_LOGIC :='0';
signal TX_FRAME_FIFO_RD_EN: STD_LOGIC :='0';
signal TX_FRAME_PREVIOUS: STD_LOGIC :='0';
signal TX_FRAME_FIFO_EMPTY: STD_LOGIC;
signal TX_FRAME_FIFO_FULL: STD_LOGIC;

signal TX_PORT_PREVIOUS: STD_LOGIC_VECTOR(1 downto 0):="00";
--signal TX_PORT_FLAG: STD_LOGIC:='0';
signal remote_mac_addr_sel:  STD_LOGIC_VECTOR(47 downto 0);
signal remote_ip_base_addr_sel:  STD_LOGIC_VECTOR(31 downto 0);
signal remote_ip_base_port_sel:  STD_LOGIC_VECTOR(15 downto 0);

signal TX_SREG: STD_LOGIC_VECTOR(47 downto 0):=(others=>'0'); -- 6 bytes

signal SEND_ARP: std_logic:='1';
--signal ARP_TYPE: std_logic:='0';
signal ARP_CTR1,ARP_CTR2: unsigned(13 downto 0):=(others=>'0');
signal arp_request_PREVIOUS: std_logic:='0';

begin

-- Basic combinatorial assignments
GMII_TXER<='0'; -- No transmit errors
--GMII_RESET_L<=not RST;
GMII_TXC_GTXCLK<=GMII_TXCLK;

UDP_LENGTH<=STD_LOGIC_VECTOR(TX_PAYLOAD_LENGTH+8);
IP_LENGTH<=STD_LOGIC_VECTOR(TX_PAYLOAD_LENGTH+28);

GMII_TXD_OUT2<=IP_CHECKSUM_OUT WHEN IP_CHECKSUM_INSERT='1' else GMII_TXD_OUT;


data_fifo0 : udp_mac_tx_data_fifo
		port map (
			rst    => rst,
			wr_clk => tx_clk,
			rd_clk => gmii_txclk,
			din    => s_axis_udp_tx_tdata,
			wr_en  => tx_fifo_wr_en,
			rd_en  => tx_fifo_rd_en,
			dout   => tx_fifo_dout,
			full   => tx_fifo_full,
			empty  => tx_fifo_empty
			);

frame_fifo0 : UDP_MAC_TX_FRAME_FIFO
		port map (
			rst    => rst,
			wr_clk => tx_clk,
			rd_clk => gmii_txclk,
			din    => tx_frame_fifo_din,
			wr_en  => tx_frame_fifo_wr_en,
			rd_en  => tx_frame_fifo_rd_en,
			dout   => tx_frame_fifo_dout,
			full   => tx_frame_fifo_full,
			empty  => tx_frame_fifo_empty
			);


-- TX Frame FIFO management
--  Counts incoming bytes and stores the frame length in the frame FIFO once a frame is finished. This allows the TX state machine :
--   1) to know that a full frame is available in the TX data FIFO, therefore ensuring uninterrupted transmission of the data on the GMII interface
--   2) know how many bytes to read from the FIFO

s_axis_udp_tx_tready_int <= (not tx_fifo_full) and (not tx_frame_fifo_full);
s_axis_udp_tx_tready <= s_axis_udp_tx_tready_int;

--TX_FRAME_LENGTH_PLUS_ONE<=TX_FRAME_LENGTH+1;
--TX_FRAME_FIFO_WR_EN<='1' when ((s_axis_udp_tx_tvalid='1' and TX_FRAME='0') or (s_axis_udp_tx_tvalid='0' and TX_FRAME='0' and TX_FRAME_PREVIOUS='1')) else '0';
tx_fifo_wr_en <= '1' when (s_axis_udp_tx_tvalid = '1' and s_axis_udp_tx_tready_int = '1') else '0';
tx_frame_fifo_wr_en <= '1' when (s_axis_udp_tx_tvalid = '1' and s_axis_udp_tx_tready_int = '1' and s_axis_udp_tx_tlast = '1') else '0';
--TX_FRAME_FIFO_DIN(15 downto 0)<=STD_LOGIC_VECTOR(TX_FRAME_LENGTH_PLUS_ONE) when s_axis_udp_tx_tvalid='1' else STD_LOGIC_VECTOR(TX_FRAME_LENGTH);
tx_frame_fifo_din(15 downto 0) <= std_logic_vector(tx_frame_length);
--tx_frame_fifo_din(17 downto 16)<=tx_port_offset when s_axis_udp_tx_tvalid='1' else TX_PORT_PREVIOUS; -- If the END of frame is detected by seeing that s_axis_udp_tx_tvalid is no longer active, we want to use the last valid port number sent with the last data byte while s_axis_udp_tx_tvalid was '1'
tx_frame_fifo_din(17 downto 16) <= tx_port_offset; -- If the END of frame is detected by seeing that s_axis_udp_tx_tvalid is no longer active, we want to use the last valid port number sent with the last data byte while s_axis_udp_tx_tvalid was '1'

tx_front_end : process(tx_clk, RST)
	begin
		if RST='1' then
			tx_frame_length <= to_unsigned(1, tx_frame_length'length);
			tx_overflow <= '0';
		elsif rising_edge(tx_clk) then
			-- Determine if the transmit buffer has overflow. Now we are very conservative and assume there is an overflow if we ever have to throttle the data source.
			-- which in practive should not be a problem
			if s_axis_udp_tx_tready_int='0' then
				tx_overflow <= '1';
			end if;

			if tx_fifo_wr_en ='1' then -- if we are writing a byte in the fifo...
				tx_frame_length <= tx_frame_length + 1; --... increase the byte counter
				if s_axis_udp_tx_tlast ='1' then -- but if this is the last byte of the packet
					tx_frame_length <= to_unsigned(1, tx_frame_length'length); -- ... reset the counter to 1
				end if;
			end if;
		end if; -- CLK
	end process;



tx_back_end : process(GMII_TXCLK, RST)
	begin
		if RST='1' then
			arp_request_PREVIOUS<='0';
			SEND_ARP<='0';
			--SEND_GRATUITOUS_ARP<='1';
			--TX_SRC_SEL<=TX_SRC_SEL_IDLE;
			--TX_STATE<=TX_STATE_STDBY;

		elsif rising_edge(GMII_TXCLK) then

		-- RAM process
--		RAM_DOUT<=RAM(to_integer(TX_CTR(5 downto 0))); --

		-- Output registering with CRC or CHECKSUM insertion

		if CRC_INSERT='1' THEN
			GMII_TXD<=CRC_OUT;
		else
			GMII_TXD<=GMII_TXD_OUT2;
		end if;

		GMII_TXEN<=GMII_TXEN_OUT;

		-- generate ARP timer to send ARP packets periodically
--		ARP_CTR1<=ARP_CTR1+1;
--		if ARP_CTR1=0 then
--			ARP_CTR2<=ARP_CTR2+1;
--			if ARP_CTR2=0 then
--				SEND_ARP<='1';
--			end if;
--		end if;
		arp_request_PREVIOUS<=arp_request;
		if(arp_request_PREVIOUS='0' and arp_request='1') then
			SEND_ARP<='1';
		end if;


		-- Data source selector
		CASE TX_SRC_SEL IS
			WHEN TX_SRC_SEL_IDLE =>
				GMII_TXEN_OUT<='0';
				GMII_TXD_OUT<=X"55";
				IP_CHECKSUM_IN<=TX_SREG(47 downto 40); -- Not useful

			WHEN TX_SRC_SEL_PREAMBLE =>
				GMII_TXEN_OUT<='1';
				GMII_TXD_OUT<=TX_REG;
				IP_CHECKSUM_IN<=TX_SREG(47 downto 40);

			WHEN TX_SRC_SEL_SREG =>
				GMII_TXEN_OUT<='1';
				GMII_TXD_OUT<=TX_SREG(47 downto 40);
				IP_CHECKSUM_IN<=TX_SREG(47 downto 40);

			WHEN TX_SRC_SEL_FIFO =>
				GMII_TXEN_OUT<='1';
				GMII_TXD_OUT<=TX_FIFO_DOUT;
				IP_CHECKSUM_IN<=TX_FIFO_DOUT;

			END CASE;


		-- Sets the CRC computation/insertion control lines based on the CRC tag that was set with the data
		CASE CRC_ACTION IS
			WHEN CRC_ACTION_INIT =>
				CRC_EN<='0';
				CRC_INIT<='1';
				CRC_CALC<='0';
				CRC_INSERT<='0';

			WHEN CRC_ACTION_CALC=>
				CRC_EN<='1';
				CRC_INIT<='0';
				CRC_CALC<='1';
				CRC_INSERT<='0';

			WHEN CRC_ACTION_INSERT =>
				CRC_EN<='1';
				CRC_INIT<='0';
				CRC_CALC<='0';
				CRC_INSERT<='1';
			END CASE;

		-- Sets the IP checksum computation/insertion control lines based on the IP CHECKSUM ACTION tag that was set with the data
		CASE IP_CHECKSUM_ACTION IS
			WHEN IP_CHECKSUM_ACTION_INIT =>
				IP_CHECKSUM_INIT<='1';
				IP_CHECKSUM_CALC<='0';
				IP_CHECKSUM_INSERT<='0';

			WHEN IP_CHECKSUM_ACTION_CALC=>
				IP_CHECKSUM_INIT<='0';
				IP_CHECKSUM_CALC<='1';
				IP_CHECKSUM_INSERT<='0';

			WHEN IP_CHECKSUM_ACTION_HOLD=>
				IP_CHECKSUM_INIT<='0';
				IP_CHECKSUM_CALC<='0';
				IP_CHECKSUM_INSERT<='0';

			WHEN IP_CHECKSUM_ACTION_INSERT =>
				IP_CHECKSUM_INIT<='0';
				IP_CHECKSUM_CALC<='0';
				IP_CHECKSUM_INSERT<='1';
			END CASE;


			-- Transmit state machine: Sequences the transmission of the Ethernet/IP/UDP frame

			-- The signals used to get the data (RAM address, FIFO_RD_EN) is set as the same time as the state that process this data is set.
			-- The data source is set when clocking out of that state.
			-- The flag indicating the source of the data is set when clocking out. It tags the data.
			--


			CASE TX_STATE IS


				-- STANDBY State
				WHEN TX_STATE_STDBY =>
					TX_SRC_SEL<=TX_SRC_SEL_IDLE;  -- just in case.

					CRC_ACTION<=CRC_ACTION_INIT; -- not really needed - will be initialized later

					if(TX_FRAME_FIFO_EMPTY='0') then -- If frame data is available
						TX_STATE<=TX_STATE_TX_PREAMBLE;
						TX_CTR<=(others=>'0'); -- Initialize the counter. We're going to count 8 bytes
						TX_FRAME_FIFO_RD_EN<='1'; -- Read Frame length from frame FIFO
						IP_CHECKSUM_ACTION<=IP_CHECKSUM_ACTION_INIT; -- needed to prepare for IP header checksum precomputation
					elsif SEND_ARP='1' then
						TX_STATE<=TX_STATE_TX_PREAMBLE;
						TX_CTR<=(others=>'0'); -- Initialize the counter. We're going to count 8 bytes
						IP_CHECKSUM_ACTION<=IP_CHECKSUM_ACTION_INIT; -- needed to prepare for IP header checksum precomputation
					end if;

				WHEN TX_STATE_TX_PREAMBLE => -- Transmits the 8-byte Ethernet preamble (0x55 x7 and 0xD5). While doing that, compute the IP Checksum on the IP addresses


					TX_SREG(47 downto 8)<=TX_SREG(39 downto 0); -- Shift left SREG by one byte. This assignment may be overriden below.
					TX_CTR<=TX_CTR+1; -- This assignment may be overriden below

					CASE TX_CTR(3 downto 0) is
						WHEN X"0"=>
							TX_FRAME_FIFO_RD_EN<='0'; -- Stop reading the FIFO buffer. Length of current frame to transmit is now on the FRAME_FIFO_DOUT. It will be transferred lated into the length register
							TX_SRC_SEL<=TX_SRC_SEL_PREAMBLE; -- Send the data in TX_REG to the GMII, but the SREG data to the IP checksum engine for IP checksum precomputation
							TX_REG<=X"55";
							TX_SREG(47 downto 16)<=local_ip_addr;
							IP_CHECKSUM_ACTION<=IP_CHECKSUM_ACTION_CALC; -- Pre-Compute IP header checksum from the IP addresses
						WHEN X"1"=>
							-- FRAME FIFO word is now on the bus.
							TX_PAYLOAD_LENGTH<=UNSIGNED(TX_FRAME_FIFO_DOUT(15 downto 0)); -- Store Frame length in register -- need it to obtain IP and UDP lengths, and to count bytes during the payload transmission
							-- Now store the destination port based on bit 17:16
							case to_integer(unsigned(TX_FRAME_FIFO_DOUT(17 downto 16))) is
								when 0 =>
									remote_mac_addr_sel     <= remote_mac_addr0;
									remote_ip_base_addr_sel <= remote_ip_addr0;
									remote_ip_base_port_sel <= remote_ip_port0;
								when 1 =>
									remote_mac_addr_sel     <= remote_mac_addr1;
									remote_ip_base_addr_sel <= remote_ip_addr1;
									remote_ip_base_port_sel <= remote_ip_port1;
								when others =>
									remote_mac_addr_sel     <= remote_mac_addr0;
									remote_ip_base_addr_sel <= remote_ip_addr0;
									remote_ip_base_port_sel <= remote_ip_port0;
							end case;
						WHEN X"4"=>
							TX_SREG(47 downto 16)<=remote_ip_base_addr_sel;
						WHEN X"7"=>
							TX_REG<=X"D5";
							CRC_ACTION<=CRC_ACTION_INIT; -- initialize CRC. COmputation will start at the next state.
							TX_CTR<=(others=>'0'); -- Initialize the header byte address for header transmission

							if SEND_ARP='1' then
								TX_STATE<=TX_STATE_TX_ARP;
							else
								TX_STATE<=TX_STATE_TX_HEADER;
							end if;
						WHEN others=>
							-- Do nothing else
					end case;

				-- TX_HEADER state
				WHEN TX_STATE_TX_HEADER =>  -- Transmits the Ethernet/IP/UDP headers. IP Header computation/insertion is enabled when necessary. Computed IP/UDP lengths are inserted when necessary.

						TX_CTR<=TX_CTR+1; -- This assignment is sometimes overriden below
						TX_SREG(47 downto 8)<=TX_SREG(39 downto 0); -- Shift left SREG by one byte. -- This assignment is sometimes overriden below

						CASE TX_CTR(7 downto 0) IS
							WHEN X"00" => --
								CRC_ACTION<=CRC_ACTION_CALC; -- needed to start computing the Ethernet CRC
								IP_CHECKSUM_ACTION<=IP_CHECKSUM_ACTION_HOLD; -- Needed to stop precomputation of the IP checksum on the IP addresses

								TX_SRC_SEL<=TX_SRC_SEL_SREG;
								TX_SREG(47 downto 0)<=remote_mac_addr_sel;
							WHEN X"06" => --
								TX_SRC_SEL<=TX_SRC_SEL_SREG;
								TX_SREG(47 downto 0)<=local_mac_addr;
							WHEN X"0C" => -- Ethertype
								TX_SRC_SEL<=TX_SRC_SEL_SREG;
								TX_SREG(47 downto 32)<=X"0800"; -- Ethertype=0x0800
							WHEN X"0E" => -- First IP header byte
								IP_CHECKSUM_ACTION<=IP_CHECKSUM_ACTION_CALC; -- Resume IP header checksum computation
								TX_SRC_SEL<=TX_SRC_SEL_SREG;
								TX_SREG(47 downto 16)<=(X"4500" & IP_LENGTH); --  Ip version 0x4, IP Hdr Length = 0x5, DSCP/ECP=0x00, IP total Length= IP_LENGTH
							WHEN X"12" => -- First IP header byte
								TX_SRC_SEL<=TX_SRC_SEL_SREG;
								TX_SREG(47 downto 0)<=X"142600007F11"; -- IP Identification =0x1426, Flags/Fragments offset=0x0000, TTL=0x7F, Protocol=0x11 (UDP)
							WHEN X"18" => -- Start inserting IP Checksum
								IP_CHECKSUM_ACTION<=IP_CHECKSUM_ACTION_INSERT; -- Start inserting the IP Checksum. The checksum must include the IP addresses that will follow after this checksum, but we already precomputed them while sending the preamble so the checksum is valid
								TX_SRC_SEL<=TX_SRC_SEL_SREG; -- not useful - data is overriden by IP_CHECKSUM_ACTION_INSERT
							WHEN X"1A" => -- Source IP addresses
								IP_CHECKSUM_ACTION<=IP_CHECKSUM_ACTION_INIT; -- Stop inserting IP Checksum
								TX_SRC_SEL<=TX_SRC_SEL_SREG;
								TX_SREG(47 downto 16)<=local_ip_addr;
							WHEN X"1E" => -- Get Destination IP
								TX_SRC_SEL<=TX_SRC_SEL_SREG;
								TX_SREG(47 downto 16)<=remote_ip_base_addr_sel;
							WHEN X"22" => -- Source port, Destination port, UDP Length
								TX_SRC_SEL<=TX_SRC_SEL_SREG;
								TX_SREG(47 downto 0)<=(X"0000" & remote_ip_base_port_sel & UDP_LENGTH); --
							WHEN X"28" => --  UDP Checksum (disabled)
								TX_SRC_SEL<=TX_SRC_SEL_SREG;
								TX_SREG(47 downto 32)<=X"0000"; -- UDP Checksum will be ignored
							WHEN X"29"=> -- end of header buffer: proceed to data trasmnission
--								TX_SRC_SEL<=TX_SRC_SEL_RAM;
								TX_STATE<=TX_STATE_TX_PAYLOAD;
								TX_FIFO_RD_EN<='1';
								TX_CTR<=(others=>'0');
							WHEN others =>
								-- Do nothing
						end case;

				WHEN TX_STATE_TX_ARP =>  -- Transmits the Ethernet/IP/UDP headers. IP Header computation/insertion is enabled when necessary. Computed IP/UDP lengths are inserted when necessary.
						SEND_ARP<='0';
						TX_CTR<=TX_CTR+1; -- This assignment is sometimes overriden below
						TX_SREG(47 downto 8)<=TX_SREG(39 downto 0); -- Shift left SREG by one byte. -- This assignment is sometimes overriden below

						CASE TX_CTR(7 downto 0) IS
							WHEN X"00" => --
								CRC_ACTION<=CRC_ACTION_CALC; -- needed to start computing the Ethernet CRC
								TX_SRC_SEL<=TX_SRC_SEL_SREG;
								TX_SREG(47 downto 0)<=arp_remote_mac_addr; --
							WHEN X"06" => --
								TX_SREG(47 downto 0)<=local_mac_addr;
							WHEN X"0C" => -- Ethertype et al.
								TX_SRC_SEL<=TX_SRC_SEL_SREG;
								TX_SREG(47 downto 0)<=X"080600010800"; -- Ethertype=0x0806 (ARP), ARP HArdware type: 1 (ethernet), ARP Protocol type 0800=IP

							WHEN X"12" => -- First IP header byte
								TX_SRC_SEL<=TX_SRC_SEL_SREG;
								--if ARP_TYPE='0' then
								TX_SREG(47 downto 16)<=X"06040002" ; -- Hsize=6,  ProtoSize=4, Opcode=reply
								--else
								--	TX_SREG(47 downto 16)<=X"06040001" ; --
								--end if;
								--ARP_TYPE<=not ARP_TYPE;
							WHEN X"16" => -- Sender MAC
								TX_SRC_SEL<=TX_SRC_SEL_SREG;
								TX_SREG(47 downto 0)<=local_mac_addr;
							WHEN X"1C" => -- Sender IP
								TX_SRC_SEL<=TX_SRC_SEL_SREG;
								TX_SREG(47 downto 16)<=local_ip_addr;
							WHEN X"20" => -- target MAC
								TX_SRC_SEL<=TX_SRC_SEL_SREG;
								TX_SREG(47 downto 0)<=arp_remote_mac_addr;
							WHEN X"26" => -- TArget IP
								TX_SRC_SEL<=TX_SRC_SEL_SREG;
								TX_SREG(47 downto 16)<=arp_remote_ip_addr;
							WHEN X"2A" => -- Filing to greate a 60 byte ethernet frame (excluding pramble & checksum)
								TX_SRC_SEL<=TX_SRC_SEL_SREG;
								TX_SREG(47 downto 0)<=X"000000000000"; -- Filling
							WHEN X"3B"=> -- end of frame -- proceed to checksum transmission
								TX_STATE<=TX_STATE_TX_ETH_CHECKSUM;
								TX_CTR<=(others=>'0');
							WHEN others =>
								-- Do nothing
						end case;

				WHEN TX_STATE_TX_PAYLOAD => -- Transmit the UDP payload data frol the TX data FIFO
						TX_SRC_SEL<=TX_SRC_SEL_FIFO;
						CRC_ACTION<=CRC_ACTION_CALC;

						if (TX_CTR=(TX_PAYLOAD_LENGTH-1)) THEN
							TX_FIFO_RD_EN<='0';
							if(TX_CTR>=17) then -- if the minimum payload size was transmitted to ensure a 64 byte overall ethernet frame (including checksum)
								TX_STATE<=TX_STATE_TX_ETH_CHECKSUM;
								TX_CTR<=(others=>'0');
							else -- send padding
								TX_STATE<=TX_STATE_TX_PADDING;
								TX_CTR<=TX_CTR+1;
							end if;
						else
							TX_CTR<=TX_CTR+1;
						end if;
				WHEN TX_STATE_TX_PADDING => -- Transmit Padding up to 18 bytes
						TX_SRC_SEL<=TX_SRC_SEL_SREG;
						TX_SREG(47 downto 40)<=X"00"; -- send zeros for padding
						CRC_ACTION<=CRC_ACTION_CALC; -- redundant

						if (TX_CTR=17) THEN
								TX_STATE<=TX_STATE_TX_ETH_CHECKSUM;
								TX_CTR<=(others=>'0');
						else
								TX_CTR<=TX_CTR+1;

						end if;



				WHEN TX_STATE_TX_ETH_CHECKSUM =>  -- Transmits the Ethernet CRC32 checksum that was computed on the whole ethernet frame
					CRC_ACTION<=CRC_ACTION_INSERT;

					if(TX_CTR=3) then
							TX_STATE<=TX_STATE_INTERFRAME;
							TX_CTR<=(others=>'0');
					else
							TX_CTR<=TX_CTR+1;
					end if;

				WHEN TX_STATE_INTERFRAME => -- Wait for 12 clocks without sending anything to implement the interframe delay.
					CRC_ACTION<=CRC_ACTION_INIT; -- needed to stop the CRC engine to override output words
					TX_SRC_SEL<=TX_SRC_SEL_IDLE; -- don't send anything

					if(TX_CTR=15) then
							if(TX_FRAME_FIFO_EMPTY='1') then -- if there is no new full frame available then jump to standby
								TX_STATE<=TX_STATE_STDBY;
								TX_CTR<=(others=>'0');
							else -- else start transmission of a new frame immediately
								TX_STATE<=TX_STATE_TX_PREAMBLE;
								TX_CTR<=(others=>'0');
								TX_FRAME_FIFO_RD_EN<='1'; -- Enable FRAME_FIFO Read to get the frame length. Will be available on the next state.
								IP_CHECKSUM_ACTION<=IP_CHECKSUM_ACTION_INIT; -- needed to prepare for IP header checksum precomputation
							end if;
					else
							TX_CTR<=TX_CTR+1;
					end if;




			end CASE;

		end if; -- if GMII_TXCLK
	end process; --tx_back_end

	crc32_0: entity work.CRC32 -- we explicitely specify the work library because CRC32 also exists in the unisim lirbary
		PORT MAP(
			crc_reg => ETH_CRC,
			crc => CRC_OUT,
			d => GMII_TXD_OUT2,
			calc => CRC_CALC,
			init => CRC_INIT,
			d_valid => CRC_EN,
			clk => GMII_TXCLK,
			reset => RST
		);


-- IP CHECKSUM process
ip_checksum : process(GMII_TXCLK)
	begin
		if (GMII_TXCLK'EVENT and GMII_TXCLK='1') then
			if IP_CHECKSUM_INIT='1' then
				IP_CHECKSUM_REG<=(others=>'0');
				IP_CHECKSUM_MSB<=(others=>'0'); -- not needed, just to make simulations look nicer
				IP_CHECKSUM_IS_MSB<='1';
			else
				if IP_CHECKSUM_CALC='1' then
					if IP_CHECKSUM_IS_MSB='1' then
						IP_CHECKSUM_MSB<=IP_CHECKSUM_IN;
					else
						IP_CHECKSUM_REG<=IP_CHECKSUM_REG+("00000" & UNSIGNED(IP_CHECKSUM_MSB) & UNSIGNED(IP_CHECKSUM_IN));
					end if;
				end if;
				if IP_CHECKSUM_CALC='1' or IP_CHECKSUM_INSERT='1' then
					IP_CHECKSUM_IS_MSB<=not IP_CHECKSUM_IS_MSB;
				end if;
			end if;
		end if; -- if GMII_TXCLK
	end process; --ip_checksum

IP_CHECKSUM_OUT16<=not(IP_CHECKSUM_REG(15 downto 0)+("00000000000" & IP_CHECKSUM_REG(20 downto 16)));
IP_CHECKSUM_OUT<=STD_LOGIC_VECTOR(IP_CHECKSUM_OUT16(15 downto 8)) WHEN IP_CHECKSUM_IS_MSB='1' else STD_LOGIC_VECTOR(IP_CHECKSUM_OUT16(7 downto 0));

end Behavioral;

