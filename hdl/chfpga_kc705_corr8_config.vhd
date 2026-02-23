library work;
use work.chFPGA_package.all;

package chfpga_config is
	constant CONFIG_PLATFORM_ID: integer := PLATFORM_ID_KC705;

	-- Channelizer config

	constant CONFIG_CHAN_IMPLEMENT_FFT: boolean              := TRUE;
	constant CONFIG_CHAN_FFT_TYPE: fft_type_enum             := HIRAX_3DSP;
	constant CONFIG_NUMBER_OF_CHANNELIZERS_WITH_FFT: integer := 8;
	constant CONFIG_CHAN_SCALER_USE_COMPLEX_GAINS: boolean   := FALSE;
	constant CONFIG_CHAN_CAPTURE_TYPE: chan_capture_type_enum := PROBER;

	-- Corner-turn engine

	constant CONFIG_CT_TYPE: ct_type_enum             := BCT;
	constant CONFIG_CT_LEVEL: integer                 := 1;
	constant CONFIG_CT_CLK_SOURCE: ct_clk_source_enum := ADC_CLK; -- Use the ADC clock directly. At CT_LEVEL=1, we don't need packet overheads

	constant CONFIG_NUMBER_OF_CROSSBAR_OUTPUTS: integer := 8; -- matches the number of correlators
	-- constant CONFIG_NUMBER_OF_BP_PCB_SHUFFLE_LANES: integer := 0;
	-- constant CONFIG_NUMBER_OF_BP_QSFP_SHUFFLE_LANES: integer := 0;
	-- constant CONFIG_NUMBER_OF_BP_SHUFFLE_LINKS: integer := 0;

	-- Correlator config

	constant CONFIG_CORR_TYPE: corr_type_enum := UCORR44;
	constant CONFIG_NUMBER_OF_CORRELATORS: integer := FFT_INFO(CONFIG_CHAN_FFT_TYPE).BINS_PER_WORD; -- One correlator per bin in the FFT output word
	constant CONFIG_CORR_READOUT_BINS: integer_array(0 to CONFIG_NUMBER_OF_CORRELATORS-1) := (0, 0);

	-- Real-time data offload

	constant CONFIG_GPU_LINK_TYPE: gpu_link_type_enum := NONE;

end chfpga_config;
