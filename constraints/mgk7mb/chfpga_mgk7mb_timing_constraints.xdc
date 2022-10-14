######################################
# TIMING CONSTRAINTS
######################################

# Tell the tool to analyze only the timing when the ADCCLK is selected by the chan_mmcm (as opposed to the internal 200 MHz clock)
# The following line does this by forcing the CLKINSEL input to '0'
set_case_analysis 1 [get_pins -hierarchical gen_chanpll_k7.chan_mmcm0/CLKINSEL]


# ADC clocks
# ----------
create_clock -period 2.350 -name ADCCLK0 -waveform {0.000 1.175} [get_ports fmca_adc0_adrp]
create_clock -period 2.350 -name ADCCLK1 -waveform {0.000 1.175} [get_ports fmca_adc0_bdrp]
create_clock -period 2.350 -name ADCCLK2 -waveform {0.000 1.175} [get_ports fmca_adc0_cdrp]
create_clock -period 2.350 -name ADCCLK3 -waveform {0.000 1.175} [get_ports fmca_adc0_ddrp]
#create_generated_clock -name ADC_CLK_SLAVE -source [get_ports fmca_adc0_bdrp] -multiply_by 1 [get_ports {fmca_adc0_adrp fmca_adc0_cdrp fmca_adc0_ddrp}]
create_clock -period 2.350 -name ADCCLK4 -waveform {0.000 1.175} [get_ports fmca_adc1_adrp]
create_clock -period 2.350 -name ADCCLK5 -waveform {0.000 1.175} [get_ports fmca_adc1_bdrp]
create_clock -period 2.350 -name ADCCLK6 -waveform {0.000 1.175} [get_ports fmca_adc1_cdrp]
create_clock -period 2.350 -name ADCCLK7 -waveform {0.000 1.175} [get_ports fmca_adc1_ddrp]

create_clock -period 2.350 -name ADCCLK8 -waveform {0.000 1.175} [get_ports fmcb_adc0_adrp]
create_clock -period 2.350 -name ADCCLK9 -waveform {0.000 1.175} [get_ports fmcb_adc0_bdrp]
create_clock -period 2.350 -name ADCCLK10 -waveform {0.000 1.175} [get_ports fmcb_adc0_cdrp]
create_clock -period 2.350 -name ADCCLK11 -waveform {0.000 1.175} [get_ports fmcb_adc0_ddrp]
create_clock -period 2.350 -name ADCCLK12 -waveform {0.000 1.175} [get_ports fmcb_adc1_adrp]
create_clock -period 2.350 -name ADCCLK13 -waveform {0.000 1.175} [get_ports fmcb_adc1_bdrp]
create_clock -period 2.350 -name ADCCLK14 -waveform {0.000 1.175} [get_ports fmcb_adc1_cdrp]
create_clock -period 2.350 -name ADCCLK15 -waveform {0.000 1.175} [get_ports fmcb_adc1_ddrp]


# Make all ADC clocks asynchronous to any other clocks
set_clock_groups -name ADCCLK0_GROUP -asynchronous -group [get_clocks -include_generated_clocks ADCCLK0]
set_clock_groups -name ADCCLK1_GROUP -asynchronous -group [get_clocks -include_generated_clocks ADCCLK1]
set_clock_groups -name ADCCLK2_GROUP -asynchronous -group [get_clocks -include_generated_clocks ADCCLK2]
set_clock_groups -name ADCCLK3_GROUP -asynchronous -group [get_clocks -include_generated_clocks ADCCLK3]
set_clock_groups -name ADCCLK4_GROUP -asynchronous -group [get_clocks -include_generated_clocks ADCCLK4]
set_clock_groups -name ADCCLK5_GROUP -asynchronous -group [get_clocks -include_generated_clocks ADCCLK5]
set_clock_groups -name ADCCLK6_GROUP -asynchronous -group [get_clocks -include_generated_clocks ADCCLK6]
set_clock_groups -name ADCCLK7_GROUP -asynchronous -group [get_clocks -include_generated_clocks ADCCLK7]

