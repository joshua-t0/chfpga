library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use IEEE.NUMERIC_STD.ALL;
use work.chFPGA_Package.ALL;

entity lfsr is
	generic (
		DATA_WIDTH: integer      := 112;
		TAPS: integer_array      := (32, 30, 26, 25); -- indices are 1 based indexing from lfsr polynomial table
		SHIFT_REG_WIDTH: integer := max(TAPS)
	);
	port (
		seed: in std_logic_vector(0 to SHIFT_REG_WIDTH - 1);
		output: out std_logic_vector(DATA_WIDTH - 1 downto 0);
		rst: in std_logic;
		clk: in std_logic
	);
end entity lfsr;

architecture impl of lfsr is

	signal a_reg: std_logic_vector(0 to SHIFT_REG_WIDTH - 1) := (others => '0');

begin

	myprocess: process(all)

		variable xorres: std_logic;
		variable a_reg_var: std_logic_vector(0 to SHIFT_REG_WIDTH - 1) := (others => '0');

	begin
		if rising_edge(clk) then
			a_reg_var := a_reg;
			for i in 0 to DATA_WIDTH - 1 loop
				xorres := '0';
				for j in 0 to TAPS'LENGTH - 1 loop
					xorres := xorres xor a_reg_var(TAPS(j) - 1);
				end loop;

				a_reg_var := xorres & a_reg_var(0 to SHIFT_REG_WIDTH - 2);
				output(i) <= a_reg_var(SHIFT_REG_WIDTH - 1);
			end loop;

			a_reg <= a_reg_var;
			if rst then
				output <= (others => '0');
				a_reg <= seed;
			end if; -- reset
		end if; -- clk
	end process;

end architecture impl;
