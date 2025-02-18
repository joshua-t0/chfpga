----------------------------------------------------------------------------------
-- Company: McGill Univ.
-- Engineer: JF Cliche
--
-- Create Date:    2025-02-16
-- Design Name:
-- Module Name:    chan_fifo
-- Project Name:
-- Target Devices: K7 and Ultrascale+
-- Tool versions: Vivado 2022.2
-- Description: Implements an async FIFO to be used at the output of the channelizer
--
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

-- Uses embedded FIFO36 to save resources.
-- FIFO is FWFT, 0 latency, with output register
-- FIFO is aynchronous so it can be used as a Rx FIFO
--
entity chan_fifo is

	generic (
		FPGA_SERIES: integer;
		DATA_WIDTH : integer := 64;
		USER_WIDTH : integer := 4;
		ALMOST_FULL_THRESH: integer := 511;
		ALMOST_EMPTY_THRESH: integer := 2
		);
	port (
		-- User AXI-Streaming data input (nnon-blocking)
		s_axis_tdata: in std_logic_vector(DATA_WIDTH-1 downto 0);
		s_axis_tuser: in std_logic_vector(USER_WIDTH-1 downto 0) := (others => '0');
		s_axis_tlast: in std_logic;
		s_axis_tvalid: in std_logic;
		s_axis_clk: in std_logic;

		m_axis_tdata: out std_logic_vector(DATA_WIDTH-1 downto 0);
		m_axis_tuser: out std_logic_vector(USER_WIDTH-1 downto 0);
		m_axis_tlast: out std_logic;
		m_axis_tready: in std_logic := '1';
		m_axis_tvalid: out std_logic;
		m_axis_clk: in std_logic;

		empty: out std_logic;
		full: out std_logic;
		almost_full: out std_logic;
		almost_empty: out std_logic;
		overflow: out std_logic;
        wr_count: out std_logic_vector(9 downto 0);

		rst : in std_logic -- asynchronous reset
		);
end entity chan_fifo;

