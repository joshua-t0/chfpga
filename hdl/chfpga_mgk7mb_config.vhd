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
end chfpga_config;
