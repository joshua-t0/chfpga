----------------------------------------------------------------------------------
-- Company: McGill University
-- Engineer: J.-F. Cliche
--
-- Create Date: 2016
-- Design Name: chFPGA
-- Module Name: CMAC44 - Behavioral
-- Project Name: Suitcase Interferometer
-- Target Devices: 7 Series
-- Tool versions: Vivado 2016.4
-- Description: Implements a compact (4+4) bit complex multiplier/accumulator
--
-- Dependencies:
--
-- Revision:
--
-- Additional Comments:
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.math_complex.ALL;

library work;
use work.chFPGA_Package.all;

library UNISIM;
use UNISIM.VComponents.all;
library UNIMACRO;
use unimacro.Vcomponents.all;


-- ----------------------------------
-- CMAC44: (4+4) bit complex vector multiplier-and-accumulate core
-- ----------------------------------
-- Casadable, compact (4+4) bit 512-element complex vector
-- multiplier/accumulator that uses two DSP48E1 and two RAMB16 blocks.
--
-- The input stream consist of a pair of (4+4) bit complex value presented on
-- each clock on its 16-bit input data bus. Each pair in a frame is multiplied
-- and accumulated in a separate memory location. Up to 512 separate products
-- can be stored.
--
-- The data is accumulated in a FIFO as a saturated (18+18) bit value. ! When
-- the `last_frame` flag is set, the final accumulated values are transferred
-- in a BRAM readout ! buffer and are read slowly through a 36-bit bus while
-- another integration in is progress. A readout input port allows the CMACs
-- to be connected in a readout chain.
--
--
-- See the Entity architecture for more implementation details.
entity CMAC44 is
	GENERIC (
		PLATFORM_ID: integer;
		RPM_NAME: string; -- name of the RPM set name that identify which correlator the DSPs and BRAMs belong to.
		RPM_COORDS: cmac44_rpm_coord_struct; -- RPM coordinates of the DSPs and BRAMs
		DSP_RPM_X: integer := 45; -- X coordinate for both DSP1 and DSP2. They are on top of each other, in the same tile.
		BRAM_RPM_X: integer := 34; -- X coordinate of BRAM/FIFO. They also are on top of each other, in the same tile.
		DSP_RPM_Y0: integer := 0; -- Y coordinate of bottom DSP (DSP1)
		DSP_RPM_Y1: integer := 0; -- Y coordinate of top DSP (DSP2)
		BRAM_RPM_Y0: integer := 0; -- Y coordinate of bottom BRAM (Accumulator FIFO)
		BRAM_RPM_Y1: integer := 0 -- Y coordinate of top BRAM (Capture BRAM)
		);
	PORT(

		-- Input X & Y streams to be multiplied/accumulated. AXI4-Streaming, non-blocking.

		s_axis_xy_tvalid: in std_logic;
		s_axis_xy_tlast: in std_logic;
		s_axis_xy_last_frame: in std_logic; -- Is high during all VALID words of the last frame to be integrated
		s_axis_xy_tdata: in std_logic_vector(15 downto 0); -- Contains both (4+4) bit complex numbers to be multiplied together.  x_re:x_im:y_re:y_im
		s_axis_xy_xconj: in std_logic := '0'; -- when '1', uses the complex conjugate of the x input
		s_axis_xy_yconj: in std_logic := '0'; -- when '1', uses the complex conjugate of the y input


		-- Data output from this CMAC

		m_axis_z_out_tdata: out std_logic_vector(35 downto 0);
		m_axis_z_out_tlast: out std_logic;
		m_axis_z_out_tvalid: out std_logic := '0'; -- for sims
		m_axis_z_out_start: in std_logic := '0';
		m_axis_z_out_send: in std_logic := '1'; -- Tells this CMAC to start or stop sending data as soon as possible (i.e. after the latency of the control/data pipeline). This is **not** the AXI-S tready, which acts immediately.
		m_axis_z_out_local_data: out std_logic := '0'; -- '1': data is coming from this CMAC, '0': data is coming from the daisy-chained CMAC.

		-- Data input from the neighboring CMAC

		s_axis_z_in_tdata: in std_logic_vector(35 downto 0) := (others=>'0');
		s_axis_z_in_tlast: in std_logic := '0';
		s_axis_z_in_tvalid: in std_logic := '0';
		s_axis_z_in_send: out std_logic := '0'; -- Tells the next node it should start or stop sending data as soon as possible
		s_axis_z_in_start: out std_logic;

		-- Debugging outputs
		no_accum: in std_logic := '0';
		-- re: out signed(17 downto 0);
		-- im: out signed(17 downto 0);
		re2: out signed(17 downto 0);
		im2: out signed(17 downto 0);
		rd_err: out std_logic;
		wr_err: out std_logic;
		readout_err: out std_logic;

		clk : in std_logic; -- clock
		rst : in std_logic -- rst

		);

end CMAC44;

-- @brief Implementation of the compact (4+4) bit complex multiplier/accumulator.
--
-- The complex multiplier/accumulator (CMAC) takes advantage of the small bit width if the incoming
-- complex number (4-bit real, 4-bit imaginary) to implement a full complex multiplier, accumulator
-- and readout buffer using two DSP48 and two RAMB18K and a very small amount of logic and routing
-- resources. The CMAC does not require external memory. Many tricks have been used to use the various features and operation modes of the DSP
-- block to minimize the use of fabric logic (such as fabric-based adders) and maximize speed.
-- Since the two DSP and RAM blocks use the same amount of space in an FPGA column, the CMAC can be
-- packed very densely and efficiently in the FPGA.
--
-- Only one RAMB18K is used as an accumulator, which means we can accumulate the complex product
-- into up to 512 distinct (18+18) complex values. This ultimately sets the limit on how long the
-- products can be integrated before they need to be sent out to prevent saturation. This buffer is
-- implemented as a FIFO, which uses the embedded FIFO hardware associated with a pair of RAMB18K
-- block (i.e. a RAMB36K ), so we do not use fabric resources to implement address counters etc.
--
-- A separate RAMB18K is used as a capture buffer to store the final sums at the end of the
-- integration period and allow the data to be trickled down through the comm link without
-- interrupting the integration of the next frame (i.e no dead time). It is assumed that the
-- integration period is long enough so that the data can be sent out before a new integration period
-- starts. The capture buffer has the same geometry as the accumulator. It is implemented as a BRAM,
-- not a FIFO, since the FIFO embedded logic is used by the accumulator FIFO. The read logic is
-- simplified compared to a ful-fledged FIFO in order to reduce the logic count.
--
--
-- Readout logic
-- -------------
--
-- The CMAC output is meant to be daisy-chained with other CMACs in order to stream the captured
-- accumulated products of all the units in the chain. Once the first unit of the chain has sent its data, the data
-- from the second CMAC is passed through the first one, and so on. This ensures that the routing needed to readout all the CMACs stays local.
--
-- Each CMAC has a `send` signal both on the upstream and downstram side to allow some degree of flow
-- control. On the downstream side, the `send` signal indicates a CMAC can send its data, or , when it is finished, it's neighbor's data.
-- The upstram `send` signal is enabled when the CMAC has finished sending its data to tells the neighbor that it can send its own data.
--
-- The `send` signal **does not** behave exactly as a AXI-S tREADY signal, which
-- *instantaneously* starts or stop data transfer. Implementing this behaviour in a daisy-chained (and
-- pipelined) data path involves more complex logic and data buffering to deal with data that
-- was sent based on delayed tready signal but can no longer be immediately accepted it when it
-- arrives at the sink.
--
-- Instead, the `send_in` signal is an instruction to start and stop sending data "as soon as
-- possible", meaning that  the data flow can start and stop some time after the signal is asserted.
-- This allows time for the `send_in` signal to propagate up to the targeted data source and for the
-- data to propagate back down through its pipeline stages. In other word, the `send` signal will
-- take effect only after the control and data pipeline latency.
--
-- Using such a *lazy* flow control scheme greatly simplifies the logic and storage requirements
-- (i.e flops) in each and every of the CMAC modules. However, an elastic buffer with sufficient
-- capacity is required at the end of the readout module to accomodate the time lag between the flow
-- control instruction and the actual effect of the flow. Since  we need to have a FIFO anyways to
-- cope with data width conversion and clock domain crossing, and that FIFO is needed only once
-- for every group of daisy-chained CMAC blocks, the resource usage is totally acceptable.
--
--
architecture Behavioral of CMAC44 is


