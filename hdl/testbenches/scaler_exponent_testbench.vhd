-- Self-checking testbench of the exponent mode of the scaler (generic EXPONENT_BITS, control bit exponent_enable).
--
-- In the exponent mode each bin has an exponent e: the smallest one from 0 to 7 for which the real part and the
-- imaginary part, divided by 2^e and rounded, are from -7 to 7. The scaler sends the two rounded values (4 bits each)
-- and e. The value of the bin is output x 2^e.
--
-- Check 1 (mode off): a scaler with EXPONENT_BITS = 3 and exponent_enable = 0 gives the same data, flags and frame
-- ends as a scaler with EXPONENT_BITS = 0, 4 clocks later, and its exponents are 0. The data are random, with values
-- far above the range of 4 bits.
--
-- Check 2 (mode on): a model in the testbench computes the exact product of each FFT value and its gain, with the
-- shift, and then the exponent, the two 4-bit values and the overflow flag from the definition. Every bin of the
-- scaler is compared with the model: for the three rounding modes, with and without the symmetric saturation and
-- the zero on saturation, with random gains (integer gains and floating-point gains, which have a shift for each
-- bin), and with a table of values at the limits: 7.5 x 2^e (must take e + 1), -7.5 x 2^e, 7 x 2^e, 8 x 2^e, one
-- step above and below each one, and values that no exponent covers. The table is given to the real part alone, to
-- the imaginary part alone and to the two parts.
--
-- Check 3 (the largest exponent): exponent_max from 0 to 7. The model limits the exponent. With 0 the output must be
-- that of the scaler with EXPONENT_BITS = 0, which gets the same data.
--
-- Check 4 (the table of the bins with no exponent): the host writes the table through the RAM interface. Patterns:
-- all the bins, one bin, all the bins but one, every second bin (the two cases), random. A bin in the table must have
-- the output and the overflow flag of the scaler with EXPONENT_BITS = 0 and the exponent 0. The model uses the bin
-- number of each sample.
--
-- In checks 2 to 4, the bit that tells that a bin has an exponent (the MSB of the bits of the bin in
-- m_axis_out_texp, which the packetizer uses) is compared with the model: 1 if the bin is not in the table of the
-- bins with no exponent and exponent_max is not 0. In check 1 all these bits must be 0.
--
-- The test ends with the message "SCALER EXPONENT TEST PASSED" or a failure.
--
library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;
use ieee.math_real.ALL;

library work;
use work.chFPGA_Package.ALL;
use work.tb_package.ALL;

entity scaler_exponent_testbench is
	generic (
		BINS: integer := 256; -- bins in a frame (4 in a word): one page of gains for each bank
		FRAMES: integer := 30; -- frames for each setting
		EB: integer := 3 -- EXPONENT_BITS of the scaler under test (the ct build has 2)
	);
end scaler_exponent_testbench;

