############################################################################
##
##   ZCU111 Rev1.0 - Master XDC 05/30/2018
##
############################################################################

set_property BITSTREAM.CONFIG.USR_ACCESS TIMESTAMP [current_design]

# Frequency counter
# ----------------
# Constrain the frequency counter clock. The clock frequency on this net is 1/2 if the measured clock source
create_clock -period 3.200 -name FREQCTR_CLK [get_pins sifpga_crs_i/sifpga_crs_chfpga_0/U0/chfpga0/FREQ_CTR0/V6.SRCCLK0/O]
set_clock_groups -name FREQCTR_GROUP -asynchronous -group [get_clocks FREQCTR_CLK]


# correlator clock is not interacting with other clocks
# set_clock_groups -name CORR_CLK_GROUP -asynchronous -group [get_clocks -include_generated_clocks CORR_CLK_NOBUF]


####################
# Backplane signals
####################
# # IRIG-B
# set_property PACKAGE_PIN K19     [get_ports {bp_irig_p}]; # Bank  69 VCC1V8
# set_property IOSTANDARD  LVDS     [get_ports {bp_irig_p}];

# # Backplane clock (copy fed to the HMC7044)
# set_property PACKAGE_PIN H17     [get_ports {pl_bp_clk_10mhz_p}]; # Bank  69 VCC1V8
# set_property IOSTANDARD  LVDS     [get_ports {pl_bp_clk_10mhz_p}];
# create_clock -name PL_BP_CLK10 -period 10MHz [get_ports {pl_bp_clk_10mhz_p}]

# # GPIO pins
# set_property PACKAGE_PIN C23     [get_ports {bp_gpio_p[1]}]; # Bank  57 VCC1V8
# set_property IOSTANDARD  LVDS     [get_ports {bp_gpio_p[1]}];

# set_property PACKAGE_PIN H22     [get_ports {bp_gpio_p[0]}]; # Bank  57 VCC1V8
# set_property IOSTANDARD  LVDS     [get_ports {bp_gpio_p[0]}];


########################
# Rear SMAs (DC coupled)
########################
# # IRIG-B signal
# set_property PACKAGE_PIN K16     [get_ports {sma_irig_p}]; # Bank  69 VCC1V8
# set_property IOSTANDARD  LVDS     [get_ports {sma_irig_p}];
# # Aux signal
# set_property PACKAGE_PIN H11     [get_ports {sma_aux_p}]; # Bank  57 VCC1V8
# set_property IOSTANDARD  LVDS     [get_ports {sma_aux_p}];
# # 10 MHz clock signal (copy fed to the HMC7044 input)
# set_property PACKAGE_PIN J11     [get_ports {pl_sma_clk_10mhz_p}]; # Bank  57 VCC1V8
# set_property IOSTANDARD  LVDS     [get_ports {pl_sma_clk_10mhz_p}];
# create_clock -name PL_SMA_CLK10 -period 10MHz [get_ports {pl_sma_clk_10mhz_p}]

###############################################################
# Primary clocks from AD9574 (Always present, non-programmable)
###############################################################
# # Fixed 156.25 MHz
# set_property PACKAGE_PIN W33      [get_ports {gty_clk0_p129}] ; # GTY Bank 129, REFCLK0
# set_property PACKAGE_PIN P31      [get_ports {gty_clk0_p131}] ; # GTY Bank  131, REFCLK0
# create_clock -name GTY_P129 -period 156.25MHz [get_ports {gty_clk0_p129}]
# create_clock -name GTY_P131 -period 156.25MHz [get_ports {gty_clk0_p131}]

##########################################################################
# Secondary clocks from HMC7044 PLL (Programmable, not defined at powerup)
##########################################################################
# # Sync control line
# set_property PACKAGE_PIN D19       [get_ports {hmc7044_sync}] ; # Bank  69  VCC1V8
# set_property IOSTANDARD  LVCMOS18 [get_ports {hmc7044_sync}] ;# Bank  87 VCCO - VCC1V8   - IO_L2P_AD14P_87

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

