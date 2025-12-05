----------------------------------------------------------------------------------
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
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.ALL;

package irigb_package is

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
	type slv32_array is array (NATURAL RANGE <>) of std_logic_vector(31 downto 0);

end irigb_package;

package body irigb_package is

end irigb_package;

