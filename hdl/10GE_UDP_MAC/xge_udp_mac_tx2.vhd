----------------------------------------------------------------------------------
-- Company: McGill Univ.
-- Engineer: JF Cliche
--
-- Create Date:    2013-03-27
-- Design Name:
-- Module Name:    XGMII_UDP_MAC_TX
-- Project Name:
-- Target Devices:
-- Tool versions:
-- Description: Implements a simplified 10 Gigabit Ethernet UDP/IP/Ethernet Transmitter Packetizer and MAC with a 64-bit XGMII output interface.
--   Comments
--		- Does not add padding to the frame to meet the 64-byte minimum Ethernet frame length. The payload must therefore be big enough  (five 32-bit words)
--      - Does not transmit ARP packets
--      - The module must be reset if the IP source or destination addresses are changed. The IP checksum is precomputed only on reset.
--      - The module adds payload bytes to align the CRC to the next 64-bit word.
-- Dependencies:
--
-- History:
-- 	130321 JFC: File Created

-- Additional Comments:
-- 	TODO:
--
-- Possible features:

----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.VComponents.all;

library work;
use work.chFPGA_Package.all;


entity XGE_UDP_MAC_TX is
	generic (
		USE_LITTLE_ENDIAN: boolean := TRUE -- TRUE: Byte is LSB is transmitted first (i.e. bit 0 of word transmitted first). FALSE: Byte in MSB is transmitted first (i.e. bit 24 of word is transmitted first)
		);
	port (
		MAC_SRC_ADDR:  in std_logic_vector(47 downto 0):=X"1234567890AB";
		MAC_DEST_ADDR: in std_logic_vector(47 downto 0):=X"FFFFFFFFFFFF";
		IP_SRC_ADDR :  in std_logic_vector(31 downto 0):=X"0A_0A_0A_0B";
		IP_DEST_ADDR:  in std_logic_vector(31 downto 0):=X"FF_FF_FF_FF";
		IP_DEST_PORT:  in std_logic_vector(15 downto 0):=to_slv(41000, 16);


		-- User-side streaming interface
		s_axis_tx_tdata: in std_logic_vector(31 downto 0); -- See USE_LITTLE_ENDIAN for transmission order
		s_axis_tx_tvalid: in std_logic;
		s_axis_tx_tlast: in std_logic;
		s_axis_tx_tready: out std_logic;
		s_axis_tx_clk: in std_logic; -- <322.5 MHz, minus Ethernet overhead


		data_overflow: out std_logic;
		frame_overflow: out std_logic;

		-- xgblip interface
		tx_data: out  std_logic_vector(31 downto 0); -- Transmit data word. MSB is transmitted first
		tx_header: out  std_logic_vector(1 downto 0); -- 2-bit header of the 66 bit block
		tx_ready: in std_logic;
		clk: in std_logic; -- Transmit clock

		RST : in std_logic -- asynchronous reset
		);

end XGE_UDP_MAC_TX;

architecture Behavioral of XGE_UDP_MAC_TX is

-- Signals

signal tx_data_int: std_logic_vector(31 downto 0);
signal tx_header_int: std_logic_vector(1 downto 0);

-- TX state machine
TYPE TX_STATE_TYPE IS ( -- States of the TX state machine. The 0/1 suffix indicates if the state send data on the first (0) or second (1) half of the 64-bit data block.
	TX_STATE_STANDBY_IDLE0,
	TX_STATE_STANDBY_IDLE1,
	TX_STATE_SOF0,
	TX_STATE_SOF1,
	TX_STATE_HEADER0_0,
	TX_STATE_HEADER0_1,
	TX_STATE_HEADER1_0,
	TX_STATE_HEADER1_1,
	TX_STATE_HEADER2_0,
	TX_STATE_HEADER2_1,
	TX_STATE_HEADER3_0,
	TX_STATE_HEADER3_1,
	TX_STATE_HEADER4_0,
	TX_STATE_HEADER4_1,
	TX_STATE_DATA_FIRST0,
	TX_STATE_DATA,
	TX_STATE_DATA_LAST,
	TX_STATE_DATA_PAD1,
	TX_STATE_CRC_EOF0,
	TX_STATE_CRC_EOF1
	);
