# Common constraints are in ice_physical_constraints_common.xdc


##############################
# LOCATION CONSTRAINTS
##############################

### MMCMs ###
# We need to put the ADCDAQ PLL in the same bank as the BUFR that drives it (Bank 13)
#set_property LOC MMCME2_ADV_X0Y3 [get_cells {chfpga0/chan_array0/adc_gen.ev8aq160_case.adcgen[0].adcdaq0/IMPL.USEPLL.PLL0/U0/mmcm_adv_inst}]
# The Channelizer MMCM has 2 inputs:  adcdaq0 and System MMCM (CLK200). If Tey are there were driven directly (no BUFG) by both the ADCDAQ BUFR and Sysntem MMCM output, . The MMCM must be adjacent, but on a half that has enough BUFGs
#set_property LOC MMCME2_ADV_X0Y3 [get_cells chfpga0/clk0/gen_chanpll_k7.chan_mmcm0]
#set_property LOC MMCME2_ADV_X0Y3 [get_cells chfpga0/clk0/gen_chanpll_k7.mmcm_case.chan_mmcm0]
# The system MMCM also drives the Channelizer MMCM, and also needs to be adjacent.

set_property LOC BUFGCTRL_X0Y18 [get_cells chfpga0/GPU_GEN.gpu_sel_gen.gpulink0/xglink0/txoutclk_bufg0]
set_property LOC BUFGCTRL_X0Y19 [get_cells chfpga0/GPU_GEN.gpu_sel_gen.gpulink0/xglink0/refclk_bufg0]




# ###################################
# # AREA Contraints
# ###################################

create_pblock CHAN0
add_cells_to_pblock [get_pblocks CHAN0] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[0].chan0}]]
resize_pblock [get_pblocks CHAN0] -add {SLICE_X8Y175:SLICE_X155Y199}
resize_pblock [get_pblocks CHAN0] -add {DSP48_X0Y70:DSP48_X9Y79}
resize_pblock [get_pblocks CHAN0] -add {RAMB18_X1Y70:RAMB18_X9Y79 RAMB18_X0Y74:RAMB18_X0Y79}
resize_pblock [get_pblocks CHAN0] -add {RAMB36_X1Y35:RAMB36_X9Y39 RAMB36_X0Y37:RAMB36_X0Y39}
set_property IS_SOFT FALSE [get_pblocks CHAN0]

# add_cells_to_pblock [get_pblocks CHAN0] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[0].chan0}]]

create_pblock CHAN1
add_cells_to_pblock [get_pblocks CHAN1] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[1].chan0}]]
resize_pblock [get_pblocks CHAN1] -add {SLICE_X8Y150:SLICE_X155Y174}
resize_pblock [get_pblocks CHAN1] -add {DSP48_X0Y60:DSP48_X9Y69}
resize_pblock [get_pblocks CHAN1] -add {RAMB18_X1Y60:RAMB18_X9Y69 RAMB18_X0Y60:RAMB18_X0Y65}
resize_pblock [get_pblocks CHAN1] -add {RAMB36_X1Y30:RAMB36_X9Y34 RAMB36_X0Y30:RAMB36_X0Y32}
set_property IS_SOFT FALSE [get_pblocks CHAN1]
# add_cells_to_pblock [get_pblocks CHAN1] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[1].chan0}]]

create_pblock CHAN2
add_cells_to_pblock [get_pblocks CHAN2] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[2].chan0}]]
resize_pblock [get_pblocks CHAN2] -add {SLICE_X8Y125:SLICE_X141Y149}
resize_pblock [get_pblocks CHAN2] -add {DSP48_X0Y50:DSP48_X8Y59}
resize_pblock [get_pblocks CHAN2] -add {RAMB18_X1Y50:RAMB18_X8Y59 RAMB18_X0Y54:RAMB18_X0Y59}
resize_pblock [get_pblocks CHAN2] -add {RAMB36_X1Y25:RAMB36_X8Y29 RAMB36_X0Y27:RAMB36_X0Y29}
set_property IS_SOFT FALSE [get_pblocks CHAN2]

# add_cells_to_pblock [get_pblocks CHAN2] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[2].chan0}]]
create_pblock CHAN3
add_cells_to_pblock [get_pblocks CHAN3] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[3].chan0}]]
resize_pblock [get_pblocks CHAN3] -add {SLICE_X8Y100:SLICE_X141Y124}
resize_pblock [get_pblocks CHAN3] -add {DSP48_X0Y40:DSP48_X8Y49}
resize_pblock [get_pblocks CHAN3] -add {RAMB18_X1Y40:RAMB18_X8Y49 RAMB18_X0Y44:RAMB18_X0Y49}
resize_pblock [get_pblocks CHAN3] -add {RAMB36_X1Y20:RAMB36_X8Y24 RAMB36_X0Y22:RAMB36_X0Y24}
set_property IS_SOFT FALSE [get_pblocks CHAN3]

# add_cells_to_pblock [get_pblocks CHAN3] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[3].chan0}]]

