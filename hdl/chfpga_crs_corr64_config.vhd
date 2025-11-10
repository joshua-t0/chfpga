library work;
-- Get all chFPGA_package definitions. Since this USE statement is outside the
-- package, its content is visible only to this package, i.e. "USE
-- chFPGA_config.all" does not import the contents of chFPGA_package.
use work.chFPGA_package.all;

package chfpga_config is
	constant CONFIG_PLATFORM_ID: integer := PLATFORM_ID_CRS;

	constant CONFIG_NUMBER_OF_ADCS: integer := 8; -- Number of ADC inputs that are connected

	-- F-Engine/channelizer configuration

	constant CONFIG_CHAN_IMPLEMENT_FFT: boolean               := TRUE;
	constant CONFIG_CHAN_FFT_TYPE: fft_type_enum              := CHORD; -- 14 bit samples, 8 samples/word, 16384 samples/frame, 32+32 bit output
	constant CONFIG_CHAN_CAPTURE_TYPE: chan_capture_type_enum := UCAP;
	constant CONFIG_CHAN_NUMBER_OF_CAPTURE_SOURCES: integer   := 2;
	constant CONFIG_CHAN_SCALER_USE_COMPLEX_GAINS: boolean    := FALSE;
	constant CONFIG_NUMBER_OF_CHANNELIZERS_WITH_FFT: integer  := 8;

    -- Corner-turn engine configuration

	constant CONFIG_CT_TYPE: ct_type_enum                    := UCT; -- UCT or BCT
	constant CONFIG_CT_LEVEL: integer                        := 3; -- 2 for CORR32, 3 for CORR64
	constant CONFIG_CT_CLK_SOURCE: ct_clk_source_enum        := ADC_CLK; -- Run the corner-turn & correlator on the 400 MHz ADC clock
	constant CONFIG_CT_LANE_TO_LINK_MAP: integer_array       := (-1, 6, 8, 10, -1, -1, 0, 1); -- (CT2 bypass, 3x CT2 PCB links, CT3 bypass, CT3 bypass, CT3 SFP1, CT3 SFP2)
	constant CONFIG_NUMBER_OF_CROSSBAR_INPUTS: integer       := CONFIG_NUMBER_OF_ADCS; -- (Typ. =16)(0-NUMBER_OF_CHANNELIZERS): Number of channelizers output that are being aligned, filtered and repacked for the corrleator or GPU links
	constant CONFIG_NUMBER_OF_CROSSBAR1_OUTPUTS: integer     := 8; -- (Typ. =16): Number of output lanes of CROSSBAR1. Should be 8 for URAM-based crossbar1.


	constant CONFIG_CORR_TYPE: CORR_TYPE_ENUM                := UCORR44;
	constant CONFIG_NUMBER_OF_CORRELATORS: integer           := 1; -- One correlator only since we have corner-turned the data sufficiently (CT_LEVEL=2) to end up with only one bin stream
	constant CONFIG_CORR_READOUT_BINS: integer_array(0 to 0) := (0 => 0); -- With CONFIG_FFT_ROTATE_BINS=True, true bins 0, 1, 2 & 3 will be used for readout

    -- 10/100G Ethernet Real-time data offload links configuration
    constant CONFIG_GPU_LINK_TYPE: gpu_link_type_enum        := NONE;

end chfpga_config;
