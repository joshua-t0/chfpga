----------------------------------------------------------------------------------
--! @file
-- Company: McGill University
-- Engineer: JF Cliche
--
-- Create Date:   Q1 2011
-- Design Name:  chFPGA
-- Module Name:    Package
-- Project Name: CHIME
-- Target Devices: Virtex 6, Kintex 7
-- Tool versions: ISE 14.4, Vivado 2012.4
-- Description: Implements module and global variable definitions
--
-- Dependencies:
--
-- Revision:
-- 2011-09-14 JFC: Created this header block
-- 2013-01-28 JFC: Modified chFPGA_V6 to chFPGA


----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.ALL;
use IEEE.math_real.all; -- needed for ceil()
use IEEE.math_complex.all;
use IEEE.STD_LOGIC_MISC.ALL; -- for or_reduce()
-------- chFPGA Package ------------
--! @brief Defines the system-level constants and data types, declares the components used in the system, and provide support functions and procedures
package chFPGA_Package is



-- generic types and subtypes
subtype Byte is std_logic_vector(7 downto 0);
subtype slv is std_logic_vector;
subtype slv1 is std_logic_vector(0 downto 0);
subtype slv2 is std_logic_vector(1 downto 0);
subtype slv3 is std_logic_vector(2 downto 0);
subtype slv4 is std_logic_vector(3 downto 0);
subtype slv5 is std_logic_vector(4 downto 0);
subtype slv6 is std_logic_vector(5 downto 0);
subtype slv7 is std_logic_vector(6 downto 0);
subtype slv8 is std_logic_vector(7 downto 0);
subtype slv9 is std_logic_vector(8 downto 0);
subtype slv10 is std_logic_vector(9 downto 0);
subtype slv12 is std_logic_vector(11 downto 0);
subtype slv16 is std_logic_vector(15 downto 0);
subtype slv17 is std_logic_vector(16 downto 0);
subtype slv18 is std_logic_vector(17 downto 0);
subtype slv19 is std_logic_vector(18 downto 0);
subtype slv20 is std_logic_vector(19 downto 0);
subtype slv24 is std_logic_vector(23 downto 0);
subtype slv32 is std_logic_vector(31 downto 0);
subtype slv33 is std_logic_vector(32 downto 0);
subtype slv34 is std_logic_vector(33 downto 0);
subtype slv35 is std_logic_vector(34 downto 0);
subtype slv36 is std_logic_vector(35 downto 0);
subtype slv48 is std_logic_vector(47 downto 0);
subtype slv64 is std_logic_vector(63 downto 0);
subtype slv65 is std_logic_vector(64 downto 0);
subtype slv72 is std_logic_vector(71 downto 0);
subtype slv80 is std_logic_vector(79 downto 0);
subtype slv112 is std_logic_vector(111 downto 0);
subtype slv144 is std_logic_vector(143 downto 0);
type ByteArray8 is array (0 to 7) of std_logic_vector(7 downto 0);
type ByteArray is array (NATURAL RANGE <>) of std_logic_vector(7 downto 0);

type slv_array is array (NATURAL RANGE <>) of std_logic_vector; -- VHDL2008 only
type signed_array is array (NATURAL RANGE <>) of signed; -- VHDL2008 only
type unsigned_array is array (NATURAL RANGE <>) of unsigned; -- VHDL2008 only

type slv2_array is array (NATURAL RANGE <>) of std_logic_vector(1 downto 0);
type slv3_array is array (NATURAL RANGE <>) of std_logic_vector(2 downto 0);
type slv4_array is array (NATURAL RANGE <>) of std_logic_vector(3 downto 0);
type slv5_array is array (NATURAL RANGE <>) of std_logic_vector(4 downto 0);
type slv6_array is array (NATURAL RANGE <>) of std_logic_vector(5 downto 0);
type slv7_array is array (NATURAL RANGE <>) of std_logic_vector(6 downto 0);
type slv8_array is array (NATURAL RANGE <>) of std_logic_vector(7 downto 0);
type slv9_array is array (NATURAL RANGE <>) of std_logic_vector(8 downto 0);
type slv10_array is array (NATURAL RANGE <>) of std_logic_vector(9 downto 0);
type slv11_array is array (NATURAL RANGE <>) of std_logic_vector(10 downto 0);
type slv12_array is array (NATURAL RANGE <>) of std_logic_vector(11 downto 0);
type slv13_array is array (NATURAL RANGE <>) of std_logic_vector(12 downto 0);
type slv14_array is array (NATURAL RANGE <>) of std_logic_vector(13 downto 0);
type slv15_array is array (NATURAL RANGE <>) of std_logic_vector(14 downto 0);
type slv16_array is array (NATURAL RANGE <>) of std_logic_vector(15 downto 0);
type slv24_array is array (NATURAL RANGE <>) of std_logic_vector(23 downto 0);
type slv27_array is array (NATURAL RANGE <>) of std_logic_vector(26 downto 0);
type slv28_array is array (NATURAL RANGE <>) of std_logic_vector(27 downto 0);
type slv32_array is array (NATURAL RANGE <>) of std_logic_vector(31 downto 0);
type slv33_array is array (NATURAL RANGE <>) of std_logic_vector(32 downto 0);
type slv34_array is array (NATURAL RANGE <>) of std_logic_vector(33 downto 0);
type slv35_array is array (NATURAL RANGE <>) of std_logic_vector(34 downto 0);
type slv36_array is array (NATURAL RANGE <>) of std_logic_vector(35 downto 0);
type slv48_array is array (NATURAL RANGE <>) of std_logic_vector(47 downto 0);
type slv64_array is array (NATURAL RANGE <>) of std_logic_vector(63 downto 0);
type slv65_array is array (NATURAL RANGE <>) of std_logic_vector(64 downto 0);
type slv66_array is array (NATURAL RANGE <>) of std_logic_vector(65 downto 0);
type slv80_array is array (NATURAL RANGE <>) of std_logic_vector(79 downto 0);
type slv112_array is array (NATURAL RANGE <>) of std_logic_vector(111 downto 0);
type slv128_array is array (NATURAL RANGE <>) of std_logic_vector(127 downto 0);
type slv144_array is array (NATURAL RANGE <>) of std_logic_vector(143 downto 0);
type slv256_array is array (NATURAL RANGE <>) of std_logic_vector(255 downto 0);
type Word3Array is array (NATURAL RANGE <>) of std_logic_vector(2 downto 0);
type Word32Array is array (NATURAL RANGE <>) of std_logic_vector(31 downto 0);
type Word33Array is array (NATURAL RANGE <>) of std_logic_vector(32 downto 0);
type BoolArray is array (natural range <>) of BOOLEAN;
type u2_array is array (NATURAL RANGE <>) of unsigned(1 downto 0);
type u3_array is array (NATURAL RANGE <>) of unsigned(2 downto 0);
type u4_array is array (NATURAL RANGE <>) of unsigned(3 downto 0);
type u8_array is array (NATURAL RANGE <>) of unsigned(7 downto 0);
type u9_array is array (NATURAL RANGE <>) of unsigned(8 downto 0);
type u10_array is array (NATURAL RANGE <>) of unsigned(9 downto 0);
type u11_array is array (NATURAL RANGE <>) of unsigned(10 downto 0);
type u12_array is array (NATURAL RANGE <>) of unsigned(11 downto 0);
type u13_array is array (NATURAL RANGE <>) of unsigned(12 downto 0);
type u16_array is array (NATURAL RANGE <>) of unsigned(15 downto 0);
type u24_array is array (NATURAL RANGE <>) of unsigned(23 downto 0);
type u48_array is array (NATURAL RANGE <>) of unsigned(47 downto 0);
type int8_array is array (NATURAL RANGE <>) of signed(7 downto 0);
type int35_array is array (NATURAL RANGE <>) of signed(34 downto 0);

--type StringArray is array (natural range <>) of STRING;
type IntegerArray is array (natural range <>) of INTEGER;
type integer_array is array (natural range <>) of INTEGER;
type bool_array is array (natural range <>) of boolean;
type integer_16xN_array is array (natural range <>) of integer_array(0 to 15);

type FanoutArray is array (NATURAL RANGE <>) of std_logic_vector(0 downto 0); --! used to create a vector of independent signals used to fan out signal without having the map tool pack them into a single slice because of "register ordering"
type BUFMRIndexArray is array (0 to 8) of INTEGER range -1 to 2; --! used to indicate which BUFMR to use for each bit and the clock of the ADC output
type BUFMRIndexArrayArray is  array (NATURAL RANGE <>) of BUFMRIndexArray;
-- Application specific types and subtypes
subtype PortOffset is std_logic_vector(1 downto 0);
type PortOffsetArray is array (natural range <>) of PortOffset;

--type ADCOut is array (0 to 7) of STD_LOGIC_VECTOR(31 downto 0); -- 8 64-bit words provided by the two ADCs ;


-- Platform IDs
--
-- Is used both by the HDL source code and runtime software to identify the
-- hardware (FPGA and PCB type) on which the firmware runs
--
-- The number is used to index FPGA_SERIES_LIST below
constant PLATFORM_ID_ML605: integer :=0;
constant PLATFORM_ID_KC705: integer :=1;
constant PLATFORM_ID_UNUSED: integer :=2;
constant PLATFORM_ID_MGK7MB: integer :=3;
constant PLATFORM_ID_ZCU111: integer :=4;
constant PLATFORM_ID_CRS: integer :=5;