# # Output from the HMC7044 PLL1  (50 MHz, always phase-aligned with the 10 MHz reference clock)
# set_property PACKAGE_PIN J19     [get_ports {oscout_p}]; # Bank  69 VCC1V8
# set_property IOSTANDARD  LVDS     [get_ports {oscout_p}];
# create_clock -name GTY_P130 -period 50MHz [get_ports {oscout_p}]

# PL_CLK (Bank 69), Fabric signal processing word clock (programmable, must be ADC sampling freq / 8 samples/word)
set_property PACKAGE_PIN G17 [get_ports {pl_clk_p[0]}]
set_property IOSTANDARD LVDS [get_ports {pl_clk_p[0]}]
set_property DIFF_TERM_ADV TERM_100 [get_ports {pl_clk_p[0]}]
create_clock -period 2.666 -name PL_CLK [get_ports pl_clk_p]

# SYSREF clock (Bank 69), 0.75 MHz, used to synchronize all the PLLs. A copy of this signal (RF_SYSREF) also goes to the ADC/DACs
set_property PACKAGE_PIN H18 [get_ports {clk10_clk_p[0]}]
set_property IOSTANDARD LVDS [get_ports {clk10_clk_p[0]}]
set_property DIFF_TERM_ADV TERM_100 [get_ports {clk10_clk_p[0]}]
create_clock -period 100.000 -name PL_SYSREF [get_ports clk10_clk_p]

# DDR4_CLK (Bank 67), used as a 250 MHz system clock
set_property PACKAGE_PIN H23 [get_ports {clk200_clk_p[0]}]
set_property IOSTANDARD LVDS [get_ports {clk200_clk_p[0]}]
set_property DIFF_TERM_ADV TERM_100 [get_ports {clk200_clk_p[0]}]
create_clock -period 4.000 -name CLK200_CLK [get_ports clk200_clk_p]

# # Recovered clock output (not used)
# set_property PACKAGE_PIN C84     [get_ports {pl_recclk_p}]; # Bank  69 VCC1V8
# set_property IOSTANDARD  LVDS     [get_ports {pl_recclk_p}];

