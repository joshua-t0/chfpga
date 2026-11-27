----------------------------------------------------------------------------------
-- Company:  McGill University
-- Engineer: JF Cliche
--
-- Create Date: 2023-02-20
-- Design Name: chfpga
-- Module Name: uram_ct
-- Project Name: CHORD
-- Target Devices: Zynq Ultrascale+ RfSoC
-- Tool Versions: Vivado 2022.1 +
-- Description: UltraRAM-based data packetizer
--
--
----------------------------------------------------------------------------------


library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.ALL;

library UNISIM;
use UNISIM.VComponents.ALL;

library xpm;
use xpm.vcomponents.ALL;


library work;
use work.chFPGA_Package.ALL;

-- Implements an UltraRAM-based data packetizer that stores multiple frames of incoming data in an UltraRAM matrix and reads them out in a specified order, including software-programmable header packets that can contain MAC/IP/UDP headers if needed. The module is meant to feed a 100G MAC, and packs the data in a way tat allows the efficient implementation of corner-turn operations using network switches. 
--
-- The input data shall be 4x 64-bit words, with 8192 words per frame. 16 such frames are stored before being read out. Readout reads selected 64-bit words 4 frames at a time. Two or Four such sets of frames can be read.  
--
-- Data storage is organized as a 4x4 UltraRAM matrix that is filled with channelizer data on one axis and is read out on the other axis.
--
-- Each frame contains 8k bins (16k samples / 2), spread into 4 columns. Each column has to store 8k/4 = 2k bins/frame/bank.
-- We have to store 16 frames (to fill a 128-byte GPU cache line with same-bin data, i.e. 8 samples * 16 frames= 128 bytes) & 2 banks (one is read while the other is written).
-- We therefore need to store 2k bins/col * 16 frames * 2 banks = 64k bins per column. Each bin is one address x 8 byte wide, we have 64K addresses, 4K per URAM, 16 URAM total/col.
-- The frames are spread in 4 rows (so we can read 4x8 =32 bytes in parallel), so we need 2k bins * 16 frames *2 banks/4 cells/col = 2k*8=16k bins/cell (14 bit address/cell)
-- An URAM can store 4k bins, so each cell of the 4x4 matrix is made of 2k*8/4k = 4 URAMs.
-- Each cell has 64 bit data (8 bytes) and 14 bits of address, in both the read and write ports.
-- The total write address space is 16 bits wide. This address selects the row; we write all 4 columns at the same time.
--
--    15:14: cell row number (4 rows)
--    13:12: uram select in cell (4 URAM/cell)
--    11:0: address in URAM (4kword/uram)
--
-- On the write side, we write data 4 bins at a time, accessing all 4 URAM in a row. The data from
-- one bin is contain in a 8-byte word. The word for each bin is written in a different URAM column.
-- Consecutive frames are written successive rows, looping back to the next line of row 0 every 4
-- frames. Each URAM cell can store 4 frames, for a total of 16 frames. Address bits are assigned as
--
--    15:14: frame_ctr(1:0) ( consecutive frames are stored in separate cells so 4 consecutive frames can be accessed simultaneously on the readout side)
--    13: bank ( 2 banks per cell)
--    12:11: frame_ctr(3:2) ( 4 frames per cell)
--    10:0: bin_ctr (2k bins)
--
-- On the read side, we read bins one column at a time, i.e. 4 frames at a time. We select which column based on the desired bin.
--
-- The buffer can be written using the BSB interface. This is a 8 bit wide interface.
-- The logical address space from the BSB point of view is:
--
--    20: bank (1 bit = 2 banks) -> from page register
--    19:16: frame (4 bits = 16 frames) => from page register
--    15:3 bin  (13 bits = 2k bins) => from bsb_ram_addr(15:3)
--    2:0: channel (3 bits = 8 channels) => from bsb_ram_addr(2:0)
--
-- 16 bits (bin and channel) are derived from the BSB write address directly.
-- The remaining address bins (frame and bank) are taken from paging registers. There are 32 pages of 64Kbytes.
-- Writing one 64K  page might require multiple transactions as to not overflow the command buffers and the Ethernet MTU.
--
-- Exponent mode (generic EXPONENT_BITS = 2 or 3)
--
-- Each input sample has an exponent of EXPONENT_BITS bits (value = sample x 2^exponent) and one bit that tells that
-- its bin has an exponent in its scaler (s_axis_in_texp, from the exponent mode of the scalers). The host writes the
-- bins that have an exponent in the scalers only: the packetizer has no table of bins.
--
-- The buffer keeps the exponent of each sample beside the data, for the two banks. The exponent bits of a bin of a
-- frame (8 inputs, input 0 in the MSBs: 16 bits, or 24 with EXPONENT_BITS = 3) are 8 bits in the byte of the 72-bit
-- UltraRAM word that the data does not use and the other 8 or 16 bits in more UltraRAMs with no cascade, read with
-- the address of the data: 8 UltraRAMs (2 for each frame row) with EXPONENT_BITS = 2, and 16 (4 for each frame row)
-- with EXPONENT_BITS = 3, which are then all the UltraRAMs that the device has more than the data buffer (UCAP has
-- no memory in that build). One block RAM has, for each bin and bank, one bit: one input or more told that the bin
-- has an exponent in the last frame that was written. The frames are written as with EXPONENT_BITS = 0, so a packet
-- with a timestamp has the same frames as with that entity.
--
-- A data bin of a packet (bit 13 of its entry in the playlist = '1'; the playlist is the list of the bins of each
-- packet, which the host writes) has exponents if that bit is 1 for the bank that is read: one input or more told so
-- in the last of the 16 frames of the packet. A header bin never has exponents.
--
-- With the control bit tx_exponents:
--   - The 16 frames of a bin with exponents are in groups of B frames (B = 2, 4, 8 or 16, control field exp_block =
--     log2(B) - 1; the groups start at frame 0 of the packet). For each input, the exponent E of a group is the
--     largest sample exponent in the group. A sample with a smaller exponent e has its two 4-bit parts divided by
--     2^(E - e), rounded to the nearest integer, a tie to the even integer. The 4 words of the bin are sent at their
--     place, as without exponents: the data bins of a packet are where they are without the mode.
--   - After the last data bin of a packet come the exponents of its bins that have exponents, in the order of the
--     bins. A bin gives 16 / B numbers, one for each group of frames, the first group first.
--       Exponents of 2 bits (control bit exp_field4 = '0'): the number of a group has 16 bits, most significant byte
--       first: input i has the bits 15 - 2i and 14 - 2i. A bin gives 32 / B bytes.
--       Exponents of 4 bits (exp_field4 = '1', only with EXPONENT_BITS = 3): the number of a group has 32 bits, most
--       significant byte first: input i has the bits 31 - 4i to 28 - 4i (0 to 7). A bin gives 64 / B bytes.
--     These numbers follow each other with no gap, and zeros follow to a multiple of 64 bytes: each packet must have
--     an even number of 32-byte words. (The path to the 100G MAC, cge, puts two 32-byte words in each word of its
--     FIFO. If a packet ends in the first half and the next packet starts on the next clock, the first word of that
--     packet goes to the MAC alone with only its upper 32 bytes enabled, and the packet is lost.) A packet with no bin
--     with exponents has no exponent bytes.
--   - After each packet the readout waits: a packet of W words takes W + (W - 1) / 32 + 1 clocks, so that the
--     packets do not come faster than the 100G link can send them (if not, the FIFO of cge fills during the readout
--     of a set of 16 frames and its last packets are lost).
--   - For each packet, the 48 bits in bytes 16 to 21 of the payload header (little endian; the host writes them:
--     bit k = 1 if data bin k of the packet has exponents) are compared with the bins that got exponents. If they
--     are not the same, the status flag exponent_bins_mismatch is set (it stays until tx_reset) and
--     exponent_bins_mismatch_count goes up by 1.
--   - The host must write the lengths in the headers for the exponent bytes.
--   - With EXPONENT_BITS = 3 and exponents of 2 bits, the host must limit the exponents of the scalers to 3
--     (exponent_max). An exponent of a group above 3 is sent as 3 and the status flag exp_field_over is set (it stays
--     until tx_reset): the values of that group are then wrong at the receiver.
-- No readout starts at the end of tx_reset: the first one starts when the set of 16 frames in progress is complete.
-- A readout keeps its bank to its end. If it is not complete when the next set of 16 frames is complete, the flag
-- overrun is set, the readout stops, the packet in progress gets one or two words of zeros and its end (an even
-- number of words; it is not a correct packet, and the words of its last data bin can have wrong shifts), the
-- timestamp counts that set of frames, and the readout of the new set starts 24 clocks later.
-- Change tx_exponents, exp_block and exp_field4 only while the transmitter is in reset (tx_reset).
-- A packet can have 31 words of 32 bytes of exponents at most with EXPONENT_BITS = 2 (62 bins with one exponent for
-- 2 frames), and 63 with EXPONENT_BITS = 3 (63 bins with one exponent for 2 frames and exponents of 4 bits); the
-- word of zeros that makes the number even is not counted. With tx_override_data the mode is off.
-- With tx_exponents = '0' the packets are those of an entity with EXPONENT_BITS = 0, 7 clocks later.
-- With EXPONENT_BITS = 0 the entity is as it was.

entity upack is
	generic (
		SIM : boolean := false;
		EXPONENT_BITS : integer := 0 -- 0: no exponents. 2 or 3: bits of the exponent of each input sample (exponent mode)
	);
	port (
		s_axis_in_tdata  : in std_logic_vector(255 downto 0) := (others => '0'); -- First byte to transmit is in in most significant byte
		-- Exponent bits of each sample of s_axis_in_tdata (EXPONENT_BITS > 0): sample n is in tdata(8n + 7 downto 8n) and has the
		-- EXPONENT_BITS + 1 bits texp((EXPONENT_BITS + 1) * n + EXPONENT_BITS downto (EXPONENT_BITS + 1) * n). The MSB tells that the
		-- bin of the sample has an exponent in its scaler; the other bits are the exponent (0 if the MSB is 0).
		-- 1 bit for each sample if EXPONENT_BITS = 0 (not used).
		s_axis_in_texp   : in std_logic_vector(32 * sel(EXPONENT_BITS > 0, EXPONENT_BITS + 1, 1) - 1 downto 0) := (others => '0');
		s_axis_in_tvalid : in std_logic                      := '0';
		s_axis_in_tlast  : in std_logic                      := '0';

		m_axis_out_tdata  : out std_logic_vector(255 downto 0);
		m_axis_out_tvalid : out std_logic := '0';
		m_axis_out_tlast  : out std_logic := '0';

		clk : in std_logic;
		rst : in std_logic; -- synchrounous reset


		debug_out : out slv32;

		-- init_clk: in std_logic; -- continuous clock

		-- Control and reply streams
		s_axis_bsb_tdata  : in std_logic_vector(7 downto 0) := (others => '0');
		s_axis_bsb_tvalid : in std_logic                    := '0';
		s_axis_bsb_tlast  : in std_logic                    := '0';
		s_axis_bsb_tready : out std_logic;
		m_axis_bsb_tdata  : out std_logic_vector(7 downto 0);
		m_axis_bsb_tvalid : out std_logic;
		m_axis_bsb_tlast  : out std_logic;
		m_axis_bsb_tready : in std_logic                    := '0';
		bsb_clk           : in std_logic                    := '0'; -- control clock
		bsb_rst           : in std_logic                    := '0'

	-- areset: in std_logic -- asynchronous reset
	);
