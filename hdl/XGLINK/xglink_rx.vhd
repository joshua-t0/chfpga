----------------------------------------------------------------------------------
-- Company: McGill Univ.
-- Engineer: JF Cliche
--
-- Create Date:    2014-06-17
-- Design Name:
-- Module Name:    xglink_tx_framer
-- Project Name:
-- Target Devices: Kintex 7
-- Tool versions: Vivado 2014.2
-- Description: Depacketizes data incoming from the xglink GTX interface. The AXI stream starts after a 'start of frame' control code is detected on the link and ends just before the CRC, which is the last received word before a 'end of frame' control code.
-- An error line is asserted on the last word of the stream (at the same time as tlast) if the frame is invalid (bad CRC or other causes).
-- The framing is identical to that used by 10G Ethernet (IEEE 802.3ae).
-- This receiver is meant to be very lightweight in terms or resource utilization.
--
-- On the link, the byte in the MSB of the user data word is received first (big-endian). In other words, bit 24 is received first.
-- This is consistent with the ordering used by the xglink core, and is easier to visualize in simulations.
-- The endianness is not configurable.

-- History:
-- 	140617 JFC: File Created

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
-- use work.ip_package.all; -- Import definition of components used in this module


entity xglink_rx is
	port (
		-- GTX-side streaming interface

		rx_data: in slv32;
		rx_data_valid: in std_logic;
		rx_header: in slv2; -- '10' for control, '01' for data
		rx_header_valid: in std_logic;
		rx_clk: in std_logic;


		-- User-side streaming interface
		
		m_axis_rx_tdata: out slv32;
		m_axis_rx_tvalid: out std_logic;
		m_axis_rx_tlast: out std_logic;
		m_axis_rx_tready: in std_logic := '1';
		m_axis_rx_terror: out std_logic;
		m_axis_rx_clk: in std_logic; -- AXIS bus clock

		-- Rx stats
		
		rx_fifo_overflow: out std_logic; -- non-sticky
		reset_stats: in std_logic; -- for stats below
		rx_frame_detect: out std_logic;
		rx_err_ctr: out std_logic_vector(15 downto 0);
		rx_max_frame: out std_logic_vector(12 downto 0);
		rx_min_frame: out std_logic_vector(12 downto 0);

		rst : in std_logic -- asynchronous reset
		);
end xglink_rx;


-- Implementation notes:
--   1) It is assumed that there are no Idles between the last data word and the CRC and between the CRC and the EOF
architecture Behavioral of xglink_rx is



-- Signals

-- TX state machine
type RX_STATE_TYPE is (

	RX_STATE_SOF0,
	RX_STATE_SOF1,
	RX_STATE_DATA0,
	RX_STATE_DATA_IDLE1,
	RX_STATE_CRC_EOF1
	);

signal RX_STATE: RX_STATE_TYPE := RX_STATE_SOF0; -- Initialization needed


signal m_axis_rx_tdata_int: slv32;
signal m_axis_rx_tvalid_int: std_logic;
signal m_axis_rx_tlast_int: std_logic;
signal m_axis_rx_tready_int: std_logic;
signal m_axis_rx_terror_int: std_logic;

signal m_axis_rx_tdata_int2: slv32;
signal m_axis_rx_tvalid_int2: std_logic;
signal m_axis_rx_tlast_int2: std_logic;
signal m_axis_rx_terror_int2: std_logic;

signal rx_fifo_overflow_int: std_logic;
signal rx_fifo_overflow_pulse: std_logic_vector(3 downto 0);

signal tdata1: slv32;
signal tvalid1: std_logic;

signal tdata2: slv32;
signal tvalid2: std_logic;



-- signal crc_calc: std_logic:='0'; --
signal crc_init: std_logic:='0'; --
signal crc_out: slv32; -- Ethernet CRC word
signal crc_out_int: slv32; -- Ethernet CRC word
signal crc_en: std_logic;

signal err_ctr_int: unsigned(15 downto 0); -- counts rx errors
signal rx_max_frame_int: unsigned(12 downto 0); -- maximum detected frame size (max 8191)
signal rx_min_frame_int: unsigned(12 downto 0); -- minimum detecteed frame size
signal rx_word_ctr: unsigned(12 downto 0); -- counts rx errors on lane specified uin 'lane_sel'

begin

