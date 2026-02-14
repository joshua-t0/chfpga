# Common constraints are in ice_physical_constraints_common.xdc



# create_pblock CHAN0
# add_cells_to_pblock [get_pblocks CHAN0] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[0].chan0}]]
# resize_pblock [get_pblocks CHAN0] -add {SLICE_X132Y200:SLICE_X149Y214 SLICE_X8Y175:SLICE_X131Y199}
# resize_pblock [get_pblocks CHAN0] -add {DSP48_X8Y80:DSP48_X9Y85 DSP48_X0Y70:DSP48_X7Y79}
# resize_pblock [get_pblocks CHAN0] -add {RAMB18_X8Y80:RAMB18_X9Y85 RAMB18_X1Y70:RAMB18_X7Y79 RAMB18_X0Y74:RAMB18_X0Y79}
# resize_pblock [get_pblocks CHAN0] -add {RAMB36_X8Y40:RAMB36_X9Y42 RAMB36_X1Y35:RAMB36_X7Y39 RAMB36_X0Y37:RAMB36_X0Y39}
# # add_cells_to_pblock [get_pblocks CHAN0] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[0].chan0}]]

# create_pblock CHAN1
# add_cells_to_pblock [get_pblocks CHAN1] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[1].chan0}]]
# resize_pblock [get_pblocks CHAN1] -add {SLICE_X136Y168:SLICE_X147Y174 SLICE_X8Y150:SLICE_X135Y174}
# resize_pblock [get_pblocks CHAN1] -add {DSP48_X0Y60:DSP48_X7Y69}
# resize_pblock [get_pblocks CHAN1] -add {RAMB18_X1Y60:RAMB18_X8Y69 RAMB18_X0Y60:RAMB18_X0Y65}
# resize_pblock [get_pblocks CHAN1] -add {RAMB36_X1Y30:RAMB36_X8Y34 RAMB36_X0Y30:RAMB36_X0Y32}
# # add_cells_to_pblock [get_pblocks CHAN1] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[1].chan0}]]

# create_pblock CHAN2
# add_cells_to_pblock [get_pblocks CHAN2] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[2].chan0}]]
# resize_pblock [get_pblocks CHAN2] -add {SLICE_X8Y125:SLICE_X143Y149}
# resize_pblock [get_pblocks CHAN2] -add {DSP48_X0Y50:DSP48_X7Y59}
# resize_pblock [get_pblocks CHAN2] -add {RAMB18_X1Y50:RAMB18_X7Y59 RAMB18_X0Y54:RAMB18_X0Y59}
# resize_pblock [get_pblocks CHAN2] -add {RAMB36_X1Y25:RAMB36_X7Y29 RAMB36_X0Y27:RAMB36_X0Y29}
# # add_cells_to_pblock [get_pblocks CHAN2] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[2].chan0}]]
# create_pblock CHAN3
# add_cells_to_pblock [get_pblocks CHAN3] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[3].chan0}]]
# resize_pblock [get_pblocks CHAN3] -add {SLICE_X8Y100:SLICE_X135Y124}
# resize_pblock [get_pblocks CHAN3] -add {DSP48_X0Y40:DSP48_X7Y49}
# resize_pblock [get_pblocks CHAN3] -add {RAMB18_X1Y40:RAMB18_X7Y49 RAMB18_X0Y44:RAMB18_X0Y49}
# resize_pblock [get_pblocks CHAN3] -add {RAMB36_X1Y20:RAMB36_X7Y24 RAMB36_X0Y22:RAMB36_X0Y24}
# # add_cells_to_pblock [get_pblocks CHAN3] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[3].chan0}]]

# create_pblock CHAN4
# add_cells_to_pblock [get_pblocks CHAN4] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[4].chan0}]]
# resize_pblock [get_pblocks CHAN4] -add {SLICE_X8Y0:SLICE_X135Y24}
# resize_pblock [get_pblocks CHAN4] -add {DSP48_X0Y0:DSP48_X7Y9}
# resize_pblock [get_pblocks CHAN4] -add {RAMB18_X1Y0:RAMB18_X7Y9 RAMB18_X0Y0:RAMB18_X0Y5}
# resize_pblock [get_pblocks CHAN4] -add {RAMB36_X1Y0:RAMB36_X7Y4 RAMB36_X0Y0:RAMB36_X0Y2}
# # add_cells_to_pblock [get_pblocks CHAN4] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[4].chan0}]]

