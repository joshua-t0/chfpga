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
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets clk10_ibufds1/O]
# # GPIO pins
# set_property PACKAGE_PIN C23     [get_ports {bp_gpio_p[1]}]; # Bank  57 VCC1V8
# set_property IOSTANDARD  LVDS     [get_ports {bp_gpio_p[1]}];

# set_property PACKAGE_PIN H22     [get_ports {bp_gpio_p[0]}]; # Bank  57 VCC1V8
# set_property IOSTANDARD  LVDS     [get_ports {bp_gpio_p[0]}];


########################
# Rear SMAs (DC coupled at the input buffer, AC coupled to the FPGA pins)
########################
# # IRIG-B signal
set_property PACKAGE_PIN K16 [get_ports sma_irig_p]
set_property IOSTANDARD LVDS [get_ports sma_irig_p]
set_input_delay -clock [get_clocks SYS_CLK] -max 0.015 [get_ports sma_irig_p]
set_input_delay -clock [get_clocks SYS_CLK] -min -0.015 [get_ports sma_irig_p]

# AUX SMA

# set_property PACKAGE_PIN H11     [get_ports {sma_aux_p}]; # Bank  57 VCC1V8
set_property PACKAGE_PIN E6     [get_ports {sma_aux_drv}]; # Bank  87 VCC3V3
set_property IOSTANDARD LVCMOS33 [get_ports {sma_aux_drv}]
set_property SLEW FAST [get_ports {sma_aux_drv}]
set_property DRIVE 16 [get_ports {sma_aux_drv}]

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
# set_property package_pin P32 [get_ports mgtrefclk0_x0y4_n]
# Timing is defined in the GTY cores
create_clock -period 6.400 -name CLK_BP_SHUFFLE_REFCLK [get_ports bp_shuffle_refclk_p]
# set_property PACKAGE_PIN P31      [get_ports {gty_clk0_p131}] ; # GTY Bank  131, REFCLK0
# create_clock -name GTY_P131 -period 156.25MHz [get_ports {gty_clk0_p131}]


# GTY reference clock, 156.25 MHz from fixed PLL, Bank 129
# 100G interface reference clock
# This is defined in the -ct config-specific physical constraint file
# set_property PACKAGE_PIN W33      [get_ports {gty_clk0_p129}] ; # GTY Bank 129, REFCLK0
# set_property PACKAGE_PIN W33 [get_ports clk156_p]
# create_clock -name CLK156 -period 6.4 [get_ports {clk156_p}]
# create_clock -name GTY_P129 -period 156.25MHz [get_ports {gty_clk0_p129}]

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
resize_pblock [get_pblocks ADC] -add {DSP48E2_X22Y24:DSP48E2_X22Y119}
set_property EXCLUDE_PLACEMENT 1 [get_pblocks ADC]

# Modules are assigned to the SYSTEM PBLOCK by setting the TARGET_PBLOCK attribute to "SYSTEM" in VHDL
# Use this line to automatically pick the cells
# add_cells_to_pblock [get_pblocks SYSTEM] [get_cells * -hier -filter TARGET_PBLOCK==SYSTEM]

