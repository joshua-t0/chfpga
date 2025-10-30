############################################################################
##
##   CRS Rev1 and Rev2 Physical constraints
##
############################################################################

set_property BITSTREAM.CONFIG.USR_ACCESS TIMESTAMP [current_design]

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
create_clock -period 100.000 -name SMA_CLK10 [get_ports sma_clk10_p]

###############################################################
# Primary clocks from AD9574 (Always present, non-programmable)
###############################################################
# # Fixed 156.25 MHz


# GTY reference clock MGTREFCLK0, 156.25 MHz from fixed PLL, Bank 131
# Corner-turn engine GTY reference clock
set_property PACKAGE_PIN P31 [get_ports {bp_shuffle_refclk_p[0]}]
create_clock -period 6.400 -name CLK_BP_SHUFFLE_REFCLK [get_ports {bp_shuffle_refclk_p[0]}]

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
create_clock -period 20.000 -name OSCOUT [get_ports pll_oscout_p]

# PLL Sync control line, synchronus to OSCOUT
set_property PACKAGE_PIN D19 [get_ports pll_sync]
set_property IOSTANDARD LVCMOS18 [get_ports pll_sync]
set_property SLEW FAST [get_ports pll_sync]
set_property DRIVE 12 [get_ports pll_sync]
set_output_delay -clock OSCOUT -max 1.000 [get_ports pll_sync]
set_output_delay -clock OSCOUT -min -1.000 [get_ports pll_sync]
set_multicycle_path -setup -to [get_ports pll_sync] 1

# PL_CLK (Bank 69), Fabric signal processing word clock (programmable, must be ADC sampling freq / 8 samples/word)
# 3000 MSPS/ 8 = 375 MHz
set_property PACKAGE_PIN G17 [get_ports plclk_p]
set_property IOSTANDARD LVDS [get_ports plclk_p]
set_property DIFF_TERM_ADV TERM_100 [get_ports plclk_p]
#create_clock -period 2.666 -name PL_CLK [get_ports plclk_p]
create_clock -period 2.500 -name PL_CLK [get_ports plclk_p]
set_clock_latency -min -source -0.015 [get_ports plclk_p]
set_clock_latency -max -source 0.015 [get_ports plclk_p]

# SYSREF clock (Bank 69), 2.5 MHz, used to synchronize all the ADC logic. The equivalent of this signal (RF_SYSREF) also goes directly to the ADC/DACs bank.
# This signal is not treated as a clock, but rather a signal that is synchronized to PLCLK.
set_property PACKAGE_PIN H18 [get_ports pl_sysref_p]
set_property IOSTANDARD LVDS [get_ports pl_sysref_p]
set_property DIFF_TERM_ADV TERM_100 [get_ports pl_sysref_p]
#create_clock -period 400.000 -name PL_SYSREF [get_ports pl_sysref_p]
#set_input_delay -clock [get_clocks PL_CLK] 0.0 [get_ports pl_sysref_p]
set_input_delay -clock [get_clocks PL_CLK] -max 0.015 [get_ports pl_sysref_p]
set_input_delay -clock [get_clocks PL_CLK] -min -0.015 [get_ports pl_sysref_p]
#set_multicycle_path 3 -setup -from  [get_ports pl_sysref_p] -to [get_ports plclk_p]
# PL_CLK needs to sample SYSREF, but it is much more delayed than SYSREF because of the BUFG.
# The normal setup rule tries to meet SYSREF setup with the next PL_CLK edge (2.5 ns later), which cause the tool to try and add lots of delay on the SYSREF line, but fails.
# We fix this by aligning SYSREF setup on the same edge if is generated outside the FPGA.
set_multicycle_path -setup -from [get_ports pl_sysref_p] 0

# DDR4_CLK (Bank 67), used as a 10 MHz system clock
set_property PACKAGE_PIN H23 [get_ports sysclk_p]
set_property IOSTANDARD LVDS [get_ports sysclk_p]
set_property DIFF_TERM_ADV TERM_100 [get_ports sysclk_p]
create_clock -period 100.000 -name SYS_CLK [get_ports sysclk_p]
set_clock_latency -min -source -0.015 [get_ports sysclk_p]
set_clock_latency -max -source 0.015 [get_ports sysclk_p]

set_multicycle_path -setup -from [get_clocks SYS_CLK] -to [get_clocks PL_CLK] 0

# # Recovered clock output (not used)
# set_property PACKAGE_PIN C84     [get_ports {pl_recclk_p}]; # Bank  69 VCC1V8
# set_property IOSTANDARD  LVDS     [get_ports {pl_recclk_p}];

# 100 MHz clock provided by the PS to the PL is not in phase with any other clock
set_clock_groups -name BSB_CLK_GROUP -asynchronous -group [get_clocks clk_pl_0]

# Programmable PLL SYNC input



####################
# Backplane signals (DC coupled at the input buffer, AC coupled to the FPGA pins)
####################
# IRIG-B
# Fix: Was K19, moved to K22
set_property PACKAGE_PIN H22 [get_ports bp_irig_p]
set_property IOSTANDARD LVDS [get_ports bp_irig_p]

set_input_delay -clock [get_clocks SYS_CLK] -max 0.015 [get_ports bp_irig_p]
set_input_delay -clock [get_clocks SYS_CLK] -min -0.015 [get_ports bp_irig_p]


# Backplane 10 MHz reference clock (copy of the signal fed to the HMC7044)
set_property PACKAGE_PIN H17 [get_ports bp_clk10_p]
set_property IOSTANDARD LVDS [get_ports bp_clk10_p]
set_property DIFF_TERM_ADV TERM_100 [get_ports bp_clk10_p]

# set_property IOSTANDARD DIFF_SSTL18_I_DCI [get_ports bp_clk10_p]
# set_property DQS_BIAS TRUE [get_ports bp_clk10_p]

create_clock -period 100.000 -name PL_BP_CLK10 [get_ports bp_clk10_p]

set_clock_groups -name exclusive_clk0_clk1 -physically_exclusive -group SMA_CLK10 -group PL_BP_CLK10

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
set_input_delay -clock [get_clocks SYS_CLK] -max 0.015 [get_ports sma_irig_p]
set_input_delay -clock [get_clocks SYS_CLK] -min -0.015 [get_ports sma_irig_p]

# AUX SMA

# set_property PACKAGE_PIN H11     [get_ports {sma_aux_p}]; # Bank  57 VCC1V8
# AUX SMA Driver port, sma_aux_drv: Bank  87 VCC3V3
set_property PACKAGE_PIN E6 [get_ports sma_aux_drv]
set_property IOSTANDARD LVCMOS33 [get_ports sma_aux_drv]
set_property SLEW FAST [get_ports sma_aux_drv]
set_property DRIVE 16 [get_ports sma_aux_drv]
# set_output_delay -clock [get_clocks PL_CLK] -max 0.015 [get_ports sma_aux_drv]
# set_output_delay -clock [get_clocks PL_CLK] -min -0.015 [get_ports sma_aux_drv]



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

# Dummy output delays for the buck sync signals so Vivado won't complain
# set_output_delay -clock [get_clocks clk200_nobuf] -max -4 [get_ports buck_sync_*]
# set_output_delay -clock [get_clocks clk200_nobuf] -min -4 [get_ports buck_sync_*]
set_false_path -to [get_ports buck_sync_*]


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

#set_property IO_BUFFER_TYPE none [get_ports {qsfp_txp*}]
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




# ignore timing between CLK200 and CORR_CLK  domains. This line has to be placed after we have defines the source clock for the two specified derived clocks
# set_false_path -from [get_clocks CLK200_MMCM_NOBUF] -to [get_clocks {CORR_CLK_NOBUF}]

###
# Debug core
###




########################################
# Corner-turn engine
########################################
# These constraints are needed for the CDC synchronizers in the GTY core
# False path constraints
# ----------------------------------------------------------------------------------------------------------------------
##set_false_path -to [get_cells -hierarchical -filter {NAME =~ *reset_synchronizer*inst/rst_in_*_reg}] -quiet



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



#add_cells_to_pblock [get_pblocks CGE] [get_cells -quiet [list chfpga0/CGE_GEN.cge0]]




#add_cells_to_pblock [get_pblocks UCORN] [get_cells -quiet [list chfpga0/crossbar0_gen.cb1_gen.uram_case.uram0]]

# create_pblock CORR
# add_cells_to_pblock [get_pblocks CORR] [get_cells -quiet [list chfpga0/CORRGEN.corr_sel_gen.ucorr44_case.ucorr44_array0]]
# resize_pblock [get_pblocks CORR] -add {SLICE_X0Y180:SLICE_X25Y419}
# resize_pblock [get_pblocks CORR] -add {DSP48E2_X0Y72:DSP48E2_X2Y167}
# resize_pblock [get_pblocks CORR] -add {PCIE4CE4_X0Y0:PCIE4CE4_X0Y0}
# resize_pblock [get_pblocks CORR] -add {RAMB18_X0Y72:RAMB18_X1Y167}
# resize_pblock [get_pblocks CORR] -add {RAMB36_X0Y36:RAMB36_X1Y83}
# resize_pblock [get_pblocks CORR] -add {URAM288_X0Y0:URAM288_X0Y63}
# set_property IS_SOFT FALSE [get_pblocks CORR]
# #add_cells_to_pblock [get_pblocks CORR] [get_cells -quiet [list chfpga0/CORRGEN.corr_array0]]


create_pblock ADC
add_cells_to_pblock [get_pblocks ADC] [get_cells -quiet [list zynq/usp_rf_data_converter_0]]
resize_pblock [get_pblocks ADC] -add {SLICE_X113Y60:SLICE_X118Y299}
set_property EXCLUDE_PLACEMENT 1 [get_pblocks ADC]
# resize_pblock [get_pblocks ADC] -add {DSP48E2_X22Y24:DSP48E2_X22Y119}

# Modules are assigned to the SYSTEM PBLOCK by setting the TARGET_PBLOCK attribute to "SYSTEM" in VHDL
# Use this line to automatically pick the cells
# add_cells_to_pblock [get_pblocks SYSTEM] [get_cells * -hier -filter TARGET_PBLOCK==SYSTEM]

create_pblock SYSTEM
add_cells_to_pblock [get_pblocks SYSTEM] [get_cells -quiet [list chfpga0/CLK0 chfpga0/bsb_master_blk.ctrl_master0 chfpga0/chan_router_blk.chan_router0 chfpga0/ct_clk_blk.ct_reset_cdc0 chfpga0/top_router_blk.top_router0]]
resize_pblock [get_pblocks SYSTEM] -add {SLICE_X113Y300:SLICE_X118Y419}
resize_pblock [get_pblocks SYSTEM] -add {DSP48E2_X22Y120:DSP48E2_X22Y167}
set_property IS_SOFT FALSE [get_pblocks SYSTEM]


create_pblock TCPIPE
add_cells_to_pblock [get_pblocks TCPIPE] [get_cells -quiet [list zynq/axi_dma_0 zynq/axi_dma_1 zynq/rst_ps8_0_96M zynq/smartconnect_0 zynq/xlconcat_0 zynq/zynq_ultra_ps_e_0]]
resize_pblock [get_pblocks TCPIPE] -add {SLICE_X22Y0:SLICE_X25Y179}
resize_pblock [get_pblocks TCPIPE] -add {BUFG_PS_X0Y0:BUFG_PS_X0Y71}
resize_pblock [get_pblocks TCPIPE] -add {DSP48E2_X2Y0:DSP48E2_X2Y71}
resize_pblock [get_pblocks TCPIPE] -add {RAMB18_X2Y18:RAMB18_X2Y23}
resize_pblock [get_pblocks TCPIPE] -add {RAMB36_X2Y9:RAMB36_X2Y11}
set_property IS_SOFT FALSE [get_pblocks TCPIPE]

create_pblock DEBUG
add_cells_to_pblock [get_pblocks DEBUG] [get_cells -quiet [list zynq/system_ila_0]]
resize_pblock [get_pblocks DEBUG] -add {SLICE_X0Y420:SLICE_X14Y479}
resize_pblock [get_pblocks DEBUG] -add {DSP48E2_X0Y168:DSP48E2_X0Y191}
resize_pblock [get_pblocks DEBUG] -add {PCIE4CE4_X0Y1:PCIE4CE4_X0Y1}
resize_pblock [get_pblocks DEBUG] -add {RAMB18_X1Y180:RAMB18_X1Y191 RAMB18_X0Y168:RAMB18_X0Y191}
resize_pblock [get_pblocks DEBUG] -add {RAMB36_X1Y90:RAMB36_X1Y95 RAMB36_X0Y84:RAMB36_X0Y95}
set_property IS_SOFT FALSE [get_pblocks DEBUG]

create_pblock UCAP
add_cells_to_pblock [get_pblocks UCAP] [get_cells -quiet [list chfpga0/cap_gen.uram_case.ucap0]]
resize_pblock [get_pblocks UCAP] -add {SLICE_X15Y420:SLICE_X21Y479}
resize_pblock [get_pblocks UCAP] -add {DSP48E2_X1Y168:DSP48E2_X1Y191}
resize_pblock [get_pblocks UCAP] -add {RAMB18_X1Y168:RAMB18_X1Y179}
resize_pblock [get_pblocks UCAP] -add {URAM288_X0Y64:URAM288_X0Y79}
set_property EXCLUDE_PLACEMENT 1 [get_pblocks UCAP]


# Python generated below

create_pblock CHAN0
add_cells_to_pblock [get_pblocks CHAN0] [get_cells -quiet [list {chfpga0/CHANGEN[0].CHANi}]]
resize_pblock [get_pblocks CHAN0] -add {SLICE_X26Y0:SLICE_X112Y59}
resize_pblock [get_pblocks CHAN0] -add {DSP48E2_X3Y0:DSP48E2_X22Y23}
resize_pblock [get_pblocks CHAN0] -add {RAMB18_X2Y0:RAMB18_X11Y23}
resize_pblock [get_pblocks CHAN0] -add {RAMB36_X2Y0:RAMB36_X11Y11}
set_property IS_SOFT FALSE [get_pblocks CHAN0]


# create_pblock FFT0
# add_cells_to_pblock [get_pblocks FFT0] [get_cells -quiet [list {chfpga0/CHANGEN[0].CHANi/IMPL_GEN.fft_blk.FFT0}]]
# resize_pblock [get_pblocks FFT0] -add {SLICE_X109Y40:SLICE_X112Y59 SLICE_X82Y0:SLICE_X108Y59 SLICE_X57Y0:SLICE_X79Y59 SLICE_X32Y0:SLICE_X55Y59}
# resize_pblock [get_pblocks FFT0] -add {DSP48E2_X5Y0:DSP48E2_X22Y23}
# resize_pblock [get_pblocks FFT0] -add {RAMB18_X11Y16:RAMB18_X11Y23 RAMB18_X3Y0:RAMB18_X10Y23}
# resize_pblock [get_pblocks FFT0] -add {RAMB36_X11Y8:RAMB36_X11Y11 RAMB36_X3Y0:RAMB36_X10Y11}
# set_property EXCLUDE_PLACEMENT 1 [get_pblocks FFT0]

# # pblock below seems unused
# create_pblock PFB0
# resize_pblock [get_pblocks PFB0] -add {SLICE_X92Y0:SLICE_X105Y59}
# resize_pblock [get_pblocks PFB0] -add {DSP48E2_X18Y0:DSP48E2_X20Y23}
# resize_pblock [get_pblocks PFB0] -add {RAMB18_X9Y0:RAMB18_X10Y23}
# resize_pblock [get_pblocks PFB0] -add {RAMB36_X9Y0:RAMB36_X10Y11}


# create_pblock FUNCGEN0
# add_cells_to_pblock [get_pblocks FUNCGEN0] [get_cells -quiet [list {chfpga0/CHANGEN[0].CHANi/IMPL_GEN.funcgen_blk.FUNCGEN0}]]
# resize_pblock [get_pblocks FUNCGEN0] -add {SLICE_X109Y0:SLICE_X112Y39}
# resize_pblock [get_pblocks FUNCGEN0] -add {RAMB18_X11Y0:RAMB18_X11Y15}
# resize_pblock [get_pblocks FUNCGEN0] -add {RAMB36_X11Y0:RAMB36_X11Y7}
# set_property IS_SOFT FALSE [get_pblocks FUNCGEN0]


# create_pblock SCALER0
# add_cells_to_pblock [get_pblocks SCALER0] [get_cells -quiet [list {chfpga0/CHANGEN[0].CHANi/IMPL_GEN.scaler_blk.SCALER0}]]
# resize_pblock [get_pblocks SCALER0] -add {SLICE_X26Y0:SLICE_X31Y59}
# resize_pblock [get_pblocks SCALER0] -add {DSP48E2_X3Y0:DSP48E2_X4Y23}
# resize_pblock [get_pblocks SCALER0] -add {RAMB18_X2Y0:RAMB18_X2Y15}
# resize_pblock [get_pblocks SCALER0] -add {RAMB36_X2Y0:RAMB36_X2Y7}
# set_property IS_SOFT FALSE [get_pblocks SCALER0]


create_pblock CHAN1
add_cells_to_pblock [get_pblocks CHAN1] [get_cells -quiet [list {chfpga0/CHANGEN[1].CHANi}]]
resize_pblock [get_pblocks CHAN1] -add {SLICE_X26Y60:SLICE_X112Y119}
resize_pblock [get_pblocks CHAN1] -add {DSP48E2_X3Y24:DSP48E2_X22Y47}
resize_pblock [get_pblocks CHAN1] -add {RAMB18_X2Y24:RAMB18_X11Y47}
resize_pblock [get_pblocks CHAN1] -add {RAMB36_X2Y12:RAMB36_X11Y23}
set_property IS_SOFT FALSE [get_pblocks CHAN1]


# create_pblock FFT1
# add_cells_to_pblock [get_pblocks FFT1] [get_cells -quiet [list {chfpga0/CHANGEN[1].CHANi/IMPL_GEN.fft_blk.FFT0}]]
# resize_pblock [get_pblocks FFT1] -add {SLICE_X109Y100:SLICE_X112Y119 SLICE_X82Y60:SLICE_X108Y119 SLICE_X57Y60:SLICE_X79Y119 SLICE_X32Y60:SLICE_X55Y119}
# resize_pblock [get_pblocks FFT1] -add {DSP48E2_X5Y24:DSP48E2_X22Y47}
# resize_pblock [get_pblocks FFT1] -add {RAMB18_X11Y40:RAMB18_X11Y47 RAMB18_X3Y24:RAMB18_X10Y47}
# resize_pblock [get_pblocks FFT1] -add {RAMB36_X11Y20:RAMB36_X11Y23 RAMB36_X3Y12:RAMB36_X10Y23}
# set_property EXCLUDE_PLACEMENT 1 [get_pblocks FFT1]


# create_pblock FUNCGEN1
# add_cells_to_pblock [get_pblocks FUNCGEN1] [get_cells -quiet [list {chfpga0/CHANGEN[1].CHANi/IMPL_GEN.funcgen_blk.FUNCGEN0}]]
# resize_pblock [get_pblocks FUNCGEN1] -add {SLICE_X109Y60:SLICE_X112Y99}
# resize_pblock [get_pblocks FUNCGEN1] -add {RAMB18_X11Y24:RAMB18_X11Y39}
# resize_pblock [get_pblocks FUNCGEN1] -add {RAMB36_X11Y12:RAMB36_X11Y19}
# set_property IS_SOFT FALSE [get_pblocks FUNCGEN1]


