set_property BITSTREAM.CONFIG.USR_ACCESS TIMESTAMP [current_design]
set_property BITSTREAM.GENERAL.COMPRESS true [current_design]

##################################################################
##################################################################
## Physical Constraints for the MGK7MB Rev0 ICEBOARD (7K420FFG901-2)  ##
##################################################################
##################################################################

#set_property IOSTANDARD LVCMOS18 [get_ports SFPCLK_QO_P]


#################################
# TIMING CONSTRAINTS
#################################
# The following is because the SYSCLK BUFG and BUFGMUX on ANT[1].ADCDAQ are not in the same half. Should be f
#set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets CLK0/CLK200]


#################################
# LOC CONSTRAINTS
#################################
# Force the CLK0 MMCM to be in the same half of the FPGA as the ADCDAQ PLL so their outputs can reach a single BUFGMUX that select which clock is to be used for data processing. 
#set_property LOC MMCME2_ADV_X0Y4 [get_cells CLK0/CLK200/MMCM0]


#################################
# SYSTEM CLOCK and RESET PINS
#################################
# set_property IOSTANDARD LVDS [get_ports SYSCLK_P]
# set_property DIFF_TERM FALSE [get_ports SYSCLK_P]
# set_property DIFF_TERM FALSE [get_ports SYSCLK_N]
# #set_property DIFF_TERM FALSE [get_ports SYSCLK_N]
# set_property PACKAGE_PIN AD12 [get_ports SYSCLK_P]
# set_property PACKAGE_PIN AD11 [get_ports SYSCLK_N]
# set_property PACKAGE_PIN AB7 [get_ports cpu_reset_n]
# set_property IOSTANDARD LVCMOS15 [get_ports CPU_RESET]

# RESET is on ARM_RST_O
# NOTE: *** THIS AN ACTIVE LOW RESET ****
set_property PACKAGE_PIN V30 [get_ports cpu_reset_n]
set_property IOSTANDARD LVCMOS25 [get_ports cpu_reset_n]


#################################
# IIC
#################################
# Allows access to the motherboard as well as FMC I2C devices through a I2C switch 
set_property PACKAGE_PIN R21 [get_ports i2c_scl]
set_property DRIVE 8 [get_ports i2c_scl]
set_property IOSTANDARD LVCMOS25 [get_ports i2c_scl]
set_property SLEW SLOW [get_ports i2c_scl]

set_property PACKAGE_PIN V29 [get_ports i2c_sda]
set_property DRIVE 8 [get_ports i2c_sda]
set_property IOSTANDARD LVCMOS25 [get_ports i2c_sda]
set_property SLEW SLOW [get_ports i2c_sda]

# Unused so far on ICEBoard
# set_property PACKAGE_PIN Y23 [get_ports {UART1_TX_V}]
# set_property PACKAGE_PIN AE20 [get_ports {UART1_TX_V}]
# set_property PACKAGE_PIN Y24 [get_ports {GPIO_RST_V}]
# set_property PACKAGE_PIN T22 [get_ports {SPI_SCK_V}]
# set_property PACKAGE_PIN T30 [get_ports {SPI_D1_V}]
# set_property PACKAGE_PIN R30 [get_ports {SPI_D0_V}]
# set_property PACKAGE_PIN V30 [get_ports {ARM_RST_0_V}]
# set_property PACKAGE_PIN R20 [get_ports {FPGA_CS_V}]
# set_property PACKAGE_PIN W21 [get_ports {ARM_IRQ_V}]
# set_property PACKAGE_PIN E24 [get_ports {CLK_RAW}]
# set_property PACKAGE_PIN AF28 [get_ports {CLK_FPGA_A_C_N}]
# set_property PACKAGE_PIN AE28 [get_ports {CLK_FPGA_A_C_P}]
# set_property PACKAGE_PIN D22 [get_ports {CLK_FPGA_B_C_N}]
# set_property PACKAGE_PIN D21 [get_ports {CLK_FPGA_B_C_N}]
# set_property PACKAGE_PIN V26 [get_ports {FLASH_CS_V}]; # config
# set_property PACKAGE_PIN R18 [get_ports {GPIO_IRQ_V}]
# Unused pins
# set_property PACKAGE_PIN AC19 [get_ports {NC}]
# set_property PACKAGE_PIN L22 [get_ports {NC}]
# set_property PACKAGE_PIN M27 [get_ports {NC}]
# set_property PACKAGE_PIN N27 [get_ports {NC}]
# set_property PACKAGE_PIN P22 [get_ports {NC}]
# set_property PACKAGE_PIN Y19 [get_ports {NC}]
# set_property PACKAGE_PIN Y18 [get_ports {NC}]
# set_property PACKAGE_PIN AB19 [get_ports {NC}]



#################################
# BP IO PINS
#################################

# BP0 on BP_IO5 (AG27, SMA A)
# BP1 on BP_IO4 (W26, SMA B)
# BP2 on BP_IO0_P (AG30)
# BP3 on BP_IO0_N (AH30)
# BP4 on BP_IO1_P (AJ29)
# BP5 on BP_IO1_N (AK30)
# BP6 on BP_IO2_P (AK28)
# BP7 on BP_IO2_N (AK29)
# BP8 on BP_IO3   (W24)


set_property IOSTANDARD LVCMOS25 [get_ports bp_io?]

set_property PACKAGE_PIN AG27 [get_ports bp_io0]
set_property PACKAGE_PIN W26 [get_ports bp_io1]
set_property PACKAGE_PIN AG30 [get_ports bp_io2]
set_property PACKAGE_PIN AH30 [get_ports bp_io3]
set_property PACKAGE_PIN AJ29 [get_ports bp_io4]
set_property PACKAGE_PIN AK30 [get_ports bp_io5]
set_property PACKAGE_PIN AK28 [get_ports bp_io6]
set_property PACKAGE_PIN AK29 [get_ports bp_io7]
set_property PACKAGE_PIN W24 [get_ports bp_io8]


#################################
# Motherboard Buck SYNC lines
#################################

set_property IOSTANDARD LVCMOS25 [get_ports sync_*]

set_property PACKAGE_PIN F28 [get_ports sync_1v0_gtx]
set_property PACKAGE_PIN T26 [get_ports sync_3v3]
set_property PACKAGE_PIN U23 [get_ports sync_12v0]
set_property PACKAGE_PIN F26 [get_ports sync_5v0]
set_property PACKAGE_PIN J24 [get_ports sync_1v0]
set_property PACKAGE_PIN H21 [get_ports sync_vadj]
set_property PACKAGE_PIN A23 [get_ports sync_1v5]
set_property PACKAGE_PIN A22 [get_ports sync_1v8]
set_property PACKAGE_PIN L17 [get_ports sync_1v2]


#################################
# SMA connectors
#################################
# set_property IOSTANDARD LVCMOS25 [get_ports USER_SMA_*]
# set_property PACKAGE_PIN Y23 [get_ports USER_SMA_GPIO_P]
# set_property PACKAGE_PIN Y24 [get_ports USER_SMA_GPIO_N]
# set_property PACKAGE_PIN L25 [get_ports USER_SMA_CLOCK_P]
# set_property PACKAGE_PIN K25 [get_ports USER_SMA_CLOCK_N]


#################################
# SFP+ PINS
#################################
# set_property PACKAGE_PIN P19 [get_ports SFP_LOS]
# set_property IOSTANDARD LVCMOS25 [get_ports SFP_LOS]
# set_property PACKAGE_PIN H2 [get_ports SFP_TX_P]
# set_property PACKAGE_PIN H1 [get_ports SFP_TX_N]
# set_property PACKAGE_PIN G3 [get_ports SFP_RX_P]
# set_property PACKAGE_PIN G4 [get_ports SFP_RX_N]
# # Reference clock for the SFP+: use the lon-board low jitter PLL SI5326 
# # On MGTREFCLK0P_116 and MGTREFCLK0N_116
# set_property PACKAGE_PIN L8 [get_ports SFPCLK_QO_P]

#################################
# SFP Pins
#################################


# 125 MHz  reference clock on CLK_FPGA_B (MGTREFCLK1, Bank 116)
set_property PACKAGE_PIN H6 [get_ports sfp_clk_p]
set_property PACKAGE_PIN H5 [get_ports sfp_clk_n]


# SFP line son the PCI_SFP GTX transceiver( MGT3, Bank 115) 
# set_property LOC GTXE2_CHANNEL_X0Y19 [get_cells dfmux0/UDP_PHY0/sgmiigen.sgmii0/core_wrapper/U0/transceiver_inst/gtwizard_inst/GTWIZARD_i/U0/gt0_GTWIZARD_i/gtxe2_i]
# set_property LOC GTXE2_CHANNEL_X0Y19 [get_cells dfmux0/UDP_PHY0/sgmiigen.sgmii0/core_wrapper/U0/transceiver_inst/gtwizard_inst/gtwizard_i/U0/gt0_GTWIZARD_i/gtxe2_i]
set_property LOC GTXE2_CHANNEL_X0Y19 [get_cells chfpga0/udp_mac0/sgmiigen.sgmii0/core_wrapper/U0/transceiver_inst/gtwizard_inst/gtwizard_i/U0/gt0_GTWIZARD_i/gtxe2_i]
set_property PACKAGE_PIN J3 [get_ports sfp_rx_n]
set_property PACKAGE_PIN J4 [get_ports sfp_rx_p]
set_property PACKAGE_PIN F1 [get_ports sfp_tx_n]
set_property PACKAGE_PIN F2 [get_ports sfp_tx_p]


#################################
# QSFP+ Pins
#################################

# 156.25 MHz  reference clock on CLK_FPGA_A (MGTREFCLK0, Bank 116)
set_property PACKAGE_PIN F6 [get_ports -quiet {xge_refclk_p[0]}]
set_property PACKAGE_PIN F5 [get_ports -quiet {xge_refclk_n[0]}]


### QSFP A
# We use the -quiet flag because the ports are not always present in the design depending on the configuration
set_property -quiet LOC GTXE2_CHANNEL_X0Y20 [get_cells {chfpga0/GPUGEN.xge0/gtx_gen[0].pcs_pma0/U0/gt0_gtwizard_10gbaser_i/gtxe2_i}]
set_property -quiet PACKAGE_PIN D1 [get_ports {xge_tx_n[0]}]
set_property -quiet PACKAGE_PIN G3 [get_ports {xge_rx_n[0]}]
set_property -quiet PACKAGE_PIN G4 [get_ports {xge_rx_p[0]}]
set_property -quiet PACKAGE_PIN D2 [get_ports {xge_tx_p[0]}]

set_property -quiet LOC GTXE2_CHANNEL_X0Y23 [get_cells {chfpga0/GPUGEN.xge0/gtx_gen[1].pcs_pma0/U0/gt0_gtwizard_10gbaser_i/gtxe2_i}]
set_property -quiet PACKAGE_PIN B5 [get_ports {xge_tx_n[3]}]
set_property -quiet PACKAGE_PIN C3 [get_ports {xge_rx_n[3]}]
set_property -quiet PACKAGE_PIN C4 [get_ports {xge_rx_p[3]}]
set_property -quiet PACKAGE_PIN B6 [get_ports {xge_tx_p[3]}]

set_property -quiet LOC GTXE2_CHANNEL_X0Y21 [get_cells {chfpga0/GPUGEN.xge0/gtx_gen[2].pcs_pma0/U0/gt0_gtwizard_10gbaser_i/gtxe2_i}]
set_property -quiet PACKAGE_PIN B1 [get_ports {xge_tx_n[1]}]
set_property -quiet PACKAGE_PIN E3 [get_ports {xge_rx_n[1]}]
set_property -quiet PACKAGE_PIN E4 [get_ports {xge_rx_p[1]}]
set_property -quiet PACKAGE_PIN B2 [get_ports {xge_tx_p[1]}]

set_property -quiet LOC GTXE2_CHANNEL_X0Y22 [get_cells {chfpga0/GPUGEN.xge0/gtx_gen[3].pcs_pma0/U0/gt0_gtwizard_10gbaser_i/gtxe2_i}]
set_property -quiet PACKAGE_PIN A3 [get_ports {xge_tx_n[2]}]
set_property -quiet PACKAGE_PIN D5 [get_ports {xge_rx_n[2]}]
set_property -quiet PACKAGE_PIN D6 [get_ports {xge_rx_p[2]}]
set_property -quiet PACKAGE_PIN A4 [get_ports {xge_tx_p[2]}]

### QSFP B

set_property -quiet PACKAGE_PIN F9  [get_ports {xge_rx_n[4]}]
set_property -quiet PACKAGE_PIN F10 [get_ports {xge_rx_p[4]}]
set_property -quiet PACKAGE_PIN C7  [get_ports {xge_tx_n[4]}]
set_property -quiet PACKAGE_PIN C8  [get_ports {xge_tx_p[4]}]

set_property -quiet PACKAGE_PIN D9  [get_ports {xge_rx_n[5]}]
set_property -quiet PACKAGE_PIN D10 [get_ports {xge_rx_p[5]}]
set_property -quiet PACKAGE_PIN A7  [get_ports {xge_tx_n[5]}]
set_property -quiet PACKAGE_PIN A8  [get_ports {xge_tx_p[5]}]

set_property -quiet PACKAGE_PIN E11 [get_ports {xge_rx_n[6]}]
set_property -quiet PACKAGE_PIN E12 [get_ports {xge_rx_p[6]}]
set_property -quiet PACKAGE_PIN B9  [get_ports {xge_tx_n[6]}]
set_property -quiet PACKAGE_PIN B10 [get_ports {xge_tx_p[6]}]

set_property -quiet PACKAGE_PIN C11 [get_ports {xge_rx_n[7]}]
set_property -quiet PACKAGE_PIN C12 [get_ports {xge_rx_p[7]}]
set_property -quiet PACKAGE_PIN A11 [get_ports {xge_tx_n[7]}]
set_property -quiet PACKAGE_PIN A12 [get_ports {xge_tx_p[7]}]


#################################
# XADC PINS
#################################
#set_property PACKAGE_PIN C39 [get_ports VAUX_CURR_N]
#set_property PACKAGE_PIN C38 [get_ports VAUX_CURR_P]
#set_property PACKAGE_PIN A34 [get_ports VAUX_VOLT_N]
#set_property PACKAGE_PIN B34 [get_ports VAUX_VOLT_P]
#set_property PACKAGE_PIN T14 [get_ports VN]
#set_property PACKAGE_PIN R15 [get_ports VP]
# [Netlist 29-55] Pins VAUXN[6], VAUXN[7], VAUXN[13], VAUXN[14], VAUXN[15], VAUXP[6], VAUXP[7], VAUXP[13], VAUXP[14] or VAUXP[15] are used on XADC instance 'SYSMON0/SYSMON_TIMING_IGNORE'. Please ensure that all of these pins are unconnected in order to avoid an unroutable situation. This instance will be converted to a black box element.
#NET  XADC_VAUX0P_R             LOC = J23  | IOSTANDARD=LVCMOS25; # Bank  15 VCCO - VCC2V5_FPGA - IO_L1P_T0_AD0P_15
#NET  XADC_VAUX0N_R             LOC = J24  | IOSTANDARD=LVCMOS25; # Bank  15 VCCO - VCC2V5_FPGA - IO_L1N_T0_AD0N_15
#NET  XADC_VAUX8P_R             LOC = L22  | IOSTANDARD=LVCMOS25; # Bank  15 VCCO - VCC2V5_FPGA - IO_L2P_T0_AD8P_15
#NET  XADC_VAUX8N_R             LOC = L23  | IOSTANDARD=LVCMOS25; # Bank  15 VCCO - VCC2V5_FPGA - IO_L2N_T0_AD8N_15
#####################################################
# FMC HPC Connections 
#####################################################
#------------------
# FMC Buck regulator sync
#------------------
set_property IOSTANDARD LVCMOS25 [get_ports fmc?_buck*_sync]
## set_property PACKAGE_PIN AD28 [get_ports fmca_buck1v8_sync]
## set_property PACKAGE_PIN AD27 [get_ports fmca_buck3v3_sync]
set_property PACKAGE_PIN AD16 [get_ports fmca_buck1v8_sync]
set_property PACKAGE_PIN AC16 [get_ports fmca_buck3v3_sync]
#------------------
# FMC SPI
#------------------
set_property IOSTANDARD LVCMOS25 [get_ports fmc?_spi_*]

set_property DRIVE 4 [get_ports fmc?_spi_sck]
set_property SLEW SLOW [get_ports fmc?_spi_sck]

set_property PACKAGE_PIN AE30 [get_ports {fmca_spi_addr[0]}]
set_property PACKAGE_PIN AC25 [get_ports {fmca_spi_addr[1]}]
set_property PACKAGE_PIN AB25 [get_ports {fmca_spi_addr[2]}]
set_property PACKAGE_PIN Y29 [get_ports fmca_spi_cs_n]
set_property PACKAGE_PIN AF30 [get_ports fmca_spi_miso]
set_property PACKAGE_PIN AJ27 [get_ports fmca_spi_mosi]
set_property PACKAGE_PIN AB23 [get_ports fmca_spi_rst_n_alt]
set_property PACKAGE_PIN AJ28 [get_ports fmca_spi_sck]


#------------------
# FMC Reference Clock
#------------------
set_property IOSTANDARD LVDS_25 [get_ports fmc?_refclk_m2c_p]
#set_property LOC IDELAY_X0Y28 [get_cells chfpga0/REFCLK0/REFCLKDLY0]
# set_property PACKAGE_PIN AE23 [get_ports fmca_refclk_m2c_p]
# set_property PACKAGE_PIN AF23 [get_ports fmca_refclk_m2c_n]
set_property LOC IDELAY_X0Y28 [get_cells chfpga0/REFCLK0/REFCLKDLY0]
set_property PACKAGE_PIN AH16 [get_ports fmca_refclk_m2c_p]
set_property PACKAGE_PIN AH17 [get_ports fmca_refclk_m2c_n]


#------------------
# FMC ADC RESET
#------------------
set_property IOSTANDARD LVCMOS25 [get_ports fmc?_adc_rst_n]
# set_property PACKAGE_PIN G18 [get_ports ADC_RST_N]
set_property PACKAGE_PIN Y28 [get_ports fmca_adc_rst_n]
#------------------
# FMC ADC SYNC
#------------------
set_property IOSTANDARD LVDS_25 [get_ports fmc?_adc_sync_p]
# set_property PACKAGE_PIN E29 [get_ports ADC_SYNC_P]
# set_property PACKAGE_PIN E30 [get_ports ADC_SYNC_N]
set_property PACKAGE_PIN R23 [get_ports fmca_adc_sync_p]
set_property PACKAGE_PIN T23 [get_ports fmca_adc_sync_n]

