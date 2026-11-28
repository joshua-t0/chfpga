-- Self-checking testbench of ucap with 4 or 2 memories (BUFFERS_WITH_MEMORY).
--
-- Two ucap modules get the same data and the same commands: the reference (8 UltraRAM buffers) and the module under
-- test (BUFFERS memories, in UltraRAM or in block RAM). After one capture the two output streams are compared.
--
-- In each mode the channels have equal parts of the memory. For a mode with BUFFERS channels or fewer, the module
-- under test sends the same packets as the reference: the headers must be equal, the data of the first frames of
-- each channel (2 x BUFFERS / channels) must be equal to the data of the reference, and the data of the other frames
-- must be zeros. For the mode with 2 x BUFFERS channels (one frame of each channel): the module under test sends
-- 8 x BUFFERS packets, and the 4 packets of each channel must be equal (header and data) to the packets of frame 0 of
-- that channel of the reference. For a mode with more channels (mode 0 with 2 memories) all the data must be zeros.
-- With BUFFERS = 8 the two streams must be equal.
--
-- The test ends with the message "UCAP BUFFERS TEST PASSED" or a failure.
library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

library work;
use work.chFPGA_Package.ALL;
use work.tb_package.ALL;

entity ucap_buffers_testbench is
	generic (
		MODE: integer := 1; -- UCAP mode: 0 (8 channels), 1 (4 channels), 2 (2 channels), 3 (1 channel)
		CH0: integer := 5; -- the selected channels
		CH1: integer := 2;
		CH2: integer := 7;
		CH3: integer := 0;
		BUFFERS: integer := 2; -- BUFFERS_WITH_MEMORY of the module under test: 8, 4 or 2
		MEMORY: string := "block" -- "ultra" or "block"
	);
end entity;

architecture sim of ucap_buffers_testbench is
	constant WORDS_PER_FRAME: integer := 2048;
	constant PACKET_BYTES: integer := FRAME_HEADER_BYTE_LENGTH + 8192;
	constant PACKETS: integer := 64; -- 16 frames of 4 packets in one capture
	signal clk, bsb_clk: std_logic := '0';
	signal rst, bsb_rst: std_logic := '1';
	signal done: boolean := FALSE;
	signal tvalid_in, tlast_in: std_logic_vector(0 to 1) := "00";
	signal tdata_in: slv_array(0 to 7)(127 downto 0) := (others => (others => '0'));
	signal cmd_tdata: slv8 := (others => '0');
	signal cmd_tvalid, cmd_tlast: std_logic := '0';
	signal cmd_tready: std_logic;
	type stream is record
		tdata: slv8;
		tvalid, tlast: std_logic;
	end record;
	type stream_array is array (0 to 1) of stream;
	signal o: stream_array; -- 0: reference, 1: under test
	type byte_store is array (0 to 1, 0 to PACKETS * PACKET_BYTES - 1) of slv8;
	shared variable store: byte_store;
	type int2 is array (0 to 1) of integer;
	signal count: int2 := (0, 0);
	constant CHANNELS: integer := 8 / 2 ** MODE; -- channels of the mode
	constant K: integer := 8 / CHANNELS; -- buffers of a channel in the reference
	constant ONE_FRAME_TEST: boolean := CHANNELS = 2 * BUFFERS; -- one frame of each channel, two channels in a memory
	constant NO_DATA: boolean := CHANNELS > 2 * BUFFERS; -- the mode has more channels than the memories can hold
	constant DUT_PACKETS: integer := sel(ONE_FRAME_TEST, 8 * BUFFERS, PACKETS);
