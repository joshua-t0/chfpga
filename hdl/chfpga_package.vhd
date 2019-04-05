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
subtype slv144 is std_logic_vector(143 downto 0);
type ByteArray8 is array (0 to 7) of std_logic_vector(7 downto 0);
type ByteArray is array (NATURAL RANGE <>) of std_logic_vector(7 downto 0);
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
type slv144_array is array (NATURAL RANGE <>) of std_logic_vector(143 downto 0);
type Word3Array is array (NATURAL RANGE <>) of std_logic_vector(2 downto 0);
type Word32Array is array (NATURAL RANGE <>) of std_logic_vector(31 downto 0);
type Word33Array is array (NATURAL RANGE <>) of std_logic_vector(32 downto 0);
type BoolArray is array (natural range <>) of BOOLEAN;
type u16_array is array (NATURAL RANGE <>) of unsigned(15 downto 0);
type u13_array is array (NATURAL RANGE <>) of unsigned(12 downto 0);
type u4_array is array (NATURAL RANGE <>) of unsigned(3 downto 0);
type u8_array is array (NATURAL RANGE <>) of unsigned(7 downto 0);
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


-- Platform related constants
constant PLATFORM_ID_ML605: integer :=0;
constant PLATFORM_ID_KC705: integer :=1;
constant PLATFORM_ID_MGK7MB_REV0: integer :=2;
constant PLATFORM_ID_MGK7MB_REV2: integer :=3;
constant FPGA_SERIES_LIST: IntegerArray(0 to 2):=(6,7,7); --! 6 for VIRTEX6, 7 for VIRTEX/KINTEX7
--constant SIM_DEVICE_LIST: StringArray(0 to 1):=("VIRTEX6","7SERIES");
-- Hardware-related constants
constant NUMBER_OF_CHANNELIZERS_MAX: INTEGER :=16; -- Maximum number of antennas supported by the system
constant NUMBER_OF_ADCS_MAX: INTEGER :=16; -- Maximum number of antennas supported by the system
--constant NUMBER_OF_ANTENNAS: INTEGER :=NUMBER_OF_ANTENNAS_MAX; -- Number of antennas actually implemented. If changed, the UCF file needs to be changed to avoid IOSTANDARD errors.
constant NUMBER_OF_CORRELATORS_MAX: INTEGER :=8; -- Maximum number of correlators supported by the system



--! Basic system configuration
--! These constants are defined globally in this package because the CHAN and CORR modules cannot be implemented
--! out of contect if they have generics.
constant GLOBAL_IMPLEMENT_FFT: boolean := TRUE;
constant GLOBAL_NUMBER_OF_CHANNELIZERS_TO_CORRELATE: integer := 8;
constant GLOBAL_SIM: boolean := FALSE;
constant GLOBAL_NUMBER_OF_GPU_LINKS: integer := 8; --! (0- NUMBER_OF_CHANNELIZERS) Number of 10Gb Ethernet links to connecto to the GPUs
constant GLOBAL_NUMBER_OF_GPU_REFCLKS: integer := 1; --! Number of Reference clocks provided for the 10GE links to the GPU
constant GLOBAL_GPU_CHANNEL_QUAD: IntegerArray := (0 to 3=> 0, 4 to 7=> 1); -- Channels 0-3 use QUAD0, Channels 4-7 use QUAD1
constant GLOBAL_GPU_QUAD_REFCLK: IntegerArray := (0 to 1=>0); -- Both QUAD0 and QUAD1 use refclk(0)




constant FRAME_LENGTH: integer:= 2048; --! 2048 time samples per frame (1024 frame samples per frame)
constant LOG2_FRAME_LENGTH: integer :=11; --! Number of time samples per frame. 2^11 = 2048 time samples per frame
constant LOG2_FREQ_SAMPLES_PER_FRAME: integer :=LOG2_FRAME_LENGTH-1; --! Number of frequency samples per frame. 1/2 of the time samples as we discard negative frequencies
constant LOG2_WORDS_PER_FRAME: integer :=LOG2_FRAME_LENGTH-2; --! Number of words per frame. One word is 4 8-bit time samples or 2 8+8-bits frequency samples.

--	Control bus parameters
constant CTRL_CMD_BYTE_LENGTH: integer :=3; --! Number of bytes in the command word
constant CTRL_CMD_WORD_WIDTH: integer :=CTRL_CMD_BYTE_LENGTH*8; --! Number of bits in the command word
constant CTRL_CMD_BYTE_COUNT_WIDTH: integer :=2; --! number of bits requird to count the number of bytes in a command
constant CTRL_CMD_DIR_BIT: integer:=23;
constant CTRL_CMD_INCR_BIT: integer:=22;
constant CTRL_CMD_COUNT_WIDTH: integer:=2;
constant CTRL_CMD_COUNT_LSB: integer:=20;
type CTRL_CMD_COUNT_RANGE is range (CTRL_CMD_COUNT_LSB+CTRL_CMD_COUNT_WIDTH-1) downto CTRL_CMD_COUNT_LSB;
constant CTRL_ADDR_WIDTH: INTEGER :=20; --! Total numbe rof address bits. The address is in the LSBs of the command word (i.e. downto 0)
--constant CTRL_PORT_NUMBER_WIDTH: INTEGER :=5; --! Number of address bits used for port number
--constant CTRL_MODULE_NUMBER_WIDTH: INTEGER :=3; --! Number of address bits used for module number
--constant CTRL_MODULE_ADDR_WIDTH: INTEGER :=CTRL_ADDR_WIDTH-CTRL_PORT_NUMBER_WIDTH-CTRL_MODULE_NUMBER_WIDTH; -- Number of address bits used within a module
constant CTRL_MODULE_ADDR_WIDTH: INTEGER := 10; -- Number of address bits used within a module
type CTRL_ADDR_RANGE is range (CTRL_ADDR_WIDTH-1) downto 0;

-- subtype CTRL_PORT_NUMBER_RANGE is integer RANGE (CTRL_ADDR_WIDTH-1) downto CTRL_ADDR_WIDTH-CTRL_PORT_NUMBER_WIDTH; --
-- subtype CTRL_MODULE_NUMBER_RANGE is integer RANGE (CTRL_ADDR_WIDTH-CTRL_PORT_NUMBER_WIDTH-1) downto CTRL_ADDR_WIDTH-CTRL_PORT_NUMBER_WIDTH-CTRL_MODULE_NUMBER_WIDTH; --

