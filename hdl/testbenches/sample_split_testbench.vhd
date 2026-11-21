-- Self-checking testbench for sample_split (the split-sample stage in front of the correlator).
--
-- The testbench has its own model of the stage. On every clock it compares all the outputs with
-- the model, in the default mode and in the split mode, with mode changes at random times (a frame
-- must have one mode only). The data are:
--  - every value from -128 to 127 on every component of every lane (the values beyond -60 and 59
--    saturate, and the testbench checks the saturation counters);
--  - random values on four wide inputs that have a common signal. Over these, the testbench sums
--    the products of the wide values of each pair of inputs, and the products of their parts as the
--    correlator makes them: 64 hh + 8 (hl + lh) + ll must be the product of the wide values, exactly.
--
-- In the default mode the output is the 4 MSBs of each component: the values of the channelizers
-- pass with no change.
--
-- The test ends with the message "SAMPLE SPLIT TEST PASSED" or a failure.
--
library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;
use ieee.math_real.ALL;

library work;
use work.chFPGA_Package.ALL;

entity sample_split_testbench is
	generic (
		FRAMES: integer := 3000; -- frames of random data
		WORDS: integer := 16 -- words in a frame
	);
end sample_split_testbench;

architecture behavior of sample_split_testbench is
	constant CLK_PERIOD: time := 2.5 ns;
	signal clk: std_logic := '0';
	signal rst: std_logic := '1';
	signal done: boolean := FALSE;

	signal in_tdata: slv_array(0 to 7)(63 downto 0) := (others => (others => '0'));
	signal in_tuser, out_tuser: slv_array(0 to 7)(3 downto 0) := (others => (others => '0'));
	signal in_tvalid, in_tlast, out_tvalid, out_tlast: std_logic_vector(0 to 7) := (others => '0');
	signal out_tdata: slv_array(0 to 7)(31 downto 0);
	signal split_mode, sat_reset: std_logic := '0';
	signal sat_count: slv_array(0 to 3)(15 downto 0);
