----------------------------------------------------------------------------------
-- Company: McGill University
-- Engineer: J.-F. Cliche
--
-- Create Date:    2025-10-07
-- Design Name:
-- Module Name:    AXIS_SYNC_FIFO - Impl
-- Project Name:  chFPGA
-- Target Devices: Virtex 6, 7 series, Ultrascale+
-- Tool versions: Vivado 2022.2
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.VComponents.all;

--library work;
--use work.chFPGA_Package.all;



-- Implements a shallow AXIS FIFO allowing TREADY to be pipelined
entity axis_sync_fifo is
	GENERIC (
		DATA_WIDTH: integer := 8
		);
     PORT (
		-- Command streams from single slave input to multiple master outputs
		s_axis_tdata: in std_logic_vector(DATA_WIDTH-1 downto 0);
		s_axis_tvalid: in std_logic := '0';
		s_axis_tlast: in std_logic;
		s_axis_tready: out std_logic;

		m_axis_tdata:  out std_logic_vector(DATA_WIDTH-1 downto 0);
		m_axis_tvalid: out std_logic;
		m_axis_tlast:  out std_logic;
		m_axis_tready: in std_logic;

		clk: in std_logic;
		rst: in std_logic
		);

end axis_sync_fifo;


architecture Impl of axis_sync_fifo is

	-- One word FIFO storage
	signal fifo_tdata: std_logic_vector(DATA_WIDTH-1 downto 0);
	signal fifo_tvalid: std_logic;
	signal fifo_tlast: std_logic;

	signal dest_ready: std_logic;

begin

	dest_ready <= m_axis_tready or not m_axis_tvalid; -- '1' when new data can be moved to the output (previous data is going out or there is no data)

	fifo_proc: process(all)	begin
		if rising_edge(clk) then
			s_axis_tready <= dest_ready; -- data is moving, so we'll have room for new one

			-- Set the output
			if dest_ready then -- if data can be moved to the output
				if fifo_tvalid then -- if the FIFO is not empty, data will come from it
					m_axis_tdata  <= fifo_tdata;
					m_axis_tlast  <= fifo_tlast;
					m_axis_tvalid <= '1'; -- FIFO is not empty, so we'll have data for sure at the output
					fifo_tvalid   <= '0'; -- is overriden below if we write data at the same time we read it
				else -- FIFO is empty, pass data directly from input, if any
					m_axis_tdata <= s_axis_tdata;
					m_axis_tlast <= s_axis_tlast;
					m_axis_tvalid <= s_axis_tready and s_axis_tvalid; -- data is taken only when we signalled we would take it
				end if;
			end if;

			-- Write to FIFO, only if we need to take the inpout data but cannot write to the output. This block has to come after the read block because we override the FIFO register.
			if s_axis_tvalid and s_axis_tready and (not dest_ready or fifo_tvalid) then -- if we accept a word, but either 1) There's something in the FIFO shifting out or 2) the output is not ready
				fifo_tdata <= s_axis_tdata;
				fifo_tlast <= s_axis_tlast;
				fifo_tvalid <= '1';
			end if;

			if rst then
				fifo_tvalid <= '0';
				m_axis_tvalid <= '0';
				s_axis_tready <= '0';
			end if; -- rst

		end if; --clk

	end process;


end Impl;

