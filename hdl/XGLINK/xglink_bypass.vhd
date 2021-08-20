--!@file
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
--! Description: Packetizes an incoming AXI stream with a start of frame, payload, CRC32 and end of frame to be fed to the 10G link. The framing is to that of 10G Ethernet (IEEE 802.3ae).
--! This transmitter is meant to be very lightweight in terms or resource utilization.
--!
--! On the user side, the start of a frame is initiated when TVALID is active after the last byte of the previous frame is accepted (TVALID=1, TLAST=1 & TREADY=1)
--! If the input data is continuously available, continuous transmission will occur without mid-frame IDLEs (this is needed for Ethernet). If there is no input data, IDLE frames will be inserted.
--! A 32-bit CRC is added at the end of the frame, followed by the End of Frame control block.
--!
--! On the GTX side, data will be captured only when tx_ready='1' (due to the GTX gearbox, this line is low every 2 consecutive clock out of every 66 clocks).
--! The next word word accepted after tready has been low is always the first word of a block. The ready line is therefore used to synchronize the first/last half of the data block.
--!
--! On the link, the byte in the MSB of the user data word is transmitted first (big-endian). In other words, bit 24 is transmitted first.
--! This is consistent with the ordering used by the xglink core, and is easier to visualize in simulations.
--! The endianness is not configurable.
--!
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


entity xglink_bypass is
	port (
		-- User AXI-Streaming data input (nnon-blocking)
		s_axis_tx_tdata: in slv32; -- Fisrt *byte* transmitted is in the MSB (i.e. first bit transmitted is bit 24)
		s_axis_tx_tvalid: in std_logic;
		s_axis_tx_tlast: in std_logic;

		reset_stats: in std_logic;
		tx_fifo_overflow: out std_logic;
		rx_fifo_overflow: out std_logic;
		rx_frame_detect: out std_logic;
		rx_err_ctr: out std_logic_vector(15 downto 0);
		rx_max_frame: out std_logic_vector(12 downto 0);
		rx_min_frame: out std_logic_vector(12 downto 0);

		-- User AXI-Streaming data output (non-blocking)
		m_axis_rx_tdata: out slv32;
		m_axis_rx_tvalid: out std_logic;
		m_axis_rx_tlast: out std_logic;
		m_axis_rx_terror: out std_logic;

		clk: in std_logic; -- clock for both the user and GTX interface
		rst : in std_logic -- asynchronous reset
		);


end xglink_bypass;

architecture Behavioral of xglink_bypass is



-- FIFO output signals
signal s_axis_tx_tready: std_logic;
signal s_axis_tx_tdata_int: slv32; -- Fisrt *byte* transmitted is in the MSB (i.e. first bit transmitted is bit 24)
signal s_axis_tx_tvalid_int: std_logic;
signal s_axis_tx_tlast_int: std_logic;
signal s_axis_tx_tready_int: std_logic;
signal tx_fifo_overflow_int: std_logic;


signal s_axis_rx_tready: std_logic;
signal rx_fifo_overflow_int: std_logic;

signal m_axis_rx_tvalid_int: std_logic;
signal m_axis_rx_tlast_int: std_logic;

signal tx_ctr: unsigned(6 downto 0) := (others=>'0');
signal read_en: std_logic; --!

signal rx_max_frame_int: unsigned(12 downto 0); -- maximum detected frame size (max 8191)
signal rx_min_frame_int: unsigned(12 downto 0); -- minimum detecteed frame size
signal rx_word_ctr: unsigned(12 downto 0); -- counts rx errors on lane specified uin 'lane_sel'


begin