architecture behavior of scaler_exponent_testbench is
	constant CLK_PERIOD: time := 2.5 ns;
	constant WORDS: integer := BINS / 4;
	constant EMAX: integer := 2 ** EB - 1;
	constant F: integer := 44; -- bits of the product (48 bits) below the 4-bit value
	constant LATENCY_DIFF: integer := 4; -- clocks that the exponent mode adds (3 exponent stages and the register stage in front of stage 1)

	signal clk, bsb_clk: std_logic := '0';
	signal clk_on: boolean := FALSE;
	signal rst, bsb_rst: std_logic := '1';
	signal done: boolean := FALSE;
	signal fft_tdata: std_logic_vector(255 downto 0) := (others => '0');
	signal fft_tvalid, fft_tlast: std_logic := '0';
	signal ref_tdata, dut_tdata: std_logic_vector(31 downto 0);
	signal ref_tuser, dut_tuser: std_logic_vector(6 downto 0);
	signal ref_texp: std_logic_vector(3 downto 0);
	signal dut_texp: std_logic_vector(4 * (EB + 1) - 1 downto 0); -- for each bin: the bit that tells that the bin has an exponent (MSB), and the exponent
	signal ref_tvalid, ref_tlast, dut_tvalid, dut_tlast: std_logic;
	signal cmd_tdata: slv8;
	signal cmd_tvalid, cmd_tlast: std_logic := '0';
	signal cmd_to: integer range 0 to 2 := 2; -- 0: reference scaler. 1: scaler under test. 2: the two
	signal cmd_tvalid_r, cmd_tvalid_d, cmd_tready_r, cmd_tready_d, cmd_tready: std_logic;

	-- Settings of the test (the control process writes them to the scalers)
	signal run: boolean := FALSE; -- send data
	signal stim: integer range 0 to 3 := 0; -- 0: random. 1: table on the real part. 2: on the imaginary part. 3: on the two
	signal mode_on: boolean := FALSE; -- exponent mode of the scaler under test
	signal rounding: integer range 0 to 2 := 2;
	signal symmetric, zero_on_sat, offset_binary, float_gains: boolean := FALSE;
	signal left_shift: integer range 0 to 31 := 0;
	type gain_table is array (0 to BINS - 1) of unsigned(15 downto 0);
	signal gains: gain_table := (others => (others => '0'));
	signal emax_set: integer range 0 to 7 := EMAX; -- exponent_max of the scaler under test
	signal off_table: std_logic_vector(0 to BINS - 1) := (others => '0'); -- '1': the bin has no exponent (table of the scaler under test)

	-- Results
	signal words_off, words_on: integer := 0;
	signal pending: integer := 0; -- words that the model expects and that the scaler did not give yet
	type count_array is array (0 to EMAX + 1) of integer;
	signal count_e: count_array := (others => 0); -- bins checked with each exponent; EMAX + 1: no exponent is sufficient
	signal count_re, count_im: count_array := (others => 0); -- bins whose exponent is that of the real (imaginary) part alone
	-- Run-time controls: bins checked in the setting in progress (the control process sets them to 0 with count_clear)
	signal count_clear: boolean := FALSE;
	signal n_limited: integer := 0; -- bins with an exponent that need more than exponent_max
	signal n_on_big: integer := 0; -- bins with an exponent, and the exponent is not 0
	signal n_off_big: integer := 0; -- bins with no exponent that need one (they are limited as in the 4-bit mode)
	signal n_off: integer := 0; -- bins with no exponent

	-- Table of values at the limits, in units of 1 / 65536 of an output step (gain 4096, shift 16: value = FFT / 65536)
	constant N_BASE: integer := 12;
	constant N_FAR: integer := 10;
	constant N_TABLE: integer := (EMAX + 1) * N_BASE * 3 + N_FAR * 3;
	type real_array is array (natural range <>) of real;
	-- 6.75 and -7.25 have a '1' only in the bit below the rounding bit: they are not exactly between two output values
	constant BASE: real_array(0 to N_BASE - 1) := (7.5, -7.5, 7.0, -7.0, 8.0, -8.0, 6.5, -6.5, 3.5, 0.5, 6.75, -7.25);
	constant FAR: real_array(0 to N_FAR - 1) := (1000.0, -1000.0, 1024.0, -1024.0, 1023.5, -1023.5, 2000.0, -2000.0, 30000.0, -30000.0);

	function table(k: integer) return integer is
		variable n: integer := k mod N_TABLE;
		variable delta: integer := (n mod 3) - 1; -- one FFT step below, exact, one above
		variable v: real;
	begin
		n := n / 3;
		if n < (EMAX + 1) * N_BASE then
			v := BASE(n mod N_BASE) * 2.0 ** (n / N_BASE);
		else
			v := FAR(n - (EMAX + 1) * N_BASE);
		end if;
		return integer(v * 65536.0) + delta;
	end function;
