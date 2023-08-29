----------------------------------------------------------------------------------
-- @file
-- Company: McGill University, Cosmology Instrumentation Lab
-- Engineer: J.-F. Cliche
--
-- Create Date:    20:34:01 03/26/2011
-- Design Name:     chFPGA
-- Module Name:    FFT - Behavioral
-- Project Name: CHIME
-- Target Devices: Virtex 6
-- Tool versions: ISE 13.4
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

library UNISIM;
use UNISIM.VComponents.all;

--===== ENTITY DECLARATION ======================

-- Wraps a CASPER wideband FFT into a AXI4-STREAMING
-- processing block with a few memory-mapped control registers.
--
-- The FFT input is an non-blocking, AXI4-Streaming bus with 32 bits of data and 4 bits of user-
-- defined bits. The 4 bytes correspond to four 8-bit signed data samples, with the first sample
-- being placed in the most significant byte.
--
-- The FFT is a PFB-FFT from CASPER.  The FFT has a duplex architecture that can process two complex
-- input samples per clock. The FFT is done across frames consisting of 2048 real samples presented
-- as 512 32-bit words. The PFB applies windowing across 4 consecutive frames.

-- Since the input data is real, the negative frequency bins are the
-- complex conjugate of the corresponding positive frequency bins.  The FFT is designed to taka
-- advantage of this, and discards the negative frequencies in exchange of the ability to to process
-- twice as many samples per clock. Overall, the FFT processes 4 real samples per clock.
--
-- The FFT outputs two (18+18) bits complex numbers per clock, for a total of 1024 frequency bins
-- emitted during the 512-clock frame. An Even-numbered and Odd-numbered bin is provided on each
-- clock. Those a re packed onto a 72-bit-wide non-blocking AXI-Streaming bus. The order of the
-- 18-bit signed numbers emitted on each clock is, from MSB to LSB: Re Even, Im Even, Re Odd and Im Odd.
--
-- In BYPASS mode, each of the 8 bit of the input are signed extended to 18 bits and are passed to
-- the output in the same order. The TUSER bits from the input are also passed directly to the output.
--
--
--! Generating the underlying CASPER FFT block
--
--! -------------------------------
--!
--! The following system setup was used:
--!     - Matlab 200Xb
--!     - ISE 12.X
--!     - CASPER libraries 10.X
--!     - Path added to MATLAB:
--!        - mlib_devel_10_X/casper_library
--!
--! Other configurations might work.
--!
--! The CASPER toolset must be open in the Simulink library browser before the FFT model is loaded to force it to re-parse the library
--!
entity FFT is
	generic (
		IMPLEMENT_FFT		   : BOOLEAN := TRUE;
		FFT_TYPE			   : string  := "D3A"; -- tells the entity which experiment-dependent Casper-generated PFB/FFT block to use. Currently accepts "CHIME" or "D3A"
		ADC_BITS_PER_SAMPLE    : integer := 14; -- CHIME: 8 bits, D3A/CHORD: 14 bits
		ADC_SAMPLES_PER_WORD   : integer := 8; -- CHIME: 4, D3A/CHORD: 8
		ADC_BITS_PER_WORD	   : integer := ADC_BITS_PER_SAMPLE * ADC_SAMPLES_PER_WORD;
		FFT_BITS_PER_BIN 	   : integer := 18+18; -- real + imaginary
		FFT_BINS_PER_WORD 	   : integer := 4; -- CHIME: 2, D3A/CHORD: 4
		FFT_BITS_PER_WORD 	   : integer := FFT_BITS_PER_BIN * FFT_BINS_PER_WORD;
		FFT_OVERFLOW_BITLENGTH : integer := 2 -- CHIME: 1, D3A/CHORD: 2. Needed since D3A/CHORD FFT overflow signal is 2 bits for some reason
		);
	port (
		-- I/O interfaces
		--
		-- CHIME: N_bit_in = 32,  N_samp = 4, N_bit_out = 72
		-- D3A:   N_bit_in = 112, N_samp = 8, N_bit_out = 144

		-- Input Interface
		-- Input time stream, implemented as a non-blocking AXI4 Streaming Interface with a N_bit_in-bit data bus.
		-- Each word presents N_samp time samples, where the early sample is in the MSB.
		
		-- in_dat  : in axis32_dat_struct; -- old format using a structure
		
		-- Output Interface
		-- Output spectrum stream, implemented as a non-blocking AXI4 Streaming interface with a N_bit_out-bit bus.
		--
		-- CHIME:
		-- Each N_bit_out-bit word contains two 36-bit complex numbers (18 bit real signed + 18 bit imaginary signed values).
		-- The most significant 36 bits contains the value for the even frequency bins,
		-- while the lower ones is the value for the odd frequency bin.
		-- The Most significant bits of a complex value contains the real part.
		--
		-- D3A:
		-- Each N_bit_out-bit word contains four 36-bit complex numbers (18 bit real signed + 18 bit imaginary signed values).
		-- The most significant 36 bits contains the value for the first (even) frequency bins, the next contains the value for
		-- the following odd bin, etc.
		-- The Most significant bits of a complex value contains the real part.

		-- out_dat : out axis72_dat_struct; -- old

		s_axis_in_dat_tdata    : in std_logic_vector(ADC_BITS_PER_WORD-1 downto 0);
		s_axis_in_dat_tvalid   : in std_logic; 
		s_axis_in_dat_tlast    : in std_logic;
		s_axis_in_dat_tuser    : in std_logic_vector(3 downto 0);

		m_axis_out_dat_tdata   : out std_logic_vector(FFT_BITS_PER_WORD-1 downto 0);
		m_axis_out_dat_tvalid  : out std_logic;
		m_axis_out_dat_tlast   : out std_logic;
		m_axis_out_dat_tuser   : out std_logic_vector(3 downto 0);



		-- Common Clock and Reset
		clk     : in  std_logic; --! Processing clock, common to the input and output bus
		reset   : in  std_logic; --! clk-synchronous Antenna processor reset.
		                         --! In this module, resets the SYNC generator and send SYNC signals to the FFT

		-- Control interface (command and reply stream buses)
		ctrl_cmd_in_dat     : in  AXIS8_DAT_STRUCT;
		ctrl_cmd_in_rdy     : out AXIS8_RDY_STRUCT;
		ctrl_rply_out_dat   : out AXIS8_DAT_STRUCT;
		ctrl_rply_out_rdy   : in  AXIS8_RDY_STRUCT;
		ctrl_clk            : in  std_logic;
		ctrl_rst            : in  std_logic
		);
