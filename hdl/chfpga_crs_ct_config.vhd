library work;
-- Get all chFPGA_package definitions. Since this USE statement is outside the
-- package, its content is visible only to this package, i.e. "USE
-- chFPGA_config.all" does not import the contents of chFPGA_package.
use work.chFPGA_package.all;

package chfpga_config is
	constant CONFIG_PLATFORM_ID: integer := PLATFORM_ID_CRS;

	constant CONFIG_NUMBER_OF_ADCS: integer := 8; -- Number of ADC inputs that are connected

	constant CONFIG_CHAN_IMPLEMENT_FFT: boolean := TRUE;
	constant CONFIG_CHAN_FFT_TYPE: string := "D3A";
	constant CONFIG_FFT_CTR_WIDTH: integer := 14; -- CHIME: 12, D3A/CHORD: 13. Number of bits of the delay line. Max delay = 2^CONFIG_FFT_CTR_WIDTH
	constant CONFIG_FFT_ROTATE_BINS: boolean := TRUE; -- CHIME: False, D3A/CHORD: True.
	constant CONFIG_ADC_SAMPLES_PER_WORD: integer := 8; -- we pack 8 samples per word
	constant CONFIG_ADC_BITS_PER_SAMPLE: integer := 14;
	constant CONFIG_ADC_SAMPLES_PER_FRAME: integer := 16384;
	constant CONFIG_CHAN_CAPTURE_TYPE: string := "URAM";
	constant CONFIG_CHAN_NUMBER_OF_CAPTURE_SOURCES: integer := 2;
	constant CONFIG_CHAN_SCALER_USE_COMPLEX_GAINS: boolean:= FALSE;
	constant CONFIG_NUMBER_OF_CHANNELIZERS_WITH_FFT: integer := 8; -- only implement one channelizer with an FFT for now
	constant CONFIG_CAPTURE_BITS_PER_WORD: integer := sel(CONFIG_CHAN_CAPTURE_TYPE="URAM", 128, 32);

    -- Corner-turn engine configuration
    constant CONFIG_CROSSBAR1_TYPE: string                       := "URAM"; -- "BRAM" or "URAM"
	constant CONFIG_NUMBER_OF_CROSSBAR_INPUTS: integer           := CONFIG_NUMBER_OF_ADCS; -- (Typ. =16)(0-NUMBER_OF_CHANNELIZERS): Number of channelizers output that are being aligned, filtered and repacked for the corrleator or GPU links
	constant CONFIG_NUMBER_OF_CROSSBAR1_OUTPUTS: integer         := 8; -- (Typ. =16): Number of output lanes of CROSSBAR1. Should be 8 for URAM-based crossbar1.
	constant CONFIG_NUMBER_OF_CORRELATORS: integer               := 0; -- Number of correlators. Normally NUMBER_OF_CROSSBAR_OUTPUTS. Correlator not implemented if zero.
	constant CONFIG_NUMBER_OF_BP_PCB_SHUFFLE_LANES: integer      := 0;
	constant CONFIG_NUMBER_OF_BP_QSFP_SHUFFLE_LANES: integer     := 0;
	constant CONFIG_NUMBER_OF_BP_SHUFFLE_LINKS: integer          := 0; -- Number of GTXes for both the backplane PCB and QSFP shuffle links. Usually matches the number of 1st crossbar output lanes.
	constant CONFIG_NUMBER_OF_BP_SHUFFLE_REFCLKS: integer        := 0;

    constant CONFIG_CORR_TYPE: string                            := "NONE";
--	constant CONFIG_NUMBER_OF_CORRELATORS: integer               := 4; -- Number of correlators. Normally NUMBER_OF_CROSSBAR_OUTPUTS. Correlator not implemented if zero.

    -- 10/100G Ethernet Real-time data offload links configuration
    constant CONFIG_GPU_LINK_TYPE: string:= "100GE";
	constant CONFIG_NUMBER_OF_GPU_LINKS: integer                 := 4; -- (0- NUMBER_OF_REORDER_OUTPUTS) Number of 10Gb Ethernet links to connecto to the GPUs
	constant CONFIG_NUMBER_OF_GPU_REFCLKS: integer               := 1; -- Number of Reference clocks provided for the 10GE links to the GPU



end chfpga_config;