#------------------
# FMC ADC Data buses and clocks
#------------------
# Make all ADC inputs LVDS by default
set_property IOSTANDARD LVDS_25 [get_ports {fmca_adc0_ahdp[7]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmca_adc0_ahdp[6]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmca_adc0_ahdp[5]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmca_adc0_ahdp[4]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmca_adc0_ahdp[3]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmca_adc0_ahdp[2]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmca_adc0_ahdp[1]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmca_adc0_bhdp[7]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmca_adc0_bhdp[6]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmca_adc0_bhdp[5]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmca_adc0_bhdp[4]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmca_adc0_bhdp[3]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmca_adc0_bhdp[2]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmca_adc0_bhdp[1]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmca_adc0_bhdp[0]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmca_adc0_chdp[7]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmca_adc0_chdp[6]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmca_adc0_chdp[5]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmca_adc0_chdp[4]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmca_adc0_chdp[3]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmca_adc0_chdp[2]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmca_adc0_chdp[1]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmca_adc0_chdp[0]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmca_adc0_dhdp[7]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmca_adc0_dhdp[6]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmca_adc0_dhdp[5]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmca_adc0_dhdp[4]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmca_adc0_dhdp[3]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmca_adc0_dhdp[2]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmca_adc0_dhdp[1]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmca_adc0_dhdp[0]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmca_adc1_ahdp[7]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmca_adc1_ahdp[6]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmca_adc1_ahdp[5]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmca_adc1_ahdp[4]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmca_adc1_ahdp[3]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmca_adc1_ahdp[2]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmca_adc1_ahdp[1]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmca_adc1_ahdp[0]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmca_adc1_bhdp[7]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmca_adc1_bhdp[6]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmca_adc1_bhdp[5]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmca_adc1_bhdp[4]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmca_adc1_bhdp[3]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmca_adc1_bhdp[2]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmca_adc1_bhdp[1]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmca_adc1_bhdp[0]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmca_adc1_chdp[7]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmca_adc1_chdp[6]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmca_adc1_chdp[5]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmca_adc1_chdp[4]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmca_adc1_chdp[3]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmca_adc1_chdp[2]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmca_adc1_chdp[1]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmca_adc1_chdp[0]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmca_adc1_dhdp[7]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmca_adc1_dhdp[6]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmca_adc1_dhdp[5]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmca_adc1_dhdp[4]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmca_adc1_dhdp[3]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmca_adc1_dhdp[2]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmca_adc1_dhdp[1]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmca_adc1_dhdp[0]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmcb_adc0_ahdp[7]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmcb_adc0_ahdp[6]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmcb_adc0_ahdp[5]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmcb_adc0_ahdp[4]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmcb_adc0_ahdp[3]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmcb_adc0_ahdp[2]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmcb_adc0_ahdp[1]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmcb_adc0_bhdp[7]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmcb_adc0_bhdp[6]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmcb_adc0_bhdp[5]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmcb_adc0_bhdp[4]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmcb_adc0_bhdp[3]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmcb_adc0_bhdp[2]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmcb_adc0_bhdp[1]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmcb_adc0_bhdp[0]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmcb_adc0_chdp[7]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmcb_adc0_chdp[6]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmcb_adc0_chdp[5]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmcb_adc0_chdp[4]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmcb_adc0_chdp[3]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmcb_adc0_chdp[2]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmcb_adc0_chdp[1]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmcb_adc0_chdp[0]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmcb_adc0_dhdp[7]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmcb_adc0_dhdp[6]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmcb_adc0_dhdp[5]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmcb_adc0_dhdp[4]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmcb_adc0_dhdp[3]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmcb_adc0_dhdp[2]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmcb_adc0_dhdp[1]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmcb_adc0_dhdp[0]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmcb_adc1_ahdp[7]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmcb_adc1_ahdp[6]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmcb_adc1_ahdp[5]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmcb_adc1_ahdp[4]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmcb_adc1_ahdp[3]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmcb_adc1_ahdp[2]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmcb_adc1_ahdp[1]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmcb_adc1_ahdp[0]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmcb_adc1_bhdp[7]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmcb_adc1_bhdp[6]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmcb_adc1_bhdp[5]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmcb_adc1_bhdp[4]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmcb_adc1_bhdp[3]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmcb_adc1_bhdp[2]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmcb_adc1_bhdp[1]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmcb_adc1_bhdp[0]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmcb_adc1_chdp[7]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmcb_adc1_chdp[6]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmcb_adc1_chdp[5]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmcb_adc1_chdp[4]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmcb_adc1_chdp[3]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmcb_adc1_chdp[2]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmcb_adc1_chdp[1]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmcb_adc1_chdp[0]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmcb_adc1_dhdp[7]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmcb_adc1_dhdp[6]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmcb_adc1_dhdp[5]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmcb_adc1_dhdp[4]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmcb_adc1_dhdp[3]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmcb_adc1_dhdp[2]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmcb_adc1_dhdp[1]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmcb_adc1_dhdp[0]}]
set_property IOSTANDARD LVDS_25 [get_ports fmca_adc0_adrp]
set_property IOSTANDARD LVDS_25 [get_ports fmca_adc0_cdrp]
set_property IOSTANDARD LVDS_25 [get_ports fmca_adc0_ddrp]
set_property IOSTANDARD LVDS_25 [get_ports fmca_adc1_adrp]
set_property IOSTANDARD LVDS_25 [get_ports fmca_adc1_bdrp]
set_property IOSTANDARD LVDS_25 [get_ports fmca_adc1_cdrp]
set_property IOSTANDARD LVDS_25 [get_ports fmca_adc1_ddrp]
set_property IOSTANDARD LVDS_25 [get_ports fmcb_adc0_adrp]
set_property IOSTANDARD LVDS_25 [get_ports fmcb_adc0_cdrp]
set_property IOSTANDARD LVDS_25 [get_ports fmcb_adc0_ddrp]
set_property IOSTANDARD LVDS_25 [get_ports fmcb_adc1_adrp]
set_property IOSTANDARD LVDS_25 [get_ports fmcb_adc1_bdrp]
set_property IOSTANDARD LVDS_25 [get_ports fmcb_adc1_cdrp]
set_property IOSTANDARD LVDS_25 [get_ports fmcb_adc1_ddrp]
# Reassign the single-ended exceptions
set_property IOSTANDARD LVCMOS25 [get_ports {fmc?_adc0_ahdp[0] fmc?_adc0_bdrp}]
# Remove the IBUF generated for the N side of the single-ended ports

set_property LOC IDELAY_X0Y176 [get_cells {chfpga0/ADCGEN[0].ADCDAQ0/IMPL.CLKDLY0}]
set_property LOC ILOGIC_X0Y176 [get_cells {chfpga0/ADCGEN[0].ADCDAQ0/IMPL.IDDR_CLK}]
set_property LOC BUFMRCE_X0Y6 [get_cells {chfpga0/ADCGEN[0].ADCDAQ0/IMPL.YESBUFMR.BUFMRn}]
set_property PACKAGE_PIN U24 [get_ports fmca_adc0_adrp]
set_property PACKAGE_PIN U25 [get_ports fmca_adc0_adrn]
# set_property PACKAGE_PIN  [get_ports {fmca_adc0_ahdn[0]}]
# NOTE: adc0_ahd is single-ended
set_property PACKAGE_PIN T25 [get_ports {fmca_adc0_ahdp[0]}]
set_property LOC ILOGIC_X0Y166 [get_cells {chfpga0/ADCGEN[0].ADCDAQ0/IMPL.GBIT[1].ISERDESE0}]
set_property LOC IDELAY_X0Y166 [get_cells {chfpga0/ADCGEN[0].ADCDAQ0/IMPL.GBIT[1].DLY0}]
set_property PACKAGE_PIN U20 [get_ports {fmca_adc0_ahdp[1]}]
set_property PACKAGE_PIN V20 [get_ports {fmca_adc0_ahdn[1]}]
set_property LOC ILOGIC_X0Y168 [get_cells {chfpga0/ADCGEN[0].ADCDAQ0/IMPL.GBIT[2].ISERDESE0}]
set_property LOC IDELAY_X0Y168 [get_cells {chfpga0/ADCGEN[0].ADCDAQ0/IMPL.GBIT[2].DLY0}]
set_property PACKAGE_PIN T20 [get_ports {fmca_adc0_ahdp[2]}]
set_property PACKAGE_PIN T21 [get_ports {fmca_adc0_ahdn[2]}]
set_property LOC ILOGIC_X0Y152 [get_cells {chfpga0/ADCGEN[0].ADCDAQ0/IMPL.GBIT[3].ISERDESE0}]
set_property LOC IDELAY_X0Y152 [get_cells {chfpga0/ADCGEN[0].ADCDAQ0/IMPL.GBIT[3].DLY0}]
set_property PACKAGE_PIN W18 [get_ports {fmca_adc0_ahdp[3]}]
set_property PACKAGE_PIN W19 [get_ports {fmca_adc0_ahdn[3]}]
set_property LOC ILOGIC_X0Y160 [get_cells {chfpga0/ADCGEN[0].ADCDAQ0/IMPL.GBIT[4].ISERDESE0}]
set_property LOC IDELAY_X0Y160 [get_cells {chfpga0/ADCGEN[0].ADCDAQ0/IMPL.GBIT[4].DLY0}]
set_property PACKAGE_PIN U19 [get_ports {fmca_adc0_ahdp[4]}]
set_property PACKAGE_PIN V19 [get_ports {fmca_adc0_ahdn[4]}]
set_property LOC ILOGIC_X0Y158 [get_cells {chfpga0/ADCGEN[0].ADCDAQ0/IMPL.GBIT[5].ISERDESE0}]
set_property LOC IDELAY_X0Y158 [get_cells {chfpga0/ADCGEN[0].ADCDAQ0/IMPL.GBIT[5].DLY0}]
set_property PACKAGE_PIN T17 [get_ports {fmca_adc0_ahdp[5]}]
set_property PACKAGE_PIN T18 [get_ports {fmca_adc0_ahdn[5]}]
set_property LOC ILOGIC_X0Y156 [get_cells {chfpga0/ADCGEN[0].ADCDAQ0/IMPL.GBIT[6].ISERDESE0}]
set_property LOC IDELAY_X0Y156 [get_cells {chfpga0/ADCGEN[0].ADCDAQ0/IMPL.GBIT[6].DLY0}]
set_property PACKAGE_PIN U17 [get_ports {fmca_adc0_ahdp[6]}]
set_property PACKAGE_PIN U18 [get_ports {fmca_adc0_ahdn[6]}]
set_property LOC ILOGIC_X0Y190 [get_cells {chfpga0/ADCGEN[0].ADCDAQ0/IMPL.GBIT[7].ISERDESE0}]
set_property LOC IDELAY_X0Y190 [get_cells {chfpga0/ADCGEN[0].ADCDAQ0/IMPL.GBIT[7].DLY0}]
set_property PACKAGE_PIN U27 [get_ports {fmca_adc0_ahdp[7]}]
set_property PACKAGE_PIN U28 [get_ports {fmca_adc0_ahdn[7]}]

