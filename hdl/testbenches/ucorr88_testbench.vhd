-- Self-checking testbench of the correlator with (8+8)-bit inputs (UCORR44_ARRAY with N_BITS_PER_BIN = 16:
-- one correlator of 8 inputs, the multipliers of UCMAC88_ARRAY).
--
-- All the inputs have random values. A model in the testbench computes the 36 products of each bin
-- (product 4 * i + j is x(i) * conj(x((i + j) mod 8)); for i >= 5 and i + j >= 8 it is
-- conj(x(i - 1)) * x((i + j) mod 8)), and each result record is compared with the model.
-- The frames are short (WORDS words) so that a run takes a few minutes. Bin 0 is not compared (the readout bin).
--
-- With SAMPLE_BITS = 8 the same test runs on the (4+4)-bit correlator (values from -8 to 7, records of 5 bytes for
-- each product): this shows that the two correlators have the same order and the same signs of the products.
--
-- The test ends with the message "UCORR88 TEST PASSED" or a failure.
library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;
use ieee.math_real.ALL;

library work;
use work.chFPGA_Package.ALL;

entity ucorr88_testbench is
	generic (
		SAMPLE_BITS: integer := 16; -- 16: (8+8)-bit inputs. 8: (4+4)-bit inputs.
		WORDS: integer := 32; -- words (bins) in a frame
		INTEG: integer := 320; -- frames in an integration (the readout of all the bins must fit)
		INTEGRATIONS: integer := 3 -- integrations to check
	);
end entity;

architecture sim of ucorr88_testbench is
	constant COMP_BITS: integer := SAMPLE_BITS / 2;
	constant PROD_BYTES: integer := sel(SAMPLE_BITS = 16, 6, 5);
	constant RECORD_BYTES: integer := 10 + 36 * PROD_BYTES;
	signal clk: std_logic := '0';
	signal rst: std_logic := '1';
	signal done: boolean := FALSE;
	signal corr_tdata: std_logic_vector(8 * SAMPLE_BITS - 1 downto 0) := (others => '0');
	signal corr_tvalid, corr_tlast: std_logic := '0';
	signal z_tdata: slv8;
	signal z_tvalid, z_tlast: std_logic;
	signal records: integer := 0;

	type sum_table is array (0 to 1, 0 to WORDS - 1, 0 to 35) of integer; -- integration (even or odd), bin, product
	shared variable sum_re, sum_im: sum_table;
begin
	clk <= not clk after 1.25 ns when not done;

	corr0: entity work.ucorr44_array
		generic map (
			PLATFORM_TYPE  => CRS,
			NCORR          => 1,
			NCHAN          => 8,
			NBINS_PER_CORR => 2048,
			N_BITS_PER_BIN => SAMPLE_BITS,
			URAM_TOTAL     => 20,
			SOFT_NINTEG    => INTEG,
			READOUT_BINS   => (0 => 0),
			INPUT_WIDTH    => 8 * SAMPLE_BITS
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
		variable s1, s2: positive := 5;
		variable r: real;
		type int8 is array (0 to 7) of integer;
		variable re, im: int8;
		variable k, p, q, pr, pi: integer;
		variable frame, word: integer := 0;
	begin
		for i in 1 to 20 loop wait until rising_edge(clk); end loop;
		rst <= '0';
		for i in 1 to 20 loop wait until rising_edge(clk); end loop;
		loop
			k := (frame / INTEG) mod 2;
			for ch in 0 to 7 loop -- input 0 is in the MSBs; the real part is in the MSBs of a value
				uniform(s1, s2, r); re(ch) := integer(floor(r * real(2 ** COMP_BITS))) - 2 ** (COMP_BITS - 1);
				uniform(s1, s2, r); im(ch) := integer(floor(r * real(2 ** COMP_BITS))) - 2 ** (COMP_BITS - 1);
				corr_tdata(SAMPLE_BITS * (8 - ch) - 1 downto SAMPLE_BITS * (7 - ch)) <= std_logic_vector(to_signed(re(ch), COMP_BITS)) & std_logic_vector(to_signed(im(ch), COMP_BITS));
			end loop;
			for i in 0 to 8 loop
				for j in 0 to 3 loop
					q := (i + j) mod 8;
					if i >= 5 and i + j >= 8 then -- conj(x(p)) * x(q)
						p := i - 1;
						pr := re(p) * re(q) + im(p) * im(q);
						pi := re(p) * im(q) - im(p) * re(q);
					else -- x(p) * conj(x(q))
						p := i;
						pr := re(p) * re(q) + im(p) * im(q);
						pi := im(p) * re(q) - re(p) * im(q);
					end if;
					if frame mod INTEG = 0 then
						sum_re(k, word, 4 * i + j) := pr;
						sum_im(k, word, 4 * i + j) := pi;
					else
						sum_re(k, word, 4 * i + j) := sum_re(k, word, 4 * i + j) + pr;
						sum_im(k, word, 4 * i + j) := sum_im(k, word, 4 * i + j) + pi;
					end if;
				end loop;
			end loop;
			corr_tvalid <= '1';
			corr_tlast <= to_std_logic(word = WORDS - 1);
			wait until rising_edge(clk);
			if word = WORDS - 1 then
				word := 0;
				frame := frame + 1;
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
		variable bin, integration, x_re, x_im: integer;
		variable ts: unsigned(47 downto 0);
		variable prod: std_logic_vector(47 downto 0);
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
				if integration >= 1 and bin /= 0 then -- not the first integration after the reset, not the readout bin
					for i in 0 to 35 loop
						prod := (others => '0');
						for b in 0 to PROD_BYTES - 1 loop -- the LSB is first
							prod(8 * b + 7 downto 8 * b) := rec(10 + PROD_BYTES * i + b);
						end loop;
						if SAMPLE_BITS = 16 and i mod 4 = 0 and i < 32 then -- autocorrelation: unsigned number
							x_re := to_integer(unsigned(prod(30 downto 0)));
							x_im := 0;
							assert prod(47 downto 30) = "000000000000000000" report "Autocorrelation with bits above bit 29" severity FAILURE;
						elsif SAMPLE_BITS = 16 then
							x_im := to_integer(signed(prod(23 downto 0)));
							x_re := to_integer(signed(prod(47 downto 24))) - to_integer(signed(prod(23 downto 18))); -- RE - IM_HIGH
						else
							assert prod(39 downto 36) = "0000" report "Saturation flag" severity FAILURE;
							x_re := to_integer(signed(prod(35 downto 18)));
							x_im := to_integer(signed(prod(17 downto 0)));
						end if;
						assert x_re = sum_re(integration mod 2, bin, i) and x_im = sum_im(integration mod 2, bin, i)
							report "Integration " & integer'image(integration) & " bin " & integer'image(bin) & " product " & integer'image(i) & ": " & integer'image(x_re) & " " & integer'image(x_im) &
							       ", expected " & integer'image(sum_re(integration mod 2, bin, i)) & " " & integer'image(sum_im(integration mod 2, bin, i)) severity FAILURE;
					end loop;
					records <= records + 1;
					if records = INTEGRATIONS * (WORDS - 1) - 1 then -- this was the last record
						report "UCORR88 TEST PASSED: " & integer'image(records + 1) & " result records with " & integer'image(SAMPLE_BITS / 2) & "-bit components";
						done <= TRUE;
						wait;
					end if;
				end if;
			end if;
			assert z_tlast = '0' or n = 0 report "A result frame does not end at the end of a record" severity FAILURE;
		end if;
	end process result_proc;
end architecture sim;
