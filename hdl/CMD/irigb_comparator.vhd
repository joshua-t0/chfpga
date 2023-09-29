library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.icecore_package.irigb;

entity irigb_comparator is
	port (
		current_ts: in irigb;
		target_ts: in irigb;
		compare_en: in std_logic;
		force_sync: in std_logic;

		before_target: out std_logic; -- Is '1' when current time is before the target time, and '0' when it is equal of after. There is 7 clocks latency compared to current time input.

		clk_200mhz	: in std_logic
	);
end irigb_comparator;

architecture behav of irigb_comparator is

	attribute async_reg : string;
	attribute shreg_extract : string;


	signal target_ts_sync1: irigb;
	signal target_ts_sync2: irigb;
	attribute async_reg of target_ts_sync1, target_ts_sync2 : signal is "true";

	-- Timestamp comparator
	signal compare_en_sync1, compare_en_sync2 : std_logic := '0';
	attribute async_reg of compare_en_sync1, compare_en_sync2 : signal is "true";

	signal y_gt, y_eq, d_gt, d_eq, h_gt, h_eq, m_gt, m_eq, s_gt, s_eq, ss_gt, ss_eq : boolean := FALSE;

	signal before_target_pre3: std_logic := '0';
	signal before_target_pre2: std_logic := '0';
	signal before_target_pre1: std_logic := '0';
	attribute shreg_extract of before_target_pre3, before_target_pre2, before_target_pre1 : signal is "no";

	signal force_sync1, force_sync2 : std_logic := '0';
	attribute async_reg of force_sync1, force_sync2 : signal is "true";

begin

	timestamp_comparator_proc : process(clk_200mhz)
	begin
		if rising_edge(clk_200mhz) then

			-- Resynchronize the compare enable signal to the 200 MHz clock
			compare_en_sync1 <= compare_en;
			compare_en_sync2 <= compare_en_sync1;

			-- Resynchronize the force signal to the 200 MHz clock
			force_sync1 <= force_sync;
			force_sync2 <= force_sync1;

			-- Resynchronize the target timestamp to the 200 MHz clock
			target_ts_sync1 <= target_ts;
			target_ts_sync2 <= target_ts_sync1;

			-- Timestamp comparison involves great honking big
			-- vectors, which we're doing a combination of
			-- equality testing and greater-than/less-than
			-- matching. Try some pipelining in the hopes it's
			-- less onerous.
			y_gt <= target_ts_sync2.y > current_ts.y;
			y_eq <= target_ts_sync2.y = current_ts.y;

			d_gt <= target_ts_sync2.d > current_ts.d;
			d_eq <= target_ts_sync2.d = current_ts.d;

			h_gt <= target_ts_sync2.h > current_ts.h;
			h_eq <= target_ts_sync2.h = current_ts.h;

			m_gt <= target_ts_sync2.m > current_ts.m;
			m_eq <= target_ts_sync2.m = current_ts.m;

			s_gt <= target_ts_sync2.s > current_ts.s;
			s_eq <= target_ts_sync2.s = current_ts.s;

			ss_gt <= target_ts_sync2.ss > current_ts.ss;
			-- ss_eq <= target_ts_sync2.ss = tcurrent_s.ss;

			-- Hold 'before_target' at '1' as long as target time > current time.
			-- Falls back to zero when current time is equal or exceeds target time.
			before_target_pre3 <= '0';
			if current_ts.recent='1' and (
					(y_gt) or
					(y_eq and d_gt) or
					(y_eq and d_eq and h_gt) or
					(y_eq and d_eq and h_eq and m_gt) or
					(y_eq and d_eq and h_eq and m_eq and s_gt) or
					(y_eq and d_eq and h_eq and m_eq and s_eq and ss_gt)) then
				before_target_pre3 <= '1';
			end if;

			before_target_pre2 <= (before_target_pre3 and compare_en_sync2) or force_sync2;
			before_target_pre1 <= before_target_pre2;
			before_target <= before_target_pre1;
		end if;
	end process;

end behav;
