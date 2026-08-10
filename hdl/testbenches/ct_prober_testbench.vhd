----------------------------------------------------------------------------------
-- Company: McGill University
-- Engineer: V. Bidula
--
-- Create Date: 2026-08-06
-- Design Name: chFPGA
-- Module Name: ct_prober_testbench
-- Project Name: HIRAX
-- Description: Self-checking testbench for the ct_prober corner-turn output capture probe.
--
-- The testbench emulates the corner-turn output bus: 8 lanes of 32-bit packetized streams
-- concatenated with lane 0 at the MSBs (as flattened by bct_engine), sharing one
-- TVALID/TLAST. Each lane word encodes its lane number, packet number and word index
-- (lane(8) & packet(8) & word_index(16)), so any lane-mux or lane-reversal bug is directly
-- visible in the captured payload.
--
-- The DUT is configured through its BSB interface using the tb_package helpers, which drive
-- the bsb_regs command stream directly (no router or bsb_master is needed). Reply packets
-- from bsb_regs start with a dummy byte; the reply monitor therefore keeps the LAST byte of
-- each reply, which is the data byte for single-byte reads.
--
-- Checks performed:
--   1. Parked by default: no capture output while capture_en = 0.
--   2. Capture packet format: 0xA2 cookie, burst index in STREAM_ID(15:12), lane number in
--      STREAM_ID(3:0), zero flags, correct length, full payload compare (lane/packet/word).
--   3. Burst behaviour: both packets of a burst share the timestamp; packet numbers are
--      consecutive; timestamps of consecutive bursts differ by the capture period.
--   4. Live lane switch between bursts, and current_lane status readback.
--   5. Overrun detection when triggers occur while a readout is stalled, and its clearing
--      by soft_reset.
--   6. Parked again: an in-flight burst completes but no new bursts trigger.
--
-- The simulation ends with "ct_prober_testbench PASSED" and std.env.finish on success, or a
-- failed assertion otherwise.
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;
use std.env.finish;

library work;
use work.chFPGA_Package.ALL;
use work.tb_package.ALL;

entity ct_prober_testbench is
end entity ct_prober_testbench;

architecture sim of ct_prober_testbench is

	constant IN_CLK_PERIOD: time := 4.096 ns; -- 244 MHz corner-turn clock
	constant OUT_CLK_PERIOD: time := 8 ns; -- 125 MHz capture/BSB clock (out_clk = bsb_clk, as on ICE)

	constant NUMBER_OF_LANES: integer := 8;
	constant WORDS_PER_PACKET: integer := 16; -- small CT packets keep the simulation fast; the DUT is packet-size-agnostic
	constant PACKET_GAP: integer := 4; -- idle in_clk cycles between CT packets

	-- Capture period register value: capture every PERIOD+1 packets. Must exceed the burst
	-- readout time (2 packets x 74 bytes at 125 MHz is about 15 packet durations) or every
	-- burst would overrun the previous readout.
	constant PERIOD: integer := 24;

	constant CAPTURE_BYTES: integer := FRAME_HEADER_BYTE_LENGTH + 4 * WORDS_PER_PACKET; -- output packet length

	-- Clocks and resets
	signal in_clk: std_logic := '0';
	signal out_clk: std_logic := '0';
	signal in_reset: std_logic := '1';
	signal bsb_rst: std_logic := '1';

	-- Corner-turn bus emulation
	signal in_tdata: std_logic_vector(NUMBER_OF_LANES * 32 - 1 downto 0) := (others => '0');
	signal in_tvalid: std_logic := '0';
	signal in_tlast: std_logic := '0';

	-- Capture output stream
	signal out_tdata: std_logic_vector(7 downto 0);
	signal out_tvalid: std_logic;
	signal out_tlast: std_logic;
	signal out_tready: std_logic;
	signal rx_enable: std_logic := '1';

	-- BSB command/reply streams
	signal cmd_tdata: std_logic_vector(7 downto 0) := (others => '0');
	signal cmd_tvalid: std_logic := '0';
	signal cmd_tlast: std_logic := '0';
	signal cmd_tready: std_logic;
	signal rply_tdata: std_logic_vector(7 downto 0);
	signal rply_tvalid: std_logic;
	signal rply_tlast: std_logic;

	-- Stimulus bookkeeping
	signal stim_run: boolean := false;
	signal packets_sent: integer := 0;

	-- Received capture packets
	signal rx_pkt: slv8_array(0 to 127) := (others => (others => '0'));
	signal rx_len: integer := 0;
	signal rx_count: integer := 0;

	-- Received BSB replies (last byte of the most recent reply packet)
	signal reply_data: std_logic_vector(7 downto 0) := (others => '0');
	signal reply_count: integer := 0;