end FFT;


--------- FFT architecture --------------------
--! Implements the FFT module functionnalities
architecture Behavioral of FFT is


	signal flags_in, flags_out: std_logic_vector(5 downto 0);


	signal fft_pipeline_delay: std_logic_vector(11 downto 0);
	signal fft_measured_pipeline_delay: std_logic_vector(11 downto 0);
	signal sync_reset: std_logic;


	-- FFT block

	signal fft_in_tvalid       : std_logic;
	signal fft_in_tdata        : std_logic_vector(s_axis_in_dat_tdata'RANGE);
	signal fft_in_tlast        : std_logic;
	signal fft_in_tuser        : std_logic_vector(3 downto 0);

	signal out_dat_pre_tvalid  : std_logic;
	signal out_dat_pre_tdata   : std_logic_vector(m_axis_out_dat_tdata'RANGE);
	signal out_dat_pre_tlast   : std_logic;
	signal out_dat_pre_tuser   : std_logic_vector(3 downto 0);

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
	-- signal fft_overflow: std_logic := '0';
	signal fft_overflow: std_logic_vector(FFT_OVERFLOW_BITLENGTH-1 downto 0) := (others=>'0');
	signal fft_overflow_sticky: std_logic;
	signal fft_overflow_sticky_dly: std_logic;
	signal fft_tuser: std_logic_vector(m_axis_out_dat_tuser'RANGE);
	signal fft_tlast: std_logic;
	signal fft_tvalid: std_logic;

	--- Define Control word and its signals
	signal control_bytes: slv8_array(0 to 6);
	signal status_bytes: slv8_array(0 to 2);

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

begin

-----------------------------------------------------------------------------------
-- CONTROL and STATUS Bytes
-----------------------------------------------------------------------------------
--! \addtogroup memory_map
--! FFT Module Memory Map
--!
--!  ------------------------------------------------------------------------------
--! |  Page   | Addr|Bit(s)|     Name             | Description                   |
--! |---------|-----|------|----------------------|-------------------------------|
--! | CONTROL |  0  | 7    | soft_reset           | Reset the block. Also reset the computation of the CASPER block pipelining delay. When released, the block will compute the block latency once a CASPER SYNC has passed through the block and make the result available.|
--! |         |     | 6:4  |  Unused              |                               |
--! |         |     |  3   | overflow_force       | Forces the overflow flag to 1. Used for testing. |
--! |         |     |  2   | overflow_reset       | Resets the overflow counter   |
--! |         |     |  1   | Unused               |                               |
--! |         |     |  0   | bypass_fft           | Bypass the FFT                |
--! |         | 1:2 | 15:0 | fft_shift_schedule   | Sets the shifting schedule through the FFT to prevent overflow. Bit 0 specifies the behavior of stage 0, bit 1 of stage 1, and so on. |
--! |         | 3:4 | 15:0 | sync_period          | Number of clock cycles between SYNC pulses. If zero, no SYNC pulses are generated. See CASPER documentation for minimum SYNC spacing. |
--! |         | 5:6 | 15:0 | fft_pipeline_delay   | Latency (in number of clocks) of the CASPER PFB/FFT. This is used to delay the input flags that accompany the data fed into the FFT so they come out aligned with the FFT output. This should be the values measured by fft_measured_pipeline_delay. |
--! | STATUS  | 0:1 | 15:0 | fft_measured_pipeline_delay   | Measured latency (in number of clocks) of the CASPER PFB/FFT. This is updated when a reset is performed |
--! |         |  2  |  7:0 | overflow_count       | Number of FFT overflows since reset (rolls back) |
--!  ------------------------------------------------------------------------------
--!

-- CONTROL Byte 0
soft_reset <= control_bytes(0)(7);
overflow_reset <= control_bytes(0)(2);
overflow_force <= control_bytes(0)(3);
bypass_fft <= control_bytes(0)(0); --!

--! CONTROL Byte 1-2
fft_shift_schedule <= to_slv(control_bytes(1 to 2),fft_shift_schedule'LENGTH); --Sets the shifting schedule through the FFT to prevent overflow. Bit 0 specifies the behavior of stage 0, bit 1 of stage 1, and so on.

-- CONTROL Bytes 3-4
sync_period <= to_unsigned(control_bytes(3 to 4));

-- CONTROL Bytes 5-6
fft_pipeline_delay <= to_slv(control_bytes(5 to 6),fft_pipeline_delay'LENGTH);

-- STATUS Byte 0-1
status_bytes(0 to 1) <= ("0000" & fft_measured_pipeline_delay(11 downto 8), fft_measured_pipeline_delay(7 downto 0));

-- STATUS Byte 2
status_bytes(2) <= std_logic_vector(overflow_count);

-----------------------------------------------------------------------------------
-- Memory-Mapped interface
-----------------------------------------------------------------------------------
--! Instantiates a memory-mapped interface to the control and status bytes
CTRL_SLAVE0: entity work.CTRL_SLAVE
	GENERIC MAP (
		NUMBER_OF_CONTROL_BYTES => control_bytes'LENGTH(1), -- Number of bits in the control word
		NUMBER_OF_STATUS_BYTES  => status_bytes'LENGTH(1), -- Number of bits in the status word.
		DEFAULT_CONTROL_BYTES   => X"00_03FF_0000_0C9E" -- default values.
	)

	PORT MAP(
		-- Control interface (command and reply stream buses)
		ctrl_cmd_in_dat   => ctrl_cmd_in_dat,
		ctrl_cmd_in_rdy   => ctrl_cmd_in_rdy,
		ctrl_rply_out_dat => ctrl_rply_out_dat,
		ctrl_rply_out_rdy => ctrl_rply_out_rdy,
		ctrl_clk          => ctrl_clk,
		ctrl_rst          => ctrl_rst,

		control_bytes     => control_bytes,
		status_bytes      => status_bytes
	);


-----------------------------------------------------------------------------------
-- Main process
-----------------------------------------------------------------------------------
--! Sends the input data to the FFT input and repackage the FFT output and pass it to the output bus.
fft_clk_en <= '1'; -- clock is always enabled, as the buffer should always have some data (i.e., data always streaming out)
main_proc: process(clk)
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
			-- elsif fft_tvalid='1' and fft_clk_en='1' and (fft_overflow='1' or overflow_force='1') and signed(overflow_count)/=-1 then
			elsif fft_tvalid='1' and fft_clk_en='1' and (fft_overflow/=(fft_overflow'range => '0') or overflow_force='1') and signed(overflow_count)/=-1 then
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
			-- elsif fft_tvalid='1' and fft_clk_en='1' and (fft_overflow='1' or overflow_force='1') then
			elsif fft_tvalid='1' and fft_clk_en='1' and (fft_overflow/=(fft_overflow'range => '0') or overflow_force='1') then
				fft_overflow_sticky <= '1';
			end if;

			-- Process the input data
			-- fft_in <= in_dat; -- delay the data so it is aligned with the generated sync
--			fft_in_tvalid <= s_axis_in_dat_tvalid;
			fft_in_tdata  <= s_axis_in_dat_tdata;
			fft_in_tlast  <= s_axis_in_dat_tlast;
			fft_in_tuser  <= s_axis_in_dat_tuser;
			-- fft_clk_en   <= in_dat.TVALID; -- enable passing the valid data into the FFT
			-- delay_clk_en <= in_dat.TVALID; -- enable writing control signals through the delay line
			delay_clk_en <= s_axis_in_dat_tvalid; -- enable writing control signals through the delay line

			-- if in_dat.TVALID='1' then
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

			-- Register the final output. The delay is also used so we can insert the overflow flag on the final word.
			-- Warning: out_dat.TUSER is overriden below - do not move down
			-- SHREG_EXTRACT is set to FALSE to prevent the pipeline with the SCALER input from being turned into a shift register.
			-- out_dat <= out_dat_pre;
			m_axis_out_dat_tvalid <= out_dat_pre_tvalid;
			m_axis_out_dat_tdata  <= out_dat_pre_tdata;
			m_axis_out_dat_tlast  <= out_dat_pre_tlast;
			m_axis_out_dat_tuser  <= out_dat_pre_tuser;

			if IMPLEMENT_FFT=TRUE and bypass_fft='0' then -- if the FFT is being used
				-- if the FFT module is present and it is not bypassed by software, pass the FFT output to the output
				-- out_dat_pre.TVALID <= fft_tvalid and fft_clk_en; -- The FFT outputs valid data only of the FFT is clocked AND the data has gone through the pipeline
				-- out_dat_pre.TLAST <= fft_tlast;
				-- out_dat_pre.TUSER <= fft_tuser;
				-- out_dat_pre.TDATA <= fft_tdata;
				out_dat_pre_tvalid <= fft_tvalid and fft_clk_en; -- The FFT outputs valid data only of the FFT is clocked AND the data has gone through the pipeline
				out_dat_pre_tlast  <= fft_tlast;
				out_dat_pre_tuser  <= fft_tuser;
				out_dat_pre_tdata  <= fft_tdata;

				-- Insert the FFT overflow flag in the next_to_last Serial flag bit
				if fft_tlast='1' and fft_tvalid='1' and fft_clk_en='1' then
					-- out_dat.TUSER(TUSER_SERIAL_FLAGS_BIT) <= fft_overflow_sticky or fft_overflow or overflow_force; -- add the FFT overflow flag, including the one on TLAST
					m_axis_out_dat_tuser(TUSER_SERIAL_FLAGS_BIT) <= fft_overflow_sticky or overflow_force; 
				end if;
			else
				-- otherwise, just pass the input to the output, adapting the data width.
				-- out_dat_pre.TVALID <= in_dat.TVALID;
				-- out_dat_pre.TLAST <= in_dat.TLAST;
				-- out_dat_pre.TUSER <= in_dat.TUSER;
				-- out_dat_pre.TDATA <= (others=>'0'); -- all bits are dezo by default unless defined below
				out_dat_pre_tvalid <= s_axis_in_dat_tvalid;
				out_dat_pre_tlast  <= s_axis_in_dat_tlast;
				out_dat_pre_tuser  <= s_axis_in_dat_tuser;
				out_dat_pre_tdata  <= (others=>'0'); -- all bits are dezo by default unless defined below
				-- for i in 0 to 3 loop
				for i in 0 to ADC_SAMPLES_PER_WORD-1 loop -- parameterized
					-- out_dat_pre.TDATA(18*i+17 downto 18*i) <= std_logic_vector(resize(signed(in_dat.TDATA(8*i+7 downto 8*i)), 18)); -- make sure to sign extend the byte to the full 18 bits
					out_dat_pre_tdata(18*i+17 downto 18*i) <= std_logic_vector(resize(signed(s_axis_in_dat_tdata(ADC_BITS_PER_SAMPLE*i+(ADC_BITS_PER_SAMPLE - 1) downto ADC_BITS_PER_SAMPLE*i)), 18));
				end loop; -- if FFT is implemented

			end if;

			-- Synchronous Resets -- overrides only some of the previously assigned signals
			-- If reset is enabled, the FFT is fed with dummy data and SYNC=1.
			-- When reset is disabled, the FFT is fed with the incoming data and is clocked only if the data is valid.
			-- SYNC is pulsed every N frames afterwards.
			-- Define intermediate signals to simplify the logic
			-- These are needed only at the first TLAST, so they have time to initialize before they are needed. No reset values are necessary.
			if reset='1' then
				sync_frame_ctr <= (others=>'0'); --needed
				overflow_count <= (others=>'0');
				-- Clock the FFT with a SYNC input
				-- fft_in.TVALID <= '0';
				-- fft_in.TDATA <= (others=>'X');
				-- out_dat.TVALID <= '0'; --! needed to make sure we don't send invalid data after reset.
--				fft_in_tvalid <= '0';
				fft_in_tdata <= (others=>'X');
				m_axis_out_dat_tvalid <= '0'; -- needed to make sure we don't send invalid data after reset
				-- fft_clk_en<='1';
				fft_sync_in <= '1';
				delay_clk_en <= '0'; -- don't write anything to the delay line. we don't want the forced SYNC in there
			end if; -- if RST

		end if; -- clk
	end process;


FFT_GEN: if IMPLEMENT_FFT=TRUE generate

	-----------------------------------------------------------------------------------
	-- PFB/FFT Instance
	-----------------------------------------------------------------------------------
	-- This is a CASPER PFB/FFT generated using Xilinx System Generator
	--
	-- -- CHIME PFB/FFT --
	-- Time-based data is presented 4 samples at a time,  in0 being the earliest sample. A time sample is 8 bit wide.
	-- Output is the complex frequency samples (18 bits real + 18 bits imaginary). Out0 and out 1 provide the even and odd 
	-- frequencies respectively. The upper
	
	fftype_gen: if FFT_TYPE = "CHIME" generate
	
		FFT0: entity work.FFT2
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
	
	elsif FFT_TYPE = "D3A" generate
		FFT0: entity work.pfb_fft_d3a_0
			PORT MAP(
				sync_in(0)  => fft_sync_in,
				in0      => fft_in_tdata(ADC_BITS_PER_WORD - (ADC_BITS_PER_SAMPLE * 0) - 1 downto ADC_BITS_PER_SAMPLE * 7),
				in1      => fft_in_tdata(ADC_BITS_PER_WORD - (ADC_BITS_PER_SAMPLE * 1) - 1 downto ADC_BITS_PER_SAMPLE * 6),
				in2      => fft_in_tdata(ADC_BITS_PER_WORD - (ADC_BITS_PER_SAMPLE * 2) - 1 downto ADC_BITS_PER_SAMPLE * 5),
				in3      => fft_in_tdata(ADC_BITS_PER_WORD - (ADC_BITS_PER_SAMPLE * 3) - 1 downto ADC_BITS_PER_SAMPLE * 4),
				in4      => fft_in_tdata(ADC_BITS_PER_WORD - (ADC_BITS_PER_SAMPLE * 4) - 1 downto ADC_BITS_PER_SAMPLE * 3),
				in5      => fft_in_tdata(ADC_BITS_PER_WORD - (ADC_BITS_PER_SAMPLE * 5) - 1 downto ADC_BITS_PER_SAMPLE * 2),
				in6      => fft_in_tdata(ADC_BITS_PER_WORD - (ADC_BITS_PER_SAMPLE * 6) - 1 downto ADC_BITS_PER_SAMPLE * 1),
				in7      => fft_in_tdata(ADC_BITS_PER_WORD - (ADC_BITS_PER_SAMPLE * 7) - 1 downto ADC_BITS_PER_SAMPLE * 0),

				sync_out(0) => fft_sync_out,
				out0     => fft_dout0_int,
				out1     => fft_dout1_int,
				out2 	 => fft_dout2_int,
				out3 	 => fft_dout3_int,

				shift    => fft_shift_schedule(13 downto 0),
--				of_x0 => (0 => fft_overflow, others => open),--fixme
				clk    => clk
			);
--        fft_overflow <= '0';
		fft_tdata <= (fft_dout0_int & fft_dout1_int & fft_dout2_int & fft_dout3_int);

	end generate fftype_gen;

	-- -- Pass the FFT CE signal through a BUFH to avoid the signal to be replicated a large number of times to meet timing.
	-- fft_ce_bufh : BUFH
	--  port map (
	--      I => fft_clk_en,
	--      O => fft_clk_en_buf
	--  );

	--  sync_reset <= soft_reset;

	flags_in(5)   <= fft_sync_in;
	flags_in(4)   <= fft_in_TLAST;
	flags_in(3 downto 0) <= fft_in_TUSER;
	fft_sync_out2 <= flags_out(5); -- for validating proper delay adjustment; should align with fft_sync_out
	fft_tlast     <= flags_out(4);
	fft_tuser     <= flags_out(3 downto 0);


	-----------------------------------------------------------------------------------
	-- Pipeline Delay measurer/generator
	-----------------------------------------------------------------------------------
	--! Measures the CASPER block pipelining delay and propagate a vector containing the data flags with the same delay
		DELAY0: entity work.FFT_DELAY
			GENERIC MAP (
				CTR_WIDTH  => fft_pipeline_delay'Length,
				DATA_WIDTH => flags_in' Length
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

