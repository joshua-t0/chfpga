----------------------------------------------------------------------------------
-- Company: McGill Univ.
-- Engineer: JF Cliche
--
-- Create Date:    2025-01-22
-- Design Name:
-- Module Name:    xxvglink_rx
-- Project Name:
-- Target Devices: Ultrascale+
-- Tool versions: Vivado 2012.2
-- Description: Depacketizes data coming from the GTY interface.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.VComponents.all;

library work;
use work.chFPGA_Package.all;


-- The AXI stream starts after a 'start of frame' control code is detected on the link and ends just before the CRC, which is the last received word before a 'end of frame' control code.
-- An error line is asserted on the last word of the stream (at the same time as tlast) if the frame is invalid (bad CRC or other causes).
-- The framing is identical to that used by 10G Ethernet (IEEE 802.3ae).
-- This receiver is meant to be very lightweight in terms or resource utilization.
--
-- On the link, the byte in the MSB of the user data word is received first (big-endian). In other words, bit 24 is received first.
-- This is consistent with the ordering used by the xglink core, and is easier to visualize in simulations.
-- The endianness is not configurable.
entity xxvglink_rx is
	port (
		-- GTX-side streaming interface

		rx_data: in slv64;
		rx_data_valid: in std_logic;
		rx_header: in slv2; -- '10' for control, '01' for data
		rx_header_valid: in std_logic;
		rx_clk: in std_logic;


		-- User-side streaming interface
		m_axis_rx_tdata: out slv64;
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
end xxvglink_rx;


--! Implementation notes:
--!   1) It is assumed that there are no Idles between the last data word and the CRC and between the CRC and the EOF
architecture Behavioral of xxvglink_rx is


constant RX_HEADER_DATA: std_logic_vector(1 downto 0) := "01";
constant RX_HEADER_OSET: std_logic_vector(1 downto 0) := "10";

-- Signals

-- RX state machine
type RX_STATE_TYPE is (
	RX_STATE_SOF,
	RX_STATE_DATA
	);

signal RX_STATE: RX_STATE_TYPE := RX_STATE_SOF; -- Initialization for sims


signal rx_tdata1: slv64;
signal rx_tvalid1: std_logic;

signal rx_tdata2: slv64;
signal rx_tvalid2: std_logic;
signal rx_tlast2: std_logic;
signal rx_terror2: std_logic;

signal rx_fifo_overflow_int: std_logic;
signal rx_fifo_overflow_pulse: std_logic_vector(3 downto 0);





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
crc32_0: entity work.crc32_64
	port map(
		din => reverse_bits_same_dir(reverse_bytes(rx_data)), -- First bit to transmit is in the MSB of data_in
		crc_out => crc_out_int,
		rst => crc_init,
		en => crc_en,
		clk => rx_clk
);
crc_out <= not reverse_bytes(reverse_bits_same_dir(crc_out_int)); -- First *byte* to transmit in the MSB, all bits inverted as per Ethernet standard
crc_en <= to_std_logic(rx_state=RX_STATE_DATA and rx_data_valid='1' and rx_header_valid='1' and rx_header=RX_HEADER_DATA);
crc_init <= to_std_logic(rx_state /= RX_STATE_DATA); -- Reset CRC when not in data state

rx_proc : process(rx_clk)

begin
	if rising_edge(rx_clk) then

        rx_tvalid2 <= '0';

		if rx_data_valid and rx_header_valid then -- with the 64-bit wide GTY, data_valid and header_valid are identical

			rx_tdata1 <= rx_data;
			rx_tvalid1 <= '0';

			-- Delay the data because we can set tlast and terror only when we get the EOF/CRC word following the last word
			rx_tdata2 <= rx_tdata1;
			rx_tvalid2 <= rx_tvalid1;
			rx_tlast2 <= '0';
			rx_terror2 <= '0';

			case rx_state is
				when RX_STATE_SOF => -- Wait for Start of frame (SOF) ordered set
					rx_tvalid1 <= '0'; -- ignore data coming while we wait for SOF
					if rx_header_valid='1' and rx_header = RX_HEADER_OSET and rx_data = X"78555555_555555D5" then
						rx_state <= RX_STATE_DATA;
					end if;

				when RX_STATE_DATA => --Data block
					if rx_header = RX_HEADER_OSET and rx_data(64-1 downto 64-8) = X"CC"then -- if EOF ordered set
						-- set the tlast flag
						rx_tlast2 <= '1';
						-- If the CRC does not match, set error flags on the last word before the CRC, which is presented at the output
						if crc_out /= rx_data(64-8-1 downto 64-8-32) then
							rx_terror2 <= '1'; -- set the terror flag (a AXI-S TUSER bit)
						end if;
						rx_state <= RX_STATE_SOF; -- wait for SOF. The SOF0 state will receive the second half of the EOF block, which the transmitter sets to zeros. It will therefore be skipped by the SOF state.
					elsif rx_header = RX_HEADER_DATA then
						rx_tvalid1 <= '1';
					end if; -- if ordered set
			end case;

		end if; -- if rx_valid=1


		if rst  then
			rx_state <= RX_STATE_SOF;
			rx_tvalid1 <= '0';
			rx_tvalid2 <= '0';
		end if;

	end if; -- if CLK
end process;


rx_fifo0: entity work.xxvglink_data_fifo
	port map (
		s_axis_tvalid   => rx_tvalid2,
		s_axis_tdata    => rx_tdata2,
		s_axis_tlast    => rx_tlast2,
		s_axis_terror   => rx_terror2,
		s_clk          => rx_clk,

		m_axis_tvalid   => m_axis_rx_tvalid,
		m_axis_tdata    => m_axis_rx_tdata,
		m_axis_tlast    => m_axis_rx_tlast,
		m_axis_terror   => m_axis_rx_terror,
		m_axis_tready   => m_axis_rx_tvalid, -- Always read (non blocking output) AXI4S specs: A slave is permitted to wait for TVALID to be asserted before asserting the corresponding TREADY
		m_clk          => m_axis_rx_clk,

		overflow => rx_fifo_overflow,
		rst      => rst
	);



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
			if m_axis_rx_tvalid='1' and m_axis_rx_tlast='1' and m_axis_rx_terror='1' and signed(err_ctr_int)/=-1 then
				err_ctr_int <= err_ctr_int + 1;
			elsif rst='1' or reset_stats='1' then
				err_ctr_int <= (others=>'0');
			end if;

			-- Detect maximum and minimum frame length
			if m_axis_rx_tvalid = '1' then
				rx_word_ctr <= rx_word_ctr + 1;
				if m_axis_rx_tlast = '1' then
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

