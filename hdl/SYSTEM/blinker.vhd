----------------------------------------------------------------------------------
-- Company: McGill University
-- Engineer: JF Cliche
--
-- Create Date:    01:13:55 03/14/2011
-- Design Name:
-- Module Name:    blinker - Behavioral
-- Project Name:
-- Target Devices:
-- Tool versions:
-- Description: Generate PWM patterns to make LEDs blink in a nice way
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
	GENERIC (
		PING_PONG: boolean := FALSE;
		DUMMY: BOOLEAN:=FALSE
		);
   PORT (
		-- Reset line
		RST: in  STD_LOGIC;

		-- Clock
		CLK: in  STD_LOGIC;
		KICK: in std_logic:='0'; --! increases the blink speed when '1'
		LEDS: out STD_LOGIC_VECTOR(7 downto 0); --! Ramp up and down pattern Intensity = (0,1,2,3,2,1,0,0,0...)
		LEDS_U: out STD_LOGIC_VECTOR(7 downto 0); --! Ramp_up pattern        Intensity = (0,1,2,3,0,0,0,0,0...)
		LEDS_D: out STD_LOGIC_VECTOR(7 downto 0) --! Ramp down parrern      Intensity = (0,0,0,3,2,1,0,0,0...)
		);

end blinker;

architecture Behavioral of blinker is

signal CTR: unsigned (31 downto 0):=(others=>'0'); --


signal LEAD: unsigned(0 to 7) := "10000000"; -- The bit that bounces around
type TRAIL_TYPE is array(natural range <>) of unsigned(0 to 4);
signal TRAIL: TRAIL_TYPE(0 to 7) ; -- Memory of the passage of the bit so we can compute remanent intensity
signal PWM_LOW_TO_HIGH: std_logic_vector(0 to 2); -- 3 levels of PWM
signal PWM_HIGH_TO_LOW: std_logic_vector(0 to 2); -- 3 levels of PWM
signal DIR: STD_LOGIC:='1';
signal TRIG: boolean;
signal LEDS_U_INT, LEDS_D_INT: std_logic_vector(7 downto 0);
signal kick_pulse: std_logic;

begin


LEDS <= LEDS_U_INT or LEDS_D_INT;
LEDS_U <= LEDS_U_INT;
LEDS_D <= LEDS_D_INT;

NODUMMY: if DUMMY=FALSE generate


blinker : process(CLK, kick)
	begin
		if kick='1' then
			kick_pulse <= '1';
		elsif rising_edge(clk) then
			if kick_pulse='1' then
				kick_pulse <='0';
			end if;
		end if;


		if rising_edge(CLK) then
			if RST='1' then
				LEDS_D_INT <= (others=>'0');
				LEDS_U_INT <= (others=>'0');
				LEAD <= (0=>'1', others=>'0');
				DIR <= '1';
			else
				CTR <= CTR + 1;
				-- Generate 3 signals with different PWM duty cycles
				-- We use the last 17 bits of CTR to determine the ON status so the PWM waveform is at a reasonable frequency
				-- bits 16:0 : duty cycle= 2^0 / 2^17 = 2^-17
				-- bits 16:1 : duty cycle= 2^1 / 2^17 = 2^-16
				-- bits 16:12 : duty cycle= 2^12 / 2^17 = 2^-5 = 1/32
				-- bits 16:15 : duty cycle= 2^15 / 2^17 = 2^-2 = 1/4
				PWM_LOW_TO_HIGH(0) <= and_reduce(std_logic_vector(CTR(16 downto 12)));  -- 1/32 duty cycle
				PWM_LOW_TO_HIGH(1) <= and_reduce(std_logic_vector(CTR(16 downto 15)));  -- 1/4 duty cycle
				PWM_LOW_TO_HIGH(2) <= '1'; -- 100% duty cycle
				PWM_HIGH_TO_LOW(0) <= PWM_LOW_TO_HIGH(2);
				PWM_HIGH_TO_LOW(1) <= PWM_LOW_TO_HIGH(1);
				PWM_HIGH_TO_LOW(2) <= PWM_LOW_TO_HIGH(0);

				if PING_PONG then
					if(LEAD(0)='1') then
						DIR<='1';
					elsif(LEAD(7)='1') then
						DIR<='0';
					end if;
				end if;

				-- TRIG <= CTR(22 downto 0)=0 or (CTR(20 downto 0)=0 and KICK='1');
				TRIG <= CTR(22 downto 0)=0 or kick_pulse='1';

				if TRIG  then
					if DIR='1' then
						LEAD <= rotate_right(LEAD, 1);
					else
						LEAD <= rotate_left(LEAD, 1);
					end if;

					for i in 0 to 7 loop
						TRAIL(i) <= shift_right(TRAIL(i), 1);
						TRAIL(i)(0) <= LEAD(i);
					end loop;
				end if; -- if TRIG

				for i in 0 to 7 loop
					LEDS_D_INT(i) <= or_reduce(std_logic_vector(TRAIL(i)(2 to 4)) and PWM_HIGH_TO_LOW);
					LEDS_U_INT(i) <= or_reduce(std_logic_vector(TRAIL(i)(0 to 2)) and PWM_LOW_TO_HIGH);
				end loop;
			end if; -- if RST
		end if; -- CLK
	end process;

--	in_eth(7 downto 0)<=STD_LOGIC_VECTOR(tx_byte); -- combinatorial assignment -- debug

end generate;

ISDUMMY: if DUMMY=TRUE generate
		LEDS_D_INT<=(others=>'0');
		LEDS_U_INT<=(others=>'0');
end generate;


end Behavioral;

