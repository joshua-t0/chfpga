----------------------------------------------------------------------------------
-- Design Name: chFPGA
-- Module Name: UCMAC88_ARRAY
-- Target Devices: Ultrascale+
-- Tool versions: Vivado 2022.2 +
-- Description: Array of UltraRAM-based (8+8)-bit complex multipliers/accumulators with wide accumulators
-----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.chFPGA_Package.ALL;

library UNISIM;
use UNISIM.VComponents.ALL;

library xpm;
use xpm.vcomponents.ALL;

-- UCMAC88_ARRAY: the (8+8)-bit version of UCMAC44_ARRAY
--
-- NCMAC complex multipliers-and-accumulators for inputs with 8-bit components (-128 to 127). The products are exact:
-- there is no scaling and no rounding. For each clock with s_axis_xy_tvalid = 1, CMAC i computes X * conj(Y)
-- (conj(X) * Y if its s_axis_xy_swap bit is 1) and adds it to the sum of the current word of the frame (the bin).
--
-- The control logic, the two memory banks, the readout of one bin for each frame and the daisy chain of the
-- result bytes are those of UCMAC44_ARRAY: see that module. The differences:
--
-- - Each input word has 32 bits: X_re, X_im, Y_re, Y_im from MSB to LSB, 8 bits each.
-- - A cross-product is accumulated in CROSS_BITS + CROSS_BITS bits (default 24 + 24), an autocorrelation (the first
--   CMAC of each group of AUTOCORR_STRIDE, but not in the last group) as an unsigned number of AUTO_BITS bits
--   (default 30).
-- - The accumulators of all the CMACs are packed in RAM words of 72 bits with no unused bits between them:
--   36 CMACs with 8 autocorrelations of 30 bits and 28 cross-products of 48 bits fill 22 RAM words exactly.
--   The first URAM_MAX words are UltraRAMs, the others are block RAMs.
-- - A result record has the 10-byte header, then 6 bytes for each product (with CROSS_BITS = 22). See below.
--
-- Each CMAC has two DSP48E2, for x = a + jb and y = c + jd:
--
-- - dsp1: (a * 2^18 + b) * c = ac * 2^18 + bc          (pre-adder, multiplier)
-- - dsp2: (b * 2^18 - a) * d + dsp1 + sum from the RAM
--   Without the sum this is V = (ac + bd) * 2^18 + (bc - ad): one signed number with the imaginary part of the
--   product in its 18 LSBs and the real part above. dsp2 accumulates V as one number.
--
-- With swap, the pre-adders compute a * 2^18 - b and b * 2^18 + a: the imaginary part has the opposite sign.
--
-- The sum of a cross-product in the RAM has three fields (CROSS_BITS = 24):
--
-- - IM_LOW (18 bits): the 18 LSBs of the sum of V. They are the 18 LSBs of the sum of the imaginary parts.
-- - IM_HIGH (6 bits, signed): the bits above of the sum of the imaginary parts. This is a counter: +1 when IM_LOW
--   passes 2^18 upward, -1 when it passes 0 downward (the imaginary part of one product is less than 2^16, so the
--   two MSBs of IM_LOW before and after the addition tell). IM_HIGH & IM_LOW is the sum of the imaginary parts
--   as a signed 24-bit number.
-- - RE (24 bits, signed): bits 41:18 of the sum of V. This is the sum of the real parts plus IM_HIGH (the carries
--   and borrows of IM_LOW go in it). So: sum of the real parts = RE - IM_HIGH. The readout computes this.
--
-- Saturation: RE stays at its largest or smallest value when the sum passes it (also a sum that is exactly at a
-- limit is taken as saturated). IM_HIGH stays at its largest value (31) or smallest value (-32) when it gets there.
-- When IM_HIGH is at a limit, the real part is not valid (the carries are no longer counted).
--
-- An autocorrelation is a number that is not negative: its sum is in bits 18 and above of the DSP, and it stays
-- at 2^AUTO_BITS - 1 when it passes that value.
--
-- Result record: the 10-byte header, then for each product a little-endian word of 2 * CROSS_BITS + 2 bits in whole
-- bytes (6 bytes for 22 bits). The readout computes the sum of the real parts (RE - IM_HIGH), so the record has the two
-- parts as plain signed numbers of CROSS_BITS bits, and two saturation flags above them. See product_bytes.
entity UCMAC88_ARRAY is
	generic (
		NCMAC           : integer := 8 * 9 / 2; -- Number of CMACs
		CROSS_BITS      : integer range 20 to 24 := 24; -- Bits of each part of the sum of a cross-product
		AUTO_BITS       : integer range 18 to 30 := 30; -- Bits of the sum of an autocorrelation
		AUTOCORR_STRIDE : integer := 1; -- Spacing (in CMACs) between autocorrelation products. We assume there will be NCMAC/AUTOCORR_STRIDE-1 autocorrelations
		CORR_NUMBER     : integer; -- correlator number to be used in packet headers
		NCORR           : integer := 1; -- Total number of correlators (not used; as UCMAC44_ARRAY)
		URAM_MAX        : integer := 20; -- Maximum number of RAM words (72 bits) in UltraRAM. The others use block RAMs.
		READOUT_BIN     : integer := 0; -- Bin number sacrificed for the readout cycle
		BINS_PER_FRAME_LOG2 : integer := 3 -- Aggregate 2**N readout bins per AXIS frame (TLAST every 2**N bins, or on the last bin). 3 => 8 bins/frame. 0: TLAST on each record.
	);
	port (
		-- Data be correlated & integrated. AXI4-Streaming, non-blocking.
		s_axis_xy_tdata  : in slv_array(0 to NCMAC - 1)(31 downto 0); -- Pairs of (8+8)-bit complex numbers to multiply. From MSB to LSB: X_re, X_im, Y_re, Y_im.
		s_axis_xy_tlast  : in std_logic;
		s_axis_xy_tvalid : in std_logic;
		s_axis_xy_swap   : in std_logic_vector(0 to NCMAC - 1); -- '1': conj(X) * Y

		bin_set       : in std_logic_vector(3 downto 0) := "0000"; -- current bin set, used in header only.
		integ_period  : in std_logic_vector(15 downto 0);
		autocorr_only : in std_logic                    := '1';
		no_accum      : in std_logic                    := '1'; -- when '1', there is no accumulation: only the last product of the accumulation period is kept. (for debugging)
		corr_id       : in std_logic_vector(3 downto 0); -- Software-defined identifier placed in the MSB of the STREAM ID.

		overrun       : out std_logic; -- indicates that data could not be streamed out fast enough and data was lost
		overrun_reset : in std_logic;

		last_frame  : out std_logic; -- '1' while the frame in the accumulators is the last frame of an integration
		integ_start : out std_logic_vector(47 downto 0); -- timestamp of the first frame of the integration in progress, as in the result packets

		-- Byte-serialized cascadable data input/outputs, AXI-Streaming, 8-bit, sloppy blocking via `send`
		m_axis_z_tdata  : out std_logic_vector(7 downto 0);
		m_axis_z_tlast  : out std_logic;
		m_axis_z_tvalid : out std_logic;
		m_axis_z_send   : in std_logic := '0';

		s_axis_z_tdata  : in std_logic_vector(7 downto 0) := (others => '0');
		s_axis_z_tlast  : in std_logic                    := '0';
		s_axis_z_tvalid : in std_logic                    := '0';
		s_axis_z_send   : out std_logic                   := '0';

		clk : in std_logic;
		rst : in std_logic
	);
