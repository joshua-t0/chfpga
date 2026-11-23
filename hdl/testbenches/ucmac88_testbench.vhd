-- Self-checking testbench of UCMAC88_ARRAY: the (8+8)-bit multipliers and their wide accumulators.
--
-- Random and extreme input values go to all the CMACs for some integrations. A model in the testbench computes the
-- fields of the sums (RE and IM_HIGH & IM_LOW, with the saturation rules of the module), and each result record is
-- compared with the model. Where nothing is saturated, RE - IM_HIGH is also compared with the exact sum of the real parts.
-- The frames are short (WORDS words) so that a run takes a few minutes. The bin READOUT_BIN is not compared
-- (the module does not accumulate it correctly: see UCMAC44_ARRAY).
--
-- Integration 0: small random values. 1: random values of the full range. 2: values at the limits in the odd bins,
-- so that the cross-products go past their limits in the two directions (and the autocorrelations, with a small
-- AUTO_BITS). 3: random values again (the saturation must be gone).
library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;
use ieee.math_real.ALL;

library work;
use work.chFPGA_Package.ALL;

entity ucmac88_testbench is
	generic (
		NCMAC: integer := 36;
		STRIDE: integer := 4;
		WORDS: integer := 32; -- words (bins) in a frame
		INTEG: integer := 320; -- frames in an integration (the readout of all the bins must fit)
		INTEGRATIONS: integer := 4;
		CROSS_BITS: integer := 24;
		AUTO_BITS: integer := 30
	);
end entity;

architecture sim of ucmac88_testbench is
	constant RECORD_BYTES: integer := FRAME_HEADER_BYTE_LENGTH + 6 * NCMAC;
	constant CROSS_MAX: integer := 2 ** (CROSS_BITS - 1) - 1;
	constant CROSS_MIN: integer := -(2 ** (CROSS_BITS - 1));
	constant AUTO_MAX: real := 2.0 ** AUTO_BITS - 1.0;
	constant HIGH_MAX: integer := 2 ** (CROSS_BITS - 19) - 1; -- limit of IM_HIGH

	signal clk: std_logic := '0';
	signal rst: std_logic := '1';
	signal tdata: slv_array(0 to NCMAC - 1)(31 downto 0) := (others => (others => '0'));
	signal tvalid, tlast: std_logic := '0';
	signal swap: std_logic_vector(0 to NCMAC - 1) := (others => '0');
	signal z_tdata: std_logic_vector(7 downto 0);
	signal z_tvalid, z_tlast, overrun: std_logic;
	signal done: boolean := FALSE;

	type sum_array is array (0 to NCMAC - 1, 0 to WORDS - 1) of real; -- exact for these integers
	shared variable snap_re, snap_im, snap_re_tot: sum_array; -- the fields of the integration that is read out, and its exact sums of the real parts
	shared variable snap_number: integer := -1;
	signal records_checked, saturations_seen, exact_checked: integer := 0;

	function is_auto(i: integer) return boolean is
	begin
		return i mod STRIDE = 0 and i / STRIDE < NCMAC / STRIDE - 1;
	end function;
