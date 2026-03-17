############################################################################
##
##   CRS Common Physical constraints
##
############################################################################

set_property BITSTREAM.CONFIG.USR_ACCESS TIMESTAMP [current_design]

set_operating_conditions -ambient_temp 23.0
set_operating_conditions -board large
set_operating_conditions -heatsink high


# Frequency counter
# ----------------
# Constrain the frequency counter clock. The clock frequency on this net is 1/2 if the measured clock source
# correlator clock is not interacting with other clocks
# set_clock_groups -name CORR_CLK_GROUP -asynchronous -group [get_clocks -include_generated_clocks CORR_CLK_NOBUF]



# CLK10 SMA: 10 MHz clock signal (copy fed to the HMC7044 input)
set_property PACKAGE_PIN J11 [get_ports sma_clk10_p]
# set_property IOSTANDARD DIFF_SSTL18_I_DCI [get_ports sma_clk10_p]
# set_property DQS_BIAS TRUE [get_ports sma_clk10_p]
set_property IOSTANDARD LVDS [get_ports sma_clk10_p]
set_property DIFF_TERM_ADV TERM_100 [get_ports sma_clk10_p]

###############################################################
# Primary clocks from AD9574 (Always present, non-programmable)
###############################################################
# # Fixed 156.25 MHz


# GTY reference clock MGTREFCLK0, 156.25 MHz from fixed PLL, Bank 131
# Corner-turn engine GTY reference clock
set_property PACKAGE_PIN P31 [get_ports {bp_shuffle_refclk_p[0]}]

# GTY reference clock MGTREFCLK0, 156.25 MHz from fixed PLL, Bank 129
# Is used for either:
#  - 100G interface reference clock
#  - SFP/ corner-turn reference clock
# See config-specific physical constraint file fro pin assignment


##########################################################################
# Secondary clocks from HMC7044 PLL (Programmable, not defined at powerup)
##########################################################################
# DAC and ADC reference clock (programmable, fixed connections).
# set_property PACKAGE_PIN N5      [get_ports {rf_clk_p229}] ; # DAC_CLK_P_230
# set_property PACKAGE_PIN AF5      [get_ports {rf_clk_p224}] ; # ADC_CLK_P_224
# set_property PACKAGE_PIN AD5      [get_ports {rf_clk_p225}] ; # ADC_CLK_P_225
# set_property PACKAGE_PIN AB5      [get_ports {rf_clk_p226}] ; # ADC_CLK_P_226
# set_property PACKAGE_PIN Y5      [get_ports {rf_clk_p227}] ; # ADC_CLK_P_227

# # GTY clock, (programmable)
# set_property PACKAGE_PIN AA33      [get_ports {gty_clk0_p128}] ; # GTY Bank  128, REFCLK0
# create_clock -name GTY_P128 -period 125MHz [get_ports {gty_clk0_p128}]
# # GTY clock, 125 MHz
# set_property PACKAGE_PIN U33      [get_ports {gty_clk0_p130}] ; # GTY Bank  130, REFCLK0
# create_clock -name GTY_P130 -period 125MHz [get_ports {gty_clk0_p130}]

# Output from the HMC7044 PLL1  (50 MHz, always phase-aligned with the SMA or BP 10 MHz reference clock when present)
set_property PACKAGE_PIN J19 [get_ports pll_oscout_p]
set_property IOSTANDARD LVDS [get_ports pll_oscout_p]
set_property DIFF_TERM_ADV TERM_100 [get_ports pll_oscout_p]

# PLL Sync control line, synchronus to OSCOUT
set_property PACKAGE_PIN D19 [get_ports pll_sync]
set_property IOSTANDARD LVCMOS18 [get_ports pll_sync]
set_property SLEW FAST [get_ports pll_sync]
set_property DRIVE 12 [get_ports pll_sync]

# PL_CLK (Bank 69), Fabric signal processing word clock (programmable, must be ADC sampling freq / 8 samples/word)
# 3000 MSPS/ 8 = 375 MHz
set_property PACKAGE_PIN G17 [get_ports plclk_p]
set_property IOSTANDARD LVDS [get_ports plclk_p]
set_property DIFF_TERM_ADV TERM_100 [get_ports plclk_p]

# SYSREF clock (Bank 69), 2.5 MHz, used to synchronize all the ADC logic. The equivalent of this signal (RF_SYSREF) also goes directly to the ADC/DACs bank.
# This signal is not treated as a clock, but rather a signal that is synchronized to PLCLK.
set_property PACKAGE_PIN H18 [get_ports pl_sysref_p]
set_property IOSTANDARD LVDS [get_ports pl_sysref_p]
set_property DIFF_TERM_ADV TERM_100 [get_ports pl_sysref_p]

