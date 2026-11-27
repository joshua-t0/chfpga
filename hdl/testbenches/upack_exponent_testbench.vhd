-- Self-checking testbench of the exponent mode of the packetizer (upack with EXPONENT_BITS = EB: 2 or 3).
--
-- The input is the stream of the corner-turn engine: frames of WORDS words, a word has 4 bins of 8 inputs. Each
-- sample is a (4+4)-bit value with an exponent of EB bits and one bit that tells that its bin has an exponent in its
-- scaler (the exponent is 0 if this bit is 0). Each input has its own table of the bins with an exponent. The
-- testbench writes the mask, the headers and the playlist (the list of the bins of each packet) through the BSB
-- interface, in the sequence of the host (corriscope, ct_engine/upack.py), and compares every byte of every packet
-- with a model of the definition:
--
--   - a data bin of a packet has exponents if one input or more told so in the last of the 16 frames of the packet
--     (and tx_exponents = 1);
--   - the 16 frames of such a bin are in groups of B frames (from frame 0 of the packet); for each input the
--     exponent of a group is the largest exponent of its samples; a sample with a smaller exponent is divided by
--     2^(difference), rounded to the nearest integer, a tie to the even integer;
--   - a packet is its header (64 bytes, with the timestamp), then the data bins (128 bytes each, at the offsets of
--     the packets with no exponents), then the exponents: for each bin with exponents, in the order of the bins,
--     16 / B numbers (the first group of frames first), with zeros to a multiple of 64 bytes. The number of a group
--     has 2 bytes (input i has the bits 15 - 2i and 14 - 2i, most significant byte first), or 4 bytes with exp_field4
--     (EB = 3 only: input i has the bits 31 - 4i to 28 - 4i);
--   - the packet with the timestamp T (after a reset of the packetizer) has the frames T to T + 15, counted from
--     the first frame after the reset (the frame in progress at the end of the reset is frame 0), as the
--     packetizer with EXPONENT_BITS = 0;
--   - with EB = 3 and exponents of 2 bits in the packets, an exponent above 3 is sent as 3 and the status flag
--     exp_field_over is set.
--
-- Every packet must have an even number of 32-byte words, and with tx_exponents = 1 the packets of a set of 16
-- frames must come W + (W - 1) / 32 + 1 clocks apart (W = words of the packet): the pause of the packetizer.
--
-- Phases:
--   1. tx_exponents = 0 (random exponents at the input): the packets and their timestamps are equal to those of a
--      packetizer with EXPONENT_BITS = 0 that gets the same frames and the same resets, a fixed number of clocks
--      later, for a reset that ends before the stream starts, at the end of a frame and in the middle of a frame.
--   2. For exponents of 2 bits in the packets (and of 4 bits with EB = 3), B = 2, 4, 8 and 16, four tables of the bins
--      with an exponent: all the bins, none, random and not the same for each input, a band of bins.
--   3. EB = 3: exponents of 2 bits in the packets with input exponents to 7: the flag exp_field_over.
--   4. Resets of the transmitter (tx_reset) at SWEEP moments of two sets of 16 frames while the frames flow: after
--      each one the flag overrun is 0 and the exponents are those of their samples.
--   5. A header with wrong bits for the bins with exponents: the flag exponent_bins_mismatch and its counter.
--   6. The tables of the bins with an exponent change while the frames flow.
--   7. A playlist that is too long for a set of 16 frames: the flag overrun, the packets that are complete are right,
--      the packet that the packetizer stopped ends with an even number of words, and the timestamps go on by 16 for
--      each set.
--   8. A reset of the packetizer in the middle of the stream and of a readout.
--
-- With VECTORS (a directory), only one setting runs (VEC_B, VEC_FIELD4, and all the bins with exponents or, with
-- VEC_BAND, a band of 10 % of the data bins), and the testbench writes two files for the host decoder: packets.hex
-- (the UDP payload of each packet of the first 2 sets of 16 frames, one line for each packet) and samples.txt (the
-- true value of each sample).
--
-- The test ends with "UPACK EXPONENT TEST PASSED" (or "UPACK EXPONENT VECTORS WRITTEN") or a failure.
library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;
use ieee.math_real.ALL;
use std.textio.ALL;

library work;
use work.chFPGA_Package.ALL;
use work.tb_package.ALL;

entity upack_exponent_testbench is
	generic (
		WORDS: integer := 32; -- words in a frame (4 bins each). The firmware has 2048.
		NPKT: integer := 4; -- packets of a set of 16 frames
		NBINS: integer := 8; -- data bins in a packet (48 at most)
		BLOCKS: integer := 3; -- sets of 16 frames that each phase checks
		SEED: integer := 1;
		EB: integer := 2; -- EXPONENT_BITS of the packetizer under test: 2 or 3
		SWEEP: integer := 16; -- resets of the transmitter in phase 4
		VECTORS: string := ""; -- directory for the vector files (none if empty)
		VEC_B: integer := 2; -- with VECTORS: frames that have one exponent
		VEC_BAND: boolean := FALSE; -- with VECTORS: only a band of 10 % of the data bins has exponents
		VEC_FIELD4: boolean := FALSE -- with VECTORS: fields of 4 bits (EB = 3)
	);
end entity;