create_pblock CHAN4
add_cells_to_pblock [get_pblocks CHAN4] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[4].chan0}]]
resize_pblock [get_pblocks CHAN4] -add {SLICE_X8Y0:SLICE_X141Y24}
resize_pblock [get_pblocks CHAN4] -add {DSP48_X0Y0:DSP48_X8Y9}
resize_pblock [get_pblocks CHAN4] -add {RAMB18_X1Y0:RAMB18_X8Y9 RAMB18_X0Y0:RAMB18_X0Y5}
resize_pblock [get_pblocks CHAN4] -add {RAMB36_X1Y0:RAMB36_X8Y4 RAMB36_X0Y0:RAMB36_X0Y2}
# add_cells_to_pblock [get_pblocks CHAN4] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[4].chan0}]]
# set_property IS_SOFT FALSE [get_pblocks CHAN4]

create_pblock CHAN5
add_cells_to_pblock [get_pblocks CHAN5] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[5].chan0}]]
resize_pblock [get_pblocks CHAN5] -add {SLICE_X8Y25:SLICE_X141Y49}
resize_pblock [get_pblocks CHAN5] -add {DSP48_X0Y10:DSP48_X8Y19}
resize_pblock [get_pblocks CHAN5] -add {RAMB18_X1Y10:RAMB18_X8Y19 RAMB18_X0Y10:RAMB18_X0Y15}
resize_pblock [get_pblocks CHAN5] -add {RAMB36_X1Y5:RAMB36_X8Y9 RAMB36_X0Y5:RAMB36_X0Y7}
# add_cells_to_pblock [get_pblocks CHAN5] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[5].chan0}]]
# set_property IS_SOFT FALSE [get_pblocks CHAN5]

create_pblock CHAN6
add_cells_to_pblock [get_pblocks CHAN6] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[6].chan0}]]
resize_pblock [get_pblocks CHAN6] -add {SLICE_X8Y50:SLICE_X141Y74}
resize_pblock [get_pblocks CHAN6] -add {DSP48_X0Y20:DSP48_X8Y29}
resize_pblock [get_pblocks CHAN6] -add {RAMB18_X1Y20:RAMB18_X8Y29 RAMB18_X0Y20:RAMB18_X0Y25}
resize_pblock [get_pblocks CHAN6] -add {RAMB36_X1Y10:RAMB36_X8Y14 RAMB36_X0Y10:RAMB36_X0Y12}
# add_cells_to_pblock [get_pblocks CHAN6] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[6].chan0}]]
# set_property IS_SOFT FALSE [get_pblocks CHAN6]

create_pblock CHAN7
add_cells_to_pblock [get_pblocks CHAN7] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[7].chan0}]]
resize_pblock [get_pblocks CHAN7] -add {SLICE_X8Y75:SLICE_X141Y99}
resize_pblock [get_pblocks CHAN7] -add {DSP48_X0Y30:DSP48_X8Y39}
resize_pblock [get_pblocks CHAN7] -add {RAMB18_X1Y30:RAMB18_X8Y39 RAMB18_X0Y34:RAMB18_X0Y39}
resize_pblock [get_pblocks CHAN7] -add {RAMB36_X1Y15:RAMB36_X8Y19 RAMB36_X0Y17:RAMB36_X0Y19}
# add_cells_to_pblock [get_pblocks CHAN7] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[7].chan0}]]
# set_property IS_SOFT FALSE [get_pblocks CHAN7]



create_pblock CHAN8
add_cells_to_pblock [get_pblocks CHAN8] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[8].chan0}]]
resize_pblock [get_pblocks CHAN8] -add {SLICE_X8Y275:SLICE_X141Y299}
resize_pblock [get_pblocks CHAN8] -add {DSP48_X0Y110:DSP48_X8Y119}
resize_pblock [get_pblocks CHAN8] -add {RAMB18_X1Y110:RAMB18_X8Y119 RAMB18_X0Y110:RAMB18_X0Y115}
resize_pblock [get_pblocks CHAN8] -add {RAMB36_X1Y55:RAMB36_X8Y59 RAMB36_X0Y55:RAMB36_X0Y57}
# add_cells_to_pblock [get_pblocks CHAN8] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[8].chan0}]]

create_pblock CHAN14
add_cells_to_pblock [get_pblocks CHAN14] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[14].chan0}]]
resize_pblock [get_pblocks CHAN14] -add {SLICE_X8Y375:SLICE_X141Y399}
resize_pblock [get_pblocks CHAN14] -add {DSP48_X0Y150:DSP48_X8Y159}
resize_pblock [get_pblocks CHAN14] -add {RAMB18_X1Y150:RAMB18_X8Y159 RAMB18_X0Y154:RAMB18_X0Y159}
resize_pblock [get_pblocks CHAN14] -add {RAMB36_X1Y75:RAMB36_X8Y79 RAMB36_X0Y77:RAMB36_X0Y79}
# add_cells_to_pblock [get_pblocks CHAN14] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[14].chan0}]]

create_pblock CHAN15
add_cells_to_pblock [get_pblocks CHAN15] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[15].chan0}]]
resize_pblock [get_pblocks CHAN15] -add {SLICE_X8Y350:SLICE_X141Y374}
resize_pblock [get_pblocks CHAN15] -add {DSP48_X0Y140:DSP48_X8Y149}
resize_pblock [get_pblocks CHAN15] -add {RAMB18_X1Y140:RAMB18_X8Y149 RAMB18_X0Y140:RAMB18_X0Y145}
resize_pblock [get_pblocks CHAN15] -add {RAMB36_X1Y70:RAMB36_X8Y74 RAMB36_X0Y70:RAMB36_X0Y72}
# add_cells_to_pblock [get_pblocks CHAN15] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[15].chan0}]]