signal tx_state: TX_STATE_TYPE := TX_STATE_STANDBY_IDLE0; -- Initialization needed


signal payload_length: unsigned(15 downto 0):= (others=>'0'); -- Amount of data to transfer in UDP packet
--signal UDP_LENGTH: STD_LOGIC_VECTOR(15 downto 0); -- UDP packet length (including header), to be insterted in UDP Length field
--signal IP_LENGTH: STD_LOGIC_VECTOR(15 downto 0); -- IP packet length (including header), to be insterted in IP Length field


-- signal tx_ctr: unsigned(15 downto 0) := (others=>'0'); -- General purpose counter. Indexes the header RAM.
--signal HEADER_BYTE: STD_LOGIC_VECTOR(7 downto 0); -- General purpose counter. Indexes the header RAM.
-- signal TXD: STD_LOGIC_VECTOR(63 downto 0);
-- signal TXC: STD_LOGIC_VECTOR(7 downto 0);
-- signal TXD_REVERSE: STD_LOGIC_VECTOR(63 downto 0);
-- signal TXC_REVERSE: STD_LOGIC_VECTOR(7 downto 0);
signal txd_dly: std_logic_vector(15 downto 0);


--TYPE CRC_ACTION_TYPE IS (CRC_ACTION_INIT,CRC_ACTION_CALC, CRC_ACTION_INSERT);
--signal CRC_ACTION: CRC_ACTION_TYPE:=CRC_ACTION_INIT; -- Initialization is needed

--signal ETH_CRC: STD_LOGIC_VECTOR(31 downto 0):=X"12345678"; -- Ethernet frame CRC32
signal crc_calc: std_logic:='0'; --
signal crc_init: std_logic:='0'; --
signal crc_out_reg: std_logic_vector(31 downto 0); -- ethernet crc word
signal crc_out_reg_int: std_logic_vector(31 downto 0); -- ethernet crc word
signal crc_out_comb: std_logic_vector(31 downto 0); -- ethernet crc word
signal crc_out_comb_int: std_logic_vector(31 downto 0);

signal tx_half: std_logic;
signal tx_ready_dly: std_logic;

-- IP Checksum
TYPE IP_CHECKSUM_ACTION_TYPE IS (
	IP_CHECKSUM_ACTION_LOAD,
	IP_CHECKSUM_ACTION_ADD,
	IP_CHECKSUM_ACTION_ADD_CARRY,
	IP_CHECKSUM_ACTION_HOLD
	);
signal ip_checksum_action: IP_CHECKSUM_ACTION_TYPE:=IP_CHECKSUM_ACTION_HOLD; -- Initialization is needed

-- signal IP_CHECKSUM_ENGINE_READY: std_logic:='0';
-- signal IP_CHECKSUM_PRECOMPUTE_STEP: integer range 0 to 3:=0;
-- signal IP_CHECKSUM_PRECOMPUTED_SUM: unsigned(19 downto 0);
signal ip_checksum_sum: unsigned(19 downto 0);
signal ip_checksum_dout: std_logic_vector(15 downto 0);
signal ip_checksum_din: std_logic_vector(19 downto 0);


signal data_fifo_din: STD_LOGIC_VECTOR(32 downto 0); -- TX FIFO output data
signal data_fifo_wr_en: STD_LOGIC:='0'; -- TX FIFO write enable
signal data_fifo_dout: STD_LOGIC_VECTOR(32 downto 0); -- TX FIFO output data
signal data_fifo_rd_en: STD_LOGIC:='0'; -- TX FIFO Read enable
signal data_fifo_valid: STD_LOGIC; -- TX FIFO valid flag
signal data_fifo_overflow: std_logic;
signal data_fifo_overflow_sticky: std_logic;
signal data_fifo_dout_last: std_logic;
-- signal data_fifo_dout_dly: STD_LOGIC_VECTOR(33 downto 0); -- delayed LSW of TX FIFO output data
signal din_ctr: unsigned(13 downto 0); -- counts words (4 bytes at a time)