# 100 MHz clock provided by the PS to the PL is not in phase with any other clock
set_clock_groups -name BSB_CLK_GROUP -asynchronous -group [get_clocks clk_pl_0]


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
# # SMP (on-board clip-on coax) connectors and testpoints
# #################
set_property PACKAGE_PIN B9 [get_ports {smp[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {smp[0]}]
set_property PACKAGE_PIN B10 [get_ports {smp[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {smp[1]}]
set_property PACKAGE_PIN B7 [get_ports {smp[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {smp[2]}]
set_property PACKAGE_PIN B8 [get_ports {smp[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {smp[3]}]


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


# set_property PACKAGE_PIN F8       [get_ports {tp13}] ; # Bank  87 VCC3V3
# set_property IOSTANDARD  LVCMOS33 [get_ports {tp13}] ;

# -- QSFP Connector
# -- GTY QSFP28 ports - Bank 128
# Note: The pin assignments here overrides the pins assigned in the CMAC IP
set_property PACKAGE_PIN Y35 [get_ports {qsfp_txp[0]}]
set_property PACKAGE_PIN V35 [get_ports {qsfp_txp[1]}]
set_property PACKAGE_PIN T35 [get_ports {qsfp_txp[2]}]
set_property PACKAGE_PIN R33 [get_ports {qsfp_txp[3]}]

# -- SFP connectors
#set_property PACKAGE_PIN P35 [get_ports {qsfp_txp[0]}]; # SFP1 - GTY_TX_P4 - TXP0 Bank 129 - GTYX0Y8 (CMAC X0Y0, CMAC X0Y1)
#set_property PACKAGE_PIN N33 [get_ports {qsfp_txp[1]}]; # SFP2 - GTY_TX_P5 - TXP1 Bank 129 - GTYX0Y9 (CMAC X0Y0, CMAC X0Y1)
#set_property PACKAGE_PIN L33 [get_ports {qsfp_txp[2]}]; # SFP3 - GTY_TX_P6 - TXP2 Bank 129 - GTYX0Y10 (CMAC X0Y0, CMAC X0Y1)
#set_property PACKAGE_PIN J33 [get_ports {qsfp_txp[3]}]; # SFP4 - GTY_TX_P7 - TXP3 Bank 129 - GTYX0Y11 (CMAC X0Y0, CMAC X0Y1)
#set_property PACKAGE_PIN H31 [get_ports {qsfp_txp[0]}]; # SFP5 - GTY_TX_P8 - TXP0 Bank 130 - GTYX0Y12 (CMAC X0Y1)
#set_property PACKAGE_PIN G33 [get_ports {qsfp_txp[0]}]; # SFP6 - GTY_TX_P9 - TXP1 Bank 130 - GTYX0Y13 (CMAC X0Y1)

# -- Backplane high speed links
#set_property PACKAGE_PIN F31 [get_ports {qsfp_txp[0]}]; # BP Lane 0 - GTY_TX_P10 - TXP2 Bank 130 - GTYX0Y14 (CMAC X0Y1)
#set_property PACKAGE_PIN E33 [get_ports {qsfp_txp[0]}]; # BP Lane 1 - GTY_TX_P11 - TXP3 Bank 130 - GTYX0Y15 (CMAC X0Y1)
#set_property PACKAGE_PIN D31 [get_ports {qsfp_txp[0]}]; # BP Lane 2 - GTY_TX_P12 - TXP0 Bank 131 - GTYX0Y16 (CMAC X0Y1)
#set_property PACKAGE_PIN C33 [get_ports {qsfp_txp[0]}]; # BP Lane 3 - GTY_TX_P13 - TXP1 Bank 131 - GTYX0Y17 (CMAC X0Y1)
#set_property PACKAGE_PIN B31 [get_ports {qsfp_txp[0]}]; # BP Lane 4 - GTY_TX_P14 - TXP2 Bank 131 - GTYX0Y18 (CMAC X0Y1)
#set_property PACKAGE_PIN A33 [get_ports {qsfp_txp[0]}]; # BP Lane 5 - GTY_TX_P15 - TXP3 Bank 131 - GTYX0Y19 (CMAC X0Y1)



# GTY reference clock, 156.25 MHz from fixed PLL, Bank 129
set_property PACKAGE_PIN W33 [get_ports clk156_p]

# ignore timing between CLK200 and CORR_CLK  domains. This line has to be placed after we have defines the source clock for the two specified derived clocks
# set_false_path -from [get_clocks CLK200_MMCM_NOBUF] -to [get_clocks {CORR_CLK_NOBUF}]




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



create_pblock CGE
add_cells_to_pblock [get_pblocks CGE] [get_cells -quiet [list sifpga_crs_i/sifpga_crs_chfpga_0/U0/chfpga0/CGE_GEN.cge0]]
resize_pblock [get_pblocks CGE] -add {SLICE_X5Y180:SLICE_X11Y239}
resize_pblock [get_pblocks CGE] -add {DSP48E2_X0Y72:DSP48E2_X0Y95}
resize_pblock [get_pblocks CGE] -add {RAMB18_X0Y72:RAMB18_X0Y95}
resize_pblock [get_pblocks CGE] -add {RAMB36_X0Y36:RAMB36_X0Y47}
set_property EXCLUDE_PLACEMENT 1 [get_pblocks CGE]
set_property IS_SOFT FALSE [get_pblocks CGE]




create_pblock UCORN
add_cells_to_pblock [get_pblocks UCORN] [get_cells -quiet [list sifpga_crs_i/sifpga_crs_chfpga_0/U0/chfpga0/crossbar0_gen.cburam_gen.uram0]]
resize_pblock [get_pblocks UCORN] -add {SLICE_X15Y180:SLICE_X19Y419 SLICE_X12Y180:SLICE_X14Y199}
resize_pblock [get_pblocks UCORN] -add {RAMB18_X1Y72:RAMB18_X1Y79}
resize_pblock [get_pblocks UCORN] -add {RAMB36_X1Y36:RAMB36_X1Y39}
resize_pblock [get_pblocks UCORN] -add {URAM288_X0Y0:URAM288_X0Y63}
set_property EXCLUDE_PLACEMENT 1 [get_pblocks UCORN]
set_property IS_SOFT FALSE [get_pblocks UCORN]

create_pblock CORR
resize_pblock [get_pblocks CORR] -add {SLICE_X22Y180:SLICE_X32Y479}
resize_pblock [get_pblocks CORR] -add {DSP48E2_X2Y72:DSP48E2_X4Y191}
resize_pblock [get_pblocks CORR] -add {RAMB18_X2Y72:RAMB18_X3Y191}
resize_pblock [get_pblocks CORR] -add {RAMB36_X2Y36:RAMB36_X3Y95}
set_property EXCLUDE_PLACEMENT 1 [get_pblocks CORR]
set_property IS_SOFT FALSE [get_pblocks CORR]
#add_cells_to_pblock [get_pblocks CORR] [get_cells -quiet [list sifpga_crs_i/sifpga_crs_chfpga_0/U0/chfpga0/CORRGEN.corr_array0]]


create_pblock ADC
add_cells_to_pblock [get_pblocks ADC] [get_cells -quiet [list sifpga_crs_i/usp_rf_data_converter_0]]
resize_pblock [get_pblocks ADC] -add {SLICE_X112Y0:SLICE_X118Y239}
resize_pblock [get_pblocks ADC] -add {DSP48E2_X22Y0:DSP48E2_X22Y95}
resize_pblock [get_pblocks ADC] -add {RAMB18_X11Y0:RAMB18_X11Y95}
resize_pblock [get_pblocks ADC] -add {RAMB36_X11Y0:RAMB36_X11Y47}
set_property EXCLUDE_PLACEMENT 1 [get_pblocks ADC]

# Modules are assigned to the SYSTEM PBLOCK by setting the TARGET_PBLOCK attribute to "SYSTEM" in VHDL
# Use this line to automatically pick the cells
# add_cells_to_pblock [get_pblocks SYSTEM] [get_cells * -hier -filter TARGET_PBLOCK==SYSTEM]

create_pblock SYSTEM
resize_pblock [get_pblocks SYSTEM] -add {CLOCKREGION_X1Y1:CLOCKREGION_X1Y1}
set_property EXCLUDE_PLACEMENT 1 [get_pblocks SYSTEM]




create_pblock UCAP
add_cells_to_pblock [get_pblocks UCAP] [get_cells -quiet [list sifpga_crs_i/sifpga_crs_chfpga_0/U0/chfpga0/cap_gen.ucap0]]
resize_pblock [get_pblocks UCAP] -add {SLICE_X15Y420:SLICE_X21Y479}
resize_pblock [get_pblocks UCAP] -add {DSP48E2_X1Y168:DSP48E2_X1Y191}
resize_pblock [get_pblocks UCAP] -add {URAM288_X0Y64:URAM288_X0Y79}
set_property EXCLUDE_PLACEMENT 1 [get_pblocks UCAP]


create_pblock CHAN0
add_cells_to_pblock [get_pblocks CHAN0] [get_cells -quiet [list {sifpga_crs_i/sifpga_crs_chfpga_0/U0/chfpga0/CHANGEN[0].CHANi}]]
resize_pblock [get_pblocks CHAN0] -add {SLICE_X24Y420:SLICE_X115Y479}
resize_pblock [get_pblocks CHAN0] -add {DSP48E2_X2Y168:DSP48E2_X22Y191}
resize_pblock [get_pblocks CHAN0] -add {RAMB18_X2Y168:RAMB18_X10Y191}
resize_pblock [get_pblocks CHAN0] -add {RAMB36_X2Y84:RAMB36_X10Y95}

create_pblock CHAN1
add_cells_to_pblock [get_pblocks CHAN1] [get_cells -quiet [list {sifpga_crs_i/sifpga_crs_chfpga_0/U0/chfpga0/CHANGEN[1].CHANi}]]
resize_pblock [get_pblocks CHAN1] -add {SLICE_X24Y360:SLICE_X118Y419}
resize_pblock [get_pblocks CHAN1] -add {DSP48E2_X2Y144:DSP48E2_X22Y167}
resize_pblock [get_pblocks CHAN1] -add {RAMB18_X2Y144:RAMB18_X11Y167}
resize_pblock [get_pblocks CHAN1] -add {RAMB36_X2Y72:RAMB36_X11Y83}
create_pblock CHAN2
add_cells_to_pblock [get_pblocks CHAN2] [get_cells -quiet [list {sifpga_crs_i/sifpga_crs_chfpga_0/U0/chfpga0/CHANGEN[2].CHANi}]]
resize_pblock [get_pblocks CHAN2] -add {SLICE_X24Y300:SLICE_X118Y360}
resize_pblock [get_pblocks CHAN2] -add {DSP48E2_X2Y120:DSP48E2_X22Y143}
resize_pblock [get_pblocks CHAN2] -add {RAMB18_X2Y120:RAMB18_X11Y143}
resize_pblock [get_pblocks CHAN2] -add {RAMB36_X2Y60:RAMB36_X11Y71}
create_pblock CHAN3
add_cells_to_pblock [get_pblocks CHAN3] [get_cells -quiet [list {sifpga_crs_i/sifpga_crs_chfpga_0/U0/chfpga0/CHANGEN[3].CHANi}]]
resize_pblock [get_pblocks CHAN3] -add {SLICE_X24Y240:SLICE_X118Y299}
resize_pblock [get_pblocks CHAN3] -add {DSP48E2_X2Y96:DSP48E2_X22Y119}
resize_pblock [get_pblocks CHAN3] -add {RAMB18_X2Y96:RAMB18_X11Y119}
resize_pblock [get_pblocks CHAN3] -add {RAMB36_X2Y48:RAMB36_X11Y59}
create_pblock CHAN4
add_cells_to_pblock [get_pblocks CHAN4] [get_cells -quiet [list {sifpga_crs_i/sifpga_crs_chfpga_0/U0/chfpga0/CHANGEN[4].CHANi}]]
resize_pblock [get_pblocks CHAN4] -add {SLICE_X24Y180:SLICE_X111Y239}
resize_pblock [get_pblocks CHAN4] -add {DSP48E2_X2Y72:DSP48E2_X21Y95}
resize_pblock [get_pblocks CHAN4] -add {RAMB18_X2Y72:RAMB18_X10Y95}
resize_pblock [get_pblocks CHAN4] -add {RAMB36_X2Y36:RAMB36_X10Y47}
create_pblock CHAN5
add_cells_to_pblock [get_pblocks CHAN5] [get_cells -quiet [list {sifpga_crs_i/sifpga_crs_chfpga_0/U0/chfpga0/CHANGEN[5].CHANi}]]
resize_pblock [get_pblocks CHAN5] -add {SLICE_X22Y120:SLICE_X110Y179}
resize_pblock [get_pblocks CHAN5] -add {BUFG_PS_X0Y48:BUFG_PS_X0Y71}
resize_pblock [get_pblocks CHAN5] -add {DSP48E2_X2Y48:DSP48E2_X21Y71}
resize_pblock [get_pblocks CHAN5] -add {RAMB18_X2Y48:RAMB18_X10Y71}
resize_pblock [get_pblocks CHAN5] -add {RAMB36_X2Y24:RAMB36_X10Y35}
create_pblock CHAN6
add_cells_to_pblock [get_pblocks CHAN6] [get_cells -quiet [list {sifpga_crs_i/sifpga_crs_chfpga_0/U0/chfpga0/CHANGEN[6].CHANi}]]
resize_pblock [get_pblocks CHAN6] -add {SLICE_X38Y60:SLICE_X111Y119}
resize_pblock [get_pblocks CHAN6] -add {DSP48E2_X7Y24:DSP48E2_X21Y47}
resize_pblock [get_pblocks CHAN6] -add {RAMB18_X4Y24:RAMB18_X10Y47}
resize_pblock [get_pblocks CHAN6] -add {RAMB36_X4Y12:RAMB36_X10Y23}
create_pblock CHAN7
add_cells_to_pblock [get_pblocks CHAN7] [get_cells -quiet [list {sifpga_crs_i/sifpga_crs_chfpga_0/U0/chfpga0/CHANGEN[7].CHANi}]]
resize_pblock [get_pblocks CHAN7] -add {SLICE_X61Y0:SLICE_X111Y59}
resize_pblock [get_pblocks CHAN7] -add {DSP48E2_X10Y0:DSP48E2_X21Y23}
resize_pblock [get_pblocks CHAN7] -add {RAMB18_X6Y0:RAMB18_X10Y23}
resize_pblock [get_pblocks CHAN7] -add {RAMB36_X6Y0:RAMB36_X10Y11}


set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets clk]
