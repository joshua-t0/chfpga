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

library xpm;
use xpm.vcomponents.all;

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
		fifo_overflow: out std_logic; -- non-sticky, on m_axis_rx_clk
--		reset_stats: in std_logic; -- for stats below
--		rx_frame_detect: out std_logic;
--		rx_err_ctr: out std_logic_vector(15 downto 0);
--		rx_max_frame: out std_logic_vector(12 downto 0);
--		rx_min_frame: out std_logic_vector(12 downto 0);
		fifo_in_tvalid: out std_logic; -- on rx_clk
		fifo_in_tlast: out std_logic; -- on rx_clk
		fifo_in_terror: out std_logic; -- on rx_clk

		arst: in std_logic --async reset
		);
end xxvglink_rx;


--! Implementation notes:
--!   1) It is assumed that there are no Idles between the last data word and the CRC and between the CRC and the EOF
architecture impl of xxvglink_rx is


    constant RX_HEADER_DATA: std_logic_vector(1 downto 0) := "01";
    constant RX_HEADER_OSET: std_logic_vector(1 downto 0) := "10";

    -- Signals

    -- RX state machine
    type RX_STATE_TYPE is (
        RX_STATE_SOF,
        RX_STATE_DATA
        );


    signal RX_STATE: RX_STATE_TYPE := RX_STATE_SOF; -- Initialization for sims

    signal rx_rst: std_logic;
    signal rx_tdata1: slv64;
    signal rx_tvalid1: std_logic;

    signal fifo_in_tdata: slv64;
    signal fifo_almost_full: std_logic;

    -- signal crc_calc: std_logic:='0'; --
    signal crc_init: std_logic:='0'; --
    signal crc_out: slv32; -- Ethernet CRC word
    signal crc_out_int: slv32; -- Ethernet CRC word
    signal crc_en: std_logic;

begin

	rxrrst_cdc0: xpm_cdc_async_rst
		generic map (RST_ACTIVE_HIGH => 1)
		port map (
			src_arst  => arst,
			dest_clk  => rx_clk,
			dest_arst => rx_rst
			);

	--axrrst_cdc0: xpm_cdc_async_rst
	--	generic map (RST_ACTIVE_HIGH => 1)
	--	port map (
	--		src_arst  => arst,
	--		dest_clk  => a_clk,
	--		dest_arst => rx_rst
	--		);

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

    rx_proc : process(all) begin
        if rising_edge(rx_clk) then

            fifo_in_tvalid <= '0'; -- Data is valid only for one clock cycle unless new data is made available below
            fifo_in_tlast <= '0'; -- Needed as default when not set below
            fifo_in_terror <= '0'; -- Needed as default when not set below

            if rx_data_valid and rx_header_valid then -- with the 64-bit wide GTY, data_valid and header_valid are identical

                case rx_state is
                    when RX_STATE_SOF => -- Wait for Start of frame (SOF) ordered set
                        rx_tvalid1 <= '0'; -- ignore data coming while we wait for SOF
                        if rx_header_valid='1' and rx_header = RX_HEADER_OSET and rx_data = X"78555555_555555D5" then
                            rx_state <= RX_STATE_DATA;
                        end if;

                    when RX_STATE_DATA => --Data block
                        if rx_header = RX_HEADER_OSET then
                        	if rx_data(64-1 downto 64-8) = X"CC" then -- if EOF ordered set
	                            -- Send previous data word to FIFO, flag it as last, and set the error flag if CRC does not match
		                        fifo_in_tdata <= rx_tdata1;
		                        fifo_in_tvalid <= rx_tvalid1;
	                            fifo_in_tlast <= '1';
	                            fifo_in_terror <= rx_tvalid1 when crc_out /= rx_data(64-8-1 downto 64-8-32); -- we don't set the error flag if there is no data (empty frame)
	                            rx_tvalid1 <= '0'; -- no more data coming down the pipe
	                            rx_state <= RX_STATE_SOF;
	                    	end if; -- type of ordered set
                        elsif rx_header = RX_HEADER_DATA then
                            -- Send previous data word fo FIFO, leave tlast and terror as defaul, i.e. '0'.
                            fifo_in_tdata <= rx_tdata1;
                            fifo_in_tvalid <= rx_tvalid1;
                            fifo_in_tlast <= '0'; -- redundant, for clarity
                            -- Store incoming data use and mark is as valid
                            rx_tdata1 <= rx_data;
                            rx_tvalid1 <= '1';
                        end if; -- if ordered set
                end case;

            end if; -- if rx_valid=1

            if rx_rst then
                rx_state <= RX_STATE_SOF;
                rx_tvalid1 <= '0';
            end if;

        end if; -- if CLK
    end process;

    rx_fifo0: entity work.xxvglink_data_fifo
        port map (
            s_axis_tvalid   => fifo_in_tvalid and (not fifo_almost_full or fifo_in_tlast), -- FIFO desync prevention: ensure there is room for tlast words
            s_axis_tdata    => fifo_in_tdata,
            s_axis_tlast    => fifo_in_tlast,
            s_axis_terror   => fifo_in_terror,
            s_clk           => rx_clk,

            m_axis_tvalid   => m_axis_rx_tvalid,
            m_axis_tdata    => m_axis_rx_tdata,
            m_axis_tlast    => m_axis_rx_tlast,
            m_axis_terror   => m_axis_rx_terror,
            m_axis_tready   => '1', -- Always read (non blocking output) AXI4S specs: A slave is permitted to wait for TVALID to be asserted before asserting the corresponding TREADY
            m_clk           => m_axis_rx_clk,

            overflow => fifo_overflow,
            almost_full => fifo_almost_full,
            arst      => rx_rst -- async reset

        );


end impl;