# create_pblock CHAN5
# add_cells_to_pblock [get_pblocks CHAN5] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[5].chan0}]]
# resize_pblock [get_pblocks CHAN5] -add {SLICE_X8Y25:SLICE_X135Y49}
# resize_pblock [get_pblocks CHAN5] -add {DSP48_X0Y10:DSP48_X7Y19}
# resize_pblock [get_pblocks CHAN5] -add {RAMB18_X1Y10:RAMB18_X7Y19 RAMB18_X0Y10:RAMB18_X0Y15}
# resize_pblock [get_pblocks CHAN5] -add {RAMB36_X1Y5:RAMB36_X7Y9 RAMB36_X0Y5:RAMB36_X0Y7}
# # add_cells_to_pblock [get_pblocks CHAN5] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[5].chan0}]]

# create_pblock CHAN6
# add_cells_to_pblock [get_pblocks CHAN6] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[6].chan0}]]
# resize_pblock [get_pblocks CHAN6] -add {SLICE_X132Y51:SLICE_X135Y74 SLICE_X8Y50:SLICE_X131Y74}
# resize_pblock [get_pblocks CHAN6] -add {DSP48_X0Y20:DSP48_X7Y29}
# resize_pblock [get_pblocks CHAN6] -add {RAMB18_X1Y20:RAMB18_X7Y29 RAMB18_X0Y20:RAMB18_X0Y25}
# resize_pblock [get_pblocks CHAN6] -add {RAMB36_X1Y10:RAMB36_X7Y14 RAMB36_X0Y10:RAMB36_X0Y12}
# # add_cells_to_pblock [get_pblocks CHAN6] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[6].chan0}]]

# create_pblock CHAN7
# add_cells_to_pblock [get_pblocks CHAN7] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[7].chan0}]]
# resize_pblock [get_pblocks CHAN7] -add {SLICE_X8Y75:SLICE_X135Y99}
# resize_pblock [get_pblocks CHAN7] -add {DSP48_X0Y30:DSP48_X7Y39}
# resize_pblock [get_pblocks CHAN7] -add {RAMB18_X1Y30:RAMB18_X7Y39 RAMB18_X0Y34:RAMB18_X0Y39}
# resize_pblock [get_pblocks CHAN7] -add {RAMB36_X1Y15:RAMB36_X7Y19 RAMB36_X0Y17:RAMB36_X0Y19}
# # add_cells_to_pblock [get_pblocks CHAN7] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[7].chan0}]]

# ######


# create_pblock CHAN8
# add_cells_to_pblock [get_pblocks CHAN8] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[8].chan0}]]
# resize_pblock [get_pblocks CHAN8] -add {SLICE_X8Y275:SLICE_X135Y299}
# resize_pblock [get_pblocks CHAN8] -add {DSP48_X0Y110:DSP48_X7Y119}
# resize_pblock [get_pblocks CHAN8] -add {RAMB18_X1Y110:RAMB18_X8Y119 RAMB18_X0Y110:RAMB18_X0Y115}
# resize_pblock [get_pblocks CHAN8] -add {RAMB36_X1Y55:RAMB36_X8Y59 RAMB36_X0Y55:RAMB36_X0Y57}
# # add_cells_to_pblock [get_pblocks CHAN8] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[8].chan0}]]

# create_pblock CHAN14
# add_cells_to_pblock [get_pblocks CHAN14] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[14].chan0}]]
# resize_pblock [get_pblocks CHAN14] -add {SLICE_X8Y375:SLICE_X135Y399}
# resize_pblock [get_pblocks CHAN14] -add {DSP48_X0Y150:DSP48_X7Y159}
# resize_pblock [get_pblocks CHAN14] -add {RAMB18_X1Y150:RAMB18_X8Y159 RAMB18_X0Y154:RAMB18_X0Y159}
# resize_pblock [get_pblocks CHAN14] -add {RAMB36_X1Y75:RAMB36_X8Y79 RAMB36_X0Y77:RAMB36_X0Y79}
# # add_cells_to_pblock [get_pblocks CHAN14] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[14].chan0}]]