# NOTE: adc0_bdr is single-ended
set_property LOC BUFIO_X0Y12 [get_cells {chfpga0/ADCGEN[1].ADCDAQ0/IMPL.NOEXTCLK.BUFIOGEN[0].BUFIO0}]
set_property LOC ILOGIC_X0Y172 [get_cells {chfpga0/ADCGEN[1].ADCDAQ0/IMPL.IDDR_CLK}]
set_property LOC IDELAY_X0Y172 [get_cells {chfpga0/ADCGEN[1].ADCDAQ0/IMPL.CLKDLY0}]
set_property PACKAGE_PIN U22 [get_ports fmca_adc0_bdrp]
set_property LOC ILOGIC_X0Y174 [get_cells {chfpga0/ADCGEN[1].ADCDAQ0/IMPL.GBIT[0].ISERDESE0}]
set_property LOC IDELAY_X0Y174 [get_cells {chfpga0/ADCGEN[1].ADCDAQ0/IMPL.GBIT[0].DLY0}]
set_property PACKAGE_PIN V21 [get_ports {fmca_adc0_bhdp[0]}]
set_property PACKAGE_PIN V22 [get_ports {fmca_adc0_bhdn[0]}]
set_property LOC ILOGIC_X0Y154 [get_cells {chfpga0/ADCGEN[1].ADCDAQ0/IMPL.GBIT[1].ISERDESE0}]
set_property LOC IDELAY_X0Y154 [get_cells {chfpga0/ADCGEN[1].ADCDAQ0/IMPL.GBIT[1].DLY0}]
set_property PACKAGE_PIN V17 [get_ports {fmca_adc0_bhdp[1]}]
set_property PACKAGE_PIN W17 [get_ports {fmca_adc0_bhdn[1]}]
set_property LOC ILOGIC_X0Y180 [get_cells {chfpga0/ADCGEN[1].ADCDAQ0/IMPL.GBIT[2].ISERDESE0}]
set_property LOC IDELAY_X0Y180 [get_cells {chfpga0/ADCGEN[1].ADCDAQ0/IMPL.GBIT[2].DLY0}]
set_property PACKAGE_PIN R26 [get_ports {fmca_adc0_bhdp[2]}]
set_property PACKAGE_PIN T27 [get_ports {fmca_adc0_bhdn[2]}]
set_property LOC ILOGIC_X0Y196 [get_cells {chfpga0/ADCGEN[1].ADCDAQ0/IMPL.GBIT[3].ISERDESE0}]
set_property LOC IDELAY_X0Y196 [get_cells {chfpga0/ADCGEN[1].ADCDAQ0/IMPL.GBIT[3].DLY0}]
set_property PACKAGE_PIN R28 [get_ports {fmca_adc0_bhdp[3]}]
set_property PACKAGE_PIN T28 [get_ports {fmca_adc0_bhdn[3]}]
set_property LOC ILOGIC_X0Y192 [get_cells {chfpga0/ADCGEN[1].ADCDAQ0/IMPL.GBIT[4].ISERDESE0}]
set_property LOC IDELAY_X0Y192 [get_cells {chfpga0/ADCGEN[1].ADCDAQ0/IMPL.GBIT[4].DLY0}]
set_property PACKAGE_PIN U29 [get_ports {fmca_adc0_bhdp[4]}]
set_property PACKAGE_PIN U30 [get_ports {fmca_adc0_bhdn[4]}]
set_property LOC ILOGIC_X0Y186 [get_cells {chfpga0/ADCGEN[1].ADCDAQ0/IMPL.GBIT[5].ISERDESE0}]
set_property LOC IDELAY_X0Y186 [get_cells {chfpga0/ADCGEN[1].ADCDAQ0/IMPL.GBIT[5].DLY0}]
set_property PACKAGE_PIN R24 [get_ports {fmca_adc0_bhdp[5]}]
set_property PACKAGE_PIN R25 [get_ports {fmca_adc0_bhdn[5]}]
set_property LOC ILOGIC_X0Y164 [get_cells {chfpga0/ADCGEN[1].ADCDAQ0/IMPL.GBIT[6].ISERDESE0}]
set_property LOC IDELAY_X0Y164 [get_cells {chfpga0/ADCGEN[1].ADCDAQ0/IMPL.GBIT[6].DLY0}]
set_property PACKAGE_PIN W22 [get_ports {fmca_adc0_bhdp[6]}]
set_property PACKAGE_PIN W23 [get_ports {fmca_adc0_bhdn[6]}]
set_property LOC ILOGIC_X0Y182 [get_cells {chfpga0/ADCGEN[1].ADCDAQ0/IMPL.GBIT[7].ISERDESE0}]
set_property LOC IDELAY_X0Y182 [get_cells {chfpga0/ADCGEN[1].ADCDAQ0/IMPL.GBIT[7].DLY0}]
set_property PACKAGE_PIN V24 [get_ports {fmca_adc0_bhdp[7]}]
set_property PACKAGE_PIN V25 [get_ports {fmca_adc0_bhdn[7]}]
set_property LOC IDELAY_X0Y124 [get_cells {chfpga0/ADCGEN[2].ADCDAQ0/IMPL.CLKDLY0}]
set_property LOC ILOGIC_X0Y124 [get_cells {chfpga0/ADCGEN[2].ADCDAQ0/IMPL.IDDR_CLK}]
set_property LOC BUFMRCE_X0Y5 [get_cells {chfpga0/ADCGEN[2].ADCDAQ0/IMPL.YESBUFMR.BUFMRn}]
set_property PACKAGE_PIN AC27 [get_ports fmca_adc0_cdrp]
set_property PACKAGE_PIN AD28 [get_ports fmca_adc0_cdrn]
set_property LOC ILOGIC_X0Y68 [get_cells {chfpga0/ADCGEN[2].ADCDAQ0/IMPL.GBIT[0].ISERDESE0}]
set_property LOC IDELAY_X0Y68 [get_cells {chfpga0/ADCGEN[2].ADCDAQ0/IMPL.GBIT[0].DLY0}]
set_property PACKAGE_PIN AD21 [get_ports {fmca_adc0_chdp[0]}]
set_property PACKAGE_PIN AD22 [get_ports {fmca_adc0_chdn[0]}]
set_property LOC ILOGIC_X0Y52 [get_cells {chfpga0/ADCGEN[2].ADCDAQ0/IMPL.GBIT[1].ISERDESE0}]
set_property LOC IDELAY_X0Y52 [get_cells {chfpga0/ADCGEN[2].ADCDAQ0/IMPL.GBIT[1].DLY0}]
set_property PACKAGE_PIN AJ26 [get_ports {fmca_adc0_chdp[1]}]
set_property PACKAGE_PIN AK26 [get_ports {fmca_adc0_chdn[1]}]
set_property LOC ILOGIC_X0Y110 [get_cells {chfpga0/ADCGEN[2].ADCDAQ0/IMPL.GBIT[2].ISERDESE0}]
set_property LOC IDELAY_X0Y110 [get_cells {chfpga0/ADCGEN[2].ADCDAQ0/IMPL.GBIT[2].DLY0}]
set_property PACKAGE_PIN AG29 [get_ports {fmca_adc0_chdp[2]}]
set_property PACKAGE_PIN AH29 [get_ports {fmca_adc0_chdn[2]}]
set_property LOC ILOGIC_X0Y136 [get_cells {chfpga0/ADCGEN[2].ADCDAQ0/IMPL.GBIT[3].ISERDESE0}]
set_property LOC IDELAY_X0Y136 [get_cells {chfpga0/ADCGEN[2].ADCDAQ0/IMPL.GBIT[3].DLY0}]
set_property PACKAGE_PIN AC26 [get_ports {fmca_adc0_chdp[3]}]
set_property PACKAGE_PIN AD27 [get_ports {fmca_adc0_chdn[3]}]
set_property LOC ILOGIC_X0Y134 [get_cells {chfpga0/ADCGEN[2].ADCDAQ0/IMPL.GBIT[4].ISERDESE0}]
set_property LOC IDELAY_X0Y134 [get_cells {chfpga0/ADCGEN[2].ADCDAQ0/IMPL.GBIT[4].DLY0}]
set_property PACKAGE_PIN Y25 [get_ports {fmca_adc0_chdp[4]}]
set_property PACKAGE_PIN AA25 [get_ports {fmca_adc0_chdn[4]}]
set_property LOC ILOGIC_X0Y114 [get_cells {chfpga0/ADCGEN[2].ADCDAQ0/IMPL.GBIT[5].ISERDESE0}]
set_property LOC IDELAY_X0Y114 [get_cells {chfpga0/ADCGEN[2].ADCDAQ0/IMPL.GBIT[5].DLY0}]
set_property PACKAGE_PIN AF27 [get_ports {fmca_adc0_chdp[5]}]
set_property PACKAGE_PIN AG28 [get_ports {fmca_adc0_chdn[5]}]
set_property LOC ILOGIC_X0Y130 [get_cells {chfpga0/ADCGEN[2].ADCDAQ0/IMPL.GBIT[6].ISERDESE0}]
set_property LOC IDELAY_X0Y130 [get_cells {chfpga0/ADCGEN[2].ADCDAQ0/IMPL.GBIT[6].DLY0}]
set_property PACKAGE_PIN AB24 [get_ports {fmca_adc0_chdp[6]}]
set_property PACKAGE_PIN AC24 [get_ports {fmca_adc0_chdn[6]}]
set_property LOC ILOGIC_X0Y120 [get_cells {chfpga0/ADCGEN[2].ADCDAQ0/IMPL.GBIT[7].ISERDESE0}]
set_property LOC IDELAY_X0Y120 [get_cells {chfpga0/ADCGEN[2].ADCDAQ0/IMPL.GBIT[7].DLY0}]
set_property PACKAGE_PIN AC29 [get_ports {fmca_adc0_chdp[7]}]
set_property PACKAGE_PIN AC30 [get_ports {fmca_adc0_chdn[7]}]
set_property LOC IDELAY_X0Y126 [get_cells {chfpga0/ADCGEN[3].ADCDAQ0/IMPL.CLKDLY0}]
set_property LOC ILOGIC_X0Y126 [get_cells {chfpga0/ADCGEN[3].ADCDAQ0/IMPL.IDDR_CLK}]
set_property LOC BUFMRCE_X0Y4 [get_cells {chfpga0/ADCGEN[3].ADCDAQ0/IMPL.YESBUFMR.BUFMRn}]
set_property PACKAGE_PIN AA27 [get_ports fmca_adc0_ddrp]
set_property PACKAGE_PIN AB27 [get_ports fmca_adc0_ddrn]
set_property LOC ILOGIC_X0Y58 [get_cells {chfpga0/ADCGEN[3].ADCDAQ0/IMPL.GBIT[0].ISERDESE0}]
set_property LOC IDELAY_X0Y58 [get_cells {chfpga0/ADCGEN[3].ADCDAQ0/IMPL.GBIT[0].DLY0}]
set_property PACKAGE_PIN AJ22 [get_ports {fmca_adc0_dhdp[0]}]
set_property PACKAGE_PIN AK23 [get_ports {fmca_adc0_dhdn[0]}]
set_property LOC ILOGIC_X0Y54 [get_cells {chfpga0/ADCGEN[3].ADCDAQ0/IMPL.GBIT[1].ISERDESE0}]
set_property LOC IDELAY_X0Y54 [get_cells {chfpga0/ADCGEN[3].ADCDAQ0/IMPL.GBIT[1].DLY0}]
set_property PACKAGE_PIN AK24 [get_ports {fmca_adc0_dhdp[1]}]
set_property PACKAGE_PIN AK25 [get_ports {fmca_adc0_dhdn[1]}]
set_property LOC ILOGIC_X0Y66 [get_cells {chfpga0/ADCGEN[3].ADCDAQ0/IMPL.GBIT[2].ISERDESE0}]
set_property LOC IDELAY_X0Y66 [get_cells {chfpga0/ADCGEN[3].ADCDAQ0/IMPL.GBIT[2].DLY0}]
set_property PACKAGE_PIN AE21 [get_ports {fmca_adc0_dhdp[2]}]
set_property PACKAGE_PIN AF21 [get_ports {fmca_adc0_dhdn[2]}]
set_property LOC ILOGIC_X0Y118 [get_cells {chfpga0/ADCGEN[3].ADCDAQ0/IMPL.GBIT[3].ISERDESE0}]
set_property LOC IDELAY_X0Y118 [get_cells {chfpga0/ADCGEN[3].ADCDAQ0/IMPL.GBIT[3].DLY0}]
set_property PACKAGE_PIN AD29 [get_ports {fmca_adc0_dhdp[3]}]
set_property PACKAGE_PIN AE29 [get_ports {fmca_adc0_dhdn[3]}]
set_property LOC ILOGIC_X0Y146 [get_cells {chfpga0/ADCGEN[3].ADCDAQ0/IMPL.GBIT[4].ISERDESE0}]
set_property LOC IDELAY_X0Y146 [get_cells {chfpga0/ADCGEN[3].ADCDAQ0/IMPL.GBIT[4].DLY0}]
set_property PACKAGE_PIN AB29 [get_ports {fmca_adc0_dhdp[4]}]
set_property PACKAGE_PIN AB30 [get_ports {fmca_adc0_dhdn[4]}]
set_property LOC ILOGIC_X0Y144 [get_cells {chfpga0/ADCGEN[3].ADCDAQ0/IMPL.GBIT[5].ISERDESE0}]
set_property LOC IDELAY_X0Y144 [get_cells {chfpga0/ADCGEN[3].ADCDAQ0/IMPL.GBIT[5].DLY0}]
set_property PACKAGE_PIN Y30 [get_ports {fmca_adc0_dhdp[5]}]
set_property PACKAGE_PIN AA30 [get_ports {fmca_adc0_dhdn[5]}]
set_property LOC ILOGIC_X0Y148 [get_cells {chfpga0/ADCGEN[3].ADCDAQ0/IMPL.GBIT[6].ISERDESE0}]
set_property LOC IDELAY_X0Y148 [get_cells {chfpga0/ADCGEN[3].ADCDAQ0/IMPL.GBIT[6].DLY0}]
set_property PACKAGE_PIN AA28 [get_ports {fmca_adc0_dhdp[6]}]
set_property PACKAGE_PIN AB28 [get_ports {fmca_adc0_dhdn[6]}]
set_property LOC ILOGIC_X0Y140 [get_cells {chfpga0/ADCGEN[3].ADCDAQ0/IMPL.GBIT[7].ISERDESE0}]
set_property LOC IDELAY_X0Y140 [get_cells {chfpga0/ADCGEN[3].ADCDAQ0/IMPL.GBIT[7].DLY0}]
set_property PACKAGE_PIN W28 [get_ports {fmca_adc0_dhdp[7]}]
set_property PACKAGE_PIN W29 [get_ports {fmca_adc0_dhdn[7]}]
set_property LOC IDELAY_X0Y26 [get_cells {chfpga0/ADCGEN[4].ADCDAQ0/IMPL.CLKDLY0}]
set_property LOC ILOGIC_X0Y26 [get_cells {chfpga0/ADCGEN[4].ADCDAQ0/IMPL.IDDR_CLK}]
set_property LOC BUFMRCE_X0Y0 [get_cells {chfpga0/ADCGEN[4].ADCDAQ0/IMPL.YESBUFMR.BUFMRn}]
set_property PACKAGE_PIN AF17 [get_ports fmca_adc1_adrp]
set_property PACKAGE_PIN AG17 [get_ports fmca_adc1_adrn]
set_property LOC ILOGIC_X0Y12 [get_cells {chfpga0/ADCGEN[4].ADCDAQ0/IMPL.GBIT[0].ISERDESE0}]
set_property LOC IDELAY_X0Y12 [get_cells {chfpga0/ADCGEN[4].ADCDAQ0/IMPL.GBIT[0].DLY0}]
set_property PACKAGE_PIN AE18 [get_ports {fmca_adc1_ahdp[0]}]
set_property PACKAGE_PIN AE19 [get_ports {fmca_adc1_ahdn[0]}]
set_property LOC ILOGIC_X0Y30 [get_cells {chfpga0/ADCGEN[4].ADCDAQ0/IMPL.GBIT[1].ISERDESE0}]
set_property LOC IDELAY_X0Y30 [get_cells {chfpga0/ADCGEN[4].ADCDAQ0/IMPL.GBIT[1].DLY0}]
set_property PACKAGE_PIN AJ14 [get_ports {fmca_adc1_ahdp[1]}]
set_property PACKAGE_PIN AK14 [get_ports {fmca_adc1_ahdn[1]}]
set_property LOC ILOGIC_X0Y36 [get_cells {chfpga0/ADCGEN[4].ADCDAQ0/IMPL.GBIT[2].ISERDESE0}]
set_property LOC IDELAY_X0Y36 [get_cells {chfpga0/ADCGEN[4].ADCDAQ0/IMPL.GBIT[2].DLY0}]
set_property PACKAGE_PIN AK15 [get_ports {fmca_adc1_ahdp[2]}]
set_property PACKAGE_PIN AK16 [get_ports {fmca_adc1_ahdn[2]}]
set_property LOC ILOGIC_X0Y38 [get_cells {chfpga0/ADCGEN[4].ADCDAQ0/IMPL.GBIT[3].ISERDESE0}]
set_property LOC IDELAY_X0Y38 [get_cells {chfpga0/ADCGEN[4].ADCDAQ0/IMPL.GBIT[3].DLY0}]
set_property PACKAGE_PIN AF18 [get_ports {fmca_adc1_ahdp[3]}]
set_property PACKAGE_PIN AG18 [get_ports {fmca_adc1_ahdn[3]}]
set_property LOC ILOGIC_X0Y46 [get_cells {chfpga0/ADCGEN[4].ADCDAQ0/IMPL.GBIT[4].ISERDESE0}]
set_property LOC IDELAY_X0Y46 [get_cells {chfpga0/ADCGEN[4].ADCDAQ0/IMPL.GBIT[4].DLY0}]
set_property PACKAGE_PIN AH19 [get_ports {fmca_adc1_ahdp[4]}]
set_property PACKAGE_PIN AJ19 [get_ports {fmca_adc1_ahdn[4]}]
set_property LOC ILOGIC_X0Y6 [get_cells {chfpga0/ADCGEN[4].ADCDAQ0/IMPL.GBIT[5].ISERDESE0}]
set_property LOC IDELAY_X0Y6 [get_cells {chfpga0/ADCGEN[4].ADCDAQ0/IMPL.GBIT[5].DLY0}]
set_property PACKAGE_PIN AB17 [get_ports {fmca_adc1_ahdp[5]}]
set_property PACKAGE_PIN AB18 [get_ports {fmca_adc1_ahdn[5]}]
set_property LOC ILOGIC_X0Y14 [get_cells {chfpga0/ADCGEN[4].ADCDAQ0/IMPL.GBIT[6].ISERDESE0}]
set_property LOC IDELAY_X0Y14 [get_cells {chfpga0/ADCGEN[4].ADCDAQ0/IMPL.GBIT[6].DLY0}]
set_property PACKAGE_PIN AD14 [get_ports {fmca_adc1_ahdp[6]}]
set_property PACKAGE_PIN AE14 [get_ports {fmca_adc1_ahdn[6]}]
set_property LOC ILOGIC_X0Y4 [get_cells {chfpga0/ADCGEN[4].ADCDAQ0/IMPL.GBIT[7].ISERDESE0}]
set_property LOC IDELAY_X0Y4 [get_cells {chfpga0/ADCGEN[4].ADCDAQ0/IMPL.GBIT[7].DLY0}]
set_property PACKAGE_PIN AA17 [get_ports {fmca_adc1_ahdp[7]}]
set_property PACKAGE_PIN AA18 [get_ports {fmca_adc1_ahdn[7]}]
set_property LOC IDELAY_X0Y24 [get_cells {chfpga0/ADCGEN[5].ADCDAQ0/IMPL.CLKDLY0}]
set_property LOC ILOGIC_X0Y24 [get_cells {chfpga0/ADCGEN[5].ADCDAQ0/IMPL.IDDR_CLK}]
set_property LOC BUFMRCE_X0Y1 [get_cells {chfpga0/ADCGEN[5].ADCDAQ0/IMPL.YESBUFMR.BUFMRn}]
set_property PACKAGE_PIN AF15 [get_ports fmca_adc1_bdrp]
set_property PACKAGE_PIN AF16 [get_ports fmca_adc1_bdrn]
set_property LOC ILOGIC_X0Y10 [get_cells {chfpga0/ADCGEN[5].ADCDAQ0/IMPL.GBIT[0].ISERDESE0}]
set_property LOC IDELAY_X0Y10 [get_cells {chfpga0/ADCGEN[5].ADCDAQ0/IMPL.GBIT[0].DLY0}]
set_property PACKAGE_PIN AD18 [get_ports {fmca_adc1_bhdp[0]}]
set_property PACKAGE_PIN AD19 [get_ports {fmca_adc1_bhdn[0]}]
set_property LOC ILOGIC_X0Y48 [get_cells {chfpga0/ADCGEN[5].ADCDAQ0/IMPL.GBIT[1].ISERDESE0}]
set_property LOC IDELAY_X0Y48 [get_cells {chfpga0/ADCGEN[5].ADCDAQ0/IMPL.GBIT[1].DLY0}]
set_property PACKAGE_PIN AG19 [get_ports {fmca_adc1_bhdp[1]}]
set_property PACKAGE_PIN AH20 [get_ports {fmca_adc1_bhdn[1]}]
set_property LOC ILOGIC_X0Y44 [get_cells {chfpga0/ADCGEN[5].ADCDAQ0/IMPL.GBIT[2].ISERDESE0}]
set_property LOC IDELAY_X0Y44 [get_cells {chfpga0/ADCGEN[5].ADCDAQ0/IMPL.GBIT[2].DLY0}]
set_property PACKAGE_PIN AK19 [get_ports {fmca_adc1_bhdp[2]}]
set_property PACKAGE_PIN AK20 [get_ports {fmca_adc1_bhdn[2]}]
set_property LOC ILOGIC_X0Y42 [get_cells {chfpga0/ADCGEN[5].ADCDAQ0/IMPL.GBIT[3].ISERDESE0}]
set_property LOC IDELAY_X0Y42 [get_cells {chfpga0/ADCGEN[5].ADCDAQ0/IMPL.GBIT[3].DLY0}]
set_property PACKAGE_PIN AJ18 [get_ports {fmca_adc1_bhdp[3]}]
set_property PACKAGE_PIN AK18 [get_ports {fmca_adc1_bhdn[3]}]
set_property LOC ILOGIC_X0Y32 [get_cells {chfpga0/ADCGEN[5].ADCDAQ0/IMPL.GBIT[4].ISERDESE0}]
set_property LOC IDELAY_X0Y32 [get_cells {chfpga0/ADCGEN[5].ADCDAQ0/IMPL.GBIT[4].DLY0}]
set_property PACKAGE_PIN AG14 [get_ports {fmca_adc1_bhdp[4]}]
set_property PACKAGE_PIN AG15 [get_ports {fmca_adc1_bhdn[4]}]
set_property LOC ILOGIC_X0Y8 [get_cells {chfpga0/ADCGEN[5].ADCDAQ0/IMPL.GBIT[5].ISERDESE0}]
set_property LOC IDELAY_X0Y8 [get_cells {chfpga0/ADCGEN[5].ADCDAQ0/IMPL.GBIT[5].DLY0}]
set_property PACKAGE_PIN AC17 [get_ports {fmca_adc1_bhdp[5]}]
set_property PACKAGE_PIN AD17 [get_ports {fmca_adc1_bhdn[5]}]
set_property LOC ILOGIC_X0Y34 [get_cells {chfpga0/ADCGEN[5].ADCDAQ0/IMPL.GBIT[6].ISERDESE0}]
set_property LOC IDELAY_X0Y34 [get_cells {chfpga0/ADCGEN[5].ADCDAQ0/IMPL.GBIT[6].DLY0}]
set_property PACKAGE_PIN AH14 [get_ports {fmca_adc1_bhdp[6]}]
set_property PACKAGE_PIN AH15 [get_ports {fmca_adc1_bhdn[6]}]
set_property LOC ILOGIC_X0Y40 [get_cells {chfpga0/ADCGEN[5].ADCDAQ0/IMPL.GBIT[7].ISERDESE0}]
set_property LOC IDELAY_X0Y40 [get_cells {chfpga0/ADCGEN[5].ADCDAQ0/IMPL.GBIT[7].DLY0}]
set_property PACKAGE_PIN AJ16 [get_ports {fmca_adc1_bhdp[7]}]
set_property PACKAGE_PIN AJ17 [get_ports {fmca_adc1_bhdn[7]}]
set_property LOC IDELAY_X0Y76 [get_cells {chfpga0/ADCGEN[6].ADCDAQ0/IMPL.CLKDLY0}]
set_property LOC ILOGIC_X0Y76 [get_cells {chfpga0/ADCGEN[6].ADCDAQ0/IMPL.IDDR_CLK}]
set_property LOC BUFMRCE_X0Y2 [get_cells {chfpga0/ADCGEN[6].ADCDAQ0/IMPL.YESBUFMR.BUFMRn}]
set_property PACKAGE_PIN AG24 [get_ports fmca_adc1_cdrp]
set_property PACKAGE_PIN AH24 [get_ports fmca_adc1_cdrn]
set_property LOC ILOGIC_X0Y74 [get_cells {chfpga0/ADCGEN[6].ADCDAQ0/IMPL.GBIT[0].ISERDESE0}]
set_property LOC IDELAY_X0Y74 [get_cells {chfpga0/ADCGEN[6].ADCDAQ0/IMPL.GBIT[0].DLY0}]
set_property PACKAGE_PIN AG22 [get_ports {fmca_adc1_chdp[0]}]
set_property PACKAGE_PIN AG23 [get_ports {fmca_adc1_chdn[0]}]
set_property LOC ILOGIC_X0Y72 [get_cells {chfpga0/ADCGEN[6].ADCDAQ0/IMPL.GBIT[1].ISERDESE0}]
set_property LOC IDELAY_X0Y72 [get_cells {chfpga0/ADCGEN[6].ADCDAQ0/IMPL.GBIT[1].DLY0}]
set_property PACKAGE_PIN AF22 [get_ports {fmca_adc1_chdp[1]}]
set_property PACKAGE_PIN AF23 [get_ports {fmca_adc1_chdn[1]}]
set_property LOC ILOGIC_X0Y70 [get_cells {chfpga0/ADCGEN[6].ADCDAQ0/IMPL.GBIT[2].ISERDESE0}]
set_property LOC IDELAY_X0Y70 [get_cells {chfpga0/ADCGEN[6].ADCDAQ0/IMPL.GBIT[2].DLY0}]
set_property PACKAGE_PIN AD23 [get_ports {fmca_adc1_chdp[2]}]
set_property PACKAGE_PIN AE23 [get_ports {fmca_adc1_chdn[2]}]
set_property LOC ILOGIC_X0Y94 [get_cells {chfpga0/ADCGEN[6].ADCDAQ0/IMPL.GBIT[3].ISERDESE0}]
set_property LOC IDELAY_X0Y94 [get_cells {chfpga0/ADCGEN[6].ADCDAQ0/IMPL.GBIT[3].DLY0}]
set_property PACKAGE_PIN AA22 [get_ports {fmca_adc1_chdp[3]}]
set_property PACKAGE_PIN AA23 [get_ports {fmca_adc1_chdn[3]}]
set_property LOC ILOGIC_X0Y64 [get_cells {chfpga0/ADCGEN[6].ADCDAQ0/IMPL.GBIT[4].ISERDESE0}]
set_property LOC IDELAY_X0Y64 [get_cells {chfpga0/ADCGEN[6].ADCDAQ0/IMPL.GBIT[4].DLY0}]
set_property PACKAGE_PIN AF20 [get_ports {fmca_adc1_chdp[4]}]
set_property PACKAGE_PIN AG20 [get_ports {fmca_adc1_chdn[4]}]
set_property LOC ILOGIC_X0Y98 [get_cells {chfpga0/ADCGEN[6].ADCDAQ0/IMPL.GBIT[5].ISERDESE0}]
set_property LOC IDELAY_X0Y98 [get_cells {chfpga0/ADCGEN[6].ADCDAQ0/IMPL.GBIT[5].DLY0}]
set_property PACKAGE_PIN Y20 [get_ports {fmca_adc1_chdp[5]}]
set_property PACKAGE_PIN Y21 [get_ports {fmca_adc1_chdn[5]}]
set_property LOC ILOGIC_X0Y96 [get_cells {chfpga0/ADCGEN[6].ADCDAQ0/IMPL.GBIT[6].ISERDESE0}]
set_property LOC IDELAY_X0Y96 [get_cells {chfpga0/ADCGEN[6].ADCDAQ0/IMPL.GBIT[6].DLY0}]
set_property PACKAGE_PIN AA20 [get_ports {fmca_adc1_chdp[6]}]
set_property PACKAGE_PIN AA21 [get_ports {fmca_adc1_chdn[6]}]
set_property LOC ILOGIC_X0Y80 [get_cells {chfpga0/ADCGEN[6].ADCDAQ0/IMPL.GBIT[7].ISERDESE0}]
set_property LOC IDELAY_X0Y80 [get_cells {chfpga0/ADCGEN[6].ADCDAQ0/IMPL.GBIT[7].DLY0}]
set_property PACKAGE_PIN AD24 [get_ports {fmca_adc1_chdp[7]}]
set_property PACKAGE_PIN AE24 [get_ports {fmca_adc1_chdn[7]}]
set_property LOC BUFIO_X0Y7 [get_cells {chfpga0/ADCGEN[7].ADCDAQ0/IMPL.NOEXTCLK.BUFIOGEN[0].BUFIO0}]
set_property LOC ILOGIC_X0Y78 [get_cells {chfpga0/ADCGEN[7].ADCDAQ0/IMPL.IDDR_CLK}]
set_property LOC IDELAY_X0Y78 [get_cells {chfpga0/ADCGEN[7].ADCDAQ0/IMPL.CLKDLY0}]
set_property PACKAGE_PIN AF25 [get_ports fmca_adc1_ddrp]
set_property PACKAGE_PIN AG25 [get_ports fmca_adc1_ddrn]
set_property LOC ILOGIC_X0Y62 [get_cells {chfpga0/ADCGEN[7].ADCDAQ0/IMPL.GBIT[0].ISERDESE0}]
set_property LOC IDELAY_X0Y62 [get_cells {chfpga0/ADCGEN[7].ADCDAQ0/IMPL.GBIT[0].DLY0}]
set_property PACKAGE_PIN AH21 [get_ports {fmca_adc1_dhdp[0]}]
set_property PACKAGE_PIN AH22 [get_ports {fmca_adc1_dhdn[0]}]
set_property LOC ILOGIC_X0Y56 [get_cells {chfpga0/ADCGEN[7].ADCDAQ0/IMPL.GBIT[1].ISERDESE0}]
set_property LOC IDELAY_X0Y56 [get_cells {chfpga0/ADCGEN[7].ADCDAQ0/IMPL.GBIT[1].DLY0}]
set_property PACKAGE_PIN AJ23 [get_ports {fmca_adc1_dhdp[1]}]
set_property PACKAGE_PIN AJ24 [get_ports {fmca_adc1_dhdn[1]}]
set_property LOC ILOGIC_X0Y60 [get_cells {chfpga0/ADCGEN[7].ADCDAQ0/IMPL.GBIT[2].ISERDESE0}]
set_property LOC IDELAY_X0Y60 [get_cells {chfpga0/ADCGEN[7].ADCDAQ0/IMPL.GBIT[2].DLY0}]
set_property PACKAGE_PIN AJ21 [get_ports {fmca_adc1_dhdp[2]}]
set_property PACKAGE_PIN AK21 [get_ports {fmca_adc1_dhdn[2]}]
set_property LOC ILOGIC_X0Y84 [get_cells {chfpga0/ADCGEN[7].ADCDAQ0/IMPL.GBIT[3].ISERDESE0}]
set_property LOC IDELAY_X0Y84 [get_cells {chfpga0/ADCGEN[7].ADCDAQ0/IMPL.GBIT[3].DLY0}]
set_property PACKAGE_PIN AH25 [get_ports {fmca_adc1_dhdp[3]}]
set_property PACKAGE_PIN AH26 [get_ports {fmca_adc1_dhdn[3]}]
set_property LOC ILOGIC_X0Y92 [get_cells {chfpga0/ADCGEN[7].ADCDAQ0/IMPL.GBIT[4].ISERDESE0}]
set_property LOC IDELAY_X0Y92 [get_cells {chfpga0/ADCGEN[7].ADCDAQ0/IMPL.GBIT[4].DLY0}]
set_property PACKAGE_PIN AB20 [get_ports {fmca_adc1_dhdp[4]}]
set_property PACKAGE_PIN AC20 [get_ports {fmca_adc1_dhdn[4]}]
set_property LOC ILOGIC_X0Y86 [get_cells {chfpga0/ADCGEN[7].ADCDAQ0/IMPL.GBIT[5].ISERDESE0}]
set_property LOC IDELAY_X0Y86 [get_cells {chfpga0/ADCGEN[7].ADCDAQ0/IMPL.GBIT[5].DLY0}]
set_property PACKAGE_PIN AD26 [get_ports {fmca_adc1_dhdp[5]}]
set_property PACKAGE_PIN AE26 [get_ports {fmca_adc1_dhdn[5]}]
set_property LOC ILOGIC_X0Y82 [get_cells {chfpga0/ADCGEN[7].ADCDAQ0/IMPL.GBIT[6].ISERDESE0}]
set_property LOC IDELAY_X0Y82 [get_cells {chfpga0/ADCGEN[7].ADCDAQ0/IMPL.GBIT[6].DLY0}]
set_property PACKAGE_PIN AE25 [get_ports {fmca_adc1_dhdp[6]}]
set_property PACKAGE_PIN AF26 [get_ports {fmca_adc1_dhdn[6]}]
set_property LOC ILOGIC_X0Y88 [get_cells {chfpga0/ADCGEN[7].ADCDAQ0/IMPL.GBIT[7].ISERDESE0}]
set_property LOC IDELAY_X0Y88 [get_cells {chfpga0/ADCGEN[7].ADCDAQ0/IMPL.GBIT[7].DLY0}]
set_property PACKAGE_PIN AC21 [get_ports {fmca_adc1_dhdp[7]}]
set_property PACKAGE_PIN AC22 [get_ports {fmca_adc1_dhdn[7]}]



#######################################################
#  ######    #      #     #####      ######
#  #         ##    ##    #     #     #     ##
#  ###       # #  # #   #            ######
#  #         #  ##  #    #     #     #     ##
#  #         #      #     #####      ######
#######################################################

