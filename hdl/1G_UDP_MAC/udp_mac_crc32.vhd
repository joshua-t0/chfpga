----------------------------------------------------------------------------------
-- Company: McGill University
-- Engineer: JF Cliche
--
-- Create Date:    03:38:16 01/04/2011
-- Design Name:
-- Module Name:    udp_mac_crc32 - Behavioral
-- Project Name:
-- Target Devices:
-- Tool versions:
-- Description:
--   Ethernet udp_mac_crc32 computation module based on the Verilog code provided with the Xilinx SP605 Eval board
--

--

-- Dependencies:
--
-- Revision:
-- 110104 JFC: File Created from verilog code

-- Additional Comments:
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity udp_mac_crc32 is
	port (
		CRC_REG: out STD_LOGIC_VECTOR(31 downto 0);
		CRC: out STD_LOGIC_VECTOR(7 downto 0);
		D: in STD_LOGIC_VECTOR(7 downto 0);
		CALC: in STD_LOGIC;
		INIT: in STD_LOGIC;
		D_VALID: in STD_LOGIC;
		CLK: in STD_LOGIC;
		RESET: in STD_LOGIC
		);

end udp_mac_crc32;

architecture Behavioral of udp_mac_crc32 is

	signal CRC_REG_INT, NEXT_CRC: STD_LOGIC_VECTOR(31 downto 0);

begin

CRC_REG <= CRC_REG_INT;

