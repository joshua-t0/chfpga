############################################################################
##
##   CRS Rev1 and Rev2 Physical constraints
##
############################################################################

set_property BITSTREAM.CONFIG.USR_ACCESS TIMESTAMP [current_design]

# Frequency counter
# ----------------
# Constrain the frequency counter clock. The clock frequency on this net is 1/2 if the measured clock source
create_clock -period 5.000 -name FREQ_CTR_CLK [get_pins chfpga0/freq_ctr_blk.FREQ_CTR0/V6.SRCCLK0/O]
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
set_property PACKAGE_PIN K16 [get_ports sma_irig_p]
set_property IOSTANDARD LVDS [get_ports sma_irig_p]
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

# GTY reference clock, 156.25 MHz from fixed PLL, Bank 129
# This is config-specific
#set_property PACKAGE_PIN W33 [get_ports clk156_p]
# Note: clock period is defined by the CMAC IP and does not need to be defined below.
#create_clock -name CLK156 -period 6.4 [get_ports {clk156_p}]

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
create_clock -period 4.000 -name CLK200_CLK [get_ports {clk200_clk_p[0]}]

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
          chfpga0/refclk_blk.REFCLK0 \
          chfpga0/sysmon_blk.SYSMON0 \
          chfpga0/sysrtr_blk.sys_router0 \
          chfpga0/top_router_blk.top_router0]]
resize_pblock [get_pblocks SYSTEM] -add {SLICE_X113Y300:SLICE_X118Y419}
resize_pblock [get_pblocks SYSTEM] -add {DSP48E2_X22Y120:DSP48E2_X22Y167}
set_property IS_SOFT FALSE [get_pblocks SYSTEM]




create_pblock UCAP
add_cells_to_pblock [get_pblocks UCAP] [get_cells -quiet [list chfpga0/cap_gen.uram_case.ucap0]]
resize_pblock [get_pblocks UCAP] -add {SLICE_X15Y420:SLICE_X21Y479}
resize_pblock [get_pblocks UCAP] -add {DSP48E2_X1Y168:DSP48E2_X1Y191}
resize_pblock [get_pblocks UCAP] -add {URAM288_X0Y64:URAM288_X0Y79}
set_property EXCLUDE_PLACEMENT 1 [get_pblocks UCAP]


create_pblock CHAN0
add_cells_to_pblock [get_pblocks CHAN0] [get_cells -quiet [list {chfpga0/CHANGEN[0].CHANi}]]
resize_pblock [get_pblocks CHAN0] -add {SLICE_X26Y420:SLICE_X112Y479}
resize_pblock [get_pblocks CHAN0] -add {DSP48E2_X3Y168:DSP48E2_X21Y191}
resize_pblock [get_pblocks CHAN0] -add {RAMB18_X2Y168:RAMB18_X11Y191}
resize_pblock [get_pblocks CHAN0] -add {RAMB36_X2Y84:RAMB36_X11Y95}
set_property IS_SOFT FALSE [get_pblocks CHAN0]

create_pblock CHAN1
add_cells_to_pblock [get_pblocks CHAN1] [get_cells -quiet [list {chfpga0/CHANGEN[1].CHANi}]]
resize_pblock [get_pblocks CHAN1] -add {SLICE_X26Y360:SLICE_X112Y419}
resize_pblock [get_pblocks CHAN1] -add {DSP48E2_X3Y144:DSP48E2_X21Y167}
resize_pblock [get_pblocks CHAN1] -add {RAMB18_X2Y144:RAMB18_X11Y167}
resize_pblock [get_pblocks CHAN1] -add {RAMB36_X2Y72:RAMB36_X11Y83}
set_property IS_SOFT FALSE [get_pblocks CHAN1]

create_pblock CHAN2
add_cells_to_pblock [get_pblocks CHAN2] [get_cells -quiet [list {chfpga0/CHANGEN[2].CHANi}]]
resize_pblock [get_pblocks CHAN2] -add {SLICE_X26Y300:SLICE_X112Y359}
resize_pblock [get_pblocks CHAN2] -add {DSP48E2_X3Y120:DSP48E2_X21Y143}
resize_pblock [get_pblocks CHAN2] -add {RAMB18_X2Y120:RAMB18_X11Y143}
resize_pblock [get_pblocks CHAN2] -add {RAMB36_X2Y60:RAMB36_X11Y71}
set_property IS_SOFT FALSE [get_pblocks CHAN2]