# DDR4_CLK (Bank 67), used as a 10 MHz system clock
set_property PACKAGE_PIN H23 [get_ports sysclk_p]
set_property IOSTANDARD LVDS [get_ports sysclk_p]
set_property DIFF_TERM_ADV TERM_100 [get_ports sysclk_p]

# # Recovered clock output (not used)
# set_property PACKAGE_PIN C84     [get_ports {pl_recclk_p}]; # Bank  69 VCC1V8
# set_property IOSTANDARD  LVDS     [get_ports {pl_recclk_p}];

# Programmable PLL SYNC input



####################
# Backplane signals (DC coupled at the input buffer, AC coupled to the FPGA pins)
####################
# IRIG-B
# Fix: Was K19, moved to K22
set_property PACKAGE_PIN H22 [get_ports bp_irig_p]
set_property IOSTANDARD LVDS [get_ports bp_irig_p]

# Backplane 10 MHz reference clock (copy of the signal fed to the HMC7044)
set_property PACKAGE_PIN H17 [get_ports bp_clk10_p]
set_property IOSTANDARD LVDS [get_ports bp_clk10_p]
set_property DIFF_TERM_ADV TERM_100 [get_ports bp_clk10_p]

# set_property IOSTANDARD DIFF_SSTL18_I_DCI [get_ports bp_clk10_p]
# set_property DQS_BIAS TRUE [get_ports bp_clk10_p]

set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets clk10_ibufds1/O]


# # GPIO pins
# set_property PACKAGE_PIN C23     [get_ports {bp_gpio_p[1]}]; # Bank  57 VCC1V8
# set_property IOSTANDARD  LVDS     [get_ports {bp_gpio_p[1]}];

# set_property PACKAGE_PIN H22     [get_ports {bp_gpio_p[0]}]; # Bank  57 VCC1V8
# set_property IOSTANDARD  LVDS     [get_ports {bp_gpio_p[0]}];


########################
# Rear SMAs (DC coupled at the input buffer, AC coupled to the FPGA pins)
########################
# Warning: This block must be located after the SYS_CLK cock definition
# # IRIG-B signal
set_property PACKAGE_PIN K16 [get_ports sma_irig_p]
set_property IOSTANDARD LVDS [get_ports sma_irig_p]

# AUX SMA

# set_property PACKAGE_PIN H11     [get_ports {sma_aux_p}]; # Bank  57 VCC1V8
# AUX SMA Driver port, sma_aux_drv: Bank  87 VCC3V3
set_property PACKAGE_PIN E6 [get_ports sma_aux_drv]
set_property IOSTANDARD LVCMOS33 [get_ports sma_aux_drv]
set_property SLEW FAST [get_ports sma_aux_drv]
set_property DRIVE 16 [get_ports sma_aux_drv]

# #############################################
# # Buck SYNC signals
# #############################################

set_property IOSTANDARD LVCMOS33 [get_ports buck_sync_*]

set_property PACKAGE_PIN AP5 [get_ports buck_sync_5v0]
set_property PACKAGE_PIN AP6 [get_ports buck_sync_0v85]
set_property PACKAGE_PIN AR6 [get_ports buck_sync_3v3]
set_property PACKAGE_PIN AR7 [get_ports buck_sync_2v5]
set_property PACKAGE_PIN AV7 [get_ports buck_sync_1v8]
set_property PACKAGE_PIN AU7 [get_ports buck_sync_1v2a]
set_property PACKAGE_PIN AV8 [get_ports buck_sync_1v2b]
set_property PACKAGE_PIN AU8 [get_ports buck_sync_1v4]
set_property PACKAGE_PIN AT7 [get_ports buck_sync_bp]

