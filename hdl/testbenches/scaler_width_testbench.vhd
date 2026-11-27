-- Self-checking testbench: a scaler with (8+8)-bit outputs gives, in the 4-bit mode, the values of a
-- scaler with (4+4)-bit outputs.
--
-- The corr8 build has scalers with (8+8)-bit outputs. In the default mode
-- (four_bits = 1) the correlator takes the 4 MSBs of each component. This testbench gives the same
-- random data, the same random gain tables and the same settings to a scaler of each width, and
-- compares the 4-bit values on every clock, for each rounding mode, with and without the symmetric
-- saturation. Then it sets the wide scaler to the 8-bit mode and checks that it uses its 4 LSBs.
--
-- The test ends with the message "SCALER WIDTH TEST PASSED" or a failure.
--
library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;
use ieee.math_real.ALL;

library work;
use work.chFPGA_Package.ALL;
use work.tb_package.ALL;

entity scaler_width_testbench is
	generic (
		BINS: integer := 256; -- bins in a frame (4 in a word): one page of gains for each bank
		FRAMES: integer := 300 -- frames for each setting
	);
end scaler_width_testbench;

architecture behavior of scaler_width_testbench is
	constant CLK_PERIOD: time := 2.5 ns;
	constant WORDS: integer := BINS / 4;
	signal clk, bsb_clk: std_logic := '0';
	signal clk_on: boolean := FALSE;
	signal rst, bsb_rst: std_logic := '1';
	signal done: boolean := FALSE;
	signal fft_tdata: std_logic_vector(255 downto 0) := (others => '0');
	signal fft_tvalid, fft_tlast: std_logic := '0';
	signal narrow_tdata: std_logic_vector(31 downto 0);
	signal wide_tdata: std_logic_vector(63 downto 0);
	signal narrow_tvalid, narrow_tlast, wide_tvalid, wide_tlast: std_logic;
	signal cmd_tdata: slv8;
	signal cmd_tvalid, cmd_tlast: std_logic := '0';
	signal cmd_to: integer range 0 to 2 := 2; -- 0: narrow scaler. 1: wide scaler. 2: the two
	signal cmd_tvalid_n, cmd_tvalid_w, cmd_tready_n, cmd_tready_w, cmd_tready: std_logic;
	signal compare: boolean := FALSE;
	signal words_checked, nonzero, low_bits: integer := 0;