create_pblock CHAN3
add_cells_to_pblock [get_pblocks CHAN3] [get_cells -quiet [list {chfpga0/CHANGEN[3].CHANi}]]
resize_pblock [get_pblocks CHAN3] -add {SLICE_X26Y240:SLICE_X112Y299}
resize_pblock [get_pblocks CHAN3] -add {DSP48E2_X3Y96:DSP48E2_X21Y119}
resize_pblock [get_pblocks CHAN3] -add {RAMB18_X2Y96:RAMB18_X11Y119}
resize_pblock [get_pblocks CHAN3] -add {RAMB36_X2Y48:RAMB36_X11Y59}
set_property IS_SOFT FALSE [get_pblocks CHAN3]

create_pblock CHAN4
add_cells_to_pblock [get_pblocks CHAN4] [get_cells -quiet [list {chfpga0/CHANGEN[4].CHANi}]]
resize_pblock [get_pblocks CHAN4] -add {SLICE_X26Y180:SLICE_X112Y239}
resize_pblock [get_pblocks CHAN4] -add {DSP48E2_X3Y72:DSP48E2_X21Y95}
resize_pblock [get_pblocks CHAN4] -add {RAMB18_X2Y72:RAMB18_X11Y95}
resize_pblock [get_pblocks CHAN4] -add {RAMB36_X2Y36:RAMB36_X11Y47}
set_property IS_SOFT FALSE [get_pblocks CHAN4]

create_pblock CHAN5
add_cells_to_pblock [get_pblocks CHAN5] [get_cells -quiet [list {chfpga0/CHANGEN[5].CHANi}]]
resize_pblock [get_pblocks CHAN5] -add {SLICE_X26Y120:SLICE_X112Y179}
resize_pblock [get_pblocks CHAN5] -add {DSP48E2_X3Y48:DSP48E2_X21Y71}
resize_pblock [get_pblocks CHAN5] -add {RAMB18_X2Y48:RAMB18_X11Y71}
resize_pblock [get_pblocks CHAN5] -add {RAMB36_X2Y24:RAMB36_X11Y35}
set_property IS_SOFT FALSE [get_pblocks CHAN5]

create_pblock CHAN6
add_cells_to_pblock [get_pblocks CHAN6] [get_cells -quiet [list {chfpga0/CHANGEN[6].CHANi}]]
resize_pblock [get_pblocks CHAN6] -add {SLICE_X26Y60:SLICE_X112Y119}
resize_pblock [get_pblocks CHAN6] -add {DSP48E2_X3Y24:DSP48E2_X21Y47}
resize_pblock [get_pblocks CHAN6] -add {RAMB18_X2Y24:RAMB18_X11Y47}
resize_pblock [get_pblocks CHAN6] -add {RAMB36_X2Y12:RAMB36_X11Y23}
set_property IS_SOFT FALSE [get_pblocks CHAN6]

create_pblock CHAN7
add_cells_to_pblock [get_pblocks CHAN7] [get_cells -quiet [list {chfpga0/CHANGEN[7].CHANi}]]
resize_pblock [get_pblocks CHAN7] -add {SLICE_X26Y0:SLICE_X112Y59}
resize_pblock [get_pblocks CHAN7] -add {DSP48E2_X3Y0:DSP48E2_X21Y23}
resize_pblock [get_pblocks CHAN7] -add {RAMB18_X3Y0:RAMB18_X11Y23 RAMB18_X2Y0:RAMB18_X2Y17}
resize_pblock [get_pblocks CHAN7] -add {RAMB36_X3Y0:RAMB36_X11Y11 RAMB36_X2Y0:RAMB36_X2Y8}
set_property IS_SOFT FALSE [get_pblocks CHAN7]








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
resize_pblock [get_pblocks DEBUG] -add {RAMB18_X0Y168:RAMB18_X1Y191}
resize_pblock [get_pblocks DEBUG] -add {RAMB36_X0Y84:RAMB36_X1Y95}
set_property IS_SOFT FALSE [get_pblocks DEBUG]