-- Instantiate the CRC engine, 32-bit wide input.
crc_en <= tvalid1 and rx_data_valid;
crc32_0: entity work.xglink_crc32_32
	port map(
		data_in => reverse_bits_same_dir(reverse_bytes(tdata1)), -- First bit to transmit is in the MSB of data_in
		crc_out => crc_out_int,
		rst => crc_init,
		crc_en => crc_en,
		clk => rx_clk
);
crc_out <= not reverse_bytes(reverse_bits_same_dir(crc_out_int)); -- First *byte* to transmit in the MSB, all bits inverted as per Ethernet standard


rx_proc : process(rx_clk)

begin
	if rising_edge(rx_clk) then


		-- if m_axis_rx_tready_int = '1' then
			m_axis_rx_tvalid_int <= '0';
		-- end if;

		-- tvalid1 <= '0';
		crc_init<='0'; -- Compute CRC by default unless INIT=1

		if rx_data_valid='1' then

			-- tready <='0'; -- By default do not pull a word from the tiny FIFO

			tvalid1 <= to_std_logic(rx_header="01");
			tdata1 <= rx_data;

			tvalid2 <= tvalid1;
			tdata2 <= tdata1;

			m_axis_rx_tdata_int <= tdata2;
			m_axis_rx_tvalid_int <= tvalid2;
			m_axis_rx_tlast_int <= '0';
			m_axis_rx_terror_int <= '0';

			case rx_state is
				-- STANDBY State
				when RX_STATE_SOF0 =>
					tvalid1 <= '0';
					if rx_header_valid='1' and rx_header = "10" and rx_data = X"78555555" then
						rx_state <= RX_STATE_SOF1;
					end if;
					crc_init <= '1';

				when RX_STATE_SOF1 =>--Start of frame block
					-- We assume rx_header_valid=0 and the header has not changed value from SOF0
					tvalid1 <= '0';
					if rx_data =X"555555D5" then
						rx_state <= RX_STATE_DATA0;
					else
						rx_state <= RX_STATE_SOF0;
					end if;

				when RX_STATE_DATA0 => --Data block
					if rx_header_valid='1' and rx_header = "10" then
						tvalid1 <= '0';
						-- Situation 1: We get a control 0x87 (End of frame with no data), meaning that the previous word was the CRC
						if rx_data(31 downto 24) = X"87" then -- end of frame
							-- disable the tvalid of the CRC  that is already in the data pipeline so it it not passed on to the output
							tvalid2 <= '0';
							-- set the tlast flag on the data word before the CRC, whih is being presented at the output (m_axis_rx_tdata_int)
							m_axis_rx_tlast_int <= '1';
							-- If the CRC does not match, set error flags on the last word before the CRC, which is presented at the output
							if crc_out /= tdata1 then
								m_axis_rx_terror_int <= '1'; -- set the terror flag (a AXI-S TUSER bit)
								m_axis_rx_tdata_int(31) <= '1'; -- force '1' in the MSB of the last word (packet flags) to indicate an error (in case `terror` is not propagated)
							end if;
							rx_state <= RX_STATE_SOF0; -- wait for SOF. The SOF0 state will receive the second half of the EOF block, which the transmitter sets to zeros. It will therefore be skipped by the SOF state.
						-- Situation 2: We get a control 0xCC (end of frame with data); The first 24 bits of the CRC are included in the first half (32 bits) of the block, and the last 8 bits are in the MSB of the second half.
						elsif rx_data(31 downto 24) = X"CC" then -- end of frame with a CRC. Get the second word of the block, which contains some of the CRC
							rx_state <= RX_STATE_CRC_EOF1;
						-- This is an unsopported control code or genuine Idle. Treat as idle. Skip the second 32-bit word of the 64-bit control word.
						else
							rx_state <= RX_STATE_DATA_IDLE1;
						end if;
					end if;

				when RX_STATE_DATA_IDLE1 =>-- Skip the 2nd word of the command block
					tvalid1 <= '0';
					rx_state <= RX_STATE_DATA0;

				when RX_STATE_CRC_EOF1 => -- Second half of the combined CRC/EOF block
					-- set the tlast flag on the data word before the CRC, whih is being presented at the output (m_axis_rx_tdata_int)
					m_axis_rx_tlast_int <= '1';
					-- If the CRC does not match, set error flags on the last word before the CRC, which is presented at the output
					if crc_out /= (tdata1(23 downto 0) & rx_data(31 downto 24)) then
						m_axis_rx_terror_int <= '1'; -- set the terror flag (a AXI-S TUSER bit)
						m_axis_rx_tdata_int(31) <= '1'; -- force '1' in the MSB of the last word (packet flags) to indicate an error (in case `terror` is not propagated)
					end if;
					rx_state <= RX_STATE_SOF0;

			end case;

		end if; -- if rx_valid=1


		if RST='1' then
			rx_state <= RX_STATE_SOF0;
			tvalid1<='0';
			m_axis_rx_tvalid_int <= '0';
			tvalid2<='0';
		end if;

	end if; -- if CLK