begin
	clk <= not clk after 1.333 ns when not done;
	bsb_clk <= not bsb_clk after 5 ns when not done;

	ref0: entity work.ucap
		generic map (FPGA_SERIES => ULTRASCALEPLUS)
		port map (
			s_axis_tdata => tdata_in, s_axis_tvalid => tvalid_in, s_axis_tlast => tlast_in, source_sel_out => open, source_sel_in => "00000000",
			s_axis_clk => clk, rst => rst,
			m_axis_tdata => o(0).tdata, m_axis_tvalid => o(0).tvalid, m_axis_tlast => o(0).tlast, m_axis_tready => '1', m_axis_clk => bsb_clk,
			s_axis_bsb_tdata => cmd_tdata, s_axis_bsb_tvalid => cmd_tvalid, s_axis_bsb_tlast => cmd_tlast, s_axis_bsb_tready => cmd_tready,
			m_axis_bsb_tready => '1', bsb_clk => bsb_clk, bsb_rst => bsb_rst
		);

	dut0: entity work.ucap
		generic map (FPGA_SERIES => ULTRASCALEPLUS, BUFFERS_WITH_MEMORY => BUFFERS, MEMORY_PRIMITIVE => MEMORY)
		port map (
			s_axis_tdata => tdata_in, s_axis_tvalid => tvalid_in, s_axis_tlast => tlast_in, source_sel_out => open, source_sel_in => "00000000",
			s_axis_clk => clk, rst => rst,
			m_axis_tdata => o(1).tdata, m_axis_tvalid => o(1).tvalid, m_axis_tlast => o(1).tlast, m_axis_tready => '1', m_axis_clk => bsb_clk,
			s_axis_bsb_tdata => cmd_tdata, s_axis_bsb_tvalid => cmd_tvalid, s_axis_bsb_tlast => cmd_tlast, s_axis_bsb_tready => open,
			m_axis_bsb_tready => '1', bsb_clk => bsb_clk, bsb_rst => bsb_rst
		);

	stim: process
		variable v: integer;
	begin
		sleep(bsb_clk, 10);
		bsb_rst <= '0';
		sleep(bsb_clk, 10);
		fpga_write_control(bsb_clk, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, 1, CH3 * 8 + CH2);
		fpga_write_control(bsb_clk, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, 0, MODE * 64 + CH1 * 8 + CH0);
		sleep(clk, 20);
		rst <= '0'; -- the capture starts with the first frame after the reset
		sleep(clk, 20);
		for frame in 0 to 19 loop
			for word in 0 to WORDS_PER_FRAME - 1 loop
				for chan in 0 to 7 loop
					for b in 0 to 15 loop -- no byte is zero
						v := (chan * 37 + frame * 11 + word * 3 + b * 7) mod 255 + 1;
						tdata_in(chan)(8 * b + 7 downto 8 * b) <= std_logic_vector(to_unsigned(v, 8));
					end loop;
				end loop;
				tvalid_in(0) <= '1';
				tlast_in(0) <= '1' when word = WORDS_PER_FRAME - 1 else '0';
				sleep(clk);
			end loop;
		end loop;
		tvalid_in(0) <= '0';
		wait;
	end process;

	mon_gen: for k in 0 to 1 generate
		process(bsb_clk) begin
			if rising_edge(bsb_clk) and o(k).tvalid = '1' then
				assert count(k) < PACKETS * PACKET_BYTES report "Too many output bytes" severity FAILURE;
				store(k, count(k)) := o(k).tdata;
				assert (o(k).tlast = '1') = (count(k) mod PACKET_BYTES = PACKET_BYTES - 1) report "Bad position of the end of a packet, stream " & integer'image(k) severity FAILURE;
				count(k) <= count(k) + 1;
			end if;
		end process;
	end generate;

	check: process
		variable equal, zeros: boolean;
		variable n_equal, n_zero, base, ref_base, buf: integer := 0;
	begin
		wait until count(0) = PACKETS * PACKET_BYTES and count(1) = DUT_PACKETS * PACKET_BYTES for 20 ms;
		wait for 200 us; -- no more bytes after the last packet
		assert count(0) = PACKETS * PACKET_BYTES and count(1) = DUT_PACKETS * PACKET_BYTES
			report "Output bytes: " & integer'image(count(0)) & " and " & integer'image(count(1)) & ", expected " & integer'image(PACKETS * PACKET_BYTES) severity FAILURE;
		if ONE_FRAME_TEST then
			for c in 0 to CHANNELS - 1 loop -- channel of the mode (mode 1: the selected channel number c)
				for sub in 0 to 3 loop -- packet of the frame
					base := ((c / 2) * 8 + (c mod 2) * 4 + sub) * PACKET_BYTES; -- memory c / 2, first or second half
					ref_base := (K * c * 8 + sub) * PACKET_BYTES; -- first buffer of channel c of the reference, frame 0
					for b in 0 to PACKET_BYTES - 1 loop
						assert store(1, base + b) = store(0, ref_base + b) report "Channel " & integer'image(c) & " packet " & integer'image(sub) & " byte " & integer'image(b) & " is not equal to the reference" severity FAILURE;
					end loop;
					for b in FRAME_HEADER_BYTE_LENGTH to PACKET_BYTES - 1 loop
						assert store(0, ref_base + b) /= X"00" report "Zero byte in the reference" severity FAILURE;
					end loop;
				end loop;
			end loop;
			report "UCAP BUFFERS TEST PASSED: mode " & integer'image(MODE) & ", one frame of each of the " & integer'image(CHANNELS) & " channels, " & integer'image(DUT_PACKETS) & " packets equal to the reference";
			done <= TRUE;
			wait;
		end if;
		for p in 0 to PACKETS - 1 loop
			base := p * PACKET_BYTES;
			for b in 0 to FRAME_HEADER_BYTE_LENGTH - 1 loop
				assert store(0, base + b) = store(1, base + b) report "Header of packet " & integer'image(p) & " is not equal" severity FAILURE;
			end loop;
			equal := TRUE; zeros := TRUE;
			for b in FRAME_HEADER_BYTE_LENGTH to PACKET_BYTES - 1 loop
				assert store(0, base + b) /= X"00" report "Zero byte in the reference" severity FAILURE;
				if store(1, base + b) /= store(0, base + b) then equal := FALSE; end if;
				if store(1, base + b) /= X"00" then zeros := FALSE; end if;
			end loop;
			assert equal or zeros report "Data of packet " & integer'image(p) & " are not those of the reference and are not zeros" severity FAILURE;
			-- The reference sends the packets of buffer 0 first, then those of buffer 1, ... A channel has K buffers in
			-- the reference; the module under test has data in the first BUFFERS / CHANNELS of them.
			buf := p / (PACKETS / 8);
			assert equal = (not NO_DATA and buf mod K < BUFFERS / CHANNELS) report "Packet " & integer'image(p) & " (buffer " & integer'image(buf) & "): data " & boolean'image(equal) severity FAILURE;
			if equal then n_equal := n_equal + 1; else n_zero := n_zero + 1; end if;
		end loop;
		assert n_equal * 8 = PACKETS * sel(NO_DATA, 0, BUFFERS) report "Packets with data: " & integer'image(n_equal) & ", expected " & integer'image(PACKETS * sel(NO_DATA, 0, BUFFERS) / 8) severity FAILURE;
		report "UCAP BUFFERS TEST PASSED: mode " & integer'image(MODE) & ", " & integer'image(n_equal) & " packets equal to the reference, " & integer'image(n_zero) & " packets of zeros";
		done <= TRUE;
		wait;
	end process;
end architecture;
