-- Self-checking testbench for the switch of the scaler gain bank at the end of a correlator integration.
--
-- Two scalers feed the correlator array (UCORR44_ARRAY with one correlator of 8 inputs, which gets
-- the first bin of each word: the even inputs come from scaler 0 and the odd inputs from scaler 1). A delay line of DELAY clocks stands for the
-- channelizer FIFO and the pipelines between them. The frames are short (BINS / 4 words) so that
-- many integrations can be simulated. The input of the scalers is constant, and the two gain banks
-- have different gains. The testbench looks at the data on the input of the multipliers of the
-- correlator, with the frame counter of the correlator: all the words of an integration, from its
-- first frame to its last frame, must be the same. It fails on an integration with frames of the
-- two banks.
--
-- With frames of the real length (BINS = 8192, and INTEG = 2100 or more for the readout), the
-- testbench also reads the result packets: the products of each integration must have one of two
-- values. The correlator keeps its two accumulator banks apart only with frames of that length, so
-- the products are not checked with shorter frames.
--
-- The test arms the two scalers (switch_at_integration) at many times in the integration, close
-- together around its end. The scalers are armed one after the other while the correlator holds the
-- switch (gain_switch_enable = 0), as the host does: without that, the end of an integration can
-- come between the two armings. It checks that the two scalers switch on the same clock, that each
-- arming gives one switch, and that the armed status follows. Then:
--  - a gain table is written a second time before the switch: the latest table is the one used;
--  - the frame-number mode still switches at its frame number.
--
-- BREAK = 1 delays the signal of the correlator by one frame: the test must then fail. It also
-- fails if DELAY is as long as a frame.
--
-- The test ends with the message "GAIN SWITCH TEST PASSED" or a failure.
--
library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

library work;
use work.chFPGA_Package.ALL;
use work.tb_package.ALL;

entity gain_switch_testbench is
	generic (
		BINS: integer := 1024; -- bins in a frame of a scaler (4 bins in a word). 8192: the real length, and the result packets are checked.
		INTEG: integer := 200; -- frames in an integration. With BINS = 8192, it must be long enough for the readout (2100).
		DELAY: integer range 1 to 1000 := 20; -- clocks from the output of the scalers to the input of the correlator
		DENSE: integer := 60; -- number of armings close to the end of an integration, 3 clocks apart
		COARSE: integer := 12; -- number of armings spread over an integration
		BREAK: integer range 0 to 1 := 0 -- 1: the signal of the correlator comes one frame late (the test must fail)
	);
end gain_switch_testbench;

architecture behavior of gain_switch_testbench is
	constant CLK_PERIOD: time := 2.5 ns;
	constant WORDS: integer := BINS / 4; -- words in a frame
	constant INTEG_CLOCKS: integer := INTEG * WORDS;
	constant TABLE_PAGES: integer := BINS * 2 / 512; -- pages of 512 bytes in the gain table of one bank
	constant PRODUCT_BYTES: integer := 36 * 5;
	constant RECORD_BYTES: integer := 10 + PRODUCT_BYTES;

	signal clk, bsb_clk: std_logic := '0';
	signal clk_on: boolean := FALSE;
	signal rst, bsb_rst, corr_rst: std_logic := '1';
	signal done: boolean := FALSE;

	signal fft_tdata: std_logic_vector(255 downto 0);
	signal fft_tvalid, fft_tlast: std_logic := '0';
	signal word: integer := 0;

	type word_array is array (natural range <>) of std_logic_vector(31 downto 0);
	signal out_tdata: word_array(0 to 1);
	signal out_tvalid, out_tlast: std_logic_vector(0 to 1);
	type delay_array is array (0 to DELAY - 1) of std_logic_vector(65 downto 0);
	signal delay_line: delay_array := (others => (others => '0'));
	signal corr_tdata: std_logic_vector(63 downto 0);
	signal corr_tvalid, corr_tlast: std_logic;

	signal integ_last_frame: std_logic;
	signal last_frame_pipe: std_logic_vector(0 to 1 + BREAK * WORDS) := (others => '0');
	signal last_frame_scaler: std_logic;

	type cmd_array is array (0 to 2) of std_logic_vector(7 downto 0);
	signal cmd_tdata: slv8;
	signal cmd_tvalid, cmd_tlast: std_logic := '0';
	signal cmd_sel: integer range 0 to 2 := 0; -- 0, 1: scalers. 2: correlator
	signal cmd_tvalid_sel, cmd_tready_sel: std_logic_vector(0 to 2);
	signal cmd_tready: std_logic;

	signal z_tdata: slv8;
	signal z_tvalid, z_tlast: std_logic;

	signal bank, armed: std_logic_vector(0 to 1) := "00";
	signal frame_ctr: unsigned(31 downto 0);
	signal switches: integer := 0; -- switches of the gain bank of scaler 0
	constant CHECK_PRODUCTS: boolean := BINS = 8192;
	signal check_on: boolean := TRUE;
	signal patterns, records: integer := 0;
	signal integrations, data_values: integer := 0; -- integrations checked on the input of the multipliers, and values of the data seen