set_property PACKAGE_PIN G18 [get_ports fmcb_adc_rst_n]
set_property PACKAGE_PIN H25 [get_ports fmcb_adc_sync_p]
set_property PACKAGE_PIN G25 [get_ports fmcb_adc_sync_n]
set_property LOC IDELAY_X0Y276 [get_cells {chfpga0/ADCGEN[8].ADCDAQ0/IMPL.CLKDLY0}]
set_property LOC ILOGIC_X0Y276 [get_cells {chfpga0/ADCGEN[8].ADCDAQ0/IMPL.IDDR_CLK}]
set_property LOC BUFMRCE_X0Y10 [get_cells {chfpga0/ADCGEN[8].ADCDAQ0/IMPL.YESBUFMR.BUFMRn}]
set_property PACKAGE_PIN E25 [get_ports fmcb_adc0_adrp]
set_property PACKAGE_PIN E26 [get_ports fmcb_adc0_adrn]
set_property PACKAGE_PIN F25 [get_ports {fmcb_adc0_ahdp[0]}]
set_property LOC ILOGIC_X0Y288 [get_cells {chfpga0/ADCGEN[8].ADCDAQ0/IMPL.GBIT[1].ISERDESE0}]
set_property LOC IDELAY_X0Y288 [get_cells {chfpga0/ADCGEN[8].ADCDAQ0/IMPL.GBIT[1].DLY0}]
set_property PACKAGE_PIN D26 [get_ports {fmcb_adc0_ahdp[1]}]
set_property PACKAGE_PIN D27 [get_ports {fmcb_adc0_ahdn[1]}]
set_property LOC ILOGIC_X0Y286 [get_cells {chfpga0/ADCGEN[8].ADCDAQ0/IMPL.GBIT[2].ISERDESE0}]
set_property LOC IDELAY_X0Y286 [get_cells {chfpga0/ADCGEN[8].ADCDAQ0/IMPL.GBIT[2].DLY0}]
set_property PACKAGE_PIN H24 [get_ports {fmcb_adc0_ahdp[2]}]
set_property PACKAGE_PIN G24 [get_ports {fmcb_adc0_ahdn[2]}]
set_property LOC ILOGIC_X0Y290 [get_cells {chfpga0/ADCGEN[8].ADCDAQ0/IMPL.GBIT[3].ISERDESE0}]
set_property LOC IDELAY_X0Y290 [get_cells {chfpga0/ADCGEN[8].ADCDAQ0/IMPL.GBIT[3].DLY0}]
set_property PACKAGE_PIN C27 [get_ports {fmcb_adc0_ahdp[3]}]
set_property PACKAGE_PIN B27 [get_ports {fmcb_adc0_ahdn[3]}]
set_property LOC ILOGIC_X0Y282 [get_cells {chfpga0/ADCGEN[8].ADCDAQ0/IMPL.GBIT[4].ISERDESE0}]
set_property LOC IDELAY_X0Y282 [get_cells {chfpga0/ADCGEN[8].ADCDAQ0/IMPL.GBIT[4].DLY0}]
set_property PACKAGE_PIN J26 [get_ports {fmcb_adc0_ahdp[4]}]
set_property PACKAGE_PIN J27 [get_ports {fmcb_adc0_ahdn[4]}]
set_property LOC ILOGIC_X0Y268 [get_cells {chfpga0/ADCGEN[8].ADCDAQ0/IMPL.GBIT[5].ISERDESE0}]
set_property LOC IDELAY_X0Y268 [get_cells {chfpga0/ADCGEN[8].ADCDAQ0/IMPL.GBIT[5].DLY0}]
set_property PACKAGE_PIN F30 [get_ports {fmcb_adc0_ahdp[5]}]
set_property PACKAGE_PIN E30 [get_ports {fmcb_adc0_ahdn[5]}]
set_property LOC ILOGIC_X0Y296 [get_cells {chfpga0/ADCGEN[8].ADCDAQ0/IMPL.GBIT[6].ISERDESE0}]
set_property LOC IDELAY_X0Y296 [get_cells {chfpga0/ADCGEN[8].ADCDAQ0/IMPL.GBIT[6].DLY0}]
set_property PACKAGE_PIN B24 [get_ports {fmcb_adc0_ahdp[6]}]
set_property PACKAGE_PIN B25 [get_ports {fmcb_adc0_ahdn[6]}]
set_property LOC ILOGIC_X0Y280 [get_cells {chfpga0/ADCGEN[8].ADCDAQ0/IMPL.GBIT[7].ISERDESE0}]
set_property LOC IDELAY_X0Y280 [get_cells {chfpga0/ADCGEN[8].ADCDAQ0/IMPL.GBIT[7].DLY0}]
set_property PACKAGE_PIN H26 [get_ports {fmcb_adc0_ahdp[7]}]
set_property PACKAGE_PIN H27 [get_ports {fmcb_adc0_ahdn[7]}]

set_property LOC ILOGIC_X0Y274 [get_cells {chfpga0/ADCGEN[9].ADCDAQ0/IMPL.GBIT[0].ISERDESE0}]
set_property LOC IDELAY_X0Y274 [get_cells {chfpga0/ADCGEN[9].ADCDAQ0/IMPL.GBIT[0].DLY0}]
set_property PACKAGE_PIN G27 [get_ports {fmcb_adc0_bhdp[0]}]
set_property PACKAGE_PIN F27 [get_ports {fmcb_adc0_bhdn[0]}]
set_property LOC ILOGIC_X0Y266 [get_cells {chfpga0/ADCGEN[9].ADCDAQ0/IMPL.GBIT[1].ISERDESE0}]
set_property LOC IDELAY_X0Y266 [get_cells {chfpga0/ADCGEN[9].ADCDAQ0/IMPL.GBIT[1].DLY0}]
set_property PACKAGE_PIN H30 [get_ports {fmcb_adc0_bhdp[1]}]
set_property PACKAGE_PIN G30 [get_ports {fmcb_adc0_bhdn[1]}]
set_property LOC ILOGIC_X0Y298 [get_cells {chfpga0/ADCGEN[9].ADCDAQ0/IMPL.GBIT[2].ISERDESE0}]
set_property LOC IDELAY_X0Y298 [get_cells {chfpga0/ADCGEN[9].ADCDAQ0/IMPL.GBIT[2].DLY0}]
set_property PACKAGE_PIN D24 [get_ports {fmcb_adc0_bhdp[2]}]
set_property PACKAGE_PIN C24 [get_ports {fmcb_adc0_bhdn[2]}]
set_property LOC ILOGIC_X0Y262 [get_cells {chfpga0/ADCGEN[9].ADCDAQ0/IMPL.GBIT[3].ISERDESE0}]
set_property LOC IDELAY_X0Y262 [get_cells {chfpga0/ADCGEN[9].ADCDAQ0/IMPL.GBIT[3].DLY0}]
set_property PACKAGE_PIN E28 [get_ports {fmcb_adc0_bhdp[3]}]
set_property PACKAGE_PIN D28 [get_ports {fmcb_adc0_bhdn[3]}]
set_property LOC ILOGIC_X0Y264 [get_cells {chfpga0/ADCGEN[9].ADCDAQ0/IMPL.GBIT[4].ISERDESE0}]
set_property LOC IDELAY_X0Y264 [get_cells {chfpga0/ADCGEN[9].ADCDAQ0/IMPL.GBIT[4].DLY0}]
set_property PACKAGE_PIN J28 [get_ports {fmcb_adc0_bhdp[4]}]
set_property PACKAGE_PIN J29 [get_ports {fmcb_adc0_bhdn[4]}]
set_property LOC ILOGIC_X0Y270 [get_cells {chfpga0/ADCGEN[9].ADCDAQ0/IMPL.GBIT[5].ISERDESE0}]
set_property LOC IDELAY_X0Y270 [get_cells {chfpga0/ADCGEN[9].ADCDAQ0/IMPL.GBIT[5].DLY0}]
set_property PACKAGE_PIN H29 [get_ports {fmcb_adc0_bhdp[5]}]
set_property PACKAGE_PIN G29 [get_ports {fmcb_adc0_bhdn[5]}]
set_property LOC ILOGIC_X0Y294 [get_cells {chfpga0/ADCGEN[9].ADCDAQ0/IMPL.GBIT[6].ISERDESE0}]
set_property LOC IDELAY_X0Y294 [get_cells {chfpga0/ADCGEN[9].ADCDAQ0/IMPL.GBIT[6].DLY0}]
set_property PACKAGE_PIN C25 [get_ports {fmcb_adc0_bhdp[6]}]
set_property PACKAGE_PIN C26 [get_ports {fmcb_adc0_bhdn[6]}]
set_property LOC ILOGIC_X0Y292 [get_cells {chfpga0/ADCGEN[9].ADCDAQ0/IMPL.GBIT[7].ISERDESE0}]
set_property LOC IDELAY_X0Y292 [get_cells {chfpga0/ADCGEN[9].ADCDAQ0/IMPL.GBIT[7].DLY0}]
set_property PACKAGE_PIN A25 [get_ports {fmcb_adc0_bhdp[7]}]
set_property PACKAGE_PIN A26 [get_ports {fmcb_adc0_bhdn[7]}]
set_property LOC IDELAY_X0Y324 [get_cells {chfpga0/ADCGEN[10].ADCDAQ0/IMPL.CLKDLY0}]
set_property LOC ILOGIC_X0Y324 [get_cells {chfpga0/ADCGEN[10].ADCDAQ0/IMPL.IDDR_CLK}]
set_property LOC BUFMRCE_X0Y13 [get_cells {chfpga0/ADCGEN[10].ADCDAQ0/IMPL.YESBUFMR.BUFMRn}]
set_property PACKAGE_PIN E20 [get_ports fmcb_adc0_cdrp]
set_property PACKAGE_PIN E21 [get_ports fmcb_adc0_cdrn]
set_property LOC ILOGIC_X0Y368 [get_cells {chfpga0/ADCGEN[10].ADCDAQ0/IMPL.GBIT[0].ISERDESE0}]
set_property LOC IDELAY_X0Y368 [get_cells {chfpga0/ADCGEN[10].ADCDAQ0/IMPL.GBIT[0].DLY0}]
set_property PACKAGE_PIN C14 [get_ports {fmcb_adc0_chdp[0]}]
set_property PACKAGE_PIN B15 [get_ports {fmcb_adc0_chdn[0]}]
set_property LOC ILOGIC_X0Y366 [get_cells {chfpga0/ADCGEN[10].ADCDAQ0/IMPL.GBIT[1].ISERDESE0}]
set_property LOC IDELAY_X0Y366 [get_cells {chfpga0/ADCGEN[10].ADCDAQ0/IMPL.GBIT[1].DLY0}]
set_property PACKAGE_PIN B14 [get_ports {fmcb_adc0_chdp[1]}]
set_property PACKAGE_PIN A14 [get_ports {fmcb_adc0_chdn[1]}]
set_property LOC ILOGIC_X0Y260 [get_cells {chfpga0/ADCGEN[10].ADCDAQ0/IMPL.GBIT[2].ISERDESE0}]
set_property LOC IDELAY_X0Y260 [get_cells {chfpga0/ADCGEN[10].ADCDAQ0/IMPL.GBIT[2].DLY0}]
set_property PACKAGE_PIN E29 [get_ports {fmcb_adc0_chdp[2]}]
set_property PACKAGE_PIN D29 [get_ports {fmcb_adc0_chdn[2]}]
set_property LOC ILOGIC_X0Y256 [get_cells {chfpga0/ADCGEN[10].ADCDAQ0/IMPL.GBIT[3].ISERDESE0}]
set_property LOC IDELAY_X0Y256 [get_cells {chfpga0/ADCGEN[10].ADCDAQ0/IMPL.GBIT[3].DLY0}]
set_property PACKAGE_PIN B28 [get_ports {fmcb_adc0_chdp[3]}]
set_property PACKAGE_PIN B29 [get_ports {fmcb_adc0_chdn[3]}]
set_property LOC ILOGIC_X0Y254 [get_cells {chfpga0/ADCGEN[10].ADCDAQ0/IMPL.GBIT[4].ISERDESE0}]
set_property LOC IDELAY_X0Y254 [get_cells {chfpga0/ADCGEN[10].ADCDAQ0/IMPL.GBIT[4].DLY0}]
set_property PACKAGE_PIN B30 [get_ports {fmcb_adc0_chdp[4]}]
set_property PACKAGE_PIN A30 [get_ports {fmcb_adc0_chdn[4]}]
set_property LOC ILOGIC_X0Y312 [get_cells {chfpga0/ADCGEN[10].ADCDAQ0/IMPL.GBIT[5].ISERDESE0}]
set_property LOC IDELAY_X0Y312 [get_cells {chfpga0/ADCGEN[10].ADCDAQ0/IMPL.GBIT[5].DLY0}]
set_property PACKAGE_PIN C19 [get_ports {fmcb_adc0_chdp[5]}]
set_property PACKAGE_PIN C20 [get_ports {fmcb_adc0_chdn[5]}]
set_property LOC ILOGIC_X0Y252 [get_cells {chfpga0/ADCGEN[10].ADCDAQ0/IMPL.GBIT[6].ISERDESE0}]
set_property LOC IDELAY_X0Y252 [get_cells {chfpga0/ADCGEN[10].ADCDAQ0/IMPL.GBIT[6].DLY0}]
set_property PACKAGE_PIN A27 [get_ports {fmcb_adc0_chdp[6]}]
set_property PACKAGE_PIN A28 [get_ports {fmcb_adc0_chdn[6]}]
set_property LOC ILOGIC_X0Y308 [get_cells {chfpga0/ADCGEN[10].ADCDAQ0/IMPL.GBIT[7].ISERDESE0}]
set_property LOC IDELAY_X0Y308 [get_cells {chfpga0/ADCGEN[10].ADCDAQ0/IMPL.GBIT[7].DLY0}]
set_property PACKAGE_PIN B18 [get_ports {fmcb_adc0_chdp[7]}]
set_property PACKAGE_PIN A18 [get_ports {fmcb_adc0_chdn[7]}]
set_property LOC IDELAY_X0Y326 [get_cells {chfpga0/ADCGEN[11].ADCDAQ0/IMPL.CLKDLY0}]
set_property LOC ILOGIC_X0Y326 [get_cells {chfpga0/ADCGEN[11].ADCDAQ0/IMPL.IDDR_CLK}]
set_property LOC BUFMRCE_X0Y12 [get_cells {chfpga0/ADCGEN[11].ADCDAQ0/IMPL.YESBUFMR.BUFMRn}]
set_property PACKAGE_PIN F20 [get_ports fmcb_adc0_ddrp]
set_property PACKAGE_PIN F21 [get_ports fmcb_adc0_ddrn]
set_property LOC ILOGIC_X0Y364 [get_cells {chfpga0/ADCGEN[11].ADCDAQ0/IMPL.GBIT[0].ISERDESE0}]
set_property LOC IDELAY_X0Y364 [get_cells {chfpga0/ADCGEN[11].ADCDAQ0/IMPL.GBIT[0].DLY0}]
set_property PACKAGE_PIN A15 [get_ports {fmcb_adc0_dhdp[0]}]
set_property PACKAGE_PIN A16 [get_ports {fmcb_adc0_dhdn[0]}]
set_property LOC ILOGIC_X0Y362 [get_cells {chfpga0/ADCGEN[11].ADCDAQ0/IMPL.GBIT[1].ISERDESE0}]
set_property LOC IDELAY_X0Y362 [get_cells {chfpga0/ADCGEN[11].ADCDAQ0/IMPL.GBIT[1].DLY0}]
set_property PACKAGE_PIN D17 [get_ports {fmcb_adc0_dhdp[1]}]
set_property PACKAGE_PIN C17 [get_ports {fmcb_adc0_dhdn[1]}]
set_property LOC ILOGIC_X0Y360 [get_cells {chfpga0/ADCGEN[11].ADCDAQ0/IMPL.GBIT[2].ISERDESE0}]
set_property LOC IDELAY_X0Y360 [get_cells {chfpga0/ADCGEN[11].ADCDAQ0/IMPL.GBIT[2].DLY0}]
set_property PACKAGE_PIN B17 [get_ports {fmcb_adc0_dhdp[2]}]
set_property PACKAGE_PIN A17 [get_ports {fmcb_adc0_dhdn[2]}]
set_property LOC ILOGIC_X0Y306 [get_cells {chfpga0/ADCGEN[11].ADCDAQ0/IMPL.GBIT[3].ISERDESE0}]
set_property LOC IDELAY_X0Y306 [get_cells {chfpga0/ADCGEN[11].ADCDAQ0/IMPL.GBIT[3].DLY0}]
set_property PACKAGE_PIN A20 [get_ports {fmcb_adc0_dhdp[3]}]
set_property PACKAGE_PIN A21 [get_ports {fmcb_adc0_dhdn[3]}]
set_property LOC ILOGIC_X0Y318 [get_cells {chfpga0/ADCGEN[11].ADCDAQ0/IMPL.GBIT[4].ISERDESE0}]
set_property LOC IDELAY_X0Y318 [get_cells {chfpga0/ADCGEN[11].ADCDAQ0/IMPL.GBIT[4].DLY0}]
set_property PACKAGE_PIN C21 [get_ports {fmcb_adc0_dhdp[4]}]
set_property PACKAGE_PIN C22 [get_ports {fmcb_adc0_dhdn[4]}]
set_property LOC ILOGIC_X0Y314 [get_cells {chfpga0/ADCGEN[11].ADCDAQ0/IMPL.GBIT[5].ISERDESE0}]
set_property LOC IDELAY_X0Y314 [get_cells {chfpga0/ADCGEN[11].ADCDAQ0/IMPL.GBIT[5].DLY0}]
set_property PACKAGE_PIN D18 [get_ports {fmcb_adc0_dhdp[5]}]
set_property PACKAGE_PIN D19 [get_ports {fmcb_adc0_dhdn[5]}]
set_property LOC ILOGIC_X0Y316 [get_cells {chfpga0/ADCGEN[11].ADCDAQ0/IMPL.GBIT[6].ISERDESE0}]
set_property LOC IDELAY_X0Y316 [get_cells {chfpga0/ADCGEN[11].ADCDAQ0/IMPL.GBIT[6].DLY0}]
set_property PACKAGE_PIN E18 [get_ports {fmcb_adc0_dhdp[6]}]
set_property PACKAGE_PIN E19 [get_ports {fmcb_adc0_dhdn[6]}]
set_property LOC ILOGIC_X0Y320 [get_cells {chfpga0/ADCGEN[11].ADCDAQ0/IMPL.GBIT[7].ISERDESE0}]
set_property LOC IDELAY_X0Y320 [get_cells {chfpga0/ADCGEN[11].ADCDAQ0/IMPL.GBIT[7].DLY0}]
set_property PACKAGE_PIN E23 [get_ports {fmcb_adc0_dhdp[7]}]
set_property PACKAGE_PIN D23 [get_ports {fmcb_adc0_dhdn[7]}]
set_property LOC ILOGIC_X0Y226 [get_cells {chfpga0/ADCGEN[12].ADCDAQ0/IMPL.IDDR_CLK}]
set_property LOC BUFMRCE_X0Y8 [get_cells {chfpga0/ADCGEN[12].ADCDAQ0/IMPL.YESBUFMR.BUFMRn}]
set_property LOC IDELAY_X0Y226 [get_cells {chfpga0/ADCGEN[12].ADCDAQ0/IMPL.CLKDLY0}]
set_property PACKAGE_PIN L26 [get_ports fmcb_adc1_adrp]
set_property PACKAGE_PIN L27 [get_ports fmcb_adc1_adrn]
set_property LOC IDELAY_X0Y238 [get_cells {chfpga0/ADCGEN[12].ADCDAQ0/IMPL.GBIT[0].DLY0}]
set_property LOC ILOGIC_X0Y238 [get_cells {chfpga0/ADCGEN[12].ADCDAQ0/IMPL.GBIT[0].ISERDESE0}]
set_property PACKAGE_PIN M28 [get_ports {fmcb_adc1_ahdp[0]}]
set_property PACKAGE_PIN L28 [get_ports {fmcb_adc1_ahdn[0]}]
set_property LOC IDELAY_X0Y230 [get_cells {chfpga0/ADCGEN[12].ADCDAQ0/IMPL.GBIT[1].DLY0}]
set_property LOC ILOGIC_X0Y230 [get_cells {chfpga0/ADCGEN[12].ADCDAQ0/IMPL.GBIT[1].ISERDESE0}]
set_property PACKAGE_PIN P27 [get_ports {fmcb_adc1_ahdp[1]}]
set_property PACKAGE_PIN P28 [get_ports {fmcb_adc1_ahdn[1]}]
set_property LOC IDELAY_X0Y216 [get_cells {chfpga0/ADCGEN[12].ADCDAQ0/IMPL.GBIT[2].DLY0}]
set_property LOC ILOGIC_X0Y216 [get_cells {chfpga0/ADCGEN[12].ADCDAQ0/IMPL.GBIT[2].ISERDESE0}]
set_property PACKAGE_PIN P23 [get_ports {fmcb_adc1_ahdp[2]}]
set_property PACKAGE_PIN P24 [get_ports {fmcb_adc1_ahdn[2]}]
set_property LOC IDELAY_X0Y206 [get_cells {chfpga0/ADCGEN[12].ADCDAQ0/IMPL.GBIT[3].DLY0}]
set_property LOC ILOGIC_X0Y206 [get_cells {chfpga0/ADCGEN[12].ADCDAQ0/IMPL.GBIT[3].ISERDESE0}]
set_property PACKAGE_PIN P19 [get_ports {fmcb_adc1_ahdp[3]}]
set_property PACKAGE_PIN N19 [get_ports {fmcb_adc1_ahdn[3]}]
set_property LOC IDELAY_X0Y204 [get_cells {chfpga0/ADCGEN[12].ADCDAQ0/IMPL.GBIT[4].DLY0}]
set_property LOC ILOGIC_X0Y204 [get_cells {chfpga0/ADCGEN[12].ADCDAQ0/IMPL.GBIT[4].ISERDESE0}]
set_property PACKAGE_PIN N17 [get_ports {fmcb_adc1_ahdp[4]}]
set_property PACKAGE_PIN M17 [get_ports {fmcb_adc1_ahdn[4]}]
set_property LOC IDELAY_X0Y202 [get_cells {chfpga0/ADCGEN[12].ADCDAQ0/IMPL.GBIT[5].DLY0}]
set_property LOC ILOGIC_X0Y202 [get_cells {chfpga0/ADCGEN[12].ADCDAQ0/IMPL.GBIT[5].ISERDESE0}]
set_property PACKAGE_PIN P17 [get_ports {fmcb_adc1_ahdp[5]}]
set_property PACKAGE_PIN P18 [get_ports {fmcb_adc1_ahdn[5]}]
set_property LOC IDELAY_X0Y220 [get_cells {chfpga0/ADCGEN[12].ADCDAQ0/IMPL.GBIT[6].DLY0}]
set_property LOC ILOGIC_X0Y220 [get_cells {chfpga0/ADCGEN[12].ADCDAQ0/IMPL.GBIT[6].ISERDESE0}]
set_property PACKAGE_PIN L23 [get_ports {fmcb_adc1_ahdp[6]}]
set_property PACKAGE_PIN K24 [get_ports {fmcb_adc1_ahdn[6]}]
set_property LOC IDELAY_X0Y218 [get_cells {chfpga0/ADCGEN[12].ADCDAQ0/IMPL.GBIT[7].DLY0}]
set_property LOC ILOGIC_X0Y218 [get_cells {chfpga0/ADCGEN[12].ADCDAQ0/IMPL.GBIT[7].ISERDESE0}]
set_property PACKAGE_PIN N22 [get_ports {fmcb_adc1_ahdp[7]}]
set_property PACKAGE_PIN M22 [get_ports {fmcb_adc1_ahdn[7]}]
set_property LOC BUFMRCE_X0Y9 [get_cells {chfpga0/ADCGEN[13].ADCDAQ0/IMPL.YESBUFMR.BUFMRn}]
set_property LOC ILOGIC_X0Y224 [get_cells {chfpga0/ADCGEN[13].ADCDAQ0/IMPL.IDDR_CLK}]
set_property LOC IDELAY_X0Y224 [get_cells {chfpga0/ADCGEN[13].ADCDAQ0/IMPL.CLKDLY0}]
set_property PACKAGE_PIN M23 [get_ports fmcb_adc1_bdrp]
set_property PACKAGE_PIN M24 [get_ports fmcb_adc1_bdrn]
set_property LOC IDELAY_X0Y248 [get_cells {chfpga0/ADCGEN[13].ADCDAQ0/IMPL.GBIT[0].DLY0}]
set_property LOC ILOGIC_X0Y248 [get_cells {chfpga0/ADCGEN[13].ADCDAQ0/IMPL.GBIT[0].ISERDESE0}]
set_property PACKAGE_PIN K28 [get_ports {fmcb_adc1_bhdp[0]}]
set_property PACKAGE_PIN K29 [get_ports {fmcb_adc1_bhdn[0]}]
set_property LOC IDELAY_X0Y246 [get_cells {chfpga0/ADCGEN[13].ADCDAQ0/IMPL.GBIT[1].DLY0}]
set_property LOC ILOGIC_X0Y246 [get_cells {chfpga0/ADCGEN[13].ADCDAQ0/IMPL.GBIT[1].ISERDESE0}]
set_property PACKAGE_PIN L30 [get_ports {fmcb_adc1_bhdp[1]}]
set_property PACKAGE_PIN K30 [get_ports {fmcb_adc1_bhdn[1]}]
set_property LOC IDELAY_X0Y244 [get_cells {chfpga0/ADCGEN[13].ADCDAQ0/IMPL.GBIT[2].DLY0}]
set_property LOC ILOGIC_X0Y244 [get_cells {chfpga0/ADCGEN[13].ADCDAQ0/IMPL.GBIT[2].ISERDESE0}]
set_property PACKAGE_PIN N30 [get_ports {fmcb_adc1_bhdp[2]}]
set_property PACKAGE_PIN M30 [get_ports {fmcb_adc1_bhdn[2]}]
set_property LOC IDELAY_X0Y242 [get_cells {chfpga0/ADCGEN[13].ADCDAQ0/IMPL.GBIT[3].DLY0}]
set_property LOC ILOGIC_X0Y242 [get_cells {chfpga0/ADCGEN[13].ADCDAQ0/IMPL.GBIT[3].ISERDESE0}]
set_property PACKAGE_PIN N29 [get_ports {fmcb_adc1_bhdp[3]}]
set_property PACKAGE_PIN M29 [get_ports {fmcb_adc1_bhdn[3]}]
set_property LOC IDELAY_X0Y240 [get_cells {chfpga0/ADCGEN[13].ADCDAQ0/IMPL.GBIT[4].DLY0}]
set_property LOC ILOGIC_X0Y240 [get_cells {chfpga0/ADCGEN[13].ADCDAQ0/IMPL.GBIT[4].ISERDESE0}]
set_property PACKAGE_PIN R29 [get_ports {fmcb_adc1_bhdp[4]}]
set_property PACKAGE_PIN P29 [get_ports {fmcb_adc1_bhdn[4]}]
set_property LOC IDELAY_X0Y212 [get_cells {chfpga0/ADCGEN[13].ADCDAQ0/IMPL.GBIT[5].DLY0}]
set_property LOC ILOGIC_X0Y212 [get_cells {chfpga0/ADCGEN[13].ADCDAQ0/IMPL.GBIT[5].ISERDESE0}]
set_property PACKAGE_PIN N20 [get_ports {fmcb_adc1_bhdp[5]}]
set_property PACKAGE_PIN M20 [get_ports {fmcb_adc1_bhdn[5]}]
set_property LOC IDELAY_X0Y236 [get_cells {chfpga0/ADCGEN[13].ADCDAQ0/IMPL.GBIT[6].DLY0}]
set_property LOC ILOGIC_X0Y236 [get_cells {chfpga0/ADCGEN[13].ADCDAQ0/IMPL.GBIT[6].ISERDESE0}]
set_property PACKAGE_PIN K25 [get_ports {fmcb_adc1_bhdp[6]}]
set_property PACKAGE_PIN K26 [get_ports {fmcb_adc1_bhdn[6]}]
set_property LOC IDELAY_X0Y234 [get_cells {chfpga0/ADCGEN[13].ADCDAQ0/IMPL.GBIT[7].DLY0}]
set_property LOC ILOGIC_X0Y234 [get_cells {chfpga0/ADCGEN[13].ADCDAQ0/IMPL.GBIT[7].ISERDESE0}]
set_property PACKAGE_PIN P26 [get_ports {fmcb_adc1_bhdp[7]}]
set_property PACKAGE_PIN N26 [get_ports {fmcb_adc1_bhdn[7]}]
set_property LOC BUFMRCE_X0Y14 [get_cells {chfpga0/ADCGEN[14].ADCDAQ0/IMPL.YESBUFMR.BUFMRn}]
set_property LOC ILOGIC_X0Y376 [get_cells {chfpga0/ADCGEN[14].ADCDAQ0/IMPL.IDDR_CLK}]
set_property LOC IDELAY_X0Y376 [get_cells {chfpga0/ADCGEN[14].ADCDAQ0/IMPL.CLKDLY0}]
set_property PACKAGE_PIN G15 [get_ports fmcb_adc1_cdrp]
set_property PACKAGE_PIN F15 [get_ports fmcb_adc1_cdrn]
set_property LOC IDELAY_X0Y378 [get_cells {chfpga0/ADCGEN[14].ADCDAQ0/IMPL.GBIT[0].DLY0}]
set_property LOC ILOGIC_X0Y378 [get_cells {chfpga0/ADCGEN[14].ADCDAQ0/IMPL.GBIT[0].ISERDESE0}]
set_property PACKAGE_PIN F16 [get_ports {fmcb_adc1_chdp[0]}]
set_property PACKAGE_PIN E16 [get_ports {fmcb_adc1_chdn[0]}]
set_property LOC IDELAY_X0Y372 [get_cells {chfpga0/ADCGEN[14].ADCDAQ0/IMPL.GBIT[1].DLY0}]
set_property LOC ILOGIC_X0Y372 [get_cells {chfpga0/ADCGEN[14].ADCDAQ0/IMPL.GBIT[1].ISERDESE0}]
set_property PACKAGE_PIN E15 [get_ports {fmcb_adc1_chdp[1]}]
set_property PACKAGE_PIN D16 [get_ports {fmcb_adc1_chdn[1]}]
set_property LOC IDELAY_X0Y388 [get_cells {chfpga0/ADCGEN[14].ADCDAQ0/IMPL.GBIT[2].DLY0}]
set_property LOC ILOGIC_X0Y388 [get_cells {chfpga0/ADCGEN[14].ADCDAQ0/IMPL.GBIT[2].ISERDESE0}]
set_property PACKAGE_PIN J16 [get_ports {fmcb_adc1_chdp[2]}]
set_property PACKAGE_PIN J17 [get_ports {fmcb_adc1_chdn[2]}]
set_property LOC IDELAY_X0Y348 [get_cells {chfpga0/ADCGEN[14].ADCDAQ0/IMPL.GBIT[3].DLY0}]
set_property LOC ILOGIC_X0Y348 [get_cells {chfpga0/ADCGEN[14].ADCDAQ0/IMPL.GBIT[3].ISERDESE0}]
set_property PACKAGE_PIN K23 [get_ports {fmcb_adc1_chdp[3]}]
set_property PACKAGE_PIN J23 [get_ports {fmcb_adc1_chdn[3]}]
set_property LOC IDELAY_X0Y384 [get_cells {chfpga0/ADCGEN[14].ADCDAQ0/IMPL.GBIT[4].DLY0}]
set_property LOC ILOGIC_X0Y384 [get_cells {chfpga0/ADCGEN[14].ADCDAQ0/IMPL.GBIT[4].ISERDESE0}]
set_property PACKAGE_PIN H16 [get_ports {fmcb_adc1_chdp[4]}]
set_property PACKAGE_PIN H17 [get_ports {fmcb_adc1_chdn[4]}]
set_property LOC IDELAY_X0Y382 [get_cells {chfpga0/ADCGEN[14].ADCDAQ0/IMPL.GBIT[5].DLY0}]
set_property LOC ILOGIC_X0Y382 [get_cells {chfpga0/ADCGEN[14].ADCDAQ0/IMPL.GBIT[5].ISERDESE0}]
set_property PACKAGE_PIN H14 [get_ports {fmcb_adc1_chdp[5]}]
set_property PACKAGE_PIN G14 [get_ports {fmcb_adc1_chdn[5]}]
set_property LOC IDELAY_X0Y380 [get_cells {chfpga0/ADCGEN[14].ADCDAQ0/IMPL.GBIT[6].DLY0}]
set_property LOC ILOGIC_X0Y380 [get_cells {chfpga0/ADCGEN[14].ADCDAQ0/IMPL.GBIT[6].ISERDESE0}]
set_property PACKAGE_PIN G17 [get_ports {fmcb_adc1_chdp[6]}]
set_property PACKAGE_PIN F17 [get_ports {fmcb_adc1_chdn[6]}]
set_property LOC IDELAY_X0Y370 [get_cells {chfpga0/ADCGEN[14].ADCDAQ0/IMPL.GBIT[7].DLY0}]
set_property LOC ILOGIC_X0Y370 [get_cells {chfpga0/ADCGEN[14].ADCDAQ0/IMPL.GBIT[7].ISERDESE0}]
set_property PACKAGE_PIN E14 [get_ports {fmcb_adc1_chdp[7]}]
set_property PACKAGE_PIN D14 [get_ports {fmcb_adc1_chdn[7]}]
set_property LOC BUFMRCE_X0Y15 [get_cells {chfpga0/ADCGEN[15].ADCDAQ0/IMPL.YESBUFMR.BUFMRn}]
set_property LOC ILOGIC_X0Y374 [get_cells {chfpga0/ADCGEN[15].ADCDAQ0/IMPL.IDDR_CLK}]
set_property LOC IDELAY_X0Y374 [get_cells {chfpga0/ADCGEN[15].ADCDAQ0/IMPL.CLKDLY0}]
set_property PACKAGE_PIN C15 [get_ports fmcb_adc1_ddrp]
set_property PACKAGE_PIN C16 [get_ports fmcb_adc1_ddrn]
set_property LOC IDELAY_X0Y346 [get_cells {chfpga0/ADCGEN[15].ADCDAQ0/IMPL.GBIT[0].DLY0}]
set_property LOC ILOGIC_X0Y346 [get_cells {chfpga0/ADCGEN[15].ADCDAQ0/IMPL.GBIT[0].ISERDESE0}]
set_property PACKAGE_PIN J22 [get_ports {fmcb_adc1_dhdp[0]}]
set_property PACKAGE_PIN H22 [get_ports {fmcb_adc1_dhdn[0]}]
set_property LOC IDELAY_X0Y344 [get_cells {chfpga0/ADCGEN[15].ADCDAQ0/IMPL.GBIT[1].DLY0}]
set_property LOC ILOGIC_X0Y344 [get_cells {chfpga0/ADCGEN[15].ADCDAQ0/IMPL.GBIT[1].ISERDESE0}]
set_property PACKAGE_PIN K21 [get_ports {fmcb_adc1_dhdp[1]}]
set_property PACKAGE_PIN J21 [get_ports {fmcb_adc1_dhdn[1]}]
set_property LOC IDELAY_X0Y342 [get_cells {chfpga0/ADCGEN[15].ADCDAQ0/IMPL.GBIT[2].DLY0}]
set_property LOC ILOGIC_X0Y342 [get_cells {chfpga0/ADCGEN[15].ADCDAQ0/IMPL.GBIT[2].ISERDESE0}]
set_property PACKAGE_PIN K19 [get_ports {fmcb_adc1_dhdp[2]}]
set_property PACKAGE_PIN K20 [get_ports {fmcb_adc1_dhdn[2]}]
set_property LOC IDELAY_X0Y340 [get_cells {chfpga0/ADCGEN[15].ADCDAQ0/IMPL.GBIT[3].DLY0}]
set_property LOC ILOGIC_X0Y340 [get_cells {chfpga0/ADCGEN[15].ADCDAQ0/IMPL.GBIT[3].ISERDESE0}]
set_property PACKAGE_PIN J18 [get_ports {fmcb_adc1_dhdp[3]}]
set_property PACKAGE_PIN J19 [get_ports {fmcb_adc1_dhdn[3]}]
set_property LOC IDELAY_X0Y338 [get_cells {chfpga0/ADCGEN[15].ADCDAQ0/IMPL.GBIT[4].DLY0}]
set_property LOC ILOGIC_X0Y338 [get_cells {chfpga0/ADCGEN[15].ADCDAQ0/IMPL.GBIT[4].ISERDESE0}]
set_property PACKAGE_PIN L18 [get_ports {fmcb_adc1_dhdp[4]}]
set_property PACKAGE_PIN K18 [get_ports {fmcb_adc1_dhdn[4]}]
set_property LOC IDELAY_X0Y336 [get_cells {chfpga0/ADCGEN[15].ADCDAQ0/IMPL.GBIT[5].DLY0}]
set_property LOC ILOGIC_X0Y336 [get_cells {chfpga0/ADCGEN[15].ADCDAQ0/IMPL.GBIT[5].ISERDESE0}]
set_property PACKAGE_PIN G23 [get_ports {fmcb_adc1_dhdp[5]}]
set_property PACKAGE_PIN F23 [get_ports {fmcb_adc1_dhdn[5]}]
set_property LOC IDELAY_X0Y334 [get_cells {chfpga0/ADCGEN[15].ADCDAQ0/IMPL.GBIT[6].DLY0}]
set_property LOC ILOGIC_X0Y334 [get_cells {chfpga0/ADCGEN[15].ADCDAQ0/IMPL.GBIT[6].ISERDESE0}]
set_property PACKAGE_PIN H20 [get_ports {fmcb_adc1_dhdp[6]}]
set_property PACKAGE_PIN G20 [get_ports {fmcb_adc1_dhdn[6]}]
set_property LOC IDELAY_X0Y332 [get_cells {chfpga0/ADCGEN[15].ADCDAQ0/IMPL.GBIT[7].DLY0}]
set_property LOC ILOGIC_X0Y332 [get_cells {chfpga0/ADCGEN[15].ADCDAQ0/IMPL.GBIT[7].ISERDESE0}]
set_property PACKAGE_PIN H19 [get_ports {fmcb_adc1_dhdp[7]}]
set_property PACKAGE_PIN G19 [get_ports {fmcb_adc1_dhdn[7]}]