create_pblock SCALER0
add_cells_to_pblock [get_pblocks SCALER0] [get_cells -quiet [list {chfpga0/CHANGEN[0].CHANi/IMPL_GEN.DATA_FIFO_K7.chan_fifo0} {chfpga0/CHANGEN[0].CHANi/IMPL_GEN.scaler_blk.SCALER0}]]
resize_pblock [get_pblocks SCALER0] -add {SLICE_X26Y420:SLICE_X34Y454}
resize_pblock [get_pblocks SCALER0] -add {DSP48E2_X3Y168:DSP48E2_X4Y181}
resize_pblock [get_pblocks SCALER0] -add {RAMB18_X2Y168:RAMB18_X3Y181}
resize_pblock [get_pblocks SCALER0] -add {RAMB36_X2Y84:RAMB36_X3Y90}




create_pblock PFB0
add_cells_to_pblock [get_pblocks PFB0] [get_cells -quiet [list {chfpga0/CHANGEN[0].CHANi/IMPL_GEN.fft_blk.FFT0/FFT_GEN.fftype_gen.FFT0/U0/fft_pfb_struct/pfb_fir_real}]]
resize_pblock [get_pblocks PFB0] -add {SLICE_X106Y440:SLICE_X112Y479 SLICE_X65Y420:SLICE_X105Y479}
resize_pblock [get_pblocks PFB0] -add {DSP48E2_X21Y176:DSP48E2_X21Y191 DSP48E2_X11Y168:DSP48E2_X20Y191}
resize_pblock [get_pblocks PFB0] -add {RAMB18_X10Y176:RAMB18_X11Y191 RAMB18_X6Y168:RAMB18_X9Y191}
resize_pblock [get_pblocks PFB0] -add {RAMB36_X10Y88:RAMB36_X11Y95 RAMB36_X6Y84:RAMB36_X9Y95}

create_pblock PFB1
add_cells_to_pblock [get_pblocks PFB1] [get_cells -quiet [list {chfpga0/CHANGEN[1].CHANi/IMPL_GEN.fft_blk.FFT0/FFT_GEN.fftype_gen.FFT0/U0/fft_pfb_struct/pfb_fir_real}]]
resize_pblock [get_pblocks PFB1] -add {SLICE_X106Y380:SLICE_X112Y419 SLICE_X65Y360:SLICE_X105Y419}
resize_pblock [get_pblocks PFB1] -add {DSP48E2_X21Y152:DSP48E2_X21Y167 DSP48E2_X11Y144:DSP48E2_X20Y167}
resize_pblock [get_pblocks PFB1] -add {RAMB18_X10Y152:RAMB18_X11Y167 RAMB18_X6Y144:RAMB18_X9Y167}
resize_pblock [get_pblocks PFB1] -add {RAMB36_X10Y76:RAMB36_X11Y83 RAMB36_X6Y72:RAMB36_X9Y83}

create_pblock PFB2
add_cells_to_pblock [get_pblocks PFB2] [get_cells -quiet [list {chfpga0/CHANGEN[2].CHANi/IMPL_GEN.fft_blk.FFT0/FFT_GEN.fftype_gen.FFT0/U0/fft_pfb_struct/pfb_fir_real}]]
resize_pblock [get_pblocks PFB2] -add {SLICE_X106Y320:SLICE_X112Y359 SLICE_X65Y300:SLICE_X105Y359}
resize_pblock [get_pblocks PFB2] -add {DSP48E2_X21Y128:DSP48E2_X21Y143 DSP48E2_X11Y120:DSP48E2_X20Y143}
resize_pblock [get_pblocks PFB2] -add {RAMB18_X10Y128:RAMB18_X11Y143 RAMB18_X6Y120:RAMB18_X9Y143}
resize_pblock [get_pblocks PFB2] -add {RAMB36_X10Y64:RAMB36_X11Y71 RAMB36_X6Y60:RAMB36_X9Y71}