-- Platform information structure
type PLATFORM_INFO_STRUCT is
	record
		FPGA_SERIES: integer; -- indicates that the series of the FPGA. Is typically used to select low level primitives
		DSP_TILE_DELTA_RPM_Y: integer; -- vertical spacing between DSP tiles in RPM coordinates
		DSP_BEL_DELTA_RPM_Y: integer; -- vertical spacing between DSPs BELs within a tile, in RPM coordinates
		BRAM_TILE_DELTA_RPM_Y: integer; -- vertical spacing between BRAM tiles in RPM coordinates
		BRAM_BEL_DELTA_RPM_Y: integer; -- vertical spacing between BRAMs BELs within a tile, in RPM coordinates
	end record;

type PLATFORM_INFO_ARRAY is array (NATURAL RANGE <>) of PLATFORM_INFO_STRUCT;

-- FPGA series list
--
-- Is indexed by the PLATFORM_ID value to obtain the FPGA series, which is used to select low-level primitives.
--
--  - 6: for VIRTEX6,
--  - 7: VIRTEX/KINTEX7
--  - 8: Ultrascale
--  - 9: Ultrascale+
constant FPGA_VIRTEX6: integer := 6;
constant FPGA_KINTEX7: integer := 7;
constant FPGA_ULTRASCALE: integer := 8;
constant FPGA_ULTRASCALEPLUS: integer := 9;

-- Define platform-specific constants
constant PLATFORM_INFO: PLATFORM_INFO_ARRAY := (
	PLATFORM_ID_ML605 => (
		FPGA_SERIES => FPGA_VIRTEX6,
		DSP_TILE_DELTA_RPM_Y => 0, -- to be defined of ever needed again
		DSP_BEL_DELTA_RPM_Y => 0,
		BRAM_TILE_DELTA_RPM_Y => 0,
		BRAM_BEL_DELTA_RPM_Y => 0
		),

	PLATFORM_ID_KC705 => (
		FPGA_SERIES => FPGA_KINTEX7,
		DSP_TILE_DELTA_RPM_Y => 5,
		DSP_BEL_DELTA_RPM_Y => 5,
		BRAM_TILE_DELTA_RPM_Y => 5,
		BRAM_BEL_DELTA_RPM_Y => 5
		),

	PLATFORM_ID_UNUSED => (
		FPGA_SERIES => FPGA_KINTEX7,
		DSP_TILE_DELTA_RPM_Y => 5,
		DSP_BEL_DELTA_RPM_Y => 5,
		BRAM_TILE_DELTA_RPM_Y => 5,
		BRAM_BEL_DELTA_RPM_Y => 5
		),

	PLATFORM_ID_MGK7MB => (
		FPGA_SERIES => FPGA_KINTEX7,
		-- site spacing in slice coordinates
		--DSP_TILE_DELTA_RPM_Y => 2, -- was 10
		--DSP_BEL_DELTA_RPM_Y => 1, -- was 5
		--BRAM_TILE_DELTA_RPM_Y => 2, -- was 10
		--BRAM_BEL_DELTA_RPM_Y => 1 -- was 5

		-- site spacing in RPM_GRID coordinates
		DSP_TILE_DELTA_RPM_Y => 10,
		DSP_BEL_DELTA_RPM_Y => 5, -- DSPs within a tile are spaced by 5 RPM_Y grid units
		BRAM_TILE_DELTA_RPM_Y => 10,
		BRAM_BEL_DELTA_RPM_Y => 1 -- BRAMs within a tile are spaced by 1 RPM_Y grip unit (yeah, different from DSPs!)
		),

	PLATFORM_ID_ZCU111 => (
		FPGA_SERIES => FPGA_ULTRASCALEPLUS,
		DSP_TILE_DELTA_RPM_Y => 10,
		DSP_BEL_DELTA_RPM_Y => 1,
		BRAM_TILE_DELTA_RPM_Y => 10,
		BRAM_BEL_DELTA_RPM_Y => 1
		),


	PLATFORM_ID_CRS => (
		FPGA_SERIES => FPGA_ULTRASCALEPLUS,
		DSP_TILE_DELTA_RPM_Y => 10,
		DSP_BEL_DELTA_RPM_Y => 1,
		BRAM_TILE_DELTA_RPM_Y => 10,
		BRAM_BEL_DELTA_RPM_Y => 1
		)

	);



constant FPGA_SERIES_LIST: IntegerArray:=(
	PLATFORM_ID_ML605 => FPGA_VIRTEX6,
	PLATFORM_ID_KC705 => FPGA_KINTEX7,
	PLATFORM_ID_UNUSED => FPGA_KINTEX7,
	PLATFORM_ID_MGK7MB => FPGA_KINTEX7,
	PLATFORM_ID_ZCU111 => FPGA_ULTRASCALEPLUS,
	PLATFORM_ID_CRS => FPGA_ULTRASCALEPLUS
	);

-- Hardware-related constants
constant NUMBER_OF_CHANNELIZERS_MAX: INTEGER :=16; -- Maximum number of channelizers supported by the system
constant NUMBER_OF_ADCS_MAX: INTEGER :=16; -- Maximum number of ADC inputs supported by the system
constant NUMBER_OF_CORRELATORS_MAX: INTEGER :=8; -- Maximum number of correlators supported by the system

-- maximum number of CMACs in a CORR44 core.  The factor of two is because CORR44 needs to process two vectors at the same time so the results are coming out as fast at the data is pushed in
constant NUMBER_OF_CMACS_MAX : integer := (NUMBER_OF_CHANNELIZERS_MAX + 1) * 2;


--! Basic system configuration
--! These constants are defined globally in this package because the CHAN and CORR modules cannot be implemented
--! out of contect if they have generics.
--constant GLOBAL_IMPLEMENT_FFT: boolean := TRUE;
constant GLOBAL_NUMBER_OF_CHANNELIZERS_TO_CORRELATE: integer := 8;
constant GLOBAL_SIM: boolean := FALSE;
constant GLOBAL_NUMBER_OF_GPU_LINKS: integer := 8; --! (0- NUMBER_OF_CHANNELIZERS) Number of 10Gb Ethernet links to connecto to the GPUs
constant GLOBAL_NUMBER_OF_GPU_REFCLKS: integer := 1; --! Number of Reference clocks provided for the 10GE links to the GPU
constant GLOBAL_GPU_CHANNEL_QUAD: IntegerArray := (0 to 3=> 0, 4 to 7=> 1); -- Channels 0-3 use QUAD0, Channels 4-7 use QUAD1
constant GLOBAL_GPU_QUAD_REFCLK: IntegerArray := (0 to 1=>0); -- Both QUAD0 and QUAD1 use refclk(0)




--constant FRAME_LENGTH: integer:= 2048; --! 2048 time samples per frame (1024 frame samples per frame)
--constant LOG2_FRAME_LENGTH: integer :=11; --! Number of time samples per frame. 2^11 = 2048 time samples per frame
--constant LOG2_FREQ_SAMPLES_PER_FRAME: integer :=LOG2_FRAME_LENGTH-1; --! Number of frequency samples per frame. 1/2 of the time samples as we discard negative frequencies
--constant LOG2_WORDS_PER_FRAME: integer :=LOG2_FRAME_LENGTH-2; --! Number of words per frame. One word is 4 8-bit time samples or 2 8+8-bits frequency samples.

--type frame_word_ctr_array is array (natural range <>) of unsigned(LOG2_WORDS_PER_FRAME-1 downto 0);

--	Control bus parameters
constant CTRL_CMD_BYTE_LENGTH: integer :=3; --! Number of bytes in the command word
constant CTRL_CMD_WORD_WIDTH: integer := CTRL_CMD_BYTE_LENGTH * 8; --! Number of bits in the command word
constant CTRL_CMD_BYTE_COUNT_WIDTH: integer :=2; --! number of bits requird to count the number of bytes in a command
--constant CTRL_CMD_DIR_BIT: integer:=23;
--constant CTRL_CMD_INCR_BIT: integer:=22;
constant CTRL_CMD_OPCODE_WIDTH: integer :=3; --! Number of bits in the opcode
constant CTRL_CMD_COUNT_WIDTH: integer:=2;
--constant CTRL_CMD_COUNT_LSB: integer:=20;
--type CTRL_CMD_COUNT_RANGE is range (CTRL_CMD_COUNT_LSB+CTRL_CMD_COUNT_WIDTH-1) downto CTRL_CMD_COUNT_LSB;
constant CTRL_CMD_ADDR_WIDTH: integer := CTRL_CMD_WORD_WIDTH - CTRL_CMD_OPCODE_WIDTH - CTRL_CMD_COUNT_WIDTH; --! Total number of address bits. The address is in the LSBs of the command word (i.e. downto 0)
--constant CTRL_PORT_NUMBER_WIDTH: INTEGER :=5; --! Number of address bits used for port number
--constant CTRL_MODULE_NUMBER_WIDTH: INTEGER :=3; --! Number of address bits used for module number
--constant CTRL_MODULE_ADDR_WIDTH: INTEGER :=CTRL_ADDR_WIDTH-CTRL_PORT_NUMBER_WIDTH-CTRL_MODULE_NUMBER_WIDTH; -- Number of address bits used within a module
--constant CTRL_MODULE_ADDR_WIDTH: INTEGER := 10; -- Number of address bits used within a module
--type CTRL_ADDR_RANGE is range (CTRL_ADDR_WIDTH-1) downto 0;

-- subtype CTRL_PORT_NUMBER_RANGE is integer RANGE (CTRL_ADDR_WIDTH-1) downto CTRL_ADDR_WIDTH-CTRL_PORT_NUMBER_WIDTH; --
-- subtype CTRL_MODULE_NUMBER_RANGE is integer RANGE (CTRL_ADDR_WIDTH-CTRL_PORT_NUMBER_WIDTH-1) downto CTRL_ADDR_WIDTH-CTRL_PORT_NUMBER_WIDTH-CTRL_MODULE_NUMBER_WIDTH; --

