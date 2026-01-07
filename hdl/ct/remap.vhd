----------------------------------------------------------------------------------
-- Company: McGill University
-- Engineer: J.-F. Cliche
--
-- Create Date:    2013-11-24
-- Design Name: chFPGA
-- Module Name:    remap
-- Project Name: CHIME
-- Target Devices: K7
-- Tool versions: Vivado 2013.3
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;
use ieee.std_logic_misc.ALL; -- for and_reduce

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.

library unisim;
use unisim.vcomponents.ALL;
use work.chfpga_package.ALL; -- Get all component definitions

-- Remap input lanes to output lanes,

entity remap is
	generic (
		NUMBER_OF_INPUT_LANES  : integer := 4;
		NUMBER_OF_OUTPUT_LANES : integer := 4
	);
	port (
		-- Input interface (non-blocking, i.e. always accept data)

		s_axis_tvalid : in slv(0 to NUMBER_OF_INPUT_LANES - 1);
		s_axis_tdata  : in slv32_array(0 to NUMBER_OF_INPUT_LANES - 1);
		s_axis_tlast  : in slv(0 to NUMBER_OF_INPUT_LANES - 1);

		m_axis_tvalid : out slv(0 to NUMBER_OF_OUTPUT_LANES - 1);
		m_axis_tdata  : out slv32_array(0 to NUMBER_OF_OUTPUT_LANES - 1);
		m_axis_tlast  : out slv(0 to NUMBER_OF_OUTPUT_LANES - 1);

		lane_map : in slv4_array(0 to NUMBER_OF_OUTPUT_LANES - 1);
		clk      : in std_logic;
		rst      : in std_logic -- Synchronous  reset synchronized to CLK
	);
end entity remap;

-- Describes the logic that implement the entity's functionnalities. See this architecture for the
-- implementation details.

architecture impl of remap is

begin

	remap_proc: process(all)

		variable source_lane: integer range 0 to NUMBER_OF_OUTPUT_LANES - 1;

	begin
		if rising_edge(clk) then

			for target_lane in 0 to NUMBER_OF_OUTPUT_LANES - 1 loop
				source_lane := to_integer(unsigned(lane_map(target_lane))); -- remap the lane
				m_axis_tvalid(target_lane) <= s_axis_tvalid(source_lane); -- remap and pipeline the data bus
				m_axis_tdata(target_lane)  <= s_axis_tdata(source_lane); -- remap and pipeline the data bus
				m_axis_tlast(target_lane)  <= s_axis_tlast(source_lane); -- remap and pipeline the data bus

			end loop;

			if rst then
				m_axis_tvalid <= (others => '0');
			end if; -- rst
		end if; -- clk
	end process;

end architecture impl;