signal rst_reg: std_logic;

signal dsp1_a: std_logic_vector(29 downto 0);
signal dsp1_b: std_logic_vector(17 downto 0);
signal dsp1_c: std_logic_vector(47 downto 0);
-- signal dsp1_c_dly: std_logic_vector(47 downto 0);
signal dsp1_p: std_logic_vector(47 downto 0);
signal dsp1_pcout: std_logic_vector(47 downto 0);
signal dsp1_alumode: std_logic_vector(3 downto 0);
signal dsp1_cin: std_logic;


signal dsp2_ab: std_logic_vector(47 downto 0);
signal dsp2_c: std_logic_vector(47 downto 0);
signal dsp2_p: std_logic_vector(47 downto 0);
signal dsp2_cin: std_logic;
signal dsp2_opmode: std_logic_vector(6 downto 0);
signal dsp2_c_im_sign3: std_logic;
signal dsp2_c_im_sign4: std_logic;
signal dsp2_c_re_sign3: std_logic;
signal dsp2_c_re_sign4: std_logic;
signal im_sat3: std_logic;
signal re_sat3: std_logic;
signal im_sat4: std_logic;
signal re_sat4: std_logic;
signal dsp2_ab_im_sign4: std_logic;

signal a: signed(3 downto 0); --
signal b: signed(3 downto 0); --
signal c: signed(3 downto 0); --
signal d: signed(3 downto 0); --

signal a1: unsigned(3 downto 0); -- ranges from 0 to 8
signal b1: signed(4 downto 0); -- ranges from -8 to 8
signal c1: unsigned(3 downto 0); -- ranges from 0 to 8
signal d1: signed(4 downto 0); -- ranges from -8 to 8
signal a1_zero: std_logic;
signal b1_zero: std_logic;
signal c1_zero: std_logic;
signal d1_zero: std_logic;
signal b1_neg: std_logic;
signal d1_neg: std_logic;
signal neg1: std_logic;

signal acc_fifo_dout: std_logic_vector(35 downto 0);
signal acc_fifo_din: std_logic_vector(35 downto 0);
signal acc_fifo_wr_en: std_logic :='0';
signal acc_fifo_rd_en: std_logic :='0';
signal acc_fifo_full: std_logic;
signal acc_fifo_dout_complex: complex;
signal acc_fifo_din_complex: complex;
signal acc_fifo_rderr: std_logic;
signal acc_fifo_wrerr: std_logic;
signal acc_fifo_empty: std_logic;
signal acc_fifo_wrcount: std_logic_vector(12 downto 0) := (others =>'0'); -- for sims: make sure MSB is set to zero if we don't assign it
signal acc_fifo_rdcount: std_logic_vector(12 downto 0) := (others =>'0');
signal acc_fifo_rd_error: std_logic;
signal acc_fifo_wr_error: std_logic;


signal capture_addr4: unsigned(8 downto 0):=(others=>'1');
signal capture_dout6: std_logic_vector(35 downto 0);
signal capture_wr_en4: std_logic:='0';
signal capture_rd_en4, capture_rd_en5, capture_rd_en6: std_logic:='0';
signal capture_wr_en_vect: std_logic_vector(0 downto 0):="0";

signal tvalid1, tvalid2, tvalid3, tvalid4: std_logic:='0';
signal tlast1, tlast2, tlast3: std_logic;
signal last_frame1, last_frame2, last_frame3: std_logic;
signal tfirst3: std_logic :='1';
signal first_frame_completed0: std_logic :='0'; --init needed
signal first_frame_completed1: std_logic :='0'; --init needed
signal first_frame_completed2: std_logic :='0'; --init needed
signal first_frame2: std_logic :='1'; --init needed
signal readout_enable4, readout_enable5, readout_enable6: std_logic := '0';
signal send: std_logic := '0';
signal started: std_logic := '0';
signal m_axis_z_out_start_dly: std_logic := '1';

-- Relative Placed Macro constraints

attribute RPM_GRID : string;
attribute RLOC : string;
--attribute HU_SET : string;
attribute U_SET : string;
attribute RLOC_ORIGIN : string;
attribute KEEP_HIERARCHY : string;
--attribute HU_SET : string;
--constant DSP_LEFT: boolean := FALSE;
--constant DSP1_RLOC: string := sel(DSP_LEFT, "X65Y0", "X45Y0");
--constant FIFO_RLOC: string := sel(DSP_LEFT, "X78Y0", "X34Y0");
--constant BRAM_RLOC: string := sel(DSP_LEFT, "X78Y1", "X34Y1");

-- Get the FPGA series for this platform so we can chose which DSP primitive to use
constant FPGA_SERIES:integer := PLATFORM_INFO(PLATFORM_ID).FPGA_SERIES;

-- DSP & BRAM vertical spacing in RPM coordinates for this platform
attribute KEEP_HIERARCHY of Behavioral: architecture is "YES";
--attribute RLOC_ORIGIN of Behavioral: architecture is ORIGIN;

begin

-- First DSP: Implements the multiplier with correction factors, which yields the ac, (ad-bc) and bd terms in its output registers.
-- a and c are assumed to be unsigned. Corrections are applied by the adder to compensate for overlaps between the bd and (ad-bc) terms. results are presented on the P and PC (calcaded P)  ports.
blkdsp: block
	--attribute U_SET of dsp1, dsp2 : label is "CORR" & integer'IMAGE(CORR_NUMBER);
	attribute RPM_GRID of dsp1: label is "GRID";  -- coordinates in unit of RPM_X and RPM_Y. All element sin the same group will automatically use that grid.
	attribute U_SET of dsp1, dsp2 : label is RPM_NAME;
	attribute RLOC of dsp1: label is rpm_to_string(RPM_COORDS.DSP1);
	attribute RLOC of dsp2: label is rpm_to_string(RPM_COORDS.DSP2);
