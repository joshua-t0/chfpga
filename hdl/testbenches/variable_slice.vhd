----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07/28/2025 03:29:44 PM
-- Design Name: 
-- Module Name: variable_slice - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity variable_slice is
    port (
        width: in std_logic_vector(1 downto 0);
        all_ones1: out std_logic;
        all_ones2: out std_logic;
        all_ones3: out std_logic;
        all_ones4: out std_logic
        );
end variable_slice;

architecture impl of variable_slice is
    signal value: std_logic_vector(3 downto 0) := "1100";
    signal test: std_logic_vector(3 downto 0) := "1111";
    
    function allbits(v:std_logic_vector; b:integer) return boolean is
        variable target: std_logic_vector(v'range) := (others =>'1'); -- size of vector needs to be resolved to a constant
    begin
        return v(v'HIGH downto b) = target(v'HIGH downto b); -- works
--        return v(v'HIGH downto b) = (v'HIGH downto b => '1'); -- synth error: needs to resolve to constant
    end function allbits;

begin
    -- Width, Expected value, actual value:
    -- "00": 0, 0
    -- "01": 0, 0
    -- "10": 1, 0 ERROR
    -- "11": 1, 0: ERROR
    all_ones1 <= '1' when signed(value(value'HIGH downto to_integer(unsigned(width))))=-1 else '0'; 
    all_ones2 <= '1' when value(value'HIGH downto to_integer(unsigned(width))) = test(test'HIGH downto to_integer(unsigned(width))) else '0'; 
    all_ones3 <= '1' when allbits(value, to_integer(unsigned(width))) else '0';

    process(all) 
        variable width_int: integer range 0 to 3;   
    begin
        width_int := to_integer(unsigned(width));
        all_ones4 <= '1' when signed(value(value'HIGH downto width_int))=-1 else '0'; 
        
    end process; 
--    test(value'HIGH downto to_integer(unsigned(width))) <= (others 
end impl;
