-- Self-checking testbench for the switch of the scaler gain bank at a frame number.
--
-- One scaler. The testbench selects the other gain bank in each mode and looks at the frame at
-- which the bank changes, at the status register that has that frame (gain_switch_frame) and at
-- the late flag (gain_switch_late):
--
--  1. Unsynchronised mode: the bank changes at the end of the frame in progress. No late flag.
--  2. Frame-number mode with a target that is ahead: the bank changes at the end of the target frame,
--     and not before. No late flag. gain_switch_frame is the target.
--  3. Frame-number mode with a target that is past when the bank is selected: the bank changes at the
--     end of the frame in progress. Late flag. gain_switch_frame is that frame. The host clears the flag.
--  4. An old target that is not written again: the same as case 3.
--
-- With WRAP = 1, the frame counter starts 30 frames before its limit and the target is frame 5: the
-- bank changes at the end of frame 5, after the counter went back to zero, and not before.
--
-- The test ends with the message "SCALER GAIN SWITCH TEST PASSED" or a failure.
--
library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

library work;
use work.chFPGA_Package.ALL;
use work.tb_package.ALL;

entity scaler_gain_switch_testbench is
	generic (
		WRAP: integer range 0 to 1 := 0
	);
end scaler_gain_switch_testbench;

architecture behavior of scaler_gain_switch_testbench is
	constant CLK_PERIOD: time := 2.5 ns;
	constant WORDS: integer := 64; -- words in a frame
	constant FRAME_TIME: time := WORDS * CLK_PERIOD;
	function reset_value return std_logic_vector is
	begin
		if WRAP = 1 then
			return X"FFFFFFE2"; -- 2^32 - 30
		end if;
		return X"00000000";
	end function;
	signal clk, bsb_clk: std_logic := '0';
	signal clk_on: boolean := FALSE;
	signal rst, bsb_rst: std_logic := '1';
	signal done: boolean := FALSE;
	signal fft_tvalid, fft_tlast: std_logic := '0';
	signal cmd_tdata: slv8;
	signal cmd_tvalid, cmd_tlast: std_logic := '0';
	signal cmd_tready: std_logic;
	-- State of the scaler, one clock late
	signal bank, late: std_logic := '0';
	signal frame_ctr, switch_frame: unsigned(31 downto 0) := (others => '0');
	signal changes: integer := 0;
	signal change_frame: unsigned(31 downto 0) := (others => '0'); -- frame counter just after the last change of the bank