# #################
#  SMP (on-board clip-on coax) connectors and testpoints
# These are located towards the front of the CRS, behind the DAC SMAs
# From edge towards center, Silk label & Refdes = SMP5, SMP6, SMP7, SMP8
# Corresponding FPGA Pins are: B10, B9, B8, B7
# Mapping is:
#   smp[0]: SMP6 (2nd from top)
#   smp[1]: SMP5 (1st from top)
#   smp[2]: SMP8 (4th from top)
#   smp[3]: SMP7 (3rd from top)
# #################
set_property PACKAGE_PIN B9 [get_ports {smp[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {smp[0]}]
set_property PACKAGE_PIN B10 [get_ports {smp[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {smp[1]}]
set_property PACKAGE_PIN B7 [get_ports {smp[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {smp[2]}]
set_property PACKAGE_PIN B8 [get_ports {smp[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {smp[3]}]
set_property SLEW FAST [get_ports {smp[*]}]
set_property DRIVE 16 [get_ports {smp[*]}]

# #############################################
# # LED signals
# #############################################

set_property IOSTANDARD LVCMOS33 [get_ports led7b*]

set_property PACKAGE_PIN A6 [get_ports {led7b[0]}]
set_property PACKAGE_PIN A9 [get_ports {led7b[1]}]
set_property PACKAGE_PIN A7 [get_ports {led7b[2]}]
set_property PACKAGE_PIN B5 [get_ports {led7b[3]}]
set_property PACKAGE_PIN C5 [get_ports {led7b[4]}]
set_property PACKAGE_PIN C6 [get_ports {led7b[5]}]
set_property PACKAGE_PIN A5 [get_ports {led7b[6]}]
set_property PACKAGE_PIN A10 [get_ports {led7b[7]}]

# #############################################
# # OLED Display signals
# #############################################


set_property -dict {IOSTANDARD LVCMOS33 DRIVE 4 SLEW SLOW} [get_ports fpc_d*]
set_property PACKAGE_PIN D8 [get_ports {fpc_d[0]}]
set_property PACKAGE_PIN D9 [get_ports {fpc_d[1]}]

# set_property PACKAGE_PIN F8       [get_ports {tp13}] ; # Bank  87 VCC3V3
# set_property IOSTANDARD  LVCMOS33 [get_ports {tp13}] ;

# -- QSFP Connector
# -- GTY QSFP28 ports - Bank 128
# Note: The pin assignments here overrides the pins assigned in the CMAC IP
#set_property PACKAGE_PIN Y35 [get_ports {qsfp_txp[0]}]
#set_property PACKAGE_PIN V35 [get_ports {qsfp_txp[1]}]
#set_property PACKAGE_PIN T35 [get_ports {qsfp_txp[2]}]
#set_property PACKAGE_PIN R33 [get_ports {qsfp_txp[3]}]

# -- SFP connectors
#set_property PACKAGE_PIN P35 [get_ports {sfp_txp[0]}]; # SFP1 - GTY_TX_P4 - TXP0 Bank 129 - GTYX0Y8 (CMAC X0Y0, CMAC X0Y1)
#set_property PACKAGE_PIN N33 [get_ports {sfp_txp[1]}]; # SFP2 - GTY_TX_P5 - TXP1 Bank 129 - GTYX0Y9 (CMAC X0Y0, CMAC X0Y1)
#set_property PACKAGE_PIN L33 [get_ports {sfp_txp[2]}]; # SFP3 - GTY_TX_P6 - TXP2 Bank 129 - GTYX0Y10 (CMAC X0Y0, CMAC X0Y1)
#set_property PACKAGE_PIN J33 [get_ports {sfp_txp[3]}]; # SFP4 - GTY_TX_P7 - TXP3 Bank 129 - GTYX0Y11 (CMAC X0Y0, CMAC X0Y1)
#set_property PACKAGE_PIN H31 [get_ports {sfp_txp[4]}]; # SFP5 - GTY_TX_P8 - TXP0 Bank 130 - GTYX0Y12 (CMAC X0Y1)
#set_property PACKAGE_PIN G33 [get_ports {sfp_txp[5]}]; # SFP6 - GTY_TX_P9 - TXP1 Bank 130 - GTYX0Y13 (CMAC X0Y1)

# -- Backplane high speed links
#set_property PACKAGE_PIN F31 [get_ports {bp_shuffle_txp[0]}]; # BP Lane 0 - GTY_TX_P10 - TXP2 Bank 130 - GTYX0Y14 (CMAC X0Y1)
#set_property PACKAGE_PIN E33 [get_ports {qsfp_txp[0]}]; # BP Lane 1 - GTY_TX_P11 - TXP3 Bank 130 - GTYX0Y15 (CMAC X0Y1)
#set_property PACKAGE_PIN D31 [get_ports {qsfp_txp[0]}]; # BP Lane 2 - GTY_TX_P12 - TXP0 Bank 131 - GTYX0Y16 (CMAC X0Y1)
#set_property PACKAGE_PIN C33 [get_ports {qsfp_txp[0]}]; # BP Lane 3 - GTY_TX_P13 - TXP1 Bank 131 - GTYX0Y17 (CMAC X0Y1)
#set_property PACKAGE_PIN B31 [get_ports {qsfp_txp[0]}]; # BP Lane 4 - GTY_TX_P14 - TXP2 Bank 131 - GTYX0Y18 (CMAC X0Y1)
#set_property PACKAGE_PIN A33 [get_ports {qsfp_txp[0]}]; # BP Lane 5 - GTY_TX_P15 - TXP3 Bank 131 - GTYX0Y19 (CMAC X0Y1)




# ignore timing between CLK200 and CORR_CLK  domains. This line has to be placed after we have defines the source clock for the two specified derived clocks
# set_false_path -from [get_clocks CLK200_MMCM_NOBUF] -to [get_clocks {CORR_CLK_NOBUF}]

###
# Debug core
###





########################################
# RESET
########################################
#set_property PACKAGE_PIN AF15     [get_ports "CPU_RESET"] ;# Bank  64 VCCO - VCC1V8   - IO_T2U_N12_64
#set_property IOSTANDARD  LVCMOS18 [get_ports "CPU_RESET"] ;# Bank  64 VCCO - VCC1V8   - IO_T2U_N12_64


########################################
########################################
# Floorplanning constraints
########################################
########################################

# NOTE: UCORR44 constraints are in crs_physical_constraints_ucorr44_*_LOCs.xdc 
# NOTE: CHAN and FFT constraints are in crs_physical_constraints_chan_LOCs.xdc and crs_physical_constraints_chord_fft_LOCs.xdc

############################################################################
# ADC
############################################################################

create_pblock ADC
add_cells_to_pblock [get_pblocks ADC] [get_cells -quiet [list zynq/usp_rf_data_converter_0]]
resize_pblock [get_pblocks ADC] -add {SLICE_X113Y60:SLICE_X118Y299}
set_property EXCLUDE_PLACEMENT 1 [get_pblocks ADC]

############################################################################
# SYSTEM
############################################################################

create_pblock SYSTEM
add_cells_to_pblock [get_pblocks SYSTEM] [get_cells -quiet [list chfpga0/clk0 chfpga0/bsb_master_blk.ctrl_master0 chfpga0/chan_router_blk.chan_router0 chfpga0/ct_clk_blk.ct_reset_cdc0 chfpga0/top_router_blk.top_router0]]
resize_pblock [get_pblocks SYSTEM] -add {SLICE_X113Y300:SLICE_X118Y419}
resize_pblock [get_pblocks SYSTEM] -add {DSP48E2_X22Y120:DSP48E2_X22Y167}
set_property IS_SOFT FALSE [get_pblocks SYSTEM]

############################################################################
# TCPIPE
############################################################################

create_pblock TCPIPE
add_cells_to_pblock [get_pblocks TCPIPE] [get_cells -quiet [list zynq/axi_dma_0 zynq/axi_dma_1 zynq/rst_ps8_0_96M zynq/smartconnect_0 zynq/xlconcat_0 zynq/zynq_ultra_ps_e_0]]
resize_pblock [get_pblocks TCPIPE] -add {SLICE_X22Y0:SLICE_X25Y179}
resize_pblock [get_pblocks TCPIPE] -add {BUFG_PS_X0Y0:BUFG_PS_X0Y71}
resize_pblock [get_pblocks TCPIPE] -add {DSP48E2_X2Y0:DSP48E2_X2Y71}
resize_pblock [get_pblocks TCPIPE] -add {RAMB18_X2Y18:RAMB18_X2Y23}
resize_pblock [get_pblocks TCPIPE] -add {RAMB36_X2Y9:RAMB36_X2Y11}
set_property IS_SOFT FALSE [get_pblocks TCPIPE]

############################################################################
# Debug core
############################################################################

create_pblock DEBUG
add_cells_to_pblock [get_pblocks DEBUG] [get_cells -quiet [list zynq/system_ila_0]]
resize_pblock [get_pblocks DEBUG] -add {SLICE_X0Y420:SLICE_X14Y479}
resize_pblock [get_pblocks DEBUG] -add {DSP48E2_X0Y168:DSP48E2_X0Y191}
resize_pblock [get_pblocks DEBUG] -add {PCIE4CE4_X0Y1:PCIE4CE4_X0Y1}
resize_pblock [get_pblocks DEBUG] -add {RAMB18_X1Y180:RAMB18_X1Y191 RAMB18_X0Y168:RAMB18_X0Y191}
resize_pblock [get_pblocks DEBUG] -add {RAMB36_X1Y90:RAMB36_X1Y95 RAMB36_X0Y84:RAMB36_X0Y95}
set_property IS_SOFT FALSE [get_pblocks DEBUG]

set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets smp_OBUF[3]]

############################################################################
# UCAP
############################################################################

create_pblock UCAP
add_cells_to_pblock [get_pblocks UCAP] [get_cells -quiet [list chfpga0/chan_array0/cap_gen.uram_case.ucap0]]
resize_pblock [get_pblocks UCAP] -add {SLICE_X15Y420:SLICE_X21Y479}
resize_pblock [get_pblocks UCAP] -add {DSP48E2_X1Y168:DSP48E2_X1Y191}
resize_pblock [get_pblocks UCAP] -add {RAMB18_X1Y168:RAMB18_X1Y179}
resize_pblock [get_pblocks UCAP] -add {URAM288_X0Y64:URAM288_X0Y79}
set_property EXCLUDE_PLACEMENT 1 [get_pblocks UCAP]


