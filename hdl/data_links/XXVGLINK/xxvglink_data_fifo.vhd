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
use UNISIM.VComponents.all;

library xpm;
use xpm.vcomponents.all;

library work;
use work.chFPGA_Package.all;

-- Uses embedded FIFO36 to save resources.
-- FIFO is FWFT, 0 latency, with output register
-- FIFO is aynchronous so it can be used as a Rx FIFO
--
entity xxvglink_data_fifo is

	generic (
		DATA_WIDTH : integer := 64;
		EMPTY_THRESHOLD: integer := 1; -- Must be >=1
		FULL_THRESHOLD: integer := 500 
		);
	port (
		-- User AXI-Streaming data input (nnon-blocking)
		
		s_axis_tdata: in std_logic_vector(DATA_WIDTH-1 downto 0);
		s_axis_tlast: in std_logic;
		s_axis_tvalid: in std_logic;
		s_axis_terror: in std_logic := '0';
		s_clk: in std_logic;

		full: out std_logic; -- on s_clk
        almost_full: out std_logic; -- on s_clk
		overflow: out std_logic; -- on s_clk

		m_axis_tdata: out std_logic_vector(DATA_WIDTH-1 downto 0);
		m_axis_tlast: out std_logic;
		m_axis_tready: in std_logic := '1';
		m_axis_tvalid: out std_logic;
		m_axis_terror: out std_logic;
		m_clk: in std_logic; -- clock for both the user and GTX interface

		empty: out std_logic; -- on m_clk
        almost_empty: out std_logic;

		arst : in std_logic -- asynchronous reset
		);
end entity xxvglink_data_fifo;

architecture impl of xxvglink_data_fifo is

	signal s_rst: std_logic;
    signal fifo_doutp: std_logic_vector(7 downto 0);
    signal wr_count, rd_count: std_logic_vector(13 downto 0); -- for debug

begin


	-- Synchronize reset to the write domain
	rst0: xpm_cdc_async_rst
		generic map (
			RST_ACTIVE_HIGH => 1, -- Active high reset
			DEST_SYNC_FF => 3 -- Reset pulse minimum width
		)
		port map (
			src_arst => arst,
			dest_clk => s_clk,
			dest_arst => s_rst
		);

	m_axis_tvalid <= not empty;
    m_axis_terror <= fifo_doutp(1);
    m_axis_tlast <= fifo_doutp(0);
	-- FIFO is implemented using the FIFO36E2 primitive because the XPM_FIFO macro does not support the embedded FIFO.
	-- RST is synchronous to WR_CLK
	acc_fifo0 : FIFO36E2
		generic map (
			CLOCK_DOMAINS => "INDEPENDENT", -- independent clock / asynchronous FIFO
			PROG_EMPTY_THRESH     => EMPTY_THRESHOLD, -- Sets the almost empty threshold
			PROG_FULL_THRESH      => FULL_THRESHOLD, -- Sets almost full threshold
			READ_WIDTH              => 72, -- Sets data width to 4-72
			WRITE_WIDTH              => 72, -- Sets data width to 4-72
			REGISTER_MODE         => "REGISTERED", -- Output is registered as part of the FIFO, and does not add additional latency.
			--REGISTER_MODE         => "DO_PIPELINED", -- Output is registered as a pipeline register, with an additional latency. We need this latency to be compatible with the 7-series FIFOE1 in synchronous mode with output register.
			FIRST_WORD_FALL_THROUGH => "TRUE", -- Sets the FIFO FWFT to FALSE, TRUE. Must be FALSE when EN_SYN=TRUE.
            WRCOUNT_TYPE => "EXTENDED_DATACOUNT",
            RDCOUNT_TYPE => "EXTENDED_DATACOUNT"
--			INIT                    => X"000000000", -- Initial values on output port
--			SRVAL                   => X"000000000" -- Set/Reset value for output port
		)
		port map (
			CASDIN => (others => '0'),
			CASDINP => (others => '0'),
			casdomux => '0',
			casdomuxen => '0',
			casnxtrden => '0',
			casoregimux => '0',
			casoregimuxen => '0',
			casprvempty => '0',
            injectsbiterr => '0',
            injectdbiterr => '0',
			-- Read Data: 32-bit (each) output: Read output data
			DOUT          => m_axis_tdata(DATA_WIDTH-1 downto 0), -- 64-bit output: Data output
--			DOUTP      => (0 =>  m_axis_tlast, -- 8-bit output: Parity data output
--			               1 => m_axis_terror, -- 8-bit output: Parity data output
--			               others => '0'),
			DOUTP      => fifo_doutp, -- 8-bit output: Parity data output. Cannot use partial assignments here.

			-- Read Control Signals: 1-bit (each) input: Read clock, enable and reset input signals
			RDCLK       => m_clk, -- 1-bit input: Read clock
			RDEN        => m_axis_tready, -- 1-bit input: Read enable
			REGCE       => '1', -- 1-bit input: Clock enable
			RSTREG      => '0', -- 1-bit input: Output register set/reset
			SLEEP => '0',
			EMPTY => empty,

			-- Write Control Signals: 1-bit (each) input: Write clock and enable input signals
			WRCLK       => s_clk, -- 1-bit input: Write clock
			RST         => s_rst, -- Synchronous to wrclk
			WREN        => s_axis_tvalid, -- 1-bit input: Write enable
			FULL        => full,
			RDERR => open,
			WRERR => overflow,
			WRCOUNT => wr_count,
			RDCOUNT => rd_count,
			PROGFULL => almost_full,
			PROGEMPTY => almost_empty,
			-- Write Data: 32-bit (each) input: Write input data
			DIN(DATA_WIDTH-1 downto 0)          => s_axis_tdata, -- 64-bit input: Data input
			DINP         => "000000" & s_axis_terror  & s_axis_tlast -- 8-bit input: Parity input
		);

end architecture;