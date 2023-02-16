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

# PL_CLK, Fabric signal processing word clock (programmable, must be ADC sampling freq / 8 samples/word)
set pin [get_ports {clk200_clk_p}];
set_property PACKAGE_PIN G17     $pin; # Bank  69 VCC1V8
set_property IOSTANDARD  LVDS     $pin;
set_property DIFF_TERM_ADV TERM_100  $pin;
create_clock -name PL_CLK -period 5 $pin

# SYSREF clock, 0.75 MHz, used to synchronize all the PLLs. A copy of this signal (RF_SYSREF) also goes to the ADC/DACs
set pin [get_ports {clk10_clk_p}];
set_property PACKAGE_PIN H18     $pin; # Bank  69 VCC1V8
set_property IOSTANDARD  LVDS     $pin;
set_property DIFF_TERM  TRUE     $pin;
create_clock -name PL_SYSREF -period 100 $pin

# # Recovered clock output (not used)
# set_property PACKAGE_PIN C84     [get_ports {pl_recclk_p}]; # Bank  69 VCC1V8
# set_property IOSTANDARD  LVDS     [get_ports {pl_recclk_p}];

# 100 MHz clock provided by the PS to the PL is not in phase with any other clock
set_clock_groups -name BSB_CLK_GROUP -asynchronous -group [get_clocks clk_pl_0]


# #############################################
# # Buck SYNC signals
# #############################################

set_property IOSTANDARD  LVCMOS33 [get_ports {buck_sync_*}]

set_property PACKAGE_PIN AP5       [get_ports {buck_sync_5v0}] ; # Bank  84 VCC3V3
set_property PACKAGE_PIN AP6       [get_ports {buck_sync_0v85}] ; # Bank  84 VCC3V3
set_property PACKAGE_PIN AR6       [get_ports {buck_sync_3v3}] ; # Bank  84 VCC3V3
set_property PACKAGE_PIN AR7       [get_ports {buck_sync_2v5}] ; # Bank  84 VCC3V3
set_property PACKAGE_PIN AV7       [get_ports {buck_sync_1v8}] ; # Bank  84 VCC3V3
set_property PACKAGE_PIN AU7       [get_ports {buck_sync_1v2a}] ; # Bank  84 VCC3V3
set_property PACKAGE_PIN AV8       [get_ports {buck_sync_1v2b}] ; # Bank  84 VCC3V3
set_property PACKAGE_PIN AU8       [get_ports {buck_sync_1v4}] ; # Bank  84 VCC3V3
set_property PACKAGE_PIN AT7       [get_ports {buck_sync_bp}] ; # Bank  84 VCC3V3

# #################
# # SMP (on-board clip-on coax) connectors and testpoints
# #################
set_property PACKAGE_PIN B9       [get_ports {smp[0]}] ; # Bank  87 VCC3V3
set_property IOSTANDARD  LVCMOS33 [get_ports {smp[0]}] ;
set_property PACKAGE_PIN B10      [get_ports {smp[1]}] ; # Bank  87 VCC3V3
set_property IOSTANDARD  LVCMOS33 [get_ports {smp[1]}] ;
set_property PACKAGE_PIN B7       [get_ports {smp[2]}] ; # Bank  87 VCC3V3
set_property IOSTANDARD  LVCMOS33 [get_ports {smp[2]}] ;
set_property PACKAGE_PIN B8       [get_ports {smp[3]}] ; # Bank  87 VCC3V3
set_property IOSTANDARD  LVCMOS33 [get_ports {smp[3]}] ;

# set_property PACKAGE_PIN F8       [get_ports {tp13}] ; # Bank  87 VCC3V3
# set_property IOSTANDARD  LVCMOS33 [get_ports {tp13}] ;

# -- GTY QSFP28 ports - Bank 128
set_property PACKAGE_PIN Y35       [get_ports {qsfp_txp[0]}] ;
set_property PACKAGE_PIN V35       [get_ports {qsfp_txp[1]}] ;
set_property PACKAGE_PIN T35       [get_ports {qsfp_txp[2]}] ;
set_property PACKAGE_PIN R33       [get_ports {qsfp_txp[3]}] ;

# GTY reference clock, 156.25 MHz from fixed PLL, Bank 129
set_property PACKAGE_PIN W33       [get_ports {clk156_p}]; # GTY_CLK0_P129, Bank 129

# ignore timing between CLK200 and CORR_CLK  domains. This line has to be placed after we have defines the source clock for the two specified derived clocks
# set_false_path -from [get_clocks CLK200_MMCM_NOBUF] -to [get_clocks {CORR_CLK_NOBUF}]




########################################
# RESET
########################################
#set_property PACKAGE_PIN AF15     [get_ports "CPU_RESET"] ;# Bank  64 VCCO - VCC1V8   - IO_T2U_N12_64
#set_property IOSTANDARD  LVCMOS18 [get_ports "CPU_RESET"] ;# Bank  64 VCCO - VCC1V8   - IO_T2U_N12_64




