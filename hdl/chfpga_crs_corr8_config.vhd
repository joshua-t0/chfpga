library work;
-- Get all chFPGA_package definitions. Since this USE statement is outside the
-- package, its content is visible only to this package, i.e. "USE
-- chFPGA_config.all" does not import the contents of chFPGA_package.
use work.chFPGA_package.all;

package chfpga_config is
	constant CONFIG_PLATFORM_ID: integer := PLATFORM_ID_CRS;

	constant CONFIG_NUMBER_OF_ADCS: integer := 8; -- Number of ADC inputs that are connected

	constant CONFIG_CHAN_IMPLEMENT_FFT: boolean := TRUE;
	constant CONFIG_CHAN_FFT_TYPE: integer := FFT_TYPE_CHORD; -- 14 bit samples, 8 samples/word, 16384 samples/frame, 32+32 bit output
	constant CONFIG_FFT_ROTATE_BINS: boolean := TRUE; -- CHIME: False, D3A/CHORD: True.
	constant CONFIG_CHAN_CAPTURE_TYPE: string := "URAM";
	constant CONFIG_CHAN_NUMBER_OF_CAPTURE_SOURCES: integer := 2;
	constant CONFIG_CHAN_SCALER_USE_COMPLEX_GAINS: boolean:= FALSE;
	constant CONFIG_NUMBER_OF_CHANNELIZERS_WITH_FFT: integer := 8;
	constant CONFIG_CAPTURE_BITS_PER_WORD: integer := sel(CONFIG_CHAN_CAPTURE_TYPE="URAM", 128, 32);

    -- Corner-turn engine configuration

    constant CONFIG_CT_TYPE: integer                             := CT_TYPE_UCT;
    constant CONFIG_CT_LEVEL: integer := 1;
    constant CONFIG_CT_CLK_SOURCE: string                        := "ADC_CLK"; -- Run the corner-turn & correlator on the 400 MHz ADC clock
    --constant CONFIG_CROSSBAR1_TYPE: string                       := "NONE"; -- "BRAM" or "URAM"
	constant CONFIG_NUMBER_OF_CROSSBAR_INPUTS: integer           := CONFIG_NUMBER_OF_ADCS; -- (Typ. =16)(0-NUMBER_OF_CHANNELIZERS): Number of channelizers output that are being aligned, filtered and repacked for the corrleator or GPU links
	constant CONFIG_NUMBER_OF_CROSSBAR1_OUTPUTS: integer         := 0; -- (Typ. =16): Number of output lanes of CROSSBAR1. Should be 8 for URAM-based crossbar1.
	constant CONFIG_NUMBER_OF_BP_PCB_SHUFFLE_LANES: integer      := 0;
	constant CONFIG_NUMBER_OF_BP_QSFP_SHUFFLE_LANES: integer     := 0;
	constant CONFIG_NUMBER_OF_BP_SHUFFLE_LINKS: integer          := 3; -- Number of GTXes for both the backplane PCB and QSFP shuffle links. Usually matches the number of 1st crossbar output lanes.
	constant CONFIG_NUMBER_OF_BP_SHUFFLE_REFCLKS: integer        := 1;

	-- Correlator

    constant CONFIG_CORR_TYPE: string                            := "UCORR44";
	constant CONFIG_NUMBER_OF_CORRELATORS: integer               := FFT_INFO(CONFIG_CHAN_FFT_TYPE).BINS_PER_WORD; -- One correlator per bin in the FFT output word
	constant CONFIG_CORR_READOUT_BINS: integer_array(0 to CONFIG_NUMBER_OF_CORRELATORS-1) := (0, 1, 2, 3); -- With CONFIG_FFT_ROTATE_BINS=True, true bins 0, 1, 2 & 3 will be used for readout


    -- 10/100G Ethernet Real-time data offload links configuration
    constant CONFIG_GPU_LINK_TYPE: string := "NONE";



end chfpga_config;
