----------------------------------------------------------------------------------
-- @file
-- Company: McGill University
-- Engineer: J.-F. Cliche
--
-- Create Date:    2013-11-24
-- Design Name: chFPGA
-- Module Name:    REMAP
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
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_misc.ALL; -- for and_reduce

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;
use work.chFPGA_Package.all; -- Get all component definitions

------- REMAP ENTITY DECLARATION ----------------------
--! @brief Remap input lanes to output lanes,
--!
entity REMAP is
	GENERIC (
		NUMBER_OF_INPUT_LANES: INTEGER:=4; --!
		NUMBER_OF_OUTPUT_LANES: INTEGER:=4 --!
		);
    PORT (
		-- Input interface (non-blocking, i.e. always accept data)

		s_axis_tvalid: in slv(0 to NUMBER_OF_INPUT_LANES-1);
		s_axis_tdata: in slv32_array(0 to NUMBER_OF_INPUT_LANES-1);
		s_axis_tlast: in slv(0 to NUMBER_OF_INPUT_LANES-1);

		m_axis_tvalid: out slv(0 to NUMBER_OF_OUTPUT_LANES-1);
		m_axis_tdata: out slv32_array(0 to NUMBER_OF_OUTPUT_LANES-1);
		m_axis_tlast: out slv(0 to NUMBER_OF_OUTPUT_LANES-1);

		lane_map: in slv4_array(0 to NUMBER_OF_OUTPUT_LANES-1);
		clk: in std_logic;
		rst : in STD_LOGIC --! Synchronous  reset synchronized to CLK
  );


end REMAP;

--- ARCHITECTURE DECLARATION and DEFINITION ---------------------
--! Describes the logic that implement the entity's functionnalities. See this architecture for the implementation details.
architecture Behavioral of REMAP is

--- Signal definitions ------------------------------------

begin

remap_proc: process(clk)
	variable source_lane: integer range 0 to NUMBER_OF_OUTPUT_LANES-1;
	begin
		if rising_edge(clk) then
			for target_lane in 0 to NUMBER_OF_OUTPUT_LANES-1 loop
				source_lane := to_integer(unsigned(lane_map(target_lane)));
				m_axis_tvalid(target_lane) <= s_axis_tvalid(source_lane); -- remap and pipeline the data bus
				m_axis_tdata(target_lane) <= s_axis_tdata(source_lane); -- remap and pipeline the data bus
				m_axis_tlast(target_lane) <= s_axis_tlast(source_lane); -- remap and pipeline the data bus
			end loop;

			if rst='1' then
				m_axis_tvalid<=(others=>'0');
			end if; -- rst
		end if; -- clk
	end process;

end Behavioral;
