library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.chFPGA_package.all; -- get platform-specific configurations

library UNISIM;
use UNISIM.VComponents.all;

entity SCALER_MUL is
	generic (
		A_WIDTH: integer := 16; -- should be smaller than 18
		B_WIDTH: integer := 32;
		P_WIDTH: integer := A_WIDTH + B_WIDTH -- should be >= A_WIDTH + B_WIDTH
		);
   port (
		a : in  signed(A_WIDTH-1 downto 0);
		b : in  signed(B_WIDTH-1 downto 0);
		p : out  signed(P_WIDTH-1 downto 0);
		clk : in  std_logic;
		rst : in  std_logic
		);

end SCALER_MUL;

architecture impl of SCALER_MUL is
    
    signal a1: signed(A_WIDTH-1 downto 0);
    signal b1: signed(B_WIDTH-1 downto 0);
    
    constant B_WIDTH_MAX: integer := 18; -- use  2 multipliers if B_WIDTH > B_WIDTH_MAX
    constant IM1_WIDTH:integer := B_WIDTH_MAX + A_WIDTH + 1; -- b1 unsigned slice has a extra guard bit to make it signed
    constant IM2_WIDTH: integer := B_WIDTH - B_WIDTH_MAX + A_WIDTH;
    signal im1: signed(IM1_WIDTH-1 downto 0);
    signal im2: signed(IM2_WIDTH-1 downto 0);
    
begin

mul_proc: process(clk)
    begin
        if rising_edge(clk) then
            a1 <= a;
            b1 <= b;
    
            if B_WIDTH <= B_WIDTH_MAX then
                p <= resize(a1 * b1, P_WIDTH);
            else
                im1 <= a1 * signed(resize(unsigned(b1(B_WIDTH_MAX-1 downto 0)), B_WIDTH_MAX + 1));
                im2 <= a1 * b1(B_WIDTH-1 downto B_WIDTH_MAX);
                p <= shift_left(resize(im2, P_WIDTH), B_WIDTH_MAX) + im1;
            end if;
        end if; --clk
    end process;
    
end architecture impl;
