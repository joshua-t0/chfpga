-- Self-checking testbench for the accumulators of the correlator (UCORR44_ARRAY, one correlator of
-- 8 inputs, frames of the real length: 2048 words).
--
-- Inputs 0 to 2 are constant at full scale (-7 - 7j, 7 - 7j, and -8 - 8j, which the 4 bits can
-- also hold). Inputs 3 to 7 are random. The testbench has the exact sum of the power of each input
-- in each bin for each integration, and compares it with the autocorrelations in the result
-- packets, for the first 64 bins (and the constant inputs in all the bins). With WIDE = 1 (36-bit unsigned autocorrelations) they must be equal, with no saturation
-- flag, also when the sum is more than the 18 bits of the other products can hold (INTEG = 2100
-- gives 205800 for a full-scale input). The first integration after the reset is not checked,
-- but with CONSTANT_ONLY = 1 it is the one that is checked (for one long integration:
-- INTEG = 32768 gives 3211264).
--
-- DUMP_FILE gets one line for each result record (timestamp, bin, product bytes). To show that the
-- other products do not change, run the testbench on the design before the change and compare the
-- files (run.sh does that).
--
-- The test ends with the message "UCORR ACC TEST PASSED" or a failure.
--
library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;
use ieee.math_real.ALL;
use std.textio.ALL;

library work;
use work.chFPGA_Package.ALL;

entity ucorr_acc_testbench is
	generic (
		INTEG: integer := 2100; -- frames in an integration (the readout needs 2048)
		INTEGRATIONS: integer := 2; -- integrations to check
		WIDE: integer range 0 to 1 := 1; -- 1: 36-bit unsigned autocorrelations, checked against the exact sums
		CONSTANT_ONLY: integer range 0 to 1 := 0; -- 1: all the inputs are constant at -7 - 7j or 7 + 7j (for long integrations: no table of sums)
		DUMP_FILE: string := ""
	);
end ucorr_acc_testbench;

architecture behavior of ucorr_acc_testbench is
	constant CLK_PERIOD: time := 2.5 ns;
	constant WORDS: integer := 2048;
	constant RECORD_BYTES: integer := 10 + 36 * 5;
	signal clk: std_logic := '0';
	signal clk_on: boolean := FALSE;
	signal rst: std_logic := '1';
	signal done: boolean := FALSE;
	signal corr_tdata: std_logic_vector(63 downto 0) := (others => '0');
	signal corr_tvalid, corr_tlast: std_logic := '0';
	signal z_tdata: slv8;
	signal z_tvalid, z_tlast: std_logic;
	signal records: integer := 0;

	constant CHECK_BINS: integer := 64; -- the bins 1 to CHECK_BINS have their exact sums (a small table: the simulator is slow with a large shared one)
	type sum_table is array (0 to 1, 0 to CHECK_BINS, 3 to 7) of integer; -- integration (even or odd), bin, input
	shared variable sums: sum_table := (others => (others => (others => 0)));