create_pblock SYSTEM
add_cells_to_pblock [get_pblocks SYSTEM] [get_cells -quiet [list \
          chfpga0/CLK0 \
          chfpga0/blinker_blk.BLINKER0 \
          chfpga0/bsb_master_blk.ctrl_master0 \
          chfpga0/chan_router_blk.chan_router0 \
          chfpga0/ct_clk_blk.ct_reset_cdc0 \
          chfpga0/freq_ctr_blk.FREQ_CTR0 \
          chfpga0/gpio_blk.GPIO0 \
          {chfpga0/refclk_blk.REFCLK0/FSM_onehot_sync_state[1]_i_1} \
          {chfpga0/refclk_blk.REFCLK0/FSM_onehot_sync_state[2]_i_1} \
          {chfpga0/refclk_blk.REFCLK0/FSM_onehot_sync_state[3]_i_2} \
          {chfpga0/refclk_blk.REFCLK0/FSM_onehot_sync_state[3]_i_3} \
          {chfpga0/refclk_blk.REFCLK0/FSM_onehot_sync_state[3]_i_4} \
          {chfpga0/refclk_blk.REFCLK0/FSM_onehot_sync_state_reg[1]} \
          {chfpga0/refclk_blk.REFCLK0/FSM_onehot_sync_state_reg[2]} \
          {chfpga0/refclk_blk.REFCLK0/FSM_onehot_sync_state_reg[3]} \
          chfpga0/refclk_blk.REFCLK0/VCC \
          chfpga0/refclk_blk.REFCLK0/adcdaq_reset_reg \
          chfpga0/refclk_blk.REFCLK0/bsb_regs0 \
          chfpga0/refclk_blk.REFCLK0/local_sync_dly_reg \
          chfpga0/refclk_blk.REFCLK0/local_sync_reg_reg \
          {chfpga0/refclk_blk.REFCLK0/sync_ctr[0]_i_1} \
          {chfpga0/refclk_blk.REFCLK0/sync_ctr[10]_i_1} \
          {chfpga0/refclk_blk.REFCLK0/sync_ctr[11]_i_1} \
          {chfpga0/refclk_blk.REFCLK0/sync_ctr[12]_i_1} \
          {chfpga0/refclk_blk.REFCLK0/sync_ctr[13]_i_1} \
          {chfpga0/refclk_blk.REFCLK0/sync_ctr[14]_i_1} \
          {chfpga0/refclk_blk.REFCLK0/sync_ctr[15]_i_2} \
          {chfpga0/refclk_blk.REFCLK0/sync_ctr[15]_i_3} \
          {chfpga0/refclk_blk.REFCLK0/sync_ctr[1]_i_1} \
          {chfpga0/refclk_blk.REFCLK0/sync_ctr[2]_i_1} \
          {chfpga0/refclk_blk.REFCLK0/sync_ctr[3]_i_1} \
          {chfpga0/refclk_blk.REFCLK0/sync_ctr[4]_i_1} \
          {chfpga0/refclk_blk.REFCLK0/sync_ctr[5]_i_1} \
          {chfpga0/refclk_blk.REFCLK0/sync_ctr[5]_i_2} \
          {chfpga0/refclk_blk.REFCLK0/sync_ctr[6]_i_1} \
          {chfpga0/refclk_blk.REFCLK0/sync_ctr[7]_i_1} \
          {chfpga0/refclk_blk.REFCLK0/sync_ctr[8]_i_1} \
          {chfpga0/refclk_blk.REFCLK0/sync_ctr[9]_i_1} \
          {chfpga0/refclk_blk.REFCLK0/sync_ctr[9]_i_2} \
          {chfpga0/refclk_blk.REFCLK0/sync_ctr_reg[0]} \
          {chfpga0/refclk_blk.REFCLK0/sync_ctr_reg[10]} \
          {chfpga0/refclk_blk.REFCLK0/sync_ctr_reg[11]} \
          {chfpga0/refclk_blk.REFCLK0/sync_ctr_reg[12]} \
          {chfpga0/refclk_blk.REFCLK0/sync_ctr_reg[13]} \
          {chfpga0/refclk_blk.REFCLK0/sync_ctr_reg[14]} \
          {chfpga0/refclk_blk.REFCLK0/sync_ctr_reg[15]} \
          {chfpga0/refclk_blk.REFCLK0/sync_ctr_reg[1]} \
          {chfpga0/refclk_blk.REFCLK0/sync_ctr_reg[2]} \
          {chfpga0/refclk_blk.REFCLK0/sync_ctr_reg[3]} \
          {chfpga0/refclk_blk.REFCLK0/sync_ctr_reg[4]} \
          {chfpga0/refclk_blk.REFCLK0/sync_ctr_reg[5]} \
          {chfpga0/refclk_blk.REFCLK0/sync_ctr_reg[6]} \
          {chfpga0/refclk_blk.REFCLK0/sync_ctr_reg[7]} \
          {chfpga0/refclk_blk.REFCLK0/sync_ctr_reg[8]} \
          {chfpga0/refclk_blk.REFCLK0/sync_ctr_reg[9]} \
          chfpga0/refclk_blk.REFCLK0/sync_dly_reg \
          chfpga0/refclk_blk.REFCLK0/sync_done_reg \
          {chfpga0/refclk_blk.REFCLK0/sync_event_ctr[0]_i_1} \
          {chfpga0/refclk_blk.REFCLK0/sync_event_ctr[1]_i_1} \
          {chfpga0/refclk_blk.REFCLK0/sync_event_ctr[2]_i_1} \
          {chfpga0/refclk_blk.REFCLK0/sync_event_ctr[3]_i_2} \
          {chfpga0/refclk_blk.REFCLK0/sync_event_ctr_reg[0]} \
          {chfpga0/refclk_blk.REFCLK0/sync_event_ctr_reg[1]} \
          {chfpga0/refclk_blk.REFCLK0/sync_event_ctr_reg[2]} \
          {chfpga0/refclk_blk.REFCLK0/sync_event_ctr_reg[3]} \
          chfpga0/refclk_blk.REFCLK0/sync_reg \
          chfpga0/sysmon_blk.SYSMON0 \
          chfpga0/sysrtr_blk.sys_router0 \
          chfpga0/top_router_blk.top_router0]]
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
resize_pblock [get_pblocks CHAN0] -add {DSP48E2_X3Y0:DSP48E2_X21Y23}
resize_pblock [get_pblocks CHAN0] -add {RAMB18_X2Y0:RAMB18_X11Y23}
resize_pblock [get_pblocks CHAN0] -add {RAMB36_X2Y0:RAMB36_X11Y11}
set_property IS_SOFT FALSE [get_pblocks CHAN0]