# create_pblock SCALER1
# add_cells_to_pblock [get_pblocks SCALER1] [get_cells -quiet [list {chfpga0/CHANGEN[1].CHANi/IMPL_GEN.scaler_blk.SCALER0}]]
# resize_pblock [get_pblocks SCALER1] -add {SLICE_X26Y60:SLICE_X31Y119}
# resize_pblock [get_pblocks SCALER1] -add {DSP48E2_X3Y24:DSP48E2_X4Y47}
# resize_pblock [get_pblocks SCALER1] -add {RAMB18_X2Y24:RAMB18_X2Y39}
# resize_pblock [get_pblocks SCALER1] -add {RAMB36_X2Y12:RAMB36_X2Y19}
# set_property IS_SOFT FALSE [get_pblocks SCALER1]


create_pblock CHAN2
add_cells_to_pblock [get_pblocks CHAN2] [get_cells -quiet [list {chfpga0/CHANGEN[2].CHANi}]]
resize_pblock [get_pblocks CHAN2] -add {SLICE_X26Y120:SLICE_X112Y179}
resize_pblock [get_pblocks CHAN2] -add {DSP48E2_X3Y48:DSP48E2_X22Y71}
resize_pblock [get_pblocks CHAN2] -add {RAMB18_X2Y48:RAMB18_X11Y71}
resize_pblock [get_pblocks CHAN2] -add {RAMB36_X2Y24:RAMB36_X11Y35}
set_property IS_SOFT FALSE [get_pblocks CHAN2]


# create_pblock FFT2
# add_cells_to_pblock [get_pblocks FFT2] [get_cells -quiet [list {chfpga0/CHANGEN[2].CHANi/IMPL_GEN.fft_blk.FFT0}]]
# resize_pblock [get_pblocks FFT2] -add {SLICE_X109Y160:SLICE_X112Y179 SLICE_X82Y120:SLICE_X108Y179 SLICE_X57Y120:SLICE_X79Y179 SLICE_X32Y120:SLICE_X55Y179}
# resize_pblock [get_pblocks FFT2] -add {DSP48E2_X5Y48:DSP48E2_X22Y71}
# resize_pblock [get_pblocks FFT2] -add {RAMB18_X11Y64:RAMB18_X11Y71 RAMB18_X3Y48:RAMB18_X10Y71}
# resize_pblock [get_pblocks FFT2] -add {RAMB36_X11Y32:RAMB36_X11Y35 RAMB36_X3Y24:RAMB36_X10Y35}
# set_property EXCLUDE_PLACEMENT 1 [get_pblocks FFT2]


# create_pblock FUNCGEN2
# add_cells_to_pblock [get_pblocks FUNCGEN2] [get_cells -quiet [list {chfpga0/CHANGEN[2].CHANi/IMPL_GEN.funcgen_blk.FUNCGEN0}]]
# resize_pblock [get_pblocks FUNCGEN2] -add {SLICE_X109Y120:SLICE_X112Y159}
# resize_pblock [get_pblocks FUNCGEN2] -add {RAMB18_X11Y48:RAMB18_X11Y63}
# resize_pblock [get_pblocks FUNCGEN2] -add {RAMB36_X11Y24:RAMB36_X11Y31}
# set_property IS_SOFT FALSE [get_pblocks FUNCGEN2]


# create_pblock SCALER2
# add_cells_to_pblock [get_pblocks SCALER2] [get_cells -quiet [list {chfpga0/CHANGEN[2].CHANi/IMPL_GEN.scaler_blk.SCALER0}]]
# resize_pblock [get_pblocks SCALER2] -add {SLICE_X26Y120:SLICE_X31Y179}
# resize_pblock [get_pblocks SCALER2] -add {DSP48E2_X3Y48:DSP48E2_X4Y71}
# resize_pblock [get_pblocks SCALER2] -add {RAMB18_X2Y48:RAMB18_X2Y63}
# resize_pblock [get_pblocks SCALER2] -add {RAMB36_X2Y24:RAMB36_X2Y31}
# set_property IS_SOFT FALSE [get_pblocks SCALER2]


create_pblock CHAN3
add_cells_to_pblock [get_pblocks CHAN3] [get_cells -quiet [list {chfpga0/CHANGEN[3].CHANi}]]
resize_pblock [get_pblocks CHAN3] -add {SLICE_X26Y180:SLICE_X112Y239}
resize_pblock [get_pblocks CHAN3] -add {DSP48E2_X3Y72:DSP48E2_X22Y95}
resize_pblock [get_pblocks CHAN3] -add {RAMB18_X2Y72:RAMB18_X11Y95}
resize_pblock [get_pblocks CHAN3] -add {RAMB36_X2Y36:RAMB36_X11Y47}
set_property IS_SOFT FALSE [get_pblocks CHAN3]


# create_pblock FFT3
# add_cells_to_pblock [get_pblocks FFT3] [get_cells -quiet [list {chfpga0/CHANGEN[3].CHANi/IMPL_GEN.fft_blk.FFT0}]]
# resize_pblock [get_pblocks FFT3] -add {SLICE_X109Y220:SLICE_X112Y239 SLICE_X82Y180:SLICE_X108Y239 SLICE_X57Y180:SLICE_X79Y239 SLICE_X32Y180:SLICE_X55Y239}
# resize_pblock [get_pblocks FFT3] -add {DSP48E2_X5Y72:DSP48E2_X22Y95}
# resize_pblock [get_pblocks FFT3] -add {RAMB18_X11Y88:RAMB18_X11Y95 RAMB18_X3Y72:RAMB18_X10Y95}
# resize_pblock [get_pblocks FFT3] -add {RAMB36_X11Y44:RAMB36_X11Y47 RAMB36_X3Y36:RAMB36_X10Y47}
# set_property EXCLUDE_PLACEMENT 1 [get_pblocks FFT3]


# create_pblock FUNCGEN3
# add_cells_to_pblock [get_pblocks FUNCGEN3] [get_cells -quiet [list {chfpga0/CHANGEN[3].CHANi/IMPL_GEN.funcgen_blk.FUNCGEN0}]]
# resize_pblock [get_pblocks FUNCGEN3] -add {SLICE_X109Y180:SLICE_X112Y219}
# resize_pblock [get_pblocks FUNCGEN3] -add {RAMB18_X11Y72:RAMB18_X11Y87}
# resize_pblock [get_pblocks FUNCGEN3] -add {RAMB36_X11Y36:RAMB36_X11Y43}
# set_property IS_SOFT FALSE [get_pblocks FUNCGEN3]


# create_pblock SCALER3
# add_cells_to_pblock [get_pblocks SCALER3] [get_cells -quiet [list {chfpga0/CHANGEN[3].CHANi/IMPL_GEN.scaler_blk.SCALER0}]]
# resize_pblock [get_pblocks SCALER3] -add {SLICE_X26Y180:SLICE_X31Y239}
# resize_pblock [get_pblocks SCALER3] -add {DSP48E2_X3Y72:DSP48E2_X4Y95}
# resize_pblock [get_pblocks SCALER3] -add {RAMB18_X2Y72:RAMB18_X2Y87}
# resize_pblock [get_pblocks SCALER3] -add {RAMB36_X2Y36:RAMB36_X2Y43}
# set_property IS_SOFT FALSE [get_pblocks SCALER3]


create_pblock CHAN4
add_cells_to_pblock [get_pblocks CHAN4] [get_cells -quiet [list {chfpga0/CHANGEN[4].CHANi}]]
resize_pblock [get_pblocks CHAN4] -add {SLICE_X26Y240:SLICE_X112Y299}
resize_pblock [get_pblocks CHAN4] -add {DSP48E2_X3Y96:DSP48E2_X22Y119}
resize_pblock [get_pblocks CHAN4] -add {RAMB18_X2Y96:RAMB18_X11Y119}
resize_pblock [get_pblocks CHAN4] -add {RAMB36_X2Y48:RAMB36_X11Y59}
set_property IS_SOFT FALSE [get_pblocks CHAN4]


# create_pblock FFT4
# add_cells_to_pblock [get_pblocks FFT4] [get_cells -quiet [list {chfpga0/CHANGEN[4].CHANi/IMPL_GEN.fft_blk.FFT0}]]
# resize_pblock [get_pblocks FFT4] -add {SLICE_X109Y280:SLICE_X112Y299 SLICE_X82Y240:SLICE_X108Y299 SLICE_X57Y240:SLICE_X79Y299 SLICE_X32Y240:SLICE_X55Y299}
# resize_pblock [get_pblocks FFT4] -add {DSP48E2_X5Y96:DSP48E2_X22Y119}
# resize_pblock [get_pblocks FFT4] -add {RAMB18_X11Y112:RAMB18_X11Y119 RAMB18_X3Y96:RAMB18_X10Y119}
# resize_pblock [get_pblocks FFT4] -add {RAMB36_X11Y56:RAMB36_X11Y59 RAMB36_X3Y48:RAMB36_X10Y59}
# set_property EXCLUDE_PLACEMENT 1 [get_pblocks FFT4]


# create_pblock FUNCGEN4
# add_cells_to_pblock [get_pblocks FUNCGEN4] [get_cells -quiet [list {chfpga0/CHANGEN[4].CHANi/IMPL_GEN.funcgen_blk.FUNCGEN0}]]
# resize_pblock [get_pblocks FUNCGEN4] -add {SLICE_X109Y240:SLICE_X112Y279}
# resize_pblock [get_pblocks FUNCGEN4] -add {RAMB18_X11Y96:RAMB18_X11Y111}
# resize_pblock [get_pblocks FUNCGEN4] -add {RAMB36_X11Y48:RAMB36_X11Y55}
# set_property IS_SOFT FALSE [get_pblocks FUNCGEN4]


# create_pblock SCALER4
# add_cells_to_pblock [get_pblocks SCALER4] [get_cells -quiet [list {chfpga0/CHANGEN[4].CHANi/IMPL_GEN.scaler_blk.SCALER0}]]
# resize_pblock [get_pblocks SCALER4] -add {SLICE_X26Y240:SLICE_X31Y299}
# resize_pblock [get_pblocks SCALER4] -add {DSP48E2_X3Y96:DSP48E2_X4Y119}
# resize_pblock [get_pblocks SCALER4] -add {RAMB18_X2Y96:RAMB18_X2Y111}
# resize_pblock [get_pblocks SCALER4] -add {RAMB36_X2Y48:RAMB36_X2Y55}
# set_property IS_SOFT FALSE [get_pblocks SCALER4]


create_pblock CHAN5
add_cells_to_pblock [get_pblocks CHAN5] [get_cells -quiet [list {chfpga0/CHANGEN[5].CHANi}]]
resize_pblock [get_pblocks CHAN5] -add {SLICE_X26Y300:SLICE_X112Y359}
resize_pblock [get_pblocks CHAN5] -add {DSP48E2_X3Y120:DSP48E2_X22Y143}
resize_pblock [get_pblocks CHAN5] -add {RAMB18_X2Y120:RAMB18_X11Y143}
resize_pblock [get_pblocks CHAN5] -add {RAMB36_X2Y60:RAMB36_X11Y71}
set_property IS_SOFT FALSE [get_pblocks CHAN5]


# create_pblock FFT5
# add_cells_to_pblock [get_pblocks FFT5] [get_cells -quiet [list {chfpga0/CHANGEN[5].CHANi/IMPL_GEN.fft_blk.FFT0}]]
# resize_pblock [get_pblocks FFT5] -add {SLICE_X109Y340:SLICE_X112Y359 SLICE_X82Y300:SLICE_X108Y359 SLICE_X57Y300:SLICE_X79Y359 SLICE_X32Y300:SLICE_X55Y359}
# resize_pblock [get_pblocks FFT5] -add {DSP48E2_X5Y120:DSP48E2_X22Y143}
# resize_pblock [get_pblocks FFT5] -add {RAMB18_X11Y136:RAMB18_X11Y143 RAMB18_X3Y120:RAMB18_X10Y143}
# resize_pblock [get_pblocks FFT5] -add {RAMB36_X11Y68:RAMB36_X11Y71 RAMB36_X3Y60:RAMB36_X10Y71}
# set_property EXCLUDE_PLACEMENT 1 [get_pblocks FFT5]


# create_pblock FUNCGEN5
# add_cells_to_pblock [get_pblocks FUNCGEN5] [get_cells -quiet [list {chfpga0/CHANGEN[5].CHANi/IMPL_GEN.funcgen_blk.FUNCGEN0}]]
# resize_pblock [get_pblocks FUNCGEN5] -add {SLICE_X109Y300:SLICE_X112Y339}
# resize_pblock [get_pblocks FUNCGEN5] -add {RAMB18_X11Y120:RAMB18_X11Y135}
# resize_pblock [get_pblocks FUNCGEN5] -add {RAMB36_X11Y60:RAMB36_X11Y67}
# set_property IS_SOFT FALSE [get_pblocks FUNCGEN5]


# create_pblock SCALER5
# add_cells_to_pblock [get_pblocks SCALER5] [get_cells -quiet [list {chfpga0/CHANGEN[5].CHANi/IMPL_GEN.scaler_blk.SCALER0}]]
# resize_pblock [get_pblocks SCALER5] -add {SLICE_X26Y300:SLICE_X31Y359}
# resize_pblock [get_pblocks SCALER5] -add {DSP48E2_X3Y120:DSP48E2_X4Y143}
# resize_pblock [get_pblocks SCALER5] -add {RAMB18_X2Y120:RAMB18_X2Y135}
# resize_pblock [get_pblocks SCALER5] -add {RAMB36_X2Y60:RAMB36_X2Y67}
# set_property IS_SOFT FALSE [get_pblocks SCALER5]


create_pblock CHAN6
add_cells_to_pblock [get_pblocks CHAN6] [get_cells -quiet [list {chfpga0/CHANGEN[6].CHANi}]]
resize_pblock [get_pblocks CHAN6] -add {SLICE_X26Y360:SLICE_X112Y419}
resize_pblock [get_pblocks CHAN6] -add {DSP48E2_X3Y144:DSP48E2_X22Y167}
resize_pblock [get_pblocks CHAN6] -add {RAMB18_X2Y144:RAMB18_X11Y167}
resize_pblock [get_pblocks CHAN6] -add {RAMB36_X2Y72:RAMB36_X11Y83}
set_property IS_SOFT FALSE [get_pblocks CHAN6]


# create_pblock FFT6
# add_cells_to_pblock [get_pblocks FFT6] [get_cells -quiet [list {chfpga0/CHANGEN[6].CHANi/IMPL_GEN.fft_blk.FFT0}]]
# resize_pblock [get_pblocks FFT6] -add {SLICE_X109Y400:SLICE_X112Y419 SLICE_X82Y360:SLICE_X108Y419 SLICE_X57Y360:SLICE_X79Y419 SLICE_X32Y360:SLICE_X55Y419}
# resize_pblock [get_pblocks FFT6] -add {DSP48E2_X5Y144:DSP48E2_X22Y167}
# resize_pblock [get_pblocks FFT6] -add {RAMB18_X11Y160:RAMB18_X11Y167 RAMB18_X3Y144:RAMB18_X10Y167}
# resize_pblock [get_pblocks FFT6] -add {RAMB36_X11Y80:RAMB36_X11Y83 RAMB36_X3Y72:RAMB36_X10Y83}
# set_property EXCLUDE_PLACEMENT 1 [get_pblocks FFT6]


# create_pblock FUNCGEN6
# add_cells_to_pblock [get_pblocks FUNCGEN6] [get_cells -quiet [list {chfpga0/CHANGEN[6].CHANi/IMPL_GEN.funcgen_blk.FUNCGEN0}]]
# resize_pblock [get_pblocks FUNCGEN6] -add {SLICE_X109Y360:SLICE_X112Y399}
# resize_pblock [get_pblocks FUNCGEN6] -add {RAMB18_X11Y144:RAMB18_X11Y159}
# resize_pblock [get_pblocks FUNCGEN6] -add {RAMB36_X11Y72:RAMB36_X11Y79}
# set_property IS_SOFT FALSE [get_pblocks FUNCGEN6]


# create_pblock SCALER6
# add_cells_to_pblock [get_pblocks SCALER6] [get_cells -quiet [list {chfpga0/CHANGEN[6].CHANi/IMPL_GEN.scaler_blk.SCALER0}]]
# resize_pblock [get_pblocks SCALER6] -add {SLICE_X26Y360:SLICE_X31Y419}
# resize_pblock [get_pblocks SCALER6] -add {DSP48E2_X3Y144:DSP48E2_X4Y167}
# resize_pblock [get_pblocks SCALER6] -add {RAMB18_X2Y144:RAMB18_X2Y159}
# resize_pblock [get_pblocks SCALER6] -add {RAMB36_X2Y72:RAMB36_X2Y79}
# set_property IS_SOFT FALSE [get_pblocks SCALER6]


create_pblock CHAN7
add_cells_to_pblock [get_pblocks CHAN7] [get_cells -quiet [list {chfpga0/CHANGEN[7].CHANi}]]
resize_pblock [get_pblocks CHAN7] -add {SLICE_X26Y420:SLICE_X112Y479}
resize_pblock [get_pblocks CHAN7] -add {DSP48E2_X3Y168:DSP48E2_X22Y191}
resize_pblock [get_pblocks CHAN7] -add {RAMB18_X2Y168:RAMB18_X11Y191}
resize_pblock [get_pblocks CHAN7] -add {RAMB36_X2Y84:RAMB36_X11Y95}
set_property IS_SOFT FALSE [get_pblocks CHAN7]


# create_pblock FFT7
# add_cells_to_pblock [get_pblocks FFT7] [get_cells -quiet [list {chfpga0/CHANGEN[7].CHANi/IMPL_GEN.fft_blk.FFT0}]]
# resize_pblock [get_pblocks FFT7] -add {SLICE_X109Y460:SLICE_X112Y479 SLICE_X82Y420:SLICE_X108Y479 SLICE_X57Y420:SLICE_X79Y479 SLICE_X32Y420:SLICE_X55Y479}
# resize_pblock [get_pblocks FFT7] -add {DSP48E2_X5Y168:DSP48E2_X22Y191}
# resize_pblock [get_pblocks FFT7] -add {RAMB18_X11Y184:RAMB18_X11Y191 RAMB18_X3Y168:RAMB18_X10Y191}
# resize_pblock [get_pblocks FFT7] -add {RAMB36_X11Y92:RAMB36_X11Y95 RAMB36_X3Y84:RAMB36_X10Y95}
# set_property EXCLUDE_PLACEMENT 1 [get_pblocks FFT7]


# create_pblock FUNCGEN7
# add_cells_to_pblock [get_pblocks FUNCGEN7] [get_cells -quiet [list {chfpga0/CHANGEN[7].CHANi/IMPL_GEN.funcgen_blk.FUNCGEN0}]]
# resize_pblock [get_pblocks FUNCGEN7] -add {SLICE_X109Y420:SLICE_X112Y459}
# resize_pblock [get_pblocks FUNCGEN7] -add {RAMB18_X11Y168:RAMB18_X11Y183}
# resize_pblock [get_pblocks FUNCGEN7] -add {RAMB36_X11Y84:RAMB36_X11Y91}
# set_property IS_SOFT FALSE [get_pblocks FUNCGEN7]


# create_pblock SCALER7
# add_cells_to_pblock [get_pblocks SCALER7] [get_cells -quiet [list {chfpga0/CHANGEN[7].CHANi/IMPL_GEN.scaler_blk.SCALER0}]]
# resize_pblock [get_pblocks SCALER7] -add {SLICE_X26Y420:SLICE_X31Y479}
# resize_pblock [get_pblocks SCALER7] -add {DSP48E2_X3Y168:DSP48E2_X4Y191}
# resize_pblock [get_pblocks SCALER7] -add {RAMB18_X2Y168:RAMB18_X2Y183}
# resize_pblock [get_pblocks SCALER7] -add {RAMB36_X2Y84:RAMB36_X2Y91}
# set_property IS_SOFT FALSE [get_pblocks SCALER7]


