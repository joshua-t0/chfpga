--------------------------------------------------------------------------------
-- Testbench for entity blinker (PWM / Knight Rider style LED patterns).
-- Drives reset, clock, and periodic kick pulses so the pattern advances without
-- waiting for ctr(22 downto 0) wrap (~8M clock cycles).
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library std;
use std.env.all;

entity blinker_testbench is
end entity blinker_testbench;

architecture sim of blinker_testbench is

	constant CLK_PERIOD : time := 10 ns;

	signal clk  : std_logic := '0';
	signal rst  : std_logic := '1';
	signal kick : std_logic := '0';

	signal leds : std_logic_vector(7 downto 0);

begin

	clk <= not clk after CLK_PERIOD / 2;

	uut : entity work.blinker
		generic map (
			PING_PONG => FALSE,
			DUMMY     => FALSE
		)
		port map (
			rst  => rst,
			clk  => clk,
			kick => kick,
			leds => leds
		);

	stim : process is
	begin
		kick <= '0';
		rst  <= '1';
		wait for CLK_PERIOD * 10;
		rst  <= '0';
		wait for CLK_PERIOD * 20;

		-- Advance pattern with kick; much faster than natural trig from ctr wrap.
		for i in 1 to 400 loop
			wait until rising_edge(clk);
			kick <= '1';
			wait until rising_edge(clk);
			kick <= '0';
			for j in 1 to 49 loop
				wait until rising_edge(clk);
			end loop;
		end loop;

		report "blinker_testbench: finished kick-driven stimulus" severity note;
		finish(0);
	end process stim;

end architecture sim;
