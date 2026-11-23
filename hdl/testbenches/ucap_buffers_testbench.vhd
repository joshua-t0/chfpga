-- Self-checking testbench of ucap with memory in some buffers only (BUFFERS_WITH_MEMORY, MEMORY_PRIMITIVE = "block").
--
-- Two ucap modules get the same data and the same commands: the reference (8 UltraRAM buffers) and the module under
-- test (BUFFERS buffers in block RAM, with register stages in front of the memories). After one capture the two output
-- streams are compared packet for packet. The headers must be equal. The data of a packet must be equal to the data of
-- the reference, or all zeros (a buffer with no memory), and the fraction of the packets with equal data must be
-- BUFFERS / 8. With BUFFERS = 8 the two streams must be equal.
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
		CH0: integer := 5; -- first selected channel
		CH1: integer := 2; -- second selected channel
		BUFFERS: integer := 2;
		MEMORY: string := "block"
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
		variable n_equal, n_zero, base: integer := 0;
	begin
		wait until count(0) = PACKETS * PACKET_BYTES and count(1) = PACKETS * PACKET_BYTES for 20 ms;
		assert count(0) = PACKETS * PACKET_BYTES and count(1) = PACKETS * PACKET_BYTES
			report "Output bytes: " & integer'image(count(0)) & " and " & integer'image(count(1)) & ", expected " & integer'image(PACKETS * PACKET_BYTES) severity FAILURE;
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
			if equal then n_equal := n_equal + 1; else n_zero := n_zero + 1; end if;
		end loop;
		assert n_equal * 8 = PACKETS * BUFFERS report "Packets with data: " & integer'image(n_equal) & ", expected " & integer'image(PACKETS * BUFFERS / 8) severity FAILURE;
		report "UCAP BUFFERS TEST PASSED: mode " & integer'image(MODE) & ", " & integer'image(n_equal) & " packets equal to the reference, " & integer'image(n_zero) & " packets of zeros";
		done <= TRUE;
		wait;
	end process;
end architecture;