-- AXI4 STREAMING data structure used for the control system (Command and Reply buses)
type AXIS8_DAT_STRUCT is -- control/data bus used to communicate from  master to slave
	record
		DUMMY: std_logic; -- needed to cirvumvent simulator bug on VIvado 2012.4 and 2013.1. Otherwise the control bus doesnot work in simulation.
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
		PROBE_ID: std_logic_vector(7 downto 0); -- 1 byte, user-defined. Generally a cookie, but can be used by user to convey more info (e.g. extend the number of channels)
		STREAM_ID: std_logic_vector(15 downto 0); --! 16 bit value used to uniquely define the data stream and lookup . Defined as listed below:
			--! Bits 15-12 (4 bits). Software defined. Identifies the data source within the internal pipeline (1st shuffle, 2nd shufle, raw data etc.).
			--! Bits 12-8 (4 bits). Software defined. Identifies the crate_number.
			--! Bits 7-4 (4 bits). Software defined. Identifies slot number (zero-based).
			--! Bits 3-0 (4 bits). Hardware defined. Identifies the 10Gb/s lane (1st shuffle has 15 lanes, 2nd shuffle has 4 lanes, GPU link has 8 lanes).
		SERIAL_FLAGS: std_logic_vector(3 downto 0); -- last 4 bits of the TUSER_SERIAL_FLAGS_BIT field (meaning depends on the data source)
		FLAGS: std_logic_vector(3 downto 0); -- 4 bits: aggregated TUSER bits at the input source
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
function repeat( V: std_logic_vector; N: natural) return std_logic_vector; --! Concatenates a vector N times
function width(len: integer) return integer; --! computes the minimum number of bits needed to represent len-1
function bitwidth(value: integer) return integer;--! Computes the minimum number of bits needed to represent value
function shift_left(i:std_logic_vector; n: integer) return std_logic_vector; -- shift left a STD_LOGIC_VECTOR
function shift_left(ARG:slv8_array; COUNT: natural) return slv8_array; -- shift left a byte array
function shift_right(i:std_logic_vector; n: integer) return std_logic_vector; -- shift right a STD_LOGIC_VECTOR with zero padding from the left
function cmplx(re, im:integer) return complex; -- Create a complex value out of two integer values
function cmplx(re, im:signed) return complex; -- Create a complex value out of two signed values


FUNCTION struct_to_bytes(s:FRAME_HEADER_STRUCT) return slv8_array; -- Converts a FRAME_HEADER structure into a word array
-- function word_to_struct(w: Word32Array) return FRAME_HEADER_STRUCT; -- Converts a word array into a FRAME_HEADER structure

function struct_to_word(s:SHUFFLE_FRAME_HEADER_STRUCT) return slv32_array; -- Converts a SHUFFLE_FRAME_HEADER structure into a word array
function word_to_struct(w: slv32_array(0 to SHUFFLE_FRAME_HEADER_WORD_LENGTH-1):= (others=>(others=>'0'))) return SHUFFLE_FRAME_HEADER_STRUCT; -- Converts a word array into a SHUFFLE_FRAME_HEADER structure

--FUNCTION resize(s:signed; constant size:integer) return signed;
PROCEDURE axis32_write_buffer(buffer_in: in Word32Array; signal stream_out: out AXIS32_DAT_STRUCT; signal clk: in std_logic);



----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
-- CHAN: Channelizer module
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
COMPONENT CHAN is
	PORT (

		in_dat_tdata: in slv32;
		in_dat_tvalid: in std_logic;
		in_dat_tlast: in std_logic;
		in_dat_tuser: in slv4;
		in_reset: in std_logic; --! Resets all the antenna processor modules, except ADCDAQ. Must be synchronous to ANT_CLK.
		in_clk : in  STD_LOGIC; --! Data processing clock for all the Antenna processing pipeline

		-- Data processing clock

		-- Output interface
--		OUT_DAT : out  AXIS32_DAT_STRUCT; --! Output data stream
		out_dat_tdata: out slv32;
		out_dat_tvalid: out std_logic;
		out_dat_tlast: out std_logic;
		out_dat_tuser: out slv4;
		out_clk: in std_logic;
		out_reset: in std_logic;

		-- System level signals
		TRIG : in  STD_LOGIC; --! Global trigger/capture signal. Indicates to SRCSEL when to start flagging the incoming frames the data capture.
--		ADC_DAQ_BUFR_SYNC: in STD_LOGIC;
--		ADC_DAQ_SERDES_SYNC: in STD_LOGIC;
		lane_monitor: out std_logic_vector(3 downto 0);

		-- Control interface (command and reply stream buses)
--		CTRL_CMD_IN_DAT: in AXIS8_DAT_STRUCT;
--		CTRL_CMD_IN_RDY: out AXIS8_RDY_STRUCT;
		ctrl_cmd_tdata: in std_logic_vector(7 downto 0);
		ctrl_cmd_tvalid: in std_logic;
		ctrl_cmd_tlast: in std_logic;
		ctrl_cmd_tready: out std_logic;

--		CTRL_RPLY_OUT_DAT: out AXIS8_DAT_STRUCT;
--		CTRL_RPLY_OUT_RDY: in AXIS8_RDY_STRUCT;
		ctrl_rply_tdata: out std_logic_vector(7 downto 0);
		ctrl_rply_tvalid: out std_logic;
		ctrl_rply_tlast: out std_logic;
		ctrl_rply_tready: in std_logic;

		CTRL_CLK : in  STD_LOGIC;
		CTRL_RST : in  STD_LOGIC; --! Global asynchronous RESET, activated at power-up.

		-- Control interface to be hooked-up  to the corresponding ADCDAQ module
		-- ADC_CMD_DAT: out AXIS8_DAT_STRUCT;
		-- ADC_CMD_RDY: in AXIS8_RDY_STRUCT;
		-- ADC_RPLY_DAT: in AXIS8_DAT_STRUCT;
		-- ADC_RPLY_RDY: out AXIS8_RDY_STRUCT;
		adc_cmd_tdata: out std_logic_vector(7 downto 0);
		adc_cmd_tvalid: out std_logic;
		adc_cmd_tlast: out std_logic;
		adc_cmd_tready: in std_logic;

--		adc_RPLY_OUT_DAT: out AXIS8_DAT_STRUCT;
--		adc_RPLY_OUT_RDY: out AXIS8_RDY_STRUCT;
		adc_rply_tdata: in std_logic_vector(7 downto 0);
		adc_rply_tvalid: in std_logic;
		adc_rply_tlast: in std_logic;
		adc_rply_tready: out std_logic;

		-- Data Probe interface
		-- PRB_DAT: out AXIS8_DAT_STRUCT; --! Data capture bus (AXI4 Streaming)
		-- PRB_RDY: in AXIS8_RDY_STRUCT;
		prb_tdata: out std_logic_vector(7 downto 0);
		prb_tvalid: out std_logic;
		prb_tlast: out std_logic;
		prb_tready: in std_logic;


		PRB_CLK : in  STD_LOGIC  --! Data capture clock

		-- System
		);
end COMPONENT;




COMPONENT CORR is
	GENERIC (
		IMPLEMENT_CORR: BOOLEAN :=TRUE;
		NUMBER_OF_CHANNELIZERS_TO_CORRELATE: INTEGER := GLOBAL_NUMBER_OF_CHANNELIZERS_TO_CORRELATE;
		SIM: boolean:=GLOBAL_SIM
	);

	PORT (
		-- Antenna processor output interface (non-blocking)
		IN_DAT : in  AXIS32_DAT_STRUCT; --! Array of input data stream containing the channelized data from every antenna processor
		IN_CLK : in std_logic; --! Input clock channelized data.
		IN_RESET: in std_logic; --! Reset synchronous to the input clock

		-- Data Probe output interface (blocking)
		PRB_DAT : out  AXIS8_DAT_STRUCT; --! Output data stream containing the integrated values. Packaged in 8 bit stream for transmission over the Ethernet.
		PRB_RDY : in  AXIS8_RDY_STRUCT; --! Handshaking for the output data stream to control the data flow
		PRB_CLK : in STD_LOGIC; --! Output data stream clock

		-- Control and reply streams
		CMD_DAT: in AXIS8_DAT_STRUCT;
		CMD_RDY: out AXIS8_RDY_STRUCT;
		RPLY_DAT: out AXIS8_DAT_STRUCT;
		RPLY_RDY: in AXIS8_RDY_STRUCT;
		CTRL_CLK : IN std_logic; -- control clock
		CTRL_RST : in STD_LOGIC
			);


