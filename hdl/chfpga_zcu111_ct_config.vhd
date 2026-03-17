library work;
-- Get all chFPGA_package definitions. Since this USE statement is outside the
-- package, its content is visible only to this package, i.e. "USE
-- chFPGA_config.all" does not import the contents of chFPGA_package.
use work.chFPGA_package.all;

package chfpga_config is

	-- F-Engine/channelizer configuration

	constant CONFIG_CHAN_IMPLEMENT_FFT: boolean               := TRUE;
	constant CONFIG_CHAN_FFT_TYPE: fft_type_enum              := CHORD; -- 14 bit samples, 8 samples/word, 16384 samples/frame, 32+32 bit output
	constant CONFIG_CHAN_CAPTURE_TYPE: chan_capture_type_enum := UCAP;
	constant CONFIG_CHAN_SCALER_USE_COMPLEX_GAINS: boolean   := FALSE;
	constant CONFIG_NUMBER_OF_CHANNELIZERS_WITH_FFT: integer := 8;

	-- Corner-turn engine configuration (single board, no backplane shuffle)

	constant CONFIG_CT_TYPE: ct_type_enum             := UCT;
	constant CONFIG_CT_LEVEL: integer                  := 1;
	constant CONFIG_CT_CLK_SOURCE: ct_clk_source_enum  := ADC_CLK;
	constant CONFIG_CT_LANE_TO_LINK_MAP: integer_array := (0 => -1); -- single bypass lane

	-- Correlator config (none in this config)

	constant CONFIG_NUMBER_OF_CORRELATORS: integer     := 0;
	constant CONFIG_CORR_TYPE: corr_type_enum          := NONE;
	constant CONFIG_CORR_READOUT_BINS: integer_array(0 to 0) := (0 => 0);

	-- 10/100G Ethernet Real-time data offload links configuration

	constant CONFIG_DATA_LINK_TYPE: data_link_type_enum := UPACK_CGE;
	constant CONFIG_DATA_LINK_LINK_TO_QUAD_MAP: integer_array   := (0 to 3 => 0); -- single quad for 100G
	constant CONFIG_DATA_LINK_QUAD_TO_REFCLK_MAP: integer_array    := (0 => 0);

end chfpga_config;
