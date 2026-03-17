----------------------------------------------------------------------------------
-- Company: McGill Univ.
-- Engineer: JF Cliche
--
-- Create Date:    2025-01-20
-- Design Name:
-- Module Name:    align64_fifo
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

-- 64-bit x 512 words embedded symmetrical, synchronous FWFT FIFO for use with align64.
--
--
-- We use an embedded FIFO36 to save resources. We instantiate a FIFO36E2 because The XPM macros
-- don't support embedded FIFOs. This entity is just a wrapper to provide a simpler interface and
-- facilitate future upgrades.
--
-- FIFO is synchronous, FWFT, 0 latency, with output register. Uses a single RAMB36 site.
--
entity align64_fifo is
	generic (
		DATA_WIDTH: integer         := 64; -- Currently limited to 64 or less. Could be more if we used unused parity bits.
		ALMOST_FULL_THRESH: integer := 511;
		ALMOST_EMPTY_THRESH: integer := 1
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
		almost_empty: out std_logic;
		almost_full: out std_logic;
		overflow: out std_logic;
		wr_count: out std_logic_vector(9 downto 0);
		clk: in std_logic; -- comon clock for both read and write domains
		rst: in std_logic -- synchronous reset
	);
end entity align64_fifo;

architecture impl of align64_fifo is

	signal fifo_doutp: std_logic_vector(7 downto 0);
	signal wr_count_wide: std_logic_vector(13 downto 0);
	signal rd_rst_busy, wr_rst_busy: std_logic;

begin

	wr_count      <= wr_count_wide(wr_count'RANGE);
	m_axis_tvalid <= not empty;
	m_axis_tlast  <= fifo_doutp(0);

	-- FIFO instantiation
	--
	-- FIFO is implemented using the FIFO36E2 primitive because the XPM_FIFO macro does not support the embedded FIFO.
	-- RST is synchronous to WR_CLK
	--
	-- FIFO is 512 words x 72-bit
	acc_fifo0: FIFO36E2
		generic map (
			CLOCK_DOMAINS => "COMMON", -- synchronous FIFO
			PROG_EMPTY_THRESH => ALMOST_EMPTY_THRESH, -- Sets the almost empty threshold
			PROG_FULL_THRESH => ALMOST_FULL_THRESH, -- Almost full threshold. This is an absolute value.
			READ_WIDTH       => 72, --  4-72. Todo: use generics...
			WRITE_WIDTH      => 72, --  4-72
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

			-- Read Data: 64-bit output: Read output data
			dout => m_axis_tdata(DATA_WIDTH - 1 downto 0), -- 64-bit output: Data output
			doutp => fifo_doutp, -- 8-bit output: Parity data output. Cannot use partial assignments here.

			-- Read Control Signals
			rdclk  => clk,
			rden   => m_axis_tready and not rd_rst_busy,
			regce  => '1', -- Output regirter clock enable
			rst    => rst, -- reset, synchronous to WR_CLK
			rstreg => '0',
			sleep  => '0',
			empty  => empty,
			progempty => almost_empty,
			rdcount  => open,
            rdrstbusy => rd_rst_busy,

			-- Write Control Signals
			wrclk    => clk,
			wren     => s_axis_tvalid and not wr_rst_busy,
			full     => full,
			progfull => almost_full,
			rderr    => open,
			wrerr    => overflow,
			wrcount  => wr_count_wide,
            wrrstbusy => wr_rst_busy,
			-- Write Data: 32-bit (each) input: Write input data
			din(DATA_WIDTH - 1 downto 0) => s_axis_tdata, -- 64-bit input: Data input
			dinp                         => 7x"00" & s_axis_tlast -- 8-bit input: Parity input
		);

end architecture impl;