end COMPONENT;

COMPONENT xge_udp_mac is
	generic (
		NUMBER_OF_CHANNELS: integer := GLOBAL_NUMBER_OF_GPU_LINKS;
		NUMBER_OF_REFCLK: integer:= GLOBAL_NUMBER_OF_GPU_REFCLKS;
		CHANNEL_QUAD: integerArray := GLOBAL_GPU_CHANNEL_QUAD; --! Indicates which quad is associated each channel. The QUAD number is an integer between 0 and N-1, where N is the total number of quads used.
		QUAD_REFCLK: integerArray := GLOBAL_GPU_QUAD_REFCLK; --! Indicates which refclk is associated with each QUAD (N integers from 0 to NUMBER_OF_REFCLK-1).
		DEFAULT_MAC_SRC_ADDR: slv48_array := (0 to GLOBAL_NUMBER_OF_GPU_LINKS-1=> X"123456789ABC");
		DEFAULT_MAC_DEST_ADDR: slv48_array := (0 to GLOBAL_NUMBER_OF_GPU_LINKS-1=> X"FFFFFFFFFFFF");
		DEFAULT_IP_SRC_ADDR: slv32_array := (0 to GLOBAL_NUMBER_OF_GPU_LINKS-1=> X"0A0A0A0B");
		DEFAULT_IP_DEST_ADDR: slv32_array := (0 to GLOBAL_NUMBER_OF_GPU_LINKS-1=> X"0A0A0A0A");
		DEFAULT_IP_DEST_PORT: slv16_array := (0 to GLOBAL_NUMBER_OF_GPU_LINKS-1=> X"A028")
		);
	port (
		tx_p: out std_logic_vector(0 to NUMBER_OF_CHANNELS-1);
		tx_n: out std_logic_vector(0 to NUMBER_OF_CHANNELS-1);
		rx_p: in std_logic_vector(0 to NUMBER_OF_CHANNELS-1);
		rx_n: in std_logic_vector(0 to NUMBER_OF_CHANNELS-1);
		refclk_p : in std_logic_vector(0 to NUMBER_OF_REFCLK-1); --156.250 clock
		refclk_n : in std_logic_vector(0 to NUMBER_OF_REFCLK-1);

		clk156_div2: out std_logic; -- Data clock generated from MMCM
		userclk_div2: out std_logic; -- data clock geterated from GTX
		refclk_div2: out std_logic; -- 156.25 MHz reference clock

		s_axis_tx_tdata: in slv32_array(0 to NUMBER_OF_CHANNELS-1);
		s_axis_tx_tvalid: in std_logic_vector(0 to NUMBER_OF_CHANNELS-1);
		s_axis_tx_tlast: in std_logic_vector(0 to NUMBER_OF_CHANNELS-1);
		s_axis_tx_tready: out std_logic_vector(0 to NUMBER_OF_CHANNELS-1);


		-- Control and reply streams
		CMD_DAT: in AXIS8_DAT_STRUCT;
		CMD_RDY: out AXIS8_RDY_STRUCT;
		RPLY_DAT: out AXIS8_DAT_STRUCT;
		RPLY_RDY: in AXIS8_RDY_STRUCT;
		CTRL_CLK : IN std_logic; -- control clock
		CTRL_RST : in std_logic;

		clk: in std_logic; --! AXI-S data clock. Not related to the 10G Ethernet clocks.
		areset: in std_logic --! asynchronous reset
	 );
end COMPONENT;

----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
-- SP605_GMII_PHY
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------



-- COMPONENT ML605_GMII_PHY
-- 	PORT(
-- 		PHY_RXCLK : IN std_logic;
-- 		PHY_TXCLK : IN std_logic;
-- 		PHY_RXCTRL_RXDV : IN std_logic;
-- 		PHY_RXD : IN std_logic_vector(7 downto 0);
-- 		GMII_RESET_L : IN std_logic;
-- 		GMII_TXC_GTXCLK : IN std_logic;
-- 		GMII_TXEN : IN std_logic;
-- 		GMII_TXER : IN std_logic;
-- 		GMII_TXD : IN std_logic_vector(7 downto 0);
-- 		PHY_RESET_L : OUT std_logic;
-- 		PHY_TXER : OUT std_logic;
-- 		PHY_TXC_GTXCLK : OUT std_logic;
-- 		PHY_TXEN : OUT std_logic;
-- 		PHY_TXD : OUT std_logic_vector(7 downto 0);
-- 		GMII_RXCLK : OUT std_logic;
-- 		GMII_TXCLK : OUT std_logic;
-- 		GMII_RXCTRL_RXDV : OUT std_logic;
-- 		GMII_RXD : OUT std_logic_vector(7 downto 0)
-- 		);
-- 	END COMPONENT;


----------------------------------------------------------------------------------
-- GMII_to_SFP
----------------------------------------------------------------------------------

	-- COMPONENT GMII_to_SFP
	-- PORT(
	-- 	gmii_tx_clk0 : IN std_logic;
	-- 	gmii_txd0 : IN std_logic_vector(7 downto 0);
	-- 	gmii_tx_en0 : IN std_logic;
	-- 	gmii_tx_er0 : IN std_logic;
	-- 	configuration_vector0 : IN std_logic_vector(3 downto 0);
	-- 	reset0 : IN std_logic;
	-- 	signal_detect0 : IN std_logic;
	-- 	SFPCLKP : IN std_logic;
	-- 	SFPCLKN : IN std_logic;
	-- 	SFP_RX_P : IN std_logic;
	-- 	SFP_RX_N : IN std_logic;
	-- 	gmii_rx_clk0 : OUT std_logic;
	-- 	gmii_rxd0 : OUT std_logic_vector(7 downto 0);
	-- 	gmii_rx_dv0 : OUT std_logic;
	-- 	gmii_rx_er0 : OUT std_logic;
	-- 	status_vector0 : OUT std_logic_vector(7 downto 0);
	-- 	SFP_TX_P : OUT std_logic;
	-- 	SFP_TX_N : OUT std_logic
	-- 	);
	-- END COMPONENT;

----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
-- UDP_SFP
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------