# JFC commented out 2025-10-02
# create_pblock FFT_BIPLEX0
# add_cells_to_pblock [get_pblocks FFT_BIPLEX0] [get_cells -quiet [list {chfpga0/CHANGEN[0].CHANi/IMPL_GEN.fft_blk.FFT0/FFT_GEN.fftype_gen.FFT0/U0/pfb_fft_bitgrowth_struct/fft_wideband_real/fft_biplex_real_4x}]]
# resize_pblock [get_pblocks FFT_BIPLEX0] -add {RAMB36_X3Y7:RAMB36_X9Y11 RAMB36_X10Y9:RAMB36_X10Y11}
# resize_pblock [get_pblocks FFT_BIPLEX0] -add {RAMB18_X3Y14:RAMB18_X9Y23 RAMB18_X10Y18:RAMB18_X10Y23}
# resize_pblock [get_pblocks FFT_BIPLEX0] -add {SLICE_X32Y35:SLICE_X104Y59 SLICE_X105Y45:SLICE_X105Y59}
# resize_pblock [get_pblocks FFT_BIPLEX0] -add {DSP48E2_X5Y14:DSP48E2_X20Y23}

# create_pblock FFT_DIRECT0
# add_cells_to_pblock [get_pblocks FFT_DIRECT0] [get_cells -quiet [list {chfpga0/CHANGEN[0].CHANi/IMPL_GEN.fft_blk.FFT0/FFT_GEN.fftype_gen.FFT0/U0/pfb_fft_bitgrowth_struct/fft_wideband_real/fft_direct}]]
# resize_pblock [get_pblocks FFT_DIRECT0] -add {RAMB36_X3Y0:RAMB36_X7Y0}
# resize_pblock [get_pblocks FFT_DIRECT0] -add {RAMB18_X3Y0:RAMB18_X7Y1}
# resize_pblock [get_pblocks FFT_DIRECT0] -add {SLICE_X32Y0:SLICE_X112Y14}
# resize_pblock [get_pblocks FFT_DIRECT0] -add {DSP48E2_X5Y0:DSP48E2_X22Y5}

# create_pblock FUNCGEN0
# add_cells_to_pblock [get_pblocks FUNCGEN0] [get_cells -quiet [list {chfpga0/CHANGEN[0].CHANi/IMPL_GEN.funcgen_blk.FUNCGEN0}]]
# resize_pblock [get_pblocks FUNCGEN0] -add {RAMB36_X11Y4:RAMB36_X11Y11}
# resize_pblock [get_pblocks FUNCGEN0] -add {RAMB18_X11Y8:RAMB18_X11Y23}
# resize_pblock [get_pblocks FUNCGEN0] -add {SLICE_X106Y35:SLICE_X112Y59}

# create_pblock PFB0
# add_cells_to_pblock [get_pblocks PFB0] [get_cells -quiet [list {chfpga0/CHANGEN[0].CHANi/IMPL_GEN.fft_blk.FFT0/FFT_GEN.fftype_gen.FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real}]]
# resize_pblock [get_pblocks PFB0] -add {RAMB36_X3Y1:RAMB36_X7Y6 RAMB36_X8Y0:RAMB36_X9Y6 RAMB36_X10Y0:RAMB36_X10Y8 RAMB36_X11Y0:RAMB36_X11Y3}
# resize_pblock [get_pblocks PFB0] -add {RAMB18_X3Y2:RAMB18_X7Y13 RAMB18_X8Y0:RAMB18_X9Y13 RAMB18_X10Y0:RAMB18_X10Y17 RAMB18_X11Y0:RAMB18_X11Y7}
# resize_pblock [get_pblocks PFB0] -add {SLICE_X32Y15:SLICE_X112Y34 SLICE_X105Y35:SLICE_X105Y44}
# resize_pblock [get_pblocks PFB0] -add {DSP48E2_X5Y6:DSP48E2_X22Y13}

# create_pblock SCALER0
# add_cells_to_pblock [get_pblocks SCALER0] [get_cells -quiet [list {chfpga0/CHANGEN[0].CHANi/IMPL_GEN.scaler_blk.SCALER0} {chfpga0/CHANGEN[0].CHANi/IMPL_GEN.fifo_blk.fifo0}]]
# resize_pblock [get_pblocks SCALER0] -add {RAMB36_X2Y0:RAMB36_X2Y11}
# resize_pblock [get_pblocks SCALER0] -add {RAMB18_X2Y0:RAMB18_X2Y23}
# resize_pblock [get_pblocks SCALER0] -add {SLICE_X26Y0:SLICE_X31Y59}
# resize_pblock [get_pblocks SCALER0] -add {DSP48E2_X3Y0:DSP48E2_X4Y23}

# create_pblock FFT_BIPLEX1
# add_cells_to_pblock [get_pblocks FFT_BIPLEX1] [get_cells -quiet [list {chfpga0/CHANGEN[1].CHANi/IMPL_GEN.fft_blk.FFT0/FFT_GEN.fftype_gen.FFT0/U0/pfb_fft_bitgrowth_struct/fft_wideband_real/fft_biplex_real_4x}]]
# resize_pblock [get_pblocks FFT_BIPLEX1] -add {RAMB36_X3Y19:RAMB36_X9Y23 RAMB36_X10Y21:RAMB36_X10Y23}
# resize_pblock [get_pblocks FFT_BIPLEX1] -add {RAMB18_X3Y38:RAMB18_X9Y47 RAMB18_X10Y42:RAMB18_X10Y47}
# resize_pblock [get_pblocks FFT_BIPLEX1] -add {SLICE_X32Y95:SLICE_X104Y119 SLICE_X105Y105:SLICE_X105Y119}
# resize_pblock [get_pblocks FFT_BIPLEX1] -add {DSP48E2_X5Y38:DSP48E2_X20Y47}

# create_pblock FFT_DIRECT1
# add_cells_to_pblock [get_pblocks FFT_DIRECT1] [get_cells -quiet [list {chfpga0/CHANGEN[1].CHANi/IMPL_GEN.fft_blk.FFT0/FFT_GEN.fftype_gen.FFT0/U0/pfb_fft_bitgrowth_struct/fft_wideband_real/fft_direct}]]
# resize_pblock [get_pblocks FFT_DIRECT1] -add {RAMB36_X3Y12:RAMB36_X7Y12}
# resize_pblock [get_pblocks FFT_DIRECT1] -add {RAMB18_X3Y24:RAMB18_X7Y25}
# resize_pblock [get_pblocks FFT_DIRECT1] -add {SLICE_X32Y60:SLICE_X112Y74}
# resize_pblock [get_pblocks FFT_DIRECT1] -add {DSP48E2_X5Y24:DSP48E2_X22Y29}

# create_pblock FUNCGEN1
# add_cells_to_pblock [get_pblocks FUNCGEN1] [get_cells -quiet [list {chfpga0/CHANGEN[1].CHANi/IMPL_GEN.funcgen_blk.FUNCGEN0}]]
# resize_pblock [get_pblocks FUNCGEN1] -add {RAMB36_X11Y16:RAMB36_X11Y23}
# resize_pblock [get_pblocks FUNCGEN1] -add {RAMB18_X11Y32:RAMB18_X11Y47}
# resize_pblock [get_pblocks FUNCGEN1] -add {SLICE_X106Y95:SLICE_X112Y119}

# create_pblock PFB1
# add_cells_to_pblock [get_pblocks PFB1] [get_cells -quiet [list {chfpga0/CHANGEN[1].CHANi/IMPL_GEN.fft_blk.FFT0/FFT_GEN.fftype_gen.FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real}]]
# resize_pblock [get_pblocks PFB1] -add {RAMB36_X3Y13:RAMB36_X7Y18 RAMB36_X8Y12:RAMB36_X9Y18 RAMB36_X10Y12:RAMB36_X10Y20 RAMB36_X11Y12:RAMB36_X11Y15}
# resize_pblock [get_pblocks PFB1] -add {RAMB18_X3Y26:RAMB18_X7Y37 RAMB18_X8Y24:RAMB18_X9Y37 RAMB18_X10Y24:RAMB18_X10Y41 RAMB18_X11Y24:RAMB18_X11Y31}
# resize_pblock [get_pblocks PFB1] -add {SLICE_X32Y75:SLICE_X112Y94 SLICE_X105Y95:SLICE_X105Y104}
# resize_pblock [get_pblocks PFB1] -add {DSP48E2_X5Y30:DSP48E2_X22Y37}

# create_pblock SCALER1
# add_cells_to_pblock [get_pblocks SCALER1] [get_cells -quiet [list {chfpga0/CHANGEN[1].CHANi/IMPL_GEN.scaler_blk.SCALER0} {chfpga0/CHANGEN[1].CHANi/IMPL_GEN.fifo_blk.fifo0}]]
# resize_pblock [get_pblocks SCALER1] -add {RAMB36_X2Y12:RAMB36_X2Y23}
# resize_pblock [get_pblocks SCALER1] -add {RAMB18_X2Y24:RAMB18_X2Y47}
# resize_pblock [get_pblocks SCALER1] -add {SLICE_X26Y60:SLICE_X31Y119}
# resize_pblock [get_pblocks SCALER1] -add {DSP48E2_X3Y24:DSP48E2_X4Y47}

# create_pblock FFT_BIPLEX2
# add_cells_to_pblock [get_pblocks FFT_BIPLEX2] [get_cells -quiet [list {chfpga0/CHANGEN[2].CHANi/IMPL_GEN.fft_blk.FFT0/FFT_GEN.fftype_gen.FFT0/U0/pfb_fft_bitgrowth_struct/fft_wideband_real/fft_biplex_real_4x}]]
# resize_pblock [get_pblocks FFT_BIPLEX2] -add {RAMB36_X3Y31:RAMB36_X9Y35 RAMB36_X10Y33:RAMB36_X10Y35}
# resize_pblock [get_pblocks FFT_BIPLEX2] -add {RAMB18_X3Y62:RAMB18_X9Y71 RAMB18_X10Y66:RAMB18_X10Y71}
# resize_pblock [get_pblocks FFT_BIPLEX2] -add {SLICE_X32Y155:SLICE_X104Y179 SLICE_X105Y165:SLICE_X105Y179}
# resize_pblock [get_pblocks FFT_BIPLEX2] -add {DSP48E2_X5Y62:DSP48E2_X20Y71}

# create_pblock FFT_DIRECT2
# add_cells_to_pblock [get_pblocks FFT_DIRECT2] [get_cells -quiet [list {chfpga0/CHANGEN[2].CHANi/IMPL_GEN.fft_blk.FFT0/FFT_GEN.fftype_gen.FFT0/U0/pfb_fft_bitgrowth_struct/fft_wideband_real/fft_direct}]]
# resize_pblock [get_pblocks FFT_DIRECT2] -add {RAMB36_X3Y24:RAMB36_X7Y24}
# resize_pblock [get_pblocks FFT_DIRECT2] -add {RAMB18_X3Y48:RAMB18_X7Y49}
# resize_pblock [get_pblocks FFT_DIRECT2] -add {SLICE_X32Y120:SLICE_X112Y134}
# resize_pblock [get_pblocks FFT_DIRECT2] -add {DSP48E2_X5Y48:DSP48E2_X22Y53}

# create_pblock FUNCGEN2
# add_cells_to_pblock [get_pblocks FUNCGEN2] [get_cells -quiet [list {chfpga0/CHANGEN[2].CHANi/IMPL_GEN.funcgen_blk.FUNCGEN0}]]
# resize_pblock [get_pblocks FUNCGEN2] -add {RAMB36_X11Y28:RAMB36_X11Y35}
# resize_pblock [get_pblocks FUNCGEN2] -add {RAMB18_X11Y56:RAMB18_X11Y71}
# resize_pblock [get_pblocks FUNCGEN2] -add {SLICE_X106Y155:SLICE_X112Y179}

# create_pblock PFB2
# add_cells_to_pblock [get_pblocks PFB2] [get_cells -quiet [list {chfpga0/CHANGEN[2].CHANi/IMPL_GEN.fft_blk.FFT0/FFT_GEN.fftype_gen.FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real}]]
# resize_pblock [get_pblocks PFB2] -add {RAMB36_X3Y25:RAMB36_X7Y30 RAMB36_X8Y24:RAMB36_X9Y30 RAMB36_X10Y24:RAMB36_X10Y32 RAMB36_X11Y24:RAMB36_X11Y27}
# resize_pblock [get_pblocks PFB2] -add {RAMB18_X3Y50:RAMB18_X7Y61 RAMB18_X8Y48:RAMB18_X9Y61 RAMB18_X10Y48:RAMB18_X10Y65 RAMB18_X11Y48:RAMB18_X11Y55}
# resize_pblock [get_pblocks PFB2] -add {SLICE_X32Y135:SLICE_X112Y154 SLICE_X105Y155:SLICE_X105Y164}
# resize_pblock [get_pblocks PFB2] -add {DSP48E2_X5Y54:DSP48E2_X22Y61}

# create_pblock SCALER2
# add_cells_to_pblock [get_pblocks SCALER2] [get_cells -quiet [list {chfpga0/CHANGEN[2].CHANi/IMPL_GEN.scaler_blk.SCALER0} {chfpga0/CHANGEN[2].CHANi/IMPL_GEN.fifo_blk.fifo0}]]
# resize_pblock [get_pblocks SCALER2] -add {RAMB36_X2Y24:RAMB36_X2Y35}
# resize_pblock [get_pblocks SCALER2] -add {RAMB18_X2Y48:RAMB18_X2Y71}
# resize_pblock [get_pblocks SCALER2] -add {SLICE_X26Y120:SLICE_X31Y179}
# resize_pblock [get_pblocks SCALER2] -add {DSP48E2_X3Y48:DSP48E2_X4Y71}

# create_pblock FFT_BIPLEX3
# add_cells_to_pblock [get_pblocks FFT_BIPLEX3] [get_cells -quiet [list {chfpga0/CHANGEN[3].CHANi/IMPL_GEN.fft_blk.FFT0/FFT_GEN.fftype_gen.FFT0/U0/pfb_fft_bitgrowth_struct/fft_wideband_real/fft_biplex_real_4x}]]
# resize_pblock [get_pblocks FFT_BIPLEX3] -add {RAMB36_X3Y43:RAMB36_X9Y47 RAMB36_X10Y45:RAMB36_X10Y47}
# resize_pblock [get_pblocks FFT_BIPLEX3] -add {RAMB18_X3Y86:RAMB18_X9Y95 RAMB18_X10Y90:RAMB18_X10Y95}
# resize_pblock [get_pblocks FFT_BIPLEX3] -add {SLICE_X32Y215:SLICE_X104Y239 SLICE_X105Y225:SLICE_X105Y239}
# resize_pblock [get_pblocks FFT_BIPLEX3] -add {DSP48E2_X5Y86:DSP48E2_X20Y95}

# create_pblock FFT_DIRECT3
# add_cells_to_pblock [get_pblocks FFT_DIRECT3] [get_cells -quiet [list {chfpga0/CHANGEN[3].CHANi/IMPL_GEN.fft_blk.FFT0/FFT_GEN.fftype_gen.FFT0/U0/pfb_fft_bitgrowth_struct/fft_wideband_real/fft_direct}]]
# resize_pblock [get_pblocks FFT_DIRECT3] -add {RAMB36_X3Y36:RAMB36_X7Y36}
# resize_pblock [get_pblocks FFT_DIRECT3] -add {RAMB18_X3Y72:RAMB18_X7Y73}
# resize_pblock [get_pblocks FFT_DIRECT3] -add {SLICE_X32Y180:SLICE_X112Y194}
# resize_pblock [get_pblocks FFT_DIRECT3] -add {DSP48E2_X5Y72:DSP48E2_X22Y77}

# create_pblock FUNCGEN3
# add_cells_to_pblock [get_pblocks FUNCGEN3] [get_cells -quiet [list {chfpga0/CHANGEN[3].CHANi/IMPL_GEN.funcgen_blk.FUNCGEN0}]]
# resize_pblock [get_pblocks FUNCGEN3] -add {RAMB36_X11Y40:RAMB36_X11Y47}
# resize_pblock [get_pblocks FUNCGEN3] -add {RAMB18_X11Y80:RAMB18_X11Y95}
# resize_pblock [get_pblocks FUNCGEN3] -add {SLICE_X106Y215:SLICE_X112Y239}

# create_pblock PFB3
# add_cells_to_pblock [get_pblocks PFB3] [get_cells -quiet [list {chfpga0/CHANGEN[3].CHANi/IMPL_GEN.fft_blk.FFT0/FFT_GEN.fftype_gen.FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real}]]
# resize_pblock [get_pblocks PFB3] -add {RAMB36_X3Y37:RAMB36_X7Y42 RAMB36_X8Y36:RAMB36_X9Y42 RAMB36_X10Y36:RAMB36_X10Y44 RAMB36_X11Y36:RAMB36_X11Y39}
# resize_pblock [get_pblocks PFB3] -add {RAMB18_X3Y74:RAMB18_X7Y85 RAMB18_X8Y72:RAMB18_X9Y85 RAMB18_X10Y72:RAMB18_X10Y89 RAMB18_X11Y72:RAMB18_X11Y79}
# resize_pblock [get_pblocks PFB3] -add {SLICE_X32Y195:SLICE_X112Y214 SLICE_X105Y215:SLICE_X105Y224}
# resize_pblock [get_pblocks PFB3] -add {DSP48E2_X5Y78:DSP48E2_X22Y85}

# create_pblock SCALER3
# add_cells_to_pblock [get_pblocks SCALER3] [get_cells -quiet [list {chfpga0/CHANGEN[3].CHANi/IMPL_GEN.scaler_blk.SCALER0} {chfpga0/CHANGEN[3].CHANi/IMPL_GEN.fifo_blk.fifo0}]]
# resize_pblock [get_pblocks SCALER3] -add {RAMB36_X2Y36:RAMB36_X2Y47}
# resize_pblock [get_pblocks SCALER3] -add {RAMB18_X2Y72:RAMB18_X2Y95}
# resize_pblock [get_pblocks SCALER3] -add {SLICE_X26Y180:SLICE_X31Y239}
# resize_pblock [get_pblocks SCALER3] -add {DSP48E2_X3Y72:DSP48E2_X4Y95}

# create_pblock FFT_BIPLEX4
# add_cells_to_pblock [get_pblocks FFT_BIPLEX4] [get_cells -quiet [list {chfpga0/CHANGEN[4].CHANi/IMPL_GEN.fft_blk.FFT0/FFT_GEN.fftype_gen.FFT0/U0/pfb_fft_bitgrowth_struct/fft_wideband_real/fft_biplex_real_4x}]]
# resize_pblock [get_pblocks FFT_BIPLEX4] -add {RAMB36_X3Y55:RAMB36_X9Y59 RAMB36_X10Y57:RAMB36_X10Y59}
# resize_pblock [get_pblocks FFT_BIPLEX4] -add {RAMB18_X3Y110:RAMB18_X9Y119 RAMB18_X10Y114:RAMB18_X10Y119}
# resize_pblock [get_pblocks FFT_BIPLEX4] -add {SLICE_X32Y275:SLICE_X104Y299 SLICE_X105Y285:SLICE_X105Y299}
# resize_pblock [get_pblocks FFT_BIPLEX4] -add {DSP48E2_X5Y110:DSP48E2_X20Y119}