create_pblock FFT0
add_cells_to_pblock [get_pblocks FFT0] [get_cells -quiet [list {chfpga0/CHANGEN[0].CHANi/IMPL_GEN.fft_blk.FFT0}]]
resize_pblock [get_pblocks FFT0] -add {SLICE_X109Y40:SLICE_X112Y59 SLICE_X82Y0:SLICE_X108Y59 SLICE_X57Y0:SLICE_X79Y59 SLICE_X32Y0:SLICE_X55Y59}
resize_pblock [get_pblocks FFT0] -add {DSP48E2_X5Y0:DSP48E2_X21Y23}
resize_pblock [get_pblocks FFT0] -add {RAMB18_X11Y16:RAMB18_X11Y23 RAMB18_X3Y0:RAMB18_X10Y23}
resize_pblock [get_pblocks FFT0] -add {RAMB36_X11Y8:RAMB36_X11Y11 RAMB36_X3Y0:RAMB36_X10Y11}
set_property EXCLUDE_PLACEMENT 1 [get_pblocks FFT0]

# pblock below seems unused
create_pblock PFB0
resize_pblock [get_pblocks PFB0] -add {SLICE_X92Y0:SLICE_X105Y59}
resize_pblock [get_pblocks PFB0] -add {DSP48E2_X18Y0:DSP48E2_X20Y23}
resize_pblock [get_pblocks PFB0] -add {RAMB18_X9Y0:RAMB18_X10Y23}
resize_pblock [get_pblocks PFB0] -add {RAMB36_X9Y0:RAMB36_X10Y11}


create_pblock FUNCGEN0
add_cells_to_pblock [get_pblocks FUNCGEN0] [get_cells -quiet [list {chfpga0/CHANGEN[0].CHANi/IMPL_GEN.funcgen_blk.FUNCGEN0}]]
resize_pblock [get_pblocks FUNCGEN0] -add {SLICE_X109Y0:SLICE_X112Y39}
resize_pblock [get_pblocks FUNCGEN0] -add {RAMB18_X11Y0:RAMB18_X11Y15}
resize_pblock [get_pblocks FUNCGEN0] -add {RAMB36_X11Y0:RAMB36_X11Y7}
set_property IS_SOFT FALSE [get_pblocks FUNCGEN0]


create_pblock SCALER0
add_cells_to_pblock [get_pblocks SCALER0] [get_cells -quiet [list {chfpga0/CHANGEN[0].CHANi/IMPL_GEN.scaler_blk.SCALER0}]]
resize_pblock [get_pblocks SCALER0] -add {SLICE_X26Y0:SLICE_X31Y59}
resize_pblock [get_pblocks SCALER0] -add {DSP48E2_X3Y0:DSP48E2_X4Y23}
resize_pblock [get_pblocks SCALER0] -add {RAMB18_X2Y0:RAMB18_X2Y15}
resize_pblock [get_pblocks SCALER0] -add {RAMB36_X2Y0:RAMB36_X2Y7}
set_property IS_SOFT FALSE [get_pblocks SCALER0]


create_pblock CHAN1
add_cells_to_pblock [get_pblocks CHAN1] [get_cells -quiet [list {chfpga0/CHANGEN[1].CHANi}]]
resize_pblock [get_pblocks CHAN1] -add {SLICE_X26Y60:SLICE_X112Y119}
resize_pblock [get_pblocks CHAN1] -add {DSP48E2_X3Y24:DSP48E2_X21Y47}
resize_pblock [get_pblocks CHAN1] -add {RAMB18_X2Y24:RAMB18_X11Y47}
resize_pblock [get_pblocks CHAN1] -add {RAMB36_X2Y12:RAMB36_X11Y23}
set_property IS_SOFT FALSE [get_pblocks CHAN1]


create_pblock FFT1
add_cells_to_pblock [get_pblocks FFT1] [get_cells -quiet [list {chfpga0/CHANGEN[1].CHANi/IMPL_GEN.fft_blk.FFT0}]]
resize_pblock [get_pblocks FFT1] -add {SLICE_X109Y100:SLICE_X112Y119 SLICE_X82Y60:SLICE_X108Y119 SLICE_X57Y60:SLICE_X79Y119 SLICE_X32Y60:SLICE_X55Y119}
resize_pblock [get_pblocks FFT1] -add {DSP48E2_X5Y24:DSP48E2_X21Y47}
resize_pblock [get_pblocks FFT1] -add {RAMB18_X11Y40:RAMB18_X11Y47 RAMB18_X3Y24:RAMB18_X10Y47}
resize_pblock [get_pblocks FFT1] -add {RAMB36_X11Y20:RAMB36_X11Y23 RAMB36_X3Y12:RAMB36_X10Y23}
set_property EXCLUDE_PLACEMENT 1 [get_pblocks FFT1]