create_pblock PFB3
add_cells_to_pblock [get_pblocks PFB3] [get_cells -quiet [list {chfpga0/CHANGEN[3].CHANi/IMPL_GEN.fft_blk.FFT0/FFT_GEN.fftype_gen.FFT0/U0/fft_pfb_struct/pfb_fir_real}]]
resize_pblock [get_pblocks PFB3] -add {SLICE_X106Y260:SLICE_X112Y299 SLICE_X65Y240:SLICE_X105Y299}
resize_pblock [get_pblocks PFB3] -add {DSP48E2_X21Y104:DSP48E2_X21Y119 DSP48E2_X11Y96:DSP48E2_X20Y119}
resize_pblock [get_pblocks PFB3] -add {RAMB18_X10Y104:RAMB18_X11Y119 RAMB18_X6Y96:RAMB18_X9Y119}
resize_pblock [get_pblocks PFB3] -add {RAMB36_X10Y52:RAMB36_X11Y59 RAMB36_X6Y48:RAMB36_X9Y59}

create_pblock PFB4
add_cells_to_pblock [get_pblocks PFB4] [get_cells -quiet [list {chfpga0/CHANGEN[4].CHANi/IMPL_GEN.fft_blk.FFT0/FFT_GEN.fftype_gen.FFT0/U0/fft_pfb_struct/pfb_fir_real}]]
resize_pblock [get_pblocks PFB4] -add {SLICE_X106Y200:SLICE_X112Y239 SLICE_X65Y180:SLICE_X105Y239}
resize_pblock [get_pblocks PFB4] -add {DSP48E2_X21Y80:DSP48E2_X21Y95 DSP48E2_X11Y72:DSP48E2_X20Y95}
resize_pblock [get_pblocks PFB4] -add {RAMB18_X10Y80:RAMB18_X11Y95 RAMB18_X6Y72:RAMB18_X9Y95}
resize_pblock [get_pblocks PFB4] -add {RAMB36_X10Y40:RAMB36_X11Y47 RAMB36_X6Y36:RAMB36_X9Y47}

create_pblock PFB5
add_cells_to_pblock [get_pblocks PFB5] [get_cells -quiet [list {chfpga0/CHANGEN[5].CHANi/IMPL_GEN.fft_blk.FFT0/FFT_GEN.fftype_gen.FFT0/U0/fft_pfb_struct/pfb_fir_real}]]
resize_pblock [get_pblocks PFB5] -add {SLICE_X106Y140:SLICE_X112Y179 SLICE_X65Y120:SLICE_X105Y179}
resize_pblock [get_pblocks PFB5] -add {DSP48E2_X21Y56:DSP48E2_X21Y71 DSP48E2_X11Y48:DSP48E2_X20Y71}
resize_pblock [get_pblocks PFB5] -add {RAMB18_X10Y56:RAMB18_X11Y71 RAMB18_X6Y48:RAMB18_X9Y71}
resize_pblock [get_pblocks PFB5] -add {RAMB36_X10Y28:RAMB36_X11Y35 RAMB36_X6Y24:RAMB36_X9Y35}

create_pblock PFB6
add_cells_to_pblock [get_pblocks PFB6] [get_cells -quiet [list {chfpga0/CHANGEN[6].CHANi/IMPL_GEN.fft_blk.FFT0/FFT_GEN.fftype_gen.FFT0/U0/fft_pfb_struct/pfb_fir_real}]]
resize_pblock [get_pblocks PFB6] -add {SLICE_X106Y85:SLICE_X112Y119 SLICE_X65Y60:SLICE_X105Y119}
resize_pblock [get_pblocks PFB6] -add {DSP48E2_X21Y34:DSP48E2_X21Y47 DSP48E2_X11Y24:DSP48E2_X20Y47}
resize_pblock [get_pblocks PFB6] -add {RAMB18_X10Y34:RAMB18_X11Y47 RAMB18_X6Y24:RAMB18_X9Y47}
resize_pblock [get_pblocks PFB6] -add {RAMB36_X10Y17:RAMB36_X11Y23 RAMB36_X6Y12:RAMB36_X9Y23}

