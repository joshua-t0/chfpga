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
--		110501 JFC - Major rewrite of the transmitter. Eliminated header RAM and associated logic. Header values are loaded in a 6-byte register (tx_sreg) in the state machine for transmission. Removed tx_reg and associated logic.
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


entity udp_mac_tx is

	PORT (
			-- User-side streaming interface
			
		local_mac_addr: in std_logic_vector(47 downto 0);
		local_ip_addr: in std_logic_vector(31 downto 0);

		-- Primary destination (tx_port_offset = 0)
		
		remote_mac_addr0: in std_logic_vector(47 downto 0);
		remote_ip_addr0: in std_logic_vector(31 downto 0);
		remote_ip_port0: in std_logic_vector(15 downto 0);

		-- Secondary destination (tx_port_offset = 1)
		
		remote_mac_addr1: in std_logic_vector(47 downto 0);
		remote_ip_addr1: in std_logic_vector(31 downto 0);
		remote_ip_port1: in std_logic_vector(15 downto 0);

		arp_request : in std_logic;
		arp_remote_mac_addr: in std_logic_vector(47 downto 0);
		arp_remote_ip_addr: in std_logic_vector(31 downto 0);

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

--		GMII_RESET_L: out std_logic; -- GMII interface reset (logic low)

		gmii_txclk : in  std_logic; --  transmit clock
		gmii_txer: out std_logic; -- Transmit error flag
--		gmii_txclk: in std_logic; --  10-100BASE_T Transmit clock supplied by the PHY. We do not use it.
		gmii_txc_gtxclk: out std_logic; -- Transmit clock we generate for the PHY
		gmii_txen: out std_logic;  -- Transmit word enable
		gmii_txd: out  std_logic_vector(7 downto 0) -- Transmit word
		);


end udp_mac_tx;

-- UDP MAC TX implementation
--------------------------
--
-- We try to make the transmitter as robust as possible against overflows etc.
--
-- We don't write data in the data fifo unles we are certain we can fit the last word. This ensures there is at lease one data word for each frame flag word, and that ensures that the TLAST flag will be present.

-- Scenarios
-- 	1) Frame fifo not full, data is not read out, and we keep writing last words until FIFO is full.
--     desired behavior: we can't match data packets with frame words anymore: the frame word should not be written.
--
--	   Solution: We don't write frame word if data fifo is Full? This works because the ladt data word and frame word are written at the same time, and we know if the data write will succeed.
--
--  2) If he data fifo is full and is being filled, it will stop when the
--     frame fifo is full. If the frame fifi suddenly becomes available, the
--     end of a packet will be stored. packet length will be ok, the user will
--     have to live with partial packets with the wrong length.
architecture Behavioral of UDP_MAC_TX is


-- Signals

-- TX state machine states
TYPE TX_STATE_TYPE IS (
	TX_STATE_STDBY,
	TX_STATE_TX_PREAMBLE,
	TX_STATE_TX_HEADER,
	TX_STATE_TX_ARP,
	TX_STATE_TX_PAYLOAD,
	TX_STATE_TX_PADDING,
	TX_STATE_TX_ETH_CHECKSUM,
	TX_STATE_INTERFRAME); -- States of the TX state machine

signal tx_state: TX_STATE_TYPE := TX_STATE_STDBY; -- Initialization needed

-- TX Source selection. Determines from where the data will be taken on the next clock to be sent on the GMII TX port.
TYPE TX_SRC_SEL_TYPE IS (TX_SRC_SEL_IDLE,TX_SRC_SEL_PREAMBLE, TX_SRC_SEL_SREG, TX_SRC_SEL_FIFO);
signal tx_src_sel: TX_SRC_SEL_TYPE;
signal tx_reg: std_logic_vector(7 downto 0); -- Temporary storage for the outgoing TX byte to delay its transmission by one clock and align it with the FIFO latency