end entity upack;

architecture impl of upack is

	signal control_bytes: slv8_array(0 to 7);
	signal status_bytes: slv8_array(0 to sel(EXPONENT_BITS > 0, 3, 2));

	signal cmd_dat_int_tdata: std_logic_vector(7 downto 0);
	signal cmd_dat_int_tvalid: std_logic;
	signal cmd_dat_int_tlast: std_logic;
	signal cmd_rdy_int_tready: std_logic;
	signal rply_dat_int_tdata: std_logic_vector(7 downto 0);
	signal rply_dat_int_tvalid: std_logic;
	signal rply_dat_int_tlast: std_logic;
	signal rply_rdy_int_tready: std_logic;
	signal ctrl_rst_int: std_logic;

	signal ram_wr_addr, ram_rd_addr: std_logic_vector(13 downto 0);
	signal ram_din: std_logic_vector(255 downto 0);
	signal ram_dout: slv256_array(3 downto 0); -- one for each column;
	signal ram_wr_row_en: std_logic_vector(3 downto 0);  -- one for each row
	signal ram_wr_byte_en: std_logic_vector(31 downto 0);  -- enable for each of the 32 bytes across the row
	signal ram_rd_col_en: std_logic_vector(3 downto 0);  -- one for each column
	signal wr_bank: std_logic; -- 2 banks
	signal overrun: std_logic;

	signal bsb_ram_din: std_logic_vector(7 downto 0);
	signal bsb_ram_addr: std_logic_vector(15 downto 0);
	signal bsb_ram_we, bsb_ram_en: std_logic;
	signal bsb_ram_bank: std_logic;
	signal bsb_ram_frame: std_logic_vector(3 downto 0);

	signal rx_write_enable: std_logic;
	signal rx_mask_low_bins: std_logic;
	signal tx_trig_sel: std_logic;
	signal tx_period: unsigned(31 downto 0);
	signal tx_length: unsigned(7 downto 0);
	signal tx_enable: std_logic;
	signal tx_reset: std_logic;
	-- signal play_ram_wr_en: std_logic;
	-- signal play_ram_wr_byte_en: std_logic_vector(0 downto 0);
	signal play_ram_rd_addr: unsigned(12 downto 0);
	signal play_ram_rd_en: std_logic;
	signal play_ram_dout: std_logic_vector(15 downto 0);
	signal bsb_ram_sel: std_logic;
	signal mask_ram_sel: std_logic;
	signal in_frame_ctr: unsigned(7 downto 0);
	signal out_frame_ctr: unsigned(7 downto 0);
	signal tx_override_data: std_logic;
	signal tx_toggle_bank: std_logic;
	signal tx_insert_timestamp: std_logic;
	signal timestamp_incr: unsigned(4 downto 0);

	-- Exponent mode
	constant EXP: boolean := EXPONENT_BITS > 0;
	constant UW: integer := sel(EXP, 72, 64); -- bits of an UltraRAM word that are in use
	constant EB: integer := sel(EXP, EXPONENT_BITS, 2); -- bits of the exponent of a sample
	constant EF: integer := EB + 1; -- bits of a sample in s_axis_in_texp: the bit that tells that its bin has an exponent, and the exponent
	constant EW: integer := 8 * EB; -- exponent bits of a bin of a frame (8 inputs, input 0 in the MSBs): 16 or 24
	constant XW: integer := EW - 8; -- of these, the LSBs that are in the UltraRAMs of the exponents (the 8 MSBs are in byte 8 of the data words): 8 or 16
	constant X_U: integer := XW / 4; -- UltraRAMs of the exponents for each frame row: 2 or 4
	constant FIELD4: boolean := EXPONENT_BITS = 3; -- the build can send exponents of 4 bits
	constant XF_AW: integer := sel(FIELD4, 6, 5); -- bits of the address of the FIFO of the exponent words of a packet (31 or 63 words at most)
	signal exp_field4: std_logic; -- '1': exponents of 4 bits in the packets (FIELD4). '0': exponents of 2 bits
	signal exp_field_over: std_logic := '0'; -- an exponent above 3 was sent as 3 (exponents of 2 bits in the packets). Stays until tx_reset
	signal tx_exponents: std_logic; -- '1': one exponent for each group of B frames, and the exponents at the end of the packets
	signal exp_block: unsigned(1 downto 0); -- log2(B) - 1: 0 to 3 for one exponent for 2, 4, 8, 16 frames
	-- Stream that is written in the buffer
	signal wr_tdata: std_logic_vector(255 downto 0);
	signal wr_tvalid, wr_tlast: std_logic;
	signal wr_texp: std_logic_vector(4 * EW - 1 downto 0) := (others => '0'); -- EW exponent bits for each bin (column) of the word: input 0 in the MSBs
	signal ram_dsp_in: std_logic_vector(31 downto 0) := (others => '0'); -- byte 8 of the UltraRAM word of each column (write): the 8 MSBs of the exponents of the bin
	signal ram_wr_sp_en: std_logic_vector(3 downto 0) := (others => '0'); -- its write enable
	signal ram_dsp_out: slv_array(3 downto 0)(31 downto 0) := (others => (others => '0')); -- byte 8 of the 4 rows, for each column (read)
	-- UltraRAMs with the other exponent bits: the XW bits c of a word are the bin of column c
	signal x_din: std_logic_vector(4 * XW - 1 downto 0) := (others => '0');
	signal x_we: std_logic_vector(3 downto 0) := (others => '0'); -- for each column
	signal x_row_en: std_logic_vector(3 downto 0) := (others => '0');
	signal x_waddr: std_logic_vector(13 downto 0) := (others => '0'); -- bank, frame(3 downto 2), word: as the data
	signal x_dout: slv_array(3 downto 0)(4 * XW - 1 downto 0) := (others => (others => '0')); -- for each row, 5 clocks after the address
	-- Bins with exponents: one bit for each bin and bank, '1' = in the last frame that was written, one input or more
	-- had the bit that tells that the bin has an exponent
	signal wr_bin_exp: std_logic_vector(3 downto 0) := (others => '0'); -- for each column of the word that is written: OR of these bits of the 8 inputs
	signal bin_exp_din: std_logic_vector(3 downto 0) := (others => '0');
	signal bin_exp_we: std_logic := '0';
	signal bin_exp_waddr: std_logic_vector(11 downto 0) := (others => '0'); -- bank, word
	signal bin_exp_raddr: std_logic_vector(13 downto 0) := (others => '0'); -- bank, bin
	signal bin_exp_dout: std_logic := '0'; -- '1': the bin has exponents
	-- Check of the headers that the host wrote: the 48 bits that tell which bins of the packet have exponents
	signal exponent_bins_mismatch: std_logic := '0'; -- in a packet, the bins that got exponents were not the bins that its header gives. Stays until tx_reset
	signal exponent_bins_mismatch_count: unsigned(7 downto 0) := (others => '0'); -- number of these packets (stops at 255)