end entity UCMAC88_ARRAY;

architecture impl of UCMAC88_ARRAY is

	attribute KEEP_HIERARCHY: string;
	attribute keep_hierarchy of impl: architecture is "YES";

	constant BYTES_PER_PRODUCT: integer := (2 * CROSS_BITS + 2 + 7) / 8; -- the two parts and two saturation flags: 6 bytes for 22 bits

	function is_auto(i: integer) return boolean is
	begin
		return i mod AUTOCORR_STRIDE = 0 and i / AUTOCORR_STRIDE < NCMAC / AUTOCORR_STRIDE - 1;
	end function;

	-- Position of the sum of CMAC i in the accumulator word (i = NCMAC: the number of bits of all the sums)
	function acc_offset(i: integer) return integer is
		variable n: integer := 0;
	begin
		for k in 0 to i - 1 loop
			if is_auto(k) then
				n := n + AUTO_BITS;
			else
				n := n + 2 * CROSS_BITS;
			end if;
		end loop;
		return n;
	end function;
	constant NWORDS: integer := (acc_offset(NCMAC) + 71) / 72; -- RAM words of 72 bits

	-- The sums of all the CMACs for one bin. A cross-product: RE, IM_HIGH, IM_LOW (in the LSBs).
	signal acc_dout: std_logic_vector(72 * NWORDS - 1 downto 0);
	signal acc_din: std_logic_vector(72 * NWORDS - 1 downto 0) := (others => '0');
	signal ro_raw: std_logic_vector(72 * NWORDS - 1 downto 0); -- the sums of the readout bin of this frame (the result bytes need a subtraction: one more clock)

	constant SAT_POS: std_logic_vector(CROSS_BITS - 1 downto 0) := std_logic_vector(to_signed(2 ** (CROSS_BITS - 1) - 1, CROSS_BITS));
	constant SAT_NEG: std_logic_vector(CROSS_BITS - 1 downto 0) := std_logic_vector(to_signed(-(2 ** (CROSS_BITS - 1)), CROSS_BITS));

	constant HIGH_BITS: integer := CROSS_BITS - 18; -- bits of IM_HIGH

	-- The bytes of a product in a result record (little-endian word), from the sums of one bin.
	-- Cross-product: bits CROSS_BITS - 1 : 0 = sum of the imaginary parts, bits 2 * CROSS_BITS - 1 : CROSS_BITS = sum of the
	-- real parts (RE - IM_HIGH), bit 2 * CROSS_BITS = the imaginary part is saturated, bit 2 * CROSS_BITS + 1 = the real part
	-- is saturated or not valid (also set when the imaginary part is saturated). A saturated part has the largest or the
	-- smallest value. Autocorrelation: unsigned number in the LSBs, bit 2 * CROSS_BITS + 1 = saturated.
	function product_bytes(acc: std_logic_vector; i: integer) return slv8_array is
		constant LSB: integer := acc_offset(i);
		variable prod: std_logic_vector(8 * BYTES_PER_PRODUCT - 1 downto 0) := (others => '0');
		variable re_field: std_logic_vector(CROSS_BITS - 1 downto 0);
		variable im_high: signed(HIGH_BITS - 1 downto 0);
		variable d: signed(CROSS_BITS downto 0); -- RE - IM_HIGH, with one more bit
		variable re_sat, im_sat: std_logic;
	begin
		if is_auto(i) then
			prod(AUTO_BITS - 1 downto 0) := acc(LSB + AUTO_BITS - 1 downto LSB);
			prod(2 * CROSS_BITS + 1) := and(acc(LSB + AUTO_BITS - 1 downto LSB));
		else
			re_field := acc(LSB + 2 * CROSS_BITS - 1 downto LSB + CROSS_BITS);
			im_high := signed(acc(LSB + CROSS_BITS - 1 downto LSB + 18));
			im_sat := to_std_logic(im_high = 2 ** (HIGH_BITS - 1) - 1 or im_high = -(2 ** (HIGH_BITS - 1)));
			d := resize(signed(re_field), CROSS_BITS + 1) - resize(im_high, CROSS_BITS + 1);
			re_sat := '1';
			if re_field = SAT_POS or (re_field /= SAT_NEG and d(CROSS_BITS) = '0' and d(CROSS_BITS - 1) = '1') then
				prod(2 * CROSS_BITS - 1 downto CROSS_BITS) := SAT_POS;
			elsif re_field = SAT_NEG or (d(CROSS_BITS) = '1' and d(CROSS_BITS - 1) = '0') then
				prod(2 * CROSS_BITS - 1 downto CROSS_BITS) := SAT_NEG;
			else
				prod(2 * CROSS_BITS - 1 downto CROSS_BITS) := std_logic_vector(d(CROSS_BITS - 1 downto 0));
				re_sat := '0';
			end if;
			if im_sat = '0' then
				prod(CROSS_BITS - 1 downto 0) := acc(LSB + CROSS_BITS - 1 downto LSB);
			elsif im_high(HIGH_BITS - 1) = '0' then
				prod(CROSS_BITS - 1 downto 0) := SAT_POS;
			else
				prod(CROSS_BITS - 1 downto 0) := SAT_NEG;
			end if;
			prod(2 * CROSS_BITS) := im_sat;
			prod(2 * CROSS_BITS + 1) := re_sat or im_sat;
		end if;
		return to_slv8_array(reverse_bytes(prod));
	end function;


	signal rst_reg: std_logic;

	signal ram_wr_addr: std_logic_vector(11 downto 0); -- 12 bits = 4096 words
	signal ram_rd_addr: std_logic_vector(11 downto 0);
	signal ram_wr_en: std_logic := '0';
	signal ram_rd_en: std_logic := '1';

	signal tvalid0, tvalid1, tvalid2, tvalid3, tvalid4: std_logic := '0';
	signal tlast0, tlast1, tlast2, tlast3, tlast4: std_logic;
	signal ro_word1, ro_word2, ro_word3: std_logic := '1'; -- first word of frame
	signal last_frame1, last_frame2, last_frame3, last_frame4: std_logic;
	signal first_frame1, first_frame2: std_logic := '1'; -- init needed

