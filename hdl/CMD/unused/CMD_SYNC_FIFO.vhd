----------------------------------------------------------------------------------
--! @file
-- Company: McGill University
-- Engineer: J.-F. Cliche
--
-- Create Date:    2012-10-17
-- Design Name:
-- Module Name:    CTRL_FIFO - Behavioral
-- Project Name: CHIME PoC
-- Target Devices: Virtex 6 or 7 series
-- Tool versions: ISE 14.2
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 	2012-10-17 JFC: Created

----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.VComponents.all;

library work;
use work.chFPGA_Package.all; -- Get all component definitions



--! @brief Implements a shallow FIFO for the command system from A to B
entity CTRL_FIFO is
	GENERIC (
		DATA_WIDTH: integer := 8
		);
     PORT (
		-- Command streams from single slave input to multiple master outputs
		s_axis_tdata: in std_logic_vector(DATA_WIDTH-1 downto 0);
		s_axis_tvalid: in std_logic;
		s_axis_tlast: in std_logic;
		s_axis_tready: out std_logic;

		m_axis_tdata:  out std_logic_vector(DATA_WIDTH-1 downto 0);
		m_axis_tvalid: out std_logic;
		m_axis_tlast:  out std_logic;
		m_axis_tready: in std_logic;

		clk: in std_logic;
		rst: in std_logic
		);

end CTRL_FIFO;


architecture Behavioral of CTRL_FIFO is

	signal fifo_tdata: std_logic_vector(DATA_WIDTH-1 downto 0);
	signal fifo_tvalid: std_logic;
	signal fifo_tlast: std_logic;

	signal dest_ready: std_logic;


begin

	dest_ready <= m_axis_tready or not m_axis_tdata; -- '1' when new data can be moved to the output (previous data is going out or there is no data)

	fifo_proc: process(all)	begin
		if rising_edge(clk) then
			s_axis_tready <= dest_ready; -- data is moving, so we'll have room for new one

			-- Set the output with new data from input or from FIFO
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

			-- Write to FIFO. This block has to come after the read block because we override the FIFO register.
			if s_axis_tvalid and s_axis_tready then -- if we accept a word
				if not dest_ready or fifo_tvalid then -- if destination not ready to accept a word, or if there is a valid FIFO word
					fifo_tdata <= s_axis_tdata;
					fifo_tlast <= s_axis_tlast;
					fifo_tvalid <= '1';
				end if;
			end if;

			if rst then
				fifo_tvalid <= '0';
				m_axis_tvalid <= '0';
				s_axis_tready <= '0';
			end if; -- rst

		end if; --clk

	end process;


end Behavioral;