set_clock_groups -name ADCCLK8_GROUP -asynchronous -group [get_clocks -include_generated_clocks ADCCLK8]
set_clock_groups -name ADCCLK9_GROUP -asynchronous -group [get_clocks -include_generated_clocks ADCCLK9]
set_clock_groups -name ADCCLK10_GROUP -asynchronous -group [get_clocks -include_generated_clocks ADCCLK10]
set_clock_groups -name ADCCLK11_GROUP -asynchronous -group [get_clocks -include_generated_clocks ADCCLK11]
set_clock_groups -name ADCCLK12_GROUP -asynchronous -group [get_clocks -include_generated_clocks ADCCLK12]
set_clock_groups -name ADCCLK13_GROUP -asynchronous -group [get_clocks -include_generated_clocks ADCCLK13]
set_clock_groups -name ADCCLK14_GROUP -asynchronous -group [get_clocks -include_generated_clocks ADCCLK14]
set_clock_groups -name ADCCLK15_GROUP -asynchronous -group [get_clocks -include_generated_clocks ADCCLK15]

# Remove timing constraints from the FIFO Reset signal
#set_false_path -from [get_pins {chfpga0/ADCGEN[*].ADCDAQ0/IMPL.FIFO_RST_INT_reg/C}] -to [get_pins {chfpga0/ADCGEN[*].ADCDAQ0/IMPL.FIFO_RST_reg/D}]

#set_clock_groups -name ADCCLK_GROUP -asynchronous -group [get_clocks -include_generated_clocks ADCCLK?]

# 10 MHz Reference clocks from the Mezzanines.
# -------------------------------------------
# These are used to generate accurate ADC SYNC signals relative to the ADC 1600 MHZ clock.
# Those are also measured by the Frequency counter
create_clock -period 100.000 -name FMCA_REFCLK_M2C -waveform {0.000 50.000} [get_ports fmca_refclk_m2c_p]
create_clock -period 100.000 -name FMCB_REFCLK_M2C -waveform {0.000 50.000} [get_ports fmcb_refclk_m2c_p]

# Timing with any other clocks is to be ignored
set_clock_groups -name FMCA_REFCLK_GROUP -asynchronous -group [get_clocks -include_generated_clocks FMCA_REFCLK_M2C]
set_clock_groups -name FMCB_REFCLK_GROUP -asynchronous -group [get_clocks -include_generated_clocks FMCB_REFCLK_M2C]

# 10 MHz Reference clocks from the FPGA
# -------------------------------------------
# Used to sequence the SYNC state machine. The ADCDAQ reset is registered on this clock.
# Is also used to trigger IRIG-B time capture in order to measure the drift betreen the He maser and the GPS.
# Is monitored by the frequency counter.

create_clock -period 100.000 -name mgt_clk10_p -waveform {0.000 50.000} [get_ports mgt_clk10_p]

# This clock generates the sync and async signals that reset the ADCDAQ logic. CDC is handled there.
# The IRIG-B capture CBC is also handled in the HDL
# We don't want the timing between this clock and other clock to be considered
set_clock_groups -name REFCLK_GROUP -asynchronous -group [get_clocks -include_generated_clocks mgt_clk10_p]


# Frequency counter
# ----------------
# Constrain the frequency counter clock. The clock frequency on this net is 1/2 if the measured clock source
create_clock -period 3.200 -name FREQ_CTR [get_pins */FREQ_CTR0/K7.SRCCLK0/I]
set_clock_groups -name FREQ_CTR_GROUP -asynchronous -group [get_clocks FREQ_CTR]

# Motherboard raw (single-ended) 10 MHz Reference clock
# -----------------------------------------------------
# This clock is on a single-ended, not-clock-capable pin, so it is not good enough and routable-enough to be used as an reference.
# Is only monitored by the Frequency counter for QC purposes.
create_clock -period 100.000 -name raw_clk10 -waveform {0.000 50.000} [get_ports raw_clk10]