create_pblock FUNCGEN1
add_cells_to_pblock [get_pblocks FUNCGEN1] [get_cells -quiet [list {chfpga0/CHANGEN[1].CHANi/IMPL_GEN.funcgen_blk.FUNCGEN0}]]
resize_pblock [get_pblocks FUNCGEN1] -add {SLICE_X109Y60:SLICE_X112Y99}
resize_pblock [get_pblocks FUNCGEN1] -add {RAMB18_X11Y24:RAMB18_X11Y39}
resize_pblock [get_pblocks FUNCGEN1] -add {RAMB36_X11Y12:RAMB36_X11Y19}
set_property IS_SOFT FALSE [get_pblocks FUNCGEN1]


create_pblock SCALER1
add_cells_to_pblock [get_pblocks SCALER1] [get_cells -quiet [list {chfpga0/CHANGEN[1].CHANi/IMPL_GEN.scaler_blk.SCALER0}]]
resize_pblock [get_pblocks SCALER1] -add {SLICE_X26Y60:SLICE_X31Y119}
resize_pblock [get_pblocks SCALER1] -add {DSP48E2_X3Y24:DSP48E2_X4Y47}
resize_pblock [get_pblocks SCALER1] -add {RAMB18_X2Y24:RAMB18_X2Y39}
resize_pblock [get_pblocks SCALER1] -add {RAMB36_X2Y12:RAMB36_X2Y19}
set_property IS_SOFT FALSE [get_pblocks SCALER1]


create_pblock CHAN2
add_cells_to_pblock [get_pblocks CHAN2] [get_cells -quiet [list {chfpga0/CHANGEN[2].CHANi}]]
resize_pblock [get_pblocks CHAN2] -add {SLICE_X26Y120:SLICE_X112Y179}
resize_pblock [get_pblocks CHAN2] -add {DSP48E2_X3Y48:DSP48E2_X21Y71}
resize_pblock [get_pblocks CHAN2] -add {RAMB18_X2Y48:RAMB18_X11Y71}
resize_pblock [get_pblocks CHAN2] -add {RAMB36_X2Y24:RAMB36_X11Y35}
set_property IS_SOFT FALSE [get_pblocks CHAN2]


create_pblock FFT2
add_cells_to_pblock [get_pblocks FFT2] [get_cells -quiet [list {chfpga0/CHANGEN[2].CHANi/IMPL_GEN.fft_blk.FFT0}]]
resize_pblock [get_pblocks FFT2] -add {SLICE_X109Y160:SLICE_X112Y179 SLICE_X82Y120:SLICE_X108Y179 SLICE_X57Y120:SLICE_X79Y179 SLICE_X32Y120:SLICE_X55Y179}
resize_pblock [get_pblocks FFT2] -add {DSP48E2_X5Y48:DSP48E2_X21Y71}
resize_pblock [get_pblocks FFT2] -add {RAMB18_X11Y64:RAMB18_X11Y71 RAMB18_X3Y48:RAMB18_X10Y71}
resize_pblock [get_pblocks FFT2] -add {RAMB36_X11Y32:RAMB36_X11Y35 RAMB36_X3Y24:RAMB36_X10Y35}
set_property EXCLUDE_PLACEMENT 1 [get_pblocks FFT2]


create_pblock FUNCGEN2
add_cells_to_pblock [get_pblocks FUNCGEN2] [get_cells -quiet [list {chfpga0/CHANGEN[2].CHANi/IMPL_GEN.funcgen_blk.FUNCGEN0}]]
resize_pblock [get_pblocks FUNCGEN2] -add {SLICE_X109Y120:SLICE_X112Y159}
resize_pblock [get_pblocks FUNCGEN2] -add {RAMB18_X11Y48:RAMB18_X11Y63}
resize_pblock [get_pblocks FUNCGEN2] -add {RAMB36_X11Y24:RAMB36_X11Y31}
set_property IS_SOFT FALSE [get_pblocks FUNCGEN2]