-- signal data_fifo_aligned_dout: std_logic_vector(63 downto 0);
-- -- signal data_fifo_aligned_last: std_logic;
-- signal data_fifo_aligned_last_h: std_logic;
-- signal data_fifo_aligned_last_l: std_logic;
-- signal data_fifo_aligned_rd_en: std_logic;
-- -- signal data_fifo_alignment: std_logic;

signal header_fifo_din: std_logic_vector(17 downto 0);
signal header_fifo_dout: STD_LOGIC_VECTOR(17 downto 0); --
signal header_fifo_wr_en: STD_LOGIC :='0';
signal header_fifo_rd_en: STD_LOGIC :='0';
signal header_fifo_valid: STD_LOGIC :='0';
signal header_fifo_overflow: std_logic;
signal header_fifo_overflow_sticky: std_logic;


--COMPONENT XGMII_UDP_MAC_TX_HEADER_FIFO
--  PORT (
--    rst : IN STD_LOGIC;
--    wr_clk : IN STD_LOGIC;
--    rd_clk : IN STD_LOGIC;
--    din : IN STD_LOGIC_VECTOR(17 DOWNTO 0);
--    wr_en : IN STD_LOGIC;
--    rd_en : IN STD_LOGIC;
--    dout : OUT STD_LOGIC_VECTOR(17 DOWNTO 0);
--    full : OUT STD_LOGIC;
--    overflow : OUT STD_LOGIC;
--    empty : OUT STD_LOGIC;
--    valid : OUT STD_LOGIC
--  );
--END COMPONENT;

--COMPONENT XGMII_UDP_MAC_TX_DATA_FIFO
--  PORT (
--    rst : IN STD_LOGIC;
--    wr_clk : IN STD_LOGIC;
--    rd_clk : IN STD_LOGIC;
--    din : IN STD_LOGIC_VECTOR(32 DOWNTO 0);
--    wr_en : IN STD_LOGIC;
--    rd_en : IN STD_LOGIC;
--    dout : OUT STD_LOGIC_VECTOR(32 DOWNTO 0);
--    full : OUT STD_LOGIC;
--    overflow : OUT STD_LOGIC;
--    empty : OUT STD_LOGIC;
--    valid : OUT STD_LOGIC
--  );
--END COMPONENT;


begin

tx_data <= tx_data_int;
tx_header <= tx_header_int;

DATA_FIFO0 : entity work.XGMII_UDP_MAC_TX_DATA_FIFO
		port map (
			rst => RST,
			wr_clk => s_axis_tx_clk,
			din => data_fifo_din,
			wr_en => data_fifo_wr_en,

			rd_clk => clk,
			rd_en => data_fifo_rd_en and tx_ready,
			dout => data_fifo_dout,
			valid => data_fifo_valid,
			overflow => data_fifo_overflow
			);
data_fifo_dout_last <= data_fifo_dout(32);

FRAME_FIFO0 : entity work.XGMII_UDP_MAC_TX_HEADER_FIFO
		port map (
			rst => RST,
			wr_clk => s_axis_tx_clk,
			rd_clk => clk,
			din => header_fifo_din,
			wr_en => header_fifo_wr_en,
			rd_en => header_fifo_rd_en,
			dout => header_fifo_dout,
			valid => header_fifo_valid,
			overflow => header_fifo_overflow
			);

-- Instantiate the CRC engine, 32-bit wide input.
crc32_0: entity work.xglink_crc32_32
	port map(
		data_in => reverse_bits_same_dir(reverse_bytes(tx_data_int)), -- First bit to transmit is in the MSB of data_in
		crc_out_comb => crc_out_comb_int,
		crc_out => crc_out_reg_int,
		rst => crc_init,
		crc_en => crc_calc,
		clk => clk
);
-- crc_calc <= data_fifo_valid and data_fifo_rd_en;
crc_calc <= to_std_logic(tx_ready='1' and tx_header_int="01"); -- Compute CRC only on 'data' blocks when they are accepted by the destination
crc_out_comb <= not reverse_bytes(reverse_bits_same_dir(crc_out_comb_int)); -- First *byte* to transmit in the MSB, all bits inverted as per Ethernet standard
crc_out_reg <= not reverse_bytes(reverse_bits_same_dir(crc_out_reg_int)); -- First *byte* to transmit in the MSB, all bits inverted as per Ethernet standard