begin
	dsp1 : DSP48E1
		generic map (
			-- Feature Control Attributes: Data Path Selection
			A_INPUT            => "DIRECT", -- Selects A input source, "DIRECT" (A port) or "CASCADE" (ACIN port)
			B_INPUT            => "DIRECT", -- Selects B input source, "DIRECT" (B port) or "CASCADE" (BCIN port)
			USE_DPORT          => FALSE, -- Select D port usage (TRUE or FALSE)
			USE_MULT           => "MULTIPLY", -- Select multiplier usage ("MULTIPLY", "DYNAMIC", or "NONE")
			USE_SIMD           => "ONE48", -- SIMD selection ("ONE48", "TWO24", "FOUR12")
			-- Pattern Detector Attributes: Pattern Detection Configuration
			AUTORESET_PATDET   => "NO_RESET", -- "NO_RESET", "RESET_MATCH", "RESET_NOT_MATCH"
			MASK               => X"3fffffffffff", -- 48-bit mask value for pattern detect (1=ignore)
			PATTERN            => X"000000000000", -- 48-bit pattern match for pattern detect
			SEL_MASK           => "MASK", -- "C", "MASK", "ROUNDING_MODE1", "ROUNDING_MODE2"
			SEL_PATTERN        => "PATTERN", -- Select pattern value ("PATTERN" or "C")
			USE_PATTERN_DETECT => "NO_PATDET", -- Enable pattern detect ("PATDET" or "NO_PATDET")
			-- Register Control Attributes: Pipeline Register Configuration
			ACASCREG           => 1, -- Number of pipeline stages between A/ACIN and ACOUT (0, 1 or 2)
			ADREG              => 1, -- Number of pipeline stages for pre-adder (0 or 1)
			ALUMODEREG         => 1, -- Number of pipeline stages for ALUMODE (0 or 1)
			AREG               => 1, -- Number of pipeline stages for A (0, 1 or 2)
			BCASCREG           => 1, -- Number of pipeline stages between B/BCIN and BCOUT (0, 1 or 2)
			BREG               => 1, -- Number of pipeline stages for B (0, 1 or 2)
			CARRYINREG         => 1, -- Number of pipeline stages for CARRYIN (0 or 1)
			CARRYINSELREG      => 1, -- Number of pipeline stages for CARRYINSEL (0 or 1)
			CREG               => 1, -- Number of pipeline stages for C (0 or 1)
			DREG               => 1, -- Number of pipeline stages for D (0 or 1)
			INMODEREG          => 1, -- Number of pipeline stages for INMODE (0 or 1)
			MREG               => 1, -- Number of multiplier pipeline stages (0 or 1)
			OPMODEREG          => 1, -- Number of pipeline stages for OPMODE (0 or 1)
			PREG               => 1 -- Number of pipeline stages for P (0 or 1)
		)
		port map (
			-- Cascade: 30-bit (each) output: Cascade Ports
			ACOUT          => open, -- 30-bit output: A port cascade output
			BCOUT          => open, -- 18-bit output: B port cascade output
			CARRYCASCOUT   => open, -- 1-bit output: Cascade carry output
			MULTSIGNOUT    => open, -- 1-bit output: Multiplier sign cascade output
			PCOUT          => dsp1_pcout, -- 48-bit output: Cascade output
			P              => dsp1_p, -- 48-bit output: Primary data output
			-- Control: 1-bit (each) output: Control Inputs/Status Bits
			OVERFLOW       => open, -- 1-bit output: Overflow in add/acc output
			PATTERNBDETECT => open, -- 1-bit output: Pattern bar detect output
			PATTERNDETECT  => open, -- 1-bit output: Pattern detect output
			UNDERFLOW      => open, -- 1-bit output: Underflow in add/acc output
			-- Data: 4-bit (each) output: Data Ports
			CARRYOUT       => open, -- 4-bit output: Carry output
			-- Cascade: 30-bit (each) input: Cascade Ports
			ACIN           => (others=> '0'), -- 30-bit input: A cascade data input
			BCIN           => (others=> '0'), -- 18-bit input: B cascade input
			CARRYCASCIN    => '0', -- 1-bit input: Cascade carry input
			MULTSIGNIN     => '0', -- 1-bit input: Multiplier sign input
			PCIN           => (others=> '0'), -- 48-bit input: P cascade input
			-- Control: 4-bit (each) input: Control Inputs/Status Bits
			ALUMODE        => dsp1_alumode, -- 4-bit input: ALU control input
			CARRYINSEL     => "000", -- 3-bit input: Carry select input
			CLK            => clk, -- 1-bit input: Clock input
			INMODE         => "00000", -- 5-bit input: INMODE control input
			OPMODE         => "0110101", -- 7-bit input: Operation mode input, X/Y=M, P=C
			-- Data: 30-bit (each) input: Data Ports
			A              => dsp1_a, -- 30-bit input: A data input
			B              => dsp1_b, -- 18-bit input: B data input
			C              => dsp1_c, -- 48-bit input: C data input
			CARRYIN        => dsp1_cin, -- 1-bit input: Carry input signal
			D              => (others=> '0'), -- 25-bit input: D data input
			-- Reset/Clock Enable: 1-bit (each) input: Reset/Clock Enable Inputs
			CEA1           => '1', -- 1-bit input: Clock enable input for 1st stage AREG
			CEA2           => '1', -- 1-bit input: Clock enable input for 2nd stage AREG
			CEAD           => '0', -- 1-bit input: Clock enable input for ADREG
			CEALUMODE      => '1', -- 1-bit input: Clock enable input for ALUMODE
			CEB1           => '1', -- 1-bit input: Clock enable input for 1st stage BREG
			CEB2           => '1', -- 1-bit input: Clock enable input for 2nd stage BREG
			CEC            => '1', -- 1-bit input: Clock enable input for CREG
			CECARRYIN      => '1', -- 1-bit input: Clock enable input for CARRYINREG
			CECTRL         => '1', -- 1-bit input: Clock enable input for OPMODEREG and CARRYINSELREG
			CED            => '0', -- 1-bit input: Clock enable input for DREG
			CEINMODE       => '1', -- 1-bit input: Clock enable input for INMODEREG
			CEM            => '1', -- 1-bit input: Clock enable input for MREG
			CEP            => '1', -- 1-bit input: Clock enable input for PREG
			RSTA           => '0', -- 1-bit input: Reset input for AREG
			RSTALLCARRYIN  => '0', -- 1-bit input: Reset input for CARRYINREG
			RSTALUMODE     => '0', -- 1-bit input: Reset input for ALUMODEREG
			RSTB           => '0', -- 1-bit input: Reset input for BREG
			RSTC           => '0', -- 1-bit input: Reset input for CREG
			RSTCTRL        => '0', -- 1-bit input: Reset input for OPMODEREG and CARRYINSELREG
			RSTD           => '0', -- 1-bit input: Reset input for DREG and ADREG
			RSTINMODE      => '0', -- 1-bit input: Reset input for INMODEREG
			RSTM           => '0', -- 1-bit input: Reset input for MREG
			RSTP           => '0' -- 1-bit input: Reset input for PREG
		);

	-- Second DSP: sums the ad and bd terms, and adds the accumulator output to the (ac+bd) and (ad-bc)
	-- terms, with guard bits to allow for overflow detection.
	dsp2 : DSP48E1
		generic map (
			-- Feature Control Attributes: Data Path Selection
			A_INPUT            => "DIRECT", -- Selects A input source, "DIRECT" (A port) or "CASCADE" (ACIN port)
			B_INPUT            => "DIRECT", -- Selects B input source, "DIRECT" (B port) or "CASCADE" (BCIN port)
			USE_DPORT          => FALSE, -- Select D port usage (TRUE or FALSE)
			USE_MULT           => "MULTIPLY", -- Select multiplier usage ("MULTIPLY", "DYNAMIC", or "NONE")
			USE_SIMD           => "ONE48", -- SIMD selection ("ONE48", "TWO24", "FOUR12")
			-- Pattern Detector Attributes: Pattern Detection Configuration
			AUTORESET_PATDET   => "NO_RESET", -- "NO_RESET", "RESET_MATCH", "RESET_NOT_MATCH"
			MASK               => X"3fffffffffff", -- 48-bit mask value for pattern detect (1=ignore)
			PATTERN            => X"000000000000", -- 48-bit pattern match for pattern detect
			SEL_MASK           => "MASK", -- "C", "MASK", "ROUNDING_MODE1", "ROUNDING_MODE2"
			SEL_PATTERN        => "PATTERN", -- Select pattern value ("PATTERN" or "C")
			USE_PATTERN_DETECT => "NO_PATDET", -- Enable pattern detect ("PATDET" or "NO_PATDET")
			-- Register Control Attributes: Pipeline Register Configuration
			ACASCREG           => 0, -- Number of pipeline stages between A/ACIN and ACOUT (0, 1 or 2)
			ADREG              => 1, -- Number of pipeline stages for pre-adder (0 or 1)
			ALUMODEREG         => 1, -- Number of pipeline stages for ALUMODE (0 or 1)
			AREG               => 0, -- Number of pipeline stages for A (0, 1 or 2)
			BCASCREG           => 0, -- Number of pipeline stages between B/BCIN and BCOUT (0, 1 or 2)
			BREG               => 0, -- Number of pipeline stages for B (0, 1 or 2)
			CARRYINREG         => 1, -- Number of pipeline stages for CARRYIN (0 or 1)
			CARRYINSELREG      => 1, -- Number of pipeline stages for CARRYINSEL (0 or 1)
			CREG               => 1, -- Number of pipeline stages for C (0 or 1)
			DREG               => 1, -- Number of pipeline stages for D (0 or 1)
			INMODEREG          => 1, -- Number of pipeline stages for INMODE (0 or 1)
			MREG               => 1, -- Number of multiplier pipeline stages (0 or 1)
			OPMODEREG          => 1, -- Number of pipeline stages for OPMODE (0 or 1)
			PREG               => 1 -- Number of pipeline stages for P (0 or 1)
		)
		port map (
			-- Cascade: 30-bit (each) output: Cascade Ports
			ACOUT          => open, -- 30-bit output: A port cascade output
			BCOUT          => open, -- 18-bit output: B port cascade output
			CARRYCASCOUT   => open, -- 1-bit output: Cascade carry output
			MULTSIGNOUT    => open, -- 1-bit output: Multiplier sign cascade output
			PCOUT          => open, -- 48-bit output: Cascade output
			P              => dsp2_p, -- 48-bit output: Primary data output
			-- Control: 1-bit (each) output: Control Inputs/Status Bits
			OVERFLOW       => open, -- 1-bit output: Overflow in add/acc output
			PATTERNBDETECT => open, -- 1-bit output: Pattern bar detect output
			PATTERNDETECT  => open, -- 1-bit output: Pattern detect output
			UNDERFLOW      => open, -- 1-bit output: Underflow in add/acc output
			-- Data: 4-bit (each) output: Data Ports
			CARRYOUT       => open, -- 4-bit output: Carry output
			-- Cascade: 30-bit (each) input: Cascade Ports
			ACIN           => (others=> '0'), -- 30-bit input: A cascade data input
			BCIN           => (others=> '0'), -- 18-bit input: B cascade input
			CARRYCASCIN    => '0', -- 1-bit input: Cascade carry input
			MULTSIGNIN     => '0', -- 1-bit input: Multiplier sign input
			PCIN           => dsp1_pcout, -- 48-bit input: P cascade input
			-- Control: 4-bit (each) input: Control Inputs/Status Bits
			ALUMODE        => "0001", -- 4-bit input: ALU control input:
			CARRYINSEL     => "000", -- 3-bit input: Carry select input
			CLK            => clk, -- 1-bit input: Clock input
			INMODE         => "00000", -- 5-bit input: INMODE control input
			OPMODE         => dsp2_opmode, -- 7-bit input: Operation mode input
			-- Data: 30-bit (each) input: Data Ports
			A              => dsp2_ab(47 downto 18), -- 30-bit input: A data input
			B              => dsp2_ab(17 downto 0), -- 18-bit input: B data input
			C              => dsp2_c, -- 48-bit input: C data input
			CARRYIN        => dsp2_cin, -- 1-bit input: Carry input signal
			D              => (others=> '0'), -- 25-bit input: D data input
			-- Reset/Clock Enable: 1-bit (each) input: Reset/Clock Enable Inputs
			CEA1           => '0', -- 1-bit input: Clock enable input for 1st stage AREG
			CEA2           => '0', -- 1-bit input: Clock enable input for 2nd stage AREG
			CEAD           => '0', -- 1-bit input: Clock enable input for ADREG
			CEALUMODE      => '1', -- 1-bit input: Clock enable input for ALUMODE
			CEB1           => '0', -- 1-bit input: Clock enable input for 1st stage BREG
			CEB2           => '0', -- 1-bit input: Clock enable input for 2nd stage BREG
			CEC            => '1', -- 1-bit input: Clock enable input for CREG
			CECARRYIN      => '1', -- 1-bit input: Clock enable input for CARRYINREG
			CECTRL         => '1', -- 1-bit input: Clock enable input for OPMODEREG and CARRYINSELREG
			CED            => '0', -- 1-bit input: Clock enable input for DREG
			CEINMODE       => '1', -- 1-bit input: Clock enable input for INMODEREG
			CEM            => '1', -- 1-bit input: Clock enable input for MREG
			CEP            => '1', -- 1-bit input: Clock enable input for PREG
			RSTA           => '0', -- 1-bit input: Reset input for AREG
			RSTALLCARRYIN  => '0', -- 1-bit input: Reset input for CARRYINREG
			RSTALUMODE     => '0', -- 1-bit input: Reset input for ALUMODEREG
			RSTB           => '0', -- 1-bit input: Reset input for BREG
			RSTC           => '0', -- 1-bit input: Reset input for CREG
			RSTCTRL        => '0', -- 1-bit input: Reset input for OPMODEREG and CARRYINSELREG
			RSTD           => '0', -- 1-bit input: Reset input for DREG and ADREG
			RSTINMODE      => '0', -- 1-bit input: Reset input for INMODEREG
			RSTM           => '0', -- 1-bit input: Reset input for MREG
			RSTP           => '0' -- 1-bit input: Reset input for PREG
		);