# create_pblock CHAN15
# add_cells_to_pblock [get_pblocks CHAN15] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[15].chan0}]]
# resize_pblock [get_pblocks CHAN15] -add {SLICE_X8Y350:SLICE_X135Y374}
# resize_pblock [get_pblocks CHAN15] -add {DSP48_X0Y140:DSP48_X7Y149}
# resize_pblock [get_pblocks CHAN15] -add {RAMB18_X1Y140:RAMB18_X8Y149 RAMB18_X0Y140:RAMB18_X0Y145}
# resize_pblock [get_pblocks CHAN15] -add {RAMB36_X1Y70:RAMB36_X8Y74 RAMB36_X0Y70:RAMB36_X0Y72}
# # add_cells_to_pblock [get_pblocks CHAN15] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[15].chan0}]]

# create_pblock CHAN11
# add_cells_to_pblock [get_pblocks CHAN11] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[11].chan0}]]
# resize_pblock [get_pblocks CHAN11] -add {SLICE_X8Y325:SLICE_X135Y349}
# resize_pblock [get_pblocks CHAN11] -add {DSP48_X0Y130:DSP48_X7Y139}
# resize_pblock [get_pblocks CHAN11] -add {RAMB18_X1Y130:RAMB18_X8Y139 RAMB18_X0Y130:RAMB18_X0Y135}
# resize_pblock [get_pblocks CHAN11] -add {RAMB36_X1Y65:RAMB36_X8Y69 RAMB36_X0Y65:RAMB36_X0Y67}
# # add_cells_to_pblock [get_pblocks CHAN11] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[11].chan0}]]

# create_pblock CHAN10
# add_cells_to_pblock [get_pblocks CHAN10] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[10].chan0}]]
# resize_pblock [get_pblocks CHAN10] -add {SLICE_X8Y300:SLICE_X135Y324}
# resize_pblock [get_pblocks CHAN10] -add {DSP48_X0Y120:DSP48_X7Y129}
# resize_pblock [get_pblocks CHAN10] -add {RAMB18_X1Y120:RAMB18_X8Y129 RAMB18_X0Y124:RAMB18_X0Y129}
# resize_pblock [get_pblocks CHAN10] -add {RAMB36_X1Y60:RAMB36_X8Y64 RAMB36_X0Y62:RAMB36_X0Y64}
# # add_cells_to_pblock [get_pblocks CHAN10] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[10].chan0}]]

# create_pblock CHAN9
# add_cells_to_pblock [get_pblocks CHAN9] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[9].chan0}]]
# resize_pblock [get_pblocks CHAN9] -add {SLICE_X8Y250:SLICE_X135Y274}
# resize_pblock [get_pblocks CHAN9] -add {DSP48_X0Y100:DSP48_X7Y109}
# resize_pblock [get_pblocks CHAN9] -add {RAMB18_X1Y100:RAMB18_X8Y109 RAMB18_X0Y100:RAMB18_X0Y105}
# resize_pblock [get_pblocks CHAN9] -add {RAMB36_X1Y50:RAMB36_X8Y54 RAMB36_X0Y50:RAMB36_X0Y52}
# # add_cells_to_pblock [get_pblocks CHAN9] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[9].chan0}]]


# create_pblock CHAN12
# add_cells_to_pblock [get_pblocks CHAN12] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[12].chan0}]]
# resize_pblock [get_pblocks CHAN12] -add {SLICE_X132Y215:SLICE_X149Y224 SLICE_X8Y200:SLICE_X131Y224}
# resize_pblock [get_pblocks CHAN12] -add {DSP48_X8Y86:DSP48_X9Y89 DSP48_X0Y80:DSP48_X7Y89}
# resize_pblock [get_pblocks CHAN12] -add {RAMB18_X1Y86:RAMB18_X9Y89 RAMB18_X0Y80:RAMB18_X7Y85}
# resize_pblock [get_pblocks CHAN12] -add {RAMB36_X1Y43:RAMB36_X9Y44 RAMB36_X0Y40:RAMB36_X7Y42}
# # add_cells_to_pblock [get_pblocks CHAN12] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[12].chan0}]]