end process;


rx_fifo0: entity work.XGLINK_RX_DATA_FIFO
	PORT MAP (

		s_aclk          => rx_clk,
		s_aresetn       => not rst,

		s_axis_tvalid   => m_axis_rx_tvalid_int,
		s_axis_tdata    => m_axis_rx_tdata_int,
		s_axis_tlast    => m_axis_rx_tlast_int,
		s_axis_tuser(0) => m_axis_rx_terror_int,
		s_axis_tready   => m_axis_rx_tready_int, -- We should always accept data. If the FIFO is not ready, we'll set the overflow flag.

		m_aclk          => m_axis_rx_clk,
		m_axis_tvalid   => m_axis_rx_tvalid_int2,
		m_axis_tdata    => m_axis_rx_tdata_int2,
		m_axis_tlast    => m_axis_rx_tlast_int2,
		m_axis_tuser(0) => m_axis_rx_terror_int2,
		m_axis_tready   => m_axis_rx_tvalid_int2 -- Always read (non blocking output) AXI4S specs: A slave is permitted to wait for TVALID to be asserted before asserting the corresponding TREADY

--		axis_overflow => rx_fifo_overflow_int -- on rx_clk clock
	);

m_axis_rx_tvalid <= m_axis_rx_tvalid_int2;
m_axis_rx_tdata <= m_axis_rx_tdata_int2;
m_axis_rx_tlast <= m_axis_rx_tlast_int2;
m_axis_rx_terror <= m_axis_rx_terror_int2;

rx_fifo_overflow <= rx_fifo_overflow_int or not m_axis_rx_tready_int;

--rx_overflow_proc: process(rx_clk, rst, reset_stats)
--begin
--	if rising_edge(rx_clk) then
--		if rx_fifo_overflow_int='1' or m_axis_rx_tready_int='0' then
--			rx_fifo_overflow <= '1';
--		elsif rst='1' or reset_stats='1' then
--			rx_fifo_overflow <= '0';
--		end if;
--	end if;
--end process;

rx_err_ctr <= std_logic_vector(err_ctr_int);
rx_max_frame <= std_logic_vector(rx_max_frame_int);
rx_min_frame <= std_logic_vector(rx_min_frame_int);
-- Gather stats of the RX data stream
rx_fifo_overflow_proc: process(m_axis_rx_clk)
	begin
		if rising_edge(m_axis_rx_clk) then

			-- Count RX errors
			if m_axis_rx_tvalid_int2='1' and m_axis_rx_tlast_int2='1' and m_axis_rx_terror_int2='1' and signed(err_ctr_int)/=-1 then
				err_ctr_int <= err_ctr_int + 1;
			elsif rst='1' or reset_stats='1' then
				err_ctr_int <= (others=>'0');
			end if;

			-- Detect maximum and minimum frame length
			if m_axis_rx_tvalid_int2 = '1' then
				rx_word_ctr <= rx_word_ctr + 1;
				if m_axis_rx_tlast_int2 = '1' then
					rx_frame_detect <= '1';
					rx_word_ctr <= (others => '0');
					if rx_word_ctr > rx_max_frame_int then
						rx_max_frame_int <= rx_word_ctr;
					end if;
					if rx_word_ctr < rx_min_frame_int then
						rx_min_frame_int <= rx_word_ctr;
					end if;
				end if;
			end if;

			--resets
			if rst='1' then
				rx_word_ctr <= (others => '0'); -- don't reset the word counter with reset_stats so we don't capture partial frames which affects the minimum packet size.
			end if;

			if reset_stats='1' or rst='1' then
				rx_max_frame_int <= (others=>'0');
				rx_min_frame_int <= (others=>'1');
				rx_frame_detect <= '0';
			end if; -- reset


		end if; --clk
	end process;

end Behavioral;

