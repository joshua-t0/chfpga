----------------------------------------------------------------------------------
--! @file
-- Company: McGill University
-- Engineer: JF Cliche & Graeme Smecher
--
-- Create Date:   2013-05-22
-- Design Name:  Icecore
-- Module Name:    Package
-- Project Name: icecore
-- Tool versions: Vivado 2014.4
-- Description: Implements common icecore variables and types
----------------------------------------------------------------------------------

library IEEE;
use IEEE.math_real.all; -- needed for ceil()
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.ALL;

package icecore_package is

	type irigb is record
		s,m : unsigned(6 downto 0);
		h : unsigned(5 downto 0);
		d : unsigned(8 downto 0);
		y : unsigned(7 downto 0);
		c : std_logic_vector(17 downto 0);
		sbs : std_logic_vector(17 downto 0);  -- straight binary seconds
		ss : unsigned(27 downto 0); -- 100 MHz (10 ns) ticks, saturating
		recent : std_logic;
		source : unsigned(2 downto 0);
	end record;

	-- generic types and subtypes
	type SLV8_ARRAY_TYPE is array (NATURAL RANGE <>) of std_logic_vector(7 downto 0);
	type SLV16_ARRAY_TYPE is array (NATURAL RANGE <>) of std_logic_vector(15 downto 0);
	type SLV32_ARRAY_TYPE is array (NATURAL RANGE <>) of std_logic_vector(31 downto 0);
	subtype slv32 is std_logic_vector(31 downto 0);
	type slv32_array is array (NATURAL RANGE <>) of std_logic_vector(31 downto 0);

	type U16_ARRAY_TYPE is array(integer range <>) of unsigned(15 downto 0);
	type U32_ARRAY_TYPE is array(integer range <>) of unsigned(31 downto 0);

	type INTEGER_ARRAY_TYPE is array (natural range <>) of integer;

	function to_std_logic(i:boolean) return std_logic; -- converts bool to std_logic
	function width(len: integer) return integer; --! computes the number of bits needed to represent a number from 0 to len-1

end icecore_package;

package body icecore_package is

	FUNCTION to_std_logic(i:boolean) return std_logic is -- converts bool to std_logic
		begin
			if i then
				return '1';
			else
				return '0';
			end if;
		end to_std_logic;


--! Compute the number of bits needed to represent `len` values (from 0 to len-1)
function width(len: integer) return integer is
	begin
		return integer(ceil(log2(real(len))));
	end function;

end icecore_package;
