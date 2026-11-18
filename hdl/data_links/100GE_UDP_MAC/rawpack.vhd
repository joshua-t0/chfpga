----------------------------------------------------------------------------------
-- Company:  McGill University
--
-- Create Date: 2026-11-18
-- Design Name: chfpga
-- Module Name: rawpack
-- Target Devices: Zynq Ultrascale+ RfSoC
-- Tool Versions: Vivado 2022.2
-- Description: Raw ADC sample packetizer for the 100G Ethernet link (cge)
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.ALL;

library work;
use work.chFPGA_Package.ALL;

-- Streams raw ADC samples of one or two channels as UDP packets for the 100G MAC (``cge``). Each sample is
-- sent as 12 bits: the 12 most significant bits of the 14-bit ADC sample (the 2 low bits are dropped).
--
-- The module taps the capture bus that feeds UCAP (8 samples per clock per channel, each sample
-- MSB-aligned in 16 bits). Two channels (A and B) are selected at run time. The data source of each
-- channel (0 = FUNCGEN output, i.e. ADC or test pattern, 1 = SCALER output) is the one currently
-- selected by UCAP (UCAP control byte 9); ``rawpack`` only reports it in the packet header. Both
-- channels should use the same source. The frame timing is taken from the source of channel A.
--
-- Data rate: 2 channels x 8 samples x 12 bits = 192 bits per clock (76.8 Gb/s at 400 MHz). A 3:4
-- gearbox packs 4 input words (a "block", 32 sample times) into 3 words of 256 bits. Each packet
-- carries ``blocks_per_packet`` blocks preceded by two 32-byte header words.
--
-- In single-channel mode only channel A is sent (38.4 Gb/s). Two consecutive input words then take
-- the place of the two channels, so a block is 8 input words (64 sample times) and both the bit
-- rate and the packet rate are halved. The block and packet sizes in bytes are the same.
--
-- Output bus: 256-bit non-blocking AXI4-Stream in the format expected by ``cge``: the first byte on
-- the wire is the most significant byte of the word.
--
-- When the module is disabled, the ``s_axis_in`` bus (normally from ``upack``) is passed to the
-- output with one clock of latency. The two streams are mutually exclusive: stop the upstream
-- transmitter before enabling ``rawpack``. When ``enable`` is cleared, the packet in progress is
-- completed before the output is handed back.
--
-- Packet format (all multi-byte header fields are big-endian)
--
--   Bytes 0-13   Ethernet header (dest MAC, source MAC, ethertype 0x0800)
--   Bytes 14-33  IPv4 header (no options, DF set, TTL 64, protocol UDP, valid header checksum)
--   Bytes 34-41  UDP header (checksum = 0, i.e. not used)
--   Bytes 42-63  Raw stream header:
--       42-43  magic 0x5241 ("RA")
--       44     format version (2 = 12-bit samples, little-endian bit packing)
--       45     flags: bit 0 = data source of channel A, bit 1 = data source of channel B,
--                     bit 2 = single-channel mode (only channel A is in the packet),
--                     bit 6 = framing error (sticky), bit 7 = internal FIFO overflow (sticky)
--       46     channels: bits 2:0 = channel A, bits 6:4 = channel B (not sent in single-channel mode)
--       47     blocks_per_packet
--       48-53  packet counter (48 bits), zero at reset, counts every packet sent
--       54-59  frame number (48 bits) of the first sample of the packet. Counts frames since the
--              channelizer reset, like the UCAP timestamp.
--       60-61  word number (0-2047) of the first sample of the packet within its frame. The first
--              sample is sample number 8 * word of that frame.
--       62     stream number: incremented every time the stream starts (when it is enabled, and when
--              it restarts after a packetizer reset). The packet counter restarts at zero only on a
--              reset, so a change of stream number tells a receiver that the counter may have restarted.
--       63     reserved (0)
--   Bytes 64...  96 * blocks_per_packet bytes of samples.
--
-- Sample packing: the payload is a little-endian bit stream, i.e. stream bit n is bit (n mod 8) of
-- payload byte (n / 8). Sample number i of the packet occupies stream bits 12*i to 12*i+11 (LSB
-- first). Samples are interleaved in time order: A(t), B(t), A(t+1), B(t+1), ... In single-channel
-- mode the samples are A(t), A(t+1), A(t+2), ... Every 2 samples fill exactly 3 bytes. A sample
-- value is the 14-bit ADC sample divided by 4 (signed, -2048 to 2047). The first packet after
-- ``enable`` starts on the first word of a frame. With the default 64 blocks per packet, a packet
-- holds 2048 sample times of two channels and a frame of 16384 samples is exactly 8 packets.
--
entity rawpack is
	generic (
		NUMBER_OF_CHANNELS: integer := 8;
		NUMBER_OF_SOURCES: integer  := 2;

		DEFAULT_ENABLE: std_logic                         := '0';
		DEFAULT_SINGLE: std_logic                         := '0'; -- '1': send channel A only
		DEFAULT_CHAN_A: integer range 0 to 7              := 0;
		DEFAULT_CHAN_B: integer range 0 to 7              := 1;
		DEFAULT_BLOCKS_PER_PACKET: integer range 4 to 90  := 64; -- 64 blocks = 6144 bytes of samples, 8 packets per frame
		DEFAULT_MAC_SRC_ADDR: slv48  := X"005d03000000";
		DEFAULT_MAC_DEST_ADDR: slv48 := X"FFFFFFFFFFFF"; -- Ethernet broadcast
		DEFAULT_IP_SRC_ADDR: slv32   := X"0AC00002";
		DEFAULT_IP_DEST_ADDR: slv32  := X"FFFFFFFF";
		DEFAULT_IP_SRC_PORT: slv16   := X"A027";
		DEFAULT_IP_DEST_PORT: slv16  := X"A028"
	);
	port (
		-- Capture bus (same bus as UCAP), synchronous to clk
		s_axis_raw_tdata  : in slv_array(0 to NUMBER_OF_CHANNELS - 1)(127 downto 0); -- 8 samples x 16 bits per channel; as on the UCAP bus, the first sample in time is in the most significant 16 bits
		s_axis_raw_tvalid : in std_logic_vector(0 to NUMBER_OF_SOURCES - 1); -- one per data source, common to all channels
		s_axis_raw_tlast  : in std_logic_vector(0 to NUMBER_OF_SOURCES - 1); -- last word of a frame, one per data source
		source_sel_in     : in std_logic_vector(0 to NUMBER_OF_CHANNELS - 1) := (others => '0'); -- data source currently on tdata for each channel
		raw_rst           : in std_logic := '0'; -- resets the frame counters. Use the same reset as UCAP to get the same frame numbers.

		-- Pass-through input (used when rawpack is disabled)
		s_axis_in_tdata  : in std_logic_vector(255 downto 0) := (others => '0');
		s_axis_in_tvalid : in std_logic                      := '0';
		s_axis_in_tlast  : in std_logic                      := '0';

		-- Output to cge
		m_axis_out_tdata  : out std_logic_vector(255 downto 0);
		m_axis_out_tvalid : out std_logic := '0';
		m_axis_out_tlast  : out std_logic := '0';

		clk : in std_logic;
		rst : in std_logic; -- synchronous reset of the packetizer

		-- Control and reply streams
		s_axis_bsb_tdata  : in std_logic_vector(7 downto 0) := (others => '0');
		s_axis_bsb_tvalid : in std_logic                    := '0';
		s_axis_bsb_tlast  : in std_logic                    := '0';
		s_axis_bsb_tready : out std_logic;
		m_axis_bsb_tdata  : out std_logic_vector(7 downto 0);
		m_axis_bsb_tvalid : out std_logic;
		m_axis_bsb_tlast  : out std_logic;
		m_axis_bsb_tready : in std_logic                    := '0';
		bsb_clk           : in std_logic                    := '0';
		bsb_rst           : in std_logic                    := '0'
	);