signal tx_payload_length: unsigned(15 downto 0):= (others=>'0'); -- Amount of data to transfer in UDP packet
signal udp_length: std_logic_vector(15 downto 0); -- UDP packet length (including header), to be insterted in UDP Length field
signal ip_length: std_logic_vector(15 downto 0); -- IP packet length (including header), to be insterted in IP Length field


signal tx_ctr: unsigned(15 downto 0) := (others=>'0'); -- General purpose counter. Indexes the header RAM.
--signal HEADER_BYTE: std_logic_vector(7 downto 0); -- General purpose counter. Indexes the header RAM.
signal gmii_txd_out, gmii_txd_out2: std_logic_vector(7 downto 0); --
signal gmii_txen_out: std_logic:='0'; --


TYPE CRC_ACTION_TYPE IS (CRC_ACTION_INIT,CRC_ACTION_CALC, CRC_ACTION_INSERT);
signal crc_action: CRC_ACTION_TYPE:=CRC_ACTION_INIT; -- Initialization is needed

signal eth_crc: std_logic_vector(31 downto 0) := X"12345678"; -- Ethernet frame CRC32
signal crc_calc: std_logic := '0'; --
signal crc_init: std_logic := '0'; --
signal crc_en: std_logic := '0'; --
signal crc_out: std_logic_vector(7 downto 0); -- Ethernet CRC byte
signal crc_insert: std_logic := '0'; --


TYPE IP_CHECKSUM_ACTION_TYPE IS (IP_CHECKSUM_ACTION_INIT,IP_CHECKSUM_ACTION_CALC,IP_CHECKSUM_ACTION_HOLD, IP_CHECKSUM_ACTION_INSERT);
signal ip_checksum_action: IP_CHECKSUM_ACTION_TYPE := IP_CHECKSUM_ACTION_INIT; -- Initialization is needed

signal ip_checksum_reg: unsigned(20 downto 0); -- IP header Checksum computation register.
signal ip_checksum_out16: unsigned(15 downto 0);
signal ip_checksum_in, ip_checksum_out, ip_checksum_msb: std_logic_vector(7 downto 0);
signal ip_checksum_is_msb : std_logic := '1';
signal ip_checksum_calc: std_logic := '0'; --
signal ip_checksum_init: std_logic := '1'; --
signal ip_checksum_insert: std_logic := '0'; --

signal tx_fifo_dout: std_logic_vector(8 downto 0); -- TX FIFO output data
signal tx_fifo_rd_en: std_logic := '0'; -- TX FIFO Read enable
signal tx_fifo_wr_en: std_logic := '0'; -- TX FIFO Write enable
signal tx_fifo_empty: std_logic; -- TX FIFO empty flag (on the read side)
signal tx_fifo_full: std_logic; -- TX FIFO full flag
signal tx_fifo_almost_full: std_logic; -- TX FIFO almost full flag

signal s_axis_udp_tx_tready_int: std_logic;

signal tx_frame_fifo_din, tx_frame_fifo_dout: std_logic_vector(17 downto 0); --
signal tx_frame_length: unsigned(15 downto 0) := (0=>'1', others=>'0'); -- needed in case there is no reset
signal tx_frame_length_plus_one: unsigned(15 downto  0) ;

signal tx_frame_fifo_wr_en: std_logic :='0';
signal tx_frame_fifo_rd_en: std_logic :='0';
signal tx_frame_previous: std_logic :='0';
signal tx_frame_fifo_empty :  std_logic;
signal tx_frame_fifo_full: std_logic;
signal tx_frame_fifo_almost_full: std_logic;

signal remote_mac_addr_sel:  std_logic_vector(47 downto 0);
signal remote_ip_base_addr_sel:  std_logic_vector(31 downto 0);
signal remote_ip_base_port_sel:  std_logic_vector(15 downto 0);

signal tx_sreg: std_logic_vector(47 downto 0) := (others => '0'); -- 6 bytes

signal send_arp: std_logic:='1';
--signal ARP_TYPE: std_logic:='0';
signal arp_request_previous: std_logic:='0';

begin