-- AXI4 STREAMING data structure used for the control system (Command and Reply buses)
type AXIS8_DAT_STRUCT is -- control/data bus used to communicate from  master to slave
	record
		--DUMMY: std_logic; -- needed to cirvumvent simulator bug on VIvado 2012.4 and 2013.1. Otherwise the control bus doesnot work in simulation.
		TVALID: std_logic; -- indicates that the master is driving a valid value
		TDATA : std_logic_vector(7 downto 0); -- data from the master
		TLAST: std_logic; -- indicated that the master is driving the last byte of the frame
	end record;

type AXIS8_RDY_STRUCT is  -- control bus used to communicate from  slave to master
	record
		TREADY: std_logic; -- indicates that the slave device is ready to accept data. The transaction occurs when TREA|DY and TVALID are both '1';
	end record;

type AXIS8_DAT_STRUCT_ARRAY is ARRAY (natural range <>) of AXIS8_DAT_STRUCT;
type AXIS8_RDY_STRUCT_ARRAY is ARRAY (natural range <>) of AXIS8_RDY_STRUCT;

-- 32-bit wide AXI4 STREAMING data structure used for the time-based (4 sampels per word) and spectrum (2 samples per word) data streams
type AXIS32_DAT_STRUCT is -- control/data bus used to communicate from  master to slave
	record
		TVALID: std_logic; -- indicates that the master is driving a valid value
		TDATA : std_logic_vector(31 downto 0); -- data from the master
		TLAST: std_logic; -- indicated that the master is driving the last byte of the frame
		TUSER : std_logic_vector(3 downto 0); -- Used to transfer ancilliary information (overflows, frame info etc). Meaning is specific to each bus segments
	end record;
type AXIS32_DAT_STRUCT_ARRAY is ARRAY (natural range <>) of AXIS32_DAT_STRUCT;

type AXIS32_RDY_STRUCT is  -- control bus used to communicate from  slave to master. Not normally used since data streams flow is not handshaked
	record
		TREADY: std_logic; -- indicates that the slave device is ready to accept data. The transaction occurs when TREA|DY and TVALID are both '1';
	end record;
type AXIS32_RDY_STRUCT_ARRAY is ARRAY (natural range <>) of AXIS32_RDY_STRUCT;

-- 64-bit wide AXI4 STREAMING data structure
type AXIS64_DAT_STRUCT is -- control/data bus used to communicate from  master to slave
	record
		TVALID: std_logic; -- indicates that the master is driving a valid value
		TDATA : std_logic_vector(63 downto 0); -- data from the master
		TLAST: std_logic; -- indicated that the master is driving the last byte of the frame
		TUSER : std_logic_vector(3 downto 0); -- Used to transfer ancilliary information (overflows, frame info etc). Meaning is specific to each bus segments
	end record;
type AXIS64_DAT_STRUCT_ARRAY is ARRAY (natural range <>) of AXIS64_DAT_STRUCT;


-- 72-bit wide AXI4 STREAMING bus used for the FFT output consisting of two (18+18) bits wide frequency samples
type AXIS72_DAT_STRUCT is
	record
		TVALID: std_logic; -- indicates that the master is driving a valid value
		TDATA : std_logic_vector(71 downto 0); -- data from the master
		TLAST: std_logic; -- indicated that the master is driving the last byte of the frame
		TUSER : std_logic_vector(3 downto 0); -- Used to transfer ancilliary information (overflows, frame info etc). Meaning is specific to each bus segments
	end record;

-- 34-bit wide AXI4 STREAMING bus used for the complex multiplier output (17+17) bits
type AXIS34_DAT_STRUCT is
	record
		TVALID: std_logic; -- indicates that the master is driving a valid value
		TDATA : std_logic_vector(33 downto 0); -- data from the master
		TLAST: std_logic; -- indicated that the master is driving the last byte of the frame
		TUSER : std_logic_vector(3 downto 0); -- Used to transfer ancilliary information (overflows, frame info etc). Meaning is specific to each bus segments
	end record;
type AXIS34_DAT_STRUCT_ARRAY is ARRAY (natural range <>) of AXIS34_DAT_STRUCT;

-- 108-bit wide AXI4 STREAMING bus used for the complex accumulator output (54+54) bits
-- 1/850e6 samples/s * 2048 samples/frame * 2^(54-17) accumulated frames before overflow = 331 147 s = 92h
type AXIS108_DAT_STRUCT is
	record
		TVALID: std_logic; -- indicates that the master is driving a valid value
		TDATA : std_logic_vector(107 downto 0); -- data from the master
		TLAST: std_logic; -- indicated that the master is driving the last byte of the frame
		TUSER : std_logic_vector(3 downto 0); -- Used to transfer ancilliary information (overflows, frame info etc). Meaning is specific to each bus segments
	end record;
type AXIS108_DAT_STRUCT_ARRAY is ARRAY (natural range <>) of AXIS108_DAT_STRUCT;

-- Channelizer AXIS bus TUSER bit definitions
---------------------------------------------
-- From  ADCDAQ:
--   Bits 0-3 are overflow flags for sample 0-3 in each word
-- From FUNCGEN
constant TUSER_CAPTURE_BIT: INTEGER :=0; -- Set by FUNCGEN and passed downstream to indicate to the PROBER that the data should be captured if continuous capture  mode is enabled

-- Flags that are set on the last N words of each packet.
--  TLAST - 0: ADC Overflow (Downstream of FUNCGEN only)
--  TLAST - 1: FFT Overflow (Downstream of FFT only)
--  TLAST - 2: Gain Bank (Downstream of SCALER only)
constant TUSER_SERIAL_FLAGS_BIT: INTEGER :=3;

constant TUSER_ADC_OVERFLOW_BIT: INTEGER :=3; -- Set by SRCSEL ont he last word of a frame to indicate that ADC saturation has occured on a sample of the frame.
constant TUSER_FFT_OVERFLOW_BIT: INTEGER :=0; -- Set by SRCSEL and passed downstream to indicate to the PROBER that the data should be captured if continuous capture  mode is enabled

constant TUSER_SCALER_LOW_OVERFLOW_BIT: INTEGER :=1; -- Set by SCALER to indicate ovweflow on the sample in the Low part of the word
constant TUSER_SCALER_HIGH_OVERFLOW_BIT: INTEGER :=2; -- -- Set by SCALER to indicate ovweflow on the sample in the high part of the word
constant TUSER_EVEN_SCALER_OVERFLOW_BIT: INTEGER := TUSER_SCALER_HIGH_OVERFLOW_BIT; -- -- Set by SCALER to indicate ovweflow on the sample in the high part of the word
constant TUSER_ODD_SCALER_OVERFLOW_BIT: INTEGER := TUSER_SCALER_LOW_OVERFLOW_BIT; -- -- Set by SCALER to indicate ovweflow on the sample in the high part of the word

type FREQ_SAMPLE_STRUCT is
	record
		Re: signed(7 downto 0);
		Im: signed(7 downto 0);
	end record;
constant FREQ_SAMPLE_ZERO: FREQ_SAMPLE_STRUCT := (Re=>(others=>'0'),Im=>(others=>'0'));
type FREQ_SAMPLE_STRUCT_ARRAY is array (NATURAL RANGE <>) of FREQ_SAMPLE_STRUCT;


-- Complex number at the output of the corrleator multiplier
type COMPLEX17_STRUCT is -- (17 Re + 17 Im) = 34 bits wide combined
	record
		Re: signed(16 downto 0);
		Im: signed(16 downto 0);
	end record;
type COMPLEX17_STRUCT_ARRAY is array (NATURAL RANGE <>) of COMPLEX17_STRUCT;

-- Complex number stored in the accumulator
type COMPLEX48_STRUCT is -- (54 Re + 54 Im) = 108 bits wide combined -- maximum width of 3 RAMB18K (which is the height of the complex multiplier)
	record
		Re: signed(47 downto 0);
		Im: signed(47 downto 0);
	end record;
type COMPLEX48_STRUCT_ARRAY is array (NATURAL RANGE <>) of COMPLEX48_STRUCT;

--! Raw data capture (PROBER) frame header
constant FRAME_HEADER_BYTE_LENGTH: integer := 10; -- Number of 32-bit words taken by a header
type FRAME_HEADER_STRUCT is
	record  -- In transmission order (bytewise)
		-- Byte 0
		PROBE_ID: std_logic_vector(7 downto 0); -- 1 byte, user-defined. Generally a cookie, but can be used by user to convey more info (e.g. extend the number of channels)
		-- Bytes 1-2
		STREAM_ID: std_logic_vector(15 downto 0); --! 16 bit value used to uniquely define the data stream and lookup . Defined as listed below:
			--! Bits 15-12 (4 bits). Software defined. Identifies the data source (0 = adc/funcgen, 1=fft/scaler).
			--! Bits 12-8 (4 bits). Software defined. Identifies the crate_number.
			--! Bits 7-4 (4 bits). Software defined. Identifies slot number (zero-based).
			--! Bits 3-0 (4 bits). Hardware defined. Identifies the 10Gb/s lane (1st shuffle has 15 lanes, 2nd shuffle has 4 lanes, GPU link has 8 lanes).
		-- Byte 3
		SERIAL_FLAGS: std_logic_vector(3 downto 0); -- last 4 bits of the TUSER_SERIAL_FLAGS_BIT field (meaning depends on the data source)
		FLAGS: std_logic_vector(3 downto 0); -- 4 bits: aggregated TUSER bits at the input source
		-- Bytes 4-9
		TIMESTAMP: std_logic_vector(47 downto 0); --6 bytes (48 bits), system-defined
	end record;