create_pblock PFB7
add_cells_to_pblock [get_pblocks PFB7] [get_cells -quiet [list {chfpga0/CHANGEN[7].CHANi/IMPL_GEN.fft_blk.FFT0/FFT_GEN.fftype_gen.FFT0/U0/fft_pfb_struct/pfb_fir_real}]]
resize_pblock [get_pblocks PFB7] -add {SLICE_X106Y20:SLICE_X112Y59 SLICE_X65Y0:SLICE_X105Y59}
resize_pblock [get_pblocks PFB7] -add {DSP48E2_X21Y8:DSP48E2_X21Y23 DSP48E2_X11Y0:DSP48E2_X20Y23}
resize_pblock [get_pblocks PFB7] -add {RAMB18_X10Y8:RAMB18_X11Y23 RAMB18_X6Y0:RAMB18_X9Y23}
resize_pblock [get_pblocks PFB7] -add {RAMB36_X10Y4:RAMB36_X11Y11 RAMB36_X6Y0:RAMB36_X9Y11}


create_pblock FUNCGEN0
add_cells_to_pblock [get_pblocks FUNCGEN0] [get_cells -quiet [list {chfpga0/CHANGEN[0].CHANi/IMPL_GEN.funcgen_blk.FUNCGEN0}]]
resize_pblock [get_pblocks FUNCGEN0] -add {SLICE_X106Y420:SLICE_X112Y439}
resize_pblock [get_pblocks FUNCGEN0] -add {DSP48E2_X21Y168:DSP48E2_X21Y175}
resize_pblock [get_pblocks FUNCGEN0] -add {RAMB18_X10Y168:RAMB18_X11Y175}
resize_pblock [get_pblocks FUNCGEN0] -add {RAMB36_X10Y84:RAMB36_X11Y87}
set_property IS_SOFT FALSE [get_pblocks FUNCGEN0]
create_pblock FUNCGEN1
add_cells_to_pblock [get_pblocks FUNCGEN1] [get_cells -quiet [list {chfpga0/CHANGEN[1].CHANi/IMPL_GEN.funcgen_blk.FUNCGEN0}]]
resize_pblock [get_pblocks FUNCGEN1] -add {SLICE_X106Y360:SLICE_X112Y379}
resize_pblock [get_pblocks FUNCGEN1] -add {DSP48E2_X21Y144:DSP48E2_X21Y151}
resize_pblock [get_pblocks FUNCGEN1] -add {RAMB18_X10Y144:RAMB18_X11Y151}
resize_pblock [get_pblocks FUNCGEN1] -add {RAMB36_X10Y72:RAMB36_X11Y75}
set_property IS_SOFT FALSE [get_pblocks FUNCGEN1]
create_pblock FUNCGEN2
add_cells_to_pblock [get_pblocks FUNCGEN2] [get_cells -quiet [list {chfpga0/CHANGEN[2].CHANi/IMPL_GEN.funcgen_blk.FUNCGEN0}]]
resize_pblock [get_pblocks FUNCGEN2] -add {SLICE_X106Y300:SLICE_X112Y319}
resize_pblock [get_pblocks FUNCGEN2] -add {DSP48E2_X21Y120:DSP48E2_X21Y127}
resize_pblock [get_pblocks FUNCGEN2] -add {RAMB18_X10Y120:RAMB18_X11Y127}
resize_pblock [get_pblocks FUNCGEN2] -add {RAMB36_X10Y60:RAMB36_X11Y63}
set_property IS_SOFT FALSE [get_pblocks FUNCGEN2]
create_pblock FUNCGEN3
add_cells_to_pblock [get_pblocks FUNCGEN3] [get_cells -quiet [list {chfpga0/CHANGEN[3].CHANi/IMPL_GEN.funcgen_blk.FUNCGEN0}]]
resize_pblock [get_pblocks FUNCGEN3] -add {SLICE_X106Y240:SLICE_X112Y259}
resize_pblock [get_pblocks FUNCGEN3] -add {DSP48E2_X21Y96:DSP48E2_X21Y103}
resize_pblock [get_pblocks FUNCGEN3] -add {RAMB18_X10Y96:RAMB18_X11Y103}
resize_pblock [get_pblocks FUNCGEN3] -add {RAMB36_X10Y48:RAMB36_X11Y51}
set_property IS_SOFT FALSE [get_pblocks FUNCGEN3]
create_pblock FUNCGEN4
add_cells_to_pblock [get_pblocks FUNCGEN4] [get_cells -quiet [list {chfpga0/CHANGEN[4].CHANi/IMPL_GEN.funcgen_blk.FUNCGEN0}]]
resize_pblock [get_pblocks FUNCGEN4] -add {SLICE_X106Y180:SLICE_X112Y199}
resize_pblock [get_pblocks FUNCGEN4] -add {DSP48E2_X21Y72:DSP48E2_X21Y79}
resize_pblock [get_pblocks FUNCGEN4] -add {RAMB18_X10Y72:RAMB18_X11Y79}
resize_pblock [get_pblocks FUNCGEN4] -add {RAMB36_X10Y36:RAMB36_X11Y39}
set_property IS_SOFT FALSE [get_pblocks FUNCGEN4]
create_pblock FUNCGEN5
add_cells_to_pblock [get_pblocks FUNCGEN5] [get_cells -quiet [list {chfpga0/CHANGEN[5].CHANi/IMPL_GEN.funcgen_blk.FUNCGEN0}]]
resize_pblock [get_pblocks FUNCGEN5] -add {SLICE_X106Y120:SLICE_X112Y139}
resize_pblock [get_pblocks FUNCGEN5] -add {DSP48E2_X21Y48:DSP48E2_X21Y55}
resize_pblock [get_pblocks FUNCGEN5] -add {RAMB18_X10Y48:RAMB18_X11Y55}
resize_pblock [get_pblocks FUNCGEN5] -add {RAMB36_X10Y24:RAMB36_X11Y27}
set_property IS_SOFT FALSE [get_pblocks FUNCGEN5]
create_pblock FUNCGEN6
add_cells_to_pblock [get_pblocks FUNCGEN6] [get_cells -quiet [list {chfpga0/CHANGEN[6].CHANi/IMPL_GEN.funcgen_blk.FUNCGEN0}]]
resize_pblock [get_pblocks FUNCGEN6] -add {SLICE_X106Y60:SLICE_X112Y84}
resize_pblock [get_pblocks FUNCGEN6] -add {DSP48E2_X21Y24:DSP48E2_X21Y33}
resize_pblock [get_pblocks FUNCGEN6] -add {RAMB18_X10Y24:RAMB18_X11Y33}
resize_pblock [get_pblocks FUNCGEN6] -add {RAMB36_X10Y12:RAMB36_X11Y16}
set_property IS_SOFT FALSE [get_pblocks FUNCGEN6]
create_pblock FUNCGEN7
add_cells_to_pblock [get_pblocks FUNCGEN7] [get_cells -quiet [list {chfpga0/CHANGEN[7].CHANi/IMPL_GEN.funcgen_blk.FUNCGEN0}]]
resize_pblock [get_pblocks FUNCGEN7] -add {SLICE_X106Y0:SLICE_X112Y19}
resize_pblock [get_pblocks FUNCGEN7] -add {DSP48E2_X21Y0:DSP48E2_X21Y7}
resize_pblock [get_pblocks FUNCGEN7] -add {RAMB18_X10Y0:RAMB18_X11Y7}
resize_pblock [get_pblocks FUNCGEN7] -add {RAMB36_X10Y0:RAMB36_X11Y3}
set_property IS_SOFT FALSE [get_pblocks FUNCGEN7]