-- Basic combinatorial assignments
gmii_txer <= '0'; -- No transmit errors
gmii_txc_gtxclk <= gmii_txclk;

udp_length <= std_logic_vector(tx_payload_length + 8);
ip_length <= std_logic_vector(tx_payload_length + 28);

gmii_txd_out2 <= ip_checksum_out WHEN ip_checksum_insert = '1' else gmii_txd_out;

-- Data FIFO instance
data_fifo0 : entity work.udp_mac_tx_data_fifo
	port map (
		rst    => rst,
		wr_clk => tx_clk,
		rd_clk => gmii_txclk,
		din(8) => s_axis_udp_tx_tlast,
		din(7 downto 0) => s_axis_udp_tx_tdata,
		wr_en  => tx_fifo_wr_en,
		rd_en  => tx_fifo_rd_en,
		dout   => tx_fifo_dout,
		full   => tx_fifo_full,
		almost_full   => tx_fifo_almost_full,
		empty  => tx_fifo_empty
		);

-- Frame FIFO instance
--
-- Stores the number of bytes stored in the DATA, and to which tranmit channel they should be sent.
-- We need to store the length here because the length of the packet must be sent *before* the data in the IP header.
-- The FIFO also allows clock domain crossing from the user data clock to the GMII interface clock.
frame_fifo0 : entity work.udp_mac_tx_frame_fifo
	port map (
		rst         => rst,
		wr_clk      => tx_clk,
		rd_clk      => gmii_txclk,
		din         => tx_frame_fifo_din,
		wr_en       => tx_frame_fifo_wr_en,
		rd_en       => tx_frame_fifo_rd_en,
		dout        => tx_frame_fifo_dout,
		full        => tx_frame_fifo_full,
		almost_full => tx_frame_fifo_almost_full,
		empty       => tx_frame_fifo_empty
			);


-- We will accept the data (but can discard it) until we can no longer write
-- the final word in either the data or frame FIFO
s_axis_udp_tx_tready_int <= (not tx_fifo_full) and (not tx_frame_fifo_full);
s_axis_udp_tx_tready <= s_axis_udp_tx_tready_int;

-- We write data to the FIFO as long as there is place for the last word to be
-- registered in both the data and frame fifo, i.e. the frame FIFO is not full
-- and if this is not the last data word, the data FIFO must have at least one
-- additional word left for that last word
tx_fifo_wr_en <= '1' when (
	s_axis_udp_tx_tvalid='1' and tx_frame_fifo_full='0' and
	(tx_fifo_almost_full='0' or s_axis_udp_tx_tlast ='1'))
	else '0';
-- We write the length to the FRAME FIFO when the last word arrives. We don't
-- check if this FIFO is full. The write won't work anyway, and we need the
-- write+full condition to detect overflows. But we don't want to write
-- anything her eif the the DATA fifo write of the last word is not going to work (data fifo full)
tx_frame_fifo_wr_en <= '1' when (
	s_axis_udp_tx_tvalid='1' and s_axis_udp_tx_tlast='1' and tx_fifo_full='0')
	else '0';
tx_frame_fifo_din(15 downto 0) <= std_logic_vector(tx_frame_length);
tx_frame_fifo_din(17 downto 16) <= tx_port_offset; -- If the END of frame is detected by seeing that s_axis_udp_tx_tvalid is no longer active, we want to use the last valid port number sent with the last data byte while s_axis_udp_tx_tvalid was '1'

