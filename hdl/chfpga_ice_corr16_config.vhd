library work;
-- Get all chFPGA_package definitions. Since this USE statement is outside the
-- package, its content is visible only to this package, i.e. "USE
-- chFPGA_config.all" does not import the contents of chFPGA_package.
use work.chFPGA_package.all;

package chfpga_config is
	constant CONFIG_PLATFORM_ID: integer := PLATFORM_ID_MGK7MB;
	constant CONFIG_CHAN_IMPLEMENT_FFT: boolean := TRUE;
	--constant CONFIG_ADC_SAMPLES_PER_WORD: integer := 4;
	--constant CONFIG_ADC_BITS_PER_SAMPLE: integer := 8;
	--constant CONFIG_ADC_SAMPLES_PER_FRAME: integer := 2048;
	constant CONFIG_CHAN_SCALER_USE_COMPLEX_GAINS: boolean := FALSE;
	constant CONFIG_CHAN_NUMBER_OF_CAPTURE_SOURCES: integer := 2;
	constant CONFIG_CHAN_CAPTURE_TYPE: string := "BRAM";
	constant CONFIG_CHAN_FFT_TYPE: integer := FFT_TYPE_CHIME;
	constant CONFIG_NUMBER_OF_CHANNELIZERS_WITH_FFT: integer := 16; -- only implement one channelizer with an FFT for now
	constant CONFIG_CAPTURE_BITS_PER_WORD: integer := 32;
	--constant CONFIG_FFT_CTR_WIDTH: integer := 12; -- CHIME: 12, D3A/CHORD: 13. Number of bits of the delay line. Max delay = 2^CONFIG_FFT_CTR_WIDTH
	constant CONFIG_FFT_ROTATE_BINS: boolean := FALSE; -- CHIME: False, D3A/CHORD: True.
	constant CONFIG_NUMBER_OF_CHANNELIZERS_TO_CORRELATE: integer := 8; -- ignored when there are no correlators

	-- the following parameters differ between the ct and corr configs

	-- Corner-turn engine

    constant CONFIG_CT_TYPE: integer   := CT_TYPE_BCT; -- "UCT" or "BCT"
	constant CONFIG_CT_LEVEL: integer := 1;

	constant CONFIG_CT_CLK_SOURCE: string := "CORR_CLK"; -- Use the 250 MHz clock  from the main MMCM. This provides enough speed to handle packet overheads.
	constant CONFIG_NUMBER_OF_CROSSBAR_OUTPUTS: integer := 8 ; -- matches the number of correlators

	constant CONFIG_NUMBER_OF_BP_PCB_SHUFFLE_LANES: integer := 0;
	constant CONFIG_NUMBER_OF_BP_QSFP_SHUFFLE_LANES: integer := 0;
	constant CONFIG_NUMBER_OF_BP_SHUFFLE_LINKS: integer := 0;
	constant CONFIG_NUMBER_OF_GPU_LINKS: integer := 0;

	-- Correlator

	constant CONFIG_CORR_TYPE: string := "UCORR44";
	constant CONFIG_NUMBER_OF_CORRELATORS: integer := 2; -- each correlator handles 128 bins
	constant CONFIG_CORR_READOUT_BINS: integer_array(0 to CONFIG_NUMBER_OF_CORRELATORS-1) := (0, 0);


	-- Real-time data offload

    constant CONFIG_GPU_LINK_TYPE: string := "NONE";
	constant CONFIG_GPU_LINK_TO_QUAD_MAP: integer_array := (0 to 3=> 0, 4 to 7=> 1); -- Channels 0-3 use QUAD0, Channels 4-7 use QUAD1
	constant CONFIG_GPU_QUAD_TO_REFCLK_MAP: integer_array := (0 to 1=>0); -- Both QUAD0 and QUAD1 use refclk(0)

end chfpga_config;
