----------------------------------------------------------------------------------
-- Company: McGill Univ.
-- Engineer: JF Cliche
--
-- Create Date:    2025-01-20
-- Design Name:
-- Module Name:    xxvglink_tx_data_fifo
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

library work;
use work.chFPGA_Package.all;

-- Uses embedded FIFO. FWFT, 0 latency, with output register
-- FIFO is synchronous, as input data is coming in on the Tx clock.
--
entity xxvglink_tx_data_fifo is

	generic (
		DATA_WIDTH : integer := 65
		);
	port (
		-- User AXI-Streaming data input (nnon-blocking)
		din: in std_logic_vector(DATA_WIDTH-1 downto 0);
		wr_en: in std_logic;

		dout: out std_logic_vector(DATA_WIDTH-1 downto 0);
		rd_en: in std_logic;
		valid: out std_logic;
		empty: out std_logic;

		clk: in std_logic; -- clock for both the user and GTX interface
		rst : in std_logic -- asynchronous reset
		);
end entity xxvglink_tx_data_fifo;

architecture impl of xxvglink_tx_data_fifo is

	signal rst_reg: std_logic;

begin


	-- Synchronize reset to the write domain
	rst0: xpm_cdc_async_rst
		generic map (
			RST_ACTIVE_HIGH => 1, -- Active high reset
			DEST_SYNC_FF => 3 -- Reset pulse minimum width
		)
		port map (
			src_arst => rst,
			dest_clk => clk,
			dest_arst => rst_reg
		);

	valid <= not empty;

	-- FIFO is implemented using the FIFO36E2 primitive because the XPM_FIFO macro does not support the embedded FIFO.
	-- RST is synchronous to WR_CLK
	acc_fifo0 : FIFO36E2
		generic map (
			CLOCK_DOMAINS => "COMMON", -- common clock / synchronous FIFO
			--PROG_EMPTY_THRESH     => 128, -- Sets the almost empty threshold
			--PROG_FULL_THRESH      => 128, -- Sets almost full threshold
			READ_WIDTH              => 72, -- Sets data width to 4-72
			WRITE_WIDTH              => 72, -- Sets data width to 4-72
			REGISTER_MODE         => "REGISTERED", -- Output is registered as part of the FIFO, and does not add additional latency.
			--REGISTER_MODE         => "DO_PIPELINED", -- Output is registered as a pipeline register, with an additional latency. We need this latency to be compatible with the 7-series FIFOE1 in synchronous mode with output register.
			FIRST_WORD_FALL_THROUGH => "TRUE", -- Sets the FIFO FWFT to FALSE, TRUE. Must be FALSE when EN_SYN=TRUE.
			INIT                    => X"000000000", -- Initial values on output port
			SRVAL                   => X"000000000" -- Set/Reset value for output port
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

			-- Read Data: 32-bit (each) output: Read output data
			DOUT          => dout(63 downto 0), -- 64-bit output: Data output
			DOUTP(0)      => dout(64), -- 8-bit output: Parity data output
			-- Read Control Signals: 1-bit (each) input: Read clock, enable and reset input signals
			RDCLK       => clk, -- 1-bit input: Read clock
			RDEN        => rd_en, -- 1-bit input: Read enable
			REGCE       => '1', -- 1-bit input: Clock enable
			RST         => rst_reg, -- 1-bit input: Asynchronous Reset
			RSTREG      => '0', -- 1-bit input: Output register set/reset
			SLEEP => '0',
			EMPTY => empty,
			-- Write Control Signals: 1-bit (each) input: Write clock and enable input signals
			WRCLK       => clk, -- 1-bit input: Write clock
			WREN        => wr_en, -- 1-bit input: Write enable
			FULL        => full,
			RDERR => open,
			WRERR => overflow,
			WRCOUNT => open,
			RDCOUNT => open,
			-- Write Data: 32-bit (each) input: Write input data
			DIN          => din(63 downto 0), -- 64-bit input: Data input
			DINP         => "0000000" & din(64) -- 8-bit input: Parity input
		);