-- 	COMPONENT UDP_MAC
-- 	PORT(
-- 		-- User-side streaming interface
-- 		RX_MAC_DEST_ADDR: in STD_LOGIC_VECTOR(47 downto 0);
-- 		RX_IP_DEST_ADDR: in STD_LOGIC_VECTOR(31 downto 0);
-- 		RX_IP_DEST_PORT: in STD_LOGIC_VECTOR(15 downto 0);

-- 				-- User-side streaming interface
-- 		TX_MAC_DEST_ADDR: in STD_LOGIC_VECTOR(47 downto 0);
-- 		TX_IP_DEST_ADDR: in STD_LOGIC_VECTOR(31 downto 0);
-- 		TX_IP_DEST_PORT: in STD_LOGIC_VECTOR(15 downto 0);


-- 		TX_EN : IN std_logic;
-- 		TX_FRAME : IN std_logic;
-- 		TX_PORT: IN STD_LOGIC_VECTOR(1 downto 0):="00";

-- 		RXD : OUT std_logic_vector(7 downto 0);
-- 		RX_READY : OUT std_logic;
-- 		TXD : IN std_logic_vector(7 downto 0);
-- 		CLK125 : IN std_logic;
-- 		RST : IN std_logic;

-- 		GMII_RXCLK : IN std_logic;
-- 		GMII_RXCTRL_RXDV : IN std_logic;
-- 		GMII_RXD : IN std_logic_vector(7 downto 0);
-- 		GMII_TXCLK : IN std_logic;
-- 		GMII_RESET_L : OUT std_logic;
-- 		GMII_TXER : OUT std_logic;
-- 		GMII_TXC_GTXCLK : OUT std_logic;
-- 		GMII_TXEN : OUT std_logic;
-- 		GMII_TXD : OUT std_logic_vector(7 downto 0)
-- 		);
-- 	END COMPONENT;


-- component XGMII_UDP_MAC_TX is

-- 	PORT (
-- 			-- User-side streaming interface
-- 		MAC_SRC_ADDR: in STD_LOGIC_VECTOR(47 downto 0);
-- 		IP_SRC_ADDR: in STD_LOGIC_VECTOR(31 downto 0);

-- 		MAC_DEST_ADDR: in STD_LOGIC_VECTOR(47 downto 0);
-- 		IP_DEST_ADDR: in STD_LOGIC_VECTOR(31 downto 0); --! Must reset whenever this address is changed
-- 		IP_DEST_PORT: in STD_LOGIC_VECTOR(15 downto 0); --! Must reset whenever this address is changed

-- --		ARP_REQUEST : in STD_LOGIC;
-- --		ARP_MAC_DEST_ADDR: in STD_LOGIC_VECTOR(47 downto 0);
-- --		ARP_IP_DEST_ADDR: in STD_LOGIC_VECTOR(31 downto 0);

-- 		-- User-side streaming interface
-- 		DIN: in AXIS32_DAT_STRUCT;
-- 		DIN_CLK: in std_logic; -- <322.5 MHz, minus Ethernet overhead

-- 		-- XGMII Interface
-- 		XGMII_TXD: out  STD_LOGIC_VECTOR(63 downto 0); -- Transmit data word
-- 		XGMII_TXC: out  STD_LOGIC_VECTOR(7 downto 0); -- Transmit control flags
-- 		XGMII_CLK: in STD_LOGIC; -- Transmit clock

-- 		RST : in STD_LOGIC -- asynchronous reset
-- 		);


-- end component;

----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
-- ADC_DAQ
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------

-- COMPONENT MGT_DIST is
-- 	GENERIC (
-- 		NUMBER_OF_MGT: INTEGER :=2;
-- 		NUMBER_OF_ANTENNAS: INTEGER :=1
-- 	);

-- 	PORT (

-- 		-- MGT pin interfaces

-- 		MGT_TXP: out STD_LOGIC_VECTOR(0 to NUMBER_OF_MGT-1);
-- 		MGT_TXN: out STD_LOGIC_VECTOR(0 to NUMBER_OF_MGT-1);
-- 		MGT_RXP: in STD_LOGIC_VECTOR(0 to NUMBER_OF_MGT-1);
-- 		MGT_RXN: in STD_LOGIC_VECTOR(0 to NUMBER_OF_MGT-1);

-- --		MGT_TXP: out STD_LOGIC;
-- --		MGT_TXN: out STD_LOGIC;
-- --		MGT_RXP: in STD_LOGIC;
-- --		MGT_RXN: in STD_LOGIC;

-- 		MGT_REFCLKP: in STD_LOGIC;
-- 		MGT_REFCLKN: in STD_LOGIC;


-- 		-- Antenna processor output interface
-- 		ANT_OUT_DAT : in  AXIS32_DAT_STRUCT_ARRAY(NUMBER_OF_ANTENNAS-1 downto 0); -- Antenna data stream
-- 		ANT_OUT_RDY : out  AXIS32_RDY_STRUCT_ARRAY(NUMBER_OF_ANTENNAS-1 downto 0); -- Antenna data frame is ready for readout
-- 		ANT_CLK:  OUT STD_LOGIC;

-- 		-- MGT Distributor output interface

-- 		MGT_DOUT : out  ByteArray(NUMBER_OF_MGT-1 downto 0); -- Antenna data stream
-- 		MGT_READY : out STD_LOGIC_VECTOR(NUMBER_OF_MGT-1 downto 0); -- Antenna data frame is ready for readout
-- 		MGT_RD_EN : in STD_LOGIC_VECTOR(NUMBER_OF_MGT-1 downto 0); -- Read enable (maintain high while ANT_READY is high)
-- 		MGT_CLK:  in STD_LOGIC;

-- 		-- System
-- 		MGT_REFCLK_DIV2: out STD_LOGIC;
-- 		MGT_USRCLK2_DIV2: out STD_LOGIC;

-- 		-- Control interface
-- 		CTRL_CMD_IN_DAT: in AXIS8_DAT_STRUCT;
-- 		CTRL_CMD_IN_RDY: out AXIS8_RDY_STRUCT;
-- 		CTRL_RPLY_OUT_DAT: out AXIS8_DAT_STRUCT;
-- 		CTRL_RPLY_OUT_RDY: in AXIS8_RDY_STRUCT;
-- 		CTRL_CLK: in  STD_LOGIC;

-- 		CLK200: in  STD_LOGIC;
-- 		RST : in STD_LOGIC
-- 		);

-- end COMPONENT;