begin
	clk <= not clk after CLK_PERIOD / 2 when clk_on and not done; -- starts after the reset of the registers: the scaler fails on undefined controls
	bsb_clk <= not bsb_clk after 4 ns when not done;

	-- Input of the scalers: a constant in every bin, frames of WORDS words with no gap
	fft_proc: process begin
		wait until rising_edge(clk);
		for i in 0 to 3 loop
			fft_tdata(64 * i + 63 downto 64 * i) <= X"20000000" & X"E0000000"; -- Re, Im: with the gains of the test, the output is 1 - 1j (bank 0) or 2 - 2j (bank 1)
		end loop;
		fft_tvalid <= not rst;
		fft_tlast <= to_std_logic(word = WORDS - 1);
		if rst then
			word <= 0;
		else
			word <= (word + 1) mod WORDS;
		end if;
	end process fft_proc;

	scaler_gen: for i in 0 to 1 generate
		scaler0: entity work.scaler
			generic map (
				FFT_BITS_PER_BIN   => 32 + 32,
				FFT_BINS_PER_WORD  => 4,
				FFT_BINS_PER_FRAME => BINS,
				USE_COMPLEX_GAINS  => FALSE,
				COEFF_BITS_PER_BIN => 16,
				OUT_BITS_PER_BIN   => 4 + 4,
				CAP_BITS_PER_WORD  => 128
			)
			port map (
				s_axis_in_tdata  => fft_tdata,
				s_axis_in_tvalid => fft_tvalid,
				s_axis_in_tlast  => fft_tlast,
				s_axis_in_tuser  => "00",

				m_axis_out_tdata  => out_tdata(i),
				m_axis_out_tvalid => out_tvalid(i),
				m_axis_out_tlast  => out_tlast(i),

				clk   => clk,
				reset => rst,

				integ_last_frame => last_frame_scaler,

				s_axis_bsb_tdata  => cmd_tdata,
				s_axis_bsb_tvalid => cmd_tvalid_sel(i),
				s_axis_bsb_tlast  => cmd_tlast,
				s_axis_bsb_tready => cmd_tready_sel(i),
				m_axis_bsb_tready => '1',
				bsb_clk => bsb_clk,
				bsb_rst => bsb_rst
			);

		-- Internal state of the scalers
		probe_proc: process
			alias s_bank is <<signal scaler0.current_gain_bank: std_logic>>;
			alias s_status is <<signal scaler0.status_bytes: slv8_array(0 to 18)>>;
		begin
			wait until rising_edge(clk);
			bank(i) <= s_bank;
			armed(i) <= s_status(18)(0);
		end process probe_proc;
	end generate scaler_gen;

	frame_proc: process
		alias s_frame_ctr is <<signal scaler_gen(0).scaler0.frame_ctr: unsigned(31 downto 0)>>;
	begin
		wait until rising_edge(clk);
		frame_ctr <= s_frame_ctr;
	end process frame_proc;

	cmd_gen: for i in 0 to 2 generate
		cmd_tvalid_sel(i) <= cmd_tvalid when cmd_sel = i else '0';
	end generate cmd_gen;
	cmd_tready <= cmd_tready_sel(cmd_sel);

	-- The channelizer FIFO and the pipelines: DELAY clocks. Then the wiring of the corner-turn engine of level 1:
	-- a correlator gets one bin of each word, from the 8 inputs.
	delay_proc: process begin
		wait until rising_edge(clk);
		delay_line(0) <= out_tlast(0) & out_tvalid(0) & out_tdata(0) & out_tdata(1);
		for i in 1 to DELAY - 1 loop
			delay_line(i) <= delay_line(i - 1);
		end loop;
	end process delay_proc;

	corr_in_proc: process(all)
		variable d: std_logic_vector(65 downto 0);
		variable lsb: integer;
	begin
		d := delay_line(DELAY - 1);
		corr_tlast <= d(65);
		corr_tvalid <= d(64);
		for ch in 0 to 7 loop
			lsb := 56 - 8 * ch;
			if ch mod 2 = 0 then
				corr_tdata(lsb + 7 downto lsb) <= d(63 downto 56);
			else
				corr_tdata(lsb + 7 downto lsb) <= d(31 downto 24);
			end if;
		end loop;
	end process corr_in_proc;

	corr0: entity work.ucorr44_array
		generic map (
			PLATFORM_TYPE       => CRS,
			NCORR               => 1,
			NCHAN               => 8,
			NBINS_PER_CORR      => WORDS,
			SOFT_NINTEG         => INTEG,
			GAIN_SWITCH_SUPPORT => TRUE,
			READOUT_BINS        => (0 => 0),
			INPUT_WIDTH         => 64
		)
		port map (
			s_axis_data_tdata  => corr_tdata,
			s_axis_data_tvalid => corr_tvalid,
			s_axis_data_tlast  => corr_tlast,

			integ_last_frame => integ_last_frame,

			clk => clk,
			rst => corr_rst,

			m_axis_data_tdata  => z_tdata,
			m_axis_data_tvalid => z_tvalid,
			m_axis_data_tlast  => z_tlast,
			m_axis_data_tready => '1',
			out_clk            => clk, -- a fast readout, since the frames are short

			s_axis_bsb_tdata  => cmd_tdata,
			s_axis_bsb_tvalid => cmd_tvalid_sel(2),
			s_axis_bsb_tlast  => cmd_tlast,
			s_axis_bsb_tready => cmd_tready_sel(2),
			m_axis_bsb_tready => '1',
			bsb_clk => bsb_clk,
			bsb_rst => bsb_rst
		);

	-- The pipeline from the correlator to the scalers, as in chfpga.vhd
	pipe_proc: process begin
		wait until rising_edge(clk);
		last_frame_pipe <= integ_last_frame & last_frame_pipe(0 to last_frame_pipe'RIGHT - 1);
	end process pipe_proc;
	last_frame_scaler <= last_frame_pipe(last_frame_pipe'RIGHT);

	-- The two scalers switch on the same clock. In the integration mode, a switch comes with the signal of the correlator.
	switch_proc: process
		variable prev: std_logic_vector(0 to 1) := "00";
	begin
		wait until rising_edge(clk);
		if rst = '0' and bank /= prev then
			assert bank = not prev report "The two scalers did not switch on the same clock" severity FAILURE;
			switches <= switches + 1;
		end if;
		prev := bank;
	end process switch_proc;

	-- The data on the input of the multipliers, with the frame counter of the correlator: an integration has one value only
	data_proc: process
		alias xy_tdata is <<signal corr0.corr_gen(0).corr0.cmac_gen.corr0.s_axis_xy_tdata: slv_array(0 to 35)(15 downto 0)>>;
		alias xy_tvalid is <<signal corr0.corr_gen(0).corr0.cmac_gen.corr0.s_axis_xy_tvalid: std_logic>>;
		alias xy_tlast is <<signal corr0.corr_gen(0).corr0.cmac_gen.corr0.s_axis_xy_tlast: std_logic>>;
		alias frame is <<signal corr0.corr_gen(0).corr0.cmac_gen.corr0.ctrl_blk.frame: unsigned(15 downto 0)>>;
		variable first, a, b: slv_array(0 to 35)(15 downto 0);
		variable have_first: boolean := FALSE;
		variable n_values: integer := 0;
		variable complete: boolean := FALSE; -- the integration in progress was seen from its first frame
	begin
		wait until rising_edge(clk);
		if corr_rst = '0' and xy_tvalid = '1' and check_on then
			if not have_first then
				first := xy_tdata;
				have_first := TRUE;
				complete := frame = 0;
			end if;
			assert xy_tdata = first report "An integration has frames of the two gain banks (frame " & integer'image(to_integer(frame)) & " of the integration)" severity FAILURE;
			if xy_tlast = '1' and frame = INTEG - 1 then -- end of the integration
				if complete then
					integrations <= integrations + 1;
					if n_values = 0 or (first /= a and n_values = 1) then
						if n_values = 0 then a := first; else b := first; end if;
						n_values := n_values + 1;
					end if;
					assert first = a or first = b report "A third value of the data: integration " & integer'image(integrations) & ", after " & integer'image(switches) & " switches, word " & to_hstring(first(0)) & ", was " & to_hstring(a(0)) & " and " & to_hstring(b(0)) severity FAILURE;
					data_values <= n_values;
				end if;
				have_first := FALSE;
			end if;
		end if;
	end process data_proc;

	-- Result packets of the correlator: records of a 10-byte header and 36 products of 5 bytes
	result_proc: process
		type pattern_array is array (0 to 3) of slv8_array(0 to PRODUCT_BYTES - 1);
		variable known: pattern_array;
		variable n_known: integer := 0;
		variable rec: slv8_array(0 to RECORD_BYTES - 1);
		variable n: integer := 0;
		variable corr, bin, found: integer;
		variable ts, last_ts: unsigned(47 downto 0) := (others => '1');
		variable last_found: integer := -1;
	begin
		wait until rising_edge(clk);
		if z_tvalid then
			rec(n) := z_tdata;
			n := n + 1;
			if n = RECORD_BYTES then
				n := 0;
				assert rec(0) = X"CF" report "Bad first byte of a result record" severity FAILURE;
				corr := to_integer(unsigned(rec(1)(7 downto 3)));
				bin := to_integer(unsigned(rec(1)(2 downto 0)) & unsigned(rec(2)));
				ts := unsigned(rec(4)) & unsigned(rec(5)) & unsigned(rec(6)) & unsigned(rec(7)) & unsigned(rec(8)) & unsigned(rec(9));
				assert rec(3)(0) = '0' or not CHECK_PRODUCTS report "Correlator overrun" severity FAILURE;
				-- Not checked: the first integration (it starts at the reset), and the bin that each correlator gives to the readout
				if CHECK_PRODUCTS and check_on and ts /= 0 and bin /= corr then
					found := -1;
					for i in 0 to n_known - 1 loop
						if known(i) = rec(10 to RECORD_BYTES - 1) then
							found := i;
						end if;
					end loop;
					if found < 0 then
						assert n_known < 2 report "An integration (timestamp " & integer'image(to_integer(ts)) & ", correlator " & integer'image(corr) & ", bin " & integer'image(bin) &
							") has products that are not those of one gain bank" severity FAILURE;
						found := n_known;
						known(n_known) := rec(10 to RECORD_BYTES - 1);
						n_known := n_known + 1;
						patterns <= n_known;
					end if;
					assert ts /= last_ts or found = last_found report "The records of one integration do not have the same products" severity FAILURE;
					last_ts := ts;
					last_found := found;
					records <= records + 1;
				end if;
			end if;
			assert z_tlast = '0' or n = 0 report "A result frame does not end at the end of a record" severity FAILURE;
		end if;
	end process result_proc;

	ctrl_proc: process
		variable target: integer := 0; -- gain bank in use after the next switch
		variable expected_switches: integer := 0;
		variable offset: integer;
		variable f: integer;

		procedure write(sel, addr, data: integer; nbytes: integer := 1) is
		begin
			cmd_sel <= sel;
			wait until rising_edge(bsb_clk);
			fpga_write_control(bsb_clk, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, addr, data, nbytes);
		end procedure;

		-- Control byte 1 of a scaler: the page of the gain table for the BSB (the bank), and the next gain bank
		procedure write_byte1(sel, page, next_bank: integer) is
		begin
			-- Two's complement outputs (bit 6 = 0), as the correlator takes them. Page: bits 3:0, then bit 5 and bit 7.
			write(sel, 1, 128 * ((page / 32) mod 2) + 32 * ((page / 16) mod 2) + 16 * next_bank + page mod 16);
		end procedure;

		-- Writes the same gain in all the bins of a bank. The next gain bank does not change.
		procedure write_table(sel, table_bank, gain_byte, next_bank: integer) is
			variable bytes: slv8_array(0 to 511) := (others => std_logic_vector(to_unsigned(gain_byte, 8)));
		begin
			for p in 0 to TABLE_PAGES - 1 loop
				write_byte1(sel, table_bank * TABLE_PAGES + p, next_bank);
				fpga_write_ram(bsb_clk, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, 0, bytes);
			end loop;
		end procedure;

		procedure wait_clocks(n: integer) is
		begin
			for i in 1 to n loop
				wait until rising_edge(clk);
			end loop;
		end procedure;

		-- Arms the two scalers and waits for the switch. As the host does: the correlator does not let the scalers
		-- switch while they are armed one after the other, so that they switch at the end of the same integration.
		procedure switch is
		begin
			target := 1 - target;
			write(2, 3, 16#40#); -- no gain_switch_enable
			write_byte1(0, 0, target);
			write_byte1(1, 0, target);
			write(2, 3, 16#60#); -- gain_switch_enable
			expected_switches := expected_switches + 1;
			wait until rising_edge(clk) and armed = "11" for 1 us;
			assert armed = "11" or switches = expected_switches report "The scalers are not armed" severity FAILURE;
			wait until switches = expected_switches for (2 * INTEG_CLOCKS + 1000) * CLK_PERIOD;
			assert switches = expected_switches report "No switch at the end of the integration" severity FAILURE;
			wait_clocks(20);
			assert armed = "00" report "The scalers are armed after the switch" severity FAILURE;
		end procedure;
	begin
		wait for 100 ns;
		wait until rising_edge(bsb_clk);
		bsb_rst <= '0';
		wait for 100 ns;
		clk_on <= TRUE;
		wait for 100 ns;
		-- Gain tables: bank 0 and bank 1 have different gains. Integration mode, 4-bit output.
		for s in 0 to 1 loop
			write_table(s, 0, 16#40#, 0);
			write_table(s, 1, 16#80#, 0);
			write_byte1(s, 0, 0);
			write(s, 13, 16#81#); -- switch_at_integration, left shift of bank 1
		end loop;
		wait until rising_edge(clk);
		rst <= '0';
		wait_clocks(4 * WORDS);
		corr_rst <= '0';
		wait_clocks(INTEG_CLOCKS / 2);
		assert switches = 0 report "A switch with no arming" severity FAILURE;

		-- Armings at many times in the integration. The first ones are close to its end, 3 clocks apart.
		for k in 0 to DENSE + COARSE - 1 loop
			if k < DENSE then
				offset := INTEG_CLOCKS - 120 + 3 * k; -- from the last switch: around the end of the next integration
			else
				offset := (k - DENSE) * INTEG_CLOCKS / COARSE + 7;
			end if;
			wait_clocks(offset);
			switch;
		end loop;

		-- A second write of the table before the switch: the latest table is used
		wait_clocks(100);
		write_table(0, 1 - target, 16#C0#, target);
		write_table(1, 1 - target, 16#C0#, target);
		write_byte1(0, 0, 1 - target); -- armed with a table that must not be used
		write_byte1(1, 0, 1 - target);
		wait_clocks(50);
		write_table(0, 1 - target, 16#40# + 16#40# * (1 - target), 1 - target);
		write_table(1, 1 - target, 16#40# + 16#40# * (1 - target), 1 - target);
		assert switches = expected_switches report "The table writes took more than one integration: make INTEG longer" severity FAILURE;
		target := 1 - target;
		expected_switches := expected_switches + 1;
		wait until switches = expected_switches for (INTEG_CLOCKS + 1000) * CLK_PERIOD;
		assert switches = expected_switches report "No switch after the second write of the table" severity FAILURE;

		-- Three more integrations, and the time for their readout
		wait_clocks(4 * INTEG_CLOCKS);
		assert switches = expected_switches report "A switch with no arming" severity FAILURE;
		assert data_values = 2 report "The data of the two gain banks were not seen: " & integer'image(data_values) severity FAILURE;
		assert integrations >= DENSE + COARSE report "Not enough integrations: " & integer'image(integrations) severity FAILURE;
		if CHECK_PRODUCTS then
			assert patterns = 2 report "The products of the two gain banks were not seen: " & integer'image(patterns) severity FAILURE;
			assert records > 2000 * (DENSE + COARSE) report "Not enough result records: " & integer'image(records) severity FAILURE;
		end if;

		-- Frame-number mode: the switch comes at the end of the frame with the given number
		check_on <= FALSE;
		f := to_integer(frame_ctr) + 50;
		for s in 0 to 1 loop
			write(s, 6, f, 4);
			write(s, 2, 16#12#); -- synchronize_gain_bank_switch
			write(s, 13, 16#01#); -- no switch_at_integration
		end loop;
		target := 1 - target;
		write_byte1(0, 0, target);
		write_byte1(1, 0, target);
		assert to_integer(frame_ctr) < f report "The frame number of the switch is past" severity FAILURE;
		wait until switches = expected_switches + 1 for 100 * WORDS * CLK_PERIOD;
		assert switches = expected_switches + 1 report "No switch in the frame-number mode" severity FAILURE;
		wait until rising_edge(clk);
		assert to_integer(frame_ctr) = f + 1 report "The switch of the frame-number mode came at frame " & integer'image(to_integer(frame_ctr)) & ", expected " & integer'image(f + 1) severity FAILURE;

		report "GAIN SWITCH TEST PASSED: " & integer'image(switches) & " switches, " & integer'image(integrations) & " integrations checked, " & integer'image(records) & " result records checked";
		done <= TRUE;
		wait;
	end process ctrl_proc;
end architecture behavior;