create_pblock SCALER2
add_cells_to_pblock [get_pblocks SCALER2] [get_cells -quiet [list {chfpga0/CHANGEN[2].CHANi/IMPL_GEN.scaler_blk.SCALER0}]]
resize_pblock [get_pblocks SCALER2] -add {SLICE_X26Y120:SLICE_X31Y179}
resize_pblock [get_pblocks SCALER2] -add {DSP48E2_X3Y48:DSP48E2_X4Y71}
resize_pblock [get_pblocks SCALER2] -add {RAMB18_X2Y48:RAMB18_X2Y63}
resize_pblock [get_pblocks SCALER2] -add {RAMB36_X2Y24:RAMB36_X2Y31}
set_property IS_SOFT FALSE [get_pblocks SCALER2]


create_pblock CHAN3
add_cells_to_pblock [get_pblocks CHAN3] [get_cells -quiet [list {chfpga0/CHANGEN[3].CHANi}]]
resize_pblock [get_pblocks CHAN3] -add {SLICE_X26Y180:SLICE_X112Y239}
resize_pblock [get_pblocks CHAN3] -add {DSP48E2_X3Y72:DSP48E2_X21Y95}
resize_pblock [get_pblocks CHAN3] -add {RAMB18_X2Y72:RAMB18_X11Y95}
resize_pblock [get_pblocks CHAN3] -add {RAMB36_X2Y36:RAMB36_X11Y47}
set_property IS_SOFT FALSE [get_pblocks CHAN3]


create_pblock FFT3
add_cells_to_pblock [get_pblocks FFT3] [get_cells -quiet [list {chfpga0/CHANGEN[3].CHANi/IMPL_GEN.fft_blk.FFT0}]]
resize_pblock [get_pblocks FFT3] -add {SLICE_X109Y220:SLICE_X112Y239 SLICE_X82Y180:SLICE_X108Y239 SLICE_X57Y180:SLICE_X79Y239 SLICE_X32Y180:SLICE_X55Y239}
resize_pblock [get_pblocks FFT3] -add {DSP48E2_X5Y72:DSP48E2_X21Y95}
resize_pblock [get_pblocks FFT3] -add {RAMB18_X11Y88:RAMB18_X11Y95 RAMB18_X3Y72:RAMB18_X10Y95}
resize_pblock [get_pblocks FFT3] -add {RAMB36_X11Y44:RAMB36_X11Y47 RAMB36_X3Y36:RAMB36_X10Y47}
set_property EXCLUDE_PLACEMENT 1 [get_pblocks FFT3]


create_pblock FUNCGEN3
add_cells_to_pblock [get_pblocks FUNCGEN3] [get_cells -quiet [list {chfpga0/CHANGEN[3].CHANi/IMPL_GEN.funcgen_blk.FUNCGEN0}]]
resize_pblock [get_pblocks FUNCGEN3] -add {SLICE_X109Y180:SLICE_X112Y219}
resize_pblock [get_pblocks FUNCGEN3] -add {RAMB18_X11Y72:RAMB18_X11Y87}
resize_pblock [get_pblocks FUNCGEN3] -add {RAMB36_X11Y36:RAMB36_X11Y43}
set_property IS_SOFT FALSE [get_pblocks FUNCGEN3]


create_pblock SCALER3
add_cells_to_pblock [get_pblocks SCALER3] [get_cells -quiet [list {chfpga0/CHANGEN[3].CHANi/IMPL_GEN.scaler_blk.SCALER0}]]
resize_pblock [get_pblocks SCALER3] -add {SLICE_X26Y180:SLICE_X31Y239}
resize_pblock [get_pblocks SCALER3] -add {DSP48E2_X3Y72:DSP48E2_X4Y95}
resize_pblock [get_pblocks SCALER3] -add {RAMB18_X2Y72:RAMB18_X2Y87}
resize_pblock [get_pblocks SCALER3] -add {RAMB36_X2Y36:RAMB36_X2Y43}
set_property IS_SOFT FALSE [get_pblocks SCALER3]


create_pblock CHAN4
add_cells_to_pblock [get_pblocks CHAN4] [get_cells -quiet [list {chfpga0/CHANGEN[4].CHANi}]]
resize_pblock [get_pblocks CHAN4] -add {SLICE_X26Y240:SLICE_X112Y299}
resize_pblock [get_pblocks CHAN4] -add {DSP48E2_X3Y96:DSP48E2_X21Y119}
resize_pblock [get_pblocks CHAN4] -add {RAMB18_X2Y96:RAMB18_X11Y119}
resize_pblock [get_pblocks CHAN4] -add {RAMB36_X2Y48:RAMB36_X11Y59}
set_property IS_SOFT FALSE [get_pblocks CHAN4]


