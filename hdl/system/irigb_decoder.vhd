library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.irigb_package.irigb;

-- IRIG-B time decoder
--
-- This entity decodes IRIG-B time and places it in the `ts` data structure at the end of each
-- second. The occcurence of the start bit is detected only at the end of the bit, therefore
-- delaying the decoding my an additional 10 ms. The `ts` structure therefore always shows the time
-- 1.010 seconds later that the real time (excluding all registering delays on the IRIG-B signal,
-- decoding logic, an final `ts` registering).
--
-- The `ts` structure contains a subsecond (ss) field that is not sampled on each second but rather
-- continuously counts time within the current second with a 200 MHz clock (5 ns). The counter is
-- reset at the beginning of each frame. All but the last bit of the counter make up the ``ss``
-- subsecond field, which can therefore be use to interpolate time within the second with a
-- resolution of 10 ns.
--
-- A IRIG-B consists of 100 bits, each of which is 10 ms long. Each frame lasts exactly 1 second.
-- The IRIG-B signal goes high at the beginning of each bit, and the type of bit is determined by
-- when it goes down after the beginning of the bit:
--
--    - "0", if IRIG-B goes down after 2 ms (low period < 8 ms)
--    - "1", if IRIG-B goes down after 5 ms (low period < 5 ms)
--    - marker (or P symbol) if IRIG-B goes down after 8 ms (low period < 2 ms)
--
-- The second marker in a series of two consecutive marker bits indcates the beginning of a frame.
-- The leading edge of that marker is the beginning of the second that is encoded in the frame.
--
-- We capture the hours, minutes, seconds etc. into separate signals as the frame bits are coming
-- in. Those fields are reistered  into the `ts` structure on the beginning of the next frame.
--
entity irigb_decoder is port (
	clk_200mhz : in std_logic; -- 200 MHz clock, used to sample and decode the IRIGB signal and interpolate time between seconds
	irig : in std_logic_vector(0 to 7); -- IRIG-B sources, one of which is selected by the index in `source`
	source : in unsigned(2 downto 0); -- Selects which IRIG-B source to use
    pol : in std_logic; -- IRIG-B signal polarity: 0= normal, 1=inverted
	pps: out std_logic; -- Pulsed high for 0.5s at the eginning of each new IRIG-B frame
	ts : out irigb -- structure containing the decoded time contained in the previous IRIG-B frame
);
end irigb_decoder;