-- component MGT
-- generic
-- (
--     -- Simulation attributes
--     WRAPPER_SIM_GTXRESET_SPEEDUP    : integer   := 0 -- Set to 1 to speed up sim reset
-- );
-- port
-- (
-- 	-- MGT Input and outputs
-- 	RXN                             : in   std_logic;
--    RXP                             : in   std_logic;
-- 	TXN                            : out  std_logic;
-- 	TXP                            : out  std_logic;

-- 	-- MGT control signals
-- 	USRCLK                        : in   std_logic;
-- 	USRCLK2                       : in   std_logic;
-- 	REFCLK                        : in   std_logic;
-- 	TXOUTCLK                        : out   std_logic;
-- 	RX_RESET                      : in   std_logic;
--    RX_PLL_LOCKED                     : out  std_logic;
-- 	TX_RESET                         : in   std_logic;

-- 	-- Antenna processor output interface

-- 	ANT_DOUT : in  STD_LOGIC_VECTOR(31 downto 0); -- Antenna data stream
-- 	ANT_READY : in STD_LOGIC; -- Antenna data frame is ready for readout
-- 	ANT_RD_EN : out STD_LOGIC; -- Read enable (maintain high while ANT_READY is high)
-- 	ANT_CLK:  OUT STD_LOGIC;

-- 	-- MGT Distributor output interface

-- 	MGT_DOUT : out  STD_LOGIC_VECTOR(7 downto 0):=(others=>'0'); -- Antenna data stream
-- 	MGT_READY : out STD_LOGIC:='0'; -- Antenna data frame is ready for readout
-- 	MGT_RD_EN : in STD_LOGIC; -- Read enable (maintain high while ANT_READY is high)
-- 	MGT_CLK:  in STD_LOGIC;

-- 	-- Control interface
-- 	CTRL_CMD_IN_DAT: in AXIS8_DAT_STRUCT;
-- 	CTRL_CMD_IN_RDY: out AXIS8_RDY_STRUCT;
-- 	CTRL_RPLY_OUT_DAT: out AXIS8_DAT_STRUCT;
-- 	CTRL_RPLY_OUT_RDY: in AXIS8_RDY_STRUCT;
-- 	CTRL_CLK: in  STD_LOGIC;

-- 	-- System
-- 	USER_RESET : in STD_LOGIC;
-- 	RST : in STD_LOGIC
-- );
-- end component;


----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
-- EV8AQ160
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------

-- COMPONENT EV8AQ160 is
-- 	 GENERIC (
-- 			DMUX :boolean :=FALSE; -- Is the output Demuxed between the High and Low bytes? (TRUE or FALSE)
-- 			CHANNELS : INTEGER := 4 -- Number of output channels (1, 2 or 4)
-- 	);

--     Port ( CLK : in  STD_LOGIC; -- Clock privided at the input of the ADC. The internal sampling clocks are half that rate (although they operate in DDR)

--            AHP : out  STD_LOGIC_VECTOR (7 downto 0); -- A Data
--            AHN : out  STD_LOGIC_VECTOR (7 downto 0); -- A Data
--            ALP : out  STD_LOGIC_VECTOR (7 downto 0); -- A Data (DMUX Mode only)
--            ALN : out  STD_LOGIC_VECTOR (7 downto 0); -- A Data (DMUX Mode only)

--            BHP : out  STD_LOGIC_VECTOR (7 downto 0);
--            BHN : out  STD_LOGIC_VECTOR (7 downto 0);
--            BLP : out  STD_LOGIC_VECTOR (7 downto 0);
--            BLN : out  STD_LOGIC_VECTOR (7 downto 0);

--            CHP : out  STD_LOGIC_VECTOR (7 downto 0);
--            CHN : out  STD_LOGIC_VECTOR (7 downto 0);
--            CLP : out  STD_LOGIC_VECTOR (7 downto 0);
--            CLN : out  STD_LOGIC_VECTOR (7 downto 0);

--            DHP : out  STD_LOGIC_VECTOR (7 downto 0);
--            DHN : out  STD_LOGIC_VECTOR (7 downto 0);
--            DLP : out  STD_LOGIC_VECTOR (7 downto 0);
--            DLN : out  STD_LOGIC_VECTOR (7 downto 0);

--            AAI : in  REAL;
--            BAI : in  REAL;
--           CAI : in  REAL;
--          DAI : in  REAL;

--            ADRP : out  STD_LOGIC;	-- DDR Output clock for AH Data (and AL Data if DMUS mode is used)
--            ADRN : out  STD_LOGIC;	-- DDR Output clock for AH Data (and AL Data if DMUS mode is used)

--            BDRP : out  STD_LOGIC;
--            BDRN : out  STD_LOGIC;

--            CDRP : out  STD_LOGIC;
--            CDRN : out  STD_LOGIC;

--            DDRP : out  STD_LOGIC;
--            DDRN : out  STD_LOGIC;

--            SYNCP : in  STD_LOGIC;
--            SYNCN : in  STD_LOGIC

-- 			  );
-- end COMPONENT;

----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
-- FMC_EMUL
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------

-- COMPONENT FMC_EMUL is
-- 		 GENERIC (
-- 			PRESENT:BOOLEAN := TRUE;
-- 			SAMPLING_FREQUENCY: real
-- 		);

-- 	PORT(
-- 		ADC_RESET : IN std_logic;

-- 		ADC0_AHDP : OUT std_logic_vector(7 downto 0);
-- 		ADC0_AHDN : OUT std_logic_vector(7 downto 0);
-- 		ADC0_ADRP : OUT std_logic;
-- 		ADC0_ADRN : OUT std_logic;

-- 		ADC0_BHDP_ALDP : OUT std_logic_vector(7 downto 0);
-- 		ADC0_BHDN_ALDN : OUT std_logic_vector(7 downto 0);
-- 		ADC0_BDRP : OUT std_logic;
-- 		ADC0_BDRN : OUT std_logic;

-- 		ADC0_CHDP : OUT std_logic_vector(7 downto 0);
-- 		ADC0_CHDN : OUT std_logic_vector(7 downto 0);
-- 		ADC0_CDRP : OUT std_logic;
-- 		ADC0_CDRN : OUT std_logic;

-- 		ADC0_DHDP_CLDP : OUT std_logic_vector(7 downto 0);
-- 		ADC0_DHDN_CLDN : OUT std_logic_vector(7 downto 0);
-- 		ADC0_DDRP : OUT std_logic;
-- 		ADC0_DDRN : OUT std_logic;

-- 		ADC1_AHDP : OUT std_logic_vector(7 downto 0);
-- 		ADC1_AHDN : OUT std_logic_vector(7 downto 0);
-- 		ADC1_ADRP : OUT std_logic;
-- 		ADC1_ADRN : OUT std_logic;

-- 		ADC1_BHDP_ALDP : OUT std_logic_vector(7 downto 0);
-- 		ADC1_BHDN_ALDN : OUT std_logic_vector(7 downto 0);
-- 		ADC1_BDRP : OUT std_logic;
-- 		ADC1_BDRN : OUT std_logic;
-- 		ADC1_CHDP : OUT std_logic_vector(7 downto 0);
-- 		ADC1_CHDN : OUT std_logic_vector(7 downto 0);
-- 		ADC1_CDRP : OUT std_logic;
-- 		ADC1_CDRN : OUT std_logic;
-- 		ADC1_DHDP_CLDP : OUT std_logic_vector(7 downto 0);
-- 		ADC1_DHDN_CLDN : OUT std_logic_vector(7 downto 0);
-- 		ADC1_DDRP : OUT std_logic;
-- 		ADC1_DDRN : OUT std_logic;

-- 		ADC_SYNCP : IN std_logic;
-- 		ADC_SYNCN : IN std_logic;

-- 		-----------------------
-- 		-- SPI Interface ------
-- 		-----------------------

-- 		SPI_MISO : OUT std_logic;
-- 		SPI_MOSI : IN std_logic:='0';
-- 		SPI_ADDR : IN std_logic_vector (2 downto 0):="000";
-- 		SPI_SCK : IN std_logic:='0';


-- 		-----------------------
-- 		-- PLL Interface ------
-- 		-----------------------

-- 		PLL_LE: IN std_logic:='0';


-- 		-----------------------
-- 		-- I2C Interface ------
-- 		-----------------------

-- 		I2C_SDI: INOUT std_logic:='0';
-- 		I2C_SCK: IN std_logic:='0';
-- 		--------------------------------
-- 		-- 10 MHz reference clock ------
-- 		--------------------------------

-- 		REFCLK: IN std_logic:='0'

-- 		);

