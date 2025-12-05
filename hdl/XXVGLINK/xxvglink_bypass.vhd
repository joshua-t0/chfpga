----------------------------------------------------------------------------------
-- Company: McGill Univ.
-- Engineer: JF Cliche
--
-- Create Date:    2025-01-20
-- Design Name:
-- Module Name:    xxvglink_bypass
-- Project Name:
-- Target Devices: Ultrascale+
-- Tool versions: Vivado 2022.2
-- Description: Implements a direct internal data link that simulates the GTY RX-TX pair.
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.VComponents.all;

library work;
use work.chFPGA_Package.all;


entity xxvglink_bypass is
    generic (
        DELAY: integer := 1 -- must be >=1
        );
	port (
		-- User AXI-Streaming data input (nnon-blocking)
		s_axis_tx_tdata: in slv64; -- Fisrt *byte* transmitted is in the MSB (i.e. first bit transmitted is bit 24)
		s_axis_tx_tvalid: in std_logic;
		s_axis_tx_tlast: in std_logic;

--		reset_stats: in std_logic;
		tx_fifo_overflow: out std_logic;
		rx_fifo_overflow: out std_logic;
		--rx_frame_detect: out std_logic;
		--rx_err_ctr: out std_logic_vector(15 downto 0); -- always 0 for a direct internal link
		--rx_max_frame: out std_logic_vector(12 downto 0);
		--rx_min_frame: out std_logic_vector(12 downto 0);

		-- User AXI-Streaming data output (non-blocking)
		m_axis_rx_tdata: out slv64;
		m_axis_rx_tvalid: out std_logic;
		m_axis_rx_tlast: out std_logic;
		m_axis_rx_terror: out std_logic := '0'; -- no error


		-- Rx stats
		fifo_overflow: out std_logic; -- non-sticky, on m_axis_rx_clk
		fifo_in_tvalid: out std_logic; -- on rx_clk
		fifo_in_tlast: out std_logic; -- on rx_clk
		fifo_in_terror: out std_logic; -- on rx_clk

		clk: in std_logic; -- clock for both the user and GTX interface
		arst : in std_logic -- asynchronous reset
		);


end xxvglink_bypass;

architecture Behavioral of xxvglink_bypass is



    -- FIFO output signals
    --signal s_axis_tx_tready: std_logic;
    signal axis_tx_tdata_int: slv64; -- Fisrt *byte* transmitted is in the MSB (i.e. first bit transmitted is bit 24)
    signal axis_tx_tvalid_int: std_logic;
    signal axis_tx_tlast_int: std_logic;

    signal tx_ctr: unsigned(6 downto 0) := (others=>'0'); -- counts clocks (0-65) to implement RX FIFO throttling
    signal read_en: std_logic; --
    signal almost_empty: std_logic;

begin


    --------------------------------------
    -- TX FIFO
    --------------------------------------
    -- TX FIFO: synchronous, FWFT, 33x512 words. The design expects a read latency of 0.
    -- Using embedded output register is highly desirable to facilitate timing closure, especially if the CT engine runs at 322 MHz.
    -- Note: We cannot use EMBED FIFO (FIFO18) with embedded output register because it has a latency of 1.
    -- We use a BRAM-based FIFO with embedded register, which has a latency of 0.
    tx_fifo0 : entity work.xxvglink_data_fifo

      PORT MAP (
        s_axis_tvalid => s_axis_tx_tvalid,
        s_axis_tlast  => s_axis_tx_tlast,
        s_axis_tdata  => s_axis_tx_tdata,
        s_clk         => clk,

        m_axis_tready => read_en,
        m_axis_tvalid => axis_tx_tvalid_int,
        m_axis_tlast  => axis_tx_tlast_int,
        m_axis_tdata  => axis_tx_tdata_int,
        m_clk         => clk,

        overflow      => tx_fifo_overflow,

        arst           => arst
      );

    rx_fifo0: entity work.xxvglink_data_fifo
      generic map (
        EMPTY_THRESHOLD => DELAY
        )
        port map (
            s_axis_tdata  => axis_tx_tdata_int,
            s_axis_tlast  => axis_tx_tlast_int,
            s_axis_tvalid => axis_tx_tvalid_int and read_en,
            s_clk         => clk,

            m_axis_tready => m_axis_rx_tvalid,
            m_axis_tvalid => m_axis_rx_tvalid,
            m_axis_tdata  => m_axis_rx_tdata,
            m_axis_tlast  => m_axis_rx_tlast,
            m_clk         => clk,

            overflow      => rx_fifo_overflow,
            almost_empty  => almost_empty,
            arst          => arst
        );

    -- Throttle the RX FIFO by skipping 2 reads every 66 clocks  to simulate the
    -- behavior of the GTY transmission which uses a 64/66 bit gearbox.
    bypass_proc: process(all) begin
        if rising_edge(clk) then
            tx_ctr <= tx_ctr + 1;
            read_en <= not almost_empty;
            if arst='1' or tx_ctr=66-1 then
                tx_ctr <= (others=>'0');
            elsif tx_ctr = 66-3 or tx_ctr = 66-2 then
                read_en <= '0';
            end if;
        end if; --clk
    end process;

    -- Assign Rx monitoring signals
    fifo_overflow <= tx_fifo_overflow or rx_fifo_overflow;
    fifo_in_tvalid <= axis_tx_tvalid_int;
    fifo_in_tlast <= axis_tx_tlast_int;
    fifo_in_terror <= '0';

end Behavioral;