architecture rtl of irigb_decoder is

	signal irig_dly1, irig_dly2 : std_logic := '0';
	signal symbol_counter : unsigned(17 downto 0) := (others => '0');
	signal pol_dly1, pol_dly2: std_logic;
	signal source_dly1, source_dly2 : unsigned(source'RANGE) := (others => '0');

	-- How many milliseconds has the IRIG signal remained low?
	-- We use this to discriminate between symbols. Tracking 'high'
	-- length might seem more conventional, but this way, we can decode
	-- symbols at the instant of the next rising edge (which is what we
	-- ultimately align timestamps to.)
	signal ms_lo : unsigned(3 downto 0) := (others => '0');
	signal ms_strobe : std_logic := '0';

	-- Strobes for 0, 1, and p symbols.
	signal strobe_0, strobe_1, strobe_p : std_logic := '0';
	signal last_p, double_p : std_logic := '0';

	-- There's a state here for every IRIG-B bit, and a 'stuffed' state
	-- that the decoder slides into after each timestamp. It's
	-- re-activated when two timing pulses occur back-to-back.
	type state_type is (
		S1, S2, S4, S8, Sb, S10, S20, S40, P1,
		M1, M2, M4, M8, Mb, M10, M20, M40, Mb2, P2,
		H1, H2, H4, H8, Hb, H10, H20, Hb2, Hb3, P3,
		D1, D2, D4, D8, Db, D10, D20, D40, D80, P4,
		D100, D200, Db2, Db3, Db4, Db5, Db6, Db7, Db8, P5,
		Y1, Y2, Y4, Y8, Yb, Y10, Y20, Y40, Y80, P6,
		C0, C1, C2, C3, C4, C5, C6, C7, C8, P7,
		C9, C10, C11, C12, C13, C14, C15, C16, C17, P8,
		SBS0, SBS1, SBS2, SBS3, SBS4, SBS5, SBS6, SBS7, SBS8, P9,
		SBS9, SBS10, SBS11, SBS12, SBS13, SBS14, SBS15, SBS16, SBSb, P0,
		STUFFED
	);
	signal state : state_type := STUFFED;

	-- Sized to fit maximum BCD values (so a deranged IRIG-B timestamp
	-- will still be accurately decoded)
	signal s,m : unsigned(6 downto 0) := (others => '0');
	signal h : unsigned(5 downto 0) := (others => '0');
	signal d : unsigned(8 downto 0) := (others => '0');
	signal y : unsigned(7 downto 0) := (others => '0');
	signal c : std_logic_vector(17 downto 0) := (others => '0');
	signal sbs : std_logic_vector(17 downto 0) := (others => '0');
	signal ss : unsigned(28 downto 0) := (others => '1'); -- at 200 MHz, ~2.7 seconds to saturation

	-- Output timestamp (pipelined)
	signal ts_pre : irigb;

begin
	-- Symbol detector
	process(all) begin
		if rising_edge(clk_200mhz) then

			-- Multiplex and delay for pipelining and edge detection
			irig_dly1 <= irig(to_integer(source_dly2)) xor pol_dly2;
			irig_dly2 <= irig_dly1;

			source_dly1 <= source;
			source_dly2 <= source_dly1;

			pol_dly1 <= pol;
			pol_dly2 <= pol_dly1;

			-- Mark milliseconds while IRIG-B signal is stable
			--
			-- `symbol_counter` counts up at a frequency of 200E6 Hz as long as the IRIG-B signal does not have a rising or falling edge.
			--  When `symbol_counter` reaches 200E3, the `ms_strobe` is pulsed and the counter is reset.
			-- Consequently, `ms_strobe` is high for one clk200 at the end of each millisecond where the IRIG-B signal was stable
			-- Note: A IRIG-B symbol lasts 10 ms.
			symbol_counter <= (others => '0');
			ms_strobe <= '0';
			if irig_dly1=irig_dly2 then
				symbol_counter <= symbol_counter + 1;
				if symbol_counter=199999 then
					symbol_counter <= (others => '0');
					ms_strobe <= '1';
				end if;
			end if;

			-- Count how many milliseconds have elapsed while IRIG-B signal was low.
			--
			-- The counter is in reset state (zero) as long as IRIG-B is high and counts when it is low.
			--
			-- We could have measured the low time in 200 MHz clock counts, but that makes checking
			-- the duration more complex (i.e. involving less-than comparisons on 17-bit values). So
			-- instead we quantify the low time in milliseconds increments
			if irig_dly2='1' then -- IRIG-B is high, reset the counter
				ms_lo <= (others => '0');
			elsif ms_strobe='1' and ms_lo /= (ms_lo'range => '1') then -- increment ms counter unless it has reached its limit
				ms_lo <= ms_lo + 1;
			end if;

			-- When IRIG-B goes high, pulse one of the bit type (0,1 or P) depending on the length of the low IRIG-B period just before this high.
			--
			-- The strobe happens when IRIG-B is high, AND the `ms_lo` counter has a valid value
			-- (not zero, 3,6 , 9). Since the ms_lo is cleared the clock after IRIG-B is detected
			-- high, it means that the strobe is issued only once at the beginning of the following
			-- bit.
			--
			-- T
			strobe_0 <= '0';
			strobe_1 <= '0';
			strobe_p <= '0';
			if irig_dly2='1' then
				case to_integer(ms_lo) is
					when 1|2 => strobe_p <= '1';
					when 4|5 => strobe_1 <= '1';
					when 7|8 => strobe_0 <= '1';
					when others =>
				end case;
			end if;

			-- Set `last_p` when we detect consecutive markers (that are not separated by 0 ou 1 bits).
			if strobe_p='1' then
				last_p <= '1';
			end if;
			if strobe_0='1' or strobe_1='1' then
				last_p <= '0';
			end if;

			-- Start a new frame when we get two consecutive (double-P) markers, irrespective of the
			-- state we are in (so we can resync robustly). This is how the state machine gets
			-- initialized after each timestamp.
			--
			-- Detecting a double-P means we just received Pr, so reset the state to S1 which will
			-- be the next incoming bit. This is the only way we get out of the STUFFED state.
			--
			-- Note that getting a double P does not mean we successfully decoded the frame. It
			-- might have been interrupted mid-frame. We have a valid frame only if we made it all the
			-- way to P0 and then we receive a marker. This is handled further below.
			if strobe_p='1' and last_p='1' then
				state <= S1;
				s <= (others => '0');
				m <= (others => '0');
				h <= (others => '0');
				d <= (others => '0');
				y <= (others => '0');
				c <= (others => '0');
				sbs <= (others => '0');
			end if;

			-- If we switch the irig source, invalidate the state so we we'll never get to the P0
			-- state and issue a garbled timestamp.
			if source_dly1 /= source_dly2 or pol_dly1 /= pol_dly2 then
				state <= STUFFED;
			-- Otherwise, we proceed through states, unless we are in an invalid (STUFFED) state, in
			-- which case we stay just there until someone gets us out of here.
			--
			-- The timestamp will be latched when we get to the P0 (last) state.
			--
			-- In normal operation, we will run into the STUFFED state after P0. In this case, this
			-- means we expect Pr (i.e we are in Pr state). If Pr arrives, the code above will reset the state to S1, and
			-- will not be overrided here because we are in STUFFED state.
			--
			-- If bits keep coming without a Pr, we'll end up safely in the STUFFED state
			elsif state/=STUFFED and (strobe_1 or strobe_0 or strobe_p)='1' then
				state <= state_type'val(state_type'pos(state) + 1);
			end if;

			-- When a '1' is decoded, we need to set some bits somewhere
			if strobe_1='1' then
				case state is
					-- seconds
					when S1    => s <= s + 1;
					when S2    => s <= s + 2;
					when S4    => s <= s + 4;
					when S8    => s <= s + 8;
					when S10   => s <= s + 10;
					when S20   => s <= s + 20;
					when S40   => s <= s + 40;
					-- minutes
					when M1    => m <= m + 1;
					when M2    => m <= m + 2;
					when M4    => m <= m + 4;
					when M8    => m <= m + 8;
					when M10   => m <= m + 10;
					when M20   => m <= m + 20;
					when M40   => m <= m + 40;
					-- hours
					when H1    => h <= h + 1;
					when H2    => h <= h + 2;
					when H4    => h <= h + 4;
					when H8    => h <= h + 8;
					when H10   => h <= h + 10;
					when H20   => h <= h + 20;
					-- day of year
					when D1    => d <= d + 1;
					when D2    => d <= d + 2;
					when D4    => d <= d + 4;
					when D8    => d <= d + 8;
					when D10   => d <= d + 10;
					when D20   => d <= d + 20;
					when D40   => d <= d + 40;
					when D80   => d <= d + 80;
					when D100  => d <= d + 100;
					when D200  => d <= d + 200;
					-- two-digit year
					when Y1    => y <= y + 1;
					when Y2    => y <= y + 2;
					when Y4    => y <= y + 4;
					when Y8    => y <= y + 8;
					when Y10   => y <= y + 10;
					when Y20   => y <= y + 20;
					when Y40   => y <= y + 40;
					when Y80   => y <= y + 80;
					--
					when C0    => c(0) <= '1';
					when C1    => c(1) <= '1';
					when C2    => c(2) <= '1';
					when C3    => c(3) <= '1';
					when C4    => c(4) <= '1';
					when C5    => c(5) <= '1';
					when C6    => c(6) <= '1';
					when C7    => c(7) <= '1';
					when C8    => c(8) <= '1';
					when C9    => c(9) <= '1';
					when C10   => c(10) <= '1';
					when C11   => c(11) <= '1';
					when C12   => c(12) <= '1';
					when C13   => c(13) <= '1';
					when C14   => c(14) <= '1';
					when C15   => c(15) <= '1';
					when C16   => c(16) <= '1';
					when C17   => c(17) <= '1';

					when SBS0  => sbs(0) <= '1';
					when SBS1  => sbs(1) <= '1';
					when SBS2  => sbs(2) <= '1';
					when SBS3  => sbs(3) <= '1';
					when SBS4  => sbs(4) <= '1';
					when SBS5  => sbs(5) <= '1';
					when SBS6  => sbs(6) <= '1';
					when SBS7  => sbs(7) <= '1';
					when SBS8  => sbs(8) <= '1';
					when SBS9  => sbs(9) <= '1';
					when SBS10 => sbs(10) <= '1';
					when SBS11 => sbs(11) <= '1';
					when SBS12 => sbs(12) <= '1';
					when SBS13 => sbs(13) <= '1';
					when SBS14 => sbs(14) <= '1';
					when SBS15 => sbs(15) <= '1';
					when SBS16 => sbs(16) <= '1';

					when others => -- nop
				end case;
			end if;

			-- Count subseconds; on saturation or on source change, clear the 'recent' flag.
			if signed(ss) = -1 or source_dly1 /= source_dly2 or pol_dly1 /= pol_dly2 then -- also clear the recent flag immediately when the source is changed so we can use it reliably to know  when time is valid after a source change
				ts_pre.recent <= '0';
				ss <= (others => '1'); -- make sure we stop counting subseconds when the source change so 'recent' stays zero
				ts_pre.source <= source_dly2; -- otherwise this never gets updated when IRIG source is invalid
			else
				ts_pre.recent <= '1';
				ss <= ss + 1;
			end if;

			-- Clear PPS 0.5 seconds after the beginning of a frame to yield a 50% duty cycle.
			-- pps <= '0';
			if ss = 100000000 then
				pps <= '0';
			end if;

			-- If we made it all the way to state P0 and then receive a marker, we successfully
			-- finished decoding a whole frame without interruption. In this case, we latch the time
			-- into the output structure and pulse the PPS line.
			--
			--The strobe_p arrives at the end of the actual physical Pr, meaning that we will latch
			--the time 10 ms later that the real rising edge of the IRIG-B (plus a few 200-MHz
			--register stages). Also, the time that appears is the time of the last frame, not the
			--time of the current frame, adding a 1 second delay between the real time and captured
			--time . Finally, the time structure coming out of this module (`ts`) is a registered
			--version of the time thah was captured, adding an extra 200 MHz clock delay.
			--
			-- In total, this means that `ts` appears at least 1.010005 later than the actual time.
			-- This excludes the time it gets for the IRIG-B signal on the FPGA pin to generte the
			-- strobe signal.This will be many additional clocks.
			--
			if state=P0 and strobe_p='1' then
				pps <= '1'; -- generate a PPS rising edge on the rising edge following the last

				-- Latch timestamp
				ts_pre.s <= s;
				ts_pre.m <= m;
				ts_pre.h <= h;
				ts_pre.d <= d;
				ts_pre.y <= y;
				ts_pre.c <= c;
				ts_pre.sbs <= sbs;
				ts_pre.source <= source_dly2;

				ss <= (others => '0'); -- reset the 200 MHz subsecond counter
			end if;

			-- register ts
			ts <= ts_pre; -- Register the timestamp to the output of this module

		end if; -- clk
	end process;

	-- Assign subseconds in the timestamp structure; divide It is divided by two so it counts at 100 MHz (10 ns resolution).
	ts_pre.ss <= ss(28 downto 1);

end rtl;

