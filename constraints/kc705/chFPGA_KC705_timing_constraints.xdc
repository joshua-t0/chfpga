######################################
# TIMING CONSTRAINTS
######################################
create_clock -period 2.350 -name ADCCLK1 -waveform {0.000 1.175} [get_ports ADC0_BDRP]
create_generated_clock -name ADC_CLK_SLAVE -source [get_ports ADC0_BDRP] -multiply_by 1 [get_ports {ADC0_ADRP ADC0_CDRP ADC0_DDRP}]
create_clock -period 5.000 -name SYSCLK -waveform {0.000 2.500} [get_ports SYSCLK_P]
create_clock -period 8.000 -name PHY_RXCLK -waveform {0.000 4.000} [get_ports PHY_RXCLK]
create_clock -period 100.000 -name REFCLK_M2C -waveform {0.000 50.000} [get_ports REFCLK_M2C_P]
#create_clock -period 100.000 -name CLK10 -waveform {0.000 50.000} [get_nets CHFPGA0/REFCLK0/CLK10]
#create_clock -period 5.000 -name FREQ_CTR_SRC_CLOCK -waveform {0.000 2.500} [get_nets CHFPGA0/FREQ_CTR0/SRC_CLK_FABRIC]
create_clock -period 5.000 -name CLK200 -waveform {0.000 2.500} [get_nets CHFPGA0/CLK0/CLK200_MMCM_NOBUF]
#create_clock -period 8.000 -name CLK125 -waveform {0.000 4.000} [get_nets CHFPGA0/CLK0/CLK125_NOBUF]
#create_clock -period 4.000 -name CORR_CLK -waveform {0.000 2.000} [get_nets CHFPGA0/CLK0/CORR_CLK_NOBUF]
set_clock_groups -name CLK200_GROUP -asynchronous -group [get_clocks CLK200]
create_clock -period 2.350 -name ADCCLK4 -waveform {0.000 1.175} [get_ports ADC1_ADRP]
create_clock -period 2.350 -name ADCCLK5 -waveform {0.000 1.175} [get_ports ADC1_BDRP]
create_clock -period 2.350 -name ADCCLK6 -waveform {0.000 1.175} [get_ports ADC1_CDRP]
create_clock -period 2.350 -name ADCCLK7 -waveform {0.000 1.175} [get_ports ADC1_DDRP]
set_clock_groups -name ADCCLK_GROUP -asynchronous -group [get_clocks -include_generated_clocks ADCCLK?]
#set_clock_groups -name CLK125_GROUP -asynchronous -group [get_clocks -include_generated_clocks CLK125]
set_clock_groups -name SYSCLK_GROUP -asynchronous -group [get_clocks -include_generated_clocks SYSCLK]
set_clock_groups -name REFCLK_GROUP -asynchronous -group [get_clocks -include_generated_clocks REFCLK_M2C]
#set_clock_groups -name CLK10_GROUP -asynchronous -group [get_clocks -include_generated_clocks CLK10]
set_false_path -from [get_cells -match_style UCF *TIMING_IGNORE*]
set_false_path -through [get_cells -match_style UCF *TIMING_IGNORE*]
#set_clock_groups -name FREQ_CTR_GROUP -asynchronous -group [get_clocks FREQ_CTR_SRC_CLOCK]
set_clock_groups -name CLK125_GROUP -asynchronous -group [get_clocks n_1_MMCM0]






