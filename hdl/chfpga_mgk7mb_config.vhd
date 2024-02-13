library work;
-- Get all chFPGA_package definitions. Since this USE statement is outside the
-- package, its content is visible only to this package, i.e. "USE
-- chFPGA_config.all" does not import the contents of chFPGA_package.
use work.chFPGA_package.all;

package chfpga_config is
	constant CONFIG_PLATFORM_ID: integer := PLATFORM_ID_MGK7MB;
	constant CONFIG_CHAN_IMPLEMENT_FFT: boolean := TRUE;
	constant CONFIG_ADC_SAMPLES_PER_WORD: integer := 4; 
	constant CONFIG_ADC_BITS_PER_SAMPLE: integer := 8;
	constant CONFIG_ADC_SAMPLES_PER_FRAME: integer := 2048;
	constant CONFIG_CHAN_SCALER_USE_COMPLEX_GAINS: boolean := TRUE;
	constant CONFIG_CHAN_NUMBER_OF_CAPTURE_SOURCES: integer := 2;
	constant CONFIG_CHAN_CAPTURE_TYPE: string := "BRAM";
	constant CONFIG_CHAN_FFT_TYPE: string := "CHIME";
	constant CONFIG_NUMBER_OF_CHANNELIZERS_WITH_FFT: integer := 16; -- only implement one channelizer with an FFT for now
	constant CONFIG_CAPTURE_BITS_PER_WORD: integer := 32;

end chfpga_config;