begin
	clk <= not clk after 1.25 ns when not done;

	uut: entity work.UCMAC88_ARRAY
		generic map (NCMAC => NCMAC, CROSS_BITS => CROSS_BITS, AUTO_BITS => AUTO_BITS, AUTOCORR_STRIDE => STRIDE, CORR_NUMBER => 0, NCORR => 1, READOUT_BIN => 0)
		port map (
			s_axis_xy_tdata => tdata, s_axis_xy_tlast => tlast, s_axis_xy_tvalid => tvalid, s_axis_xy_swap => swap,
			integ_period => std_logic_vector(to_unsigned(INTEG - 1, 16)), autocorr_only => '0', no_accum => '0', corr_id => "0000",
			overrun => overrun, overrun_reset => '0', last_frame => open, integ_start => open,
			m_axis_z_tdata => z_tdata, m_axis_z_tlast => z_tlast, m_axis_z_tvalid => z_tvalid, m_axis_z_send => '1',
			clk => clk, rst => rst
		);

	stim: process
		variable s1, s2: positive := 11;
		variable r: real;
		variable acc_re, acc_im, im_tot, re_tot: sum_array; -- RE field, IM_HIGH & IM_LOW, exact sum of the imaginary parts
		type int_array is array (0 to NCMAC - 1, 0 to WORDS - 1) of integer;
		variable hold: int_array; -- IM_HIGH when it is at a limit, or 0
		variable hi, hi_old: integer;
		variable a, b, c, d, pr, pi: integer;
		variable v: real;
		impure function rnd(level: integer) return integer is -- level 0: full range
			variable u1, u2: real;
			variable x: integer;
		begin
			uniform(s1, s2, u1);
			if level = 0 then
				return integer(floor(u1 * 256.0)) - 128;
			end if;
			uniform(s1, s2, u2);
			x := integer(round(real(level) * sqrt(-2.0 * log(u1 + 1.0e-12)) * cos(6.283185307 * u2)));
			if x > 127 then return 127; elsif x < -128 then return -128; end if;
			return x;
		end function;
	begin
		for i in 0 to NCMAC - 1 loop -- as the correlator: a CMAC has always the same swap
			uniform(s1, s2, r);
			swap(i) <= '1' when r > 0.5 and not is_auto(i) else '0';
		end loop;
		for k in 1 to 10 loop wait until rising_edge(clk); end loop;
		rst <= '0';
		for k in 1 to 10 loop wait until rising_edge(clk); end loop;

		for n in 0 to INTEGRATIONS - 1 loop
			for f in 0 to INTEG - 1 loop
				for w in 0 to WORDS - 1 loop
					for i in 0 to NCMAC - 1 loop
						if n mod 4 = 2 and w mod 2 = 1 then -- values at the limits
							case i mod 4 is
								when 0 => a := -128; b := -128; c := -128; d := -128; -- real part up
								when 1 => a := -128; b := -128; c := 127; d := 127; -- real part down
								when 2 => a := -128; b := 127; c := 127; d := 127; -- imaginary part up (down with swap)
								when others => a := 127; b := -128; c := 127; d := 127; -- imaginary part down (up with swap)
							end case;
						elsif n mod 4 = 0 then
							a := rnd(10); b := rnd(10); c := rnd(10); d := rnd(10);
						else
							a := rnd(0); b := rnd(0); c := rnd(0); d := rnd(0);
						end if;
						if is_auto(i) then
							c := a; d := b;
						end if;
						tdata(i) <= std_logic_vector(to_signed(a, 8)) & std_logic_vector(to_signed(b, 8)) & std_logic_vector(to_signed(c, 8)) & std_logic_vector(to_signed(d, 8));

						-- the model
						pr := a * c + b * d;
						pi := b * c - a * d;
						if swap(i) = '1' then
							pi := -pi;
						end if;
						if is_auto(i) then
							v := real(pr);
							if f > 0 then v := acc_re(i, w) + v; end if;
							if v > AUTO_MAX then v := AUTO_MAX; end if;
							acc_re(i, w) := v;
							acc_im(i, w) := 0.0;
						else
							-- IM_HIGH & IM_LOW: the exact sum, until IM_HIGH gets to a limit (then IM_HIGH stays, IM_LOW goes on)
							if f = 0 then im_tot(i, w) := 0.0; hold(i, w) := 0; end if;
							hi_old := integer(floor(im_tot(i, w) / 262144.0));
							im_tot(i, w) := im_tot(i, w) + real(pi);
							hi := integer(floor(im_tot(i, w) / 262144.0));
							if hold(i, w) = 0 and (hi >= HIGH_MAX or hi <= -HIGH_MAX - 1) then
								hold(i, w) := hi;
							end if;
							if hold(i, w) /= 0 then
								acc_im(i, w) := real(hold(i, w)) * 262144.0 + (im_tot(i, w) - real(hi) * 262144.0);
							else
								acc_im(i, w) := im_tot(i, w);
							end if;
							-- RE: the sum of the real parts plus the carries of IM_LOW, with saturation
							if f = 0 then
								v := real(pr) + real(hi);
							elsif acc_re(i, w) = real(CROSS_MAX) or acc_re(i, w) = real(CROSS_MIN) then
								v := acc_re(i, w);
							else
								v := acc_re(i, w) + real(pr) + real(hi - hi_old);
							end if;
							if v > real(CROSS_MAX) then v := real(CROSS_MAX); elsif v < real(CROSS_MIN) then v := real(CROSS_MIN); end if;
							acc_re(i, w) := v;
							if f = 0 then re_tot(i, w) := real(pr); else re_tot(i, w) := re_tot(i, w) + real(pr); end if;
						end if;
					end loop;
					tvalid <= '1';
					tlast <= '1' when w = WORDS - 1 else '0';
					wait until rising_edge(clk);
				end loop;
			end loop;
			-- the module now reads out this integration: one bin for each frame in which its byte buffer is free
			assert snap_number < 0 or records_checked >= (snap_number + 1) * WORDS - WORDS report "The readout of the integration before is not complete" severity FAILURE;
			snap_re := acc_re; snap_im := acc_im; snap_re_tot := re_tot; snap_number := n;
		end loop;
		-- one more integration time for the last readout (zeros on the inputs)
		tdata <= (others => (others => '0'));
		for f in 0 to INTEG - 1 loop
			for w in 0 to WORDS - 1 loop
				tlast <= '1' when w = WORDS - 1 else '0';
				wait until rising_edge(clk);
			end loop;
		end loop;
		tvalid <= '0';
		assert overrun = '0' report "Readout overrun" severity FAILURE;
		assert records_checked = INTEGRATIONS * WORDS report "Number of result records: " & integer'image(records_checked) & ", expected " & integer'image(INTEGRATIONS * WORDS) severity FAILURE;
		assert INTEGRATIONS < 3 or saturations_seen > 0 report "No saturation was seen" severity FAILURE;
		report "UCMAC88 TEST PASSED: " & integer'image(records_checked) & " records, " & integer'image(saturations_seen) & " saturated values, " & integer'image(exact_checked) & " exact real sums";
		done <= TRUE;
		wait;
	end process;

	check: process(clk)
		variable rec: slv8_array(0 to RECORD_BYTES - 1);
		variable n: integer := 0;
		variable bin: integer;
		variable w48: std_logic_vector(47 downto 0);
		variable re, im: real;
		variable sat: integer;
		variable exact: integer := 0;
	begin
		if rising_edge(clk) and z_tvalid = '1' then
			rec(n) := z_tdata;
			n := n + 1;
			if n = RECORD_BYTES then
				n := 0;
				bin := records_checked mod WORDS;
				sat := 0;
				for i in 0 to NCMAC - 1 loop
					for k in 0 to 5 loop -- little-endian
						w48(8 * k + 7 downto 8 * k) := rec(FRAME_HEADER_BYTE_LENGTH + 6 * i + k);
					end loop;
					if is_auto(i) then
						re := real(to_integer(unsigned(w48(47 downto 24)))) * 16777216.0 + real(to_integer(unsigned(w48(23 downto 0))));
						im := 0.0;
						if re = AUTO_MAX then sat := sat + 1; end if;
					else
						re := real(to_integer(signed(w48(47 downto 24))));
						im := real(to_integer(signed(w48(23 downto 0))));
						if re = real(CROSS_MAX) or re = real(CROSS_MIN) then sat := sat + 1; end if;
						if im >= real(HIGH_MAX) * 262144.0 or im < real(-HIGH_MAX) * 262144.0 then sat := sat + 1; end if;
					end if;
					-- the formula of the host: sum of the real parts = RE - IM_HIGH (valid if nothing is saturated)
					if bin /= 0 and not is_auto(i) and re /= real(CROSS_MAX) and re /= real(CROSS_MIN) and im < real(HIGH_MAX) * 262144.0 and im >= real(-HIGH_MAX) * 262144.0 then
						assert re - floor(im / 262144.0) = snap_re_tot(i, bin) report "RE - IM_HIGH is not the sum of the real parts: CMAC " & integer'image(i) & " bin " & integer'image(bin) severity FAILURE;
						exact := exact + 1;
					end if;
					if bin /= 0 then -- bin 0 is the readout bin
						assert re = snap_re(i, bin) and im = snap_im(i, bin)
							report "Integration " & integer'image(snap_number) & " bin " & integer'image(bin) & " CMAC " & integer'image(i) & ": " & real'image(re) & " " & real'image(im) &
							       ", expected " & real'image(snap_re(i, bin)) & " " & real'image(snap_im(i, bin)) severity FAILURE;
					end if;
				end loop;
				if bin /= 0 then
					saturations_seen <= saturations_seen + sat;
				end if;
				exact_checked <= exact;
				records_checked <= records_checked + 1;
			end if;
		end if;
	end process;
end architecture;