create_pblock FFT4
add_cells_to_pblock [get_pblocks FFT4] [get_cells -quiet [list {chfpga0/CHANGEN[4].CHANi/IMPL_GEN.fft_blk.FFT0}]]
resize_pblock [get_pblocks FFT4] -add {SLICE_X109Y280:SLICE_X112Y299 SLICE_X82Y240:SLICE_X108Y299 SLICE_X57Y240:SLICE_X79Y299 SLICE_X32Y240:SLICE_X55Y299}
resize_pblock [get_pblocks FFT4] -add {DSP48E2_X5Y96:DSP48E2_X21Y119}
resize_pblock [get_pblocks FFT4] -add {RAMB18_X11Y112:RAMB18_X11Y119 RAMB18_X3Y96:RAMB18_X10Y119}
resize_pblock [get_pblocks FFT4] -add {RAMB36_X11Y56:RAMB36_X11Y59 RAMB36_X3Y48:RAMB36_X10Y59}
set_property EXCLUDE_PLACEMENT 1 [get_pblocks FFT4]


create_pblock FUNCGEN4
add_cells_to_pblock [get_pblocks FUNCGEN4] [get_cells -quiet [list {chfpga0/CHANGEN[4].CHANi/IMPL_GEN.funcgen_blk.FUNCGEN0}]]
resize_pblock [get_pblocks FUNCGEN4] -add {SLICE_X109Y240:SLICE_X112Y279}
resize_pblock [get_pblocks FUNCGEN4] -add {RAMB18_X11Y96:RAMB18_X11Y111}
resize_pblock [get_pblocks FUNCGEN4] -add {RAMB36_X11Y48:RAMB36_X11Y55}
set_property IS_SOFT FALSE [get_pblocks FUNCGEN4]


create_pblock SCALER4
add_cells_to_pblock [get_pblocks SCALER4] [get_cells -quiet [list {chfpga0/CHANGEN[4].CHANi/IMPL_GEN.scaler_blk.SCALER0}]]
resize_pblock [get_pblocks SCALER4] -add {SLICE_X26Y240:SLICE_X31Y299}
resize_pblock [get_pblocks SCALER4] -add {DSP48E2_X3Y96:DSP48E2_X4Y119}
resize_pblock [get_pblocks SCALER4] -add {RAMB18_X2Y96:RAMB18_X2Y111}
resize_pblock [get_pblocks SCALER4] -add {RAMB36_X2Y48:RAMB36_X2Y55}
set_property IS_SOFT FALSE [get_pblocks SCALER4]


create_pblock CHAN5
add_cells_to_pblock [get_pblocks CHAN5] [get_cells -quiet [list {chfpga0/CHANGEN[5].CHANi}]]
resize_pblock [get_pblocks CHAN5] -add {SLICE_X26Y300:SLICE_X112Y359}
resize_pblock [get_pblocks CHAN5] -add {DSP48E2_X3Y120:DSP48E2_X21Y143}
resize_pblock [get_pblocks CHAN5] -add {RAMB18_X2Y120:RAMB18_X11Y143}
resize_pblock [get_pblocks CHAN5] -add {RAMB36_X2Y60:RAMB36_X11Y71}
set_property IS_SOFT FALSE [get_pblocks CHAN5]


create_pblock FFT5
add_cells_to_pblock [get_pblocks FFT5] [get_cells -quiet [list {chfpga0/CHANGEN[5].CHANi/IMPL_GEN.fft_blk.FFT0}]]
resize_pblock [get_pblocks FFT5] -add {SLICE_X109Y340:SLICE_X112Y359 SLICE_X82Y300:SLICE_X108Y359 SLICE_X57Y300:SLICE_X79Y359 SLICE_X32Y300:SLICE_X55Y359}
resize_pblock [get_pblocks FFT5] -add {DSP48E2_X5Y120:DSP48E2_X21Y143}
resize_pblock [get_pblocks FFT5] -add {RAMB18_X11Y136:RAMB18_X11Y143 RAMB18_X3Y120:RAMB18_X10Y143}
resize_pblock [get_pblocks FFT5] -add {RAMB36_X11Y68:RAMB36_X11Y71 RAMB36_X3Y60:RAMB36_X10Y71}
set_property EXCLUDE_PLACEMENT 1 [get_pblocks FFT5]


create_pblock FUNCGEN5
add_cells_to_pblock [get_pblocks FUNCGEN5] [get_cells -quiet [list {chfpga0/CHANGEN[5].CHANi/IMPL_GEN.funcgen_blk.FUNCGEN0}]]
resize_pblock [get_pblocks FUNCGEN5] -add {SLICE_X109Y300:SLICE_X112Y339}
resize_pblock [get_pblocks FUNCGEN5] -add {RAMB18_X11Y120:RAMB18_X11Y135}
resize_pblock [get_pblocks FUNCGEN5] -add {RAMB36_X11Y60:RAMB36_X11Y67}
set_property IS_SOFT FALSE [get_pblocks FUNCGEN5]