-- TX Frame FIFO management process
--  Counts incoming bytes and stores the frame length in the frame FIFO once a frame is finished. This allows the TX state machine :
--   1) to know that a full frame is available in the TX data FIFO, therefore ensuring uninterrupted transmission of the data on the GMII interface
--   2) know how many bytes to read from the FIFO
tx_front_end : process(all) begin
	if rising_edge(tx_clk) then
			-- Determine if the transmit buffer has overflow. Now we are very conservative and assume there is an overflow if we ever have to throttle the data source.
			-- which in practive should not be a problem
			if (tx_fifo_wr_en='1' and tx_fifo_full='1') or
			   (tx_frame_fifo_wr_en='1' and tx_frame_fifo_full='1') then
				tx_overflow <= '1';
			end if;

			if s_axis_udp_tx_tvalid and s_axis_udp_tx_tlast then -- but if this is the last byte of the packet
				tx_frame_length <= to_unsigned(1, tx_frame_length'length); -- ... reset the counter to 1
			elsif tx_fifo_wr_en and not tx_fifo_full then -- if we are actually writing a byte in the fifo...
				tx_frame_length <= tx_frame_length + 1; --... increase the byte counter
			end if;

			if rst then -- synchronous reset
				tx_frame_length <= to_unsigned(1, tx_frame_length'length);
				tx_overflow <= '0';
			end if; --rst
		end if; -- CLK
	end process;


-- GMII transmit process
--
-- Sends the Ethernet, IP and UDP header, payload and CRC32 to the GMII interface
tx_back_end : process(all) begin
	if rising_edge(gmii_txclk) then

		-- Output registering with CRC or CHECKSUM insertion
		if crc_insert then
			gmii_txd <= crc_out;
		else
			gmii_txd <= gmii_txd_out2;
		end if;

		GMII_TXEN <= gmii_txen_out;

		-- Detect a '0'-to-'1' transition on the arp_request input to trigger ARP packet
		-- transmission
		arp_request_previous <= arp_request;
		if(arp_request_previous='0' and arp_request='1') then
			send_arp <= '1';
		end if;


		-- Data source selector
		--
		-- Selects what data is produced on the GMII output bus: IDLE, preamble, internally-generated bytes or FIFO data
		CASE tx_src_sel IS
			WHEN TX_SRC_SEL_IDLE =>
				gmii_txen_out <= '0';
				gmii_txd_out <= X"55";
				ip_checksum_in <= tx_sreg(47 downto 40); -- Not useful

			WHEN TX_SRC_SEL_PREAMBLE =>
				gmii_txen_out <= '1';
				gmii_txd_out <= tx_reg;
				ip_checksum_in <= tx_sreg(47 downto 40);

			WHEN TX_SRC_SEL_SREG =>
				gmii_txen_out <= '1';
				gmii_txd_out <= tx_sreg(47 downto 40);
				ip_checksum_in <= tx_sreg(47 downto 40);

			WHEN TX_SRC_SEL_FIFO =>
				gmii_txen_out <= '1';
				gmii_txd_out <= tx_fifo_dout(7 downto 0);
				ip_checksum_in <= tx_fifo_dout(7 downto 0);

		END CASE;


		-- Sets the CRC computation/insertion control lines based on the CRC tag that was set with the data
		CASE crc_action IS
			WHEN CRC_ACTION_INIT =>
				crc_en<='0';
				crc_init<='1';
				crc_calc<='0';
				crc_insert<='0';

			WHEN CRC_ACTION_CALC=>
				crc_en<='1';
				crc_init<='0';
				crc_calc<='1';
				crc_insert<='0';

			WHEN CRC_ACTION_INSERT =>
				crc_en<='1';
				crc_init<='0';
				crc_calc<='0';
				crc_insert<='1';
		END CASE;

		-- Sets the IP checksum computation/insertion control lines based on the IP CHECKSUM ACTION tag that was set with the data
		CASE ip_checksum_action IS
			WHEN IP_CHECKSUM_ACTION_INIT =>
				ip_checksum_init <= '1';
				ip_checksum_calc <= '0';
				ip_checksum_insert <= '0';

			WHEN IP_CHECKSUM_ACTION_CALC=>
				ip_checksum_init <= '0';
				ip_checksum_calc <= '1';
				ip_checksum_insert <= '0';

			WHEN IP_CHECKSUM_ACTION_HOLD=>
				ip_checksum_init <= '0';
				ip_checksum_calc <= '0';
				ip_checksum_insert <= '0';

			WHEN IP_CHECKSUM_ACTION_INSERT =>
				ip_checksum_init <= '0';
				ip_checksum_calc <= '0';
				ip_checksum_insert <= '1';
		END CASE;


		-- Transmit state machine: Sequences the transmission of the Ethernet/IP/UDP frame
		--
		-- The signals used to get the data (RAM address, FIFO_RD_EN) is set as the same time as the state that process this data is set.
		-- The data source is set when clocking out of that state.
		-- The flag indicating the source of the data is set when clocking out. It tags the data.
		--
		CASE tx_state IS

			-- STANDBY State
			WHEN TX_STATE_STDBY  =>
				tx_src_sel <= TX_SRC_SEL_IDLE;  -- just in case.

				crc_action <= CRC_ACTION_INIT; -- not really needed - will be initialized later

				if not tx_frame_fifo_empty then -- If frame data is available
					tx_state <= TX_STATE_TX_PREAMBLE;
					tx_ctr <= (others => '0'); -- Initialize the counter. We're going to count 8 bytes
					tx_frame_fifo_rd_en <='1'; -- Read Frame length from frame FIFO
					ip_checksum_action <= IP_CHECKSUM_ACTION_INIT; -- needed to prepare for IP header checksum precomputation
				elsif send_arp then
					tx_state <= TX_STATE_TX_PREAMBLE;
					tx_ctr <= (others => '0'); -- Initialize the counter. We're going to count 8 bytes
					ip_checksum_action <= IP_CHECKSUM_ACTION_INIT; -- needed to prepare for IP header checksum precomputation
				end if;

			WHEN TX_STATE_TX_PREAMBLE => -- Transmits the 8-byte Ethernet preamble (0x55 x7 and 0xD5). While doing that, compute the IP Checksum on the IP addresses


				tx_sreg(47 downto 8) <= tx_sreg(39 downto 0); -- Shift left SREG by one byte. This assignment may be overriden below.
				tx_ctr <= tx_ctr + 1; -- This assignment may be overriden below

				CASE tx_ctr(3 downto 0) is
					WHEN X"0" =>
						tx_frame_fifo_rd_en <= '0'; -- Stop reading the FIFO buffer. Length of current frame to transmit is now on the FRAME_FIFO_DOUT. It will be transferred lated into the length register
						tx_src_sel <= TX_SRC_SEL_PREAMBLE; -- Send the data in tx_reg to the GMII, but the SREG data to the IP checksum engine for IP checksum precomputation
						tx_reg <= X"55";
						tx_sreg(47 downto 16) <= local_ip_addr;
						ip_checksum_action <= IP_CHECKSUM_ACTION_CALC; -- Pre-Compute IP header checksum from the IP addresses
					WHEN X"1" =>
						-- FRAME FIFO word is now on the bus.
						tx_payload_length <= unsigned(tx_frame_fifo_dout(15 downto 0)); -- Store Frame length in register -- need it to obtain IP and UDP lengths, and to count bytes during the payload transmission
						-- Now store the destination port based on bit 17:16
						case to_integer(unsigned(tx_frame_fifo_dout(17 downto 16))) is
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
					WHEN X"4" =>
						tx_sreg(47 downto 16) <= remote_ip_base_addr_sel;
					WHEN X"7" =>
						tx_reg <= X"D5";
						crc_action <= CRC_ACTION_INIT; -- initialize CRC. COmputation will start at the next state.
						tx_ctr <= (others => '0'); -- Initialize the header byte address for header transmission

						if send_arp then
							tx_state <= TX_STATE_TX_ARP;
						else
							tx_state <= TX_STATE_TX_HEADER;
						end if;
					WHEN others=>
						-- Do nothing else
				end case;

			-- TX_HEADER state
			WHEN TX_STATE_TX_HEADER =>  -- Transmits the Ethernet/IP/UDP headers. IP Header computation/insertion is enabled when necessary. Computed IP/UDP lengths are inserted when necessary.

					tx_ctr <= tx_ctr + 1; -- This assignment is sometimes overriden below
					tx_sreg(47 downto 8) <= tx_sreg(39 downto 0); -- Shift left SREG by one byte. -- This assignment is sometimes overriden below

					CASE tx_ctr(7 downto 0) IS
						WHEN X"00" => --
							crc_action <= CRC_ACTION_CALC; -- needed to start computing the Ethernet CRC
							ip_checksum_action <= IP_CHECKSUM_ACTION_HOLD; -- Needed to stop precomputation of the IP checksum on the IP addresses

							tx_src_sel <= TX_SRC_SEL_SREG;
							tx_sreg(47 downto 0) <= remote_mac_addr_sel;
						WHEN X"06" => --
							tx_src_sel <= TX_SRC_SEL_SREG;
							tx_sreg(47 downto 0) <= local_mac_addr;
						WHEN X"0C" => -- Ethertype
							tx_src_sel <= TX_SRC_SEL_SREG;
							tx_sreg(47 downto 32) <= X"0800"; -- Ethertype=0x0800
						WHEN X"0E" => -- First IP header byte
							ip_checksum_action <= IP_CHECKSUM_ACTION_CALC; -- Resume IP header checksum computation
							tx_src_sel <= TX_SRC_SEL_SREG;
							tx_sreg(47 downto 16) <= (X"4500" & ip_length); --  Ip version 0x4, IP Hdr Length = 0x5, DSCP/ECP=0x00, IP total Length= ip_length
						WHEN X"12" => -- First IP header byte
							tx_src_sel<=TX_SRC_SEL_SREG;
							tx_sreg(47 downto 0)<=X"142600007F11"; -- IP Identification =0x1426, Flags/Fragments offset=0x0000, TTL=0x7F, Protocol=0x11 (UDP)
						WHEN X"18" => -- Start inserting IP Checksum
							ip_checksum_action<=IP_CHECKSUM_ACTION_INSERT; -- Start inserting the IP Checksum. The checksum must include the IP addresses that will follow after this checksum, but we already precomputed them while sending the preamble so the checksum is valid
							tx_src_sel<=TX_SRC_SEL_SREG; -- not useful - data is overriden by IP_CHECKSUM_ACTION_INSERT
						WHEN X"1A" => -- Source IP addresses
							ip_checksum_action <= IP_CHECKSUM_ACTION_INIT; -- Stop inserting IP Checksum
							tx_src_sel <= TX_SRC_SEL_SREG;
							tx_sreg(47 downto 16) <= local_ip_addr;
						WHEN X"1E" => -- Get Destination IP
							tx_src_sel <= TX_SRC_SEL_SREG;
							tx_sreg(47 downto 16) <= remote_ip_base_addr_sel;
						WHEN X"22" => -- Source port, Destination port, UDP Length
							tx_src_sel<=TX_SRC_SEL_SREG;
							tx_sreg(47 downto 0) <= (X"0000" & remote_ip_base_port_sel & udp_length); --
						WHEN X"28" => --  UDP Checksum (disabled)
							tx_src_sel<=TX_SRC_SEL_SREG;
							tx_sreg(47 downto 32) <= X"0000"; -- UDP Checksum will be ignored
						WHEN X"29"=>
							-- The second byte of the UDP checksum is still
							-- being sent on this cycle. But this is also the
							-- end of header buffer: proceed to data
							-- trasmnission
							tx_state <= TX_STATE_TX_PAYLOAD;
							tx_fifo_rd_en <= '1'; -- data will come in the next cycle since the FIFO has a layency of 1 clock
							tx_ctr <= (others => '0'); -- Start the data word count at 1 so we can compare directly with the packet length
						WHEN others =>
							-- Do nothing
					end case;

			WHEN TX_STATE_TX_ARP =>  -- Transmits the Ethernet/IP/UDP headers. IP Header computation/insertion is enabled when necessary. Computed IP/UDP lengths are inserted when necessary.
					send_arp <= '0';
					tx_ctr <= tx_ctr + 1; -- This assignment is sometimes overriden below
					tx_sreg(47 downto 8) <= tx_sreg(39 downto 0); -- Shift left SREG by one byte. -- This assignment is sometimes overriden below

					CASE tx_ctr(7 downto 0) IS
						WHEN X"00" => --
							crc_action <= CRC_ACTION_CALC; -- needed to start computing the Ethernet CRC
							tx_src_sel <= TX_SRC_SEL_SREG;
							tx_sreg(47 downto 0) <= arp_remote_mac_addr; --
						WHEN X"06" => --
							tx_sreg(47 downto 0)<=local_mac_addr;
						WHEN X"0C" => -- Ethertype et al.
							tx_src_sel <= TX_SRC_SEL_SREG;
							tx_sreg(47 downto 0)<=X"080600010800"; -- Ethertype=0x0806 (ARP), ARP HArdware type: 1 (ethernet), ARP Protocol type 0800=IP

						WHEN X"12" => -- First IP header byte
							tx_src_sel <= TX_SRC_SEL_SREG;
							--if ARP_TYPE='0' then
							tx_sreg(47 downto 16) <= X"06040002" ; -- Hsize=6,  ProtoSize=4, Opcode=reply
							--else
							--	tx_sreg(47 downto 16)<=X"06040001" ; --
							--end if;
							--ARP_TYPE<=not ARP_TYPE;
						WHEN X"16" => -- Sender MAC
							tx_src_sel <= TX_SRC_SEL_SREG;
							tx_sreg(47 downto 0) <= local_mac_addr;
						WHEN X"1C" => -- Sender IP
							tx_src_sel <= TX_SRC_SEL_SREG;
							tx_sreg(47 downto 16) <= local_ip_addr;
						WHEN X"20" => -- target MAC
							tx_src_sel <= TX_SRC_SEL_SREG;
							tx_sreg(47 downto 0) <= arp_remote_mac_addr;
						WHEN X"26" => -- TArget IP
							tx_src_sel <= TX_SRC_SEL_SREG;
							tx_sreg(47 downto 16) <= arp_remote_ip_addr;
						WHEN X"2A" => -- Filing to greate a 60 byte ethernet frame (excluding pramble & checksum)
							tx_src_sel <= TX_SRC_SEL_SREG;
							tx_sreg(47 downto 0) <= X"000000000000"; -- Filling
						WHEN X"3B"=> -- end of frame -- proceed to checksum transmission
							tx_state <= TX_STATE_TX_ETH_CHECKSUM;
							tx_ctr <= (others => '0');
						WHEN others =>
							-- Do nothing
					end case;

			WHEN TX_STATE_TX_PAYLOAD => -- Transmit the UDP payload data frol the TX data FIFO
					-- The fifo is registering rhe rd_en=1 and the first data word will appear on this clock edge
					tx_src_sel <= TX_SRC_SEL_FIFO; -- we register the data source at the same time as the data
					crc_action <= CRC_ACTION_CALC;

					-- Stop reading the FIFO what we have reached the packet length count.
					if tx_ctr = (tx_payload_length -1) then
						tx_fifo_rd_en <= '0'; -- ok, we're finished reading data from the FIFO
						-- Check if the minimum UDP payload size of 18 bytes was transmitted to
						-- ensure a 64 byte overall ethernet frame length (including
						-- CRC). This is lots of combinatorial
						-- logic, but it works at 125 MHz
						if (tx_ctr >= 17) then
							tx_state <= TX_STATE_TX_ETH_CHECKSUM;
							tx_ctr <= (others => '0');
						else -- send padding
							tx_state <= TX_STATE_TX_PADDING;
							tx_ctr <= tx_ctr + 1;
						end if;
					else
						tx_ctr <= tx_ctr + 1;
					end if;
			WHEN TX_STATE_TX_PADDING => -- Transmit Padding up to 18 bytes
					tx_src_sel <= TX_SRC_SEL_SREG;
					tx_sreg(47 downto 40) <= X"00"; -- send zeros for padding
					crc_action <= CRC_ACTION_CALC; -- redundant

					if (tx_ctr=17) then
							tx_state <= TX_STATE_TX_ETH_CHECKSUM;
							tx_ctr <= (others => '0');
					else
							tx_ctr <= tx_ctr + 1;

					end if;



			WHEN TX_STATE_TX_ETH_CHECKSUM =>  -- Transmits the Ethernet CRC32 checksum that was computed on the whole ethernet frame
				crc_action <= CRC_ACTION_INSERT;

				if tx_ctr=3 then
						tx_state <= TX_STATE_INTERFRAME;
						tx_ctr <= (others => '0');
				else
						tx_ctr <= tx_ctr + 1;
				end if;

			WHEN TX_STATE_INTERFRAME => -- Wait for 12 clocks without sending anything to implement the interframe delay.
				crc_action <= CRC_ACTION_INIT; -- needed to stop the CRC engine to override output words
				tx_src_sel <= TX_SRC_SEL_IDLE; -- don't send anything

				if (tx_ctr=15) then
						if tx_frame_fifo_empty then -- if there is no new full frame available then jump to standby
							tx_state <= TX_STATE_STDBY;
							tx_ctr <= (others=>'0');
						else -- else start transmission of a new frame immediately
							tx_state <= TX_STATE_TX_PREAMBLE;
							tx_ctr <= (others => '0');
							tx_frame_fifo_rd_en <= '1'; -- Enable FRAME_FIFO Read to get the frame length. Will be available on the next state.
							ip_checksum_action <= IP_CHECKSUM_ACTION_INIT; -- needed to prepare for IP header checksum precomputation
						end if;
				else
						tx_ctr <= tx_ctr + 1;
				end if;
		end CASE; -- TX_STATE

		-- Synchronous reset
		if rst then
			arp_request_previous <= '0';
			send_arp <= '0';
			--SEND_GRATUITOUS_ARP<='1';
			tx_src_sel <= TX_SRC_SEL_IDLE;
			tx_state <= TX_STATE_STDBY;
		end if; -- if 'rst'
	end if; -- if gmii_txclk
end process; --tx_back_end

-- Instantiate CRC32 computing engine
crc32_0: entity work.udp_mac_crc32 -- we explicitely specify the work library because CRC32 also exists in the unisim lirbary
	PORT MAP(
		crc_reg => eth_crc,
		crc     => crc_out,
		d       => gmii_txd_out2,
		calc    => crc_calc,
		init    => crc_init,
		d_valid => crc_en,
		clk     => gmii_txclk,
		reset   => rst
	);


-- IP CHECKSUM process
--
-- Computes the 16-bit IP header checksum while the Ethernet header bytes are being sent. This is because
-- we need to send the checksum *before* the IP header is sent.
ip_checksum : process(all) begin
	if (gmii_txclk'EVENT and gmii_txclk='1') then
			if ip_checksum_init then
				ip_checksum_reg <= (others => '0');
				ip_checksum_msb <= (others => '0'); -- not needed, just to make simulations look nicer
				ip_checksum_is_msb <= '1';
			else
				if ip_checksum_calc then
					if ip_checksum_is_msb then
						ip_checksum_msb <= ip_checksum_in;
					else
						ip_checksum_reg <= ip_checksum_reg + ("00000" & unsigned(ip_checksum_msb) & unsigned(ip_checksum_in));
					end if;
				end if;
				if ip_checksum_calc or ip_checksum_insert then
					ip_checksum_is_msb <= not ip_checksum_is_msb;
				end if;
			end if;
		end if; -- if gmii_txclk
	end process; --ip_checksum

ip_checksum_out16 <= not(ip_checksum_reg(15 downto 0) + ("00000000000" & ip_checksum_reg(20 downto 16)));
ip_checksum_out <= std_logic_vector(ip_checksum_out16(15 downto 8)) WHEN ip_checksum_is_msb = '1' else std_logic_vector(ip_checksum_out16(7 downto 0));

end Behavioral;