begin

	assert acc_offset(NCMAC) > 0 report "UCMAC88_ARRAY: " & integer'image(acc_offset(NCMAC)) & " accumulator bits in " & integer'image(NWORDS) & " RAM words" severity NOTE;

	ctrl_blk : block

		signal frame: unsigned(15 downto 0); -- 11-bits wide: 2048 integ, 12-bits wide: 4096 frame integration
		signal rd_word_ctr1: unsigned(10 downto 0); -- 2048 words/frame.
		signal ro_word_ctr1: unsigned(10 downto 0); -- readout word counter. 2048 words/frame.
		signal wr_word_ctr5: unsigned(10 downto 0); -- readout bank read address
		signal acc_bank1, acc_bank5: std_logic; -- Accumulator bank
		signal ro_word_ctr_max: unsigned(10 downto 0); -- Number of words to readout

		signal bytes: slv8_array(0 to FRAME_HEADER_BYTE_LENGTH + NCMAC * BYTES_PER_PRODUCT - 1); -- readout buffer: header, then the products
		signal byte_ctr: integer range 0 to bytes'LENGTH;
		signal ro_active: std_logic := '0'; -- bank readout busy
		signal ro_shift: std_logic := '0'; -- data available for shift out
		signal ro_last: std_logic := '0'; -- is the last shift out of the integ period
		constant GROUP_MASK: unsigned(10 downto 0) := to_unsigned(2 ** BINS_PER_FRAME_LOG2 - 1, 11); -- 0: each record closes a frame
		signal ro_group_end: std_logic := '0'; -- close the AXIS frame (assert TLAST) on this bin: every 2**BINS_PER_FRAME_LOG2 bins, or the last bin
		signal ro_bin_set: std_logic_vector(3 downto 0); -- bin set to be placed in the headers
		signal dc_busy: std_logic := '0'; -- daisy chain readout busy
		signal timestamp, integ_timestamp, readout_timestamp: unsigned(47 downto 0);
	begin

		--    ram_rd_addr <= (not acc_bank1) & std_logic_vector(ro_word_ctr1) when rd_word_ctr1=READOUT_BIN else
		--                   acc_bank1 & std_logic_vector(rd_word_ctr1);
		ram_wr_addr <= acc_bank5 & std_logic_vector(wr_word_ctr5);
		last_frame <= last_frame1;
		integ_start <= std_logic_vector(integ_timestamp);

		wr_proc: process(all)

			variable frame_header: frame_header_struct := (PROBE_ID => X"CF", others => (others => '0'));
			-- variable prod: integer range 0 to NCMAC; -- counts autocorr products (not NCMAC-1 because last increment?)
			variable next_timestamp: unsigned(47 downto 0);
			variable next_rd_word_ctr: unsigned(rd_word_ctr1'RANGE);
			variable next_acc_bank: std_logic;
			variable is_capture_word: boolean;

		begin
			if rising_edge(clk) then
				rst_reg <= rst;

				-- The data takes one clock more in the multipliers than in UCMAC44_ARRAY: this block has tvalid and tlast one clock late
				tvalid0 <= s_axis_xy_tvalid;
				tlast0 <= s_axis_xy_tlast;

				-------------
				-- CLOCK 1 - sign-corrected data is clocked into the DSP1 A & B registers, and we register sign and zero flags
				-------------


				-- Write state machine: count words and frames, and set the done signal
				--              src_readout_trig <= '0'; -- single clock pulse signal, overriden below
				if tvalid0 then
				    next_acc_bank := acc_bank1; -- get current accum bank
					next_rd_word_ctr := rd_word_ctr1 + 1;
					if tlast0 then
						ro_word_ctr_max <= rd_word_ctr1; -- capture the frame length so we can readout the same amount of words
						next_rd_word_ctr := (others => '0');
						frame <= frame + 1;
						next_timestamp := timestamp + 1;
						timestamp <= next_timestamp;
						if frame = unsigned(integ_period) then -- if last frame of the integration period
							frame <= (others => '0'); -- restart the readout from word 0
							overrun <= '1' when ro_active;
							ro_active <= '1'; -- start readout of the readout bank
							ro_bin_set <= bin_set; --  register the bin set on the last word of the last frame of the integ period
							readout_timestamp <= integ_timestamp;
							integ_timestamp <= next_timestamp; -- timestamp+1 should reuses the logic above
							s_axis_z_send <= '0'; -- tell the upstream cascaded correlators we stop accepting data
							next_acc_bank := not next_acc_bank; -- switch bank
						end if; -- last frame of integ_period
					end if; -- tlast
					-- set the next RAM address to read
					ram_rd_addr <= (not next_acc_bank) & std_logic_vector(ro_word_ctr1) when next_rd_word_ctr = READOUT_BIN else
	               next_acc_bank & std_logic_vector(next_rd_word_ctr);
					acc_bank1 <= next_acc_bank;
					rd_word_ctr1 <= next_rd_word_ctr;
				end if; -- tvalid

				-- pipeline the control signals
				tvalid1 <= tvalid0;
				tlast1 <= tlast0;
				ro_word1 <= to_std_logic(rd_word_ctr1 = READOUT_BIN); -- active when we are reading the readout bin
				last_frame1 <= to_std_logic(frame = unsigned(integ_period)); -- last frame of accumulation
				first_frame1 <= to_std_logic(all_zeros(frame)); -- last frame of accumulation
				-------------
				-- CLOCK 2: The product is clocked in the M=XY register of DSP1, and we clock the correction in the C=Z register.
				-- We also present the FIFO output back into the C input of the DSP2.
				-------------

				-- pipeline the control signals
				tvalid2 <= tvalid1;
				tlast2 <= tlast1;
				ro_word2 <= ro_word1;
				ro_word3 <= ro_word2;
				if ro_word2 then
					ro_raw <= acc_dout; -- the RAM has the readout bin on its outputs
				end if;
				last_frame2 <= last_frame1;
				first_frame2 <= first_frame1;

				-------------
				-- CLOCK 3: Pre-accumulation product (DSP1 sum XY+Z) was registered in DSP1.P
				--          RAM outputs registers the previous value for the same product, which is fed to DSP2.C.
				--          If this is the first word of the frame, RAM does not output the previous accumulated value but rather
				--          outputs at the current the readout address from the readout bank. We capture those in a byte array if we
				--          this array is free.
				-------------

				-- pipeline the control signals
				tvalid3 <= tvalid2;
				tlast3 <= tlast2;
				last_frame3 <= last_frame2;

				-- Clear tvalid. Is overriden below if a new byte is available.
				m_axis_z_tvalid <= '0';
				-- Clear send flag. Is overriden below when we are ready to forward data.
				s_axis_z_send <= '0'; -- m_axis_z_send;

				-- Send readout bytes from this correlator or from the down-cascaded correlator
				if ro_active then -- read data from this correlator
					if ro_shift then -- -- we have bytes to shift out
						s_axis_z_send <= '0';
						m_axis_z_tdata <= bytes(0);
						m_axis_z_tlast <= '0';
						m_axis_z_tvalid <= '0';
						if m_axis_z_send then -- we have a byte to shift out and we are allowed to send it
							m_axis_z_tvalid <= '1';
							if byte_ctr = 1 then -- last byte of this bin's packet
								-- Aggregation: only close the AXIS frame (assert TLAST) on a
								-- group boundary (every 2**BINS_PER_FRAME_LOG2 bins, or the last
								-- bin). Non-boundary bins keep tlast='0' so several bins pack into
								-- one DMA frame / UDP datagram. ro_group_end was registered with
								-- this bin (see capture branch below), same lifetime as ro_last.
								m_axis_z_tlast <= ro_group_end;
								ro_shift <= '0'; -- stop shifting
								if ro_last then -- if last readout on integration period
									ro_active <= '0';
								end if; -- last word
							end if;
							-- Shift the byte vector. This affects a verly large number of registers, so control logic has a high fanout.
							-- Control logic: ro_word2, ro_active, ro_shift, m_axis_z_send, and autocorr_only (see below)
							bytes(0 to bytes'LENGTH - 2) <= bytes(1 to bytes'LENGTH - 1);
							byte_ctr <= byte_ctr - 1;
						end if; -- if m_axis_z_send='1'
					elsif ro_word3 then -- ro_shift=0 ,ro_active=1
						-- Readout is active, no shift is in progress, and are processing the 1st product word of the frame,
						-- meaning the RAM outputs data from the readout bank. .
						-- We therefore capture the products in the byte array, set the byte counter and enable ro_shift.

						-- Store the header in the bytes buffer
                        frame_header.STREAM_ID(15 downto 11) := to_slv(to_integer(unsigned(corr_id)) + CORR_NUMBER, 5);
                        frame_header.STREAM_ID(10 downto 0) := std_logic_vector(ro_word_ctr1);
						-- frame_header.STREAM_ID(LOG2_NCORR-1 downto 0) := to_slv(CORR_NUMBER, LOG2_NCORR);
                        frame_header.TIMESTAMP := std_logic_vector(readout_timestamp);
                        frame_header.SERIAL_FLAGS := ro_bin_set;
                        frame_header.FLAGS(0) := overrun;
                        frame_header.FLAGS(1) := autocorr_only;
						bytes(0 to FRAME_HEADER_BYTE_LENGTH - 1) <= struct_to_bytes(frame_header);

						-- Store the product bytes in the bytes buffer
						-- Capture the RAM outputs, slice them in 5-byte products,  and store them in the shift register
						-- This affects a large number of registers, implying large fanout controls
						for i in 0 to NCMAC - 1 loop
							bytes(FRAME_HEADER_BYTE_LENGTH + BYTES_PER_PRODUCT * i to FRAME_HEADER_BYTE_LENGTH + BYTES_PER_PRODUCT * (i + 1) - 1) <= product_bytes(ro_raw, i);
						end loop;

						-- Override the first product bytes after the frame header with the autocorrelation products if autocorr='1'
						if autocorr_only then
							for i in 0 to NCMAC / AUTOCORR_STRIDE - 2 loop -- assume that last one is not an autocorrelation (first N elements in N+1 high column are autocorrs)
								bytes(FRAME_HEADER_BYTE_LENGTH + BYTES_PER_PRODUCT * i to FRAME_HEADER_BYTE_LENGTH + BYTES_PER_PRODUCT * (i + 1) - 1) <= product_bytes(ro_raw, i * AUTOCORR_STRIDE);
							end loop;
						end if;

						-- set the byte counter to signify we now have data to send
						if autocorr_only then
							-- We send only the autocorrelations. We dont have the NCHAN parameter, but if we assume that
							-- we have NCMAC = (NCHAN+1)*AUTOCORR_STRIDE CMACs, we can deduct if with  NCHAN = NCMAC/AUTOCORR_STRIDE-1
							byte_ctr <= FRAME_HEADER_BYTE_LENGTH + (NCMAC / AUTOCORR_STRIDE - 1) * BYTES_PER_PRODUCT;
						else
							byte_ctr <= FRAME_HEADER_BYTE_LENGTH + NCMAC * BYTES_PER_PRODUCT;
						end if;
						ro_shift <= '1'; -- there is data to shift out
						ro_last <= '0'; -- is this the last readout? overriden below.
						-- Aggregation frame boundary for this bin: assert TLAST every
						-- 2**BINS_PER_FRAME_LOG2 bins (i.e. when the low bits of the bin
						-- index are all ones, bin mod 2**N = 2**N-1). The last bin below
						-- forces it too so the frame always closes. Registered here so it
						-- stays stable while this bin's packet shifts out (like ro_last).
						if (ro_word_ctr1 and GROUP_MASK) = GROUP_MASK then
							ro_group_end <= '1';
						else
							ro_group_end <= '0';
						end if;
						-- Increment the readout word counter, or reset it if this is the last integration
						-- The readout word counter must be ready before we set the RAM read address for reading the first word of the next frame.
						-- Since we increment the counter 2 clocks after first word, and the next first word is almost one frame away,
						-- the counter is guaranteed to be ready
						ro_word_ctr1 <= ro_word_ctr1 + 1; -- next word to readout
						if ro_word_ctr1 = ro_word_ctr_max then -- last readout word
							-- Set the readout word counter(address) in preparation for the readout phase.
							ro_word_ctr1 <= (others => '0');
							ro_last <= '1';
							ro_group_end <= '1'; -- the last bin always closes the AXIS frame
						end if;
					end if; -- ro_shift, ro_word2


				else -- ro_active=0, sending cascade input data if any
					s_axis_z_send <= m_axis_z_send; -- pass on the send flag
					m_axis_z_tvalid <= s_axis_z_tvalid;
					m_axis_z_tdata <= s_axis_z_tdata;
					m_axis_z_tlast <= s_axis_z_tlast;
					if s_axis_z_tvalid then
						dc_busy <= '1';
						if s_axis_z_tlast then
							dc_busy <= '0';
							s_axis_z_send <= '0';
						end if;
					end if;
				end if; -- if ro_active


				-------------
				-- CLOCK 4: Register the accumulated product in DSP2.P and set the RAM wr_en signal if data is valid.
				-------------

				--= pipeline control signals
				tvalid4 <= tvalid3;
				tlast4 <= tlast3; -- last word
				last_frame4 <= last_frame3; -- last frame
				ram_wr_en <= tvalid3; -- write the data

				-------------
				-- CLOCK 5:  Increment write address once data has been written. Switch write bank if last frame is completed.
				-------------

				-- Increment ram write address post-write
				if tvalid4 then
					wr_word_ctr5 <= wr_word_ctr5 + 1;
					if tlast4 then
						wr_word_ctr5 <= (others => '0');
					end if;
					if tlast4 and last_frame4 then
						acc_bank5 <= not acc_bank5;
					end if;
				end if;


				if overrun_reset then
					overrun <= '0';
				end if;

				-- Synchronous resets (overrides signals above)
				if rst_reg then
					rd_word_ctr1 <= (others => '0');
					ro_word_ctr1 <= (others => '0'); -- prepare readout word counter for first readout.
					ram_rd_addr <= (others => '0'); -- always zero since acc_bank=0 and rd/ro_word_ctr=0 as well

					frame <= (others => '0');
					ro_active <= '0';
					ro_group_end <= '0';
					overrun <= '0';

					timestamp <= (others => '0');
					integ_timestamp <= (others => '0');

					tvalid0 <= '0';
					tvalid1 <= '0';
					tvalid2 <= '0';
					tvalid3 <= '0';
					tvalid4 <= '0';


					acc_bank1 <= '0';
					acc_bank5 <= '0';
					wr_word_ctr5 <= (others => '0');

				--          first_frame2 <= '1';
				--          last_frame4 <= '0';
				end if;

			end if; -- CLK
		end process wr_proc;

	end block ctrl_blk;

	-----------------------------
	-- DSPs
	-----------------------------
	-- The clock numbers are those of the control block (one clock after the clock of the input data).
	dsp_gen: for i in 0 to NCMAC - 1 generate
		constant LSB: integer := acc_offset(i);
		constant AUTO: boolean := is_auto(i);

		signal a, b, c, d: std_logic_vector(7 downto 0);
		signal a_dly, b_dly, d_dly: std_logic_vector(7 downto 0);
		signal swap_dly: std_logic;
		signal inmode1, inmode2: std_logic_vector(4 downto 0);
		signal dsp1_a, dsp2_a: std_logic_vector(29 downto 0);
		signal dsp1_b, dsp2_b: std_logic_vector(17 downto 0);
		signal dsp1_d, dsp2_d: std_logic_vector(26 downto 0);
		signal dsp1_pcout: std_logic_vector(47 downto 0);
		signal dsp2_c: std_logic_vector(47 downto 0) := (others => '0');
		signal dsp2_p: std_logic_vector(47 downto 0);
		signal dsp2_opmode: std_logic_vector(8 downto 0);
		signal first: std_logic; -- no sum from the RAM
		signal msb3, msb4: std_logic; -- autocorrelation: MSB of the sum from the RAM
		signal re_sign3, re_sign4, re_sat3, re_sat4: std_logic; -- RE from the RAM: its sign, and it is at a limit
		signal low3, low4: std_logic_vector(1 downto 0); -- the two MSBs of IM_LOW from the RAM
		signal high3, high4, high4_up, high4_dn: signed(HIGH_BITS - 1 downto 0); -- IM_HIGH from the RAM, with one more and one less
		signal high_hold4: std_logic; -- IM_HIGH is at a limit
	begin
		a <= s_axis_xy_tdata(i)(31 downto 24); -- X_re
		b <= s_axis_xy_tdata(i)(23 downto 16); -- X_im
		c <= s_axis_xy_tdata(i)(15 downto 8); -- Y_re
		d <= s_axis_xy_tdata(i)(7 downto 0); -- Y_im

		-- dsp1: (a * 2^18 + b) * c. With swap: (a * 2^18 - b) * c.
		dsp1_d <= a(7) & a & "000000000000000000";
		dsp1_a <= std_logic_vector(resize(signed(b), 30));
		dsp1_b <= std_logic_vector(resize(signed(c), 18));
		inmode1 <= "0" & s_axis_xy_swap(i) & "100"; -- D + A, or D - A

		-- dsp2 is one clock after dsp1: (b * 2^18 - a) * d + dsp1 + sum from the RAM. With swap: (b * 2^18 + a) * d.
		dsp2_d <= b_dly(7) & b_dly & "000000000000000000";
		dsp2_a <= std_logic_vector(resize(signed(a_dly), 30));
		dsp2_b <= std_logic_vector(resize(signed(d_dly), 18));
		inmode2 <= "0" & (not swap_dly) & "100"; -- D - A, or D + A

		-- The sum from the RAM (CLOCK 3: it goes in the C register of dsp2)
		first <= first_frame2 or no_accum;
		c_gen: if AUTO generate
			dsp2_c(18 + AUTO_BITS - 1 downto 18) <= acc_dout(LSB + AUTO_BITS - 1 downto LSB);
		else generate
			dsp2_c(47 downto 18) <= std_logic_vector(resize(signed(acc_dout(LSB + 2 * CROSS_BITS - 1 downto LSB + CROSS_BITS)), 30)); -- RE
			dsp2_c(17 downto 0) <= acc_dout(LSB + 17 downto LSB); -- IM_LOW
		end generate c_gen;
		dsp2_opmode <= "000010101" when first = '1' else -- P = M + PCIN (first frame of an integration)
		               "110010101"; -- P = M + PCIN + C

		dsp1: DSP48E2
			generic map (
				AMULTSEL => "AD", A_INPUT => "DIRECT", BMULTSEL => "B", B_INPUT => "DIRECT", PREADDINSEL => "A",
				USE_MULT => "MULTIPLY", USE_SIMD => "ONE48", USE_PATTERN_DETECT => "NO_PATDET",
				AREG => 1, ACASCREG => 1, BREG => 2, BCASCREG => 2, DREG => 1, ADREG => 1, INMODEREG => 1, MREG => 1, PREG => 1,
				CREG => 1, OPMODEREG => 1, ALUMODEREG => 1, CARRYINREG => 1, CARRYINSELREG => 1
			)
			port map (
				acout => open, bcout => open, carrycascout => open, multsignout => open, pcout => dsp1_pcout,
				overflow => open, patternbdetect => open, patterndetect => open, underflow => open, carryout => open, p => open, xorout => open,
				acin => (others => '0'), bcin => (others => '0'), carrycascin => '0', multsignin => '0', pcin => (others => '0'),
				alumode => "0000", carryinsel => "000", clk => clk, inmode => inmode1, opmode => "000000101", -- P = M
				a => dsp1_a, b => dsp1_b, c => (others => '1'), carryin => '0', d => dsp1_d,
				cea1 => '1', cea2 => '1', cead => '1', cealumode => '1', ceb1 => '1', ceb2 => '1', cec => '1', cecarryin => '1',
				cectrl => '1', ced => '1', ceinmode => '1', cem => '1', cep => '1',
				rsta => '0', rstallcarryin => '0', rstalumode => '0', rstb => '0', rstc => '0', rstctrl => '0', rstd => '0',
				rstinmode => '0', rstm => '0', rstp => '0'
			);

		dsp2: DSP48E2
			generic map (
				AMULTSEL => "AD", A_INPUT => "DIRECT", BMULTSEL => "B", B_INPUT => "DIRECT", PREADDINSEL => "A",
				USE_MULT => "MULTIPLY", USE_SIMD => "ONE48", USE_PATTERN_DETECT => "NO_PATDET",
				AREG => 1, ACASCREG => 1, BREG => 2, BCASCREG => 2, DREG => 1, ADREG => 1, INMODEREG => 1, MREG => 1, PREG => 1,
				CREG => 1, OPMODEREG => 1, ALUMODEREG => 1, CARRYINREG => 1, CARRYINSELREG => 1
			)
			port map (
				acout => open, bcout => open, carrycascout => open, multsignout => open, pcout => open,
				overflow => open, patternbdetect => open, patterndetect => open, underflow => open, carryout => open, p => dsp2_p, xorout => open,
				acin => (others => '0'), bcin => (others => '0'), carrycascin => '0', multsignin => '0', pcin => dsp1_pcout,
				alumode => "0000", carryinsel => "000", clk => clk, inmode => inmode2, opmode => dsp2_opmode,
				a => dsp2_a, b => dsp2_b, c => dsp2_c, carryin => '0', d => dsp2_d,
				cea1 => '1', cea2 => '1', cead => '1', cealumode => '1', ceb1 => '1', ceb2 => '1', cec => '1', cecarryin => '1',
				cectrl => '1', ced => '1', ceinmode => '1', cem => '1', cep => '1',
				rsta => '0', rstallcarryin => '0', rstalumode => '0', rstb => '0', rstc => '0', rstctrl => '0', rstd => '0',
				rstinmode => '0', rstm => '0', rstp => '0'
			);

		dsp_proc: process(clk)
			variable high_v: signed(HIGH_BITS - 1 downto 0);
		begin
			if rising_edge(clk) then
				-- dsp2 is one clock after dsp1
				a_dly <= a;
				b_dly <= b;
				d_dly <= d;
				swap_dly <= s_axis_xy_swap(i);

				-- CLOCK 3: the fields from the RAM that the logic after dsp2 needs (zeros for the first frame: dsp2 does not add the sum)
				if AUTO then
					msb3 <= acc_dout(LSB + AUTO_BITS - 1) and not first;
				else
					re_sign3 <= acc_dout(LSB + 2 * CROSS_BITS - 1);
					re_sat3 <= to_std_logic(first = '0' and (acc_dout(LSB + 2 * CROSS_BITS - 1 downto LSB + CROSS_BITS) = SAT_POS or acc_dout(LSB + 2 * CROSS_BITS - 1 downto LSB + CROSS_BITS) = SAT_NEG));
					if first then
						low3 <= "00";
						high3 <= (others => '0');
					else
						low3 <= acc_dout(LSB + 17 downto LSB + 16);
						high3 <= signed(acc_dout(LSB + CROSS_BITS - 1 downto LSB + 18));
					end if;
				end if;

				-- CLOCK 4: the new sum is in the P register of dsp2
				msb4 <= msb3;
				re_sign4 <= re_sign3;
				re_sat4 <= re_sat3;
				low4 <= low3;
				high4 <= high3;
				high4_up <= high3 + 1;
				high4_dn <= high3 - 1;
				high_hold4 <= to_std_logic(high3 = 2 ** (HIGH_BITS - 1) - 1 or high3 = -(2 ** (HIGH_BITS - 1)));
			end if;
		end process dsp_proc;

		-- The new sum to the RAM (combinatorial logic between the P register of dsp2 and the RAM inputs)
		sat_gen: if AUTO generate
			-- one product is less than half the range: the sum passed its limit if its MSB went from 1 to 0
			acc_din(LSB + AUTO_BITS - 1 downto LSB) <= (others => '1') when msb4 = '1' and dsp2_p(18 + AUTO_BITS - 1) = '0' else dsp2_p(18 + AUTO_BITS - 1 downto 18);
		else generate
			signal re_up, re_dn, im_up, im_dn: std_logic;
		begin
			-- RE has 30 bits in dsp2: it is past a limit if its MSBs are not all equal
			re_up <= not dsp2_p(47) and or(dsp2_p(46 downto 18 + CROSS_BITS - 1));
			re_dn <= dsp2_p(47) and nand(dsp2_p(46 downto 18 + CROSS_BITS - 1));
			acc_din(LSB + 2 * CROSS_BITS - 1 downto LSB + CROSS_BITS) <=
				SAT_POS when (re_sat4 = '1' and re_sign4 = '0') or re_up = '1' else
				SAT_NEG when (re_sat4 = '1' and re_sign4 = '1') or re_dn = '1' else
				dsp2_p(18 + CROSS_BITS - 1 downto 18);

			-- IM_LOW passed 2^18 (from its last quarter to its first quarter) or 0 (the opposite)
			im_up <= to_std_logic(low4 = "11" and dsp2_p(17 downto 16) = "00");
			im_dn <= to_std_logic(low4 = "00" and dsp2_p(17 downto 16) = "11");
			acc_din(LSB + CROSS_BITS - 1 downto LSB + 18) <=
				std_logic_vector(high4) when high_hold4 = '1' else
				std_logic_vector(high4_up) when im_up = '1' else
				std_logic_vector(high4_dn) when im_dn = '1' else
				std_logic_vector(high4);
			acc_din(LSB + 17 downto LSB) <= dsp2_p(17 downto 0);
		end generate sat_gen;

	end generate dsp_gen;

	-----------------------------
	-- RAM blocks
	-----------------------------
	-- As in UCMAC44_ARRAY (see the notes there on the read latency of 2 and on the placement of the block RAMs),
	-- but each RAM has 72 bits of the accumulator word and not the sums of two CMACs.
	ram_gen: for i in 0 to NWORDS - 1 generate
		constant MEM_TYPE: string := sel(i < URAM_MAX, "ultra", "block");
	begin
		ram0: xpm_memory_sdpram
			generic map (
				MEMORY_PRIMITIVE   => MEM_TYPE,
				ADDR_WIDTH_A       => 12,
				WRITE_DATA_WIDTH_A => 72,
				BYTE_WRITE_WIDTH_A => 72,
				ADDR_WIDTH_B       => 12,
				READ_DATA_WIDTH_B  => 72,
				MEMORY_SIZE        => 72 * 4096, -- two banks of 2048 bins: 1 x URAM288 or 8 x RAMB36
				READ_LATENCY_B     => 2,
				SIM_ASSERT_CHK     => 1,
				WRITE_MODE_B       => "read_first",
				WRITE_PROTECT      => 1
			)
			port map (
				dina  => acc_din(72 * i + 71 downto 72 * i),
				addra => ram_wr_addr,
				ena   => ram_wr_en,
				wea   => "1",
				doutb => acc_dout(72 * i + 71 downto 72 * i),
				addrb => ram_rd_addr,
				enb   => ram_rd_en,
				clka  => clk,
				rstb  => rst_reg,
				sleep          => '0',
				injectsbiterra => '0',
				injectdbiterra => '0',
				regceb         => '1',
				clkb           => '0'
			);
	end generate ram_gen;

end architecture impl;
