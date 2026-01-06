-- Company: McGill Univ.
-- Engineer: JF Cliche
--
-- Create Date:    2014-06-17
-- Design Name:
-- Module Name:    xglink_tx_framer
-- Project Name:
-- Target Devices: Kintex 7
-- Tool versions: Vivado 2014.2

-- Description: Packetizes an incoming AXI stream with a header and CRC and
-- feed the packets to a 64/66B XGLINK core transmitter, inserting control
-- words and IDLEs as needed.

-- History:
-- 	140617 JFC: File Created

-- Additional Comments:
-- Possible features:

----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.VComponents.all;

library work;
use work.chFPGA_Package.all;


-- Packetizes an incoming AXI stream with a start of frame, payload, CRC32 and end of frame to be fed to the 10G link. The framing is to that of 10G Ethernet (IEEE 802.3ae).
-- This transmitter is meant to be very lightweight in terms or resource utilization.
--
-- On the user side, the start of a frame is initiated when TVALID is active after the last byte of the previous frame is accepted (TVALID=1, TLAST=1 & TREADY=1)
-- If the input data is continuously available, continuous transmission will occur without mid-frame IDLEs (this is needed for Ethernet). If there is no input data, IDLE frames will be inserted.
-- A 32-bit CRC is added at the end of the frame, followed by the End of Frame control block.
--
-- On the GTX side, data will be captured only when tx_ready='1' (due to the GTX gearbox, this line is low every 2 consecutive clock out of every 66 clocks).
-- The next word word accepted after tready has been low is always the first word of a block. The ready line is therefore used to synchronize the first/last half of the data block.
--
-- On the link, the byte in the MSB of the user data word is transmitted first (big-endian). In other words, bit 24 is transmitted first.
-- This is consistent with the ordering used by the xglink core, and is easier to visualize in simulations.
-- The endianness is not configurable.
entity xglink_tx is
	port (
			-- User-side streaming interface
			
		s_axis_tx_tdata: in slv32; -- Fisrt *byte* transmitted is in the MSB (i.e. first bit transmitted is bit 24)
		s_axis_tx_tvalid: in std_logic;
		s_axis_tx_tlast: in std_logic;

		--reset_stats: in std_logic;
		tx_fifo_overflow: out std_logic; -- transient flag indicating that the TX FIFO has a overflow condition.

		-- XGLINK core interface
		
		tx_data: out slv32;
		tx_header: out slv2; -- '10' for control, '01' for data
		tx_ready: in std_logic; -- The data is accepted only on clocks where tx_ready is High

		clk: in std_logic; -- TX clock from the XGLINK core
		rst : in STD_LOGIC -- asynchronous reset
		);


end xglink_tx;

architecture Behavioral of xglink_tx is



-- Signals

-- TX state machine
type TX_STATE_TYPE is (

	TX_STATE_STANDBY_IDLE0,
	TX_STATE_STANDBY_IDLE1,
	TX_STATE_SOF0,
	TX_STATE_SOF1,
	TX_STATE_DATA0,
	TX_STATE_DATA1,
	TX_STATE_DATA1_IDLE,
	TX_STATE_DATA1_CRC,
	TX_STATE_EOF0,
	TX_STATE_EOF1,
	TX_STATE_CRC_EOF0,
	TX_STATE_CRC_EOF1
	);

signal TX_STATE: TX_STATE_TYPE := TX_STATE_STANDBY_IDLE0; -- Initialization needed

signal tx_half: std_logic; -- Indicates which half of the 64-bit block is expected on the bus

signal tdata1: slv32;
signal tvalid1: std_logic;
signal tlast1: std_logic;

signal tdata2: slv32;
signal tvalid2: std_logic;
signal tlast2: std_logic;

signal tready: std_logic;
signal tx_ready_dly: std_logic;

signal s_axis_tx_tdata_int: slv32;
signal s_axis_tx_tvalid_int: std_logic;
signal s_axis_tx_tlast_int: std_logic;
signal s_axis_tx_tready_int: std_logic;
signal tx_fifo_overflow_int: std_logic;
signal tx_reset_done: std_logic;
signal tx_reset_ctr: unsigned(3 downto 0);

signal send_data: std_logic_vector(1 downto 0); -- Identifies when we are in either of the data sending phases so we don't have to decode the state

signal crc_calc: std_logic:='0'; --
signal crc_init: std_logic:='0'; --
signal crc_out: slv32; -- Ethernet CRC word
signal crc_out_int: slv32; -- Ethernet CRC word


begin