set_property PACKAGE_PIN L21 [get_ports fmcb_buck1v8_sync]
set_property PACKAGE_PIN L20 [get_ports fmcb_buck3v3_sync]


set_property PACKAGE_PIN F18 [get_ports fmcb_spi_cs_n]

set_property PACKAGE_PIN B19 [get_ports {fmcb_spi_addr[0]}]
set_property PACKAGE_PIN C30 [get_ports {fmcb_spi_addr[1]}]
set_property PACKAGE_PIN C29 [get_ports {fmcb_spi_addr[2]}]
set_property PACKAGE_PIN B23 [get_ports fmcb_spi_sck]
set_property PACKAGE_PIN B20 [get_ports fmcb_spi_miso]
set_property PACKAGE_PIN B22 [get_ports fmcb_spi_mosi]
set_property PACKAGE_PIN H15 [get_ports fmcb_spi_rst_n_alt]
#set_property PACKAGE_PIN  [get_ports {fmcb_SPI_RST_N}]

set_property PACKAGE_PIN M25 [get_ports fmcb_refclk_m2c_p]
set_property PACKAGE_PIN L25 [get_ports fmcb_refclk_m2c_n]



# set_property PACKAGE_PIN U7 [get_ports {fmca_MGT0_CLK_M2C_N}]
# set_property PACKAGE_PIN U8 [get_ports {fmca_MGT0_CLK_M2C_P}]
# set_property PACKAGE_PIN W7 [get_ports {fmca_MGT4_CLK_M2C_N}]
# set_property PACKAGE_PIN W8 [get_ports {fmca_MGT4_CLK_M2C_P}]
# set_property PACKAGE_PIN AB22 [get_ports {fmca_PLL_LOCK[2]}]