end entity rawpack;

architecture impl of rawpack is

	constant SAMPLES_PER_WORD: integer := 8;
	constant IN_BITS_PER_SAMPLE: integer := 16; -- capture bus sample width (sample is MSB-aligned)
	constant BITS_PER_SAMPLE: integer := 12; -- bits sent per sample: the MSBs of the capture bus sample
	constant PACKED_WIDTH: integer := 2 * SAMPLES_PER_WORD * BITS_PER_SAMPLE; -- 192 bits per clock
	constant GEARBOX_STEP: integer := 256 - PACKED_WIDTH; -- 64: bits that each output word takes from the next input word, more than the previous one
	constant FORMAT_VERSION: std_logic_vector(7 downto 0) := X"02";

	-- bsb_regs indexes this vector from 0 (byte 0 bit 7 = element 0), so the range must be ascending
	constant DEFAULT_CONTROL_BYTES: std_logic_vector(0 to 28 * 8 - 1) :=
		"000000" & DEFAULT_SINGLE & DEFAULT_ENABLE &                                    -- byte 0
		'0' & to_slv(DEFAULT_CHAN_B, 3) & '0' & to_slv(DEFAULT_CHAN_A, 3) &             -- byte 1
		to_slv(DEFAULT_BLOCKS_PER_PACKET, 8) &                                          -- byte 2
		X"00" &                                                                         -- byte 3
		DEFAULT_MAC_DEST_ADDR & DEFAULT_MAC_SRC_ADDR &                                  -- bytes 4-15
		DEFAULT_IP_DEST_ADDR & DEFAULT_IP_SRC_ADDR &                                    -- bytes 16-23
		DEFAULT_IP_DEST_PORT & DEFAULT_IP_SRC_PORT;                                     -- bytes 24-27

	signal control_bytes: slv8_array(0 to 27);
	signal status_bytes: slv8_array(0 to 8);

	signal cmd_dat_int_tdata: std_logic_vector(7 downto 0);
	signal cmd_dat_int_tvalid: std_logic;
	signal cmd_dat_int_tlast: std_logic;
	signal cmd_rdy_int_tready: std_logic;
	signal rply_dat_int_tdata: std_logic_vector(7 downto 0);
	signal rply_dat_int_tvalid: std_logic;
	signal rply_dat_int_tlast: std_logic;
	signal rply_rdy_int_tready: std_logic;
	signal ctrl_rst_int: std_logic;

	-- Registered control values
	signal enable: std_logic := '0';
	signal single: std_logic := '0';
	signal sel_a, sel_b: unsigned(2 downto 0) := (others => '0');
	signal blocks_per_packet: unsigned(7 downto 0) := (others => '0');
	signal last_block: unsigned(7 downto 0) := (others => '0'); -- blocks_per_packet - 1
	signal last_word: unsigned(10 downto 0) := (others => '0'); -- 3 * blocks_per_packet - 1
	signal src_port_mask: std_logic_vector(7 downto 0);
	signal mac_dest, mac_src: slv48;
	signal ip_dest, ip_src: slv32;
	signal port_dest, port_src: slv16;

	-- Frame tracking, one per data source
	signal frame_ctr: u48_array(0 to NUMBER_OF_SOURCES - 1) := (others => (others => '0'));
	type u11_array_t is array (natural range <>) of unsigned(10 downto 0);
	signal word_ctr: u11_array_t(0 to NUMBER_OF_SOURCES - 1) := (others => (others => '0'));

	-- Stage 0: channel selection
	signal a0, b0: std_logic_vector(127 downto 0);
	signal v0: std_logic := '0';
	signal ts0: unsigned(47 downto 0);
	signal w0: unsigned(10 downto 0);
	signal src_a, src_b: std_logic := '0';

	-- Stage 1: 12-bit packing
	signal d1: std_logic_vector(PACKED_WIDTH - 1 downto 0);
	signal v1: std_logic := '0';
	signal ts1: unsigned(47 downto 0);
	signal w1: unsigned(10 downto 0);

	-- Stage 2: 3:4 gearbox
	signal running: std_logic := '0';
	signal phase: unsigned(1 downto 0) := (others => '0'); -- input word number in the block
	signal block_ctr: unsigned(7 downto 0) := (others => '0'); -- block number in the packet
	signal hold: std_logic_vector(PACKED_WIDTH - 1 downto 0);
	signal gbx_tdata: std_logic_vector(255 downto 0);
	signal gbx_tvalid: std_logic := '0';
	signal gbx_sop: std_logic := '0'; -- first data word of a packet
	signal sop_pending: std_logic := '0';
	signal hdr_ts: unsigned(47 downto 0) := (others => '0');
	signal hdr_word: unsigned(10 downto 0) := (others => '0');
	signal stream_number: unsigned(7 downto 0) := (others => '0'); -- not cleared by rst, so a restart after a reset is visible

	-- Elastic buffer between the gearbox (3 words every 4 clocks) and the packet sequencer (which
	-- needs 2 clocks per packet to insert the header). It never holds more than a few words.
	constant FIFO_ADDR_WIDTH: integer := 4;
	type fifo_ram_type is array (0 to 2 ** FIFO_ADDR_WIDTH - 1) of std_logic_vector(256 downto 0);
	signal fifo_ram: fifo_ram_type;
	attribute ram_style: string;
	attribute ram_style of fifo_ram: signal is "distributed";
	signal fifo_wr_ptr, fifo_rd_ptr: unsigned(FIFO_ADDR_WIDTH downto 0) := (others => '0');
	signal fifo_head: std_logic_vector(256 downto 0);
	signal fifo_empty, fifo_full: std_logic;
	signal fifo_overflow_sticky: std_logic := '0';
	signal framing_error_sticky: std_logic := '0';

	-- Header
	signal udp_length, ip_length: unsigned(15 downto 0);
	signal csum_a, csum_b, csum_c: unsigned(16 downto 0);
	signal csum_total: unsigned(19 downto 0);
	signal ip_checksum: std_logic_vector(15 downto 0);
	signal port_src_eff: unsigned(15 downto 0);
	signal header1, header2: std_logic_vector(255 downto 0);
	signal flags: std_logic_vector(7 downto 0);

	-- Packet sequencer
	type tx_state_type is (IDLE, SEND_HEADER2, SEND_DATA);
	signal tx_state: tx_state_type := IDLE;
	signal tx_word_ctr: unsigned(10 downto 0) := (others => '0');
	signal packet_ctr: unsigned(47 downto 0) := (others => '0');
	signal pkt_tdata: std_logic_vector(255 downto 0);
	signal pkt_tvalid: std_logic := '0';
	signal pkt_tlast: std_logic := '0';
	signal raw_active: std_logic := '0';