create_pblock SCALER5
add_cells_to_pblock [get_pblocks SCALER5] [get_cells -quiet [list {chfpga0/CHANGEN[5].CHANi/IMPL_GEN.scaler_blk.SCALER0}]]
resize_pblock [get_pblocks SCALER5] -add {SLICE_X26Y300:SLICE_X31Y359}
resize_pblock [get_pblocks SCALER5] -add {DSP48E2_X3Y120:DSP48E2_X4Y143}
resize_pblock [get_pblocks SCALER5] -add {RAMB18_X2Y120:RAMB18_X2Y135}
resize_pblock [get_pblocks SCALER5] -add {RAMB36_X2Y60:RAMB36_X2Y67}
set_property IS_SOFT FALSE [get_pblocks SCALER5]


create_pblock CHAN6
add_cells_to_pblock [get_pblocks CHAN6] [get_cells -quiet [list {chfpga0/CHANGEN[6].CHANi}]]
resize_pblock [get_pblocks CHAN6] -add {SLICE_X26Y360:SLICE_X112Y419}
resize_pblock [get_pblocks CHAN6] -add {DSP48E2_X3Y144:DSP48E2_X21Y167}
resize_pblock [get_pblocks CHAN6] -add {RAMB18_X2Y144:RAMB18_X11Y167}
resize_pblock [get_pblocks CHAN6] -add {RAMB36_X2Y72:RAMB36_X11Y83}
set_property IS_SOFT FALSE [get_pblocks CHAN6]


create_pblock FFT6
add_cells_to_pblock [get_pblocks FFT6] [get_cells -quiet [list {chfpga0/CHANGEN[6].CHANi/IMPL_GEN.fft_blk.FFT0}]]
resize_pblock [get_pblocks FFT6] -add {SLICE_X109Y400:SLICE_X112Y419 SLICE_X82Y360:SLICE_X108Y419 SLICE_X57Y360:SLICE_X79Y419 SLICE_X32Y360:SLICE_X55Y419}
resize_pblock [get_pblocks FFT6] -add {DSP48E2_X5Y144:DSP48E2_X21Y167}
resize_pblock [get_pblocks FFT6] -add {RAMB18_X11Y160:RAMB18_X11Y167 RAMB18_X3Y144:RAMB18_X10Y167}
resize_pblock [get_pblocks FFT6] -add {RAMB36_X11Y80:RAMB36_X11Y83 RAMB36_X3Y72:RAMB36_X10Y83}
set_property EXCLUDE_PLACEMENT 1 [get_pblocks FFT6]


create_pblock FUNCGEN6
add_cells_to_pblock [get_pblocks FUNCGEN6] [get_cells -quiet [list {chfpga0/CHANGEN[6].CHANi/IMPL_GEN.funcgen_blk.FUNCGEN0}]]
resize_pblock [get_pblocks FUNCGEN6] -add {SLICE_X109Y360:SLICE_X112Y399}
resize_pblock [get_pblocks FUNCGEN6] -add {RAMB18_X11Y144:RAMB18_X11Y159}
resize_pblock [get_pblocks FUNCGEN6] -add {RAMB36_X11Y72:RAMB36_X11Y79}
set_property IS_SOFT FALSE [get_pblocks FUNCGEN6]


create_pblock SCALER6
add_cells_to_pblock [get_pblocks SCALER6] [get_cells -quiet [list {chfpga0/CHANGEN[6].CHANi/IMPL_GEN.scaler_blk.SCALER0}]]
resize_pblock [get_pblocks SCALER6] -add {SLICE_X26Y360:SLICE_X31Y419}
resize_pblock [get_pblocks SCALER6] -add {DSP48E2_X3Y144:DSP48E2_X4Y167}
resize_pblock [get_pblocks SCALER6] -add {RAMB18_X2Y144:RAMB18_X2Y159}
resize_pblock [get_pblocks SCALER6] -add {RAMB36_X2Y72:RAMB36_X2Y79}
set_property IS_SOFT FALSE [get_pblocks SCALER6]


create_pblock CHAN7
add_cells_to_pblock [get_pblocks CHAN7] [get_cells -quiet [list {chfpga0/CHANGEN[7].CHANi}]]
resize_pblock [get_pblocks CHAN7] -add {SLICE_X26Y420:SLICE_X112Y479}
resize_pblock [get_pblocks CHAN7] -add {DSP48E2_X3Y168:DSP48E2_X21Y191}
resize_pblock [get_pblocks CHAN7] -add {RAMB18_X2Y168:RAMB18_X11Y191}
resize_pblock [get_pblocks CHAN7] -add {RAMB36_X2Y84:RAMB36_X11Y95}
set_property IS_SOFT FALSE [get_pblocks CHAN7]