architecture sim of upack_exponent_testbench is
	constant RING: integer := 64; -- frames that the testbench keeps
	constant NBIN: integer := 4 * WORDS; -- bins of a frame
	constant EF: integer := EB + 1; -- exponent bits of a sample: the bit that tells that its bin has an exponent, and the exponent
	constant EMAX: integer := 2 ** EB - 1; -- largest exponent of a sample
	constant XBYTES: integer := sel(EB = 3, 32, 16); -- most exponent bytes of a bin (one exponent for 2 frames; exponents of 4 bits with EB = 3)
	constant MAXLEN: integer := 64 + 128 * NBINS + 64 * ((XBYTES * NBINS + 63) / 64);
	constant MAXW: integer := MAXLEN / 32; -- words of the longest packet
	constant READOUT: integer := NPKT * (MAXW + (MAXW - 1) / 32 + 1); -- clocks of the longest readout of a set of 16 frames
	-- Phase 7: packets of a playlist that is too long for a set of 16 frames (each packet more than one time)
	constant W_LONG: integer := 2 + 4 * NBINS + 2 * ((16 * NBINS + 63) / 64); -- words of a packet whose bins all have exponents (one exponent of 2 bits for 2 frames)
	constant NP_LONG: integer := (16 * WORDS) / (W_LONG + (W_LONG - 1) / 32 + 1) + 2;

	signal clk, bsb_clk: std_logic := '0';
	signal done: boolean := FALSE;
	signal rst, bsb_rst: std_logic := '1'; -- rst: reset of the two packetizers

	signal s_tdata: std_logic_vector(255 downto 0) := (others => '0');
	signal s_texp: std_logic_vector(32 * EF - 1 downto 0) := (others => '0');
	signal s_tvalid, s_tlast: std_logic := '0';
	signal stim_on: boolean := TRUE; -- FALSE: no stream (the next frame starts at its first word)
	signal fidx: integer := 0; -- number of the input frame in progress
	signal widx: integer := 0; -- number of its word
	signal tx_exp: boolean := FALSE; -- tx_exponents of the dut
	signal lb: integer := 1; -- log2(B)
	signal f4: boolean := FALSE; -- exp_field4 of the dut: fields of 4 bits
	signal emax_in: integer := EMAX; -- largest exponent of the input samples
	signal free_order: boolean := FALSE; -- phase 7: the packets of a set of 16 frames are not all there
	signal txr_ev: integer := 0; -- changes when the reset of the transmitter (tx_reset) ends

	signal d_tdata, r_tdata: std_logic_vector(255 downto 0);
	signal d_tvalid, d_tlast, r_tvalid, r_tlast: std_logic;

	signal dcmd_tdata, rcmd_tdata: std_logic_vector(7 downto 0) := (others => '0');
	signal dcmd_tvalid, dcmd_tlast, dcmd_tready, rcmd_tvalid, rcmd_tlast, rcmd_tready: std_logic := '0';

	signal dut_pkts, ref_pkts: integer := 0; -- packets since the last reset (dut: that were checked)
	signal phase: integer := 0;
	signal with_ref, vec_now: boolean := FALSE;

	-- The input frames: one word = the 256 data bits and the 32 exponent fields
	type store_t is array (0 to RING * WORDS - 1) of std_logic_vector(255 + 32 * EF downto 0);
	shared variable store: store_t;
	-- Tables of the scalers: tbl_in(i)(bin) = '1': the bin has an exponent in input i
	type tbl_t is array (0 to 7) of std_logic_vector(0 to NBIN - 1);
	shared variable tbl_in: tbl_t := (others => (others => '1'));

	subtype pkt_t is slv8_array(0 to MAXLEN - 1);
	type pkt_array is array (natural range <>) of pkt_t;
	type int_array_t is array (natural range <>) of integer;
	shared variable hdr: pkt_array(0 to NPKT - 1); -- the 64 header bytes of each packet (only 0 to 63 are used)
	shared variable ref_pk: pkt_array(0 to BLOCKS * NPKT - 1); -- packets of the reference
	shared variable ref_len: int_array_t(0 to BLOCKS * NPKT - 1);
	shared variable shift_seen, tie_pos, tie_neg: int_array_t(1 to 7) := (others => 0); -- parts divided by 2^d, and the ties by the sign of the part
	shared variable over_seen: boolean := FALSE; -- since the last reset of the dut: an exponent above 3 with exponents of 2 bits in the packets
	shared variable pk_none, pk_pad, pk_even, bins_with, bins_without: integer := 0; -- packets with no exponent word, with a word of zeros at the end, with none
	shared variable mixed_bins: integer := 0; -- bins with exponents, but not in all the inputs
	shared variable complete_pkts, stopped_pkts: integer := 0; -- phase 7: packets that are complete and right, packets that the packetizer stopped
	shared variable gaps_checked: integer := 0; -- pauses between two packets that were measured
	shared variable t_first_dut, t_first_ref: time := 0 ns;
	shared variable base_seen: integer := 0; -- number of the set of 16 frames of the first packet after the last reset
	shared variable part0_seen: boolean := FALSE; -- the last reset ended in the middle of a frame

	-- Header bin of packet pn, and data bin k of packet pn
	function header_bin(pn: integer) return integer is begin return pn; end function;
	function data_bin(pn, k: integer) return integer is begin return NPKT + pn + NPKT * k; end function;

	-- Division by 2^d, rounded to the nearest integer, a tie to the even integer
	function rq(m, d: integer) return integer is
		variable y, f: real;
	begin
		y := real(m) / real(2 ** d);
		f := floor(y);
		if y - f > 0.5 then
			return integer(f) + 1;
		elsif y - f = 0.5 then
			if integer(f) mod 2 /= 0 then return integer(f) + 1; else return integer(f); end if;
		end if;
		return integer(f);
	end function;

	function nib(v: std_logic_vector(3 downto 0)) return integer is begin return to_integer(signed(v)); end function;

	-- TRUE if the bin has an exponent in one input or more (tables as they are now)
	impure function has_exponent(bin: integer) return boolean is
	begin
		for i in 0 to 7 loop
			if tbl_in(i)(bin) = '1' then return TRUE; end if;
		end loop;
		return FALSE;
	end function;

	-- Bins with exponents in packet pn (with the tables and tx_exponents as they are)
	impure function bins_with_exponents(pn: integer; exponents: boolean) return integer is
		variable n: integer := 0;
	begin
		if exponents then
			for k in 0 to NBINS - 1 loop
				if has_exponent(data_bin(pn, k)) then n := n + 1; end if;
			end loop;
		end if;
		return n;
	end function;

	-- Bytes of the exponents of a packet with n such bins: an even number of 32-byte words
	function exponent_bytes(n, lb: integer; field4: boolean := FALSE) return integer is
	begin
		return 64 * ((n * (sel(field4, 64, 32) / 2 ** lb) + 63) / 64);
	end function;