begin

	-- Bridge the BSB bus to the clk domain so all the registers are synchronous to the data path.
	bsb_fifo0: entity work.bsb_async_fifo
		port map (
			cmd_a_tdata   => s_axis_bsb_tdata,
			cmd_a_tvalid  => s_axis_bsb_tvalid,
			cmd_a_tlast   => s_axis_bsb_tlast,
			cmd_a_tready  => s_axis_bsb_tready,
			rply_a_tdata  => m_axis_bsb_tdata,
			rply_a_tvalid => m_axis_bsb_tvalid,
			rply_a_tlast  => m_axis_bsb_tlast,
			rply_a_tready => m_axis_bsb_tready,
			a_clk         => bsb_clk,

			cmd_b_tdata   => cmd_dat_int_tdata,
			cmd_b_tvalid  => cmd_dat_int_tvalid,
			cmd_b_tlast   => cmd_dat_int_tlast,
			cmd_b_tready  => cmd_rdy_int_tready,
			rply_b_tdata  => rply_dat_int_tdata,
			rply_b_tvalid => rply_dat_int_tvalid,
			rply_b_tlast  => rply_dat_int_tlast,
			rply_b_tready => rply_rdy_int_tready,
			b_clk         => clk,

			rst       => bsb_rst,
			b_rst_out => ctrl_rst_int
		);

	-- Memory Map
	-- ------------------------------------------------------------------------------------------
	-- |  Page   | Addr |Bit(s)|     Name            | Description                               |
	-- |---------|------|------|---------------------|-------------------------------------------|
	-- | CONTROL |  0   |  0   | enable              | '1': stream raw samples. '0': pass the upstream bus through |
	-- |         |      |  1   | single              | '1': send channel A only (half the data rate). Taken into account only while the stream is stopped (raw_active = 0). |
	-- |         |  1   | 2:0  | chan_a              | First channel to stream (0-7)             |
	-- |         |      | 6:4  | chan_b              | Second channel to stream (0-7)            |
	-- |         |  2   | 7:0  | blocks_per_packet   | Blocks (96 bytes: 32 sample times of 2 channels or 64 of one) per packet. 4 to 90. Taken into account only while the stream is stopped (raw_active = 0). |
	-- |         |  3   | 7:0  | src_port_mask       | UDP source port = src_port + (packet counter and mask) |
	-- |         | 4-9  | 47:0 | mac_dest            | Destination MAC address                   |
	-- |         |10-15 | 47:0 | mac_src             | Source MAC address                        |
	-- |         |16-19 | 31:0 | ip_dest             | Destination IP address                    |
	-- |         |20-23 | 31:0 | ip_src              | Source IP address                         |
	-- |         |24-25 | 15:0 | port_dest           | UDP destination port                      |
	-- |         |26-27 | 15:0 | port_src            | UDP source port                           |
	-- | STATUS  |  0   |  0   | running             | Samples are being packed                  |
	-- |         |      |  1   | raw_active          | The output bus carries the raw stream     |
	-- |         |      |  2   | fifo_overflow       | Internal FIFO overflow (sticky until reset) |
	-- |         |      |  3   | framing_error       | Packet framing error (sticky until reset) |
	-- |         |  1   | 7:0  | packet_ctr          | Low 8 bits of the packet counter          |
	-- |         |  2   | 7:0  | source_sel          | Data source of each channel (bit 0 = channel 0) |
	-- |         | 3-8  | 47:0 | packet_ctr_full     | Packet counter (48 bits). The bytes are read one at a time: read it when the stream is stopped. |
	-- ------------------------------------------------------------------------------------------
	bsb_regs0: entity work.bsb_regs
		generic map (
			DEFAULT_CONTROL_BYTES   => DEFAULT_CONTROL_BYTES,
			NUMBER_OF_CONTROL_BYTES => control_bytes'Length(1),
			NUMBER_OF_STATUS_BYTES  => status_bytes'Length(1)
		)
		port map (
			s_axis_bsb_tdata  => cmd_dat_int_tdata,
			s_axis_bsb_tvalid => cmd_dat_int_tvalid,
			s_axis_bsb_tlast  => cmd_dat_int_tlast,
			s_axis_bsb_tready => cmd_rdy_int_tready,
			m_axis_bsb_tdata  => rply_dat_int_tdata,
			m_axis_bsb_tvalid => rply_dat_int_tvalid,
			m_axis_bsb_tlast  => rply_dat_int_tlast,
			m_axis_bsb_tready => rply_rdy_int_tready,
			bsb_clk           => clk,
			bsb_rst           => ctrl_rst_int,

			control_bytes => control_bytes,
			status_bytes  => status_bytes
		);

	status_bytes(0) <= (0 => running, 1 => raw_active, 2 => fifo_overflow_sticky, 3 => framing_error_sticky, others => '0');
	status_bytes(1) <= std_logic_vector(packet_ctr(7 downto 0));
	status_bytes(2) <= reverse_bits_and_dir(source_sel_in);
	status_bytes(3 to 8) <= to_slv8_array(packet_ctr);

	-- Register the control values and pre-compute everything that depends only on them. These
	-- values are static while the stream is running.
	ctrl_proc: process(all)
		variable bpp: unsigned(10 downto 0);
		variable ip_header: std_logic_vector(20 * 8 - 1 downto 0);
		variable udp_header: std_logic_vector(8 * 8 - 1 downto 0);
		variable fold: unsigned(16 downto 0);
	begin
		if rising_edge(clk) then
			enable <= control_bytes(0)(0);
			sel_a <= unsigned(control_bytes(1)(2 downto 0));
			sel_b <= unsigned(control_bytes(1)(6 downto 4));
			-- The mode and the packet size are taken only while the raw stream is completely stopped,
			-- so a change made while it runs (or before the last packet is out) cannot corrupt a packet.
			if not raw_active then
				single <= control_bytes(0)(1);
				blocks_per_packet <= unsigned(control_bytes(2));
			end if;
			src_port_mask <= control_bytes(3);
			mac_dest <= std_logic_vector(to_unsigned(control_bytes(4 to 9)));
			mac_src <= std_logic_vector(to_unsigned(control_bytes(10 to 15)));
			ip_dest <= std_logic_vector(to_unsigned(control_bytes(16 to 19)));
			ip_src <= std_logic_vector(to_unsigned(control_bytes(20 to 23)));
			port_dest <= std_logic_vector(to_unsigned(control_bytes(24 to 25)));
			port_src <= std_logic_vector(to_unsigned(control_bytes(26 to 27)));

			-- Packet geometry: 3 data words per block
			bpp := resize(blocks_per_packet, 11);
			last_block <= blocks_per_packet - 1;
			last_word <= shift_left(bpp, 1) + bpp - 1;

			-- Lengths: UDP header (8) + raw stream header (22) + 32 bytes per data word
			udp_length <= 30 + shift_left(resize(last_word + 1, 16), 5);
			ip_length <= 20 + udp_length;

			-- IP header checksum, computed over three clocks. Constant header words:
			-- 0x4500 (version/length/DSCP), 0x0000 (ID), 0x4000 (don't fragment), 0x4011 (TTL 64, UDP).
			csum_a <= resize(ip_length, 17) + X"4500";
			csum_b <= resize(unsigned(ip_src(31 downto 16)), 17) + unsigned(ip_src(15 downto 0));
			csum_c <= resize(unsigned(ip_dest(31 downto 16)), 17) + unsigned(ip_dest(15 downto 0));
			csum_total <= resize(csum_a, 20) + csum_b + csum_c + X"8011";
			fold := resize(csum_total(15 downto 0), 17) + csum_total(19 downto 16);
			fold := resize(fold(15 downto 0), 17) + fold(16 downto 16); -- add the carry back (1's complement sum)
			ip_checksum <= not std_logic_vector(fold(15 downto 0));

			-- Rotating the source port lets the receiving NIC spread the packets over its receive queues
			port_src_eff <= unsigned(port_src) + unsigned(packet_ctr(7 downto 0) and unsigned(src_port_mask));

			flags <= (0 => src_a, 1 => src_b, 2 => single, 6 => framing_error_sticky, 7 => fifo_overflow_sticky, others => '0');

			-- Header words. The first byte on the wire is the most significant byte.
			ip_header := X"4500" & std_logic_vector(ip_length) & X"0000" & X"4000" & X"40" & X"11" & ip_checksum & ip_src & ip_dest;
			udp_header := std_logic_vector(port_src_eff) & port_dest & std_logic_vector(udp_length) & X"0000";
			header1 <= mac_dest & mac_src & X"0800" & ip_header(20 * 8 - 1 downto 2 * 8);
			header2 <= ip_header(15 downto 0) & udp_header &
			           X"5241" & FORMAT_VERSION & flags &
			           '0' & std_logic_vector(sel_b) & '0' & std_logic_vector(sel_a) &
			           std_logic_vector(blocks_per_packet) &
			           std_logic_vector(packet_ctr) &
			           std_logic_vector(hdr_ts) &
			           "00000" & std_logic_vector(hdr_word) &
			           std_logic_vector(stream_number) & X"00";
		end if;
	end process ctrl_proc;

	-- Count the frames and words of every data source, like UCAP does, so the frame numbers are
	-- valid whichever source is selected.
	frame_proc: process(all) begin
		if rising_edge(clk) then
			for src in 0 to NUMBER_OF_SOURCES - 1 loop
				if s_axis_raw_tvalid(src) then
					word_ctr(src) <= word_ctr(src) + 1;
					if s_axis_raw_tlast(src) then
						word_ctr(src) <= (others => '0');
						frame_ctr(src) <= frame_ctr(src) + 1;
					end if;
				end if;
			end loop;
			if raw_rst then
				word_ctr <= (others => (others => '0'));
				frame_ctr <= (others => (others => '0'));
			end if;
		end if;
	end process frame_proc;

	-- Stages 0 and 1: select the two channels, then keep the 12 MSBs of each sample and interleave
	-- the channels in time order. In single-channel mode, two consecutive words of channel A (an even
	-- word of the frame, then the odd word that follows) are joined instead.
	sel_proc: process(all)
		variable src: integer range 0 to NUMBER_OF_SOURCES - 1;
		variable pa, pb: std_logic_vector(SAMPLES_PER_WORD * BITS_PER_SAMPLE - 1 downto 0); -- the 8 samples of each channel, 12 bits each
	begin
		if rising_edge(clk) then
			src_a <= source_sel_in(to_integer(sel_a));
			src_b <= source_sel_in(to_integer(sel_b));
			src := to_integer(unsigned'("" & source_sel_in(to_integer(sel_a))));

			a0 <= s_axis_raw_tdata(to_integer(sel_a));
			b0 <= s_axis_raw_tdata(to_integer(sel_b));
			v0 <= s_axis_raw_tvalid(src);
			ts0 <= frame_ctr(src);
			w0 <= word_ctr(src);

			-- Sample s in time order is in input slot 7-s (the first sample is in the MSBs of the capture
			-- word). It goes to position s of pa/pb so that the output bit stream is in time order.
			for s in 0 to SAMPLES_PER_WORD - 1 loop
				pa((s + 1) * BITS_PER_SAMPLE - 1 downto s * BITS_PER_SAMPLE) := a0((SAMPLES_PER_WORD - s) * IN_BITS_PER_SAMPLE - 1 downto (SAMPLES_PER_WORD - s) * IN_BITS_PER_SAMPLE - BITS_PER_SAMPLE);
				pb((s + 1) * BITS_PER_SAMPLE - 1 downto s * BITS_PER_SAMPLE) := b0((SAMPLES_PER_WORD - s) * IN_BITS_PER_SAMPLE - 1 downto (SAMPLES_PER_WORD - s) * IN_BITS_PER_SAMPLE - BITS_PER_SAMPLE);
			end loop;

			if single then
				-- Frames have an even number of words, so the word number tells which half this is
				v1 <= '0';
				if v0 then
					if w0(0) = '0' then
						d1(PACKED_WIDTH / 2 - 1 downto 0) <= pa;
						ts1 <= ts0;
						w1 <= w0;
					else
						d1(PACKED_WIDTH - 1 downto PACKED_WIDTH / 2) <= pa;
						v1 <= '1';
					end if;
				end if;
			else
				for s in 0 to SAMPLES_PER_WORD - 1 loop
					d1((2 * s + 1) * BITS_PER_SAMPLE - 1 downto (2 * s) * BITS_PER_SAMPLE) <= pa((s + 1) * BITS_PER_SAMPLE - 1 downto s * BITS_PER_SAMPLE);
					d1((2 * s + 2) * BITS_PER_SAMPLE - 1 downto (2 * s + 1) * BITS_PER_SAMPLE) <= pb((s + 1) * BITS_PER_SAMPLE - 1 downto s * BITS_PER_SAMPLE);
				end loop;
				v1 <= v0;
				ts1 <= ts0;
				w1 <= w0;
			end if;

			if rst then
				v0 <= '0';
				v1 <= '0';
			end if;
		end if;
	end process sel_proc;

	-- Stage 2: 3:4 gearbox. Four 192-bit input words make three 256-bit output words. Output word
	-- j of a block is made of the last 192-64j bits of input word j and the first 64(j+1) bits of
	-- input word j+1, so no output is produced on the first input word of a block.
	gbx_proc: process(all)
		variable accept: boolean;
	begin
		if rising_edge(clk) then
			gbx_tvalid <= '0';
			accept := FALSE;

			if v1 then
				if running then
					if phase = 0 and block_ctr = 0 and enable = '0' then
						running <= '0'; -- stop on a packet boundary so the last packet is complete
					else
						accept := TRUE;
					end if;
				elsif enable = '1' and w1 = 0 then
					running <= '1'; -- start on the first word of a frame
					stream_number <= stream_number + 1;
					accept := TRUE;
				end if;
			end if;

			if accept then
				hold <= d1;
				if phase = 0 then
					if block_ctr = 0 then -- first word of a packet: remember where the packet starts
						hdr_ts <= ts1;
						hdr_word <= w1;
						sop_pending <= '1';
					end if;
				else
					for p in 1 to 3 loop
						if phase = p then
							gbx_tdata <= d1(GEARBOX_STEP * p - 1 downto 0) & hold(PACKED_WIDTH - 1 downto GEARBOX_STEP * (p - 1));
						end if;
					end loop;
					gbx_tvalid <= '1';
					gbx_sop <= sop_pending;
					sop_pending <= '0';
				end if;

				phase <= phase + 1;
				if phase = 3 then
					if block_ctr = last_block then
						block_ctr <= (others => '0');
					else
						block_ctr <= block_ctr + 1;
					end if;
				end if;
			end if;

			if rst then
				running <= '0';
				phase <= (others => '0');
				block_ctr <= (others => '0');
				gbx_tvalid <= '0';
				sop_pending <= '0';
			end if;
		end if;
	end process gbx_proc;

	-- Elastic buffer (distributed RAM, asynchronous read)
	fifo_empty <= '1' when fifo_wr_ptr = fifo_rd_ptr else '0';
	fifo_full <= '1' when fifo_wr_ptr(FIFO_ADDR_WIDTH) /= fifo_rd_ptr(FIFO_ADDR_WIDTH) and fifo_wr_ptr(FIFO_ADDR_WIDTH - 1 downto 0) = fifo_rd_ptr(FIFO_ADDR_WIDTH - 1 downto 0) else '0';
	fifo_head <= fifo_ram(to_integer(fifo_rd_ptr(FIFO_ADDR_WIDTH - 1 downto 0)));

	fifo_wr_proc: process(all) begin
		if rising_edge(clk) then
			if gbx_tvalid then
				if fifo_full then
					fifo_overflow_sticky <= '1'; -- the word is dropped
				else
					fifo_ram(to_integer(fifo_wr_ptr(FIFO_ADDR_WIDTH - 1 downto 0))) <= gbx_sop & gbx_tdata;
					fifo_wr_ptr <= fifo_wr_ptr + 1;
				end if;
			end if;
			if rst then
				fifo_wr_ptr <= (others => '0');
				fifo_overflow_sticky <= '0';
			end if;
		end if;
	end process fifo_wr_proc;

	-- Packet sequencer: two header words, then 3 * blocks_per_packet data words. A packet starts as
	-- soon as its first data word is in the buffer.
	tx_proc: process(all) begin
		if rising_edge(clk) then
			pkt_tvalid <= '0';
			pkt_tlast <= '0';

			case tx_state is
				when IDLE =>
					if not fifo_empty then
						if fifo_head(256) then
							pkt_tdata <= header1;
							pkt_tvalid <= '1';
							tx_state <= SEND_HEADER2;
						else -- not the start of a packet: discard until we are back in step
							fifo_rd_ptr <= fifo_rd_ptr + 1;
							framing_error_sticky <= '1';
						end if;
					end if;

				when SEND_HEADER2 =>
					pkt_tdata <= header2;
					pkt_tvalid <= '1';
					packet_ctr <= packet_ctr + 1;
					tx_word_ctr <= (others => '0');
					tx_state <= SEND_DATA;

				when SEND_DATA =>
					if not fifo_empty then
						-- The gearbox words are little-endian (stream bit 0 in bit 0); cge sends the most significant byte first.
						pkt_tdata <= reverse_bytes(fifo_head(255 downto 0));
						pkt_tvalid <= '1';
						fifo_rd_ptr <= fifo_rd_ptr + 1;
						tx_word_ctr <= tx_word_ctr + 1;
						if fifo_head(256) = '1' and tx_word_ctr /= 0 then
							framing_error_sticky <= '1';
						end if;
						if tx_word_ctr = last_word then
							pkt_tlast <= '1';
							tx_state <= IDLE;
						end if;
					end if;
			end case;

			if rst then
				tx_state <= IDLE;
				fifo_rd_ptr <= (others => '0');
				packet_ctr <= (others => '0');
				framing_error_sticky <= '0';
				pkt_tvalid <= '0';
				pkt_tlast <= '0';
			end if;
		end if;
	end process tx_proc;

	-- Output selection. The raw stream owns the output from ``enable`` until its last packet is out.
	out_proc: process(all) begin
		if rising_edge(clk) then
			raw_active <= enable or running or not fifo_empty or to_std_logic(tx_state /= IDLE) or gbx_tvalid;
			if raw_active or pkt_tvalid then
				m_axis_out_tdata <= pkt_tdata;
				m_axis_out_tvalid <= pkt_tvalid;
				m_axis_out_tlast <= pkt_tlast;
			else
				m_axis_out_tdata <= s_axis_in_tdata;
				m_axis_out_tvalid <= s_axis_in_tvalid;
				m_axis_out_tlast <= s_axis_in_tlast;
			end if;
			if rst then
				m_axis_out_tvalid <= '0';
				m_axis_out_tlast <= '0';
			end if;
		end if;
	end process out_proc;

end architecture impl;