end block;

-- Accumulator FIFO
--
--acc_fifo0: entity work.CMAC44_ACC_FIFO
--  PORT MAP (
--	clk      => clk,
--	rst      => '0',
--	din      => acc_fifo_din,
--	wr_en    => acc_fifo_wr_en,
--	rd_en    => acc_fifo_rd_en,
--	dout     => acc_fifo_dout,
--	full     => open,
--	overflow => open,
--	empty    => open,
--	valid    => open
--  );

acc_fifo_wr_en <= tvalid4 and not rst_reg;
acc_fifo_rd_en <= first_frame_completed0 and s_axis_xy_tvalid and not rst_reg; -- EN_SYN=1, FWFT=0
--acc_fifo_rd_en <= first_frame_completed1 and tvalid1 and not rst_reg; -- EN_SYN=0, FWFT=0
--acc_fifo_rd_en <= first_frame_completed2 and tvalid2 and not rst_reg; -- EN_SYN=0, FWFT=1

--acc_fifo_dout_complex <= CMPLX(signed(acc_fifo_dout(35 downto 18)), signed(acc_fifo_dout(17 downto 0)));
--acc_fifo_din_complex <= CMPLX(signed(acc_fifo_din(35 downto 18)), signed(acc_fifo_din(17 downto 0)));

--acc_fifo0 : FIFO_SYNC_MACRO
--	generic map (
--		DEVICE              => "7SERIES", -- Target Device: "VIRTEX5, "VIRTEX6", "7SERIES"
--		ALMOST_FULL_OFFSET  => X"0080", -- Sets almost full threshold
--		ALMOST_EMPTY_OFFSET => X"0080", -- Sets the almost empty threshold
--		DATA_WIDTH          => 36, -- Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
--		FIFO_SIZE           => "18Kb" -- Target BRAM, "18Kb" or "36Kb"
--		)
--	port map (
--		--ALMOSTEMPTY => ALMOSTEMPTY, -- 1-bit output almost empty
--		--ALMOSTFULL  => ALMOSTFULL, -- 1-bit output almost full
--		DO            => acc_fifo_dout, -- Output data, width defined by DATA_WIDTH parameter
--		--EMPTY       => EMPTY, -- 1-bit output empty
--		--FULL        => FULL, -- 1-bit output full
--		--RDCOUNT     => RDCOUNT, -- Output read count, width determined by FIFO depth
--		--RDERR       => RDERR, -- 1-bit output read error
--		--WRCOUNT     => WRCOUNT, -- Output write count, width determined by FIFO depth
--		--WRERR       => WRERR, -- 1-bit output write error
--		CLK           => clk, -- 1-bit input clock
--		DI            => acc_fifo_din, -- Input data, width defined by DATA_WIDTH parameter
--		RDEN          => acc_fifo_rd_en, -- 1-bit input read enable
--		RST           => '0', -- 1-bit input reset
--		WREN          => acc_fifo_wr_en -- 1-bit input write enable
--	);

-- ----------------------------------------
-- Accumulator FIFO
-- ----------------------------------------
-- The accumulator FIFO is part of the vector accumulator and stores the gradually accumulating products generated by the multiplier-and-accumulate logic.
--
-- The FIFO is used as a circular buffer: the previous accumulated product is
-- poped out of the FIFO as the newly accumulated one is pushed in. The final
-- product of the integration period is not stored in the accumulator FIFO bus
-- is stored in the capture memory, which will be read out slowly as the FIFO
-- starts a new integration period.
--
-- The cumulated products are stored in (36+36i) format, which is the maximum
-- width of a single FIFOs primitime, and is just about enough to allow for a
-- sufficiently long integration.
--
-- A built-in FIFO is used to save resources. This means that the other RAMB18 in the tile cannot be used as a FIFO.
-- The FIFO is 36-bit word x 512 words deep, is *NOT* FWFT and has an embedded output register (DO_REG=1).
--
-- The embedded register greatly improves clock-to-output timing (0.6 ns instead of 1.8 ns). We need this.
-- If the FIFO is configured as a synchronous FIFO (EN_SYN=TRUE), then the additional register would cause the read layency to be 2 clocks, but there would be no uncertainties in the flags.
-- When we use it as an asynchronous FIFO (EN_SYN=FALSE) with RD and WR clocks tied together, we have only one clock read latency but the flags are less accurate.
-- Since we don't need the flags, we'll use the async FIFO to get a 1 clock read latency.
-- (i.e. data appears on the clock after rd_en is high).
--
-- *** to Update*** We do not need a FWFT FIFO because we know one clock in advance when we need a new value out of the FIFO.
--
-- NOTE: When EN_SYN=TRUE, then FWFT *must* be FALSE.
gen_fifo7: if FPGA_SERIES=FPGA_KINTEX7 generate
	attribute U_SET of acc_fifo0: label is RPM_NAME;
	attribute RLOC of acc_fifo0: label is rpm_to_string(RPM_COORDS.FIFO);