-- tready is high when we will consume the data on the next clock
-- We consume data if we are sending the second word, or we are sending the first word of the block and we are the last word of the frame or we expect a second word
-- data_fifo_rd_en <= to_std_logic(tx_ready='1' and (tx_state = TX_STATE_DATA_FIRST0 or tx_state = TX_STATE_DATA));

-- FIFO input management
--  Counts incoming bytes and stores the frame length in the frame FIFO once a frame is finished. This allows the TX state machine :
--   1) to know that a full frame is available in the TX data FIFO, therefore ensuring uninterrupted transmission of the data on the GMII interface
--   2) know in advance how many bytes are in the buffer so we can use that information to set the IP Length and UDP Length fields before we start reading the data
--  Also inserts a dummy frame if an odd amount of 32-bit words is received to make sure that the data will appear on the 64-bit output of the FIFO
s_axis_tx_tready <= '1';
tx_front_end : process(s_axis_tx_clk)
	begin

		if rising_edge(s_axis_tx_clk) then
			header_fifo_wr_en<='0';
			DATA_FIFO_WR_EN<='0';

			if s_axis_tx_tvalid='1' then
				if USE_LITTLE_ENDIAN then
					DATA_FIFO_DIN(31 downto 0) <= reverse_bytes(s_axis_tx_tdata); -- by default the internal order is to transmit byte in MSB first
				else
					DATA_FIFO_DIN(31 downto 0) <= s_axis_tx_tdata;
				end if;
				DATA_FIFO_DIN(32) <= s_axis_tx_tlast;
				DATA_FIFO_WR_EN <= '1';

				-- increment the word counter
				if(s_axis_tx_tlast='1') then
					header_fifo_din(15 downto 0)<= (std_logic_vector(DIN_CTR) & "00");
					header_fifo_din(17 downto 16)<="00";
					header_fifo_wr_en<='1';
					DIN_CTR <= to_unsigned(1, DIN_CTR'LENGTH);
				else
					DIN_CTR<=DIN_CTR + 1;
				end if;

				-- store the header info
			end if;

			-- SYnchronous reset
			if RST='1' then
				DIN_CTR<=to_unsigned(1,DIN_CTR'LENGTH);
			end if;

		end if; -- CLK
	end process;

data_overflow <= data_fifo_overflow_sticky;
frame_overflow <= header_fifo_overflow_sticky;

fifo_readout : process(clk)
	begin
		if rising_edge(clk) then
			if RST='1' then -- synchronous reset
				-- data_fifo_alignment<='0';
				DATA_FIFO_OVERFLOW_STICKY <= '0';
				header_fifo_overflow_sticky <= '0';
			else
				DATA_FIFO_OVERFLOW_STICKY <= data_fifo_overflow_sticky or data_fifo_overflow;
				header_fifo_overflow_sticky <= header_fifo_overflow_sticky or header_fifo_overflow;
			end if; -- reset
		end if; --clk
	end process;

-- TXD_REVERSE<=reverse_bytes(TXD);
-- TXC_REVERSE<=reverse_bits_same_dir(TXC);

--- -------------------------------
-- Transmit packet encoder process
-- --------------------------------
--
-- The tx_back_end process reads the FIFO and generate the control and data words that wil form UDP packets Using the 10G protocol.
-- The words sent are 32-bit wide, although the downstream transmitter  use a 64-bit word boundary to implement the 64-66 bit encoding.
--
tx_back_end : process(clk)
	-- variable XGMII_TXD_REVERSE_VAR: std_logic_vector(63 downto 0);
	-- variable XGMII_TXC_REVERSE_VAR: std_logic_vector(7 downto 0);

begin

	if rising_edge(clk) then

		-- Determine if the word on the output data has to be the first or second hald of the data block based on tready transitioning from low to high.
		-- The word present on the output when tx_ready is high after being low is always the first half of the block (tx_half=0).
		-- tx_half=0 means that the word appearing on the next clock is the first of the group.
		if tx_ready='1' and tx_ready_dly='0' then
			tx_half<='0';
		else
			tx_half <= not tx_half;
		end if;
		tx_ready_dly <= tx_ready;

		-- Transmit state machine: Sequences the transmission of the Ethernet/IP/UDP frame

		header_fifo_rd_en<='0'; -- This is enabled for one clock pulse only
		ip_checksum_action<=IP_CHECKSUM_ACTION_HOLD; -- by default hold the IP checksum unless action is overriden below
		-- data_fifo_rd_en<='0';

		crc_init <='0';

		if tx_ready='1' then -- If the destination is ready to receive a word

			txd_dly <= data_fifo_dout(15 downto 0); -- preserve the last 16 bits to send on the next cycle
			data_fifo_rd_en<='0';

			case tx_state is
				-- STANDBY State
				when TX_STATE_STANDBY_IDLE0 =>
					tx_data_int <= X"1E000000";
					tx_header_int <= "10";
					if tx_half='0' then -- Make sure we are aligned with the first half of the block
						tx_state <= TX_STATE_STANDBY_IDLE1;
					else
						tx_state <= TX_STATE_STANDBY_IDLE0;
					end if;

				when TX_STATE_STANDBY_IDLE1 =>
					tx_data_int <= X"00000000";
					tx_header_int <= "10";
					if header_fifo_valid='1' then -- If frame data is available and pre-computation of the IP checksum is complete
						PAYLOAD_LENGTH<=unsigned(header_fifo_dout(15 downto 0));
						header_fifo_rd_en<='1'; -- Fetch next header for next time. Will be cleared on next clock
						ip_checksum_action <= IP_CHECKSUM_ACTION_LOAD;
						ip_checksum_din <= to_slv(16#4500#+16#7F11#+28, 20);
						tx_state <= TX_STATE_SOF0;
					else
						tx_state <= TX_STATE_STANDBY_IDLE0;
					end if;

				when TX_STATE_SOF0 =>--Start of frame block
					tx_data_int <= X"78555555";
					tx_header_int <= "10";
					ip_checksum_action <= IP_CHECKSUM_ACTION_ADD;
					ip_checksum_din <= to_slv(resize(unsigned(IP_SRC_ADDR(31 downto 16)),20));
					tx_state <= TX_STATE_SOF1;
					crc_init <= '1';

				when TX_STATE_SOF1 =>--Start of frame block
					tx_data_int <= X"555555D5";
					tx_header_int <= "10";
					ip_checksum_action<=IP_CHECKSUM_ACTION_ADD; -- Will start sum with precomputed checksum and will add provided word
					ip_checksum_din <= to_slv(resize(unsigned(IP_SRC_ADDR(15 downto 0)),20));
					tx_state <= TX_STATE_HEADER0_0;

				when TX_STATE_HEADER0_0 =>
					tx_data_int <= MAC_DEST_ADDR(47 downto 16);
					tx_header_int <= "01";
					-- crc_init <= '0';
					-- crc_calc <= '1';
					ip_checksum_action<=IP_CHECKSUM_ACTION_ADD; -- Will start sum with precomputed checksum and will add provided word
					ip_checksum_din<= to_slv(resize(unsigned(IP_DEST_ADDR(31 downto 16)),20));
					TX_STATE<=TX_STATE_HEADER0_1;

				when TX_STATE_HEADER0_1 =>
					tx_data_int <= MAC_DEST_ADDR(15 downto 0) & MAC_SRC_ADDR(47 downto 32);
					tx_header_int <= "01";
					ip_checksum_action<=IP_CHECKSUM_ACTION_ADD; -- Will start sum with precomputed checksum and will add provided word
					ip_checksum_din<= to_slv(resize(unsigned(IP_DEST_ADDR(15 downto 0)),20));
					TX_STATE<=TX_STATE_HEADER1_0;

				when TX_STATE_HEADER1_0 =>
					tx_data_int <= MAC_SRC_ADDR(31 downto 0);
					tx_header_int <= "01";
					ip_checksum_action<=IP_CHECKSUM_ACTION_ADD; -- Will start sum with precomputed checksum and will add provided word
					ip_checksum_din<= to_slv(PAYLOAD_LENGTH, 20); -- +28 was included in the initial value
					TX_STATE<=TX_STATE_HEADER1_1;

				when TX_STATE_HEADER1_1 =>
					tx_data_int <= X"0800_4500"; -- Ethertype (0x0800), IP version (0x4)/Header length (0x5) /DSCP_ECP(0x00)
					tx_header_int <= "01";
					ip_checksum_action<=IP_CHECKSUM_ACTION_ADD_CARRY; -- Will add the carries to complete the IP checksum computation
					TX_STATE<=TX_STATE_HEADER2_0;

				when TX_STATE_HEADER2_0 =>
					tx_data_int(31 downto 16) <= std_logic_vector(PAYLOAD_LENGTH+28); -- total IP packet length, including IP header (20 bytes). We add 8 to include UDP headers.
					tx_data_int(15 downto 00) <= X"0000"; -- Identification
					tx_header_int <= "01";
					-- ip checksum not ready yet
					TX_STATE<=TX_STATE_HEADER2_1;

				when TX_STATE_HEADER2_1 =>
					tx_data_int <= X"0000_7F_11"; --flags/fragment offset, TTL, Protocol (UDP=0x11)
					tx_header_int <= "01";
					-- ip checksum ready here
					TX_STATE<=TX_STATE_HEADER3_0;

				when TX_STATE_HEADER3_0 =>
					tx_data_int(31 downto 16) <= ip_checksum_dout; -- by this time, the checksum is ready
					tx_data_int(15 downto 0) <= IP_SRC_ADDR(31 downto 16);
					tx_header_int <= "01";
					TX_STATE<=TX_STATE_HEADER3_1;

				when TX_STATE_HEADER3_1 =>
					tx_data_int(31 downto 16) <= IP_SRC_ADDR(15 downto 0);
					tx_data_int(15 downto 0) <= IP_DEST_ADDR(31 downto 16);
					tx_header_int <= "01";
					TX_STATE<=TX_STATE_HEADER4_0;

				when TX_STATE_HEADER4_0 => --
					tx_data_int(31 downto 16) <= IP_DEST_ADDR(15 downto 0);
					tx_data_int(15 downto 0) <= X"0000"; -- IP source port
					tx_header_int <= "01";
					TX_STATE<=TX_STATE_HEADER4_1;


				when TX_STATE_HEADER4_1 => --
					tx_data_int(31 downto 16) <= IP_DEST_PORT;
					tx_data_int(15 downto 0) <= std_logic_vector(PAYLOAD_LENGTH+8); -- UDP payload length
					tx_header_int <= "01";
					data_fifo_rd_en<='1'; -- Have the RD_EN flag set when we read the word on the bus so we get the next word immediatly on the next clock
					TX_STATE<=TX_STATE_DATA_FIRST0;

				when TX_STATE_DATA_FIRST0 =>
					tx_data_int(31 downto 16) <= X"0000"; -- UDP checksum - Not implemented
					tx_data_int(15 downto 0) <= data_fifo_dout(31 downto 16);
					tx_header_int <= "01";
					if data_fifo_dout_last='1' then -- We just read the last word of the frame (but still have to send the final 16 bits in TXD_DLY)
						tx_state<=TX_STATE_DATA_LAST; -- Send last half of data and first haldf of CRC in a data block, which will be followed by a control block with the rest of the CRC and EOF.
					else
						data_fifo_rd_en<='1'; -- Have the RD_EN flag set when we read the word on the bus so we get the next word immediatly on the next clock
						tx_state<=TX_STATE_DATA;
					end if;

				when TX_STATE_DATA => --
					tx_data_int(31 downto 16) <= TXD_DLY;
					tx_data_int(15 downto 0) <= data_fifo_dout(31 downto 16);
					tx_header_int <= "01";
					if data_fifo_dout_last='1' then -- We just read the last word of the frame (but still have to send the final 16 bits in TXD_DLY)
						tx_state<=TX_STATE_DATA_LAST; -- Send last half of data and first haldf of CRC in a data block, which will be followed by a control block with the rest of the CRC and EOF.
					else
						data_fifo_rd_en<='1'; -- Have the RD_EN flag set when we read the word on the bus so we get the next word immediatly on the next clock
					end if;

				when TX_STATE_DATA_LAST => -- Transmits the last data word, which is the last 16-bit overhanging value padded with zero to complete a 64-bit word. The padding is not included in the IP length so it will be stripped out. We pad because the CRC is computed on full 64-bit words only.
					tx_data_int(31 downto 16) <= TXD_DLY;
					tx_data_int(15 downto 0) <= X"0000"; -- Insert first half of CRC
					tx_header_int <= "01";
					if tx_half='0' then -- if this is the firt word of the block
						tx_state<=TX_STATE_DATA_PAD1; -- Send last half of data and first haldf of CRC in a data block, which will be followed by a control block with the rest of the CRC and EOF.
					else
						tx_state<=TX_STATE_CRC_EOF0; -- Send last half of data, the CRC and the EOF in the next block
					end if;

				when TX_STATE_DATA_PAD1 => -- Add an extra word of data padding to fill  the second half of the data block
					tx_data_int <= X"00000000";
					tx_header_int <= "01";
					tx_state<=TX_STATE_CRC_EOF0; -- Send last half of data, the CRC and the EOF in the next block

				when TX_STATE_CRC_EOF0 => -- Transmits the last data word, which is the last 16-bit overhanging value padded with zero to complete a 64-bit word. The padding is not included in the IP length so it will be stripped out. We pad because the CRC is computed on full 64-bit words only.
					-- crc_calc<='0';
					tx_data_int(31 downto 24) <= X"CC";
					tx_data_int(23 downto 0) <= crc_out_comb(31 downto 8); -- Insert second half of CRC
					tx_header_int <= "10";
					tx_state<=TX_STATE_CRC_EOF1;

				when TX_STATE_CRC_EOF1 => -- Transmits the last data word, which is the last 16-bit overhanging value padded with zero to complete a 64-bit word. The padding is not included in the IP length so it will be stripped out. We pad because the CRC is computed on full 64-bit words only.
					tx_data_int(31 downto 24) <= crc_out_reg(7 downto 0); --remainder of the CRC
					tx_data_int(23 downto 0) <= X"000000"; -- Idle
					tx_header_int <= "10";
					tx_state<=TX_STATE_STANDBY_IDLE0;



			end case;
		end if; -- if destination ready to accept word

		-- Synchronous reset
		-- We reset here to override any signals that need to be reset
		-- If the reset was at the top, with the cod ein the 'else' clause, we risk inferring a lot of unnecessary data enables for signals that are not resetted.
		if RST='1' then
			TX_STATE<=TX_STATE_STANDBY_IDLE0;
		end if;

		end if; -- if CLK
	end process; --tx_back_end


-- IP CHECKSUM process

-- Completes computation of the IP checksum
ip_checksum_dout<=std_logic_vector(not(ip_checksum_sum(15 downto 0))); -- Checksum is 1's complement of sum
ip_checksum_proc: process(clk)
	begin
		if rising_edge(clk) then
			case ip_checksum_action is
				when IP_CHECKSUM_ACTION_LOAD => -- Initialize with the precomputed checksum plus the provided word
					ip_checksum_sum <= unsigned(ip_checksum_din);
				when IP_CHECKSUM_ACTION_ADD => -- Add the provided word to the current checksum
					ip_checksum_sum <= ip_checksum_sum + unsigned(ip_checksum_din);
				when IP_CHECKSUM_ACTION_ADD_CARRY => -- Add any carries to the checksum to finalize it
					ip_checksum_sum <= ip_checksum_sum + resize(ip_checksum_sum(19 downto 16),20);
				when IP_CHECKSUM_ACTION_HOLD => -- do nothing
					-- do nothing, hold current sum
			end case;
		end if; -- CLK
	end process; --ip_checksum_proc

end Behavioral;