-- end COMPONENT;


-- COMPONENT FFT is
-- 	generic (
-- 		IMPLEMENT_FFT: BOOLEAN :=TRUE
-- 		);
-- 	port (
-- 		-- Input interface
-- 		IN_DAT: in AXIS32_DAT_STRUCT;
-- --		SYNC_IN : in  STD_LOGIC; -- This is the CASPER SYNC

-- 		-- Output interface
-- 		OUT_DAT: out AXIS72_DAT_STRUCT;

-- 		-- Control interface (command and reply stream buses)
-- 		CTRL_CMD_IN_DAT: in AXIS8_DAT_STRUCT;
-- 		CTRL_CMD_IN_RDY: out AXIS8_RDY_STRUCT;
-- 		CTRL_RPLY_OUT_DAT: out AXIS8_DAT_STRUCT;
-- 		CTRL_RPLY_OUT_RDY: in AXIS8_RDY_STRUCT;
-- 		CTRL_CLK: in  STD_LOGIC;

-- 		CLK : in  STD_LOGIC;
-- 		ANT_RESET : in  STD_LOGIC;
-- 		RST : in  STD_LOGIC
-- 		);
-- END COMPONENT;

-- COMPONENT SPI_SLAVE is
-- 	 generic (
-- 		ADDRESS: integer :=4;
-- 		BYTES: integer :=2;
-- 		READ_VALUE: STD_LOGIC_VECTOR :=X"0000"
-- 		);
--     port (
-- 		--SPI signals
-- 		SPI_SCK: in STD_LOGIC;
-- 		SPI_MISO: out STD_LOGIC;
-- 		SPI_MOSI: in STD_LOGIC;
-- 		SPI_ADDR: in STD_LOGIC_VECTOR(2 downto 0);
-- 		SPI_RST_N: in STD_LOGIC;

-- 		-- System-level signals
-- 		RST: in STD_LOGIC
-- 	);

-- end component;


-- component FFT_DELAY is
-- 	generic (
-- 		CTR_WIDTH: INTEGER := 12; -- number of bits of the delay line. Max delay = 2^CTR_WIDTH
-- 		DATA_WIDTH: INTEGER := 4 -- number of flag bits to propagate through the delay line.
-- 		);
--    port (
-- 		SYNC_IN : in  STD_LOGIC;
-- 		SYNC_OUT: in  STD_LOGIC;
-- 		MEASURED_DELAY: out STD_LOGIC_VECTOR(CTR_WIDTH-1 downto 0);

-- 		DATA_IN : in  STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
-- 		DATA_OUT: out  STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
-- 		VALID: out std_logic;
-- 		DELAY: in STD_LOGIC_VECTOR(CTR_WIDTH-1 downto 0);

-- 		CLK : in  STD_LOGIC;
-- 		CE : in  STD_LOGIC;
-- 		RST : in  STD_LOGIC
-- 		);

-- end component;


-- COMPONENT simple_fft
-- 	PORT(
-- 		ce_1 : IN std_logic;
-- 		clk_1 : IN std_logic;
-- 		in0 : IN std_logic_vector(7 downto 0);
-- 		in1 : IN std_logic_vector(7 downto 0);
-- 		in2 : IN std_logic_vector(7 downto 0);
-- 		in3 : IN std_logic_vector(7 downto 0);
-- 		sync_in : IN std_logic;
-- 		out1 : OUT std_logic_vector(15 downto 0);
-- 		out2 : OUT std_logic_vector(15 downto 0);
-- 		overflow : OUT std_logic;
-- 		sync_out : OUT std_logic
-- 		);
-- END COMPONENT;

COMPONENT simple_pfb_v2
  port (
    ce_1: in std_logic;
    clk_1: in std_logic;
    in0: in std_logic_vector(7 downto 0);
    in1: in std_logic_vector(7 downto 0);
    in2: in std_logic_vector(7 downto 0);
    in3: in std_logic_vector(7 downto 0);
    shift: in std_logic_vector(10 downto 0);
    sync_in: in std_logic;
    out1: out std_logic_vector(35 downto 0);
    out2: out std_logic_vector(35 downto 0);
    overflow: out std_logic;
    sync_out: out std_logic
  );
END COMPONENT;

-- component SCALER is
-- 	generic (
-- 		IMPLEMENT_CALIB: BOOLEAN :=TRUE
-- 		);
-- 	port (
-- 		-- Input interface
-- 		IN_DAT: in AXIS72_DAT_STRUCT;

-- 		-- Output interface
-- 		OUT_DAT: out AXIS32_DAT_STRUCT;

-- 		-- Control interface (command and reply stream buses)
-- 		CTRL_CMD_IN_DAT: in AXIS8_DAT_STRUCT;
-- 		CTRL_CMD_IN_RDY: out AXIS8_RDY_STRUCT;
-- 		CTRL_RPLY_OUT_DAT: out AXIS8_DAT_STRUCT;
-- 		CTRL_RPLY_OUT_RDY: in AXIS8_RDY_STRUCT;
-- 		CTRL_CLK: in  STD_LOGIC;

-- 		CLK : in  STD_LOGIC;
-- 		ANT_RESET : in  STD_LOGIC;
-- 		RST : in  STD_LOGIC
-- 		);
-- end component;

-- COMPONENT FUNCGEN is
--     PORT (

-- 		-- Output data interface
-- 		OUT_DAT : out  AXIS32_DAT_STRUCT; --! Output stream of the function generator

-- 		-- Data clock
-- 		CLK : in  STD_LOGIC; --! Output stream clock

-- 		-- Control interface (command and reply stream buses)
-- 		CTRL_CMD_IN_DAT: in AXIS8_DAT_STRUCT;
-- 		CTRL_CMD_IN_RDY: out AXIS8_RDY_STRUCT;
-- 		CTRL_RPLY_OUT_DAT: out AXIS8_DAT_STRUCT;
-- 		CTRL_RPLY_OUT_RDY: in AXIS8_RDY_STRUCT;
-- 		CTRL_CLK: in  STD_LOGIC;

-- 		-- System interface
-- 		ANT_RESET: in std_logic; --! synchronous reset for the whole antenna processing chain
-- 		RST : in  STD_LOGIC --! Asynchronous power-on reset.
-- 	  );
-- end COMPONENT;

-- COMPONENT INJECT is
--     PORT (
-- 		-- Output data interface
-- 		OUT_DAT : out  AXIS32_DAT_STRUCT; --! Output stream

-- 		-- Data clock
-- 		CLK : in  STD_LOGIC; --! Antenna processing clock common to the input and output streams

-- 		-- System level signals
-- 		TRIG : in  STD_LOGIC; --! Global trigger, used to enable start the transmission of the data stored in the local FIFOs

-- 		-- Control interface (command and reply stream buses)
-- 		CTRL_CMD_IN_DAT: in AXIS8_DAT_STRUCT;
-- 		CTRL_CMD_IN_RDY: out AXIS8_RDY_STRUCT;
-- 		CTRL_RPLY_OUT_DAT: out AXIS8_DAT_STRUCT;
-- 		CTRL_RPLY_OUT_RDY: in AXIS8_RDY_STRUCT;
-- 		CTRL_CLK: in  STD_LOGIC;

-- 		-- System interface
-- 		ANT_RESET: in std_logic; --! synchronous reset for the whole antenna processing chain
-- 		RST : in  STD_LOGIC --! Asynchronous power-on reset.
-- 	  );
-- end COMPONENT;