create_pblock SCALER1
add_cells_to_pblock [get_pblocks SCALER1] [get_cells -quiet [list {chfpga0/CHANGEN[1].CHANi/IMPL_GEN.scaler_blk.SCALER0}]]
resize_pblock [get_pblocks SCALER1] -add {SLICE_X26Y360:SLICE_X34Y394}
resize_pblock [get_pblocks SCALER1] -add {DSP48E2_X3Y144:DSP48E2_X4Y157}
resize_pblock [get_pblocks SCALER1] -add {RAMB18_X2Y144:RAMB18_X3Y157}
resize_pblock [get_pblocks SCALER1] -add {RAMB36_X2Y72:RAMB36_X3Y78}
create_pblock SCALER2
add_cells_to_pblock [get_pblocks SCALER2] [get_cells -quiet [list {chfpga0/CHANGEN[2].CHANi/IMPL_GEN.scaler_blk.SCALER0}]]
resize_pblock [get_pblocks SCALER2] -add {SLICE_X26Y300:SLICE_X34Y334}
resize_pblock [get_pblocks SCALER2] -add {DSP48E2_X3Y120:DSP48E2_X4Y133}
resize_pblock [get_pblocks SCALER2] -add {RAMB18_X2Y120:RAMB18_X3Y133}
resize_pblock [get_pblocks SCALER2] -add {RAMB36_X2Y60:RAMB36_X3Y66}
create_pblock SCALER3
add_cells_to_pblock [get_pblocks SCALER3] [get_cells -quiet [list {chfpga0/CHANGEN[3].CHANi/IMPL_GEN.scaler_blk.SCALER0}]]
resize_pblock [get_pblocks SCALER3] -add {SLICE_X26Y240:SLICE_X34Y274}
resize_pblock [get_pblocks SCALER3] -add {DSP48E2_X3Y96:DSP48E2_X4Y109}
resize_pblock [get_pblocks SCALER3] -add {RAMB18_X2Y96:RAMB18_X3Y109}
resize_pblock [get_pblocks SCALER3] -add {RAMB36_X2Y48:RAMB36_X3Y54}
create_pblock SCALER4
add_cells_to_pblock [get_pblocks SCALER4] [get_cells -quiet [list {chfpga0/CHANGEN[4].CHANi/IMPL_GEN.scaler_blk.SCALER0}]]
resize_pblock [get_pblocks SCALER4] -add {SLICE_X26Y180:SLICE_X34Y214}
resize_pblock [get_pblocks SCALER4] -add {DSP48E2_X3Y72:DSP48E2_X4Y85}
resize_pblock [get_pblocks SCALER4] -add {RAMB18_X2Y72:RAMB18_X3Y85}
resize_pblock [get_pblocks SCALER4] -add {RAMB36_X2Y36:RAMB36_X3Y42}
create_pblock SCALER5
add_cells_to_pblock [get_pblocks SCALER5] [get_cells -quiet [list {chfpga0/CHANGEN[5].CHANi/IMPL_GEN.scaler_blk.SCALER0}]]
resize_pblock [get_pblocks SCALER5] -add {SLICE_X26Y120:SLICE_X34Y154}
resize_pblock [get_pblocks SCALER5] -add {DSP48E2_X3Y48:DSP48E2_X4Y61}
resize_pblock [get_pblocks SCALER5] -add {RAMB18_X2Y48:RAMB18_X3Y61}
resize_pblock [get_pblocks SCALER5] -add {RAMB36_X2Y24:RAMB36_X3Y30}
create_pblock SCALER6
add_cells_to_pblock [get_pblocks SCALER6] [get_cells -quiet [list {chfpga0/CHANGEN[6].CHANi/IMPL_GEN.scaler_blk.SCALER0}]]
resize_pblock [get_pblocks SCALER6] -add {SLICE_X26Y60:SLICE_X34Y94}
resize_pblock [get_pblocks SCALER6] -add {DSP48E2_X3Y24:DSP48E2_X4Y37}
resize_pblock [get_pblocks SCALER6] -add {RAMB18_X2Y24:RAMB18_X3Y37}
resize_pblock [get_pblocks SCALER6] -add {RAMB36_X2Y12:RAMB36_X3Y18}
create_pblock SCALER7
add_cells_to_pblock [get_pblocks SCALER7] [get_cells -quiet [list {chfpga0/CHANGEN[7].CHANi/IMPL_GEN.scaler_blk.SCALER0}]]
resize_pblock [get_pblocks SCALER7] -add {SLICE_X26Y0:SLICE_X34Y34}
resize_pblock [get_pblocks SCALER7] -add {DSP48E2_X3Y0:DSP48E2_X4Y13}
resize_pblock [get_pblocks SCALER7] -add {RAMB18_X2Y0:RAMB18_X3Y13}
resize_pblock [get_pblocks SCALER7] -add {RAMB36_X2Y0:RAMB36_X3Y6}