begin
	acc_fifo0 : FIFO18E1
		generic map (
			ALMOST_EMPTY_OFFSET     => X"0080", -- Sets the almost empty threshold
			ALMOST_FULL_OFFSET      => X"0080", -- Sets almost full threshold
			DATA_WIDTH              => 36, -- Sets data width to 4-36
			DO_REG                  => 1, -- Enable output register (1-0) Must be 1 if EN_SYN = FALSE.
			EN_SYN                  => TRUE, -- Specifies FIFO as dual-clock (FALSE) or Synchronous (TRUE).
			FIFO_MODE               => "FIFO18_36", -- Sets mode to FIFO18 or FIFO18_36
			FIRST_WORD_FALL_THROUGH => FALSE, -- Sets the FIFO FWFT to FALSE, TRUE. Must be FALSE when EN_SYN=TRUE.
			INIT                    => X"000000000", -- Initial values on output port
			SIM_DEVICE              => "7SERIES", -- Must be set to "7SERIES" for simulation behavior
			SRVAL                   => X"000000000" -- Set/Reset value for output port
		)
		port map (
			-- Read Data: 32-bit (each) output: Read output data
			DO          => acc_fifo_dout(31 downto 0), -- 32-bit output: Data output
			DOP         => acc_fifo_dout(35 downto 32), -- 4-bit output: Parity data output
			-- Read Control Signals: 1-bit (each) input: Read clock, enable and reset input signals
			RDCLK       => clk, -- 1-bit input: Read clock
			RDEN        => acc_fifo_rd_en, -- 1-bit input: Read enable
			REGCE       => '1', -- 1-bit input: Clock enable
			RST         => rst_reg, -- 1-bit input: Asynchronous Reset
			RSTREG      => '0', -- 1-bit input: Output register set/reset
			-- Write Control Signals: 1-bit (each) input: Write clock and enable input signals
			WRCLK       => clk, -- 1-bit input: Write clock
			WREN        => acc_fifo_wr_en, -- 1-bit input: Write enable
			FULL        => acc_fifo_full,
			RDERR => acc_fifo_rderr,
			WRERR => acc_fifo_wrerr,
			EMPTY => acc_fifo_empty,
			WRCOUNT => acc_fifo_wrcount(11 downto 0),
			RDCOUNT => acc_fifo_rdcount(11 downto 0),
			-- Write Data: 32-bit (each) input: Write input data
			DI          => acc_fifo_din(31 downto 0), -- 32-bit input: Data input
			DIP         => acc_fifo_din(35 downto 32) -- 4-bit input: Parity input
		);
end generate;

gen_fifoup: if FPGA_SERIES=FPGA_ULTRASCALEPLUS generate
	attribute U_SET of acc_fifo0 : label is RPM_NAME;
	attribute RLOC of acc_fifo0: label is rpm_to_string(RPM_COORDS.FIFO);
begin
	acc_fifo0 : FIFO18E2
		generic map (
			CLOCK_DOMAINS => "COMMON", -- common clock / synchronous FIFO
			PROG_EMPTY_THRESH     => 128, -- Sets the almost empty threshold
			PROG_FULL_THRESH      => 128, -- Sets almost full threshold
			READ_WIDTH              => 36, -- Sets data width to 4-36
			WRITE_WIDTH              => 36, -- Sets data width to 4-36
			--REGISTER_MODE         => "REGISTERED", -- Output is registered as part of the FIFO, and does not add additional latency.
			REGISTER_MODE         => "DO_PIPELINED", -- Output is registered as a pipeline register, with an additional latency. We need this latency to be compatible with the 7-series FIFOE1 in synchronous mode with output register.
			FIRST_WORD_FALL_THROUGH => "FALSE", -- Sets the FIFO FWFT to FALSE, TRUE. Must be FALSE when EN_SYN=TRUE.
			INIT                    => X"000000000", -- Initial values on output port
			SRVAL                   => X"000000000" -- Set/Reset value for output port
		)
		port map (
			CASDIN => (others => '0'),
			CASDINP => (others => '0'),
			casdomux => '0',
			casdomuxen => '0',
			casnxtrden => '0',
			casoregimux => '0',
			casoregimuxen => '0',
			casprvempty => '0',

			-- Read Data: 32-bit (each) output: Read output data
			DOUT          => acc_fifo_dout(31 downto 0), -- 32-bit output: Data output
			DOUTP         => acc_fifo_dout(35 downto 32), -- 4-bit output: Parity data output
			-- Read Control Signals: 1-bit (each) input: Read clock, enable and reset input signals
			RDCLK       => clk, -- 1-bit input: Read clock
			RDEN        => acc_fifo_rd_en, -- 1-bit input: Read enable
			REGCE       => '1', -- 1-bit input: Clock enable
			RST         => rst_reg, -- 1-bit input: Asynchronous Reset
			RSTREG      => '0', -- 1-bit input: Output register set/reset
			SLEEP => '0',
			-- Write Control Signals: 1-bit (each) input: Write clock and enable input signals
			WRCLK       => clk, -- 1-bit input: Write clock
			WREN        => acc_fifo_wr_en, -- 1-bit input: Write enable
			FULL        => acc_fifo_full,
			RDERR => acc_fifo_rderr,
			WRERR => acc_fifo_wrerr,
			EMPTY => acc_fifo_empty,
			WRCOUNT => acc_fifo_wrcount,
			RDCOUNT => acc_fifo_rdcount,
			-- Write Data: 32-bit (each) input: Write input data
			DIN          => acc_fifo_din(31 downto 0), -- 32-bit input: Data input
			DINP         => acc_fifo_din(35 downto 32) -- 4-bit input: Parity input
		);
end generate;


capture_wr_en_vect <= (others=> capture_wr_en4);

-- ----------------------------------------
-- Data capture BRAM
-- ----------------------------------------
--
-- 512 words x 36 bits (18+18)
-- We do not use a FIFO, as the embedded FIFO logic is already used and we do not need a full-fledged FIFO which uses more resources.
-- We use the output registers to improve logic.
-- Data shows at the output 2 clocks after the address is applied.
--capture_bram0 : entity work.CMAC44_CAPTURE_BRAM
--  PORT MAP (
--    clka => clk,
--    wea => capture_wr_en_vect,
--    regcea => capture_reg_en,
--    addra => std_logic_vector(capture_addr4(8 downto 0)),
--    dina => acc_fifo_din,
--    douta => capture_dout6
--  );
blkbram: block
	attribute U_SET of capture_bram0: label is RPM_NAME;
	attribute RLOC of capture_bram0: label is rpm_to_string(RPM_COORDS.BRAM);