constant SHUFFLE_FRAME_HEADER_WORD_LENGTH: integer :=4; -- Number of 32-bit words taken by a header
constant SHUFFLE_FRAME_HEADER_COOKIE: std_logic_vector(7 downto 0) := x"CF";
constant SHUFFLE_FRAME_HEADER_PROTOCOL_VERSION: std_logic_vector(3 downto 0) := X"1";

type SHUFFLE_FRAME_HEADER_STRUCT is
	record
		-- Word 0
		STREAM_ID: std_logic_vector(15 downto 0); --! 16 bit value used to uniquely define the data stream and lookup . Defined as listed below:
			--! Bits 15-12 (4 bits). Software defined. Identifies the data source within the internal pipeline (1st shuffle, 2nd shufle, raw data etc.).
			--! Bits 12-8 (4 bits). Software defined. Identifies the crate_number.
			--! Bits 7-4 (4 bits). Software defined. Identifies slot number (zero-based).
			--! Bits 3-0 (4 bits). Hardware defined. Identifies the 10Gb/s lane (1st shuffle has 15 lanes, 2nd shuffle has 4 lanes, GPU link has 8 lanes).
		PROTOCOL_VERSION: std_logic_vector(3 downto 0); --! Along with the cookie, identifies how the data is encoded in this header and the data. The cookie will have to change if we run out of space for versions.
		HEADER_LENGTH_IN_WORDS: std_logic_vector(3 downto 0); --! Number of 32-bit words in this header, to help the GPU skip this part if needed
		COOKIE: std_logic_vector(7 downto 0); --! 8 Bits (hardcoded) used to identify the type of frame. The cookie is last in the word so it appears first in the packet.
		-- Word 1
		ENCODING: std_logic_vector(3 downto 0); --! bit 0: '0' = 8 bit mode, '1' = 4 bit mode; bit 1: '0'= 2's complement, '1'=offset binary, bits 2-3: reserved
		NUMBER_OF_FRAMES: std_logic_vector(3 downto 0); --! number of frames per packet (1-255)
		NUMBER_OF_BINS: std_logic_vector(11 downto 0); --! Number of frequency bins included in each frame (1-4095) (there are up to 1024 bins in full CHIME)
		NUMBER_OF_ANTENNAS: std_logic_vector(11 downto 0); --! Number of antennas included for each frequency bin (1-4095) (there are up to 2560 antennas in full CHIME)

		-- Word 2
		ANCILLARY_DATA: std_logic_vector(31 downto 0); --! Ancillary data channel to trickle a statistical (or other low rate) data stream

		-- Word 3
		TIMESTAMP: std_logic_vector(31 downto 0); -- --! 32-bit frame number of the *first* frame in the packet. The data sampling time relative to the last SYNC event is directly computed from the frame number. Rolls back every ~3h @ 800MSPS, 2048 time samples/frame.
	end record;

type rpm_coord_struct is record
	x: integer;
	y: integer;
end record;
--type rpm_coord_struct_array is array (NATURAL RANGE <>) of rpm_coord_struct;

-- Structure that defines the RPM coordinates of each element (2 DSPs and 2 BRAMs) in a CORR44
--    - DSP1 computes the product
--    - DSP2 finalizes/combines the products and adds the previous values
--    - FIFO is the vecrtor accumulator
--    - BRAM stores the final accumuled products and trickle them out while the new integration is under way
type cmac44_rpm_coord_struct is record
	DSP1, DSP2, FIFO, BRAM: rpm_coord_struct;
end record;

-- Array that describes the relative location of each CMAC44 elements in a CORR44
type cmac44_rpm_coord_struct_array is array (NATURAL RANGE 0 to NUMBER_OF_CMACS_MAX -1) of cmac44_rpm_coord_struct;

-- Structure that describes the layout and absolute location a CORR44 core
-- The positions are absolute RPM_GRID coordinates.
-- The coordinate specify the lower left corner of the CORR44 core, which can be a DSP, BRAM/FIFO depending on the layout
type corr44_rloc_origin_struct is record
	loc: rpm_coord_struct; -- Absolute location of lower left cell (type of site depends on layout)
	layout: string(1 to 4); -- layout of the CMAC44 (e.g. "BDDB" or "DBBD" )
end record;

-- Array that describes the layout and absolute positions of the corr44 cores in a CORR44_ARRAY
type corr44_rloc_origins_struct_array is array (NATURAL RANGE 0 to NUMBER_OF_CORRELATORS_MAX -1) of corr44_rloc_origin_struct;



function bit_reverse(s1:std_logic_vector) return std_logic_vector; -- reverses left-right bit order of a vector AND the direction of the vector
function reverse_bits_same_dir(s1:std_logic_vector) return std_logic_vector; --! reverses left-right bit order of a vector but keep the vector original direction
function reverse_bits_and_dir(s1:std_logic_vector) return std_logic_vector ; --! reverse both the bit order and  direction of vector.
function reverse_bytes(s1:std_logic_vector) return std_logic_vector; --! reverses byte order of a vector. Input vector length must be a multiple of 8.
function lsb(s1:unsigned; width:integer:=8) return unsigned; -- returns least significant byte of a word
function lsb(s1:std_logic_vector; width:integer:=8) return std_logic_vector;
function msb(s1:signed; width:integer:=8) return signed;
function msb(s1:std_logic_vector; width:integer:=8) return std_logic_vector;
function sign_bit(i:signed) return std_logic; --! Returns the sign bit (the MSB) of a signed number
function sign_bit(i:unsigned) return std_logic; --! Returns the sign bit (the MSB) of an unsigned number
function sign_bit(i:std_logic_vector) return std_logic; --! Returns the sign bit (the MSB) of a std_logic_vector
function sel(b: BOOLEAN; if_true: string; if_false: string) return string;
function sel(b: BOOLEAN; if_true: real; if_false: real) return real;
function sel(b: BOOLEAN; if_true: integer; if_false: integer) return integer;
function sel(b: BOOLEAN; if_true: time; if_false: time) return time;
function sel(b: BOOLEAN; if_true: std_logic; if_false: std_logic) return std_logic;
function sel(b: BOOLEAN; if_true: std_logic_vector; if_false: std_logic_vector) return std_logic_vector;
function sel(b: BOOLEAN; if_true: slv32_array; if_false: slv32_array) return slv32_array;
function sel(b: std_logic; if_true: std_logic_vector; if_false: std_logic_vector) return std_logic_vector;

function MAX (LEFT, RIGHT: INTEGER) return INTEGER;
function MAX (vin: IntegerArray) return INTEGER;
function MIN (LEFT, RIGHT: INTEGER) return INTEGER;
function MIN (vin: IntegerArray) return INTEGER;
function MIN (LEFT, RIGHT: unsigned) return unsigned;
function to_std_logic(i:boolean) return std_logic; -- converts bool to std_logic
function to_slv(i:integer; n: integer) return std_logic_vector; -- converts integer to standard_logic_vector with specified numbe rof bits
function to_slv(r:real; n: integer) return std_logic_vector; -- converts real to standard_logic_vector with specified numbe rof bits
function to_slv(i:std_logic) return std_logic_vector; -- converts a std_logic into a one element vector
function to_slv(i:unsigned) return std_logic_vector; -- converts unsigned to STD_LOGIC_VECTOR
function to_slv(i:unsigned; n: integer) return std_logic_vector; -- resize and converts unsigned to STD_LOGIC_VECTOR
function to_slv(i:ByteArray; n: integer) return std_logic_vector; -- concatenate bytes in a ByteAray and return the n LSBs as a STD_LOGIC_VECTOR
function to_slv(i:ByteArray) return std_logic_vector; -- concatenated bytes in a ByteAray and return them as a STD_LOGIC_VECTOR
function to_slv(i:slv8_array; n: integer) return std_logic_vector; -- concatenate bytes in a slv8_array and return the n LSBs as a STD_LOGIC_VECTOR
function to_slv(i:slv8_array) return std_logic_vector; -- concatenated bytes in a slv8_array and return them as a STD_LOGIC_VECTOR

