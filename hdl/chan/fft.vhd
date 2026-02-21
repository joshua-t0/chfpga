----------------------------------------------------------------------------------
-- Company: McGill University, Cosmology Instrumentation Lab
-- Engineer: J.-F. Cliche
--
-- Create Date:    20:34:01 03/26/2011
-- Design Name:    chFPGA
-- Module Name:    FFT - Behavioral
-- Project Name: CHIME/CHORD
-- Target Devices: Virtex 6, Kintex 7, Ultrascale+
-- Tool versions: Vivado 2022.2
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--  2012-05-31 JFC: Rewritten for the new PFB_FFT and AXI4 Streaming input and output buses
--      2012-08-31 JFC: Rewritten to include the SYNC generator, cleanup reset sequence, and use the new latency counter/delay line.
--      2012-09-11 JFC: Set sync_period to zero (no sync) by default.
--    2012-09-20 JFC: Implemented a better OVERFLOW_COUNTER with its own reset. CHanged default values for FFT_SHIFT.
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.chFPGA_Package.all; -- Get all component definitions
use work.chFPGA_config.all; -- get platform-specific configurations

library UNISIM;
use UNISIM.VComponents.all;

--===== ENTITY DECLARATION ======================

-- Wraps a CASPER wideband FFT into a non-blocking AXI4-STREAMING
-- processing block with a few memory-mapped control registers.
--
-- The FFT input is an non-blocking, AXI4-Streaming bus that accepts ``ADC_SAMPLES_PER_WORD`` ADC samples per clock,
-- each clock providing ``ADC_BITS_PER_SAMPLE`` bits for each sample. ADC samples are signed values, and are packed
-- into a single word with the first sample being placed in the most significant bits of the word.
-- A frame consists of ``CONFIG_ADC_SAMPLES_PER_FRAME`` samples, or ``CONFIG_ADC_SAMPLES_PER_FRAME/ADC_SAMPLES_PER_WORD`` words.
--
-- The FFT is a PFB-FFT from CASPER.  The PFB submodule processes ``ADC_SAMPLES_PER_WORD``
-- and applies windowing across 4 consecutive frames.
-- The FFT submodule performs the **real** FFT operation on the windowed data.
-- Since the input data is real, the negative frequency bins are the
-- complex conjugate of the corresponding positive frequency bins.  The FFT is designed to taka
-- advantage of this, and discards the negative frequencies in exchange of the ability to to process
-- twice as many samples per clock.
--
-- The FFT outputs ``ADC_SAMPLES_PER_WORD/2`` complex numbers per clock, for a total of CONFIG_ADC_SAMPLES_PER_FRAME/2 frequency bins.
-- Each complex number consist of a ``FFT_BITS_PER_BIN``-bit vector, where the ``FFT_BITS_PER_BIN/2`` most significant bits are the signed real part and
-- the ``FFT_BITS_PER_BIN/2`` least significant bits are the signed imaginary part.
-- Those ``ADC_SAMPLES_PER_WORD/2`` complex numbers are packed into a ``FFT_BITS_PER_WORD`` bit wide vector, where the lower bin in stored in the MSBs.
-- This vector is streamed out as a non-blocking AXI-streaming bus.
--
-- In BYPASS mode, each of the 8 bit of the input are signed extended to 18 bits and are passed to
-- the output in the same order. The TUSER bits from the input are also passed directly to the output.
--
--
-- Generating the underlying CASPER FFT block
-- ==========================================
--
-- The following system setup was used:
--     - Matlab 200Xb
--     - ISE 12.X
--     - CASPER libraries 10.X
--     - Path added to MATLAB:
--        - mlib_devel_10_X/casper_library
--
-- Other configurations might work.
--
-- The CASPER toolset must be open in the Simulink library browser before the FFT model is loaded to force it to re-parse the library
--
-- Configurations
-- ==============
--
-- The FFT currently exists in 2 configurations:
--
--   - CHIME (N_bit_in = 32,  N_samp = 4, N_bit_out = 72)
--      Uses a 2048-sample FFT, 8-bit per samples, 4 samples (32-bits) per clock. Sampling is at 800 MSPS and processing clock is 200 MHz. This is typically run on a Xilinx Kintex 7 (XC7K420).
--
--      Each output word contains two 36-bit complex numbers (18 bit real signed + 18 bit imaginary signed values).
--      The most significant 36 bits contains the value for the even frequency bins,
--      while the lower ones is the value for the odd frequency bin.
--      The Most significant bits of a complex value contains the real part.
--
--   - D3A/CHORD (N_bit_in = 112, N_samp = 8, N_bit_out = 144)
--      Uses a 16384-sample FFT, 14-bit per sample, 8 samples (112-bits) per clock. Sampling is at 3200 MSPS and processing clock is at 400 MHz. This is typically run on a Xilinx Ultrascale+ Zynq RfSoC (ZU027/28 or ZU047/48).
--
--      Each N_bit_out-bit word contains four 36-bit complex numbers (18 bit real signed + 18 bit imaginary signed values).
--      The most significant 36 bits contains the value for the first (even) frequency bins, the next contains the value for
--      the following odd bin, etc.
--      The Most significant bits of a complex value contains the real part.
entity fft is
	generic (
		IMPLEMENT_FFT		   : BOOLEAN := TRUE;
		FFT_TYPE			   : fft_type_enum := HIRAX; -- tells the entity which experiment-dependent Casper-generated PFB/FFT block to use. Currently accepts "CHIME" or "D3A"
		ROTATE_BINS            : boolean := FALSE; -- rotate down the bins in the output by N positions, where N is the word number. Used to spread low bins to multiple word positions in cases where the FFT does not naturally do that (e.g. no unscrambler)

        -- Derived (but overridable) parameters
		ADC_BITS_PER_SAMPLE    : integer := FFT_INFO(FFT_TYPE).BITS_PER_SAMPLE; -- CHIME: 8 bits, D3A/CHORD: 14 bits
		ADC_SAMPLES_PER_WORD   : integer := FFT_INFO(FFT_TYPE).SAMPLES_PER_WORD; -- CHIME: 4, D3A/CHORD: 8
		ADC_BITS_PER_WORD	   : integer := ADC_BITS_PER_SAMPLE * ADC_SAMPLES_PER_WORD;
		FUNCGEN_TUSER_BITS_PER_WORD: integer := 1;
		FFT_TUSER_BITS_PER_WORD: integer := FUNCGEN_TUSER_BITS_PER_WORD + 1; -- add 1 bit for FFT overflow
		FFT_BITS_PER_BIN 	   : integer := FFT_INFO(FFT_TYPE).BITS_PER_BIN; -- real + imaginary
		FFT_BINS_PER_WORD 	   : integer := FFT_INFO(FFT_TYPE).BINS_PER_WORD; -- CHIME: 2, D3A/CHORD: 4. -- we divide by 2 because the FFT outputs only the positive frequencies
		FFT_BITS_PER_WORD 	   : integer := FFT_BITS_PER_BIN * FFT_BINS_PER_WORD
		);

	port (

		-- Input Interface: AXI4 Streaming, non-blocking, `ADC_BITS_PER_WORD`-wide, synchronous to `clk`
		-- Each word presents `ADC_SAMPLES_PER_WORD` samples  where the early sample is in the MSB.

		s_axis_in_dat_tdata    : in std_logic_vector(ADC_BITS_PER_WORD-1 downto 0);
		s_axis_in_dat_tvalid   : in std_logic;
		s_axis_in_dat_tlast    : in std_logic;
		s_axis_in_dat_tuser    : in std_logic_vector(FUNCGEN_TUSER_BITS_PER_WORD-1 downto 0);

		-- Output Interface: AXI4 Streaming, non-blocking, `FFT_BITS_PER_WORD`-wide, synchronous to
		-- `clk` Each word is made of `ADC_SAMPLES_PER_WORD/2` frequency bins (Re + Im), where the
		-- the lower bin is in the MSB of the word, and the real part of that bin is also in the
		-- MSB.

		m_axis_out_dat_tdata   : out std_logic_vector(FFT_BITS_PER_WORD-1 downto 0);
		m_axis_out_dat_tvalid  : out std_logic;
		m_axis_out_dat_tlast   : out std_logic;
		m_axis_out_dat_tuser   : out std_logic_vector(FFT_TUSER_BITS_PER_WORD-1 downto 0);

		-- Clock and Reset

		clk     : in  std_logic; -- Processing clock, common to the input and output bus
		reset   : in  std_logic; -- clk-synchronous channelizer reset.
		                         -- In this module, resets the SYNC generator and send SYNC signals to the FFT

		-- Control bus (Byte-Serial-Bus protocol)

		s_axis_bsb_tdata  : in  std_logic_vector(7 downto 0);
		s_axis_bsb_tvalid : in  std_logic;
		s_axis_bsb_tlast  : in  std_logic;
		s_axis_bsb_tready : out std_logic;
		m_axis_bsb_tdata  : out std_logic_vector(7 downto 0);
		m_axis_bsb_tvalid : out std_logic;
		m_axis_bsb_tlast  : out std_logic;
		m_axis_bsb_tready : in  std_logic;
		bsb_clk           : in  std_logic;
		bsb_rst           : in  std_logic
		);