tx_fifo0 : entity work.XGLINK_TX_DATA_FIFO
  PORT MAP (

	wr_en             => s_axis_tx_tvalid and tx_reset_done,
	din(32)           => s_axis_tx_tlast,
	din(31 downto 0)  => s_axis_tx_tdata,

	rd_en             => s_axis_tx_tready_int,
	valid             => s_axis_tx_tvalid_int,
	dout(32)          => s_axis_tx_tlast_int,
	dout(31 downto 0) => s_axis_tx_tdata_int,
	overflow          => tx_fifo_overflow_int,

	full              => open,
	empty             => open,

	clk               => clk,
	rst               => rst
  );


tx_fifo_overflow <= tx_fifo_overflow_int;


-- Instantiate the CRC engine, 32-bit wide input.
crc32_0: entity work.xglink_crc32_32
	port map(
		data_in => reverse_bits_same_dir(reverse_bytes(tdata2)), -- First bit to transmit is in the MSB of data_in
		crc_out => crc_out_int,
		rst => crc_init,
		crc_en => crc_calc,
		clk => clk
);
crc_calc <= tvalid2 and tready;
crc_out <= not reverse_bytes(reverse_bits_same_dir(crc_out_int)); -- First *byte* to transmit in the MSB, all bits inverted as per Ethernet standard

s_axis_tx_tready_int <= to_std_logic(tready='1' or tvalid2='0' or tvalid1='0'); -- We will take the data if there is any empty slot or if we are poping a word out

-- tready is high when we will consume the data on the next clock
-- We consume data if we are sending the second word, or we are sending the first word of the block and we are the last word of the frame or we expect a second word
tready <= '1' when tx_ready='1' and (send_data="11" or (send_data="10" and tvalid2='1' and (tlast2='1' or tvalid1='1'))) else '0'; -- We will consume the data word only if it is the last word or if there are two words