begin
	clk <= not clk after CLK_PERIOD / 2 when clk_on and not done;
	bsb_clk <= not bsb_clk after 4 ns when not done;
	cmd_tvalid_r <= cmd_tvalid when cmd_to /= 1 else '0';
	cmd_tvalid_d <= cmd_tvalid when cmd_to /= 0 else '0';
	cmd_tready <= cmd_tready_r and cmd_tready_d;

	ref0: entity work.scaler
		generic map (FFT_BITS_PER_BIN => 64, FFT_BINS_PER_WORD => 4, FFT_BINS_PER_FRAME => BINS, USE_COMPLEX_GAINS => FALSE, COEFF_BITS_PER_BIN => 16, OUT_BITS_PER_BIN => 4 + 4, CAP_BITS_PER_WORD => 128)
		port map (
			s_axis_in_tdata => fft_tdata, s_axis_in_tvalid => fft_tvalid, s_axis_in_tlast => fft_tlast, s_axis_in_tuser => "00",
			m_axis_out_tdata => ref_tdata, m_axis_out_tvalid => ref_tvalid, m_axis_out_tlast => ref_tlast, m_axis_out_tuser => ref_tuser, m_axis_out_texp => ref_texp,
			clk => clk, reset => rst,
			s_axis_bsb_tdata => cmd_tdata, s_axis_bsb_tvalid => cmd_tvalid_r, s_axis_bsb_tlast => cmd_tlast, s_axis_bsb_tready => cmd_tready_r,
			m_axis_bsb_tready => '1', bsb_clk => bsb_clk, bsb_rst => bsb_rst
		);

	dut0: entity work.scaler
		generic map (FFT_BITS_PER_BIN => 64, FFT_BINS_PER_WORD => 4, FFT_BINS_PER_FRAME => BINS, USE_COMPLEX_GAINS => FALSE, COEFF_BITS_PER_BIN => 16, OUT_BITS_PER_BIN => 4 + 4, CAP_BITS_PER_WORD => 128,
		             EXPONENT_BITS => EB)
		port map (
			s_axis_in_tdata => fft_tdata, s_axis_in_tvalid => fft_tvalid, s_axis_in_tlast => fft_tlast, s_axis_in_tuser => "00",
			m_axis_out_tdata => dut_tdata, m_axis_out_tvalid => dut_tvalid, m_axis_out_tlast => dut_tlast, m_axis_out_tuser => dut_tuser, m_axis_out_texp => dut_texp,
			clk => clk, reset => rst,
			s_axis_bsb_tdata => cmd_tdata, s_axis_bsb_tvalid => cmd_tvalid_d, s_axis_bsb_tlast => cmd_tlast, s_axis_bsb_tready => cmd_tready_d,
			m_axis_bsb_tready => '1', bsb_clk => bsb_clk, bsb_rst => bsb_rst
		);

	-- Data. Component 2b + 1 of a word is the real part of bin b of the word and component 2b is its imaginary part;
	-- bin 3 is the first bin of the word.
	fft_proc: process
		variable seed1, seed2: positive := 3;
		variable r, mag: real;
		variable word, k: integer := 0;
		variable re, im: integer;

		impure function random_value return integer is -- all the magnitudes from 1 to 2^31, both signs
		begin
			uniform(seed1, seed2, mag);
			uniform(seed1, seed2, r);
			return integer(floor((r - 0.5) * 2.0 ** (31.0 * mag + 1.0) * 0.999));
		end function;
	begin
		wait until rising_edge(clk);
		if run then
			for b in 3 downto 0 loop
				case stim is
					when 1 => re := table(k); im := ((k * 7) mod 5 - 2) * 65536;
					when 2 => im := table(k); re := ((k * 7) mod 5 - 2) * 65536;
					when 3 => re := table(k); im := table(k * 37 + 11);
					when others => re := random_value; im := random_value;
				end case;
				k := k + 1;
				fft_tdata(64 * b + 63 downto 64 * b + 32) <= std_logic_vector(to_signed(re, 32));
				fft_tdata(64 * b + 31 downto 64 * b) <= std_logic_vector(to_signed(im, 32));
			end loop;
			fft_tvalid <= '1';
			fft_tlast <= to_std_logic(word = WORDS - 1);
			word := (word + 1) mod WORDS;
		else
			fft_tvalid <= '0';
			fft_tlast <= '0';
			word := 0;
			k := 0;
		end if;
	end process fft_proc;

	-- Check 1: mode off, the scaler under test against the reference scaler LATENCY_DIFF clocks before
	off_proc: process
		type slv32_pipe is array (1 to LATENCY_DIFF) of std_logic_vector(31 downto 0);
		type slv7_pipe is array (1 to LATENCY_DIFF) of std_logic_vector(6 downto 0);
		variable d: slv32_pipe := (others => (others => '0'));
		variable u: slv7_pipe := (others => (others => '0'));
		variable v, l: std_logic_vector(1 to LATENCY_DIFF) := (others => '0');
	begin
		wait until rising_edge(clk);
		if not mode_on and rst = '0' then
			assert dut_tvalid = v(LATENCY_DIFF) report "Mode off: the scaler with the exponent stages does not have the timing of the reference scaler, " & integer'image(LATENCY_DIFF) & " clocks later" severity FAILURE;
			if dut_tvalid then
				assert dut_tdata = d(LATENCY_DIFF) and dut_tuser = u(LATENCY_DIFF) and dut_tlast = l(LATENCY_DIFF)
					report "Mode off: " & to_hstring(dut_tdata) & " " & to_string(dut_tuser) & " " & std_logic'image(dut_tlast) &
					       ", the reference scaler has " & to_hstring(d(LATENCY_DIFF)) & " " & to_string(u(LATENCY_DIFF)) & " " & std_logic'image(l(LATENCY_DIFF)) severity FAILURE;
				assert unsigned(dut_texp) = 0 report "Mode off: a bit of m_axis_out_texp is not 0" severity FAILURE;
				words_off <= words_off + 1;
			end if;
		end if;
		assert rst = '1' or ref_tvalid /= '1' or unsigned(ref_texp) = 0 report "The scaler without the mode has an exponent that is not 0" severity FAILURE;
		for n in LATENCY_DIFF downto 2 loop
			d(n) := d(n - 1); u(n) := u(n - 1); v(n) := v(n - 1); l(n) := l(n - 1);
		end loop;
		d(1) := ref_tdata; u(1) := ref_tuser; v(1) := ref_tvalid; l(1) := ref_tlast;
		if rst then
			v := (others => '0');
		end if;
	end process off_proc;

	-- Check 2: mode on, the scaler under test against the model
	on_proc: process
		constant DEPTH: integer := 64;
		type exp_record is record
			tdata: std_logic_vector(31 downto 0);
			texp: std_logic_vector(4 * EB - 1 downto 0);
			overflow: std_logic_vector(3 downto 0);
			tlast: std_logic;
			has_exp: std_logic_vector(3 downto 0); -- the bin has an exponent (it is not in the table of the bins with no exponent, and exponent_max is not 0)
			as_ref: std_logic_vector(3 downto 0); -- '1': the bin has no exponent: the output of the reference scaler (4-bit mode)
		end record;
		type exp_fifo is array (0 to DEPTH - 1) of exp_record;
		variable fifo: exp_fifo;
		variable wr, rd, word: integer := 0;
		variable x: exp_record;
		-- Words of the reference scaler, which gets the same data and gives them LATENCY_DIFF clocks before
		type ref_record is record
			tdata: std_logic_vector(31 downto 0);
			overflow: std_logic_vector(3 downto 0);
		end record;
		type ref_fifo_t is array (0 to DEPTH - 1) of ref_record;
		variable ref_fifo: ref_fifo_t;
		variable rwr, rrd: integer := 0;
		variable y: ref_record;
		variable bin_number: integer;
		variable ok: boolean;
		variable got_exp: std_logic_vector(4 * EB - 1 downto 0);
		variable got_has_exp: std_logic_vector(3 downto 0);
		variable c_lim, c_on_big, c_off_big, c_off: integer := 0;
		variable gain: unsigned(15 downto 0);
		variable lg, e, e_re, e_im: integer;
		variable v_re, v_im: signed(127 downto 0);
		variable r_re, r_im: integer;
		variable fit_re, fit_im: boolean;
		variable nib_re, nib_im: signed(3 downto 0);
		variable ce, cre, cim: count_array := (others => 0);

		-- Exact value of a component: FFT x gain x 2^shift, in units of 2^-F of an output step
		function product(fft: std_logic_vector(31 downto 0); coeff: unsigned(15 downto 0); shift: integer) return signed is
		begin
			return shift_left(resize(signed(fft) * signed('0' & coeff), 128), shift);
		end function;

		-- The value divided by 2^e and rounded. fit: the result is from -7 to 7.
		procedure round(v: signed(127 downto 0); e: integer; r: out integer; fit: out boolean) is
			variable q: signed(127 downto 0) := shift_right(v, F + e); -- floor
			variable half: boolean := v(F + e - 1) = '1';
			variable below: boolean := v(F + e - 2 downto 0) /= 0;
		begin
			if rounding = 1 and half then -- 0.5 and more: up
				q := q + 1;
			elsif rounding = 2 and half and (below or q(0) = '1') then -- exactly 0.5: to the even value
				q := q + 1;
			end if;
			fit := q >= -7 and q <= 7;
			r := 0;
			if q >= -7 and q <= 7 then
				r := to_integer(q);
			end if;
		end procedure;

		impure function saturated(v: signed(127 downto 0)) return integer is
		begin
			if v >= 0 then
				return 7;
			elsif symmetric then
				return -7;
			end if;
			return -8;
		end function;

		impure function smallest(v: signed(127 downto 0)) return integer is -- smallest exponent of one component; EMAX + 1 if there is none
			variable r: integer;
			variable fit: boolean;
		begin
			for n in 0 to EMAX loop
				round(v, n, r, fit);
				if fit then
					return n;
				end if;
			end loop;
			return EMAX + 1;
		end function;
	begin
		wait until rising_edge(clk);
		if count_clear then
			c_lim := 0; c_on_big := 0; c_off_big := 0; c_off := 0;
		end if;
		if not mode_on or rst = '1' then
			wr := 0; rd := 0; word := 0; rwr := 0; rrd := 0;
		else
			if ref_tvalid then
				ref_fifo(rwr) := (tdata => ref_tdata, overflow => ref_tuser(6 downto 3));
				rwr := (rwr + 1) mod DEPTH;
				assert rwr /= rrd report "The scaler does not give its words (reference FIFO)" severity FAILURE;
			end if;
			-- The scaler under test takes a word at this clock edge: what the model expects for it
			if fft_tvalid then
				for b in 0 to 3 loop
					bin_number := 4 * word + 3 - b; -- byte b of the output word is bin 3 - b of the word
					gain := gains(bin_number);
					lg := left_shift;
					if float_gains then
						lg := lg + to_integer(gain(15 downto 11));
						gain := "00000" & gain(10 downto 0);
					end if;
					v_re := product(fft_tdata(64 * b + 63 downto 64 * b + 32), gain, lg);
					v_im := product(fft_tdata(64 * b + 31 downto 64 * b), gain, lg);
					e_re := smallest(v_re);
					e_im := smallest(v_im);
					e := minimum(maximum(e_re, e_im), emax_set); -- not more than exponent_max
					-- A bin with no exponent (the table, or exponent_max = 0): the 4-bit mode
					x.as_ref(b) := to_std_logic(off_table(bin_number) = '1' or emax_set = 0);
					x.has_exp(b) := not x.as_ref(b);
					if x.as_ref(b) then
						c_off := c_off + 1;
						if maximum(e_re, e_im) > 0 then
							c_off_big := c_off_big + 1;
						end if;
					else
						if maximum(e_re, e_im) > emax_set then
							c_lim := c_lim + 1;
						end if;
						if e > 0 then
							c_on_big := c_on_big + 1;
						end if;
					end if;
					round(v_re, e, r_re, fit_re);
					round(v_im, e, r_im, fit_im);
					if not fit_re then r_re := saturated(v_re); end if;
					if not fit_im then r_im := saturated(v_im); end if;
					if zero_on_sat and not (fit_re and fit_im) then
						r_re := 0; r_im := 0;
					end if;
					nib_re := to_signed(r_re, 4);
					nib_im := to_signed(r_im, 4);
					if offset_binary then
						nib_re(3) := not nib_re(3);
						nib_im(3) := not nib_im(3);
					end if;
					x.tdata(8 * b + 7 downto 8 * b) := std_logic_vector(nib_re) & std_logic_vector(nib_im);
					x.texp(EB * b + EB - 1 downto EB * b) := std_logic_vector(to_unsigned(e, EB));
					x.overflow(b) := to_std_logic(not (fit_re and fit_im));
					-- What the test covered
					ce(maximum(e_re, e_im)) := ce(maximum(e_re, e_im)) + 1;
					if e_re > e_im then
						cre(e_re) := cre(e_re) + 1;
					elsif e_im > e_re then
						cim(e_im) := cim(e_im) + 1;
					end if;
				end loop;
				count_e <= ce; count_re <= cre; count_im <= cim;
				n_limited <= c_lim; n_on_big <= c_on_big; n_off_big <= c_off_big; n_off <= c_off;
				x.tlast := fft_tlast;
				fifo(wr) := x;
				wr := (wr + 1) mod DEPTH;
				assert wr /= rd report "The scaler does not give its words" severity FAILURE;
				word := (word + 1) mod WORDS;
			end if;
			if dut_tvalid then
				assert rd /= wr report "Mode on: the scaler gives a word that it did not get" severity FAILURE;
				x := fifo(rd);
				rd := (rd + 1) mod DEPTH;
				assert rrd /= rwr report "Mode on: the scaler under test gives a word before the reference scaler" severity FAILURE;
				y := ref_fifo(rrd);
				rrd := (rrd + 1) mod DEPTH;
				for b in 0 to 3 loop -- the bins with no exponent: what the reference scaler gave, and the exponent 0
					if x.as_ref(b) then
						x.tdata(8 * b + 7 downto 8 * b) := y.tdata(8 * b + 7 downto 8 * b);
						x.texp(EB * b + EB - 1 downto EB * b) := (others => '0');
						x.overflow(b) := y.overflow(b);
					end if;
				end loop;
				for b in 0 to 3 loop -- the bits of a bin: the bit that tells that it has an exponent (MSB), and the exponent
					got_exp(EB * b + EB - 1 downto EB * b) := dut_texp((EB + 1) * b + EB - 1 downto (EB + 1) * b);
					got_has_exp(b) := dut_texp((EB + 1) * b + EB);
				end loop;
				ok := dut_tdata = x.tdata and got_exp = x.texp and got_has_exp = x.has_exp and dut_tuser(6 downto 3) = x.overflow and dut_tlast = x.tlast;
				if not ok then
					report "Mode on: values " & to_hstring(dut_tdata) & " exponents " & to_string(got_exp) & " bins with an exponent " & to_string(got_has_exp) & " flags " & to_string(dut_tuser(6 downto 3)) &
					       ", the model has " & to_hstring(x.tdata) & " " & to_string(x.texp) & " " & to_string(x.has_exp) & " " & to_string(x.overflow) &
					       " (rounding " & integer'image(rounding) & ", stimulus " & integer'image(stim) & ", exponent_max " & integer'image(emax_set) &
					       ", bins with no exponent " & to_string(x.as_ref) & ")" severity FAILURE;
				end if;
				words_on <= words_on + 1;
			end if;
		end if;
		pending <= (wr - rd) mod DEPTH;
	end process on_proc;

	ctrl_proc: process
		variable seed1, seed2: positive := 9;
		variable r: real;
		variable bytes: slv8_array(0 to 2 * BINS - 1);
		variable g: gain_table;
		variable setting: integer := 0;
		variable pattern: std_logic_vector(0 to BINS - 1);

		procedure write(addr, data: integer) is
		begin
			wait until rising_edge(bsb_clk);
			fpga_write_control(bsb_clk, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, addr, data, 1);
		end procedure;

		procedure write_gains(random: boolean) is -- random gains, or 4096 for all the bins
		begin
			for i in 0 to BINS - 1 loop
				uniform(seed1, seed2, r);
				g(i) := to_unsigned(4096, 16);
				if random then
					g(i) := to_unsigned(integer(floor(r * 65536.0)), 16);
				end if;
				bytes(2 * i) := std_logic_vector(g(i)(7 downto 0)); -- LSB first
				bytes(2 * i + 1) := std_logic_vector(g(i)(15 downto 8));
			end loop;
			gains <= g;
			fpga_write_ram(bsb_clk, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, 0, bytes);
		end procedure;

		-- Stops the data and writes exponent_max and the table of the bins with no exponent to the scaler under test
		-- (bin b is bit b mod 8 of byte b / 8, through the RAM interface with exp_table_select = '1')
		procedure set_exponents(emax_v: integer; table_v: std_logic_vector(0 to BINS - 1)) is
			variable tb: slv8_array(0 to BINS / 8 - 1) := (others => (others => '0'));
		begin
			run <= FALSE;
			wait for 40 * CLK_PERIOD;
			wait until rising_edge(clk);
			assert pending = 0 report "The scaler did not give all its words" severity FAILURE;
			for i in 0 to BINS - 1 loop
				tb(i / 8)(i mod 8) := table_v(i);
			end loop;
			cmd_to <= 1;
			write(1, 16#00#); -- page 0
			write(14, 128 + emax_v); -- exp_table_select
			wait until rising_edge(bsb_clk);
			fpga_write_ram(bsb_clk, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, 0, tb);
			write(14, emax_v);
			cmd_to <= 2;
			emax_set <= emax_v;
			off_table <= table_v;
			count_clear <= TRUE;
			wait until rising_edge(clk);
			wait until rising_edge(clk);
			count_clear <= FALSE;
		end procedure;

		-- Stops the data, writes the settings to the scalers, and sends `frames` frames
		procedure go(on_v: boolean; stim_v, rounding_v: integer; sym_v, zero_v, ob_v, float_v: boolean; shift_v, frames_v: integer) is
		begin
			run <= FALSE;
			wait for 40 * CLK_PERIOD; -- the words in the scalers come out
			wait until rising_edge(clk);
			assert pending = 0 report "The scaler did not give all its words" severity FAILURE;
			rst <= '1';
			cmd_to <= 2;
			write(0, 16#20# + shift_v); -- four_bits and the left shift of bank 0
			write(1, 16#40# * boolean'pos(ob_v)); -- page 0 of the gains, bank 0, offset binary
			write(2, rounding_v + 64 * boolean'pos(sym_v) + 32 * boolean'pos(zero_v));
			write(10, 128 * boolean'pos(float_v));
			cmd_to <= 1;
			write(13, 1 + 32 * boolean'pos(on_v)); -- exponent_enable, on the scaler under test only
			cmd_to <= 2;
			stim <= stim_v; rounding <= rounding_v; symmetric <= sym_v; zero_on_sat <= zero_v; offset_binary <= ob_v; float_gains <= float_v; left_shift <= shift_v;
			wait for 200 ns;
			wait until rising_edge(clk);
			mode_on <= on_v;
			rst <= '0';
			wait for 20 * CLK_PERIOD;
			wait until rising_edge(clk);
			run <= TRUE;
			wait for frames_v * WORDS * CLK_PERIOD;
			setting := setting + 1;
		end procedure;
	begin
		wait for 100 ns;
		wait until rising_edge(bsb_clk);
		bsb_rst <= '0';
		wait for 100 ns;
		clk_on <= TRUE;
		wait for 100 ns;
		write(1, 16#00#);
		write_gains(TRUE);

		-- Check 1: mode off
		for n in 0 to 11 loop -- the 3 rounding modes, with and without the symmetric saturation and the zero on saturation
			go(FALSE, 0, n mod 3, (n / 3) mod 2 = 1, n / 6 = 1, n = 4, n = 7 or n = 10, 3 * (n mod 4), FRAMES);
		end loop;

		-- Check 2: mode on, random data and random gains. Floating-point gains have a shift of 0 to 31 for each bin.
		for n in 0 to 23 loop
			go(TRUE, 0, n mod 3, (n / 3) mod 2 = 1, (n / 6) mod 2 = 1, n = 5 or n = 16, n >= 12, sel(n >= 12, n mod 4, 2 + 3 * (n mod 4)), FRAMES);
		end loop;

		-- Check 2: mode on, the table of values at the limits. Gain 4096 and a shift of 16: value = FFT / 65536.
		run <= FALSE;
		wait for 40 * CLK_PERIOD;
		write_gains(FALSE);
		for n in 0 to 11 loop
			for s in 1 to 3 loop
				go(TRUE, s, n mod 3, (n / 3) mod 2 = 1, n / 6 = 1, FALSE, FALSE, 16, 8);
			end loop;
		end loop;
		-- Check 3: the largest exponent (exponent_max), random data and the table of values. With 0 the output is
		-- that of the 4-bit mode (the reference scaler).
		for m in 0 to EMAX loop
			set_exponents(m, (0 to BINS - 1 => '0'));
			go(TRUE, 0, m mod 3, m mod 2 = 1, m = 5, m = 6, FALSE, 16, FRAMES);
			go(TRUE, 3, (m + 1) mod 3, m mod 2 = 0, m = 2, FALSE, FALSE, 16, 8);
			run <= FALSE;
			wait for 40 * CLK_PERIOD;
			if m = 0 then
				assert n_off > FRAMES * BINS and n_off_big > 1000 and n_on_big = 0 report "exponent_max = 0: the bins were not checked as bins of the 4-bit mode" severity FAILURE;
			else
				assert n_on_big > 1000 and (n_limited > 1000 or m = EMAX) and n_off = 0 report "exponent_max = " & integer'image(m) & ": not enough bins at the limit" severity FAILURE;
			end if;
			report "exponent_max " & integer'image(m) & ": " & integer'image(n_on_big) & " bins with an exponent that is not 0, " & integer'image(n_limited) & " that need more than the limit";
		end loop;

		-- Check 4: the table of the bins with no exponent. Patterns: all the bins in the table, one bin in it, one bin
		-- not in it, every second bin, random. The model has the bin number of each sample.
		for t in 0 to 5 loop
			for i in 0 to BINS - 1 loop
				uniform(seed1, seed2, r);
				case t is
					when 0 => pattern(i) := '1';
					when 1 => pattern(i) := to_std_logic(i = 37);
					when 2 => pattern(i) := to_std_logic(i /= 37);
					when 3 => pattern(i) := to_std_logic(i mod 2 = 0);
					when 4 => pattern(i) := to_std_logic(i mod 2 = 1);
					when others => pattern(i) := to_std_logic(r < 0.5);
				end case;
			end loop;
			set_exponents(sel(t = 4, minimum(3, EMAX), EMAX), pattern);
			go(TRUE, 0, t mod 3, t = 1, t = 3, t = 5, FALSE, 16, FRAMES);
			go(TRUE, 3, (t + 1) mod 3, t = 2, t = 4, FALSE, FALSE, 16, 8);
			run <= FALSE;
			wait for 40 * CLK_PERIOD;
			assert n_off_big > 10 and (n_on_big > 10 or t = 0) and (n_on_big = 0 or t /= 0)
				report "Table pattern " & integer'image(t) & ": not enough bins of the two kinds (" & integer'image(n_on_big) & " with an exponent, " & integer'image(n_off_big) & " limited with no exponent)" severity FAILURE;
			report "Table pattern " & integer'image(t) & ": " & integer'image(n_on_big) & " bins with an exponent that is not 0, " & integer'image(n_off_big) & " bins with no exponent that are limited";
		end loop;
		set_exponents(EMAX, (0 to BINS - 1 => '0'));
		run <= FALSE;
		wait for 40 * CLK_PERIOD;
		assert pending = 0 report "The scaler did not give all its words" severity FAILURE;

		assert words_off > 10 * FRAMES * WORDS and words_on > 20 * FRAMES * WORDS report "Not enough data checked" severity FAILURE;
		for n in 0 to EMAX + 1 loop
			assert count_e(n) > 0 report "No bin with the exponent " & integer'image(n) severity FAILURE;
			if n > 0 then
				assert count_re(n) > 0 and count_im(n) > 0 report "No bin that has the exponent " & integer'image(n) & " for one part alone" severity FAILURE;
			end if;
			report "Exponent " & integer'image(n) & sel(n > EMAX, " (no exponent is sufficient)", "") & ": " & integer'image(count_e(n)) & " bins, " &
			       integer'image(count_re(n)) & " for the real part alone, " & integer'image(count_im(n)) & " for the imaginary part alone";
		end loop;
		report "SCALER EXPONENT TEST PASSED: " & integer'image(words_off) & " words with the mode off, " & integer'image(words_on) & " words with the mode on, " & integer'image(setting) & " settings";
		done <= TRUE;
		wait;
	end process ctrl_proc;
end architecture behavior;