begin
	assert EXPONENT_BITS = 0 or EXPONENT_BITS = 2 or EXPONENT_BITS = 3 report "upack: EXPONENT_BITS must be 0, 2 or 3" severity FAILURE;

	-- Implement an an asynchronous FIFO to bridge the BSB bus from the BSB
	-- to the clk domains (RAM accesses must be made in the clk domain)
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

			rst       => bsb_rst, -- reset is asynchronous and will be extended until a few clocks have happened on both clocks
			b_rst_out => ctrl_rst_int  -- ctrl_reset, resynchronized to the B_CLK
		);

	-- Memory Map
	-- ------------------------------------------------------------------------------
	-- |  Page   | Addr|Bit(s)|     Name             | Description                   |
	-- |---------|-----|------|----------------------|-------------------------------|
	-- | CONTROL |  0  |  7   | exp_field4           | '1': exponents of 4 bits in the packets (32 bits for the 8 inputs of a group of frames). '0': exponents of 2 bits (16 bits). EXPONENT_BITS = 3 only |
	-- |         |     |  6   | (not used)           | (was bsb_exp_table: the packetizer has no table of bins any more; the scalers tell which bins have an exponent) |
	-- |         |     |  5   | bsb_ram_sel          | Write data target: 0=data buffer, 1=playlist/mask buffer |
	-- |         |     |  4   | bsb_ram_bank          | If bsb_ram_sel=0, selects rd/wr bank; if bsb_ram_sel=1, selects playlist memory (0) or mask memory (1) |
	-- |         |     | 3:0  | bsb_ram_frame         | Frame number |
	-- |         |  1  |  7   | rx_write_enable       | When '1', incoming data is written to the data buffer |
	-- |         |     |  6   | tx_trig_sel           | 0: Data transmission starts when an incoming frame set is completed; 1: data transmission starts every TX_PERIOD clocks |
	-- |         |     |  5   | tx_enable             | '1' to enable data transmission. '0' data transmission is muted |
	-- |         |     |  4   | tx_reset              | '1' resets the data transmitter |
	-- |         |     |  3   | tx_toggle_bank         | '1' allows the read and write banks to alternate |
	-- |         |     |  2   | tx_insert_timestamp    | Insert timestamp in output |
	-- |         |     |  1   | rx_mask_low_bins      | Mask low bins |
	-- |         |     |  0   | tx_override_data       | Override data |
	-- |         | 2-5 | 31:0 | tx_period              | Number of clocks between data transmission starts (32 bits) |
	-- |         |  6  | 7:0  | tx_length              | Transmission length |
	-- |         |  7  | 4:0  | timestamp_incr        | Timestamp increment value |
	-- |         |     | 6:5  | exp_block             | log2(B) - 1: 0, 1, 2, 3 = one exponent for each group of 2, 4, 8, 16 frames (EXPONENT_BITS > 0) |
	-- |         |     |  7   | tx_exponents          | '1': the bins with exponents are sent with one exponent for each group of B frames, and the exponents follow the last data bin of each packet (EXPONENT_BITS > 0) |
	-- | STATUS  |  0  |  0   | overrun               | Overrun flag |
	-- |         |     |  1   | exp_field_over        | '1': an exponent above 3 was sent as 3 (EXPONENT_BITS = 3, exp_field4 = '0'). Cleared by tx_reset |
	-- |         |     |  2   | exponent_bins_mismatch | '1': in a packet, the bins that got exponents were not the bins that the header of the packet gives (bytes 16 to 21 of the payload header, which the host writes: bit k = 1 if data bin k of the packet has exponents). Cleared by tx_reset (EXPONENT_BITS > 0) |
	-- |         |     |  3   | exponent_bins_from_scalers | '1': the scalers tell which bins have an exponent (the packetizer has no table of bins), the exponents of a packet are filled with zeros to 64 bytes, and exponent_bins_mismatch and status byte 3 are there (EXPONENT_BITS > 0) |
	-- |         |     | 5:4  | EXPONENT_BITS         | Value of the generic. 0: the build has no exponent mode |
	-- |         |     |  6   | exponent_v2           | '1': the exponent mode has exp_block and the exponents at the end of the packet |
	-- |         |     |  7   | exp_field4_support    | '1': the build has exp_field4 (EXPONENT_BITS = 3) |
	-- |         |  1  | 7:0  | in_frame_ctr           | Input frame counter |
	-- |         |  2  | 7:0  | out_frame_ctr          | Output frame counter |
	-- |         |  3  | 7:0  | exponent_bins_mismatch_count | Packets with exponent_bins_mismatch since tx_reset (stops at 255). The byte is only there with EXPONENT_BITS > 0 |
	-- | RAM     | 0-65535 | - | Data/Playlist/Mask RAM | RAM for data buffer, playlist, or mask depending on bsb_ram_sel and bsb_ram_bank |
	-- ------------------------------------------------------------------------------

	bsb_regs0: entity work.bsb_regs
		generic map (
			DEFAULT_CONTROL_BYTES   => X"00_66_00010000_FF_10",
			USE_RAM_DOUT_RDY        => FALSE, -- need to wait for the RDY signal on RAM read accesses
			RAM_DATA_WIDTH          => 8,
			RAM_ADDR_WIDTH          => 16, -- 16 bits : 64k page, 8k bins x 8 channels
			NUMBER_OF_CONTROL_BYTES => control_bytes'Length(1), -- Number of bits in the control word
			NUMBER_OF_STATUS_BYTES  => status_bytes'Length(1) -- Number of bits in the status word.
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
			status_bytes  => status_bytes,

			-- RAM interface
			ram_din  => bsb_ram_din,
			ram_dout => (others => '0'),
			-- RAM_DOUT_RDY => bsb_ram_rdy,
			ram_wr_en => bsb_ram_we,
			ram_en    => bsb_ram_en,
			ram_addr  => bsb_ram_addr

		-- -- System
		-- RST => areset
		);


	-- CONTROL byte 0

	bsb_ram_sel   <= control_bytes(0)(5); -- write data target:  0: data buffer, 1: playlist/mask buffer
	bsb_ram_bank  <= control_bytes(0)(4); -- if bsb_ram_sel=0, selects rd/wr bank; if bsb_ram_sel=1, selects playlist memory (0) or mask memory (1)
	bsb_ram_frame <= control_bytes(0)(3 downto 0);

	-- CONTROL byte 1
	rx_write_enable      <= control_bytes(1)(7); -- When '1', incoming data is written to the data buffer, otherwise incoming data is not written.
	tx_trig_sel          <= control_bytes(1)(6); -- 0: Data transmission starts when an incoming frame set is completed; 1: data transmission starts every `TX_PERIOD` clocks.
	tx_enable            <= control_bytes(1)(5); -- '1' to enable data transmission. '0' data transmission is muted.
	tx_reset             <= control_bytes(1)(4); -- '1' resets the data transmitter
	tx_toggle_bank       <= control_bytes(1)(3); -- '1' allows the read and write banks to alternate. Normally '0' for generating test patterns, and '1' for live data.
	tx_insert_timestamp  <= control_bytes(1)(2);
	rx_mask_low_bins     <= control_bytes(1)(1);
	tx_override_data     <= control_bytes(1)(0);
	-- CONTROL byte 2-5
	tx_period <= to_unsigned(control_bytes(2 to 5));

	-- CONTROL byte 6
	tx_length <= unsigned(control_bytes(6));


	timestamp_incr <= unsigned(control_bytes(7)(4 downto 0));
	tx_exponents <= (control_bytes(7)(7) and not tx_override_data) when EXP else '0'; -- not with the test pattern of tx_override_data
	exp_block <= unsigned(control_bytes(7)(6 downto 5));
	exp_field4 <= control_bytes(0)(7) when FIELD4 else '0';

	-- STATUS byte 0
	status_bytes(0)(0) <= overrun;
	status_bytes(0)(5 downto 4) <= std_logic_vector(to_unsigned(EXPONENT_BITS, 2));
	status_bytes(0)(6) <= to_std_logic(EXP);
	status_bytes(0)(1) <= exp_field_over;
	status_bytes(0)(7) <= to_std_logic(FIELD4);
	status_bytes(0)(2) <= exponent_bins_mismatch;
	status_bytes(0)(3) <= to_std_logic(EXP);
	st3_gen: if EXP generate
		status_bytes(3) <= std_logic_vector(exponent_bins_mismatch_count);
	end generate st3_gen;

	-- STATUS byte 1
	status_bytes(1) <= std_logic_vector(in_frame_ctr);
	-- STATUS byte 2
	status_bytes(2) <= std_logic_vector(out_frame_ctr);

	uram_row_gen: for row in 3 downto 0 generate

		uram_col_gen: for col in 3 downto 0 generate
			signal ram_dout_word: std_logic_vector(UW - 1 downto 0);
			signal ram_din_word: std_logic_vector(UW - 1 downto 0);
			signal ram_wr_byte_en_word: std_logic_vector(UW / 8 - 1 downto 0);
		begin
			ram_dout(col)(64 * row + 63 downto 64 * row) <= ram_dout_word(63 downto 0);
			ram_din_word(63 downto 0)                    <= ram_din(64 * col + 63 downto 64 * col);
			ram_wr_byte_en_word(7 downto 0)              <= ram_wr_byte_en(8 * col + 7 downto 8 * col);
			-- Exponent mode: byte 8 of the word has the exponents of inputs 0 to 3 of the bin (see the write process)
			sp_gen: if EXP generate
				ram_din_word(71 downto 64) <= ram_dsp_in(8 * col + 7 downto 8 * col);
				ram_wr_byte_en_word(8) <= ram_wr_sp_en(col);
				ram_dsp_out(col)(8 * row + 7 downto 8 * row) <= ram_dout_word(71 downto 64);
			end generate sp_gen;
			-- xpm_memory_sdpram: Simple Dual Port RAM
			-- Xilinx Parameterized Macro, version 2022.1
			-- UltraRAM primitive is organized as 4K x 72 bits
			-- Addr width: we use all the memory space. The uram is 2kx
			uram_cell_inst: xpm_memory_sdpram
				generic map (
					MEMORY_PRIMITIVE => "ultra",     -- force the use of UltraRAM
					-- write bus A
					ADDR_WIDTH_A       => 14,        -- 4k (12 bits) per URAM, +2 because we cascade 4 of them.
					WRITE_DATA_WIDTH_A => UW,        -- 8 byte (64 bits) wide write bus (9 bytes in the exponent mode)
					BYTE_WRITE_WIDTH_A => 8,         -- We use 8-bit-wide-byte-enabled write, i.e. we have 8 byte enable bits
					-- Read bus B
					ADDR_WIDTH_B      => 14,         -- same
					READ_DATA_WIDTH_B => UW,         -- 8 byte (64 bits) wide read bus
					-- CASCADE_HEIGHT => 4,          -- We castade 4 URAM
					-- MEMORY_OPTIMIZATION => "true",-- String
					MEMORY_SIZE => UW * 4096 * 4,    -- 64-bit word * 4096 words/URAM * 4 URAMs
					-- MESSAGE_CONTROL => 0,         -- DECIMAL
					READ_LATENCY_B => 5,             -- Needs to be >= of cascade height to allow registering. Synthesis ask for more than 4 to have full pipelining (4 is partial).
					-- READ_RESET_VALUE_B => "0",    -- String
					-- RST_MODE_A => "SYNC",         -- String
					-- RST_MODE_B => "SYNC",         -- String
					SIM_ASSERT_CHK => 1,             -- DECIMAL; 0=disable simulation messages, 1=enable simulation messages
					-- USE_EMBEDDED_CONSTRAINT => 0, -- DECIMAL
					-- USE_MEM_INIT => 1,            -- DECIMAL
					-- USE_MEM_INIT_MMI => 0,        -- DECIMAL
					-- WAKEUP_TIME => "disable_sleep",-- String
					WRITE_MODE_B  => "write_first",  -- URAM is either read_first or write_first
					WRITE_PROTECT => 1               -- DECIMAL
				)
				port map (
					-- Write port
					dina  => ram_din_word,
					addra => ram_wr_addr,
					ena   => ram_wr_row_en(row),
					wea   => ram_wr_byte_en_word,

					-- read port
					doutb => ram_dout_word,
					addrb => ram_rd_addr,
					enb   => ram_rd_col_en(col),

					-- clock and reset
					clka => clk,
					rstb => rst,

					-- unused signals
					sleep          => '0',
					injectsbiterra => '0',
					injectdbiterra => '0',
					regceb         => '1',
					clkb           => '0'
				);

		end generate uram_col_gen;

	end generate uram_row_gen;


	-- Stream that is written in the buffer
	no_exp_gen: if not EXP generate
		wr_tdata <= s_axis_in_tdata;
		wr_tvalid <= s_axis_in_tvalid;
		wr_tlast <= s_axis_in_tlast;
	end generate no_exp_gen;

	exp_gen: if EXP generate
	begin
		-- The frames are written as with EXPONENT_BITS = 0 (also the frame in progress at the end of a reset), so that a
		-- packet with a timestamp has the same frames as a packet of that entity.
		wr_tdata <= s_axis_in_tdata;
		wr_tvalid <= s_axis_in_tvalid;
		wr_tlast <= s_axis_in_tlast;
		-- The exponent of each sample, and for each bin (column) of the word: one input or more tells that the bin has an exponent
		process(all)
			variable m: std_logic;
		begin
			for n in 0 to 31 loop
				wr_texp(EB * n + EB - 1 downto EB * n) <= s_axis_in_texp(EF * n + EB - 1 downto EF * n);
			end loop;
			for c in 0 to 3 loop
				m := '0';
				for j in 0 to 7 loop
					m := m or s_axis_in_texp(EF * (8 * c + j) + EB);
				end loop;
				wr_bin_exp(c) <= m;
			end loop;
		end process;

		-- The exponent bits that are not in byte 8 of the data words (XW bits for each bin of a frame), in UltraRAMs with
		-- no cascade. The read address has its own register (these UltraRAMs are not next to those of the data), the
		-- read has 3 clocks, then comes the selection: 5 clocks, as the data.
		--   EXPONENT_BITS = 2 (8 bits for a bin): 2 UltraRAMs for each frame row, one for each bank. Address: frame(3),
		--     word. A word has frame(2) = 0 in its bits 31:0 and frame(2) = 1 in its bits 63:32; byte c of these 32 bits
		--     is the bin of column c.
		--   EXPONENT_BITS = 3 (16 bits for a bin): 4 UltraRAMs for each frame row, one for each bank and frame(2)
		--     (UltraRAM 2 x bank + frame(2)). Address: frame(3), word. The 16 bits c of a word are the bin of column c.
		x_blk: block
			type sel_array is array (1 to 4) of std_logic_vector(1 downto 0);
			signal rd_sel: sel_array := (others => "00"); -- bank and frame(2) of the read address, 1 to 4 clocks before
			signal x_raddr: std_logic_vector(11 downto 0) := (others => '0'); -- read address, one clock after ram_rd_addr
		begin
			x_row_gen: for row in 0 to 3 generate
				signal ud: slv_array(0 to X_U - 1)(63 downto 0);
			begin
				x_u_gen: for u in 0 to X_U - 1 generate
					signal wea: std_logic_vector(7 downto 0);
					signal ena: std_logic;
					signal din: std_logic_vector(63 downto 0);
				begin
					w8_gen: if XW = 8 generate
						wea_gen: for c in 0 to 3 generate
							wea(c) <= x_we(c) and not x_waddr(11);
							wea(4 + c) <= x_we(c) and x_waddr(11);
						end generate wea_gen;
						ena <= x_row_en(row) and to_std_logic(x_waddr(13) = to_std_logic(u = 1));
						din <= x_din & x_din;
					else generate
						wea16_gen: for c in 0 to 3 generate
							wea(2 * c) <= x_we(c);
							wea(2 * c + 1) <= x_we(c);
						end generate wea16_gen;
						ena <= x_row_en(row) and to_std_logic(x_waddr(13) = to_std_logic(u >= 2) and x_waddr(11) = to_std_logic(u mod 2 = 1));
						din <= x_din;
					end generate w8_gen;
					x_ram0: xpm_memory_sdpram
						generic map (
							MEMORY_PRIMITIVE   => "ultra",
							CLOCKING_MODE      => "common_clock",
							ADDR_WIDTH_A       => 12,
							WRITE_DATA_WIDTH_A => 64,
							BYTE_WRITE_WIDTH_A => 8,
							ADDR_WIDTH_B       => 12,
							READ_DATA_WIDTH_B  => 64,
							MEMORY_SIZE        => 64 * 4096,
							READ_LATENCY_B     => 3,
							SIM_ASSERT_CHK     => 1,
							WRITE_MODE_B       => "read_first",
							WRITE_PROTECT      => 1
						)
						port map (
							dina  => din,
							addra => x_waddr(12) & x_waddr(10 downto 0),
							ena   => ena,
							wea   => wea,
							doutb => ud(u),
							addrb => x_raddr,
							enb   => '1',
							clka  => clk,
							rstb  => '0',
							sleep => '0', injectsbiterra => '0', injectdbiterra => '0', regceb => '1', clkb => '0'
						);
				end generate x_u_gen;

				r8_gen: if XW = 8 generate
					process(clk)
					begin
						if rising_edge(clk) then
							case rd_sel(4) is
								when "00" => x_dout(row) <= ud(0)(31 downto 0);
								when "01" => x_dout(row) <= ud(0)(63 downto 32);
								when "10" => x_dout(row) <= ud(1)(31 downto 0);
								when others => x_dout(row) <= ud(1)(63 downto 32);
							end case;
						end if;
					end process;
				else generate
					process(clk)
					begin
						if rising_edge(clk) then
							x_dout(row) <= ud(to_integer(unsigned(rd_sel(4))));
						end if;
					end process;
				end generate r8_gen;
			end generate x_row_gen;

			process(clk)
			begin
				if rising_edge(clk) then
					rd_sel <= (ram_rd_addr(13) & ram_rd_addr(11)) & rd_sel(1 to 3);
					x_raddr <= ram_rd_addr(12) & ram_rd_addr(10 downto 0);
				end if;
			end process;
		end block x_blk;

		-- Bins with exponents: one bit for each bin and bank. The write side writes, with each word of each frame, for its
		-- 4 bins, if one input or more tells that the bin has an exponent: after the last of the 16 frames the memory has
		-- the bits of that frame. The read side reads the bit of a bin with the bank that it reads. A word of 4 bits has
		-- the bin of column 3 - k in its bit k, so the read address is the bank and the bin number.
		bin_exp_ram0: xpm_memory_sdpram
			generic map (
				MEMORY_PRIMITIVE   => "block",
				CLOCKING_MODE      => "common_clock",
				ADDR_WIDTH_A       => 12,
				WRITE_DATA_WIDTH_A => 4,
				BYTE_WRITE_WIDTH_A => 4,
				ADDR_WIDTH_B       => 14,
				READ_DATA_WIDTH_B  => 1,
				MEMORY_SIZE        => 16384,
				READ_LATENCY_B     => 1,
				SIM_ASSERT_CHK     => 1,
				WRITE_MODE_B       => "read_first",
				WRITE_PROTECT      => 1
			)
			port map (
				dina     => bin_exp_din,
				addra    => bin_exp_waddr,
				ena      => bin_exp_we,
				wea      => "1",
				doutb(0) => bin_exp_dout,
				addrb    => bin_exp_raddr,
				enb      => '1',
				clka     => clk,
				rstb     => '0',
				sleep => '0', injectsbiterra => '0', injectdbiterra => '0', regceb => '1', clkb => '0'
			);
	end generate exp_gen;

	-- Write the incoming data to the 4x4 UltraRAM cell array.
	--
	-- Bins form one frame are written in all cells in one row.
	-- Consecutive frames are written in consecutive rows.
	-- Consecutive sets of 16 frames are stored in alternate banks.
	-- One row stores two banks of 4 frames.
	ram_wr_block: block is
		signal word_ctr: unsigned(10 downto 0); -- 8k/4 = 2k bins -- we recive and count 4 bins at a time
		signal frame_ctr: unsigned(3 downto 0); -- 16 frames per bank
		signal mask_ram_dout_pre: std_logic_vector(3 downto 0);
		--    signal bin_frame_ctr: unsigned(14 downto 0); -- 8k bins/4 * 16 frames

		signal ram_wr_addr_pre: std_logic_vector(13 downto 0);
		signal ram_din_pre: std_logic_vector(255 downto 0);
		signal ram_wr_row_en_pre: std_logic_vector(3 downto 0);  -- one for each row
		signal ram_wr_bsb_byte_en_pre: std_logic_vector(31 downto 0);  -- enable for each of the 32 bytes across the row
		signal use_mask_byte_en_pre: std_logic;
		signal ram_dsp_pre: std_logic_vector(31 downto 0); -- exponent mode: byte 8 of the UltraRAM words
		signal x_din_pre: std_logic_vector(4 * XW - 1 downto 0); -- exponent mode: the exponent bits that go in the UltraRAMs of the exponents
	begin


		-- Write mask RAM
		mask_ram0: xpm_memory_sdpram
			generic map (
				MEMORY_PRIMITIVE => "block",        -- force the use of block ram
				CLOCKING_MODE    => "common_clock", -- BSB is FIFO'ed in the data clock domain
				-- write bus A
				ADDR_WIDTH_A       => 10,           -- 8k bins/ 8 bits/byte (10 bits), 1024 bytes
				WRITE_DATA_WIDTH_A => 8,            -- 8 byte (64 bits) wide write bus
				BYTE_WRITE_WIDTH_A => 8,            -- We use 8-bit-wide-byte-enabled write, i.e. we have 8 byte enable bits
				-- Read bus B
				ADDR_WIDTH_B      => 11,            -- 8K bits/4 bits = 2K,
				READ_DATA_WIDTH_B => 4,             -- 4 bits per word, 1 bit per bin
				MEMORY_SIZE       => 8192,          -- Number of bins in the mask RAM
				READ_LATENCY_B    => 1,             -- Need the data immediately.
				SIM_ASSERT_CHK    => 1,             -- DECIMAL; 0=disable simulation messages, 1=enable simulation messages
				WRITE_MODE_B      => "read_first",  -- has to be read_first for assymetrical data ports, otherwise raises error on synthesis
				WRITE_PROTECT     => 1              -- DECIMAL
			)
			port map (
				-- Write port
				dina  => bsb_ram_din,
				addra => bsb_ram_addr(9 downto 0),
				ena   => bsb_ram_en and bsb_ram_sel and bsb_ram_bank,
				wea   => (0 => bsb_ram_we),

				-- read port
				doutb(3 downto 0) => mask_ram_dout_pre, -- Byte written at low address on din appears in LSB in dout
				addrb             => std_logic_vector(word_ctr),
				enb               => '1',

				-- clock and reset
				clka => clk,
				rstb => rst,

				-- unused signals
				sleep          => '0',
				injectsbiterra => '0',
				injectdbiterra => '0',
				regceb         => '1',
				clkb           => '0'
			);

		ram_wr_proc: process(all)

			variable row, byte: integer;
			variable bank: std_logic;                     -- 2 banks
			variable frame: std_logic_vector(3 downto 0); -- 16 frames
			variable bin: std_logic_vector(10 downto 0);  -- 8k/4 = 2k bins
			variable wr_en: std_logic;
			variable rcol: integer;

		begin
			if rising_edge(clk) then
				wr_en := '0'; -- overriden below
				bin := std_logic_vector(word_ctr);
				frame := std_logic_vector(frame_ctr);
				bank := wr_bank;

				-- Always set byte enables and din by default to make sure we don't infer unnecessary enables
				use_mask_byte_en_pre <= '1';
				ram_din_pre <= wr_tdata;
				if wr_tvalid then
					word_ctr <= word_ctr + 1; -- Each word contains 4 bins
					-- Write data unless we rx_mask_low_bins=1 and we are receiving bins 0-127
					-- if not(rx_mask_low_bins = '1' and word_ctr(10 downto 5) = 0) then  -- 128 bins / (4 bins/count) = 32 counts = last 5 bits
					wr_en := rx_write_enable;
					--          end if;
					if wr_tlast then
						in_frame_ctr <= in_frame_ctr + 1; -- counts frames for debugging only
						word_ctr <= (others => '0');
						frame_ctr <= frame_ctr + 1;
						if unsigned(frame) = 15 then
							wr_bank <= not wr_bank;
						end if;
					end if;
				end if;

				-- Exponent mode: the EW exponent bits of each bin of the word (EB bits for each input, input 0 in the MSBs).
				-- The 8 MSBs go in byte 8 of the UltraRAM word of the bin, the others in the UltraRAMs of the exponents.
				-- For the 4 bins: the bit that tells that the bin has exponents, in its memory, for the bank and the word of the stream.
				if EXP then
					bin_exp_we <= wr_tvalid and rx_write_enable;
					bin_exp_waddr <= wr_bank & std_logic_vector(word_ctr);
					for k in 0 to 3 loop
						bin_exp_din(k) <= wr_bin_exp(3 - k);
					end loop;
					for col in 0 to 3 loop
						ram_dsp_pre(8 * col + 7 downto 8 * col) <= wr_texp(EW * col + EW - 1 downto EW * col + XW);
						x_din_pre(XW * col + XW - 1 downto XW * col) <= wr_texp(EW * col + XW - 1 downto EW * col);
					end loop;
				end if;

				--  Write from BSB overrides incoming stream write
				if bsb_ram_en and bsb_ram_we and not bsb_ram_sel then
					byte := to_integer(unsigned(not bsb_ram_addr(4 downto 0))); -- 8 channels * 4 cols = 32 bytes, addr 0 = byte 31
					bin := bsb_ram_addr(15 downto 5);
					frame := bsb_ram_frame;
					bank := bsb_ram_bank;

					wr_en := '1';
					ram_wr_bsb_byte_en_pre <= (others => '0');
					ram_wr_bsb_byte_en_pre(byte) <= '1';
					use_mask_byte_en_pre <= '0';
					for i in 0 to 31 loop
						ram_din_pre(8 * i + 7 downto 8 * i) <= bsb_ram_din;
					end loop;

				end if;

				-- generate address and row enable
				ram_wr_addr_pre <= bank & frame(3 downto 2) & bin; -- 1 + 2 + 11 = 14 bits, 16 kwords = 128 kB/cell = 4x32 kB
				row := to_integer(unsigned(not frame(1 downto 0)));
				ram_wr_row_en_pre <= (others => '0'); -- overriden below
				ram_wr_row_en_pre(row) <= wr_en;

				-- On this clock, the address, data and row enables are ready in pre, as well as the BSB byte enable and mask RAM 4-bit output.
				-- We pipeline those to ease routing, and also compute the final byte mask patten.
				ram_din <= ram_din_pre;
				ram_wr_row_en <= ram_wr_row_en_pre;
				ram_wr_addr <= ram_wr_addr_pre;
				-- Assign the byte enable from either the BSB write logic or the MASK RAM
				if use_mask_byte_en_pre then
					for col in 0 to 3 loop
						rcol := 3 - col;
						ram_wr_byte_en(8 * col + 7 downto 8 * col) <= (others => mask_ram_dout_pre(rcol)); -- Select which bin is written. Mask bit 0 selects bin in the MSB, i.e. the first to be transmitted.
					end loop;

				else
					ram_wr_byte_en <= ram_wr_bsb_byte_en_pre;
				end if; -- use_mask_byte_en
				-- Exponent mode: byte 8 is written with the data of the stream, and not by the BSB
				if EXP then
					ram_dsp_in <= ram_dsp_pre;
					x_din <= x_din_pre;
					x_row_en <= ram_wr_row_en_pre;
					x_waddr <= ram_wr_addr_pre;
					for col in 0 to 3 loop
						ram_wr_sp_en(col) <= mask_ram_dout_pre(3 - col) and use_mask_byte_en_pre;
						x_we(col) <= mask_ram_dout_pre(3 - col) and use_mask_byte_en_pre;
					end loop;
				end if;

				if rst then
					-- bin_frame_ctr <= (others => '0');
					frame_ctr <= (others => '0');
					word_ctr <= (others => '0');
					wr_bank <= '0';
					in_frame_ctr <= (others => '0');
					bin_exp_we <= '0';
				end if; -- rst
			end if; -- clk
		end process ram_wr_proc;

	end block ram_wr_block;

	play_ram0: xpm_memory_sdpram
		generic map (
			MEMORY_PRIMITIVE => "auto",         -- force the use of UltraRAM
			CLOCKING_MODE    => "common_clock", -- BSB is FIFO'ed in the data clk domain
			-- write bus A
			ADDR_WIDTH_A       => 14,           -- 4k (12 bits) per URAM, +2 because we cascade 4 of them.
			WRITE_DATA_WIDTH_A => 8,            -- 8 byte (64 bits) wide write bus
			BYTE_WRITE_WIDTH_A => 8,            -- We use 8-bit-wide-byte-enabled write, i.e. we have 8 byte enable bits
			-- Read bus B
			ADDR_WIDTH_B      => 13,            -- same
			READ_DATA_WIDTH_B => 16,            -- 8 byte (64 bits) wide read bus
			MEMORY_SIZE       => 16 * 8192,     -- 64-bit word * 4096 words/URAM * 4 URAMs
			CASCADE_HEIGHT    => sel(EXP, 1, 0), -- exponent mode: 4 block RAMs with no cascade (the cascade that the tools make is the slowest path of the packetizer). 0: the tools select, as before
			READ_LATENCY_B    => 1,             -- Needs to be >= of cascade height to allow registering.
			SIM_ASSERT_CHK    => 1,             -- DECIMAL; 0=disable simulation messages, 1=enable simulation messages
			WRITE_MODE_B      => "read_first",  -- has to be read_first for assymetrical data ports, otherwise raises error on synthesis
			WRITE_PROTECT     => 1              -- DECIMAL
		)
		port map (
			-- Write port
			dina  => bsb_ram_din,
			addra => bsb_ram_addr(13 downto 0),
			ena   => bsb_ram_en and bsb_ram_sel and not bsb_ram_bank,
			wea   => (0 => bsb_ram_we),

			-- read port
			doutb(7 downto 0)  => play_ram_dout(15 downto 8), -- Byte written at low address on din appears in LSB in dout
			doutb(15 downto 8) => play_ram_dout(7 downto 0),
			addrb              => std_logic_vector(play_ram_rd_addr),
			enb                => play_ram_rd_en,

			-- clock and reset
			clka => clk, -- Clocks ports A and B in common clock mode
			rstb => rst,

			-- unused signals
			sleep          => '0',
			injectsbiterra => '0',
			injectdbiterra => '0',
			regceb         => '1',
			clkb           => '0' -- not used in common clock mode
		);

	-- Reads data from 4x4 UltraRAM cell array in the specified order.
	--
	-- Bins from one frame are written in all cells in one row.
	-- Consecutive frames are written in consecutive rows.
	-- Consecutive sets of 16 frames are stored in alternate banks.
	-- One row stores two banks of 4 frames.
	ram_rd_block: block
		-- signal bin_ctr: unsigned(12 downto 0); -- 8k bins
		signal framegroup_ctr: unsigned(1 downto 0); -- 16/4 = 4 frames (we read frames 4 at a time)
		signal wr_bank_reg, rd_bank: std_logic; -- 2 banks
		signal rd_bank_l: std_logic := '0'; -- exponent mode: the bank of the readout in progress (it does not change when the write side changes its bank)
		signal rd_bank_use: std_logic; -- the bank that the read addresses have
		signal busy: std_logic;
		signal tvalid, tlast: std_logic_vector(5 downto 0);
		signal col: slv_array(5 downto 0)(1 downto 0);
		signal insert_ts: std_logic_vector(5 downto 0);
		signal eot: std_logic_vector(5 downto 0);
		signal tdata_reg: std_logic_vector(255 downto 0);
		signal tvalid_reg, tlast_reg: std_logic;
		signal play_ram_rd_rdy: std_logic;
		signal word_ctr: unsigned(31 downto 0);
		signal timestamp: unsigned(63 downto 0);
		signal first_bin: std_logic;

		-- Exponent mode: the sequence of the words
		signal exp_left: unsigned(XF_AW downto 0) := (others => '0'); -- exponent words that are still to send (with the word of zeros that makes their number even)
		-- Pause after each packet with tx_exponents: the packets then do not come faster than the 100G link can send them
		signal pause_left: unsigned(4 downto 0) := (others => '0'); -- clocks of the pause that are left
		signal pkt_words: unsigned(9 downto 0) := (others => '0'); -- words of the packet that were sent before this clock
		-- Readout that is not complete when the next set of 16 frames is complete: it is stopped
		constant STOP_CLOCKS: integer := 24; -- clocks from the stop of the readout to the start of the next one: all its words are then out
		signal stop_cnt: unsigned(4 downto 0) := (others => '0');
		signal out_open: std_logic := '0'; -- at the output: a packet has started and its last word did not come
		signal out_odd: std_logic := '0'; -- that packet has an odd number of words until now
		-- Check of the 48 bits of the header that tell which bins of the packet have exponents
		signal hdr_word2: std_logic_vector(5 downto 0) := (others => '0'); -- the word is the second word of the header of a packet (as tvalid)
		signal hdr_word2_d: std_logic := '0';
		signal hdr_bins: std_logic_vector(47 downto 0) := (others => '0'); -- these 48 bits (bytes 16 to 21 of the payload header, little endian: bit k = data bin k of the packet)
		signal sent_bins, sent_bins_cmp: std_logic_vector(47 downto 0) := (others => '0'); -- bit k = 1: data bin k of the packet got exponents
		signal data_bin_nr: unsigned(5 downto 0) := (others => '0'); -- number of the data bin in the packet (0 for the first one)
		signal cmp_delay: std_logic_vector(1 to 4) := (others => '0'); -- the last data bin of a packet was read 1 to 4 clocks before
		signal n_words: unsigned(XF_AW - 1 downto 0) := (others => '0'); -- exponent words of the packet, for its bins with exponents until now
		signal chunk_mod: unsigned(3 downto 0) := (others => '0'); -- bins with exponents in the last of these words
		signal bmask: unsigned(3 downto 0); -- bins in an exponent word, minus 1 (B - 1 with exponents of 2 bits, B / 2 - 1 with exponents of 4 bits)
		constant ZERO_WORD: std_logic_vector(2 * EW - 1 downto 0) := (others => '0');
		signal lu: unsigned(2 downto 0); -- log2 of the number of 16-bit units that a bin has in the exponent words: 0 to 4
		signal pend_eot: std_logic := '0'; -- the end of the transmission comes with the last exponent word
		signal pl_reg, pl_reg2: std_logic_vector(15 downto 13) := "000"; -- bits 15:13 of the playlist entry, 1 and 2 clocks later
		signal fgp: slv_array(5 downto 0)(1 downto 0) := (others => "00"); -- group of 4 frames of the word
		signal xv: std_logic_vector(5 downto 0) := (others => '0'); -- the word is an exponent word
		signal hx: std_logic_vector(3 downto 0) := (others => '0'); -- the word is a word of a data bin with exponents (as tvalid(3 downto 0))
		-- Exponent mode: the words after the UltraRAMs
		signal e_reg: std_logic_vector(4 * EW - 1 downto 0) := (others => '0'); -- exponents of the samples of tdata_reg: frame f of the word in the EW bits 3 - f (frame 0 in the MSBs), input 0 in the MSBs of these
		signal s_hx, s_g3, s_xv: std_logic := '0'; -- with tdata_reg: bin with exponents, its last word, exponent word
		signal sh_m2: std_logic_vector(8 * EW - 1 downto 0) := (others => '0'); -- largest exponents of the pairs of frames of the last 4 words (the first word in the MSBs)
		signal sh_m4: std_logic_vector(4 * EW - 1 downto 0) := (others => '0'); -- the same for the 4 frames of each word
		signal a_lat, b_lat, c_valid: std_logic := '0';
		signal b_m2: std_logic_vector(8 * EW - 1 downto 0) := (others => '0');
		signal b_m4: std_logic_vector(4 * EW - 1 downto 0) := (others => '0');
		signal b_m8: std_logic_vector(2 * EW - 1 downto 0) := (others => '0');
		signal e_sr: std_logic_vector(8 * EW - 1 downto 0) := (others => '0'); -- exponents of the groups of the two pairs of frames of each word of the bin; the word at the stage d1 in the MSBs
		signal c_chunk: std_logic_vector(8 * EW - 1 downto 0) := (others => '0'); -- the exponents of the groups of frames of the bin (EW bits for each group, the first one in the MSBs, zeros after the last one)
		signal dl_tdata: slv_array(1 to 6)(255 downto 0);
		signal dl_e: slv_array(1 to 6)(4 * EW - 1 downto 0);
		signal dl_valid, dl_last, dl_hx, dl_xv: std_logic_vector(1 to 6) := (others => '0');
		signal d1_tdata: std_logic_vector(255 downto 0);
		signal d1_d: std_logic_vector(32 * EB - 1 downto 0) := (others => '0'); -- for each sample (8 x frame + input, EB bits): exponent of the group - sample exponent
		signal d1_valid, d1_last, d1_xv: std_logic := '0';
		-- Exponent words of the packet
		signal acc: std_logic_vector(255 downto 0) := (others => '0'); -- the word in progress
		signal acc_cnt: unsigned(3 downto 0) := (others => '0'); -- bins in it
		signal acc_full: std_logic := '0';
		type fifo_t is array (0 to 2 ** XF_AW - 1) of std_logic_vector(255 downto 0);
		signal fifo_mem: fifo_t; -- complete words that wait for the end of the packet (48 bins: 24 words at most with exponents of 2 bits, 48 with exponents of 4 bits)
		attribute ram_style: string;
		attribute ram_style of fifo_mem: signal is "distributed";
		signal wr_ptr, rd_ptr: unsigned(XF_AW - 1 downto 0) := (others => '0');
		signal xword_reg: std_logic_vector(255 downto 0);

		-- Larger exponents of two groups (8 exponents of EB bits)
		function fmax(a, b: std_logic_vector(EW - 1 downto 0)) return std_logic_vector is
			variable r: std_logic_vector(EW - 1 downto 0);
		begin
			for i in 0 to 7 loop
				if unsigned(a(EB * i + EB - 1 downto EB * i)) > unsigned(b(EB * i + EB - 1 downto EB * i)) then
					r(EB * i + EB - 1 downto EB * i) := a(EB * i + EB - 1 downto EB * i);
				else
					r(EB * i + EB - 1 downto EB * i) := b(EB * i + EB - 1 downto EB * i);
				end if;
			end loop;
			return r;
		end function;

		-- m / 2^d, rounded to the nearest integer, a tie to the even integer. With d of 4 or more the result is 0
		-- (the part is from -8 to 7: -8 / 16 is a tie between -1 and 0).
		function rdiv(m: std_logic_vector(3 downto 0); d: std_logic_vector(EB - 1 downto 0)) return std_logic_vector is
			variable q: signed(3 downto 0);
			variable inc: std_logic;
		begin
			case to_integer(unsigned(d)) is
				when 0 => q := signed(m); inc := '0';
				when 1 => q := resize(signed(m(3 downto 1)), 4); inc := m(0) and m(1);
				when 2 => q := resize(signed(m(3 downto 2)), 4); inc := m(1) and (m(0) or m(2));
				when 3 => q := resize(signed(m(3 downto 3)), 4); inc := m(2) and (m(1) or m(0) or m(3));
				when others => q := "0000"; inc := '0';
			end case;
			if inc = '1' then
				q := q + 1;
			end if;
			return std_logic_vector(q);
		end function;
	begin
		rd_bank        <= (not wr_bank) and tx_toggle_bank;
		-- Exponent mode: a readout keeps its bank to its end. If it is not complete when the write side changes its bank,
		-- its last word is then still a word of its set of 16 frames (with rd_bank, that word is from the other bank).
		rd_bank_use    <= rd_bank_l when EXP else rd_bank;
		play_ram_rd_en <= busy;
		-- A bin with exponents has 16 / B numbers of 16 bits, or of 32 bits with exp_field4: 2^lu units of 16 bits, and
		-- an exponent word has the numbers of 16 / 2^lu bins
		lu <= to_unsigned(4, 3) - exp_block when exp_field4 = '1' else to_unsigned(3, 3) - exp_block;
		with lu select bmask <= "1111" when "000", "0111" when "001", "0011" when "010", "0001" when "011", "0000" when others;


		debug_out(0)          <= busy;
		debug_out(1)          <= play_ram_rd_rdy;
		debug_out(3 downto 2) <= std_logic_vector(framegroup_ctr);
		debug_out(4)          <= rd_bank;
		debug_out(5)          <= play_ram_rd_en;
		debug_out(15 downto 8)  <= std_logic_vector(play_ram_rd_addr(7 downto 0));
		debug_out(31 downto 16) <= play_ram_dout;


		ram_rd_proc: process(all)

			-- variable frame: std_logic_vector(1 downto 0);
			variable bin: std_logic_vector(12 downto 0);
			variable col_var: std_logic_vector(1 downto 0);
			variable col_int: integer;

			variable last_framegroup: unsigned(1 downto 0);
			variable end_of_packet: std_logic;
			variable end_of_transmission: std_logic;
			variable exp_follow: std_logic;
			variable m2: slv_array(0 to 1)(EW - 1 downto 0);
			variable m16, grp: std_logic_vector(EW - 1 downto 0);
			variable ef, ch: std_logic_vector(8 * EW - 1 downto 0);
			variable ecur, es, dd: unsigned(EB - 1 downto 0);
			variable ev: std_logic_vector(EB - 1 downto 0);
			variable cw: std_logic_vector(255 downto 0); -- the exponent numbers of the bin as they are sent, the first one in the MSBs
			variable over: std_logic;
			variable hi, src: integer;
			variable hit: boolean;

		begin
			if rising_edge(clk) then
				-- Generate read address and enable signals
				bin := play_ram_dout(12 downto 0);
				-- Number of framegroups to read. 0=2 framegroups (64 bytes), 1=4 framegroups (128 bytes)
				last_framegroup := "11" when play_ram_dout(13) else "01";
				end_of_packet := play_ram_dout(14);
				end_of_transmission := play_ram_dout(15);
				-- Exponent mode: exponent words follow the last data bin of the packet
				exp_follow := tx_exponents when EXP and n_words /= 0 else '0';

				ram_rd_addr <= rd_bank_use & std_logic_vector(framegroup_ctr) & bin(12 downto 2);
				col_var := not bin(1 downto 0);  -- first column in col 3
				col_int := to_integer(unsigned(col_var));
				ram_rd_col_en <= (others => '0'); -- one bit overriden below
				ram_rd_col_en(col_int) <= '1'; -- set read_en only when we are actually using the data to make simulations more clear

				-- Delay various signals to compensate for the URAM 5-clock latency

				tvalid <= shift_right(tvalid, 1); -- shift in a '0', overriden below
				tlast <= shift_right(tlast, 1); -- shift in a '0', overriden below
				insert_ts <= shift_right(insert_ts, 1); -- shift in a '0', overriden below
				eot <= shift_right(eot, 1); -- shift in a '0', overriden below
				col <= shift_right(col, 1); -- shift in overriden below
				col(col'LEFT) <= col_var;

				word_ctr <= word_ctr + 1;
				play_ram_rd_rdy <= play_ram_rd_en; -- 1 clk latency on playlist RAM
				if EXP then
					xv <= shift_right(xv, 1);
					fgp <= shift_right(fgp, 1);
					fgp(fgp'LEFT) <= std_logic_vector(framegroup_ctr);
					-- Registers of the playlist entry: the logic of the exponents uses them, and not the output of the playlist
					-- RAM, which is on the critical path. For an entry that is at the output of the playlist RAM from the clock
					-- t (its first group of 4 frames): pl_reg has it from t + 1 to t + 4; pl_reg2 and the output of the memory
					-- of the bins with exponents have it from t + 2 to t + 5. The word of group g is at tvalid(4) at t + g + 2.
					pl_reg <= play_ram_dout(15 downto 13);
					pl_reg2 <= pl_reg;
					bin_exp_raddr <= rd_bank_l & play_ram_dout(12 downto 0);
					hx <= '0' & hx(3 downto 1);
					hx(3) <= tvalid(4) and not xv(4) and pl_reg2(13) and bin_exp_dout and tx_exponents;
					hdr_word2 <= '0' & hdr_word2(5 downto 1);
					cmp_delay <= '0' & cmp_delay(1 to 3);
					-- The pause after a packet: the playlist waits
					if pause_left /= 0 then
						pause_left <= pause_left - 1;
						if pause_left /= 1 then
							play_ram_rd_rdy <= '0';
						end if;
					end if;
					if exp_left /= 0 then
						-- An exponent word. The playlist waits (play_ram_rd_rdy = '0'): its output stays on the next entry.
						tvalid(tvalid'LEFT) <= '1';
						xv(xv'LEFT) <= '1';
						exp_left <= exp_left - 1;
						pkt_words <= pkt_words + 1;
						play_ram_rd_rdy <= '0';
						if exp_left = 1 then -- the last word of the packet, then the pause
							tlast(tlast'LEFT) <= '1';
							eot(eot'LEFT) <= pend_eot;
							pause_left <= pkt_words(9 downto 5) + 1;
							pkt_words <= (others => '0');
						end if;
					end if;
				end if;
				if play_ram_rd_rdy then
					framegroup_ctr <= framegroup_ctr + 1;
					tvalid(tvalid'LEFT) <= '1';
					if EXP then
						pkt_words <= pkt_words + 1;
						if first_bin = '1' and framegroup_ctr = 1 then -- the second word of the header: it has the 48 bits of the bins with exponents
							hdr_word2(hdr_word2'LEFT) <= '1';
						end if;
					end if;
					-- Send a signal to insert the timestamp on the second frame downstream in the pipeline
					if tx_insert_timestamp = '1' and first_bin = '1' and framegroup_ctr = 1 then
						insert_ts(insert_ts'LEFT) <= '1';
					end if;
					-- Setup the next read one frame before the last because of the RAM latency
					-- We have to do this because the output of the RAM is feeds back into the RAM address (via last_framegroup)
					if framegroup_ctr = last_framegroup - 1 then
						play_ram_rd_addr <= play_ram_rd_addr + 1;
						if end_of_transmission then
							busy <= '0'; -- we're done
						end if;
					end if;
					-- if the last frame of a bin
					if framegroup_ctr = last_framegroup then
						framegroup_ctr <= (others => '0');
						first_bin <= '0';
						-- Exponent mode: if the packet has bins with exponents, the exponent words come after its last data
						-- bin, and the last one is the end of the packet and of the transmission
						if end_of_packet then -- 8k bins / 128 NUMA =64 bins/packets, 16 frames*8 bytes/bin/frame * 64 bins/packets = 8kB packet
							tlast(tlast'LEFT) <= not exp_follow;
							first_bin <= '1';
						end if;
						if end_of_transmission then
							eot(eot'LEFT) <= not exp_follow; -- signal end of transmission down the pipeline
						end if;
					end if; -- if last frame
					-- Exponent mode, a data bin. At its third group of 4 frames, the memory of the bins with exponents gives its bit:
					-- count the exponent words of the packet (a word has the exponents of B bins) and note the number of the bin in
					-- the packet. At its last group, if it is the last bin of the packet: the exponent words start (an even number
					-- of words: one word of zeros is added if necessary, because the path to the 100G MAC needs packets with an
					-- even number of 32-byte words), or the pause after the packet.
					if EXP and tx_exponents = '1' and pl_reg(13) = '1' then
						if framegroup_ctr = 2 and bin_exp_dout = '1' then
							if chunk_mod = 0 then
								n_words <= n_words + 1;
							end if;
							if chunk_mod = bmask then
								chunk_mod <= (others => '0');
							else
								chunk_mod <= chunk_mod + 1;
							end if;
							if data_bin_nr < 48 then
								sent_bins(to_integer(data_bin_nr)) <= '1';
							end if;
						end if;
						if framegroup_ctr = 3 then
							if data_bin_nr /= 63 then
								data_bin_nr <= data_bin_nr + 1;
							end if;
							if pl_reg(14) = '1' then
								n_words <= (others => '0');
								chunk_mod <= (others => '0');
								data_bin_nr <= (others => '0');
								sent_bins <= (others => '0');
								sent_bins_cmp <= sent_bins;
								cmp_delay(1) <= '1';
								play_ram_rd_rdy <= '0';
								if n_words /= 0 then
									exp_left <= resize(n_words, XF_AW + 1) + ("" & n_words(0));
									pend_eot <= pl_reg(15);
								else
									pause_left <= pkt_words(9 downto 5) + 1;
									pkt_words <= (others => '0');
								end if;
							end if;
						end if;
					end if;

				-- Force end of transmission based on tx_len. This is a protection to protect against never-ending packets or transmissions.
				-- Should never be reached if playlist is programmed properly.
				-- if word_ctr = tx_length  then
				--  busy <= '0'; -- we're done
				--  tlast(tlast'LEFT) <= '1'; -- force tlast on that word
				--  first_bin <= '1';
				-- end if;
				end if;


				-- capture URAM output when it comes out
				tdata_reg <= ram_dout(to_integer(unsigned(col(col'RIGHT))));
				-- insert the timestamp when it's time (2nd frame of 1st bin of a packet)
				if insert_ts(insert_ts'RIGHT) = '1' then
					tdata_reg(8 * 6 + 63 downto 8 * 6) <= reverse_bytes(std_logic_vector(timestamp));
				end if;
				-- override output in test mode
				if tx_override_data then
					tdata_reg <= X"000102030405060708090A0B0C0D0E0F_101112131415161718191A1B1C1D1E1F";
				end if;

				tvalid_reg <= tvalid(tvalid'RIGHT) and tx_enable;
				tlast_reg <= tlast(tvalid'RIGHT);

				-- keep track of output frames for debugging
				out_frame_ctr <= out_frame_ctr + 1 when tvalid_reg and tlast_reg;

				-- increment timestamp
				if eot(eot'RIGHT) = '1' then
					timestamp <= timestamp + timestamp_incr;
				end if;

				if not EXP then
					---- pipeline final output
					m_axis_out_tdata <= tdata_reg;
					m_axis_out_tvalid <= tvalid_reg;
					m_axis_out_tlast <= tlast_reg;
				else
					-- Exponent mode. The 4 words of a data bin come one after the other (c, c + 1, c + 2, c + 3 at tdata_reg).
					-- With tdata_reg: the exponents of the 32 samples of the word (byte 8 of the data UltraRAM words and
					-- the UltraRAMs of the exponents).
					col_int := to_integer(unsigned(col(col'RIGHT)));
					for row in 0 to 3 loop
						e_reg(EW * row + EW - 1 downto EW * row) <= ram_dsp_out(col_int)(8 * row + 7 downto 8 * row) & x_dout(row)(XW * col_int + XW - 1 downto XW * col_int);
					end loop;
					s_hx <= hx(0);
					s_g3 <= hx(0) and to_std_logic(fgp(fgp'RIGHT) = "11");
					s_xv <= xv(xv'RIGHT);

					-- Stage A: the largest exponents of the two pairs of frames of the word and of its 4 frames, for each
					-- input. After the last word of the bin (c + 4) the 4 words are in the shift registers.
					if s_hx = '1' then
						m2(0) := fmax(e_reg(4 * EW - 1 downto 3 * EW), e_reg(3 * EW - 1 downto 2 * EW));
						m2(1) := fmax(e_reg(2 * EW - 1 downto EW), e_reg(EW - 1 downto 0));
						sh_m2 <= sh_m2(6 * EW - 1 downto 0) & m2(0) & m2(1);
						sh_m4 <= sh_m4(3 * EW - 1 downto 0) & fmax(m2(0), m2(1));
					end if;
					a_lat <= s_g3;

					-- Stage B (c + 5): the largest exponents of 8 frames
					b_m2 <= sh_m2;
					b_m4 <= sh_m4;
					b_m8 <= fmax(sh_m4(4 * EW - 1 downto 3 * EW), sh_m4(3 * EW - 1 downto 2 * EW)) & fmax(sh_m4(2 * EW - 1 downto EW), sh_m4(EW - 1 downto 0));
					b_lat <= a_lat;

					-- Stage C (c + 6): the exponent of the group of each pair of frames of each word (e_sr), and the exponents of the groups of the bin
					m16 := fmax(b_m8(2 * EW - 1 downto EW), b_m8(EW - 1 downto 0));
					ch := (others => '0');
					case exp_block is
						when "00" => -- one exponent for 2 frames
							ef := b_m2;
							ch := b_m2;
						when "01" => -- one exponent for 4 frames
							for g in 0 to 3 loop
								grp := b_m4(4 * EW - 1 - EW * g downto 3 * EW - EW * g);
								ef(8 * EW - 1 - 2 * EW * g downto 6 * EW - 2 * EW * g) := grp & grp;
							end loop;
							ch(8 * EW - 1 downto 4 * EW) := b_m4;
						when "10" => -- one exponent for 8 frames
							for g in 0 to 3 loop
								grp := b_m8(2 * EW - 1 - EW * (g / 2) downto EW - EW * (g / 2));
								ef(8 * EW - 1 - 2 * EW * g downto 6 * EW - 2 * EW * g) := grp & grp;
							end loop;
							ch(8 * EW - 1 downto 6 * EW) := b_m8;
						when others => -- one exponent for 16 frames
							for g in 0 to 7 loop
								ef(8 * EW - 1 - EW * g downto 7 * EW - EW * g) := m16;
							end loop;
							ch(8 * EW - 1 downto 7 * EW) := m16;
					end case;
					c_valid <= b_lat;
					if b_lat = '1' then
						e_sr <= ef;
						c_chunk <= ch;
					else
						e_sr <= e_sr(6 * EW - 1 downto 0) & ZERO_WORD; -- the next word of the bin
					end if;

					-- The words wait 6 clocks: word g of the bin is at dl(6) at c + g + 6, with the exponents of its groups in the MSBs of e_sr
					dl_tdata(1) <= tdata_reg;
					dl_e(1) <= e_reg;
					dl_valid(1) <= tvalid_reg;
					dl_last(1) <= tlast_reg;
					dl_hx(1) <= s_hx;
					dl_xv(1) <= s_xv;
					for k in 2 to 6 loop
						dl_tdata(k) <= dl_tdata(k - 1);
						dl_e(k) <= dl_e(k - 1);
						dl_valid(k) <= dl_valid(k - 1);
						dl_last(k) <= dl_last(k - 1);
						dl_hx(k) <= dl_hx(k - 1);
						dl_xv(k) <= dl_xv(k - 1);
					end loop;

					-- Stage d1: for each sample, the exponent of its group minus its own exponent
					d1_tdata <= dl_tdata(6);
					d1_valid <= dl_valid(6);
					d1_last <= dl_last(6);
					d1_xv <= dl_xv(6);
					for f in 0 to 3 loop
						for i in 0 to 7 loop
							ecur := unsigned(e_sr(8 * EW - 1 - EW * (f / 2) - EB * i downto 8 * EW - EW * (f / 2) - EB * i - EB));
							es := unsigned(dl_e(6)(4 * EW - 1 - EW * f - EB * i downto 4 * EW - EW * f - EB * i - EB));
							dd := (others => '0');
							if dl_hx(6) = '1' then
								dd := ecur - es;
							end if;
							d1_d(EB * (8 * f + i) + EB - 1 downto EB * (8 * f + i)) <= std_logic_vector(dd);
						end loop;
					end loop;

					-- Output: the two parts of each sample divided by 2^(difference), or an exponent word
					for f in 0 to 3 loop
						for i in 0 to 7 loop
							hi := 255 - 64 * f - 8 * i;
							m_axis_out_tdata(hi downto hi - 3) <= rdiv(d1_tdata(hi downto hi - 3), d1_d(EB * (8 * f + i) + EB - 1 downto EB * (8 * f + i)));
							m_axis_out_tdata(hi - 4 downto hi - 7) <= rdiv(d1_tdata(hi - 4 downto hi - 7), d1_d(EB * (8 * f + i) + EB - 1 downto EB * (8 * f + i)));
						end loop;
					end loop;
					if d1_xv = '1' then
						m_axis_out_tdata <= xword_reg;
					end if;
					m_axis_out_tvalid <= d1_valid;
					m_axis_out_tlast <= d1_last;
					if d1_valid = '1' then
						out_open <= not d1_last;
						out_odd <= not d1_last and not out_odd;
					end if;

					-- The 48 bits of the header (the last 6 bytes of its second word) against the bins that got exponents
					hdr_word2_d <= hdr_word2(0);
					if hdr_word2_d = '1' then
						hdr_bins <= reverse_bytes(tdata_reg(47 downto 0));
					end if;
					if cmp_delay(4) = '1' and sent_bins_cmp /= hdr_bins then
						exponent_bins_mismatch <= '1';
						if exponent_bins_mismatch_count /= 255 then
							exponent_bins_mismatch_count <= exponent_bins_mismatch_count + 1;
						end if;
					end if;

					-- The exponent words of the packet. The exponent numbers of a bin (from c_chunk, at c + 7) go in the word in progress:
					-- a word has the numbers of 16 / 2^lu bins, the first bin in the MSBs. A complete word goes in the FIFO.
					-- The first exponent word of the packet is at dl(4) at c + 8 or later: the word in progress, if it has
					-- numbers, goes in the FIFO then (the bits that are not written are 0). An exponent word is read from
					-- the FIFO when it is at dl(6).
					-- The numbers as they are sent: 16 bits for a group of frames (2 bits for each input; an exponent above 3 is sent
					-- as 3, with the flag exp_field_over), or 32 bits with exp_field4 (4 bits for each input).
					cw := (others => '0');
					over := '0';
					for k in 0 to 7 loop
						grp := c_chunk(8 * EW - 1 - EW * k downto 7 * EW - EW * k);
						for i in 0 to 7 loop
							ev := grp(EW - 1 - EB * i downto EW - EB * i - EB);
							if exp_field4 = '1' then
								cw(255 - 32 * k - 4 * i downto 252 - 32 * k - 4 * i) := std_logic_vector(resize(unsigned(ev), 4));
							elsif EB = 3 then
								cw(255 - 16 * k - 2 * i downto 254 - 16 * k - 2 * i) := (ev(EB - 1) or ev(1)) & (ev(EB - 1) or ev(0));
								over := over or ev(EB - 1);
							else
								cw(255 - 16 * k - 2 * i downto 254 - 16 * k - 2 * i) := ev(1 downto 0);
							end if;
						end loop;
					end loop;
					if c_valid = '1' then
						for j in 0 to 15 loop
							case lu is
								when "000" => hit := j = to_integer(acc_cnt); src := 0;
								when "001" => hit := j / 2 = to_integer(acc_cnt); src := j mod 2;
								when "010" => hit := j / 4 = to_integer(acc_cnt); src := j mod 4;
								when "011" => hit := j / 8 = to_integer(acc_cnt); src := j mod 8;
								when others => hit := TRUE; src := j; -- one bin in a word
							end case;
							if hit then
								acc(255 - 16 * j downto 240 - 16 * j) <= cw(255 - 16 * src downto 240 - 16 * src);
							end if;
						end loop;
						if acc_cnt = bmask then
							acc_full <= '1';
							acc_cnt <= (others => '0');
						else
							acc_cnt <= acc_cnt + 1;
						end if;
						if over = '1' then
							exp_field_over <= '1';
						end if;
					end if;
					if acc_full = '1' or (dl_xv(4) = '1' and acc_cnt /= 0) then
						fifo_mem(to_integer(wr_ptr)) <= acc;
						wr_ptr <= wr_ptr + 1;
						acc <= (others => '0');
						acc_full <= '0';
						acc_cnt <= (others => '0');
					end if;
					if dl_xv(6) = '1' then
						if rd_ptr /= wr_ptr then
							xword_reg <= fifo_mem(to_integer(rd_ptr));
							rd_ptr <= rd_ptr + 1;
						else -- the word of zeros that makes the number of exponent words even
							xword_reg <= (others => '0');
						end if;
					end if;
				end if;

				-- start a new readout and set the busy flag when the bank changes (tx_trig_sel=0) or when the specified period has elapsed (tx_trig_sel=1)
				wr_bank_reg <= wr_bank;
				if (tx_trig_sel = '0' and wr_bank /= wr_bank_reg) or (tx_trig_sel = '1' and word_ctr = tx_period) then
					if not EXP then
						if busy = '1' then
							overrun <= '1';
						end if;
						busy <= '1';
						framegroup_ctr <= (others => '0');
						-- bin_ctr <= (others => '0');
						word_ctr <= (others => '0');
						play_ram_rd_addr <= (others => '0');
					elsif busy = '1' or exp_left /= 0 or stop_cnt /= 0 then
						-- Exponent mode: the readout is not complete. It stops here; its words that are on their way go out, the
						-- packet in progress gets an end, the timestamp counts the set of 16 frames of that readout, and the new
						-- readout starts STOP_CLOCKS later (see below).
						overrun <= '1';
						word_ctr <= (others => '0');
						if stop_cnt = 0 then
							busy <= '0';
							exp_left <= (others => '0');
							pause_left <= (others => '0');
							play_ram_rd_rdy <= '0';
							stop_cnt <= to_unsigned(STOP_CLOCKS, stop_cnt'length);
						end if;
					else
						busy <= '1';
						rd_bank_l <= rd_bank;
						framegroup_ctr <= (others => '0');
						word_ctr <= (others => '0');
						play_ram_rd_addr <= (others => '0');
						exp_left <= (others => '0');
						pause_left <= (others => '0');
						n_words <= (others => '0');
						chunk_mod <= (others => '0');
						pkt_words <= (others => '0');
						data_bin_nr <= (others => '0');
						sent_bins <= (others => '0');
						first_bin <= '1';
					end if;
				end if;

				-- Exponent mode, after a readout that was not complete: at the output, the packet in progress gets one or two
				-- words of zeros, the last one with tlast, so that it ends and has an even number of words (it is not a correct
				-- packet: its length is not that of its header). Then the state of the exponent words is cleared and the new
				-- readout starts.
				if EXP and stop_cnt /= 0 then
					stop_cnt <= stop_cnt - 1;
					play_ram_rd_rdy <= '0';
					if (stop_cnt = 6 and out_open = '1' and out_odd = '0') or (stop_cnt = 5 and out_open = '1') then
						m_axis_out_tdata <= (others => '0');
						m_axis_out_tvalid <= '1';
						m_axis_out_tlast <= to_std_logic(stop_cnt = 5);
						out_open <= to_std_logic(stop_cnt /= 5);
						out_odd <= to_std_logic(stop_cnt /= 5);
					end if;
					if stop_cnt = 4 then
						timestamp <= timestamp + timestamp_incr; -- (here, and not at the start: the header of the packet in progress can be on its way)
						n_words <= (others => '0');
						chunk_mod <= (others => '0');
						acc <= (others => '0');
						acc_cnt <= (others => '0');
						acc_full <= '0';
						wr_ptr <= (others => '0');
						rd_ptr <= (others => '0');
						data_bin_nr <= (others => '0');
						sent_bins <= (others => '0');
						cmp_delay <= (others => '0');
						pkt_words <= (others => '0');
						pause_left <= (others => '0');
					end if;
					if stop_cnt = 1 then
						busy <= '1';
						rd_bank_l <= rd_bank;
						framegroup_ctr <= (others => '0');
						play_ram_rd_addr <= (others => '0');
						first_bin <= '1';
					end if;
				end if;

				if rst or tx_reset then
					framegroup_ctr <= (others => '0');
					-- bin_ctr <= (others => '0');
					busy <= '0';
					overrun <= '0';
					-- tvalid_pre <= '0';
					tvalid <= (others => '0');
					tvalid_reg <= '0';
					m_axis_out_tvalid <= '0';
					play_ram_rd_rdy <= '0';
					play_ram_rd_addr <= (others => '0');
					-- Exponent mode: no readout starts at the end of tx_reset (with '0' here, a readout starts in the middle
					-- of a set of 16 frames when the write side is in its bank 1, and the next set then finds it not complete)
					wr_bank_reg <= wr_bank when EXP else '0';
					out_frame_ctr <= (others => '0');
					word_ctr <= (others => '0');
					first_bin <= '1';
					timestamp <= (others => '0');
					exp_left <= (others => '0');
					n_words <= (others => '0');
					chunk_mod <= (others => '0');
					xv <= (others => '0');
					hx <= (others => '0');
					s_hx <= '0';
					s_g3 <= '0';
					s_xv <= '0';
					a_lat <= '0';
					b_lat <= '0';
					c_valid <= '0';
					dl_valid <= (others => '0');
					dl_hx <= (others => '0');
					dl_xv <= (others => '0');
					d1_valid <= '0';
					d1_xv <= '0';
					acc <= (others => '0');
					acc_cnt <= (others => '0');
					acc_full <= '0';
					wr_ptr <= (others => '0');
					rd_ptr <= (others => '0');
					exp_field_over <= '0';
					pause_left <= (others => '0');
					pkt_words <= (others => '0');
					stop_cnt <= (others => '0');
					out_open <= '0';
					out_odd <= '0';
					hdr_word2 <= (others => '0');
					hdr_word2_d <= '0';
					sent_bins <= (others => '0');
					data_bin_nr <= (others => '0');
					cmp_delay <= (others => '0');
					pend_eot <= '0';
					exponent_bins_mismatch <= '0';
					exponent_bins_mismatch_count <= (others => '0');
				end if; -- rst
			end if; -- clk
		end process ram_rd_proc;

	end block ram_rd_block;


end architecture impl;