begin
	clk <= not clk after CLK_PERIOD / 2 when not done;

	uut: entity work.sample_split
		port map (
			s_axis_tdata  => in_tdata,
			s_axis_tuser  => in_tuser,
			s_axis_tvalid => in_tvalid,
			s_axis_tlast  => in_tlast,
			m_axis_tdata  => out_tdata,
			m_axis_tuser  => out_tuser,
			m_axis_tvalid => out_tvalid,
			m_axis_tlast  => out_tlast,
			split_mode      => split_mode,
			sat_count       => sat_count,
			sat_count_reset => sat_reset,
			clk => clk,
			rst => rst
		);

	test_proc: process
		variable seed1, seed2: positive := 11;
		variable r: real;
		type int_array is array (natural range <>) of integer;
		type comp_array is array (0 to 7, 0 to 7) of integer; -- lane, component
		variable v: comp_array := (others => (others => 0));
		-- Model: the last two input words and their mode
		type word_array is array (0 to 7) of std_logic_vector(31 downto 0);
		type pipe_array is array (1 to 2) of word_array;
		variable exp_data: pipe_array := (others => (others => (others => '0')));
		variable exp_valid, exp_last: std_logic_vector(1 to 2) := "00";
		variable exp_first: slv_array(1 to 2)(3 downto 0) := (others => "0000");
		variable mode: std_logic := '0'; -- mode of the frame on the input
		variable word: integer := 0;
		variable valid: std_logic := '0';
		variable w, t, high, low, common: integer;
		variable sat: boolean;
		variable expected_sat: int_array(0 to 3) := (others => 0);
		variable words_split, words_default, mode_changes: integer := 0;
		-- Sums of products of real components (component 0 of each wide input): wide values, and parts
		type sum_array is array (0 to 3, 0 to 3) of integer;
		variable sum_w, sum_hh, sum_hl, sum_lh, sum_ll: sum_array := (others => (others => 0));
		variable wv, hv, lv: int_array(0 to 3);

		impure function rand(lo, hi: integer) return integer is
		begin
			uniform(seed1, seed2, r);
			return lo + integer(floor(r * real(hi - lo + 1)));
		end function;

		function to_nibble(i: integer) return std_logic_vector is
		begin
			return std_logic_vector(to_signed(i, 4));
		end function;

		-- One clock: drives the values in ``v``, and compares the outputs with the model
		procedure step is
			variable d: word_array;
			variable byte: std_logic_vector(7 downto 0);
		begin
			-- Model of the word that goes in
			for l in 0 to 7 loop
				for c in 0 to 7 loop
					byte := std_logic_vector(to_signed(v(l, c), 8));
					d(l)(4 * c + 3 downto 4 * c) := byte(7 downto 4);
				end loop;
			end loop;
			if mode = '1' then
				for i in 0 to 3 loop
					sat := FALSE;
					for c in 0 to 7 loop
						w := v(i, c);
						if w > 59 then w := 59; sat := TRUE; end if;
						if w < -60 then w := -60; sat := TRUE; end if;
						t := w + 4;
						high := integer(floor(real(t) / 8.0));
						low := t - 8 * high - 4;
						assert high >= -7 and high <= 7 and low >= -4 and low <= 3 and 8 * high + low = w report "Error in the model" severity FAILURE;
						d(2 * i)(4 * c + 3 downto 4 * c) := to_nibble(high);
						d(2 * i + 1)(4 * c + 3 downto 4 * c) := to_nibble(low);
						if c = 0 then
							wv(i) := w; hv(i) := high; lv(i) := low;
						end if;
					end loop;
					if sat and valid = '1' then
						expected_sat(i) := expected_sat(i) + 1;
					end if;
				end loop;
				if valid = '1' then
					words_split := words_split + 1;
					for i in 0 to 3 loop
						for j in 0 to 3 loop
							sum_w(i, j) := sum_w(i, j) + wv(i) * wv(j);
							sum_hh(i, j) := sum_hh(i, j) + hv(i) * hv(j);
							sum_hl(i, j) := sum_hl(i, j) + hv(i) * lv(j);
							sum_lh(i, j) := sum_lh(i, j) + lv(i) * hv(j);
							sum_ll(i, j) := sum_ll(i, j) + lv(i) * lv(j);
						end loop;
					end loop;
				end if;
			elsif valid = '1' then
				words_default := words_default + 1;
			end if;

			for l in 0 to 7 loop
				for c in 0 to 7 loop
					in_tdata(l)(8 * c + 7 downto 8 * c) <= std_logic_vector(to_signed(v(l, c), 8));
				end loop;
				in_tuser(l) <= std_logic_vector(to_unsigned((word + l) mod 16, 4));
			end loop;
			in_tvalid <= (others => valid);
			in_tlast <= (others => to_std_logic(word = WORDS - 1));
			wait until rising_edge(clk);

			-- The outputs now are those of the word of two clocks before
			assert out_tvalid = (0 to 7 => exp_valid(2)) report "Wrong tvalid" severity FAILURE;
			if exp_valid(2) = '1' then
				assert out_tlast = (0 to 7 => exp_last(2)) report "Wrong tlast" severity FAILURE;
				assert out_tuser(0) = exp_first(2) report "Wrong tuser" severity FAILURE;
				for l in 0 to 7 loop
					assert out_tdata(l) = exp_data(2)(l) report "Wrong data on lane " & integer'image(l) & ": " & to_hstring(out_tdata(l)) & ", expected " & to_hstring(exp_data(2)(l)) severity FAILURE;
				end loop;
			end if;
			exp_data(2) := exp_data(1); exp_valid(2) := exp_valid(1); exp_last(2) := exp_last(1); exp_first(2) := exp_first(1);
			exp_data(1) := d; exp_valid(1) := valid; exp_last(1) := to_std_logic(word = WORDS - 1);
			exp_first(1) := std_logic_vector(to_unsigned(word mod 16, 4));

			-- The mode changes at the end of a frame
			if valid = '1' and word = WORDS - 1 then
				if mode /= split_mode then
					mode_changes := mode_changes + 1;
				end if;
				mode := split_mode;
			end if;
			if valid = '1' then
				word := (word + 1) mod WORDS;
			end if;
		end procedure;
	begin
		for i in 1 to 5 loop
			step;
		end loop;
		rst <= '0';
		valid := '1';

		-- Every value on every component, in the default mode then in the split mode
		for m in 0 to 1 loop
			split_mode <= to_std_logic(m = 1);
			for n in -128 to 127 + 2 * WORDS loop
				for l in 0 to 7 loop
					for c in 0 to 7 loop
						v(l, c) := (n + 128 + 37 * l + 11 * c) mod 256 - 128;
					end loop;
				end loop;
				step;
			end loop;
		end loop;
		assert expected_sat(0) > 100 report "No saturation in the test" severity FAILURE;

		-- Random data with a common signal, mode changes at random times, and gaps in the data
		for f in 1 to FRAMES * WORDS loop
			common := rand(-40, 40);
			for l in 0 to 7 loop
				for c in 0 to 7 loop
					v(l, c) := common + rand(-30, 30);
					if rand(0, 99) = 0 then
						v(l, c) := rand(-128, 127);
					end if;
				end loop;
			end loop;
			if rand(0, 20 * WORDS) = 0 then
				split_mode <= not split_mode;
			end if;
			valid := to_std_logic(rand(0, 15) /= 0);
			step;
		end loop;
		valid := '0';
		for i in 1 to 5 loop
			step;
		end loop;

		for i in 0 to 3 loop
			assert to_integer(unsigned(sat_count(i))) = expected_sat(i) report "Saturation counter " & integer'image(i) & ": " & integer'image(to_integer(unsigned(sat_count(i)))) & ", expected " & integer'image(expected_sat(i)) severity FAILURE;
			for j in 0 to 3 loop
				assert 64 * sum_hh(i, j) + 8 * (sum_hl(i, j) + sum_lh(i, j)) + sum_ll(i, j) = sum_w(i, j)
					report "The products of the parts do not give the product of the wide values (inputs " & integer'image(i) & " and " & integer'image(j) & ")" severity FAILURE;
			end loop;
		end loop;
		assert sum_w(0, 1) /= 0 and words_split > 1000 and words_default > 1000 and mode_changes > 10 report "The test did not cover the two modes" severity FAILURE;
		sat_reset <= '1';
		wait until rising_edge(clk);
		sat_reset <= '0';
		wait until rising_edge(clk);
		wait until rising_edge(clk);
		assert sat_count(0) = X"0000" report "The saturation counter is not cleared" severity FAILURE;

		report "SAMPLE SPLIT TEST PASSED: " & integer'image(words_split) & " words in the split mode, " & integer'image(words_default) & " in the default mode, " &
		       integer'image(mode_changes) & " mode changes, " & integer'image(expected_sat(0)) & " saturated words on input 0";
		done <= TRUE;
		wait;
	end process test_proc;
end architecture behavior;