# set_property PACKAGE_PIN G18 [get_ports {fmcb_ADC_RST_N}]
# set_property PACKAGE_PIN G25 [get_ports {fmcb_ADC_SYNC_N}]
# set_property PACKAGE_PIN H25 [get_ports {fmcb_ADC_SYNC_P}]
# set_property PACKAGE_PIN E26 [get_ports {fmcb_adc0_adrn}]
# set_property PACKAGE_PIN E25 [get_ports {fmcb_adc0_adrp}]
# set_property PACKAGE_PIN  [get_ports {fmcb_adc0_ahdn[0]}]
# set_property PACKAGE_PIN D27 [get_ports {fmcb_adc0_ahdn[1]}]
# set_property PACKAGE_PIN G24 [get_ports {fmcb_adc0_ahdn[2]}]
# set_property PACKAGE_PIN B27 [get_ports {fmcb_adc0_ahdn[3]}]
# set_property PACKAGE_PIN J27 [get_ports {fmcb_adc0_ahdn[4]}]
# set_property PACKAGE_PIN E30 [get_ports {fmcb_adc0_ahdn[5]}]
# set_property PACKAGE_PIN B25 [get_ports {fmcb_adc0_ahdn[6]}]
# set_property PACKAGE_PIN H27 [get_ports {fmcb_adc0_ahdn[7]}]
# set_property PACKAGE_PIN F25 [get_ports {fmcb_adc0_ahdp[0]}]
# set_property PACKAGE_PIN D26 [get_ports {fmcb_adc0_ahdp[1]}]
# set_property PACKAGE_PIN H24 [get_ports {fmcb_adc0_ahdp[2]}]
# set_property PACKAGE_PIN C27 [get_ports {fmcb_adc0_ahdp[3]}]
# set_property PACKAGE_PIN J26 [get_ports {fmcb_adc0_ahdp[4]}]
# set_property PACKAGE_PIN F30 [get_ports {fmcb_adc0_ahdp[5]}]
# set_property PACKAGE_PIN B24 [get_ports {fmcb_adc0_ahdp[6]}]
# set_property PACKAGE_PIN H26 [get_ports {fmcb_adc0_ahdp[7]}]
# set_property PACKAGE_PIN F28 [get_ports {fmcb_adc0_bdrn}]
# set_property PACKAGE_PIN G28 [get_ports {fmcb_adc0_bdrp}]
# set_property PACKAGE_PIN F27 [get_ports {fmcb_adc0_bhdn[0]}]
# set_property PACKAGE_PIN G30 [get_ports {fmcb_adc0_bhdn[1]}]
# set_property PACKAGE_PIN C24 [get_ports {fmcb_adc0_bhdn[2]}]
# set_property PACKAGE_PIN D28 [get_ports {fmcb_adc0_bhdn[3]}]
# set_property PACKAGE_PIN J29 [get_ports {fmcb_adc0_bhdn[4]}]
# set_property PACKAGE_PIN G29 [get_ports {fmcb_adc0_bhdn[5]}]
# set_property PACKAGE_PIN C26 [get_ports {fmcb_adc0_bhdn[6]}]
# set_property PACKAGE_PIN A26 [get_ports {fmcb_adc0_bhdn[7]}]
# set_property PACKAGE_PIN G27 [get_ports {fmcb_adc0_bhdp[0]}]
# set_property PACKAGE_PIN H30 [get_ports {fmcb_adc0_bhdp[1]}]
# set_property PACKAGE_PIN D24 [get_ports {fmcb_adc0_bhdp[2]}]
# set_property PACKAGE_PIN E28 [get_ports {fmcb_adc0_bhdp[3]}]
# set_property PACKAGE_PIN J28 [get_ports {fmcb_adc0_bhdp[4]}]
# set_property PACKAGE_PIN H29 [get_ports {fmcb_adc0_bhdp[5]}]
# set_property PACKAGE_PIN C25 [get_ports {fmcb_adc0_bhdp[6]}]
# set_property PACKAGE_PIN A25 [get_ports {fmcb_adc0_bhdp[7]}]
# set_property PACKAGE_PIN E21 [get_ports {fmcb_adc0_cdrn}]
# set_property PACKAGE_PIN E20 [get_ports {fmcb_adc0_cdrp}]
# set_property PACKAGE_PIN B15 [get_ports {fmcb_adc0_chdn[0]}]
# set_property PACKAGE_PIN A14 [get_ports {fmcb_adc0_chdn[1]}]
# set_property PACKAGE_PIN D29 [get_ports {fmcb_adc0_chdn[2]}]
# set_property PACKAGE_PIN B29 [get_ports {fmcb_adc0_chdn[3]}]
# set_property PACKAGE_PIN A30 [get_ports {fmcb_adc0_chdn[4]}]
# set_property PACKAGE_PIN C20 [get_ports {fmcb_adc0_chdn[5]}]
# set_property PACKAGE_PIN A28 [get_ports {fmcb_adc0_chdn[6]}]
# set_property PACKAGE_PIN A18 [get_ports {fmcb_adc0_chdn[7]}]
# set_property PACKAGE_PIN C14 [get_ports {fmcb_adc0_chdp[0]}]
# set_property PACKAGE_PIN B14 [get_ports {fmcb_adc0_chdp[1]}]
# set_property PACKAGE_PIN E29 [get_ports {fmcb_adc0_chdp[2]}]
# set_property PACKAGE_PIN B28 [get_ports {fmcb_adc0_chdp[3]}]
# set_property PACKAGE_PIN B30 [get_ports {fmcb_adc0_chdp[4]}]
# set_property PACKAGE_PIN C19 [get_ports {fmcb_adc0_chdp[5]}]
# set_property PACKAGE_PIN A27 [get_ports {fmcb_adc0_chdp[6]}]
# set_property PACKAGE_PIN B18 [get_ports {fmcb_adc0_chdp[7]}]
# set_property PACKAGE_PIN F21 [get_ports {fmcb_adc0_ddrn}]
# set_property PACKAGE_PIN F20 [get_ports {fmcb_adc0_ddrp}]
# set_property PACKAGE_PIN A16 [get_ports {fmcb_adc0_dhdn[0]}]
# set_property PACKAGE_PIN C17 [get_ports {fmcb_adc0_dhdn[1]}]
# set_property PACKAGE_PIN A17 [get_ports {fmcb_adc0_dhdn[2]}]
# set_property PACKAGE_PIN A21 [get_ports {fmcb_adc0_dhdn[3]}]
# set_property PACKAGE_PIN C22 [get_ports {fmcb_adc0_dhdn[4]}]
# set_property PACKAGE_PIN D19 [get_ports {fmcb_adc0_dhdn[5]}]
# set_property PACKAGE_PIN E19 [get_ports {fmcb_adc0_dhdn[6]}]
# set_property PACKAGE_PIN D23 [get_ports {fmcb_adc0_dhdn[7]}]
# set_property PACKAGE_PIN A15 [get_ports {fmcb_adc0_dhdp[0]}]
# set_property PACKAGE_PIN D17 [get_ports {fmcb_adc0_dhdp[1]}]
# set_property PACKAGE_PIN B17 [get_ports {fmcb_adc0_dhdp[2]}]
# set_property PACKAGE_PIN A20 [get_ports {fmcb_adc0_dhdp[3]}]
# set_property PACKAGE_PIN C21 [get_ports {fmcb_adc0_dhdp[4]}]
# set_property PACKAGE_PIN D18 [get_ports {fmcb_adc0_dhdp[5]}]
# set_property PACKAGE_PIN E18 [get_ports {fmcb_adc0_dhdp[6]}]
# set_property PACKAGE_PIN E23 [get_ports {fmcb_adc0_dhdp[7]}]
# set_property PACKAGE_PIN L27 [get_ports {fmcb_adc1_adrn}]
# set_property PACKAGE_PIN L26 [get_ports {fmcb_adc1_adrp}]
# set_property PACKAGE_PIN L28 [get_ports {fmcb_adc1_ahdn[0]}]
# set_property PACKAGE_PIN P28 [get_ports {fmcb_adc1_ahdn[1]}]
# set_property PACKAGE_PIN P24 [get_ports {fmcb_adc1_ahdn[2]}]
# set_property PACKAGE_PIN N19 [get_ports {fmcb_adc1_ahdn[3]}]
# set_property PACKAGE_PIN M17 [get_ports {fmcb_adc1_ahdn[4]}]
# set_property PACKAGE_PIN P18 [get_ports {fmcb_adc1_ahdn[5]}]
# set_property PACKAGE_PIN K24 [get_ports {fmcb_adc1_ahdn[6]}]
# set_property PACKAGE_PIN M22 [get_ports {fmcb_adc1_ahdn[7]}]
# set_property PACKAGE_PIN M28 [get_ports {fmcb_adc1_ahdp[0]}]
# set_property PACKAGE_PIN P27 [get_ports {fmcb_adc1_ahdp[1]}]
# set_property PACKAGE_PIN P23 [get_ports {fmcb_adc1_ahdp[2]}]
# set_property PACKAGE_PIN P19 [get_ports {fmcb_adc1_ahdp[3]}]
# set_property PACKAGE_PIN N17 [get_ports {fmcb_adc1_ahdp[4]}]
# set_property PACKAGE_PIN P17 [get_ports {fmcb_adc1_ahdp[5]}]
# set_property PACKAGE_PIN L23 [get_ports {fmcb_adc1_ahdp[6]}]
# set_property PACKAGE_PIN N22 [get_ports {fmcb_adc1_ahdp[7]}]
# set_property PACKAGE_PIN M24 [get_ports {fmcb_adc1_bdrn}]
# set_property PACKAGE_PIN M23 [get_ports {fmcb_adc1_bdrp}]
# set_property PACKAGE_PIN K29 [get_ports {fmcb_adc1_bhdn[0]}]
# set_property PACKAGE_PIN K30 [get_ports {fmcb_adc1_bhdn[1]}]
# set_property PACKAGE_PIN M30 [get_ports {fmcb_adc1_bhdn[2]}]
# set_property PACKAGE_PIN M29 [get_ports {fmcb_adc1_bhdn[3]}]
# set_property PACKAGE_PIN P29 [get_ports {fmcb_adc1_bhdn[4]}]
# set_property PACKAGE_PIN M20 [get_ports {fmcb_adc1_bhdn[5]}]
# set_property PACKAGE_PIN K26 [get_ports {fmcb_adc1_bhdn[6]}]
# set_property PACKAGE_PIN N26 [get_ports {fmcb_adc1_bhdn[7]}]
# set_property PACKAGE_PIN K28 [get_ports {fmcb_adc1_bhdp[0]}]
# set_property PACKAGE_PIN L30 [get_ports {fmcb_adc1_bhdp[1]}]
# set_property PACKAGE_PIN N30 [get_ports {fmcb_adc1_bhdp[2]}]
# set_property PACKAGE_PIN N29 [get_ports {fmcb_adc1_bhdp[3]}]
# set_property PACKAGE_PIN R29 [get_ports {fmcb_adc1_bhdp[4]}]
# set_property PACKAGE_PIN N20 [get_ports {fmcb_adc1_bhdp[5]}]
# set_property PACKAGE_PIN K25 [get_ports {fmcb_adc1_bhdp[6]}]
# set_property PACKAGE_PIN P26 [get_ports {fmcb_adc1_bhdp[7]}]
# set_property PACKAGE_PIN F15 [get_ports {fmcb_adc1_cdrn}]
# set_property PACKAGE_PIN G15 [get_ports {fmcb_adc1_cdrp}]
# set_property PACKAGE_PIN E16 [get_ports {fmcb_adc1_chdn[0]}]
# set_property PACKAGE_PIN D16 [get_ports {fmcb_adc1_chdn[1]}]
# set_property PACKAGE_PIN J17 [get_ports {fmcb_adc1_chdn[2]}]
# set_property PACKAGE_PIN J23 [get_ports {fmcb_adc1_chdn[3]}]
# set_property PACKAGE_PIN H17 [get_ports {fmcb_adc1_chdn[4]}]
# set_property PACKAGE_PIN G14 [get_ports {fmcb_adc1_chdn[5]}]
# set_property PACKAGE_PIN F17 [get_ports {fmcb_adc1_chdn[6]}]
# set_property PACKAGE_PIN D14 [get_ports {fmcb_adc1_chdn[7]}]
# set_property PACKAGE_PIN F16 [get_ports {fmcb_adc1_chdp[0]}]
# set_property PACKAGE_PIN E15 [get_ports {fmcb_adc1_chdp[1]}]
# set_property PACKAGE_PIN J16 [get_ports {fmcb_adc1_chdp[2]}]
# set_property PACKAGE_PIN K23 [get_ports {fmcb_adc1_chdp[3]}]
# set_property PACKAGE_PIN H16 [get_ports {fmcb_adc1_chdp[4]}]
# set_property PACKAGE_PIN H14 [get_ports {fmcb_adc1_chdp[5]}]
# set_property PACKAGE_PIN G17 [get_ports {fmcb_adc1_chdp[6]}]
# set_property PACKAGE_PIN E14 [get_ports {fmcb_adc1_chdp[7]}]
# set_property PACKAGE_PIN C16 [get_ports {fmcb_adc1_ddrn}]
# set_property PACKAGE_PIN C15 [get_ports {fmcb_adc1_ddrp}]
# set_property PACKAGE_PIN H22 [get_ports {fmcb_adc1_dhdn[0]}]
# set_property PACKAGE_PIN J21 [get_ports {fmcb_adc1_dhdn[1]}]
# set_property PACKAGE_PIN K20 [get_ports {fmcb_adc1_dhdn[2]}]
# set_property PACKAGE_PIN J19 [get_ports {fmcb_adc1_dhdn[3]}]
# set_property PACKAGE_PIN K18 [get_ports {fmcb_adc1_dhdn[4]}]
# set_property PACKAGE_PIN F23 [get_ports {fmcb_adc1_dhdn[5]}]
# set_property PACKAGE_PIN G20 [get_ports {fmcb_adc1_dhdn[6]}]
# set_property PACKAGE_PIN G19 [get_ports {fmcb_adc1_dhdn[7]}]
# set_property PACKAGE_PIN J22 [get_ports {fmcb_adc1_dhdp[0]}]
# set_property PACKAGE_PIN K21 [get_ports {fmcb_adc1_dhdp[1]}]
# set_property PACKAGE_PIN K19 [get_ports {fmcb_adc1_dhdp[2]}]
# set_property PACKAGE_PIN J18 [get_ports {fmcb_adc1_dhdp[3]}]
# set_property PACKAGE_PIN L18 [get_ports {fmcb_adc1_dhdp[4]}]
# set_property PACKAGE_PIN G23 [get_ports {fmcb_adc1_dhdp[5]}]
# set_property PACKAGE_PIN H20 [get_ports {fmcb_adc1_dhdp[6]}]
# set_property PACKAGE_PIN H19 [get_ports {fmcb_adc1_dhdp[7]}]
# set_property PACKAGE_PIN L21 [get_ports {fmcb_BUCK1V8_SYNC}]
# set_property PACKAGE_PIN L20 [get_ports {fmcb_BUCK3V3_SYNC}]

# set_property PACKAGE_PIN AC7 [get_ports {fmcb_MGT0_CLK_M2C_N}]
# set_property PACKAGE_PIN AC8 [get_ports {fmcb_MGT0_CLK_M2C_P}]
# set_property PACKAGE_PIN AE7 [get_ports {fmcb_MGT4_CLK_M2C_N}]
# set_property PACKAGE_PIN AE8 [get_ports {fmcb_MGT4_CLK_M2C_P}]


# set_property PACKAGE_PIN F18 [get_ports {fmcb_PLL_LE}]
# set_property PACKAGE_PIN J14 [get_ports {fmcb_PLL_LOCK[2]}]
# set_property PACKAGE_PIN L25 [get_ports {fmcb_REFCLK_M2C_N}]
# set_property PACKAGE_PIN M25 [get_ports {fmcb_REFCLK_M2C_P}]
# set_property PACKAGE_PIN B19 [get_ports {fmcb_SPI_ADDR[0]}]
# set_property PACKAGE_PIN C30 [get_ports {fmcb_SPI_ADDR[1]}]
# set_property PACKAGE_PIN C29 [get_ports {fmcb_SPI_ADDR[2]}]
# set_property PACKAGE_PIN B20 [get_ports {fmcb_SPI_MISO}]
# set_property PACKAGE_PIN B22 [get_ports {fmcb_SPI_MOSI}]
# set_property PACKAGE_PIN  [get_ports {fmcb_SPI_RST_N}]
# set_property PACKAGE_PIN H15 [get_ports {fmcb_SPI_RST_N_ALT[2]}]
# set_property PACKAGE_PIN B23 [get_ports {fmcb_SPI_SCK}]

set_property LOC DCIRESET_X0Y0 [get_cells chfpga0/REFCLK0/DCIRESET0]
set_property LOC USR_ACCESS_X0Y0 [get_cells chfpga0/GPIO0/USRACCESS_7.USR_ACCESS0]
set_property LOC XADC_X0Y0 [get_cells chfpga0/SYSMON0/SYSMON7_GEN.XADC0]

##############################
# LOCATION CONSTRAINTS 
##############################

### MMCMs ###
# We need to put the ADCDAQ PLL in the same bank as the BUFR that drives it (Bank 13)
#set_property LOC MMCME2_ADV_X0Y3 [get_cells {chfpga0/ADCGEN[0].ADCDAQ0/IMPL.USEPLL.PLL0/U0/mmcm_adv_inst}]
# The Channelizer MMCM is driven directly (no BUFG) by both the ADCDAQ MMCM. The MMCM must be adjacent, but on a half that has enough BUFGs
set_property LOC MMCME2_ADV_X0Y4 [get_cells chfpga0/CLK0/chan_mmcm0]
# The system MMCM also drives the Channelizer MMCM, and also needs to be adjacent.
set_property LOC MMCME2_ADV_X0Y2 [get_cells chfpga0/CLK0/mmcm_adv_inst]

### REFCLK ###
# REFCLK is in bank 11, coming from a SRCC pins.
# IBUFGDS and IDELAY are automatically placed on that pad
# The BUFR must be in the same region
# set_property LOC BUFR_X0Y3 [get_cells {chfpga0/REFCLK0/FMCBUFR0}]; # Place REFCLK BUFR in same region as the pad.
# The BUFGMUX must be in the same half
set_property LOC BUFGCTRL_X0Y0 [get_cells chfpga0/REFCLK0/FMCBUFG0]

# CH2
# NOTE: It is assumed that the ADCDAQ logic is located in the same bank as the clock so it can be clocked out of the BUFR in that region
set_property LOC BUFR_X0Y4 [get_cells {chfpga0/ADCGEN[2].ADCDAQ0/IMPL.BUFRGEN[1].BUFRn}]
set_property LOC BUFR_X0Y8 [get_cells {chfpga0/ADCGEN[2].ADCDAQ0/IMPL.BUFRGEN[0].BUFRn}]

# CH3
# NOTE: It is assumed that the ADCDAQ logic is located in the same bank as the clock so it can be clocked out of the BUFR in that region
set_property LOC BUFR_X0Y5 [get_cells {chfpga0/ADCGEN[3].ADCDAQ0/IMPL.BUFRGEN[1].BUFRn}]
set_property LOC BUFR_X0Y9 [get_cells {chfpga0/ADCGEN[3].ADCDAQ0/IMPL.BUFRGEN[0].BUFRn}]

set_property LOC IDELAY_X0Y272 [get_cells {chfpga0/ADCGEN[9].ADCDAQ0/IMPL.CLKDLY0}]
set_property LOC BUFIO_X0Y20 [get_cells {chfpga0/ADCGEN[9].ADCDAQ0/IMPL.NOEXTCLK.BUFIOGEN[0].BUFIO0}]
set_property LOC ILOGIC_X0Y272 [get_cells {chfpga0/ADCGEN[9].ADCDAQ0/IMPL.IDDR_CLK}]
set_property PACKAGE_PIN G28 [get_ports fmcb_adc0_bdrp]
set_property LOC BUFR_X0Y22 [get_cells {chfpga0/ADCGEN[9].ADCDAQ0/IMPL.BUFRGEN[0].BUFRn}]

set_property LOC BUFIO_X0Y27 [get_cells {chfpga0/ADCGEN[14].ADCDAQ0/IMPL.NOEXTCLK.BUFIOGEN[1].BUFIO0}]

set_property LOC BUFIO_X0Y25 [get_cells {chfpga0/ADCGEN[15].ADCDAQ0/IMPL.NOEXTCLK.BUFIOGEN[0].BUFIO0}]