# create_pblock CHAN13
# add_cells_to_pblock [get_pblocks CHAN13] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[13].chan0}]]
# resize_pblock [get_pblocks CHAN13] -add {SLICE_X8Y225:SLICE_X135Y249}
# resize_pblock [get_pblocks CHAN13] -add {DSP48_X0Y90:DSP48_X8Y99}
# resize_pblock [get_pblocks CHAN13] -add {RAMB18_X1Y90:RAMB18_X8Y99 RAMB18_X0Y94:RAMB18_X0Y99}
# resize_pblock [get_pblocks CHAN13] -add {RAMB36_X1Y45:RAMB36_X8Y49 RAMB36_X0Y47:RAMB36_X0Y49}
# # add_cells_to_pblock [get_pblocks CHAN13] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[13].chan0}]]

# set_property LOC DNA_PORT_X0Y0 [get_cells chfpga0/*.system0/*.gpio0/gen_dna7.dna0]


create_pblock SYSTEM
add_cells_to_pblock [get_pblocks SYSTEM] [get_cells -quiet {chfpga0/*.system0/*.blinker0 chfpga0/*.system0/*.freq_ctr0 chfpga0/*.system0/*.i2c0 chfpga0/*.system0/*.gpio0/core_regs0 chfpga0/*.system0/*.gpio0/irigb_comparator0 chfpga0/*.system0/*.gpio0/irigb_decoder0 chfpga0/*.system0/*.gpio0/irigb_encoder0}]
resize_pblock [get_pblocks SYSTEM] -add {SLICE_X180Y225:SLICE_X189Y324}


create_pblock UDP_MAC
add_cells_to_pblock [get_pblocks UDP_MAC] [get_cells -quiet [list chfpga0/bsb_master_blk.ctrl_master0 chfpga0/gen_eth.phy_case.udp_mac0]]
resize_pblock [get_pblocks UDP_MAC] -add {SLICE_X150Y200:SLICE_X189Y224}
resize_pblock [get_pblocks UDP_MAC] -add {DSP48_X10Y80:DSP48_X11Y89}
resize_pblock [get_pblocks UDP_MAC] -add {RAMB18_X10Y80:RAMB18_X10Y89}
resize_pblock [get_pblocks UDP_MAC] -add {RAMB36_X10Y40:RAMB36_X10Y44}


create_pblock CLK0
add_cells_to_pblock [get_pblocks CLK0] [get_cells -quiet [list chfpga0/clk0]]
resize_pblock [get_pblocks CLK0] -add {SLICE_X0Y248:SLICE_X7Y249 SLICE_X0Y150:SLICE_X7Y151}

create_pblock ARM_SPI
resize_pblock [get_pblocks ARM_SPI] -add {SLICE_X0Y187:SLICE_X7Y206}

create_pblock I2C
resize_pblock [get_pblocks I2C] -add {SLICE_X0Y200:SLICE_X7Y204}
create_pblock SPI
resize_pblock [get_pblocks SPI] -add {SLICE_X0Y93:SLICE_X7Y95}
create_pblock BP_BUCK_SYNC
resize_pblock [get_pblocks BP_BUCK_SYNC] -add {SLICE_X0Y117:SLICE_X7Y124}




create_pblock CORR
add_cells_to_pblock [get_pblocks CORR] [get_cells -quiet [list chfpga0/CORRGEN.corr_sel_gen.ucorr44_case.ucorr44_array0]]
resize_pblock [get_pblocks CORR] -add {SLICE_X180Y325:SLICE_X189Y399 SLICE_X180Y0:SLICE_X189Y136 SLICE_X132Y225:SLICE_X179Y399 SLICE_X132Y0:SLICE_X179Y169}
resize_pblock [get_pblocks CORR] -add {DSP48_X8Y90:DSP48_X11Y159 DSP48_X8Y0:DSP48_X11Y67}
resize_pblock [get_pblocks CORR] -add {RAMB18_X8Y90:RAMB18_X11Y159 RAMB18_X8Y0:RAMB18_X11Y67}
resize_pblock [get_pblocks CORR] -add {RAMB36_X8Y45:RAMB36_X11Y79 RAMB36_X8Y0:RAMB36_X11Y33}






