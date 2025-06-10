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
	constant CONFIG_CHAN_SCALER_USE_COMPLEX_GAINS: boolean := TRUE;
	constant CONFIG_CHAN_NUMBER_OF_CAPTURE_SOURCES: integer := 2;
	constant CONFIG_CHAN_CAPTURE_TYPE: string := "BRAM";
	constant CONFIG_CHAN_FFT_TYPE: integer := FFT_TYPE_CHIME;
	constant CONFIG_NUMBER_OF_CHANNELIZERS_WITH_FFT: integer := 16; -- only implement one channelizer with an FFT for now
	constant CONFIG_CAPTURE_BITS_PER_WORD: integer := 32;
	--constant CONFIG_FFT_CTR_WIDTH: integer := 12; -- CHIME: 12, D3A/CHORD: 13. Number of bits of the delay line. Max delay = 2^CONFIG_FFT_CTR_WIDTH
	constant CONFIG_FFT_ROTATE_BINS: boolean := FALSE; -- CHIME: False, D3A/CHORD: True.
	constant CONFIG_NUMBER_OF_CHANNELIZERS_TO_CORRELATE: integer := 8; -- ignored when there are no correlators

	-- the following parameters differ between the cct and corr configs
	constant CONFIG_CT_CLK_SOURCE: string := "BP_SHUFFLE_TXCLK"; -- "CORR_CLK" for corr config
	constant CONFIG_NUMBER_OF_CROSSBAR_OUTPUTS: integer := 16 ; -- 8 on corr config
	constant CONFIG_NUMBER_OF_CORRELATORS: integer := 0; --8 for corr config
	constant CONFIG_NUMBER_OF_BP_PCB_SHUFFLE_LANES: integer := 16; -- 0 for corr config
	constant CONFIG_NUMBER_OF_BP_QSFP_SHUFFLE_LANES: integer := 8; -- o for corr config
	constant CONFIG_NUMBER_OF_BP_SHUFFLE_LINKS: integer := 19; -- 0 for corr config
	constant CONFIG_NUMBER_OF_GPU_LINKS: integer := 8; -- 0 for corr config

end chfpga_config;