function resize(i:std_logic_vector; n: integer) return std_logic_vector; -- resizes a STD_LOGIC_VECTOR. Truncates or adds zero padding.
function to_ByteArray(i:std_logic_vector) return ByteArray;-- spilt a slv in ia ByteArray. The SLV length must be multiples of 8 bits.
function to_ByteArray(i:unsigned) return ByteArray;-- spilt a unsigned in ia ByteArray. The SLV length must be multiples of 8 bits.
function to_ByteArray(i:slv8_array) return ByteArray; -- Convert slv8_array to ByteArray (for legacy compatibility).
function to_slv8_array(i:std_logic_vector) return slv8_array;-- spilt a unsigned in ia ByteArray. The SLV length must be multiples of 8 bits.
function to_slv8_array(i:unsigned) return slv8_array;-- spilt a unsigned in ia ByteArray. The SLV length must be multiples of 8 bits.
function to_slv8_array_le(i:slv32_array) return slv8_array; -- split a slv32_array byte-wise in a slv8_array in the Little Endian order i(0)(7 downto 0)) is in result(0).
function to_unsigned(i:ByteArray; n: integer) return unsigned; -- concatenate bytes in a ByteAray and return them as a n-bit unsigned
function to_unsigned(i:ByteArray) return unsigned; -- concatenate bytes in a ByteAray and return them as an unsigned
function to_unsigned(i:slv8_array; n: integer) return unsigned; -- concatenate bytes in a ByteAray and return them as a n-bit unsigned
function to_unsigned(i:slv8_array) return unsigned; -- concatenate bytes in a slv8_array and return them as an unsigned
function to_unsigned(i:std_logic) return unsigned; -- converts a std_logic into a one element unsigned
function str(i:integer) return string; -- converts integer to a string. Allows expressions, contrary to to_string().
function repeat( V: std_logic_vector; N: natural) return std_logic_vector; --! Concatenates a vector N times
function log2(v: integer) return real; -- Returns the log2 of an integer as a real (overloads the library log2())
function integer_log2(v: integer) return integer; -- Returns the log2 of an integer as an integer
function integer_log2(v: real) return integer; -- Returns the log2 of areal as an integer
function width(len: integer) return integer; --! computes the minimum number of bits needed to represent len-1
function bitwidth(value: integer) return integer;--! Computes the minimum number of bits needed to represent value
function shift_left(i:std_logic_vector; n: integer) return std_logic_vector; -- shift left a STD_LOGIC_VECTOR
function shift_left(ARG:slv8_array; COUNT: natural) return slv8_array; -- shift left a byte array
function shift_right(i:std_logic_vector; n: integer) return std_logic_vector; -- shift right a STD_LOGIC_VECTOR with zero padding from the left
function shift_right(x:slv2_array)  return slv2_array; -- shift right a slv2_array. 
function shift_right(x:slv3_array)  return slv3_array; -- shift right a slv3_array.
function shift_right(x:slv4_array)  return slv4_array; -- shift right a slv4_array.
function any_one(v: std_logic_vector) return boolean; -- Return TRUE if any bit is '1'.
function any_one(v: unsigned) return boolean; -- Return TRUE if any bit is '1'.
function any_zero(v: std_logic_vector) return boolean; -- Return TRUE if any bit is '1'.
function any_zero(v: unsigned) return boolean; -- Return TRUE if any bit is '1'.
function all_ones(v: std_logic_vector) return boolean; -- Return TRUE if all bits are '1'.
function all_ones(v: unsigned) return boolean; -- Return TRUE if all bits are '1'.
function all_zeros(v: std_logic_vector) return boolean; -- Return TRUE if all bits are '0'.
function all_zeros(v: unsigned) return boolean; -- Return TRUE if all bits are '0'.
function cmplx(re, im:integer) return complex; -- Create a complex value out of two integer values
function cmplx(re, im:signed) return complex; -- Create a complex value out of two signed values


FUNCTION struct_to_bytes(s:FRAME_HEADER_STRUCT) return slv8_array; -- Converts a FRAME_HEADER structure into a word array
-- function word_to_struct(w: Word32Array) return FRAME_HEADER_STRUCT; -- Converts a word array into a FRAME_HEADER structure

function struct_to_word(s:SHUFFLE_FRAME_HEADER_STRUCT) return slv32_array; -- Converts a SHUFFLE_FRAME_HEADER structure into a word array
function word_to_struct(w: slv32_array(0 to SHUFFLE_FRAME_HEADER_WORD_LENGTH-1):= (others=>(others=>'0'))) return SHUFFLE_FRAME_HEADER_STRUCT; -- Converts a word array into a SHUFFLE_FRAME_HEADER structure

--FUNCTION resize(s:signed; constant size:integer) return signed;
PROCEDURE axis32_write_buffer(buffer_in: in Word32Array; signal stream_out: out AXIS32_DAT_STRUCT; signal clk: in std_logic);

function rpm_to_string(rpm: rpm_coord_struct) return string; -- convert a RPM coordinate pair into a "XnYn" string
function get_cmac44_rpm_coords_struct_array(platform_id: integer; N_CHAN: integer; layout: string) return cmac44_rpm_coord_struct_array; -- returns the locations of the CMAC44 DSPs and BRAMs for a corr44 correlator core with specified layout
function get_corr44_rloc_origins_struct_array(platform_id:integer; N_CHAN:integer) return corr44_rloc_origins_struct_array; -- returns the layout and absolute location of each corr4 core in a corr44_array

end chFPGA_Package;

package body chFPGA_Package is

