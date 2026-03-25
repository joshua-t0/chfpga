######################################
# TIMING CONSTRAINTS
######################################
create_clock -period 2.5 -name ADCCLK1 -waveform {0.000 1.25} [get_ports adc0_bdrp]
create_clock -period 2.5 -name ADCCLK0 -waveform {0.000 1.25} [get_ports adc0_adrp]
create_clock -period 2.5 -name ADCCLK2 -waveform {0.000 1.25} [get_ports adc0_cdrp]
create_clock -period 2.5 -name ADCCLK3 -waveform {0.000 1.25} [get_ports adc0_ddrp]
create_clock -period 2.5 -name ADCCLK4 -waveform {0.000 1.25} [get_ports adc1_adrp]
create_clock -period 2.5 -name ADCCLK5 -waveform {0.000 1.25} [get_ports adc1_bdrp]
create_clock -period 2.5 -name ADCCLK6 -waveform {0.000 1.25} [get_ports adc1_cdrp]
create_clock -period 2.5 -name ADCCLK7 -waveform {0.000 1.25} [get_ports adc1_ddrp]
#create_generated_clock -name ADC_CLK_SLAVE -source [get_ports adc0_bdrp] -multiply_by 1 [get_ports {adc0_adrp adc0_cdrp adc0_ddrp}]

create_clock -period 5.000 -name SYSCLK -waveform {0.000 2.500} [get_ports sysclk_p]
create_clock -period 8.000 -name PHY_RXCLK -waveform {0.000 4.000} [get_ports phy_rxclk]
create_clock -period 100.000 -name REFCLK_M2C -waveform {0.000 50.000} [get_ports refclk_m2c_p]
create_clock -period 100.000 -name MGT_PLL_M2C_CLK -waveform {0.000 50.000} [get_ports mgt_pll_m2c_p]
create_clock -period 100.000 -name REFCLK_SMA -waveform {0.000 50.000} [get_ports user_sma_clock_p]
#create_clock -period 100.000 -name CLK10 -waveform {0.000 50.000} [get_nets CHFPGA0/REFCLK0/CLK10]
#create_clock -period 5.000 -name FREQ_CTR_SRC_CLOCK -waveform {0.000 2.500} [get_nets CHFPGA0/FREQ_CTR0/SRC_CLK_FABRIC]
#create_clock -period 5.000 -name CLK200 -waveform {0.000 2.500} [get_nets CHFPGA0/CLK0/CLK200_MMCM_NOBUF]
#create_clock -period 8.000 -name CLK125 -waveform {0.000 4.000} [get_nets CHFPGA0/CLK0/CLK125_NOBUF]
#create_clock -period 4.000 -name CORR_CLK -waveform {0.000 2.000} [get_nets CHFPGA0/CLK0/CORR_CLK_NOBUF]
set_clock_groups -name CLK200_GROUP -asynchronous -group [get_clocks clk200_nobuf]
set_clock_groups -name ADCCLK_GROUP -asynchronous -group [get_clocks -include_generated_clocks ADCCLK?]
#set_clock_groups -name CLK125_GROUP -asynchronous -group [get_clocks -include_generated_clocks CLK125]
set_clock_groups -name SYSCLK_GROUP -asynchronous -group [get_clocks -include_generated_clocks SYSCLK]
set_clock_groups -name REFCLK_GROUP -asynchronous -group [get_clocks -include_generated_clocks REFCLK_M2C]
#set_clock_groups -name CLK10_GROUP -asynchronous -group [get_clocks -include_generated_clocks CLK10]
# set_false_path -from [get_cells -match_style UCF *TIMING_IGNORE*]
# set_false_path -through [get_cells -match_style UCF *TIMING_IGNORE*]
#set_clock_groups -name FREQ_CTR_GROUP -asynchronous -group [get_clocks FREQ_CTR_SRC_CLOCK]
# set_clock_groups -name CLK125_GROUP -asynchronous -group [get_clocks n_1_MMCM0]

# Set the frequency counter clock (clock is outputted by a fabric mux)
create_clock -period 3.200 -name FREQ_CTR [get_pins */*.system0/freq_ctr_blk.freq_ctr0/srcclk_bufg_gen*.bufh0/I]
set_clock_groups -name FREQ_CTR_GROUP -asynchronous -group [get_clocks FREQ_CTR]



# Ignore the reset path for the FIFOs in generic_fifo
set_false_path -to [get_pins -of_objects [get_cells -hier -filter {RST_FALSE_PATH == "TRUE"}] -filter {REF_PIN_NAME == RST}]