tx_proc : process(all) begin
	if rising_edge(clk) then

		-- Mare sure no data is written to FIFO a few clocks after reset
		if signed(tx_reset_ctr) = -1 then
			tx_reset_done <= '1';
		else
			tx_reset_ctr <= tx_reset_ctr + 1;
		end if;


		-- Store up to two words in an elastic queue so we know if we have two words to send.
		-- This is essentially a two word deep FIFO, but with the ability to look at the status of the two words at the same time
		if tready='1' then
			tvalid2 <='0';
		end if;

		if tvalid1='1' and (tvalid2='0' or tready='1') then
			tvalid2 <= '1';
			tdata2 <= tdata1;
			tlast2 <= tlast1;
			tvalid1 <= '0';
		end if;

		if s_axis_tx_tvalid_int='1' and s_axis_tx_tready_int='1' then
			tvalid1 <= '1';
			tdata1 <= s_axis_tx_tdata_int;
			tlast1 <= s_axis_tx_tlast_int;
		end if;

		crc_init<='0'; -- Compute CRC by default unless INIT=1

		-- Determine if the word on the output data has to be the first or second hald of the data block based on tready transitioning from low to high.
		-- The word present on the output when tx_ready is high after being low is always the first half of the block (tx_half=0).
		-- tx_half=0 means that the word appearing on the next clock is the first of the group.
		if tx_ready='1' and tx_ready_dly='0' then
			tx_half<='0';
		else
			tx_half <= not tx_half;
		end if;
		tx_ready_dly <= tx_ready;

		-- Output data state machine
		if tx_ready='1' then

			-- tready <='0'; -- By default do not pull a word from the tiny FIFO

			case tx_state is
				-- STANDBY State
				when TX_STATE_STANDBY_IDLE0 =>
					tx_data <= X"1E000000";
					tx_header <= "10";
					send_data <= "00";
					if tx_half='0' then -- Make sure we are aligned with the first half of the block
						tx_state <= TX_STATE_STANDBY_IDLE1;
					else
						tx_state <= TX_STATE_STANDBY_IDLE0;
					end if;

				when TX_STATE_STANDBY_IDLE1 =>
					tx_data <= X"00000000";
					tx_header <= "10";
					send_data <= "00";
					if tvalid2='1' or tvalid1='1' or s_axis_tx_tvalid_int='1' then -- if there is any data coming our way, start a new frame
						tx_state <= TX_STATE_SOF0;
					else
						tx_state <= TX_STATE_STANDBY_IDLE0;
					end if;

				when TX_STATE_SOF0 =>--Start of frame block
					tx_data <= X"78555555";
					tx_header <= "10";
					send_data <= "00";
					tx_state <= TX_STATE_SOF1;
					crc_init <= '1';

				when TX_STATE_SOF1 =>--Start of frame block
					tx_data <= X"555555D5";
					tx_header <= "10";
					send_data <= "10";
					tx_state <= TX_STATE_DATA0;

				when TX_STATE_DATA0 => --Data block, first half
					if tvalid2='1' and tlast2='1' then -- if this is the last word of the frame
						tx_data <= tdata2;
						tx_header <= "01";
						send_data <= "00";
						tx_state<=TX_STATE_DATA1_CRC; -- ...send the CRC on the second half of the block, then EOF in a new block
					elsif tvalid2='1' and tvalid1='1' then -- If there are two words in the FIFO (we can't interrupt mid-block)...
						tx_data <= tdata2;
						tx_header <= "01";
						-- tready <= '1';
						send_data <= "11";
						tx_state<=TX_STATE_DATA1; -- ... send the second word of the block
					else -- othewise we don't have enough data to fill a block so send an IDLE block instead. The data is in the pipeline and will be sent later.
						tx_data <= X"1E000000";
						tx_header <= "10";
						send_data <= "00";
						tx_state <= TX_STATE_DATA1_IDLE; -- send second word of IDLE
					end if;

				when TX_STATE_DATA1 => -- Data block, second half
					tx_data <= tdata2;
					tx_header <= "01";
					if tlast2='1' then
						send_data <= "00";
						tx_state<=TX_STATE_CRC_EOF0; -- send the CRC with the EOF on the next block
					else
						-- tready <= '1';
						send_data <= "10";
						tx_state<=TX_STATE_DATA0; -- Next word will be the first half of a data block
					end if;

				when TX_STATE_DATA1_IDLE => -- Second half of Idle block (during data transmission)
					tx_data <= X"00000000";
					tx_header <= "10";
					send_data <= "10";
					tx_state <= TX_STATE_DATA0;
					-- tready <= '1';

				when TX_STATE_DATA1_CRC => -- Send CRC on the second half of the block
					tx_data <= crc_out;
					tx_header <= "01";
					send_data <= "00";
					tx_state<=TX_STATE_EOF0; -- then send a EOF aligned with the beginning of next block

				when TX_STATE_EOF0 => --End of frame block, first half
					tx_data <= X"87000000"; -- Format: 0x87 T0 C0 C1 C2 C3 C4 C5 C6 C7. T0="0000000", and commands C0-C7 are IDLEs (0)
					tx_header <= "10";
					send_data <= "00";
					tx_state<=TX_STATE_EOF1;

				when TX_STATE_EOF1 =>--End of frame block, second half
					tx_data <= X"00000000"; -- Note: see format above. Second word is all zeros, so it won't trigger a SOF
					tx_header <= "10";
					send_data <= "00";
					tx_state<=TX_STATE_STANDBY_IDLE0;

				when TX_STATE_CRC_EOF0 =>-- First half of a combined CRC and EOF block.
					tx_data(31 downto 24) <= X"CC"; -- data block format: 0xCC D0 D1 D2 D3 T4 C5 C6 C7. D0-D4 is CRC, T4="0000", and C5-C7 are IDLEs (0)
					tx_data(23 downto 0) <= crc_out(31 downto 8);
					tx_header <= "10";
					send_data <= "00";
					tx_state<=TX_STATE_CRC_EOF1; -- Send second half of the block

				when TX_STATE_CRC_EOF1 =>-- Second half of the combined CRC and EOF block.
					tx_data(31 downto 24) <= crc_out(7 downto 0);
					tx_data(23 downto 0) <= X"000000"; -- pad remaining of block (C5 C6 C7) with IDLEs
					tx_header <= "10";
					send_data <= "00";
					tx_state<=TX_STATE_STANDBY_IDLE0;

			end case;

		end if; -- if tx_ready=1

		if rst = '1' then
			tx_state <= TX_STATE_STANDBY_IDLE0;
			send_data <= "00";
			tvalid1 <= '0';
			tvalid2 <= '0';
			tx_half <= '0';
			tx_header <= "01"; -- Make sure we have a valid header even when RST is held high.
			tx_reset_ctr <= (others => '0');
			tx_reset_done <= '0';

		end if;

	end if; -- if CLK
end process;


---- Gather stats of the RX data stream
-- (we do not provide a sticky flag here, just a transient. Stickines is managed by upper level)
--rx_fifo_overflow_proc: process(clk)
--begin
--	if rising_edge(clk) then
--		-- Detect TX FIFO overflows
--		if tx_fifo_overflow_int='1' then
--			tx_fifo_overflow <= '1';
--		elsif rst='1' or reset_stats='1'then
--			tx_fifo_overflow <= '0';
--		end if; -- reset

--	end if; --clk
--end process;

end Behavioral;

