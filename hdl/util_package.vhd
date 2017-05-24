----------------------------------------------------------------------------------
--! @file
-- Company: McGill University
-- Engineer: JF Cliche
-- 
-- Create Date:   2013-05-22 
-- Design Name:  None
-- Module Name:    Utility Package
-- Project Name: None
-- Target Devices: Kintex 7
-- Tool versions: Vivado 2013.1
-- Description: Provides additional generic types and functions commonly used in many designs
--
-- Dependencies: 
--
-- Revision: 
--  2013--06-02 JFC: Created
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.ALL;
use IEEE.math_real.all; -- needed for ceil()

-------- chFPGA Package ------------
--! @brief Defines the system-level constants and data types, declares the components used in the system, and provide support functions and procedures 
package util_package is


-- generic types and subtypes
subtype slv is std_logic_vector;
subtype slv2 is std_logic_vector(1 downto 0);
subtype slv3 is std_logic_vector(2 downto 0);
subtype slv4 is std_logic_vector(3 downto 0);
subtype slv8 is std_logic_vector(7 downto 0);
subtype slv16 is std_logic_vector(15 downto 0);
subtype slv32 is std_logic_vector(31 downto 0);
subtype slv48 is std_logic_vector(47 downto 0);
subtype slv64 is std_logic_vector(63 downto 0);
type ByteArray8 is array (0 to 7) of std_logic_vector(7 downto 0);
type ByteArray is array (NATURAL RANGE <>) of std_logic_vector(7 downto 0);
type slv2_array is array (NATURAL RANGE <>) of std_logic_vector(1 downto 0);
type slv4_array is array (NATURAL RANGE <>) of std_logic_vector(3 downto 0);
type slv8_array is array (NATURAL RANGE <>) of std_logic_vector(7 downto 0);
type slv16_array is array (NATURAL RANGE <>) of std_logic_vector(15 downto 0);
type slv32_array is array (NATURAL RANGE <>) of std_logic_vector(31 downto 0);
type slv48_array is array (NATURAL RANGE <>) of std_logic_vector(47 downto 0);
type slv64_array is array (NATURAL RANGE <>) of std_logic_vector(63 downto 0);
type IntegerArray is array (natural range <>) of INTEGER;
type INTEGER_ARRAY_TYPE is array (natural range <>) 	 of integer; --
subtype uint32 is unsigned(31 downto 0);

end util_package;

package body util_package is


end util_package;