begin
	capture_bram0 : RAMB18E1
		generic map (
			-- Address Collision Mode: "PERFORMANCE" or "DELAYED_WRITE"
			RDADDR_COLLISION_HWCONFIG => "DELAYED_WRITE",
			-- Collision check: Values ("ALL", "WARNING_ONLY", "GENERATE_X_ONLY" or "NONE")
			SIM_COLLISION_CHECK       => "ALL",
			-- DOA_REG, DOB_REG: Optional output register (0 or 1)
			DOA_REG                   => 1,
			DOB_REG                   => 1,
			RAM_MODE                  => "TDP", -- RAM Mode: "SDP" or "TDP" . We use TDP because we need
												-- output regs on both A and B ports, but we wire the
												-- buses as a SDP memory
			-- READ_WIDTH_A/B, WRITE_WIDTH_A/B: Read/write width per port
			READ_WIDTH_A              => 18, -- 0-72
			READ_WIDTH_B              => 18, -- 0-18
			WRITE_WIDTH_A             => 18, -- 0-18
			WRITE_WIDTH_B             => 18, -- 0-72
			-- RSTREG_PRIORITY_A, RSTREG_PRIORITY_B: Reset or enable priority ("RSTREG" or "REGCE")
			RSTREG_PRIORITY_A         => "REGCE",
			RSTREG_PRIORITY_B         => "REGCE",
			-- SRVAL_A, SRVAL_B: Set/reset value for output
			SRVAL_A                   => X"00000",
			SRVAL_B                   => X"00000",
			-- Simulation Device: Must be set to "7SERIES" for simulation behavior
			SIM_DEVICE                => "7SERIES",
			-- WriteMode: Value on output upon a write ("WRITE_FIRST", "READ_FIRST", or "NO_CHANGE")
			WRITE_MODE_A              => "WRITE_FIRST",
			WRITE_MODE_B              => "WRITE_FIRST"
		)
		port map (
			DOADO            => capture_dout6(15 downto 0), -- 16-bit output: A port data/LSB data
			DOPADOP          => capture_dout6(17 downto 16), -- 2-bit output: A port parity/LSB parity
			DOBDO            => capture_dout6(33 downto 18), -- 16-bit output: B port data/MSB data
			DOPBDOP          => capture_dout6(35 downto 34), -- 2-bit output: B port parity/MSB parity
			-- Port A Address/Control Signals: 14-bit (each) input: Port A address and control signals (read port
			-- when RAM_MODE ="SDP")
			ADDRARDADDR(13 downto 5)      => std_logic_vector(capture_addr4), -- 14-bit input: A port address/Read address
			ADDRARDADDR(4 downto 0)      => "00000",
			ADDRBWRADDR(13 downto 5)      => std_logic_vector(capture_addr4), -- 14-bit input: B port address/Write address
			ADDRBWRADDR(4 downto 0)      => "10000",

			ENARDEN          => '1', -- 1-bit input: A port enable/Read enable
			ENBWREN          => '1', -- 1-bit input: B port enable/Write enable

			REGCEAREGCE      => '1', -- 1-bit input: A port register enable/Register enable
			REGCEB           => '1', -- 1-bit input: B port register enable



			DIADI            => acc_fifo_din(15 downto 0), -- 16-bit input: A port data/LSB data
			DIPADIP          => acc_fifo_din(17 downto 16), -- 2-bit input: A port parity/LSB parity
			DIBDI            => acc_fifo_din(33 downto 18), -- 16-bit input: B port data/MSB data
			DIPBDIP          => acc_fifo_din(35 downto 34), -- 2-bit input: B port parity/MSB parity

			WEA               => (others=> capture_wr_en4), -- 2-bit input: A port write enable
			WEBWE(3 downto 2) => "00", -- 4-bit input: B port write enable/Write enable
			WEBWE(1 downto 0) => (others=> capture_wr_en4),

			CLKARDCLK        => clk, -- 1-bit input: A port clock/Read clock
			CLKBWRCLK        => clk, -- 1-bit input: B port clock/Write clock

			RSTRAMARSTRAM    => '0', -- 1-bit input: A port set/reset
			RSTREGARSTREG    => '0', -- 1-bit input: A port register set/reset
			RSTRAMB          => '0', -- 1-bit input: B port set/reset
			RSTREGB          => '0' -- 1-bit input: B port register set/reset
		);
end block;

-- Extract a,b,c and d from the AXI4-S input word. These are all 4-bit signed values. This does not require any logic.
a <= signed(s_axis_xy_tdata(15 downto 12));
b <= signed(s_axis_xy_tdata(11 downto 8));
c <= signed(s_axis_xy_tdata(7 downto 4));
d <= signed(s_axis_xy_tdata(3 downto 0));


-- Make sure that a and c are always positive. If a was negative and is negated, then negate b so
-- the entire complex value (a+jb) is negated. Likewise, if c is negated, negate d as well. We will
-- invert the sign of the product if either one of a or b was negated (see the neg1 flag)
--
-- Since the second dsp inverts the real part of the result (we get (bd-ad) instead of (ad-bd)), we
-- will compute instead -(*X)(*Y) = -(a-jb)(c-jd) = -((ac-bd)+j(-ad-bc)) = (bd-ac)+j(ad+bc), which,
-- after the dsp2 stage, will yield (ac-bd)+j(ad+bc). We therefore take the complex conjugate of X
-- and Y (i.e invert the sign of b and d), and we will invert the neg1 flag.
--
-- The signs of b and d can also be inverted individually to allow the user to use the complex
-- conjugate of either X and Y.
--
-- a1 & c1 are 4 bit unsigned values since they store positive values from 0 to 8.
-- b1 & d1 are 5 bit signed values since they store signed values from -8 to 8.
-- The negation operations involves some combinatorial logic, which is not too costly here because we operate on 4-bit values.

a1 <= unsigned(-a) when a(3)='1' else unsigned(a); -- 4-bit unsigned (0-8)
b1 <= -resize(b,5) when (a(3) xor s_axis_xy_xconj)='0' else resize(b,5); -- use conjugate if a was NOT inverted or if requested
c1 <= unsigned(-c) when c(3)='1' else unsigned(c); -- 4-bit unsigned (0-8)
d1 <= -resize(d,5) when (c(3) xor s_axis_xy_yconj) ='0' else resize(d,5); -- use conjugate if a was NOT inverted or if requested

-- Pack a1, b1, c1 and d1 into the A and B port of the first DSP
-- b1 and d1 are sign-entended to 9 bits, a1 and c1 are sign-extended to the left (all zeros since always positive)
-- we have a combinatorial 4-bit negater between the module input and the DSP.

dsp1_a <= "0000000000000" & std_logic_vector(a1) & "0000" & std_logic_vector(resize(b1, 9));
dsp1_b <= "0" & std_logic_vector(c1) & "0000" & std_logic_vector(resize(d1, 9));

-- The XY products contain:
-- b1*d1:  products spans 17:0, bits 17:13 nulled by correction, bits 12:8 unused, final product in 7:0 ( 8 bits)
-- (ad+bc): product spans 23:13, +1 added if negated, final product in 21:13 (9 bits)
-- a1*c1: product spans 47:26, correction applied to set 47:45 to '1', final product in 44:26 (19 bits)
--
-- In summary:
--     dsp1_p (48 bits) = [111][ac, 19 bits][xxxx][ad+bc, 9 bits][xxxxx][bd, 8 bits]
--------------------------------------------



-- Corrections for overlaps and to negate values. This imply some combinatorial logic between registered signals and the dsp1_c input.


-- No need to correct the lower b1*d1
dsp1_c(12 downto 0) <= (others=>'0');

-- Compute correction in C port to compensate for the b*d product overlap with ad+bc (all ones), and to add 1 to ad+bc if we negate
dsp1_c(18 downto 13) <= "100000" when b1_neg='1' and d1_neg='1' and neg1='1' else --# correct for bd/im overlap and add 1 to negate im. No carry proparates from negating bd because bd!=0
                        "011111" when b1_neg='1' and d1_neg='1' and neg1='0' else --# correct for bd/im overlap. We don't negate so no need to add 1.
                        "000001" when b1_zero='0' and d1_zero='0' and neg1='1' else -- # There is no bd overlap, so no correction for this. But add 1 to im to negate if there is no carry from bd while negating.
                        "000000";-- no correction needed
dsp1_c(25 downto 19) <= (others=>'0');
-- Add one to ac if we negate and if we don't have a carry from (ab+bc) that does that for us
dsp1_c(26) <= '1' when neg1='1' and ((a1_zero='0' and d1_zero='0') or (b1_zero='0' and c1_zero='0')) else --# add 1 to ac if im is not zero
              '0';
dsp1_c(44 downto 27) <= (others=>'0');

-- Set upper msbs to '111' to prepare for the following accumulation
dsp1_c(47 downto 45) <= "001" when neg1='0' else -- 000-001=111
                        "111" when (a1_zero='1' or c1_zero='1') else -- neg=1 and ac=0, cancel the carry
                        "000"; --- neg=1, we already have 111, do nothing

-- dsp1_c(45) <= neg1;
-- dsp1_c(47 downto 46) <= (others=>'0');


-- Set ALUMODE and CIN so we negate (X+Y) if neg=1.
dsp1_alumode <= "0011" when neg1='1' else  -- p = corr - (p + 0) = corr-p ,  P = Z-(X+Y+CIN)
                "0001"; --p = ~corr + (p + 1) = p-corr # P = ~Z+(X+Y+CIN)
dsp1_cin <= not neg1; -- adds one to ~bd so we don't have to include this 'one' to the dsp1_c correction