# create_pblock FFT_DIRECT4
# add_cells_to_pblock [get_pblocks FFT_DIRECT4] [get_cells -quiet [list {chfpga0/CHANGEN[4].CHANi/IMPL_GEN.fft_blk.FFT0/FFT_GEN.fftype_gen.FFT0/U0/pfb_fft_bitgrowth_struct/fft_wideband_real/fft_direct}]]
# resize_pblock [get_pblocks FFT_DIRECT4] -add {RAMB36_X3Y48:RAMB36_X7Y48}
# resize_pblock [get_pblocks FFT_DIRECT4] -add {RAMB18_X3Y96:RAMB18_X7Y97}
# resize_pblock [get_pblocks FFT_DIRECT4] -add {SLICE_X32Y240:SLICE_X112Y254}
# resize_pblock [get_pblocks FFT_DIRECT4] -add {DSP48E2_X5Y96:DSP48E2_X22Y101}

# create_pblock FUNCGEN4
# add_cells_to_pblock [get_pblocks FUNCGEN4] [get_cells -quiet [list {chfpga0/CHANGEN[4].CHANi/IMPL_GEN.funcgen_blk.FUNCGEN0}]]
# resize_pblock [get_pblocks FUNCGEN4] -add {RAMB36_X11Y52:RAMB36_X11Y59}
# resize_pblock [get_pblocks FUNCGEN4] -add {RAMB18_X11Y104:RAMB18_X11Y119}
# resize_pblock [get_pblocks FUNCGEN4] -add {SLICE_X106Y275:SLICE_X112Y299}

# create_pblock PFB4
# add_cells_to_pblock [get_pblocks PFB4] [get_cells -quiet [list {chfpga0/CHANGEN[4].CHANi/IMPL_GEN.fft_blk.FFT0/FFT_GEN.fftype_gen.FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real}]]
# resize_pblock [get_pblocks PFB4] -add {RAMB36_X3Y49:RAMB36_X7Y54 RAMB36_X8Y48:RAMB36_X9Y54 RAMB36_X10Y48:RAMB36_X10Y56 RAMB36_X11Y48:RAMB36_X11Y51}
# resize_pblock [get_pblocks PFB4] -add {RAMB18_X3Y98:RAMB18_X7Y109 RAMB18_X8Y96:RAMB18_X9Y109 RAMB18_X10Y96:RAMB18_X10Y113 RAMB18_X11Y96:RAMB18_X11Y103}
# resize_pblock [get_pblocks PFB4] -add {SLICE_X32Y255:SLICE_X112Y274 SLICE_X105Y275:SLICE_X105Y284}
# resize_pblock [get_pblocks PFB4] -add {DSP48E2_X5Y102:DSP48E2_X22Y109}

# create_pblock SCALER4
# add_cells_to_pblock [get_pblocks SCALER4] [get_cells -quiet [list {chfpga0/CHANGEN[4].CHANi/IMPL_GEN.scaler_blk.SCALER0} {chfpga0/CHANGEN[4].CHANi/IMPL_GEN.fifo_blk.fifo0}]]
# resize_pblock [get_pblocks SCALER4] -add {RAMB36_X2Y48:RAMB36_X2Y59}
# resize_pblock [get_pblocks SCALER4] -add {RAMB18_X2Y96:RAMB18_X2Y119}
# resize_pblock [get_pblocks SCALER4] -add {SLICE_X26Y240:SLICE_X31Y299}
# resize_pblock [get_pblocks SCALER4] -add {DSP48E2_X3Y96:DSP48E2_X4Y119}

# create_pblock FFT_BIPLEX5
# add_cells_to_pblock [get_pblocks FFT_BIPLEX5] [get_cells -quiet [list {chfpga0/CHANGEN[5].CHANi/IMPL_GEN.fft_blk.FFT0/FFT_GEN.fftype_gen.FFT0/U0/pfb_fft_bitgrowth_struct/fft_wideband_real/fft_biplex_real_4x}]]
# resize_pblock [get_pblocks FFT_BIPLEX5] -add {RAMB36_X3Y67:RAMB36_X9Y71 RAMB36_X10Y69:RAMB36_X10Y71}
# resize_pblock [get_pblocks FFT_BIPLEX5] -add {RAMB18_X3Y134:RAMB18_X9Y143 RAMB18_X10Y138:RAMB18_X10Y143}
# resize_pblock [get_pblocks FFT_BIPLEX5] -add {SLICE_X32Y335:SLICE_X104Y359 SLICE_X105Y345:SLICE_X105Y359}
# resize_pblock [get_pblocks FFT_BIPLEX5] -add {DSP48E2_X5Y134:DSP48E2_X20Y143}

# create_pblock FFT_DIRECT5
# add_cells_to_pblock [get_pblocks FFT_DIRECT5] [get_cells -quiet [list {chfpga0/CHANGEN[5].CHANi/IMPL_GEN.fft_blk.FFT0/FFT_GEN.fftype_gen.FFT0/U0/pfb_fft_bitgrowth_struct/fft_wideband_real/fft_direct}]]
# resize_pblock [get_pblocks FFT_DIRECT5] -add {RAMB36_X3Y60:RAMB36_X7Y60}
# resize_pblock [get_pblocks FFT_DIRECT5] -add {RAMB18_X3Y120:RAMB18_X7Y121}
# resize_pblock [get_pblocks FFT_DIRECT5] -add {SLICE_X32Y300:SLICE_X112Y314}
# resize_pblock [get_pblocks FFT_DIRECT5] -add {DSP48E2_X5Y120:DSP48E2_X22Y125}

# create_pblock FUNCGEN5
# add_cells_to_pblock [get_pblocks FUNCGEN5] [get_cells -quiet [list {chfpga0/CHANGEN[5].CHANi/IMPL_GEN.funcgen_blk.FUNCGEN0}]]
# resize_pblock [get_pblocks FUNCGEN5] -add {RAMB36_X11Y64:RAMB36_X11Y71}
# resize_pblock [get_pblocks FUNCGEN5] -add {RAMB18_X11Y128:RAMB18_X11Y143}
# resize_pblock [get_pblocks FUNCGEN5] -add {SLICE_X106Y335:SLICE_X112Y359}

# create_pblock PFB5
# add_cells_to_pblock [get_pblocks PFB5] [get_cells -quiet [list {chfpga0/CHANGEN[5].CHANi/IMPL_GEN.fft_blk.FFT0/FFT_GEN.fftype_gen.FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real}]]
# resize_pblock [get_pblocks PFB5] -add {RAMB36_X3Y61:RAMB36_X7Y66 RAMB36_X8Y60:RAMB36_X9Y66 RAMB36_X10Y60:RAMB36_X10Y68 RAMB36_X11Y60:RAMB36_X11Y63}
# resize_pblock [get_pblocks PFB5] -add {RAMB18_X3Y122:RAMB18_X7Y133 RAMB18_X8Y120:RAMB18_X9Y133 RAMB18_X10Y120:RAMB18_X10Y137 RAMB18_X11Y120:RAMB18_X11Y127}
# resize_pblock [get_pblocks PFB5] -add {SLICE_X32Y315:SLICE_X112Y334 SLICE_X105Y335:SLICE_X105Y344}
# resize_pblock [get_pblocks PFB5] -add {DSP48E2_X5Y126:DSP48E2_X22Y133}

# create_pblock SCALER5
# add_cells_to_pblock [get_pblocks SCALER5] [get_cells -quiet [list {chfpga0/CHANGEN[5].CHANi/IMPL_GEN.scaler_blk.SCALER0} {chfpga0/CHANGEN[5].CHANi/IMPL_GEN.fifo_blk.fifo0}]]
# resize_pblock [get_pblocks SCALER5] -add {RAMB36_X2Y60:RAMB36_X2Y71}
# resize_pblock [get_pblocks SCALER5] -add {RAMB18_X2Y120:RAMB18_X2Y143}
# resize_pblock [get_pblocks SCALER5] -add {SLICE_X26Y300:SLICE_X31Y359}
# resize_pblock [get_pblocks SCALER5] -add {DSP48E2_X3Y120:DSP48E2_X4Y143}

# create_pblock FFT_BIPLEX6
# add_cells_to_pblock [get_pblocks FFT_BIPLEX6] [get_cells -quiet [list {chfpga0/CHANGEN[6].CHANi/IMPL_GEN.fft_blk.FFT0/FFT_GEN.fftype_gen.FFT0/U0/pfb_fft_bitgrowth_struct/fft_wideband_real/fft_biplex_real_4x}]]
# resize_pblock [get_pblocks FFT_BIPLEX6] -add {RAMB36_X3Y79:RAMB36_X9Y83 RAMB36_X10Y81:RAMB36_X10Y83}
# resize_pblock [get_pblocks FFT_BIPLEX6] -add {RAMB18_X3Y158:RAMB18_X9Y167 RAMB18_X10Y162:RAMB18_X10Y167}
# resize_pblock [get_pblocks FFT_BIPLEX6] -add {SLICE_X32Y395:SLICE_X104Y419 SLICE_X105Y405:SLICE_X105Y419}
# resize_pblock [get_pblocks FFT_BIPLEX6] -add {DSP48E2_X5Y158:DSP48E2_X20Y167}

# create_pblock FFT_DIRECT6
# add_cells_to_pblock [get_pblocks FFT_DIRECT6] [get_cells -quiet [list {chfpga0/CHANGEN[6].CHANi/IMPL_GEN.fft_blk.FFT0/FFT_GEN.fftype_gen.FFT0/U0/pfb_fft_bitgrowth_struct/fft_wideband_real/fft_direct}]]
# resize_pblock [get_pblocks FFT_DIRECT6] -add {RAMB36_X3Y72:RAMB36_X7Y72}
# resize_pblock [get_pblocks FFT_DIRECT6] -add {RAMB18_X3Y144:RAMB18_X7Y145}
# resize_pblock [get_pblocks FFT_DIRECT6] -add {SLICE_X32Y360:SLICE_X112Y374}
# resize_pblock [get_pblocks FFT_DIRECT6] -add {DSP48E2_X5Y144:DSP48E2_X22Y149}

# create_pblock FUNCGEN6
# add_cells_to_pblock [get_pblocks FUNCGEN6] [get_cells -quiet [list {chfpga0/CHANGEN[6].CHANi/IMPL_GEN.funcgen_blk.FUNCGEN0}]]
# resize_pblock [get_pblocks FUNCGEN6] -add {RAMB36_X11Y76:RAMB36_X11Y83}
# resize_pblock [get_pblocks FUNCGEN6] -add {RAMB18_X11Y152:RAMB18_X11Y167}
# resize_pblock [get_pblocks FUNCGEN6] -add {SLICE_X106Y395:SLICE_X112Y419}

# create_pblock PFB6
# add_cells_to_pblock [get_pblocks PFB6] [get_cells -quiet [list {chfpga0/CHANGEN[6].CHANi/IMPL_GEN.fft_blk.FFT0/FFT_GEN.fftype_gen.FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real}]]
# resize_pblock [get_pblocks PFB6] -add {RAMB36_X3Y73:RAMB36_X7Y78 RAMB36_X8Y72:RAMB36_X9Y78 RAMB36_X10Y72:RAMB36_X10Y80 RAMB36_X11Y72:RAMB36_X11Y75}
# resize_pblock [get_pblocks PFB6] -add {RAMB18_X3Y146:RAMB18_X7Y157 RAMB18_X8Y144:RAMB18_X9Y157 RAMB18_X10Y144:RAMB18_X10Y161 RAMB18_X11Y144:RAMB18_X11Y151}
# resize_pblock [get_pblocks PFB6] -add {SLICE_X32Y375:SLICE_X112Y394 SLICE_X105Y395:SLICE_X105Y404}
# resize_pblock [get_pblocks PFB6] -add {DSP48E2_X5Y150:DSP48E2_X22Y157}

# create_pblock SCALER6
# add_cells_to_pblock [get_pblocks SCALER6] [get_cells -quiet [list {chfpga0/CHANGEN[6].CHANi/IMPL_GEN.scaler_blk.SCALER0} {chfpga0/CHANGEN[6].CHANi/IMPL_GEN.fifo_blk.fifo0}]]
# resize_pblock [get_pblocks SCALER6] -add {RAMB36_X2Y72:RAMB36_X2Y83}
# resize_pblock [get_pblocks SCALER6] -add {RAMB18_X2Y144:RAMB18_X2Y167}
# resize_pblock [get_pblocks SCALER6] -add {SLICE_X26Y360:SLICE_X31Y419}
# resize_pblock [get_pblocks SCALER6] -add {DSP48E2_X3Y144:DSP48E2_X4Y167}

# create_pblock FFT_BIPLEX7
# add_cells_to_pblock [get_pblocks FFT_BIPLEX7] [get_cells -quiet [list {chfpga0/CHANGEN[7].CHANi/IMPL_GEN.fft_blk.FFT0/FFT_GEN.fftype_gen.FFT0/U0/pfb_fft_bitgrowth_struct/fft_wideband_real/fft_biplex_real_4x}]]
# resize_pblock [get_pblocks FFT_BIPLEX7] -add {RAMB36_X3Y91:RAMB36_X9Y95 RAMB36_X10Y93:RAMB36_X10Y95}
# resize_pblock [get_pblocks FFT_BIPLEX7] -add {RAMB18_X3Y182:RAMB18_X9Y191 RAMB18_X10Y186:RAMB18_X10Y191}
# resize_pblock [get_pblocks FFT_BIPLEX7] -add {SLICE_X32Y455:SLICE_X104Y479 SLICE_X105Y465:SLICE_X105Y479}
# resize_pblock [get_pblocks FFT_BIPLEX7] -add {DSP48E2_X5Y182:DSP48E2_X20Y191}

# create_pblock FFT_DIRECT7
# add_cells_to_pblock [get_pblocks FFT_DIRECT7] [get_cells -quiet [list {chfpga0/CHANGEN[7].CHANi/IMPL_GEN.fft_blk.FFT0/FFT_GEN.fftype_gen.FFT0/U0/pfb_fft_bitgrowth_struct/fft_wideband_real/fft_direct}]]
# resize_pblock [get_pblocks FFT_DIRECT7] -add {RAMB36_X3Y84:RAMB36_X7Y84}
# resize_pblock [get_pblocks FFT_DIRECT7] -add {RAMB18_X3Y168:RAMB18_X7Y169}
# resize_pblock [get_pblocks FFT_DIRECT7] -add {SLICE_X32Y420:SLICE_X112Y434}
# resize_pblock [get_pblocks FFT_DIRECT7] -add {DSP48E2_X5Y168:DSP48E2_X22Y173}

# create_pblock FUNCGEN7
# add_cells_to_pblock [get_pblocks FUNCGEN7] [get_cells -quiet [list {chfpga0/CHANGEN[7].CHANi/IMPL_GEN.funcgen_blk.FUNCGEN0}]]
# resize_pblock [get_pblocks FUNCGEN7] -add {RAMB36_X11Y88:RAMB36_X11Y95}
# resize_pblock [get_pblocks FUNCGEN7] -add {RAMB18_X11Y176:RAMB18_X11Y191}
# resize_pblock [get_pblocks FUNCGEN7] -add {SLICE_X106Y455:SLICE_X112Y479}

# create_pblock PFB7
# add_cells_to_pblock [get_pblocks PFB7] [get_cells -quiet [list {chfpga0/CHANGEN[7].CHANi/IMPL_GEN.fft_blk.FFT0/FFT_GEN.fftype_gen.FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real}]]
# resize_pblock [get_pblocks PFB7] -add {RAMB36_X3Y85:RAMB36_X7Y90 RAMB36_X8Y84:RAMB36_X9Y90 RAMB36_X10Y84:RAMB36_X10Y92 RAMB36_X11Y84:RAMB36_X11Y87}
# resize_pblock [get_pblocks PFB7] -add {RAMB18_X3Y170:RAMB18_X7Y181 RAMB18_X8Y168:RAMB18_X9Y181 RAMB18_X10Y168:RAMB18_X10Y185 RAMB18_X11Y168:RAMB18_X11Y175}
# resize_pblock [get_pblocks PFB7] -add {SLICE_X32Y435:SLICE_X112Y454 SLICE_X105Y455:SLICE_X105Y464}
# resize_pblock [get_pblocks PFB7] -add {DSP48E2_X5Y174:DSP48E2_X22Y181}

# create_pblock SCALER7
# add_cells_to_pblock [get_pblocks SCALER7] [get_cells -quiet [list {chfpga0/CHANGEN[7].CHANi/IMPL_GEN.scaler_blk.SCALER0} {chfpga0/CHANGEN[7].CHANi/IMPL_GEN.fifo_blk.fifo0}]]
# resize_pblock [get_pblocks SCALER7] -add {RAMB36_X2Y84:RAMB36_X2Y95}
# resize_pblock [get_pblocks SCALER7] -add {RAMB18_X2Y168:RAMB18_X2Y191}
# resize_pblock [get_pblocks SCALER7] -add {SLICE_X26Y420:SLICE_X31Y479}
# resize_pblock [get_pblocks SCALER7] -add {DSP48E2_X3Y168:DSP48E2_X4Y191}

# Allow last elements of SRLs to become registers to help timing
#set_property SRL_STYLE srl_reg [get_cells -hier -filter {PRIMITIVE_TYPE =~ CLB.SRL.* && NAME =~  "*FFT*" }]


# Pin the UCAP UltraRAM sites to facilitate P&R

# Pin the UCAP UltraRAM sites to facilitate P&R

