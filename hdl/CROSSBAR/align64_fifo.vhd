----------------------------------------------------------------------------------
-- Company: McGill Univ.
-- Engineer: JF Cliche
--
-- Create Date:    2025-01-20
-- Design Name:
-- Module Name:    xxvglink_data_fifo
-- Project Name:
-- Target Devices: Ultrascale+
-- Tool versions: Vivado 2022.2
-- Description: Implements a TX data FIFO using an embedded FIFO
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.VComponents.ALL;

library xpm;
use xpm.vcomponents.ALL;

library work;
use work.chFPGA_Package.ALL;

-- Uses embedded FIFO36 to save resources.
-- FIFO is FWFT, 0 latency, with output register
-- FIFO is synchronous
--
entity align64_fifo is
	generic (
		DATA_WIDTH: integer         := 64;
		ALMOST_FULL_THRESH: integer := 511
	);
	port (
		-- User AXI-Streaming data input (non-blocking)
		s_axis_tdata: in std_logic_vector(DATA_WIDTH - 1 downto 0);
		s_axis_tlast: in std_logic;
		s_axis_tvalid: in std_logic;

		m_axis_tdata: out std_logic_vector(DATA_WIDTH - 1 downto 0);
		m_axis_tlast: out std_logic;
		m_axis_tready: in std_logic := '1';
		m_axis_tvalid: out std_logic;

		empty: out std_logic;
		full: out std_logic;
		almost_full: out std_logic;
		overflow: out std_logic;
		wr_count: out std_logic_vector(9 downto 0);
		clk: in std_logic;
		rst: in std_logic -- synchronous reset
	);
end entity align64_fifo;

architecture impl of align64_fifo is

	signal fifo_doutp: std_logic_vector(7 downto 0);
	signal wr_count_wide: std_logic_vector(13 downto 0);

begin

	wr_count      <= wr_count_wide(wr_count'RANGE);
	m_axis_tvalid <= not empty;
	m_axis_tlast  <= fifo_doutp(0);
	-- FIFO is implemented using the FIFO36E2 primitive because the XPM_FIFO macro does not support the embedded FIFO.
	-- RST is synchronous to WR_CLK

	-- FIFO is 512 words x 72-bit
	acc_fifo0: FIFO36E2
		generic map (
			CLOCK_DOMAINS => "COMMON", -- synchronous FIFO
			-- PROG_EMPTY_THRESH     => 128, -- Sets the almost empty threshold
			PROG_FULL_THRESH => ALMOST_FULL_THRESH, -- Almost full threshold. This is an absolute value.
			READ_WIDTH       => 72, -- Sets data width to 4-72
			WRITE_WIDTH      => 72, -- Sets data width to 4-72
			REGISTER_MODE    => "REGISTERED", -- Output is registered as part of the FIFO, and does not add additional latency.
			FIRST_WORD_FALL_THROUGH => "TRUE",
			WRCOUNT_TYPE            => "EXTENDED_DATACOUNT"
		)
		port map (
			casdin        => (others => '0'),
			casdinp       => (others => '0'),
			casdomux      => '0',
			casdomuxen    => '0',
			casnxtrden    => '0',
			casoregimux   => '0',
			casoregimuxen => '0',
			casprvempty   => '0',
			injectsbiterr => '0',
			injectdbiterr => '0',
			-- Read Data: 32-bit (each) output: Read output data
			dout => m_axis_tdata(DATA_WIDTH - 1 downto 0), -- 64-bit output: Data output
			--      DOUTP      => (0 =>  m_axis_tlast, -- 8-bit output: Parity data output
			--                     1 => m_axis_terror, -- 8-bit output: Parity data output
			--                     others => '0'),
			doutp => fifo_doutp, -- 8-bit output: Parity data output. Cannot use partial assignments here.
			-- Read Control Signals: 1-bit (each) input: Read clock, enable and reset input signals
			rdclk  => clk, -- 1-bit input: Read clock
			rden   => m_axis_tready, -- 1-bit input: Read enable
			regce  => '1', -- 1-bit input: Clock enable
			rst    => rst, -- synchronous to WR_CLK
			rstreg => '0', -- 1-bit input: Output register set/reset
			sleep  => '0',
			empty  => empty,
			-- Write Control Signals: 1-bit (each) input: Write clock and enable input signals
			wrclk    => clk, -- 1-bit input: Write clock
			wren     => s_axis_tvalid, -- 1-bit input: Write enable
			full     => full,
			progfull => almost_full,
			rderr    => open,
			wrerr    => overflow,
			wrcount  => wr_count_wide,
			rdcount  => open,
			-- Write Data: 32-bit (each) input: Write input data
			din(DATA_WIDTH - 1 downto 0) => s_axis_tdata, -- 64-bit input: Data input
			dinp                         => 7x"00" & s_axis_tlast -- 8-bit input: Parity input
		);

end architecture impl;