-- COMPONENT SRCSEL is
--     PORT (
-- 		-- Input streams interface
-- 		ADC_IN_DAT : in  AXIS32_DAT_STRUCT; --! Data stream from the ADC. The TUSER field contain an overflow bit flag for each byte.
-- 		FUNCGEN_IN_DAT : in  AXIS32_DAT_STRUCT; --! Data stream from the Function Generator.
-- 		INJECT_IN_DAT : in  AXIS32_DAT_STRUCT; --! Data stream from the user injected data.

-- 		-- Output data interface
-- 		OUT_DAT : out  AXIS32_DAT_STRUCT; --! Output stream, selected from the software programmable source (ADC, injection or function generator)

-- 		-- Data clock
-- 		CLK : in  STD_LOGIC; --! Antenna processing clock common to the input and output streams

-- 		-- System level signals
-- 		TRIG : in  STD_LOGIC; --! Global trigger, used to enable the injection buffer readout or tag the ADC or function generator streams with the CAPTURE flag. This is synchronous to the antenna processor clock.

-- 		-- Control interface (command and reply stream buses)
-- 		CTRL_CMD_IN_DAT: in AXIS8_DAT_STRUCT;
-- 		CTRL_CMD_IN_RDY: out AXIS8_RDY_STRUCT;
-- 		CTRL_RPLY_OUT_DAT: out AXIS8_DAT_STRUCT;
-- 		CTRL_RPLY_OUT_RDY: in AXIS8_RDY_STRUCT;
-- 		CTRL_CLK: in  STD_LOGIC;

-- 		-- System interface
-- 		ANT_RESET: in std_logic; --! synchronous reset for the whole antenna processing chain
-- 		RST : in  STD_LOGIC --! Asynchronous power-on reset.
-- 	  );
-- END COMPONENT;

-- COMPONENT CH_DIST is
-- 	GENERIC (
-- 		NUMBER_OF_ANTENNAS: INTEGER -- Number of antennas to capture simultaneously
-- 		);
--     PORT (
-- 		-- Input interface (non-blocking, i.e. always accept data)
-- 		IN_DAT : in  AXIS32_DAT_STRUCT_ARRAY(NUMBER_OF_ANTENNAS-1 downto 0);
-- 		IN_CLK: in  STD_LOGIC;

-- 		-- Output interface (blocking, i.e. will send data only when the sink is ready)
-- 		OUT_DAT : out  AXIS32_DAT_STRUCT;
-- 		OUT_RDY : in  AXIS32_RDY_STRUCT;
-- 		OUT_CLK: in  STD_LOGIC; -- readout clock

-- 		-- Control interface (command and reply stream buses)
-- 		CTRL_CMD_IN_DAT: in AXIS8_DAT_STRUCT;
-- 		CTRL_CMD_IN_RDY: out AXIS8_RDY_STRUCT;
-- 		CTRL_RPLY_OUT_DAT: out AXIS8_DAT_STRUCT;
-- 		CTRL_RPLY_OUT_RDY: in AXIS8_RDY_STRUCT;
-- 		CTRL_CLK: in  STD_LOGIC;

-- 		CORR_RESET : in STD_LOGIC; --! Global correlator reset
-- 		RST : in  STD_LOGIC
-- 	  );

-- END COMPONENT;



----------- BLINKER ---------------------


------- Command interface end-point ----------------

-- COMPONENT CTRL_SLAVE is
-- 	GENERIC (
-- 		DEFAULT_CONTROL_BYTES: STD_LOGIC_VECTOR:=X"00000000"; -- Vector of bits to initialize the control register to a known value
-- 		NUMBER_OF_CONTROL_BYTES: INTEGER :=1; -- Number of bytes in the control word
-- 		NUMBER_OF_STATUS_BYTES: INTEGER :=1; -- Number of bytes in the status word.
-- 		STICKY_BYTES_MASK:  STD_LOGIC_VECTOR:=X""; -- Determines which status bits are sticky (1=sticky, 0=non-sticky)
-- 		USE_RAM_DOUT_RDY: BOOLEAN :=FALSE; -- Indicates is the RAM interface provides a DOUT_RDY signal. If FALSE, it is assumed that the data is available the clock after RD_EN.
-- 		RAM_DATA_WIDTH: INTEGER :=8; -- Either 8 or 16 bits.
-- 		ADDR_WIDTH: INTEGER :=10; -- Number of bits in the CTRL bus address word
-- 		RAM_ADDR_WIDTH: INTEGER :=8; -- Number of bits in the RAM_Bank selection word.
-- 		USE_ASYNC_FIFO: boolean := False
-- 		);
--     PORT (

-- 		-- Control interface

-- 		CTRL_CMD_IN_DAT: in AXIS8_DAT_STRUCT; -- Command stream input, signals from master (Data, Valid, Last)
-- 		CTRL_CMD_IN_RDY: out AXIS8_RDY_STRUCT; -- Command stream input, signals to master (Ready)
-- 		CTRL_RPLY_OUT_DAT: out AXIS8_DAT_STRUCT; -- Reply stream output, signals to slave (Data, Valid, Last)
-- 		CTRL_RPLY_OUT_RDY: in AXIS8_RDY_STRUCT; -- Reply stream output,  signals from slave (Ready)
-- 		CTRL_CLK: in STD_LOGIC;

-- 		-- Control/status words
-- 		CONTROL_BYTES: out ByteArray(0 to NUMBER_OF_CONTROL_BYTES-1); --
-- 		STATUS_BYTES: in ByteArray(0 to NUMBER_OF_STATUS_BYTES-1):=(others=> (others=>'0')); --
-- 		CLK: in STD_LOGIC;

-- 		-- FIFO/RAM interface
-- 		RAM_DIN : OUT  STD_LOGIC_VECTOR (RAM_DATA_WIDTH-1 downto 0);
-- 		RAM_DOUT : IN  STD_LOGIC_VECTOR (RAM_DATA_WIDTH-1 downto 0):=(others=>'0');
-- 		RAM_DOUT_RDY : IN  STD_LOGIC :='0'; -- To interface devices that have a ready pin. Set GLOBAL variable USE_RAM_DOUT_RDY to determine whether this pin is used or not
-- 		RAM_ADDR : OUT  STD_LOGIC_VECTOR (RAM_ADDR_WIDTH-1 downto 0);
-- 		RAM_WR_EN : OUT  STD_LOGIC;
-- 		RAM_RD_EN : OUT  STD_LOGIC;
-- 		RAM_EN : OUT  STD_LOGIC;
-- --		RAM_BANK: IN  STD_LOGIC_VECTOR(RAM_BANK_WIDTH-1 downto 0) :=(others=>'0');

-- 		-- System interface
-- 		RST : in  STD_LOGIC
-- 		);
-- end COMPONENT CTRL_SLAVE;


