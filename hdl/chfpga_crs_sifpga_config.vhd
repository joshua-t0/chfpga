library work;
-- Get all chFPGA_package definitions. Since this USE statement is outside the
-- package, its content is visible only to this package, i.e. "USE
-- chFPGA_config.all" does not import the contents of chFPGA_package.
use work.chFPGA_package.all;

package chfpga_config is
	constant CONFIG_PLATFORM_ID: integer := PLATFORM_ID_CRS;
	constant CONFIG_CHAN_IMPLEMENT_FFT: boolean := TRUE;
	constant CONFIG_CHAN_FFT_TYPE: string := "D3A";
	constant CONFIG_FFT_CTR_WIDTH: integer := 14; -- CHIME: 12, D3A/CHORD: 13. Number of bits of the delay line. Max delay = 2^CONFIG_FFT_CTR_WIDTH
	constant CONFIG_ADC_SAMPLES_PER_WORD: integer := 8; -- we pack 8 samples per word
	constant CONFIG_ADC_BITS_PER_SAMPLE: integer := 14;
	constant CONFIG_ADC_SAMPLES_PER_FRAME: integer := 16384;
	constant CONFIG_CHAN_CAPTURE_TYPE: string := "URAM"; 
	constant CONFIG_CHAN_NUMBER_OF_CAPTURE_SOURCES: integer := 2; 
	constant CONFIG_CHAN_SCALER_USE_COMPLEX_GAINS: boolean:= FALSE; 
	constant CONFIG_NUMBER_OF_CHANNELIZERS_WITH_FFT: integer := 1; -- only implement one channelizer with an FFT for now
	constant CONFIG_CAPTURE_BITS_PER_WORD: integer := sel(CONFIG_CHAN_CAPTURE_TYPE="URAM", 128, 32);
end chfpga_config;