begin
	clk <= not clk after CLK_PERIOD / 2 when clk_on and not done;
	bsb_clk <= not bsb_clk after 4 ns when not done;

	fft_proc: process
		variable word: integer := 0;
	begin
		wait until rising_edge(clk);
		fft_tvalid <= not rst;
		fft_tlast <= to_std_logic(word = WORDS - 1);
		if rst then
			word := 0;
		else
			word := (word + 1) mod WORDS;
		end if;
	end process fft_proc;

	scaler0: entity work.scaler
		generic map (FFT_BITS_PER_BIN => 64, FFT_BINS_PER_WORD => 4, FFT_BINS_PER_FRAME => 4 * WORDS, USE_COMPLEX_GAINS => FALSE, COEFF_BITS_PER_BIN => 16,
		             OUT_BITS_PER_BIN => 4 + 4, CAP_BITS_PER_WORD => 128, FRAME_CTR_RESET_VALUE => reset_value)
		port map (
			s_axis_in_tdata => (255 downto 0 => '0'), s_axis_in_tvalid => fft_tvalid, s_axis_in_tlast => fft_tlast, s_axis_in_tuser => "00",
			clk => clk, reset => rst,
			s_axis_bsb_tdata => cmd_tdata, s_axis_bsb_tvalid => cmd_tvalid, s_axis_bsb_tlast => cmd_tlast, s_axis_bsb_tready => cmd_tready,
			m_axis_bsb_tready => '1', bsb_clk => bsb_clk, bsb_rst => bsb_rst
		);

	probe_proc: process
		alias s_bank is <<signal scaler0.current_gain_bank: std_logic>>;
		alias s_frame_ctr is <<signal scaler0.frame_ctr: unsigned(31 downto 0)>>;
		alias s_status is <<signal scaler0.status_bytes: slv8_array(0 to 22)>>;
		variable prev: std_logic := '0';
	begin
		wait until rising_edge(clk);
		bank <= s_bank;
		frame_ctr <= s_frame_ctr;
		late <= s_status(18)(1);
		switch_frame <= unsigned(s_status(19)) & unsigned(s_status(20)) & unsigned(s_status(21)) & unsigned(s_status(22));
		if rst = '0' and s_bank /= prev then
			changes <= changes + 1;
			change_frame <= s_frame_ctr;
		end if;
		prev := s_bank;
	end process probe_proc;

	ctrl_proc: process
		variable target: unsigned(31 downto 0);
		variable n, to_bank: integer := 0;

		procedure write(addr, data: integer; nbytes: integer := 1) is
		begin
			wait until rising_edge(bsb_clk);
			fpga_write_control(bsb_clk, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, addr, data, nbytes);
		end procedure;

		procedure write_target(t: unsigned(31 downto 0)) is
		begin
			for i in 0 to 3 loop -- control bytes 6 to 9, MSB first, one byte at a time as the host does
				write(6 + i, to_integer(t(31 - 8 * i downto 24 - 8 * i)));
			end loop;
		end procedure;

		-- Selects the other bank (control byte 1, bit 4)
		procedure select_other_bank is
		begin
			to_bank := 1 - to_bank;
			n := changes;
			write(1, 16 * to_bank);
		end procedure;

		-- The bank changed one time, at the end of frame ``at``; flag and register as given
		procedure check(at: unsigned(31 downto 0); expect_late: std_logic; what: string) is
		begin
			wait for 3 * FRAME_TIME;
			wait until rising_edge(clk);
			assert changes = n + 1 report what & ": " & integer'image(changes - n) & " changes of the bank" severity FAILURE;
			assert change_frame = at + 1 report what & ": the bank changed at the end of frame " & to_hstring(change_frame - 1) & ", expected " & to_hstring(at) severity FAILURE;
			assert switch_frame = at report what & ": gain_switch_frame is " & to_hstring(switch_frame) & ", expected " & to_hstring(at) severity FAILURE;
			assert late = expect_late report what & ": gain_switch_late is " & std_logic'image(late) severity FAILURE;
		end procedure;
	begin
		wait for 100 ns;
		wait until rising_edge(bsb_clk);
		bsb_rst <= '0';
		wait for 100 ns;
		clk_on <= TRUE;
		wait for 100 ns;

		if WRAP = 1 then
			-- The counter is 30 frames before its limit. Target: frame 5, after the limit.
			write(2, 16#12#); -- synchronize_gain_bank_switch
			write_target(X"00000005");
			select_other_bank;
			wait until rising_edge(clk);
			rst <= '0';
			wait until rising_edge(clk) and frame_ctr = X"FFFFFFFF";
			assert changes = 0 report "The bank changed before the limit of the counter" severity FAILURE;
			wait until rising_edge(clk) and frame_ctr = X"00000005"; -- the target frame is in progress
			assert changes = 0 report "The bank changed before the target frame, which is after the limit of the counter" severity FAILURE;
			check(X"00000005", '0', "Target after the limit of the counter");
			report "SCALER GAIN SWITCH TEST PASSED (counter limit)";
			done <= TRUE;
			wait;
		end if;

		wait until rising_edge(clk);
		rst <= '0';
		wait for 10 * FRAME_TIME;

		-- 1. Unsynchronised mode (the reset state)
		select_other_bank;
		wait for 2 * FRAME_TIME;
		wait until rising_edge(clk);
		check(change_frame - 1, '0', "Unsynchronised mode");
		assert changes = 1 report "Unsynchronised mode: no change of the bank" severity FAILURE;

		-- 2. A target that is ahead
		write(2, 16#12#); -- synchronize_gain_bank_switch
		wait until rising_edge(clk);
		target := frame_ctr + 40;
		write_target(target);
		select_other_bank;
		wait until rising_edge(clk) and frame_ctr = target; -- the target frame is in progress
		assert changes = n report "The bank changed before the target frame" severity FAILURE;
		check(target, '0', "Target ahead");

		-- 3. A target that is past when the bank is selected
		wait until rising_edge(clk);
		target := frame_ctr + 2;
		write_target(target);
		wait for 10 * FRAME_TIME;
		select_other_bank;
		wait for 2 * FRAME_TIME;
		wait until rising_edge(clk);
		assert change_frame - 1 > target report "Late selection: the test did not select the bank after the target" severity FAILURE;
		check(change_frame - 1, '1', "Late selection");
		write(13, 16#41#); -- gain_switch_late_reset
		write(13, 16#01#);
		wait for FRAME_TIME;
		assert late = '0' report "gain_switch_late is not cleared" severity FAILURE;

		-- 4. The old target, not written again
		select_other_bank;
		wait for 2 * FRAME_TIME;
		wait until rising_edge(clk);
		check(change_frame - 1, '1', "Old target");
		write(13, 16#41#);
		write(13, 16#01#);

		-- 5. Unsynchronised mode again: no late flag
		write(2, 16#02#);
		select_other_bank;
		wait for 2 * FRAME_TIME;
		wait until rising_edge(clk);
		check(change_frame - 1, '0', "Unsynchronised mode, second time");

		report "SCALER GAIN SWITCH TEST PASSED: " & integer'image(changes) & " changes of the bank";
		done <= TRUE;
		wait;
	end process ctrl_proc;
end architecture behavior;