# ###################################
# # AREA Contraints
# ###################################
# create_pblock ANT0
# add_cells_to_pblock [get_pblocks ANT0] [get_cells -quiet [list {chfpga0/ANTGEN[0].ANTn/CTRL_ROUTER0} {chfpga0/ANTGEN[0].ANTn/IMPL.FFT0} {chfpga0/ANTGEN[0].ANTn/IMPL.FUNCGEN0} {chfpga0/ANTGEN[0].ANTn/IMPL.INJECT0} {chfpga0/ANTGEN[0].ANTn/IMPL.SRCSEL0}]]
# resize_pblock [get_pblocks ANT0] -add {SLICE_X8Y200:SLICE_X145Y224}
# resize_pblock [get_pblocks ANT0] -add {DSP48_X0Y80:DSP48_X5Y89}
# resize_pblock [get_pblocks ANT0] -add {RAMB18_X0Y80:RAMB18_X5Y89}
# resize_pblock [get_pblocks ANT0] -add {RAMB36_X0Y40:RAMB36_X5Y44}
# create_pblock ANT1
# add_cells_to_pblock [get_pblocks ANT1] [get_cells -quiet [list {chfpga0/ANTGEN[1].ANTn/CTRL_ROUTER0} {chfpga0/ANTGEN[1].ANTn/IMPL.FFT0} {chfpga0/ANTGEN[1].ANTn/IMPL.FUNCGEN0} {chfpga0/ANTGEN[1].ANTn/IMPL.INJECT0} {chfpga0/ANTGEN[1].ANTn/IMPL.SRCSEL0}]]
# resize_pblock [get_pblocks ANT1] -add {SLICE_X8Y225:SLICE_X145Y249}
# resize_pblock [get_pblocks ANT1] -add {DSP48_X0Y90:DSP48_X5Y99}
# resize_pblock [get_pblocks ANT1] -add {RAMB18_X0Y90:RAMB18_X5Y99}
# resize_pblock [get_pblocks ANT1] -add {RAMB36_X0Y45:RAMB36_X5Y49}
# create_pblock ANT2
# add_cells_to_pblock [get_pblocks ANT2] [get_cells -quiet [list {chfpga0/ANTGEN[2].ANTn/CTRL_ROUTER0} {chfpga0/ANTGEN[2].ANTn/IMPL.FFT0} {chfpga0/ANTGEN[2].ANTn/IMPL.FUNCGEN0} {chfpga0/ANTGEN[2].ANTn/IMPL.INJECT0} {chfpga0/ANTGEN[2].ANTn/IMPL.SRCSEL0}]]
# resize_pblock [get_pblocks ANT2] -add {SLICE_X8Y250:SLICE_X145Y274}
# resize_pblock [get_pblocks ANT2] -add {DSP48_X0Y100:DSP48_X5Y109}
# resize_pblock [get_pblocks ANT2] -add {RAMB18_X0Y100:RAMB18_X5Y109}
# resize_pblock [get_pblocks ANT2] -add {RAMB36_X0Y50:RAMB36_X5Y54}
# create_pblock ANT3
# add_cells_to_pblock [get_pblocks ANT3] [get_cells -quiet [list {chfpga0/ANTGEN[3].ANTn/CTRL_ROUTER0} {chfpga0/ANTGEN[3].ANTn/IMPL.FFT0} {chfpga0/ANTGEN[3].ANTn/IMPL.FUNCGEN0} {chfpga0/ANTGEN[3].ANTn/IMPL.INJECT0} {chfpga0/ANTGEN[3].ANTn/IMPL.SRCSEL0}]]
# resize_pblock [get_pblocks ANT3] -add {SLICE_X8Y275:SLICE_X145Y299}
# resize_pblock [get_pblocks ANT3] -add {DSP48_X0Y110:DSP48_X5Y119}
# resize_pblock [get_pblocks ANT3] -add {RAMB18_X0Y110:RAMB18_X5Y119}
# resize_pblock [get_pblocks ANT3] -add {RAMB36_X0Y55:RAMB36_X5Y59}
# #add_cells_to_pblock [get_pblocks ANT4] [get_cells  [list {chfpga0/ANTGEN[4].ANTn/IMPL.FFT0}]]
# #add_cells_to_pblock [get_pblocks ANT4_FE] [get_cells  [list {chfpga0/ANTGEN[4].ANTn/IMPL.FFT0/FFT_GEN.FFT0/pfb_fir_real1_8f5364a5e8}]]
# create_pblock ANT5
# add_cells_to_pblock [get_pblocks ANT5] [get_cells -quiet [list {chfpga0/ANTGEN[5].ANTn/CTRL_ROUTER0} {chfpga0/ANTGEN[5].ANTn/IMPL.FFT0} {chfpga0/ANTGEN[5].ANTn/IMPL.FUNCGEN0} {chfpga0/ANTGEN[5].ANTn/IMPL.INJECT0} {chfpga0/ANTGEN[5].ANTn/IMPL.SRCSEL0}]]
# resize_pblock [get_pblocks ANT5] -add {SLICE_X8Y25:SLICE_X141Y49}
# resize_pblock [get_pblocks ANT5] -add {DSP48_X0Y10:DSP48_X5Y19}
# resize_pblock [get_pblocks ANT5] -add {RAMB18_X0Y10:RAMB18_X5Y19}
# resize_pblock [get_pblocks ANT5] -add {RAMB36_X0Y5:RAMB36_X5Y9}
# create_pblock ANT6
# add_cells_to_pblock [get_pblocks ANT6] [get_cells -quiet [list {chfpga0/ANTGEN[6].ANTn/CTRL_ROUTER0} {chfpga0/ANTGEN[6].ANTn/IMPL.FFT0} {chfpga0/ANTGEN[6].ANTn/IMPL.FUNCGEN0} {chfpga0/ANTGEN[6].ANTn/IMPL.INJECT0} {chfpga0/ANTGEN[6].ANTn/IMPL.SRCSEL0}]]
# resize_pblock [get_pblocks ANT6] -add {SLICE_X8Y300:SLICE_X145Y324}
# resize_pblock [get_pblocks ANT6] -add {DSP48_X0Y120:DSP48_X5Y129}
# resize_pblock [get_pblocks ANT6] -add {RAMB18_X0Y120:RAMB18_X5Y129}
# resize_pblock [get_pblocks ANT6] -add {RAMB36_X0Y60:RAMB36_X5Y64}
# create_pblock ANT7
# add_cells_to_pblock [get_pblocks ANT7] [get_cells -quiet [list {chfpga0/ANTGEN[7].ANTn/CTRL_ROUTER0} {chfpga0/ANTGEN[7].ANTn/IMPL.FFT0} {chfpga0/ANTGEN[7].ANTn/IMPL.FUNCGEN0} {chfpga0/ANTGEN[7].ANTn/IMPL.INJECT0} {chfpga0/ANTGEN[7].ANTn/IMPL.SRCSEL0}]]
# resize_pblock [get_pblocks ANT7] -add {SLICE_X8Y325:SLICE_X145Y349}
# resize_pblock [get_pblocks ANT7] -add {DSP48_X0Y130:DSP48_X5Y139}
# resize_pblock [get_pblocks ANT7] -add {RAMB18_X0Y130:RAMB18_X5Y139}
# resize_pblock [get_pblocks ANT7] -add {RAMB36_X0Y65:RAMB36_X5Y69}
# create_pblock CORR0
# add_cells_to_pblock [get_pblocks CORR0] [get_cells -quiet [list {chfpga0/CORRGEN[0].CORBLK0}]]
# resize_pblock [get_pblocks CORR0] -add {SLICE_X66Y50:SLICE_X153Y74}
# resize_pblock [get_pblocks CORR0] -add {DSP48_X3Y20:DSP48_X5Y29}
# resize_pblock [get_pblocks CORR0] -add {RAMB18_X3Y20:RAMB18_X6Y29}
# resize_pblock [get_pblocks CORR0] -add {RAMB36_X3Y10:RAMB36_X6Y14}
# #add_cells_to_pblock [get_pblocks CORR0] [get_cells -quiet [list {chfpga0/CORRGEN[0].CORBLK0/CORR_RESET_REG} {chfpga0/CORRGEN[0].CORBLK0/IMPL.ACC0} {chfpga0/CORRGEN[0].CORBLK0/VCC} {chfpga0/CORRGEN[0].CORBLK0/IMPL.XMUL0} {chfpga0/CORRGEN[0].CORBLK0/CTRL_ROUTER0} {chfpga0/CORRGEN[0].CORBLK0/GND} {chfpga0/CORRGEN[0].CORBLK0/IMPL.CH_DIST0}]]
# create_pblock PHY
# add_cells_to_pblock [get_pblocks PHY] [get_cells -quiet [list chfpga0/UDP_PHY0]]
# resize_pblock [get_pblocks PHY] -add {SLICE_X0Y150:SLICE_X11Y199}
# resize_pblock [get_pblocks PHY] -add {RAMB18_X0Y60:RAMB18_X0Y79}
# resize_pblock [get_pblocks PHY] -add {RAMB36_X0Y30:RAMB36_X0Y39}
# create_pblock I2C
# add_cells_to_pblock [get_pblocks I2C] [get_cells -quiet [list chfpga0/I2C0]]
# resize_pblock [get_pblocks I2C] -add {SLICE_X0Y50:SLICE_X11Y99}
# create_pblock SPI
# add_cells_to_pblock [get_pblocks SPI] [get_cells -quiet [list chfpga0/SPI0]]
# resize_pblock [get_pblocks SPI] -add {SLICE_X0Y100:SLICE_X7Y149}
# create_pblock ADCDAQ0
# add_cells_to_pblock [get_pblocks ADCDAQ0] [get_cells -quiet [list {chfpga0/ANTGEN[0].ADCDAQ0}]]
# resize_pblock [get_pblocks ADCDAQ0] -add {SLICE_X0Y200:SLICE_X7Y224}
# resize_pblock [get_pblocks ADCDAQ0] -add {RAMB18_X0Y80:RAMB18_X0Y89}
# resize_pblock [get_pblocks ADCDAQ0] -add {RAMB36_X0Y40:RAMB36_X0Y44}
# create_pblock ADCDAQ1
# resize_pblock [get_pblocks ADCDAQ1] -add {SLICE_X0Y225:SLICE_X7Y249}
# resize_pblock [get_pblocks ADCDAQ1] -add {RAMB18_X0Y90:RAMB18_X0Y99}
# resize_pblock [get_pblocks ADCDAQ1] -add {RAMB36_X0Y45:RAMB36_X0Y49}
# create_pblock ADCDAQ2
# add_cells_to_pblock [get_pblocks ADCDAQ2] [get_cells -quiet [list {chfpga0/ANTGEN[2].ADCDAQ0}]]
# resize_pblock [get_pblocks ADCDAQ2] -add {SLICE_X0Y250:SLICE_X7Y274}
# resize_pblock [get_pblocks ADCDAQ2] -add {RAMB18_X0Y100:RAMB18_X0Y109}
# resize_pblock [get_pblocks ADCDAQ2] -add {RAMB36_X0Y50:RAMB36_X0Y54}
# create_pblock ADCDAQ3
# add_cells_to_pblock [get_pblocks ADCDAQ3] [get_cells -quiet [list {chfpga0/ANTGEN[3].ADCDAQ0}]]
# resize_pblock [get_pblocks ADCDAQ3] -add {SLICE_X0Y275:SLICE_X7Y298}
# resize_pblock [get_pblocks ADCDAQ3] -add {RAMB18_X0Y110:RAMB18_X0Y117}
# resize_pblock [get_pblocks ADCDAQ3] -add {RAMB36_X0Y55:RAMB36_X0Y58}
# create_pblock ADCDAQ4
# add_cells_to_pblock [get_pblocks ADCDAQ4] [get_cells -quiet [list {chfpga0/ANTGEN[4].ADCDAQ0}]]
# resize_pblock [get_pblocks ADCDAQ4] -add {SLICE_X0Y0:SLICE_X7Y24}
# resize_pblock [get_pblocks ADCDAQ4] -add {RAMB18_X0Y0:RAMB18_X0Y9}
# resize_pblock [get_pblocks ADCDAQ4] -add {RAMB36_X0Y0:RAMB36_X0Y4}
# create_pblock ADCDAQ5
# add_cells_to_pblock [get_pblocks ADCDAQ5] [get_cells -quiet [list {chfpga0/ANTGEN[5].ADCDAQ0}]]
# resize_pblock [get_pblocks ADCDAQ5] -add {SLICE_X0Y25:SLICE_X7Y49}
# resize_pblock [get_pblocks ADCDAQ5] -add {RAMB18_X0Y10:RAMB18_X0Y19}
# resize_pblock [get_pblocks ADCDAQ5] -add {RAMB36_X0Y5:RAMB36_X0Y9}
# create_pblock ADCDAQ6
# add_cells_to_pblock [get_pblocks ADCDAQ6] [get_cells -quiet [list {chfpga0/ANTGEN[6].ADCDAQ0}]]
# resize_pblock [get_pblocks ADCDAQ6] -add {SLICE_X0Y300:SLICE_X7Y324}
# resize_pblock [get_pblocks ADCDAQ6] -add {RAMB18_X0Y120:RAMB18_X0Y129}
# resize_pblock [get_pblocks ADCDAQ6] -add {RAMB36_X0Y60:RAMB36_X0Y64}
# create_pblock ADCDAQ7
# add_cells_to_pblock [get_pblocks ADCDAQ7] [get_cells -quiet [list {chfpga0/ANTGEN[7].ADCDAQ0}]]
# resize_pblock [get_pblocks ADCDAQ7] -add {SLICE_X0Y325:SLICE_X7Y349}
# resize_pblock [get_pblocks ADCDAQ7] -add {RAMB18_X0Y130:RAMB18_X0Y139}
# resize_pblock [get_pblocks ADCDAQ7] -add {RAMB36_X0Y65:RAMB36_X0Y69}
# create_pblock ANT4
# add_cells_to_pblock [get_pblocks ANT4] [get_cells -quiet [list {chfpga0/ANTGEN[4].ANTn/CTRL_ROUTER0}]]
# resize_pblock [get_pblocks ANT4] -add {SLICE_X42Y0:SLICE_X135Y24}
# resize_pblock [get_pblocks ANT4] -add {DSP48_X2Y0:DSP48_X5Y9}
# resize_pblock [get_pblocks ANT4] -add {RAMB18_X2Y0:RAMB18_X5Y9}
# resize_pblock [get_pblocks ANT4] -add {RAMB36_X2Y0:RAMB36_X5Y4}
# #add_cells_to_pblock [get_pblocks ANT4] [get_cells  [list {chfpga0/ANTGEN[4].ANTn/CTRL_ROUTER0} {chfpga0/ANTGEN[4].ANTn/IMPL.FFT0/FFT_GEN.FFT0}]]
# #This must come after ANT4
# create_pblock ANT4_FE
# add_cells_to_pblock [get_pblocks ANT4_FE] [get_cells -quiet [list {chfpga0/ANTGEN[4].ANTn/IMPL.FUNCGEN0} {chfpga0/ANTGEN[4].ANTn/IMPL.INJECT0} {chfpga0/ANTGEN[4].ANTn/IMPL.SRCSEL0}]]
# resize_pblock [get_pblocks ANT4_FE] -add {SLICE_X8Y0:SLICE_X41Y24}
# resize_pblock [get_pblocks ANT4_FE] -add {DSP48_X0Y0:DSP48_X1Y9}
# resize_pblock [get_pblocks ANT4_FE] -add {RAMB18_X0Y0:RAMB18_X1Y9}
# resize_pblock [get_pblocks ANT4_FE] -add {RAMB36_X0Y0:RAMB36_X1Y4}
# create_pblock ANT4_BE
# resize_pblock [get_pblocks ANT4_BE] -add {SLICE_X136Y0:SLICE_X141Y24}
#create_pblock NOC
#add_cells_to_pblock [get_pblocks NOC] [get_cells -hierarchical *TIMING_REG*]
#add_cells_to_pblock [get_pblocks NOC] [get_cells {chfpga0/ANTGEN[6].ANTn/IMPL.PROBER0 chfpga0/ANTGEN[6].ANTn/IMPL.SCALER0 chfpga0/ANTGEN[4].ANTn/IMPL.PROBER0 chfpga0/ANTGEN[4].ANTn/IMPL.SCALER0 chfpga0/ANTGEN[1].ANTn/IMPL.PROBER0 chfpga0/ANTGEN[1].ANTn/IMPL.SCALER0 chfpga0/ANTGEN[1].ADCDAQ0 chfpga0/ANTGEN[3].ANTn/IMPL.PROBER0 chfpga0/ANTGEN[3].ANTn/IMPL.SCALER0 chfpga0/ANTGEN[5].ANTn/IMPL.SCALER0 chfpga0/ANTGEN[5].ANTn/IMPL.PROBER0 chfpga0/CORRGEN[0].CORBLK0 chfpga0/ANTGEN[7].ANTn/IMPL.PROBER0 chfpga0/ANTGEN[7].ANTn/IMPL.SCALER0 chfpga0/ANTGEN[2].ANTn/IMPL.PROBER0 chfpga0/ANTGEN[2].ANTn/IMPL.SCALER0 chfpga0/ANTGEN[4].ANTn/IMPL.FFT0/FFT_GEN.FFT0}]
#resize_pblock [get_pblocks NOC] -add {CLOCKREGION_X0Y0:CLOCKREGION_X1Y6}
#add_cells_to_pblock [get_pblocks NOC] [get_cells -hierarchical *TIMING_REG*]
# Remove cells containing TIMING_REG in their name from all pblocks so they can be freely placed to meet timing
# The commands are automatically generated by the following script line:
#  foreach x [get_pblocks -of_objects [get_cells -match_style UCF *TIMING_REG*]] {puts "remove_cells_from_pblock -quiet $x \[get_cells -match_style UCF *TIMING_REG* -filter Pblock==$x\]"}
# Specific component LOC'ing
### ANT4 DSP LOC'ing
# set_property LOC DSP48_X2Y9 [get_cells {chfpga0/ANTGEN[4].ANTn/IMPL.FFT0/FFT_GEN.FFT0/fft_wideband_real_11fe8dc52f/fft_biplex_real_4x0_a6db7c2226/biplex_core_9fdf53fa96/fft_stage_3_96534c353a/butterfly_direct_50808961d0/twiddle_general_3mult_bb4dfd79c5/mult0/comp0.core_instance0/blk00000003}]
# set_property LOC DSP48_X2Y8 [get_cells {chfpga0/ANTGEN[4].ANTn/IMPL.FFT0/FFT_GEN.FFT0/fft_wideband_real_11fe8dc52f/fft_biplex_real_4x0_a6db7c2226/biplex_core_9fdf53fa96/fft_stage_3_96534c353a/butterfly_direct_50808961d0/twiddle_general_3mult_bb4dfd79c5/mult1/comp1.core_instance1/blk00000003}]
# set_property LOC DSP48_X2Y7 [get_cells {chfpga0/ANTGEN[4].ANTn/IMPL.FFT0/FFT_GEN.FFT0/fft_wideband_real_11fe8dc52f/fft_biplex_real_4x0_a6db7c2226/biplex_core_9fdf53fa96/fft_stage_3_96534c353a/butterfly_direct_50808961d0/twiddle_general_3mult_bb4dfd79c5/mult2/comp1.core_instance1/blk00000003}]
# set_property LOC DSP48_X2Y6 [get_cells {chfpga0/ANTGEN[4].ANTn/IMPL.FFT0/FFT_GEN.FFT0/fft_wideband_real_11fe8dc52f/fft_biplex_real_4x0_a6db7c2226/biplex_core_9fdf53fa96/fft_stage_4_d21032e16e/butterfly_direct_1fc1d2b049/twiddle_general_3mult_0689a61b43/mult0/comp0.core_instance0/blk00000003}]
# set_property LOC DSP48_X2Y5 [get_cells {chfpga0/ANTGEN[4].ANTn/IMPL.FFT0/FFT_GEN.FFT0/fft_wideband_real_11fe8dc52f/fft_biplex_real_4x0_a6db7c2226/biplex_core_9fdf53fa96/fft_stage_4_d21032e16e/butterfly_direct_1fc1d2b049/twiddle_general_3mult_0689a61b43/mult1/comp1.core_instance1/blk00000003}]
# set_property LOC DSP48_X2Y4 [get_cells {chfpga0/ANTGEN[4].ANTn/IMPL.FFT0/FFT_GEN.FFT0/fft_wideband_real_11fe8dc52f/fft_biplex_real_4x0_a6db7c2226/biplex_core_9fdf53fa96/fft_stage_4_d21032e16e/butterfly_direct_1fc1d2b049/twiddle_general_3mult_0689a61b43/mult2/comp1.core_instance1/blk00000003}]
# set_property LOC DSP48_X2Y3 [get_cells {chfpga0/ANTGEN[4].ANTn/IMPL.FFT0/FFT_GEN.FFT0/fft_wideband_real_11fe8dc52f/fft_biplex_real_4x0_a6db7c2226/biplex_core_9fdf53fa96/fft_stage_5_521e6eb210/butterfly_direct_c96c7425d3/twiddle_general_3mult_c41c62dfcf/mult0/comp0.core_instance0/blk00000003}]
# set_property LOC DSP48_X2Y2 [get_cells {chfpga0/ANTGEN[4].ANTn/IMPL.FFT0/FFT_GEN.FFT0/fft_wideband_real_11fe8dc52f/fft_biplex_real_4x0_a6db7c2226/biplex_core_9fdf53fa96/fft_stage_5_521e6eb210/butterfly_direct_c96c7425d3/twiddle_general_3mult_c41c62dfcf/mult1/comp1.core_instance1/blk00000003}]
# set_property LOC DSP48_X2Y1 [get_cells {chfpga0/ANTGEN[4].ANTn/IMPL.FFT0/FFT_GEN.FFT0/fft_wideband_real_11fe8dc52f/fft_biplex_real_4x0_a6db7c2226/biplex_core_9fdf53fa96/fft_stage_5_521e6eb210/butterfly_direct_c96c7425d3/twiddle_general_3mult_c41c62dfcf/mult2/comp1.core_instance1/blk00000003}]
# set_property LOC DSP48_X3Y1 [get_cells {chfpga0/ANTGEN[4].ANTn/IMPL.FFT0/FFT_GEN.FFT0/fft_wideband_real_11fe8dc52f/fft_biplex_real_4x0_a6db7c2226/biplex_core_9fdf53fa96/fft_stage_6_3f6b6d5ea5/butterfly_direct_0c0b0db8d3/twiddle_general_3mult_12e153c68e/mult0/comp0.core_instance0/blk00000003}]
# set_property LOC DSP48_X3Y2 [get_cells {chfpga0/ANTGEN[4].ANTn/IMPL.FFT0/FFT_GEN.FFT0/fft_wideband_real_11fe8dc52f/fft_biplex_real_4x0_a6db7c2226/biplex_core_9fdf53fa96/fft_stage_6_3f6b6d5ea5/butterfly_direct_0c0b0db8d3/twiddle_general_3mult_12e153c68e/mult1/comp1.core_instance1/blk00000003}]
# set_property LOC DSP48_X3Y3 [get_cells {chfpga0/ANTGEN[4].ANTn/IMPL.FFT0/FFT_GEN.FFT0/fft_wideband_real_11fe8dc52f/fft_biplex_real_4x0_a6db7c2226/biplex_core_9fdf53fa96/fft_stage_6_3f6b6d5ea5/butterfly_direct_0c0b0db8d3/twiddle_general_3mult_12e153c68e/mult2/comp1.core_instance1/blk00000003}]
# set_property LOC DSP48_X3Y4 [get_cells {chfpga0/ANTGEN[4].ANTn/IMPL.FFT0/FFT_GEN.FFT0/fft_wideband_real_11fe8dc52f/fft_biplex_real_4x0_a6db7c2226/biplex_core_9fdf53fa96/fft_stage_7_09edaf7a48/butterfly_direct_a14d5b8667/twiddle_general_3mult_4feca36b72/mult0/comp0.core_instance0/blk00000003}]
# set_property LOC DSP48_X3Y5 [get_cells {chfpga0/ANTGEN[4].ANTn/IMPL.FFT0/FFT_GEN.FFT0/fft_wideband_real_11fe8dc52f/fft_biplex_real_4x0_a6db7c2226/biplex_core_9fdf53fa96/fft_stage_7_09edaf7a48/butterfly_direct_a14d5b8667/twiddle_general_3mult_4feca36b72/mult1/comp1.core_instance1/blk00000003}]
# set_property LOC DSP48_X3Y6 [get_cells {chfpga0/ANTGEN[4].ANTn/IMPL.FFT0/FFT_GEN.FFT0/fft_wideband_real_11fe8dc52f/fft_biplex_real_4x0_a6db7c2226/biplex_core_9fdf53fa96/fft_stage_7_09edaf7a48/butterfly_direct_a14d5b8667/twiddle_general_3mult_4feca36b72/mult2/comp1.core_instance1/blk00000003}]
# set_property LOC DSP48_X3Y7 [get_cells {chfpga0/ANTGEN[4].ANTn/IMPL.FFT0/FFT_GEN.FFT0/fft_wideband_real_11fe8dc52f/fft_biplex_real_4x0_a6db7c2226/biplex_core_9fdf53fa96/fft_stage_8_12753ece67/butterfly_direct_b64b9dc4dd/twiddle_general_3mult_cad14affaf/mult0/comp0.core_instance0/blk00000003}]
# set_property LOC DSP48_X3Y8 [get_cells {chfpga0/ANTGEN[4].ANTn/IMPL.FFT0/FFT_GEN.FFT0/fft_wideband_real_11fe8dc52f/fft_biplex_real_4x0_a6db7c2226/biplex_core_9fdf53fa96/fft_stage_8_12753ece67/butterfly_direct_b64b9dc4dd/twiddle_general_3mult_cad14affaf/mult1/comp1.core_instance1/blk00000003}]
# set_property LOC DSP48_X3Y9 [get_cells {chfpga0/ANTGEN[4].ANTn/IMPL.FFT0/FFT_GEN.FFT0/fft_wideband_real_11fe8dc52f/fft_biplex_real_4x0_a6db7c2226/biplex_core_9fdf53fa96/fft_stage_8_12753ece67/butterfly_direct_b64b9dc4dd/twiddle_general_3mult_cad14affaf/mult2/comp1.core_instance1/blk00000003}]
# set_property LOC DSP48_X4Y9 [get_cells {chfpga0/ANTGEN[4].ANTn/IMPL.FFT0/FFT_GEN.FFT0/fft_wideband_real_11fe8dc52f/fft_biplex_real_4x0_a6db7c2226/biplex_core_9fdf53fa96/fft_stage_9_61cde768a9/butterfly_direct_bfe329cdbb/twiddle_general_3mult_82f62cbc05/mult0/comp0.core_instance0/blk00000003}]
# set_property LOC DSP48_X4Y8 [get_cells {chfpga0/ANTGEN[4].ANTn/IMPL.FFT0/FFT_GEN.FFT0/fft_wideband_real_11fe8dc52f/fft_biplex_real_4x0_a6db7c2226/biplex_core_9fdf53fa96/fft_stage_9_61cde768a9/butterfly_direct_bfe329cdbb/twiddle_general_3mult_82f62cbc05/mult1/comp1.core_instance1/blk00000003}]
# set_property LOC DSP48_X4Y7 [get_cells {chfpga0/ANTGEN[4].ANTn/IMPL.FFT0/FFT_GEN.FFT0/fft_wideband_real_11fe8dc52f/fft_biplex_real_4x0_a6db7c2226/biplex_core_9fdf53fa96/fft_stage_9_61cde768a9/butterfly_direct_bfe329cdbb/twiddle_general_3mult_82f62cbc05/mult2/comp1.core_instance1/blk00000003}]
# set_property LOC DSP48_X4Y6 [get_cells {chfpga0/ANTGEN[4].ANTn/IMPL.FFT0/FFT_GEN.FFT0/fft_wideband_real_11fe8dc52f/fft_direct_578bf29dcc/butterfly1_0_707d4af107/twiddle_general_3mult_2d7d51b9a9/mult0/comp0.core_instance0/blk00000003}]
# set_property LOC DSP48_X4Y5 [get_cells {chfpga0/ANTGEN[4].ANTn/IMPL.FFT0/FFT_GEN.FFT0/fft_wideband_real_11fe8dc52f/fft_direct_578bf29dcc/butterfly1_0_707d4af107/twiddle_general_3mult_2d7d51b9a9/mult1/comp1.core_instance1/blk00000003}]
# set_property LOC DSP48_X4Y4 [get_cells {chfpga0/ANTGEN[4].ANTn/IMPL.FFT0/FFT_GEN.FFT0/fft_wideband_real_11fe8dc52f/fft_direct_578bf29dcc/butterfly1_0_707d4af107/twiddle_general_3mult_2d7d51b9a9/mult2/comp1.core_instance1/blk00000003}]
# set_property LOC DSP48_X4Y3 [get_cells {chfpga0/ANTGEN[4].ANTn/IMPL.FFT0/FFT_GEN.FFT0/fft_wideband_real_11fe8dc52f/fft_direct_578bf29dcc/butterfly1_1_aa094e2b14/twiddle_general_3mult_d62f26f1ee/mult0/comp0.core_instance0/blk00000003}]
# set_property LOC DSP48_X4Y2 [get_cells {chfpga0/ANTGEN[4].ANTn/IMPL.FFT0/FFT_GEN.FFT0/fft_wideband_real_11fe8dc52f/fft_direct_578bf29dcc/butterfly1_1_aa094e2b14/twiddle_general_3mult_d62f26f1ee/mult1/comp1.core_instance1/blk00000003}]
# set_property LOC DSP48_X4Y1 [get_cells {chfpga0/ANTGEN[4].ANTn/IMPL.FFT0/FFT_GEN.FFT0/fft_wideband_real_11fe8dc52f/fft_direct_578bf29dcc/butterfly1_1_aa094e2b14/twiddle_general_3mult_d62f26f1ee/mult2/comp1.core_instance1/blk00000003}]
# set_property LOC DSP48_X5Y6 [get_cells {chfpga0/ANTGEN[4].ANTn/IMPL.FFT0/FFT_GEN.FFT0/fft_wideband_real_11fe8dc52f/fft_direct_578bf29dcc/butterfly2_0_bb9773f5f5/twiddle_general_3mult_8f71bd60be/mult0/comp0.core_instance0/blk00000003}]
# set_property LOC DSP48_X5Y5 [get_cells {chfpga0/ANTGEN[4].ANTn/IMPL.FFT0/FFT_GEN.FFT0/fft_wideband_real_11fe8dc52f/fft_direct_578bf29dcc/butterfly2_0_bb9773f5f5/twiddle_general_3mult_8f71bd60be/mult1/comp1.core_instance1/blk00000003}]
# set_property LOC DSP48_X5Y4 [get_cells {chfpga0/ANTGEN[4].ANTn/IMPL.FFT0/FFT_GEN.FFT0/fft_wideband_real_11fe8dc52f/fft_direct_578bf29dcc/butterfly2_0_bb9773f5f5/twiddle_general_3mult_8f71bd60be/mult2/comp1.core_instance1/blk00000003}]
# set_property LOC DSP48_X5Y3 [get_cells {chfpga0/ANTGEN[4].ANTn/IMPL.FFT0/FFT_GEN.FFT0/fft_wideband_real_11fe8dc52f/fft_direct_578bf29dcc/butterfly2_1_4559277e38/twiddle_general_3mult_f10710e567/mult0/comp0.core_instance0/blk00000003}]
# set_property LOC DSP48_X5Y2 [get_cells {chfpga0/ANTGEN[4].ANTn/IMPL.FFT0/FFT_GEN.FFT0/fft_wideband_real_11fe8dc52f/fft_direct_578bf29dcc/butterfly2_1_4559277e38/twiddle_general_3mult_f10710e567/mult1/comp1.core_instance1/blk00000003}]
# set_property LOC DSP48_X5Y1 [get_cells {chfpga0/ANTGEN[4].ANTn/IMPL.FFT0/FFT_GEN.FFT0/fft_wideband_real_11fe8dc52f/fft_direct_578bf29dcc/butterfly2_1_4559277e38/twiddle_general_3mult_f10710e567/mult2/comp1.core_instance1/blk00000003}]
# set_property LOC DCIRESET_X0Y0 [get_cells chfpga0/REFCLK0/DCIRESET0]
# #set_property LOC USR_ACCESS_X0Y0 [get_cells chfpga0/GPIO0/USR_ACCESS0]
# set_property LOC BUFR_X0Y23 [get_cells {chfpga0/ANTGEN[2].ADCDAQ0/IMPL.BUFRGEN[0].BUFRn}]
# set_property LOC BUFR_X0Y22 [get_cells {chfpga0/ANTGEN[3].ADCDAQ0/IMPL.BUFRGEN[0].BUFRn}]
# set_property LOC BUFR_X0Y1 [get_cells {chfpga0/ANTGEN[5].ADCDAQ0/IMPL.BUFRGEN[0].BUFRn}]
# set_property LOC BUFR_X0Y5 [get_cells {chfpga0/ANTGEN[5].ADCDAQ0/IMPL.BUFRGEN[1].BUFRn}]
# set_property DRIVE 4 [get_ports SPI_SCK]
# set_property SLEW SLOW [get_ports SPI_SCK]
# # Fix FIFO XDCs
# set_false_path -from [get_cells -hierarchical ngwrdrst.grst.rd_rst_reg*]
# set_false_path -from [get_cells -hierarchical ngwrdrst.grst.wr_rst_reg*]
# set_property LOC USR_ACCESS_X0Y0 [get_cells chfpga0/GPIO0/USRACCESS_7.USR_ACCESS0]
# set_property LOC XADC_X0Y0 [get_cells chfpga0/SYSMON0/SYSMON7_GEN.XADC0]
# set_default_switching_activity -toggle_rate 10.000 -type {clock}
# set_operating_conditions -board_layers 16+
# create_pblock CORR2
# add_cells_to_pblock [get_pblocks CORR2] [get_cells -quiet [list {chfpga0/CORRGEN[2].CORBLK0}]]
# resize_pblock [get_pblocks CORR2] -add {SLICE_X66Y100:SLICE_X153Y124}
# resize_pblock [get_pblocks CORR2] -add {DSP48_X3Y40:DSP48_X5Y49}
# resize_pblock [get_pblocks CORR2] -add {RAMB18_X3Y40:RAMB18_X6Y49}
# resize_pblock [get_pblocks CORR2] -add {RAMB36_X3Y20:RAMB36_X6Y24}
# create_pblock CORR3
# add_cells_to_pblock [get_pblocks CORR3] [get_cells -quiet [list {chfpga0/CORRGEN[3].CORBLK0}]]
# resize_pblock [get_pblocks CORR3] -add {SLICE_X66Y125:SLICE_X153Y149}
# resize_pblock [get_pblocks CORR3] -add {DSP48_X3Y50:DSP48_X5Y59}
# resize_pblock [get_pblocks CORR3] -add {RAMB18_X3Y50:RAMB18_X6Y59}
# resize_pblock [get_pblocks CORR3] -add {RAMB36_X3Y25:RAMB36_X6Y29}
# create_pblock CORR4
# add_cells_to_pblock [get_pblocks CORR4] [get_cells -quiet [list {chfpga0/CORRGEN[4].CORBLK0}]]
# resize_pblock [get_pblocks CORR4] -add {SLICE_X80Y150:SLICE_X125Y199}
# resize_pblock [get_pblocks CORR4] -add {DSP48_X3Y60:DSP48_X4Y79}
# resize_pblock [get_pblocks CORR4] -add {RAMB18_X3Y60:RAMB18_X4Y79}
# resize_pblock [get_pblocks CORR4] -add {RAMB36_X3Y30:RAMB36_X4Y39}
# create_pblock CORR5
# add_cells_to_pblock [get_pblocks CORR5] [get_cells -quiet [list {chfpga0/CORRGEN[5].CORBLK0}]]
# resize_pblock [get_pblocks CORR5] -add {SLICE_X12Y150:SLICE_X79Y199}
# resize_pblock [get_pblocks CORR5] -add {DSP48_X1Y60:DSP48_X2Y79}
# resize_pblock [get_pblocks CORR5] -add {RAMB18_X1Y60:RAMB18_X2Y79}
# resize_pblock [get_pblocks CORR5] -add {RAMB36_X1Y30:RAMB36_X2Y39}
# create_pblock CORR6
# add_cells_to_pblock [get_pblocks CORR6] [get_cells -quiet [list {chfpga0/CORRGEN[6].CORBLK0}]]
# resize_pblock [get_pblocks CORR6] -add {SLICE_X14Y50:SLICE_X63Y99}
# resize_pblock [get_pblocks CORR6] -add {DSP48_X1Y20:DSP48_X2Y39}
# resize_pblock [get_pblocks CORR6] -add {RAMB18_X1Y20:RAMB18_X2Y39}
# resize_pblock [get_pblocks CORR6] -add {RAMB36_X1Y10:RAMB36_X2Y19}
# create_pblock CORR7
# add_cells_to_pblock [get_pblocks CORR7] [get_cells -quiet [list {chfpga0/CORRGEN[7].CORBLK0}]]
# resize_pblock [get_pblocks CORR7] -add {SLICE_X8Y100:SLICE_X63Y149}
# resize_pblock [get_pblocks CORR7] -add {DSP48_X0Y40:DSP48_X2Y59}
# resize_pblock [get_pblocks CORR7] -add {RAMB18_X1Y40:RAMB18_X2Y59}
# resize_pblock [get_pblocks CORR7] -add {RAMB36_X1Y20:RAMB36_X2Y29}
# create_pblock CORR1
# add_cells_to_pblock [get_pblocks CORR1] [get_cells -quiet [list {chfpga0/CORRGEN[1].CORBLK0}]]
# resize_pblock [get_pblocks CORR1] -add {SLICE_X66Y75:SLICE_X153Y99}
# resize_pblock [get_pblocks CORR1] -add {DSP48_X3Y30:DSP48_X5Y39}
# resize_pblock [get_pblocks CORR1] -add {RAMB18_X3Y30:RAMB18_X6Y39}
# resize_pblock [get_pblocks CORR1] -add {RAMB36_X3Y15:RAMB36_X6Y19}
# set_property BITSTREAM.GENERAL.CRC Enable [current_design]
# set_property BITSTREAM.READBACK.READBACK true [current_design]
# set_property PACKAGE_PIN L7 [get_ports SFPCLK_QO_N]
# set_property PACKAGE_PIN L7 [get_ports SFPCLK_QO_N]