set_property LOC URAM288_X0Y64 [get_cells {chfpga0/*ucap0/uram_gen[0]*/*/*_uram_0}]
set_property LOC URAM288_X0Y65 [get_cells {chfpga0/*ucap0/uram_gen[0]*/*/*_uram_1}]
set_property LOC URAM288_X0Y66 [get_cells {chfpga0/*ucap0/uram_gen[1]*/*/*_uram_0}]
set_property LOC URAM288_X0Y67 [get_cells {chfpga0/*ucap0/uram_gen[1]*/*/*_uram_1}]
set_property LOC URAM288_X0Y68 [get_cells {chfpga0/*ucap0/uram_gen[2]*/*/*_uram_0}]
set_property LOC URAM288_X0Y69 [get_cells {chfpga0/*ucap0/uram_gen[2]*/*/*_uram_1}]
set_property LOC URAM288_X0Y70 [get_cells {chfpga0/*ucap0/uram_gen[3]*/*/*_uram_0}]
set_property LOC URAM288_X0Y71 [get_cells {chfpga0/*ucap0/uram_gen[3]*/*/*_uram_1}]
set_property LOC URAM288_X0Y72 [get_cells {chfpga0/*ucap0/uram_gen[4]*/*/*_uram_0}]
set_property LOC URAM288_X0Y73 [get_cells {chfpga0/*ucap0/uram_gen[4]*/*/*_uram_1}]
set_property LOC URAM288_X0Y74 [get_cells {chfpga0/*ucap0/uram_gen[5]*/*/*_uram_0}]
set_property LOC URAM288_X0Y75 [get_cells {chfpga0/*ucap0/uram_gen[5]*/*/*_uram_1}]
set_property LOC URAM288_X0Y76 [get_cells {chfpga0/*ucap0/uram_gen[6]*/*/*_uram_0}]
set_property LOC URAM288_X0Y77 [get_cells {chfpga0/*ucap0/uram_gen[6]*/*/*_uram_1}]
set_property LOC URAM288_X0Y78 [get_cells {chfpga0/*ucap0/uram_gen[7]*/*/*_uram_0}]
set_property LOC URAM288_X0Y79 [get_cells {chfpga0/*ucap0/uram_gen[7]*/*/*_uram_1}]



# PFB BRAMs
set_property LOC RAMB36_X10Y6 [get_cells {chfpga0/CHANGEN[0]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X10Y5 [get_cells {chfpga0/CHANGEN[0]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X10Y4 [get_cells {chfpga0/CHANGEN[0]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X10Y3 [get_cells {chfpga0/CHANGEN[0]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X10Y2 [get_cells {chfpga0/CHANGEN[0]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in1_first_tap/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X10Y1 [get_cells {chfpga0/CHANGEN[0]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in1_tap2/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X10Y0 [get_cells {chfpga0/CHANGEN[0]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in1_tap3/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X9Y6 [get_cells {chfpga0/CHANGEN[0]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X9Y5 [get_cells {chfpga0/CHANGEN[0]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X9Y4 [get_cells {chfpga0/CHANGEN[0]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X9Y3 [get_cells {chfpga0/CHANGEN[0]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X9Y2 [get_cells {chfpga0/CHANGEN[0]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in2_first_tap/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X9Y1 [get_cells {chfpga0/CHANGEN[0]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in2_tap2/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X9Y0 [get_cells {chfpga0/CHANGEN[0]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in2_tap3/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X8Y6 [get_cells {chfpga0/CHANGEN[0]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X8Y5 [get_cells {chfpga0/CHANGEN[0]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X8Y4 [get_cells {chfpga0/CHANGEN[0]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X8Y3 [get_cells {chfpga0/CHANGEN[0]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X8Y2 [get_cells {chfpga0/CHANGEN[0]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in3_first_tap/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X8Y1 [get_cells {chfpga0/CHANGEN[0]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in3_tap2/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X8Y0 [get_cells {chfpga0/CHANGEN[0]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in3_tap3/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X7Y6 [get_cells {chfpga0/CHANGEN[0]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X7Y5 [get_cells {chfpga0/CHANGEN[0]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X7Y4 [get_cells {chfpga0/CHANGEN[0]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X7Y3 [get_cells {chfpga0/CHANGEN[0]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X7Y2 [get_cells {chfpga0/CHANGEN[0]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in4_first_tap/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X7Y1 [get_cells {chfpga0/CHANGEN[0]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in4_tap2/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X7Y0 [get_cells {chfpga0/CHANGEN[0]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in4_tap3/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X6Y6 [get_cells {chfpga0/CHANGEN[0]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in5_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X6Y5 [get_cells {chfpga0/CHANGEN[0]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in5_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X6Y4 [get_cells {chfpga0/CHANGEN[0]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in5_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X6Y3 [get_cells {chfpga0/CHANGEN[0]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in5_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X6Y2 [get_cells {chfpga0/CHANGEN[0]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in5_first_tap/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X6Y1 [get_cells {chfpga0/CHANGEN[0]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in5_tap2/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X6Y0 [get_cells {chfpga0/CHANGEN[0]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in5_tap3/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X5Y6 [get_cells {chfpga0/CHANGEN[0]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in6_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X5Y5 [get_cells {chfpga0/CHANGEN[0]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in6_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X5Y4 [get_cells {chfpga0/CHANGEN[0]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in6_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X5Y3 [get_cells {chfpga0/CHANGEN[0]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in6_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X5Y2 [get_cells {chfpga0/CHANGEN[0]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in6_first_tap/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X5Y1 [get_cells {chfpga0/CHANGEN[0]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in6_tap2/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X5Y0 [get_cells {chfpga0/CHANGEN[0]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in6_tap3/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X4Y6 [get_cells {chfpga0/CHANGEN[0]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in7_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X4Y5 [get_cells {chfpga0/CHANGEN[0]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in7_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X4Y4 [get_cells {chfpga0/CHANGEN[0]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in7_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X4Y3 [get_cells {chfpga0/CHANGEN[0]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in7_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X4Y2 [get_cells {chfpga0/CHANGEN[0]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in7_first_tap/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X4Y1 [get_cells {chfpga0/CHANGEN[0]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in7_tap2/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X4Y0 [get_cells {chfpga0/CHANGEN[0]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in7_tap3/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X3Y6 [get_cells {chfpga0/CHANGEN[0]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in8_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X3Y5 [get_cells {chfpga0/CHANGEN[0]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in8_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X3Y4 [get_cells {chfpga0/CHANGEN[0]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in8_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X3Y3 [get_cells {chfpga0/CHANGEN[0]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in8_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X3Y2 [get_cells {chfpga0/CHANGEN[0]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in8_first_tap/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X3Y1 [get_cells {chfpga0/CHANGEN[0]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in8_tap2/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X3Y0 [get_cells {chfpga0/CHANGEN[0]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in8_tap3/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X10Y18 [get_cells {chfpga0/CHANGEN[1]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X10Y17 [get_cells {chfpga0/CHANGEN[1]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X10Y16 [get_cells {chfpga0/CHANGEN[1]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X10Y15 [get_cells {chfpga0/CHANGEN[1]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X10Y14 [get_cells {chfpga0/CHANGEN[1]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in1_first_tap/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X10Y13 [get_cells {chfpga0/CHANGEN[1]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in1_tap2/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X10Y12 [get_cells {chfpga0/CHANGEN[1]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in1_tap3/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X9Y18 [get_cells {chfpga0/CHANGEN[1]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X9Y17 [get_cells {chfpga0/CHANGEN[1]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X9Y16 [get_cells {chfpga0/CHANGEN[1]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X9Y15 [get_cells {chfpga0/CHANGEN[1]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X9Y14 [get_cells {chfpga0/CHANGEN[1]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in2_first_tap/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X9Y13 [get_cells {chfpga0/CHANGEN[1]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in2_tap2/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X9Y12 [get_cells {chfpga0/CHANGEN[1]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in2_tap3/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X8Y18 [get_cells {chfpga0/CHANGEN[1]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X8Y17 [get_cells {chfpga0/CHANGEN[1]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X8Y16 [get_cells {chfpga0/CHANGEN[1]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X8Y15 [get_cells {chfpga0/CHANGEN[1]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X8Y14 [get_cells {chfpga0/CHANGEN[1]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in3_first_tap/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X8Y13 [get_cells {chfpga0/CHANGEN[1]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in3_tap2/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X8Y12 [get_cells {chfpga0/CHANGEN[1]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in3_tap3/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X7Y18 [get_cells {chfpga0/CHANGEN[1]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X7Y17 [get_cells {chfpga0/CHANGEN[1]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X7Y16 [get_cells {chfpga0/CHANGEN[1]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X7Y15 [get_cells {chfpga0/CHANGEN[1]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X7Y14 [get_cells {chfpga0/CHANGEN[1]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in4_first_tap/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X7Y13 [get_cells {chfpga0/CHANGEN[1]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in4_tap2/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X7Y12 [get_cells {chfpga0/CHANGEN[1]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in4_tap3/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X6Y18 [get_cells {chfpga0/CHANGEN[1]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in5_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X6Y17 [get_cells {chfpga0/CHANGEN[1]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in5_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X6Y16 [get_cells {chfpga0/CHANGEN[1]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in5_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X6Y15 [get_cells {chfpga0/CHANGEN[1]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in5_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X6Y14 [get_cells {chfpga0/CHANGEN[1]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in5_first_tap/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X6Y13 [get_cells {chfpga0/CHANGEN[1]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in5_tap2/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X6Y12 [get_cells {chfpga0/CHANGEN[1]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in5_tap3/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X5Y18 [get_cells {chfpga0/CHANGEN[1]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in6_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X5Y17 [get_cells {chfpga0/CHANGEN[1]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in6_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X5Y16 [get_cells {chfpga0/CHANGEN[1]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in6_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X5Y15 [get_cells {chfpga0/CHANGEN[1]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in6_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X5Y14 [get_cells {chfpga0/CHANGEN[1]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in6_first_tap/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X5Y13 [get_cells {chfpga0/CHANGEN[1]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in6_tap2/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X5Y12 [get_cells {chfpga0/CHANGEN[1]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in6_tap3/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X4Y18 [get_cells {chfpga0/CHANGEN[1]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in7_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X4Y17 [get_cells {chfpga0/CHANGEN[1]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in7_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X4Y16 [get_cells {chfpga0/CHANGEN[1]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in7_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X4Y15 [get_cells {chfpga0/CHANGEN[1]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in7_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X4Y14 [get_cells {chfpga0/CHANGEN[1]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in7_first_tap/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X4Y13 [get_cells {chfpga0/CHANGEN[1]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in7_tap2/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X4Y12 [get_cells {chfpga0/CHANGEN[1]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in7_tap3/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X3Y18 [get_cells {chfpga0/CHANGEN[1]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in8_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X3Y17 [get_cells {chfpga0/CHANGEN[1]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in8_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X3Y16 [get_cells {chfpga0/CHANGEN[1]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in8_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X3Y15 [get_cells {chfpga0/CHANGEN[1]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in8_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X3Y14 [get_cells {chfpga0/CHANGEN[1]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in8_first_tap/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X3Y13 [get_cells {chfpga0/CHANGEN[1]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in8_tap2/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X3Y12 [get_cells {chfpga0/CHANGEN[1]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in8_tap3/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X10Y30 [get_cells {chfpga0/CHANGEN[2]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X10Y29 [get_cells {chfpga0/CHANGEN[2]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X10Y28 [get_cells {chfpga0/CHANGEN[2]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X10Y27 [get_cells {chfpga0/CHANGEN[2]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X10Y26 [get_cells {chfpga0/CHANGEN[2]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in1_first_tap/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X10Y25 [get_cells {chfpga0/CHANGEN[2]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in1_tap2/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X10Y24 [get_cells {chfpga0/CHANGEN[2]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in1_tap3/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X9Y30 [get_cells {chfpga0/CHANGEN[2]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X9Y29 [get_cells {chfpga0/CHANGEN[2]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X9Y28 [get_cells {chfpga0/CHANGEN[2]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X9Y27 [get_cells {chfpga0/CHANGEN[2]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X9Y26 [get_cells {chfpga0/CHANGEN[2]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in2_first_tap/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X9Y25 [get_cells {chfpga0/CHANGEN[2]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in2_tap2/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X9Y24 [get_cells {chfpga0/CHANGEN[2]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in2_tap3/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X8Y30 [get_cells {chfpga0/CHANGEN[2]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X8Y29 [get_cells {chfpga0/CHANGEN[2]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X8Y28 [get_cells {chfpga0/CHANGEN[2]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X8Y27 [get_cells {chfpga0/CHANGEN[2]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X8Y26 [get_cells {chfpga0/CHANGEN[2]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in3_first_tap/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X8Y25 [get_cells {chfpga0/CHANGEN[2]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in3_tap2/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X8Y24 [get_cells {chfpga0/CHANGEN[2]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in3_tap3/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X7Y30 [get_cells {chfpga0/CHANGEN[2]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X7Y29 [get_cells {chfpga0/CHANGEN[2]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X7Y28 [get_cells {chfpga0/CHANGEN[2]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X7Y27 [get_cells {chfpga0/CHANGEN[2]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X7Y26 [get_cells {chfpga0/CHANGEN[2]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in4_first_tap/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X7Y25 [get_cells {chfpga0/CHANGEN[2]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in4_tap2/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X7Y24 [get_cells {chfpga0/CHANGEN[2]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in4_tap3/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X6Y30 [get_cells {chfpga0/CHANGEN[2]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in5_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X6Y29 [get_cells {chfpga0/CHANGEN[2]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in5_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X6Y28 [get_cells {chfpga0/CHANGEN[2]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in5_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X6Y27 [get_cells {chfpga0/CHANGEN[2]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in5_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X6Y26 [get_cells {chfpga0/CHANGEN[2]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in5_first_tap/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X6Y25 [get_cells {chfpga0/CHANGEN[2]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in5_tap2/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X6Y24 [get_cells {chfpga0/CHANGEN[2]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in5_tap3/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X5Y30 [get_cells {chfpga0/CHANGEN[2]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in6_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X5Y29 [get_cells {chfpga0/CHANGEN[2]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in6_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X5Y28 [get_cells {chfpga0/CHANGEN[2]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in6_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X5Y27 [get_cells {chfpga0/CHANGEN[2]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in6_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X5Y26 [get_cells {chfpga0/CHANGEN[2]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in6_first_tap/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X5Y25 [get_cells {chfpga0/CHANGEN[2]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in6_tap2/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X5Y24 [get_cells {chfpga0/CHANGEN[2]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in6_tap3/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X4Y30 [get_cells {chfpga0/CHANGEN[2]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in7_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X4Y29 [get_cells {chfpga0/CHANGEN[2]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in7_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X4Y28 [get_cells {chfpga0/CHANGEN[2]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in7_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X4Y27 [get_cells {chfpga0/CHANGEN[2]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in7_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X4Y26 [get_cells {chfpga0/CHANGEN[2]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in7_first_tap/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X4Y25 [get_cells {chfpga0/CHANGEN[2]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in7_tap2/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X4Y24 [get_cells {chfpga0/CHANGEN[2]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in7_tap3/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X3Y30 [get_cells {chfpga0/CHANGEN[2]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in8_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X3Y29 [get_cells {chfpga0/CHANGEN[2]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in8_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X3Y28 [get_cells {chfpga0/CHANGEN[2]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in8_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X3Y27 [get_cells {chfpga0/CHANGEN[2]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in8_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X3Y26 [get_cells {chfpga0/CHANGEN[2]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in8_first_tap/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X3Y25 [get_cells {chfpga0/CHANGEN[2]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in8_tap2/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X3Y24 [get_cells {chfpga0/CHANGEN[2]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in8_tap3/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X10Y42 [get_cells {chfpga0/CHANGEN[3]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X10Y41 [get_cells {chfpga0/CHANGEN[3]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X10Y40 [get_cells {chfpga0/CHANGEN[3]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X10Y39 [get_cells {chfpga0/CHANGEN[3]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X10Y38 [get_cells {chfpga0/CHANGEN[3]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in1_first_tap/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X10Y37 [get_cells {chfpga0/CHANGEN[3]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in1_tap2/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X10Y36 [get_cells {chfpga0/CHANGEN[3]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in1_tap3/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X9Y42 [get_cells {chfpga0/CHANGEN[3]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X9Y41 [get_cells {chfpga0/CHANGEN[3]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X9Y40 [get_cells {chfpga0/CHANGEN[3]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X9Y39 [get_cells {chfpga0/CHANGEN[3]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X9Y38 [get_cells {chfpga0/CHANGEN[3]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in2_first_tap/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X9Y37 [get_cells {chfpga0/CHANGEN[3]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in2_tap2/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X9Y36 [get_cells {chfpga0/CHANGEN[3]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in2_tap3/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X8Y42 [get_cells {chfpga0/CHANGEN[3]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X8Y41 [get_cells {chfpga0/CHANGEN[3]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X8Y40 [get_cells {chfpga0/CHANGEN[3]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X8Y39 [get_cells {chfpga0/CHANGEN[3]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X8Y38 [get_cells {chfpga0/CHANGEN[3]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in3_first_tap/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X8Y37 [get_cells {chfpga0/CHANGEN[3]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in3_tap2/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X8Y36 [get_cells {chfpga0/CHANGEN[3]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in3_tap3/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X7Y42 [get_cells {chfpga0/CHANGEN[3]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X7Y41 [get_cells {chfpga0/CHANGEN[3]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X7Y40 [get_cells {chfpga0/CHANGEN[3]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X7Y39 [get_cells {chfpga0/CHANGEN[3]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X7Y38 [get_cells {chfpga0/CHANGEN[3]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in4_first_tap/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X7Y37 [get_cells {chfpga0/CHANGEN[3]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in4_tap2/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X7Y36 [get_cells {chfpga0/CHANGEN[3]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in4_tap3/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X6Y42 [get_cells {chfpga0/CHANGEN[3]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in5_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X6Y41 [get_cells {chfpga0/CHANGEN[3]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in5_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X6Y40 [get_cells {chfpga0/CHANGEN[3]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in5_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X6Y39 [get_cells {chfpga0/CHANGEN[3]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in5_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X6Y38 [get_cells {chfpga0/CHANGEN[3]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in5_first_tap/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X6Y37 [get_cells {chfpga0/CHANGEN[3]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in5_tap2/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X6Y36 [get_cells {chfpga0/CHANGEN[3]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in5_tap3/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X5Y42 [get_cells {chfpga0/CHANGEN[3]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in6_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X5Y41 [get_cells {chfpga0/CHANGEN[3]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in6_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X5Y40 [get_cells {chfpga0/CHANGEN[3]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in6_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X5Y39 [get_cells {chfpga0/CHANGEN[3]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in6_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X5Y38 [get_cells {chfpga0/CHANGEN[3]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in6_first_tap/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X5Y37 [get_cells {chfpga0/CHANGEN[3]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in6_tap2/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X5Y36 [get_cells {chfpga0/CHANGEN[3]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in6_tap3/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X4Y42 [get_cells {chfpga0/CHANGEN[3]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in7_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X4Y41 [get_cells {chfpga0/CHANGEN[3]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in7_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X4Y40 [get_cells {chfpga0/CHANGEN[3]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in7_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X4Y39 [get_cells {chfpga0/CHANGEN[3]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in7_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X4Y38 [get_cells {chfpga0/CHANGEN[3]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in7_first_tap/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X4Y37 [get_cells {chfpga0/CHANGEN[3]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in7_tap2/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X4Y36 [get_cells {chfpga0/CHANGEN[3]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in7_tap3/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X3Y42 [get_cells {chfpga0/CHANGEN[3]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in8_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X3Y41 [get_cells {chfpga0/CHANGEN[3]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in8_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X3Y40 [get_cells {chfpga0/CHANGEN[3]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in8_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X3Y39 [get_cells {chfpga0/CHANGEN[3]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in8_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X3Y38 [get_cells {chfpga0/CHANGEN[3]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in8_first_tap/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X3Y37 [get_cells {chfpga0/CHANGEN[3]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in8_tap2/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X3Y36 [get_cells {chfpga0/CHANGEN[3]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in8_tap3/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X10Y54 [get_cells {chfpga0/CHANGEN[4]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X10Y53 [get_cells {chfpga0/CHANGEN[4]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X10Y52 [get_cells {chfpga0/CHANGEN[4]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X10Y51 [get_cells {chfpga0/CHANGEN[4]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X10Y50 [get_cells {chfpga0/CHANGEN[4]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in1_first_tap/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X10Y49 [get_cells {chfpga0/CHANGEN[4]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in1_tap2/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X10Y48 [get_cells {chfpga0/CHANGEN[4]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in1_tap3/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X9Y54 [get_cells {chfpga0/CHANGEN[4]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X9Y53 [get_cells {chfpga0/CHANGEN[4]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X9Y52 [get_cells {chfpga0/CHANGEN[4]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X9Y51 [get_cells {chfpga0/CHANGEN[4]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X9Y50 [get_cells {chfpga0/CHANGEN[4]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in2_first_tap/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X9Y49 [get_cells {chfpga0/CHANGEN[4]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in2_tap2/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X9Y48 [get_cells {chfpga0/CHANGEN[4]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in2_tap3/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X8Y54 [get_cells {chfpga0/CHANGEN[4]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X8Y53 [get_cells {chfpga0/CHANGEN[4]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X8Y52 [get_cells {chfpga0/CHANGEN[4]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X8Y51 [get_cells {chfpga0/CHANGEN[4]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X8Y50 [get_cells {chfpga0/CHANGEN[4]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in3_first_tap/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X8Y49 [get_cells {chfpga0/CHANGEN[4]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in3_tap2/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X8Y48 [get_cells {chfpga0/CHANGEN[4]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in3_tap3/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X7Y54 [get_cells {chfpga0/CHANGEN[4]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X7Y53 [get_cells {chfpga0/CHANGEN[4]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X7Y52 [get_cells {chfpga0/CHANGEN[4]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X7Y51 [get_cells {chfpga0/CHANGEN[4]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X7Y50 [get_cells {chfpga0/CHANGEN[4]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in4_first_tap/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X7Y49 [get_cells {chfpga0/CHANGEN[4]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in4_tap2/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X7Y48 [get_cells {chfpga0/CHANGEN[4]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in4_tap3/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X6Y54 [get_cells {chfpga0/CHANGEN[4]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in5_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X6Y53 [get_cells {chfpga0/CHANGEN[4]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in5_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X6Y52 [get_cells {chfpga0/CHANGEN[4]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in5_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X6Y51 [get_cells {chfpga0/CHANGEN[4]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in5_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X6Y50 [get_cells {chfpga0/CHANGEN[4]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in5_first_tap/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X6Y49 [get_cells {chfpga0/CHANGEN[4]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in5_tap2/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X6Y48 [get_cells {chfpga0/CHANGEN[4]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in5_tap3/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X5Y54 [get_cells {chfpga0/CHANGEN[4]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in6_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X5Y53 [get_cells {chfpga0/CHANGEN[4]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in6_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X5Y52 [get_cells {chfpga0/CHANGEN[4]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in6_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X5Y51 [get_cells {chfpga0/CHANGEN[4]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in6_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X5Y50 [get_cells {chfpga0/CHANGEN[4]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in6_first_tap/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X5Y49 [get_cells {chfpga0/CHANGEN[4]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in6_tap2/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X5Y48 [get_cells {chfpga0/CHANGEN[4]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in6_tap3/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X4Y54 [get_cells {chfpga0/CHANGEN[4]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in7_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X4Y53 [get_cells {chfpga0/CHANGEN[4]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in7_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X4Y52 [get_cells {chfpga0/CHANGEN[4]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in7_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X4Y51 [get_cells {chfpga0/CHANGEN[4]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in7_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X4Y50 [get_cells {chfpga0/CHANGEN[4]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in7_first_tap/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X4Y49 [get_cells {chfpga0/CHANGEN[4]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in7_tap2/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X4Y48 [get_cells {chfpga0/CHANGEN[4]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in7_tap3/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X3Y54 [get_cells {chfpga0/CHANGEN[4]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in8_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X3Y53 [get_cells {chfpga0/CHANGEN[4]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in8_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X3Y52 [get_cells {chfpga0/CHANGEN[4]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in8_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X3Y51 [get_cells {chfpga0/CHANGEN[4]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in8_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X3Y50 [get_cells {chfpga0/CHANGEN[4]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in8_first_tap/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X3Y49 [get_cells {chfpga0/CHANGEN[4]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in8_tap2/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X3Y48 [get_cells {chfpga0/CHANGEN[4]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in8_tap3/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X10Y66 [get_cells {chfpga0/CHANGEN[5]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X10Y65 [get_cells {chfpga0/CHANGEN[5]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X10Y64 [get_cells {chfpga0/CHANGEN[5]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X10Y63 [get_cells {chfpga0/CHANGEN[5]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X10Y62 [get_cells {chfpga0/CHANGEN[5]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in1_first_tap/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X10Y61 [get_cells {chfpga0/CHANGEN[5]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in1_tap2/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X10Y60 [get_cells {chfpga0/CHANGEN[5]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in1_tap3/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X9Y66 [get_cells {chfpga0/CHANGEN[5]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X9Y65 [get_cells {chfpga0/CHANGEN[5]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X9Y64 [get_cells {chfpga0/CHANGEN[5]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X9Y63 [get_cells {chfpga0/CHANGEN[5]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X9Y62 [get_cells {chfpga0/CHANGEN[5]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in2_first_tap/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X9Y61 [get_cells {chfpga0/CHANGEN[5]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in2_tap2/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X9Y60 [get_cells {chfpga0/CHANGEN[5]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in2_tap3/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X8Y66 [get_cells {chfpga0/CHANGEN[5]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X8Y65 [get_cells {chfpga0/CHANGEN[5]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X8Y64 [get_cells {chfpga0/CHANGEN[5]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X8Y63 [get_cells {chfpga0/CHANGEN[5]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X8Y62 [get_cells {chfpga0/CHANGEN[5]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in3_first_tap/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X8Y61 [get_cells {chfpga0/CHANGEN[5]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in3_tap2/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X8Y60 [get_cells {chfpga0/CHANGEN[5]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in3_tap3/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X7Y66 [get_cells {chfpga0/CHANGEN[5]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X7Y65 [get_cells {chfpga0/CHANGEN[5]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X7Y64 [get_cells {chfpga0/CHANGEN[5]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X7Y63 [get_cells {chfpga0/CHANGEN[5]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X7Y62 [get_cells {chfpga0/CHANGEN[5]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in4_first_tap/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X7Y61 [get_cells {chfpga0/CHANGEN[5]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in4_tap2/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X7Y60 [get_cells {chfpga0/CHANGEN[5]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in4_tap3/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X6Y66 [get_cells {chfpga0/CHANGEN[5]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in5_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X6Y65 [get_cells {chfpga0/CHANGEN[5]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in5_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X6Y64 [get_cells {chfpga0/CHANGEN[5]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in5_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X6Y63 [get_cells {chfpga0/CHANGEN[5]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in5_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X6Y62 [get_cells {chfpga0/CHANGEN[5]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in5_first_tap/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X6Y61 [get_cells {chfpga0/CHANGEN[5]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in5_tap2/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X6Y60 [get_cells {chfpga0/CHANGEN[5]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in5_tap3/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X5Y66 [get_cells {chfpga0/CHANGEN[5]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in6_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X5Y65 [get_cells {chfpga0/CHANGEN[5]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in6_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X5Y64 [get_cells {chfpga0/CHANGEN[5]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in6_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X5Y63 [get_cells {chfpga0/CHANGEN[5]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in6_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X5Y62 [get_cells {chfpga0/CHANGEN[5]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in6_first_tap/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X5Y61 [get_cells {chfpga0/CHANGEN[5]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in6_tap2/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X5Y60 [get_cells {chfpga0/CHANGEN[5]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in6_tap3/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X4Y66 [get_cells {chfpga0/CHANGEN[5]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in7_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X4Y65 [get_cells {chfpga0/CHANGEN[5]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in7_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X4Y64 [get_cells {chfpga0/CHANGEN[5]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in7_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X4Y63 [get_cells {chfpga0/CHANGEN[5]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in7_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X4Y62 [get_cells {chfpga0/CHANGEN[5]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in7_first_tap/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X4Y61 [get_cells {chfpga0/CHANGEN[5]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in7_tap2/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X4Y60 [get_cells {chfpga0/CHANGEN[5]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in7_tap3/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X3Y66 [get_cells {chfpga0/CHANGEN[5]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in8_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X3Y65 [get_cells {chfpga0/CHANGEN[5]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in8_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X3Y64 [get_cells {chfpga0/CHANGEN[5]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in8_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X3Y63 [get_cells {chfpga0/CHANGEN[5]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in8_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X3Y62 [get_cells {chfpga0/CHANGEN[5]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in8_first_tap/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X3Y61 [get_cells {chfpga0/CHANGEN[5]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in8_tap2/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X3Y60 [get_cells {chfpga0/CHANGEN[5]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in8_tap3/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X10Y78 [get_cells {chfpga0/CHANGEN[6]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X10Y77 [get_cells {chfpga0/CHANGEN[6]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X10Y76 [get_cells {chfpga0/CHANGEN[6]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X10Y75 [get_cells {chfpga0/CHANGEN[6]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X10Y74 [get_cells {chfpga0/CHANGEN[6]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in1_first_tap/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X10Y73 [get_cells {chfpga0/CHANGEN[6]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in1_tap2/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X10Y72 [get_cells {chfpga0/CHANGEN[6]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in1_tap3/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X9Y78 [get_cells {chfpga0/CHANGEN[6]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X9Y77 [get_cells {chfpga0/CHANGEN[6]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X9Y76 [get_cells {chfpga0/CHANGEN[6]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X9Y75 [get_cells {chfpga0/CHANGEN[6]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X9Y74 [get_cells {chfpga0/CHANGEN[6]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in2_first_tap/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X9Y73 [get_cells {chfpga0/CHANGEN[6]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in2_tap2/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X9Y72 [get_cells {chfpga0/CHANGEN[6]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in2_tap3/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X8Y78 [get_cells {chfpga0/CHANGEN[6]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X8Y77 [get_cells {chfpga0/CHANGEN[6]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X8Y76 [get_cells {chfpga0/CHANGEN[6]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X8Y75 [get_cells {chfpga0/CHANGEN[6]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X8Y74 [get_cells {chfpga0/CHANGEN[6]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in3_first_tap/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X8Y73 [get_cells {chfpga0/CHANGEN[6]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in3_tap2/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X8Y72 [get_cells {chfpga0/CHANGEN[6]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in3_tap3/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X7Y78 [get_cells {chfpga0/CHANGEN[6]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X7Y77 [get_cells {chfpga0/CHANGEN[6]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X7Y76 [get_cells {chfpga0/CHANGEN[6]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X7Y75 [get_cells {chfpga0/CHANGEN[6]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X7Y74 [get_cells {chfpga0/CHANGEN[6]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in4_first_tap/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X7Y73 [get_cells {chfpga0/CHANGEN[6]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in4_tap2/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X7Y72 [get_cells {chfpga0/CHANGEN[6]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in4_tap3/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X6Y78 [get_cells {chfpga0/CHANGEN[6]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in5_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X6Y77 [get_cells {chfpga0/CHANGEN[6]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in5_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X6Y76 [get_cells {chfpga0/CHANGEN[6]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in5_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X6Y75 [get_cells {chfpga0/CHANGEN[6]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in5_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X6Y74 [get_cells {chfpga0/CHANGEN[6]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in5_first_tap/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X6Y73 [get_cells {chfpga0/CHANGEN[6]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in5_tap2/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X6Y72 [get_cells {chfpga0/CHANGEN[6]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in5_tap3/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X5Y78 [get_cells {chfpga0/CHANGEN[6]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in6_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X5Y77 [get_cells {chfpga0/CHANGEN[6]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in6_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X5Y76 [get_cells {chfpga0/CHANGEN[6]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in6_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X5Y75 [get_cells {chfpga0/CHANGEN[6]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in6_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X5Y74 [get_cells {chfpga0/CHANGEN[6]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in6_first_tap/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X5Y73 [get_cells {chfpga0/CHANGEN[6]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in6_tap2/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X5Y72 [get_cells {chfpga0/CHANGEN[6]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in6_tap3/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X4Y78 [get_cells {chfpga0/CHANGEN[6]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in7_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X4Y77 [get_cells {chfpga0/CHANGEN[6]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in7_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X4Y76 [get_cells {chfpga0/CHANGEN[6]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in7_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X4Y75 [get_cells {chfpga0/CHANGEN[6]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in7_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X4Y74 [get_cells {chfpga0/CHANGEN[6]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in7_first_tap/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X4Y73 [get_cells {chfpga0/CHANGEN[6]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in7_tap2/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X4Y72 [get_cells {chfpga0/CHANGEN[6]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in7_tap3/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X3Y78 [get_cells {chfpga0/CHANGEN[6]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in8_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X3Y77 [get_cells {chfpga0/CHANGEN[6]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in8_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X3Y76 [get_cells {chfpga0/CHANGEN[6]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in8_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X3Y75 [get_cells {chfpga0/CHANGEN[6]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in8_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X3Y74 [get_cells {chfpga0/CHANGEN[6]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in8_first_tap/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X3Y73 [get_cells {chfpga0/CHANGEN[6]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in8_tap2/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X3Y72 [get_cells {chfpga0/CHANGEN[6]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in8_tap3/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X10Y90 [get_cells {chfpga0/CHANGEN[7]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X10Y89 [get_cells {chfpga0/CHANGEN[7]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X10Y88 [get_cells {chfpga0/CHANGEN[7]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X10Y87 [get_cells {chfpga0/CHANGEN[7]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X10Y86 [get_cells {chfpga0/CHANGEN[7]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in1_first_tap/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X10Y85 [get_cells {chfpga0/CHANGEN[7]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in1_tap2/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X10Y84 [get_cells {chfpga0/CHANGEN[7]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in1_tap3/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X9Y90 [get_cells {chfpga0/CHANGEN[7]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X9Y89 [get_cells {chfpga0/CHANGEN[7]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X9Y88 [get_cells {chfpga0/CHANGEN[7]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X9Y87 [get_cells {chfpga0/CHANGEN[7]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X9Y86 [get_cells {chfpga0/CHANGEN[7]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in2_first_tap/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X9Y85 [get_cells {chfpga0/CHANGEN[7]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in2_tap2/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X9Y84 [get_cells {chfpga0/CHANGEN[7]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in2_tap3/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X8Y90 [get_cells {chfpga0/CHANGEN[7]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X8Y89 [get_cells {chfpga0/CHANGEN[7]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X8Y88 [get_cells {chfpga0/CHANGEN[7]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X8Y87 [get_cells {chfpga0/CHANGEN[7]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X8Y86 [get_cells {chfpga0/CHANGEN[7]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in3_first_tap/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X8Y85 [get_cells {chfpga0/CHANGEN[7]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in3_tap2/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X8Y84 [get_cells {chfpga0/CHANGEN[7]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in3_tap3/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X7Y90 [get_cells {chfpga0/CHANGEN[7]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X7Y89 [get_cells {chfpga0/CHANGEN[7]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X7Y88 [get_cells {chfpga0/CHANGEN[7]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X7Y87 [get_cells {chfpga0/CHANGEN[7]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X7Y86 [get_cells {chfpga0/CHANGEN[7]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in4_first_tap/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X7Y85 [get_cells {chfpga0/CHANGEN[7]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in4_tap2/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X7Y84 [get_cells {chfpga0/CHANGEN[7]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in4_tap3/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X6Y90 [get_cells {chfpga0/CHANGEN[7]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in5_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X6Y89 [get_cells {chfpga0/CHANGEN[7]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in5_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X6Y88 [get_cells {chfpga0/CHANGEN[7]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in5_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X6Y87 [get_cells {chfpga0/CHANGEN[7]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in5_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X6Y86 [get_cells {chfpga0/CHANGEN[7]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in5_first_tap/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X6Y85 [get_cells {chfpga0/CHANGEN[7]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in5_tap2/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X6Y84 [get_cells {chfpga0/CHANGEN[7]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in5_tap3/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X5Y90 [get_cells {chfpga0/CHANGEN[7]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in6_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X5Y89 [get_cells {chfpga0/CHANGEN[7]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in6_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X5Y88 [get_cells {chfpga0/CHANGEN[7]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in6_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X5Y87 [get_cells {chfpga0/CHANGEN[7]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in6_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X5Y86 [get_cells {chfpga0/CHANGEN[7]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in6_first_tap/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X5Y85 [get_cells {chfpga0/CHANGEN[7]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in6_tap2/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X5Y84 [get_cells {chfpga0/CHANGEN[7]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in6_tap3/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X4Y90 [get_cells {chfpga0/CHANGEN[7]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in7_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X4Y89 [get_cells {chfpga0/CHANGEN[7]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in7_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X4Y88 [get_cells {chfpga0/CHANGEN[7]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in7_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X4Y87 [get_cells {chfpga0/CHANGEN[7]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in7_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X4Y86 [get_cells {chfpga0/CHANGEN[7]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in7_first_tap/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X4Y85 [get_cells {chfpga0/CHANGEN[7]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in7_tap2/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X4Y84 [get_cells {chfpga0/CHANGEN[7]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in7_tap3/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X3Y90 [get_cells {chfpga0/CHANGEN[7]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in8_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X3Y89 [get_cells {chfpga0/CHANGEN[7]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in8_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X3Y88 [get_cells {chfpga0/CHANGEN[7]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in8_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X3Y87 [get_cells {chfpga0/CHANGEN[7]*/*FFT0/*FFT0/U0/*/pfb_fir_real/pol1_in8_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB36_X3Y86 [get_cells {chfpga0/CHANGEN[7]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in8_first_tap/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X3Y85 [get_cells {chfpga0/CHANGEN[7]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in8_tap2/delay_bram/ram/xpm_memory*/*/*_bram_0}]
set_property LOC RAMB36_X3Y84 [get_cells {chfpga0/CHANGEN[7]*/*FFT0/*FFT0/U0/pfb_fft_bitgrowth_struct/pfb_fir_real/pol1_in8_tap3/delay_bram/ram/xpm_memory*/*/*_bram_0}]

# SCALER BRAMs & DSPs
set_property LOC RAMB36_X2Y0 [get_cells {chfpga0/CHANGEN[0].CHANi/IMPL_GEN.scaler_blk.SCALER0/coeff_ram0/xpm_memory*/*bram_0}]
set_property LOC RAMB36_X2Y1 [get_cells {chfpga0/CHANGEN[0].CHANi/IMPL_GEN.scaler_blk.SCALER0/coeff_ram0/xpm_memory*/*bram_1}]
set_property LOC RAMB36_X2Y2 [get_cells {chfpga0/CHANGEN[0].CHANi/IMPL_GEN.scaler_blk.SCALER0/coeff_ram0/xpm_memory*/*bram_2}]
set_property LOC RAMB36_X2Y3 [get_cells {chfpga0/CHANGEN[0].CHANi/IMPL_GEN.scaler_blk.SCALER0/coeff_ram0/xpm_memory*/*bram_3}]
set_property LOC RAMB36_X2Y4 [get_cells {chfpga0/CHANGEN[0].CHANi/IMPL_GEN.scaler_blk.SCALER0/coeff_ram0/xpm_memory*/*bram_4}]
set_property LOC RAMB36_X2Y5 [get_cells {chfpga0/CHANGEN[0].CHANi/IMPL_GEN.scaler_blk.SCALER0/coeff_ram0/xpm_memory*/*bram_5}]
set_property LOC RAMB36_X2Y6 [get_cells {chfpga0/CHANGEN[0].CHANi/IMPL_GEN.scaler_blk.SCALER0/coeff_ram0/xpm_memory*/*bram_6}]
set_property LOC RAMB36_X2Y7 [get_cells {chfpga0/CHANGEN[0].CHANi/IMPL_GEN.scaler_blk.SCALER0/coeff_ram0/xpm_memory*/*bram_7}]
set_property LOC DSP48E2_X3Y0 [get_cells {chfpga0/CHANGEN[0].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[0].rmul0/dsp1*}]
set_property LOC DSP48E2_X3Y1 [get_cells {chfpga0/CHANGEN[0].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[0].rmul0/dsp2*}]
set_property LOC DSP48E2_X3Y2 [get_cells {chfpga0/CHANGEN[0].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[1].rmul0/dsp1*}]
set_property LOC DSP48E2_X3Y3 [get_cells {chfpga0/CHANGEN[0].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[1].rmul0/dsp2*}]
set_property LOC DSP48E2_X3Y4 [get_cells {chfpga0/CHANGEN[0].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[2].rmul0/dsp1*}]
set_property LOC DSP48E2_X3Y5 [get_cells {chfpga0/CHANGEN[0].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[2].rmul0/dsp2*}]
set_property LOC DSP48E2_X3Y6 [get_cells {chfpga0/CHANGEN[0].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[3].rmul0/dsp1*}]
set_property LOC DSP48E2_X3Y7 [get_cells {chfpga0/CHANGEN[0].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[3].rmul0/dsp2*}]
set_property LOC DSP48E2_X3Y8 [get_cells {chfpga0/CHANGEN[0].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[4].rmul0/dsp1*}]
set_property LOC DSP48E2_X3Y9 [get_cells {chfpga0/CHANGEN[0].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[4].rmul0/dsp2*}]
set_property LOC DSP48E2_X3Y10 [get_cells {chfpga0/CHANGEN[0].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[5].rmul0/dsp1*}]
set_property LOC DSP48E2_X3Y11 [get_cells {chfpga0/CHANGEN[0].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[5].rmul0/dsp2*}]
set_property LOC DSP48E2_X3Y12 [get_cells {chfpga0/CHANGEN[0].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[6].rmul0/dsp1*}]
set_property LOC DSP48E2_X3Y13 [get_cells {chfpga0/CHANGEN[0].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[6].rmul0/dsp2*}]
set_property LOC DSP48E2_X3Y14 [get_cells {chfpga0/CHANGEN[0].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[7].rmul0/dsp1*}]
set_property LOC DSP48E2_X3Y15 [get_cells {chfpga0/CHANGEN[0].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[7].rmul0/dsp2*}]
set_property LOC RAMB36_X2Y12 [get_cells {chfpga0/CHANGEN[1].CHANi/IMPL_GEN.scaler_blk.SCALER0/coeff_ram0/xpm_memory*/*bram_0}]
set_property LOC RAMB36_X2Y13 [get_cells {chfpga0/CHANGEN[1].CHANi/IMPL_GEN.scaler_blk.SCALER0/coeff_ram0/xpm_memory*/*bram_1}]
set_property LOC RAMB36_X2Y14 [get_cells {chfpga0/CHANGEN[1].CHANi/IMPL_GEN.scaler_blk.SCALER0/coeff_ram0/xpm_memory*/*bram_2}]
set_property LOC RAMB36_X2Y15 [get_cells {chfpga0/CHANGEN[1].CHANi/IMPL_GEN.scaler_blk.SCALER0/coeff_ram0/xpm_memory*/*bram_3}]
set_property LOC RAMB36_X2Y16 [get_cells {chfpga0/CHANGEN[1].CHANi/IMPL_GEN.scaler_blk.SCALER0/coeff_ram0/xpm_memory*/*bram_4}]
set_property LOC RAMB36_X2Y17 [get_cells {chfpga0/CHANGEN[1].CHANi/IMPL_GEN.scaler_blk.SCALER0/coeff_ram0/xpm_memory*/*bram_5}]
set_property LOC RAMB36_X2Y18 [get_cells {chfpga0/CHANGEN[1].CHANi/IMPL_GEN.scaler_blk.SCALER0/coeff_ram0/xpm_memory*/*bram_6}]
set_property LOC RAMB36_X2Y19 [get_cells {chfpga0/CHANGEN[1].CHANi/IMPL_GEN.scaler_blk.SCALER0/coeff_ram0/xpm_memory*/*bram_7}]
set_property LOC DSP48E2_X3Y24 [get_cells {chfpga0/CHANGEN[1].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[0].rmul0/dsp1*}]
set_property LOC DSP48E2_X3Y25 [get_cells {chfpga0/CHANGEN[1].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[0].rmul0/dsp2*}]
set_property LOC DSP48E2_X3Y26 [get_cells {chfpga0/CHANGEN[1].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[1].rmul0/dsp1*}]
set_property LOC DSP48E2_X3Y27 [get_cells {chfpga0/CHANGEN[1].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[1].rmul0/dsp2*}]
set_property LOC DSP48E2_X3Y28 [get_cells {chfpga0/CHANGEN[1].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[2].rmul0/dsp1*}]
set_property LOC DSP48E2_X3Y29 [get_cells {chfpga0/CHANGEN[1].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[2].rmul0/dsp2*}]
set_property LOC DSP48E2_X3Y30 [get_cells {chfpga0/CHANGEN[1].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[3].rmul0/dsp1*}]
set_property LOC DSP48E2_X3Y31 [get_cells {chfpga0/CHANGEN[1].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[3].rmul0/dsp2*}]
set_property LOC DSP48E2_X3Y32 [get_cells {chfpga0/CHANGEN[1].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[4].rmul0/dsp1*}]
set_property LOC DSP48E2_X3Y33 [get_cells {chfpga0/CHANGEN[1].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[4].rmul0/dsp2*}]
set_property LOC DSP48E2_X3Y34 [get_cells {chfpga0/CHANGEN[1].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[5].rmul0/dsp1*}]
set_property LOC DSP48E2_X3Y35 [get_cells {chfpga0/CHANGEN[1].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[5].rmul0/dsp2*}]
set_property LOC DSP48E2_X3Y36 [get_cells {chfpga0/CHANGEN[1].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[6].rmul0/dsp1*}]
set_property LOC DSP48E2_X3Y37 [get_cells {chfpga0/CHANGEN[1].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[6].rmul0/dsp2*}]
set_property LOC DSP48E2_X3Y38 [get_cells {chfpga0/CHANGEN[1].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[7].rmul0/dsp1*}]
set_property LOC DSP48E2_X3Y39 [get_cells {chfpga0/CHANGEN[1].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[7].rmul0/dsp2*}]
set_property LOC RAMB36_X2Y24 [get_cells {chfpga0/CHANGEN[2].CHANi/IMPL_GEN.scaler_blk.SCALER0/coeff_ram0/xpm_memory*/*bram_0}]
set_property LOC RAMB36_X2Y25 [get_cells {chfpga0/CHANGEN[2].CHANi/IMPL_GEN.scaler_blk.SCALER0/coeff_ram0/xpm_memory*/*bram_1}]
set_property LOC RAMB36_X2Y26 [get_cells {chfpga0/CHANGEN[2].CHANi/IMPL_GEN.scaler_blk.SCALER0/coeff_ram0/xpm_memory*/*bram_2}]
set_property LOC RAMB36_X2Y27 [get_cells {chfpga0/CHANGEN[2].CHANi/IMPL_GEN.scaler_blk.SCALER0/coeff_ram0/xpm_memory*/*bram_3}]
set_property LOC RAMB36_X2Y28 [get_cells {chfpga0/CHANGEN[2].CHANi/IMPL_GEN.scaler_blk.SCALER0/coeff_ram0/xpm_memory*/*bram_4}]
set_property LOC RAMB36_X2Y29 [get_cells {chfpga0/CHANGEN[2].CHANi/IMPL_GEN.scaler_blk.SCALER0/coeff_ram0/xpm_memory*/*bram_5}]
set_property LOC RAMB36_X2Y30 [get_cells {chfpga0/CHANGEN[2].CHANi/IMPL_GEN.scaler_blk.SCALER0/coeff_ram0/xpm_memory*/*bram_6}]
set_property LOC RAMB36_X2Y31 [get_cells {chfpga0/CHANGEN[2].CHANi/IMPL_GEN.scaler_blk.SCALER0/coeff_ram0/xpm_memory*/*bram_7}]
set_property LOC DSP48E2_X3Y48 [get_cells {chfpga0/CHANGEN[2].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[0].rmul0/dsp1*}]
set_property LOC DSP48E2_X3Y49 [get_cells {chfpga0/CHANGEN[2].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[0].rmul0/dsp2*}]
set_property LOC DSP48E2_X3Y50 [get_cells {chfpga0/CHANGEN[2].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[1].rmul0/dsp1*}]
set_property LOC DSP48E2_X3Y51 [get_cells {chfpga0/CHANGEN[2].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[1].rmul0/dsp2*}]
set_property LOC DSP48E2_X3Y52 [get_cells {chfpga0/CHANGEN[2].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[2].rmul0/dsp1*}]
set_property LOC DSP48E2_X3Y53 [get_cells {chfpga0/CHANGEN[2].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[2].rmul0/dsp2*}]
set_property LOC DSP48E2_X3Y54 [get_cells {chfpga0/CHANGEN[2].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[3].rmul0/dsp1*}]
set_property LOC DSP48E2_X3Y55 [get_cells {chfpga0/CHANGEN[2].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[3].rmul0/dsp2*}]
set_property LOC DSP48E2_X3Y56 [get_cells {chfpga0/CHANGEN[2].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[4].rmul0/dsp1*}]
set_property LOC DSP48E2_X3Y57 [get_cells {chfpga0/CHANGEN[2].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[4].rmul0/dsp2*}]
set_property LOC DSP48E2_X3Y58 [get_cells {chfpga0/CHANGEN[2].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[5].rmul0/dsp1*}]
set_property LOC DSP48E2_X3Y59 [get_cells {chfpga0/CHANGEN[2].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[5].rmul0/dsp2*}]
set_property LOC DSP48E2_X3Y60 [get_cells {chfpga0/CHANGEN[2].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[6].rmul0/dsp1*}]
set_property LOC DSP48E2_X3Y61 [get_cells {chfpga0/CHANGEN[2].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[6].rmul0/dsp2*}]
set_property LOC DSP48E2_X3Y62 [get_cells {chfpga0/CHANGEN[2].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[7].rmul0/dsp1*}]
set_property LOC DSP48E2_X3Y63 [get_cells {chfpga0/CHANGEN[2].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[7].rmul0/dsp2*}]
set_property LOC RAMB36_X2Y36 [get_cells {chfpga0/CHANGEN[3].CHANi/IMPL_GEN.scaler_blk.SCALER0/coeff_ram0/xpm_memory*/*bram_0}]
set_property LOC RAMB36_X2Y37 [get_cells {chfpga0/CHANGEN[3].CHANi/IMPL_GEN.scaler_blk.SCALER0/coeff_ram0/xpm_memory*/*bram_1}]
set_property LOC RAMB36_X2Y38 [get_cells {chfpga0/CHANGEN[3].CHANi/IMPL_GEN.scaler_blk.SCALER0/coeff_ram0/xpm_memory*/*bram_2}]
set_property LOC RAMB36_X2Y39 [get_cells {chfpga0/CHANGEN[3].CHANi/IMPL_GEN.scaler_blk.SCALER0/coeff_ram0/xpm_memory*/*bram_3}]
set_property LOC RAMB36_X2Y40 [get_cells {chfpga0/CHANGEN[3].CHANi/IMPL_GEN.scaler_blk.SCALER0/coeff_ram0/xpm_memory*/*bram_4}]
set_property LOC RAMB36_X2Y41 [get_cells {chfpga0/CHANGEN[3].CHANi/IMPL_GEN.scaler_blk.SCALER0/coeff_ram0/xpm_memory*/*bram_5}]
set_property LOC RAMB36_X2Y42 [get_cells {chfpga0/CHANGEN[3].CHANi/IMPL_GEN.scaler_blk.SCALER0/coeff_ram0/xpm_memory*/*bram_6}]
set_property LOC RAMB36_X2Y43 [get_cells {chfpga0/CHANGEN[3].CHANi/IMPL_GEN.scaler_blk.SCALER0/coeff_ram0/xpm_memory*/*bram_7}]
set_property LOC DSP48E2_X3Y72 [get_cells {chfpga0/CHANGEN[3].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[0].rmul0/dsp1*}]
set_property LOC DSP48E2_X3Y73 [get_cells {chfpga0/CHANGEN[3].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[0].rmul0/dsp2*}]
set_property LOC DSP48E2_X3Y74 [get_cells {chfpga0/CHANGEN[3].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[1].rmul0/dsp1*}]
set_property LOC DSP48E2_X3Y75 [get_cells {chfpga0/CHANGEN[3].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[1].rmul0/dsp2*}]
set_property LOC DSP48E2_X3Y76 [get_cells {chfpga0/CHANGEN[3].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[2].rmul0/dsp1*}]
set_property LOC DSP48E2_X3Y77 [get_cells {chfpga0/CHANGEN[3].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[2].rmul0/dsp2*}]
set_property LOC DSP48E2_X3Y78 [get_cells {chfpga0/CHANGEN[3].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[3].rmul0/dsp1*}]
set_property LOC DSP48E2_X3Y79 [get_cells {chfpga0/CHANGEN[3].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[3].rmul0/dsp2*}]
set_property LOC DSP48E2_X3Y80 [get_cells {chfpga0/CHANGEN[3].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[4].rmul0/dsp1*}]
set_property LOC DSP48E2_X3Y81 [get_cells {chfpga0/CHANGEN[3].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[4].rmul0/dsp2*}]
set_property LOC DSP48E2_X3Y82 [get_cells {chfpga0/CHANGEN[3].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[5].rmul0/dsp1*}]
set_property LOC DSP48E2_X3Y83 [get_cells {chfpga0/CHANGEN[3].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[5].rmul0/dsp2*}]
set_property LOC DSP48E2_X3Y84 [get_cells {chfpga0/CHANGEN[3].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[6].rmul0/dsp1*}]
set_property LOC DSP48E2_X3Y85 [get_cells {chfpga0/CHANGEN[3].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[6].rmul0/dsp2*}]
set_property LOC DSP48E2_X3Y86 [get_cells {chfpga0/CHANGEN[3].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[7].rmul0/dsp1*}]
set_property LOC DSP48E2_X3Y87 [get_cells {chfpga0/CHANGEN[3].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[7].rmul0/dsp2*}]
set_property LOC RAMB36_X2Y48 [get_cells {chfpga0/CHANGEN[4].CHANi/IMPL_GEN.scaler_blk.SCALER0/coeff_ram0/xpm_memory*/*bram_0}]
set_property LOC RAMB36_X2Y49 [get_cells {chfpga0/CHANGEN[4].CHANi/IMPL_GEN.scaler_blk.SCALER0/coeff_ram0/xpm_memory*/*bram_1}]
set_property LOC RAMB36_X2Y50 [get_cells {chfpga0/CHANGEN[4].CHANi/IMPL_GEN.scaler_blk.SCALER0/coeff_ram0/xpm_memory*/*bram_2}]
set_property LOC RAMB36_X2Y51 [get_cells {chfpga0/CHANGEN[4].CHANi/IMPL_GEN.scaler_blk.SCALER0/coeff_ram0/xpm_memory*/*bram_3}]
set_property LOC RAMB36_X2Y52 [get_cells {chfpga0/CHANGEN[4].CHANi/IMPL_GEN.scaler_blk.SCALER0/coeff_ram0/xpm_memory*/*bram_4}]
set_property LOC RAMB36_X2Y53 [get_cells {chfpga0/CHANGEN[4].CHANi/IMPL_GEN.scaler_blk.SCALER0/coeff_ram0/xpm_memory*/*bram_5}]
set_property LOC RAMB36_X2Y54 [get_cells {chfpga0/CHANGEN[4].CHANi/IMPL_GEN.scaler_blk.SCALER0/coeff_ram0/xpm_memory*/*bram_6}]
set_property LOC RAMB36_X2Y55 [get_cells {chfpga0/CHANGEN[4].CHANi/IMPL_GEN.scaler_blk.SCALER0/coeff_ram0/xpm_memory*/*bram_7}]
set_property LOC DSP48E2_X3Y96 [get_cells {chfpga0/CHANGEN[4].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[0].rmul0/dsp1*}]
set_property LOC DSP48E2_X3Y97 [get_cells {chfpga0/CHANGEN[4].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[0].rmul0/dsp2*}]
set_property LOC DSP48E2_X3Y98 [get_cells {chfpga0/CHANGEN[4].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[1].rmul0/dsp1*}]
set_property LOC DSP48E2_X3Y99 [get_cells {chfpga0/CHANGEN[4].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[1].rmul0/dsp2*}]
set_property LOC DSP48E2_X3Y100 [get_cells {chfpga0/CHANGEN[4].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[2].rmul0/dsp1*}]
set_property LOC DSP48E2_X3Y101 [get_cells {chfpga0/CHANGEN[4].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[2].rmul0/dsp2*}]
set_property LOC DSP48E2_X3Y102 [get_cells {chfpga0/CHANGEN[4].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[3].rmul0/dsp1*}]
set_property LOC DSP48E2_X3Y103 [get_cells {chfpga0/CHANGEN[4].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[3].rmul0/dsp2*}]
set_property LOC DSP48E2_X3Y104 [get_cells {chfpga0/CHANGEN[4].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[4].rmul0/dsp1*}]
set_property LOC DSP48E2_X3Y105 [get_cells {chfpga0/CHANGEN[4].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[4].rmul0/dsp2*}]
set_property LOC DSP48E2_X3Y106 [get_cells {chfpga0/CHANGEN[4].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[5].rmul0/dsp1*}]
set_property LOC DSP48E2_X3Y107 [get_cells {chfpga0/CHANGEN[4].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[5].rmul0/dsp2*}]
set_property LOC DSP48E2_X3Y108 [get_cells {chfpga0/CHANGEN[4].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[6].rmul0/dsp1*}]
set_property LOC DSP48E2_X3Y109 [get_cells {chfpga0/CHANGEN[4].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[6].rmul0/dsp2*}]
set_property LOC DSP48E2_X3Y110 [get_cells {chfpga0/CHANGEN[4].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[7].rmul0/dsp1*}]
set_property LOC DSP48E2_X3Y111 [get_cells {chfpga0/CHANGEN[4].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[7].rmul0/dsp2*}]
set_property LOC RAMB36_X2Y60 [get_cells {chfpga0/CHANGEN[5].CHANi/IMPL_GEN.scaler_blk.SCALER0/coeff_ram0/xpm_memory*/*bram_0}]
set_property LOC RAMB36_X2Y61 [get_cells {chfpga0/CHANGEN[5].CHANi/IMPL_GEN.scaler_blk.SCALER0/coeff_ram0/xpm_memory*/*bram_1}]
set_property LOC RAMB36_X2Y62 [get_cells {chfpga0/CHANGEN[5].CHANi/IMPL_GEN.scaler_blk.SCALER0/coeff_ram0/xpm_memory*/*bram_2}]
set_property LOC RAMB36_X2Y63 [get_cells {chfpga0/CHANGEN[5].CHANi/IMPL_GEN.scaler_blk.SCALER0/coeff_ram0/xpm_memory*/*bram_3}]
set_property LOC RAMB36_X2Y64 [get_cells {chfpga0/CHANGEN[5].CHANi/IMPL_GEN.scaler_blk.SCALER0/coeff_ram0/xpm_memory*/*bram_4}]
set_property LOC RAMB36_X2Y65 [get_cells {chfpga0/CHANGEN[5].CHANi/IMPL_GEN.scaler_blk.SCALER0/coeff_ram0/xpm_memory*/*bram_5}]
set_property LOC RAMB36_X2Y66 [get_cells {chfpga0/CHANGEN[5].CHANi/IMPL_GEN.scaler_blk.SCALER0/coeff_ram0/xpm_memory*/*bram_6}]
set_property LOC RAMB36_X2Y67 [get_cells {chfpga0/CHANGEN[5].CHANi/IMPL_GEN.scaler_blk.SCALER0/coeff_ram0/xpm_memory*/*bram_7}]
set_property LOC DSP48E2_X3Y120 [get_cells {chfpga0/CHANGEN[5].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[0].rmul0/dsp1*}]
set_property LOC DSP48E2_X3Y121 [get_cells {chfpga0/CHANGEN[5].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[0].rmul0/dsp2*}]
set_property LOC DSP48E2_X3Y122 [get_cells {chfpga0/CHANGEN[5].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[1].rmul0/dsp1*}]
set_property LOC DSP48E2_X3Y123 [get_cells {chfpga0/CHANGEN[5].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[1].rmul0/dsp2*}]
set_property LOC DSP48E2_X3Y124 [get_cells {chfpga0/CHANGEN[5].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[2].rmul0/dsp1*}]
set_property LOC DSP48E2_X3Y125 [get_cells {chfpga0/CHANGEN[5].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[2].rmul0/dsp2*}]
set_property LOC DSP48E2_X3Y126 [get_cells {chfpga0/CHANGEN[5].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[3].rmul0/dsp1*}]
set_property LOC DSP48E2_X3Y127 [get_cells {chfpga0/CHANGEN[5].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[3].rmul0/dsp2*}]
set_property LOC DSP48E2_X3Y128 [get_cells {chfpga0/CHANGEN[5].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[4].rmul0/dsp1*}]
set_property LOC DSP48E2_X3Y129 [get_cells {chfpga0/CHANGEN[5].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[4].rmul0/dsp2*}]
set_property LOC DSP48E2_X3Y130 [get_cells {chfpga0/CHANGEN[5].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[5].rmul0/dsp1*}]
set_property LOC DSP48E2_X3Y131 [get_cells {chfpga0/CHANGEN[5].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[5].rmul0/dsp2*}]
set_property LOC DSP48E2_X3Y132 [get_cells {chfpga0/CHANGEN[5].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[6].rmul0/dsp1*}]
set_property LOC DSP48E2_X3Y133 [get_cells {chfpga0/CHANGEN[5].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[6].rmul0/dsp2*}]
set_property LOC DSP48E2_X3Y134 [get_cells {chfpga0/CHANGEN[5].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[7].rmul0/dsp1*}]
set_property LOC DSP48E2_X3Y135 [get_cells {chfpga0/CHANGEN[5].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[7].rmul0/dsp2*}]
set_property LOC RAMB36_X2Y72 [get_cells {chfpga0/CHANGEN[6].CHANi/IMPL_GEN.scaler_blk.SCALER0/coeff_ram0/xpm_memory*/*bram_0}]
set_property LOC RAMB36_X2Y73 [get_cells {chfpga0/CHANGEN[6].CHANi/IMPL_GEN.scaler_blk.SCALER0/coeff_ram0/xpm_memory*/*bram_1}]
set_property LOC RAMB36_X2Y74 [get_cells {chfpga0/CHANGEN[6].CHANi/IMPL_GEN.scaler_blk.SCALER0/coeff_ram0/xpm_memory*/*bram_2}]
set_property LOC RAMB36_X2Y75 [get_cells {chfpga0/CHANGEN[6].CHANi/IMPL_GEN.scaler_blk.SCALER0/coeff_ram0/xpm_memory*/*bram_3}]
set_property LOC RAMB36_X2Y76 [get_cells {chfpga0/CHANGEN[6].CHANi/IMPL_GEN.scaler_blk.SCALER0/coeff_ram0/xpm_memory*/*bram_4}]
set_property LOC RAMB36_X2Y77 [get_cells {chfpga0/CHANGEN[6].CHANi/IMPL_GEN.scaler_blk.SCALER0/coeff_ram0/xpm_memory*/*bram_5}]
set_property LOC RAMB36_X2Y78 [get_cells {chfpga0/CHANGEN[6].CHANi/IMPL_GEN.scaler_blk.SCALER0/coeff_ram0/xpm_memory*/*bram_6}]
set_property LOC RAMB36_X2Y79 [get_cells {chfpga0/CHANGEN[6].CHANi/IMPL_GEN.scaler_blk.SCALER0/coeff_ram0/xpm_memory*/*bram_7}]
set_property LOC DSP48E2_X3Y144 [get_cells {chfpga0/CHANGEN[6].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[0].rmul0/dsp1*}]
set_property LOC DSP48E2_X3Y145 [get_cells {chfpga0/CHANGEN[6].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[0].rmul0/dsp2*}]
set_property LOC DSP48E2_X3Y146 [get_cells {chfpga0/CHANGEN[6].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[1].rmul0/dsp1*}]
set_property LOC DSP48E2_X3Y147 [get_cells {chfpga0/CHANGEN[6].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[1].rmul0/dsp2*}]
set_property LOC DSP48E2_X3Y148 [get_cells {chfpga0/CHANGEN[6].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[2].rmul0/dsp1*}]
set_property LOC DSP48E2_X3Y149 [get_cells {chfpga0/CHANGEN[6].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[2].rmul0/dsp2*}]
set_property LOC DSP48E2_X3Y150 [get_cells {chfpga0/CHANGEN[6].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[3].rmul0/dsp1*}]
set_property LOC DSP48E2_X3Y151 [get_cells {chfpga0/CHANGEN[6].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[3].rmul0/dsp2*}]
set_property LOC DSP48E2_X3Y152 [get_cells {chfpga0/CHANGEN[6].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[4].rmul0/dsp1*}]
set_property LOC DSP48E2_X3Y153 [get_cells {chfpga0/CHANGEN[6].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[4].rmul0/dsp2*}]
set_property LOC DSP48E2_X3Y154 [get_cells {chfpga0/CHANGEN[6].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[5].rmul0/dsp1*}]
set_property LOC DSP48E2_X3Y155 [get_cells {chfpga0/CHANGEN[6].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[5].rmul0/dsp2*}]
set_property LOC DSP48E2_X3Y156 [get_cells {chfpga0/CHANGEN[6].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[6].rmul0/dsp1*}]
set_property LOC DSP48E2_X3Y157 [get_cells {chfpga0/CHANGEN[6].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[6].rmul0/dsp2*}]
set_property LOC DSP48E2_X3Y158 [get_cells {chfpga0/CHANGEN[6].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[7].rmul0/dsp1*}]
set_property LOC DSP48E2_X3Y159 [get_cells {chfpga0/CHANGEN[6].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[7].rmul0/dsp2*}]
set_property LOC RAMB36_X2Y84 [get_cells {chfpga0/CHANGEN[7].CHANi/IMPL_GEN.scaler_blk.SCALER0/coeff_ram0/xpm_memory*/*bram_0}]
set_property LOC RAMB36_X2Y85 [get_cells {chfpga0/CHANGEN[7].CHANi/IMPL_GEN.scaler_blk.SCALER0/coeff_ram0/xpm_memory*/*bram_1}]
set_property LOC RAMB36_X2Y86 [get_cells {chfpga0/CHANGEN[7].CHANi/IMPL_GEN.scaler_blk.SCALER0/coeff_ram0/xpm_memory*/*bram_2}]
set_property LOC RAMB36_X2Y87 [get_cells {chfpga0/CHANGEN[7].CHANi/IMPL_GEN.scaler_blk.SCALER0/coeff_ram0/xpm_memory*/*bram_3}]
set_property LOC RAMB36_X2Y88 [get_cells {chfpga0/CHANGEN[7].CHANi/IMPL_GEN.scaler_blk.SCALER0/coeff_ram0/xpm_memory*/*bram_4}]
set_property LOC RAMB36_X2Y89 [get_cells {chfpga0/CHANGEN[7].CHANi/IMPL_GEN.scaler_blk.SCALER0/coeff_ram0/xpm_memory*/*bram_5}]
set_property LOC RAMB36_X2Y90 [get_cells {chfpga0/CHANGEN[7].CHANi/IMPL_GEN.scaler_blk.SCALER0/coeff_ram0/xpm_memory*/*bram_6}]
set_property LOC RAMB36_X2Y91 [get_cells {chfpga0/CHANGEN[7].CHANi/IMPL_GEN.scaler_blk.SCALER0/coeff_ram0/xpm_memory*/*bram_7}]
set_property LOC DSP48E2_X3Y168 [get_cells {chfpga0/CHANGEN[7].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[0].rmul0/dsp1*}]
set_property LOC DSP48E2_X3Y169 [get_cells {chfpga0/CHANGEN[7].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[0].rmul0/dsp2*}]
set_property LOC DSP48E2_X3Y170 [get_cells {chfpga0/CHANGEN[7].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[1].rmul0/dsp1*}]
set_property LOC DSP48E2_X3Y171 [get_cells {chfpga0/CHANGEN[7].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[1].rmul0/dsp2*}]
set_property LOC DSP48E2_X3Y172 [get_cells {chfpga0/CHANGEN[7].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[2].rmul0/dsp1*}]
set_property LOC DSP48E2_X3Y173 [get_cells {chfpga0/CHANGEN[7].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[2].rmul0/dsp2*}]
set_property LOC DSP48E2_X3Y174 [get_cells {chfpga0/CHANGEN[7].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[3].rmul0/dsp1*}]
set_property LOC DSP48E2_X3Y175 [get_cells {chfpga0/CHANGEN[7].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[3].rmul0/dsp2*}]
set_property LOC DSP48E2_X3Y176 [get_cells {chfpga0/CHANGEN[7].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[4].rmul0/dsp1*}]
set_property LOC DSP48E2_X3Y177 [get_cells {chfpga0/CHANGEN[7].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[4].rmul0/dsp2*}]
set_property LOC DSP48E2_X3Y178 [get_cells {chfpga0/CHANGEN[7].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[5].rmul0/dsp1*}]
set_property LOC DSP48E2_X3Y179 [get_cells {chfpga0/CHANGEN[7].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[5].rmul0/dsp2*}]
set_property LOC DSP48E2_X3Y180 [get_cells {chfpga0/CHANGEN[7].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[6].rmul0/dsp1*}]
set_property LOC DSP48E2_X3Y181 [get_cells {chfpga0/CHANGEN[7].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[6].rmul0/dsp2*}]
set_property LOC DSP48E2_X3Y182 [get_cells {chfpga0/CHANGEN[7].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[7].rmul0/dsp1*}]
set_property LOC DSP48E2_X3Y183 [get_cells {chfpga0/CHANGEN[7].CHANi/IMPL_GEN.scaler_blk.SCALER0/mul_gen.gen_rmul[7].rmul0/dsp2*}]

# FUNCGEN BRAMs
set_property LOC RAMB36_X11Y0 [get_cells {chfpga0/CHANGEN[0].CHANi/*FUNCGEN0/*ram0/*/*bram_0}]
set_property LOC RAMB36_X11Y1 [get_cells {chfpga0/CHANGEN[0].CHANi/*FUNCGEN0/*ram0/*/*bram_1}]
set_property LOC RAMB36_X11Y2 [get_cells {chfpga0/CHANGEN[0].CHANi/*FUNCGEN0/*ram0/*/*bram_2}]
set_property LOC RAMB36_X11Y3 [get_cells {chfpga0/CHANGEN[0].CHANi/*FUNCGEN0/*ram0/*/*bram_3}]
set_property LOC RAMB36_X11Y4 [get_cells {chfpga0/CHANGEN[0].CHANi/*FUNCGEN0/*ram0/*/*bram_4}]
set_property LOC RAMB36_X11Y5 [get_cells {chfpga0/CHANGEN[0].CHANi/*FUNCGEN0/*ram0/*/*bram_5}]
set_property LOC RAMB36_X11Y6 [get_cells {chfpga0/CHANGEN[0].CHANi/*FUNCGEN0/*ram0/*/*bram_6}]
set_property LOC RAMB36_X11Y7 [get_cells {chfpga0/CHANGEN[0].CHANi/*FUNCGEN0/*ram0/*/*bram_7}]
set_property LOC RAMB36_X11Y12 [get_cells {chfpga0/CHANGEN[1].CHANi/*FUNCGEN0/*ram0/*/*bram_0}]
set_property LOC RAMB36_X11Y13 [get_cells {chfpga0/CHANGEN[1].CHANi/*FUNCGEN0/*ram0/*/*bram_1}]
set_property LOC RAMB36_X11Y14 [get_cells {chfpga0/CHANGEN[1].CHANi/*FUNCGEN0/*ram0/*/*bram_2}]
set_property LOC RAMB36_X11Y15 [get_cells {chfpga0/CHANGEN[1].CHANi/*FUNCGEN0/*ram0/*/*bram_3}]
set_property LOC RAMB36_X11Y16 [get_cells {chfpga0/CHANGEN[1].CHANi/*FUNCGEN0/*ram0/*/*bram_4}]
set_property LOC RAMB36_X11Y17 [get_cells {chfpga0/CHANGEN[1].CHANi/*FUNCGEN0/*ram0/*/*bram_5}]
set_property LOC RAMB36_X11Y18 [get_cells {chfpga0/CHANGEN[1].CHANi/*FUNCGEN0/*ram0/*/*bram_6}]
set_property LOC RAMB36_X11Y19 [get_cells {chfpga0/CHANGEN[1].CHANi/*FUNCGEN0/*ram0/*/*bram_7}]
set_property LOC RAMB36_X11Y24 [get_cells {chfpga0/CHANGEN[2].CHANi/*FUNCGEN0/*ram0/*/*bram_0}]
set_property LOC RAMB36_X11Y25 [get_cells {chfpga0/CHANGEN[2].CHANi/*FUNCGEN0/*ram0/*/*bram_1}]
set_property LOC RAMB36_X11Y26 [get_cells {chfpga0/CHANGEN[2].CHANi/*FUNCGEN0/*ram0/*/*bram_2}]
set_property LOC RAMB36_X11Y27 [get_cells {chfpga0/CHANGEN[2].CHANi/*FUNCGEN0/*ram0/*/*bram_3}]
set_property LOC RAMB36_X11Y28 [get_cells {chfpga0/CHANGEN[2].CHANi/*FUNCGEN0/*ram0/*/*bram_4}]
set_property LOC RAMB36_X11Y29 [get_cells {chfpga0/CHANGEN[2].CHANi/*FUNCGEN0/*ram0/*/*bram_5}]
set_property LOC RAMB36_X11Y30 [get_cells {chfpga0/CHANGEN[2].CHANi/*FUNCGEN0/*ram0/*/*bram_6}]
set_property LOC RAMB36_X11Y31 [get_cells {chfpga0/CHANGEN[2].CHANi/*FUNCGEN0/*ram0/*/*bram_7}]
set_property LOC RAMB36_X11Y36 [get_cells {chfpga0/CHANGEN[3].CHANi/*FUNCGEN0/*ram0/*/*bram_0}]
set_property LOC RAMB36_X11Y37 [get_cells {chfpga0/CHANGEN[3].CHANi/*FUNCGEN0/*ram0/*/*bram_1}]
set_property LOC RAMB36_X11Y38 [get_cells {chfpga0/CHANGEN[3].CHANi/*FUNCGEN0/*ram0/*/*bram_2}]
set_property LOC RAMB36_X11Y39 [get_cells {chfpga0/CHANGEN[3].CHANi/*FUNCGEN0/*ram0/*/*bram_3}]
set_property LOC RAMB36_X11Y40 [get_cells {chfpga0/CHANGEN[3].CHANi/*FUNCGEN0/*ram0/*/*bram_4}]
set_property LOC RAMB36_X11Y41 [get_cells {chfpga0/CHANGEN[3].CHANi/*FUNCGEN0/*ram0/*/*bram_5}]
set_property LOC RAMB36_X11Y42 [get_cells {chfpga0/CHANGEN[3].CHANi/*FUNCGEN0/*ram0/*/*bram_6}]
set_property LOC RAMB36_X11Y43 [get_cells {chfpga0/CHANGEN[3].CHANi/*FUNCGEN0/*ram0/*/*bram_7}]
set_property LOC RAMB36_X11Y48 [get_cells {chfpga0/CHANGEN[4].CHANi/*FUNCGEN0/*ram0/*/*bram_0}]
set_property LOC RAMB36_X11Y49 [get_cells {chfpga0/CHANGEN[4].CHANi/*FUNCGEN0/*ram0/*/*bram_1}]
set_property LOC RAMB36_X11Y50 [get_cells {chfpga0/CHANGEN[4].CHANi/*FUNCGEN0/*ram0/*/*bram_2}]
set_property LOC RAMB36_X11Y51 [get_cells {chfpga0/CHANGEN[4].CHANi/*FUNCGEN0/*ram0/*/*bram_3}]
set_property LOC RAMB36_X11Y52 [get_cells {chfpga0/CHANGEN[4].CHANi/*FUNCGEN0/*ram0/*/*bram_4}]
set_property LOC RAMB36_X11Y53 [get_cells {chfpga0/CHANGEN[4].CHANi/*FUNCGEN0/*ram0/*/*bram_5}]
set_property LOC RAMB36_X11Y54 [get_cells {chfpga0/CHANGEN[4].CHANi/*FUNCGEN0/*ram0/*/*bram_6}]
set_property LOC RAMB36_X11Y55 [get_cells {chfpga0/CHANGEN[4].CHANi/*FUNCGEN0/*ram0/*/*bram_7}]
set_property LOC RAMB36_X11Y60 [get_cells {chfpga0/CHANGEN[5].CHANi/*FUNCGEN0/*ram0/*/*bram_0}]
set_property LOC RAMB36_X11Y61 [get_cells {chfpga0/CHANGEN[5].CHANi/*FUNCGEN0/*ram0/*/*bram_1}]
set_property LOC RAMB36_X11Y62 [get_cells {chfpga0/CHANGEN[5].CHANi/*FUNCGEN0/*ram0/*/*bram_2}]
set_property LOC RAMB36_X11Y63 [get_cells {chfpga0/CHANGEN[5].CHANi/*FUNCGEN0/*ram0/*/*bram_3}]
set_property LOC RAMB36_X11Y64 [get_cells {chfpga0/CHANGEN[5].CHANi/*FUNCGEN0/*ram0/*/*bram_4}]
set_property LOC RAMB36_X11Y65 [get_cells {chfpga0/CHANGEN[5].CHANi/*FUNCGEN0/*ram0/*/*bram_5}]
set_property LOC RAMB36_X11Y66 [get_cells {chfpga0/CHANGEN[5].CHANi/*FUNCGEN0/*ram0/*/*bram_6}]
set_property LOC RAMB36_X11Y67 [get_cells {chfpga0/CHANGEN[5].CHANi/*FUNCGEN0/*ram0/*/*bram_7}]
set_property LOC RAMB36_X11Y72 [get_cells {chfpga0/CHANGEN[6].CHANi/*FUNCGEN0/*ram0/*/*bram_0}]
set_property LOC RAMB36_X11Y73 [get_cells {chfpga0/CHANGEN[6].CHANi/*FUNCGEN0/*ram0/*/*bram_1}]
set_property LOC RAMB36_X11Y74 [get_cells {chfpga0/CHANGEN[6].CHANi/*FUNCGEN0/*ram0/*/*bram_2}]
set_property LOC RAMB36_X11Y75 [get_cells {chfpga0/CHANGEN[6].CHANi/*FUNCGEN0/*ram0/*/*bram_3}]
set_property LOC RAMB36_X11Y76 [get_cells {chfpga0/CHANGEN[6].CHANi/*FUNCGEN0/*ram0/*/*bram_4}]
set_property LOC RAMB36_X11Y77 [get_cells {chfpga0/CHANGEN[6].CHANi/*FUNCGEN0/*ram0/*/*bram_5}]
set_property LOC RAMB36_X11Y78 [get_cells {chfpga0/CHANGEN[6].CHANi/*FUNCGEN0/*ram0/*/*bram_6}]
set_property LOC RAMB36_X11Y79 [get_cells {chfpga0/CHANGEN[6].CHANi/*FUNCGEN0/*ram0/*/*bram_7}]
set_property LOC RAMB36_X11Y84 [get_cells {chfpga0/CHANGEN[7].CHANi/*FUNCGEN0/*ram0/*/*bram_0}]
set_property LOC RAMB36_X11Y85 [get_cells {chfpga0/CHANGEN[7].CHANi/*FUNCGEN0/*ram0/*/*bram_1}]
set_property LOC RAMB36_X11Y86 [get_cells {chfpga0/CHANGEN[7].CHANi/*FUNCGEN0/*ram0/*/*bram_2}]
set_property LOC RAMB36_X11Y87 [get_cells {chfpga0/CHANGEN[7].CHANi/*FUNCGEN0/*ram0/*/*bram_3}]
set_property LOC RAMB36_X11Y88 [get_cells {chfpga0/CHANGEN[7].CHANi/*FUNCGEN0/*ram0/*/*bram_4}]
set_property LOC RAMB36_X11Y89 [get_cells {chfpga0/CHANGEN[7].CHANi/*FUNCGEN0/*ram0/*/*bram_5}]
set_property LOC RAMB36_X11Y90 [get_cells {chfpga0/CHANGEN[7].CHANi/*FUNCGEN0/*ram0/*/*bram_6}]
set_property LOC RAMB36_X11Y91 [get_cells {chfpga0/CHANGEN[7].CHANi/*FUNCGEN0/*ram0/*/*bram_7}]