# SGMII interface constraints
# ---------------------------
# 125 MHz reference
# Used to clock the 1G Ethernet subsystem (SGMII).
# Also feeds a MMCM to generate the internal 200 MHz, control systel clock (CLK125), SYSMON clock and CORR clock
create_clock -period 8.000 -name SFP_CLK [get_ports sfp_clk_p]
create_clock -period 8.000 -name arm_spi_virt_clk
# Make unrelated MMCM-generated system clocks independent from the other clocks
set_clock_groups -name ARM_SPI_CLK_GROUP -asynchronous -group [get_clocks -include_generated_clocks {arm_spi_virt_clk}]
set_clock_groups -name CLK125_GROUP -asynchronous -group [get_clocks -include_generated_clocks {CLK125_NOBUF}]
set_clock_groups -name SYSMON_CLK_GROUP -asynchronous -group [get_clocks -include_generated_clocks SYSMON_CLK_NOBUF]
set_clock_groups -name CORR_CLK_GROUP -asynchronous -group [get_clocks -include_generated_clocks CORR_CLK_NOBUF]

# Vivado 2016.2 does not seem to automatically create GTX TXOUTCLK clocks
# Belay that. No, it's defined in the sgmii xdc file. For some reason a previous compile ignored that.
# create_clock -period 16 -name sgmii_txclk [get_pins  {chfpga0/gen_eth.udp_mac0/sgmiigen.sgmii0/core_wrapper/U0/transceiver_inst/gtwizard_inst/U0/gtwizard_i/gt0_GTWIZARD_i/gtxe2_i/TXOUTCLK}]
# set_clock_groups -name SGMII_CLOCK_GROUP -asynchronous -group [get_clocks -include_generated_clocks sgmii_txclk]

# Clock period for the recovered Rx clock
# This clock is now automatically defined by the core itself
# create_clock -period 16.000 -name sgmii_rxclk [get_pins chfpga0/gen_eth.udp_mac0/sgmiigen.sgmii0/core_wrapper/U0/transceiver_inst/gtwizard_inst/*/gtwizard_i/gt0_GTWIZARD_i/gtxe2_i/RXOUTCLK]

# Clock period for the Txout clock
# This clock is now automatically defined by the core itself
# create_clock -period 16.000 -name sgmii_txclk [get_pins chfpga0/gen_eth.udp_mac0/sgmiigen.sgmii0/core_wrapper/U0/transceiver_inst/gtwizard_inst/*/gtwizard_i/gt0_GTWIZARD_i/gtxe2_i/TXOUTCLK]

# set_clock_groups -name sgmii_txclk_group -asynchronous -group [get_clocks -include_generated_clocks sgmii_txclk]