begin
	clk <= not clk after CLK_PERIOD / 2 when clk_on and not done;
	bsb_clk <= not bsb_clk after 4 ns when not done;
	cmd_tvalid_n <= cmd_tvalid when cmd_to /= 1 else '0';
	cmd_tvalid_w <= cmd_tvalid when cmd_to /= 0 else '0';
	cmd_tready <= cmd_tready_n and cmd_tready_w;

	narrow0: entity work.scaler
		generic map (FFT_BITS_PER_BIN => 64, FFT_BINS_PER_WORD => 4, FFT_BINS_PER_FRAME => BINS, USE_COMPLEX_GAINS => FALSE, COEFF_BITS_PER_BIN => 16, OUT_BITS_PER_BIN => 4 + 4, CAP_BITS_PER_WORD => 128)
		port map (
			s_axis_in_tdata => fft_tdata, s_axis_in_tvalid => fft_tvalid, s_axis_in_tlast => fft_tlast, s_axis_in_tuser => "00",
			m_axis_out_tdata => narrow_tdata, m_axis_out_tvalid => narrow_tvalid, m_axis_out_tlast => narrow_tlast,
			clk => clk, reset => rst,
			s_axis_bsb_tdata => cmd_tdata, s_axis_bsb_tvalid => cmd_tvalid_n, s_axis_bsb_tlast => cmd_tlast, s_axis_bsb_tready => cmd_tready_n,
			m_axis_bsb_tready => '1', bsb_clk => bsb_clk, bsb_rst => bsb_rst
		);

	wide0: entity work.scaler
		generic map (FFT_BITS_PER_BIN => 64, FFT_BINS_PER_WORD => 4, FFT_BINS_PER_FRAME => BINS, USE_COMPLEX_GAINS => FALSE, COEFF_BITS_PER_BIN => 16, OUT_BITS_PER_BIN => 8 + 8, CAP_BITS_PER_WORD => 128)
		port map (
			s_axis_in_tdata => fft_tdata, s_axis_in_tvalid => fft_tvalid, s_axis_in_tlast => fft_tlast, s_axis_in_tuser => "00",
			m_axis_out_tdata => wide_tdata, m_axis_out_tvalid => wide_tvalid, m_axis_out_tlast => wide_tlast,
			clk => clk, reset => rst,
			s_axis_bsb_tdata => cmd_tdata, s_axis_bsb_tvalid => cmd_tvalid_w, s_axis_bsb_tlast => cmd_tlast, s_axis_bsb_tready => cmd_tready_w,
			m_axis_bsb_tready => '1', bsb_clk => bsb_clk, bsb_rst => bsb_rst
		);

	-- Random data: small and large values, so that the output has all the values and saturations
	fft_proc: process
		variable seed1, seed2: positive := 3;
		variable r, scale: real;
		variable word: integer := 0;
	begin
		wait until rising_edge(clk);
		for c in 0 to 7 loop
			uniform(seed1, seed2, scale);
			uniform(seed1, seed2, r);
			fft_tdata(32 * c + 31 downto 32 * c) <= std_logic_vector(to_signed(integer((r - 0.5) * scale * scale * 4.0e9), 32));
		end loop;
		fft_tvalid <= not rst;
		fft_tlast <= to_std_logic(word = WORDS - 1);
		if rst then
			word := 0;
		else
			word := (word + 1) mod WORDS;
		end if;
	end process fft_proc;

	check_proc: process begin
		wait until rising_edge(clk);
		if compare then
			assert narrow_tvalid = wide_tvalid and narrow_tlast = wide_tlast report "The two scalers do not have the same timing" severity FAILURE;
			if narrow_tvalid then
				for c in 0 to 7 loop
					assert wide_tdata(8 * c + 7 downto 8 * c + 4) = narrow_tdata(4 * c + 3 downto 4 * c)
						report "Component " & integer'image(c) & ": " & to_hstring(wide_tdata) & " and " & to_hstring(narrow_tdata) severity FAILURE;
					assert wide_tdata(8 * c + 3 downto 8 * c) = "0000" report "The 4 LSBs are not zero in the 4-bit mode" severity FAILURE;
				end loop;
				words_checked <= words_checked + 1;
				if narrow_tdata /= X"00000000" and narrow_tdata /= X"88888888" then
					nonzero <= nonzero + 1;
				end if;
			end if;
		elsif wide_tvalid = '1' and (wide_tdata and X"0F0F0F0F0F0F0F0F") /= X"0000000000000000" then
			low_bits <= low_bits + 1;
		end if;
	end process check_proc;

	ctrl_proc: process
		variable seed1, seed2: positive := 9;
		variable r: real;
		variable bytes: slv8_array(0 to 511);

		procedure write(addr, data: integer) is
		begin
			wait until rising_edge(bsb_clk);
			fpga_write_control(bsb_clk, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, addr, data, 1);
		end procedure;
	begin
		wait for 100 ns;
		wait until rising_edge(bsb_clk);
		bsb_rst <= '0';
		wait for 100 ns;
		clk_on <= TRUE;
		wait for 100 ns;
		-- Random gains in bank 0, two's complement outputs
		for i in bytes'range loop
			uniform(seed1, seed2, r);
			bytes(i) := std_logic_vector(to_unsigned(integer(floor(r * 256.0)), 8));
		end loop;
		write(1, 16#00#);
		fpga_write_ram(bsb_clk, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, 0, bytes);
		wait until rising_edge(clk);
		rst <= '0';
		for setting in 0 to 7 loop -- rounding mode (0 to 2), symmetric saturation, zero on saturation
			if setting mod 4 /= 3 then
				compare <= FALSE;
				write(2, (setting mod 4) + 64 * (setting / 4) + 32 * (setting / 4));
				write(0, 16#21# + (setting mod 3)); -- four_bits, and a left shift of 1 to 3
				wait for 50 * WORDS * CLK_PERIOD;
				wait until rising_edge(clk);
				compare <= TRUE;
				wait for FRAMES * WORDS * CLK_PERIOD;
			end if;
		end loop;
		wait until rising_edge(clk);
		compare <= FALSE;
		assert words_checked > 5 * FRAMES * WORDS and nonzero > words_checked / 2 report "Not enough data checked" severity FAILURE;
		-- The 8-bit mode of the wide scaler uses the 4 LSBs
		cmd_to <= 1;
		write(0, 16#01#);
		wait for 100 * WORDS * CLK_PERIOD;
		assert low_bits > 10 * WORDS report "The wide scaler does not give 8-bit values in the 8-bit mode" severity FAILURE;
		report "SCALER WIDTH TEST PASSED: " & integer'image(words_checked) & " words checked";
		done <= TRUE;
		wait;
	end process ctrl_proc;
end architecture behavior;