--------------------------------------
-- TX FIFO
--------------------------------------


	-- tx_fifo0: entity work.XGLINK_TX_DATA_FIFO
	-- 	PORT MAP (

	-- 		s_aclk          => clk,
	-- 		s_aresetn       => not rst,

	-- 		s_axis_tvalid   => s_axis_tx_tvalid,
	-- 		s_axis_tdata    => s_axis_tx_tdata,
	-- 		s_axis_tlast    => s_axis_tx_tlast,
	-- 		s_axis_tready   => s_axis_tx_tready, -- Should always be '1'. If not, we consider this an overflow.

	-- 		m_aclk          => clk,
	-- 		m_axis_tvalid   => s_axis_tx_tvalid_int,
	-- 		m_axis_tdata    => s_axis_tx_tdata_int,
	-- 		m_axis_tlast    => s_axis_tx_tlast_int,
	-- 		m_axis_tready   => read_en,

	-- 		axis_overflow => tx_fifo_overflow_int -- on s_aclk clock
	-- 	);

		-- TX FIFO: synchronous, FWFT, 33x512 words. The design expects a read latency of 0.
		-- Using embedded output register is highly desirable to facilitate timing closure, especially if the CT engine runs at 322 MHz.
		-- Note: We cannot use EMBED FIFO (FIFO18) with embedded output register because it has a latency of 1.
		-- We use a BRAM-based FIFO with embedded register, which has a latency of 0.
		tx_fifo0 : entity work.XGLINK_TX_DATA_FIFO
		  PORT MAP (

			wr_en             => s_axis_tx_tvalid,
			din(32)           => s_axis_tx_tlast,
			din(31 downto 0)  => s_axis_tx_tdata,

			rd_en             => read_en,
			valid             => s_axis_tx_tvalid_int,
			dout(32)          => s_axis_tx_tlast_int,
			dout(31 downto 0) => s_axis_tx_tdata_int,
			overflow          => tx_fifo_overflow_int,

			full              => open,
			empty             => open,

			clk               => clk,
			srst              => rst
		  );


m_axis_rx_tvalid <= m_axis_rx_tvalid_int;
m_axis_rx_tlast <= m_axis_rx_tlast_int;
	rx_fifo0: entity work.XGLINK_RX_DATA_FIFO
		PORT MAP (

			s_aclk          => clk,
			s_aresetn       => not rst,

			s_axis_tvalid   => s_axis_tx_tvalid_int and read_en,
			s_axis_tdata    => s_axis_tx_tdata_int,
			s_axis_tlast    => s_axis_tx_tlast_int,
			s_axis_tuser    => (others => '0'),
			s_axis_tready   => s_axis_rx_tready, --

			m_aclk          => clk,
			m_axis_tvalid   => m_axis_rx_tvalid_int,
			m_axis_tdata    => m_axis_rx_tdata,
			m_axis_tlast    => m_axis_rx_tlast_int,
			m_axis_tuser(0) => m_axis_rx_terror,
			m_axis_tready   => '1', -- always send data (non-blocking output)

			axis_overflow => rx_fifo_overflow_int -- on s_aclk clock
		);

-- Test pattern generator
bypass_proc: process(clk)
begin
	if rising_edge(clk) then

		tx_ctr <= tx_ctr + 1;
		if rst='1' or tx_ctr=66-1 then
			tx_ctr <= (others=>'0');
			read_en <= '1';
		elsif tx_ctr = 66-3 then
			read_en <= '0';
		end if;

	end if; --clk
end process;


rx_err_ctr <= (others=>'0');
rx_max_frame <= std_logic_vector(rx_max_frame_int);
rx_min_frame <= std_logic_vector(rx_min_frame_int);

rx_fifo_overflow_proc: process(clk)
	begin
		if rising_edge(clk) then

			-- Detect FIFO overflows
			if rx_fifo_overflow_int='1' or s_axis_rx_tready='0' then
				rx_fifo_overflow <= '1';
			elsif rst='1' or reset_stats='1' then
				rx_fifo_overflow <= '0';
			end if;

			if tx_fifo_overflow_int='1' or s_axis_tx_tready='0' then
				tx_fifo_overflow <= '1';
			elsif rst='1' or reset_stats='1' then
				tx_fifo_overflow <= '0';
			end if;

			-- Detect maximum and minimum frame length
			if m_axis_rx_tvalid_int = '1' then
				rx_word_ctr <= rx_word_ctr + 1;
				if m_axis_rx_tlast_int = '1' then
					-- rx_frame_ctr <= rx_frame_ctr + 1;
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
				-- rx_frame_ctr <= (others => '0');
			end if; -- reset


		end if; --clk
	end process;



end Behavioral;

