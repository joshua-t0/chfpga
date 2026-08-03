----------------------------------------------------------------------------------
-- Company: McGill University
-- Engineer: JF Cliche
--
-- Create Date:    01:13:55 03/14/2011
-- Design Name:
-- Module Name:    blinker - impl
-- Project Name:
-- Target Devices:
-- Tool versions:
-- Description: Generate PWM patterns to make leds blink in a nice way
-- Dependencies:
--
-- Revision:
-- 110314 JFC: Created from the top_all.vhd code during major code cleanup

-- Additional Comments:
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_MISC.ALL;

use IEEE.NUMERIC_STD.ALL;

use work.chfpga_package.ALL;

-- Knight Rider's KIT2000-style LED blinker
entity blinker is
	generic (
		PING_PONG: boolean := FALSE; -- if true, the lead bit will bounce back and forth between the two ends of the array
		DUMMY: boolean     := FALSE; -- if true, the blinker will be disabled
		STYLE: integer     := 3
		-- 0: raw one-hot lead; 1: ramp-up PWM trail; 2: ramp-down PWM trail; 3: ramp up then down (classic)
	);
	port (
		-- Reset and clock

		rst: in  std_logic; -- reset signal, synchronous to clk
		clk: in  std_logic;

		-- Blinker control

		kick: in std_logic := '0'; -- increases the blink speed when '1'. Pulse.

		-- LED outputs (muxed by STYLE)

		leds: out std_logic_vector(0 to 7)
	);
end entity blinker;

architecture impl of blinker is

	signal ctr: unsigned (31 downto 0) := (others => '0'); --

	signal lead: std_logic_vector(0 to 7) := "10000000"; -- The bit that bounces around

	signal trail: slv_array(0 to 7)(0 to 4); -- Memory of the passage of the bit so we can compute remanent intensity
	signal pwm_levels: std_logic_vector(0 to 4); -- 5 duty cycles: 1/32, 1/4, 1, 1/4, 1/32
	signal dir: std_logic := '1';
	signal trig: boolean;
	signal kick_pulse: std_logic;

begin

	gen: if DUMMY generate

		leds   <= (others => '0');

	else generate

		process(all) begin
			if kick then
				kick_pulse <= '1';
			elsif rising_edge(clk) then
				if kick_pulse then
					kick_pulse <= '0';
				end if;

				ctr <= ctr + 1;
				-- Generate 3 signals with different PWM duty cycles
				-- We use the last 17 bits of ctr to determine the ON status so the PWM waveform is at a reasonable frequency
				-- bits 16:0 : duty cycle= 2^0 / 2^17 = 2^-17
				-- bits 16:1 : duty cycle= 2^1 / 2^17 = 2^-16
				-- bits 16:12 : duty cycle= 2^12 / 2^17 = 2^-5 = 1/32
				-- bits 16:15 : duty cycle= 2^15 / 2^17 = 2^-2 = 1/4
				pwm_levels(0) <= and(std_logic_vector(ctr(16 downto 12)));  -- 1/32 duty cycle
				pwm_levels(1) <= and(std_logic_vector(ctr(16 downto 15)));  -- 1/4 duty cycle
				pwm_levels(2) <= '1'; -- 100% duty cycle
				pwm_levels(3) <= pwm_levels(1); -- 1/4 duty cycle
				pwm_levels(4) <= pwm_levels(0); -- 1/32 duty cycle

				if PING_PONG then
					dir <= '1' when lead(0) = '1' else '0' when lead(7) = '1';
				end if;

				-- trig <= ctr(22 downto 0)=0 or (ctr(20 downto 0)=0 and kick='1');
				trig <= ctr(22 downto 0) = 0 or kick_pulse = '1';

				if trig then
					lead <= lead ror  1 when dir else lead rol 1;

					for i in 0 to 7 loop
						trail(i) <= shift_right(trail(i), 1, insert => lead(i));
					end loop;

				end if; -- if trig

				for i in 0 to 7 loop
					leds(i) <=	lead(i) when STYLE = 0 else -- one-hot
						or(trail(i)(0 to 2) and pwm_levels(0 to 2)) when STYLE = 1 else -- ramp-up PWM trail
						or(trail(i)(2 to 4) and pwm_levels(2 to 4)) when STYLE = 2 else -- ramp-down PWM trail
						or(trail(i) and pwm_levels); -- ramp up then down
				end loop;

				-- synchronous resets. Overrides variables above.
				if rst then
					leds <= (others => '0');
					lead <= (0 => '1', others => '0');
					dir <= '1';
				end if; -- if rst
			end if; -- clk
		end process;

	end generate gen;


end architecture impl;