create_pblock CHAN11
add_cells_to_pblock [get_pblocks CHAN11] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[11].chan0}]]
resize_pblock [get_pblocks CHAN11] -add {SLICE_X8Y325:SLICE_X141Y349}
resize_pblock [get_pblocks CHAN11] -add {DSP48_X0Y130:DSP48_X8Y139}
resize_pblock [get_pblocks CHAN11] -add {RAMB18_X1Y130:RAMB18_X8Y139 RAMB18_X0Y130:RAMB18_X0Y135}
resize_pblock [get_pblocks CHAN11] -add {RAMB36_X1Y65:RAMB36_X8Y69 RAMB36_X0Y65:RAMB36_X0Y67}
# add_cells_to_pblock [get_pblocks CHAN11] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[11].chan0}]]

create_pblock CHAN10
add_cells_to_pblock [get_pblocks CHAN10] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[10].chan0}]]
resize_pblock [get_pblocks CHAN10] -add {SLICE_X8Y300:SLICE_X141Y324}
resize_pblock [get_pblocks CHAN10] -add {DSP48_X0Y120:DSP48_X8Y129}
resize_pblock [get_pblocks CHAN10] -add {RAMB18_X1Y120:RAMB18_X8Y129 RAMB18_X0Y124:RAMB18_X0Y129}
resize_pblock [get_pblocks CHAN10] -add {RAMB36_X1Y60:RAMB36_X8Y64 RAMB36_X0Y62:RAMB36_X0Y64}
# add_cells_to_pblock [get_pblocks CHAN10] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[10].chan0}]]

create_pblock CHAN9
add_cells_to_pblock [get_pblocks CHAN9] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[9].chan0}]]
resize_pblock [get_pblocks CHAN9] -add {SLICE_X8Y250:SLICE_X141Y274}
resize_pblock [get_pblocks CHAN9] -add {DSP48_X0Y100:DSP48_X8Y109}
resize_pblock [get_pblocks CHAN9] -add {RAMB18_X1Y100:RAMB18_X8Y109 RAMB18_X0Y100:RAMB18_X0Y105}
resize_pblock [get_pblocks CHAN9] -add {RAMB36_X1Y50:RAMB36_X8Y54 RAMB36_X0Y50:RAMB36_X0Y52}
# add_cells_to_pblock [get_pblocks CHAN9] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[9].chan0}]]


create_pblock CHAN12
add_cells_to_pblock [get_pblocks CHAN12] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[12].chan0}]]
resize_pblock [get_pblocks CHAN12] -add {SLICE_X8Y200:SLICE_X155Y224}
resize_pblock [get_pblocks CHAN12] -add {DSP48_X0Y80:DSP48_X9Y89}
resize_pblock [get_pblocks CHAN12] -add {RAMB18_X1Y80:RAMB18_X9Y89 RAMB18_X0Y80:RAMB18_X0Y85}
resize_pblock [get_pblocks CHAN12] -add {RAMB36_X1Y40:RAMB36_X9Y44 RAMB36_X0Y40:RAMB36_X0Y42}
# add_cells_to_pblock [get_pblocks CHAN12] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[12].chan0}]]

create_pblock CHAN13
add_cells_to_pblock [get_pblocks CHAN13] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[13].chan0}]]
resize_pblock [get_pblocks CHAN13] -add {SLICE_X142Y225:SLICE_X155Y234 SLICE_X8Y225:SLICE_X141Y249}
resize_pblock [get_pblocks CHAN13] -add {DSP48_X9Y90:DSP48_X9Y93 DSP48_X0Y90:DSP48_X8Y99}
resize_pblock [get_pblocks CHAN13] -add {RAMB18_X9Y90:RAMB18_X9Y93 RAMB18_X1Y90:RAMB18_X8Y99}
resize_pblock [get_pblocks CHAN13] -add {RAMB36_X9Y45:RAMB36_X9Y46 RAMB36_X1Y45:RAMB36_X8Y49}
# add_cells_to_pblock [get_pblocks CHAN13] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[13].chan0}]]