set_clock_groups -name sgmii_txclk_group -asynchronous -group [get_clocks -include_generated_clocks -of_objects [get_pins chfpga0/gen_eth.udp_mac0/sgmiigen.sgmii0/core_wrapper/U0/transceiver_inst/gtwizard_inst/*/gtwizard_i/gt0_GTWIZARD_i/gtxe2_i/TXOUTCLK]]

# The following clocks are not used except for monitoring their frequency during board QC
# ----------------------------------------
create_clock -period 6.400 -name {fmca_mgt_pll_refclk_p[0]} -waveform {0.000 3.200} [get_ports {fmca_mgt_pll_refclk_p[0]}]
create_clock -period 6.400 -name {fmca_mgt_pll_refclk_p[1]} -waveform {0.000 3.200} [get_ports {fmca_mgt_pll_refclk_p[1]}]
create_clock -period 6.400 -name {fmcb_mgt_pll_refclk_p[0]} -waveform {0.000 3.200} [get_ports {fmcb_mgt_pll_refclk_p[0]}]
create_clock -period 6.400 -name {fmcb_mgt_pll_refclk_p[1]} -waveform {0.000 3.200} [get_ports {fmcb_mgt_pll_refclk_p[1]}]
create_clock -period 10.000 -name mgt_clk100_p -waveform {0.000 5.000} [get_ports mgt_clk100_p]
create_clock -period 8.000 -name mgt_clk125_p -waveform {0.000 4.000} [get_ports mgt_clk125_p]
create_clock -period 5.000 -name mgt_clk200_p -waveform {0.000 2.500} [get_ports mgt_clk200_p]


################
# GPU LINKS (10G Ethernet)
################

create_clock -period 6.400 -name GPU_REFCLK [get_ports {xge_refclk_p[*]}]
set_clock_groups -name GPU_REFCLK_GROUP -asynchronous -group [get_clocks -include_generated_clocks GPU_REFCLK]

create_clock -period 3.103 -name gpu_rxclks [get_pins {chfpga0/GPUGEN.gpulink0/xglink0/gtx_gen[*].gtx_i/gtxe2_i/RXOUTCLK}]

create_clock -period 3.103 -name gpu_txclk [get_pins {chfpga0/GPUGEN.gpulink0/xglink0/gtx_gen[0].gtx_i/gtxe2_i/TXOUTCLK}]
set_clock_groups -name gpu_txclk_group -asynchronous -group [get_clocks -include_generated_clocks gpu_txclk]

################
# BP SHUFFLE (7.5 Gbps custom protocol)
################
# create_clock -period 6.400 -name bp_shuffle_refclk0 [get_pins -hier -filter {name=~*bp_shuffle*quad_gen[0]*gtxe2_common_0_i*GTREFCLK0}]
# create_clock -name GT0_GTREFCLK0_COMMON_IN -period 6.4 [get_pins -hier -filter {name=~*common0_i*gtxe2_common_i*GTREFCLK0}]
# create_clock -name GT1_GTREFCLK0_COMMON_IN -period 6.4 [get_pins -hier -filter {name=~*common1_i*gtxe2_common_i*GTREFCLK0}]
# create_clock -name drpclk_in_i -period 8.0 [get_pins -hier -filter {name=~*shuffle_gtx_support_i*gt_usrclk_source*DRP_CLK_BUFG*I}]

create_clock -period 6.400 -name bp_shuffle_refclk0 -waveform {0.000 3.200} [get_ports {bp_shuffle_refclk_p[*]}]
set_clock_groups -name bp_shuffle_refclk_group -asynchronous -group [get_clocks -include_generated_clocks bp_shuffle_refclk0]

# The GTX requires us to specify a constraint for the RX and TX clock. These are not derived from the reference clock.
# For the RX clock, we buldle all of the GTX RX clock in one constraint
create_clock -period 4.096 -name bp_rxclks [get_pins {chfpga0/BPSHFGEN.bp_shuffle0/core0/gtx_gen[*].gtx_i/gtxe2_i/RXOUTCLK}]
# For the tx clock, we use only the clock from lane 0.
create_clock -period 4.096 -name bp_txclk [get_pins {chfpga0/BPSHFGEN.bp_shuffle0/core0/gtx_gen[0].gtx_i/gtxe2_i/TXOUTCLK}]
# We create a constraint to ignore any interaction with the tx clock and other clocks
set_clock_groups -name bp_txclk_group -asynchronous -group [get_clocks -include_generated_clocks bp_txclk]

# User Clock Constraints

# create_clock -period 6.400 -name bp_shuffle_refclk [get_ports {bp_shuffle_refclk_p[*]}]

# ARM SPI clock
################
# The ARM SPI signals are sampled on the 125 MHz clock (the SPI clock is not used directly to capture and set data).
# We refer the timing of these signals to a virtual clock (arm_spi_virt_clk) which acts as a fixed external reference.
# We set the input delay relative to this clock, so if anything changes in the FPGA timing we are more likely to know about it.
# It may make the timing of the routing more predictable.
#
# The delay is set to roughly take into account the min (fast) and max (slow) delay caused between the external virtual clock and the CLK125 clock.
# Really, it would be better to sample the SPI signal on their SPI clocks. Some problems have been reported with the current set-up by others.

set_input_delay -clock [get_clocks arm_spi_virt_clk] 4.0 [get_ports {arm_spi_sck arm_spi_cs_n arm_spi_mosi}]

# FMC SPI clock
################

set_input_delay -clock [get_clocks arm_spi_virt_clk] 4.0 [get_ports {fmc?_spi_miso}]

# I2C clock
################
create_clock -period 1000 -name i2c_clk [get_ports i2c_scl]
set_clock_groups -name i2c_clk_group -asynchronous -group [get_clocks -include_generated_clocks i2c_clk]

set_input_delay -clock [get_clocks i2c_clk] 0.0 [get_ports {i2c_sda}]

# Ignore input delays and timing on asynchronously-sampled inputs
################
set_input_delay -clock [get_clocks arm_spi_virt_clk] 0.0 [get_ports {bp_gpio_int fmc?_adc_pll_lock fpga_led1_bp_sma sma_b_fpga_led2}]
set_false_path -from [get_ports {bp_gpio_int fmc?_adc_pll_lock fpga_led1_bp_sma sma_b_fpga_led2}]

set_input_delay -clock [get_clocks arm_spi_virt_clk] 0.0 [get_ports {arm_irq_n bp_buck_sync cpu_reset_n flash_spi_cs_n gpio_irq_n gpio_rst_n uart_rx uart_tx}]
set_false_path -from [get_ports {arm_irq_n bp_buck_sync cpu_reset_n flash_spi_cs_n gpio_irq_n gpio_rst_n uart_rx uart_tx}]


#create_clock -period 100.000 -name CLK10 -waveform {0.000 50.000} [get_nets CHFPGA0/REFCLK0/CLK10]
#create_clock -period 5.000 -name FREQ_CTR_SRC_CLOCK -waveform {0.000 2.500} [get_nets CHFPGA0/FREQ_CTR0/SRC_CLK_FABRIC]

#


#create_clock -period 5.000 -name CLK200 -waveform {0.000 2.500} [get_nets CHFPGA0/CLK0/CLK200_MMCM_NOBUF]
#create_clock -period 8.000 -name CLK125 -waveform {0.000 4.000} [get_nets CHFPGA0/CLK0/CLK125_NOBUF]
#create_clock -period 4.000 -name CORR_CLK -waveform {0.000 2.000} [get_nets CHFPGA0/CLK0/CORR_CLK_NOBUF]
#set_clock_groups -name CLK200_GROUP -asynchronous -group [get_clocks CLK200]
#set_clock_groups -name SYSCLK_GROUP -asynchronous -group [get_clocks -include_generated_clocks SYSCLK]
#set_clock_groups -name CLK10_GROUP -asynchronous -group [get_clocks -include_generated_clocks CLK10]
#set_clock_groups -name CLK125_GROUP -asynchronous -group [get_clocks n_1_MMCM0]

#set_false_path -from [get_cells -match_style UCF *TIMING_IGNORE*]
#set_false_path -through [get_cells -match_style UCF *TIMING_IGNORE*]
#set_clock_groups -name FREQ_CTR_GROUP -asynchronous -group [get_clocks FREQ_CTR_SRC_CLOCK]

#set_false_path -from [get_cells chfpga0/CLK0/*TIMING_IGNORE_reg]

#set_false_path -from [get_cells *TIMING_IGNORE* -hierarchical]

############################
# Clocking exceptions
############################

# Ignore path from the internal 200 MHz to the channel clock 0
# There is one path between the IRIG-B output and the event capture register used to capture the frame number (on chan clock)  and IRIG-B time (on clk200)
set_false_path -from [get_clocks CLK200_MMCM_NOBUF] -to [get_clocks {chan_clk_nobuf[0]}]


# Eliminate paths ending to synchronizing registers in the clock module (CLK0)
set_false_path -to [get_cells -hierarchical -filter {NAME =~ "*/CLK0/*" && ASYNC_REG == TRUE}]

#set_false_path -through [get_ports rst] -to [get_pins inst_fifo_gen/gconvfifo.rf/grf.rf/rstblk/*/CLR]

set_false_path -from [get_clocks divclk_local_d_3] -to [get_clocks {chan_clk_nobuf[0]}]

# adc-send_data_reg1 signals come from multiple clocks. Ignore the timing to that register. That register has a ASYNC_REG=True property.
set_false_path -to [get_pins {chfpga0/ADCGEN[*].adc_send_data_reg1_reg[*]/D}]


# create_clock -period 1000.000 -name fmca_spi_sck -waveform {0.000 500.000} [get_ports fmca_spi_sck]
# set_output_delay -clock [get_clocks fmca_spi_sck] 0.000 [get_ports fmca_spi_mosi]

# ADC input delays
# Vivado does not take into account the fact that we use a delay line and that we don't care if we capture one or more samples after the clock.
# If we just put the ADC output delays, we end up with setup and hold violations.
# We fix this by offseting the input delays with the propagation time of the data and the clock in the FPGA.
# (we tried the option -network_latency_included or -source_latency_included but they don't seem to do anything).

# ADC spec: setup: 0.4 - 0.6 ns, hold: 0.2-0.4 ns
# In the FPGA, data arrives earlier than the clock due to the multiple clock buffers (BUFMR, BUFIO)
# For the hold time, analysis is done rising edge to rising edge. The clock to data skew is
#   - 2.16 ns without BUFMR => min_delay = hold_min + 2.16 ns = 2.36 ns
#   - 3.6 ns with BUFMR . => min_delay = hold_min + 3.6 ns = 3.8 ns
#
# For the setup time, new data is placed on the bus by the ADC on the rising edge and is to be be sampled on the falling edge of the clock.
# The clock to data skew is (excluding the 1.175 ns offset added because we sample on the following edge)
#   - 0.530 ns without BUFMR => max_delay = (1.175-setup_min) + 1.081 = 1.305 ns (ADCCLK1,7,9)
#   - 1.081 ns with BUFMR  => max_delay = (1.175-setup_min) + 1.081 = 1.856 ns
#

set_input_delay -clock [get_clocks ADCCLK0] -min 3.8 [get_ports {fmca_adc0_ahdp[*]}]
set_input_delay -clock [get_clocks ADCCLK0] -max 1.856 [get_ports {fmca_adc0_ahdp[*]}]
set_input_delay -clock [get_clocks ADCCLK0] -clock_fall -min -add_delay 3.8 [get_ports {fmca_adc0_ahdp[*]}]
set_input_delay -clock [get_clocks ADCCLK0] -clock_fall -max -add_delay 1.856 [get_ports {fmca_adc0_ahdp[*]}]

set_input_delay -clock [get_clocks ADCCLK1] -min 2.36 [get_ports {fmca_adc0_bhdp[*]}]
set_input_delay -clock [get_clocks ADCCLK1] -max 1.305 [get_ports {fmca_adc0_bhdp[*]}]
set_input_delay -clock [get_clocks ADCCLK1] -clock_fall -min -add_delay 2.36 [get_ports {fmca_adc0_bhdp[*]}]
set_input_delay -clock [get_clocks ADCCLK1] -clock_fall -max -add_delay 1.305 [get_ports {fmca_adc0_bhdp[*]}]

set_input_delay -clock [get_clocks ADCCLK2] -min 3.8 [get_ports {fmca_adc0_chdp[*]}]
set_input_delay -clock [get_clocks ADCCLK2] -max 1.856 [get_ports {fmca_adc0_chdp[*]}]
set_input_delay -clock [get_clocks ADCCLK2] -clock_fall -min -add_delay 3.8 [get_ports {fmca_adc0_chdp[*]}]
set_input_delay -clock [get_clocks ADCCLK2] -clock_fall -max -add_delay 1.856 [get_ports {fmca_adc0_chdp[*]}]

set_input_delay -clock [get_clocks ADCCLK3] -min 3.8 [get_ports {fmca_adc0_dhdp[*]}]
set_input_delay -clock [get_clocks ADCCLK3] -max 1.856 [get_ports {fmca_adc0_dhdp[*]}]
set_input_delay -clock [get_clocks ADCCLK3] -clock_fall -min -add_delay 3.8 [get_ports {fmca_adc0_dhdp[*]}]
set_input_delay -clock [get_clocks ADCCLK3] -clock_fall -max -add_delay 1.856 [get_ports {fmca_adc0_dhdp[*]}]

set_input_delay -clock [get_clocks ADCCLK4] -min 3.8 [get_ports {fmca_adc1_ahdp[*]}]
set_input_delay -clock [get_clocks ADCCLK4] -max 1.856 [get_ports {fmca_adc1_ahdp[*]}]
set_input_delay -clock [get_clocks ADCCLK4] -clock_fall -min -add_delay 3.8 [get_ports {fmca_adc1_ahdp[*]}]
set_input_delay -clock [get_clocks ADCCLK4] -clock_fall -max -add_delay 1.856 [get_ports {fmca_adc1_ahdp[*]}]

set_input_delay -clock [get_clocks ADCCLK5] -min 3.8 [get_ports {fmca_adc1_bhdp[*]}]
set_input_delay -clock [get_clocks ADCCLK5] -max 1.856 [get_ports {fmca_adc1_bhdp[*]}]
set_input_delay -clock [get_clocks ADCCLK5] -clock_fall -min -add_delay 3.8 [get_ports {fmca_adc1_bhdp[*]}]
set_input_delay -clock [get_clocks ADCCLK5] -clock_fall -max -add_delay 1.856 [get_ports {fmca_adc1_bhdp[*]}]

set_input_delay -clock [get_clocks ADCCLK6] -min 3.8 [get_ports {fmca_adc1_chdp[*]}]
set_input_delay -clock [get_clocks ADCCLK6] -max 1.856 [get_ports {fmca_adc1_chdp[*]}]
set_input_delay -clock [get_clocks ADCCLK6] -clock_fall -min -add_delay 3.8 [get_ports {fmca_adc1_chdp[*]}]
set_input_delay -clock [get_clocks ADCCLK6] -clock_fall -max -add_delay 1.856 [get_ports {fmca_adc1_chdp[*]}]

set_input_delay -clock [get_clocks ADCCLK7] -min 2.36 [get_ports {fmca_adc1_dhdp[*]}]
set_input_delay -clock [get_clocks ADCCLK7] -max 1.305 [get_ports {fmca_adc1_dhdp[*]}]
set_input_delay -clock [get_clocks ADCCLK7] -clock_fall -min -add_delay 2.36 [get_ports {fmca_adc1_dhdp[*]}]
set_input_delay -clock [get_clocks ADCCLK7] -clock_fall -max -add_delay 1.305 [get_ports {fmca_adc1_dhdp[*]}]

set_input_delay -clock [get_clocks ADCCLK8] -min 3.8 [get_ports {fmcb_adc0_ahdp[*]}]
set_input_delay -clock [get_clocks ADCCLK8] -max 1.856 [get_ports {fmcb_adc0_ahdp[*]}]
set_input_delay -clock [get_clocks ADCCLK8] -clock_fall -min -add_delay 3.8 [get_ports {fmcb_adc0_ahdp[*]}]
set_input_delay -clock [get_clocks ADCCLK8] -clock_fall -max -add_delay 1.856 [get_ports {fmcb_adc0_ahdp[*]}]

set_input_delay -clock [get_clocks ADCCLK9] -min 2.36 [get_ports {fmcb_adc0_bhdp[*]}]
set_input_delay -clock [get_clocks ADCCLK9] -max 1.305 [get_ports {fmcb_adc0_bhdp[*]}]
set_input_delay -clock [get_clocks ADCCLK9] -clock_fall -min -add_delay 2.36 [get_ports {fmcb_adc0_bhdp[*]}]
set_input_delay -clock [get_clocks ADCCLK9] -clock_fall -max -add_delay 1.305 [get_ports {fmcb_adc0_bhdp[*]}]

set_input_delay -clock [get_clocks ADCCLK10] -min 3.8 [get_ports {fmcb_adc0_chdp[*]}]
set_input_delay -clock [get_clocks ADCCLK10] -max 1.856 [get_ports {fmcb_adc0_chdp[*]}]
set_input_delay -clock [get_clocks ADCCLK10] -clock_fall -min -add_delay 3.8 [get_ports {fmcb_adc0_chdp[*]}]
set_input_delay -clock [get_clocks ADCCLK10] -clock_fall -max -add_delay 1.856 [get_ports {fmcb_adc0_chdp[*]}]

set_input_delay -clock [get_clocks ADCCLK11] -min 3.8 [get_ports {fmcb_adc0_dhdp[*]}]
set_input_delay -clock [get_clocks ADCCLK11] -max 1.856 [get_ports {fmcb_adc0_dhdp[*]}]
set_input_delay -clock [get_clocks ADCCLK11] -clock_fall -min -add_delay 3.8 [get_ports {fmcb_adc0_dhdp[*]}]
set_input_delay -clock [get_clocks ADCCLK11] -clock_fall -max -add_delay 1.856 [get_ports {fmcb_adc0_dhdp[*]}]

set_input_delay -clock [get_clocks ADCCLK12] -min 3.8 [get_ports {fmcb_adc1_ahdp[*]}]
set_input_delay -clock [get_clocks ADCCLK12] -max 1.856 [get_ports {fmcb_adc1_ahdp[*]}]
set_input_delay -clock [get_clocks ADCCLK12] -clock_fall -min -add_delay 3.8 [get_ports {fmcb_adc1_ahdp[*]}]
set_input_delay -clock [get_clocks ADCCLK12] -clock_fall -max -add_delay 1.856 [get_ports {fmcb_adc1_ahdp[*]}]

set_input_delay -clock [get_clocks ADCCLK13] -min 3.8 [get_ports {fmcb_adc1_bhdp[*]}]
set_input_delay -clock [get_clocks ADCCLK13] -max 1.856 [get_ports {fmcb_adc1_bhdp[*]}]
set_input_delay -clock [get_clocks ADCCLK13] -clock_fall -min -add_delay 3.8 [get_ports {fmcb_adc1_bhdp[*]}]
set_input_delay -clock [get_clocks ADCCLK13] -clock_fall -max -add_delay 1.856 [get_ports {fmcb_adc1_bhdp[*]}]

set_input_delay -clock [get_clocks ADCCLK14] -min 3.8 [get_ports {fmcb_adc1_chdp[*]}]
set_input_delay -clock [get_clocks ADCCLK14] -max 1.856 [get_ports {fmcb_adc1_chdp[*]}]
set_input_delay -clock [get_clocks ADCCLK14] -clock_fall -min -add_delay 3.8 [get_ports {fmcb_adc1_chdp[*]}]
set_input_delay -clock [get_clocks ADCCLK14] -clock_fall -max -add_delay 1.856 [get_ports {fmcb_adc1_chdp[*]}]

set_input_delay -clock [get_clocks ADCCLK15] -min 3.8 [get_ports {fmcb_adc1_dhdp[*]}]
set_input_delay -clock [get_clocks ADCCLK15] -max 1.856 [get_ports {fmcb_adc1_dhdp[*]}]
set_input_delay -clock [get_clocks ADCCLK15] -clock_fall -min -add_delay 3.8 [get_ports {fmcb_adc1_dhdp[*]}]
set_input_delay -clock [get_clocks ADCCLK15] -clock_fall -max -add_delay 1.856 [get_ports {fmcb_adc1_dhdp[*]}]


















