-- We bypass the DSP2 multiplier, and we bring the 48-bit AB signal directly to the adder
-- The AB=X signal of DSP2 is composed of slices of the P (fabric) output of DSP1.
-- The Y signal of the DSP2 adder is the DSP2 C input (the accumulator output)
-- The Z input of the adder of DSP2 is the cascaded link between DSP1 (PC) shifted right by 17 bits

dsp2_ab(47 downto 30) <= std_logic_vector(resize(signed(dsp1_p(13 + 9 - 1 downto 13)), 18)); -- im=ac-bd, dsp1_p(21 downto 13) (9 bits wide), casted into 19 bits wide, p[21] copied 10 times,
dsp2_ab(29 downto 28) <= "00"; -- guard bit, prevents the sum of re part from overflowing in the im part
dsp2_ab(27 downto 9) <= std_logic_vector(resize(signed(dsp1_p(7 downto 0)), 19)); -- bd
dsp2_ab(8 downto 0) <= dsp1_p(25 downto 17);

-- AB = ((im & 0x7FFFF) << 29) | (( bin_to_int(p, 8) & 0x7FFFF)<<9) |(bit(p, 25) << 8)  # im, 9 bits, sign extended to 19 bits, in AB[47:29]. bd, 8 bits, is sign extended to 19 bits and is in AB[27:9].
-- dsp2_c(47 downto 29) <= (others=>'0'); -- im
dsp2_c(47 downto 30) <= acc_fifo_dout(17 downto 0); -- im
dsp2_c(29 downto 28) <= "00"; -- guard bit
dsp2_c(27) <= acc_fifo_dout(35);
dsp2_c(26 downto 9) <= acc_fifo_dout(35 downto 18); -- im
dsp2_c(8 downto 0) <= (others=>'0');
dsp2_cin <= '1';
dsp2_opmode <= "1010011" when first_frame2='1' or no_accum='1' else --X=A:B, Y=0, Z=PCIN>>17
               "1011111"; --X=A:B, Y=C, Z=PCIN>>17

-----------------------------------------------
-- Saturate accumulated sum before storing it into the FIFO
-- This implies combinatorial logic between the DSP P output and the FIFO/BRAM inputs
acc_fifo_din(35 downto 18) <= -- Real part
	"011111111111111111" when (re_sat4='1' and dsp2_c_re_sign4='0') or (dsp2_p(26)='1' and dsp2_p(27)='0') else
	"100000000000000000" when (re_sat4='1' and dsp2_c_re_sign4='1') or (dsp2_p(26)='0' and dsp2_p(27)='1') else
	dsp2_p(26 downto 9);

acc_fifo_din(17 downto 0) <= -- Imaginary part
	"011111111111111111" when (im_sat4='1' and dsp2_c_im_sign4='0') or (dsp2_c_im_sign4='0' and dsp2_ab_im_sign4='0' and dsp2_p(47)='1') else
	"100000000000000000" when (im_sat4='1' and dsp2_c_im_sign4='1') or (dsp2_c_im_sign4='1' and dsp2_ab_im_sign4='1' and dsp2_p(47)='0') else
	dsp2_p(47 downto 30);




-- Debugging signals

-- re <= signed(dsp2_p(33 downto 17));
-- im <= signed(dsp2_p(16 downto 0));

-- acc_re <= signed(capture_dout(17 downto 0));
-- acc_im <= signed(capture_dout(35 downto 18));

-- z <= capture_dout;

im2 <= signed(dsp2_p(47 downto 30));
re2 <= signed(dsp2_p(26 downto 9));
-- re2 <= (others=>'0');
-- im2 <= (others=>'0');