main: process(all) begin
		if (clk'EVENT and clk='1') then

			if (RESET or INIT) then
					CRC_REG_INT <= X"FFFFFFFF";
					CRC<= X"FF";
			elsif (CALC and D_VALID) then
				CRC_REG_INT <= NEXT_CRC;
				CRC     <= not (next_crc(24) & next_crc(25) & next_crc(26) & next_crc(27) & next_crc(28) & next_crc(29) & next_crc(30) & next_crc(31));
			elsif (not CALC and D_VALID) then
				  CRC_REG_INT <=  (CRC_REG_INT(23 downto 0) & X"FF");
				  CRC     <= not (CRC_REG_INT(16) & CRC_REG_INT(17) & CRC_REG_INT(18) & CRC_REG_INT(19) & CRC_REG_INT(20) & CRC_REG_INT (21) &  CRC_REG_INT(22) & CRC_REG_INT(23));
			end if;
		end if; -- CLK
	end process;

 next_crc(0) <= CRC_REG_INT(30) xor d(1) xor CRC_REG_INT(24) xor d(7);
 next_crc(1) <= d(6) xor d(7) xor d(0) xor CRC_REG_INT(30) xor CRC_REG_INT(31) xor d(1) xor CRC_REG_INT(24) xor CRC_REG_INT(25);
 next_crc(2) <= CRC_REG_INT(26) xor d(5) xor d(6) xor d(7) xor CRC_REG_INT(30) xor d(0) xor d(1) xor CRC_REG_INT(31) xor CRC_REG_INT(24) xor CRC_REG_INT(25);
 next_crc(3) <= d(4) xor CRC_REG_INT(26) xor d(5) xor CRC_REG_INT(27) xor d(6) xor d(0) xor CRC_REG_INT(31) xor CRC_REG_INT(25);
 next_crc(4) <= d(4) xor CRC_REG_INT(26) xor d(5) xor CRC_REG_INT(27) xor CRC_REG_INT(28) xor d(7) xor CRC_REG_INT(30) xor d(1) xor CRC_REG_INT(24) xor d(3);
 next_crc(5) <= d(4) xor CRC_REG_INT(27) xor d(6) xor CRC_REG_INT(28) xor d(7) xor CRC_REG_INT(29) xor CRC_REG_INT(30) xor d(0) xor d(1) xor CRC_REG_INT(31) xor d(2) xor CRC_REG_INT(24) xor d(3) xor CRC_REG_INT(25);
 next_crc(6) <= CRC_REG_INT(26) xor d(5) xor d(6) xor CRC_REG_INT(28) xor CRC_REG_INT(29) xor d(0) xor CRC_REG_INT(30) xor CRC_REG_INT(31) xor d(1) xor d(2) xor d(3) xor CRC_REG_INT(25);
 next_crc(7) <= d(4) xor CRC_REG_INT(26) xor d(5) xor CRC_REG_INT(27) xor d(7) xor CRC_REG_INT(29) xor d(0) xor CRC_REG_INT(31) xor d(2) xor CRC_REG_INT(24);
 next_crc(8) <= d(4) xor CRC_REG_INT(27) xor d(6) xor CRC_REG_INT(28) xor d(7) xor CRC_REG_INT(24) xor CRC_REG_INT(0) xor d(3) xor CRC_REG_INT(25);
 next_crc(9) <= CRC_REG_INT(26) xor d(5) xor d(6) xor CRC_REG_INT(28) xor CRC_REG_INT(29) xor d(2) xor d(3) xor CRC_REG_INT(25) xor CRC_REG_INT(1);
 next_crc(10) <= d(4) xor CRC_REG_INT(26) xor CRC_REG_INT(2) xor d(5) xor CRC_REG_INT(27) xor d(7) xor CRC_REG_INT(29) xor d(2) xor CRC_REG_INT(24);
 next_crc(11) <= d(4) xor CRC_REG_INT(27) xor d(6) xor CRC_REG_INT(3) xor CRC_REG_INT(28) xor d(7) xor CRC_REG_INT(24) xor d(3) xor CRC_REG_INT(25);
 next_crc(12) <= CRC_REG_INT(26) xor d(5) xor d(6) xor CRC_REG_INT(28) xor d(7) xor CRC_REG_INT(4) xor CRC_REG_INT(29) xor CRC_REG_INT(30) xor d(1) xor d(2) xor CRC_REG_INT(24) xor d(3) xor CRC_REG_INT(25);
 next_crc(13) <= d(4) xor CRC_REG_INT(26) xor d(5) xor CRC_REG_INT(27) xor d(6) xor CRC_REG_INT(29) xor d(0) xor CRC_REG_INT(30) xor CRC_REG_INT(5) xor CRC_REG_INT(31) xor d(1) xor d(2) xor CRC_REG_INT(25);
 next_crc(14) <= d(4) xor CRC_REG_INT(26) xor d(5) xor CRC_REG_INT(27) xor CRC_REG_INT(28) xor CRC_REG_INT(30) xor d(0) xor d(1) xor CRC_REG_INT(31) xor CRC_REG_INT(6) xor d(3);
 next_crc(15) <= d(4) xor CRC_REG_INT(27) xor CRC_REG_INT(28) xor CRC_REG_INT(29) xor d(0) xor CRC_REG_INT(31) xor d(2) xor CRC_REG_INT(7) xor d(3);
 next_crc(16) <= CRC_REG_INT(28) xor d(7) xor CRC_REG_INT(29) xor d(2) xor CRC_REG_INT(24) xor d(3) xor CRC_REG_INT(8);
 next_crc(17) <= CRC_REG_INT(9) xor d(6) xor CRC_REG_INT(29) xor CRC_REG_INT(30) xor d(1) xor d(2) xor CRC_REG_INT(25);
 next_crc(18) <= CRC_REG_INT(26) xor d(5) xor CRC_REG_INT(10) xor CRC_REG_INT(30) xor d(0) xor d(1) xor CRC_REG_INT(31);
 next_crc(19) <= d(4) xor CRC_REG_INT(27) xor CRC_REG_INT(11) xor d(0) xor CRC_REG_INT(31);
 next_crc(20) <= CRC_REG_INT(28) xor CRC_REG_INT(12) xor d(3);
 next_crc(21) <= CRC_REG_INT(29) xor CRC_REG_INT(13) xor d(2);
 next_crc(22) <= d(7) xor CRC_REG_INT(14) xor CRC_REG_INT(24);
 next_crc(23) <= d(6) xor d(7) xor CRC_REG_INT(30) xor d(1) xor CRC_REG_INT(15) xor CRC_REG_INT(24) xor CRC_REG_INT(25);
 next_crc(24) <= CRC_REG_INT(26) xor d(5) xor d(6) xor d(0) xor CRC_REG_INT(31) xor CRC_REG_INT(16) xor CRC_REG_INT(25);
 next_crc(25) <= d(4) xor CRC_REG_INT(17) xor CRC_REG_INT(26) xor d(5) xor CRC_REG_INT(27);
 next_crc(26) <= d(4) xor CRC_REG_INT(18) xor CRC_REG_INT(27) xor CRC_REG_INT(28) xor d(7) xor CRC_REG_INT(30) xor d(1) xor CRC_REG_INT(24) xor d(3);
 next_crc(27) <= d(6) xor CRC_REG_INT(19) xor CRC_REG_INT(28) xor CRC_REG_INT(29) xor d(0) xor CRC_REG_INT(31) xor d(2) xor d(3) xor CRC_REG_INT(25);
 next_crc(28) <= CRC_REG_INT(26) xor d(5) xor CRC_REG_INT(20) xor CRC_REG_INT(29) xor CRC_REG_INT(30) xor d(1) xor d(2);
 next_crc(29) <= d(4) xor CRC_REG_INT(27) xor CRC_REG_INT(21) xor CRC_REG_INT(30) xor d(0) xor d(1) xor CRC_REG_INT(31);
 next_crc(30) <= CRC_REG_INT(28) xor d(0) xor CRC_REG_INT(22) xor CRC_REG_INT(31) xor d(3);
 next_crc(31) <= CRC_REG_INT(29) xor CRC_REG_INT(23) xor d(2);

end Behavioral;