end fft;


--------- FFT architecture --------------------
-- Implements the FFT module functionnalities
architecture Behavioral of FFT is

	attribute DONT_TOUCH: string;
	attribute shreg_extract: string;

    -- Latencies of each type of FFT. These are used as default values in the FFT_LATENCY control register
    constant FFT_LATENCY: integer := FFT_INFO(FFT_TYPE).LATENCY;
	constant FFT_DELAY_CTR_WIDTH: integer := bitwidth(FFT_LATENCY); -- CHIME: 12, D3A/CHORD: 14

	signal flags_in, flags_out: std_logic_vector(FUNCGEN_TUSER_BITS_PER_WORD+1 downto 0); -- add 2 bits for tlast and sync

	signal fft_pipeline_delay: std_logic_vector(FFT_DELAY_CTR_WIDTH - 1 downto 0);
	signal fft_measured_pipeline_delay: std_logic_vector(FFT_DELAY_CTR_WIDTH - 1 downto 0);
	signal sync_reset: std_logic;


	-- CASPER FFT output
	signal fft_in_tvalid       : std_logic;
	signal fft_in_tdata        : std_logic_vector(s_axis_in_dat_tdata'RANGE);
	signal fft_in_tlast        : std_logic;
	signal fft_in_tuser        : std_logic_vector(FUNCGEN_TUSER_BITS_PER_WORD-1 downto 0);

    -- Rotated FFT output
	signal fft_rot_tvalid  : std_logic;
	signal fft_rot_tdata   : std_logic_vector(m_axis_out_dat_tdata'RANGE);
	signal fft_rot_tlast   : std_logic;
	signal fft_rot_tuser   : std_logic_vector(FUNCGEN_TUSER_BITS_PER_WORD-1 downto 0);
    attribute shreg_extract of fft_rot_tdata, fft_rot_tuser, fft_rot_tvalid, fft_rot_tlast : signal is "no";


	signal out_dat_pre_tvalid  : std_logic;
	signal out_dat_pre_tdata   : std_logic_vector(m_axis_out_dat_tdata'RANGE);
	signal out_dat_pre_tlast   : std_logic;
	signal out_dat_pre_tuser   : std_logic_vector(FUNCGEN_TUSER_BITS_PER_WORD-1 downto 0);
    attribute shreg_extract of out_dat_pre_tdata, out_dat_pre_tuser, out_dat_pre_tvalid, out_dat_pre_tlast : signal is "no";

    -- Bypass pipeline
	signal bypass1_tvalid  : std_logic;
	signal bypass1_tdata   : std_logic_vector(s_axis_in_dat_tdata'RANGE);
	signal bypass1_tlast   : std_logic;
	signal bypass1_tuser   : std_logic_vector(FUNCGEN_TUSER_BITS_PER_WORD-1 downto 0);
    attribute shreg_extract of bypass1_tdata, bypass1_tuser, bypass1_tvalid, bypass1_tlast : signal is "no";

	signal bypass2_tvalid  : std_logic;
	signal bypass2_tdata   : std_logic_vector(s_axis_in_dat_tdata'RANGE);
	signal bypass2_tlast   : std_logic;
	signal bypass2_tuser   : std_logic_vector(FUNCGEN_TUSER_BITS_PER_WORD-1 downto 0);
    attribute shreg_extract of bypass2_tdata, bypass2_tuser, bypass2_tvalid, bypass2_tlast : signal is "no";

	signal fft_dout0_int, fft_dout1_int: std_logic_vector(FFT_BITS_PER_BIN-1 downto 0) := (others=>'0');

	-- Add 2 more output signals for D3A FFT
	signal fft_dout2_int, fft_dout3_int: std_logic_vector(FFT_BITS_PER_BIN-1 downto 0) := (others=>'0');

	signal fft_clk_en: std_logic:='1'; -- init value needed for initial sync
	signal fft_clk_en_buf: std_logic;
	signal delay_clk_en: std_logic;
	signal fft_tdata: std_logic_vector(m_axis_out_dat_tdata'RANGE) := (others=>'0');
	signal fft_sync_in: std_logic := '1'; -- init value needed to generate first sync pulse
	signal fft_sync_out: std_logic := '0';
	signal fft_sync_out2: std_logic := '0';
	signal fft_overflow: std_logic := '0';
	signal fft_overflow_d3a: std_logic_vector(1 downto 0) := (others=>'0'); -- temporary hack --fixme
	-- signal fft_overflow: std_logic_vector(FFT_OVERFLOW_BITLENGTH-1 downto 0) := (others=>'0');
	signal fft_overflow_sticky: std_logic;
	signal fft_rot_overflow_sticky: std_logic;
	signal out_dat_pre_overflow_sticky: std_logic;
	signal fft_tuser: std_logic_vector(FUNCGEN_TUSER_BITS_PER_WORD - 1 downto 0);
	signal fft_tlast: std_logic;
	signal fft_tvalid: std_logic;

	--- Define Control word and its signals
	signal control_bytes: slv8_array(0 to 6);
	signal status_bytes: slv8_array(0 to 4);

	signal bypass_fft: std_logic;
	signal soft_reset: std_logic;
	signal fft_shift_schedule: std_logic_vector(15 downto 0);
	signal overflow_count: unsigned(7 downto 0);
	signal overflow_reset: std_logic;
	signal overflow_force: std_logic;

	signal sync_period: unsigned(15 downto 0);
	signal sync_frame_ctr: unsigned(sync_period'Range):=(others=>'0'); -- Counts SYNC pulses
	signal sync_period_is_zero: std_logic;
	signal is_last_frame_of_sync_period: std_logic;

    signal word_ctr: unsigned_array(0 to FFT_BINS_PER_WORD-1)(INTEGER_LOG2(FFT_BINS_PER_WORD)-1 downto 0); -- counts words at the output of the FFT. Used to rotate the bins
	attribute DONT_TOUCH of word_ctr: signal is "yes";
begin

-----------------------------------------------------------------------------------
-- Memory Map
--
-- ------------------------------------------------------------------------------
-- |  Page   | Addr|Bit(s)|     Name             | Description                   |
-- |---------|-----|------|----------------------|-------------------------------|
-- | CONTROL |  0  | 7    | soft_reset           | Reset the block. Also reset the computation of the CASPER block pipelining delay. When released, the block will compute the block latency once a CASPER SYNC has passed through the block and make the result available.|
-- |         |     | 6:4  |  Unused              |                               |
-- |         |     |  3   | overflow_force       | Forces the overflow flag to 1. Used for testing. |
-- |         |     |  2   | overflow_reset       | Resets the overflow counter   |
-- |         |     |  1   | Unused               |                               |
-- |         |     |  0   | bypass_fft           | Bypass the FFT                |
-- |         | 1:2 | 15:0 | fft_shift_schedule   | Sets the shifting schedule through the FFT to prevent overflow. Bit 0 specifies the behavior of stage 0, bit 1 of stage 1, and so on. |
-- |         | 3:4 | 15:0 | sync_period          | Number of clock cycles between SYNC pulses. If zero, no SYNC pulses are generated. See CASPER documentation for minimum SYNC spacing. |
-- |         | 5:6 | 15:0 | fft_pipeline_delay   | Latency (in number of clocks) of the CASPER PFB/FFT. This is used to delay the input flags that accompany the data fed into the FFT so they come out aligned with the FFT output. This should be the values measured by fft_measured_pipeline_delay. |
-- | STATUS  | 0:1 | 15:0 | fft_measured_pipeline_delay   | Measured latency (in number of clocks) of the CASPER PFB/FFT. This is updated when a reset is performed |
-- |         |  2  |  7:0 | overflow_count       | Number of FFT overflows since reset (rolls back) |
-- |         |  3  |  7:3 | fft_delay_ctr_width  | Width of the counter for the latency of the CASPER PFB/FFT |
-- |         |     |  2:0 | fft_type             | Type of FFT implemented in the firmware |
-- |         |  4  |   7  | IMPLEMENT_FFT        | '1' when FFT is implemented |
-- |         |     |   6  | ROTATE_BINS          | '1' when bin rotation is enabled |
-- |         |     |   5  | sync_reset           | Synchronous reset status |
-- |         |     | 4:0  | (unused)             |                               |
-- ------------------------------------------------------------------------------
--

-- CONTROL Byte 0
soft_reset <= control_bytes(0)(7);
overflow_reset <= control_bytes(0)(2);
overflow_force <= control_bytes(0)(3);
bypass_fft <= control_bytes(0)(0); --

-- CONTROL Byte 1-2
fft_shift_schedule <= to_slv(control_bytes(1 to 2),fft_shift_schedule'LENGTH); --Sets the shifting schedule through the FFT to prevent overflow. Bit 0 specifies the behavior of stage 0, bit 1 of stage 1, and so on.

-- CONTROL Bytes 3-4
sync_period <= to_unsigned(control_bytes(3 to 4));

-- CONTROL Bytes 5-6
fft_pipeline_delay <= to_slv(control_bytes(5 to 6),fft_pipeline_delay'LENGTH);

-- STATUS Byte 0-1
status_bytes(0 to 1) <= to_slv8_array(resize(fft_measured_pipeline_delay, 16)); -- fft_measured_pipeline_delay(11 downto 8), fft_measured_pipeline_delay(7 downto 0));

-- STATUS Byte 2
status_bytes(2) <= std_logic_vector(overflow_count);

-- STATUS BYTE 3
status_bytes(3)(2 downto 0) <= to_slv(fft_type_enum'POS(FFT_TYPE), 3);
status_bytes(3)(7 downto 3) <= to_slv(FFT_DELAY_CTR_WIDTH, 5);

-- STATUS BYTE 4

status_bytes(4)(7) <= to_std_logic(IMPLEMENT_FFT);
status_bytes(4)(6) <= to_std_logic(ROTATE_BINS);
status_bytes(4)(5) <= sync_reset;

-----------------------------------------------------------------------------------
-- Memory-Mapped interface
-----------------------------------------------------------------------------------
-- Instantiates a memory-mapped interface to the control and status bytes
bsb_regs0: entity work.bsb_regs
	GENERIC MAP (
		NUMBER_OF_CONTROL_BYTES => control_bytes'LENGTH(1), -- Number of bits in the control word
		NUMBER_OF_STATUS_BYTES  => status_bytes'LENGTH(1), -- Number of bits in the status word.
		DEFAULT_CONTROL_BYTES   => X"00_03FF_0000" & to_slv(FFT_LATENCY, 16) -- default values.
	)

	PORT MAP(
		-- Control interface (command and reply stream buses)
		s_axis_bsb_tdata => s_axis_bsb_tdata,
		s_axis_bsb_tvalid => s_axis_bsb_tvalid,
		s_axis_bsb_tlast => s_axis_bsb_tlast,
		s_axis_bsb_tready => s_axis_bsb_tready,
		m_axis_bsb_tdata => m_axis_bsb_tdata,
		m_axis_bsb_tvalid => m_axis_bsb_tvalid,
		m_axis_bsb_tlast => m_axis_bsb_tlast,
		m_axis_bsb_tready => m_axis_bsb_tready,
		bsb_clk => bsb_clk,
		bsb_rst => bsb_rst,

		control_bytes     => control_bytes,
		status_bytes      => status_bytes
	);


    -----------------------------------------------------------------------------------
    -- Main process
    -----------------------------------------------------------------------------------
    -- Sends the input data to the FFT input and repackage the FFT output and pass it to the output bus.
    fft_clk_en <= '1'; -- clock is always enabled, as the buffer should always have some data (i.e., data always streaming out)
    main_proc: process(all)
        variable src_lane: integer range 0 to FFT_BINS_PER_WORD-1;
	begin
		if rising_edge(clk) then
			sync_reset <= soft_reset or reset; -- Both reset sources are clk-synchronous

			sync_period_is_zero <= to_std_logic(sync_period=0);

			-- This is set on a TLAST=1, and is not needed until the next TLAST, so they have time to set before then.
			if sync_frame_ctr = (sync_period - 1) then
				is_last_frame_of_sync_period <='1';
			else
				is_last_frame_of_sync_period <='0';
			end if;

			-- Counts the FFT overflows and stop at maximum value, and reset when overflow_reset=1
			-- Parameterization of fft_overflow: check that fft_overflow is not '0' (CHIME) or '00' (D3A/CHORD)
			if overflow_reset='1' then
				overflow_count <= (others=>'0');
			elsif fft_tvalid='1' and fft_clk_en='1' and (fft_overflow='1' or overflow_force='1') and signed(overflow_count)/=-1 then
			-- elsif fft_tvalid='1' and fft_clk_en='1' and (fft_overflow/=(fft_overflow'range => '0') or overflow_force='1') and signed(overflow_count)/=-1 then
				overflow_count <= overflow_count + 1;
			end if;

			-- Keep track of the FFT overflow flag during the frame. Note that
			-- the CASPER fft flag is not necessarily aligned to a frame, so
			-- this info shall be used carefully (maybe invalidate one or more
			-- frames after, and maybe the frame before). Also note that thet
			-- TLAST occurs, we have not yet included the last `fft_overflow` in
			-- `fft_overflow_sticky`; we ned to do that separately.
			if fft_tvalid='1' and fft_clk_en='1' and fft_tlast='1' then
				fft_overflow_sticky <= '0';
				--fft_overflow_sticky_dly <= fft_overflow_sticky_int or fft_overflow;
			elsif fft_tvalid='1' and fft_clk_en='1' and (fft_overflow='1' or overflow_force='1') then
			-- elsif fft_tvalid='1' and fft_clk_en='1' and (fft_overflow/=(fft_overflow'range => '0') or overflow_force='1') then
				fft_overflow_sticky <= '1';
			end if;

			-- Process the input data
			-- fft_in <= in_dat; -- delay the data so it is aligned with the generated sync
			delay_clk_en <= s_axis_in_dat_tvalid; -- enable writing control signals through the delay line
			fft_in_tdata  <= s_axis_in_dat_tdata;
			fft_in_tlast  <= s_axis_in_dat_tlast;
			fft_in_tuser  <= s_axis_in_dat_tuser;

			if s_axis_in_dat_tvalid='1' then
				-- Generate a SYNC pulse every sync_period frames on the last word of the previous frame
				fft_sync_in <= '0'; -- SYNC returns to zero on every valid word so it lasts only one sample. Will be overriden below.
				-- if in_dat.TLAST='1' and sync_period_is_zero='0' then -- if this is the last word of the frame, check if it is time to generate a SYNC pulse
				if s_axis_in_dat_tlast='1' and sync_period_is_zero='0' then
					if  is_last_frame_of_sync_period='1' then -- if maximum count reach, send a sync pulse, otherwise blank it
						sync_frame_ctr <= (others=>'0');
						fft_sync_in <= '1';
					else
						sync_frame_ctr <= sync_frame_ctr + 1;
					end if; -- sync_frame_ctr = max count
				end if; -- TLAST=1
			end if; -- TVALID=1


			-- pipeline the bypass path. It has to go over the whole FFT, which spans the whole width of the FPGA.
			bypass1_tvalid <= s_axis_in_dat_tvalid;
			bypass1_tlast  <= s_axis_in_dat_tlast;
			bypass1_tuser  <= s_axis_in_dat_tuser;
			bypass1_tdata  <= s_axis_in_dat_tdata;

			bypass2_tvalid <= bypass1_tvalid;
			bypass2_tlast  <= bypass1_tlast;
			bypass2_tuser  <= bypass1_tuser;
			bypass2_tdata  <= bypass1_tdata;

            -- Compute rotated FFT output. This involves a large number of 2:1 or 4:1 MUXes depending on the FFT.
            -- We dont want this to be dependent on bypass_fft because it adds an extra mux input and adds combinatorial depth.
            -- Count the words coming out of the FFT
            for i in 0 to FFT_BINS_PER_WORD-1 loop
	            if fft_tvalid and fft_clk_en then
	                word_ctr(i) <= (others => '0') when fft_tlast else word_ctr(i) + 1;
	            end if;
	        end loop;
            -- Assign words to the next pipeline stage, rotating them as necessary if ROTATE_BINS=TRUE
            fft_rot_tvalid <= fft_tvalid and fft_clk_en; -- The FFT outputs valid data only of the FFT is clocked AND the data has gone through the pipeline
            fft_rot_tlast  <= fft_tlast;
            fft_rot_tuser  <= fft_tuser;
			fft_rot_overflow_sticky <= fft_overflow_sticky or overflow_force; -- incorporate last overflow
			if ROTATE_BINS then
	            for i in 0 to FFT_BINS_PER_WORD-1 loop
	                src_lane := (i + to_integer(word_ctr(i))) MOD FFT_BINS_PER_WORD;
	                fft_rot_tdata((i+1)*FFT_BITS_PER_BIN-1 downto i*FFT_BITS_PER_BIN) <= fft_tdata((src_lane+1)*FFT_BITS_PER_BIN -1 downto src_lane*FFT_BITS_PER_BIN);
				end loop; -- if FFT is implemented
			else
				fft_rot_tdata <= fft_tdata;
			end if;

			-- Register the final output. The delay is also used so we can insert the overflow flag on the final word.
			-- Warning: out_dat.TUSER is overriden below - do not move down
			-- SHREG_EXTRACT is set to FALSE to prevent the pipeline with the SCALER input from being turned into a shift register.
			-- out_dat <= out_dat_pre;
			m_axis_out_dat_tvalid <= out_dat_pre_tvalid;
			m_axis_out_dat_tdata  <= out_dat_pre_tdata;
			m_axis_out_dat_tlast  <= out_dat_pre_tlast;
			m_axis_out_dat_tuser  <= (others => '0'); -- overriden below - do not move down
			m_axis_out_dat_tuser(FUNCGEN_TUSER_BITS_PER_WORD-1 downto 0)  <= out_dat_pre_tuser;

			if IMPLEMENT_FFT=TRUE and bypass_fft='0' then -- if the FFT is being used
				-- if the FFT module is present and it is not bypassed by software, pass the FFT output to the output
				out_dat_pre_tvalid <= fft_rot_tvalid; -- The FFT outputs valid data only of the FFT is clocked AND the data has gone through the pipeline
				out_dat_pre_tlast  <= fft_rot_tlast;
				out_dat_pre_tuser  <= fft_rot_tuser;
				out_dat_pre_tdata  <= fft_rot_tdata;
				out_dat_pre_overflow_sticky <= fft_rot_overflow_sticky;
				if out_dat_pre_tlast='1' and out_dat_pre_tvalid='1' then -- if out_data_pre_tvalid then fft_clk_en must also be true
					m_axis_out_dat_tuser(FUNCGEN_TUSER_BITS_PER_WORD) <= out_dat_pre_overflow_sticky; -- set FFT overflow flag
				end if;
			else
				-- otherwise, just pass the input to the output, adapting the data width.
				out_dat_pre_tvalid <= bypass2_tvalid;
				out_dat_pre_tlast  <= bypass2_tlast;
				out_dat_pre_tuser  <= bypass2_tuser;
				out_dat_pre_tdata  <= (others=>'0'); -- all bits are zero by default unless defined below
				for i in 0 to ADC_SAMPLES_PER_WORD-1 loop -- parameterized
					-- Forward the adc word to the *upper* bits of the FFT output word
					out_dat_pre_tdata((i+1)*FFT_BITS_PER_BIN/2-1 downto (i+1)*FFT_BITS_PER_BIN/2 - ADC_BITS_PER_SAMPLE) <= bypass2_tdata((i+1)*ADC_BITS_PER_SAMPLE -1 downto i*ADC_BITS_PER_SAMPLE);
				end loop; -- if FFT is implemented


			end if; -- bypass

			-- Synchronous Resets -- overrides only some of the previously assigned signals
			-- If reset is enabled, the FFT is fed with dummy data and SYNC=1.
			-- When reset is disabled, the FFT is fed with the incoming data and is clocked only if the data is valid.
			-- SYNC is pulsed every N frames afterwards.
			-- Define intermediate signals to simplify the logic
			-- These are needed only at the first TLAST, so they have time to initialize before they are needed. No reset values are necessary.
			if reset then
				sync_frame_ctr <= (others=>'0'); --needed
				overflow_count <= (others=>'0');
				-- Clock the FFT with a SYNC input
				-- fft_in.TVALID <= '0';
				-- fft_in.TDATA <= (others=>'X');
				-- out_dat.TVALID <= '0'; -- needed to make sure we don't send invalid data after reset.
--				fft_in_tvalid <= '0';
				fft_in_tdata <= (others=>'X');
				m_axis_out_dat_tvalid <= '0'; -- needed to make sure we don't send invalid data after reset
				-- fft_clk_en<='1';
				fft_sync_in <= '1';
				delay_clk_en <= '0'; -- don't write anything to the delay line. we don't want the forced SYNC in there
				word_ctr <= (others => (others => '0'));
			end if; -- if RST

		end if; -- clk
	end process;


FFT_GEN: if IMPLEMENT_FFT=TRUE generate

	-----------------------------------------------------------------------------------
	-- PFB/FFT Instance
	-----------------------------------------------------------------------------------
	-- This is a CASPER PFB/FFT generated using Xilinx System Generator
	--
	fftype_gen: case FFT_TYPE generate

		-- -- CHIME PFB/FFT --
		-- Time-based data is presented 4 samples at a time,  in0 being the earliest sample. A time sample is 8 bit wide.
		-- Output is the complex frequency samples (18 bits real + 18 bits imaginary). Out0 and out 1 provide the even and odd
		-- frequencies respectively. The lower (even) bin is in the MSB.
        when CHIME =>
            fft0: entity work.FFT2
                PORT MAP(
                    sync_in  => fft_sync_in,
                    in0      => fft_in_tdata(ADC_BITS_PER_WORD - (ADC_BITS_PER_SAMPLE * 0) - 1 downto ADC_BITS_PER_SAMPLE * 3),
                    in1      => fft_in_tdata(ADC_BITS_PER_WORD - (ADC_BITS_PER_SAMPLE * 1) - 1 downto ADC_BITS_PER_SAMPLE * 2),
                    in2      => fft_in_tdata(ADC_BITS_PER_WORD - (ADC_BITS_PER_SAMPLE * 2) - 1 downto ADC_BITS_PER_SAMPLE * 1),
                    in3      => fft_in_tdata(ADC_BITS_PER_WORD - (ADC_BITS_PER_SAMPLE * 3) - 1 downto ADC_BITS_PER_SAMPLE * 0),

                    sync_out => fft_sync_out,
                    out1     => fft_dout0_int,
                    out2     => fft_dout1_int,

                    shift    => fft_shift_schedule(10 downto 0),
                    overflow => fft_overflow,
                    ce_1     => fft_clk_en,
                    clk_1    => clk
                );

            fft_tdata <= (fft_dout0_int & fft_dout1_int);


        -- -- D3A PFB/FFT --
        -- Time-based data is presented 8 samples at a time, in0 being the earliest sample. A time sample is 14 bits wide.
        -- Output is the complex frequency samples (18 bits real + 18 bits imaginary). out0 is the first frequency bin,
        -- out1 is the next, etc.
        when D3A =>
            fft0: entity work.pfb_fft_d3a_0
                PORT MAP(
                    sync_in(0)  => fft_sync_in,
                    in0      => fft_in_tdata(ADC_BITS_PER_SAMPLE * 8 - 1 downto ADC_BITS_PER_SAMPLE * 7),
                    in1      => fft_in_tdata(ADC_BITS_PER_SAMPLE * 7 - 1 downto ADC_BITS_PER_SAMPLE * 6),
                    in2      => fft_in_tdata(ADC_BITS_PER_SAMPLE * 6 - 1 downto ADC_BITS_PER_SAMPLE * 5),
                    in3      => fft_in_tdata(ADC_BITS_PER_SAMPLE * 5 - 1 downto ADC_BITS_PER_SAMPLE * 4),
                    in4      => fft_in_tdata(ADC_BITS_PER_SAMPLE * 4 - 1 downto ADC_BITS_PER_SAMPLE * 3),
                    in5      => fft_in_tdata(ADC_BITS_PER_SAMPLE * 3 - 1 downto ADC_BITS_PER_SAMPLE * 2),
                    in6      => fft_in_tdata(ADC_BITS_PER_SAMPLE * 2 - 1 downto ADC_BITS_PER_SAMPLE * 1),
                    in7      => fft_in_tdata(ADC_BITS_PER_SAMPLE * 1 - 1 downto ADC_BITS_PER_SAMPLE * 0),

                    sync_out(0) => fft_sync_out,
                    out0     => fft_dout0_int,
                    out1     => fft_dout1_int,
                    out2 	 => fft_dout2_int,
                    out3 	 => fft_dout3_int,

                    shift    => fft_shift_schedule(13 downto 0),
                    of_x0    => fft_overflow_d3a, -- (0 => fft_overflow, others => open),--fixme
                    clk      => clk
                );

            fft_overflow <= or fft_overflow_d3a;
            fft_tdata <= (fft_dout0_int & fft_dout1_int & fft_dout2_int & fft_dout3_int);

        when CHORD =>
    		-- Overflow-free FFT, allowing bitgrowth
            fft0: entity work.pfb_fft_bitgrowth_0
                PORT MAP(
                    sync_in(0)  => fft_sync_in,
                    in0      => fft_in_tdata(ADC_BITS_PER_SAMPLE * 8 - 1 downto ADC_BITS_PER_SAMPLE * 7),
                    in1      => fft_in_tdata(ADC_BITS_PER_SAMPLE * 7 - 1 downto ADC_BITS_PER_SAMPLE * 6),
                    in2      => fft_in_tdata(ADC_BITS_PER_SAMPLE * 6 - 1 downto ADC_BITS_PER_SAMPLE * 5),
                    in3      => fft_in_tdata(ADC_BITS_PER_SAMPLE * 5 - 1 downto ADC_BITS_PER_SAMPLE * 4),
                    in4      => fft_in_tdata(ADC_BITS_PER_SAMPLE * 4 - 1 downto ADC_BITS_PER_SAMPLE * 3),
                    in5      => fft_in_tdata(ADC_BITS_PER_SAMPLE * 3 - 1 downto ADC_BITS_PER_SAMPLE * 2),
                    in6      => fft_in_tdata(ADC_BITS_PER_SAMPLE * 2 - 1 downto ADC_BITS_PER_SAMPLE * 1),
                    in7      => fft_in_tdata(ADC_BITS_PER_SAMPLE * 1 - 1 downto ADC_BITS_PER_SAMPLE * 0),

                    sync_out(0) => fft_sync_out,
                    out0     => fft_dout0_int,
                    out1     => fft_dout1_int,
                    out2 	 => fft_dout2_int,
                    out3 	 => fft_dout3_int,

                    shift    => fft_shift_schedule(13 downto 0),
                    of_x0    => fft_overflow_d3a, -- (0 => fft_overflow, others => open),--fixme
                    clk      => clk
                );

            fft_overflow <= or fft_overflow_d3a;
            fft_tdata <= (fft_dout0_int & fft_dout1_int & fft_dout2_int & fft_dout3_int);

		when HIRAX =>
			-- Same as FFT_TYPE_CHIME, but allows full bitgrowth
			fft0: entity work.hirax_bit_growth_0
                PORT MAP(
                    sync_in(0)  => fft_sync_in,
                    pol_in1      => fft_in_tdata(ADC_BITS_PER_WORD - (ADC_BITS_PER_SAMPLE * 0) - 1 downto ADC_BITS_PER_SAMPLE * 3),
                    pol_in2      => fft_in_tdata(ADC_BITS_PER_WORD - (ADC_BITS_PER_SAMPLE * 1) - 1 downto ADC_BITS_PER_SAMPLE * 2),
                    pol_in3      => fft_in_tdata(ADC_BITS_PER_WORD - (ADC_BITS_PER_SAMPLE * 2) - 1 downto ADC_BITS_PER_SAMPLE * 1),
                    pol_in4      => fft_in_tdata(ADC_BITS_PER_WORD - (ADC_BITS_PER_SAMPLE * 3) - 1 downto ADC_BITS_PER_SAMPLE * 0),

                    sync_out(0) => fft_sync_out,
                    out00    => fft_dout0_int,
                    out01    => fft_dout1_int,

                    shift    => to_slv(0, 11), -- still an input but ignored internally
                    overflow(0) => fft_overflow,
                    -- ce_1     => fft_clk_en,
                    clk    => clk
                );

            fft_tdata <= (fft_dout0_int & fft_dout1_int);

		when HIRAX_3DSP =>
			-- Same as FFT_TYPE_CHIME, but allows bitgrowth limited to 25+25 bits, use 3-DSP complex multipliers, and
			fft0: entity work.hirax_bit_growth_3dsp
                PORT MAP(
                    sync_in(0)  => fft_sync_in,
                    pol_in1      => fft_in_tdata(ADC_BITS_PER_WORD - (ADC_BITS_PER_SAMPLE * 0) - 1 downto ADC_BITS_PER_SAMPLE * 3),
                    pol_in2      => fft_in_tdata(ADC_BITS_PER_WORD - (ADC_BITS_PER_SAMPLE * 1) - 1 downto ADC_BITS_PER_SAMPLE * 2),
                    pol_in3      => fft_in_tdata(ADC_BITS_PER_WORD - (ADC_BITS_PER_SAMPLE * 2) - 1 downto ADC_BITS_PER_SAMPLE * 1),
                    pol_in4      => fft_in_tdata(ADC_BITS_PER_WORD - (ADC_BITS_PER_SAMPLE * 3) - 1 downto ADC_BITS_PER_SAMPLE * 0),

                    sync_out(0) => fft_sync_out,
                    out00    => fft_dout0_int,
                    out01    => fft_dout1_int,

                    shift    => to_slv(0, 11),
                    overflow(0) => fft_overflow,
                    -- ce_1     => fft_clk_en,
                    clk    => clk
                );

            fft_tdata <= (fft_dout0_int & fft_dout1_int);
		when others =>
			assert FALSE report "Invalid FFT Type" severity FAILURE;
	end generate fftype_gen;

	flags_in(FUNCGEN_TUSER_BITS_PER_WORD+1)   <= fft_sync_in;
	flags_in(FUNCGEN_TUSER_BITS_PER_WORD)   <= fft_in_TLAST;
	flags_in(FUNCGEN_TUSER_BITS_PER_WORD-1 downto 0) <= fft_in_TUSER;
	fft_sync_out2 <= flags_out(FUNCGEN_TUSER_BITS_PER_WORD+1); -- for validating proper delay adjustment; should align with fft_sync_out
	fft_tlast     <= flags_out(FUNCGEN_TUSER_BITS_PER_WORD);
	fft_tuser     <= flags_out(FUNCGEN_TUSER_BITS_PER_WORD-1 downto 0);


	-----------------------------------------------------------------------------------
	-- Pipeline Delay measurer/generator
	-----------------------------------------------------------------------------------
	-- Measures the CASPER block pipelining delay and propagate a vector containing the data flags with the same delay
		delay0: entity work.fft_delay
			GENERIC MAP (
				CTR_WIDTH  => fft_pipeline_delay'LENGTH,
				DATA_WIDTH => flags_in'LENGTH
				)

			PORT MAP(
				-- Delay measurement signals
				sync_in        => fft_sync_in, -- SYNC at the input of the FFT
				sync_out       => fft_sync_out, -- SYNC at the output of the FFT
				measured_delay => fft_measured_pipeline_delay, -- Contains the pipeline delay

				-- Delay line
				delay          => fft_pipeline_delay, -- Contains the pipeline delay
				data_in        => flags_in,  -- user data synchronized with the SYNC at the input of the processing block
				data_out       => flags_out, -- user data synchronized with SYNC_OUT and DOUT
				valid          => fft_tvalid,

				clk            => clk,
				ce             => delay_clk_en,
				rst            => sync_reset
			);
end generate FFT_GEN;


end Behavioral;