--! function bit_reverse
--! Reverses both the left-right bit order and the direction of the vector.
FUNCTION bit_reverse(s1:std_logic_vector) return std_logic_vector is
  --    variable rr : std_logic_vector(s1'high downto s1'low);
  -- begin
  --   for ii in s1'high downto s1'low loop
  --     rr(ii) := s1(s1'high-ii);
  --   end loop;
  --   return rr;
  -- end bit_reverse;
	variable result: std_logic_vector(s1'REVERSE_RANGE);
	--	alias aa: std_logic_vector(s1'RANGE) is s1;
	begin
		for i in s1'RANGE loop
			result(i) := s1(i);
		end loop;
		return result;
	end bit_reverse;

--! reverses the order of the bits but yield a vector indexed in the same direction
--! i.e. x(3 downto 0) := "1100"; y(3 downto 0) = reverse_bits_same_dir(x) = "0011"
FUNCTION reverse_bits_same_dir(s1:std_logic_vector) return std_logic_vector is
	variable result: std_logic_vector(s1'RANGE);
	alias s1_rev: std_logic_vector(s1'REVERSE_RANGE) is s1;
	begin
		for i in s1'RANGE loop
			-- result(i) := s1_rev(i);
			result(i) := s1(s1'LOW + (s1'HIGH-i)); -- alternate way to do it without alias
		end loop;
		return result;
	end reverse_bits_same_dir;

--! reverses the order of the bits but yield a vector indexed in the same direction
--! i.e. x(3 downto 0) := "1100"; y(0 downto 3) = reverse_bits_same_dir(x) = "0011"
FUNCTION reverse_bits_and_dir(s1:std_logic_vector) return std_logic_vector is
	variable result: std_logic_vector(s1'REVERSE_RANGE);
	begin
		for i in s1'RANGE loop
			result(i) := s1(i);
		end loop;
		return result;
	end reverse_bits_and_dir;


FUNCTION reverse_bytes(s1:std_logic_vector) return std_logic_vector is
     variable rr : std_logic_vector(s1'high downto s1'low);
	 variable num_bytes: integer;
	begin
	  num_bytes := s1'LENGTH/8;
	  for i in 0 to (num_bytes-1) loop
		rr(8*i+7+s1'low downto 8*i+s1'low) := s1(8*(num_bytes-1-i)+7+s1'low downto 8*(num_bytes-1-i)+s1'low);
	  end loop;
		return rr;
	end reverse_bytes;


FUNCTION lsb(s1:unsigned; width:integer:=8) return unsigned is
  begin
    return s1(width-1 downto 0);
  end lsb;

FUNCTION lsb(s1:std_logic_vector; width:integer:=8) return std_logic_vector is
  begin
    return s1(width-1 downto 0);
  end lsb;

FUNCTION msb(s1:signed; width:integer:=8) return signed is
  begin
    return s1(s1'LENGTH-1 downto s1'LENGTH-width);
  end msb;

FUNCTION msb(s1:std_logic_vector; width:integer:=8) return std_logic_vector is
  begin
    return s1(s1'LENGTH-1 downto s1'LENGTH-width);
  end msb;

FUNCTION sign_bit(i:signed) return std_logic is --
  	begin
  		return i(i'LENGTH-1);
  	end sign_bit;

FUNCTION sign_bit(i:unsigned) return std_logic is --
	begin
		return i(i'LENGTH-1);
	end sign_bit;

FUNCTION sign_bit(i:std_logic_vector) return std_logic is --
	begin
		return i(i'LENGTH-1);
	end sign_bit;

-- stolen from std_numeric
function MAX(LEFT, RIGHT: INTEGER) return INTEGER is
  begin
    if LEFT > RIGHT then return LEFT;
    else return RIGHT;
    end if;
  end MAX;

function MAX(vin: IntegerArray) return INTEGER is
		variable vout: integer;
		begin
			vout := INTEGER'LOW;
			for j in 0 to vin'Length-1 loop
				if 	vin(j) > vout then
					vout := vin(j);
				end if;
			end loop;
			return vout;
		end MAX;

function MIN(vin: IntegerArray) return INTEGER is
		variable vout: integer;
		begin
			vout := INTEGER'HIGH;
			for j in 0 to vin'Length-1 loop
				if 	vin(j) < vout then
					vout := vin(j);
				end if;
			end loop;
			return vout;
		end MIN;

-- stolen from std_numeric
function MIN(LEFT, RIGHT: INTEGER) return INTEGER is
  begin
    if LEFT < RIGHT then return LEFT;
    else return RIGHT;
    end if;
  end MIN;

function min(LEFT, RIGHT: unsigned) return unsigned is
  begin
    if LEFT < RIGHT then return LEFT;
    else return RIGHT;
    end if;
  end min;

FUNCTION to_std_logic(i:boolean) return std_logic is -- converts boot to std_logic
	begin
		if i then
			return '1';
		else
			return '0';
		end if;
	end to_std_logic;

FUNCTION to_slv(i:integer; n: integer) return std_logic_vector is -- converts integer to standard_logic_vector with specified numbe rof bits
	begin
		return std_logic_vector(to_unsigned(i,n));
	end to_slv;

FUNCTION to_slv(r:real; n: integer) return std_logic_vector is -- converts real to std_logic_vector with specified numbe rof bits
	begin
		return std_logic_vector(to_signed(integer(r), n));
	end to_slv;

FUNCTION to_slv(i:unsigned) return std_logic_vector is -- converts unsigned to STD_LOGIC_VECTOR
	begin
		return std_logic_vector(i);
	end to_slv;

FUNCTION to_slv(i:unsigned; n: integer) return std_logic_vector is -- resizes and converts unsigned to STD_LOGIC_VECTOR
	begin
		return std_logic_vector(resize(i,n));
	end to_slv;

FUNCTION resize(i:std_logic_vector; n: integer) return std_logic_vector is -- resizes a STD_LOGIC_VECTOR. Truncates or adds zero padding.
	begin
		return std_logic_vector(resize(unsigned(i),n));
	end resize;

FUNCTION to_slv(i:ByteArray; n: integer) return std_logic_vector is -- concatenate bytes in a ByteAray and return them as a n bit STD_LOGIC_VECTOR
	variable v:std_logic_vector(n-1 downto 0);
	variable ix: integer;
	begin
		v:=(others=>'0'); -- clear all bits by default in case we ask for more bits than there are in the byte array
		ix:=i'Right;
		for j in 0 to n-1 loop
			if i'Ascending then
				v(j):=i(ix-j/8)(j mod 8);
			else
				v(j):=i(ix+j/8)(j mod 8);
			end if;
		end loop;
		return v;
	end to_slv;

FUNCTION to_slv(i:slv8_array; n: integer) return std_logic_vector is -- concatenate bytes in a slv8_array and return them as a n bit STD_LOGIC_VECTOR
	variable v:std_logic_vector(n-1 downto 0);
	variable ix: integer;
	begin
		v:=(others=>'0'); -- clear all bits by default in case we ask for more bits than there are in the byte array
		ix:=i'Right;
		for j in 0 to n-1 loop
			if i'Ascending then
				v(j):=i(ix-j/8)(j mod 8);
			else
				v(j):=i(ix+j/8)(j mod 8);
			end if;
		end loop;
		return v;
	end to_slv;

FUNCTION to_slv8_array(i:std_logic_vector) return slv8_array is -- split a slv in a slv8_array in the Big Endian order (result(0) is the MSB). The slv is treated as unsigned and is zero padded to the next multiple of 8 bits.
	variable N: integer := (i'LENGTH+7)/8;
	variable v: slv8_array(0 to N-1);
	variable ii: std_logic_vector(N*8-1 downto 0) := resize(i, N * 8); -- zero padded to multiple of 8 bits
	begin
		v:=(others=>(others=>'0')); -- clear all bytes by default
		for j in 0 to N-1 loop
			v(j):=ii((N-j)*8-1 downto (N-j)*8-8);
		end loop;
		return v;
	end to_slv8_array;

FUNCTION to_slv8_array(i:unsigned) return slv8_array is -- split a unsigned in a slv8_array. The SLV length must be multiples of 8 bits.
	begin
		return to_slv8_array(std_logic_vector(i));
	end to_slv8_array;

FUNCTION to_slv8_array_le(i:slv32_array) return slv8_array is -- split a slv32_array byte-wise in a slv8_array in the Little Endian order i(0)(7 downto 0)) is in result(0).
	variable N: integer := i'LENGTH; -- number of words
	variable v: slv8_array(0 to 4*N-1);
	begin
		for j in 0 to N-1 loop
			for k in 0 to 3 loop
				v(4*j+k):=i(j)(k*8+7 downto k*8);
			end loop;
		end loop;
		return v;
	end to_slv8_array_le;

FUNCTION to_ByteArray(i:slv8_array) return ByteArray is -- Convert slv8_array to ByteArray (for legacy compatibility).
	variable v:ByteArray(i'range);
	begin
		for j in i'range loop
			v(j):=i(j);
		end loop;
		return v;
	end to_ByteArray;

FUNCTION to_ByteArray(i:std_logic_vector) return ByteArray is -- split a slv in ia ByteArray.
	begin
		return to_ByteArray(to_slv8_array(i));
	end to_ByteArray;

FUNCTION to_ByteArray(i:unsigned) return ByteArray is -- split a unsigned in ia ByteArray. The SLV length must be multiples of 8 bits.
	begin
		return to_ByteArray(std_logic_vector(i));
	end to_ByteArray;

FUNCTION to_slv(i:ByteArray) return std_logic_vector is -- concatenate bytes in a ByteAray and return them as a STD_LOGIC_VECTOR
	begin
		return to_slv(i,8*i'Length);
	end to_slv;

FUNCTION to_slv(i:slv8_array) return std_logic_vector is -- concatenate bytes in a ByteAray and return them as a STD_LOGIC_VECTOR
	begin
		return to_slv(i,8*i'Length);
	end to_slv;

--	variable v:std_logic_vector(8*i'Length-1 downto 0);
--	variable ix: integer;
--	begin
--		ix:=i'Left;
--		for j in i'Length-1 downto 0 loop
--			v(8*j-1 downto 8*j):=i(ix);
--			if i'Ascending then
--				ix:=ix+1;
--			else
--				ix:=ix-1;
--			end if;
--		end loop;
--		return v;
--	end to_slv;


FUNCTION to_slv(i:std_logic) return std_logic_vector is -- converts a std_logic into a one element vector
	variable v: std_logic_vector(0 downto 0);
	begin
		v(0) := i;
		return v;
	end to_slv;

FUNCTION to_unsigned(i:std_logic) return unsigned is -- converts a std_logic into a one element unsigned
	variable v: unsigned(0 downto 0);
	begin
		v(0) := i;
		return v;
	end to_unsigned;

FUNCTION to_unsigned(i:ByteArray; n: integer) return unsigned is -- concatenated bytes in a ByteAray and return them as a unsigned
	begin
		return unsigned(to_slv(i,n));
	end to_unsigned;

FUNCTION to_unsigned(i:ByteArray) return unsigned is -- concatenated bytes in a ByteAray and return them as a unsigned
	begin
		return to_unsigned(i,8*i'Length);
	end to_unsigned;

FUNCTION to_unsigned(i:slv8_array; n: integer) return unsigned is -- concatenated bytes in a ByteAray and return them as a unsigned
	begin
		return unsigned(to_slv(i,n));
	end to_unsigned;

FUNCTION to_unsigned(i:slv8_array) return unsigned is -- concatenated bytes in a ByteAray and return them as a unsigned
	begin
		return to_unsigned(i,8*i'Length);
	end to_unsigned;

FUNCTION str(i:integer) return string is -- converts integer to a string. Allows expressions, contrary to to_string().
	begin
		return to_string(i);
	end str;

-- Return the Raw data capture frame header structure as a byte array
FUNCTION struct_to_bytes(s:FRAME_HEADER_STRUCT) return slv8_array is
	variable b: slv8_array(0 to FRAME_HEADER_BYTE_LENGTH - 1);
	variable w: std_logic_vector(8 * FRAME_HEADER_BYTE_LENGTH - 1 downto 0);
	begin
		w := s.PROBE_ID & s.STREAM_ID & s.SERIAL_FLAGS & s.FLAGS & s.TIMESTAMP;
		for i in 0 to FRAME_HEADER_BYTE_LENGTH-1 loop
			b(i) := w(8 * (FRAME_HEADER_BYTE_LENGTH - i) - 1 downto 8 * (FRAME_HEADER_BYTE_LENGTH - i - 1));
		end loop;
		return b;
	end struct_to_bytes;

-- FUNCTION word_to_struct(w: Word32Array) return FRAME_HEADER_STRUCT is
-- 	variable s : FRAME_HEADER_STRUCT;
-- 	begin
-- 		s.ID:=w(0)(31 downto 16);
-- 		s.FLAGS:=w(0)(15 downto 12);
-- 		s.WORD_LENGTH:=w(0)(11 downto 0);
-- 		s.TIMESTAMP:=w(1);
-- 		return s;
-- 	end word_to_struct;


FUNCTION struct_to_word(s:SHUFFLE_FRAME_HEADER_STRUCT) return slv32_array is
	variable w : slv32_array(0 to SHUFFLE_FRAME_HEADER_WORD_LENGTH-1);
	begin
		w(0):= (s.STREAM_ID & s.PROTOCOL_VERSION & s.HEADER_LENGTH_IN_WORDS & s.COOKIE );
		w(1):= (s.ENCODING & s.NUMBER_OF_FRAMES & s.NUMBER_OF_BINS & s.NUMBER_OF_ANTENNAS);
		w(2):= s.ANCILLARY_DATA;
		w(3):= s.TIMESTAMP;
		return w;
	end struct_to_word;

FUNCTION word_to_struct(w: slv32_array(0 to SHUFFLE_FRAME_HEADER_WORD_LENGTH-1) := (others=>(others=>'0'))) return SHUFFLE_FRAME_HEADER_STRUCT is
	-- We use an constrained array as parameter 'w' so we can use s=word_to_struct((word_index=>word)) to easily  extract fields from a single word in the strcuture
	variable s : SHUFFLE_FRAME_HEADER_STRUCT;
	begin
		-- Word 0
		s.STREAM_ID              := w(0)(31 downto 16);
		s.PROTOCOL_VERSION       := w(0)(15 downto 12);
		s.HEADER_LENGTH_IN_WORDS := w(0)(11 downto 8);
		s.COOKIE                 := w(0)(7 downto 0);
		-- Word 1
		s.ENCODING           := w(1)(31 downto 28);
		s.NUMBER_OF_FRAMES   := w(1)(27 downto 24);
		s.NUMBER_OF_BINS     := w(1)(23 downto 12);
		s.NUMBER_OF_ANTENNAS := w(1)(11 downto 0);
		-- Word 2
		s.ANCILLARY_DATA := w(2);
		-- Word 3
		s.TIMESTAMP := w(3);
		return s;
	end word_to_struct;

FUNCTION sel(b: BOOLEAN; if_true: std_logic; if_false: std_logic) return std_logic is
	begin
		if b then
			return if_true;
		else
			return if_false;
		end if;
	end sel;

FUNCTION sel(b: BOOLEAN; if_true: std_logic_vector; if_false: std_logic_vector) return std_logic_vector is
	begin
		if b then
			return if_true;
		else
			return if_false;
		end if;
	end sel;

FUNCTION sel(b: BOOLEAN; if_true: slv32_array; if_false: slv32_array) return slv32_array is
	begin
		if b then
			return if_true;
		else
			return if_false;
		end if;
	end sel;

FUNCTION sel(b: BOOLEAN; if_true: real; if_false: real) return real is
	begin
		if b then
			return if_true;
		else
			return if_false;
		end if;
	end sel;

FUNCTION sel(b: BOOLEAN; if_true: string; if_false: string) return string is
	begin
		if b then
			return if_true;
		else
			return if_false;
		end if;
	end sel;

FUNCTION sel(b: BOOLEAN; if_true: integer; if_false: integer) return integer is
	begin
		if b then
			return if_true;
		else
			return if_false;
		end if;
	end sel;

FUNCTION sel(b: BOOLEAN; if_true: time; if_false: time) return time is
	begin
		if b then
			return if_true;
		else
			return if_false;
		end if;
	end sel;

FUNCTION sel(b: std_logic; if_true: std_logic_vector; if_false: std_logic_vector) return std_logic_vector is
	begin
		if b='1' then
			return if_true;
		elsif b='0' then
			return if_false;
		else
			report "Test value in sel(test_value, if_true, if_false) is neither '0' or '1'" severity failure;
			return if_false;
		end if;
	end sel;

function repeat( V: std_logic_vector; N: natural) return std_logic_vector is
	constant L: natural := V'length;
	variable result: std_logic_vector(0 to N*L - 1);
	begin
		for i in 0 to N-1 loop
			result(i*L to i*L + L - 1) := V;
		end loop;
		return result;
	end repeat;

--Returns TRUE if any bit is '1'
function any_one(v: std_logic_vector) return boolean is
	begin
		return or(v) = '1';
	end function;

--Returns TRUE if any bits is '1'
function any_one(v: unsigned) return boolean is
	begin
		return or(v) = '1';
	end function;

--Returns TRUE if any bit is '0'
function any_zero(v: std_logic_vector) return boolean is
	begin
		return and(v) = '0';
	end function;

--Returns TRUE if any bit is '0'
function any_zero(v: unsigned) return boolean is
	begin
		return and(v) = '0';
	end function;

--Returns TRUE if all bits are '1'
function all_ones(v: std_logic_vector) return boolean is
	begin
		return and(v) = '1';
	end function;


--Returns TRUE if all bits are '1'
function all_ones(v: unsigned) return boolean is
	begin
		return and(v) = '1';
	end function;

--Returns TRUE if all bits are 'o'
function all_zeros(v: std_logic_vector) return boolean is
	begin
		return or(v) = '0';
	end function;


--Returns TRUE if all bits are 'o'
function all_zeros(v: unsigned) return boolean is
	begin
		return or(v) = '0';
	end function;

--Returns the log2 of a integer as a real value
function log2(v: integer) return real is
	begin
		return log2(real(v));
	end function;

--Returns the log2 of a integer as an integer
function integer_log2(v: integer) return integer is
	begin
		return integer(log2(real(v)));
	end function;

--Returns the log2 of a real as an integer
function integer_log2(v: real) return integer is
	begin
		return integer(log2(v));
	end function;

--! Compute the number of bits needed to represent `len` values (from 0 to len-1)
function width(len: integer) return integer is
	begin
		return integer(ceil(log2(real(len))));
	end function;

--! Compute the number of bits needed to represent 'value'
function bitwidth(value: integer) return integer is
	begin
		return integer(ceil(log2(real(value+1))));
	end function;

function shift_left(i:std_logic_vector; n: integer) return std_logic_vector is  -- shift left a STD_LOGIC_VECTOR
	begin
		return std_logic_vector(shift_left(unsigned(i), n));
	end function;


function shift_left(ARG:slv8_array; COUNT: natural) return slv8_array is -- shift left a byte array
	constant ARG_L: INTEGER := ARG'LENGTH-1;
	alias XARG: slv8_array(ARG_L downto 0) is ARG;
	variable RESULT: slv8_array(ARG_L downto 0) := (others=>(others => '0'));
begin
	if COUNT <= ARG_L then
		RESULT(ARG_L downto COUNT) := XARG(ARG_L-COUNT downto 0);
	end if;
	return RESULT;
end function;

function shift_right(i:std_logic_vector; n: integer) return std_logic_vector is  -- shift right a STD_LOGIC_VECTOR with zero padding on the left
	begin
		return std_logic_vector(shift_right(unsigned(i), n));

	end function;


function shift_right(x:slv_array)  return slv_array is
	variable r: slv_array(x'RANGE);
	begin
	r(x'LEFT-1 downto 0) := x(x'LEFT downto 1);
	r(x'LEFT) := (others=>'0');
	return r;
end function;

function shift_right(x:slv2_array)  return slv2_array is
	variable r: slv2_array(x'RANGE);
	begin
	r(x'LEFT-1 downto 0) := x(x'LEFT downto 1);
	r(x'LEFT) := (others=>'0');
	return r;
end function;

function shift_right(x:slv3_array)  return slv3_array is
	variable r: slv3_array(x'RANGE);
	begin
	r(x'LEFT-1 downto 0) := x(x'LEFT downto 1);
	r(x'LEFT) := (others=>'0');
	return r;
end function;

function shift_right(x:slv4_array)  return slv4_array is
	variable r: slv4_array(x'RANGE);
	begin
	r(x'LEFT-1 downto 0) := x(x'LEFT downto 1);
	r(x'LEFT) := (others=>'0');
	return r;
end function;


function cmplx(re, im:integer) return complex is -- Create a complex value out of two integer values
begin
	return cmplx(real(re), real(im));
end function;

function cmplx(re, im:signed) return complex is -- Create a complex value out of two signed values
begin
	return cmplx(real(to_integer(re)), real(to_integer(im)));
end function;

PROCEDURE axis32_write_buffer(buffer_in: in Word32Array; signal stream_out: out AXIS32_DAT_STRUCT; signal clk: in std_logic) is
	variable i : integer:=0;
	begin
		for i in 0 to buffer_in'LENGTH-1 loop
			stream_out.TDATA<=buffer_in(i);
			stream_out.TVALID<='1';
			if i=buffer_in'LENGTH-1 then
				stream_out.TLAST<='1';
			else
				stream_out.TLAST<='0';
			end if;
			wait until rising_edge(CLK);
			wait for 1 ps; -- make sure the other processes do not see the changes on the same clock
--		end if; -- CLK
		end loop;
--			if i=buffer_in'LENGTH then
--		wait until rising_edge(CLK);
--		wait for 1 ps; -- make sure the other processes do not see the changes on the same clock
		stream_out.TVALID<='0';
--			return;
--			end if;
--			i:=i+1;
end procedure;

------------------------
-- RPM-related functions
------------------------


-- Converts a rpm_coord struct into a "XxYy" string for use in RPM-related attributes
function rpm_to_string(rpm: rpm_coord_struct) return string is
begin
	return "X" & integer'IMAGE(rpm.x) & "Y" & integer'IMAGE(rpm.y);
end function rpm_to_string;



--type corr44_rpm_coord_struct is record
--	DSP: rpm_coord_struct_array(0 to NUMBER_OF_CMACS_MAX -1);
--	BRAM: rpm_coord_struct_array(0 to NUMBER_OF_CMACS_MAX -1);
--end record;

-- Returns a structure that defines the layout of CORR44 core expressed as the relative RPM position of the CMAC44 correlator elements in the fabric
--
--    N_CHAN (integer): Number of inputs to correlate
--    layout (string): Layout to use
--
-- For layout = "BDDB" and layout="DBBD", the CORR44 layout is implemented as two columns of DSPs with their associated two columns of BRAMs.
-- For a N-channel correlator, each CORR44 is N DSP tiles high, or 2*N DSP high.
-- The layout can be provided for columns ordered as BRAM-DSP-DSP-BRAM (layout="BDDB") or BRAM-DSP-DSP-BRAM (layout="DBBD").
-- In the first case, the origin (0,0) refer to a FIFO. In the second case, it refers to a DSP.
function get_cmac44_rpm_coords_struct_array(platform_id: integer; N_CHAN: integer; layout:string) return cmac44_rpm_coord_struct_array is
 	variable rpm: cmac44_rpm_coord_struct_array;
 	variable fpga_family: integer;
 	variable pf_info: PLATFORM_INFO_STRUCT;
 	variable DSP_XL, DSP_XR, FIFO_XL, FIFO_XR, DSP_Y0, FIFO_Y0: integer;
begin


	pf_info := PLATFORM_INFO(platform_id);

	if platform_id = PLATFORM_ID_MGK7MB then

	 	--DSP_X0L:=361;
	 	--DSP_X0R:=381;
	 	--DSP_X1L := 425;
	 	--DSP_X1R := 473;
	 	--FIFO_X0L := 350;
	 	--FIFO_X0R := 394;
	 	--BRAM_X1L := 438;
	 	--BRAM_X1R := 462;
	 	--DSP_Y0 := 0;
	 	--DSP_Y1 := DSP_Y0 + DSP_TILE_DELTA_Y*(N+1); -- :=170 -- A corr44 is two columns of (N+1) CMAC44, each one being DSP tile high
	 	--DSP_Y2 := 450;
	 	--DSP_Y3 := DSP_Y2 + DSP_TILE_DELTA_Y*(N+1); -- =620

	 	-- Slice coordinates (RPM_GRID not defined).
	 	-- Does not work: it says capture_bram0 is not on a RAMB site
	 	--DSP_X0L:=8;
	 	--DSP_X0R:=9;
	 	--DSP_X1L := 10;
	 	--DSP_X1R := 11;
	 	--FIFO_X0L := 8;
	 	--FIFO_X0R := 9;
	 	--BRAM_X1L := 10;
	 	--BRAM_X1R := 11;
	 	--DSP_Y0 := 0;
	 	--DSP_Y1 := DSP_Y0 + DSP_TILE_DELTA_Y*(N+1); -- :=170 -- A corr44 is two columns of (N+1) CMAC44, each one being DSP tile high
	 	--DSP_Y2 := 36;
	 	--DSP_Y3 := DSP_Y2 + DSP_TILE_DELTA_Y*(N+1); -- =620

	 	-- using RPM_GRID="GRID" (uses RPM_X and RPM_Y)
	 	-- Here we use the RPM_X and RPM_Y cooordinates of the leftmost pair of DSP/BRAM columns (BRAM-DSP-DSP-BRAM)
	 	--DSP_X0L:=45-45;
	 	--DSP_X0R:=65-45;
	 	--DSP_X1L := 121-45;
	 	--DSP_X1R := 141-45;
	 	--FIFO_X0L := 34-34;
	 	--FIFO_X0R := 78-34;
	 	--BRAM_X1L := 110-34;
	 	--BRAM_X1R := 154-34;
	 	if layout="BDDB" then
		 	FIFO_XL := 350-350; -- relative location of the FIFO in left column. This is our origin point.  Should be 0.
		 	DSP_XL := 361-350; -- relative location of dsp1 on leftmost column.
		 	DSP_XR := 381-350; -- relative location of dsp1 on rightmost column
		 	FIFO_XR := 394-350;
		elsif layout="DBBD" then
		 	DSP_XL := 425-425; -- relative location of dsp1 on leftmost column. This is our origin point.  Should be 0.
		 	FIFO_XL := 438-425; -- relative location of the FIFO in left column.
		 	FIFO_XR := 462-425;
		 	DSP_XR := 473-425; -- relative location of dsp1 on rightmost column
		else
			assert FALSE report "Invalid CORR44 layout CONFIG string";
		end if;

	 	DSP_Y0 := 0; -- should be zero.
	 	FIFO_Y0 := 0; -- position of the FIFO, which must be at the bottom


	elsif platform_id = PLATFORM_ID_ZCU111 or platform_id = PLATFORM_ID_CRS then


	 	if layout="BDDB" then
		 	FIFO_XL := 3360; -- relative location of the FIFO in left column. This is our origin point.
		 	DSP_XL := 3520; -- relative location of dsp1 on leftmost column.
		 	DSP_XR := 3592; -- relative location of dsp1 on rightmost column
		 	FIFO_XR := 3664;
		elsif layout="DBBD" then
		 	DSP_XL := 2840; -- relative location of dsp1 on leftmost column. This is our origin point.
		 	FIFO_XL := 2872; -- relative location of the FIFO in left column.
		 	FIFO_XR := 3048;
		 	DSP_XR := 3120; -- relative location of dsp1 on rightmost column
		else
			assert FALSE report "Invalid CORR44 layout CONFIG string";
		end if;

		FIFO_XL := FIFO_XL - FIFO_XL;
		DSP_XL := DSP_XL - FIFO_XL;
		DSP_XR := DSP_XR - FIFO_XL;
		FIFO_XR := FIFO_XR - FIFO_XL;
	 	DSP_Y0 := 2; -- bottom.
	 	FIFO_Y0 := 2; -- position of the FIFO, which must be at the bottom


		--assert N_CHAN=8 report "Unsupported N for this platform" severity ERROR;
	 	--DSP_XL := 0;--3;
	 	--DSP_XR :=1;--4;
	 	--FIFO_XL  := 0;--2;
	 	--FIFO_XR  := 1;--3;
	 	--DSP_Y0  := 0;--72;
	 	--FIFO_Y0  := 0;--72;

		--	for i in 0 to NUMBER_OF_CORRELATORS_MAX-1 loop
		--	rpm(i).DSP1 := (DSP_XL;
		--	rpm(i).LEFT_BRAM_X   := FIFO_XL;
		--	rpm(i).RIGHT_DSP_X   := DSP_XR;
		--	rpm(i).RIGHT_BRAM_X  := FIFO_XR;
		--	rpm(i).DSP_BOTTOM_Y  := DSP_Y0 + pf_info.DSP_TILE_DELTA_RPM_Y*(N_CHAN+1)*i; -- Each CORR44 is (N+1) DSP tile high
		--	rpm(i).BRAM_BOTTOM_Y := FIFO_Y0 + pf_info.DSP_TILE_DELTA_RPM_Y*(N_CHAN+1)*i; --
		--end loop;
		--return rpm;

	else
		assert FALSE report "UNSUPPORTED PLATFORM" severity ERROR;
		return rpm;
	end if;

	-- The code below assumes a two column layout
	for i in 0 to NUMBER_OF_CMACS_MAX-1 loop
		rpm(i).DSP1 := (X => sel((i mod 2)=0, DSP_XL, DSP_XR), Y=> DSP_Y0 + (i/2) * pf_info.DSP_TILE_DELTA_RPM_Y); -- Each CMAC44 is 1 DSP tile (2 DSP) high
		rpm(i).DSP2 := (X => sel((i mod 2)=0, DSP_XL, DSP_XR), Y=>  DSP_Y0 + (i/2) * pf_info.DSP_TILE_DELTA_RPM_Y + pf_info.DSP_BEL_DELTA_RPM_Y);
		rpm(i).FIFO := (X => sel((i mod 2)=0, FIFO_XL, FIFO_XR), Y => FIFO_Y0 + (i/2) * pf_info.BRAM_TILE_DELTA_RPM_Y);
		rpm(i).BRAM := (X => sel((i mod 2)=0, FIFO_XL, FIFO_XR), Y => FIFO_Y0 + (i/2) * pf_info.BRAM_TILE_DELTA_RPM_Y + pf_info.BRAM_BEL_DELTA_RPM_Y);
	end loop;
	return rpm;

end function get_cmac44_rpm_coords_struct_array;



-- Return the platform-specific layout and locations of the corr44 cores
--
function get_corr44_rloc_origins_struct_array(platform_id:integer; N_CHAN:integer) return corr44_rloc_origins_struct_array is
 	variable locs: corr44_rloc_origins_struct_array;
 	variable CORR44_DELTA_Y, X0, X1, Y0, Y1, Y2, Y3: integer;

begin

	CORR44_DELTA_Y := PLATFORM_INFO(platform_id).DSP_TILE_DELTA_RPM_Y * (N_CHAN+1);

	if platform_id = PLATFORM_ID_MGK7MB then
		-- This is the absolute locations of the CORR44 cores on the 7K420.
		-- Coordinates are in the RPM_GRID system. They refer to the bottom-left corner of the CORR44, which is a BRAM/FIFO.
		-- Coordinates provide dby this function must therefore only refer only to FIFO18E1 sites.
		-- See RPM_X and RPM_Y properties of BRAM sites for those coordinates (in the Vivado Device view).
		--
		-- The cores are placed in a 4-high by 2-wide array. A first 4 are in
		-- a 2x2 array vertically spanning the lower 7 clock regions, and the
		-- remaining 4 span the upper 7 clock regions.
		--
		-- On the Kintex 7, the CMACS are located at the right of the chip,
		-- and unfortunately, the organization of the DSP and BRAM columns is
		-- not the same for the leftmost and righmost CMAC44s, so we have so
		-- specify different CMAC44 layouts. In the left column, we have a
		-- BRAM-DSP-DSP-BRAM columns ("BDDR" layout), whereas we have a
		-- DSP-BRAM-BRAM-DSP columns (layout "DBBD" in the right column).
		--
		-- A 16-channel CORR44 is 17 DSP tiles (34 DSPs) high. There are 10
		-- DSPs per clock region. Two CORR44 are 68 DSP high. 7 clock regions
		-- provide 70 DSPs. Nice fit.

	 	X0 := 350; -- Left colums, BDDB layout, FIFO site
	 	X1 := 425; -- Right column, DBBD layout, DSP site
	 	-- Lower CORR44s
	 	Y0 := 0;
	 	Y1 := Y0 + CORR44_DELTA_Y; -- :=170 -- A corr44 is two columns of (N+1) CMAC44, each one being DSP tile high
	 	-- Upper CORR44s
	 	Y2 := 450;
	 	Y3 := Y2 + CORR44_DELTA_Y; -- =620

		locs := (
			0 => (layout => "BDDB", loc => (X0, Y0)),
			1 => (layout => "DBBD", loc => (X1, Y0)),
			2 => (layout => "BDDB", loc => (X0, Y1)),
			3 => (layout => "DBBD", loc => (X1, Y1)),
			4 => (layout => "BDDB", loc => (X0, Y2)),
			5 => (layout => "DBBD", loc => (X1, Y2)),
			6 => (layout => "BDDB", loc => (X0, Y3)),
			7 => (layout => "DBBD", loc => (X1, Y3)),
			others => (layout => "unknown", loc => (-1,-1))
			);
		return locs;
	else -- if platform_id
		assert FALSE report "UNSUPPORTED PLATFORM for correlator" severity ERROR;
	end if; -- if platform_id

end function;



end chFPGA_Package;
