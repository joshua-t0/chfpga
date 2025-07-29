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

-- Knight Rider's KIT2000-style LED blinker
entity blinker is
	generic (
		PING_PONG: boolean := FALSE;
		DUMMY: boolean     := FALSE
	);
	port (
		-- Reset line
		rst: in  std_logic;

		-- Clock
		clk: in  std_logic;
		kick: in std_logic := '0'; -- increases the blink speed when '1'
		leds: out std_logic_vector(7 downto 0); -- Ramp up and down pattern Intensity = (0,1,2,3,2,1,0,0,0...)
		leds_u: out std_logic_vector(7 downto 0); -- Ramp_up pattern        Intensity = (0,1,2,3,0,0,0,0,0...)
		leds_d: out std_logic_vector(7 downto 0) -- Ramp down parrern      Intensity = (0,0,0,3,2,1,0,0,0...)
	);
end entity blinker;

architecture impl of blinker is

	signal ctr: unsigned (31 downto 0) := (others => '0'); --

	signal lead: unsigned(0 to 7) := "10000000"; -- The bit that bounces around

	type trail_type is array(natural range <>) of unsigned(0 to 4);

	signal trail: trail_type(0 to 7); -- Memory of the passage of the bit so we can compute remanent intensity
	signal pwm_low_to_high: std_logic_vector(0 to 2); -- 3 levels of PWM
	signal pwm_high_to_low: std_logic_vector(0 to 2); -- 3 levels of PWM
	signal dir: std_logic := '1';
	signal trig: boolean;
	signal leds_u_int, leds_d_int: std_logic_vector(7 downto 0) := (others => '0');
	signal kick_pulse: std_logic;

begin


	leds   <= leds_u_int or leds_d_int;
	leds_u <= leds_u_int;
	leds_d <= leds_d_int;

	nodummy: if DUMMY = FALSE generate

		blinker: process(clk, kick) is
		begin
			if kick = '1' then
				kick_pulse <= '1';
			elsif rising_edge(clk) then
				if kick_pulse = '1' then
					kick_pulse <= '0';
				end if;
			end if;
			if rising_edge(clk) then
				ctr <= ctr + 1;
				-- Generate 3 signals with different PWM duty cycles
				-- We use the last 17 bits of ctr to determine the ON status so the PWM waveform is at a reasonable frequency
				-- bits 16:0 : duty cycle= 2^0 / 2^17 = 2^-17
				-- bits 16:1 : duty cycle= 2^1 / 2^17 = 2^-16
				-- bits 16:12 : duty cycle= 2^12 / 2^17 = 2^-5 = 1/32
				-- bits 16:15 : duty cycle= 2^15 / 2^17 = 2^-2 = 1/4
				pwm_low_to_high(0) <= and_reduce(std_logic_vector(ctr(16 downto 12)));  -- 1/32 duty cycle
				pwm_low_to_high(1) <= and_reduce(std_logic_vector(ctr(16 downto 15)));  -- 1/4 duty cycle
				pwm_low_to_high(2) <= '1'; -- 100% duty cycle
				pwm_high_to_low(0) <= pwm_low_to_high(2);
				pwm_high_to_low(1) <= pwm_low_to_high(1);
				pwm_high_to_low(2) <= pwm_low_to_high(0);

				if PING_PONG then
					if lead(0) = '1' then
						dir <= '1';
					elsif lead(7) = '1' then
						dir <= '0';
					end if;
				end if;

				-- trig <= ctr(22 downto 0)=0 or (ctr(20 downto 0)=0 and kick='1');
				trig <= ctr(22 downto 0) = 0 or kick_pulse = '1';

				if trig  then
					if dir = '1' then
						lead <= rotate_right(lead, 1);
					else
						lead <= rotate_left(lead, 1);
					end if;

					for i in 0 to 7 loop
						trail(i) <= shift_right(trail(i), 1);
						trail(i)(0) <= lead(i);
					end loop;

				end if; -- if trig

				for i in 0 to 7 loop
					leds_d_int(i) <= or_reduce(std_logic_vector(trail(i)(2 to 4)) and pwm_high_to_low);
					leds_u_int(i) <= or_reduce(std_logic_vector(trail(i)(0 to 2)) and pwm_low_to_high);
				end loop;

				-- synchronous resets. Overrides variables above.
				if rst = '1' then
					leds_d_int <= (others => '0');
					leds_u_int <= (others => '0');
					lead <= (0 => '1', others => '0');
					dir <= '1';
				end if; -- if rst
			end if; -- clk
		end process;

	end generate nodummy;

end architecture impl;