------ Command interface router ----------

-- component CTRL_ROUTER is
-- 	generic(
-- 		NUMBER_OF_PORTS: INTEGER :=8;
-- 		PORT_NUMBER_HIGH_BIT: integer;
-- 		PORT_NUMBER_LOW_BIT: integer
-- 		--SIM: boolean :=FALSE

-- 		);
--     PORT (
-- 		-- Command streams from single slave input to multiple master outputs
-- 		CMD_IN_DAT: in AXIS8_DAT_STRUCT;
-- 		CMD_IN_RDY: out AXIS8_RDY_STRUCT;
-- 		CMD_OUT_DAT: out AXIS8_DAT_STRUCT_ARRAY(NUMBER_OF_PORTS-1 downto 0);
-- 		CMD_OUT_RDY: in AXIS8_RDY_STRUCT_ARRAY(NUMBER_OF_PORTS-1 downto 0);

-- 		-- Reply streams from multiple slave inputs to single master output
-- 		RPLY_IN_DAT: in AXIS8_DAT_STRUCT_ARRAY(NUMBER_OF_PORTS-1 downto 0);
-- 		RPLY_IN_RDY: out AXIS8_RDY_STRUCT_ARRAY(NUMBER_OF_PORTS-1 downto 0);
-- 		RPLY_OUT_DAT: out AXIS8_DAT_STRUCT;
-- 		RPLY_OUT_RDY: in AXIS8_RDY_STRUCT;

-- 		-- System interface
-- 		CLK: in STD_LOGIC;
-- 		RST : in  STD_LOGIC
-- 		);
-- end component;

-- COMPONENT CTRL_FIFO is
-- 	GENERIC (
-- 		USE_ASYNC_FIFO: boolean;
-- 		SIM: boolean :=FALSE
-- 		);
--     PORT (

-- 		-- Command streams from single slave input to multiple master outputs
-- 		CMD_A_DAT: in AXIS8_DAT_STRUCT;
-- 		CMD_A_RDY: out AXIS8_RDY_STRUCT;
-- 		RPLY_A_DAT: out AXIS8_DAT_STRUCT;
-- 		RPLY_A_RDY: in AXIS8_RDY_STRUCT;
-- 		A_CLK: in STD_LOGIC;

-- 		CMD_B_DAT: out AXIS8_DAT_STRUCT;
-- 		CMD_B_RDY: in AXIS8_RDY_STRUCT;
-- 		RPLY_B_DAT: in AXIS8_DAT_STRUCT;
-- 		RPLY_B_RDY: out AXIS8_RDY_STRUCT;
-- 		B_CLK: in STD_LOGIC;

-- 		-- System interface
-- 		RST : in  STD_LOGIC
-- 		);

-- end COMPONENT;

-------------- SPI Interface -------------------


-- ------------ ML605 FAN interface -------------------
-- COMPONENT FAN is
--     PORT (
-- 			-- FPGA fan signals
-- 			FAN_PWM: out STD_LOGIC;
-- 			FAN_TACH: in STD_LOGIC;
-- 			FAN_TACH_DIV2: out STD_LOGIC;

-- 			CLK200: in  STD_LOGIC;
--          RST: in  STD_LOGIC
-- 			 );
-- end COMPONENT;

-- ------------ FPGA System Monitor -------------------



-- component PROBER is
-- 	generic (
-- 		SIM: BOOLEAN :=FALSE
-- 		);
--    port (
-- 	-- Input interface
-- 	IN_DAT : in  AXIS32_DAT_STRUCT; -- Word to be captured (TDATA)
-- 	IN_CLK:  in STD_LOGIC;

-- 	-- Output interface
-- 	OUT_DAT: out AXIS8_DAT_STRUCT;
-- 	OUT_RDY: in AXIS8_RDY_STRUCT;
-- 	OUT_CLK:  in STD_LOGIC;

-- 	-- Control interface (command and reply stream buses)
-- 	CTRL_CMD_IN_DAT: in AXIS8_DAT_STRUCT;
-- 	CTRL_CMD_IN_RDY: out AXIS8_RDY_STRUCT;
-- 	CTRL_RPLY_OUT_DAT: out AXIS8_DAT_STRUCT;
-- 	CTRL_RPLY_OUT_RDY: in AXIS8_RDY_STRUCT;
-- 	CTRL_CLK : in  STD_LOGIC;

-- 	-- System
-- 	ANT_RESET : in STD_LOGIC;
-- 	RST : in STD_LOGIC
-- 	);


-- end component;

----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
-- CORRELATOR
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------

-- component XMUL is
-- 	GENERIC (
-- 		N: integer :=8 --! Number of antennas to correlate
-- 		);
-- 	PORT(
-- 	-- Input stream (non blocking)
-- 		IN_DAT : IN AXIS32_DAT_STRUCT;

-- 	-- Output stream (non blocking)
-- 		OUT_DAT : OUT AXIS34_DAT_STRUCT_ARRAY(0 to N);

-- 	-- Control and reply streams
-- 		CTRL_DAT: in AXIS8_DAT_STRUCT;
-- 		CTRL_RDY: out AXIS8_RDY_STRUCT;
-- 		RPLY_DAT: out AXIS8_DAT_STRUCT;
-- 		RPLY_RDY: in AXIS8_RDY_STRUCT;
-- 		CTRL_CLK : IN std_logic; -- control clock


-- 	-- General system clocks
-- 		CLK : IN std_logic; -- processing clock
-- 		CORR_RESET: IN std_logic; --! Global correltor reset
-- 		RST: IN std_logic -- asynchronous reset

-- 		);

-- end component;

-- component ACC is
-- 	GENERIC(
-- 		N: INTEGER:=8; -- Number of antennas per correlation
-- --		M: INTEGER:=4; -- Number of channel pairs that are correlated in a frame (i.e. number of times the antenna sequence is repeated)
-- 		SIM: boolean:=FALSE
-- 		);
-- 	PORT(
-- 		IN_DAT: in AXIS34_DAT_STRUCT_ARRAY(0 to N);
-- 		IN_CLK : IN std_logic; -- processing clock


-- 		OUT_DAT: out AXIS8_DAT_STRUCT;
-- 		OUT_RDY: in AXIS8_RDY_STRUCT;
-- 		OUT_CLK : IN std_logic; -- output clock

-- 	-- Control and reply streams
-- 		CTRL_DAT: in AXIS8_DAT_STRUCT;
-- 		CTRL_RDY: out AXIS8_RDY_STRUCT;
-- 		RPLY_DAT: out AXIS8_DAT_STRUCT;
-- 		RPLY_RDY: in AXIS8_RDY_STRUCT;
-- 		CTRL_CLK : IN std_logic; -- control clock

-- 		-- system
-- 		CORR_RESET: IN std_logic; --! Global correltor reset
-- 		RST: IN std_logic -- asynchronous reset

-- 		);
-- end component;


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

--! Compute the number of bits needed to represent values from 0 to len-1
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


end chFPGA_Package;