create_pblock FFT7
add_cells_to_pblock [get_pblocks FFT7] [get_cells -quiet [list {chfpga0/CHANGEN[7].CHANi/IMPL_GEN.fft_blk.FFT0}]]
resize_pblock [get_pblocks FFT7] -add {SLICE_X109Y460:SLICE_X112Y479 SLICE_X82Y420:SLICE_X108Y479 SLICE_X57Y420:SLICE_X79Y479 SLICE_X32Y420:SLICE_X55Y479}
resize_pblock [get_pblocks FFT7] -add {DSP48E2_X5Y168:DSP48E2_X21Y191}
resize_pblock [get_pblocks FFT7] -add {RAMB18_X11Y184:RAMB18_X11Y191 RAMB18_X3Y168:RAMB18_X10Y191}
resize_pblock [get_pblocks FFT7] -add {RAMB36_X11Y92:RAMB36_X11Y95 RAMB36_X3Y84:RAMB36_X10Y95}
set_property EXCLUDE_PLACEMENT 1 [get_pblocks FFT7]


create_pblock FUNCGEN7
add_cells_to_pblock [get_pblocks FUNCGEN7] [get_cells -quiet [list {chfpga0/CHANGEN[7].CHANi/IMPL_GEN.funcgen_blk.FUNCGEN0}]]
resize_pblock [get_pblocks FUNCGEN7] -add {SLICE_X109Y420:SLICE_X112Y459}
resize_pblock [get_pblocks FUNCGEN7] -add {RAMB18_X11Y168:RAMB18_X11Y183}
resize_pblock [get_pblocks FUNCGEN7] -add {RAMB36_X11Y84:RAMB36_X11Y91}
set_property IS_SOFT FALSE [get_pblocks FUNCGEN7]


create_pblock SCALER7
add_cells_to_pblock [get_pblocks SCALER7] [get_cells -quiet [list {chfpga0/CHANGEN[7].CHANi/IMPL_GEN.scaler_blk.SCALER0}]]
resize_pblock [get_pblocks SCALER7] -add {SLICE_X26Y420:SLICE_X31Y479}
resize_pblock [get_pblocks SCALER7] -add {DSP48E2_X3Y168:DSP48E2_X4Y191}
resize_pblock [get_pblocks SCALER7] -add {RAMB18_X2Y168:RAMB18_X2Y183}
resize_pblock [get_pblocks SCALER7] -add {RAMB36_X2Y84:RAMB36_X2Y91}
set_property IS_SOFT FALSE [get_pblocks SCALER7]




set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets smp_OBUF[3]]

# Pin the UCAP UltraRAM sites to facilitate P&R

set_property LOC URAM288_X0Y64 [get_cells chfpga0/*ucap0/uram_gen[0]*/*/*_uram_0]
set_property LOC URAM288_X0Y65 [get_cells chfpga0/*ucap0/uram_gen[0]*/*/*_uram_1]
set_property LOC URAM288_X0Y66 [get_cells chfpga0/*ucap0/uram_gen[1]*/*/*_uram_0]
set_property LOC URAM288_X0Y67 [get_cells chfpga0/*ucap0/uram_gen[1]*/*/*_uram_1]
set_property LOC URAM288_X0Y68 [get_cells chfpga0/*ucap0/uram_gen[2]*/*/*_uram_0]
set_property LOC URAM288_X0Y69 [get_cells chfpga0/*ucap0/uram_gen[2]*/*/*_uram_1]
set_property LOC URAM288_X0Y70 [get_cells chfpga0/*ucap0/uram_gen[3]*/*/*_uram_0]
set_property LOC URAM288_X0Y71 [get_cells chfpga0/*ucap0/uram_gen[3]*/*/*_uram_1]
set_property LOC URAM288_X0Y72 [get_cells chfpga0/*ucap0/uram_gen[4]*/*/*_uram_0]
set_property LOC URAM288_X0Y73 [get_cells chfpga0/*ucap0/uram_gen[4]*/*/*_uram_1]
set_property LOC URAM288_X0Y74 [get_cells chfpga0/*ucap0/uram_gen[5]*/*/*_uram_0]
set_property LOC URAM288_X0Y75 [get_cells chfpga0/*ucap0/uram_gen[5]*/*/*_uram_1]
set_property LOC URAM288_X0Y76 [get_cells chfpga0/*ucap0/uram_gen[6]*/*/*_uram_0]
set_property LOC URAM288_X0Y77 [get_cells chfpga0/*ucap0/uram_gen[6]*/*/*_uram_1]
set_property LOC URAM288_X0Y78 [get_cells chfpga0/*ucap0/uram_gen[7]*/*/*_uram_0]
set_property LOC URAM288_X0Y79 [get_cells chfpga0/*ucap0/uram_gen[7]*/*/*_uram_1]