# create_pblock ANT0
# add_cells_to_pblock [get_pblocks ANT0] [get_cells -quiet [list {chfpga0/ANTGEN[0].ANTn}]]
# resize_pblock [get_pblocks ANT0] -add {SLICE_X36Y175:SLICE_X179Y199}
# resize_pblock [get_pblocks ANT0] -add {DSP48_X2Y70:DSP48_X10Y79}
# resize_pblock [get_pblocks ANT0] -add {RAMB18_X2Y70:RAMB18_X11Y79}
# resize_pblock [get_pblocks ANT0] -add {RAMB36_X2Y35:RAMB36_X11Y39}
# create_pblock ANT1
# add_cells_to_pblock [get_pblocks ANT1] [get_cells -quiet [list {chfpga0/ANTGEN[1].ANTn}]]
# resize_pblock [get_pblocks ANT1] -add {SLICE_X36Y150:SLICE_X179Y174}
# resize_pblock [get_pblocks ANT1] -add {DSP48_X2Y60:DSP48_X10Y69}
# resize_pblock [get_pblocks ANT1] -add {RAMB18_X2Y60:RAMB18_X11Y69}
# resize_pblock [get_pblocks ANT1] -add {RAMB36_X2Y30:RAMB36_X11Y34}


# create_pblock ANT2
# add_cells_to_pblock [get_pblocks ANT2] [get_cells -quiet [list {chfpga0/ANTGEN[2].ANTn}]]
# resize_pblock [get_pblocks ANT2] -add {SLICE_X34Y125:SLICE_X179Y149}
# resize_pblock [get_pblocks ANT2] -add {DSP48_X2Y50:DSP48_X10Y59}
# resize_pblock [get_pblocks ANT2] -add {RAMB18_X2Y50:RAMB18_X11Y59}
# resize_pblock [get_pblocks ANT2] -add {RAMB36_X2Y25:RAMB36_X11Y29}
# create_pblock ANT3
# add_cells_to_pblock [get_pblocks ANT3] [get_cells -quiet [list {chfpga0/ANTGEN[3].ANTn}]]
# resize_pblock [get_pblocks ANT3] -add {SLICE_X34Y100:SLICE_X179Y124}
# resize_pblock [get_pblocks ANT3] -add {DSP48_X2Y40:DSP48_X10Y49}
# resize_pblock [get_pblocks ANT3] -add {RAMB18_X2Y40:RAMB18_X11Y49}
# resize_pblock [get_pblocks ANT3] -add {RAMB36_X2Y20:RAMB36_X11Y24}
# create_pblock ANT4
# add_cells_to_pblock [get_pblocks ANT4] [get_cells -quiet [list {chfpga0/ANTGEN[4].ANTn}]]
# resize_pblock [get_pblocks ANT4] -add {SLICE_X34Y0:SLICE_X179Y24}
# resize_pblock [get_pblocks ANT4] -add {DSP48_X2Y0:DSP48_X10Y9}
# resize_pblock [get_pblocks ANT4] -add {RAMB18_X2Y0:RAMB18_X11Y9}
# resize_pblock [get_pblocks ANT4] -add {RAMB36_X2Y0:RAMB36_X11Y4}
# create_pblock ANT5
# add_cells_to_pblock [get_pblocks ANT5] [get_cells -quiet [list {chfpga0/ANTGEN[5].ANTn}]]
# resize_pblock [get_pblocks ANT5] -add {SLICE_X32Y25:SLICE_X179Y49}
# resize_pblock [get_pblocks ANT5] -add {DSP48_X2Y10:DSP48_X10Y19}
# resize_pblock [get_pblocks ANT5] -add {RAMB18_X2Y10:RAMB18_X11Y19}
# resize_pblock [get_pblocks ANT5] -add {RAMB36_X2Y5:RAMB36_X11Y9}
# create_pblock ANT6
# add_cells_to_pblock [get_pblocks ANT6] [get_cells -quiet [list {chfpga0/ANTGEN[6].ANTn}]]
# resize_pblock [get_pblocks ANT6] -add {SLICE_X32Y50:SLICE_X179Y74}
# resize_pblock [get_pblocks ANT6] -add {DSP48_X2Y20:DSP48_X10Y29}
# resize_pblock [get_pblocks ANT6] -add {RAMB18_X2Y20:RAMB18_X11Y29}
# resize_pblock [get_pblocks ANT6] -add {RAMB36_X2Y10:RAMB36_X11Y14}
# create_pblock ANT7
# add_cells_to_pblock [get_pblocks ANT7] [get_cells -quiet [list {chfpga0/ANTGEN[7].ANTn}]]
# resize_pblock [get_pblocks ANT7] -add {SLICE_X32Y75:SLICE_X179Y99}
# resize_pblock [get_pblocks ANT7] -add {DSP48_X2Y30:DSP48_X10Y39}
# resize_pblock [get_pblocks ANT7] -add {RAMB18_X2Y30:RAMB18_X11Y39}
# resize_pblock [get_pblocks ANT7] -add {RAMB36_X2Y15:RAMB36_X11Y19}

# create_pblock ANT8
# add_cells_to_pblock [get_pblocks ANT8] [get_cells -quiet [list {chfpga0/ANTGEN[8].ANTn}]]
# resize_pblock [get_pblocks ANT8] -add {SLICE_X36Y275:SLICE_X179Y299}
# resize_pblock [get_pblocks ANT8] -add {DSP48_X2Y110:DSP48_X10Y119}
# resize_pblock [get_pblocks ANT8] -add {RAMB18_X2Y110:RAMB18_X11Y119}
# resize_pblock [get_pblocks ANT8] -add {RAMB36_X2Y55:RAMB36_X11Y59}
# create_pblock ANT12
# add_cells_to_pblock [get_pblocks ANT12] [get_cells -quiet [list {chfpga0/ANTGEN[12].ANTn}]]
# resize_pblock [get_pblocks ANT12] -add {SLICE_X36Y200:SLICE_X183Y224}
# resize_pblock [get_pblocks ANT12] -add {DSP48_X2Y80:DSP48_X11Y89}
# resize_pblock [get_pblocks ANT12] -add {RAMB18_X2Y80:RAMB18_X10Y89}
# resize_pblock [get_pblocks ANT12] -add {RAMB36_X2Y40:RAMB36_X10Y44}
# create_pblock ANT14
# add_cells_to_pblock [get_pblocks ANT14] [get_cells -quiet [list {chfpga0/ANTGEN[14].ANTn}]]
# resize_pblock [get_pblocks ANT14] -add {SLICE_X36Y375:SLICE_X175Y399}
# resize_pblock [get_pblocks ANT14] -add {DSP48_X2Y150:DSP48_X10Y159}
# resize_pblock [get_pblocks ANT14] -add {RAMB18_X2Y150:RAMB18_X10Y159}
# resize_pblock [get_pblocks ANT14] -add {RAMB36_X2Y75:RAMB36_X10Y79}
# create_pblock ANT15
# add_cells_to_pblock [get_pblocks ANT15] [get_cells -quiet [list {chfpga0/ANTGEN[15].ANTn}]]
# resize_pblock [get_pblocks ANT15] -add {SLICE_X36Y350:SLICE_X175Y374}
# resize_pblock [get_pblocks ANT15] -add {DSP48_X2Y140:DSP48_X10Y149}
# resize_pblock [get_pblocks ANT15] -add {RAMB18_X2Y140:RAMB18_X10Y149}
# resize_pblock [get_pblocks ANT15] -add {RAMB36_X2Y70:RAMB36_X10Y74}
# create_pblock ANT11
# add_cells_to_pblock [get_pblocks ANT11] [get_cells -quiet [list {chfpga0/ANTGEN[11].ANTn}]]
# resize_pblock [get_pblocks ANT11] -add {SLICE_X36Y325:SLICE_X175Y349}
# resize_pblock [get_pblocks ANT11] -add {DSP48_X2Y130:DSP48_X10Y139}
# resize_pblock [get_pblocks ANT11] -add {RAMB18_X2Y130:RAMB18_X10Y139}
# resize_pblock [get_pblocks ANT11] -add {RAMB36_X2Y65:RAMB36_X10Y69}
# create_pblock ANT10
# add_cells_to_pblock [get_pblocks ANT10] [get_cells -quiet [list {chfpga0/ANTGEN[10].ANTn}]]
# resize_pblock [get_pblocks ANT10] -add {SLICE_X36Y300:SLICE_X179Y324}
# resize_pblock [get_pblocks ANT10] -add {DSP48_X2Y120:DSP48_X10Y129}
# resize_pblock [get_pblocks ANT10] -add {RAMB18_X2Y120:RAMB18_X11Y129}
# resize_pblock [get_pblocks ANT10] -add {RAMB36_X2Y60:RAMB36_X11Y64}
# create_pblock ANT9
# add_cells_to_pblock [get_pblocks ANT9] [get_cells -quiet [list {chfpga0/ANTGEN[9].ANTn}]]
# resize_pblock [get_pblocks ANT9] -add {SLICE_X34Y250:SLICE_X179Y274}
# resize_pblock [get_pblocks ANT9] -add {DSP48_X2Y100:DSP48_X10Y109}
# resize_pblock [get_pblocks ANT9] -add {RAMB18_X2Y100:RAMB18_X11Y109}
# resize_pblock [get_pblocks ANT9] -add {RAMB36_X2Y50:RAMB36_X11Y54}
# create_pblock ANT13
# add_cells_to_pblock [get_pblocks ANT13] [get_cells -quiet [list {chfpga0/ANTGEN[13].ANTn}]]
# resize_pblock [get_pblocks ANT13] -add {SLICE_X36Y225:SLICE_X183Y249}
# resize_pblock [get_pblocks ANT13] -add {DSP48_X2Y90:DSP48_X11Y99}
# resize_pblock [get_pblocks ANT13] -add {RAMB18_X2Y90:RAMB18_X11Y99}
# resize_pblock [get_pblocks ANT13] -add {RAMB36_X2Y45:RAMB36_X11Y49}

set_property LOC DNA_PORT_X0Y0 [get_cells chfpga0/GPIO0/dna0]

