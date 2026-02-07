library work;
-- Get all chFPGA_package definitions. Since this USE statement is outside the
-- package, its content is visible only to this package, i.e. "USE
-- chFPGA_config.all" does not import the contents of chFPGA_package.
use work.chFPGA_package.all;

package chfpga_config is
	constant CONFIG_PLATFORM_ID: integer := PLATFORM_ID_MGK7MB;

	-- Channelizer config

	constant CONFIG_CHAN_IMPLEMENT_FFT: boolean              := TRUE;
	constant CONFIG_CHAN_FFT_TYPE: fft_type_enum             := HIRAX_3DSP;
	constant CONFIG_NUMBER_OF_CHANNELIZERS_WITH_FFT: integer := 16; -- only implement one channelizer with an FFT for now
	constant CONFIG_CHAN_SCALER_USE_COMPLEX_GAINS: boolean   := FALSE;
	--constant CONFIG_CHAN_NUMBER_OF_CAPTURE_SOURCES: integer  := 2;
	constant CONFIG_CHAN_CAPTURE_TYPE: chan_capture_type_enum := PROBER;
	--constant CONFIG_CAPTURE_BITS_PER_WORD: integer           := 32;

	-- Corner-turn engine

	constant CONFIG_CT_TYPE: ct_type_enum             := BCT; -- "UCT" or "BCT"
	constant CONFIG_CT_LEVEL: integer := 1;
	constant CONFIG_CT_CLK_SOURCE: ct_clk_source_enum := CORR_CLK; -- Use the 250 MHz clock  from the main MMCM. This provides enough speed to handle packet overheads.

	constant CONFIG_NUMBER_OF_CROSSBAR_OUTPUTS: integer := 8 ; -- matches the number of correlators
	constant CONFIG_NUMBER_OF_BP_PCB_SHUFFLE_LANES: integer := 0;
	constant CONFIG_NUMBER_OF_BP_QSFP_SHUFFLE_LANES: integer := 0;
	constant CONFIG_NUMBER_OF_BP_SHUFFLE_LINKS: integer := 0;

	-- Correlator config

	constant CONFIG_CORR_TYPE: corr_type_enum := UCORR44;
	constant CONFIG_NUMBER_OF_CORRELATORS: integer := 2; -- each correlator handles 128 bins
	constant CONFIG_CORR_READOUT_BINS: integer_array(0 to CONFIG_NUMBER_OF_CORRELATORS-1) := (0, 0);


	-- Real-time data offload

    constant CONFIG_GPU_LINK_TYPE: gpu_link_type_enum := NONE;
	--constant CONFIG_GPU_LINK_TO_QUAD_MAP: integer_array := (0 to 3=> 0, 4 to 7=> 1); -- Channels 0-3 use QUAD0, Channels 4-7 use QUAD1
	--constant CONFIG_GPU_LINK_TO_QUAD_MAP: integer_array(0 to -1); -- **this crashes the synth* NULL range, no GTX connections.
	--constant CONFIG_GPU_QUAD_TO_REFCLK_MAP: integer_array := (0 to 1=>0); -- Both QUAD0 and QUAD1 use refclk(0)

end chfpga_config;