set_property LOC DNA_PORT_X0Y0 [get_cells chfpga0/*.system0/*.gpio0/gen_dna7.dna0]



create_pblock SYSTEM
add_cells_to_pblock [get_pblocks SYSTEM] [get_cells -quiet [list chfpga0/*.system0/blinker_blk.blinker0 chfpga0/*.system0/freq_ctr_blk.freq_ctr0 chfpga0/*.system0/gen_i2c.I2C0 chfpga0/*.system0/gen_spi.spi0 chfpga0/*.system0/gpio_blk.gpio0/core_regs0 chfpga0/*.system0/gpio_blk.gpio0/irigb_comparator0 chfpga0/*.system0/gpio_blk.gpio0/irigb_decoder0 chfpga0/*.system0/gpio_blk.gpio0/irigb_encoder0]]
resize_pblock [get_pblocks SYSTEM] -add {SLICE_X166Y350:SLICE_X189Y374}
resize_pblock [get_pblocks SYSTEM] -add {DSP48_X11Y140:DSP48_X11Y149}
resize_pblock [get_pblocks SYSTEM] -add {RAMB18_X11Y140:RAMB18_X11Y149}
resize_pblock [get_pblocks SYSTEM] -add {RAMB36_X11Y70:RAMB36_X11Y74}

create_pblock UDP_MAC
add_cells_to_pblock [get_pblocks UDP_MAC] [get_cells -quiet [list chfpga0/bsb_master_blk.ctrl_master0 chfpga0/gen_eth.phy_case.udp_mac0]]
resize_pblock [get_pblocks UDP_MAC] -add {SLICE_X142Y235:SLICE_X189Y249}
resize_pblock [get_pblocks UDP_MAC] -add {DSP48_X9Y94:DSP48_X11Y99}
resize_pblock [get_pblocks UDP_MAC] -add {RAMB18_X9Y94:RAMB18_X11Y99}
resize_pblock [get_pblocks UDP_MAC] -add {RAMB36_X9Y47:RAMB36_X11Y49}


create_pblock CLK0
add_cells_to_pblock [get_pblocks CLK0] [get_cells -quiet [list chfpga0/clk0]]
resize_pblock [get_pblocks CLK0] -add {SLICE_X0Y248:SLICE_X7Y249 SLICE_X0Y150:SLICE_X7Y151}


create_pblock ARM_SPI
add_cells_to_pblock [get_pblocks ARM_SPI] [get_cells -quiet [list chfpga0/*.system0/*.gpio0/gen_armspi.arm_spi0]]
resize_pblock [get_pblocks ARM_SPI] -add {SLICE_X0Y187:SLICE_X7Y206}

# create_pblock I2C
# resize_pblock [get_pblocks I2C] -add {SLICE_X0Y200:SLICE_X7Y204}

# create_pblock SPI
# resize_pblock [get_pblocks SPI] -add {SLICE_X0Y93:SLICE_X7Y95}

# create_pblock BP_BUCK_SYNC
# resize_pblock [get_pblocks BP_BUCK_SYNC] -add {SLICE_X0Y117:SLICE_X7Y124}

#create_pblock BP0
#add_cells_to_pblock [get_pblocks BP0] [get_cells { {chfpga0/*.ct0/*.bp_shuffle0/core0/*x_gen[0].*} {chfpga0/*.ct0/*.bp_shuffle0/core0/*x_gen[1].*} {chfpga0/*.ct0/*.bp_shuffle0/core0/*x_gen[2].*} {chfpga0/*.ct0/*.bp_shuffle0/core0/*x_gen[3].*} {chfpga0/*.ct0/*.bp_shuffle0/lane_gen[0].*} {chfpga0/*.ct0/*.bp_shuffle0/lane_gen[1].*} {chfpga0/*.ct0/*.bp_shuffle0/lane_gen[2].*} {chfpga0/*.ct0/*.bp_shuffle0/lane_gen[3].*} {chfpga0/*.ct0/*.bp_shuffle0/lane_gen[4].*} {chfpga0/*.ct0/*.chan_crossbar0/BIN_SEL_GEN[0].*} {chfpga0/*.ct0/*.chan_crossbar0/BIN_SEL_GEN[1].*} {chfpga0/*.ct0/*.chan_crossbar0/BIN_SEL_GEN[2].*} {chfpga0/*.ct0/*.chan_crossbar0/BIN_SEL_GEN[3].*} {chfpga0/*.ct0/*.chan_crossbar0/BIN_SEL_GEN[4].*} }]
# Below may be too tight
# resize_pblock [get_pblocks BP0] -add {SLICE_X144Y160:SLICE_X189Y199}
# resize_pblock [get_pblocks BP0] -add {DSP48_X10Y64:DSP48_X11Y79}
# resize_pblock [get_pblocks BP0] -add {RAMB18_X9Y64:RAMB18_X11Y79}
# resize_pblock [get_pblocks BP0] -add {RAMB36_X9Y32:RAMB36_X11Y39}


# add_cells_to_pblock [get_pblocks BP1] [get_cells { {chfpga0/*.ct0/*.bp_shuffle0/core0/*x_gen[4].*} {chfpga0/*.ct0/*.bp_shuffle0/core0/*x_gen[5].*} {chfpga0/*.ct0/*.bp_shuffle0/core0/*x_gen[6].*} {chfpga0/*.ct0/*.bp_shuffle0/core0/*x_gen[7].*} {chfpga0/*.ct0/*.bp_shuffle0/lane_gen[5].*} {chfpga0/*.ct0/*.bp_shuffle0/lane_gen[6].*} {chfpga0/*.ct0/*.bp_shuffle0/lane_gen[7].*} {chfpga0/*.ct0/*.bp_shuffle0/lane_gen[8].*} {chfpga0/*.ct0/*.chan_crossbar0/BIN_SEL_GEN[5].*} {chfpga0/*.ct0/*.chan_crossbar0/BIN_SEL_GEN[6].*} {chfpga0/*.ct0/*.chan_crossbar0/BIN_SEL_GEN[7].*} {chfpga0/*.ct0/*.chan_crossbar0/BIN_SEL_GEN[8].*} }]
# Below may be too tight
# resize_pblock [get_pblocks BP1] -add {SLICE_X144Y0:SLICE_X189Y39}
# resize_pblock [get_pblocks BP1] -add {DSP48_X10Y0:DSP48_X11Y15}


# add_cells_to_pblock [get_pblocks BP2] [get_cells { {chfpga0/*.ct0/*.bp_shuffle0/core0/*x_gen[8].*} {chfpga0/*.ct0/*.bp_shuffle0/core0/*x_gen[9].*} {chfpga0/*.ct0/*.bp_shuffle0/core0/*x_gen[10].*} {chfpga0/*.ct0/*.bp_shuffle0/core0/*x_gen[11].*} {chfpga0/*.ct0/*.bp_shuffle0/lane_gen[9].*} {chfpga0/*.ct0/*.bp_shuffle0/lane_gen[10].*} {chfpga0/*.ct0/*.bp_shuffle0/lane_gen[11].*} {chfpga0/*.ct0/*.bp_shuffle0/lane_gen[12].*} {chfpga0/*.ct0/*.chan_crossbar0/BIN_SEL_GEN[9].*} {chfpga0/*.ct0/*.chan_crossbar0/BIN_SEL_GEN[10].*} {chfpga0/*.ct0/*.chan_crossbar0/BIN_SEL_GEN[11].*} {chfpga0/*.ct0/*.chan_crossbar0/BIN_SEL_GEN[12].*} }]
# Below may be too tight
# resize_pblock [get_pblocks BP2] -add {SLICE_X180Y45:SLICE_X189Y94 SLICE_X144Y45:SLICE_X179Y74}
# resize_pblock [get_pblocks BP2] -add {DSP48_X11Y18:DSP48_X11Y37 DSP48_X10Y18:DSP48_X10Y29}
# resize_pblock [get_pblocks BP2] -add {RAMB18_X9Y18:RAMB18_X11Y29}
# resize_pblock [get_pblocks BP2] -add {RAMB36_X9Y9:RAMB36_X11Y14}


# add_cells_to_pblock [get_pblocks BP3] [get_cells { {chfpga0/*.ct0/*.bp_shuffle0/core0/*x_gen[12].*} {chfpga0/*.ct0/*.bp_shuffle0/core0/*x_gen[13].*} {chfpga0/*.ct0/*.bp_shuffle0/core0/*x_gen[14].*} {chfpga0/*.ct0/*.bp_shuffle0/lane_gen[13].*} {chfpga0/*.ct0/*.bp_shuffle0/lane_gen[14].*} {chfpga0/*.ct0/*.bp_shuffle0/lane_gen[15].*} {chfpga0/*.ct0/*.chan_crossbar0/BIN_SEL_GEN[13].*} {chfpga0/*.ct0/*.chan_crossbar0/BIN_SEL_GEN[14].*} {chfpga0/*.ct0/*.chan_crossbar0/BIN_SEL_GEN[15].*} }]
# Below may be too tight
# resize_pblock [get_pblocks BP3] -add {SLICE_X140Y210:SLICE_X189Y234}
# resize_pblock [get_pblocks BP3] -add {DSP48_X9Y84:DSP48_X11Y93}
# resize_pblock [get_pblocks BP3] -add {RAMB18_X9Y84:RAMB18_X11Y93}
# resize_pblock [get_pblocks BP3] -add {RAMB36_X9Y42:RAMB36_X11Y46}


# add_cells_to_pblock [get_pblocks BP4] [get_cells  { chfpga0/*.ct0/*.crossbar2/align0 {chfpga0/*.ct0/*.crossbar2/BIN_SEL_GEN[0].*} {chfpga0/*.ct0/*.crossbar2/BIN_SEL_GEN[1].*} chfpga0/*.ct0/*.crossbar2/bsb_regs0 chfpga0/*.ct0/*.crossbar2/crossbar_router0 chfpga0/*.ct0/*.crossbar2/remap0
# {chfpga0/*.ct0/*.bp_shuffle0/core0/*x_gen[15].*} {chfpga0/*.ct0/*.bp_shuffle0/core0/*x_gen[16].*} {chfpga0/*.ct0/*.bp_shuffle0/core0/*x_gen[17].*} {chfpga0/*.ct0/*.bp_shuffle0/core0/*x_gen[18].*}
# {chfpga0/*.ct0/*.bp_shuffle0/lane_gen[16].*} {chfpga0/*.ct0/*.bp_shuffle0/lane_gen[17].*} {chfpga0/*.ct0/*.bp_shuffle0/lane_gen[18].*} {chfpga0/*.ct0/*.bp_shuffle0/lane_gen[19].*} {chfpga0/*.ct0/*.bp_shuffle0/lane_gen[20].*} {chfpga0/*.ct0/*.bp_shuffle0/lane_gen[21].*} {chfpga0/*.ct0/*.bp_shuffle0/lane_gen[22].*} {chfpga0/*.ct0/*.bp_shuffle0/lane_gen[23].*}
# }]

# Not included
# {chfpga0/*.ct0/*.chan_crossbar0/BIN_SEL_GEN[16].*} # {chfpga0/*.ct0/*.chan_crossbar0/BIN_SEL_GEN[17].*} # {chfpga0/*.ct0/*.chan_crossbar0/BIN_SEL_GEN[18].*} # {chfpga0/*.ct0/*.chan_crossbar0/BIN_SEL_GEN[19].*} # {chfpga0/*.ct0/*.chan_crossbar0/BIN_SEL_GEN[20].*} # {chfpga0/*.ct0/*.chan_crossbar0/BIN_SEL_GEN[21].*} # {chfpga0/*.ct0/*.chan_crossbar0/BIN_SEL_GEN[22].*} # {chfpga0/*.ct0/*.chan_crossbar0/BIN_SEL_GEN[23].*}
# below may be too tight
# resize_pblock [get_pblocks BP4] -add {SLICE_X140Y95:SLICE_X189Y159 SLICE_X166Y85:SLICE_X179Y94}
# resize_pblock [get_pblocks BP4] -add {DSP48_X9Y38:DSP48_X11Y63}
# resize_pblock [get_pblocks BP4] -add {RAMB18_X11Y34:RAMB18_X11Y63 RAMB18_X9Y38:RAMB18_X10Y63}
# resize_pblock [get_pblocks BP4] -add {RAMB36_X11Y17:RAMB36_X11Y31 RAMB36_X9Y19:RAMB36_X10Y31}
# set_property EXCLUDE_PLACEMENT TRUE [get_pblocks BP4]


# add_cells_to_pblock [get_pblocks ALIGN2] [get_cells -quiet { chfpga0/*.ct0/*.chan_crossbar0/bsb_regs0 chfpga0/*.ct0/*.chan_crossbar0/align0 }]

# set_property IS_SOFT FALSE [get_pblocks ALIGN2]


# set_property IS_SOFT FALSE [get_pblocks ALIGN3]


create_pblock GPU0
add_cells_to_pblock [get_pblocks GPU0] [get_cells -quiet [list {chfpga0/GPU_GEN.gpu_sel_gen.gpulink0/udp_gen[0].udp0} {chfpga0/GPU_GEN.gpu_sel_gen.gpulink0/udp_gen[1].udp0}]]
resize_pblock [get_pblocks GPU0] -add {SLICE_X166Y250:SLICE_X189Y269}
resize_pblock [get_pblocks GPU0] -add {DSP48_X11Y100:DSP48_X11Y107}
resize_pblock [get_pblocks GPU0] -add {RAMB18_X11Y100:RAMB18_X11Y107}
resize_pblock [get_pblocks GPU0] -add {RAMB36_X11Y50:RAMB36_X11Y53}

# set_property IS_SOFT FALSE [get_pblocks GPU0]


create_pblock GPU1
add_cells_to_pblock [get_pblocks GPU1] [get_cells -quiet [list {chfpga0/GPU_GEN.gpu_sel_gen.gpulink0/udp_gen[2].udp0} {chfpga0/GPU_GEN.gpu_sel_gen.gpulink0/udp_gen[3].udp0}]]
resize_pblock [get_pblocks GPU1] -add {SLICE_X166Y270:SLICE_X189Y289}
resize_pblock [get_pblocks GPU1] -add {DSP48_X11Y108:DSP48_X11Y115}
resize_pblock [get_pblocks GPU1] -add {RAMB18_X11Y108:RAMB18_X11Y115}
resize_pblock [get_pblocks GPU1] -add {RAMB36_X11Y54:RAMB36_X11Y57}
# set_property IS_SOFT FALSE [get_pblocks GPU1]


create_pblock GPU2
add_cells_to_pblock [get_pblocks GPU2] [get_cells -quiet [list {chfpga0/GPU_GEN.gpu_sel_gen.gpulink0/udp_gen[4].udp0} {chfpga0/GPU_GEN.gpu_sel_gen.gpulink0/udp_gen[5].udp0}]]
resize_pblock [get_pblocks GPU2] -add {SLICE_X166Y310:SLICE_X189Y329}
resize_pblock [get_pblocks GPU2] -add {DSP48_X11Y124:DSP48_X11Y131}
resize_pblock [get_pblocks GPU2] -add {RAMB18_X11Y124:RAMB18_X11Y131}
resize_pblock [get_pblocks GPU2] -add {RAMB36_X11Y62:RAMB36_X11Y65}
# set_property IS_SOFT FALSE [get_pblocks GPU2]


create_pblock GPU3
add_cells_to_pblock [get_pblocks GPU3] [get_cells -quiet [list {chfpga0/GPU_GEN.gpu_sel_gen.gpulink0/udp_gen[6].udp0} {chfpga0/GPU_GEN.gpu_sel_gen.gpulink0/udp_gen[7].udp0}]]
resize_pblock [get_pblocks GPU3] -add {SLICE_X166Y330:SLICE_X189Y349}
resize_pblock [get_pblocks GPU3] -add {DSP48_X11Y132:DSP48_X11Y139}
resize_pblock [get_pblocks GPU3] -add {RAMB18_X11Y132:RAMB18_X11Y139}
resize_pblock [get_pblocks GPU3] -add {RAMB36_X11Y66:RAMB36_X11Y69}
# set_property IS_SOFT FALSE [get_pblocks GPU3]


create_pblock ADCDAQ0
add_cells_to_pblock [get_pblocks ADCDAQ0] [get_cells -quiet {chfpga0/chan_array0/adc_gen.ev8aq160_case.adcgen[0].*}]
resize_pblock [get_pblocks ADCDAQ0] -add {SLICE_X0Y169:SLICE_X7Y186}
resize_pblock [get_pblocks ADCDAQ0] -add {RAMB18_X0Y70:RAMB18_X0Y71}
resize_pblock [get_pblocks ADCDAQ0] -add {RAMB36_X0Y35:RAMB36_X0Y35}
create_pblock ADCDAQ1
add_cells_to_pblock [get_pblocks ADCDAQ1] [get_cells -quiet {chfpga0/chan_array0/adc_gen.ev8aq160_case.adcgen[1].*}]
resize_pblock [get_pblocks ADCDAQ1] -add {SLICE_X0Y152:SLICE_X7Y168}
resize_pblock [get_pblocks ADCDAQ1] -add {RAMB18_X0Y68:RAMB18_X0Y69}
resize_pblock [get_pblocks ADCDAQ1] -add {RAMB36_X0Y34:RAMB36_X0Y34}
create_pblock ADCDAQ2
add_cells_to_pblock [get_pblocks ADCDAQ2] [get_cells -quiet {chfpga0/chan_array0/adc_gen.ev8aq160_case.adcgen[2].*}]
resize_pblock [get_pblocks ADCDAQ2] -add {SLICE_X0Y125:SLICE_X7Y142 SLICE_X0Y96:SLICE_X7Y97}
resize_pblock [get_pblocks ADCDAQ2] -add {RAMB18_X0Y50:RAMB18_X0Y51}
resize_pblock [get_pblocks ADCDAQ2] -add {RAMB36_X0Y25:RAMB36_X0Y25}
create_pblock ADCDAQ3
add_cells_to_pblock [get_pblocks ADCDAQ3] [get_cells -quiet {chfpga0/chan_array0/adc_gen.ev8aq160_case.adcgen[3].*}]
resize_pblock [get_pblocks ADCDAQ3] -add {SLICE_X0Y98:SLICE_X7Y116}
resize_pblock [get_pblocks ADCDAQ3] -add {RAMB18_X0Y40:RAMB18_X0Y41}
resize_pblock [get_pblocks ADCDAQ3] -add {RAMB36_X0Y20:RAMB36_X0Y20}
create_pblock ADCDAQ4
add_cells_to_pblock [get_pblocks ADCDAQ4] [get_cells -quiet {chfpga0/chan_array0/adc_gen.ev8aq160_case.adcgen[4].*}]
resize_pblock [get_pblocks ADCDAQ4] -add {SLICE_X0Y7:SLICE_X7Y24}
resize_pblock [get_pblocks ADCDAQ4] -add {RAMB18_X0Y8:RAMB18_X0Y9}
resize_pblock [get_pblocks ADCDAQ4] -add {RAMB36_X0Y4:RAMB36_X0Y4}
create_pblock ADCDAQ5
add_cells_to_pblock [get_pblocks ADCDAQ5] [get_cells -quiet {chfpga0/chan_array0/adc_gen.ev8aq160_case.adcgen[5].*}]
resize_pblock [get_pblocks ADCDAQ5] -add {SLICE_X0Y30:SLICE_X7Y49}
resize_pblock [get_pblocks ADCDAQ5] -add {RAMB18_X0Y18:RAMB18_X0Y19}
resize_pblock [get_pblocks ADCDAQ5] -add {RAMB36_X0Y9:RAMB36_X0Y9}
create_pblock ADCDAQ6
add_cells_to_pblock [get_pblocks ADCDAQ6] [get_cells -quiet {chfpga0/chan_array0/adc_gen.ev8aq160_case.adcgen[6].*}]
resize_pblock [get_pblocks ADCDAQ6] -add {SLICE_X0Y57:SLICE_X7Y74}
resize_pblock [get_pblocks ADCDAQ6] -add {RAMB18_X0Y28:RAMB18_X0Y29}
resize_pblock [get_pblocks ADCDAQ6] -add {RAMB36_X0Y14:RAMB36_X0Y14}
create_pblock ADCDAQ7
add_cells_to_pblock [get_pblocks ADCDAQ7] [get_cells -quiet {chfpga0/chan_array0/adc_gen.ev8aq160_case.adcgen[7].*}]
resize_pblock [get_pblocks ADCDAQ7] -add {SLICE_X0Y75:SLICE_X7Y92}
resize_pblock [get_pblocks ADCDAQ7] -add {RAMB18_X0Y30:RAMB18_X0Y31}
resize_pblock [get_pblocks ADCDAQ7] -add {RAMB36_X0Y15:RAMB36_X0Y15}
create_pblock ADCDAQ8
add_cells_to_pblock [get_pblocks ADCDAQ8] [get_cells -quiet {chfpga0/chan_array0/adc_gen.ev8aq160_case.adcgen[8].*}]
resize_pblock [get_pblocks ADCDAQ8] -add {SLICE_X0Y281:SLICE_X7Y298}
resize_pblock [get_pblocks ADCDAQ8] -add {RAMB18_X0Y118:RAMB18_X0Y119}
resize_pblock [get_pblocks ADCDAQ8] -add {RAMB36_X0Y59:RAMB36_X0Y59}
create_pblock ADCDAQ9
add_cells_to_pblock [get_pblocks ADCDAQ9] [get_cells -quiet {chfpga0/chan_array0/adc_gen.ev8aq160_case.adcgen[9].*}]
resize_pblock [get_pblocks ADCDAQ9] -add {SLICE_X0Y257:SLICE_X7Y274}
resize_pblock [get_pblocks ADCDAQ9] -add {RAMB18_X0Y108:RAMB18_X0Y109}
resize_pblock [get_pblocks ADCDAQ9] -add {RAMB36_X0Y54:RAMB36_X0Y54}
create_pblock ADCDAQ10
add_cells_to_pblock [get_pblocks ADCDAQ10] [get_cells -quiet {chfpga0/chan_array0/adc_gen.ev8aq160_case.adcgen[10].*}]
resize_pblock [get_pblocks ADCDAQ10] -add {SLICE_X0Y352:SLICE_X7Y353 SLICE_X0Y299:SLICE_X7Y316}
resize_pblock [get_pblocks ADCDAQ10] -add {RAMB18_X0Y120:RAMB18_X0Y121}
resize_pblock [get_pblocks ADCDAQ10] -add {RAMB36_X0Y60:RAMB36_X0Y60}
create_pblock ADCDAQ11
add_cells_to_pblock [get_pblocks ADCDAQ11] [get_cells -quiet {chfpga0/chan_array0/adc_gen.ev8aq160_case.adcgen[11].*}]
resize_pblock [get_pblocks ADCDAQ11] -add {SLICE_X0Y332:SLICE_X7Y351}
resize_pblock [get_pblocks ADCDAQ11] -add {RAMB18_X0Y138:RAMB18_X0Y139}
resize_pblock [get_pblocks ADCDAQ11] -add {RAMB36_X0Y69:RAMB36_X0Y69}
create_pblock ADCDAQ12
add_cells_to_pblock [get_pblocks ADCDAQ12] [get_cells -quiet {chfpga0/chan_array0/adc_gen.ev8aq160_case.adcgen[12].*}]
resize_pblock [get_pblocks ADCDAQ12] -add {SLICE_X0Y207:SLICE_X7Y224}
resize_pblock [get_pblocks ADCDAQ12] -add {RAMB18_X0Y88:RAMB18_X0Y89}
resize_pblock [get_pblocks ADCDAQ12] -add {RAMB36_X0Y44:RAMB36_X0Y44}
create_pblock ADCDAQ13
add_cells_to_pblock [get_pblocks ADCDAQ13] [get_cells -quiet {chfpga0/chan_array0/adc_gen.ev8aq160_case.adcgen[13].*}]
resize_pblock [get_pblocks ADCDAQ13] -add {SLICE_X0Y225:SLICE_X7Y245}
resize_pblock [get_pblocks ADCDAQ13] -add {RAMB18_X0Y90:RAMB18_X0Y91}
resize_pblock [get_pblocks ADCDAQ13] -add {RAMB36_X0Y45:RAMB36_X0Y45}
create_pblock ADCDAQ14
add_cells_to_pblock [get_pblocks ADCDAQ14] [get_cells -quiet {chfpga0/chan_array0/adc_gen.ev8aq160_case.adcgen[14].*}]
resize_pblock [get_pblocks ADCDAQ14] -add {SLICE_X0Y377:SLICE_X7Y393 SLICE_X0Y330:SLICE_X7Y331}
resize_pblock [get_pblocks ADCDAQ14] -add {RAMB18_X0Y150:RAMB18_X0Y151}
resize_pblock [get_pblocks ADCDAQ14] -add {RAMB36_X0Y75:RAMB36_X0Y75}
create_pblock ADCDAQ15
add_cells_to_pblock [get_pblocks ADCDAQ15] [get_cells -quiet {chfpga0/chan_array0/adc_gen.ev8aq160_case.adcgen[15].*}]
resize_pblock [get_pblocks ADCDAQ15] -add {SLICE_X0Y358:SLICE_X7Y376 SLICE_X0Y328:SLICE_X7Y329}
resize_pblock [get_pblocks ADCDAQ15] -add {RAMB18_X0Y148:RAMB18_X0Y149}
resize_pblock [get_pblocks ADCDAQ15] -add {RAMB36_X0Y74:RAMB36_X0Y74}











create_pblock CT
add_cells_to_pblock [get_pblocks CT] [get_cells -quiet [list chfpga0/*.ct0/bsb_router0 chfpga0/*.ct0/*.bp_shuffle0 chfpga0/*.ct0/*.chan_crossbar0 chfpga0/*.ct0/*.crossbar2 chfpga0/*.ct0/*.crossbar3]]
resize_pblock [get_pblocks CT] -add {SLICE_X166Y375:SLICE_X189Y399 SLICE_X166Y290:SLICE_X189Y309 SLICE_X156Y0:SLICE_X189Y234 SLICE_X142Y250:SLICE_X165Y399 SLICE_X142Y0:SLICE_X155Y149}
resize_pblock [get_pblocks CT] -add {RAMB18_X10Y150:RAMB18_X11Y159 RAMB18_X10Y116:RAMB18_X11Y123 RAMB18_X10Y0:RAMB18_X11Y93 RAMB18_X9Y100:RAMB18_X9Y159 RAMB18_X9Y0:RAMB18_X9Y59}
resize_pblock [get_pblocks CT] -add {RAMB36_X10Y75:RAMB36_X11Y79 RAMB36_X10Y58:RAMB36_X11Y61 RAMB36_X10Y0:RAMB36_X11Y46 RAMB36_X9Y50:RAMB36_X9Y79 RAMB36_X9Y0:RAMB36_X9Y29}
set_property IS_SOFT FALSE [get_pblocks CT]