-- (a+jb)(c+jd) = (ac-bd) + j(ad+bc)
-- if a<0, A=-a, then:
-- =(-Ac-bd) + j(

-- capture_dump_done <= capture_addr4(capture_addr4'HIGH);

--ready <= '1' when (m_axis_z_out_tvalid='0' or m_axis_z_out_tready='1') and last_byte='1' and (z_in_done='1' or CASCADED=FALSE) else '0';

rd_err <= acc_fifo_rd_error;
wr_err <= acc_fifo_wr_error;

main: process(CLK)

	begin
		if rising_edge(CLK) then
			rst_reg <= rst;

			-- FIFO sticky error flags
			if acc_fifo_rderr='1' then
				acc_fifo_rd_error <= '1';
			end if;

			if acc_fifo_wrerr='1' then
				acc_fifo_wr_error <= '1';
			end if;

			if rst_reg='1' then
				acc_fifo_rd_error <= '0';
				acc_fifo_wr_error <= '0';
			end if;

			if s_axis_xy_tvalid='1' and s_axis_xy_tlast='1' then
				first_frame_completed0 <= '1';
			end if;

			-- Reset overrides
			if rst_reg = '1' then
				first_frame_completed0 <= '0';
			end if;


			-------------
			-- STAGE 1 - sign-corrected data is clocked into the DSP1 A & B registers, and we register sign and zero flags
			-------------

			-- We need to compensate for these sign inversions so the result have the correct sign
			-- z = (Sa*a*Sc*c - Sa*b*Sc*d) + j(Sa*a*Sc*d + Sa*b*Sc*c) = SaSc(ac-bd) + jSaSc(ad+bc) = SaSc[(ac-bd) +j(ad+bc)]
			-- if both a and c are positive (Sa=Sc=1), nothing is negated, and the result has the right sign
			-- if both a and c are negative (Sa=Sc=-1), all of a,b,c and c are therefore negated, so the result has the right sign. No need to invert the result.
			-- if either a or c is negative Sa=1 & Sc=-1 or Sa=-1 and Sc=1, then we need to invert the result.
			-- neg indicates whether this sign inversion is needed. The inversion will be done by the DSP ALU unit if needed.
			--
			-- Also, to compensate for the sign inversion of the real part of the result, we actually compute -(*X)(*Y).
			-- We therefore invert to negate signal the result.
			b1_neg <= b1(4);
			d1_neg <= d1(4);
			neg1 <= not (a(3) xor c(3));

			-- x = A | B
			-- y = C | D
			-- P = AC | AD+BC | BD
			a1_zero <= to_std_logic(a=0);
			b1_zero <= to_std_logic(b=0);
			c1_zero <= to_std_logic(c=0);
			d1_zero <= to_std_logic(d=0);


			-- Framing signals

			tvalid1 <= s_axis_xy_tvalid;

			tlast1 <= s_axis_xy_tlast;
			last_frame1 <= s_axis_xy_last_frame;

			-- Indicate when the first_reg frame is completed, and is used to start reading the FIFO.
			-- Once the readout is started, it continues indefinitely. Since we push data in as fast as
			-- we pull data out, we'll never overflow nor underflow by design.
			-- We need to present the FIFO output to the DSP2 C input on stage 2,
			-- but the FIFO read out has a latency of 1 clock, so we set this signal one stage
			-- earlier. We do not want the FIFO to be FWFT because the
			if tvalid1='1' and tlast1='1' then
				first_frame_completed1 <= '1';
			end if;

			-- Reset overrides
			if rst_reg = '1' then
				tvalid1 <= '0';
				first_frame_completed1 <= '0';
			end if;
			-------------
			-- STAGE 2: The product is clocked in the M=XY register of DSP1, and we clock the correction in the C=Z register.
			-- We also present the FIFO output back into the C input of the DSP2.
			-------------

			tvalid2 <= tvalid1;
			tlast2 <= tlast1;
			last_frame2 <= last_frame1;


			if tvalid2='1' and tlast2='1' then
				first_frame2 <= last_frame2; -- used to tell when DSP2 needs to start a new accumulation (C=0)
				first_frame_completed2 <= '1'; -- used to when to start reading out data from the FWFT FIFO
			end if;


			-- Reset overrides
			if rst_reg = '1' then
				tvalid2 <= '0';
				first_frame2 <= '1';
				first_frame_completed2 <= '0';
			end if;

			-------------
			-- STAGE 3: The DSP1 sum XY+Z is clocked at its output P, which propagates combinatorially to the DSP2 X and Z adder inputs.
			-- We also clock the DSP2 C register, which also directly becomes the DSP2 Y adder input.
			-- This is the stage we decide of the next BRAM address, which is clocked on stage 4 along with the DSP output.
			-------------

			tvalid3 <= tvalid2;
			tlast3 <= tlast2;
			last_frame3 <= last_frame2;

			if tvalid3='1' then -- We create a tfirst flag, which will be used to detect the first
				                -- word of the last frame in the next state
				tfirst3 <= tlast3;
			end if;


			dsp2_c_re_sign3 <= acc_fifo_dout(35); -- register the real part sign bit
			re_sat3 <= to_std_logic( first_frame2 ='0' and (
				acc_fifo_dout(35 downto 18) = "011111111111111111" or
			    acc_fifo_dout(35 downto 18) = "100000000000000000"));

			dsp2_c_im_sign3 <= acc_fifo_dout(17); -- register the imaginary part sign bit
			im_sat3 <= to_std_logic(first_frame2 ='0' and (
				acc_fifo_dout(17 downto 0) = "011111111111111111" or
				acc_fifo_dout(17 downto 0) =	"100000000000000000"));


			-- Reset overrides
			if rst_reg = '1' then
				tvalid3 <= '0';
				tfirst3 <= '1';
			end if;

			-------------
			-- STAGE 4: The DSP2 P output is clocked out. We also generate the Capture and Readout BRAM address.
			-------------

			dsp2_c_re_sign4 <= dsp2_c_re_sign3; -- popeline the sign bit
			dsp2_c_im_sign4 <= dsp2_c_im_sign3; -- popeline the sign bit
			re_sat4 <= re_sat3;
			im_sat4 <= im_sat3;
			dsp2_ab_im_sign4 <= dsp2_ab(47); -- register the AB sign bit

			tvalid4 <= tvalid3;

			-- Clock in the new BRAM address
			-- This state machine operates in two modes:
			--  1) Capture state (readout_enable=0): If we are receiving data from the last frame to
			--     be integrated, store that data into the capture BRAM. We switch into capture mode
			--     whenever we receive such data, and readout operations are aborted even if it was
			--     not completed (meaning it is possible we quit readout mode without sending the
			--     `last` word, which could create frames without end). We switch to readout when we
			--     write the last word to be captured. We also immediately set the `read` flag if
			--     the `send` flag is set.
			--  2) Readout state: (readout_enable=1): Whenever the `send` flag is set, we set the
			--     `rd_en` flag, which propagate down and will indicate that a valid word is
			--     present. We **decrement** the address counter after a word was read (rd_en=1) to
			--     prepare for the next readout. If the address is zero, the last word have already
			--     been read, we leave the readout mode. By decrementing the counter, we do not need
			--     to have a register tell us how many words we need to read out; this is given by
			--     the length of the captured frame, which is assumed to be the same as every frame.
			--
			-- `readout_enable` is always high when rd_en is high.
			capture_wr_en4 <= '0'; -- overriden below when there is data to be written to BRAM
			capture_rd_en4 <= '0'; -- overriden below when we can read data from BRAM
			-- CAPTURE STATE
			if tvalid3='1' and  last_frame3='1' then -- if we have valid data from the last frame of the integration period
				if readout_enable4='1' then  -- If we start storing a new frame while we are still rading out the previous frame, flag an error
					readout_err <= '1';
				end if;
				readout_enable4 <= '0'; -- stop readout of the BRAM if it is still in progress
				capture_wr_en4 <= '1'; -- write the word to the capture BRAM
				if tfirst3='1' then -- if the first word of the last frame of the integration period
					capture_addr4 <= (others=>'0'); -- start writing data at address 0 on the next clock
				else
					capture_addr4 <= capture_addr4 + 1;-- otherwise increment the address
				end if;
				if tlast3='1' then -- if we are writing the last word of the last frame
					readout_enable4 <= '1';  -- go into readout state
					capture_rd_en4 <= send; -- immediately start a read if the destination is ready.
														 -- We don't have to, but since we can read the first readout word at the same time
														 -- we write the last capture word, why not save a cycle?
				end if;
			-- READOUT STATE
			elsif  readout_enable4='1' then -- if we are in the capture state
				capture_rd_en4 <= send; -- read the data at the current address if the sink is ready to accept it
				if capture_rd_en4='1' then -- if we previously read a word, decrement the address counter
					capture_addr4 <= capture_addr4 - 1;
					if capture_addr4 = 0 then -- but if we just read the word at address zero, stop the readout
						readout_enable4 <= '0'; -- The end of the readout state also indicates that the last word was sent down the pipeline in the previous clock.
						capture_rd_en4 <= '0'; -- we finished reading the last word. Dont read address -1, even if `send` is still high.
					end if;
				end if;
			end if;

			-- Reset overrides
			if rst_reg = '1' then
				tvalid4 <= '0';
				readout_enable4 <= '0';
				readout_err <= '0';
			end if;

			-------------
			-- STAGE 5: Internal pipelined BRAM read
			-------------
			capture_rd_en5 <= capture_rd_en4;
			readout_enable5 <= readout_enable4;

			-- Reset overrides
			if rst_reg = '1' then
				capture_rd_en5 <= '0';
				readout_enable5 <= '0';
			end if;

			-------------
			-- STAGE 6: Read word comes out of BRAM
			-------------
			capture_rd_en6 <= capture_rd_en5; -- means we have valid data coming out of BRAM
			readout_enable6 <= readout_enable5;

			-- Reset overrides
			if rst_reg = '1' then
				capture_rd_en6 <= '0';
				readout_enable6 <= '0';
			end if;

			-------------
			-- STAGE 7: Readout data comes out of CMAC
			-------------
			-- We register the output here. This takes lots of FFs (well, 36), but we don't want a
			-- combinatorial tata path through all the daisy-chained CMACs. That will kill out
			-- maximum operating frequency. (although we could register every CMAC out of two or
			-- three, if FF scarcity was really an issue; another option would be to stream the data
			-- out on an 8-bit bus, but that is not compatible with the possible use of 10G
			-- downlinks)

			m_axis_z_out_start_dly <= m_axis_z_out_start;
			--if m_axis_z_out_send='0' then
			if readout_enable6 = '1' and readout_enable5='0' then
				started <= '0';
			elsif m_axis_z_out_start='1' and m_axis_z_out_start_dly='0' then
				started <= '1';
			end if;

			send <= started and m_axis_z_out_send;

			s_axis_z_in_start <= '0';
			if readout_enable6 = '1' then
				m_axis_z_out_local_data <= '1'; -- data is coming from this CMAC
				m_axis_z_out_tdata <= capture_dout6;
				m_axis_z_out_tvalid <= capture_rd_en6;
				s_axis_z_in_send <= '0'; -- Don't let the following CMAC send data; we are busy sending our own.

				-- We terminate of the frame when de detect we will leave the readout mode on the
				-- next clock. When this happens, we force sending a final word with the *last* flag
				-- enabled. Unless the readout was interrupted before it is finished, the current
				-- word should be valid (rd_en=1) and be the last word of the frame anyway. However,
				-- if the readout was interrupted, a dummy word with the *last* flag will be sent,
				-- but at least we won't end up with an unterminated stream that will confuse the
				-- hell out of the downstream logic. This way the data transmit logic has a chance
				-- of recovering naturally if a bad config was used and then corrected.
				m_axis_z_out_tlast <= '0'; -- overriden below
				if readout_enable5 = '0' then
					m_axis_z_out_tvalid <= '1';
					m_axis_z_out_tlast <= '1';
					s_axis_z_in_start <= '1';
				end if;
			else
				-- m_axis_z_out_tdata <= capture_dout_padded(to_integer(byte_ctr5)*8+7 downto to_integer(byte_ctr5)*8);
				m_axis_z_out_local_data <= '0'; -- data is coming from the daisy-chained CMAC
				m_axis_z_out_tdata <= s_axis_z_in_tdata;
				m_axis_z_out_tvalid <= s_axis_z_in_tvalid;
				m_axis_z_out_tlast <= s_axis_z_in_tlast;
				s_axis_z_in_send <= m_axis_z_out_send;
			end if;

			if rst_reg = '1' then
				started <= '0';
				send <= '0';
				m_axis_z_out_tvalid <='0';
				s_axis_z_in_send <= '0';
				m_axis_z_out_local_data <= '0';
				s_axis_z_in_start <= '0';
				m_axis_z_out_start_dly <= '1';
			end if;


		end if; -- CLK
	end process;



end Behavioral;