begin
	clk <= not clk after CLK_PERIOD / 2 when clk_on and not done;

	corr0: entity work.ucorr44_array
		generic map (
			PLATFORM_TYPE  => CRS,
			NCORR          => 1,
			NCHAN          => 8,
			NBINS_PER_CORR => WORDS,
			SOFT_NINTEG    => INTEG,
			WIDE_AUTOCORR  => WIDE = 1,
			READOUT_BINS   => (0 => 0),
			INPUT_WIDTH    => 64
		)
		port map (
			s_axis_data_tdata  => corr_tdata,
			s_axis_data_tvalid => corr_tvalid,
			s_axis_data_tlast  => corr_tlast,
			clk => clk,
			rst => rst,
			m_axis_data_tdata  => z_tdata,
			m_axis_data_tvalid => z_tvalid,
			m_axis_data_tlast  => z_tlast,
			m_axis_data_tready => '1',
			out_clk            => clk,
			m_axis_bsb_tready => '1',
			bsb_clk => clk,
			bsb_rst => rst
		);

	stim_proc: process
		variable lcg: integer := 1;
		variable re, im, k: integer;
		variable frame, word: integer := 0;
	begin
		wait for 50 ns;
		clk_on <= TRUE;
		for i in 1 to 20 loop
			wait until rising_edge(clk);
		end loop;
		rst <= '0';
		for i in 1 to 20 loop
			wait until rising_edge(clk);
		end loop;
		loop
			k := (frame / INTEG) mod 2;
			if word = 0 and frame mod INTEG = 0 and CONSTANT_ONLY = 0 then -- new integration: clear its sums
				for b in 0 to CHECK_BINS loop
					for ch in 3 to 7 loop
						sums(k, b, ch) := 0;
					end loop;
				end loop;
			end if;
			corr_tdata(63 downto 56) <= X"99"; -- -7 - 7j
			corr_tdata(55 downto 48) <= X"79"; -- 7 - 7j
			corr_tdata(47 downto 40) <= X"88"; -- -8 - 8j
			if CONSTANT_ONLY = 1 then
				corr_tdata(47 downto 0) <= X"779977997799";
			else
				for ch in 3 to 7 loop
					lcg := (lcg * 75 + 74) mod 65537; -- a fast generator of numbers from 0 to 65536
					re := (lcg / 16) mod 15 - 7;
					im := (lcg / 512) mod 15 - 7;
					corr_tdata(63 - 8 * ch downto 56 - 8 * ch) <= std_logic_vector(to_signed(re, 4)) & std_logic_vector(to_signed(im, 4));
					if word <= CHECK_BINS then
						sums(k, word, ch) := sums(k, word, ch) + re * re + im * im;
					end if;
				end loop;
			end if;
			corr_tvalid <= '1';
			corr_tlast <= to_std_logic(word = WORDS - 1);
			wait until rising_edge(clk);
			if word = WORDS - 1 then
				word := 0;
				frame := frame + 1;
				if frame mod 500 = 0 then
					report "PROGRESS frame " & integer'image(frame);
				end if;
			else
				word := word + 1;
			end if;
			exit when done;
		end loop;
		wait;
	end process stim_proc;

	result_proc: process
		variable rec: slv8_array(0 to RECORD_BYTES - 1);
		variable n: integer := 0;
		variable bin, integration, expected, input_power: integer;
		variable ts: unsigned(47 downto 0);
		variable prod: unsigned(39 downto 0);
		variable value: unsigned(35 downto 0);
		file dump: text;
		variable dump_open: boolean := FALSE;
		variable l: line;
	begin
		wait until rising_edge(clk);
		if z_tvalid then
			rec(n) := z_tdata;
			n := n + 1;
			if n = RECORD_BYTES then
				n := 0;
				assert rec(0) = X"CF" report "Bad first byte of a result record" severity FAILURE;
				assert rec(3)(0) = '0' report "Correlator overrun" severity FAILURE;
				bin := to_integer(unsigned(rec(1)(2 downto 0)) & unsigned(rec(2)));
				ts := unsigned(rec(4)) & unsigned(rec(5)) & unsigned(rec(6)) & unsigned(rec(7)) & unsigned(rec(8)) & unsigned(rec(9));
				integration := to_integer(ts) / INTEG;
				assert to_integer(ts) mod INTEG = 0 report "Bad timestamp" severity FAILURE;
				if integration >= 1 - CONSTANT_ONLY and bin /= 0 then -- not the bin that the correlator gives to the readout
					if DUMP_FILE'length > 0 then
						if not dump_open then
							file_open(dump, DUMP_FILE, write_mode);
							dump_open := TRUE;
						end if;
						write(l, integration); write(l, string'(" ")); write(l, bin); write(l, string'(" "));
						for i in 10 to RECORD_BYTES - 1 loop
							hwrite(l, rec(i));
						end loop;
						writeline(dump, l);
					end if;
					if WIDE = 1 and (bin <= CHECK_BINS or CONSTANT_ONLY = 1) then
						for ch in 0 to 7 loop -- the autocorrelation of input ch is product 4 * ch
							for b in 0 to 4 loop
								prod(8 * b + 7 downto 8 * b) := unsigned(rec(10 + 20 * ch + b)); -- the LSB is first
							end loop;
							value := prod(17 downto 0) & prod(35 downto 18);
							if CONSTANT_ONLY = 1 or ch < 2 then
								expected := 98 * INTEG;
							elsif ch = 2 then
								expected := 128 * INTEG;
							else
								expected := sums(integration mod 2, bin, ch);
							end if;
							assert prod(39 downto 36) = "0000" report "Saturation flag on an autocorrelation" severity FAILURE;
							assert value = expected report "Autocorrelation of input " & integer'image(ch) & ", bin " & integer'image(bin) & ", integration " & integer'image(integration) &
								": " & integer'image(to_integer(value(30 downto 0))) & ", expected " & integer'image(expected) severity FAILURE;
						end loop;
					end if;
					records <= records + 1;
				end if;
				if records = INTEGRATIONS * (WORDS - 1) - 1 and integration >= 1 - CONSTANT_ONLY and bin /= 0 then -- this was the last record
					report "UCORR ACC TEST PASSED: " & integer'image(records + 1) & " result records, autocorrelations of " & integer'image(98 * INTEG) & " for a full-scale input";
					if dump_open then
						file_close(dump);
					end if;
					done <= TRUE;
					wait;
				end if;
			end if;
			assert z_tlast = '0' or n = 0 report "A result frame does not end at the end of a record" severity FAILURE;
		end if;
	end process result_proc;
end architecture behavior;
