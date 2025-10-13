--------------------------------------------------------------------------------
-- Company: McGill University
-- Engineer:J.-F. Cliche
--
-- Create Date: 2025-03
-- Design Name: scaler_mul_testbench
-- Project Name: chFPGA
-- Target Device: 7-Series, Ultrascale+
-- Tool versions: Vivado 2022.2
-- Programming language: VHDL 2008
-- Description:
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE std.env.finish;

use std.textio.all;

library work;
USE work.chfpga_package.all;
use work.tb_package.all;

ENTITY scaler_mul_testbench IS
    generic (
        A_WIDTH : integer := 8;
        B_WIDTH : integer := 8
        );
END scaler_mul_testbench;


ARCHITECTURE behavior OF scaler_mul_testbench IS

   -- Clock period definitions

    constant CLK_PERIOD : time := 2 ns; -- 500 MHz

    constant P_WIDTH : integer := A_WIDTH+B_WIDTH;

	signal reset : std_logic := '0';
	signal clk: std_logic; --

    signal v, v1, v2, v3: std_logic := '0';
    signal a, a1, a2, a3: signed(A_WIDTH-1 downto 0);
    signal b, b1, b2, b3: unsigned(B_WIDTH-1 downto 0);
    signal p_int: std_logic_vector(P_WIDTH-1 downto 0);
    signal p, p1, p2, p3: signed(P_WIDTH-1 downto 0);

    function test_pattern(WIDTH:integer; seq:integer) return std_logic_vector is
        variable r: std_logic_vector(WIDTH-1 downto 0);
    begin
        if seq<WIDTH then
            r := (seq => '1', others => '0');
        elsif seq < 2*WIDTH then
            r := (seq-WIDTH downto 0 => '1', others =>'0');
        elsif seq < 3*WIDTH then
            r := (WIDTH-1 downto WIDTH-1-(seq-2*WIDTH)=> '1', others =>'0');
        else
            r := (others => '0');
        end if;
        return r;
    end function;


    signal a_values: signed_array(0 to 4)(A_WIDTH-1 downto 0) := (
        (others =>'0'),
        (others => '1'),
        (0 => '1', others => '0'),
        (A_WIDTH-1 => '1', others=>'0'),
        (A_WIDTH-1 => '0', others=>'1')
        );
    signal b_values: integer_array(0 to 8) := (0, 1, 100, 17000, 27812, 32767, 32768, 40000, 65535);

begin


p <= signed(p_int);

dut0: entity work.scaler_mul
    generic map (
        A_WIDTH=> A_WIDTH,
        B_WIDTH=> B_WIDTH
  )
	port map (

        a => std_logic_vector(a),
        b => std_logic_vector(b),
        p => p_int,
		clk => clk
	);


clk_process :process
   begin
		clk <= '0';
		wait for CLK_PERIOD/2;
		clk <= '1';
		wait for CLK_PERIOD/2;
   end process;
reset_proc: process begin
		reset <= '1';
		sleep(clk, 2);
		reset <= '0';
        wait;
end process;

stim_proc : process begin
    for i in 0 to 3 * A_WIDTH  loop
        for j in 0 to 3 * B_WIDTH loop
            a <= signed(test_pattern(A_WIDTH, i));
            b <= unsigned(test_pattern(B_WIDTH, j));
            v <= '1';
            sleep(clk);
        end loop;
    end loop;
    v <= '0';
    sleep(clk,10);
    finish;
end process ; -- lane0_proc

check_proc: process(clk)
    variable a_var: signed(A_WIDTH-1 downto 0);
    variable b_var: unsigned(B_WIDTH-1 downto 0);
    variable prod, p_var : signed(P_WIDTH downto 0); -- add one bit to
    variable buf: line;

begin
    if rising_edge(clk) then
        v1 <= v; v2 <= v1; v3 <= v2;
        a1 <= a; a2 <= a1; a3 <= a2;
        b1 <= b; b2 <= b1; b3 <= b2;

        if v3='1' then
            a_var := a3;
            b_var := b3;
            prod := a3 * signed(resize(b3,b3'LENGTH+1));
            p_var :=  resize(p, prod'LENGTH);
            write(buf, to_string(a_var) & " * " & to_string(b_var) &  " = " & to_hstring(p_var) & " Expected " & to_hstring(prod));
            if p_var=prod then
                write(buf, string'(" OK"));
            else
                write(buf, string'(" ERROR!"));
            end if;

                writeline(output, buf);
            assert p_var=prod report "Bad product!" SEVERITY FAILURE;
        end if; -- valid
    end if; -- clk
end process;
END;