begin
	assert NBINS <= 48 report "At most 48 bins in a packet (the mask of the header has 48 bits)" severity FAILURE;
	assert NBIN >= NPKT * (NBINS + 1) report "Not enough bins in a frame" severity FAILURE;
	assert EB = 2 or EB = 3 report "EB must be 2 or 3" severity FAILURE;
	assert WORDS >= 32 report "A frame must have 32 words or more" severity FAILURE;
	assert READOUT < 16 * WORDS - 16 report "The readout of a set of 16 frames is too long" severity FAILURE;
	assert NP_LONG * (NBINS + 1) <= 8192 report "The long playlist of phase 7 does not fit in the playlist memory" severity FAILURE;
	-- The rule, with numbers: this does not depend on the code of the model
	assert rq(7, 1) = 4 and rq(5, 1) = 2 and rq(3, 1) = 2 and rq(1, 1) = 0 and rq(-1, 1) = 0 and rq(-3, 1) = -2 and rq(-5, 1) = -2 and rq(-7, 1) = -4
		and rq(6, 2) = 2 and rq(2, 2) = 0 and rq(-2, 2) = 0 and rq(-6, 2) = -2 and rq(5, 2) = 1 and rq(7, 2) = 2 and rq(-7, 2) = -2
		and rq(4, 3) = 0 and rq(-4, 3) = 0 and rq(5, 3) = 1 and rq(-5, 3) = -1 and rq(7, 3) = 1 and rq(-8, 3) = -1
		and rq(7, 4) = 0 and rq(-7, 4) = 0 and rq(-8, 4) = 0 and rq(7, 5) = 0 and rq(-8, 5) = 0 and rq(-8, 7) = 0 and rq(7, 7) = 0
		report "The model of the rounding is wrong" severity FAILURE;
	assert exponent_bytes(0, 1) = 0 and exponent_bytes(1, 1) = 64 and exponent_bytes(2, 1) = 64 and exponent_bytes(3, 1) = 64 and exponent_bytes(4, 1) = 64 and exponent_bytes(5, 1) = 128
		and exponent_bytes(48, 1) = 768 and exponent_bytes(1, 4) = 64 and exponent_bytes(32, 4) = 64 and exponent_bytes(33, 4) = 128 and exponent_bytes(48, 4) = 128
		and exponent_bytes(1, 1, TRUE) = 64 and exponent_bytes(2, 1, TRUE) = 64 and exponent_bytes(3, 1, TRUE) = 128 and exponent_bytes(48, 1, TRUE) = 1536 and exponent_bytes(48, 4, TRUE) = 192
		report "The model of the length is wrong" severity FAILURE;

	clk <= not clk after 1.25 ns when not done;
	bsb_clk <= not bsb_clk after 4 ns when not done;

	dut: entity work.upack
		generic map (SIM => TRUE, EXPONENT_BITS => EB)
		port map (
			s_axis_in_tdata => s_tdata, s_axis_in_texp => s_texp, s_axis_in_tvalid => s_tvalid, s_axis_in_tlast => s_tlast,
			m_axis_out_tdata => d_tdata, m_axis_out_tvalid => d_tvalid, m_axis_out_tlast => d_tlast,
			clk => clk, rst => rst, debug_out => open,
			s_axis_bsb_tdata => dcmd_tdata, s_axis_bsb_tvalid => dcmd_tvalid, s_axis_bsb_tlast => dcmd_tlast, s_axis_bsb_tready => dcmd_tready,
			m_axis_bsb_tready => '1', bsb_clk => bsb_clk, bsb_rst => bsb_rst
		);

	ref: entity work.upack
		generic map (SIM => TRUE, EXPONENT_BITS => 0)
		port map (
			s_axis_in_tdata => s_tdata, s_axis_in_tvalid => s_tvalid, s_axis_in_tlast => s_tlast,
			m_axis_out_tdata => r_tdata, m_axis_out_tvalid => r_tvalid, m_axis_out_tlast => r_tlast,
			clk => clk, rst => rst, debug_out => open,
			s_axis_bsb_tdata => rcmd_tdata, s_axis_bsb_tvalid => rcmd_tvalid, s_axis_bsb_tlast => rcmd_tlast, s_axis_bsb_tready => rcmd_tready,
			m_axis_bsb_tready => '1', bsb_clk => bsb_clk, bsb_rst => bsb_rst
		);

	-- Frames with no gap, as the corner-turn engine sends them. A sample of a bin that has an exponent in its input has
	-- a random exponent; the other samples have the exponent 0 (as the scalers).
	stim_proc: process
		variable s1: positive := 17 + SEED;
		variable s2: positive := 4711;
		variable r: real;
		variable w: integer := 0;
		variable f: integer := 0;
		variable d: std_logic_vector(255 downto 0);
		variable x: std_logic_vector(32 * EF - 1 downto 0);
		variable m, bin, inp, e: integer;
	begin
		wait until rising_edge(clk);
		loop
			if not stim_on then
				s_tvalid <= '0';
				s_tlast <= '0';
				if w /= 0 then
					w := 0;
					f := f + 1;
				end if;
				wait until rising_edge(clk);
			else
				for n in 0 to 31 loop
					for part in 0 to 1 loop
						uniform(s1, s2, r);
						m := integer(floor(r * 15.0)) - 7; -- -7 to 7
						uniform(s1, s2, r);
						if r < 0.02 then m := -8; end if; -- a value that the exponent mode of the scaler does not make
						d(8 * n + 4 * part + 3 downto 8 * n + 4 * part) := std_logic_vector(to_signed(m, 4));
					end loop;
					bin := 4 * w + 3 - n / 8; -- sample n of the word: column n / 8, input 7 - n mod 8
					inp := 7 - n mod 8;
					e := 0;
					uniform(s1, s2, r);
					if tbl_in(inp)(bin) = '1' and r > 0.5 then
						uniform(s1, s2, r);
						e := integer(floor(r * real(emax_in + 1)));
					end if;
					x(EF * n + EB - 1 downto EF * n) := std_logic_vector(to_unsigned(e, EB));
					x(EF * n + EB) := tbl_in(inp)(bin);
				end loop;
				store((f mod RING) * WORDS + w) := x & d;
				s_tdata <= d;
				s_texp <= x;
				s_tvalid <= '1';
				s_tlast <= to_std_logic(w = WORDS - 1);
				fidx <= f;
				widx <= w;
				wait until rising_edge(clk);
				if w = WORDS - 1 then
					w := 0;
					f := f + 1;
				else
					w := w + 1;
				end if;
			end if;
			exit when done;
		end loop;
		wait;
	end process stim_proc;

	-- Packets of the reference (EXPONENT_BITS = 0)
	ref_proc: process
		variable p: pkt_t;
		variable n: integer := 0;
	begin
		wait until rising_edge(clk);
		if rst then
			n := 0;
			ref_pkts <= 0;
		elsif r_tvalid then
			if n = 0 and ref_pkts = 0 then t_first_ref := now; end if;
			if n + 32 <= MAXLEN then
				for i in 0 to 31 loop
					p(n + i) := r_tdata(255 - 8 * i downto 248 - 8 * i);
				end loop;
			end if;
			n := n + 32;
			if r_tlast then
				if ref_pkts < BLOCKS * NPKT then
					ref_pk(ref_pkts) := p;
					ref_len(ref_pkts) := n;
				end if;
				ref_pkts <= ref_pkts + 1;
				n := 0;
			end if;
		end if;
	end process ref_proc;

	-- Packets of the dut against the model
	dut_proc: process
		variable p, e: pkt_t;
		variable xb: slv8_array(0 to XBYTES * NBINS + 63);
		variable n, q, b, pn, len, pos, f0, bin, sn, d, big, nxb, bsz, ts, fa, re, im, b_base, cmp_len: integer := 0;
		variable last_ts, prev_ts, prev_w, txr_seen, n_inputs_exp: integer := 0;
		variable t_start, prev_t: time := 0 ns;
		variable have_f0, hasx, need_base, part0, have_prev, cut: boolean := FALSE;
		variable w: std_logic_vector(255 + 32 * EF downto 0);
		type e_table is array (0 to 15, 0 to 7) of integer;
		variable ev, bg: e_table;
		variable field: std_logic_vector(15 downto 0);
		variable field32: std_logic_vector(31 downto 0);
		file fp, ft: text;
		variable l: line;
		variable files_open: boolean := FALSE;
		-- The packetizer stops a readout that is not complete and ends the packet in progress with words of zeros
		alias stop_cnt is <<signal dut.ram_rd_block.stop_cnt: unsigned(4 downto 0)>>;
		alias stop_open is <<signal dut.ram_rd_block.out_open: std_logic>>;
		variable stop_seen: boolean := FALSE; -- the packet in progress was ended in this way
	begin
		loop
		wait until rising_edge(clk);
		if rst = '0' and stop_cnt = 5 and stop_open = '1' then
			stop_seen := TRUE;
		end if;
		if rst then
			n := 0;
			stop_seen := FALSE;
			have_f0 := FALSE;
			need_base := TRUE;
			have_prev := FALSE;
			last_ts := 0;
			txr_seen := txr_ev;
			dut_pkts <= 0;
			over_seen := FALSE;
			if files_open then
				file_close(fp); file_close(ft);
				files_open := FALSE;
			end if;
		else
			if s_tvalid = '1' and not have_f0 then
				f0 := fidx; -- the first frame that the packetizer gets after the reset (complete or not) is frame 0 of the first set of 16 frames
				part0 := widx /= 0;
				part0_seen := part0;
				have_f0 := TRUE;
			end if;
			if txr_ev /= txr_seen then -- the reset of the transmitter ended: the timestamps start again at 0
				txr_seen := txr_ev;
				n := 0;
				need_base := TRUE;
				have_prev := FALSE;
				last_ts := 0;
				dut_pkts <= 0;
			end if;
			if d_tvalid then
				if n = 0 then
					t_start := now;
					if need_base then
						-- The set of 16 frames of the first readout: the one that was complete when it started
						b_base := ((fidx - f0) * WORDS + widx - 8) / (16 * WORDS) - 1;
						base_seen := b_base;
						need_base := FALSE;
						t_first_dut := now;
					end if;
				end if;
				if n + 32 > MAXLEN then
					report "Phase " & integer'image(phase) & ": a packet is too long" severity FAILURE;
				end if;
				for i in 0 to 31 loop
					p(n + i) := d_tdata(255 - 8 * i downto 248 - 8 * i);
				end loop;
				n := n + 32;
				if d_tlast then
					assert have_f0 report "A packet before the first frame" severity FAILURE;
					if n mod 64 /= 0 then
						report "Phase " & integer'image(phase) & ": a packet has an odd number of 32-byte words (" & integer'image(n / 32) & ")" severity FAILURE;
					end if;
					q := dut_pkts;
					bsz := 2 ** lb;
					cut := stop_seen;
					stop_seen := FALSE;
					if cut and not free_order then
						report "Phase " & integer'image(phase) & ": a readout was not complete and the packetizer stopped it" severity FAILURE;
					end if;
					if cut and n <= 64 then
						-- A packet that was stopped in its header (its words, then words of zeros): nothing to compare
						stopped_pkts := stopped_pkts + 1;
						dut_pkts <= dut_pkts + 1;
						n := 0;
						next;
					end if;
					-- The packet says which one it is: stream ID (byte 46) and timestamp (bytes 50 to 57, little endian)
					pn := to_integer(unsigned(p(46)));
					ts := to_integer(unsigned(p(53)(6 downto 0)) & unsigned(p(52)) & unsigned(p(51)) & unsigned(p(50)));
					if pn >= NPKT or ts mod 16 /= 0 or p(54) /= X"00" or p(55) /= X"00" or p(56) /= X"00" or p(57) /= X"00" then
						report "Phase " & integer'image(phase) & " packet " & integer'image(q) & ": stream ID " & integer'image(pn) & " or timestamp " & integer'image(ts) & " is not possible" severity FAILURE;
					end if;
					if free_order then
						if ts /= last_ts and ts /= last_ts + 16 then
							report "Phase " & integer'image(phase) & ": the timestamp goes from " & integer'image(last_ts) & " to " & integer'image(ts) severity FAILURE;
						end if;
					elsif pn /= q mod NPKT or ts /= 16 * (q / NPKT) then
						report "Phase " & integer'image(phase) & " packet " & integer'image(q) & ": stream ID " & integer'image(pn) & " and timestamp " & integer'image(ts)
						     & ", expected " & integer'image(q mod NPKT) & " and " & integer'image(16 * (q / NPKT)) severity FAILURE;
					end if;
					-- The pause between two packets of a set of 16 frames
					if have_prev and ts = prev_ts and not free_order then
						if (t_start - prev_t) / 2.5 ns /= prev_w + sel(tx_exp, (prev_w - 1) / 32 + 1, 0) then
							report "Phase " & integer'image(phase) & " packet " & integer'image(q) & ": " & integer'image((t_start - prev_t) / 2.5 ns) & " clocks after the packet before, which has "
							     & integer'image(prev_w) & " words" severity FAILURE;
						end if;
						gaps_checked := gaps_checked + 1;
					end if;
					have_prev := TRUE; prev_ts := ts; prev_t := t_start; prev_w := n / 32;
					last_ts := ts;
					b := b_base + ts / 16;
					-- The expected packet
					for i in 0 to 63 loop e(i) := hdr(pn)(i); end loop;
					for i in 0 to 7 loop -- the timestamp of the packet (checked above)
						e(50 + i) := p(50 + i);
					end loop;
					pos := 64;
					nxb := 0;
					if vec_now and q = 0 then
						file_open(fp, VECTORS & "/packets.hex", write_mode);
						file_open(ft, VECTORS & "/samples.txt", write_mode);
						write(l, string'("# packet data_bin_of_the_packet frame input real imaginary exponent has_exponents (value = (real + j imaginary) x 2^exponent)")); writeline(ft, l);
						files_open := TRUE;
					end if;
					for k in 0 to NBINS - 1 loop
						bin := data_bin(pn, k);
						sn := 8 * (3 - bin mod 4);
						-- The bin has exponents if one input or more told so in the last of the 16 frames of the packet
						w := store(((f0 + 16 * b + 15) mod RING) * WORDS + bin / 4);
						n_inputs_exp := 0;
						for i in 0 to 7 loop
							if w(256 + EF * (sn + 7 - i) + EB) = '1' then n_inputs_exp := n_inputs_exp + 1; end if;
						end loop;
						hasx := tx_exp and n_inputs_exp > 0;
						if hasx then bins_with := bins_with + 1; else bins_without := bins_without + 1; end if;
						if hasx and n_inputs_exp < 8 then mixed_bins := mixed_bins + 1; end if;
						-- The exponents of the samples of the bin, and the largest one of each group of B frames
						for j in 0 to 15 loop
							fa := f0 + 16 * b + j;
							w := store((fa mod RING) * WORDS + bin / 4);
							for i in 0 to 7 loop
								ev(j, i) := to_integer(unsigned(w(256 + EF * (sn + 7 - i) + EB - 1 downto 256 + EF * (sn + 7 - i))));
							end loop;
						end loop;
						for j in 0 to 15 loop
							for i in 0 to 7 loop
								big := 0;
								for jj in (j / bsz) * bsz to (j / bsz) * bsz + bsz - 1 loop
									if ev(jj, i) > big then big := ev(jj, i); end if;
								end loop;
								bg(j, i) := big;
							end loop;
						end loop;
						for j in 0 to 15 loop
							fa := f0 + 16 * b + j;
							w := store((fa mod RING) * WORDS + bin / 4);
							for i in 0 to 7 loop
								re := nib(w(8 * (sn + 7 - i) + 7 downto 8 * (sn + 7 - i) + 4));
								im := nib(w(8 * (sn + 7 - i) + 3 downto 8 * (sn + 7 - i)));
								d := 0;
								if hasx then
									d := bg(j, i) - ev(j, i);
									if d > 0 then
										shift_seen(d) := shift_seen(d) + 2;
										if (2 * re) mod (2 ** d) = 0 and re mod (2 ** d) /= 0 then
											if re > 0 then tie_pos(d) := tie_pos(d) + 1; else tie_neg(d) := tie_neg(d) + 1; end if;
										end if;
										if (2 * im) mod (2 ** d) = 0 and im mod (2 ** d) /= 0 then
											if im > 0 then tie_pos(d) := tie_pos(d) + 1; else tie_neg(d) := tie_neg(d) + 1; end if;
										end if;
									end if;
									re := rq(re, d);
									im := rq(im, d);
								end if;
								e(pos) := std_logic_vector(to_signed(re, 4)) & std_logic_vector(to_signed(im, 4));
								pos := pos + 1;
								if files_open and q < 2 * NPKT then
									write(l, q); write(l, ' '); write(l, k); write(l, ' '); write(l, j); write(l, ' '); write(l, i);
									write(l, ' '); write(l, re); write(l, ' '); write(l, im); write(l, ' ');
									if hasx then write(l, bg(j, i)); write(l, string'(" 1")); else write(l, string'("0 0")); end if;
									writeline(ft, l);
								end if;
							end loop;
						end loop;
						if hasx then
							for blk in 0 to 16 / bsz - 1 loop
								if f4 then -- 4 bits for each input
									for i in 0 to 7 loop
										field32(31 - 4 * i downto 28 - 4 * i) := std_logic_vector(to_unsigned(bg(blk * bsz, i), 4));
									end loop;
									for y in 0 to 3 loop
										xb(nxb + y) := field32(31 - 8 * y downto 24 - 8 * y);
									end loop;
									nxb := nxb + 4;
								else -- 2 bits for each input: an exponent above 3 is sent as 3 (and the flag exp_field_over)
									for i in 0 to 7 loop
										field(15 - 2 * i downto 14 - 2 * i) := std_logic_vector(to_unsigned(minimum(bg(blk * bsz, i), 3), 2));
										if bg(blk * bsz, i) > 3 then over_seen := TRUE; end if;
									end loop;
									xb(nxb) := field(15 downto 8);
									xb(nxb + 1) := field(7 downto 0);
									nxb := nxb + 2;
								end if;
							end loop;
						end if;
					end loop;
					-- The exponents, with zeros to a multiple of 64 bytes (an even number of words)
					if nxb = 0 then
						pk_none := pk_none + 1;
					elsif ((nxb + 31) / 32) mod 2 = 1 then
						pk_pad := pk_pad + 1;
					else
						pk_even := pk_even + 1;
					end if;
					while nxb mod 64 /= 0 loop
						xb(nxb) := X"00";
						nxb := nxb + 1;
					end loop;
					for i in 0 to nxb - 1 loop
						e(pos + i) := xb(i);
					end loop;
					len := pos + nxb;
					cmp_len := len;
					if cut then
						-- A packet of a readout that was stopped: its words until the stop, then one or two words of zeros
						if n > len then
							report "Phase " & integer'image(phase) & ": a packet that was stopped is longer than the complete packet" severity FAILURE;
						end if;
						-- (the words of a data bin that did not get its 4 words are not compared: they can have wrong shifts)
						cmp_len := minimum(64 + 128 * ((n - 128) / 128), 64 + 128 * NBINS);
						for i in n - 32 to n - 1 loop
							if p(i) /= X"00" then report "Phase " & integer'image(phase) & ": the last word of a packet that was stopped is not zeros" severity FAILURE; end if;
						end loop;
						stopped_pkts := stopped_pkts + 1;
					elsif n /= len then
						report "Phase " & integer'image(phase) & " packet " & integer'image(q) & ": " & integer'image(n) & " bytes, expected " & integer'image(len) severity FAILURE;
					end if;
					if not (part0 and b = 0) then -- (the first set of 16 frames after a reset in the middle of a frame has a frame that is not complete)
						for i in 0 to cmp_len - 1 loop -- (an if, not an assert: with an assert here, xsim 2022.2 gave a false failure in the run with frames of 2048 words)
							if p(i) /= e(i) then
								report "Phase " & integer'image(phase) & " packet " & integer'image(q) & " (set of frames " & integer'image(b) & ", packet " & integer'image(pn) & ") byte " & integer'image(i)
								     & ": " & to_hstring(p(i)) & ", expected " & to_hstring(e(i)) severity FAILURE;
							end if;
						end loop;
					end if;
					if free_order and not cut then complete_pkts := complete_pkts + 1; end if;
					-- The same packet as the packetizer with no exponent mode
					if with_ref and q < BLOCKS * NPKT then
						if ref_pkts <= q then report "The reference has no packet " & integer'image(q) severity FAILURE; end if;
						if ref_len(q) /= n then report "Packet " & integer'image(q) & ": the length is not that of the reference" severity FAILURE; end if;
						for i in 0 to n - 1 loop
							if p(i) /= ref_pk(q)(i) then
								report "Packet " & integer'image(q) & " byte " & integer'image(i) & " is not that of the reference" severity FAILURE;
							end if;
						end loop;
					end if;
					if files_open and q < 2 * NPKT then
						for i in 42 to n - 1 loop
							write(l, to_hstring(p(i)));
						end loop;
						writeline(fp, l);
						if q = 2 * NPKT - 1 then
							file_close(fp); file_close(ft);
							files_open := FALSE;
						end if;
					end if;
					dut_pkts <= dut_pkts + 1;
					n := 0;
				end if;
			end if;
		end if;
		end loop;
	end process dut_proc;

	main_proc: process
		-- One command to the two packetizers
		procedure control(addr, data: integer) is
		begin
			wait until rising_edge(bsb_clk);
			fpga_write_control(bsb_clk, dcmd_tdata, dcmd_tvalid, dcmd_tlast, dcmd_tready, addr, data, 1);
			fpga_write_control(bsb_clk, rcmd_tdata, rcmd_tvalid, rcmd_tlast, rcmd_tready, addr, data, 1);
		end procedure;
		procedure ram(addr: integer; data: slv8_array) is
		begin
			wait until rising_edge(bsb_clk);
			fpga_write_ram(bsb_clk, dcmd_tdata, dcmd_tvalid, dcmd_tlast, dcmd_tready, addr, data);
			fpga_write_ram(bsb_clk, rcmd_tdata, rcmd_tvalid, rcmd_tlast, rcmd_tready, addr, data);
		end procedure;

		-- The sequence of the host (upack.py: init, set_playlist, set_ethernet_header), with the lengths of the packets,
		-- the info byte and the 48 bits that tell which bins of the packet have exponents in the headers. np: packets of
		-- the playlist (packet j is packet j mod NPKT). wrong_header: number of a packet for which these bits are wrong
		-- (-1: none).
		procedure program(exponents: boolean; lb: integer; field4: boolean := FALSE; np: integer := NPKT; wrong_header: integer := -1) is
			constant c0: integer := sel(field4, 16#80#, 0); -- exp_field4 is bit 7 of control byte 0: each write of this byte has it
			variable mask: slv8_array(0 to NBIN / 8 - 1);
			variable play: slv8_array(0 to 2 * (NBINS + 1) - 1);
			variable entry, bin, udp_len, ip_len, pn: integer;
			variable h: slv8_array(0 to 63);
		begin
			control(1, 16#BE#); -- rx_write_enable, tx_enable, tx_reset, tx_toggle_bank, tx_insert_timestamp, rx_mask_low_bins
			control(7, 16#10# + 32 * (lb - 1) + sel(exponents, 16#80#, 0)); -- timestamp_incr = 16, exp_block, tx_exponents
			-- Mask: the stream does not write the header bins
			mask := (others => X"FF");
			for pn in 0 to NPKT - 1 loop
				bin := header_bin(pn);
				mask(bin / 8)(bin mod 8) := '0';
			end loop;
			control(0, 16#30# + c0); -- playlist/mask buffer, mask
			ram(0, mask);
			for pn in 0 to NPKT - 1 loop
				-- The Ethernet, IP and UDP headers and the header of the payload (22 bytes), as the host writes them
				udp_len := 8 + 22 + 128 * NBINS + exponent_bytes(bins_with_exponents(pn, exponents), lb, field4);
				ip_len := 20 + udp_len;
				h := (others => X"00");
				h(0 to 5) := (X"01", X"23", X"34", X"67", X"89", std_logic_vector(to_unsigned(pn mod 16, 8)));
				h(6 to 11) := (X"02", X"00", X"00", X"00", X"00", X"01");
				h(12 to 13) := (X"08", X"00");
				h(14) := X"45";
				h(16) := std_logic_vector(to_unsigned(ip_len / 256, 8)); h(17) := std_logic_vector(to_unsigned(ip_len mod 256, 8));
				h(22) := X"40"; h(23) := X"11";
				h(26 to 29) := (X"0A", X"58", X"00", X"FE");
				h(30 to 33) := (X"0A", X"58", X"00", std_logic_vector(to_unsigned(pn mod 16 + 1, 8)));
				h(34 to 35) := (X"A0", X"29"); h(36 to 37) := (X"A0", X"29"); -- port 41001
				h(38) := std_logic_vector(to_unsigned(udp_len / 256, 8)); h(39) := std_logic_vector(to_unsigned(udp_len mod 256, 8));
				h(42) := X"CF";
				h(43) := X"14"; -- header info
				h(44) := X"10"; -- source ID
				h(46) := std_logic_vector(to_unsigned(pn, 8)); -- stream ID
				if exponents then
					h(43) := std_logic_vector(to_unsigned(16#20# + lb + sel(field4, 8, 0), 8)); -- packets of version 2 with exponents: 0x20 + log2(B), and 0x28 + log2(B) with fields of 4 bits
					for k in 0 to NBINS - 1 loop -- bytes 16 to 21 of the payload header: bit k = 1 if data bin k of the packet has exponents (little endian)
						if has_exponent(data_bin(pn, k)) then
							h(58 + k / 8)(k mod 8) := '1';
						end if;
					end loop;
					if pn = wrong_header then
						h(58)(0) := not h(58)(0);
					end if;
				end if;
				for i in 0 to 63 loop hdr(pn)(i) := h(i); end loop;
				for bank in 0 to 1 loop
					for frame in 0 to 7 loop
						control(0, 16 * bank + frame + c0); -- data buffer
						ram(8 * header_bin(pn), h(8 * frame to 8 * frame + 7));
					end loop;
				end loop;
			end loop;
			-- Playlist: for each packet its header bin (2 groups of 4 frames), then its data bins (4 groups)
			control(0, 16#20# + c0); -- playlist/mask buffer, playlist
			for j in 0 to np - 1 loop
				pn := j mod NPKT;
				for k in 0 to NBINS loop
					entry := header_bin(pn) when k = 0 else data_bin(pn, k - 1) + 2 ** 13;
					if k = NBINS then
						entry := entry + 2 ** 14;
						if j = np - 1 then entry := entry + 2 ** 15; end if;
					end if;
					play(2 * k) := std_logic_vector(to_unsigned(entry / 256, 8));
					play(2 * k + 1) := std_logic_vector(to_unsigned(entry mod 256, 8));
				end loop;
				ram(2 * (NBINS + 1) * j, play);
			end loop;
			control(1, 16#AE#); -- tx_reset = 0
			for i in 1 to 20 loop wait until rising_edge(bsb_clk); end loop;
		end procedure;

		procedure wait_packets(count: integer) is
			variable guard: integer := 0;
		begin
			while dut_pkts < count loop
				wait until rising_edge(clk);
				guard := guard + 1;
				if guard >= (count / NPKT + 8) * 16 * WORDS then
					report "Phase " & integer'image(phase) & ": no packets" severity FAILURE;
				end if;
			end loop;
		end procedure;

		variable s1: positive := 99 + SEED;
		variable s2: positive := 12345;
		variable r: real;

		-- Tables of the bins with an exponent. 0: all the bins, in all the inputs. 1: none. 2: random, each input its own
		-- table. 3: a band of the data bins (pct percent), in all the inputs
		procedure make_table(pattern, pct: integer) is
			constant first: integer := NPKT;
			constant span: integer := NPKT * NBINS;
			variable lo, hi: integer;
		begin
			lo := first + span * (50 - pct / 2) / 100;
			hi := first + span * (50 - pct / 2 + pct) / 100;
			for i in 0 to 7 loop
				for bin in 0 to NBIN - 1 loop
					case pattern is
						when 0 => tbl_in(i)(bin) := '1';
						when 1 => tbl_in(i)(bin) := '0';
						when 2 => uniform(s1, s2, r); tbl_in(i)(bin) := to_std_logic(r < 0.2);
						when others => tbl_in(i)(bin) := to_std_logic(bin >= lo and bin < hi);
					end case;
				end loop;
			end loop;
		end procedure;

		-- How the reset of the packetizers ends
		constant AT_START: integer := 0; -- before the stream starts (as after a sync)
		constant AT_FRAME: integer := 1; -- at the end of a frame
		constant IN_FRAME: integer := 2; -- in the middle of a frame

		-- One setting: reset, program, end of the reset, check BLOCKS sets of 16 frames
		procedure run(exponents: boolean; log2b, pattern, pct: integer; field4: boolean := FALSE; emax_v: integer := EMAX; how: integer := AT_FRAME;
		              np: integer := NPKT; wrong_header: integer := -1; ref_check: boolean := FALSE; count: integer := BLOCKS * NPKT) is
		begin
			rst <= '1';
			wait until rising_edge(clk);
			phase <= phase + 1;
			with_ref <= ref_check;
			free_order <= np /= NPKT;
			tx_exp <= exponents; lb <= log2b; f4 <= field4; emax_in <= emax_v;
			make_table(pattern, pct);
			for i in 1 to 2 * WORDS loop wait until rising_edge(clk); end loop; -- the stream has the new tables
			program(exponents, log2b, field4, np, wrong_header);
			if how = AT_START then
				stim_on <= FALSE;
				for i in 1 to 2 * WORDS loop wait until rising_edge(clk); end loop;
				rst <= '0';
				for i in 1 to 37 loop wait until rising_edge(clk); end loop;
				stim_on <= TRUE;
			else
				wait until rising_edge(clk) and s_tlast = '1';
				if how = IN_FRAME then
					for i in 1 to WORDS / 3 loop wait until rising_edge(clk); end loop;
				end if;
				rst <= '0';
			end if;
			wait_packets(count);
			assert base_seen = 0 report "Phase " & integer'image(phase) & ": the first packet after the reset has the set of frames number " & integer'image(base_seen) & ", not the first one" severity FAILURE;
			assert part0_seen = (how = IN_FRAME) report "Phase " & integer'image(phase) & ": the reset did not end where the test wants it" severity FAILURE;
		end procedure;

		-- Before the tests: the stream writes all the bins, with their exponents, in the two banks (mask of ones, the
		-- transmitter in reset). The header bins then keep exponents, and the bit that tells that they have exponents: a
		-- header must not use them.
		procedure prefill is
			variable mask: slv8_array(0 to NBIN / 8 - 1) := (others => X"FF");
		begin
			control(1, 16#BE#);
			control(0, 16#30#);
			ram(0, mask);
			wait until rising_edge(clk);
			rst <= '0';
			for i in 1 to 35 * WORDS loop wait until rising_edge(clk); end loop;
			rst <= '1';
			wait until rising_edge(clk);
		end procedure;

		alias overrun is <<signal dut.overrun: std_logic>>;
		alias exp_status is <<signal dut.status_bytes: slv8_array(0 to 3)>>;
		alias exp_over is <<signal dut.exp_field_over: std_logic>>;
		alias mismatch_flag is <<signal dut.exponent_bins_mismatch: std_logic>>;
		alias mismatch_count is <<signal dut.exponent_bins_mismatch_count: unsigned(7 downto 0)>>;
		variable total: integer := 0;
		variable st: slv8_array(0 to 3);
		variable lat: time := 0 ns;

		procedure flags_clear(what: string) is
		begin
			assert overrun = '0' report what & " (phase " & integer'image(phase) & "): overrun of the readout" severity FAILURE;
			assert mismatch_flag = '0' and mismatch_count = 0 report what & " (phase " & integer'image(phase) & "): the flag exponent_bins_mismatch is set" severity FAILURE;
		end procedure;
	begin
		for i in 1 to 10 loop wait until rising_edge(bsb_clk); end loop;
		bsb_rst <= '0';
		for i in 1 to 40 loop wait until rising_edge(bsb_clk); end loop;
		prefill;

		if VECTORS /= "" then
			-- One setting, with the files for the host decoder
			assert BLOCKS >= 2 report "The vectors are the packets of 2 sets of 16 frames" severity FAILURE;
			vec_now <= TRUE;
			assert EB = 3 or not VEC_FIELD4 report "Fields of 4 bits need EB = 3" severity FAILURE;
			-- fields of 2 bits: the input exponents are from 0 to 3, as the host must set them
			if VEC_B = 2 then run(TRUE, 1, sel(VEC_BAND, 3, 0), 10, VEC_FIELD4, sel(VEC_FIELD4, EMAX, 3));
			elsif VEC_B = 4 then run(TRUE, 2, sel(VEC_BAND, 3, 0), 10, VEC_FIELD4, sel(VEC_FIELD4, EMAX, 3));
			elsif VEC_B = 8 then run(TRUE, 3, sel(VEC_BAND, 3, 0), 10, VEC_FIELD4, sel(VEC_FIELD4, EMAX, 3));
			else run(TRUE, 4, sel(VEC_BAND, 3, 0), 10, VEC_FIELD4, sel(VEC_FIELD4, EMAX, 3));
			end if;
			flags_clear("Vectors");
			assert exp_over = '0' report "The flag exp_field_over is set" severity FAILURE;
			report "UPACK EXPONENT VECTORS WRITTEN: " & integer'image(dut_pkts) & " packets checked, one exponent for " & integer'image(VEC_B) & " frames, exponents of " & integer'image(sel(VEC_FIELD4, 4, 2)) & " bits, " & integer'image(bins_with) & " bins with exponents and "
			     & integer'image(bins_without) & " with none (this is not the full test)";
			done <= TRUE;
			wait;
		end if;

		-- Phase 1: tx_exponents = 0 (the input has random exponents); against the packetizer with no exponent
		-- mode, with the three ends of the reset
		for how in AT_START to IN_FRAME loop
			run(FALSE, 1, 0, 0, how => how, ref_check => TRUE);
			st := exp_status;
			assert st(0)(5 downto 4) = std_logic_vector(to_unsigned(EB, 2)) and st(0)(6) = '1' and st(0)(7) = to_std_logic(EB = 3) and st(0)(3 downto 0) = "1000" and st(3) = X"00"
				report "The status does not give what the build has (EXPONENT_BITS, exponent_bins_from_scalers, exp_field4_support) and flags at 0" severity FAILURE;
			if how = AT_START then
				lat := t_first_dut - t_first_ref;
			end if;
			assert t_first_dut - t_first_ref = lat and lat > 0 ns
				report "The packets come " & time'image(t_first_dut - t_first_ref) & " after those of the reference, and " & time'image(lat) & " in the first case" severity FAILURE;
			total := total + dut_pkts;
			flags_clear("Mode off");
		end loop;
		with_ref <= FALSE;
		report "Phase 1: 3 x " & integer'image(BLOCKS * NPKT) & " packets (reset that ends before the stream, at the end of a frame, in a frame) equal to those with EXPONENT_BITS = 0, with the same timestamps, "
		     & integer'image(lat / 2.5 ns) & " clocks later";

		-- Phase 2: one exponent for 2, 4, 8, 16 frames, with the 4 tables. Exponents of 2 bits in the packets (input
		-- exponents from 0 to 3), then of 4 bits (EB = 3: input exponents from 0 to 7). The reset ends at the end of a frame, in a frame, or before the stream.
		for fs in 0 to sel(EB = 3, 1, 0) loop
			for log2b in 1 to 4 loop
				for pattern in 0 to 3 loop
					run(TRUE, log2b, pattern, 30, fs = 1, sel(fs = 1, EMAX, 3), how => (log2b + pattern) mod 3);
					total := total + dut_pkts;
					assert exp_over = '0' report "The flag exp_field_over is set (exponents of " & integer'image(2 + 2 * fs) & " bits, phase " & integer'image(phase) & ")" severity FAILURE;
					assert not over_seen report "The model has an exponent above 3 with exponents of 2 bits" severity FAILURE;
					flags_clear("One exponent for " & integer'image(2 ** log2b) & " frames");
				end loop;
				report "Exponents of " & integer'image(2 + 2 * fs) & " bits, one exponent for " & integer'image(2 ** log2b) & " frames: 4 tables of bins checked (phases " & integer'image(phase - 3) & " to " & integer'image(phase) & ")";
			end loop;
		end loop;

		-- Phase 3, EB = 3: exponents of 2 bits in the packets with input exponents to 7 (the host did not limit the scalers). The exponents
		-- above 3 are sent as 3, the samples have the shift of the true exponent, and the flag exp_field_over is set.
		if EB = 3 then
			run(TRUE, 2, 0, 0, FALSE, EMAX);
			total := total + dut_pkts;
			assert over_seen report "No exponent above 3 in this phase" severity FAILURE;
			assert exp_over = '1' report "The flag exp_field_over is not set" severity FAILURE;
			st := exp_status;
			assert st(0)(1) = '1' report "The status does not have exp_field_over" severity FAILURE;
			report "Exponents of 2 bits in the packets with input exponents to 7: the flag exp_field_over is set (phase " & integer'image(phase) & ")";
		end if;

		-- Phase 4: resets of the transmitter while the frames flow, as the host does them (tx_reset = 1, then 0), at
		-- SWEEP moments of two sets of 16 frames (the write side is in its bank 0, then in its bank 1). After each one:
		-- the first packet has the timestamp 0 and the set of frames that was complete, the exponents are those of
		-- their samples (one exponent for 2 frames; the model checks every packet), and the flag overrun stays at 0.
		run(TRUE, 1, 2, 0, EB = 3);
		total := total + dut_pkts;
		assert exp_over = '0' report "The flag exp_field_over stays after tx_reset" severity FAILURE;
		for k in 0 to SWEEP - 1 loop
			-- A moment in the two sets of 16 frames: frame, then word
			wait until rising_edge(clk) and widx = 0 and (fidx mod 32) = (k * 32) / SWEEP;
			for i in 1 to (k * 7) mod WORDS loop wait until rising_edge(clk); end loop;
			control(1, 16#BE#);
			for i in 1 to 40 loop wait until rising_edge(clk); end loop;
			assert d_tvalid = '0' report "A word at the output while the transmitter is in reset" severity FAILURE;
			txr_ev <= txr_ev + 1;
			control(1, 16#AE#);
			wait_packets(BLOCKS * NPKT);
			total := total + dut_pkts;
			flags_clear("Reset of the transmitter " & integer'image(k));
		end loop;
		report "Phase 4: " & integer'image(SWEEP) & " resets of the transmitter while the frames flow: overrun = 0 and right packets after each one (phase " & integer'image(phase) & ")";

		-- Phase 5: the header of packet 1 has wrong bits for the bins with exponents
		run(TRUE, 2, 0, 0, EB = 3, wrong_header => 1);
		total := total + dut_pkts;
		for i in 1 to 64 loop wait until rising_edge(clk); end loop;
		st := exp_status;
		assert mismatch_flag = '1' and st(0)(2) = '1' report "The flag exponent_bins_mismatch is not set" severity FAILURE;
		assert mismatch_count >= BLOCKS and mismatch_count <= BLOCKS + 1 and st(3) = std_logic_vector(mismatch_count)
			report "The counter exponent_bins_mismatch_count has " & integer'image(to_integer(mismatch_count)) & " for " & integer'image(BLOCKS) & " sets of 16 frames" severity FAILURE;
		report "Phase 5: the header of one packet has wrong bits for the bins with exponents: exponent_bins_mismatch = 1, " & integer'image(to_integer(mismatch_count)) & " packets counted (phase " & integer'image(phase) & ")";

		-- Phase 6: the tables of the bins with an exponent change while the frames flow (one exponent for 4 frames). The bins of a packet with
		-- exponents are those that the inputs gave in the last of its 16 frames; the headers are those of the old tables.
		run(TRUE, 2, 0, 0, EB = 3, count => NPKT);
		flags_clear("Before the change of the tables");
		for i in 1 to 5 * WORDS + 3 loop wait until rising_edge(clk); end loop;
		make_table(2, 0);
		wait_packets((BLOCKS + 2) * NPKT);
		for i in 1 to 2 * WORDS loop wait until rising_edge(clk); end loop;
		make_table(3, 30);
		wait_packets((2 * BLOCKS + 4) * NPKT);
		total := total + dut_pkts;
		assert mismatch_flag = '1' report "The tables changed and the flag exponent_bins_mismatch is not set" severity FAILURE;
		assert overrun = '0' report "Overrun of the readout" severity FAILURE;
		report "Phase 6: the tables of the bins with an exponent change two times while the frames flow: " & integer'image(dut_pkts) & " packets right (phase " & integer'image(phase) & ")";

		-- Phase 7: a playlist that is too long for a set of 16 frames (all the bins with exponents, one exponent for 2 frames)
		complete_pkts := 0; stopped_pkts := 0;
		run(TRUE, 1, 0, 0, EB = 3, np => NP_LONG, count => 5 * NP_LONG / 2);
		total := total + dut_pkts;
		st := exp_status;
		assert overrun = '1' and st(0)(0) = '1' report "The readout is too long for a set of 16 frames and the flag overrun is not set" severity FAILURE;
		assert complete_pkts >= 2 * NP_LONG and stopped_pkts >= 1 report "Phase 7: " & integer'image(complete_pkts) & " complete packets and " & integer'image(stopped_pkts) & " packets that were stopped" severity FAILURE;
		report "Phase 7: the readout is too long for a set of 16 frames: overrun = 1, " & integer'image(complete_pkts) & " complete packets right, " & integer'image(stopped_pkts) & " packets stopped with an even number of words (phase " & integer'image(phase) & ")";

		-- Phase 8: a reset in the middle of the stream and of a readout (one exponent for 8 frames, random tables)
		run(TRUE, 3, 2, 0, EB = 3);
		total := total + dut_pkts;
		for i in 1 to 16 * WORDS - READOUT / 2 + 3 loop wait until rising_edge(clk); end loop;
		rst <= '1';
		for i in 1 to 5 loop wait until rising_edge(clk); end loop;
		phase <= phase + 1;
		rst <= '0';
		wait_packets(BLOCKS * NPKT);
		total := total + dut_pkts;
		flags_clear("Reset in the stream");
		report "Phase 8: " & integer'image(dut_pkts) & " packets after a reset in the middle of the stream (phase " & integer'image(phase) & ")";

		for d in 1 to EMAX loop -- a tie above 0 is possible with shifts of 1 to 3 only, and a tie below 0 with 1 to 4 (-8 / 16)
			report "Shift by " & integer'image(d) & ": " & integer'image(shift_seen(d)) & " parts, " & integer'image(tie_pos(d)) & " ties above 0, " & integer'image(tie_neg(d)) & " ties below 0";
			assert shift_seen(d) > 0 and (tie_pos(d) > 0 or d > 3) and (tie_neg(d) > 0 or d > 4) report "No tie of each sign with a shift of " & integer'image(d) severity FAILURE;
		end loop;
		report "Packets with no exponent word: " & integer'image(pk_none) & ", with a word of zeros after the exponents: " & integer'image(pk_pad) & ", with none: " & integer'image(pk_even)
		     & ". Bins with exponents: " & integer'image(bins_with) & " (" & integer'image(mixed_bins) & " not in all the inputs), with none: " & integer'image(bins_without)
		     & ". Pauses measured: " & integer'image(gaps_checked);
		assert pk_none > 0 and pk_pad > 0 and (pk_even > 0 or NBINS < 3) and bins_with > 0 and bins_without > 0 and mixed_bins > 0 and gaps_checked > 0 report "A case of the exponent words was not in the test" severity FAILURE;
		report "UPACK EXPONENT TEST PASSED: " & integer'image(total) & " packets, exponents of " & integer'image(EB) & " bits, " & integer'image(NPKT) & " packets of " & integer'image(NBINS) & " bins for each set of 16 frames, frames of " & integer'image(WORDS) & " words";
		done <= TRUE;
		wait;
	end process main_proc;
end architecture sim;