begin

	in_clk  <= not in_clk after IN_CLK_PERIOD / 2;
	out_clk <= not out_clk after OUT_CLK_PERIOD / 2;

	out_tready <= rx_enable;

	dut: entity work.ct_prober
		generic map (
			FPGA_SERIES     => KINTEX7,
			NUMBER_OF_LANES => NUMBER_OF_LANES,
			SIM             => TRUE
		)
		port map (
			in_tdata  => in_tdata,
			in_tvalid => in_tvalid,
			in_tlast  => in_tlast,
			in_clk    => in_clk,
			in_reset  => in_reset,

			out_tdata  => out_tdata,
			out_tvalid => out_tvalid,
			out_tlast  => out_tlast,
			out_tready => out_tready,
			out_clk    => out_clk,

			s_axis_bsb_tdata  => cmd_tdata,
			s_axis_bsb_tvalid => cmd_tvalid,
			s_axis_bsb_tlast  => cmd_tlast,
			s_axis_bsb_tready => cmd_tready,
			m_axis_bsb_tdata  => rply_tdata,
			m_axis_bsb_tvalid => rply_tvalid,
			m_axis_bsb_tlast  => rply_tlast,
			m_axis_bsb_tready => '1',
			bsb_clk           => out_clk,
			bsb_rst           => bsb_rst
		);

	----------------------------------------------------------------
	-- Corner-turn bus stimulus: continuously sends CT packets on all 8 lanes while stim_run.
	-- Lane 0 is placed at the MSBs of in_tdata, modeling the bct_engine output lane reversal.
	----------------------------------------------------------------
	stim_proc: process

		procedure send_ct_packet (
			packet_number : in integer
		) is
		begin

			for w in 0 to WORDS_PER_PACKET - 1 loop
				for lane in 0 to NUMBER_OF_LANES - 1 loop
					in_tdata(32 * (NUMBER_OF_LANES - 1 - lane) + 31 downto 32 * (NUMBER_OF_LANES - 1 - lane)) <= to_slv(lane, 8) & to_slv(packet_number, 8) & to_slv(w, 16);
				end loop;

				in_tvalid <= '1';
				in_tlast  <= to_std_logic(w = WORDS_PER_PACKET - 1);
				wait until in_clk = '1';
			end loop;

			in_tvalid <= '0';
			in_tlast  <= '0';

		end procedure send_ct_packet;

	begin
		if not stim_run then
			wait until stim_run;
		end if;
		send_ct_packet(packets_sent mod 256);
		packets_sent <= packets_sent + 1;
		sleep(in_clk, PACKET_GAP);
	end process;

	----------------------------------------------------------------
	-- Capture output receiver: collects bytes into rx_pkt, bumps rx_count on TLAST.
	----------------------------------------------------------------
	rx_proc: process

		variable idx: integer := 0;

	begin
		wait until out_clk = '1';
		if out_tvalid = '1' and out_tready = '1' then
			assert idx < CAPTURE_BYTES
				report "capture packet longer than expected (missing TLAST?)"
				severity failure;
			rx_pkt(idx) <= out_tdata;
			idx := idx + 1;
			if out_tlast = '1' then
				rx_len <= idx;
				rx_count <= rx_count + 1;
				idx := 0;
			end if;
		end if;
	end process;

	----------------------------------------------------------------
	-- BSB reply monitor: keeps the last byte of each reply packet (the data byte for
	-- single-byte reads; the first reply byte is a dummy inserted by bsb_regs).
	----------------------------------------------------------------
	reply_proc: process
	begin
		wait until out_clk = '1';
		if rply_tvalid = '1' then
			reply_data <= rply_tdata;
			if rply_tlast = '1' then
				reply_count <= reply_count + 1;
			end if;
		end if;
	end process;

	----------------------------------------------------------------
	-- Global timeout watchdog
	----------------------------------------------------------------
	timeout_proc: process
	begin
		wait for 1 ms;
		assert FALSE
			report "ct_prober_testbench TIMEOUT"
			severity failure;
	end process;

	----------------------------------------------------------------
	-- Main test sequencer
	----------------------------------------------------------------
	main_proc: process

		variable t0, t1: unsigned(47 downto 0);
		variable base_pkt: integer;
		variable cnt: integer;
		variable baseline: integer;
		variable status: std_logic_vector(7 downto 0);

		-- Reads one status/control byte through the BSB interface and returns it.

		procedure read_byte (
			addr  : in integer;
			value : out std_logic_vector(7 downto 0)
		) is
		begin

			fpga_read(out_clk, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, addr);
			wait on reply_count;                            -- one reply packet completes per read command
			value := reply_data;

		end procedure read_byte;

		-- Checks the header and full payload of the most recently received capture packet.

		procedure check_capture_packet (
			lane      : in integer;
			burst_idx : in integer
		) is
		begin

			assert rx_len = CAPTURE_BYTES
				report "bad capture length: got " & str(rx_len) & ", expected " & str(CAPTURE_BYTES)
				severity failure;
			assert rx_pkt(0) = X"A2"
				report "bad cookie byte"
				severity failure;
			assert rx_pkt(1) = to_slv(burst_idx * 16, 8)    -- STREAM_ID(15:12) = burst index, (11:8) = 0
				report "bad STREAM_ID high byte (burst index)"
				severity failure;
			assert rx_pkt(2) = X"A" & '0' & to_slv(lane, 3) -- STREAM_ID(7:4) = software 0xA, (3:0) = lane
				report "bad STREAM_ID low byte (lane number)"
				severity failure;
			assert rx_pkt(3) = X"00"
				report "bad flags byte"
				severity failure;
			for w in 0 to WORDS_PER_PACKET - 1 loop
				assert rx_pkt(10 + 4 * w) = to_slv(lane, 8)
					report "bad payload lane byte at word " & str(w)
					severity failure;
				assert rx_pkt(12 + 4 * w) = to_slv(w / 256, 8) and rx_pkt(13 + 4 * w) = to_slv(w mod 256, 8)
					report "bad payload word index at word " & str(w)
					severity failure;
			end loop;

		end procedure check_capture_packet;

	begin
		-- Release resets
		sleep(out_clk, 10);
		bsb_rst <= '0';
		sleep(out_clk, 10);
		in_reset <= '0';
		sleep(out_clk, 10);

		----------------------------------------------------------------
		-- Test 1: parked by default (capture_en = 0), no output despite incoming packets
		----------------------------------------------------------------
		stim_run <= true;
		wait until packets_sent >= 20;
		assert rx_count = 0
			report "capture output while parked (default config)"
			severity failure;

		----------------------------------------------------------------
		-- Configure: period, stream_id, then soft-reset pulse and enable on lane 3 with
		-- a 2-packet burst (burst_length = 1)
		----------------------------------------------------------------
		fpga_write_control(out_clk, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, 4, PERIOD, 3);
		fpga_write_control(out_clk, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, 7, 16#00A5#, 2);
		fpga_write_control(out_clk, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, 0, X"80"); -- soft_reset, parked
		sleep(out_clk, 5);
		fpga_write_control(out_clk, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, 0, X"59"); -- capture_en=1, lane=3, burst_length=1
		sleep(in_clk, 300); -- let the FIFO reset sequence (wr_rst_busy) complete

		----------------------------------------------------------------
		-- Test 2/3: first burst - packet format, payload, burst index, shared timestamp
		----------------------------------------------------------------
		wait until rx_count = 1;
		check_capture_packet(lane => 3, burst_idx => 0);
		t0 := to_unsigned(rx_pkt(4 to 9));
		base_pkt := to_integer(unsigned(rx_pkt(11)));

		wait until rx_count = 2;
		check_capture_packet(lane => 3, burst_idx => 1);
		assert to_unsigned(rx_pkt(4 to 9)) = t0
			report "timestamp not shared between packets of the same burst"
			severity failure;
		assert to_integer(unsigned(rx_pkt(11))) = (base_pkt + 1) mod 256
			report "burst packets are not consecutive CT packets"
			severity failure;

		wait until rx_count = 3; -- first packet of the second burst
		check_capture_packet(lane => 3, burst_idx => 0);
		t1 := to_unsigned(rx_pkt(4 to 9));
		assert to_integer(t1 - t0) = PERIOD + 1
			report "burst period mismatch: timestamps differ by " & str(to_integer(t1 - t0)) & ", expected " & str(PERIOD + 1)
			severity failure;

		----------------------------------------------------------------
		-- Test 4: live lane switch between bursts + current_lane status readback
		----------------------------------------------------------------
		cnt := rx_count;
		fpga_write_control(out_clk, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, 0, X"69"); -- capture_en=1, lane=5, burst_length=1
		wait until rx_count >= cnt + 4; -- skip any burst that was in flight during the write
		check_capture_packet(lane => 5, burst_idx => (rx_count - 1) mod 2);
		read_byte(16#81#, status);
		assert status(2 downto 0) = "101"
			report "current_lane status readback mismatch"
			severity failure;

		----------------------------------------------------------------
		-- Test 5: overrun detection and clearing
		----------------------------------------------------------------
		wait until out_tvalid = '1'; -- a burst readout is starting
		rx_enable <= '0'; -- stall the readout; capture triggers will now be missed
		baseline := packets_sent;
		wait until packets_sent >= baseline + 3 * (PERIOD + 1); -- miss several triggers
		read_byte(16#80#, status);
		assert status(1) = '1'
			report "overrun bit not set while readout stalled"
			severity failure;

		rx_enable <= '1'; -- resume; the stalled burst completes normally
		cnt := rx_count;
		wait until rx_count >= cnt + 2;

		fpga_write_control(out_clk, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, 0, X"29"); -- park (capture_en=0, lane=5)
		sleep(out_clk, 2000); -- let any in-flight burst drain

		----------------------------------------------------------------
		-- Test 6: parked again - no new captures
		----------------------------------------------------------------
		cnt := rx_count;
		baseline := packets_sent;
		wait until packets_sent >= baseline + 2 * (PERIOD + 1);
		assert rx_count = cnt
			report "capture output while parked (capture_en=0)"
			severity failure;

		-- Soft reset while parked clears the sticky overrun bit
		fpga_write_control(out_clk, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, 0, X"A9"); -- soft_reset, parked, lane=5
		sleep(out_clk, 5);
		fpga_write_control(out_clk, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, 0, X"29"); -- release reset, still parked
		sleep(in_clk, 300);
		read_byte(16#80#, status);
		assert status(1) = '0'
			report "overrun bit not cleared by soft_reset"
			severity failure;
		assert status(2) = '0'
			report "overflow sticky bit unexpectedly set"
			severity failure;

		report "ct_prober_testbench PASSED";
		finish;
	end process;

end architecture sim;