architecture impl of chan_fifo is
begin

    fifo_gen: case FPGA_SERIES generate

        when k7_case:FPGA_KINTEX7 =>
            signal fifo_wr_en: std_logic;
            signal fifo_rd_en: std_logic;
            signal fifo_rst_ctr : unsigned(4 downto 0);
            signal fifo_rst: std_logic;
        begin
            ----------------------
            -- FIFO reset process.
            ----------------------
            -- According to the user manual, for Async FIFOs, reset
            -- must be held for 31 clocks of the slowest clk (in_clk) when there is no safety circuit, and there must be no
            -- read or write during that period. There does not seem to be a safety circuit from the core generator GUI.
            fifo_pipe_proc: process(all) begin
                    if rising_edge(s_axis_clk) then
                        if rst = '1' then
                            fifo_rst <= '1';
                            fifo_rst_ctr <= (others => '0'); -- this is a 5-bit counter
                        elsif signed(fifo_rst_ctr) = -1 then
                            fifo_rst <= '0';
                        else
                            fifo_rst_ctr <= fifo_rst_ctr + 1;
                        end if; --reset
                    end if; --clk
                end process;

            fifo_rd_en <= m_axis_tvalid and not fifo_rst; -- start reading only when there is data. make sure we don't read during reset. In simulation, tying rd_en to '1' causes 'valid' to be invalid.
            fifo_wr_en <= s_axis_tvalid and not fifo_rst and (not almost_full or s_axis_tlast); -- make sure we don't write during reset

            -- FIFO is asynchronous, 37 bit wide (32-bit tdata, 4-bit tuser, 1 bit tlast), FWFT, zero latency
            chan_fifo0 : entity work.CHAN_FIFO2
                PORT MAP (
                    rst                => fifo_rst, -- asynchronous
                    wr_clk             => s_axis_clk,
                    wr_en              => fifo_wr_en,
                    din(31 downto 0)   => axis_fifo_in_tdata,
                    din(32)            => axis_fifo_in_tlast,
                    din(36 downto 33)  => axis_fifo_in_tuser,

                    rd_clk             => m_axis_clk,
                    rd_en              => fifo_rd_en,
                    dout(31 downto 0)  => axis_fifo_out_tdata,
                    dout(32)           => axis_fifo_out_tlast,
                    dout(36 downto 33) => axis_fifo_out_tuser,
                    valid              => axis_fifo_out_tvalid,
                    full               => open,
                    prog_full          => fifo_almost_full,
                    prog_empty         => fifo_almost_empty,
                    overflow           => fifo_overflow,
                    empty              => open
                );
        end k7_case;

        when usp_case:FPGA_ULTRASCALEPLUS =>
            signal fifo_wr_rst_busy: std_logic;
            signal fifo_rd_rst_busy: std_logic;
            signal fifo_wr_en: std_logic;
            signal fifo_rd_en: std_logic;
            signal fifo_dout: std_logic_vector(71 downto 0);
            --signal fifo_empty: std_logic;
            signal fifo_rst: std_logic;
        begin
            ----------------------
            -- FIFO reset process.
            ----------------------
            -- The Ultrascale embedded FIFO has a single reset (srst) synchronous to the write clock.
            -- The reset for the read clock domain is generated automatically.
            -- We must not assert wr_en or rd_en while the rd/wr_reset_busy is active.
            -- The reset pulse must be held for at least one write clock.
            --
            -- In this implementation we make sure the read and writes are gated by their respective reset busy signals. We therefore avoid clock domain crossing.


            fifo_rst <= rst; -- synchronous to write clock
            fifo_wr_en <= s_axis_tvalid and not (fifo_rst or fifo_wr_rst_busy); -- write clock domain
            fifo_rd_en <= m_axis_tready and not fifo_rd_rst_busy; -- start reading only when there is data. make sure we don't read during reset.

            m_axis_tdata <= fifo_dout(DATA_WIDTH-1 downto 0);
            m_axis_tlast <= fifo_dout(64);
            m_axis_tuser <= fifo_dout(64 + USER_WIDTH downto 65);
            m_axis_tvalid <= not empty;
            chan_fifo0 : FIFO36E2
                generic map (
                    CLOCK_DOMAINS           => "INDEPENDENT", -- independent clock / asynchronous FIFO
                    PROG_EMPTY_THRESH       => ALMOST_EMPTY_THRESH, -- Sets the almost empty threshold
                    PROG_FULL_THRESH        => ALMOST_FULL_THRESH, -- Sets almost full threshold
                    READ_WIDTH              => 72, -- Sets data width to 4-36
                    WRITE_WIDTH             => 72, -- Sets data width to 4-36
                    REGISTER_MODE           => "REGISTERED", -- Output is registered as part of the FIFO, and does not add additional latency.
                    FIRST_WORD_FALL_THROUGH => "TRUE" -- Sets the FIFO FWFT to FALSE, TRUE. Must be FALSE when EN_SYN=TRUE.
                )
                port map (

                    -- Write port
                    WRCLK    => s_axis_clk,
                    DIN      => resize(s_axis_tdata, 64), -- 32-bit input: Data input
                    DINP     => resize(s_axis_tuser & s_axis_tlast, 8) ,
                    WREN     => fifo_wr_en, -- 1-bit input: Write enable
                    PROGFULL =>  full,
                    WRERR    => overflow,
                    WRRSTBUSY => fifo_wr_rst_busy,

                    -- Read port
                    RDCLK    => m_axis_clk, -- 1-bit input: Read clock
                    DOUT     => fifo_dout(63 downto 0),
                    DOUTP    => fifo_dout(71 downto 64),
                    RDEN     => fifo_rd_en, -- 1-bit input: Read enable
                    EMPTY    => empty, -- = not valid
                    PROGEMPTY => almost_empty,
                    RDRSTBUSY => fifo_rd_rst_busy,

                    RST      => fifo_rst, -- synchronous to WRCLK

                    -- Unused inputs
                    CASDIN => (others => '0'), CASDINP => (others => '0'),
                    casdomux => '0', casdomuxen => '0', casnxtrden => '0',
                    casoregimux => '0', casoregimuxen => '0', casprvempty => '0',
                    injectsbiterr => '0', injectdbiterr => '0',
                    REGCE => '1', RSTREG => '0',
                    SLEEP => '0'

                );

--            chan_fifo0 : entity work.CHAN_FIFO2_UP
--                PORT MAP (
--                    srst               => fifo_rst, -- synchronous to the write clock
--                    wr_clk             => in_clk,
--                    wr_en              => fifo_wr_en,
--                    din(31 downto 0)   => axis_fifo_in_tdata,
--                    din(32)            => axis_fifo_in_tlast,
--                    din(36 downto 33)  => axis_fifo_in_tuser,

--                    rd_clk             => out_clk,
--                    rd_en              => fifo_rd_en,
--                    dout(31 downto 0)  => axis_fifo_out_tdata,
--                    dout(32)           => axis_fifo_out_tlast,
--                    dout(36 downto 33) => axis_fifo_out_tuser,
--                    valid              => axis_fifo_out_tvalid,
--                    full               => open,
--                    prog_full          => fifo_almost_full,
--                    overflow           => fifo_overflow,
--                    empty              => open,
--                    wr_rst_busy        => fifo_wr_rst_busy,
--                    rd_rst_busy        => fifo_rd_rst_busy
--                );

        end usp_case;

        when others =>
			assert FALSE report "Unknown FPGA_SERIES in CHAN FIFO selection" severity FAILURE;

    end generate fifo_gen;

end architecture;